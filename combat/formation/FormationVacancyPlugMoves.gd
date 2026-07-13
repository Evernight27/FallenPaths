class_name FormationVacancyPlugMoves
extends RefCounted

## Vacancy plug reconcile, rank-0 fill policy, native line compaction. See **CombatFormationFlow** header for plug
## order.

const VACANCY_LATERAL_EDGE_META := "_vacancy_lateral_edges"
const VACANCY_PLUG_RESERVED_DONORS_META := "_vacancy_plug_reserved_donors"


## Rank-0 hole only: best **rear** donor on **any other** file (rank '''deg' 1) who can occupy the front slot in one
## plug.
## Deeper ranks preferred as donors first (then shallower); ties prefer smaller |file 'I??' hole| then lower file index.
## Proximity for scoring includes file distance so farther sidesteps lose to nearer fit reserves before front-rank
## lateral.
static func _evaluate_best_rear_infill_for_rank0_hole(
    manager: Node,
    fid: String,
    slots: Dictionary,
    hole_file: int,
    nfiles: int,
    formation_ranks: int,
    side_wanted: String,
    reserved: Dictionary
) -> Dictionary:
    var best: Dictionary = {}
    var best_pri: float = -1.0
    var rank_tie_eps: float = 1e-4
    for nf in range(nfiles):
        if nf == hole_file:
            continue
        for search_rank in range(formation_ranks - 1, 0, -1):
            if not FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(search_rank, nf)):
                continue
            var ally_r: Variant = FormationVacancyDonorScoring._combatant_from_slot_primary_living(
                manager, slots, Vector2i(search_rank, nf), fid, side_wanted
            )
            if ally_r == null:
                continue
            var aid: int = CombatantEntityAccess.id_int(ally_r)
            if reserved.get(aid, false):
                continue
            if not FormationVacancyDonorScoring._rear_infill_hole_column_passable(
                manager, fid, slots, hole_file, search_rank, side_wanted
            ):
                continue
            if FormationVacancyDonorScoring._vacancy_lateral_is_reverse_blocked(manager, aid, nf, hole_file, 0):
                continue
            var file_dist: int = abs(nf - hole_file)
            var prox: int = search_rank + file_dist
            var pri: float = FormationVacancyDonorScoring._plug_priority_score(manager, prox, ally_r, 0)
            var cand: Dictionary = {
                "ally": ally_r,
                "kind": "rear_infill",
                "from_rank": search_rank,
                "from_file": nf,
                "prox": prox,
                "pri": pri,
            }
            if best.is_empty() or pri > best_pri + rank_tie_eps:
                best = cand
                best_pri = pri
            elif absf(pri - best_pri) <= rank_tie_eps:
                var best_fr: int = int(best.get("from_rank", 999))
                var best_nf: int = int(best.get("from_file", 999))
                var best_fd: int = abs(best_nf - hole_file)
                if search_rank > best_fr:
                    best = cand
                    best_pri = pri
                elif search_rank == best_fr:
                    if file_dist < best_fd:
                        best = cand
                        best_pri = pri
                    elif file_dist == best_fd and nf < best_nf:
                        best = cand
                        best_pri = pri
                    elif (
                        file_dist == best_fd
                        and nf == best_nf
                        and (
                            aid
                            < CombatantEntityAccess.id_int(
                                CombatantEntityAccess.nested_dictionary_read(best, "ally"), 999999
                            )
                        )
                    ):
                        best = cand
                        best_pri = pri
    return best


## Best **front-rank** lateral option for this hole (same rank, adjacent files only). Evaluated after vertical and rear
## infill.


