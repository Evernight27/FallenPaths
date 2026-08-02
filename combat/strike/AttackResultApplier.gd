class_name AttackResultApplier
extends RefCounted

## Applies AttackResolver result to combatant state: skip, defeated, miss, dodge, parry_deflect, parry_partial, hit.
## Footing: **`GuardLineUpdater`** on hit stagger (**`low`**), dodge guard, move finish - L3 drift;
## **`CombatFootwork.clear_on_exchange_end`** on exchange end. LIVE_PATHS **`#wf-guard-writers`** - **`#wf-tier-44-pa`**
## (clear).
## **`parry_deflect`**: records **`CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`** on
## **`attacker`** for Tier **4.2** feint listing pressure vs **`target_id`**; **`action_resolved`** emits
## **`target_id`**, **`attacker_id`**, then payload ( **`parry_clash_context`** copied when resolver supplied a dict -
## **`BattleScene`** parameter names follow slot order).
## **`parry_partial`**: **`action_resolved`** emits **`target_id`**, **`attacker_id`**, then payload (**defender**,
## **attacker**, same slot order as **`parry_deflect`**); then **`_execute_attack`** continues the strike. Resolver
## **`parry_clash_context`** is copied onto the **attacker** dict and onto the emitted payload when present. When the
## defender meets the same blade-alignment gate used for guard updates and clash **`parry_control`** crosses the bind
## threshold (**`PARRY_BIND_CONTROL_THRESHOLD`**), set **`parry_was_bind`**, **`parry_against_id`**,
## **`parry_bonus_until`** on the defender like **`parry_deflect`** so bind-riposte wind-up can apply; aligned but
## sub-threshold control sets **`parry_was_bind`** false; misaligned partial **`erase`**s those keys (clears stale bind
## state).
## Manager must have: emit_signal, _get_by_id, _check_for_winner, _end_combat_phase, _execute_attack.
## **`hit`**: clears **`parry_clash_context`** / **`defender_guard_line_at_parry`** / **`defender_form_at_parry`** on the attacker (stale partial-parry
## calibration after follow-through); clears Tier **4.2** feint listing parry-deflect memory for **`target_id`**.


static func _log_outcome(action: String, atk_id: int, tgt_id: int) -> void:
    if CombatConstants.combat_debug_active():
        CombatDebug.log("%s atk=%d tgt=%d" % [action, atk_id, tgt_id])


## F5 soak (**II-2b**): grep `parry_deflect` / `parry_bind` / `parry_partial` without **`COMBAT_DEBUG`**.
static func _log_fp_parry_outcome(
    atk: Dictionary, tgt: Dictionary, atk_id: int, tgt_id: int, outcome: String, clash: Dictionary
) -> void:
    if not OperationalLog.is_play_session_active():
        return
    var atk_n: String = CombatantEntityAccess.get_display_name(atk, atk_id)
    var tgt_n: String = CombatantEntityAccess.get_display_name(tgt, tgt_id)
    var ctrl: float = clash.get(DataKeys.RESULT_PARRY_CONTROL, 0.0)
    var reason: String = CombatLogFormatter.damage_resolve_note({"outcome": outcome})
    var interpose_suffix: String = ""
    var interpose_boost: float = clash.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0)
    if interpose_boost > 0.0:
        interpose_suffix = (
            " arm_interpose_arm=%s arm_interpose_boost=%.3f"
            % [
                clash.get(DataKeys.RESULT_ARM_INTERPOSE_ARM, ""),
                interpose_boost,
            ]
        )
    if outcome == "parry_deflect":
        var tag: String = "parry_bind" if tgt.get(DataKeys.PA_PARRY_WAS_BIND, false) else "parry_deflect"
        CombatDebug.combat_session(
            "%s %s vs %s ctrl=%.3f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, reason, interpose_suffix]
        )
    elif outcome == "parry_partial":
        var rem: float = 0.0
        if clash.has(DataKeys.RESULT_REMAINING_RATIO):
            rem = float(clash[DataKeys.RESULT_REMAINING_RATIO])
        var bind: bool = tgt.get(DataKeys.PA_PARRY_WAS_BIND, false)
        var tag: String = "parry_bind" if bind else "parry_partial"
        CombatDebug.combat_session(
            (
                "%s %s vs %s ctrl=%.3f remaining_ratio=%.2f reason=%s%s"
                % [tag, tgt_n, atk_n, ctrl, rem, reason, interpose_suffix]
            )
        )


static func _consume_stamina(manager: Node, c: Dictionary, amount: float) -> void:
    if c == null:
        return
    var s: float = CombatantEntityAccess.stamina_float(c)
    c[DataKeys.COMBATANT_STAMINA] = maxf(0.0, s - amount)
    CombatExhaustion.apply_exertion_from_stamina_spend(manager, c, amount)


static func _stamina_parry_cost_for_defender(atk: Dictionary, incoming_intensity: float = -1.0, consecutive_parry_count: int = 1) -> float:
    var i: float = incoming_intensity
    if i < 0.0:
        i = 0.5
        if not atk.is_empty():
            i = _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5)
    var base_cost: float = CombatConstants.stamina_parry_cost_from_intensity(i)
    # Consecutive parry fatigue: repeated parrying without full recovery compounds stamina drain.
    if consecutive_parry_count > 1:
        base_cost *= CombatConstants.consecutive_parry_stamina_mult(consecutive_parry_count)
    return base_cost

static func _stamina_dodge_cost_for_defender(atk: Dictionary, intensity: float = -1.0) -> float:
    var i: float = intensity
    if i < 0.0:
        i = 0.5
        if not atk.is_empty():
            i = _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5)
    return CombatConstants.stamina_dodge_cost_from_intensity(i)


