class_name CombatResolveAction
extends RefCounted

## Player/AI action dispatch: medical, close, formation moves, melee wind-up scheduling.
## Footing: focus-line resolve -> **`GuardLineUpdater.set_guard_from_line`** (L3 drift, not form home) . melee ->
## **`AttackWindUpStarter`** (PA stamp when flag on). LIVE_PATHS **`#wf-guard-writers`** . **`#wf-pick-vs-strike`** .
## **`#wf-tier-44-pa`**.


static func is_medical_move(move_id: String) -> bool:
    return CombatConstants.is_medical_move(move_id)


## True when the action changed combatant state (wind-up, formation move, flee, etc.). False -> reject/skip path; no
## turn log.
static func resolve(manager: Node, attacker_id: int, target_id: int, move_id: String, options: Dictionary) -> bool:
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty():
        return false
    if manager.medical_phase:
        if not CombatantEntityAccess.is_on_side(atk, str(manager.medical_phase_winner)):
            return false
        if not is_medical_move(move_id):
            return false
    var use_counter_tempo: bool = options.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)
    if (
        CombatantEntityAccess.state_str(atk) == CombatConstants.STATE_WAITING
        and CombatantEntityAccess.gauge_float(atk) < 100.0
        and not manager.medical_phase
    ):
        var mercy_execute: bool = (
            move_id == CombatConstants.MOVE_ID_EXECUTE
            and CombatExecute.is_downed_opponent_of(manager, atk, CombatantEntityAccess.manager_get_combatant(manager, target_id))
        )
        if not ((use_counter_tempo and CounterTempo.can_act(manager, atk)) or mercy_execute):
            return false
    if (
        CombatantEntityAccess.state_str(atk) == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
        and CombatConstants.is_direct_pressure_move(move_id)
        and target_id == attacker_id
    ):
        atk.receiving_care_turn_pending = false
        atk.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
        var part: String = str(options.get(DataKeys.ACTION_TARGET_PART, ""))
        if part.is_empty():
            return false
        if not CombatMedicalCoordination.medical_action_allowed(
            manager, attacker_id, attacker_id, part, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
        ):
            return false
        if CombatantEntityAccess.entity_apply_direct_pressure(manager, atk, part):
            var who: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
            CombatDebug.medical_session("%s (receiving care) holding direct pressure on %s" % [who, part])
            manager.emit_signal(
                "action_resolved",
                attacker_id,
                attacker_id,
                {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false}
            )
            # XCamp-4: proficiency gains for self-pressure during receiving care.
            if CompanyState.read_stub_proficiency_enabled():
                var perf_node := CombatantEntityAccess.get_entity_from_manager(manager, atk)
                if perf_node != null and perf_node.has("_proficiency_bonus"):
                    EntityProficiency.award_stat_gain(
                        perf_node,
                        "intelligence",
                        EntityProficiency.GAIN_MEDICAL_ACTION_BASE * EntityProficiency.GAIN_DIRECT_PRESSURE_INT_MULT
                    )
            manager.emit_signal("turn_resolved", attacker_id)
            return true
        return false
    if (
        CombatantEntityAccess.state_str(atk) != CombatConstants.STATE_WAITING
        and CombatantEntityAccess.state_str(atk) != CombatConstants.STATE_COWERING
    ):
        return false
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(atk)
    if (
        CombatMobilityRetreat.cannot_commit_melee(atk)
        and not CombatMobilityRetreat.resolve_move_allowed_when_cannot_melee(move_id, target_id, attacker_id)
    ):
        CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "cannot commit melee")
        return false
    CombatPlayerTurnHints.clear_formation_listed_turn_hint_on_combatant(atk)
    if move_id == CombatConstants.MOVE_ID_WAIT:
        manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_WAIT, "explicit wait move")
        return true
    if move_id == CombatConstants.MOVE_ID_FLEE and target_id == attacker_id:
        if not _resolve_flee_legal(manager, atk):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "flee not legal")
            return false
        CombatFormationFlee.apply_flee(manager, attacker_id)
        return true
    if move_id == CombatConstants.MOVE_ID_YIELD and target_id == attacker_id:
        if not CombatFormationYield.yield_action_legal(manager, atk):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "yield not legal")
            return false
        CombatFormationYield.apply_yield(manager, attacker_id)
        return true
    if CombatConstants.is_leader_formation_command_move(move_id) and target_id == attacker_id:
        if OperationalLog.is_play_session_active():
            var fid_cmd: String = CombatantEntityAccess.formation_id_str(atk)
            CombatF5SoakTrace.note_leader_formation_command_pick(
                CombatantEntityAccess.get_display_name(atk, attacker_id),
                move_id,
                fid_cmd,
                CombatantEntityAccess.side_str(atk)
            )
        if not CombatLeaderFormationCommand.apply_leader_command(manager, attacker_id, move_id):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "leader command not legal")
            return false
        return true
    if CombatConstants.is_focus_line_move(move_id):
        var focus_line: String = CombatConstants.guard_line_for_focus_move_id(move_id)
        if focus_line.is_empty():
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "unknown focus move")
            return false
        var cur_line: String = str(atk.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
        if cur_line == focus_line:
            CombatDebug.flow_log_event(
                "focus_line_skip id=%d move=%s line=%s (already set)" % [attacker_id, move_id, focus_line],
                "focus_skip:%d:%s" % [attacker_id, focus_line]
            )
            manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_WAIT, "focus already set")
            return true
        GuardLineUpdater.set_guard_from_line(atk, focus_line)
        CombatDebug.flow_log_event(
            "focus_line_set id=%d move=%s line=%s" % [attacker_id, move_id, focus_line],
            "focus_set:%d:%s" % [attacker_id, focus_line]
        )
        manager.emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "focus_line", "line": focus_line})
        manager.emit_signal("turn_resolved", attacker_id)
        CombatDebug.finish_instant_turn_and_schedule_ready(manager, atk)
        return true
    if is_medical_move(move_id):
        var part: String = str(options.get(DataKeys.ACTION_TARGET_PART, ""))
        if not CombatMedicalCoordination.medical_action_allowed(manager, attacker_id, target_id, part, move_id):
            var block_reason: String = CombatMedicalCoordination.medical_action_coordination_blocked(
                manager, attacker_id, target_id, part, move_id
            )
            CombatDebug.resolve_action_rejected(
                manager, attacker_id, move_id, "medical coordination: %s" % block_reason
            )
            return false
        var who: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
        var tgt_desc: String = "ally" if target_id != attacker_id else "self"
        if OperationalLog.is_play_session_active():
            CombatF5SoakTrace.note_medical_action_pick(who, move_id, part, tgt_desc)
        elif not CombatDebug.flow_verbose_enabled():
            CombatDebug.combat_session("action %s chose medical %s on part=%s (%s)" % [who, move_id, part, tgt_desc])
        MedicalActionStarter.start(manager, attacker_id, target_id, move_id, part)
        manager.emit_signal("turn_resolved", attacker_id)
        return true
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if tgt.is_empty() or not CombatantEntityAccess.is_alive_in_combat(tgt):
        CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "target missing or dead")
        return false
    if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        var dist_close: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
        if not CombatMeleeListing.attempt_close_listed_for_pair(manager, atk, target_id, dist_close):
            # Stale UI / scripted resolve: same blocked path as `CombatEngagementResolver` (telemetry).
            return _commit_close_attempt_resolve(manager, attacker_id, target_id)
        if (
            not OperationalLog.is_play_session_active()
            and not CombatDebug.flow_verbose_enabled()
            and CombatConstants.combat_event_debug_active()
        ):
            var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
            var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
            CombatDebug.combat_session(
                "%s attempting to close on %s (tactical distance - pressure vs evasion roll)" % [atk_name, tgt_name]
            )
        if OperationalLog.is_play_session_active():
            CombatF5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
        return _commit_close_attempt_resolve(manager, attacker_id, target_id)
    if CombatConstants.is_formation_reposition_move(move_id):
        var move_policy: Dictionary = CombatEngagementMode.movement_policy(manager)
        if move_id == CombatConstants.MOVE_ID_SWAP_RANK and not move_policy.get(DataKeys.MOVE_POLICY_ALLOW_SWAP_RANK, false):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks swap_rank")
            return false
        if move_id == CombatConstants.MOVE_ID_DRAG_BACK and not move_policy.get(DataKeys.MOVE_POLICY_ALLOW_DRAG_BACK, false):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks drag_back")
            return false
        if move_id == CombatConstants.MOVE_ID_FALL_BACK and not move_policy.get(DataKeys.MOVE_POLICY_ALLOW_FALL_BACK, false):
            # Cowering solo retreat is listed without stable-line policy (`formation_retreat_only` in builder).
            var cowering_solo_retreat: bool = (
                target_id == attacker_id
                and CombatMobilityRetreat.formation_retreat_only_for(atk)
                and CombatFormationMoveListing.solo_fall_back_action_legal(manager, atk)
            )
            if not cowering_solo_retreat:
                CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks fall_back")
                return false
        if (
            move_id == CombatConstants.MOVE_ID_ROTATE_FILE
            and not CombatEngagementMode.allow_rotate_file_for_formation(
                manager, CombatantEntityAccess.formation_id_str(atk)
            )
        ):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks rotate_file")
            return false
        if move_id == CombatConstants.MOVE_ID_PLUG_FORWARD:
            var can_plug: bool = (
                move_policy.get(DataKeys.MOVE_POLICY_ALLOW_SWAP_RANK, false)
                or CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.side_str(atk))
            )
            if not can_plug:
                CombatDebug.resolve_action_rejected(
                    manager, attacker_id, move_id, "movement policy blocks plug_forward"
                )
                return false
        var ctx_mv: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, atk)
        var fid_mv: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_mv)
        if move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id:
            if not CombatFormationMoveListing.solo_fall_back_action_legal(manager, atk):
                CombatDebug.resolve_action_rejected(
                    manager, attacker_id, move_id, "solo fall_back not legal fid=%s" % fid_mv
                )
                return false
        if move_id != CombatConstants.MOVE_ID_FALL_BACK or target_id != attacker_id:
            var partner_mv: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
            if partner_mv.is_empty() or not CombatantEntityAccess.is_available_formation_partner(atk, partner_mv):
                CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "invalid formation partner")
                return false
            match move_id:
                CombatConstants.MOVE_ID_ROTATE_FILE:
                    if not CombatFormationMoveListing.rotate_file_action_legal(manager, atk, partner_mv, ctx_mv):
                        CombatDebug.resolve_action_rejected(
                            manager, attacker_id, move_id, "rotate_file not legal for partner"
                        )
                        return false
                CombatConstants.MOVE_ID_SWAP_RANK:
                    if not CombatFormationMoveListing.swap_rank_action_legal(manager, atk, partner_mv, ctx_mv):
                        CombatDebug.resolve_action_rejected(
                            manager, attacker_id, move_id, "swap_rank not legal for partner"
                        )
                        return false
                CombatConstants.MOVE_ID_DRAG_BACK:
                    if not CombatFormationMoveListing.front_rank_paired_retreat_action_legal(
                        manager, atk, partner_mv, ctx_mv
                    ):
                        CombatDebug.resolve_action_rejected(
                            manager, attacker_id, move_id, "drag_back not legal for partner"
                        )
                        return false
                CombatConstants.MOVE_ID_FALL_BACK:
                    if not CombatFormationMoveListing.front_rank_paired_retreat_action_legal(
                        manager, atk, partner_mv, ctx_mv
                    ):
                        CombatDebug.resolve_action_rejected(
                            manager, attacker_id, move_id, "fall_back pair not legal for partner"
                        )
                        return false
                CombatConstants.MOVE_ID_PLUG_FORWARD:
                    if not CombatFormationMoveListing.plug_forward_action_legal(manager, atk, partner_mv, ctx_mv):
                        CombatDebug.resolve_action_rejected(
                            manager, attacker_id, move_id, "plug_forward not legal for partner"
                        )
                        return false
    if move_id == CombatConstants.MOVE_ID_SWAP_RANK:
        if OperationalLog.is_play_session_active():
            CombatF5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
        manager._start_formation_pair_move(attacker_id, target_id, move_id)
        manager.emit_signal("turn_resolved", attacker_id)
        return true
    if move_id == CombatConstants.MOVE_ID_DRAG_BACK:
        if OperationalLog.is_play_session_active():
            CombatF5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
        manager._start_formation_pair_move(attacker_id, target_id, move_id)
        manager.emit_signal("turn_resolved", attacker_id)
        return true
    if move_id == CombatConstants.MOVE_ID_FALL_BACK:
        if OperationalLog.is_play_session_active():
            var fb_tag: String = (
                "cowering_fall_back"
                if CombatantEntityAccess.state_str(atk) == CombatConstants.STATE_COWERING
                else CombatConstants.MOVE_ID_FALL_BACK
            )
            CombatF5SoakTrace.note_fall_back_pick(
                fb_tag, CombatantEntityAccess.get_display_name(atk, attacker_id), target_id
            )
        if target_id == attacker_id:
            manager._start_fall_back_solo(attacker_id)
        else:
            manager._start_formation_pair_move(
                attacker_id, target_id, CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR
            )
        manager.emit_signal("turn_resolved", attacker_id)
        return true
    if move_id == CombatConstants.MOVE_ID_ROTATE_FILE:
        if CombatantEntityAccess.rank_int(atk) != 0:
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "rotate_file requires front rank")
            return false
        var rotate_menu: Array = (
            manager.get_available_actions(attacker_id) if manager.has_method("get_available_actions") else []
        )
        if CombatDoctrine.should_suppress_skirmish_rotate_file(manager, atk, rotate_menu):
            CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "envelop mop-up suppresses rotate_file")
            return false
        if OperationalLog.is_play_session_active():
            CombatF5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
        manager._start_rotate_file(attacker_id, target_id)
        manager.emit_signal("turn_resolved", attacker_id)
        return true
    if move_id == CombatConstants.MOVE_ID_PLUG_FORWARD:
        if OperationalLog.is_play_session_active():
            CombatF5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
        manager._start_plug_forward(attacker_id, target_id)
        manager.emit_signal("turn_resolved", attacker_id)
        return true
    if move_id == CombatConstants.MOVE_ID_EXECUTE:
        _resolve_execute(manager, attacker_id, target_id, atk, tgt)
        return true
    if CombatantEntityAccess.is_applying_direct_pressure_scene(atk):
        var pressure_part: String = CombatantEntityAccess.get_direct_pressure_part_scene(atk)
        CombatDebug.flow_log(
            (
                "clear_direct_pressure id=%d %s (was %s)"
                % [
                    attacker_id,
                    CombatantEntityAccess.get_display_name(atk, attacker_id),
                    pressure_part if not pressure_part.is_empty() else "?"
                ]
            ),
            "clear_direct_pressure:%d" % attacker_id
        )
    CombatantEntityAccess.clear_direct_pressure_scene(atk)
    if CombatMobilityRetreat.cannot_commit_melee(atk):
        CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "no functional arm for melee")
        return false
    if move_id == CombatConstants.MOVE_ID_BIND_PRESS:
        CombatBindPressure.resolve_bind_press(manager, attacker_id, target_id)
        return true
    if move_id == CombatConstants.MOVE_ID_BIND_VOID:
        CombatBindPressure.resolve_bind_void(manager, attacker_id, target_id)
        return true
    if move_id == CombatConstants.MOVE_ID_BIND_WIND:
        CombatBindPressure.resolve_bind_wind(manager, attacker_id, target_id)
        return true
    if move_id == CombatConstants.MOVE_ID_BIND_WRESTLE:
        CombatBindPressure.resolve_bind_wrestle(manager, attacker_id, target_id)
        return true
    var opts: Dictionary = {}
    if options.has(DataKeys.ACTION_TARGET_PART):
        opts[DataKeys.ATTACK_TARGET_PART] = options.target_part
    if options.has(DataKeys.ACTION_FEINT_PART):
        opts[DataKeys.ATTACK_FEINT_PART] = options.feint_part
    if use_counter_tempo:
        opts[CombatConstants.ACTION_KEY_COUNTER_TEMPO] = true
        CounterTempo.spend_gauge(atk)
        CounterTempo.clear_window(atk)
    var incoming_attacker_id: int = -1
    if use_counter_tempo:
        incoming_attacker_id = CounterTempo.incoming_attacker_id(manager, attacker_id)
    AttackWindUpStarter.start(manager, attacker_id, target_id, move_id, opts)
    var wind_st: String = CombatantEntityAccess.state_str(atk)
    if wind_st == CombatConstants.STATE_WIND_UP and atk.state_duration > 0.0:
        CombatTargetScoring.on_combat_commitment(manager, attacker_id, target_id)
        manager.emit_signal("turn_resolved", attacker_id)
        (
            CombatantEntityAccess
            . manager_schedule_event(
                manager,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": attacker_id,
                    "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, atk.state_duration),
                    "data": {},
                }
            )
        )
        if use_counter_tempo and incoming_attacker_id >= 0:
            CounterTempo.defer_incoming_melee_after_counter(manager, attacker_id, incoming_attacker_id)
        return true
    if (
        wind_st != CombatConstants.STATE_WAITING
        or CombatantEntityAccess.gauge_float(atk) < CombatConstants.GAUGE_FULL_THRESHOLD
    ):
        # e.g. short recovery when no functional arm — consume gauge to prevent stuck loop.
        manager.emit_signal("turn_resolved", attacker_id)
        var reason: String = ""
        if wind_st != CombatConstants.STATE_WAITING:
            reason = "wind_up did not produce STATE_WIND_UP (state=%s duration=%.1f)" % [wind_st, atk.state_duration]
        else:
            reason = "wind_up did not start: gauge=%.1f threshold=%s" % [
                CombatantEntityAccess.gauge_float(atk),
                CombatConstants.GAUGE_FULL_THRESHOLD,
            ]
        CombatDebug.flow_log_event(
            "resolve_action_silent_fail id=%d move=%s reason=%s" % [attacker_id, move_id, reason],
            "silent_fail:%d:%s" % [attacker_id, move_id]
        )
        manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_PASS, "wind_up_failed: %s" % reason)
        return true
    return false


