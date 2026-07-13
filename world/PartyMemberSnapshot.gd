class_name PartyMemberSnapshot
extends RefCounted

## Builds party member display dicts from nodes. Reduces duplication between PartyManager.add_member
## and get_members. Single source for entity|'display snapshot logic.
## Uses CombatantStatsSync for base stats (single source of truth with combat registration).


static func init_from_node(node: Node) -> Dictionary:
    """Returns stored member dict for PartyManager.members. Call when adding a member."""
    var member_name: String = "Unnamed"
    if node and "name" in node:
        member_name = node.name
    var base := _read_from_node(node)
    base["name"] = member_name
    base["node_ref"] = node
    base["company_mood"] = CampaignTypes.MOOD_DEFAULT
    return base


## Returns full display dict for get_members. Prefers node_ref when valid; else uses member's stored values.
static func snapshot_from_member(member: Dictionary) -> Dictionary:
    var node_ref = member.get("node_ref")
    var result: Dictionary
    if is_instance_valid(node_ref) and node_ref is Node:
        result = _read_from_node(node_ref).duplicate()
        result["name"] = member.get("name", "Unknown")
        result["weapon_name"] = CombatantEntityAccess.get_weapon_display_name_from_node(node_ref)
        result["armor_summary"] = CombatantEntityAccess.get_armor_summary_from_node(node_ref)
        result["blood_volume"] = CombatantEntityAccess.get_blood_volume_from_node(node_ref)
        result["total_bleeding_rate"] = CombatantEntityAccess.get_total_bleeding_rate_from_node(node_ref)
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
        if entity != null and entity.has_method("get_campaign_affliction_labels"):
            result["affliction_labels"] = entity.get_campaign_affliction_labels()
            result["affliction_effects"] = _format_affliction_effects(entity)
        else:
            result["affliction_labels"] = PackedStringArray()
            result["affliction_effects"] = ""
        result["node_ref"] = node_ref
    else:
        result = {
            "name": member.get("name", "Unknown"),
            "body_cutting": _duplicate_if_dictionary(member.get("body_cutting", null)),
            "body_blunt": _duplicate_if_dictionary(member.get("body_blunt", null)),
            "body_max": _duplicate_if_dictionary(member.get("body_max", null)),
            "bone_health": _duplicate_if_dictionary(member.get("bone_health", null)),
            "bone_max": _duplicate_if_dictionary(member.get("bone_max", null)),
            "strength": member.get("strength", CombatConstants.DEFAULT_STAT_VALUE),
            "agility": member.get("agility", CombatConstants.DEFAULT_STAT_VALUE),
            "intelligence": member.get("intelligence", CombatConstants.DEFAULT_STAT_VALUE),
            "endurance": member.get("endurance", CombatConstants.DEFAULT_STAT_VALUE),
            "perception": member.get("perception", CombatConstants.DEFAULT_STAT_VALUE),
            "weapon_name": "",
            "armor_summary": [],
            "blood_volume": 100.0,
            "total_bleeding_rate": 0.0
        }
        result["node_ref"] = node_ref
        result["affliction_labels"] = PackedStringArray()
        result["affliction_effects"] = ""
        if member.has("company_mood"):
            result["company_mood"] = member.get("company_mood", CampaignTypes.MOOD_DEFAULT)
        if member.has("stance_preference"):
            result["stance_preference"] = str(member.get("stance_preference", "")).strip_edges()
    if member.has("company_mood") and not result.has("company_mood"):
        result["company_mood"] = member.get("company_mood", CampaignTypes.MOOD_DEFAULT)
    return result


static func _format_affliction_effects(entity: Node) -> String:
    if entity == null or not ("campaign_afflictions" in entity):
        return ""
    var lines: PackedStringArray = PackedStringArray()
    for raw in entity.campaign_afflictions:
        if not raw is Dictionary:
            continue
        var def: Dictionary = raw as Dictionary
        var label: String = str(def.get("label", def.get("id", "")))
        var bits: PackedStringArray = PackedStringArray()
        var sm: float = def.get("stamina_mult", 1.0)
        var pm: float = def.get("pain_mult", 1.0)
        if absf(sm - 1.0) > 0.02:
            bits.append("Stamina f - %.0f%%" % (sm * 100.0))
        if absf(pm - 1.0) > 0.02:
            bits.append("Pain f - %.0f%%" % (pm * 100.0))
        if bits.is_empty():
            lines.append(label)
        else:
            lines.append("%s (%s)" % [label, ", ".join(bits)])
    return "; ".join(lines)


static func _duplicate_if_dictionary(v: Variant) -> Dictionary:
    if v is Dictionary:
        return (v as Dictionary).duplicate()
    return {}


static func _read_from_node(node: Node) -> Dictionary:
    var stats: Dictionary = CombatantStatsSync.sync_from_entity_for_register(node)
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node)
    if entity != null:
        CombatantStatsSync.sync_from_entity(entity, stats)
        var wounded: Array = entity.get_wounded_parts() if entity.has_method("get_wounded_parts") else []
        stats["wounded_part_count"] = wounded.size()
        stats["has_untreated_wounds"] = CampaignEncounterBridge.entity_has_untreated_wounds(entity)
        stats["untreated_parts"] = CampaignEncounterBridge.untreated_wound_part_names(entity)
    else:
        stats["wounded_part_count"] = 0
        stats["has_untreated_wounds"] = false
        stats["untreated_parts"] = PackedStringArray()
    if node != null and node.has_method("is_unconscious"):
        stats["is_unconscious"] = node.is_unconscious()
    elif entity != null and entity.has_method("is_unconscious"):
        stats["is_unconscious"] = entity.is_unconscious()
    else:
        stats["is_unconscious"] = false
    if node != null and node.has_method("can_flee_or_fall_back"):
        stats["can_flee_or_fall_back"] = node.can_flee_or_fall_back()
    else:
        stats["can_flee_or_fall_back"] = true
    var stance_pref: String = ""
    if node != null:
        var raw_pref: Variant = node.get("stance_preference")
        if raw_pref != null:
            stance_pref = str(raw_pref).strip_edges()
    stats["stance_preference"] = stance_pref
    stats["is_party_leader"] = node != null and node.get("is_party_leader") == true
    return stats
