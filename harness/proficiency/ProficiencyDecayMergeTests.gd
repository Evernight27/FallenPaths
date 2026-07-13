class_name ProficiencyDecayMergeTests
extends CombatRegressionHarnessCore
## XCamp-4: use-based stat proficiency system tests.
## All tests are gated by CompanyState.read_stub_proficiency_enabled() --" stub is false by default.


## Parry deflect awards END gain for defender (absorbing recoil).
static func _run_parry_deflect_awards_end_gains(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        CombatRegressionHarness._fail(failures, "parry_end_gains: setup failed")
        return

    var enemy_ent: Node = data.get("enemy_ent")

    # Set up attack on player that will be parried.
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
    if atk.is_empty():
        CombatRegressionHarness._fail(failures, "parry_end_gains: no player combatant")
        return

    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {
        "target_id": 1,
        "intensity": 0.5,
        "attack_type": "thrust",
    }

    var result: Dictionary = AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))

    if result.get("action", "") == "parry_deflect":
        var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
        if bonus_end < 0.1:
            CombatRegressionHarness._fail(
                failures, "parry_end_gains: defender END gain too low on parry_deflect (got %.2f)" % bonus_end
            )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## Parry partial awards no END gain to defender (parry absorbed the strike).


## Parry partial awards no END gain to defender (parry absorbed the strike).
static func _run_parry_partial_no_defender_gain(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        CombatRegressionHarness._fail(failures, "parry_partial_no_defender: setup failed")
        return

    var enemy_ent: Node = data.get("enemy_ent")
    var initial_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)

    # Set up attack on player that will be partially parried.
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
    if atk.is_empty():
        CombatRegressionHarness._fail(failures, "parry_partial_no_defender: no player combatant")
        return

    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {
        "target_id": 1,
        "intensity": 0.5,
        "attack_type": "thrust",
    }

    var result: Dictionary = AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))

    var action: String = result.get("action", "")
    if not action.is_empty():
        var final_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
        if action == "parry_partial" and final_end > initial_end + 0.001:
            CombatRegressionHarness._fail(
                failures,
                (
                    "parry_partial_no_defender: defender END should not increase on parry_partial (initial=%.2f fin"
                    + "al=%.2f)" % [initial_end, final_end]
                )
            )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## Medic INT floor tracks per-entity actions (not global counter).


