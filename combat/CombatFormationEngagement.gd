class_name CombatFormationEngagement
extends RefCounted

## Line cohesion (0..1) and engagement posture per formation. See docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md.

const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")


static func recompute_all(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	var fm: Dictionary = manager.formations
	for fid in ["player", "enemy"]:
		var form: Dictionary = fm.get(fid, {})
		if form.is_empty():
			continue
		var coh: float = _compute_line_cohesion(manager, fid, form)
		var posture: String = _compute_posture(manager, fid, coh)
		var prev_c: float = float(form.get("line_cohesion", -1.0))
		var prev_p: String = str(form.get("engagement_posture", ""))
		form["line_cohesion"] = coh
		form["engagement_posture"] = posture
		var changed: bool = absf(prev_c - coh) > 0.004 or prev_p != posture
		if changed and manager.has_method("notify_engagement_state_changed"):
			manager.notify_engagement_state_changed(fid, coh, posture)


static func _avg_breach_severity(form: Dictionary) -> float:
	var bf: Dictionary = form.get("breached_files", {})
	if bf.is_empty():
		return 0.0
	var s: float = 0.0
	var n: int = 0
	for v in bf.values():
		s += clampf(float(v), 0.0, 1.0)
		n += 1
	return s / float(maxi(1, n))


static func _compute_line_cohesion(manager: Node, fid: String, form: Dictionary) -> float:
	var n_front: int = _FormationBreachRules.count_front_rank_alive(manager, fid)
	var files: int = maxi(1, int(form.get("files", 1)))
	var front_fill: float = clampf(float(n_front) / float(files), 0.0, 1.0)
	var breach_avg: float = _avg_breach_severity(form)
	var morale: float = clampf(float(form.get("morale_cohesion_factor", 1.0)), 0.15, 1.0)
	var raw: float = (
		(CombatConstants.COHESION_BASE_FLOOR + CombatConstants.COHESION_FILL_SCALE * front_fill)
		* (1.0 - CombatConstants.COHESION_BREACH_WEIGHT * breach_avg)
		* morale
	)
	return clampf(raw, 0.0, 1.0)


static func _compute_posture(manager: Node, _fid: String, cohesion: float) -> String:
	var p: int = _FormationBreachRules.count_front_rank_alive(manager, "player")
	var e: int = _FormationBreachRules.count_front_rank_alive(manager, "enemy")
	if p >= 1 and e >= 1 and p <= 1 and e <= 1:
		return CombatConstants.ENGAGEMENT_POSTURE_DUEL
	if cohesion >= CombatConstants.LINE_COHESION_POSTURE_LINE_MIN:
		return CombatConstants.ENGAGEMENT_POSTURE_LINE
	return CombatConstants.ENGAGEMENT_POSTURE_OPEN
