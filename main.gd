extends Node2D

@onready var tilemap: TileMap = $TileMap

@export var enemy_scene: PackedScene

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _tile_coords(pos: Vector2) -> Vector2i:
	return Vector2i(floor((pos.x - 32) / 64.0), floor((pos.y - 32) / 64.0))

func _get_available_species_paths() -> Array:
	var paths: Array = []
	var dir = DirAccess.open("res://species")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.ends_with(".tres"):
				paths.append("res://species/" + file)
			file = dir.get_next()
	return paths

func _ready():
	# Match FallenFramework: fill screen — maximized window + stretch to viewport
	var main_window = get_tree().root
	main_window.content_scale_size = Vector2i(1920, 1080)
	main_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	main_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	main_window.mode = Window.MODE_MAXIMIZED

	# Generate tile texture if it doesn't exist
	_generate_tile_texture_if_needed()
	
	# Wait a frame for texture to be ready
	await get_tree().process_frame
	
	# Create tileset programmatically
	_setup_tileset()
	
	# Fill the 3x3 grid with tiles
	var source_id = 0
	var atlas_coords = Vector2i(0, 0)
	
	for x in range(3):
		for y in range(3):
			var coords = Vector2i(x, y)
			tilemap.set_cell(0, coords, source_id, atlas_coords)
	
	print("3x3 grid created!")
	
	# Randomize RNG and spawn enemy group (all enemies on same tile as one encounter)
	rng.randomize()
	_spawn_enemy_group(2)
	# Assign player species *before* party setup so party UI shows correct stats
	if has_node("Character"):
		var player = $Character
		var human_path = "res://species/human.tres"
		if ResourceLoader.exists(human_path):
			var human_res = load(human_path)
			if human_res != null and "species" in player:
				player.species = human_res
				if player.has_method("apply_species"):
					player.apply_species()
		if player.has_method("equip_armor") and player.has_method("equip_weapon"):
			_equip_random_equipment(player)
		# Disable input for companion so only player controls movement (companion is hidden, part of party icon)
		if has_node("Character/Companion"):
			var companion = $Character/Companion
			companion.set_process_input(false)
			if ResourceLoader.exists(human_path):
				var human_res = load(human_path)
				if human_res != null and "species" in companion:
					companion.species = human_res
					if companion.has_method("apply_species"):
						companion.apply_species()
			if companion.has_method("equip_armor") and companion.has_method("equip_weapon"):
				_equip_random_equipment(companion)
	# Setup party manager (after species so snapshot has correct stats)
	var party_manager_script = load("res://PartyManager.gd")
	if party_manager_script:
		var pm = party_manager_script.new()
		# parent to root so it's accessible globally
		get_tree().root.add_child(pm)
		# add the player character as first member if present
		if has_node("Character"):
			pm.add_member($Character)
		# add companion as second party member (lives inside Character, represented by single icon)
		if has_node("Character/Companion"):
			pm.add_member($Character/Companion)
		# create party menu and attach to root for later use
		var party_menu_script = load("res://ui/PartyMenu.gd")
		if party_menu_script:
			var party_menu = party_menu_script.new()
			# Ensure there's a high-layer overlay so the party menu appears above other CanvasLayers
			var root = get_tree().root
			var overlay = null
			for child in root.get_children():
				if child.name == "UIOverlayLayer":
					overlay = child
					break
			if overlay == null:
				overlay = CanvasLayer.new()
				overlay.name = "UIOverlayLayer"
				overlay.layer = 100
				root.add_child(overlay)
			# Add the party menu to the overlay
			overlay.add_child(party_menu)
			# Create a Party button using anchor presets (similar to fallenFramework)
			var party_button = Button.new()
			party_button.name = "PartyButton"
			party_button.text = "Party"
			party_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
			party_button.offset_left = 10
			party_button.offset_top = 10
			party_button.offset_right = 110
			party_button.offset_bottom = 50
			party_button.focus_mode = Control.FOCUS_NONE
			party_button.mouse_filter = Control.MOUSE_FILTER_STOP
			# Match fallenFramework defaults: sized and anchored top-left with offsets
			party_button.custom_minimum_size = Vector2(100, 32)
			party_button.add_theme_font_size_override("font_size", 16)
			party_button.z_index = 101
			overlay.add_child(party_button)
			party_button.connect("pressed", Callable(self, "_on_party_button_pressed"))
			# store on self for button handler
			self.set_meta("party_manager", pm)
			self.set_meta("party_menu", party_menu)
	# connect to player moved signal to detect encounters
	if has_node("Character"):
		var player = $Character
		if player.has_signal("moved"):
			player.connect("moved", Callable(self, "_on_player_moved"))
		# Connect party button if present
		if has_node("PartyButton"):
			$PartyButton.connect("pressed", Callable(self, "_on_party_button_pressed"))

