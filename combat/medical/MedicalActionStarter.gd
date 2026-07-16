class_name MedicalActionStarter
extends RefCounted

## Starts a medical action: direct pressure (instant or during wind-up), bandage/tourniquet/pack wind-up.
## Footing: medic **`clear_on_exchange_end`** / **`reconcile_idle_offset`** on start . ally receiving scrub on entry --
## LIVE_PATHS **`#wf-tier-44-pa`**.
## Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess), emit_signal.


static func _try_windup_pressure_while_preparing(
    manager: Node, performer: Dictionary, target: Dictionary, target_part: String, medical_id: String, self_target: bool
) -> void:
    if target_part.is_empty() or not CombatantEntityAccess.entity_has_wound_part(manager, target, target_part):
        return
    var who_name: String = CombatantEntityAccess.get_display_name(performer)
    if self_target:
        var tgt_entity_self: Node = CombatantEntityAccess.get_entity_from_manager(manager, target)
        if (
            tgt_entity_self != null
            and tgt_entity_self.get("direct_pressure_part") == target_part
            and tgt_entity_self.get("direct_pressure_held_by") != null
        ):
            var perf_entity_self: Node = CombatantEntityAccess.get_entity_from_manager(manager, performer)
            if (
                perf_entity_self != null
                and CombatantEntityAccess.entity_stack_assist_pressure_during_ally_treatment(
                    manager, target, performer, target_part
                )
            ):
                CombatDebug.medical_session(
                    "%s assisting existing pressure on %s during %s wind-up" % [who_name, target_part, medical_id]
                )
                return
        if CombatantEntityAccess.entity_apply_direct_pressure(manager, target, target_part):
            CombatDebug.medical_session(
                "%s applying direct pressure on %s during %s wind-up" % [who_name, target_part, medical_id]
            )
        return
    if CombatantEntityAccess.entity_stack_assist_pressure_during_ally_treatment(
        manager, target, performer, target_part
    ):
        CombatDebug.medical_session(
            (
                "%s assisting pressure on ally's %s during %s wind-up (helper still holding)"
                % [who_name, target_part, medical_id]
            )
        )
        return
    if CombatantEntityAccess.entity_apply_direct_pressure_from_ally(manager, target, performer, target_part):
        var tgt_entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, target)
        CombatantEntityAccess.link_performer_direct_pressure_on_ally(manager, performer, tgt_entity, target_part)
        CombatDebug.medical_session(
            "%s applying direct pressure on ally's %s during %s wind-up" % [who_name, target_part, medical_id]
        )


