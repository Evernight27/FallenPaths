extends Node2D

## Scene controller for the interactive combat tuning scene.
## Now uses the full production combat pipeline (formations, AI, signals, medical phase)
## with tuning controls layered on top for debugging.

# --- Preloads (production dependencies) ---
const _MgrScript := preload("res://tools/combat_tuning/TuningCombatManager.gd")
static var _EntityAccess: Variant = null


static func _get_entity_access() -> GDScript:
    if _EntityAccess == null:
        _EntityAccess = load("res://combat/access/CombatantEntityAccess.gd")
    return _EntityAccess


static var _CombatConstants: Variant = null


static func _get_combat_constants() -> GDScript:
    if _CombatConstants == null:
        _CombatConstants = load("res://combat/CombatConstants.gd")
    return _CombatConstants


const _WeaponForm := preload("res://combat/weapon_form/CombatWeaponForm.gd")
const _TurnReadyHandler := preload("res://ui/battle/TurnReadyHandler.gd")
const _FormationPreset := preload("res://combat/formation/FormationPreset.gd")
static var _CombatAIPicker: Variant = null


static func _get_combat_ai_picker() -> GDScript:
    if _CombatAIPicker == null:
        _CombatAIPicker = load("res://combat/ai/CombatAIActionPicker.gd")
    return _CombatAIPicker


const _EventDispatch := preload("res://combat/flow/CombatEventDispatch.gd")
const _ProcessTick := preload("res://combat/flow/CombatProcessTick.gd")
const _EventScheduler := preload("res://combat/flow/CombatEventScheduler.gd")

# --- Preloads (tuning modules) ---
const _ConfigData := preload("res://tools/combat_tuning/TuningConfigData.gd")
const _Config := _ConfigData
const _Spawner := preload("res://tools/combat_tuning/CombatantSpawner.gd")
const _Formatter := preload("res://tools/combat_tuning/TuningLogFormatter.gd")

# --- State ---
var manager: Node = null
var attacker_entity: Node = null
var defender_entity: Node = null
var attacker_id: int = -1
var defender_id: int = -1

var attacker_config: Variant = _Config.default_attacker_config()
var defender_config: Variant = _Config.default_defender_config()

var _current_move_id: String = "oberhau"
var _current_intensity: float = 0.62
var _strike_count: int = 0

# Auto-combat settings
var _auto_enabled: bool = false
var _auto_waiting_for_death: bool = false
var _auto_respawn_delay: float = 0.0
var _auto_medical_ff: bool = false  # fast-forward medical in auto mode

# Cycle tracking (auto mode)
var _cycle_count: int = 0
var _cycle_attacker_wins: int = 0
var _cycle_defender_wins: int = 0
var _cycle_total_strikes: int = 0
var _cycle_attacker_dmg_dealt: float = 0.0
var _cycle_defender_dmg_dealt: float = 0.0
var _cycle_start_strikes: int = 0
var _cycle_outcome_counts: Dictionary = {}
var _cycle_ke_samples: Array = []
var _last_end_cause: String = ""

# Override state: maps combatant_id -> {move_id, target_id, intensity}
var _tuning_override: Dictionary = {}
# Set to true when we've injected an override and are waiting for it to resolve
var _override_pending: bool = false

# --- UI references (built in _build_ui) ---
var _attacker_health_labels: Dictionary = {}
var _defender_health_labels: Dictionary = {}
var _attacker_state_label: Label = null
var _defender_state_label: Label = null
var _attacker_fg_line: Label = null
var _defender_fg_line: Label = null
var _attacker_header_label: Label = null
var _defender_header_label: Label = null
var _log_rtl: RichTextLabel = null
var _plain_log: PackedStringArray = []
var _move_option: OptionButton = null
var _intensity_slider: HSlider = null
var _intensity_label: Label = null
var _status_bar: Label = null
var _strike_btn: Button = null
var _exchange_btn: Button = null

var _player_preset: Dictionary = {}
var _enemy_preset: Dictionary = {}
var _tuning_main_vbox: VBoxContainer = null
var _active_scenario_key: String = "Random"


func _ready() -> void:
    _build_ui()
    _apply_configs_for_active_scenario()
    _spawn_combatants()


func _apply_configs_for_active_scenario(randomize_intensity: bool = true) -> void:
    var configs: Array = []
    if _active_scenario_key == "Random":
        configs = _ConfigData.TuningCombatantConfig.random_configs_pair()
    else:
        configs = _load_scenario(_active_scenario_key)
        if configs.size() < 2:
            _active_scenario_key = "Random"
            configs = _ConfigData.TuningCombatantConfig.random_configs_pair()
    attacker_config = configs[0]
    defender_config = configs[1]
    if randomize_intensity or _active_scenario_key == "Random":
        _current_intensity = randf_range(0.4, 0.9)
    if _attacker_header_label != null:
        _attacker_header_label.text = attacker_config.display_name
    if _defender_header_label != null:
        _defender_header_label.text = defender_config.display_name
    if _intensity_slider != null:
        _intensity_slider.value = _current_intensity
    if _intensity_label != null:
        _intensity_label.text = "%.2f" % _current_intensity


func _apply_random_matchup_configs() -> void:
    _active_scenario_key = "Random"
    _apply_configs_for_active_scenario()


func _process(_delta: float) -> void:
    if manager == null or not is_instance_valid(manager):
        return

    # Auto-combat: detect combat end and respawn
    if _auto_enabled:
        if _auto_try_respawn(_delta):
            return

    # Refresh tuning UI periodically
    _refresh_meter_display()


# ============================================================
#  Auto-combat lifecycle
# ============================================================


func _any_dead() -> bool:
    if manager == null:
        return false
    var atk_c = _get_entity_access().manager_get_combatant(manager, attacker_id)
    var def_c = _get_entity_access().manager_get_combatant(manager, defender_id)
    if atk_c.is_empty() or def_c.is_empty():
        return false
    return not _get_entity_access().alive_bool(atk_c) or not _get_entity_access().alive_bool(def_c)


func _is_resolution_closed() -> bool:
    if manager == null:
        return true
    if "combat_resolution_closed" in manager and manager.combat_resolution_closed:
        return true
    if manager.medical_phase and manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase():
        return true
    return false


func _auto_try_respawn(delta: float) -> bool:
    if _any_dead() or _is_resolution_closed():
        if not _auto_waiting_for_death:
            _log_cycle_summary()
            _auto_waiting_for_death = true
            _append_log("[color=#ffff88]Auto-combat: cycle complete, respawning.[/color]")
        _auto_respawn_delay += delta
        if _auto_respawn_delay >= 0.1:
            _auto_respawn_delay = 0.0
            _apply_configs_for_active_scenario(false)
            _spawn_combatants()
        return true
    return false


func _fast_forward_medical_phase():
    if manager == null or not is_instance_valid(manager):
        _auto_medical_ff = false
        _spawn_combatants()
        return
    if not manager.medical_phase:
        _auto_medical_ff = false
        _spawn_combatants()
        return
    if manager.has_method("finish_battle_interactive"):
        manager.set_process(false)
        await manager.finish_battle_interactive()
        _auto_medical_ff = false
        if not is_instance_valid(manager):
            _spawn_combatants()
            return
    if manager.medical_phase:
        manager.set_process(false)
        _cleanup_manager()
    _auto_medical_ff = false
    _spawn_combatants()


# ============================================================
#  Signal Handlers (wired to CombatManager)
# ============================================================


func _on_turn_ready(combatant_id: int) -> void:
    if _auto_enabled:
        # Auto mode: use normal TurnReadyHandler (AI picks)
        _TurnReadyHandler.handle(manager, combatant_id)
    else:
        # Manual mode: check for override
        if _tuning_override.has(combatant_id):
            var override = _tuning_override[combatant_id]
            var target_id: int = override.get("target_id", -1)
            var move_id: String = override.get("move_id", "oberhau")
            var intensity: float = override.get("intensity", 0.62)

            # Build a single-action list for the picker
            var action: Dictionary = {
                "move_id": move_id,
                "target_id": target_id,
                "intensity": intensity,
                "weight": 999999,
                "target_part": "",
            }
            _tuning_override.erase(combatant_id)
            _override_pending = false

            var actions: Array = [action]
            _get_combat_ai_picker().resolve_picked_turn_or_skip(
                manager, combatant_id, actions, _get_combat_constants().SIDE_PLAYER
            )
        else:
            # No override -- use normal AI
            _TurnReadyHandler.handle(manager, combatant_id)


func _enrich_strike_log_result(result: Dictionary, attacker_id_sig: int) -> Dictionary:
    var out: Dictionary = result.duplicate(true)
    var rd: Dictionary = out
    if out.get("result_dict") is Dictionary:
        rd = out["result_dict"]
    if str(out.get("weapon_id", rd.get("weapon_id", ""))).is_empty():
        var wid: String = ""
        if attacker_id_sig == attacker_id:
            wid = attacker_config.weapon_id
        elif attacker_id_sig == defender_id:
            wid = defender_config.weapon_id
        if not wid.is_empty():
            out["weapon_id"] = wid
            if out.get("result_dict") is Dictionary:
                out["result_dict"]["weapon_id"] = wid
    return out


