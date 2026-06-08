extends PopupPanel

# Simple party menu that displays member info (body parts: cutting + blunt)
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
var content_vbox: VBoxContainer
var _end_day_button: Button
var _camp_heal_button: Button
var _hire_button: Button
var _new_company_button: Button
var _autosave_footer_label: Label
var _title_label: Label
var _world: Node2D
var _triage_was_active: bool = false
var _field_care_notice: String = ""

func _ready() -> void:
	min_size = Vector2(420, 440)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main_vbox)

	_title_label = Label.new()
	_title_label.text = "Party"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_title_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.add_theme_constant_override("separation", 8)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_vbox)

	_end_day_button = Button.new()
	_end_day_button.text = _CompanyState.format_end_day_button_label()
	_end_day_button.visible = false
	_end_day_button.pressed.connect(_on_end_day_pressed)
	main_vbox.add_child(_end_day_button)

	_camp_heal_button = Button.new()
	_camp_heal_button.text = _CompanyState.format_camp_rest_button_label(null, true)
	_camp_heal_button.visible = false
	_camp_heal_button.pressed.connect(_on_camp_heal_pressed)
	main_vbox.add_child(_camp_heal_button)

	_hire_button = Button.new()
	_hire_button.text = _CompanyState.format_hire_button_label()
	_hire_button.visible = false
	_hire_button.pressed.connect(_on_hire_pressed)
	main_vbox.add_child(_hire_button)

	_new_company_button = Button.new()
	_new_company_button.text = _CompanyState.format_new_company_button_label()
	_new_company_button.visible = false
	_new_company_button.pressed.connect(_on_new_company_pressed)
	main_vbox.add_child(_new_company_button)

	_autosave_footer_label = Label.new()
	_autosave_footer_label.visible = false
	_RowFormatter.configure_wrapped_label(_autosave_footer_label)
	_autosave_footer_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.88))
	main_vbox.add_child(_autosave_footer_label)

