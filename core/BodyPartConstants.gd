class_name BodyPartConstants
extends RefCounted

# --- Body part lists (single source of truth) ---
# Used by SpeciesResource, BodyPartQuery, BattleScene, PartyMenu, PartyManager.
const BODY_PARTS := ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]
const BODY_LABELS := {"head": "Head", "chest": "Chest", "right_arm": "R.Arm", "left_arm": "L.Arm", "left_leg": "L.Leg", "right_leg": "R.Leg"}
# Two-column layout for battle UI body bars: left [head, right_arm, left_leg], right [chest, left_arm, right_leg]
const BODY_BAR_COLUMNS := [["head", "right_arm", "left_leg"], ["chest", "left_arm", "right_leg"]]

# --- Per-body-part and per-sub-region bone damage (tissue vs bone split) ---
# Research: skull fracture 4–23 J, femoral ~35 J, tibial ~25 J (PubMed 20803457; SciDirect long bone).
# Sub-regions: scalp thin over skull; face facial bones; neck less bone; thoracic ribs; abdominal soft;
# humerus shaft/deep brachial; elbow; forearm radius/ulna (distal most common); hand; thigh femur; knee; calf tibia; foot.
# See RESEARCH_BASED_APPROXIMATIONS.md, BleedingConstants.SUB_REGIONS.
const BONE_DAMAGE_MIN: int = 1

const _PART_BONE_THRESHOLD: Dictionary = {
	"head": 3,
	"chest": 8,
	"right_arm": 5,
	"left_arm": 5,
	"right_leg": 6,
	"left_leg": 6
}

const _PART_BONE_FRACTION: Dictionary = {
	"head": 0.55,
	"chest": 0.30,
	"right_arm": 0.38,
	"left_arm": 0.38,
	"right_leg": 0.42,
	"left_leg": 0.42
}

# Per-sub-region bone threshold (damage above this can go to bone). Lower = bone involved earlier.
const _SUB_REGION_BONE_THRESHOLD: Dictionary = {
	"head": {"scalp": 2, "face": 3, "neck": 6},
	"chest": {"thoracic": 6, "abdominal": 10},
	"right_arm": {"upper_arm": 4, "elbow": 3, "forearm": 5, "hand": 4},
	"left_arm": {"upper_arm": 4, "elbow": 3, "forearm": 5, "hand": 4},
	"right_leg": {"thigh": 5, "knee": 4, "calf": 6, "foot": 5},
	"left_leg": {"thigh": 5, "knee": 4, "calf": 6, "foot": 5}
}

# Per-sub-region fraction of damage (above threshold) that goes to bone vs tissue.
const _SUB_REGION_BONE_FRACTION: Dictionary = {
	"head": {"scalp": 0.50, "face": 0.60, "neck": 0.35},
	"chest": {"thoracic": 0.35, "abdominal": 0.22},
	"right_arm": {"upper_arm": 0.40, "elbow": 0.45, "forearm": 0.35, "hand": 0.30},
	"left_arm": {"upper_arm": 0.40, "elbow": 0.45, "forearm": 0.35, "hand": 0.30},
	"right_leg": {"thigh": 0.45, "knee": 0.40, "calf": 0.42, "foot": 0.35},
	"left_leg": {"thigh": 0.45, "knee": 0.40, "calf": 0.42, "foot": 0.35}
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

# --- Targeting (weapon hit probability by body part) ---
# Relative chance to be hit: based on body surface area and exposure (NCBI NBK224908: head/neck 12%, thorax 16%, abdomen 11%, extremities 61%).
# Chest = thoracic + abdominal; arms/legs split from extremities. Used for weighted random when selecting hit part.
const BODY_PART_TARGET_WEIGHTS: Dictionary = {
	"head": 1.2,      # head/neck ~12% surface area; often defended
	"chest": 2.7,     # thorax + abdomen ~27%; center mass
	"right_arm": 1.0,
	"left_arm": 1.0,  # each arm ~10% of extremities
	"right_leg": 2.0,
	"left_leg": 2.0   # each leg ~20%; large, stable target
}

# Pick one body part from targetable_parts with optional preferred_parts bonus.
# preferred_parts: Array of part names that get bonus weight (e.g. move's cut geometry).
# preferred_mult: weight multiplier for parts in preferred_parts (1.0 = no bonus).
# Returns "" if targetable_parts is empty. Parts not in weights get weight 1.0.
static func get_weighted_random_part(targetable_parts: Array, preferred_parts: Array = [], preferred_mult: float = 1.0) -> String:
	if targetable_parts.is_empty():
		return ""
	var total: float = 0.0
	for part in targetable_parts:
		var w: float = float(BODY_PART_TARGET_WEIGHTS.get(part, 1.0))
		if preferred_parts.has(part) and preferred_mult > 1.0:
			w *= preferred_mult
		total += w
	if total <= 0.0:
		return targetable_parts[randi() % targetable_parts.size()]
	var r: float = randf() * total
	var acc: float = 0.0
	for part in targetable_parts:
		var w: float = float(BODY_PART_TARGET_WEIGHTS.get(part, 1.0))
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
