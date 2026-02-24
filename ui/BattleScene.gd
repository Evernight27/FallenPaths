extends Node

signal battle_ended(winner: String, defeated: Node)

var players: Array = []
var enemies: Array = []
var parent_scene: Node = null

# Body part order for UI; layout matches party screen: rows of [head, chest], [arms], [legs]
const BODY_PARTS := ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]
const BODY_LABELS := {"head": "Head", "chest": "Chest", "right_arm": "R.Arm", "left_arm": "L.Arm", "left_leg": "L.Leg", "right_leg": "R.Leg"}
const PART_LINES := [["head", "chest"], ["right_arm", "left_arm"], ["left_leg", "right_leg"]]

# manager & combat ids
var manager: Node = null
var id_to_controls := {} # map combatant id -> {row, name, body_bars, body_labels, gauge, gauge_label, node}
var combat_log: RichTextLabel = null
var combat_log_scroll: ScrollContainer = null
var end_battle_button: Button = null
var _pending_winner: String = ""
var _pending_defeated: Node = null
const LOG_MAX_LINES := 80
const MAIN_LIST_PATH := "CombatCanvasLayer/UIRoot/ContentVBox/MainScroll/MainHBox"

# UI nodes
var canvas_layer: CanvasLayer

func _ready() -> void:
	# Processing will be enabled by start()
	set_process(false)

func start(p_players, p_enemies) -> void:
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

	_create_ui()
	_update_ui()

	# setup combat manager
	var mgr_script = load("res://ui/CombatManager.gd")
	if mgr_script == null:
		print("CombatManager missing")
		return
	manager = mgr_script.new()
	add_child(manager)
	# register combatants
	for pl in players:
		var pid = manager.register(pl, "player")
		_create_ui_row(pid, pl, "player")
	for en in enemies:
		var eid = manager.register(en, "enemy")
		_create_ui_row(eid, en, "enemy")
	# Ensure ScrollContainer child has proper minimum size so scrolling works (wait for layout)
	await get_tree().process_frame
	await get_tree().process_frame
	_update_scroll_content_size()
	# connect signals
	manager.connect("turn_ready", Callable(self, "_on_turn_ready"))
	manager.connect("action_resolved", Callable(self, "_on_action_resolved"))
	manager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	manager.connect("combatant_health_changed", Callable(self, "_on_combatant_health_changed"))
	# start the manager
	manager.start()
	set_process(true)

func _update_scroll_content_size() -> void:
	var main_scroll = get_node_or_null("CombatCanvasLayer/UIRoot/ContentVBox/MainScroll")
	var main_hbox = get_node_or_null(MAIN_LIST_PATH)
	if main_hbox == null or not main_hbox is Control or main_scroll == null:
		return
	# ScrollContainer only shows scrollbar when child min size exceeds container size.
	# get_combined_minimum_size() can be unreliable with nested containers, so we also
	# calculate from actual row count (each combatant row ~180px).
	var content_min = main_hbox.get_combined_minimum_size()
	var row_count = players.size() + enemies.size()
	var estimated_height = row_count * 180
	var scroll_height = main_scroll.size.y
	var min_height = maxf(maxf(content_min.y, estimated_height), scroll_height + 1)
	main_hbox.custom_minimum_size = Vector2(content_min.x, min_height)

func _create_ui() -> void:
	# Canvas layer root (ensures UI is on top)
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "CombatCanvasLayer"
	add_child(canvas_layer)

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
	enemy_list_vbox.size_flags_vertical = Control.SIZE_SHRINK_END  # Size to content so ScrollContainer can scroll
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
	player_list_vbox.size_flags_vertical = Control.SIZE_SHRINK_END  # Size to content so ScrollContainer can scroll
	player_vbox.add_child(player_list_vbox)

	# Combat log panel (below main panels) — spacing above so it doesn't overlap
	const LOG_MIN_WIDTH := 420
	const LOG_MIN_HEIGHT := 140
	var log_sep = HSeparator.new()
	log_sep.name = "LogSeparator"
	log_sep.custom_minimum_size = Vector2(0, 20)
	content_vbox.add_child(log_sep)
	var log_title = Label.new()
	log_title.text = "Combat log"
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(log_title)
	combat_log_scroll = ScrollContainer.new()
	combat_log_scroll.name = "CombatLogScroll"
	combat_log_scroll.custom_minimum_size = Vector2(LOG_MIN_WIDTH, LOG_MIN_HEIGHT)
	combat_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(combat_log_scroll)
	combat_log = RichTextLabel.new()
	combat_log.name = "CombatLog"
	combat_log.bbcode_enabled = true
	combat_log.fit_content = true
	combat_log.scroll_following = true
	combat_log.selection_enabled = false
	combat_log.custom_minimum_size = Vector2(LOG_MIN_WIDTH, 120)
	combat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Ensure log is visible: dark background, light text
	combat_log.add_theme_color_override("default_color", Color(0.95, 0.95, 0.9))
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 0.95)
	style.set_content_margin_all(6)
	combat_log.add_theme_stylebox_override("normal", style)
	combat_log_scroll.add_child(combat_log)