func _on_action_resolved(attacker_id_sig: int, target_id_sig: int, result: Dictionary) -> void:
    var log_result: Dictionary = _enrich_strike_log_result(result, attacker_id_sig)
    var atk: Dictionary = _get_entity_access().manager_get_combatant(manager, attacker_id_sig)
    var tgt: Dictionary = _get_entity_access().manager_get_combatant(manager, target_id_sig)
    var atk_name: String = _get_entity_access().get_display_name(atk, attacker_id_sig)
    var tgt_name: String = _get_entity_access().get_display_name(tgt, target_id_sig)

    var atk_ent: Node = attacker_entity if attacker_id_sig == attacker_id else defender_entity
    var tgt_ent: Node = defender_entity if target_id_sig == defender_id else attacker_entity
    if attacker_id_sig == defender_id:
        atk_ent = defender_entity
    if target_id_sig == attacker_id:
        tgt_ent = attacker_entity

    var outcome: String = _Formatter.exchange_outcome(log_result)
    _record_exchange_outcome(outcome, log_result)

    var gauge_atk: float = float(log_result.get(DataKeys.PA_GAUGE_ATK_PRE, 0.0))
    var gauge_def: float = float(log_result.get(DataKeys.PA_GAUGE_DEF_PRE, 0.0))
    if _batch_running and _batch_csv_lines.size() > 0:
        _batch_csv_lines.append(_Formatter.csv_row(_strike_count, "", log_result, gauge_atk, gauge_def))
    var exchange_line: String = _Formatter.format_exchange_line(
        atk_name, tgt_name, log_result, atk_ent, tgt_ent, _strike_count, gauge_atk, gauge_def
    )
    _log_line(exchange_line)

    if outcome in ["hit", "glancing", "negligible"]:
        var rd: Dictionary = log_result
        if log_result.get("result_dict") is Dictionary:
            rd = log_result.get("result_dict")
        var dmg: float = float(rd.get("dmg", 0.0))
        if attacker_id_sig == attacker_id:
            _cycle_attacker_dmg_dealt += dmg
        else:
            _cycle_defender_dmg_dealt += dmg

    _refresh_display()


func _on_combat_ended(winner_side: String, _defeated_node: Node) -> void:
    var end_cause: String = _infer_end_cause(winner_side)
    _last_end_cause = end_cause
    _log_line(
        _Formatter.format_fight_end(
            winner_side,
            end_cause,
            attacker_config.display_name,
            defender_config.display_name,
            attacker_entity,
            defender_entity
        )
    )
    if not _auto_enabled and not _batch_running:
        _show_end_battle_button()


func _on_enemies_eliminated(_winner_side: String) -> void:
    pass


var _in_medical_phase: bool = false


func _in_medical_phase_start() -> void:
    _in_medical_phase = true
    _append_log("[color=orange]------ Enemies eliminated. Medical phase active. ------[/color]", false)
    if not _auto_enabled and not _batch_running:
        _show_end_battle_button()


func _on_combatant_health_changed(_cid: int) -> void:
    _refresh_meter_display()


func _on_formation_changed(_side: String) -> void:
    pass


func _on_engagement_state_changed(_formation_id: String, _line_cohesion: float, _engagement_posture: String) -> void:
    pass


func _on_combat_ui_hint(message: String) -> void:
    # Combat UI hints are noisy for paste-to-AI workflows; omit from plain log.
    if _log_rtl != null:
        var hint := message.strip_edges()
        if not hint.is_empty():
            if _log_rtl.text.is_empty():
                _log_rtl.append_text("[color=#666666][UI] %s[/color]" % hint)
            else:
                _log_rtl.append_text("\n[color=#666666][UI] %s[/color]" % hint)


# ============================================================
#  Override Provider (called from TuningCombatManager)
# ============================================================


func _override_provider(combatant_id: int) -> Array:
    if _tuning_override.has(combatant_id):
        var override = _tuning_override[combatant_id]
        var target_id: int = override.get("target_id", -1)
        var move_id: String = override.get("move_id", "oberhau")
        var intensity: float = override.get("intensity", 0.62)
        _tuning_override.erase(combatant_id)
        _override_pending = false
        return [
            {
                "move_id": move_id,
                "target_id": target_id,
                "intensity": intensity,
                "weight": 999999,
            }
        ]
    return []


# ============================================================
#  UI Construction
# ============================================================


func _build_ui() -> void:
    _build_tuning_overlay()


func _build_tuning_overlay() -> void:
    # Tuning overlay sits outside the production canvas layer so it's on top
    var overlay := CanvasLayer.new()
    overlay.name = "TuningOverlayLayer"
    overlay.layer = 10
    add_child(overlay)

    # Dark translucent background to block production UI underneath
    var bg := ColorRect.new()
    bg.name = "TuningBg"
    bg.color = Color(0.08, 0.08, 0.1, 0.88)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(bg)

    var margin: MarginContainer = MarginContainer.new()
    margin.anchor_right = 1.0
    margin.anchor_bottom = 1.0
    margin.add_theme_constant_override("margin_left", 4)
    margin.add_theme_constant_override("margin_right", 4)
    margin.add_theme_constant_override("margin_top", 4)
    margin.add_theme_constant_override("margin_bottom", 4)
    overlay.add_child(margin)

    _tuning_main_vbox = VBoxContainer.new()
    _tuning_main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tuning_main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _tuning_main_vbox.add_theme_constant_override("separation", 4)
    margin.add_child(_tuning_main_vbox)

    # Top bar: tuning buttons
    _tuning_main_vbox.add_child(_build_top_bar())

    # Combatant cards side by side
    var cards_hbox: HBoxContainer = HBoxContainer.new()
    cards_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    cards_hbox.custom_minimum_size = Vector2i(0, 240)
    cards_hbox.add_theme_constant_override("separation", 8)
    _tuning_main_vbox.add_child(cards_hbox)
    var atk_card := _build_combatant_card(true)
    cards_hbox.add_child(atk_card)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards_hbox.add_child(spacer)
    var def_card := _build_combatant_card(false)
    cards_hbox.add_child(def_card)

    # Controls row
    _tuning_main_vbox.add_child(_build_controls_row())

    # Tuning log
    _tuning_main_vbox.add_child(_build_tuning_log_panel())

    # Status bar
    _status_bar = Label.new()
    _status_bar.text = "Ready"
    _status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status_bar.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    _tuning_main_vbox.add_child(_status_bar)


func _build_top_bar() -> HBoxContainer:
    var hbox: HBoxContainer = HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.modulate = Color(1, 1, 1, 0.92)

    _strike_btn = Button.new()
    _strike_btn.text = "Strike (Atk)"
    _strike_btn.tooltip_text = "Force attacker's next turn to use selected move + intensity"
    _strike_btn.pressed.connect(_on_strike_pressed)
    hbox.add_child(_strike_btn)

    _exchange_btn = Button.new()
    _exchange_btn.text = "Exchange"
    _exchange_btn.tooltip_text = "Force attacker then defender to use selected move"
    _exchange_btn.pressed.connect(_on_exchange_pressed)
    hbox.add_child(_exchange_btn)

    var reset_btn: Button = Button.new()
    reset_btn.text = "Reset"
    reset_btn.tooltip_text = "Spawn fresh combatants"
    reset_btn.pressed.connect(_on_reset_pressed)
    hbox.add_child(reset_btn)

    var batch_btn: Button = Button.new()
    batch_btn.text = "Batch..."
    batch_btn.tooltip_text = "Run N cycles and collect aggregate stats"
    batch_btn.pressed.connect(_on_batch_pressed)
    hbox.add_child(batch_btn)

    var scenario_btn: Button = Button.new()
    scenario_btn.text = "Presets..."
    scenario_btn.tooltip_text = "Load a scenario preset"
    scenario_btn.pressed.connect(_on_scenario_pressed)
    hbox.add_child(scenario_btn)

    var randomize_btn: Button = Button.new()
    randomize_btn.text = "Randomize"
    randomize_btn.tooltip_text = "Randomize both combatants"
    randomize_btn.pressed.connect(_on_randomize_pressed)
    hbox.add_child(randomize_btn)

    # Auto-combat toggle
    var auto_btn: Button = Button.new()
    auto_btn.text = "Auto: ON"
    auto_btn.tooltip_text = "Toggle auto-combat loop (AI drives both sides)"
    auto_btn.pressed.connect(func(): _toggle_auto())
    hbox.add_child(auto_btn)

    var spacer: Control = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(spacer)

    return hbox


