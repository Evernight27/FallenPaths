class_name GuardLineUpdater
extends RefCounted

## Updates combatant guard_line based on weapon use. Physics: blade ends where action ends.
## Outcome-dependent: parried blade ends deflected; hit blade ends in attack line; etc.
## Call whenever a weapon is used (attack completes, parry deflects, parry partial, etc).

const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
## Sets combatant guard_line to deflected position (blade was knocked aside by parry).
## Angle-based: bilateral deflection — blade deflects "away from" defender's blade.
## Bind: parry_control high → blade stays; else magnitude from alignment/severity.
## effective_line_override: use when available (e.g. diagonal roll); else from move.
## defender_guard_line: defender's guard at parry.
## clash_context: optional {parry_control, severity (else derived from margin_ratio via `CombatConstants.parry_deflect_severity_from_margin_ratio`), attack_type (move_id), contact_type (stab|cut|blunt), defender_guard_line, alignment, attack_angle_deg, parry_time_to_react, parry_readiness, late_parry, parry_off_balance, margin_ratio, kinematic_delivery, strike_velocity_m_s, strike_kinetic_energy_j, strike_measure_ratio, …} for HEMA bind/deflect / calibration.
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
	var severity: float = 1.0
	if clash_context.has("severity"):
		severity = float(clash_context["severity"])
	elif clash_context.has("margin_ratio"):
		severity = CombatConstants.parry_deflect_severity_from_margin_ratio(float(clash_context["margin_ratio"]))
	# Prefer explicit contact_type from clash (e.g. parry_deflect); else derive from move_id in attack_type.
	var ct_ctx: String = str(clash_context.get("contact_type", "")).to_lower().strip_edges()
	var attack_move_id: String = str(clash_context.get("attack_type", "cut"))
	var deflect_contact: String = ct_ctx
	if ct_ctx != WeaponConstants.ATTACK_TYPE_STAB and ct_ctx != WeaponConstants.ATTACK_TYPE_CUT and ct_ctx != WeaponConstants.ATTACK_TYPE_BLUNT:
		deflect_contact = WeaponConstants.contact_type_for_move_id(attack_move_id)
	var line: String
	var blend: float = 0.0
	if not clash_context.is_empty() and can_bind and parry_control >= CombatConstants.PARRY_BIND_CONTROL_THRESHOLD:
		line = atk_line
		blend = 0.0
	elif not def_guard.is_empty() and not clash_context.is_empty():
		var atk_angle: float = clash_context.get("attack_angle_deg", CombatConstants.line_to_angle(atk_line))
		var guard_angle: float = clash_context.get("guard_angle_deg", CombatConstants.line_to_angle(def_guard))
		var alignment: float = clash_context.get("alignment", CombatConstants.get_line_alignment(atk_line, def_guard))
		line = CombatConstants.get_deflected_line_from_angles(atk_angle, guard_angle, severity, deflect_contact, alignment)
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
	var prev: String = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
	c["guard_line"] = line
	c["guard_deflect_blend"] = blend
	c["guard_deflect_from_line"] = atk_line
	_sync_guard_zone_from_line(c, line)
	if CombatConstants.COMBAT_DEBUG:
		var name_s: String = _EntityAccess.get_display_name(c)
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
		var prev: String = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
		c["guard_line"] = line
		c.erase("guard_deflect_blend")
		c.erase("guard_deflect_from_line")
		_sync_guard_zone_from_line(c, line, true)
		if CombatConstants.COMBAT_DEBUG:
			var name_s: String = _EntityAccess.get_display_name(c)
			_CombatDebug.log("guard_line %s: %s -> %s (move=%s)" % [name_s, prev, line, move_id])

## Sets combatant guard_line directly from line (e.g. when we have effective_attack_line from diagonal roll).
static func set_guard_from_line(c: Dictionary, line: String) -> void:
	if line.is_empty():
		return
	var prev: String = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
	c["guard_line"] = line
	c.erase("guard_deflect_blend")
	c.erase("guard_deflect_from_line")
	_sync_guard_zone_from_line(c, line, true)
	if CombatConstants.COMBAT_DEBUG:
		var name_s: String = _EntityAccess.get_display_name(c)
		_CombatDebug.log("guard_line %s: %s -> %s (from_line)" % [name_s, prev, line])

## Keeps guard_zone consistent with guard_line when blade position changes from outcome.
static func _sync_guard_zone_from_line(c: Dictionary, line: String, sync_focus: bool = false) -> void:
	var part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(line, "")
	if not part.is_empty():
		c["guard_zone"] = part
		if sync_focus and _Attention.enabled():
			_Attention.set_focus(c, part)
		elif str(c.get(CombatConstants.COMBATANT_KEY_FOCUS_PART, "")).is_empty():
			_Attention.set_focus(c, part)
