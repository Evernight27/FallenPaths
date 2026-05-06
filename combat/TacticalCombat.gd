class_name TacticalCombat
extends RefCounted

## Phase 6: Ambush penalties, surround (multi-threat defense split + perception), incursion pressure for ZoC.
## See docs/COMBAT_ROADMAP_AND_STAMINA.md Phase 6; formations/ambush — docs/TACTICAL_FORMATIONS_FF4.md.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")

## Tier 1.8 (P9): counters on the combat manager for soak / debug (mode transitions, illegal crash resolves).
const META_COMBAT_TELEMETRY := "_combat_telemetry"

static func _mode_code(mode_name: String) -> int:
	if mode_name == CombatConstants.ENGAGEMENT_MODE_FORMATION:
		return int(CombatConstants.ENGAGEMENT_MODE_CODE_FORMATION)
	if mode_name == CombatConstants.ENGAGEMENT_MODE_DUEL:
		return int(CombatConstants.ENGAGEMENT_MODE_CODE_DUEL)
	return int(CombatConstants.ENGAGEMENT_MODE_CODE_SKIRMISH)

## Enemy front-rank units that could actually land a melee strike on the defender (weapon reach + spacing + band).
## Not merely “MID distance” from formation geometry — matches AvailableActionsBuilder.can_melee_threaten.
static func count_engaging_threats(manager: Node, defender_id: int) -> int:
	var d: Dictionary = manager._get_by_id(defender_id) if manager.has_method("_get_by_id") else {}
	if d.is_empty() or not d.get("alive", false):
		return 0
	var n: int = 0
	for c in manager.combatants:
		if not c.get("alive", false) or c.get("side", "") == d.get("side", ""):
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		if _ActionsBuilder.can_melee_threaten(manager, c, d):
			n += 1
	return n

## Parry/dodge multiplier from surround + awareness (perception). Only meaningful when threats > 1.
static func surround_defense_multiplier(defender: Dictionary, num_engaging_threats: int) -> float:
	if num_engaging_threats <= 1:
		return 1.0
	var div: int = mini(num_engaging_threats, CombatConstants.SURROUND_MAX_SPLIT_DIVISOR)
	var split: float = 1.0 / float(div)
	var perc_norm: float = clampf(float(defender.stats.get("perception", 100)) / 100.0, 0.0, 1.0)
	var awareness: float = lerpf(CombatConstants.SURROUND_AWARENESS_AT_LOW_PERCEPTION, 1.0, perc_norm)
	return split * awareness

## Ambush: defender side suffers worse parry/dodge. Returns 1.0 if no ambush or defender is not ambushed.
static func ambush_defense_multiplier(manager: Node, defender: Dictionary) -> float:
	if manager == null or defender.is_empty():
		return 1.0
	var enc: Variant = manager.get("encounter")
	if enc == null or typeof(enc) != TYPE_DICTIONARY:
		return 1.0
	var e: Dictionary = enc
	var at: String = str(e.get("ambush_type", CombatConstants.AMBUSH_TYPE_NONE))
	if at == CombatConstants.AMBUSH_TYPE_NONE or at.is_empty():
		return 1.0
	var ambushed: String = str(e.get(CombatConstants.ENCOUNTER_AMBUSHED_SIDE, "player"))
	if defender.get("side", "") != ambushed:
		return 1.0
	var p: float = float(e.get("ambush_penalty", 0.25))
	p = clampf(p, 0.0, 0.85)
	if at == CombatConstants.AMBUSH_TYPE_PARTIAL:
		p *= 0.5
	return 1.0 - p

