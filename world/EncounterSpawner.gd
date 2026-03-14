class_name EncounterSpawner
extends RefCounted

## Spawns enemy encounters on the world map. Used by main.gd.
## parent: the Node2D world (has add_child, get_children, _tile_coords)

const TILE_SIZE := 64
const DEFAULT_SPECIES := [ResourcePaths.GOBLIN_SPECIES, ResourcePaths.HUMAN_SPECIES]

static func spawn_encounters(parent: Node, rng: RandomNumberGenerator, num_encounters: int, enemies_per_encounter: int, enemy_scene: PackedScene) -> void:
	var excluded_tiles: Array = []
	if parent.has_node("Character"):
		excluded_tiles.append(_tile_coords(parent.get_node("Character").position))
	for i in num_encounters:
		var used_tile = _spawn_enemy_group(parent, rng, enemies_per_encounter, excluded_tiles, enemy_scene)
		if used_tile != null:
			excluded_tiles.append(used_tile)

static func _tile_coords(pos: Vector2) -> Vector2i:
	return Vector2i(floor((pos.x - 32) / 64.0), floor((pos.y - 32) / 64.0))

static func _get_available_species_paths() -> Array:
	var paths: Array = []
	var dir = DirAccess.open(ResourcePaths.SPECIES_DIR)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.ends_with(".tres"):
				paths.append(ResourcePaths.SPECIES_DIR + "/" + file)
			file = dir.get_next()
	return paths

static func _get_enemy_species_paths() -> Array:
	var all_paths := _get_available_species_paths()
	if all_paths.is_empty():
		return DEFAULT_SPECIES.duplicate()
	return all_paths

static func _spawn_enemy_group(parent: Node, rng: RandomNumberGenerator, count: int, excluded_tiles: Array, enemy_scene: PackedScene) -> Variant:
	var scene = enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	if scene == null:
		print("No enemy scene found to spawn.")
		return null
	var tx = 0
	var ty = 0
	var tries = 0
	var tile = Vector2i(0, 0)
	while true:
		tx = rng.randi_range(0, 2)
		ty = rng.randi_range(0, 2)
		tries += 1
		tile = Vector2i(tx, ty)
		var skip = false
		for et in excluded_tiles:
			if tile == et:
				skip = true
				break
		if not skip:
			break
		if tries > 100:
			return null
	var tile_center = Vector2(tx * TILE_SIZE + 32, ty * TILE_SIZE + 32)
	var species_paths := _get_enemy_species_paths()
	if species_paths.is_empty():
		species_paths = [ResourcePaths.GOBLIN_SPECIES]
	for i in count:
		var enemy = scene.instantiate()
		enemy.position = tile_center
		var species_res_path = species_paths[rng.randi() % species_paths.size()]
		if ResourceLoader.exists(species_res_path):
			var s = load(species_res_path)
			if s != null and "species" in enemy:
				enemy.species = s
		parent.add_child(enemy)
		if enemy.species != null and enemy.has_method("apply_species"):
			enemy.apply_species()
		if enemy.has_method("equip_armor") and enemy.has_method("equip_weapon"):
			equip_random_equipment(enemy, rng)
	return tile

static func equip_random_equipment(entity: Node, rng: RandomNumberGenerator) -> void:
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
