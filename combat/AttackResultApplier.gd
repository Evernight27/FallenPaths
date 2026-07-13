class_name AttackResultApplier
extends RefCounted

## Applies AttackResolver result to combatant state: skip, defeated, miss, dodge, parry_deflect, parry_partial, hit.
## Footing: **`GuardLineUpdater`** on hit stagger (**`low`**), dodge guard, move finish - L3 drift; **`CombatFootwork.clear_on_exchange_end`** on exchange end. LIVE_PATHS **`#wf-guard-writers`** - **`#wf-tier-44-pa`** (clear).
## **`parry_deflect`**: records **`CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`** on **`attacker`** for Tier **4.2** feint listing pressure vs **`target_id`**; **`action_resolved`** emits **`target_id`**, **`attacker_id`**, then payload ( **`parry_clash_context`** copied when resolver supplied a dict - **`BattleScene`** parameter names follow slot order).
## **`parry_partial`**: **`action_resolved`** emits **`target_id`**, **`attacker_id`**, then payload (**defender**, **attacker**, same slot order as **`parry_deflect`**); then **`_execute_attack`** continues the strike. Resolver **`parry_clash_context`** is copied onto the **attacker** dict and onto the emitted payload when present. When the defender meets the same blade-alignment gate used for guard updates and clash **`parry_control`** crosses the bind threshold (**`PARRY_BIND_CONTROL_THRESHOLD`**), set **`parry_was_bind`**, **`parry_against_id`**, **`parry_bonus_until`** on the defender like **`parry_deflect`** so bind-riposte wind-up can apply; aligned but sub-threshold control sets **`parry_was_bind`** false; misaligned partial **`erase`**s those keys (clears stale bind state).
## Manager must have: emit_signal, _get_by_id, _check_for_winner, _end_combat_phase, _execute_attack.
## **`hit`**: clears **`parry_clash_context`** / **`defender_guard_line_at_parry`** on the attacker (stale partial-parry calibration after follow-through); clears Tier **4.2** feint listing parry-deflect memory for **`target_id`**.

