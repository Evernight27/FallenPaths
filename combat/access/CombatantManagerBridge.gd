class_name CombatantManagerBridge
extends RefCounted

## Manager bridge, scene node access, dict helpers, and combat clock.
## Canonical: docs/AGENTS_API.md

static var _combat_constants: Variant = null
static var _entity_wounds_cache: Variant = null
static var _impact_velocity_model_cache: Variant = null
static var _entity_medical_cache: Variant = null
static var _medical_phase_cache: Variant = null
static var _exhaustion_cache: Variant = null
static var _formation_slots_cache: Variant = null
static var _footwork_cache: Variant = null
static var _state_handlers_cache: Variant = null
static var _mobility_retreat_cache: Variant = null
static var _rout_cache: Variant = null


## Opponent band from actor `distance_to` (default **LONG** when unset).
static func alive_bool(combatant: Dictionary, default_alive: bool = false) -> bool:
    var v = combatant.get(DataKeys.COMBATANT_ALIVE, default_alive)
    return v == true


## `state` string; uses `default_state` when missing.

## `state` string; uses `default_state` when missing.


## `alive` combatant flag, on the field, and not `is_dead` on the scene node.
static func is_alive_in_combat(combatant: Dictionary) -> bool:
    if has_left_battlefield(combatant):
        return false
    if not alive_bool(combatant):
        return false
    var node = node_variant(combatant)
    if node != null and node.has_method("is_dead") and node.is_dead():
        return false
    return true


