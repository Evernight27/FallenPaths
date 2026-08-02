class_name CombatFormationVacancyPlugs
extends RefCounted

## Vacancy plug reconcile, rank-0 fill policy, native line compaction. See **CombatFormationFlow** header for plug
## order.

const VACANCY_LATERAL_EDGE_META := "_vacancy_lateral_edges"
const VACANCY_PLUG_RESERVED_DONORS_META := "_vacancy_plug_reserved_donors"


static func formation_has_rank0_hole(manager: Node, fid: String) -> bool:
    if manager == null:
        return false
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var nfiles: int = maxi(1, int(formation.get(DataKeys.FORMATION_FILES, 1)))
    for file in range(nfiles):
        if not FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
            return true
    return false


## True when this formation currently has at least one legal plug move into rank 0.
## Frontline-first policy: if true, keep line closure ahead of non-essential movement choices.
## MS-L5: fight-finish / sparse-finish / mop-up offense defer plug to L4b or salience utility pick.
static func formation_plug_layer_blocked(manager: Node, c: Dictionary, actions: Array, combatant_id: int) -> bool:
    if manager == null or c.is_empty():
        return true
    if CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
        return true
    if (
        not actions.is_empty()
        and CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, actions, combatant_id)
    ):
        return true
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if (
        not actions.is_empty()
        and not fid.is_empty()
        and CombatDoctrine.envelop_mop_up_active(manager, fid)
        and CombatListedActions.action_list_has_hostile_strike(actions, combatant_id)
    ):
        return true
    return false

## MS-L5: true when plug cognition should run (not blocked and at least one listed plug move).
static func formation_plug_layer_eligible(manager: Node, c: Dictionary, combatant_id: int, actions: Array) -> bool:
    if formation_plug_layer_blocked(manager, c, actions, combatant_id):
        return false
    return not filter_formation_plug_actions(manager, c, combatant_id, actions).is_empty()


## MS-L5: listed vacancy / plug-forward actions for **`MentalStackDecider`** (swap_rank relief, incap plug, Skirmish
## rotate).
static func filter_formation_plug_actions(manager: Node, c: Dictionary, combatant_id: int, actions: Array) -> Array:
    var out: Array = []
    if manager == null or c.is_empty() or actions.is_empty():
        return out
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if CombatFormationMoveListing.listed_action_is_formation_plug_pick(manager, c, a, actions, combatant_id):
            out.append(a)
    return out


static func formation_has_frontline_fill_opportunity(manager: Node, fid: String) -> bool:
    if manager == null:
        return false
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var formation_ranks: int = int(formation.get(DataKeys.FORMATION_RANKS, 1))
    if formation_ranks <= 1:
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var nfiles: int = maxi(1, int(formation.get(DataKeys.FORMATION_FILES, 1)))
    var side_wanted: String = FormationSlots.formation_side_str(formation)
    for file in range(nfiles):
        if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
            continue
        var reserved: Dictionary = {}
        var move: Dictionary = FormationVacancyPlugMoves._select_best_plug_move_for_empty_cell(
            manager, fid, slots, 0, file, formation_ranks, nfiles, side_wanted, reserved, true, true
        )
        if not move.is_empty():
            return true
    return false


## Same as **`formation_has_frontline_fill_opportunity`**, but only for one **file** column (solo **`fall_back`** uses
## this so an empty front cell in another lane does not block retreat).
static func formation_has_frontline_fill_opportunity_at_file(manager: Node, fid: String, file: int) -> bool:
    if manager == null or file < 0:
        return false
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var formation_ranks: int = int(formation.get(DataKeys.FORMATION_RANKS, 1))
    if formation_ranks <= 1:
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var nfiles: int = maxi(1, int(formation.get(DataKeys.FORMATION_FILES, 1)))
    if file >= nfiles:
        return false
    if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
        return false
    var side_wanted: String = FormationSlots.formation_side_str(formation)
    var reserved: Dictionary = {}
    var move: Dictionary = FormationVacancyPlugMoves._select_best_plug_move_for_empty_cell(
        manager, fid, slots, 0, file, formation_ranks, nfiles, side_wanted, reserved, true, true
    )
    return not move.is_empty()


## Busy combatants must not be picked as vacancy donors (would fight slot state during swaps / wind-up).
## Units just moved by automatic plug also sit out briefly so reconcile ticks cannot ping-pong them as donors.


