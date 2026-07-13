class_name CampaignComposureSync
extends RefCounted

## Persists in-combat composure gauge onto party CoreEntity between fights (COMPOSURE_PLAN §8B).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func sync_from_manager(manager: Node) -> void:
    if manager == null or not ("combatants" in manager):
        return
    for raw in manager.combatants:
        if raw is not Dictionary:
            continue
        var c: Dictionary = raw as Dictionary
        if _EntityAccess.side_str(c) != CombatConstants.SIDE_PLAYER:
            continue
        if not _EntityAccess.alive_bool(c):
            continue
        var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
        if entity == null or not entity.has_method("set_campaign_composure_readiness"):
            continue
        entity.set_campaign_composure_readiness(_EntityAccess.gauge_float(c))


static func restore_party_at_camp(world: Node2D) -> void:
    if world == null:
        return
    const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
    for n in _Bridge.get_fightable_party_nodes(world):
        var entity: Node = _Bridge.health_entity_from_character(n)
        if entity != null and entity.has_method("restore_campaign_composure_at_camp"):
            entity.restore_campaign_composure_at_camp()
        if entity != null and entity.has_method("restore_muscle_fatigue_at_camp"):
            entity.restore_muscle_fatigue_at_camp()
