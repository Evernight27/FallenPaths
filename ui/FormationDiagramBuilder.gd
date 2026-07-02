class_name FormationDiagramBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _UiConstants := preload("res://ui/BattleUIConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")

## Builds a compact visual formation diagram: rankÃ - file grid with per-unit health bars + names.
## Cell label suffix order (footing): optional footwork Ã¢â ' **`[HiL]`** guard Ã¢â ' **`[Wrath]`** form — `_cell_label_with_footwork`. LIVE_PATHS **`#battle-ui`** · **`#wf-soak-audit-status`** · **`#wf-footing-doc-map`**.
## Shows Front (rank 0) and Back (rank 1+) so formation changes (swap rank, etc.) are trackable.
## Canonical: PartyRowFormatter.total_body_health_ratio / body_functionality_ratio for bar fill + tint.
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
	title.text = "Enemies" if side == _CombatConstants.SIDE_ENEMY else "Party"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	vbox.add_child(title)

	var zoc_line = Label.new()
	zoc_line.name = "ZocLine"
	zoc_line.add_theme_font_size_override("font_size", 10)
	zoc_line.add_theme_color_override("font_color", Color(0.55, 0.62, 0.68))
	_RowFormatter.configure_wrapped_label(zoc_line)
	vbox.add_child(zoc_line)

	var fled_line = Label.new()
	fled_line.name = "FledLine"
	fled_line.visible = false
	fled_line.add_theme_font_size_override("font_size", 10)
	fled_line.add_theme_color_override("font_color", Color(0.62, 0.58, 0.52))
	_RowFormatter.configure_wrapped_label(fled_line)
	vbox.add_child(fled_line)

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
	root.set_meta("_fled_line", fled_line)
	_refresh_internal(root)
	return root


static func refresh(diagram_root: Control) -> void:
	if diagram_root == null:
		return
	_refresh_internal(diagram_root)


## Harness: describe grid children when health-bar probe fails.
static func debug_grid_cell_summary(grid: GridContainer) -> String:
	if grid == null:
		return "grid=null"
	var parts: PackedStringArray = PackedStringArray()
	for child in grid.get_children():
		var kind: String = child.get_class()
		var extra: String = ""
		if child is Label:
			extra = " text='%s'" % str((child as Label).text)
		else:
			var bars: int = 0
			for node in _nodes_under(child):
				if node is ProgressBar:
					bars += 1
			extra = " bars=%d children=%d" % [bars, child.get_child_count()]
		parts.append("%s%s" % [kind, extra])
	return "; ".join(parts)


## First formation health bar under a diagram grid (harness / tests). Skips rank-column labels.
static func first_health_bar_in_grid(grid: GridContainer) -> ProgressBar:
	if grid == null:
		return null
	for child in grid.get_children():
		if child is Label:
			continue
		for node in _nodes_under(child):
			if node is ProgressBar:
				return node as ProgressBar
	return null


static func _nodes_under(node: Node) -> Array:
	var out: Array = [node]
	for ch in node.get_children():
		out.append_array(_nodes_under(ch))
	return out


## All name labels under a grid cell (harness / tests).
static func labels_under_cell(node: Node) -> Array:
	var out: Array = []
	if node is Label:
		out.append(node)
	for ch in node.get_children():
		out.append_array(labels_under_cell(ch))
	return out


static func _cell_label_with_footwork(base: String, footwork_sources: Array) -> String:
	if base.is_empty() or base == "\u2014" or footwork_sources.is_empty():
		return base
	var text: String = base
	var got_fw: bool = false
	var got_grd: bool = false
	var got_form: bool = false
	var got_leader: bool = false
	for raw in footwork_sources:
		if raw is not Dictionary:
			continue
		var oc: Dictionary = raw
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
		if not got_form:
			var form: String = _UiHints.weapon_form_diagram_suffix(oc)
			if not form.is_empty():
				text += form
				got_form = true
		if not got_leader:
			var ldr: String = _UiHints.party_leader_diagram_suffix(oc)
			if ldr.is_empty():
				ldr = _UiHints.enemy_leader_diagram_suffix(oc)
			if not ldr.is_empty():
				text += ldr
				got_leader = true
		if got_fw and got_grd and got_form and got_leader:
			break
	return text


