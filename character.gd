extends CharacterBody2D

const TILE_SIZE = 64.0
var target_position: Vector2
var is_moving = false
signal moved

# Combat/body stats live on the CombatBody child (CoreEntity); we expose them so
# combat and UI that read this node still work.
@export var species: Resource = null
@onready var _combat_body: CoreEntity = $CombatBody

var body_cutting: Dictionary: get = _get_body_cutting
var body_blunt: Dictionary: get = _get_body_blunt
var body_max: Dictionary: get = _get_body_max
var bone_health: Dictionary: get = _get_bone_health
var bone_max: Dictionary: get = _get_bone_max
var strength: int: get = _get_strength
var agility: int: get = _get_agility
var intelligence: int: get = _get_intelligence
var endurance: int: get = _get_endurance
var perception: int: get = _get_perception

func get_effective_speed() -> int:
	return _combat_body.get_effective_speed() if _combat_body else agility

func get_leg_functionality() -> float:
	return _combat_body.get_leg_functionality() if _combat_body else 1.0

func _get_body_cutting() -> Dictionary:
	return _combat_body.body_cutting if _combat_body else {}

func _get_body_blunt() -> Dictionary:
	return _combat_body.body_blunt if _combat_body else {}

func _get_body_max() -> Dictionary:
	return _combat_body.body_max if _combat_body else {}

func _get_bone_health() -> Dictionary:
	return _combat_body.bone_health if _combat_body else {}

func _get_bone_max() -> Dictionary:
	return _combat_body.bone_max if _combat_body else {}

func _get_strength() -> int:
	return _combat_body.strength if _combat_body else 100

func _get_agility() -> int:
	return _combat_body.agility if _combat_body else 100

func _get_intelligence() -> int:
	return _combat_body.intelligence if _combat_body else 100

func _get_endurance() -> int:
	return _combat_body.endurance if _combat_body else 100

func _get_perception() -> int:
	return _combat_body.perception if _combat_body else 100

func get_medical_effectiveness() -> float:
	return _combat_body.get_medical_effectiveness() if _combat_body else 1.0

func get_targetable_parts() -> Array:
	return _combat_body.get_targetable_parts() if _combat_body else []

func get_attacking_arm() -> String:
	return _combat_body.get_attacking_arm() if _combat_body else ""

func get_attack_damage_modifier() -> float:
	return _combat_body.get_attack_damage_modifier() if _combat_body else 0.0

func get_weapon():
	return _combat_body.get_weapon() if _combat_body else null

func equip_weapon(w) -> void:
	if _combat_body:
		_combat_body.equip_weapon(w)

func is_dead() -> bool:
	return _combat_body.is_dead() if _combat_body else true

func is_incapacitated() -> bool:
	return _combat_body.is_incapacitated() if _combat_body else false

func is_cowering() -> bool:
	return _combat_body.is_cowering() if _combat_body else false

func get_performance_modifier() -> float:
	return _combat_body.get_performance_modifier() if _combat_body else 1.0

func get_action_bar_performance_modifier() -> float:
	return _combat_body.get_action_bar_performance_modifier() if _combat_body else 1.0

func get_hit_chance_performance_modifier() -> float:
	return _combat_body.get_hit_chance_performance_modifier() if _combat_body else 1.0

func get_total_pain() -> float:
	return _combat_body.get_total_pain() if _combat_body else 0.0

func get_dodge_chance() -> float:
	return _combat_body.get_dodge_chance() if _combat_body else 0.0

func get_passive_parry_reaction_time() -> float:
	return _combat_body.get_passive_parry_reaction_time() if _combat_body else 0.5

func get_effective_consciousness() -> float:
	return _combat_body.get_effective_consciousness() if _combat_body else 100.0

func get_death_reason() -> String:
	return _combat_body.get_death_reason() if _combat_body else "no_combat_body"

func take_damage(amount: int, part: String, damage_type: String = "BLUNT", penetration_sharp: float = -1.0, penetration_blunt_momentum_per_area: float = -1.0) -> Dictionary:
	if _combat_body:
		return _combat_body.take_damage(amount, part, damage_type, penetration_sharp, penetration_blunt_momentum_per_area)
	return { "final_type": damage_type, "final_amount": 0 }

func take_damage_split(cut_pre: float, blunt_pre: float, part: String, penetration_sharp: float = -1.0, penetration_blunt_momentum_per_area: float = -1.0, blunt_contact_cm: float = -1.0) -> Dictionary:
	if _combat_body:
		return _combat_body.take_damage_split(cut_pre, blunt_pre, part, penetration_sharp, penetration_blunt_momentum_per_area, blunt_contact_cm)
	return { "final_cut": 0, "final_blunt": 0 }

func get_armor_for_part(part: String) -> Variant:
	return _combat_body.get_armor_for_part(part) if _combat_body else null

func get_armor_sharp_resistance_for_part(part: String) -> float:
	return _combat_body.get_armor_sharp_resistance_for_part(part) if _combat_body else 0.0

func get_armor_slots() -> Dictionary:
	return _combat_body.get_armor_slots() if _combat_body else {}

func equip_armor(part: String, piece: Variant) -> void:
	if _combat_body:
		_combat_body.equip_armor(part, piece)

func get_blood_volume() -> float:
	return _combat_body.blood_volume if _combat_body else 100.0

func get_total_bleeding_rate() -> float:
	return _combat_body.get_total_bleeding_rate() if _combat_body else 0.0

func get_medical_entity() -> Node:
	if _combat_body:
		return _combat_body
	return self

func ensure_consciousness_current() -> void:
	if _combat_body and _combat_body.has_method("ensure_consciousness_current"):
		_combat_body.ensure_consciousness_current()

