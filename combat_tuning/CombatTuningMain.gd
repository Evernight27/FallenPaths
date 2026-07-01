extends Node2D

## Scene controller for the interactive combat tuning scene.
## Builds UI procedurally, manages 1v1 combat lifecycle, and provides
## per-strike trace for number tuning.

# --- Preloads (production dependencies) ---
const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")

# --- Preloads (tuning modules) ---
const _ConfigData := preload("res://combat_tuning/TuningConfigData.gd")
const _Config := _ConfigData
const _Spawner := preload("res://combat_tuning/CombatantSpawner.gd")
const _Formatter := preload("res://combat_tuning/TuningLogFormatter.gd")

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
var _auto_enabled: bool = true
var _auto_timer: float = 0.0
var _auto_waiting_for_death: bool = false
var _auto_respawn_delay: float = 0.0

# Cycle tracking (auto mode)
var _cycle_count: int = 0
var _cycle_attacker_wins: int = 0
var _cycle_defender_wins: int = 0
var _cycle_total_strikes: int = 0
var _cycle_attacker_dmg_dealt: float = 0.0
var _cycle_defender_dmg_dealt: float = 0.0
var _cycle_start_strikes: int = 0


# --- UI references (built in _build_ui) ---
var _attacker_health_labels: Dictionary = {}  # part -> Label
var _defender_health_labels: Dictionary = {}
var _attacker_state_label: Label = null
var _defender_state_label: Label = null
var _attacker_header_label: Label = null
var _defender_header_label: Label = null
var _log_rtl: RichTextLabel = null
var _move_option: OptionButton = null
var _intensity_slider: HSlider = null
var _intensity_label: Label = null
var _status_bar: Label = null
var _strike_btn: Button = null
var _exchange_btn: Button = null


func _ready() -> void:
	_build_ui()
	_spawn_combatants()


func _process(delta: float) -> void:
	if not _auto_enabled:
		return
	if manager == null or not is_instance_valid(manager):
		return

	# Detect combat resolution closed for respawn (incapacitation/medical phase)
	var resolution_closed: bool = "combat_resolution_closed" in manager and manager.combat_resolution_closed
	if resolution_closed or _any_dead():
		if not _auto_waiting_for_death:
			_log_cycle_summary()
			_auto_waiting_for_death = true
			_append_log("[color=#ffff88]Auto-combat: respawning fresh combatants.[/color]")
		# Wait a few frames before respawning so UI can update
		_auto_respawn_delay += delta
		if _auto_respawn_delay >= 0.1:
			_auto_respawn_delay = 0.0
			_spawn_combatants()
			_auto_waiting_for_death = false
		return

	var atk_c = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var def_c = _EntityAccess.manager_get_combatant(manager, defender_id)
	if atk_c.is_empty() or def_c.is_empty():
		return

	# Use a fixed short delay between auto exchanges for balance testing.
	# Full game timing (wind_up + recovery) is skipped to maximise cycles per second.
	const AUTO_CYCLE_DELAY_S: float = 0.15

	_auto_timer += delta
	if _auto_timer < AUTO_CYCLE_DELAY_S:
		return
	_auto_timer = 0.0

	_auto_exchange()


# ============================================================
#  UI Construction
# ============================================================

func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(main_vbox)

	# --- Top button bar ---
	main_vbox.add_child(_build_top_bar())

	# --- Combatant cards (horizontal split) ---
	var cards_hbox: HBoxContainer = HBoxContainer.new()
	cards_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cards_hbox.custom_minimum_size = Vector2i(0, 360)
	cards_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(cards_hbox)
	var atk_card := _build_combatant_card(true)
	cards_hbox.add_child(atk_card)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_hbox.add_child(spacer)
	var def_card := _build_combatant_card(false)
	cards_hbox.add_child(def_card)

	# --- Controls row ---
	main_vbox.add_child(_build_controls_row())

	# --- Log panel ---
	main_vbox.add_child(_build_log_panel())

	# --- Status bar ---
	_status_bar = Label.new()
	_status_bar.text = "Ready"
	_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_status_bar)