func _build_combatant_card(is_attacker: bool) -> Control:
    var wrapper := PanelContainer.new()
    var card_color: Color = Color(0.12, 0.12, 0.14) if is_attacker else Color(0.14, 0.12, 0.12)
    var border_color: Color = Color(0.4, 0.6, 0.9) if is_attacker else Color(0.9, 0.4, 0.4)
    var style := StyleBoxFlat.new()
    style.bg_color = card_color
    style.border_width_left = 1
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 1
    style.border_color = border_color
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    wrapper.add_theme_stylebox_override("panel", style)
    wrapper.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
    wrapper.custom_minimum_size = Vector2i(320, 200)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 2)
    wrapper.add_child(vbox)

    # Header
    var header: Label = Label.new()
    var cfg_v: Variant = attacker_config if is_attacker else defender_config
    header.text = cfg_v.display_name
    header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_theme_font_size_override("font_size", 16)
    header.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0) if is_attacker else Color(1.0, 0.8, 0.8))
    if is_attacker:
        _attacker_header_label = header
    else:
        _defender_header_label = header
    vbox.add_child(header)

    # Stats
    var species_name := "Human"
    if cfg_v.species_tres_path.contains("goblin"):
        species_name = "Goblin"
    var stats_label: Label = Label.new()
    stats_label.text = (
        "%s  STR:%d AGI:%d INT:%d END:%d PER:%d  %s"
        % [
            species_name,
            cfg_v.strength,
            cfg_v.agility,
            cfg_v.intelligence,
            cfg_v.endurance,
            cfg_v.perception,
            cfg_v.weapon_id
        ]
    )
    stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    vbox.add_child(stats_label)

    # Form and guard
    var fg_label: Label = Label.new()
    fg_label.text = "Form: %s  Guard: %s" % [cfg_v.form, cfg_v.guard_line]
    fg_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    vbox.add_child(fg_label)
    if is_attacker:
        _attacker_fg_line = fg_label
    else:
        _defender_fg_line = fg_label

    # Body health
    var body_title := Label.new()
    body_title.text = "Body Health"
    body_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
    vbox.add_child(body_title)

    for part in _ConfigData.BODY_PARTS:
        var hl: Label = Label.new()
        hl.text = "  %s: --" % part
        hl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
        vbox.add_child(hl)
        if is_attacker:
            _attacker_health_labels[part] = hl
        else:
            _defender_health_labels[part] = hl

    # Blood
    var blood_label: Label = Label.new()
    blood_label.text = "Blood: --"
    blood_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    vbox.add_child(blood_label)
    if is_attacker:
        _attacker_health_labels["_blood"] = blood_label
    else:
        _defender_health_labels["_blood"] = blood_label

    # Consciousness
    var con_label: Label = Label.new()
    con_label.text = "Con: --"
    con_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.7))
    vbox.add_child(con_label)
    if is_attacker:
        _attacker_health_labels["_con"] = con_label
    else:
        _defender_health_labels["_con"] = con_label

    # Stamina
    var stamina_label: Label = Label.new()
    stamina_label.text = "Stamina: --"
    stamina_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
    vbox.add_child(stamina_label)
    if is_attacker:
        _attacker_health_labels["_stamina"] = stamina_label
    else:
        _defender_health_labels["_stamina"] = stamina_label

    # Gauge
    var gauge_label: Label = Label.new()
    gauge_label.text = "Gauge: --"
    gauge_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
    vbox.add_child(gauge_label)
    if is_attacker:
        _attacker_health_labels["_gauge"] = gauge_label
    else:
        _defender_health_labels["_gauge"] = gauge_label

    # State
    var state_label: Label = Label.new()
    state_label.text = "State: --"
    state_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
    vbox.add_child(state_label)
    if is_attacker:
        _attacker_state_label = state_label
    else:
        _defender_state_label = state_label

    # Alive
    var alive_label: Label = Label.new()
    alive_label.text = "Alive: Yes"
    alive_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
    vbox.add_child(alive_label)
    if is_attacker:
        _attacker_health_labels["_alive"] = alive_label
    else:
        _defender_health_labels["_alive"] = alive_label

    return wrapper


func _build_controls_row() -> HBoxContainer:
    var hbox: HBoxContainer = HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.modulate = Color(1, 1, 1, 0.92)

    var move_label: Label = Label.new()
    move_label.text = " Move:"
    move_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    hbox.add_child(move_label)

    _move_option = OptionButton.new()
    _move_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _move_option.item_selected.connect(_on_move_selected)
    hbox.add_child(_move_option)

    var int_label: Label = Label.new()
    int_label.text = " Intensity:"
    int_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    hbox.add_child(int_label)

    _intensity_slider = HSlider.new()
    _intensity_slider.min_value = 0.1
    _intensity_slider.max_value = 1.0
    _intensity_slider.step = 0.01
    _intensity_slider.value = _current_intensity
    _intensity_slider.value_changed.connect(_on_intensity_changed)
    _intensity_slider.custom_minimum_size.x = 120
    hbox.add_child(_intensity_slider)

    _intensity_label = Label.new()
    _intensity_label.text = "%.2f" % _current_intensity
    _intensity_label.custom_minimum_size.x = 40
    _intensity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    hbox.add_child(_intensity_label)

    return hbox


func _build_tuning_log_panel() -> VBoxContainer:
    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL | Control.SIZE_SHRINK_END
    vbox.custom_minimum_size.y = 120

    var header_row := HBoxContainer.new()
    vbox.add_child(header_row)

    var log_header: Label = Label.new()
    log_header.text = "HEMA Tuning Log — Copy Log for AI review; structured lines also print to Output"
    log_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    log_header.add_theme_font_size_override("font_size", 13)
    log_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
    header_row.add_child(log_header)

    var copy_btn := Button.new()
    copy_btn.text = "Copy Log"
    copy_btn.pressed.connect(_copy_plain_log)
    header_row.add_child(copy_btn)

    var clear_btn := Button.new()
    clear_btn.text = "Clear"
    clear_btn.pressed.connect(_clear_plain_log)
    header_row.add_child(clear_btn)

    var sc: ScrollContainer = ScrollContainer.new()
    sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sc.custom_minimum_size.y = 80
    vbox.add_child(sc)

    _log_rtl = RichTextLabel.new()
    _log_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _log_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _log_rtl.bbcode_enabled = true
    _log_rtl.scroll_active = true
    _log_rtl.fit_content = true
    sc.add_child(_log_rtl)

    return vbox


# ============================================================
#  Combat Lifecycle
# ============================================================


func _spawn_combatants() -> void:
    _auto_medical_ff = false
    _cleanup_manager()

    manager = _MgrScript.new()
    manager.tuning_skip_medical = true
    manager.tuning_wait_for_player = true
    add_child(manager)

    var result: Dictionary = _Spawner.spawn_1v1(manager, attacker_config, defender_config)
    attacker_entity = result.get("attacker_entity") as Node
    defender_entity = result.get("defender_entity") as Node
    attacker_id = result.get("attacker_id", -1)
    defender_id = result.get("defender_id", -1)

    # Wire the override provider
    manager.tuning_override_provider = Callable(self, "_override_provider")

    # Create formation presets for 1v1
    _player_preset = _FormationPreset.default_for_count(1)
    _enemy_preset = _FormationPreset.default_for_count(1)

    # Connect signals
    manager.connect("turn_ready", Callable(self, "_on_turn_ready"))
    manager.connect("action_resolved", Callable(self, "_on_action_resolved"))
    manager.connect("combat_ended", Callable(self, "_on_combat_ended"))
    manager.connect("enemies_eliminated", Callable(self, "_on_enemies_eliminated"))
    manager.connect("combatant_health_changed", Callable(self, "_on_combatant_health_changed"))
    manager.connect("formation_changed", Callable(self, "_on_formation_changed"))
    manager.connect("engagement_state_changed", Callable(self, "_on_engagement_state_changed"))
    manager.connect("combat_ui_hint", Callable(self, "_on_combat_ui_hint"))

    # Start the manager -- builds formations, assigns rank/file, seeds events
    manager.start(_player_preset, _enemy_preset)

    # Batch mode: cancel initial ACTION_READY cooldowns (2-4 s) and fire immediately so the
    # first cycle does not waste time waiting for timers.  Manual tuning still uses the delay.
    if tuning_wait_for_player:
        var eac := _get_entity_access()
        for c in manager.combatants:
            if eac.alive_bool(c):
                _EventScheduler.cancel_pending_action_ready(manager, eac.id_int(c))
        for c in manager.combatants:
            if eac.alive_bool(c):
                _EventScheduler.schedule_action_ready(manager, eac.id_int(c), 0.0)

    # Assign forms and guards after start so rank/file/etc are set
    var atk_c: Dictionary = _get_entity_access().manager_get_combatant(manager, attacker_id)
    var def_c: Dictionary = _get_entity_access().manager_get_combatant(manager, defender_id)
    if not atk_c.is_empty():
        _WeaponForm.assign_form(manager, atk_c, attacker_config.form, "harness_baseline")
        atk_c["guard_line"] = attacker_config.guard_line
    if not def_c.is_empty():
        _WeaponForm.assign_form(manager, def_c, defender_config.form, "harness_baseline")
        def_c["guard_line"] = defender_config.guard_line

    _auto_waiting_for_death = false
    _auto_respawn_delay = 0.0
    _in_medical_phase = false
    _cycle_start_strikes = _strike_count
    _reset_cycle_exchange_stats()
    _log_line(_Formatter.format_calibration_preamble(), "#aaccff")
    _log_line(_Formatter.format_matchup_banner(attacker_config, defender_config), "#88ff88")
    _populate_move_dropdown()
    _refresh_display()


