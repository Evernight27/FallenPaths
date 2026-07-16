class_name MedicalPhaseBatchResolve
extends RefCounted
const MANAGER_META_MEDICAL_FAST_FORWARD := "_medical_phase_fast_forward"
const INSTANT_FAST_FORWARD_MAX_SECONDS: float = 7200.0
## Harness-only cap for sim_cap termination tests (`instant_complete_on_early_exit(mgr, cap)`).
const INSTANT_FAST_FORWARD_INTERACTIVE_MAX_SECONDS: float = 600.0
## Wall-clock budget per frame while interactive fast-forward runs on **`CombatManager`**.
const INTERACTIVE_FAST_FORWARD_FRAME_BUDGET_US: int = 22000
const INSTANT_FAST_FORWARD_STAGNANT_LIMIT: int = 48
const INSTANT_FAST_FORWARD_MAX_ITERATIONS: int = 100000
const INSTANT_FAST_FORWARD_MIN_STEP_S: float = 0.001
## Idle tick when queue has no resolve_at but triage work remains (avoids sim_s=0 stall).
const INSTANT_FAST_FORWARD_IDLE_STEP_S: float = 1.0
const INSTANT_FAST_FORWARD_YIELD_EVERY_TICKS: int = 12
## Campaign contract early exit: best-effort dress passes (fighters ->'f??' ->->''''A!f??' -> -  wounds); not used for
## soak tick-replay.
const CAMPAIGN_BATCH_DRESS_MAX_ROUNDS: int = 256

## Queued events suppressed for the losing side once **`medical_phase`** is active.
const POST_VICTORY_BLOCKED_EVENT_TYPES: Array[String] = [
    CombatConstants.EVENT_MELEE_ATTACK,
    CombatConstants.EVENT_ACTION_READY,
    CombatConstants.EVENT_RECOVERY_END,
    CombatConstants.EVENT_SWAP_RANK_RESOLVE,
    CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
    CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
]

# AI / phase gating ->''--''''A!''--'''s''?" ATLS bands in BleedingConstants (docs/LIVE_PATHS.md#bleeding-units).
const MEDICAL_DANGER_BLOOD_THRESHOLD: float = BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING
const MEDICAL_DANGER_SECONDS: float = BleedingConstants.MEDICAL_TRIAGE_DANGER_SECONDS
const IMMEDIATE_PERIL_BLOOD_THRESHOLD: float = BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
const IMMEDIATE_PERIL_SECONDS: float = BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS
const MEDICAL_URGENCY_WEIGHT_MAX: float = 6.0
const MEDICAL_URGENCY_RANDOM_MIN: float = 0.8
const MEDICAL_URGENCY_RANDOM_MAX: float = 1.2
# Medical AI (`CombatAIActionPicker`): deterministic triage + skill-shaped procedure choice.
const MEDICAL_AI_PART_THREAT_MULT := 2.8
const MEDICAL_AI_ADVANCED_SKILL_EXP := 1.7
const MEDICAL_AI_PRESSURE_LOW_SKILL_MULT := 1.42
const MEDICAL_AI_PRESSURE_HIGH_SKILL_MULT := 0.66
const MEDICAL_AI_EFF_CLAMP_MIN := 0.3
const MEDICAL_AI_EFF_CLAMP_MAX := 1.5
# TCCC hemorrhage-control ladder (relative weights; illegal options already omitted from listings).
const MEDICAL_AI_WEIGHT_PRESSURE_ACTIVE_BLEED: float = 5.0
const MEDICAL_AI_WEIGHT_TOURNIQUET_INDICATED: float = 4.5
const MEDICAL_AI_WEIGHT_PACK_BEFORE_PRESSURE: float = 0.25
const MEDICAL_AI_WEIGHT_BANDAGE_BEFORE_HEMOSTASIS: float = 0.20
const MEDICAL_AI_WEIGHT_PENDING_RETRY_PERIL: float = 4.0
const MEDICAL_AI_WEIGHT_PENDING_RETRY: float = 3.0
const MEDICAL_AI_WEIGHT_FAILED_PART_RETRY: float = 2.8
## Out of immediate peril: prefer definitive dressings (bandage/pack) over stabilize-only holds.
const MEDICAL_AI_WEIGHT_STABILIZE_OUT_OF_PERIL: float = 0.32
const MEDICAL_AI_WEIGHT_DRESSING_OUT_OF_PERIL: float = 2.6
## Listing/resolve overlap guard ->''--''''A!''--'''s''?" redundant pressure or another
## medic->''--''''A!''--'''s''?->'f''s''->''''A!--'''s'...3/4->''''A!f''s''s wind-up on the same part.
const MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED: float = 0.001
## Second pair of hands on an ally-held wound (stack assist only; no takeover).
const MEDICAL_AI_WEIGHT_TREATMENT_ASSIST_PRESSURE: float = 3.5

