class_name EncounterNode
extends Node2D

## Singular map entity representing one encounter. One square on the map.
## One visual marker per encounter; unit count is separate (spawned when combat starts).

func _ready() -> void:
	var rect = ColorRect.new()
	rect.name = "EncounterMarker"
	rect.offset_left = -30.0
	rect.offset_top = -30.0
	rect.offset_right = 30.0
	rect.offset_bottom = 30.0
	rect.color = Color(0.9, 0.2, 0.2, 1)
	add_child(rect)
## Holds spawn config; enemies are instantiated when combat starts.
## Matches how other games (FF, DQ) handle encounters: one icon per encounter, spawn units on engage.

@export var enemy_count: int = 1
var enemy_scene: PackedScene

## Spawns enemy units for combat. Call when player enters combat. Returns array of enemy nodes.
## parent: world node to add enemies to. rng: for species/equipment randomization.
func spawn_enemies(parent: Node, rng: RandomNumberGenerator) -> Array:
	var scene = enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	if scene == null:
		return []
	var species_paths := _get_species_paths()
	if species_paths.is_empty():
		species_paths = [ResourcePaths.GOBLIN_SPECIES]
	var enemies: Array = []
	for i in enemy_count:
		var enemy = scene.instantiate()
		enemy.position = position
		var species_res_path = species_paths[rng.randi() % species_paths.size()]
		if ResourceLoader.exists(species_res_path):
			var s = load(species_res_path)
			if s != null and "species" in enemy:
				enemy.species = s
		parent.add_child(enemy)
		if enemy.species != null and enemy.has_method("apply_species"):
			enemy.apply_species()
		if enemy.has_method("equip_armor") and enemy.has_method("equip_weapon"):
			EncounterSpawner.equip_random_equipment(enemy, rng)
		enemies.append(enemy)
	return enemies

func _get_species_paths() -> Array:
	var paths: Array = []
	var dir = DirAccess.open(ResourcePaths.SPECIES_DIR)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.ends_with(".tres"):
				paths.append(ResourcePaths.SPECIES_DIR + "/" + file)
			file = dir.get_next()
	return paths if not paths.is_empty() else [ResourcePaths.GOBLIN_SPECIES, ResourcePaths.HUMAN_SPECIES]
