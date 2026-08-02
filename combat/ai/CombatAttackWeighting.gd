class_name CombatAttackWeighting
extends RefCounted

## Short-horizon parry-deflect recency pressure for feint listing.
## Public static — called from `CombatAIActionWeights._compute_attack_weight_components`.
static func _feint_listing_opp_parry_deflect_pressure_mult(
	manager: Node, attacker: Dictionary, defender_id: int
) -> float:
	if manager == null or attacker.is_empty() or defender_id < 0:
		return 1.0
	var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
	if raw_m == null or not (raw_m is Dictionary):
		return 1.0
	var st: Variant = (raw_m as Dictionary).get(str(defender_id), null)
	if st == null:
		return 1.0
	var stored_tick: int = int(st)
	var tick_now: int = manager.get_combat_tick_index()
	var age: int = tick_now - stored_tick
	if age < 0:
		return 1.0
	var win: int = maxi(1, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS)
	var t: float = 1.0 - clampf(float(age) / win, 0.0, 1.0)
	return lerpf(1.0, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT, t)