## Medical phase queries: danger, urgency, untreated wounds, end-of-phase, ally medical actions, campaign
## **`batch_resolve_on_campaign_exit`**.
## Footing: halting wind-up on phase entry ->'f??' ->->''''A!f''s''->'f''s''->''''A!--''''A!''->''''A!f''s' '
## **`CombatFootwork.clear_on_exchange_end`** per combatant ->''''A!f''s'. **`return_to_waiting`** on idle reset
## ->''--''''A!''--'''s''?" LIVE_PATHS **`#wf-tier-44-pa`** (clear). Does **not** change **`weapon_form`** / home guard.
## Manager must have: combatants (Array), medical_phase (bool), medical_phase_winner (String), get_health_entity(node)
## -> Node (or use CombatantEntityAccess).

static var _company_state: Variant = null
static var _counter_tempo_cache: Variant = null
static var _wind_up_starter_cache: Variant = null
static var _process_tick_cache: Variant = null


static func _get_company_state() -> GDScript:
    if MedicalPhaseBatchResolve._company_state == null:
        MedicalPhaseBatchResolve._company_state = load("res://world/CompanyState.gd")
    return MedicalPhaseBatchResolve._company_state


# Runtime preload --'''s'''''? circular dependency (CounterTempo preloads MedicalPhaseController).


static func _get_counter_tempo() -> GDScript:
    if _counter_tempo_cache == null:
        _counter_tempo_cache = load("res://combat/strike/CounterTempo.gd")
    return _counter_tempo_cache


# Runtime preload -- circular dependency (AttackWindUpStarter preloads MedicalPhaseController).


static func _get_wind_up_starter() -> GDScript:
    if _wind_up_starter_cache == null:
        _wind_up_starter_cache = load("res://combat/strike/AttackWindUpStarter.gd")
    return _wind_up_starter_cache


static func _get_process_tick() -> GDScript:
    if _process_tick_cache == null:
        _process_tick_cache = load("res://combat/flow/CombatProcessTick.gd")
    return _process_tick_cache


## True once player-side victory: no new combat resolutions (medical triage only).


static func _reset_fled_and_combat_absent(c: Dictionary) -> void:
    c.erase(DataKeys.SNAPSHOT_COMBAT_ABSENT)
    if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_FLED:
        CombatFootwork.return_to_waiting(c)
        c.state_timer = 0.0
        c.state_duration = 0.0


## Player-win medical phase: cancel losing-side combat, abort wind-ups, idle combat states.


## Same threshold as bleed-out death (`CoreEntity._get_blood_loss_death_threshold` / `EntityWounds`).
static func _blood_loss_death_threshold_for_entity(entity: Node) -> float:
    return CombatantEntityAccess.entity_blood_loss_death_threshold(entity)


## Max permanent bleed rate (abstract HP/s) that stays within clotting-safe buffer before death threshold.


## Max permanent bleed rate (abstract HP/s) that stays within clotting-safe buffer before death threshold.
static func _max_safe_permanent_bleed_rate(buffer_above_death: float) -> float:
    if buffer_above_death <= 0.0:
        return 0.0
    return (
        buffer_above_death
        * BleedingConstants.CLOTTING_SAFE_EFFECTIVE_RATE
        / BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER
    )


## Shared blood-volume + time-to-death urgency (x = blood band, y = time band).


## Shared blood-volume + time-to-death urgency (x = blood band, y = time band).
static func _medical_urgency_components(blood_volume: float, death_threshold: float, bleed_rate: float) -> Vector2:
    var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_threshold
    var urgency_blood: float = (
        1.0
        if blood_volume <= death_threshold
        else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - blood_volume) / maxf(0.01, range_bv), 0.0, 1.0)
    )
    var urgency_time: float = 0.0
    if bleed_rate > 0.0:
        var time_to_death: float = BleedingConstants.seconds_to_exsanguination_at_death_threshold(
            bleed_rate, blood_volume, death_threshold, 1.0
        )
        if time_to_death < INF:
            urgency_time = (
                1.0 if time_to_death <= 0.0 else clampf(1.0 - time_to_death / MEDICAL_DANGER_SECONDS, 0.0, 1.0)
            )
    return Vector2(urgency_blood, urgency_time)


## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated.


static func _batch_complete_in_progress_windups(manager: Node) -> void:
    for c in manager.combatants:
        if c is not Dictionary:
            continue
        if not MedicalPhaseController.is_winner_side(manager, c) or not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
            continue
        var pm_raw: Variant = c.get(DataKeys.PA_PENDING_MEDICAL, null)
        if pm_raw is not Dictionary:
            continue
        var pm: Dictionary = pm_raw
        if pm.is_empty():
            continue
        MedicalWindUpHandler.complete(manager, c, pm)
        c[DataKeys.PA_PENDING_MEDICAL] = {}


static func _batch_scrub_winner_busy_states_for_exit(manager: Node) -> void:
    var busy_exit_states: Array[String] = [
        CombatConstants.STATE_RECOVERING,
        CombatConstants.STATE_MEDICAL_WIND_UP,
    ]
    for c in manager.combatants:
        if c is not Dictionary:
            continue
        if not MedicalPhaseController.is_winner_side(manager, c) or not CombatantEntityAccess.alive_bool(c):
            continue
        var st: String = CombatantEntityAccess.state_str(c)
        if st in busy_exit_states:
            CombatFootwork.return_to_waiting(c)
            c.gauge = 100.0
        elif st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
            if c.get(DataKeys.PA_RECEIVING_MEDICAL_COUNT, 0) <= 0:
                CombatFootwork.return_to_waiting(c)
                c.gauge = 100.0


static func _batch_best_effort_dress_winner_side(manager: Node) -> void:
    var rounds: int = 0
    while (
        rounds < CAMPAIGN_BATCH_DRESS_MAX_ROUNDS
        and MedicalPhaseController.winner_side_untreated_part_count(manager) > 0
    ):
        rounds += 1
        var targets: Array = MedicalPhaseBatchResolve._batch_collect_urgent_untreated_parts(manager)
        if targets.is_empty():
            break
        var progressed: bool = false
        for entry in targets:
            if entry is not Dictionary:
                continue
            var target_id: int = entry.get(DataKeys.ACTION_TARGET_ID, -1)
            var part: String = entry.get("part", "")
            if target_id < 0 or part.is_empty():
                continue
            var performer_id: int = MedicalPhaseBatchResolve._batch_pick_performer_for_part(manager, target_id, part)
            if performer_id < 0:
                continue
            var actions: Array = MedicalPhaseBatchResolve._batch_medical_actions_for_part(
                manager, performer_id, target_id, part
            )
            actions = CombatMedicalCoordination.filter_actions_for_pick(manager, performer_id, actions)
            if actions.is_empty():
                continue
            var choice: Dictionary = CombatAIActionPicker.pick_highest_medical(actions, performer_id, manager)
            if choice.is_empty():
                continue
            if MedicalPhaseBatchResolve._batch_apply_medical_action(
                manager,
                performer_id,
                int(choice.get(DataKeys.ACTION_TARGET_ID, target_id)),
                choice.get(DataKeys.ACTION_MOVE_ID, ""),
                str(choice.get(DataKeys.ACTION_TARGET_PART, part))
            ):
                progressed = true
                break
        if not progressed:
            break


static func _batch_collect_urgent_untreated_parts(manager: Node) -> Array:
    var out: Array = []
    for c in manager.combatants:
        if c is not Dictionary:
            continue
        if not MedicalPhaseController.is_winner_side(manager, c) or not CombatantEntityAccess.alive_bool(c):
            continue
        if not MedicalPhaseController.has_untreated_wounds(manager, c):
            continue
        var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
        if entity == null:
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        for part in EntityWounds.sorted_untreated_part_names(entity):
            var urgency: float = MedicalPhaseController.get_medical_urgency_deterministic(manager, c)
            urgency += MedicalPhaseController.get_part_intervention_threat(manager, c, part)
            out.append({"target_id": cid, "part": part, "urgency": urgency})
    out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.get("urgency", 0.0) > b.get("urgency", 0.0))
    return out


static func _batch_performer_available(manager: Node, c: Dictionary) -> bool:
    if not MedicalPhaseController.is_winner_side(manager, c) or not CombatantEntityAccess.alive_bool(c):
        return false
    var st: String = CombatantEntityAccess.state_str(c)
    return (
        st == CombatConstants.STATE_WAITING
        or st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
        or st == CombatConstants.STATE_RECOVERING
    )


