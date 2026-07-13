class_name CampaignAfflictions
extends RefCounted

## Post-victory permanent injuries (Camp-2.4 / XCamp-3.4 catalog).
## Tier RNG from [guide affliction table](../../docs/CAMPAIGN_DECISION_GUIDE.md#affliction-rng-medieval-alignment).
## Canonical: `apply_after_victory` . `format_scar_line` . `count_scarred_brothers`.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _Bridge := preload("res://world/CampaignEncounterBridge.gd")

# Runtime preload -- circular dependency (CompanyState preloads CampaignAfflictions).
static var _CompanyState: Variant = null


static func _get_company_state() -> GDScript:
    if CampaignAfflictions._CompanyState == null:
        CampaignAfflictions._CompanyState = load("res://world/CompanyState.gd")
    return CampaignAfflictions._CompanyState


const AFFLICTION_SLOWED_CIRCULATION := "slowed_circulation"
const AFFLICTION_OLD_WOUND_ACHE := "old_wound_ache"
const AFFLICTION_LIMPING_LIMB := "limping_limb"
const AFFLICTION_PARTLY_COLLAPSED_LUNG := "partly_collapsed_lung"
const AFFLICTION_SHAKY_GRIP := "shaky_grip"
const AFFLICTION_CRACKED_RIBS := "cracked_ribs"

const P_PERIL := 0.30
const P_DANGER := 0.12
const P_BONE_CRIPPLE := 0.45
const P_ARTERIAL_FAIL := 0.55
const P_STRUCK_DOWN := 0.33
const P_CAP := 0.55
const P_COLLAPSED_LUNG_SPLIT := 0.35

const CATALOG_IDS: Array[String] = [
    AFFLICTION_SLOWED_CIRCULATION,
    AFFLICTION_OLD_WOUND_ACHE,
    AFFLICTION_LIMPING_LIMB,
    AFFLICTION_PARTLY_COLLAPSED_LUNG,
    AFFLICTION_SHAKY_GRIP,
    AFFLICTION_CRACKED_RIBS,
]


static func apply_after_victory(world: Node2D, rng: RandomNumberGenerator) -> PackedStringArray:
    var lines: PackedStringArray = PackedStringArray()
    if not _get_company_state().read_stub_afflictions_enabled():
        return lines
    if world == null or rng == null:
        return lines
    for n in _Bridge.get_fightable_party_nodes(world):
        var entity: Node = _Bridge.health_entity_from_character(n)
        if entity == null:
            continue
        var roll: Dictionary = _roll_affliction_for_entity(entity, n, rng)
        if roll.is_empty():
            continue
        if not entity.has_method("add_campaign_affliction"):
            continue
        if entity.add_campaign_affliction(roll):
            var name_s: String = str(n.name)
            lines.append(format_scar_line(name_s, roll))
            _get_company_state().adjust_member_mood(world, name_s, -1.35)
    return lines


static func count_scarred_brothers(world: Node2D) -> int:
    if world == null:
        return 0
    var n: int = 0
    for node in _Bridge.get_fightable_party_nodes(world):
        var entity: Node = _Bridge.health_entity_from_character(node)
        if entity == null or not ("campaign_afflictions" in entity):
            continue
        if entity.campaign_afflictions is Array and not (entity.campaign_afflictions as Array).is_empty():
            n += 1
    return n


static func format_scar_line(member_name: String, def: Dictionary) -> String:
    var label: String = str(def.get("label", def.get("id", "?")))
    var fx: String = _effect_suffix(def)
    if fx.is_empty():
        return "%s  -  %s" % [member_name, label]
    return "%s  -  %s (%s)" % [member_name, label, fx]


static func catalog_def(id: String, bone_part: String = "") -> Dictionary:
    return _affliction_def(id, bone_part)


