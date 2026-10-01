class_name SimulationCombatBase

extends CombatRegressionHarnessCore

## Shared simulation fixtures: species preloads, tolerance constants, entity/
## swing constructors, fracture-wound probe, species-flag helpers, and the
## ml-pool harness entity. Shared across all Simulation* test modules.

const HumanSpecies := preload("res://resources/species/human.tres")

const GoblinSpecies := preload("res://resources/species/goblin.tres")

## Test tolerance thresholds — calibrated to floating-point variation in multi-step damage calculations.
## KE comparisons: 0.5J accounts for rounding in mass×velocity²/2 across weapon archetypes.
## Cut/blunt comparisons: 0.01 accounts for sqrt/exp variations in tissue failure functions.
const TOLERANCE_KE_J: float = 0.5

const TOLERANCE_SHARP: float = 0.01


static func _sim_entity() -> CoreEntity:
    var ent: CoreEntity = CoreEntity.new()
    HarnessFixtures._track_harness_node(ent)
    return ent


static func _oberhau_swing_instance(intensity: float, commit_frac: float) -> AttackInstance:
    var ai: AttackInstance = AttackInstance.new("oberhau", intensity)
    ai.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    if commit_frac >= 0.0:
        ai.delivery_commit_fraction = commit_frac
    return ai


## General attack-instance builder for a named move (used by the realism cross-check to
## generate committed cuts/thrusts). commit < 0 leaves the move at its natural commitment.


static func _sim_attack(move_id: String, intensity: float, commit_frac: float) -> AttackInstance:
    var ai: AttackInstance = AttackInstance.new(move_id, intensity)
    if commit_frac >= 0.0:
        ai.delivery_commit_fraction = commit_frac
    return ai


## S1: extension commit scales KE and pre_armor_cut; intensity ordering at fixed commit.


static func _has_fracture_wound(ent: Node, part: String) -> bool:
    for w: Variant in ent.wounds.get(part, []):
        if w is Dictionary and str(w.get("injury_type", "")) == BleedingConstants.INJURY_TYPE_FRACTURE:
            return true
    return false


## S3: cut-dominant, low penetration -> no fracture (old pool would often chip bone).


static func _entity_for_species(sp: SpeciesResource) -> CoreEntity:
    var ent: CoreEntity = SimulationCombatBase._sim_entity()
    ent.species = sp
    ent.apply_species()
    return ent


## S4: same raw tissue damage -> same severity on human vs goblin arm (absolute bands on).


static func _species_with_derived_flag(sp: SpeciesResource) -> SpeciesResource:
    var dup: SpeciesResource = sp.duplicate() as SpeciesResource
    dup.feature_derived_limb_capacity = true
    return dup


static func _within_pct(actual: int, expected: int, tolerance_pct: float) -> bool:
    if expected <= 0:
        return actual == expected
    var slack: int = maxi(1, int(round(float(expected) * tolerance_pct)))
    return absi(actual - expected) <= slack


## S5: human + goblin production flags on; profiled derived matches hand exports.


static func _hand_tuned_limb_tissue(sp: SpeciesResource, part: String) -> int:
    match part:
        "right_arm":
            return sp.right_arm
        "left_arm":
            return sp.left_arm
        "left_leg":
            return sp.left_leg
        "right_leg":
            return sp.right_leg
    return 0


static func _hand_tuned_limb_bone(sp: SpeciesResource, part: String) -> int:
    match part:
        "right_arm":
            return sp.right_arm_bone
        "left_arm":
            return sp.left_arm_bone
        "left_leg":
            return sp.left_leg_bone
        "right_leg":
            return sp.right_leg_bone
    return 1


## S5: derived human arm tissue/bone within +/-15% of hand-tuned 12/8 when pilot flag on.


static func _harness_entity_with_ml_pool(sp: SpeciesResource) -> CoreEntity:
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var ent: CoreEntity = SimulationCombatBase._sim_entity()
    ent.species = sp
    ent.apply_species()
    return ent

## S6 literal blood: mL max scales with species reference mass (human 75 kg -> 5250 mL via `CombatDesignAnchors`).
