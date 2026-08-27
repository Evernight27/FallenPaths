class_name CombatMoraleCohesion
extends RefCounted

## Tier 1.5 (P6): drives `formations[fid].morale_cohesion_factor` before line cohesion each recompute.
## Priority: encounter per-side override |' mean of combatant `morale_cohesion` (alive, not incapacitated) |' 1.0.
## Flee / rout reads **`line_cohesion`** + casualty ratio via **`CombatFormationRout`** (not this factor directly).
## MS-L5 cohesion modifier: `_compute_cohesion_modifier(combatant_id, manager)` returns float [0.5–1.5] based on
## ally proximity and banner carrier presence; applied as bonus/malus to plug action weights.
## L6 rout morale check: `morale_check_during_rout(combatant_id, manager) -> bool` gates rout behavior based on
## side morale state (returns true when the combatant's side has sufficient collective morale to resist rout).
##
## Unit-cohesion loss (fear of injury): witnessing a comrade take a wound or fall drops the side's raw
## morale-cohesion. Bounded by MORALE_DRAIN_FLOOR so line cohesion stays well above the flee threshold
## (FORMATION_FLEE_LINE_COHESION_MAX). Leader deaths are handled by the stronger leader-death shock
## (CombatFormationRout.apply_leader_death_morale_shock) and do not double-trigger the death drain.
const FEAR_WOUND_DRAIN: float = 0.01
const FEAR_DEATH_DRAIN: float = 0.02
const MORALE_DRAIN_FLOOR: float = 0.70
const MORALE_SAFE_RECOVERY_PER_SEC: float = 0.005
const PARRY_MORALE_FLOOR_MULT: float = 0.85


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
        form[DataKeys.FORMATION_MORALE_COHESION_FACTOR] = clampf(factor, CombatConstants.MORALE_COHESION_FACTOR_MIN, 1.0)


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
        s += clampf(c.get(DataKeys.MORALE_COHESION_FACTOR_RAW, 1.0), 0.0, 1.0)
        n += 1
    if n <= 0:
        return 1.0
    return s / float(n)


## MS-L5: compute a cohesion modifier [0.5–1.5] for plug actions based on ally proximity and banner carrier presence.
static func _compute_cohesion_modifier(combatant_id: int, manager: Node) -> float:
    if manager == null or combatant_id < 0:
        return 1.0
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return 1.0
    var side: String = CombatantEntityAccess.side_str(c)
    var form: Dictionary = FormationSlots.formation_record_for_manager(manager, side)
    if form.is_empty():
        return 1.0
    var cohesion_factor: float = form.get(DataKeys.FORMATION_MORALE_COHESION_FACTOR, 1.0)
    var modifier: float = 1.0
    ## Bonus for allies within close range (proximity cohesion).
    var nearby_allies: int = 0
    for other in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(other, side):
            continue
        if CombatantEntityAccess.id_int(other) == combatant_id:
            continue
        var dist: String = CombatantEntityAccess.distance_to_opponent_band(c, CombatantEntityAccess.id_int(other), "")
        if dist in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
            nearby_allies += 1
    if nearby_allies >= 2:
        modifier += 0.15 * (cohesion_factor - 0.5)
    elif nearby_allies <= 0:
        modifier -= 0.15 * (1.0 - cohesion_factor)
    ## Banner carrier presence bonus (if side has a designated banner carrier alive).
    var banner_carrier_alive: bool = false
    for other in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(other, side):
            continue
        if other.get(DataKeys.COMBATANT_BANNER_CARRIER, false):
            banner_carrier_alive = true
            break
    if banner_carrier_alive:
        modifier += 0.1 * cohesion_factor
    return clampf(modifier, 0.5, 1.5)


