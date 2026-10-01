class_name BodyPartQuery

extends RefCounted

## Body part lists, targeting, and part-state queries (operable vs severed/crushed/destroyed, arm/leg functionality).
## Targeting uses is_part_physically_operable: cut, blunt, and bone (if bone_max > 0) must all be > 0.
## Entity must have: species (with BODY_PARTS, VITAL_PARTS), body_cutting, body_blunt, bone_health, body_max, bone_max.
## Optional for get_attacking_arm: dominant_hand, offhand_functionality (caller can implement on entity using these
## helpers).
## Canonical membership helpers: `is_arm()`, `is_leg()`, `is_vital()`, `is_limb()`  -  replace all hardcoded string
## comparisons.
const LIMB_PARTS := [
    BodyPartConstants.PART_RIGHT_ARM,
    BodyPartConstants.PART_LEFT_ARM,
    BodyPartConstants.PART_RIGHT_LEG,
    BodyPartConstants.PART_LEFT_LEG
]

const ARM_PARTS := [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM]

const LEG_PARTS := [BodyPartConstants.PART_RIGHT_LEG, BodyPartConstants.PART_LEFT_LEG]

const HEAD_CHEST_PARTS := [BodyPartConstants.PART_HEAD, BodyPartConstants.PART_CHEST]

const _PART_OPERABILITY_CHANNEL_WEIGHTS: Dictionary = {
    "cutting": 0.45,
    "blunt": 0.35,
    "bone": 0.20,
}

## Minimum operability threshold for a part to be considered functional (raised from 0.10 to 0.15 then 0.20).
## At 0.20: bone alone contributes 20% (if intact) but requires some tissue to drop below threshold.
const PART_OPERABILITY_THRESHOLD: float = 0.20

## Minimum tissue factor for an arm to retain grip strength and wield a weapon.
## Clinical basis: <15% remaining tissue means insufficient muscle/tendon integrity for grip.
## An arm at this level may still be targeted but cannot functionally attack.
const ARM_GRIP_TISSUE_THRESHOLD: float = 0.15

## Minimum bone health ratio for any limb to remain functional (below this, structural integrity fails).
const LIMB_BONE_FUNCTIONAL_RATIO: float = 0.15


## Check if a body part name is an arm (canonical  -  replaces hardcoded string comparisons).
static func is_arm(part: String) -> bool:
    return part in ARM_PARTS


## Check if a body part name is a leg (canonical).


static func is_leg(part: String) -> bool:
    return part in LEG_PARTS


## Check if a body part name is a limb (arm or leg, canonical  -  replaces LIMB_PARTS checks).


static func is_limb(part: String) -> bool:
    return part in LIMB_PARTS


## Check if a body part name is head or chest (vital regions, canonical).


static func is_vital_region(part: String) -> bool:
    return part in HEAD_CHEST_PARTS


static func get_body_part_list(entity: Node) -> Array:
    if entity.species != null and "BODY_PARTS" in entity.species:
        return entity.species.BODY_PARTS.duplicate()
    return BodyPartConstants.BODY_PARTS.duplicate()


static func get_vital_parts(entity: Node) -> Array:
    if entity.species != null and "VITAL_PARTS" in entity.species:
        return entity.species.VITAL_PARTS.duplicate()
    return BodyPartConstants.VITAL_PARTS.duplicate()


# --- Part state: severed (cut+bone 0), crushed (blunt+bone 0), destroyed (either) ---


static func is_part_severed(entity: Node, part: String) -> bool:
    return entity.body_cutting.get(part, 0.0) <= 0.0 and entity.bone_health.get(part, 0.0) <= 0.0


static func is_part_crushed(entity: Node, part: String) -> bool:
    return entity.body_blunt.get(part, 0.0) <= 0.0 and entity.bone_health.get(part, 0.0) <= 0.0


static func is_part_destroyed(entity: Node, part: String) -> bool:
    return is_part_severed(entity, part) or is_part_crushed(entity, part)


## Limb/part can still function and receive aimed blows: all channels that exist for the part must be > 0.
## If cutting OR blunt OR bone (when this part has bone_max > 0) reaches zero, the part is inoperable and excluded from
## targeting.


static func get_part_operability(entity: Node, part: String) -> float:
    if not part in entity.body_cutting or not part in entity.body_blunt:
        return 0.0
    var cutting_max: float = maxf(1.0, float(entity.body_max.get(part, 10)))
    var blunt_max: float = maxf(1.0, float(entity.body_max.get(part, 10)))
    var cutting_ratio: float = clampf(entity.body_cutting.get(part, 0.0) / cutting_max, 0.0, 1.0)
    var blunt_ratio: float = clampf(entity.body_blunt.get(part, 0.0) / blunt_max, 0.0, 1.0)
    var bone_ratio: float = 1.0
    if entity.get("bone_health") != null and entity.get("bone_max") != null:
        var bmx: int = entity.bone_max.get(part, 0)
        if bmx > 0:
            bone_ratio = clampf(entity.bone_health.get(part, float(bmx)) / float(bmx), 0.0, 1.0)
    return (
        cutting_ratio * _PART_OPERABILITY_CHANNEL_WEIGHTS["cutting"]
        + blunt_ratio * _PART_OPERABILITY_CHANNEL_WEIGHTS["blunt"]
        + bone_ratio * _PART_OPERABILITY_CHANNEL_WEIGHTS["bone"]
    )


