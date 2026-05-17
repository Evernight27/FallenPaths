class_name CombatPairGeometry
extends RefCounted

## Pair reach geometry: file spacing, lane offset, wedge pull, ZoC mult → **`eff_dist`** / **`file_spacing_equiv`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")


static func _wedge_distance_pull(manager: Node, a: Dictionary, b: Dictionary, half_width_spacing: float) -> float:
	var form: Dictionary = {}
	var anchor_f: int = -1
	if _ZoneOfControl.is_intruded(a):
		var hf_a: String = _ZoneOfControl.intrusion_host_fid(a)
		if hf_a.is_empty():
			return 0.0
		form = _ZoneOfControl.formation_dict_for_zone_geometry(manager, a, hf_a)
		anchor_f = _EntityAccess.intrusion_anchor_file_raw_int(a)
	elif _ZoneOfControl.is_intruded(b):
		var hf_b: String = _ZoneOfControl.intrusion_host_fid(b)
		if hf_b.is_empty():
			return 0.0
		form = _ZoneOfControl.formation_dict_for_zone_geometry(manager, b, hf_b)
		anchor_f = _EntityAccess.intrusion_anchor_file_raw_int(b)
	if form.is_empty() or anchor_f < 0:
		return 0.0
	var p: float = _IntrusionWedge.pressure_at_file(form, anchor_f)
	var dep: float = _IntrusionWedge.depth_at_file(form, anchor_f)
	if p <= 0.0001 and dep <= 0.0001:
		return 0.0
	return p * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_PRESSURE_PULL \
		+ dep * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_DEPTH_PULL


static func wedge_pressure_depth_at_combatant_column(manager: Node, c: Dictionary) -> Vector2:
	if _ZoneOfControl.is_intruded(c):
		var hf_i: String = _ZoneOfControl.intrusion_host_fid(c)
		if hf_i.is_empty():
			return Vector2.ZERO
		var form_i: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, hf_i)
		if form_i.is_empty():
			return Vector2.ZERO
		var fi_i: int = _EntityAccess.intrusion_anchor_or_file_int(c)
		return Vector2(_IntrusionWedge.pressure_at_file(form_i, fi_i), _IntrusionWedge.depth_at_file(form_i, fi_i))
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
	var form: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid)
	if form.is_empty():
		return Vector2.ZERO
	var fi: int = _EntityAccess.file_int(c)
	return Vector2(_IntrusionWedge.pressure_at_file(form, fi), _IntrusionWedge.depth_at_file(form, fi))


static func _wedge_bystander_corridor_pull(manager: Node, a: Dictionary, b: Dictionary, half_width_spacing: float) -> float:
	var va: Vector2 = wedge_pressure_depth_at_combatant_column(manager, a)
	var vb: Vector2 = wedge_pressure_depth_at_combatant_column(manager, b)
	var p: float = maxf(va.x, vb.x)
	var dep: float = maxf(va.y, vb.y)
	if p <= 0.0001 and dep <= 0.0001:
		return 0.0
	var m: float = CombatConstants.EFF_DIST_WEDGE_BYSTANDER_MULT
	return p * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_PRESSURE_PULL * m \
		+ dep * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_DEPTH_PULL * m


static func effective_pair_geometry(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> Dictionary:
	var fa: Dictionary = (
		(formation_a_cache as Dictionary)
		if formation_a_cache != null and formation_a_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, a)
	)
	var fb: Dictionary = (
		(formation_b_cache as Dictionary)
		if formation_b_cache != null and formation_b_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, b)
	)
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
	var wedge_pull: float = maxf(
		_wedge_distance_pull(manager, a, b, half_width),
		_wedge_bystander_corridor_pull(manager, a, b, half_width)
	)
	var pre_zoc: float = maxf(0.04, base + lateral - wedge_pull)
	var zoc_m: float = _ZoneOfControl.geometric_reach_extent_multiplier(manager, a, b, fa, fb)
	var eff_dist: float = pre_zoc * zoc_m
	var denom: float = half_width * CombatConstants.REACH_SAFETY_FACTOR * maxf(0.001, zoc_m)
	var file_spacing: float = eff_dist / denom if denom >= 1e-5 else df
	return {"eff_dist": eff_dist, "file_spacing_equiv": file_spacing}


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
	return float(
		effective_pair_geometry(manager, a, b, formation_a_cache, formation_b_cache).get("eff_dist", 0.0)
	)
