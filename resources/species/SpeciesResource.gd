class_name SpeciesResource
extends Resource

## Species data: body plan, pain reference, stat modifiers.

# Body part max health. Unit dies when head or chest reaches 0.
# Lists: BodyPartConstants (single source). BodyPartQuery reads BODY_PARTS / VITAL_PARTS from species when set.
const BODY_PARTS := BodyPartConstants.BODY_PARTS
const VITAL_PARTS := BodyPartConstants.VITAL_PARTS
const LIMB_PARTS := ["right_arm", "left_arm", "left_leg", "right_leg"]
## Narrative KE / reference mass  -  canonical values in `CombatDesignAnchors`.
const DESIGN_KE_ARM_J := CombatDesignAnchors.DESIGN_KE_ARM_J
const DESIGN_KE_LEG_J := CombatDesignAnchors.DESIGN_KE_LEG_J
const REFERENCE_ADULT_MASS_KG := CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
const REFERENCE_HUMAN_TISSUE_SUM := CombatDesignAnchors.REFERENCE_HUMAN_TISSUE_SUM
## Tuned so human @ 75 kg matches hand-tuned 12 arm / 16 leg tissue.
const DERIVED_ARM_TISSUE_FACTOR := 0.60
const DERIVED_LEG_TISSUE_FACTOR := 0.565
const DERIVED_BONE_TO_TISSUE_ARM := 8.0 / 12.0
const DERIVED_BONE_TO_TISSUE_LEG := 12.0 / 16.0

# Basic stats for a species. Save as .tres in res://resources/species/
# Tissue max = abstract capacity per part. Give each species UNIQUE mass proportions so they play differently:
#   Human: segment-mass (de Leva/Plagenhoef)  -  chest > leg > head = arm.
#   Goblin: top-heavy, spindly limbs  -  large head/chest share, thin arms/legs.
#   (Future: e.g. Orc = limb-heavy; Elf = lean limbs, smaller chest.)
# Mass proportions: clinical segment models; calibration â docs/LIVE_PATHS.md#species-calibration ·
# docs/LIVE_PATHS.md#5-literal-blood-volume-ml.
@export var name: String = "Unknown"
@export var head: int = 10  # human ~9% of total; goblin larger share
@export var chest: int = 30  # human largest; scale per species
# Tissue/bone integers = combat HP budgets (not kg). Narrative KE anchors (~100 J arm / ~200 J leg) tune
# DAMAGE_KE_SCALE; see .calibration_audit.txt.
# reference_body_mass_kg = adult kg for blunt reduced-mass (WeaponDamageHelper); -1 infers from tissue sum vs human 96.
@export var right_arm: int = 12
@export var left_arm: int = 12
@export var left_leg: int = 16
@export var right_leg: int = 16
# Bone max: scale with tissue; larger segments = more bone. Keep proportions per species.
@export var head_bone: int = 8
@export var chest_bone: int = 6
@export var right_arm_bone: int = 8
@export var left_arm_bone: int = 8
@export var left_leg_bone: int = 14
@export var right_leg_bone: int = 14
# Core attributes: one scale for all. 100 = average, 50 - 150 typical range â stat/100.0 gives 0.5 - 1.5 multiplier.
@export var strength: int = 100  # Damage, parry (50 - 150: 100 = average)
@export var agility: int = 100  # Gauge fill, dodge, cooldowns (50 - 150: 100 = average)
@export var intelligence: int = 100  # Medical effectiveness modifier (50 - 150)
@export var endurance: int = 100  # Damage resistance, pain shock resistance (50 - 150)
@export var perception: int = 100  # Dodge (not ranged accuracy) (50 - 150)
@export var description: String = ""

# Blood loss thresholds (0 - 100 remaining %). If < 0, use BleedingConstants defaults (death 35, critical 30).
# Lets different species be more/less tolerant: e.g. death at 40% = more fragile, 30% = more resilient.
@export var blood_loss_death_threshold: float = -1.0  # death when remaining <= this; -1 = use global default
# critical state when remaining <= this; -1 = use global default
@export var blood_loss_critical_threshold: float = -1.0
## Reduced-momentum blunt partner mass (kg). When > 0, overrides segment-based mass from body size.
@export var effective_blunt_target_mass_kg: float = -1.0
## Adult-scale body mass (kg) for blunt segment masses. -1 = infer from tissue totals vs human reference (see
## WeaponDamageHelper).
@export var reference_body_mass_kg: float = -1.0

# Pain reference for normalized pain (Method B). Typical pain from 1 moderate hit for this species.
# Smaller species get higher severity per damage â more pain per hit. -1 = auto-compute from body proportions.
@export var pain_reference_scale: float = -1.0
## S5 pilot: derive limb tissue/bone max from reference mass + DESIGN_KE anchors (head/chest stay exported).
@export var feature_derived_limb_capacity: bool = false


static func is_limb_part(part: String) -> bool:
    return part in LIMB_PARTS


static func is_leg_part(part: String) -> bool:
    return part == "left_leg" or part == "right_leg"


## Sum of exported tissue integers (`.tres` hand tuning). Used for mass inference, not live combat caps.
func exported_tissue_sum() -> int:
    return head + chest + right_arm + left_arm + left_leg + right_leg


## Live tissue max per part (`get_body_part_max`); respects `feature_derived_limb_capacity`.
func live_body_max_dict() -> Dictionary:
    var out: Dictionary = {}
    for p in BODY_PARTS:
        out[p] = get_body_part_max(p)
    return out


func live_tissue_sum() -> int:
    var total: int = 0
    for p in BODY_PARTS:
        total += get_body_part_max(p)
    return total


func live_pain_reference() -> float:
    return get_pain_reference(live_body_max_dict())


