class_name CombatConstantsAttackPath

extends RefCounted

## Attack path tables and geometry functions extracted from CombatConstants.gd.
## Canonical source for body-part paths, angles, alignment, deflection logic.
const PARRY_ALIGNMENT_FLOOR := 0.0

const GEOMETRIC_LEAK_MAX := 0.25

## Non-linear geometric leak: alignment loss follows a square curve so high-alignment parries (HEMA "on the blade") are
## clean, while oblique angles produce proportionally more leak than linear scaling would suggest. Formula: pow(1-align,
## 2) * GEOMETRIC_LEAK_MAX.
const PARRY_GEOMETRY_VARIANCE_BASE := 0.08

## Fatigue-driven aim drift: the intended-part boost is multiplied by lerp(this, 1.0, stamina_ratio).
## A fresh attacker (stamina 1.0) aims precisely (boost x1.0); an exhausted one (stamina 0.0)
## aims at 80% precision (boost x0.80), so the landing part drifts off the aimed part a bit more
## often. Couples the diagnostic aim_drift to a real mechanic (stamina). 0.80 reflects the
## sports-science finding that fatigue widens the error around the intended target (precision loss)
## rather than shifting which part is aimed at — the aimed part stays the modal outcome even when
## exhausted, just with somewhat wider scatter.
const AIM_DRIFT_FATIGUE_FLOOR := 0.8

## Aim-leak near-miss falloff: the probability that leaks off the aimed part (the
## (1—aim_share) remainder) decays with blade-path distance from that part,
## 1/(1 + K*d) where d = number of path positions from the aimed part. Path order
## is blade-travel order, so the parts the blade actually passes clip preferentially.
## A fresh fencer's error cloud is tight (high K -> steep falloff, near-misses dominate);
## fatigue widens it (K drops -> flatter falloff, misses spread to more distant parts),
## matching the sports-science finding that fatigue raises the spread of the aim error.
const LEAK_PROXIMITY_FALLOFF_K := 0.7

const LEAK_PROXIMITY_FALLOFF_K_FATIGUED := 0.25

const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := 0.65

const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := 0.5

const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := 0.8

const DEFLECTED_GUARD_FROM_ATTACK: Dictionary = {"high": "low", "low": "high", "left": "right", "right": "left"}

const LINE_ADJACENTS: Dictionary = {
    "high": ["left", "right"], "low": ["left", "right"], "left": ["high", "low"], "right": ["high", "low"]
}

const DODGE_END_GUARD_FROM_ATTACK: Dictionary = {"high": "low", "low": "high", "left": "right", "right": "left"}

const GUARD_DEFAULT := "high"

# Option 6: Path + Guard Intercept — blade path per attack_line; guard determines intercept point.
# Path order = blade travel; early parts = first contact when guard puts limbs in the way.
# High alignment (same line) = early intercept (arms/limbs); low alignment = blade gets through (center mass).
const ATTACK_PATH_HIGH: Array = ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"]  # descending

const ATTACK_PATH_LOW: Array = ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"]  # rising

const ATTACK_PATH_LEFT: Array = ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"]  # from left

const ATTACK_PATH_RIGHT: Array = ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"]  # from right

const ATTACK_PATHS: Dictionary = {
    "high": ATTACK_PATH_HIGH, "low": ATTACK_PATH_LOW, "left": ATTACK_PATH_LEFT, "right": ATTACK_PATH_RIGHT
}

# Guard-dependent paths: path varies by defender posture.
const ATTACK_PATHS_BY_GUARD: Dictionary = {
    "high":
    {
        "high": ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"],
        "low": ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"],
        "left": ["left_arm", "head", "chest", "right_arm", "left_leg", "right_leg"],
        "right": ["right_arm", "head", "chest", "left_arm", "left_leg", "right_leg"]
    },
    "low":
    {
        "high": ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"],
        "low": ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"],
        "left": ["left_leg", "left_arm", "right_leg", "chest", "right_arm", "head"],
        "right": ["right_leg", "right_arm", "left_leg", "chest", "left_arm", "head"]
    },
    "left":
    {
        "high": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
        "low": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
        "left": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
        "right": ["left_arm", "chest", "left_leg", "head", "right_arm", "right_leg"]
    },
    "right":
    {
        "high": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"],
        "low": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"],
        "left": ["right_arm", "chest", "right_leg", "head", "left_arm", "left_leg"],
        "right": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"]
    }
}