func _reset_cycle_exchange_stats() -> void:
    _cycle_outcome_counts.clear()
    _cycle_ke_samples.clear()
    _last_end_cause = ""
    if manager != null:
        manager.set_meta("tuning_strike_count", 0)


func _record_exchange_outcome(outcome: String, result: Dictionary) -> void:
    if outcome.is_empty() or outcome == "?":
        return
    # Rejects are guard-line invalidations — never counted as strikes.
    if outcome == "reject":
        _cycle_outcome_counts[outcome] = int(_cycle_outcome_counts.get(outcome, 0)) + 1
        return
    _strike_count += 1
    if manager != null:
        manager.set_meta("tuning_strike_count", _strike_count)
    _cycle_outcome_counts[outcome] = int(_cycle_outcome_counts.get(outcome, 0)) + 1
    # Track bind as a subset annotation on its parent parry outcome.
    if outcome in ["parry_deflect", "parry_partial"] and bool(result.get("parry_bind", false)):
        _cycle_outcome_counts["parry_bind"] = int(_cycle_outcome_counts.get("parry_bind", 0)) + 1
    var sample: Dictionary = _Formatter.ke_sample_from_result(result)
    var ke_j: float = float(sample.get("ke_j", 0.0))
    if ke_j > 0.0 or outcome in ["parry_deflect", "parry_partial"]:
        _cycle_ke_samples.append(sample)


func _infer_end_cause(winner_side: String) -> String:
    if manager == null:
        return "unknown"
    var atk_c = _get_entity_access().manager_get_combatant(manager, attacker_id)
    var def_c = _get_entity_access().manager_get_combatant(manager, defender_id)
    if not atk_c.is_empty() and _get_entity_access().is_yielded(atk_c):
        return "yield"
    if not def_c.is_empty() and _get_entity_access().is_yielded(def_c):
        return "yield"
    if (
        not atk_c.is_empty()
        and (
            bool(atk_c.get("combat_absent", false))
            or _get_entity_access().state_str(atk_c) == _get_combat_constants().STATE_FLED
        )
    ):
        return "flee"
    if (
        not def_c.is_empty()
        and (
            bool(def_c.get("combat_absent", false))
            or _get_entity_access().state_str(def_c) == _get_combat_constants().STATE_FLED
        )
    ):
        return "flee"
    if not atk_c.is_empty() and not _get_entity_access().alive_bool(atk_c):
        return "kill"
    if not def_c.is_empty() and not _get_entity_access().alive_bool(def_c):
        return "kill"
    if not atk_c.is_empty() and _get_entity_access().is_incapacitated(atk_c):
        return "incapacitate"
    if not def_c.is_empty() and _get_entity_access().is_incapacitated(def_c):
        return "incapacitate"
    if winner_side.is_empty():
        return "draw"
    return "standing"


func _cleanup_manager() -> void:
    if manager != null and is_instance_valid(manager):
        # Disconnect signals
        if manager.is_connected("turn_ready", Callable(self, "_on_turn_ready")):
            manager.disconnect("turn_ready", Callable(self, "_on_turn_ready"))
        if manager.is_connected("action_resolved", Callable(self, "_on_action_resolved")):
            manager.disconnect("action_resolved", Callable(self, "_on_action_resolved"))
        if manager.is_connected("combat_ended", Callable(self, "_on_combat_ended")):
            manager.disconnect("combat_ended", Callable(self, "_on_combat_ended"))
        if manager.is_connected("enemies_eliminated", Callable(self, "_on_enemies_eliminated")):
            manager.disconnect("enemies_eliminated", Callable(self, "_on_enemies_eliminated"))
        if manager.is_connected("combatant_health_changed", Callable(self, "_on_combatant_health_changed")):
            manager.disconnect("combatant_health_changed", Callable(self, "_on_combatant_health_changed"))
        if manager.is_connected("formation_changed", Callable(self, "_on_formation_changed")):
            manager.disconnect("formation_changed", Callable(self, "_on_formation_changed"))
        if manager.is_connected("engagement_state_changed", Callable(self, "_on_engagement_state_changed")):
            manager.disconnect("engagement_state_changed", Callable(self, "_on_engagement_state_changed"))
        if manager.is_connected("combat_ui_hint", Callable(self, "_on_combat_ui_hint")):
            manager.disconnect("combat_ui_hint", Callable(self, "_on_combat_ui_hint"))
        manager.queue_free()
        manager = null
    attacker_entity = null
    defender_entity = null
    attacker_id = -1
    defender_id = -1
    _strike_count = 0


func _populate_move_dropdown() -> void:
    _move_option.clear()
    var atk_c: Dictionary = _get_entity_access().manager_get_combatant(manager, attacker_id)
    if atk_c.is_empty():
        _move_option.add_item("oberhau")
        return

    var weapon: Variant = _get_entity_access().get_weapon(atk_c)
    if weapon == null:
        _move_option.add_item("oberhau")
        return

    var moves: Array = weapon.get_available_attack_types()
    if moves.is_empty():
        moves = ["oberhau"]

    for m in moves:
        _move_option.add_item(str(m))

    var idx: int = -1
    for i in range(moves.size()):
        if str(moves[i]) == _current_move_id:
            idx = i
            break
    if idx >= 0:
        _move_option.select(idx)
    else:
        _move_option.select(0)
        _current_move_id = str(moves[0])


func _set_tuning_override(combatant_id: int, target_id: int) -> void:
    _tuning_override[combatant_id] = {
        "move_id": _current_move_id,
        "target_id": target_id,
        "intensity": _current_intensity,
    }
    _override_pending = true

    # Expedite this combatant's next turn by rescheduling
    # Cancel any existing action_ready and schedule one soon
    if manager != null and is_instance_valid(manager):
        _EventScheduler.cancel_pending_action_ready(manager, combatant_id)
        _EventScheduler.schedule_action_ready(manager, combatant_id, 0.05)
        # Kick the process tick if it was held waiting for player
        manager.set_process(true)


func _show_end_battle_button(button_text: String = "End battle", button_min_width: int = 160) -> void:
    if _auto_enabled or _batch_running:
        return
    # In manual mode, show an end-battle button in the tuning overlay
    if _tuning_main_vbox == null:
        return
    for c in _tuning_main_vbox.get_children():
        if c is Button and c.name == "TuningEndBattleButton":
            return
    var btn := Button.new()
    btn.name = "TuningEndBattleButton"
    btn.text = button_text
    btn.custom_minimum_size = Vector2(button_min_width, 44)
    btn.pressed.connect(_on_tuning_end_battle)
    _tuning_main_vbox.add_child(btn)


func _on_tuning_end_battle():
    if manager == null or not is_instance_valid(manager):
        _spawn_combatants()
        return
    if manager.medical_phase:
        manager.set_process(false)
        if manager.has_method("finish_battle_interactive"):
            await manager.finish_battle_interactive()
        elif manager.has_method("finish_battle"):
            manager.finish_battle()
    _spawn_combatants()


# ============================================================
#  Batch fast-forward combat runner
# ============================================================


func _batch_run_cycle_to_completion():
    ## Drive combat from the current state to resolution without waiting real-time.
    ## Pumps event queue and process ticks in tight loops, yielding occasionally
    ## for UI responsiveness but advancing many logical seconds per yield.
    var eac := _get_entity_access()

    var max_cycles: int = 5000
    var logical_seconds: float = 0.0
    var tick_delta: float = 0.1
    var events_per_burst: int = 20

    for _cycle in range(max_cycles):
        if manager == null or not is_instance_valid(manager):
            return
        if "combat_resolution_closed" in manager and manager.combat_resolution_closed:
            break

        var atk_c = eac.manager_get_combatant(manager, attacker_id)
        var def_c = eac.manager_get_combatant(manager, defender_id)
        if atk_c.is_empty() or def_c.is_empty():
            break
        if not eac.alive_bool(atk_c) or not eac.alive_bool(def_c):
            break

        for _b in range(events_per_burst):
            if manager == null or not is_instance_valid(manager):
                return
            _EventDispatch.process_event_queue(manager)
            _ProcessTick.tick(manager, tick_delta)
            logical_seconds += tick_delta

            if "combat_resolution_closed" in manager and manager.combat_resolution_closed:
                break
            if not manager.medical_phase:
                var early_victor := ""
                if manager.has_method("_check_for_winner"):
                    early_victor = manager._check_for_winner()
                if not early_victor.is_empty():
                    var _MedicalPhase = preload("res://combat/medical/MedicalPhaseController.gd")
                    if _MedicalPhase.should_apply_phase_end(manager, early_victor):
                        manager._end_combat_phase(early_victor, null)
                        break

        if logical_seconds >= 2.0:
            await get_tree().process_frame
            logical_seconds = 0.0


