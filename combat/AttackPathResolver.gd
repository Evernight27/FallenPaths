class_name AttackPathResolver
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _WeightedSample := preload("res://core/WeightedSample.gd")

## Option 6: Path + Guard Intercept  -  hit part selection from blade trajectory.
## Footing: optional **`alignment_context`** **`attack_angle_deg`** / **`guard_angle_deg`**  -  use **`CombatFootwork.guard_angle_deg`** at contact, not raw **`guard_line`** alone when PA flag on. LIVE_PATHS **`#wf-tier-44-pa`** (geometry).
## Path varies by (attack_line, guard_line): defender posture determines what's in the blade's way.
## High guard vs high attack = arms first; low guard vs high attack = head exposed first.
## Intercept: high alignment = early contact; low = blade travels further.

## Returns hit part from path + intercept. Falls back to weighted random if path yields nothing.
## defender_ctx: optional { state, recovery_cause, passive_parry_attempted } for reaction-state modifiers.
## defender: optional combatant dict for deflect-aware alignment (guard_deflect_blend).
## intended_part: optional; when in path segment, boosts weight (attacker aimed here).
## alignment_context: optional { attack_angle_deg, guard_angle_deg } for angle-based alignment.
static func resolve_hit_part(attack_line: String, guard_line: String, targetable: Array, defender_ctx: Dictionary = {}, intended_part: String = "", defender: Dictionary = {}, alignment_context: Dictionary = {}) -> String:
	if targetable.is_empty():
		return ""
	var atk_line_path: String = attack_line
	var guard_line_path: String = guard_line
	if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
		atk_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["attack_angle_deg"]))
		guard_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["guard_angle_deg"]))
	var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	if path.is_empty():
		return BodyPartConstants.get_weighted_random_part(targetable)
	var def_for_align: Dictionary = defender if not defender.is_empty() else {"guard_line": guard_line}
	var alignment: float = CombatConstants.get_line_alignment_with_deflect(attack_line, def_for_align, alignment_context)
	var intercept_max: int = intercept_max_index_for_alignment(path, alignment)
	var path_segment: Array = []
	for i in range(intercept_max + 1):
		if i < path.size():
			var p: String = path[i]
			if targetable.has(p):
				path_segment.append(p)
	if path_segment.is_empty():
		return BodyPartConstants.get_weighted_random_part(targetable)
	# Reaction state: RECOVERING + attack_hit = staggered, bias center mass. Parry attempted + hit = limbs in way.
	var part_weights: Dictionary = {}
	for p in path_segment:
		part_weights[p] = 1.0
	var recovery_cause: String = CombatConstants.normalize_recovery_cause(
		defender_ctx.get("recovery_cause", "")
	)
	var passive_parry: bool = defender_ctx.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
	if recovery_cause == "attack_hit" and _EntityAccess.state_str(defender_ctx) == CombatConstants.STATE_RECOVERING:
		# Staggered: center mass (chest) more likely
		if part_weights.has(BodyPartConstants.PART_CHEST):
			part_weights[BodyPartConstants.PART_CHEST] = 1.5
	if passive_parry:
		# Blade met blade; if hit, limbs (arms) more likely in the way
		for limb in [BodyPartConstants.PART_LEFT_ARM, BodyPartConstants.PART_RIGHT_ARM]:
			if part_weights.has(limb):
				part_weights[limb] = 1.4
	var interpose: Dictionary = _GuardLines.arm_interpose_eval(attack_line, guard_line, alignment, targetable)
	if interpose.get("active", false):
		var interpose_arm: String = interpose.get("arm", "")
		if path_segment.has(interpose_arm):
			part_weights[interpose_arm] = (
				part_weights.get(interpose_arm, 1.0) * CombatConstants.ARM_INTERPOSE_HIT_WEIGHT_MULT
			)
	# Intended target: boost weight when in path (attacker aimed here; pathway allows it)
	if not intended_part.is_empty() and path_segment.has(intended_part):
		part_weights[intended_part] = part_weights.get(intended_part, 1.0) * 2.0
	var part: String = BodyPartConstants.get_weighted_random_part(path_segment) if part_weights.values().min() == part_weights.values().max() else _WeightedSample.pick_random(part_weights)
	if part.is_empty():
		part = BodyPartConstants.get_weighted_random_part(path_segment)
	if CombatConstants.combat_debug_active():
		var angle_info: String = ""
		if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
			angle_info = " (atk=%.0f° guard=%.0f°)" % [float(alignment_context["attack_angle_deg"]), float(alignment_context["guard_angle_deg"])]
		CombatDebug.log("path atk=%s guard=%s%s align=%.2f intercept_max=%d segment=%s => %s" % [atk_line_path, guard_line_path, angle_info, alignment, intercept_max, str(path_segment), part])
	return part


## Path intercept depth from alignment (0 = early parts on path, path.size()-1 = full depth).
static func intercept_max_index_for_alignment(path: Array, alignment: float) -> int:
	if path.is_empty():
		return 0
	var intercept_max: int = int(
		lerpf(
			float(CombatConstants.PATH_INTERCEPT_EARLY_MAX),
			float(path.size() - 1),
			1.0 - alignment
		)
	)
	return clampi(intercept_max, 0, path.size() - 1)


static func path_intercept_max_index(
	attack_line: String,
	guard_line: String,
	alignment: float,
	alignment_context: Dictionary = {}
) -> int:
	var atk_line_path: String = attack_line
	var guard_line_path: String = guard_line
	if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
		atk_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["attack_angle_deg"]))
		guard_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["guard_angle_deg"]))
	var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	return intercept_max_index_for_alignment(path, alignment)