static func _roll_affliction_for_entity(entity: Node, character: Node, rng: RandomNumberGenerator) -> Dictionary:
    var blood: float = 100.0
    if "blood_volume" in entity:
        blood = entity.blood_volume
    var p: float = 0.0
    var pick: String = AFFLICTION_SLOWED_CIRCULATION
    var bone_part: String = _worst_bone_part(entity)
    if character.has_method("is_unconscious") and character.is_unconscious():
        p = maxf(p, P_STRUCK_DOWN)
        pick = AFFLICTION_SLOWED_CIRCULATION
    if blood < _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING:
        p = maxf(p, P_PERIL)
        pick = AFFLICTION_SLOWED_CIRCULATION
    elif blood < _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING:
        p = maxf(p, P_DANGER)
        pick = (AFFLICTION_PARTLY_COLLAPSED_LUNG if rng.randf() < P_COLLAPSED_LUNG_SPLIT else AFFLICTION_OLD_WOUND_ACHE)
    if _count_untreated_arterial(entity) >= 2:
        p = maxf(p, P_ARTERIAL_FAIL)
        pick = AFFLICTION_SLOWED_CIRCULATION
    if not bone_part.is_empty():
        p = maxf(p, P_BONE_CRIPPLE)
        pick = _bone_affliction_id(bone_part)
    p = minf(p, P_CAP)
    if p <= 0.0 or rng.randf() >= p:
        return {}
    return _affliction_def(pick, bone_part)


static func _bone_affliction_id(part: String) -> String:
    var p: String = part.to_lower()
    if p.contains("leg") or p.contains("foot"):
        return AFFLICTION_LIMPING_LIMB
    if p.contains("arm") or p.contains("hand"):
        return AFFLICTION_SHAKY_GRIP
    if p.contains("chest") or p.contains("rib"):
        return AFFLICTION_CRACKED_RIBS
    return AFFLICTION_LIMPING_LIMB


static func _affliction_def(id: String, bone_part: String) -> Dictionary:
    match id:
        AFFLICTION_OLD_WOUND_ACHE:
            return {
                "id": id,
                "label": "Old wound ache",
                "stamina_mult": 1.0,
                "pain_mult": 1.08,
            }
        AFFLICTION_PARTLY_COLLAPSED_LUNG:
            return {
                "id": id,
                "label": "Partly collapsed lung",
                "stamina_mult": 0.85,
                "pain_mult": 1.0,
            }
        AFFLICTION_SHAKY_GRIP:
            return {
                "id": id,
                "label": "Shaky grip",
                "stamina_mult": 0.94,
                "pain_mult": 1.04,
                "part": bone_part,
            }
        AFFLICTION_CRACKED_RIBS:
            return {
                "id": id,
                "label": "Cracked ribs",
                "stamina_mult": 0.88,
                "pain_mult": 1.05,
                "part": bone_part,
            }
        AFFLICTION_LIMPING_LIMB:
            var limb_label: String = bone_part if not bone_part.is_empty() else "leg"
            return {
                "id": id,
                "label": "Limping %s" % limb_label,
                "stamina_mult": 0.92,
                "pain_mult": 1.0,
                "part": bone_part,
            }
        _:
            return {
                "id": AFFLICTION_SLOWED_CIRCULATION,
                "label": "Slowed circulation",
                "stamina_mult": 0.90,
                "pain_mult": 1.0,
            }


static func _effect_suffix(def: Dictionary) -> String:
    var bits: PackedStringArray = PackedStringArray()
    var sm: float = def.get("stamina_mult", 1.0)
    var pm: float = def.get("pain_mult", 1.0)
    if absf(sm - 1.0) > 0.02:
        bits.append("Stamina - - %.0f%%" % (sm * 100.0))
    if absf(pm - 1.0) > 0.02:
        bits.append("Pain - - %.0f%%" % (pm * 100.0))
    return ", ".join(bits)


static func _count_untreated_arterial(entity: Node) -> int:
    var n := 0
    if not entity.wounds is Dictionary:
        return 0
    var bandaged: Dictionary = entity.bandaged_parts if "bandaged_parts" in entity else {}
    var packed: Dictionary = entity.packed_parts if "packed_parts" in entity else {}
    var tq: Dictionary = entity.tourniquet_applied if "tourniquet_applied" in entity else {}
    for part in entity.wounds.keys():
        if bandaged.get(part, false) or packed.get(part, false) or tq.has(part):
            continue
        for injury in entity.wounds[part]:
            if injury is Dictionary and injury.get("is_arterial", false):
                n += 1
    return n


static func _worst_bone_part(entity: Node) -> String:
    var worst: String = ""
    var worst_ratio: float = 1.0
    if entity.get("bone_health") == null or entity.get("bone_max") == null:
        return ""
    for part in entity.bone_health.keys():
        var mx: float = entity.bone_max.get(part, 0)
        if mx <= 0.0:
            continue
        var ratio: float = entity.bone_health.get(part, 0.0) / mx
        if ratio <= 0.25 and ratio < worst_ratio:
            worst_ratio = ratio
            worst = part as String
    return worst
