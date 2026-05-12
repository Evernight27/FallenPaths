class_name AttackWindUpStarter
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")

## Starts an attack wind-up: power/follow-through roll, intensity, weapon selection, wind-up duration.
## Manager must have: _get_by_id; health reads go through CombatantEntityAccess + manager.get_health_entity.
## Mutates attacker combatant in place.

static func start(manager: Node, attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(target_id)
	if atk == null or tgt == null or not _EntityAccess.alive_bool(tgt):
		return
	var atk_n: Node = _EntityAccess.scene_node(atk)
	if atk_n != null and atk_n.has_method("get_attacking_arm") and atk_n.get_attacking_arm().is_empty():
		var atk_name_skip: String = _EntityAccess.get_display_name(atk, attacker_id)
		print("[Combat] %s has no functional arm; skip attack (short recovery)." % atk_name_skip)
		atk.state = CombatConstants.STATE_RECOVERING
		atk.state_timer = 0.0
		atk.state_duration = 0.8
		atk.gauge = 0.0
		atk.pending_attack = {}
		return
	# Power and follow_through (0.2–1.0) per attack; intensity drives velocity, wind-up, and recovery. Strength biases toward higher commitment.
	var power: float = randf_range(CombatConstants.POWER_MIN, CombatConstants.POWER_MAX)
	var follow_through: float = randf_range(CombatConstants.FOLLOW_THROUGH_MIN, CombatConstants.FOLLOW_THROUGH_MAX)
	var rolled_intensity: float = (0.5 + 0.5 * power) * (0.5 + 0.5 * follow_through)
	var strength_intensity: float = CombatTiming.intensity_from_stats(atk)
	var intensity: float = clampf(lerpf(rolled_intensity, strength_intensity, CombatConstants.INTENSITY_STRENGTH_BIAS), CombatConstants.INTENSITY_MIN, 1.0)
	var weapon = _EntityAccess.get_weapon(atk)
	var attack_type: String = WeaponConstants.ATTACK_TYPE_CUT
	var archetype: Dictionary = WeaponConstants.get_archetype(WeaponConstants.ARCHETYPE_SLASH)
	if weapon != null and weapon.has_method("get_available_attack_types"):
		if move_id != "" and weapon.get_available_attack_types().has(move_id):
			attack_type = move_id
		else:
			var types_arr: Array = weapon.get_available_attack_types()
			var non_parry: Array = []
			for mid in types_arr:
				if not WeaponConstants.is_parry_move(mid):
					non_parry.append(mid)
			if non_parry.is_empty():
				non_parry = types_arr
			if not non_parry.is_empty():
				attack_type = non_parry[randi() % non_parry.size()]
		if weapon.has_method("get_archetype_id"):
			archetype = WeaponConstants.get_archetype(weapon.get_archetype_id(attack_type))
	var windup_mult: float = float(archetype.get("windup_multiplier", 1.0))
	var wind_up_s: float = CombatTiming.wind_up_duration(intensity, windup_mult)
	# Guard transition: blade must move from current guard to attack line. Physics: angular distance (angle-based).
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var attack_line: String = move_def.get("attack_line", "high")
	var arc_start_deg: float = CombatConstants.get_guard_angle_deg(atk)
	var align_ctx: Dictionary = {
		"attack_angle_deg": CombatConstants.line_to_angle(attack_line),
		"guard_angle_deg": arc_start_deg
	}
	var align: float = CombatConstants.get_line_alignment_with_deflect(attack_line, atk, align_ctx)
	var trans_mult: float = 1.0 + (1.0 - align) * CombatConstants.GUARD_TRANSITION_COST_SCALE
	wind_up_s *= trans_mult
	# Bind riposte: parry_part × contact_type. Extend=fast, wind=moderate, swing=slow.
	if weapon != null and atk.get("parry_was_bind", false) and atk.get("parry_against_id", -1) == target_id:
		var contact_type: String = weapon.get_contact_type(attack_type) if weapon.has_method("get_contact_type") else ""
		var eligible: Array = weapon.bind_riposte_contact_types if weapon.get("bind_riposte_contact_types") is Array else []
		if contact_type in eligible:
			var parry_part: String = weapon.get_parry_contact_type() if weapon.has_method("get_parry_contact_type") else "blade"
			var part_row: Variant = CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT.get(parry_part, {})
			var mult: float = float(part_row.get(contact_type, -1.0)) if part_row is Dictionary else -1.0
			if mult < 0.0:
				mult = CombatConstants.PARRY_BIND_RIPOSTE_MULT_FALLBACK
			wind_up_s *= mult
	# Leg functionality: longer wind-up when legs injured (harder to get into position to attack).
	if atk_n != null and atk_n.has_method("get_leg_functionality"):
		var leg: float = clampf(atk_n.get_leg_functionality(), CombatConstants.WINDUP_LEG_MIN, 1.0)
		wind_up_s /= leg
	# Pain/consciousness: wounded attackers swing slower
	var atk_perf_mod: float = 1.0
	if atk_n != null and atk_n.has_method("get_performance_modifier"):
		atk_perf_mod = atk_n.get_performance_modifier()
	if atk_perf_mod > 0.0:
		wind_up_s /= maxf(CombatConstants.PERF_MOD_MIN, atk_perf_mod)
	# Agility: higher agility shortens wind-up (faster into position)
	var atk_agi: float = float(_EntityAccess.stats_dict(atk).get("agility", 100))
	wind_up_s /= clampf(atk_agi / 100.0, 0.7, 1.3)
	atk.gauge = 0.0
	atk["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	atk.erase("guard_deflect_blend")
	atk.erase("guard_deflect_from_line")
	atk.erase("parry_was_bind")
	atk.erase("parry_against_id")
	atk.state = CombatConstants.STATE_WIND_UP
	atk.state_timer = 0.0
	atk.state_duration = wind_up_s
	# arc_intended_deg: intended target angle (no variance) — lets systems query blade position during wind-up.
	var arc_intended_deg: float = align_ctx["attack_angle_deg"]
	var pa: Dictionary = {"target_id": target_id, "intensity": intensity, "power": power, "follow_through": follow_through, "attack_type": attack_type, "archetype": archetype, "wind_up_duration": wind_up_s, "arc_start_deg": arc_start_deg, "arc_intended_deg": arc_intended_deg}
	if weapon != null:
		pa["impact_blade_station"] = _StrikeRealism.roll_blade_station(weapon, attack_type, intensity)
	var target_part: String = str(options.get("target_part", ""))
	var feint_part: String = str(options.get("feint_part", ""))
	if not target_part.is_empty():
		pa["target_part"] = target_part
	if not feint_part.is_empty():
		pa["feint_part"] = feint_part
	# Tier 3.1: pair geometry + depth lane flags (`AvailableActionsBuilder.stamp_attack_pair_geometry_on_dict`; re-stamped each resolve).
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(manager, atk, tgt, pa)
	if weapon != null:
		# After stamp so **`strike_measure_ratio`** uses the same **`effective_pair_eff_dist`** as parry / resolve.
		pa["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			manager, atk, tgt, weapon, float(pa.get("effective_pair_eff_dist", -1.0))
		)
		pa["move_contact_type"] = WeaponConstants.contact_type_for_move_id(attack_type)
	atk.pending_attack = pa
	# Feint D: defender reacts to telegraph at wind-up start. If feint, they guard feint_part; else they guard target_part.
	var telegraph_part: String = str(pa.get("feint_part", pa.get("target_part", "head")))
	tgt["guard_zone"] = telegraph_part
	var atk_name_log: String = (str(atk_n.name) if atk_n != null else "id:%d" % attacker_id)
	if CombatConstants.COMBAT_DEBUG:
		var angle_info: String = " [atk=%.0f° guard=%.0f°]" % [align_ctx["attack_angle_deg"], align_ctx["guard_angle_deg"]]
		CombatDebug.log("%s | guard=%s atk_line=%s align=%.2f trans=%.2f%s | wind_up=%.2fs" % [atk_name_log, atk.get("guard_line", CombatConstants.GUARD_DEFAULT), attack_line, align, trans_mult, angle_info, wind_up_s])
