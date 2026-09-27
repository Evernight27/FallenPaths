extends Node2D

## Gladiator school (XCamp-6 playable slice): a UI-first replacement for the movement overworld.
##
## The player runs a company of gladiators from a single management screen—no tile movement:
##   - Roster: hire fighters, drill stats / forms / weapons (queued, applied at camp rest via
##     CompanyState.train_*), and manage gear + field care through the shared Party manager.
##   - Rival schools: dispatch scouts (dossier intel), appoint match lineups, and book an arena day.
##   - Arena nights: bouts fight 1v1 through the normal encounter pipeline (single-fighter lock,
##     CompanyMatch.build_current_bout_encounter -> CombatFlow.start_combat) and resolve into
##     gold / renown / fame through CompanyGladiator.finalize_bout.
##
## Reuses the shared company world (PartySetup, CompanyState and its split modules) so nothing here
## owns persistence; the scene script is container + UI glue only.

const FORMS: Array = ["wall", "ox", "balanced", "plow", "tempest", "wrath"]
const WEAPON_TRAIN_IDS: Array = ["SWORD", "SPEAR", "AXE", "MACE", "DAGGER"]
const ARENA_DAY_OPTIONS: int = 5

@export var dev_research_feel: bool = false
@export var dev_hit_summary: bool = true

var rng := RandomNumberGenerator.new()

@onready var player: Node2D = $Character

var _ui_layer: CanvasLayer
var _status_label: RichTextLabel
var _log_label: RichTextLabel
var _roster_box: VBoxContainer
var _schools_box: VBoxContainer
var _match_box: VBoxContainer
var _busy: bool = false


