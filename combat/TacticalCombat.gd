class_name TacticalCombat
extends RefCounted

## Phase 6: Ambush penalties, surround (multi-threat defense split + perception), incursion pressure for ZoC.
## Formations / ambush: CombatConstants presets; plan Tier 1 --" docs/LIVE_PATHS.md#tier-1-spec.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _ArcOccupancy := preload("res://combat/CombatSurroundArcOccupancy.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")

## Tier 1.8 (P9): counters on the combat manager for soak / debug (mode transitions, illegal melee / close resolves).
## Keys are stable for logs, **`_tactical_mode_snapshot["telemetry"]`**, and **`CombatRegressionHarness`** (`_run_telemetry_*`).
const META_COMBAT_TELEMETRY := "_combat_telemetry"


static func _new_combat_telemetry_dict() -> Dictionary:
	return {
		"engagement_mode_transitions": 0,
		"invalid_melee_resolve_blocked": 0,
		"invalid_close_resolve_blocked": 0,
		"automatic_doctrine_pinch_count": 0,
		"last_resolved_mode": "",
		"last_mode_transition": {},
	}

static func _iv12_slot_distraction_pad(manager: Node, defender: Dictionary, threaten_per_cell: Dictionary) -> float:
	if not CombatConstants.is_feature_iv12_slot_distraction_enabled():
		return 0.0
	if manager == null or defender.is_empty() or threaten_per_cell.is_empty():
		return 0.0
	var pad: float = 0.0
	for cell_key in threaten_per_cell.keys():
		if threaten_per_cell.get(cell_key, 0) < 1:
			continue
		var parts: PackedStringArray = str(cell_key).split(":")
		if parts.size() != 3:
			continue
		var fid: String = parts[0]
		var rank_i: int = int(parts[1])
		var file_i: int = int(parts[2])
		var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if formation.is_empty():
			continue
		var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
		var slot_key := Vector2i(rank_i, file_i)
		if _FormationSlots.living_count_in_slot(manager, slots, slot_key) < 2:
			continue
		pad += CombatConstants.IV12_SLOT_DISTRACTION_WEIGHT_PAD
	return pad


static func _iv12_threat_cell_key(manager: Node, c: Dictionary) -> String:
	var fid: String = _EntityAccess.formation_id_str(c)
	if CombatConstants.is_feature_iv12_slot_distraction_enabled() and manager != null:
		var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if not formation.is_empty():
			var slot_key: Variant = _FormationSlots.slot_key_for_combatant_id(
				manager, formation, _EntityAccess.id_int(c)
			)
			if slot_key is Vector2i:
				var sk: Vector2i = slot_key as Vector2i
				return "%s:%d:%d" % [fid, sk.x, sk.y]
	return (
		"%s:%d:%d"
		% [fid, _EntityAccess.rank_int(c), _EntityAccess.file_int(c)]
	)


static func _melee_threat_scan(manager: Node, defender: Dictionary) -> Dictionary:
	var count: int = 0
	var entries: Array = []
	var threaten_per_cell: Dictionary = {}
	if manager == null or defender.is_empty() or not _EntityAccess.alive_bool(defender):
		return {"count": 0, "weight_sum": 0.0}
	for c in manager.combatants:
		if not _EntityAccess.is_living_hostile_to(defender, c):
			continue
		var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(manager, c, defender)
		if not _MeleeListing.can_melee_threaten(manager, c, defender, pair_geom):
			continue
		count += 1
		var eff_f: float = pair_geom.get("file_spacing_equiv", 0.0)
		var w: float = eff_f / maxf(0.001, CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN)
		w = clampf(w, CombatConstants.SURROUND_SECTOR_WEIGHT_MIN, 1.0)
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
		var center: float
		if not pa.is_empty():
			center = _ArcOccupancy.arc_center_deg_from_pa(pa)
		else:
			var df: float = float(_EntityAccess.file_int(c) - _EntityAccess.file_int(defender))
			center = fmod(90.0 + df * 38.0 + 360.0, 360.0)
		entries.append({"weight": w, "arc_center_deg": center})
		var cell_key: String = _iv12_threat_cell_key(manager, c)
		threaten_per_cell[cell_key] = threaten_per_cell.get(cell_key, 0) + 1
	var surround_load: Dictionary = _ArcOccupancy.surround_load_from_threat_entries(entries)
	var weight_sum: float = surround_load.get("weight_sum", 0.0)
	weight_sum += _iv12_slot_distraction_pad(manager, defender, threaten_per_cell)
	return {
		"count": count,
		"weight_sum": weight_sum,
		"arc_occupancy_blocked": surround_load.get("arc_occupancy_blocked", 0),
		"threaten_per_cell": threaten_per_cell,
	}


