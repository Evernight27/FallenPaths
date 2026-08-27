class_name CombatEngagementResolver
extends RefCounted

## Close attempts (`MOVE_ID_ATTEMPT_CLOSE`): close tactical range from **LONG** (or MID/CLOSE under III-4 **3e**
## envelop) so melee can threaten.
## Footing: reads **`form_str`** for close/evasion pressure only — not **`guard_line`** or Tier 4.4 PA. LIVE_PATHS
## **`#wf-pick-vs-strike`** . **`#wf-assign-form-contract`**.
## Listing: `CombatMeleeListing`; resolve: `CombatResolveAction` --'' ' `CombatManager._resolve_close_attempt`.


static func _finish_close_attempt_turn(manager: Node, atk: Dictionary, attacker_id: int) -> void:
    atk.gauge = 0.0
    atk[DataKeys.ACTION_COOLDOWN_UNTIL] = CombatantEntityAccess.combat_clock_plus(
        manager, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
    )
    CombatEventScheduler.schedule_action_ready(manager, attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)


static func resolve_close_attempt(manager: Node, attacker_id: int, target_id: int) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if atk.is_empty() or tgt.is_empty() or not CombatantEntityAccess.are_alive_opponents(atk, tgt):
        return
    if CombatantEntityAccess.is_incapacitated(atk) or CombatantEntityAccess.is_incapacitated(tgt):
        return
    # Listed at LONG (out of reach), or MID/CLOSE under III-4 **3e** envelop
    # (`CombatMeleeListing.attempt_close_listed_for_pair`).
    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
    if not CombatMeleeListing.attempt_close_listed_for_pair(manager, atk, target_id, band):
        _reject_close_attempt_not_long(manager, atk, attacker_id, target_id, band)
        return
    if not CombatMeleeListing.defender_has_free_close_slot(manager, tgt, attacker_id):
        _reject_close_attempt_slots_full(manager, atk, attacker_id, target_id, tgt)
        return
    var melee_range: float = CombatantEntityAccess.weapon_melee_reach(atk)
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var str_val: float = float(
        atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)
    )
    var agi_def: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    var pressure: float = (
        str_val * CombatConstants.stamina_factor(CombatantEntityAccess.stamina_ratio(atk)) * (melee_range / CombatConstantsCloseSlots.CLOSE_CONTEST_MELEE_RANGE_NORMALIZER)
    )
    pressure *= CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(atk), "close_attempt", CombatantEntityAccess.get_weapon(atk)
    )
    var evasion: float = agi_def * CombatConstants.stamina_factor(CombatantEntityAccess.stamina_ratio(tgt))
    evasion *= CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(tgt), "evasion", CombatantEntityAccess.get_weapon(tgt)
    )
    evasion *= TacticalCombat.ambush_defense_multiplier(manager, tgt)
    if CombatWeaponForm.controlling_pressure_active(tgt):
        evasion /= CombatWeaponForm.opponent_close_evasion_divisor(CombatantEntityAccess.form_str(tgt))
    var ctx_tgt: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, tgt)
    var form_geom: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx_tgt)
    var density: String = str(form_geom.get(DataKeys.FORMATION_DENSITY, "normal")) if not form_geom.is_empty() else "normal"
    evasion *= CombatConstants.get_density_close_mod(density)
    var success: bool = randf() < pressure / (pressure + maxf(evasion, 1.0))
    if CombatDebug.flow_verbose_enabled():
        CombatDebug.flow_log(
            (
                "close_attempt atk=%d tgt=%d success=%s pressure=%.1f evasion=%.1f"
                % [attacker_id, target_id, success, pressure, evasion]
            )
        )
    elif not OperationalLog.is_play_session_active() and CombatConstants.combat_event_debug_active():
        var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
        var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
        CombatDebug.combat_session(
            (
                "close attempt %s vs %s: %s (next turn in %.1fs)"
                % [atk_name, tgt_name, "success" if success else "failed", CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S]
            )
        )
    var close_result: Dictionary = {"outcome": "close_success", "dmg": 0, "died": false}
    if not success:
        close_result = {"outcome": "close_failed", "dmg": 0, "died": false, "reason": "contest_failed"}
        var contest_tag: String = ""
        if CombatWeaponForm.controlling_pressure_active(tgt):
            contest_tag = CombatUiHints.close_attempt_list_hint_for_defender(tgt)
        if not contest_tag.is_empty():
            close_result[DataKeys.CLOSE_CONTEST_NOTE] = contest_tag
    manager.emit_signal("action_resolved", attacker_id, target_id, close_result)
    var blk: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(atk, "close_block_until_by_target_id")
    if success:
        CombatantEntityAccess.sync_close_distance_pair(atk, tgt, attacker_id, target_id)
        # Closing distance is a leg-driven advance: the initiator's legs tire (slows their next movement via
        # step_speed_mult, degrades dodge via dodge_chance_mult). Only the initiator moves; the defender's band
        # is a symmetric modeling artifact. Leg fatigue is arm-independent, so parry capacity is unaffected.
        CombatMuscleFatigue.apply_formation_exertion(atk, CombatConstants.MOVE_ID_ATTEMPT_CLOSE)
        blk.erase(target_id)
        CombatTargetScoring.on_combat_commitment(manager, attacker_id, target_id)
    else:
        blk[target_id] = (
            CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S
        )
    _finish_close_attempt_turn(manager, atk, attacker_id)


static func _reject_close_attempt_not_long(
    manager: Node, atk: Dictionary, attacker_id: int, target_id: int, band: String
) -> void:
    TacticalCombat.record_invalid_close_resolve_blocked(manager)
    if CombatDebug.flow_verbose_enabled():
        CombatDebug.flow_log("close_blocked id=%d->%d reason=not_long dist=%s" % [attacker_id, target_id, band])
    manager.emit_signal(
        "action_resolved",
        attacker_id,
        target_id,
        {"outcome": "close_failed", "dmg": 0, "died": false, "reason": "not_long"}
    )
    _finish_close_attempt_turn(manager, atk, attacker_id)


static func _reject_close_attempt_slots_full(
    manager: Node, atk: Dictionary, attacker_id: int, target_id: int, tgt: Dictionary
) -> void:
    TacticalCombat.record_invalid_close_resolve_blocked(manager)
    if CombatDebug.flow_verbose_enabled():
        (
            CombatDebug
            . flow_log(
                (
                    "close_blocked id=%d->%d reason=close_slots_full cap=%d occupied=%d"
                    % [
                        attacker_id,
                        target_id,
                        CombatMeleeListing.max_close_slots_for_defender(manager, tgt),
                        CombatMeleeListing.count_close_attackers_on_defender(manager, target_id, attacker_id),
                    ]
                )
            )
        )
    manager.emit_signal(
        "action_resolved",
        attacker_id,
        target_id,
        {"outcome": "close_failed", "dmg": 0, "died": false, "reason": "close_slots_full"}
    )
    var blk: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(atk, "close_block_until_by_target_id")
    blk[target_id] = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S
    )
    _finish_close_attempt_turn(manager, atk, attacker_id)






