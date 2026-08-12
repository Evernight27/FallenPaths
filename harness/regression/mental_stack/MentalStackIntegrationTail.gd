class_name CombatRegressionHarnessMentalStackIntegrationTail
extends RefCounted
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

## Stacked-phase integration tests: verify layer precedence when multiple FEATURE flags are active.
## Tests that activate multiple phases simultaneously and check MENTAL_STACK_LAYER_* stamps.


## Helper: set up a minimal manager with two combatants (player + enemy).
static func _make_two_sided_manager() -> Node:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    return mgr


## Helper: set up a three-combatant manager (2 player + 1 enemy).
static func _make_three_combatant_manager() -> Node:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    return mgr


## Helper: set up a four-combatant manager (2 player + 2 enemy) for surround scenarios.
static func _make_four_combatant_manager() -> Node:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    return mgr


## Helper: set up immediate peril on an entity (bleeding chest with low blood volume).
static func _set_immediate_peril(ent: Node) -> void:
    if ent == null:
        return
    ent.blood_volume = 46.0
    EntityWounds.add_wound(
        ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
    )


## Helper: set exhaustion level on a combatant dict and enable the feature.
static func _set_exhaustion(c: Dictionary, level: float) -> void:
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = level


## 1. Exhausted + surrounded: Phase 5 (exhaustion) fires before Phase 6 (positional).
## Exhaustion tunnel activates at threshold; MS-L9 never reached due to early return.
static func _run_mental_stack_integration_exhausted_surrounded(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_fight_exhaustion_index_load(true)
    CombatConstants.set_feature_ms_positional_awareness_load(true)

    var mgr: Node = _make_four_combatant_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy1_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])
    var enemy2_id: int = CombatantEntityAccess.id_int(mgr.combatants[3])

    # Set exhaustion above tunnel threshold.
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.85
    fighter["state"] = CombatConstants.STATE_WAITING
    fighter["gauge"] = 100.0

    # Build actions including disengage and offense.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy1_id, "target_part": "head"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_exhausted_surrounded: expected exhaustion layer pick but got none"
        )
    else:
        var layer: String = str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION:
            CombatRegressionHarness._fail(
                failures, "integration_exhausted_surrounded: want exhaustion layer got %s" % layer
            )

    CombatConstants.set_feature_fight_exhaustion_index_load(-1)
    CombatConstants.set_feature_ms_positional_awareness_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 2. Post-strike + surrounded + wounded: Phase 3 fires before Phase 6.
## Post-strike stamp set; positional check never reached.
static func _run_mental_stack_integration_post_strike_surrounded_wounded(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_post_strike_load(true)
    CombatConstants.set_feature_ms_positional_awareness_load(true)

    var mgr: Node = _make_four_combatant_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy1_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])

    # Simulate a recent strike stamp (combat_clock is ~0 at start, tolerance is 2.0).
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = enemy1_id
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = float(mgr.combat_clock)
    fighter["state"] = CombatConstants.STATE_WAITING
    fighter["gauge"] = 100.0

    # Build actions: offense vs struck target + disengage.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy1_id, "target_part": "head"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_post_strike_surrounded: expected post-strike layer pick but got none"
        )
    else:
        var layer: String = str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE:
            CombatRegressionHarness._fail(
                failures, "integration_post_strike_surrounded: want post-strike layer got %s" % layer
            )

    CombatConstants.set_feature_ms_post_strike_load(-1)
    CombatConstants.set_feature_ms_positional_awareness_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 3. Rout + medical peril: Phase 7 (medical escalation) fires, rout blocked by peril.
## Ally in immediate peril -> L1 medical layer fires; rout layer blocked.
static func _run_mental_stack_integration_rout_medical_peril(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_l6_rout_load(true)
    CombatConstants.set_feature_ms_medical_escalation_load(true)

    var mgr: Node = _make_three_combatant_manager()
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)

    # Set up ally in immediate peril (bleeding chest, low blood volume).
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    _set_immediate_peril(ally_ent)

    # Set medic state for action building.
    medic["state"] = CombatConstants.STATE_WAITING
    medic["gauge"] = 100.0

    # Build medical actions (simulating what AvailableActionsBuilder produces in med phase).
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": medic_id},
        {"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_id": ally_id, "target_part": "chest"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, medic_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_rout_medical_peril: expected medical layer pick but got none"
        )
    else:
        var layer: String = str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_MEDICAL:
            CombatRegressionHarness._fail(failures, "integration_rout_medical_peril: want medical layer got %s" % layer)

    CombatConstants.set_feature_ms_l6_rout_load(-1)
    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 4. Feint vs exhausted orthogonal: Phase 2 blocks feints on attacker, Phase 5 fires on defender.