func _ready() -> void:
	if OS.get_cmdline_args().has("--tuning"):
		get_tree().change_scene_to_file("res://tools/combat_tuning/combat_tuning.tscn")
		return
	if dev_research_feel:
		CombatConstants.set_combat_dev_verbose_override(true)
	if OS.has_feature("editor"):
		OperationalLog.begin_play_session("res://scenes/gladiator/gladiator.tscn", "", dev_research_feel, dev_hit_summary)
		CombatF5SoakTrace.reset_session_camp_trace()
		CombatF5SoakTrace.prepare_fight_end_log()

	var main_window := get_tree().root
	main_window.content_scale_size = Vector2i(1920, 1080)
	main_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	main_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	main_window.mode = Window.MODE_MAXIMIZED

	# Same as the campaign boot: yield one frame so the SceneTree finishes instantiating the packed
	# scene before the shared company UI (root overlay + Party menu) attaches to the root.
	await get_tree().process_frame

	rng.randomize()
	# Fresh company each session unless a P2 autosave exists (mirrors the campaign boot).
	var boot_save: Dictionary = {}
	if CompanyState.persistence_uses_disk_autosave():
		boot_save = CompanyState.load_campaign_autosave_for_boot()
	var restoring_campaign_save: bool = not boot_save.is_empty()

	PlayerCompanionSetup.setup_player_and_companion(self, rng)
	PartySetup.setup_party(self)
	if restoring_campaign_save:
		CompanyState.restore_campaign_autosave_on_main(self, boot_save, rng, null)
		if OperationalLog.is_play_session_active():
			OperationalLog.play_world(
				"gladiator_school_restore path=%s gold=%d day=%d"
				% [CampaignPersistence.SAVE_PATH, CompanyState.get_gold(self), CompanyState.get_day_index(self)]
			)
	else:
		if OperationalLog.is_play_session_active():
			OperationalLog.play_world("gladiator_school_boot fresh=true gold=%d day=%d"
			% [CompanyState.get_gold(self), CompanyState.get_day_index(self)])

	_build_ui()
	# Keep the roster/status panels honest when the shared Party manager popup closes.
	var _pm: Variant = get_meta("party_manager") if has_meta("party_manager") else null
	var menu: Variant = get_meta("party_menu") if has_meta("party_menu") else null
	if menu is PopupPanel:
		(menu as PopupPanel).popup_hide.connect(rebuild_all)
	rebuild_all()


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "SchoolManager"
	_ui_layer.layer = 20
	add_child(_ui_layer)

	var root_panel := PanelContainer.new()
	root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_layer.add_child(root_panel)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.07, 0.09, 1.0)
	root_panel.add_theme_stylebox_override("panel", bg)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	root_panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left)
	_build_left_column(left)

	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(560, 0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(center)
	_build_roster_column(center)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(680, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)
	_build_schools_column(right)


func _build_left_column(left: VBoxContainer) -> void:
	left.add_child(_mk_label("GLADIATOR SCHOOL", 26, Color(0.93, 0.78, 0.45)))
	left.add_child(_mk_label("Company of fighters - schedule, drill, and fight", 13, Color(0.75, 0.72, 0.68)))

	_status_label = RichTextLabel.new()
	_status_label.bbcode_enabled = true
	_status_label.fit_content = true
	_status_label.scroll_active = false
	_status_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left.add_child(_status_label)

	left.add_child(_mk_sep())

	var company_buttons := HBoxContainer.new()
	left.add_child(company_buttons)
	company_buttons.add_child(_mk_button("Hire rookie", _on_hire))
	company_buttons.add_child(_mk_button("Hire surgeon", _on_hire_surgeon))
	company_buttons.add_child(_mk_button("Manage company", _on_manage_company))

	var day_buttons := HBoxContainer.new()
	left.add_child(day_buttons)
	day_buttons.add_child(_mk_button("End day", _on_end_day))
	day_buttons.add_child(_mk_button("Camp rest", _on_camp_rest))

	left.add_child(_mk_sep())
	left.add_child(_mk_label("ARENA NIGHT", 19, Color(0.93, 0.78, 0.45)))
	_match_box = VBoxContainer.new()
	left.add_child(_match_box)

	left.add_child(_mk_sep())
	left.add_child(_mk_label("LOG", 16, Color(0.75, 0.72, 0.68)))
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = true
	_log_label.custom_minimum_size = Vector2(0, 180)
	left.add_child(_log_label)


func _build_roster_column(center: VBoxContainer) -> void:
	center.add_child(_mk_label("ROSTER", 19, Color(0.93, 0.78, 0.45)))
	_roster_box = VBoxContainer.new()
	_roster_box.add_theme_constant_override("separation", 10)
	center.add_child(_roster_box)


func _build_schools_column(right: VBoxContainer) -> void:
	right.add_child(_mk_label("RIVAL SCHOOLS", 19, Color(0.93, 0.78, 0.45)))
	_schools_box = VBoxContainer.new()
	_schools_box.add_theme_constant_override("separation", 12)
	right.add_child(_schools_box)


## === Refresh ===


func rebuild_all() -> void:
	if _status_label == null:
		return
	_refresh_status()
	_refresh_match()
	_refresh_roster()
	_refresh_schools()


func _refresh_status() -> void:
	var living: int = CompanyState.count_living_roster(self)
	var wage: int = CompanyState.compute_next_wage_bill(self)
	var food: int = CompanyState.get_food_supplies(self)
	var food_days: int = int(float(food) / float(living)) if living > 0 else 0
	_status_label.text = (
		"[color=#e8e6e0]Day %d[/color]\n"
		+ "[color=#d9c27a]Gold %d[/color]  (wages %d/day)\n"
		+ "Renown [color=#d9c27a]%d[/color]   Supplies: food %d (%d d)  med %d  tools %d\n"
		+ "Living [color=#d9c27a]%d[/color]/%d"
	) % [
		CompanyState.get_day_index(self),
		CompanyState.get_gold(self),
		wage,
		CompanyState.get_renown(self),
		food,
		food_days,
		CompanyState.get_medical_supplies(self),
		CompanyState.get_tool_supplies(self),
		living,
		CompanyState.ROSTER_MAX_LIVING,
	]


func _refresh_match() -> void:
	_clear_children(_match_box)
	if not CompanyState.has_active_match(self):
		var hint := _mk_label(
			"No match booked. Pick a rival school on the right, choose a lineup, and schedule an arena day.",
			14,
			Color(0.68, 0.66, 0.62),
		)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_match_box.add_child(hint)
		return

	var school_id: String = CompanyState.match_school_id(self)
	_match_box.add_child(_mk_label(CompanyState.school_display_name(school_id), 17, Color(0.95, 0.9, 0.8)))
	var arena_day: int = CompanyMatch.match_day(self)
	var arena_text: String
	if arena_day >= 0:
		arena_text = "Arena day %d (today %d)" % [arena_day, CompanyState.get_day_index(self)]
	else:
		arena_text = "Bouts open now"
	_match_box.add_child(_mk_label(arena_text, 13, Color(0.75, 0.72, 0.68)))

	var score: Dictionary = CompanyState.match_score(self)
	_match_box.add_child(
		_mk_label(
			"Bout %d/%d   You %d - %d school"
			% [int(score.get("bout_index", 0)) + 1, score.get("total_bouts"), score.get("player_wins"), score.get("opponent_wins")],
			14,
			Color(0.85, 0.83, 0.77),
		)
	)
	var card: Dictionary = CompanyState.current_bout_card(self)
	if bool(card.get("ok", false)):
		var opponent: String = str(card.get("opponent_name", "?"))
		var info: Array = [opponent]
		var w: String = str(card.get("opponent_weapon_id", ""))
		if not w.is_empty():
			info.append("wields " + w)
		_match_box.add_child(
			_mk_label(
				"Now: %s vs %s" % [_resolve_member_display_name(str(card.get("player_name", ""))), "  ".join(info)],
				14,
				Color(0.95, 0.95, 0.9),
			)
		)
	elif arena_day >= 0 and CompanyState.get_day_index(self) < arena_day:
		var reason: String = str(card.get("reason", "arena day not reached"))
		_match_box.add_child(_mk_label(reason, 13, Color(0.75, 0.72, 0.68)))

	var bout_buttons := HBoxContainer.new()
	_match_box.add_child(bout_buttons)
	var gate: Dictionary = CompanyGladiator.bout_entry_gate(self)
	var enter_btn := _mk_button("Enter bout", _on_enter_bout)
	enter_btn.disabled = not bool(gate.get("ok", false)) or _busy
	if not bool(gate.get("ok", false)):
		enter_btn.tooltip_text = str(gate.get("reason", ""))
	bout_buttons.add_child(enter_btn)
	bout_buttons.add_child(_mk_button("Cancel match", _on_cancel_match))


func _refresh_roster() -> void:
	_clear_children(_roster_box)
	var pm: Variant = get_meta("party_manager") if has_meta("party_manager") else null
	if pm == null:
		return
	for m in pm.members:
		if not (m is Dictionary):
			continue
		var snap: Dictionary = PartyMemberSnapshot.snapshot_from_member(m as Dictionary)
		var node_ref: Variant = snap.get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		var node: Node = node_ref as Node
		if node.has_method("is_dead") and node.is_dead():
			continue
		_roster_box.add_child(_build_member_row(node, snap))


func _build_member_row(node: Node, snap: Dictionary) -> Control:
	var name_s: String = str(snap.get("display_name", node.name))
	var entity: Node = CampaignEncounterBridge.health_entity_from_character(node)
	var fame: int = 0
	var tier: String = "Newcomer"
	if entity != null and "fame" in entity:
		fame = int(entity.fame)
		tier = CompanyState.fame_tier_label(fame)
	var mood: float = float(snap.get("company_mood", CompanyState.MOOD_DEFAULT))

	var bits: PackedStringArray = PackedStringArray()
	if CompanyState.member_is_scouting(self, str(node.name)):
		bits.append("away scouting (%d d)" % CompanyState.scout_days_remaining(self, str(node.name)))
	var wounded: int = int(snap.get("wounded_part_count", 0))
	if wounded > 0:
		var untreated: String = str(int(snap.get("untreated_parts", PackedStringArray()).size()))
		bits.append("[color=#d9534f]%d wound(s), %s untreated[/color]" % [wounded, untreated])
	if bit(snap, "is_unconscious"):
		bits.append("[color=#d9534f]unconscious[/color]")
	var blood: float = float(snap.get("blood_volume", 100.0))
	if blood < 100.0:
		bits.append("blood %.0f%%" % blood)

	var header := _mk_label(
		"%s  (%s)   Fame [color=#d9c27a]%d[/color] %s   Mood %.0f%%" % [name_s, tier, fame, mood_text(mood), mood],
		15,
		Color(0.95, 0.95, 0.9),
	)
	var body := _mk_label(
		"STR %d  AGI %d  END %d  INT %d  PER %d    %s%s%s"
		% [
			int(snap.get("strength", 0)),
			int(snap.get("agility", 0)),
			int(snap.get("endurance", 0)),
			int(snap.get("intelligence", 0)),
			int(snap.get("perception", 0)),
			("  " + str(snap.get("weapon_name", ""))),
			(format_armor(snap.get("armor_summary", []))),
			("  " + "  ".join(bits)),
		],
		12,
		Color(0.72, 0.7, 0.66),
	)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var row := PanelContainer.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.13, 0.12, 0.15, 1.0)
	panel.corner_radius_top_left = 4
	panel.corner_radius_top_right = 4
	panel.corner_radius_bottom_left = 4
	panel.corner_radius_bottom_right = 4
	row.add_theme_stylebox_override("panel", panel)
	var vbox := VBoxContainer.new()
	row.add_child(vbox)
	vbox.add_child(header)
	vbox.add_child(body)

	var train_row := HBoxContainer.new()
	var chooser := OptionButton.new()
	var choices: Array = _drill_choices(node)
	for choice in choices:
		chooser.add_item(str(choice.get("label", "")), int(choice.get("id", 0)))
	chooser.selected = 0
	chooser.add_to_group("glad_drill_choosers")
	chooser.set_meta("glad_options", choices)
	chooser.set_meta("glad_node", node)
	var drill_btn := _mk_button("Drill (%dg)" % CompanyEconomy.TRAIN_GOLD_COST, Callable(self, "_on_train").bind(chooser))
	drill_btn.disabled = not _can_pay_drill()
	train_row.add_child(chooser)
	train_row.add_child(drill_btn)
	if not _can_pay_drill():
		drill_btn.tooltip_text = "Need %dg" % CompanyEconomy.TRAIN_GOLD_COST
	vbox.add_child(train_row)
	return row


