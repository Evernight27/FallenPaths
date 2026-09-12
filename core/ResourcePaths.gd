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

# Assets
const TILE_TEXTURE := "res://assets/tiles/tile_texture.png"

## Load enemy scene (cached).
static var _enemy_scene_cache: PackedScene = preload("res://scenes/actors/enemy.tscn")
static var _battle_scene_cache: PackedScene = preload("res://scenes/battle/battle.tscn")


static func get_enemy_scene() -> PackedScene:
    return _enemy_scene_cache


static func get_battle_scene() -> PackedScene:
    return _battle_scene_cache
