class_name AttackResolver
extends RefCounted

## Strike resolve pipeline: path, alignment, **`DefenseChoiceResolver.choose_defense`**, damage apply dispatch.
## Footing: PA stamp at resolve if **`effective_attack_line`** differs from wind-up (diagonal **C** roll); exchange end
## **`clear_on_exchange_end`** both sides. LIVE_PATHS **`#wf-tier-44-pa`**.

## Debug logging — delegates to `CombatDebug.log` which gates on `combat_debug_active`.


## Multiplier applied to sharp/blunt penetration for oblique incidence (parry/deflect or misaligned guard).
## When `velocity_override` < 0, intensity-derived speed is used and this factor stays **1** (no oblique scaling here).
## Parry branch wins when `parry_remaining_ratio` < 1 (partial contact already encodes obliquity). Otherwise misaligned
## guard uses the alignment scale against `PARRY_PENETRATION_ANGLE_MIN`.
static func penetration_oblique_angle_factor(
	velocity_override: float, parry_remaining_ratio: float, alignment: float
) -> float:
	if velocity_override < 0.0:
		return 1.0
	if parry_remaining_ratio < 1.0:
		return lerpf(1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, 1.0 - parry_remaining_ratio)
	if alignment < 1.0:
		return lerpf(
			1.0,
			CombatConstants.PARRY_PENETRATION_ANGLE_MIN,
			(1.0 - alignment) * CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
		)
	return 1.0