## === Rival schools column ===


func _refresh_schools() -> void:
	_clear_children(_schools_box)
	var overviews: Array = CompanyState.schools_overview(self)
	for school in overviews:
		_schools_box.add_child(_build_school_card(school))


func _build_school_card(summary: Dictionary) -> Control:
	var school_id: String = str(summary.get("id", ""))
	var card := PanelContainer.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.12, 0.11, 0.14, 1.0)
	panel.corner_radius_top_left = 4
	panel.corner_radius_top_right = 4
	panel.corner_radius_bottom_left = 4
	panel.corner_radius_bottom_right = 4
	card.add_theme_stylebox_override("panel", panel)
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var reveal: float = float(summary.get("reveal_ratio", 0.0))
	vbox.add_child(
		_mk_label(
			"[b]%s[/b]   prestige %d    roster %d    intel %d%%"
			% [
				str(summary.get("display_name", school_id)),
				int(summary.get("prestige", 0)),
				int(summary.get("roster_size", 0)),
				int(reveal * 100.0),
			],
			15,
			Color(0.95, 0.9, 0.8),
		)
	)
	var dossier: Array = CompanyState.dossier_visible_view(self, school_id)
	if dossier.is_empty():
		vbox.add_child(_mk_label("No intel yet.", 12, Color(0.7, 0.68, 0.64)))
	else:
		for row in dossier:
			var line: Array = ["  %s" % str(row.get("name", "?"))]
			var w_: String = str(row.get("weapon_id", ""))
			if not w_.is_empty():
				line.append("  wields %s" % w_)
			var f_: String = str(row.get("form_id", ""))
			if not f_.is_empty():
				line.append("  form %s" % f_)
			else:
				line.append("  (scout to learn their style)")
			vbox.add_child(_mk_label(" ".join(line), 12, Color(0.72, 0.7, 0.66)))

	var scouts: Dictionary = CompanyState.scouting_candidates(self)
	var ready_scouts: Array = scouts.get(school_id, [])
	var scout_row := HBoxContainer.new()
	if ready_scouts.is_empty():
		var fully: bool = bool(summary.get("fully_revealed", false))
		var scout_note := _mk_label(
			"Fully scouted" if fully else "No one free to scout",
			12,
			Color(0.68, 0.66, 0.62),
		)
		scout_row.add_child(scout_note)
	else:
		var scout_menu := OptionButton.new()
		for member in ready_scouts:
			scout_menu.add_item(str(member))
		scout_menu.selected = 0
		var scout_btn := _mk_button(
			"Dispatch scout (%dg)" % CompanyScout.SCOUT_GOLD_COST,
			Callable(self, "_on_scout").bind(school_id, scout_menu),
		)
		if CompanyState.get_gold(self) < CompanyScout.SCOUT_GOLD_COST:
			scout_btn.disabled = true
			scout_btn.tooltip_text = "Need %dg" % CompanyScout.SCOUT_GOLD_COST
		scout_row.add_child(scout_menu)
		scout_row.add_child(scout_btn)
	vbox.add_child(scout_row)

	var schedule_row := HBoxContainer.new()
	var presets: Array = _lineup_presets(school_id)
	var preset_menu := OptionButton.new()
	if presets.is_empty():
		preset_menu.add_item("No free fighters")
		preset_menu.disabled = true
	else:
		for preset in presets:
			preset_menu.add_item(str(preset.get("label", "")))
		preset_menu.selected = mini(presets.size() - 1, 1)
	var day_menu := OptionButton.new()
	var today: int = CompanyState.get_day_index(self)
	for i in range(ARENA_DAY_OPTIONS):
		var d: int = today + i
		var label: String = "Today" if i == 0 else "+%d day" % i
		day_menu.add_item("%s (day %d)" % [label, d])
	day_menu.selected = 0
	var schedule_btn := _mk_button(
		"Schedule match",
		Callable(self, "_on_schedule").bind(school_id, preset_menu, day_menu),
	)
	if CompanyState.has_active_match(self) or presets.is_empty():
		schedule_btn.disabled = true
	schedule_row.add_child(preset_menu)
	schedule_row.add_child(day_menu)
	schedule_row.add_child(schedule_btn)
	vbox.add_child(schedule_row)
	return card