## Best **front-rank** lateral option for this hole (same rank, adjacent files only). Evaluated after vertical and rear
## infill.
static func _evaluate_best_lateral_plug_for_cell(
    manager: Node,
    fid: String,
    slots: Dictionary,
    fill_rank: int,
    file: int,
    nfiles: int,
    formation_ranks: int,
    side_wanted: String,
    reserved: Dictionary
) -> Dictionary:
    var best: Dictionary = {}
    var best_pri: float = -1.0
    var file_tie_eps: float = 1e-4
    for dfile in [-1, 1]:
        var nf: int = file + dfile
        if nf < 0 or nf >= nfiles:
            continue
        if not FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(fill_rank, nf)):
            continue
        var ally_l: Variant = FormationVacancyDonorScoring._combatant_from_slot_primary_living(
            manager, slots, Vector2i(fill_rank, nf), fid, side_wanted
        )
        if ally_l == null:
            continue
        var aid: int = CombatantEntityAccess.id_int(ally_l)
        if reserved.get(aid, false):
            continue
        if FormationVacancyDonorScoring._vacancy_lateral_is_reverse_blocked(manager, aid, nf, file, fill_rank):
            continue
        if FormationVacancyDonorScoring._vacancy_lateral_undo_blocked_persistent(
            manager, ally_l, nf, file, fill_rank
        ):
            continue
        if (
            fill_rank == 0
            and not FormationVacancyPlugMoves._rank0_lateral_slide_allowed(
                manager, slots, file, nf, formation_ranks, fid, side_wanted
            )
        ):
            continue
        var pri: float = FormationVacancyDonorScoring._plug_priority_score(manager, 1, ally_l, fill_rank)
        var cand: Dictionary = {
            "ally": ally_l,
            "kind": "lateral",
            "from_rank": fill_rank,
            "from_file": nf,
            "prox": 1,
            "pri": pri,
        }
        if best.is_empty() or pri > best_pri + file_tie_eps:
            best = cand
            best_pri = pri
        elif absf(pri - best_pri) <= file_tie_eps:
            if nf < int(best.get("from_file", 999)):
                best = cand
                best_pri = pri
    return best


## Strips scoring fields; `_apply_plug_move` only needs ally/kind/from_rank/from_file.


## Strips scoring fields; `_apply_plug_move` only needs ally/kind/from_rank/from_file.
static func _plug_move_for_apply(move: Dictionary) -> Dictionary:
    if move.is_empty():
        return {}
    return {
        "ally": move["ally"],
        "kind": move["kind"],
        "from_rank": move.get("from_rank", 0),
        "from_file": move.get("from_file", 0),
        "prox": move.get("prox", 0),
    }


## Resolves one hole: vertical first, then rank-0 rear infill, then same-rank lateral (see file header).


## Resolves one hole: vertical first, then rank-0 rear infill, then same-rank lateral (see file header).
static func _select_best_plug_move_for_empty_cell(
    manager: Node,
    fid: String,
    slots: Dictionary,
    fill_rank: int,
    file: int,
    formation_ranks: int,
    nfiles: int,
    side_wanted: String,
    reserved: Dictionary,
    adjacent_vertical_only: bool = true,
    allow_lateral: bool = true
) -> Dictionary:
    var vert: Dictionary = FormationVacancyDonorScoring._evaluate_best_vertical_plug_for_cell(
        manager, fid, slots, fill_rank, file, formation_ranks, side_wanted, reserved, adjacent_vertical_only
    )
    if not vert.is_empty():
        return FormationVacancyPlugMoves._plug_move_for_apply(vert)
    if allow_lateral:
        if fill_rank == 0 and formation_ranks > 1:
            var rear: Dictionary = FormationVacancyPlugMoves._evaluate_best_rear_infill_for_rank0_hole(
                manager, fid, slots, file, nfiles, formation_ranks, side_wanted, reserved
            )
            if not rear.is_empty():
                return FormationVacancyPlugMoves._plug_move_for_apply(rear)
        var lat: Dictionary = FormationVacancyPlugMoves._evaluate_best_lateral_plug_for_cell(
            manager, fid, slots, fill_rank, file, nfiles, formation_ranks, side_wanted, reserved
        )
        if not lat.is_empty():
            return FormationVacancyPlugMoves._plug_move_for_apply(lat)
    return {}


