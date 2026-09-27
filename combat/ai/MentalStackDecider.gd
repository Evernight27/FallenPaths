class_name MentalStackDecider
extends RefCounted

## Tier 4.3: prioritized AI decision layers (self-medical -> ally medical -> counter -> incoming -> MS-L8 post-strike ->
## L4b sparse fight -> L4 hold line -> MS-L5 formation plug -> MS-L6 rout -> L5 exhaustion -> salience-damped utility
## pick).
## **MS-L4 footing boundary:** hold-line layer picks listed moves only  -  does **not** write **`guard_line`**, PA
## offset, or **`weapon_form`**. LIVE_PATHS **`#wf-pick-vs-strike`** . **`#wf-layer-labels`**.
## **No player target UI** — same picker for all sides; layers only narrow/reweight the listed action pool.


static func enabled() -> bool:
    return CombatConstants.is_feature_mental_stack_ai_enabled()


## Returns a picked action when a high-priority layer applies; empty **`{}`** -> caller uses salience-damped
## **`pick_weighted`**.
static func try_pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
    if not enabled() or actions.is_empty() or manager == null or combatant_id < 0:
        return {}
    CombatAttention.refresh_salience(manager, combatant_id)
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return {}
    ## Phase 3: tier persistence — skip re-evaluation within commitment window.
    if _tier_is_persistent(c, manager):
        var persistent_result: Dictionary = _tier_get_persistent_result(c, actions, combatant_id, manager)
        if not persistent_result.is_empty():
            return persistent_result
        c.erase(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE)
    ## Phase 3: transition guards — track failures and escalate tiers.
    c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
    # MS-L8: read post-strike stamp (clock-based, naturally expires after ~1 turn).
    var strike_tick_val: float = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0)
    var current_clock: float = manager.combat_clock
    var strike_tick_active: bool = (
        strike_tick_val >= 0.0
        and absf(strike_tick_val - current_clock) < CombatConstants.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE
    )
    if CombatMobilityRetreat.cannot_commit_melee(c):
        var retreat_only: Array = CombatMobilityRetreat.filter_actions_for_retreat_only(actions, c)
        if retreat_only.is_empty():
            return {}
        return CombatAIActionPicker.pick_weighted(retreat_only, combatant_id, manager)
    # L0: own immediate peril — self-aid before helping allies (TCCC-style).
    var tier_failed_this_tick: bool = false
    if CombatantEntityAccess.is_in_immediate_peril(manager, c):
        var self_med: Array = _filter_self_medical_actions(actions, combatant_id, manager)
        if self_med.is_empty():
            self_med = _filter_self_medical_actions_fallback(actions, combatant_id)
        if not self_med.is_empty():
            _reset_tier_failures(c)
            return _stamp_layer_pick(
                c,
                CombatConstants.MENTAL_STACK_LAYER_SELF_MEDICAL,
                CombatAIActionPicker.pick_weighted(self_med, combatant_id, manager),
                manager
            )
        tier_failed_this_tick = true
    # L1: ally peril -> coordinated medical only.
    var l1_ally_peril: bool = CombatAttention.ally_in_immediate_peril(manager, combatant_id)
    if l1_ally_peril and not tier_failed_this_tick:
        var medical: Array = _filter_coordinated_medical_actions(actions, combatant_id, manager)
        if medical.is_empty():
            medical = _filter_ally_medical_actions_fallback(actions, combatant_id, manager)
        if not medical.is_empty():
            _reset_tier_failures(c)
            return _stamp_layer_pick(
                c,
                CombatConstants.MENTAL_STACK_LAYER_MEDICAL,
                CombatAIActionPicker.pick_weighted(medical, combatant_id, manager),
                manager
            )
        tier_failed_this_tick = true
    # L2: counter-tempo window — gated by tier failure threshold so higher tiers get priority.
    var l1_failures: int = _get_tier_consecutive_failures(c)
    if CounterTempo.can_act(manager, c):
        ## Transition guard: require enough consecutive failures at higher tiers before allowing L2.
        if l1_failures >= CombatConstantsMentalStack.MENTAL_STACK_L1_TO_L2_FAILURE_THRESHOLD:
            var counters: Array = _filter_counter_tempo_actions(actions)
            if not counters.is_empty():
                _reset_tier_failures(c)
                return _stamp_layer_pick(
                    c,
                    CombatConstants.MENTAL_STACK_LAYER_COUNTER,
                    CombatAIActionPicker.pick_weighted(counters, combatant_id, manager),
                    manager
                )
            tier_failed_this_tick = true
    # L3: incoming wind-up on me -> counter (if listed) or melee vs that attacker.
    if CombatAttention.is_being_wind_up_targeted(manager, combatant_id):
        var incoming_id: int = CounterTempo.incoming_attacker_id(manager, combatant_id)
        var threat: Array = _filter_incoming_threat_actions(actions, incoming_id)
        if not threat.is_empty():
            _reset_tier_failures(c)
            return _stamp_layer_pick(
                c,
                CombatConstants.MENTAL_STACK_LAYER_INCOMING,
                CombatAIActionPicker.pick_weighted(threat, combatant_id, manager),
                manager
            )
        tier_failed_this_tick = true
    if tier_failed_this_tick:
        _increment_tier_failure(c)
    ## Phase 3: transition guard — escalate to L4b when counter/income tiers repeatedly fail.
    var esc_failures: int = _get_tier_consecutive_failures(c)
    if esc_failures >= CombatConstantsMentalStack.MENTAL_STACK_TIER_COMMITMENT_TICKS:
        _reset_tier_failures(c)
    # MS-L8: post-strike momentum  -  press advantage or disengage cleanly after a successful strike.
    # Fires before L4b so pressing a specific target advantage takes priority over general
    # fight-finishing pressure (L4b sparse-fight / mop-up).
    var fight_finish_tail: bool = false
    if CombatConstants.is_feature_ms_post_strike_enabled() and strike_tick_active:
        var struck_id: int = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID, -1)
        if struck_id >= 0:
            var ps_pool: Array = CombatPostStrike.filter_post_strike_actions(actions, combatant_id, manager, struck_id)
            if not ps_pool.is_empty():
                return _stamp_layer_pick(
                    c,
                    CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE,
                    CombatAIActionPicker.pick_weighted(ps_pool, combatant_id, manager),
                    manager
                )
    # L4b (before L4): combat-finish tails  -  sparse post-flee rank-0 or mop-up underdog; offense over wait/focus
    # shuffle. Also acts as escalation target when counter/income tiers repeatedly fail (transition guard).
    # Skip when this combatant or any ally is in immediate peril  -  medical layers take priority.
    var my_peril: bool = CombatantEntityAccess.is_in_immediate_peril(manager, c)
    var ally_in_peril_count: int = 0
    for _other in manager.combatants:
        if _other is not Dictionary:
            continue
        var o: Dictionary = _other
        if CombatantEntityAccess.side_str(o) != CombatantEntityAccess.side_str(c):
            continue
        if CombatantEntityAccess.id_int(o) == combatant_id:
            continue
        if CombatantEntityAccess.is_in_immediate_peril(manager, o):
            ally_in_peril_count += 1
    if not my_peril and ally_in_peril_count == 0:
        fight_finish_tail = CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id) or esc_failures >= CombatConstantsMentalStack.MENTAL_STACK_L1_TO_L2_FAILURE_THRESHOLD
    if fight_finish_tail:
        var fight_first: Array = _filter_sparse_fight_first_actions(actions, combatant_id, manager, c)
        if not fight_first.is_empty():
            return _stamp_layer_pick(
                c,
                CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT,
                CombatAIActionPicker.pick_weighted(fight_first, combatant_id, manager),
                manager
            )
    # L4G: guard priority — hold + position blade toward the expected attack line (live telegraph,
    # else engaged opponent's habitual yomi line) instead of opening new offense. Fires after L3
    # (no counter / threat melee listed) and after L4b fight-finish; before L4 hold-line. Telegraph
    # tells the unit "brace and parry" vs "attack". Guard-priority drift aligns the yomi habit for
    # free on waiting ticks; this layer spends the action to align on a live wind-up. Reads the
    # stamped target line from `apply_guard_priority_drift` to avoid redundant yomi scans.
    if (
        not CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id)
        and CombatAttention.guard_priority_score(manager, c)
            >= CombatConstantsMentalStack.GUARD_PRIORITY_MIN_SCORE
    ):
        var gp_target: String = str(c.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE, "")).strip_edges()
        if gp_target.is_empty():
            gp_target = CombatAttention.guard_priority_target_line(manager, c)
        if not gp_target.is_empty():
            var cur_line_gp: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
            if gp_target != cur_line_gp:
                var gp_pool: Array = _filter_guard_priority_actions(actions, gp_target)
                if not gp_pool.is_empty():
                    return _stamp_layer_pick(
                        c,
                        CombatConstants.MENTAL_STACK_LAYER_GUARD_PRIORITY,
                        CombatAIActionPicker.pick_weighted(gp_pool, combatant_id, manager),
                        manager
                    )
    # L4: back rank / no reach — hold in place; retarget guard only on incoming telegraph mismatch.
    # Fight-finish tails skip L4 wait/focus when L4b had no offense  -  utility pick handles trusted close/strikes.
    if CombatListedActions.action_list_is_reserve_posture_only(actions):
        if fight_finish_tail:
            var close_only: Array = _filter_hold_line_close_actions(actions, combatant_id, manager, c)
            if not close_only.is_empty():
                return _stamp_layer_pick(
                    c,
                    CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
                    CombatAIActionPicker.pick_weighted(close_only, combatant_id, manager),
                    manager
                )
        else:
            var hold_pick: Dictionary = _pick_hold_line_action(actions, combatant_id, manager, c)
            if not hold_pick.is_empty():
                return _stamp_layer_pick(c, CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE, hold_pick, manager)
    # MS-L5: vacancy / plug-forward  -  close rank-0 gaps before utility offense when plug moves are listed.
    if not CombatFormationVacancyPlugs.formation_plug_layer_blocked(manager, c, actions, combatant_id):
        var plug_pool: Array = CombatFormationVacancyPlugs.filter_formation_plug_actions(
            manager, c, combatant_id, actions
        )
        if not plug_pool.is_empty():
            var cohesion_mod: float = CombatMoraleCohesion._compute_cohesion_modifier(combatant_id, manager)
            for i in range(plug_pool.size()):
                var pa: Dictionary = plug_pool[i] as Dictionary
                if pa is Dictionary and not pa.is_empty():
                    var base_w: float = pa.get(DataKeys.ACTION_WEIGHT, 1.0)
                    pa[DataKeys.ACTION_WEIGHT] = base_w * cohesion_mod
            return _stamp_layer_pick(
                c,
                CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG,
                CombatAIActionPicker.pick_weighted(plug_pool, combatant_id, manager, actions),
                manager
            )
    # MS-L6: cohesion break / abandon-field  -  flee or fall_back before salience utility offense.
    if CombatConstants.is_feature_ms_l6_rout_enabled():
        if not CombatFormationRout.rout_layer_blocked(manager, c, actions, combatant_id):
            ## Cognition pressure must be checked BEFORE filtering — a combatant under no rout
            ## pressure should never fire a rout action regardless of what's listed.
            if CombatFormationRout.rout_cognition_pressure(manager, c):
                var rout_pool: Array = CombatFormationRout.filter_rout_disengage_actions(manager, c, combatant_id, actions)
                if not rout_pool.is_empty():
                    return _stamp_layer_pick(
                        c,
                        CombatConstants.MENTAL_STACK_LAYER_ROUT,
                        CombatAIActionPicker.pick_weighted(rout_pool, combatant_id, manager, actions),
                        manager
                    )
    # MS-L9: positional awareness  -  disengage when surrounded and vulnerable.
    # Fight-finish tails skip MS-L9 so listed offense can win via L4b or salience-damped utility pick.
    if CombatConstants.is_feature_ms_positional_awareness_enabled():
        if not CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
            var pos_pool: Array = _positional_disengage_check(manager, combatant_id, actions, c)
            if not pos_pool.is_empty():
                return _stamp_layer_pick(
                    c,
                    CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS,
                    CombatAIActionPicker.pick_weighted(pos_pool, combatant_id, manager),
                    manager
                )
    # L5 (MS-L7): exhaustion tunnel or critical stamina — wait / disengage before salience utility pick.
    # Fight-finish tails skip L5 so listed offense can win via L4b or salience-damped utility pick.
    ## Gradual ramp: disengage preference scales from 0 at tunnel threshold to full at exhausted threshold,
    ## matching the clinical progression where fighters degrade precision before abandoning engagement entirely.
    var tunnel_active: bool = CombatExhaustion.exhaustion_tunnel_active(c)
    var critical_stamina: bool = CombatantEntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
    if tunnel_active or critical_stamina:
        if not CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
            var ex: float = CombatantEntityAccess.exhaustion_float(c)
            if CombatDebug.flow_verbose_enabled():
                var offense_mult: float = CombatExhaustion.exhaustion_offense_weight_mult(c)
                var zone_label: String = "exhausted"
                if not tunnel_active:
                    zone_label = "low_stamina"
                elif ex < CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD + 0.15:
                    zone_label = "fatigued"
                elif ex < CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD:
                    zone_label = "winded"
                CombatDebug.flow_log(
                    (
                        "L5 exhaustion zone=%s ex=%.2f offense_mult=%.3f stamina_ratio=%.2f tunnel=%s crit_stam=%s"
                        % [zone_label, ex, offense_mult, CombatantEntityAccess.stamina_ratio(c), tunnel_active, critical_stamina]
                    )
                )
            if tunnel_active:
                ## Scale disengage preference by how far the combatant is into exhaustion — at threshold just barely prefer it,
                ## at exhausted threshold fully commit. This prevents the binary flip from 0.54→0.55 where behavior jumps
                ## from "full offense" to "must disengage."
                var span: float = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD - CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
                var tunnel_fraction: float = clampf((ex - CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD) / span, 0.0, 1.0)
                ## Only force disengage when tunnel fraction is meaningful (>10% into exhaustion tunnel).
                ## Below that threshold the offense damp in lower layers handles gradual adaptation.
                if tunnel_fraction > 0.3:
                    var disengage: Array = _filter_exhaustion_disengage_actions(actions, combatant_id, manager, c)
                    if not disengage.is_empty():
                        return _stamp_layer_pick(
                            c,
                            CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION,
                            CombatAIActionPicker.pick_weighted(disengage, combatant_id, manager),
                            manager
                        )
            elif critical_stamina:
                ## Critical stamina (no exhaustion): immediate disengage preference since no fatigue memory exists.
                var disengage: Array = _filter_exhaustion_disengage_actions(actions, combatant_id, manager, c)
                if not disengage.is_empty():
                    return _stamp_layer_pick(
                        c,
                        CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION,
                        CombatAIActionPicker.pick_weighted(disengage, combatant_id, manager),
                        manager
                    )
    return {}


