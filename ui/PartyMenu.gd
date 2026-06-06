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
var _title_label: Label
var _world: Node2D

func _ready() -> void:
	min_size = Vector2(380, 420)

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
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.add_theme_constant_override("separation", 8)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_vbox)

	_end_day_button = Button.new()
	_end_day_button.text = "End day"
	_end_day_button.visible = false
	_end_day_button.pressed.connect(_on_end_day_pressed)
	main_vbox.add_child(_end_day_button)

	_camp_heal_button = Button.new()
	_camp_heal_button.text = _CompanyState.format_camp_rest_button_label(null, true)
	_camp_heal_button.visible = false
	_camp_heal_button.pressed.connect(_on_camp_heal_pressed)
	main_vbox.add_child(_camp_heal_button)

func show_party(world: Node2D, members: Array) -> void:
	_world = world
	if _title_label != null and world != null:
		var renown: int = _CompanyState.get_renown(world)
		var renown_bit: String = " · renown %d" % renown if renown > 0 else ""
		_title_label.text = (
			"Party — %dg · %d med · %d tools · day %d%s%s"
			% [
				_CompanyState.get_gold(world),
				_CompanyState.get_medical_supplies(world),
				_CompanyState.get_tool_supplies(world),
				_CompanyState.get_day_index(world),
				renown_bit,
				_CompanyState.format_hud_triage_suffix(world),
			]
		)
	for child in content_vbox.get_children():
		child.queue_free()

	if world != null and _CampaignBridge.party_has_untreated_wounds(world):
		var gate_lbl := Label.new()
		gate_lbl.text = _CompanyState.format_party_triage_gate_line(world)
		_RowFormatter.configure_wrapped_label(gate_lbl)
		gate_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
		content_vbox.add_child(gate_lbl)

	for m in members:
		var v = VBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = str(m.get("name", "Unknown")) + "  STR:" + str(m.get("strength", 100)) + " AGI:" + str(m.get("agility", 100)) + " INT:" + str(m.get("intelligence", 100)) + " END:" + str(m.get("endurance", 100)) + " PER:" + str(m.get("perception", 100))
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
			var care_row := HBoxContainer.new()
			care_row.add_theme_constant_override("separation", 6)
			if _MapFieldCare.can_offer_field_pressure(_world, m):
				var btn_p := Button.new()
				btn_p.text = _MapFieldCare.format_field_pressure_button_label(_world, m)
				var member_copy: Dictionary = m.duplicate(true)
				btn_p.pressed.connect(
					func() -> void:
						_MapFieldCare.try_field_pressure(_world, member_copy)
						_refresh_party_view()
				)
				care_row.add_child(btn_p)
			if _MapFieldCare.can_offer_field_bandage(_world, m):
				var btn_b := Button.new()
				btn_b.text = _MapFieldCare.format_field_bandage_button_label(_world, m)
				var member_copy_b: Dictionary = m.duplicate(true)
				btn_b.pressed.connect(
					func() -> void:
						_MapFieldCare.try_field_bandage(_world, member_copy_b)
						_refresh_party_view()
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
						_MapFieldCare.try_field_pack(_world, member_copy_pk)
						_refresh_party_view()
				)
				care_row.add_child(btn_pk)
			if _MapFieldCare.can_offer_field_tourniquet(_world, m):
				var btn_tq := Button.new()
				btn_tq.text = _MapFieldCare.format_field_tourniquet_button_label(_world, m)
				var member_copy_tq: Dictionary = m.duplicate(true)
				btn_tq.pressed.connect(
					func() -> void:
						_MapFieldCare.try_field_tourniquet(_world, member_copy_tq)
						_refresh_party_view()
				)
				care_row.add_child(btn_tq)
			if _MapFieldCare.can_offer_field_stabilize(_world, m):
				var btn_s := Button.new()
				btn_s.text = _MapFieldCare.format_field_stabilize_button_label(_world, m)
				var member_copy_s: Dictionary = m.duplicate(true)
				btn_s.pressed.connect(
					func() -> void:
						_MapFieldCare.try_field_stabilize(_world, member_copy_s)
						_refresh_party_view()
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

	if _end_day_button != null:
		_end_day_button.visible = _CompanyState.can_offer_end_day(world)
	if _camp_heal_button != null:
		var ready_camp: bool = _CompanyState.camp_heal_ready(world, true)
		_camp_heal_button.visible = _CompanyState.should_show_party_camp_rest_button(world)
		_camp_heal_button.disabled = not ready_camp
		if ready_camp:
			_camp_heal_button.text = _CompanyState.format_camp_rest_button_label(world, true)
		else:
			_camp_heal_button.text = _CompanyState.format_camp_heal_block_reason(world, true)
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


func _refresh_party_view() -> void:
	if _world == null:
		return
	var pm: Variant = _world.get_meta("party_manager") if _world.has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		show_party(_world, pm.get_members())
	_CompanyState.refresh_hud(_world)


func _on_end_day_pressed() -> void:
	if _world == null:
		return
	if _CompanyState.request_end_day(_world):
		_CompanyState.refresh_hud(_world)
		hide()


func _on_camp_heal_pressed() -> void:
	if _world == null:
		return
	if _CompanyState.try_camp_heal(_world, true):
		_CompanyState.refresh_hud(_world)
		hide()
	else:
		_OperationalLog.play_world(
			"Camp rest blocked — %s"
			% _CompanyState.format_camp_heal_block_reason(_world, true).trim_prefix("Camp rest ")
		)
