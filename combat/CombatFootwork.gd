class_name CombatFootwork
extends RefCounted

## Tier 4.4 pilot: abstract step-on-attack shifts **`attack_angle_deg`** via per-combatant offset (no world positions).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_position_angle_footwork_enabled()


static func apply_attack_step_on_windup(attacker: Dictionary, attack_line: String) -> void:
	if not enabled() or attacker == null:
		return
	var line: String = str(attack_line).strip_edges()
	if line.is_empty():
		attacker.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
		return
	attacker[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = (
		CombatConstants.position_angle_offset_deg_for_attack_line(line)
	)


static func get_attacker_offset_deg(attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return 0.0
	return float(attacker.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))


static func apply_offset_to_angle_deg(base_deg: float, attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return base_deg
	return fmod(base_deg + get_attacker_offset_deg(attacker) + 360.0, 360.0)


static func clear_position_offset(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
