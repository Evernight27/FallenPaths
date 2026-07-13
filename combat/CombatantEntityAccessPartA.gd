class_name CombatantEntityAccessPartA
extends RefCounted

## Central combatant dictionary lookups: health, identity, wounds, weapon, side/alive, vitals.
## Nested dict helpers: CombatantDictAccess (delegated below — public API unchanged).
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


static func _get_combat_constants() -> GDScript:
    if CombatantEntityAccess._combat_constants == null:
        CombatantEntityAccess._combat_constants = load("res://combat/CombatConstants.gd")
    return CombatantEntityAccess._combat_constants


static func _get_entity_wounds() -> GDScript:
    if _entity_wounds_cache == null:
        _entity_wounds_cache = load("res://core/EntityWounds.gd")
    return _entity_wounds_cache


static func _get_impact_velocity_model() -> GDScript:
    if _impact_velocity_model_cache == null:
        _impact_velocity_model_cache = load("res://weapon/ImpactVelocityModel.gd")
    return _impact_velocity_model_cache


static func _load_entity_medical() -> GDScript:
    if _entity_medical_cache == null:
        _entity_medical_cache = load("res://core/EntityMedical.gd")
    return _entity_medical_cache


static func _get_medical_phase() -> GDScript:
    if _medical_phase_cache == null:
        _medical_phase_cache = load("res://combat/MedicalPhaseController.gd")
    return _medical_phase_cache


static func _load_exhaustion() -> GDScript:
    if _exhaustion_cache == null:
        _exhaustion_cache = load("res://combat/CombatExhaustion.gd")
    return _exhaustion_cache


static func _get_formation_slots() -> GDScript:
    if _formation_slots_cache == null:
        _formation_slots_cache = load("res://combat/FormationSlots.gd")
    return _formation_slots_cache


static func _get_footwork() -> GDScript:
    if _footwork_cache == null:
        _footwork_cache = load("res://combat/CombatFootwork.gd")
    return _footwork_cache


static func _get_state_handlers() -> GDScript:
    if _state_handlers_cache == null:
        _state_handlers_cache = load("res://combat/CombatStateHandlers.gd")
    return _state_handlers_cache


static func _get_mobility_retreat() -> GDScript:
    if _mobility_retreat_cache == null:
        _mobility_retreat_cache = load("res://combat/CombatMobilityRetreat.gd")
    return _mobility_retreat_cache


static func _get_rout() -> GDScript:
    if _rout_cache == null:
        _rout_cache = load("res://combat/CombatFormationRout.gd")
    return _rout_cache


## Centralized access to combatant node/entity for weapon, armor, performance, etc.
## Reduces repeated node.has_method("get_weapon") patterns across AttackResolver, DefenseChoiceResolver, etc.
## Footing: **`form_str`** is canonical L2 id for picker/UI/close  -  not **`guard_line`** or PA offset. LIVE_PATHS
## **`#wf-assign-form-contract`** f''s'. **`#wf-footing-doc-map`**.

## Scene `node` on the combatant dict (e.g. Character); null if missing.

## Centralized access to combatant node/entity for weapon, armor, performance, etc.
## Reduces repeated node.has_method("get_weapon") patterns across AttackResolver, DefenseChoiceResolver, etc.
## Footing: **`form_str`** is canonical L2 id for picker/UI/close  -  not **`guard_line`** or PA offset. LIVE_PATHS
## **`#wf-assign-form-contract`** f''s'. **`#wf-footing-doc-map`**.


## Scene `node` on the combatant dict (e.g. Character); null if missing.
static func node_variant(combatant: Dictionary) -> Variant:
    return combatant.get("node", null)


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
static func weapon_attack_types(weapon: Variant) -> Array:
    if weapon == null or not weapon.has_method("get_available_attack_types"):
        return []
    return weapon.get_available_attack_types()


static func weapon_has_attack_types(weapon: Variant) -> bool:
    return weapon != null and weapon.has_method("get_available_attack_types")


static func weapon_contact_type(weapon: Variant, move_id: String, default_contact: String = "cut") -> String:
    if weapon == null or not weapon.has_method("get_contact_type"):
        return default_contact
    return str(weapon.get_contact_type(move_id))


## Delegates to **`WeaponConstants.weapon_mass_kg`** (combat call sites).


