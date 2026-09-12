class_name CombatStandingHelper
extends RefCounted

## Standing = alive and not incapacitated. Used for winner checks and standing counts.
## Centralizes the standing/winner logic so the manager's _check_for_winner shares one definition.


## Returns dict: side -> count of standing combatants. Combatant is standing if alive and not incapacitated.
static func get_standing_by_side(combatants: Array) -> Dictionary:
    var standing: Dictionary = {}
    for c in combatants:
        if not CombatantEntityAccess.is_standing_combatant(c):
            continue
        var sd: String = CombatantEntityAccess.side_str(c)
        standing[sd] = standing.get(sd, 0) + 1
    return standing


## Returns winner side string if one side has 0 standing. Empty if battle continues.
static func get_winner(combatants: Array) -> String:
    var standing: Dictionary = get_standing_by_side(combatants)
    var sides_list: Array = []
    for c in combatants:
        var sdc: String = CombatantEntityAccess.side_str(c)
        if sdc not in sides_list:
            sides_list.append(sdc)
    if sides_list.size() >= 2:
        var a: int = standing.get(sides_list[0], 0)
        var b: int = standing.get(sides_list[1], 0)
        if a == 0:
            return sides_list[1]
        if b == 0:
            return sides_list[0]
    return ""



