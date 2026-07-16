class_name CombatEventDispatch
extends RefCounted

## Drains the combat event queue and dispatches to CombatManager handlers.
## **Read order:** queue drain loop -> event type dispatch -> state/medical/counter side effects.


static func process_event_queue(manager: Node) -> void:
    while manager.event_queue.size() > 0:
        var head_raw: Variant = manager.event_queue[0]
        if head_raw is not Dictionary:
            CombatDebug.operational_warn(
                "event_queue dropped non-dictionary head type=%s" % type_string(typeof(head_raw))
            )
            manager.event_queue.pop_front()
            continue
        var head: Dictionary = head_raw
        if head.get(DataKeys.EVENT_RESOLVE_AT, 0.0) > CombatantEntityAccess.combat_clock_float(manager):
            break
        var ev: Dictionary = manager.event_queue.pop_front() as Dictionary
        handle_event(manager, ev)


static func handle_event(manager: Node, ev: Dictionary) -> void:
    var ev_type: String = ev.get(DataKeys.EVENT_TYPE, "")
    var cid: int = ev.get(DataKeys.EVENT_COMBATANT_ID, -1)
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, cid)
    if (
        ev_type != CombatConstants.EVENT_SWAP_RANK_RESOLVE
        and ev_type != CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE
        and ev_type != CombatConstants.EVENT_ROTATE_FILE_RESOLVE
        and ev_type != CombatConstants.EVENT_PLUG_FORWARD_RESOLVE
        and not c.is_empty()
        and not CombatantEntityAccess.is_alive_in_combat(c)
    ):
        return
    if (
        MedicalPhaseController.combat_resolution_blocked(manager)
        and MedicalPhaseController.should_block_scheduled_event(manager, ev)
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
        CombatConstants.EVENT_PLUG_FORWARD_RESOLVE:
            manager._handle_plug_forward_resolve(ev)
        CombatConstants.EVENT_FORM_SWITCH_COMPLETE:
            CombatFormSwitch.handle_complete_event(manager, c)
        _:
            CombatDebug.flow_log_event("unknown event type %s" % ev_type, "event_dispatch_unknown")


static func handle_action_ready(manager: Node, c: Dictionary) -> void:
    if c.is_empty() or not CombatantEntityAccess.is_alive_in_combat(c) or CombatantEntityAccess.is_unconscious(c):
        return
    var cid_ready: int = CombatantEntityAccess.id_int(c)
    if (
        CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WAITING
        and CombatantEntityAccess.gauge_float(c) >= CombatConstants.GAUGE_FULL_THRESHOLD
    ):
        CombatDebug.flow_log(
            "stale ACTION_READY id=%d (gauge full)  -  skip_turn recover" % cid_ready,
            "stale_action_ready:%d" % cid_ready
        )
        CombatantEntityAccess.manager_skip_turn(
            manager, cid_ready, CombatConstants.SKIP_TURN_LOG_PASS, "stale action_ready"
        )
        return
    if MedicalPhaseController.combat_resolution_blocked(manager) and MedicalPhaseController.is_losing_side(manager, c):
        return
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
    var state: String = CombatantEntityAccess.state_str(c)
    var retreat_only: bool = CombatMobilityRetreat.formation_retreat_only_for(c)
    var mobile_retreat_ready: bool = retreat_only and CombatantEntityAccess.can_flee_or_fall_back(c)
    if CombatantEntityAccess.is_incapacitated(c) and not mobile_retreat_ready:
        return
    if state != CombatConstants.STATE_WAITING and state != CombatConstants.STATE_COWERING:
        if CombatDebug.flow_verbose_enabled():
            var who: String = CombatantEntityAccess.get_display_name(c)
            var cid: int = CombatantEntityAccess.id_int(c)
            CombatDebug.flow_log(
                "EVENT_ACTION_READY skipped %s (id=%d state=%s)" % [who, cid, state], "action_ready_skip:%d" % cid
            )
        return
    c.gauge = 100.0
    c.erase(DataKeys.ACTION_COOLDOWN_UNTIL)
    c.erase(CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON)
    if CombatantEntityAccess.is_player_side(c):
        if MedicalPhaseController.medical_fast_forward_active(manager):
            MedicalPhaseController.resolve_player_medical_turn_during_fast_forward(manager, cid_ready)
        else:
            manager.notify_turn_ready(CombatantEntityAccess.id_int(c))
    else:
        var actions: Array = manager.get_available_actions(CombatantEntityAccess.id_int(c))
        CombatAIActionPicker.resolve_picked_turn_or_skip(
            manager, CombatantEntityAccess.id_int(c), actions, CombatConstants.SIDE_ENEMY
        )


static func handle_melee_attack(manager: Node, c: Dictionary) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        if not c.is_empty() and CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
            var cid_abort: int = CombatantEntityAccess.id_int(c)
            CounterTempo.abort_attacker_wind_up(manager, cid_abort)
            CombatFootwork.return_to_waiting(c)
            c.gauge = 0.0
        return
    if (
        c.is_empty()
        or not CombatantEntityAccess.alive_bool(c)
        or CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WIND_UP
    ):
        return
    if CombatMobilityRetreat.cannot_commit_melee(c):
        CounterTempo.abort_attacker_wind_up(manager, CombatantEntityAccess.id_int(c))
        return
    manager._execute_attack(CombatantEntityAccess.id_int(c))
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, CombatantEntityAccess.id_int(c))
    if (
        not atk.is_empty()
        and CombatantEntityAccess.state_str(atk) == CombatConstants.STATE_RECOVERING
        and atk.state_duration > 0.0
    ):
        (
            CombatantEntityAccess
            . manager_schedule_event(
                manager,
                {
                    "type": CombatConstants.EVENT_RECOVERY_END,
                    "combatant_id": CombatantEntityAccess.id_int(c),
                    "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, atk.state_duration),
                    "data": {},
                }
            )
        )


static func handle_recovery_end(manager: Node, c: Dictionary) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager) and MedicalPhaseController.is_losing_side(manager, c):
        return
    if (
        c.is_empty()
        or not CombatantEntityAccess.alive_bool(c)
        or CombatantEntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING
    ):
        return
    var cid: int = CombatantEntityAccess.id_int(c)
    CombatEventScheduler.cancel_pending_action_ready(manager, cid)
    CombatStateHandlers.complete_recovery(manager, c)
    if CombatantEntityAccess.state_str(c) in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
        if (
            CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WAITING
            or CombatantEntityAccess.can_flee_or_fall_back(c)
        ):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, c)