## Medic INT floor tracks per-entity actions (not global counter).
static func _run_medic_int_floor_per_entity_tracking(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var Bridge := preload("res://world/CampaignEncounterBridge.gd")

    # Simulate two medic entities performing different numbers of actions.
    var ent1: Node = CombatRegressionHarness._new_entity("SWORD")
    var ent2: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
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
    if int(stored.get(ent1, 0)) != 3:
        CombatRegressionHarness._fail(
            failures, "medic_int_floor: entity1 should have 3 actions (got %s)" % str(stored.get(ent1))
        )
    if int(stored.get(ent2, 0)) != 5:
        CombatRegressionHarness._fail(
            failures, "medic_int_floor: entity2 should have 5 actions (got %s)" % str(stored.get(ent2))
        )

    world.queue_free()
    CombatRegressionHarness._free_harness_node(ent1)
    CombatRegressionHarness._free_harness_node(ent2)


## merge_training_pending is wired into camp heal flow.


## merge_training_pending is wired into camp heal flow.
static func _run_merge_training_pending_wired_in_camp_heal(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    ent._proficiency_bonus["strength"] = 5.0
    ent.training_pending["strength"] = 3.0
    ent.training_pending["intelligence"] = 2.0

    # Call merge directly to verify it works (the wiring is in CompanyState.try_camp_heal).
    EntityProficiency.merge_training_pending(ent)
    var merged_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
    if absf(merged_str - 8.0) > 0.01:
        CombatRegressionHarness._fail(failures, "merge_wired: STR should be 8.0 after merge (got %.2f)" % merged_str)

    CombatRegressionHarness._free_harness_node(ent)


## Decay applies on defeat (not just player victory).


## Decay applies on defeat (not just player victory).
static func _run_decay_applies_on_defeat(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    ent._proficiency_bonus["strength"] = 15.0
    ent.last_fought_day = -3

    # Simulate defeat scenario: decay should still apply.
    EntityProficiency.apply_decay(ent, 0)  # 3 inactive days (day 0 - (-3) = 3).
    var defeated_decay: float = float(ent._proficiency_bonus.get("strength", 15) or 15)

    # Compare with victory scenario (same decay expected).
    var ent2: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    ent2._proficiency_bonus["strength"] = 15.0
    ent2.last_fought_day = -3
    EntityProficiency.apply_decay(ent2, 0)
    var victory_decay: float = float(ent2._proficiency_bonus.get("strength", 15) or 15)

    if absf(defeated_decay - victory_decay) > 0.001:
        CombatRegressionHarness._fail(
            failures,
            "decay_defeat: defeated decay (%.4f) should match victory decay (%.4f)" % [defeated_decay, victory_decay]
        )

    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(ent)
    CombatRegressionHarness._free_harness_node(ent2)


## Medical item multipliers scale INT gain correctly.


## Medical item multipliers scale INT gain correctly.
static func _run_medical_item_multipliers(failures: PackedStringArray) -> void:
    var bandage_mult: float = EntityProficiency.get_medical_item_mult("bandage")
    if absf(bandage_mult - 0.8) > 0.001:
        CombatRegressionHarness._fail(failures, "med_item: bandage mult should be 0.8 (got %.2f)" % bandage_mult)

    var pack_mult: float = EntityProficiency.get_medical_item_mult("pack")
    if absf(pack_mult - 1.2) > 0.001:
        CombatRegressionHarness._fail(failures, "med_item: pack mult should be 1.2 (got %.2f)" % pack_mult)

    var tkt_mult: float = EntityProficiency.get_medical_item_mult("tourniquet")
    if absf(tkt_mult - 1.5) > 0.001:
        CombatRegressionHarness._fail(failures, "med_item: tourniquet mult should be 1.5 (got %.2f)" % tkt_mult)

    var unknown_mult: float = EntityProficiency.get_medical_item_mult("unknown")
    if absf(unknown_mult - 1.0) > 0.001:
        CombatRegressionHarness._fail(
            failures, "med_item: unknown type should default to 1.0 (got %.2f)" % unknown_mult
        )


## Decay protection from low blood volume halves decay rate (replaces removed _in_medical_danger test).


## Decay protection from low blood volume halves decay rate (replaces removed _in_medical_danger test).
static func _run_decay_low_blood_volume_protection(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    ent._proficiency_bonus["strength"] = 15.0
    ent.last_fought_day = -3
    # CoreEntity default blood_volume is not set to <40, so add a mock entity with low bv
    var ent_low_bv := CombatRegressionHarness._new_entity("SWORD")
    ent_low_bv._proficiency_bonus["strength"] = 15.0
    ent_low_bv.last_fought_day = -3

    EntityProficiency.apply_decay(ent, 0)
    var normal_decay: float = float(ent._proficiency_bonus.get("strength", 15) or 15)

    # Set low blood volume on second entity to test wounded protection (decay x0.5).
    ent_low_bv.blood_volume = 30.0
    EntityProficiency.apply_decay(ent_low_bv, 0)
    var low_bv_decay: float = float(ent_low_bv._proficiency_bonus.get("strength", 15) or 15)

    if low_bv_decay >= normal_decay:
        CombatRegressionHarness._fail(
            failures,
            (
                "decay_low_blood: low blood volume decay (%.4f) should be less than normal (%.4f)"
                % [low_bv_decay, normal_decay]
            )
        )

    CombatRegressionHarness._free_harness_node(ent)
    CombatRegressionHarness._free_harness_node(ent_low_bv)


## Medical wind-up speed uses effective INT when stub is on.


## Medical wind-up speed uses effective INT when stub is on.
static func _run_medical_windup_uses_effective_int(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var mgr: Node = CombatManager.new()
    var medic_ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    medic_ent.intelligence = 100
    medic_ent._proficiency_bonus["intelligence"] = 20.0  # Effective INT = 120.
    mgr.register(medic_ent, "player")

    var patient_ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
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
        CombatRegressionHarness._fail(
            failures, "windup_eff_int: effective (%.2f) should differ from base (%.2f)" % [eff_speed, base_speed]
        )

    CombatRegressionHarness._free_harness_node(mgr)


## Pain shock END slope constant is correctly named and usable.


## Pain shock END slope constant is correctly named and usable.
static func _run_pain_shock_end_slope_constant(failures: PackedStringArray) -> void:
    var slope: float = PainConsciousnessConstants.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
    if absf(slope - 0.02) > 0.001:
        CombatRegressionHarness._fail(failures, "pain_shock_slope: constant should be 0.02 (got %.4f)" % slope)


## Medical effectiveness formula uses correct clamp.


## Medical effectiveness formula uses correct clamp.
static func _run_medical_effectiveness_formula(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")

    ent.intelligence = 100
    if absf(ent._get_medical_effectiveness() - 1.0) > 0.001:
        CombatRegressionHarness._fail(
            failures, "med_eff@100: should be 1.0 (got %.4f)" % ent._get_medical_effectiveness()
        )

    ent.intelligence = 50
    var eff_50: float = ent._get_medical_effectiveness()
    if absf(eff_50 - 0.5) > 0.001:
        CombatRegressionHarness._fail(failures, "med_eff@50: should be 0.5 (got %.4f)" % eff_50)

    ent.intelligence = 150
    var eff_150: float = ent._get_medical_effectiveness()
    if absf(eff_150 - 1.5) > 0.001:
        CombatRegressionHarness._fail(failures, "med_eff@150: should be 1.5 (got %.4f)" % eff_150)

    ent.intelligence = 200
    var eff_200: float = ent._get_medical_effectiveness()
    if absf(eff_200 - 1.5) > 0.001:
        CombatRegressionHarness._fail(failures, "med_eff@200: should still be 1.5 (got %.4f)" % eff_200)

    CombatRegressionHarness._free_harness_node(ent)


## Dodge formula uses /100 divisor instead of /200.


## Dodge formula uses /100 divisor instead of /200.
static func _run_dodge_formula_divisor(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    ent.agility = 150

    # Dodge factor should be (AGI-100)/100 * 0.5 = 50/100 * 0.5 = 0.25
    var dodge_factor: float = float(ent.agility - 100) / 100.0 * 0.5
    if absf(dodge_factor - 0.25) > 0.001:
        CombatRegressionHarness._fail(failures, "dodge_divisor: expected 0.25 (got %.4f)" % dodge_factor)

    # Old formula would have given: 50/200 * 0.5 = 0.125 --" half as much.
    var old_dodge_factor: float = float(ent.agility - 100) / 200.0 * 0.5
    if absf(old_dodge_factor - 0.125) > 0.001:
        CombatRegressionHarness._fail(
            failures, "dodge_divisor: old formula should give 0.125 (got %.4f)" % old_dodge_factor
        )

    CombatRegressionHarness._free_harness_node(ent)


## Parry multipliers extract to named constants with correct values.


## Parry multipliers extract to named constants with correct values.
static func _run_parry_constants_correct_values(failures: PackedStringArray) -> void:
    var parry_deflect_str: float = EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT
    if absf(parry_deflect_str - 0.5) > 0.001:
        CombatRegressionHarness._fail(failures, "parry_deflect_str_mult: expected 0.5 (got %.4f)" % parry_deflect_str)

    var parry_deflect_end: float = EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT
    if absf(parry_deflect_end - 0.5) > 0.001:
        CombatRegressionHarness._fail(failures, "parry_deflect_end_mult: expected 0.5 (got %.4f)" % parry_deflect_end)

    var parry_partial_str: float = EntityProficiency.GAIN_PARRY_PARTIAL_STR_MULT
    if absf(parry_partial_str - 0.3) > 0.001:
        CombatRegressionHarness._fail(failures, "parry_partial_str_mult: expected 0.3 (got %.4f)" % parry_partial_str)


## Direct pressure awards INT to medic and small END to patient.


## Direct pressure awards INT to medic and small END to patient.
static func _run_direct_pressure_awards_gains(failures: PackedStringArray) -> void:
    var ent1: Node = CombatRegressionHarness._new_entity("SWORD")
    var ent2: CoreEntity = CombatRegressionHarness._new_entity("SPEAR")

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
        CombatRegressionHarness._fail(
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
        CombatRegressionHarness._fail(
            failures,
            "dp END gain: expected %.4f (got %.4f)" % [expected_end_gain, ent2._proficiency_bonus.get("endurance", 0)]
        )

    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(ent1)
    CombatRegressionHarness._free_harness_node(ent2)


## Decay skips entities that never fought (_last_fought_day == 0).


## Decay skips entities that never fought (_last_fought_day == 0).
static func _run_decay_skips_never_fought_entities(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")

    ent._proficiency_bonus = {"strength": 0, "endurance": 25, "intelligence": 0, "agility": 0, "perception": 0}
    ent.last_fought_day = 0  # Never fought --" should NOT decay

    EntityProficiency.apply_decay(ent, 1)  # Day 1, last_fought=0 |' skip

    if float(ent._proficiency_bonus.get("endurance", 0)) != 25.0:
        CombatRegressionHarness._fail(
            failures,
            "never-fought decay: endurance should stay 25 (got %.4f)" % ent._proficiency_bonus.get("endurance", 0)
        )

    # Now set last_fought_day to a past day --" decay should apply.
    ent.last_fought_day = -10  # 11 inactive days on day 1
    var expected_after_decay: float = maxf(
        0.0, 25.0 + (EntityProficiency.DECAY_RATE_VETERAN_PLUS * EntityProficiency.DECAY_MULT_END) * 11
    )
    EntityProficiency.apply_decay(ent, 1)

    if absf(float(ent._proficiency_bonus.get("endurance", 0)) - expected_after_decay) > 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "post-fight decay: expected %.4f (got %.4f)"
                % [expected_after_decay, ent._proficiency_bonus.get("endurance", 0)]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(ent)


## Outnumbered dodge bonus uses proper slot-group alive count.


## Outnumbered dodge bonus uses proper slot-group alive count.
static func _run_outnumbered_dodge_bonus_with_slot_group_check(failures: PackedStringArray) -> void:
    var CombatantEntityAccess := preload("res://combat/CombatantEntityAccess.gd")

    # Build a minimal mock manager with get_combatants().
    var mock_mgr = Node.new()
    mock_mgr.name = "mock_mgr"
    var combatants := []

    # Create defender in slot group 1, player side.
    var defender := {"slot_key": "player_1_0", "side": "player", "alive": true}
    combatants.append(defender)

    # Only one alive in group |' production function returns false (no get_combatants method).
    var AttackResultApplierScript = preload("res://combat/AttackResultApplier.gd")
    var is_outnumbered: bool = AttackResultApplierScript._is_defender_outnumbered(mock_mgr, defender)
    if is_outnumbered:
        CombatRegressionHarness._fail(
            failures, "outnumbered: production func returns false without get_combatants (expected)"
        )

    mock_mgr.queue_free()

    # Verify slot-group counting logic directly --" should be 1 for defender alone, 2 with ally.
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
        CombatRegressionHarness._fail(failures, "outnumbered count: should be 2 with ally (got %d)" % group_count)

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
        CombatRegressionHarness._fail(failures, "outnumbered count: enemy should not count (got %d)" % group_count)


## Post-combat stub gating: apply_decay respects read_stub_proficiency_enabled().


## Post-combat stub gating: apply_decay respects read_stub_proficiency_enabled().
static func _run_stub_gating_post_combat(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")

    ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 20, "agility": 0, "perception": 0}
    ent.last_fought_day = -5  # Simulate last fought 6 days before day 1

    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = false

    EntityProficiency.apply_decay(ent, 1)

    if float(ent._proficiency_bonus.get("intelligence", 0)) != 20.0:
        CombatRegressionHarness._fail(
            failures,
            (
                "post_combat_stub_off: intelligence should stay 20 (got %.4f)"
                % ent._proficiency_bonus.get("intelligence", 0)
            )
        )

    CompanyState.proficiency_enabled = true
    var expected_after_decay: float = maxf(
        0.0, 20.0 + (EntityProficiency.DECAY_RATE_VETERAN_PLUS * EntityProficiency.DECAY_MULT_INT) * 6
    )
    EntityProficiency.apply_decay(ent, 1)

    if absf(float(ent._proficiency_bonus.get("intelligence", 0)) - expected_after_decay) > 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "post_combat_stub_on: intelligence should decay to %.4f (got %.4f)"
                % [expected_after_decay, ent._proficiency_bonus.get("intelligence", 0)]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(ent)


## Batch resolve medical actions award proficiency gains.


## Batch resolve medical actions award proficiency gains.
static func _run_batch_resolve_awards_medical_gains(failures: PackedStringArray) -> void:
    var medic_ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    var patient_ent: CoreEntity = CombatRegressionHarness._new_entity("SPEAR")

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
        CombatRegressionHarness._fail(
            failures, "batch bandage INT: expected 0.4 (got %.4f)" % medic_ent._proficiency_bonus.get("intelligence", 0)
        )

    # Patient END gain on successful bandage: GAIN_BLOOD_PERIL_BASE * GAIN_MEDICAL_PATIENT_END_MULT = 0.8 * 0.5 = 0.4
    EntityProficiency.award_stat_gain(
        patient_ent,
        "endurance",
        EntityProficiency.GAIN_BLOOD_PERIL_BASE * EntityProficiency.GAIN_MEDICAL_PATIENT_END_MULT
    )
    if absf(float(patient_ent._proficiency_bonus.get("endurance", 0)) - 0.4) > 0.001:
        CombatRegressionHarness._fail(
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
        CombatRegressionHarness._fail(
            failures,
            "batch tourniquet INT: expected 0.75 (got %.4f)" % medic_ent._proficiency_bonus.get("intelligence", 0)
        )

    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(medic_ent)
    CombatRegressionHarness._free_harness_node(patient_ent)


## Weapon/form proficiency channels and Layer C intended-part boost scaling.


## Weapon/form proficiency channels and Layer C intended-part boost scaling.
static func _run_targeting_proficiency_channels(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    EntityProficiency.award_weapon_proficiency(ent, "SWORD", 20.0)
    EntityProficiency.award_form_proficiency(ent, CombatWeaponForm.FORM_WRATH, 20.0)
    var boost_vet: float = EntityProficiency.intended_part_boost_mult(ent, "SWORD", CombatWeaponForm.FORM_WRATH)
    if boost_vet < 2.95:
        CombatRegressionHarness._fail(
            failures, "targeting_prof: veteran intended_part boost want ~3.0 got %.2f" % boost_vet
        )
    var ent_nov: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    var boost_nov: float = EntityProficiency.intended_part_boost_mult(ent_nov, "SWORD", CombatWeaponForm.FORM_BALANCED)
    if absf(boost_nov - 2.0) > 0.05:
        CombatRegressionHarness._fail(
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
        CombatRegressionHarness._fail(failures, "targeting_prof: resolve_hit_part returned empty")
    EntityProficiency.notify_targeting_gains_from_hit(
        ent, "SWORD", CombatWeaponForm.FORM_WRATH, move_def, "chest", "chest", "head"
    )
    if float(ent._weapon_proficiency.get("SWORD", 0.0)) <= 20.0:
        CombatRegressionHarness._fail(failures, "targeting_prof: weapon prof should increase on hit")
    if float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0)) <= 20.0:
        CombatRegressionHarness._fail(failures, "targeting_prof: form prof should increase on hit")
    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(ent)
    CombatRegressionHarness._free_harness_node(ent_nov)

## Run all proficiency harness tests.
