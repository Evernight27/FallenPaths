class_name MedicalPhaseController
extends RefCounted

const Footwork := preload("res://combat/weapon_form/CombatFootwork.gd")
const FlurryBind := preload("res://combat/strike/CombatFlurryBind.gd")
const AIPicker := preload("res://combat/ai/CombatAIActionPicker.gd")

const _WINNER_TRIAGE_BUSY_STATES: Array[String] = [
    CombatConstants.STATE_WIND_UP,
    CombatConstants.STATE_MEDICAL_WIND_UP,
    CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
    CombatConstants.STATE_RECOVERING,
    CombatConstants.STATE_SWAP_RANK,
    CombatConstants.STATE_FALLING_BACK,
    CombatConstants.STATE_COWERING,
]

## Medical phase queries: danger, urgency, untreated wounds, end-of-phase, ally medical actions, campaign
## **`batch_resolve_on_campaign_exit`**.
## Footing: halting wind-up on phase entry ->'f??' ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' '
## **`CombatFootwork.clear_on_exchange_end`** per combatant ->''''A!f''s'. **`return_to_waiting`** on idle reset
## ->''--''''A!''--'''s''?" LIVE_PATHS **`#wf-tier-44-pa`** (clear). Does **not** change **`weapon_form`** / home guard.
## Manager must have: combatants (Array), medical_phase (bool), medical_phase_winner (String), get_health_entity(node)
## -> Node (or use CombatantEntityAccess).


## True once player-side victory: no new combat resolutions (medical triage only).
static func combat_resolution_blocked(manager: Node) -> bool:
    return manager != null and manager.medical_phase


## Post-victory medical phase: bleed-out / standing-count cannot reverse `medical_phase_winner`.


## Post-victory medical phase: bleed-out / standing-count cannot reverse `medical_phase_winner`.
static func should_apply_phase_end(manager: Node, victor: String) -> bool:
    if manager == null or victor.is_empty():
        return false
    var crc = manager.get("combat_resolution_closed")
    if (crc as bool) == true and manager.medical_phase != true:
        return false
    if manager.medical_phase != true:
        return true
    return victor == str(manager.medical_phase_winner)


static func is_winner_side(manager: Node, c: Dictionary) -> bool:
    if manager == null or c == null or c.is_empty() or not manager.medical_phase:
        return false
    return CombatantEntityAccess.is_on_side(c, str(manager.medical_phase_winner))


static func is_losing_side(manager: Node, c: Dictionary) -> bool:
    if manager == null or c == null or c.is_empty():
        return false
    if not manager.medical_phase:
        return false
    return not is_winner_side(manager, c)


static func is_losing_side_id(manager: Node, combatant_id: int) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    return is_losing_side(manager, c)


## True when an event should not be queued for the losing side (or a pair touching them) during medical phase.


## True when an event should not be queued for the losing side (or a pair touching them) during medical phase.
static func should_block_scheduled_event(manager: Node, ev: Dictionary) -> bool:
    if manager == null or not manager.medical_phase:
        return false
    var ev_type: String = ev.get(DataKeys.EVENT_TYPE, "")
    if ev_type not in MedicalPhaseBatchResolve.POST_VICTORY_BLOCKED_EVENT_TYPES:
        return false
    var cid: int = int(ev.get(DataKeys.EVENT_COMBATANT_ID, -1))
    if is_losing_side_id(manager, cid):
        return true
    if ev_type == CombatConstants.EVENT_SWAP_RANK_RESOLVE or ev_type == CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
        var dr: Variant = ev.get(DataKeys.EVENT_DATA, null)
        if dr is Dictionary:
            var pid: int = int(dr.get(DataKeys.EVENT_PARTNER_ID, -1))
            if is_losing_side_id(manager, pid):
                return true
    return false


## Formation resolve handlers: skip grid mutations for the losing side during medical phase.