func _build_top_bar() -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_strike_btn = Button.new()
	_strike_btn.text = "Strike"
	_strike_btn.tooltip_text = "Execute one strike (attacker -> defender)"
	_strike_btn.pressed.connect(_on_strike_pressed)
	hbox.add_child(_strike_btn)

	_exchange_btn = Button.new()
	_exchange_btn.text = "Exchange"
	_exchange_btn.tooltip_text = "Full exchange: attacker strikes, then defender strikes"
	_exchange_btn.pressed.connect(_on_exchange_pressed)
	hbox.add_child(_exchange_btn)

	var reset_btn: Button = Button.new()
	reset_btn.text = "Reset"
	reset_btn.tooltip_text = "Full heal and reset both combatants"
	reset_btn.pressed.connect(_on_reset_pressed)
	hbox.add_child(reset_btn)

	var batch_btn: Button = Button.new()
	batch_btn.text = "Batch…"
	batch_btn.tooltip_text = "Run N cycles and collect aggregate stats"
	batch_btn.pressed.connect(_on_batch_pressed)
	hbox.add_child(batch_btn)

	var scenario_btn: Button = Button.new()
	scenario_btn.text = "Presets…"
	scenario_btn.tooltip_text = "Load a scenario preset"
	scenario_btn.pressed.connect(_on_scenario_pressed)
	hbox.add_child(scenario_btn)

	var randomize_btn: Button = Button.new()
	randomize_btn.text = "Randomize"
	randomize_btn.tooltip_text = "Randomize both combatants (species, stats, weapon, form, guard, armor)"
	randomize_btn.pressed.connect(_on_randomize_pressed)
	hbox.add_child(randomize_btn)

	# Auto-combat toggle
	var auto_btn: Button = Button.new()
	auto_btn.text = "Auto: ON"
	auto_btn.tooltip_text = "Toggle auto-combat loop"
	auto_btn.pressed.connect(func(): _toggle_auto())
	hbox.add_child(auto_btn)

	# Spacer
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
	wrapper.custom_minimum_size = Vector2i(460, 360)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	wrapper.add_child(vbox)

	# Header
	var header: Label = Label.new()
	header.text = attacker_config.display_name if is_attacker else defender_config.display_name
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0) if is_attacker else Color(1.0, 0.8, 0.8))
	if is_attacker:
		_attacker_header_label = header
	else:
		_defender_header_label = header
	vbox.add_child(header)

	# Stats line
	var stats_label: Label = Label.new()
	var cfg = attacker_config if is_attacker else defender_config
	var species_name := "Human"
	if cfg.species_tres_path.contains("goblin"):
		species_name = "Goblin"
	stats_label.text = "%s  STR:%d AGI:%d INT:%d END:%d PER:%d  %s" % [
		species_name, cfg.strength, cfg.agility, cfg.intelligence, cfg.endurance, cfg.perception, cfg.weapon_id
	]
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(stats_label)

	# Form and guard
	var form_label: Label = Label.new()
	form_label.text = "Form: %s  Guard: %s" % [cfg.form, cfg.guard_line]
	form_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(form_label)

	# Health per body part (labels stored)
	var body_label := Label.new()
	body_label.text = "— Body Health —"
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(body_label)

	for part in _ConfigData.BODY_PARTS:
		var hl: Label = Label.new()
		hl.text = "  %s: —" % part
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		vbox.add_child(hl)
		if is_attacker:
			_attacker_health_labels[part] = hl
		else:
			_defender_health_labels[part] = hl

	# Blood / consciousness
	var blood_label: Label = Label.new()
	blood_label.name = "blood_label"
	blood_label.text = "Blood: —  Con: —"
	blood_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(blood_label)
	if is_attacker:
		_attacker_health_labels["_blood"] = blood_label
	else:
		_defender_health_labels["_blood"] = blood_label

	# Combatant state
	var state_label: Label = Label.new()
	state_label.name = "state_label"
	state_label.text = "State: —  Stamina: —  Gauge: —"
	state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	state_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	vbox.add_child(state_label)
	if is_attacker:
		_attacker_state_label = state_label
	else:
		_defender_state_label = state_label

	return wrapper


func _build_controls_row() -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Move selector
	var move_label: Label = Label.new()
	move_label.text = " Move:"
	move_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hbox.add_child(move_label)

	_move_option = OptionButton.new()
	_move_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_move_option.item_selected.connect(_on_move_selected)
	hbox.add_child(_move_option)

	# Intensity label + slider
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
	_intensity_slider.custom_minimum_size.x = 150
	hbox.add_child(_intensity_slider)

	_intensity_label = Label.new()
	_intensity_label.text = "%.2f" % _current_intensity
	_intensity_label.custom_minimum_size.x = 50
	_intensity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hbox.add_child(_intensity_label)

	return hbox


func _build_log_panel() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var log_header: Label = Label.new()
	log_header.text = "Combat Log"
	log_header.add_theme_font_size_override("font_size", 16)
	log_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(log_header)

	var sc: ScrollContainer = ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size.y = 200
	vbox.add_child(sc)

	_log_rtl = RichTextLabel.new()
	_log_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_rtl.bbcode_enabled = true
	_log_rtl.scroll_active = true
	_log_rtl.fit_content = true
	_scroll_to_bottom_on_log = true
	sc.add_child(_log_rtl)

	return vbox


var _scroll_to_bottom_on_log: bool = true


# ============================================================
#  Combat Lifecycle
# ============================================================

func _spawn_combatants() -> void:
	_cleanup_manager()
	manager = _MgrScript.new()
	add_child(manager)

	var result: Dictionary = _Spawner.spawn_1v1(manager, attacker_config, defender_config)
	attacker_entity = result.get("attacker_entity") as Node
	defender_entity = result.get("defender_entity") as Node
	attacker_id = result.get("attacker_id", -1)
	defender_id = result.get("defender_id", -1)

	_auto_waiting_for_death = false
	_auto_respawn_delay = 0.0
	_auto_timer = 0.0
	_cycle_start_strikes = _strike_count
	_populate_move_dropdown()
	_refresh_display()
	_append_log("[color=#88ff88]Combatants spawned. Ready for strikes.[/color]")


func _cleanup_manager() -> void:
	if manager != null and is_instance_valid(manager):
		manager.queue_free()
		manager = null
	attacker_entity = null
	defender_entity = null
	attacker_id = -1
	defender_id = -1
	_strike_count = 0


