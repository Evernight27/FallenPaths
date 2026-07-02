class_name MaterialFailureCurves
extends RefCounted

## M1+ material failure constitutive laws: pen/KE -> game damage; M2 blend in `EntityDamage`.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _DamageMechanism := preload("res://core/CombatDamageMechanism.gd")
const _Bp := preload("res://core/BodyPartConstants.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
## Graze -> penetrating cut in tissue (mm).
const CUT_TISSUE_YIELD_PEN_MM := 0.5
## Game damage at ultimate pen (forearm anchor 'permille^ moderate laceration stream before MFB split).
const CUT_TISSUE_ULTIMATE_DAMAGE_BY_PART: Dictionary = {
	_Bp.PART_HEAD: 14.0,
	_Bp.PART_CHEST: 16.0,
	_Bp.PART_RIGHT_ARM: 11.0,
	_Bp.PART_LEFT_ARM: 11.0,
	_Bp.PART_RIGHT_LEG: 13.0,
	_Bp.PART_LEFT_LEG: 13.0,
}


static func is_active(force: bool = false) -> bool:
	return force or _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES


## Ultimate cut pen (mm): S8 `PENETRATION_DEPTH_SEVERITY_FULL_MM` + `CombatDesignAnchors` offset (6.0).
static func cut_tissue_ultimate_pen_mm() -> float:
	return _DesignAnchors.cut_tissue_ultimate_pen_mm()


## Shallow/deep branch  -  single delegate to `BleedingConstants` (no fork).
static func penetration_depth_mult(penetration_to_tissue_mm: float) -> float:
	return _Bleeding.penetration_depth_severity_mult(penetration_to_tissue_mm)


## Piecewise cut tissue damage from post-armor penetration (mm). `scale` tunes harness/audit rows.
static func cut_tissue_damage_from_pen(pen_mm: float, part: String, scale: float = 1.0) -> float:
	if pen_mm <= 0.0:
		return 0.0
	var ultimate_damage: float = CUT_TISSUE_ULTIMATE_DAMAGE_BY_PART.get(part, 11.0) * maxf(0.0, scale)
	var depth_mult: float = penetration_depth_mult(pen_mm)
	if pen_mm <= CUT_TISSUE_YIELD_PEN_MM:
		var graze_frac: float = pen_mm / CUT_TISSUE_YIELD_PEN_MM
		return ultimate_damage * 0.12 * graze_frac * depth_mult
	var ultimate_pen: float = cut_tissue_ultimate_pen_mm()
	if pen_mm >= ultimate_pen:
		return ultimate_damage * depth_mult
	var span: float = ultimate_pen - CUT_TISSUE_YIELD_PEN_MM
	var t: float = (pen_mm - CUT_TISSUE_YIELD_PEN_MM) / span
	var core: float = lerpf(ultimate_damage * 0.18, ultimate_damage, clampf(t, 0.0, 1.0))
	return core * depth_mult


## Blunt bone chip from strike KE (J); matches MFB `j_excess_to_bone_damage` at anchors.
static func blunt_bone_damage_from_ke(ke_j: float, part: String, sub_region: String) -> float:
	if ke_j < 0.0:
		return 0.0
	var j_anchor: float = _DamageMechanism.blunt_fracture_j_anchor(part, sub_region)
	if ke_j < j_anchor:
		return 0.0
	return _DamageMechanism.j_excess_to_bone_damage(ke_j - j_anchor)


## Cut-dominant bone gate in pen space (mm); mirrors `MFB_CUT_BONE_MIN_PENETRATION_MM` until M2 blend.
static func cut_bone_damage_from_pen(
	pen_mm: float, part: String, _sub_region: String, scale: float = 1.0
) -> float:
	if pen_mm < _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
		return 0.0
	var tissue: float = cut_tissue_damage_from_pen(pen_mm, part, scale)
	var bone_frac: float = 0.35
	return tissue * bone_frac * penetration_depth_mult(pen_mm)


## Committed oberhau reference KE (J) for audit/harness anchors.
static func reference_committed_arm_ke_j() -> float:
	return _DesignAnchors.REFERENCE_COMMITTED_OBERHAU_KE_J


## M2: curve-based bone/tissue split (same return shape as `CombatDamageMechanism.allocate_bone_and_tissue`).
static func allocate_bone_and_tissue(
	final_cut: float,
	final_blunt: float,
	total_final: float,
	part: String,
	sub_region: String,
	_pen_to_tissue_mm: float,
	pen_for_bone_mm: float,
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
	if cut_share >= _DamageMechanism.MFB_SHARP_DOMINANT_RATIO:
		mechanism = "sharp"
	elif blunt_share >= _DamageMechanism.MFB_SHARP_DOMINANT_RATIO:
		mechanism = "blunt"
	else:
		mechanism = "mixed"
	match mechanism:
		"sharp":
			to_bone = cut_bone_damage_from_pen(pen_for_bone_mm, part, sub_region)
			if strike_ke_j >= 0.0:
				to_bone = maxf(
					to_bone, blunt_bone_damage_from_ke(strike_ke_j, part, sub_region)
				)
			to_bone = minf(to_bone, total_final * 0.45)
		"blunt":
			to_bone = blunt_bone_damage_from_ke(ke_blunt, part, sub_region)
			to_bone = minf(to_bone, final_blunt * _DamageMechanism.MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT)
		_:
			to_bone = blunt_bone_damage_from_ke(ke_blunt, part, sub_region)
			to_bone = minf(to_bone, final_blunt * _DamageMechanism.MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT)
	to_tissue_total = maxf(0.0, total_final - to_bone)
	if to_tissue_total > 0.0:
		to_cut = to_tissue_total * (final_cut / total_final)
		to_blunt = maxf(0.0, to_tissue_total - to_cut)
	return _pack(to_cut, to_blunt, to_bone, to_tissue_total, mechanism)


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


## Blend MFB vs curve allocations; `blend_weight` 0 = MFB only, 1 = curve only.
static func blend_allocations(mfb: Dictionary, curve: Dictionary, blend_weight: float) -> Dictionary:
	var w: float = clampf(blend_weight, 0.0, 1.0)
	return {
		"to_cut": lerpf(mfb.get("to_cut", 0.0), curve.get("to_cut", 0.0), w),
		"to_blunt": lerpf(mfb.get("to_blunt", 0.0), curve.get("to_blunt", 0.0), w),
		"to_bone": lerpf(mfb.get("to_bone", 0.0), curve.get("to_bone", 0.0), w),
		"to_tissue_total": lerpf(
			mfb.get("to_tissue_total", 0.0), curve.get("to_tissue_total", 0.0), w
		),
		"mechanism": str(curve.get("mechanism", mfb.get("mechanism", "mixed"))),
	}
