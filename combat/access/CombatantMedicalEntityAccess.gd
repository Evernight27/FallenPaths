class_name CombatantMedicalEntityAccess
extends CombatantWeaponAccess

## Entity and scene medical / wound accessors.

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
static func scene_entity(combatant: Dictionary) -> CoreEntity:
    var node: Node = scene_node(combatant)
    return node as CoreEntity if node is CoreEntity else null


## Abstract weapon reach in meters; **`default_reach`** when no weapon (listing uses **0**, contests often **1.5**).


## Abstract weapon reach in meters; **`default_reach`** when no weapon (listing uses **0**, contests often **1.5**).
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
static func entity_has_untreated_wounds(entity: Node) -> bool:
    return _get_entity_wounds().entity_has_untreated_wounds(entity)


## Medical danger / peril  -  delegates to **`MedicalPhaseController`** (AGENTS canonical names).


## Medical danger / peril  -  delegates to **`MedicalPhaseController`** (AGENTS canonical names).
static func is_in_medical_danger(manager: Node, c: Dictionary) -> bool:
    return _get_medical_phase().is_in_medical_danger(manager, c)


static func is_in_immediate_peril(manager: Node, c: Dictionary) -> bool:
    return _get_medical_phase().is_in_immediate_peril(manager, c)


static func has_left_immediate_peril_permanently(manager: Node, c: Dictionary) -> bool:
    return _get_medical_phase().has_left_immediate_peril_permanently(manager, c)


## True when formation **retreat** (disengage swap, drag/fall_back pair, solo fall_back) is justified by injury or peril
## -  not fatigue-only composite fitness.


## True when formation **retreat** (disengage swap, drag/fall_back pair, solo fall_back) is justified by injury or peril
## -  not fatigue-only composite fitness.
static func get_medical_windup_speed_modifier(manager: Node, performer: Dictionary, target: Dictionary) -> float:
    var perf_entity: Node = get_entity_from_manager(manager, performer)
    var med_eff: float = get_medical_effectiveness_from_node(perf_entity)
    med_eff = maxf(0.5, med_eff)
    if id_int(performer) == id_int(target):
        var perf: float = get_performance_modifier(performer)
        return maxf(CombatConstants.PERF_MOD_MIN, perf) * med_eff
    var patient_perf: float = get_performance_modifier(target)
    var thrash: float = (
        clampf(1.0 - patient_perf, 0.0, 1.0) * CombatConstants.MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY
    )
    return med_eff * (1.0 - thrash)


## Effective medical wind-up speed: reads INT from combatant stats dict (includes proficiency bonuses via
## _copy_core_stats()).
## Use this when proficiency system is enabled instead of get_medical_windup_speed_modifier().


## Effective medical wind-up speed: reads INT from combatant stats dict (includes proficiency bonuses via
## _copy_core_stats()).
## Use this when proficiency system is enabled instead of get_medical_windup_speed_modifier().
static func get_effective_medical_windup_speed_modifier(
    _manager: Node, performer: Dictionary, target: Variant
) -> float:
    var perf_node = node_variant(performer)
    var eff_int: float = 100.0
    if perf_node != null and "_proficiency_bonus" in perf_node:
        eff_int = float(perf_node.intelligence or 0) + float(perf_node._proficiency_bonus.get("intelligence", 0) or 0)
    else:
        eff_int = float(performer.get("intelligence", CombatConstants.DEFAULT_STAT_VALUE))
    var med_eff: float = clampf(
        eff_int / 100.0, CombatConstants.STAT_EFFECT_MULT_MIN, CombatConstants.STAT_EFFECT_MULT_MAX
    )
    med_eff = maxf(0.5, med_eff)
    if id_int(performer) == id_int(target):
        var perf: float = get_performance_modifier(performer)
        return maxf(CombatConstants.PERF_MOD_MIN, perf) * med_eff
    var patient_perf: float = get_performance_modifier(target)
    var thrash: float = (
        clampf(1.0 - patient_perf, 0.0, 1.0) * CombatConstants.MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY
    )
    return med_eff * (1.0 - thrash)


## Divisor for dressing wind-up when compression is held (primary holder / stacked assist).


## Divisor for dressing wind-up when compression is held (primary holder / stacked assist).
static func get_medical_windup_assist_duration_divisor(manager: Node, target: Dictionary, part: String) -> float:
    var divisor: float = 1.0
    var tgt_entity: Node = get_entity_from_manager(manager, target)
    if tgt_entity == null or part.is_empty():
        return divisor
    if part_has_active_direct_pressure_on_entity(tgt_entity, part):
        divisor += CombatConstants.MEDICAL_WINDUP_PRIMARY_HOLDER_DURATION_BONUS
    if tgt_entity.get("direct_pressure_assist_held_by") != null and tgt_entity.direct_pressure_assist_held_by != null:
        divisor += CombatConstants.MEDICAL_WINDUP_STACK_ASSIST_DURATION_BONUS
    return divisor


static func part_has_active_direct_pressure_on_entity(entity: Node, part: String) -> bool:
    if entity == null or part.is_empty():
        return false
    if entity.has_method("has_direct_pressure_on_part"):
        return entity.has_direct_pressure_on_part(part)
    return false


static func get_medical_effectiveness_from_node(node: Node) -> float:
    if node == null:
        return 1.0
    if node.has_method("_get_medical_effectiveness"):
        return node._get_medical_effectiveness()
    return 1.0


