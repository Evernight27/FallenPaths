class_name CombatFormationFlee
extends RefCounted

## Tier 6.2: abandon the engagement (leave the field) vs tactical **`fall_back`** within formation.
## Footing: **`clear_on_exchange_end`** + idle scrub on **`STATE_FLED`**  -  LIVE_PATHS **`#wf-tier-44-pa`**.
## Rout policy: **`CombatFormationRout`** (`line_cohesion` + side casualty ratio); listing via
## **`flee_abandonment_warranted`**.


static func flee_action_legal(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    CombatFormationRout.ensure_rout_baseline(manager)
    if c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false):
        return false
    if not CombatantEntityAccess.can_flee_or_fall_back(c):
        return false
    if not CombatantEntityAccess.alive_bool(c):
        return false
    var st: String = CombatantEntityAccess.state_str(c)
    if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
        return false
    if CombatFormationMoveListing.in_pair_abort_cooldown(manager, c):
        return false
    if CombatMobilityRetreat.formation_retreat_only_for(c):
        var no_attacking_arm: bool = CombatantEntityAccess.get_attacking_arm(c).is_empty()
        var alone: bool = _is_cowering_alone_on_side(manager, c)
        if no_attacking_arm and alone:
            CombatF5SoakTrace.note_cowering_no_fall_back_alone(CombatantEntityAccess.get_display_name(c))
            return false
    if not CombatantEntityAccess.flee_abandonment_warranted(c, manager):
        return false
    return not CombatFormationMoveListing.solo_fall_back_action_legal(manager, c)


## Verbose build trace when **`flee`** is listed (cohesion / casualties / holding field).
static func log_flee_listed_if_verbose(manager: Node, c: Dictionary) -> void:
    if not CombatDebug.flow_verbose_enabled() or manager == null or c.is_empty():
        return
    var ctx: Dictionary = CombatFormationRout.rout_context_snapshot(manager, c)
    (
        CombatDebug
        . flow_log(
            (
                "flee_listed id=%d %s cohesion=%.2f casualty=%.2f stressed=%s holding=%s"
                % [
                    CombatantEntityAccess.id_int(c),
                    CombatantEntityAccess.get_display_name(c, CombatantEntityAccess.id_int(c)),
                    ctx.get(DataKeys.FORMATION_LINE_COHESION, 0.0),
                    ctx.get(DataKeys.FLEE_CTX_CASUALTY_RATIO, 0.0),
                    str(ctx.get(DataKeys.FLEE_CTX_FORMATION_STRESSED, false)),
                    str(ctx.get(DataKeys.FLEE_CTX_SIDE_HOLDING_FIELD, false)),
                ]
            )
        )
    )


static func apply_flee(manager: Node, combatant_id: int) -> void:
    if manager == null or combatant_id < 0:
        return
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not flee_action_legal(manager, c):
        return
    var st: String = CombatantEntityAccess.state_str(c)
    if st in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]:
        var pid: int = c.get(DataKeys.FM_FORMATION_MOVE_PARTNER_ID, -1)
        var partner: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, pid)
        if not partner.is_empty():
            CombatFormationFlow.abort_pair(manager, c, partner, CombatConstants.MOVE_ID_FLEE)
    CombatEventScheduler.cancel_pending_combat_events_for_combatant(manager, combatant_id)
    CombatFootwork.clear_on_exchange_end(c)
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if not fid.is_empty():
        var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
        if not formation.is_empty():
            var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
            FormationSlots.remove_combatant_from_slots(slots, combatant_id)
    c[DataKeys.COMBATANT_COMBAT_ABSENT] = true
    c.state = CombatConstants.STATE_FLED
    CombatFootwork.reconcile_idle_offset(c)
    c.state_timer = 0.0
    c.state_duration = 0.0
    c.gauge = 0.0
    c.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    CombatDoctrine.clear_combatant_doctrine_commitment(c)
    var ctx: Dictionary = CombatFormationRout.rout_context_snapshot(manager, c)
    if CombatDebug.flow_verbose_enabled():
        (
            CombatDebug
            . flow_log(
                (
                    "flee id=%d %s fid=%s cohesion=%.2f casualty=%.2f stressed=%s holding=%s"
                    % [
                        combatant_id,
                        CombatantEntityAccess.get_display_name(c, combatant_id),
                        fid,
                        ctx.get(DataKeys.FORMATION_LINE_COHESION, 0.0),
                        ctx.get(DataKeys.FLEE_CTX_CASUALTY_RATIO, 0.0) * 100.0,
                        str(ctx.get(DataKeys.FLEE_CTX_FORMATION_STRESSED, false)),
                        str(ctx.get(DataKeys.FLEE_CTX_SIDE_HOLDING_FIELD, false)),
                    ]
                )
            )
        )
    CombatF5SoakTrace.note_fled(
        combatant_id,
        CombatantEntityAccess.get_display_name(c, combatant_id),
        ctx.get(DataKeys.FORMATION_LINE_COHESION, 0.0),
        ctx.get(DataKeys.FLEE_CTX_CASUALTY_RATIO, 0.0) * 100.0,
        ctx.get(DataKeys.FLEE_CTX_SIDE_HOLDING_FIELD, false)
    )
    if not fid.is_empty():
        manager.notify_formation_changed(fid)
        manager.recompute_zoc_and_distance()
        CombatEventScheduler.reschedule_back_rank_turns(manager, fid)
    (
        manager
        . emit_signal(
            "action_resolved",
            combatant_id,
            combatant_id,
            {
                "outcome": "fled",
                "dmg": 0,
                "died": false,
                DataKeys.FORMATION_LINE_COHESION: ctx.get(DataKeys.FORMATION_LINE_COHESION, -1.0),
                DataKeys.FLEE_CTX_CASUALTY_RATIO: ctx.get(DataKeys.FLEE_CTX_CASUALTY_RATIO, -1.0),
                DataKeys.FLEE_CTX_FORMATION_STRESSED: ctx.get(DataKeys.FLEE_CTX_FORMATION_STRESSED, false),
                DataKeys.FLEE_CTX_SIDE_HOLDING_FIELD: ctx.get(DataKeys.FLEE_CTX_SIDE_HOLDING_FIELD, false),
            }
        )
    )
    manager.emit_signal("turn_resolved", combatant_id)
    var winner: String = manager._check_for_winner() if manager.has_method("_check_for_winner") else ""
    if not winner.is_empty() and manager.has_method("_end_combat_phase"):
        manager._end_combat_phase(winner, null)


static func _is_cowering_alone_on_side(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var side: String = CombatantEntityAccess.side_str(c)
    if not side.is_empty():
        for other in manager.combatants:
            if other is not Dictionary:
                continue
            if CombatantEntityAccess.id_int(other) == CombatantEntityAccess.id_int(c):
                continue
            if CombatantEntityAccess.is_living_same_side(c, other):
                return false
    return true
