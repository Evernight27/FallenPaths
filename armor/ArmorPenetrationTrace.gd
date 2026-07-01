class_name ArmorPenetrationTrace
extends RefCounted

## Sharp penetration depth remaining after armor layers (S7).
## Each layer's `sharp_resistance_rha_mm` consumes strike penetration before tissue / bone MFB.
## Aligns with Williams RHA-equivalent stack; independent of scalar damage reduction in `ArmorPiece.apply_damage`.

static func sharp_penetration_to_tissue_mm(armor: ArmorPiece, penetration_sharp_mm: float) -> Dictionary:
	if armor == null or penetration_sharp_mm < 0.0:
		return {
			"penetration_to_tissue_mm": penetration_sharp_mm,
			"armor_pen_consumed_mm": 0.0,
			"stopped_by_armor": false,
		}
	var pen: float = penetration_sharp_mm
	var consumed: float = 0.0
	for layer in armor.layers:
		if not layer is Dictionary or _is_layer_destroyed(layer):
			continue
		var res: float = maxf(0.0, float(layer.get(ArmorConstants.ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM, ArmorConstants.DEFAULT_ARMOR_LAYER_SHARP_RESISTANCE)))
		if pen < res:
			return {
				"penetration_to_tissue_mm": 0.0,
				"armor_pen_consumed_mm": consumed,
				"stopped_by_armor": true,
			}
		pen -= res
		consumed += res
	return {
		"penetration_to_tissue_mm": maxf(0.0, pen),
		"armor_pen_consumed_mm": consumed,
		"stopped_by_armor": false,
	}


static func _is_layer_destroyed(layer: Dictionary) -> bool:
	return layer.get("durability", 100.0) <= 0.0