func _scroll_combat_log_to_bottom() -> void:
	if combat_log_scroll == null:
		return
	# Layout updates next frame; scrollbar max_value is stale until then
	call_deferred("_do_scroll_combat_log_to_bottom")

func _do_scroll_combat_log_to_bottom() -> void:
	if combat_log_scroll == null:
		return
	var vbar = combat_log_scroll.get_v_scroll_bar()
	if vbar:
		combat_log_scroll.scroll_vertical = int(vbar.max_value)

func _create_ui_row(id: int, node: Node, side: String) -> void:
	# Row: name, gauge, equipment (weapon + armor), then 6 body part bars
	var row = VBoxContainer.new()
	row.name = "combat_row_%d" % id
	var top_row = HBoxContainer.new()
	var name_lbl = Label.new()
	name_lbl.text = str(node.name) if node != null else "Entity"
	name_lbl.custom_minimum_size = Vector2(60, 0)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_lbl)
	var gauge = ProgressBar.new()
	gauge.min_value = 0.0
	gauge.max_value = 100.0
	gauge.value = 0.0
	gauge.custom_minimum_size = Vector2(60, 14)
	top_row.add_child(gauge)
	var gauge_lbl = Label.new()
	gauge_lbl.name = "GaugeLabel"
	gauge_lbl.text = "0%"
	gauge_lbl.custom_minimum_size = Vector2(36, 0)
	top_row.add_child(gauge_lbl)
	row.add_child(top_row)
	var last_hit_lbl = Label.new()
	last_hit_lbl.name = "LastHitLabel"
	last_hit_lbl.text = ""
	last_hit_lbl.add_theme_font_size_override("font_size", 11)
	last_hit_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	row.add_child(last_hit_lbl)
	# Blood volume and bleeding (medical realism)
	var blood_row = HBoxContainer.new()
	blood_row.name = "BloodRow"
	var blood_lbl = Label.new()
	blood_lbl.name = "BloodLabel"
	blood_lbl.text = "Blood: 100%"
	blood_lbl.add_theme_font_size_override("font_size", 11)
	blood_lbl.custom_minimum_size = Vector2(70, 0)
	blood_row.add_child(blood_lbl)
	var blood_bar = ProgressBar.new()
	blood_bar.name = "BloodBar"
	blood_bar.min_value = 0.0
	blood_bar.max_value = 100.0
	blood_bar.value = 100.0
	blood_bar.custom_minimum_size = Vector2(60, 10)
	blood_bar.show_percentage = false
	blood_row.add_child(blood_bar)
	var bleeding_lbl = Label.new()
	bleeding_lbl.name = "BleedingLabel"
	bleeding_lbl.text = ""
	bleeding_lbl.add_theme_font_size_override("font_size", 11)
	bleeding_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
	blood_row.add_child(bleeding_lbl)
	row.add_child(blood_row)
	# Consciousness and performance (pain/consciousness modifier for gauge fill, hit chance, etc.)
	var consc_row = HBoxContainer.new()
	consc_row.name = "ConsciousnessRow"
	var consc_lbl = Label.new()
	consc_lbl.name = "ConsciousnessLabel"
	consc_lbl.text = "Pain: 0 | Consc: 100% | Perf: 100%"
	consc_lbl.add_theme_font_size_override("font_size", 10)
	consc_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.9))
	consc_row.add_child(consc_lbl)
	row.add_child(consc_row)
	var equip_parts: Array = []
	if node != null and node.has_method("get_weapon"):
		var w = node.get_weapon()
		if w != null:
			var wn: String = w.display_name if w.display_name else (w.weapon_type if w.weapon_type else "?")
			equip_parts.append("Weapon: %s" % wn)
	if node != null and node.has_method("get_armor_slots"):
		var slots = node.get_armor_slots()
		var armor_names: Array = []
		for part in slots.keys():
			var piece = slots[part]
			if piece != null and piece.get("display_name"):
				armor_names.append(piece.display_name)
		if armor_names.size() > 0:
			equip_parts.append("Armor: " + ", ".join(armor_names))
	if equip_parts.size() > 0:
		var equip_lbl = Label.new()
		equip_lbl.name = "EquipLabel"
		equip_lbl.text = "  ".join(equip_parts)
		equip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		equip_lbl.custom_minimum_size = Vector2(0, 0)
		row.add_child(equip_lbl)
	var bars_vbox = VBoxContainer.new()
	var body_bars := {}
	var body_labels := {}
	for part_line in PART_LINES:
		var bars_row = HBoxContainer.new()
		for part in part_line:
			var cell = VBoxContainer.new()
			cell.custom_minimum_size = Vector2(48, 0)
			var lbl = Label.new()
			lbl.name = "lbl_%s" % part
			lbl.text = BODY_LABELS.get(part, part) + " 0/0"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(lbl)
			body_labels[part] = lbl
			var bar = ProgressBar.new()
			bar.min_value = 0.0
			bar.max_value = 1.0
			bar.value = 1.0
			bar.custom_minimum_size = Vector2(48, 12)
			bar.show_percentage = false
			cell.add_child(bar)
			body_bars[part] = bar
			bars_row.add_child(cell)
		bars_vbox.add_child(bars_row)
	row.add_child(bars_vbox)
	if side == "player":
		var list = get_node(MAIN_LIST_PATH + "/PlayerPanel/PlayerVBox/PlayerList") if has_node(MAIN_LIST_PATH + "/PlayerPanel/PlayerVBox/PlayerList") else null
		if list:
			list.add_child(row)
	else:
		var list = get_node(MAIN_LIST_PATH + "/EnemyPanel/EnemyVBox/EnemyList") if has_node(MAIN_LIST_PATH + "/EnemyPanel/EnemyVBox/EnemyList") else null
		if list:
			list.add_child(row)
	id_to_controls[id] = {"row": row, "name": name_lbl, "body_bars": body_bars, "body_labels": body_labels, "gauge": gauge, "gauge_label": gauge_lbl, "last_hit_label": last_hit_lbl, "blood_label": blood_lbl, "blood_bar": blood_bar, "bleeding_label": bleeding_lbl, "consciousness_label": consc_lbl, "node": node}

