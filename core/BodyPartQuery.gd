class_name BodyPartQuery
extends RefCounted

## Body part lists, targeting, and part-state queries (severed/crushed/destroyed, arm/leg functionality).
## Entity must have: species (with BODY_PARTS, VITAL_PARTS), body_cutting, body_blunt, bone_health, body_max, bone_max.
## Optional for get_attacking_arm: dominant_hand, offhand_functionality (caller can implement on entity using these helpers).

# --- Part lists (from species or default) ---

static func get_body_part_list(entity: Node) -> Array:
	if entity.species != null and "BODY_PARTS" in entity.species:
		return entity.species.BODY_PARTS.duplicate()
	return ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]

static func get_vital_parts(entity: Node) -> Array:
	if entity.species != null and "VITAL_PARTS" in entity.species:
		return entity.species.VITAL_PARTS.duplicate()
	return ["head", "chest"]

# --- Part state: severed (cut+bone 0), crushed (blunt+bone 0), destroyed (either) ---

static func is_part_severed(entity: Node, part: String) -> bool:
	return entity.body_cutting.get(part, 0.0) <= 0.0 and entity.bone_health.get(part, 0.0) <= 0.0

static func is_part_crushed(entity: Node, part: String) -> bool:
	return entity.body_blunt.get(part, 0.0) <= 0.0 and entity.bone_health.get(part, 0.0) <= 0.0

static func is_part_destroyed(entity: Node, part: String) -> bool:
	return is_part_severed(entity, part) or is_part_crushed(entity, part)

# Part is targetable until severed or crushed (tissue can be 0 with bone > 0 = mangled, not targetable for new hits).
static func get_targetable_parts(entity: Node) -> Array:
	var out: Array = []
	for part in get_body_part_list(entity):
		if is_part_destroyed(entity, part):
			continue
		if entity.body_cutting.get(part, 0.0) > 0.0 or entity.body_blunt.get(part, 0.0) > 0.0:
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
	if part != "right_arm" and part != "left_arm":
		return 0.0
	var max_per_type: int = entity.body_max.get(part, 0)
	if max_per_type <= 0:
		return 0.0
	var combined_max: float = float(max_per_type * 2)
	var remaining: float = float(entity.body_cutting.get(part, 0.0) + entity.body_blunt.get(part, 0.0))
	return clampf(remaining / combined_max, 0.0, 1.0)

static func is_arm_destroyed(entity: Node, part: String) -> bool:
	if part != "right_arm" and part != "left_arm":
		return true
	if is_part_destroyed(entity, part):
		return true
	return entity.body_cutting.get(part, 0.0) <= 0.0 or entity.body_blunt.get(part, 0.0) <= 0.0

static func get_arm_functionality(entity: Node, part: String) -> float:
	if part != "right_arm" and part != "left_arm":
		return 0.0
	if is_part_destroyed(entity, part):
		return 0.0
	var tissue: float = get_arm_tissue_factor(entity, part)
	var bone_factor: float = get_bone_functionality_factor(entity, part)
	return clampf(tissue * bone_factor, 0.0, 1.0)

# --- Leg functionality: min of both legs (both needed for gait); geometric mean when both damaged ---

static func get_leg_functionality(entity: Node) -> float:
	var left: float = get_bone_functionality_factor(entity, "left_leg")
	var right: float = get_bone_functionality_factor(entity, "right_leg")
	if left <= 0.0 or right <= 0.0:
		return 0.08
	return sqrt(left * right)
