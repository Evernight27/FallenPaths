class_name CombatFormationYield
extends RefCounted

## Voluntary surrender: stay on the field but stop fighting (duel disarm path).
## Canonical listing: **`CombatFormationMoveListing`**; resolve: **`CombatResolveAction`**.


static func yield_action_legal(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    if c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false):
        return false
    if not CombatantEntityAccess.alive_bool(c):
        return false
    if CombatantEntityAccess.is_yielded(c):
        return false
    var st: String = CombatantEntityAccess.state_str(c)
    if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
        return false
    if CombatantEntityAccess.rank_int(c) != 0:
        return false
    if not CombatFormationRout.duel_disarmed_retreat_menu(manager, c):
        return false
    return CombatMobilityRetreat.formation_retreat_only_for(c)


static func apply_yield(manager: Node, combatant_id: int) -> void:
    if manager == null or combatant_id < 0:
        return
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not yield_action_legal(manager, c):
        return
    CombatEventScheduler.cancel_pending_combat_events_for_combatant(manager, combatant_id)
    CombatFootwork.clear_on_exchange_end(c)
    c.state = CombatConstants.STATE_YIELDED
    CombatFootwork.reconcile_idle_offset(c)
    c.state_timer = 0.0
    c.state_duration = 0.0
    c.gauge = 0.0
    c.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    CombatDoctrine.clear_combatant_doctrine_commitment(c)
    if CombatDebug.flow_verbose_enabled():
        CombatDebug.flow_log("yield id=%d %s" % [combatant_id, CombatantEntityAccess.get_display_name(c, combatant_id)])
    manager.emit_signal("action_resolved", combatant_id, combatant_id, {"outcome": "yielded", "dmg": 0, "died": false})
    manager.turn_resolved.emit(combatant_id)
    var winner: String = manager._check_for_winner() if manager.has_method("_check_for_winner") else ""
    if not winner.is_empty() and manager.has_method("_end_combat_phase"):
        manager._end_combat_phase(winner, null)