func _populate_move_dropdown() -> void:
	_move_option.clear()
	var atk_c: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk_c.is_empty():
		_move_option.add_item("oberhau")
		return

	var weapon: Variant = _EntityAccess.get_weapon(atk_c)
	if weapon == null:
		_move_option.add_item("oberhau")
		return

	var moves: Array = weapon.get_available_attack_types()
	if moves.is_empty():
		moves = ["oberhau"]

	for m in moves:
		_move_option.add_item(str(m))

	# Select current move if available
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


func _do_strike() -> void:
	if manager == null or attacker_id < 0 or defender_id < 0:
		_append_log("[color=#ff8888]Error: no combatants. Reset or spawn first.[/color]")
		return

	_Spawner.reset_combatants(manager, attacker_entity, defender_entity,
		attacker_id, defender_id, attacker_config, defender_config)
	manager.medical_phase = false
	manager.medical_phase_winner = ""
	manager.combat_resolution_closed = false

	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if atk.is_empty() or tgt.is_empty():
		_append_log("[color=#ff8888]Error: combatant not found in manager.[/color]")
		return
	if not _EntityAccess.alive_bool(atk):
		_append_log("[color=#ff8888]Attacker is dead.[/color]")
		return

	atk.state = _CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": defender_id,
		"intensity": _current_intensity,
		"attack_type": _current_move_id,
	}

	var result: Dictionary = _AttackResolver.resolve_attack(manager, attacker_id)
	_AttackResultApplier.apply_result(manager, attacker_id, result)

	_StatsSync.sync_from_entity(defender_entity,
		_EntityAccess.stats_dict_for_mutation(tgt))

	_strike_count += 1
	var gauge_atk: float = atk.get("gauge", 0.0)
	var gauge_def: float = tgt.get("gauge", 0.0)

	_log_result(result, _current_move_id, gauge_atk, gauge_def)
	_refresh_display()

	# Check for death
	if not _EntityAccess.alive_bool(tgt):
		_append_log("[color=#ffff88]Defender died![/color]")

	_status_bar.text = "Strike #%d: %s" % [_strike_count,
		_Formatter.format_strike_one_line(_current_move_id, result)]


func _any_dead() -> bool:
	if manager == null:
		return false
	var atk_c = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var def_c = _EntityAccess.manager_get_combatant(manager, defender_id)
	if atk_c.is_empty() or def_c.is_empty():
		return false
	return not _EntityAccess.alive_bool(atk_c) or not _EntityAccess.alive_bool(def_c)


func _auto_exchange() -> void:
	# Clear medical flags so resolve_attack doesn't skip the defender's counter-strike
	manager.medical_phase = false
	manager.medical_phase_winner = ""
	manager.combat_resolution_closed = false

	# Sync health from entities to combatant dicts without healing
	_sync_combatant_stats()

	# Attacker strikes (target is defender → pass defender_entity for health sync)
	_auto_strike(attacker_id, defender_id, defender_entity, attacker_config.display_name, defender_config.display_name)

	if _any_dead():
		return

	# Defender counter-strikes (target is attacker → pass attacker_entity for health sync)
	_auto_strike(defender_id, attacker_id, attacker_entity, defender_config.display_name, attacker_config.display_name)


## Single auto strike without healing entities first. Resets combatant state to WAITING
## before the strike (like Proficiency1v1Tail) to prevent manager lifecycle from blocking it.
func _auto_strike(striker_id: int, target_id: int, target_entity: Node, striker_name: String, target_name: String) -> void:
	var striker: Dictionary = _EntityAccess.manager_get_combatant(manager, striker_id)
	if striker.is_empty() or not _EntityAccess.alive_bool(striker):
		return

	# Reset combatant to WAITING first (tail pattern) so the next strike isn't blocked
	striker.state = _CombatConstants.STATE_WAITING
	striker.guard_line = "high"
	# Pick a move appropriate for this striker's weapon
	var move_id: String = _pick_move_for(striker_id)

	striker.state = _CombatConstants.STATE_WIND_UP
	striker.pending_attack = {
		"target_id": target_id,
		"intensity": _current_intensity,
		"attack_type": move_id,
	}

	var result: Dictionary = _AttackResolver.resolve_attack(manager, striker_id)
	_AttackResultApplier.apply_result(manager, striker_id, result)

	# Sync target entity health back to target combatant dict (target takes the damage)
	var target: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if not target.is_empty() and target_entity != null:
		_StatsSync.sync_from_entity(target_entity,
			_EntityAccess.stats_dict_for_mutation(target))

	_strike_count += 1
	var gauge_atk: float = striker.get("gauge", 0.0)
	var gauge_def: float = target.get("gauge", 0.0) if not target.is_empty() else 0.0
	_log_result(result, "%s→%s %s" % [striker_name, target_name, move_id], gauge_atk, gauge_def)
	_refresh_display()

	# Track damage for cycle summary
	if result.get("action") == "hit":
		var dmg: float = result.get("dmg", 0.0)
		if striker_id == attacker_id:
			_cycle_attacker_dmg_dealt += dmg
		else:
			_cycle_defender_dmg_dealt += dmg


## Pick a random attack from the combatant's weapon's available moves.
func _pick_move_for(combatant_id: int) -> String:
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return "oberhau"
	var weapon: Variant = _EntityAccess.get_weapon(c)
	if weapon == null:
		return "oberhau"
	var moves: Array = weapon.get_available_attack_types()
	if moves.is_empty():
		return "oberhau"
	var idx: int = randi() % moves.size()
	return str(moves[idx])


