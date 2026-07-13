class_name MapFieldCare
extends RefCounted

## Camp-2.1 map field care (D-bleed add-on): TCCC MARCH hemorrhage control on the overworld map.
## Procedure time advances `process_bleeding` + `process_blood_loss` only (no `process_healing`).
## Dressing uses `EntityMedical` / `BleedingConstants` (pressure flow retention, bandage RNG, med refund on fail).
## E3 hybrid: bandage at 0 company med uses reduced efficacy (no med consumed); pack/stabilize still require med >= 1.
## Regenerative healing belongs in camp rest (`CompanyState.try_camp_heal`) or overworld steps.

const FIELD_CARE_SECONDS := 120.0
## Procedure duration scale (2 min base - -  1.25 --'''deg* 150 s sim); hemorrhage physics only  -  not tissue healing.
const FIELD_CARE_PROCEDURE_TIME_MULT := 1.25
## Sim seconds advanced per field-care step (bleed + blood loss); UI labels stay ~2 min player-facing.
const FIELD_CARE_SIM_ADVANCE_SECONDS := FIELD_CARE_SECONDS * FIELD_CARE_PROCEDURE_TIME_MULT

# Runtime preload ' circular dependency (CompanyState |' CampaignEncounterBridge |' MapFieldCare).
static var _company_state: Variant = null


static func _get_company_state() -> GDScript:
    if MapFieldCare._company_state == null:
        MapFieldCare._company_state = load("res://world/CompanyState.gd")
    return MapFieldCare._company_state


static func can_offer_field_pressure(world: Node2D, member: Dictionary) -> bool:
    return not _first_pressure_part(world, member).is_empty()


static func can_offer_field_stabilize(world: Node2D, member: Dictionary) -> bool:
    if _get_company_state().get_medical_supplies(world) < 1:
        return false
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return false
    return not _first_stabilize_part(entity).is_empty()


static func can_offer_field_bandage(_world: Node2D, member: Dictionary) -> bool:
    return not field_bandage_part_ready(member).is_empty()


static func can_offer_field_pack(world: Node2D, member: Dictionary) -> bool:
    if _get_company_state().get_medical_supplies(world) < 1:
        return false
    return not _first_pack_part(member).is_empty()


static func can_offer_field_tourniquet(_world: Node2D, member: Dictionary) -> bool:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return false
    return not _first_tourniquet_part(entity).is_empty()


