class_name CombatMedicalWeighting
extends RefCounted

## Pure medical triage weight computation extracted from **`CombatAIActionPicker._get_medical_weight`**.
## Handles: coordination gate, urgency, part threat, skill effectiveness scaling, pending retry,
## failed-part retry, stabilize/dressing out-of-peril dampening, tourniquet indication,
## bleeding rate + direct pressure interaction, packing before pressure ordering.


## Check if the medical escalation feature is active (inline to avoid circular preload).
static func is_feature_ms_medical_escalation_enabled() -> bool:
    return CombatConstants.is_feature_ms_medical_escalation_enabled()


## Compute triage weight for a single medical action. Returns **`MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED`** when
## coordination gate fails.
static func compute_weight(a: Dictionary, combatant_id: int, manager: Node) -> float:
    var mid: String = a.get("move_id", "")
    var tgt_id: int = a.get("target_id", -1)
    var part: String = str(a.get("target_part", ""))

    # Coordination gate
    if not CombatMedicalCoordination.medical_action_allowed(manager, combatant_id, tgt_id, part, mid):
        return MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED

    # Fetch target and performer
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tgt_id)
    var performer: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)

    # Skill effectiveness (clamped)
    var perf_entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, performer)
    var eff: float = clampf(
        CombatantEntityAccess.get_medical_effectiveness_from_node(perf_entity),
        MedicalPhaseBatchResolve.MEDICAL_AI_EFF_CLAMP_MIN,
        MedicalPhaseBatchResolve.MEDICAL_AI_EFF_CLAMP_MAX
    )

    # Urgency + part threat base weight
    var urgency: float = (
        MedicalPhaseController.get_medical_urgency_deterministic(manager, tgt) if not tgt.is_empty() else 0.0
    )
    var part_threat: float = (
        MedicalPhaseController.get_part_intervention_threat(manager, tgt, part)
        if not tgt.is_empty() and not part.is_empty()
        else 0.0
    )
    var w: float = 1.0 + urgency * (MedicalPhaseBatchResolve.MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
    w += part_threat * MedicalPhaseBatchResolve.MEDICAL_AI_PART_THREAT_MULT

    # Skill effectiveness scaling
    w = _compute_skill_multiplier(w, mid, eff)

    # Pending retry preference / penalty
    w = _compute_pending_retry_weight(a, performer, tgt, manager, w)

    # Failed-part retry
    w = _compute_failed_part_retry_weight(a, tgt, mid, w, combatant_id, manager)

    # Out-of-peril dampening for stabilize/dressing
    w = _compute_out_of_peril_dampening(tgt, mid, manager, w)

    # Tourniquet indication boost
    w = _compute_tourniquet_indication_weight(tgt, part, mid, manager, w)

    # Bleeding rate + direct pressure interaction
    w = _compute_bleeding_interaction(combatant_id, tgt, tgt_id, part, mid, manager, w)

    # Medical escalation bonus: boost higher-tier TCCC steps when prior steps failed.
    if is_feature_ms_medical_escalation_enabled() and CombatConstants.is_wind_up_medical_move(mid):
        var esc: float = _compute_escalation_bonus(tgt, part, mid, combatant_id, manager)
        w *= esc

    return maxf(w, 0.001)


## Compute skill effectiveness multiplier inline (avoids mutating `w` by reference).
static func _compute_skill_multiplier(base_w: float, mid: String, eff: float) -> float:
    if CombatConstants.is_wind_up_medical_move(mid):
        return base_w * pow(eff, MedicalPhaseBatchResolve.MEDICAL_AI_ADVANCED_SKILL_EXP)
    if mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
        var span: float = maxf(
            MedicalPhaseBatchResolve.MEDICAL_AI_EFF_CLAMP_MAX - MedicalPhaseBatchResolve.MEDICAL_AI_EFF_CLAMP_MIN, 0.01
        )
        var t: float = clampf((eff - MedicalPhaseBatchResolve.MEDICAL_AI_EFF_CLAMP_MIN) / span, 0.0, 1.0)
        return (
            base_w
            * lerpf(
                MedicalPhaseBatchResolve.MEDICAL_AI_PRESSURE_LOW_SKILL_MULT,
                MedicalPhaseBatchResolve.MEDICAL_AI_PRESSURE_HIGH_SKILL_MULT,
                t
            )
        )
    return base_w


## Compute pending retry weight factor. Modifies `w` by returning the multiplied result.
static func _compute_pending_retry_weight(
    a: Dictionary, performer: Dictionary, tgt: Dictionary, manager: Node, w: float
) -> float:
    var pending: Dictionary = {}
    if performer != null:
        var pnd_raw: Variant = performer.get("pending_retry", null)
        if pnd_raw is Dictionary:
            pending = pnd_raw as Dictionary
    if (
        not pending.is_empty()
        and pending.get("target_id", -1) == a.get("target_id", -1)
        and pending.get("part", "") == a.get("target_part", "")
    ):
        if not tgt.is_empty() and CombatantEntityAccess.is_in_immediate_peril(manager, tgt):
            return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_PENDING_RETRY_PERIL
        return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_PENDING_RETRY
    return w


## Compute failed-part retry weight factor.
## When escalation is available (a higher-tier TCCC action exists), suppresses the retry bonus
## so the picker prefers escalating rather than repeating the same failed step.
static func _compute_failed_part_retry_weight(
    a: Dictionary, tgt: Dictionary, mid: String, w: float, performer_id: int = -1, manager: Node = null
) -> float:
    var failed_raw: Variant = tgt.get("failed_medical_parts", null) if not tgt.is_empty() else null
    if (
        failed_raw is Array
        and part_in_array(failed_raw as Array, a.get("target_part", ""))
        and CombatConstants.is_wind_up_medical_move(mid)
    ):
        # Escalation check: is a higher-tier action available on the TCCC ladder?
        if is_feature_ms_medical_escalation_enabled() and performer_id >= 0 and manager != null:
            var escalation_available: bool = _escalation_path_has_next_step(
                tgt, a.get("target_part", ""), mid, manager, performer_id
            )
            if escalation_available:
                return w  # Suppress retry bonus --" escalate instead
        return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_FAILED_PART_RETRY
    return w


## Compute out-of-peril dampening for stabilize/dressing moves.
static func _compute_out_of_peril_dampening(tgt: Dictionary, mid: String, manager: Node, w: float) -> float:
    if not tgt.is_empty() and not CombatantEntityAccess.is_in_immediate_peril(manager, tgt):
        if mid == CombatConstants.MOVE_ID_STABILIZE_WOUND:
            return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_STABILIZE_OUT_OF_PERIL
        if mid == CombatConstants.MOVE_ID_BANDAGE_SELF or mid == CombatConstants.MOVE_ID_PACK_WOUND:
            return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_DRESSING_OUT_OF_PERIL
    return w


## Compute tourniquet indication weight factor.
static func _compute_tourniquet_indication_weight(
    tgt: Dictionary, part: String, mid: String, manager: Node, w: float
) -> float:
    if not tgt.is_empty() and not part.is_empty() and CombatantEntityAccess.is_in_immediate_peril(manager, tgt):
        var health: Node = CombatantEntityAccess.get_health_entity_from_node(
            manager, CombatantEntityAccess.scene_node(tgt)
        )
        if CombatantEntityAccess.entity_is_tourniquet_indicated_for_part(health, tgt, part):
            if mid == CombatConstants.MOVE_ID_APPLY_TOURNIQUET:
                return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_TOURNIQUET_INDICATED
            if CombatConstants.is_dressing_medical_move(mid):
                return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_BANDAGE_BEFORE_HEMOSTASIS
    return w


## Compute bleeding rate + direct pressure interaction weight. Returns early with coordination-blocked when pressure is
## held.
static func _compute_bleeding_interaction(
    combatant_id: int, tgt: Dictionary, tgt_id: int, part: String, mid: String, manager: Node, w: float
) -> float:
    if not tgt.is_empty() and not part.is_empty():
        var health: Node = CombatantEntityAccess.get_health_entity_from_node(
            manager, CombatantEntityAccess.scene_node(tgt)
        )
        var bleed_r: float = CombatantEntityAccess.entity_bleeding_rate_for_part(health, tgt, part)
        var active_bleed: bool = bleed_r > BleedingConstants.BLEEDING_RATE_EPSILON
        var held: bool = CombatantEntityAccess.entity_has_direct_pressure_on_part(health, tgt, part)
        if (
            mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
            and CombatMedicalCoordination.can_stack_assist_pressure(manager, combatant_id, tgt_id, part)
        ):
            return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_TREATMENT_ASSIST_PRESSURE
        if held and mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
            return MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED
        if active_bleed and not held:
            if mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
                return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_PRESSURE_ACTIVE_BLEED
            if CombatConstants.is_dressing_medical_move(mid):
                if not MedicalPhaseController.dressings_allowed_for_part(manager, tgt, part):
                    return 0.001
                if mid == CombatConstants.MOVE_ID_PACK_WOUND:
                    # When escalation is active and this part has failed bandage,
                    # pack IS the correct TCCC step --" don't dampen it.
                    if is_feature_ms_medical_escalation_enabled():
                        var failed_raw: Variant = tgt.get("failed_medical_parts", null)
                        if failed_raw is Array and part_in_array(failed_raw as Array, part):
                            var esc_path: Array = MedicalPhaseController.escalation_path_for_part(
                                int(tgt.get("id", -1)), combatant_id, part, manager
                            )
                            if not esc_path.is_empty():
                                var cur_idx: int = esc_path.find(CombatConstants.MOVE_ID_PACK_WOUND)
                                if cur_idx > 0:
                                    return w  # Skip dampening --" pack is an escalation step
                    return w * MedicalPhaseBatchResolve.MEDICAL_AI_WEIGHT_PACK_BEFORE_PRESSURE
    return w


## Check if a higher-tier TCCC action is available for the given part and current move.
## Returns true when the current move_id is NOT the last step on the escalation path.
static func _escalation_path_has_next_step(
    tgt: Dictionary, part: String, current_move_id: String, manager: Node, performer_id: int
) -> bool:
    if performer_id < 0 or manager == null:
        return false
    var path: Array = MedicalPhaseController.escalation_path_for_part(
        int(tgt.get("id", -1)), performer_id, part, manager
    )
    if path.is_empty():
        return false
    var current_idx: int = path.find(current_move_id)
    if current_idx < 0 or current_idx >= path.size() - 1:
        return false
    # Verify the next step is actually performable --" capability matters.
    var perf: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, performer_id)
    if not perf.is_empty():
        var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, perf)
        if entity != null and path.size() > current_idx + 1:
            var next_mid: String = path[current_idx + 1]
            if next_mid == CombatConstants.MOVE_ID_PACK_WOUND:
                if not EntityMedical.can_apply_packing(entity, part):
                    return false
            elif next_mid == CombatConstants.MOVE_ID_APPLY_TOURNIQUET:
                if not EntityMedical._can_apply_tourniquet(entity, part):
                    return false
    return true


