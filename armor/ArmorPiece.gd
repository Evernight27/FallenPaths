class_name ArmorPiece
extends RefCounted

# One piece of armor per body part. A piece can be composed of multiple layers
# (e.g. plate + gambeson) to reflect medieval kit. Damage is processed through
# layers in order: outer first, then inner.
#
# SHARP: Penetration model. pen_sharp vs sharp_resistance → penetrate or stop.
#        When stopped: fraction transmitted as blunt (sharp_deflect_transmission); durability loss on absorbed share.
# BLUNT: Transmission-only model. Fraction of damage passes (blunt_transmission); cushion and area coupling reduce it. Durability loss on absorbed share.

var display_name: String = ""
var body_part: String = ""
# Each layer: { sharp_resistance_rha_mm, blunt_transmission, durability, max_durability, durability_loss_rate }; blunt_resistance_mpa optional (reference only, not used for durability).
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


# Apply damage through all layers. Returns { damage, damage_type, was_deflected, transmitted_blunt_amount }.
# When SHARP is stopped by a layer: fraction transmitted as blunt (one layer's transmission); caller adds to blunt and runs once.
# BLUNT: transmission-only. Uses blunt_transmission + cushion (momentum_per_area) + area coupling (rigid layers).
# blunt_contact_cm: weapon contact for area coupling; < 0 = skip (e.g. unarmed fallback).
# start_layer_index: when >0, skip outer layers (e.g. 1 after sharp deflected on layer 0 so deflected blunt is not reduced twice).
func apply_damage(incoming_damage: float, damage_type: String, penetration_sharp: float, penetration_blunt_momentum_per_area: float = -1.0, blunt_contact_cm: float = -1.0, start_layer_index: int = 0) -> Dictionary:
	var damage_remaining: float = incoming_damage
	var current_damage_type: String = damage_type
	var pen_rha: float = penetration_sharp
	var was_deflected: bool = false
	var incoming_was_sharp: bool = (damage_type == ArmorConstants.DAMAGE_TYPE_SHARP)

	for i in range(start_layer_index, layers.size()):
		var layer: Dictionary = layers[i]
		if _is_layer_destroyed(layer):
			continue
		var result := _process_layer(damage_remaining, current_damage_type, pen_rha, layer, penetration_blunt_momentum_per_area, blunt_contact_cm)
		damage_remaining = result.damage
		current_damage_type = result.damage_type
		if result.deflected:
			was_deflected = true
			if incoming_was_sharp:
				# Sharp stopped by layer: transmitted as blunt; caller adds to blunt and runs once.
				var raw_blunt: float = maxf(0.0, damage_remaining)
				return {
					"damage": raw_blunt,
					"damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT,
					"was_deflected": true,
					"transmitted_blunt_amount": raw_blunt
				}
			# Blunt: this layer applied transmission; continue to inner layers.
			# Do not break — next iteration processes damage_remaining as blunt.
		if damage_remaining <= 0.0:
			break

	var transmitted_blunt_amount: float = 0.0
	if was_deflected and incoming_was_sharp and current_damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		transmitted_blunt_amount = maxf(0.0, damage_remaining)
	return {
		"damage": maxf(0.0, damage_remaining),
		"damage_type": current_damage_type,
		"was_deflected": was_deflected,
		"transmitted_blunt_amount": transmitted_blunt_amount
	}


