class_name CombatLeaderFormationCommand
extends RefCounted

## IV-11: formation command issuer doctrine commands (doctrine shifts; instant turn, not slot movement).
## Canonical: **`CombatConstants.is_leader_formation_command_move`** . **`order_*_legal`** . **`apply_leader_command`**.


static func _leader_command_base_legal(manager: Node, c: Dictionary) -> bool:
    if not CombatConstants.is_feature_leader_formation_command_enabled():
        return false
    if manager == null or c.is_empty():
        return false
    if not CombatantEntityAccess.is_formation_command_issuer(c):
        return false
    if CombatantEntityAccess.rank_int(c) != 0:
        return false
    if not CombatantEntityAccess.alive_bool(c) or CombatantEntityAccess.is_incapacitated(c):
        return false
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        return false
    if CombatantEntityAccess.formation_id_str(c).is_empty():
        return false
    return true


static func _order_doctrine_switch_legal(manager: Node, c: Dictionary, active_doctrine: String) -> bool:
    if not _leader_command_base_legal(manager, c):
        return false
    return CombatDoctrine.doctrine_for_fid(manager, CombatantEntityAccess.formation_id_str(c)) != active_doctrine


static func order_hold_lane_legal(manager: Node, c: Dictionary) -> bool:
    return _order_doctrine_switch_legal(manager, c, CombatConstants.DOCTRINE_HOLD_LANE)


static func order_probing_legal(manager: Node, c: Dictionary) -> bool:
    return _order_doctrine_switch_legal(manager, c, CombatConstants.DOCTRINE_PROBING)


static func order_pinch_center_legal(manager: Node, c: Dictionary) -> bool:
    return _order_doctrine_switch_legal(manager, c, CombatConstants.DOCTRINE_PINCH_CENTER)


static func _apply_doctrine_order(
    manager: Node, combatant_id: int, c: Dictionary, doctrine: String, outcome: String
) -> bool:
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    manager.set_formation_doctrine(fid, doctrine)
    manager.emit_signal("action_resolved", combatant_id, combatant_id, {"outcome": outcome, "formation_id": fid})
    manager.turn_resolved.emit(combatant_id)
    CombatDebug.finish_instant_turn_and_schedule_ready(manager, c)
    return true


static func apply_order_hold_lane(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if not order_hold_lane_legal(manager, c):
        return false
    return _apply_doctrine_order(manager, combatant_id, c, CombatConstants.DOCTRINE_HOLD_LANE, "leader_order_hold_lane")


static func apply_order_probing(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if not order_probing_legal(manager, c):
        return false
    return _apply_doctrine_order(manager, combatant_id, c, CombatConstants.DOCTRINE_PROBING, "leader_order_probing")


static func apply_order_pinch_center(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if not order_pinch_center_legal(manager, c):
        return false
    return _apply_doctrine_order(
        manager, combatant_id, c, CombatConstants.DOCTRINE_PINCH_CENTER, "leader_order_pinch_center"
    )


static func _append_command_if_legal(
    manager: Node, c: Dictionary, combatant_id: int, actions: Array, move_id: String, legal_fn: Callable
) -> void:
    if not legal_fn.call(manager, c):
        return
    var entry: Dictionary = {"target_id": combatant_id, "move_id": move_id}
    actions.append(entry)
    CombatFormationMoveDuration.stamp_listed_action_duration_hint(manager, c, entry)


static func append_leader_formation_commands(manager: Node, c: Dictionary, combatant_id: int, actions: Array) -> void:
    if not CombatConstants.is_feature_leader_formation_command_enabled():
        return
    _append_command_if_legal(
        manager, c, combatant_id, actions, CombatConstants.MOVE_ID_ORDER_HOLD_LANE, order_hold_lane_legal
    )
    _append_command_if_legal(
        manager, c, combatant_id, actions, CombatConstants.MOVE_ID_ORDER_PROBING, order_probing_legal
    )
    _append_command_if_legal(
        manager, c, combatant_id, actions, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER, order_pinch_center_legal
    )


static func apply_leader_command(manager: Node, combatant_id: int, move_id: String) -> bool:
    match move_id:
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            return apply_order_hold_lane(manager, combatant_id)
        CombatConstants.MOVE_ID_ORDER_PROBING:
            return apply_order_probing(manager, combatant_id)
        CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
            return apply_order_pinch_center(manager, combatant_id)
    return false





