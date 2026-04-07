class_name FormationBreachRules
extends RefCounted

## Breach congestion: `formation.breached_files[file_index] -> 0..1` (severity). Separate from global incursion and per-file dual/density lane stress.
## See docs/TACTICAL_ZONES_BREACH_MOVEMENT.md §3.1, §11.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _BREACH_ACTIVE_EPSILON := 0.001

static func _count_front_rank_alive(manager: Node, formation_key: String) -> int:
	var n: int = 0
	if manager == null or not manager.has_method("_get_by_id"):
		return 0
	for c in manager.combatants:
		if not c.get("alive", false):
			continue
		if c.get("formation_id", "") != formation_key:
			continue
		if c.get("rank", 0) != 0:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		n += 1
	return n


## True when there is no real two-sided rank-0 line (duel, cleanup, or one side's front row empty). Used to relax breach-based formation move locks.
static func is_skirmish_line_engagement(manager: Node) -> bool:
	var p: int = _count_front_rank_alive(manager, "player")
	var e: int = _count_front_rank_alive(manager, "enemy")
	if p == 0 or e == 0:
		return true
	return p <= 1 and e <= 1


## Whether open-lane formation moves should be withheld for this formation (swap / rotate / fall_back). Honors skirmish uncleg when enabled.
static func breach_blocks_open_lane_moves(manager: Node, formation: Dictionary) -> bool:
	if formation.is_empty() or not breach_clogs_open_lanes(formation):
		return false
	if CombatConstants.FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES and is_skirmish_line_engagement(manager):
		return false
	return true


static func breach_clogs_open_lanes(formation: Dictionary) -> bool:
	var bf: Dictionary = formation.get("breached_files", {})
	if bf.is_empty():
		return false
	for v in bf.values():
		if float(v) > _BREACH_ACTIVE_EPSILON:
			return true
	return false

## Extra lane stress from plugging / crowding at a breached file (physics-flavored bump). Capped before merge into 0..1 lane stress.
static func breach_local_lane_stress_bonus(formation: Dictionary, file_index: int) -> float:
	var bf: Dictionary = formation.get("breached_files", {})
	var raw: float = float(bf.get(file_index, bf.get(str(file_index), 0.0)))
	if raw <= _BREACH_ACTIVE_EPSILON:
		return 0.0
	var add: float = raw * CombatConstants.LANE_STRESS_BREACH_LOCAL_SCALE
	return minf(add, CombatConstants.LANE_STRESS_BREACH_LOCAL_BONUS_MAX)
