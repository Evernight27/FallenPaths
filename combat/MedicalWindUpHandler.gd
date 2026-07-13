class_name MedicalWindUpHandler
extends RefCounted

static var _entity_access_cache: Variant = null
static var _company_state: Variant = null


static func _get_entity_access() -> GDScript:
    if MedicalWindUpHandler._entity_access_cache == null:
        MedicalWindUpHandler._entity_access_cache = load("res://combat/CombatantEntityAccess.gd")
    return MedicalWindUpHandler._entity_access_cache


# Runtime preload ' circular dependency (CompanyState |' CampaignEncounterBridge |' MedicalWindUpHandler).


static func _get_company_state() -> GDScript:
    if MedicalWindUpHandler._company_state == null:
        MedicalWindUpHandler._company_state = load("res://world/CompanyState.gd")
    return MedicalWindUpHandler._company_state


## Handles completion of medical wind-up: apply bandage/packing/tourniquet, emit outcome, track retry.
## Footing: medic **`clear_on_exchange_end`** before post-care **`STATE_RECOVERING`** - LIVE_PATHS **`#wf-tier-44-pa`**.
## Manager must have: get_health_entity (via CombatantEntityAccess), _track_medical_failure_and_maybe_retry,
## emit_signal, get.


static func complete(manager: Node, c: Dictionary, pm: Dictionary) -> void:
    var med_id: String = pm.get("medical_id", "")
    var part: String = pm.get("target_part", "")
    var tgt_cid: int = pm.get("target_combatant_id", _get_entity_access().id_int(c))
    var tgt_c: Dictionary = _get_entity_access().manager_get_combatant(manager, tgt_cid)
    var tgt_nd: Node = _get_entity_access().scene_node(tgt_c)
    var who_m: String = _get_entity_access().get_display_name(c)
    # Recovery after medical (scaled by pain/consciousness)
    var med_rec_dur: float = CombatConstants.RECOVERY_AFTER_MEDICAL_S
    var med_perf: float = _get_entity_access().get_performance_modifier(c)
    if med_perf > 0.0:
        med_rec_dur /= maxf(CombatConstants.PERF_MOD_MIN, med_perf)
    # Only apply if target is still alive (may have died during wind-up)
    var tgt_alive: bool = not tgt_c.is_empty() and _get_entity_access().is_alive_in_combat(tgt_c)
    if not tgt_c.is_empty() and tgt_nd != null and tgt_alive and not part.is_empty():
        var wind_up_cfg: Dictionary = CombatConstantsMedical.wind_up_config_for(med_id)
        var target_method: String = wind_up_cfg.get("target_method", "")
        if not target_method.is_empty():
            var tgt_entity: Node = _get_entity_access().get_entity_from_manager(manager, tgt_c)
            var perf_entity: Node = _get_entity_access().get_entity_from_manager(manager, c)
            var had_treatment_assist: bool = (
                tgt_entity != null
                and tgt_entity.get("direct_pressure_assist_held_by") != null
                and tgt_entity.direct_pressure_assist_held_by != null
            )
            var eff: float = _get_entity_access().get_medical_effectiveness_from_node(perf_entity)
            if had_treatment_assist:
                eff += CombatConstants.MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS
                eff = clampf(eff, 0.0, 1.5)
            var result: Variant = _get_entity_access().entity_invoke_medical_method(
                tgt_entity, target_method, part, eff
            )
            var world: Node2D = _get_company_state().resolve_world_from_battle(manager)
            if result != null:
                _finish_medical_procedure(
                    manager,
                    c,
                    tgt_c,
                    tgt_cid,
                    med_id,
                    part,
                    who_m,
                    med_rec_dur,
                    target_method,
                    result,
                    eff,
                    wind_up_cfg
                )
                if world != null:
                    _get_company_state().on_battle_medical_complete(
                        world, target_method, _medical_procedure_succeeded(result)
                    )
            # XCamp-4: award for completed wind-up even when the procedure fails / returns null.
            _proficiency_medical_gains(c, perf_entity, tgt_entity, world, med_id, result, who_m)
    # Target finishes receiving care: ready to act immediately
    if not tgt_c.is_empty() and tgt_cid != _get_entity_access().id_int(c):
        tgt_c.receiving_medical_count = max(0, tgt_c.get("receiving_medical_count", 0) - 1)
        if tgt_c.receiving_medical_count <= 0:
            CombatFootwork.return_to_waiting(tgt_c)
            tgt_c.gauge = 100.0
            tgt_c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
            if _get_entity_access().is_player_side(tgt_c):
                manager.notify_turn_ready(tgt_cid)
    CombatFootwork.clear_on_exchange_end(c)
    c.state = CombatConstants.STATE_RECOVERING
    c.state_timer = 0.0
    c.state_duration = med_rec_dur


