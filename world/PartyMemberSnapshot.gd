class_name PartyMemberSnapshot
extends RefCounted

## Builds party member display dicts from nodes. Reduces duplication between PartyManager.add_member
## and get_members. Single source for entity→display snapshot logic.
## Uses CombatantStatsSync for base stats (single source of truth with combat registration).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")

static func init_from_node(node: Node) -> Dictionary:
	"""Returns stored member dict for PartyManager.members. Call when adding a member."""
	var member_name: String = "Unnamed"
	if node and "name" in node:
		member_name = node.name
	var base := _read_from_node(node)
	base["name"] = member_name
	base["node_ref"] = node
	base["company_mood"] = _CompanyState.MOOD_DEFAULT
	return base

## Returns full display dict for get_members. Prefers node_ref when valid; else uses member's stored values.
static func snapshot_from_member(member: Dictionary) -> Dictionary:
	var node_ref = member.get("node_ref")
	var result: Dictionary
	if is_instance_valid(node_ref) and node_ref is Node:
		result = _read_from_node(node_ref).duplicate()
		result["name"] = member.get("name", "Unknown")
		result["weapon_name"] = _EntityAccess.get_weapon_display_name_from_node(node_ref)
		result["armor_summary"] = _EntityAccess.get_armor_summary_from_node(node_ref)
		result["blood_volume"] = _EntityAccess.get_blood_volume_from_node(node_ref)
		result["total_bleeding_rate"] = _EntityAccess.get_total_bleeding_rate_from_node(node_ref)
		var entity: Node = _CampaignBridge.health_entity_from_character(node_ref)
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
			"strength": member.get("strength", 100),
			"agility": member.get("agility", 100),
			"intelligence": member.get("intelligence", 100),
			"endurance": member.get("endurance", 100),
			"perception": member.get("perception", 100),
			"weapon_name": "",
			"armor_summary": [],
			"blood_volume": 100.0,
			"total_bleeding_rate": 0.0
		}
		result["node_ref"] = node_ref
		result["affliction_labels"] = PackedStringArray()
		result["affliction_effects"] = ""
		if member.has("company_mood"):
			result["company_mood"] = member.get("company_mood", _CompanyState.MOOD_DEFAULT)
	if member.has("company_mood") and not result.has("company_mood"):
		result["company_mood"] = member.get("company_mood", _CompanyState.MOOD_DEFAULT)
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
		var sm: float = float(def.get("stamina_mult", 1.0))
		var pm: float = float(def.get("pain_mult", 1.0))
		if absf(sm - 1.0) > 0.02:
			bits.append("Stamina ×%.0f%%" % (sm * 100.0))
		if absf(pm - 1.0) > 0.02:
			bits.append("Pain ×%.0f%%" % (pm * 100.0))
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
	var stats: Dictionary = _StatsSync.sync_from_entity_for_register(node)
	var entity: Node = _CampaignBridge.health_entity_from_character(node)
	if entity != null:
		_StatsSync.sync_from_entity(entity, stats)
		var wounded: Array = (
			entity.get_wounded_parts() if entity.has_method("get_wounded_parts") else []
		)
		stats["wounded_part_count"] = wounded.size()
		stats["has_untreated_wounds"] = _CampaignBridge.entity_has_untreated_wounds(entity)
	else:
		stats["wounded_part_count"] = 0
		stats["has_untreated_wounds"] = false
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
	return stats
