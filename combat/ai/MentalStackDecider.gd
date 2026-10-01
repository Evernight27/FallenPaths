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
        fight_finish_tail = (
            CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id)
            or esc_failures >= CombatConstantsMentalStack.MENTAL_STACK_L1_TO_L2_FAILURE_THRESHOLD
        )
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
        and CombatAttention.guard_priority_score(manager, c) >= CombatConstantsMentalStack.GUARD_PRIORITY_MIN_SCORE
    ):
        var gp_target: String = (
            str(c.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE, "")).strip_edges()
        )
        if gp_target.is_empty():
            gp_target = CombatAttention.guard_priority_target_line(manager, c)
        if not gp_target.is_empty():
            var cur_line_gp: String = (
                str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
            )
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
                var rout_pool: Array = CombatFormationRout.filter_rout_disengage_actions(
                    manager, c, combatant_id, actions
                )
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
                        % [
                            zone_label,
                            ex,
                            offense_mult,
                            CombatantEntityAccess.stamina_ratio(c),
                            tunnel_active,
                            critical_stamina
                        ]
                    )
                )
            if tunnel_active:
                ## Scale disengage preference by how far the combatant is into exhaustion — at threshold just barely
                ## prefer it,
                ## at exhausted threshold fully commit. This prevents the binary flip from 0.54→0.55 where behavior
                ## jumps
                ## from "full offense" to "must disengage."
                var span: float = (
                    CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD
                    - CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
                )
                var tunnel_fraction: float = clampf(
                    (ex - CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD) / span, 0.0, 1.0
                )
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


## Mental-stack layer filters + tier-state helpers extracted to MentalStackLayers (pure code-motion split).
## The thin delegates below keep existing call sites (try_pick + external) unchanged.


static func _stamp_layer_pick(c: Dictionary, layer: String, picked: Dictionary, manager: Node = null) -> Dictionary:
    return MentalStackLayers._stamp_layer_pick(c, layer, picked, manager)


static func _filter_coordinated_medical_actions(actions: Array, performer_id: int, manager: Node) -> Array:
    return MentalStackLayers._filter_coordinated_medical_actions(actions, performer_id, manager)


static func _filter_self_medical_actions(actions: Array, combatant_id: int, manager: Node) -> Array:
    return MentalStackLayers._filter_self_medical_actions(actions, combatant_id, manager)


static func _filter_self_medical_actions_fallback(actions: Array, combatant_id: int) -> Array:
    return MentalStackLayers._filter_self_medical_actions_fallback(actions, combatant_id)


static func _filter_ally_medical_actions_fallback(actions: Array, combatant_id: int, manager: Node) -> Array:
    return MentalStackLayers._filter_ally_medical_actions_fallback(actions, combatant_id, manager)


static func _filter_counter_tempo_actions(actions: Array) -> Array:
    return MentalStackLayers._filter_counter_tempo_actions(actions)


static func _filter_hold_line_actions(actions: Array) -> Array:
    return MentalStackLayers._filter_hold_line_actions(actions)


static func _filter_guard_priority_actions(actions: Array, target_line: String) -> Array:
    return MentalStackLayers._filter_guard_priority_actions(actions, target_line)


static func _filter_sparse_fight_first_actions(
    actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
    return MentalStackLayers._filter_sparse_fight_first_actions(actions, combatant_id, manager, c)


static func _filter_hold_line_close_actions(actions: Array, combatant_id: int, manager: Node, c: Dictionary) -> Array:
    return MentalStackLayers._filter_hold_line_close_actions(actions, combatant_id, manager, c)


static func _pick_hold_line_action(actions: Array, combatant_id: int, manager: Node, c: Dictionary) -> Dictionary:
    return MentalStackLayers._pick_hold_line_action(actions, combatant_id, manager, c)


static func _hold_line_needs_focus_retarget(manager: Node, combatant_id: int, c: Dictionary) -> bool:
    return MentalStackLayers._hold_line_needs_focus_retarget(manager, combatant_id, c)


static func _filter_incoming_threat_actions(actions: Array, incoming_attacker_id: int) -> Array:
    return MentalStackLayers._filter_incoming_threat_actions(actions, incoming_attacker_id)


static func _filter_exhaustion_disengage_actions(
    actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
    return MentalStackLayers._filter_exhaustion_disengage_actions(actions, combatant_id, manager, c)


static func _positional_disengage_check(manager: Node, combatant_id: int, actions: Array, c: Dictionary) -> Array:
    return MentalStackLayers._positional_disengage_check(manager, combatant_id, actions, c)


static func _tier_is_persistent(c: Dictionary, manager: Node) -> bool:
    return MentalStackLayers._tier_is_persistent(c, manager)


static func _tier_get_persistent_result(c: Dictionary, actions: Array, combatant_id: int, manager: Node) -> Dictionary:
    return MentalStackLayers._tier_get_persistent_result(c, actions, combatant_id, manager)


static func _stamp_tier_state(c: Dictionary, layer: String, manager: Node = null) -> void:
    MentalStackLayers._stamp_tier_state(c, layer, manager)


static func _increment_tier_failure(c: Dictionary) -> void:
    MentalStackLayers._increment_tier_failure(c)


static func _get_tier_consecutive_failures(c: Dictionary) -> int:
    return MentalStackLayers._get_tier_consecutive_failures(c)


static func _reset_tier_failures(c: Dictionary) -> void:
    MentalStackLayers._reset_tier_failures(c)


static func _record_guard_break(c: Dictionary) -> void:
    MentalStackLayers._record_guard_break(c)


static func _reset_guard_breaks(c: Dictionary) -> void:
    MentalStackLayers._reset_guard_breaks(c)
