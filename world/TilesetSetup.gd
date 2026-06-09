class_name TilesetSetup
extends RefCounted

## Tile texture generation and tileset creation. Used by main.gd.

const _ResourcePaths := preload("res://core/ResourcePaths.gd")
const TEXTURE_PATH := _ResourcePaths.TILE_TEXTURE
const TILE_SIZE := 64

static func generate_tile_texture_if_needed() -> void:
	if ResourceLoader.exists(TEXTURE_PATH):
		var texture = load(TEXTURE_PATH) as Texture2D
		if texture != null:
			var texture_image = texture.get_image()
			if texture_image != null and texture_image.get_width() == TILE_SIZE and texture_image.get_height() == TILE_SIZE:
				print("Tile texture exists and is valid")
				return
	print("Generating tile texture...")
	var new_image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	new_image.fill(Color(0.4, 0.6, 0.8))
	var border_color = Color(0.2, 0.3, 0.4)
	for x in range(TILE_SIZE):
		new_image.set_pixel(x, 0, border_color)
		new_image.set_pixel(x, TILE_SIZE - 1, border_color)
	for y in range(TILE_SIZE):
		new_image.set_pixel(0, y, border_color)
		new_image.set_pixel(TILE_SIZE - 1, y, border_color)
	var error = new_image.save_png(TEXTURE_PATH)
	if error == OK:
		print("Generated tile texture at ", TEXTURE_PATH)
	else:
		print("Could not save texture (this is normal at runtime).")
		print("Please run create_tile_texture.gd in the editor (File > Run Script)")

static func setup_tileset(tilemap: TileMap) -> void:
	var texture: Texture2D
	if ResourceLoader.exists(TEXTURE_PATH):
		texture = load(TEXTURE_PATH) as Texture2D
	else:
		print("Warning: Texture not found, creating default...")
		var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
		img.fill(Color(0.4, 0.6, 0.8))
		texture = ImageTexture.create_from_image(img)
	if texture == null:
		print("Error: Could not load or create texture!")
		return
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.create_tile(Vector2i(0, 0))
	var source_id = new_tileset.add_source(atlas_source)
	new_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tilemap.tile_set = new_tileset
	print("TileSet created successfully with source_id: ", source_id)
