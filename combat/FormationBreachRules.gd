class_name FormationBreachRules
extends RefCounted

## Breach congestion: `formation.breached_files[file_index] -> 0..1` (severity). Separate from global incursion and per-file dual/density lane stress.
## See docs/TACTICAL_ZONES_BREACH_MOVEMENT.md §3.1, §11.
##
## Skirmish vs formation (breach move lock only): counts are **rank 0 only**, alive, not incapacitated.
## | player front | enemy front | skirmish (default tuning) |
## |--------------|-------------|---------------------------|
## | 0            | *           | yes if SKIRMISH_WHEN_EITHER_SIDE_ZERO_FRONT |
## | *            | 0           | same |
## | 1            | 1           | yes (duel) |
## | 2+           | 1           | no (2v1 line) |
## | 1            | 2+          | no |
## | 2+           | 2+          | no |

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CombatAIActionPicker := preload("res://combat/CombatAIActionPicker.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FileKeys := preload("res://combat/CombatFileKeyedDict.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _BREACH_ACTIVE_EPSILON := 0.001

## Severity at a file index; keys may be int or string (serialization). Prefer int when writing.
static func breached_file_severity(breached_files: Dictionary, file_index: int, default_if_missing: float = 0.0) -> float:
	return float(_FileKeys.get_value(breached_files, file_index, default_if_missing))


## Canonical rank-0 count for player / enemy formations (native line only; matches `CombatEngagementMode.snapshot`).
static func count_front_rank_alive(manager: Node, formation_key: String) -> int:
	return _EngagementMode.count_front_rank_alive(manager, formation_key)


static func engagement_mode(manager: Node) -> String:
	return _EngagementMode.engagement_mode(manager)


## True when there is no robust two-sided line (duel/skirmish). Used to relax breach-based formation move locks.
static func is_skirmish_line_engagement(manager: Node) -> bool:
	return engagement_mode(manager) != "formation"


## Crash/incursion should only open in full formation mode; existing intruders may still fight from depth.
static func incursion_allowed(manager: Node) -> bool:
	return _EngagementMode.incursion_allowed(manager)


## Whether open-lane formation moves should be withheld for **listing** disengage / fall-back (see `AvailableActionsBuilder`).
## Plug/relief `swap_rank` and same-rank `rotate_file` can still resolve via `resolve_blocks_formation_move`.
## Honors skirmish uncleg when enabled.
static func breach_blocks_open_lane_moves(manager: Node, formation: Dictionary) -> bool:
	if formation.is_empty() or not breach_clogs_open_lanes(formation):
		return false
	if CombatConstants.FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES and is_skirmish_line_engagement(manager):
		return false
	return true


static func breach_clogs_open_lanes(formation: Dictionary) -> bool:
	var bf: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation, "breached_files")
	if bf.is_empty():
		return false
	for v in bf.values():
		if float(v) > _BREACH_ACTIVE_EPSILON:
			return true
	return false

## Adjacent-rank swap to step over an incapacitated front neighbor (same column).
static func is_plug_forward_adjacent_rank_swap(initiator: Dictionary, partner: Dictionary) -> bool:
	var ri: int = _EntityAccess.rank_int(initiator)
	var rp: int = _EntityAccess.rank_int(partner)
	if abs(ri - rp) != 1:
		return false
	var r_front: int = mini(ri, rp)
	var front: Dictionary = initiator if ri == r_front else partner
	return _EntityAccess.is_incapacitated(front)


## Adjacent-rank relief rotation: deeper rank swaps toward the front when tactically justified.
static func is_relief_adjacent_rank_swap(initiator: Dictionary, partner: Dictionary) -> bool:
	var ri: int = _EntityAccess.rank_int(initiator)
	var rp: int = _EntityAccess.rank_int(partner)
	if abs(ri - rp) != 1:
		return false
	if _EntityAccess.is_incapacitated(initiator) or _EntityAccess.is_incapacitated(partner):
		return false
	var deeper: Dictionary = initiator if ri > rp else partner
	var shallower: Dictionary = partner if ri > rp else initiator
	return _CombatAIActionPicker.is_relief_swap_tactically_allowed(deeper, shallower)


static func is_plug_or_relief_adjacent_rank_swap(initiator: Dictionary, partner: Dictionary) -> bool:
	return is_plug_forward_adjacent_rank_swap(initiator, partner) or is_relief_adjacent_rank_swap(
		initiator, partner
	)


## Formation move resolution while lanes are clogged: allow row plugging / relief and same-rank line rotation; block disengage-style moves.
static func resolve_blocks_formation_move(
	manager: Node,
	formation: Dictionary,
	move_id: String,
	initiator: Dictionary,
	partner: Dictionary
) -> bool:
	if formation.is_empty() or not breach_clogs_open_lanes(formation):
		return false
	if CombatConstants.FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES and is_skirmish_line_engagement(manager):
		return false
	match move_id:
		CombatConstants.MOVE_ID_ROTATE_FILE:
			return false
		CombatConstants.MOVE_ID_SWAP_RANK:
			return not is_plug_or_relief_adjacent_rank_swap(initiator, partner)
		CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK:
			return true
		_:
			return false


## Extra lane stress from plugging / crowding at a breached file (physics-flavored bump). Capped before merge into 0..1 lane stress.
static func breach_local_lane_stress_bonus(formation: Dictionary, file_index: int) -> float:
	var bf: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation, "breached_files")
	var raw: float = breached_file_severity(bf, file_index)
	if raw <= _BREACH_ACTIVE_EPSILON:
		return 0.0
	var add: float = raw * CombatConstants.LANE_STRESS_BREACH_LOCAL_SCALE
	return minf(add, CombatConstants.LANE_STRESS_BREACH_LOCAL_BONUS_MAX)
