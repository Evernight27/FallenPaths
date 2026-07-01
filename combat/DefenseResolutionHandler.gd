class_name DefenseResolutionHandler
extends RefCounted

## Resolves defense outcomes: partial parry follow-through (twist dodge), full/partial dodge, parry deflect/partial.
## Footing (strike geometry): reads **`CombatFootwork.guard_angle_deg`** + attacker offset on contact —" not form home guard. LIVE_PATHS **`#wf-tier-44-pa`** (geometry) · **`#wf-guard-writers`**.
## **Read order:** parry deflect/partial branches Ã¢â ' dodge branches Ã¢â ' follow-through re-entry hooks.
## **`parry_deflect`** full-stop and **`parry_partial`** follow-through both attach a **`parry_clash_context`** dict on the returned result (partial adds **`remaining_ratio`** / **`geometric_leak`**; Tier **3.0** KE on partial uses reduced **`pa["velocity_m_s"]`**).
## Returns a result dict to return from resolve_attack, or null to fall through to hit.

const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

## Debug logging —" delegates to `CombatDebug.log` which gates on `combat_debug_active`.

## Resolves defense. Returns dict with action, target_id, recovery_duration (if applicable); or null to fall through to hit.
static func resolve(
	pa: Dictionary, atk: Dictionary, tgt: Dictionary, dc: Dictionary,
	targetable: Array, attack_type: String, intensity: float, archetype: Dictionary,
	velocity_override: float, recovery_mult: float, perf_mod: float,
	target_id: int, atk_name: String, tgt_name: String
) -> Variant:
	var already_used_defense: bool = pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
	var defense_choice: String = dc.defense
	var parry_p_a: float = dc.parry_p_a
	var parry_c_d: float = dc.parry_c_d
	var parry_time_to_react: float = dc.parry_time_to_react
	var parry_readiness: float = dc.parry_readiness
	var is_block_parry: bool = dc.is_block_parry
	var m_a_parry: float = dc.m_a_parry
	var m_d_parry: float = dc.m_d_parry
	var dodge_chance: float = dc.dodge_chance
	var dodge_eval_part: String = dc.dodge_eval_part
	var effective_redirect: float = dc.effective_redirect

	if already_used_defense:
		var result = _resolve_partial_parry_follow_through(
			pa, atk, tgt, targetable, attack_type, intensity, archetype, velocity_override,
			recovery_mult, perf_mod, target_id, atk_name, tgt_name
		)
		if result != null:
			return result
	elif defense_choice == "dodge":
		var result = _resolve_dodge(
			pa, atk, tgt, targetable, attack_type, intensity, archetype,
			dodge_chance, dodge_eval_part, recovery_mult, perf_mod, target_id, tgt_name
		)
		if result != null:
			return result
	elif defense_choice == "parry":
		var late_parry: bool = dc.get("late_parry", false)
		var parry_off_balance: bool = dc.get("parry_off_balance", false)
		var m_a_velocity: float = dc.get("m_a_velocity", m_a_parry)
		return _resolve_parry(
			pa, atk, tgt, attack_type, intensity, archetype, recovery_mult,
			parry_p_a, parry_c_d, parry_time_to_react, parry_readiness,
			is_block_parry, m_a_parry, m_d_parry, m_a_velocity, effective_redirect,
			late_parry, parry_off_balance, target_id, atk_name, tgt_name, dc
		)
	return null


static func _arm_interpose_clash_extra(dc: Dictionary) -> Dictionary:
	var boost: float = dc.get("arm_interpose_boost", 0.0)
	if boost <= 0.0:
		return {}
	return {
		"arm_interpose_arm": str(dc.get(CombatConstants.CLASH_KEY_ARM_INTERPOSE, "")),
		"arm_interpose_boost": boost,
	}