## IV-12 slice 2: distraction pad from co-located threats on this defender (0 when flag off or no dual slot).
static func iv12_slot_distraction_pad_for_defender(manager: Node, defender_id: int) -> float:
	var d: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if d.is_empty():
		return 0.0
	var scan: Dictionary = _melee_threat_scan(manager, d)
	var per_cell: Dictionary = scan.get("threaten_per_cell", {})
	if not (per_cell is Dictionary):
		return 0.0
	return _iv12_slot_distraction_pad(manager, d, per_cell as Dictionary)


## IV-12 slice 2: damp hostile pick weights when co-located slot distraction is active.
static func iv12_offense_weight_mult(manager: Node, defender_id: int) -> float:
	if not CombatConstants.is_feature_iv12_slot_distraction_enabled():
		return 1.0
	if iv12_slot_distraction_pad_for_defender(manager, defender_id) <= 0.0:
		return 1.0
	return CombatConstants.IV12_AI_OFFENSE_WEIGHT_MULT


## IV-12 slice 2: living hostile slot-mate already threatens this defender (pile-on targeting bias).
static func attacker_has_co_located_slot_mate_threatening(
	manager: Node, attacker: Dictionary, defender: Dictionary
) -> bool:
	if not CombatConstants.is_feature_iv12_slot_distraction_enabled():
		return false
	if manager == null or attacker.is_empty() or defender.is_empty():
		return false
	if not _EntityAccess.is_living_hostile_to(attacker, defender):
		return false
	var fid: String = _EntityAccess.formation_id_str(attacker)
	if fid.is_empty():
		return false
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var self_id: int = _EntityAccess.id_int(attacker)
	var slot_key_var: Variant = _FormationSlots.slot_key_for_combatant_id(
		manager, formation, self_id
	)
	if slot_key_var == null or not (slot_key_var is Vector2i):
		return false
	var slot_key: Vector2i = slot_key_var as Vector2i
	if _FormationSlots.living_count_in_slot(manager, slots, slot_key) < 2:
		return false
	for cid in _FormationSlots.normalize_cell(slots.get(slot_key, [])):
		var mate_id: int = int(cid)
		if mate_id == self_id:
			continue
		var mate: Dictionary = _EntityAccess.manager_get_combatant(manager, mate_id)
		if mate.is_empty() or not _EntityAccess.is_living_hostile_to(mate, defender):
			continue
		var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(manager, mate, defender)
		if _MeleeListing.can_melee_threaten(manager, mate, defender, pair_geom):
			return true
	return false


## Enemy front-rank units that could actually land a melee strike on the defender (weapon reach + spacing + band).
## Not merely --A"MID distance--? from formation geometry --" matches **`CombatMeleeListing.can_melee_threaten`**.
static func count_engaging_threats(manager: Node, defender_id: int) -> int:
	var d: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if d.is_empty():
		return 0
	return _melee_threat_scan(manager, d).get("count", 0)

static func _surround_awareness_factor(defender: Dictionary) -> float:
	var perc_norm: float = clampf(float(_EntityAccess.stats_dict(defender).get("perception", CombatConstants.DEFAULT_STAT_VALUE)) / 100.0, 0.0, 1.0)
	var base: float = lerpf(CombatConstants.SURROUND_AWARENESS_AT_LOW_PERCEPTION, 1.0, perc_norm)
	return base * _Exhaustion.performance_mult_for_combatant(defender)


## Sum of sector weights for each enemy that `can_melee_threaten` the defender (Tier 3.1 --" uses `effective_pair_file_spacing_equivalent` vs flank spacing).
## Live scan: count, sector **`weight_sum`**, and arc-overlap demotions (**`arc_occupancy_blocked`**).
static func surround_threat_scan_for_defender(manager: Node, defender: Dictionary) -> Dictionary:
	if manager == null or defender.is_empty():
		return {"count": 0, "weight_sum": 0.0, "arc_occupancy_blocked": 0}
	return _melee_threat_scan(manager, defender)


