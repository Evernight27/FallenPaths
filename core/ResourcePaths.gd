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
const ENEMY_SCENE := "res://enemy/Enemy.tscn"

# Assets
const TILE_TEXTURE := "res://tile_texture.png"
