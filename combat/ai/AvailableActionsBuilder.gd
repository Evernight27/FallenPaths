class_name AvailableActionsBuilder
extends RefCounted

## Orchestrates turn **`build()`**  -  delegates to listing modules (canonical lookups: **`AGENTS.md`**).
## Footing: lists moves only  -  does **not** set **`guard_line`**, **`weapon_form`**, or PA offset. Formation lane
## footing affects **duration** via **`CombatFormationMoveDuration`**, not blade posture. LIVE_PATHS
## **`#wf-pick-vs-strike`** . **`#wf-footing-terminology`**.
## **Read order:** preflight -> receiving-care pressure -> (combat) melee -> formation -> focus/wait -> MS-MID ally
## peril med -> (medical phase) winner actions -> counter-tempo filter -> dead-target drop.


static func _counter_tempo() -> GDScript:
    return preload(CombatConstants.PATH_COUNTER_TEMPO)


static func build(manager: Node, combatant_id: int) -> Array:
    var log_fid: String = ""
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return []
    CombatantEntityAccess.finalize_dead_combatant_if_node_dead(manager, c)
    if not CombatantEntityAccess.is_alive_in_combat(c):
        return []
    var counter_tempo: bool = false
    if CombatantEntityAccess.gauge_float(c) < 100.0:
        if _counter_tempo().call("can_act", manager, c):
            counter_tempo = true
        else:
            return []
    var state: String = CombatantEntityAccess.state_str(c)
    if (
        state != CombatConstants.STATE_WAITING
        and state != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
        and state != CombatConstants.STATE_COWERING
    ):
        return []
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
    state = CombatantEntityAccess.state_str(c)
    var formation_retreat_only: bool = CombatMobilityRetreat.formation_retreat_only_for(c)
    var actions: Array = []
    var combatants: Array = manager.combatants
    var medical_phase: bool = manager.medical_phase
    var medical_phase_winner: String = manager.medical_phase_winner
    if medical_phase and MedicalPhaseController.is_losing_side(manager, c):
        return []

    if CombatMedicalActionListing.append_receiving_care_direct_pressure(
        manager, c, combatant_id, actions, medical_phase_winner
    ):
        return actions

    if not medical_phase:
        var zone_ctx: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, c)
        CombatMeleeListing.append_melee_actions_for_combatant(
            manager, c, combatants, actions, formation_retreat_only, zone_ctx
        )
        var fm_ctx: Dictionary = CombatFormationMoveListing.append_formation_move_actions(
            manager, c, combatant_id, combatants, actions, formation_retreat_only, zone_ctx
        )
        log_fid = fm_ctx.get(DataKeys.ZONE_ID, "")
        if fm_ctx.get(DataKeys.COWERING_EARLY_EXIT, false):
            CombatFormationMoveListing.append_combat_wait_if_needed(manager, c, actions, combatant_id)
            return actions
        CombatAttention.append_focus_line_listing_actions(c, combatant_id, actions)
        CombatFormationMoveListing.append_combat_wait_if_needed(manager, c, actions, combatant_id)
        CombatMedicalActionListing.append_mid_fight_ally_medical_actions(manager, c, combatants, actions)
    else:
        CombatMedicalActionListing.append_medical_phase_winner_actions(
            manager, c, combatants, actions, medical_phase_winner
        )
    var result_actions: Array = actions
    if counter_tempo:
        result_actions = _counter_tempo().call("filter_actions_for_counter_tempo", actions, c)
    result_actions = _drop_actions_vs_dead_opponents(manager, c, result_actions)
    CombatDebug.log_available_actions_build(
        manager, combatant_id, c, result_actions, actions, counter_tempo, medical_phase, log_fid, combatants
    )
    return result_actions


## Drop hostile actions whose target died between listing and pick (death same tick / queue lag).
## Also drop ally-medical actions whose target has left the battlefield (fled / combat_absent).
static func _drop_actions_vs_dead_opponents(manager: Node, actor: Dictionary, actions: Array) -> Array:
    if actions.is_empty() or actor.is_empty():
        return actions
    var kept: Array = []
    for a in actions:
        var tid: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tid < 0:
            kept.append(a)
            continue
        var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid)
        if tgt.is_empty():
            kept.append(a)
            continue
        if CombatantEntityAccess.is_living_same_side(actor, tgt):
            if not CombatantEntityAccess.is_alive_in_combat(tgt):
                continue
            kept.append(a)
            continue
        if CombatantEntityAccess.is_alive_in_combat(tgt):
            kept.append(a)
    return kept
