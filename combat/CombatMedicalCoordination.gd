class_name CombatMedicalCoordination
extends RefCounted

## Retry tracking, “who can treat this ally”, and parts under ally wind-up (direct-pressure gating).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func track_failure_and_maybe_retry(manager: Node, performer: Dictionary, target: Dictionary, part: String, target_cid: int) -> void:
	if target == null:
		return
	var failed: Array = target.get("failed_medical_parts", [])
	if part not in failed:
		failed.append(part)
	target.failed_medical_parts = failed
	var others: int = count_others_who_can_perform_medical_on_target(manager, performer.id, target_cid)
	if others <= 0:
		performer.pending_retry = {"target_id": target_cid, "part": part}


static func count_others_who_can_perform_medical_on_target(manager: Node, exclude_id: int, target_id: int) -> int:
	var count: int = 0
	for other in manager.combatants:
		if other.id == exclude_id or not other.alive or other.side != manager.medical_phase_winner or other.node == null:
			continue
		if _EntityAccess.is_incapacitated(other):
			continue
		var acts: Array = manager.get_available_actions(other.id)
		for a in acts:
			if a.get("target_id", -1) == target_id:
				count += 1
				break
	return count


static func get_parts_being_treated_on(manager: Node, combatant_id: int) -> Array:
	var out: Array = []
	for other in manager.combatants:
		if other.state != CombatConstants.STATE_MEDICAL_WIND_UP:
			continue
		var pm = other.get("pending_medical", {})
		if pm.get("target_combatant_id", -1) == combatant_id:
			var part: String = pm.get("target_part", "")
			if not part.is_empty() and part not in out:
				out.append(part)
	return out
