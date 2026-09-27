class_name CombatStateHandlers
extends RefCounted

## Per-state handlers for CombatManager _process loop.
## Footing: parry/deflect → **`GuardLineUpdater.set_guard_deflected`**. recovery →
## **`set_guard_from_move`** '. **`CombatFootwork.clear_on_exchange_end`** '. idle **`reconcile_idle_offset`** on tick
## paths '. **`return_to_waiting`** / **`return_to_cowering`** on state transitions. LIVE_PATHS **`#wf-guard-writers`**
## '. **`#wf-tier-44-pa`**.
## Each handler mutates combatant (c) and may call manager methods.
## Manager must have: get_available_actions, resolve_action, emit_signal, _get_by_id,
## _execute_attack.

# Runtime preload ' circular dependency (CombatMobilityRetreat preloads CombatStateHandlers).
static var _mobility_retreat_cache: Variant = null
static var _muscle_fatigue_cache: Variant = null


static func _get_mobility_retreat() -> GDScript:
    if _mobility_retreat_cache == null:
        _mobility_retreat_cache = load("res://combat/formation/CombatMobilityRetreat.gd")
    return _mobility_retreat_cache


# Runtime load ' CombatMuscleFatigue may be unavailable during early bootstrap.


static func _get_muscle_fatigue() -> GDScript:
    if _muscle_fatigue_cache == null:
        _muscle_fatigue_cache = load("res://combat/flow/CombatMuscleFatigue.gd")
    return _muscle_fatigue_cache


## Drop queued turns for this combatant once they are dead (bleed-out or fatal wound).
static func cancel_events_for_dead_combatant(manager: Node, c: Dictionary) -> void:
    if manager == null or c.is_empty():
        return
    CombatEventScheduler.cancel_pending_combat_events_for_combatant(manager, CombatantEntityAccess.id_int(c))


## Checks if combatant died this tick (e.g. bled out). Mutates c, emits action_resolved if died.
## Returns victor string if battle should end (non-empty), else "".
static func process_death_tick(manager: Node, c: Dictionary) -> String:
    if not CombatantEntityAccess.alive_bool(c) or CombatantEntityAccess.scene_node(c) == null:
        return ""
    if not CombatantEntityAccess.is_dead(c):
        return ""
    c.alive = false
    CombatFootwork.clear_on_death(c)
    c.state = CombatConstants.STATE_DEAD
    cancel_events_for_dead_combatant(manager, c)
    # Emit died signal for deaths caught by per-tick check (vital destruction grace period expiry
    # or blood loss). The immediate emit was removed from EntityDamage for vital destruction;
    # this is the deferred emission path that ensures the signal fires exactly once.
    var death_scene_node: Node = CombatantEntityAccess.scene_node(c)
    if death_scene_node != null:
        EntityWounds.emit_death_once(death_scene_node)
    var death_reason: String = CombatantEntityAccess.get_death_reason(c)
    var who: String = CombatantEntityAccess.get_display_name(c)
    # Grace-expiry trace: a vital death registered by the per-tick path means the vital-destruction
    # grace countdown reached 0 (combat_time), i.e. the kill landed seconds after the fatal hit.
    # vital_grace_has_elapsed() (not grace <= 0.0) excludes test-manipulated destructions where no
    # grace was ever armed (remains -1.0), so only real expiries are traced.
    if death_scene_node != null and death_scene_node.has_method("vital_grace_has_elapsed") and death_scene_node.vital_grace_has_elapsed():
        CombatDebug.combat_session("VITAL_GRACE_EXPIRED %s -- %s" % [who, death_reason])
    if OperationalLog.play_session_is_editor_f5():
        CombatF5SoakTrace.note_death_tick(who, death_reason)
    else:
        # Compact stable token on the always-on line; verbose numeric reason is calibration-only.
        var death_token: String = "BLEED_OUT" if str(death_reason).to_lower().begins_with("blood_loss") else ("VITAL_DESTROYED" if (str(death_reason).to_lower().begins_with("vital_part_destroyed") or str(death_reason).to_lower().begins_with("vital_part_zero")) else "OTHER")
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session("DEATH (tick) %s  -  %s" % [who, death_reason])
        else:
            CombatDebug.combat_session("DEATH (tick) %s -- %s" % [who, death_token])
    # Phase 3: Plug on death  -  update formation (slot_obstacles, promote rank 1 if rank 0 died).
    if manager.has_method("_on_combatant_died"):
        manager.on_combatant_died(c)
    manager.emit_signal(
        "action_resolved",
        CombatantEntityAccess.id_int(c),
        -1,
        {
            "dmg": 0,
            "died": true,
            "part": "",
            "damage_type": "",
            "outcome": "bled_out",
            "move_id": "bled_out",
            "health_before": 0,
            "health_after": 0,
            "final_cut": 0,
            "final_blunt": 0
        }
    )
    return manager._check_for_winner()


