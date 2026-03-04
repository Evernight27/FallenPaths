class_name AttackResolver
extends RefCounted

## Computes pre-armor damage, applies take_damage_split, and builds the result dict for one attack.
## Manager must have: _get_entity(node), DAMAGE_TYPE_SHARP, DAMAGE_TYPE_BLUNT, GLANCING_DAMAGE_RATIO.
## Parry: defensive move ~40–60% of max strike velocity (research).
const PARRY_V_FRACTION_OF_MAX_STRIKE: float = 0.5
## Returns { "result_dict": Dictionary, "outcome": String, "recovery_duration": float }.
## Also updates tgt.stats (body_cutting, body_blunt, etc.) and tgt.alive/tgt.state if target died.

static func compute_and_apply_damage(
	manager: Node,
	attacker_id: int,
	target_id: int,
	atk: Dictionary,
	tgt: Dictionary,
	part: String,
	intensity: float,
	attack_type: String,
	archetype: Dictionary,
	velocity_override: float,
	recovery_mult: float,
	perf_mod: float,
	power: float = -1.0,
	follow_through: float = -1.0,
	parry_remaining_ratio: float = 1.0
) -> Dictionary:
	var atk_name: String = atk.node.name if atk.node != null else "id:%d" % attacker_id
	var tgt_name: String = tgt.node.name if tgt.node != null else "id:%d" % target_id
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt_momentum_per_area: float = -1.0
	var blunt_contact_cm: float = -1.0
	var pre_cut: float = 0.0
	var pre_blunt: float = 0.0

	var weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null

	if weapon != null and weapon.has_method("get_available_attack_types"):
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else WeaponDamageHelper.velocity_m_s_from_intensity(intensity, archetype)
		var arm_mod: float = atk.node.get_attack_damage_modifier() if atk.node.has_method("get_attack_damage_modifier") else 1.0
		var v_m_s: float = WeaponDamageHelper.get_effective_velocity_m_s(weapon, attack_instance)
		var ke_j: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, attack_instance)
		var mass_kg: float = float(weapon.mass) if (weapon.get("mass") is float or weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
		var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, attack_type, archetype)
		# Physics: deflected cut presents flat/slap; edge doesn't bite. Shift cut→blunt on partial parry.
		if attack_type == WeaponConstants.ATTACK_TYPE_CUT and velocity_override >= 0.0 and parry_remaining_ratio < 1.0:
			var shift_const: float = manager.PARRY_CUT_TO_BLUNT_SHIFT if manager != null else 0.45
			var redirect_shift: float = shift_const * (1.0 - parry_remaining_ratio)
			cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect_shift)
		pre_cut = WeaponDamageHelper.compute_pre_armor_cut(weapon, attack_instance, atk.stats.strength, arm_mod) * cut_ratio
		pre_blunt = WeaponDamageHelper.compute_pre_armor_blunt(weapon, attack_instance, atk.stats.strength, arm_mod) * (1.0 - cut_ratio)
		pre_armor = pre_cut + pre_blunt
		var pen_sharp_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, manager.DAMAGE_TYPE_SHARP)
		pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
		var blunt_opts: Dictionary = {}
		if tgt.node != null and tgt.node.has_method("get_armor_sharp_resistance_for_part"):
			blunt_opts["armor_resistance_rha_mm"] = tgt.node.get_armor_sharp_resistance_for_part(part)
		blunt_opts["pen_sharp_mm"] = pen_sharp
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, manager.DAMAGE_TYPE_BLUNT, blunt_opts)
		pen_blunt_momentum_per_area = pen_blunt_dict.get("penetration_blunt_momentum_per_area", -1.0)
		blunt_contact_cm = pen_blunt_dict.get("blunt_contact_cm", -1.0)
		# Angle (deflection): separate from velocity. Oblique impact = less penetration (armor research).
		if velocity_override >= 0.0 and parry_remaining_ratio < 1.0 and manager != null:
			var angle_min: float = manager.PARRY_PENETRATION_ANGLE_MIN
			var angle_factor: float = lerpf(1.0, angle_min, 1.0 - parry_remaining_ratio)
			if pen_sharp >= 0.0:
				pen_sharp *= angle_factor
			if pen_blunt_momentum_per_area >= 0.0:
				pen_blunt_momentum_per_area *= angle_factor
		print("[Damage equation] %s -> %s | power=%.2f follow_through=%.2f intensity=%.2f | v=%.2f m/s mass=%.2f kg KE=%.1f J | strength=%.2f arm=%.2f cut_ratio=%.2f => pre_armor=%.1f (cut=%.1f blunt=%.1f) | pen_sharp=%.2f mm RHA" % [atk_name, tgt_name, power, follow_through, intensity, v_m_s, mass_kg, ke_j, float(atk.stats.strength) / 100.0, arm_mod, cut_ratio, pre_armor, pre_cut, pre_blunt, pen_sharp])
	else:
		var mod: float = atk.node.get_attack_damage_modifier() if (atk.node != null and atk.node.has_method("get_attack_damage_modifier")) else 1.0
		pre_armor = (float(atk.stats.strength) / 100.0) * 8.0 * mod
		if parry_remaining_ratio < 1.0:
			pre_armor *= lerpf(0.5, 1.0, parry_remaining_ratio)
		pre_blunt = pre_armor
		pre_cut = 0.0
		print("[Damage equation] %s -> %s | fallback (unarmed): pre_armor=%.1f (cut=%.1f blunt=%.1f)" % [atk_name, tgt_name, pre_armor, pre_cut, pre_blunt])

	var health_before_cut: float = tgt.node.body_cutting.get(part, 0.0)
	var health_before_blunt: float = tgt.node.body_blunt.get(part, 0.0)
	var health_before_bone: float = tgt.node.bone_health.get(part, 0.0) if tgt.node.get("bone_health") else 0.0

	var take_result: Dictionary = {}
	if tgt.node.has_method("take_damage_split"):
		take_result = tgt.node.take_damage_split(pre_cut, pre_blunt, part, pen_sharp, pen_blunt_momentum_per_area, blunt_contact_cm)
	else:
		if pre_cut >= pre_blunt and tgt.node.has_method("take_damage"):
			take_result = tgt.node.take_damage(pre_cut, part, manager.DAMAGE_TYPE_SHARP, pen_sharp, -1.0)
			take_result["final_cut"] = take_result.get("final_amount", 0.0)
			take_result["final_blunt"] = 0.0
		else:
			take_result = tgt.node.take_damage(pre_blunt, part, manager.DAMAGE_TYPE_BLUNT, -1.0, pen_blunt_momentum_per_area)
			take_result["final_cut"] = 0.0
			take_result["final_blunt"] = take_result.get("final_amount", 0.0)

	var final_cut: float = take_result.get("final_cut", 0.0)
	var final_blunt: float = take_result.get("final_blunt", 0.0)
	var final_bone: float = take_result.get("final_bone", 0.0)
	var actual_dmg: int = int(roundf(final_cut + final_blunt + final_bone))
	var tissue_dmg: float = final_cut + final_blunt
	var outcome: String = "hit"
	if pre_armor > 0:
		if actual_dmg <= 0:
			outcome = "deflected"
		elif tissue_dmg < pre_armor * manager.GLANCING_DAMAGE_RATIO:
			outcome = "glancing"

	var tgt_entity = manager._get_entity(tgt.node)
	if tgt_entity == null:
		tgt_entity = tgt.node
	tgt.stats.body_cutting = tgt_entity.body_cutting.duplicate()
	tgt.stats.body_blunt = tgt_entity.body_blunt.duplicate()
	if tgt_entity.has_method("get_total_pain"):
		tgt.stats.total_pain = tgt_entity.get_total_pain()
	if tgt_entity.has_method("get_effective_consciousness"):
		tgt.stats.effective_consciousness = tgt_entity.get_effective_consciousness()
	if tgt_entity.has_method("get_performance_modifier"):
		tgt.stats.performance_modifier = tgt_entity.get_performance_modifier()
	if tgt_entity.has_method("get_blood_volume"):
		tgt.stats.blood_volume = tgt_entity.get_blood_volume()
	elif "blood_volume" in tgt_entity:
		tgt.stats.blood_volume = tgt_entity.blood_volume
	if tgt_entity.has_method("get_total_bleeding_rate"):
		tgt.stats.total_bleeding_rate = tgt_entity.get_total_bleeding_rate()

	var health_after_cut: float = tgt_entity.body_cutting.get(part, 0.0)
	var health_after_blunt: float = tgt_entity.body_blunt.get(part, 0.0)
	var health_after_bone: float = tgt_entity.bone_health.get(part, 0.0) if tgt_entity.get("bone_health") else 0.0
	var part_max: int = tgt_entity.body_max.get(part, 0)
	var part_bone_max: int = tgt_entity.bone_max.get(part, 0) if tgt_entity.get("bone_max") else 0
	var outcome_note: String = outcome
	if outcome == "deflected":
		outcome_note = "deflected (all damage avoided)"
	elif outcome == "glancing":
		outcome_note = "glancing (tissue_dmg %.2f < pre_armor*%.2f=%.1f)" % [tissue_dmg, manager.GLANCING_DAMAGE_RATIO, pre_armor * manager.GLANCING_DAMAGE_RATIO]
	print("[Combat] %s (%s) -> %s (%s) %s: applied cut=%.2f blunt=%.2f bone=%.2f (total %d) | part state: cut %.2f->%.2f blunt %.2f->%.2f bone %.2f->%.2f (max cut/blunt %d bone %d) | outcome: %s" % [atk_name, atk.side, tgt_name, tgt.side, part, final_cut, final_blunt, final_bone, actual_dmg, health_before_cut, health_after_cut, health_before_blunt, health_after_blunt, health_before_bone, health_after_bone, part_max, part_bone_max, outcome_note])

	var result_dict: Dictionary = {
		"dmg": actual_dmg,
		"died": false,
		"part": part,
		"damage_type": "SPLIT",
		"health_before_cut": health_before_cut,
		"health_after_cut": health_after_cut,
		"health_before_blunt": health_before_blunt,
		"health_after_blunt": health_after_blunt,
		"health_before_bone": health_before_bone,
		"health_after_bone": health_after_bone,
		"final_cut": final_cut,
		"final_blunt": final_blunt,
		"final_bone": final_bone,
		"outcome": outcome,
		"was_deflected": take_result.get("was_deflected", false),
		"was_glancing": outcome == "glancing"
	}
	result_dict["health_before"] = int(roundf(health_before_cut + health_before_blunt))
	result_dict["health_after"] = int(roundf(health_after_cut + health_after_blunt))

	if tgt.node.has_method("is_dead") and tgt.node.is_dead():
		tgt.alive = false
		tgt.state = manager.STATE_DEAD
		result_dict["died"] = true
		var death_reason: String = ""
		if tgt.node.has_method("get_death_reason"):
			death_reason = tgt.node.get_death_reason()
		print("[Combat] DEATH: %s — %s" % [tgt_name, death_reason])

	var rec_dur: float = manager._recovery_duration(intensity, outcome, recovery_mult, perf_mod, atk.stats.get("agility", 100))
	return {
		"result_dict": result_dict,
		"outcome": outcome,
		"recovery_duration": rec_dur
	}

