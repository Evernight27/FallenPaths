class_name CombatPairGeometry
extends RefCounted

## Pair reach geometry: file spacing, lane offset, ZoC mult |' **`eff_dist`** / **`file_spacing_equiv`**.
## Track A mapped rank-0 opposition uses logical file gap (not raw grid `|"file|`) so wings reach their assigned foe.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")


static func _file_spacing_for_pair(manager: Node, a: Dictionary, b: Dictionary) -> float:
    if manager != null:
        var band: String = _EntityAccess.distance_to_opponent_band(a, _EntityAccess.id_int(b))
        # CLOSE band = successful bind for this pair --" grid file gap no longer limits weapon reach.
        if band == CombatConstants.DISTANCE_CLOSE:
            return 0.0
    var df: float = absf(float(_EntityAccess.file_int(a) - _EntityAccess.file_int(b)))
    if manager == null:
        return df
    if CombatConstants.is_feature_gap_column_topology_enabled():
        if _EntityAccess.is_living_same_side(a, b):
            var form_same: Dictionary = _FormationSlots.formation_record_for_manager(manager, _EntityAccess.side_str(a))
            if not form_same.is_empty():
                df = _FormationSlots.column_graph_file_distance(
                    _EntityAccess.file_int(a), _EntityAccess.file_int(b), _FormationSlots.gap_column_files(form_same)
                )
        elif (
            _EntityAccess.rank_int(a) == 0
            and _EntityAccess.rank_int(b) == 0
            and _EntityAccess.is_living_hostile_to(a, b)
        ):
            var form_a: Dictionary = _FormationSlots.formation_record_for_manager(manager, _EntityAccess.side_str(a))
            var form_b: Dictionary = _FormationSlots.formation_record_for_manager(manager, _EntityAccess.side_str(b))
            if not form_a.is_empty() and not form_b.is_empty():
                var occ_a: PackedInt32Array = _FormationSlots.occupied_files_for_rank(manager, form_a, 0)
                var occ_b: PackedInt32Array = _FormationSlots.occupied_files_for_rank(manager, form_b, 0)
                if _FormationSlots.occupied_files_have_gaps(occ_a) or _FormationSlots.occupied_files_have_gaps(occ_b):
                    return _FormationSlots.column_arc_file_distance(
                        occ_a, _EntityAccess.file_int(a), occ_b, _EntityAccess.file_int(b)
                    )
        return df
    if (
        _EntityAccess.rank_int(a) == 0
        and _EntityAccess.rank_int(b) == 0
        and _EntityAccess.is_living_hostile_to(a, b)
        and _EngagementOpposition.is_mapped_file_opposed(manager, a, b)
    ):
        df = float(_EngagementOpposition.mapped_opposition_file_distance(manager, a, b))
    return df


static func effective_pair_geometry(
    manager: Node, a: Dictionary, b: Dictionary, formation_a_cache: Variant = null, formation_b_cache: Variant = null
) -> Dictionary:
    var fa: Dictionary = _ZoneOfControl.formation_for_combatant_cached(manager, a, formation_a_cache)
    var fb: Dictionary = _ZoneOfControl.formation_for_combatant_cached(manager, b, formation_b_cache)
    var df: float = _file_spacing_for_pair(manager, a, b)
    if fa.is_empty() or fb.is_empty():
        var eff_empty: float = df * CombatConstants.SPACING_NORMAL * CombatConstants.REACH_SAFETY_FACTOR
        return {"eff_dist": eff_empty, "file_spacing_equiv": df}
    var sa: float = CombatConstants.get_spacing_from_density(fa.get("density", "normal"))
    var sb: float = CombatConstants.get_spacing_from_density(fb.get("density", "normal"))
    var half_width: float = (sa + sb) * 0.5
    var base: float = df * half_width * CombatConstants.REACH_SAFETY_FACTOR
    var loa: float = _EntityAccess.lane_offset_float(a)
    var lob: float = _EntityAccess.lane_offset_float(b)
    var lateral_frac: float = absf(loa - lob)
    var lateral: float = (
        lateral_frac
        * CombatConstants.EFF_DIST_LANE_OFFSET_FILE_EQUIV
        * half_width
        * CombatConstants.REACH_SAFETY_FACTOR
    )
    var pre_zoc: float = maxf(0.04, base + lateral)
    var zoc_m: float = _ZoneOfControl.geometric_reach_extent_multiplier(manager, a, b, fa, fb)
    var eff_dist: float = pre_zoc * zoc_m
    var denom: float = half_width * CombatConstants.REACH_SAFETY_FACTOR * maxf(0.001, zoc_m)
    var file_spacing: float = eff_dist / denom if denom >= 1e-5 else df
    return {
        "eff_dist": eff_dist,
        "effective_pair_eff_dist": eff_dist,
        "file_spacing_equiv": file_spacing,
        "effective_pair_file_spacing_equivalent": file_spacing,
    }


## `effective_pair_geometry` dict or stamped `pa`; `-1` when cache missing.
static func cached_eff_dist(pair_geometry_cache: Variant) -> float:
    if pair_geometry_cache == null or not (pair_geometry_cache is Dictionary):
        return -1.0
    var g: Dictionary = pair_geometry_cache as Dictionary
    if g.has("effective_pair_eff_dist"):
        return g.get("effective_pair_eff_dist", -1.0)
    if g.has("eff_dist"):
        return g.get("eff_dist", -1.0)
    return -1.0


static func melee_reach_covers_eff_dist(melee_range: float, eff_dist: float) -> bool:
    return melee_range >= eff_dist


static func effective_pair_file_spacing_equivalent(
    manager: Node, a: Dictionary, b: Dictionary, formation_a_cache: Variant = null, formation_b_cache: Variant = null
) -> float:
    return float(
        effective_pair_geometry(manager, a, b, formation_a_cache, formation_b_cache).get("file_spacing_equiv", 0.0)
    )


static func effective_pair_eff_dist(
    manager: Node, a: Dictionary, b: Dictionary, formation_a_cache: Variant = null, formation_b_cache: Variant = null
) -> float:
    return cached_eff_dist(effective_pair_geometry(manager, a, b, formation_a_cache, formation_b_cache))