# ============================================================
#  Logging — plain text for copy/paste + optional UI color
# ============================================================


func _log_line_should_mirror(plain: String) -> bool:
    if plain.is_empty():
        return false
    var first: String = plain.split("\n", false)[0]
    for prefix in ["[HEMA]", "[Matchup]", "[Fight end]", "[Tuning]", "--- Cycle", "[Batch]", "=== BATCH"]:
        if first.begins_with(prefix):
            return true
    return false


func _log_line(plain: String, color: String = "", mirror: bool = true) -> void:
    plain = plain.strip_edges()
    if plain.is_empty():
        return
    for line in plain.split("\n", false):
        if not line.is_empty():
            _plain_log.append(line)
    if _log_rtl != null:
        var display := plain
        if not color.is_empty():
            if "\n" in plain:
                var colored := PackedStringArray()
                for line in plain.split("\n", false):
                    colored.append("[color=%s]%s[/color]" % [color, line])
                display = "\n".join(colored)
            else:
                display = "[color=%s]%s[/color]" % [color, plain]
        if _log_rtl.text.is_empty():
            _log_rtl.append_text(display)
        else:
            _log_rtl.append_text("\n" + display)
        var sc: ScrollContainer = _log_rtl.get_parent() as ScrollContainer
        if sc != null:
            var vbar = sc.get_v_scroll_bar()
            if vbar:
                sc.scroll_vertical = int(vbar.max_value)
    if mirror and _log_line_should_mirror(plain):
        print(plain)


func _append_log(text: String, store_plain: bool = true) -> void:
    if store_plain:
        var plain := _Formatter.strip_bbcode(text)
        for line in plain.split("\n", false):
            if not line.is_empty():
                _plain_log.append(line)
    if _log_rtl == null:
        return
    if _log_rtl.text.is_empty():
        _log_rtl.append_text(text)
    else:
        _log_rtl.append_text("\n" + text)
    var sc: ScrollContainer = _log_rtl.get_parent() as ScrollContainer
    if sc != null:
        var vbar = sc.get_v_scroll_bar()
        if vbar:
            sc.scroll_vertical = int(vbar.max_value)


func _copy_plain_log() -> void:
    if _plain_log.is_empty():
        return
    DisplayServer.clipboard_set("\n".join(_plain_log))


func _clear_plain_log() -> void:
    _plain_log.clear()
    if _log_rtl != null:
        _log_rtl.clear()


# ============================================================
#  Display Refresh
# ============================================================


func _refresh_display() -> void:
    _refresh_tuning_display()


func _refresh_tuning_display() -> void:
    _refresh_entity_display(attacker_entity, _attacker_health_labels, _attacker_state_label, true)
    if _attacker_fg_line != null:
        var atk_c = _get_entity_access().manager_get_combatant(manager, attacker_id) if manager != null else {}
        _attacker_fg_line.text = (
            "Form: %s  Guard: %s"
            % [
                _get_entity_access().form_str(atk_c) if not atk_c.is_empty() else "?",
                atk_c.get("guard_line", "?") if not atk_c.is_empty() else "?"
            ]
        )
    _refresh_entity_display(defender_entity, _defender_health_labels, _defender_state_label, false)
    if _defender_fg_line != null:
        var def_c = _get_entity_access().manager_get_combatant(manager, defender_id) if manager != null else {}
        _defender_fg_line.text = (
            "Form: %s  Guard: %s"
            % [
                _get_entity_access().form_str(def_c) if not def_c.is_empty() else "?",
                def_c.get("guard_line", "?") if not def_c.is_empty() else "?"
            ]
        )


func _refresh_meter_display() -> void:
    _refresh_tuning_display()


func _refresh_entity_display(entity: Node, health_labels: Dictionary, state_label: Label, _is_atk: bool) -> void:
    if entity == null or not is_instance_valid(entity):
        if state_label != null:
            state_label.text = "State: (no entity)"
        return
    entity.ensure_consciousness_current()

    for part in _ConfigData.BODY_PARTS:
        var hl: Label = health_labels.get(part) as Label
        if hl == null:
            continue
        var cut: float = entity.body_cutting.get(part, 0.0)
        var blunt: float = entity.body_blunt.get(part, 0.0)
        var max_single: float = entity.body_max.get(part, 1.0)
        var hp: float = cut + blunt
        var max_hp: float = max_single * 2.0
        var hp_ratio: float = hp / max_hp if max_hp > 0.0 else 0.0
        hl.text = "  %s: %.1f/%.1f" % [part, hp, max_hp]
        hl.add_theme_color_override("font_color", _health_color(hp_ratio))

    var blood_label: Label = health_labels.get("_blood") as Label
    if blood_label != null:
        blood_label.text = "Blood: %.1f" % entity.blood_volume

    var con_label: Label = health_labels.get("_con") as Label
    if con_label != null:
        con_label.text = "Con: %.2f" % entity.consciousness

    var cid_st: int = attacker_id if entity == attacker_entity else (defender_id if entity == defender_entity else -1)
    var stamina_s: String = "Stamina: --"
    var gauge_s: String = "Gauge: --"
    if cid_st >= 0 and manager != null:
        var c_st: Dictionary = _get_entity_access().manager_get_combatant(manager, cid_st)
        if not c_st.is_empty():
            stamina_s = "Stamina: %.1f" % c_st.get("stamina", 0.0)
            gauge_s = "Gauge: %.1f" % c_st.get("gauge", 0.0)

    var stamina_label: Label = health_labels.get("_stamina") as Label
    if stamina_label != null:
        stamina_label.text = stamina_s

    var gauge_label: Label = health_labels.get("_gauge") as Label
    if gauge_label != null:
        gauge_label.text = gauge_s

    var alive_label: Label = health_labels.get("_alive") as Label
    if alive_label != null:
        var cid2: int = attacker_id if entity == attacker_entity else (defender_id if entity == defender_entity else -1)
        if cid2 >= 0:
            var c2: Dictionary = _get_entity_access().manager_get_combatant(manager, cid2)
            alive_label.text = (
                "Alive: %s" % ("Yes" if not c2.is_empty() and _get_entity_access().alive_bool(c2) else "NO")
            )
            alive_label.add_theme_color_override(
                "font_color",
                (
                    Color(0.5, 1.0, 0.5)
                    if not c2.is_empty() and _get_entity_access().alive_bool(c2)
                    else Color(1.0, 0.3, 0.3)
                )
            )

    if state_label == null:
        return

    var cid: int = attacker_id if entity == attacker_entity else (defender_id if entity == defender_entity else -1)
    if cid < 0:
        state_label.text = "State: (no entity)"
        return
    var c: Dictionary = _get_entity_access().manager_get_combatant(manager, cid)
    if c.is_empty():
        state_label.text = "State: (not in combat)"
        return
    state_label.text = "State: %s" % c.get("state", "?")


static func _health_color(ratio: float) -> String:
    if ratio > 0.7:
        return "#88ff88"
    elif ratio > 0.4:
        return "#ffff88"
    elif ratio > 0.15:
        return "#ffaa44"
    return "#ff4444"


# ============================================================
#  Cycle Summary
# ============================================================


## Returns "attacker", "defender", "mutual", or "" when unresolved.
func _resolve_tuning_matchup_winner(atk_c: Dictionary, def_c: Dictionary) -> String:
    var atk_alive: bool = not atk_c.is_empty() and _get_entity_access().alive_bool(atk_c)
    var def_alive: bool = not def_c.is_empty() and _get_entity_access().alive_bool(def_c)
    if not atk_alive and def_alive:
        return "defender"
    if not def_alive and atk_alive:
        return "attacker"
    if not atk_alive and not def_alive:
        return "mutual"
    var mw: String = manager.medical_phase_winner if manager != null and "medical_phase_winner" in manager else ""
    if mw == "enemy":
        return "defender"
    if mw == "player":
        return "attacker"
    if manager != null and "combat_resolution_closed" in manager and manager.combat_resolution_closed:
        var atk_incap: bool = not atk_c.is_empty() and _get_entity_access().is_incapacitated(atk_c)
        var def_incap: bool = not def_c.is_empty() and _get_entity_access().is_incapacitated(def_c)
        if atk_incap and not def_incap:
            return "defender"
        if def_incap and not atk_incap:
            return "attacker"
    return ""