static func is_part_physically_operable(entity: Node, part: String) -> bool:
    var operability: float = get_part_operability(entity, part)
    return operability >= PART_OPERABILITY_THRESHOLD


static func get_targetable_parts(entity: Node) -> Array:
    var out: Array = []
    for part in get_body_part_list(entity):
        if is_part_physically_operable(entity, part):
            out.append(part)
    return out


# --- Bone functionality (research-based tiers) ---


static func get_bone_functionality_factor(entity: Node, part: String) -> float:
    var cur: float = entity.bone_health.get(part, 0.0)
    var mx: int = entity.bone_max.get(part, 1)
    if mx <= 0:
        return 0.0
    if cur <= 0.0:
        return 0.0
    var ratio: float = cur / float(mx)
    if ratio <= 0.25:
        return 0.15
    if ratio <= 0.5:
        return 0.40
    if ratio <= 0.75:
        return 0.70
    if ratio < 1.0:
        return 0.92
    return 1.0


# --- Arm-only: tissue factor and combined arm functionality ---


static func get_arm_tissue_factor(entity: Node, part: String) -> float:
    if not is_arm(part):
        return 0.0
    var max_per_type: int = entity.body_max.get(part, 0)
    if max_per_type <= 0:
        return 0.0
    var combined_max: float = float(max_per_type * 2)
    var remaining: float = entity.body_cutting.get(part, 0.0) + entity.body_blunt.get(part, 0.0)
    return clampf(remaining / combined_max, 0.0, 1.0)


static func is_arm_destroyed(entity: Node, part: String) -> bool:
    if not is_arm(part):
        return true
    # Arm must have meaningful tissue left to grip/hold weapon — even with intact bone, a flayed/severed arm
    # cannot wield a weapon. Tissue factor < ARM_GRIP_TISSUE_THRESHOLD means insufficient muscle/tendon for grip.
    var tissue_factor: float = get_arm_tissue_factor(entity, part)
    if tissue_factor < ARM_GRIP_TISSUE_THRESHOLD:
        return true
    return not is_part_physically_operable(entity, part)


static func get_arm_functionality(entity: Node, part: String) -> float:
    if not is_arm(part):
        return 0.0
    var operability: float = get_part_operability(entity, part)
    if operability < PART_OPERABILITY_THRESHOLD:
        return 0.0
    var tissue: float = get_arm_tissue_factor(entity, part)
    var bone_factor: float = get_bone_functionality_factor(entity, part)
    # Below grip threshold, functionality drops sharply — can't effectively wield weapon even if technically operable.
    var grip_penalty: float = 1.0
    if tissue < ARM_GRIP_TISSUE_THRESHOLD:
        grip_penalty = tissue / maxf(ARM_GRIP_TISSUE_THRESHOLD, 0.001)
    # CAMP-SCAR-1 §9.5: a scarred/contracted/malunited arm grips weaker than the acute-wound
    # tissue/bone measure captures (elasticity loss + flexion contracture persist after healing).
    if entity.has_method("_get_scar_part_penalty"):
        grip_penalty *= float(entity._get_scar_part_penalty(part).get("grip", 1.0))
    var combined: float = clampf(tissue * bone_factor, 0.0, 1.0)
    return clampf(combined * operability / maxf(operability, PART_OPERABILITY_THRESHOLD) * grip_penalty, 0.0, 1.0)


# --- Arm-only: sub-region + severity weapon-function (grip) degradation from localized wounds ---
## Doc-10 Issue 2 (plan_balance_tuning.md): a whole-arm tissue/bone measure cannot see a *localized* hand/forearm
## wound. This folds sub-region + severity into a weapon-function mult stacked on top of the whole-arm measure.
## Only wounds with a sub_region contribute (legacy no-sub-region wounds are already captured by the whole-arm
## `get_arm_functionality`). Feature-gated: returns 1.0 when `FEATURE_ARM_WOUND_DEGRADATION` is off.


static func get_arm_wound_function_mult(entity: Node, part: String) -> float:
    if not is_arm(part) or entity == null or not CombatConstants.is_feature_arm_wound_degradation_enabled():
        return 1.0
    if not entity.get("wounds") is Dictionary or not entity.wounds.has(part):
        return 1.0
    var penalties: float = 0.0
    for injury in entity.wounds[part]:
        if not injury is Dictionary:
            continue
        var sub: String = str(injury.get("sub_region", ""))
        if sub.is_empty():
            continue
        var sub_weight: float = float(CombatConstants.ARM_WOUND_GRIP_SUB_REGION_WEIGHT.get(sub, 0.0))
        if sub_weight <= 0.0:
            continue
        var sev: String = str(injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE))
        var sev_weight: float = float(CombatConstants.ARM_WOUND_GRIP_SEVERITY_WEIGHT.get(sev, 0.0))
        penalties += sub_weight * sev_weight * CombatConstants.ARM_WOUND_GRIP_PENALTY_PER_UNIT
    return clampf(1.0 - penalties, CombatConstants.ARM_WOUND_GRIP_FLOOR, 1.0)


