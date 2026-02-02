class_name ArmorPiece
extends RefCounted

# One piece of armor per body part. A piece can be composed of multiple layers
# (e.g. plate + gambeson) to reflect medieval kit. Damage is processed through
# layers in order: outer first (deflection/penetration), then inner.

var display_name: String = ""
var body_part: String = ""
# Each layer: { sharp_resistance_rha_mm, blunt_resistance_mpa, durability, max_durability, durability_loss_rate }
var layers: Array = []


static func create_from_definition(piece_id: String) -> ArmorPiece:
	var def: Dictionary = ArmorConstants.get_piece_definition(piece_id)
	if def.is_empty():
		return null
	var piece := ArmorPiece.new()
	piece.display_name = def.get("name", piece_id)
	piece.body_part = def.get("body_part", "")
	var layer_defs: Array = def.get("layers", [])
	for layer_def in layer_defs:
		var layer: Dictionary = layer_def.duplicate()
		layer["durability"] = 100.0
		layer["max_durability"] = 100.0
		if not layer.has("durability_loss_rate"):
			layer["durability_loss_rate"] = ArmorConstants.DURABILITY_LOSS_RATE
		piece.layers.append(layer)
	return piece


# Apply damage through all layers. Returns { damage: float, damage_type: String }.
# penetration_sharp in mm RHA, penetration_blunt in MPa.
func apply_damage(incoming_damage: float, damage_type: String, penetration_sharp: float, penetration_blunt: float) -> Dictionary:
	var damage_remaining: float = incoming_damage
	var current_damage_type: String = damage_type
	var pen_rha: float = penetration_sharp
	var pen_mpa: float = penetration_blunt
	if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP:
		pen_mpa = penetration_sharp * ArmorConstants.RHA_TO_MPA

	for i in range(layers.size()):
		var layer: Dictionary = layers[i]
		if _is_layer_destroyed(layer):
			continue
		var result := _process_layer(damage_remaining, current_damage_type, pen_rha, pen_mpa, layer)
		damage_remaining = result.damage
		current_damage_type = result.damage_type
		if result.deflected:
			break
		if damage_remaining <= 0.0:
			break

	return {"damage": maxf(0.0, damage_remaining), "damage_type": current_damage_type}


func _process_layer(damage: float, damage_type: String, pen_rha: float, pen_mpa: float, layer: Dictionary) -> Dictionary:
	var sharp_res: float = layer.get("sharp_resistance_rha_mm", 0.0)
	var blunt_res: float = layer.get("blunt_resistance_mpa", 0.0)
	var current_pen: float = pen_rha if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP else pen_mpa
	var layer_res: float = sharp_res if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP else blunt_res

	if current_pen < layer_res:
		# Deflection: sharp fails to penetrate; halve damage and convert to blunt
		var after_deflect: float = damage / 2.0
		var new_type: String = ArmorConstants.DAMAGE_TYPE_BLUNT
		var blunt_pen: float = pen_mpa
		if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP:
			blunt_pen = pen_rha * ArmorConstants.RHA_TO_MPA
		# Test blunt against this layer (cap effectiveness at 1.0 to avoid amplifying damage)
		if blunt_pen < blunt_res:
			var effectiveness: float = clampf(blunt_pen / maxf(0.1, blunt_res), 0.0, 1.0)
			after_deflect *= effectiveness * ArmorConstants.DEFLECTION_DAMAGE_REDUCTION
		else:
			var factor: float = clampf(1.0 - (blunt_res / maxf(0.1, blunt_pen)) * ArmorConstants.BLUNT_PENETRATION_REDUCTION, 0.0, 1.0)
			after_deflect *= factor
		_apply_durability_loss(layer, damage - after_deflect)
		return {"damage": after_deflect, "damage_type": new_type, "deflected": true}
	else:
		# Penetration: reduce damage and continue to next layer (clamp factor so we never amplify)
		var factor: float = clampf(1.0 - (layer_res / maxf(1.0, current_pen)) * ArmorConstants.PENETRATION_DAMAGE_REDUCTION_MAX, 0.0, 1.0)
		var after_pen: float = damage * factor
		_apply_durability_loss(layer, damage - after_pen)
		return {"damage": after_pen, "damage_type": damage_type, "deflected": false}


func _is_layer_destroyed(layer: Dictionary) -> bool:
	var dur: float = layer.get("durability", 100.0)
	return dur <= 0.0


func _apply_durability_loss(layer: Dictionary, damage_absorbed: float) -> void:
	var rate: float = layer.get("durability_loss_rate", ArmorConstants.DURABILITY_LOSS_RATE)
	var loss: float = damage_absorbed * rate
	layer["durability"] = maxf(0.0, layer.get("durability", 100.0) - loss)


func protects_body_part(part: String) -> bool:
	return body_part == part


func get_durability_percent() -> float:
	if layers.is_empty():
		return 100.0
	var total: float = 0.0
	var current: float = 0.0
	for layer in layers:
		var max_d: float = layer.get("max_durability", 100.0)
		var dur: float = layer.get("durability", 100.0)
		total += max_d
		current += dur
	if total <= 0.0:
		return 100.0
	return (current / total) * 100.0
