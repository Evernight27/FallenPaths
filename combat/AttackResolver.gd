class_name AttackResolver
extends RefCounted

const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _DefenseResolution := preload("res://combat/DefenseResolutionHandler.gd")
const _PathResolver := preload("res://combat/AttackPathResolver.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

static func _debug(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG:
		CombatDebug.log(msg)


## Multiplier applied to sharp/blunt penetration for oblique incidence (parry/deflect or misaligned guard).
## When `velocity_override` < 0, intensity-derived speed is used and this factor stays **1** (no oblique scaling here).
static func penetration_oblique_angle_factor(
	velocity_override: float, parry_remaining_ratio: float, alignment: float
) -> float:
	if velocity_override < 0.0:
		return 1.0
	var angle_factor: float = 1.0
	if parry_remaining_ratio < 1.0:
		var angle_min_p: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
		angle_factor = lerpf(1.0, angle_min_p, 1.0 - parry_remaining_ratio)
	elif parry_remaining_ratio >= 1.0 and alignment < 1.0:
		var align_scale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
		var angle_min_a: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
		angle_factor = lerpf(1.0, angle_min_a, (1.0 - alignment) * align_scale)
	return angle_factor


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
	_power: float = -1.0,
	_follow_through: float = -1.0,
	parry_remaining_ratio: float = 1.0,
	afterblow_damage_mult: float = 1.0,
	alignment: float = 1.0,
	strike_mods: Dictionary = {},
	strike_physics_ctx: Dictionary = {}
) -> Dictionary:
	var sm: Dictionary = strike_mods
	var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
	var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt_momentum_per_area: float = -1.0
	var blunt_contact_cm: float = -1.0
	var pre_cut: float = 0.0
	var pre_blunt: float = 0.0
	var strike_ke_j: float = -1.0
	var atk_n: Node = _EntityAccess.scene_node(atk)
	var tgt_n: Node = _EntityAccess.scene_node(tgt)

	var weapon = _EntityAccess.get_weapon(atk)

	if weapon != null and weapon.has_method("get_available_attack_types"):
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		attack_instance.strike_energy_mult = float(sm.get("strike_energy_mult", 1.0))
		attack_instance.strike_momentum_mult = float(sm.get("strike_momentum_mult", 1.0))
		var v_base: float = velocity_override if velocity_override >= 0.0 else WeaponDamageHelper.velocity_m_s_from_intensity(intensity, archetype, weapon, attack_type)
		attack_instance.velocity_m_s = v_base
		attack_instance.velocity_m_s *= _StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
		var atk_st_ratio_w: float = clampf(_EntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
		var stamina_vel_scale: float = sqrt(lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(atk_st_ratio_w)))
		attack_instance.velocity_m_s *= stamina_vel_scale
		if afterblow_damage_mult < 1.0:
			attack_instance.velocity_m_s *= sqrt(maxf(0.04, afterblow_damage_mult))
		attack_instance.velocity_m_s = clampf(attack_instance.velocity_m_s, _ImpactVelocityModel.ABS_VELOCITY_MIN_M_S, _ImpactVelocityModel.ABS_VELOCITY_MAX_M_S)
		var arm_mod: float = atk_n.get_attack_damage_modifier() if (atk_n != null and atk_n.has_method("get_attack_damage_modifier")) else 1.0
		var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, part)
		var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, attack_type, archetype)
		# Physics: deflected cut presents flat/slap; edge doesn't bite. Shift cut→blunt on partial parry.
		var move_contact: String = weapon.get_contact_type(attack_type) if weapon.has_method("get_contact_type") else WeaponConstants.ATTACK_TYPE_CUT
		if move_contact == WeaponConstants.ATTACK_TYPE_CUT and velocity_override >= 0.0 and parry_remaining_ratio < 1.0:
			var shift_const: float = CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT
			var redirect_shift: float = shift_const * (1.0 - parry_remaining_ratio)
			cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect_shift)
		var atk_str: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
		pre_cut = WeaponDamageHelper.compute_pre_armor_cut(weapon, attack_instance, atk_str, arm_mod) * cut_ratio
		pre_blunt = WeaponDamageHelper.compute_pre_armor_blunt(weapon, attack_instance, atk_str, arm_mod, target_mass) * (1.0 - cut_ratio)
		pre_cut *= float(sm.get("cut_damage_mult", 1.0))
		pre_blunt *= float(sm.get("blunt_damage_mult", 1.0))
		pre_armor = pre_cut + pre_blunt
		var pen_sharp_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, CombatConstants.DAMAGE_TYPE_SHARP)
		pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
		var blunt_opts: Dictionary = {}
		if tgt_n != null and tgt_n.has_method("get_armor_sharp_resistance_for_part"):
			blunt_opts["armor_resistance_rha_mm"] = tgt_n.get_armor_sharp_resistance_for_part(part)
		blunt_opts["pen_sharp_mm"] = pen_sharp
		blunt_opts["target_effective_mass_kg"] = target_mass
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, CombatConstants.DAMAGE_TYPE_BLUNT, blunt_opts)
		pen_blunt_momentum_per_area = pen_blunt_dict.get("penetration_blunt_momentum_per_area", -1.0)
		blunt_contact_cm = pen_blunt_dict.get("blunt_contact_cm", -1.0)
		# Angle (deflection): oblique impact = less penetration (armor research).
		var angle_factor: float = penetration_oblique_angle_factor(
			velocity_override, parry_remaining_ratio, alignment
		)
		if angle_factor < 1.0:
			if pen_sharp >= 0.0:
				pen_sharp *= angle_factor
			if pen_blunt_momentum_per_area >= 0.0:
				pen_blunt_momentum_per_area *= angle_factor
		if pen_sharp >= 0.0:
			pen_sharp *= float(sm.get("sharp_penetration_mult", 1.0))
		if pen_blunt_momentum_per_area >= 0.0:
			pen_blunt_momentum_per_area *= float(sm.get("blunt_momentum_pa_mult", 1.0))
		strike_ke_j = WeaponDamageHelper.compute_kinetic_energy_j(weapon, attack_instance)
		_debug("dmg %s->%s part=%s pre_armor=%.1f cut=%.1f blunt=%.1f pen=%.2f ke_j=%.1f" % [atk_name, tgt_name, part, pre_armor, pre_cut, pre_blunt, pen_sharp, strike_ke_j])
	else:
		var mod: float = atk_n.get_attack_damage_modifier() if (atk_n != null and atk_n.has_method("get_attack_damage_modifier")) else 1.0
		pre_armor = WeaponDamageHelper.unarmed_base_pre_armor(
			float(_EntityAccess.stats_dict(atk).get("strength", 100)), mod
		)
		if parry_remaining_ratio < 1.0:
			pre_armor *= lerpf(0.5, 1.0, parry_remaining_ratio)
		var atk_st_ratio_u: float = clampf(_EntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
		var stamina_u: float = sqrt(lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(atk_st_ratio_u)))
		var afterblow_u: float = sqrt(maxf(0.04, afterblow_damage_mult))
		pre_armor *= _StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx) * stamina_u * afterblow_u
		pre_blunt = pre_armor
		pre_cut = 0.0
		_debug("dmg %s->%s unarmed pre_armor=%.1f" % [atk_name, tgt_name, pre_armor])

	# Stance modifier (defensive ×0.85, aggressive ×1.2, etc.) — commitment, not raw speed.
	var stance_dmg_mult: float = CombatConstants.get_stance_modifier(_EntityAccess.stance_str(atk), "damage")
	pre_cut *= stance_dmg_mult
	pre_blunt *= stance_dmg_mult
	pre_armor = pre_cut + pre_blunt

	var health_before_cut: float = tgt_n.body_cutting.get(part, 0.0)
	var health_before_blunt: float = tgt_n.body_blunt.get(part, 0.0)
	var health_before_bone: float = tgt_n.bone_health.get(part, 0.0) if tgt_n.get("bone_health") else 0.0

	var dmg_extras: Dictionary = {}
	if strike_ke_j >= 0.0:
		dmg_extras["strike_ke_j"] = strike_ke_j
	var take_result: Dictionary = tgt_n.take_damage_split(
		pre_cut, pre_blunt, part, pen_sharp, pen_blunt_momentum_per_area, blunt_contact_cm, dmg_extras
	)

	var final_cut: float = take_result.get("final_cut", 0.0)
	var final_blunt: float = take_result.get("final_blunt", 0.0)
	var final_bone: float = take_result.get("final_bone", 0.0)
	# total_physical: authoritative chip for UI/logs. dmg: int rounded for compact compat.
	var total_physical: float = final_cut + final_blunt + final_bone
	var actual_dmg: int = int(roundf(total_physical))
	var tissue_dmg: float = final_cut + final_blunt
	var outcome: String = "hit"
	var glancing_severity: float = -1.0
	var mech_post_armor: float = float(take_result.get("mechanical_post_armor", -1.0))
	var glance_denom: float = pre_armor
	if mech_post_armor > 0.0:
		glance_denom = mech_post_armor
	if pre_armor > 0:
		if total_physical <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
			outcome = "deflected"
		elif tissue_dmg < glance_denom * CombatConstants.GLANCING_DAMAGE_RATIO:
			outcome = "glancing"
			var ratio_denom: float = glance_denom * CombatConstants.GLANCING_DAMAGE_RATIO
			glancing_severity = clampf(tissue_dmg / maxf(ratio_denom, 0.001), 0.0, 1.0)

	var rounded_zero_chip: bool = actual_dmg == 0 and total_physical > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS
	if rounded_zero_chip and outcome == "hit":
		outcome = "negligible"

	var tgt_entity: Node = _EntityAccess.get_health_entity_from_node(manager, tgt_n)
	if tgt_entity == null:
		tgt_entity = tgt_n
	_StatsSync.sync_from_entity(tgt_entity, _EntityAccess.stats_dict_for_mutation(tgt))

	var health_after_cut: float = tgt_entity.body_cutting.get(part, 0.0)
	var health_after_blunt: float = tgt_entity.body_blunt.get(part, 0.0)
	var health_after_bone: float = tgt_entity.bone_health.get(part, 0.0) if tgt_entity.get("bone_health") else 0.0
	var part_max: int = tgt_entity.body_max.get(part, 0)
	var part_bone_max: int = tgt_entity.bone_max.get(part, 0) if tgt_entity.get("bone_max") else 0
	var outcome_note: String = outcome
	if outcome == "deflected":
		outcome_note = "deflected (all damage avoided)"
	elif outcome == "glancing":
		outcome_note = "glancing (tissue_dmg %.2f < post_armor_mech*%.2f=%.2f; pre_armor=%.1f)" % [tissue_dmg, CombatConstants.GLANCING_DAMAGE_RATIO, glance_denom * CombatConstants.GLANCING_DAMAGE_RATIO, pre_armor]
	elif outcome == "negligible":
		outcome_note = "negligible (contact; phys %.4f rounds to 0 HP)" % total_physical
	elif rounded_zero_chip:
		outcome_note = "%s | sub-threshold chip (phys %.4f rounds to 0)" % [outcome_note, total_physical]

	var total_disp: String = str(actual_dmg)
	if rounded_zero_chip:
		total_disp = "0 (~%.3f phys)" % total_physical
	elif absf(total_physical - float(actual_dmg)) > 0.01:
		total_disp = "%d (phys %.3f)" % [actual_dmg, total_physical]

	if CombatConstants.COMBAT_DEBUG:
		var depth_extra: String = ""
		if _EntityAccess.rank_int(atk) > 0 and _ActionsBuilder._melee_pair_rank_allowed(manager, atk, tgt):
			var cls: float = _StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
			var lane_lbl: String = str(strike_physics_ctx.get("depth_polearm_lane_type", ""))
			if lane_lbl.is_empty():
				lane_lbl = "-"
			depth_extra = " | depth_polearm rank=%d lane=%s closing_spd=%.3f tgt_angle=%s" % [
				_EntityAccess.rank_int(atk),
				lane_lbl,
				cls,
				str(tgt.get("engagement_angle", "?"))
			]
		var hit_line: String = (
			"[Combat] %s (%s) -> %s (%s) %s | cut=%.2f blunt=%.2f bone=%.2f | total=%s | outcome: %s%s"
			% [
				atk_name,
				_EntityAccess.side_str(atk),
				tgt_name,
				_EntityAccess.side_str(tgt),
				part,
				final_cut,
				final_blunt,
				final_bone,
				total_disp,
				outcome_note,
				depth_extra
			]
		)
		print(hit_line)
		if CombatConstants.COMBAT_DEBUG_CALIBRATION:
			print("  └ part state: cut %.2f→%.2f blunt %.2f→%.2f bone %.2f→%.2f | max c/b %d bone %d" % [health_before_cut, health_after_cut, health_before_blunt, health_after_blunt, health_before_bone, health_after_bone, part_max, part_bone_max])

	var result_dict: Dictionary = {
		"dmg": actual_dmg,
		"total_physical": total_physical,
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
		# Armor sharp→blunt conversion; unrelated to outcome "deflected" (no net physical chip).
		"was_deflected": take_result.get("was_deflected", false),
		"was_glancing": outcome == "glancing",
		"was_negligible": outcome == "negligible",
		"mechanical_post_armor": mech_post_armor,
		"rounded_zero_chip": rounded_zero_chip
	}
	result_dict["health_before"] = int(roundf(health_before_cut + health_before_blunt))
	result_dict["health_after"] = int(roundf(health_after_cut + health_after_blunt))
	# Headless harness only: `CombatRegressionHarness` sets meta on the manager before `compute_and_apply_damage`.
	if manager != null and bool(manager.get_meta("_harness_expose_penetration_applied", false)):
		result_dict["penetration_sharp_applied"] = pen_sharp
		result_dict["penetration_blunt_mpa_applied"] = pen_blunt_momentum_per_area

	if tgt_n != null and tgt_n.has_method("is_dead") and tgt_n.is_dead():
		tgt.alive = false
		tgt.state = CombatConstants.STATE_DEAD
		result_dict["died"] = true
		var death_reason: String = ""
		if tgt_n.has_method("get_death_reason"):
			death_reason = tgt_n.get_death_reason()
		print("[Combat] DEATH: %s — %s" % [tgt_name, death_reason])

	var rec_dur: float = CombatTiming.recovery_duration(intensity, outcome, recovery_mult, perf_mod, _EntityAccess.stats_dict(atk).get("agility", 100), glancing_severity)
	return {
		"result_dict": result_dict,
		"outcome": outcome,
		"recovery_duration": rec_dur
	}

