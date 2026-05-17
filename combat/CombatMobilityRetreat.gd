class_name CombatMobilityRetreat
extends RefCounted

## Tier 6.1: cowering / no functional arms — retreat-only listing, resolve gates, arm-loss react.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")


static func formation_retreat_only_for(c: Dictionary) -> bool:
	if c.is_empty():
		return false
	return (
		_EntityAccess.state_str(c) == CombatConstants.STATE_COWERING
		or _EntityAccess.get_attacking_arm(c).is_empty()
	)


static func cannot_commit_melee(c: Dictionary) -> bool:
	return formation_retreat_only_for(c)


static func resolve_move_allowed_when_cannot_melee(
	move_id: String, target_id: int, attacker_id: int
) -> bool:
	if move_id == CombatConstants.MOVE_ID_WAIT:
		return true
	return move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id


static func is_offensive_melee_move_id(move_id: String) -> bool:
	if move_id.is_empty():
		return false
	if resolve_move_allowed_when_cannot_melee(move_id, -1, -1):
		return false
	if move_id in CombatConstants.MEDICAL_MOVE_IDS:
		return false
	if move_id in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
		return false
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return true
	if move_id == CombatConstants.MOVE_ID_CRASH:
		return true
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
	c.state = CombatConstants.STATE_COWERING


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
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_WAIT:
			out.append(a)
		elif mid == CombatConstants.MOVE_ID_FALL_BACK and int(a.get("target_id", -1)) == cid:
			out.append(a)
	return out
