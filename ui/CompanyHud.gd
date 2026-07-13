class_name CompanyHud
extends PanelContainer
## Overworld company resource strip (Camp-1.1 HUD '. Camp-1.2 wage hint). Parent: tree root **`UIOverlayLayer`**.

# Runtime preload ' circular dependency (CompanyState preloads CompanyHud).
static var _company_state_cache: Variant = null

var _gold_label: Label
var _med_label: Label
var _tools_label: Label
var _food_label: Label
var _day_label: Label
var _wage_hint_label: Label
var _bleed_hint_label: Label
var _renown_label: Label
var _persistence_label: Label


static func _get_company_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


func _init() -> void:
    name = "CompanyHud"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    focus_mode = Control.FOCUS_NONE
    z_index = 101
    set_anchors_preset(Control.PRESET_TOP_LEFT)
    offset_left = 120
    offset_top = 10
    offset_right = 820
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

    _gold_label = _make_stat_label(row, "Gold:  - ")
    _med_label = _make_stat_label(row, "Med:  - ")
    _tools_label = _make_stat_label(row, "Tools:  - ")
    _food_label = _make_stat_label(row, "Food:  - ")
    _day_label = _make_stat_label(row, "Day:  - ")
    _wage_hint_label = _make_stat_label(row, "")
    _wage_hint_label.visible = false
    _wage_hint_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
    _bleed_hint_label = _make_stat_label(row, "")
    _bleed_hint_label.visible = false
    _bleed_hint_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
    _renown_label = _make_stat_label(row, "")
    _renown_label.visible = false
    _renown_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
    _persistence_label = _make_stat_label(row, "")
    _persistence_label.visible = false


static func _make_stat_label(parent: HBoxContainer, text: String) -> Label:
    var lbl := Label.new()
    lbl.text = text
    lbl.add_theme_font_size_override("font_size", 14)
    parent.add_child(lbl)
    return lbl


func refresh_from_state(
    state: Dictionary, living_count: int = 0, show_wage_hint: bool = false, world: Node2D = null
) -> void:
    if _gold_label == null:
        return
    var gold: int = state.get("gold", 0)
    _gold_label.text = "Gold: %d" % gold
    if world is Node2D:
        var bill: int = _get_company_state().compute_next_wage_bill(world as Node2D)
        if gold < 0:
            _gold_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.4))
        elif gold < bill:
            _gold_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
        else:
            _gold_label.remove_theme_color_override("font_color")
    var med_n: int = state.get("medical_supplies", 0)
    var triage_suffix: String = ""
    if world is Node2D:
        triage_suffix = _get_company_state().format_hud_triage_suffix(world as Node2D)
    _med_label.text = "Med: %d%s" % [med_n, triage_suffix]
    _tools_label.text = "Tools: %d" % state.get("tool_supplies", 0)
    if _food_label != null:
        var food_n: int = state.get("food_supplies", 0)
        _food_label.text = "Food: %d" % food_n
        if world is Node2D and _get_company_state().should_show_next_provisions_hint(world as Node2D):
            _food_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
            _food_label.tooltip_text = _get_company_state().format_next_provisions_hint(world as Node2D)
        else:
            _food_label.remove_theme_color_override("font_color")
            _food_label.tooltip_text = ""
    if world is Node2D:
        _day_label.text = _get_company_state().format_day_hud_line(world)
    else:
        _day_label.text = "Day: %d" % state.get("day_index", 0)
    if _persistence_label != null:
        var persist_line: String = ""
        if world is Node2D:
            persist_line = _get_company_state().format_hud_persistence_line(world as Node2D)
        _persistence_label.visible = not persist_line.is_empty()
        if not persist_line.is_empty():
            _persistence_label.text = persist_line
            if persist_line == "Restored":
                _persistence_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.62))
            elif persist_line == "Saved":
                _persistence_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.95))
            else:
                _persistence_label.add_theme_color_override("font_color", Color(0.6, 0.78, 0.88))
    if _wage_hint_label != null:
        var economy_hints: PackedStringArray = PackedStringArray()
        if world is Node2D:
            economy_hints = _get_company_state().format_hud_economy_hint_lines(state, living_count, world as Node2D)
        elif show_wage_hint:
            economy_hints = _get_company_state().format_hud_economy_hint_lines(state, living_count)
        _wage_hint_label.visible = not economy_hints.is_empty()
        if not economy_hints.is_empty():
            _wage_hint_label.text = " '. ".join(economy_hints)
    if _bleed_hint_label != null:
        var bleed_hint: String = ""
        if world is Node2D:
            bleed_hint = MapBleedPolicy.hud_bleed_hint(world)
        _bleed_hint_label.visible = not bleed_hint.is_empty()
        if not bleed_hint.is_empty():
            _bleed_hint_label.text = bleed_hint
    if _renown_label != null:
        var renown: int = 0
        if world is Node2D:
            renown = _get_company_state().get_renown(world)
        _renown_label.visible = renown > 0
        if renown > 0:
            _renown_label.text = "Renown: %d" % renown