func _update_ui() -> void:
	if manager == null:
		return
	var caps = manager.get_combatants()
	for c in caps:
		if c.id in id_to_controls:
			var ctrl = id_to_controls[c.id]
			if ctrl.name:
				ctrl.name.text = str(c.node.name) if c.node != null else ctrl.name.text
			if ctrl.gauge:
				var state: String = c.get("state", "waiting")
				# Action bar only shows fill when waiting (charging next turn); stays empty during swing/medical/recovery
				if state == "wind_up" or state == "medical_wind_up" or state == "recovering":
					ctrl.gauge.value = 0.0
				else:
					ctrl.gauge.value = c.gauge
			if ctrl.get("gauge_label"):
				var state: String = c.get("state", "waiting")
				var state_timer: float = c.get("state_timer", 0.0)
				var state_duration: float = c.get("state_duration", 0.0)
				if state == "wind_up":
					var remain: float = maxf(0.0, state_duration - state_timer)
					ctrl.gauge_label.text = "Wind-up %.1fs" % remain
				elif state == "medical_wind_up":
					var remain: float = maxf(0.0, state_duration - state_timer)
					ctrl.gauge_label.text = "Medical %.1fs" % remain
				elif state == "recovering":
					var remain: float = maxf(0.0, state_duration - state_timer)
					ctrl.gauge_label.text = "Recov. %.1fs" % remain
				else:
					ctrl.gauge_label.text = "Ready!" if c.gauge >= 100.0 else "%d%%" % int(c.gauge)
			# Blood volume and bleeding
			if ctrl.get("blood_label"):
				var bv: float = c.stats.get("blood_volume", 100.0)
				ctrl.blood_label.text = "Blood: %d%%" % int(clampf(bv, 0.0, 100.0))
			if ctrl.get("blood_bar"):
				var bv: float = c.stats.get("blood_volume", 100.0)
				ctrl.blood_bar.value = clampf(bv, 0.0, 100.0)
			if ctrl.get("bleeding_label"):
				var rate: float = c.stats.get("total_bleeding_rate", 0.0)
				ctrl.bleeding_label.text = "Bleeding: %.1f/s" % rate if rate > 0.0 else ""
			if ctrl.get("consciousness_label"):
				var pain: float = c.stats.get("total_pain", 0.0)
				var consc: float = c.stats.get("effective_consciousness", 100.0)
				var perf: float = c.stats.get("performance_modifier", 1.0)
				ctrl.consciousness_label.text = "Pain: %.1f | Consc: %d%% | Perf: %d%%" % [pain, int(clampf(consc, 0.0, 100.0)), int(roundf(perf * 100.0))]
			if "body_bars" in ctrl and ctrl.body_bars:
				var bc: Dictionary = c.stats.get("body_cutting", {})
				var bb: Dictionary = c.stats.get("body_blunt", {})
				var bm: Dictionary = c.stats.get("body_max", {})
				var bone_h: Dictionary = c.stats.get("bone_health", {})
				var bone_m: Dictionary = c.stats.get("bone_max", {})
				for part in BODY_PARTS:
					if part in ctrl.body_bars:
						var bar: ProgressBar = ctrl.body_bars[part]
						var c_cur: float = bc.get(part, 0.0)
						var b_cur: float = bb.get(part, 0.0)
						var mx = max(1, bm.get(part, 1))
						var worst: float = minf(c_cur, b_cur)
						bar.max_value = float(mx)
						bar.value = worst
						bar.visible = mx > 0
						if part in ctrl.get("body_labels", {}):
							var bo_cur: float = bone_h.get(part, 0.0)
							var bo_mx: int = bone_m.get(part, 0)
							ctrl.body_labels[part].text = BODY_LABELS.get(part, part) + " C:%.2f/%.0f B:%.2f/%.0f Bo:%.2f/%d" % [c_cur, mx, b_cur, mx, bo_cur, bo_mx]
							ctrl.body_labels[part].visible = mx > 0

