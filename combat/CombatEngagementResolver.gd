class_name CombatEngagementResolver
extends RefCounted

## Close attempts (`MOVE_ID_ATTEMPT_CLOSE`): close tactical range from **LONG** so melee can threaten.
## Not line-crash / breach fiction (removed D-008). Listing: `CombatMeleeListing`; resolve: `CombatResolveAction` → `CombatManager._resolve_close_attempt`.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")


static func _finish_close_attempt_turn(manager: Node, atk: Dictionary, attacker_id: int) -> void:
	atk.gauge = 0.0
	atk["action_cooldown_until"] = _EntityAccess.combat_clock_plus(
		manager, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	)
	_EventScheduler.schedule_action_ready(
		manager, attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	)


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
	var st_atk: float = _EntityAccess.stamina_float(atk)
	var st_def: float = _EntityAccess.stamina_float(tgt)
	var pressure: float = str_val * CombatConstants.stamina_factor(st_atk / CombatConstants.STAMINA_MAX) * (melee_range / 1.5)
	pressure *= CombatConstants.get_stance_modifier(_EntityAccess.stance_str(atk), "close_attempt")
	var evasion: float = agi_def * CombatConstants.stamina_factor(st_def / CombatConstants.STAMINA_MAX)
	evasion *= CombatConstants.get_stance_modifier(_EntityAccess.stance_str(tgt), "evasion")
	evasion *= _TacticalCombat.ambush_defense_multiplier(manager, tgt)
	if _EntityAccess.stance_str(tgt, "") == CombatConstants.STANCE_CONTROLLING:
		evasion /= CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	var ctx_tgt: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, tgt)
	var form_geom: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_tgt)
	var density: String = str(form_geom.get("density", "normal")) if not form_geom.is_empty() else "normal"
	evasion *= CombatConstants.get_density_close_mod(density)
	var success: bool = randf() < pressure / (pressure + maxf(evasion, 1.0))
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"close_attempt atk=%d tgt=%d success=%s pressure=%.1f evasion=%.1f"
			% [attacker_id, target_id, success, pressure, evasion]
		)
	elif CombatConstants.combat_event_debug_active():
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
		_EntityAccess.nested_dictionary_for_mutation(atk, "distance_to")[target_id] = CombatConstants.DISTANCE_CLOSE
		_EntityAccess.nested_dictionary_for_mutation(tgt, "distance_to")[attacker_id] = CombatConstants.DISTANCE_CLOSE
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
