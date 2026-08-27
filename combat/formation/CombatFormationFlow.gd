class_name CombatFormationFlow
extends RefCounted

## Formation moves, resolve events, slot plug on death, hit reaction delays on pending formation events.
## Footing: rank/file shuffle only  -  does **not** write **`guard_line`**, **`weapon_form`**, or
## **`position_angle_offset_deg`**. Lane duration mult: **`ZoneOfControl.get_footing_duration_multiplier`**. LIVE_PATHS
## **`#wf-footing-terminology`** . **`#wf-pick-vs-strike`**.
##
## **Vacancy plug** on the home formation (empty rank-0 without death). **Death plug** stays in
## `on_combatant_died` only; same-tick ordering avoids mixing vacancy with death removal.
##
## **Fill vs posture:** vacancy/death/pair moves are orthogonal to engagement posture;
## `lane_offset` repacks to column center when rank/file changes.
##
## **Vacancy reconcile:** `reconcile_vacancy_plugs` (dirty-only when `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY`) or full
## `reconcile_vacancy_plugs_track_changed_fids`; per-file work in `reconcile_vacancy_plugs_formation`.
## **`finish_vacancy_reconcile_follow_up`**
## applies ZoC, moved-only back-rank `action_ready`, and optional `formation_changed`. `notify_formation_changed` marks
## dirty then reconciles;
## `get_available_actions` marks all lines then reconciles (full pass); `CombatProcessTick` reconciles dirty formations
## only.
## **Plug priority (rank-0 hole, after same-column vertical):** **rear infill** from **any** other file (`rear_infill`:
## rank --''deg'' 1 steps into the empty front slot when the hole column is passable) before **front-rank lateral**
## (same-rank neighbor slide). Cross-file rear uses `prox` = rank depth + |f"file| so closer reserves win; lateral is
## last resort.
## Front lateral at rank 0 only when `_rank0_lateral_slide_allowed` (hole column has no promotable native deeper).
## Deeper empty ranks: same-rank lateral from neighbors is allowed so the rear echelon can close gaps without rank-0
## shuffling.
## `apply_vacancy_plug_same_file` scans **deepest empty rank first** so a gap under the front is closed from the rear
## before rank-0 considers lateral.
## Donors are **reserved** for the reconcile pass so the same unit is not assigned to two holes.
## Rank/file shuffle resolve + vacancy plug call **`CombatDoctrine.clear_combatant_doctrine_commitment`** (stale target
## lock).
## Footing: return-to-waiting via **`_set_combatant_waiting`** . shuffle start via
## **`_scrub_idle_footwork_for_formation_move`**  -  LIVE_PATHS **`#wf-tier-44-pa`**.


static func _set_combatant_waiting(c: Dictionary) -> void:
    CombatFootwork.return_to_waiting(c)


static func _scrub_idle_footwork_for_formation_move(c: Dictionary) -> void:
    CombatFootwork.reconcile_idle_offset(c)


static func _clear_shuffle_doctrine_commitments(combatants: Array) -> void:
    for c in combatants:
        if c is Dictionary and not (c as Dictionary).is_empty():
            CombatDoctrine.clear_combatant_doctrine_commitment(c as Dictionary)


static func _stamp_rotate_file_cooldown(manager: Node, c0: Dictionary, c1: Dictionary) -> void:
    if manager == null or c0.is_empty() or c1.is_empty():
        return
    var until: float = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S
    )
    c0[DataKeys.FM_ROTATE_FILE_COOLDOWN_UNTIL] = until
    c1[DataKeys.FM_ROTATE_FILE_COOLDOWN_UNTIL] = until


static func _stamp_rotate_file_reverse_pair_lock(manager: Node, c0: Dictionary, c1: Dictionary) -> void:
    if manager == null or c0.is_empty() or c1.is_empty():
        return
    var until: float = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_ROTATE_FILE_REVERSE_PAIR_LOCK_S
    )
    var id0: int = CombatantEntityAccess.id_int(c0)
    var id1: int = CombatantEntityAccess.id_int(c1)
    c0[DataKeys.FM_ROTATE_FILE_REVERSE_LOCK_UNTIL] = until
    c0[DataKeys.FM_ROTATE_FILE_REVERSE_PARTNER_ID] = id1
    c1[DataKeys.FM_ROTATE_FILE_REVERSE_LOCK_UNTIL] = until
    c1[DataKeys.FM_ROTATE_FILE_REVERSE_PARTNER_ID] = id0


## True when this unit just rotated with `partner_id` and must not immediately swap back.
static func rotate_file_reverse_pair_blocked(manager: Node, c: Dictionary, partner_id: int) -> bool:
    if manager == null or c.is_empty() or partner_id < 0:
        return false
    if not c.has(DataKeys.FM_ROTATE_FILE_REVERSE_PARTNER_ID):
        return false
    var until: float = c.get(DataKeys.FM_ROTATE_FILE_REVERSE_LOCK_UNTIL, -1.0)
    if CombatantEntityAccess.combat_clock_float(manager) >= until:
        return false
    return c.get(DataKeys.FM_ROTATE_FILE_REVERSE_PARTNER_ID, -1) == partner_id


static func _pair_abort_cooldown_active(manager: Node, c: Dictionary) -> bool:
    return CombatantEntityAccess.combatant_cooldown_active(manager, c, "formation_pair_abort_cooldown_until", -1.0)


