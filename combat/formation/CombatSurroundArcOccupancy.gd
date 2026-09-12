class_name CombatSurroundArcOccupancy
extends RefCounted

## Front-arc occupancy for surround: limits full-weight threats by blade arc overlap.
## See **`docs/LIVE_PATHS.md`** (D-005 surround).


static func arc_half_width_deg() -> float:
    return CombatConstants.SURROUND_ARC_HALF_WIDTH_DEG


static func arc_center_deg_from_pa(pa: Dictionary) -> float:
    var end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
    if end >= -900.0:
        return fmod(end + 360.0, 360.0)
    var intended: float = pa.get(DataKeys.PA_ARC_INTENDED_DEG, pa.get(DataKeys.ATTACK_ARC_START_DEG, 0.0))
    return fmod(intended + 360.0, 360.0)


static func arcs_overlap(center_a: float, center_b: float, half_w: float) -> bool:
    var d: float = CombatGuardLines.angle_diff_deg(center_a, center_b)
    return d < half_w * 2.0 - CombatConstants.SURROUND_ARC_OVERLAP_TOLERANCE_DEG


## Each entry: `{ "weight": float, "arc_center_deg": float }`. Returns **`weight_sum`** + **`arc_occupancy_blocked`**
## (overlap demotions).
static func surround_load_from_threat_entries(entries: Array) -> Dictionary:
    var out: Dictionary = {"weight_sum": 0.0, "arc_occupancy_blocked": 0}
    if entries.is_empty():
        return out
    if not CombatConstants.is_feature_surround_arc_occupancy_enabled():
        var plain: float = 0.0
        for e in entries:
            plain += (e as Dictionary).get(DataKeys.ACTION_WEIGHT, 0.0)
        out[DataKeys.ARC_OCCUPANCY_WEIGHT_SUM] = plain
        return out
    var sorted: Array = entries.duplicate()
    sorted.sort_custom(func(a, b): return a.get(DataKeys.ACTION_WEIGHT, 0.0) > b.get(DataKeys.ACTION_WEIGHT, 0.0))
    var half_w: float = arc_half_width_deg()
    var claimed: Array = []
    var total: float = 0.0
    var blocked_n: int = 0
    for raw in sorted:
        var e: Dictionary = raw as Dictionary
        var w: float = e.get(DataKeys.ACTION_WEIGHT, 0.0)
        var center: float = e.get(DataKeys.THREAT_ARC_CENTER_DEG, 0.0)
        var blocked: bool = false
        for c in claimed:
            if arcs_overlap(center, float(c), half_w):
                blocked = true
                break
        if blocked:
            blocked_n += 1
            total += w * CombatConstants.SURROUND_ARC_BLOCKED_THREAT_WEIGHT_MULT
        else:
            claimed.append(center)
            total += w
    out[DataKeys.ARC_OCCUPANCY_WEIGHT_SUM] = total
    out[DataKeys.SURROUND_THREAT_WEIGHT_SUM] = total
    out[DataKeys.ARC_OCCUPANCY_BLOCKED] = blocked_n
    return out