func show_party(world: Node2D, members: Array) -> void:
	if content_vbox == null:
		return
	_world = world
	if _title_label != null and world != null:
		var renown: int = _CompanyState.get_renown(world)
		var renown_bit: String = " · renown %d" % renown if renown > 0 else ""
		_title_label.text = (
			"Party — %dg · %d med · %d tools · %d food · day %d%s%s%s%s%s"
			% [
				_CompanyState.get_gold(world),
				_CompanyState.get_medical_supplies(world),
				_CompanyState.get_tool_supplies(world),
				_CompanyState.get_food_supplies(world),
				_CompanyState.get_day_index(world),
				renown_bit,
				_CompanyState.format_hud_wage_suffix(world),
				_CompanyState.format_hud_provisions_suffix(world),
				_CompanyState.format_hud_triage_suffix(world),
				_CompanyState.format_hud_persistence_suffix(world),
			]
		)
	for child in content_vbox.get_children():
		child.queue_free()

	if not _field_care_notice.is_empty():
		var notice_lbl := Label.new()
		notice_lbl.text = _field_care_notice
		_RowFormatter.configure_wrapped_label(notice_lbl)
		notice_lbl.add_theme_color_override("font_color", Color(0.95, 0.5, 0.45))
		content_vbox.add_child(notice_lbl)

	var triage_active: bool = world != null and _CampaignBridge.party_has_untreated_wounds(world)
	# One-shot when the last untreated part is dressed (med may still be 0 — copy in complete_line).
	var camp_unlock: bool = (
		_triage_was_active
		and not triage_active
		and world != null
	)
	_triage_was_active = triage_active
	if camp_unlock:
		var ready_lbl := Label.new()
		ready_lbl.text = _CompanyState.format_field_care_complete_line(world)
		_RowFormatter.configure_wrapped_label(ready_lbl)
		ready_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.62))
		content_vbox.add_child(ready_lbl)
	if triage_active:
		var gate_lbl := Label.new()
		gate_lbl.text = _CompanyState.format_party_triage_gate_line(world)
		_RowFormatter.configure_wrapped_label(gate_lbl)
		gate_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
		content_vbox.add_child(gate_lbl)
		if _MapFieldCare.can_treat_next_wound(world, members):
			var treat_btn := Button.new()
			treat_btn.text = _MapFieldCare.format_treat_next_wound_button_label(world, members)
			treat_btn.tooltip_text = (
				"One MARCH step on the highest-threat wounded brother "
				+ "(same order as the buttons on each row below)."
			)
			treat_btn.pressed.connect(_on_treat_next_wound_pressed)
			content_vbox.add_child(treat_btn)

	var display_members: Array = members
	if triage_active:
		var wounded: Array = []
		var healthy: Array = []
		for raw in members:
			if raw is not Dictionary:
				continue
			var row: Dictionary = raw as Dictionary
			if bool(row.get("has_untreated_wounds", false)):
				wounded.append(row)
			else:
				healthy.append(row)
		wounded.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				return _RowFormatter.member_triage_priority(a) < _RowFormatter.member_triage_priority(b)
		)
		display_members = wounded
		if not healthy.is_empty():
			var healthy_hdr := Label.new()
			healthy_hdr.text = (
				"%d unwounded — no field care needed (camp rest unlocks after everyone is dressed)."
				% healthy.size()
			)
			_RowFormatter.configure_wrapped_label(healthy_hdr)
			healthy_hdr.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
			content_vbox.add_child(healthy_hdr)
			for h in healthy:
				_append_compact_member_row(content_vbox, h)
			if not wounded.is_empty():
				var wounded_hdr := Label.new()
				wounded_hdr.text = "Wounded — field care"
				wounded_hdr.add_theme_font_size_override("font_size", 14)
				_RowFormatter.configure_wrapped_label(wounded_hdr)
				wounded_hdr.add_theme_color_override("font_color", Color(0.95, 0.72, 0.45))
				content_vbox.add_child(wounded_hdr)

	var triage_row_index: int = 0
	for m in display_members:
		var triage_row: bool = triage_active and bool(m.get("has_untreated_wounds", false))
		if triage_row:
			if triage_row_index > 0:
				content_vbox.add_child(HSeparator.new())
			triage_row_index += 1
		var v = VBoxContainer.new()
		var name_lbl = Label.new()
		if triage_row:
			name_lbl.text = str(m.get("name", "Unknown")) + _RowFormatter.format_party_role_suffix(m)
			name_lbl.add_theme_font_size_override("font_size", 15)
		else:
			name_lbl.text = (
				str(m.get("name", "Unknown"))
				+ _RowFormatter.format_party_role_suffix(m)
				+ "  STR:"
				+ str(m.get("strength", 100))
				+ " AGI:"
				+ str(m.get("agility", 100))
				+ " INT:"
				+ str(m.get("intelligence", 100))
				+ " END:"
				+ str(m.get("endurance", 100))
				+ " PER:"
				+ str(m.get("perception", 100))
			)
		_RowFormatter.configure_wrapped_label(name_lbl)
		v.add_child(name_lbl)
		var bv: float = float(m.get("blood_volume", 100.0))
		var bleed: float = float(m.get("total_bleeding_rate", 0.0))
		var blood_lbl = Label.new()
		blood_lbl.text = _RowFormatter.format_blood_line(bv, bleed)
		if bleed > 0.0:
			blood_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
		v.add_child(blood_lbl)
		var triage_line: String = _RowFormatter.format_triage_line(bv, bleed)
		if not triage_line.is_empty():
			var triage_lbl = Label.new()
			triage_lbl.text = triage_line
			_RowFormatter.configure_wrapped_label(triage_lbl)
			if bleed > 0.0 or bv <= _RowFormatter.danger_blood_threshold():
				triage_lbl.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
			v.add_child(triage_lbl)
		var dressing_gate: String = _RowFormatter.format_dressing_gate_line(m)
		if not dressing_gate.is_empty():
			var dress_gate_lbl := Label.new()
			dress_gate_lbl.text = dressing_gate
			_RowFormatter.configure_wrapped_label(dress_gate_lbl)
			dress_gate_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.5))
			v.add_child(dress_gate_lbl)
		var status_line: String = _RowFormatter.format_vitality_status(m)
		if not status_line.is_empty():
			var status_lbl = Label.new()
			status_lbl.text = status_line
			_RowFormatter.configure_wrapped_label(status_lbl)
			if bool(m.get("has_untreated_wounds", false)) or bool(m.get("is_unconscious", false)):
				status_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
			v.add_child(status_lbl)
		var untreated_parts: Variant = m.get("untreated_parts", [])
		if untreated_parts is PackedStringArray and (untreated_parts as PackedStringArray).size() > 0:
			var wound_lbl = Label.new()
			wound_lbl.text = "Needs dressing: " + _MapFieldCare.format_part_list(untreated_parts)
			_RowFormatter.configure_wrapped_label(wound_lbl)
			wound_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
			v.add_child(wound_lbl)
		if not triage_row:
			var weapon_name: String = m.get("weapon_name", "")
			if weapon_name != "":
				var weapon_lbl = Label.new()
				weapon_lbl.text = "Weapon: " + weapon_name
				v.add_child(weapon_lbl)
			var form_pref: String = str(m.get("stance_preference", "")).strip_edges()
			if not form_pref.is_empty():
				var form_lbl = Label.new()
				form_lbl.text = (
					"Form preference: "
					+ _WeaponForm.display_name(_WeaponForm.normalize_form(form_pref))
				)
				v.add_child(form_lbl)
			var armor_summary: Array = m.get("armor_summary", [])
			if armor_summary.size() > 0:
				var armor_lbl = Label.new()
				armor_lbl.text = "Armor: " + ", ".join(armor_summary)
				v.add_child(armor_lbl)
			var bc: Dictionary = _EntityAccess.nested_dictionary_read(m, "body_cutting")
			var bb: Dictionary = _EntityAccess.nested_dictionary_read(m, "body_blunt")
			var bm: Dictionary = _EntityAccess.nested_dictionary_read(m, "body_max")
			var bone_h: Dictionary = _EntityAccess.nested_dictionary_read(m, "bone_health")
			var bone_m: Dictionary = _EntityAccess.nested_dictionary_read(m, "bone_max")
			for pair in _RowFormatter.PART_LINES:
				var h = HBoxContainer.new()
				for part in pair:
					var line: String = _RowFormatter.format_body_part(part, bc, bb, bm, bone_h, bone_m)
					if not line.is_empty():
						var lbl = Label.new()
						lbl.text = line
						lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						h.add_child(lbl)
				v.add_child(h)
		if _world != null:
			var next_action: String = _MapFieldCare.format_next_field_care_action(_world, m)
			if not next_action.is_empty():
				var next_lbl := Label.new()
				next_lbl.text = next_action
				_RowFormatter.configure_wrapped_label(next_lbl)
				next_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95))
				v.add_child(next_lbl)
			var care_row := VBoxContainer.new()
			care_row.add_theme_constant_override("separation", 4)
			if _MapFieldCare.can_offer_field_pressure(_world, m):
				var btn_p := Button.new()
				btn_p.text = _MapFieldCare.format_field_pressure_button_label(_world, m)
				var member_copy: Dictionary = m.duplicate(true)
				btn_p.pressed.connect(
					func() -> void:
						_run_field_care_step(
							func() -> bool:
								return _MapFieldCare.try_field_pressure(_world, member_copy),
							"pressure"
						)
				)
				care_row.add_child(btn_p)
			if _MapFieldCare.can_offer_field_bandage(_world, m):
				var btn_b := Button.new()
				btn_b.text = _MapFieldCare.format_field_bandage_button_label(_world, m)
				var member_copy_b: Dictionary = m.duplicate(true)
				btn_b.pressed.connect(
					func() -> void:
						_run_field_care_step(
							func() -> bool:
								return _MapFieldCare.try_field_bandage(_world, member_copy_b),
							"bandage"
						)
				)
				care_row.add_child(btn_b)
			elif _MapFieldCare.field_bandage_needs_pressure_first(m):
				var btn_b_wait := Button.new()
				btn_b_wait.text = _MapFieldCare.format_field_bandage_waiting_label(m)
				btn_b_wait.disabled = true
				care_row.add_child(btn_b_wait)
			if _MapFieldCare.can_offer_field_pack(_world, m):
				var btn_pk := Button.new()
				btn_pk.text = _MapFieldCare.format_field_pack_button_label(_world, m)
				var member_copy_pk: Dictionary = m.duplicate(true)
				btn_pk.pressed.connect(
					func() -> void:
						_run_field_care_step(
							func() -> bool:
								return _MapFieldCare.try_field_pack(_world, member_copy_pk),
							"pack"
						)
				)
				care_row.add_child(btn_pk)
			if _MapFieldCare.can_offer_field_tourniquet(_world, m):
				var btn_tq := Button.new()
				btn_tq.text = _MapFieldCare.format_field_tourniquet_button_label(_world, m)
				var member_copy_tq: Dictionary = m.duplicate(true)
				btn_tq.pressed.connect(
					func() -> void:
						_run_field_care_step(
							func() -> bool:
								return _MapFieldCare.try_field_tourniquet(_world, member_copy_tq),
							"tourniquet"
						)
				)
				care_row.add_child(btn_tq)
			if _MapFieldCare.can_offer_field_stabilize(_world, m):
				var btn_s := Button.new()
				btn_s.text = _MapFieldCare.format_field_stabilize_button_label(_world, m)
				var member_copy_s: Dictionary = m.duplicate(true)
				btn_s.pressed.connect(
					func() -> void:
						_run_field_care_step(
							func() -> bool:
								return _MapFieldCare.try_field_stabilize(_world, member_copy_s),
							"stabilize"
						)
				)
				care_row.add_child(btn_s)
			if care_row.get_child_count() > 0:
				v.add_child(care_row)
			var pressure_line: String = _MapFieldCare.format_member_pressure_held_line(m)
			if not pressure_line.is_empty():
				var pressure_lbl := Label.new()
				pressure_lbl.text = pressure_line
				_RowFormatter.configure_wrapped_label(pressure_lbl)
				pressure_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.65))
				v.add_child(pressure_lbl)
			var care_hint: String = _MapFieldCare.format_member_field_care_hint(m)
			if not care_hint.is_empty():
				var care_note := Label.new()
				care_note.text = care_hint
				_RowFormatter.configure_wrapped_label(care_note)
				care_note.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
				v.add_child(care_note)
		var afflictions: Variant = m.get("affliction_labels", [])
		if afflictions is PackedStringArray and (afflictions as PackedStringArray).size() > 0:
			var aff_lbl = Label.new()
			aff_lbl.text = "Afflictions: " + ", ".join(afflictions)
			_RowFormatter.configure_wrapped_label(aff_lbl)
			aff_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95))
			v.add_child(aff_lbl)
		var aff_fx: String = _RowFormatter.format_affliction_effects_line(m)
		if not aff_fx.is_empty():
			var fx_lbl := Label.new()
			fx_lbl.text = aff_fx
			_RowFormatter.configure_wrapped_label(fx_lbl)
			fx_lbl.add_theme_color_override("font_color", Color(0.7, 0.62, 0.88))
			v.add_child(fx_lbl)
		if m.has("company_mood"):
			var mood_val: float = float(m.get("company_mood", _CompanyState.MOOD_DEFAULT))
			var mood_lbl = Label.new()
			mood_lbl.text = "Mood: %d" % int(roundf(mood_val))
			if mood_val <= _CompanyState.MOOD_ANGRY_THRESHOLD:
				mood_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.4))
				mood_lbl.text += " — desertion risk at day end"
			v.add_child(mood_lbl)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_vbox.add_child(v)

	if _autosave_footer_label != null:
		var menu_footer: String = _CompanyState.format_party_menu_footer(world)
		_autosave_footer_label.visible = not menu_footer.is_empty()
		_autosave_footer_label.text = menu_footer
	if _end_day_button != null:
		_end_day_button.visible = _CompanyState.can_offer_end_day(world)
		_end_day_button.text = _CompanyState.format_end_day_button_label(world)
		_end_day_button.tooltip_text = _CompanyState.format_end_day_tooltip(world)
	if _camp_heal_button != null:
		var ready_camp: bool = _CompanyState.camp_heal_ready(world, true)
		_camp_heal_button.visible = _CompanyState.should_show_party_camp_rest_button(world)
		_camp_heal_button.disabled = not ready_camp
		if ready_camp:
			_camp_heal_button.text = _CompanyState.format_camp_rest_button_label(world, true)
		else:
			_camp_heal_button.text = _CompanyState.format_camp_heal_block_reason(world, true)
		_camp_heal_button.tooltip_text = _CompanyState.format_camp_rest_tooltip(world)
	if _hire_button != null:
		var ready_hire: bool = _CompanyState.can_offer_hire(world, true)
		_hire_button.visible = _CompanyState.should_show_party_hire_button(world)
		_hire_button.disabled = not ready_hire
		if ready_hire:
			_hire_button.text = _CompanyState.format_hire_button_label(world)
		else:
			_hire_button.text = _CompanyState.format_hire_block_reason(world, true)
		_hire_button.tooltip_text = _CompanyState.format_hire_tooltip(world, true)
	if _new_company_button != null:
		_new_company_button.visible = _CompanyState.can_offer_new_campaign_from_menu()
	var opening: bool = not visible
	popup_centered()
	self.grab_focus()
	if opening and _OperationalLog.is_play_session_active():
		var untreated: int = 0
		var bleeding: int = 0
		for m in members:
			if bool(m.get("has_untreated_wounds", false)):
				untreated += 1
			if float(m.get("total_bleeding_rate", 0.0)) > 0.0:
				bleeding += 1
		var parts_need: int = _CampaignBridge.party_untreated_part_count(world)
		var budget: Dictionary = _CompanyState.triage_med_budget(world)
		_OperationalLog.play_world(
			(
				"party_triage_open living=%d untreated=%d bleeding=%d parts_need_dressing=%d "
				+ "med_left=%d bandage_med_est=%d camp_med=%d total_med_est=%d med_shortfall=%d"
			)
			% [
				members.size(),
				untreated,
				bleeding,
				parts_need,
				_CompanyState.get_medical_supplies(world),
				int(budget.get("field_bandage_med_est", 0)),
				int(budget.get("camp_med", 0)),
				int(budget.get("total_worst_case", 0)),
				int(budget.get("med_shortfall", 0)),
			]
		)