const _Afterblow := preload("res://combat/AfterblowHandler.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _GuardUpdater := preload("res://combat/GuardLineUpdater.gd")
const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _LogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _Proficiency := preload("res://core/EntityProficiency.gd")
const _CompanyState := preload("res://world/CompanyState.gd")


static func _log_outcome(action: String, atk_id: int, tgt_id: int) -> void:
    if CombatConstants.combat_debug_active():
        CombatDebug.log("%s atk=%d tgt=%d" % [action, atk_id, tgt_id])


## F5 soak (**II-2b**): grep `parry_deflect` / `parry_bind` / `parry_partial` without **`COMBAT_DEBUG`**.
static func _log_fp_parry_outcome(
    atk: Dictionary, tgt: Dictionary, atk_id: int, tgt_id: int, outcome: String, clash: Dictionary
) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var atk_n: String = _EntityAccess.get_display_name(atk, atk_id)
    var tgt_n: String = _EntityAccess.get_display_name(tgt, tgt_id)
    var ctrl: float = clash.get("parry_control", 0.0)
    var reason: String = _LogFormatter.damage_resolve_note({"outcome": outcome})
    var interpose_suffix: String = ""
    var interpose_boost: float = clash.get("arm_interpose_boost", 0.0)
    if interpose_boost > 0.0:
        interpose_suffix = (
            " arm_interpose_arm=%s arm_interpose_boost=%.3f"
            % [
                clash.get("arm_interpose_arm", ""),
                interpose_boost,
            ]
        )
    if outcome == "parry_deflect":
        var tag: String = "parry_bind" if tgt.get("parry_was_bind", false) else "parry_deflect"
        CombatDebug.combat_session(
            "%s %s vs %s ctrl=%.3f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, reason, interpose_suffix]
        )
    elif outcome == "parry_partial":
        var rem: float = 0.0
        if clash.has("remaining_ratio"):
            rem = float(clash["remaining_ratio"])
        var bind: bool = tgt.get("parry_was_bind", false)
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
    var s: float = _EntityAccess.stamina_float(c)
    c["stamina"] = maxf(0.0, s - amount)
    _Exhaustion.apply_exertion_from_stamina_spend(manager, c, amount)


static func _stamina_parry_cost_for_defender(atk: Dictionary, incoming_intensity: float = -1.0) -> float:
    var i: float = incoming_intensity
    if i < 0.0:
        i = 0.5
        if not atk.is_empty():
            i = _pending_attack_read(atk).get("intensity", 0.5)
    return CombatConstants.stamina_parry_cost_from_intensity(i)


static func _stamina_attack_cost_for_attacker(manager: Node, atk: Dictionary, target_id: int) -> float:
    if atk.is_empty():
        return CombatConstants.stamina_attack_cost_from_intensity(1.0)
    var cost: float = CombatConstants.stamina_attack_cost_from_intensity(
        _pending_attack_read(atk).get("intensity", 1.0)
    )
    if manager != null and target_id >= 0:
        var clk: float = _EntityAccess.combat_clock_float(manager)
        cost *= _FlurryBind.stamina_attack_cost_mult(atk, target_id, clk)
    return cost


static func _pending_attack_read(atk: Dictionary) -> Dictionary:
    return _EntityAccess.nested_dictionary_read(atk, "pending_attack")


static func _tuning_follow_through_extras(atk: Dictionary) -> Dictionary:
    if atk.is_empty() or not atk.has("tuning_ft_parent_strike"):
        return {}
    return {
        "parent_exchange_index": int(atk["tuning_ft_parent_strike"]),
        "note": "follow_through_from_parry",
    }


static func _clear_tuning_follow_through_marker(atk: Dictionary) -> void:
    if not atk.is_empty():
        atk.erase("tuning_ft_parent_strike")


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
        "move_id": atk.get("last_move_id", "") if not atk.is_empty() else "",
        "attack_line": atk.get("effective_attack_line", "") if not atk.is_empty() else "",
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
        payload["move_id"] = str(pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, ""))
        payload["intensity"] = float(pa.get("intensity", 0.0))
        payload["power"] = float(pa.get("power", 0.0))
        payload["follow_through"] = float(pa.get("follow_through", 0.0))
        payload["wind_up_s"] = float(pa.get("wind_up_duration", 0.0))
        payload["attack_line"] = str(pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""))
        if pa.has("gauge_atk_pre"):
            payload["gauge_atk_pre"] = float(pa["gauge_atk_pre"])
            payload["gauge_def_pre"] = float(pa.get("gauge_def_pre", -1.0))
    if not atk.is_empty():
        if str(payload.get("move_id", "")).is_empty():
            payload["move_id"] = str(atk.get("last_move_id", ""))
        payload["atk_guard"] = str(atk.get("guard_line", ""))
        payload["atk_form"] = str(atk.get("weapon_form", atk.get("_form_str", "")))
        if _EntityAccess.has_weapon(atk):
            var w = _EntityAccess.get_weapon(atk)
            if w is Dictionary:
                payload["weapon_id"] = str((w as Dictionary).get("id", ""))
            elif w != null and w.get("id") != null:
                payload["weapon_id"] = str(w.id)
    if not tgt.is_empty():
        payload["def_guard"] = str(tgt.get("guard_line", ""))
    for k in extras:
        payload[k] = extras[k]
    if str(payload.get("kinematic_delivery", "")).is_empty() and not pa.is_empty():
        var arch: Variant = pa.get("archetype", null)
        if arch is Dictionary:
            var arch_delivery: String = str((arch as Dictionary).get("kinematic_delivery", ""))
            if not arch_delivery.is_empty():
                payload["kinematic_delivery"] = arch_delivery
    var outcome: String = str(payload.get("outcome", ""))
    if outcome in ["parry_deflect", "parry_partial"]:
        var clash: Variant = payload.get("parry_clash_context", null)
        if clash is Dictionary:
            payload["parry_bind"] = bool(tgt.get("parry_was_bind", false)) if not tgt.is_empty() else false
            payload["parry_control"] = float((clash as Dictionary).get(CombatConstants.CLASH_KEY_PARRY_CONTROL, 0.0))
            if (clash as Dictionary).has("remaining_ratio"):
                payload["follow_through_rem"] = float((clash as Dictionary)["remaining_ratio"])
            var delivery: String = str((clash as Dictionary).get("kinematic_delivery", ""))
            if not delivery.is_empty():
                payload["kinematic_delivery"] = delivery


static func _clear_attacker_pending_attack(atk: Dictionary, manager: Node) -> void:
    if atk.is_empty():
        return
    var pa0: Dictionary = _pending_attack_read(atk)
    _WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa0)
    _Footwork.clear_on_exchange_end(atk)
    atk.pending_attack = {}


