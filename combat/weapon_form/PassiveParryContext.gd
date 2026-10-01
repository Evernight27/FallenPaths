class_name PassiveParryContext
extends RefCounted

## Parry paradigm config and readiness helpers for AttackResolver.
## Footing: **`guard_zone`** gauge here is **not** L3 **`guard_line`** (blade posture)  -  see LIVE_PATHS
## **`#wf-layer-labels`**. Decouples parry/dodge logic from CombatManager.


## Parry paradigm config (redirect-default, block as exception). Used by AttackResolver.
static func get_parry_config() -> Dictionary:
    var cfg: Dictionary = {
        "block_mass_threshold": CombatConstants.PARRY_BLOCK_MASS_THRESHOLD,
        "block_str_threshold": CombatConstants.PARRY_BLOCK_STR_THRESHOLD,
        "redirect_bonus": CombatConstants.PARRY_REDIRECT_BONUS,
        "redirect_skill_scale": CombatConstants.PARRY_REDIRECT_SKILL_SCALE,
        "redirect_attempt_ratio": CombatConstants.PARRY_REDIRECT_ATTEMPT_RATIO,
        "redirect_attempt_agility_scale": CombatConstants.PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE,
        "glancing_exponent": CombatConstants.PARRY_GLANCING_EXPONENT,
        "redirect_thrust_bonus": CombatConstants.PARRY_REDIRECT_THRUST_BONUS,
        "redirect_blunt_penalty": CombatConstants.PARRY_REDIRECT_BLUNT_PENALTY,
        "mass_disparity_bonus": CombatConstants.PARRY_MASS_DISPARITY_BONUS
    }
    cfg[DataKeys.PARRY_STRONG_CONTACT_BY_ARCH] = CombatConstants.PARRY_STRONG_CONTACT_BY_ARCH
    return cfg


## 0..1 guard gauge for passive parry (not **`guard_line`**). Coerces numeric types; non-numeric -> 1.0.
static func guard_readiness_float(c: Dictionary) -> float:
    var raw: Variant = c.get("guard", 1.0)
    if raw is float or raw is int:
        return clampf(float(raw), 0.0, 1.0)
    return 1.0


## Readiness multiplier for passive parry. WAITING = 1.0 × guard; RECOVERING = lerp(early, late) by progress.
## Uses READINESS_BY_CAUSE for cause-specific curves (attack_hit = more stunned, attack_miss = off-balance, etc.).
## C3: FORM_SWITCH = lerped readiness scaling with transition progress.
static func get_passive_parry_readiness(c: Dictionary) -> float:
    var base: float = 0.0
    if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WAITING:
        base = guard_readiness_float(c)
    elif CombatantEntityAccess.state_str(c) == CombatConstants.STATE_RECOVERING:
        var dur: float = c.get(DataKeys.PA_STATE_DURATION, 0.001)
        var t: float = c.get(DataKeys.PA_STATE_TIMER, 0.0)
        var progress: float = clampf(t / dur, 0.0, 1.0)
        var cause: String = CombatConstants.normalize_recovery_cause(str(c.get(DataKeys.ATTACK_RECOVERY_CAUSE, "skip")))
        var curve: Array = CombatConstants.readiness_curve_for_cause(cause)
        var early: float = curve[0] if curve.size() >= 1 else 0.5
        var late: float = curve[1] if curve.size() >= 2 else 0.85
        base = lerpf(early, late, progress)
    elif CombatantEntityAccess.state_str(c) == CombatConstants.STATE_FORM_SWITCH:
        base = CombatFormSwitch.parry_readiness_during_switch(CombatFormSwitch.transition_progress(c))
    if base <= 0.0:
        return base
    var overcommit_mult: Variant = c.get(DataKeys.PA_OVERCOMMIT_PARRY_MULT, null)
    if overcommit_mult != null and float(overcommit_mult) < 1.0:
        base *= float(overcommit_mult)
    return (
        base
        * CombatConstants.PASSIVE_PARRY_READINESS_BASELINE_MULT
        * CombatConstants.armor_burden_passive_readiness_mult(c)
        * wound_caution_parry_readiness_mult(c)
    )