func _log_cycle_summary() -> void:
    _cycle_count += 1
    var strikes_this_cycle: int = _strike_count - _cycle_start_strikes
    _cycle_total_strikes += strikes_this_cycle

    var atk_c = _get_entity_access().manager_get_combatant(manager, attacker_id) if manager != null else {}
    var def_c = _get_entity_access().manager_get_combatant(manager, defender_id) if manager != null else {}

    var winner_side: String = _resolve_tuning_matchup_winner(atk_c, def_c)
    var winner_name: String = "?"
    match winner_side:
        "defender":
            winner_name = defender_config.display_name
            _cycle_defender_wins += 1
        "attacker":
            winner_name = attacker_config.display_name
            _cycle_attacker_wins += 1
        "mutual":
            winner_name = "mutual"
        _:
            winner_name = "draw"

    var win_rate_atk: float = float(_cycle_attacker_wins) / float(maxf(_cycle_count, 1)) * 100.0
    var avg_strikes: float = float(_cycle_total_strikes) / float(maxf(_cycle_count, 1))

    var end_cause: String = (
        _last_end_cause
        if not _last_end_cause.is_empty()
        else _infer_end_cause(
            (
                "player"
                if winner_name == attacker_config.display_name
                else ("enemy" if winner_name == defender_config.display_name else "")
            )
        )
    )
    var aggregate_line: String = (
        "Aggregate: %s %d  %s %d  cycles=%d  avg_strikes=%.1f  atk_win_rate=%.0f%%"
        % [
            attacker_config.display_name,
            _cycle_attacker_wins,
            defender_config.display_name,
            _cycle_defender_wins,
            _cycle_count,
            avg_strikes,
            win_rate_atk
        ]
    )
    var summary: String = _Formatter.format_cycle_hema_summary(
        _cycle_count,
        winner_name,
        end_cause,
        strikes_this_cycle,
        _cycle_outcome_counts,
        _cycle_ke_samples,
        _cycle_attacker_dmg_dealt,
        _cycle_defender_dmg_dealt,
        aggregate_line,
        _active_scenario_key,
        attacker_config,
        defender_config
    )
    _log_line(summary, "#88ccff")

    _cycle_attacker_dmg_dealt = 0.0
    _cycle_defender_dmg_dealt = 0.0
    _reset_cycle_exchange_stats()

    var status_parts := PackedStringArray()
    status_parts.append("Cycle %d: %s" % [_cycle_count, winner_name])
    status_parts.append("%s: %d wins" % [attacker_config.display_name, _cycle_attacker_wins])
    status_parts.append("%s: %d wins" % [defender_config.display_name, _cycle_defender_wins])
    status_parts.append("avg %.1f strikes" % avg_strikes)
    if _status_bar != null:
        _status_bar.text = "  |  ".join(status_parts)


func _log_batch_cycle_summary(
    cycle_index: int,
    total_cycles: int,
    atk_cfg_snap: Variant,
    def_cfg_snap: Variant,
    scenario_key_snap: String,
    start_strikes: int
) -> void:
    var strikes_this_cycle: int = _strike_count - start_strikes
    var atk_c = _get_entity_access().manager_get_combatant(manager, attacker_id) if manager != null else {}
    var def_c = _get_entity_access().manager_get_combatant(manager, defender_id) if manager != null else {}
    var winner_side: String = _resolve_tuning_matchup_winner(atk_c, def_c)
    var winner_name: String = "draw"
    var batch_atk_wins: int = 0
    var batch_def_wins: int = 0
    match winner_side:
        "defender":
            winner_name = def_cfg_snap.display_name
            batch_def_wins = 1
        "attacker":
            winner_name = atk_cfg_snap.display_name
            batch_atk_wins = 1
        "mutual":
            winner_name = "mutual"
    var end_cause: String = (
        _last_end_cause
        if not _last_end_cause.is_empty()
        else _infer_end_cause("player" if winner_side == "attacker" else ("enemy" if winner_side == "defender" else ""))
    )
    var aggregate_line: String = (
        "Batch cycle %d/%d: %s %d - %s %d (%.0f%% atk win)"
        % [
            cycle_index,
            total_cycles,
            atk_cfg_snap.display_name,
            batch_atk_wins,
            def_cfg_snap.display_name,
            batch_def_wins,
            float(batch_atk_wins) * 100.0,
        ]
    )
    var summary: String = _Formatter.format_cycle_hema_summary(
        cycle_index,
        winner_name,
        end_cause,
        strikes_this_cycle,
        _cycle_outcome_counts.duplicate(),
        _cycle_ke_samples.duplicate(true),
        _cycle_attacker_dmg_dealt,
        _cycle_defender_dmg_dealt,
        aggregate_line,
        scenario_key_snap,
        atk_cfg_snap,
        def_cfg_snap
    )
    _log_line(summary, "#88ccff")
    _cycle_attacker_dmg_dealt = 0.0
    _cycle_defender_dmg_dealt = 0.0
    _last_end_cause = ""
    _reset_cycle_exchange_stats()


# ============================================================
#  Signal Handlers
# ============================================================


func _on_strike_pressed() -> void:
    if manager == null or attacker_id < 0 or defender_id < 0:
        return
    _auto_enabled = false
    _set_tuning_override(attacker_id, defender_id)
    _append_log(
        (
            "[color=#ffcc88]Override set: %s -> %s (%s, int=%.2f)[/color]"
            % [attacker_config.display_name, defender_config.display_name, _current_move_id, _current_intensity]
        )
    )


func _on_exchange_pressed() -> void:
    if manager == null or attacker_id < 0 or defender_id < 0:
        return
    _auto_enabled = false
    # Set override for attacker first, then for defender after it resolves
    _set_tuning_override(attacker_id, defender_id)
    _append_log(
        (
            "[color=#ffcc88]Override set: %s->%s (%s)[/color]"
            % [attacker_config.display_name, defender_config.display_name, _current_move_id]
        )
    )
    # Schedule defender override after a short delay
    get_tree().create_timer(0.5).timeout.connect(
        func():
            if manager == null or not is_instance_valid(manager):
                return
            if _any_dead():
                return
            _set_tuning_override(defender_id, attacker_id)
            _append_log(
                (
                    "[color=#ffcc88]Override set: %s->%s (%s)[/color]"
                    % [defender_config.display_name, attacker_config.display_name, _current_move_id]
                )
            )
    )


func _on_reset_pressed() -> void:
    _auto_enabled = false
    _spawn_combatants()
    _append_log("[color=#8888ff]Reset: fresh combatants spawned (waiting for action).[/color]")


func _on_randomize_pressed() -> void:
    _apply_random_matchup_configs()
    _spawn_combatants()
    var atk_species := "Human" if attacker_config.species_tres_path.contains("human") else "Goblin"
    var def_species := "Human" if defender_config.species_tres_path.contains("human") else "Goblin"
    _append_log(
        (
            "[color=#ff88ff]Randomized: %s (%s/%s) vs %s (%s/%s)"
            % [
                attacker_config.display_name,
                atk_species,
                attacker_config.weapon_id,
                defender_config.display_name,
                def_species,
                defender_config.weapon_id
            ]
        )
    )
    if _status_bar != null:
        _status_bar.text = "Randomized"


func _on_batch_pressed() -> void:
    _reset_combat_for_batch()
    _append_log("[color=#8888ff]Batch: combat cleared.[/color]")
    _open_batch_window()


func _on_scenario_pressed() -> void:
    _open_presets_window()


func _on_move_selected(idx: int) -> void:
    _current_move_id = _move_option.get_item_text(idx)


func _on_intensity_changed(value: float) -> void:
    _current_intensity = value
    if _intensity_label != null:
        _intensity_label.text = "%.2f" % value


func _toggle_auto() -> void:
    _auto_enabled = not _auto_enabled
    _auto_waiting_for_death = false
    _update_auto_buttons()
    # Kick process tick if combat was held waiting for player
    if manager != null and is_instance_valid(manager):
        manager.set_process(true)
    _append_log(
        (
            "[color=%s]Auto-combat %s.[/color]"
            % ["#88ff88" if _auto_enabled else "#ff8888", "enabled" if _auto_enabled else "disabled"]
        )
    )


func _update_auto_buttons() -> void:
    for child in get_children():
        if child is MarginContainer:
            continue
        if child is CanvasLayer and child.name == "TuningOverlayLayer":
            _for_each_button_in(
                child,
                func(btn):
                    if btn.text.begins_with("Auto:"):
                        btn.text = "Auto: %s" % ("ON" if _auto_enabled else "OFF")
            )


func _for_each_button_in(node: Node, callback: Callable) -> void:
    for child in node.get_children():
        if child is Button:
            callback.call(child)
        _for_each_button_in(child, callback)


# ============================================================
#  Presets Window
# ============================================================

var _presets_window: Window = null