static func arc_occupancy_blocked_for_defender(manager: Node, defender: Dictionary) -> int:
	return surround_threat_scan_for_defender(manager, defender).get("arc_occupancy_blocked", 0)


static func stamp_surround_threat_on_pa(manager: Node, defender: Dictionary, pa: Dictionary) -> void:
	if manager == null or defender.is_empty() or pa.is_empty():
		return
	var sur_scan: Dictionary = surround_threat_scan_for_defender(manager, defender)
	pa["surround_threat_count"] = sur_scan.get("count", 0)
	if CombatConstants.is_feature_sector_surround_load():
		pa["surround_threat_weight_sum"] = sur_scan.get("weight_sum", 0.0)
	else:
		pa.erase("surround_threat_weight_sum")
	var arc_blocked: int = sur_scan.get("arc_occupancy_blocked", 0)
	if arc_blocked > 0 and CombatConstants.is_feature_surround_arc_occupancy_enabled():
		pa["arc_occupancy_blocked"] = arc_blocked
	else:
		pa.erase("arc_occupancy_blocked")


## Per-attacker sector weight (0.35--"1.0) for one defender --" same geometry as surround threat scan.
static func sector_weight_for_attacker_on_defender(
	manager: Node, defender_id: int, attacker_id: int
) -> float:
	var defender: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if defender.is_empty() or attacker_id < 0:
		return 1.0
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty() or not _EntityAccess.is_living_hostile_to(defender, atk):
		return 1.0
	var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(manager, atk, defender)
	if not _MeleeListing.can_melee_threaten(manager, atk, defender, pair_geom):
		return 1.0
	var eff_f: float = pair_geom.get("file_spacing_equiv", 0.0)
	var w: float = eff_f / maxf(0.001, CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN)
	return clampf(w, CombatConstants.SURROUND_SECTOR_WEIGHT_MIN, 1.0)


static func compute_surround_threat_weight_sum(manager: Node, defender_id: int) -> float:
	var d: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if d.is_empty():
		return 0.0
	return _melee_threat_scan(manager, d).get("weight_sum", 0.0)


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
		var wsum: float = pa.get("surround_threat_weight_sum", pa.get("surround_threat_count", 1))
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
	if enc is not Dictionary:
		return 1.0
	var e: Dictionary = enc
	var at: String = str(e.get("ambush_type", CombatConstants.AMBUSH_TYPE_NONE))
	if at == CombatConstants.AMBUSH_TYPE_NONE or at.is_empty():
		return 1.0
	var ambushed: String = str(e.get(CombatConstants.ENCOUNTER_AMBUSHED_SIDE, "player"))
	if not _EntityAccess.is_on_side(defender, ambushed):
		return 1.0
	var p: float = e.get("ambush_penalty", 0.25)
	p = clampf(p, 0.0, 0.85)
	if at == CombatConstants.AMBUSH_TYPE_PARTIAL:
		p *= 0.5
	return 1.0 - p

