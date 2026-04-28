class_name CombatFormationEngagement
extends RefCounted

## Line cohesion (0..1) and engagement posture per formation. See docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md.

const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")


static func recompute_all(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	var fm: Dictionary = manager.formations
	for fid in ["player", "enemy"]:
		var form: Dictionary = fm.get(fid, {})
		if form.is_empty():
			continue
		var coh: float = _compute_line_cohesion(manager, fid, form)
		var posture: String = _compute_posture(manager, fid, coh, form)
		var prev_c: float = float(form.get("line_cohesion", -1.0))
		var prev_p: String = str(form.get("engagement_posture", ""))
		form["line_cohesion"] = coh
		form["engagement_posture"] = posture
		var changed: bool = absf(prev_c - coh) > 0.004 or prev_p != posture
		if changed and manager.has_method("notify_engagement_state_changed"):
			manager.notify_engagement_state_changed(fid, coh, posture)


static func _avg_numeric_values_clamped_0_1(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var s: float = 0.0
	for v in values:
		s += clampf(float(v), 0.0, 1.0)
	return s / float(values.size())


static func _avg_breach_severity(form: Dictionary) -> float:
	var bf: Dictionary = form.get("breached_files", {})
	return _avg_numeric_values_clamped_0_1(bf.values())


static func _avg_wedge_pressure(form: Dictionary) -> float:
	var byf: Dictionary = form.get("intrusion_wedge_by_file", {})
	if byf.is_empty():
		return 0.0
	var s: float = 0.0
	var n: int = 0
	for w in byf.values():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		s += clampf(float((w as Dictionary).get(_IntrusionWedge.FIELD_PRESSURE, 0.0)), 0.0, 1.0)
		n += 1
	return s / float(maxi(1, n))


static func _avg_wedge_depth(form: Dictionary) -> float:
	var byf: Dictionary = form.get("intrusion_wedge_by_file", {})
	if byf.is_empty():
		return 0.0
	var s: float = 0.0
	var n: int = 0
	for w in byf.values():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		s += clampf(float((w as Dictionary).get(_IntrusionWedge.FIELD_DEPTH, 0.0)), 0.0, 1.0)
		n += 1
	return s / float(maxi(1, n))


static func _compute_line_cohesion(manager: Node, fid: String, form: Dictionary) -> float:
	var n_front: int = _FormationBreachRules.count_front_rank_alive(manager, fid)
	var files: int = maxi(1, int(form.get("files", 1)))
	var front_fill: float = clampf(float(n_front) / float(files), 0.0, 1.0)
	var breach_avg: float = _avg_breach_severity(form)
	var wedge_avg: float = maxf(_avg_wedge_pressure(form), _avg_wedge_depth(form))
	var breach_eff: float = maxf(breach_avg, wedge_avg)
	var morale: float = clampf(float(form.get("morale_cohesion_factor", 1.0)), 0.15, 1.0)
	var raw: float = (
		(CombatConstants.COHESION_BASE_FLOOR + CombatConstants.COHESION_FILL_SCALE * front_fill)
		* (1.0 - CombatConstants.COHESION_BREACH_WEIGHT * breach_eff)
		* morale
	)
	return clampf(raw, 0.0, 1.0)


static func _effective_posture_thresholds(manager: Node, form: Dictionary) -> Vector2:
	var l_in: float = CombatConstants.LINE_COHESION_POSTURE_ENTER_LINE_MIN
	var l_out: float = CombatConstants.LINE_COHESION_POSTURE_LEAVE_LINE_BELOW
	var disc_enc: String = ""
	if manager != null:
		var enc: Variant = manager.get("encounter")
		if enc != null and typeof(enc) == TYPE_DICTIONARY:
			var ed: Dictionary = enc as Dictionary
			l_in += float(ed.get(CombatConstants.ENCOUNTER_KEY_POSTURE_ENTER_DELTA, 0.0))
			l_out += float(ed.get(CombatConstants.ENCOUNTER_KEY_POSTURE_LEAVE_DELTA, 0.0))
			disc_enc = str(ed.get(CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE, "")).strip_edges().to_lower()
	l_in += float(form.get("discipline_posture_enter_delta", 0.0))
	l_out += float(form.get("discipline_posture_leave_delta", 0.0))
	var disc_form: String = str(form.get("line_discipline", "")).strip_edges().to_lower()
	var disc_pick: String = disc_form if not disc_form.is_empty() else disc_enc
	var disc_xy: Vector2 = CombatConstants.line_discipline_posture_extra_deltas(disc_pick)
	l_in += disc_xy.x
	l_out += disc_xy.y
	l_in = clampf(l_in, 0.40, 0.92)
	l_out = clampf(l_out, 0.28, 0.88)
	if l_in <= l_out + 0.03:
		l_out = maxf(0.25, l_in - 0.05)
	return Vector2(l_in, l_out)


static func _compute_posture(manager: Node, _fid: String, cohesion: float, form: Dictionary) -> String:
	var p: int = _FormationBreachRules.count_front_rank_alive(manager, "player")
	var e: int = _FormationBreachRules.count_front_rank_alive(manager, "enemy")
	if p >= 1 and e >= 1 and p <= 1 and e <= 1:
		return CombatConstants.ENGAGEMENT_POSTURE_DUEL
	var prev: String = str(form.get("engagement_posture", ""))
	var thr: Vector2 = _effective_posture_thresholds(manager, form)
	var l_in: float = thr.x
	var l_out: float = thr.y
	if prev.is_empty() or prev == CombatConstants.ENGAGEMENT_POSTURE_DUEL:
		if cohesion >= l_in:
			return CombatConstants.ENGAGEMENT_POSTURE_LINE
		return CombatConstants.ENGAGEMENT_POSTURE_OPEN
	if prev == CombatConstants.ENGAGEMENT_POSTURE_LINE:
		if cohesion < l_out:
			return CombatConstants.ENGAGEMENT_POSTURE_OPEN
		return CombatConstants.ENGAGEMENT_POSTURE_LINE
	if cohesion >= l_in:
		return CombatConstants.ENGAGEMENT_POSTURE_LINE
	return CombatConstants.ENGAGEMENT_POSTURE_OPEN
