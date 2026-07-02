class_name CombatMobilityRetreat
extends RefCounted

## Tier 6.1: cowering / no functional arms  -  retreat-only listing, resolve gates, arm-loss react.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")

static func _get_counter_tempo() -> GDScript:
	return _CounterTempo

static func _get_event_scheduler() -> GDScript:
	return _EventScheduler

static func _get_state_handlers() -> GDScript:
	return _StateHandlers

const _Footwork := preload("res://combat/CombatFootwork.gd")


static func formation_retreat_only_for(c: Dictionary) -> bool:
	if c.is_empty():
		return false
	return (
		_EntityAccess.state_str(c) == CombatConstants.STATE_COWERING
		or _EntityAccess.get_attacking_arm(c).is_empty()
	)


static func cannot_commit_melee(c: Dictionary) -> bool:
	return formation_retreat_only_for(c)


static func action_entry_is_self_target_move(
	a: Dictionary, combatant_id: int, move_id: String
) -> bool:
	return _ListedActions.action_entry_is_self_target_move(a, combatant_id, move_id)


static func actions_include_move_id(actions: Array, move_id: String) -> bool:
	return _ListedActions.actions_include_move_id(actions, move_id)


static func actions_include_self_target_move(
	actions: Array, combatant_id: int, move_id: String
) -> bool:
	return _ListedActions.actions_include_self_target_move(actions, combatant_id, move_id)


static func first_action_with_move_id(actions: Array, move_id: String) -> Dictionary:
	return _ListedActions.first_action_with_move_id(actions, move_id)


static func first_self_target_action(
	actions: Array, combatant_id: int, move_id: String
) -> Dictionary:
	return _ListedActions.first_self_target_action(actions, combatant_id, move_id)


## Harness / tests: first listed `move_id` outside retreat + medical allowlists (empty = ok).
static func first_disallowed_retreat_only_move_id(actions: Array) -> String:
	return _ListedActions.first_move_id_not_in_allowed_sets(
		actions,
		[
			[
				CombatConstants.MOVE_ID_WAIT,
				CombatConstants.MOVE_ID_FALL_BACK,
				CombatConstants.MOVE_ID_FLEE,
				CombatConstants.MOVE_ID_YIELD,
			],
			CombatConstants.MEDICAL_MOVE_IDS,
		]
	)


static func resolve_move_allowed_when_cannot_melee(
	move_id: String, target_id: int, attacker_id: int
) -> bool:
	if move_id == CombatConstants.MOVE_ID_WAIT:
		return true
	if CombatConstants.is_leader_formation_command_move(move_id) and target_id == attacker_id:
		return true
	return (
		(move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id)
		or (move_id == CombatConstants.MOVE_ID_FLEE and target_id == attacker_id)
		or (move_id == CombatConstants.MOVE_ID_YIELD and target_id == attacker_id)
	)


static func is_offensive_melee_move_id(move_id: String) -> bool:
	if move_id.is_empty():
		return false
	if resolve_move_allowed_when_cannot_melee(move_id, -1, -1):
		return false
	if CombatConstants.is_medical_move(move_id):
		return false
	if CombatConstants.is_formation_movement_move(move_id):
		return false
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return true
	if CombatConstants.is_leader_formation_command_move(move_id):
		return false
	if CombatConstants.is_focus_line_move(move_id):
		return false
	if WeaponConstants.is_parry_move(move_id):
		return false
	return true


static func sync_cowering_state_if_no_functional_arm(c: Dictionary) -> void:
	if c.is_empty() or not formation_retreat_only_for(c):
		return
	if _EntityAccess.state_str(c) == CombatConstants.STATE_COWERING:
		return
	if _EntityAccess.state_str(c) in [
		CombatConstants.STATE_WIND_UP,
		CombatConstants.STATE_RECOVERING,
		CombatConstants.STATE_DEAD,
	]:
		return
	_Footwork.return_to_cowering(c)


static func react_attacking_arm_lost_if_needed(manager: Node, c: Dictionary) -> void:
	if manager == null or c.is_empty() or not _EntityAccess.is_cowering(c):
		return
	sync_cowering_state_if_no_functional_arm(c)
	var cid: int = _EntityAccess.id_int(c)
	var st: String = _EntityAccess.state_str(c)
	if st == CombatConstants.STATE_WIND_UP:
		_CounterTempo.abort_attacker_wind_up(manager, cid)
		return
	if st == CombatConstants.STATE_RECOVERING:
		_EventScheduler.cancel_pending_recovery_end(manager, cid)
		_StateHandlers.complete_recovery(manager, c)
		st = _EntityAccess.state_str(c)
	_EventScheduler.cancel_pending_action_ready(manager, cid)
	if st in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
		if _EntityAccess.can_flee_or_fall_back(c):
			_EventScheduler.schedule_action_ready_for_combatant(manager, c)


static func filter_actions_for_retreat_only(actions: Array, c: Dictionary) -> Array:
	if not formation_retreat_only_for(c):
		return actions
	var cid: int = _EntityAccess.id_int(c)
	return _ListedActions.filter_actions(
		actions,
		func(a: Dictionary) -> bool:
			var mid: String = _ListedActions.entry_move_id(a)
			if mid == CombatConstants.MOVE_ID_WAIT:
				return true
			return action_entry_is_self_target_move(a, cid, CombatConstants.MOVE_ID_FALL_BACK) or (
				action_entry_is_self_target_move(a, cid, CombatConstants.MOVE_ID_FLEE)
			)
	)
