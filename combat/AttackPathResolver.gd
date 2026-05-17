class_name AttackPathResolver
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Option 6: Path + Guard Intercept — hit part selection from blade trajectory.
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
	# High alignment = guard in position = limbs in path = early intercept (small index)
	# Low alignment = wrong guard = blade travels further = late intercept (large index)
	var intercept_max: int = int(lerpf(
		float(CombatConstants.PATH_INTERCEPT_EARLY_MAX),
		float(path.size() - 1),
		1.0 - alignment
	))
	intercept_max = clampi(intercept_max, 0, path.size() - 1)
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
	var recovery_cause: String = defender_ctx.get("recovery_cause", "")
	var passive_parry: bool = defender_ctx.get("passive_parry_attempted", false)
	if recovery_cause == "attack_hit" and _EntityAccess.state_str(defender_ctx) == CombatConstants.STATE_RECOVERING:
		# Staggered: center mass (chest) more likely
		if part_weights.has("chest"):
			part_weights["chest"] = 1.5
	if passive_parry:
		# Blade met blade; if hit, limbs (arms) more likely in the way
		for limb in ["left_arm", "right_arm"]:
			if part_weights.has(limb):
				part_weights[limb] = 1.4
	# Intended target: boost weight when in path (attacker aimed here; pathway allows it)
	if not intended_part.is_empty() and path_segment.has(intended_part):
		part_weights[intended_part] = part_weights.get(intended_part, 1.0) * 2.0
	var part: String = BodyPartConstants.get_weighted_random_part(path_segment) if part_weights.values().min() == part_weights.values().max() else _weighted_sample(part_weights)
	if part.is_empty():
		part = BodyPartConstants.get_weighted_random_part(path_segment)
	if CombatConstants.combat_debug_active():
		var angle_info: String = ""
		if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
			angle_info = " (atk=%.0f° guard=%.0f°)" % [float(alignment_context["attack_angle_deg"]), float(alignment_context["guard_angle_deg"])]
		CombatDebug.log("path atk=%s guard=%s%s align=%.2f intercept_max=%d segment=%s => %s" % [atk_line_path, guard_line_path, angle_info, alignment, intercept_max, str(path_segment), part])
	return part

static func _weighted_sample(weights: Dictionary) -> String:
	var total: float = 0.0
	for w in weights.values():
		total += float(w)
	if total <= 0.0:
		return ""
	var r: float = randf() * total
	for p in weights:
		r -= float(weights[p])
		if r <= 0.0:
			return p
	return weights.keys()[0] if not weights.is_empty() else ""
