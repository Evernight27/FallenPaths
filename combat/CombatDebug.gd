class_name CombatDebug
extends RefCounted

## Conditional combat logging. Only logs when CombatConstants.COMBAT_DEBUG is true.
## calibration_log: logs when COMBAT_DEBUG_CALIBRATION is true (alignment, parry_c_d, variance, etc.).
## flow_log: logs when COMBAT_EVENT_DEBUG and COMBAT_EVENT_DEBUG_VERBOSE — action lists, incursion snapshots, resolves.
## flow_log_turn: logs turn pick line when COMBAT_EVENT_DEBUG alone is true.

static func log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG:
		print("[Combat.Debug] ", msg)

## Calibration logs: alignment, parry_c_d, variance, remaining_ratio. Only when COMBAT_DEBUG_CALIBRATION.
static func calibration_log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		print("[Combat.Cal] ", msg)

## Verbose flow (action lists, incursion snapshots, formation resolves). Requires `COMBAT_EVENT_DEBUG_VERBOSE`.
static func flow_log(msg: String) -> void:
	if CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE:
		print("[Combat.Flow] ", msg)


## Vacancy plug / rank-0 reconcile. Toggle `CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG`.
static func formation_vacancy_log(msg: String) -> void:
	if CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG:
		print("[Combat.Formation] ", msg)

## One-line summary of build() output for logs (move_id@target_id[:part]).
static func format_actions_compact(actions: Array) -> String:
	var parts: PackedStringArray = []
	for a in actions:
		var mid: String = str(a.get("move_id", ""))
		var tid: int = a.get("target_id", -1)
		var part: String = str(a.get("target_part", ""))
		if part.is_empty():
			parts.append("%s@%d" % [mid, tid])
		else:
			parts.append("%s@%d:%s" % [mid, tid, part])
	return ", ".join(parts)

static func flow_log_turn(side: String, combatant_id: int, actions: Array, choice: Dictionary) -> void:
	if not CombatConstants.COMBAT_EVENT_DEBUG:
		return
	var act_str: String = format_actions_compact(actions)
	print(
		"[Combat.Flow] turn side=%s id=%d actions=[%s] => pick move_id=%s target_id=%d"
		% [side, combatant_id, act_str, choice.get("move_id", ""), choice.get("target_id", -1)]
	)


## breached_files keys may be int or String from serialization paths; values 0..1
static func format_breached_files(bf: Dictionary) -> String:
	if bf.is_empty():
		return ""
	var parts: PackedStringArray = []
	for k in bf.keys():
		parts.append("%s:%.2f" % [str(k), float(bf[k])])
	return "; ".join(parts)


## lane_stress_by_file or similar: file index -> float
static func format_lane_stress(by_file: Dictionary) -> String:
	if by_file.is_empty():
		return ""
	var parts: PackedStringArray = []
	for k in by_file.keys():
		parts.append("f%s=%.2f" % [str(k), float(by_file[k])])
	return ", ".join(parts)