## Handles cowering recovery when arm functionality returns. Returns true if combatant should be skipped
## (incapacitated).
static func process_incapacitation(manager: Node, c: Dictionary) -> bool:
    if CombatantEntityAccess.scene_node(c) == null:
        return false
    if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_COWERING:
        CombatFootwork.reconcile_idle_offset(c)
    if CombatantEntityAccess.is_unconscious(c):
        return true
    # Cowering: when arm functionality returns, leave cowering state
    if (
        CombatantEntityAccess.state_str(c) == CombatConstants.STATE_COWERING
        and not CombatantEntityAccess.is_cowering(c)
    ):
        CombatFootwork.return_to_waiting(c)
        c.gauge = 0.0
        c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
        PassiveParryContext.apply_cower_replant(c)
        var who_name: String = CombatantEntityAccess.get_display_name(c)
        CombatDebug.combat_session("%s no longer cowering (arm functionality returned)." % who_name)
        CombatEventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
        return false
    # Mobile cowering (no arms, functional legs): allow ticks so formation retreat can be offered
    if CombatantEntityAccess.is_cowering(c):
        _get_mobility_retreat().sync_cowering_state_if_no_functional_arm(c)
        return not CombatantEntityAccess.can_flee_or_fall_back(c)
    if CombatantEntityAccess.is_incapacitated(c):
        return true
    return false


## Enters short recovery (no arm, skip turn). For event-driven flow.
## When **`manager`** is set and **`c.pending_attack`** is non-empty, clears defender
## **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** (Tier 4.2) like **`complete_recovery`**.
static func enter_short_recovery(c: Dictionary, manager: Node = null) -> void:
    CombatFootwork.clear_on_exchange_end(c)
    c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
    c.state = CombatConstants.STATE_RECOVERING
    c.state_timer = 0.0
    c.state_duration = 0.8
    c.gauge = 0.0
    var pa_short: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
    c.pending_attack = {}
    if manager != null and not pa_short.is_empty():
        AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa_short)


## Completes recovery: guard update, state -> WAITING or COWERING. For event-driven flow.
static func complete_recovery(manager: Node, c: Dictionary) -> void:
    c.gauge = 0.0
    c.state_timer = 0.0
    c.state_duration = 0.0
    var move_id: String = c.get(DataKeys.PA_LAST_MOVE_ID, c.get(DataKeys.ATTACK_LAST_MOVE_ID, ""))
    if move_id.is_empty():
        move_id = str(
            CombatantEntityAccess.nested_dictionary_read(c, "pending_attack").get(
                CombatConstants.PA_KEY_ATTACK_TYPE, ""
            )
        )
    var eff_line: String = c.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
    var cause: String = CombatConstants.normalize_recovery_cause(str(c.get(DataKeys.ATTACK_RECOVERY_CAUSE, "")))
    if cause == "attack_deflect":
        # Guard already displaced at parry time — just clean up stored data.
        c.erase(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY)
        c.erase(DataKeys.PA_DEFENDER_FORM_AT_PARRY)
        c.erase(DataKeys.PA_PARRY_CLASH_CONTEXT)
    else:
        GuardLineUpdater.set_guard_from_move(c, move_id, eff_line)
    var pa_before: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
    c.pending_attack = {}
    if manager != null and not pa_before.is_empty():
        AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa_before)
    CombatFootwork.clear_on_exchange_end(c)
    if CombatantEntityAccess.get_attacking_arm(c).is_empty():
        CombatFootwork.return_to_cowering(c)
        if not OperationalLog.is_play_session_active():
            var who_name: String = CombatantEntityAccess.get_display_name(c)
            CombatDebug.combat_session("%s is cowering (no functional arms)" % who_name)
    else:
        CombatFootwork.return_to_waiting(c)
        c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK


