class_name CombatMedicalCoordination
extends RefCounted

## Retry tracking, overlap guards, and “who can treat this ally” (listing + resolve).
## **Read order:** coordination gate → retry → overlap/wind-up → listing filters.
## Canonical: **`medical_action_allowed`** · **`track_failure_and_maybe_retry`** · **`AGENTS.md`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")


# --- Coordination gate (resolve + listing) ---


## Empty when allowed; otherwise a short reason for resolve reject / debug.
static func medical_action_coordination_blocked(
	manager: Node, performer_id: int, target_id: int, part: String, move_id: String
) -> String:
	if part.is_empty():
		return "empty_part"
	var target: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if target.is_empty():
		return "missing_target"
	if CombatConstants.is_direct_pressure_move(move_id):
		if can_stack_assist_pressure(manager, performer_id, target_id, part):
			return ""
		var bleed_r: float = _EntityAccess.entity_bleeding_rate_for_part(manager, target, part)
		if bleed_r <= _Bleeding.BLEEDING_RATE_EPSILON:
			return "no_active_bleed"
		if part_has_compression_on(manager, target, part):
			return "compression_already_held"
		var other_tx: Dictionary = get_active_windup_treatment_by_other(
			manager, performer_id, target_id, part
		)
		if not other_tx.is_empty():
			return "other_treatment_in_progress"
		return ""
	var other_tx_adv: Dictionary = get_active_windup_treatment_by_other(
		manager, performer_id, target_id, part
	)
	if not other_tx_adv.is_empty():
		return "other_treatment_in_progress"
	return ""


static func medical_action_allowed(
	manager: Node, performer_id: int, target_id: int, part: String, move_id: String
) -> bool:
	return medical_action_coordination_blocked(manager, performer_id, target_id, part, move_id).is_empty()


# --- Retry tracking ---


static func track_failure_and_maybe_retry(
	manager: Node, performer: Dictionary, target: Dictionary, part: String, target_cid: int
) -> void:
	if target == null:
		return
	var failed: Array = _EntityAccess.nested_array_for_mutation(target, "failed_medical_parts")
	if part not in failed:
		failed.append(part)
	var others: int = count_others_who_can_perform_medical_on_target(
		manager, _EntityAccess.id_int(performer), target_cid
	)
	if others <= 0:
		performer.pending_retry = {"target_id": target_cid, "part": part}


static func count_others_who_can_perform_medical_on_target(
	manager: Node, exclude_id: int, target_id: int
) -> int:
	var count: int = 0
	for other in manager.combatants:
		if (
			_EntityAccess.id_int(other) == exclude_id
			or not _EntityAccess.is_living_on_side(other, str(manager.medical_phase_winner))
			or _EntityAccess.scene_node(other) == null
		):
			continue
		var acts: Array = manager.get_available_actions(_EntityAccess.id_int(other))
		for a in acts:
			if a.get("target_id", -1) == target_id:
				count += 1
				break
	return count


# --- Overlap / wind-up ---


static func get_parts_being_treated_on(manager: Node, combatant_id: int) -> Array:
	var out: Array = []
	for other in manager.combatants:
		if _EntityAccess.state_str(other) != CombatConstants.STATE_MEDICAL_WIND_UP:
			continue
		var pm_raw: Variant = other.get("pending_medical", null)
		if typeof(pm_raw) != TYPE_DICTIONARY:
			continue
		var pm: Dictionary = pm_raw as Dictionary
		if pm.get("target_combatant_id", -1) == combatant_id:
			var part: String = pm.get("target_part", "")
			if not part.is_empty() and part not in out:
				out.append(part)
	return out


## Another medic’s in-flight wind-up on **`target_id`** + **`part`** (excludes **`exclude_performer_id`**).
static func get_active_windup_treatment_by_other(
	manager: Node, exclude_performer_id: int, target_id: int, part: String
) -> Dictionary:
	if manager == null or part.is_empty() or target_id < 0:
		return {}
	for other in manager.combatants:
		if _EntityAccess.id_int(other) == exclude_performer_id:
			continue
		if _EntityAccess.state_str(other) != CombatConstants.STATE_MEDICAL_WIND_UP:
			continue
		var pm_raw: Variant = other.get("pending_medical", null)
		if typeof(pm_raw) != TYPE_DICTIONARY:
			continue
		var pm: Dictionary = pm_raw as Dictionary
		if pm.get("target_combatant_id", -1) != target_id:
			continue
		if str(pm.get("target_part", "")) != part:
			continue
		return {
			"performer_id": _EntityAccess.id_int(other),
			"medical_id": str(pm.get("medical_id", "")),
		}
	return {}


static func is_part_under_treatment_by_other(
	manager: Node, performer_id: int, target_id: int, part: String
) -> bool:
	return not get_active_windup_treatment_by_other(manager, performer_id, target_id, part).is_empty()


static func part_has_compression_on(manager: Node, target: Dictionary, part: String) -> bool:
	if target.is_empty() or part.is_empty():
		return false
	return _EntityAccess.entity_has_direct_pressure_on_part(manager, target, part)


## Second medic may stack assist only (no takeover) while primary holds compression or wind-up is active.
static func can_stack_assist_pressure(
	manager: Node, performer_id: int, target_id: int, part: String
) -> bool:
	var performer: Dictionary = _EntityAccess.manager_get_combatant(manager, performer_id)
	var target: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if performer.is_empty() or target.is_empty():
		return false
	return _EntityAccess.entity_stack_assist_pressure_eligible(manager, target, performer, part)


# --- Listing filters ---


static func filter_actions_for_pick(manager: Node, performer_id: int, actions: Array) -> Array:
	if manager == null or not bool(manager.medical_phase):
		return actions
	var out: Array = []
	for raw in actions:
		if raw is not Dictionary:
			continue
		var act: Dictionary = raw as Dictionary
		var part: String = str(act.get("target_part", ""))
		var mid: String = str(act.get("move_id", ""))
		var tgt_id: int = int(act.get("target_id", -1))
		if medical_action_allowed(manager, performer_id, tgt_id, part, mid):
			out.append(act)
	return out


static func filter_ally_medical_actions(
	manager: Node, performer: Dictionary, ally: Dictionary, actions: Array
) -> Array:
	var out: Array = []
	var performer_id: int = _EntityAccess.id_int(performer)
	var ally_id: int = _EntityAccess.id_int(ally)
	for raw in actions:
		if raw is not Dictionary:
			continue
		var act: Dictionary = raw as Dictionary
		var part: String = str(act.get("target_part", ""))
		var mid: String = str(act.get("move_id", ""))
		if medical_action_allowed(manager, performer_id, ally_id, part, mid):
			out.append(act)
	return out
