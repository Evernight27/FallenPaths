class_name CombatResolveAction
extends RefCounted

## Player/AI action dispatch: medical, close, crash, formation moves, melee wind-up scheduling.

const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")


static func is_medical_move(move_id: String) -> bool:
	return move_id in CombatConstants.MEDICAL_MOVE_IDS


static func resolve(manager: Node, attacker_id: int, target_id: int, move_id: String, options: Dictionary) -> void:
	var atk = manager._get_by_id(attacker_id)
	if atk == null:
		return
	if atk.state == CombatConstants.STATE_WAITING and atk.gauge < 100.0 and not manager.medical_phase:
		return
	if atk.state == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION and move_id == "apply_direct_pressure" and target_id == attacker_id:
		atk.receiving_care_turn_pending = false
		atk.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
		var part: String = str(options.get("target_part", ""))
		if part.is_empty():
			return
		var parts_being_treated: Array = manager._get_parts_being_treated_on(attacker_id)
		if part in parts_being_treated:
			return
		var entity = _EntityAccess.get_entity_from_manager(manager, atk)
		if entity != null and entity.has_method("apply_direct_pressure") and entity.apply_direct_pressure(part):
			var who: String = _EntityAccess.get_display_name(atk, attacker_id)
			print("[Combat] %s (receiving care) holding direct pressure on %s" % [who, part])
			manager.emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false})
			manager.emit_signal("turn_resolved", attacker_id)
		return
	if atk.state != CombatConstants.STATE_WAITING:
		return
	if move_id == CombatConstants.MOVE_ID_WAIT:
		manager.skip_turn(attacker_id, "wait", "explicit wait move")
		return
	if is_medical_move(move_id):
		var part: String = str(options.get("target_part", ""))
		var who: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_desc: String = "ally" if target_id != attacker_id else "self"
		CombatDebug.flow_log("resolve_action id=%d medical %s part=%s (%s)" % [attacker_id, move_id, part, tgt_desc])
		print("[Combat] Action: %s chose medical %s on part=%s (%s)" % [who, move_id, part, tgt_desc])
		MedicalActionStarter.start(manager, attacker_id, target_id, move_id, part)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	var tgt = manager._get_by_id(target_id)
	if tgt == null or not tgt.alive:
		return
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		CombatDebug.flow_log("resolve_action id=%d move=attempt_close target_id=%d" % [attacker_id, target_id])
		if CombatConstants.COMBAT_EVENT_DEBUG:
			var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
			var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
			print("[Combat] %s attempting to close on %s (tactical distance — pressure vs evasion roll)" % [atk_name, tgt_name])
		manager._resolve_close_attempt(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_CRASH:
		if int(atk.get("rank", 0)) != 0:
			return
		if str(atk.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			return
		CombatDebug.flow_log("resolve_action id=%d move=crash target_id=%d" % [attacker_id, target_id])
		manager._resolve_crash_attempt(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK, CombatConstants.MOVE_ID_ROTATE_FILE]:
		var move_policy: Dictionary = _EngagementMode.movement_policy(manager)
		if move_id == CombatConstants.MOVE_ID_SWAP_RANK and not bool(move_policy.get("allow_swap_rank", false)):
			return
		if move_id == CombatConstants.MOVE_ID_DRAG_BACK and not bool(move_policy.get("allow_drag_back", false)):
			return
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and not bool(move_policy.get("allow_fall_back", false)):
			return
		if move_id == CombatConstants.MOVE_ID_ROTATE_FILE and not bool(move_policy.get("allow_rotate_file", false)):
			return
		var fid_mv: String = atk.get("formation_id", "")
		var f_mv: Dictionary = manager.formations.get(fid_mv, {})
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id:
			if not AvailableActionsBuilder.solo_fall_back_action_legal(manager, atk):
				CombatDebug.flow_log(
					"resolve_action solo fall_back rejected id=%d fid=%s (discipline/state/breach/fill)"
					% [attacker_id, fid_mv]
				)
				return
		var breach_blocked: bool = false
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id:
			breach_blocked = _FormationBreachRules.breach_blocks_open_lane_moves(manager, f_mv)
		else:
			var partner_mv = manager._get_by_id(target_id)
			if partner_mv == null or not partner_mv.alive:
				return
			breach_blocked = _FormationBreachRules.resolve_blocks_formation_move(
				manager, f_mv, move_id, atk, partner_mv
			)
		if breach_blocked:
			CombatDebug.flow_log(
				"resolve_action formation move blocked breach_blocks_moves id=%d move=%s fid=%s breached[%s]"
				% [
					attacker_id,
					move_id,
					fid_mv,
					CombatDebug.format_breached_files(f_mv.get("breached_files", {}))
				]
			)
			return
		CombatDebug.flow_log("resolve_action id=%d formation move_id=%s target_id=%d" % [attacker_id, move_id, target_id])
	if move_id == CombatConstants.MOVE_ID_SWAP_RANK:
		manager._start_formation_pair_move(attacker_id, target_id, "swap_rank")
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_DRAG_BACK:
		manager._start_formation_pair_move(attacker_id, target_id, "drag_back")
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_FALL_BACK:
		if target_id == attacker_id:
			manager._start_fall_back_solo(attacker_id)
		else:
			manager._start_formation_pair_move(attacker_id, target_id, "fall_back_pair")
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_ROTATE_FILE:
		if int(atk.get("rank", 0)) != 0:
			return
		if str(atk.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			return
		manager._start_rotate_file(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	CombatDebug.flow_log("resolve_action id=%d melee move_id=%s target_id=%d" % [attacker_id, move_id, target_id])
	if atk.node != null and atk.node.has_method("clear_direct_pressure"):
		if atk.node.has_method("is_applying_direct_pressure") and atk.node.is_applying_direct_pressure():
			print("[Combat] %s taking another action => clear_direct_pressure (was holding %s)" % [atk.node.name if atk.node else "id:%d" % attacker_id, atk.node.get_direct_pressure_part() if atk.node.has_method("get_direct_pressure_part") else "?"])
		atk.node.clear_direct_pressure()
	var opts: Dictionary = {}
	if options.has("target_part"):
		opts["target_part"] = options.target_part
	if options.has("feint_part"):
		opts["feint_part"] = options.feint_part
	_WindUpStarter.start(manager, attacker_id, target_id, move_id, opts)
	_TargetScoring.on_combat_commitment(manager, attacker_id, target_id)
	manager.emit_signal("turn_resolved", attacker_id)
	if atk.state == CombatConstants.STATE_WIND_UP and atk.state_duration > 0.0:
		manager._schedule_event({
			"type": CombatConstants.EVENT_MELEE_ATTACK,
			"combatant_id": attacker_id,
			"resolve_at": manager.combat_clock + atk.state_duration,
			"data": {}
		})