## Full attack resolution: miss, dodge, parry (deflect/partial), or hit.
## Manager must have: _get_by_id, STATE_*; timing uses CombatTiming.
## _get_passive_parry_readiness, _is_off_balance, MISS_CHANCE_BASE, HIT_CHANCE_*, COMMITMENT_FRACTION, PARRY_*, etc.
## Returns { "action": String, "target_id": int, "result_dict": {}, "recovery_duration": float, "outcome": String }.
## Weighted roll for diagonal C: pick attack_line from weights dict (line -> weight).
static func _weighted_roll_attack_line(weights: Dictionary) -> String:
	var total: float = 0.0
	for w in weights.values():
		total += float(w)
	if total <= 0.0:
		return "high"
	var r: float = randf() * total
	for line in weights:
		r -= float(weights[line])
		if r <= 0.0:
			return line
	return weights.keys()[0] if not weights.is_empty() else "high"

## For parry_partial, mutates atk.pending_attack["velocity_m_s"] and defense sets **`parry_clash_context`** on the result dict; **`AttackResultApplier`** emits **`action_resolved`** then re-enters **`_execute_attack`** for follow-through.
static func resolve_attack(manager: Node, attacker_id: int) -> Dictionary:
	var atk = manager._get_by_id(attacker_id)
	if atk == null:
		return { "action": "skip", "target_id": -1, "recovery_duration": 0.0 }
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	if pa.is_empty():
		return { "action": "skip", "target_id": -1, "recovery_duration": 0.0 }
	var target_id: int = pa.target_id
	var intensity: float = pa.intensity
	var attack_type: String = pa.get("attack_type", WeaponConstants.ATTACK_TYPE_CUT)
	var archetype: Dictionary = _EntityAccess.nested_dictionary_read(pa, "archetype")
	var velocity_override: float = pa.get("velocity_m_s", -1.0)
	var tgt = manager._get_by_id(target_id)
	if tgt == null or not _EntityAccess.alive_bool(tgt):
		return { "action": "skip", "target_id": target_id, "recovery_duration": 0.0 }
	var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
	var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
	_debug("attack %s -> %s %s" % [atk_name, tgt_name, attack_type])

	var recovery_mult: float = float(archetype.get("recovery_multiplier", 1.0))
	var atk_perf_mod: float = _EntityAccess.get_performance_modifier(atk)
	if _EntityAccess.get_attacking_arm(atk).is_empty():
		var rec_dur_skip: float = CombatTiming.recovery_duration(intensity, "hit", recovery_mult, atk_perf_mod, _EntityAccess.stats_dict(atk).get("agility", 100))
		print("[Combat] %s has no functional arm; skips attack. intensity=%.2f => recovery=%.2fs" % [atk_name, intensity, rec_dur_skip])
		return { "action": "skip", "target_id": target_id, "recovery_duration": rec_dur_skip }

	var targetable: Array = _EntityAccess.get_targetable_parts(tgt)
	if targetable.is_empty():
		return { "action": "defeated", "target_id": target_id }
	var fid_atk_resolve: String = (
		_ZoneOfControl.formation_id_for_zone_geometry(manager, atk)
		if _EntityAccess.rank_int(atk) > 0
		else ""
	)
	var want_depth_part_log: bool = (
		CombatDebug.flow_verbose_enabled()
		and not fid_atk_resolve.is_empty()
		and _ActionsBuilder.depth_polearm_lane_open(manager, atk, fid_atk_resolve)
	)
	var n_targetable_before: int = targetable.size() if want_depth_part_log else 0
	targetable = _ActionsBuilder.depth_polearm_targetable_parts_filter(manager, atk, targetable)
	if want_depth_part_log and targetable.size() < n_targetable_before:
		var fd_atk_log: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, atk, fid_atk_resolve)
		var dens_log: String = str(fd_atk_log.get("density", "normal")) if not fd_atk_log.is_empty() else "normal"
		CombatDebug.flow_log(
			"depth_polearm_resolve_parts atk=%d tgt=%d dens=%s parts=%s"
			% [attacker_id, target_id, dens_log, str(targetable)],
			"depth_polearm_resolve:%d:%d" % [attacker_id, target_id]
		)
	if targetable.is_empty():
		return { "action": "defeated", "target_id": target_id }

	var atk_wep: Variant = _EntityAccess.get_weapon(atk)
	if (
		atk_wep != null
		and atk_wep.has_method("get_available_attack_types")
		and not _ActionsBuilder.can_melee_threaten(manager, atk, tgt)
	):
		_TacticalCombat.record_invalid_melee_resolve_blocked(manager)
		var rec_geom: float = CombatTiming.recovery_duration(
			intensity, "miss", recovery_mult, atk_perf_mod, _EntityAccess.stats_dict(atk).get("agility", 100)
		)
		_debug("abort resolve: can_melee_threaten false atk=%d tgt=%d" % [attacker_id, target_id])
		return { "action": "skip", "target_id": target_id, "recovery_duration": rec_geom }

	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(manager, atk, tgt, pa)

	var perf_mod: float = _EntityAccess.get_hit_chance_performance_modifier(atk)
	var perception_factor: float = clampf(float(_EntityAccess.stats_dict(atk).get("perception", 100)) / 100.0, CombatConstants.HIT_CHANCE_PERCEPTION_MIN, CombatConstants.HIT_CHANCE_PERCEPTION_MAX)
	var effective_hit_chance: float = (1.0 - CombatConstants.MISS_CHANCE_BASE) * perf_mod * perception_factor
	var miss_chance: float = 1.0 - effective_hit_chance
	var miss_roll: float = randf()
	if miss_roll < miss_chance:
		_debug("miss %s->%s roll=%.3f" % [atk_name, tgt_name, miss_roll])
		var rec_dur: float = CombatTiming.recovery_duration(intensity, "miss", recovery_mult, perf_mod, _EntityAccess.stats_dict(atk).get("agility", 100))
		return { "action": "miss", "target_id": target_id, "recovery_duration": rec_dur }
	_debug("hit_roll %s->%s roll=%.3f" % [atk_name, tgt_name, miss_roll])

	# Diagonal C: alignment-weighted roll for diagonal moves. Store effective_attack_line for parry/path/hit.
	# Angle-based: store attack_angle_deg for continuous trajectory (deflection, alignment, damage).
	var move_def_pre: Dictionary = WeaponConstants.get_move(attack_type)
	var atk_line_base: String = move_def_pre.get("attack_line", "high")
	if CombatConstants.DIAGONAL_WEIGHTS.has(attack_type):
		var guard_line_def: String = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
		var weights: Variant = CombatConstants.DIAGONAL_WEIGHTS[attack_type].get(guard_line_def, {})
		if weights is Dictionary and not weights.is_empty():
			atk_line_base = _weighted_roll_attack_line(weights)
		pa["effective_attack_line"] = atk_line_base
	var arc_start: float = pa.get("arc_start_deg", CombatConstants.line_to_angle(atk_line_base))
	var var_ctx: Dictionary = {}
	var s: float = _EntityAccess.stamina_float(atk)
	var_ctx["stamina_ratio"] = clampf(s / CombatConstants.STAMINA_MAX, 0.0, 1.0)
	var_ctx["off_balance"] = _PassiveParry.is_off_balance(atk)
	var atk_weapon = _EntityAccess.get_weapon(atk)
	var_ctx["weapon_mass_kg"] = float(atk_weapon.mass) if atk_weapon != null and (atk_weapon.get("mass") is float or atk_weapon.get("mass") is int) else CombatConstants.ANGLE_VARIANCE_MASS_REFERENCE_KG
	pa["attack_angle_deg"] = CombatConstants.get_attack_angle_deg(atk_line_base, true, move_def_pre, var_ctx)
	pa["attack_angle_deg"] = _Footwork.apply_offset_to_angle_deg(pa["attack_angle_deg"], atk)
	pa["position_angle_offset_deg"] = _Footwork.get_attacker_offset_deg(atk)
	pa["arc_end_deg"] = pa["attack_angle_deg"]
	pa["arc_span_deg"] = CombatConstants.angle_diff_deg(arc_start, pa["arc_end_deg"])

	var zone_mult: float = _ZoneOfControl.get_engagement_parry_multiplier(manager, attacker_id, target_id)
	pa["zone_engagement_parry_mult"] = zone_mult
	if zone_mult <= CombatConstants.REAR_PARRY_MOD + 0.001:
		tgt["engagement_angle"] = "rear"
	elif zone_mult <= CombatConstants.FLANK_PARRY_MOD + 0.001:
		tgt["engagement_angle"] = "flank"
	else:
		tgt["engagement_angle"] = "front"

	pa["surround_threat_count"] = _TacticalCombat.count_engaging_threats(manager, target_id)
	if CombatConstants.is_feature_sector_surround_load():
		pa["surround_threat_weight_sum"] = _TacticalCombat.compute_surround_threat_weight_sum(manager, target_id)
	pa["tactical_ambush_mult"] = _TacticalCombat.ambush_defense_multiplier(manager, tgt)
	if atk_weapon != null:
		pa["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			manager, atk, tgt, atk_weapon, float(pa.get("effective_pair_eff_dist", -1.0))
		)
		if str(pa.get("move_contact_type", "")).is_empty():
			pa["move_contact_type"] = WeaponConstants.contact_type_for_move_id(attack_type)
	else:
		pa["strike_measure_ratio"] = 1.0

	var dc: Dictionary = _DefenseChoice.choose_defense(pa, atk, tgt, targetable, attack_type, archetype, velocity_override)
	var _already_used_defense: bool = pa.get("passive_parry_attempted", false)
	var defense_choice: String = dc.defense
	var can_parry_in_time: bool = dc.can_parry_in_time
	var parry_p_a: float = dc.parry_p_a
	var parry_c_d: float = dc.parry_c_d
	var _parry_time_to_react: float = dc.parry_time_to_react
	var parry_readiness: float = dc.parry_readiness
	var _parry_off_balance: bool = dc.parry_off_balance
	var late_parry: bool = dc.late_parry
	var is_block_parry: bool = dc.is_block_parry
	var _m_a_parry: float = dc.m_a_parry
	var _m_d_parry: float = dc.m_d_parry
	var dodge_chance: float = dc.dodge_chance
	var _dodge_eval_part: String = dc.dodge_eval_part
	var effective_redirect: float = dc.effective_redirect
	var def_has_weapon: bool = _EntityAccess.has_weapon(tgt)
	if not def_has_weapon:
		_debug("defense %s unarmed -> %s" % [tgt_name, defense_choice])
	elif not can_parry_in_time:
		_debug("defense %s no parry time -> %s" % [tgt_name, defense_choice])
	else:
		var _parry_reason: String = "parry" if defense_choice == "parry" else "dodge"
		if late_parry:
			_parry_reason = "parry (late/reflex)"
		elif defense_choice == "parry" and dodge_chance < CombatConstants.PARRY_DESPERATE_DODGE_THRESHOLD and not (is_block_parry and parry_p_a <= parry_c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO) and parry_p_a > parry_c_d * effective_redirect:
			_parry_reason = "parry (desperate, dodge=%.2f)" % dodge_chance
		elif defense_choice == "dodge" and def_has_weapon:
			_parry_reason = "dodge (expected better or clean avoid likely)"
		_debug("defense %s -> %s block=%s p_a=%.1f c_d=%.1f" % [tgt_name, defense_choice, is_block_parry, parry_p_a, parry_c_d])

	var defense_result = _DefenseResolution.resolve(
		pa, atk, tgt, dc, targetable, attack_type, intensity, archetype,
		velocity_override, recovery_mult, perf_mod, target_id, atk_name, tgt_name
	)
	if defense_result != null:
		return defense_result

	var power: float = pa.get("power", -1.0)
	var follow_through: float = pa.get("follow_through", -1.0)
	var parry_remaining_ratio: float = pa.get("parry_remaining_ratio", 1.0)
	var afterblow_damage_mult: float = pa.get("afterblow_damage_mult", 1.0)
	var dmg_velocity_override: float = pa.get("velocity_m_s", velocity_override)
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var atk_line: String = pa.get("effective_attack_line", move_def.get("attack_line", "high"))
	var guard_line: String = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
	var atk_angle: float = pa.get("attack_angle_deg", CombatConstants.line_to_angle(atk_line))
	var wobble_hit: Dictionary = {}
	if pa.get("passive_parry_attempted", false):
		var def_weapon_hit = _EntityAccess.get_weapon(tgt)
		var def_mass_hit: float = float(def_weapon_hit.mass) if def_weapon_hit != null and (def_weapon_hit.get("mass") is float or def_weapon_hit.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
		wobble_hit = {"parry_readiness": parry_readiness, "defender_mass_kg": def_mass_hit}
	var guard_angle: float = CombatConstants.get_guard_angle_deg(tgt, wobble_hit)
	var align_ctx: Dictionary = {"attack_angle_deg": atk_angle, "guard_angle_deg": guard_angle}
	var hit_alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx, wobble_hit)
	var part: String = pa.get("partial_dodge_part", "")
	if part.is_empty():
		# Path + guard intercept; defender_ctx and intended_part refine hit distribution. Angle-based trajectory.
		var defender_ctx: Dictionary = {
			"state": _EntityAccess.state_str(tgt),
			"recovery_cause": tgt.get("recovery_cause", ""),
			"passive_parry_attempted": pa.get("passive_parry_attempted", false)
		}
		var intended_part: String = pa.get("target_part", "")
		part = _PathResolver.resolve_hit_part(atk_line, guard_line, targetable, defender_ctx, intended_part, tgt, align_ctx)
		if part.is_empty():
			part = BodyPartConstants.get_weighted_random_part(targetable)
	atk["last_move_id"] = pa.get("attack_type", "")
	atk["effective_attack_line"] = pa.get("effective_attack_line", "")
	var strike_mods: Dictionary = {}
	if atk_weapon != null:
		strike_mods = _StrikeRealism.compute_strike_modifiers(
			manager, atk, tgt, atk_weapon, attack_type, intensity, archetype, hit_alignment, parry_remaining_ratio, pa
		)
	var strike_phys_ctx: Dictionary = {
		"tactical_ambush_mult": float(pa.get("tactical_ambush_mult", 1.0)),
		"attack_type": attack_type,
		"depth_polearm_attack": bool(pa.get("depth_polearm_attack", false)),
		"depth_polearm_lane_type": str(pa.get("depth_polearm_lane_type", "")),
		"depth_polearm_allows_low_targets": bool(pa.get("depth_polearm_allows_low_targets", true)),
	}
	_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa)
	atk.pending_attack = {}
	var res: Dictionary = compute_and_apply_damage(
		manager, attacker_id, target_id, atk, tgt, part,
		intensity, attack_type, archetype, dmg_velocity_override, recovery_mult, perf_mod,
		power, follow_through, parry_remaining_ratio, afterblow_damage_mult, hit_alignment, strike_mods,
		strike_phys_ctx
	)
	return {
		"action": "hit",
		"target_id": target_id,
		"result_dict": res.result_dict,
		"recovery_duration": res.recovery_duration,
		"outcome": res.outcome,
		"intensity": intensity
	}