## Formation resolve handlers: skip grid mutations for the losing side during medical phase.
static func should_skip_formation_resolve(manager: Node, initiator_id: int, partner_id: int = -1) -> bool:
    if not manager.medical_phase:
        return false
    if is_losing_side_id(manager, initiator_id):
        return true
    if partner_id >= 0 and is_losing_side_id(manager, partner_id):
        return true
    return false


## Remove any queued post-victory combat events for the losing side (and pairs touching them).


## Remove any queued post-victory combat events for the losing side (and pairs touching them).
static func purge_blocked_events_from_queue(manager: Node) -> void:
    if manager == null or not manager.medical_phase:
        return
    manager.event_queue = manager.event_queue.filter(
        func(ev: Variant) -> bool:
            if ev is not Dictionary:
                return false
            return not should_block_scheduled_event(manager, ev)
    )


## Player-win medical phase: cancel losing-side combat, abort wind-ups, idle combat states.
static func halt_losing_side_combat(manager: Node) -> void:
    if manager == null or not manager.medical_phase:
        return
    var winner: String = manager.medical_phase_winner
    for c in manager.combatants:
        if CombatantEntityAccess.is_on_side(c, winner):
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        CombatEventScheduler.cancel_pending_combat_events_for_combatant(manager, cid)
        var st: String = CombatantEntityAccess.state_str(c)
        if st == CombatConstants.STATE_WIND_UP:
            MedicalPhaseBatchResolve._get_counter_tempo().abort_attacker_wind_up(manager, cid)
            CombatEventScheduler.cancel_pending_recovery_end(manager, cid)
            Footwork.return_to_waiting(c)
            c.gauge = 0.0
            continue
        var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
        if not pa.is_empty():
            MedicalPhaseBatchResolve._get_wind_up_starter().clear_incoming_attack_telegraph_from_pa(manager, pa)
            Footwork.clear_on_exchange_end(c)
            c.pending_attack = {}
        if (
            st
            in [
                CombatConstants.STATE_RECOVERING,
                CombatConstants.STATE_SWAP_RANK,
                CombatConstants.STATE_FALLING_BACK,
                CombatConstants.STATE_MEDICAL_WIND_UP,
            ]
        ):
            Footwork.return_to_waiting(c)
            c.gauge = 0.0
        c[DataKeys.PA_PENDING_MEDICAL] = {}
        c.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
        c.erase(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART)
        c.erase(DataKeys.PA_PARRY_WAS_BIND)
        c.erase(DataKeys.PA_PARRY_AGAINST_ID)
        c.erase(DataKeys.PA_PARRY_BONUS_UNTIL)
        MedicalPhaseBatchResolve._get_counter_tempo().clear_window(c)
        MedicalPhaseBatchResolve._get_counter_tempo().clear_riposte_chain(c)
        FlurryBind.clear(c)
        if c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false) or CombatantEntityAccess.state_str(c) == CombatConstants.STATE_FLED:
            c[DataKeys.SNAPSHOT_COMBAT_ABSENT] = true
            c.state = CombatConstants.STATE_FLED
            Footwork.reconcile_idle_offset(c)
    for c in manager.combatants:
        if not CombatantEntityAccess.is_on_side(c, winner):
            continue
        MedicalPhaseBatchResolve._get_counter_tempo().clear_window(c)
        MedicalPhaseBatchResolve._get_counter_tempo().clear_riposte_chain(c)
        var had_fled: bool = (
            c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false) or CombatantEntityAccess.state_str(c) == CombatConstants.STATE_FLED
        )
        MedicalPhaseBatchResolve._reset_fled_and_combat_absent(c)
        # Fled winners: triage needs them on-field (`is_alive_in_combat`); suspend bleed ticks only
        # (they left before victory ->''--''''A!''--'''s''?" wounds should not drain during post-victory medical phase).
        if had_fled:
            c[CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK] = true
    purge_blocked_events_from_queue(manager)


## Same threshold as bleed-out death (`CoreEntity._get_blood_loss_death_threshold` / `EntityWounds`).


## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated.
static func can_end_medical_phase(manager: Node) -> bool:
    if not manager.medical_phase:
        return false
    for c in manager.combatants:
        if (
            not CombatantEntityAccess.is_living_on_side(c, str(manager.medical_phase_winner))
            or CombatantEntityAccess.scene_node(c) == null
        ):
            continue
        if is_in_medical_danger(manager, c):
            return false
        if has_untreated_wounds(manager, c):
            return false
    return true


## True while any living winner-side fighter is mid-triage (procedure, gauge fill, or turn-ready with work left).


## True while any living winner-side fighter is mid-triage (procedure, gauge fill, or turn-ready with work left).
static func winner_side_triage_busy(manager: Node, combatants_scan: Array = []) -> bool:
    if manager == null or not manager.medical_phase:
        return false
    var winner_side: String = str(manager.medical_phase_winner)
    var scan: Array = combatants_scan if not combatants_scan.is_empty() else manager.combatants
    var can_end: bool = can_end_medical_phase(manager)
    for raw in scan:
        if raw is not Dictionary:
            continue
        var c: Dictionary = raw
        if not CombatantEntityAccess.alive_bool(c, true):
            continue
        if CombatantEntityAccess.side_str(c) != winner_side:
            continue
        var st: String = CombatantEntityAccess.state_str(c)
        if st in _WINNER_TRIAGE_BUSY_STATES:
            return true
        if st == CombatConstants.STATE_WAITING:
            if CombatantEntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
                return true
            if not can_end:
                return true
    return false


## True if combatant has any wounded part not comprehensively treated (bandaged, packed, or tourniqueted).


## True if combatant has any wounded part not comprehensively treated (bandaged, packed, or tourniqueted).
static func winner_side_untreated_part_count(manager: Node) -> int:
    if manager == null:
        return 0
    var total: int = 0
    for c in manager.combatants:
        if not is_winner_side(manager, c):
            continue
        var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
        if entity == null:
            continue
        total += EntityWounds.sorted_untreated_part_names(entity).size()
    return total


static func has_untreated_wounds(manager: Node, c: Dictionary) -> bool:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return false
    return CombatantEntityAccess.entity_has_untreated_wounds(entity)


## True when blood volume or estimated time to blood-loss death is in danger zone (consider medical).


## True when blood volume or estimated time to blood-loss death is in danger zone (consider medical).
static func is_in_medical_danger(manager: Node, c: Dictionary) -> bool:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return false
    var bv: float = CombatantEntityAccess.get_blood_volume_from_node(entity)
    if bv <= MedicalPhaseBatchResolve.MEDICAL_DANGER_BLOOD_THRESHOLD:
        return true
    var rate: float = CombatantEntityAccess.get_total_bleeding_rate_from_node(entity)
    if rate <= 0.0:
        return false
    var perm_rate: float = CombatantEntityAccess.get_permanent_bleeding_rate_from_node(entity, rate)
    var death_thresh: float = MedicalPhaseBatchResolve._blood_loss_death_threshold_for_entity(entity)
    var buffer: float = bv - death_thresh
    if (
        buffer > 0.0
        and perm_rate > 0.0
        and perm_rate <= MedicalPhaseBatchResolve._max_safe_permanent_bleed_rate(buffer)
    ):
        return false
    var time_to_death: float = BleedingConstants.seconds_to_exsanguination_at_death_threshold(
        rate, bv, death_thresh, 1.0
    )
    return time_to_death <= MedicalPhaseBatchResolve.MEDICAL_DANGER_SECONDS


## Stricter than is_in_medical_danger: about to bleed out; must self-treat first.


