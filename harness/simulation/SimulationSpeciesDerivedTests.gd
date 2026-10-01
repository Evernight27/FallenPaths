class_name SimulationSpeciesDerivedTests

extends SimulationCombatBase

## S1 derived-species realism: production species flag propagation, limb
## capacity references (arm/leg), goblin scaling, body-reach scale, and
## pain-reference parity against entity body max.


static func _run_sim_derived_production_species_flags(failures: PackedStringArray) -> void:
    if not HumanSpecies.feature_derived_limb_capacity:
        SimulationCombatTests._fail(
            failures, "sim_derived_flag: human.tres feature_derived_limb_capacity must be true (S5 pilot)"
        )
    if not GoblinSpecies.feature_derived_limb_capacity:
        SimulationCombatTests._fail(
            failures, "sim_derived_flag: goblin.tres feature_derived_limb_capacity must be true (S5 pilot)"
        )
    for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
        var hand_t: int = SimulationCombatBase._hand_tuned_limb_tissue(HumanSpecies, part)
        var hand_b: int = SimulationCombatBase._hand_tuned_limb_bone(HumanSpecies, part)
        if HumanSpecies.get_body_part_max(part) != hand_t or HumanSpecies.get_bone_max(part) != hand_b:
            (
                SimulationCombatTests
                . _fail(
                    failures,
                    (
                        "sim_derived_flag: human production %s tissue/bone %d/%d != hand %d/%d"
                        % [
                            part,
                            HumanSpecies.get_body_part_max(part),
                            HumanSpecies.get_bone_max(part),
                            hand_t,
                            hand_b,
                        ]
                    )
                )
            )
    for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
        var hand_t_g: int = SimulationCombatBase._hand_tuned_limb_tissue(GoblinSpecies, part)
        var hand_b_g: int = SimulationCombatBase._hand_tuned_limb_bone(GoblinSpecies, part)
        if GoblinSpecies.get_body_part_max(part) != hand_t_g or GoblinSpecies.get_bone_max(part) != hand_b_g:
            (
                SimulationCombatTests
                . _fail(
                    failures,
                    (
                        "sim_derived_flag: goblin production %s tissue/bone %d/%d != hand %d/%d"
                        % [
                            part,
                            GoblinSpecies.get_body_part_max(part),
                            GoblinSpecies.get_bone_max(part),
                            hand_t_g,
                            hand_b_g,
                        ]
                    )
                )
            )


static func _run_sim_derived_limb_capacity_human_arm_reference(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = SimulationCombatBase._species_with_derived_flag(HumanSpecies)
    var part: String = "right_arm"
    var tissue: int = sp.get_body_part_max(part)
    var bone: int = sp.get_bone_max(part)
    if not SimulationCombatBase._within_pct(tissue, 12, 0.15):
        SimulationCombatTests._fail(
            failures, "sim_derived_human_arm: tissue=%d want ~12 within 15%% (derived formula)" % tissue
        )
    if not SimulationCombatBase._within_pct(bone, 8, 0.15):
        SimulationCombatTests._fail(
            failures, "sim_derived_human_arm: bone=%d want ~8 within 15%% (derived formula)" % bone
        )
    var ent: CoreEntity = SimulationCombatBase._entity_for_species(sp)
    if int(ent.body_max.get(part, 0)) != tissue or int(ent.bone_max.get(part, 0)) != bone:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_derived_human_arm: CoreEntity caps tissue=%d bone=%d != getters %d/%d"
                % [int(ent.body_max.get(part, 0)), int(ent.bone_max.get(part, 0)), tissue, bone]
            )
        )


## S5: derived human leg tissue/bone within +/-15% of hand-tuned 16/12 when pilot flag on.