static func _react_attacking_arm_loss_after_wound(manager: Node, c: Variant) -> void:
    if manager == null or c == null or not (c is Dictionary):
        return
    var cd: Dictionary = c as Dictionary
    if cd.is_empty():
        return
    _EntityAccess.react_attacking_arm_lost_if_needed(manager, cd)


static func _clear_defender_footwork(tgt: Dictionary) -> void:
    if not tgt.is_empty():
        _Footwork.clear_on_exchange_end(tgt)


static func _abort_incoming_wind_up_if_target_died(manager: Node, target_id: int) -> void:
    if manager == null or target_id < 0:
        return
    var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
    if tgt.is_empty() or _EntityAccess.alive_bool(tgt):
        return
    _CounterTempo.abort_attacker_wind_up(manager, target_id)


## Parry outcomes default the defender to waiting. Paired formation moves (`swap_rank` / drag / fall_back_pair)
## keep both partners in motion state until resolve - do not clobber that here.
static func _defender_set_idle_after_parry(tgt: Dictionary) -> void:
    if tgt.is_empty():
        return
    if (
        _EntityAccess.state_str(tgt)
        in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]
    ):
        return
    _clear_defender_footwork(tgt)
    _Footwork.return_to_waiting(tgt)
    tgt.state_timer = 0.0
    tgt.state_duration = 0.0