static func _medical_procedure_succeeded(result: Variant) -> bool:
    if result == true:
        return true
    if result is Dictionary:
        return (result as Dictionary).get("success", false)
    return false


static func _outcome_for_medical_method(
    target_method: String, result: Variant, wind_up_cfg: Dictionary, med_id: String
) -> String:
    var ok: bool = _medical_procedure_succeeded(result)
    var outcome := CombatConstants.medical_outcome_string(target_method, ok)
    if outcome != "":
        return outcome
    return str(wind_up_cfg.get("outcome", med_id))


static func _finish_medical_procedure(
    manager: Node,
    c: Dictionary,
    tgt_c: Dictionary,
    tgt_cid: int,
    med_id: String,
    part: String,
    who_m: String,
    med_rec_dur: float,
    target_method: String,
    result: Variant,
    eff: float,
    wind_up_cfg: Dictionary
) -> void:
    var tracked: bool = CombatConstants.is_medical_target_method(target_method)
    if tracked:
        var outcome: String = _outcome_for_medical_method(target_method, result, wind_up_cfg, med_id)
        var med_log: String = med_id
        if tgt_cid != _get_entity_access().id_int(c):
            med_log = "%s (ally)" % med_id
        CombatDebug.medical_session(
            "Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_log, part, outcome, med_rec_dur]
        )
        var self_id: int = _get_entity_access().id_int(c)
        (
            manager
            . emit_signal(
                "action_resolved",
                self_id,
                tgt_cid,
                {
                    "outcome": outcome,
                    "part": part,
                    "dmg": 0,
                    "died": false,
                    "effectiveness": eff,
                    "medical_move_id": med_id,
                    "medical_target_is_self": tgt_cid == self_id,
                }
            )
        )
        if not _medical_procedure_succeeded(result):
            manager.track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
        else:
            c.pending_retry = {}
            var failed: Array = _get_entity_access().nested_array_for_mutation(tgt_c, "failed_medical_parts")
            var idx: int = failed.find(part)
            if idx >= 0:
                failed.remove_at(idx)
    elif result != false:
        var outcome: String = _outcome_for_medical_method(target_method, result, wind_up_cfg, med_id)
        CombatDebug.medical_session(
            "Medical complete: %s %s on %s => recovery %.1fs" % [who_m, med_id, part, med_rec_dur]
        )
        manager.emit_signal(
            "action_resolved",
            _get_entity_access().id_int(c),
            tgt_cid,
            {"outcome": outcome, "part": part, "dmg": 0, "died": false}
        )


## XCamp-4: award proficiency stat gains for completed medical actions.
static func _proficiency_medical_gains(
    _c: Dictionary, perf_entity: Node, tgt_entity: Node, world: Node2D, med_id: String, _result: Variant, _who_m: String
) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if perf_entity == null or not "_proficiency_bonus" in perf_entity:
        return

    # Medic INT + patient END: award for completed wind-up (practice / exposure), even when the procedure fails.

    # Determine item type from med_id for INT multiplier.
    var item_type: String = ""
    match med_id:
        CombatConstants.MOVE_ID_BANDAGE_SELF, CombatConstants.MOVE_TARGET_APPLY_BANDAGE:
            item_type = "bandage"
        CombatConstants.MOVE_TARGET_APPLY_PACKING, CombatConstants.MOVE_TARGET_APPLY_STABILIZE:
            item_type = "pack"
        CombatConstants.MOVE_ID_APPLY_TOURNIQUET:
            item_type = CombatConstants.MEDICAL_ITEM_TOURNIQUET

    var item_mult: float = EntityProficiency.get_medical_item_mult(item_type)
    var base_gain: float = EntityProficiency.GAIN_MEDICAL_ACTION_BASE * item_mult

    # INT gain for medic performing the action.
    EntityProficiency.award_stat_gain(perf_entity, "intelligence", base_gain)

    # Patient END gain (exposure to blood peril during treatment attempt).
    if tgt_entity != null and "_proficiency_bonus" in tgt_entity:
        EntityProficiency.award_stat_gain(
            tgt_entity,
            "endurance",
            EntityProficiency.GAIN_BLOOD_PERIL_BASE * EntityProficiency.GAIN_MEDICAL_PATIENT_END_MULT
        )

    # Record this medic action for post-combat INT floor bonus (per-entity tracking).
    if world != null:
        CampaignEncounterBridge.record_medic_action(world, perf_entity)