static func _rotate_file_cooldown_active(manager: Node, c: Dictionary) -> bool:
    return CombatantEntityAccess.combatant_cooldown_active(manager, c, "formation_rotate_file_cooldown_until", -1.0)


## Tier 1.3 P4: after rank/file changes from plugs or formation moves, keep `lane_offset` bounded (f''Sec4.2 repack).
## Intruders keep seam bias; line fighters reset to column center.
static func repack_lane_offset_after_rank_file_change(c: Dictionary) -> void:
    if c.is_empty():
        return
    c[DataKeys.BIND_LANE_OFFSET] = CombatConstants.LANE_OFFSET_DEFAULT


static func formation_has_frontline_fill_opportunity(manager: Node, fid: String) -> bool:
    return CombatFormationVacancyPlugs.formation_has_frontline_fill_opportunity(manager, fid)


static func formation_has_rank0_hole(manager: Node, fid: String) -> bool:
    return CombatFormationVacancyPlugs.formation_has_rank0_hole(manager, fid)


## Rank-0 hole on the line **or** a legal depth plug into rank 0 (Skirmish gaps + Formation relief).
static func formation_line_has_rank0_gap(manager: Node, fid: String) -> bool:
    if formation_has_rank0_hole(manager, fid):
        return true
    return formation_has_frontline_fill_opportunity(manager, fid)


## Post-flee / casualty sparse front: at most half of file slots hold a living rank-0 fighter while holes remain.
## Adjacent **`rotate_file`** cannot close distant gaps  -  prefer strikes/close when engagement is listed.
static func skirmish_line_sparse_after_casualties(manager: Node, fid: String) -> bool:
    if manager == null or not formation_has_rank0_hole(manager, fid):
        return false
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var nfiles: int = maxi(1, int(formation.get(DataKeys.FORMATION_FILES, 1)))
    var occupied: int = 0
    for file in range(nfiles):
        if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
            occupied += 1
    return occupied * 2 <= nfiles


static func formation_has_frontline_fill_opportunity_at_file(manager: Node, fid: String, file: int) -> bool:
    return CombatFormationVacancyPlugs.formation_has_frontline_fill_opportunity_at_file(manager, fid, file)


static func apply_vacancy_plug_same_file(manager: Node, fid: String, file: int) -> bool:
    return CombatFormationVacancyPlugs.apply_vacancy_plug_same_file(manager, fid, file)


static func reconcile_vacancy_plugs_formation(manager: Node, fid: String) -> bool:
    return CombatFormationVacancyPlugs.reconcile_vacancy_plugs_formation(manager, fid)


static func reconcile_vacancy_plugs_track_changed_fids(manager: Node) -> Array:
    return CombatFormationVacancyPlugs.reconcile_vacancy_plugs_track_changed_fids(manager)


static func reconcile_vacancy_plugs(manager: Node) -> Array:
    return CombatFormationVacancyPlugs.reconcile_vacancy_plugs(manager)


static func reconcile_vacancy_plugs_dirty_fids(manager: Node) -> Array:
    return CombatFormationVacancyPlugs.reconcile_vacancy_plugs_dirty_fids(manager)


static func reconcile_vacancy_plugs_all_formations(manager: Node) -> bool:
    return CombatFormationVacancyPlugs.reconcile_vacancy_plugs_all_formations(manager)


static func finish_vacancy_reconcile_follow_up(
    manager: Node, changed_fids: Array, placement_snap_before: Dictionary, emit_formation_changed_signals: bool
) -> void:
    CombatFormationVacancyPlugs.finish_vacancy_reconcile_follow_up(
        manager, changed_fids, placement_snap_before, emit_formation_changed_signals
    )


static func debug_verify_vacancy_invariants_after_reconcile(manager: Node) -> void:
    CombatFormationVacancyPlugs.debug_verify_vacancy_invariants_after_reconcile(manager)


static func apply_hit_reaction_if_needed(manager: Node, combatant_id: int, intensity: float = 0.5) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var c = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not CombatantEntityAccess.alive_bool(c):
        return
    var st: String = CombatantEntityAccess.state_str(c)
    if (
        st != CombatConstants.STATE_SWAP_RANK
        and st != CombatConstants.STATE_FALLING_BACK
        and st != CombatConstants.STATE_PLUG_FORWARD
    ):
        return
    if intensity >= CombatConstants.FORMATION_HIT_CANCEL_INTENSITY:
        cancel_formation_move_from_hit(manager, combatant_id, intensity)
        return
    var extra: float = CombatConstants.FORMATION_HIT_REACTION_EXTRA_S * lerpf(0.4, 1.2, clampf(intensity, 0.0, 1.0))
    c.state_duration += extra
    var pid: int = c.get(DataKeys.FM_FORMATION_MOVE_PARTNER_ID, -1)
    if pid >= 0:
        var p = CombatantEntityAccess.manager_get_combatant(manager, pid)
        if not p.is_empty() and CombatantEntityAccess.alive_bool(p):
            var pst: String = CombatantEntityAccess.state_str(p)
            if (
                pst == CombatConstants.STATE_SWAP_RANK
                or pst == CombatConstants.STATE_FALLING_BACK
                or pst == CombatConstants.STATE_PLUG_FORWARD
            ):
                p.state_duration += extra
    bump_resolve_events(manager, combatant_id, extra)