static func _stamina_attack_cost_for_attacker(manager: Node, atk: Dictionary, target_id: int) -> float:
    if atk.is_empty():
        return CombatConstants.stamina_attack_cost_from_intensity(1.0)
    var cost: float = CombatConstants.stamina_attack_cost_from_intensity(
        _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 1.0)
    )
    if manager != null and target_id >= 0:
        var clk: float = CombatantEntityAccess.combat_clock_float(manager)
        cost *= CombatFlurryBind.stamina_attack_cost_mult(atk, target_id, clk)
    cost *= _consecutive_action_stamina_mult_for_combatant(atk)
    return cost


static func _consecutive_action_stamina_mult_for_combatant(c: Dictionary) -> float:
    var count: int = c.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0)
    if count <= 1:
        return 1.0
    var t: float = float(count - 1)
    return lerpf(1.0, 2.5, clampf(t / 4.0, 0.0, 1.0))


static func _track_consecutive_action_start(c: Dictionary) -> void:
    if c.is_empty():
        return
    var state: String = c.get(DataKeys.COMBATANT_STATE, "")
    if state == CombatConstants.STATE_RECOVERING:
        c[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = 1
        return
    var count: int = c.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0) + 1
    c[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = count


static func _track_consecutive_parry_for_defender(tgt: Dictionary) -> int:
    if tgt.is_empty():
        return 1
    var state: String = tgt.get(DataKeys.COMBATANT_STATE, "")
    # If defender is in recovery, parry streak resets.
    if state == CombatConstants.STATE_RECOVERING:
        tgt[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES] = 1
        return 1
    var count: int = tgt.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES, 0) + 1
    tgt[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES] = count
    return count


static func _pending_attack_read(atk: Dictionary) -> Dictionary:
    return CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")


static func _tuning_follow_through_extras(atk: Dictionary) -> Dictionary:
    if atk.is_empty() or not atk.has(DataKeys.PA_TUNING_FT_PARENT_STRIKE):
        return {}
    return {
        "parent_exchange_index": int(atk[DataKeys.PA_TUNING_FT_PARENT_STRIKE]),
        "note": "follow_through_from_parry",
    }


static func _clear_tuning_follow_through_marker(atk: Dictionary) -> void:
    if not atk.is_empty():
        atk.erase(DataKeys.PA_TUNING_FT_PARENT_STRIKE)


static func _tuning_parry_parent_strike_index(manager: Node) -> int:
    if manager == null:
        return -1
    return int(manager.get_meta("tuning_strike_count", 0)) + 1


static func _hit_tuning_extras(
    atk: Dictionary, intensity: float, recovery_duration: float, ft_extras: Dictionary
) -> Dictionary:
    var extras: Dictionary = {
        "intensity": intensity,
        "recovery_s": recovery_duration,
        "move_id": atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")) if not atk.is_empty() else "",
        "attack_line": atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "") if not atk.is_empty() else "",
    }
    extras.merge(ft_extras)
    return extras


static func _tuning_context_enabled(manager: Node) -> bool:
    return manager != null and bool(manager.get_meta("tuning_expose_strike_context", false))


## Tuning scene: stamp wind-up / guard / parry context on `action_resolved` payloads.
static func _enrich_payload_for_tuning(
    manager: Node, payload: Dictionary, atk: Dictionary, tgt: Dictionary, pa: Dictionary, extras: Dictionary = {}
) -> void:
    if not _tuning_context_enabled(manager):
        return
    if not pa.is_empty():
        payload[DataKeys.RESULT_MOVE_ID] = str(pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, ""))
        payload[DataKeys.ATTACK_INTENSITY] = float(pa.get(DataKeys.ATTACK_INTENSITY, 0.0))
        payload[DataKeys.RESULT_POWER] = float(pa.get(DataKeys.ATTACK_POWER, 0.0))
        payload[DataKeys.RESULT_FOLLOW_THROUGH] = float(pa.get(DataKeys.ATTACK_FOLLOW_THROUGH, 0.0))
        payload["wind_up_s"] = float(pa.get(DataKeys.PA_WIND_UP_DURATION, 0.0))
        payload[DataKeys.RESULT_ATTACK_LINE] = str(pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""))
        if pa.has(DataKeys.PA_GAUGE_ATK_PRE):
            payload[DataKeys.PA_GAUGE_ATK_PRE] = float(pa[DataKeys.PA_GAUGE_ATK_PRE])
            payload["gauge_def_pre"] = float(pa.get(DataKeys.RESOLVE_GAUGE_DEF_PRE, -1.0))
    if not atk.is_empty():
        if str(payload.get(DataKeys.ACTION_MOVE_ID, "")).is_empty():
            payload[DataKeys.RESULT_MOVE_ID] = str(atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")))
        payload["atk_guard"] = str(atk.get(DataKeys.ATTACK_GUARD_LINE, ""))
        payload["atk_form"] = str(atk.get(DataKeys.PA_WEAPON_FORM, atk.get(DataKeys.COMBATANT_FORM_STR, "")))
        if CombatantEntityAccess.has_weapon(atk):
            var w = CombatantEntityAccess.get_weapon(atk)
            if w is Dictionary:
                payload[DataKeys.RESULT_WEAPON_ID] = str((w as Dictionary).get("id", ""))
            elif w != null and w.get("id") != null:
                payload[DataKeys.RESULT_WEAPON_ID] = str(w.id)
    if not tgt.is_empty():
        payload["def_guard"] = str(tgt.get(DataKeys.ATTACK_GUARD_LINE, ""))
    for k in extras:
        payload[k] = extras[k]
    if str(payload.get(DataKeys.WD_KINEMATIC_DELIVERY, "")).is_empty() and not pa.is_empty():
        var arch: Variant = pa.get(DataKeys.WD_ARCHETYPE, null)
        if arch is Dictionary:
            var arch_delivery: String = str((arch as Dictionary).get(DataKeys.WD_KINEMATIC_DELIVERY, ""))
            if not arch_delivery.is_empty():
                payload[DataKeys.RESULT_KINEMATIC_DELIVERY] = arch_delivery
    var outcome: String = str(payload.get(DataKeys.RESULT_OUTCOME, ""))
    if outcome in ["parry_deflect", "parry_partial"]:
        var clash: Variant = payload.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
        if clash is Dictionary:
            payload["parry_bind"] = bool(tgt.get(DataKeys.PA_PARRY_WAS_BIND, false)) if not tgt.is_empty() else false
            payload[DataKeys.RESULT_PARRY_CONTROL] = float((clash as Dictionary).get(CombatConstants.CLASH_KEY_PARRY_CONTROL, 0.0))
            if (clash as Dictionary).has(DataKeys.RESULT_REMAINING_RATIO):
                payload["follow_through_rem"] = float((clash as Dictionary)[DataKeys.RESULT_REMAINING_RATIO])
            var delivery: String = str((clash as Dictionary).get(DataKeys.WD_KINEMATIC_DELIVERY, ""))
            if not delivery.is_empty():
                payload[DataKeys.RESULT_KINEMATIC_DELIVERY] = delivery


static func _clear_attacker_pending_attack(atk: Dictionary, manager: Node) -> void:
    if atk.is_empty():
        return
    var pa0: Dictionary = _pending_attack_read(atk)
    AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa0)
    CombatFootwork.clear_on_exchange_end(atk)
    atk.pending_attack = {}


