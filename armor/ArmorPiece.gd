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


# Apply damage through all layers. Returns { damage, damage_type, was_deflected, deflected_blunt_amount }.
# When SHARP deflects: return raw deflected blunt (one layer's transmission only); caller adds to blunt and runs once.
# When BLUNT fails to penetrate a layer: rigid = pressure (pen_blunt vs blunt_resistance_mpa); cushion reduces transmission (Option B).
# penetration_sharp in mm RHA. penetration_blunt in MPa (Option 1: blend of KE/area + momentum/area for rigid). penetration_blunt_momentum_per_area in (kg·m/s)/m² for cushion (when < 0 or cushion 0, transmission = base_tx * (1 - cushion) only).
# start_layer_index: when >0, skip outer layers (e.g. 1 after sharp deflected on layer 0 so deflected blunt is not reduced twice).
func apply_damage(incoming_damage: float, damage_type: String, penetration_sharp: float, penetration_blunt: float, penetration_blunt_momentum_per_area: float = -1.0, start_layer_index: int = 0) -> Dictionary:
	var damage_remaining: float = incoming_damage
	var current_damage_type: String = damage_type
	var pen_rha: float = penetration_sharp
	var pen_mpa: float = penetration_blunt
	if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP:
		pen_mpa = penetration_sharp * ArmorConstants.RHA_TO_MPA
	var was_deflected: bool = false
	var incoming_was_sharp: bool = (damage_type == ArmorConstants.DAMAGE_TYPE_SHARP)

	for i in range(start_layer_index, layers.size()):
		var layer: Dictionary = layers[i]
		if _is_layer_destroyed(layer):
			continue
		var result := _process_layer(damage_remaining, current_damage_type, pen_rha, pen_mpa, layer, penetration_blunt_momentum_per_area)
		damage_remaining = result.damage
		current_damage_type = result.damage_type
		if result.deflected:
			was_deflected = true
			if incoming_was_sharp:
				# Sharp deflected: return raw blunt so caller can add to blunt component and run once.
				var raw_blunt: float = maxf(0.0, damage_remaining)
				return {
					"damage": raw_blunt,
					"damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT,
					"was_deflected": true,
					"deflected_blunt_amount": raw_blunt
				}
			# Blunt "deflected" (pen < res): this layer applied transmission; continue to inner layers.
			# Do not break — next iteration processes damage_remaining as blunt.
		if damage_remaining <= 0.0:
			break

	var deflected_blunt_amount: float = 0.0
	if was_deflected and incoming_was_sharp and current_damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		deflected_blunt_amount = maxf(0.0, damage_remaining)
	return {
		"damage": maxf(0.0, damage_remaining),
		"damage_type": current_damage_type,
		"was_deflected": was_deflected,
		"deflected_blunt_amount": deflected_blunt_amount
	}


func _process_layer(damage: float, damage_type: String, pen_rha: float, pen_mpa: float, layer: Dictionary, blunt_momentum_per_area: float = -1.0) -> Dictionary:
	var sharp_res: float = layer.get("sharp_resistance_rha_mm", 0.0)
	var blunt_res: float = layer.get("blunt_resistance_mpa", 0.0)
	var current_pen: float = pen_rha if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP else pen_mpa
	var layer_res: float = sharp_res if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP else blunt_res

	if current_pen < layer_res:
		# Layer stops attack: convert to blunt (or reduce blunt). Sharp uses deflection_transmission.
		# Blunt cushion (physics): padding absorbs impulse (momentum). Transmission = base_tx * (1 - cushion * momentum_factor).
		# momentum_factor = 1 - (p/A) / threshold, clamped [0,1]: low impulse/area → factor 1 (padding helps); high → factor 0 (padding overwhelmed).
		var transmission: float
		if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
			var base_tx: float = layer.get("blunt_bat_transmission", ArmorConstants.BLUNT_BAT_TRANSMISSION)
			var cushion: float = layer.get("blunt_cushion", 0.0)
			if blunt_momentum_per_area < 0.0 or cushion <= 0.0:
				transmission = base_tx * (1.0 - cushion)
			else:
				var thresh: float = ArmorConstants.BLUNT_CUSHION_MOMENTUM_THRESHOLD
				var momentum_factor: float = clampf(1.0 - blunt_momentum_per_area / thresh, 0.0, 1.0)
				transmission = base_tx * (1.0 - cushion * momentum_factor)
		else:
			transmission = layer.get("deflection_transmission", ArmorConstants.DEFLECTION_TRANSMISSION_DEFAULT)
		var after_deflect: float = damage * transmission
		_apply_durability_loss(layer, damage - after_deflect)
		return {"damage": after_deflect, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}
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
	var sharp_res: float = layer.get("sharp_resistance_rha_mm", 0.0)
	var blunt_res: float = layer.get("blunt_resistance_mpa", 0.0)
	var armor_value: float = sharp_res + blunt_res / 10.0
	var threshold: float = maxf(ArmorConstants.DURABILITY_MIN_DAMAGE_FLAT, armor_value * ArmorConstants.DURABILITY_MIN_DAMAGE_RATIO)
	if damage_absorbed < threshold:
		return
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
