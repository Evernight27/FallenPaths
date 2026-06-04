class_name FormationSlots
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## `side` on a runtime formation record (`manager.formations[fid]`).
static func formation_side_str(formation: Dictionary, default_side: String = "") -> String:
	return str(formation.get("side", default_side))


## Array-based formation occupancy: slots[Vector2i(rank,file)] = Array of combatant_ids.
## Normal length 1. During same-column adjacent-rank moves, the shallower rank cell lists both [shallow, deep]
## and the deeper rank key is omitted until resolve (dual occupancy for dragging UI / lane crowding).
##
## Vacancy/death plugs promote natives within `slots`; dual-occupancy cells may list two ids during adjacent-rank moves (see class header).

## Ensures `formation["slots"]` exists and returns it — avoids mutating a fresh `{}` from `Dictionary.get(..., {})`.
static func formation_slots_dict(formation: Dictionary) -> Dictionary:
	if not formation.has("slots"):
		formation["slots"] = {}
	return formation["slots"] as Dictionary


## Read-only: nested dict on `manager.formations[fid]` (e.g. `slot_obstacles`, `zone_control`); does not create keys.
static func formation_nested_dictionary_read(formation: Dictionary, key: String) -> Dictionary:
	return _EntityAccess.nested_dictionary_read(formation, key)


## Read-only: `formations[fid]` when it is a Dictionary; `{}` if missing, wrong-typed, or `formations` is not a Dictionary.
## Avoids treating non-dict slots as formation records and avoids chained `.get(..., {}).method` failures on bad saves/tests.
## Read-only: `manager.formations[fid]` when present and dict-shaped.
static func formation_record_for_manager(manager: Node, fid: String) -> Dictionary:
	if manager == null or fid.is_empty():
		return {}
	return formation_record_read(manager.formations, fid)


static func formation_record_read(formations: Variant, fid: String) -> Dictionary:
	if formations == null or not (formations is Dictionary):
		return {}
	var raw: Variant = (formations as Dictionary).get(fid, null)
	if raw is Dictionary:
		return raw as Dictionary
	return {}


static func normalize_cell(val: Variant) -> Array:
	if val == null:
		return []
	if val is Array:
		return (val as Array).duplicate()
	if typeof(val) == TYPE_INT:
		return [val as int]
	if typeof(val) == TYPE_FLOAT:
		return [int(val)]
	return []

## Normalize slot values to `Array` of ids (single id, pair move, or empty).
static func normalize_formation_slots(formation: Dictionary) -> void:
	var slots: Dictionary = formation_slots_dict(formation)
	for k in slots.keys():
		slots[k] = normalize_cell(slots[k])


static func slot_has_any(slots: Dictionary, key: Vector2i) -> bool:
	return not normalize_cell(slots.get(key, [])).is_empty()


## True if at least one **living** combatant occupies the cell (dead ids alone do not count).
static func slot_has_any_living_occupant(manager: Node, slots: Dictionary, key: Vector2i) -> bool:
	return living_count_in_slot(manager, slots, key) > 0


## Remove dead combatant ids from slot arrays and erase emptied cells. Returns whether `slots` changed.
static func prune_dead_ids_from_formation_slots(manager: Node, slots: Dictionary) -> bool:
	if manager == null:
		return false
	var changed: bool = false
	for k in slots.keys().duplicate():
		var arr: Array = normalize_cell(slots.get(k, []))
		if arr.is_empty():
			continue
		var kept: Array = []
		for cid in arr:
			var c: Dictionary = _EntityAccess.manager_get_combatant(manager, int(cid))
			if not c.is_empty() and _EntityAccess.is_alive_in_combat(c):
				kept.append(int(cid))
		if kept.size() != arr.size():
			changed = true
		if kept.is_empty():
			slots.erase(k)
		else:
			slots[k] = kept
	return changed


static func slot_primary_id(slots: Dictionary, key: Vector2i) -> int:
	var arr: Array = normalize_cell(slots.get(key, []))
	if arr.is_empty():
		return -1
	return int(arr[0])


static func slot_set_single(slots: Dictionary, key: Vector2i, combatant_id: int) -> void:
	slots[key] = [combatant_id]


static func remove_combatant_from_slots(slots: Dictionary, combatant_id: int) -> void:
	var to_erase: Array = []
	for k in slots.keys():
		var arr: Array = normalize_cell(slots[k])
		var filtered: Array = []
		for id in arr:
			if int(id) != combatant_id:
				filtered.append(int(id))
		if filtered.is_empty():
			to_erase.append(k)
		else:
			slots[k] = filtered
	for k in to_erase:
		slots.erase(k)


## Same-file adjacent ranks (any depth): both ids listed at the shallower rank cell; deeper rank key cleared for duration.
static func begin_adjacent_rank_pair_move(slots: Dictionary, rank_shallow: int, rank_deep: int, file: int, id_at_shallow: int, id_at_deep: int) -> void:
	if rank_shallow > rank_deep:
		push_error("FormationSlots.begin_adjacent_rank_pair_move: rank_shallow must be <= rank_deep")
		return
	var k_shallow := Vector2i(rank_shallow, file)
	var k_deep := Vector2i(rank_deep, file)
	slots.erase(k_deep)
	slots[k_shallow] = [id_at_shallow, id_at_deep]


static func living_count_in_slot(manager: Node, slots: Dictionary, key: Vector2i) -> int:
	var arr: Array = normalize_cell(slots.get(key, []))
	var n: int = 0
	for cid in arr:
		var c: Dictionary = _EntityAccess.manager_get_combatant(manager, int(cid))
		if not c.is_empty() and _EntityAccess.is_alive_in_combat(c):
			n += 1
	return n