static func _react_attacking_arm_loss_after_wound(manager: Node, c: Variant) -> void:
    if manager == null or c == null or not (c is Dictionary):
        return
    var cd: Dictionary = c as Dictionary
    if cd.is_empty():
        return
    CombatantEntityAccess.react_attacking_arm_lost_if_needed(manager, cd)


static func _clear_defender_footwork(tgt: Dictionary) -> void:
    if not tgt.is_empty():
        CombatFootwork.clear_on_exchange_end(tgt)


static func _abort_incoming_wind_up_if_target_died(manager: Node, target_id: int) -> void:
    if manager == null or target_id < 0:
        return
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if tgt.is_empty() or CombatantEntityAccess.alive_bool(tgt):
        return
    CounterTempo.abort_attacker_wind_up(manager, target_id)


## Parry outcomes default the defender to waiting. Paired formation moves (`swap_rank` / drag / fall_back_pair)
## keep both partners in motion state until resolve - do not clobber that here.
static func _defender_set_idle_after_parry(tgt: Dictionary) -> void:
    if tgt.is_empty():
        return
    if (
        CombatantEntityAccess.state_str(tgt)
        in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]
    ):
        return
    _clear_defender_footwork(tgt)
    CombatFootwork.return_to_waiting(tgt)
    tgt.state_timer = 0.0
    tgt.state_duration = 0.0


