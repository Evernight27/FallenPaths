class_name CombatMedicalActionListing
extends RefCounted

## Listing: **`CombatantEntityAccess`** + **`CombatMedicalCoordination`** +
## **`MedicalPhaseController.get_ally_medical_actions`**.
## **Read order:** receiving-care pressure --'' ' medical-phase winner scan --'' ' ally part menu --'' ' MS-MID
## mid-fight peril allies.
## Move IDs: **`CombatConstants.MOVE_ID_*`** . membership via **`CombatConstants.is_medical_move`**.
## Post-victory prisoner triage (plan §3 hook 7): when Stage-1 winner triage is done, append execute / stabilize
## actions for each downed losing-side combatant. Decision weight uses CombatExecute personality/mood/threat/grudge.


static func append_receiving_care_direct_pressure(
	manager: Node, c: Dictionary, combatant_id: int, actions: Array, medical_phase_winner: String
) -> bool:
	if manager == null or c.is_empty():
		return false
	if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
		return false
	if not manager.medical_phase:
		return false
	if not CombatantEntityAccess.is_on_side(c, medical_phase_winner):
		return false
	if not CombatantEntityAccess.scene_supports_medical_pressure_listing(c):
		return true
	var parts_being_treated: Array = CombatMedicalCoordination.get_parts_being_treated_on(manager, combatant_id)
	for part in CombatantEntityAccess.get_wounded_parts(c, manager):
		if part.is_empty() or part in parts_being_treated:
			continue
		if CombatantEntityAccess.entity_has_direct_pressure_on_part(manager, c, part):
			continue
		if not CombatMedicalCoordination.medical_action_allowed(
			manager, combatant_id, combatant_id, part, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
		):
			continue
		if CombatantEntityAccess.entity_can_apply_direct_pressure(manager, c, part):
			(
				actions
				. append(
					{
						"target_id": combatant_id,
						"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE,
						"target_part": part,
					}
				)
			)
	return true


static func append_medical_phase_winner_actions(
	manager: Node, c: Dictionary, combatants: Array, actions: Array, medical_phase_winner: String
) -> void:
	if manager == null or c.is_empty():
		return
	if not CombatantEntityAccess.is_on_side(c, medical_phase_winner):
		return
	if not CombatantEntityAccess.scene_can_apply_direct_pressure_api(c):
		return
	var immediate_peril: bool = CombatantEntityAccess.is_in_immediate_peril(manager, c)
	for ally in combatants:
		if not CombatantEntityAccess.is_living_same_side(c, ally) or CombatantEntityAccess.scene_node(ally) == null:
			continue
		if not CombatantEntityAccess.is_on_side(ally, medical_phase_winner):
			continue
		if not CombatantEntityAccess.is_available_medical_ally(c, ally):
			continue
		if not CombatantEntityAccess.scene_has_wounded_parts_listing(ally):
			continue
		if immediate_peril and CombatantEntityAccess.id_int(ally) != CombatantEntityAccess.id_int(c):
			continue
		var wounded: Array = CombatantEntityAccess.get_wounded_parts(ally, manager)
		var parts_being_treated: Array = CombatMedicalCoordination.get_parts_being_treated_on(
			manager, CombatantEntityAccess.id_int(ally)
		)
		for part in wounded:
			if part.is_empty() or part in parts_being_treated:
				continue
			var tgt_id: int = CombatantEntityAccess.id_int(ally)
			for act in MedicalPhaseController.get_ally_medical_actions(manager, c, ally, part):
				if act is not Dictionary:
					continue
				(
					actions
					. append(
						{
							"target_id": tgt_id,
							"move_id": act.get("move_id", ""),
							"target_part": act.get(DataKeys.ACTION_TARGET_PART, ""),
						}
					)
				)
	# Stage-2: after ally medical actions, add prisoner triage (execute / spare-stabilize) when Stage-1 is done.
	if not immediate_peril:
		append_prisoner_triage_actions(manager, c, combatants, actions, medical_phase_winner)