## === Actions ===


func _on_end_day() -> void:
	if _busy:
		return
	if CompanyState.try_advance_day(self):
		_log("Advanced to day %d." % CompanyState.get_day_index(self))
	else:
		_log("The day could not be advanced.")
	rebuild_all()


func _on_camp_rest() -> void:
	if _busy:
		return
	var res: Dictionary = CompanyGladiator.rest_day(self)
	if str(res.get("kind", "")) == "camp_rest":
		_log("Camp rest: the company heals, trains, and recovers morale. Day %d." % int(res.get("day", 0)))
	else:
		_log("Couldn't rest (wounds need tending or a med supply) - the day ended instead. Day %d." % int(res.get("day", 0)))
	rebuild_all()


func _on_hire() -> void:
	if _busy:
		return
	var gold_before: int = CompanyState.get_gold(self)
	if CompanyState.try_hire_rookie(self, rng, true):
		var gained: int = gold_before - CompanyState.get_gold(self)
		_log("Hired a new fighter (%dg)." % gained)
	else:
		_log("Can't hire %s" % CompanyState.format_hire_block_reason(self, true).trim_prefix("Hire").strip_edges())
	rebuild_all()


func _on_hire_surgeon() -> void:
	if _busy:
		return
	var gold_before: int = CompanyState.get_gold(self)
	if CompanyState.try_hire_surgeon(self, rng, true):
		var gained: int = gold_before - CompanyState.get_gold(self)
		var surgeon: Node = CompanyState.find_living_surgeon(self)
		_log(
			"Hired a surgeon, %s (%dg). They treat wounded fighters in the field after battles."
			% [PlayerCompanionSetup.resolve_fighter_display_name(surgeon), gained]
		)
	else:
		_log("Can't hire %s" % CompanyState.format_surgeon_hire_block_reason(self, true).trim_prefix("Hire surgeon").strip_edges())
	rebuild_all()