func _equip_random_equipment(entity: Node) -> void:
	if entity == null:
		return
	var options_by_part: Dictionary = ArmorConstants.get_armor_options_by_part()
	for part in options_by_part.keys():
		var ids: Array = options_by_part[part]
		if ids.is_empty():
			continue
		var piece_id: String = ids[rng.randi() % ids.size()]
		var piece = ArmorPiece.create_from_definition(piece_id)
		if piece != null and entity.has_method("equip_armor"):
			entity.equip_armor(part, piece)
	var weapon_ids: Array = WeaponConstants.get_all_weapon_ids()
	if weapon_ids.is_empty():
		return
	var weapon_id: String = weapon_ids[rng.randi() % weapon_ids.size()]
	var w = Weapon.create_from_definition(weapon_id)
	if w != null and entity.has_method("equip_weapon"):
		entity.equip_weapon(w)

func _on_party_button_pressed() -> void:
	var pm = self.get_meta("party_manager")
	var menu = self.get_meta("party_menu")
	if pm and menu:
		menu.show_party(pm.get_members())

func _spawn_enemy_group(count: int):
	# Spawn a group of enemies on the same tile (one encounter per tile)
	if enemy_scene == null:
		enemy_scene = load("res://enemy/Enemy.tscn")
	if enemy_scene == null:
		print("No enemy scene found to spawn.")
		return
	# Pick one tile for the whole group, avoiding party's tile
	var p_tile = Vector2i(-1, -1)
	if has_node("Character"):
		p_tile = _tile_coords($Character.position)
	var tx = 0
	var ty = 0
	var tries = 0
	while true:
		tx = rng.randi_range(0, 2)
		ty = rng.randi_range(0, 2)
		tries += 1
		var tile = Vector2i(tx, ty)
		if tile != p_tile:
			break
		if tries > 100:
			break
	var tile_center = Vector2(tx * 64 + 32, ty * 64 + 32)
	var species_paths := _get_available_species_paths()
	if species_paths.is_empty():
		species_paths = ["res://species/goblin.tres"]
	for i in count:
		var enemy = enemy_scene.instantiate()
		enemy.position = tile_center
		var species_res_path = species_paths[rng.randi() % species_paths.size()]
		if ResourceLoader.exists(species_res_path):
			var s = load(species_res_path)
			if s != null and "species" in enemy:
				enemy.species = s
		add_child(enemy)
		if enemy.species != null and enemy.has_method("apply_species"):
			enemy.apply_species()
		if enemy.has_method("equip_armor") and enemy.has_method("equip_weapon"):
			_equip_random_equipment(enemy)

func _on_player_moved():
	var player = $Character
	var p_tile = _tile_coords(player.position)
	# Build set of party member nodes so we don't treat them as enemies
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
		# identify enemies by having take_damage method (CoreEntity)
		if child is Node2D and child.has_method("take_damage"):
			var e_tile = _tile_coords(child.position)
			if e_tile == p_tile:
				enemies_on_tile.append(child)
	if not enemies_on_tile.is_empty():
		_start_combat(enemies_on_tile)
		return
	# No combat: advance time by 1 minute; bleeding and blood loss continue, then healing (medical realism)
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
		if entity.has_method("process_bleeding"):
			entity.process_bleeding(SECONDS_PER_MOVE)
		if entity.has_method("process_blood_loss"):
			entity.process_blood_loss(SECONDS_PER_MOVE)
		if entity.has_method("process_healing"):
			entity.process_healing(SECONDS_PER_MOVE)

func _find_party_button():
	# Prefer the named UI overlay where the PartyButton is added, then fallback to a broader search.
	var root = get_tree().root
	for child in root.get_children():
		if "name" in child and child.name == "UIOverlayLayer":
			# direct child lookup
			if child.has_node("PartyButton"):
				return child.get_node("PartyButton")
			# or inspect its children directly
			for gc in child.get_children():
				if "name" in gc and gc.name == "PartyButton":
					return gc
	# fallback: try a safe recursive search among root children
	for child in root.get_children():
		if child.has_method("find_node"):
			var pb = child.find_node("PartyButton", true, false)
			if pb != null:
				return pb
		if "name" in child and child.name == "PartyButton":
			return child
	return null