func _open_presets_window() -> void:
    if _presets_window != null and is_instance_valid(_presets_window):
        _presets_window.grab_focus()
        return

    _auto_enabled = false

    _presets_window = Window.new()
    _presets_window.title = "Load Scenario Preset"
    _presets_window.min_size = Vector2i(460, 420)
    _presets_window.close_requested.connect(_close_presets_window)
    add_child(_presets_window)

    var vbox := VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 8)
    _presets_window.add_child(vbox)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    vbox.add_child(margin)

    var inner_vbox := VBoxContainer.new()
    inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_child(inner_vbox)

    var desc := Label.new()
    desc.text = "Choose a preset scenario for both combatants:"
    inner_vbox.add_child(desc)

    var option_btn := OptionButton.new()
    option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var item_keys: Array[String] = _populate_scenario_option_button(option_btn)
    inner_vbox.add_child(option_btn)

    var preview := Label.new()
    preview.text = _scenario_description_for_key(item_keys[0] if not item_keys.is_empty() else "Random")
    preview.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inner_vbox.add_child(preview)

    option_btn.item_selected.connect(
        func(idx: int):
            if idx >= 0 and idx < item_keys.size():
                preview.text = _scenario_description_for_key(item_keys[idx])
    )

    var btn_row := HBoxContainer.new()
    inner_vbox.add_child(btn_row)

    var apply_btn := Button.new()
    apply_btn.text = "Apply Preset"
    apply_btn.pressed.connect(
        func():
            var idx := option_btn.selected
            if idx < 0 or idx >= item_keys.size():
                return
            var skey: String = item_keys[idx]
            if skey.is_empty():
                return
            _active_scenario_key = skey
            var configs: Array = _load_scenario(skey)
            if configs.size() >= 2:
                attacker_config = configs[0]
                defender_config = configs[1]
                if _attacker_header_label != null:
                    _attacker_header_label.text = attacker_config.display_name
                if _defender_header_label != null:
                    _defender_header_label.text = defender_config.display_name
                _spawn_combatants()
                _append_log("[color=#ff88ff]Preset '%s' loaded.[/color]" % skey)
            _close_presets_window()
    )
    btn_row.add_child(apply_btn)

    var cancel_btn := Button.new()
    cancel_btn.text = "Cancel"
    cancel_btn.pressed.connect(_close_presets_window)
    btn_row.add_child(cancel_btn)

    _presets_window.popup_centered()


func _close_presets_window() -> void:
    if _presets_window != null and is_instance_valid(_presets_window):
        _presets_window.queue_free()
    _presets_window = null


func _load_scenario(key: String) -> Array:
    return _Config.configs_for_scenario(key)


func _scenario_description_for_key(key: String) -> String:
    for entry in _Config.scenario_menu_entries():
        if not entry.get("separator", false) and str(entry.get("key", "")) == key:
            return str(entry.get("description", key))
    return key


func _populate_scenario_option_button(option_btn: OptionButton) -> Array[String]:
    var item_keys: Array[String] = []
    for entry in _Config.scenario_menu_entries():
        var label: String = str(entry.get("label", ""))
        option_btn.add_item(label)
        var item_idx: int = option_btn.item_count - 1
        if entry.get("separator", false):
            option_btn.set_item_disabled(item_idx, true)
            item_keys.append("")
        else:
            item_keys.append(str(entry.get("key", "")))
    return item_keys


func _reset_combat_for_batch() -> void:
    _auto_enabled = false
    _auto_waiting_for_death = false
    _auto_respawn_delay = 0.0
    _in_medical_phase = false
    _cleanup_manager()
    _reset_cycle_exchange_stats()
    _cycle_attacker_dmg_dealt = 0.0
    _cycle_defender_dmg_dealt = 0.0
    _refresh_display()


func _populate_batch_scenario_option_button(option_btn: OptionButton) -> Array[String]:
    var item_keys: Array[String] = ["__WEAPON_SWEEP__", "__BALANCE_MATRIX__"]
    option_btn.add_item("Weapon sweep (each weapon, random 1v1)")
    option_btn.add_item("Balance Matrix (all calibration scenarios)")
    for key in _Config.balance_matrix_keys():
        option_btn.add_item(key)
        item_keys.append(key)
    return item_keys


# ============================================================
#  Batch Runner
# ============================================================

var _batch_window: Window = null


func _open_batch_window() -> void:
    if _batch_window != null and is_instance_valid(_batch_window):
        _batch_window.grab_focus()
        return

    _auto_enabled = false

    _batch_window = Window.new()
    _batch_window.title = "Batch Runner"
    _batch_window.min_size = Vector2i(440, 540)
    _batch_window.close_requested.connect(_close_batch_window)
    add_child(_batch_window)

    var vbox := VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 8)
    _batch_window.add_child(vbox)

    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    vbox.add_child(margin)

    var inner_vbox := VBoxContainer.new()
    inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inner_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(inner_vbox)

    var scenario_label := Label.new()
    scenario_label.text = "Scenario:"
    inner_vbox.add_child(scenario_label)

    var scenario_opt := OptionButton.new()
    scenario_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var batch_item_keys: Array[String] = _populate_batch_scenario_option_button(scenario_opt)
    inner_vbox.add_child(scenario_opt)

    var cycle_row := HBoxContainer.new()
    cycle_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inner_vbox.add_child(cycle_row)

    var cycle_label := Label.new()
    cycle_label.text = "Cycles:"
    cycle_row.add_child(cycle_label)

    var cycle_spin := SpinBox.new()
    cycle_spin.min_value = 1
    cycle_spin.max_value = 10000
    cycle_spin.value = 3
    cycle_spin.step = 1
    cycle_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cycle_row.add_child(cycle_spin)

    var csv_toggle := CheckBox.new()
    csv_toggle.text = "Write per-strike CSV to stdout"
    csv_toggle.button_pressed = true
    inner_vbox.add_child(csv_toggle)

    var progress_bar := ProgressBar.new()
    progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_bar.value = 0
    inner_vbox.add_child(progress_bar)

    var status_label := Label.new()
    status_label.text = "Ready"
    status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    inner_vbox.add_child(status_label)

    var result_label := Label.new()
    result_label.name = "batch_result"
    result_label.text = ""
    result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inner_vbox.add_child(result_label)

    var btn_row := HBoxContainer.new()
    inner_vbox.add_child(btn_row)

    var run_btn := Button.new()
    run_btn.text = "Run Batch"
    btn_row.add_child(run_btn)

    var cancel_btn := Button.new()
    cancel_btn.text = "Abort"
    cancel_btn.disabled = true
    btn_row.add_child(cancel_btn)

    var close_btn := Button.new()
    close_btn.text = "Close"
    close_btn.pressed.connect(_close_batch_window)
    btn_row.add_child(close_btn)

    run_btn.pressed.connect(
        func():
            if _batch_running:
                return
            _batch_running = true
            _batch_abort = false
            run_btn.disabled = true
            cancel_btn.disabled = false
            close_btn.disabled = true
            _auto_enabled = false
            var n_cycles: int = int(cycle_spin.value)
            var csv_enabled: bool = csv_toggle.button_pressed
            var s_idx := scenario_opt.selected
            var s_key: String = (
                batch_item_keys[s_idx] if s_idx >= 0 and s_idx < batch_item_keys.size() else "HEMA Sword Duel"
            )
            _reset_combat_for_batch()
            if s_key == "__WEAPON_SWEEP__":
                _run_weapon_sweep_batch(
                    n_cycles, csv_enabled, run_btn, cancel_btn, close_btn, progress_bar, status_label, result_label
                )
            elif s_key == "__BALANCE_MATRIX__":
                _run_balance_matrix_batch(
                    n_cycles, csv_enabled, run_btn, cancel_btn, close_btn, progress_bar, status_label, result_label
                )
            else:
                _run_batch(
                    s_key,
                    n_cycles,
                    csv_enabled,
                    run_btn,
                    cancel_btn,
                    close_btn,
                    progress_bar,
                    status_label,
                    result_label
                )
    )

    cancel_btn.pressed.connect(func(): _batch_abort = true)

    _batch_window.popup_centered(Vector2i(440, 540))


var _batch_running: bool = false
var _batch_abort: bool = false
var _batch_csv_lines: PackedStringArray = []
var _batch_strike_idx: int = 0


func _close_batch_window() -> void:
    _batch_running = false
    _batch_abort = true
    if _batch_window != null and is_instance_valid(_batch_window):
        _batch_window.queue_free()
    _batch_window = null


func _run_balance_matrix_batch(
    num_cycles_per_scenario: int,
    csv_enabled: bool,
    run_btn: Button,
    cancel_btn: Button,
    close_btn: Button,
    progress_bar: ProgressBar,
    status_label: Label,
    result_label: Label
):
    var matrix_keys: Array[String] = _Config.balance_matrix_keys()
    var matrix_lines := PackedStringArray()
    matrix_lines.append(
        "=== Balance Matrix (%d scenarios x %d cycles) ===" % [matrix_keys.size(), num_cycles_per_scenario]
    )
    for i in matrix_keys.size():
        if _batch_abort:
            break
        var skey: String = matrix_keys[i]
        if is_instance_valid(status_label):
            status_label.text = "Matrix %d/%d: %s" % [i + 1, matrix_keys.size(), skey]
        if is_instance_valid(progress_bar):
            progress_bar.value = float(i) / float(maxf(matrix_keys.size(), 1)) * 100.0
        await _run_batch(
            skey,
            num_cycles_per_scenario,
            csv_enabled,
            run_btn,
            cancel_btn,
            close_btn,
            progress_bar,
            status_label,
            result_label,
            false
        )
        if is_instance_valid(result_label):
            matrix_lines.append(result_label.text.strip_edges())
        await get_tree().process_frame
    if is_instance_valid(progress_bar):
        progress_bar.value = 100.0
    if is_instance_valid(result_label):
        result_label.text = "\n\n".join(matrix_lines)
    if is_instance_valid(status_label):
        status_label.text = "Balance matrix complete"
    _batch_running = false
    if is_instance_valid(run_btn):
        run_btn.disabled = false
    if is_instance_valid(cancel_btn):
        cancel_btn.disabled = true
    if is_instance_valid(close_btn):
        close_btn.disabled = false
    _auto_enabled = true
    _log_line("[Balance Matrix] %d scenarios complete" % matrix_keys.size(), "#88ff88")


