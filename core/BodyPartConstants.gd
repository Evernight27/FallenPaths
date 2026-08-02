class_name BodyPartConstants
extends RefCounted

## Body part lists, bone damage thresholds, targeting weights (single source of truth).

# --- Body part lists (single source of truth) ---
# Used by SpeciesResource, BodyPartQuery, BattleScene, PartyMenu, PartyManager.
const PART_HEAD: String = "head"
const PART_CHEST: String = "chest"
const PART_RIGHT_ARM: String = "right_arm"
const PART_LEFT_ARM: String = "left_arm"
const PART_RIGHT_LEG: String = "right_leg"
const PART_LEFT_LEG: String = "left_leg"

const BODY_PARTS := ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]
const VITAL_PARTS := ["head", "chest"]
const BODY_LABELS := {
    "head": "Head",
    "chest": "Chest",
    "right_arm": "R.Arm",
    "left_arm": "L.Arm",
    "left_leg": "L.Leg",
    "right_leg": "R.Leg"
}
# Two-column layout for battle UI body bars: left [head, right_arm, left_leg], right [chest, left_arm, right_leg]
const BODY_BAR_COLUMNS := [["head", "right_arm", "left_leg"], ["chest", "left_arm", "right_leg"]]

# --- Per-body-part and per-sub-region bone damage (tissue vs bone split) ---
# Research: skull fracture 4 - 23 J, femoral ~35 J, tibial ~25 J (PubMed 20803457; SciDirect long bone).
# Sub-regions: scalp thin over skull; face facial bones; neck less bone; thoracic ribs; abdominal soft;
# humerus shaft/deep brachial; elbow; forearm radius/ulna (distal most common); hand; thigh femur; knee; calf tibia;
# foot.
# See RESEARCH_BASED_APPROXIMATIONS.md, BleedingConstants.SUB_REGIONS.
const BONE_DAMAGE_MIN: int = 1

const _PART_BONE_THRESHOLD: Dictionary = {
    "head": 6, "chest": 10, "right_arm": 5, "left_arm": 5, "right_leg": 7, "left_leg": 7
}

const _PART_BONE_FRACTION: Dictionary = {
    "head": 0.45, "chest": 0.32, "right_arm": 0.38, "left_arm": 0.38, "right_leg": 0.42, "left_leg": 0.42
}

# Per-sub-region bone threshold (damage above this can go to bone). Lower = bone involved earlier.
const _SUB_REGION_BONE_THRESHOLD: Dictionary = {
    "head": {"scalp": 4, "face": 5, "neck": 7},
    "chest": {"thoracic": 8, "abdominal": 12},
    "right_arm": {"upper_arm": 4, "elbow": 3, "forearm": 5, "hand": 4},
    "left_arm": {"upper_arm": 4, "elbow": 3, "forearm": 5, "hand": 4},
    "right_leg": {"thigh": 6, "knee": 5, "calf": 7, "foot": 6},
    "left_leg": {"thigh": 6, "knee": 5, "calf": 7, "foot": 6}
}

# Per-sub-region fraction of damage (above threshold) that goes to bone vs tissue.
const _SUB_REGION_BONE_FRACTION: Dictionary = {
    "head": {"scalp": 0.42, "face": 0.55, "neck": 0.30},
    "chest": {"thoracic": 0.32, "abdominal": 0.20},
    "right_arm": {"upper_arm": 0.40, "elbow": 0.45, "forearm": 0.35, "hand": 0.30},
    "left_arm": {"upper_arm": 0.40, "elbow": 0.45, "forearm": 0.35, "hand": 0.30},
    "right_leg": {"thigh": 0.44, "knee": 0.40, "calf": 0.42, "foot": 0.35},
    "left_leg": {"thigh": 0.44, "knee": 0.40, "calf": 0.42, "foot": 0.35}
}

# --- Targeting (weapon hit probability by body part) ---
# Relative chance to be hit: based on body surface area and exposure (NCBI NBK224908: head/neck 12%,
# thorax 16%, abdomen 11%, extremities 61%).
# Chest = thoracic + abdominal; arms/legs split from extremities. Used for weighted random when selecting hit part.
# head/neck ~12% surface (often defended); thorax+abdomen ~27%; each arm ~10%; each leg ~20%.
const BODY_PART_TARGET_WEIGHTS: Dictionary = {
    "head": 1.2,
    "chest": 2.7,
    "right_arm": 1.0,
    "left_arm": 1.0,
    "right_leg": 2.0,
    "left_leg": 2.0,
}