## L6: prerequisite for the coordinated MS-L6 rout layer — returns true when the side is still coherent enough
## (line cohesion + average morale above threshold) to make a *coordinated* rout decision. A side below the
## threshold has already collapsed; its members flee via the individual personal-crisis / abandonment paths instead.
## NOTE: this is a "coherent enough to coordinate" gate, NOT a "will resist rout" check — the caller uses it as a
## permit to run the rout layer (see CombatFormationRout.rout_cognition_pressure).
static func morale_check_during_rout(combatant_id: int, manager: Node) -> bool:
    if manager == null or combatant_id < 0:
        return false
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return false
    var side: String = CombatantEntityAccess.side_str(c)
    var form: Dictionary = FormationSlots.formation_record_for_manager(manager, side)
    if form.is_empty():
        return false
    var line_cohesion: float = form.get(DataKeys.FORMATION_LINE_COHESION, 1.0)
    var avg_morale: float = _average_combatant_morale_cohesion(manager, side)
    var threshold: float = CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD as float
    return line_cohesion > (threshold / 10.0) and avg_morale > 0.3


## Unit-cohesion loss (fear of injury): a comrade just took a wound, so every other living member of that
## side's line drops a little morale. The wounded combatant is the victim (not a witness) and is skipped.
## No-op in a 1v1 (no other same-side combatant to witness). Bounded by MORALE_DRAIN_FLOOR.
static func apply_fear_drain_for_witnesses(manager: Node, wounded_id: int) -> void:
    if manager == null:
        return
    var wounded: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, wounded_id)
    if wounded.is_empty():
        return
    var side: String = CombatantEntityAccess.side_str(wounded)
    for c in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, side):
            continue
        if CombatantEntityAccess.id_int(c) == wounded_id:
            continue
        _drain_raw_morale(c, FEAR_WOUND_DRAIN)


## Unit-cohesion loss: a comrade just fell, so every other living member of that side's line drops morale.
## The dead combatant is no longer living and is skipped by is_living_on_side. Leader deaths are handled by
## the stronger leader-death shock, so the caller skips this for the party leader (see CombatManager).
static func apply_cohesion_loss_for_witnesses(manager: Node, dead: Dictionary) -> void:
    if manager == null or dead.is_empty():
        return
    var side: String = CombatantEntityAccess.side_str(dead)
    for c in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, side):
            continue
        _drain_raw_morale(c, FEAR_DEATH_DRAIN)


static func _drain_raw_morale(c: Dictionary, amount: float) -> void:
    var raw: float = float(c.get(DataKeys.MORALE_COHESION_FACTOR_RAW, 1.0))
    c[DataKeys.MORALE_COHESION_FACTOR_RAW] = maxf(MORALE_DRAIN_FLOOR, raw - amount)


## Safe-state recovery: while waiting (out of the exchange) a fighter regains composure toward full morale.
static func recover_morale_if_safe(c: Dictionary, delta: float) -> void:
    if delta <= 0.0:
        return
    var raw: float = float(c.get(DataKeys.MORALE_COHESION_FACTOR_RAW, 1.0))
    if raw >= 1.0:
        return
    c[DataKeys.MORALE_COHESION_FACTOR_RAW] = minf(1.0, raw + MORALE_SAFE_RECOVERY_PER_SEC * delta)


## Maps per-combatant raw morale [MORALE_DRAIN_FLOOR, 1.0] to a parry readiness multiplier [0.85, 1.0].
## At full morale (1.0) there is no effect; at the drain floor (0.70) parry readiness is reduced by 15%.
## Models HEMA/clinical: fear degrades fine motor control and reaction timing for blade-on-blade catches.


static func morale_parry_readiness_mult(morale: float) -> float:
    if morale >= 1.0:
        return 1.0
    if morale <= MORALE_DRAIN_FLOOR:
        return PARRY_MORALE_FLOOR_MULT
    return lerpf(PARRY_MORALE_FLOOR_MULT, 1.0, (morale - MORALE_DRAIN_FLOOR) / (1.0 - MORALE_DRAIN_FLOOR))