## Wounded-fighter caution (plan_balance_tuning.md): a defender who is hurt (pain + blood loss) guards up —
## higher parry readiness. Behavioral mirror of the wounded-vitals exploit (attackers press damaged vitals).
## Distinct from physical degradation (which reduces parry CAPACITY): this raises the PREFERENCE/readiness to
## parry. Feature-gated; deterministic (no RNG). Returns 1.0 when the feature is off or the defender is fresh.
static func wound_caution_parry_readiness_mult(c: Dictionary) -> float:
    if not CombatConstants.is_feature_wounded_defender_caution_enabled():
        return 1.0
    var entity: Node = CombatantEntityAccess.combat_body(c)
    if entity == null or not entity.has_method("get_wounded_parts"):
        return 1.0
    # Pain component: normalized pain (NRS-like, ref ~6.0) ramping to full caution at severe pain.
    var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(entity)
    var pain_t: float = clampf(pain / CombatConstants.WOUNDED_DEFENDER_CAUTION_PAIN_REF, 0.0, 1.0)
    # Blood-loss component: a bleeding fighter becomes more self-preserving.
    var blood: float = float(entity.blood_volume) if "blood_volume" in entity else 100.0
    var blood_t: float = clampf((100.0 - blood) / CombatConstants.WOUNDED_DEFENDER_CAUTION_BLOOD_REF, 0.0, 1.0)
    # Take the stronger signal (a fighter in acute pain OR bleeding out guards up).
    var caution: float = maxf(pain_t, blood_t)
    return 1.0 + caution * CombatConstants.WOUNDED_DEFENDER_CAUTION_MAX_BONUS


## True if combatant is still in "off balance" window (after miss or parry deflect).
static func is_off_balance(c: Dictionary) -> bool:
    var until: float = c.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0)
    return until > 0.0 and CombatTiming.now_seconds() < until


## Fraction of the off-balance window still remaining: 1.0 = just lost footing, 0.0 = about to recover.
## Lets off-balance penalties fade proportionally as the fighter re-establishes balance instead of
## staying flat for the whole window. When the total window is unknown (legacy / harness sets only
## `off_balance_until`), returns 1.0 so the full penalty still applies — backward compatible.
static func off_balance_depth(c: Dictionary) -> float:
    var until: float = c.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0)
    var now: float = CombatTiming.now_seconds()
    if until <= 0.0 or now >= until:
        return 0.0
    var total: float = c.get(DataKeys.PA_OFF_BALANCE_TOTAL, 0.0)
    if total <= 0.0:
        return 1.0
    return clampf((until - now) / total, 0.0, 1.0)


## Proportional off-balance penalty: interpolate from 1.0 (settled) toward full_mult (fully off-balance)
## by how deep into the off-balance window the combatant is, so the penalty fades as balance returns
## instead of staying flat at full strength for the whole window. `full_mult` is the full-strength
## constant (e.g. OFF_BALANCE_PARRY_CAPACITY_MULT, ANGLE_VARIANCE_OFF_BALANCE_MULT). Returns 1.0
## (no penalty) when settled.
static func off_balance_penalty_mult(c: Dictionary, full_mult: float) -> float:
    return lerpf(1.0, full_mult, off_balance_depth(c))


## Fraction of the facing-turn window still remaining: 1.0 = just turned (fully off-line), 0.0 = re-centered.
## Mirrors off_balance_depth but reads the facing-turn pair. No window (front-on / never stamped) -> 0.0,
## so the consumer is neutral for a settled or D001-style front-on fighter.
static func facing_turn_depth(c: Dictionary) -> float:
    var until: float = c.get(DataKeys.PA_FACING_TURN_UNTIL, -1.0)
    var now: float = CombatTiming.now_seconds()
    if until <= 0.0 or now >= until:
        return 0.0
    var total: float = c.get(DataKeys.PA_FACING_TURN_TOTAL, 0.0)
    if total <= 0.0:
        return 1.0
    return clampf((until - now) / total, 0.0, 1.0)


## Bounded parry-capacity dip while the fighter is still turned: lerp from 1.0 (settled) toward
## FACING_TURN_PARRY_CAPACITY_MULT_MIN as the facing depth rises. Distinct axis from off-balance,
## so it never stacks into a double stagger. D001-neutral: front-on fights never stamp a facing turn.
static func facing_turn_parry_capacity_mult(c: Dictionary) -> float:
    return lerpf(1.0, CombatConstantsParry.FACING_TURN_PARRY_CAPACITY_MULT_MIN, facing_turn_depth(c))


