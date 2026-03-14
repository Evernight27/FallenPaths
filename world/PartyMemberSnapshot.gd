class_name PartyMemberSnapshot
extends RefCounted

## Builds party member display dicts from nodes. Reduces duplication between PartyManager.add_member
## and get_members. Single source for entity→display snapshot logic.
## Uses CombatantStatsSync for base stats (single source of truth with combat registration).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")

static func init_from_node(node: Node) -> Dictionary:
	"""Returns stored member dict for PartyManager.members. Call when adding a member."""
	var member_name: String = "Unnamed"
	if node and "name" in node:
		member_name = node.name
	var base := _read_from_node(node)
	base["name"] = member_name
	base["node_ref"] = node
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
	else:
		result = {
			"name": member.get("name", "Unknown"),
			"body_cutting": member.get("body_cutting", {}).duplicate(),
			"body_blunt": member.get("body_blunt", {}).duplicate(),
			"body_max": member.get("body_max", {}).duplicate(),
			"bone_health": member.get("bone_health", {}).duplicate(),
			"bone_max": member.get("bone_max", {}).duplicate(),
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
	return result

static func _read_from_node(node: Node) -> Dictionary:
	# Use CombatantStatsSync for base stats — single source of truth with combat registration.
	return _StatsSync.sync_from_entity_for_register(node)
