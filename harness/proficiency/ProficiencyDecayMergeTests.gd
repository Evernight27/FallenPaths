class_name ProficiencyDecayMergeTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

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
        EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE
        * EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT * diff
    )
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0))
    if bonus_end < initial_end + expected_min - 0.001:
        _fail(
            failures,
            "parry_end_gains: defender END gain too low on parry_deflect "
            + "(got %.4f, want >= %.4f at diff=%.3f)" % [bonus_end, expected_min, diff]
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
            "parry_form_end: defensive form (WALL) should yield more END gain than neutral (BALANCED) (wall=%.4f, balanced=%.4f)"
            % [wall_gain, balanced_gain],
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "hit", {"dmg": 30.0})
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "hit", {"dmg": 30.0})
    var wall_gain: float = float(enemy_ent2._proficiency_bonus.get("endurance", 0.0)) - wall_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if not (wall_gain > bal_gain):
        _fail(
            failures,
            "hit_form_end: defensive form (WALL) should yield more END than neutral (BALANCED) on an absorbed hit (wall=%.4f balanced=%.4f)"
            % [wall_gain, bal_gain],
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
            "parry_reflex_agi: untracked defender should not gain AGI on parry (before %.4f got %.4f)"
            % [agi_before2, agi_gain2],
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
            "blood_peril_end_factor: must be monotonic full<half<empty (full=%.4f half=%.4f empty=%.4f)"
            % [at_full, at_half, at_empty],
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
        _fail(
            failures, "wounded_write_factor: empty blood should be ~FLOOR (got %.4f)" % at_empty
        )
    if not (at_full > at_half and at_half > at_empty):
        _fail(
            failures,
            "wounded_write_factor: must be monotonic decreasing full>half>empty (full=%.4f half=%.4f empty=%.4f)"
            % [at_full, at_half, at_empty],
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
    var str_full_gain: float = float(player_ent._proficiency_bonus.get("strength", 0.0)) - str_full_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    if str_full_gain <= 0.0:
        _fail(failures, "wounded_gain_less: full-blood attacker should gain STR on a strike attempt (got %.4f)" % str_full_gain)
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "miss", {})
    var str_low_gain: float = float(player_ent2._proficiency_bonus.get("strength", 0.0)) - str_low_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if str_low_gain <= 0.0:
        _fail(failures, "wounded_gain_less: low-blood attacker should still gain STR (got %.4f)" % str_low_gain)
        return
    if not (str_low_gain < str_full_gain):
        _fail(
            failures,
            "wounded_gain_less: low-blood attacker should gain less STR than full-blood (low=%.4f full=%.4f)"
            % [str_low_gain, str_full_gain],
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
            "exec_q: floor should clamp at MIN_PERFORMANCE_MODIFIER (got %.4f want %.4f)"
            % [floor, PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER],
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "miss", {})
    var str_dazed: float = float(player_ent2._proficiency_bonus.get("strength", 0.0)) - str_before2
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if str_dazed <= 0.0:
        _fail(failures, "dazed_trains_less: dazed attacker should still gain STR (got %.4f)" % str_dazed)
        return
    if not (str_dazed < str_healthy):
        _fail(
            failures,
            "dazed_trains_less: dazed attacker should gain less STR than healthy (dazed=%.4f healthy=%.4f)"
            % [str_dazed, str_healthy],
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr2, p_id2, enemy_id2, "miss", {})
    var wp_dazed: float = EntityProficiency.weapon_proficiency_value(player_ent2, "SWORD") - wp_before2
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if wp_dazed <= 0.0:
        _fail(failures, "dazed_weapon: dazed attacker should still gain weapon prof (got %.4f)" % wp_dazed)
        return
    if not (wp_dazed < wp_healthy):
        _fail(
            failures,
            "dazed_weapon: dazed attacker should gain less weapon prof than healthy (dazed=%.4f healthy=%.4f)"
            % [wp_dazed, wp_healthy],
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "miss", {})
    var atk_end_gain: float = float(player_ent._proficiency_bonus.get("endurance", 0.0)) - atk_end_before
    var enemy_end_after: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    if atk_end_gain <= 0.0:
        _fail(
            failures,
            "aerobic_end: full-blood tracked attacker should gain END on a committed strike (got %.4f)"
            % atk_end_gain,
        )
    if absf(enemy_end_after - enemy_end_before) > 0.001:
        _fail(
            failures,
            "aerobic_end: untracked defender must not gain END from the attacker's swing (before %.4f after %.4f)"
            % [enemy_end_before, enemy_end_after],
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
    AttackResultApplier._evaluate_counter_read_outcome(mgr, p_id, enemy_id, "wall")
    var per_correct: float = float(player_ent._proficiency_bonus.get("perception", 0.0)) - per_before

    # Reset commitment so the wrong-read case also fires (success cleared it above).
    atk[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL] = 1e9
    per_before = float(player_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier._evaluate_counter_read_outcome(mgr, p_id, enemy_id, "plow")
    var per_wrong: float = float(player_ent._proficiency_bonus.get("perception", 0.0)) - per_before

    if per_correct <= 0.0:
        _fail(failures, "counter_read_per: correct read should award PER (got %.4f)" % per_correct)
    if per_wrong <= 0.0:
        _fail(failures, "counter_read_per: wrong read should still award PER (got %.4f)" % per_wrong)
    if per_correct <= per_wrong:
        _fail(
            failures,
            "counter_read_per: correct read should beat wrong read (correct=%.4f wrong=%.4f)"
            % [per_correct, per_wrong],
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
            "dodge_read_per: a successful dodge should award the tracked defender PER (before %.4f, after %.4f)"
            % [per_before, per_after],
        )
    if per_after - per_before > EntityProficiency.GAIN_PARRY_READ_PER_BASE:
        _fail(
            failures,
            "dodge_read_per: dodge-read PER must stay under the parry-read base (got %.4f > %.4f)"
            % [per_after - per_before, EntityProficiency.GAIN_PARRY_READ_PER_BASE],
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
                "hit_windup_agi: clean hit should award the attacker wind-up AGI (before=%.4f after=%.4f)"
                % [agi_before, agi_after],
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
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "dodge", {})
    var agi_gain: float = float(player_ent._proficiency_bonus.get("agility", 0.0)) - agi_before
    if agi_gain <= 0.0:
        _fail(
            failures,
            "dodge_windup_agi: attacker should gain AGI from completed wind-up on dodge (got %.4f)"
            % agi_gain,
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
        CombatantEntityAccess.stats_dict(enemy).get(DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE)
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
            "parry_read_per: full parry should award the base PER read x difficulty "
            + "(expected %.4f got %.4f)" % [expected_full, per_gain_full],
        )
    # Partial parry earns the reduced PER read (still below NOVICE_MAX, so the multiplier stays 1.0).
    var per_before2: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_partial", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_gain_partial: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before2
    var expected_partial: float = EntityProficiency.GAIN_PARRY_READ_PER_BASE * EntityProficiency.GAIN_PARRY_PARTIAL_PER_MULT * diff
    if absf(per_gain_partial - expected_partial) > 0.001:
        _fail(
            failures,
            "parry_read_per: partial parry should award the reduced PER read x difficulty "
            + "(expected %.4f got %.4f)" % [expected_partial, per_gain_partial],
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
            "parry_read_per: untracked defender should not gain PER on parry "
            + "(before %.4f got %.4f)" % [per_before3, per_gain3],
        )
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)


## Medic INT floor tracks per-entity actions (not global counter).


## Medic INT floor tracks per-entity actions (not global counter).
static func _run_medic_int_floor_per_entity_tracking(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var Bridge := preload("res://world/CampaignEncounterBridge.gd")

    # Simulate two medic entities performing different numbers of actions.
    var ent1: Node = _new_entity("SWORD")
    var ent2: CoreEntity = _new_entity("SWORD")
    ent1._proficiency_bonus["intelligence"] = 0
    ent2._proficiency_bonus["intelligence"] = 0

    # Create a mock world node with party manager.
    var world: Node2D = Node2D.new()
    world.set_meta("party_manager", null)
    var medic_actions: Dictionary = {}
    world.set_meta("campaign_medic_actions_by", medic_actions)

    # Entity 1 performs 3 actions, entity 2 performs 5 actions.
    Bridge.record_medic_action(world, ent1)
    Bridge.record_medic_action(world, ent1)
    Bridge.record_medic_action(world, ent1)
    Bridge.record_medic_action(world, ent2)
    Bridge.record_medic_action(world, ent2)
    Bridge.record_medic_action(world, ent2)
    Bridge.record_medic_action(world, ent2)
    Bridge.record_medic_action(world, ent2)

    var stored: Dictionary = world.get_meta("campaign_medic_actions_by")
    if int(stored.get(ent1.get_instance_id(), 0)) != 3:
        _fail(
            failures,
            "medic_int_floor: entity1 should have 3 actions (got %s)" % str(stored.get(ent1.get_instance_id()))
        )
    if int(stored.get(ent2.get_instance_id(), 0)) != 5:
        _fail(
            failures,
            "medic_int_floor: entity2 should have 5 actions (got %s)" % str(stored.get(ent2.get_instance_id()))
        )

    world.queue_free()
    HarnessFixtures._free_harness_node(ent1)
    HarnessFixtures._free_harness_node(ent2)


## merge_training_pending is wired into camp heal flow.


## merge_training_pending is wired into camp heal flow.
static func _run_merge_training_pending_wired_in_camp_heal(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var ent: CoreEntity = _new_entity("SWORD")
    ProficiencyAwardPersistenceTests._set_prof_bonus(ent, "strength", 5.0)
    ent.training_pending["strength"] = 3.0
    ent.training_pending["intelligence"] = 2.0

    # Call merge directly to verify it works (the wiring is in CompanyState.try_camp_heal).
    EntityProficiency.merge_training_pending(ent)
    var merged_str: float = ProficiencyAwardPersistenceTests._get_prof_bonus(ent, "strength")
    if absf(merged_str - 8.0) > 0.01:
        _fail(failures, "merge_wired: STR should be 8.0 after merge (got %.2f)" % merged_str)

    HarnessFixtures._free_harness_node(ent)


## Decay applies on defeat (not just player victory).


## Decay applies on defeat (not just player victory).
static func _run_decay_applies_on_defeat(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")
    ent._proficiency_bonus["strength"] = 15.0
    ent.last_fought_day = -3

    # Simulate defeat scenario: decay should still apply.
    EntityProficiency.apply_decay(ent, 0)  # 3 inactive days (day 0 - (-3) = 3).
    var defeated_decay: float = float(ent._proficiency_bonus.get("strength", 15))

    # Compare with victory scenario (same decay expected).
    var ent2: CoreEntity = _new_entity("SWORD")
    ent2._proficiency_bonus["strength"] = 15.0
    ent2.last_fought_day = -3
    EntityProficiency.apply_decay(ent2, 0)
    var victory_decay: float = float(ent2._proficiency_bonus.get("strength", 15))

    if absf(defeated_decay - victory_decay) > 0.001:
        _fail(
            failures,
            "decay_defeat: defeated decay (%.4f) should match victory decay (%.4f)" % [defeated_decay, victory_decay]
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent2)


## Medical item multipliers scale INT gain correctly.


## Medical item multipliers scale INT gain correctly.
static func _run_medical_item_multipliers(failures: PackedStringArray) -> void:
    var bandage_mult: float = EntityProficiency.get_medical_item_mult("bandage")
    if absf(bandage_mult - 0.8) > 0.001:
        _fail(failures, "med_item: bandage mult should be 0.8 (got %.2f)" % bandage_mult)

    var pack_mult: float = EntityProficiency.get_medical_item_mult("pack")
    if absf(pack_mult - 1.2) > 0.001:
        _fail(failures, "med_item: pack mult should be 1.2 (got %.2f)" % pack_mult)

    var tkt_mult: float = EntityProficiency.get_medical_item_mult("tourniquet")
    if absf(tkt_mult - 1.5) > 0.001:
        _fail(failures, "med_item: tourniquet mult should be 1.5 (got %.2f)" % tkt_mult)

    var unknown_mult: float = EntityProficiency.get_medical_item_mult("unknown")
    if absf(unknown_mult - 1.0) > 0.001:
        _fail(
            failures, "med_item: unknown type should default to 1.0 (got %.2f)" % unknown_mult
        )


## Decay protection from low blood volume halves decay rate (replaces removed _in_medical_danger test).


## Decay protection from low blood volume halves decay rate (replaces removed _in_medical_danger test).
static func _run_decay_low_blood_volume_protection(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")
    ProficiencyAwardPersistenceTests._set_prof_bonus(ent, "strength", 15.0)
    ent.last_fought_day = -3
    var ent_low_bv := _new_entity("SWORD")
    ProficiencyAwardPersistenceTests._set_prof_bonus(ent_low_bv, "strength", 15.0)
    ent_low_bv.last_fought_day = -3

    EntityProficiency.apply_decay(ent, 0)
    var normal_remaining: float = ProficiencyAwardPersistenceTests._get_prof_bonus(ent, "strength")

    # Set low blood volume on second entity to test wounded protection (decay x0.5).
    ent_low_bv.blood_volume = 30.0
    EntityProficiency.apply_decay(ent_low_bv, 0)
    var low_bv_remaining: float = ProficiencyAwardPersistenceTests._get_prof_bonus(ent_low_bv, "strength")

    if low_bv_remaining <= normal_remaining:
        _fail(
            failures,
            (
                "decay_low_blood: low blood volume remaining (%.4f) should exceed normal (%.4f)"
                % [low_bv_remaining, normal_remaining]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_low_bv)


## XCamp-4: the wounded-merc protection (x0.5 decay below 55% blood) also halves weapon/form rust,
## so a gravely wounded fighter is not double-penalized by losing technique on top of their body.
static func _run_decay_low_blood_volume_protection_weapon_form(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._weapon_proficiency["SWORD"] = 15.0
    ent._form_proficiency[CombatWeaponForm.FORM_WRATH] = 15.0
    ent.last_fought_day = -3
    var ent_low_bv: CoreEntity = _new_entity("SWORD")
    ent_low_bv._combat_skill_trained = true
    ent_low_bv._weapon_proficiency["SWORD"] = 15.0
    ent_low_bv._form_proficiency[CombatWeaponForm.FORM_WRATH] = 15.0
    ent_low_bv.last_fought_day = -3

    EntityProficiency.apply_decay(ent, 0)
    var normal_wp: float = EntityProficiency.weapon_proficiency_value(ent, "SWORD")
    var normal_fp: float = EntityProficiency.form_proficiency_value(ent, CombatWeaponForm.FORM_WRATH)

    ent_low_bv.blood_volume = 30.0
    EntityProficiency.apply_decay(ent_low_bv, 0)
    var low_bv_wp: float = EntityProficiency.weapon_proficiency_value(ent_low_bv, "SWORD")
    var low_bv_fp: float = EntityProficiency.form_proficiency_value(ent_low_bv, CombatWeaponForm.FORM_WRATH)

    if low_bv_wp <= normal_wp:
        _fail(
            failures,
            (
                "decay_low_blood_wpf: wounded weapon prof remaining (%.4f) should exceed healthy (%.4f)"
                % [low_bv_wp, normal_wp]
            )
        )
    if low_bv_fp <= normal_fp:
        _fail(
            failures,
            (
                "decay_low_blood_wpf: wounded form prof remaining (%.4f) should exceed healthy (%.4f)"
                % [low_bv_fp, normal_fp]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_low_bv)


## Medical wind-up speed uses effective INT when stub is on.


## Medical wind-up speed uses effective INT when stub is on.
static func _run_medical_windup_uses_effective_int(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var mgr: Node = CombatManager.new()
    var medic_ent: CoreEntity = _new_entity("SWORD")
    medic_ent.intelligence = 100
    medic_ent._proficiency_bonus["intelligence"] = 20.0  # Effective INT = 120.
    mgr.register(medic_ent, "player")

    var patient_ent: CoreEntity = _new_entity("SWORD")
    patient_ent.intelligence = 100
    mgr.register(patient_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var eff_speed: float = CombatantEntityAccess.get_effective_medical_windup_speed_modifier(
        mgr, mgr.combatants[0], mgr.combatants[1]
    )
    var base_speed: float = CombatantEntityAccess.get_medical_windup_speed_modifier(
        mgr, mgr.combatants[0], mgr.combatants[1]
    )

    if absf(eff_speed - base_speed) < 0.01:
        _fail(
            failures, "windup_eff_int: effective (%.2f) should differ from base (%.2f)" % [eff_speed, base_speed]
        )

    HarnessFixtures._free_harness_node(mgr)


## Pain shock END slope constant is correctly named and usable.


## Pain shock END slope constant is correctly named and usable.
static func _run_pain_shock_end_slope_constant(failures: PackedStringArray) -> void:
    var slope: float = PainConsciousnessConstants.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
    if absf(slope - 0.02) > 0.001:
        _fail(failures, "pain_shock_slope: constant should be 0.02 (got %.4f)" % slope)


## Medical effectiveness formula uses correct clamp.


## Medical effectiveness formula uses correct clamp.
static func _run_medical_effectiveness_formula(failures: PackedStringArray) -> void:
    var ent: CoreEntity = _new_entity("SWORD")

    ent.intelligence = 100
    if absf(ent._get_medical_effectiveness() - 1.0) > 0.001:
        _fail(
            failures, "med_eff@100: should be 1.0 (got %.4f)" % ent._get_medical_effectiveness()
        )

    ent.intelligence = 50
    var eff_50: float = ent._get_medical_effectiveness()
    if absf(eff_50 - 0.5) > 0.001:
        _fail(failures, "med_eff@50: should be 0.5 (got %.4f)" % eff_50)

    ent.intelligence = 150
    var eff_150: float = ent._get_medical_effectiveness()
    if absf(eff_150 - 1.5) > 0.001:
        _fail(failures, "med_eff@150: should be 1.5 (got %.4f)" % eff_150)

    ent.intelligence = 200
    var eff_200: float = ent._get_medical_effectiveness()
    if absf(eff_200 - 1.5) > 0.001:
        _fail(failures, "med_eff@200: should still be 1.5 (got %.4f)" % eff_200)

    HarnessFixtures._free_harness_node(ent)


## Dodge formula uses /100 divisor instead of /200.


## Dodge formula uses /100 divisor instead of /200.
static func _run_dodge_formula_divisor(failures: PackedStringArray) -> void:
    var ent: CoreEntity = _new_entity("SWORD")
    ent.agility = 150

    # Dodge factor should be (AGI-100)/100 * 0.5 = 50/100 * 0.5 = 0.25
    var dodge_factor: float = float(ent.agility - 100) / 100.0 * 0.5
    if absf(dodge_factor - 0.25) > 0.001:
        _fail(failures, "dodge_divisor: expected 0.25 (got %.4f)" % dodge_factor)

    # Old formula would have given: 50/200 * 0.5 = 0.125 — half as much.
    var old_dodge_factor: float = float(ent.agility - 100) / 200.0 * 0.5
    if absf(old_dodge_factor - 0.125) > 0.001:
        _fail(
            failures, "dodge_divisor: old formula should give 0.125 (got %.4f)" % old_dodge_factor
        )

    HarnessFixtures._free_harness_node(ent)


## Parry multipliers extract to named constants with correct values.


## Parry multipliers extract to named constants with correct values.
static func _run_parry_constants_correct_values(failures: PackedStringArray) -> void:
    var parry_deflect_str: float = EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT
    if absf(parry_deflect_str - 0.5) > 0.001:
        _fail(failures, "parry_deflect_str_mult: expected 0.5 (got %.4f)" % parry_deflect_str)

    var parry_deflect_end: float = EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT
    if absf(parry_deflect_end - 0.5) > 0.001:
        _fail(failures, "parry_deflect_end_mult: expected 0.5 (got %.4f)" % parry_deflect_end)

    var parry_partial_str: float = EntityProficiency.GAIN_PARRY_PARTIAL_STR_MULT
    if absf(parry_partial_str - 0.3) > 0.001:
        _fail(failures, "parry_partial_str_mult: expected 0.3 (got %.4f)" % parry_partial_str)


## Direct pressure awards INT to medic and small END to patient.


## Direct pressure awards INT to medic and small END to patient.
static func _run_direct_pressure_awards_gains(failures: PackedStringArray) -> void:
    var ent1: Node = _new_entity("SWORD")
    var ent2: CoreEntity = _new_entity("SPEAR")

    # Simulate stub being ON by temporarily enabling it.
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true

    ent1._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}
    ent2._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}

    # Direct pressure INT gain: GAIN_MEDICAL_ACTION_BASE * 0.8 (bandage mult since no item specified)
    var expected_int_gain: float = (
        EntityProficiency.GAIN_MEDICAL_ACTION_BASE * EntityProficiency.GAIN_DIRECT_PRESSURE_INT_MULT
    )  # 0.5 * 0.8 = 0.4
    EntityProficiency.award_stat_gain(ent1, "intelligence", expected_int_gain)

    if absf(float(ent1._proficiency_bonus.get("intelligence", 0)) - expected_int_gain) > 0.001:
        _fail(
            failures,
            (
                "dp INT gain: expected %.4f (got %.4f)"
                % [expected_int_gain, ent1._proficiency_bonus.get("intelligence", 0)]
            )
        )

    # Direct pressure END gain for patient: GAIN_BLOOD_PERIL_BASE * GAIN_DIRECT_PRESSURE_PATIENT_END_MULT = 0.8 * 0.25 =
    # 0.2
    var expected_end_gain: float = (
        EntityProficiency.GAIN_BLOOD_PERIL_BASE * EntityProficiency.GAIN_DIRECT_PRESSURE_PATIENT_END_MULT
    )  # 0.2
    EntityProficiency.award_stat_gain(ent2, "endurance", expected_end_gain)

    if absf(float(ent2._proficiency_bonus.get("endurance", 0)) - expected_end_gain) > 0.001:
        _fail(
            failures,
            "dp END gain: expected %.4f (got %.4f)" % [expected_end_gain, ent2._proficiency_bonus.get("endurance", 0)]
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent1)
    HarnessFixtures._free_harness_node(ent2)


## Decay skips entities that never fought (_last_fought_day == 0).


## Decay skips entities that never fought (_last_fought_day == 0).
static func _run_decay_skips_never_fought_entities(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")

    ent._proficiency_bonus = {"strength": 0, "endurance": 25, "intelligence": 0, "agility": 0, "perception": 0}
    ent.last_fought_day = 0  # Never fought — should NOT decay

    EntityProficiency.apply_decay(ent, 1)  # Day 1, last_fought=0 |' skip

    if float(ent._proficiency_bonus.get("endurance", 0)) != 25.0:
        _fail(
            failures,
            "never-fought decay: endurance should stay 25 (got %.4f)" % ent._proficiency_bonus.get("endurance", 0)
        )

    # Now set last_fought_day to a past day — decay should apply.
    ent.last_fought_day = -10  # 11 inactive days on day 1
    var expected_after_decay: float = maxf(
        0.0,
        25.0 + (EntityProficiency.DECAY_RATE_VETERAN_PLUS * EntityProficiency.DECAY_MULT_END)
        * EntityProficiency.decay_inactivity_factor(11)
    )
    EntityProficiency.apply_decay(ent, 1)

    if absf(float(ent._proficiency_bonus.get("endurance", 0)) - expected_after_decay) > 0.01:
        _fail(
            failures,
            (
                "post-fight decay: expected %.4f (got %.4f)"
                % [expected_after_decay, ent._proficiency_bonus.get("endurance", 0)]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)


## Outnumbered dodge bonus uses proper slot-group alive count.


## Outnumbered dodge bonus uses proper slot-group alive count.
static func _run_outnumbered_dodge_bonus_with_slot_group_check(failures: PackedStringArray) -> void:
    var CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")

    # Build a minimal mock manager with get_combatants().
    var mock_mgr = Node.new()
    mock_mgr.name = "mock_mgr"
    var combatants := []

    # Create defender in slot group 1, player side.
    var defender := {"slot_key": "player_1_0", "side": "player", "alive": true}
    combatants.append(defender)

    # Only one alive in group |' production function returns false (no get_combatants method).
    var AttackResultApplierScript = preload("res://combat/strike/AttackResultApplier.gd")
    var is_outnumbered: bool = AttackResultApplierScript._is_defender_outnumbered(mock_mgr, defender)
    if is_outnumbered:
        _fail(
            failures, "outnumbered: production func returns false without get_combatants (expected)"
        )

    mock_mgr.queue_free()

    # Verify slot-group counting logic directly — should be 1 for defender alone, 2 with ally.
    var ally := {"slot_key": "player_1_1", "side": "player", "alive": true}
    var enemy := {"slot_key": "enemy_2_0", "side": "enemy", "alive": true}

    var group_count: int = 0
    for c in [defender, ally]:
        if not c is Dictionary:
            continue
        var c_slot := str(c.get("slot_key", "")).get_slice("_", 1)
        if c_slot != "1":
            continue
        if not c.get("alive", false):
            continue
        group_count += 1
    if group_count != 2:
        _fail(failures, "outnumbered count: should be 2 with ally (got %d)" % group_count)

    # Enemy in different group and side should not count.
    group_count = 0
    for c in [defender, enemy]:
        if not c is Dictionary:
            continue
        var c_slot := str(c.get("slot_key", "")).get_slice("_", 1)
        if c_slot != "1":
            continue
        if not c.get("alive", false):
            continue
        group_count += 1
    if group_count != 1:
        _fail(failures, "outnumbered count: enemy should not count (got %d)" % group_count)


## Post-combat stub gating: apply_decay respects read_stub_proficiency_enabled().


## Post-combat stub gating: apply_decay respects read_stub_proficiency_enabled().
static func _run_stub_gating_post_combat(failures: PackedStringArray) -> void:
    var ent: CoreEntity = _new_entity("SWORD")

    ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 20, "agility": 0, "perception": 0}
    ent.last_fought_day = -5  # Simulate last fought 6 days before day 1

    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = false

    EntityProficiency.apply_decay(ent, 1)

    if float(ent._proficiency_bonus.get("intelligence", 0)) != 20.0:
        _fail(
            failures,
            (
                "post_combat_stub_off: intelligence should stay 20 (got %.4f)"
                % ent._proficiency_bonus.get("intelligence", 0)
            )
        )

    CompanyState.proficiency_enabled = true
    var expected_after_decay: float = maxf(
        0.0,
        20.0 + (EntityProficiency.DECAY_RATE_PROFICIENT_PLUS * EntityProficiency.DECAY_MULT_INT)
        * EntityProficiency.decay_inactivity_factor(6)
    )
    EntityProficiency.apply_decay(ent, 1)

    if absf(float(ent._proficiency_bonus.get("intelligence", 0)) - expected_after_decay) > 0.01:
        _fail(
            failures,
            (
                "post_combat_stub_on: intelligence should decay to %.4f (got %.4f)"
                % [expected_after_decay, ent._proficiency_bonus.get("intelligence", 0)]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)


## Batch resolve medical actions award proficiency gains.


## Batch resolve medical actions award proficiency gains.
static func _run_batch_resolve_awards_medical_gains(failures: PackedStringArray) -> void:
    var medic_ent: CoreEntity = _new_entity("SWORD")
    var patient_ent: CoreEntity = _new_entity("SPEAR")

    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true

    medic_ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}
    patient_ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}

    # Bandage: INT gain = 0.5 * 0.8 (bandage mult) = 0.4
    EntityProficiency.award_stat_gain(
        medic_ent,
        "intelligence",
        EntityProficiency.GAIN_MEDICAL_ACTION_BASE * EntityProficiency.get_medical_item_mult("bandage")
    )
    if absf(float(medic_ent._proficiency_bonus.get("intelligence", 0)) - 0.4) > 0.001:
        _fail(
            failures, "batch bandage INT: expected 0.4 (got %.4f)" % medic_ent._proficiency_bonus.get("intelligence", 0)
        )

    # Patient END gain on successful bandage: GAIN_BLOOD_PERIL_BASE * GAIN_MEDICAL_PATIENT_END_MULT = 0.8 * 0.5 = 0.4
    EntityProficiency.award_stat_gain(
        patient_ent,
        "endurance",
        EntityProficiency.GAIN_BLOOD_PERIL_BASE * EntityProficiency.GAIN_MEDICAL_PATIENT_END_MULT
    )
    if absf(float(patient_ent._proficiency_bonus.get("endurance", 0)) - 0.4) > 0.001:
        _fail(
            failures, "batch bandage END: expected 0.4 (got %.4f)" % patient_ent._proficiency_bonus.get("endurance", 0)
        )

    # Tourniquet: INT gain = 0.5 * 1.5 (tourniquet mult) = 0.75
    medic_ent._proficiency_bonus["intelligence"] = 0.0
    EntityProficiency.award_stat_gain(
        medic_ent,
        "intelligence",
        EntityProficiency.GAIN_MEDICAL_ACTION_BASE * EntityProficiency.get_medical_item_mult("tourniquet")
    )
    if absf(float(medic_ent._proficiency_bonus.get("intelligence", 0)) - 0.75) > 0.001:
        _fail(
            failures,
            "batch tourniquet INT: expected 0.75 (got %.4f)" % medic_ent._proficiency_bonus.get("intelligence", 0)
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(medic_ent)
    HarnessFixtures._free_harness_node(patient_ent)


## Weapon/form proficiency channels and Layer C intended-part boost scaling.


## Weapon/form proficiency channels and Layer C intended-part boost scaling.
static func _run_targeting_proficiency_channels(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")
    EntityProficiency.award_weapon_proficiency(ent, "SWORD", 20.0)
    EntityProficiency.award_form_proficiency(ent, CombatWeaponForm.FORM_WRATH, 20.0)
    var boost_vet: float = EntityProficiency.intended_part_boost_mult(ent, "SWORD", CombatWeaponForm.FORM_WRATH)
    if boost_vet < 2.95:
        _fail(
            failures, "targeting_prof: veteran intended_part boost want ~3.0 got %.2f" % boost_vet
        )
    var ent_nov: CoreEntity = _new_entity("SWORD")
    var boost_nov: float = EntityProficiency.intended_part_boost_mult(ent_nov, "SWORD", CombatWeaponForm.FORM_BALANCED)
    if absf(boost_nov - 2.0) > 0.05:
        _fail(
            failures, "targeting_prof: novice intended_part boost want 2.0 got %.2f" % boost_nov
        )
    var atk: Dictionary = {
        "weapon": {"weapon_type": "SWORD"},
        "weapon_form": CombatWeaponForm.FORM_WRATH,
    }
    var move_def: Dictionary = {"contact_type": "stab", "preferred_parts": ["chest"]}
    var part: String = AttackPathResolver.resolve_hit_part(
        "high", "low", ["head", "chest", "left_arm"], {}, "chest", {}, {}, atk, move_def
    )
    if part.is_empty():
        _fail(failures, "targeting_prof: resolve_hit_part returned empty")
    # A fighter below the cap still gains on a hit (capped entity above stays at 20 by design).
    var ent_hit: CoreEntity = _new_entity("SWORD")
    EntityProficiency.award_weapon_proficiency(ent_hit, "SWORD", 5.0)
    EntityProficiency.award_form_proficiency(ent_hit, CombatWeaponForm.FORM_WRATH, 5.0)
    var wp_before: float = float(ent_hit._weapon_proficiency.get("SWORD", 0.0))
    var fp_before: float = float(ent_hit._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))
    EntityProficiency.notify_targeting_gains_from_hit(
        ent_hit, "SWORD", CombatWeaponForm.FORM_WRATH, move_def, "chest", "chest", "head"
    )
    if float(ent_hit._weapon_proficiency.get("SWORD", 0.0)) <= wp_before:
        _fail(failures, "targeting_prof: weapon prof should increase on hit")
    if float(ent_hit._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0)) <= fp_before:
        _fail(failures, "targeting_prof: form prof should increase on hit")
    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_nov)
    HarnessFixtures._free_harness_node(ent_hit)


## Swing-mechanics economy bounds (TOPIC 8a/8b/8c/8d pure functions). Stub-independent.
static func _run_swing_economy_bounds(failures: PackedStringArray) -> void:
    if absf(EntityProficiency.swing_velocity_economy(0.0) - 0.88) > 0.0001:
        _fail(failures, "swing_econ: tier0 velocity economy want 0.88 got %.4f" % EntityProficiency.swing_velocity_economy(0.0))
    if absf(EntityProficiency.swing_velocity_economy(1.0) - 1.0) > 0.0001:
        _fail(failures, "swing_econ: tier1 velocity economy want 1.0 got %.4f" % EntityProficiency.swing_velocity_economy(1.0))
    if absf(EntityProficiency.strike_mass_coupling(0.0) - 0.90) > 0.0001:
        _fail(failures, "swing_econ: tier0 mass coupling want 0.90 got %.4f" % EntityProficiency.strike_mass_coupling(0.0))
    if absf(EntityProficiency.strike_mass_coupling(1.0) - 1.0) > 0.0001:
        _fail(failures, "swing_econ: tier1 mass coupling want 1.0 got %.4f" % EntityProficiency.strike_mass_coupling(1.0))
    if absf(EntityProficiency.swing_stamina_economy(0.0) - 1.22) > 0.0001:
        _fail(failures, "swing_econ: tier0 stamina waste want 1.22 got %.4f" % EntityProficiency.swing_stamina_economy(0.0))
    if absf(EntityProficiency.swing_stamina_economy(1.0) - 1.0) > 0.0001:
        _fail(failures, "swing_econ: tier1 stamina economy want 1.0 got %.4f" % EntityProficiency.swing_stamina_economy(1.0))
    if absf(EntityProficiency.swing_skill_hold(0.0) + 0.5) > 0.0001:
        _fail(failures, "swing_econ: tier0 skill hold want -0.5 got %.4f" % EntityProficiency.swing_skill_hold(0.0))
    if absf(EntityProficiency.swing_skill_hold(1.0) - 0.5) > 0.0001:
        _fail(failures, "swing_econ: tier1 skill hold want 0.5 got %.4f" % EntityProficiency.swing_skill_hold(1.0))


## Swing-proficiency tier gating (TOPIC 8e): 1.0 for stub-off / null / untracked; combined tier otherwise.
static func _run_swing_tier_gating(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._weapon_proficiency = {"SWORD": 10.0}
    ent._form_proficiency = {CombatWeaponForm.FORM_BALANCED: 10.0}

    CompanyState.proficiency_enabled = false
    if not is_equal_approx(EntityProficiency.swing_proficiency_tier(ent, "SWORD", CombatWeaponForm.FORM_BALANCED), 1.0):
        _fail(failures, "swing_tier: stub-off should be 1.0")
    if not is_equal_approx(EntityProficiency.swing_proficiency_tier(null, "SWORD", CombatWeaponForm.FORM_BALANCED), 1.0):
        _fail(failures, "swing_tier: null entity should be 1.0")
    if EntityProficiency.is_swing_proficiency_tracked(ent):
        _fail(failures, "swing_tier: tracked ent must not be tracked while stub-off")

    CompanyState.proficiency_enabled = true
    if not is_equal_approx(EntityProficiency.swing_proficiency_tier(null, "SWORD", CombatWeaponForm.FORM_BALANCED), 1.0):
        _fail(failures, "swing_tier: null entity stub-on should be 1.0")
    if EntityProficiency.is_swing_proficiency_tracked(null):
        _fail(failures, "swing_tier: null entity must not be tracked stub-on")
    var rookie: CoreEntity = _new_entity("SWORD")
    rookie._combat_skill_trained = false
    if not is_equal_approx(EntityProficiency.swing_proficiency_tier(rookie, "SWORD", CombatWeaponForm.FORM_BALANCED), 1.0):
        _fail(failures, "swing_tier: untracked should be 1.0")
    if EntityProficiency.is_swing_proficiency_tracked(rookie):
        _fail(failures, "swing_tier: untracked entity must not be tracked")
    if not EntityProficiency.is_swing_proficiency_tracked(ent):
        _fail(failures, "swing_tier: trained ent should be tracked stub-on")
    var tier: float = EntityProficiency.swing_proficiency_tier(ent, "SWORD", CombatWeaponForm.FORM_BALANCED)
    if absf(tier - 0.5) > 0.0001:
        _fail(failures, "swing_tier: 10+10 combined want 0.5 got %.4f" % tier)

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(rookie)


## Fatigue velocity skill hold (TOPIC 8d): green loses more blade speed at the same effort, veteran holds.
static func _run_fatigue_velocity_skill_hold(failures: PackedStringArray) -> void:
    if absf(CombatConstantsStamina.fatigue_velocity_mult(1.0, 0.0, -0.5) - 1.0) > 0.0001:
        _fail(failures, "fat_hold: full stamina green should be 1.0")
    var green: float = CombatConstantsStamina.fatigue_velocity_mult(0.0, 0.0, -0.5)
    var neutral: float = CombatConstantsStamina.fatigue_velocity_mult(0.0, 0.0, 0.0)
    var veteran: float = CombatConstantsStamina.fatigue_velocity_mult(0.0, 0.0, 0.5)
    if absf(green - 0.75) > 0.0001:
        _fail(failures, "fat_hold: green zero-stamina want 0.75 got %.4f" % green)
    if absf(neutral - 0.80) > 0.0001:
        _fail(failures, "fat_hold: neutral zero-stamina want 0.80 got %.4f" % neutral)
    if absf(veteran - 0.85) > 0.0001:
        _fail(failures, "fat_hold: veteran zero-stamina want 0.85 got %.4f" % veteran)
    if not (green < neutral and neutral < veteran):
        _fail(failures, "fat_hold: ordering violated green<neutral<veteran")
    var exh_green: float = CombatConstantsStamina.fatigue_velocity_mult(1.0, 1.0, -0.5)
    var exh_veteran: float = CombatConstantsStamina.fatigue_velocity_mult(1.0, 1.0, 0.5)
    if absf(exh_green - 0.75) > 0.0001 or absf(exh_veteran - 0.85) > 0.0001:
        _fail(failures, "fat_hold: exhaustion floors wrong green=%.4f veteran=%.4f" % [exh_green, exh_veteran])


## Strike-mass coupling (TOPIC 8b): strike_mass_kg scales a fixture by strike_mass_mult; default stays 1.0.
static func _run_strike_mass_coupling(failures: PackedStringArray) -> void:
    var w: RefCounted = HarnessFixtures.get_cached_weapon("SWORD")
    if w == null:
        _fail(failures, "swing_mass: cached SWORD weapon missing")
        return
    var ai1 := AttackInstance.new("oberhau", 0.6)
    var ai2 := AttackInstance.new("oberhau", 0.6)
    ai2.strike_mass_mult = 0.9
    var m1: float = WeaponDamageHelper.strike_mass_kg(w, ai1)
    var m2: float = WeaponDamageHelper.strike_mass_kg(w, ai2)
    if m1 <= 0.0:
        _fail(failures, "swing_mass: base mass should be positive (got %.4f)" % m1)
    if absf(m1 * 0.9 - m2) > 0.001:
        _fail(failures, "swing_mass: 0.9 coupling should scale mass want %.4f got %.4f" % [m1 * 0.9, m2])
    if absf(WeaponDamageHelper.strike_mass_kg(w, AttackInstance.new("oberhau", 0.6)) - m1) > 0.0001:
        _fail(failures, "swing_mass: default mult should preserve base mass")


## Forgetting-curve / detraining shape of decay_inactivity_factor (Topic 7d).
## Pins that inactivity rusts skill fastest early and then saturates instead of draining linearly.
static func _run_decay_forgetting_curve_shape(failures: PackedStringArray) -> void:
    # Day 1 is exactly one day-equivalent of decay by construction.
    if not is_equal_approx(EntityProficiency.decay_inactivity_factor(1), 1.0):
        _fail(failures, "decay_curve: day-1 factor want 1.0 got %.4f" % EntityProficiency.decay_inactivity_factor(1))
    # Non-positive inactivity gives no decay.
    if EntityProficiency.decay_inactivity_factor(0) != 0.0 or EntityProficiency.decay_inactivity_factor(-5) != 0.0:
        _fail(failures, "decay_curve: non-positive days should give 0.0")
    # Monotonic: more layoff days never yields less decay.
    var prev: float = 0.0
    for d in range(1, 41):
        var f: float = EntityProficiency.decay_inactivity_factor(d)
        if f < prev:
            _fail(failures, "decay_curve: factor not monotonic at day %d (%.4f < %.4f)" % [d, f, prev])
        prev = f
    # Saturation: a 30-day layoff costs fewer than 30 day-equivalents (vs the old linear drain).
    if EntityProficiency.decay_inactivity_factor(30) >= 30.0:
        _fail(failures, "decay_curve: 30-day factor should be < 30 (saturating), got %.4f" % EntityProficiency.decay_inactivity_factor(30))
    # But still strictly increasing toward that bound (not flat).
    if not (EntityProficiency.decay_inactivity_factor(30) > EntityProficiency.decay_inactivity_factor(10)):
        _fail(failures, "decay_curve: 30-day factor should exceed 10-day factor")
    # Long layoffs bound near ~1/lambda day-equivalents, well below linear.
    if EntityProficiency.decay_inactivity_factor(60) >= 20.0:
        _fail(failures, "decay_curve: 60-day factor should stay < 20 (saturated), got %.4f" % EntityProficiency.decay_inactivity_factor(60))
    # Concrete value pinning the curve constant (guards against accidental re-tuning to a flat/identity shape).
    if absf(EntityProficiency.decay_inactivity_factor(5) - 4.4507) > 0.01:
        _fail(failures, "decay_curve: 5-day factor want ~4.4507 got %.4f" % EntityProficiency.decay_inactivity_factor(5))


## Gain-side severity curve (compressive clinical shape, decoupled from the AI severity score).
static func _run_gain_severity_curve(failures: PackedStringArray) -> void:
    # Compressive shape: minor < moderate < severe < critical, but the top step is smaller than the first.
    var vals: Array = [
        EntityProficiency.get_severity_mult("minor"),
        EntityProficiency.get_severity_mult("moderate"),
        EntityProficiency.get_severity_mult("severe"),
        EntityProficiency.get_severity_mult("critical"),
    ]
    if absf(vals[0] - 0.4) > 0.0001 or absf(vals[1] - 1.0) > 0.0001 \
            or absf(vals[2] - 1.4) > 0.0001 or absf(vals[3] - 1.7) > 0.0001:
        _fail(failures, "sev_gain: expected 0.4/1.0/1.4/1.7 got %s" % str(vals))
    if not (vals[0] < vals[1] and vals[1] < vals[2] and vals[2] < vals[3]):
        _fail(failures, "sev_gain: severity ordering violated %s" % str(vals))
    # Compressive: the minor->moderate jump must be larger than the severe->critical step.
    if not (vals[1] - vals[0] > vals[3] - vals[2]):
        _fail(failures, "sev_gain: curve should be compressive %s" % str(vals))
    # Decoupled from the AI wound-damage score: gain 'severe' differs from the AI 'severe' (1.5).
    if absf(EntityProficiency.get_severity_mult("severe") - float(EntityProficiency.SEVERITY_MULT["severe"])) < 0.0001:
        _fail(failures, "sev_gain: gain curve still aliased with AI SEVERITY_MULT")
    # Unknown severity falls back to 1.0.
    if absf(EntityProficiency.get_severity_mult("unknown") - 1.0) > 0.0001:
        _fail(failures, "sev_gain: unknown severity should default to 1.0")


## Opponent-difficulty multiplier is self-relative: a near-level bout is the 1.0 baseline, beating a
## stronger foe teaches more (>1.0), a weaker foe teaches less (<1.0), and an empty own-strength falls
## back to the fixed GAIN_DIFFICULTY_STR_BASE reference. The result is clamped to the [MIN, MAX] band.
static func _run_opponent_difficulty_self_relative(failures: PackedStringArray) -> void:
    # Near-level: target strength == own strength -> exactly the 1.0 baseline.
    if absf(EntityProficiency.opponent_difficulty_mult(120.0, 120.0) - 1.0) > 0.0001:
        _fail(failures, "diff_self: near-level bout should be the 1.0 baseline")
    # Beating a stronger foe teaches more.
    var stronger: float = EntityProficiency.opponent_difficulty_mult(140.0, 100.0)
    if not (stronger > 1.0):
        _fail(failures, "diff_self: stronger foe should scale up (got %.3f)" % stronger)
    # Beating a weaker foe teaches less.
    var weaker: float = EntityProficiency.opponent_difficulty_mult(60.0, 100.0)
    if not (weaker < 1.0):
        _fail(failures, "diff_self: weaker foe should scale down (got %.3f)" % weaker)
    # Self-relative: the same strong foe teaches a *weaker* attacker more than a stronger one,
    # because the gap to their own strength is larger.
    var weak_attacker: float = EntityProficiency.opponent_difficulty_mult(120.0, 80.0)
    var strong_attacker: float = EntityProficiency.opponent_difficulty_mult(120.0, 120.0)
    if not (weak_attacker > strong_attacker):
        _fail(
            failures,
            "diff_self: weaker attacker should gain more from the same strong foe (weak=%.3f strong=%.3f)"
            % [weak_attacker, strong_attacker],
        )
    # Empty own-strength (0.0) falls back to the fixed base reference.
    var base_ref: float = EntityProficiency.opponent_difficulty_mult(120.0, 0.0)
    var expected_base: float = clampf(
        1.0 + (120.0 - EntityProficiency.GAIN_DIFFICULTY_STR_BASE) * EntityProficiency.GAIN_DIFFICULTY_STR_SCALE,
        EntityProficiency.GAIN_DIFFICULTY_STR_MIN,
        EntityProficiency.GAIN_DIFFICULTY_STR_MAX
    )
    if absf(base_ref - expected_base) > 0.0001:
        _fail(failures, "diff_self: own-strength 0 should use the base reference (got %.3f want %.3f)" % [base_ref, expected_base])
    # Band clamping: a far-weak target floors at MIN.
    var floored: float = EntityProficiency.opponent_difficulty_mult(1.0, 100.0)
    if absf(floored - EntityProficiency.GAIN_DIFFICULTY_STR_MIN) > 0.0001:
        _fail(failures, "diff_self: far-weak target should clamp to MIN (got %.3f)" % floored)


## Repeated apply_decay calls within one absence (consecutive camp rests) must not re-charge
## days already decayed: total loss over a 3-day absence equals the single-shot geometric
## bound, not the full-span factor re-applied on each rest (Topic 7d saturation shape).
static func _run_decay_repeated_calls_do_not_double_charge(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true

    # Stepped: three camp rests (days 2, 3, 4) after a fight on day 1.
    var stepped: CoreEntity = _new_entity("SWORD")
    stepped._proficiency_bonus["strength"] = 25.0
    stepped.last_fought_day = 1
    EntityProficiency.apply_decay(stepped, 2)
    EntityProficiency.apply_decay(stepped, 3)
    EntityProficiency.apply_decay(stepped, 4)
    var stepped_str: float = float(stepped._proficiency_bonus.get("strength", 0.0))

    # A no-op call on the same day must not decay again.
    EntityProficiency.apply_decay(stepped, 4)
    var noop_str: float = float(stepped._proficiency_bonus.get("strength", 0.0))
    if absf(noop_str - stepped_str) > 0.0001:
        _fail(
            failures, "decay_repeat: same-day re-apply should be a no-op (%.4f -> %.4f)" % [stepped_str, noop_str]
        )

    # One-shot: a single call spanning the same absence must land on the same value.
    var one_shot: CoreEntity = _new_entity("SWORD")
    one_shot._proficiency_bonus["strength"] = 25.0
    one_shot.last_fought_day = 1
    EntityProficiency.apply_decay(one_shot, 4)
    var one_shot_str: float = float(one_shot._proficiency_bonus.get("strength", 0.0))

    if absf(stepped_str - one_shot_str) > 0.001:
        _fail(
            failures,
            "decay_repeat: stepped 3 calls (%.4f) should equal one-shot span (%.4f)" % [stepped_str, one_shot_str],
        )

    # Saturation bound: total loss must not exceed rate*mult*factor(3) (the full geometric span).
    var bound_loss: float = (
        absf(EntityProficiency.DECAY_RATE_VETERAN_PLUS * EntityProficiency.DECAY_MULT_STR)
        * EntityProficiency.decay_inactivity_factor(3)
    )
    if 25.0 - stepped_str > bound_loss + 0.0001:
        _fail(
            failures,
            "decay_repeat: loss (%.4f) exceeds saturating bound (%.4f)" % [25.0 - stepped_str, bound_loss],
        )
    if stepped_str >= 25.0:
        _fail(failures, "decay_repeat: no decay was applied (still %.4f)" % stepped_str)

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(stepped)
    HarnessFixtures._free_harness_node(one_shot)


## Weapon/form proficiency stops accumulating at the veteran cap (20): the tier clamps to 1.0 past it,
## so extra points would be pure bookkeeping that shows up as e.g. "27/20" in the roster UI.
static func _run_weapon_form_proficiency_capped_at_veteran_max(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")
    # One large gain would overshoot the cap; the stored value must not.
    EntityProficiency.award_weapon_proficiency(ent, "SWORD", 100.0)
    var wp: float = float(ent._weapon_proficiency.get("SWORD", 0.0))
    if absf(wp - EntityProficiency.WEAPON_PROF_VETERAN_MAX) > 0.001:
        _fail(
            failures,
            "wp_cap: weapon prof should cap at %.0f, got %.2f" % [EntityProficiency.WEAPON_PROF_VETERAN_MAX, wp],
        )
    EntityProficiency.award_form_proficiency(ent, CombatWeaponForm.FORM_WRATH, 100.0)
    var fp: float = float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))
    if absf(fp - EntityProficiency.FORM_PROF_VETERAN_MAX) > 0.001:
        _fail(
            failures,
            "form_cap: form prof should cap at %.0f, got %.2f" % [EntityProficiency.FORM_PROF_VETERAN_MAX, fp],
        )
    # A further award at the cap must be a no-op.
    EntityProficiency.award_weapon_proficiency(ent, "SWORD", 5.0)
    if absf(float(ent._weapon_proficiency.get("SWORD", 0.0)) - EntityProficiency.WEAPON_PROF_VETERAN_MAX) > 0.001:
        _fail(
            failures,
            "wp_cap: at-cap re-award should be a no-op, got %.2f" % float(ent._weapon_proficiency.get("SWORD", 0.0)),
        )
    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)


## XCamp-4 write-side gate: only proficiency-tracked fighters accrue stat bonuses. A full strike
## through the production path (AttackResultApplier) must grow the tracked attacker's STR on every
## resolved outcome while the untracked defender's bonuses stay exactly where they started.
static func _run_untracked_fighter_does_not_gain_stat_bonus(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "gate_untracked: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy_ent: Node = data.get("enemy_ent")

    # Fixture invariants: party player is tracked, enemy is not.
    if not ("_combat_skill_trained" in player_ent and bool(player_ent.get("_combat_skill_trained"))):
        _fail(failures, "gate_untracked: fixture player should be tracked")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    if "_combat_skill_trained" in enemy_ent and bool(enemy_ent.get("_combat_skill_trained")):
        _fail(failures, "gate_untracked: fixture enemy should be untracked")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return

    var enemy_before: Dictionary = {}
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        enemy_before[stat] = float(enemy_ent._proficiency_bonus.get(stat, 0.0))
    var player_str_before: float = float(player_ent._proficiency_bonus.get("strength", 0.0))

    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    if atk.is_empty():
        _fail(failures, "gate_untracked: no player combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {
        "target_id": 1,
        "intensity": 0.5,
        "attack_type": "thrust",
    }

    # Every resolved attacker-side outcome (miss/dodge/hit/parry) awards the wind-up STR gain.
    AttackResultApplier.apply_result(mgr, p_id, AttackResolver.resolve_attack(mgr, p_id))

    var player_str_after: float = float(player_ent._proficiency_bonus.get("strength", 0.0))
    if player_str_after <= player_str_before:
        _fail(
            failures,
            "gate_untracked: tracked attacker should gain STR on any resolved strike (before %.2f after %.2f)"
            % [player_str_before, player_str_after],
        )

    for stat in enemy_before:
        var after_val: float = float(enemy_ent._proficiency_bonus.get(stat, 0.0))
        if absf(after_val - float(enemy_before[stat])) > 0.001:
            _fail(
                failures,
                "gate_untracked: untracked defender should not accrue %s (before %.2f after %.2f)"
                % [stat, float(enemy_before[stat]), after_val],
            )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: weapon/form proficiency accrues on completed strike attempts (reps) for tracked
## fighters; untracked fighters never accrue weapon/form proficiency.
static func _run_weapon_form_attempt_gains_tracked_only(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "wp_attempt: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy_ent: Node = data.get("enemy_ent")

    # Execute a strike - any outcome (miss/dodge/hit/parry) should build player weapon prof.
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    if atk.is_empty():
        _fail(failures, "wp_attempt: no player combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {
        "target_id": 1,
        "intensity": 0.5,
        "attack_type": "thrust",
    }
    AttackResultApplier.apply_result(mgr, p_id, AttackResolver.resolve_attack(mgr, p_id))

    # Player (tracked) should have accrued some weapon proficiency regardless of outcome.
    var player_wp: float = 0.0
    if "_weapon_proficiency" in player_ent:
        for v in (player_ent._weapon_proficiency as Dictionary).values():
            player_wp += float(v)
    if player_wp <= 0.0:
        _fail(
            failures,
            "wp_attempt: tracked player should accrue weapon proficiency on a strike attempt (got %.3f)" % player_wp,
        )

    # Enemy (untracked) must have zero weapon proficiency - the write-side gate excludes them.
    var enemy_wp: float = 0.0
    if "_weapon_proficiency" in enemy_ent:
        for v in (enemy_ent._weapon_proficiency as Dictionary).values():
            enemy_wp += float(v)
    if enemy_wp > 0.0:
        _fail(failures, "wp_attempt: untracked enemy should NOT accrue weapon proficiency (got %.3f)" % enemy_wp)

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a perception read is a *cognitive* act, so it is gated by execution quality
## (pain x consciousness, blood excluded) — not by the wounded-fighter physical factor. A dazed
## parrier (low consciousness, no blood loss) reads the incoming line less sharply than an alert one,
## so their PER gain is smaller, while still accruing something. Blood loss alone does NOT reduce the
## read (the parryer here is full-blood), isolating the consciousness channel.
static func _run_dazed_parryer_reads_less(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    # Healthy parrier baseline: a full parry read lands at the base value (execution factor 1.0).
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "dazed_parry_read: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "dazed_parry_read: no enemy combatant")
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
    var per_before: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_healthy: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    # XCamp-4: the read also scales by the attacker's difficulty (desirable difficulty), so the
    # healthy baseline is base x that factor, not the raw base.
    var diff_healthy: float = EntityProficiency.opponent_difficulty_mult(
        CombatantEntityAccess.stats_dict(atk).get(DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE),
        CombatantEntityAccess.stats_dict(enemy).get(DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE)
    )
    var expected_healthy: float = EntityProficiency.GAIN_PARRY_READ_PER_BASE * diff_healthy
    if absf(per_healthy - expected_healthy) > 0.001:
        _fail(
            failures,
            "dazed_parry_read: healthy parrier should read at base x difficulty (got %.4f, want %.4f)"
            % [per_healthy, expected_healthy],
        )
        return

    # Dazed parrier: same rep, consciousness pinned at 50% (dirty flag cleared so it sticks). Full
    # blood, so the only thing reduced is the execution-quality (consciousness) channel.
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "dazed_parry_read: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var enemy_ent2: CoreEntity = data2.get("enemy_ent")
    enemy_ent2._combat_skill_trained = true
    enemy_ent2.effective_consciousness = 50.0
    enemy_ent2._consciousness_dirty = false
    var p_id2: int = data2.get("p_id")
    var enemy2: Dictionary = mgr2.combatants[1]
    if enemy2.is_empty():
        _fail(failures, "dazed_parry_read: no enemy combatant2")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
        return
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    var atk2: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr2, p_id2)
    atk2.pending_attack = {"target_id": enemy_id2, "intensity": 0.5, "attack_type": "thrust"}
    var per_before2: float = float(enemy_ent2._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr2, p_id2, {"action": "parry_deflect", "target_id": enemy_id2, "parry_clash_context": pclash}
    )
    var per_dazed: float = float(enemy_ent2._proficiency_bonus.get("perception", 0.0)) - per_before2
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if per_dazed <= 0.0:
        _fail(failures, "dazed_parry_read: dazed parrier should still read something (got %.4f)" % per_dazed)
        return
    if not (per_dazed < per_healthy):
        _fail(
            failures,
            "dazed_parry_read: dazed parrier should read less than healthy "
            + "(dazed=%.4f healthy=%.4f)" % [per_dazed, per_healthy],
        )


## XCamp-4: desirable difficulty on the perception channel — successfully parrying a *stronger*
## opponent's strike is a sharper perception lesson, so the parrier's PER read scales up with the
## attacker's strength (and down with a weaker one). Mirrors the attacker-STR scaling already applied
## on a clean hit. Isolates the difficulty dimension: the parrier is healthy and full-blooded in both
## runs (execution quality 1.0), so only the attacker's strength varies.
static func _run_stronger_foe_sharpens_parry_read(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var per_weak: float = _measure_parry_read_vs_attacker_strength(failures, 40.0)
    if per_weak == -INF:
        return
    var per_strong: float = _measure_parry_read_vs_attacker_strength(failures, 200.0)
    if per_strong == -INF:
        return
    if per_weak <= 0.0:
        _fail(failures, "strong_foe_read: parrier should read the weak attacker's line (got %.4f)" % per_weak)
        return
    if not (per_strong > per_weak):
        _fail(
            failures,
            "strong_foe_read: parrying a stronger foe should sharpen the PER read "
            + "(strong=%.4f weak=%.4f)" % [per_strong, per_weak],
        )


## XCamp-4 helper: run one healthy, full-blooded parry against an attacker whose strength is pinned
## to `str_value` and return the parrier's PER gain. Returns -INF on setup failure (already
## reported to `failures`). The parrier's own strength and execution quality are held constant, so
## only the desirable-difficulty factor varies between calls.
static func _measure_parry_read_vs_attacker_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "strong_foe_read: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "strong_foe_read: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    # Pin the attacker's strength so the desirable-difficulty factor is controlled.
    CombatantEntityAccess.stats_dict_for_mutation(atk).set(DataKeys.ENTITY_STRENGTH, str_value)
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var per_before: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_gain: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return per_gain


## XCamp-4: desirable difficulty on the *defensive physical* channel — meeting a *stronger* foe's
## blade is a harder physical/reflex lesson, so the parrier's absorbed-END (and, by the same factor,
## reflex-AGI / weapon-STR) gain scales up with the attacker's strength, mirroring the PER read that
## already scales in the same parry event. Isolates the difficulty dimension: the parrier is healthy
## and full-blooded in both runs (execution quality 1.0), so only the attacker's strength varies.
static func _run_stronger_foe_sharpens_defensive_gains(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var end_weak: float = _measure_parry_deflect_end_vs_attacker_strength(failures, 40.0)
    if end_weak == -INF:
        return
    var end_strong: float = _measure_parry_deflect_end_vs_attacker_strength(failures, 200.0)
    if end_strong == -INF:
        return
    if end_weak <= 0.0:
        _fail(failures, "strong_foe_end: parrier should absorb the weak attacker's blow (got %.4f)" % end_weak)
        return
    if not (end_strong > end_weak):
        _fail(
            failures,
            "strong_foe_end: parrying a stronger foe should train more defensive END "
            + "(strong=%.4f weak=%.4f)" % [end_strong, end_weak],
        )


## XCamp-4 helper: run one healthy, full-blooded parry_deflect against an attacker whose strength is
## pinned to `str_value` and return the parrier's END gain. Returns -INF on setup failure. The
## parrier's own strength and execution quality are held constant, so only the desirable-difficulty
## factor varies between calls.
static func _measure_parry_deflect_end_vs_attacker_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "strong_foe_end: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "strong_foe_end: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    # Pin the attacker's strength so the desirable-difficulty factor is controlled.
    CombatantEntityAccess.stats_dict_for_mutation(atk).set(DataKeys.ENTITY_STRENGTH, str_value)
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var end_before: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var end_gain: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0)) - end_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return end_gain


## XCamp-4: desirable difficulty on the attacker's weapon/form channel — landing a clean hit on a
## *stronger* opponent is a sharper weapon-handling lesson, so the weapon/form hit award scales with
## the target's strength (mirroring the hit STR gain in the same resolve). Isolates the difficulty
## dimension: both runs use a healthy, full-blooded attacker and the same 5.0 dmg.
static func _run_hit_weapon_form_scales_with_target_difficulty(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var wp_weak: float = _measure_hit_weapon_gain_vs_target_strength(failures, 40.0)
    if wp_weak == -INF:
        return
    var wp_strong: float = _measure_hit_weapon_gain_vs_target_strength(failures, 200.0)
    if wp_strong == -INF:
        return
    if wp_weak <= 0.0:
        _fail(failures, "hit_wp_diff: attacker should build SWORD prof on a clean hit (got %.4f)" % wp_weak)
        return
    if not (wp_strong > wp_weak):
        _fail(
            failures,
            "hit_wp_diff: hitting a stronger target should build more weapon prof "
            + "(strong=%.4f weak=%.4f)" % [wp_strong, wp_weak],
        )


## XCamp-4 helper: one clean hit against a target whose strength is pinned to `str_value`; returns the
## attacker's SWORD weapon-proficiency gain. Returns -INF on setup failure. Attacker health and
## execution quality are held constant, so only the target's desirable-difficulty factor varies.
static func _measure_hit_weapon_gain_vs_target_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "hit_wp_diff: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: CoreEntity = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "hit_wp_diff: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    # Pin the target's strength so the desirable-difficulty factor is controlled.
    CombatantEntityAccess.stats_dict_for_mutation(enemy).set(DataKeys.ENTITY_STRENGTH, str_value)
    var wp_before: float = float(player_ent._weapon_proficiency.get("SWORD", 0.0))
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "hit", {"dmg": 5})
    var wp_gain: float = float(player_ent._weapon_proficiency.get("SWORD", 0.0)) - wp_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return wp_gain


## XCamp-4: desirable difficulty on the attacker's STR channel — a clean hit that leaves a severe
## wound on a *stronger* opponent is a bigger lesson, so the total STR award (hit + severe-wound)
## scales with the target's strength. Isolates the difficulty dimension: healthy full-blooded
## attacker, same 5.0 dmg and wound severity in both runs.
static func _run_hit_str_scales_with_target_difficulty(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var str_weak: float = _measure_hit_str_gain_vs_target_strength(failures, 40.0)
    if str_weak == -INF:
        return
    var str_strong: float = _measure_hit_str_gain_vs_target_strength(failures, 200.0)
    if str_strong == -INF:
        return
    if str_weak <= 0.0:
        _fail(failures, "hit_str_diff: attacker should gain STR from a clean hit (got %.4f)" % str_weak)
        return
    if not (str_strong > str_weak):
        _fail(
            failures,
            "hit_str_diff: hitting a stronger target should award more STR "
            + "(strong=%.4f weak=%.4f)" % [str_strong, str_weak],
        )


## XCamp-4 helper: one clean severe hit against a target whose strength is pinned to `str_value`;
## returns the attacker's STR bonus gain (hit + severe-wound). Returns -INF on setup failure.
static func _measure_hit_str_gain_vs_target_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "hit_str_diff: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: CoreEntity = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "hit_str_diff: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.stats_dict_for_mutation(enemy).set(DataKeys.ENTITY_STRENGTH, str_value)
    var str_before: float = float(player_ent._proficiency_bonus.get("strength", 0.0))
    AttackResultApplier.notify_proficiency_gains_from_resolve(
        mgr, p_id, enemy_id, "hit", {"dmg": 5, "wound_severity": "severe"}
    )
    var str_gain: float = float(player_ent._proficiency_bonus.get("strength", 0.0)) - str_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return str_gain


## XCamp-4: desirable difficulty on the attacker's off-focus PER read — hitting where the defender is
## NOT guarding is an opponent-attention perception act, so it is harder (and a sharper lesson) against
## a *stronger* opponent. This completes the difficulty thread on the offensive cognitive channel: the
## preferred-part INT award is deliberately left unscaled because it rewards the attacker's own
## targeting execution, not a read of the opponent. Both combatants' strengths are pinned, so the
## full difficulty band (floor 0.85, baseline 1.0, ceiling 1.35) is verified end-to-end.
static func _run_off_focus_per_scales_with_target_difficulty(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Target strength probes: 0.0 and 200.0 sit well past the clamp band (with the attacker at the
    # reference base), so they exercise the floor and ceiling; the reference base exercises 1.0.
    var per_floor: float = _measure_off_focus_per_vs_target_strength(failures, 0.0)
    if per_floor == -INF:
        return
    var per_base: float = _measure_off_focus_per_vs_target_strength(
        failures, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    if per_base == -INF:
        return
    var per_ceiling: float = _measure_off_focus_per_vs_target_strength(failures, 200.0)
    if per_ceiling == -INF:
        return
    var base: float = EntityProficiency.GAIN_OFF_FOCUS_HIT_PER_BASE
    var want_floor: float = base * EntityProficiency.GAIN_DIFFICULTY_STR_MIN
    var want_base: float = base
    var want_ceiling: float = base * EntityProficiency.GAIN_DIFFICULTY_STR_MAX
    if absf(per_floor - want_floor) > 0.001:
        _fail(failures, "off_focus_per_diff: floor read want %.4f got %.4f" % [want_floor, per_floor])
    if absf(per_base - want_base) > 0.001:
        _fail(failures, "off_focus_per_diff: baseline read want %.4f got %.4f" % [want_base, per_base])
    if absf(per_ceiling - want_ceiling) > 0.001:
        _fail(failures, "off_focus_per_diff: ceiling read want %.4f got %.4f" % [want_ceiling, per_ceiling])


## XCamp-4 helper: one clean off-focus hit with the attacker's strength pinned to 100 and the target's
## to `str_value`; returns the attacker's PER bonus gain. Returns -INF on setup failure. The defender's
## focus is pinned to "head" while the strike lands off-focus on "chest", so only the off-focus PER read
## fires (no preferred-part INT, since the move id is left empty). Both combatants' strengths are held
## fixed, so only the desirable-difficulty factor varies between calls.
static func _measure_off_focus_per_vs_target_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "off_focus_per_diff: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: CoreEntity = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "off_focus_per_diff: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    # Defender is focused on "head"; the strike lands off-focus on "chest".
    enemy[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "head"
    # Pin both combatants' strengths so the difficulty factor is fully controlled. The attacker is
    # held at the reference base so the target strength is the sole driver of the difficulty factor.
    CombatantEntityAccess.stats_dict_for_mutation(atk).set(
        DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    CombatantEntityAccess.stats_dict_for_mutation(enemy).set(DataKeys.ENTITY_STRENGTH, str_value)
    var per_before: float = float(player_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.notify_proficiency_gains_from_resolve(
        mgr, p_id, enemy_id, "hit",
        {DataKeys.RESULT_PART: "chest", DataKeys.ACTION_TARGET_PART: "chest", DataKeys.RESULT_DMG: 5}
    )
    var per_gain: float = float(player_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return per_gain


## XCamp-4: weapon/form familiarity rusts with inactivity for tracked fighters only, and only above
## the 10.0 foundational floor — so a rusted fighter's aim drops in step with their rusted stats.
static func _run_weapon_form_proficiency_decays_with_inactivity(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true

    # Tracked fighter with a trained edge (above the 10.0 floor) on both weapon and form.
    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._weapon_proficiency["SWORD"] = 15.0
    ent._form_proficiency[CombatWeaponForm.FORM_WRATH] = 15.0
    ent.last_fought_day = -5  # 6 days inactive at day 0.
    var wp_before: float = float(ent._weapon_proficiency.get("SWORD", 0.0))
    var fp_before: float = float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))

    EntityProficiency.apply_decay(ent, 0)

    var wp_after: float = float(ent._weapon_proficiency.get("SWORD", 0.0))
    var fp_after: float = float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))
    if wp_after >= wp_before:
        _fail(failures, "wpf_decay: tracked weapon prof should rust (before %.2f after %.2f)" % [wp_before, wp_after])
    if fp_after >= fp_before:
        _fail(failures, "wpf_decay: tracked form prof should rust (before %.2f after %.2f)" % [fp_before, fp_after])

    # Untracked fighter: weapon/form should never have accrued, so decay is a no-op even when a
    # value is present (the write-side gate is the real protection; this proves decay respects it).
    var ent_un: CoreEntity = _new_entity("SWORD")
    ent_un._combat_skill_trained = false
    ent_un._weapon_proficiency["SWORD"] = 15.0
    ent_un.last_fought_day = -5
    var uwp_before: float = float(ent_un._weapon_proficiency.get("SWORD", 0.0))
    EntityProficiency.apply_decay(ent_un, 0)
    var uwp_after: float = float(ent_un._weapon_proficiency.get("SWORD", 0.0))
    if absf(uwp_after - uwp_before) > 0.001:
        _fail(failures, "wpf_decay: untracked weapon prof should NOT rust (before %.2f after %.2f)" % [uwp_before, uwp_after])

    # Foundational edge (<= 10.0) never rusts, mirroring the stat "foundational skill" rule.
    var ent_low: CoreEntity = _new_entity("SWORD")
    ent_low._combat_skill_trained = true
    ent_low._weapon_proficiency["SWORD"] = 8.0
    ent_low.last_fought_day = -5
    var low_before: float = float(ent_low._weapon_proficiency.get("SWORD", 0.0))
    EntityProficiency.apply_decay(ent_low, 0)
    var low_after: float = float(ent_low._weapon_proficiency.get("SWORD", 0.0))
    if absf(low_after - low_before) > 0.001:
        _fail(failures, "wpf_decay: foundational (<=10) weapon prof should NOT rust (before %.2f after %.2f)" % [low_before, low_after])

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_un)
    HarnessFixtures._free_harness_node(ent_low)


## XCamp-4: a successful parry is also a precise weapon act for the *defender* — the parrier brought
## their own blade to meet the incoming strike, so they train their weapon/form too. Gated on the
## write-side tracked flag, so an untracked parrier stays at baseline.
static func _run_parry_deflect_awards_parryer_weapon_prof(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_wp: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    # Make the defender tracked so the parry weapon/form gain is expected to fire.
    enemy_ent._combat_skill_trained = true
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])

    var wp_before: float = EntityProficiency.weapon_proficiency_value(enemy_ent, "SWORD")
    # Simulate a clean parry resolution: the defender (e_id) met the attacker's (p_id) strike.
    AttackResultApplier.notify_proficiency_gains_from_resolve(mgr, p_id, e_id, "parry_deflect", {})
    var wp_after: float = EntityProficiency.weapon_proficiency_value(enemy_ent, "SWORD")
    if wp_after <= wp_before:
        _fail(
            failures,
            "parry_wp: tracked parrier should gain weapon proficiency on a clean parry (before %.3f after %.3f)"
            % [wp_before, wp_after],
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: the rust warning fires when *any* trainable proficiency (stat bonus OR weapon/form mastery)
## is above the 10.0 foundational floor and the fighter has gone days without combat — so a fighter
## whose only trained edge is blade mastery is warned too, not just one with high stat bonuses.
static func _run_rust_note_fires_for_weapon_form_mastery(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var world: Node2D = Node2D.new()
    CompanyState.set_day_index(world, 10)

    # Weapon/form above the 10.0 floor, no stat bonuses -> should still get the rust warning.
    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._weapon_proficiency["SWORD"] = 15.0
    ent._form_proficiency[CombatWeaponForm.FORM_WRATH] = 15.0
    ent.last_fought_day = 4  # 6 days without combat.
    var note: String = PartyRowFormatter._proficiency_rust_note(ent, world)
    if note.is_empty():
        _fail(failures, "rust_note_wpf: weapon/form mastery >10 with no stat bonus should still get a rust warning")

    # Weapon/form at/below the 10.0 foundational floor -> no warning (mirrors the stat floor rule).
    var ent_low: CoreEntity = _new_entity("SWORD")
    ent_low._combat_skill_trained = true
    ent_low._weapon_proficiency["SWORD"] = 8.0
    ent_low.last_fought_day = 4
    var low_note: String = PartyRowFormatter._proficiency_rust_note(ent_low, world)
    if not low_note.is_empty():
        _fail(
            failures,
            "rust_note_wpf: foundational (<=10) weapon mastery should NOT trigger a rust warning, got '%s'"
            % low_note,
        )

    CompanyState.proficiency_enabled = old_stub
    world.queue_free()
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_low)


## XCamp-4: the combat-participation snapshot marks the *canonical* `last_fought_in_combat` property
## (the one the post-combat reader and save/load use), not an orphaned underscore variant the reader
## never sees. Guards the "did this fighter actually fight" flag that participant-gated progression
## (gains/decay only for those who fought) is built on.
static func _run_snapshot_marks_canonical_fought_flag(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var ent: CoreEntity = _new_entity("SWORD")
    world.set_meta("party_manager", {"members": [{"node_ref": ent}]})

    CampaignEncounterBridge._proficiency_snapshot_combat_participation(world)

    if not ent.last_fought_in_combat:
        _fail(
            failures,
            "fought_flag: snapshot should set the canonical last_fought_in_combat property (got %s)"
            % str(ent.last_fought_in_combat)
        )
    if "_last_fought_in_combat" in ent:
        _fail(
            failures,
            "fought_flag: snapshot should not leave an orphaned _last_fought_in_combat dynamic property"
        )

    world.queue_free()
    HarnessFixtures._free_harness_node(ent)


## XCamp-4: a fighter who fights on campaign day 0 (DEFAULT_DAY_INDEX) is recorded with
## last_fought_day >= 1, never the 0 "never fought" sentinel — so their bonuses actually decay
## on later days instead of being silently skipped forever.
static func _run_day0_fight_records_decaying_last_fought_day(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var world: Node2D = Node2D.new()
    CompanyState.set_day_index(world, 0)

    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._proficiency_bonus["strength"] = 15.0
    ent.last_fought_in_combat = true
    ent.last_fought_day = 0
    world.set_meta("party_manager", {"members": [{"node_ref": ent}]})

    # Post-combat on day 0: should clamp last_fought_day to 1, not leave it at the 0 sentinel.
    CampaignEncounterBridge._proficiency_post_combat(world)
    var recorded: int = int(ent.last_fought_day)
    if recorded == 0:
        _fail(
            failures,
            "day0_fought: day-0 fight should record last_fought_day >= 1, not the 0 'never fought' sentinel (got %d)"
            % recorded
        )

    # The bonus must actually decay on a later day (proving the recorded day is live, not skipped).
    var before: float = float(ent._proficiency_bonus["strength"])
    CompanyState.set_day_index(world, 5)
    EntityProficiency.apply_decay(ent, 5)
    var after: float = float(ent._proficiency_bonus["strength"])
    if after >= before:
        _fail(
            failures,
            "day0_fought: day-0 fighter's bonus should decay by day 5 (before %.2f after %.2f)" % [before, after]
        )

    CompanyState.proficiency_enabled = old_stub
    world.queue_free()
    HarnessFixtures._free_harness_node(ent)