static func _append_cell_tooltips(cell: Control, combatants: Array, manager: Node = null) -> void:
	if cell == null:
		return
	var lines: PackedStringArray = []
	for raw in combatants:
		if raw is not Dictionary:
			continue
		var oc: Dictionary = raw
		var nm: String = _EntityAccess.get_display_name(oc, _EntityAccess.id_int(oc))
		var stats: Dictionary = _EntityAccess.stats_dict(oc)
		var hp_pct: int = int(roundf(_RowFormatter.total_body_health_ratio(stats) * 100.0))
		var fn_pct: int = int(roundf(_RowFormatter.body_functionality_ratio(oc, manager) * 100.0))
		lines.append("%s — body %d%% · function %d%%" % [nm, hp_pct, fn_pct])
		for line in _UiHints.formation_cell_tooltip_lines(oc, nm, manager):
			lines.append(line)
	if lines.is_empty():
		return
	cell.tooltip_text = "\n".join(lines)


static func _formation_health_bar_fill_style(functionality_ratio: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _RowFormatter.formation_health_bar_fill_color(functionality_ratio)
	style.set_corner_radius_all(1)
	return style


static func _make_formation_health_bar(combatant: Dictionary, manager: Node = null) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	var stats: Dictionary = _EntityAccess.stats_dict(combatant)
	var health_ratio: float = _RowFormatter.total_body_health_ratio(stats)
	var func_ratio: float = _RowFormatter.body_functionality_ratio(combatant, manager)
	bar.value = health_ratio * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, _UiConstants.FORMATION_HEALTH_BAR_HEIGHT)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("background", _UiConstants.progress_bar_background_style())
	bar.add_theme_stylebox_override("fill", _formation_health_bar_fill_style(func_ratio))
	return bar


static func _make_unit_stack(combatant: Dictionary, display_name: String, manager: Node = null) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	stack.add_child(_make_formation_health_bar(combatant, manager))
	var name_lbl := Label.new()
	name_lbl.text = _cell_label_with_footwork(display_name, [combatant])
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
	stack.add_child(name_lbl)
	return stack


static func _build_formation_cell(
	footwork_sources: Array,
	unit_entries: Array,
	empty_dash: bool,
	manager: Node
) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 2)
	cell.custom_minimum_size = Vector2(84, 0)
	if empty_dash:
		var dash := Label.new()
		dash.text = "—"
		dash.add_theme_font_size_override("font_size", 12)
		dash.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
		cell.add_child(dash)
	else:
		for entry in unit_entries:
			if entry is not Dictionary:
				continue
			var e: Dictionary = entry
			var oc: Dictionary = e.get("combatant", {})
			var nm: String = e.get("name", "")
			if oc.is_empty() or nm.is_empty():
				continue
			cell.add_child(_make_unit_stack(oc, nm, manager))
	if cell.get_child_count() == 0 and not footwork_sources.is_empty():
		for raw in footwork_sources:
			if raw is not Dictionary:
				continue
			var oc_fb: Dictionary = raw
			var nm_fb: String = _EntityAccess.get_display_name(oc_fb, _EntityAccess.id_int(oc_fb))
			cell.add_child(_make_unit_stack(oc_fb, nm_fb, manager))
			break
	if cell.get_child_count() == 0:
		var dash_fb := Label.new()
		dash_fb.text = "—"
		dash_fb.add_theme_font_size_override("font_size", 12)
		dash_fb.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
		cell.add_child(dash_fb)
	_append_cell_tooltips(cell, footwork_sources, manager)
	return cell