## Stricter than is_in_medical_danger: about to bleed out; must self-treat first.
static func is_in_immediate_peril(manager: Node, c: Dictionary) -> bool:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return false
    var bv: float = CombatantEntityAccess.get_blood_volume_from_node(entity)
    if bv <= MedicalPhaseBatchResolve.IMMEDIATE_PERIL_BLOOD_THRESHOLD:
        return true
    var rate: float = CombatantEntityAccess.get_total_bleeding_rate_from_node(entity)
    if rate <= 0.0:
        return false
    var death_thresh_im: float = MedicalPhaseBatchResolve._blood_loss_death_threshold_for_entity(entity)
    var time_to_death: float = BleedingConstants.seconds_to_exsanguination_at_death_threshold(
        rate, bv, death_thresh_im, 1.0
    )
    return time_to_death <= MedicalPhaseBatchResolve.IMMEDIATE_PERIL_SECONDS


## True when entity has permanently left immediate peril (permanent bleeding rate low enough to recover).


## True when entity has permanently left immediate peril (permanent bleeding rate low enough to recover).
static func has_left_immediate_peril_permanently(manager: Node, c: Dictionary) -> bool:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return false
    var perm_rate: float = CombatantEntityAccess.get_permanent_bleeding_rate_from_node(entity, 0.0)
    if perm_rate <= BleedingConstants.BLEEDING_RATE_EPSILON:
        return true
    var bv: float = CombatantEntityAccess.get_blood_volume_from_node(entity)
    var death_thresh_pp: float = MedicalPhaseBatchResolve._blood_loss_death_threshold_for_entity(entity)
    var buffer: float = bv - death_thresh_pp
    if buffer > 0.0 and perm_rate <= MedicalPhaseBatchResolve._max_safe_permanent_bleed_rate(buffer):
        return true
    var time_to_death: float = BleedingConstants.seconds_to_exsanguination_at_death_threshold(
        perm_rate, bv, death_thresh_pp, 1.0
    )
    if time_to_death >= INF:
        return true
    return time_to_death > MedicalPhaseBatchResolve.IMMEDIATE_PERIL_SECONDS * 2.0


## True while **`instant_complete_on_early_exit`** simulates elapsed triage time (player side uses AI picks).


## True while **`instant_complete_on_early_exit`** simulates elapsed triage time (player side uses AI picks).
static func medical_fast_forward_active(manager: Node) -> bool:
    return (
        manager != null
        and manager.has_meta(MedicalPhaseBatchResolve.MANAGER_META_MEDICAL_FAST_FORWARD)
        and bool(manager.get_meta(MedicalPhaseBatchResolve.MANAGER_META_MEDICAL_FAST_FORWARD))
    )


## During fast-forward, player-side medical turns resolve via the same AI picker as enemies.


## During fast-forward, player-side medical turns resolve via the same AI picker as enemies.
static func resolve_player_medical_turn_during_fast_forward(manager: Node, combatant_id: int) -> void:
    if manager == null or combatant_id < 0:
        return
    var actions: Array = manager.get_available_actions(combatant_id)
    AIPicker.resolve_picked_turn_or_skip(manager, combatant_id, actions, "player")


## Campaign contract only: finish in-progress wind-ups + best-effort dress without tick-replay.


## Campaign contract only: finish in-progress wind-ups + best-effort dress without tick-replay.
static func batch_resolve_on_campaign_exit(manager: Node) -> void:
    if manager == null or not manager.medical_phase or can_end_medical_phase(manager):
        return
    var parts_before: int = winner_side_untreated_part_count(manager)
    MedicalPhaseBatchResolve._batch_complete_in_progress_windups(manager)
    MedicalPhaseBatchResolve._batch_scrub_winner_busy_states_for_exit(manager)
    MedicalPhaseBatchResolve._batch_best_effort_dress_winner_side(manager)
    MedicalPhaseFastForward._log_batch_resolve_result(manager, parts_before)


## When the player ends battle during medical phase, advance **`combat_clock`** through the tick pipeline until triage
## finishes.
static func instant_complete_on_early_exit(manager: Node, max_sim_seconds: float = -1.0) -> void:
    var sim_state: Dictionary = fast_forward_prepare(manager, max_sim_seconds)
    if sim_state.is_empty():
        return
    var break_reason: String = MedicalPhaseFastForward._fast_forward_drive_sync(manager, sim_state)
    fast_forward_finalize(manager, sim_state, break_reason)


