@tool
extends EditorScript

func _run():
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(Color(0.4, 0.6, 0.8))  # Light blue color
	
	# Add a border
	var border_color = Color(0.2, 0.3, 0.4)
	for x in range(64):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, 63, border_color)
	for y in range(64):
		image.set_pixel(0, y, border_color)
		image.set_pixel(63, y, border_color)
	
	# Save as PNG directly
	var error = image.save_png("res://tile_texture.png")
	if error == OK:
		print("Tile texture created successfully at res://tile_texture.png")
	else:
		print("Error creating tile texture: ", error)
