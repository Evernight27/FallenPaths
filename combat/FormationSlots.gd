class_name FormationSlots
extends RefCounted

## Array-based formation occupancy: slots[Vector2i(rank,file)] = Array of combatant_ids.
## Normal length 1. During same-column adjacent-rank moves, the shallower rank cell lists both [shallow, deep]
## and the deeper rank key is omitted until resolve (dual occupancy for dragging UI / lane crowding).

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

## Migrate legacy int values to single-element arrays.
static func normalize_formation_slots(formation: Dictionary) -> void:
	var slots: Dictionary = formation.get("slots", {})
	for k in slots.keys():
		slots[k] = normalize_cell(slots[k])


static func slot_has_any(slots: Dictionary, key: Vector2i) -> bool:
	return not normalize_cell(slots.get(key, [])).is_empty()


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
		var c = manager._get_by_id(int(cid)) if manager.has_method("_get_by_id") else null
		if c != null and c.get("alive", false):
			n += 1
	return n