## Promote / slide into empty cells (no death, no slot_obstacles). Caller runs ZoC/distance if needed.
## Priority = `pow(effectiveness01, EXP) / (1 + W*proximity_steps)` so heavy injury nonlinearly defers plugging when
## fitter allies exist in other ranks or files.
## Returns true if any combatant moved.
static func apply_vacancy_plug_same_file(manager: Node, fid: String, file: int) -> bool:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var formation_ranks: int = formation.get(DataKeys.FORMATION_RANKS, 1)
    if formation_ranks <= 1:
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var side_wanted: String = FormationSlots.formation_side_str(formation)
    var nfiles: int = int(formation.get(DataKeys.FORMATION_FILES, 1))
    var any_promoted: bool = false
    var micro_max: int = CombatConstants.FORMATION_VACANCY_MICRO_STEPS_MAX
    for _micro in range(micro_max):
        var moved_step: bool = false
        # Deepest empty rank first so rank-1.. gaps are closed from the rear before rank-0 (avoids lateral into the
        # front while the same file still has depth below).
        for fill_rank in range(formation_ranks - 1, -1, -1):
            if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(fill_rank, file)):
                continue
            # Rank 0 is always meaningful (front line). Deeper ranks are only meaningful when
            # someone exists behind them in the same file; otherwise the empty cell is valid reserve space.
            if (
                fill_rank > 0
                and not FormationVacancyPlugMoves._has_living_deeper_in_file(
                    manager, slots, fill_rank, file, formation_ranks
                )
            ):
                continue
            var reserved: Dictionary = FormationVacancyDonorScoring._vacancy_plug_reserved_donors(manager)
            var allow_lateral: bool = true
            var move: Dictionary = FormationVacancyPlugMoves._select_best_plug_move_for_empty_cell(
                manager,
                fid,
                slots,
                fill_rank,
                file,
                formation_ranks,
                nfiles,
                side_wanted,
                reserved,
                true,
                allow_lateral
            )
            if move.is_empty():
                continue
            FormationVacancyPlugMoves._apply_plug_move(manager, slots, move, fill_rank, file, "Vacancy plug")
            any_promoted = true
            moved_step = true
            break
        if not moved_step:
            break
    return any_promoted


## Skirmish outnumber (III-4 **2b**): wider side keeps intentional file span  -  do not pack to `0..n-1`.


## Pack home-line `formation_id` natives to files `0..n-1` per rank (stable sort by current file, then id).
## Returns true if any combatant moved or slots were repaired.
static func compact_native_line_files_if_thinned(manager: Node, fid: String) -> bool:
    if manager == null or not FormationVacancyPlugMoves._should_compact_native_line_files(manager, fid):
        return false
    if FormationVacancyPlugMoves._formation_has_blocking_formation_motion_for_compact(manager, fid):
        return false
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var side_wanted: String = FormationSlots.formation_side_str(formation)
    var formation_ranks: int = maxi(1, int(formation.get(DataKeys.FORMATION_RANKS, 1)))
    var any: bool = false
    for rank in range(formation_ranks):
        var natives: Array = []
        for c in manager.combatants:
            if not CombatantEntityAccess.is_alive_on_side(c, side_wanted):
                continue
            if CombatantEntityAccess.formation_id_str(c) != fid:
                continue
            if CombatantEntityAccess.rank_int(c) != rank:
                continue
            natives.append(c)
        if natives.is_empty():
            continue
        natives.sort_custom(
            func(a: Dictionary, b: Dictionary) -> bool:
                var af: int = CombatantEntityAccess.file_int(a)
                var bf: int = CombatantEntityAccess.file_int(b)
                if af != bf:
                    return af < bf
                return CombatantEntityAccess.id_int(a, 0) < CombatantEntityAccess.id_int(b, 0)
        )
        var i: int = 0
        for nat in natives:
            var nid: int = CombatantEntityAccess.id_int(nat)
            var new_f: int = i
            i += 1
            var key := Vector2i(rank, new_f)
            var need: bool = CombatantEntityAccess.file_int(nat) != new_f
            if not need:
                var occ: Array = FormationSlots.normalize_cell(slots.get(key, []))
                need = not occ.has(nid)
            if not need:
                continue
            FormationVacancyPlugMoves._slot_place_native_preserving_other_occupants(
                manager, slots, fid, rank, new_f, nid
            )
            any = true
    if any:
        FormationSlots.refresh_gap_column_topology(formation)
    return any


## When `COMBAT_FORMATION_VACANCY_DEBUG`, log rank-0 holes that still have no living slot occupant while an eligible
## deeper ally exists.