static func _batch_pick_performer_for_part(manager: Node, target_id: int, part: String) -> int:
    for c in manager.combatants:
        if c is not Dictionary:
            continue
        if not MedicalPhaseBatchResolve._batch_performer_available(manager, c):
            continue
        var performer_id: int = CombatantEntityAccess.id_int(c)
        var actions: Array = MedicalPhaseBatchResolve._batch_medical_actions_for_part(
            manager, performer_id, target_id, part
        )
        if CombatMedicalCoordination.filter_actions_for_pick(manager, performer_id, actions).is_empty():
            continue
        return performer_id
    return -1


static func _batch_medical_actions_for_part(manager: Node, performer_id: int, target_id: int, part: String) -> Array:
    var performer: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, performer_id)
    var target: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if performer.is_empty() or target.is_empty():
        return []
    var out: Array = []
    for raw_act in MedicalPhaseController.get_ally_medical_actions(manager, performer, target, part):
        if raw_act is not Dictionary:
            continue
        var act: Dictionary = raw_act
        out.append(
            {
                "target_id": target_id,
                "move_id": act.get(DataKeys.ACTION_MOVE_ID, ""),
                "target_part": str(act.get("target_part", part)),
            }
        )
    return out


static func _batch_apply_medical_action(
    manager: Node, performer_id: int, target_id: int, move_id: String, part: String
) -> bool:
    if part.is_empty() or move_id.is_empty():
        return false
    if not CombatMedicalCoordination.medical_action_allowed(manager, performer_id, target_id, part, move_id):
        return false
    var performer: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, performer_id)
    var target: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if performer.is_empty() or target.is_empty():
        return false
    if move_id == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
        return MedicalPhaseFastForward._batch_apply_direct_pressure(
            manager, performer, target, performer_id, target_id, part
        )
    var wind_up_cfg: Dictionary = CombatConstantsMedical.wind_up_config_for(move_id)
    var target_method: String = wind_up_cfg.get("target_method", "")
    if target_method.is_empty():
        return false
    var tgt_entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, target)
    var perf_entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, performer)
    if tgt_entity == null or perf_entity == null:
        return false
    var had_treatment_assist: bool = (
        tgt_entity.get("direct_pressure_assist_held_by") != null and tgt_entity.direct_pressure_assist_held_by != null
    )
    var eff: float = CombatantEntityAccess.get_medical_effectiveness_from_node(perf_entity)
    if had_treatment_assist:
        eff += CombatConstants.MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS
        eff = clampf(eff, 0.0, 1.5)
    var result: Variant = CombatantEntityAccess.entity_invoke_medical_method(tgt_entity, target_method, part, eff)
    if result == null:
        return false
    var ok: bool = MedicalPhaseFastForward._batch_medical_procedure_succeeded(result)
    var who_m: String = CombatantEntityAccess.get_display_name(performer)
    var med_log: String = move_id if target_id == performer_id else "%s (ally)" % move_id
    var outcome: String = MedicalPhaseFastForward._batch_outcome_for_method(target_method, result, wind_up_cfg, move_id)
    CombatDebug.medical_session("Medical batch: %s %s on %s => %s" % [who_m, med_log, part, outcome])
    var world: Node2D = MedicalPhaseBatchResolve._get_company_state().resolve_world_from_battle(manager)
    if world != null:
        MedicalPhaseBatchResolve._get_company_state().on_battle_medical_complete(world, target_method, ok)
    if ok:
        var failed: Array = CombatantEntityAccess.nested_array_for_mutation(target, "failed_medical_parts")
        var idx: int = failed.find(part)
        if idx >= 0:
            failed.remove_at(idx)
        # XCamp-4: proficiency gains for batch medical actions.
        if MedicalPhaseBatchResolve._get_company_state().read_stub_proficiency_enabled():
            EntityProficiency.award_stat_gain(
                perf_entity,
                "intelligence",
                EntityProficiency.GAIN_MEDICAL_ACTION_BASE * MedicalPhaseFastForward._get_batch_item_mult(move_id)
            )
            if perf_entity != tgt_entity and tgt_entity.has("_proficiency_bonus"):
                EntityProficiency.award_stat_gain(
                    tgt_entity,
                    "endurance",
                    EntityProficiency.GAIN_BLOOD_PERIL_BASE * EntityProficiency.GAIN_MEDICAL_PATIENT_END_MULT
                )
    else:
        var failed_mut: Array = CombatantEntityAccess.nested_array_for_mutation(target, "failed_medical_parts")
        if part not in failed_mut:
            failed_mut.append(part)
    return ok