func _on_manage_company() -> void:
	var menu: Variant = get_meta("party_menu") if has_meta("party_menu") else null
	var pm: Variant = get_meta("party_manager") if has_meta("party_manager") else null
	if menu is Node and pm != null and (menu as Node).has_method("show_party"):
		(menu as Node).show_party(self, pm.get_members())


func _on_party_button_pressed() -> void:
	_on_manage_company()


func _on_scout(school_id: String, chooser: OptionButton) -> void:
	if _busy:
		return
	var selected: String = str(chooser.get_item_text(chooser.selected))
	var gate: Dictionary = CompanyState.can_dispatch_scout(self, selected, school_id)
	if not gate.get("ok", false):
		_log("Couldn't scout: %s" % str(gate.get("reason", "")))
		rebuild_all()
		return
	CompanyState.dispatch_scout(self, selected, school_id)
	_log(
		"%s scouts %s (returns day %d)."
		% [selected, CompanyState.school_display_name(school_id), CompanyState.get_day_index(self) + CompanyScout.SCOUT_TIE_DAYS]
	)
	rebuild_all()


func _on_schedule(school_id: String, preset_menu: OptionButton, day_menu: OptionButton) -> void:
	if _busy:
		return
	var presets: Array = _lineup_presets(school_id)
	if preset_menu.selected < 0 or preset_menu.selected >= presets.size():
		return
	var lineup: Array = (presets[preset_menu.selected] as Dictionary).get("names", [])
	var arena_day: int = CompanyState.get_day_index(self) + day_menu.selected
	var gate: Dictionary = CompanyGladiator.can_schedule_match(self, school_id, lineup, arena_day)
	if not gate.get("ok", false):
		_log("Couldn't schedule: %s" % str(gate.get("reason", "")))
		rebuild_all()
		return
	if CompanyGladiator.schedule_match(self, school_id, lineup, arena_day):
		_log(
			"Booked %s for day %d (%d fighters)."
			% [CompanyState.school_display_name(school_id), arena_day, lineup.size()]
		)
	rebuild_all()


