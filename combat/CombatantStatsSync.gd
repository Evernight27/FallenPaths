class_name CombatantStatsSync
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Syncs entity health/combat stats into a combatant stats dictionary.
## Used by CombatManager for _refresh_combatant_stats and get_combatants.
## Ensures single source of truth for entity→stats copy logic.

## Syncs entity state into stats dict (mutates stats in place).
## If ensure_consciousness is true, calls entity.ensure_consciousness_current() first.
static func sync_from_entity(entity: Node, stats: Dictionary, ensure_consciousness: bool = true) -> void:
	if entity == null:
		return
	if ensure_consciousness and entity.has_method("ensure_consciousness_current"):
		entity.ensure_consciousness_current()
	if "body_cutting" in entity:
		stats.body_cutting = entity.body_cutting.duplicate()
	if "body_blunt" in entity:
		stats.body_blunt = entity.body_blunt.duplicate()
	if "bone_health" in entity:
		stats.bone_health = entity.bone_health.duplicate()
	if "bone_max" in entity:
		stats.bone_max = entity.bone_max.duplicate()
	if "body_max" in entity:
		stats.body_max = entity.body_max.duplicate()
	stats.blood_volume = _EntityAccess.get_blood_volume_from_node(entity)
	stats.total_bleeding_rate = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if entity.has_method("get_total_pain"):
		stats.total_pain = entity.get_total_pain()
	if entity.has_method("get_effective_consciousness"):
		stats.effective_consciousness = entity.get_effective_consciousness()
	if entity.has_method("get_performance_modifier"):
		stats.performance_modifier = entity.get_performance_modifier()
	# Combat-relevant attributes (parry capacity, reaction time)
	if "strength" in entity:
		stats.strength = entity.strength
	if "agility" in entity:
		stats.agility = entity.agility
	if "perception" in entity:
		stats.perception = entity.perception

## Returns initial stats dict for combatant registration. Single source of truth for entity→stats copy.
## Entity can be null; returns defaults. Handles CoreEntity-style and nodes with "speed" instead of "agility".
static func sync_from_entity_for_register(entity: Node) -> Dictionary:
	var s := {
		"body_cutting": {},
		"body_blunt": {},
		"body_max": {},
		"bone_health": {},
		"bone_max": {},
		"strength": 100,
		"agility": 100,
		"intelligence": 100,
		"endurance": 100,
		"perception": 100
	}
	if entity == null:
		return s
	if "body_cutting" in entity:
		s.body_cutting = entity.body_cutting.duplicate()
	if "body_blunt" in entity:
		s.body_blunt = entity.body_blunt.duplicate()
	if "body_max" in entity:
		s.body_max = entity.body_max.duplicate()
	if "bone_health" in entity:
		s.bone_health = entity.bone_health.duplicate()
	if "bone_max" in entity:
		s.bone_max = entity.bone_max.duplicate()
	if "strength" in entity:
		s.strength = entity.strength
	if "agility" in entity:
		s.agility = entity.agility
	elif "speed" in entity:
		s.agility = entity.speed
	if "intelligence" in entity:
		s.intelligence = entity.intelligence
	if "endurance" in entity:
		s.endurance = entity.endurance
	if "perception" in entity:
		s.perception = entity.perception
	return s

## Applies default values for stats keys that may be missing (e.g. when entity lacks methods).
## Use when building output for UI or external consumers.
static func ensure_defaults(stats: Dictionary) -> void:
	if not stats.has("blood_volume"):
		stats.blood_volume = 100.0
	if not stats.has("total_bleeding_rate"):
		stats.total_bleeding_rate = 0.0
	if not stats.has("effective_consciousness"):
		stats.effective_consciousness = 100.0
	if not stats.has("performance_modifier"):
		stats.performance_modifier = 1.0
	if not stats.has("total_pain"):
		stats.total_pain = 0.0
