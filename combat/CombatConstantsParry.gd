class_name CombatConstantsParry
extends RefCounted

const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5
const PARRY_STRENGTH_NORM := 100.0
const PARRY_DEFLECT_THRESHOLD := 1.08
const PARRY_TECHNIQUE_VARIANCE := 0.15
const PARRY_V_MIN_FRACTION := 0.2
const PARRY_V_MIN_NEAR_DEFLECT := 0.1
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := 0.25
const PARRY_BLADE_MOVEMENT_S := 0.13
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0
const PERF_MOD_MIN := 0.35
const COMMITMENT_FRACTION := 0.2
const COMMITMENT_FRACTION_FEINT := 0.35
const RECOVERY_READINESS_EARLY := 0.5
const RECOVERY_READINESS_LATE := 0.85
const OFF_BALANCE_DURATION_S := 0.4
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7
const OFF_BALANCE_GAUGE_FILL_MULT := 0.5
const PARRY_BONUS_AFTER_DEFLECT_S := 2.0
const GUARD_AFTER_ATTACK := 0.4
const GUARD_RISE_RATE := 0.6
const PARRY_DODGE_STRENGTH_RATIO := 2.2
const PARRY_BLOCK_MASS_THRESHOLD := 0.75
const PARRY_BLOCK_STR_THRESHOLD := 0.85
const PARRY_REDIRECT_BONUS := 0.18
const PARRY_REDIRECT_SKILL_SCALE := 0.35
const PARRY_REDIRECT_ATTEMPT_RATIO := 2.5
const PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE := 0.5
const PARRY_GLANCING_EXPONENT := 0.5
const PARRY_REDIRECT_THRUST_BONUS := 0.22
const PARRY_REDIRECT_BLUNT_PENALTY := 0.12
const PARRY_CUT_TO_BLUNT_SHIFT := 0.28
const PARRY_PENETRATION_ANGLE_MIN := 0.72
const PARRY_PENETRATION_ALIGNMENT_SCALE := 0.5  # Legacy: replaced by cosine obliquity model (AttackResolver.penetration_oblique_angle_factor). Kept for harness regression tests.
const PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD := 0.6
const PARRY_BIND_CONTROL_THRESHOLD := 0.65

static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool) -> bool:
	return is_block_parry and c_d >= parry_p_a * PARRY_DEFLECT_THRESHOLD

static func parry_edge_deflect_reached(
	c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool
) -> bool:
	if is_block_parry:
		return false
	return (
		alignment >= PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
		and c_d >= parry_p_a * PARRY_DEFLECT_THRESHOLD
	)

static func parry_bind_control_reached(parry_control: float) -> bool:
	return parry_control >= PARRY_BIND_CONTROL_THRESHOLD

static func iii3_baseline_constants_line() -> String:
	return (
		"III-3 constants: unchanged baseline (PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f)"
		% [PARRY_DEFLECT_THRESHOLD, PARRY_BIND_CONTROL_THRESHOLD]
	)

static func p4d_parry_bind_doc_sync_line() -> String:
	var blade: Dictionary = PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary
	var shaft: Dictionary = PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary
	return (
		"P4d bind sync: blade stab=%.2f cut=%.2f shaft blunt=%.2f fallback=%.2f gauge_bonus=%.0f"
		% [
			float(blade["stab"]),
			float(blade["cut"]),
			float(shaft["blunt"]),
			PARRY_BIND_RIPOSTE_MULT_FALLBACK,
			PARRY_BIND_RIPOSTE_GAUGE_BONUS,
		]
	)

const ARCHETYPES_NEVER_BIND: Array[String] = ["pommel_strike", "heavy_blunt"]
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
	"blade": {"stab": 0.55, "cut": 0.78},
	"shaft": {"stab": 0.55, "cut": 0.78, "blunt": 0.90},
	"haft": {"stab": 0.55, "cut": 0.78}
}
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = 0.78
const _Stamina := preload("res://combat/CombatConstantsStamina.gd")
const PARRY_BIND_RIPOSTE_GAUGE_BONUS := float(_Stamina.PARRY_BIND_RIPOSTE_GAUGE_BONUS)
const PARRY_LATE_CONTROL_FACTOR := 0.6
const PARRY_OFF_BALANCE_CONTROL_FACTOR := 0.7
const PARRY_THRUST_CONTROL_MULT := 0.85
const PARRY_DESPERATE_DODGE_THRESHOLD := 0.06
const PARRY_PREFER_DODGE_FULL_THRESHOLD := 0.04
const PARRY_MASS_DISPARITY_BONUS := 0.18
const PARRY_LATE_CAPACITY_FLOOR := 0.22
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.88, "haft": 0.92}
const PARRY_DEF_VS_ATK_MOD: Dictionary = {"DAGGER": {"stab": 0.9}, "MACE": {"blunt": 1.05}, "SPEAR": {"cut": 0.95}}
const PARRY_INERTIA_BLEND: float = 0.5
const PARRY_LEVERAGE_LONG_PART_CM: float = 80.0
const PARRY_LEVERAGE_FLOOR: float = 0.65