# Diagonal line roll (C: alignment-weighted): weights per (move_id, defender_guard_line).
const DIAGONAL_WEIGHTS: Dictionary = {
    "oberhau":
    {
        "high": {"high": 0.7, "low": 0.5, "left": 0.55, "right": 0.5},
        "low": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.5},
        "left": {"high": 0.6, "low": 0.5, "left": 0.65, "right": 0.5},
        "right": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.65}
    },
    "oberhau_feint":
    {
        "high": {"high": 0.7, "low": 0.5, "left": 0.55, "right": 0.5},
        "low": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.5},
        "left": {"high": 0.6, "low": 0.5, "left": 0.65, "right": 0.5},
        "right": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.65}
    },
    "unterhau":
    {
        "high": {"high": 0.5, "low": 0.65, "left": 0.5, "right": 0.5},
        "low": {"high": 0.5, "low": 0.7, "left": 0.55, "right": 0.55},
        "left": {"high": 0.5, "low": 0.6, "left": 0.65, "right": 0.5},
        "right": {"high": 0.5, "low": 0.6, "left": 0.5, "right": 0.65}
    },
    "diagonal_chop":
    {
        "high": {"high": 0.65, "low": 0.5, "left": 0.7, "right": 0.5},
        "low": {"high": 0.5, "low": 0.6, "left": 0.65, "right": 0.55},
        "left": {"high": 0.55, "low": 0.5, "left": 0.7, "right": 0.5},
        "right": {"high": 0.5, "low": 0.55, "left": 0.5, "right": 0.65}
    },
    "slash":
    {
        "high": {"high": 0.55, "low": 0.5, "left": 0.65, "right": 0.55},
        "low": {"high": 0.5, "low": 0.55, "left": 0.6, "right": 0.55},
        "left": {"high": 0.55, "low": 0.5, "left": 0.7, "right": 0.5},
        "right": {"high": 0.5, "low": 0.55, "left": 0.5, "right": 0.65}
    },
    "side_strike":
    {
        "high": {"high": 0.5, "low": 0.5, "left": 0.65, "right": 0.65},
        "low": {"high": 0.5, "low": 0.5, "left": 0.6, "right": 0.6},
        "left": {"high": 0.55, "low": 0.55, "left": 0.65, "right": 0.5},
        "right": {"high": 0.55, "low": 0.55, "left": 0.5, "right": 0.65}
    }
}

# Intercept: alignment 1.0 = hit early parts (indices 0..2); alignment 0.0 = full path (0..5)
const PATH_INTERCEPT_EARLY_MAX := 2

const PATH_INTERCEPT_FULL_MAX := 5

## Angle (degrees) from defender guard line to attacker attack line.
const LINE_ANGLE_DEG: Dictionary = {
    "high": {"high": 0, "low": 90, "left": 45, "right": 45},
    "low": {"high": 90, "low": 0, "left": 45, "right": 45},
    "left": {"high": 45, "low": 45, "left": 0, "right": 90},
    "right": {"high": 45, "low": 45, "left": 90, "right": 0}
}

const LINE_TO_ANGLE_DEG: Dictionary = {"high": 0.0, "right": 90.0, "low": 180.0, "left": 270.0}

const ANGLE_VARIANCE_DEG: float = 8.0

const ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT: float = 1.6

const ANGLE_VARIANCE_OFF_BALANCE_MULT: float = 1.35

const ANGLE_VARIANCE_MASS_REFERENCE_KG: float = 1.0

const ANGLE_VARIANCE_MASS_SCALE: float = 0.1

const GUARD_WOBBLE_MAX_DEG: float = 12.0

const GUARD_WOBBLE_READINESS_SCALE: float = 1.0

const GUARD_WOBBLE_MASS_REFERENCE_KG: float = 1.0

const GUARD_WOBBLE_MASS_SCALE: float = 0.08

const ARC_SPAN_LATE_PARRY_THRESHOLD_DEG: float = 50.0

const ARC_SPAN_LATE_PARRY_PENALTY_MAX: float = 0.25

const DODGE_FULL_THRESHOLD := 0.55

## Dodge outcome threshold: randf() < this value → full dodge; otherwise partial (glancing) dodge.
## Game-feel tuning: ~55% of successful dodges roll as full evasions for average combatants, with the remainder
## producing partial dodges that reduce but don't eliminate hit damage. Higher values make dodges feel more reliable.
const DODGE_PARTIAL_RATIO_MIN := 0.4

const PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY := 0.67

const PARRY_FOLLOW_THROUGH_PARTIAL_MIN := 0.5

const PARRY_PARTIAL_MAX_RATIO := 0.85

const PARRY_FOLLOW_THROUGH_THRUST_PENALTY := 0.12

const PARRY_FOLLOW_THROUGH_CUT_BONUS := 0.05

const RECOVERY_AGILITY_MIN := 0.7

const RECOVERY_AGILITY_MAX := 1.3

const WEAK_EXPOSURE_BY_ARCH: Dictionary = {
    "overhead": 1.0, "heavy_blunt": 0.0, "slash": 0.5, "stab": 0.75, "pommel_strike": 0.0, "quick_slash": 0.3
}

const DEFENDER_STRONG_BONUS: float = 0.12

const PARRY_STRONG_CONTACT_BY_ARCH: Dictionary = {
    "overhead": 1.12, "heavy_blunt": 1.08, "slash": 1.0, "stab": 1.02, "pommel_strike": 1.0, "quick_slash": 0.95
}

## Forte/schwach bonus scales with blade flexibility. A flexible blade (long/thin) flexes more under load,
## so its forte/schwach difference is larger; a stiff blade (short/thick) flexes less. Slenderness =
## blade_length_cm / blade_width_cm. Reference calibrated to SWORD (90cm / 2.0cm = 45) so D001 (SWORD-only)
## is unaffected. Flexible blades (high slenderness) get up to FLEX_FACTOR_MAX; stiff blades get FLEX_FACTOR_MIN.
const FLEX_REFERENCE_SLENDERNESS := 45.0

const FLEX_FACTOR_MIN := 0.5

const FLEX_FACTOR_MAX := 1.5

const HIT_SUB_REGION_SEED_MULTIPLIER: int = 31


static func flex_factor_for_slenderness(slenderness: float) -> float:
    ## Forte/schwach bonus multiplier from blade slenderness. 0.0 (no blade) -> 1.0 (neutral, no forte/schwach).
    ## At the reference slenderness (45, SWORD) -> 1.0. More slender (flexible) -> up to 1.5; stiffer -> down to 0.5.
    if slenderness <= 0.0:
        return 1.0
    return clampf(slenderness / FLEX_REFERENCE_SLENDERNESS, FLEX_FACTOR_MIN, FLEX_FACTOR_MAX)


static func _iv6_bubble_pair(parts: Array, before: String, after: String) -> Array:
    var out: Array = parts.duplicate()
    var i_before: int = out.find(before)
    var i_after: int = out.find(after)
    if i_before < 0 or i_after < 0 or i_before <= i_after:
        return out
    out.remove_at(i_before)
    i_after = out.find(after)
    out.insert(i_after, before)
    return out


static func _iv6_promote_to_front(parts: Array, part: String) -> Array:
    var out: Array = parts.duplicate()
    var idx: int = out.find(part)
    if idx <= 0:
        return out
    out.remove_at(idx)
    out.insert(0, part)
    return out


static func _iv6_diagonal_path_pool(flank_path: Array, vert_path: Array, zone_part: String) -> Array:
    var pool: Array = []
    for part in flank_path:
        var p: String = str(part)
        if p != zone_part and p not in pool:
            pool.append(p)
    for part in vert_path:
        var p: String = str(part)
        if p != zone_part and p not in pool:
            pool.append(p)
    return pool


static func _iv6_shape_diagonal_pool(pool: Array, guard_oct: String) -> Array:
    var shaped: Array = pool.duplicate()
    match guard_oct:
        CombatGuardLines.LINE_HIGH_LEFT:
            shaped = _iv6_bubble_pair(shaped, "head", "right_arm")
            shaped = _iv6_bubble_pair(shaped, "right_arm", "chest")
        CombatGuardLines.LINE_HIGH_RIGHT:
            shaped = _iv6_bubble_pair(shaped, "head", "left_arm")
            shaped = _iv6_bubble_pair(shaped, "left_arm", "chest")
        CombatGuardLines.LINE_LOW_LEFT, CombatGuardLines.LINE_LOW_RIGHT:
            shaped = _iv6_promote_to_front(shaped, "left_leg")
            shaped = _iv6_promote_to_front(shaped, "right_leg")
    return shaped


