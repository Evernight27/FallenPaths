class_name TacticalCombat
extends RefCounted

## Phase 6: Ambush penalties, surround (multi-threat defense split + perception), incursion pressure for ZoC.
## See docs/COMBAT_ROADMAP_AND_STAMINA.md Phase 6; formations/ambush — docs/TACTICAL_FORMATIONS_FF4.md.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")

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
	for fid in ["player", "enemy"]:
		var formation: Dictionary = manager.formations.get(fid, {})
		if formation.is_empty():
			continue
		var opp_side: String = "enemy" if fid == "player" else "player"
		var our_front: int = _FormationBreachRules.count_front_rank_alive(manager, fid)
		var opp_front: int = _FormationBreachRules.count_front_rank_alive(manager, opp_side)
		var delta: int = opp_front - our_front
		var pressure: float = clampf(float(delta) * CombatConstants.INCURSION_PRESSURE_PER_RANK_ADVANTAGE, 0.0, CombatConstants.INCURSION_PRESSURE_MAX)
		formation["incursion_pressure"] = pressure
		_recompute_lane_stress_by_file(manager, formation)
		if CombatConstants.COMBAT_EVENT_DEBUG:
			var bf: Dictionary = formation.get("breached_files", {})
			var raw_clog: bool = _FormationBreachRules.breach_clogs_open_lanes(formation)
			var blocks_moves: bool = _FormationBreachRules.breach_blocks_open_lane_moves(manager, formation)
			var skirm: bool = _FormationBreachRules.is_skirmish_line_engagement(manager)
			CombatDebug.flow_log(
				(
					"incursion_snapshot fid=%s pressure=%.3f lane_stress[%s] breached[%s] "
					+ "breach_raw_clogs=%s breach_blocks_moves=%s skirmish=%s"
				)
				% [
					fid,
					float(formation.get("incursion_pressure", 0.0)),
					CombatDebug.format_lane_stress(formation.get("lane_stress_by_file", {})),
					CombatDebug.format_breached_files(bf),
					raw_clog,
					blocks_moves,
					skirm
				]
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
		by_file[f] = clampf(stress, 0.0, 1.0)
	formation["lane_stress_by_file"] = by_file

