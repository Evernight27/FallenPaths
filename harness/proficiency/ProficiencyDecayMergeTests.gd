class_name ProficiencyDecayMergeTests

extends CombatRegressionHarnessCore

## XCamp-4: use-based stat proficiency award mechanics. Parry deflect / partial parry /
## dodge / counter-read gains, wounded + dazed write factors, execution quality,
## blood-peril end scaling and camp training-pending merge.

const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")


## XCamp-4: use-based stat proficiency system tests.
## All tests are gated by CompanyState.read_stub_proficiency_enabled() — proficiency_enabled defaults to true.
## Parry deflect awards END gain for defender (absorbing recoil).
static func _run_parry_deflect_awards_end_gains(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_end_gains: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var enemy_ent: Node = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true  # Tracked defender so the END-gain path is exercised.
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "parry_end_gains: no enemy combatant")
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var initial_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0))

    # Proficiency gains are awarded in apply_result (not resolve_attack). Apply a parry_deflect
    # result where the player (attacker) is parried by the enemy (defender). Momentum 0 skips the
    # recoil so only the proficiency award is exercised.
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    # XCamp-4: the defender's absorbed-END lesson scales by the desirable-difficulty factor
    # (meeting a stronger foe's blade is a harder physical lesson), so the minimum threshold is
    # the base END gain multiplied by that factor (same source as the production path).
    var atk_str: float = CombatantEntityAccess.stats_dict(atk).get(
        DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    var def_str: float = CombatantEntityAccess.stats_dict(enemy).get(
        DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    var diff: float = EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
    var expected_min: float = (
        EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT * diff
    )
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0))
    if bonus_end < initial_end + expected_min - 0.001:
        _fail(
            failures,
            (
                "parry_end_gains: defender END gain too low on parry_deflect "
                + "(got %.4f, want >= %.4f at diff=%.3f)" % [bonus_end, expected_min, diff]
            )
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: the defender's stance form modulates their END gain on a parry — a defensive form (WALL,
## END mult 1.25) should yield a larger END gain than a neutral form (BALANCED, END mult 1.0),
## proving the defender's weapon/form now feeds their physical gains just like the attacker's.


static func _run_parry_deflect_end_gain_scales_with_defender_form(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_form_end: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "parry_form_end: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }

    # Baseline: defender in BALANCED (neutral END 1.0). Expected END gain =
    # 0.2 * 0.5 * 1.0 * def_wounded * diff, where diff = opponent_difficulty_mult(atk_str, def_str).
    enemy[CombatConstantsMentalStack.COMBATANT_KEY_WEAPON_FORM] = CombatWeaponForm.FORM_BALANCED
    var end_before_balanced: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var end_after_balanced: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    var balanced_gain: float = end_after_balanced - end_before_balanced

    # Defensive: defender in WALL (defensive END 1.25). Expected END gain = 0.2 * 0.5 * 1.25 * 1.0 * diff
    enemy[CombatConstantsMentalStack.COMBATANT_KEY_WEAPON_FORM] = CombatWeaponForm.FORM_WALL
    var end_before_wall: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var end_after_wall: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    var wall_gain: float = end_after_wall - end_before_wall

    if wall_gain <= balanced_gain:
        _fail(
            failures,
            (
                (
                    "parry_form_end: defensive form (WALL) should yield more END gain than neutral (BALANCED) "
                    + "(wall=%.4f, "
                    + "balanced=%.4f)"
                )
                % [wall_gain, balanced_gain]
            ),
        )
    if wall_gain < 0.12:
        _fail(
            failures,
            "parry_form_end: WALL defender END gain should be ~0.125 (got %.4f)" % wall_gain,
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a defender's stance form modulates END training from absorbing a *hit* — a braced/defensive
## guard (WALL, END mult 1.25) that holds the line and eats the blow trains more endurance than a loose
## neutral stance (BALANCED, END 1.0). Mirrors the parry-deflect form handling; the hit path previously
## ignored the defender's stance when awarding absorbed-damage END.


static func _run_hit_absorbed_end_scales_with_defender_form(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Baseline: BALANCED defender (END mult 1.0).
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "hit_form_end: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "hit_form_end: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    enemy[CombatConstantsMentalStack.COMBATANT_KEY_WEAPON_FORM] = CombatWeaponForm.FORM_BALANCED
    var bal_before: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "hit", {"dmg": 30.0})
    var bal_gain: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0)) - bal_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    if bal_gain <= 0.0:
        _fail(failures, "hit_form_end: BALANCED defender should gain END from absorbing a hit (got %.4f)" % bal_gain)
        return

    # Defensive: WALL defender (END mult 1.25).
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "hit_form_end: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var enemy_ent2: CoreEntity = data2.get("enemy_ent")
    enemy_ent2._combat_skill_trained = true
    var p_id2: int = data2.get("p_id")
    var enemy2: Dictionary = mgr2.combatants[1]
    if enemy2.is_empty():
        _fail(failures, "hit_form_end: no enemy combatant2")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
        return
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    enemy2[CombatConstantsMentalStack.COMBATANT_KEY_WEAPON_FORM] = CombatWeaponForm.FORM_WALL
    var wall_before: float = float(enemy_ent2._proficiency_bonus.get("endurance", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "hit", {"dmg": 30.0})
    var wall_gain: float = float(enemy_ent2._proficiency_bonus.get("endurance", 0.0)) - wall_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if not (wall_gain > bal_gain):
        _fail(
            failures,
            (
                (
                    "hit_form_end: defensive form (WALL) should yield more END than neutral (BALANCED) on an absorbed "
                    + "hit "
                    + "(wall=%.4f balanced=%.4f)"
                )
                % [wall_gain, bal_gain]
            ),
        )


## XCamp-4: a clean parry trains the defender's reflexes (AGI) on top of the weapon skill (STR) and
## force absorption (END). A successful parry is a fast reactive act — read the incoming strike and
## meet it with the own blade in time. The gain is modest (smaller than a full-body dodge) and is
## gated on the write-side tracked flag: an untracked enemy accrues no AGI.


static func _run_parry_deflect_awards_reflex_agi(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Tracked defender: parrying should grow AGI.
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_reflex_agi: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "parry_reflex_agi: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var agi_before: float = float(enemy_ent._proficiency_bonus.get("agility", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var agi_gain: float = float(enemy_ent._proficiency_bonus.get("agility", 0.0)) - agi_before
    if agi_gain <= 0.05:
        _fail(failures, "parry_reflex_agi: parrying defender should gain AGI (got %.4f)" % agi_gain)
    if agi_gain >= 0.2:
        _fail(failures, "parry_reflex_agi: parry AGI gain too large for a controlled movement (got %.4f)" % agi_gain)
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)

    # Untracked defender: parrying must NOT accrue AGI (write-side gate).
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "parry_reflex_agi: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var enemy_ent2: CoreEntity = data2.get("enemy_ent")
    # _combat_skill_trained left false -> untracked.
    var p_id2: int = data2.get("p_id")
    var enemy2: Dictionary = mgr2.combatants[1]
    if enemy2.is_empty():
        _fail(failures, "parry_reflex_agi: no enemy combatant2")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
        return
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    var atk2: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr2, p_id2)
    atk2.pending_attack = {"target_id": enemy_id2, "intensity": 0.5, "attack_type": "thrust"}
    var agi_before2: float = float(enemy_ent2._proficiency_bonus.get("agility", 0.0))
    AttackResultApplier.apply_result(
        mgr2, p_id2, {"action": "parry_deflect", "target_id": enemy_id2, "parry_clash_context": pclash}
    )
    var agi_gain2: float = float(enemy_ent2._proficiency_bonus.get("agility", 0.0)) - agi_before2
    if absf(agi_gain2) > 0.001:
        _fail(
            failures,
            (
                "parry_reflex_agi: untracked defender should not gain AGI on parry (before %.4f got %.4f)"
                % [agi_before2, agi_gain2]
            ),
        )
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)