static func fast_forward_prepare(manager: Node, max_sim_seconds: float) -> Dictionary:
    if manager == null or not manager.medical_phase or can_end_medical_phase(manager):
        return {}
    manager.set_meta(MedicalPhaseBatchResolve.MANAGER_META_MEDICAL_FAST_FORWARD, true)
    return {
        "sim_seconds": 0.0,
        "stagnant_steps": 0,
        "total_iterations": 0,
        "sim_cap": MedicalPhaseFastForward._instant_complete_sim_cap(max_sim_seconds),
    }


static func fast_forward_advance_chunk(
    manager: Node, sim_state: Dictionary, sim_cap: float, max_chunk_iters: int
) -> Dictionary:
    if manager == null or not manager.medical_phase:
        return {
            "continue_loop": false,
            "break_reason": "medical_phase_cleared",
        }
    var iters_run: int = 0
    while (
        manager.medical_phase
        and not can_end_medical_phase(manager)
        and float(sim_state[DataKeys.SIM_STATE_SIM_SECONDS]) < sim_cap
        and iters_run < max_chunk_iters
    ):
        iters_run += 1
        var total_iterations: int = sim_state.get(DataKeys.SIM_STATE_TOTAL_ITERATIONS, 0) + 1
        sim_state[DataKeys.SIM_STATE_TOTAL_ITERATIONS] = total_iterations
        if total_iterations > MedicalPhaseBatchResolve.INSTANT_FAST_FORWARD_MAX_ITERATIONS:
            return {
                "continue_loop": false,
                "break_reason": "iteration_cap",
            }
        var step: Dictionary = MedicalPhaseFastForward._instant_complete_fast_forward_step(manager, sim_state)
        if step.get(DataKeys.MEDICAL_CONTINUE_LOOP, true) != true:
            return {
                "continue_loop": false,
                "break_reason": "stagnant",
            }
    if can_end_medical_phase(manager):
        return {
            "continue_loop": false,
            "break_reason": "complete",
        }
    if float(sim_state[DataKeys.SIM_STATE_SIM_SECONDS]) >= sim_cap:
        return {
            "continue_loop": false,
            "break_reason": "sim_cap",
        }
    return {
        "continue_loop": true,
        "break_reason": "",
    }


## Run fast-forward steps until **`budget_usec`** elapses or the pass ends (interactive time-slice).


## Run fast-forward steps until **`budget_usec`** elapses or the pass ends (interactive time-slice).
static func fast_forward_advance_time_slice(
    manager: Node, sim_state: Dictionary, sim_cap: float, budget_usec: int
) -> Dictionary:
    if manager == null or not manager.medical_phase:
        return {
            "continue_loop": false,
            "break_reason": "medical_phase_cleared",
        }
    var slice_start_usec: int = Time.get_ticks_usec()
    while manager.medical_phase and not can_end_medical_phase(manager) and float(sim_state[DataKeys.SIM_STATE_SIM_SECONDS]) < sim_cap:
        if Time.get_ticks_usec() - slice_start_usec >= budget_usec:
            return {
                "continue_loop": true,
                "break_reason": "",
            }
        var total_iterations: int = sim_state.get(DataKeys.SIM_STATE_TOTAL_ITERATIONS, 0) + 1
        sim_state[DataKeys.SIM_STATE_TOTAL_ITERATIONS] = total_iterations
        if total_iterations > MedicalPhaseBatchResolve.INSTANT_FAST_FORWARD_MAX_ITERATIONS:
            return {
                "continue_loop": false,
                "break_reason": "iteration_cap",
            }
        var step: Dictionary = MedicalPhaseFastForward._instant_complete_fast_forward_step(manager, sim_state)
        if step.get(DataKeys.MEDICAL_CONTINUE_LOOP, true) != true:
            return {
                "continue_loop": false,
                "break_reason": "stagnant",
            }
    if can_end_medical_phase(manager):
        return {
            "continue_loop": false,
            "break_reason": "complete",
        }
    if float(sim_state[DataKeys.SIM_STATE_SIM_SECONDS]) >= sim_cap:
        return {
            "continue_loop": false,
            "break_reason": "sim_cap",
        }
    return {
        "continue_loop": true,
        "break_reason": "",
    }