## Parry speed (m/s): defensive move ~40–60% of max strike. Optional def_weapon.parry_speed_factor scales it.
static func get_parry_speed_m_s(def_weapon = null) -> float:
	var base_speed: float = WeaponConstants.VELOCITY_MAX_M_S * PARRY_V_FRACTION_OF_MAX_STRIKE
	if def_weapon != null and (def_weapon.get("parry_speed_factor") is float or def_weapon.get("parry_speed_factor") is int):
		base_speed *= clampf(float(def_weapon.parry_speed_factor), 0.5, 1.5)
	return base_speed

## Full attack resolution: miss, dodge, parry (deflect/partial), or hit.
## Manager must have: _get_by_id, STATE_*, _recovery_duration, _velocity_curve_factor,
## _get_passive_parry_readiness, _is_off_balance, MISS_CHANCE_BASE, HIT_CHANCE_*, COMMITMENT_FRACTION, PARRY_*, etc.
## Returns { "action": String, "target_id": int, "result_dict": {}, "recovery_duration": float, "outcome": String }.
## For parry_partial, mutates atk.pending_attack["velocity_m_s"]; manager must then set defender state and re-call _execute_attack.
static func resolve_attack(manager: Node, attacker_id: int) -> Dictionary:
	var atk = manager._get_by_id(attacker_id)
	if atk == null:
		return { "action": "skip", "target_id": -1, "recovery_duration": 0.0 }
	var pa: Dictionary = atk.pending_attack
	if pa.is_empty():
		return { "action": "skip", "target_id": -1, "recovery_duration": 0.0 }
	var target_id: int = pa.target_id
	var intensity: float = pa.intensity
	var attack_type: String = pa.get("attack_type", WeaponConstants.ATTACK_TYPE_CUT)
	var archetype: Dictionary = pa.get("archetype", {})
	var velocity_override: float = pa.get("velocity_m_s", -1.0)
	var tgt = manager._get_by_id(target_id)
	if tgt == null or not tgt.alive:
		return { "action": "skip", "target_id": target_id, "recovery_duration": 0.0 }
	var atk_name: String = atk.node.name if atk.node != null else "id:%d" % attacker_id
	var tgt_name: String = tgt.node.name if tgt.node != null else "id:%d" % target_id
	print("[Combat] Attack attempt: %s -> %s" % [atk_name, tgt_name])

	var recovery_mult: float = float(archetype.get("recovery_multiplier", 1.0))
	var atk_perf_mod: float = 1.0
	if atk.node != null and atk.node.has_method("get_performance_modifier"):
		atk_perf_mod = atk.node.get_performance_modifier()
	if atk.node != null and atk.node.has_method("get_attacking_arm") and atk.node.get_attacking_arm().is_empty():
		var rec_dur_skip: float = manager._recovery_duration(intensity, "hit", recovery_mult, atk_perf_mod, atk.stats.get("agility", 100))
		print("[Combat] %s has no functional arm; skips attack. intensity=%.2f => recovery=%.2fs" % [atk_name, intensity, rec_dur_skip])
		return { "action": "skip", "target_id": target_id, "recovery_duration": rec_dur_skip }

	var targetable: Array = []
	if tgt.node != null and tgt.node.has_method("get_targetable_parts"):
		targetable = tgt.node.get_targetable_parts()
	if targetable.is_empty():
		return { "action": "defeated", "target_id": target_id }

	var perf_mod: float = 1.0
	if atk.node != null:
		if atk.node.has_method("get_hit_chance_performance_modifier"):
			perf_mod = atk.node.get_hit_chance_performance_modifier()
		elif atk.node.has_method("get_performance_modifier"):
			perf_mod = atk.node.get_performance_modifier()
	var perception_factor: float = clampf(float(atk.stats.get("perception", 100)) / 100.0, manager.HIT_CHANCE_PERCEPTION_MIN, manager.HIT_CHANCE_PERCEPTION_MAX)
	var effective_hit_chance: float = (1.0 - manager.MISS_CHANCE_BASE) * perf_mod * perception_factor
	var miss_chance: float = 1.0 - effective_hit_chance
	var miss_roll: float = randf()
	if miss_roll < miss_chance:
		print("[Combat] Hit chance: %s -> %s | perf_mod=%.2f effective_hit=%.2f miss_chance=%.2f roll=%.3f => miss" % [atk_name, tgt_name, perf_mod, effective_hit_chance, miss_chance, miss_roll])
		var rec_dur: float = manager._recovery_duration(intensity, "miss", recovery_mult, perf_mod, atk.stats.get("agility", 100))
		return { "action": "miss", "target_id": target_id, "recovery_duration": rec_dur }
	print("[Combat] Hit chance: %s -> %s | perf_mod=%.2f effective_hit=%.2f miss_chance=%.2f roll=%.3f => hit" % [atk_name, tgt_name, perf_mod, effective_hit_chance, miss_chance, miss_roll])

	var already_used_defense: bool = pa.get("passive_parry_attempted", false)
	var can_parry_in_time: bool = false
	var parry_p_a: float = 0.0
	var parry_c_d: float = 0.0
	var parry_time_to_react: float = 0.0
	var parry_capacity_mult: float = 0.0
	var parry_readiness: float = 0.0
	var parry_off_balance: bool = false
	var late_parry: bool = false
	if not already_used_defense and tgt.state != manager.STATE_WIND_UP and tgt.state != manager.STATE_MEDICAL_WIND_UP:
		var wind_up_duration: float = pa.get("wind_up_duration", 0.5)
		var effective_wind_up: float = wind_up_duration * (1.0 - manager.COMMITMENT_FRACTION)
		if tgt.node != null and tgt.node.has_method("get_passive_parry_reaction_time") and tgt.node.has_method("get_weapon"):
			var def_weapon = tgt.node.get_weapon()
			if def_weapon != null and effective_wind_up > 0.0:
				var atk_weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
				var reaction_time: float = tgt.node.get_passive_parry_reaction_time()
				if reaction_time < effective_wind_up and atk_weapon != null:
					can_parry_in_time = true
					var attack_instance = AttackInstance.new(attack_type, intensity)
					attack_instance.archetype = archetype
					attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
					var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
					var m_a: float = float(atk_weapon.mass)
					parry_time_to_react = effective_wind_up - reaction_time
					var parry_progress: float = 1.0 - clampf(parry_time_to_react / maxf(0.001, effective_wind_up), 0.0, 1.0)
					parry_p_a = m_a * v_intent * manager._velocity_curve_factor(parry_progress)
					var m_d: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
					var s_d: float = float(tgt.stats.get("strength", 100))
					var c_d_full: float = m_d * get_parry_speed_m_s(def_weapon) * (s_d / manager.PARRY_STRENGTH_NORM)
					var agi_d: float = float(tgt.stats.get("agility", 100))
					c_d_full *= clampf(agi_d / 100.0, 0.7, 1.3)
					var def_perf: float = 1.0
					if tgt.node.has_method("get_performance_modifier"):
						def_perf = tgt.node.get_performance_modifier()
					c_d_full *= maxf(manager.PERF_MOD_MIN, def_perf)
					var arm_mod: float = 1.0
					if tgt.node.has_method("get_attack_damage_modifier"):
						arm_mod = tgt.node.get_attack_damage_modifier()
					c_d_full *= maxf(0.1, arm_mod)
					var blade_movement_s: float = manager.PARRY_BLADE_MOVEMENT_S * clampf(m_d * manager.PARRY_STRENGTH_NORM / maxf(s_d, 1.0), manager.PARRY_MOVEMENT_MASS_STRENGTH_MIN, manager.PARRY_MOVEMENT_MASS_STRENGTH_MAX)
					var effective_parry_time: float = maxf(0.0, parry_time_to_react - blade_movement_s)
					parry_capacity_mult = clampf(effective_parry_time / manager.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0.0, 1.0)
					parry_readiness = manager._get_passive_parry_readiness(tgt)
					parry_off_balance = manager._is_off_balance(tgt)
					parry_c_d = c_d_full * parry_capacity_mult * parry_readiness
					if parry_off_balance:
						parry_c_d *= manager.OFF_BALANCE_PARRY_CAPACITY_MULT
					var now_s: float = Time.get_ticks_msec() / 1000.0
					if tgt.get("parry_bonus_until", -1.0) > now_s:
						parry_c_d *= 1.1
				elif atk_weapon != null:
					# Late parry: HEMA 57–80% of contacts blade-on-blade; defender gets reflexive/partial contact even when "too late"
					can_parry_in_time = true
					late_parry = true
					var attack_instance = AttackInstance.new(attack_type, intensity)
					attack_instance.archetype = archetype
					attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
					var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
					var m_a: float = float(atk_weapon.mass)
					parry_p_a = m_a * v_intent * manager._velocity_curve_factor(1.0)
					parry_time_to_react = 0.0
					var m_d: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
					var s_d: float = float(tgt.stats.get("strength", 100))
					var c_d_full: float = m_d * get_parry_speed_m_s(def_weapon) * (s_d / manager.PARRY_STRENGTH_NORM)
					var agi_d: float = float(tgt.stats.get("agility", 100))
					c_d_full *= clampf(agi_d / 100.0, 0.7, 1.3)
					var def_perf: float = 1.0
					if tgt.node.has_method("get_performance_modifier"):
						def_perf = tgt.node.get_performance_modifier()
					c_d_full *= maxf(manager.PERF_MOD_MIN, def_perf)
					var arm_mod: float = 1.0
					if tgt.node.has_method("get_attack_damage_modifier"):
						arm_mod = tgt.node.get_attack_damage_modifier()
					c_d_full *= maxf(0.1, arm_mod)
					parry_readiness = manager._get_passive_parry_readiness(tgt)
					parry_off_balance = manager._is_off_balance(tgt)
					parry_capacity_mult = manager.PARRY_LATE_CAPACITY_FLOOR
					parry_c_d = c_d_full * parry_capacity_mult * parry_readiness
					if parry_off_balance:
						parry_c_d *= manager.OFF_BALANCE_PARRY_CAPACITY_MULT
					var now_s: float = Time.get_ticks_msec() / 1000.0
					if tgt.get("parry_bonus_until", -1.0) > now_s:
						parry_c_d *= 1.1
	var m_a_parry: float = 0.0
	var m_d_parry: float = 0.0
	var s_atk_parry: float = 100.0
	var s_d_parry: float = 100.0
	if can_parry_in_time:
		var atk_w: Variant = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
		var def_w: Variant = tgt.node.get_weapon() if (tgt.node != null and tgt.node.has_method("get_weapon")) else null
		if atk_w != null and def_w != null:
			m_a_parry = float(atk_w.mass) if (atk_w.get("mass") is float or atk_w.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
			m_d_parry = float(def_w.mass) if (def_w.get("mass") is float or def_w.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
		s_atk_parry = float(atk.stats.get("strength", 100))
		s_d_parry = float(tgt.stats.get("strength", 100))
	var dodge_chance: float = 0.0
	if tgt.node != null and tgt.node.has_method("get_dodge_chance"):
		dodge_chance = tgt.node.get_dodge_chance()
	var pcfg: Dictionary = manager._get_parry_config() if manager.has_method("_get_parry_config") else {}
	var block_mass_t: float = pcfg.get("block_mass_threshold", 0.9)
	var block_str_t: float = pcfg.get("block_str_threshold", 0.95)
	var redirect_attempt: float = pcfg.get("redirect_attempt_ratio", 2.5)
	var agi_scale: float = pcfg.get("redirect_attempt_agility_scale", 0.5)
	var agi_d_attempt: float = float(tgt.stats.get("agility", 100))
	var effective_redirect: float = redirect_attempt * (0.75 + agi_scale * clampf(agi_d_attempt / 100.0, 0.0, 1.5))
	var is_block_parry: bool = m_d_parry >= m_a_parry * block_mass_t and s_d_parry >= s_atk_parry * block_str_t
	var block_viable: bool = can_parry_in_time and parry_p_a <= parry_c_d * manager.PARRY_DODGE_STRENGTH_RATIO
	var desperate_parry: bool = can_parry_in_time and dodge_chance < manager.PARRY_DESPERATE_DODGE_THRESHOLD
	var redirect_viable: bool = can_parry_in_time and (parry_p_a <= parry_c_d * effective_redirect or desperate_parry)
	var def_has_weapon: bool = tgt.node != null and tgt.node.has_method("get_weapon") and (tgt.node.get_weapon() if tgt.node != null else null) != null
	var dodge_eval_part: String = BodyPartConstants.get_weighted_random_part(targetable) if not targetable.is_empty() else ""
	var choose_parry: bool = false
	if not def_has_weapon:
		choose_parry = false
	elif desperate_parry:
		choose_parry = true
	elif not can_parry_in_time:
		choose_parry = false
	elif can_parry_in_time and def_has_weapon:
		var part_mod: float = 1.0
		if tgt.node != null and tgt.node.has_method("get_part_dodge_modifier") and not dodge_eval_part.is_empty():
			part_mod = tgt.node.get_part_dodge_modifier(dodge_eval_part)
		var effective_dodge_chance: float = dodge_chance * part_mod
		var full_dodge_prob: float = effective_dodge_chance * manager.DODGE_FULL_THRESHOLD
		var partial_dodge_avg_ratio: float = (manager.DODGE_PARTIAL_RATIO_MIN + 1.0) * 0.5
		var E_dodge: float = (1.0 - effective_dodge_chance) * 1.0 + effective_dodge_chance * (1.0 - manager.DODGE_FULL_THRESHOLD) * partial_dodge_avg_ratio
		var parry_full: bool = is_block_parry and parry_c_d >= (parry_p_a * manager.PARRY_DEFLECT_THRESHOLD)
		var r_bonus: float = pcfg.get("redirect_bonus", 0.18)
		var r_scale: float = pcfg.get("redirect_skill_scale", 0.35)
		var redirect_skill: float = clampf((float(tgt.stats.get("agility", 100)) + float(tgt.stats.get("perception", 100))) / 200.0, 0.5, 1.5)
		var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
		if attack_type == WeaponConstants.ATTACK_TYPE_STAB:
			redirect_mult *= 1.0 + pcfg.get("redirect_thrust_bonus", 0.22)
		elif attack_type == WeaponConstants.ATTACK_TYPE_BLUNT:
			redirect_mult *= 1.0 - pcfg.get("redirect_blunt_penalty", 0.12)
		if not is_block_parry and m_a_parry > 0.001 and m_d_parry < m_a_parry:
			var mass_bonus: float = pcfg.get("mass_disparity_bonus", 0.18) * (1.0 - m_d_parry / m_a_parry)
			redirect_mult *= 1.0 + mass_bonus
		var parry_remaining_est: float = 1.0
		if not parry_full and parry_p_a > 0.001:
			parry_remaining_est = clampf(maxf(0.0, parry_p_a - parry_c_d * redirect_mult) / parry_p_a, 0.0, 1.0)
		var glancing_exp: float = pcfg.get("glancing_exponent", 0.5)
		var E_parry: float = 0.0 if parry_full else pow(parry_remaining_est, glancing_exp)
		var dodge_better: bool = E_dodge < E_parry
		var clean_dodge_likely: bool = full_dodge_prob >= manager.PARRY_PREFER_DODGE_FULL_THRESHOLD
		choose_parry = late_parry or ((block_viable or redirect_viable) and not dodge_better and not clean_dodge_likely)
	var defense_choice: String = "parry" if choose_parry else "dodge"
	if not def_has_weapon:
		print("[Combat] Defense choice: %s -> %s (unarmed; dodge only)" % [tgt_name, defense_choice])
	elif not can_parry_in_time:
		print("[Combat] Defense choice: %s -> %s (cannot parry in time; reaction too slow or no weapon)" % [tgt_name, defense_choice])
	else:
		var parry_reason: String = "parry" if choose_parry else "dodge"
		if late_parry:
			parry_reason = "parry (late/reflex)"
		elif choose_parry and desperate_parry and not (is_block_parry and block_viable) and parry_p_a > parry_c_d * effective_redirect:
			parry_reason = "parry (desperate, dodge=%.2f)" % dodge_chance
		elif not choose_parry and def_has_weapon:
			parry_reason = "dodge (expected better or clean avoid likely)"
		print("[Combat] Defense choice: %s -> %s (block=%s p_a=%.1f c_d=%.1f %s)" % [tgt_name, defense_choice, is_block_parry, parry_p_a, parry_c_d, parry_reason])

	if already_used_defense:
		print("[Combat] Partial parry follow-through: %s -> %s (no second defense, resolving damage)" % [atk_name, tgt_name])
	elif defense_choice == "dodge":
		var dodge_target_part: String = dodge_eval_part if not dodge_eval_part.is_empty() else BodyPartConstants.get_weighted_random_part(targetable)
		var part_mod: float = 1.0
		if tgt.node != null and tgt.node.has_method("get_part_dodge_modifier"):
			part_mod = tgt.node.get_part_dodge_modifier(dodge_target_part)
		var effective_dodge_chance: float = dodge_chance * part_mod
		var dodge_roll: float = randf()
		if effective_dodge_chance > 0.0:
			if dodge_roll < effective_dodge_chance * manager.DODGE_FULL_THRESHOLD:
				print("[Combat] Dodge: %s (defender) dodge=%.2f eff=%.2f roll=%.3f => full dodge" % [tgt_name, dodge_chance, effective_dodge_chance, dodge_roll])
				var rec_dur: float = manager._recovery_duration(intensity, "dodge", recovery_mult, perf_mod, atk.stats.get("agility", 100))
				return { "action": "dodge", "target_id": target_id, "recovery_duration": rec_dur }
			elif dodge_roll < effective_dodge_chance:
				var partial_range: float = effective_dodge_chance * (1.0 - manager.DODGE_FULL_THRESHOLD)
				var t: float = (dodge_roll - effective_dodge_chance * manager.DODGE_FULL_THRESHOLD) / partial_range if partial_range > 0.001 else 1.0
				var dodge_remaining_ratio: float = lerpf(manager.DODGE_PARTIAL_RATIO_MIN, 1.0, clampf(t, 0.0, 1.0))
				pa["parry_remaining_ratio"] = dodge_remaining_ratio
				var atk_weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
				if atk_weapon != null:
					var attack_instance = AttackInstance.new(attack_type, intensity)
					attack_instance.archetype = archetype
					var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
					var glancing_factor: float = pow(clampf(dodge_remaining_ratio, 0.0, 1.0), 0.5)
					pa["velocity_m_s"] = v_intent * glancing_factor
				else:
					pa["velocity_m_s"] = -1.0
				pa["partial_dodge_part"] = dodge_target_part
				print("[Combat] Dodge: %s (defender) dodge=%.2f eff=%.2f roll=%.3f part=%s => partial (ratio=%.2f)" % [tgt_name, dodge_chance, effective_dodge_chance, dodge_roll, dodge_target_part, dodge_remaining_ratio])
			else:
				print("[Combat] Dodge: %s (defender) dodge=%.2f eff=%.2f roll=%.3f => hit (no dodge)" % [tgt_name, dodge_chance, effective_dodge_chance, dodge_roll])
	elif defense_choice == "parry":
		pa["passive_parry_attempted"] = true
		var c_d_final: float = parry_c_d
		if manager.PARRY_TECHNIQUE_VARIANCE > 0.0:
			var agi_var: float = float(tgt.stats.get("agility", 100))
			var variance_scale: float = clampf(1.0 - 0.5 * (agi_var - 100.0) / 100.0, 0.5, 1.0)
			var variance_eff: float = manager.PARRY_TECHNIQUE_VARIANCE * variance_scale
			c_d_final *= randf_range(1.0 - variance_eff, 1.0 + variance_eff)
		var def_name: String = tgt.node.name if tgt.node != null else "id:%d" % target_id
		print("[Combat] Passive parry (redirect-default): %s block=%s%s => c_d=%.1f vs p_a=%.1f" % [def_name, is_block_parry, " off_balance" if parry_off_balance else "", c_d_final, parry_p_a])
		var full_stop: bool = is_block_parry and c_d_final >= (parry_p_a * manager.PARRY_DEFLECT_THRESHOLD)
		if full_stop:
			var parry_intensity: float = pa.get("intensity", 0.5)
			var atk_perf: float = 1.0
			if atk.node != null and atk.node.has_method("get_performance_modifier"):
				atk_perf = atk.node.get_performance_modifier()
			var rec_dur: float = manager._recovery_duration(parry_intensity, "full_stop", recovery_mult, atk_perf, atk.stats.get("agility", 100))
			print("[Combat] Parry result: full stop (%s blocked %s) => attacker recovery debuff" % [def_name, atk_name])
			return { "action": "parry_deflect", "target_id": target_id, "recovery_duration": rec_dur }
		var attacker_weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
		var m_a: float = float(attacker_weapon.mass) if attacker_weapon != null else WeaponConstants.BASELINE_MASS_KG
		var agi_d: float = float(tgt.stats.get("agility", 100))
		var perc_d: float = float(tgt.stats.get("perception", 100))
		var redirect_skill: float = clampf((agi_d + perc_d) / 200.0, 0.5, 1.5)
		var r_bonus: float = pcfg.get("redirect_bonus", 0.18)
		var r_scale: float = pcfg.get("redirect_skill_scale", 0.35)
		var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
		# Physics: thrust easiest to redirect (point diverts with lateral force); blunt hardest (momentum-based).
		if attack_type == WeaponConstants.ATTACK_TYPE_STAB:
			redirect_mult *= 1.0 + pcfg.get("redirect_thrust_bonus", 0.22)
		elif attack_type == WeaponConstants.ATTACK_TYPE_BLUNT:
			redirect_mult *= 1.0 - pcfg.get("redirect_blunt_penalty", 0.12)
		# Mass disparity: light weapon deflects by angle (Fiore); can't absorb, so redirect capacity bonus.
		if not is_block_parry and m_a_parry > 0.001 and m_d_parry < m_a_parry:
			var mass_bonus: float = pcfg.get("mass_disparity_bonus", 0.18) * (1.0 - m_d_parry / m_a_parry)
			redirect_mult *= 1.0 + mass_bonus
		var effective_reduction: float = c_d_final * redirect_mult
		var remaining_momentum: float = maxf(0.0, parry_p_a - effective_reduction)
		var remaining_ratio: float = remaining_momentum / parry_p_a if parry_p_a > 0.0 else 0.0
		var glancing_exp: float = pcfg.get("glancing_exponent", 0.5)
		var glancing_factor: float = pow(clampf(remaining_ratio, 0.0, 1.0), glancing_exp)
		var v_reduced: float = (parry_p_a * glancing_factor) / m_a
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance) if attacker_weapon != null else 10.0
		var v_min_eff: float = v_intent * lerpf(manager.PARRY_V_MIN_NEAR_DEFLECT, manager.PARRY_V_MIN_FRACTION, clampf(remaining_ratio, 0.0, 1.0))
		pa["velocity_m_s"] = maxf(v_reduced, v_min_eff)
		pa["parry_remaining_ratio"] = remaining_ratio
		print("[Combat] Parry result: redirect/partial (%s vs %s) skill=%.2f mult=%.2f => v_reduced" % [def_name, atk_name, redirect_skill, redirect_mult])
		return { "action": "parry_partial", "target_id": target_id }

	var power: float = pa.get("power", -1.0)
	var follow_through: float = pa.get("follow_through", -1.0)
	var parry_remaining_ratio: float = pa.get("parry_remaining_ratio", 1.0)
	var dmg_velocity_override: float = pa.get("velocity_m_s", velocity_override)
	var part: String = pa.get("partial_dodge_part", "")
	if part.is_empty():
		part = BodyPartConstants.get_weighted_random_part(targetable)
	atk.pending_attack = {}
	var res: Dictionary = compute_and_apply_damage(
		manager, attacker_id, target_id, atk, tgt, part,
		intensity, attack_type, archetype, dmg_velocity_override, recovery_mult, perf_mod,
		power, follow_through, parry_remaining_ratio
	)
	return {
		"action": "hit",
		"target_id": target_id,
		"result_dict": res.result_dict,
		"recovery_duration": res.recovery_duration,
		"outcome": res.outcome
	}
