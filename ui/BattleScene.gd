extends Node

signal battle_ended(winner: String, defeated: Node)

const _TurnReadyHandler := preload("res://ui/TurnReadyHandler.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationDiagramBuilder := preload("res://ui/FormationDiagramBuilder.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")

var players: Array = []
var enemies: Array = []
var parent_scene: Node = null

# manager & combat ids
var manager: Node = null
var id_to_controls := {} # map combatant id -> {row, name, body_bars, body_labels, gauge, gauge_label, node}
var combat_log: RichTextLabel = null
var combat_log_scroll: ScrollContainer = null
var end_battle_button: Button = null
var _pending_winner: String = ""
var _pending_defeated: Node = null
var _in_medical_phase: bool = false
var _medical_phase_finished_announced: bool = false

# UI nodes
var canvas_layer: CanvasLayer
var formation_diagram_hbox: Control = null
var formation_diagram_enemy: Control = null
var formation_diagram_player: Control = null
var _enemy_engagement_label: Label = null
var _player_engagement_label: Label = null
var _player_list: Control = null
var _enemy_list: Control = null
var _player_preset: Dictionary = {}
var _enemy_preset: Dictionary = {}
var _diagram_footwork_sig: String = ""

func _ready() -> void:
	# Processing will be enabled by start()
	set_process(false)

## Start battle. Optional p_player_formation and p_enemy_formation: { files, ranks, density, optional **`CombatConstants.FORMATION_PRESET_KEY_DOCTRINE`** or **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, optional **`CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS`**, … }.
## When omitted, uses world meta "party_formation" / "enemy_formation" or defaults from count.
## Optional p_encounter: merged into **`CombatManager.encounter`** before **`manager.start()`** (same keys as **`CombatManager.start`** default_enc — doctrine, **`depth_polearm_ai_doctrine_mults_*`**, posture deltas, …). If empty, reads **`parent_scene`** meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** when present (**`CombatFlow.start_combat`** can set it on the world).
func start(
	p_players,
	p_enemies,
	p_player_formation: Dictionary = {},
	p_enemy_formation: Dictionary = {},
	p_encounter: Dictionary = {}
) -> void:
	# Accept either a single Node or an Array of Nodes for each side
	if p_players == null:
		players = []
	elif typeof(p_players) == TYPE_ARRAY:
		players = p_players.duplicate()
	else:
		players = [p_players]

	if p_enemies == null:
		enemies = []
	elif typeof(p_enemies) == TYPE_ARRAY:
		enemies = p_enemies.duplicate()
	else:
		enemies = [p_enemies]

	# Hide the previous scene to prevent underlying UI from showing (Node has no visible; CanvasItem does)
	if parent_scene != null and "visible" in parent_scene:
		parent_scene.visible = false

	_diagram_footwork_sig = ""
	_create_ui()
	_update_ui()

	# setup combat manager
	var mgr_script = load(ResourcePaths.COMBAT_MANAGER)
	if mgr_script == null:
		print("CombatManager missing")
		return
	manager = mgr_script.new()
	add_child(manager)
	# register combatants
	_player_list = get_node_or_null(BattleUIConstants.MAIN_LIST_PATH + "/PlayerStatsScroll/PlayerPanel/PlayerVBox/PlayerList")
	_enemy_list = get_node_or_null(BattleUIConstants.MAIN_LIST_PATH + "/EnemyStatsScroll/EnemyPanel/EnemyVBox/EnemyList")
	for pl in players:
		var pid = manager.register(pl, "player")
		CombatantRowBuilder.create_row(pid, pl, _player_list, id_to_controls)
	for en in enemies:
		var eid = manager.register(en, "enemy")
		CombatantRowBuilder.create_row(eid, en, _enemy_list, id_to_controls)
	# Formation presets: use provided or default from count
	_player_preset = p_player_formation if not p_player_formation.is_empty() else _FormationPreset.default_for_count(players.size())
	_enemy_preset = p_enemy_formation if not p_enemy_formation.is_empty() else _FormationPreset.default_for_count(enemies.size())
	# Connect signals BEFORE manager.start() so turn_ready is never missed (robustness)
	manager.connect("turn_ready", Callable(self, "_on_turn_ready"))
	manager.connect("action_resolved", Callable(self, "_on_action_resolved"))
	manager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	manager.connect("enemies_eliminated", Callable(self, "_on_enemies_eliminated"))
	manager.connect("combatant_health_changed", Callable(self, "_on_combatant_health_changed"))
	manager.connect("formation_changed", Callable(self, "_on_formation_changed"))
	manager.connect("engagement_state_changed", Callable(self, "_on_engagement_state_changed"))
	manager.connect("combat_ui_hint", Callable(self, "_on_combat_ui_hint"))
	var encounter_src: Dictionary = {}
	if not p_encounter.is_empty():
		encounter_src = p_encounter.duplicate(true)
	elif parent_scene != null and parent_scene.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		var em: Variant = parent_scene.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
		if em != null and em is Dictionary:
			encounter_src = (em as Dictionary).duplicate(true)
	if not encounter_src.is_empty():
		manager.encounter = encounter_src
	# Start manager (builds formations, assigns rank/file; merges encounter defaults)
	manager.start(_player_preset, _enemy_preset)
	if CombatConstants.DEBUG_BACK_RANK_DEPTH_POLEARM_LOADOUT:
		_apply_debug_depth_polearm_loadout(manager)
	# Creature stats: fixed registration order (rows stay in list order; no reparent on formation change).
	# Formation positions: FormationDiagramBuilder only.
	if formation_diagram_hbox != null:
		formation_diagram_enemy = _FormationDiagramBuilder.create(manager, _enemy_preset, "enemy")
		formation_diagram_player = _FormationDiagramBuilder.create(manager, _player_preset, "player")
		var player_col := VBoxContainer.new()
		player_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_player_engagement_label = Label.new()
		_player_engagement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_player_engagement_label.add_theme_font_size_override("font_size", 11)
		_player_engagement_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		player_col.add_child(_player_engagement_label)
		player_col.add_child(formation_diagram_player)
		formation_diagram_hbox.add_child(player_col)
		var sep = VSeparator.new()
		sep.custom_minimum_size = Vector2(12, 0)
		formation_diagram_hbox.add_child(sep)
		var enemy_col := VBoxContainer.new()
		enemy_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_enemy_engagement_label = Label.new()
		_enemy_engagement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_enemy_engagement_label.add_theme_font_size_override("font_size", 11)
		_enemy_engagement_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		enemy_col.add_child(_enemy_engagement_label)
		enemy_col.add_child(formation_diagram_enemy)
		formation_diagram_hbox.add_child(enemy_col)
		_sync_engagement_labels_from_manager()
	# Ensure ScrollContainer child has proper minimum size so scrolling works (wait for layout)
	await get_tree().process_frame
	await get_tree().process_frame
	_update_scroll_content_size()
	set_process(true)

func _update_scroll_content_size() -> void:
	var base := BattleUIConstants.MAIN_LIST_PATH
	var player_scroll: ScrollContainer = get_node_or_null(base + "/PlayerStatsScroll") as ScrollContainer
	var enemy_scroll: ScrollContainer = get_node_or_null(base + "/EnemyStatsScroll") as ScrollContainer
	var player_vbox: Control = get_node_or_null(base + "/PlayerStatsScroll/PlayerPanel/PlayerVBox") as Control
	var enemy_vbox: Control = get_node_or_null(base + "/EnemyStatsScroll/EnemyPanel/EnemyVBox") as Control
	if player_scroll == null or enemy_scroll == null or player_vbox == null or enemy_vbox == null:
		return
	_apply_stats_scroll_min_size(player_scroll, player_vbox, players.size())
	_apply_stats_scroll_min_size(enemy_scroll, enemy_vbox, enemies.size())


func _apply_stats_scroll_min_size(scroll: ScrollContainer, inner_vbox: Control, row_count: int) -> void:
	# ScrollContainer only shows scrollbar when child min size exceeds viewport.
	# get_combined_minimum_size() can be unreliable with nested containers, so we also
	# estimate from row count (each combatant row ~180px).
	var content_min := inner_vbox.get_combined_minimum_size()
	var estimated_height := row_count * 180
	var scroll_height := scroll.size.y
	if scroll_height <= 1.0:
		var p: Control = scroll.get_parent() as Control
		if p != null:
			scroll_height = p.size.y
	if scroll_height <= 1.0:
		scroll_height = 260.0
	var min_height := maxf(maxf(content_min.y, estimated_height), scroll_height + 1.0)
	inner_vbox.custom_minimum_size = Vector2(content_min.x, min_height)

## Tier 1.9 playtest: rank > 0 fighters get `SPEAR` (formation presets are unchanged).
func _apply_debug_depth_polearm_loadout(mgr: Node) -> void:
	if mgr == null:
		return
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.rank_int(c) <= 0:
			continue
		var n: Node = _EntityAccess.scene_node(c)
		if n == null or not n.has_method("equip_weapon"):
			continue
		var w: Weapon = _Weapon.create_from_definition("SPEAR")
		if w != null:
			n.call("equip_weapon", w)


func _create_ui() -> void:
	var layout = BattleUILayout.create(self)
	canvas_layer = layout.canvas_layer
	combat_log = layout.combat_log
	combat_log_scroll = layout.combat_log_scroll
	formation_diagram_hbox = layout.get("formation_diagram_hbox", null)

func _scroll_combat_log_to_bottom() -> void:
	if combat_log_scroll == null:
		return
	# Layout updates over multiple frames; scrollbar max_value is stale until layout settles.
	# Single defer is often insufficient (especially during medical phase when layout changes).
	# Use double defer so we scroll after the RichTextLabel's fit_content has propagated.
	call_deferred("_scroll_combat_log_to_bottom_deferred")

func _scroll_combat_log_to_bottom_deferred() -> void:
	if combat_log_scroll == null:
		return
	call_deferred("_do_scroll_combat_log_to_bottom")

func _do_scroll_combat_log_to_bottom() -> void:
	if combat_log_scroll == null:
		return
	var vbar = combat_log_scroll.get_v_scroll_bar()
	if vbar:
		combat_log_scroll.scroll_vertical = int(vbar.max_value)

## Builds the combatant snapshot once and refreshes rows. Returns the snapshot for reuse in the same frame.
func _update_ui() -> Array:
	if manager == null:
		return []
	var caps: Array = manager.get_combatants()
	for c in caps:
		var cid_ui: int = _EntityAccess.id_int(c)
		if cid_ui in id_to_controls:
			BattleUIUpdater.update_combatant_row(id_to_controls[cid_ui], c, manager)
	_sync_formation_diagrams_for_tactical_hints(caps)
	return caps


func _tactical_diagram_signature(caps: Array) -> String:
	var parts: PackedStringArray = []
	for raw in caps:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = raw as Dictionary
		if not _EntityAccess.alive_bool(c, true):
			continue
		var chunks: PackedStringArray = []
		var sfx: String = _UiHints.footwork_diagram_suffix(c).strip_edges()
		if not sfx.is_empty():
			chunks.append("sfx=%s" % sfx)
		var fw: String = _UiHints.footwork_hint_text(c)
		if not fw.is_empty():
			chunks.append("fw=%s" % fw)
		var attn: String = _UiHints.attention_hint_text(c)
		if not attn.is_empty():
			chunks.append("a=%s" % attn)
		var tempo: String = _UiHints.counter_tempo_hint_key(c, manager)
		if not tempo.is_empty():
			chunks.append("t=%s" % tempo)
		if chunks.is_empty():
			continue
		parts.append("%d:%s" % [_EntityAccess.id_int(c), "|".join(chunks)])
	parts.sort()
	return "|".join(parts)


func _sync_formation_diagrams_for_tactical_hints(caps: Array) -> void:
	var any_tactical: bool = _UiHints.any_tactical_features_enabled()
	if not any_tactical:
		if not _diagram_footwork_sig.is_empty():
			_diagram_footwork_sig = ""
			if formation_diagram_player != null:
				_FormationDiagramBuilder.refresh(formation_diagram_player)
			if formation_diagram_enemy != null:
				_FormationDiagramBuilder.refresh(formation_diagram_enemy)
		return
	var sig: String = _tactical_diagram_signature(caps)
	if sig == _diagram_footwork_sig:
		return
	_diagram_footwork_sig = sig
	if formation_diagram_player != null:
		_FormationDiagramBuilder.refresh(formation_diagram_player)
	if formation_diagram_enemy != null:
		_FormationDiagramBuilder.refresh(formation_diagram_enemy)

func _process(_delta: float) -> void:
	# keep UI in sync with manager (single snapshot per frame)
	var caps: Array = _update_ui()
	# Medical phase: show End battle when all wounded are stabilized
	if _in_medical_phase and manager != null and manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase():
		_show_end_battle_button()
		# After medical actions are done and everyone is paused (no one in wind_up/medical_wind_up), announce once
		if not _medical_phase_finished_announced:
			var anyone_busy: bool = false
			for c in caps:
				if not _EntityAccess.alive_bool(c, true):
					continue  # Only alive combatants can be "busy"; dead enemies may still have wind_up state
				var s: String = _EntityAccess.state_str(c, "waiting")
				if s == "wind_up" or s == "medical_wind_up":
					anyone_busy = true
					break
			if not anyone_busy:
				_medical_phase_finished_announced = true
				if combat_log:
					combat_log.append_text("\n[color=green]——— Medical phase finished. You may end the battle. ———[/color]\n")
					_scroll_combat_log_to_bottom()

func _on_combatant_health_changed(_combatant_id: int) -> void:
	# Refresh UI when consciousness/pain/blood changes (driven by health_changed signal from entity)
	_update_ui()

func _on_formation_changed(_side: String) -> void:
	_diagram_footwork_sig = ""
	if formation_diagram_player != null:
		_FormationDiagramBuilder.refresh(formation_diagram_player)
	if formation_diagram_enemy != null:
		_FormationDiagramBuilder.refresh(formation_diagram_enemy)


func _on_engagement_state_changed(_formation_id: String, _line_cohesion: float, _engagement_posture: String) -> void:
	_sync_engagement_labels_from_manager()


func _sync_engagement_labels_from_manager() -> void:
	if manager == null:
		return
	if _enemy_engagement_label != null:
		_enemy_engagement_label.text = _format_engagement_line(
			_FormationSlots.formation_record_for_manager(manager, "enemy"), "enemy"
		)
	if _player_engagement_label != null:
		_player_engagement_label.text = _format_engagement_line(
			_FormationSlots.formation_record_for_manager(manager, "player"), "player"
		)


func _format_engagement_line(form: Dictionary, formation_id: String) -> String:
	if form.is_empty():
		return "—"
	var mode_disp: String = "—"
	if manager != null:
		mode_disp = _EngagementMode.mode_display_name(_EngagementMode.engagement_mode(manager))
	var posture: String = str(form.get("engagement_posture", "—"))
	var coh: float = float(form.get("line_cohesion", 0.0))
	var line: String = "%s · %s · cohesion %d%%" % [mode_disp, posture.capitalize(), int(roundf(coh * 100.0))]
	if manager != null and manager.has_method("get_formation_doctrine"):
		var doc: String = str(manager.get_formation_doctrine(formation_id))
		if doc != CombatConstants.DOCTRINE_DEFAULT and not doc.is_empty():
			line += " · %s" % doc.replace("_", " ").capitalize()
	return line


func _on_combat_ui_hint(message: String) -> void:
	if combat_log == null or str(message).strip_edges().is_empty():
		return
	combat_log.append_text("[color=#aab0c0]%s[/color]\n" % str(message))
	_scroll_combat_log_to_bottom()

func _on_turn_ready(combatant_id: int) -> void:
	_TurnReadyHandler.handle(manager, combatant_id)

func _append_combat_log(attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary) -> void:
	if combat_log == null:
		return
	var line: String = CombatLogFormatter.format_action_line(attacker_name, attacker_side, target_name, target_side, result)
	combat_log.append_text(line + "\n")
	# Trim old lines (RichTextLabel doesn't have line limit; approximate by newline count)
	var text: String = combat_log.text
	var lines: PackedStringArray = text.split("\n")
	if lines.size() > BattleUIConstants.LOG_MAX_LINES:
		combat_log.text = "\n".join(lines.slice(-BattleUIConstants.LOG_MAX_LINES, lines.size()))
	_scroll_combat_log_to_bottom()

func _on_action_resolved(attacker_id: int, target_id: int, result: Dictionary) -> void:
	var atk = manager._get_by_id(attacker_id) if manager and manager.has_method("_get_by_id") else null
	var tgt = manager._get_by_id(target_id) if manager and manager.has_method("_get_by_id") else null
	var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
	var atk_side: String = _EntityAccess.side_str(atk) if atk != null else ""
	var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
	var tgt_side: String = _EntityAccess.side_str(tgt) if tgt != null else ""
	_append_combat_log(atk_name, atk_side, tgt_name, tgt_side, result)
	# Show last hit on target row (prefers total_physical so fractional chips still show)
	var part: String = result.get("part", "")
	var show_hit: bool = not part.is_empty() and CombatLogFormatter.has_resolved_physical_damage(result)
	if target_id in id_to_controls and id_to_controls[target_id].get("last_hit_label"):
		var lbl: Label = id_to_controls[target_id].last_hit_label
		if show_hit:
			lbl.text = CombatLogFormatter.format_last_hit_on_target_row(result)
		elif result.get("died", false) and not show_hit:
			lbl.text = "No targetable parts"
		else:
			lbl.text = ""
	_update_ui()

func _on_enemies_eliminated(winner_side: String) -> void:
	_pending_winner = winner_side
	_pending_defeated = null
	_in_medical_phase = true
	_medical_phase_finished_announced = false
	print("[Combat] BattleScene: enemies_eliminated => medical phase started, winner=%s" % winner_side)
	if combat_log:
		combat_log.append_text("\n[color=orange]——— Enemies eliminated. Medical phase: stabilize your wounded before ending. ———[/color]\n")
		_scroll_combat_log_to_bottom()
	# End battle button shown when can_end_medical_phase() (polled in _process)

func _on_combat_ended(winner_side: String, defeated_node: Node) -> void:
	_pending_winner = winner_side
	_pending_defeated = defeated_node
	var def_name: String = str(defeated_node.name) if defeated_node != null else "null"
	print("[Combat] BattleScene: combat_ended => winner=%s defeated=%s" % [winner_side, def_name])
	if combat_log:
		combat_log.append_text("\n[color=yellow]——— Combat ended. Winner: %s ———[/color]\n" % winner_side)
		_scroll_combat_log_to_bottom()
	# Enemy won: show End battle immediately. Player won: handled by _on_enemies_eliminated (medical phase first).
	if winner_side == "enemy":
		_show_end_battle_button()

func _show_end_battle_button() -> void:
	if end_battle_button != null:
		return
	var content_vbox = get_node_or_null("CombatCanvasLayer/UIRoot/ContentVBox")
	if content_vbox == null:
		return
	print("[Combat] BattleScene: showing End battle button, pausing manager (can_end_medical_phase=true)")
	# Pause combat loop: no more gauge fills or turn cycling until End battle is pressed
	if manager != null:
		manager.set_process(false)
	end_battle_button = Button.new()
	end_battle_button.name = "EndBattleButton"
	end_battle_button.text = "End battle"
	end_battle_button.custom_minimum_size = Vector2(160, 44)
	end_battle_button.pressed.connect(_on_end_battle_button_pressed)
	content_vbox.add_child(end_battle_button)
	# Button changes layout; scroll again after layout settles so "Combat ended" stays visible
	call_deferred("_scroll_combat_log_to_bottom")

func _on_end_battle_button_pressed() -> void:
	if _in_medical_phase and manager != null and manager.has_method("finish_battle"):
		manager.finish_battle()
	emit_signal("battle_ended", _pending_winner, _pending_defeated)
	queue_free()

func _exit_tree() -> void:
	# Restore visibility of the parent scene when this battle UI is removed
	if parent_scene != null:
		parent_scene.visible = true
