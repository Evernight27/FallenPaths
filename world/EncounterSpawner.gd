class_name EncounterSpawner
extends RefCounted

const _EncounterNodeScript := preload("res://world/EncounterNode.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _OverworldMap := preload("res://world/OverworldMap.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")

## Spawns encounter markers on the world map. One square per encounter.
## Enemies are spawned when combat starts (EncounterNode.spawn_enemies).
## Matches FF/DQ style: map shows one icon per encounter; unit count is separate.

static func spawn_encounters(parent: Node, rng: RandomNumberGenerator, num_encounters: int, enemies_per_encounter: int, enemy_scene: PackedScene) -> void:
	var excluded_tiles: Array = []
	if parent.has_node("Character"):
		excluded_tiles.append(
			_CampaignBridge.overworld_tile_from_position(parent.get_node("Character").position)
		)
	for i in num_encounters:
		var used_tile = _spawn_encounter_marker(parent, rng, enemies_per_encounter, excluded_tiles, enemy_scene)
		if used_tile != null:
			excluded_tiles.append(used_tile)
static func _spawn_encounter_marker(parent: Node, rng: RandomNumberGenerator, enemy_count: int, excluded_tiles: Array, enemy_scene: PackedScene) -> Variant:
	var scene = enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	if scene == null:
		return null
	var tries = 0
	while tries < 100:
		var tile: Vector2i = _OverworldMap.random_tile(rng, parent)
		tries += 1
		var skip = false
		for et in excluded_tiles:
			if tile == et:
				skip = true
				break
		if skip:
			continue
		var tile_center = _CampaignBridge.overworld_tile_center(tile)
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
		skip.append(
			_CampaignBridge.overworld_tile_from_position(parent.get_node("Character").position)
		)
	for child in parent.get_children():
		if child.get_script() == _EncounterNodeScript:
			skip.append(_CampaignBridge.overworld_tile_from_position(child.position))
	var candidates: Array = []
	for pt in preferred_tiles:
		if pt is Vector2i and pt not in skip:
			candidates.append(pt)
	for tries in range(100):
		var tile: Vector2i
		if tries < candidates.size():
			tile = candidates[tries] as Vector2i
		else:
			tile = _OverworldMap.random_tile(rng, parent)
		if tile in skip:
			continue
		var encounter = _EncounterNodeScript.new()
		encounter.position = _CampaignBridge.overworld_tile_center(tile)
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


## D-persistence P2: read equipped weapon template id from a **`CoreEntity`** (or combatant node).
static func weapon_id_from_entity(entity: Node) -> String:
	if entity == null or not ("weapon" in entity):
		return ""
	var w: Variant = entity.weapon
	if w == null:
		return ""
	if w is Weapon:
		return str((w as Weapon).weapon_type).strip_edges()
	return ""


## D-persistence P2: body_part → armor definition id (empty values omitted).
static func armor_ids_from_entity(entity: Node) -> Dictionary:
	var out: Dictionary = {}
	if entity == null or not ("armor_slots" in entity):
		return out
	for part in entity.armor_slots.keys():
		var piece: Variant = entity.armor_slots[part]
		if piece is ArmorPiece:
			var piece_id: String = _armor_piece_id_from_instance(piece as ArmorPiece)
			if not piece_id.is_empty():
				out[str(part)] = piece_id
	return out


static func apply_equipment_snapshot(
	character: Node, weapon_id: String, armor_by_part: Dictionary
) -> void:
	if character == null:
		return
	if not weapon_id.is_empty():
		equip_weapon_id(character, weapon_id)
	if armor_by_part is Dictionary:
		for part in (armor_by_part as Dictionary).keys():
			var piece_id: String = str((armor_by_part as Dictionary)[part]).strip_edges()
			if piece_id.is_empty():
				continue
			var piece: Variant = ArmorPiece.create_from_definition(piece_id)
			if piece != null and character.has_method("equip_armor"):
				character.equip_armor(str(part), piece)


static func _armor_piece_id_from_instance(piece: ArmorPiece) -> String:
	if piece == null:
		return ""
	var options: Dictionary = ArmorConstants.get_armor_options_by_part()
	for ids in options.values():
		if ids is not Array:
			continue
		for raw_id in ids as Array:
			var piece_id: String = str(raw_id)
			var def: Dictionary = ArmorConstants.get_piece_definition(piece_id)
			if def.is_empty():
				continue
			if str(def.get("name", "")) == piece.display_name and str(def.get("body_part", "")) == piece.body_part:
				return piece_id
	return ""


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