static func fast_forward_finalize(manager: Node, sim_state: Dictionary, break_reason: String) -> void:
    if manager == null or not is_instance_valid(manager):
        return
    MedicalPhaseFastForward._clear_instant_complete_fast_forward_meta(manager)
    MedicalPhaseFastForward._log_instant_complete_result(manager, sim_state, break_reason)


## 0..1: higher when more hurt (lower blood, shorter time to death). Includes randomness.
static func get_medical_urgency(manager: Node, c: Dictionary) -> float:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return 0.0
    var comps: Vector2 = MedicalPhaseBatchResolve._medical_urgency_components(
        CombatantEntityAccess.get_blood_volume_from_node(entity),
        MedicalPhaseBatchResolve._blood_loss_death_threshold_for_entity(entity),
        CombatantEntityAccess.get_total_bleeding_rate_from_node(entity)
    )
    var raw: float = maxf(comps.x, comps.y)
    raw *= randf_range(
        MedicalPhaseBatchResolve.MEDICAL_URGENCY_RANDOM_MIN, MedicalPhaseBatchResolve.MEDICAL_URGENCY_RANDOM_MAX
    )
    return clampf(raw, 0.0, 1.0)


## Same blood/time urgency as `get_medical_urgency` but **no randomness** ->''--''''A!''--'''s''? used for medical
## action weights so triage is stable.


## Same blood/time urgency as `get_medical_urgency` but **no randomness** ->''--''''A!''--'''s''? used for medical
## action weights so triage is stable.
static func get_medical_urgency_deterministic(manager: Node, c: Dictionary) -> float:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return 0.0
    var comps: Vector2 = MedicalPhaseBatchResolve._medical_urgency_components(
        CombatantEntityAccess.get_blood_volume_from_node(entity),
        MedicalPhaseBatchResolve._blood_loss_death_threshold_for_entity(entity),
        CombatantEntityAccess.get_total_bleeding_rate_from_node(entity)
    )
    return clampf(maxf(comps.x, comps.y), 0.0, 1.0)


## Higher = intervene on this part before milder wounds (bleed rate + severity + arterial/stump + tourniquet
## indication).


## Higher = intervene on this part before milder wounds (bleed rate + severity + arterial/stump + tourniquet
## indication).
static func get_part_intervention_threat(manager: Node, c: Dictionary, part: String) -> float:
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if entity == null:
        return 0.0
    return EntityWounds.get_part_intervention_threat(entity, part)


## Returns list of { move_id, target_part } for medical actions the performer can apply to the ally's part.
## TCCC: dressings only when bleed is controlled or compression is on the part.
static func dressings_allowed_for_part(manager: Node, ally: Dictionary, part: String) -> bool:
    if part.is_empty():
        return false
    var bleed_rate: float = CombatantEntityAccess.entity_bleeding_rate_for_part(manager, ally, part)
    var actively_bleeding: bool = bleed_rate > BleedingConstants.BLEEDING_RATE_EPSILON
    var has_pressure: bool = CombatantEntityAccess.entity_has_direct_pressure_on_part(manager, ally, part)
    return not actively_bleeding or has_pressure


