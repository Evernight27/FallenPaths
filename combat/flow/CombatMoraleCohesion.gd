class_name CombatMoraleCohesion
extends RefCounted

## Tier 1.5 (P6): drives `formations[fid].morale_cohesion_factor` before line cohesion each recompute.
## Priority: encounter per-side override |' mean of combatant `morale_cohesion` (alive, not incapacitated) |' 1.0.
## Flee / rout reads **`line_cohesion`** + casualty ratio via **`CombatFormationRout`** (not this factor directly).


static func apply_to_formations(manager: Node) -> void:
    if manager == null or not manager.get("formations"):
        return
    var enc: Dictionary = {}
    if manager.encounter is Dictionary:
        enc = manager.encounter as Dictionary
    for fid in [CombatConstants.SIDE_PLAYER, CombatConstants.SIDE_ENEMY]:
        var form: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
        if form.is_empty():
            continue
        var side: String = FormationSlots.formation_side_str(form, fid)
        var factor: float = _resolve_morale_cohesion_factor(manager, enc, side)
        form["morale_cohesion_factor"] = clampf(factor, CombatConstants.MORALE_COHESION_FACTOR_MIN, 1.0)


static func _resolve_morale_cohesion_factor(manager: Node, enc: Dictionary, side: String) -> float:
    var key: String = (
        CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER
        if side == CombatConstants.SIDE_PLAYER
        else CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_ENEMY
    )
    if enc.has(key):
        return float(enc[key])
    return _average_combatant_morale_cohesion(manager, side)


static func _average_combatant_morale_cohesion(manager: Node, side: String) -> float:
    var n: int = 0
    var s: float = 0.0
    for c in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, side):
            continue
        s += clampf(c.get("morale_cohesion", 1.0), 0.0, 1.0)
        n += 1
    if n <= 0:
        return 1.0
    return s / float(n)