func _start_combat(p_enemies: Array):
	# Gather all party members as players
	var players: Array = []
	var pm = get_meta("party_manager", null) if has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for member in pm.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if is_instance_valid(node_ref) and not (node_ref as Node).is_dead() if node_ref.has_method("is_dead") else true:
				players.append(node_ref)
	if players.is_empty():
		return
	# Disable input for all player characters
	for p in players:
		if p.has_method("set_process_input"):
			p.set_process_input(false)
	# hide the party button (it's parented to the root overlay)
	var _pb = _find_party_button()
	if _pb:
		_pb.visible = false
	# instantiate battle scene wrapper (programmatic UI avoids tscn parent-path fragility)
	var battle_script = load("res://ui/BattleScene.gd")
	if battle_script == null:
		print("BattleScene script missing")
		return
	# parent the battle to the scene root so hiding the current scene
	# doesn't hide the battle UI. Remember the current scene so it can be restored.
	var current = get_tree().get_current_scene()
	var battle = battle_script.new()
	battle.parent_scene = current
	get_tree().root.add_child(battle)
	# Store enemies on main scene for cleanup when player wins (battle may free before callback)
	set_meta("_combat_enemies", p_enemies)
	# wait a frame to ensure nodes are ready
	await get_tree().process_frame
	if battle.has_method("start"):
		battle.start(players, p_enemies)
	await get_tree().process_frame
	print("--- Battle debug: instantiated & parented ---")
	print("battle:", battle, " child_count:", battle.get_child_count())
	# listen for end
	if battle.has_signal("battle_ended"):
		battle.connect("battle_ended", Callable(self, "_on_battle_ended"), CONNECT_ONE_SHOT)

func _on_battle_ended(winner: String, _defeated: Node) -> void:
	var player = get_node_or_null("Character")
	# wait a frame to allow the battle node to free and parent_scene to be restored
	await get_tree().process_frame
	# Player lost: don't re-enable input on a dead character; show outcome
	var player_lost := (winner != "player")
	if player_lost:
		print("You were defeated.")
		# Optionally: get_tree().reload_current_scene() for full reset, or show game-over UI
		return
	# Player won: re-enable input and clean up
	var pm = get_meta("party_manager", null) if has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for member in pm.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if is_instance_valid(node_ref) and node_ref.has_method("set_process_input"):
				node_ref.set_process_input(node_ref == player)  # Only player gets input
	var _pb = _find_party_button()
	if _pb:
		_pb.visible = true
	if player != null and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D")
		if cam and cam.has_method("make_current"):
			cam.make_current()
	# Remove all defeated enemies from the scene (stored when combat started)
	if has_meta("_combat_enemies"):
		for enemy in get_meta("_combat_enemies"):
			if is_instance_valid(enemy) and enemy is Node:
				enemy.queue_free()
				print("Enemy defeated.")
		remove_meta("_combat_enemies")

func _print_node_tree(node: Node, indent: String = "") -> void:
	if node == null:
		return
	print(indent, node.name, "<", node.get_class(), ">")
	for child in node.get_children():
		_print_node_tree(child, indent + "  ")

func _setup_tileset():
	var texture_path = "res://tile_texture.png"
	
	# Load or create texture
	var texture: Texture2D
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path) as Texture2D
	else:
		print("Warning: Texture not found, creating default...")
		var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
		img.fill(Color(0.4, 0.6, 0.8))
		var img_texture = ImageTexture.create_from_image(img)
		texture = img_texture
	
	if texture == null:
		print("Error: Could not load or create texture!")
		return
	
	# Create a new TileSet
	var new_tileset = TileSet.new()
	
	# Create TileSetAtlasSource
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	
	# Create tile at (0, 0) in the atlas
	var tile_coords = Vector2i(0, 0)
	atlas_source.create_tile(tile_coords)
	
	# Add the source to the tileset (source_id will be 0)
	var source_id = new_tileset.add_source(atlas_source)
	
	# Set tile size
	new_tileset.tile_size = Vector2i(64, 64)
	
	# Assign to tilemap
	tilemap.tile_set = new_tileset
	
	print("TileSet created successfully with source_id: ", source_id)

func _generate_tile_texture_if_needed():
	var texture_path = "res://tile_texture.png"
	
	# Check if texture exists and is valid
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path) as Texture2D
		if texture != null:
			var texture_image = texture.get_image()
			if texture_image != null and texture_image.get_width() == 64 and texture_image.get_height() == 64:
				print("Tile texture exists and is valid")
				return
	
	# Texture doesn't exist or is invalid, try to generate it
	print("Generating tile texture...")
	var new_image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	new_image.fill(Color(0.4, 0.6, 0.8))
	
	# Draw border
	var border_color = Color(0.2, 0.3, 0.4)
	for x in range(64):
		new_image.set_pixel(x, 0, border_color)
		new_image.set_pixel(x, 63, border_color)
	for y in range(64):
		new_image.set_pixel(0, y, border_color)
		new_image.set_pixel(63, y, border_color)
	
	# Try to save - this will work in editor but not at runtime for res://
	var error = new_image.save_png(texture_path)
	if error == OK:
		print("Generated tile texture at ", texture_path)
	else:
		print("Could not save texture (this is normal at runtime).")
		print("Please run create_tile_texture.gd in the editor (File > Run Script)")