static func _resolve_partial_parry_follow_through(
	pa: Dictionary, atk: Dictionary, tgt: Dictionary, targetable: Array,
	attack_type: String, intensity: float, _archetype: Dictionary, velocity_override: float,
	recovery_mult: float, perf_mod: float, target_id: int, atk_name: String, tgt_name: String
) -> Variant:
	var time_to_react: float = pa.get("parry_twist_time_to_react", 0.0)
	var twist_readiness: float = pa.get("parry_twist_readiness", 1.0)
	var time_factor: float = clampf(time_to_react / maxf(0.001, CombatConstants.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S), 0.0, 1.0)
	if time_to_react <= 0.0:
		time_factor = 0.15
	var leg: float = _EntityAccess.get_leg_functionality(tgt)
	var perf: float = _EntityAccess.get_performance_modifier(tgt)
	var agi: float = float(_EntityAccess.stats_dict(tgt).get("agility", CombatConstants.DEFAULT_STAT_VALUE))
	var perc: float = float(_EntityAccess.stats_dict(tgt).get("perception", CombatConstants.DEFAULT_STAT_VALUE))
	var mobility_factor: float = leg * perf * CombatConstants.stats_factor_agi_perc(agi, perc)
	var twist_capacity: float = time_factor * mobility_factor * twist_readiness
	var follow_eff: float = CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY
	var attack_type_mod: float = 1.0
	var twist_ct: String = _WeaponConstants.contact_type_for_move_id(attack_type)
	if twist_ct == WeaponConstants.ATTACK_TYPE_STAB:
		attack_type_mod = 1.0 - CombatConstants.PARRY_FOLLOW_THROUGH_THRUST_PENALTY
	elif twist_ct == WeaponConstants.ATTACK_TYPE_CUT:
		attack_type_mod = 1.0 + CombatConstants.PARRY_FOLLOW_THROUGH_CUT_BONUS
	var twist_partial_min: float = CombatConstants.PARRY_FOLLOW_THROUGH_PARTIAL_MIN
	var parry_ratio: float = pa.get("parry_remaining_ratio", 1.0)
	var parry_quality_scale: float = 1.0 - 0.3 * parry_ratio
	parry_quality_scale = clampf(parry_quality_scale, 0.7, 1.0)
	var dodge_chance_follow: float = _EntityAccess.get_dodge_chance(tgt)
	var part_follow: String = BodyPartConstants.get_weighted_random_part(targetable) if not targetable.is_empty() else ""
	var part_mod_follow: float = _EntityAccess.get_part_dodge_modifier(tgt, part_follow)
	var effective_follow_dodge: float = dodge_chance_follow * follow_eff * part_mod_follow * twist_capacity * attack_type_mod * parry_quality_scale
	var dodge_roll_follow: float = randf()
	if effective_follow_dodge > 0.0:
		if dodge_roll_follow < effective_follow_dodge * CombatConstants.DODGE_FULL_THRESHOLD:
			CombatDebug.log("twist_full_dodge %s->%s eff=%.2f" % [atk_name, tgt_name, effective_follow_dodge])
			var rec_dur: float = CombatTiming.recovery_duration(intensity, "dodge", recovery_mult, perf_mod, _EntityAccess.stats_dict(atk).get("agility", CombatConstants.DEFAULT_STAT_VALUE))
			return { "action": "dodge", "target_id": target_id, "recovery_duration": rec_dur }
		elif dodge_roll_follow < effective_follow_dodge:
			var partial_range: float = effective_follow_dodge * (1.0 - CombatConstants.DODGE_FULL_THRESHOLD)
			var t_twist: float = (dodge_roll_follow - effective_follow_dodge * CombatConstants.DODGE_FULL_THRESHOLD) / partial_range if partial_range > 0.001 else 1.0
			var twist_remaining_ratio: float = lerpf(twist_partial_min, 1.0, clampf(t_twist, 0.0, 1.0))
			var combined_ratio: float = parry_ratio * twist_remaining_ratio
			pa["parry_remaining_ratio"] = combined_ratio
			var v_current: float = pa.get("velocity_m_s", velocity_override)
			if v_current >= 0.0:
				var glancing_factor: float = CombatConstants.glancing_factor(twist_remaining_ratio, 0.5)
				pa["velocity_m_s"] = v_current * glancing_factor
			CombatDebug.log("twist_partial %s->%s combined=%.2f" % [atk_name, tgt_name, combined_ratio])
		else:
			CombatDebug.log("twist_none %s->%s resolving" % [atk_name, tgt_name])
	else:
		CombatDebug.log("twist_no_capacity %s->%s" % [atk_name, tgt_name])
	return null