static func start(
    manager: Node, combatant_id: int, target_combatant_id: int, medical_id: String, target_part: String
) -> void:
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    var target_node: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_combatant_id)
    if c.is_empty() or target_node.is_empty() or CombatantEntityAccess.scene_node(target_node) == null:
        return
    if manager.medical_phase and MedicalPhaseController.is_losing_side(manager, c):
        return
    if not CombatMedicalCoordination.medical_action_allowed(
        manager, combatant_id, target_combatant_id, target_part, medical_id
    ):
        return
    # Clear pending_retry when starting a different action (e.g. helping another ally)
    var pr_raw: Variant = c.get("pending_retry", null)
    if pr_raw is Dictionary:
        var pr: Dictionary = pr_raw
        if not pr.is_empty() and (pr.get(DataKeys.ACTION_TARGET_ID, -1) != target_combatant_id or pr.get(DataKeys.ACTION_PART, "") != target_part):
            c[DataKeys.PA_PENDING_RETRY] = {}
    var who_name: String = CombatantEntityAccess.get_display_name(c, combatant_id)
    # Bandage/pack/tourniquet: free treater's other holds; keep compression on the wound being dressed.
    if CombatConstants.is_wind_up_medical_move(medical_id):
        CombatantEntityAccess.prepare_for_medical_windup_scene(manager, c, target_node, target_part)
        _try_windup_pressure_while_preparing(
            manager, c, target_node, target_part, medical_id, target_combatant_id == combatant_id
        )
    var duration: float = 0.0
    if medical_id == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
        # Instant: apply now, then short recovery (scaled by pain/consciousness)
        var med_rec_dur: float = CombatConstants.RECOVERY_AFTER_MEDICAL_S
        var med_perf: float = CombatantEntityAccess.get_performance_modifier(c)
        if med_perf > 0.0:
            med_rec_dur /= maxf(CombatConstants.PERF_MOD_MIN, med_perf)
        var applied: bool = false
        if target_combatant_id == combatant_id:
            applied = CombatantEntityAccess.scene_apply_direct_pressure(target_node, target_part)
        elif CombatMedicalCoordination.can_stack_assist_pressure(
            manager, combatant_id, target_combatant_id, target_part
        ):
            if CombatantEntityAccess.entity_stack_assist_pressure_during_ally_treatment(
                manager, target_node, c, target_part
            ):
                applied = true
                CombatDebug.medical_session("%s treatment-assist pressure on ally's %s" % [who_name, target_part])
        elif CombatantEntityAccess.entity_apply_direct_pressure_from_ally(manager, target_node, c, target_part):
            applied = true
            CombatantEntityAccess.link_performer_direct_pressure_on_ally(
                manager, c, CombatantEntityAccess.get_entity_from_manager(manager, target_node), target_part
            )
        if applied:
            if not OperationalLog.is_play_session_active():
                CombatDebug.combat_session(
                    (
                        "medical %s applied direct_pressure on %s (instant) => recovery %.1fs"
                        % [who_name, target_part, med_rec_dur]
                    )
                )
            manager.emit_signal(
                "action_resolved",
                combatant_id,
                target_combatant_id,
                {"outcome": "direct_pressure", "part": target_part, "dmg": 0, "died": false}
            )
            # XCamp-4: proficiency gains for direct pressure (same INT gain as wind-up medical).
            var perf_entity = CombatantEntityAccess.get_entity_from_manager(manager, c)
            var tgt_entity = CombatantEntityAccess.get_entity_from_manager(manager, target_node)
            if CompanyState.read_stub_proficiency_enabled():
                EntityProficiency.award_stat_gain(
                    perf_entity,
                    "intelligence",
                    EntityProficiency.GAIN_MEDICAL_ACTION_BASE * EntityProficiency.GAIN_DIRECT_PRESSURE_INT_MULT
                )
                if tgt_entity != null and "_proficiency_bonus" in tgt_entity:
                    EntityProficiency.award_stat_gain(
                        tgt_entity,
                        "endurance",
                        (
                            EntityProficiency.GAIN_BLOOD_PERIL_BASE
                            * EntityProficiency.GAIN_DIRECT_PRESSURE_PATIENT_END_MULT
                        )
                    )
        CombatFootwork.clear_on_exchange_end(c)
        c.gauge = 0.0
        c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
        c.state = CombatConstants.STATE_RECOVERING
        c.state_timer = 0.0
        c.state_duration = med_rec_dur
        return
    var wind_up_cfg: Dictionary = CombatConstantsMedical.wind_up_config_for(medical_id)
    var dur_method: String = wind_up_cfg.get("duration_method", "")
    var dur_takes_part: bool = wind_up_cfg.get("duration_takes_part", false)
    var target_entity = CombatantEntityAccess.get_entity_from_manager(manager, target_node)
    if not dur_method.is_empty() and target_entity != null and target_entity.has_method(dur_method):
        if dur_takes_part and not target_part.is_empty():
            duration = target_entity.call(dur_method, target_part)
        else:
            duration = target_entity.call(dur_method)
    if duration <= 0.0 and not wind_up_cfg.is_empty():
        duration = 4.0  # fallback for custom entities
    var speed_mod: float = 1.0
    # XCamp-4: use effective INT (includes proficiency bonus) when system is enabled.
    if CompanyState.read_stub_proficiency_enabled():
        speed_mod = CombatantEntityAccess.get_effective_medical_windup_speed_modifier(manager, c, target_node)
    else:
        speed_mod = CombatantEntityAccess.get_medical_windup_speed_modifier(manager, c, target_node)
    if speed_mod > 0.0:
        duration /= speed_mod
    var assist_div: float = CombatantEntityAccess.get_medical_windup_assist_duration_divisor(
        manager, target_node, target_part
    )
    if assist_div > 1.0:
        duration /= assist_div
    if not OperationalLog.is_play_session_active():
        CombatDebug.combat_session(
            "medical %s starting %s on part=%s => wind_up=%.1fs" % [who_name, medical_id, target_part, duration]
        )
    CombatFootwork.reconcile_idle_offset(c)
    c.gauge = 0.0
    c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
    c.state = CombatConstants.STATE_MEDICAL_WIND_UP
    c.state_timer = 0.0
    c.state_duration = duration
    c.pending_medical = {
        "medical_id": medical_id, "target_part": target_part, "target_combatant_id": target_combatant_id
    }
    # Target (ally) enters receiving_medical_attention: gauge full, cannot act until care finishes
    if target_combatant_id != combatant_id:
        CombatFootwork.reconcile_idle_offset(target_node)
        target_node.receiving_medical_count = target_node.get(DataKeys.PA_RECEIVING_MEDICAL_COUNT, 0) + 1
        target_node.state = CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
        target_node.gauge = 100.0



