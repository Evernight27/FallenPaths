class_name CombatUiHints
extends RefCounted

## Shared UI hint resolution for snapshot rows and live combatant dicts.

const _Footwork := preload("res://combat/CombatFootwork.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")


static func footwork_hint_text(c: Dictionary) -> String:
	var stamped: String = str(c.get("position_angle_ui_hint", "")).strip_edges()
	if not stamped.is_empty():
		return stamped
	if not _Footwork.enabled():
		return ""
	return _Footwork.get_ui_hint(c)


static func footwork_hint_suffix(c: Dictionary) -> String:
	var hint: String = footwork_hint_text(c)
	return (" · " + hint) if not hint.is_empty() else ""


static func attention_hint_text(c: Dictionary) -> String:
	var stamped: String = str(c.get("attention_ui_hint", "")).strip_edges()
	if not stamped.is_empty():
		return stamped
	if not _Attention.enabled():
		return ""
	return _Attention.format_attention_ui_hint(c)


## Prefer exported row keys (snapshot-safe); live derive when flags on and **`manager`** set.
static func counter_tempo_hint_key(c: Dictionary, manager: Node = null) -> String:
	var tempo: String = str(c.get("counter_tempo_ui_hint", "")).strip_edges()
	if not tempo.is_empty():
		return tempo
	if not _CounterTempo.enabled():
		return ""
	if manager != null and c != null:
		return _CounterTempo.snapshot_ui_hint(manager, c)
	return str(c.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")).strip_edges()