## Hard hit during **`STATE_SWAP_RANK`** / **`STATE_FALLING_BACK`**: abort pair or solo move and drop pending resolves.
static func cancel_formation_move_from_hit(manager: Node, combatant_id: int, intensity: float = 1.0) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var c = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not CombatantEntityAccess.alive_bool(c):
        return
    var st: String = CombatantEntityAccess.state_str(c)
    if (
        st != CombatConstants.STATE_SWAP_RANK
        and st != CombatConstants.STATE_FALLING_BACK
        and st != CombatConstants.STATE_PLUG_FORWARD
    ):
        return
    var pid: int = c.get(DataKeys.FM_FORMATION_MOVE_PARTNER_ID, -1)
    CombatEventScheduler.cancel_pending_formation_events_for_combatant(manager, combatant_id)
    if pid >= 0:
        CombatEventScheduler.cancel_pending_formation_events_for_combatant(manager, pid)
        var partner = CombatantEntityAccess.manager_get_combatant(manager, pid)
        abort_pair(manager, c, partner, "hit_cancel intensity=%.2f" % intensity)
        if CombatantEntityAccess.alive_bool(c):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, c)
        if not partner.is_empty() and CombatantEntityAccess.alive_bool(partner):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, partner)
    else:
        abort_solo_formation_move(manager, c, "hit_cancel intensity=%.2f" % intensity)
        if CombatantEntityAccess.alive_bool(c):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, c)


static func bump_resolve_events(manager: Node, for_combatant_id: int, extra_s: float) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    for ev in manager.event_queue:
        if ev is not Dictionary:
            continue
        var t: String = ev.get(DataKeys.EVENT_TYPE, "")
        var cid: int = ev.get(DataKeys.EVENT_COMBATANT_ID, -1)
        var data_raw: Variant = ev.get(DataKeys.EVENT_DATA, null)
        var data: Dictionary = data_raw if data_raw is Dictionary else {}
        var bump: bool = false
        match t:
            CombatConstants.EVENT_SWAP_RANK_RESOLVE:
                if cid == for_combatant_id or data.get(DataKeys.EVENT_PARTNER_ID, -1) == for_combatant_id:
                    bump = true
            CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE:
                if cid == for_combatant_id:
                    bump = true
            CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
                if cid == for_combatant_id or data.get(DataKeys.EVENT_PARTNER_ID, -1) == for_combatant_id:
                    bump = true
        if bump:
            ev["resolve_at"] = ev.get(DataKeys.EVENT_RESOLVE_AT, 0.0) + extra_s
    CombatEventScheduler.sort_event_queue(manager)


