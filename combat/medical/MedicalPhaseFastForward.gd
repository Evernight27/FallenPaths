class_name MedicalPhaseFastForward
extends MedicalPhaseBatchResolve

const Proficiency := preload("res://core/EntityProficiency.gd")
const AIPicker := preload("res://combat/ai/CombatAIActionPicker.gd")
const CombatConstantsScript := preload("res://combat/CombatConstants.gd")

## Medical phase queries: danger, urgency, untreated wounds, end-of-phase, ally medical actions, campaign
## **`batch_resolve_on_campaign_exit`**.
## Footing: halting wind-up on phase entry ->'f??' ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' '
## **`CombatFootwork.clear_on_exchange_end`** per combatant ->''''A!f''s'. **`return_to_waiting`** on idle reset
## ->''--''''A!''--'''s''?" LIVE_PATHS **`#wf-tier-44-pa`** (clear). Does **not** change **`weapon_form`** / home guard.
## Manager must have: combatants (Array), medical_phase (bool), medical_phase_winner (String), get_health_entity(node)
## -> Node (or use CombatantEntityAccess).


static func _batch_apply_direct_pressure(
    manager: Node, performer: Dictionary, target: Dictionary, performer_id: int, target_id: int, part: String
) -> bool:
    var applied: bool = false
    if target_id == performer_id:
        applied = CombatantEntityAccess.entity_apply_direct_pressure(manager, target, part)
    elif CombatMedicalCoordination.can_stack_assist_pressure(manager, performer_id, target_id, part):
        applied = CombatantEntityAccess.entity_stack_assist_pressure_during_ally_treatment(
            manager, target, performer, part
        )
    elif CombatantEntityAccess.entity_apply_direct_pressure_from_ally(manager, target, performer, part):
        applied = true
        CombatantEntityAccess.link_performer_direct_pressure_on_ally(
            manager, performer, CombatantEntityAccess.get_entity_from_manager(manager, target), part
        )
    if applied:
        CombatDebug.medical_session(
            (
                "Medical batch: %s apply_direct_pressure on %s => held"
                % [CombatantEntityAccess.get_display_name(performer), part]
            )
        )
        # XCamp-4: proficiency gains for batch direct pressure.
        if MedicalPhaseBatchResolve._get_company_state().read_stub_proficiency_enabled():
            var perf_entity = CombatantEntityAccess.get_entity_from_manager(manager, performer)
            var tgt_entity = CombatantEntityAccess.get_entity_from_manager(manager, target)
            if perf_entity != null and "_proficiency_bonus" in perf_entity and EntityProficiency.is_stat_gain_tracked(perf_entity):
                Proficiency.award_stat_gain(
                    perf_entity,
                    "intelligence",
                    Proficiency.GAIN_MEDICAL_ACTION_BASE * Proficiency.GAIN_DIRECT_PRESSURE_INT_MULT
                )
            if tgt_entity != null and "_proficiency_bonus" in tgt_entity and EntityProficiency.is_stat_gain_tracked(tgt_entity):
                # Enduring blood peril scales with how badly the patient is bleeding (deep hemorrhage
                # trains more endurance than a light scratch) — matches the wind-up and batch paths.
                Proficiency.award_stat_gain(
                    tgt_entity,
                    "endurance",
                    Proficiency.GAIN_BLOOD_PERIL_BASE
                    * Proficiency.GAIN_DIRECT_PRESSURE_PATIENT_END_MULT
                    * EntityProficiency.blood_peril_end_factor(float(tgt_entity.blood_volume))
                )
    return applied


static func _batch_medical_procedure_succeeded(result: Variant) -> bool:
    if result == true:
        return true
    if result is Dictionary:
        return result.get("success", false)
    return false


static func _batch_outcome_for_method(
    target_method: String, result: Variant, wind_up_cfg: Dictionary, med_id: String
) -> String:
    var ok: bool = MedicalPhaseFastForward._batch_medical_procedure_succeeded(result)
    var outcome := CombatConstants.medical_outcome_string(target_method, ok)
    if outcome != "":
        return outcome
    return str(wind_up_cfg.get(DataKeys.MEDICAL_OUTCOME), med_id)


## Returns the medical item type multiplier for batch resolve proficiency gains.