static func _apply_plug_move(
    manager: Node, slots: Dictionary, move: Dictionary, fill_rank: int, file: int, log_prefix: String
) -> void:
    var ally: Dictionary = move["ally"]
    var kind: String = str(move.get("kind", "vertical"))
    var from_f: int = move.get("from_file", 0)
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(ally))
    ally.rank = fill_rank
    ally.file = file
    CombatDoctrine.clear_combatant_doctrine_commitment(ally)
    FormationVacancyDonorScoring._repack_lane_offset_after_rank_file_change(ally)
    FormationSlots.slot_set_single(slots, Vector2i(fill_rank, file), CombatantEntityAccess.id_int(ally))
    ally["formation_autofill_cooldown_until"] = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S
    )
    ally["formation_autofill_last_move_clock"] = CombatantEntityAccess.combat_clock_float(manager)
    if kind == "lateral" or kind == "rear_infill":
        ally["formation_vacancy_lateral_last_from_file"] = from_f
        ally["formation_vacancy_lateral_last_to_file"] = file
        ally["formation_vacancy_lateral_reverse_lock_until"] = (
            CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_VACANCY_LATERAL_REVERSE_LOCK_S
        )
        if manager.has_meta(VACANCY_LATERAL_EDGE_META):
            FormationVacancyDonorScoring._vacancy_lateral_record_edge(
                manager, CombatantEntityAccess.id_int(ally), from_f, file, fill_rank
            )
    else:
        ally.erase("formation_vacancy_lateral_last_from_file")
        ally.erase("formation_vacancy_lateral_last_to_file")
        ally.erase("formation_vacancy_lateral_reverse_lock_until")
    if CombatConstants.COMBAT_FORMATION_PLUG_MOVE_DEBUG:
        var name_p: String = CombatantEntityAccess.get_display_name(ally, CombatantEntityAccess.id_int(ally))
        var plug_msg: String = ""
        if kind == "lateral":
            plug_msg = "%s: %s slid file %d -> %d (rank %d)" % [log_prefix, name_p, from_f, file, fill_rank]
        elif kind == "rear_infill":
            plug_msg = (
                "%s: %s rear infill rank %d file %d -> rank %d file %d"
                % [log_prefix, name_p, move.get("from_rank", 0), from_f, fill_rank, file]
            )
        else:
            plug_msg = "%s: %s advanced to rank %d (file %d)" % [log_prefix, name_p, fill_rank, file]
        if not plug_msg.is_empty():
            CombatDebug.combat_session(plug_msg)
    elif CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG and str(log_prefix).begins_with("Vacancy"):
        var name_v: String = CombatantEntityAccess.get_display_name(ally, CombatantEntityAccess.id_int(ally))
        CombatDebug.formation_vacancy_log(
            "%s: %s |' rank %d file %d (%s)" % [log_prefix, name_v, fill_rank, file, kind]
        )
    if manager.has_meta(VACANCY_PLUG_RESERVED_DONORS_META):
        var rd: Dictionary = manager.get_meta(VACANCY_PLUG_RESERVED_DONORS_META) as Dictionary
        rd[CombatantEntityAccess.id_int(ally)] = true
    var ready_delay: float = CombatConstants.READY_DELAY_AFTER_PROMOTION_S
    if kind == "rear_infill":
        var fdist: int = abs(int(from_f) - int(file))
        ready_delay += float(fdist) * CombatConstants.FORMATION_PLUG_REAR_CROSS_FILE_READY_PER_FILE_S
    CombatEventScheduler.schedule_action_ready(manager, CombatantEntityAccess.id_int(ally), ready_delay)
    CombatFootwork.reconcile_idle_offset(ally)


## True when this file has a living occupant strictly deeper than `rank_i`.
## Vacancy reconcile should not force-fill optional rear depth (e.g. lone reserve bouncing between files).


## True when this file has a living occupant strictly deeper than `rank_i`.
## Vacancy reconcile should not force-fill optional rear depth (e.g. lone reserve bouncing between files).
static func _has_living_deeper_in_file(
    manager: Node, slots: Dictionary, rank_i: int, file: int, formation_ranks: int
) -> bool:
    for rr in range(rank_i + 1, formation_ranks):
        if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(rr, file)):
            return true
    return false


## True if any rank below `rank_i` has a **vacancy vertical-style** donor (same filters as
## `_combatant_from_slot_primary_living`).
## Avoids treating foreign-only occupants (or other skipped slot ids) as "depth" that blocks rank-0 lateral while
## vertical finds nobody.


## True if any rank below `rank_i` has a **vacancy vertical-style** donor (same filters as
## `_combatant_from_slot_primary_living`).
## Avoids treating foreign-only occupants (or other skipped slot ids) as "depth" that blocks rank-0 lateral while
## vertical finds nobody.
static func _has_promotable_deeper_in_file(
    manager: Node,
    slots: Dictionary,
    rank_i: int,
    file: int,
    formation_ranks: int,
    fid: String,
    side_wanted: String,
) -> bool:
    for rr in range(rank_i + 1, formation_ranks):
        if (
            FormationVacancyDonorScoring._combatant_from_slot_primary_living(
                manager, slots, Vector2i(rr, file), fid, side_wanted
            )
            != null
        ):
            return true
    return false


## True when the formation has at least one eligible non-intruded donor in ranks >= 1.
## Used to avoid rank-0 lateral "hole chasing" when the line has no reserves at all.


