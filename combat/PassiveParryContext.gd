class_name PassiveParryContext
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")

## Parry paradigm config and readiness helpers for AttackResolver.
## Footing: **`guard_zone`** gauge here is **not** L3 **`guard_line`** (blade posture)  -  see LIVE_PATHS **`#wf-layer-labels`**. Decouples parry/dodge logic from CombatManager.


## Parry paradigm config (redirect-default, block as exception). Used by AttackResolver.
static func get_parry_config() -> Dictionary:
    var cfg: Dictionary = {
        "block_mass_threshold": _CombatConstants.PARRY_BLOCK_MASS_THRESHOLD,
        "block_str_threshold": _CombatConstants.PARRY_BLOCK_STR_THRESHOLD,
        "redirect_bonus": _CombatConstants.PARRY_REDIRECT_BONUS,
        "redirect_skill_scale": _CombatConstants.PARRY_REDIRECT_SKILL_SCALE,
        "redirect_attempt_ratio": _CombatConstants.PARRY_REDIRECT_ATTEMPT_RATIO,
        "redirect_attempt_agility_scale": _CombatConstants.PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE,
        "glancing_exponent": _CombatConstants.PARRY_GLANCING_EXPONENT,
        "redirect_thrust_bonus": _CombatConstants.PARRY_REDIRECT_THRUST_BONUS,
        "redirect_blunt_penalty": _CombatConstants.PARRY_REDIRECT_BLUNT_PENALTY,
        "mass_disparity_bonus": _CombatConstants.PARRY_MASS_DISPARITY_BONUS
    }
    cfg["strong_contact_by_arch"] = _CombatConstants.PARRY_STRONG_CONTACT_BY_ARCH
    return cfg


## 0..1 guard gauge for passive parry (not **`guard_line`**). Coerces numeric types; non-numeric -> 1.0.
static func guard_readiness_float(c: Dictionary) -> float:
    var raw: Variant = c.get("guard", 1.0)
    if raw is float or raw is int:
        return clampf(float(raw), 0.0, 1.0)
    return 1.0


## Readiness multiplier for passive parry. WAITING = 1.0 - -  guard; RECOVERING = lerp(early, late) by progress.
## Uses READINESS_BY_CAUSE for cause-specific curves (attack_hit = more stunned, attack_miss = off-balance, etc.).
static func get_passive_parry_readiness(c: Dictionary) -> float:
    var base: float = 0.0
    if _EntityAccess.state_str(c) == _CombatConstants.STATE_WAITING:
        base = guard_readiness_float(c)
    elif _EntityAccess.state_str(c) == _CombatConstants.STATE_RECOVERING:
        var dur: float = c.get("state_duration", 0.001)
        var t: float = c.get("state_timer", 0.0)
        var progress: float = clampf(t / dur, 0.0, 1.0)
        var cause: String = _CombatConstants.normalize_recovery_cause(str(c.get("recovery_cause", "skip")))
        var curve: Array = _CombatConstants.readiness_curve_for_cause(cause)
        var early: float = curve[0] if curve.size() >= 1 else 0.5
        var late: float = curve[1] if curve.size() >= 2 else 0.85
        base = lerpf(early, late, progress)
    if base <= 0.0:
        return base
    return base * _CombatConstants.armor_burden_passive_readiness_mult(c)


## True if combatant is still in "off balance" window (after miss or parry deflect).
static func is_off_balance(c: Dictionary) -> bool:
    var until: float = c.get("off_balance_until", -1.0)
    return until > 0.0 and CombatTiming.now_seconds() < until


## Parry speed (m/s): defensive move ~40 - 60% of this weapon's resolved strike-band ceiling (ImpactVelocityModel).
## Shaft/haft parries use the blunt band; blade uses cut. Optional def_weapon.parry_speed_factor scales it.
static func get_parry_speed_m_s(def_weapon = null) -> float:
    var ref_contact: String = _EntityAccess.weapon_parry_ref_contact_type(def_weapon)
    var band_max: float = _EntityAccess.weapon_impact_velocity_band_max(def_weapon, ref_contact)
    var base_speed: float = band_max * _CombatConstants.PARRY_V_FRACTION_OF_MAX_STRIKE
    if def_weapon != null:
        var psf: Variant = def_weapon.parry_speed_factor
        if psf is float or psf is int:
            base_speed *= clampf(
                float(psf), _CombatConstants.STAT_EFFECT_MULT_MIN, _CombatConstants.STAT_EFFECT_MULT_MAX
            )
    return base_speed
