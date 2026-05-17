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
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")

## Tier 1.8 (P9): counters on the combat manager for soak / debug (mode transitions, illegal crash / melee / close resolves).
## Keys are stable for logs, **`_tactical_mode_snapshot["telemetry"]`**, and **`CombatRegressionHarness`** (`_run_telemetry_*`).
const META_COMBAT_TELEMETRY := "_combat_telemetry"


static func _new_combat_telemetry_dict() -> Dictionary:
	return {
		"engagement_mode_transitions": 0,
		"invalid_crash_resolve_blocked": 0,
		"invalid_melee_resolve_blocked": 0,
		"invalid_close_resolve_blocked": 0,
		"automatic_doctrine_pinch_count": 0,
		"last_resolved_mode": "",
		"last_mode_transition": {},
	}

## Enemy front-rank units that could actually land a melee strike on the defender (weapon reach + spacing + band).
## Not merely “MID distance” from formation geometry — matches AvailableActionsBuilder.can_melee_threaten.
static func count_engaging_threats(manager: Node, defender_id: int) -> int:
	var d: Dictionary = (
		_EntityAccess.combatant_dict_or_empty(manager._get_by_id(defender_id))
		if manager.has_method("_get_by_id")
		else {}
	)
	if d.is_empty() or not _EntityAccess.alive_bool(d):
		return 0
	var n: int = 0
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.side_str(c) == _EntityAccess.side_str(d):
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		var pair_geom: Dictionary = _ActionsBuilder.effective_pair_geometry(manager, c, d)
		if _ActionsBuilder.can_melee_threaten(manager, c, d, pair_geom):
			n += 1
	return n

static func _surround_awareness_factor(defender: Dictionary) -> float:
	var perc_norm: float = clampf(float(_EntityAccess.stats_dict(defender).get("perception", 100)) / 100.0, 0.0, 1.0)
	return lerpf(CombatConstants.SURROUND_AWARENESS_AT_LOW_PERCEPTION, 1.0, perc_norm)


## Sum of sector weights for each enemy that `can_melee_threaten` the defender (Tier 3.1 — uses `effective_pair_file_spacing_equivalent` vs flank spacing).
static func compute_surround_threat_weight_sum(manager: Node, defender_id: int) -> float:
	var d: Dictionary = (
		_EntityAccess.combatant_dict_or_empty(manager._get_by_id(defender_id))
		if manager.has_method("_get_by_id")
		else {}
	)
	if d.is_empty() or not _EntityAccess.alive_bool(d):
		return 0.0
	var sum_w: float = 0.0
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.side_str(c) == _EntityAccess.side_str(d):
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		var pair_geom: Dictionary = _ActionsBuilder.effective_pair_geometry(manager, c, d)
		if not _ActionsBuilder.can_melee_threaten(manager, c, d, pair_geom):
			continue
		var eff_f: float = float(pair_geom.get("file_spacing_equiv", 0.0))
		var w: float = eff_f / maxf(0.001, CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN)
		w = clampf(w, CombatConstants.SURROUND_SECTOR_WEIGHT_MIN, 1.0)
		sum_w += w
	return sum_w


static func _surround_from_weight_sum(defender: Dictionary, weight_sum: float) -> float:
	if weight_sum <= CombatConstants.SURROUND_SECTOR_LOAD_FREE + 0.0001:
		return 1.0
	var excess: float = weight_sum - CombatConstants.SURROUND_SECTOR_LOAD_FREE
	var mult: float = 1.0 / (1.0 + CombatConstants.SURROUND_SECTOR_LOAD_K * excess)
	mult = maxf(mult, 1.0 / float(CombatConstants.SURROUND_MAX_SPLIT_DIVISOR))
	return mult * _surround_awareness_factor(defender)


## Parry/dodge surround: uses `pa` when **`is_feature_sector_surround_load`** (weight sum in `pa`); else integer **`surround_threat_count`**.
static func surround_defense_multiplier_from_pa(defender: Dictionary, pa: Dictionary) -> float:
	return surround_defense_multiplier_from_pa_with_sector(
		defender, pa, CombatConstants.is_feature_sector_surround_load()
	)


