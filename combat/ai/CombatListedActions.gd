class_name CombatListedActions
extends RefCounted

## Shared scans over **`get_available_actions`** / **`build()`** output arrays (harness + UI hints).


static func _entry(raw: Variant) -> Dictionary:
    if raw is Dictionary:
        return raw as Dictionary
    return {}


static func entry_move_id(a: Dictionary) -> String:
    return str(a.get(DataKeys.ACTION_MOVE_ID, ""))


static func entry_target_id(a: Dictionary, missing: int = -1) -> int:
    return a.get(DataKeys.ACTION_TARGET_ID, missing)


static func action_entry_is_self_target_move(a: Dictionary, combatant_id: int, move_id: String) -> bool:
    return entry_move_id(a) == move_id and entry_target_id(a) == combatant_id


## Hostile strike or **`attempt_close`** vs another combatant (not self-only focus/wait/formation).
static func action_list_has_hostile_strike(actions: Array, self_id: int) -> bool:
    return _action_list_has_hostile_engagement(actions, self_id, true)


## Listed melee/feint vs hostile target — excludes **`attempt_close`** (III-4 **3e** rotate suppress).
static func action_list_has_hostile_melee_strike(actions: Array, self_id: int) -> bool:
    return _action_list_has_hostile_engagement(actions, self_id, false)


static func _action_list_has_hostile_engagement(actions: Array, self_id: int, include_attempt_close: bool) -> bool:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        var mid: String = entry_move_id(a)
        if mid.is_empty():
            continue
        if mid == CombatConstants.MOVE_ID_WAIT:
            continue
        if CombatConstants.is_focus_line_move(mid):
            continue
        if CombatConstants.is_formation_movement_move(mid):
            continue
        if CombatConstants.is_medical_move(mid):
            continue
        if not include_attempt_close and mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tid: int = entry_target_id(a, self_id)
        if tid != self_id:
            return true
    return false


static func is_reserve_posture_listing_move_id(move_id: String) -> bool:
    if move_id.is_empty():
        return false
    if move_id == CombatConstants.MOVE_ID_WAIT:
        return true
    if CombatConstants.is_focus_line_move(move_id):
        return true
    if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        return true
    return false


## True when every listed action is **`wait`** or a focus-line move (back rank / no ZoC reach).
static func action_list_is_hold_line_only(actions: Array) -> bool:
    var saw_action: bool = false
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        var mid: String = entry_move_id(a)
        if mid.is_empty():
            continue
        saw_action = true
        if mid == CombatConstants.MOVE_ID_WAIT:
            continue
        if CombatConstants.is_focus_line_move(mid):
            continue
        return false
    return saw_action


## Hold-line plus **`attempt_close`** only (no melee) — same reserve posture / wait requirement.
static func action_list_is_reserve_posture_only(actions: Array) -> bool:
    var saw_action: bool = false
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        var mid: String = entry_move_id(a)
        if mid.is_empty():
            continue
        saw_action = true
        if is_reserve_posture_listing_move_id(mid):
            continue
        return false
    return saw_action


static func actions_include_move_id(actions: Array, move_id: String) -> bool:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if entry_move_id(a) == move_id:
            return true
    return false


static func actions_include_move_vs_target(actions: Array, target_id: int, move_id: String) -> bool:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if entry_target_id(a, -9) == target_id and entry_move_id(a) == move_id:
            return true
    return false


static func _move_id_allowed(move_id: String, move_ids: Variant) -> bool:
    if move_ids is Dictionary:
        return (move_ids as Dictionary).has(move_id)
    if move_ids is Array:
        return move_id in move_ids
    return false


static func actions_include_any_move_in_vs_target(actions: Array, target_id: int, move_ids: Variant) -> bool:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if entry_target_id(a, -9) != target_id:
            continue
        if _move_id_allowed(entry_move_id(a), move_ids):
            return true
    return false


static func actions_any_vs_target(actions: Array, target_id: int) -> bool:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if entry_target_id(a, -9) == target_id:
            return true
    return false


static func first_action_vs_target(actions: Array, target_id: int) -> Dictionary:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if entry_target_id(a, -9) == target_id:
            return a
    return {}


static func actions_include_self_target_move(actions: Array, combatant_id: int, move_id: String) -> bool:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if action_entry_is_self_target_move(a, combatant_id, move_id):
            return true
    return false


static func first_action_with_move_id(actions: Array, move_id: String) -> Dictionary:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if entry_move_id(a) == move_id:
            return a
    return {}


static func first_action_move_vs_target(actions: Array, move_id: String, target_id: int) -> Dictionary:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if entry_move_id(a) == move_id and entry_target_id(a) == target_id:
            return a
    return {}


static func first_self_target_action(actions: Array, combatant_id: int, move_id: String) -> Dictionary:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if action_entry_is_self_target_move(a, combatant_id, move_id):
            return a
    return {}


## Sorted `move_id:target_id` signature for parity tests.
static func compact_signature(actions: Array) -> String:
    var rows: PackedStringArray = []
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        rows.append("%s:%d" % [entry_move_id(a), entry_target_id(a)])
    rows.sort()
    return ",".join(rows)


## First `move_id` not in any allowlist array; empty string when all entries are allowed or skipped.
static func first_move_id_not_in_allowed_sets(actions: Array, allowlists: Array) -> String:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        var mid: String = entry_move_id(a)
        if mid.is_empty():
            continue
        for list_v in allowlists:
            if list_v is Array and mid in list_v:
                mid = ""
                break
        if not mid.is_empty():
            return mid
    return ""


## First action dict for which `predicate` returns true (`predicate` receives the entry dict).
static func first_action_where(actions: Array, predicate: Callable) -> Dictionary:
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if predicate.call(a):
            return a
    return {}


static func filter_actions(actions: Array, keep_predicate: Callable) -> Array:
    var out: Array = []
    for raw in actions:
        var a: Dictionary = _entry(raw)
        if a.is_empty():
            continue
        if keep_predicate.call(a):
            out.append(a)
    return out



