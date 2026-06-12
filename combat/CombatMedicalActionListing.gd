class_name CombatMedicalActionListing
extends RefCounted

## Listing: **`CombatantEntityAccess`** + **`CombatMedicalCoordination`** + **`MedicalPhaseController.get_ally_medical_actions`**.
## **Read order:** receiving-care pressure → medical-phase winner scan → ally part menu → MS-MID mid-fight peril allies.
## Move IDs: **`CombatConstants.MOVE_ID_*`** · membership via **`CombatConstants.is_medical_move`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _Attention := preload("res://combat/CombatAttention.gd")


static func append_receiving_care_direct_pressure(
	manager: Node, c: Dictionary, combatant_id: int, actions: Array, medical_phase_winner: String
) -> bool:
	if manager == null or c.is_empty():
		return false
	if _EntityAccess.state_str(c) != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
		return false
	if not manager.medical_phase:
		return false
	if not _EntityAccess.is_on_side(c, medical_phase_winner):
		return false
	if not _EntityAccess.scene_supports_medical_pressure_listing(c):
		return true
	var parts_being_treated: Array = _MedicalCoord.get_parts_being_treated_on(manager, combatant_id)
	for part in _EntityAccess.get_wounded_parts(c, manager):
		if part.is_empty() or part in parts_being_treated:
			continue
		if _EntityAccess.entity_has_direct_pressure_on_part(manager, c, part):
			continue
		if not _MedicalCoord.medical_action_allowed(
			manager, combatant_id, combatant_id, part, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
		):
			continue
		if _EntityAccess.entity_can_apply_direct_pressure(manager, c, part):
			actions.append(
				{
					"target_id": combatant_id,
					"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE,
					"target_part": part,
				}
			)
	return true


static func append_medical_phase_winner_actions(
	manager: Node, c: Dictionary, combatants: Array, actions: Array, medical_phase_winner: String
) -> void:
	if manager == null or c.is_empty():
		return
	if not _EntityAccess.is_on_side(c, medical_phase_winner):
		return
	if not _EntityAccess.scene_can_apply_direct_pressure_api(c):
		return
	var immediate_peril: bool = _EntityAccess.is_in_immediate_peril(manager, c)
	for ally in combatants:
		if (
			not _EntityAccess.is_living_same_side(c, ally)
			or _EntityAccess.scene_node(ally) == null
		):
			continue
		if not _EntityAccess.is_on_side(ally, medical_phase_winner):
			continue
		if not _EntityAccess.is_available_medical_ally(c, ally):
			continue
		if not _EntityAccess.scene_has_wounded_parts_listing(ally):
			continue
		if immediate_peril and _EntityAccess.id_int(ally) != _EntityAccess.id_int(c):
			continue
		var wounded: Array = _EntityAccess.get_wounded_parts(ally, manager)
		var parts_being_treated: Array = _MedicalCoord.get_parts_being_treated_on(
			manager, _EntityAccess.id_int(ally)
		)
		for part in wounded:
			if part.is_empty() or part in parts_being_treated:
				continue
			var tgt_id: int = _EntityAccess.id_int(ally)
			for act in _MedicalPhase.get_ally_medical_actions(manager, c, ally, part):
				if act is not Dictionary:
					continue
				actions.append(
					{
						"target_id": tgt_id,
						"move_id": str(act.get("move_id", "")),
						"target_part": str(act.get("target_part", "")),
					}
				)


static func append_mid_fight_ally_medical_actions(
	manager: Node, c: Dictionary, combatants: Array, actions: Array
) -> void:
	if manager == null or c.is_empty():
		return
	if not CombatConstants.is_feature_ms_mid_infight_med_enabled():
		return
	if manager.medical_phase:
		return
	if not _EntityAccess.scene_can_apply_direct_pressure_api(c):
		return
	var performer_id: int = _EntityAccess.id_int(c)
	if _EntityAccess.is_in_immediate_peril(manager, c):
		return
	if not _Attention.ally_in_immediate_peril(manager, performer_id):
		return
	for ally in combatants:
		if (
			not _EntityAccess.is_living_same_side(c, ally)
			or _EntityAccess.scene_node(ally) == null
		):
			continue
		if _EntityAccess.id_int(ally) == performer_id:
			continue
		if not _EntityAccess.is_available_medical_ally(c, ally):
			continue
		if not _EntityAccess.is_in_immediate_peril(manager, ally):
			continue
		if not _EntityAccess.scene_has_wounded_parts_listing(ally):
			continue
		var wounded: Array = _EntityAccess.get_wounded_parts(ally, manager)
		var parts_being_treated: Array = _MedicalCoord.get_parts_being_treated_on(
			manager, _EntityAccess.id_int(ally)
		)
		for part in wounded:
			if part.is_empty() or part in parts_being_treated:
				continue
			var tgt_id: int = _EntityAccess.id_int(ally)
			for act in _MedicalPhase.get_ally_medical_actions(manager, c, ally, part):
				if act is not Dictionary:
					continue
				actions.append(
					{
						"target_id": tgt_id,
						"move_id": str(act.get("move_id", "")),
						"target_part": str(act.get("target_part", "")),
					}
				)
