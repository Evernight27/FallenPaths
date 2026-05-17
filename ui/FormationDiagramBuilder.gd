class_name FormationDiagramBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

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

	var intruder_strip = HBoxContainer.new()
	intruder_strip.name = "IntruderStrip"
	intruder_strip.add_theme_constant_override("separation", 6)
	vbox.add_child(intruder_strip)

	var deployed_strip = HBoxContainer.new()
	deployed_strip.name = "DeployedIntruderStrip"
	deployed_strip.add_theme_constant_override("separation", 6)
	vbox.add_child(deployed_strip)

	# Store references for refresh
	root.set_meta("_formation_manager", manager)
	root.set_meta("_formation_side", side)
	root.set_meta("_formation_preset", preset)
	root.set_meta("_formation_grid", grid)
	root.set_meta("_zoc_line", zoc_line)
	root.set_meta("_wedge_strip", wedge_strip)
	root.set_meta("_intruder_strip", intruder_strip)
	root.set_meta("_deployed_strip", deployed_strip)

	_refresh_internal(root)
	return root


static func refresh(diagram_root: Control) -> void:
	if diagram_root == null:
		return
	_refresh_internal(diagram_root)


static func _append_footwork_tooltip(cell: Label, combatants: Array) -> void:
	if not _Footwork.enabled() or cell == null:
		return
	var lines: PackedStringArray = []
	for raw in combatants:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var oc: Dictionary = raw as Dictionary
		var fw: String = _Footwork.get_ui_hint(oc)
		if fw.is_empty():
			continue
		var nm: String = _EntityAccess.get_display_name(oc, _EntityAccess.id_int(oc))
		lines.append("%s: %s" % [nm, fw])
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

	var files: int = preset.get("files", 1)
	var ranks: int = preset.get("ranks", 1)
	var formation: Dictionary = {}
	if "formations" in manager and manager.formations is Dictionary:
		formation = _FormationSlots.formation_record_read(manager.formations, side)
	var slot_map: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation, "slots")
	# Keep diagram bounds synced with actual slot occupancy (not just preset), so deep swaps/plugs remain visible.
	for k in slot_map.keys():
		if typeof(k) == TYPE_VECTOR2I:
			var kk: Vector2i = k
			ranks = maxi(ranks, kk.x + 1)
			files = maxi(files, kk.y + 1)

	# Map (rank, file) -> combatant
	var slot_to_combatant: Dictionary = {}
	var intruders_by_file: Dictionary = {}
	var deployed_intruders: Array = []
	for c in manager.get_combatants():
		if _EntityAccess.side_str(c) != side:
			# Intruders physically occupying this side's formation are rendered in a dedicated strip.
			if _EntityAccess.alive_bool(c, true) and _ZoneOfControl.intruder_on_host_formation(c, side):
				var ifile: int = _EntityAccess.intrusion_anchor_or_file_int(c)
				if not intruders_by_file.has(ifile):
					intruders_by_file[ifile] = []
				(intruders_by_file[ifile] as Array).append(c)
			continue
		if not _EntityAccess.alive_bool(c, true):
			continue
		if _ZoneOfControl.is_intruded(c):
			deployed_intruders.append(c)
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
			var in_lane_intruders: Array = []
			var footwork_sources: Array = []
			var cell = Label.new()
			if not occ.is_empty():
				var names: Array = []
				for cid in occ:
					var oc = manager._get_by_id(int(cid)) if manager.has_method("_get_by_id") else null
					if oc != null and _EntityAccess.alive_bool(oc):
						var nm: String = _EntityAccess.get_display_name(oc, _EntityAccess.id_int(oc))
						# Host grid can list intruders (home formation_id) or dual cells; tag so UI matches combat truth.
						var intruded: bool = _ZoneOfControl.is_intruded(oc)
						var home_fid: String = _EntityAccess.formation_id_str(oc)
						if intruded or home_fid != side:
							in_lane_intruders.append(oc)
							continue
						names.append(nm)
						footwork_sources.append(oc)
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
					cell.text = _EntityAccess.get_display_name(c, _EntityAccess.id_int(c))
					cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
					footwork_sources.append(c)
				else:
					cell.text = "—"
					cell.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
			cell.add_theme_font_size_override("font_size", 12)
			cell.custom_minimum_size = Vector2(72, 0)
			if not in_lane_intruders.is_empty():
				cell.tooltip_text = "Intruder(s) in this lane are shown below in Intruders."
			_append_footwork_tooltip(cell, footwork_sources)
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

	var istrp: Variant = diagram_root.get_meta("_intruder_strip", null)
	if istrp != null and istrp is HBoxContainer:
		for ch in (istrp as HBoxContainer).get_children():
			ch.queue_free()
		var ilab := Label.new()
		ilab.text = "Intruders"
		ilab.add_theme_font_size_override("font_size", 10)
		ilab.add_theme_color_override("font_color", Color(0.8, 0.52, 0.42))
		ilab.custom_minimum_size = Vector2(48, 0)
		(istrp as HBoxContainer).add_child(ilab)
		for fi in range(files):
			var intr_label := Label.new()
			var in_list: Array = intruders_by_file.get(fi, [])
			if in_list.is_empty():
				intr_label.text = "—"
				intr_label.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
				intr_label.tooltip_text = "No intruders at file %d" % fi
			else:
				var names_i: Array = []
				for ic in in_list:
					var nm_i: String = _EntityAccess.get_display_name(ic, _EntityAccess.id_int(ic))
					var d: int = _EntityAccess.tactical_penetration_depth_int(ic)
					names_i.append("%s(d%d)" % [nm_i, d])
				intr_label.text = str(names_i[0]) if names_i.size() == 1 else "%s +%d" % [str(names_i[0]), names_i.size() - 1]
				intr_label.add_theme_color_override("font_color", Color(0.92, 0.62, 0.5))
				intr_label.tooltip_text = "Intruding at file %d: %s" % [fi, ", ".join(names_i)]
			intr_label.add_theme_font_size_override("font_size", 11)
			intr_label.custom_minimum_size = Vector2(72, 0)
			(istrp as HBoxContainer).add_child(intr_label)

	var dstrp: Variant = diagram_root.get_meta("_deployed_strip", null)
	if dstrp != null and dstrp is HBoxContainer:
		for ch in (dstrp as HBoxContainer).get_children():
			ch.queue_free()
		var dlab := Label.new()
		dlab.text = "Deployed"
		dlab.add_theme_font_size_override("font_size", 10)
		dlab.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		dlab.custom_minimum_size = Vector2(48, 0)
		(dstrp as HBoxContainer).add_child(dlab)
		if deployed_intruders.is_empty():
			var none := Label.new()
			none.text = "—"
			none.add_theme_font_size_override("font_size", 11)
			none.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
			none.custom_minimum_size = Vector2(72, 0)
			(dstrp as HBoxContainer).add_child(none)
		else:
			for cdi in deployed_intruders:
				var item := Label.new()
				var nm_d: String = _EntityAccess.get_display_name(cdi, _EntityAccess.id_int(cdi))
				var host_d: String = _ZoneOfControl.intrusion_host_fid(cdi)
				var file_d: int = _EntityAccess.intrusion_anchor_or_file_int(cdi)
				var depth_d: int = _EntityAccess.tactical_penetration_depth_int(cdi)
				item.text = "%s@%s:f%d(d%d)" % [nm_d, host_d, file_d, depth_d]
				item.add_theme_font_size_override("font_size", 11)
				item.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
				item.custom_minimum_size = Vector2(72, 0)
				(dstrp as HBoxContainer).add_child(item)