static func start_pair_move(manager: Node, initiator_id: int, partner_id: int, move_kind: String) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
    if init.is_empty() or partner.is_empty() or not CombatantEntityAccess.is_available_formation_partner(init, partner):
        return
    if _pair_abort_cooldown_active(manager, init) or _pair_abort_cooldown_active(manager, partner):
        return
    if CombatantEntityAccess.formation_id_str(init) != CombatantEntityAccess.formation_id_str(partner):
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty() or formation.get(DataKeys.FORMATION_RANKS, 1) <= 1:
        return
    var r0: int = CombatantEntityAccess.rank_int(init)
    var r1: int = CombatantEntityAccess.rank_int(partner)
    var f0: int = CombatantEntityAccess.file_int(init)
    var f1: int = CombatantEntityAccess.file_int(partner)
    if f0 != f1 or abs(r0 - r1) != 1:
        return
    var lane_foot: float = ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
    var pressure_mod: float = ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
    var duration: float = CombatFormationMoveDuration.estimate_adjacent_rank_pair_duration_s(
        manager, init, partner, move_kind
    )
    var use_falling: bool = (
        move_kind == CombatConstants.MOVE_ID_DRAG_BACK
        or move_kind == CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR
    )
    var st: String = CombatConstants.STATE_FALLING_BACK if use_falling else CombatConstants.STATE_SWAP_RANK
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var r_lo: int = mini(r0, r1)
    var r_hi: int = maxi(r0, r1)
    var id_at_lo: int = (
        CombatantEntityAccess.id_int(init)
        if CombatantEntityAccess.rank_int(init) == r_lo
        else CombatantEntityAccess.id_int(partner)
    )
    var id_at_hi: int = (
        CombatantEntityAccess.id_int(init)
        if CombatantEntityAccess.rank_int(init) == r_hi
        else CombatantEntityAccess.id_int(partner)
    )
    FormationSlots.begin_adjacent_rank_pair_move(slots, r_lo, r_hi, f0, id_at_lo, id_at_hi)
    init[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = partner_id
    partner[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = initiator_id
    _scrub_idle_footwork_for_formation_move(init)
    _scrub_idle_footwork_for_formation_move(partner)
    init.state = st
    init.state_timer = 0.0
    init.state_duration = duration
    partner.state = st
    partner.state_timer = 0.0
    partner.state_duration = duration
    # Formation movement is leg exertion: both movers accumulate leg muscle-fatigue (slows subsequent
    # movement via step_speed_mult, degrades dodge/precision). Reuses the production leg-fatigue writer.
    CombatMuscleFatigue.apply_formation_exertion(init, move_kind)
    CombatMuscleFatigue.apply_formation_exertion(partner, move_kind)
    if CombatDebug.flow_verbose_enabled():
        var n0: String = CombatantEntityAccess.get_display_name(init, initiator_id)
        var n1: String = CombatantEntityAccess.get_display_name(partner, partner_id)
        CombatDebug.flow_log(
            (
                "formation_move_start %s (%d) %s with %s (%d) (%.2fs lane- - foot- - %.2f pressure- - %.2f)"
                % [n0, initiator_id, move_kind, n1, partner_id, duration, lane_foot, pressure_mod]
            )
        )
    CombatEventScheduler.cancel_pending_swap_rank_pair_events(manager, initiator_id, partner_id)
    CombatantEntityAccess.manager_schedule_event(
        manager,
        {
            "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
            "combatant_id": initiator_id,
            "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, duration),
            "data": {"partner_id": partner_id, "move_kind": move_kind}
        }
    )


static func start_fall_back_solo(manager: Node, initiator_id: int) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    if init.is_empty() or not CombatantEntityAccess.alive_bool(init):
        return
    if _pair_abort_cooldown_active(manager, init):
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return
    var ranks: int = formation.get(DataKeys.FORMATION_RANKS, 1)
    if ranks <= 1 or CombatantEntityAccess.rank_int(init) != 0:
        return
    var f: int = CombatantEntityAccess.file_int(init)
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
        return
    var duration: float = CombatFormationMoveDuration.estimate_solo_fall_back_duration_s(manager, init)
    init[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = -1
    _scrub_idle_footwork_for_formation_move(init)
    init.state = CombatConstants.STATE_FALLING_BACK
    init.state_timer = 0.0
    init.state_duration = duration
    CombatMuscleFatigue.apply_formation_exertion(init, CombatConstants.MOVE_ID_FALL_BACK)
    if CombatDebug.flow_verbose_enabled():
        var n0: String = CombatantEntityAccess.get_display_name(init, initiator_id)
        CombatDebug.flow_log("fall_back_solo_start %s (%d) (%.2fs)" % [n0, initiator_id, duration])
    CombatantEntityAccess.manager_schedule_event(
        manager,
        {
            "type": CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
            "combatant_id": initiator_id,
            "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, duration),
            "data": {}
        }
    )


static func start_rotate_file(manager: Node, initiator_id: int, partner_id: int) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
    if init.is_empty() or partner.is_empty() or not CombatantEntityAccess.is_available_formation_partner(init, partner):
        return
    if (
        _pair_abort_cooldown_active(manager, init)
        or _pair_abort_cooldown_active(manager, partner)
        or _rotate_file_cooldown_active(manager, init)
        or _rotate_file_cooldown_active(manager, partner)
        or rotate_file_reverse_pair_blocked(manager, init, partner_id)
        or rotate_file_reverse_pair_blocked(manager, partner, initiator_id)
    ):
        return
    if CombatantEntityAccess.formation_id_str(init) != CombatantEntityAccess.formation_id_str(partner):
        return
    var r_init: int = CombatantEntityAccess.rank_int(init)
    var r_partner: int = CombatantEntityAccess.rank_int(partner)
    if r_init != r_partner:
        return
    var f0: int = CombatantEntityAccess.file_int(init)
    var f1: int = CombatantEntityAccess.file_int(partner)
    if abs(f0 - f1) != 1:
        return
    var duration: float = CombatFormationMoveDuration.estimate_rotate_file_duration_s(manager, init, partner)
    init[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = partner_id
    partner[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = initiator_id
    _scrub_idle_footwork_for_formation_move(init)
    _scrub_idle_footwork_for_formation_move(partner)
    init.state = CombatConstants.STATE_SWAP_RANK
    init.state_timer = 0.0
    init.state_duration = duration
    partner.state = CombatConstants.STATE_SWAP_RANK
    partner.state_timer = 0.0
    partner.state_duration = duration
    CombatMuscleFatigue.apply_formation_exertion(init, CombatConstants.MOVE_ID_ROTATE_FILE)
    CombatMuscleFatigue.apply_formation_exertion(partner, CombatConstants.MOVE_ID_ROTATE_FILE)
    if CombatDebug.flow_verbose_enabled():
        var n0: String = CombatantEntityAccess.get_display_name(init, initiator_id)
        var n1: String = CombatantEntityAccess.get_display_name(partner, partner_id)
        CombatDebug.flow_log(
            "rotate_file_start %s (%d) <-> %s (%d) (%.2fs)" % [n0, initiator_id, n1, partner_id, duration]
        )
    CombatantEntityAccess.manager_schedule_event(
        manager,
        {
            "type": CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
            "combatant_id": initiator_id,
            "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, duration),
            "data": {"partner_id": partner_id}
        }
    )


static func pair_state_ok(c) -> bool:
    return (
        not c.is_empty()
        and (
            CombatantEntityAccess.state_str(c)
            in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]
        )
    )


static func abort_pair(manager: Node, init, partner, reason: String = "") -> void:
    var iid: int = CombatantEntityAccess.id_int(init) if not init.is_empty() else -1
    var pid: int = CombatantEntityAccess.id_int(partner) if not partner.is_empty() else -1
    var rs: String = (" reason=%s" % reason) if not reason.is_empty() else ""
    CombatDebug.flow_log("formation_pair abort (reset to waiting) initiator_id=%d partner_id=%d%s" % [iid, pid, rs])
    if not init.is_empty():
        init.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    if not partner.is_empty():
        partner.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    if not init.is_empty() and not partner.is_empty():
        var fid: String = CombatantEntityAccess.formation_id_str(init)
        if (
            not fid.is_empty()
            and CombatantEntityAccess.formation_id_str(init) == CombatantEntityAccess.formation_id_str(partner)
        ):
            var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
            var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
            FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(init))
            FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(partner))
            if CombatantEntityAccess.alive_bool(init):
                FormationSlots.slot_set_single(
                    slots,
                    Vector2i(CombatantEntityAccess.rank_int(init), CombatantEntityAccess.file_int(init)),
                    CombatantEntityAccess.id_int(init)
                )
            if CombatantEntityAccess.alive_bool(partner):
                FormationSlots.slot_set_single(
                    slots,
                    Vector2i(CombatantEntityAccess.rank_int(partner), CombatantEntityAccess.file_int(partner)),
                    CombatantEntityAccess.id_int(partner)
                )
            manager.recompute_zoc_and_distance()
            manager.notify_formation_changed(fid)
            CombatEventScheduler.reschedule_back_rank_turns(manager, fid)
    if not init.is_empty() and CombatantEntityAccess.alive_bool(init) and pair_state_ok(init):
        _set_combatant_waiting(init)
    if not partner.is_empty() and CombatantEntityAccess.alive_bool(partner) and pair_state_ok(partner):
        _set_combatant_waiting(partner)
    # Keep a brief local guard after abort so the same pair does not instantly requeue under churn.
    var until: float = CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_PAIR_ABORT_RETRY_COOLDOWN_S
    if not init.is_empty() and CombatantEntityAccess.alive_bool(init):
        init[DataKeys.FM_PAIR_ABORT_COOLDOWN_UNTIL] = until
    if not partner.is_empty() and CombatantEntityAccess.alive_bool(partner):
        partner[DataKeys.FM_PAIR_ABORT_COOLDOWN_UNTIL] = until


static func abort_solo_formation_move(manager: Node, init, reason: String = "") -> void:
    var iid: int = CombatantEntityAccess.id_int(init) if not init.is_empty() else -1
    var rs: String = (" reason=%s" % reason) if not reason.is_empty() else ""
    CombatDebug.flow_log("formation_solo abort (reset to waiting) id=%d%s" % [iid, rs])
    if init.is_empty():
        return
    init.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    if (
        CombatantEntityAccess.alive_bool(init)
        and CombatantEntityAccess.state_str(init) == CombatConstants.STATE_FALLING_BACK
    ):
        _set_combatant_waiting(init)
    var until: float = CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_PAIR_ABORT_RETRY_COOLDOWN_S
    if CombatantEntityAccess.alive_bool(init):
        init[DataKeys.FM_PAIR_ABORT_COOLDOWN_UNTIL] = until


static func _formation_resolve_medical_phase_skip(manager: Node, initiator_id: int, partner_id: int = -1) -> bool:
    if not MedicalPhaseController.should_skip_formation_resolve(manager, initiator_id, partner_id):
        return false
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, partner_id)
    for c in [init, partner]:
        if c.is_empty() or not CombatantEntityAccess.alive_bool(c):
            continue
        _set_combatant_waiting(c)
        c.state_timer = 0.0
        c.state_duration = 0.0
        c.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    return true


static func handle_swap_rank_resolve(manager: Node, ev: Dictionary) -> void:
    var initiator_id: int = ev.get(DataKeys.EVENT_COMBATANT_ID, -1)
    var data_raw: Variant = ev.get(DataKeys.EVENT_DATA, null)
    var data: Dictionary = data_raw if data_raw is Dictionary else {}
    var partner_id: int = data.get(DataKeys.EVENT_PARTNER_ID, -1)
    var move_kind: String = data.get(DataKeys.EVENT_MOVE_KIND, CombatConstants.MOVE_ID_SWAP_RANK)
    if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
    if init.is_empty():
        if not partner.is_empty() and pair_state_ok(partner):
            _set_combatant_waiting(partner)
        return
    if partner.is_empty():
        if pair_state_ok(init):
            _set_combatant_waiting(init)
        return
    if not CombatantEntityAccess.are_both_alive(init, partner):
        abort_pair(manager, init, partner, "swap_rank_resolve_not_alive")
        if not init.is_empty() and CombatantEntityAccess.alive_bool(init):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
        if not partner.is_empty() and CombatantEntityAccess.alive_bool(partner):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, partner)
        return
    if not pair_state_ok(init) or not pair_state_ok(partner):
        var si: String = CombatantEntityAccess.state_str(init) if not init.is_empty() else "null"
        var sp: String = CombatantEntityAccess.state_str(partner) if not partner.is_empty() else "null"
        abort_pair(manager, init, partner, "swap_rank_resolve_pair_state init=%s partner=%s" % [si, sp])
        if not init.is_empty() and CombatantEntityAccess.alive_bool(init):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
        if not partner.is_empty() and CombatantEntityAccess.alive_bool(partner):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, partner)
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        abort_pair(manager, init, partner, "swap_rank_resolve_formation_empty fid=%s" % fid)
        return
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var r0: int = CombatantEntityAccess.rank_int(init)
    var r1: int = CombatantEntityAccess.rank_int(partner)
    var f0: int = CombatantEntityAccess.file_int(init)
    var f1: int = CombatantEntityAccess.file_int(partner)
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(init))
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(partner))
    init.rank = r1
    init.file = f1
    partner.rank = r0
    partner.file = f0
    repack_lane_offset_after_rank_file_change(init)
    repack_lane_offset_after_rank_file_change(partner)
    FormationSlots.slot_set_single(
        slots,
        Vector2i(CombatantEntityAccess.rank_int(init), CombatantEntityAccess.file_int(init)),
        CombatantEntityAccess.id_int(init)
    )
    FormationSlots.slot_set_single(
        slots,
        Vector2i(CombatantEntityAccess.rank_int(partner), CombatantEntityAccess.file_int(partner)),
        CombatantEntityAccess.id_int(partner)
    )
    FormationSlots.refresh_gap_column_topology(formation)
    init.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    partner.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    _clear_shuffle_doctrine_commitments([init, partner])
    _set_combatant_waiting(init)
    _set_combatant_waiting(partner)
    var outcome: String = "swap_rank_complete"
    match move_kind:
        CombatConstants.MOVE_ID_DRAG_BACK:
            outcome = "drag_back_complete"
        CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR:
            outcome = "fall_back_complete"
        _:
            outcome = "swap_rank_complete"
    manager.emit_signal(
        "action_resolved",
        initiator_id,
        partner_id,
        {"outcome": outcome, "dmg": 0, "died": false, "move_kind": move_kind}
    )
    if CombatDebug.flow_verbose_enabled():
        var n0: String = CombatantEntityAccess.get_display_name(init, initiator_id)
        var n1: String = CombatantEntityAccess.get_display_name(partner, partner_id)
        CombatDebug.flow_log(
            (
                "formation_pair_resolve %s (%d) <-> %s (%d) move_kind=%s outcome=%s"
                % [n0, initiator_id, n1, partner_id, move_kind, outcome]
            )
        )
    manager.recompute_zoc_and_distance()
    manager.notify_formation_changed(fid)
    CombatEventScheduler.reschedule_back_rank_turns(manager, fid)
    CombatEventScheduler.reschedule_same_file_depth_rank2_plus(manager, fid, f0)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
    if not partner.is_empty() and CombatantEntityAccess.is_standing_combatant(partner):
        CombatEventScheduler.schedule_action_ready(manager, partner_id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


static func handle_fall_back_solo_resolve(manager: Node, ev: Dictionary) -> void:
    var initiator_id: int = ev.get(DataKeys.EVENT_COMBATANT_ID, -1)
    if _formation_resolve_medical_phase_skip(manager, initiator_id):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    if init.is_empty() or not CombatantEntityAccess.alive_bool(init):
        return
    if CombatantEntityAccess.state_str(init) != CombatConstants.STATE_FALLING_BACK:
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        _set_combatant_waiting(init)
        return
    var f: int = CombatantEntityAccess.file_int(init)
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    if FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
        CombatDebug.flow_log("fall_back_solo_resolve id=%d aborted: rear slot (1,%d) occupied" % [initiator_id, f])
        _set_combatant_waiting(init)
        CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
        return
    FormationSlots.remove_combatant_from_slots(slots, initiator_id)
    init.rank = 1
    repack_lane_offset_after_rank_file_change(init)
    FormationSlots.slot_set_single(slots, Vector2i(1, f), initiator_id)
    FormationSlots.refresh_gap_column_topology(formation)
    init.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    _clear_shuffle_doctrine_commitments([init])
    _set_combatant_waiting(init)
    CombatDebug.flow_log("fall_back_solo_resolve id=%d complete rank 0->1 file %d" % [initiator_id, f])
    if CombatantEntityAccess.get_attacking_arm(init).is_empty():
        CombatF5SoakTrace.note_cowering_fall_back_executed(
            CombatantEntityAccess.get_display_name(init, initiator_id), f
        )
    manager.emit_signal(
        "action_resolved", initiator_id, initiator_id, {"outcome": "fall_back_solo_complete", "dmg": 0, "died": false}
    )
    manager.recompute_zoc_and_distance()
    # Manual rank/file write above  -  skip vacancy reconcile (would plug rank-2 into rank-1 and undo retreat).
    manager.emit_signal("formation_changed", fid)
    CombatEventScheduler.reschedule_back_rank_turns(manager, fid)
    CombatEventScheduler.reschedule_same_file_depth_rank2_plus(manager, fid, f)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)


