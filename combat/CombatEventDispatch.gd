class_name CombatEventDispatch
extends RefCounted

## Drains the combat event queue and dispatches to CombatManager handlers.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")

static func process_event_queue(manager: Node) -> void:
	while manager.event_queue.size() > 0:
		var head_raw: Variant = manager.event_queue[0]
		if typeof(head_raw) != TYPE_DICTIONARY:
			manager.event_queue.pop_front()
			continue
		var head: Dictionary = head_raw as Dictionary
		if float(head.get("resolve_at", 0.0)) > _EntityAccess.combat_clock_float(manager):
			break
		var ev: Dictionary = manager.event_queue.pop_front() as Dictionary
		handle_event(manager, ev)


static func handle_event(manager: Node, ev: Dictionary) -> void:
	var ev_type: String = ev.get("type", "")
	var cid: int = ev.get("combatant_id", -1)
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, cid)
	if (
		ev_type != CombatConstants.EVENT_SWAP_RANK_RESOLVE
		and ev_type != CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE
		and ev_type != CombatConstants.EVENT_ROTATE_FILE_RESOLVE
		and not c.is_empty()
		and not _EntityAccess.alive_bool(c)
	):
		return
	if (
		_MedicalPhase.combat_resolution_blocked(manager)
		and _MedicalPhase.should_block_scheduled_event(manager, ev)
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
	if c.is_empty() or not _EntityAccess.alive_bool(c) or _EntityAccess.is_unconscious(c):
		return
	if _MedicalPhase.combat_resolution_blocked(manager) and _MedicalPhase.is_losing_side(manager, c):
		return
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
	var state: String = _EntityAccess.state_str(c)
	var retreat_only: bool = _MobilityRetreat.formation_retreat_only_for(c)
	var mobile_retreat_ready: bool = retreat_only and _EntityAccess.can_flee_or_fall_back(c)
	if _EntityAccess.is_incapacitated(c) and not mobile_retreat_ready:
		return
	if state != CombatConstants.STATE_WAITING and state != CombatConstants.STATE_COWERING:
		if CombatDebug.flow_verbose_enabled():
			var who: String = _EntityAccess.get_display_name(c)
			var cid: int = _EntityAccess.id_int(c)
			CombatDebug.flow_log(
				"EVENT_ACTION_READY skipped %s (id=%d state=%s)" % [who, cid, state],
				"action_ready_skip:%d" % cid
			)
		return
	c.gauge = 100.0
	c.erase("action_cooldown_until")
	if _EntityAccess.is_player_side(c):
		manager.notify_turn_ready(_EntityAccess.id_int(c))
	else:
		var actions: Array = manager.get_available_actions(_EntityAccess.id_int(c))
		CombatAIActionPicker.resolve_picked_turn_or_skip(manager, _EntityAccess.id_int(c), actions, "enemy")


static func handle_melee_attack(manager: Node, c: Dictionary) -> void:
	if _MedicalPhase.combat_resolution_blocked(manager):
		if not c.is_empty() and _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
			var cid_abort: int = _EntityAccess.id_int(c)
			_CounterTempo.abort_attacker_wind_up(manager, cid_abort)
			c.state = CombatConstants.STATE_WAITING
			c.state_timer = 0.0
			c.state_duration = 0.0
			c.gauge = 0.0
		return
	if c.is_empty() or not _EntityAccess.alive_bool(c) or _EntityAccess.state_str(c) != CombatConstants.STATE_WIND_UP:
		return
	if _MobilityRetreat.cannot_commit_melee(c):
		_CounterTempo.abort_attacker_wind_up(manager, _EntityAccess.id_int(c))
		return
	manager._execute_attack(_EntityAccess.id_int(c))
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, _EntityAccess.id_int(c))
	if (
		not atk.is_empty()
		and _EntityAccess.state_str(atk) == CombatConstants.STATE_RECOVERING
		and atk.state_duration > 0.0
	):
		_EntityAccess.manager_schedule_event(
			manager,
			{
				"type": CombatConstants.EVENT_RECOVERY_END,
				"combatant_id": _EntityAccess.id_int(c),
				"resolve_at": _EntityAccess.combat_clock_plus(manager, atk.state_duration),
				"data": {},
			}
		)


static func handle_recovery_end(manager: Node, c: Dictionary) -> void:
	if _MedicalPhase.combat_resolution_blocked(manager) and _MedicalPhase.is_losing_side(manager, c):
		return
	if c.is_empty() or not _EntityAccess.alive_bool(c) or _EntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING:
		return
	var cid: int = _EntityAccess.id_int(c)
	_EventScheduler.cancel_pending_action_ready(manager, cid)
	_StateHandlers.complete_recovery(manager, c)
	if _EntityAccess.state_str(c) in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
		if (
			_EntityAccess.state_str(c) == CombatConstants.STATE_WAITING
			or _EntityAccess.can_flee_or_fall_back(c)
		):
			_EventScheduler.schedule_action_ready_for_combatant(manager, c)
