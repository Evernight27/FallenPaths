class_name CombatMobilityRetreat
extends RefCounted

## Tier 6.1: cowering / no functional arms  -  retreat-only listing, resolve gates, arm-loss react.


static func _get_counter_tempo() -> GDScript:
    return CounterTempo


static func _get_event_scheduler() -> GDScript:
    return CombatEventScheduler


static func _get_state_handlers() -> GDScript:
    return CombatStateHandlers


static func formation_retreat_only_for(c: Dictionary) -> bool:
    if c.is_empty():
        return false
    return (
        CombatantEntityAccess.state_str(c) == CombatConstants.STATE_COWERING
        or CombatantEntityAccess.get_attacking_arm(c).is_empty()
    )


static func cannot_commit_melee(c: Dictionary) -> bool:
    return formation_retreat_only_for(c)


static func action_entry_is_self_target_move(a: Dictionary, combatant_id: int, move_id: String) -> bool:
    return CombatListedActions.action_entry_is_self_target_move(a, combatant_id, move_id)


static func actions_include_move_id(actions: Array, move_id: String) -> bool:
    return CombatListedActions.actions_include_move_id(actions, move_id)


static func actions_include_self_target_move(actions: Array, combatant_id: int, move_id: String) -> bool:
    return CombatListedActions.actions_include_self_target_move(actions, combatant_id, move_id)


static func first_action_with_move_id(actions: Array, move_id: String) -> Dictionary:
    return CombatListedActions.first_action_with_move_id(actions, move_id)


static func first_self_target_action(actions: Array, combatant_id: int, move_id: String) -> Dictionary:
    return CombatListedActions.first_self_target_action(actions, combatant_id, move_id)


## Harness / tests: first listed `move_id` outside retreat + medical allowlists (empty = ok).
static func first_disallowed_retreat_only_move_id(actions: Array) -> String:
    return (
        CombatListedActions
        . first_move_id_not_in_allowed_sets(
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
    )


static func resolve_move_allowed_when_cannot_melee(move_id: String, target_id: int, attacker_id: int) -> bool:
    if move_id == CombatConstants.MOVE_ID_WAIT:
        return true
    if CombatConstants.is_leader_formation_command_move(move_id) and target_id == attacker_id:
        return true
    return target_id == attacker_id and move_id in [
        CombatConstants.MOVE_ID_FALL_BACK,
        CombatConstants.MOVE_ID_FLEE,
        CombatConstants.MOVE_ID_YIELD,
    ]


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
    if CombatConstants.is_focus_line_move(move_id):
        return false
    if WeaponConstants.is_parry_move(move_id):
        return false
    return true


static func sync_cowering_state_if_no_functional_arm(c: Dictionary) -> void:
    if c.is_empty() or not formation_retreat_only_for(c):
        return
    var st: String = CombatantEntityAccess.state_str(c)
    if st == CombatConstants.STATE_COWERING:
        return
    if st in [CombatConstants.STATE_WIND_UP, CombatConstants.STATE_RECOVERING, CombatConstants.STATE_DEAD, CombatConstants.STATE_FALLING_BACK]:
        return
    CombatFootwork.return_to_cowering(c)


static func react_attacking_arm_lost_if_needed(manager: Node, c: Dictionary) -> void:
    if manager == null or c.is_empty() or not CombatantEntityAccess.is_cowering(c):
        return
    sync_cowering_state_if_no_functional_arm(c)
    var cid: int = CombatantEntityAccess.id_int(c)
    var st: String = CombatantEntityAccess.state_str(c)
    if st == CombatConstants.STATE_WIND_UP:
        CounterTempo.abort_attacker_wind_up(manager, cid)
        return
    if st == CombatConstants.STATE_RECOVERING:
        CombatEventScheduler.cancel_pending_recovery_end(manager, cid)
        CombatStateHandlers.complete_recovery(manager, c)
        st = CombatantEntityAccess.state_str(c)
    CombatEventScheduler.cancel_pending_action_ready(manager, cid)
    if st in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
        if CombatantEntityAccess.can_flee_or_fall_back(c):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, c)


static func filter_actions_for_retreat_only(actions: Array, c: Dictionary) -> Array:
    if not formation_retreat_only_for(c):
        return actions
    var cid: int = CombatantEntityAccess.id_int(c)
    return CombatListedActions.filter_actions(
        actions,
        func(a: Dictionary) -> bool:
            var mid: String = CombatListedActions.entry_move_id(a)
            if mid == CombatConstants.MOVE_ID_WAIT:
                return true
            return (
                action_entry_is_self_target_move(a, cid, CombatConstants.MOVE_ID_FALL_BACK)
                or (action_entry_is_self_target_move(a, cid, CombatConstants.MOVE_ID_FLEE))
            )
    )