## Close attempt: resolver clears gauge via **`_resolve_close_attempt`**; if it no-ops, **`skip_turn`** (no
## **`FP_WARN`**).
static func _commit_close_attempt_resolve(manager: Node, attacker_id: int, target_id: int) -> bool:
    manager._resolve_close_attempt(attacker_id, target_id)
    var atk_after: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk_after.is_empty():
        return false
    if (
        CombatantEntityAccess.state_str(atk_after) == CombatConstants.STATE_WAITING
        and CombatantEntityAccess.gauge_float(atk_after) >= CombatConstants.GAUGE_FULL_THRESHOLD
    ):
        manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_PASS, "close resolve no-op")
        return false
    manager.emit_signal("turn_resolved", attacker_id)
    return true


## Resolve-time flee legality: allows manual resolution (harness tests, forced flee) even when listing is blocked by
## the "alone on side" cowering guard — that guard only applies to action **listing**, not direct resolve calls.
static func _resolve_flee_legal(manager: Node, atk: Dictionary) -> bool:
    if manager == null or atk.is_empty():
        return false
    if atk.get(DataKeys.COMBATANT_COMBAT_ABSENT, false):
        return false
    if not CombatantEntityAccess.can_flee_or_fall_back(atk):
        return false
    if not CombatantEntityAccess.alive_bool(atk):
        return false
    var st: String = CombatantEntityAccess.state_str(atk)
    if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
        return false
    return true


