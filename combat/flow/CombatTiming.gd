class_name CombatTiming

extends RefCounted

const WIND_UP_FACTOR_OPTIMAL_S: float = 0.40

## Maximum wind_up/t_optimal ratio fed into the quadratic energy factor. Beyond 3× optimal the curve is
## already saturated (minf(…, 1.0) clamps it); the 3.0 cap just bounds the input before squaring so a
## pathological wind-up duration cannot produce an intermediate overflow-prone value.
const WIND_UP_RATIO_MAX: float = 3.0

# --- Tactical breathing / recovery offset (Issue #8) ---
## When a fighter deliberately extends wind-up beyond optimal, they can "recover" during the
## preparation phase rather than after impact. This models the HEMA principle of taking time
## between actions to breathe, reset posture, and reduce fatigue accumulation.
## Recovery offset: each second of excess wind-up above optimal reduces post-strike recovery by up to 15%.
const TACTICAL_BREATHING_EXCESS_WINDUP_THRESHOLD_S: float = WIND_UP_FACTOR_OPTIMAL_S

const TACTICAL_BREATHING_RECOVERY_REFUND_MAX_RATIO: float = 0.15  # max 15% recovery reduction

const TACTICAL_BREATHING_WINDUP_PER_SECOND_OF_REFUND: float = 0.20  # 0.2s excess windup = 1% refund


## Combat timing calculations: intensity, wind-up, recovery, velocity curve.
## Extracted from CombatManager for reuse by AttackResolver and other systems.
## Formation move duration: heavier armor slows fall-back / swap / rotate (see **`FORMATION_ARMOR_*`** in
## **`CombatConstants`**).
static func armor_mass_duration_multiplier_for_node(node: Node) -> float:
    if node == null:
        return 1.0
    var m: float = CombatantEntityAccess.get_total_armor_mass_kg_from_node(node)
    var ref: float = CombatConstants.FORMATION_ARMOR_MASS_REF_KG
    var t: float = clampf(m / ref, 0.0, CombatConstants.FORMATION_ARMOR_MASS_RATIO_MAX)
    return lerpf(1.0, CombatConstants.FORMATION_ARMOR_MAX_SLOW_MULT, t)


## Current time in seconds (Time.get_ticks_msec() / 1000.0). Single source for combat time checks.


static func now_seconds() -> float:
    return Time.get_ticks_msec() / 1000.0


static func intensity_from_stats(c: Dictionary) -> float:
    var str_val: float = float(
        CombatantEntityAccess.stats_dict(c).get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)
    )
    var base: float = (
        0.2 + CombatConstants.INTENSITY_STRENGTH_SCALE * (str_val / CombatConstants.INTENSITY_STRENGTH_NORM)
    )
    return clampf(
        base + randf_range(-CombatConstants.INTENSITY_RANDOM_RANGE, CombatConstants.INTENSITY_RANDOM_RANGE), 0.1, 1.0
    )


static func wind_up_duration(intensity: float, windup_multiplier: float = 1.0) -> float:
    return (
        (CombatConstants.WIND_UP_BASE_S + CombatConstants.WIND_UP_SCALE_S * intensity)
        * maxf(CombatConstants.WIND_UP_MULTIPLIER_MIN, windup_multiplier)
    )


static func wind_up_duration_with_form(
    intensity: float, windup_multiplier: float, form: String, weapon: Variant = null
) -> float:
    var base: float = (
        (CombatConstants.WIND_UP_BASE_S + CombatConstants.WIND_UP_SCALE_S * intensity)
        * maxf(CombatConstants.WIND_UP_MULTIPLIER_MIN, windup_multiplier)
    )
    if form.is_empty():
        return base
    var mods: Dictionary = CombatWeaponForm.cooldown_modifiers(form, "", weapon)
    var form_windup: float = float(mods.get("windup", 1.0))
    return base * form_windup


## Guard-line transition multiplier for wind-up (clamped — see **`GUARD_TRANSITION_MULT_MAX`**).


static func guard_transition_mult(align: float) -> float:
    var a: float = clampf(align, 0.0, 1.0)
    var raw: float = 1.0 + (1.0 - a) * CombatConstants.GUARD_TRANSITION_COST_SCALE
    return minf(raw, CombatConstants.GUARD_TRANSITION_MULT_MAX)


## Velocity curve over wind-up progress (0 = swing start, 1 = impact). Peak at 1.0 so impact uses full velocity.
## Quadratic (p'2): blade accelerates into impact; early parry meets less momentum than linear.


static func velocity_curve_factor(progress: float) -> float:
    var p: float = clampf(progress, 0.0, 1.0)
    return p * p


