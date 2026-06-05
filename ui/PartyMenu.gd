extends PopupPanel

## Party roster, field care, End day, and Camp rest. Canonical: `CompanyState.try_camp_heal` · `request_end_day`.
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
var content_vbox: VBoxContainer
var _end_day_button: Button
var _camp_heal_button: Button
var _title_label: Label
var _action_feedback_label: Label
var _day_actions_hint_label: Label
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
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.add_theme_constant_override("separation", 8)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_vbox)

	_action_feedback_label = Label.new()
	_action_feedback_label.visible = false
	_action_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_feedback_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	_RowFormatter.configure_wrapped_label(_action_feedback_label)
	main_vbox.add_child(_action_feedback_label)

	_day_actions_hint_label = Label.new()
	_day_actions_hint_label.visible = false
	_day_actions_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_day_actions_hint_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_RowFormatter.configure_wrapped_label(_day_actions_hint_label)
	main_vbox.add_child(_day_actions_hint_label)

	_end_day_button = Button.new()
	_end_day_button.text = "End day"
	_end_day_button.visible = false
	_end_day_button.pressed.connect(_on_end_day_pressed)
	main_vbox.add_child(_end_day_button)

	_camp_heal_button = Button.new()
	_camp_heal_button.text = _CompanyState.format_camp_rest_button_label()
	_camp_heal_button.visible = false
	_camp_heal_button.pressed.connect(_on_camp_heal_pressed)
	main_vbox.add_child(_camp_heal_button)

func show_party(world: Node2D, members: Array) -> void:
	_world = world
	_set_action_feedback("")
	if _title_label != null and world != null:
		var renown: int = _CompanyState.get_renown(world)
		var renown_bit: String = " · renown %d" % renown if renown > 0 else ""
		_title_label.text = (
			"Party — %dg · %d med · %d tools · day %d%s"
			% [
				_CompanyState.get_gold(world),
				_CompanyState.get_medical_supplies(world),
				_CompanyState.get_tool_supplies(world),
				_CompanyState.get_day_index(world),
				renown_bit,
			]
		)
	for child in content_vbox.get_children():
		child.queue_free()

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
		var weapon_name: String = m.get("weapon_name", "")
		if weapon_name != "":
			var weapon_lbl = Label.new()
			weapon_lbl.text = "Weapon: " + weapon_name
			v.add_child(weapon_lbl)
		var armor_summary: Array = m.get("armor_summary", [])
		if armor_summary.size() > 0:
			var armor_lbl = Label.new()
			armor_lbl.text = "Armor: " + ", ".join(armor_summary)
			v.add_child(armor_lbl)
		var body_stats: Dictionary = _RowFormatter.read_body_stat_dicts(m)
		var bc: Dictionary = body_stats["body_cutting"]
		var bb: Dictionary = body_stats["body_blunt"]
		var bm: Dictionary = body_stats["body_max"]
		var bone_h: Dictionary = body_stats["bone_health"]
		var bone_m: Dictionary = body_stats["bone_max"]
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
			var care_row := HBoxContainer.new()
			care_row.add_theme_constant_override("separation", 6)
			if _MapFieldCare.can_offer_field_pressure(_world, m):
				var btn_p := Button.new()
				btn_p.text = "Field pressure (2m)"
				var member_copy: Dictionary = m.duplicate(true)
				btn_p.pressed.connect(
					func() -> void:
						if _MapFieldCare.try_field_pressure(_world, member_copy):
							_refresh_party_view()
				)
				care_row.add_child(btn_p)
			if _MapFieldCare.can_offer_field_stabilize(_world, m):
				var btn_s := Button.new()
				btn_s.text = "Field stabilize (−1 med, 2m)"
				var member_copy_s: Dictionary = m.duplicate(true)
				btn_s.pressed.connect(
					func() -> void:
						if _MapFieldCare.try_field_stabilize(_world, member_copy_s):
							_refresh_party_view()
				)
				care_row.add_child(btn_s)
			if _MapFieldCare.can_offer_field_bandage(_world, m):
				var btn_b := Button.new()
				btn_b.text = "Field bandage (−1 med, 2m)"
				var member_copy_b: Dictionary = m.duplicate(true)
				btn_b.pressed.connect(
					func() -> void:
						if _MapFieldCare.try_field_bandage(_world, member_copy_b):
							_refresh_party_view()
				)
				care_row.add_child(btn_b)
			if care_row.get_child_count() > 0:
				v.add_child(care_row)
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

	_refresh_day_action_buttons(world)

	popup_centered()
	self.grab_focus()


func _refresh_day_action_buttons(world: Node2D) -> void:
	if _end_day_button == null or _camp_heal_button == null:
		return
	var show_end_day: bool = _CompanyState.can_offer_end_day(world)
	var can_heal: bool = _CompanyState.can_offer_camp_heal(world, true)
	_end_day_button.visible = show_end_day
	_camp_heal_button.visible = can_heal or _CompanyState.get_medical_supplies(world) >= 1
	_camp_heal_button.disabled = not can_heal
	if can_heal:
		_camp_heal_button.text = _CompanyState.format_camp_rest_button_label(world)
	else:
		_camp_heal_button.text = _CompanyState.format_camp_heal_block_reason(world, true)
	if _day_actions_hint_label != null:
		if show_end_day and can_heal:
			_day_actions_hint_label.text = _CompanyState.format_party_day_actions_hint()
			_day_actions_hint_label.visible = true
		else:
			_day_actions_hint_label.visible = false


func _set_action_feedback(message: String) -> void:
	if _action_feedback_label == null:
		return
	if message.is_empty():
		_action_feedback_label.visible = false
		_action_feedback_label.text = ""
	else:
		_action_feedback_label.text = message
		_action_feedback_label.visible = true


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
	var wage_bill: int = _CompanyState.compute_next_wage_bill(_world)
	if _CompanyState.request_end_day(_world):
		_CompanyState.refresh_hud(_world)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				_CompanyState.format_day_tick_player_message(_world, wage_bill)
			)
		hide()


func _on_camp_heal_pressed() -> void:
	if _world == null:
		return
	var wage_bill: int = _CompanyState.compute_next_wage_bill(_world)
	if _CompanyState.try_camp_heal(_world, true):
		var feedback: String = (
			"%s Party rested — vitals updated below."
			% _CompanyState.format_day_tick_player_message(_world, wage_bill)
		)
		var pm: Variant = _world.get_meta("party_manager") if _world.has_meta("party_manager") else null
		if pm != null and pm.has_method("get_members"):
			show_party(_world, pm.get_members())
		_set_action_feedback(feedback)
	else:
		_set_action_feedback("")
		_OperationalLog.play_world(
			"Camp rest unavailable — need 1 med and bleeding controlled (stabilize in Party first)."
		)
