class_name CombatFormationYield
extends RefCounted

## Voluntary surrender: stay on the field but stop fighting (duel disarm path).
## Canonical listing: **`CombatFormationMoveListing`**; resolve: **`CombatResolveAction`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")


static func yield_action_legal(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    if c.get("combat_absent", false):
        return false
    if not _EntityAccess.alive_bool(c):
        return false
    if _EntityAccess.is_yielded(c):
        return false
    var st: String = _EntityAccess.state_str(c)
    if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
        return false
    if _EntityAccess.rank_int(c) != 0:
        return false
    if not _FormationRout.duel_disarmed_retreat_menu(manager, c):
        return false
    return _MobilityRetreat.formation_retreat_only_for(c)


static func apply_yield(manager: Node, combatant_id: int) -> void:
    if manager == null or combatant_id < 0:
        return
    var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not yield_action_legal(manager, c):
        return
    _EventScheduler.cancel_pending_combat_events_for_combatant(manager, combatant_id)
    _Footwork.clear_on_exchange_end(c)
    c.state = CombatConstants.STATE_YIELDED
    _Footwork.reconcile_idle_offset(c)
    c.state_timer = 0.0
    c.state_duration = 0.0
    c.gauge = 0.0
    c.erase("formation_move_partner_id")
    _Doctrine.clear_combatant_doctrine_commitment(c)
    if CombatDebug.flow_verbose_enabled():
        CombatDebug.flow_log("yield id=%d %s" % [combatant_id, _EntityAccess.get_display_name(c, combatant_id)])
    manager.emit_signal("action_resolved", combatant_id, combatant_id, {"outcome": "yielded", "dmg": 0, "died": false})
    manager.emit_signal("turn_resolved", combatant_id)
    var winner: String = manager._check_for_winner() if manager.has_method("_check_for_winner") else ""
    if not winner.is_empty() and manager.has_method("_end_combat_phase"):
        manager._end_combat_phase(winner, null)