static func _stamp_layer_pick(c: Dictionary, layer: String, picked: Dictionary, manager: Node = null) -> Dictionary:
    if picked.is_empty():
        c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
        return picked
    c[CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER] = layer
    ## Phase 3: stamp tier state for persistence tracking.
    _stamp_tier_state(c, layer, manager)
    if CombatDebug.flow_verbose_enabled():
        CombatDebug.flow_log(
            (
                "mental_stack %s layer=%s move=%s"
                % [CombatantEntityAccess.get_display_name(c), layer, picked.get(DataKeys.ACTION_MOVE_ID, "")]
            )
        )
    return picked


static func _filter_coordinated_medical_actions(actions: Array, performer_id: int, manager: Node) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if not CombatConstants.is_medical_move(mid):
            continue
        var tgt_id: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        var part: String = a.get(DataKeys.ACTION_TARGET_PART, "")
        if CombatMedicalCoordination.medical_action_allowed(manager, performer_id, tgt_id, part, mid):
            out.append(a)
    return out


static func _filter_self_medical_actions(actions: Array, combatant_id: int, manager: Node) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(DataKeys.ACTION_TARGET_ID, -1) != combatant_id:
            continue
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if not CombatConstants.is_medical_move(mid):
            continue
        var part: String = a.get(DataKeys.ACTION_TARGET_PART, "")
        if CombatMedicalCoordination.medical_action_allowed(manager, combatant_id, combatant_id, part, mid):
            out.append(a)
    return out


