class_name AfterblowHandler
extends RefCounted

## Dedicated afterblow handler. Physically realistic: target can complete a previously planned
## attack iff the blow wasn't intense enough to hinder that action.
## Footing: **`CombatFootwork.clear_on_exchange_end`** on afterblow resolve path. LIVE_PATHS **`#wf-tier-44-pa`**
## (clear).
## Choices: Hybrid hindrance, stance (supporting_leg), full resolution, damage *= (1-hindrance), B?A+B?C.


# Part relevance for hindrance (attacking arm from pending; supporting leg from stance)
static func _get_part_relevance(hit_part: String, attacking_arm: String, supporting_leg: String) -> float:
    if hit_part == attacking_arm:
        return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_ARM_ATTACKING
    if hit_part == BodyPartConstants.PART_HEAD:
        return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_HEAD
    if hit_part == BodyPartConstants.PART_CHEST:
        return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_TORSO
    if hit_part == supporting_leg:
        return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_SUPPORTING_LEG
    if hit_part == BodyPartConstants.PART_LEFT_LEG or hit_part == BodyPartConstants.PART_RIGHT_LEG:
        return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_LEG
    if hit_part == BodyPartConstants.PART_LEFT_ARM or hit_part == BodyPartConstants.PART_RIGHT_ARM:
        return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_ARM
    return CombatAfterblowConstants.AFTERBLOW_RELEVANCE_DEFAULT


static func _get_supporting_leg(entity: Node) -> String:
    if entity == null:
        return BodyPartConstants.PART_RIGHT_LEG
    var dom: String = BodyPartConstants.PART_RIGHT_ARM
    if "dominant_hand" in entity:
        dom = entity.dominant_hand
    return (
        BodyPartConstants.PART_RIGHT_LEG if dom == BodyPartConstants.PART_RIGHT_ARM else BodyPartConstants.PART_LEFT_LEG
    )


## Returns true if afterblow was triggered (B's attack resolved). False if hindered, cancelled, or no pending attack.
static func try_afterblow(
    manager: Node, _attacker_id: int, target_id: int, result_dict: Dictionary, intensity: float
) -> bool:
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if tgt.is_empty():
        return false
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(tgt, "pending_attack")
    if MedicalPhaseController.combat_resolution_blocked(manager):
        if not pa.is_empty() or CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_WIND_UP:
            CounterTempo.abort_attacker_wind_up(manager, target_id)
            CombatFootwork.return_to_waiting(tgt)
            tgt.gauge = 0.0
        return false
    if pa.is_empty():
        return false
    if CombatantEntityAccess.state_str(tgt) != CombatConstants.STATE_WIND_UP:
        return false
    var hit_part: String = result_dict.get("part", "")
    var outcome: String = result_dict.get("outcome", "hit")
    var final_cut: float = result_dict.get("final_cut", 0.0)
    var final_blunt: float = result_dict.get("final_blunt", 0.0)
    var final_bone: float = result_dict.get("final_bone", 0.0)
    var total_dmg: float = final_cut + final_blunt + final_bone

    # Immediate disqualifiers
    var tgt_n: Node = CombatantEntityAccess.scene_node(tgt)
    var attacking_arm: String = CombatantEntityAccess.get_attacking_arm(tgt)
    if attacking_arm.is_empty():
        _abort_afterblow_wind_up_no_arm(manager, target_id, tgt)
        return false
    var arm_inoperable: bool = BodyPartQuery._is_arm_destroyed(tgt_n, attacking_arm) if tgt_n != null else true
    if hit_part == attacking_arm and arm_inoperable:
        _abort_afterblow_wind_up_no_arm(manager, target_id, tgt)
        return false
    if hit_part == BodyPartConstants.PART_HEAD and CombatantEntityAccess.is_incapacitated(tgt):
        _cancel_pending(manager, tgt)
        return false

    # Hindrance score (hybrid model)
    if outcome == "deflected":
        # Not hindered  -  allow
        return _execute_afterblow(manager, tgt, 0.0)
    var part_relevance: float = _get_part_relevance(hit_part, attacking_arm, _get_supporting_leg(tgt_n))
    var severity: float = clampf(total_dmg / CombatAfterblowConstants.AFTERBLOW_DAMAGE_HINDER_THRESHOLD, 0.0, 1.5)
    var outcome_mult: float = 0.6 if outcome == "glancing" or outcome == "negligible" else 1.0
    var hindrance: float = clampf(part_relevance * severity * intensity * outcome_mult, 0.0, 1.0)

    if hindrance >= CombatAfterblowConstants.AFTERBLOW_HINDRANCE_BLOCK:
        _cancel_pending(manager, tgt)
        return false
    if hindrance <= CombatAfterblowConstants.AFTERBLOW_HINDRANCE_ALLOW:
        return _execute_afterblow(manager, tgt, hindrance)
    if randf() < hindrance:
        _cancel_pending(manager, tgt)
        return false
    return _execute_afterblow(manager, tgt, hindrance)


static func _abort_afterblow_wind_up_no_arm(manager: Node, target_id: int, tgt: Dictionary) -> void:
    if manager == null or tgt.is_empty() or target_id < 0:
        return
    CounterTempo.abort_attacker_wind_up(manager, target_id)
    CombatMobilityRetreat.react_attacking_arm_lost_if_needed(manager, tgt)


static func _cancel_pending(manager: Node, tgt: Dictionary) -> void:
    CombatFootwork.clear_on_exchange_end(tgt)
    tgt.pending_attack = {}
    tgt.state = CombatConstants.STATE_RECOVERING
    tgt.state_timer = 0.0
    tgt.state_duration = CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S
    var tid: int = CombatantEntityAccess.id_int(tgt)
    if tid >= 0:
        (
            CombatantEntityAccess
            . manager_schedule_event(
                manager,
                {
                    "type": CombatConstants.EVENT_RECOVERY_END,
                    "combatant_id": tid,
                    "resolve_at":
                    CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S,
                    "data": {},
                }
            )
        )
    if CombatDebug.flow_verbose_enabled():
        CombatDebug.flow_log("afterblow %s hindered swing_cancelled" % CombatantEntityAccess.get_display_name(tgt))


static func _execute_afterblow(manager: Node, tgt: Dictionary, hindrance: float) -> bool:
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(tgt, "pending_attack")
    var damage_mult: float = 1.0 - hindrance
    pa["afterblow_damage_mult"] = maxf(0.2, damage_mult)
    # Headless regression only: `CombatRegressionHarness` sets **`_harness_record_afterblow_damage_mult`** on the
    # manager.
    if manager != null and manager.has_meta("_harness_record_afterblow_damage_mult"):
        manager.set_meta("_harness_last_afterblow_damage_mult", float(pa["afterblow_damage_mult"]))
    var tgt_id: int = CombatantEntityAccess.id_int(tgt)
    if CombatDebug.flow_verbose_enabled():
        var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, tgt_id)
        CombatDebug.flow_log(
            "afterblow %s completes hindrance=%.2f dmg_mult=%.2f" % [tgt_name, hindrance, pa["afterblow_damage_mult"]]
        )
    manager._execute_attack(tgt_id)
    return true