## True when consciousness is below incapacitation floor (unconscious; cannot act or move).
static func is_unconscious(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_unconscious"):
        return false
    return node.is_unconscious()


## Tier 6.1: arm loss during combat  -  sync cowering, cancel stale turns, abort wind-up (see
## **`CombatMobilityRetreat`**).

## Tier 6.1: arm loss during combat  -  sync cowering, cancel stale turns, abort wind-up (see
## **`CombatMobilityRetreat`**).


static func has_left_battlefield(combatant: Dictionary) -> bool:
    if combatant.get(DataKeys.COMBATANT_COMBAT_ABSENT, false):
        return true
    return str(combatant.get(DataKeys.COMBATANT_STATE, "")) == "fled"


## `alive` combatant flag, on the field, and not `is_dead` on the scene node.

## `alive` combatant flag, on the field, and not `is_dead` on the scene node.


## Returns true if combatant's node is incapacitated (consciousness/cowering) or has yielded.
static func is_incapacitated(combatant: Dictionary) -> bool:
    if (
        bool(combatant.get(DataKeys.COMBATANT_YIELDED, false))
        or str(combatant.get(DataKeys.COMBATANT_STATE, "")) == "yielded"
    ):
        return true
    if str(combatant.get(DataKeys.COMBATANT_STATE, "")) == "cowering":
        return true
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_incapacitated"):
        return false
    return node.is_incapacitated()


## Voluntary surrender: non-standing but remains on the field.

## Voluntary surrender: non-standing but remains on the field.


static func _get_combat_constants() -> GDScript:
    if CombatantManagerBridge._combat_constants == null:
        CombatantManagerBridge._combat_constants = load("res://combat/CombatConstants.gd")
    return CombatantManagerBridge._combat_constants


static func _get_entity_wounds() -> GDScript:
    if _entity_wounds_cache == null:
        _entity_wounds_cache = load("res://core/EntityWounds.gd")
    return _entity_wounds_cache


static func _get_impact_velocity_model() -> GDScript:
    if _impact_velocity_model_cache == null:
        _impact_velocity_model_cache = load("res://resources/weapons/ImpactVelocityModel.gd")
    return _impact_velocity_model_cache


static func _load_entity_medical() -> GDScript:
    if _entity_medical_cache == null:
        _entity_medical_cache = load("res://core/EntityMedical.gd")
    return _entity_medical_cache


static func _get_medical_phase() -> GDScript:
    if _medical_phase_cache == null:
        _medical_phase_cache = load("res://combat/medical/MedicalPhaseController.gd")
    return _medical_phase_cache


static func _load_exhaustion() -> GDScript:
    if _exhaustion_cache == null:
        _exhaustion_cache = load("res://combat/flow/CombatExhaustion.gd")
    return _exhaustion_cache


static func _get_formation_slots() -> GDScript:
    if _formation_slots_cache == null:
        _formation_slots_cache = load("res://combat/formation/FormationSlots.gd")
    return _formation_slots_cache


static func _get_footwork() -> GDScript:
    if _footwork_cache == null:
        _footwork_cache = load("res://combat/weapon_form/CombatFootwork.gd")
    return _footwork_cache


static func _get_state_handlers() -> GDScript:
    if _state_handlers_cache == null:
        _state_handlers_cache = load("res://combat/flow/CombatStateHandlers.gd")
    return _state_handlers_cache


static func _get_mobility_retreat() -> GDScript:
    if _mobility_retreat_cache == null:
        _mobility_retreat_cache = load("res://combat/formation/CombatMobilityRetreat.gd")
    return _mobility_retreat_cache


static func _get_rout() -> GDScript:
    if _rout_cache == null:
        _rout_cache = load("res://combat/formation/CombatFormationRout.gd")
    return _rout_cache


## Centralized access to combatant node/entity for weapon, armor, performance, etc.
## Reduces repeated node.has_method("get_weapon") patterns across AttackResolver, DefenseChoiceResolver, etc.
## Footing: **`form_str`** is canonical L2 id for picker/UI/close  -  not **`guard_line`** or PA offset. LIVE_PATHS
## **`#wf-assign-form-contract`** f→s'. **`#wf-footing-doc-map`**.

## Scene `node` on the combatant dict (e.g. Character); null if missing.

## Centralized access to combatant node/entity for weapon, armor, performance, etc.
## Reduces repeated node.has_method("get_weapon") patterns across AttackResolver, DefenseChoiceResolver, etc.
## Footing: **`form_str`** is canonical L2 id for picker/UI/close  -  not **`guard_line`** or PA offset. LIVE_PATHS
## **`#wf-assign-form-contract`** f→s'. **`#wf-footing-doc-map`**.


## Scene `node` on the combatant dict (e.g. Character); null if missing.
static func node_variant(combatant: Dictionary) -> Variant:
    return combatant.get(DataKeys.COMBATANT_NODE, null)


## Typed scene node (`node_variant` as `Node`). Null if missing or not a `Node`.


## Typed scene node (`node_variant` as `Node`). Null if missing or not a `Node`.
static func scene_node(combatant: Dictionary) -> Node:
    return node_variant(combatant) as Node


## `_get_by_id` (or test doubles) may return null or a non-dict. Use before `Dictionary` ops / `stats_dict` on lookups.


## `_get_by_id` (or test doubles) may return null or a non-dict. Use before `Dictionary` ops / `stats_dict` on lookups.
static func combatant_dict_or_empty(v: Variant) -> Dictionary:
    return CombatantDictAccess.combatant_dict_or_empty(v)


## CombatManager (or harness stub) lookup by id; `{}` when missing or unavailable.


## CombatManager (or harness stub) lookup by id; `{}` when missing or unavailable.
static func manager_get_combatant(manager: Node, combatant_id: int) -> Dictionary:
    if manager == null or combatant_id < 0 or not manager.has_method("_get_by_id"):
        return {}
    return combatant_dict_or_empty(manager._get_by_id(combatant_id))


## Same as **`manager_get_combatant`**; returns `{}` when **`combatant_id < 0`**.


## Same as **`manager_get_combatant`**; returns `{}` when **`combatant_id < 0`**.
static func manager_get_combatant_optional(manager: Node, combatant_id: int) -> Dictionary:
    return manager_get_combatant(manager, combatant_id)


static func manager_notify_turn_ready(manager: Node, combatant_id: int) -> void:
    if manager != null and manager.has_method("notify_turn_ready"):
        manager.notify_turn_ready(combatant_id)


static func manager_notify_formation_changed(manager: Node, fid: String) -> void:
    if manager != null and manager.has_method("notify_formation_changed"):
        manager.notify_formation_changed(fid)


static func manager_notify_engagement_state_changed(
    manager: Node, fid: String, cohesion: float, posture: String
) -> void:
    if manager != null and manager.has_method("_notify_engagement_state_changed"):
        manager._notify_engagement_state_changed(fid, cohesion, posture)


## Live `stats` sub-dictionary for mutation (e.g. `sync_from_entity`). Creates `combatant["stats"]` if missing or wrong
## type.


## Live `stats` sub-dictionary for mutation (e.g. `sync_from_entity`). Creates `combatant["stats"]` if missing or wrong
## type.
static func stats_dict_for_mutation(combatant: Dictionary) -> Dictionary:
    return CombatantDictAccess.stats_dict_for_mutation(combatant)


## Nested `Dictionary` on a combatant record (e.g. `distance_to`, `close_block_until_by_target_id`).
## Avoids mutating a throwaway `{}` from `Dictionary.get(key, {})` when the field is missing or wrong-typed.


## Nested `Dictionary` on a combatant record (e.g. `distance_to`, `close_block_until_by_target_id`).
## Avoids mutating a throwaway `{}` from `Dictionary.get(key, {})` when the field is missing or wrong-typed.
static func nested_dictionary_for_mutation(combatant: Dictionary, key: String) -> Dictionary:
    return CombatantDictAccess.nested_dictionary_for_mutation(combatant, key)


## Read-only nested dict: returns stored dict or `{}` without assigning `combatant[key]` (safe for pure reads when key
## missing / wrong-typed).


## Read-only nested dict: returns stored dict or `{}` without assigning `combatant[key]` (safe for pure reads when key
## missing / wrong-typed).
static func nested_dictionary_read(combatant: Dictionary, key: String) -> Dictionary:
    return CombatantDictAccess.nested_dictionary_read(combatant, key)


## Nested `Array` field (e.g. `failed_medical_parts`).


## Nested `Array` field (e.g. `failed_medical_parts`).
static func nested_array_for_mutation(combatant: Dictionary, key: String) -> Array:
    return CombatantDictAccess.nested_array_for_mutation(combatant, key)


## Weapon exposes melee move ids (empty when weapon null or lacks attack list).


## Weapon exposes melee move ids (empty when weapon null or lacks attack list).
static func combat_clock_float(manager: Node) -> float:
    if manager == null:
        return 0.0
    var cc: Variant = manager.get("combat_clock")
    if cc == null:
        return 0.0
    return float(cc)


## **`combat_clock_float(manager) + offset_s`** for event `resolve_at` and cooldown stamps.


## **`combat_clock_float(manager) + offset_s`** for event `resolve_at` and cooldown stamps.
static func combat_clock_plus(manager: Node, offset_s: float) -> float:
    return combat_clock_float(manager) + offset_s


## True while combat clock is before `until`. Values below `inactive_below` are treated as off.
static func manager_schedule_event(manager: Node, ev: Dictionary) -> void:
    if manager != null and manager.has_method("_schedule_event"):
        manager._schedule_event(ev)


static func manager_skip_turn(manager: Node, combatant_id: int, reason: String, detail: String = "") -> void:
    if manager != null and manager.has_method("skip_turn"):
        manager.skip_turn(combatant_id, reason, detail)


static func manager_apply_formation_hit_reaction_if_needed(
    manager: Node, combatant_id: int, intensity: float = 0.5
) -> void:
    if manager != null and manager.has_method("_apply_formation_hit_reaction_if_needed"):
        manager._apply_formation_hit_reaction_if_needed(combatant_id, intensity)

## Returns permanent bleeding rate from node. Default fallback if unavailable.

## Returns permanent bleeding rate from node. Default fallback if unavailable.
