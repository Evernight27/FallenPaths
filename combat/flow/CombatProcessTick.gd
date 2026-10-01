class_name CombatProcessTick
extends RefCounted

## One frame of combat simulation: event queue, entity time advance, death/winner checks, per-state updates.


static func tick(manager: Node, delta: float) -> void:
    manager.combat_clock += delta
    CombatEventDispatch.process_event_queue(manager)
    manager._combat_tick_index += 1
    # Harness diagnostic: log standing counts each tick so we can see why combat persists.
    if (
        not manager.medical_phase
        and manager.has_meta("_fp_harness_diag")
        and bool(manager.get_meta("_fp_harness_diag"))
    ):
        var standing_counts: Dictionary = CombatStandingHelper.get_standing_by_side(manager.combatants)
        var alive_count: int = 0
        var dead_count: int = 0
        for c in manager.combatants:
            if not c is Dictionary:
                continue
            if not CombatantEntityAccess.alive_bool(c):
                dead_count += 1
            else:
                alive_count += 1
        var standing_str: String = ""
        for k in standing_counts:
            standing_str += "%s=%d " % [k, standing_counts[k]]
        CombatDebug.harness_diag(
            (
                "tick=%d clock=%.2f medical_phase=%s standing=[%s] alive=%d dead=%d"
                % [
                    manager._combat_tick_index,
                    manager.combat_clock,
                    str(manager.medical_phase),
                    standing_str.strip_edges(),
                    alive_count,
                    dead_count
                ]
            )
        )
    # Check for winner after event queue drain  -  prevents remaining turns from firing
    # when one side has zero standing combatants (all dead/fled/incapacitated).
    if not manager.medical_phase:
        var early_victor: String = manager._check_for_winner()
        if not early_victor.is_empty() and MedicalPhaseController.should_apply_phase_end(manager, early_victor):
            # The [Fight end] line already carries winner + cause; this internal state-machine narration is
            # redundant for realism debugging. Gate behind the calibration trace.
            if CombatDebug.dc_trace_active():
                CombatDebug.harness_diag("winner_check_1 victor=%s" % early_victor)
            manager._end_combat_phase(early_victor, null)
            return
    var fast_forward: bool = MedicalPhaseController.medical_fast_forward_active(manager)
    if not fast_forward:
        if (
            CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY
            and CombatConstants.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES > 0
        ):
            var n: int = CombatConstants.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES
            if n > 0 and manager._combat_tick_index % n == 0:
                manager.mark_all_formations_vacancy_dirty()
        var changed_fids: Array = []
        if manager.has_method("_vacancy_reconcile_pass"):
            changed_fids = manager._vacancy_reconcile_pass(true)
        else:
            var snap: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(manager)
            changed_fids = CombatFormationFlow.reconcile_vacancy_plugs(manager)
            CombatFormationFlow.finish_vacancy_reconcile_follow_up(manager, changed_fids, snap, true)
    var victor: String = ""
    var last_death_node: Node = null
    for c in manager.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        var adv_node: Node = CombatantEntityAccess.scene_node(c)
        if adv_node == null:
            continue
        if (
            c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)
            or c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)
        ):
            _set_exertion_active(manager, c, false)
            continue
        # Sync exertion flag: active combat states (wind-up, recovering) increase blood loss
        # and reduce clotting effectiveness (lethal triad: movement, adrenaline, trauma).
        var st: String = CombatantEntityAccess.state_str(c)
        _set_exertion_active(manager, c, st == CombatConstants.STATE_WIND_UP or st == CombatConstants.STATE_RECOVERING)
        # Advance bleeding/blood_loss tick, no healing
        if adv_node.has_method("process_bleeding"):
            adv_node.process_bleeding(delta)
        if adv_node.has_method("process_blood_loss"):
            adv_node.process_blood_loss(delta)
        if not fast_forward and adv_node.has_method("_try_ambient_pain_shock_tick"):
            adv_node._try_ambient_pain_shock_tick(delta)
        if not fast_forward and adv_node.has_method("_tick_adrenaline_dump"):
            adv_node._tick_adrenaline_dump()
        manager._refresh_combatant_stats(c)
    for c in manager.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        var death_node: Node = CombatantEntityAccess.scene_node(c)
        if death_node == null:
            continue
        var tick_victor: String = CombatStateHandlers.process_death_tick(manager, c)
        if not tick_victor.is_empty():
            victor = tick_victor
            last_death_node = death_node
    # Winner is sticky during medical triage; only enter phase_end once from the tick loop.
    if (
        not victor.is_empty()
        and not manager.medical_phase
        and MedicalPhaseController.should_apply_phase_end(manager, victor)
    ):
        # Redundant with the [Fight end] line; gate behind the calibration trace.
        if CombatDebug.dc_trace_active():
            CombatDebug.harness_diag("winner_check_2 victor=%s" % victor)
        manager._end_combat_phase(victor, last_death_node)
        return
    victor = manager._check_for_winner()
    if (
        not victor.is_empty()
        and not manager.medical_phase
        and MedicalPhaseController.should_apply_phase_end(manager, victor)
    ):
        # Redundant with the [Fight end] line; gate behind the calibration trace.
        if CombatDebug.dc_trace_active():
            CombatDebug.harness_diag("winner_check_3 victor=%s" % victor)
        manager._end_combat_phase(victor, null)
        return
    for c in manager.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatStateHandlers.process_incapacitation(manager, c):
            continue
        if CombatStateHandlers.process_medical_wind_up_cancel(manager, c):
            continue
        match CombatantEntityAccess.state_str(c):
            CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
                CombatStateHandlers.process_receiving_medical(manager, c, delta)
            CombatConstants.STATE_WAITING:
                CombatStateHandlers.process_waiting(manager, c, delta)
            CombatConstants.STATE_WIND_UP:
                if not (
                    MedicalPhaseController.combat_resolution_blocked(manager)
                    and MedicalPhaseController.is_losing_side(manager, c)
                ):
                    CombatStateHandlers.process_wind_up(manager, c, delta)
            CombatConstants.STATE_MEDICAL_WIND_UP:
                CombatStateHandlers.process_medical_wind_up(manager, c, delta)
            CombatConstants.STATE_RECOVERING:
                if not (
                    MedicalPhaseController.combat_resolution_blocked(manager)
                    and MedicalPhaseController.is_losing_side(manager, c)
                ):
                    CombatStateHandlers.process_recovering(manager, c, delta)
            CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK:
                if not (
                    MedicalPhaseController.combat_resolution_blocked(manager)
                    and MedicalPhaseController.is_losing_side(manager, c)
                ):
                    CombatStateHandlers.process_formation_move_timer(c, delta)
            CombatConstants.STATE_FORM_SWITCH:
                CombatFormSwitch.process_tick(manager, c, delta)


## exertion_active lives on the health entity (CoreEntity.exertion_active), not the scene node.
## Resolve the entity through the manager so player Characters and enemy creatures both sync.
static func _set_exertion_active(manager: Node, combatant: Dictionary, value: bool) -> void:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, combatant)
    if entity != null and "exertion_active" in entity:
        entity.exertion_active = value