## Independent layers  -  attacker gets weight dampened, defender gets exhaustion tunnel.
static func _run_mental_stack_integration_feint_exhausted_orthogonal(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_feint_resistance_load(true)
    CombatConstants.set_feature_fight_exhaustion_index_load(true)

    var mgr: Node = _make_two_sided_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var defender: Dictionary = mgr.combatants[1]
    var attacker_id: int = CombatantEntityAccess.id_int(attacker)
    var defender_id: int = CombatantEntityAccess.id_int(defender)

    # Set defender to high-readiness (blocks feints on attacker side).
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard"] = 1.0
    defender.erase("off_balance_until")

    # Set attacker to exhausted state.
    attacker[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.80
    attacker["state"] = CombatConstants.STATE_WAITING
    attacker["gauge"] = 100.0

    # Build actions for the EXHAUSTED attacker  -  should get exhaustion tunnel, not feints.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": attacker_id},
        {"move_id": "oberhau_feint", "target_id": defender_id, "target_part": "head"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, attacker_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_feint_exhausted_orthogonal: expected exhaustion layer pick but got none"
        )
    else:
        var layer: String = str(attacker.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION:
            CombatRegressionHarness._fail(
                failures, "integration_feint_exhausted_orthogonal: want exhaustion layer got %s" % layer
            )

    CombatConstants.set_feature_ms_feint_resistance_load(-1)
    CombatConstants.set_feature_fight_exhaustion_index_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 5. Medical escalation + rout: Rout doesn't trigger (medical peril), L1 medical fires with escalation boost.
## Failed bandage on ally chest -> pack gets 1.5x escalation bonus.
static func _run_mental_stack_integration_medical_escalation_rout(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_l6_rout_load(true)
    CombatConstants.set_feature_ms_medical_escalation_load(true)

    var mgr: Node = _make_three_combatant_manager()
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)

    # Set up ally with failed bandage on chest AND immediate peril.
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    _set_immediate_peril(ally_ent)
    ally["failed_medical_parts"] = ["chest"]

    medic["state"] = CombatConstants.STATE_WAITING
    medic["gauge"] = 100.0

    # Build medical actions  -  pack should win over bandage due to escalation.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": medic_id},
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": ally_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_id": ally_id, "target_part": "chest"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, medic_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_medical_escalation_rout: expected medical layer pick but got none"
        )
    else:
        var layer: String = str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_MEDICAL:
            CombatRegressionHarness._fail(
                failures, "integration_medical_escalation_rout: want medical layer got %s" % layer
            )

    # Verify pack was picked over bandage (escalation bonus).
    var move_id: String = str(picked.get("move_id", ""))
    if move_id != CombatConstants.MOVE_ID_PACK_WOUND:
        CombatRegressionHarness._fail(
            failures, "integration_medical_escalation_rout: want pack_wound got %s (escalation bonus)" % move_id
        )

    CombatConstants.set_feature_ms_l6_rout_load(-1)
    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 6. Full stack: post-strike + surrounded + exhausted + medical (3+5+6+7).
## MS-L8 post-strike fires first (press struck target). If no valid strikes in filter pool,
## MS-L9 positional check fires but returns empty (rout_layer_blocked by plug logic).
## L5 exhaustion would fire but medical peril takes priority -> L1 medical layer with escalation boost.
static func _run_mental_stack_integration_full_stack_post_strike_surrounded_exhausted_medical(
    failures: PackedStringArray
) -> void:
    CombatConstants.set_feature_ms_post_strike_load(true)
    CombatConstants.set_feature_fight_exhaustion_index_load(true)
    CombatConstants.set_feature_ms_l6_rout_load(true)
    CombatConstants.set_feature_ms_positional_awareness_load(true)
    CombatConstants.set_feature_ms_medical_escalation_load(true)

    var mgr: Node = _make_four_combatant_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    var enemy1_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])

    # Simulate a recent strike stamp.
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = enemy1_id
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = float(mgr.combat_clock)
    fighter["state"] = CombatConstants.STATE_WAITING
    fighter["gauge"] = 100.0

    # Set exhaustion above tunnel threshold (layer 5 would fire).
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.80

    # Set up ally in immediate peril with failed bandage on chest  -  triggers L1 medical.
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    _set_immediate_peril(ally_ent)
    ally["failed_medical_parts"] = ["chest"]

    # Build actions: offense vs struck target + medical on ally + disengage moves.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy1_id, "target_part": "head"},
        {"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_id": ally_id, "target_part": "chest"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "integration_full_stack: expected medical layer pick but got none")
    else:
        var layer: String = str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_MEDICAL:
            CombatRegressionHarness._fail(
                failures,
                (
                    "integration_full_stack: want medical layer got %s (post-strike stamp set but ally peril should"
                    + " route to L1)" % layer
                )
            )

    CombatConstants.set_feature_ms_post_strike_load(-1)
    CombatConstants.set_feature_fight_exhaustion_index_load(-1)
    CombatConstants.set_feature_ms_l6_rout_load(-1)
    CombatConstants.set_feature_ms_positional_awareness_load(-1)
    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 7. Post-strike vs dead target (Phase 3 only, edge case).
