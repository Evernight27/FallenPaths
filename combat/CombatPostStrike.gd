class_name CombatPostStrike
extends RefCounted

## Post-strike momentum layer (MS-L8): press advantage after successful strike.
## Filter function owned here — MentalStackDecider calls a single method.
## Read order: target alive check → hostile melee strikes vs struck target → attempt_close eligibility.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")


## Returns a prioritized array for pick_weighted():
## 1. Hostile melee strikes vs the struck target (highest priority)
## 2. attempt_close toward that target
## 3. Empty array if the target is dead/gone (defer to other layers)
static func filter_post_strike_actions(
	actions: Array, combatant_id: int, manager: Node, struck_target_id: int
) -> Array:
	var out: Array = []

	# Phase 1: hostile melee strikes vs the struck target.
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_WAIT:
			continue
		if CombatConstants.is_medical_move(mid):
			continue
		if mid == CombatConstants.MOVE_ID_FLEE:
			continue
		if CombatConstants.is_formation_movement_move(mid):
			continue
		if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			continue
		var tid: int = int(a.get("target_id", -1))
		if tid != struck_target_id:
			continue
		var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
		if tgt.is_empty() or not _EntityAccess.alive_bool(tgt):
			continue  # target dead — defer to other layers
		out.append(a)

	# Phase 2: attempt_close toward the struck target (if no strikes found).
	if out.is_empty():
		for raw in actions:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var a: Dictionary = raw as Dictionary
			if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
				continue
			var tid: int = int(a.get("target_id", -1))
			if tid != struck_target_id:
				continue
			out.append(a)

	return out