# Per-weapon limb targeting bias (multiplies BODY_PART_TARGET_WEIGHTS). Empty = neutral sword baseline.
const WEAPON_PART_TARGET_MULT: Dictionary = {
    "SWORD": {},
    "AXE":
    {
        "head": 1.22,
        "chest": 0.95,
        "left_arm": 1.12,
        "right_arm": 1.12,
    },
    "MACE":
    {
        "head": 1.32,
        "chest": 1.10,
        "left_arm": 0.90,
        "right_arm": 0.90,
        "left_leg": 0.88,
        "right_leg": 0.88,
    },
    "DAGGER":
    {
        "chest": 1.22,
        "head": 1.08,
        "left_arm": 0.95,
        "right_arm": 0.95,
    },
    "SPEAR":
    {
        "chest": 1.25,
        "head": 0.92,
        "left_leg": 1.10,
        "right_leg": 1.10,
    },
}

# Contact-type refinement per weapon (multiplies weapon base row).
const WEAPON_CONTACT_PART_MULT: Dictionary = {
    "SWORD":
    {
        "stab": {"chest": 1.10, "head": 1.05},
        "cut": {"head": 1.08, "left_arm": 1.05, "right_arm": 1.05},
    },
    "AXE":
    {
        "cut": {"head": 1.10, "left_arm": 1.08, "right_arm": 1.08},
        "stab": {"chest": 1.12},
        "blunt": {"head": 1.15},
    },
    "MACE":
    {
        "blunt": {"head": 1.14, "chest": 1.08},
    },
    "DAGGER":
    {
        "stab": {"chest": 1.18, "head": 1.10},
        "cut": {"left_arm": 1.08, "right_arm": 1.08},
    },
    "SPEAR":
    {
        "stab": {"chest": 1.15, "left_leg": 1.08, "right_leg": 1.08},
    },
}


static func get_bone_damage_threshold(part: String, sub_region: String = "") -> int:
    if not sub_region.is_empty() and _SUB_REGION_BONE_THRESHOLD.get(part, {}).has(sub_region):
        return _SUB_REGION_BONE_THRESHOLD[part][sub_region]
    return _PART_BONE_THRESHOLD.get(part, 5)


static func get_bone_damage_fraction(part: String, sub_region: String = "") -> float:
    if not sub_region.is_empty() and _SUB_REGION_BONE_FRACTION.get(part, {}).has(sub_region):
        return _SUB_REGION_BONE_FRACTION[part][sub_region]
    return _PART_BONE_FRACTION.get(part, 0.35)


static func get_bone_damage_min(_part: String) -> int:
    return BONE_DAMAGE_MIN


static func weapon_part_target_mult(weapon_id: String, part: String, contact_type: String = "") -> float:
    var wid: String = str(weapon_id).to_upper().strip_edges()
    var w: float = 1.0
    if WEAPON_PART_TARGET_MULT.has(wid):
        var row: Variant = WEAPON_PART_TARGET_MULT[wid]
        if row is Dictionary:
            w = float((row as Dictionary).get(part, 1.0))
    if not contact_type.is_empty() and WEAPON_CONTACT_PART_MULT.has(wid):
        var ct_row: Variant = WEAPON_CONTACT_PART_MULT[wid]
        if ct_row is Dictionary and (ct_row as Dictionary).has(contact_type):
            var part_row: Variant = (ct_row as Dictionary)[contact_type]
            if part_row is Dictionary:
                w *= float((part_row as Dictionary).get(part, 1.0))
    return w


# Pick one body part from targetable_parts with optional preferred_parts bonus.
# preferred_parts: Array of part names that get bonus weight (e.g. move's cut geometry).
# preferred_mult: weight multiplier for parts in preferred_parts (1.0 = no bonus).
# Returns "" if targetable_parts is empty. Parts not in weights get weight 1.0.
static func get_weighted_random_part(
    targetable_parts: Array, preferred_parts: Array = [], preferred_mult: float = 1.0
) -> String:
    if targetable_parts.is_empty():
        return ""
    var total: float = 0.0
    for part in targetable_parts:
        var w: float = BODY_PART_TARGET_WEIGHTS.get(part, 1.0)
        if preferred_parts.has(part) and preferred_mult > 1.0:
            w *= preferred_mult
        total += w
    if total <= 0.0:
        return targetable_parts[randi() % targetable_parts.size()]
    var r: float = randf() * total
    var acc: float = 0.0
    for part in targetable_parts:
        var w: float = BODY_PART_TARGET_WEIGHTS.get(part, 1.0)
        if preferred_parts.has(part) and preferred_mult > 1.0:
            w *= preferred_mult
        acc += w
        if r < acc:
            return part
    return targetable_parts[targetable_parts.size() - 1]

# --- Severance / destruction ---
# Severance (sharp): body_cutting <= 0 AND bone_health <= 0 (part cut through).
# Crushed (blunt): body_blunt <= 0 AND bone_health <= 0 (part destroyed).
# Part is targetable until severed or crushed: (cutting > 0 or bone > 0) and (blunt > 0 or bone > 0).
