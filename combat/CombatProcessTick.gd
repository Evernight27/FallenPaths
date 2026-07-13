class_name CombatProcessTick
extends RefCounted

## One frame of combat simulation: event queue, entity time advance, death/winner checks, per-state updates.

const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")


static func tick(manager: Node, delta: float) -> void:
    manager.combat_clock += delta
    _EventDispatch.process_event_queue(manager)
    manager._combat_tick_index += 1
    # Check for winner after event queue drain  -  prevents remaining turns from firing
    # when one side has zero standing combatants (all dead/fled/incapacitated).
    if not manager.medical_phase:
        var early_victor: String = manager._check_for_winner()
        if not early_victor.is_empty() and _MedicalPhase.should_apply_phase_end(manager, early_victor):
            manager._end_combat_phase(early_victor, null)
            return
    var fast_forward: bool = _MedicalPhase.medical_fast_forward_active(manager)
    if not fast_forward:
        if (
            _CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY
            and _CombatConstants.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES > 0
        ):
            var n: int = _CombatConstants.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES
            if n > 0 and manager._combat_tick_index % n == 0:
                manager.mark_all_formations_vacancy_dirty()
        var changed_fids: Array = []
        if manager.has_method("vacancy_reconcile_pass"):
            changed_fids = manager.vacancy_reconcile_pass(true)
        else:
            var snap: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(manager)
            changed_fids = _FormationFlow.reconcile_vacancy_plugs(manager)
            _FormationFlow.finish_vacancy_reconcile_follow_up(manager, changed_fids, snap, true)
    var victor: String = ""
    var last_death_node: Node = null
    for c in manager.combatants:
        if not _EntityAccess.alive_bool(c):
            continue
        if c.get("combat_absent", false):
            continue
        if c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false):
            continue
        var adv_node: Node = _EntityAccess.scene_node(c)
        if adv_node == null:
            continue
        # Advance bleeding/blood_loss tick, no healing
        if adv_node.has_method("process_bleeding"):
            adv_node.process_bleeding(delta)
        if adv_node.has_method("process_blood_loss"):
            adv_node.process_blood_loss(delta)
        if not fast_forward and adv_node.has_method("_try_ambient_pain_shock_tick"):
            adv_node._try_ambient_pain_shock_tick(delta)
        manager.refresh_combatant_stats(c)
    for c in manager.combatants:
        if not _EntityAccess.alive_bool(c):
            continue
        var death_node: Node = _EntityAccess.scene_node(c)
        if death_node == null:
            continue
        var tick_victor: String = _StateHandlers.process_death_tick(manager, c)
        if not tick_victor.is_empty():
            victor = tick_victor
            last_death_node = death_node
    # Winner is sticky during medical triage; only enter phase_end once from the tick loop.
    if not victor.is_empty() and not manager.medical_phase and _MedicalPhase.should_apply_phase_end(manager, victor):
        manager._end_combat_phase(victor, last_death_node)
        return
    victor = manager._check_for_winner()
    if not victor.is_empty() and not manager.medical_phase and _MedicalPhase.should_apply_phase_end(manager, victor):
        manager._end_combat_phase(victor, null)
        return
    for c in manager.combatants:
        if not _EntityAccess.alive_bool(c):
            continue
        if _StateHandlers.process_incapacitation(manager, c):
            continue
        if _StateHandlers.process_medical_wind_up_cancel(manager, c):
            continue
        match _EntityAccess.state_str(c):
            CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
                _StateHandlers.process_receiving_medical(manager, c, delta)
            CombatConstants.STATE_WAITING:
                _StateHandlers.process_waiting(manager, c, delta)
            CombatConstants.STATE_WIND_UP:
                if not (_MedicalPhase.combat_resolution_blocked(manager) and _MedicalPhase.is_losing_side(manager, c)):
                    _StateHandlers.process_wind_up(manager, c, delta)
            CombatConstants.STATE_MEDICAL_WIND_UP:
                _StateHandlers.process_medical_wind_up(manager, c, delta)
            CombatConstants.STATE_RECOVERING:
                if not (_MedicalPhase.combat_resolution_blocked(manager) and _MedicalPhase.is_losing_side(manager, c)):
                    _StateHandlers.process_recovering(manager, c, delta)
            CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK:
                if not (_MedicalPhase.combat_resolution_blocked(manager) and _MedicalPhase.is_losing_side(manager, c)):
                    _StateHandlers.process_formation_move_timer(c, delta)
