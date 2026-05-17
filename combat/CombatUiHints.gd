class_name CombatUiHints
extends RefCounted

## Shared UI hint resolution for snapshot rows and live combatant dicts.

const _Footwork := preload("res://combat/CombatFootwork.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")


static func any_tactical_features_enabled() -> bool:
	return _Footwork.enabled() or _Attention.enabled() or _CounterTempo.enabled()


static func footwork_hint_text(c: Dictionary) -> String:
	var exported: String = str(c.get("position_angle_ui_hint", "")).strip_edges()
	if not _Footwork.enabled():
		return exported
	return _Footwork.get_ui_hint(c)


## Compact formation-diagram cell suffix (` · +14°`); full label via **`footwork_hint_text`**.
static func footwork_diagram_suffix(c: Dictionary) -> String:
	if c == null:
		return ""
	var exported: String = str(c.get("position_angle_ui_hint", "")).strip_edges()
	if not _Footwork.enabled():
		if exported.is_empty():
			return ""
		return (" · " + exported) if not exported.begins_with(" · ") else exported
	return _Footwork.get_diagram_label_suffix(c)


static func footwork_hint_suffix(c: Dictionary) -> String:
	var hint: String = footwork_hint_text(c)
	return (" · " + hint) if not hint.is_empty() else ""


static func attention_hint_text(c: Dictionary) -> String:
	var exported: String = str(c.get("attention_ui_hint", "")).strip_edges()
	if not _Attention.enabled():
		return exported
	return _Attention.snapshot_ui_hint(c)


## Snapshot row keys + live derive when **`manager`** set (see **`CounterTempo.snapshot_ui_hint`**).
static func counter_tempo_hint_key(c: Dictionary, manager: Node = null) -> String:
	if c == null or c.is_empty():
		return ""
	var row: String = str(c.get("counter_tempo_ui_hint", "")).strip_edges()
	if row.is_empty():
		row = str(c.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")).strip_edges()
	if not _CounterTempo.enabled():
		return row
	if manager != null:
		var live: String = _CounterTempo.snapshot_ui_hint(manager, c)
		return live if not live.is_empty() else row
	return row


static func counter_tempo_gauge_label(tempo_hint: String) -> String:
	if tempo_hint.is_empty():
		return ""
	if tempo_hint == "counter_ready":
		return "Counter!"
	if tempo_hint == "counter_winding":
		return "Seize tempo…"
	return ""


## Export stamped hint fields on a **`CombatCombatantsSnapshot`** row from live **`c`**.
static func stamp_snapshot_hint_fields(item: Dictionary, c: Dictionary, manager: Node) -> void:
	if _Footwork.enabled():
		var off_deg: float = _Footwork.get_defender_offset_deg(c)
		if absf(off_deg) >= 0.01:
			item["position_angle_offset_deg"] = off_deg
		var fw_hint: String = footwork_hint_text(c)
		if not fw_hint.is_empty():
			item["position_angle_ui_hint"] = fw_hint
	if _Attention.enabled():
		var attn_hint: String = attention_hint_text(c)
		if not attn_hint.is_empty():
			item["attention_ui_hint"] = attn_hint
	if _CounterTempo.enabled() and manager != null:
		var tempo_hint: String = counter_tempo_hint_key(c, manager)
		if not tempo_hint.is_empty():
			item["counter_tempo_ui_hint"] = tempo_hint


## Waiting tick: salience + yomi + attention UI stamp (see **`CombatAttention.refresh_for_waiting_tick`**).
static func refresh_waiting_tick_stamps(manager: Node, c: Dictionary) -> void:
	if manager == null or c == null or not _Attention.enabled():
		return
	_Attention.refresh_for_waiting_tick(manager, c)


static func gauge_tooltip_lines(c: Dictionary, manager: Node = null) -> PackedStringArray:
	var tips: PackedStringArray = []
	var fw: String = footwork_hint_text(c)
	if not fw.is_empty():
		tips.append("Arc footwork (position-angle step): %s" % fw)
	var attn: String = attention_hint_text(c)
	if not attn.is_empty():
		tips.append("Attention: %s" % attn)
	var tempo: String = counter_tempo_hint_key(c, manager)
	if tempo == "counter_ready":
		tips.append("Counter window open — seize tempo.")
	elif tempo == "counter_winding":
		tips.append("Incoming wind-up — counter window building.")
	if bool(c.get("is_counter_tempo_wind_up", false)):
		tips.append("Counter-tempo riposte — shortened wind-up.")
	return tips


static func formation_cell_tooltip_lines(
	c: Dictionary, display_name: String, manager: Node = null
) -> PackedStringArray:
	var lines: PackedStringArray = []
	var fw: String = footwork_hint_text(c)
	if not fw.is_empty():
		lines.append("%s — footwork: %s" % [display_name, fw])
	var attn: String = attention_hint_text(c)
	if not attn.is_empty():
		lines.append("%s — attention: %s" % [display_name, attn])
	var tempo: String = counter_tempo_hint_key(c, manager)
	if tempo == "counter_ready":
		lines.append("%s — counter window open" % display_name)
	elif tempo == "counter_winding":
		lines.append("%s — counter window building" % display_name)
	return lines
