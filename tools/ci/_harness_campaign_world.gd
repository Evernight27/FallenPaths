extends Node2D

## Headless overworld stub: camp tile coords for CompanyState camp-heal tests.


func _tile_coords(pos: Vector2) -> Vector2i:
    return OverworldMap.tile_coords_from_pos(pos)
