class_name CombatFootwork
extends RefCounted

## Tier 4.4 pilot: abstract step-on-attack shifts **`attack_angle_deg`** via per-combatant offset (no world positions).
## Tier 4.4.2: symmetric defender step on committed parry (guard line) or dodge (eval part line).
## Lifecycle: **`clear_on_exchange_end`** when **`pending_attack`** drops or exchange aborts; UI via **`offset_visible_for_ui_state`** (**`wind_up`** / **`recovering`** only).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_position_angle_footwork_enabled()


## Footwork UI / diagram suffix only while an exchange step is active (not idle reserve).
static func offset_visible_for_ui_state(c: Dictionary) -> bool:
	if c == null or c.is_empty():
		return false
	var st: String = str(c.get("state", "")).strip_edges()
	return (
		st == CombatConstants.STATE_WIND_UP
		or st == CombatConstants.STATE_RECOVERING
	)


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
	return "Step"


## Prefer **`CombatUiHints.footwork_hint_text`** for UI/snapshot. Alias of **`get_ui_hint`**.
static func snapshot_ui_hint(c: Dictionary) -> String:
	return get_ui_hint(c)


## Player-visible label: stamped key when present, else derive from offset (snapshot-safe).
static func get_ui_hint(c: Dictionary) -> String:
	if not enabled() or c == null or not offset_visible_for_ui_state(c):
		return ""
	var derived: String = format_position_angle_ui_hint(c)
	var stamped: String = str(
		c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT, "")
	).strip_edges()
	if not stamped.is_empty():
		if derived.is_empty():
			return derived
		if stamped != derived:
			return derived
		return stamped
	return derived


## Formation diagram cells: no suffix (offset degrees are combat-only, not shown in UI).
static func get_diagram_label_suffix(_c: Dictionary) -> String:
	return ""


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


## Clears step offset + UI hint. Call when **`pending_attack`** is dropped or an exchange ends without **`AttackResolver`** resolve (abort, skip, recovery, medical halt).
static func clear_on_exchange_end(c: Dictionary) -> void:
	clear_position_offset(c)


static func clear_position_offset(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
	refresh_ui_hint(c)
