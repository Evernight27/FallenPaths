class_name CompanyHud
extends PanelContainer

## Overworld company resource strip (Camp-1.1 HUD · Camp-1.2 wage hint). Parent: tree root **`UIOverlayLayer`**.

const _CompanyState := preload("res://world/CompanyState.gd")
const _MapBleedPolicy := preload("res://world/MapBleedPolicy.gd")

var _gold_label: Label
var _med_label: Label
var _tools_label: Label
var _day_label: Label
var _wage_hint_label: Label
var _bleed_hint_label: Label
var _renown_label: Label


func _init() -> void:
	name = "CompanyHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	z_index = 101
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 120
	offset_top = 10
	offset_right = 720
	offset_bottom = 50
	custom_minimum_size = Vector2(600, 40)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	_gold_label = _make_stat_label(row, "Gold: —")
	_med_label = _make_stat_label(row, "Med: —")
	_tools_label = _make_stat_label(row, "Tools: —")
	_day_label = _make_stat_label(row, "Day: —")
	_wage_hint_label = _make_stat_label(row, "")
	_wage_hint_label.visible = false
	_wage_hint_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	_bleed_hint_label = _make_stat_label(row, "")
	_bleed_hint_label.visible = false
	_bleed_hint_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
	_renown_label = _make_stat_label(row, "")
	_renown_label.visible = false
	_renown_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))


static func _make_stat_label(parent: HBoxContainer, text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	parent.add_child(lbl)
	return lbl


func refresh_from_state(
	state: Dictionary,
	living_count: int = 0,
	show_wage_hint: bool = false,
	world: Node2D = null
) -> void:
	if _gold_label == null:
		return
	_gold_label.text = "Gold: %d" % int(state.get("gold", 0))
	var med_n: int = int(state.get("medical_supplies", 0))
	var triage_suffix: String = ""
	if world is Node2D:
		triage_suffix = _CompanyState.format_hud_triage_suffix(world as Node2D)
	_med_label.text = "Med: %d%s" % [med_n, triage_suffix]
	_tools_label.text = "Tools: %d" % int(state.get("tool_supplies", 0))
	if world is Node2D:
		_day_label.text = _CompanyState.format_day_hud_line(world)
	else:
		_day_label.text = "Day: %d" % int(state.get("day_index", 0))
	if _wage_hint_label != null:
		_wage_hint_label.visible = show_wage_hint
		if show_wage_hint:
			_wage_hint_label.text = _CompanyState.format_next_wage_hint(state, living_count)
	if _bleed_hint_label != null:
		var bleed_hint: String = ""
		if world is Node2D:
			bleed_hint = _MapBleedPolicy.hud_bleed_hint(world)
		_bleed_hint_label.visible = not bleed_hint.is_empty()
		if not bleed_hint.is_empty():
			_bleed_hint_label.text = bleed_hint
	if _renown_label != null:
		var renown: int = 0
		if world is Node2D:
			renown = _CompanyState.get_renown(world)
		_renown_label.visible = renown > 0
		if renown > 0:
			_renown_label.text = "Renown: %d" % renown
