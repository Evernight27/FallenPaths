class_name FormationDiagramBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")

## Builds a compact visual formation diagram: rank×file grid with unit names.
## Shows Front (rank 0) and Back (rank 1+) so formation changes (swap rank, etc.) are trackable.
## Returns the root Control; caller reparents into layout and calls refresh() when formation changes.

static func create(manager: Node, preset: Dictionary, side: String) -> Control:
	var root = PanelContainer.new()
	root.name = "FormationDiagram_" + side
	root.custom_minimum_size = Vector2(180, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.92)
	style.set_content_margin_all(6)
	style.set_corner_radius_all(4)
	style.border_color = Color(0.35, 0.4, 0.45)
	style.set_border_width_all(1)
	root.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	root.add_child(vbox)

	var title = Label.new()
	title.text = "Enemies" if side == "enemy" else "Party"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	vbox.add_child(title)

	var zoc_line = Label.new()
	zoc_line.name = "ZocLine"
	zoc_line.add_theme_font_size_override("font_size", 10)
	zoc_line.add_theme_color_override("font_color", Color(0.55, 0.62, 0.68))
	zoc_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(zoc_line)

	var grid = GridContainer.new()
	var files: int = preset.get("files", 1)
	var density: String = preset.get("density", "normal")
	grid.columns = files + 1  # +1 for rank label column
	grid.add_theme_constant_override("h_separation", int(_FormationPreset.separation_px_from_density(density) / 2.0))
	grid.add_theme_constant_override("v_separation", int(_FormationPreset.v_separation_px_from_density(density) / 2.0))
	grid.name = "FormationDiagramGrid"
	vbox.add_child(grid)

	var wedge_strip = HBoxContainer.new()
	wedge_strip.name = "WedgeCorridorStrip"
	wedge_strip.add_theme_constant_override("separation", 6)
	vbox.add_child(wedge_strip)

	# Store references for refresh
	root.set_meta("_formation_manager", manager)
	root.set_meta("_formation_side", side)
	root.set_meta("_formation_preset", preset)
	root.set_meta("_formation_grid", grid)
	root.set_meta("_zoc_line", zoc_line)
	root.set_meta("_wedge_strip", wedge_strip)

	_refresh_internal(root)
	return root


static func refresh(diagram_root: Control) -> void:
	if diagram_root == null:
		return
	_refresh_internal(diagram_root)


static func _refresh_internal(diagram_root: Control) -> void:
	var grid: GridContainer = diagram_root.get_meta("_formation_grid", null)
	var manager: Node = diagram_root.get_meta("_formation_manager", null)
	var side: String = diagram_root.get_meta("_formation_side", "")
	var preset: Dictionary = diagram_root.get_meta("_formation_preset", {})
	var zoc_line: Label = diagram_root.get_meta("_zoc_line", null)
	if zoc_line != null:
		zoc_line.text = ZoneOfControl.format_zone_control_line(manager, side)
	if grid == null or manager == null or not manager.has_method("get_combatants"):
		return

	var files: int = preset.get("files", 1)
	var ranks: int = preset.get("ranks", 1)
	var formation: Dictionary = {}
	if "formations" in manager and manager.formations is Dictionary:
		formation = manager.formations.get(side, {})
	var slot_map: Dictionary = formation.get("slots", {})

	# Map (rank, file) -> combatant
	var slot_to_combatant: Dictionary = {}
	for c in manager.get_combatants():
		if c.get("side", "") != side:
			continue
		if not c.get("alive", true):
			continue
		if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			continue
		var r: int = c.get("rank", 0)
		var f: int = c.get("file", 0)
		slot_to_combatant[Vector2i(r, f)] = c

	# Clear existing children
	for child in grid.get_children():
		child.queue_free()

	# Build grid: first column = rank label, then file columns
	for rank in range(ranks):
		var rank_label = Label.new()
		rank_label.text = "Front" if rank == 0 else ("Back" if rank == 1 else "Rank %d" % (rank + 1))
		rank_label.add_theme_font_size_override("font_size", 11)
		rank_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		rank_label.custom_minimum_size = Vector2(48, 0)
		grid.add_child(rank_label)

		for file in range(files):
			var key := Vector2i(rank, file)
			var occ: Array = _FormationSlots.normalize_cell(slot_map.get(key, []))
			var cell = Label.new()
			if not occ.is_empty():
				var names: Array = []
				for cid in occ:
					var oc = manager._get_by_id(int(cid)) if manager.has_method("_get_by_id") else null
					if oc != null and oc.get("alive", false):
						var nm: String = _EntityAccess.get_display_name(oc, oc.get("id", -1))
						# Host grid can list intruders (home formation_id) or dual cells; tag so UI matches combat truth.
						var intruded: bool = str(oc.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
						var home_fid: String = str(oc.get("formation_id", ""))
						if intruded or home_fid != side:
							nm += " [intr.]"
						names.append(nm)
				if names.is_empty():
					cell.text = "—"
					cell.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
				elif names.size() == 1:
					cell.text = str(names[0])
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
				else:
					var joined: String = str(names[0])
					for i in range(1, names.size()):
						joined += " / " + str(names[i])
					cell.text = joined
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
			else:
				var c = slot_to_combatant.get(key, null)
				if c != null:
					cell.text = _EntityAccess.get_display_name(c, c.get("id", -1))
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
				else:
					cell.text = "—"
					cell.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
			cell.add_theme_font_size_override("font_size", 12)
			cell.custom_minimum_size = Vector2(72, 0)
			grid.add_child(cell)

	var wstrip: Variant = diagram_root.get_meta("_wedge_strip", null)
	if wstrip != null and wstrip is HBoxContainer:
		for ch in (wstrip as HBoxContainer).get_children():
			ch.queue_free()
		var wlab0 := Label.new()
		wlab0.text = "Corridor"
		wlab0.add_theme_font_size_override("font_size", 10)
		wlab0.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		wlab0.custom_minimum_size = Vector2(48, 0)
		(wstrip as HBoxContainer).add_child(wlab0)
		for fi in range(files):
			var pr: float = _IntrusionWedge.pressure_at_file(formation, fi)
			var wc := Label.new()
			var bars: Array = ["▁", "▂", "▃", "▄", "▅", "▆", "▇"]
			if pr < 0.035:
				wc.text = "·"
			else:
				wc.text = str(bars[clampi(int(pr * 7.0), 0, 6)])
			wc.add_theme_font_size_override("font_size", 11)
			wc.add_theme_color_override(
				"font_color",
				Color(0.88, 0.52, 0.42) if pr >= 0.22 else Color(0.5, 0.52, 0.55)
			)
			wc.tooltip_text = "Intrusion wedge pressure (file %d): %.0f%%" % [fi, pr * 100.0]
			wc.custom_minimum_size = Vector2(72, 0)
			(wstrip as HBoxContainer).add_child(wc)