## Fallback for immediate-peril self-medical: allow any self-targeted medical move
## when coordination checks fail (e.g. harness tests where bleeding rate detection fails).
static func _filter_self_medical_actions_fallback(actions: Array, combatant_id: int) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(DataKeys.ACTION_TARGET_ID, -1) != combatant_id:
            continue
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if CombatConstants.is_medical_move(mid):
            out.append(a)
    return out


## Fallback for immediate-peril ally-medical: allow any ally-targeted medical move
## when coordination checks fail (same root cause as self-medical fallback).
static func _filter_ally_medical_actions_fallback(actions: Array, combatant_id: int, manager: Node) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if not CombatConstants.is_medical_move(mid):
            continue
        var tgt_id: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tgt_id == combatant_id:
            continue  # skip self-medical (handled by L0)
        var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
        if c.is_empty():
            continue
        var tgt_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tgt_id)
        if tgt_c.is_empty():
            continue
        if CombatantEntityAccess.side_str(tgt_c) != CombatantEntityAccess.side_str(c):
            continue  # skip enemy medical
        out.append(a)
    return out


static func _filter_counter_tempo_actions(actions: Array) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
            out.append(a)
    return out


static func _filter_hold_line_actions(actions: Array) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
            out.append(a)
    return out


## L4G: focus-line actions that align the blade to the guard-priority target line.
static func _filter_guard_priority_actions(actions: Array, target_line: String) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if not CombatConstants.is_focus_line_move(mid):
            continue
        if CombatConstants.guard_line_for_focus_move_id(mid) == target_line:
            out.append(a)
    return out