## Stage-2 prisoner triage (plan §3 hook 7 / §4): when winner-side medical is complete, each downed losing-side
## combatant becomes an execute or stabilize-spare decision. Execute resolves via standard death pipeline; spare
## applies bandage/pack/pressure to stop bleeding then stamps the target as a prisoner so they survive post-victory.
static func append_prisoner_triage_actions(
	manager: Node, c: Dictionary, combatants: Array, actions: Array, medical_phase_winner: String
) -> void:
	if manager == null or c.is_empty() or not manager.medical_phase:
		return
	if not CombatantEntityAccess.is_on_side(c, medical_phase_winner):
		return
	if not MedicalPhaseController.winner_triage_complete(manager):
		return
	var _executor_id: int = CombatantEntityAccess.id_int(c)
	for enemy in combatants:
		if not CombatantEntityAccess.is_alive_opponent_of(c, enemy):
			continue
		if CombatantEntityAccess.has_left_battlefield(enemy):
			continue
		# Only process downed enemies (cowering / unconscious / yielded).
		if CombatantEntityAccess.is_standing_combatant(enemy):
			continue
		var enemy_id: int = CombatantEntityAccess.id_int(enemy)
		var exec_fid: String = CombatantEntityAccess.formation_id_str(c)
		if not exec_fid.is_empty():
			var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, exec_fid)
			if formation.get(DataKeys.FORMATION_ENGAGEMENT_POSTURE, "") == CombatConstants.ENGAGEMENT_POSTURE_LINE:
				var flank_mates_alive: bool = false
				for other in combatants:
					if not CombatantEntityAccess.is_living_same_side(c, other):
						continue
					var other_fid: String = CombatantEntityAccess.formation_id_str(other)
					if other_fid != exec_fid or CombatantEntityAccess.id_int(other) == enemy_id:
						continue
					if not CombatantEntityAccess.is_standing_combatant(other):
						continue
					flank_mates_alive = true
					break
				if not flank_mates_alive:
					actions.append({
						"target_id": enemy_id,
						"move_id": CombatConstants.MOVE_ID_EXECUTE,
						"target_part": "",
					})
		else:
			actions.append({
				"target_id": enemy_id,
				"move_id": CombatConstants.MOVE_ID_EXECUTE,
				"target_part": "",
			})
		# Spare-and-stabilize: apply tourniquet/pressure/bandage/pack to stop bleeding so the prisoner survives.
		var wounded_parts: Array = CombatantEntityAccess.get_wounded_parts(enemy, manager)
		for part in wounded_parts:
			if part.is_empty():
				continue
			if CombatantEntityAccess.entity_is_tourniquet_indicated_for_part(manager, enemy, part):
				if CombatantEntityAccess.entity_can_apply_tourniquet(manager, c, part):
					actions.append({
						"target_id": enemy_id,
						"move_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET,
						"target_part": part,
					})
			if not CombatantEntityAccess.entity_has_direct_pressure_on_part(manager, enemy, part):
				if CombatantEntityAccess.entity_can_apply_direct_pressure(manager, c, part):
					actions.append({
						"target_id": enemy_id,
						"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE,
						"target_part": part,
					})
			if CombatantEntityAccess.entity_can_apply_bandage(manager, c, part):
				actions.append({
					"target_id": enemy_id,
					"move_id": CombatConstants.MOVE_ID_BANDAGE_ALLY,
					"target_part": part,
				})
			if CombatantEntityAccess.entity_can_apply_packing(manager, c, part):
				actions.append({
					"target_id": enemy_id,
					"move_id": CombatConstants.MOVE_ID_PACK_ALLY,
					"target_part": part,
				})


static func append_mid_fight_ally_medical_actions(
	manager: Node, c: Dictionary, combatants: Array, actions: Array
) -> void:
	if manager == null or c.is_empty():
		return
	if not CombatConstants.is_feature_ms_mid_infight_med_enabled():
		return
	if manager.medical_phase:
		return
	if not CombatantEntityAccess.scene_can_apply_direct_pressure_api(c):
		return
	var performer_id: int = CombatantEntityAccess.id_int(c)
	if CombatantEntityAccess.is_in_immediate_peril(manager, c):
		return
	if CombatantEntityAccess.rank_int(c) <= 0:
		return
	var perf_fid: String = CombatantEntityAccess.formation_id_str(c)
	if not perf_fid.is_empty():
		var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, perf_fid)
		if formation.get(DataKeys.FORMATION_ENGAGEMENT_POSTURE, "") != CombatConstants.ENGAGEMENT_POSTURE_LINE:
			return
		if CombatDepthPolearm.same_file_living_rank0_ally(manager, c, perf_fid).is_empty():
			return
	if not CombatAttention.ally_in_immediate_peril(manager, performer_id):
		return
	for ally in combatants:
		if not CombatantEntityAccess.is_living_same_side(c, ally) or CombatantEntityAccess.scene_node(ally) == null:
			continue
		if CombatantEntityAccess.id_int(ally) == performer_id:
			continue
		if not CombatantEntityAccess.is_available_medical_ally(c, ally):
			continue
		if not CombatantEntityAccess.is_in_immediate_peril(manager, ally):
			continue
		if not CombatantEntityAccess.scene_has_wounded_parts_listing(ally):
			continue
		var wounded: Array = CombatantEntityAccess.get_wounded_parts(ally, manager)
		var parts_being_treated: Array = CombatMedicalCoordination.get_parts_being_treated_on(
			manager, CombatantEntityAccess.id_int(ally)
		)
		for part in wounded:
			if part.is_empty() or part in parts_being_treated:
				continue
			var tgt_id: int = CombatantEntityAccess.id_int(ally)
			for act in MedicalPhaseController.get_ally_medical_actions(manager, c, ally, part):
				if act is not Dictionary:
					continue
				(
					actions
					. append(
						{
							"target_id": tgt_id,
							"move_id": act.get("move_id", ""),
							"target_part": act.get(DataKeys.ACTION_TARGET_PART, ""),
						}
					)
				)