static func apply_result(manager: Node, attacker_id: int, result: Dictionary) -> void:
    var action: String = result.get(DataKeys.RESULT_ACTION, "skip")
    var target_id: int = result.get(DataKeys.ACTION_TARGET_ID, -1)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    _track_consecutive_action_start(atk)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
    var tgt_scene: Node = CombatantEntityAccess.scene_node(tgt)
    var empty_result: Dictionary = {
        "dmg": 0,
        "died": false,
        "part": "",
        "damage_type": "",
        "outcome": "",
        "health_before": 0,
        "health_after": 0,
        "final_cut": 0,
        "final_blunt": 0
    }

    if action == "skip":
        if not atk.is_empty():
            if result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0) > 0.0:
                empty_result[DataKeys.RESULT_OUTCOME] = "skip"
                manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
                var pa_skip: Dictionary = _pending_attack_read(atk)
                atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_skip.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
                atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
                atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_skip.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
                atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "skip"
                _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
                atk.state = CombatConstants.STATE_RECOVERING
                atk.state_timer = 0.0
                atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
                _clear_attacker_pending_attack(atk, manager)
                _react_attacking_arm_loss_after_wound(manager, atk)
            else:
                CombatFootwork.return_to_waiting(atk)
                atk.gauge = 0.0
                atk.erase(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS)
                _clear_attacker_pending_attack(atk, manager)
                _react_attacking_arm_loss_after_wound(manager, atk)
        return
    if action == "defeated":
        if not tgt.is_empty():
            tgt.alive = false
            CombatFootwork.clear_on_death(tgt)
            tgt.state = CombatConstants.STATE_DEAD
            CombatStateHandlers.cancel_events_for_dead_combatant(manager, tgt)
        if not atk.is_empty():
            # Resolver abort (e.g. no targetable parts): do not leave attacker stuck in WIND_UP with stale
            # `pending_attack`. Clear consecutive counter since we never enter RECOVERING.
            atk.erase(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS)
            _clear_attacker_pending_attack(atk, manager)
            CombatFootwork.return_to_waiting(atk)
            atk.gauge = 0.0
            atk.state_timer = 0.0
            atk.state_duration = 0.0
        empty_result[DataKeys.RESULT_OUTCOME] = "defeated"
        empty_result[DataKeys.RESULT_DIED] = true
        _abort_incoming_wind_up_if_target_died(manager, target_id)
        manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
        var winner: String = manager._check_for_winner()
        if not winner.is_empty():
            manager._end_combat_phase(winner, tgt_scene)
        return
    if action == "miss":
        empty_result[DataKeys.RESULT_OUTCOME] = "miss"
        _log_outcome("miss", attacker_id, target_id)
        var pa_miss_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
        if not tgt.is_empty() and not pa_miss_log.is_empty():
            _record_resolved_exchange_yomi(tgt, attacker_id, pa_miss_log, true)
            _evaluate_counter_read_outcome(manager, attacker_id, target_id, CombatantEntityAccess.form_str(tgt))
        var miss_part: String = pa_miss_log.get(DataKeys.ACTION_TARGET_PART, "")
        if not miss_part.is_empty():
            empty_result[DataKeys.RESULT_PART] = miss_part
        CombatF5SoakTrace.note_strike_avoided(attacker_id, target_id, atk, tgt, "miss", miss_part)
        _enrich_payload_for_tuning(
            manager, empty_result, atk, tgt, pa_miss_log, {"recovery_s": float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0))}
        )
        manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
        # XCamp-4: proficiency gains on miss (wind-up completion).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "miss", empty_result)
        if not atk.is_empty():
            var pa_miss: Dictionary = _pending_attack_read(atk)
            atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_miss.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
            atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_miss.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
            atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_miss"
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
            atk[DataKeys.PA_OFF_BALANCE_UNTIL] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
            _clear_attacker_pending_attack(atk, manager)
        _clear_defender_footwork(tgt)
        return
    if action == "dodge":
        empty_result[DataKeys.RESULT_OUTCOME] = "dodge"
        _log_outcome("dodge", attacker_id, target_id)
        var pa_dodge_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
        if not tgt.is_empty() and not pa_dodge_log.is_empty():
            _record_resolved_exchange_yomi(tgt, attacker_id, pa_dodge_log, true)
        var dodge_part: String = str(pa_dodge_log.get(DataKeys.ATTACK_PARTIAL_DODGE_PART, pa_dodge_log.get(DataKeys.ACTION_TARGET_PART, "")))
        if not tgt.is_empty() and not pa_dodge_log.is_empty():
            _evaluate_counter_read_outcome(manager, attacker_id, target_id, CombatantEntityAccess.form_str(tgt))
        if not dodge_part.is_empty():
            empty_result[DataKeys.RESULT_PART] = dodge_part
        CombatF5SoakTrace.note_strike_avoided(attacker_id, target_id, atk, tgt, "dodge", dodge_part)
        _enrich_payload_for_tuning(
            manager, empty_result, atk, tgt, pa_dodge_log, {"recovery_s": float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0))}
        )
        manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
        # XCamp-4: proficiency gains on dodge (AGI for defender, STR wind-up for attacker).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "dodge", empty_result)
        if not atk.is_empty():
            var pa_dodge_atk: Dictionary = _pending_attack_read(atk)
            atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_dodge_atk.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
            atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_dodge_atk.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
            atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_miss"
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
        if not tgt.is_empty():
            var dodge_intensity: float = _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5) if not atk.is_empty() else 0.5
            _consume_stamina(manager, tgt, _stamina_dodge_cost_for_defender(atk, dodge_intensity))
            # Defender moved to avoid; blade/body ends in dodge position (e.g. duck high attack -> low guard).
            # Use effective_attack_line for diagonal moves (actual trajectory).
            var pa: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
            var move_id: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            var move_def: Dictionary = WeaponConstants.get_move(move_id) if not move_id.is_empty() else {}
            var atk_line: String = pa.get(
                DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high")
            )
            var dodge_guard: String = CombatConstants.DODGE_END_GUARD_FROM_ATTACK.get(
                atk_line, tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
            )
            GuardLineUpdater.set_guard_from_line(tgt, dodge_guard)
            if CombatConstants.combat_debug_active():
                CombatDebug.log(
                    (
                        "guard_line %s: -> %s (dodged %s)"
                        % ["id:%d" % CombatantEntityAccess.id_int(tgt), dodge_guard, atk_line]
                    )
                )
        if not atk.is_empty():
            _clear_attacker_pending_attack(atk, manager)
        _clear_defender_footwork(tgt)
        return
    if action == "parry_deflect":
        var incoming_parry_intensity: float = 0.5
        var pa_deflect: Dictionary = {}
        if not atk.is_empty():
            pa_deflect = _pending_attack_read(atk)
            if not tgt.is_empty() and not pa_deflect.is_empty():
                _record_resolved_exchange_yomi(tgt, attacker_id, pa_deflect, true)
            incoming_parry_intensity = float(
                pa_deflect.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
            )
            atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_deflect.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
            atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_deflect.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
            # HEMA: store defender's guard and parry_clash_context for bind vs deflect.
            if not tgt.is_empty():
                atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
                atk[DataKeys.PA_DEFENDER_FORM_AT_PARRY] = CombatantEntityAccess.form_str(tgt)
            else:
                atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = ""
                atk[DataKeys.PA_DEFENDER_FORM_AT_PARRY] = ""
            var atk_clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
            atk[DataKeys.PA_PARRY_CLASH_CONTEXT] = atk_clash_raw if atk_clash_raw is Dictionary else {}
            _clear_attacker_pending_attack(atk, manager)
            atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_deflect"
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
            atk[DataKeys.PA_OFF_BALANCE_UNTIL] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
        if not tgt.is_empty():
            var consec_parries: int = _track_consecutive_parry_for_defender(tgt)
            _consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_parry_intensity, consec_parries))
            # Weapon position: defender's blade met attacker's; blade ends in attack line.
            # Use effective_attack_line for diagonal moves (actual contact line).
            var move_id: String = atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")) if not atk.is_empty() else ""
            var eff_line: String = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "") if not atk.is_empty() else ""
            GuardLineUpdater.set_guard_from_move(tgt, move_id, eff_line)
            tgt[DataKeys.PA_PARRY_BONUS_UNTIL] = CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
            if not CombatMobilityRetreat.cannot_commit_melee(tgt):
                CounterTempo.grant_riposte_chain(manager, tgt, attacker_id)
                var clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
                var clash: Dictionary = clash_raw if clash_raw is Dictionary else {}
                var arch_id: String = clash.get(DataKeys.PA_ARCHETYPE_ID, "")
                var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
                tgt[DataKeys.PA_PARRY_WAS_BIND] = (
                    can_bind
                    and CombatConstants.parry_bind_control_reached(
                        float(clash.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL))
                    )
                )
                tgt[DataKeys.PA_PARRY_AGAINST_ID] = attacker_id
                if tgt.get(DataKeys.PA_PARRY_WAS_BIND, false):
                    CombatConstants.apply_parry_bind_riposte_gauge_bonus(tgt)
                    CombatFlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
            else:
                tgt.erase(DataKeys.PA_PARRY_WAS_BIND)
                tgt.erase(DataKeys.PA_PARRY_AGAINST_ID)
                CounterTempo.clear_riposte_chain(tgt)
            _defender_set_idle_after_parry(tgt)
        empty_result[DataKeys.RESULT_OUTCOME] = "parry_deflect"
        var clash_emit: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
        if clash_emit is Dictionary:
            empty_result[DataKeys.PA_PARRY_CLASH_CONTEXT] = clash_emit
        _log_outcome("parry_deflect", attacker_id, target_id)
        var clash_log: Dictionary = (
            result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, {}) if result.get(DataKeys.PA_PARRY_CLASH_CONTEXT) is Dictionary else {}
        )
        _log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_deflect", clash_log)
        # XCamp-4: proficiency gains on parry_deflect (partial STR for both).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "parry_deflect", empty_result)
        if not atk.is_empty():
            CombatAIActionPicker.record_opp_parry_deflect_for_feint_listing(manager, atk, target_id)
        if not tgt.is_empty():
            CombatAttention.record_parry_deflect_on_attacker_memory(tgt, attacker_id)
            _evaluate_counter_read_outcome(manager, attacker_id, target_id, atk.get(DataKeys.PA_DEFENDER_FORM_AT_PARRY, ""))
            ## Phase 2: apply overcommit penalty — reduce parry readiness when wrong counter-read was just confirmed.
            if CombatWeaponForm.is_counter_read_committed(atk, manager.combat_clock):
                var recent_wrong: int = CombatWeaponForm.count_recent_wrong_readings(atk)
                if recent_wrong > 0:
                    atk[DataKeys.PA_OVERCOMMIT_PARRY_MULT] = CombatConstantsEncounter.OVERCOMMIT_PARRY_DEFLECT_PENALTY
        _enrich_payload_for_tuning(manager, empty_result, atk, tgt, pa_deflect)
        manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)
        return
    if action == "parry_partial":
        var incoming_partial_intensity: float = 0.5
        var pa_partial_emit: Dictionary = {}
        if not atk.is_empty():
            var pa_partial_int: Dictionary = _pending_attack_read(atk)
            pa_partial_emit = pa_partial_int
            incoming_partial_intensity = pa_partial_int.get(DataKeys.ATTACK_INTENSITY, 0.5)
            var partial_clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
            atk[DataKeys.PA_PARRY_CLASH_CONTEXT] = partial_clash_raw if partial_clash_raw is Dictionary else {}
            if not tgt.is_empty():
                atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
                atk[DataKeys.PA_DEFENDER_FORM_AT_PARRY] = CombatantEntityAccess.form_str(tgt)
        if not tgt.is_empty():
            var consec_parries_partial: int = _track_consecutive_parry_for_defender(tgt)
            _consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_partial_intensity, consec_parries_partial))
            var pa_partial: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
            if not pa_partial.is_empty():
                _record_resolved_exchange_yomi(tgt, attacker_id, pa_partial, true)
            var move_id: String = pa_partial.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            var move_def: Dictionary = WeaponConstants.get_move(move_id)
            var atk_line: String = pa_partial.get(
                DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high")
            )
            var align_ctx: Dictionary = {}
            if pa_partial.get(DataKeys.ATTACK_ATTACK_ANGLE_DEG, -999.0) >= 0.0:
                var read: float = PassiveParryContext.get_passive_parry_readiness(tgt)
                var def_w = CombatantEntityAccess.get_weapon(tgt)
                var wob: Dictionary = CombatantEntityAccess.parry_wobble_context(def_w, read)
                align_ctx = {
                    DataKeys.ATTACK_ANGLE_DEG: pa_partial[DataKeys.ATTACK_ANGLE_DEG],
                    "guard_angle_deg": CombatFootwork.guard_angle_deg(tgt, wob),
                }
            var align: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
            if align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD:
                GuardLineUpdater.set_guard_from_move(tgt, move_id, atk_line)
                var pcl_bind: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
                var clash_bind: Dictionary = pcl_bind if pcl_bind is Dictionary else {}
                var arch_bind: String = clash_bind.get(DataKeys.PA_ARCHETYPE_ID, "")
                var can_bind_partial: bool = (
                    arch_bind.is_empty() or arch_bind not in CombatConstants.ARCHETYPES_NEVER_BIND
                )
                var is_bind: bool = (
                    can_bind_partial
                    and CombatConstants.parry_bind_control_reached(
                        float(
                            clash_bind.get(
                                CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
                            )
                        )
                    )
                )
                tgt[DataKeys.PA_PARRY_WAS_BIND] = is_bind
                if is_bind:
                    tgt[DataKeys.PA_PARRY_AGAINST_ID] = attacker_id
                    tgt[DataKeys.PA_PARRY_BONUS_UNTIL] = (
                        CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
                    )
                    CombatFlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
                else:
                    tgt.erase(DataKeys.PA_PARRY_AGAINST_ID)
                    tgt.erase(DataKeys.PA_PARRY_BONUS_UNTIL)
            else:
                tgt.erase(DataKeys.PA_PARRY_WAS_BIND)
                tgt.erase(DataKeys.PA_PARRY_AGAINST_ID)
                tgt.erase(DataKeys.PA_PARRY_BONUS_UNTIL)
            _defender_set_idle_after_parry(tgt)
        var partial_emit: Dictionary = {DataKeys.RESULT_OUTCOME: "parry_partial", DataKeys.RESULT_DMG: 0, DataKeys.RESULT_DIED: false}
        var pcl_emit: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
        if pcl_emit is Dictionary:
            partial_emit[DataKeys.PA_PARRY_CLASH_CONTEXT] = pcl_emit
        _log_outcome("parry_partial", attacker_id, target_id)
        var clash_partial: Dictionary = pcl_emit if pcl_emit is Dictionary else {}
        _log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_partial", clash_partial)
        # XCamp-4: proficiency gains on parry_partial (small STR for attacker).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "parry_partial", partial_emit)
        var remaining_ratio: float = pa_partial_emit.get(DataKeys.ATTACK_PARRY_REMAINING_RATIO, 1.0)
        if not atk.is_empty():
            _evaluate_counter_read_outcome(manager, attacker_id, target_id, atk.get(DataKeys.PA_DEFENDER_FORM_AT_PARRY, ""))
        ## Phase 3: parry — defender's guard held, reset their breaks; attacker gets break on follow-through.
        if not atk.is_empty() and remaining_ratio <= 0.1:
            MentalStackDecider._reset_guard_breaks(atk)
        if remaining_ratio > 0.1 and not tgt.is_empty():
            MentalStackDecider._record_guard_break(tgt)
        _enrich_payload_for_tuning(manager, partial_emit, atk, tgt, pa_partial_emit)
        if _tuning_context_enabled(manager) and not atk.is_empty():
            var parent_idx: int = _tuning_parry_parent_strike_index(manager)
            if parent_idx > 0:
                atk[DataKeys.PA_TUNING_FT_PARENT_STRIKE] = parent_idx
        manager.emit_signal("action_resolved", target_id, attacker_id, partial_emit)
        # Follow-through gate: skip strike execution when parry absorbed >=90% of energy (remaining <= 0.1). Tuning fix
        # T3.2.
        if remaining_ratio > 0.1:
            manager._execute_attack(attacker_id)
        return
    if action == "hit":
        CombatFlurryBind.clear_pair(manager, attacker_id, target_id)
        var ft_extras: Dictionary = _tuning_follow_through_extras(atk)
        # Evaluate counter-read outcome before clearing stale fields.
        if not atk.is_empty():
            _evaluate_counter_read_outcome(manager, attacker_id, target_id, atk.get(DataKeys.PA_DEFENDER_FORM_AT_PARRY, ""))
        # Follow-through after **`parry_partial`**: strip calibration carry so **`attack_hit`** recovery does not see
        # stale clash dict.
        if not atk.is_empty():
            atk.erase(DataKeys.PA_PARRY_CLASH_CONTEXT)
            atk.erase(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY)
            atk.erase(DataKeys.PA_DEFENDER_FORM_AT_PARRY)
            CombatAIActionPicker.clear_feint_listing_opp_parry_deflect_for_target(atk, target_id)
        if not tgt.is_empty():
            CombatAttention.clear_yomi_for_attacker(tgt, attacker_id)
        if not tgt.is_empty() and CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_MEDICAL_WIND_UP:
            CombatStateHandlers.abort_medical_wind_up(manager, target_id)
        var rd_raw: Variant = result.get(DataKeys.RESULT_RESULT_DICT, null)
        var result_dict: Dictionary = rd_raw if rd_raw is Dictionary else {}
        var intensity: float = result.get(DataKeys.ATTACK_INTENSITY, 0.5)
        # Harness diagnostic: log every hit outcome so we can trace damage accumulation vs lethality.
        if manager != null and manager.has_meta("_fp_harness_diag") and bool(manager.get_meta("_fp_harness_diag")):
            var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
            var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id) if not tgt.is_empty() else "?"
            var died_flag: bool = result_dict.get(CombatConstants.RESULT_KEY_DIED, false)
            var final_cut: float = result_dict.get("final_cut", 0.0)
            var final_blunt: float = result_dict.get("final_blunt", 0.0)
            var dmg: int = result_dict.get("dmg", 0)
            var part: String = result_dict.get("part", "")
            CombatDebug.harness_diag(
                "hit_resolve atk=%s tgt=%s id=%d->%d part=%s cut=%.1f blunt=%.1f dmg=%d died=%s"
                % [atk_name, tgt_name, attacker_id, target_id, part, final_cut, final_blunt, dmg, str(died_flag)]
            )
        var winner: String = ""
        if result_dict.get(CombatConstants.RESULT_KEY_DIED, false):
            _abort_incoming_wind_up_if_target_died(manager, target_id)
            CombatF5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
            _enrich_payload_for_tuning(
                manager,
                result_dict,
                atk,
                tgt,
                {},
                _hit_tuning_extras(atk, intensity, float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0)), ft_extras)
            )
            _clear_tuning_follow_through_marker(atk)
            manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
            # XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
            notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
            winner = manager._check_for_winner()
            if not winner.is_empty():
                manager._end_combat_phase(winner, tgt_scene)
            # Attacker still needs recovery (killing blow); otherwise they stay in WIND_UP and never get another turn.
            if atk != null and CombatantEntityAccess.alive_bool(atk):
                _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
                atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
                atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_hit"
                atk.state = CombatConstants.STATE_RECOVERING
                atk.state_timer = 0.0
                atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
                _set_post_strike_stamp(manager, atk, attacker_id, target_id)
            return
        winner = manager._check_for_winner()
        if not winner.is_empty():
            if tgt != null and CombatantEntityAccess.is_incapacitated(tgt):
                var reason: String = "consciousness < 10%%"
                if CombatantEntityAccess.is_cowering(tgt):
                    reason = "cowering (no functional arms)"
                var suppress_log = (
                    OperationalLog.is_play_session_active() and CombatConstants.combat_hit_summary_active()
                )
                if not suppress_log:
                    CombatDebug.combat_session(
                        "INCAPACITATED %s (%s)" % [CombatantEntityAccess.get_display_name(tgt, target_id), reason]
                    )
            CombatF5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
            _enrich_payload_for_tuning(
                manager,
                result_dict,
                atk,
                tgt,
                {},
                _hit_tuning_extras(atk, intensity, float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0)), ft_extras)
            )
            _clear_tuning_follow_through_marker(atk)
            manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
            # XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
            notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
            # Attacker still needs recovery; otherwise they stay in WIND_UP
            if atk != null and CombatantEntityAccess.alive_bool(atk):
                _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
                atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
                atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_hit"
                atk.state = CombatConstants.STATE_RECOVERING
                atk.state_timer = 0.0
                atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
                _set_post_strike_stamp(manager, atk, attacker_id, target_id)
            manager._end_combat_phase(winner, tgt_scene)
            return
        if not MedicalPhaseController.combat_resolution_blocked(manager):
            AfterblowHandler.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)
        # last_move_id set in AttackResolver before clearing pending_attack
        _log_outcome("hit", attacker_id, target_id)
        CombatF5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
        _enrich_payload_for_tuning(
            manager,
            result_dict,
            atk,
            tgt,
            {},
            _hit_tuning_extras(atk, intensity, float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0)), ft_extras)
        )
        _clear_tuning_follow_through_marker(atk)
        manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
        # XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
        if atk != null and CombatantEntityAccess.alive_bool(atk):
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")  # Set in AttackResolver before clear
            atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_hit"
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
            _set_post_strike_stamp(manager, atk, attacker_id, target_id)
        if tgt != null and CombatantEntityAccess.alive_bool(tgt):
            # Defender was hit; stagger/dropped guard - blade ends low. Sync guard_zone.
            GuardLineUpdater.set_guard_from_line(tgt, "low")
            CombatantEntityAccess.manager_apply_formation_hit_reaction_if_needed(manager, target_id, intensity)
        ## Phase 3: track guard break on hit (defense fully failed).
        if not atk.is_empty():
            MentalStackDecider._reset_guard_breaks(atk)
        if not tgt.is_empty():
            MentalStackDecider._record_guard_break(tgt)
        _react_attacking_arm_loss_after_wound(manager, atk)
        _react_attacking_arm_loss_after_wound(manager, tgt)
        _clear_defender_footwork(tgt)
        return