## Returns the medical item type multiplier for batch resolve proficiency gains.
static func _get_batch_item_mult(move_id: String) -> float:
    match move_id:
        CombatConstantsScript.MOVE_ID_BANDAGE_SELF, CombatConstantsScript.MOVE_ID_BANDAGE_ALLY, CombatConstantsScript.MOVE_TARGET_APPLY_BANDAGE:
            return Proficiency.get_medical_item_mult("bandage")
        CombatConstantsScript.MOVE_ID_PACK_WOUND, CombatConstantsScript.MOVE_ID_PACK_ALLY, CombatConstantsScript.MOVE_TARGET_APPLY_PACKING:
            return Proficiency.get_medical_item_mult("pack")
        CombatConstantsScript.MOVE_TARGET_APPLY_STABILIZE, CombatConstantsScript.MOVE_ID_STABILIZE_WOUND, CombatConstantsScript.MOVE_ID_STABILIZE_ALLY:
            return Proficiency.get_medical_item_mult("pack")
        CombatConstantsScript.MOVE_ID_APPLY_TOURNIQUET, CombatConstantsScript.MOVE_ID_APPLY_TOURNIQUET_ALLY:
            return Proficiency.get_medical_item_mult("tourniquet")
        _:
            return 1.0


static func _log_batch_resolve_result(manager: Node, parts_before: int) -> void:
    var parts_after: int = MedicalPhaseController.winner_side_untreated_part_count(manager)
    var can_end: bool = MedicalPhaseController.can_end_medical_phase(manager)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_combat(
            (
                "medical_batch_resolve parts_before=%d parts_after=%d can_end=%s"
                % [parts_before, parts_after, str(can_end).to_lower()]
            )
        )
    elif not can_end:
        CombatDebug.combat_session(
            "batch_resolve_medical_phase parts_before=%d parts_after=%d can_end=false" % [parts_before, parts_after]
        )


## When the player ends battle during medical phase, advance **`combat_clock`** through the tick pipeline until triage
## finishes.


static func _fast_forward_drive_sync(manager: Node, sim_state: Dictionary) -> String:
    var break_reason: String = "sim_cap"
    while true:
        var chunk: Dictionary = MedicalPhaseController.fast_forward_advance_chunk(
            manager, sim_state, float(sim_state[DataKeys.SIM_CAP]), INSTANT_FAST_FORWARD_MAX_ITERATIONS
        )
        if chunk.get(DataKeys.MEDICAL_CONTINUE_LOOP, false) != true:
            break_reason = str(chunk.get(DataKeys.MEDICAL_BREAK_REASON, "sim_cap"))
            break
    return break_reason


static func _instant_complete_sim_cap(max_sim_seconds: float) -> float:
    return (
        INSTANT_FAST_FORWARD_MAX_SECONDS
        if max_sim_seconds < 0.0
        else maxf(max_sim_seconds, INSTANT_FAST_FORWARD_MIN_STEP_S)
    )


static func _clear_instant_complete_fast_forward_meta(manager: Node) -> void:
    if manager.has_meta(MANAGER_META_MEDICAL_FAST_FORWARD):
        manager.remove_meta(MANAGER_META_MEDICAL_FAST_FORWARD)


## One fast-forward iteration. Mutates **`sim_state`** (`sim_seconds`, `stagnant_steps`).


## One fast-forward iteration. Mutates **`sim_state`** (`sim_seconds`, `stagnant_steps`).
static func _instant_complete_fast_forward_step(manager: Node, sim_state: Dictionary) -> Dictionary:
    MedicalPhaseFastForward._ensure_winner_recovery_end_events(manager)
    var dt: float = MedicalPhaseFastForward._next_fast_forward_delta(manager)
    var stagnant_steps: int = sim_state.get(DataKeys.SIM_STATE_STAGNANT_STEPS, 0)
    var sim_seconds: float = sim_state.get(DataKeys.SIM_STATE_SIM_SECONDS, 0.0)
    if dt <= 0.0:
        if MedicalPhaseFastForward._resolve_stalled_winner_turns(manager):
            # Advance clock on turn picks; otherwise sim_s never moves and the loop can spin forever.
            MedicalPhaseBatchResolve._get_process_tick().tick(manager, INSTANT_FAST_FORWARD_MIN_STEP_S)
            sim_seconds += INSTANT_FAST_FORWARD_MIN_STEP_S
            sim_state[DataKeys.SIM_STATE_SIM_SECONDS] = sim_seconds
            sim_state[DataKeys.SIM_STATE_STAGNANT_STEPS] = 0
            return {"continue_loop": true, "stepped": true}
        if MedicalPhaseController.winner_side_untreated_part_count(manager) > 0:
            MedicalPhaseBatchResolve._get_process_tick().tick(manager, INSTANT_FAST_FORWARD_IDLE_STEP_S)
            sim_seconds += INSTANT_FAST_FORWARD_IDLE_STEP_S
            sim_state[DataKeys.SIM_STATE_SIM_SECONDS] = sim_seconds
            sim_state[DataKeys.SIM_STATE_STAGNANT_STEPS] = 0
            return {"continue_loop": true, "stepped": true}
        stagnant_steps += 1
        sim_state[DataKeys.SIM_STATE_STAGNANT_STEPS] = stagnant_steps
        if stagnant_steps >= INSTANT_FAST_FORWARD_STAGNANT_LIMIT:
            if MedicalPhaseFastForward._unstick_medical_turns(manager):
                sim_state[DataKeys.SIM_STATE_STAGNANT_STEPS] = 0
                return {"continue_loop": true, "stepped": false}
            return {"continue_loop": false, "stepped": false}
        # Nudge clock while waiting for wind-ups / recovery to produce the next delta.
        MedicalPhaseBatchResolve._get_process_tick().tick(manager, INSTANT_FAST_FORWARD_MIN_STEP_S)
        sim_state[DataKeys.SIM_STATE_SIM_SECONDS] = sim_seconds + INSTANT_FAST_FORWARD_MIN_STEP_S
        return {"continue_loop": true, "stepped": true}
    sim_state[DataKeys.SIM_STATE_STAGNANT_STEPS] = 0
    MedicalPhaseBatchResolve._get_process_tick().tick(manager, dt)
    sim_state[DataKeys.SIM_STATE_SIM_SECONDS] = sim_seconds + dt
    return {"continue_loop": true, "stepped": true}