func _process(_delta: float) -> void:
	# keep UI in sync with manager
	_update_ui()

func _on_combatant_health_changed(_combatant_id: int) -> void:
	# Refresh UI when consciousness/pain/blood changes (driven by health_changed signal from entity)
	_update_ui()

func _on_turn_ready(combatant_id: int) -> void:
	if manager == null:
		return
	var caps = manager.get_combatants()
	var me = {}
	for c in caps:
		if c.id == combatant_id:
			me = c
			break
	if me.is_empty():
		return
	if me.side == "player":
		var actions: Array = manager.get_available_actions(combatant_id)
		if actions.is_empty():
			for c in caps:
				if c.side != "player" and c.alive:
					manager.resolve_action(combatant_id, c.id)
					return
		else:
			# Weighted choice: medical by urgency, else attack.
			var choice = manager.pick_weighted_action(actions, combatant_id)
			var opts: Dictionary = {}
			if choice.get("target_part", "") != "":
				opts["target_part"] = choice.target_part
			manager.resolve_action(combatant_id, choice.target_id, choice.get("move_id", ""), opts)

func _append_combat_log(attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary) -> void:
	if combat_log == null:
		return
	var part: String = result.get("part", "")
	var dmg: int = result.get("dmg", 0)
	var died: bool = result.get("died", false)
	var outcome: String = result.get("outcome", "hit")
	var health_before: int = result.get("health_before", -1)
	var health_after: int = result.get("health_after", -1)
	var part_label: String = BODY_LABELS.get(part, part) if part else "—"
	var line: String
	if died and dmg == 0:
		if outcome == "bled_out":
			line = "[color=red]%s (%s) — %s bled out.[/color]" % [attacker_name, attacker_side, target_name]
		else:
			line = "[color=gray]%s (%s) — %s had no targetable parts.[/color]" % [attacker_name, attacker_side, target_name]
	elif outcome == "miss":
		line = "[color=gray]%s (%s) → %s (%s): [b]Miss![/b][/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "dodge":
		line = "[color=green]%s (%s) → %s (%s): [b]Dodge![/b][/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "skip":
		line = "[color=gray]%s (%s) — no functional arm; skips attack.[/color]" % [attacker_name, attacker_side]
	elif outcome == "parry_deflect":
		line = "[color=cyan]%s (%s) parried %s (%s)'s attack.[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "deflected":
		line = "%s (%s) → %s (%s) %s: [b]%d[/b] dmg [color=orange](deflected)[/color]" % [attacker_name, attacker_side, target_name, target_side, part_label, dmg]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		elif health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
	else:
		line = "%s (%s) → %s (%s) %s: [b]%d[/b] dmg" % [attacker_name, attacker_side, target_name, target_side, part_label, dmg]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		if health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
		if died:
			line += " [color=red](defeated)[/color]"
	combat_log.append_text(line + "\n")
	# Trim old lines (RichTextLabel doesn't have line limit; approximate by newline count)
	var text: String = combat_log.text
	var lines: PackedStringArray = text.split("\n")
	if lines.size() > LOG_MAX_LINES:
		combat_log.text = "\n".join(lines.slice(-LOG_MAX_LINES, lines.size()))
	_scroll_combat_log_to_bottom()

