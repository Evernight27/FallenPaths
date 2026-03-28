class_name CombatantEntityAccess
extends RefCounted

## Centralized access to combatant node/entity for weapon, armor, performance, etc.
## Reduces repeated node.has_method("get_weapon") patterns across AttackResolver, DefenseChoiceResolver, etc.

## Returns weapon from combatant's node, or null if node lacks get_weapon or is null.
static func get_weapon(combatant: Dictionary) -> Variant:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_weapon"):
		return null
	return node.get_weapon()

## Returns entity (health/wounds holder) from manager. Use manager._get_entity(combatant.node) when manager available.
static func get_entity_from_manager(manager: Node, combatant: Dictionary) -> Node:
	var node = combatant.get("node", null)
	if node == null:
		return null
	if manager.has_method("_get_entity"):
		return manager._get_entity(node)
	return node

## Returns display name for logging/debug: node.name if available, else "id:{id}". Pass fallback_id when combatant may be null.
static func get_display_name(combatant: Variant, fallback_id: int = -1) -> String:
	if combatant == null or not (combatant is Dictionary):
		return "id:%d" % fallback_id
	var node = combatant.get("node", null)
	if node != null:
		return str(node.name)
	return "id:%d" % combatant.get("id", fallback_id)

## Returns true if combatant's node has a weapon.
static func has_weapon(combatant: Dictionary) -> bool:
	return get_weapon(combatant) != null

## Returns weapon from node directly. Use when caller has node (not combatant dict).
static func get_weapon_from_node(node: Node) -> Variant:
	if node == null or not node.has_method("get_weapon"):
		return null
	return node.get_weapon()

## Returns armor slots from node. Use when caller has node (not combatant dict).
static func get_armor_slots_from_node(node: Node) -> Dictionary:
	if node == null or not node.has_method("get_armor_slots"):
		return {}
	return node.get_armor_slots()

## Returns weapon display name for UI. Empty if no weapon or node unavailable.
static func get_weapon_display_name_from_node(node: Node) -> String:
	var w = get_weapon_from_node(node)
	if w == null:
		return ""
	if "display_name" in w and w.display_name:
		return str(w.display_name)
	if "weapon_type" in w:
		return str(w.weapon_type)
	return "?"

## Returns armor piece display names for UI (e.g. ["Cuirass", "Gambeson"]).
static func get_armor_summary_from_node(node: Node) -> Array:
	var slots: Dictionary = get_armor_slots_from_node(node)
	var names: Array = []
	for part in slots.keys():
		var piece = slots[part]
		if piece != null and "display_name" in piece and piece.display_name:
			names.append(piece.display_name)
	return names


## Sum of equipped ArmorPiece.get_total_mass_kg() — formation moves, encumbrance tuning.
static func get_total_armor_mass_kg_from_node(node: Node) -> float:
	if node == null or not node.has_method("get_armor_slots"):
		return 0.0
	var slots: Dictionary = node.get_armor_slots()
	var total: float = 0.0
	for part in slots.keys():
		var piece = slots[part]
		if piece != null and piece.has_method("get_total_mass_kg"):
			total += piece.get_total_mass_kg()
	return total

## Returns performance modifier (pain/consciousness) from combatant's node. Default 1.0 if unavailable.
static func get_performance_modifier(combatant: Dictionary) -> float:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_performance_modifier"):
		return 1.0
	return node.get_performance_modifier()

## Returns hit-chance-specific performance modifier. Falls back to get_performance_modifier if unavailable.
static func get_hit_chance_performance_modifier(combatant: Dictionary) -> float:
	var node = combatant.get("node", null)
	if node == null:
		return 1.0
	if node.has_method("get_hit_chance_performance_modifier"):
		return node.get_hit_chance_performance_modifier()
	if node.has_method("get_performance_modifier"):
		return node.get_performance_modifier()
	return 1.0

## Returns attacking arm (e.g. "right_arm") or "" if none. Empty = no functional arm.
static func get_attacking_arm(combatant: Dictionary) -> String:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_attacking_arm"):
		return ""
	return node.get_attacking_arm()

## Returns leg functionality 0–1. Default 1.0 if unavailable.
static func get_leg_functionality(combatant: Dictionary) -> float:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_leg_functionality"):
		return 1.0
	return node.get_leg_functionality()

## Returns targetable body parts array. Empty if unavailable.
static func get_targetable_parts(combatant: Dictionary) -> Array:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_targetable_parts"):
		return []
	return node.get_targetable_parts()

## Returns true if combatant's node is incapacitated (consciousness/cowering).
static func is_incapacitated(combatant: Dictionary) -> bool:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("is_incapacitated"):
		return false
	return node.is_incapacitated()

## Returns part-specific dodge modifier. Default 1.0 if unavailable.
static func get_part_dodge_modifier(combatant: Dictionary, part: String) -> float:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_part_dodge_modifier"):
		return 1.0
	return node.get_part_dodge_modifier(part)

## Returns dodge chance 0–1. Default 0.0 if unavailable.
static func get_dodge_chance(combatant: Dictionary) -> float:
	var node = combatant.get("node", null)
	if node == null or not node.has_method("get_dodge_chance"):
		return 0.0
	return node.get_dodge_chance()

## Returns blood volume 0–100 from node. Default 100.0 if unavailable.
static func get_blood_volume_from_node(node: Node) -> float:
	if node == null:
		return 100.0
	if node.has_method("get_blood_volume"):
		return node.get_blood_volume()
	if "blood_volume" in node:
		return float(node.blood_volume)
	return 100.0

## Returns total bleeding rate from node. Default 0.0 if unavailable.
static func get_total_bleeding_rate_from_node(node: Node) -> float:
	if node == null:
		return 0.0
	if node.has_method("get_total_bleeding_rate"):
		return node.get_total_bleeding_rate()
	return 0.0

## Returns medical effectiveness 0–1.5 from node. Default 1.0 if unavailable.
static func get_medical_effectiveness_from_node(node: Node) -> float:
	if node == null:
		return 1.0
	if node.has_method("get_medical_effectiveness"):
		return node.get_medical_effectiveness()
	return 1.0

## Returns permanent bleeding rate from node. Default fallback if unavailable.
static func get_permanent_bleeding_rate_from_node(node: Node, fallback: float = 0.0) -> float:
	if node == null:
		return fallback
	if node.has_method("get_permanent_bleeding_rate"):
		return node.get_permanent_bleeding_rate()
	return fallback
