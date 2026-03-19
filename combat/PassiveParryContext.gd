class_name PassiveParryContext
extends RefCounted

## Parry paradigm config and readiness helpers for AttackResolver.
## Decouples parry/dodge logic from CombatManager.

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
	cfg["strong_contact_by_arch"] = CombatConstants.PARRY_STRONG_CONTACT_BY_ARCH
	return cfg

## Readiness multiplier for passive parry. WAITING = 1.0 × guard; RECOVERING = lerp(early, late) by progress.
## Uses READINESS_BY_CAUSE for cause-specific curves (attack_hit = more stunned, attack_miss = off-balance, etc.).
static func get_passive_parry_readiness(c: Dictionary) -> float:
	if c.state == CombatConstants.STATE_WAITING:
		var guard: float = clampf(c.get("guard", 1.0), 0.0, 1.0)
		return guard
	if c.state == CombatConstants.STATE_RECOVERING:
		var dur: float = c.get("state_duration", 0.001)
		var t: float = c.get("state_timer", 0.0)
		var progress: float = clampf(t / dur, 0.0, 1.0)
		var cause: String = c.get("recovery_cause", "skip")
		var curve: Array = CombatConstants.READINESS_BY_CAUSE.get(cause, CombatConstants.READINESS_BY_CAUSE.get("medical", [0.5, 0.85]))
		var early: float = curve[0] if curve.size() >= 1 else 0.5
		var late: float = curve[1] if curve.size() >= 2 else 0.85
		return lerpf(early, late, progress)
	return 0.0

## True if combatant is still in "off balance" window (after miss or parry deflect).
static func is_off_balance(c: Dictionary) -> bool:
	var until: float = c.get("off_balance_until", -1.0)
	return until > 0.0 and CombatTiming.now_seconds() < until

## Parry speed (m/s): defensive move ~40–60% of max strike. Optional def_weapon.parry_speed_factor scales it.
static func get_parry_speed_m_s(def_weapon = null) -> float:
	var base_speed: float = WeaponConstants.VELOCITY_MAX_M_S * CombatConstants.PARRY_V_FRACTION_OF_MAX_STRIKE
	if def_weapon != null and (def_weapon.get("parry_speed_factor") is float or def_weapon.get("parry_speed_factor") is int):
		base_speed *= clampf(float(def_weapon.parry_speed_factor), 0.5, 1.5)
	return base_speed