## Global incursion 0..INCURSION_PRESSURE_MAX from front-rank imbalance; lane_stress_by_file from dual occupancy + density (not bodies --" those are obs_pen in ZoC).
static func recompute_incursion_pressure(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	var snap: Dictionary = _EngagementMode.snapshot(manager)
	var p_front: int = snap.get("player_front", 0)
	var e_front: int = snap.get("enemy_front", 0)
	var mode_now: String = _EngagementMode.engagement_mode(manager)
	var mode_now_code: int = _EngagementMode.mode_code(mode_now)
	var raw_mode: String = str(snap.get("raw_mode", "skirmish"))
	_telemetry_after_mode_resolve(manager, mode_now)
	if manager != null:
		var mode_snap: Dictionary = snap.duplicate()
		mode_snap["mode"] = mode_now
		mode_snap["mode_code"] = mode_now_code
		mode_snap["combat_clock"] = float(manager.get("combat_clock"))
		if manager.has_meta(META_COMBAT_TELEMETRY):
			mode_snap["telemetry"] = (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
		manager.set_meta("_tactical_mode_snapshot", mode_snap)
	var mode_line: String = (
		"mode=%s(%d) raw=%s(%d) active[player=%d enemy=%d] front[player=%d enemy=%d] fill[player=%.2f enemy=%.2f]"
		% [
			mode_now,
			mode_now_code,
			raw_mode,
			snap.get("raw_mode_code", _EngagementMode.mode_code(raw_mode)),
			snap.get("player_active", 0),
			snap.get("enemy_active", 0),
			p_front,
			e_front,
			snap.get("player_front_fill", 0.0),
			snap.get("enemy_front_fill", 0.0),
		]
	)
	for fid in [_CombatConstants.SIDE_PLAYER, _CombatConstants.SIDE_ENEMY]:
		var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if formation.is_empty():
			continue
		var our_front: int = p_front if fid == _CombatConstants.SIDE_PLAYER else e_front
		var opp_front: int = e_front if fid == _CombatConstants.SIDE_PLAYER else p_front
		var delta: int = opp_front - our_front
		var pressure: float = clampf(float(delta) * CombatConstants.INCURSION_PRESSURE_PER_RANK_ADVANTAGE, 0.0, CombatConstants.INCURSION_PRESSURE_MAX)
		formation["incursion_pressure"] = pressure
		_recompute_lane_stress_by_file(manager, formation)
		if CombatDebug.flow_verbose_enabled():
			CombatDebug.flow_log(
				(
					"incursion_snapshot fid=%s pressure=%.3f lane_stress[%s] mode_state[%s] front_alive=%d"
				)
				% [
					fid,
					formation.get("incursion_pressure", 0.0),
					CombatDebug.format_lane_stress(
						_FormationSlots.formation_nested_dictionary_read(formation, "lane_stress_by_file")
					),
					mode_line,
					our_front,
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
		by_file[f] = clampf(stress, 0.0, 1.0)
	formation["lane_stress_by_file"] = by_file


static func _telemetry_dict(manager: Node) -> Dictionary:
	if manager.has_meta(META_COMBAT_TELEMETRY):
		return (manager.get_meta(META_COMBAT_TELEMETRY) as Dictionary).duplicate()
	return _new_combat_telemetry_dict()


static func _bump_telemetry_counter(manager: Node, key: String, extra: Dictionary = {}) -> void:
	if manager == null:
		return
	var tel: Dictionary = _telemetry_dict(manager)
	tel[key] = tel.get(key, 0) + 1
	for ek in extra.keys():
		tel[ek] = extra[ek]
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


static func seed_engagement_mode_telemetry(manager: Node, mode_now: String) -> void:
	if manager == null or mode_now.is_empty():
		return
	var tel: Dictionary = _telemetry_dict(manager)
	tel["last_resolved_mode"] = mode_now
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


static func _telemetry_after_mode_resolve(manager: Node, mode_now: String) -> void:
	if manager == null:
		return
	var tel: Dictionary = _telemetry_dict(manager)
	var prev: String = str(tel.get("last_resolved_mode", ""))
	if prev != "" and prev != mode_now:
		tel["engagement_mode_transitions"] = tel.get("engagement_mode_transitions", 0) + 1
		tel["last_mode_transition"] = {
			"from": prev,
			"to": mode_now,
			"at": _EntityAccess.combat_clock_float(manager),
		}
		if _OperationalLog.is_play_session_active():
			var from_disp: String = _EngagementMode.mode_display_name(prev)
			var to_disp: String = _EngagementMode.mode_display_name(mode_now)
			_F5SoakTrace.note_engagement_transition(from_disp, to_disp)
	tel["last_resolved_mode"] = mode_now
	manager.set_meta(META_COMBAT_TELEMETRY, tel)


static func record_invalid_melee_resolve_blocked(manager: Node) -> void:
	_bump_telemetry_counter(manager, "invalid_melee_resolve_blocked")


static func record_invalid_close_resolve_blocked(manager: Node) -> void:
	_bump_telemetry_counter(manager, "invalid_close_resolve_blocked")


## Tier 1.8 / Option 4: `FEATURE_AUTOMATIC_DOCTRINE` applied **pinch_center** (hollow center or numeric superiority).
static func record_automatic_doctrine_pinch(
	manager: Node, formation_id: String, reason: String = ""
) -> void:
	var lap: Dictionary = {
		"formation_id": str(formation_id),
		"at": _EntityAccess.combat_clock_float(manager),
	}
	if not reason.is_empty():
		lap["reason"] = str(reason)
	_bump_telemetry_counter(
		manager,
		"automatic_doctrine_pinch_count",
		{"last_automatic_doctrine_pinch": lap}
	)
