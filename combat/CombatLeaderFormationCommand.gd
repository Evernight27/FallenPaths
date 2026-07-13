class_name CombatLeaderFormationCommand
extends RefCounted

## IV-11: formation command issuer doctrine commands (doctrine shifts; instant turn, not slot movement).
## Canonical: **`CombatConstants.is_leader_formation_command_move`** . **`order_*_legal`** . **`apply_leader_command`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _MoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")


static func _leader_command_base_legal(manager: Node, c: Dictionary) -> bool:
    if not CombatConstants.is_feature_leader_formation_command_enabled():
        return false
    if manager == null or c.is_empty():
        return false
    if not _EntityAccess.is_formation_command_issuer(c):
        return false
    if _EntityAccess.rank_int(c) != 0:
        return false
    if not _EntityAccess.alive_bool(c) or _EntityAccess.is_incapacitated(c):
        return false
    if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        return false
    if _EntityAccess.formation_id_str(c).is_empty():
        return false
    return true


static func _order_doctrine_switch_legal(manager: Node, c: Dictionary, active_doctrine: String) -> bool:
    if not _leader_command_base_legal(manager, c):
        return false
    return _Doctrine.doctrine_for_fid(manager, _EntityAccess.formation_id_str(c)) != active_doctrine


static func order_hold_lane_legal(manager: Node, c: Dictionary) -> bool:
    return _order_doctrine_switch_legal(manager, c, CombatConstants.DOCTRINE_HOLD_LANE)


static func order_probing_legal(manager: Node, c: Dictionary) -> bool:
    return _order_doctrine_switch_legal(manager, c, CombatConstants.DOCTRINE_PROBING)


static func order_pinch_center_legal(manager: Node, c: Dictionary) -> bool:
    return _order_doctrine_switch_legal(manager, c, CombatConstants.DOCTRINE_PINCH_CENTER)


static func _apply_doctrine_order(
    manager: Node, combatant_id: int, c: Dictionary, doctrine: String, outcome: String
) -> bool:
    var fid: String = _EntityAccess.formation_id_str(c)
    manager.set_formation_doctrine(fid, doctrine)
    manager.emit_signal("action_resolved", combatant_id, combatant_id, {"outcome": outcome, "formation_id": fid})
    manager.emit_signal("turn_resolved", combatant_id)
    CombatDebug.finish_instant_turn_and_schedule_ready(manager, c)
    return true


static func apply_order_hold_lane(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
    if not order_hold_lane_legal(manager, c):
        return false
    return _apply_doctrine_order(manager, combatant_id, c, CombatConstants.DOCTRINE_HOLD_LANE, "leader_order_hold_lane")


static func apply_order_probing(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
    if not order_probing_legal(manager, c):
        return false
    return _apply_doctrine_order(manager, combatant_id, c, CombatConstants.DOCTRINE_PROBING, "leader_order_probing")


static func apply_order_pinch_center(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
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
    _MoveDuration.stamp_listed_action_duration_hint(manager, c, entry)


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