func _run_weapon_sweep_batch(
    num_cycles_per_weapon: int,
    csv_enabled: bool,
    run_btn: Button,
    cancel_btn: Button,
    close_btn: Button,
    progress_bar: ProgressBar,
    status_label: Label,
    result_label: Label
):
    var sweep_keys: Array[String] = _Config.weapon_sweep_keys()
    var sweep_lines := PackedStringArray()
    sweep_lines.append(
        "=== Weapon sweep (%d weapons x %d cycles, random matchup) ===" % [sweep_keys.size(), num_cycles_per_weapon]
    )
    for i in sweep_keys.size():
        if _batch_abort:
            break
        var skey: String = sweep_keys[i]
        var wid: String = _Config.weapon_id_from_sweep_key(skey)
        if is_instance_valid(status_label):
            status_label.text = "Weapon %d/%d: %s" % [i + 1, sweep_keys.size(), wid]
        if is_instance_valid(progress_bar):
            progress_bar.value = float(i) / float(maxf(sweep_keys.size(), 1)) * 100.0
        _log_line(
            "[Weapon sweep] starting %s (%d cycles, random stats/resources/armor/species)" % [wid, num_cycles_per_weapon],
            "#aaccff"
        )
        await _run_batch(
            skey,
            num_cycles_per_weapon,
            csv_enabled,
            run_btn,
            cancel_btn,
            close_btn,
            progress_bar,
            status_label,
            result_label,
            false
        )
        if is_instance_valid(result_label):
            sweep_lines.append("--- %s ---\n%s" % [wid, result_label.text.strip_edges()])
        await get_tree().process_frame
    if is_instance_valid(progress_bar):
        progress_bar.value = 100.0
    if is_instance_valid(result_label):
        result_label.text = "\n\n".join(sweep_lines)
    if is_instance_valid(status_label):
        status_label.text = "Weapon sweep complete"
    _batch_running = false
    if is_instance_valid(run_btn):
        run_btn.disabled = false
    if is_instance_valid(cancel_btn):
        cancel_btn.disabled = true
    if is_instance_valid(close_btn):
        close_btn.disabled = false
    _auto_enabled = true
    _log_line("[Weapon sweep] %d weapon types complete" % sweep_keys.size(), "#88ff88")


func _run_batch(
    scenario_key: String,
    num_cycles: int,
    csv_enabled: bool,
    run_btn: Button,
    cancel_btn: Button,
    close_btn: Button,
    progress_bar: ProgressBar,
    status_label: Label,
    result_label: Label,
    reset_batch_ui: bool = true
):
    _batch_csv_lines.clear()
    _batch_strike_idx = 0

    var configs: Array = _load_scenario(scenario_key)
    if configs.size() < 2:
        if is_instance_valid(status_label):
            status_label.text = "ERROR: invalid scenario config"
        _batch_running = false
        if reset_batch_ui:
            if is_instance_valid(run_btn):
                run_btn.disabled = false
            if is_instance_valid(cancel_btn):
                cancel_btn.disabled = true
            if is_instance_valid(close_btn):
                close_btn.disabled = false
        return

    var atk_cfg = configs[0]
    var def_cfg = configs[1]
    _active_scenario_key = scenario_key
    attacker_config = atk_cfg
    defender_config = def_cfg
    if _attacker_header_label != null:
        _attacker_header_label.text = atk_cfg.display_name
    if _defender_header_label != null:
        _defender_header_label.text = def_cfg.display_name

    _auto_enabled = false

    var b_total_cycles: int = 0
    var b_atk_wins: int = 0
    var b_def_wins: int = 0
    var b_total_strikes: int = 0
    var b_atk_dmg: float = 0.0
    var b_def_dmg: float = 0.0

    if csv_enabled:
        _batch_csv_lines.append(_Formatter.csv_header())

    var cycle: int = 0
    var sweep_weapon: String = _Config.weapon_id_from_sweep_key(scenario_key)
    while cycle < num_cycles and not _batch_abort:
        if scenario_key == "Random":
            _apply_random_matchup_configs()
            atk_cfg = attacker_config
            def_cfg = defender_config
        elif not sweep_weapon.is_empty():
            var sweep_pair: Array = _Config.weapon_sweep_configs(sweep_weapon)
            atk_cfg = sweep_pair[0]
            def_cfg = sweep_pair[1]
            attacker_config = atk_cfg
            defender_config = def_cfg
            if _attacker_header_label != null:
                _attacker_header_label.text = atk_cfg.display_name
            if _defender_header_label != null:
                _defender_header_label.text = def_cfg.display_name
        _current_intensity = randf_range(0.4, 0.9)

        var cycle_atk_cfg = atk_cfg
        var cycle_def_cfg = def_cfg
        _spawn_combatants()
        for _i in range(3):
            await get_tree().process_frame
        if not is_instance_valid(manager):
            break

        var start_strikes: int = _strike_count

        # Fast-forward the AI-driven battle to completion (no real-time waiting)
        _batch_run_cycle_to_completion()

        if _batch_abort:
            break

        if manager == null or not is_instance_valid(manager):
            break

        # Determine winner
        var atk_c2 = _get_entity_access().manager_get_combatant(manager, attacker_id) if manager != null else {}
        var def_c2 = _get_entity_access().manager_get_combatant(manager, defender_id) if manager != null else {}
        match _resolve_tuning_matchup_winner(atk_c2, def_c2):
            "defender":
                b_def_wins += 1
            "attacker":
                b_atk_wins += 1

        var strikes_this: int = _strike_count - start_strikes
        b_total_strikes += strikes_this
        # Damage tracking via signal is not polled in batch; use aggregate from cycle summary
        b_atk_dmg += _cycle_attacker_dmg_dealt
        b_def_dmg += _cycle_defender_dmg_dealt
        b_total_cycles += 1

        _log_batch_cycle_summary(cycle + 1, num_cycles, cycle_atk_cfg, cycle_def_cfg, scenario_key, start_strikes)

        cycle += 1

        if cycle % 10 == 0 or cycle == num_cycles:
            if is_instance_valid(progress_bar):
                progress_bar.value = float(cycle) / float(num_cycles) * 100.0
            if is_instance_valid(status_label):
                status_label.text = "Cycle %d / %d" % [cycle, num_cycles]
            await get_tree().process_frame

    _batch_running = false
    if reset_batch_ui:
        if is_instance_valid(run_btn):
            run_btn.disabled = false
        if is_instance_valid(cancel_btn):
            cancel_btn.disabled = true
        if is_instance_valid(close_btn):
            close_btn.disabled = false

    var atk_name: String = attacker_config.display_name
    var def_name: String = defender_config.display_name

    var summary := "--- Batch Results (%s) ---\n" % scenario_key
    summary += "Cycles: %d | %s wins: %d | %s wins: %d\n" % [b_total_cycles, atk_name, b_atk_wins, def_name, b_def_wins]
    summary += "Attacker win rate: %.1f%%\n" % (float(b_atk_wins) / float(maxf(b_total_cycles, 1)) * 100.0)
    summary += "Avg strikes per cycle: %.1f\n" % (float(b_total_strikes) / float(maxf(b_total_cycles, 1)))
    summary += (
        "Avg atk dmg per cycle: %.1f  |  Avg def dmg per cycle: %.1f"
        % [b_atk_dmg / float(maxf(b_total_cycles, 1)), b_def_dmg / float(maxf(b_total_cycles, 1))]
    )

    if is_instance_valid(result_label):
        result_label.text = summary
    if is_instance_valid(status_label):
        status_label.text = "Done -- %d cycles" % b_total_cycles

    var batch_line := (
        "[Batch] %s: %d cycles, %s %d - %s %d (%.0f%% atk win) | avg_strikes=%.1f"
        % [
            scenario_key,
            b_total_cycles,
            atk_name,
            b_atk_wins,
            def_name,
            b_def_wins,
            float(b_atk_wins) / float(maxf(b_total_cycles, 1)) * 100.0,
            float(b_total_strikes) / float(maxf(b_total_cycles, 1)),
        ]
    )
    _log_line(batch_line, "#88ff88")

    if csv_enabled and _batch_csv_lines.size() > 1:
        print("=== BATCH CSV (%s, %d cycles) ===" % [scenario_key, b_total_cycles])
        for line in _batch_csv_lines:
            print(line)

    if reset_batch_ui:
        _auto_enabled = true
