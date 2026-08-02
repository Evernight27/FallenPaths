class_name CombatTiming
extends RefCounted

## Combat timing calculations: intensity, wind-up, recovery, velocity curve.
## Extracted from CombatManager for reuse by AttackResolver and other systems.


## Formation move duration: heavier armor slows fall-back / swap / rotate (see **`FORMATION_ARMOR_*`** in
## **`CombatConstants`**).
static func armor_mass_duration_multiplier_for_node(node: Node) -> float:
    if node == null:
        return 1.0
    var m: float = CombatantEntityAccess.get_total_armor_mass_kg_from_node(node)
    var ref: float = CombatConstants.FORMATION_ARMOR_MASS_REF_KG
    var t: float = clampf(m / ref, 0.0, 1.5)
    return lerpf(1.0, CombatConstants.FORMATION_ARMOR_MAX_SLOW_MULT, t)


## Current time in seconds (Time.get_ticks_msec() / 1000.0). Single source for combat time checks.
static func now_seconds() -> float:
    return Time.get_ticks_msec() / 1000.0


static func intensity_from_stats(c: Dictionary) -> float:
    var str_val: float = float(CombatantEntityAccess.stats_dict(c).get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var base: float = (
        0.2 + CombatConstants.INTENSITY_STRENGTH_SCALE * (str_val / CombatConstants.INTENSITY_STRENGTH_NORM)
    )
    return clampf(
        base + randf_range(-CombatConstants.INTENSITY_RANDOM_RANGE, CombatConstants.INTENSITY_RANDOM_RANGE), 0.1, 1.0
    )


static func wind_up_duration(intensity: float, windup_multiplier: float = 1.0) -> float:
    return (CombatConstants.WIND_UP_BASE_S + CombatConstants.WIND_UP_SCALE_S * intensity) * maxf(0.5, windup_multiplier)


static func wind_up_duration_with_form(intensity: float, windup_multiplier: float, form: String, weapon: Variant = null) -> float:
    var base: float = (CombatConstants.WIND_UP_BASE_S + CombatConstants.WIND_UP_SCALE_S * intensity) * maxf(0.5, windup_multiplier)
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
    var ratio: float = clampf(wind_up_s / maxf(0.001, t_optimal), 0.0, 3.0)
    return minf(ratio * ratio, 1.0)


## Optimal wind-up time (seconds) for a standard two-handed cut. At this duration the fighter
## achieves maximum practical energy delivery — the balance point of Hill's force-velocity curve.
const WIND_UP_FACTOR_OPTIMAL_S: float = 0.40


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
            extra = (
                CombatConstants.RECOVERY_EXTRA_GLANCING_BASE_S
                + (1.0 - sev) * CombatConstants.RECOVERY_GLANCING_SEVERITY_SCALE_S * commitment
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
        base += guard_transition_cost * (1.0 + 0.5 * commitment)
    return base


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
    var base: float = recovery_duration(intensity, outcome, recovery_multiplier, perf_mod, agility, glancing_severity, guard_transition_cost)
    if form.is_empty():
        return base
    var mods: Dictionary = CombatWeaponForm.cooldown_modifiers(form, "", weapon)
    var form_recovery: float = float(mods.get("recovery", 1.0))
    return base * form_recovery


## Compute guard transition cost based on defender's current guard line vs the parried position.
## Returns an absolute time penalty in seconds (0.0 = same guard, up to ~0.35s for extreme transitions).
## Guards arranged cyclically: high_left (~135), high_right (~45), low_right (~-45), low_left (~-135),
## centre (~0). Larger angular displacement between guards = more blade travel = more recovery cost.
static func compute_guard_transition_cost_s(defender_guard_line: String, attack_line: String) -> float:
    var def_angle: float = _guard_line_to_angle_deg(defender_guard_line)
    var atk_angle: float = _attack_line_to_angle_deg(attack_line)
    var delta: float = absf(_angle_diff_deg(def_angle, atk_angle))
    # Scale: 0 deg = 0 cost, 90 deg = ~0.15s, 180 deg = ~0.30s max transition penalty.
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
        "middle", "centre", "straight":
            return 0.0
        _:
            return 0.0


static func _angle_diff_deg(a: float, b: float) -> float:
    var diff: float = fmod(a - b + 180.0, 360.0)
    if diff > 180.0:
        diff -= 360.0
    return diff