func _on_action_resolved(attacker_id: int, target_id: int, result: Dictionary) -> void:
	var caps = manager.get_combatants() if manager else []
	var atk_name: String = "?"
	var atk_side: String = ""
	var tgt_name: String = "?"
	var tgt_side: String = ""
	for c in caps:
		if c.id == attacker_id:
			atk_name = str(c.node.name) if c.node != null else "id:%d" % attacker_id
			atk_side = c.side
		if c.id == target_id:
			tgt_name = str(c.node.name) if c.node != null else "id:%d" % target_id
			tgt_side = c.side
	_append_combat_log(atk_name, atk_side, tgt_name, tgt_side, result)
	# Show last hit on target row
	var part: String = result.get("part", "")
	var dmg: int = result.get("dmg", 0)
	if target_id in id_to_controls and id_to_controls[target_id].get("last_hit_label"):
		var lbl: Label = id_to_controls[target_id].last_hit_label
		if part and dmg > 0:
			lbl.text = "Hit: %s -%d" % [BODY_LABELS.get(part, part), dmg]
		elif result.get("died", false) and dmg == 0:
			lbl.text = "No targetable parts"
		else:
			lbl.text = ""
	_update_ui()

func _on_combat_ended(winner_side: String, defeated_node: Node) -> void:
	_pending_winner = winner_side
	_pending_defeated = defeated_node
	if combat_log:
		combat_log.append_text("\n[color=yellow]——— Combat ended. Winner: %s ———[/color]\n" % winner_side)
		_scroll_combat_log_to_bottom()
	# Show "End battle" button so the player can review the log before closing
	_show_end_battle_button()

func _show_end_battle_button() -> void:
	if end_battle_button != null:
		return
	var content_vbox = get_node_or_null("CombatCanvasLayer/UIRoot/ContentVBox")
	if content_vbox == null:
		return
	end_battle_button = Button.new()
	end_battle_button.name = "EndBattleButton"
	end_battle_button.text = "End battle"
	end_battle_button.custom_minimum_size = Vector2(160, 44)
	end_battle_button.pressed.connect(_on_end_battle_button_pressed)
	content_vbox.add_child(end_battle_button)
	# Button changes layout; scroll again after layout settles so "Combat ended" stays visible
	call_deferred("_scroll_combat_log_to_bottom")

func _on_end_battle_button_pressed() -> void:
	emit_signal("battle_ended", _pending_winner, _pending_defeated)
	queue_free()

func _exit_tree() -> void:
	# Restore visibility of the parent scene when this battle UI is removed
	if parent_scene != null:
		parent_scene.visible = true