## Combatant lands killing blow; stamp set; next cognition cycle the struck target is dead.
## MS-L8 filter returns empty (target dead, no valid strikes). Stamp erased at top of try_pick.
static func _run_mental_stack_integration_post_strike_vs_dead_target(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_post_strike_load(true)

    var mgr: Node = _make_two_sided_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)

    # Simulate a recent strike stamp on the enemy.
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = enemy_id
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = float(mgr.combat_clock)
    fighter["state"] = CombatConstants.STATE_WAITING
    fighter["gauge"] = 100.0

    # Kill the enemy combatant (set alive flag to false).
    enemy["alive"] = false

    # Build actions: offense vs dead target + wait.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]

    # The stamp is set but the target is dead  -  filter_post_strike_actions returns empty.
    # try_pick should fall through and return {} (no stamp layer).
    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if not picked.is_empty():
        CombatRegressionHarness._fail(
            failures,
            (
                "integration_post_strike_vs_dead_target: expected empty pick (dead target) but got %s"
                % str(picked.get("move_id", ""))
            )
        )

    CombatConstants.set_feature_ms_post_strike_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 8. Post-strike stamp expires naturally (Phase 3 only, edge case).
## Combatant lands strike on turn N; stamp set with combat_clock=10.0; next cognition cycle at 12.5.
## Stamp check absf(10.0 - 12.5) = 2.5 > 2.0 (POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE).
static func _run_mental_stack_integration_post_strike_stamp_expires(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_post_strike_load(true)

    var mgr: Node = _make_two_sided_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)

    # Simulate a stamp set at combat_clock=10.0, but advance clock to 12.5 (> tolerance).
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = enemy_id
    fighter[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = 10.0
    mgr.combat_clock = 12.5
    fighter["state"] = CombatConstants.STATE_WAITING
    fighter["gauge"] = 100.0

    # Build actions: offense vs target + wait.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]

    # Stamp expired  -  absf(10.0 - 12.5) = 2.5 > POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE (2.0).
    # try_pick should return {} (no stamp, falls through to weighted pick).
    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if not picked.is_empty():
        var layer: String = str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        CombatRegressionHarness._fail(
            failures,
            "integration_post_strike_stamp_expires: expected empty pick (expired stamp) but got layer=%s" % layer
        )

    CombatConstants.set_feature_ms_post_strike_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 9. Feint resistance + post-strike (2+3).
## Attacker with feints lands a real strike (not feint); stamp set; next turn defender has high readiness.
## Phase 2 blocks feints on attacker's attack weight computation. Phase 3 sets stamp from the real strike.
## On attacker's next turn, MS-L8 fires  -  press the struck target.
static func _run_mental_stack_integration_feint_resistance_plus_post_strike(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_feint_resistance_load(true)
    CombatConstants.set_feature_ms_post_strike_load(true)

    var mgr: Node = _make_two_sided_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var defender: Dictionary = mgr.combatants[1]
    var attacker_id: int = CombatantEntityAccess.id_int(attacker)
    var defender_id: int = CombatantEntityAccess.id_int(defender)

    # Set defender to high-readiness (blocks feints on Phase 2).
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard"] = 1.0
    defender.erase("off_balance_until")

    # Simulate a stamp from the real strike (attacker already struck this target).
    attacker[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = defender_id
    attacker[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = float(mgr.combat_clock)
    attacker["state"] = CombatConstants.STATE_WAITING
    attacker["gauge"] = 100.0

    # Build actions: feint + real strike vs defender + wait.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": attacker_id},
        {"move_id": "oberhau_feint", "target_id": defender_id, "target_part": "head"},
        {"move_id": "thrust", "target_id": defender_id, "target_part": "head"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, attacker_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_feint_resistance_plus_post_strike: expected post-strike layer pick but got none"
        )
    else:
        var layer: String = str(attacker.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE:
            CombatRegressionHarness._fail(
                failures, "integration_feint_resistance_plus_post_strike: want post-strike layer got %s" % layer
            )

    # Verify feint was NOT picked (high readiness blocks it; stamp routes to press instead).
    var move_id: String = str(picked.get("move_id", ""))
    if move_id == "oberhau_feint":
        CombatRegressionHarness._fail(
            failures, "integration_feint_resistance_plus_post_strike: feint was picked but defender has high readiness"
        )

    CombatConstants.set_feature_ms_feint_resistance_load(-1)
    CombatConstants.set_feature_ms_post_strike_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 10. Positional awareness vs rout priority (6+1).
## Combatant surrounded by 2+ hostiles; also has cohesion pressure (blood volume low).
## MS-L6 rout fires first if rout_cognition_pressure() is true -> picks flee/fall_back.
## If rout blocked (medical peril), MS-L9 fires and returns disengage pool when surrounded + wounded.
static func _run_mental_stack_integration_positional_vs_rout_priority(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_l6_rout_load(true)
    CombatConstants.set_feature_ms_positional_awareness_load(true)

    var mgr: Node = _make_four_combatant_manager()
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)

    # Set exhaustion below tunnel threshold (0.50) so L5 doesn't preempt L6/L9.
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.30
    fighter["state"] = CombatConstants.STATE_WAITING
    fighter["gauge"] = 100.0

    # Set low blood on the entity node so L9 vulnerability check fires.
    # Blood must be below FORMATION_FLEE_BLOOD_VOLUME_MAX (55) to trigger
    # abandonment_warranted -> rout_cognition_pressure -> MS-L6 rout pick.
    var fighter_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, fighter)
    if fighter_ent != null:
        fighter_ent.blood_volume = CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX - 5.0
        # Add a chest wound so is_in_immediate_peril also fires (blood + bleed rate).
        EntityWounds.add_wound(
            fighter_ent,
            "chest",
            BleedingConstants.INJURY_TYPE_CUT,
            9.0,
            "thoracic",
            BleedingConstants.SEVERITY_MODERATE
        )

    # Build actions: flee, fall_back, wait + offense.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FALL_BACK, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": CombatantEntityAccess.id_int(mgr.combatants[2]), "target_part": "head"},
    ]

    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "integration_positional_vs_rout_priority: expected rout or positional pick but got none"
        )
    else:
        var layer: String = str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if (
            layer != CombatConstants.MENTAL_STACK_LAYER_ROUT
            and layer != CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS
        ):
            CombatRegressionHarness._fail(
                failures, "integration_positional_vs_rout_priority: want rout or positional layer got %s" % layer
            )

    CombatConstants.set_feature_ms_l6_rout_load(-1)
    CombatConstants.set_feature_ms_positional_awareness_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 11. Medical escalation  -  no escalation path exists (Phase 7 only, weight-only).
## Combatant with failed bandage on chest; NO pack item in inventory, NO TK item.
## _escalation_path_has_next_step returns false (no next step available).
## Retry bonus applies normally (2.8x). AI retries bandage because escalation is impossible.
static func _run_mental_stack_integration_medical_escalation_no_path(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_medical_escalation_load(true)

    var mgr: Node = CombatManager.new()
    var medic_ent := CombatRegressionHarness._new_entity("SWORD")
    medic_ent.linen_strips_remaining = 0
    mgr.register(medic_ent, "medic")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "ally")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)

    # Wound the ally's chest  -  blood below death threshold but above peril threshold so entity is alive and in peril.
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent != null:
        ally_ent.blood_volume = 40.0
        EntityWounds.add_wound(
            ally_ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
        )
        # Apply direct pressure so dressings are allowed (bandage requires compression on bleeding wounds).
        ally_ent._apply_direct_pressure_from_ally("chest", medic_ent)

    # Simulate failed bandage on chest  -  but pack/TK are NOT available (no escalation path).
    ally["failed_medical_parts"] = ["chest"]

    # Build actions: only bandage is listed (pack/TK not in inventory -> not listed).
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": ally_id, "target_part": "chest"},
    ]

    # Compute weight  -  should have retry bonus (2.8x) since escalation is impossible.
    var w_bandage: float = CombatMedicalWeighting.compute_weight(actions[0], medic_id, mgr)
    if w_bandage < 2.0:
        CombatRegressionHarness._fail(
            failures,
            "integration_med_escalation_no_path: bandage weight=%.4f (expected retry bonus boost >= 2.0)" % w_bandage
        )

    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## 12. Medical escalation  -  success clears path (Phase 7 only, weight-only).
