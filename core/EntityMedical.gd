class_name EntityMedical
extends RefCounted

## Medical actions (bandage, packing, direct pressure, tourniquet) for entities that have
## wounds, bandaged_parts, packed_parts, tourniquet_applied, and direct_pressure_* state.
## Entity must implement: get_attacking_arm(), get_bleeding_rate_for_part(part), get_medical_effectiveness(), get_game_time_seconds()

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")

const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _BodyPartQuery := preload("res://core/BodyPartQuery.gd")


## F5: dressings/pack/TQ outcomes stay; skip hold/release pressure spam (`medical_action pick` + combat log cover menu use).
static func log_medical_session(msg: String) -> void:
    var m: String = msg.strip_edges()
    if _OperationalLog.is_play_session_active():
        if "direct_pressure" in m or m.begins_with("treatment_assist_pressure") or m.begins_with("pressure_rebound"):
            return
    _CombatDebug.medical_session(m)


# --- Shared wound treatment (bandage, packing) ---


static func part_is_bandaged(entity: Node, part: String) -> bool:
    return entity.bandaged_parts.get(part, false)


static func part_is_packed(entity: Node, part: String) -> bool:
    return entity.packed_parts.get(part, false)


## TCCC: compressible hemorrhage needs sustained compression before dress/pack while still actively bleeding.
## A packed part already has compression from the pack; bandage secures it without re-applying pressure.
static func _compression_required_before_dressing(entity: Node, part: String) -> bool:
    if part_is_packed(entity, part):
        return false
    return (
        entity.get_bleeding_rate_for_part(part) > _Bleeding.BLEEDING_RATE_EPSILON
        and not has_direct_pressure_on_part(entity, part)
    )


## Internal: shared roll-and-apply logic for stabilizing wound treatments (bandage, packing).
## Returns true on success. Mutates entity.wounds in place.
static func _apply_stabilizing_treatment(
    entity: Node,
    part: String,
    effectiveness: float,
    success_base: float,
    success_arterial_mult: float,
    arterial_eff_mult: float,
    immediate_reduction: float,
    mark_dict: Dictionary,
    pressure_held: bool = false,
    mark_injury_stabilized: bool = true
) -> Dictionary:
    if part.is_empty() or not ("wounds" in entity):
        return {"success": false, "wound_count": 0, "reduction": 0.0}
    var w: Variant = entity.get("wounds")
    if not (w is Dictionary) or not w.has(part):
        return {"success": false, "wound_count": 0, "reduction": 0.0}
    effectiveness = clampf(effectiveness, 0.0, 1.5)
    var has_arterial: bool = false
    for injury in entity.wounds[part]:
        if injury.get("is_arterial", false):
            has_arterial = true
            break
    var success_chance: float = success_base
    if has_arterial:
        success_chance *= success_arterial_mult
    success_chance *= effectiveness
    if pressure_held:
        success_chance *= _Bleeding.TREATMENT_PRESSURE_HELD_SUCCESS_MULT
    success_chance = clampf(success_chance, 0.0, 1.0)
    var roll: float = randf()
    var success: bool = roll < success_chance
    var wound_count: int = entity.wounds[part].size()
    var reduction: float = 0.0
    if success:
        for injury in entity.wounds[part]:
            var eff: float = effectiveness
            if injury.get("is_arterial", false):
                eff *= arterial_eff_mult
            var red: float = immediate_reduction * clampf(eff, 0.0, 1.0)
            var rate: float = injury.get("current_bleeding_rate", 0.0)
            injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - red))
            if mark_injury_stabilized:
                injury["is_stabilized"] = true
                if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
                    injury["stabilized_remaining_seconds"] = _Bleeding.BANDAGE_STABILIZATION_DURATION
        mark_dict[part] = true
    else:
        var closeness: float = 1.0
        if success_chance < 1.0:
            closeness = 1.0 - (roll - success_chance) / (1.0 - success_chance)
            closeness = clampf(closeness, 0.0, 1.0)
        reduction = closeness * immediate_reduction
        for injury in entity.wounds[part]:
            var eff: float = effectiveness
            if injury.get("is_arterial", false):
                eff *= arterial_eff_mult
            var wound_reduction: float = reduction * clampf(eff, 0.0, 1.0)
            var rate: float = injury.get("current_bleeding_rate", 0.0)
            injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - wound_reduction))
    return {"success": success, "wound_count": wound_count, "reduction": reduction}


