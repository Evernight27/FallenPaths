class_name ArmorJouleBudget
extends RefCounted

## Option A pilot: layer-wise KE budget aligned with `ArmorPiece` penetration/transmission (S6).
## Gameplay scales pre-armor cut/blunt by sqrt(ke_remaining / strike_ke_j) when `CombatConstants.FEATURE_JOULE_ARMOR_BUDGET`.
## S10: when joule path is active, `EntityDamage` skips scalar `ArmorPiece.apply_damage` (no double absorption).

const _ArmorConstants := preload("res://armor/ArmorConstants.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")


static func account_ke_through_armor(
	armor: ArmorPiece,
	strike_ke_j: float,
	penetration_sharp_mm: float,
	incoming_is_sharp: bool,
	penetration_blunt_momentum_per_area: float = -1.0,
	blunt_contact_cm: float = -1.0
) -> Dictionary:
	if armor == null or strike_ke_j <= 0.0:
		return _full_transmission(strike_ke_j)
	var ke_rem: float = strike_ke_j
	var absorbed: float = 0.0
	var sharp_mode: bool = incoming_is_sharp
	var pen_rha: float = maxf(0.0, penetration_sharp_mm)
	for layer in armor.layers:
		if not layer is Dictionary or _is_layer_destroyed(layer):
			continue
		var before: float = ke_rem
		if sharp_mode:
			var sharp_out: Dictionary = _sharp_ke_through_layer(ke_rem, pen_rha, layer)
			ke_rem = float(sharp_out.get("ke", ke_rem))
			absorbed += maxf(0.0, before - ke_rem)
			if bool(sharp_out.get("deflected", false)):
				sharp_mode = false
		else:
			ke_rem = _blunt_ke_through_layer(
				ke_rem, layer, penetration_blunt_momentum_per_area, blunt_contact_cm
			)
			absorbed += maxf(0.0, before - ke_rem)
	ke_rem = maxf(0.0, ke_rem)
	absorbed = maxf(0.0, strike_ke_j - ke_rem)
	var frac: float = 1.0
	if strike_ke_j > 0.01:
		frac = sqrt(ke_rem / strike_ke_j)
	return {
		"strike_ke_j": strike_ke_j,
		"armor_ke_absorbed_j": absorbed,
		"armor_ke_remaining_j": ke_rem,
		"transmitted_ke_fraction": clampf(frac, 0.0, 1.0),
	}


static func is_active(force_extras: bool = false) -> bool:
	return force_extras or _CombatConstants.is_joule_armor_budget_active()


static func _full_transmission(strike_ke_j: float) -> Dictionary:
	var ke: float = maxf(0.0, strike_ke_j)
	return {
		"strike_ke_j": ke,
		"armor_ke_absorbed_j": 0.0,
		"armor_ke_remaining_j": ke,
		"transmitted_ke_fraction": 1.0 if ke > 0.01 else 0.0,
	}


static func _is_layer_destroyed(layer: Dictionary) -> bool:
	return float(layer.get("durability", 100.0)) <= 0.0


static func _sharp_ke_through_layer(ke: float, pen_rha: float, layer: Dictionary) -> Dictionary:
	var sharp_res: float = float(layer.get("sharp_resistance_rha_mm", 0.0))
	if pen_rha < sharp_res:
		var tx: float = float(
			layer.get(
				"sharp_deflect_transmission",
				layer.get("deflection_transmission", _ArmorConstants.SHARP_DEFLECT_TRANSMISSION_DEFAULT)
			)
		)
		var after: float = ke * clampf(tx, 0.0, 1.0)
		return {"ke": after, "deflected": true}
	var factor: float = clampf(
		1.0
			- (sharp_res / maxf(1.0, pen_rha)) * _ArmorConstants.PENETRATION_DAMAGE_REDUCTION_MAX,
		0.0,
		1.0
	)
	return {"ke": ke * factor, "deflected": false}


static func _blunt_ke_through_layer(
	ke: float,
	layer: Dictionary,
	blunt_momentum_per_area: float,
	blunt_contact_cm: float
) -> float:
	var base_tx: float = float(
		layer.get("blunt_transmission", layer.get("blunt_bat_transmission", _ArmorConstants.BLUNT_TRANSMISSION_DEFAULT))
	)
	var cushion: float = float(layer.get("blunt_cushion", 0.0))
	var transmission: float
	if blunt_momentum_per_area < 0.0 or cushion <= 0.0:
		transmission = base_tx * (1.0 - cushion)
	else:
		var thresh: float = _ArmorConstants.BLUNT_CUSHION_MOMENTUM_THRESHOLD
		var momentum_factor: float = clampf(1.0 - blunt_momentum_per_area / thresh, 0.0, 1.0)
		transmission = base_tx * (1.0 - cushion * momentum_factor)
	var rigidity: float = float(layer.get("rigidity", 0.0))
	if rigidity >= _ArmorConstants.RIGIDITY_THRESHOLD and blunt_contact_cm > 0.0:
		var ref_cm: float = _WeaponConstants.get_blunt_coupling_reference_cm()
		var area_factor: float = blunt_contact_cm / ref_cm
		var coupling: float = lerpf(1.0, area_factor, rigidity)
		transmission *= coupling
	return ke * clampf(transmission, 0.0, 1.0)