static func get_ally_medical_actions(manager: Node, performer: Dictionary, ally: Dictionary, part: String) -> Array:
    var out: Array = []
    var has_pressure: bool = CombatantEntityAccess.entity_has_direct_pressure_on_part(manager, ally, part)
    var bleed_rate: float = CombatantEntityAccess.entity_bleeding_rate_for_part(manager, ally, part)
    var actively_bleeding: bool = bleed_rate > BleedingConstants.BLEEDING_RATE_EPSILON
    var tq_indicated: bool = CombatantEntityAccess.entity_is_tourniquet_indicated_for_part(manager, ally, part)
    var tq_can: bool = CombatantEntityAccess.entity_can_apply_tourniquet(manager, ally, part)
    var junctional: bool = part in BleedingConstants.PACKING_PARTS

    # Life-threatening limb: pressure (if needed) ->'f??' ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' '
    # tourniquet before slow dressings.
    if tq_indicated and tq_can:
        MedicalPhaseFastForward._append_pressure_action_if_needed(
            manager, performer, ally, part, has_pressure, actively_bleeding, out
        )
        out.append({"move_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET, "target_part": part})
        return CombatMedicalCoordination.filter_ally_medical_actions(manager, performer, ally, out)

    # Junctional (head/chest): hold pressure before packing cavity.
    if (
        junctional
        and actively_bleeding
        and not has_pressure
        and CombatantEntityAccess.entity_can_apply_packing(manager, ally, part)
    ):
        MedicalPhaseFastForward._append_pressure_action_if_needed(
            manager, performer, ally, part, has_pressure, actively_bleeding, out
        )
        if not out.is_empty():
            return CombatMedicalCoordination.filter_ally_medical_actions(manager, performer, ally, out)

    # Default menu: pressure before dressings while actively bleeding (TCCC); pack/bandage once compression is held.
    if not has_pressure:
        MedicalPhaseFastForward._append_pressure_action_if_needed(
            manager, performer, ally, part, has_pressure, actively_bleeding, out
        )
    var dressings_ok: bool = dressings_allowed_for_part(manager, ally, part)
    if (
        dressings_ok
        and has_pressure
        and actively_bleeding
        and MedicalPhaseFastForward._battle_med_supplies_available(manager)
        and CombatantEntityAccess.entity_can_apply_stabilize(manager, ally, part)
    ):
        out.append({"move_id": CombatConstants.MOVE_ID_STABILIZE_WOUND, "target_part": part})
    if dressings_ok and CombatantEntityAccess.entity_can_apply_bandage(manager, ally, part):
        out.append({"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_part": part})
    if dressings_ok and CombatantEntityAccess.entity_can_apply_packing(manager, ally, part):
        out.append({"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_part": part})
    if tq_can and tq_indicated:
        out.append({"move_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET, "target_part": part})
    return CombatMedicalCoordination.filter_ally_medical_actions(manager, performer, ally, out)


## TCCC escalation ladder for a wound part. Returns the ordered list of valid medical actions
## (bandage ->'f??' ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' ' pack ->'f??'
## ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' ' tourniquet), filtered to only actions that pass
## `medical_action_allowed()`.
## The bandage variant used depends on `performer_id == tgt_id` (self vs ally).
static func escalation_path_for_part(tgt_id: int, performer_id: int, part: String, manager: Node) -> Array[String]:
    var path: Array[String] = []
    # Step 1: bandage (same move ID for self and ally; distinguished by target_id in listing).
    if CombatMedicalCoordination.medical_action_allowed(
        manager, performer_id, tgt_id, part, CombatConstants.MOVE_ID_BANDAGE_SELF
    ):
        path.append(CombatConstants.MOVE_ID_BANDAGE_SELF)
    # Step 2: pack (shared move ID for self and ally).
    if CombatMedicalCoordination.medical_action_allowed(
        manager, performer_id, tgt_id, part, CombatConstants.MOVE_ID_PACK_WOUND
    ):
        path.append(CombatConstants.MOVE_ID_PACK_WOUND)
    # Step 3: tourniquet (shared move ID for self and ally).
    if CombatMedicalCoordination.medical_action_allowed(
        manager, performer_id, tgt_id, part, CombatConstants.MOVE_ID_APPLY_TOURNIQUET
    ):
        path.append(CombatConstants.MOVE_ID_APPLY_TOURNIQUET)
    return path
