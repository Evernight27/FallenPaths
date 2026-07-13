class_name CombatMedicalActionListing
extends RefCounted

## Listing: **`CombatantEntityAccess`** + **`CombatMedicalCoordination`** +
## **`MedicalPhaseController.get_ally_medical_actions`**.
## **Read order:** receiving-care pressure --'' ' medical-phase winner scan --'' ' ally part menu --'' ' MS-MID
## mid-fight peril allies.
## Move IDs: **`CombatConstants.MOVE_ID_*`** . membership via **`CombatConstants.is_medical_move`**.


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
                            "target_part": act.get("target_part", ""),
                        }
                    )
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
        if formation.get("engagement_posture", "") != CombatConstants.ENGAGEMENT_POSTURE_LINE:
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
                            "target_part": act.get("target_part", ""),
                        }
                    )
                )
