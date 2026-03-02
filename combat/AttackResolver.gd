class_name AttackResolver
extends RefCounted

## Computes pre-armor damage, applies take_damage_split, and builds the result dict for one attack.
## Manager must have: _get_entity(node), DAMAGE_TYPE_SHARP, DAMAGE_TYPE_BLUNT, GLANCING_DAMAGE_RATIO.
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
	follow_through: float = -1.0
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
		print("[Damage equation] %s -> %s | power=%.2f follow_through=%.2f intensity=%.2f | v=%.2f m/s mass=%.2f kg KE=%.1f J | strength=%.2f arm=%.2f cut_ratio=%.2f => pre_armor=%.1f (cut=%.1f blunt=%.1f) | pen_sharp=%.2f mm RHA" % [atk_name, tgt_name, power, follow_through, intensity, v_m_s, mass_kg, ke_j, float(atk.stats.strength) / 100.0, arm_mod, cut_ratio, pre_armor, pre_cut, pre_blunt, pen_sharp])
	else:
		var mod: float = atk.node.get_attack_damage_modifier() if (atk.node != null and atk.node.has_method("get_attack_damage_modifier")) else 1.0
		pre_armor = (float(atk.stats.strength) / 100.0) * 8.0 * mod
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

## Full attack resolution: miss, dodge, parry (deflect/partial), or hit.
## Manager must have: _get_by_id, STATE_*, _recovery_duration, _get_parry_speed_m_s, _velocity_curve_factor,
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
	if not already_used_defense and tgt.state != manager.STATE_WIND_UP and tgt.state != manager.STATE_MEDICAL_WIND_UP:
		var wind_up_duration: float = pa.get("wind_up_duration", 0.5)
		var effective_wind_up: float = wind_up_duration * (1.0 - manager.COMMITMENT_FRACTION)
		if tgt.node != null and tgt.node.has_method("get_passive_parry_reaction_time") and tgt.node.has_method("get_weapon"):
			var def_weapon = tgt.node.get_weapon()
			if def_weapon != null and effective_wind_up > 0.0:
				var reaction_time: float = tgt.node.get_passive_parry_reaction_time()
				if reaction_time < effective_wind_up:
					var atk_weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
					if atk_weapon != null:
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
						var c_d_full: float = m_d * manager._get_parry_speed_m_s(def_weapon) * (s_d / manager.PARRY_STRENGTH_NORM)
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
	var choose_parry: bool = can_parry_in_time and parry_p_a <= parry_c_d * manager.PARRY_DODGE_STRENGTH_RATIO
	var defense_choice: String = "parry" if choose_parry else "dodge"
	if not can_parry_in_time:
		print("[Combat] Defense choice: %s -> %s (cannot parry in time; reaction too slow or no weapon)" % [tgt_name, defense_choice])
	else:
		print("[Combat] Defense choice: %s -> %s (can_parry_in_time p_a=%.1f c_d=%.1f ratio=%.2f %s)" % [tgt_name, defense_choice, parry_p_a, parry_c_d, parry_p_a / parry_c_d if parry_c_d > 0 else 0.0, "prefer parry" if choose_parry else "opponent stronger, prefer dodge"])

	if already_used_defense:
		print("[Combat] Partial parry follow-through: %s -> %s (no second defense, resolving damage)" % [atk_name, tgt_name])
	elif defense_choice == "dodge":
		if tgt.node != null and tgt.node.has_method("get_dodge_chance"):
			var dodge_chance: float = tgt.node.get_dodge_chance()
			var dodge_roll: float = randf()
			if dodge_chance > 0.0 and dodge_roll < dodge_chance:
				print("[Combat] Dodge: %s (defender) dodge=%.2f roll=%.3f => dodged" % [tgt_name, dodge_chance, dodge_roll])
				var rec_dur: float = manager._recovery_duration(intensity, "dodge", recovery_mult, perf_mod, atk.stats.get("agility", 100))
				return { "action": "dodge", "target_id": target_id, "recovery_duration": rec_dur }
			elif dodge_chance > 0.0:
				print("[Combat] Dodge: %s (defender) dodge=%.2f roll=%.3f => hit (no dodge)" % [tgt_name, dodge_chance, dodge_roll])
	elif defense_choice == "parry":
		pa["passive_parry_attempted"] = true
		var c_d_final: float = parry_c_d
		if manager.PARRY_TECHNIQUE_VARIANCE > 0.0:
			var agi_var: float = float(tgt.stats.get("agility", 100))
			var variance_scale: float = clampf(1.0 - 0.5 * (agi_var - 100.0) / 100.0, 0.5, 1.0)
			var variance_eff: float = manager.PARRY_TECHNIQUE_VARIANCE * variance_scale
			c_d_final *= randf_range(1.0 - variance_eff, 1.0 + variance_eff)
		var def_name: String = tgt.node.name if tgt.node != null else "id:%d" % target_id
		var ob: String = " off_balance" if parry_off_balance else ""
		print("[Combat] Passive parry (A4v3): %s (reaction < wind_up) => time_to_react=%.2fs capacity_mult=%.2f readiness=%.2f%s => c_d=%.1f vs p_a=%.1f" % [def_name, parry_time_to_react, parry_capacity_mult, parry_readiness, ob, c_d_final, parry_p_a])
		var deflected: bool = c_d_final >= (parry_p_a * manager.PARRY_DEFLECT_THRESHOLD)
		if not deflected:
			var p_a_threshold: float = parry_p_a * manager.PARRY_DEFLECT_THRESHOLD
			print("[Combat] Parry result: partial (%s defended vs %s) c_d=%.1f < p_a*threshold=%.1f; attack continues with reduced velocity" % [def_name, atk_name, c_d_final, p_a_threshold])
			var attacker_weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
			var m_a: float = float(attacker_weapon.mass) if attacker_weapon != null else WeaponConstants.BASELINE_MASS_KG
			var remaining_momentum: float = maxf(0.0, parry_p_a - c_d_final)
			var v_reduced: float = remaining_momentum / m_a
			var remaining_ratio: float = (parry_p_a - c_d_final) / parry_p_a if parry_p_a > 0.0 else 1.0
			var attack_instance = AttackInstance.new(attack_type, intensity)
			attack_instance.archetype = archetype
			var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance) if attacker_weapon != null else 10.0
			var v_min_eff: float = v_intent * lerpf(manager.PARRY_V_MIN_NEAR_DEFLECT, manager.PARRY_V_MIN_FRACTION, clampf(remaining_ratio, 0.0, 1.0))
			pa["velocity_m_s"] = maxf(v_reduced, v_min_eff)
			return { "action": "parry_partial", "target_id": target_id }
		var parry_intensity: float = pa.get("intensity", 0.5)
		var atk_perf: float = 1.0
		if atk.node != null and atk.node.has_method("get_performance_modifier"):
			atk_perf = atk.node.get_performance_modifier()
		var rec_dur_parry: float = manager._recovery_duration(parry_intensity, "miss", recovery_mult, atk_perf, atk.stats.get("agility", 100))
		return { "action": "parry_deflect", "target_id": target_id, "recovery_duration": rec_dur_parry }

	var power: float = pa.get("power", -1.0)
	var follow_through: float = pa.get("follow_through", -1.0)
	atk.pending_attack = {}
	var part: String = BodyPartConstants.get_weighted_random_part(targetable)
	var res: Dictionary = compute_and_apply_damage(
		manager, attacker_id, target_id, atk, tgt, part,
		intensity, attack_type, archetype, velocity_override, recovery_mult, perf_mod,
		power, follow_through
	)
	return {
		"action": "hit",
		"target_id": target_id,
		"result_dict": res.result_dict,
		"recovery_duration": res.recovery_duration,
		"outcome": res.outcome
	}
