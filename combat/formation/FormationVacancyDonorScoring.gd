class_name FormationVacancyDonorScoring
extends RefCounted

## Vacancy plug reconcile, rank-0 fill policy, native line compaction. See **CombatFormationFlow** header for plug
## order.

const VACANCY_LATERAL_EDGE_META := "_vacancy_lateral_edges"
const VACANCY_PLUG_RESERVED_DONORS_META := "_vacancy_plug_reserved_donors"


static func _vacancy_lateral_begin_tracking(manager: Node) -> void:
    manager.set_meta(VACANCY_LATERAL_EDGE_META, [])
    manager.set_meta(VACANCY_PLUG_RESERVED_DONORS_META, {})


static func _vacancy_lateral_end_tracking(manager: Node) -> void:
    if manager.has_meta(VACANCY_LATERAL_EDGE_META):
        manager.remove_meta(VACANCY_LATERAL_EDGE_META)
    if manager.has_meta(VACANCY_PLUG_RESERVED_DONORS_META):
        manager.remove_meta(VACANCY_PLUG_RESERVED_DONORS_META)


static func _vacancy_plug_reserved_donors(manager: Node) -> Dictionary:
    if manager.has_meta(VACANCY_PLUG_RESERVED_DONORS_META):
        return manager.get_meta(VACANCY_PLUG_RESERVED_DONORS_META) as Dictionary
    return {}


## True if this unit already slid donor->hole this pass; blocks immediate slide back (stops 0<->1 ping-pong).


## True if this unit already slid donor->hole this pass; blocks immediate slide back (stops 0<->1 ping-pong).
static func _vacancy_lateral_is_reverse_blocked(
    manager: Node, ally_id: int, donor_file: int, hole_file: int, rk: int
) -> bool:
    if not manager.has_meta(VACANCY_LATERAL_EDGE_META):
        return false
    var arr: Array = manager.get_meta(VACANCY_LATERAL_EDGE_META) as Array
    for e in arr:
        if CombatantEntityAccess.id_int(e, -9) != ally_id:
            continue
        if e.get("rk", -9) != rk:
            continue
        if e.get("src_f", -9) == hole_file and e.get("dst_f", -9) == donor_file:
            return true
    return false


## Cross-pass undo guard: reconcile clears pass meta each run; tick + get_available_actions can otherwise alternate
## lateral fills A->B / B->A every frame.


## Cross-pass undo guard: reconcile clears pass meta each run; tick + get_available_actions can otherwise alternate
## lateral fills A->B / B->A every frame.
static func _vacancy_lateral_undo_blocked_persistent(
    manager: Node, ally: Dictionary, donor_file: int, hole_file: int, fill_rank: int
) -> bool:
    if manager == null or ally.is_empty():
        return false
    if CombatantEntityAccess.rank_int(ally, -9) != fill_rank:
        return false
    if not ally.has("formation_vacancy_lateral_reverse_lock_until"):
        return false
    var until: float = ally.get("formation_vacancy_lateral_reverse_lock_until", -1.0)
    if CombatantEntityAccess.combat_clock_float(manager) >= until:
        return false
    var last_from: int = int(ally.get("formation_vacancy_lateral_last_from_file", -999))
    var last_to: int = int(ally.get("formation_vacancy_lateral_last_to_file", -999))
    if last_from == -999 or last_to == -999:
        return false
    return hole_file == last_from and donor_file == last_to


static func _vacancy_lateral_record_edge(manager: Node, ally_id: int, src_f: int, dst_f: int, rk: int) -> void:
    var arr: Array = manager.get_meta(VACANCY_LATERAL_EDGE_META) as Array
    arr.append({"id": ally_id, "src_f": src_f, "dst_f": dst_f, "rk": rk})


