extends Node2D

@onready var tilemap: TileMap = $TileMap

func _ready():
	# Generate tile texture if it doesn't exist
	_generate_tile_texture_if_needed()
	
	# Wait a frame for texture to be ready
	await get_tree().process_frame
	
	# Create tileset programmatically
	_setup_tileset()
	
	# Fill the 10x10 grid with tiles
	var source_id = 0
	var atlas_coords = Vector2i(0, 0)
	
	for x in range(10):
		for y in range(10):
			var coords = Vector2i(x, y)
			tilemap.set_cell(0, coords, source_id, atlas_coords)
	
	print("10x10 grid created!")

func _setup_tileset():
	var texture_path = "res://tile_texture.png"
	
	# Load or create texture
	var texture: Texture2D
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path) as Texture2D
	else:
		print("Warning: Texture not found, creating default...")
		var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
		img.fill(Color(0.4, 0.6, 0.8))
		var img_texture = ImageTexture.create_from_image(img)
		texture = img_texture
	
	if texture == null:
		print("Error: Could not load or create texture!")
		return
	
	# Create a new TileSet
	var new_tileset = TileSet.new()
	
	# Create TileSetAtlasSource
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	
	# Create tile at (0, 0) in the atlas
	var tile_coords = Vector2i(0, 0)
	atlas_source.create_tile(tile_coords)
	
	# Add the source to the tileset (source_id will be 0)
	var source_id = new_tileset.add_source(atlas_source)
	
	# Set tile size
	new_tileset.tile_size = Vector2i(64, 64)
	
	# Assign to tilemap
	tilemap.tile_set = new_tileset
	
	print("TileSet created successfully with source_id: ", source_id)

func _generate_tile_texture_if_needed():
	var texture_path = "res://tile_texture.png"
	
	# Check if texture exists and is valid
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path) as Texture2D
		if texture != null:
			var texture_image = texture.get_image()
			if texture_image != null and texture_image.get_width() == 64 and texture_image.get_height() == 64:
				print("Tile texture exists and is valid")
				return
	
	# Texture doesn't exist or is invalid, try to generate it
	print("Generating tile texture...")
	var new_image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	new_image.fill(Color(0.4, 0.6, 0.8))
	
	# Draw border
	var border_color = Color(0.2, 0.3, 0.4)
	for x in range(64):
		new_image.set_pixel(x, 0, border_color)
		new_image.set_pixel(x, 63, border_color)
	for y in range(64):
		new_image.set_pixel(0, y, border_color)
		new_image.set_pixel(63, y, border_color)
	
	# Try to save - this will work in editor but not at runtime for res://
	var error = new_image.save_png(texture_path)
	if error == OK:
		print("Generated tile texture at ", texture_path)
	else:
		print("Could not save texture (this is normal at runtime).")
		print("Please run create_tile_texture.gd in the editor (File > Run Script)")
