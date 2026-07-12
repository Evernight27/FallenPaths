class_name CombatantDictAccess
extends RefCounted

## Nested dict/array helpers for combatant records.
## Canonical: CombatantEntityAccess.combatant_dict_or_empty · nested_dictionary_* · stats_dict_for_mutation (thin delegates).

static func combatant_dict_or_empty(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}


static func stats_dict_for_mutation(combatant: Dictionary) -> Dictionary:
	var s: Variant = combatant.get("stats", null)
	if s is Dictionary:
		return s
	var d: Dictionary = {}
	combatant["stats"] = d
	return d


static func nested_dictionary_for_mutation(combatant: Dictionary, key: String) -> Dictionary:
	var v: Variant = combatant.get(key, null)
	if v is Dictionary:
		return v
	var d: Dictionary = {}
	combatant[key] = d
	return d


static func nested_dictionary_read(combatant: Dictionary, key: String) -> Dictionary:
	var v: Variant = combatant.get(key, null)
	if v is Dictionary:
		return v
	return {}


static func nested_array_for_mutation(combatant: Dictionary, key: String) -> Array:
	var v: Variant = combatant.get(key, null)
	if v is Array:
		return v as Array
	var a: Array = []
	combatant[key] = a
	return a