## WF-2a: tally resolved move id (+ feint withdrawal) on defender yomi without duplicating wind-up line counts.
static func _record_resolved_exchange_yomi(
    defender: Dictionary, attacker_id: int, pa: Dictionary, count_feint_if_feint: bool
) -> void:
    if defender.is_empty() or pa.is_empty() or attacker_id < 0:
        return
    var move_id: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
    if not move_id.is_empty():
        CombatAttention.record_resolved_strike_toward_defender(defender, attacker_id, move_id)
    if count_feint_if_feint and not move_id.is_empty():
        var md: Dictionary = WeaponConstants.get_move(move_id)
        if md.get(CombatConstants.MOVE_DEF_KEY_IS_FEINT, false) or WeaponConstants.is_feint_move(move_id):
            CombatAttention.record_feint_resolved_toward_defender(defender, attacker_id)


## MS-L8: stamp the attacker's dict with the combat clock so MS-L8 post-strike momentum fires next turn.
static func _set_post_strike_stamp(
    manager: Node, atk: Dictionary, attacker_id: int, struck_target_id: int = -1
) -> void:
    if not CombatConstants.is_feature_ms_post_strike_enabled():
        return
    if atk.is_empty() or manager == null:
        return
    var atk_read: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if not atk_read.is_empty():
        atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = manager.combat_clock
        if struck_target_id >= 0:
            atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = struck_target_id


