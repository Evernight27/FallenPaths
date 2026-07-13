class_name CombatMeleeRankTargeting
extends RefCounted

## Melee rank / depth-lane gates shared by action listing.


static func melee_pair_rank_allowed(manager: Node, attacker: Dictionary, defender: Dictionary) -> bool:
    var ar: int = CombatantEntityAccess.rank_int(attacker)
    var dr: int = CombatantEntityAccess.rank_int(defender)
    if ar == 0 and dr == 0:
        return true
    if manager != null and ar > 0 and dr == 0:
        return CombatDepthPolearm.depth_polearm_valid_line_threat(manager, attacker, defender)
    return false


static func opp_matches_melee_rank_target(
    manager: Node, actor: Dictionary, opp: Dictionary, opp_rank_required: int
) -> bool:
    if not CombatantEntityAccess.is_living_hostile_to(actor, opp):
        return false
    var ornk: int = CombatantEntityAccess.rank_int(opp)
    if ornk == opp_rank_required:
        if opp_rank_required == 0 and CombatantEntityAccess.rank_int(actor) > 0:
            if manager == null or not CombatDepthPolearm.depth_polearm_valid_line_threat(manager, actor, opp):
                return false
        return true
    return false


## True when any opponent passes **`opp_matches_melee_rank_target(..., 0)`** (stalemate rank-1 pass when all front
## enemies are incap).
static func any_living_enemy_rank0_target(manager: Node, actor: Dictionary, combatants: Array) -> bool:
    for opp in combatants:
        if opp_matches_melee_rank_target(manager, actor, opp, 0):
            return true
    return false