func get_wounded_parts() -> Array:
	return _combat_body.get_wounded_parts() if _combat_body else []

func get_wounds() -> Dictionary:
	return _combat_body.get_wounds() if _combat_body else {}

func get_wound_healing_progress(injury: Dictionary) -> float:
	return _combat_body.get_wound_healing_progress(injury) if _combat_body else 0.0

func get_game_time_seconds() -> float:
	return _combat_body.get_game_time_seconds() if _combat_body else 0.0

func apply_bandage(part: String, effectiveness: float = 1.0) -> bool:
	return _combat_body.apply_bandage(part, effectiveness) if _combat_body else false

func can_apply_bandage(part: String) -> bool:
	return _combat_body.can_apply_bandage(part) if _combat_body else false

func get_bandage_application_time_seconds() -> float:
	return _combat_body.get_bandage_application_time_seconds() if _combat_body else 0.0

func get_bandage_application_time_seconds_for_part(part: String) -> float:
	return _combat_body.get_bandage_application_time_seconds_for_part(part) if _combat_body else 0.0

func can_apply_packing(part: String) -> bool:
	return _combat_body.can_apply_packing(part) if _combat_body else false

func apply_packing(part: String, effectiveness: float = 1.0) -> bool:
	return _combat_body.apply_packing(part, effectiveness) if _combat_body else false

func get_packing_application_time_seconds_for_part(part: String) -> float:
	return _combat_body.get_packing_application_time_seconds_for_part(part) if _combat_body else 0.0

func can_apply_direct_pressure(target_part: String) -> bool:
	return _combat_body.can_apply_direct_pressure(target_part) if _combat_body else false

func apply_direct_pressure(part: String) -> bool:
	return _combat_body.apply_direct_pressure(part) if _combat_body else false

func apply_direct_pressure_from_ally(part: String, performer_entity: Node = null) -> bool:
	return _combat_body.apply_direct_pressure_from_ally(part, performer_entity) if _combat_body else false

func is_applying_direct_pressure() -> bool:
	return _combat_body.is_applying_direct_pressure() if _combat_body else false

func get_direct_pressure_part() -> String:
	return _combat_body.get_direct_pressure_part() if _combat_body else ""

func clear_direct_pressure() -> void:
	if _combat_body:
		_combat_body.clear_direct_pressure()

func can_apply_tourniquet(part: String) -> bool:
	return _combat_body.can_apply_tourniquet(part) if _combat_body else false

func is_tourniquet_applied(part: String) -> bool:
	return _combat_body.is_tourniquet_applied(part) if _combat_body else false

func get_tourniquet_application_time_seconds() -> float:
	return _combat_body.get_tourniquet_application_time_seconds() if _combat_body else 0.0

func apply_tourniquet(part: String) -> bool:
	return _combat_body.apply_tourniquet(part) if _combat_body else false

func remove_tourniquet(part: String) -> void:
	if _combat_body:
		_combat_body.remove_tourniquet(part)

func process_bleeding(seconds: float) -> void:
	if _combat_body and _combat_body.has_method("process_bleeding"):
		_combat_body.process_bleeding(seconds)

func process_blood_loss(seconds: float) -> void:
	if _combat_body and _combat_body.has_method("process_blood_loss"):
		_combat_body.process_blood_loss(seconds)

func process_healing(seconds: float) -> void:
	if _combat_body and _combat_body.has_method("process_healing"):
		_combat_body.process_healing(seconds)

func apply_species() -> void:
	if _combat_body and species != null:
		_combat_body.species = species
		_combat_body.apply_species()

## Apply hero/party boost: stronger than baseline human (150 vs 100). Call after apply_species().
func apply_party_boost() -> void:
	if _combat_body:
		_combat_body.strength = 150
		_combat_body.agility = 150
		_combat_body.intelligence = 150
		_combat_body.endurance = 150
		_combat_body.perception = 150

func _ready() -> void:
	target_position = position
	position = _snap_to_grid(position)
	if species != null and _combat_body:
		_combat_body.species = species
		_combat_body.apply_species()
	if _combat_body and _combat_body.has_signal("died"):
		_combat_body.died.connect(_on_combat_body_died)

func _on_combat_body_died() -> void:
	# Battle UI will emit battle_ended(winner, defeated); main.gd handles outcome there.
	print("Player died.")

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		floor(pos.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2,
		floor(pos.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2
	)

func _input(event) -> void:
	if not is_moving and event is InputEventKey and event.pressed:
		var input_direction = Vector2.ZERO
		match event.keycode:
			KEY_W, KEY_UP:
				input_direction = Vector2.UP
			KEY_S, KEY_DOWN:
				input_direction = Vector2.DOWN
			KEY_A, KEY_LEFT:
				input_direction = Vector2.LEFT
			KEY_D, KEY_RIGHT:
				input_direction = Vector2.RIGHT
		if input_direction != Vector2.ZERO:
			var new_target = target_position + input_direction * TILE_SIZE
			if new_target.x >= TILE_SIZE / 2 and new_target.x < TILE_SIZE * 3 + TILE_SIZE / 2:
				if new_target.y >= TILE_SIZE / 2 and new_target.y < TILE_SIZE * 3 + TILE_SIZE / 2:
					target_position = new_target
					is_moving = true

func _process(delta: float) -> void:
	if is_moving:
		var distance = position.distance_to(target_position)
		if distance < 2.0:
			position = target_position
			is_moving = false
			emit_signal("moved")
		else:
			position = position.move_toward(target_position, TILE_SIZE * 8 * delta)
