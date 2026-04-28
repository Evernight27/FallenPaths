class_name MedicalWindUpHandler
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Handles completion of medical wind-up: apply bandage/packing/tourniquet, emit outcome, track retry.
## Manager must have: get_health_entity (via CombatantEntityAccess), _track_medical_failure_and_maybe_retry, emit_signal, get.

static func complete(manager: Node, c: Dictionary, pm: Dictionary) -> void:
	var med_id: String = pm.get("medical_id", "")
	var part: String = pm.get("target_part", "")
	var tgt_cid: int = pm.get("target_combatant_id", c.id)
	var tgt_c = manager._get_by_id(tgt_cid)
	var who_m: String = _EntityAccess.get_display_name(c)
	# Recovery after medical (scaled by pain/consciousness)
	var med_rec_dur: float = CombatConstants.RECOVERY_AFTER_MEDICAL_S
	var med_perf: float = 1.0
	if c.node != null and c.node.has_method("get_performance_modifier"):
		med_perf = c.node.get_performance_modifier()
	if med_perf > 0.0:
		med_rec_dur /= maxf(CombatConstants.PERF_MOD_MIN, med_perf)
	# Only apply if target is still alive (may have died during wind-up)
	var tgt_alive: bool = tgt_c != null and tgt_c.alive and (not tgt_c.node.has_method("is_dead") or not tgt_c.node.is_dead())
	if tgt_c != null and tgt_c.node != null and tgt_alive and not part.is_empty():
		var wind_up_cfg = CombatConstants.MEDICAL_WIND_UP_CONFIG.get(med_id, {})
		var target_method: String = wind_up_cfg.get("target_method", "")
		if not target_method.is_empty():
			var tgt_entity = _EntityAccess.get_entity_from_manager(manager, tgt_c)
			if tgt_entity != null and tgt_entity.has_method(target_method):
				var perf_entity = _EntityAccess.get_entity_from_manager(manager, c)
				var eff: float = _EntityAccess.get_medical_effectiveness_from_node(perf_entity)
				var result = null
				if target_method == "apply_bandage":
					result = tgt_entity.call(target_method, part, eff)
				elif target_method == "apply_packing":
					result = tgt_entity.call(target_method, part, eff)
				elif target_method == "apply_tourniquet":
					result = tgt_entity.call(target_method, part, eff)
				else:
					result = tgt_entity.call(target_method, part)
				var outcome: String
				if target_method == "apply_bandage":
					outcome = "bandaged" if result == true else "bandage_failed"
					print("[Combat] Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_id, part, outcome, med_rec_dur])
					manager.emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false, "effectiveness": eff})
					if result != true:
						manager._track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
					else:
						c.pending_retry = {}
				elif target_method == "apply_packing":
					outcome = "packed" if result == true else "packing_failed"
					print("[Combat] Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_id, part, outcome, med_rec_dur])
					manager.emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false, "effectiveness": eff})
					if result != true:
						manager._track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
					else:
						c.pending_retry = {}
				elif target_method == "apply_tourniquet":
					outcome = "tourniquet_applied" if result == true else "tourniquet_failed"
					print("[Combat] Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_id, part, outcome, med_rec_dur])
					manager.emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false, "effectiveness": eff})
					if result != true:
						manager._track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
					else:
						c.pending_retry = {}
				elif result != false:
					outcome = wind_up_cfg.get("outcome", med_id)
					print("[Combat] Medical complete: %s %s on %s => recovery %.1fs" % [who_m, med_id, part, med_rec_dur])
					manager.emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false})
	# Target finishes receiving care: ready to act immediately
	if tgt_c != null and tgt_cid != c.id:
		tgt_c.receiving_medical_count = max(0, tgt_c.get("receiving_medical_count", 0) - 1)
		if tgt_c.receiving_medical_count <= 0:
			tgt_c.state = CombatConstants.STATE_WAITING
			tgt_c.gauge = 100.0
			tgt_c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
			if tgt_c.side == "player":
				manager.notify_turn_ready(tgt_cid)
	c.state = CombatConstants.STATE_RECOVERING
	c.state_timer = 0.0
	c.state_duration = med_rec_dur
