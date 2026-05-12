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


static func resolve_close_attempt(manager: Node, attacker_id: int, target_id: int) -> void:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(target_id)
	if atk == null or tgt == null or not _EntityAccess.alive_bool(atk) or not _EntityAccess.alive_bool(tgt):
		return
	if _EntityAccess.is_incapacitated(atk) or _EntityAccess.is_incapacitated(tgt):
		return
	# `attempt_close` is only listed at LONG; resolving at MID/CLOSE is stale/illegal (Tier 1.8 telemetry).
	var band: String = str(
		_EntityAccess.nested_dictionary_read(atk, "distance_to").get(
			target_id, CombatConstants.DISTANCE_LONG
		)
	)
	if band != CombatConstants.DISTANCE_LONG:
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
		atk["action_cooldown_until"] = manager.combat_clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)
		return
	var weapon = _EntityAccess.get_weapon(atk)
	var melee_range: float = float(weapon.melee_range) if weapon != null else 1.5
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
	var fid_close: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, tgt)
	var form_geom: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, tgt, fid_close)
	var density: String = str(form_geom.get("density", "normal")) if not form_geom.is_empty() else "normal"
	evasion *= CombatConstants.get_density_close_mod(density)
	var success: bool = randf() < pressure / (pressure + maxf(evasion, 1.0))
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"close_attempt atk=%d tgt=%d success=%s pressure=%.1f evasion=%.1f"
			% [attacker_id, target_id, success, pressure, evasion]
		)
	elif CombatConstants.COMBAT_EVENT_DEBUG:
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
		blk[target_id] = float(manager.combat_clock) + CombatConstants.CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S
	atk["action_cooldown_until"] = manager.combat_clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)


static func resolve_crash_attempt(manager: Node, attacker_id: int, defender_id: int) -> void:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(defender_id)
	if atk == null or tgt == null or not _EntityAccess.alive_bool(atk) or not _EntityAccess.alive_bool(tgt):
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
		if CombatDebug.flow_verbose_enabled():
			CombatDebug.flow_log("crash_blocked id=%d->%d reason=%s" % [attacker_id, defender_id, rsn])
		manager.emit_signal(
			"action_resolved",
			attacker_id,
			defender_id,
			{"outcome": "crash_failed", "dmg": 0, "died": false, "reason": rsn}
		)
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	if _EntityAccess.stamina_float(atk, 0.0) < CombatConstants.CRASH_STAMINA_COST:
		if CombatDebug.flow_verbose_enabled():
			CombatDebug.flow_log(
				"crash_blocked id=%d->%d reason=stamina stamina=%.1f need=%.1f"
				% [attacker_id, defender_id, _EntityAccess.stamina_float(atk, 0.0), CombatConstants.CRASH_STAMINA_COST]
			)
		manager.emit_signal("action_resolved", attacker_id, defender_id, {"outcome": "crash_failed", "dmg": 0, "died": false, "reason": "stamina"})
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	if _EntityAccess.tactical_penetration_depth_int(atk) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		if CombatDebug.flow_verbose_enabled():
			CombatDebug.flow_log(
				"crash_blocked id=%d->%d reason=max_depth depth=%d max=%d"
				% [
					attacker_id,
					defender_id,
					_EntityAccess.tactical_penetration_depth_int(atk),
					CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX
				]
			)
		manager.emit_signal("action_resolved", attacker_id, defender_id, {"outcome": "crash_failed", "dmg": 0, "died": false, "reason": "max_depth"})
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	var intr_block: String = _EngagementMode.crash_intrusion_attacker_block_reason(manager, atk)
	if not intr_block.is_empty():
		if CombatDebug.flow_verbose_enabled():
			CombatDebug.flow_log("crash_blocked id=%d->%d reason=%s" % [attacker_id, defender_id, intr_block])
		manager.emit_signal(
			"action_resolved",
			attacker_id,
			defender_id,
			{"outcome": "crash_failed", "dmg": 0, "died": false, "reason": intr_block}
		)
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	var res: Dictionary = _BreachResolver.contest_crash(manager, attacker_id, defender_id)
	var ok: bool = bool(res.get("ok", false))
	atk["stamina"] = maxf(0.0, _EntityAccess.stamina_float(atk) - CombatConstants.CRASH_STAMINA_COST)
	atk["crash_cooldown_until"] = manager.combat_clock + CombatConstants.CRASH_COOLDOWN_S
	atk["action_cooldown_until"] = manager.combat_clock + CombatConstants.READY_DELAY_CRASH_ATTEMPT_S
	if ok:
		atk["tactical_penetration_depth"] = int(res.get("tactical_penetration_depth", 1))
		var fid_b: String = str(res.get("defender_formation_id", ""))
		var f_b: int = int(res.get("defender_file", 0))
		atk["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
		atk["intrusion_host_fid"] = fid_b
		atk["intrusion_anchor_file"] = f_b
		var sev: float = float(res.get("breach_severity", 0.7))
		if not fid_b.is_empty():
			var raw_fb: Variant = manager.formations.get(fid_b, null)
			if raw_fb is Dictionary:
				var form_b: Dictionary = raw_fb as Dictionary
				if not form_b.has("breached_files"):
					form_b["breached_files"] = {}
				var bf_raw: Variant = form_b.get("breached_files", null)
				if bf_raw is Dictionary:
					var bf: Dictionary = bf_raw as Dictionary
					var prev: float = _FormationBreachRules.breached_file_severity(bf, f_b)
					bf[f_b] = maxf(prev, sev)
		_FormationFlow.apply_intrusion_after_crash_success(manager, atk, defender_id, fid_b, f_b, sev)
		manager._recompute_zoc_and_distance()
		if _EntityAccess.formation_id_str(atk) != fid_b and manager.has_method("notify_formation_changed"):
			manager.notify_formation_changed(_EntityAccess.formation_id_str(atk))
		if not fid_b.is_empty():
			manager.notify_formation_changed(fid_b)
	var bf_line: String = ""
	var fid_snap: String = str(res.get("defender_formation_id", ""))
	if fid_snap.is_empty():
		fid_snap = _ZoneOfControl.formation_id_for_zone_geometry(manager, tgt)
	var form_snap: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, tgt, fid_snap)
	if not form_snap.is_empty():
		bf_line = CombatDebug.format_breached_files(_FormationSlots.formation_nested_dictionary_read(form_snap, "breached_files"))
	var breached_disp: String = bf_line if not bf_line.is_empty() else "—"
	# Verbose crash contest: single log in `BreachResolver.contest_crash` (p_win, roll, geometry).
	if not CombatDebug.flow_verbose_enabled() and CombatConstants.COMBAT_EVENT_DEBUG:
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
	manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
