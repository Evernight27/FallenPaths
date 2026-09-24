class_name ResourcePaths
extends RefCounted

## Central path constants for res:// resources. Use with load() or as references.
## Note: preload() requires literal strings and cannot use these at parse time.

# Scripts / scenes
const COMBAT_MANAGER := "res://combat/CombatManager.gd"
const PARTY_MANAGER := "res://world/PartyManager.gd"
const PARTY_MENU := "res://ui/company/PartyMenu.gd"

# Species
const SPECIES_DIR := "res://resources/species"
const HUMAN_SPECIES := "res://resources/species/human.tres"
const GOBLIN_SPECIES := "res://resources/species/goblin.tres"

# Scenes
const ENEMY_SCENE := "res://scenes/actors/enemy.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

# Assets
const TILE_TEXTURE := "res://assets/tiles/tile_texture.png"

## Scenes are loaded lazily (not preloaded at parse time): both attach CoreEntity.gd as
## their script, which is reachable from this class's dependency chain, so a parse-time
## preload here triggers a circular "Busy" load of the same scene.
static var _enemy_scene_cache: PackedScene = null
static var _battle_scene_cache: PackedScene = null


static func get_enemy_scene() -> PackedScene:
    if _enemy_scene_cache == null:
        _enemy_scene_cache = load(ENEMY_SCENE)
    return _enemy_scene_cache


static func get_battle_scene() -> PackedScene:
    if _battle_scene_cache == null:
        _battle_scene_cache = load(BATTLE_SCENE)
    return _battle_scene_cache