## Part ready to dress (pressure held or bleed controlled)  -  for UI labels.
static func field_bandage_part_ready(member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return ""
    return _first_bandage_part(entity)


## Part ready to pack (compression held or bleed controlled)  -  for UI labels and harness parity.
static func field_pack_part_ready(member: Dictionary) -> String:
    return _first_pack_part(member)


static func format_field_bandage_button_label(world: Node2D, member: Dictionary = {}) -> String:
    var part: String = field_bandage_part_ready(member) if not member.is_empty() else ""
    var part_s: String = _format_part_label(part)
    var entity: Node = _entity_for_member(member) if not member.is_empty() else null
    var med_bit: String = _get_company_state().format_field_bandage_med_bit(world, entity)
    if part_s.is_empty():
        return "Field bandage (%s, 2m)" % med_bit
    return "Field bandage (%s '. %s, 2m)" % [part_s, med_bit]


static func format_field_pressure_button_label(world: Node2D, member: Dictionary) -> String:
    var part: String = _first_pressure_part(world, member)
    var part_s: String = _format_part_label(part)
    if part_s.is_empty():
        return "Field pressure (2m)"
    return "Field pressure (%s '. 2m)" % part_s


static func format_field_stabilize_button_label(_world: Node2D, member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    var part: String = _first_stabilize_part(entity)
    var part_s: String = _format_part_label(part)
    if part_s.is_empty():
        return "Field stabilize (-1 med, hold only '. 2m)"
    return "Field stabilize (%s '. -1 med, hold only '. 2m)" % part_s


static func format_field_pack_button_label(_world: Node2D, member: Dictionary) -> String:
    var part: String = _first_pack_part(member)
    var part_s: String = _format_part_label(part)
    if part_s.is_empty():
        return "Field pack (-1 med, 2m)"
    return "Field pack (%s '. -1 med, 2m)" % part_s


static func format_field_tourniquet_button_label(_world: Node2D, member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    var part: String = _first_tourniquet_part(entity)
    var part_s: String = _format_part_label(part)
    if part_s.is_empty():
        return "Field tourniquet (2m)"
    return "Field tourniquet (%s '. 2m)" % part_s


static func member_untreated_part_count(member: Dictionary) -> int:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return 0
    return EntityWounds.sorted_untreated_part_names(entity).size()


## First untreated part that still needs compression before bandage (for disabled UI).
static func field_bandage_waiting_part(member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        var bleed: float = EntityWounds.get_bleeding_rate_for_part(entity, p)
        if bleed <= BleedingConstants.BLEEDING_RATE_EPSILON:
            continue
        if EntityMedical.has_direct_pressure_on_part(entity, p):
            continue
        return p
    return ""


static func format_field_bandage_waiting_label(member: Dictionary) -> String:
    var part: String = field_bandage_waiting_part(member)
    var part_s: String = _format_part_label(part)
    if part_s.is_empty():
        return "Field bandage (pressure first)"
    return "Field bandage (%s needs pressure '. 2m)" % part_s


static func format_part_list(parts: Array) -> String:
    var labels: PackedStringArray = PackedStringArray()
    for p in parts:
        var s: String = _format_part_label(str(p))
        if not s.is_empty():
            labels.append(s)
    return ", ".join(labels)


## Shown under care buttons when compression is held on a bleeding part awaiting bandage/pack.
static func format_member_pressure_held_line(member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        if not EntityMedical.has_direct_pressure_on_part(entity, p):
            continue
        # TCCC: keep showing held compression until dressed  -  local clot may drop bleed ~0 while still held.
        var part_s: String = _format_part_label(p)
        if part_s.is_empty():
            continue
        return "Pressure held on %s  -  bandage or pack when ready." % part_s
    return ""


static func format_member_field_care_hint(member: Dictionary) -> String:
    var n: int = member_untreated_part_count(member)
    if n <= 0:
        return ""
    if n == 1:
        return "One part left  -  finish dressing this brother to unlock camp rest."
    return "Highest-threat part first  -  %d untreated part(s) remain on this brother." % n


## Highest-threat wounded member across the roster (map triage ordering).
static func pick_next_triage_member(_world: Node2D, members: Array) -> Dictionary:
    var best_member: Dictionary = {}
    var best_threat: float = -1.0
    for raw in members:
        if raw is not Dictionary:
            continue
        var member: Dictionary = raw
        if member_untreated_part_count(member) <= 0:
            continue
        var entity: Node = _entity_for_member(member)
        if entity == null:
            continue
        for p in EntityWounds.sorted_untreated_part_names(entity):
            var threat: float = EntityWounds.get_part_intervention_threat(entity, str(p))
            if threat > best_threat:
                best_threat = threat
                best_member = member.duplicate(true)
    return best_member


## One MARCH step for the highest-threat untreated part (pressure --'??'' TQ --'??'' bandage when dress-ready --'??''
## pack --'??'' stabilize).
## Stabilize stays on manual buttons; treat-next finishes dressing before optional hemostatic trim.
static func try_treat_next_wound(world: Node2D, members: Array) -> bool:
    var member: Dictionary = pick_next_triage_member(world, members)
    if member.is_empty():
        return false
    if can_offer_field_pressure(world, member):
        return try_field_pressure(world, member)
    if can_offer_field_tourniquet(world, member):
        return try_field_tourniquet(world, member)
    if can_offer_field_bandage(world, member):
        return try_field_bandage(world, member)
    if can_offer_field_pack(world, member):
        return try_field_pack(world, member)
    if can_offer_field_stabilize(world, member):
        return try_field_stabilize(world, member)
    return false


static func can_treat_next_wound(world: Node2D, members: Array) -> bool:
    var member: Dictionary = pick_next_triage_member(world, members)
    if member.is_empty():
        return false
    if can_offer_field_pressure(world, member):
        return true
    if can_offer_field_tourniquet(world, member):
        return true
    if can_offer_field_bandage(world, member):
        return true
    if can_offer_field_pack(world, member):
        return true
    return can_offer_field_stabilize(world, member)


static func format_treat_next_wound_button_label(world: Node2D, members: Array) -> String:
    var member: Dictionary = pick_next_triage_member(world, members)
    if member.is_empty():
        return "Treat next wound"
    var name_s: String = str(member.get("name", "Brother"))
    var next_s: String = format_next_field_care_action(world, member)
    if next_s.is_empty():
        return "Treat next wound (%s)" % name_s
    return "Treat next  -  %s: %s" % [name_s, next_s.trim_prefix("Next: ")]


## Player-facing hint when a field-care procedure fails (RNG bandage, etc.).
static func format_field_care_retry_hint(action: String) -> String:
    return "Field %s failed  -  keep pressure if held and retry, or try another step below." % action


## Suggested next field-care action for Party row (pressure --'??'' TQ --'??'' bandage when dress-ready --'??'' pack
## --'??'' stabilize adjunct).
static func format_next_field_care_action(world: Node2D, member: Dictionary) -> String:
    if member_untreated_part_count(member) <= 0:
        return ""
    if can_offer_field_pressure(world, member):
        return "Next: %s" % format_field_pressure_button_label(world, member)
    if can_offer_field_tourniquet(world, member):
        return "Next: %s" % format_field_tourniquet_button_label(world, member)
    if can_offer_field_bandage(world, member):
        return "Next: %s" % format_field_bandage_button_label(world, member)
    if field_bandage_needs_pressure_first(member):
        return "Next: %s" % format_field_bandage_waiting_label(member)
    if can_offer_field_pack(world, member):
        return "Next: %s" % format_field_pack_button_label(world, member)
    if can_offer_field_stabilize(world, member):
        return "Next: %s" % format_field_stabilize_button_label(world, member)
    return ""


static func _format_part_label(part: String) -> String:
    if part.is_empty():
        return ""
    return str(BodyPartConstants.BODY_LABELS.get(part, part.replace("_", " ")))


## Untreated part still bleeding without compression  -  pressure must precede bandage.
static func field_bandage_needs_pressure_first(member: Dictionary) -> bool:
    return not field_bandage_waiting_part(member).is_empty()


static func try_field_pressure(world: Node2D, member: Dictionary) -> bool:
    if not can_offer_field_pressure(world, member):
        return false
    var entity: Node = _entity_for_member(member)
    var part: String = _first_pressure_part(world, member)
    if part.is_empty():
        return false
    var ok: bool = false
    var performer: Node = _default_performer_entity(world)
    if (
        performer != null
        and entity.has_method("_can_apply_direct_pressure_from_ally")
        and entity._can_apply_direct_pressure_from_ally(part, performer)
    ):
        ok = entity._apply_direct_pressure_from_ally(part, performer)
    elif entity.has_method(CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE):
        ok = entity.apply_direct_pressure(part)
    if ok:
        # Hold compression first, then advance procedure time (bleed sim runs with pressure on).
        _advance_field_care_time(entity)
        _get_company_state().refresh_hud(world)
        _log_field_care_success(world, "pressure", part, member)
    else:
        _log_field_care_failure(world, "pressure", part, member, "could not hold pressure  -  retry")
    return ok


static func try_field_stabilize(world: Node2D, member: Dictionary) -> bool:
    if not can_offer_field_stabilize(world, member):
        return false
    var entity: Node = _entity_for_member(member)
    var part: String = _first_stabilize_part(entity)
    if part.is_empty() or not entity.has_method("_apply_stabilize"):
        return false
    if not _get_company_state().consume_medical(world, 1):
        return false
    var eff: float = _get_company_state().compute_field_treatment_effectiveness(entity, world, true)
    # Hemostatic trim applies before procedure sim advance (rate reduction during compression window).
    var ok: bool = entity._apply_stabilize(part, eff)
    if not ok:
        _get_company_state().set_medical_supplies(world, _get_company_state().get_medical_supplies(world) + 1)
        _log_field_care_failure(world, "stabilize", part, member, "med refunded; hold pressure and retry")
        return false
    _advance_field_care_time(entity)
    _get_company_state().refresh_hud(world)
    if ok:
        _log_field_care_success(
            world,
            "stabilize",
            part,
            member,
            "med_left=%d still_needs_dressing" % _get_company_state().get_medical_supplies(world)
        )
    return ok


static func try_field_bandage(world: Node2D, member: Dictionary) -> bool:
    if not can_offer_field_bandage(world, member):
        return false
    var entity: Node = _entity_for_member(member)
    var part: String = field_bandage_part_ready(member)
    if part.is_empty() or not entity.has_method("_apply_bandage"):
        return false
    var consumed_med: bool = false
    if _get_company_state().get_medical_supplies(world) >= 1:
        if not _get_company_state().consume_medical(world, 1):
            return false
        consumed_med = true
    _advance_field_care_time(entity)
    var eff: float = _get_company_state().compute_field_treatment_effectiveness(entity, world, false)
    var ok: bool = entity._apply_bandage(part, eff)
    if not ok:
        if consumed_med:
            _get_company_state().set_medical_supplies(world, _get_company_state().get_medical_supplies(world) + 1)
        var pressure_note: String = (
            "pressure still held"
            if EntityMedical.has_direct_pressure_on_part(entity, part)
            else "apply pressure before retry"
        )
        var refund_note: String = "med refunded; " if consumed_med else ""
        _log_field_care_failure(world, "bandage", part, member, "%s%s" % [refund_note, pressure_note])
        return false
    _get_company_state().refresh_hud(world)
    if ok:
        _log_field_care_success(
            world,
            "bandage",
            part,
            member,
            "med_left=%d eff=%.2f" % [_get_company_state().get_medical_supplies(world), eff]
        )
    return ok


static func try_field_pack(world: Node2D, member: Dictionary) -> bool:
    if not can_offer_field_pack(world, member):
        return false
    var entity: Node = _entity_for_member(member)
    var part: String = _first_pack_part(member)
    if part.is_empty() or not entity.has_method("_apply_packing"):
        return false
    if not _get_company_state().consume_medical(world, 1):
        return false
    _advance_field_care_time(entity)
    var eff: float = _get_company_state().compute_field_treatment_effectiveness(entity, world, true)
    var ok: bool = entity._apply_packing(part, eff)
    if not ok:
        _get_company_state().set_medical_supplies(world, _get_company_state().get_medical_supplies(world) + 1)
        _log_field_care_failure(world, "pack", part, member, "med refunded; hold pressure and retry")
        return false
    _get_company_state().refresh_hud(world)
    if ok:
        _log_field_care_success(
            world, "pack", part, member, "med_left=%d" % _get_company_state().get_medical_supplies(world)
        )
    return ok


static func try_field_tourniquet(world: Node2D, member: Dictionary) -> bool:
    if not can_offer_field_tourniquet(world, member):
        return false
    var entity: Node = _entity_for_member(member)
    var part: String = _first_tourniquet_part(entity)
    if part.is_empty() or not entity.has_method("_apply_tourniquet"):
        return false
    var eff: float = _get_company_state().compute_field_treatment_effectiveness(entity, world, false)
    eff = clampf(eff, CombatConstants.FIELD_CARE_EFF_MIN, CombatConstants.FIELD_CARE_EFF_MAX)
    # TCCC: occlude limb hemorrhage first  -  do not sim 2 min of open bleed before TQ placement.
    var ok: bool = entity._apply_tourniquet(part, eff)
    if not ok:
        _log_field_care_failure(world, "tourniquet", part, member, "retry")
        return false
    _advance_field_care_time(entity)
    _get_company_state().refresh_hud(world)
    _log_field_care_success(world, "tourniquet", part, member)
    return ok


static func _advance_field_care_time(entity: Node) -> void:
    # Advance bleeding/blood_loss only, no healing
    if entity.has_method("process_bleeding"):
        entity.process_bleeding(FIELD_CARE_SIM_ADVANCE_SECONDS)
    if entity.has_method("process_blood_loss"):
        entity.process_blood_loss(FIELD_CARE_SIM_ADVANCE_SECONDS)
    if entity.has_method("ensure_consciousness_current"):
        entity.ensure_consciousness_current()


static func _log_field_care_failure(
    world: Node2D, action: String, part: String, member: Dictionary, detail: String
) -> void:
    if not OperationalLog.is_play_session_active():
        return
    var parts_left: int = CampaignEncounterBridge.party_untreated_part_count(world)
    OperationalLog.play_world(
        (
            "field_care %s failed part=%s target=%s parts_left=%d  -  %s"
            % [action, part, str(member.get("name", "?")), parts_left, detail]
        )
    )


static func _log_field_care_success(
    world: Node2D, action: String, part: String, member: Dictionary, extra: String = ""
) -> void:
    if not OperationalLog.is_play_session_active():
        return
    var parts_left: int = CampaignEncounterBridge.party_untreated_part_count(world)
    var tail: String = extra.strip_edges()
    if not tail.is_empty():
        tail = " " + tail
    if parts_left <= 0:
        tail += " all_dressed=true camp_rest_ready"
    OperationalLog.play_world(
        (
            "field_care %s part=%s target=%s seconds=%.0f parts_left=%d%s"
            % [action, part, str(member.get("name", "?")), FIELD_CARE_SIM_ADVANCE_SECONDS, parts_left, tail]
        )
    )


static func _entity_for_member(member: Dictionary) -> Node:
    var node_ref: Variant = member.get("node_ref")
    if not is_instance_valid(node_ref) or not (node_ref is Node):
        return null
    return CampaignEncounterBridge.health_entity_from_character(node_ref as Node)


static func _default_performer_entity(world: Node2D) -> Node:
    var player: Node2D = CampaignEncounterBridge.get_player(world)
    if player == null:
        return null
    return CampaignEncounterBridge.health_entity_from_character(player)


static func _first_pressure_part(world: Node2D, member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        var bleed: float = EntityWounds.get_bleeding_rate_for_part(entity, p)
        if bleed <= BleedingConstants.BLEEDING_RATE_EPSILON:
            continue
        if EntityMedical.has_direct_pressure_on_part(entity, p):
            continue
        if entity.has_method("_can_apply_direct_pressure") and entity._can_apply_direct_pressure(p):
            return p
        if entity.has_method("_can_apply_direct_pressure_from_ally"):
            var performer: Node = _default_performer_entity(world)
            if performer != null and entity._can_apply_direct_pressure_from_ally(p, performer):
                return p
    return ""


static func _first_stabilize_part(entity: Node) -> String:
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        if entity.has_method("_can_apply_stabilize") and entity._can_apply_stabilize(p):
            return p
    return ""


static func _first_bandage_part(entity: Node) -> String:
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        var bleed: float = EntityWounds.get_bleeding_rate_for_part(entity, p)
        var needs_pressure: bool = bleed > BleedingConstants.BLEEDING_RATE_EPSILON
        if needs_pressure and not EntityMedical.has_direct_pressure_on_part(entity, p):
            continue
        if entity.has_method("_can_apply_bandage") and entity._can_apply_bandage(p):
            return p
    return ""


static func _first_pack_part(member: Dictionary) -> String:
    var entity: Node = _entity_for_member(member)
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        if p not in BleedingConstants.PACKING_PARTS:
            continue
        var bleed: float = EntityWounds.get_bleeding_rate_for_part(entity, p)
        var needs_pressure: bool = bleed > BleedingConstants.BLEEDING_RATE_EPSILON
        if needs_pressure and not EntityMedical.has_direct_pressure_on_part(entity, p):
            continue
        if entity.has_method("can_apply_packing") and entity.can_apply_packing(p):
            return p
    return ""


static func _first_tourniquet_part(entity: Node) -> String:
    if entity == null:
        return ""
    for p in EntityWounds.sorted_untreated_part_names(entity):
        if not EntityMedical._is_tourniquet_indicated_for_part(entity, p):
            continue
        if entity.has_method("_can_apply_tourniquet") and entity._can_apply_tourniquet(p):
            return p
    return ""