static func handle_rotate_file_resolve(manager: Node, ev: Dictionary) -> void:
    var initiator_id: int = ev.get(DataKeys.EVENT_COMBATANT_ID, -1)
    var partner_id: int = -1
    var ev_data: Variant = ev.get(DataKeys.EVENT_DATA, null)
    if ev_data is Dictionary:
        partner_id = int((ev_data as Dictionary).get(DataKeys.EVENT_PARTNER_ID, -1))
    if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
    if init.is_empty() or partner.is_empty() or not CombatantEntityAccess.are_both_alive(init, partner):
        abort_pair(manager, init, partner, "rotate_file_resolve_null_or_dead")
        return
    if not pair_state_ok(init) or not pair_state_ok(partner):
        var si2: String = CombatantEntityAccess.state_str(init) if not init.is_empty() else "null"
        var sp2: String = CombatantEntityAccess.state_str(partner) if not partner.is_empty() else "null"
        abort_pair(manager, init, partner, "rotate_file_resolve_pair_state init=%s partner=%s" % [si2, sp2])
        if not init.is_empty() and CombatantEntityAccess.alive_bool(init):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
        if not partner.is_empty() and CombatantEntityAccess.alive_bool(partner):
            CombatEventScheduler.schedule_action_ready_for_combatant(manager, partner)
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        abort_pair(manager, init, partner, "rotate_file_resolve_formation_empty fid=%s" % fid)
        return
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var f0: int = CombatantEntityAccess.file_int(init)
    var f1: int = CombatantEntityAccess.file_int(partner)
    var r_rot: int = CombatantEntityAccess.rank_int(init)
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(init))
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(partner))
    init.file = f1
    partner.file = f0
    repack_lane_offset_after_rank_file_change(init)
    repack_lane_offset_after_rank_file_change(partner)
    FormationSlots.slot_set_single(
        slots, Vector2i(r_rot, CombatantEntityAccess.file_int(init)), CombatantEntityAccess.id_int(init)
    )
    FormationSlots.slot_set_single(
        slots, Vector2i(r_rot, CombatantEntityAccess.file_int(partner)), CombatantEntityAccess.id_int(partner)
    )
    FormationSlots.refresh_gap_column_topology(formation)
    init.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    partner.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    _clear_shuffle_doctrine_commitments([init, partner])
    _stamp_rotate_file_cooldown(manager, init, partner)
    _stamp_rotate_file_reverse_pair_lock(manager, init, partner)
    _set_combatant_waiting(init)
    _set_combatant_waiting(partner)
    CombatDebug.flow_log(
        "rotate_file_resolve id=%d <-> %d complete files %d <-> %d" % [initiator_id, partner_id, f0, f1]
    )
    manager.emit_signal(
        "action_resolved", initiator_id, partner_id, {"outcome": "rotate_file_complete", "dmg": 0, "died": false}
    )
    manager.recompute_zoc_and_distance()
    manager.notify_formation_changed(fid)
    CombatEventScheduler.reschedule_back_rank_turns(manager, fid)
    CombatEventScheduler.reschedule_same_file_depth_after_rotate_file(manager, fid, f0, f1)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, partner)


