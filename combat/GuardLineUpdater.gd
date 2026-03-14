class_name GuardLineUpdater
extends RefCounted

## Updates combatant guard_line based on weapon use. Physics: blade ends where action ends.
## Outcome-dependent: parried blade ends deflected; hit blade ends in attack line; etc.
## Call whenever a weapon is used (attack completes, parry deflects, parry partial, etc).

const _CombatDebug := preload("res://combat/CombatDebug.gd")

## Sets combatant guard_line to deflected position (blade was knocked aside by parry).
## Angle-based: bilateral deflection — blade deflects "away from" defender's blade.
## Bind: parry_control high → blade stays; else magnitude from alignment/severity.
## effective_line_override: use when available (e.g. diagonal roll); else from move.
## defender_guard_line: defender's guard at parry.
## clash_context: optional {parry_control, severity, attack_type, defender_guard_line, alignment, attack_angle_deg} for HEMA bind/deflect.
static func set_guard_deflected(c: Dictionary, move_id: String, effective_line_override: String = "", defender_guard_line: String = "", clash_context: Dictionary = {}) -> void:
	var atk_line: String = effective_line_override
	if atk_line.is_empty() and not move_id.is_empty():
		var move_def: Dictionary = WeaponConstants.get_move(move_id)
		if not move_def.is_empty():
			atk_line = move_def.get("attack_line", "")
	if atk_line.is_empty():
		return
	var def_guard: String = clash_context.get("defender_guard_line", defender_guard_line)
	if def_guard.is_empty():
		def_guard = defender_guard_line
	var parry_control: float = clash_context.get("parry_control", 1.0)
	var arch_id: String = clash_context.get("archetype_id", "")
	var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
	var severity: float = clash_context.get("severity", 1.0)
	var attack_type: String = clash_context.get("attack_type", "cut")
	var line: String
	var blend: float = 0.0
	if not clash_context.is_empty() and can_bind and parry_control >= CombatConstants.PARRY_BIND_CONTROL_THRESHOLD:
		line = atk_line
		blend = 0.0
	elif not def_guard.is_empty() and not clash_context.is_empty():
		var atk_angle: float = clash_context.get("attack_angle_deg", CombatConstants.line_to_angle(atk_line))
		var guard_angle: float = clash_context.get("guard_angle_deg", CombatConstants.line_to_angle(def_guard))
		var alignment: float = clash_context.get("alignment", CombatConstants.get_line_alignment(atk_line, def_guard))
		line = CombatConstants.get_deflected_line_from_angles(atk_angle, guard_angle, severity, attack_type, alignment)
		blend = severity
	elif not defender_guard_line.is_empty():
		var atk_angle: float = CombatConstants.line_to_angle(atk_line)
		var guard_angle: float = CombatConstants.line_to_angle(defender_guard_line)
		var alignment: float = CombatConstants.get_line_alignment(atk_line, defender_guard_line)
		line = CombatConstants.get_deflected_line_from_angles(atk_angle, guard_angle, 1.0, "cut", alignment)
		blend = 1.0 if line != atk_line else 0.0
	else:
		line = CombatConstants.DEFLECTED_GUARD_FROM_ATTACK.get(atk_line, atk_line)
		blend = 1.0
	var prev: String = c.get("guard_line", "high")
	c["guard_line"] = line
	c["guard_deflect_blend"] = blend
	c["guard_deflect_from_line"] = atk_line
	_sync_guard_zone_from_line(c, line)
	if CombatConstants.COMBAT_DEBUG:
		var name_s: String = c.node.name if c.get("node") != null else "id:%d" % c.get("id", -1)
		var kind: String = "bind" if line == atk_line else "deflect"
		var angle_info: String = ""
		if not clash_context.is_empty() and clash_context.get("attack_angle_deg", null) is float:
			var atk_a: float = float(clash_context["attack_angle_deg"])
			var guard_a: float = clash_context.get("guard_angle_deg", CombatConstants.line_to_angle(def_guard))
			angle_info = " [atk=%.0f° guard=%.0f°]" % [atk_a, guard_a]
		_CombatDebug.log("guard_line %s: %s -> %s (%s from %s def_guard=%s blend=%.2f)%s" % [name_s, prev, line, kind, atk_line, def_guard, blend, angle_info])

## Sets combatant guard_line from move_id. Uses attack_line from move definition.
## effective_line_override: use when available (e.g. diagonal roll); else from move.
static func set_guard_from_move(c: Dictionary, move_id: String, effective_line_override: String = "") -> void:
	var line: String = effective_line_override
	if line.is_empty() and not move_id.is_empty():
		var move_def: Dictionary = WeaponConstants.get_move(move_id)
		if not move_def.is_empty():
			line = move_def.get("attack_line", "")
	if not line.is_empty():
		var prev: String = c.get("guard_line", "high")
		c["guard_line"] = line
		c.erase("guard_deflect_blend")
		c.erase("guard_deflect_from_line")
		_sync_guard_zone_from_line(c, line)
		if CombatConstants.COMBAT_DEBUG:
			var name_s: String = c.node.name if c.get("node") != null else "id:%d" % c.get("id", -1)
			_CombatDebug.log("guard_line %s: %s -> %s (move=%s)" % [name_s, prev, line, move_id])

## Sets combatant guard_line directly from line (e.g. when we have effective_attack_line from diagonal roll).
static func set_guard_from_line(c: Dictionary, line: String) -> void:
	if line.is_empty():
		return
	var prev: String = c.get("guard_line", "high")
	c["guard_line"] = line
	c.erase("guard_deflect_blend")
	c.erase("guard_deflect_from_line")
	_sync_guard_zone_from_line(c, line)
	if CombatConstants.COMBAT_DEBUG:
		var name_s: String = c.node.name if c.get("node") != null else "id:%d" % c.get("id", -1)
		_CombatDebug.log("guard_line %s: %s -> %s (from_line)" % [name_s, prev, line])

## Keeps guard_zone consistent with guard_line when blade position changes from outcome.
static func _sync_guard_zone_from_line(c: Dictionary, line: String) -> void:
	var part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(line, "")
	if not part.is_empty():
		c["guard_zone"] = part
