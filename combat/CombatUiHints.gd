class_name CombatUiHints
extends RefCounted

## Shared UI hint resolution for snapshot rows and live combatant dicts.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")


static func any_tactical_features_enabled() -> bool:
	return _Footwork.enabled() or _Attention.enabled() or _CounterTempo.enabled() or _FlurryBind.enabled()


static func _first_exported_hint(c: Dictionary, keys: Array) -> String:
	for key in keys:
		var s: String = str(c.get(key, "")).strip_edges()
		if not s.is_empty():
			return s
	return ""


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


static func attention_hint_text(c: Dictionary, manager: Node = null) -> String:
	if c.is_empty():
		return ""
	if not _Attention.enabled():
		return _first_exported_hint(
			c, ["attention_ui_hint", CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT]
		)
	if manager != null:
		return _Attention.live_ui_hint(manager, c)
	var exported: String = _first_exported_hint(
		c, ["attention_ui_hint", CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT]
	)
	if not exported.is_empty():
		return exported
	return _Attention.snapshot_ui_hint(c)


## Snapshot row keys + live derive when **`manager`** set (see **`CounterTempo.snapshot_ui_hint`**).
static func counter_tempo_hint_key(c: Dictionary, manager: Node = null) -> String:
	if c == null or c.is_empty():
		return ""
	var row: String = _first_exported_hint(
		c, ["counter_tempo_ui_hint", CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT]
	)
	if not _CounterTempo.enabled():
		return row
	if manager != null:
		var live: String = _CounterTempo.snapshot_ui_hint(manager, c)
		return live if not live.is_empty() else row
	return row


## Empty unless **`STATE_COWERING`** (Tier **6.1** mobility).
static func cowering_mobility_tooltip_line(c: Dictionary) -> String:
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		return ""
	if _EntityAccess.can_flee_or_fall_back(c):
		return "No arms — may fall back when rear rank in your file is clear."
	if not _EntityAccess.is_unconscious(c):
		return "No arms — holding position (fall back blocked)."
	return ""


static func flurry_bind_gauge_label(c: Dictionary, manager: Node = null) -> String:
	if not _FlurryBind.enabled() or manager == null or c.is_empty():
		return ""
	var clk: float = _EntityAccess.combat_clock_float(manager)
	if not _FlurryBind.is_active(c, clk):
		return ""
	return "Bind exchange"


static func flurry_bind_hint_suffix(c: Dictionary, manager: Node = null) -> String:
	var label: String = flurry_bind_gauge_label(c, manager)
	return (" · " + label) if not label.is_empty() else ""


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
		var attn_hint: String = _first_exported_hint(
			c, [CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, "attention_ui_hint"]
		)
		if attn_hint.is_empty():
			attn_hint = attention_hint_text(c, manager)
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
	var attn: String = attention_hint_text(c, manager)
	if not attn.is_empty():
		tips.append("Attention: %s" % attn)
	var tempo: String = counter_tempo_hint_key(c, manager)
	if tempo == "counter_ready":
		tips.append("Counter window open — seize tempo.")
	elif tempo == "counter_winding":
		tips.append("Incoming wind-up — counter window building.")
	if bool(c.get("is_counter_tempo_wind_up", false)):
		tips.append("Counter-tempo riposte — shortened wind-up.")
	if _FlurryBind.enabled() and manager != null and _FlurryBind.is_active(c, _EntityAccess.combat_clock_float(manager)):
		var left: int = int(c.get("flurry_exchanges_left", 0))
		tips.append(
			"Bind exchange — faster blows vs bound opponent (%d exchange(s) left)."
			% maxi(0, left)
		)
	var cow: String = cowering_mobility_tooltip_line(c)
	if not cow.is_empty():
		tips.append(cow)
	var host_line: String = _intruder_host_line_tooltip_line(c, "", manager)
	if not host_line.is_empty():
		tips.append(host_line.strip_edges())
	var fm: String = _FormationMoveDuration.formation_preview_tooltip_line(manager, c)
	if not fm.is_empty():
		tips.append(fm)
	var st: String = _EntityAccess.state_str(c)
	if st in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
		var listed_fm: String = str(
			c.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")
		).strip_edges()
		if not listed_fm.is_empty():
			tips.append(listed_fm)
	if st in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
		tips.append(
			"Formation move — heavy hits (intensity ≥ %.0f) may cancel; lighter hits extend duration."
			% CombatConstants.FORMATION_HIT_CANCEL_INTENSITY
		)
	return tips


static func _intruder_host_line_tooltip_line(
	c: Dictionary, display_name: String, manager: Node = null
) -> String:
	if not _ZoneOfControl.is_intruded(c):
		return ""
	var home: String = _EntityAccess.formation_id_str(c)
	var host: String = (
		_ZoneOfControl.zone_geometry_fid_from_row(manager, c)
		if manager != null
		else _ZoneOfControl.intrusion_host_fid(c)
	)
	if host.is_empty() or host == home:
		return ""
	return "%s — host line %s (home %s)" % [display_name, host, home]


static func formation_cell_tooltip_lines(
	c: Dictionary, display_name: String, manager: Node = null
) -> PackedStringArray:
	var lines: PackedStringArray = []
	var host_line: String = _intruder_host_line_tooltip_line(c, display_name, manager)
	if not host_line.is_empty():
		lines.append(host_line)
	var fw: String = footwork_hint_text(c)
	if not fw.is_empty():
		lines.append("%s — footwork: %s" % [display_name, fw])
	var attn: String = attention_hint_text(c, manager)
	if not attn.is_empty():
		lines.append("%s — attention: %s" % [display_name, attn])
	var tempo: String = counter_tempo_hint_key(c, manager)
	if tempo == "counter_ready":
		lines.append("%s — counter window open" % display_name)
	elif tempo == "counter_winding":
		lines.append("%s — counter window building" % display_name)
	var cow: String = cowering_mobility_tooltip_line(c)
	if not cow.is_empty():
		lines.append("%s — %s" % [display_name, cow])
	var fm: String = _FormationMoveDuration.formation_preview_tooltip_line(manager, c)
	if not fm.is_empty():
		lines.append("%s — %s" % [display_name, fm])
	return lines