static func _iv6_diagonal_attack_path(
    flank_path: Array, vert_path: Array, guard_oct: String, zone_part: String
) -> Array:
    var pool: Array = _iv6_diagonal_path_pool(flank_path, vert_path, zone_part)
    pool = _iv6_shape_diagonal_pool(pool, guard_oct)
    var out: Array = []
    if zone_part != "":
        out.append(zone_part)
    for part in pool:
        out.append(part)
    return out


static func get_attack_path(attack_line: String, guard_line: String) -> Array:
    var atk_key: String = str(attack_line).strip_edges()
    var guard_key: String = str(guard_line).strip_edges()
    var guard_oct: String = ""
    if CombatGuardLines.is_known_line(atk_key):
        atk_key = CombatGuardLines.cardinal_for_path_lookup(atk_key)
    if CombatGuardLines.is_known_line(guard_key):
        guard_oct = CombatGuardLines.normalize_line(guard_key)
        if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
            guard_key = CombatGuardLines.guard_cardinal_for_attack_path(guard_oct)
        else:
            guard_key = CombatGuardLines.cardinal_for_path_lookup(guard_key)
    var by_guard: Variant = ATTACK_PATHS_BY_GUARD.get(atk_key, {})
    if not (by_guard is Dictionary and by_guard.has(guard_key)):
        return ATTACK_PATHS.get(atk_key, ATTACK_PATH_HIGH)
    var flank_path: Array = (by_guard as Dictionary)[guard_key]
    if (
        CombatConstantsFeatureFlags.is_feature_iv6_attack_path_octant_enabled()
        and CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled()
        and guard_oct != ""
        and CombatGuardLines.is_flank_diagonal_guard_line(guard_oct)
    ):
        var vert_key: String = CombatGuardLines.cardinal_for_path_lookup(guard_oct)
        if vert_key != guard_key:
            var vert_path: Array = (by_guard as Dictionary).get(vert_key, flank_path)
            var zone: String = CombatGuardLines.guard_zone_part_for_line(guard_oct)
            return _iv6_diagonal_attack_path(flank_path, vert_path, guard_oct, zone)
    return flank_path


static func get_arc_angle_at_progress(arc_start_deg: float, arc_end_deg: float, progress: float) -> float:
    var p: float = clampf(progress, 0.0, 1.0)
    var a: float = fmod(arc_start_deg + 360.0, 360.0)
    var b: float = fmod(arc_end_deg + 360.0, 360.0)
    var diff: float = fmod(b - a + 540.0, 360.0) - 180.0
    return fmod(a + diff * p + 360.0, 360.0)


static func arc_end_deg_for_contact_geometry(pa: Dictionary) -> float:
    var end: float = pa.get(DataKeys.PA_ARC_END_DEG, -999.0)
    if end >= -900.0:
        return end
    end = pa.get(DataKeys.PA_ARC_INTENDED_DEG, -999.0)
    if end >= -900.0:
        return end
    return -999.0


static func get_attack_angle_at_progress(pa: Dictionary, progress: float) -> float:
    var start: float = pa.get(DataKeys.ATTACK_ARC_START_DEG, 0.0)
    var end: float = arc_end_deg_for_contact_geometry(pa)
    if end < -900.0:
        end = line_to_angle("high")
    return get_arc_angle_at_progress(start, end, progress)


static func angle_diff_deg(a_deg: float, b_deg: float) -> float:
    var d := fmod(abs(a_deg - b_deg) + 360.0, 360.0)
    return minf(d, 360.0 - d) if d > 180.0 else d


static func line_to_angle(line: String) -> float:
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        return CombatGuardLines.line_to_angle(line)
    return LINE_TO_ANGLE_DEG.get(line, 0)


static func angle_to_nearest_line(angle_deg: float) -> String:
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        return CombatGuardLines.angle_to_line(angle_deg)
    var a := fmod(angle_deg + 360.0, 360.0)
    if a < 45.0 or a >= 315.0:
        return "high"
    if a < 135.0:
        return "right"
    if a < 225.0:
        return "low"
    return "left"


static func get_alignment_from_angles(attack_angle_deg: float, guard_angle_deg: float) -> float:
    var theta := angle_diff_deg(attack_angle_deg, guard_angle_deg)
    return maxf(PARRY_ALIGNMENT_FLOOR, cos(theta * PI / 180.0))


