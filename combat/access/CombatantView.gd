class_name CombatantView
extends RefCounted

## Typed read wrapper over a combatant `Dictionary`. Storage stays dict-backed;
## prefer this at UI / listing boundaries. Mutations still go through
## `CombatantEntityAccess` (or specialist access modules).

var _c: Dictionary


func _init(combatant: Dictionary = {}) -> void:
    _c = combatant


static func wrap(combatant: Dictionary) -> CombatantView:
    return CombatantView.new(combatant)


func raw() -> Dictionary:
    return _c


func id() -> int:
    return int(_c.get("id", -1))


func side() -> String:
    return str(_c.get("side", ""))


func is_alive() -> bool:
    return CombatantEntityAccess.is_alive_in_combat(_c)


func state() -> String:
    return str(_c.get("state", CombatConstants.STATE_WAITING))


func gauge() -> float:
    return float(_c.get("gauge", 0.0))


func stamina() -> float:
    return float(_c.get("stamina", _c.get("breath", CombatConstants.STAMINA_MAX)))


func guard_line() -> String:
    return str(_c.get("guard_line", CombatConstants.GUARD_DEFAULT))


func form_str() -> String:
    return CombatantEntityAccess.form_str(_c)


func rank() -> int:
    return int(_c.get("rank", 0))


func file_index() -> int:
    return int(_c.get("file", 0))


func formation_id() -> String:
    return str(_c.get("formation_id", ""))


func engaged_with_id() -> int:
    return int(_c.get("engaged_with_id", -1))


func is_party_leader() -> bool:
    return bool(_c.get("is_party_leader", false))


func is_enemy_leader() -> bool:
    return bool(_c.get("is_enemy_leader", false))


func scene_node() -> Node:
    return CombatantEntityAccess.scene_node(_c)