## True when the formation has at least one eligible non-intruded donor in ranks >= 1.
## Used to avoid rank-0 lateral "hole chasing" when the line has no reserves at all.
static func _formation_has_any_promotable_rear_donor(
    manager: Node,
    slots: Dictionary,
    formation_ranks: int,
    nfiles: int,
    fid: String,
    side_wanted: String,
) -> bool:
    if manager == null or formation_ranks <= 1:
        return false
    for rr in range(1, formation_ranks):
        for ff in range(nfiles):
            if (
                FormationVacancyDonorScoring._combatant_from_slot_primary_living(
                    manager, slots, Vector2i(rr, ff), fid, side_wanted
                )
                != null
            ):
                return true
    return false


## Rank-0 lateral: only when the **hole** column cannot pull a reserve up (no promotable native deeper).
## If this column has anyone who can vertical-plug (possibly after skipping empty ranks), do not slide a
## neighbor's front sideways  -  that read as "shuffling files" instead of filling from behind.
## `donor_file` kept for call-site stability; lateral donor search may use it later.


## Rank-0 lateral: only when the **hole** column cannot pull a reserve up (no promotable native deeper).
## If this column has anyone who can vertical-plug (possibly after skipping empty ranks), do not slide a
## neighbor's front sideways  -  that read as "shuffling files" instead of filling from behind.
## `donor_file` kept for call-site stability; lateral donor search may use it later.
static func _rank0_lateral_slide_allowed(
    manager: Node,
    slots: Dictionary,
    hole_file: int,
    _donor_file: int,
    formation_ranks: int,
    fid: String,
    side_wanted: String,
) -> bool:
    if manager == null or formation_ranks <= 1:
        return false
    var nfiles: int = 0
    for k in slots.keys():
        if k is Vector2i:
            nfiles = maxi(nfiles, int((k as Vector2i).y) + 1)
    if nfiles <= 0:
        nfiles = 1
    if not FormationVacancyPlugMoves._formation_has_any_promotable_rear_donor(
        manager, slots, formation_ranks, nfiles, fid, side_wanted
    ):
        return false
    if FormationVacancyPlugMoves._has_promotable_deeper_in_file(
        manager, slots, 0, hole_file, formation_ranks, fid, side_wanted
    ):
        return false
    return true


## Promote / slide into empty cells (no death, no slot_obstacles). Caller runs ZoC/distance if needed.
## Priority = `pow(effectiveness01, EXP) / (1 + W*proximity_steps)` so heavy injury nonlinearly defers plugging when
## fitter allies exist in other ranks or files.
## Returns true if any combatant moved.


## Skirmish outnumber (III-4 **2b**): wider side keeps intentional file span  -  do not pack to `0..n-1`.
static func _skirmish_wide_line_skip_compact(manager: Node, fid: String) -> bool:
    if manager == null:
        return false
    if str(CombatEngagementMode.engagement_mode(manager)) != str(CombatConstants.ENGAGEMENT_MODE_SKIRMISH):
        return false
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var opp_fid: String = (
        CombatConstants.SIDE_ENEMY if fid == CombatConstants.SIDE_PLAYER else CombatConstants.SIDE_PLAYER
    )
    var forms: Variant = manager.get("formations")
    if forms == null or not forms is Dictionary or not (forms as Dictionary).has(opp_fid):
        return false
    var our_files: int = maxi(1, int(formation.get("files", 1)))
    var opp_files: int = maxi(1, int((forms as Dictionary)[opp_fid].get("files", 1)))
    return our_files > opp_files


## Skirmish: pack natives to contiguous files so stragglers are addressable.
## Formation mode: usually avoid compaction (vacancy plugs handle true holes), but when there are **no rear
## donors anywhere** and rank-0 has gaps, run deterministic compaction so the line closes once and holds
## (prevents lateral hole chasing A<->B while still keeping frontage contiguous).


## Skirmish: pack natives to contiguous files so stragglers are addressable.
## Formation mode: usually avoid compaction (vacancy plugs handle true holes), but when there are **no rear
## donors anywhere** and rank-0 has gaps, run deterministic compaction so the line closes once and holds
## (prevents lateral hole chasing A<->B while still keeping frontage contiguous).
static func _should_compact_native_line_files(manager: Node, fid: String) -> bool:
    if manager == null:
        return false
    if CombatConstants.is_feature_gap_column_topology_enabled():
        return false
    if FormationVacancyPlugMoves._skirmish_wide_line_skip_compact(manager, fid):
        return false
    if str(CombatEngagementMode.engagement_mode(manager)) == str(CombatConstants.ENGAGEMENT_MODE_FORMATION):
        var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
        if formation.is_empty():
            return false
        if not formation_has_rank0_hole(manager, fid):
            return false
        var formation_ranks: int = maxi(1, int(formation.get("ranks", 1)))
        if formation_ranks <= 1:
            return true
        var nfiles: int = maxi(1, int(formation.get("files", 1)))
        var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
        var side_wanted: String = FormationSlots.formation_side_str(formation)
        return not FormationVacancyPlugMoves._formation_has_any_promotable_rear_donor(
            manager, slots, formation_ranks, nfiles, fid, side_wanted
        )
    return true