static func _resolve_dodge(
	pa: Dictionary, atk: Dictionary, tgt: Dictionary, targetable: Array,
	attack_type: String, intensity: float, archetype: Dictionary,
	dodge_chance: float, dodge_eval_part: String, recovery_mult: float, perf_mod: float,
	target_id: int, tgt_name: String
) -> Variant:
	var dodge_target_part: String = dodge_eval_part if not dodge_eval_part.is_empty() else BodyPartConstants.get_weighted_random_part(targetable)
	var part_mod: float = _EntityAccess.get_part_dodge_modifier(tgt, dodge_target_part)
	var effective_dodge_chance: float = dodge_chance * part_mod
	var dodge_roll: float = randf()
	if effective_dodge_chance > 0.0:
		if dodge_roll < effective_dodge_chance * CombatConstants.DODGE_FULL_THRESHOLD:
			CombatDebug.log("dodge_full %s eff=%.2f" % [tgt_name, effective_dodge_chance])
			var rec_dur: float = CombatTiming.recovery_duration(intensity, "dodge", recovery_mult, perf_mod, _EntityAccess.stats_dict(atk).get("agility", CombatConstants.DEFAULT_STAT_VALUE))
			return { "action": "dodge", "target_id": target_id, "recovery_duration": rec_dur }
		elif dodge_roll < effective_dodge_chance:
			var partial_range: float = effective_dodge_chance * (1.0 - CombatConstants.DODGE_FULL_THRESHOLD)
			var t: float = (dodge_roll - effective_dodge_chance * CombatConstants.DODGE_FULL_THRESHOLD) / partial_range if partial_range > 0.001 else 1.0
			var dodge_remaining_ratio: float = lerpf(CombatConstants.DODGE_PARTIAL_RATIO_MIN, 1.0, clampf(t, 0.0, 1.0))
			pa["parry_remaining_ratio"] = dodge_remaining_ratio
			var atk_weapon = _EntityAccess.get_weapon(atk)
			if atk_weapon != null:
				var attack_instance = AttackInstance.new(attack_type, intensity)
				attack_instance.archetype = archetype
				var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
				v_intent *= _StrikeRealism.velocity_intent_mult_from_pa(pa, atk_weapon, attack_type, float(pa.get("intensity", intensity)), archetype)
				var glancing_factor: float = CombatConstants.glancing_factor(dodge_remaining_ratio, 0.5)
				pa["velocity_m_s"] = v_intent * glancing_factor
			else:
				pa["velocity_m_s"] = -1.0
			pa["partial_dodge_part"] = dodge_target_part
			CombatDebug.log("dodge_partial %s part=%s ratio=%.2f" % [tgt_name, dodge_target_part, dodge_remaining_ratio])
		else:
			CombatDebug.log("dodge_none %s => hit" % [tgt_name])
	return null

