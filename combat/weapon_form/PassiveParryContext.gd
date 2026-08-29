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


## Readiness multiplier for passive parry. WAITING = 1.0 - -  guard; RECOVERING = lerp(early, late) by progress.
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
    var entity: Node = CombatantEntityAccess.scene_node(c)
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