## Returns { "result_dict": Dictionary, "outcome": String, "recovery_duration": float }.
## Also updates tgt.stats (body_cutting, body_blunt, etc.) and tgt.alive/tgt.state if target died.
## `wind_up_factor` — optional multiplier from CombatTiming.wind_up_factor(); applied after velocity/KE but before
## armor penetration to model HEMA energy curve: shorter wind-ups deliver less strike energy regardless of intensity.


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
	strike_physics_ctx: Dictionary = {},
	wind_up_factor_override: float = -1.0
) -> Dictionary:
	var sm: Dictionary = strike_mods
	var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
	var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
	var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
	var atk_stats := CombatantEntityAccess.stats_dict(atk)
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt_momentum_per_area: float = -1.0
	var blunt_contact_cm: float = -1.0
	var pre_cut: float = 0.0
	var pre_blunt: float = 0.0
	var strike_ke_j: float = -1.0
	var tgt_n: Node = CombatantEntityAccess.scene_node(tgt)
	if tgt_n == null:
		CombatDebug.log("compute_and_apply_damage %s->%s target scene node freed, skip" % [atk_name, tgt_name])
		return {"action": "skip", "target_id": target_id, "recovery_duration": 0.0}

	var weapon = CombatantEntityAccess.get_weapon(atk)

	if CombatantEntityAccess.weapon_has_attack_types(weapon):
		var commit_frac: float = strike_physics_ctx.get(DataKeys.ARCHETYPE_WEAPON_EXTENSION_COMMIT_FRACTION, -1.0)
		if commit_frac < 0.0:
			commit_frac = CombatWeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move(attack_type))
		var delivery_intensity: float = WeaponDamageHelper.effective_intensity_for_delivery(intensity, commit_frac)
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		attack_instance.delivery_commit_fraction = commit_frac
		attack_instance.strike_energy_mult = sm.get(DataKeys.ATK_MOD_STRIKE_ENERGY_MULT, 1.0)
		attack_instance.strike_momentum_mult = sm.get(DataKeys.ATK_STRIKE_MOMENTUM_MULT, 1.0)
		var v_base: float = (
			velocity_override
			if velocity_override >= 0.0
			else WeaponDamageHelper.velocity_m_s_from_intensity(delivery_intensity, archetype, weapon, attack_type)
		)
		attack_instance.velocity_m_s = v_base
		attack_instance.velocity_m_s *= StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
		var atk_st_ratio_w: float = CombatantEntityAccess.stamina_ratio(atk)
		var stamina_vel_scale: float = sqrt(
			lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(atk_st_ratio_w))
		)
		var power_m: float = CombatExhaustion.power_mult_for_combatant(atk)
		attack_instance.velocity_m_s *= stamina_vel_scale * power_m
		if afterblow_damage_mult < 1.0:
			attack_instance.velocity_m_s *= sqrt(maxf(0.04, afterblow_damage_mult))
		var wuf: float = (
			wind_up_factor_override
			if wind_up_factor_override > 0.0
			else CombatTiming.wind_up_factor(pa.get(DataKeys.PA_WIND_UP_DURATION, CombatTiming.WIND_UP_FACTOR_OPTIMAL_S))
		)
		if wuf < 1.0:
			attack_instance.velocity_m_s *= wuf
		attack_instance.velocity_m_s = ImpactVelocityModel.clamp_velocity_m_s(attack_instance.velocity_m_s)
		var arm_mod: float = CombatantEntityAccess.get_attack_damage_modifier(atk)
		var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, part)
		var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, attack_type, archetype)
		# Physics: deflected cut presents flat/slap; edge doesn't bite. Shift cut|'blunt on partial parry.
		var move_contact: String = CombatantEntityAccess.weapon_contact_type(weapon, attack_type)
		if move_contact == WeaponConstants.ATTACK_TYPE_CUT and velocity_override >= 0.0 and parry_remaining_ratio < 1.0:
			var shift_const: float = CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT
			var redirect_shift: float = shift_const * (1.0 - parry_remaining_ratio)
			cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect_shift)
		var atk_str: float = float(
			atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)
		)
		pre_cut = WeaponDamageHelper.compute_pre_armor_cut(weapon, attack_instance, atk_str, arm_mod) * cut_ratio
		pre_blunt = WeaponDamageHelper.compute_blunt_slip_pre_armor(
			weapon, attack_instance, atk_str, arm_mod, cut_ratio, target_mass, sm.get(DataKeys.ATK_BLUNT_DAMAGE_MULT, 1.0)
		)
		pre_cut *= sm.get(DataKeys.ATK_MOD_CUT_DAMAGE_MULT, 1.0)
		pre_armor = pre_cut + pre_blunt
		var pen_sharp_dict: Dictionary = WeaponDamageHelper.compute_penetration(
			weapon, attack_instance, WeaponConstants.DAMAGE_TYPE_SHARP
		)
		pen_sharp = pen_sharp_dict.get(DataKeys.ATK_PENETRATION_SHARP, -1.0)
		var blunt_opts: Dictionary = {}
		var armor_rha: float = CombatArmorDoctrine.get_effective_rha_with_degradation(tgt, part)
		if armor_rha > 0.0:
			blunt_opts[DataKeys.BLUNT_OPT_ARMOR_RESISTANCE_RHA_MM] = armor_rha
		blunt_opts[DataKeys.BLUNT_OPT_PEN_SHARP_MM] = pen_sharp
		blunt_opts[DataKeys.BLUNT_OPT_TARGET_EFFECTIVE_MASS_KG] = target_mass
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(
			weapon, attack_instance, WeaponConstants.DAMAGE_TYPE_BLUNT, blunt_opts
		)
		pen_blunt_momentum_per_area = pen_blunt_dict.get(DataKeys.ATK_PENETRATION_BLUNT_MPA, -1.0)
		blunt_contact_cm = pen_blunt_dict.get(DataKeys.ATK_BLUNT_CONTACT_CM, -1.0)
		# Angle (deflection): oblique impact = less penetration (armor research).
		var angle_factor: float = penetration_oblique_angle_factor(velocity_override, parry_remaining_ratio, alignment)
		if angle_factor < 1.0:
			if pen_sharp >= 0.0:
				pen_sharp *= angle_factor
			if pen_blunt_momentum_per_area >= 0.0:
				pen_blunt_momentum_per_area *= angle_factor
		if pen_sharp >= 0.0:
			pen_sharp *= sm.get(DataKeys.ATK_MOD_SHARP_PENETRATION_MULT, 1.0)
		if pen_blunt_momentum_per_area >= 0.0:
			pen_blunt_momentum_per_area *= sm.get(DataKeys.ATK_BLUNT_MOMENTUM_PA_MULT, 1.0)
		strike_ke_j = WeaponDamageHelper.compute_kinetic_energy_j(weapon, attack_instance)
		CombatDebug.log(
			(
				"dmg %s->%s part=%s pre_armor=%.1f cut=%.1f blunt=%.1f pen=%.2f ke_j=%.1f v_final=%.2f v_base=%.2f ovr=%.1f i=%.2f st=%.2f pwr=%.2f exh=%.2f w=%s wuf=%.2f wdur=%.2f"
				% [
					atk_name,
					tgt_name,
					part,
					pre_armor,
					pre_cut,
					pre_blunt,
					pen_sharp,
					strike_ke_j,
					attack_instance.velocity_m_s,
					v_base,
					velocity_override,
					intensity,
					stamina_vel_scale,
					power_m,
					CombatantEntityAccess.exhaustion_float(atk),
					str(weapon.weapon_type if weapon != null and "weapon_type" in weapon else "?"),
					wuf,
					float(pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)),
				]
			)
		)
	else:
		var mod: float = CombatantEntityAccess.get_attack_damage_modifier(atk)
		pre_armor = WeaponDamageHelper.unarmed_base_pre_armor(
			float(atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)), mod
		)
		if parry_remaining_ratio < 1.0:
			var ctrl_mapped := 1.0 - parry_remaining_ratio
			var damage_reduction_factor := ctrl_mapped * CombatConstantsParry.PARRY_UNARMED_MAX_DAMAGE_REDUCTION
			pre_armor *= (1.0 - clampf(damage_reduction_factor, 0.0, 1.0))
		var unarmed_wind_up_dur: float = pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)
		var unarmed_wuf: float = CombatTiming.wind_up_factor(unarmed_wind_up_dur) if unarmed_wind_up_dur > 0.0 else 1.0
		var atk_st_ratio_u: float = CombatantEntityAccess.stamina_ratio(atk)
		var stamina_u: float = sqrt(
			lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(atk_st_ratio_u))
		)
		var power_m: float = CombatExhaustion.power_mult_for_combatant(atk)
		var afterblow_u: float = sqrt(maxf(0.04, afterblow_damage_mult))
		pre_armor *= (
			StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx) * stamina_u * power_m * afterblow_u
		)
		if unarmed_wuf < 1.0:
			pre_armor *= unarmed_wuf
		pre_blunt = pre_armor
		pre_cut = 0.0
		CombatDebug.log("dmg %s->%s unarmed pre_armor=%.1f" % [atk_name, tgt_name, pre_armor])

	# Stance modifier (defensive f - 0.85, aggressive f - 1.2, etc.) — commitment, not raw speed.
	var stance_dmg_mult: float = CombatWeaponForm.mod(
		CombatantEntityAccess.form_str(atk), "damage", weapon
	)
	pre_cut *= stance_dmg_mult
	pre_blunt *= stance_dmg_mult
	pre_armor = pre_cut + pre_blunt

	var health_before_cut: float = tgt_n.body_cutting.get(part, 0.0)
	var health_before_blunt: float = tgt_n.body_blunt.get(part, 0.0)
	var health_before_bone: float = tgt_n.bone_health.get(part, 0.0) if tgt_n.get(DataKeys.BONE_HEALTH) else 0.0

	var dmg_extras: Dictionary = {}
	if strike_ke_j >= 0.0:
		dmg_extras[DataKeys.RESULT_STRIKE_KE_J] = strike_ke_j
	var hit_sub: String = strike_physics_ctx.get(DataKeys.STRIKE_CTX_HIT_SUB_REGION, "").strip_edges()
	if not hit_sub.is_empty():
		dmg_extras[DataKeys.RESULT_HIT_SUB_REGION] = hit_sub
	if strike_physics_ctx.has(DataKeys.STRIKE_CTX_HIT_SUB_REGION_SEED):
		dmg_extras[DataKeys.RESULT_HIT_SUB_REGION_SEED] = int(strike_physics_ctx[DataKeys.STRIKE_CTX_HIT_SUB_REGION_SEED])
	var take_result: Dictionary = tgt_n.take_damage_split(
		pre_cut, pre_blunt, part, pen_sharp, pen_blunt_momentum_per_area, blunt_contact_cm, dmg_extras
	)

	var final_cut: float = take_result.get(DataKeys.RESULT_FINAL_CUT, 0.0)
	var final_blunt: float = take_result.get(DataKeys.RESULT_FINAL_BLUNT, 0.0)
	var final_bone: float = take_result.get(DataKeys.RESULT_FINAL_BONE, 0.0)
	# total_physical: authoritative chip for UI/logs. dmg: int rounded for compact compat.
	var total_physical: float = final_cut + final_blunt + final_bone
	# Minimum physical damage floor: ensure at least 1.0 before rounding, preventing
	# contact hits from being rounded to zero HP when tissue_mod / armor absorption reduces the value.
	const PHYSICAL_DAMAGE_MIN_FLOOR := 1.0
	var actual_dmg: int = int(roundf(total_physical))
	var tissue_dmg: float = final_cut + final_blunt
	var outcome: String = "hit"
	var glancing_severity: float = -1.0
	if total_physical > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
		if tissue_dmg < maxf(total_physical * CombatConstants.GLANCING_DAMAGE_RATIO, CombatConstants.GLANCING_DAMAGE_ABSOLUTE_FLOOR):
			outcome = "glancing"
			var ratio_denom: float = maxf(total_physical * CombatConstants.GLANCING_DAMAGE_RATIO, CombatConstants.GLANCING_DAMAGE_ABSOLUTE_FLOOR)
			glancing_severity = clampf(tissue_dmg / maxf(ratio_denom, 0.001), 0.0, 1.0)

	# Minimum physical damage floor for contact hits: prevents rounding to zero.
	var _floor_threshold: float = PHYSICAL_DAMAGE_MIN_FLOOR if outcome == "hit" else PHYSICAL_DAMAGE_MIN_FLOOR * 0.5
	if total_physical < _floor_threshold and outcome in ["hit", "glancing"]:
		total_physical = _floor_threshold
		actual_dmg = int(roundf(total_physical))
	var rounded_zero_chip: bool = actual_dmg == 0 and total_physical > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS
	if rounded_zero_chip and outcome == "hit":
		outcome = "negligible"

	## Record armor degradation on target — absorbed damage contributes to layer wear.
	var absorbed_armor_damage: float = maxf(0.0, pre_armor - total_physical)
	if absorbed_armor_damage > 0.0:
		CombatArmorDoctrine.record_armor_damage(tgt, part, absorbed_armor_damage)

	var tgt_entity: Node = CombatantEntityAccess.get_health_entity_from_node(manager, tgt_n)
	if tgt_entity == null:
		tgt_entity = tgt_n
	CombatantStatsSync.sync_from_entity(tgt_entity, CombatantEntityAccess.stats_dict_for_mutation(tgt))

	var health_after_cut: float = tgt_entity.body_cutting.get(part, 0.0)
	var health_after_blunt: float = tgt_entity.body_blunt.get(part, 0.0)
	var health_after_bone: float = tgt_entity.bone_health.get(part, 0.0) if tgt_entity.get(DataKeys.BONE_HEALTH) else 0.0
	var outcome_note: String = outcome
	if outcome == "deflected":
		outcome_note = "deflected (all damage avoided)"
	elif outcome == "glancing":
		outcome_note = (
												"glancing (tissue_dmg %.2f < total_phys*%.2f=%.2f; total_phys=%.1f)"
			% [
				tissue_dmg,
				CombatConstants.GLANCING_DAMAGE_RATIO,
				total_physical * CombatConstants.GLANCING_DAMAGE_RATIO,
				total_physical
			]
		)
	elif outcome == "negligible":
		outcome_note = "negligible (contact; phys %.4f rounds to 0 HP)" % total_physical
	elif rounded_zero_chip:
		outcome_note = "%s | sub-threshold chip (phys %.4f rounds to 0)" % [outcome_note, total_physical]

	var total_disp: String = str(actual_dmg)
	if rounded_zero_chip:
		total_disp = "0 (~%.3f phys)" % total_physical
	elif absf(total_physical - float(actual_dmg)) > 0.01:
		total_disp = "%d (phys %.3f)" % [actual_dmg, total_physical]

	if CombatConstants.combat_debug_active():
		var depth_extra: String = ""
		if (
			CombatantEntityAccess.rank_int(atk) > 0
			and CombatMeleeRankTargeting.melee_pair_rank_allowed(manager, atk, tgt)
		):
			var cls: float = StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
			var lane_lbl: String = strike_physics_ctx.get(DataKeys.PA_DEPTH_POLEARM_LANE, "")
			if lane_lbl.is_empty():
				lane_lbl = "-"
			depth_extra = (
																" | depth_polearm rank=%d lane=%s closing_spd=%.3f tgt_angle=%s"
				% [CombatantEntityAccess.rank_int(atk), lane_lbl, cls, str(tgt.get(DataKeys.PA_ENGAGEMENT_ANGLE, "?"))]
			)
		var hit_line: String = (
												"[Combat] %s (%s) -> %s (%s) %s | cut=%.2f blunt=%.2f bone=%.2f | total=%s | outcome: %s%s"
			% [
				atk_name,
				CombatantEntityAccess.side_str(atk),
				tgt_name,
				CombatantEntityAccess.side_str(tgt),
				part,
				final_cut,
				final_blunt,
				final_bone,
				total_disp,
				outcome_note,
				depth_extra
			]
		)
		if CombatConstants.COMBAT_DEBUG_CALIBRATION:
			CombatDebug.combat_session(hit_line)

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
		# Armor sharp|'blunt conversion; unrelated to outcome "deflected" (no net physical chip).
		"was_deflected": take_result.get(DataKeys.ATTACK_WAS_DEFLECTED, false),
		"was_glancing": outcome == "glancing",
		"was_negligible": outcome == "negligible",
		"mechanical_post_armor": take_result.get(DataKeys.RESULT_MECHANICAL_POST_ARMOR, 0.0),
		"rounded_zero_chip": rounded_zero_chip,
		"tissue_dmg": tissue_dmg,
		"pre_armor": pre_armor,
	}
	result_dict[DataKeys.RESULT_DAMAGE_RESOLVE_NOTE] = CombatLogFormatter.damage_resolve_note(result_dict)
	result_dict[DataKeys.RESULT_HEALTH_BEFORE] = int(roundf(health_before_cut + health_before_blunt))
	result_dict[DataKeys.RESULT_HEALTH_AFTER] = int(roundf(health_after_cut + health_after_blunt))
	# Headless harness only: `CombatRegressionHarness` sets meta on the manager before `compute_and_apply_damage`.
	if manager != null and bool(manager.get_meta("_harness_expose_penetration_applied", false)):
		result_dict[DataKeys.RESULT_PENETRATION_SHARP_APPLIED] = pen_sharp
		result_dict[DataKeys.RESULT_PENETRATION_BLUNT_MPA_APPLIED] = pen_blunt_momentum_per_area
	if manager != null and bool(manager.get_meta("_harness_expose_damage_kinematics", false)):
		result_dict[DataKeys.RESULT_STRIKE_KE_J_APPLIED] = strike_ke_j
		result_dict[DataKeys.RESULT_BLUNT_CONTACT_CM_APPLIED] = blunt_contact_cm
		result_dict[DataKeys.RESULT_PRE_CUT_APPLIED] = pre_cut
		result_dict[DataKeys.RESULT_PRE_BLUNT_APPLIED] = pre_blunt

	if CombatantEntityAccess.is_dead(tgt):
		tgt.alive = false
		CombatFootwork.clear_on_death(tgt)
		tgt.state = CombatConstants.STATE_DEAD
		CombatStateHandlers.cancel_events_for_dead_combatant(manager, tgt)
		result_dict[DataKeys.RESULT_DIED] = true
		# F5: `hit_resolve` + combat log carry strike outcome; skip redundant DEATH line.
		if not (OperationalLog.is_play_session_active() and CombatConstants.combat_hit_summary_active()):
			CombatDebug.combat_session("DEATH %s -- %s" % [tgt_name, CombatantEntityAccess.get_death_reason(tgt)])

	var rec_dur: float = CombatTiming.recovery_duration(
		intensity,
		outcome,
		recovery_mult,
		perf_mod,
		atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
		glancing_severity
	)
	return {"result_dict": result_dict, "outcome": outcome, "recovery_duration": rec_dur}


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


