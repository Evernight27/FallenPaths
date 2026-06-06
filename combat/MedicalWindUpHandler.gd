class_name MedicalWindUpHandler
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

## Handles completion of medical wind-up: apply bandage/packing/tourniquet, emit outcome, track retry.
## Footing: medic **`clear_on_exchange_end`** before post-care **`STATE_RECOVERING`** — LIVE_PATHS **`#wf-tier-44-pa`**.
## Manager must have: get_health_entity (via CombatantEntityAccess), _track_medical_failure_and_maybe_retry, emit_signal, get.

static func complete(manager: Node, c: Dictionary, pm: Dictionary) -> void:
	var med_id: String = pm.get("medical_id", "")
	var part: String = pm.get("target_part", "")
	var tgt_cid: int = pm.get("target_combatant_id", _EntityAccess.id_int(c))
	var tgt_c: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_cid)
	var tgt_nd: Node = _EntityAccess.scene_node(tgt_c)
	var who_m: String = _EntityAccess.get_display_name(c)
	# Recovery after medical (scaled by pain/consciousness)
	var med_rec_dur: float = CombatConstants.RECOVERY_AFTER_MEDICAL_S
	var med_perf: float = _EntityAccess.get_performance_modifier(c)
	if med_perf > 0.0:
		med_rec_dur /= maxf(CombatConstants.PERF_MOD_MIN, med_perf)
	# Only apply if target is still alive (may have died during wind-up)
	var tgt_alive: bool = not tgt_c.is_empty() and _EntityAccess.is_alive_in_combat(tgt_c)
	if not tgt_c.is_empty() and tgt_nd != null and tgt_alive and not part.is_empty():
		var wind_raw: Variant = CombatConstants.MEDICAL_WIND_UP_CONFIG.get(med_id, {})
		var wind_up_cfg: Dictionary = wind_raw if wind_raw is Dictionary else {}
		var target_method: String = wind_up_cfg.get("target_method", "")
		if not target_method.is_empty():
			var tgt_entity: Node = _EntityAccess.get_entity_from_manager(manager, tgt_c)
			var perf_entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
			var had_treatment_assist: bool = (
				tgt_entity != null
				and tgt_entity.get("direct_pressure_assist_held_by") != null
				and tgt_entity.direct_pressure_assist_held_by != null
			)
			var eff: float = _EntityAccess.get_medical_effectiveness_from_node(perf_entity)
			if had_treatment_assist:
				eff += CombatConstants.MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS
				eff = clampf(eff, 0.0, 1.5)
			var result: Variant = _EntityAccess.entity_invoke_medical_method(
				tgt_entity, target_method, part, eff
			)
			if result != null:
				_finish_medical_procedure(
					manager, c, tgt_c, tgt_cid, med_id, part, who_m, med_rec_dur,
					target_method, result, eff, wind_up_cfg
				)
				var world: Node2D = _CompanyState.resolve_world_from_battle(manager)
				if world != null:
					_CompanyState.on_battle_medical_complete(
						world, target_method, _medical_procedure_succeeded(result)
					)
	# Target finishes receiving care: ready to act immediately
	if not tgt_c.is_empty() and tgt_cid != _EntityAccess.id_int(c):
		tgt_c.receiving_medical_count = max(0, tgt_c.get("receiving_medical_count", 0) - 1)
		if tgt_c.receiving_medical_count <= 0:
			_Footwork.return_to_waiting(tgt_c)
			tgt_c.gauge = 100.0
			tgt_c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
			if _EntityAccess.is_player_side(tgt_c):
				manager.notify_turn_ready(tgt_cid)
	_Footwork.clear_on_exchange_end(c)
	c.state = CombatConstants.STATE_RECOVERING
	c.state_timer = 0.0
	c.state_duration = med_rec_dur


static func _medical_procedure_succeeded(result: Variant) -> bool:
	if result == true:
		return true
	if result is Dictionary:
		return bool((result as Dictionary).get("success", false))
	return false


static func _outcome_for_medical_method(
	target_method: String, result: Variant, wind_up_cfg: Dictionary, med_id: String
) -> String:
	var ok: bool = _medical_procedure_succeeded(result)
	match target_method:
		"apply_bandage":
			return "bandaged" if ok else "bandage_failed"
		"apply_stabilize":
			return "stabilized" if ok else "stabilize_failed"
		"apply_packing":
			return "packed" if ok else "packing_failed"
		"apply_tourniquet":
			return "tourniquet_applied" if ok else "tourniquet_failed"
		_:
			return str(wind_up_cfg.get("outcome", med_id))


static func _finish_medical_procedure(
	manager: Node,
	c: Dictionary,
	tgt_c: Dictionary,
	tgt_cid: int,
	med_id: String,
	part: String,
	who_m: String,
	med_rec_dur: float,
	target_method: String,
	result: Variant,
	eff: float,
	wind_up_cfg: Dictionary
) -> void:
	var tracked: bool = target_method in [
		"apply_bandage", "apply_stabilize", "apply_packing", "apply_tourniquet"
	]
	if tracked:
		var outcome: String = _outcome_for_medical_method(target_method, result, wind_up_cfg, med_id)
		var med_log: String = med_id
		if tgt_cid != _EntityAccess.id_int(c):
			med_log = "%s (ally)" % med_id
		_CombatDebug.medical_session(
			"Medical complete: %s %s on %s => %s, recovery %.1fs"
			% [who_m, med_log, part, outcome, med_rec_dur]
		)
		var self_id: int = _EntityAccess.id_int(c)
		manager.emit_signal(
			"action_resolved",
			self_id,
			tgt_cid,
			{
				"outcome": outcome,
				"part": part,
				"dmg": 0,
				"died": false,
				"effectiveness": eff,
				"medical_move_id": med_id,
				"medical_target_is_self": tgt_cid == self_id,
			}
		)
		if not _medical_procedure_succeeded(result):
			manager._track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
		else:
			c.pending_retry = {}
			var failed: Array = _EntityAccess.nested_array_for_mutation(tgt_c, "failed_medical_parts")
			var idx: int = failed.find(part)
			if idx >= 0:
				failed.remove_at(idx)
	elif result != false:
		var outcome: String = _outcome_for_medical_method(target_method, result, wind_up_cfg, med_id)
		_CombatDebug.medical_session(
			"Medical complete: %s %s on %s => recovery %.1fs" % [who_m, med_id, part, med_rec_dur]
		)
		manager.emit_signal(
			"action_resolved",
			_EntityAccess.id_int(c),
			tgt_cid,
			{"outcome": outcome, "part": part, "dmg": 0, "died": false}
		)