func _on_train(chooser: OptionButton) -> void:
	if _busy:
		return
	var choices: Variant = chooser.get_meta("glad_options", [])
	if not (choices is Array) or chooser.selected < 0 or chooser.selected >= (choices as Array).size():
		return
	var choice: Dictionary = (choices as Array)[chooser.selected]
	var node_ref: Variant = chooser.get_meta("glad_node", null)
	if not is_instance_valid(node_ref) or not (node_ref is Node):
		return
	var name_s: String = PlayerCompanionSetup.resolve_fighter_display_name(node_ref as Node)
	var kind: String = str(choice.get("kind", ""))
	var value: String = str(choice.get("value", ""))
	var ok: bool = false
	if kind == "stat":
		ok = CompanyState.train_stat(self, node_ref as Node, value)
	elif kind == "form":
		ok = CompanyState.train_form(self, node_ref as Node, value)
	elif kind == "weapon":
		ok = CompanyState.train_weapon(self, node_ref as Node, value)
	var drill_desc: String
	if kind == "form":
		drill_desc = "form " + str(value).capitalize()
	elif kind == "weapon":
		drill_desc = str(value).to_lower().capitalize()
	else:
		drill_desc = str(value).capitalize()
	_log(("Trained %s (%s) - takes effect at next camp rest." % [name_s, drill_desc]) if ok else "Not enough gold to train (need %dg)." % CompanyEconomy.TRAIN_GOLD_COST)
	rebuild_all()


