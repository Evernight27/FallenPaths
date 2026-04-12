class_name CombatEngagementResolver
extends RefCounted

## Close attempts and crash/breach contests (Phase 2 / incursion). Mutates manager state and schedules turns.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _BreachResolver := preload("res://combat/BreachResolver.gd")


static func resolve_close_attempt(manager: Node, attacker_id: int, target_id: int) -> void:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(target_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	var weapon = _EntityAccess.get_weapon(atk)
	var melee_range: float = float(weapon.melee_range) if weapon != null else 1.5
	var str_val: float = float(atk.stats.get("strength", 100))
	var agi_def: float = float(tgt.stats.get("agility", 100))
	var st_atk: float = atk.get("stamina", CombatConstants.STAMINA_MAX)
	var st_def: float = tgt.get("stamina", CombatConstants.STAMINA_MAX)
	var pressure: float = str_val * CombatConstants.stamina_factor(st_atk / CombatConstants.STAMINA_MAX) * (melee_range / 1.5)
	pressure *= CombatConstants.get_stance_modifier(atk.get("stance", CombatConstants.STANCE_BALANCED), "close_attempt")
	var evasion: float = agi_def * CombatConstants.stamina_factor(st_def / CombatConstants.STAMINA_MAX)
	evasion *= CombatConstants.get_stance_modifier(tgt.get("stance", CombatConstants.STANCE_BALANCED), "evasion")
	evasion *= _TacticalCombat.ambush_defense_multiplier(manager, tgt)
	if tgt.get("stance", "") == CombatConstants.STANCE_CONTROLLING:
		evasion /= CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	var fid: String = tgt.get("formation_id", "")
	var density: String = manager.formations.get(fid, {}).get("density", "normal")
	evasion *= CombatConstants.get_density_close_mod(density)
	var success: bool = randf() < pressure / (pressure + maxf(evasion, 1.0))
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
		print("[Combat] Close attempt %s → %s: %s (next turn in %.1fs)" % [atk_name, tgt_name, "success" if success else "failed", CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S])
	manager.emit_signal("action_resolved", attacker_id, target_id, {"outcome": "close_success" if success else "close_failed", "dmg": 0, "died": false})
	if success:
		atk.distance_to[target_id] = CombatConstants.DISTANCE_CLOSE
		tgt.distance_to[attacker_id] = CombatConstants.DISTANCE_CLOSE
	atk["action_cooldown_until"] = manager.combat_clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
	manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)


static func resolve_crash_attempt(manager: Node, attacker_id: int, defender_id: int) -> void:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(defender_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	if float(atk.get("stamina", 0.0)) < CombatConstants.CRASH_STAMINA_COST:
		if CombatConstants.COMBAT_EVENT_DEBUG:
			CombatDebug.flow_log(
				"crash_blocked id=%d->%d reason=stamina stamina=%.1f need=%.1f"
				% [attacker_id, defender_id, float(atk.get("stamina", 0.0)), CombatConstants.CRASH_STAMINA_COST]
			)
		manager.emit_signal("action_resolved", attacker_id, defender_id, {"outcome": "crash_failed", "dmg": 0, "died": false, "reason": "stamina"})
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	if int(atk.get("tactical_penetration_depth", 0)) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		if CombatConstants.COMBAT_EVENT_DEBUG:
			CombatDebug.flow_log(
				"crash_blocked id=%d->%d reason=max_depth depth=%d max=%d"
				% [attacker_id, defender_id, int(atk.get("tactical_penetration_depth", 0)), CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX]
			)
		manager.emit_signal("action_resolved", attacker_id, defender_id, {"outcome": "crash_failed", "dmg": 0, "died": false, "reason": "max_depth"})
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	if CombatConstants.crash_breach_viability(atk) < CombatConstants.CRASH_BREACH_VIABILITY_MIN:
		if CombatConstants.COMBAT_EVENT_DEBUG:
			CombatDebug.flow_log(
				"crash_blocked id=%d->%d reason=not_viable viability=%.3f min=%.3f"
				% [
					attacker_id,
					defender_id,
					CombatConstants.crash_breach_viability(atk),
					CombatConstants.CRASH_BREACH_VIABILITY_MIN
				]
			)
		manager.emit_signal("action_resolved", attacker_id, defender_id, {"outcome": "crash_failed", "dmg": 0, "died": false, "reason": "not_viable"})
		manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
		return
	var res: Dictionary = _BreachResolver.contest_crash(manager, attacker_id, defender_id)
	var ok: bool = bool(res.get("ok", false))
	atk["stamina"] = maxf(0.0, float(atk.get("stamina", CombatConstants.STAMINA_MAX)) - CombatConstants.CRASH_STAMINA_COST)
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
		if not fid_b.is_empty() and manager.formations.has(fid_b):
			var form_b: Dictionary = manager.formations[fid_b]
			if not form_b.has("breached_files"):
				form_b["breached_files"] = {}
			var bf: Dictionary = form_b["breached_files"]
			var prev: float = float(bf.get(f_b, bf.get(str(f_b), 0.0)))
			bf[f_b] = maxf(prev, sev)
		manager._recompute_zoc_and_distance()
		if atk.get("formation_id", "") != fid_b and manager.has_method("notify_formation_changed"):
			manager.notify_formation_changed(str(atk.get("formation_id", "")))
		if not fid_b.is_empty():
			manager.notify_formation_changed(fid_b)
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_name: String = _EntityAccess.get_display_name(tgt, defender_id)
		var bf_line: String = ""
		var fid_b2: String = str(res.get("defender_formation_id", ""))
		if not fid_b2.is_empty() and manager.formations.has(fid_b2):
			var form_snap: Dictionary = manager.formations[fid_b2]
			bf_line = CombatDebug.format_breached_files(form_snap.get("breached_files", {}))
		print(
			"[Combat] Crash %s → %s: %s drive=%.1f hold=%.1f depth=%d file=%d sev=%.2f defender_breached_files[%s]"
			% [
				atk_name,
				tgt_name,
				"breach" if ok else "repelled",
				float(res.get("drive", 0.0)),
				float(res.get("hold", 1.0)),
				int(atk.get("tactical_penetration_depth", 0)),
				int(res.get("defender_file", -1)),
				float(res.get("breach_severity", 0.0)),
				bf_line if not bf_line.is_empty() else "—"
			]
		)
	manager.emit_signal(
		"action_resolved",
		attacker_id,
		defender_id,
		{
			"outcome": "crash_success" if ok else "crash_failed",
			"dmg": 0,
			"died": false,
			"tactical_penetration_depth": int(atk.get("tactical_penetration_depth", 0)),
			"breach_severity": float(res.get("breach_severity", 0.0)),
		}
	)
	manager._schedule_action_ready(attacker_id, CombatConstants.READY_DELAY_CRASH_ATTEMPT_S)
