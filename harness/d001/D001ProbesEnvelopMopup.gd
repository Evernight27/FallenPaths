class_name D001ProbesEnvelopMopup
extends RefCounted
## III-4 **3e** mop-up probes: deterministic 7v1 attrition slice + rear-rank reserve smoke.


## III-4 **3e**: deterministic 7v1 attrition slice — `engagement_debug` mop_up + hold-line hint smoke.
static func probe_ii_envelop_mopup_engagement_debug(preset_id: String) -> void:
    OperationalLog.play_combat("soak_setup ii_envelop_mopup 3e attrition smoke (engagement_debug mop_up)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var player_form: Dictionary = FormationPreset.for_front_count(7, 7, FormationPreset.DENSITY_NORMAL)
    var enemy_form: Dictionary = {"files": 3, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(preset_id, 7, 3, player_form, enemy_form, false)
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        D001Ii5Ii6RunnerTests._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup skip envelop_mop_up_active=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var actor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 3)
    if actor.is_empty():
        actor = D001RunnerHelpers._first_alive_player_front_rank(mgr)
    var enemy_left: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy_left = c
            break
    if actor.is_empty() or enemy_left.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_mopup skip missing actor/enemy")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var actor_id: int = CombatantEntityAccess.id_int(actor)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy_left)
    actor["gauge"] = 100.0
    actor["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(actor_id)
    var choice: Dictionary = {}
    for raw in acts:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw as Dictionary
        if (
            str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
            and int(a.get("target_id", -1)) == enemy_id
        ):
            choice = a.duplicate()
            break
    if choice.is_empty():
        for raw in acts:
            if raw is not Dictionary:
                continue
            var a: Dictionary = raw as Dictionary
            if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
                choice = a.duplicate()
                break
    if choice.is_empty():
        choice = {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id}
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, actor_id, acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, actor, acts)
    var hold_hint: String = str(actor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if hold_hint.contains("Mop-up"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup hold_line_hint_ok")
    # 3e strike-finish: CLOSE + listed melee -> `engagement_debug` strikes_listed line for validator/F5.
    var strike_actor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 3)
    if strike_actor.is_empty():
        strike_actor = actor
    var strike_id: int = CombatantEntityAccess.id_int(strike_actor)
    var dist_strike: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(strike_actor, "distance_to")
    dist_strike[enemy_id] = CombatConstants.DISTANCE_CLOSE
    var dist_enemy: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(enemy_left, "distance_to")
    dist_enemy[strike_id] = CombatConstants.DISTANCE_CLOSE
    strike_actor["gauge"] = 100.0
    strike_actor["state"] = CombatConstants.STATE_WAITING
    var strike_acts: Array = mgr.get_available_actions(strike_id)
    var strike_choice: Dictionary = D001RunnerHelpers._first_hostile_melee_strike_action(strike_acts, strike_id)
    if not strike_choice.is_empty():
        CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, strike_id, strike_acts, strike_choice)
        CombatPlayerTurnHints.emit_turn_ready_hints(mgr, strike_actor, strike_acts)
        CombatF5SoakTrace.log_turn_ready_player_ui(mgr, strike_actor, strike_acts)
        var strike_hold: String = (
            str(strike_actor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
        )
        if strike_hold.contains("Mop-up"):
            OperationalLog.play_combat("soak_setup ii_envelop_mopup strike_hold_line_hint_ok")
        OperationalLog.play_combat("soak_setup ii_envelop_mopup strike_finish_ok")
    else:
        CombatF5SoakTrace.log_turn_ready_player_ui(mgr, actor, acts)
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up (7x2 line).
static func probe_ii_envelop_mopup_rear_rank_hint() -> void:
    OperationalLog.play_combat("soak_setup ii_envelop_mopup rear rank hold-line smoke (7x2 reserve + close)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var mgr: Node = CombatManager.new()
    for _i in 14:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 7, "ranks": 2, "density": FormationPreset.DENSITY_NORMAL},
        {"files": 3, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
    )
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        D001Ii5Ii6RunnerTests._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear skip envelop_mop_up_active=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var rear: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 1, 3)
    if rear.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear skip missing rank-1 fixture")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var enemy_left: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy_left = c
            break
    if enemy_left.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear skip missing enemy")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy_left)
    rear["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, rear, acts)
    var hold_hint: String = str(rear.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if hold_hint.contains("Mop-up"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear_hold_line_hint_ok")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)
