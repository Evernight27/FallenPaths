class_name CombatFormationEngagement
extends RefCounted

## Line cohesion (0..1) and engagement posture per formation. See docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md.

const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")
const _MoraleCohesion := preload("res://combat/CombatMoraleCohesion.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func recompute_all(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	_MoraleCohesion.apply_to_formations(manager)
	# Single engagement snapshot for fill + raw_mode (avoids repeating full combatant scans per formation).
	var snap: Dictionary = _EngagementMode.snapshot(manager)
	# Two-pass: both sides use the same tick’s cohesions for opponent-relative posture thresholds (Tier 1.4 asymmetric coupling).
	var coh_by_fid: Dictionary = {}
	for fid in ["player", "enemy"]:
		var form0: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if form0.is_empty():
			continue
		coh_by_fid[fid] = _compute_line_cohesion(manager, fid, form0, snap)
	for fid in ["player", "enemy"]:
		var form: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if form.is_empty():
			continue
		var coh: float = float(coh_by_fid.get(fid, 0.0))
		var opp_fid: String = _EntityAccess.opponent_side_label(fid)
		var opp_coh: float = float(coh_by_fid.get(opp_fid, coh))
		var posture: String = _compute_posture(manager, fid, coh, form, opp_coh, snap)
		var prev_c: float = float(form.get("line_cohesion", -1.0))
		var prev_p: String = str(form.get("engagement_posture", ""))
		form["line_cohesion"] = coh
		form["engagement_posture"] = posture
		var changed: bool = absf(prev_c - coh) > 0.004 or prev_p != posture
		if changed:
			_EntityAccess.manager_notify_engagement_state_changed(manager, fid, coh, posture)

	_CombatDoctrine.evaluate_automatic_doctrine(manager)


static func _avg_numeric_values_clamped_0_1(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var s: float = 0.0
	for v in values:
		s += clampf(float(v), 0.0, 1.0)
	return s / float(values.size())


static func _avg_breach_severity(form: Dictionary) -> float:
	var bf: Dictionary = _FormationSlots.formation_nested_dictionary_read(form, "breached_files")
	return _avg_numeric_values_clamped_0_1(bf.values())


static func _avg_wedge_pressure(form: Dictionary) -> float:
	var byf: Dictionary = _FormationSlots.formation_nested_dictionary_read(form, "intrusion_wedge_by_file")
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
	var byf: Dictionary = _FormationSlots.formation_nested_dictionary_read(form, "intrusion_wedge_by_file")
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


static func _compute_line_cohesion(
	manager: Node, fid: String, form: Dictionary, snap: Dictionary
) -> float:
	var front_fill: float = 0.0
	if fid == "player":
		front_fill = float(snap.get("player_front_fill", 0.0))
	elif fid == "enemy":
		front_fill = float(snap.get("enemy_front_fill", 0.0))
	else:
		var n_front: int = _FormationBreachRules.count_front_rank_alive(manager, fid)
		var files: int = maxi(1, int(form.get("files", 1)))
		front_fill = clampf(float(n_front) / float(files), 0.0, 1.0)
	var breach_avg: float = _avg_breach_severity(form)
	var wedge_avg: float = maxf(_avg_wedge_pressure(form), _avg_wedge_depth(form))
	var breach_eff: float = maxf(breach_avg, wedge_avg)
	var morale: float = clampf(
		float(form.get("morale_cohesion_factor", 1.0)),
		CombatConstants.MORALE_COHESION_FACTOR_MIN,
		1.0
	)
	var raw: float = (
		(CombatConstants.COHESION_BASE_FLOOR + CombatConstants.COHESION_FILL_SCALE * front_fill)
		* (1.0 - CombatConstants.COHESION_BREACH_WEIGHT * breach_eff)
		* morale
	)
	return clampf(raw, 0.0, 1.0)


## Resolved `line_discipline` for this formation: preset field wins; else encounter `ENCOUNTER_KEY_LINE_DISCIPLINE`.
static func effective_line_discipline(manager: Node, form: Dictionary) -> String:
	var disc_enc: String = ""
	if manager != null:
		var enc: Variant = manager.get("encounter")
		if enc != null and typeof(enc) == TYPE_DICTIONARY:
			disc_enc = str((enc as Dictionary).get(CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE, "")).strip_edges().to_lower()
	var disc_form: String = str(form.get("line_discipline", "")).strip_edges().to_lower()
	return disc_form if not disc_form.is_empty() else disc_enc


static func _posture_asymmetry_couple_strength(manager: Node) -> float:
	var base: float = float(CombatConstants.POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH)
	if manager == null:
		return base
	var enc: Variant = manager.get("encounter")
	if enc != null and typeof(enc) == TYPE_DICTIONARY:
		var ed: Dictionary = enc as Dictionary
		if ed.has(CombatConstants.ENCOUNTER_KEY_POSTURE_ASYMMETRY_STRENGTH):
			return float(ed[CombatConstants.ENCOUNTER_KEY_POSTURE_ASYMMETRY_STRENGTH])
	return base


static func _effective_posture_thresholds(
	manager: Node, form: Dictionary, our_coh: float = NAN, opp_coh: float = NAN
) -> Vector2:
	var l_in: float = CombatConstants.LINE_COHESION_POSTURE_ENTER_LINE_MIN
	var l_out: float = CombatConstants.LINE_COHESION_POSTURE_LEAVE_LINE_BELOW
	if manager != null:
		var enc: Variant = manager.get("encounter")
		if enc != null and typeof(enc) == TYPE_DICTIONARY:
			var ed: Dictionary = enc as Dictionary
			l_in += float(ed.get(CombatConstants.ENCOUNTER_KEY_POSTURE_ENTER_DELTA, 0.0))
			l_out += float(ed.get(CombatConstants.ENCOUNTER_KEY_POSTURE_LEAVE_DELTA, 0.0))
	l_in += float(form.get("discipline_posture_enter_delta", 0.0))
	l_out += float(form.get("discipline_posture_leave_delta", 0.0))
	var disc_pick: String = effective_line_discipline(manager, form)
	var disc_xy: Vector2 = CombatConstants.line_discipline_posture_extra_deltas(disc_pick)
	l_in += disc_xy.x
	l_out += disc_xy.y
	var k: float = _posture_asymmetry_couple_strength(manager)
	if k > 0.0001 and not is_nan(our_coh) and not is_nan(opp_coh):
		var delta: float = k * (our_coh - opp_coh)
		l_in -= delta
		l_out += delta
	l_in = clampf(l_in, 0.40, 0.92)
	l_out = clampf(l_out, 0.28, 0.88)
	if l_in <= l_out + 0.03:
		l_out = maxf(0.25, l_in - 0.05)
	return Vector2(l_in, l_out)


static func _compute_posture(
	manager: Node, _fid: String, cohesion: float, form: Dictionary, opp_coh: float, snap: Dictionary
) -> String:
	var mode_now: String = str(snap.get("raw_mode", "skirmish"))
	if mode_now == "duel":
		return CombatConstants.ENGAGEMENT_POSTURE_DUEL
	var prev: String = str(form.get("engagement_posture", ""))
	var thr: Vector2 = _effective_posture_thresholds(manager, form, cohesion, opp_coh)
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


