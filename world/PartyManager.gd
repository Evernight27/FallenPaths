extends Node
## Party roster management: member tracking and node references.

var members: Array[Dictionary] = []


func add_member(node: Node) -> void:
    if members.size() >= CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP:
        return
    members.append(PartyMemberSnapshot.init_from_node(node))


func remove_member_by_name(member_name: String) -> bool:
    for i in range(members.size()):
        if members[i].get("name") == member_name:
            members.remove_at(i)
            return true
    return false


func get_members() -> Array:
    var out: Array = []
    for m in members:
        out.append(PartyMemberSnapshot.snapshot_from_member(m))
    return out


func clear():
    members.clear()
