class_name EncounterNode
extends Node2D

const MARKER_SIZE := Vector2(64.0, 76.0)

## Holds spawn config; enemies are instantiated when combat starts.
@export var enemy_count: int = 1
## Copied to world meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** when combat starts (doctrine, morale, posture,
## --|).
@export var encounter_config: Dictionary = {}
## Optional enemy **`CombatManager.start`** preset; empty → default for **`enemy_count`**.
@export var enemy_formation: Dictionary = {}
## Non-empty when spawned via **`SoakEncounterPresets`** (cyan map marker).

## Singular map entity representing one encounter. One square on the map.
## One visual marker per encounter; unit count is separate (spawned when combat starts).

## Campaign contract label (Camp-1.4); set before add_child.
var contract_marker_label: String = ""
## `tutorial` | `contract` | "" (soak)
var marker_kind: String = ""
var soak_preset_id: String = ""
var enemy_scene: PackedScene


func _ready() -> void:
    var marker_root := Control.new()
    marker_root.name = "MarkerRoot"
    marker_root.custom_minimum_size = MARKER_SIZE
    marker_root.size = MARKER_SIZE
    marker_root.position = -MARKER_SIZE * 0.5
    marker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(marker_root)

    var rect := ColorRect.new()
    rect.name = "EncounterMarker"
    rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if not soak_preset_id.is_empty():
        rect.color = Color(0.2, 0.55, 0.95, 1)
    elif marker_kind == "tutorial":
        rect.color = Color(0.25, 0.72, 0.42, 1)
    else:
        rect.color = Color(0.9, 0.2, 0.2, 1)
    marker_root.add_child(rect)

    if not contract_marker_label.is_empty():
        _add_marker_label(marker_root, contract_marker_label, "ContractLabel", 10, Color(1, 0.95, 0.85, 1))
    elif not soak_preset_id.is_empty():
        _add_marker_label(marker_root, soak_preset_id, "SoakPresetLabel", 14, Color(1, 1, 1, 1))


func _add_marker_label(parent: Control, text: String, label_name: String, font_size: int, font_color: Color) -> void:
    var lbl := Label.new()
    lbl.name = label_name
    lbl.text = text
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl.clip_text = true
    lbl.add_theme_font_size_override("font_size", font_size)
    lbl.add_theme_color_override("font_color", font_color)
    lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    lbl.offset_left = 3.0
    lbl.offset_top = 3.0
    lbl.offset_right = -3.0
    lbl.offset_bottom = -3.0
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(lbl)


func get_combat_encounter_dict() -> Dictionary:
    return encounter_config.duplicate(true)


func get_enemy_formation_dict() -> Dictionary:
    if not enemy_formation.is_empty():
        return enemy_formation.duplicate(true)
    return FormationPreset.default_for_count(mini(enemy_count, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP))


func is_tutorial_encounter() -> bool:
    return encounter_config.get("tutorial", false)


## Spawns enemy units for combat. Call when player enters combat. Returns array of enemy nodes.
## parent: world node to add enemies to. rng: for resources/species/equipment randomization.
func spawn_enemies(parent: Node, rng: RandomNumberGenerator) -> Array:
    var scene = enemy_scene
    if scene == null:
        scene = ResourcePaths.get_enemy_scene()
    if scene == null:
        return []
    var species_paths := _get_species_paths_for_encounter()
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
        var force_weapon: String = (
            str(encounter_config.get(SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "")).strip_edges()
        )
        if not force_weapon.is_empty():
            EncounterSpawner.equip_weapon_id(enemy, force_weapon)
        enemies.append(enemy)
    _stamp_enemy_leader_from_config(enemies)
    return enemies


func _stamp_enemy_leader_from_config(enemies: Array) -> void:
    if enemies.is_empty():
        return
    var leader_idx: int = encounter_config.get(SoakEncounterPresets.ENCOUNTER_KEY_ENEMY_LEADER_INDEX, 0)
    if leader_idx < 0:
        return
    if leader_idx >= enemies.size():
        leader_idx = 0
    var leader: Variant = enemies[leader_idx]
    if leader != null and "is_enemy_leader" in leader:
        leader.is_enemy_leader = true


func _get_species_paths_for_encounter() -> Array:
    var pool: Variant = encounter_config.get("enemy_species_pool", [])
    if pool is Array and not (pool as Array).is_empty():
        return (pool as Array).duplicate()
    return _get_species_paths()


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