static func _resolve_parry(
	pa: Dictionary, atk: Dictionary, tgt: Dictionary,
	attack_type: String, intensity: float, archetype: Dictionary, recovery_mult: float,
	parry_p_a: float, parry_c_d: float, parry_time_to_react: float, parry_readiness: float,
	is_block_parry: bool, m_a_parry: float, m_d_parry: float, m_a_velocity: float, _effective_redirect: float,
	late_parry: bool, parry_off_balance: bool, target_id: int, atk_name: String, _tgt_name: String,
	dc: Dictionary = {}
) -> Variant:
	var interpose_extra: Dictionary = _arm_interpose_clash_extra(dc)
	pa["passive_parry_attempted"] = true
	pa["parry_twist_time_to_react"] = parry_time_to_react
	pa["parry_twist_readiness"] = parry_readiness
	var _move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var _attack_line: String = pa.get("effective_attack_line", _move_def.get("attack_line", "high"))
	var _guard_line: String = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
	# Arc tracking: use blade position at parry contact for alignment (where blades meet).
	var _parry_progress: float = 1.0
	if not late_parry:
		var eff_wind: float = pa.get("wind_up_duration", 0.5) * (1.0 - CombatConstants.commitment_fraction_for_pending_attack(pa))
		_parry_progress = 1.0 - clampf(parry_time_to_react / maxf(0.001, eff_wind), 0.0, 1.0)
	var _align_ctx: Dictionary = {}
	var arc_start: float = pa.get("arc_start_deg", 0.0)
	var arc_end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
	if arc_end >= -900.0:
		var attack_angle_at_contact: float = CombatConstants.get_arc_angle_at_progress(
			arc_start, arc_end, _parry_progress
		)
		attack_angle_at_contact = _Footwork.apply_offset_to_angle_deg(attack_angle_at_contact, atk)
		var _wobble: Dictionary = _EntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
		_align_ctx = {
			"attack_angle_deg": attack_angle_at_contact,
			"guard_angle_deg": _Footwork.guard_angle_deg(tgt, _wobble),
		}
	var _alignment: float = CombatConstants.get_line_alignment_with_deflect(_attack_line, tgt, _align_ctx)
	var c_d_final: float = parry_c_d
	if CombatConstants.PARRY_TECHNIQUE_VARIANCE > 0.0:
		var agi_var: float = float(_EntityAccess.stats_dict(tgt).get("agility", CombatConstants.DEFAULT_STAT_VALUE))
		var variance_scale: float = clampf(1.0 - 0.5 * (agi_var - 100.0) / 100.0, CombatConstants.STAMINA_MULT_FLOOR, CombatConstants.STAMINA_MULT_CEILING)
		var variance_eff: float = CombatConstants.PARRY_TECHNIQUE_VARIANCE * variance_scale
		var geom_scale: float = clampf(1.0 / maxf(0.2, _alignment), 1.0, 2.5)
		variance_eff *= geom_scale
		c_d_final *= randf_range(1.0 - variance_eff, 1.0 + variance_eff)
	var _effective_alignment: float = _alignment
	if not interpose_extra.is_empty():
		_effective_alignment = minf(1.0, _alignment + interpose_extra.get("arm_interpose_boost", 0.0))
	var interpose_note: String = ""
	if not interpose_extra.is_empty():
		interpose_note = " interpose_arm=%s boost=%.3f" % [interpose_extra.get(CombatConstants.CLASH_KEY_ARM_INTERPOSE, ""), interpose_extra.get("arm_interpose_boost", 0.0)]
	var pcfg: Dictionary = _PassiveParry.get_parry_config()
	var glancing_exp: float = pcfg.get("glancing_exponent", 0.5)
	var def_name: String = _EntityAccess.get_display_name(tgt, target_id)
	CombatDebug.log("parry %s block=%s align=%.3f eff_align=%.3f c_d_final=%.2f p_a=%.2f" % [def_name, is_block_parry, _alignment, _effective_alignment, c_d_final, parry_p_a])
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		var geom_scale: float = clampf(1.0 / maxf(0.2, _alignment), 1.0, 2.5)
		var angle_suffix: String = ""
		if pa.get("attack_angle_deg", -999.0) >= 0.0:
			var _wobble_cal: Dictionary = _EntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
			angle_suffix = " atk_deg=%.0f guard_deg=%.0f" % [
				pa["attack_angle_deg"], _Footwork.guard_angle_deg(tgt, _wobble_cal)
			]
		CombatDebug.calibration_log("parry_calc atk=%s guard=%s align=%.3f eff_align=%.3f c_d_final=%.2f p_a=%.2f geom_scale=%.2f%s%s" % [_attack_line, _guard_line, _alignment, _effective_alignment, c_d_final, parry_p_a, geom_scale, angle_suffix, interpose_note])
	var full_stop: bool = CombatConstants.parry_full_stop_reached(c_d_final, parry_p_a, is_block_parry)
	if full_stop:
		var parry_intensity: float = pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
		var atk_perf: float = _EntityAccess.get_performance_modifier(atk)
		var rec_dur: float = CombatTiming.recovery_duration(parry_intensity, "full_stop", recovery_mult, atk_perf, _EntityAccess.stats_dict(atk).get("agility", CombatConstants.DEFAULT_STAT_VALUE))
		var eff_atk_line: String = pa.get("effective_attack_line", _attack_line)
		var atk_weapon_ctx = _EntityAccess.get_weapon(atk)
		var atk_angle_at_contact: float = _parry_attack_angle_deg(
			atk, arc_start, arc_end, _parry_progress, eff_atk_line
		)
		var _wobble_ctx: Dictionary = _EntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
		var kinematics_fs: Dictionary = _strike_kinematics_for_parry_clash(
			atk_weapon_ctx, pa, attack_type, intensity, archetype
		)
		var parry_clash_context: Dictionary = _build_parry_clash_context(
			eff_atk_line, attack_type, atk_angle_at_contact, c_d_final, parry_p_a, parry_c_d,
			_alignment, _guard_line, _Footwork.guard_angle_deg(tgt, _wobble_ctx),
			parry_time_to_react, parry_readiness, late_parry, parry_off_balance, is_block_parry,
			m_a_parry, m_d_parry, m_a_velocity, kinematics_fs,
			pa.get("strike_measure_ratio", -1.0),
			interpose_extra
		)
		CombatDebug.log("parry_deflect %s blocked %s align=%.3f eff_align=%.3f ctrl=%.3f%s" % [def_name, atk_name, _alignment, _effective_alignment, parry_clash_context.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL), interpose_note])
		CombatDebug.calibration_log("outcome=parry_deflect c_d_final=%.2f p_a=%.2f ctrl=%.3f align=%.3f eff_align=%.3f glancing_exp=%.2f%s" % [c_d_final, parry_p_a, parry_clash_context.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL), _alignment, _effective_alignment, glancing_exp, interpose_note])
		return { "action": "parry_deflect", "target_id": target_id, "recovery_duration": rec_dur, "parry_clash_context": parry_clash_context }
	var attacker_weapon = _EntityAccess.get_weapon(atk)
	var agi_d: float = float(_EntityAccess.stats_dict(tgt).get("agility", CombatConstants.DEFAULT_STAT_VALUE))
	var perc_d: float = float(_EntityAccess.stats_dict(tgt).get("perception", CombatConstants.DEFAULT_STAT_VALUE))
	var redirect_mult: float = CombatConstants.compute_parry_redirect_mult(pcfg, agi_d, perc_d, _WeaponConstants.contact_type_for_move_id(attack_type), is_block_parry, m_a_parry, m_d_parry)
	var effective_reduction: float = c_d_final * redirect_mult
	var remaining_momentum: float = maxf(0.0, parry_p_a - effective_reduction)
	var remaining_ratio: float = remaining_momentum / parry_p_a if parry_p_a > 0.0 else 0.0
	var geometric_leak: float = (1.0 - _effective_alignment) * CombatConstants.GEOMETRIC_LEAK_MAX
	var pre_leak_ratio: float = remaining_ratio
	remaining_ratio = minf(1.0, remaining_ratio + geometric_leak)
	if CombatConstants.combat_debug_active():
		CombatDebug.calibration_log("parry_partial c_d_final=%.2f p_a=%.2f align=%.3f eff_align=%.3f pre_leak=%.2f leak=%.2f final_ratio=%.2f glancing_exp=%.2f m_a_vel=%.2f%s" % [c_d_final, parry_p_a, _alignment, _effective_alignment, pre_leak_ratio, geometric_leak, remaining_ratio, glancing_exp, m_a_velocity, interpose_note])
	var glancing_factor: float = CombatConstants.glancing_factor(remaining_ratio, glancing_exp)
	# Use m_a_velocity (striking part mass when weapon has parts) for v_reduced; else m_a_parry (total mass).
	var m_a_vel: float = m_a_velocity if m_a_velocity > 0.0 else m_a_parry
	var v_reduced: float = (parry_p_a * glancing_factor) / maxf(0.001, m_a_vel)
	var attack_instance = AttackInstance.new(attack_type, intensity)
	attack_instance.archetype = archetype
	var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance)
	if attacker_weapon != null:
		v_intent *= _StrikeRealism.velocity_intent_mult_from_pa(pa, attacker_weapon, attack_type, float(pa.get("intensity", intensity)), archetype)
	var v_min_eff: float = v_intent * lerpf(CombatConstants.PARRY_V_MIN_NEAR_DEFLECT, CombatConstants.PARRY_V_MIN_FRACTION, clampf(remaining_ratio, 0.0, 1.0))
	pa["velocity_m_s"] = maxf(v_reduced, v_min_eff)
	pa["parry_remaining_ratio"] = remaining_ratio
	CombatDebug.log("parry_partial %s vs %s final_ratio=%.2f (align=%.2f align_eff=%.2f pre_leak=%.2f + leak=%.2f)%s" % [def_name, atk_name, remaining_ratio, _alignment, _effective_alignment, pre_leak_ratio, geometric_leak, interpose_note])
	var eff_atk_line_p: String = pa.get("effective_attack_line", _attack_line)
	var atk_angle_partial: float = _parry_attack_angle_deg(
		atk, arc_start, arc_end, _parry_progress, eff_atk_line_p
	)
	var _wobble_p: Dictionary = _EntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
	var strike_v_partial: float = pa.get("velocity_m_s", 0.0)
	var kinematics_p: Dictionary = _strike_kinematics_for_parry_clash(
		attacker_weapon, pa, attack_type, intensity, archetype, strike_v_partial
	)
	var partial_extra: Dictionary = {
		"remaining_ratio": remaining_ratio,
		"geometric_leak": geometric_leak,
	}
	for k in interpose_extra:
		partial_extra[k] = interpose_extra[k]
	var parry_clash_context_partial: Dictionary = _build_parry_clash_context(
		eff_atk_line_p, attack_type, atk_angle_partial, c_d_final, parry_p_a, parry_c_d,
		_alignment, _guard_line, _Footwork.guard_angle_deg(tgt, _wobble_p),
		parry_time_to_react, parry_readiness, late_parry, parry_off_balance, is_block_parry,
		m_a_parry, m_d_parry, m_a_velocity, kinematics_p,
		pa.get("strike_measure_ratio", -1.0),
		partial_extra
	)
	return {
		"action": "parry_partial",
		"target_id": target_id,
		"parry_clash_context": parry_clash_context_partial,
	}