func _sync_combatant_stats() -> void:
	for c in manager.combatants:
		var n: Node = _EntityAccess.scene_node(c)
		if n == null:
			continue
		var entity = _EntityAccess.get_health_entity_from_node(manager, n)
		if entity != null:
			_StatsSync.sync_from_entity(entity, _EntityAccess.stats_dict_for_mutation(c))


func _do_exchange() -> void:
	_do_strike()

	var def_c: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if def_c.is_empty() or not _EntityAccess.alive_bool(def_c):
		_append_log("[color=#ffff88]Defender dead — exchange stops.[/color]")
		return

	_Spawner.reset_combatants(manager, attacker_entity, defender_entity,
		attacker_id, defender_id, attacker_config, defender_config)
	manager.medical_phase = false
	manager.medical_phase_winner = ""
	manager.combat_resolution_closed = false

	var def_atk: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	var player_c: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)

	if def_atk.is_empty() or not _EntityAccess.alive_bool(def_atk):
		_append_log("[color=#ffff88]Defender can't counter — dead or missing.[/color]")
		return

	def_atk.state = _CombatConstants.STATE_WAITING
	def_atk.guard_line = "high"
	var def_move: String = _pick_move_for(defender_id)
	def_atk.state = _CombatConstants.STATE_WIND_UP
	def_atk.pending_attack = {
		"target_id": attacker_id,
		"intensity": _current_intensity,
		"attack_type": def_move,
	}

	var def_result: Dictionary = _AttackResolver.resolve_attack(manager, defender_id)
	_AttackResultApplier.apply_result(manager, defender_id, def_result)

	_StatsSync.sync_from_entity(attacker_entity,
		_EntityAccess.stats_dict_for_mutation(player_c))

	var gauge_atk_def: float = def_atk.get("gauge", 0.0)
	var gauge_def_atk: float = player_c.get("gauge", 0.0)

	_strike_count += 1
	_log_result(def_result, "%s→%s %s" % [defender_config.display_name, attacker_config.display_name, def_move], gauge_atk_def, gauge_def_atk)
	_refresh_display()

	if not _EntityAccess.alive_bool(player_c):
		_append_log("[color=#ffff88]Attacker died![/color]")


func _log_result(result: Dictionary, move_label: String, gauge_atk: float, gauge_def: float) -> void:
	var formatted: String = _Formatter.format_strike(move_label, result, gauge_atk, gauge_def)
	_append_log(formatted)


func _append_log(text: String) -> void:
	var cleaned: String = text
	if _log_rtl.text.is_empty():
		_log_rtl.append_text(cleaned)
	else:
		_log_rtl.append_text("\n" + cleaned)
	if _scroll_to_bottom_on_log:
		var sc: ScrollContainer = _log_rtl.get_parent() as ScrollContainer
		if sc != null:
			sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value) if sc.get_v_scroll_bar() != null else 0


func _refresh_display() -> void:
	_refresh_entity_display(attacker_entity, _attacker_health_labels, _attacker_state_label)
	_refresh_entity_display(defender_entity, _defender_health_labels, _defender_state_label)


func _refresh_entity_display(entity: Node, health_labels: Dictionary, state_label: Label) -> void:
	if entity == null or not is_instance_valid(entity):
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
		blood_label.text = "Blood: %.1f  Con: %.1f" % [entity.blood_volume, entity.consciousness]

	if state_label == null:
		return

	# Find this entity's combatant dict
	var cid: int = -1
	if entity == attacker_entity:
		cid = attacker_id
	elif entity == defender_entity:
		cid = defender_id
	if cid < 0:
		state_label.text = "State: —"
		return
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, cid)
	if c.is_empty():
		state_label.text = "State: (not in combat)"
		return

	state_label.text = _Formatter.format_combatant_state(c)


static func _health_color(ratio: float) -> String:
	if ratio > 0.7:
		return "#88ff88"
	elif ratio > 0.4:
		return "#ffff88"
	elif ratio > 0.15:
		return "#ffaa44"
	return "#ff4444"


# ============================================================
#  Signal Handlers
# ============================================================

func _on_strike_pressed() -> void:
	_auto_enabled = false
	_auto_waiting_for_death = false
	_strike_btn.disabled = true
	_exchange_btn.disabled = true
	_do_strike()
	_strike_btn.disabled = false
	_exchange_btn.disabled = false


func _on_exchange_pressed() -> void:
	_auto_enabled = false
	_auto_waiting_for_death = false
	_strike_btn.disabled = true
	_exchange_btn.disabled = true
	_do_exchange()
	_strike_btn.disabled = false
	_exchange_btn.disabled = false


func _on_reset_pressed() -> void:
	_spawn_combatants()
	_append_log("[color=#8888ff]Reset: fresh combatants spawned.[/color]")
	_status_bar.text = "Reset"


func _on_randomize_pressed() -> void:
	var configs := _ConfigData.TuningCombatantConfig.random_configs_pair()
	attacker_config = configs[0]
	defender_config = configs[1]
	_spawn_combatants()
	var atk_species := "Human" if attacker_config.species_tres_path.contains("human") else "Goblin"
	var def_species := "Human" if defender_config.species_tres_path.contains("human") else "Goblin"
	_append_log("[color=#ff88ff]Randomized: %s (%s/%s) vs %s (%s/%s)" % [
		attacker_config.display_name, atk_species, attacker_config.weapon_id,
		defender_config.display_name, def_species, defender_config.weapon_id
	])
	_status_bar.text = "Randomized"


