class_name CombatPairGeometry
extends RefCounted

## Pair reach geometry: file spacing, lane offset, ZoC mult → **`eff_dist`** / **`file_spacing_equiv`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")


static func effective_pair_geometry(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> Dictionary:
	var fa: Dictionary = _ZoneOfControl.formation_for_combatant_cached(manager, a, formation_a_cache)
	var fb: Dictionary = _ZoneOfControl.formation_for_combatant_cached(manager, b, formation_b_cache)
	var df: float = absf(float(_EntityAccess.file_int(a) - _EntityAccess.file_int(b)))
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
		return float(g.get("effective_pair_eff_dist", -1.0))
	if g.has("eff_dist"):
		return float(g.get("eff_dist", -1.0))
	return -1.0


static func melee_reach_covers_eff_dist(melee_range: float, eff_dist: float) -> bool:
	return melee_range >= eff_dist


static func effective_pair_file_spacing_equivalent(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> float:
	return float(
		effective_pair_geometry(manager, a, b, formation_a_cache, formation_b_cache).get(
			"file_spacing_equiv", 0.0
		)
	)


static func effective_pair_eff_dist(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> float:
	return cached_eff_dist(
		effective_pair_geometry(manager, a, b, formation_a_cache, formation_b_cache)
	)
