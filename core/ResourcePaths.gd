class_name ResourcePaths
extends RefCounted

## Central path constants for res:// resources. Use with load() or as references.
## Note: preload() requires literal strings and cannot use these at parse time.

# Scripts
const COMBAT_MANAGER := "res://combat/CombatManager.gd"
const BATTLE_SCENE := "res://ui/BattleScene.gd"
const PARTY_MANAGER := "res://world/PartyManager.gd"
const PARTY_MENU := "res://ui/PartyMenu.gd"

# Species
const SPECIES_DIR := "res://species"
const HUMAN_SPECIES := "res://species/human.tres"
const GOBLIN_SPECIES := "res://species/goblin.tres"

# Scenes
const BATTLE_SCENE_TSCN := "res://ui/BattleScene.tscn"
const ENEMY_SCENE := "res://enemy/Enemy.tscn"
const TUNING_SCENE := "res://combat_tuning/combat_tuning.tscn"

# Assets
const TILE_TEXTURE := "res://tile_texture.png"

## Load enemy scene (cached). Replaces `load(ResourcePaths.ENEMY_SCENE) as PackedScene` across 3+ callers.
static var _enemy_scene_cache: PackedScene = preload("res://enemy/Enemy.tscn")


static func get_enemy_scene() -> PackedScene:
    return _enemy_scene_cache
