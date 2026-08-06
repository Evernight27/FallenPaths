class_name CombatDamageMechanism
extends RefCounted

## Mechanism-first bone/tissue split (S3): cut-dominant vs blunt-dominant fracture gates.

const MFB_SHARP_DOMINANT_RATIO := 0.85
## Shallow cut / glance: no bone chip unless penetration reaches this (mm RHA scale).
## WARNING: This conflates RHA-equivalent armor penetration with wound-track tissue depth.
## For anatomically accurate bone fracture, use CUT_BONE_MIN_TISSUE_DEPTH_MM instead — clinical data shows
## cortical bone (~2-3 mm thick) requires actual tissue penetration of ~5-8 mm beyond skin/fascia to chip bone.
const MFB_CUT_BONE_MIN_PENETRATION_MM := 2.5
## Actual tissue depth (mm from skin surface) needed to reach and chip cortical bone after passing through
## subcutaneous fat, fascia, and muscle (~3-5 mm average for mid-torso). Replaces RHA-based threshold.
const CUT_BONE_MIN_TISSUE_DEPTH_MM := 6.0
const MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR := 1.0
## Blunt-dominant: bone chip capped so crush tissue remains on the stream.
const MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT := 0.45
## R4: Mace-specific bone share — currently 1.0 (no reduction from baseline); cap set but mace bone boost not applied.
const MACE_BONE_SHARE_MULT := 1.0

## Blunt fracture anchor energy (J) by sub-region (clinical biomechanics literature order-of-magnitude).
## Skull ~70-130J, rib ~40-80J, humerus ~60-120J, radius/ulna ~60-120J, femur ~120-250J (combat) / 300-500J (polearm), tibia ~100-200J.
const MFB_BLUNT_FRACTURE_J_BY_SUBREGION: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 80.0, "face": 60.0, "neck": 50.0},
    BodyPartConstants.PART_CHEST: {"thoracic": 65.0, "abdominal": 80.0},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 100.0, "elbow": 45.0, "forearm": 70.0, "hand": 35.0},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 100.0, "elbow": 45.0, "forearm": 70.0, "hand": 35.0},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 200.0, "knee": 60.0, "calf": 120.0, "foot": 55.0},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 200.0, "knee": 60.0, "calf": 120.0, "foot": 55.0},
}
const _PART_DEFAULT_BLUNT_J: Dictionary = {
    BodyPartConstants.PART_HEAD: 70.0,
    BodyPartConstants.PART_CHEST: 80.0,
    BodyPartConstants.PART_RIGHT_ARM: 100.0,
    BodyPartConstants.PART_LEFT_ARM: 100.0,
    BodyPartConstants.PART_RIGHT_LEG: 200.0,
    BodyPartConstants.PART_LEFT_LEG: 200.0,
}


static func allocate_bone_and_tissue(
    final_cut: float,
    final_blunt: float,
    total_final: float,
    part: String,
    sub_region: String,
    penetration_sharp: float,
    strike_ke_j: float,
    strike_ke_blunt_j: float = -1.0,
    weapon_type: String = ""
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
            to_bone = _blunt_bone_damage_capped(final_blunt, part, sub_region, ke_blunt, weapon_type)
            to_tissue_total = maxf(0.0, total_final - to_bone)
        _:
            to_bone = _blunt_bone_damage_capped(final_blunt, part, sub_region, ke_blunt, weapon_type)
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


## J excess -> game bone damage (~`DAMAGE_KE_SCALE * sqrt(J)` tissue scale).
static func j_excess_to_bone_damage(excess_j: float) -> float:
    return WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, excess_j))


## Convert RHA-equivalent armor penetration (mm) to approximate tissue depth (mm).
## Steel is ~3-5× harder than muscle/fat on Vickers hardness scale; a blade penetrating 2 mm RHA
## typically reaches ~6-10 mm in tissue. Historical ballistic data for edged weapons suggests
## tissue_depth ≈ rha_penetration × 3.0 (average compression factor through layered soft tissue).
static func rha_penetration_to_tissue_depth_mm(rha_pen_mm: float) -> float:
    return rha_pen_mm * 3.0


static func _sharp_bone_damage(
    final_cut: float, part: String, sub_region: String, penetration_sharp: float, strike_ke_j: float
) -> float:
    var to_bone: float = 0.0
    ## Convert RHA-equivalent armor penetration to tissue depth before bone chip check.
    ## Clinical anatomy: cortical bone ~2-3 mm thick; requires ~6+ mm actual tissue depth beyond skin.
    var tissue_depth: float = rha_penetration_to_tissue_depth_mm(penetration_sharp)
    if tissue_depth >= CUT_BONE_MIN_TISSUE_DEPTH_MM:
        to_bone = _bone_from_tissue_stream_threshold(final_cut, part, sub_region)
    if strike_ke_j >= 0.0:
        var j_anchor: float = blunt_fracture_j_anchor(part, sub_region)
        if strike_ke_j >= j_anchor:
            to_bone = maxf(
                to_bone, maxf(MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR, j_excess_to_bone_damage(strike_ke_j - j_anchor))
            )
    return to_bone


static func _blunt_bone_damage_capped(
    final_blunt: float, part: String, sub_region: String, strike_ke_j: float, weapon_type: String = ""
) -> float:
    if final_blunt <= 0.0:
        return 0.0
    var to_bone: float = 0.0
    if strike_ke_j >= 0.0:
        var j_anchor: float = blunt_fracture_j_anchor(part, sub_region)
        if strike_ke_j >= j_anchor:
            to_bone = maxf(MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR, j_excess_to_bone_damage(strike_ke_j - j_anchor))
    var stream_fallback: float = _bone_from_tissue_stream_threshold(final_blunt, part, sub_region)
    if stream_fallback > 0.0:
        to_bone = maxf(to_bone, stream_fallback)
    var cap: float = final_blunt * MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT
    if weapon_type == "MACE":
        cap *= MACE_BONE_SHARE_MULT
    return minf(to_bone, cap)


static func _bone_from_tissue_stream_threshold(stream_damage: float, part: String, sub_region: String) -> float:
    var bone_threshold: int = BodyPartConstants.get_bone_damage_threshold(part, sub_region)
    var bone_fraction: float = BodyPartConstants.get_bone_damage_fraction(part, sub_region)
    var bone_min: int = BodyPartConstants.get_bone_damage_min(part)
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