## XCamp-4: award proficiency stat gains from a resolved attack action.
## Called after each action outcome (miss, dodge, hit, parry) in apply_result.
static func notify_proficiency_gains_from_resolve(
    manager: Node, attacker_id: int, target_id: int, action: String, result_dict: Dictionary
) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
    if atk.is_empty():
        return

    var weapon_id: String = CombatantEntityAccess.weapon_type_id(atk)
    var form_str: String = CombatantEntityAccess.form_str(atk)

    var attacker_entity: Node = CombatantEntityAccess.scene_node(atk)
    var target_entity: Node = CombatantEntityAccess.scene_node(tgt) if not tgt.is_empty() else null

    match action:
        "miss":
            # Wind-up completed - counts as strike attempted for both STR and AGI.
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                EntityProficiency.award_stat_gain(
                    attacker_entity, "strength", EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE, weapon_id, form_str
                )
                EntityProficiency.award_stat_gain(
                    attacker_entity, "agility", EntityProficiency.GAIN_WINDUP_COMPLETED_AGI_BASE, weapon_id, form_str
                )

        "dodge":
            # Defender dodged - AGI gain for defender. Attacker gets STR wind-up gain.
            if tgt.is_empty() or target_entity == null:
                if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                    EntityProficiency.award_stat_gain(
                        attacker_entity, "strength", EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE, weapon_id, form_str
                    )
                return
            var outnumbered := _is_defender_outnumbered(manager, tgt)
            var dodge_gain := EntityProficiency.GAIN_DODGE_EVADED_BASE
            if outnumbered:
                dodge_gain += EntityProficiency.GAIN_DODGE_OUTNUMBERED_BONUS
            EntityProficiency.award_stat_gain(target_entity, "agility", dodge_gain)
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                EntityProficiency.award_stat_gain(
                    attacker_entity, "strength", EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE, weapon_id, form_str
                )

        "hit":
            # Attacker hit - STR gain scaled by damage dealt.
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                var dmg: float = result_dict.get(DataKeys.RESULT_DMG, 0)
                var str_gain := (
                    EntityProficiency.GAIN_MELEE_HIT_BASE
                    + minf(
                        dmg / EntityProficiency.GAIN_HIT_STR_DAMAGE_DIVIDER,
                        EntityProficiency.GAIN_MELEE_HIT_MAX_DMG_CONTRIB
                    )
                )
                EntityProficiency.award_stat_gain(attacker_entity, "strength", str_gain, weapon_id, form_str)

                # Severe wound bonus (severity from result_dict).
                var wound_severity: String = result_dict.get(DataKeys.RESULT_WOUND_SEVERITY, "")
                if not wound_severity.is_empty():
                    var sev_mult: float = EntityProficiency.get_severity_mult(wound_severity)
                    EntityProficiency.award_stat_gain(
                        attacker_entity,
                        "strength",
                        EntityProficiency.GAIN_SEVERE_WOUND_BASE * sev_mult,
                        weapon_id,
                        form_str
                    )

                var move_id_hit: String = str(result_dict.get(DataKeys.ACTION_MOVE_ID, result_dict.get(DataKeys.ATTACK_ATTACK_TYPE, "")))
                var move_def_hit: Dictionary = (
                    WeaponConstants.get_move(move_id_hit) if not move_id_hit.is_empty() else {}
                )
                var hit_part: String = str(result_dict.get(DataKeys.RESULT_PART, ""))
                var intended_part: String = str(result_dict.get(DataKeys.ACTION_TARGET_PART, result_dict.get(DataKeys.AIM_PART_OVERRIDE, "")))
                var focus_part: String = ""
                if not tgt.is_empty():
                    focus_part = CombatAttention.get_focus_part(tgt)
                EntityProficiency.notify_targeting_gains_from_hit(
                    attacker_entity, weapon_id, form_str, move_def_hit, hit_part, intended_part, focus_part
                )

            # Defender END gain for absorbing damage.
            if target_entity != null and "_proficiency_bonus" in target_entity:
                var dmg_taken: float = result_dict.get(DataKeys.RESULT_DMG, 0)
                var end_gain := (
                    EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE
                    + minf(
                        dmg_taken / EntityProficiency.GAIN_END_DMG_TAKEN_DIVIDER,
                        EntityProficiency.GAIN_DAMAGE_ABSORBED_MAX_CONTRIB
                    )
                )
                EntityProficiency.award_stat_gain(target_entity, "endurance", end_gain)

        "parry_deflect":
            # Both attacker and defender get wind-up completion gains.
            # Defender also gets END gain for successfully blocking (absorbing parry recoil).
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                EntityProficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT,
                    weapon_id,
                    form_str
                )
            if not tgt.is_empty() and target_entity != null and "_proficiency_bonus" in target_entity:
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "strength",
                    EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT
                )
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "endurance",
                    EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT
                )

        "parry_partial":
            # Attacker gets partial STR gain; defender gets no gain (parry absorbed).
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                EntityProficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * EntityProficiency.GAIN_PARRY_PARTIAL_STR_MULT,
                    weapon_id,
                    form_str
                )

        "defeated":
            # No proficiency gains on defeated action.
            pass

        _:
            # skip - no gains
            pass


