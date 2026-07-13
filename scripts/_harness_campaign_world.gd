extends Node2D

## Headless overworld stub: camp tile coords for CompanyState camp-heal tests.

const _OverworldMap := preload("res://world/OverworldMap.gd")


func _tile_coords(pos: Vector2) -> Vector2i:
    return _OverworldMap.tile_coords_from_pos(pos)


func _tile_center(tile: Vector2i) -> Vector2:
    return _OverworldMap.tile_center(tile)
