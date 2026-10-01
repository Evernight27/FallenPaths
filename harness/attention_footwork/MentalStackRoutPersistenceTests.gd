class_name MentalStackRoutPersistenceTests

extends MentalStackFormationPlugBase

## Mental-stack rout + persistence: stressed/casualty flee-beats-strike and
## flee-beats-wait, tier-persistence plug, cohesion modifier banner, L6 rout
## guard-break threshold and the L2 transition guard.


static func _run_mental_stack_rout_stressed_flee_beats_strike(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 1, "ranks": 2}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var front_c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front_c) as CoreEntity
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    ent.blood_volume = 82.0
    form["line_cohesion"] = 0.38
    form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
    if not CombatantEntityAccess.flee_abandonment_warranted(front_c, mgr):
        _fail(failures, "mental_stack_rout_stress: want abandonment warranted")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var fighter_id: int = CombatantEntityAccess.id_int(front_c)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        _fail(failures, "mental_stack_rout_stress: expected rout layer pick")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if (
        str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != (CombatConstants.MENTAL_STACK_LAYER_ROUT)
    ):
        _fail(
            failures,
            (
                "mental_stack_rout_stress: want rout got %s"
                % str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
        _fail(failures, "mental_stack_rout_stress: want flee got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L6: heavy side casualties -> **`flee`** beats **`wait`**; stamps **`rout`**.

## MS-L6: heavy side casualties -> **`flee`** beats **`wait`**; stamps **`rout`**.


static func _run_mental_stack_rout_casualty_flee_beats_wait(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 1, "ranks": 2}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    form["line_cohesion"] = 0.9
    form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
    var rear_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    HarnessFixtures._soak_kill_combatant(mgr, rear_id)
    var front_c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front_c) as CoreEntity
    ent.blood_volume = 82.0
    if not FormationRout.rout_cognition_pressure(mgr, front_c):
        _fail(failures, "mental_stack_rout_casualty: want rout pressure")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var fighter_id: int = CombatantEntityAccess.id_int(front_c)
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if (
        str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != (CombatConstants.MENTAL_STACK_LAYER_ROUT)
    ):
        _fail(
            failures,
            (
                "mental_stack_rout_casualty: want rout got %s"
                % str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
        _fail(failures, "mental_stack_rout_casualty: want flee got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L6: fight-finish tail must not stamp **`rout`** when listed offense should finish.

## Phase 3: tier persistence — plug layer persists across ticks within commitment window.


static func _run_mental_stack_tier_persistence_plug(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _fail(failures, "mental_stack_tier_persist_plug: missing fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _fail(failures, "mental_stack_tier_persist_plug: want rank-0 hole")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    rear["gauge"] = 100.0
    mgr.combat_clock = 1.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.actions_include_move_vs_target(
        acts, CombatantEntityAccess.id_int(front), CombatConstants.MOVE_ID_SWAP_RANK
    ):
        _fail(failures, "mental_stack_tier_persist_plug: want swap_rank listed")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, rear_id, mgr)
    if picked.is_empty():
        _fail(failures, "mental_stack_tier_persist_plug: expected first pick")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        _fail(
            failures,
            "mental_stack_tier_persist_plug: want swap_rank on first pick got %s" % str(picked.get("move_id", ""))
        )
    var tier_state: Dictionary = rear.get(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE, {})
    if tier_state.is_empty():
        _fail(failures, "mental_stack_tier_persist_plug: want tier state stamped")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var entered_at: float = tier_state.get(CombatConstantsMentalStack._TIER_ENTERED_AT, 0.0)
    if entered_at <= 0.0:
        _fail(failures, "mental_stack_tier_persist_plug: want non-zero entered_at")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var persistent_acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": CombatantEntityAccess.id_int(front)},
    ]
    mgr.combat_clock = entered_at + 1.0
    var second_pick: Dictionary = MentalStack.try_pick(persistent_acts, rear_id, mgr)
    if second_pick.is_empty():
        _fail(failures, "mental_stack_tier_persist_plug: want persistent pick within window")
    elif str(second_pick.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        _fail(
            failures,
            (
                "mental_stack_tier_persist_plug: want swap_rank on persistent pick got %s"
                % str(second_pick.get("move_id", ""))
            )
        )
    mgr.combat_clock = entered_at + float(CombatConstantsMentalStack.MENTAL_STACK_TIER_COMMITMENT_TICKS) + 1.0
    var expired_acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": CombatantEntityAccess.id_int(front)},
    ]
    var third_pick: Dictionary = MentalStack.try_pick(expired_acts, rear_id, mgr)
    var tier_state_after: Dictionary = rear.get(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE, {})
    if not tier_state_after.is_empty():
        var new_entered_at: float = tier_state_after.get(CombatConstantsMentalStack._TIER_ENTERED_AT, 0.0)
        if abs(new_entered_at - entered_at) < 0.01:
            _fail(
                failures,
                (
                    (
                        "mental_stack_tier_persist_plug: want expired tier state re-stamped with old clock but got "
                        + "entered_at=%.2f"
                    )
                    % new_entered_at
                )
            )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Phase 3: cohesion modifier — plug actions get bonus when nearby allies present and banner carrier alive.


static func _run_mental_stack_cohesion_modifier_nearby_banner(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if rear.is_empty():
        _fail(failures, "cohesion_modifier_nearby: missing rear fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var modifier: float = CombatMoraleCohesion._compute_cohesion_modifier(CombatantEntityAccess.id_int(rear), mgr)
    if modifier < 1.0:
        _fail(failures, "cohesion_modifier_nearby: want modifier >= 1.0 got %s" % str(modifier))
    rear["banner_carrier"] = true
    var form_player: Dictionary = mgr.formations["player"]
    form_player["morale_cohesion_factor"] = 1.0
    modifier = CombatMoraleCohesion._compute_cohesion_modifier(CombatantEntityAccess.id_int(rear), mgr)
    if modifier < 1.1:
        _fail(failures, "cohesion_modifier_banner: want banner bonus >= 1.1 got %s" % str(modifier))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Phase 3: L6 rout trigger via consecutive guard breaks — guard_break_count reaches threshold -> rout layer fires.


static func _run_mental_stack_l6_rout_guard_break_threshold(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if front.is_empty():
        _fail(failures, "l6_rout_guard_break: missing front fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    if ent != null:
        ent.blood_volume = 48.0
    for _k in range(CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD):
        MentalStackDecider._record_guard_break(front)
    var gb_count: int = front.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_BREAK_COUNT, 0)
    if gb_count != CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD:
        _fail(
            failures,
            (
                "l6_rout_guard_break: want %d guard breaks got %d"
                % [CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD, gb_count]
            )
        )
    front["gauge"] = 100.0
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[7]) if mgr.combatants.size() > 7 else -1
    if enemy_id < 0:
        for c in mgr.combatants:
            if CombatantEntityAccess.is_living_on_side(c, "enemy"):
                enemy_id = CombatantEntityAccess.id_int(c)
                break
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": front_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": front_id},
    ]
    if enemy_id >= 0:
        actions.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
    var picked: Dictionary = MentalStack.try_pick(actions, front_id, mgr)
    if (
        not picked.is_empty()
        and (
            str(front.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            == CombatConstants.MENTAL_STACK_LAYER_ROUT
        )
    ):
        pass
    else:
        if picked.is_empty():
            var layer: String = str(front.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            _fail(failures, "l6_rout_guard_break: expected rout pick got empty layer=%s" % layer)
        else:
            _fail(
                failures,
                (
                    "l6_rout_guard_break: want rout layer got %s"
                    % str(front.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
                )
            )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Phase 4: attention budget degrades excess targets — top N get full weight, beyond-N get degraded.


static func _run_mental_stack_l2_transition_guard(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty():
        _fail(failures, "l2_transition_guard: missing fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    rear["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var enemy_atk: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_atk = c
            break
    if enemy_atk.is_empty():
        _fail(failures, "l2_transition_guard: missing enemy attacker")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var atk_id: int = CombatantEntityAccess.id_int(enemy_atk)
    for enemy in mgr.combatants:
        if CombatantEntityAccess.side_str(enemy) == "enemy":
            var dist: Dictionary = enemy.get("distance_to", {}) as Dictionary
            dist[rear_id] = CombatConstants.DISTANCE_CLOSE
    AttackWindUpStarter.start(mgr, atk_id, rear_id, "thrust")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    rear[CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL] = mgr.combat_clock + 10.0
    rear[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    if not CounterTempo.can_act(mgr, rear):
        _fail(failures, "l2_transition_guard: want can_act true for counter-tempo fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    rear[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] = {
        CombatConstantsMentalStack._TIER_ACTIVE: "",
        CombatConstantsMentalStack._TIER_ENTERED_AT: mgr.combat_clock - 10.0,
        CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES: 1,
    }
    var acts_with_counters: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {
            "move_id": "parry_high",
            "target_id": rear_id,
            "target_part": "head",
            CombatConstants.ACTION_KEY_COUNTER_TEMPO: true
        },
    ]
    var picked_low: Dictionary = MentalStack.try_pick(acts_with_counters, rear_id, mgr)
    var c_check_low: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, rear_id)
    var layer_low: String = str(c_check_low.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if not picked_low.is_empty() and layer_low == CombatConstants.MENTAL_STACK_LAYER_COUNTER:
        _fail(failures, "l2_transition_guard: guard should block L2 with failures=1")
    rear[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] = {
        CombatConstantsMentalStack._TIER_ACTIVE: "",
        CombatConstantsMentalStack._TIER_ENTERED_AT: mgr.combat_clock - 10.0,
        CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES: 3,
    }
    AttackWindUpStarter.start(mgr, atk_id, rear_id, "thrust")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    rear[CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL] = mgr.combat_clock + 10.0
    rear[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    var picked_high: Dictionary = MentalStack.try_pick(acts_with_counters, rear_id, mgr)
    var c_check: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, rear_id)
    var layer: String = str(c_check.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if (
        not picked_high.is_empty()
        and (
            layer == CombatConstants.MENTAL_STACK_LAYER_COUNTER or layer == CombatConstants.MENTAL_STACK_LAYER_INCOMING
        )
    ):
        pass  ## Guard satisfied -> counter-tempo fires at L2/L3.
    else:
        _fail(
            failures,
            (
                "l2_transition_guard: expected L2/L3 to fire with failures=3 got layer='%s' picked_empty=%s"
                % [layer, str(picked_high.is_empty())]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)
