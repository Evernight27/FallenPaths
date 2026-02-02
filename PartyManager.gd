extends Node

signal party_updated()

var members: Array = []

const BODY_PARTS := ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]

func _ready():
	pass

func add_member(node: Node) -> void:
	var member_name = "Unnamed"
	if node and "name" in node:
		member_name = node.name

	var body_cutting: Dictionary = {}
	var body_blunt: Dictionary = {}
	var body_max: Dictionary = {}
	var bone_health: Dictionary = {}
	var bone_max: Dictionary = {}
	var member_strength = 0
	var member_speed = 0

	if node:
		if "body_cutting" in node:
			body_cutting = node.body_cutting.duplicate()
		if "body_blunt" in node:
			body_blunt = node.body_blunt.duplicate()
		if "body_max" in node:
			body_max = node.body_max.duplicate()
		if "bone_health" in node:
			bone_health = node.bone_health.duplicate()
		if "bone_max" in node:
			bone_max = node.bone_max.duplicate()
		if "strength" in node:
			member_strength = node.strength
		if "speed" in node:
			member_speed = node.speed

	var m = {
		"name": member_name,
		"body_cutting": body_cutting,
		"body_blunt": body_blunt,
		"body_max": body_max,
		"bone_health": bone_health,
		"bone_max": bone_max,
		"strength": member_strength,
		"speed": member_speed,
		"node_ref": node
	}
	members.append(m)
	emit_signal("party_updated")

func remove_member_by_name(member_name: String) -> bool:
	for i in range(members.size()):
		if members[i].get("name") == member_name:
			members.remove_at(i)
			emit_signal("party_updated")
			return true
	return false

func get_members() -> Array:
	var out: Array = []
	for m in members:
		var body_cutting: Dictionary = m.get("body_cutting", {}).duplicate()
		var body_blunt: Dictionary = m.get("body_blunt", {}).duplicate()
		var body_max: Dictionary = m.get("body_max", {}).duplicate()
		var bone_health: Dictionary = m.get("bone_health", {}).duplicate()
		var bone_max: Dictionary = m.get("bone_max", {}).duplicate()
		var strength = m.get("strength", 0)
		var speed = m.get("speed", 0)
		var weapon_name: String = ""
		var armor_summary: Array = []
		var blood_volume: float = 100.0
		var total_bleeding_rate: float = 0.0
		var node_ref = m.get("node_ref")
		if is_instance_valid(node_ref) and node_ref is Node:
			if "body_cutting" in node_ref:
				body_cutting = node_ref.body_cutting.duplicate()
			if "body_blunt" in node_ref:
				body_blunt = node_ref.body_blunt.duplicate()
			if "body_max" in node_ref:
				body_max = node_ref.body_max.duplicate()
			if "bone_health" in node_ref:
				bone_health = node_ref.bone_health.duplicate()
			if "bone_max" in node_ref:
				bone_max = node_ref.bone_max.duplicate()
			if "strength" in node_ref:
				strength = node_ref.strength
			if "speed" in node_ref:
				speed = node_ref.speed
			if "blood_volume" in node_ref:
				blood_volume = node_ref.blood_volume
			if node_ref.has_method("get_total_bleeding_rate"):
				total_bleeding_rate = node_ref.get_total_bleeding_rate()
			if node_ref.has_method("get_weapon"):
				var w = node_ref.get_weapon()
				if w != null:
					weapon_name = w.display_name if w.display_name else str(w.weapon_type)
			if node_ref.has_method("get_armor_slots"):
				var slots = node_ref.get_armor_slots()
				for part in slots.keys():
					var piece = slots[part]
					if piece != null and "display_name" in piece and piece.display_name:
						armor_summary.append(piece.display_name)
		out.append({
			"name": m.get("name", "Unknown"),
			"body_cutting": body_cutting,
			"body_blunt": body_blunt,
			"body_max": body_max,
			"bone_health": bone_health,
			"bone_max": bone_max,
			"strength": strength,
			"speed": speed,
			"weapon_name": weapon_name,
			"armor_summary": armor_summary,
			"blood_volume": blood_volume,
			"total_bleeding_rate": total_bleeding_rate,
			"node_ref": node_ref
		})
	return out

func clear():
	members.clear()
	emit_signal("party_updated")