## Delegates to **`WeaponConstants.weapon_mass_kg`** (combat call sites).
static func weapon_mass_kg(weapon: Variant) -> float:
    return WeaponConstants.weapon_mass_kg(weapon)


static func parry_wobble_context(defender_weapon: Variant, parry_readiness: float) -> Dictionary:
    return {"parry_readiness": parry_readiness, "defender_mass_kg": weapon_mass_kg(defender_weapon)}


static func parry_wobble_context_for_combatant(combatant: Dictionary, parry_readiness: float) -> Dictionary:
    return parry_wobble_context(get_weapon(combatant), parry_readiness)


static func weapon_archetype_id(weapon: Variant, move_id: String, default_id: String = "slash") -> String:
    if weapon == null or not weapon.has_method("get_archetype_id"):
        return default_id
    return str(weapon.get_archetype_id(move_id))


static func weapon_archetype_for_move(
    weapon: Variant, move_id: String, default_archetype_id: String = WeaponConstants.ARCHETYPE_SLASH
) -> Dictionary:
    return WeaponConstants.get_archetype(weapon_archetype_id(weapon, move_id, default_archetype_id))


static func weapon_has_parts(weapon: Variant) -> bool:
    return weapon != null and weapon.has_method("has_parts") and weapon.has_parts()


static func weapon_parry_strong_fraction(weapon: Variant, default_frac: float = 0.25) -> float:
    if weapon == null or not weapon.has_method("get_parry_strong_fraction"):
        return default_frac
    return weapon.get_parry_strong_fraction()


static func weapon_parry_part_length_cm(weapon: Variant, default_len: float = 0.0) -> float:
    if weapon == null or not weapon.has_method("get_parry_part_length_cm"):
        return default_len
    return weapon.get_parry_part_length_cm()


## Striking-segment mass for parry/block; falls back to total weapon mass or baseline.


## Striking-segment mass for parry/block; falls back to total weapon mass or baseline.
static func weapon_striking_mass_kg(weapon: Variant, contact_type: String = "") -> float:
    if weapon_has_parts(weapon):
        return weapon.get_striking_part_mass_kg(contact_type)
    return weapon_mass_kg(weapon)


static func weapon_parry_part_mass_kg(weapon: Variant) -> float:
    if weapon_has_parts(weapon) and weapon.has_method("get_parry_part_mass_kg"):
        return weapon.get_parry_part_mass_kg()
    return weapon_mass_kg(weapon)


static func weapon_parry_contact_type(weapon: Variant, default_pct: String = "blade") -> String:
    if weapon == null or not weapon.has_method("get_parry_contact_type"):
        return default_pct
    return str(weapon.get_parry_contact_type())


## Cut vs blunt band for parry-speed reference (shaft/haft ->''f''s'f''s' -> blunt).


## Cut vs blunt band for parry-speed reference (shaft/haft ->''f''s'f''s' -> blunt).
static func weapon_parry_ref_contact_type(weapon: Variant) -> String:
    var pct: String = weapon_parry_contact_type(weapon)
    if pct == "shaft" or pct == "haft":
        return WeaponConstants.ATTACK_TYPE_BLUNT
    return WeaponConstants.ATTACK_TYPE_CUT


static func weapon_impact_velocity_band_max(weapon: Variant, contact_type: String) -> float:
    if weapon != null and weapon.has_method("get_impact_velocity_band_m_s"):
        return weapon.get_impact_velocity_band_m_s(contact_type).y
    return _get_impact_velocity_model().unarmed_velocity_band_m_s().y


## Wound part list for medical UI. With **`manager`**, uses **`get_health_entity`** (same as
## **`entity_get_wounded_parts`**).


## Wound part list for medical UI. With **`manager`**, uses **`get_health_entity`** (same as
## **`entity_get_wounded_parts`**).
static func get_wounded_parts(combatant: Dictionary, manager: Node = null) -> Array:
    if manager != null:
        return entity_get_wounded_parts(manager, combatant)
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_wounded_parts"):
        return []
    return node.get_wounded_parts()


