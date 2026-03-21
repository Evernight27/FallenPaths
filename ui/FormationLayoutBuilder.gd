class_name FormationLayoutBuilder
extends RefCounted

const _FormationPreset := preload("res://combat/FormationPreset.gd")

## Builds formation grid UI: rank×file layout with unit spacing from formation density.
## Reparents existing combatant rows from VBoxContainers into GridContainers by (rank, file).

## Converts list containers to formation grids. Remarents rows into grid in (rank, file) order.
## Supports re-apply: when grid already exists, extracts rows from it and rebuilds.
## manager: CombatManager (has combatants). preset: { files, ranks, density }. side: "player"|"enemy".
static func apply_formation_layout(
	manager: Node,
	list_parent: Control,
	_id_to_controls: Dictionary,
	preset: Dictionary,
	side: String
) -> void:
	# Use manager's formation dimensions when available — CombatManager may override ranks/files
	# from combatant count (e.g. front_count, or preset.ranks missing), causing preset mismatch.
	var formation: Dictionary = {}
	if "formations" in manager and manager.formations is Dictionary:
		formation = manager.formations.get(side, {})
	var files: int = formation.get("files", preset.get("files", 1))
	var ranks: int = formation.get("ranks", preset.get("ranks", 1))
	var density: String = formation.get("density", preset.get("density", "normal"))
	var h_sep: int = _FormationPreset.separation_px_from_density(density)
	var v_sep: int = _FormationPreset.v_separation_px_from_density(density)  # Ranks closer than files

	# Map (rank, file) -> combatant for this side (alive only)
	var slot_to_combatant: Dictionary = {}
	# Map (rank, file) -> [combatant] for dead (keep at death position)
	var slot_to_dead: Dictionary = {}
	var combatants: Array = manager.get_combatants() if manager.has_method("get_combatants") else []
	for c in combatants:
		if c.get("side", "") != side:
			continue
		var r: int = c.get("rank", 0)
		var f: int = c.get("file", 0)
		var key := Vector2i(r, f)
		if not c.get("alive", true):
			if not slot_to_dead.has(key):
				slot_to_dead[key] = []
			slot_to_dead[key].append(c)
			continue
		slot_to_combatant[key] = c

	# Ensure grid covers all occupied slots (combatants may have rank/file beyond preset after plug etc.)
	for key in slot_to_combatant:
		ranks = maxi(ranks, key.x + 1)
		files = maxi(files, key.y + 1)
	for key in slot_to_dead:
		ranks = maxi(ranks, key.x + 1)
		files = maxi(files, key.y + 1)

	# Collect ALL rows (alive and dead) for reparenting
	var id_to_row: Dictionary = {}
	var grid: GridContainer = null
	for child in list_parent.get_children():
		if child.name.begins_with("combat_row_"):
			var cid = _row_id_from_name(child.name)
			list_parent.remove_child(child)
			if cid >= 0:
				id_to_row[cid] = child
		elif child is GridContainer and child.name == "FormationGrid_" + side:
			grid = child
			for gc in grid.get_children().duplicate():
				grid.remove_child(gc)
				# Slot vboxes (our structure) contain combat_row; extract rows from them
				if gc is VBoxContainer:
					for inner in gc.get_children().duplicate():
						gc.remove_child(inner)
						if inner.name.begins_with("combat_row_"):
							var cid = _row_id_from_name(inner.name)
							if cid >= 0:
								id_to_row[cid] = inner
					gc.queue_free()
				elif gc.name.begins_with("combat_row_"):
					var cid = _row_id_from_name(gc.name)
					if cid >= 0:
						id_to_row[cid] = gc
					# Do not free — we keep the row for reparenting
				else:
					gc.queue_free()

	if grid == null:
		grid = GridContainer.new()
		grid.name = "FormationGrid_" + side
		grid.columns = files
		grid.add_theme_constant_override("h_separation", h_sep)
		grid.add_theme_constant_override("v_separation", v_sep)
		list_parent.add_child(grid)

	# Build grid: each slot is a VBox containing [dead rows at this slot] [alive row or placeholder]
	# Defeated units stay at their death position (rank, file) instead of moving to bottom
	var insert_idx := 0
	for rank in range(ranks):
		for file in range(files):
			var key := Vector2i(rank, file)
			var slot_vbox := VBoxContainer.new()
			slot_vbox.add_theme_constant_override("separation", 2)
			slot_vbox.name = "formation_slot_%d_%d" % [rank, file]
			# Dead at this slot first (defeated stay where they fell)
			var dead_list: Array = slot_to_dead.get(key, [])
			for dc in dead_list:
				var row = id_to_row.get(dc.get("id", -1), null)
				if row != null:
					_modulate_dead_row(row)
					slot_vbox.add_child(row)
			# Alive occupant or placeholder
			var c = slot_to_combatant.get(key, null)
			if c != null:
				var row = id_to_row.get(c.get("id", -1), null)
				if row != null:
					slot_vbox.add_child(row)
			else:
				slot_vbox.add_child(_make_placeholder(rank, file))
			grid.add_child(slot_vbox)
			grid.move_child(slot_vbox, insert_idx)
			insert_idx += 1


static func _modulate_dead_row(row: Control) -> void:
	"""Visually dim defeated units (greyed out) so they're distinct from alive."""
	if row is CanvasItem:
		row.modulate = Color(0.65, 0.65, 0.65)

static func _row_id_from_name(name: String) -> int:
	var parts = name.split("_")
	if parts.size() >= 3:
		return int(parts[2])
	return -1

static func _make_placeholder(rank: int, file: int) -> Control:
	var placeholder = Control.new()
	placeholder.custom_minimum_size = Vector2(80, 24)
	placeholder.name = "formation_slot_%d_%d" % [rank, file]
	return placeholder