## For parry_partial, mutates atk.pending_attack["velocity_m_s"] and defense sets **`parry_clash_context`** on the
## result dict; **`AttackResultApplier`** emits **`action_resolved`** then re-enters **`_execute_attack`** for
## follow-through.
## Follow-through re-resolve keeps first-contact **`attack_angle_deg`** / **`arc_end_deg`** / **`arc_span_deg`** /
## **`effective_attack_line`** when **`passive_parry_attempted`** is already set (see
## **`stamp_resolve_angle_geometry_on_pa`**).
static func stamp_resolve_angle_geometry_on_pa(
	pa: Dictionary, atk: Dictionary, atk_line_base: String, move_def_pre: Dictionary, arc_start_deg: float
) -> void:
	if pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false):
		pa[DataKeys.PA_POSITION_ANGLE_OFFSET_DEG] = CombatFootwork.get_attacker_offset_deg(atk)
		return
	var var_ctx: Dictionary = {}
	var_ctx[DataKeys.VAR_CTX_STAMINA_RATIO] = CombatantEntityAccess.stamina_ratio(atk)
	var_ctx[DataKeys.VAR_CTX_OFF_BALANCE] = PassiveParryContext.is_off_balance(atk)
	var atk_weapon = CombatantEntityAccess.get_weapon(atk)
	var_ctx[DataKeys.VAR_CTX_WEAPON_MASS_KG] = (
		float(atk_weapon.mass)
		if atk_weapon != null and (atk_weapon.get(DataKeys.WEAPON_MASS) is float or atk_weapon.get(DataKeys.WEAPON_MASS) is int)
		else CombatConstants.ANGLE_VARIANCE_MASS_REFERENCE_KG
	)
	pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG] = CombatConstants.get_attack_angle_deg(atk_line_base, true, move_def_pre, var_ctx)
	pa[DataKeys.PA_ARC_END_DEG] = pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG]
	pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG] = CombatFootwork.apply_offset_to_angle_deg(pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG], atk)
	pa[DataKeys.PA_POSITION_ANGLE_OFFSET_DEG] = CombatFootwork.get_attacker_offset_deg(atk)
	pa[DataKeys.PA_ARC_SPAN_DEG] = CombatConstants.angle_diff_deg(arc_start_deg, pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG])