static func _repack_lane_offset_after_rank_file_change(c: Dictionary) -> void:
    if c.is_empty():
        return
    c["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT


## Busy combatants must not be picked as vacancy donors (would fight slot state during swaps / wind-up).
## Units just moved by automatic plug also sit out briefly so reconcile ticks cannot ping-pong them as donors.
static func _is_ineligible_vacancy_donor(manager: Node, c: Dictionary) -> bool:
    var st: String = CombatantEntityAccess.state_str(c)
    if (
        st
        in [
            CombatConstants.STATE_SWAP_RANK,
            CombatConstants.STATE_FALLING_BACK,
            CombatConstants.STATE_WIND_UP,
            CombatConstants.STATE_RECOVERING,
            CombatConstants.STATE_MEDICAL_WIND_UP,
            CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
            CombatConstants.STATE_COWERING,
        ]
    ):
        return true
    var until: float = c.get("formation_autofill_cooldown_until", -1.0)
    if until >= 0.0 and manager != null:
        var clk: float = CombatantEntityAccess.combat_clock_float(manager)
        # Hard lock: never allow two automatic plug donations in the same simulation clock,
        # even when frontline-first override is active.
        var last_move_clk: float = c.get("formation_autofill_last_move_clock", -9999.0)
        if absf(last_move_clk - clk) < 0.0001:
            return true
        if clk < until:
            var fid_geom: String = ZoneOfControl.zone_geometry_fid_str(manager, c)
            # Frontline-first override: if rank 0 has holes, let reserves donate even during autofill cooldown.
            if not formation_has_rank0_hole(manager, fid_geom):
                return true
    return false


## First living occupant in `slots` at `key` for this formation side (dual cells: try each id; skip busy donors).


## First living occupant in `slots` at `key` for this formation side (dual cells: try each id; skip busy donors).
static func _combatant_from_slot_primary_living(
    manager: Node, slots: Dictionary, key: Vector2i, fid: String, side_wanted: String
) -> Variant:
    var arr: Array = FormationSlots.normalize_cell(slots.get(key, []))
    for cid in arr:
        var ally: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, int(cid))
        if ally.is_empty() or not CombatantEntityAccess.is_alive_on_side(ally, side_wanted):
            continue
        if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, ally, fid):
            continue
        if FormationVacancyDonorScoring._is_ineligible_vacancy_donor(manager, ally):
            continue
        return ally
    return null


## Higher = fitter to hold the line (performance, legs, blood). Incapacitated fighters score very low.


## Higher = fitter to hold the line (performance, legs, blood). Incapacitated fighters score very low.
static func _plug_effectiveness_score(manager: Node, c: Dictionary) -> float:
    if CombatantEntityAccess.is_incapacitated(c):
        return -100.0
    var perf: float = clampf(CombatantEntityAccess.get_performance_modifier(c), 0.0, 2.0)
    var leg: float = clampf(CombatantEntityAccess.get_leg_functionality(c), 0.0, 1.0)
    if is_nan(perf) or is_inf(perf):
        perf = 1.0
    if is_nan(leg) or is_inf(leg):
        leg = 1.0
    var blood_f: float = 1.0
    var ent: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
    if ent != null:
        blood_f = clampf(CombatantEntityAccess.get_blood_volume_from_node(ent) / 100.0, 0.0, 1.0)
    if is_nan(blood_f) or is_inf(blood_f):
        blood_f = 1.0
    return perf * 0.45 + leg * 0.35 + blood_f * 0.2


## 0 = unfit to plug, 1 = peak readiness (for nonlinear curve).


## 0 = unfit to plug, 1 = peak readiness (for nonlinear curve).
static func _plug_effectiveness_normalized_0_1(manager: Node, c: Dictionary) -> float:
    var raw: float = FormationVacancyDonorScoring._plug_effectiveness_score(manager, c)
    if raw <= -50.0:
        return 0.0
    return clampf(raw / 1.5, 0.0, 1.0)


## Single score: nonlinear penalty on low effectiveness can override raw proximity when fit allies exist elsewhere.
## `fill_rank`: when 0 (front row hole), adds urgency so the line closes before lateral shuffles when scores are close.


## Single score: nonlinear penalty on low effectiveness can override raw proximity when fit allies exist elsewhere.
## `fill_rank`: when 0 (front row hole), adds urgency so the line closes before lateral shuffles when scores are close.
static func _plug_priority_score(manager: Node, prox_steps: int, c: Dictionary, fill_rank: int = -1) -> float:
    var eff_n: float = FormationVacancyDonorScoring._plug_effectiveness_normalized_0_1(manager, c)
    if is_nan(eff_n) or is_inf(eff_n):
        eff_n = 0.0
    var exp_n: float = CombatConstants.FORMATION_PLUG_EFFECTIVENESS_EXPONENT
    if is_nan(exp_n) or is_inf(exp_n) or exp_n <= 0.0:
        exp_n = 2.0
    var nonlinear: float = pow(eff_n, exp_n)
    var w: float = CombatConstants.FORMATION_PLUG_PROXIMITY_WEIGHT
    if is_nan(w) or is_inf(w) or w < 0.0:
        w = 0.28
    var prox_factor: float = 1.0 / (1.0 + w * float(max(0, prox_steps)))
    var pri: float = nonlinear * prox_factor
    if fill_rank == 0:
        pri += CombatConstants.FORMATION_PLUG_RANK0_URGENCY_BONUS
    if is_nan(pri) or is_inf(pri):
        return 0.0
    return pri


## Best vertical option for this hole (same column, deeper ranks). Evaluated separately from lateral.
## When `adjacent_rank_only`, walk ranks shallow|'deep: skip empty ranks; **skip** ranks whose primary native
## is not a legal donor (wind-up, reserved elsewhere, foreign occupant cell, etc.) and keep scanning so a deeper
## reserve can still plug the hole without forcing a front-rank lateral shuffle. Stop at the first **eligible,
## unreserved** donor (closest promotable native  -  do not jump over them to pull someone even deeper).
## When false, scan the full column and keep the best-scoring eligible donor (full-column donor scan).


