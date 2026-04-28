class_name PassiveParryContext
extends RefCounted

const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")

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

## Parry speed (m/s): defensive move ~40–60% of this weapon's resolved strike-band ceiling (ImpactVelocityModel).
## Shaft/haft parries use the blunt band; blade uses cut. Optional def_weapon.parry_speed_factor scales it.
static func get_parry_speed_m_s(def_weapon = null) -> float:
	var ref_contact: String = WeaponConstants.ATTACK_TYPE_CUT
	if def_weapon != null and def_weapon.has_method("get_parry_contact_type"):
		var pct: String = str(def_weapon.get_parry_contact_type())
		if pct == "shaft" or pct == "haft":
			ref_contact = WeaponConstants.ATTACK_TYPE_BLUNT
	var band_max: float = _ImpactVelocityModel.unarmed_velocity_band_m_s().y
	if def_weapon != null and def_weapon.has_method("get_impact_velocity_band_m_s"):
		band_max = def_weapon.get_impact_velocity_band_m_s(ref_contact).y
	var base_speed: float = band_max * CombatConstants.PARRY_V_FRACTION_OF_MAX_STRIKE
	if def_weapon != null:
		var psf: Variant = def_weapon.parry_speed_factor
		if psf is float or psf is int:
			base_speed *= clampf(float(psf), 0.5, 1.5)
	return base_speed
