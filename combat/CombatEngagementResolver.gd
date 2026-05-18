class_name CombatEngagementResolver
extends RefCounted

## Close attempts and crash/breach contests (Phase 2 / incursion). Mutates manager state and schedules turns.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _BreachResolver := preload("res://combat/BreachResolver.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")


static func _finish_close_attempt_turn(manager: Node, atk: Dictionary, attacker_id: int) -> void:
	atk["action_cooldown_until"] = _EntityAccess.combat_clock_plus(
		manager, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	)
	_EventScheduler.schedule_action_ready(
		manager, attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	)


static func _schedule_crash_attempt_recovery(manager: Node, attacker_id: int) -> void:
	_EventScheduler.schedule_action_ready(
		manager, attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S
	)


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


static func _reject_crash_attempt(
	manager: Node,
	attacker_id: int,
	defender_id: int,
	reason: String,
	flow_log_line: String = ""
) -> void:
	if not flow_log_line.is_empty() and CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(flow_log_line)
	manager.emit_signal(
		"action_resolved",
		attacker_id,
		defender_id,
		{"outcome": "crash_failed", "dmg": 0, "died": false, "reason": reason}
	)
	_schedule_crash_attempt_recovery(manager, attacker_id)


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
		print("[Combat] Close attempt %s → %s: %s (next turn in %.1fs)" % [atk_name, tgt_name, "success" if success else "failed", CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S])
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


static func resolve_crash_attempt(manager: Node, attacker_id: int, defender_id: int) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if atk.is_empty() or tgt.is_empty() or not _EntityAccess.are_alive_opponents(atk, tgt):
		return
	if _EntityAccess.is_incapacitated(atk) or _EntityAccess.is_incapacitated(tgt):
		return
	if not _EngagementMode.incursion_allowed(manager):
		_TacticalCombat.record_invalid_crash_resolve_blocked(manager)
		var rsn: String = (
			"intrusion_disabled"
			if not CombatConstants.FEATURE_LINE_CRASH_INTRUSION
			else "engagement_mode_%s" % _EngagementMode.engagement_mode(manager)
		)
		_reject_crash_attempt(
			manager,
			attacker_id,
			defender_id,
			rsn,
			"crash_blocked id=%d->%d reason=%s" % [attacker_id, defender_id, rsn]
		)
		return
	if _EntityAccess.stamina_float(atk, 0.0) < CombatConstants.CRASH_STAMINA_COST:
		_reject_crash_attempt(
			manager,
			attacker_id,
			defender_id,
			"stamina",
			(
				"crash_blocked id=%d->%d reason=stamina stamina=%.1f need=%.1f"
				% [attacker_id, defender_id, _EntityAccess.stamina_float(atk, 0.0), CombatConstants.CRASH_STAMINA_COST]
			)
		)
		return
	if _EntityAccess.tactical_penetration_depth_int(atk) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		_reject_crash_attempt(
			manager,
			attacker_id,
			defender_id,
			"max_depth",
			(
				"crash_blocked id=%d->%d reason=max_depth depth=%d max=%d"
				% [
					attacker_id,
					defender_id,
					_EntityAccess.tactical_penetration_depth_int(atk),
					CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX
				]
			)
		)
		return
	var intr_block: String = _EngagementMode.crash_intrusion_attacker_block_reason(manager, atk)
	if not intr_block.is_empty():
		_reject_crash_attempt(
			manager,
			attacker_id,
			defender_id,
			intr_block,
			"crash_blocked id=%d->%d reason=%s" % [attacker_id, defender_id, intr_block]
		)
		return
	var res: Dictionary = _BreachResolver.contest_crash(manager, attacker_id, defender_id)
	var ok: bool = bool(res.get("ok", false))
	atk["stamina"] = maxf(0.0, _EntityAccess.stamina_float(atk) - CombatConstants.CRASH_STAMINA_COST)
	atk["crash_cooldown_until"] = _EntityAccess.combat_clock_plus(manager, CombatConstants.CRASH_COOLDOWN_S)
	atk["action_cooldown_until"] = _EntityAccess.combat_clock_plus(manager, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
	if ok:
		atk["tactical_penetration_depth"] = int(res.get("tactical_penetration_depth", 1))
		var fid_b: String = str(res.get("defender_formation_id", ""))
		var f_b: int = int(res.get("defender_file", 0))
		atk["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
		atk["intrusion_host_fid"] = fid_b
		atk["intrusion_anchor_file"] = f_b
		var sev: float = float(res.get("breach_severity", 0.7))
		if not fid_b.is_empty():
			var form_b: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid_b)
			if not form_b.is_empty():
				if not form_b.has("breached_files"):
					form_b["breached_files"] = {}
				var bf: Dictionary = _FormationSlots.formation_nested_dictionary_read(form_b, "breached_files")
				var prev: float = _FormationBreachRules.breached_file_severity(bf, f_b)
				bf[f_b] = maxf(prev, sev)
		_FormationFlow.apply_intrusion_after_crash_success(manager, atk, defender_id, fid_b, f_b, sev)
		manager._recompute_zoc_and_distance()
		if _EntityAccess.formation_id_str(atk) != fid_b:
			_EntityAccess.manager_notify_formation_changed(manager, _EntityAccess.formation_id_str(atk))
		if not fid_b.is_empty():
			_EntityAccess.manager_notify_formation_changed(manager, fid_b)
	var bf_line: String = ""
	var form_snap: Dictionary = _ZoneOfControl.formation_for_combatant_cached(
		manager, tgt, null, str(res.get("defender_formation_id", ""))
	)
	if not form_snap.is_empty():
		bf_line = CombatDebug.format_breached_files(_FormationSlots.formation_nested_dictionary_read(form_snap, "breached_files"))
	var breached_disp: String = bf_line if not bf_line.is_empty() else "—"
	# Verbose crash contest: single log in `BreachResolver.contest_crash` (p_win, roll, geometry).
	if not CombatDebug.flow_verbose_enabled() and CombatConstants.combat_event_debug_active():
		var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_name: String = _EntityAccess.get_display_name(tgt, defender_id)
		print(
			"[Combat] Crash %s → %s: %s drive=%.1f hold=%.1f depth=%d file=%d sev=%.2f defender_breached_files[%s]"
			% [
				atk_name,
				tgt_name,
				"breach" if ok else "repelled",
				float(res.get("drive", 0.0)),
				float(res.get("hold", 1.0)),
				_EntityAccess.tactical_penetration_depth_int(atk),
				int(res.get("defender_file", -1)),
				float(res.get("breach_severity", 0.0)),
				breached_disp
			]
		)
	var crash_payload: Dictionary = {
		"outcome": "crash_success" if ok else "crash_failed",
		"dmg": 0,
		"died": false,
		"tactical_penetration_depth": _EntityAccess.tactical_penetration_depth_int(atk),
		"breach_severity": float(res.get("breach_severity", 0.0)),
	}
	if not ok:
		crash_payload["reason"] = "repelled"
	manager.emit_signal("action_resolved", attacker_id, defender_id, crash_payload)
	_schedule_crash_attempt_recovery(manager, attacker_id)
