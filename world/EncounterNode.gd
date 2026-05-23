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
	rect.color = Color(0.2, 0.55, 0.95, 1) if not soak_preset_id.is_empty() else Color(0.9, 0.2, 0.2, 1)
	add_child(rect)
	if not soak_preset_id.is_empty():
		var lbl := Label.new()
		lbl.name = "SoakPresetLabel"
		lbl.text = soak_preset_id
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(lbl)
## Holds spawn config; enemies are instantiated when combat starts.
## Matches how other games (FF, DQ) handle encounters: one icon per encounter, spawn units on engage.

@export var enemy_count: int = 1
## Copied to world meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** when combat starts (doctrine, morale, posture, …).
@export var encounter_config: Dictionary = {}
## Optional enemy **`CombatManager.start`** preset; empty → default for **`enemy_count`**.
@export var enemy_formation: Dictionary = {}
## Non-empty when spawned via **`SoakEncounterPresets`** (cyan map marker).
var soak_preset_id: String = ""
var enemy_scene: PackedScene


func get_combat_encounter_dict() -> Dictionary:
	return encounter_config.duplicate(true)


func get_enemy_formation_dict() -> Dictionary:
	if not enemy_formation.is_empty():
		return enemy_formation.duplicate(true)
	return FormationPreset.default_for_count(mini(enemy_count, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP))

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
	var cap: int = CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP
	var n: int = mini(enemy_count, cap)
	var enemies: Array = []
	for i in n:
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
		var force_weapon: String = str(
			encounter_config.get(SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "")
		).strip_edges()
		if not force_weapon.is_empty():
			EncounterSpawner.equip_weapon_id(enemy, force_weapon)
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