static func resolve_attack(manager: Node, attacker_id: int) -> Dictionary:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return {"action": "skip", "target_id": -1, "recovery_duration": 0.0}
	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return {"action": "skip", "target_id": -1, "recovery_duration": 0.0}
	var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
	if pa.is_empty():
		return {"action": "skip", "target_id": -1, "recovery_duration": 0.0}
	var target_id: int = pa.target_id
	var intensity: float = pa.intensity
	var attack_type: String = pa.get(DataKeys.ATTACK_ATTACK_TYPE, WeaponConstants.ATTACK_TYPE_CUT)
	var archetype: Dictionary = CombatantEntityAccess.nested_dictionary_read(pa, "archetype")
	var velocity_override: float = pa.get(DataKeys.ATTACK_VELOCITY_M_S, -1.0)
	var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty() or not CombatantEntityAccess.alive_bool(tgt):
		return {"action": "skip", "target_id": target_id, "recovery_duration": 0.0}
	var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
	var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
	var atk_stats := CombatantEntityAccess.stats_dict(atk)
	CombatDebug.log("attack %s -> %s %s" % [atk_name, tgt_name, attack_type])

	var recovery_mult: float = archetype.get(DataKeys.ATK_MOD_RECOVERY_MULTIPLIER, 1.0)
	var atk_perf_mod: float = CombatantEntityAccess.get_performance_modifier(atk)
	if CombatantEntityAccess.get_attacking_arm(atk).is_empty():
		var rec_dur_skip: float = CombatTiming.recovery_duration(
			intensity,
			"hit",
			recovery_mult,
			atk_perf_mod,
			atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
		)
		CombatDebug.combat_session(
			(
																"%s has no functional arm; skips attack. intensity=%.2f => recovery=%.2fs"
				% [atk_name, intensity, rec_dur_skip]
			)
		)
		return {"action": "skip", "target_id": target_id, "recovery_duration": rec_dur_skip}

	var targetable: Array = CombatantEntityAccess.get_targetable_parts(tgt)
	if targetable.is_empty():
		return {"action": "defeated", "target_id": target_id}
	CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(manager, atk, tgt, pa)
	var n_targetable_before: int = targetable.size()
	targetable = CombatDepthPolearm.depth_polearm_targetable_parts_filter(manager, atk, targetable, pa)
	if (
		CombatDebug.flow_verbose_enabled()
		and pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false)
		and targetable.size() < n_targetable_before
	):
		var dens_log: String = str(pa.get(DataKeys.STRIKE_CTX_ZONE_GEOMETRY_ATK_DENSITY, "normal"))
		CombatDebug.flow_log(
			(
																"depth_polearm_resolve_parts atk=%d tgt=%d dens=%s parts=%s"
				% [attacker_id, target_id, dens_log, str(targetable)]
			),
			"depth_polearm_resolve:%d:%d" % [attacker_id, target_id]
		)
	if targetable.is_empty():
		return {"action": "defeated", "target_id": target_id}

	var atk_wep: Variant = CombatantEntityAccess.get_weapon(atk)
	if (
		CombatantEntityAccess.weapon_has_attack_types(atk_wep)
		and not CombatMeleeListing.can_melee_threaten(manager, atk, tgt, pa)
	):
		TacticalCombat.record_invalid_melee_resolve_blocked(manager)
		var rec_geom: float = CombatTiming.recovery_duration(
			intensity,
			"miss",
			recovery_mult,
			atk_perf_mod,
			atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
		)
		CombatDebug.log("abort resolve: can_melee_threaten false atk=%d tgt=%d" % [attacker_id, target_id])
		return {"action": "skip", "target_id": target_id, "recovery_duration": rec_geom}

	var perf_mod: float = CombatantEntityAccess.get_hit_chance_performance_modifier(atk)
	var perception_factor: float = clampf(
		float(atk_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE)) / 100.0,
		CombatConstants.HIT_CHANCE_PERCEPTION_MIN,
		CombatConstants.HIT_CHANCE_PERCEPTION_MAX
	)
	var effective_hit_chance: float = (1.0 - CombatConstants.MISS_CHANCE_BASE) * perf_mod * perception_factor
	var miss_chance: float = 1.0 - effective_hit_chance
	var miss_roll: float = randf()
	if miss_roll < miss_chance:
		CombatDebug.log("miss %s->%s roll=%.3f" % [atk_name, tgt_name, miss_roll])
		var rec_dur: float = CombatTiming.recovery_duration(
			intensity,
			"miss",
			recovery_mult,
			perf_mod,
			atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
		)
		return {"action": "miss", "target_id": target_id, "recovery_duration": rec_dur}
	CombatDebug.log("hit_roll %s->%s roll=%.3f" % [atk_name, tgt_name, miss_roll])

	# Diagonal C: alignment-weighted roll for diagonal moves. Store effective_attack_line for parry/path/hit.
	# Angle-based: store attack_angle_deg for continuous trajectory (deflection, alignment, damage).
	var move_def_pre: Dictionary = WeaponConstants.get_move(attack_type)
	var atk_line_base: String = move_def_pre.get(DataKeys.PA_ATTACK_LINE, "high")
	if (
		not pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
		and CombatConstants.DIAGONAL_WEIGHTS.has(attack_type)
	):
		var guard_line_def: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
		var weights: Variant = CombatConstants.DIAGONAL_WEIGHTS[attack_type].get(guard_line_def, {})
		if weights is Dictionary and not weights.is_empty():
			atk_line_base = _weighted_roll_attack_line(weights)
		pa[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk_line_base
	elif not pa.has(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE):
		pa[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk_line_base
	var arc_start: float = pa.get(DataKeys.ATTACK_ARC_START_DEG, CombatConstants.line_to_angle(atk_line_base))
	# Diagonal C may roll a different line than wind-up; keep step offset aligned with resolve line.
	if not pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false):
		CombatFootwork.apply_attack_step_on_windup(atk, atk_line_base, target_id, manager)
	stamp_resolve_angle_geometry_on_pa(pa, atk, atk_line_base, move_def_pre, arc_start)

	var zone_mult: float = ZoneOfControl.get_engagement_parry_multiplier(manager, attacker_id, target_id)
	pa[DataKeys.PA_ZONE_ENGAGEMENT_PARRY_MULT] = zone_mult
	if zone_mult <= CombatConstants.REAR_PARRY_MOD + 0.001:
		tgt[DataKeys.PA_ENGAGEMENT_ANGLE] = "rear"
	elif zone_mult <= CombatConstants.FLANK_PARRY_MOD + 0.001:
		tgt[DataKeys.PA_ENGAGEMENT_ANGLE] = "flank"
	else:
		tgt[DataKeys.PA_ENGAGEMENT_ANGLE] = "front"

	TacticalCombat.stamp_surround_threat_on_pa(manager, tgt, pa)
	pa[DataKeys.PA_TACTICAL_AMBUSH_MULT] = TacticalCombat.ambush_defense_multiplier(manager, tgt)
	CombatStrikeStamping.stamp_strike_realism_on_pa(manager, atk, tgt, pa, atk_wep, attack_type)
	CombatIncomingParryChoice.stamp_parry_choice_on_pa(manager, pa, target_id, attacker_id)

	var dc: Dictionary = DefenseChoiceResolver.choose_defense(
		pa, atk, tgt, targetable, attack_type, archetype, velocity_override, manager
	)
	var defense_choice: String = dc.defense
	var can_parry_in_time: bool = dc.can_parry_in_time
	var parry_p_a: float = dc.parry_p_a
	var parry_c_d: float = dc.parry_c_d
	var parry_readiness: float = dc.parry_readiness
	var late_parry: bool = dc.late_parry
	var is_block_parry: bool = dc.is_block_parry
	var dodge_chance: float = dc.dodge_chance
	var effective_redirect: float = dc.effective_redirect
	var def_has_weapon: bool = CombatantEntityAccess.has_weapon(tgt)
	if not def_has_weapon:
		CombatDebug.log("defense %s unarmed -> %s" % [tgt_name, defense_choice])
	elif not can_parry_in_time:
		CombatDebug.log("defense %s no parry time -> %s" % [tgt_name, defense_choice])
	else:
		var parry_reason: String = "parry" if defense_choice == "parry" else "dodge"
		if late_parry:
			parry_reason = "parry (late/reflex)"
		elif (
			defense_choice == "parry"
			and dodge_chance < CombatConstants.PARRY_DESPERATE_DODGE_THRESHOLD
			and not (is_block_parry and parry_p_a <= parry_c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO)
			and parry_p_a > parry_c_d * effective_redirect
		):
			parry_reason = "parry (desperate, dodge=%.2f)" % dodge_chance
		elif defense_choice == "dodge" and def_has_weapon:
			parry_reason = "dodge (expected better or clean avoid likely)"
		CombatDebug.log(
			(
																"defense %s -> %s block=%s p_a=%.1f c_d=%.1f"
				% [tgt_name, parry_reason, is_block_parry, parry_p_a, parry_c_d]
			)
		)

	var defense_result = DefenseResolutionHandler.resolve(
		pa,
		atk,
		tgt,
		dc,
		targetable,
		attack_type,
		intensity,
		archetype,
		velocity_override,
		recovery_mult,
		perf_mod,
		target_id,
		atk_name,
		tgt_name
	)
	if defense_result != null:
		return defense_result

	var power: float = pa.get(DataKeys.ATTACK_POWER, -1.0)
	var follow_through: float = pa.get(DataKeys.ATTACK_FOLLOW_THROUGH, -1.0)
	var parry_remaining_ratio: float = pa.get(DataKeys.ATTACK_PARRY_REMAINING_RATIO, 1.0)
	var afterblow_damage_mult: float = pa.get(DataKeys.ATTACK_AFTERBLOW_DAMAGE_MULT, 1.0)
	var dmg_velocity_override: float = pa.get(DataKeys.ATTACK_VELOCITY_M_S, velocity_override)
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var atk_line: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high"))
	var guard_line: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
	var atk_angle: float = pa.get(DataKeys.ATTACK_ATTACK_ANGLE_DEG, CombatConstants.line_to_angle(atk_line))
	var wobble_hit: Dictionary = {}
	if pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false):
		var def_weapon_hit = CombatantEntityAccess.get_weapon(tgt)
		wobble_hit = CombatantEntityAccess.parry_wobble_context(def_weapon_hit, parry_readiness)
	var guard_angle: float = CombatFootwork.guard_angle_deg(tgt, wobble_hit)
	var align_ctx: Dictionary = {"attack_angle_deg": atk_angle, "guard_angle_deg": guard_angle}
	var hit_alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx, wobble_hit)
	var part: String = pa.get(DataKeys.ATTACK_PARTIAL_DODGE_PART, "")
	var intended_part: String = pa.get(DataKeys.ATTACK_TARGET_PART, "")
	if part.is_empty():
		# Path + guard intercept; defender_ctx and intended_part refine hit distribution. Angle-based trajectory.
		var defender_ctx: Dictionary = {
			"state": CombatantEntityAccess.state_str(tgt),
			"recovery_cause": CombatConstants.normalize_recovery_cause(tgt.get(DataKeys.ATTACK_RECOVERY_CAUSE, "")),
			"passive_parry_attempted": pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
		}
		part = AttackPathResolver.resolve_hit_part(
			atk_line,
			guard_line,
			targetable,
			defender_ctx,
			intended_part,
			tgt,
			align_ctx,
			atk,
			move_def,
			pa.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true)
		)
		if part.is_empty():
			part = BodyPartConstants.get_weighted_random_part(targetable)
	atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
	atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
	atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
	var strike_mods: Dictionary = {}
	if atk_wep != null:
		strike_mods = StrikeRealismProfile.compute_strike_modifiers(
			manager, atk, tgt, atk_wep, attack_type, intensity, archetype, hit_alignment, parry_remaining_ratio, pa
		)
	var path_intercept_idx: int = AttackPathResolver.path_intercept_max_index(
		atk_line, guard_line, hit_alignment, align_ctx
	)
	var hit_sub_region: String = CombatHitSubRegion.resolve_sub_region(
		part, atk_line, guard_line, align_ctx, attack_type, path_intercept_idx
	)
	var strike_phys_ctx: Dictionary = {
		"tactical_ambush_mult": pa.get(DataKeys.PA_TACTICAL_AMBUSH_MULT, 1.0),
		"attack_type": attack_type,
		DataKeys.PA_DEPTH_POLEARM_ATTACK: pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false),
		"depth_polearm_lane_type": pa.get(DataKeys.PA_DEPTH_POLEARM_LANE, ""),
		DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW: pa.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true),
		"weapon_extension_commit_fraction": CombatWeaponPosition.delivery_commit_fraction_from_pa(pa),
		"hit_sub_region": hit_sub_region,
		"hit_sub_region_seed": target_id * CombatConstantsAttackPath.HIT_SUB_REGION_SEED_MULTIPLIER + attacker_id,
	}
	AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa)
	CombatFootwork.clear_on_exchange_end(atk)
	CombatFootwork.clear_on_exchange_end(tgt)
	# Wind-up energy must be captured before pending_attack is cleared: the resolver reads it only via
	# `wind_up_factor_override`, otherwise an empty pa yields wind_up_factor(-1)=0 and zeroes strike velocity.
	var wind_up_factor_resolve: float = CombatTiming.wind_up_factor(pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0))
	atk.pending_attack = {}
	var res: Dictionary = compute_and_apply_damage(
		manager,
		attacker_id,
		target_id,
		atk,
		tgt,
		part,
		intensity,
		attack_type,
		archetype,
		dmg_velocity_override,
		recovery_mult,
		perf_mod,
		power,
		follow_through,
		parry_remaining_ratio,
		afterblow_damage_mult,
		hit_alignment,
		strike_mods,
		strike_phys_ctx,
		wind_up_factor_resolve
	)
	var rd_out: Dictionary = res.result_dict
	rd_out[DataKeys.RESULT_TARGET_PART] = intended_part
	rd_out[DataKeys.RESULT_MOVE_ID] = attack_type
	rd_out[DataKeys.RESULT_ATTACK_TYPE] = attack_type
	var ent_aim: CoreEntity = CombatantEntityAccess.scene_entity(atk)
	if ent_aim != null:
		rd_out[DataKeys.AIM_PROT_TIER] = EntityProficiency.combined_aim_prof_tier(
			ent_aim, CombatantEntityAccess.weapon_type_id(atk), CombatantEntityAccess.form_str(atk)
		)
		rd_out[DataKeys.PROF_OCC_MULT] = EntityProficiency.proficiency_occurrence_mult(
			ent_aim, CombatantEntityAccess.weapon_type_id(atk), CombatantEntityAccess.form_str(atk), attack_type
		)
	return {
		"action": "hit",
		"target_id": target_id,
		"result_dict": rd_out,
		"recovery_duration": res.recovery_duration,
		"outcome": res.outcome,
		"intensity": intensity
	}