## Apply an off-balance window from a single event, extending if the fighter is already off-balance.
## HEMA: repeated off-balance events pile on (a second whiff while already wobbly is worse than a
## fresh single whiff), so a new event adds its duration onto the remaining time instead of resetting
## the window to the fresh value. Bounded by OFF_BALANCE_MAX_WINDOW_S so repeated hits cannot pin a
## fighter off-balance indefinitely. `fresh_total` is this event's duration, already scaled by
## off_balance_recovery_mult. Returns the effective total window now in effect.
static func apply_off_balance_window(c: Dictionary, fresh_total: float) -> float:
    var now: float = CombatTiming.now_seconds()
    var old_until: float = c.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0)
    var old_remaining: float = maxf(0.0, old_until - now)
    var new_total: float
    if old_remaining > 0.0:
        new_total = minf(CombatConstantsParry.OFF_BALANCE_MAX_WINDOW_S, old_remaining + fresh_total)
    else:
        new_total = fresh_total
    c[DataKeys.PA_OFF_BALANCE_TOTAL] = new_total
    c[DataKeys.PA_OFF_BALANCE_UNTIL] = now + new_total
    return new_total


## Formation-move settling: a fighter who just stepped/rotated/fell back is mid-replant — weight is
## shifting, the base is not yet braced. Applies a short off-balance window that fades over the window
## (reusing apply_off_balance_window, so no new state and the window stays capped by
## OFF_BALANCE_MAX_WINDOW_S). The duration is move-kind scaled and already reflects re-rooting ability
## via off_balance_recovery_mult. Plug-forward is a deliberate fast advance (gains tempo) -> 0.0, so
## calling it is a no-op there. D001-neutral: the SWORD soak has no formation movement.
static func apply_formation_settle(c: Dictionary, move_kind: String) -> void:
    if c == null:
        return
    var dur: float = CombatConstants.formation_settle_off_balance_duration(move_kind)
    if dur <= 0.0:
        return
    var total: float = dur * off_balance_recovery_mult(c)
    apply_off_balance_window(c, total)


## Cower re-plant: a fighter who just got back on his feet after cowering is not instantly braced —
## weight has to come back under the body before the guard is trustworthy. Applies an off-balance
## window sized to how compromised the legs are (see cower_replant_off_balance_duration), scaled by
## re-rooting ability like every other window. D001-neutral: the SWORD soak never cowers.
static func apply_cower_replant(c: Dictionary) -> void:
    if c == null:
        return
    var leg: float = CombatantEntityAccess.get_leg_functionality(c)
    var dur: float = CombatConstants.cower_replant_off_balance_duration(leg)
    if dur <= 0.0:
        return
    var total: float = dur * off_balance_recovery_mult(c)
    apply_off_balance_window(c, total)


## Persistent facing (Tier 3.1): stamp or extend the facing-turn window after a flank/rear resolve.
## Mirrors apply_off_balance_window's pile-on semantics: if the fighter is already turned, a fresh
## flank/rear event adds its window onto the remaining time instead of resetting, capped by
## FACING_TURN_MAX_WINDOW_S so repeated hits never pin the fighter off-line indefinitely. The window
## is scaled by off_balance_recovery_mult (same as the other two apply_* helpers) so a physically
## compromised fighter (wounded legs / low agility / exhausted / concussed) re-centers more slowly
## and stays turned longer. A front-on angle (or the feature being off, checked by the caller) yields
## a 0.0 window and is a no-op. D001-neutral: the SWORD soak never resolves flank/rear, and a healthy
## fighter's recovery_mult is 1.0, so it never stamps a non-neutral window. Returns the effective
## total window now in effect (0.0 if no turn was applied).
static func apply_facing_turn(c: Dictionary, angle: String) -> float:
    if c == null:
        return 0.0
    var fresh: float = CombatConstants.facing_turn_window_s(angle)
    if fresh <= 0.0:
        return 0.0
    # Re-centering orientation is a motor action — a compromised fighter turns back more slowly,
    # so scale the window by the same recovery factor used for off-balance re-rooting.
    fresh *= off_balance_recovery_mult(c)
    var now: float = CombatTiming.now_seconds()
    var old_until: float = c.get(DataKeys.PA_FACING_TURN_UNTIL, -1.0)
    var old_remaining: float = maxf(0.0, old_until - now)
    var new_total: float
    if old_remaining > 0.0:
        new_total = minf(CombatConstantsParry.FACING_TURN_MAX_WINDOW_S, old_remaining + fresh)
    else:
        new_total = fresh
    c[DataKeys.PA_FACING_TURN_TOTAL] = new_total
    c[DataKeys.PA_FACING_TURN_UNTIL] = now + new_total
    return new_total