# --- Bandage ---


static func get_bandage_application_time_seconds() -> float:
    return _Bleeding.BANDAGE_APPLICATION_TIME_SECONDS


static func get_bandage_application_time_seconds_for_part(entity: Node, part: String) -> float:
    return _get_application_time_for_part(
        entity, part, _Bleeding.BANDAGE_APPLICATION_TIME_SECONDS, _Bleeding.BANDAGE_PER_WOUND_EXTRA_SECONDS
    )


## Anatomical / severity complexity for one dressing procedure (not raw hit count).
static func get_treatment_channel_count(entity: Node, part: String) -> int:
    if part.is_empty() or not entity.wounds.has(part) or entity.wounds[part].is_empty():
        return 1
    var channels: Dictionary = {}
    var extra_severe: int = 0
    for injury in entity.wounds[part]:
        var sr: String = injury.get("sub_region", "")
        if sr.is_empty():
            sr = "_default"
        channels[sr] = true
        if injury.get("is_stump", false) or injury.get("is_arterial", false):
            extra_severe += 1
        else:
            var sev: String = str(injury.get("severity", _Bleeding.SEVERITY_MODERATE))
            if sev == _Bleeding.SEVERITY_CRITICAL or sev == _Bleeding.SEVERITY_SEVERE:
                extra_severe += 1
    return maxi(1, channels.size() + maxi(0, extra_severe - 1))


## Internal: shared logic for bandage/packing per-part application time.
static func _get_application_time_for_part(
    entity: Node, part: String, base_seconds: float, per_wound_extra: float
) -> float:
    if part.is_empty() or not entity.wounds.has(part):
        return base_seconds
    var n: int = get_treatment_channel_count(entity, part)
    return base_seconds + per_wound_extra * max(0, n - 1)


## Ally- or self-held direct pressure on this part does **not** block bandaging; `apply_bandage` clears pressure only on a successful dressing.
static func can_apply_bandage(entity: Node, part: String) -> bool:
    if part.is_empty() or not entity.wounds.has(part) or entity.wounds[part].is_empty():
        return false
    if entity.tourniquet_applied.has(part) or part_is_bandaged(entity, part):
        return false
    # Life-threatening limb hemorrhage: TQ path --" do not bandage over indicated extremity bleed (combat listing parity).
    if _BodyPartQuery.is_limb(part) and is_tourniquet_indicated_for_part(entity, part):
        return false
    if _compression_required_before_dressing(entity, part):
        return false
    # Pack then wrap: linen cavity pack may be secured with an outer bandage.
    return true


