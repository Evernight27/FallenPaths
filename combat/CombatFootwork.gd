class_name CombatFootwork
extends RefCounted

## Tier 4.4 pilot: abstract step-on-attack shifts **`attack_angle_deg`** via per-combatant offset (no world positions).
## Tier 4.4.2: symmetric defender step on committed parry (guard line) or dodge (eval part line).
## Lifecycle: **`clear_on_exchange_end`** when **`pending_attack`** drops or exchange aborts; UI via **`offset_visible_for_ui_state`** (**`wind_up`** / **`recovering`** only).
## Attachment: reads **line keys** only — not **`weapon_form`** or legacy **`stance`**. Hub LIVE_PATHS **`#wf-tier-44-pa`** (stamp / geometry / clear / lookup). Form home via **`assign_form`**; matrix **`#wf-form-guard-pa-matrix`**.
## Canonical: apply_attack_step_on_windup · apply_defender_step_on_parry · apply_defender_step_on_dodge · guard_angle_deg · apply_offset_to_angle_deg · clear_on_exchange_end · clear_on_death · reconcile_idle_offset · return_to_waiting · return_to_cowering · CombatUiHints.footwork_hint_text.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_position_angle_footwork_enabled()


## Footing UI / diagram suffix only while an exchange step is active (not idle reserve).
static func offset_visible_for_ui_state(c: Dictionary) -> bool:
	if c == null or c.is_empty():
		return false
	var st: String = _EntityAccess.state_str(c)
	return (
		st == CombatConstants.STATE_WIND_UP
		or st == CombatConstants.STATE_RECOVERING
	)


## Attacker PA stamp from **line id** (not form). Scrubs leaked idle keys before fresh stamp. Production callers: LIVE_PATHS **`#wf-pa-stamp-callers`**. Empty line clears offset.
static func apply_attack_step_on_windup(attacker: Dictionary, attack_line: String) -> void:
	if not enabled() or attacker == null:
		return
	reconcile_idle_offset(attacker)
	var line: String = str(attack_line).strip_edges()
	if line.is_empty():
		clear_position_offset(attacker)
		return
	attacker[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = (
		CombatConstants.position_angle_offset_deg_for_attack_line(line)
	)
	refresh_ui_hint(attacker)


## Defender parry PA stamp from live **`guard_line`**. Scrubs leaked idle keys before fresh stamp. **`#wf-pa-stamp-callers`**.
static func apply_defender_step_on_parry(defender: Dictionary, guard_line: String) -> void:
	if not enabled() or defender == null:
		return
	reconcile_idle_offset(defender)
	var line: String = str(guard_line).strip_edges()
	if line.is_empty():
		line = CombatConstants.GUARD_DEFAULT
	defender[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = (
		CombatConstants.position_angle_defender_offset_deg_for_line(
			line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
		)
	)
	refresh_ui_hint(defender)


## Defender dodge PA stamp from body-part → line. Scrubs leaked idle keys before fresh stamp. **`#wf-pa-stamp-callers`**.
static func apply_defender_step_on_dodge(defender: Dictionary, dodge_eval_part: String) -> void:
	if not enabled() or defender == null:
		return
	reconcile_idle_offset(defender)
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


## Player-visible label: always derived from live offset (ignores stale stamped keys).
static func get_ui_hint(c: Dictionary) -> String:
	if not enabled() or c == null or not offset_visible_for_ui_state(c):
		return ""
	return format_position_angle_ui_hint(c)


## Drop leaked PA keys when idle (**`waiting`** / **`cowering`** / medical) — UI already hides; keeps dict + snapshot clean.
static func reconcile_idle_offset(c: Dictionary) -> void:
	if c == null or offset_visible_for_ui_state(c):
		return
	if (
		c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
		or c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
	):
		clear_position_offset(c)


## Set idle reserve and scrub leaked PA keys (same-frame snapshot guard after resolve/abort).
static func return_to_waiting(c: Dictionary) -> void:
	if c == null or c.is_empty():
		return
	c.state = CombatConstants.STATE_WAITING
	reconcile_idle_offset(c)


## Set cowering reserve and scrub leaked PA keys (mobility / no-arm idle — no Step UI).
static func return_to_cowering(c: Dictionary) -> void:
	if c == null or c.is_empty():
		return
	c.state = CombatConstants.STATE_COWERING
	reconcile_idle_offset(c)


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


## Attacker contact angle += stamped offset (read only). **`#wf-pa-geometry-callers`**.
static func apply_offset_to_angle_deg(base_deg: float, attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return base_deg
	return fmod(base_deg + get_attacker_offset_deg(attacker) + 360.0, 360.0)


static func apply_defender_offset_to_guard_deg(base_guard_deg: float, defender: Dictionary) -> float:
	if not enabled() or defender == null:
		return base_guard_deg
	return fmod(base_guard_deg + get_defender_offset_deg(defender) + 360.0, 360.0)


## Defender contact guard angle: **`get_guard_angle_deg(guard_line)`** ± PA offset. **`#wf-pa-geometry-callers`**.
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


## Clears step offset + UI hint. Call when **`pending_attack`** is dropped or an exchange ends without **`AttackResolver`** resolve (abort, skip, recovery, medical halt). All production callers: LIVE_PATHS **`#wf-pa-clear-callers`**.
static func clear_on_exchange_end(c: Dictionary) -> void:
	clear_position_offset(c)


## Fatal wound / bleed-out — alias of **`clear_on_exchange_end`** (grep **`#wf-pa-clear-callers`** death rows).
static func clear_on_death(c: Dictionary) -> void:
	clear_on_exchange_end(c)


static func clear_position_offset(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
	refresh_ui_hint(c)