## Best vertical option for this hole (same column, deeper ranks). Evaluated separately from lateral.
## When `adjacent_rank_only`, walk ranks shallow|'deep: skip empty ranks; **skip** ranks whose primary native
## is not a legal donor (wind-up, reserved elsewhere, foreign occupant cell, etc.) and keep scanning so a deeper
## reserve can still plug the hole without forcing a front-rank lateral shuffle. Stop at the first **eligible,
## unreserved** donor (closest promotable native  -  do not jump over them to pull someone even deeper).
## When false, scan the full column and keep the best-scoring eligible donor (full-column donor scan).
static func _evaluate_best_vertical_plug_for_cell(
    manager: Node,
    fid: String,
    slots: Dictionary,
    fill_rank: int,
    file: int,
    formation_ranks: int,
    side_wanted: String,
    reserved: Dictionary,
    adjacent_rank_only: bool = true
) -> Dictionary:
    var best: Dictionary = {}
    var best_pri: float = -1.0
    var rank_tie_eps: float = 1e-4
    if adjacent_rank_only:
        var search_rank: int = fill_rank + 1
        while search_rank < formation_ranks:
            if not FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(search_rank, file)):
                search_rank += 1
                continue
            var ally_v: Variant = FormationVacancyDonorScoring._combatant_from_slot_primary_living(
                manager, slots, Vector2i(search_rank, file), fid, side_wanted
            )
            if ally_v == null:
                search_rank += 1
                continue
            var aid: int = CombatantEntityAccess.id_int(ally_v)
            if reserved.get(aid, false):
                search_rank += 1
                continue
            var prox: int = search_rank - fill_rank
            var pri: float = FormationVacancyDonorScoring._plug_priority_score(manager, prox, ally_v, fill_rank)
            var cand: Dictionary = {
                "ally": ally_v,
                "kind": "vertical",
                "from_rank": search_rank,
                "from_file": file,
                "prox": prox,
                "pri": pri,
            }
            if best.is_empty() or pri > best_pri + rank_tie_eps:
                best = cand
                best_pri = pri
            elif absf(pri - best_pri) <= rank_tie_eps:
                if search_rank < int(best.get("from_rank", 999)):
                    best = cand
                    best_pri = pri
            break
        return best
    for search_rank in range(fill_rank + 1, formation_ranks):
        var ally_v2: Variant = FormationVacancyDonorScoring._combatant_from_slot_primary_living(
            manager, slots, Vector2i(search_rank, file), fid, side_wanted
        )
        if ally_v2 == null:
            continue
        var aid2: int = CombatantEntityAccess.id_int(ally_v2)
        if reserved.get(aid2, false):
            continue
        var prox2: int = search_rank - fill_rank
        var pri2: float = FormationVacancyDonorScoring._plug_priority_score(manager, prox2, ally_v2, fill_rank)
        var cand2: Dictionary = {
            "ally": ally_v2,
            "kind": "vertical",
            "from_rank": search_rank,
            "from_file": file,
            "prox": prox2,
            "pri": pri2,
        }
        if best.is_empty() or pri2 > best_pri + rank_tie_eps:
            best = cand2
            best_pri = pri2
        elif absf(pri2 - best_pri) <= rank_tie_eps:
            if search_rank < int(best.get("from_rank", 999)):
                best = cand2
                best_pri = pri2
    return best


## True when ranks `1 .. search_rank-1` in the hole file have no **promotable** occupant (same filters as vertical
## donors).
## Lets a reserve in an adjacent file step into a rank-0 hole when the same column cannot promote (or first deeper is
## busy)
## without treating a wind-up ally in-column as a hard blocker for rear infill.


## True when ranks `1 .. search_rank-1` in the hole file have no **promotable** occupant (same filters as vertical
## donors).
## Lets a reserve in an adjacent file step into a rank-0 hole when the same column cannot promote (or first deeper is
## busy)
## without treating a wind-up ally in-column as a hard blocker for rear infill.
static func _rear_infill_hole_column_passable(
    manager: Node,
    fid: String,
    slots: Dictionary,
    hole_file: int,
    search_rank: int,
    side_wanted: String,
) -> bool:
    for rr in range(1, search_rank):
        if not FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(rr, hole_file)):
            continue
        if (
            FormationVacancyDonorScoring._combatant_from_slot_primary_living(
                manager, slots, Vector2i(rr, hole_file), fid, side_wanted
            )
            != null
        ):
            return false
    return true

## Rank-0 hole only: best **rear** donor on **any other** file (rank '''deg' 1) who can occupy the front slot in one
## plug.
## Deeper ranks preferred as donors first (then shallower); ties prefer smaller |file 'I??' hole| then lower file index.
## Proximity for scoring includes file distance so farther sidesteps lose to nearer fit reserves before front-rank
## lateral.