## XCamp-4: blood_peril_end_factor scales patient-END gain by how badly the patient is bleeding —
## full blood volume (100) yields 1.0x, empty (0) yields (1.0 + GAIN_BLOOD_PERIL_END_SCALE)x,
## and the ramp is monotonic. This proves a deep hemorrhage trains more endurance than a light scratch.


static func _run_blood_peril_end_factor_monotonic(failures: PackedStringArray) -> void:
    var at_full: float = EntityProficiency.blood_peril_end_factor(100.0)
    var at_half: float = EntityProficiency.blood_peril_end_factor(50.0)
    var at_empty: float = EntityProficiency.blood_peril_end_factor(0.0)
    if at_full < 1.0 - 0.001:
        _fail(failures, "blood_peril_end_factor: full blood should be >= 1.0 (got %.4f)" % at_full)
    if at_empty < EntityProficiency.GAIN_BLOOD_PERIL_END_SCALE + 0.999:
        _fail(failures, "blood_peril_end_factor: empty blood should be ~1.0+SCALE (got %.4f)" % at_empty)
    if not (at_full < at_half and at_half < at_empty):
        _fail(
            failures,
            (
                "blood_peril_end_factor: must be monotonic full<half<empty (full=%.4f half=%.4f empty=%.4f)"
                % [at_full, at_half, at_empty]
            ),
        )