## III-4 **3e**: depth fighter steps forward into rank-0 during envelop mop-up.
static func start_plug_forward(manager: Node, initiator_id: int, partner_id: int) -> void:
    if MedicalPhaseController.combat_resolution_blocked(manager):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
    if init.is_empty() or partner.is_empty():
        return
    if not CombatantEntityAccess.alive_bool(init) or not CombatantEntityAccess.alive_bool(partner):
        return
    if CombatantEntityAccess.formation_id_str(init) != CombatantEntityAccess.formation_id_str(partner):
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return
    var r_init: int = CombatantEntityAccess.rank_int(init)
    var r_partner: int = CombatantEntityAccess.rank_int(partner)
    # Depth fighter (rank > 0) plugs into rank-0 partner's slot.
    if r_init <= r_partner:
        return
    var f: int = CombatantEntityAccess.file_int(init)
    # Partner must be rank-0 in the same file.
    if r_partner != 0 or CombatantEntityAccess.file_int(partner) != f:
        return
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    # Target slot (rank-0, same file) must be empty or occupied by the partner we're swapping with.
    var target_slot_id: int = FormationSlots.slot_primary_id(slots, Vector2i(r_partner, f))
    if target_slot_id != -1 and target_slot_id != partner_id:
        return
    var duration: float = CombatConstants.PLUG_FORWARD_DURATION_S
    init[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = partner_id
    partner[DataKeys.FM_FORMATION_MOVE_PARTNER_ID] = initiator_id
    _scrub_idle_footwork_for_formation_move(init)
    _scrub_idle_footwork_for_formation_move(partner)
    var cooldown_until: float = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_PLUG_FORWARD_COOLDOWN_S
    )
    init[DataKeys.FM_FORMATION_PLUG_FORWARD_COOLDOWN_UNTIL] = cooldown_until
    partner[DataKeys.FM_FORMATION_PLUG_FORWARD_COOLDOWN_UNTIL] = cooldown_until
    init.state = CombatConstants.STATE_PLUG_FORWARD
    init.state_timer = 0.0
    init.state_duration = duration
    partner.state = CombatConstants.STATE_PLUG_FORWARD
    partner.state_timer = 0.0
    partner.state_duration = duration
    CombatMuscleFatigue.apply_formation_exertion(init, CombatConstants.MOVE_ID_PLUG_FORWARD)
    CombatMuscleFatigue.apply_formation_exertion(partner, CombatConstants.MOVE_ID_PLUG_FORWARD)
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(init))
    FormationSlots.slot_set_single(slots, Vector2i(r_partner, f), CombatantEntityAccess.id_int(partner))
    if CombatDebug.flow_verbose_enabled():
        var n0: String = CombatantEntityAccess.get_display_name(init, initiator_id)
        var n1: String = CombatantEntityAccess.get_display_name(partner, partner_id)
        CombatDebug.flow_log(
            "plug_forward_start %s (rank%d) -> %s (rank%d) (%.2fs)" % [n0, r_init, n1, r_partner, duration]
        )
    CombatantEntityAccess.manager_schedule_event(
        manager,
        {
            "type": CombatConstants.EVENT_PLUG_FORWARD_RESOLVE,
            "combatant_id": initiator_id,
            "resolve_at": CombatantEntityAccess.combat_clock_plus(manager, duration),
            "data": {"partner_id": partner_id}
        }
    )