static func _filter_sparse_fight_first_actions(
    actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
    var out: Array = []
    for raw in _filter_hold_line_close_actions(actions, combatant_id, manager, c):
        out.append(raw)
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if mid.is_empty() or mid == CombatConstants.MOVE_ID_WAIT:
            continue
        if CombatConstants.is_focus_line_move(mid):
            continue
        if CombatConstants.is_formation_movement_move(mid):
            continue
        if CombatConstants.is_medical_move(mid):
            continue
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tid: int = CombatListedActions.entry_target_id(a, combatant_id)
        if tid == combatant_id:
            continue
        if not CombatListedActions.first_action_move_vs_target(out, mid, tid).is_empty():
            continue
        out.append(a)
    return out


static func _filter_hold_line_close_actions(actions: Array, combatant_id: int, manager: Node, c: Dictionary) -> Array:
    var trust_menu_close: bool = CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id)
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(DataKeys.ACTION_MOVE_ID, "") != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tgt_id: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tgt_id < 0:
            continue
        var dist: String = CombatantEntityAccess.distance_to_opponent_band(c, tgt_id, "")
        var close_listed: bool = CombatMeleeListing.attempt_close_listed_for_pair(manager, c, tgt_id, dist)
        if not close_listed and dist == CombatConstants.DISTANCE_LONG:
            close_listed = CombatDoctrine.envelop_close_allowed(manager, c, tgt_id)
        if not close_listed and trust_menu_close:
            close_listed = true
        if not close_listed:
            continue
        if CombatMeleeListing.close_attempt_pair_blocked(manager, c, tgt_id) and not trust_menu_close:
            continue
        if dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID:
            if CombatListedActions.action_list_has_hostile_melee_strike(actions, combatant_id):
                continue
            # CLOSE/MID without listed strikes: only mop-up may need another close (band/reach gap).
            if not CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c)):
                continue
        out.append(a)
    return out


