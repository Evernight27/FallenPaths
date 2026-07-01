class_name CombatDamageMechanism
extends RefCounted

## Mechanism-first bone/tissue split (S3): cut-dominant vs blunt-dominant fracture gates.

const _BodyPartConstants := preload("res://core/BodyPartConstants.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")

const MFB_SHARP_DOMINANT_RATIO := 0.85
## Shallow cut / glance: no bone chip unless penetration reaches this (mm RHA scale).
const MFB_CUT_BONE_MIN_PENETRATION_MM := 2.5
const MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR := 1.0
## Blunt-dominant: bone chip capped so crush tissue remains on the stream.
const MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT := 0.42

## Blunt fracture anchor energy (J) by sub-region (research order-of-magnitude; elbow low, thigh high).
const MFB_BLUNT_FRACTURE_J_BY_SUBREGION: Dictionary = {
	_BodyPartConstants.PART_HEAD: {"scalp": 12.0, "face": 15.0, "neck": 25.0},
	_BodyPartConstants.PART_CHEST: {"thoracic": 30.0, "abdominal": 35.0},
	_BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 28.0, "elbow": 18.0, "forearm": 22.0, "hand": 20.0},
	_BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 28.0, "elbow": 18.0, "forearm": 22.0, "hand": 20.0},
	_BodyPartConstants.PART_RIGHT_LEG: {"thigh": 35.0, "knee": 22.0, "calf": 25.0, "foot": 28.0},
	_BodyPartConstants.PART_LEFT_LEG: {"thigh": 35.0, "knee": 22.0, "calf": 25.0, "foot": 28.0},
}


static func allocate_bone_and_tissue(
	final_cut: float,
	final_blunt: float,
	total_final: float,
	part: String,
	sub_region: String,
	penetration_sharp: float,
	strike_ke_j: float,
	strike_ke_blunt_j: float = -1.0
) -> Dictionary:
	var ke_blunt: float = strike_ke_blunt_j if strike_ke_blunt_j >= 0.0 else strike_ke_j
	var to_cut: float = 0.0
	var to_blunt: float = 0.0
	var to_bone: float = 0.0
	var to_tissue_total: float = total_final
	var mechanism: String = "mixed"
	if total_final <= 0.0:
		return _pack(to_cut, to_blunt, to_bone, to_tissue_total, mechanism)
	var cut_share: float = final_cut / total_final
	var blunt_share: float = final_blunt / total_final
	if cut_share >= MFB_SHARP_DOMINANT_RATIO:
		mechanism = "sharp"
	elif blunt_share >= MFB_SHARP_DOMINANT_RATIO:
		mechanism = "blunt"
	else:
		mechanism = "mixed"
	match mechanism:
		"sharp":
			to_bone = _sharp_bone_damage(final_cut, part, sub_region, penetration_sharp, strike_ke_j)
			to_tissue_total = maxf(0.0, total_final - to_bone)
		"blunt":
			to_bone = _blunt_bone_damage_capped(final_blunt, part, sub_region, ke_blunt)
			to_tissue_total = maxf(0.0, total_final - to_bone)
		_:
			to_bone = _blunt_bone_damage_capped(final_blunt, part, sub_region, ke_blunt)
			to_tissue_total = maxf(0.0, total_final - to_bone)
	if to_tissue_total > 0.0:
		to_cut = to_tissue_total * (final_cut / total_final)
		to_blunt = maxf(0.0, to_tissue_total - to_cut)
	return _pack(to_cut, to_blunt, to_bone, to_tissue_total, mechanism)


static func blunt_fracture_j_anchor(part: String, sub_region: String) -> float:
	var part_row: Variant = MFB_BLUNT_FRACTURE_J_BY_SUBREGION.get(part, {})
	if part_row is Dictionary and not sub_region.is_empty() and part_row.has(sub_region):
		return float(part_row[sub_region])
	return _PART_DEFAULT_BLUNT_J.get(part, 28.0)


const _PART_DEFAULT_BLUNT_J: Dictionary = {
	_BodyPartConstants.PART_HEAD: 18.0,
	_BodyPartConstants.PART_CHEST: 32.0,
	_BodyPartConstants.PART_RIGHT_ARM: 24.0,
	_BodyPartConstants.PART_LEFT_ARM: 24.0,
	_BodyPartConstants.PART_RIGHT_LEG: 30.0,
	_BodyPartConstants.PART_LEFT_LEG: 30.0,
}


## J excess → game bone damage (~`DAMAGE_KE_SCALE * sqrt(J)` tissue scale).
static func j_excess_to_bone_damage(excess_j: float) -> float:
	return _WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, excess_j))


static func _sharp_bone_damage(
	final_cut: float,
	part: String,
	sub_region: String,
	penetration_sharp: float,
	strike_ke_j: float
) -> float:
	var to_bone: float = 0.0
	if penetration_sharp >= MFB_CUT_BONE_MIN_PENETRATION_MM:
		to_bone = _bone_from_tissue_stream_threshold(final_cut, part, sub_region)
	if strike_ke_j >= 0.0:
		var j_anchor: float = blunt_fracture_j_anchor(part, sub_region)
		if strike_ke_j >= j_anchor:
			to_bone = maxf(
				to_bone,
				maxf(MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR, j_excess_to_bone_damage(strike_ke_j - j_anchor))
			)
	return to_bone


static func _blunt_bone_damage_capped(
	final_blunt: float, part: String, sub_region: String, strike_ke_j: float
) -> float:
	if final_blunt <= 0.0:
		return 0.0
	var to_bone: float = 0.0
	if strike_ke_j >= 0.0:
		var j_anchor: float = blunt_fracture_j_anchor(part, sub_region)
		if strike_ke_j >= j_anchor:
			to_bone = maxf(
				MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR,
				j_excess_to_bone_damage(strike_ke_j - j_anchor)
			)
	var stream_fallback: float = _bone_from_tissue_stream_threshold(final_blunt, part, sub_region)
	if stream_fallback > 0.0:
		to_bone = maxf(to_bone, stream_fallback)
	var cap: float = final_blunt * MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT
	return minf(to_bone, cap)


static func _bone_from_tissue_stream_threshold(stream_damage: float, part: String, sub_region: String) -> float:
	var bone_threshold: int = _BodyPartConstants.get_bone_damage_threshold(part, sub_region)
	var bone_fraction: float = _BodyPartConstants.get_bone_damage_fraction(part, sub_region)
	var bone_min: int = _BodyPartConstants.get_bone_damage_min(part)
	if stream_damage < float(bone_threshold):
		return 0.0
	var excess: float = stream_damage - float(bone_threshold)
	return maxf(float(bone_min), excess * bone_fraction)


static func _pack(
	to_cut: float, to_blunt: float, to_bone: float, to_tissue_total: float, mechanism: String
) -> Dictionary:
	return {
		"to_cut": to_cut,
		"to_blunt": to_blunt,
		"to_bone": to_bone,
		"to_tissue_total": to_tissue_total,
		"mechanism": mechanism,
	}