static func handle_plug_forward_resolve(manager: Node, ev: Dictionary) -> void:
    var initiator_id: int = ev.get(DataKeys.EVENT_COMBATANT_ID, -1)
    var partner_id: int = -1
    var ev_data: Variant = ev.get(DataKeys.EVENT_DATA, null)
    if ev_data is Dictionary:
        partner_id = int((ev_data as Dictionary).get(DataKeys.EVENT_PARTNER_ID, -1))
    if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
        return
    var init = CombatantEntityAccess.manager_get_combatant(manager, initiator_id)
    var partner = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
    if init.is_empty() or partner.is_empty():
        return
    if not CombatantEntityAccess.alive_bool(init) or not CombatantEntityAccess.alive_bool(partner):
        abort_pair(manager, init, partner, "plug_forward_resolve_null_or_dead")
        return
    var fid: String = CombatantEntityAccess.formation_id_str(init)
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        abort_pair(manager, init, partner, "plug_forward_resolve_formation_empty fid=%s" % fid)
        return
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var f: int = CombatantEntityAccess.file_int(init)
    var r_init_old: int = CombatantEntityAccess.rank_int(init)
    var r_partner_old: int = CombatantEntityAccess.rank_int(partner)
    # Swap ranks in the same file: init goes to rank-0, partner goes to init's old rank.
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(init))
    FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(partner))
    init.rank = r_partner_old
    partner.rank = r_init_old
    repack_lane_offset_after_rank_file_change(init)
    repack_lane_offset_after_rank_file_change(partner)
    FormationSlots.slot_set_single(slots, Vector2i(r_partner_old, f), CombatantEntityAccess.id_int(init))
    FormationSlots.slot_set_single(slots, Vector2i(r_init_old, f), CombatantEntityAccess.id_int(partner))
    FormationSlots.refresh_gap_column_topology(formation)
    init.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    partner.erase(DataKeys.FM_FORMATION_MOVE_PARTNER_ID)
    init.erase(DataKeys.FM_FORMATION_PLUG_FORWARD_COOLDOWN_UNTIL)
    partner.erase(DataKeys.FM_FORMATION_PLUG_FORWARD_COOLDOWN_UNTIL)
    _clear_shuffle_doctrine_commitments([init, partner])
    _set_combatant_waiting(init)
    _set_combatant_waiting(partner)
    if CombatDebug.flow_verbose_enabled():
        var n0: String = CombatantEntityAccess.get_display_name(init, initiator_id)
        var n1: String = CombatantEntityAccess.get_display_name(partner, partner_id)
        CombatDebug.flow_log(
            "plug_forward_resolve %s (rank%d) -> %s (rank%d) complete" % [n0, r_partner_old, n1, r_init_old]
        )
    manager.emit_signal(
        "action_resolved", initiator_id, partner_id, {"outcome": "plug_forward_complete", "dmg": 0, "died": false}
    )
    manager.recompute_zoc_and_distance()
    manager.notify_formation_changed(fid)
    CombatEventScheduler.reschedule_back_rank_turns(manager, fid)
    CombatEventScheduler.reschedule_same_file_depth_after_rotate_file(manager, fid, f, f)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, init)
    CombatEventScheduler.schedule_action_ready_for_combatant(manager, partner)