## Wind-up energy factor — how much strike energy is generated based on wind-up duration.
## Implements the HEMA-calibrated quadratic model: wind_up_factor(t) = min(1.0, (t / T_optimal)^2)
## where T_optimal = 0.40s for a two-handed cut. Beyond this, muscles cannot contract fast enough
## to add more energy; below it, there isn't enough distance/time for torque application.
## At t=0.20: factor = 0.25 (only 25% of max energy — rushed strike)
## At t=0.35: factor = 0.76 (76% — quick cut/thrust)
## At t=0.40: factor = 1.0 (full energy — optimal timing)
## At t=0.60: factor = 2.25 -> capped at 1.0 (no extra benefit from longer wind-up)


static func wind_up_factor(wind_up_s: float, t_optimal: float = WIND_UP_FACTOR_OPTIMAL_S) -> float:
    var ratio: float = clampf(wind_up_s / maxf(0.001, t_optimal), 0.0, WIND_UP_RATIO_MAX)
    return minf(ratio * ratio, 1.0)


## Optimal wind-up time (seconds) for a standard two-handed cut — a tuned approximation of the time a
## committed cut needs to reach peak blade force. Reflects the force-velocity trade-off: a swing cannot
## be arbitrarily fast while still generating full force, so there is a sweet spot where delivered energy
## peaks. ~0.4s is a reasonable order of magnitude for the acceleration-to-impact phase of a two-handed
## cut (high-speed analysis of sword cuts places the strike phase at roughly 0.3-0.5s).


## Agility shortens recovery (higher = faster back to ready). agility 100 = 1.0; 50 = 0.7, 150 = 1.3.
static func recovery_duration(
    intensity: float,
    outcome: String,
    recovery_multiplier: float = 1.0,
    perf_mod: float = 1.0,
    agility: int = 100,
    glancing_severity: float = -1.0,
    guard_transition_cost: float = 0.0
) -> float:
    var commitment: float = intensity
    var extra: float = 0.0
    match outcome:
        "hit":
            # Successful hits (especially penetrating) delay recovery — momentum continues through target tissue.
            # Models biomechanical reality: strike carries force forward, delaying blade repositioning.
            extra = CombatConstants.RECOVERY_EXTRA_HIT_S
        "deflected":
            extra = (
                CombatConstants.RECOVERY_EXTRA_DEFLECTED_BASE_S
                + CombatConstants.RECOVERY_DEFLECT_MOMENTUM_SCALE_S * commitment
            )
        "negligible":
            extra = CombatConstants.RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S
        "full_stop":
            extra = (
                CombatConstants.RECOVERY_EXTRA_FULL_STOP_BASE_S
                + CombatConstants.RECOVERY_FULL_STOP_COMMITMENT_SCALE_S * commitment
            )
        "glancing":
            var sev: float = clampf(glancing_severity, 0.0, 1.0) if glancing_severity >= 0.0 else 0.5
            # Higher severity (closer to hit) → longer recovery; very glancing blows recover faster.
            extra = (
                CombatConstants.RECOVERY_EXTRA_GLANCING_BASE_S
                + sev * CombatConstants.RECOVERY_GLANCING_SEVERITY_SCALE_S * commitment
            )
        "miss", "dodge":
            # Commitment scales miss penalty: light stab whiff = short recovery; heavy overhead whiff = long (momentum
            # carries you)
            extra = (
                CombatConstants.RECOVERY_EXTRA_MISS_BASE_S
                + CombatConstants.RECOVERY_MISS_COMMITMENT_SCALE_S * commitment
            )
    var base: float = (
        (CombatConstants.RECOVERY_BASE_S + CombatConstants.RECOVERY_COMMITMENT_SCALE_S * commitment + extra)
        * maxf(0.5, recovery_multiplier)
    )
    # Pain/consciousness: wounded entities recover slower
    if perf_mod > 0.0:
        base /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
    # Agility: higher agility shortens recovery
    base /= clampf(float(agility) / 100.0, CombatConstants.RECOVERY_AGILITY_MIN, CombatConstants.RECOVERY_AGILITY_MAX)
    # Guard transition cost: HEMA parries that shift blade to a distant guard line (e.g., Ochs → Pflug)
    # require additional time to reposition the weapon back to a defensive stance. This models the spatial
    # displacement penalty — blades don't snap back instantly after being pushed far from their rest position.
    if guard_transition_cost > 0.0:
        base += guard_transition_cost * (1.0 + CombatConstants.GUARD_TRANSITION_COMMITMENT_SCALE * commitment)
    # Hard cap: prevents compound scaling (wounded + low agility + full-stop whiff) from producing 7+ second
    # recovery penalties that the RECOVERY_MAX_S guard is documented to prevent.
    return minf(base, CombatConstantsTiming.RECOVERY_MAX_S)


static func recovery_duration_with_form(
    intensity: float,
    outcome: String,
    recovery_multiplier: float = 1.0,
    perf_mod: float = 1.0,
    agility: int = 100,
    glancing_severity: float = -1.0,
    form: String = "",
    weapon: Variant = null,
    guard_transition_cost: float = 0.0
) -> float:
    var base: float = recovery_duration(
        intensity, outcome, recovery_multiplier, perf_mod, agility, glancing_severity, guard_transition_cost
    )
    if form.is_empty():
        return base
    var mods: Dictionary = CombatWeaponForm.cooldown_modifiers(form, "", weapon)
    var form_recovery: float = float(mods.get("recovery", 1.0))
    return base * form_recovery


