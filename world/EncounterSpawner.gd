class_name EncounterSpawner
extends RefCounted

const _EncounterNodeScript := preload("res://world/EncounterNode.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")

## Spawns encounter markers on the world map. One square per encounter.
## Enemies are spawned when combat starts (EncounterNode.spawn_enemies).
## Matches FF/DQ style: map shows one icon per encounter; unit count is separate.

const TILE_SIZE := 64

static func spawn_encounters(parent: Node, rng: RandomNumberGenerator, num_encounters: int, enemies_per_encounter: int, enemy_scene: PackedScene) -> void:
	var excluded_tiles: Array = []
	if parent.has_node("Character"):
		excluded_tiles.append(_tile_coords(parent.get_node("Character").position))
	for i in num_encounters:
		var used_tile = _spawn_encounter_marker(parent, rng, enemies_per_encounter, excluded_tiles, enemy_scene)
		if used_tile != null:
			excluded_tiles.append(used_tile)

static func _tile_coords(pos: Vector2) -> Vector2i:
	return Vector2i(floor((pos.x - 32) / 64.0), floor((pos.y - 32) / 64.0))

static func _spawn_encounter_marker(parent: Node, rng: RandomNumberGenerator, enemy_count: int, excluded_tiles: Array, enemy_scene: PackedScene) -> Variant:
	var scene = enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	if scene == null:
		return null
	var tx = 0
	var ty = 0
	var tries = 0
	while tries < 100:
		tx = rng.randi_range(0, 2)
		ty = rng.randi_range(0, 2)
		tries += 1
		var tile = Vector2i(tx, ty)
		var skip = false
		for et in excluded_tiles:
			if tile == et:
				skip = true
				break
		if skip:
			continue
		var tile_center = Vector2(tx * TILE_SIZE + 32, ty * TILE_SIZE + 32)
		var encounter = _EncounterNodeScript.new()
		encounter.position = tile_center
		encounter.enemy_count = mini(enemy_count, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP)
		encounter.enemy_scene = scene
		parent.add_child(encounter)
		return tile
	return null


## Dev soak marker (e.g. **`SoakEncounterPresets.PRESET_II2B_SWORD_DUEL`**) on first free tile.
static func spawn_soak_encounter_marker(
	parent: Node,
	preset_id: String,
	rng: RandomNumberGenerator,
	enemy_scene: PackedScene,
	excluded_tiles: Array = [],
	preferred_tiles: Array = []
) -> Variant:
	if preset_id.is_empty():
		return null
	var scene := enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	if scene == null:
		return null
	var skip: Array = excluded_tiles.duplicate()
	if parent.has_node("Character"):
		skip.append(_tile_coords(parent.get_node("Character").position))
	for child in parent.get_children():
		if child.get_script() == _EncounterNodeScript:
			skip.append(_tile_coords(child.position))
	var candidates: Array = []
	for pt in preferred_tiles:
		if pt is Vector2i and pt not in skip:
			candidates.append(pt)
	for tries in range(100):
		var tile: Vector2i
		if tries < candidates.size():
			tile = candidates[tries] as Vector2i
		else:
			tile = Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
		if tile in skip:
			continue
		var encounter = _EncounterNodeScript.new()
		encounter.position = Vector2(tile.x * TILE_SIZE + 32, tile.y * TILE_SIZE + 32)
		encounter.enemy_scene = scene
		if not _SoakPresets.apply_preset(encounter, preset_id):
			return null
		parent.add_child(encounter)
		return tile
	return null


static func equip_weapon_id(entity: Node, weapon_id: String) -> void:
	if entity == null or weapon_id.is_empty():
		return
	var w = Weapon.create_from_definition(weapon_id)
	if w != null and entity.has_method("equip_weapon"):
		entity.equip_weapon(w)


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
