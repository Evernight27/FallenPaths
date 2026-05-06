class_name CombatDebug
extends RefCounted

## Log tiers: `COMBAT_EVENT_DEBUG` alone → `flow_log_turn` lists actions + pick. With `COMBAT_EVENT_DEBUG_VERBOSE`,
## `get_available_actions` logs the action list once; `flow_log_turn` logs pick + count only (no duplicate list).
## `flow_log`: skip_turn, afterblow, close/crash contest, incursion, formation rejects, resolve edge cases.
## `COMBAT_DEBUG` → per-hit / armor / wind-up (`CombatDebug.log`, EntityDamage traces).
## Unconditional `[Combat]` lines stay for phase boundaries, deaths, and UI-adjacent events (see grep print("[Combat")).
## Conditional combat logging. Only logs when CombatConstants.COMBAT_DEBUG is true.
## calibration_log: logs when COMBAT_DEBUG_CALIBRATION is true (alignment, parry_c_d, variance, etc.).
## flow_log: verbose pipeline; use `dedupe_key` on poll-heavy paths (see `COMBAT_FLOW_LOG_SUPPRESS_REPEATED`). `clear_flow_log_dedup` on combat start/stop.
## flow_log_turn: logs turn pick line when COMBAT_EVENT_DEBUG alone is true.

static func log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG:
		print("[Combat.Debug] ", msg)

## Calibration logs: alignment, parry_c_d, variance, remaining_ratio. Only when COMBAT_DEBUG_CALIBRATION.
static func calibration_log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		print("[Combat.Cal] ", msg)

## True when `flow_log` prints (both event-debug toggles on). Use to skip expensive log prep work.
static func flow_verbose_enabled() -> bool:
	return CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE


## Last message per dedupe key for `COMBAT_FLOW_LOG_SUPPRESS_REPEATED` (cleared on combat start/stop).
static var _flow_log_last_by_key: Dictionary = {}


static func clear_flow_log_dedup() -> void:
	_flow_log_last_by_key.clear()


## Verbose flow. Pass `dedupe_key` for lines that may repeat unchanged every frame (e.g. `get_available_actions`, incursion snapshot); identical consecutive lines for that key are dropped when `COMBAT_FLOW_LOG_SUPPRESS_REPEATED` is on.
static func flow_log(msg: String, dedupe_key: String = "") -> void:
	if not flow_verbose_enabled():
		return
	if CombatConstants.COMBAT_FLOW_LOG_SUPPRESS_REPEATED and not dedupe_key.is_empty():
		var prev: Variant = _flow_log_last_by_key.get(dedupe_key, null)
		if prev != null and str(prev) == msg:
			return
		_flow_log_last_by_key[dedupe_key] = msg
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
	var mid: String = str(choice.get("move_id", ""))
	var tid: int = choice.get("target_id", -1)
	var part: String = str(choice.get("target_part", ""))
	var feint: String = str(choice.get("feint_part", ""))
	var part_s: String = (" part=%s" % part) if not part.is_empty() else ""
	var feint_s: String = (" feint=%s" % feint) if not feint.is_empty() else ""
	if flow_verbose_enabled():
		# Full action list is logged once in `get_available_actions`; avoid repeating it here.
		print(
			"[Combat.Flow] turn side=%s id=%d pick move_id=%s target_id=%d%s%s (actions=%d)"
			% [side, combatant_id, mid, tid, part_s, feint_s, actions.size()]
		)
	else:
		var act_str: String = format_actions_compact(actions)
		print(
			"[Combat.Flow] turn side=%s id=%d actions=[%s] => pick move_id=%s target_id=%d%s%s"
			% [side, combatant_id, act_str, mid, tid, part_s, feint_s]
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