static func _parry_attack_angle_deg(
	atk: Dictionary,
	arc_start: float,
	arc_end: float,
	parry_progress: float,
	eff_atk_line: String
) -> float:
	var angle: float = (
		CombatConstants.get_arc_angle_at_progress(arc_start, arc_end, parry_progress)
		if arc_end >= -900.0
		else CombatConstants.line_to_angle(eff_atk_line)
	)
	return _Footwork.apply_offset_to_angle_deg(angle, atk)


static func _strike_kinematics_for_parry_clash(
	atk_weapon: Variant,
	pa: Dictionary,
	attack_type: String,
	intensity: float,
	archetype: Dictionary,
	strike_velocity_m_s: float = -999.0
) -> Dictionary:
	var arch_id: String = _EntityAccess.weapon_archetype_id(atk_weapon, attack_type, "")
	var kinematic_delivery_str: String = WeaponDamageHelper.kinematic_delivery(archetype, attack_type)
	var strike_v: float = strike_velocity_m_s
	var strike_ke: float = 0.0
	if atk_weapon != null:
		var attack_instance := AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		if strike_v < -900.0:
			strike_v = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
			strike_v *= _StrikeRealism.velocity_intent_mult_from_pa(
				pa, atk_weapon, attack_type, float(pa.get("intensity", intensity)), archetype
			)
		attack_instance.velocity_m_s = strike_v
		strike_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_weapon, attack_instance)
	return {
		"archetype_id": arch_id,
		"kinematic_delivery": kinematic_delivery_str,
		"strike_velocity_m_s": strike_v,
		"strike_kinetic_energy_j": strike_ke,
	}