## Reserve posture: default **`wait`**; focus when incoming telegraph needs retarget; **`attempt_close`** when
## `hold_line_close_pick_eligible` (wing lacks map, pincer flank, or III-4 **3e** mop-up).
static func _pick_hold_line_action(actions: Array, combatant_id: int, manager: Node, c: Dictionary) -> Dictionary:
    var hold: Array = _filter_hold_line_actions(actions)
    if hold.is_empty():
        return {}
    var wait_pick: Dictionary = {}
    var focus_pool: Array = []
    var cur_line: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
    for raw in hold:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if mid == CombatConstants.MOVE_ID_WAIT:
            wait_pick = a.duplicate()
            continue
        if CombatConstants.is_focus_line_move(mid):
            var line: String = CombatConstants.guard_line_for_focus_move_id(mid)
            if line != cur_line:
                focus_pool.append(a)
    if not focus_pool.is_empty():
        var focus_lines: PackedStringArray = PackedStringArray()
        for a in focus_pool:
            focus_lines.append(CombatConstants.guard_line_for_focus_move_id(a.get(DataKeys.ACTION_MOVE_ID, "")))
        CombatDebug.flow_log_event(
            "focus_pool id=%d count=%d lines=[%s] cur_line=%s" % [
                combatant_id, focus_pool.size(), ", ".join(focus_lines), cur_line
            ],
            "focus_pool:%d" % combatant_id
        )
    var close_pool: Array = _filter_hold_line_close_actions(actions, combatant_id, manager, c)
    var close_eligible: bool = not close_pool.is_empty() and CombatDoctrine.hold_line_close_pick_eligible(manager, c)
    # III-4 **3e** / fight-finish: close beats focus shuffle when finishing the last enemy or sparse tail.
    if (
        close_eligible
        and (
            CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c))
            or CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id)
        )
    ):
        return CombatAIActionPicker.pick_weighted(close_pool, combatant_id, manager)
    if not focus_pool.is_empty() and _hold_line_needs_focus_retarget(manager, combatant_id, c):
        var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
        var tele_line: String = str(CombatConstants.PART_TO_LINE.get(tele, "")).strip_edges()
        for raw in focus_pool:
            var a: Dictionary = raw
            if CombatConstants.guard_line_for_focus_move_id(a.get(DataKeys.ACTION_MOVE_ID, "")) == tele_line:
                return a.duplicate()
        return CombatAIActionPicker.pick_weighted(focus_pool, combatant_id, manager)
    if wait_pick.is_empty():
        if close_eligible:
            return CombatAIActionPicker.pick_weighted(close_pool, combatant_id, manager)
        return CombatAIActionPicker.pick_weighted(hold, combatant_id, manager)
    if close_eligible:
        return CombatAIActionPicker.pick_weighted(close_pool, combatant_id, manager)
    return wait_pick


