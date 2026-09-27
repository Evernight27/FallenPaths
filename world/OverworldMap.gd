class_name OverworldMap
extends RefCounted

## XCamp-3.2: overworld grid size + tile math (camp stays `(0,0)`).
## Canonical: `map_tiles_for_world` . `is_tile_in_bounds` . `tile_coords_from_pos` . `tile_center`.

const TILE_SIZE := 64
const TILE_HALF := 32
## EA was 3×3; expansion default 5×5 walkable grid.
const MAP_TILES := 5

const WORLD_META_MAP_TILES := "overworld_map_tiles"


static func stamp_world_map_size(world: Node) -> void:
    if world != null:
        world.set_meta(WORLD_META_MAP_TILES, MAP_TILES)


static func map_tiles_for_world(world: Node) -> int:
    if world != null and world.has_meta(WORLD_META_MAP_TILES):
        return maxi(1, int(world.get_meta(WORLD_META_MAP_TILES)))
    return MAP_TILES


static func is_tile_in_bounds(tile: Vector2i, world: Node = null) -> bool:
    var n: int = map_tiles_for_world(world)
    return tile.x >= 0 and tile.y >= 0 and tile.x < n and tile.y < n


static func all_tiles(world: Node = null) -> Array:
    var out: Array = []
    var n: int = map_tiles_for_world(world)
    for x in range(n):
        for y in range(n):
            out.append(Vector2i(x, y))
    return out


static func tile_coords_from_pos(pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor((pos.x - TILE_HALF) / float(TILE_SIZE))), int(floor((pos.y - TILE_HALF) / float(TILE_SIZE)))
    )


static func tile_center(tile: Vector2i) -> Vector2:
    return Vector2(tile.x * TILE_SIZE + TILE_HALF, tile.y * TILE_SIZE + TILE_HALF)


static func movement_min_pos() -> float:
    return float(TILE_HALF)


static func movement_max_pos_exclusive(world: Node = null) -> float:
    return float(map_tiles_for_world(world) * TILE_SIZE + TILE_HALF)


static func random_tile(rng: RandomNumberGenerator, world: Node = null) -> Vector2i:
    var n: int = map_tiles_for_world(world)
    return Vector2i(rng.randi_range(0, n - 1), rng.randi_range(0, n - 1))


static func format_map_label(world: Node = null) -> String:
    var n: int = map_tiles_for_world(world)
    return "%d×%d" % [n, n]
