class_name BodyPartQuery
extends RefCounted

## Body part lists, targeting, and part-state queries (operable vs severed/crushed/destroyed, arm/leg functionality).
## Targeting uses is_part_physically_operable: cut, blunt, and bone (if bone_max > 0) must all be > 0.
## Entity must have: species (with BODY_PARTS, VITAL_PARTS), body_cutting, body_blunt, bone_health, body_max, bone_max.
## Optional for get_attacking_arm: dominant_hand, offhand_functionality (caller can implement on entity using these helpers).
## Canonical membership helpers: `is_arm()`, `is_leg()`, `is_vital()`, `is_limb()`  -  replace all hardcoded string comparisons.

const _Bp := preload("res://core/BodyPartConstants.gd")

# --- Part lists (from species or default) ---

const _LimbParts := [_Bp.PART_RIGHT_ARM, _Bp.PART_LEFT_ARM, _Bp.PART_RIGHT_LEG, _Bp.PART_LEFT_LEG]
const _ArmParts := [_Bp.PART_RIGHT_ARM, _Bp.PART_LEFT_ARM]
const _LegParts := [_Bp.PART_RIGHT_LEG, _Bp.PART_LEFT_LEG]
const _HeadChestParts := [_Bp.PART_HEAD, _Bp.PART_CHEST]

## Check if a body part name is an arm (canonical  -  replaces hardcoded string comparisons).
static func is_arm(part: String) -> bool:
	return part in _ArmParts

## Check if a body part name is a leg (canonical).
static func is_leg(part: String) -> bool:
	return part in _LegParts

## Check if a body part name is a limb (arm or leg, canonical  -  replaces LIMB_PARTS checks).
static func is_limb(part: String) -> bool:
	return part in _LimbParts

## Check if a body part name is head or chest (vital regions, canonical).
static func is_vital_region(part: String) -> bool:
	return part in _HeadChestParts

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
## If cutting OR blunt OR bone (when this part has bone_max > 0) reaches zero, the part is inoperable and excluded from targeting.
static func is_part_physically_operable(entity: Node, part: String) -> bool:
	if not part in entity.body_cutting or not part in entity.body_blunt:
		return false
	if entity.body_cutting.get(part, 0.0) <= 0.0:
		return false
	if entity.body_blunt.get(part, 0.0) <= 0.0:
		return false
	if entity.get("bone_health") != null and entity.get("bone_max") != null:
		var bmx: int = entity.bone_max.get(part, 0)
		if bmx > 0 and entity.bone_health.get(part, 0.0) <= 0.0:
			return false
	return true

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
	return not is_part_physically_operable(entity, part)

static func get_arm_functionality(entity: Node, part: String) -> float:
	if not is_arm(part):
		return 0.0
	if not is_part_physically_operable(entity, part):
		return 0.0
	var tissue: float = get_arm_tissue_factor(entity, part)
	var bone_factor: float = get_bone_functionality_factor(entity, part)
	return clampf(tissue * bone_factor, 0.0, 1.0)

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

static func get_leg_functionality(entity: Node) -> float:
	if not is_part_physically_operable(entity, _Bp.PART_LEFT_LEG) or not is_part_physically_operable(entity, _Bp.PART_RIGHT_LEG):
		return 0.08
	var left: float = get_bone_functionality_factor(entity, _Bp.PART_LEFT_LEG)
	var right: float = get_bone_functionality_factor(entity, _Bp.PART_RIGHT_LEG)
	if left <= 0.0 or right <= 0.0:
		return 0.08
	return sqrt(left * right)