func _process_layer(damage: float, damage_type: String, pen_rha: float, layer: Dictionary, blunt_momentum_per_area: float = -1.0, blunt_contact_cm: float = -1.0) -> Dictionary:
	if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		# BLUNT: Transmission-only — never penetrate. Cushion + area coupling (rigid layers). No clamp.
		var base_tx: float = layer.get("blunt_transmission", layer.get("blunt_bat_transmission", ArmorConstants.BLUNT_TRANSMISSION_DEFAULT))
		var cushion: float = layer.get("blunt_cushion", 0.0)
		var transmission: float
		if blunt_momentum_per_area < 0.0 or cushion <= 0.0:
			transmission = base_tx * (1.0 - cushion)
		else:
			var thresh: float = ArmorConstants.BLUNT_CUSHION_MOMENTUM_THRESHOLD
			var momentum_factor: float = clampf(1.0 - blunt_momentum_per_area / thresh, 0.0, 1.0)
			transmission = base_tx * (1.0 - cushion * momentum_factor)

		# Area coupling for rigid layers: larger contact (mace) transmits more than small (thrust)
		var rigidity: float = layer.get("rigidity", 0.0)
		if rigidity >= ArmorConstants.RIGIDITY_THRESHOLD and blunt_contact_cm > 0.0:
			var ref_cm: float = WeaponConstants.get_blunt_coupling_reference_cm()
			var area_factor: float = blunt_contact_cm / ref_cm
			var coupling: float = lerpf(1.0, area_factor, rigidity)
			transmission *= coupling
			if area_factor < ArmorConstants.BLUNT_AREA_FACTOR_WARN_MIN or area_factor > ArmorConstants.BLUNT_AREA_FACTOR_WARN_MAX:
				push_warning("[Armor] Area coupling factor %.3f outside tuning range [%.2f, %.2f] (contact=%.2f cm, ref=%.2f). Adjust BLUNT_COUPLING_REFERENCE_CM or weapon contact." % [area_factor, ArmorConstants.BLUNT_AREA_FACTOR_WARN_MIN, ArmorConstants.BLUNT_AREA_FACTOR_WARN_MAX, blunt_contact_cm, ref_cm])

		if transmission < ArmorConstants.BLUNT_TRANSMISSION_WARN_MIN or transmission > ArmorConstants.BLUNT_TRANSMISSION_WARN_MAX:
			push_warning("[Armor] Blunt transmission %.3f outside [%.2f, %.2f]. Check layer blunt_transmission, cushion, rigidity, or BLUNT_COUPLING_REFERENCE_CM." % [transmission, ArmorConstants.BLUNT_TRANSMISSION_WARN_MIN, ArmorConstants.BLUNT_TRANSMISSION_WARN_MAX])

		var after_transmission: float = damage * transmission
		_apply_durability_loss(layer, damage - after_transmission, ArmorConstants.DAMAGE_TYPE_BLUNT)
		return {"damage": after_transmission, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}

	# SHARP: Penetration model — pen vs sharp_res → penetrate or deflect
	var sharp_res: float = layer.get("sharp_resistance_rha_mm", 0.0)
	var current_pen: float = pen_rha

	if current_pen < sharp_res:
		# Layer stops sharp: fraction transmitted as blunt (durability uses absorbed portion).
		var transmission: float = layer.get("sharp_deflect_transmission", layer.get("deflection_transmission", ArmorConstants.SHARP_DEFLECT_TRANSMISSION_DEFAULT))
		var after_deflect: float = damage * transmission
		_apply_durability_loss(layer, damage - after_deflect, ArmorConstants.DAMAGE_TYPE_BLUNT)
		return {"damage": after_deflect, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}
	else:
		# Penetration: reduce damage and continue to next layer
		var factor: float = clampf(1.0 - (sharp_res / maxf(1.0, current_pen)) * ArmorConstants.PENETRATION_DAMAGE_REDUCTION_MAX, 0.0, 1.0)
		var after_pen: float = damage * factor
		_apply_durability_loss(layer, damage - after_pen, damage_type)
		return {"damage": after_pen, "damage_type": damage_type, "deflected": false}


func _is_layer_destroyed(layer: Dictionary) -> bool:
	var dur: float = layer.get("durability", 100.0)
	return dur <= 0.0


func _apply_durability_loss(layer: Dictionary, damage_absorbed: float, damage_type: String = "") -> void:
	# Threshold: sharp (mm RHA) for penetration toughness; for blunt-origin damage add term from absorption (1 - blunt_transmission) so layers that absorb more blunt require more absorbed damage before wearing (research: energy absorption and degradation linked; padding designed to absorb many small blows).
	var sharp_res: float = layer.get("sharp_resistance_rha_mm", 0.0)
	var threshold: float = maxf(ArmorConstants.DURABILITY_MIN_DAMAGE_FLAT, sharp_res * ArmorConstants.DURABILITY_MIN_DAMAGE_RATIO)
	if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		var blunt_tx: float = layer.get("blunt_transmission", layer.get("blunt_bat_transmission", ArmorConstants.BLUNT_TRANSMISSION_DEFAULT))
		threshold += (1.0 - blunt_tx) * ArmorConstants.BLUNT_DURABILITY_THRESHOLD_RATIO
	if damage_absorbed < threshold:
		return
	var rate: float = layer.get("durability_loss_rate", ArmorConstants.DURABILITY_LOSS_RATE)
	var loss: float = damage_absorbed * rate
	layer["durability"] = maxf(0.0, layer.get("durability", 100.0) - loss)


func protects_body_part(part: String) -> bool:
	return body_part == part


# Outer layer sharp resistance (mm RHA). Used for energy-based thrust contact estimation.
func get_outer_layer_sharp_resistance_rha_mm() -> float:
	for layer in layers:
		if not _is_layer_destroyed(layer):
			return layer.get("sharp_resistance_rha_mm", 0.0)
	return 0.0


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
