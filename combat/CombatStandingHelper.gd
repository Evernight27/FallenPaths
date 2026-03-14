class_name CombatStandingHelper
extends RefCounted

## Standing = alive and not incapacitated. Used for winner checks and finding opponents.
## Centralizes the logic so _check_for_winner and _find_first_opponent share one definition.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Returns dict: side -> count of standing combatants. Combatant is standing if alive and not incapacitated.
static func get_standing_by_side(combatants: Array) -> Dictionary:
	var standing: Dictionary = {}
	for c in combatants:
		if not c.alive:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		standing[c.side] = standing.get(c.side, 0) + 1
	return standing

## Returns first opponent (standing combatant on different side). Null if none.
static func get_first_opponent(combatants: Array, side: String) -> Variant:
	for c in combatants:
		if not c.alive:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		if c.side != side:
			return c
	return null

## Returns winner side string if one side has 0 standing. Empty if battle continues.
static func get_winner(combatants: Array) -> String:
	var standing: Dictionary = get_standing_by_side(combatants)
	var sides_list: Array = []
	for c in combatants:
		if c.side not in sides_list:
			sides_list.append(c.side)
	if sides_list.size() >= 2:
		var a: int = standing.get(sides_list[0], 0)
		var b: int = standing.get(sides_list[1], 0)
		if a == 0:
			return sides_list[1]
		if b == 0:
			return sides_list[0]
	return ""
