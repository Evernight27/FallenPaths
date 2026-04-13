class_name CombatIntrusionWedge
extends RefCounted

## Formation-scoped intrusion wedge: canonical breach corridor per file (see docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md §4.1).

const FIELD_PRESSURE := "pressure"
const FIELD_DEPTH := "depth"
const FIELD_INTRUDER_ID := "intruder_id"


static func _wedge_map(formation: Dictionary) -> Dictionary:
	if not formation.has("intrusion_wedge_by_file"):
		formation["intrusion_wedge_by_file"] = {}
	return formation["intrusion_wedge_by_file"]


static func upsert_from_intrusion(
	formation: Dictionary,
	anchor_file: int,
	intruder_id: int,
	breach_severity: float,
	penetration_depth: int,
	penetration_max: int
) -> void:
	var byf: Dictionary = _wedge_map(formation)
	var pres: float = clampf(breach_severity, 0.0, 1.0)
	var dep: float = clampf(float(penetration_depth) / float(maxi(1, penetration_max)), 0.0, 1.0)
	byf[anchor_file] = {
		FIELD_PRESSURE: pres,
		FIELD_DEPTH: dep,
		FIELD_INTRUDER_ID: intruder_id,
	}


static func pressure_at_file(formation: Dictionary, file: int) -> float:
	var byf: Dictionary = formation.get("intrusion_wedge_by_file", {})
	if byf.is_empty():
		return 0.0
	var w: Variant = byf.get(file, byf.get(str(file), null))
	if w == null or typeof(w) != TYPE_DICTIONARY:
		return 0.0
	return clampf(float((w as Dictionary).get(FIELD_PRESSURE, 0.0)), 0.0, 1.0)


static func depth_at_file(formation: Dictionary, file: int) -> float:
	var byf: Dictionary = formation.get("intrusion_wedge_by_file", {})
	var w: Variant = byf.get(file, byf.get(str(file), null))
	if w == null or typeof(w) != TYPE_DICTIONARY:
		return 0.0
	return clampf(float((w as Dictionary).get(FIELD_DEPTH, 0.0)), 0.0, 1.0)


## Lane stress addend 0..cap from wedge pressure at this file (use max with breach_local_lane_stress_bonus to avoid double-counting severity).
static func lane_stress_bonus_from_wedge(formation: Dictionary, file_index: int) -> float:
	var p: float = pressure_at_file(formation, file_index)
	if p <= 0.0001:
		return 0.0
	var add: float = p * CombatConstants.LANE_STRESS_WEDGE_SCALE
	return minf(add, CombatConstants.LANE_STRESS_WEDGE_BONUS_MAX)


static func remove_intruder_from_all_wedges(manager: Node, intruder_id: int) -> void:
	if manager == null or intruder_id < 0 or not manager.get("formations"):
		return
	var fm: Dictionary = manager.formations
	for fid in fm.keys():
		var form: Dictionary = fm[fid]
		if form.is_empty():
			continue
		var byf: Dictionary = form.get("intrusion_wedge_by_file", {})
		if byf.is_empty():
			continue
		var to_erase: Array = []
		for k in byf.keys():
			var w: Variant = byf[k]
			if typeof(w) != TYPE_DICTIONARY:
				continue
			if int((w as Dictionary).get(FIELD_INTRUDER_ID, -999)) == intruder_id:
				to_erase.append(k)
		for k in to_erase:
			byf.erase(k)


static func clear_all_wedges_in_formation(formation: Dictionary) -> void:
	formation["intrusion_wedge_by_file"] = {}
