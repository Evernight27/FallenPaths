class_name FormationSlots
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Array-based formation occupancy: slots[Vector2i(rank,file)] = combatant_ids.
## **Read order:** formation record helpers -> slot dict access -> rank/file queries -> vacancy/death plug hooks.
## Normal length 1. During same-column adjacent-rank moves, the shallower rank cell lists both [shallow, deep]
## and the deeper rank key is omitted until resolve (dual occupancy for dragging UI / lane crowding).
## Vacancy/death plugs promote natives within `slots`; dual-occupancy cells may list two ids during adjacent-rank moves.


## `side` on a runtime formation record (`manager.formations[fid]`).
static func formation_side_str(formation: Dictionary, default_side: String = "") -> String:
    return str(formation.get("side", default_side))


## Ensures `formation["slots"]` exists and returns it  -  avoids mutating a fresh `{}` from `Dictionary.get(..., {})`.
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
        return val.duplicate()
    if val is int:
        return [val]
    if val is float:
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
            var c: Dictionary = _EntityAccess.manager_get_combatant(manager, cid)
            if not c.is_empty() and _EntityAccess.is_alive_in_combat(c):
                kept.append(cid)
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


## Living occupant's slot cell when listed in `slots`; null when not found (fallback: combatant rank/file).
static func slot_key_for_combatant_id(manager: Node, formation: Dictionary, combatant_id: int) -> Variant:
    if manager == null or combatant_id < 0 or formation.is_empty():
        return null
    var slots: Dictionary = formation_slots_dict(formation)
    for k in slots.keys():
        if k is not Vector2i:
            continue
        var arr: Array = normalize_cell(slots[k])
        if arr.has(combatant_id):
            return k
    return null


static func slot_set_single(slots: Dictionary, key: Vector2i, combatant_id: int) -> void:
    slots[key] = [combatant_id]


static func remove_combatant_from_slots(slots: Dictionary, combatant_id: int) -> void:
    var to_erase: Array = []
    for k in slots.keys():
        var arr: Array = normalize_cell(slots[k])
        var filtered: Array = []
        for id in arr:
            if id != combatant_id:
                filtered.append(id)
        if filtered.is_empty():
            to_erase.append(k)
        else:
            slots[k] = filtered
    for k in to_erase:
        slots.erase(k)


## Same-file adjacent ranks (any depth): both ids listed at the shallower rank cell; deeper rank key cleared for duration.
static func begin_adjacent_rank_pair_move(
    slots: Dictionary, rank_shallow: int, rank_deep: int, file: int, id_at_shallow: int, id_at_deep: int
) -> void:
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
        var c: Dictionary = _EntityAccess.manager_get_combatant(manager, cid)
        if not c.is_empty() and _EntityAccess.is_alive_in_combat(c):
            n += 1
    return n


## IV-9: sorted unique file indices present in `slots` keys (any rank).
static func occupied_column_files(formation: Dictionary) -> Array:
    var files_seen: Dictionary = {}
    var slots: Dictionary = formation_slots_dict(formation)
    for k in slots.keys():
        if k is not Vector2i:
            continue
        files_seen[(k as Vector2i).y] = true
    var out: Array = files_seen.keys()
    out.sort()
    return out


## IV-9 gap mode: index distance along occupied columns; falls back to abs delta when unknown.
static func column_graph_file_distance(file_a: int, file_b: int, column_files: Array) -> float:
    if file_a == file_b:
        return 0.0
    if column_files.is_empty():
        return absf(float(file_a - file_b))
    var idx_a: int = column_files.find(file_a)
    var idx_b: int = column_files.find(file_b)
    if idx_a >= 0 and idx_b >= 0:
        return absf(float(idx_a - idx_b))
    return absf(float(file_a - file_b))


## UI / geometry: min..max span over occupied columns so intentional gaps render as empty cells.
static func column_display_files(formation: Dictionary, preset_files: int) -> Array:
    if not CombatConstants.is_feature_gap_column_topology_enabled():
        var legacy: Array = []
        for i in range(maxi(1, preset_files)):
            legacy.append(i)
        return legacy
    var occupied: Array = occupied_column_files(formation)
    if occupied.is_empty():
        var fallback: Array = []
        for j in range(maxi(1, preset_files)):
            fallback.append(j)
        return fallback
    var max_f: int = maxi(int(occupied[occupied.size() - 1]), maxi(1, preset_files) - 1)
    var out: Array = []
    for f in range(0, max_f + 1):
        out.append(f)
    return out


## Cached mirror of **`occupied_column_files`** when IV-9 flag on.
static func gap_column_files(formation: Dictionary) -> Array:
    var cached: Variant = formation.get("gap_column_files", null)
    if cached is Array and CombatConstants.is_feature_gap_column_topology_enabled():
        return cached.duplicate()
    return occupied_column_files(formation)


static func refresh_gap_column_topology(formation: Dictionary) -> void:
    if not CombatConstants.is_feature_gap_column_topology_enabled():
        formation.erase("gap_column_files")
        return
    formation["gap_column_files"] = occupied_column_files(formation)


static func refresh_gap_column_topology_for_manager(manager: Node, fid: String) -> void:
    if manager == null or fid.is_empty():
        return
    var formation: Dictionary = formation_record_for_manager(manager, fid)
    if not formation.is_empty():
        refresh_gap_column_topology(formation)


## IV-9: distinct file indices with a living occupant at `rank` (sorted ascending).
static func occupied_files_for_rank(manager: Node, formation: Dictionary, rank: int) -> PackedInt32Array:
    var out: PackedInt32Array = PackedInt32Array()
    if manager == null or formation.is_empty():
        return out
    var slots: Dictionary = formation_slots_dict(formation)
    var seen: Dictionary = {}
    for k in slots.keys():
        if not (k is Vector2i):
            continue
        var cell: Vector2i = k as Vector2i
        if cell.x != rank:
            continue
        if not slot_has_any_living_occupant(manager, slots, cell):
            continue
        var f: int = cell.y
        if not seen.has(f):
            seen[f] = true
            out.append(f)
    out.sort()
    return out


## IV-9: occupied files are exactly `0..n-1` (legacy contiguous line).
static func occupied_files_are_contiguous_from_zero(files: PackedInt32Array) -> bool:
    if files.is_empty():
        return true
    for i in range(files.size()):
        if files[i] != i:
            return false
    return true


## IV-9: intentional column gaps (not packed to file 0..n-1).
static func occupied_files_have_gaps(files: PackedInt32Array) -> bool:
    return not occupied_files_are_contiguous_from_zero(files)


## IV-9: index of `file` in sorted occupied column ids; `-1` when absent.
static func column_index_in_occupied_files(files: PackedInt32Array, file: int) -> int:
    for i in range(files.size()):
        if files[i] == file:
            return i
    return -1


## IV-9: reach distance along occupied column order (not raw grid `|I"file|`).
static func column_arc_file_distance(
    occ_a: PackedInt32Array, file_a: int, occ_b: PackedInt32Array, file_b: int
) -> float:
    var ia: int = column_index_in_occupied_files(occ_a, file_a)
    var ib: int = column_index_in_occupied_files(occ_b, file_b)
    if ia < 0 or ib < 0:
        return absf(float(file_a - file_b))
    return absf(float(ia - ib))
