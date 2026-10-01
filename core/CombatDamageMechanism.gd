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
## subcutaneous fat, fascia, and muscle (thin-build mid-torso baseline; ~6 mm, more for heavier builds). Replaces
## RHA-based threshold.
const CUT_BONE_MIN_TISSUE_DEPTH_MM := 6.0
const MFB_BLUNT_FRACTURE_GAME_DAMAGE_FLOOR := 1.0
## Blunt-dominant: bone chip capped so crush tissue remains on the stream.
const MFB_BLUNT_MAX_BONE_SHARE_OF_BLUNT := 0.45

## Blunt bone-damage threshold = the WEAPON IMPACT KE (J) that must reach a sub-region to drive
## fracture-scale damage. These are impact-energy anchors, NOT the intrinsic work of fracture: quasi-static
## bone fracture work is far lower (femur ~35 J, tibia ~25 J, skull ~4-23 J; see BodyPartConstants), and a
## real weapon must deliver well above that because the impact is dynamic and much of the strike's KE is not
## fully coupled into the bone. Magnitudes are tuned order-of-magnitude anchors for game feel.
const MFB_BLUNT_FRACTURE_J_BY_SUBREGION: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 80.0, "face": 60.0, "neck": 50.0},
    BodyPartConstants.PART_CHEST: {"thoracic": 65.0, "abdominal": 80.0, "sternum": 45.0},
    BodyPartConstants.PART_RIGHT_ARM:
    {"upper_arm": 100.0, "elbow": 45.0, "forearm": 70.0, "hand": 35.0, "armpit": 50.0, "axillary": 50.0},
    BodyPartConstants.PART_LEFT_ARM:
    {"upper_arm": 100.0, "elbow": 45.0, "forearm": 70.0, "hand": 35.0, "armpit": 50.0, "axillary": 50.0},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 200.0, "knee": 60.0, "calf": 120.0, "foot": 55.0, "inner_thigh": 130.0},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 200.0, "knee": 60.0, "calf": 120.0, "foot": 55.0, "inner_thigh": 130.0},
}

# --- Blunt internal organ trauma thresholds (J) — visceral injury without penetration ---
## Game impact-KE thresholds, not clinical measurements. Real blunt-organ injury is characterized by
## deceleration (g), chest/abdominal compression (%), or force (kN) rather than a fixed Joule amount, so
## these are order-of-magnitude anchors for when concentrated blunt energy should plausibly produce organ
## trauma. Set above the ~35 J combat-realistic floor so a normal glancing blow doesn't count.
const BLUNT_INTERNAL_ORGAN_TRAUMA_J: Dictionary = {
    "thoracic": {"pulmonary_contusion": 40.0, "aortic_vessel": 120.0},
    # lung contusion (low KE); great-vessel damage needs a much more concentrated transfer
    "abdominal": {"liver_spleen_tear": 65.0, "bowel_injury": 1500.0},
    # liver/spleen capsule tear (low threshold); bowel injury requires extreme, near-severing energy
}

# --- Internal organ trauma damage output (game HP applied to body_blunt as hidden tissue damage) ---
const BLUNT_ORGAN_BLUNT_DAMAGE_MULT: float = 1.8  # organ trauma amplifies blunt channel (soft tissue crush)
const BLUNT_ORGAN_PAIN_MULT: float = 2.5  # visceral pain is disproportionately severe (visceral nociceptors)
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
    entity_bone_max: int = 0
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
            to_bone = _sharp_bone_damage(final_cut, part, sub_region, penetration_sharp, strike_ke_j, entity_bone_max)
            to_tissue_total = maxf(0.0, total_final - to_bone)
        "blunt":
            to_bone = _blunt_bone_damage_capped(final_blunt, part, sub_region, ke_blunt, entity_bone_max)
            to_tissue_total = maxf(0.0, total_final - to_bone)
        _:
            to_bone = _blunt_bone_damage_capped(final_blunt, part, sub_region, ke_blunt, entity_bone_max)
            to_tissue_total = maxf(0.0, total_final - to_bone)
    # Enforce conservation: bone + tissue cannot exceed original input.
    if to_bone > total_final:
        to_bone = total_final
        to_tissue_total = 0.0
    # R4: a blunt impact always drives some soft-tissue trauma; at least
    # BLUNT_MIN_TISSUE_FLOOR_MULT of the (post-armor) blunt value must remain as
    # tissue rather than being allocated entirely to bone. Redistribute from bone to
    # tissue so conservation still holds.
    if mechanism in ["blunt", "mixed"] and final_blunt > 0.0:
        var tissue_floor: float = CombatConstantsDamage.BLUNT_MIN_TISSUE_FLOOR_MULT * final_blunt
        if to_tissue_total < tissue_floor:
            to_tissue_total = minf(tissue_floor, total_final)
            to_bone = maxf(0.0, total_final - to_tissue_total)
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
## NOTE: This is a game abstraction, not a clinical measurement. RHA penetration quantifies
## armor-steel resistance; tissue depth measures actual blade travel through skin→fat→fascia→muscle.
## The 3.0× factor absorbs that difference — calibrated so ~2mm RHA maps to ~6mm tissue depth, which
## reaches cortical bone at mid-torso for a thin build. Depth-to-bone is body-habitus-dependent
## (fat ~5-30mm plus pectoral muscle add several mm on average builds), so treat ~6mm as a conservative
## baseline rather than a universal constant. A fuller model would use a layered-anatomy lookup per
## body part (skin ~1-2mm, fat ~5-30mm variable, fascia ~0.5mm).
static func rha_penetration_to_tissue_depth_mm(rha_pen_mm: float) -> float:
    return rha_pen_mm * 3.0