static func _build_parry_clash_context(
	eff_atk_line: String,
	attack_type: String,
	attack_angle_deg: float,
	c_d_final: float,
	parry_p_a: float,
	parry_c_d: float,
	alignment: float,
	guard_line: String,
	guard_angle_deg: float,
	parry_time_to_react: float,
	parry_readiness: float,
	late_parry: bool,
	parry_off_balance: bool,
	is_block_parry: bool,
	m_a_parry: float,
	m_d_parry: float,
	m_a_velocity: float,
	kinematics: Dictionary,
	strike_measure_ratio: float,
	extra: Dictionary = {}
) -> Dictionary:
	var contact_ct: String = _WeaponConstants.contact_type_for_move_id(attack_type)
	var margin_ratio: float = CombatConstants.parry_deflect_margin_ratio(c_d_final, parry_p_a)
	var parry_control: float = CombatConstants.parry_control_for_bind_deflect(
		c_d_final, parry_p_a, alignment, parry_readiness, parry_off_balance, late_parry, contact_ct
	)
	var ctx: Dictionary = {
		"archetype_id": kinematics.get("archetype_id", ""),
		"parry_control": parry_control,
		"parry_p_a": parry_p_a,
		"parry_c_d": parry_c_d,
		"c_d_final": c_d_final,
		"m_a_parry": m_a_parry,
		"m_d_parry": m_d_parry,
		"m_a_velocity": m_a_velocity,
		"margin_ratio": margin_ratio,
		## IV-5: raw (pre-interpose) alignment —" parry_control and harness validation use this same value;
		## interpose boost is captured separately in arm_interpose_boost / arm_interpose_arm fields.
		"alignment": alignment,
		"defender_guard_line": guard_line,
		"guard_angle_deg": guard_angle_deg,
		"parry_time_to_react": parry_time_to_react,
		"parry_readiness": parry_readiness,
		"late_parry": late_parry,
		"parry_off_balance": parry_off_balance,
		"is_block_parry": is_block_parry,
		"attack_type": attack_type,
		"contact_type": contact_ct,
		"effective_attack_line": eff_atk_line,
		"severity": CombatConstants.parry_deflect_severity_from_margin_ratio(margin_ratio),
		"attack_angle_deg": attack_angle_deg,
		"kinematic_delivery": kinematics.get("kinematic_delivery", ""),
		"strike_velocity_m_s": kinematics.get("strike_velocity_m_s", -1.0),
		"strike_kinetic_energy_j": kinematics.get("strike_kinetic_energy_j", 0.0),
		"strike_measure_ratio": strike_measure_ratio,
	}
	for k in extra:
		ctx[k] = extra[k]
	return ctx
           