static func apply_result(manager: Node, attacker_id: int, result: Dictionary) -> void:
    var action: String = result.get("action", "skip")
    var target_id: int = result.get("target_id", -1)
    var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
    if _MedicalPhase.combat_resolution_blocked(manager):
        return
    var tgt: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, target_id)
    var tgt_scene: Node = _EntityAccess.scene_node(tgt)
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
            if result.get("recovery_duration", 0.0) > 0.0:
                empty_result["outcome"] = "skip"
                manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
                var pa_skip: Dictionary = _pending_attack_read(atk)
                atk["last_move_id"] = pa_skip.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
                atk["effective_attack_line"] = pa_skip.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
                atk["recovery_cause"] = "skip"
                _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
                atk.state = CombatConstants.STATE_RECOVERING
                atk.state_timer = 0.0
                atk.state_duration = result.recovery_duration
                _clear_attacker_pending_attack(atk, manager)
                _react_attacking_arm_loss_after_wound(manager, atk)
            else:
                _Footwork.return_to_waiting(atk)
                atk.gauge = 0.0
                _clear_attacker_pending_attack(atk, manager)
                _react_attacking_arm_loss_after_wound(manager, atk)
        return
    if action == "defeated":
        if not tgt.is_empty():
            tgt.alive = false
            _Footwork.clear_on_death(tgt)
            tgt.state = CombatConstants.STATE_DEAD
            _StateHandlers.cancel_events_for_dead_combatant(manager, tgt)
        if not atk.is_empty():
            # Resolver abort (e.g. no targetable parts): do not leave attacker stuck in WIND_UP with stale `pending_attack`.
            _clear_attacker_pending_attack(atk, manager)
            _Footwork.return_to_waiting(atk)
            atk.gauge = 0.0
            atk.state_timer = 0.0
            atk.state_duration = 0.0
        empty_result["outcome"] = "defeated"
        empty_result["died"] = true
        _abort_incoming_wind_up_if_target_died(manager, target_id)
        manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
        var winner: String = manager._check_for_winner()
        if not winner.is_empty():
            manager._end_combat_phase(winner, tgt_scene)
        return
    if action == "miss":
        empty_result["outcome"] = "miss"
        _log_outcome("miss", attacker_id, target_id)
        var pa_miss_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
        if not tgt.is_empty() and not pa_miss_log.is_empty():
            _record_resolved_exchange_yomi(tgt, attacker_id, pa_miss_log, true)
        var miss_part: String = pa_miss_log.get("target_part", "")
        if not miss_part.is_empty():
            empty_result["part"] = miss_part
        _F5SoakTrace.note_strike_avoided(attacker_id, target_id, atk, tgt, "miss", miss_part)
        _enrich_payload_for_tuning(
            manager, empty_result, atk, tgt, pa_miss_log, {"recovery_s": float(result.get("recovery_duration", 0.0))}
        )
        manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
        # XCamp-4: proficiency gains on miss (wind-up completion).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "miss", empty_result)
        if not atk.is_empty():
            var pa_miss: Dictionary = _pending_attack_read(atk)
            atk["last_move_id"] = pa_miss.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            atk["effective_attack_line"] = pa_miss.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
            atk["recovery_cause"] = "attack_miss"
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.recovery_duration
            atk["off_balance_until"] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
            _clear_attacker_pending_attack(atk, manager)
        _clear_defender_footwork(tgt)
        return
    if action == "dodge":
        empty_result["outcome"] = "dodge"
        _log_outcome("dodge", attacker_id, target_id)
        var pa_dodge_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
        if not tgt.is_empty() and not pa_dodge_log.is_empty():
            _record_resolved_exchange_yomi(tgt, attacker_id, pa_dodge_log, true)
        var dodge_part: String = str(pa_dodge_log.get("partial_dodge_part", pa_dodge_log.get("target_part", "")))
        if not dodge_part.is_empty():
            empty_result["part"] = dodge_part
        _F5SoakTrace.note_strike_avoided(attacker_id, target_id, atk, tgt, "dodge", dodge_part)
        _enrich_payload_for_tuning(
            manager, empty_result, atk, tgt, pa_dodge_log, {"recovery_s": float(result.get("recovery_duration", 0.0))}
        )
        manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
        # XCamp-4: proficiency gains on dodge (AGI for defender, STR wind-up for attacker).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "dodge", empty_result)
        if not atk.is_empty():
            var pa_dodge_atk: Dictionary = _pending_attack_read(atk)
            atk["last_move_id"] = pa_dodge_atk.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            atk["effective_attack_line"] = pa_dodge_atk.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
            atk["recovery_cause"] = "attack_miss"
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.recovery_duration
        if not tgt.is_empty():
            # Defender moved to avoid; blade/body ends in dodge position (e.g. duck high attack -> low guard).
            # Use effective_attack_line for diagonal moves (actual trajectory).
            var pa: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
            var move_id: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            var move_def: Dictionary = WeaponConstants.get_move(move_id) if not move_id.is_empty() else {}
            var atk_line: String = pa.get(
                CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, move_def.get("attack_line", "high")
            )
            var dodge_guard: String = CombatConstants.DODGE_END_GUARD_FROM_ATTACK.get(
                atk_line, tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
            )
            _GuardUpdater.set_guard_from_line(tgt, dodge_guard)
            if CombatConstants.combat_debug_active():
                CombatDebug.log(
                    "guard_line %s: -> %s (dodged %s)" % ["id:%d" % _EntityAccess.id_int(tgt), dodge_guard, atk_line]
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
            atk["last_move_id"] = pa_deflect.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            atk["effective_attack_line"] = pa_deflect.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
            # HEMA: store defender's guard and parry_clash_context for bind vs deflect.
            atk["defender_guard_line_at_parry"] = (
                tgt.get("guard_line", CombatConstants.GUARD_DEFAULT) if not tgt.is_empty() else ""
            )
            var atk_clash_raw: Variant = result.get("parry_clash_context", null)
            atk["parry_clash_context"] = atk_clash_raw if atk_clash_raw is Dictionary else {}
            _clear_attacker_pending_attack(atk, manager)
            atk["recovery_cause"] = "attack_deflect"
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.recovery_duration
            atk["off_balance_until"] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
        if not tgt.is_empty():
            _consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_parry_intensity))
            # Weapon position: defender's blade met attacker's; blade ends in attack line.
            # Use effective_attack_line for diagonal moves (actual contact line).
            var move_id: String = atk.get("last_move_id", "") if not atk.is_empty() else ""
            var eff_line: String = atk.get("effective_attack_line", "") if not atk.is_empty() else ""
            _GuardUpdater.set_guard_from_move(tgt, move_id, eff_line)
            tgt["parry_bonus_until"] = CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
            if not _MobilityRetreat.cannot_commit_melee(tgt):
                _CounterTempo.grant_riposte_chain(manager, tgt, attacker_id)
                var clash_raw: Variant = result.get("parry_clash_context", null)
                var clash: Dictionary = clash_raw if clash_raw is Dictionary else {}
                var arch_id: String = clash.get("archetype_id", "")
                var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
                tgt["parry_was_bind"] = (
                    can_bind
                    and CombatConstants.parry_bind_control_reached(
                        float(clash.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL))
                    )
                )
                tgt["parry_against_id"] = attacker_id
                if tgt.get("parry_was_bind", false):
                    CombatConstants.apply_parry_bind_riposte_gauge_bonus(tgt)
                    _FlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
            else:
                tgt.erase("parry_was_bind")
                tgt.erase("parry_against_id")
                _CounterTempo.clear_riposte_chain(tgt)
            _defender_set_idle_after_parry(tgt)
        empty_result["outcome"] = "parry_deflect"
        var clash_emit: Variant = result.get("parry_clash_context", null)
        if clash_emit is Dictionary:
            empty_result["parry_clash_context"] = clash_emit
        _log_outcome("parry_deflect", attacker_id, target_id)
        var clash_log: Dictionary = (
            result.get("parry_clash_context", {}) if result.get("parry_clash_context") is Dictionary else {}
        )
        _log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_deflect", clash_log)
        # XCamp-4: proficiency gains on parry_deflect (partial STR for both).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "parry_deflect", empty_result)
        if not atk.is_empty():
            _AIPicker.record_opp_parry_deflect_for_feint_listing(manager, atk, target_id)
        if not tgt.is_empty():
            _Attention.record_parry_deflect_on_attacker_memory(tgt, attacker_id)
        _enrich_payload_for_tuning(manager, empty_result, atk, tgt, pa_deflect)
        manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)
        return
    if action == "parry_partial":
        var incoming_partial_intensity: float = 0.5
        var pa_partial_emit: Dictionary = {}
        if not atk.is_empty():
            var pa_partial_int: Dictionary = _pending_attack_read(atk)
            pa_partial_emit = pa_partial_int
            incoming_partial_intensity = pa_partial_int.get("intensity", 0.5)
            var partial_clash_raw: Variant = result.get("parry_clash_context", null)
            atk["parry_clash_context"] = partial_clash_raw if partial_clash_raw is Dictionary else {}
            atk["defender_guard_line_at_parry"] = (
                tgt.get("guard_line", CombatConstants.GUARD_DEFAULT) if not tgt.is_empty() else ""
            )
        if not tgt.is_empty():
            _consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_partial_intensity))
            var pa_partial: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
            if not pa_partial.is_empty():
                _record_resolved_exchange_yomi(tgt, attacker_id, pa_partial, true)
            var move_id: String = pa_partial.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
            var move_def: Dictionary = WeaponConstants.get_move(move_id)
            var atk_line: String = pa_partial.get(
                CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, move_def.get("attack_line", "high")
            )
            var align_ctx: Dictionary = {}
            if pa_partial.get("attack_angle_deg", -999.0) >= 0.0:
                var read: float = _PassiveParry.get_passive_parry_readiness(tgt)
                var def_w = _EntityAccess.get_weapon(tgt)
                var wob: Dictionary = _EntityAccess.parry_wobble_context(def_w, read)
                align_ctx = {
                    "attack_angle_deg": pa_partial["attack_angle_deg"],
                    "guard_angle_deg": _Footwork.guard_angle_deg(tgt, wob),
                }
            var align: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
            if align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD:
                _GuardUpdater.set_guard_from_move(tgt, move_id, atk_line)
                var pcl_bind: Variant = result.get("parry_clash_context", null)
                var clash_bind: Dictionary = pcl_bind if pcl_bind is Dictionary else {}
                var arch_bind: String = clash_bind.get("archetype_id", "")
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
                tgt["parry_was_bind"] = is_bind
                if is_bind:
                    tgt["parry_against_id"] = attacker_id
                    tgt["parry_bonus_until"] = (
                        CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
                    )
                    _FlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
                else:
                    tgt.erase("parry_against_id")
                    tgt.erase("parry_bonus_until")
            else:
                tgt.erase("parry_was_bind")
                tgt.erase("parry_against_id")
                tgt.erase("parry_bonus_until")
            _defender_set_idle_after_parry(tgt)
        var partial_emit: Dictionary = {"outcome": "parry_partial", "dmg": 0, "died": false}
        var pcl_emit: Variant = result.get("parry_clash_context", null)
        if pcl_emit is Dictionary:
            partial_emit["parry_clash_context"] = pcl_emit
        _log_outcome("parry_partial", attacker_id, target_id)
        var clash_partial: Dictionary = pcl_emit if pcl_emit is Dictionary else {}
        _log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_partial", clash_partial)
        # XCamp-4: proficiency gains on parry_partial (small STR for attacker).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "parry_partial", partial_emit)
        _enrich_payload_for_tuning(manager, partial_emit, atk, tgt, pa_partial_emit)
        if _tuning_context_enabled(manager) and not atk.is_empty():
            var parent_idx: int = _tuning_parry_parent_strike_index(manager)
            if parent_idx > 0:
                atk["tuning_ft_parent_strike"] = parent_idx
        manager.emit_signal("action_resolved", target_id, attacker_id, partial_emit)
        var remaining_ratio: float = pa_partial_emit.get("parry_remaining_ratio", 1.0)
        # Follow-through gate: skip strike execution when parry absorbed >=90% of energy (remaining <= 0.1). Tuning fix T3.2.
        if remaining_ratio > 0.1:
            manager._execute_attack(attacker_id)
        return
    if action == "hit":
        _FlurryBind.clear_pair(manager, attacker_id, target_id)
        var ft_extras: Dictionary = _tuning_follow_through_extras(atk)
        # Follow-through after **`parry_partial`**: strip calibration carry so **`attack_hit`** recovery does not see stale clash dict.
        if not atk.is_empty():
            atk.erase("parry_clash_context")
            atk.erase("defender_guard_line_at_parry")
            _AIPicker.clear_feint_listing_opp_parry_deflect_for_target(atk, target_id)
        if not tgt.is_empty():
            _Attention.clear_yomi_for_attacker(tgt, attacker_id)
        if not tgt.is_empty() and _EntityAccess.state_str(tgt) == CombatConstants.STATE_MEDICAL_WIND_UP:
            _StateHandlers.abort_medical_wind_up(manager, target_id)
        var rd_raw: Variant = result.get("result_dict", null)
        var result_dict: Dictionary = rd_raw if rd_raw is Dictionary else {}
        var intensity: float = result.get("intensity", 0.5)
        var winner: String = ""
        if result_dict.get(CombatConstants.RESULT_KEY_DIED, false):
            _abort_incoming_wind_up_if_target_died(manager, target_id)
            _F5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
            _enrich_payload_for_tuning(
                manager,
                result_dict,
                atk,
                tgt,
                {},
                _hit_tuning_extras(atk, intensity, float(result.get("recovery_duration", 0.0)), ft_extras)
            )
            _clear_tuning_follow_through_marker(atk)
            manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
            # XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
            notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
            winner = manager._check_for_winner()
            if not winner.is_empty():
                manager._end_combat_phase(winner, tgt_scene)
            # Attacker still needs recovery (killing blow); otherwise they stay in WIND_UP and never get another turn.
            if atk != null and _EntityAccess.alive_bool(atk):
                _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
                atk["effective_attack_line"] = atk.get("effective_attack_line", "")
                atk["recovery_cause"] = "attack_hit"
                atk.state = CombatConstants.STATE_RECOVERING
                atk.state_timer = 0.0
                atk.state_duration = result.get("recovery_duration", 0.5)
                _set_post_strike_stamp(manager, atk, attacker_id, target_id)
            return
        winner = manager._check_for_winner()
        if not winner.is_empty():
            if tgt != null and _EntityAccess.is_incapacitated(tgt):
                var reason: String = "consciousness < 10%%"
                if _EntityAccess.is_cowering(tgt):
                    reason = "cowering (no functional arms)"
                var suppress_log = (
                    _OperationalLog.is_play_session_active() and CombatConstants.combat_hit_summary_active()
                )
                if not suppress_log:
                    CombatDebug.combat_session(
                        "INCAPACITATED %s (%s)" % [_EntityAccess.get_display_name(tgt, target_id), reason]
                    )
            _F5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
            _enrich_payload_for_tuning(
                manager,
                result_dict,
                atk,
                tgt,
                {},
                _hit_tuning_extras(atk, intensity, float(result.get("recovery_duration", 0.0)), ft_extras)
            )
            _clear_tuning_follow_through_marker(atk)
            manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
            # XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
            notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
            # Attacker still needs recovery; otherwise they stay in WIND_UP
            if atk != null and _EntityAccess.alive_bool(atk):
                _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
                atk["effective_attack_line"] = atk.get("effective_attack_line", "")
                atk["recovery_cause"] = "attack_hit"
                atk.state = CombatConstants.STATE_RECOVERING
                atk.state_timer = 0.0
                atk.state_duration = result.get("recovery_duration", 0.5)
                _set_post_strike_stamp(manager, atk, attacker_id, target_id)
            manager._end_combat_phase(winner, tgt_scene)
            return
        if not _MedicalPhase.combat_resolution_blocked(manager):
            _Afterblow.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)
        # last_move_id set in AttackResolver before clearing pending_attack
        _log_outcome("hit", attacker_id, target_id)
        _F5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
        _enrich_payload_for_tuning(
            manager,
            result_dict,
            atk,
            tgt,
            {},
            _hit_tuning_extras(atk, intensity, float(result.get("recovery_duration", 0.0)), ft_extras)
        )
        _clear_tuning_follow_through_marker(atk)
        manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
        # XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
        notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
        if atk != null and _EntityAccess.alive_bool(atk):
            _consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
            atk["effective_attack_line"] = atk.get("effective_attack_line", "")  # Set in AttackResolver before clear
            atk["recovery_cause"] = "attack_hit"
            atk.state = CombatConstants.STATE_RECOVERING
            atk.state_timer = 0.0
            atk.state_duration = result.recovery_duration
            _set_post_strike_stamp(manager, atk, attacker_id, target_id)
        if tgt != null and _EntityAccess.alive_bool(tgt):
            # Defender was hit; stagger/dropped guard - blade ends low. Sync guard_zone.
            _GuardUpdater.set_guard_from_line(tgt, "low")
            _EntityAccess.manager_apply_formation_hit_reaction_if_needed(manager, target_id, intensity)
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
        _Attention.record_resolved_strike_toward_defender(defender, attacker_id, move_id)
    if count_feint_if_feint and not move_id.is_empty():
        var md: Dictionary = WeaponConstants.get_move(move_id)
        if md.get(CombatConstants.MOVE_DEF_KEY_IS_FEINT, false) or WeaponConstants.is_feint_move(move_id):
            _Attention.record_feint_resolved_toward_defender(defender, attacker_id)