func _on_enter_bout() -> void:
	if _busy:
		return
	var gate: Dictionary = CompanyGladiator.bout_entry_gate(self)
	if not gate.get("ok", false):
		_log("Can't enter the bout: %s" % str(gate.get("reason", "")))
		rebuild_all()
		return
	_busy = true
	_ui_layer.visible = false
	if OperationalLog.is_play_session_active():
		OperationalLog.play_world("arena_bout_enter bout=%d/%d" % [CompanyState.current_bout_index(self) + 1, CompanyState.match_bout_count(self)])
	var enemies: Array = CompanyGladiator.enter_current_bout(self)
	if enemies.is_empty():
		_busy = false
		_ui_layer.visible = true
		_log("The bout could not start - no opponent appeared.")
		rebuild_all()
		return
	# Keep the school screen hidden and _busy set for the whole bout; CombatFlow adds the
	# full-screen battle UI on the root, and _on_battle_ended restores the school screen.
	await CombatFlow.start_combat(self, enemies)


func _on_cancel_match() -> void:
	if _busy:
		return
	if CompanyState.cancel_active_match(self):
		_log("Match cancelled.")
	rebuild_all()


func _on_battle_ended(winner: String, defeated: Node) -> void:
	if not CompanyState.has_active_match(self):
		await CombatFlow.handle_battle_ended(self, winner, defeated)
		return
	var res: Dictionary = CompanyGladiator.finalize_bout(self, winner)
	_busy = false
	if _ui_layer != null:
		_ui_layer.visible = true
	var bout: Dictionary = res.get("bout", {})
	if bool(res.get("player_won", false)):
		var text: String = "Bout won  (+%dg, +1 renown)  Score %d-%d" % [
			int(res.get("purse", 0)) + int(res.get("sponsor_gold", 0)),
			int(bout.get("player_wins", 0)),
			int(bout.get("opponent_wins", 0)),
		]
		var promotions: Variant = res.get("promotions", PackedStringArray())
		var fame_text: String = ""
		if promotions is PackedStringArray:
			fame_text = ", ".join(promotions as PackedStringArray)
		elif promotions is Array:
			var parts := PackedStringArray()
			for p in promotions as Array:
				parts.append(str(p))
			fame_text = ", ".join(parts)
		if not fame_text.is_empty():
			text += "  (Fame: %s)" % fame_text
		_log(text)
	else:
		_log(
			"Bout lost - fighter downed, will recover at camp.  Score %d-%d"
			% [int(bout.get("player_wins", 0)), int(bout.get("opponent_wins", 0))]
		)
	var match: Dictionary = res.get("match", {})
	if not match.is_empty():
		var reward: Dictionary = res.get("match_reward", {})
		var mtxt: String = "MATCH %s  %d-%d" % [
			str(match.get("outcome", "")).to_upper(),
			int(match.get("player_wins", 0)),
			int(match.get("opponent_wins", 0)),
		]
		if not reward.is_empty():
			mtxt += "  (+%dg, +%d renown, +%d med)" % [
				int(reward.get("gold", 0)),
				int(reward.get("renown", 0)),
				int(reward.get("med", 0)),
			]
		_log(mtxt)
	rebuild_all()


func _company_run_end(reason: String) -> void:
	var RunEnd := preload("res://ui/company/CompanyRunEndPanel.gd")
	await RunEnd.show_and_await(self, reason)


func _exit_tree() -> void:
	if OS.has_feature("editor"):
		OperationalLog.end_play_session()


## === Small builders ===


func _log(text: String) -> void:
	_log_label.append_text("[color=#d9d5cc]%s[/color]\n" % text.replace("[", "\\["))
	_log_label.scroll_to_line(_log_label.get_line_count())


func _can_pay_drill() -> bool:
	return CompanyState.read_stub_proficiency_enabled() and CompanyState.get_gold(self) >= CompanyEconomy.TRAIN_GOLD_COST