static func apply_bandage(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
    if part.is_empty() or not entity.wounds.has(part):
        return false
    if not can_apply_bandage(entity, part):
        return false
    var pressure_held: bool = has_direct_pressure_on_part(entity, part)
    var r = _apply_stabilizing_treatment(
        entity,
        part,
        effectiveness,
        _Bleeding.BANDAGE_SUCCESS_BASE_CHANCE,
        _Bleeding.BANDAGE_SUCCESS_ARTERIAL_MULT,
        _Bleeding.BANDAGE_ARTERIAL_EFFECTIVENESS_MULT,
        _Bleeding.BANDAGE_IMMEDIATE_REDUCTION,
        entity.bandaged_parts,
        pressure_held
    )
    if r.success:
        clear_direct_pressure(entity)
        log_medical_session(
            "%s apply_bandage(%s) => success, %d wound(s) stabilized" % [entity.name, part, r.wound_count]
        )
    else:
        log_medical_session(
            (
                "%s apply_bandage(%s) => failed (%.0f%% reduction), %d wound(s); can retry"
                % [entity.name, part, r.reduction * 100, r.wound_count]
            )
        )
    return r.success


# --- Combat stabilize (Camp-2.5) ---


static func get_stabilize_application_time_seconds_for_part(entity: Node, part: String) -> float:
    return _get_application_time_for_part(
        entity, part, _Bleeding.STABILIZE_APPLICATION_TIME_SECONDS, _Bleeding.STABILIZE_PER_WOUND_EXTRA_SECONDS
    )


## Quick hemostatic control while pressure is held; trims bleed rate only --" does **not** set `is_stabilized` (definitive dress still required).
static func can_apply_stabilize(entity: Node, part: String) -> bool:
    if part.is_empty() or not entity.wounds.has(part) or entity.wounds[part].is_empty():
        return false
    if entity.tourniquet_applied.has(part):
        return false
    if entity.bandaged_parts.get(part, false) or entity.packed_parts.get(part, false):
        return false
    if _BodyPartQuery.is_limb(part) and is_tourniquet_indicated_for_part(entity, part):
        return false
    if not has_direct_pressure_on_part(entity, part):
        return false
    for injury in entity.wounds[part]:
        if injury.get("current_bleeding_rate", 0.0) > _Bleeding.BLEEDING_RATE_EPSILON:
            return true
    return false


static func apply_stabilize(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
    if part.is_empty() or not entity.wounds.has(part):
        return false
    if not can_apply_stabilize(entity, part):
        return false
    var pressure_held: bool = has_direct_pressure_on_part(entity, part)
    var throwaway_marks: Dictionary = {}
    var r: Dictionary = _apply_stabilizing_treatment(
        entity,
        part,
        effectiveness,
        _Bleeding.STABILIZE_SUCCESS_BASE_CHANCE,
        _Bleeding.STABILIZE_SUCCESS_ARTERIAL_MULT,
        _Bleeding.STABILIZE_ARTERIAL_EFFECTIVENESS_MULT,
        _Bleeding.STABILIZE_IMMEDIATE_REDUCTION,
        throwaway_marks,
        pressure_held,
        false
    )
    if r.success:
        log_medical_session("%s apply_stabilize(%s) => success, %d wound(s)" % [entity.name, part, r.wound_count])
    else:
        log_medical_session("%s apply_stabilize(%s) => failed, %d wound(s)" % [entity.name, part, r.wound_count])
    return r.success


# --- Packing ---


static func _wound_severity_rank(severity: String) -> int:
    return int(_Bleeding.PACKING_MIN_SEVERITY_RANK.get(str(severity), 0))


static func _injury_in_strict_packing_sub_region(part: String, injury: Dictionary) -> bool:
    var sr: String = injury.get("sub_region", "")
    if sr.is_empty():
        return false
    var strict_list: Variant = _Bleeding.PACKING_STRICT_SUB_REGIONS.get(part, [])
    if not (strict_list is Array):
        return false
    for strict_sr in strict_list:
        if str(strict_sr) == sr:
            return true
    return false


## One wound channel eligible for pack: moderate+ default; junctional neck/abdominal need severe+ unless arterial.
static func injury_meets_packing_severity(part: String, injury: Dictionary) -> bool:
    if injury is not Dictionary:
        return false
    var rank: int = _wound_severity_rank(str(injury.get("severity", _Bleeding.SEVERITY_MODERATE)))
    var min_rank: int = _wound_severity_rank(_Bleeding.PACKING_MIN_SEVERITY)
    if _injury_in_strict_packing_sub_region(part, injury):
        if injury.get("is_arterial", false):
            return rank >= min_rank
        return rank >= _wound_severity_rank(_Bleeding.PACKING_STRICT_SUB_REGION_MIN_SEVERITY)
    return rank >= min_rank


static func part_meets_packing_severity(entity: Node, part: String) -> bool:
    if not entity.wounds.has(part):
        return false
    for injury in entity.wounds[part]:
        if injury_meets_packing_severity(part, injury):
            return true
    return false


## Deep / multi-channel cavities: success chance scales down (channels already extend application time).
static func packing_channel_success_mult(entity: Node, part: String) -> float:
    var n: int = get_treatment_channel_count(entity, part)
    return pow(_Bleeding.PACKING_SUCCESS_PER_EXTRA_CHANNEL, maxi(0, n - 1))


static func has_linen_for_packing(entity: Node) -> bool:
    return int(entity.get("linen_strips_remaining")) >= _Bleeding.PACKING_LINEN_COST_PER_ATTEMPT


static func can_apply_packing(entity: Node, part: String) -> bool:
    if part not in _Bleeding.PACKING_PARTS:
        return false
    if not entity.wounds.has(part) or entity.wounds[part].is_empty():
        return false
    if not part_meets_packing_severity(entity, part):
        return false
    if not has_linen_for_packing(entity):
        return false
    if entity.tourniquet_applied.has(part) or part_is_bandaged(entity, part) or part_is_packed(entity, part):
        return false
    if _compression_required_before_dressing(entity, part):
        return false
    return true


static func apply_packing(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
    if not can_apply_packing(entity, part):
        return false
    entity.linen_strips_remaining = maxi(
        0, int(entity.linen_strips_remaining) - _Bleeding.PACKING_LINEN_COST_PER_ATTEMPT
    )
    var pressure_held: bool = has_direct_pressure_on_part(entity, part)
    var eff: float = effectiveness * packing_channel_success_mult(entity, part)
    var r = _apply_stabilizing_treatment(
        entity,
        part,
        eff,
        _Bleeding.PACKING_SUCCESS_BASE_CHANCE,
        _Bleeding.PACKING_SUCCESS_ARTERIAL_MULT,
        _Bleeding.PACKING_ARTERIAL_EFFECTIVENESS_MULT,
        _Bleeding.PACKING_IMMEDIATE_REDUCTION,
        entity.packed_parts,
        pressure_held
    )
    if r.success:
        clear_direct_pressure(entity)
        log_medical_session("%s apply_packing(%s) => success, %d wound(s) packed" % [entity.name, part, r.wound_count])
    else:
        log_medical_session(
            (
                "%s apply_packing(%s) => failed (%.0f%% reduction), %d wound(s); can retry"
                % [entity.name, part, r.reduction * 100, r.wound_count]
            )
        )
    return r.success


static func get_packing_application_time_seconds_for_part(entity: Node, part: String) -> float:
    return _get_application_time_for_part(
        entity, part, _Bleeding.PACKING_APPLICATION_TIME_SECONDS, _Bleeding.PACKING_PER_WOUND_EXTRA_SECONDS
    )


# --- Direct pressure ---


## Internal: applies direct pressure wound reduction to injuries. Mutates entity.wounds in place.
static func _apply_direct_pressure_to_wounds(entity: Node, part: String, effectiveness: float) -> void:
    effectiveness = clampf(effectiveness, 0.0, 1.5)
    for injury in entity.wounds[part]:
        var eff: float = effectiveness
        if injury.get("is_arterial", false):
            eff *= _Bleeding.DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT
        var reduction: float = _Bleeding.DIRECT_PRESSURE_IMMEDIATE_REDUCTION * clampf(eff, 0.0, 1.0)
        var rate: float = injury.get("current_bleeding_rate", 0.0)
        injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - reduction))
        # Pressure slows bleed while held; bandage / pack set is_stabilized (stabilize trims rate only).


## Before bandage/pack/tourniquet wind-up: free the treater's hands without dropping compression on the wound being treated.
## Preserves ally-held pressure on `part` when the treater is also the patient (TCCC: do not release until dressing controls bleed).
static func prepare_for_medical_windup(performer: Node, target: Node, part: String) -> void:
    if performer == null or target == null or part.is_empty():
        return
    if performer.direct_pressure_on_ally.has("node") and performer.direct_pressure_on_ally.has("part"):
        var on_node: Node = performer.direct_pressure_on_ally.get("node")
        var on_part: String = performer.direct_pressure_on_ally.get("part", "")
        if on_node != target or on_part != part:
            if on_node != null and not on_part.is_empty() and "direct_pressure_part" in on_node:
                if on_node.direct_pressure_part == on_part:
                    if "direct_pressure_held_by" in on_node:
                        on_node.direct_pressure_held_by = null
                    on_node.direct_pressure_part = ""
                    _EntityWounds.rebound_bleeding_after_pressure_release(on_node, on_part)
            performer.direct_pressure_on_ally = {}
    if performer == target:
        if not performer.self_direct_pressure_part.is_empty() and performer.self_direct_pressure_part != part:
            release_direct_pressure_on_part(performer, performer.self_direct_pressure_part)
        return
    if not performer.self_direct_pressure_part.is_empty():
        release_direct_pressure_on_part(performer, performer.self_direct_pressure_part)


## Drops pressure **only** on `part` (ally-held or self). Other limbs keep their hold.
## Lets one unit hold bleeding while another applies a bandage/pack/tourniquet; the next pressure application on this part replaces the prior holder cleanly.
static func release_direct_pressure_on_part(entity: Node, part: String) -> void:
    if part.is_empty():
        return
    if entity.direct_pressure_part == part:
        if entity.direct_pressure_held_by != null and "direct_pressure_on_ally" in entity.direct_pressure_held_by:
            entity.direct_pressure_held_by.direct_pressure_on_ally = {}
        entity.direct_pressure_held_by = null
        if entity.get("direct_pressure_assist_held_by") != null:
            var assist: Variant = entity.direct_pressure_assist_held_by
            if assist != null and "direct_pressure_on_ally" in assist:
                assist.direct_pressure_on_ally = {}
            entity.direct_pressure_assist_held_by = null
        entity.direct_pressure_part = ""
        _EntityWounds.rebound_bleeding_after_pressure_release(entity, part)
        log_medical_session(
            "%s released direct pressure on %s (bleeding resumes without dressing)" % [entity.name, part]
        )
    if entity.self_direct_pressure_part == part:
        entity.self_direct_pressure_part = ""
        _EntityWounds.rebound_bleeding_after_pressure_release(entity, part)
        log_medical_session("%s released self pressure on %s (bleeding resumes without dressing)" % [entity.name, part])


## True when **`assist_entity`** may add treatment-assist pressure without displacing **`direct_pressure_held_by`**.
static func stack_assist_pressure_eligible(entity: Node, part: String, assist_entity: Node = null) -> bool:
    if part.is_empty() or not entity.wounds.has(part):
        return false
    if entity.direct_pressure_part != part or entity.direct_pressure_held_by == null:
        return false
    if assist_entity == null or entity.direct_pressure_held_by == assist_entity:
        return false
    if entity.get("direct_pressure_assist_held_by") != null and entity.direct_pressure_assist_held_by != null:
        return false
    if part_is_bandaged(entity, part) or part_is_packed(entity, part):
        return false
    if (
        entity.tourniquet_applied.has(part)
        and entity.get_bleeding_rate_for_part(part) <= _Bleeding.BLEEDING_RATE_EPSILON
    ):
        return false
    return true


## Helper already holds `part`; treater stacks extra pressure + `direct_pressure_assist_held_by` without displacing the helper.
static func stack_assist_pressure_during_ally_treatment(entity: Node, part: String, assist_entity: Node = null) -> bool:
    if not stack_assist_pressure_eligible(entity, part, assist_entity):
        return false
    var eff: float = (
        _EntityAccess.get_medical_effectiveness_from_node(assist_entity)
        * _CombatConstants.DIRECT_PRESSURE_TREATMENT_ASSIST_EFFECTIVENESS_FRACTION
    )
    _apply_direct_pressure_to_wounds(entity, part, eff)
    entity.direct_pressure_assist_held_by = assist_entity
    if assist_entity != null and "direct_pressure_on_ally" in assist_entity:
        assist_entity.direct_pressure_on_ally = {"node": entity, "part": part}
    log_medical_session(
        (
            "treatment_assist_pressure %s stacks on %s (assist mult=%.2f)"
            % [entity.name, part, _CombatConstants.DIRECT_PRESSURE_TREATMENT_ASSIST_EFFECTIVENESS_FRACTION]
        )
    )
    return true


static func can_apply_direct_pressure(entity: Node, target_part: String) -> bool:
    if part_is_bandaged(entity, target_part) or part_is_packed(entity, target_part):
        return false
    if entity.get_bleeding_rate_for_part(target_part) <= _Bleeding.BLEEDING_RATE_EPSILON:
        return false
    if entity.tourniquet_applied.has(target_part):
        return false
    var arm: String = entity.get_attacking_arm()
    if arm.is_empty():
        return false
    if _BodyPartQuery.is_arm(target_part):
        if arm == target_part:
            return false
    return true


static func can_apply_direct_pressure_from_ally(entity: Node, part: String, performer_entity: Node = null) -> bool:
    if performer_entity == null or part.is_empty() or not entity.wounds.has(part):
        return false
    if part_is_bandaged(entity, part) or part_is_packed(entity, part):
        return false
    if entity.tourniquet_applied.has(part):
        return false
    if entity.get_bleeding_rate_for_part(part) <= _Bleeding.BLEEDING_RATE_EPSILON:
        return false
    return true


static func apply_direct_pressure_from_ally(entity: Node, part: String, performer_entity: Node = null) -> bool:
    if part.is_empty() or not entity.wounds.has(part):
        return false
    if not can_apply_direct_pressure_from_ally(entity, part, performer_entity):
        return false
    if part_is_bandaged(entity, part) or part_is_packed(entity, part):
        return false
    if (
        entity.tourniquet_applied.has(part)
        and entity.get_bleeding_rate_for_part(part) <= _Bleeding.BLEEDING_RATE_EPSILON
    ):
        return false
    release_direct_pressure_on_part(entity, part)
    var effectiveness: float = _EntityAccess.get_medical_effectiveness_from_node(performer_entity)
    _apply_direct_pressure_to_wounds(entity, part, effectiveness)
    entity.direct_pressure_part = part
    entity.direct_pressure_held_by = performer_entity
    log_medical_session(
        (
            "%s direct_pressure_from_ally part=%s (TCCC sustained compression; venous ~%.0f%% / arterial ~%.0f%% flow retained while held)"
            % [
                entity.name,
                part,
                _Bleeding.DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS * 100.0,
                _Bleeding.DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL * 100.0,
            ]
        )
    )
    return true


static func apply_direct_pressure(entity: Node, part: String, effectiveness: float = -1.0) -> bool:
    if part.is_empty() or not entity.wounds.has(part):
        return false
    if not can_apply_direct_pressure(entity, part):
        return false
    release_direct_pressure_on_part(entity, part)
    if effectiveness < 0.0:
        effectiveness = _EntityAccess.get_medical_effectiveness_from_node(entity)
    _apply_direct_pressure_to_wounds(entity, part, effectiveness)
    entity.self_direct_pressure_part = part
    log_medical_session(
        (
            "%s direct_pressure self part=%s (TCCC sustained compression; venous ~%.0f%% / arterial ~%.0f%% flow retained while held)"
            % [
                entity.name,
                part,
                _Bleeding.DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS * 100.0,
                _Bleeding.DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL * 100.0,
            ]
        )
    )
    return true


static func is_applying_direct_pressure(entity: Node) -> bool:
    return (
        not entity.direct_pressure_part.is_empty()
        or not entity.self_direct_pressure_part.is_empty()
        or not entity.direct_pressure_on_ally.is_empty()
    )


static func has_direct_pressure_on_part(entity: Node, part: String) -> bool:
    return part == entity.self_direct_pressure_part or part == entity.direct_pressure_part


static func get_direct_pressure_part(entity: Node) -> String:
    if not entity.self_direct_pressure_part.is_empty():
        return entity.self_direct_pressure_part
    if entity.direct_pressure_on_ally.has("part"):
        return entity.direct_pressure_on_ally.get("part", "")
    return entity.direct_pressure_part


static func clear_direct_pressure(entity: Node) -> void:
    var rebound_self: Array = []
    if not entity.direct_pressure_part.is_empty():
        rebound_self.append(entity.direct_pressure_part)
    if not entity.self_direct_pressure_part.is_empty() and entity.self_direct_pressure_part not in rebound_self:
        rebound_self.append(entity.self_direct_pressure_part)
    if entity.get("direct_pressure_assist_held_by") != null and entity.direct_pressure_assist_held_by != null:
        var assist_clear: Variant = entity.direct_pressure_assist_held_by
        if assist_clear != null and "direct_pressure_on_ally" in assist_clear:
            assist_clear.direct_pressure_on_ally = {}
        entity.direct_pressure_assist_held_by = null
    if entity.direct_pressure_held_by != null and "direct_pressure_on_ally" in entity.direct_pressure_held_by:
        entity.direct_pressure_held_by.direct_pressure_on_ally = {}
        entity.direct_pressure_held_by = null
    if not entity.direct_pressure_part.is_empty():
        log_medical_session(
            "%s clear_direct_pressure (ally was holding %s)" % [entity.name, entity.direct_pressure_part]
        )
    entity.direct_pressure_part = ""
    if not entity.self_direct_pressure_part.is_empty():
        log_medical_session(
            "%s clear_direct_pressure (was self-holding %s)" % [entity.name, entity.self_direct_pressure_part]
        )
    entity.self_direct_pressure_part = ""
    if entity.direct_pressure_on_ally.has("node") and entity.direct_pressure_on_ally.has("part"):
        var ally_entity = entity.direct_pressure_on_ally.get("node")
        var ally_part: String = entity.direct_pressure_on_ally.get("part", "")
        if ally_entity != null and "direct_pressure_part" in ally_entity:
            _EntityWounds.rebound_bleeding_after_pressure_release(ally_entity, ally_part)
            ally_entity.direct_pressure_part = ""
            if "direct_pressure_held_by" in ally_entity:
                ally_entity.direct_pressure_held_by = null
            if ally_entity.get("direct_pressure_assist_held_by") != null:
                var asst_rel: Variant = ally_entity.direct_pressure_assist_held_by
                if asst_rel != null and "direct_pressure_on_ally" in asst_rel:
                    asst_rel.direct_pressure_on_ally = {}
                ally_entity.direct_pressure_assist_held_by = null
            log_medical_session("%s released direct_pressure on ally's %s" % [entity.name, ally_part])
    entity.direct_pressure_on_ally = {}
    for part_rb in rebound_self:
        _EntityWounds.rebound_bleeding_after_pressure_release(entity, part_rb)


# --- Tourniquet ---


static func is_tourniquet_indicated_for_part(entity: Node, part: String) -> bool:
    if not _BodyPartQuery.is_limb(part) or not entity.wounds.has(part) or entity.wounds[part].is_empty():
        return false
    for injury in entity.wounds[part]:
        if injury.get("is_stump", false):
            return true
    for injury in entity.wounds[part]:
        var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
        if sev == _Bleeding.SEVERITY_SEVERE or sev == _Bleeding.SEVERITY_CRITICAL:
            return true
    if entity.get_bleeding_rate_for_part(part) >= _Bleeding.TOURNIQUET_BLEEDING_RATE_THRESHOLD:
        return true
    return false


static func can_apply_tourniquet(entity: Node, part: String) -> bool:
    if not _BodyPartQuery.is_limb(part):
        return false
    if not entity.wounds.has(part) or entity.wounds[part].is_empty():
        return false
    if entity.tourniquet_applied.has(part) or part_is_bandaged(entity, part) or part_is_packed(entity, part):
        return false
    return true


## Normalizes float timestamp storage to { "applied_at", "effectiveness" } (e.g. older save data).
static func ensure_tourniquet_dict_entry(entity: Node, part: String) -> void:
    if not entity.tourniquet_applied.has(part):
        return
    var data = entity.tourniquet_applied[part]
    if data is float or data is int:
        entity.tourniquet_applied[part] = {"applied_at": float(data), "effectiveness": 1.0}


static func is_tourniquet_applied(entity: Node, part: String) -> bool:
    return entity.tourniquet_applied.has(part)


static func apply_tourniquet(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
    if not can_apply_tourniquet(entity, part):
        return false
    effectiveness = clampf(effectiveness, 0.0, 1.5)
    var success_chance: float = _Bleeding.TOURNIQUET_SUCCESS_BASE_CHANCE * effectiveness
    # Escalating retry chance: +15% per prior failure on same part (medic adjusts placement).
    var fail_count: int = 0
    if entity.has_method("get_tourniquet_failures"):
        fail_count = int(entity.get_tourniquet_failures(part, 0))
    success_chance += _Bleeding.TOURNIQUET_RETRY_SUCCESS_BONUS * fail_count
    success_chance = clampf(success_chance, 0.0, 1.0)
    var success: bool = randf() < success_chance
    if success:
        clear_direct_pressure(entity)
        var eff_clamped: float = clampf(effectiveness, 0.0, 1.0)
        entity.tourniquet_applied[part] = {"applied_at": entity.get_game_time_seconds(), "effectiveness": eff_clamped}
        if fail_count > 0:
            if entity.has_method("get_tourniquet_failures"):
                var fails_dict: Dictionary = entity.tourniquet_failures as Dictionary
                fails_dict.erase(part)
            elif entity.has_method("set_tourniquet_failures"):
                entity.set_tourniquet_failures(part, 0)
        var reduction_pct: float = eff_clamped * _Bleeding.TOURNIQUET_REDUCTION_AT_FULL * 100.0
        log_medical_session(
            (
                "%s apply_tourniquet(%s) => success eff=%.2f => %.0f%% bleed reduction"
                % [entity.name, part, eff_clamped, reduction_pct]
            )
        )
    else:
        # Partial bleed reduction on failure: failed TQ still partially occludes the vessel.
        var partial_reduction: float = (
            _Bleeding.TOURNIQUET_FAILED_REDUCTION_MULT
            * clampf(effectiveness, 0.0, 1.0)
            * _Bleeding.TOURNIQUET_REDUCTION_AT_FULL
        )
        for injury in entity.wounds.get(part, []):
            var rate: float = injury.get("current_bleeding_rate", 0.0)
            injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - partial_reduction))
        # Track failure count for escalating retry chance.
        if entity.has_method("get_tourniquet_failures"):
            var fails_dict: Dictionary = entity.tourniquet_failures as Dictionary
            fails_dict[part] = fail_count + 1
            entity.tourniquet_failures = fails_dict
        elif entity.has_method("set_tourniquet_failures"):
            entity.set_tourniquet_failures(part, fail_count + 1)
        log_medical_session(
            (
                "%s apply_tourniquet(%s) => failed (not tight enough; %.0f%% partial occlusion); can retry"
                % [entity.name, part, partial_reduction * 100]
            )
        )
    return success


static func remove_tourniquet(entity: Node, part: String) -> void:
    entity.tourniquet_applied.erase(part)


static func get_tourniquet_application_time_seconds() -> float:
    return _Bleeding.TOURNIQUET_APPLICATION_TIME_SECONDS
