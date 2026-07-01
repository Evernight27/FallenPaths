class_name CombatConstantsStamina
extends RefCounted

## Stamina and exhaustion constants extracted from CombatConstants.gd.
## Preload this module when you only need stamina/exhaustion values and helpers.
const _FeatureFlags := preload("res://combat/CombatConstantsFeatureFlags.gd")

const STAMINA_MAX := 100.0
const STAMINA_REFILL_RATE := 5.0
const STAMINA_ATTACK_COST_BASE := 12.0
const STAMINA_ATTACK_COST_SCALE := 8.0
const STAMINA_PARRY_COST := 12.0
const STAMINA_PARRY_COST_BASE := 12.0
const STAMINA_PARRY_COST_SCALE := 8.0
const STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT := 1.35
const PARRY_BIND_RIPOSTE_GAUGE_BONUS := 28.0
const STAMINA_AT_ZERO_PARRY_MULT := 0.5
const STAMINA_AT_ZERO_DAMAGE_MULT := 0.7
const STAMINA_FACTOR_POWER := 0.65
const STAMINA_EXHAUSTION_MAX_MULT_FLOOR := 0.7
const STAMINA_BLOOD_MAX_MULT_FLOOR := 0.7
const STAMINA_REFILL_EXHAUSTION_MULT_FLOOR := 0.4
const EXHAUSTION_OFFENSE_DAMP_START := 0.25
const EXHAUSTION_OFFENSE_DAMP_FLOOR := 0.35

const COMBATANT_KEY_EXHAUSTION := "exhaustion"
const COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED := "exhaustion_fp_band_logged"
const EXHAUSTION_MAX := 1.0
const EXHAUSTION_EXERTION_PER_STAMINA_POINT := 0.004
const EXHAUSTION_ENDURANCE_MAX_RELIEF := 0.45
const EXHAUSTION_RECOVERY_RATE := 0.012
const EXHAUSTION_CURVE := 1.35
const EXHAUSTION_FLOOR_MULT := 0.55
const EXHAUSTION_UI_SHOW_THRESHOLD := 0.06
const EXHAUSTION_GAIN_BLOOD_LOSS_MULT := 1.35
const EXHAUSTION_GAIN_PAIN_SHOCK_MULT := 1.25
const FEATURE_FIGHT_EXHAUSTION_INDEX := _FeatureFlags.FEATURE_FIGHT_EXHAUSTION_INDEX


static func stamina_factor(ratio: float) -> float:
	return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)


static func stamina_attack_cost_from_intensity(intensity: float) -> float:
	return STAMINA_ATTACK_COST_BASE + STAMINA_ATTACK_COST_SCALE * clampf(intensity, 0.0, 1.0)


static func stamina_parry_cost_from_intensity(intensity: float) -> float:
	return STAMINA_PARRY_COST_BASE + STAMINA_PARRY_COST_SCALE * clampf(intensity, 0.0, 1.0)


static func action_ready_stamina_delay_mult(stamina_ratio: float) -> float:
	return lerpf(STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT, 1.0, stamina_factor(stamina_ratio))


static func defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio: float) -> float:
	var st_ratio: float = clampf(stamina_ratio, 0.0, 1.0)
	return lerpf(STAMINA_AT_ZERO_PARRY_MULT, 1.0, stamina_factor(st_ratio))


static func is_feature_fight_exhaustion_enabled() -> bool:
	return _FeatureFlags.is_feature_fight_exhaustion_enabled()


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
	_FeatureFlags.set_feature_fight_exhaustion_index_load(on)


static func exhaustion_performance_mult(exhaustion: float) -> float:
	var t: float = pow(clampf(exhaustion, 0.0, EXHAUSTION_MAX), EXHAUSTION_CURVE)
	return lerpf(1.0, EXHAUSTION_FLOOR_MULT, t)


static func defender_passive_readiness_exhaustion_mult(combatant: Dictionary) -> float:
	if not is_feature_fight_exhaustion_enabled() or combatant.is_empty():
		return 1.0
	return exhaustion_performance_mult(combatant.get(COMBATANT_KEY_EXHAUSTION, 0.0))


static func apply_parry_bind_riposte_gauge_bonus(defender: Dictionary) -> void:
	if defender.is_empty():
		return
	var g: float = defender.get("gauge", 0.0)
	defender["gauge"] = minf(100.0, g + PARRY_BIND_RIPOSTE_GAUGE_BONUS)