## XCamp-4: wounded_write_factor reduces *physical* stat training in proportion to blood lost — 1.0 at
## full blood (healthy fighters train unchanged), down to GAIN_WOUNDED_WRITE_FLOOR at empty, monotonic.


static func _run_wounded_write_factor_bounds(failures: PackedStringArray) -> void:
    var at_full: float = EntityProficiency.wounded_write_factor(100.0)
    var at_half: float = EntityProficiency.wounded_write_factor(50.0)
    var at_empty: float = EntityProficiency.wounded_write_factor(0.0)
    if at_full > 1.0 + 0.001:
        _fail(failures, "wounded_write_factor: full blood should be ~1.0 (got %.4f)" % at_full)
    if at_empty < EntityProficiency.GAIN_WOUNDED_WRITE_FLOOR - 0.001:
        _fail(failures, "wounded_write_factor: empty blood should be ~FLOOR (got %.4f)" % at_empty)
    if not (at_full > at_half and at_half > at_empty):
        _fail(
            failures,
            (
                "wounded_write_factor: must be monotonic decreasing full>half>empty (full=%.4f half=%.4f empty=%.4f)"
                % [at_full, at_half, at_empty]
            ),
        )


## XCamp-4: a bleeding fighter's physical stat training is reduced by wounded_write_factor —
## a low-blood attacker accrues less STR from the same strike attempt than a full-blood one.
## Uses the deterministic "miss" outcome (no resolver / RNG) so the difference isolates the
## blood-peril factor; both fighters start at bonus 0.0 (novice tier, 1.0 gain multiplier).