func _append_compact_member_row(parent: VBoxContainer, m: Dictionary) -> void:
	var row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = "%s%s — OK" % [str(m.get("name", "Unknown")), _RowFormatter.format_party_role_suffix(m)]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_RowFormatter.configure_wrapped_label(name_lbl)
	row.add_child(name_lbl)
	var bv: float = float(m.get("blood_volume", 100.0))
	var bleed: float = float(m.get("total_bleeding_rate", 0.0))
	var blood_lbl := Label.new()
	blood_lbl.text = _RowFormatter.format_blood_line(bv, bleed)
	row.add_child(blood_lbl)
	parent.add_child(row)


func _party_members() -> Array:
	if _world == null:
		return []
	var pm: Variant = _world.get_meta("party_manager") if _world.has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		return pm.get_members()
	return []


func _run_field_care_step(step: Callable, action: String) -> void:
	if step.call():
		_field_care_notice = ""
	else:
		_field_care_notice = _MapFieldCare.format_field_care_retry_hint(action)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(_field_care_notice)
	_refresh_party_view()


func _on_treat_next_wound_pressed() -> void:
	if _world == null:
		return
	if _MapFieldCare.try_treat_next_wound(_world, _party_members()):
		_field_care_notice = ""
	else:
		_field_care_notice = (
			"Field care step failed — retry Treat next wound or use a brother's buttons below."
		)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(_field_care_notice)
	_refresh_party_view()