func resolved_reference_mass_kg() -> float:
    if reference_body_mass_kg > 0.0:
        return reference_body_mass_kg
    var total: int = exported_tissue_sum()
    if total <= 0:
        return REFERENCE_ADULT_MASS_KG
    return REFERENCE_ADULT_MASS_KG * (float(total) / float(CombatDesignAnchors.REFERENCE_HUMAN_TISSUE_SUM))


## Body-size reach scale: a smaller wielder has shorter arms, so shorter effective weapon reach (the weapon's
## blade length is fixed, but the arm that extends it scales with body size). Height proxy via cube root of the
## mass ratio; clamped to a gentle +/-10% so the effect is modest and engagement dynamics stay stable.
## Human (75 kg) -> 1.0; goblin (38 kg) -> 0.9.
func body_reach_scale() -> float:
    var mass: float = resolved_reference_mass_kg()
    if mass <= 0.0:
        return 1.0
    var height_scale: float = pow(mass / REFERENCE_ADULT_MASS_KG, 1.0 / 3.0)
    return clampf(height_scale, 0.9, 1.1)


static func derived_limb_body_max(part: String, reference_mass_kg: float) -> int:
    if not is_limb_part(part):
        return 0
    var mass_scale: float = reference_mass_kg / REFERENCE_ADULT_MASS_KG
    var design_ke: float = DESIGN_KE_LEG_J if is_leg_part(part) else DESIGN_KE_ARM_J
    var limb_factor: float = DERIVED_LEG_TISSUE_FACTOR if is_leg_part(part) else DERIVED_ARM_TISSUE_FACTOR
    var raw: float = WeaponConstants.DAMAGE_KE_SCALE * sqrt(design_ke) * limb_factor * mass_scale
    return maxi(1, int(round(raw)))


static func derived_limb_bone_max(part: String, limb_tissue_max: int) -> int:
    if not is_limb_part(part):
        return maxi(1, int(limb_tissue_max / 2.0))
    var ratio: float = DERIVED_BONE_TO_TISSUE_LEG if is_leg_part(part) else DERIVED_BONE_TO_TISSUE_ARM
    return maxi(1, int(round(float(limb_tissue_max) * ratio)))


## Mass-derived limb tissue capped by the exported hand-tuned value (preserves goblin spindly-limb intent): the
## hand-tuned export is a CEILING, so a species whose mass-derived limb toughness exceeds the export is clamped
## down to it. (A floor would use maxi(); the calibration harness pins this mini() cap.)
static func derived_limb_body_max_profiled(part: String, reference_mass_kg: float, hand_tuned_tissue: int) -> int:
    var mass_val: int = derived_limb_body_max(part, reference_mass_kg)
    return maxi(1, mini(mass_val, hand_tuned_tissue))


static func derived_limb_bone_max_profiled(part: String, profiled_tissue: int, hand_tuned_bone: int) -> int:
    var ratio_bone: int = derived_limb_bone_max(part, profiled_tissue)
    return maxi(1, mini(ratio_bone, hand_tuned_bone))


func _exported_limb_tissue(part: String) -> int:
    match part:
        "right_arm":
            return right_arm
        "left_arm":
            return left_arm
        "left_leg":
            return left_leg
        "right_leg":
            return right_leg
    return 0


func _exported_limb_bone(part: String) -> int:
    match part:
        "right_arm":
            return right_arm_bone
        "left_arm":
            return left_arm_bone
        "left_leg":
            return left_leg_bone
        "right_leg":
            return right_leg_bone
    return 1


func _derived_limb_tissue_live(part: String) -> int:
    return derived_limb_body_max_profiled(part, resolved_reference_mass_kg(), _exported_limb_tissue(part))


func _derived_limb_bone_live(part: String) -> int:
    var tissue: int = _derived_limb_tissue_live(part)
    return derived_limb_bone_max_profiled(part, tissue, _exported_limb_bone(part))


func get_body_part_max(part: String) -> int:
    if feature_derived_limb_capacity and is_limb_part(part):
        return _derived_limb_tissue_live(part)
    var by_part: Dictionary = {
        "head": head,
        "chest": chest,
        "right_arm": right_arm,
        "left_arm": left_arm,
        "left_leg": left_leg,
        "right_leg": right_leg,
    }
    return int(by_part.get(part, 0))


func get_bone_max(part: String) -> int:
    if feature_derived_limb_capacity and is_limb_part(part):
        return _derived_limb_bone_live(part)
    var by_part: Dictionary = {
        "head": head_bone,
        "chest": chest_bone,
        "right_arm": right_arm_bone,
        "left_arm": left_arm_bone,
        "left_leg": left_leg_bone,
        "right_leg": right_leg_bone,
    }
    if by_part.has(part):
        return int(by_part[part])
    return maxi(1, int(get_body_part_max(part) / 2.0))


## Typical pain from one moderate hit for this species. Used for normalized pain (Method B).
## Auto-computed from body_max sum when pain_reference_scale < 0. Human (sum 96) â ~3.
## Divisor 32: ~2 moderate hits to NRS 4 (first effect). Research: Krebs 4-6 band, acute trauma 57% NRS 5-10.
## See RESEARCH_pain_cognition_performance.md (NRS bands).
func get_pain_reference(body_max_dict: Dictionary) -> float:
    var total: int = 0
    for p in BODY_PARTS:
        total += body_max_dict.get(p, 0)
    if total <= 0:
        return 6.0  # fallback
    var base_ref: float = float(total) / 32.0  # human 96 â ~3; ~2 moderate hits to first effect
    if pain_reference_scale > 0.0:
        return base_ref * pain_reference_scale
    return base_ref
