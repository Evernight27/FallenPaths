class_name CombatDebug
extends RefCounted

## Conditional combat logging. Only logs when CombatConstants.COMBAT_DEBUG is true.
## calibration_log: logs when COMBAT_DEBUG_CALIBRATION is true (alignment, parry_c_d, variance, etc.).

static func log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG:
		print("[Combat.Debug] ", msg)

## Calibration logs: alignment, parry_c_d, variance, remaining_ratio. Only when COMBAT_DEBUG_CALIBRATION.
static func calibration_log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		print("[Combat.Cal] ", msg)
