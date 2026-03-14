extends Node

signal party_updated()

const _Snapshot := preload("res://world/PartyMemberSnapshot.gd")

var members: Array = []

func _ready():
	pass

func add_member(node: Node) -> void:
	members.append(_Snapshot.init_from_node(node))
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
		out.append(_Snapshot.snapshot_from_member(m))
	return out

func clear():
	members.clear()
	emit_signal("party_updated")
