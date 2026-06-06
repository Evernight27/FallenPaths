extends Node2D

## Headless overworld stub: camp tile coords for CompanyState camp-heal tests.

const TILE_SIZE := 64


func _tile_coords(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / TILE_SIZE)), int(floor(pos.y / TILE_SIZE)))
