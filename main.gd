extends Node2D

## Overworld → `CombatFlow.start_combat` → `BattleScene` / `CombatManager`.

const _EncounterNode := preload("res://world/EncounterNode.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")

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
	EncounterSpawner.spawn_encounters(self, rng, 2, 7, enemy_scene)
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
	# Detect encounter on tile (one marker per encounter; enemies spawn when combat starts)
	var encounter = _get_encounter_on_tile(p_tile)
	if encounter != null:
		var ready: Dictionary = _CampaignBridge.can_enter_combat(self)
		if not bool(ready.get("ok", false)):
			push_warning("[World] %s" % str(ready.get("message", "Cannot enter combat.")))
			return
		if _CampaignBridge.party_has_untreated_wounds(self):
			print(
				"[World] Party has untreated wounds — stabilize in battle medical phase or risk bleed-out on the map."
			)
		_CampaignBridge.prepare_combat_from_encounter(self, encounter)
		var enemies: Array = encounter.spawn_enemies(self, rng)
		encounter.queue_free()
		if not enemies.is_empty():
			await CombatFlow.start_combat(self, enemies)
		return
	_CampaignBridge.advance_party_overworld_minute(self)

func _get_encounter_on_tile(tile: Vector2i) -> Node:
	for child in get_children():
		if child.get_script() == _EncounterNode and _tile_coords(child.position) == tile:
			return child
	return null

func _on_battle_ended(winner: String, defeated: Node) -> void:
	await CombatFlow.handle_battle_ended(self, winner, defeated)

func _print_node_tree(node: Node, indent: String = "") -> void:
	if node == null:
		return
	print(indent, node.name, "<", node.get_class(), ">")
	for child in node.get_children():
		_print_node_tree(child, indent + "  ")