## Cancels medical wind-up if target died. Returns true if cancelled (caller should continue to next combatant).
static func process_medical_wind_up_cancel(manager: Node, c: Dictionary) -> bool:
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
        return false
    var pm_raw_check: Variant = c.get(DataKeys.PA_PENDING_MEDICAL, null)
    if pm_raw_check is not Dictionary:
        c[DataKeys.PA_PENDING_MEDICAL] = {}
        CombatFootwork.return_to_waiting(c)
        c.state_timer = 0.0
        c.state_duration = 0.0
        c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
        CombatEventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
        return true
    var pm_check: Dictionary = pm_raw_check
    var tgt_cid_check: int = pm_check.get(DataKeys.MEDICAL_TARGET_COMBATANT_ID, CombatantEntityAccess.id_int(c))
    if tgt_cid_check == CombatantEntityAccess.id_int(c):
        return false
    var tgt_check: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tgt_cid_check)
    if not tgt_check.is_empty() and CombatantEntityAccess.is_alive_in_combat(tgt_check):
        return false
    if not tgt_check.is_empty():
        tgt_check.receiving_medical_count = max(0, tgt_check.get(DataKeys.PA_RECEIVING_MEDICAL_COUNT, 0) - 1)
    c[DataKeys.PA_PENDING_MEDICAL] = {}
    CombatFootwork.return_to_waiting(c)
    c.state_timer = 0.0
    c.state_duration = 0.0
    c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
    var who_name: String = CombatantEntityAccess.get_display_name(c)
    CombatDebug.medical_session("Medical cancelled: %s (target died during wind-up)" % who_name)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
    return true


## Aborts medical wind-up when the performer takes damage mid-wind-up.
static func abort_medical_wind_up(manager: Node, performer_id: int) -> void:
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, performer_id)
    if c.is_empty():
        return
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
        return
    var pm: Dictionary = c.get(DataKeys.PA_PENDING_MEDICAL, {}) as Dictionary
    var tgt_cid: int = pm.get(DataKeys.MEDICAL_TARGET_COMBATANT_ID, performer_id)
    if tgt_cid != performer_id:
        var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tgt_cid)
        if not tgt.is_empty():
            tgt.receiving_medical_count = max(0, tgt.get(DataKeys.PA_RECEIVING_MEDICAL_COUNT, 0) - 1)
    c[DataKeys.PA_PENDING_MEDICAL] = {}
    CombatFootwork.return_to_waiting(c)
    c.state_timer = 0.0
    c.state_duration = 0.0
    c[DataKeys.COMBATANT_GUARD] = CombatConstants.GUARD_AFTER_ATTACK
    var who: String = CombatantEntityAccess.get_display_name(c)
    CombatDebug.medical_session("Medical wind-up interrupted: %s (took damage during treatment)" % who)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)


static func process_receiving_medical(manager: Node, c: Dictionary, delta: float) -> void:
    CombatFootwork.reconcile_idle_offset(c)
    c.gauge = 100.0  # Keep readied; can hold/switch direct pressure on other wounds
    var cooldown: float = maxf(0.0, c.get(DataKeys.PA_RECEIVING_CARE_COOLDOWN, 0.0) - delta)
    c[DataKeys.PA_RECEIVING_CARE_COOLDOWN] = cooldown
    if CombatantEntityAccess.is_player_side(c):
        var pending: bool = c.get(DataKeys.PA_RECEIVING_CARE_TURN_PENDING, false)
        if cooldown <= 0.0 and not pending:
            var recv_actions: Array = manager.get_available_actions(CombatantEntityAccess.id_int(c))
            if not recv_actions.is_empty():
                manager.notify_turn_ready(CombatantEntityAccess.id_int(c))
                c.receiving_care_turn_pending = true
                c[DataKeys.PA_RECEIVING_CARE_COOLDOWN] = CombatConstants.RECOVERY_AFTER_MEDICAL_S
    else:
        if (
            MedicalPhaseController.combat_resolution_blocked(manager)
            and MedicalPhaseController.is_losing_side(manager, c)
        ):
            return
        if cooldown <= 0.0:
            var actions: Array = manager.get_available_actions(CombatantEntityAccess.id_int(c))
            if not actions.is_empty():
                var cid_recv: int = CombatantEntityAccess.id_int(c)
                var choice: Dictionary = CombatAIActionPicker.pick(actions, cid_recv, manager)
                CombatDebug.flow_log(
                    (
                        "receiving_care enemy id=%d actions=[%s] => pick %s"
                        % [cid_recv, CombatDebug.format_actions_compact(actions), choice.get(DataKeys.ACTION_MOVE_ID, "")]
                    ),
                    "receiving_care_enemy:%d" % cid_recv
                )

                CombatAIActionPicker.resolve_choice(manager, cid_recv, choice, true)
                c[DataKeys.PA_RECEIVING_CARE_COOLDOWN] = CombatConstants.RECOVERY_AFTER_MEDICAL_S


