class_name CombatDebug
extends RefCounted

## Conditional combat logging. Only logs when CombatConstants.COMBAT_DEBUG is true.
## calibration_log: logs when COMBAT_DEBUG_CALIBRATION is true (alignment, parry_c_d, variance, etc.).
## flow_log: logs when COMBAT_EVENT_DEBUG is true — turns, actions list, picks, skip/wait, resolve entry (feature testing).

static func log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG:
		print("[Combat.Debug] ", msg)

## Calibration logs: alignment, parry_c_d, variance, remaining_ratio. Only when COMBAT_DEBUG_CALIBRATION.
static func calibration_log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		print("[Combat.Cal] ", msg)

## High-level flow: available actions, AI pick, skip/wait, resolve_action branches. Toggle CombatConstants.COMBAT_EVENT_DEBUG.
static func flow_log(msg: String) -> void:
	if CombatConstants.COMBAT_EVENT_DEBUG:
		print("[Combat.Flow] ", msg)

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
	flow_log("turn side=%s id=%d actions=[%s] => pick move_id=%s target_id=%d" % [
		side, combatant_id, act_str, choice.get("move_id", ""), choice.get("target_id", -1)
	])
