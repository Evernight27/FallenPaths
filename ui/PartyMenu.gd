extends PopupPanel

# Simple party menu that displays member info (body parts: cutting + blunt)
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
var content_vbox: VBoxContainer

func _ready() -> void:
	self.min_size = Vector2(360, 200)

	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("margin_left", 12)
	main_vbox.add_theme_constant_override("margin_top", 12)
	main_vbox.add_theme_constant_override("margin_right", 12)
	main_vbox.add_theme_constant_override("margin_bottom", 12)
	add_child(main_vbox)

	var title_label = Label.new()
	title_label.text = "Party"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)

	content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.add_theme_constant_override("separation", 8)
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_vbox)

func show_party(members: Array) -> void:
	for child in content_vbox.get_children():
		child.queue_free()

	for m in members:
		var v = VBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = str(m.get("name", "Unknown")) + "  STR:" + str(m.get("strength", 100)) + " AGI:" + str(m.get("agility", 100)) + " INT:" + str(m.get("intelligence", 100)) + " END:" + str(m.get("endurance", 100)) + " PER:" + str(m.get("perception", 100))
		v.add_child(name_lbl)
		var blood_lbl = Label.new()
		blood_lbl.text = _RowFormatter.format_blood_line(m.get("blood_volume", 100.0), m.get("total_bleeding_rate", 0.0))
		if m.get("total_bleeding_rate", 0.0) > 0.0:
			blood_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
		v.add_child(blood_lbl)
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
		var bc: Dictionary = m.get("body_cutting", {})
		var bb: Dictionary = m.get("body_blunt", {})
		var bm: Dictionary = m.get("body_max", {})
		var bone_h: Dictionary = m.get("bone_health", {})
		var bone_m: Dictionary = m.get("bone_max", {})
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
		content_vbox.add_child(v)

	popup_centered()
	self.grab_focus()