static func _refresh_internal(diagram_root: Control) -> void:
	var grid: GridContainer = diagram_root.get_meta("_formation_grid", null)
	var manager: Node = diagram_root.get_meta("_formation_manager", null)
	var side: String = diagram_root.get_meta("_formation_side", "")
	var preset: Dictionary = diagram_root.get_meta("_formation_preset", {})
	var zoc_line: Label = diagram_root.get_meta("_zoc_line", null)
	var fled_line: Label = diagram_root.get_meta("_fled_line", null)
	if zoc_line != null:
		zoc_line.text = ZoneOfControl.format_zone_control_line(manager, side)
	if grid == null or manager == null or not manager.has_method("get_combatants"):
		return

	var caps: Array = manager.get_combatants()
	var snap_by_id: Dictionary = {}
	for raw_cap in caps:
		if raw_cap is not Dictionary:
			continue
		var cap: Dictionary = raw_cap
		snap_by_id[_EntityAccess.id_int(cap)] = cap

	var files: int = preset.get("files", 1)
	var ranks: int = preset.get("ranks", 1)
	var formation: Dictionary = {}
	if "formations" in manager and manager.formations is Dictionary:
		formation = _FormationSlots.formation_record_for_manager(manager, side)
	var slot_map: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation, "slots")
	# Keep diagram bounds synced with actual slot occupancy (not just preset), so deep swaps/plugs remain visible.
	for k in slot_map.keys():
		if k is Vector2i:
			var kk: Vector2i = k
			ranks = maxi(ranks, kk.x + 1)
			files = maxi(files, kk.y + 1)

	# Map (rank, file) -> combatant still on the field (not fled / dead).
	var slot_to_combatant: Dictionary = {}
	var fled_names: PackedStringArray = PackedStringArray()
	for c in caps:
		if _EntityAccess.side_str(c) != side:
			continue
		if _EntityAccess.has_left_battlefield(c) and _EntityAccess.alive_bool(c, true):
			fled_names.append(_EntityAccess.get_display_name(c, _EntityAccess.id_int(c)))
			continue
		if not _EntityAccess.is_on_battlefield(c):
			continue
		var r: int = _EntityAccess.rank_int(c)
		var f: int = _EntityAccess.file_int(c)
		slot_to_combatant[Vector2i(r, f)] = c
	if fled_line != null:
		if fled_names.is_empty():
			fled_line.text = ""
			fled_line.visible = false
		else:
			fled_line.visible = true
			fled_line.text = "Fled: %s" % ", ".join(fled_names)

	# Clear existing children immediately (queue_free leaves stale names one frame).
	for child in grid.get_children():
		child.free()

	var display_files: Array = _FormationSlots.column_display_files(formation, files)
	if display_files.is_empty():
		for fi in range(files):
			display_files.append(fi)
	grid.columns = display_files.size() + 1

	# Build grid: first column = rank label, then file columns (gap mode shows empty gap cells)
	for rank in range(ranks):
		var rank_label = Label.new()
		rank_label.text = "Front" if rank == 0 else ("Back" if rank == 1 else "Rank %d" % (rank + 1))
		rank_label.add_theme_font_size_override("font_size", 11)
		rank_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		rank_label.custom_minimum_size = Vector2(48, 0)
		grid.add_child(rank_label)

		for file_idx in display_files:
			var file: int = int(file_idx)
			var key := Vector2i(rank, file)
			var occ: Array = _FormationSlots.normalize_cell(slot_map.get(key, []))
			var footwork_sources: Array = []
			var unit_entries: Array = []
			if not occ.is_empty():
				for cid in occ:
					var oc: Variant = snap_by_id.get(int(cid), null)
					if (
						oc != null
						and oc is Dictionary
						and _EntityAccess.is_on_battlefield(oc)
					):
						if _ZoneOfControl.zone_geometry_fid_from_row(manager, oc) != side:
							continue
						var nm: String = _EntityAccess.get_display_name(oc, _EntityAccess.id_int(oc))
						unit_entries.append({"combatant": oc, "name": nm})
						footwork_sources.append(oc)
			if unit_entries.is_empty():
				var fallback: Variant = slot_to_combatant.get(key, null)
				if fallback is Dictionary:
					var fc: Dictionary = fallback
					unit_entries.append({
						"combatant": fc,
						"name": _EntityAccess.get_display_name(fc, _EntityAccess.id_int(fc)),
					})
					if fc not in footwork_sources:
						footwork_sources.append(fc)
			var cell: Control = _build_formation_cell(
				footwork_sources, unit_entries, unit_entries.is_empty(), manager
			)
			grid.add_child(cell)
