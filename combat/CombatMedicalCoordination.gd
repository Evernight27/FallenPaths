class_name CombatMedicalCoordination
extends RefCounted

## Retry tracking, “who can treat this ally”, and parts under ally wind-up (direct-pressure gating).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func track_failure_and_maybe_retry(manager: Node, performer: Dictionary, target: Dictionary, part: String, target_cid: int) -> void:
	if target == null:
		return
	var failed: Array = _EntityAccess.nested_array_for_mutation(target, "failed_medical_parts")
	if part not in failed:
		failed.append(part)
	var others: int = count_others_who_can_perform_medical_on_target(manager, _EntityAccess.id_int(performer), target_cid)
	if others <= 0:
		performer.pending_retry = {"target_id": target_cid, "part": part}


static func count_others_who_can_perform_medical_on_target(manager: Node, exclude_id: int, target_id: int) -> int:
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
