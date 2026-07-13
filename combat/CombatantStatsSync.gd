class_name CombatantStatsSync
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

# Runtime preload '" circular dependency (CompanyState |' CampaignEncounterBridge |' CombatantStatsSync).
static var _CompanyState: Variant = null


static func _get_company_state() -> GDScript:
    if CombatantStatsSync._CompanyState == null:
        CombatantStatsSync._CompanyState = load("res://world/CompanyState.gd")
    return CombatantStatsSync._CompanyState


## Syncs entity health/combat stats into a combatant stats dictionary.
## Used by CombatManager for _refresh_combatant_stats and get_combatants.
## Ensures single source of truth for entity--''stats copy logic.


## Copies core body/stats fields from entity to stats dict. Shared by sync_from_entity and sync_from_entity_for_register.
static func _copy_core_stats(entity: Node, stats: Dictionary) -> void:
    # Body parts (no proficiency involvement)
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
    # Core stats '"" apply proficiency bonuses when system is enabled.
    var prof_active: bool = _get_company_state().read_stub_proficiency_enabled()
    if "strength" in entity:
        stats.strength = _apply_prof_bonus(entity, "strength", entity.strength, prof_active)
    if "agility" in entity:
        stats.agility = _apply_prof_bonus(entity, "agility", entity.agility, prof_active)
    elif "speed" in entity:
        stats.agility = _apply_prof_bonus(entity, "agility", entity.speed, prof_active)
    if "intelligence" in entity:
        stats.intelligence = _apply_prof_bonus(entity, "intelligence", entity.intelligence, prof_active)
    if "endurance" in entity:
        stats.endurance = _apply_prof_bonus(entity, "endurance", entity.endurance, prof_active)
    if "perception" in entity:
        stats.perception = _apply_prof_bonus(entity, "perception", entity.perception, prof_active)


## Applies proficiency bonus to a single stat value. Returns raw value when stub is off or entity lacks proficiency data.
static func _apply_prof_bonus(entity: Node, stat_key: String, base_value: Variant, prof_active: bool) -> int:
    if not prof_active:
        return int(base_value)
    if not "_proficiency_bonus" in entity:
        return int(base_value)
    var bonus: int = entity._proficiency_bonus.get(stat_key, 0)
    return int(base_value) + bonus


## Syncs entity state into stats dict (mutates stats in place).
## If ensure_consciousness is true, calls entity.ensure_consciousness_current() first.
static func sync_from_entity(entity: Node, stats: Dictionary, ensure_consciousness: bool = true) -> void:
    if entity == null:
        return
    if ensure_consciousness and entity.has_method("ensure_consciousness_current"):
        entity.ensure_consciousness_current()
    _copy_core_stats(entity, stats)
    stats.blood_volume = _EntityAccess.get_blood_volume_from_node(entity)
    stats.total_bleeding_rate = _EntityAccess.get_total_bleeding_rate_from_node(entity)
    if entity.has_method("get_total_pain"):
        stats.total_pain = entity.get_total_pain()
    if entity.has_method("get_effective_consciousness"):
        stats.effective_consciousness = entity.get_effective_consciousness()
    if entity.has_method("get_performance_modifier"):
        stats.performance_modifier = entity.get_performance_modifier()


## Returns initial stats dict for combatant registration. Single source of truth for entity--''stats copy.
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
    _copy_core_stats(entity, s)
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