static func _run_wounded_fighter_gains_less_physical_stat(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Full-blood baseline: a healthy tracked attacker accrues the full strike-attempted STR.
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "wounded_gain_less: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var str_full_before: float = float(player_ent._proficiency_bonus.get("strength", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
    var str_full_gain: float = float(player_ent._proficiency_bonus.get("strength", 0.0)) - str_full_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    if str_full_gain <= 0.0:
        _fail(
            failures,
            "wounded_gain_less: full-blood attacker should gain STR on a strike attempt (got %.4f)" % str_full_gain
        )
        return

    # Low-blood attacker: the same strike attempt, heavily bleeding, should accrue less STR.
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "wounded_gain_less: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var p_id2: int = data2.get("p_id")
    var player_ent2: Node = data2.get("player_ent")
    var enemy2: Dictionary = mgr2.combatants[1]
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    player_ent2.blood_volume = 20.0  # Heavily bleeding.
    var str_low_before: float = float(player_ent2._proficiency_bonus.get("strength", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "miss", {})
    var str_low_gain: float = float(player_ent2._proficiency_bonus.get("strength", 0.0)) - str_low_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if str_low_gain <= 0.0:
        _fail(failures, "wounded_gain_less: low-blood attacker should still gain STR (got %.4f)" % str_low_gain)
        return
    if not (str_low_gain < str_full_gain):
        _fail(
            failures,
            (
                "wounded_gain_less: low-blood attacker should gain less STR than full-blood (low=%.4f full=%.4f)"
                % [str_low_gain, str_full_gain]
            ),
        )


## XCamp-4: execution_quality_factor gates physical training by pain x consciousness — the same
## combined modifier the combat system uses to degrade a fighter's actions. Healthy entity = 1.0,
## dazed entity is reduced, and the result never falls below MIN_PERFORMANCE_MODIFIER.
## Blood loss is deliberately NOT in this factor (wounded_write_factor covers it, callers multiply).


static func _run_execution_quality_factor_bounds(failures: PackedStringArray) -> void:
    if EntityProficiency.execution_quality_factor(null) != 1.0:
        _fail(failures, "exec_q: null entity should be 1.0")

    var ent: CoreEntity = _new_entity("SWORD")
    var healthy: float = EntityProficiency.execution_quality_factor(ent)
    if absf(healthy - 1.0) > 0.001:
        _fail(failures, "exec_q: healthy entity should be 1.0 (got %.4f)" % healthy)

    # Simulate a dazed fighter: pin effective consciousness and keep the dirty flag clear so
    # get_effective_consciousness returns the pinned value instead of recomputing it from wounds.
    ent.effective_consciousness = 50.0
    ent._consciousness_dirty = false
    var dazed: float = EntityProficiency.execution_quality_factor(ent)
    if not (dazed > 0.0 and dazed < 1.0):
        _fail(failures, "exec_q: dazed entity should be in (0,1) (got %.4f)" % dazed)

    ent.effective_consciousness = 0.0
    var floor: float = EntityProficiency.execution_quality_factor(ent)
    if absf(floor - PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER) > 0.001:
        _fail(
            failures,
            (
                "exec_q: floor should clamp at MIN_PERFORMANCE_MODIFIER (got %.4f want %.4f)"
                % [floor, PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER]
            ),
        )
    HarnessFixtures._free_harness_node(ent)


## XCamp-4: a dazed fighter trains less per strike attempt than a healthy one — the
## execution-quality factor reaches the resolve path (physical gains only; perception is
## unaffected by design). Both still accrue something: practice in pain still teaches.


static func _run_dazed_fighter_trains_less_per_strike(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Healthy baseline.
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "dazed_trains_less: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var str_before: float = float(player_ent._proficiency_bonus.get("strength", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
    var str_healthy: float = float(player_ent._proficiency_bonus.get("strength", 0.0)) - str_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    if str_healthy <= 0.0:
        _fail(failures, "dazed_trains_less: healthy attacker should gain STR on a strike (got %.4f)" % str_healthy)
        return

    # Dazed twin: same rep, effective consciousness halved (dirty flag pinned off so it sticks).
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "dazed_trains_less: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var p_id2: int = data2.get("p_id")
    var player_ent2: Node = data2.get("player_ent")
    var enemy2: Dictionary = mgr2.combatants[1]
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    player_ent2.effective_consciousness = 50.0
    player_ent2._consciousness_dirty = false
    var str_before2: float = float(player_ent2._proficiency_bonus.get("strength", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "miss", {})
    var str_dazed: float = float(player_ent2._proficiency_bonus.get("strength", 0.0)) - str_before2
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if str_dazed <= 0.0:
        _fail(failures, "dazed_trains_less: dazed attacker should still gain STR (got %.4f)" % str_dazed)
        return
    if not (str_dazed < str_healthy):
        _fail(
            failures,
            (
                "dazed_trains_less: dazed attacker should gain less STR than healthy (dazed=%.4f healthy=%.4f)"
                % [str_dazed, str_healthy]
            ),
        )


## XCamp-4: execution quality gates weapon/form motor-familiarity gains the same way it gates the
## physical stat reps — a dazed fighter practices their weapon/form less per swing than a healthy one,
## while still accruing something. Isolates the weapon channel by reading weapon proficiency across the
## same deterministic "miss" rep (miss = pure attempt, no hit/damage to confound the read).


static func _run_dazed_fighter_practices_weapon_less(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Healthy baseline.
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "dazed_weapon: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var wp_before: float = EntityProficiency.weapon_proficiency_value(player_ent, "SWORD")
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
    var wp_healthy: float = EntityProficiency.weapon_proficiency_value(player_ent, "SWORD") - wp_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    if wp_healthy <= 0.0:
        _fail(failures, "dazed_weapon: healthy attacker should gain weapon prof on a strike (got %.4f)" % wp_healthy)
        return

    # Dazed twin: same rep, effective consciousness halved (dirty flag pinned off so it sticks).
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "dazed_weapon: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var p_id2: int = data2.get("p_id")
    var player_ent2: Node = data2.get("player_ent")
    var enemy2: Dictionary = mgr2.combatants[1]
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    player_ent2.effective_consciousness = 50.0
    player_ent2._consciousness_dirty = false
    var wp_before2: float = EntityProficiency.weapon_proficiency_value(player_ent2, "SWORD")
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "miss", {})
    var wp_dazed: float = EntityProficiency.weapon_proficiency_value(player_ent2, "SWORD") - wp_before2
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if wp_dazed <= 0.0:
        _fail(failures, "dazed_weapon: dazed attacker should still gain weapon prof (got %.4f)" % wp_dazed)
        return
    if not (wp_dazed < wp_healthy):
        _fail(
            failures,
            (
                "dazed_weapon: dazed attacker should gain less weapon prof than healthy (dazed=%.4f healthy=%.4f)"
                % [wp_dazed, wp_healthy]
            ),
        )


## XCamp-4: a committed strike is aerobic exertion — the attacker trains END from the swing effort
## regardless of outcome (their END channel: previously they trained END only by taking damage).
## Uses the deterministic "miss" outcome so the difference isolates the new aerobic-END channel.
## A full-blood tracked attacker's END grows on the attempt; the untracked defender gains none.


static func _run_attacker_strikes_build_aerobic_end(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "aerobic_end: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy_ent: Node = data.get("enemy_ent")
    var enemy: Dictionary = mgr.combatants[1]
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var enemy_end_before: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    var atk_end_before: float = float(player_ent._proficiency_bonus.get("endurance", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
    var atk_end_gain: float = float(player_ent._proficiency_bonus.get("endurance", 0.0)) - atk_end_before
    var enemy_end_after: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    if atk_end_gain <= 0.0:
        _fail(
            failures,
            "aerobic_end: full-blood tracked attacker should gain END on a committed strike (got %.4f)" % atk_end_gain,
        )
    if absf(enemy_end_after - enemy_end_before) > 0.001:
        _fail(
            failures,
            (
                "aerobic_end: untracked defender must not gain END from the attacker's swing (before %.4f after %.4f)"
                % [enemy_end_before, enemy_end_after]
            ),
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a committed counter-read that resolves correctly awards more PER than one that resolves
## wrong — both are cognitive perception lessons, but a correct read is the sharper one.


static func _run_counter_read_per_gain(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "counter_read_per: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var player_ent: CoreEntity = data.get("player_ent")
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "counter_read_per: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    if atk.is_empty():
        _fail(failures, "counter_read_per: no player combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return

    # Plant the counter-read commitment + inferred form for the enemy.
    atk[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL] = 1e9
    atk[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(enemy_id): "wall"}

    var per_before: float = float(player_ent._proficiency_bonus.get("perception", 0.0))
    AttackProficiencyAwarder.evaluate_counter_read_outcome(mgr, p_id, enemy_id, "wall")
    var per_correct: float = float(player_ent._proficiency_bonus.get("perception", 0.0)) - per_before

    # Reset commitment so the wrong-read case also fires (success cleared it above).
    atk[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL] = 1e9
    per_before = float(player_ent._proficiency_bonus.get("perception", 0.0))
    AttackProficiencyAwarder.evaluate_counter_read_outcome(mgr, p_id, enemy_id, "plow")
    var per_wrong: float = float(player_ent._proficiency_bonus.get("perception", 0.0)) - per_before

    if per_correct <= 0.0:
        _fail(failures, "counter_read_per: correct read should award PER (got %.4f)" % per_correct)
    if per_wrong <= 0.0:
        _fail(failures, "counter_read_per: wrong read should still award PER (got %.4f)" % per_wrong)
    if per_correct <= per_wrong:
        _fail(
            failures,
            (
                "counter_read_per: correct read should beat wrong read (correct=%.4f wrong=%.4f)"
                % [per_correct, per_wrong]
            ),
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a successful dodge awards the *defender* a small PER gain — evading an incoming strike
## requires perceiving the attack line. Subordinate to the parry-read (a parry is a direct blade-to-
## blade engagement; a dodge is more reactive footwork), and cognitive, so it is NOT scaled by the
## wounded fighter's physical-execution factor. The write-side tracked flag gates it like every award.


static func _run_dodge_read_per_gain(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "dodge_read_per: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: Node = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true  # Tracked defender so the perception-read path is exercised.
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "dodge_read_per: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    if atk.is_empty():
        _fail(failures, "dodge_read_per: no player combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}

    var per_before: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(mgr, p_id, {"action": "dodge", "target_id": enemy_id})
    var per_after: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))

    if per_after <= per_before:
        _fail(
            failures,
            (
                "dodge_read_per: a successful dodge should award the tracked defender PER (before %.4f, after %.4f)"
                % [per_before, per_after]
            ),
        )
    if per_after - per_before > EntityProficiency.GAIN_PARRY_READ_PER_BASE:
        _fail(
            failures,
            (
                "dodge_read_per: dodge-read PER must stay under the parry-read base (got %.4f > %.4f)"
                % [per_after - per_before, EntityProficiency.GAIN_PARRY_READ_PER_BASE]
            ),
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a clean hit awards the attacker the wind-up-completion AGI credit (execution/timing of the
## committed swing), matching the miss and dodge paths — so accurate fighters train their execution just
## as much as whiffing ones (no inverted incentive where hits trained AGI *less* than misses).


static func _run_combat_hit_awards_windup_agi(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "hit_windup_agi: setup failed")
        return
    var player_ent: Node = data.get("player_ent")
    var agi_before: float = float(player_ent._proficiency_bonus.get("agility", 0.0))

    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {"target_id": 1, "intensity": 0.5, "attack_type": "thrust"}
    var result: Dictionary = AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))
    AttackResultApplier.apply_result(data.get("mgr"), data.get("p_id"), result)

    if result.get("action", "") == "hit":
        var agi_after: float = float(player_ent._proficiency_bonus.get("agility", 0.0))
        if agi_after < agi_before + 0.05:
            _fail(
                failures,
                (
                    "hit_windup_agi: clean hit should award the attacker wind-up AGI (before=%.4f after=%.4f)"
                    % [agi_before, agi_after]
                ),
            )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: completing a wind-up grants the attacker execution AGI regardless of outcome — a dodged
## swing still trains the timing and follow-through muscles. This mirrors the hit-path wind-up credit.


static func _run_dodge_awards_windup_agi(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "dodge_windup_agi: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "dodge_windup_agi: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var agi_before: float = float(player_ent._proficiency_bonus.get("agility", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "dodge", {})
    var agi_gain: float = float(player_ent._proficiency_bonus.get("agility", 0.0)) - agi_before
    if agi_gain <= 0.0:
        _fail(
            failures,
            "dodge_windup_agi: attacker should gain AGI from completed wind-up on dodge (got %.4f)" % agi_gain,
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## Parry partial awards a PARTIAL END gain to the defender (absorbing the reduced hit) — less than a full
## parry_deflect, but consistent with the hit path where absorbing damage trains END.
## Parry partial awards a PARTIAL END gain to the defender (absorbing the reduced hit) — less than a full
## parry_deflect, but consistent with the hit path where absorbing damage trains END.


static func _run_parry_partial_awards_partial_end_gain(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_partial_end: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var enemy_ent: Node = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true  # Tracked defender so the END-gain path is exercised.
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "parry_partial_end: no enemy combatant")
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var initial_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0))

    # Proficiency gains are awarded in apply_result (not resolve_attack). Apply a parry_partial
    # result where the player (attacker) is partially parried by the enemy (defender). Momentum 0
    # skips the recoil so only the proficiency award is exercised.
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_partial", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var final_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0))
    if not (final_end > initial_end + 0.001):
        _fail(
            failures,
            (
                "parry_partial_end: defender END should increase (partial absorption) on parry_partial "
                + "(initial=%.2f final=%.2f)" % [initial_end, final_end]
            )
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a partial parry still met the line — the defender trains reflex/timing (AGI) on the
## reactive act, just less than a full deflect. Symmetric with the parry_deflect reflex AGI but
## scaled by GAIN_PARRY_PARTIAL_AGI_MULT (0.3). Untracked defenders gain none (write-side gate).


static func _run_parry_partial_awards_reflex_agi(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_partial_agi: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "parry_partial_agi: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var agi_before: float = float(enemy_ent._proficiency_bonus.get("agility", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_partial", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var agi_gain: float = float(enemy_ent._proficiency_bonus.get("agility", 0.0)) - agi_before
    if agi_gain <= 0.0:
        _fail(failures, "parry_partial_agi: partial parry should award the tracked defender AGI (got %.4f)" % agi_gain)

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a clean parry is a *read* of the incoming attack line — the parrier's perception (threat
## detection / anticipation) trains on a full deflect, and a partial parry earns the reduced share
## (GAIN_PARRY_PARTIAL_PER_MULT). Cognitive, so it is NOT scaled by the wounded-fighter factor or by
## stance/weapon modifiers. The write-side gate keeps untracked defenders flat on PER.


static func _run_parry_awards_read_per_gain(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_read_per: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true  # Tracked defender so the PER read is exercised.
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "parry_read_per: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    # XCamp-4: perception reads scale by the attacker's difficulty (desirable difficulty), so the
    # expected base read is multiplied by the same factor the production path applies.
    var diff: float = EntityProficiency.opponent_difficulty_mult(
        CombatantEntityAccess.stats_dict(atk).get(DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE),
        CombatantEntityAccess.stats_dict(enemy).get(
            DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
        )
    )
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    # Fresh entity: PER bonus 0 -> gain multiplier 1.0, so the full read lands at the base value.
    var per_before: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_gain_full: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    var expected_full: float = EntityProficiency.GAIN_PARRY_READ_PER_BASE * diff
    if absf(per_gain_full - expected_full) > 0.001:
        _fail(
            failures,
            (
                "parry_read_per: full parry should award the base PER read x difficulty "
                + "(expected %.4f got %.4f)" % [expected_full, per_gain_full]
            ),
        )
    # Partial parry earns the reduced PER read (still below NOVICE_MAX, so the multiplier stays 1.0).
    var per_before2: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_partial", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_gain_partial: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before2
    var expected_partial: float = (
        EntityProficiency.GAIN_PARRY_READ_PER_BASE * EntityProficiency.GAIN_PARRY_PARTIAL_PER_MULT * diff
    )
    if absf(per_gain_partial - expected_partial) > 0.001:
        _fail(
            failures,
            (
                "parry_read_per: partial parry should award the reduced PER read x difficulty "
                + "(expected %.4f got %.4f)" % [expected_partial, per_gain_partial]
            ),
        )

    # Untracked defender: PER must stay flat (write-side gate).
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "parry_read_per: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var enemy_ent2: CoreEntity = data2.get("enemy_ent")
    # _combat_skill_trained left false -> untracked.
    var p_id2: int = data2.get("p_id")
    var enemy2: Dictionary = mgr2.combatants[1]
    if enemy2.is_empty():
        _fail(failures, "parry_read_per: no enemy combatant2")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
        return
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    var atk2: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr2, p_id2)
    atk2.pending_attack = {"target_id": enemy_id2, "intensity": 0.5, "attack_type": "thrust"}
    var per_before3: float = float(enemy_ent2._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr2, p_id2, {"action": "parry_deflect", "target_id": enemy_id2, "parry_clash_context": pclash}
    )
    var per_gain3: float = float(enemy_ent2._proficiency_bonus.get("perception", 0.0)) - per_before3
    if absf(per_gain3) > 0.001:
        _fail(
            failures,
            (
                "parry_read_per: untracked defender should not gain PER on parry "
                + "(before %.4f got %.4f)" % [per_before3, per_gain3]
            ),
        )
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)

## Medic INT floor tracks per-entity actions (not global counter).

## Medic INT floor tracks per-entity actions (not global counter).