func _on_batch_pressed() -> void:
	_open_batch_window()


func _on_scenario_pressed() -> void:
	_open_presets_window()


func _on_move_selected(idx: int) -> void:
	_current_move_id = _move_option.get_item_text(idx)


func _on_intensity_changed(value: float) -> void:
	_current_intensity = value
	_intensity_label.text = "%.2f" % value


func _log_cycle_summary() -> void:
	_cycle_count += 1
	var strikes_this_cycle: int = _strike_count - _cycle_start_strikes
	_cycle_total_strikes += strikes_this_cycle

	# Determine winner: alive_bool for death, side for incapacitation
	var atk_alive: bool = false
	var def_alive: bool = false
	var atk_c = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var def_c = _EntityAccess.manager_get_combatant(manager, defender_id)
	if not atk_c.is_empty():
		atk_alive = _EntityAccess.alive_bool(atk_c)
	if not def_c.is_empty():
		def_alive = _EntityAccess.alive_bool(def_c)

	var winner_name: String = "?"
	if not atk_alive and def_alive:
		winner_name = defender_config.display_name
		_cycle_defender_wins += 1
	elif not def_alive and atk_alive:
		winner_name = attacker_config.display_name
		_cycle_attacker_wins += 1
	elif not atk_alive and not def_alive:
		winner_name = "mutual"
	else:
		# Both alive — incapacitation: track who was on the losing side
		var mw: String = manager.medical_phase_winner if "medical_phase_winner" in manager else ""
		if mw == "enemy":
			winner_name = defender_config.display_name
			_cycle_defender_wins += 1
		elif mw == "player":
			winner_name = attacker_config.display_name
			_cycle_attacker_wins += 1
		elif "combat_resolution_closed" in manager and manager.combat_resolution_closed:
			# Resolution closed but winner unknown — use side of last standing
			var player_incap: bool = false
			var enemy_incap: bool = false
			if not atk_c.is_empty() and _EntityAccess.is_incapacitated(atk_c):
				player_incap = true
			if not def_c.is_empty() and _EntityAccess.is_incapacitated(def_c):
				enemy_incap = true
			if player_incap and not enemy_incap:
				winner_name = defender_config.display_name
				_cycle_defender_wins += 1
			elif enemy_incap and not player_incap:
				winner_name = attacker_config.display_name
				_cycle_attacker_wins += 1
			else:
				winner_name = "draw"
		else:
			winner_name = "draw"

	var win_rate_atk: float = float(_cycle_attacker_wins) / float(maxf(_cycle_count, 1)) * 100.0
	var avg_strikes: float = float(_cycle_total_strikes) / float(maxf(_cycle_count, 1))

	var summary := "--- Cycle %d finished: %s wins ---\n" % [_cycle_count, winner_name]
	summary += "  Strikes: %d  Attacker dmg: %.1f  Defender dmg: %.1f\n" % [
		strikes_this_cycle, _cycle_attacker_dmg_dealt, _cycle_defender_dmg_dealt
	]
	summary += "  Aggregate: %s %d  %s %d  cycles=%d  avg_strikes=%.1f  atk_win_rate=%.0f%%" % [
		attacker_config.display_name, _cycle_attacker_wins,
		defender_config.display_name, _cycle_defender_wins,
		_cycle_count, avg_strikes, win_rate_atk
	]
	_append_log("[color=#88ccff]" + summary + "[/color]")
	print("[Tuning Cycle Summary] " + summary.replace("\n", "  "))

	# Reset per-cycle damage tracking
	_cycle_attacker_dmg_dealt = 0.0
	_cycle_defender_dmg_dealt = 0.0

	# Update status bar
	var status_parts := PackedStringArray()
	status_parts.append("Cycle %d: %s" % [_cycle_count, winner_name])
	status_parts.append("%s: %d wins" % [attacker_config.display_name, _cycle_attacker_wins])
	status_parts.append("%s: %d wins" % [defender_config.display_name, _cycle_defender_wins])
	status_parts.append("avg %.1f strikes" % avg_strikes)
	_status_bar.text = "  |  ".join(status_parts)


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
	_presets_window.min_size = Vector2i(380, 280)
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

	# Scenario definitions: key -> label, [attacker_config, defender_config] factory
	var scenario_keys := ["Default", "Heavy vs Light", "Spear vs Sword", "Goblin vs Human"]
	var scenario_labels := {
		"Default": "Attacker (110/100/105/105/95) vs Defender (100 all) — balanced sword duel",
		"Heavy vs Light": "Heavy (MACE 140/80/90/130/80) vs Light (SWORD 80/140/100/80/120)",
		"Spear vs Sword": "Spear (110/100) vs Sword (100 all) — reach advantage",
		"Goblin vs Human": "Goblin (random) vs Human (random) — species comparison",
	}

	var option_btn := OptionButton.new()
	option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in scenario_keys:
		option_btn.add_item(key)
	inner_vbox.add_child(option_btn)

	var preview := Label.new()
	preview.text = scenario_labels[scenario_keys[0]]
	preview.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner_vbox.add_child(preview)

	option_btn.item_selected.connect(func(idx: int):
		if idx >= 0 and idx < scenario_keys.size():
			preview.text = scenario_labels[scenario_keys[idx]]
	)

	var btn_row := HBoxContainer.new()
	inner_vbox.add_child(btn_row)

	var apply_btn := Button.new()
	apply_btn.text = "Apply Preset"
	apply_btn.pressed.connect(func():
		var idx := option_btn.selected
		if idx < 0 or idx >= scenario_keys.size():
			return
		var skey: String = scenario_keys[idx]
		var configs: Array = _load_scenario(skey)
		if configs.size() >= 2:
			attacker_config = configs[0]
			defender_config = configs[1]
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


## Load scenario configs by key.
func _load_scenario(key: String) -> Array:
	match key:
		"Default":
			return [_Config.default_attacker_config(), _Config.default_defender_config()]
		"Heavy vs Light":
			return _Config.heavy_vs_light_configs()
		"Spear vs Sword":
			return _Config.spear_vs_sword_configs()
		"Goblin vs Human":
			var atk := _Config.TuningCombatantConfig.new("Goblin")
			atk.species_tres_path = "res://species/goblin.tres"
			atk.randomize()
			var def := _Config.TuningCombatantConfig.new("Human")
			def.randomize()
			return [atk, def]
	return []


# ============================================================
#  Batch Runner
# ============================================================

var _batch_window: Window = null
var _batch_csv_lines: PackedStringArray = []
var _batch_strike_idx: int = 0
var _batch_running: bool = false
var _batch_cycle_abort: bool = false
## Available batch scenario keys.
const BATCH_SCENARIO_KEYS := ["Default", "Heavy vs Light", "Spear vs Sword"]

const BATCH_SCENARIO_LABELS: Dictionary = {
	"Default": "Default (attacker 110/100, defender 100 all, both SWORD)",
	"Heavy vs Light": "Heavy (MACE) vs Light (SWORD)",
	"Spear vs Sword": "Spear (110/100) vs Sword (100 all)",
}

func _open_batch_window() -> void:
	if _batch_window != null and is_instance_valid(_batch_window):
		_batch_window.grab_focus()
		return

	_auto_enabled = false
	_batch_running = false
	_batch_csv_lines.clear()
	_batch_strike_idx = 0

	_batch_window = Window.new()
	_batch_window.title = "Batch Runner"
	_batch_window.min_size = Vector2i(420, 320)
	_batch_window.close_requested.connect(_close_batch_window)
	add_child(_batch_window)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	_batch_window.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	vbox.add_child(margin)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(inner_vbox)

	# Scenario selector
	var scenario_label := Label.new()
	scenario_label.text = "Scenario:"
	inner_vbox.add_child(scenario_label)

	var scenario_opt := OptionButton.new()
	scenario_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in BATCH_SCENARIO_KEYS:
		scenario_opt.add_item(key)
	inner_vbox.add_child(scenario_opt)

	# Cycle count
	var cycle_row := HBoxContainer.new()
	cycle_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(cycle_row)

	var cycle_label := Label.new()
	cycle_label.text = "Cycles:"
	cycle_row.add_child(cycle_label)

	var cycle_spin := SpinBox.new()
	cycle_spin.min_value = 1
	cycle_spin.max_value = 10000
	cycle_spin.value = 100
	cycle_spin.step = 1
	cycle_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cycle_row.add_child(cycle_spin)

	# CSV options
	var csv_toggle := CheckBox.new()
	csv_toggle.text = "Write per-strike CSV to log"
	csv_toggle.button_pressed = true
	inner_vbox.add_child(csv_toggle)

	var save_csv_toggle := CheckBox.new()
	save_csv_toggle.text = "Save CSV to disk (project://batch_results.csv)"
	save_csv_toggle.button_pressed = false
	inner_vbox.add_child(save_csv_toggle)

	# Progress bar
	var progress_bar := ProgressBar.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.value = 0
	inner_vbox.add_child(progress_bar)

	var status_label := Label.new()
	status_label.text = "Ready"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	inner_vbox.add_child(status_label)

	# Results area
	var result_label := Label.new()
	result_label.name = "batch_result"
	result_label.text = ""
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner_vbox.add_child(result_label)

	# Buttons
	var btn_row := HBoxContainer.new()
	inner_vbox.add_child(btn_row)

	var run_btn := Button.new()
	run_btn.text = "Run Batch"
	btn_row.add_child(run_btn)

	var cancel_run_btn := Button.new()
	cancel_run_btn.text = "Abort"
	cancel_run_btn.disabled = true
	btn_row.add_child(cancel_run_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_close_batch_window)
	btn_row.add_child(close_btn)

	run_btn.pressed.connect(func():
		if _batch_running:
			return
		_batch_running = true
		_batch_cycle_abort = false
		run_btn.disabled = true
		cancel_run_btn.disabled = false
		close_btn.disabled = true
		_auto_enabled = false
		var n_cycles: int = int(cycle_spin.value)
		var csv_enabled: bool = csv_toggle.button_pressed
		var save_csv: bool = save_csv_toggle.button_pressed
		var s_idx := scenario_opt.selected
		var s_keys: Array = BATCH_SCENARIO_KEYS
		var s_key: String = s_keys[s_idx] if s_idx >= 0 and s_idx < s_keys.size() else s_keys[0]
		_run_batch(s_key, n_cycles, csv_enabled, save_csv, run_btn, cancel_run_btn, close_btn, progress_bar, status_label, result_label)
	)

	cancel_run_btn.pressed.connect(func():
		_batch_cycle_abort = true
	)

	_batch_window.popup_centered()


func _close_batch_window() -> void:
	_batch_running = false
	_batch_cycle_abort = true
	if _batch_window != null and is_instance_valid(_batch_window):
		_batch_window.queue_free()
	_batch_window = null


func _run_batch(scenario_key: String, num_cycles: int, csv_enabled: bool, save_csv: bool,
	run_btn: Button, cancel_btn: Button, close_btn: Button,
	progress_bar: ProgressBar, status_label: Label, result_label: Label) -> void:

	_batch_csv_lines.clear()
	_batch_strike_idx = 0

	# Load scenario configs
	var configs: Array = _load_scenario(scenario_key)
	if configs.size() < 2:
		status_label.text = "ERROR: invalid scenario config"
		_batch_running = false
		run_btn.disabled = false
		cancel_btn.disabled = true
		close_btn.disabled = false
		return

	var atk_cfg: Variant = configs[0]
	var def_cfg: Variant = configs[1]

	# Apply scenario to current scene
	attacker_config = atk_cfg
	defender_config = def_cfg

	# Disable auto-combat to take over the process loop
	_auto_enabled = false

	# Local aggregate tracking (avoids stale member vars across batch runs)
	var b_total_cycles: int = 0
	var b_atk_wins: int = 0
	var b_def_wins: int = 0
	var b_total_strikes: int = 0
	var b_atk_dmg: float = 0.0
	var b_def_dmg: float = 0.0

	# CSV header
	if csv_enabled:
		_batch_csv_lines.append(_Formatter.csv_header())

	# Run cycles
	var cycle: int = 0
	while cycle < num_cycles and not _batch_cycle_abort:
		# Spawn fresh combatants
		_spawn_combatants()
		# Small yield for engine to process spawn
		for _i in range(2):
			await get_tree().process_frame

		# Track strikes in this cycle
		var start_strikes: int = _strike_count
		var atk_dmg_this: float = 0.0
		var def_dmg_this: float = 0.0

		# Run exchanges until someone dies
		while not _batch_cycle_abort:
			if manager == null or not is_instance_valid(manager):
				break

			var atk_c = _EntityAccess.manager_get_combatant(manager, attacker_id)
			var def_c = _EntityAccess.manager_get_combatant(manager, defender_id)
			if atk_c.is_empty() or def_c.is_empty():
				break
			if not _EntityAccess.alive_bool(atk_c) or not _EntityAccess.alive_bool(def_c):
				break
			if "combat_resolution_closed" in manager and manager.combat_resolution_closed:
				break

			# Do an exchange
			_sync_combatant_stats()

			manager.medical_phase = false
			manager.medical_phase_winner = ""
			manager.combat_resolution_closed = false

			# Attacker strike
			var atk_result := _batch_strike(attacker_id, defender_id, defender_entity)
			if csv_enabled and not atk_result.is_empty():
				var atk_c_post = _EntityAccess.manager_get_combatant(manager, attacker_id)
				var def_c_post = _EntityAccess.manager_get_combatant(manager, defender_id)
				_batch_csv_lines.append(_Formatter.csv_row(_batch_strike_idx, "atk", atk_result,
					atk_c_post.get("gauge", 0.0), def_c_post.get("gauge", 0.0)))
				_batch_strike_idx += 1
			if atk_result.get("action") == "hit":
				atk_dmg_this += atk_result.get("dmg", 0.0)

			atk_c = _EntityAccess.manager_get_combatant(manager, attacker_id)
			def_c = _EntityAccess.manager_get_combatant(manager, defender_id)
			if atk_c.is_empty() or def_c.is_empty():
				break
			if not _EntityAccess.alive_bool(atk_c) or not _EntityAccess.alive_bool(def_c):
				break
			if "combat_resolution_closed" in manager and manager.combat_resolution_closed:
				break

			# Defender counter-strike
			var def_result := _batch_strike(defender_id, attacker_id, attacker_entity)
			if csv_enabled and not def_result.is_empty():
				var atk_c_post2 = _EntityAccess.manager_get_combatant(manager, attacker_id)
				var def_c_post2 = _EntityAccess.manager_get_combatant(manager, defender_id)
				_batch_csv_lines.append(_Formatter.csv_row(_batch_strike_idx, "def", def_result,
					def_c_post2.get("gauge", 0.0), atk_c_post2.get("gauge", 0.0)))
				_batch_strike_idx += 1
			if def_result.get("action") == "hit":
				def_dmg_this += def_result.get("dmg", 0.0)

		# Determine winner
		var atk_c2 = _EntityAccess.manager_get_combatant(manager, attacker_id) if manager != null else {}
		var def_c2 = _EntityAccess.manager_get_combatant(manager, defender_id) if manager != null else {}
		var atk_alive := not atk_c2.is_empty() and _EntityAccess.alive_bool(atk_c2)
		var def_alive := not def_c2.is_empty() and _EntityAccess.alive_bool(def_c2)

		if not atk_alive and def_alive:
			b_def_wins += 1
		elif not def_alive and atk_alive:
			b_atk_wins += 1
		else:
			# Incapacitation: check medical_phase_winner
			var mw: String = manager.medical_phase_winner if manager != null and "medical_phase_winner" in manager else ""
			if mw == "enemy":
				b_def_wins += 1
			elif mw == "player":
				b_atk_wins += 1

		var strikes_this: int = _strike_count - start_strikes
		b_total_strikes += strikes_this
		b_atk_dmg += atk_dmg_this
		b_def_dmg += def_dmg_this
		b_total_cycles += 1

		cycle += 1

		# Update progress every 10 cycles
		if cycle % 10 == 0 or cycle == num_cycles:
			progress_bar.value = float(cycle) / float(num_cycles) * 100.0
			status_label.text = "Cycle %d / %d" % [cycle, num_cycles]
			await get_tree().process_frame

	# Done — show results
	_batch_running = false
	run_btn.disabled = false
	cancel_btn.disabled = true
	close_btn.disabled = false

	var atk_name: String = attacker_config.display_name
	var def_name: String = defender_config.display_name

	var summary := "--- Batch Results (%s) ---\n" % scenario_key
	summary += "Cycles: %d | %s wins: %d | %s wins: %d\n" % [b_total_cycles, atk_name, b_atk_wins, def_name, b_def_wins]
	summary += "Attacker win rate: %.1f%%\n" % (float(b_atk_wins) / float(maxf(b_total_cycles, 1)) * 100.0)
	summary += "Avg strikes per cycle: %.1f\n" % (float(b_total_strikes) / float(maxf(b_total_cycles, 1)))
	summary += "Avg atk dmg per cycle: %.1f  |  Avg def dmg per cycle: %.1f" % [
		b_atk_dmg / float(maxf(b_total_cycles, 1)),
		b_def_dmg / float(maxf(b_total_cycles, 1))
	]

	result_label.text = summary
	status_label.text = "Done — %d cycles" % b_total_cycles

	# Headless-friendly output (stdout) for analysis scripts
	print("[Tuning Batch Results] %s: %d cycles, %s %d - %s %d (%.0f%% atk_win)" % [
		scenario_key, b_total_cycles, atk_name, b_atk_wins, def_name, b_def_wins,
		float(b_atk_wins) / float(maxf(b_total_cycles, 1)) * 100.0
	])

	_append_log("[color=#88ff88][Batch] %s: %d cycles, %s %d - %s %d (%.0f%% atk win)[/color]" % [
		scenario_key, b_total_cycles, atk_name, b_atk_wins, def_name, b_def_wins,
		float(b_atk_wins) / float(maxf(b_total_cycles, 1)) * 100.0
	])

	# Print CSV to output
	if csv_enabled and _batch_csv_lines.size() > 1:
		print("=== BATCH CSV (%s, %d cycles) ===" % [scenario_key, b_total_cycles])
		for line in _batch_csv_lines:
			print(line)

	# Save CSV to disk
	if save_csv and _batch_csv_lines.size() > 1:
		var csv_path := "res://batch_results.csv"
		var csv_text := "\n".join(_batch_csv_lines) + "\n"
		var file := FileAccess.open(csv_path, FileAccess.WRITE)
		if file != null:
			file.store_string(csv_text)
			file.close()
			print("[Tuning Batch] CSV saved to %s (%d lines)" % [csv_path, _batch_csv_lines.size()])
		else:
			print("[Tuning Batch] ERROR: could not write %s" % csv_path)

	# Re-enable auto-combat if it was on before
	_auto_enabled = true


## Single strike for batch runner (no UI refresh, no cycle tracking).
func _batch_strike(striker_id: int, target_id: int, target_entity: Node) -> Dictionary:
	var striker: Dictionary = _EntityAccess.manager_get_combatant(manager, striker_id)
	if striker.is_empty() or not _EntityAccess.alive_bool(striker):
		return {}

	striker.state = _CombatConstants.STATE_WAITING
	striker.guard_line = "high"
	var move_id: String = _pick_move_for(striker_id)

	striker.state = _CombatConstants.STATE_WIND_UP
	striker.pending_attack = {
		"target_id": target_id,
		"intensity": _current_intensity,
		"attack_type": move_id,
	}

	var result: Dictionary = _AttackResolver.resolve_attack(manager, striker_id)
	_AttackResultApplier.apply_result(manager, striker_id, result)

	var target: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if not target.is_empty() and target_entity != null:
		_StatsSync.sync_from_entity(target_entity,
			_EntityAccess.stats_dict_for_mutation(target))

	_strike_count += 1

	return result


func _toggle_auto() -> void:
	_auto_enabled = not _auto_enabled
	_auto_waiting_for_death = false
	var auto_btns: Array[Node] = []
	for child in get_children():
		if child is MarginContainer:
			for gc in child.get_children():
				if gc is VBoxContainer:
					for tb in gc.get_children():
						if tb is HBoxContainer:
							for btn in tb.get_children():
								if btn is Button and btn.text.begins_with("Auto:"):
									auto_btns.append(btn)
	for b in auto_btns:
		b.text = "Auto: %s" % ("ON" if _auto_enabled else "OFF")
	_append_log("[color=%s]Auto-combat %s.[/color]" % [
		"#88ff88" if _auto_enabled else "#ff8888",
		"enabled" if _auto_enabled else "disabled"
	])