const GUARD_TRANSITION_COST_SCALE := 0.4
const GUARD_TRANSITION_MULT_MAX := 1.35
const PREFERRED_PART_BONUS_MULT := 1.5
## AI pick: attack parts off defender mental focus / guard line.
const AI_PICK_OFF_FOCUS_PART_MULT := 1.35
const AI_PICK_ON_FOCUS_LINE_PENALTY_MULT := 0.82
const AI_PICK_NOVICE_ON_FOCUS_LINE_PENALTY_MULT := 0.95
## AI pick: yomi habit line pressure vs counter-line surprise.
const AI_PICK_YOMI_HABIT_LINE_PART_MULT := 1.28
const AI_PICK_YOMI_COUNTER_LINE_PART_MULT := 1.32
const AI_PICK_STAT_BASELINE := 100.0
const AI_PICK_STAT_SPREAD := 60.0
const AI_PICK_NOVICE_OFF_FOCUS_MULT := 1.06
const AI_PICK_NOVICE_YOMI_HABIT_MULT := 1.04
const AI_PICK_NOVICE_YOMI_COUNTER_MULT := 1.06
const AI_PICK_NOVICE_PREFERRED_MULT := 1.15

const FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD := 0.9
const FEINT_PRE_REVEAL_READINESS_MULT := 0.5
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS := 0.55
const PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS := "_harness_feint_dodge_eval_bias"
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE := 1.08
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG := 0.88

static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
	if not pa.get("feint_part", "").strip_edges().is_empty():
		return COMMITMENT_FRACTION_FEINT
	return COMMITMENT_FRACTION

static func stats_factor_agi_perc(agi: float, perc: float) -> float:
	return clampf((agi + perc) / 200.0, 0.5, 1.5)

static func glancing_factor(ratio: float, exponent: float = PARRY_GLANCING_EXPONENT) -> float:
	return pow(clampf(ratio, 0.0, 1.0), exponent)

static func compute_parry_redirect_mult(pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float) -> float:
	var r_bonus: float = pcfg.get("redirect_bonus", PARRY_REDIRECT_BONUS)
	var r_scale: float = pcfg.get("redirect_skill_scale", PARRY_REDIRECT_SKILL_SCALE)
	var redirect_skill: float = stats_factor_agi_perc(agi, perc)
	var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
	var ct: String = contact_type.to_lower()
	if ct == "stab":
		redirect_mult *= 1.0 + pcfg.get("redirect_thrust_bonus", PARRY_REDIRECT_THRUST_BONUS)
	elif ct == "blunt":
		redirect_mult *= 1.0 - pcfg.get("redirect_blunt_penalty", PARRY_REDIRECT_BLUNT_PENALTY)
	if not is_block_parry and m_a > 0.001 and m_d < m_a:
		var mass_bonus: float = pcfg.get("mass_disparity_bonus", PARRY_MASS_DISPARITY_BONUS) * (1.0 - m_d / m_a)
		redirect_mult *= 1.0 + mass_bonus
	return redirect_mult

static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
	return c_d_final / maxf(parry_p_a * PARRY_DEFLECT_THRESHOLD, 0.01)

static func parry_deflect_severity_from_margin_ratio(margin_ratio: float) -> float:
	return clampf((margin_ratio - 1.0) / 1.0, 0.0, 1.0)

static func parry_control_for_bind_deflect(
	c_d_final: float,
	parry_p_a: float,
	alignment: float,
	parry_readiness: float,
	parry_off_balance: bool,
	late_parry: bool,
	contact_type: String
) -> float:
	var margin_ratio: float = parry_deflect_margin_ratio(c_d_final, parry_p_a)
	var margin_factor: float = clampf(margin_ratio, 0.5, 2.0)
	var readiness_factor: float = parry_readiness * (PARRY_OFF_BALANCE_CONTROL_FACTOR if parry_off_balance else 1.0)
	var timing_factor: float = PARRY_LATE_CONTROL_FACTOR if late_parry else 1.0
	var p: float = clampf(margin_factor * alignment * readiness_factor * timing_factor, 0.0, 1.0)
	var ct: String = contact_type.to_lower().strip_edges()
	if ct == "stab":
		p *= PARRY_THRUST_CONTROL_MULT
	return p