## Resolves a member's raw node name (as stored in a match lineup) to the fighter's player-facing
## display name. Mirrors the combat log's CombatantIdentityAccess.get_display_name so the arena
## card and the bout read identically.
func _resolve_member_display_name(pn: String) -> String:
	if pn.is_empty():
		return pn
	var pm: Variant = get_meta("party_manager") if has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for m in pm.get_members():
			if m is not Dictionary:
				continue
			if str((m as Dictionary).get("name", "")) != pn:
				continue
			var dn: String = str((m as Dictionary).get("display_name", ""))
			return dn if not dn.is_empty() else PlayerCompanionSetup.fighter_display_name(pn)
	return PlayerCompanionSetup.fighter_display_name(pn)


## Per-member drill choices for the OptionButton: stats, then forms, then weapon types.
func _drill_choices(node: Node) -> Array:
	var out: Array = []
	for stat in CompanyCamp.TRAIN_STATS:
		if CompanyState.can_train_stat(self, node, stat):
			out.append({"id": out.size(), "kind": "stat", "value": stat, "label": "Stat: %s" % stat.capitalize()})
	for form in FORMS:
		if CompanyState.can_train_form(self, node, form):
			out.append({"id": out.size(), "kind": "form", "value": form, "label": "Form: %s" % form.capitalize()})
	for wid in WEAPON_TRAIN_IDS:
		if CompanyState.can_train_weapon(self, node, wid):
			out.append({"id": out.size(), "kind": "weapon", "value": wid, "label": "Weapon: %s" % wid})
	if out.is_empty():
		out.append({"id": 0, "kind": "", "value": "", "label": "No drills (need %dg)" % CompanyEconomy.TRAIN_GOLD_COST})
	return out


## Living, not-away fighters in roster order, capped by the school's lineup size -> "N: a, b, c" presets.
func _lineup_presets(school_id: String) -> Array:
	var out: Array = []
	var max_n: int = CompanySchool.school_lineup_size(school_id)
	var pm: Variant = get_meta("party_manager") if has_meta("party_manager") else null
	if pm == null or max_n <= 0:
		return out
	var names: Array = []
	var by_name: Dictionary = {}
	for m in pm.members:
		if not (m is Dictionary):
			continue
		var node_ref: Variant = (m as Dictionary).get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		var node: Node = node_ref as Node
		if node.has_method("is_dead") and node.is_dead():
			continue
		var m_name: String = str((m as Dictionary).get("name", ""))
		if m_name.is_empty():
			continue
		if CompanyState.member_is_scouting(self, m_name):
			continue
		names.append(m_name)
		by_name[m_name] = node
	if names.is_empty():
		return out
	var count: int = mini(names.size(), max_n)
	for k in range(1, count + 1):
		var chosen: Array = names.slice(0, k)
		var labels: PackedStringArray = PackedStringArray()
		for n_split in chosen:
			var n_ref: Variant = by_name.get(str(n_split))
			labels.append(
				PlayerCompanionSetup.resolve_fighter_display_name(n_ref) if n_ref != null else str(n_split)
			)
		out.append({"id": out.size(), "label": "%d: %s" % [k, ", ".join(labels)], "names": chosen})
	return out


func _mk_label(text: String, font_size: int, color: Color) -> RichTextLabel:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = text
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("normal_font_size", font_size)
	lbl.add_theme_color_override("default_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


func _mk_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callback)
	return btn


func _mk_sep() -> HSeparator:
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.25)
	return sep


func _clear_children(box: Node) -> void:
	for child in box.get_children():
		child.free()


func mood_text(mood: float) -> String:
	if mood >= CompanyState.MOOD_STANCE_WRATH_THRESHOLD:
		return "+"
	if mood <= CompanyState.MOOD_STANCE_WALL_THRESHOLD:
		return "-"
	return ""


func format_armor(value: Variant) -> String:
	if not (value is Array):
		return ""
	var items: Array = value as Array
	if items.is_empty():
		return ""
	var parts: Array = []
	for item in items:
		parts.append(str(item))
	return "  Armor: " + ", ".join(parts)


## Small helper so the header line can show a colored mood marker.
func bit(snap: Dictionary, key: String) -> bool:
	return bool(snap.get(key, false))