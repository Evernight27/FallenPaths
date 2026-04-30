class_name CombatEventDispatch
extends RefCounted

## Drains the combat event queue and dispatches to CombatManager handlers.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")

static func process_event_queue(manager: Node) -> void:
	while manager.event_queue.size() > 0 and manager.event_queue[0].get("resolve_at", 0.0) <= manager.combat_clock:
		var ev: Dictionary = manager.event_queue.pop_front()
		handle_event(manager, ev)


static func handle_event(manager: Node, ev: Dictionary) -> void:
	var ev_type: String = ev.get("type", "")
	var cid: int = ev.get("combatant_id", -1)
	var c = manager._get_by_id(cid)
	if ev_type != CombatConstants.EVENT_SWAP_RANK_RESOLVE and ev_type != CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE and ev_type != CombatConstants.EVENT_ROTATE_FILE_RESOLVE and c != null and not c.alive:
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
	if c == null or not c.alive or _EntityAccess.is_incapacitated(c):
		return
	if c.state != CombatConstants.STATE_WAITING:
		if CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE:
			var who: String = _EntityAccess.get_display_name(c) if c != null else "?"
			print("[Combat] EVENT_ACTION_READY skipped: %s (state=%s — hit/interrupted before turn; will act after recovery)" % [who, c.state])
		return
	c.gauge = 100.0
	c.erase("action_cooldown_until")
	if c.side == "player":
		manager.notify_turn_ready(c.id)
	else:
		var actions: Array = manager.get_available_actions(c.id)
		if actions.is_empty():
			manager.skip_turn(c.id, "pass", "no available actions")
		else:
			var choice = CombatAIActionPicker.pick(actions, c.id, manager)
			var opts: Dictionary = CombatAIActionPicker.opts_from_choice(choice)
			CombatDebug.flow_log_turn("enemy", c.id, actions, choice)
			manager.resolve_action(c.id, choice.target_id, choice.get("move_id", ""), opts)


static func handle_melee_attack(manager: Node, c: Dictionary) -> void:
	if c == null or not c.alive or c.state != CombatConstants.STATE_WIND_UP:
		return
	manager._execute_attack(c.id)
	var atk = manager._get_by_id(c.id)
	if atk != null and atk.state == CombatConstants.STATE_RECOVERING and atk.state_duration > 0.0:
		manager._schedule_event({
			"type": CombatConstants.EVENT_RECOVERY_END,
			"combatant_id": c.id,
			"resolve_at": manager.combat_clock + atk.state_duration,
			"data": {}
		})


static func handle_recovery_end(manager: Node, c: Dictionary) -> void:
	if c == null or not c.alive or c.state != CombatConstants.STATE_RECOVERING:
		return
	_StateHandlers.complete_recovery(c)
	if c.state == CombatConstants.STATE_WAITING:
		manager._schedule_action_ready(c.id, manager._action_ready_cooldown(c))
	elif c.state == CombatConstants.STATE_COWERING:
		pass
