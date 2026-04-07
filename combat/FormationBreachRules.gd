class_name FormationBreachRules
extends RefCounted

## Breach congestion: `formation.breached_files[file_index] -> 0..1` (severity). Separate from global incursion and per-file dual/density lane stress.
## See docs/TACTICAL_ZONES_BREACH_MOVEMENT.md §3.1, §11.

const _BREACH_ACTIVE_EPSILON := 0.001

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