# --- Part-specific dodge modifier: attacked part's ability to get out of the way ---
# Legs/arms: move that limb. Head/chest: bone factor (injury = harder to duck/twist).


static func get_part_dodge_modifier(entity: Node, part: String) -> float:
    if is_leg(part):
        var leg_func: float = get_leg_functionality(entity)
        return clampf(leg_func, 0.2, 1.0)
    if is_arm(part):
        var arm_func: float = get_arm_functionality(entity, part)
        return clampf(arm_func, 0.2, 1.0)
    if is_vital_region(part):
        if not is_part_physically_operable(entity, part):
            return 0.2
        var bone: float = get_bone_functionality_factor(entity, part)
        return clampf(bone, 0.2, 1.0)
    return 1.0


# --- Leg functionality: min of both legs (both needed for gait); geometric mean when both damaged ---

## Torso (core) bracing functionality: structural integrity of the chest — the rib cage, sternum and
## core musculature a fighter braces into when parrying. 1.0 when the core is intact; drops toward 0.0
## as ribs/core are damaged. Combines the chest part's bone health (ribs/sternum) with its soft-tissue
## (cutting + blunt) remaining. Distinct from `get_leg_functionality` (base) and `get_arm_functionality`
## (weapon handling): this is the *center* of the brace. A species whose chest has no bone pool
## contributes no bone term, so a healthy chest still reads 1.0. D001-neutral at a healthy chest.


static func get_torso_core_functionality(entity: Node) -> float:
    var part = BodyPartConstants.PART_CHEST
    if not part in entity.body_cutting:
        return 1.0
    var max_per_type: int = entity.body_max.get(part, 0)
    var tissue: float = 1.0
    if max_per_type > 0:
        var combined_max: float = float(max_per_type * 2)
        var remaining: float = entity.body_cutting.get(part, 0.0) + entity.body_blunt.get(part, 0.0)
        tissue = clampf(remaining / combined_max, 0.0, 1.0)
    var bone: float = 1.0
    var bmx: int = 0
    if entity.get("bone_max") != null:
        bmx = entity.bone_max.get(part, 0)
    if bmx > 0:
        bone = get_bone_functionality_factor(entity, part)
    return clampf(sqrt(bone * tissue), 0.0, 1.0)


static func get_leg_functionality(entity: Node) -> float:
    var left_op = is_part_physically_operable(entity, BodyPartConstants.PART_LEFT_LEG)
    var right_op = is_part_physically_operable(entity, BodyPartConstants.PART_RIGHT_LEG)

    # Both legs destroyed — total immobilization (wheeled crawl only).
    if not left_op and not right_op:
        return 0.08

    # One leg destroyed — significant mobility loss but can still hobble/shuffle (~40-55%).
    # Historical evidence shows fighters with one damaged leg continue fighting at reduced capacity.
    if not left_op or not right_op:
        var surviving = BodyPartConstants.PART_LEFT_LEG if left_op else BodyPartConstants.PART_RIGHT_LEG
        var bone_factor = get_bone_functionality_factor(entity, surviving)
        return clampf(0.35 + bone_factor * 0.20, 0.35, 0.55)

    # Both legs functional — geometric mean of bone factors when both damaged.
    # A fractured (bone-depleted) but tissue-intact leg still bears partial weight, so floor each leg's
    # bone factor at LIMB_BONE_FUNCTIONAL_RATIO. Without this, a single fractured leg collapses the
    # geometric mean to 0.0 (total immobilization) — worse than a destroyed leg (0.55), which is backwards.
    var left: float = maxf(
        get_bone_functionality_factor(entity, BodyPartConstants.PART_LEFT_LEG), LIMB_BONE_FUNCTIONAL_RATIO
    )
    var right: float = maxf(
        get_bone_functionality_factor(entity, BodyPartConstants.PART_RIGHT_LEG), LIMB_BONE_FUNCTIONAL_RATIO
    )
    return sqrt(left * right)


## Single-leg drive functionality: how well one specific leg can bear weight and step into a blow.
## A destroyed leg cannot drive at all; an operable leg reports its bone factor floored at the limb
## ratio (a fractured-but-standing leg still bears partial weight, same floor as the symmetric blend).
## D001-neutral: a healthy leg is operable with a full bone factor -> 1.0.


static func get_leg_functionality_for(entity: Node, part: String) -> float:
    if not is_part_physically_operable(entity, part):
        return 0.08
    return maxf(get_bone_functionality_factor(entity, part), LIMB_BONE_FUNCTIONAL_RATIO)