## Run vacancy plug on every file column so empty front cells do not persist while deeper ranks are alive (avoids soft
## deadlock: no enemy rank 0 while enemies remain).
## Repeats rounds so lateral slides that open a gap in a neighbor file get a chance to fill.
## Each round processes **files with an empty rank 0 first** (then the rest) so an edge column does not pull a
## neighbor's front fighter into a shallow hole before that neighbor's own rank-0 gap is closed  -  that pattern
## read as the line scooting over and then back when the center finally pulls a reserve.
static func reconcile_vacancy_plugs_formation(manager: Node, fid: String) -> bool:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var slots_prune: Dictionary = FormationSlots.formation_slots_dict(formation)
    if FormationSlots.prune_dead_ids_from_formation_slots(manager, slots_prune):
        CombatDebug.formation_vacancy_log("pruned dead occupant ids from slots fid=%s" % fid)
    FormationVacancyDonorScoring._vacancy_lateral_begin_tracking(manager)
    var nfiles: int = int(formation.get(DataKeys.FORMATION_FILES, 1))
    var any: bool = false
    var max_rounds: int = CombatConstants.FORMATION_VACANCY_RECONCILE_MAX_ROUNDS
    var exhausted_unstable: bool = false
    for ri in range(max_rounds):
        var round_changed: bool = false
        var files_rank0_hole_first: Array[int] = []
        var files_rest: Array[int] = []
        for file in range(nfiles):
            if not FormationSlots.slot_has_any_living_occupant(manager, slots_prune, Vector2i(0, file)):
                files_rank0_hole_first.append(file)
            else:
                files_rest.append(file)
        var file_order: Array[int] = files_rank0_hole_first + files_rest
        for file in file_order:
            if apply_vacancy_plug_same_file(manager, fid, file):
                round_changed = true
                any = true
        if not round_changed:
            break
        if ri == max_rounds - 1:
            exhausted_unstable = true
    FormationVacancyDonorScoring._vacancy_lateral_end_tracking(manager)
    if compact_native_line_files_if_thinned(manager, fid):
        any = true
    if exhausted_unstable and OS.is_debug_build():
        push_warning(
            (
                (
                    "CombatFormationFlow: vacancy reconcile used all %d rounds with a change on the last round "
                    + "(fid=%s). Slots may still have holes; check plug rules or raise "
                    + "FORMATION_VACANCY_RECONCILE_MAX_ROUNDS."
                )
                % [max_rounds, fid]
            )
        )
    FormationVacancyPlugMoves._log_rank0_vacancy_gaps_if_debug(manager, fid)
    if any:
        FormationSlots.refresh_gap_column_topology(formation)
    return any

## Returns `formation_id` strings whose `reconcile_vacancy_plugs_formation` made a change this pass.
static func reconcile_vacancy_plugs_track_changed_fids(manager: Node) -> Array:
    var changed_fids: Array = []
    if manager == null or not manager.formations is Dictionary:
        return changed_fids
    for fk in manager.formations.keys():
        if reconcile_vacancy_plugs_formation(manager, str(fk)):
            changed_fids.append(str(fk))
    debug_verify_vacancy_invariants_after_reconcile(manager)
    return changed_fids

## Entry point: full pass when `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY` is false; otherwise only
## `Combatmanager._get_vacancy_dirty_fids()` (cleared as processed).
static func reconcile_vacancy_plugs(manager: Node) -> Array:
    if manager == null or not manager.formations is Dictionary:
        return []
    if not CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
        manager._clear_vacancy_dirty_fids()
        return reconcile_vacancy_plugs_track_changed_fids(manager)
    return reconcile_vacancy_plugs_dirty_fids(manager)


static func reconcile_vacancy_plugs_dirty_fids(manager: Node) -> Array:
    var changed_fids: Array = []
    if manager == null or not manager.formations is Dictionary:
        return changed_fids
    var dirty_dict: Dictionary = manager._get_vacancy_dirty_fids()
    if dirty_dict.is_empty():
        debug_verify_vacancy_invariants_after_reconcile(manager)
        return changed_fids
    var to_proc: Array = dirty_dict.keys()
    dirty_dict.clear()
    to_proc.sort_custom(func(a, b): return str(a) < str(b))
    for fk_any in to_proc:
        var fk: String = str(fk_any)
        if FormationSlots.formation_record_for_manager(manager, fk).is_empty():
            continue
        if reconcile_vacancy_plugs_formation(manager, fk):
            changed_fids.append(fk)
    debug_verify_vacancy_invariants_after_reconcile(manager)
    return changed_fids


static func reconcile_vacancy_plugs_all_formations(manager: Node) -> bool:
    if manager == null or not manager.formations is Dictionary:
        return false
    if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY and manager.has_method("mark_all_formations_vacancy_dirty"):
        manager.mark_all_formations_vacancy_dirty()
    return not reconcile_vacancy_plugs(manager).is_empty()