static func get_deflected_angle_bilateral(
    attack_angle_deg: float, guard_angle_deg: float, magnitude_deg: float
) -> float:
    var cw := fmod(attack_angle_deg + magnitude_deg + 360.0, 360.0)
    var ccw := fmod(attack_angle_deg - magnitude_deg + 360.0, 360.0)
    var dist_cw := angle_diff_deg(cw, guard_angle_deg)
    var dist_ccw := angle_diff_deg(ccw, guard_angle_deg)
    return cw if dist_cw > dist_ccw else ccw


static func get_deflection_magnitude_deg(alignment: float, severity: float, contact_type: String) -> float:
    var base := (1.0 - alignment) * 90.0 * severity
    var mult: float = 1.0
    if contact_type == "stab":
        mult = 1.15
    elif contact_type == "blunt":
        mult = 0.9
    return base * mult * randf_range(0.9, 1.1)


static func parry_opposite_deflect_severity_threshold(contact_type: String) -> float:
    var ct: String = contact_type.to_lower().strip_edges()
    if ct == "stab":
        return PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST
    if ct == "blunt":
        return PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT
    return PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT


static func _adjacent_line_away_from_guard(attack_line: String, guard_angle_deg: float) -> String:
    var atk_line: String = attack_line
    var adj_src: Dictionary = LINE_ADJACENTS
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        atk_line = CombatGuardLines.normalize_line(attack_line)
        adj_src = CombatGuardLines.LINE_ADJACENTS
    var adj_raw: Variant = adj_src.get(atk_line, [])
    if not (adj_raw is Array):
        return atk_line
    var adj_arr: Array = adj_raw as Array
    if adj_arr.is_empty():
        return atk_line
    var best_line: String = str(adj_arr[0])
    var best_dist: float = -1.0
    for candidate in adj_arr:
        var line: String = str(candidate)
        var dist: float = angle_diff_deg(line_to_angle(line), guard_angle_deg)
        if dist > best_dist:
            best_dist = dist
            best_line = line
    return best_line


static func get_line_alignment(attack_line: String, guard_line: String) -> float:
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        return CombatGuardLines.alignment_from_lines(
            CombatGuardLines.normalize_line(attack_line),
            CombatGuardLines.normalize_line(guard_line),
            PARRY_ALIGNMENT_FLOOR
        )
    var def_row: Variant = LINE_ANGLE_DEG.get(guard_line, {})
    if def_row is Dictionary:
        var deg: float = def_row.get(attack_line, 90)
        return maxf(PARRY_ALIGNMENT_FLOOR, cos(deg * PI / 180.0))
    return PARRY_ALIGNMENT_FLOOR


static func get_attack_angle_deg(
    attack_line: String, add_variance: bool = true, move_def: Dictionary = {}, variance_context: Dictionary = {}
) -> float:
    var base := line_to_angle(attack_line)
    var offset_range: float = move_def.get(DataKeys.MOVE_DEF_ANGLE_OFFSET_DEG, 0)
    if offset_range > 0:
        base += randf_range(-offset_range, offset_range)
    if add_variance:
        var variance: float = float(move_def.get(DataKeys.MOVE_DEF_ANGLE_VARIANCE_DEG, ANGLE_VARIANCE_DEG))
        var mult: float = 1.0
        var stamina_ratio: float = variance_context.get(DataKeys.VAR_CTX_STAMINA_RATIO, 1.0)
        if stamina_ratio < 1.0:
            var sf: float = CombatConstantsStamina.stamina_factor(stamina_ratio)
            mult = 1.0 + (ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT - 1.0) * (1.0 - sf)
        var ob_depth: float = float(variance_context.get(DataKeys.VAR_CTX_OFF_BALANCE, 0.0))
        if ob_depth > 0.0:
            mult *= lerpf(1.0, ANGLE_VARIANCE_OFF_BALANCE_MULT, ob_depth)
        var mass_kg: float = float(
            variance_context.get(DataKeys.VAR_CTX_WEAPON_MASS_KG, ANGLE_VARIANCE_MASS_REFERENCE_KG)
        )
        if mass_kg > 0 and ANGLE_VARIANCE_MASS_REFERENCE_KG > 0:
            var mass_mult: float = 1.0 + (mass_kg - ANGLE_VARIANCE_MASS_REFERENCE_KG) * ANGLE_VARIANCE_MASS_SCALE
            mult *= maxf(0.7, mass_mult)
        variance *= mult
        base += randf_range(-variance, variance)
    return fmod(base + 360.0, 360.0)