static func _sharp_bone_damage(
    final_cut: float,
    part: String,
    sub_region: String,
    penetration_sharp: float,
    strike_ke_j: float,
    entity_bone_max: int = 0
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
    if entity_bone_max > 0:
        to_bone = minf(to_bone, float(entity_bone_max))
    return to_bone


static func _blunt_bone_damage_capped(
    final_blunt: float, part: String, sub_region: String, strike_ke_j: float, entity_bone_max: int = 0
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
    if entity_bone_max > 0:
        cap = minf(cap, float(entity_bone_max))
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


# --- Blunt internal organ trauma (visceral injury without penetration) ---


## Checks for blunt-force internal organ damage in thoracic/abdominal sub-regions.
## Returns {"organ_blunt_dmg": float, "organ_pain_mult": float, "trauma_type": String}.
## When a high-KE blunt strike hits visceral regions WITHOUT penetrating to bone (no cut path),
## the energy transfer can still rupture liver/spleen capsules, contuse lungs, or shear vessels.
static func check_blunt_internal_organ_trauma(
    part: String, sub_region: String, strike_ke_j: float, penetration_sharp: float
) -> Dictionary:
    if part != BodyPartConstants.PART_CHEST:
        return {"organ_blunt_dmg": 0.0, "organ_pain_mult": 1.0, "trauma_type": ""}
    var organ_data: Variant = BLUNT_INTERNAL_ORGAN_TRAUMA_J.get(sub_region, {})
    if organ_data is not Dictionary or strike_ke_j <= 0.0:
        return {"organ_blunt_dmg": 0.0, "organ_pain_mult": 1.0, "trauma_type": ""}
    ## Only trigger when there's NO sharp penetration path to bone (pure blunt trauma). Compare in
    ## tissue-depth units (RHA->tissue), consistent with the sharp bone-chip gate in _sharp_bone_damage:
    ## without the conversion a mixed strike whose blade actually reaches bone (e.g. ~3mm RHA ~ 9mm tissue)
    ## would still fire organ trauma because the raw RHA value never reaches the tissue-depth threshold.
    if rha_penetration_to_tissue_depth_mm(penetration_sharp) >= CUT_BONE_MIN_TISSUE_DEPTH_MM:
        return {"organ_blunt_dmg": 0.0, "organ_pain_mult": 1.0, "trauma_type": ""}
    var organ_blunt_dmg: float = 0.0
    var trauma_type: String = ""
    if sub_region == "thoracic" and strike_ke_j >= organ_data.get("pulmonary_contusion", 999.0):
        ## Pulmonary contusion + potential aortic injury at higher KE.
        organ_blunt_dmg = BLUNT_ORGAN_BLUNT_DAMAGE_MULT * sqrt(strike_ke_j)
        if strike_ke_j >= organ_data.get("aortic_vessel", 999.0):
            trauma_type = "aortic_trauma"  # great vessel rupture — near-instantaneous exsanguination risk
        else:
            trauma_type = "pulmonary_contusion"
    elif sub_region == "abdominal":
        if strike_ke_j >= organ_data.get("liver_spleen_tear", 999.0):
            ## Liver/spleen capsule tear — solid organs have rich blood supply; internal bleeding.
            organ_blunt_dmg = BLUNT_ORGAN_BLUNT_DAMAGE_MULT * sqrt(strike_ke_j)
            trauma_type = "liver_spleen_tear"
        elif strike_ke_j >= organ_data.get("bowel_injury", 999.0):
            ## Bowel/mesenteric shear — less immediately lethal but causes peritonitis if untreated.
            organ_blunt_dmg = BLUNT_ORGAN_BLUNT_DAMAGE_MULT * 0.6 * sqrt(strike_ke_j)
            trauma_type = "bowel_injury"
    var pain_mult: float = BLUNT_ORGAN_PAIN_MULT if organ_blunt_dmg > 0.0 else 1.0
    return {
        "organ_blunt_dmg": organ_blunt_dmg,
        "organ_pain_mult": pain_mult,
        "trauma_type": trauma_type,
    }