static func _hold_line_needs_focus_retarget(manager: Node, combatant_id: int, c: Dictionary) -> bool:
    if not CombatAttention.is_being_wind_up_targeted(manager, combatant_id):
        return false
    var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
    if tele.is_empty():
        return false
    var tele_line: String = str(CombatConstants.PART_TO_LINE.get(tele, "")).strip_edges()
    if tele_line.is_empty():
        return false
    var cur_line: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
    return tele_line != cur_line


static func _filter_incoming_threat_actions(actions: Array, incoming_attacker_id: int) -> Array:
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
            out.append(a)
            continue
        if incoming_attacker_id >= 0 and a.get(DataKeys.ACTION_TARGET_ID, -1) == incoming_attacker_id:
            var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
            if CombatConstants.is_medical_move(mid):
                continue
            if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
                continue
            out.append(a)
    return out


static func _filter_exhaustion_disengage_actions(
    actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
    var flee_listed: bool = false
    for raw in actions:
        if raw is not Dictionary:
            continue
        var probe: Dictionary = raw
        if probe.get(DataKeys.ACTION_MOVE_ID, "") == CombatConstants.MOVE_ID_FLEE and probe.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id:
            flee_listed = true
            break
    var block_formation_shuffle: bool = (
        manager != null
        and not c.is_empty()
        and CombatListedActions.action_list_has_hostile_strike(actions, combatant_id)
        and CombatantEntityAccess.rank_int(c) == 0
    )
    var out: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        if mid == CombatConstants.MOVE_ID_WAIT:
            out.append(a)
            continue
        if mid == CombatConstants.MOVE_ID_FLEE and a.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id:
            if not CombatFormationRout.duel_flee_allowed_for_action(manager, c, mid):
                continue
            out.append(a)
            continue
        if (
            flee_listed
            and (
                mid
                in [
                    CombatConstants.MOVE_ID_ROTATE_FILE,
                    CombatConstants.MOVE_ID_SWAP_RANK,
                    CombatConstants.MOVE_ID_DRAG_BACK,
                ]
            )
        ):
            continue
        if (
            block_formation_shuffle
            and (
                mid
                in [
                    CombatConstants.MOVE_ID_FALL_BACK,
                    CombatConstants.MOVE_ID_ROTATE_FILE,
                    CombatConstants.MOVE_ID_SWAP_RANK,
                    CombatConstants.MOVE_ID_DRAG_BACK,
                ]
            )
        ):
            continue
        if block_formation_shuffle and CombatConstants.is_focus_line_move(mid):
            continue
        if (
            mid
            in [
                CombatConstants.MOVE_ID_FALL_BACK,
                CombatConstants.MOVE_ID_ROTATE_FILE,
                CombatConstants.MOVE_ID_SWAP_RANK,
                CombatConstants.MOVE_ID_DRAG_BACK,
            ]
        ):
            out.append(a)
            continue
        if CombatConstants.is_focus_line_move(mid):
            out.append(a)
    return out


## MS-L9: positional awareness  -  returns weighted disengage array when combatant is surrounded and vulnerable.
## Returns empty when not surrounded OR when combatant is healthy (blood >= L9 threshold AND NOT exhausted tunnel).
## Only fires when actual disengage moves (fall_back/flee) exist  -  does not force wait over utility pick.
static func _positional_disengage_check(manager: Node, combatant_id: int, actions: Array, c: Dictionary) -> Array:
    if not ZoneOfControl.is_combatant_surrounded(manager, combatant_id):
        return []
    # Check vulnerability: must be wounded (blood < L9 threshold) OR exhausted (tunnel active).
    # Reads from entity node (not stats dict) so it works in harness tests where CombatantStatsSync
    # may not have re-synced after wounds are applied post-registration.
    var node: Variant = CombatantEntityAccess.node_variant(c)
    var blood: float = CombatantEntityAccess.get_blood_volume_from_node(node as Node)
    var exhausted_t: bool = CombatExhaustion.exhaustion_tunnel_active(c)
    if blood >= CombatConstants.MENTAL_STACK_L9_VULNERABILITY_BLOOD_THRESHOLD and not exhausted_t:
        return []
    # Build disengage pool: fall_back first, flee second, wait third.
    var out: Array = []
    var fall_backs: Array = []
    var flees: Array = []
    var waits: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
        match mid:
            CombatConstants.MOVE_ID_FALL_BACK:
                fall_backs.append(a)
            CombatConstants.MOVE_ID_FLEE:
                if (
                    a.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id
                    and CombatFormationRout.duel_flee_allowed_for_action(manager, c, mid)
                ):
                    flees.append(a)
            CombatConstants.MOVE_ID_WAIT:
                waits.append(a)
    # Only fire when actual disengage moves exist  -  do not force wait over utility pick.
    if fall_backs.is_empty() and flees.is_empty():
        return []
    out.append_array(fall_backs)
    out.append_array(flees)
    out.append_array(waits)
    return out


## Phase 3: tier persistence — check if a previously fired tier should persist into the current tick.
static func _tier_is_persistent(c: Dictionary, manager: Node) -> bool:
    if not c.has(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE):
        return false
    var state: Dictionary = c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] as Dictionary
    if state.is_empty():
        return false
    var entered_at: float = state.get(CombatConstantsMentalStack._TIER_ENTERED_AT, 0.0)
    var active_tier: String = state.get(CombatConstantsMentalStack._TIER_ACTIVE, "")
    if active_tier.is_empty():
        return false
    var clk: float = manager.combat_clock
    var commitment: int = CombatConstantsMentalStack.MENTAL_STACK_TIER_COMMITMENT_TICKS
    if float(entered_at) + commitment > clk:
        return true
    ## Expired — clear stale state.
    c.erase(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE)
    return false