## Resolve-time execute: wind-up-less kill on downed target (coup de grâce / mercy).
static func _resolve_execute(manager: Node, attacker_id: int, target_id: int, atk: Dictionary, tgt: Dictionary) -> bool:
    if not CombatantEntityAccess.alive_bool(tgt):
        return false
    var who: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
    var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
    if not OperationalLog.is_play_session_active():
        CombatDebug.combat_session("%s executes %s (coup de grâce / mercy)" % [who, tgt_name])
    var tid: int = CombatantEntityAccess.id_int(tgt)
    var ledger_raw: Variant = atk.get(DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID, null)
    var ledger: Dictionary = {}
    if ledger_raw is Dictionary:
        ledger = (ledger_raw as Dictionary).duplicate()
    ledger[tid] = float(ledger.get(tid, 0.0) + 1.0)
    atk[DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID] = ledger
    tgt.alive = false
    CombatFootwork.clear_on_death(tgt)
    tgt.state = CombatConstants.STATE_DEAD
    CombatStateHandlers.cancel_events_for_dead_combatant(manager, tgt)
    if manager.has_method("on_combatant_died"):
        manager.on_combatant_died(tgt)
    var empty_result: Dictionary = {}
    empty_result[DataKeys.RESULT_DIED] = true
    empty_result[DataKeys.RESULT_OUTCOME] = "execute"
    AttackResultApplier._abort_incoming_wind_up_if_target_died(manager, target_id)
    manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
    var winner: String = manager._check_for_winner()
    if not winner.is_empty():
        manager._end_combat_phase(winner, CombatantEntityAccess.scene_node(tgt))
    manager.emit_signal("turn_resolved", attacker_id)
    return true
