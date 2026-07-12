class_name CombatHarnessComposureSeeds
extends RefCounted

## Per-action composure gauge seeds for regression / soak setups (COMPOSURE_PLAN §7A).
## Production fight start uses entity campaign readiness or GAUGE_MAX — not these literals.

const DEFAULT := 100.0
const WAIT := 100.0
const QUICK_STRIKE := 80.0
const MEDIUM_STRIKE := 55.0
const HEAVY_STRIKE := 30.0
const FEINT := 95.0
const COUNTER_TEMPO := 70.0
const RETREAT := 90.0
const CLOSE_ATTEMPT := 65.0
const FORMATION := 85.0
const MEDICAL := 100.0


static func gauge_for_move_id(move_id: String) -> float:
	if move_id.is_empty():
		return DEFAULT
	if CombatConstants.is_medical_move(move_id):
		return MEDICAL
	if move_id == CombatConstants.MOVE_ID_WAIT:
		return WAIT
	if move_id == CombatConstants.MOVE_ID_FEINT:
		return FEINT
	if move_id == CombatConstants.MOVE_ID_QUICK:
		return QUICK_STRIKE
	if move_id == CombatConstants.MOVE_ID_MEDIUM:
		return MEDIUM_STRIKE
	if move_id == CombatConstants.MOVE_ID_HEAVY:
		return HEAVY_STRIKE
	if "retreat" in move_id or move_id == "flee":
		return RETREAT
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return CLOSE_ATTEMPT
	if move_id == "counter_tempo":
		return COUNTER_TEMPO
	if CombatConstants.is_formation_movement_move(move_id):
		return FORMATION
	return DEFAULT


static func apply_gauge(combatant: Dictionary, move_id: String = "") -> void:
	if combatant.is_empty():
		return
	combatant["gauge"] = gauge_for_move_id(move_id)


static func apply_gauge_value(combatant: Dictionary, gauge: float) -> void:
	if combatant.is_empty():
		return
	combatant["gauge"] = clampf(gauge, 0.0, 100.0)