static func scene_has_wounded_parts_listing(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    return node != null and node.has_method("get_wounded_parts")


## Scene node supports self direct-pressure while receiving care (wound list + can_apply API).


## Scene node supports self direct-pressure while receiving care (wound list + can_apply API).
static func scene_supports_medical_pressure_listing(combatant: Dictionary) -> bool:
    return scene_has_wounded_parts_listing(combatant) and scene_can_apply_direct_pressure_api(combatant)


static func scene_can_apply_direct_pressure_api(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    return node != null and node.has_method("_can_apply_direct_pressure")


## Health entity (CoreEntity) direct-pressure on `part`; false when entity or method missing.


## Health entity (CoreEntity) direct-pressure on `part`; false when entity or method missing.
static func entity_can_apply_direct_pressure(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("_can_apply_direct_pressure"):
        return false
    return entity._can_apply_direct_pressure(part)


static func entity_has_direct_pressure_on_part(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("has_direct_pressure_on_part"):
        return false
    return entity.has_direct_pressure_on_part(part)


static func entity_has_wound_part(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("get_wounds"):
        return false
    return entity.get_wounds().has(part)


static func entity_get_wounded_parts(manager: Node, combatant: Dictionary) -> Array:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("get_wounded_parts"):
        return []
    return entity.get_wounded_parts()


static func entity_bleeding_rate_for_part(manager: Node, combatant: Dictionary, part: String) -> float:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("get_bleeding_rate_for_part"):
        return 0.0
    return entity.get_bleeding_rate_for_part(part)


static func entity_can_apply_bandage(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("_can_apply_bandage"):
        return false
    return entity._can_apply_bandage(part)


static func entity_can_apply_stabilize(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("_can_apply_stabilize"):
        return false
    return entity._can_apply_stabilize(part)


static func entity_can_apply_packing(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("can_apply_packing"):
        return false
    return entity.can_apply_packing(part)


static func entity_can_apply_tourniquet(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("_can_apply_tourniquet"):
        return false
    return entity._can_apply_tourniquet(part)


static func entity_is_tourniquet_indicated_for_part(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method("_is_tourniquet_indicated_for_part"):
        return false
    return entity._is_tourniquet_indicated_for_part(part)


static func entity_blood_loss_death_threshold(entity: Node) -> float:
    if entity != null and entity.has_method("_get_blood_loss_death_threshold"):
        return float(entity._get_blood_loss_death_threshold())
    return BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD


static func scene_can_apply_direct_pressure(combatant: Dictionary, part: String) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_can_apply_direct_pressure"):
        return false
    return node._can_apply_direct_pressure(part)


## Wind-up completion: `apply_bandage` / `apply_packing` / `apply_tourniquet` pass `effectiveness`; other methods get
## `part` only.


## Wind-up completion: `apply_bandage` / `apply_packing` / `apply_tourniquet` pass `effectiveness`; other methods get
## `part` only.
static func entity_invoke_medical_method(
    entity: Node, method: String, part: String, effectiveness: float = 1.0
) -> Variant:
    if entity == null or method.is_empty() or not entity.has_method(method):
        return null
    if (
        method == _get_combat_constants().MOVE_TARGET_APPLY_BANDAGE
        or method == _get_combat_constants().MOVE_TARGET_APPLY_PACKING
        or method == _get_combat_constants().MOVE_TARGET_APPLY_STABILIZE
        or method == _get_combat_constants().MOVE_TARGET_APPLY_TOURNIQUET
    ):
        return entity.call(method, part, effectiveness)
    return entity.call(method, part)


static func entity_apply_direct_pressure(manager: Node, combatant: Dictionary, part: String) -> bool:
    var entity: Node = get_entity_from_manager(manager, combatant)
    if entity == null or not entity.has_method(_get_combat_constants().MOVE_ID_APPLY_DIRECT_PRESSURE):
        return false
    return entity.apply_direct_pressure(part)


static func entity_apply_direct_pressure_from_ally(
    manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
    var tgt_entity: Node = get_entity_from_manager(manager, target)
    var performer_entity: Node = get_entity_from_manager(manager, performer)
    if tgt_entity == null or not tgt_entity.has_method("_apply_direct_pressure_from_ally"):
        return false
    return tgt_entity._apply_direct_pressure_from_ally(part, performer_entity)


static func entity_stack_assist_pressure_eligible(
    manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
    var tgt_entity: Node = get_entity_from_manager(manager, target)
    var performer_entity: Node = get_entity_from_manager(manager, performer)
    if tgt_entity == null or not tgt_entity.has_method("_stack_assist_pressure_eligible"):
        return false
    return tgt_entity._stack_assist_pressure_eligible(part, performer_entity)


static func entity_stack_assist_pressure_during_ally_treatment(
    manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
    var tgt_entity: Node = get_entity_from_manager(manager, target)
    var performer_entity: Node = get_entity_from_manager(manager, performer)
    if tgt_entity == null or not tgt_entity.has_method("_stack_assist_pressure_during_ally_treatment"):
        return false
    return tgt_entity._stack_assist_pressure_during_ally_treatment(part, performer_entity)


static func scene_apply_direct_pressure(combatant: Dictionary, part: String) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method(_get_combat_constants().MOVE_ID_APPLY_DIRECT_PRESSURE):
        return false
    return node.apply_direct_pressure(part)


static func link_performer_direct_pressure_on_ally(
    manager: Node, performer: Dictionary, tgt_entity: Node, part: String
) -> void:
    var performer_entity: Node = get_entity_from_manager(manager, performer)
    if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
        performer_entity.direct_pressure_on_ally = {"node": tgt_entity, "part": part}


static func is_applying_direct_pressure_scene(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_is_applying_direct_pressure"):
        return false
    return node._is_applying_direct_pressure()


static func get_direct_pressure_part_scene(combatant: Dictionary) -> String:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_direct_pressure_part"):
        return ""
    return str(node._get_direct_pressure_part())


static func clear_direct_pressure_scene(combatant: Dictionary) -> void:
    var node = node_variant(combatant)
    if node != null and node.has_method("_clear_direct_pressure"):
        node._clear_direct_pressure()


static func prepare_for_medical_windup_scene(
    manager: Node, performer: Dictionary, target: Dictionary, part: String
) -> void:
    var perf_node: Node = scene_node(performer)
    var tgt_node: Node = scene_node(target)
    if perf_node == null or tgt_node == null:
        return
    if perf_node.has_method("_prepare_for_medical_windup"):
        perf_node._prepare_for_medical_windup(tgt_node, part)
        return
    if manager == null:
        return
    var perf_entity: Node = get_entity_from_manager(manager, performer)
    var tgt_entity: Node = get_entity_from_manager(manager, target)
    if perf_entity != null and tgt_entity != null:
        _load_entity_medical()._prepare_for_medical_windup(perf_entity, tgt_entity, part)


## Returns weapon from combatant's node, or null if node lacks get_weapon or is null.


## Returns weapon from combatant's node, or null if node lacks get_weapon or is null.
static func get_weapon(combatant: Dictionary) -> Variant:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_weapon"):
        return null
    return node.get_weapon()


## Canonical weapon template id (SWORD, AXE, …) from equipped Weapon instance.


## Canonical weapon template id (SWORD, AXE, …) from equipped Weapon instance.
static func weapon_type_id(combatant: Dictionary) -> String:
    var weapon: Variant = get_weapon(combatant)
    if weapon == null:
        return ""
    if "weapon_type" in weapon:
        return str(weapon.weapon_type).to_upper().strip_edges()
    return ""


## CoreEntity from combatant dict when present.


## CoreEntity from combatant dict when present.
static func scene_entity(combatant: Dictionary) -> CoreEntity:
    var node: Node = scene_node(combatant)
    return node as CoreEntity if node is CoreEntity else null


## Abstract weapon reach in meters; **`default_reach`** when no weapon (listing uses **0**, contests often **1.5**).


## Abstract weapon reach in meters; **`default_reach`** when no weapon (listing uses **0**, contests often **1.5**).
static func weapon_melee_reach(combatant: Dictionary, default_reach: float = 1.5) -> float:
    var weapon: Variant = get_weapon(combatant)
    if weapon == null:
        return default_reach
    return float(weapon.melee_range)


## Living ally on **`actor`**'s side (alive, same side).


## Living ally on **`actor`**'s side (alive, same side).
static func is_living_same_side(actor: Dictionary, other: Dictionary) -> bool:
    if not alive_bool(other):
        return false
    return side_str(other) == side_str(actor)


## Same-side partner still on the field for formation moves (not fled, not scene-dead).


## Same-side partner still on the field for formation moves (not fled, not scene-dead).
static func is_available_formation_partner(actor: Dictionary, other: Dictionary) -> bool:
    return is_living_same_side(actor, other) and is_alive_in_combat(other) and is_alive_in_combat(actor)


## Ally available for medical targeting (alive, same side, on field, not unconscious).


## Ally available for medical targeting (alive, same side, on field, not unconscious).
static func is_available_medical_ally(actor: Dictionary, other: Dictionary) -> bool:
    if not is_living_same_side(actor, other):
        return false
    if not is_alive_in_combat(other):
        return false
    if is_unconscious(other):
        return false
    return true


## Alive opponent on the opposite side (incapacitated opponents still count  -  distance bands, threat scans).


## Alive opponent on the opposite side (incapacitated opponents still count  -  distance bands, threat scans).
static func is_alive_opponent_of(actor: Dictionary, other: Dictionary) -> bool:
    if not alive_bool(other):
        return false
    return side_str(other) != side_str(actor)


## Living enemy of **`actor`** (alive, on field, opposite side, not incapacitated).


## Living enemy of **`actor`** (alive, on field, opposite side, not incapacitated).
static func is_living_hostile_to(actor: Dictionary, other: Dictionary) -> bool:
    if not is_alive_opponent_of(actor, other):
        return false
    if has_left_battlefield(other):
        return false
    if is_incapacitated(other):
        return false
    return true


## Alive fighter on **`side`** ( **`CombatConstants.SIDE_PLAYER`** / **`CombatConstants.SIDE_ENEMY`** ).


## Alive fighter on **`side`** ( **`CombatConstants.SIDE_PLAYER`** / **`CombatConstants.SIDE_ENEMY`** ).
static func is_alive_on_side(combatant: Dictionary, side: String) -> bool:
    return alive_bool(combatant) and side_str(combatant) == side


## Alive on **`side`**, not incapacitated.


## Alive on **`side`**, not incapacitated.
static func is_living_on_side(combatant: Dictionary, side: String) -> bool:
    return is_alive_on_side(combatant, side) and not is_incapacitated(combatant)


## Both alive on opposite sides (incapacitated opponents still count).


## Both alive on opposite sides (incapacitated opponents still count).
static func are_alive_opponents(a: Dictionary, b: Dictionary) -> bool:
    return is_alive_opponent_of(a, b) and is_alive_opponent_of(b, a)


## Both living hostiles (alive, opposite sides, neither incapacitated).


## Both living hostiles (alive, opposite sides, neither incapacitated).
static func are_living_hostiles(a: Dictionary, b: Dictionary) -> bool:
    return is_living_hostile_to(a, b) and is_living_hostile_to(b, a)


## Both combatants alive (any side; formation partners, dual-occupancy resolve).


## Both combatants alive (any side; formation partners, dual-occupancy resolve).
static func are_both_alive(a: Dictionary, b: Dictionary) -> bool:
    return alive_bool(a) and alive_bool(b)


## Alive and not incapacitated (winner / standing counts).


## Alive and not incapacitated (winner / standing counts).
static func is_standing_combatant(combatant: Dictionary) -> bool:
    if combatant.get("combat_absent", false):
        return false
    return alive_bool(combatant) and not is_incapacitated(combatant)


## Battle `side` string match only (no alive check).


## Battle `side` string match only (no alive check).
static func is_on_side(combatant: Dictionary, side: String) -> bool:
    return side_str(combatant) == side


static func is_player_side(combatant: Dictionary) -> bool:
    return is_on_side(combatant, CombatConstants.SIDE_PLAYER)


static func is_enemy_side(combatant: Dictionary) -> bool:
    return is_on_side(combatant, CombatConstants.SIDE_ENEMY)


## IV-11: stamp flags from register node (player leader / enemy commander only).


## IV-11: stamp flags from register node (player leader / enemy commander only).
static func leader_register_flags_from_node(node: Node, side: String) -> Dictionary:
    var party_leader := false
    var enemy_leader := false
    if node != null:
        if side == CombatConstants.SIDE_PLAYER and node.get("is_party_leader") == true:
            party_leader = true
        elif side == CombatConstants.SIDE_ENEMY and node.get("is_enemy_leader") == true:
            enemy_leader = true
    return {"is_party_leader": party_leader, "is_enemy_leader": enemy_leader}


## IV-11: player party leader or enemy commander  -  instant doctrine commands + telegraph focus.


## IV-11: player party leader or enemy commander  -  instant doctrine commands + telegraph focus.
static func is_formation_command_issuer(combatant: Dictionary) -> bool:
    if combatant.is_empty():
        return false
    if is_player_side(combatant) and combatant.get("is_party_leader", false):
        return true
    if is_enemy_side(combatant) and combatant.get("is_enemy_leader", false):
        return true
    return false


## IV-11: player party leader or enemy commander  -  telegraph-matching focus + diagram callouts.


## IV-11: player party leader or enemy commander  -  telegraph-matching focus + diagram callouts.
static func is_formation_telegraph_leader(combatant: Dictionary) -> bool:
    if combatant.is_empty():
        return false
    return combatant.get("is_party_leader", false) or combatant.get("is_enemy_leader", false)


## Opponent side label for **`actor`** (`player` ->''f''s'f''s' -> `enemy`, else `player`).


## Opponent side label for **`actor`** (`player` ->''f''s'f''s' -> `enemy`, else `player`).
static func opponent_side_for(actor: Dictionary) -> String:
    return opponent_side_label(side_str(actor))


## `player` ->''f''s'f''s'? `enemy` roster / formation id flip (same strings as **`side_str`**).


## `player` ->''f''s'f''s'? `enemy` roster / formation id flip (same strings as **`side_str`**).
static func opponent_side_label(side: String) -> String:
    return CombatConstants.SIDE_ENEMY if side == CombatConstants.SIDE_PLAYER else CombatConstants.SIDE_PLAYER


## Resolves the health/wounds holder for a combat scene node (e.g. Character ->''f''s'f''s' -> CoreEntity). Prefers
## **`manager.get_health_entity(node)`** (see **`CombatManager`**).


## Resolves the health/wounds holder for a combat scene node (e.g. Character ->''f''s'f''s' -> CoreEntity). Prefers
## **`manager.get_health_entity(node)`** (see **`CombatManager`**).
static func get_health_entity_from_node(manager: Node, node: Node) -> Node:
    if node == null:
        return null
    if manager != null and manager.has_method("get_health_entity"):
        return manager.get_health_entity(node)
    # Test doubles / stubs without get_health_entity: prefer implementing get_health_entity on the manager.
    if manager != null and manager.has_method("_get_entity"):
        return manager.get_entity_by_node(node)
    return node


## Returns entity from combatant dict (same resolution as get_health_entity_from_node on combatant.node).


## Returns entity from combatant dict (same resolution as get_health_entity_from_node on combatant.node).
static func get_entity_from_manager(manager: Node, combatant: Dictionary) -> Node:
    return get_health_entity_from_node(manager, scene_node(combatant))


## Home roster `formation_id` as string (empty if unset). Tactical host line: `ZoneOfControl.zone_geometry_fid_str`.


## Home roster `formation_id` as string (empty if unset). Tactical host line: `ZoneOfControl.zone_geometry_fid_str`.
static func formation_id_str(combatant: Dictionary) -> String:
    return combatant.get("formation_id", "")


## Battle `side` string (e.g. `player` / `enemy`); empty if unset.


## Battle `side` string (e.g. `player` / `enemy`); empty if unset.
static func side_str(combatant: Dictionary) -> String:
    return combatant.get("side", "")


## Formation `rank` index; uses `default_rank` when the key is missing.


## Formation `rank` index; uses `default_rank` when the key is missing.
static func rank_int(combatant: Dictionary, default_rank: int = 0) -> int:
    return int(combatant.get("rank", default_rank))


## Formation `file` index; uses `default_file` when the key is missing.


## Formation `file` index; uses `default_file` when the key is missing.
static func file_int(combatant: Dictionary, default_file: int = 0) -> int:
    return int(combatant.get("file", default_file))


## Lateral offset within the file column; clamped to **`CombatConstants.LANE_OFFSET_ABS_MAX`**.


## Lateral offset within the file column; clamped to **`CombatConstants.LANE_OFFSET_ABS_MAX`**.
static func lane_offset_float(combatant: Dictionary) -> float:
    return clampf(
        float(combatant.get("lane_offset", CombatConstants.LANE_OFFSET_DEFAULT)),
        -CombatConstants.LANE_OFFSET_ABS_MAX,
        CombatConstants.LANE_OFFSET_ABS_MAX
    )


## Monotonic combat clock on the manager (`0` when missing).


## Monotonic combat clock on the manager (`0` when missing).
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
