class_name BattleUILayout
extends RefCounted

## Builds the combat UI layout: canvas layer, overlay, panels, scroll area, combat log.
## Returns { "canvas_layer": CanvasLayer, "combat_log": RichTextLabel, "combat_log_scroll": ScrollContainer }.
## Parent receives the built nodes as children.

static func create(parent: Node) -> Dictionary:
	# Canvas layer root (ensures UI is on top)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "CombatCanvasLayer"
	parent.add_child(canvas_layer)

	# Root control (full rect) to host overlay + content (content on top so it's visible)
	var ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(ui_root)

	# Dim overlay first (drawn underneath; blocks input to world behind)
	var overlay = ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)

	# Content on top: formation diagram, main panels, combat log
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_theme_constant_override("separation", 8)
	ui_root.add_child(content_vbox)

	# Formation diagram: compact rank×file view (enemies | party) — shows positions, updates on swap
	var formation_header = Label.new()
	formation_header.text = "Formation (Front / Back)"
	formation_header.add_theme_font_size_override("font_size", 12)
	formation_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	formation_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(formation_header)
	var formation_hbox = HBoxContainer.new()
	formation_hbox.name = "FormationDiagramHBox"
	formation_hbox.add_theme_constant_override("separation", 16)
	formation_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_vbox.add_child(formation_hbox)

	# Creature stats: static list, never moves (separate from formation diagram above)
	var stats_header = Label.new()
	stats_header.text = "Creature stats"
	stats_header.add_theme_font_size_override("font_size", 12)
	stats_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(stats_header)

	# Scrollable area for enemy/player panels (scrolls when many combatants, combat log stays fixed below)
	var main_scroll = ScrollContainer.new()
	main_scroll.name = "MainScroll"
	main_scroll.custom_minimum_size = Vector2(0, 260)
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_vbox.add_child(main_scroll)

	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 16)
	main_scroll.add_child(main_hbox)

	# Column 1: Enemies panel
	var enemy_panel = Panel.new()
	enemy_panel.name = "EnemyPanel"
	enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(enemy_panel)

	var enemy_vbox = VBoxContainer.new()
	enemy_vbox.name = "EnemyVBox"
	enemy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_panel.add_child(enemy_vbox)

	var enemy_title = Label.new()
	enemy_title.text = "Enemies"
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_vbox.add_child(enemy_title)

	var enemy_list = GridContainer.new()
	enemy_list.name = "EnemyList"
	enemy_list.columns = 2
	enemy_list.add_theme_constant_override("h_separation", 12)
	enemy_list.add_theme_constant_override("v_separation", 8)
	enemy_list.size_flags_vertical = Control.SIZE_SHRINK_END
	enemy_vbox.add_child(enemy_list)

	# Column 2: Party panel
	var player_panel = Panel.new()
	player_panel.name = "PlayerPanel"
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(player_panel)

	var player_vbox = VBoxContainer.new()
	player_vbox.name = "PlayerVBox"
	player_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_panel.add_child(player_vbox)

	var player_title = Label.new()
	player_title.text = "Party"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(player_title)

	var player_list = GridContainer.new()
	player_list.name = "PlayerList"
	player_list.columns = 2
	player_list.add_theme_constant_override("h_separation", 12)
	player_list.add_theme_constant_override("v_separation", 8)
	player_list.size_flags_vertical = Control.SIZE_SHRINK_END
	player_vbox.add_child(player_list)

	# Combat log panel (below main panels)
	var log_sep = HSeparator.new()
	log_sep.name = "LogSeparator"
	log_sep.custom_minimum_size = Vector2(0, 12)
	content_vbox.add_child(log_sep)
	var log_title = Label.new()
	log_title.text = "Combat log"
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(log_title)
	var combat_log_scroll = ScrollContainer.new()
	combat_log_scroll.name = "CombatLogScroll"
	combat_log_scroll.custom_minimum_size = Vector2(BattleUIConstants.LOG_MIN_WIDTH, BattleUIConstants.LOG_MIN_HEIGHT)
	combat_log_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
	combat_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(combat_log_scroll)
	var combat_log = RichTextLabel.new()
	combat_log.name = "CombatLog"
	combat_log.bbcode_enabled = true
	combat_log.fit_content = true
	combat_log.scroll_following = true
	combat_log.selection_enabled = false
	combat_log.custom_minimum_size = Vector2(BattleUIConstants.LOG_MIN_WIDTH, 192)
	combat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_log.add_theme_color_override("default_color", Color(0.95, 0.95, 0.9))
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 0.95)
	style.set_content_margin_all(6)
	combat_log.add_theme_stylebox_override("normal", style)
	combat_log_scroll.add_child(combat_log)

	return {
		"canvas_layer": canvas_layer,
		"combat_log": combat_log,
		"combat_log_scroll": combat_log_scroll,
		"formation_diagram_hbox": formation_hbox
	}
