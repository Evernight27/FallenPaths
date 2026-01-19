extends CharacterBody2D

const TILE_SIZE = 64.0
var target_position: Vector2
var is_moving = false

func _ready():
	target_position = position
	# Snap to grid
	position = _snap_to_grid(position)

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		floor(pos.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2,
		floor(pos.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2
	)

func _input(event):
	if not is_moving and event is InputEventKey and event.pressed:
		var input_direction = Vector2.ZERO
		
		match event.keycode:
			KEY_W:
				input_direction = Vector2.UP
			KEY_S:
				input_direction = Vector2.DOWN
			KEY_A:
				input_direction = Vector2.LEFT
			KEY_D:
				input_direction = Vector2.RIGHT
		
		if input_direction != Vector2.ZERO:
			var new_target = target_position + input_direction * TILE_SIZE
			# Check bounds (10x10 grid)
			if new_target.x >= TILE_SIZE / 2 and new_target.x < TILE_SIZE * 10 + TILE_SIZE / 2:
				if new_target.y >= TILE_SIZE / 2 and new_target.y < TILE_SIZE * 10 + TILE_SIZE / 2:
					target_position = new_target
					is_moving = true

func _process(delta):
	# Smooth movement
	if is_moving:
		var distance = position.distance_to(target_position)
		if distance < 2.0:
			position = target_position
			is_moving = false
		else:
			position = position.move_toward(target_position, TILE_SIZE * 8 * delta)
