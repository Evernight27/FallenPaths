class_name MentalStackLayers
extends RefCounted

## Mental-stack layer filtering + tier-state persistence extracted from MentalStackDecider
## (pure code-motion split). MentalStackDecider.try_pick remains the orchestrator; these are the
## leaf action-filter and tier/guard-break bookkeeping helpers it delegates to.


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
            (
                "focus_pool id=%d count=%d lines=[%s] cur_line=%s"
                % [combatant_id, focus_pool.size(), ", ".join(focus_lines), cur_line]
            ),
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
        if (
            probe.get(DataKeys.ACTION_MOVE_ID, "") == CombatConstants.MOVE_ID_FLEE
            and probe.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id
        ):
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
            var plug_pool: Array = CombatFormationVacancyPlugs.filter_formation_plug_actions(
                manager, c, combatant_id, actions
            )
            if plug_pool.is_empty():
                return {}
            var coh_mod_persist: float = CombatMoraleCohesion._compute_cohesion_modifier(combatant_id, manager)
            for _pi in range(plug_pool.size()):
                var pa: Dictionary = plug_pool[_pi] as Dictionary
                if pa is Dictionary and not pa.is_empty():
                    var bw: float = pa.get(DataKeys.ACTION_WEIGHT, 1.0)
                    pa[DataKeys.ACTION_WEIGHT] = bw * coh_mod_persist
            return _stamp_layer_pick(
                c, active_tier, CombatAIActionPicker.pick_weighted(plug_pool, combatant_id, manager, actions), manager
            )
        CombatConstants.MENTAL_STACK_LAYER_ROUT:
            if not CombatFormationRout.rout_cognition_pressure(manager, c):
                return {}
            var rout_pool: Array = CombatFormationRout.filter_rout_disengage_actions(manager, c, combatant_id, actions)
            if rout_pool.is_empty():
                return {}
            return _stamp_layer_pick(
                c, active_tier, CombatAIActionPicker.pick_weighted(rout_pool, combatant_id, manager, actions), manager
            )
        CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE:
            var strike_tick_val: float = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0)
            var current_clock: float = manager.combat_clock
            if not (
                strike_tick_val >= 0.0
                and absf(strike_tick_val - current_clock) < CombatConstants.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE
            ):
                return {}
            var struck_id: int = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID, -1)
            if struck_id < 0:
                return {}
            var ps_pool: Array = CombatPostStrike.filter_post_strike_actions(actions, combatant_id, manager, struck_id)
            if ps_pool.is_empty():
                return {}
            return _stamp_layer_pick(
                c, active_tier, CombatAIActionPicker.pick_weighted(ps_pool, combatant_id, manager), manager
            )
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
    state[CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES] = (
        int(state.get(CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES, 0)) + 1
    )


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
