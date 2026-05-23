class_name FormationDiagramBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")

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

	# Store references for refresh
	root.set_meta("_formation_manager", manager)
	root.set_meta("_formation_side", side)
	root.set_meta("_formation_preset", preset)
	root.set_meta("_formation_grid", grid)
	root.set_meta("_zoc_line", zoc_line)
	_refresh_internal(root)
	return root


static func refresh(diagram_root: Control) -> void:
	if diagram_root == null:
		return
	_refresh_internal(diagram_root)


static func _cell_label_with_footwork(base: String, footwork_sources: Array) -> String:
	if base.is_empty() or base == "—" or footwork_sources.is_empty():
		return base
	var text: String = base
	var got_fw: bool = false
	var got_grd: bool = false
	for raw in footwork_sources:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var oc: Dictionary = raw as Dictionary
		if not got_fw:
			var fw: String = _UiHints.footwork_diagram_suffix(oc)
			if not fw.is_empty():
				text += fw
				got_fw = true
		if not got_grd:
			var grd: String = _UiHints.guard_line_diagram_suffix(oc)
			if not grd.is_empty():
				text += grd
				got_grd = true
		if got_fw and got_grd:
			break
	return text


static func _append_cell_tooltips(cell: Label, combatants: Array, manager: Node = null) -> void:
	if cell == null:
		return
	var lines: PackedStringArray = []
	for raw in combatants:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var oc: Dictionary = raw as Dictionary
		var nm: String = _EntityAccess.get_display_name(oc, _EntityAccess.id_int(oc))
		for line in _UiHints.formation_cell_tooltip_lines(oc, nm, manager):
			lines.append(line)
	if lines.is_empty():
		return
	var extra: String = "\n".join(lines)
	var base: String = str(cell.tooltip_text).strip_edges()
	cell.tooltip_text = extra if base.is_empty() else "%s\n%s" % [base, extra]


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

	var snap_by_id: Dictionary = {}
	for raw_cap in manager.get_combatants():
		if raw_cap == null or typeof(raw_cap) != TYPE_DICTIONARY:
			continue
		var cap: Dictionary = raw_cap as Dictionary
		snap_by_id[_EntityAccess.id_int(cap)] = cap

	var files: int = preset.get("files", 1)
	var ranks: int = preset.get("ranks", 1)
	var formation: Dictionary = {}
	if "formations" in manager and manager.formations is Dictionary:
		formation = _FormationSlots.formation_record_for_manager(manager, side)
	var slot_map: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation, "slots")
	# Keep diagram bounds synced with actual slot occupancy (not just preset), so deep swaps/plugs remain visible.
	for k in slot_map.keys():
		if typeof(k) == TYPE_VECTOR2I:
			var kk: Vector2i = k
			ranks = maxi(ranks, kk.x + 1)
			files = maxi(files, kk.y + 1)

	# Map (rank, file) -> combatant
	var slot_to_combatant: Dictionary = {}
	for c in manager.get_combatants():
		if _EntityAccess.side_str(c) != side:
			continue
		if not _EntityAccess.alive_bool(c, true):
			continue
		var r: int = _EntityAccess.rank_int(c)
		var f: int = _EntityAccess.file_int(c)
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
			var footwork_sources: Array = []
			var cell = Label.new()
			if not occ.is_empty():
				var names: Array = []
				for cid in occ:
					var oc: Variant = snap_by_id.get(int(cid), null)
					if oc != null and typeof(oc) == TYPE_DICTIONARY and _EntityAccess.alive_bool(oc):
						if _ZoneOfControl.zone_geometry_fid_from_row(manager, oc) != side:
							continue
						var nm: String = _EntityAccess.get_display_name(oc, _EntityAccess.id_int(oc))
						names.append(nm)
						footwork_sources.append(oc)
				if names.is_empty():
					cell.text = "—"
					cell.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
				elif names.size() == 1:
					cell.text = _cell_label_with_footwork(str(names[0]), footwork_sources)
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
				else:
					var joined: String = str(names[0])
					for i in range(1, names.size()):
						joined += " / " + str(names[i])
					cell.text = _cell_label_with_footwork(joined, footwork_sources)
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
			else:
				var c = slot_to_combatant.get(key, null)
				if c != null:
					cell.text = _cell_label_with_footwork(
						_EntityAccess.get_display_name(c, _EntityAccess.id_int(c)),
						[c]
					)
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
					footwork_sources.append(c)
				else:
					cell.text = "—"
					cell.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
			cell.add_theme_font_size_override("font_size", 12)
			cell.custom_minimum_size = Vector2(84, 0)
			_append_cell_tooltips(cell, footwork_sources, manager)
			grid.add_child(cell)