## Global incursion 0..INCURSION_PRESSURE_MAX from front-rank imbalance; lane_stress_by_file from dual occupancy + density (not bodies — those are obs_pen in ZoC).
static func recompute_incursion_pressure(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	var snap: Dictionary = _EngagementMode.snapshot(manager)
	var p_front: int = int(snap.get("player_front", 0))
	var e_front: int = int(snap.get("enemy_front", 0))
	var mode_now: String = _EngagementMode.engagement_mode(manager)
	var mode_now_code: int = _mode_code(mode_now)
	var raw_mode: String = str(snap.get("raw_mode", "skirmish"))
	var incursion_ok: bool = _EngagementMode.incursion_allowed(manager)
	_telemetry_after_mode_resolve(manager, mode_now)
	if manager != null:
		var mode_snap: Dictionary = snap.duplicate()
		mode_snap["mode"] = mode_now
		mode_snap["mode_code"] = mode_now_code
		mode_snap["incursion_allowed"] = incursion_ok
		mode_snap["combat_clock"] = float(manager.get("combat_clock"))
		if manager.has_meta(META_COMBAT_TELEMETRY):
			mode_snap["telemetry"] = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
		manager.set_meta("_tactical_mode_snapshot", mode_snap)
	var mode_line: String = (
		"mode=%s(%d) raw=%s(%d) incursion_allowed=%s active[player=%d enemy=%d] front[player=%d enemy=%d] fill[player=%.2f enemy=%.2f]"
		% [
			mode_now,
			mode_now_code,
			raw_mode,
			int(snap.get("raw_mode_code", _mode_code(raw_mode))),
			incursion_ok,
			int(snap.get("player_active", 0)),
			int(snap.get("enemy_active", 0)),
			p_front,
			e_front,
			float(snap.get("player_front_fill", 0.0)),
			float(snap.get("enemy_front_fill", 0.0)),
		]
	)
	for fid in ["player", "enemy"]:
		var formation: Dictionary = manager.formations.get(fid, {})
		if formation.is_empty():
			continue
		var our_front: int = p_front if fid == "player" else e_front
		var opp_front: int = e_front if fid == "player" else p_front
		var delta: int = opp_front - our_front
		var pressure: float = clampf(float(delta) * CombatConstants.INCURSION_PRESSURE_PER_RANK_ADVANTAGE, 0.0, CombatConstants.INCURSION_PRESSURE_MAX)
		formation["incursion_pressure"] = pressure
		_recompute_lane_stress_by_file(manager, formation)
		if CombatDebug.flow_verbose_enabled():
			var bf: Dictionary = formation.get("breached_files", {})
			var raw_clog: bool = _FormationBreachRules.breach_clogs_open_lanes(formation)
			var blocks_moves: bool = _FormationBreachRules.breach_blocks_open_lane_moves(manager, formation)
			var skirm: bool = _FormationBreachRules.is_skirmish_line_engagement(manager)
			CombatDebug.flow_log(
				(
					"incursion_snapshot fid=%s pressure=%.3f lane_stress[%s] breached[%s] "
					+ "breach_raw_clogs=%s breach_blocks_moves=%s skirmish=%s mode_state[%s] front_alive=%d intruders[%s]"
				)
				% [
					fid,
					float(formation.get("incursion_pressure", 0.0)),
					CombatDebug.format_lane_stress(formation.get("lane_stress_by_file", {})),
					CombatDebug.format_breached_files(bf),
					raw_clog,
					blocks_moves,
					skirm,
					mode_line,
					our_front,
					_format_intruders_on_host(manager, fid, int(formation.get("files", 1)))
				],
				"incursion_snapshot:%s" % fid
			)


static func _recompute_lane_stress_by_file(manager: Node, formation: Dictionary) -> void:
	var files: int = maxi(1, formation.get("files", 1))
	var ranks: int = maxi(1, formation.get("ranks", 1))
	var slots: Dictionary = formation.get("slots", {})
	var density: String = str(formation.get("density", "normal"))
	var by_file: Dictionary = {}
	for f in range(files):
		var has_dual: bool = false
		for r in range(ranks):
			if _FormationSlots.living_count_in_slot(manager, slots, Vector2i(r, f)) >= 2:
				has_dual = true
				break
		var stress: float = 0.0
		if has_dual:
			stress += CombatConstants.LANE_STRESS_DUAL_LIVING
		match density:
			"tight":
				stress += CombatConstants.LANE_STRESS_DENSITY_TIGHT
			"loose":
				stress += CombatConstants.LANE_STRESS_DENSITY_LOOSE
		var breach_b: float = _FormationBreachRules.breach_local_lane_stress_bonus(formation, f)
		var wedge_b: float = _IntrusionWedge.lane_stress_bonus_from_wedge(formation, f)
		stress += maxf(breach_b, wedge_b)
		by_file[f] = clampf(stress, 0.0, 1.0)
	formation["lane_stress_by_file"] = by_file


static func _format_intruders_on_host(manager: Node, host_fid: String, files: int) -> String:
	if manager == null:
		return "—"
	var by_file: Dictionary = {}
	for c in manager.combatants:
		if not c.get("alive", false):
			continue
		if str(c.get("engagement_role", "")) != CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			continue
		if str(c.get("intrusion_host_fid", "")) != host_fid:
			continue
		var file_i: int = int(c.get("intrusion_anchor_file", c.get("file", 0)))
		if file_i < 0 or file_i >= maxi(1, files):
			continue
		if not by_file.has(file_i):
			by_file[file_i] = 0
		by_file[file_i] = int(by_file[file_i]) + 1
	if by_file.is_empty():
		return "—"
	var parts: Array[String] = []
	for fi in range(maxi(1, files)):
		var n: int = int(by_file.get(fi, 0))
		if n > 0:
			parts.append("f%d:%d" % [fi, n])
	return "; ".join(parts)


static func _telemetry_after_mode_resolve(manager: Node, mode_now: String) -> void:
	if manager == null:
		return
	var tel: Dictionary
	if manager.has_meta(META_COMBAT_TELEMETRY):
		tel = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
	else:
		tel = {
			"engagement_mode_transitions": 0,
			"invalid_crash_resolve_blocked": 0,
			"last_resolved_mode": "",
			"last_mode_transition": {},
		}
	var prev: String = str(tel.get("last_resolved_mode", ""))
	if prev != "" and prev != mode_now:
		tel["engagement_mode_transitions"] = int(tel.get("engagement_mode_transitions", 0)) + 1
		tel["last_mode_transition"] = {
			"from": prev,
			"to": mode_now,
			"at": float(manager.combat_clock),
		}
	tel["last_resolved_mode"] = mode_now
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


static func record_invalid_crash_resolve_blocked(manager: Node) -> void:
	if manager == null:
		return
	var tel: Dictionary
	if manager.has_meta(META_COMBAT_TELEMETRY):
		tel = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
	else:
		tel = {
			"engagement_mode_transitions": 0,
			"invalid_crash_resolve_blocked": 0,
			"last_resolved_mode": "",
			"last_mode_transition": {},
		}
	tel["invalid_crash_resolve_blocked"] = int(tel.get("invalid_crash_resolve_blocked", 0)) + 1
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


