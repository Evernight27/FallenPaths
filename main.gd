extends Node2D

const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")

@onready var tilemap: TileMap = $TileMap

@export var enemy_scene: PackedScene

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _tile_coords(pos: Vector2) -> Vector2i:
	return Vector2i(floor((pos.x - 32) / 64.0), floor((pos.y - 32) / 64.0))

func _ready():
	# Match FallenFramework: fill screen — maximized window + stretch to viewport
	var main_window = get_tree().root
	main_window.content_scale_size = Vector2i(1920, 1080)
	main_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	main_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	main_window.mode = Window.MODE_MAXIMIZED

	# Generate tile texture if it doesn't exist
	TilesetSetup.generate_tile_texture_if_needed()
	
	# Wait a frame for texture to be ready
	await get_tree().process_frame
	
	# Create tileset programmatically
	TilesetSetup.setup_tileset(tilemap)
	
	# Fill the 3x3 grid with tiles
	var source_id = 0
	var atlas_coords = Vector2i(0, 0)
	
	for x in range(3):
		for y in range(3):
			var coords = Vector2i(x, y)
			tilemap.set_cell(0, coords, source_id, atlas_coords)
	
	print("3x3 grid created!")
	
	# Randomize RNG and spawn two enemy encounters on different tiles (for testing medical continuity between battles)
	rng.randomize()
	EncounterSpawner.spawn_encounters(self, rng, 2, 2, enemy_scene)
	# Assign player and companion species/equipment before party setup so party UI shows correct stats
	PlayerCompanionSetup.setup_player_and_companion(self, rng)
	# Setup party manager, party menu, and Party button (after species so snapshot has correct stats)
	PartySetup.setup_party(self)
	# Connect to player moved signal to detect encounters
	if has_node("Character"):
		var player = $Character
		if player.has_signal("moved"):
			player.connect("moved", Callable(self, "_on_player_moved"))

func _on_party_button_pressed() -> void:
	var pm = self.get_meta("party_manager")
	var menu = self.get_meta("party_menu")
	if pm and menu:
		menu.show_party(pm.get_members())

func _on_player_moved():
	var player = $Character
	var p_tile = _tile_coords(player.position)
	var party_nodes: Array = []
	var pm = get_meta("party_manager", null) if has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for member in pm.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if is_instance_valid(node_ref):
				party_nodes.append(node_ref)
	var enemies_on_tile: Array = []
	for child in get_children():
		if child in party_nodes:
			continue
		if child is Node2D and child.has_method("take_damage"):
			var e_tile = _tile_coords(child.position)
			if e_tile == p_tile:
				enemies_on_tile.append(child)
	if not enemies_on_tile.is_empty():
		await CombatFlow.start_combat(self, enemies_on_tile)
		return
	_advance_time_one_minute()

func _advance_time_one_minute() -> void:
	const SECONDS_PER_MOVE: float = 60.0
	var to_process: Array = []
	if has_node("Character"):
		to_process.append($Character)
	var pm = get_meta("party_manager", null) if has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for member in pm.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if is_instance_valid(node_ref) and node_ref != $Character:
				to_process.append(node_ref)
	for entity in to_process:
		_EntityTimeAdvance.advance(entity, SECONDS_PER_MOVE, true)

func _on_battle_ended(winner: String, defeated: Node) -> void:
	await CombatFlow.handle_battle_ended(self, winner, defeated)

func _print_node_tree(node: Node, indent: String = "") -> void:
	if node == null:
		return
	print(indent, node.name, "<", node.get_class(), ">")
	for child in node.get_children():
		_print_node_tree(child, indent + "  ")