## Compute guard transition cost based on defender's current guard line vs the parried position.
## Returns an absolute time penalty in seconds (0.0 = same guard, up to GUARD_TRANSITION_RECOVERY_MAX_S=0.25s
## for a 180° transition). Guards arranged cyclically at 45° spacing (high_right ~45, low_right ~-45,
## high_left ~135, low_left ~-135, cardinals high ~90 / low ~-90 / right ~0 / left ~180, centre ~0).
## Larger angular displacement between guards = more blade travel = more recovery cost.


static func compute_guard_transition_cost_s(defender_guard_line: String, attack_line: String) -> float:
    var def_angle: float = _guard_line_to_angle_deg(defender_guard_line)
    var atk_angle: float = _attack_line_to_angle_deg(attack_line)
    var delta: float = absf(_angle_diff_deg(def_angle, atk_angle))
    # Scale: 0 deg = 0 cost, 90 deg = 0.125s, 180 deg = 0.25s max transition penalty.
    var normalized: float = clampf(delta / 180.0, 0.0, 1.0)
    return normalized * CombatConstants.GUARD_TRANSITION_RECOVERY_MAX_S


static func _guard_line_to_angle_deg(guard_line: String) -> float:
    match guard_line.to_lower().strip_edges():
        "high_left", "ober":
            return 135.0
        "high_right", "ochs":
            return 45.0
        "low_right", "puer":
            return -45.0
        "low_left", "alber":
            return -135.0
        # Cardinals (the live 8-line home guards) — previously fell through to 0.0, giving 0s transition cost
        # for max-travel moves (e.g. a low guard meeting a high attack). Placed at the cardinal positions of
        # this symmetric ± convention so adjacent lines differ by 45° and opposites by 180°.
        "high":
            return 90.0
        "low":
            return -90.0
        "right":
            return 0.0
        "left":
            return 180.0
        "middle", "centre", "pflug", "mid":
            return 0.0
        _:
            return 0.0


static func _attack_line_to_angle_deg(attack_line: String) -> float:
    match attack_line.to_lower().strip_edges():
        "high_left", "from_above_left":
            return 135.0
        "high_right", "from_above_right":
            return 45.0
        "low_right", "from_below_right":
            return -45.0
        "low_left", "from_below_left":
            return -135.0
        # Cardinals (the live 8-line attack lines) — previously fell through to 0.0. Placed at the cardinal
        # positions of this symmetric ± convention so adjacent lines differ by 45° and opposites by 180°.
        "high":
            return 90.0
        "low":
            return -90.0
        "right":
            return 0.0
        "left":
            return 180.0
        "middle", "centre", "straight":
            return 0.0
        _:
            return 0.0


static func _angle_diff_deg(a: float, b: float) -> float:
    var diff: float = fmod(a - b + 180.0, 360.0)
    if diff > 180.0:
        diff -= 360.0
    return diff


# --- Tactical breathing recovery offset (Issue #8) ---

## Computes a recovery duration reduction based on how much the attacker's wind-up exceeded optimal.
## When wind_up_s > TACTICAL_BREATHING_EXCESS_WINDUP_THRESHOLD_S, each extra second of deliberate
## preparation reduces post-strike recovery (models breathing/pacing during combat).
## The fighter trades attack speed for reduced commitment — slower strikes that recover faster.


static func tactical_breathing_recovery_offset(wind_up_s: float, base_recovery_s: float) -> float:
    var excess: float = wind_up_s - TACTICAL_BREATHING_EXCESS_WINDUP_THRESHOLD_S
    if excess <= 0.0:
        return 0.0
    ## Linear scaling: each 0.2s of excess wind-up buys 1% refund (0.01 / WINDUP_PER_SECOND_OF_REFUND per second),
    ## capped at the max ratio. The old formula multiplied by MAX_RATIO directly, saturating the full 15% at just
    ## 0.2s of excess (a step function) instead of ramping over ~3s.
    var raw_refund_ratio: float = excess * (0.01 / TACTICAL_BREATHING_WINDUP_PER_SECOND_OF_REFUND)
    var refund_ratio: float = clampf(raw_refund_ratio, 0.0, TACTICAL_BREATHING_RECOVERY_REFUND_MAX_RATIO)
    return base_recovery_s * refund_ratio


## Applies the tactical breathing offset to a computed recovery duration. Returns adjusted duration.


static func apply_tactical_breathing_offset(wind_up_s: float, recovery_s: float) -> float:
    var offset: float = tactical_breathing_recovery_offset(wind_up_s, recovery_s)
    return maxf(recovery_s - offset, recovery_s * CombatConstants.TACTICAL_BREATHING_RECOVERY_FLOOR_RATIO)
