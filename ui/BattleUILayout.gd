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

	# Content on top: main panels + combat log (so panels and log are visible above overlay)
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_theme_constant_override("separation", 8)
	ui_root.add_child(content_vbox)

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
	main_scroll.add_child(main_hbox)

	# Left panel for enemies (list)
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

	var enemy_list_vbox = VBoxContainer.new()
	enemy_list_vbox.name = "EnemyList"
	enemy_list_vbox.size_flags_vertical = Control.SIZE_SHRINK_END
	enemy_vbox.add_child(enemy_list_vbox)

	# Separator between enemy and player panels
	var middle_sep = VSeparator.new()
	middle_sep.name = "MiddleSeparator"
	middle_sep.custom_minimum_size = Vector2(24, 0)
	main_hbox.add_child(middle_sep)

	# Right panel for players (list)
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

	var player_list_vbox = VBoxContainer.new()
	player_list_vbox.name = "PlayerList"
	player_list_vbox.size_flags_vertical = Control.SIZE_SHRINK_END
	player_vbox.add_child(player_list_vbox)

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
		"combat_log_scroll": combat_log_scroll
	}