static func get_guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
    var line: String = combatant.get(DataKeys.ATTACK_GUARD_LINE, GUARD_DEFAULT)
    var blend: float = combatant.get(DataKeys.PA_GUARD_DEFLECT_BLEND, 0.0)
    var base_angle: float
    if blend <= 0.0:
        base_angle = line_to_angle(line)
    else:
        var from_line: String = combatant.get(DataKeys.PA_GUARD_DEFLECT_FROM_LINE, line)
        var from_a: float = line_to_angle(from_line)
        var to_a: float = line_to_angle(line)
        base_angle = lerpf(from_a, to_a, blend)
    var readiness: float = wobble_context.get(DataKeys.WOBBLE_CONTEXT_PARRY_READINESS, 1.0)
    if readiness < 1.0 and GUARD_WOBBLE_MAX_DEG > 0:
        var wobble: float = GUARD_WOBBLE_MAX_DEG * (1.0 - readiness * GUARD_WOBBLE_READINESS_SCALE)
        var mass_kg: float = float(
            wobble_context.get(DataKeys.WOBBLE_CONTEXT_DEFENDER_MASS_KG, GUARD_WOBBLE_MASS_REFERENCE_KG)
        )
        if mass_kg > 0 and GUARD_WOBBLE_MASS_REFERENCE_KG > 0:
            var mass_mult: float = 1.0 + (mass_kg - GUARD_WOBBLE_MASS_REFERENCE_KG) * GUARD_WOBBLE_MASS_SCALE
            wobble *= maxf(0.7, mass_mult)
        base_angle += randf_range(-wobble, wobble)
    return fmod(base_angle + 360.0, 360.0)


static func get_deflected_line_from_angles(
    attack_angle_deg: float, guard_angle_deg: float, severity: float, contact_type: String, alignment: float
) -> String:
    var atk_line: String = angle_to_nearest_line(attack_angle_deg)
    var guard_line: String = angle_to_nearest_line(guard_angle_deg)
    if atk_line == guard_line:
        return atk_line
    var opposite_line: String = (
        CombatGuardLines.opposite_line(atk_line)
        if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled()
        else str(DEFLECTED_GUARD_FROM_ATTACK.get(atk_line, atk_line))
    )
    if guard_line == opposite_line:
        var threshold: float = parry_opposite_deflect_severity_threshold(contact_type)
        if severity >= threshold:
            return opposite_line
        return _adjacent_line_away_from_guard(atk_line, guard_angle_deg)
    var mag := get_deflection_magnitude_deg(alignment, severity, contact_type)
    var deflected := get_deflected_angle_bilateral(attack_angle_deg, guard_angle_deg, mag)
    return angle_to_nearest_line(deflected)


static func get_line_alignment_with_deflect(
    attack_line: String, combatant: Dictionary, alignment_context: Dictionary = {}, wobble_context: Dictionary = {}
) -> float:
    var atk_a: Variant = alignment_context.get(DataKeys.ALIGNMENT_ATTACK_ANGLE_DEG, null)
    var guard_a: Variant = alignment_context.get(DataKeys.ALIGNMENT_GUARD_ANGLE_DEG, null)
    if atk_a is float and guard_a is float:
        return maxf(PARRY_ALIGNMENT_FLOOR, get_alignment_from_angles(float(atk_a), float(guard_a)))
    guard_a = get_guard_angle_deg(combatant, wobble_context)
    if atk_a is float:
        return maxf(PARRY_ALIGNMENT_FLOOR, get_alignment_from_angles(float(atk_a), float(guard_a)))
    var guard_line: String = combatant.get(DataKeys.ATTACK_GUARD_LINE, GUARD_DEFAULT)
    var blend: float = combatant.get(DataKeys.PA_GUARD_DEFLECT_BLEND, 0.0)
    if blend <= 0.0:
        return get_line_alignment(attack_line, guard_line)
    var from_line: String = combatant.get(DataKeys.PA_GUARD_DEFLECT_FROM_LINE, GUARD_DEFAULT)
    var align_from: float = get_line_alignment(attack_line, from_line)
    var align_to: float = get_line_alignment(attack_line, guard_line)
    return lerpf(align_from, align_to, blend)
