class_name CombatFootwork
extends RefCounted

## Tier 4.4 pilot: abstract step-on-attack shifts **`attack_angle_deg`** via per-combatant offset (no world positions).
## Tier 4.4.2: symmetric defender step on committed parry (guard line) or dodge (eval part line).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_position_angle_footwork_enabled()


static func apply_attack_step_on_windup(attacker: Dictionary, attack_line: String) -> void:
	if not enabled() or attacker == null:
		return
	var line: String = str(attack_line).strip_edges()
	if line.is_empty():
		clear_position_offset(attacker)
		return
	attacker[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = (
		CombatConstants.position_angle_offset_deg_for_attack_line(line)
	)
	refresh_ui_hint(attacker)


static func apply_defender_step_on_parry(defender: Dictionary, guard_line: String) -> void:
	if not enabled() or defender == null:
		return
	var line: String = str(guard_line).strip_edges()
	if line.is_empty():
		line = CombatConstants.GUARD_DEFAULT
	defender[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = (
		CombatConstants.position_angle_defender_offset_deg_for_line(
			line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
		)
	)
	refresh_ui_hint(defender)


static func apply_defender_step_on_dodge(defender: Dictionary, dodge_eval_part: String) -> void:
	if not enabled() or defender == null:
		return
	var line: String = CombatConstants.guard_line_for_body_part(dodge_eval_part)
	defender[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = (
		CombatConstants.position_angle_defender_offset_deg_for_line(
			line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
		)
	)
	refresh_ui_hint(defender)


static func format_position_angle_ui_hint(c: Dictionary) -> String:
	if not enabled() or c == null:
		return ""
	var off: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(off) < 0.01:
		return ""
	var sign_prefix: String = "+" if off >= 0.0 else ""
	return "Step %s%.0f°" % [sign_prefix, off]


## Player-visible label: stamped key when present, else derive from offset (snapshot-safe).
static func get_ui_hint(c: Dictionary) -> String:
	if not enabled() or c == null:
		return ""
	var stamped: String = str(
		c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT, "")
	).strip_edges()
	if not stamped.is_empty():
		return stamped
	return format_position_angle_ui_hint(c)


static func refresh_ui_hint(c: Dictionary) -> void:
	if c == null:
		return
	var hint: String = format_position_angle_ui_hint(c)
	if hint.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = hint


static func get_attacker_offset_deg(attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return 0.0
	return float(attacker.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))


static func get_defender_offset_deg(defender: Dictionary) -> float:
	return get_attacker_offset_deg(defender)


static func apply_offset_to_angle_deg(base_deg: float, attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return base_deg
	return fmod(base_deg + get_attacker_offset_deg(attacker) + 360.0, 360.0)


static func apply_defender_offset_to_guard_deg(base_guard_deg: float, defender: Dictionary) -> float:
	if not enabled() or defender == null:
		return base_guard_deg
	return fmod(base_guard_deg + get_defender_offset_deg(defender) + 360.0, 360.0)


static func guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
	var base: float = CombatConstants.get_guard_angle_deg(combatant, wobble_context)
	return apply_defender_offset_to_guard_deg(base, combatant)


## Parry alignment during **`choose_defense`** without stamping offset until defense commits.
static func guard_angle_deg_with_step_deg(
	combatant: Dictionary, wobble_context: Dictionary, step_deg: float
) -> float:
	var base: float = CombatConstants.get_guard_angle_deg(combatant, wobble_context)
	if not enabled() or absf(step_deg) < 0.01:
		return base
	return fmod(base + step_deg + 360.0, 360.0)


static func parry_eval_step_deg_for_defender(defender: Dictionary) -> float:
	if not enabled() or defender == null:
		return 0.0
	var line: String = str(defender.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()
	if line.is_empty():
		line = CombatConstants.GUARD_DEFAULT
	return CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)


static func clear_position_offset(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
	refresh_ui_hint(c)