## Phase 3: reconstruct a result from the persistent tier when conditions still match.
static func _tier_get_persistent_result(c: Dictionary, actions: Array, combatant_id: int, manager: Node) -> Dictionary:
    if not c.has(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE):
        return {}
    var state: Dictionary = c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] as Dictionary
    if state.is_empty():
        return {}
    var active_tier: String = state.get(CombatConstantsMentalStack._TIER_ACTIVE, "")
    ## Only persist non-transient tiers (plug, rout, post-strike).
    var valid_persistent_tiers: PackedStringArray = [
        CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG,
        CombatConstants.MENTAL_STACK_LAYER_ROUT,
        CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE,
    ]
    if not active_tier in valid_persistent_tiers:
        return {}
    ## Verify conditions still hold before persisting.
    match active_tier:
        CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG:
            if CombatFormationVacancyPlugs.formation_plug_layer_blocked(manager, c, actions, combatant_id):
                return {}
            var plug_pool: Array = CombatFormationVacancyPlugs.filter_formation_plug_actions(manager, c, combatant_id, actions)
            if plug_pool.is_empty():
                return {}
            var coh_mod_persist: float = CombatMoraleCohesion._compute_cohesion_modifier(combatant_id, manager)
            for _pi in range(plug_pool.size()):
                var _pa: Dictionary = plug_pool[_pi] as Dictionary
                if _pa is Dictionary and not _pa.is_empty():
                    var _bw: float = _pa.get(DataKeys.ACTION_WEIGHT, 1.0)
                    _pa[DataKeys.ACTION_WEIGHT] = _bw * coh_mod_persist
            return _stamp_layer_pick(c, active_tier, CombatAIActionPicker.pick_weighted(plug_pool, combatant_id, manager, actions), manager)
        CombatConstants.MENTAL_STACK_LAYER_ROUT:
            if not CombatFormationRout.rout_cognition_pressure(manager, c):
                return {}
            var rout_pool: Array = CombatFormationRout.filter_rout_disengage_actions(manager, c, combatant_id, actions)
            if rout_pool.is_empty():
                return {}
            return _stamp_layer_pick(c, active_tier, CombatAIActionPicker.pick_weighted(rout_pool, combatant_id, manager, actions), manager)
        CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE:
            var strike_tick_val: float = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0)
            var current_clock: float = manager.combat_clock
            if not (strike_tick_val >= 0.0 and absf(strike_tick_val - current_clock) < CombatConstants.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE):
                return {}
            var struck_id: int = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID, -1)
            if struck_id < 0:
                return {}
            var ps_pool: Array = CombatPostStrike.filter_post_strike_actions(actions, combatant_id, manager, struck_id)
            if ps_pool.is_empty():
                return {}
            return _stamp_layer_pick(c, active_tier, CombatAIActionPicker.pick_weighted(ps_pool, combatant_id, manager), manager)
    return {}