## Shared tail for vacancy reconcile: ZoC/distance, surgical back-rank `action_ready` bump, optional
## `formation_changed`.
## Call with `emit_formation_changed_signals=false` when the caller emits those signals separately (e.g.
## `notify_formation_changed`).
static func finish_vacancy_reconcile_follow_up(
    manager: Node, changed_fids: Array, placement_snap_before: Dictionary, emit_formation_changed_signals: bool
) -> void:
    if manager == null or changed_fids.is_empty():
        return
    manager.recompute_zoc_and_distance()
    var moved: Array = CombatEventScheduler.ids_with_changed_rank_file_since_snapshot(manager, placement_snap_before)
    CombatEventScheduler.reschedule_formation_recheck_for_moved_back_ranks(manager, moved)
    if not emit_formation_changed_signals:
        return
    for fv in changed_fids:
        var fk: String = str(fv)
        if manager.formations is Dictionary and (manager.formations as Dictionary).has(fk):
            manager.formation_changed.emit(fk)

## Debug-only: after a full reconcile pass, rank 0 in a column should not stay empty if a non-intruded ally
## could step up (same rules as `apply_vacancy_plug_same_file`). Intruder-only deeper ranks are allowed.
static func debug_verify_vacancy_invariants_after_reconcile(manager: Node) -> void:
    if not CombatConstants.COMBAT_FORMATION_INVARIANT_DEBUG:
        return
    if not OS.is_debug_build():
        return
    for fid_key in manager.formations.keys():
        var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, str(fid_key))
        if formation.is_empty():
            continue
        var fid_str: String = str(fid_key)
        var formation_ranks: int = int(formation.get(DataKeys.FORMATION_RANKS, 1))
        if formation_ranks <= 1:
            continue
        var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
        var nfiles: int = int(formation.get(DataKeys.FORMATION_FILES, 1))
        var side_wanted: String = FormationSlots.formation_side_str(formation)
        for file in range(nfiles):
            if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
                continue
            var has_promotable_deeper: bool = false
            for ally in manager.combatants:
                if not CombatantEntityAccess.is_alive_on_side(ally, side_wanted):
                    continue
                if CombatantEntityAccess.formation_id_str(ally) != fid_str:
                    continue
                if FormationVacancyDonorScoring._is_ineligible_vacancy_donor(manager, ally):
                    continue
                if CombatantEntityAccess.file_int(ally) == file and CombatantEntityAccess.rank_int(ally) >= 1:
                    has_promotable_deeper = true
                    break
            if has_promotable_deeper:
                push_error("CombatFormationFlow: vacancy invariant failed after reconcile (rank 0 empty, deeper ally available) fid=%s file=%d" % [fid_str, file])

## Death-triggered same-file micro-plug (bounded steps) after corpse is written to **`slot_obstacles`**.
static func run_death_column_micro_plug(
    manager: Node, formation: Dictionary, fid_geom: String, slots: Dictionary, death_file: int
) -> void:
    if formation.get(DataKeys.FORMATION_RANKS, 1) <= 1:
        return
    var formation_ranks: int = int(formation.get(DataKeys.FORMATION_RANKS, 1))
    var nfiles_death: int = int(formation.get(DataKeys.FORMATION_FILES, 1))
    FormationVacancyDonorScoring._vacancy_lateral_begin_tracking(manager)
    var micro_max_d: int = CombatConstants.FORMATION_VACANCY_MICRO_STEPS_MAX
    for _micro_d in range(micro_max_d):
        var moved_step_d: bool = false
        for fill_rank in range(formation_ranks - 1, -1, -1):
            if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(fill_rank, death_file)):
                continue
            if (
                fill_rank > 0
                and not FormationVacancyPlugMoves._has_living_deeper_in_file(
                    manager, slots, fill_rank, death_file, formation_ranks
                )
            ):
                continue
            var reserved_d: Dictionary = FormationVacancyDonorScoring._vacancy_plug_reserved_donors(manager)
            var side_death: String = FormationSlots.formation_side_str(formation)
            var move_d: Dictionary = FormationVacancyPlugMoves._select_best_plug_move_for_empty_cell(
                manager,
                fid_geom,
                slots,
                fill_rank,
                death_file,
                formation_ranks,
                nfiles_death,
                side_death,
                reserved_d,
                true,
                true
            )
            if move_d.is_empty():
                continue
            FormationVacancyPlugMoves._apply_plug_move(manager, slots, move_d, fill_rank, death_file, "Plug")
            moved_step_d = true
            break
        if not moved_step_d:
            break
    FormationVacancyDonorScoring._vacancy_lateral_end_tracking(manager)