static func _run_sim_derived_limb_capacity_human_leg_reference(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = SimulationCombatBase._species_with_derived_flag(HumanSpecies)
    var part: String = "left_leg"
    var tissue: int = sp.get_body_part_max(part)
    var bone: int = sp.get_bone_max(part)
    if not SimulationCombatBase._within_pct(tissue, 16, 0.15):
        SimulationCombatTests._fail(
            failures, "sim_derived_human_leg: tissue=%d want ~16 within 15%% (derived formula)" % tissue
        )
    if not SimulationCombatBase._within_pct(bone, 12, 0.15):
        SimulationCombatTests._fail(
            failures, "sim_derived_human_leg: bone=%d want ~12 within 15%% (derived formula)" % bone
        )


## S5: lighter species gets smaller derived limb budgets than human (mass-scaled pilot).


static func _run_sim_derived_goblin_smaller_limb_than_human(failures: PackedStringArray) -> void:
    var human: SpeciesResource = SimulationCombatBase._species_with_derived_flag(HumanSpecies)
    var goblin: SpeciesResource = SimulationCombatBase._species_with_derived_flag(GoblinSpecies)
    for part in ["right_arm", "left_leg"]:
        var h_t: int = human.get_body_part_max(part)
        var g_t: int = goblin.get_body_part_max(part)
        if g_t >= h_t:
            SimulationCombatTests._fail(
                failures, "sim_derived_goblin: %s goblin tissue=%d should be < human %d" % [part, g_t, h_t]
            )
        var h_b: int = human.get_bone_max(part)
        var g_b: int = goblin.get_bone_max(part)
        if g_b >= h_b:
            SimulationCombatTests._fail(
                failures, "sim_derived_goblin: %s goblin bone=%d should be < human %d" % [part, g_b, h_b]
            )


## S5: body-size reach scaling — a smaller wielder (goblin) has shorter effective weapon reach than a human
## with the same weapon (shorter arms extend the blade less). Human (75 kg) -> 1.0; goblin (38 kg) -> ~0.9.


static func _run_sim_body_reach_scale_scales_with_species(failures: PackedStringArray) -> void:
    var human_scale: float = HumanSpecies.body_reach_scale()
    var goblin_scale: float = GoblinSpecies.body_reach_scale()
    if absf(human_scale - 1.0) > 0.001:
        SimulationCombatTests._fail(failures, "sim_reach_scale: human should be 1.0 (got %.4f)" % human_scale)
    if not (goblin_scale < human_scale - 0.001):
        SimulationCombatTests._fail(
            failures, "sim_reach_scale: goblin (%.4f) should be < human (%.4f)" % [goblin_scale, human_scale]
        )
    # Full path: a goblin wielding a sword has shorter effective reach than a human with the same sword.
    var human_ent: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var goblin_ent: CoreEntity = SimulationCombatBase._entity_for_species(GoblinSpecies)
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    human_ent.equip_weapon(sword)
    goblin_ent.equip_weapon(sword)
    var human_c: Dictionary = {DataKeys.COMBATANT_NODE: human_ent}
    var goblin_c: Dictionary = {DataKeys.COMBATANT_NODE: goblin_ent}
    var human_reach: float = CombatantEntityAccess.weapon_melee_reach(human_c)
    var goblin_reach: float = CombatantEntityAccess.weapon_melee_reach(goblin_c)
    if not (goblin_reach < human_reach - 0.001):
        SimulationCombatTests._fail(
            failures,
            "sim_reach_scale: goblin reach (%.4f) should be < human reach (%.4f)" % [goblin_reach, human_reach]
        )
    HarnessFixtures._free_harness_node(human_ent)
    HarnessFixtures._free_harness_node(goblin_ent)


## S5: profiled derived goblin limbs equal hand-tuned exports (mini mass, hand cap).


static func _run_sim_derived_goblin_limbs_match_hand_tuned(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = SimulationCombatBase._species_with_derived_flag(GoblinSpecies)
    for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
        var hand_t: int = SimulationCombatBase._hand_tuned_limb_tissue(GoblinSpecies, part)
        var hand_b: int = SimulationCombatBase._hand_tuned_limb_bone(GoblinSpecies, part)
        if sp.get_body_part_max(part) != hand_t:
            SimulationCombatTests._fail(
                failures,
                "sim_derived_goblin_hand: %s tissue=%d want hand-tuned %d" % [part, sp.get_body_part_max(part), hand_t]
            )
        if sp.get_bone_max(part) != hand_b:
            SimulationCombatTests._fail(
                failures,
                "sim_derived_goblin_hand: %s bone=%d want hand-tuned %d" % [part, sp.get_bone_max(part), hand_b]
            )


## S5: pain reference uses applied entity body_max (getters), not bypassing derived caps.


static func _run_sim_derived_pain_reference_matches_entity_body_max(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = SimulationCombatBase._species_with_derived_flag(HumanSpecies)
    var ent: CoreEntity = SimulationCombatBase._entity_for_species(sp)
    var from_entity: float = sp.get_pain_reference(ent.body_max)
    var from_getters: float = sp.live_pain_reference()
    if not is_equal_approx(from_entity, from_getters):
        SimulationCombatTests._fail(
            failures,
            "sim_derived_pain_ref: entity body_max sum pain ref %.3f != getter dict %.3f" % [from_entity, from_getters]
        )

## S6: layer KE walk conserves strike_ke_j = absorbed + remaining.
