class_name CombatEventDispatch
extends RefCounted

## Drains the combat event queue and dispatches to CombatManager handlers.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")

static func process_event_queue(manager: Node) -> void:
	while manager.event_queue.size() > 0:
		var head_raw: Variant = manager.event_queue[0]
		if typeof(head_raw) != TYPE_DICTIONARY:
			manager.event_queue.pop_front()
			continue
		var head: Dictionary = head_raw as Dictionary
		if float(head.get("resolve_at", 0.0)) > manager.combat_clock:
			break
		var ev: Dictionary = manager.event_queue.pop_front() as Dictionary
		handle_event(manager, ev)


static func handle_event(manager: Node, ev: Dictionary) -> void:
	var ev_type: String = ev.get("type", "")
	var cid: int = ev.get("combatant_id", -1)
	var c: Dictionary = (
		_EntityAccess.combatant_dict_or_empty(manager._get_by_id(cid))
		if manager.has_method("_get_by_id")
		else {}
	)
	if (
		ev_type != CombatConstants.EVENT_SWAP_RANK_RESOLVE
		and ev_type != CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE
		and ev_type != CombatConstants.EVENT_ROTATE_FILE_RESOLVE
		and not c.is_empty()
		and not _EntityAccess.alive_bool(c)
	):
		return
	match ev_type:
		CombatConstants.EVENT_ACTION_READY:
			handle_action_ready(manager, c)
		CombatConstants.EVENT_MELEE_ATTACK:
			handle_melee_attack(manager, c)
		CombatConstants.EVENT_RECOVERY_END:
			handle_recovery_end(manager, c)
		CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			manager._handle_swap_rank_resolve(ev)
		CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE:
			manager._handle_fall_back_solo_resolve(ev)
		CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
			manager._handle_rotate_file_resolve(ev)


static func handle_action_ready(manager: Node, c: Dictionary) -> void:
	if c.is_empty() or not _EntityAccess.alive_bool(c) or _EntityAccess.is_incapacitated(c):
		return
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		if CombatDebug.flow_verbose_enabled():
			var who: String = _EntityAccess.get_display_name(c)
			var cid: int = _EntityAccess.id_int(c)
			CombatDebug.flow_log(
				"EVENT_ACTION_READY skipped %s (id=%d state=%s)" % [who, cid, _EntityAccess.state_str(c)],
				"action_ready_skip:%d" % cid
			)
		return
	c.gauge = 100.0
	c.erase("action_cooldown_until")
	if _EntityAccess.side_str(c) == "player":
		manager.notify_turn_ready(_EntityAccess.id_int(c))
	else:
		var actions: Array = manager.get_available_actions(_EntityAccess.id_int(c))
		if actions.is_empty():
			manager.skip_turn(_EntityAccess.id_int(c), "pass", "no available actions")
		else:
			var choice = CombatAIActionPicker.pick(actions, _EntityAccess.id_int(c), manager)
			var opts: Dictionary = CombatAIActionPicker.opts_from_choice(choice)
			CombatDebug.flow_log_turn("enemy", _EntityAccess.id_int(c), actions, choice)
			manager.resolve_action(_EntityAccess.id_int(c), choice.target_id, choice.get("move_id", ""), opts)


static func handle_melee_attack(manager: Node, c: Dictionary) -> void:
	if c.is_empty() or not _EntityAccess.alive_bool(c) or _EntityAccess.state_str(c) != CombatConstants.STATE_WIND_UP:
		return
	manager._execute_attack(_EntityAccess.id_int(c))
	var atk: Dictionary = _EntityAccess.combatant_dict_or_empty(
		manager._get_by_id(_EntityAccess.id_int(c)) if manager.has_method("_get_by_id") else null
	)
	if (
		not atk.is_empty()
		and _EntityAccess.state_str(atk) == CombatConstants.STATE_RECOVERING
		and atk.state_duration > 0.0
	):
		manager._schedule_event({
			"type": CombatConstants.EVENT_RECOVERY_END,
			"combatant_id": _EntityAccess.id_int(c),
			"resolve_at": manager.combat_clock + atk.state_duration,
			"data": {}
		})


static func handle_recovery_end(manager: Node, c: Dictionary) -> void:
	if c.is_empty() or not _EntityAccess.alive_bool(c) or _EntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING:
		return
	_StateHandlers.complete_recovery(c)
	if _EntityAccess.state_str(c) == CombatConstants.STATE_WAITING:
		manager._schedule_action_ready(_EntityAccess.id_int(c), manager._action_ready_cooldown(c))
	elif _EntityAccess.state_str(c) == CombatConstants.STATE_COWERING:
		pass
