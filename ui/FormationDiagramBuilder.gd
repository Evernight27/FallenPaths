class_name FormationDiagramBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")

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
	if grid == null or manager == null or not manager.has_method("get_combatants"):
		return

	var files: int = preset.get("files", 1)
	var ranks: int = preset.get("ranks", 1)

	# Map (rank, file) -> combatant
	var slot_to_combatant: Dictionary = {}
	for c in manager.get_combatants():
		if c.get("side", "") != side:
			continue
		if not c.get("alive", true):
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
			var c = slot_to_combatant.get(Vector2i(rank, file), null)
			var cell = Label.new()
			if c != null:
				cell.text = _EntityAccess.get_display_name(c, c.get("id", -1))
				cell.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
			else:
				cell.text = "—"
				cell.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
			cell.add_theme_font_size_override("font_size", 12)
			cell.custom_minimum_size = Vector2(72, 0)
			grid.add_child(cell)
