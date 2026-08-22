class_name CombatConstantsDamage
extends RefCounted

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

const MISS_CHANCE_BASE := 0.08
const HIT_CHANCE_PERCEPTION_MIN := 0.8
const HIT_CHANCE_PERCEPTION_MAX := 1.2
## Minimum cap on effective hit chance after all multiplicative penalties (stamina, pain, fatigue).
## HEMA shows ~50-70% contact rate at close range; compounding penalties were collapsing to 20-40%.
const HIT_CHANCE_MIN_CAP := 0.45
const GLANCING_DAMAGE_RATIO := 0.1
const GLANCING_DAMAGE_ABSOLUTE_FLOOR := 0.3
const PHYSICAL_DAMAGE_ZERO_EPS := 1e-4

## Williams formula (KE/55)^0.6 outputs RHA penetration calibrated against steel plate tests.
## For unarmored targets, tissue yields and bleeds rather than deforming rigidly like steel,
## so energy dissipates through different failure modes (laceration vs plastic deformation).
## This factor was reserved for a future conversion from RHA penetration to soft-tissue depth.
## Attinger et al. (J. Trauma 62:686, 2007) suggests tissue is ~74× easier to penetrate than RHA by depth,
## but this constant is not currently used in the damage pipeline.
# const FLESH_EQUIVALENT_PENETRATION_FACTOR := 74.0  # Reserved: tissue-to-RHA penetration depth ratio; see Attinger et al. J. Trauma 62:686 (2007)

## R4: Minimum tissue floor for blunt damage — after armor absorption, at least this fraction of
## pre-armor blunt value must remain as tissue damage. Prevents high-KE blunt weapons from allocating
## nearly all post-armor damage to bone while doing almost zero soft-tissue trauma.
const BLUNT_MIN_TISSUE_FLOOR_MULT := 0.30

## Measure-ratio hit penalty (heuristic). At ratio=1.2 (attacker overextended by 20%),
## hit chance multiplier drops to this floor. Models short-weapon-at-range targeting loss.
## Formula: lerp(1.0, FLOOR, clampf((ratio - 1.0) * 5.0, 0, 1)) — full penalty at ratio >= 1.2.
const MEASURE_HIT_CHANCE_FLOOR := 0.55

const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 100.0
const INTENSITY_STRENGTH_BIAS := 0.35
const INTENSITY_RANDOM_RANGE := 0.2