## Phase 3: stamp tier state after a layer fires (records current clock for persistence window).
static func _stamp_tier_state(c: Dictionary, layer: String, manager: Node = null) -> void:
    var entered_at: float = 0.0
    if manager != null and "combat_clock" in manager:
        entered_at = manager.combat_clock
    c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] = {
        CombatConstantsMentalStack._TIER_ACTIVE: layer,
        CombatConstantsMentalStack._TIER_ENTERED_AT: entered_at,
        CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES: 0,
    }


## Phase 3: increment consecutive failure count when a tier fails to fire despite matching conditions.
static func _increment_tier_failure(c: Dictionary) -> void:
    if not c.has(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE):
        c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] = {
            CombatConstantsMentalStack._TIER_ACTIVE: "",
            CombatConstantsMentalStack._TIER_ENTERED_AT: 0.0,
            CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES: 0,
        }
    var state: Dictionary = c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] as Dictionary
    state[CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES] = int(state.get(CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES, 0)) + 1


## Phase 3: get consecutive failure count for transition guards.
static func _get_tier_consecutive_failures(c: Dictionary) -> int:
    if not c.has(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE):
        return 0
    var state: Dictionary = c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] as Dictionary
    return int(state.get(CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES, 0))


## Phase 3: reset consecutive failure count after a successful tier fire.
static func _reset_tier_failures(c: Dictionary) -> void:
    if not c.has(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE):
        return
    var state: Dictionary = c[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] as Dictionary
    state[CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES] = 0


## Phase 3: increment guard break count for L6 rout trigger.
static func _record_guard_break(c: Dictionary) -> void:
    var current: int = int(c.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_BREAK_COUNT, 0))
    c[CombatConstantsMentalStack.COMBATANT_KEY_GUARD_BREAK_COUNT] = current + 1


## Phase 3: reset guard break count on a successful action.
static func _reset_guard_breaks(c: Dictionary) -> void:
    c[CombatConstantsMentalStack.COMBATANT_KEY_GUARD_BREAK_COUNT] = 0
