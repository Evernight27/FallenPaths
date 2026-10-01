class_name CombatExecute
extends RefCounted

## Mercy & execution decision module (plan_mercy_execute §1 / §3 / §10 / §13).
## Execute weight = base_ai_weight(MOVE_ID_EXECUTE) × personality × mood × threat × grudge, folded into the
## existing action-weight pipeline (CombatAIActionWeights branch). "Spare" is the implicit fallback: not choosing
## execute leaves the target downed, and post-victory spared units become prisoners (§4).
## Downed predicate lives here, beside `CombatantIdentityAccess.is_living_hostile_to`.
## Tuning knobs (plan §10): EXECUTE_BASE_AI_WEIGHT low (execute is not a default habit), RUTHLESSNESS_MULT
## 0.4…1.6 over 0…100 (50 = 1.0), mood ramp low→spare / high→execute, EXECUTE_THREATENED_MULT ≤0.2 while any
## enemy in melee reach, EXECUTE_GRUDGE_MULT ≥1.5 when the executor dealt damage to the target.

const EXECUTE_BASE_AI_WEIGHT := 0.12  # ~5-10% of a standard attack's weight (plan §13, R1/R2)
const EXECUTE_RUTHLESSNESS_MULT_MIN := 0.4  # ruthlessness 0 → spare bias
const EXECUTE_RUTHLESSNESS_MULT_MAX := 1.6  # ruthlessness 100 → execute bias
const EXECUTE_RUTHLESSNESS_NEUTRAL := 50.0  # 50 = 1.0 (neutral personality, no bias)
const EXECUTE_THREATENED_MULT := 0.2  # any enemy in melee reach of executor → dampen to 0.2×
const EXECUTE_GRUDGE_MULT := 1.5  # executor dealt damage to the target → boost


## Downed predicate: **`target`** is alive, on the field, an opponent of **`attacker`**, and not standing
## (**`is_incapacitated`** covers cowering/unconscious; the bridge also treats `STATE_YIELDED` as incapacitated).
static func is_downed_opponent_of(manager: Node, attacker: Dictionary, target: Dictionary) -> bool:
    if manager == null or attacker.is_empty() or target.is_empty():
        return false
    if not CombatantIdentityAccess.is_alive_opponent_of(attacker, target):
        return false
    if CombatantEntityAccess.has_left_battlefield(target):
        return false
    return not CombatantEntityAccess.is_standing_combatant(target)


## Personality mult: linear ramp over ruthlessness 0…100 with 50 = 1.0 (plan §13).
static func personality_mult(ruthlessness: float) -> float:
    var ruth: float = clampf(ruthlessness, 0.0, 100.0)
    if ruth <= EXECUTE_RUTHLESSNESS_NEUTRAL:
        return lerpf(EXECUTE_RUTHLESSNESS_MULT_MIN, 1.0, ruth / EXECUTE_RUTHLESSNESS_NEUTRAL)
    return lerpf(
        1.0,
        EXECUTE_RUTHLESSNESS_MULT_MAX,
        (ruth - EXECUTE_RUTHLESSNESS_NEUTRAL) / (100.0 - EXECUTE_RUTHLESSNESS_NEUTRAL)
    )


## Mood mult: low morale → sparing (<1.0), high morale → executing (>1.0). Reuses the existing
## **`CombatCampaignMoodBias.offense_action_weight_mult`** ramp (plan §1 / §10).
static func mood_mult(manager: Node, c: Dictionary) -> float:
    return CombatCampaignMoodBias.offense_action_weight_mult(CombatCampaignMoodBias.mood_bias_for_combatant(manager, c))


## Threat mult: 1.0 when the executor has no rank-0 melee opponents **in reach** (not engaged → safe to finish),
## else **`EXECUTE_THREATENED_MULT`** while any enemy can melee-threaten (plan §1 / §13 R3).
static func threat_mult(manager: Node, c: Dictionary) -> float:
    var opps: Array = CombatTargetScoring.ordered_melee_opponents(manager, c, _combatant_rows(manager), 0)
    if opps.is_empty():
        return 1.0
    var weapon = CombatantEntityAccess.get_weapon(c)
    if weapon == null or not CombatantEntityAccess.weapon_has_attack_types(weapon):
        return 1.0
    var melee_range: float = float(weapon.melee_range)
    for opp in opps:
        if not CombatantEntityAccess.is_standing_combatant(opp):
            continue
        var eff_dist: float = CombatPairGeometry.effective_pair_eff_dist(manager, c, opp)
        var dist_band: String = CombatantEntityAccess.distance_to_opponent_band(
            c, CombatantEntityAccess.id_int(opp), ""
        )
        if dist_band == CombatConstants.DISTANCE_LONG:
            continue
        if CombatPairGeometry.melee_reach_covers_eff_dist(melee_range, eff_dist):
            return EXECUTE_THREATENED_MULT
    return 1.0


## Grudge mult: **`EXECUTE_GRUDGE_MULT`** when the executor's per-pair damage ledger shows damage dealt to the
## target, else 1.0 (plan §1 / §13 R2 — personal violence is the strongest signal).
static func grudge_mult(c: Dictionary, target_id: int) -> float:
    var ledger: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID)
    if float(ledger.get(target_id, 0.0)) > 0.0:
        return EXECUTE_GRUDGE_MULT
    return 1.0


## Full execute decision weight (plan §1). Returns 0.0 when the target is not a downed opponent.
## Base weight is low (execute is not a default habit); personality/mood/threat/grudge move the number.
static func execute_weight(manager: Node, c: Dictionary, target: Dictionary) -> float:
    if not is_downed_opponent_of(manager, c, target):
        return 0.0
    var ruth: float = float(c.get(DataKeys.COMBATANT_RUTHLESSNESS, EXECUTE_RUTHLESSNESS_NEUTRAL))
    return (
        EXECUTE_BASE_AI_WEIGHT
        * personality_mult(ruth)
        * mood_mult(manager, c)
        * threat_mult(manager, c)
        * grudge_mult(c, CombatantEntityAccess.id_int(target))
    )


## Live **`CombatManager.combatants`** dicts (not UI snapshot from **`get_combatants()`**) — same source as
## **`CombatMeleeListing._live_combatant_rows`**.
static func _combatant_rows(manager: Node) -> Array:
    if manager == null:
        return []
    var live: Variant = manager.get("combatants")
    if live is Array:
        return live as Array
    if manager.has_method("get_combatants"):
        return manager.get_combatants()
    return []