static func _formation_has_blocking_formation_motion_for_compact(manager: Node, fid: String) -> bool:
    for c in manager.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, fid):
            continue
        var st: String = CombatantEntityAccess.state_str(c)
        if (
            st == CombatConstants.STATE_SWAP_RANK
            or st == CombatConstants.STATE_FALLING_BACK
            or st == CombatConstants.STATE_PLUG_FORWARD
        ):
            return true
    return false


## After removing `native_id` from all cells, write it at `key` while preserving other formation ids already in that
## cell.


## After removing `native_id` from all cells, write it at `key` while preserving other formation ids already in that
## cell.
static func _slot_place_native_preserving_other_occupants(
    manager: Node, slots: Dictionary, fid: String, rank: int, file_col: int, native_id: int
) -> void:
    var nat: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, native_id)
    if nat.is_empty() or not CombatantEntityAccess.alive_bool(nat):
        return
    var key := Vector2i(rank, file_col)
    FormationSlots.remove_combatant_from_slots(slots, native_id)
    var merged: Array = []
    var cur: Array = FormationSlots.normalize_cell(slots.get(key, []))
    for cid in cur:
        var oc: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, int(cid))
        if oc.is_empty() or not CombatantEntityAccess.alive_bool(oc):
            continue
        if CombatantEntityAccess.formation_id_str(oc) != fid:
            merged.append(int(cid))
    if not merged.has(native_id):
        merged.append(native_id)
    slots[key] = merged
    nat["rank"] = rank
    nat["file"] = file_col
    FormationVacancyDonorScoring._repack_lane_offset_after_rank_file_change(nat)
    nat["formation_autofill_cooldown_until"] = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S
    )
    nat["formation_autofill_last_move_clock"] = CombatantEntityAccess.combat_clock_float(manager)
    nat.erase("formation_vacancy_lateral_last_from_file")
    nat.erase("formation_vacancy_lateral_last_to_file")
    nat.erase("formation_vacancy_lateral_reverse_lock_until")
    CombatEventScheduler.schedule_action_ready(manager, native_id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


## Pack home-line `formation_id` natives to files `0..n-1` per rank (stable sort by current file, then id).
## Returns true if any combatant moved or slots were repaired.


## When `COMBAT_FORMATION_VACANCY_DEBUG`, log rank-0 holes that still have no living slot occupant while an eligible
## deeper ally exists.
static func _log_rank0_vacancy_gaps_if_debug(manager: Node, fid: String) -> void:
    if not CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG:
        return
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return
    var formation_ranks: int = int(formation.get("ranks", 1))
    if formation_ranks <= 1:
        return
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var nfiles: int = int(formation.get("files", 1))
    var side_wanted: String = FormationSlots.formation_side_str(formation)
    for file in range(nfiles):
        if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
            continue
        for ally in manager.combatants:
            if not CombatantEntityAccess.is_alive_on_side(ally, side_wanted):
                continue
            if CombatantEntityAccess.formation_id_str(ally) != fid:
                continue
            if CombatantEntityAccess.file_int(ally) != file or CombatantEntityAccess.rank_int(ally) < 1:
                continue
            if FormationVacancyDonorScoring._is_ineligible_vacancy_donor(manager, ally):
                continue
            CombatDebug.formation_vacancy_log(
                (
                    "rank0 gap fid=%s file=%d donor id=%d state=%s rank=%d (slots out of sync or plug blocked)"
                    % [
                        fid,
                        file,
                        CombatantEntityAccess.id_int(ally),
                        CombatantEntityAccess.state_str(ally),
                        CombatantEntityAccess.rank_int(ally)
                    ]
                )
            )
            break

## Run vacancy plug on every file column so empty front cells do not persist while deeper ranks are alive (avoids soft
## deadlock: no enemy rank 0 while enemies remain).
## Repeats rounds so lateral slides that open a gap in a neighbor file get a chance to fill.
## Each round processes **files with an empty rank 0 first** (then the rest) so an edge column does not pull a
## neighbor's front fighter into a shallow hole before that neighbor's own rank-0 gap is closed  -  that pattern
## read as the line scooting over and then back when the center finally pulls a reserve.