## Phase 2: evaluate whether a counter-read switch was correct by comparing the defender's actual form at action start against their inferred form.
static func _evaluate_counter_read_outcome(
    manager: Node, attacker_id: int, target_id: int, defender_form_at_parry: String
) -> void:
    if manager == null or attacker_id < 0 or target_id < 0:
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty():
        return
    ## Check if the attacker had a counter-read commitment stamp — this means they auto-switched based on inference.
    if not CombatWeaponForm.is_counter_read_committed(atk, manager.combat_clock):
        return
    ## The defender's actual form at action start was captured and stored on the attacker.
    ## If the attacker switched to a counter-form expecting that form but got something else, record wrong.
    var inferred_key: String = CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID
    var cache_raw: Variant = atk.get(inferred_key, null)
    if cache_raw is not Dictionary:
        return
    var cached_val: Variant = (cache_raw as Dictionary).get(str(target_id), "")
    if cached_val is String and not str(cached_val).is_empty():
        var inferred_form: String = str(cached_val).strip_edges()
        var success: bool = defender_form_at_parry.strip_edges() == inferred_form
        CombatWeaponForm.record_counter_read_outcome(atk, target_id, success, inferred_form)
        CombatAttention.record_deception_outcome(atk, target_id, success)


## Checks if the defender combatant is the last alive in their slot group (outnumbered).
static func _is_defender_outnumbered(manager: Node, defender: Dictionary) -> bool:
    var slot_key: String = defender.get(DataKeys.COMBATANT_SLOT_KEY, "")
    if slot_key.is_empty():
        return false
    var slot_group: String = slot_key.get_slice("_", 0) if "_" in slot_key else ""
    if slot_group.is_empty():
        return false
    var defender_side := CombatantEntityAccess.side_str(defender)
    var count_alive_in_group: int = 0
    if not manager.has_method("get_combatants"):
        return false
    for c in manager.get_combatants():
        if not c is Dictionary:
            continue
        if not CombatantEntityAccess.side_str(c) == defender_side:
            continue
        var c_slot: String = c.get(DataKeys.COMBATANT_SLOT_KEY, "").get_slice("_", 1)
        if c_slot != slot_group:
            continue
        if not CombatantEntityAccess.alive_bool(c):
            continue
        count_alive_in_group += 1
    return count_alive_in_group <= 1



