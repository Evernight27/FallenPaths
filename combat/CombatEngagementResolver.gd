class_name CombatEngagementResolver
extends RefCounted

## Close attempts (`MOVE_ID_ATTEMPT_CLOSE`): close tactical range from **LONG** so melee can threaten.
## **Read order:** listing legality check → contest roll → schedule resolve / turn finish.
## Canonical: **`CombatMeleeListing.attempt_close_listed_for_pair`** · resolve via **`CombatResolveAction`** → **`CombatManager._resolve_close_attempt`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")


static func _finish_close_attempt_turn(manager: Node, atk: Dictionary, attacker_id: int) -> void:
	atk.gauge = 0.0
	atk["action_cooldown_until"] = _EntityAccess.combat_clock_plus(
		manager, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	)
	_EventScheduler.schedule_action_ready(
		manager, attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	)


static func _lane_stress_at_file(manager: Node, c: Dictionary) -> float:
	if manager == null or c.is_empty():
		return 0.0
	var ctx: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var form: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx)
	if form.is_empty():
		return 0.0
	var ls: Dictionary = _FormationSlots.formation_nested_dictionary_read(form, "lane_stress_by_file")
	var fi: int = _EntityAccess.file_int(c)
	var raw: Variant = ls.get(fi, ls.get(str(fi), 0.0))
	return clampf(float(raw), 0.0, 1.0)


static func _close_attempt_pressure_mult(
	manager: Node, attacker_id: int, atk: Dictionary, tgt: Dictionary
) -> float:
	var mult: float = 1.0
	var tgt_id: int = _EntityAccess.id_int(tgt)
	var sector_w: float = _TacticalCombat.sector_weight_for_attacker_on_defender(
		manager, tgt_id, attacker_id
	)
	mult *= lerpf(
		CombatConstants.CLOSE_ATTEMPT_FLANK_PRESSURE_MULT_AT_MIN_SECTOR,
		1.0,
		clampf(sector_w, CombatConstants.SURROUND_SECTOR_WEIGHT_MIN, 1.0)
	)
	if _EntityAccess.rank_int(atk) == 0 and _EntityAccess.rank_int(tgt) == 0:
		if _TargetScoring.is_file_opposed_rank0_pair(manager, atk, tgt):
			mult *= CombatConstants.CLOSE_ATTEMPT_FILE_OPPOSED_PRESSURE_MULT
	var lane_atk: float = _lane_stress_at_file(manager, atk)
	mult *= lerpf(1.0, CombatConstants.CLOSE_ATTEMPT_LANE_STRESS_PRESSURE_MIN, lane_atk)
	var sur: Dictionary = _TacticalCombat.surround_threat_scan_for_defender(manager, tgt)
	if int(sur.get("count", 0)) >= 2:
		mult *= CombatConstants.CLOSE_ATTEMPT_DEFENDER_ENGAGED_PRESSURE_MULT
	return mult


static func _close_attempt_evasion_mult(
	manager: Node, attacker_id: int, tgt: Dictionary
) -> float:
	var mult: float = 1.0
	var lane_def: float = _lane_stress_at_file(manager, tgt)
	mult *= lerpf(1.0, CombatConstants.CLOSE_ATTEMPT_LANE_STRESS_EVASION_MIN, lane_def)
	var tgt_id: int = _EntityAccess.id_int(tgt)
	var occupied: int = _MeleeListing.count_close_attackers_on_defender(
		manager, tgt_id, attacker_id
	)
	if occupied > 0:
		mult *= pow(CombatConstants.CLOSE_ATTEMPT_CROWD_EVASION_MULT_PER_OCCUPANT, float(occupied))
	var sur: Dictionary = _TacticalCombat.surround_threat_scan_for_defender(manager, tgt)
	var sur_n: int = int(sur.get("count", 1))
	if sur_n > 1:
		mult *= _TacticalCombat.surround_defense_multiplier(tgt, sur_n)
	return mult


