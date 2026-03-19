class_name FormationLayoutBuilder
extends RefCounted

const _FormationPreset := preload("res://combat/FormationPreset.gd")

## Builds formation grid UI: rank×file layout with unit spacing from formation density.
## Reparents existing combatant rows from VBoxContainers into GridContainers by (rank, file).

## Converts list containers to formation grids. Removes rows from list_parent, creates GridContainer,
## reparents rows into grid in (rank, file) order, adds placeholders for empty slots.
## manager: CombatManager (has combatants). preset: { files, ranks, density }. side: "player"|"enemy".
static func apply_formation_layout(
	manager: Node,
	list_parent: Control,
	_id_to_controls: Dictionary,
	preset: Dictionary,
	side: String
) -> void:
	var files: int = preset.get("files", 1)
	var ranks: int = preset.get("ranks", 1)
	var density: String = preset.get("density", "normal")
	var sep: int = _FormationPreset.separation_px_from_density(density)

	# Map (rank, file) -> combatant for this side
	var slot_to_combatant: Dictionary = {}
	var combatants: Array = manager.get_combatants() if manager.has_method("get_combatants") else []
	for c in combatants:
		if c.get("side", "") != side:
			continue
		var r: int = c.get("rank", 0)
		var f: int = c.get("file", 0)
		slot_to_combatant[Vector2i(r, f)] = c

	# Remove existing rows from list parent
	var rows_to_reparent: Array = []
	for child in list_parent.get_children():
		if child.name.begins_with("combat_row_"):
			list_parent.remove_child(child)
			rows_to_reparent.append(child)

	# Create GridContainer and add as single child of list parent
	var grid = GridContainer.new()
	grid.name = "FormationGrid_" + side
	grid.columns = files
	grid.add_theme_constant_override("h_separation", sep)
	grid.add_theme_constant_override("v_separation", sep)
	list_parent.add_child(grid)

	# Map combatant id -> row for reparenting
	var id_to_row: Dictionary = {}
	for row in rows_to_reparent:
		# Row name is "combat_row_N"
		var parts = row.name.split("_")
		if parts.size() >= 3:
			var cid = int(parts[2])
			id_to_row[cid] = row

	# Fill grid in rank-major order (rank 0 front, then rank 1, ...)
	for rank in range(ranks):
		for file in range(files):
			var c = slot_to_combatant.get(Vector2i(rank, file), null)
			if c != null:
				var cid: int = c.get("id", -1)
				var row = id_to_row.get(cid, null)
				if row != null:
					grid.add_child(row)
				else:
					_add_placeholder(grid, rank, file)
			else:
				_add_placeholder(grid, rank, file)


static func _add_placeholder(grid: GridContainer, rank: int, file: int) -> void:
	var placeholder = Control.new()
	placeholder.custom_minimum_size = Vector2(80, 24)
	placeholder.name = "formation_slot_%d_%d" % [rank, file]
	grid.add_child(placeholder)