## Compute escalation bonus for the current medical action.
## Returns MEDICAL_AI_WEIGHT_ESCALATION_BONUS when the action is a higher-tier TCCC step
## and the target part has failed medical parts (indicating prior steps failed).
static func _compute_escalation_bonus(
    tgt: Dictionary, part: String, current_move_id: String, performer_id: int, manager: Node
) -> float:
    if performer_id < 0 or manager == null:
        return 1.0
    var path: Array = MedicalPhaseController.escalation_path_for_part(
        int(tgt.get("id", -1)), performer_id, part, manager
    )
    if path.is_empty():
        return 1.0
    var current_idx: int = path.find(current_move_id)
    if current_idx < 0:
        return 1.0
    # Check if the part has failed medical parts.
    var failed_raw: Variant = tgt.get("failed_medical_parts", null)
    if failed_raw is not Array:
        return 1.0
    var failed_list: Array = failed_raw
    if failed_list.is_empty():
        return 1.0
    # If the current step is NOT the first in the path, and the part has failed,
    # this is an escalation --" apply bonus.
    if current_idx > 0 and part_in_array(failed_list, part):
        return CombatConstants.MEDICAL_AI_WEIGHT_ESCALATION_BONUS
    return 1.0


## Helper: check if a value is in an array (avoids `in` operator on Variant arrays).
static func part_in_array(arr: Array, val: String) -> bool:
    for item in arr:
        if str(item) == val:
            return true
    return false