## Off-balance window a landed hit staggers the defender for: one named formula combining base
## duration (blow intensity), strike location, hit outcome (glancing / negligible), kinetic energy
## (impulse), engagement orientation (front / flank / rear), the defender's own re-rooting ability,
## and the head-impact startle floor. The hit path in the applier multiplies nothing else, so this
## is the single place to read or tune "how long does a hit stagger someone". `ke_j <= 0` keeps the
## impulse term neutral; a missing/unknown engagement angle keeps orientation neutral ("front").
static func hit_off_balance_window(
    intensity: float, part: String, outcome: String, c: Dictionary, ke_j: float = -1.0
) -> float:
    var engagement_angle: String = str(c.get(DataKeys.PA_ENGAGEMENT_ANGLE, "front"))
    var armor_ratio: float = (
        CombatConstants.armor_burden_mass_ratio_for_combatant(c)
        if CombatConstants.is_feature_armor_burden_enabled()
        else 0.0
    )
    var leg: float = CombatantEntityAccess.get_leg_functionality(c)
    var window: float = (
        CombatConstants.hit_defender_off_balance_duration(intensity)
        * CombatConstants.hit_part_off_balance_mult(part)
        * CombatConstants.hit_off_balance_outcome_mult(outcome)
        * CombatConstants.hit_impulse_stagger_mult(ke_j)
        * CombatConstants.hit_orientation_stagger_mult(engagement_angle)
        * CombatConstants.hit_armor_inertia_mult(armor_ratio)
        * CombatConstants.hit_off_balance_leg_susceptibility_mult(leg)
        * off_balance_recovery_mult(c)
    )
    return maxf(window, CombatConstants.hit_startle_min_s(part, outcome, ke_j))


## Off-balance recovery multiplier: how long a fighter stays off-balance after losing footing.
## Re-establishing your center of gravity is a proprioceptive/motor skill, so it degrades with the
## fighter's physical and mental state, not just their build. Four terms multiply together:
##   - leg functionality (body): wounded legs can't plant, re-rooting lingers
##   - agility (body): a nimbler fighter re-roots faster
##   - exhaustion: a spent fighter is slower to recover balance (motor control degrades with fatigue)
##   - concussion balance: a concussed fighter has impaired balance/proprioception
## All state reads are neutral at D001 defaults (no species, default stats, no wounds/injuries), so the
## D001 SWORD soak is unaffected. Final result clamped to a bounded band (0.75x - 1.6x base).
static func off_balance_recovery_mult(c: Dictionary) -> float:
    if c.is_empty():
        return 1.0
    var leg: float = CombatantEntityAccess.get_leg_functionality(c)
    var agi: float = float(
        CombatantEntityAccess.stats_dict(c).get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
    )
    var m: float = CombatConstants.off_balance_recovery_mult(leg, agi)
    # Exhaustion: invert the timing factor (lower timing = slower) into a duration extension, floored.
    var ex: float = CombatantEntityAccess.exhaustion_float(c)
    var timing: float = CombatConstants.exhaustion_timing_mult(ex)
    if timing < 0.999:
        m /= maxf(timing, CombatConstantsParry.OFF_BALANCE_RECOVERY_EXHAUSTION_FLOOR)
    # Concussion: impaired balance (balance_mult < 1 while concussed, 1.0 otherwise) slows re-rooting.
    var entity: Node = CombatantEntityAccess.combat_body(c)
    if entity != null:
        var balance: float = float(EntityPainConsciousness.get_concussion_phase_info(entity).get("balance_mult", 1.0))
        if balance < 0.999:
            m /= balance
    return clampf(m, CombatConstantsParry.OFF_BALANCE_RECOVERY_MIN, CombatConstantsParry.OFF_BALANCE_RECOVERY_MAX)


## Parry speed (m/s): defensive move ~40 - 60% of this weapon's resolved strike-band ceiling (ImpactVelocityModel).
## Shaft/haft parries use the blunt band; blade uses cut. Optional def_weapon.parry_speed_factor scales it.
static func get_parry_speed_m_s(def_weapon = null) -> float:
    var ref_contact: String = CombatantEntityAccess.weapon_parry_ref_contact_type(def_weapon)
    var band_max: float = CombatantEntityAccess.weapon_impact_velocity_band_max(def_weapon, ref_contact)
    var base_speed: float = band_max * CombatConstants.PARRY_V_FRACTION_OF_MAX_STRIKE
    if def_weapon != null:
        var psf: Variant = def_weapon.parry_speed_factor
        if psf is float or psf is int:
            base_speed *= clampf(float(psf), CombatConstants.STAT_EFFECT_MULT_MIN, CombatConstants.STAT_EFFECT_MULT_MAX)
    return base_speed