static func process_waiting(_manager: Node, c: Dictionary, delta: float) -> void:
    # Option A: Event-driven. No gauge fill or turn_ready  -  events handle readiness. Only guard + stamina.
    var g: float = PassiveParryContext.guard_readiness_float(c)
    # Low consciousness degrades guard — fighter with severe head damage can barely maintain defense
    if entity_has_effective_consciousness_below_threshold(c, 25.0):
        g = minf(g, 0.3)
    c[DataKeys.COMBATANT_GUARD] = minf(1.0, g + CombatConstants.GUARD_RISE_RATE * delta)
    CombatExhaustion.process_waiting_recovery(c, delta)
    var s: float = CombatantEntityAccess.stamina_float(c)
    var cap: float = CombatExhaustion.effective_stamina_max(c)
    # First-order (exponential) PCr resynthesis: refill rate is proportional to the deficit (cap - s), so the
    # pool recovers fast when depleted and tapers as it approaches the (exhaustion-reduced) cap.
    var refill_k: float = CombatExhaustion.effective_stamina_refill_rate(c)
    c[DataKeys.COMBATANT_STAMINA] = minf(cap, s + refill_k * (cap - s) * delta)
    # Standing-ready is a partial rest (limbs holding a guard, not fully at rest), so local limb fatigue
    # recovers at the partial rate — matching the "recovers while waiting" tooltip. Cowering (limbs fully
    # down) recovers at the full rate via process_cowering_idle.
    _get_muscle_fatigue().apply_guard_hold_exertion(_manager, c, delta)
    _get_muscle_fatigue().process_recovering_recovery(c, delta)
    # Out of the exchange a fighter regains composure — morale slowly recovers toward full.
    CombatMoraleCohesion.recover_morale_if_safe(c, delta)
    CounterTempo.process_waiting(_manager, c)
    CombatFlurryBind.process_waiting(_manager, c)
    # HEMA: sustained bind pressure fatigues the holding muscles — pressure decays over time (progressive
    # leverage degradation after the grace period). Previously dead code; now ticked each waiting frame.
    CombatBindPressure.apply_decay(c, _manager, delta)
    # In batch/harness mode the idle offset keys and UI attention hints are never rendered — skip
    # the reconciliation + formatting to save significant per-tick time across thousands of ticks.
    var skip_ui: bool = _manager != null and _manager.has_meta("_batch_skip_ui_tick") and bool(_manager.get_meta("_batch_skip_ui_tick"))
    if not skip_ui:
        CombatFootwork.reconcile_idle_offset(c)
        CombatUiHints.refresh_waiting_tick_stamps(_manager, c)


static func process_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
    c.gauge = 0.0
    c.state_timer += delta
    if manager != null and _get_mobility_retreat().cannot_commit_melee(c):
        CounterTempo.abort_attacker_wind_up(manager, CombatantEntityAccess.id_int(c))
        return
    # Completion handled by EVENT_MELEE_ATTACK; state_timer for UI countdown only


static func process_medical_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
    CombatFootwork.reconcile_idle_offset(c)
    c.gauge = 0.0
    c.state_timer += delta
    if manager != null and _get_mobility_retreat().cannot_commit_melee(c):
        abort_medical_wind_up(manager, CombatantEntityAccess.id_int(c))
        return
    if c.state_timer >= c.state_duration:
        var pm_raw: Variant = c.get(DataKeys.PA_PENDING_MEDICAL, null)
        var pm: Dictionary = pm_raw as Dictionary if pm_raw is Dictionary else {}
        c[DataKeys.PA_PENDING_MEDICAL] = {}
        MedicalWindUpHandler.complete(manager, c, pm)


static func process_recovering(manager: Node, c: Dictionary, delta: float) -> void:
    c.gauge = 0.0
    c.state_timer += delta
    if manager != null and _get_mobility_retreat().cannot_commit_melee(c):
        _get_mobility_retreat().react_attacking_arm_lost_if_needed(manager, c)
        return
    # Completion handled by EVENT_RECOVERY_END; state_timer for UI countdown only


## Formation shuffle timers (**`swap_rank`**, **`fall_back`**)  -  scrub idle PA each tick (no **`process_waiting`** on
## these states).
static func process_formation_move_timer(c: Dictionary, delta: float) -> void:
    CombatFootwork.reconcile_idle_offset(c)
    c.state_timer = minf(c.state_timer + delta, c.get(DataKeys.PA_STATE_DURATION, 1.0))


## Cowering idle: limb fatigue decay + composure fill while cowering.
static func process_cowering_idle(_manager: Node, c: Dictionary, delta: float) -> void:
    _get_muscle_fatigue().process_waiting_recovery(c, delta)
    var g: float = CombatantEntityAccess.gauge_float(c)
    c.gauge = minf(100.0, g + 0.5 * delta)


## Check if a combatant's effective consciousness is below a threshold (via entity lookup).
static func entity_has_effective_consciousness_below_threshold(c: Dictionary, threshold: float) -> bool:
    var entity_node = CombatantEntityAccess.scene_node(c)
    if entity_node == null:
        return false
    if not entity_node.has_method("_get_effective_consciousness"):
        return false
    var eff_consciousness: float = entity_node._get_effective_consciousness()
    return eff_consciousness < threshold