## MS-L8: stamp the attacker's dict with the combat clock so MS-L8 post-strike momentum fires next turn.
static func _set_post_strike_stamp(
    manager: Node, atk: Dictionary, attacker_id: int, struck_target_id: int = -1
) -> void:
    if not CombatConstants.is_feature_ms_post_strike_enabled():
        return
    if atk.is_empty() or manager == null:
        return
    var atk_read: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
    if not atk_read.is_empty():
        atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = manager.combat_clock
        if struck_target_id >= 0:
            atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = struck_target_id


## XCamp-4: award proficiency stat gains from a resolved attack action.
## Called after each action outcome (miss, dodge, hit, parry) in apply_result.
static func notify_proficiency_gains_from_resolve(
    manager: Node, attacker_id: int, target_id: int, action: String, result_dict: Dictionary
) -> void:
    if not _CompanyState.read_stub_proficiency_enabled():
        return

    var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, target_id)
    if atk.is_empty():
        return

    var weapon_id: String = _EntityAccess.weapon_type_id(atk)
    var form_str: String = _EntityAccess.form_str(atk)

    var attacker_entity: Node = _EntityAccess.scene_node(atk)
    var target_entity: Node = _EntityAccess.scene_node(tgt) if not tgt.is_empty() else null

    match action:
        "miss":
            # Wind-up completed - counts as strike attempted for both STR and AGI.
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                _Proficiency.award_stat_gain(
                    attacker_entity, "strength", _Proficiency.GAIN_STRIKE_ATTEMPTED_BASE, weapon_id, form_str
                )
                _Proficiency.award_stat_gain(
                    attacker_entity, "agility", _Proficiency.GAIN_WINDUP_COMPLETED_AGI_BASE, weapon_id, form_str
                )

        "dodge":
            # Defender dodged - AGI gain for defender. Attacker gets STR wind-up gain.
            if tgt.is_empty() or target_entity == null:
                if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                    _Proficiency.award_stat_gain(
                        attacker_entity, "strength", _Proficiency.GAIN_STRIKE_ATTEMPTED_BASE, weapon_id, form_str
                    )
                return
            var outnumbered := _is_defender_outnumbered(manager, tgt)
            var dodge_gain := _Proficiency.GAIN_DODGE_EVaded_BASE
            if outnumbered:
                dodge_gain += _Proficiency.GAIN_DODGE_OUTNUMBERED_BONUS
            _Proficiency.award_stat_gain(target_entity, "agility", dodge_gain)
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                _Proficiency.award_stat_gain(
                    attacker_entity, "strength", _Proficiency.GAIN_STRIKE_ATTEMPTED_BASE, weapon_id, form_str
                )

        "hit":
            # Attacker hit - STR gain scaled by damage dealt.
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                var dmg: float = result_dict.get("dmg", 0)
                var str_gain := (
                    _Proficiency.GAIN_MELEE_HIT_BASE
                    + minf(dmg / _Proficiency.GAIN_HIT_STR_DAMAGE_DIVIDER, _Proficiency.GAIN_MELEE_HIT_MAX_DMG_CONTRIB)
                )
                _Proficiency.award_stat_gain(attacker_entity, "strength", str_gain, weapon_id, form_str)

                # Severe wound bonus (severity from result_dict).
                var wound_severity: String = result_dict.get("wound_severity", "")
                if not wound_severity.is_empty():
                    var sev_mult: float = _Proficiency.get_severity_mult(wound_severity)
                    _Proficiency.award_stat_gain(
                        attacker_entity, "strength", _Proficiency.GAIN_SEVERE_WOUND_BASE * sev_mult, weapon_id, form_str
                    )

                var move_id_hit: String = str(result_dict.get("move_id", result_dict.get("attack_type", "")))
                var move_def_hit: Dictionary = (
                    WeaponConstants.get_move(move_id_hit) if not move_id_hit.is_empty() else {}
                )
                var hit_part: String = str(result_dict.get("part", ""))
                var intended_part: String = str(result_dict.get("target_part", result_dict.get("aim_part", "")))
                var focus_part: String = ""
                if not tgt.is_empty():
                    focus_part = _Attention.get_focus_part(tgt)
                _Proficiency.notify_targeting_gains_from_hit(
                    attacker_entity, weapon_id, form_str, move_def_hit, hit_part, intended_part, focus_part
                )

            # Defender END gain for absorbing damage.
            if target_entity != null and "_proficiency_bonus" in target_entity:
                var dmg_taken: float = result_dict.get("dmg", 0)
                var end_gain := (
                    _Proficiency.GAIN_DAMAGE_ABSORBED_BASE
                    + minf(
                        dmg_taken / _Proficiency.GAIN_END_DMG_TAKEN_DIVIDER,
                        _Proficiency.GAIN_DAMAGE_ABSORBED_MAX_CONTRIB
                    )
                )
                _Proficiency.award_stat_gain(target_entity, "endurance", end_gain)

        "parry_deflect":
            # Both attacker and defender get wind-up completion gains.
            # Defender also gets END gain for successfully blocking (absorbing parry recoil).
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                _Proficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    _Proficiency.GAIN_STRIKE_ATTEMPTED_BASE * _Proficiency.GAIN_PARRY_DEFLECT_STR_MULT,
                    weapon_id,
                    form_str
                )
            if not tgt.is_empty() and target_entity != null and "_proficiency_bonus" in target_entity:
                _Proficiency.award_stat_gain(
                    target_entity,
                    "strength",
                    _Proficiency.GAIN_STRIKE_ATTEMPTED_BASE * _Proficiency.GAIN_PARRY_DEFLECT_STR_MULT
                )
                _Proficiency.award_stat_gain(
                    target_entity,
                    "endurance",
                    _Proficiency.GAIN_DAMAGE_ABSORBED_BASE * _Proficiency.GAIN_PARRY_DEFLECT_END_MULT
                )

        "parry_partial":
            # Attacker gets partial STR gain; defender gets no gain (parry absorbed).
            if attacker_entity != null and "_proficiency_bonus" in attacker_entity:
                _Proficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    _Proficiency.GAIN_STRIKE_ATTEMPTED_BASE * _Proficiency.GAIN_PARRY_PARTIAL_STR_MULT,
                    weapon_id,
                    form_str
                )

        "defeated":
            # No proficiency gains on defeated action.
            pass

        _:
            # skip - no gains
            pass


## Checks if the defender combatant is the last alive in their slot group (outnumbered).
static func _is_defender_outnumbered(manager: Node, defender: Dictionary) -> bool:
    var slot_key: String = defender.get("slot_key", "")
    if slot_key.is_empty():
        return false
    var slot_group: String = slot_key.get_slice("_", 0) if "_" in slot_key else ""
    if slot_group.is_empty():
        return false
    var defender_side := _EntityAccess.side_str(defender)
    var count_alive_in_group: int = 0
    if not manager.has_method("get_combatants"):
        return false
    for c in manager.get_combatants():
        if not c is Dictionary:
            continue
        if not _EntityAccess.side_str(c) == defender_side:
            continue
        var c_slot: String = c.get("slot_key", "").get_slice("_", 1)
        if c_slot != slot_group:
            continue
        if not _EntityAccess.alive_bool(c):
            continue
        count_alive_in_group += 1
    return count_alive_in_group <= 1