static func on_combatant_died(manager: Node, c: Dictionary) -> void:
    if manager == null or c.is_empty():
        return
    var fid_home: String = CombatantEntityAccess.formation_id_str(c)
    var ctx_geom: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid_geom: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_geom)
    # Intruders may occupy host `slots` while `formation_id` stays home  -  strip from every formation first.
    for fk in manager.formations.keys():
        var fd: Dictionary = FormationSlots.formation_record_for_manager(manager, str(fk))
        if fd.is_empty():
            continue
        var s: Dictionary = FormationSlots.formation_slots_dict(fd)
        FormationSlots.remove_combatant_from_slots(s, CombatantEntityAccess.id_int(c))
    var formation: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx_geom)
    if formation.is_empty():
        return
    ## Corpse obstacle + vacancy micro-plug run on the **host** grid (`fid_geom`); roster home is `fid_home`.
    var r: int = CombatantEntityAccess.rank_int(c)
    var f: int = CombatantEntityAccess.file_int(c)
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    FormationSlots.prune_dead_ids_from_formation_slots(manager, slots)
    if not formation.has("slot_obstacles"):
        formation[DataKeys.FM_SLOT_OBSTACLES] = {}
    var obstacles: Dictionary = formation[DataKeys.FM_SLOT_OBSTACLES] as Dictionary
    var key := Vector2i(r, f)
    if not obstacles.has(key):
        obstacles[key] = []
    obstacles[key].append(CombatantEntityAccess.id_int(c))
    if formation.get(DataKeys.FORMATION_RANKS, 1) > 1:
        CombatFormationVacancyPlugs.run_death_column_micro_plug(manager, formation, fid_geom, slots, f)
    manager.recompute_zoc_and_distance()
    if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
        manager.mark_all_formations_vacancy_dirty()
    CombatantEntityAccess.manager_notify_formation_changed(manager, fid_geom)
    if fid_home != fid_geom:
        CombatantEntityAccess.manager_notify_formation_changed(manager, fid_home)
    CombatEventScheduler.reschedule_back_rank_turns(manager, fid_geom)
    if fid_home != fid_geom:
        CombatEventScheduler.reschedule_back_rank_turns(manager, fid_home)