static func _log_instant_complete_result(
    manager: Node, sim_state: Dictionary, break_reason: String = "sim_cap"
) -> void:
    var sim_seconds: float = sim_state.get(DataKeys.SIM_STATE_SIM_SECONDS, 0.0)
    var total_iterations: int = sim_state.get(DataKeys.SIM_STATE_TOTAL_ITERATIONS, 0)
    var can_end: bool = MedicalPhaseController.can_end_medical_phase(manager)
    var reason: String = break_reason if not break_reason.is_empty() else "sim_cap"
    if OperationalLog.is_play_session_active():
        if can_end:
            (
                OperationalLog
                . play_combat(
                    (
                        ("medical_fast_forward complete sim_s=%.1f can_end=true parts_left=%d " + "iters=%d reason=%s")
                        % [
                            sim_seconds,
                            MedicalPhaseController.winner_side_untreated_part_count(manager),
                            total_iterations,
                            reason,
                        ]
                    )
                )
            )
        else:
            (
                OperationalLog
                . play_combat(
                    (
                        (
                            "medical_fast_forward incomplete sim_s=%.1f can_end=false parts_left=%d "
                            + "iters=%d reason=%s ->''--''''A!''--'''s''? field care may still be needed"
                        )
                        % [
                            sim_seconds,
                            MedicalPhaseController.winner_side_untreated_part_count(manager),
                            total_iterations,
                            reason,
                        ]
                    )
                )
            )
    elif not can_end:
        CombatDebug.combat_session(
            (
                "fast_forward_medical_phase sim_s=%.1f can_end=false iters=%d reason=%s"
                % [sim_seconds, total_iterations, reason]
            )
        )


static func _next_fast_forward_delta(manager: Node) -> float:
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    var best: float = INF
    for raw in manager.event_queue:
        if raw is not Dictionary:
            continue
        var ev: Dictionary = raw
        if MedicalPhaseController.should_block_scheduled_event(manager, ev):
            continue
        var resolve_at: float = float(ev.get(DataKeys.EVENT_RESOLVE_AT, INF))
        if resolve_at > clock:
            best = minf(best, resolve_at - clock)
    for c in manager.combatants:
        if not MedicalPhaseController.is_winner_side(manager, c):
            continue
        var st: String = CombatantEntityAccess.state_str(c)
        if st == CombatConstants.STATE_MEDICAL_WIND_UP:
            var wind_rem: float = c.get(DataKeys.PA_STATE_DURATION, 0.0) - c.get(DataKeys.PA_STATE_TIMER, 0.0)
            if wind_rem > 0.0:
                best = minf(best, wind_rem)
            else:
                best = minf(best, INSTANT_FAST_FORWARD_MIN_STEP_S)
        elif st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
            var cd: float = c.get(DataKeys.PA_RECEIVING_CARE_COOLDOWN, 0.0)
            if cd > 0.0:
                best = minf(best, cd)
            else:
                best = minf(best, INSTANT_FAST_FORWARD_MIN_STEP_S)
        elif st == CombatConstants.STATE_WAITING:
            if CombatantEntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
                best = minf(best, INSTANT_FAST_FORWARD_IDLE_STEP_S)
    if best == INF:
        if MedicalPhaseController.winner_side_untreated_part_count(manager) > 0:
            return INSTANT_FAST_FORWARD_IDLE_STEP_S
        return 0.0
    return maxf(best, INSTANT_FAST_FORWARD_MIN_STEP_S)