static func resolve_close_attempt(manager: Node, attacker_id: int, target_id: int) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if atk.is_empty() or tgt.is_empty() or not _EntityAccess.are_alive_opponents(atk, tgt):
		return
	if _EntityAccess.is_incapacitated(atk) or _EntityAccess.is_incapacitated(tgt):
		return
	# `attempt_close` is only listed at LONG (`CombatMeleeListing.attempt_close_listed_for_pair`); MID/CLOSE resolve is telemetry-only.
	var band: String = _EntityAccess.distance_to_opponent_band(atk, target_id)
	if band != CombatConstants.DISTANCE_LONG:
		_reject_close_attempt_not_long(manager, atk, attacker_id, target_id, band)
		return
	if not _MeleeListing.defender_has_free_close_slot(manager, tgt, attacker_id):
		_reject_close_attempt_slots_full(manager, atk, attacker_id, target_id, tgt)
		return
	var melee_range: float = _EntityAccess.weapon_melee_reach(atk)
	var str_val: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
	var agi_def: float = float(_EntityAccess.stats_dict(tgt).get("agility", 100))
	var pressure: float = (
		str_val
		* CombatConstants.stamina_factor(_EntityAccess.stamina_ratio(atk))
		* (melee_range / 1.5)
	)
	pressure *= CombatConstants.get_stance_modifier(_EntityAccess.stance_str(atk), "close_attempt")
	pressure *= _close_attempt_pressure_mult(manager, attacker_id, atk, tgt)
	var evasion: float = agi_def * CombatConstants.stamina_factor(_EntityAccess.stamina_ratio(tgt))
	evasion *= CombatConstants.get_stance_modifier(_EntityAccess.stance_str(tgt), "evasion")
	evasion *= _TacticalCombat.ambush_defense_multiplier(manager, tgt)
	if _EntityAccess.stance_str(tgt, "") == CombatConstants.STANCE_CONTROLLING:
		evasion /= CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	var ctx_tgt: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, tgt)
	var form_geom: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_tgt)
	var density: String = str(form_geom.get("density", "normal")) if not form_geom.is_empty() else "normal"
	evasion *= CombatConstants.get_density_close_mod(density)
	evasion *= _close_attempt_evasion_mult(manager, attacker_id, tgt)
	var success: bool = randf() < pressure / (pressure + maxf(evasion, 1.0))
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"close_attempt atk=%d tgt=%d success=%s pressure=%.1f evasion=%.1f"
			% [attacker_id, target_id, success, pressure, evasion]
		)
	elif (
		not _OperationalLog.is_play_session_active()
		and CombatConstants.combat_event_debug_active()
	):
		var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
		CombatDebug.combat_session(
			"close attempt %s → %s: %s (next turn in %.1fs)"
			% [atk_name, tgt_name, "success" if success else "failed", CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S]
		)
	var close_result: Dictionary = {"outcome": "close_success", "dmg": 0, "died": false}
	if not success:
		close_result = {"outcome": "close_failed", "dmg": 0, "died": false, "reason": "contest_failed"}
	manager.emit_signal("action_resolved", attacker_id, target_id, close_result)
	var blk: Dictionary = _EntityAccess.nested_dictionary_for_mutation(atk, "close_block_until_by_target_id")
	if success:
		_EntityAccess.sync_close_distance_pair(atk, tgt, attacker_id, target_id)
		blk.erase(target_id)
		_TargetScoring.on_combat_commitment(manager, attacker_id, target_id)
	else:
		blk[target_id] = _EntityAccess.combat_clock_float(manager) + CombatConstants.CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S
	_finish_close_attempt_turn(manager, atk, attacker_id)


static func _reject_close_attempt_not_long(
	manager: Node,
	atk: Dictionary,
	attacker_id: int,
	target_id: int,
	band: String
) -> void:
	_TacticalCombat.record_invalid_close_resolve_blocked(manager)
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"close_blocked id=%d->%d reason=not_long dist=%s" % [attacker_id, target_id, band]
		)
	manager.emit_signal(
		"action_resolved",
		attacker_id,
		target_id,
		{"outcome": "close_failed", "dmg": 0, "died": false, "reason": "not_long"}
	)
	_finish_close_attempt_turn(manager, atk, attacker_id)


static func _reject_close_attempt_slots_full(
	manager: Node,
	atk: Dictionary,
	attacker_id: int,
	target_id: int,
	tgt: Dictionary
) -> void:
	_TacticalCombat.record_invalid_close_resolve_blocked(manager)
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"close_blocked id=%d->%d reason=close_slots_full cap=%d occupied=%d"
			% [
				attacker_id,
				target_id,
				_MeleeListing.max_close_slots_for_defender(manager, tgt),
				_MeleeListing.count_close_attackers_on_defender(manager, target_id, attacker_id),
			]
		)
	manager.emit_signal(
		"action_resolved",
		attacker_id,
		target_id,
		{"outcome": "close_failed", "dmg": 0, "died": false, "reason": "close_slots_full"}
	)
	_finish_close_attempt_turn(manager, atk, attacker_id)