## Same as **`surround_defense_multiplier_from_pa`**, but **`use_sector_weight_sum`** is explicit (harness can assert the sector path while the feature flag stays **false** in production).
static func surround_defense_multiplier_from_pa_with_sector(
	defender: Dictionary, pa: Dictionary, use_sector_weight_sum: bool
) -> float:
	if use_sector_weight_sum:
		var wsum: float = float(pa.get("surround_threat_weight_sum", pa.get("surround_threat_count", 1)))
		return _surround_from_weight_sum(defender, wsum)
	var n: int = int(pa.get("surround_threat_count", 1))
	return surround_defense_multiplier(defender, n)


## Parry/dodge multiplier from surround + awareness (perception). Integer threat count only (`is_feature_sector_surround_load` false).
static func surround_defense_multiplier(defender: Dictionary, num_engaging_threats: int) -> float:
	if num_engaging_threats <= 1:
		return 1.0
	var div: int = mini(num_engaging_threats, CombatConstants.SURROUND_MAX_SPLIT_DIVISOR)
	var split: float = 1.0 / float(div)
	return split * _surround_awareness_factor(defender)


## Harness: sector path mult ignoring the feature flag (compares to integer **`surround_defense_multiplier`** for the same defender).
static func surround_multiplier_from_weight_sum_for_harness(defender: Dictionary, weight_sum: float) -> float:
	return _surround_from_weight_sum(defender, weight_sum)

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
	if _EntityAccess.side_str(defender) != ambushed:
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
	var mode_now_code: int = _EngagementMode.mode_code(mode_now)
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
			int(snap.get("raw_mode_code", _EngagementMode.mode_code(raw_mode))),
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
		var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
		if formation.is_empty():
			continue
		var our_front: int = p_front if fid == "player" else e_front
		var opp_front: int = e_front if fid == "player" else p_front
		var delta: int = opp_front - our_front
		var pressure: float = clampf(float(delta) * CombatConstants.INCURSION_PRESSURE_PER_RANK_ADVANTAGE, 0.0, CombatConstants.INCURSION_PRESSURE_MAX)
		formation["incursion_pressure"] = pressure
		_recompute_lane_stress_by_file(manager, formation)
		if CombatDebug.flow_verbose_enabled():
			var bf: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation, "breached_files")
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
					CombatDebug.format_lane_stress(_FormationSlots.formation_nested_dictionary_read(formation, "lane_stress_by_file")),
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
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
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
		if not _EntityAccess.alive_bool(c):
			continue
		if not _ZoneOfControl.intruder_on_host_formation(c, host_fid):
			continue
		var file_i: int = _EntityAccess.intrusion_anchor_or_file_int(c)
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
		tel = _new_combat_telemetry_dict()
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
		tel = _new_combat_telemetry_dict()
	tel["invalid_crash_resolve_blocked"] = int(tel.get("invalid_crash_resolve_blocked", 0)) + 1
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


static func record_invalid_melee_resolve_blocked(manager: Node) -> void:
	if manager == null:
		return
	var tel: Dictionary
	if manager.has_meta(META_COMBAT_TELEMETRY):
		tel = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
	else:
		tel = _new_combat_telemetry_dict()
	tel["invalid_melee_resolve_blocked"] = int(tel.get("invalid_melee_resolve_blocked", 0)) + 1
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


static func record_invalid_close_resolve_blocked(manager: Node) -> void:
	if manager == null:
		return
	var tel: Dictionary
	if manager.has_meta(META_COMBAT_TELEMETRY):
		tel = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
	else:
		tel = _new_combat_telemetry_dict()
	tel["invalid_close_resolve_blocked"] = int(tel.get("invalid_close_resolve_blocked", 0)) + 1
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


## Tier 1.8 / Option 4: `FEATURE_AUTOMATIC_DOCTRINE` applied **pinch_center** from hollow enemy line.
static func record_automatic_doctrine_pinch(manager: Node, formation_id: String) -> void:
	if manager == null:
		return
	var tel: Dictionary
	if manager.has_meta(META_COMBAT_TELEMETRY):
		tel = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
	else:
		tel = _new_combat_telemetry_dict()
	tel["automatic_doctrine_pinch_count"] = int(tel.get("automatic_doctrine_pinch_count", 0)) + 1
	tel["last_automatic_doctrine_pinch"] = {"formation_id": str(formation_id), "at": float(manager.combat_clock)}
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