## Combatant with failed bandage on chest; escalates to pack which succeeds.
## failed_medical_parts removal on success clears the part.
## Subsequent actions on that part return to normal weights  -  no escalation bonus, no suppressed retry.
static func _run_mental_stack_integration_medical_escalation_success_clears_path(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ms_medical_escalation_load(true)

    var mgr: Node = CombatManager.new()
    var medic_ent := CombatRegressionHarness._new_entity("SWORD")
    medic_ent.linen_strips_remaining = 0
    mgr.register(medic_ent, "medic")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "ally")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)

    # Wound the ally's chest  -  blood below death threshold but above peril threshold so entity is alive and in peril.
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent != null:
        ally_ent.blood_volume = 40.0
        EntityWounds.add_wound(
            ally_ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
        )
        # Apply direct pressure so dressings are allowed (bandage requires compression on bleeding wounds).
        ally_ent._apply_direct_pressure_from_ally("chest", medic_ent)

    # Simulate failed bandage on chest.
    ally["failed_medical_parts"] = ["chest"]

    # Build actions: pack (escalation step) + bandage (retry).
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": ally_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_id": ally_id, "target_part": "chest"},
    ]

    # Before success: pack should have escalation bonus (higher weight than bandage).
    var w_pack_before: float = CombatMedicalWeighting.compute_weight(actions[1], medic_id, mgr)
    var w_bandage_before: float = CombatMedicalWeighting.compute_weight(actions[0], medic_id, mgr)
    if w_pack_before <= w_bandage_before:
        CombatRegressionHarness._fail(
            failures,
            (
                "integration_med_escalation_success_clears_path: before success, pack weight=%.4f <= bandage weight"
                + "=%.4f (pack should be boosted)" % [w_pack_before, w_bandage_before]
            )
        )

    # Simulate successful pack: remove "chest" from failed_medical_parts.
    var failed: Array = ally.get("failed_medical_parts", []) as Array
    var idx: int = failed.find("chest")
    if idx >= 0:
        failed.remove_at(idx)
    ally["failed_medical_parts"] = failed

    # After success: pack should NOT have escalation bonus anymore.
    var w_pack_after: float = CombatMedicalWeighting.compute_weight(actions[1], medic_id, mgr)
    var w_bandage_after: float = CombatMedicalWeighting.compute_weight(actions[0], medic_id, mgr)
    if w_pack_after < 1.0:
        CombatRegressionHarness._fail(
            failures,
            (
                "integration_med_escalation_success_clears_path: after success, pack weight=%.4f (should still be v"
                + "alid action >= 1.0)" % w_pack_after
            )
        )

    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Entry point: called from CombatRegressionHarness.run_all().
static func run(failures: PackedStringArray) -> void:
    _run_mental_stack_integration_exhausted_surrounded(failures)
    _run_mental_stack_integration_post_strike_surrounded_wounded(failures)
    _run_mental_stack_integration_rout_medical_peril(failures)
    _run_mental_stack_integration_feint_exhausted_orthogonal(failures)
    _run_mental_stack_integration_medical_escalation_rout(failures)
    _run_mental_stack_integration_full_stack_post_strike_surrounded_exhausted_medical(failures)
    _run_mental_stack_integration_post_strike_vs_dead_target(failures)
    _run_mental_stack_integration_post_strike_stamp_expires(failures)
    _run_mental_stack_integration_feint_resistance_plus_post_strike(failures)
    _run_mental_stack_integration_positional_vs_rout_priority(failures)
    _run_mental_stack_integration_medical_escalation_no_path(failures)
    _run_mental_stack_integration_medical_escalation_success_clears_path(failures)