static func _has_pending_recovery_end(manager: Node, combatant_id: int) -> bool:
    for raw in manager.event_queue:
        if raw is not Dictionary:
            continue
        var ev: Dictionary = raw
        if ev.get(DataKeys.EVENT_TYPE, "") == CombatConstants.EVENT_RECOVERY_END and int(ev.get(DataKeys.EVENT_COMBATANT_ID, -1)) == combatant_id:
            return true
    return false


static func _ensure_winner_recovery_end_events(manager: Node) -> void:
    for c in manager.combatants:
        if not MedicalPhaseController.is_winner_side(manager, c):
            continue
        if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING:
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        if MedicalPhaseFastForward._has_pending_recovery_end(manager, cid):
            continue
        var remaining: float = maxf(0.0, c.get(DataKeys.PA_STATE_DURATION, 0.0) - c.get(DataKeys.PA_STATE_TIMER, 0.0))
        (
            CombatantEntityAccess
            . manager_schedule_event(
                manager,
                {
                    "type": CombatConstants.EVENT_RECOVERY_END,
                    "combatant_id": cid,
                    "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, remaining),
                    "data": {},
                }
            )
        )


## Unstick winner turns stuck at partial gauge or empty pick during fast-forward triage.


## Unstick winner turns stuck at partial gauge or empty pick during fast-forward triage.
static func _unstick_medical_turns(manager: Node) -> bool:
    var unstick: bool = false
    for c in manager.combatants:
        if not MedicalPhaseController.is_winner_side(manager, c) or not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
            continue
        if CombatantEntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
            c.gauge = 100.0
            unstick = true
    if MedicalPhaseFastForward._resolve_stalled_winner_turns(manager):
        return true
    return unstick


static func _resolve_stalled_winner_turns(manager: Node) -> bool:
    var acted: bool = false
    for c in manager.combatants:
        if not MedicalPhaseController.is_winner_side(manager, c) or not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
            continue
        if CombatantEntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        var actions: Array = manager.get_available_actions(cid)
        actions = CombatMedicalCoordination.filter_actions_for_pick(manager, cid, actions)
        if actions.is_empty():
            continue
        AIPicker.resolve_picked_turn_or_skip(manager, cid, actions, "player")
        acted = true
    return acted


## 0..1: higher when more hurt (lower blood, shorter time to death). Includes randomness.


static func _append_pressure_action_if_needed(
    manager: Node,
    performer: Dictionary,
    ally: Dictionary,
    part: String,
    has_pressure: bool,
    actively_bleeding: bool,
    out: Array
) -> void:
    if not actively_bleeding:
        return
    if (
        not CombatantEntityAccess.scene_can_apply_direct_pressure_api(performer)
        or CombatantEntityAccess.is_applying_direct_pressure_scene(performer)
    ):
        return
    if (
        CombatantEntityAccess.id_int(performer) == CombatantEntityAccess.id_int(ally)
        and not CombatantEntityAccess.entity_can_apply_direct_pressure(manager, ally, part)
    ):
        return
    var performer_id: int = CombatantEntityAccess.id_int(performer)
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    if has_pressure:
        if CombatMedicalCoordination.can_stack_assist_pressure(manager, performer_id, ally_id, part):
            out.append({"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE, "target_part": part})
        return
    if not CombatMedicalCoordination.medical_action_allowed(
        manager, performer_id, ally_id, part, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
    ):
        return
    out.append({"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE, "target_part": part})


## Returns list of { move_id, target_part } for medical actions the performer can apply to the ally's part.
## TCCC: dressings only when bleed is controlled or compression is on the part.


static func _battle_med_supplies_available(manager: Node) -> bool:
    var world: Node2D = MedicalPhaseBatchResolve._get_company_state().resolve_world_from_battle(manager)
    return world != null and MedicalPhaseBatchResolve._get_company_state().get_medical_supplies(world) >= 1

## TCCC escalation ladder for a wound part. Returns the ordered list of valid medical actions
## (bandage ->'f??' ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' ' pack ->'f??'
## ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' ' tourniquet), filtered to only actions that pass
## `medical_action_allowed()`.
## The bandage variant used depends on `performer_id == tgt_id` (self vs ally).