func _refresh_party_view() -> void:
	if _world == null:
		return
	var members: Array = _party_members()
	if not members.is_empty():
		show_party(_world, members)
	_CompanyState.refresh_hud(_world)


func _on_end_day_pressed() -> void:
	if _world == null:
		return
	if _CompanyState.request_end_day(_world):
		_CompanyState.refresh_hud(_world)
		hide()
	elif _OperationalLog.is_play_session_active():
		var block_hint: String = _CompanyState.format_party_end_day_unavailable_hint(_world)
		if block_hint.is_empty():
			block_hint = "End day unavailable (check camp tile or day-tick mode)."
		_OperationalLog.play_world("End day blocked — %s" % block_hint)


func _on_camp_heal_pressed() -> void:
	if _world == null:
		return
	if _CompanyState.try_camp_heal(_world, true):
		_CompanyState.refresh_hud(_world)
		hide()
	elif _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"Camp rest blocked — %s"
			% _CompanyState.format_camp_heal_block_reason(_world, true).trim_prefix("Camp rest ")
		)


func _on_hire_pressed() -> void:
	if _world == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if _CompanyState.try_hire_rookie(_world, rng, true):
		_refresh_party_view()
	elif _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"Hire blocked — %s"
			% _CompanyState.format_hire_block_reason(_world, true).trim_prefix("Hire ")
		)


func _on_new_company_pressed() -> void:
	if _world == null:
		return
	hide()
	_CompanyState.request_new_campaign(_world)
