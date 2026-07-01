class_name CombatFormationFlow
extends RefCounted

## Formation moves, resolve events, slot plug on death, hit reaction delays on pending formation events.
## Footing: rank/file shuffle only  -  does **not** write **`guard_line`**, **`weapon_form`**, or **`position_angle_offset_deg`**. Lane duration mult: **`ZoneOfControl.get_footing_duration_multiplier`**. LIVE_PATHS **`#wf-footing-terminology`** · **`#wf-pick-vs-strike`**.
##
## **Vacancy plug** on the home formation (empty rank-0 without death). **Death plug** stays in
## `on_combatant_died` only; same-tick ordering avoids mixing vacancy with death removal.
##
## **Fill vs posture:** vacancy/death/pair moves are orthogonal to engagement posture;
## `lane_offset` repacks to column center when rank/file changes.
##
## **Vacancy reconcile:** `reconcile_vacancy_plugs` (dirty-only when `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY`) or full
## `reconcile_vacancy_plugs_track_changed_fids`; per-file work in `reconcile_vacancy_plugs_formation`. **`finish_vacancy_reconcile_follow_up`**
## applies ZoC, moved-only back-rank `action_ready`, and optional `formation_changed`. `notify_formation_changed` marks dirty then reconciles;
## `get_available_actions` marks all lines then reconciles (full pass); `CombatProcessTick` reconciles dirty formations only.
## **Plug priority (rank-0 hole, after same-column vertical):** **rear infill** from **any** other file (`rear_infill`:
## rank Ã¢â°Â¥ 1 steps into the empty front slot when the hole column is passable) before **front-rank lateral**
## (same-rank neighbor slide). Cross-file rear uses `prox` = rank depth + |Ã"file| so closer reserves win; lateral is last resort.
## Front lateral at rank 0 only when `_rank0_lateral_slide_allowed` (hole column has no promotable native deeper).
## Deeper empty ranks: same-rank lateral from neighbors is allowed so the rear echelon can close gaps without rank-0 shuffling.
## `apply_vacancy_plug_same_file` scans **deepest empty rank first** so a gap under the front is closed from the rear before rank-0 considers lateral.
## Donors are **reserved** for the reconcile pass so the same unit is not assigned to two holes.
## Rank/file shuffle resolve + vacancy plug call **`CombatDoctrine.clear_combatant_doctrine_commitment`** (stale target lock).
## Footing: return-to-waiting via **`_set_combatant_waiting`** · shuffle start via **`_scrub_idle_footwork_for_formation_move`**  -  LIVE_PATHS **`#wf-tier-44-pa`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _VacancyPlugs := preload("res://combat/CombatFormationVacancyPlugs.gd")
const _MoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")


static func _set_combatant_waiting(c: Dictionary) -> void:
	_Footwork.return_to_waiting(c)


static func _scrub_idle_footwork_for_formation_move(c: Dictionary) -> void:
	_Footwork.reconcile_idle_offset(c)


static func _clear_shuffle_doctrine_commitments(combatants: Array) -> void:
	for c in combatants:
		if c is Dictionary and not (c as Dictionary).is_empty():
			_Doctrine.clear_combatant_doctrine_commitment(c as Dictionary)


static func _stamp_rotate_file_cooldown(manager: Node, c0: Dictionary, c1: Dictionary) -> void:
	if manager == null or c0.is_empty() or c1.is_empty():
		return
	var until: float = (
		_EntityAccess.combat_clock_float(manager)
		+ CombatConstants.FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S
	)
	c0["formation_rotate_file_cooldown_until"] = until
	c1["formation_rotate_file_cooldown_until"] = until


static func _stamp_rotate_file_reverse_pair_lock(
	manager: Node, c0: Dictionary, c1: Dictionary
) -> void:
	if manager == null or c0.is_empty() or c1.is_empty():
		return
	var until: float = (
		_EntityAccess.combat_clock_float(manager)
		+ CombatConstants.FORMATION_ROTATE_FILE_REVERSE_PAIR_LOCK_S
	)
	var id0: int = _EntityAccess.id_int(c0)
	var id1: int = _EntityAccess.id_int(c1)
	c0["formation_rotate_file_reverse_lock_until"] = until
	c0["formation_rotate_file_reverse_partner_id"] = id1
	c1["formation_rotate_file_reverse_lock_until"] = until
	c1["formation_rotate_file_reverse_partner_id"] = id0


## True when this unit just rotated with `partner_id` and must not immediately swap back.
static func rotate_file_reverse_pair_blocked(
	manager: Node, c: Dictionary, partner_id: int
) -> bool:
	if manager == null or c.is_empty() or partner_id < 0:
		return false
	if not c.has("formation_rotate_file_reverse_partner_id"):
		return false
	var until: float = c.get("formation_rotate_file_reverse_lock_until", -1.0)
	if _EntityAccess.combat_clock_float(manager) >= until:
		return false
	return c.get("formation_rotate_file_reverse_partner_id", -1) == partner_id


static func _pair_abort_cooldown_active(manager: Node, c: Dictionary) -> bool:
	return _EntityAccess.combatant_cooldown_active(
		manager, c, "formation_pair_abort_cooldown_until", -1.0
	)


static func _rotate_file_cooldown_active(manager: Node, c: Dictionary) -> bool:
	return _EntityAccess.combatant_cooldown_active(
		manager, c, "formation_rotate_file_cooldown_until", -1.0
	)


## Tier 1.3 P4: after rank/file changes from plugs or formation moves, keep `lane_offset` bounded (ÃÂ§4.2 repack).
## Intruders keep seam bias; line fighters reset to column center.
static func repack_lane_offset_after_rank_file_change(c: Dictionary) -> void:
	if c.is_empty():
		return
	c["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT


static func formation_has_frontline_fill_opportunity(manager: Node, fid: String) -> bool:
	return _VacancyPlugs.formation_has_frontline_fill_opportunity(manager, fid)


static func formation_has_rank0_hole(manager: Node, fid: String) -> bool:
	return _VacancyPlugs.formation_has_rank0_hole(manager, fid)


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
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var nfiles: int = maxi(1, int(formation.get("files", 1)))
	var occupied: int = 0
	for file in range(nfiles):
		if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
			occupied += 1
	return occupied * 2 <= nfiles


static func formation_has_frontline_fill_opportunity_at_file(
	manager: Node, fid: String, file: int
) -> bool:
	return _VacancyPlugs.formation_has_frontline_fill_opportunity_at_file(manager, fid, file)


static func apply_vacancy_plug_same_file(manager: Node, fid: String, file: int) -> bool:
	return _VacancyPlugs.apply_vacancy_plug_same_file(manager, fid, file)


static func reconcile_vacancy_plugs_formation(manager: Node, fid: String) -> bool:
	return _VacancyPlugs.reconcile_vacancy_plugs_formation(manager, fid)


static func reconcile_vacancy_plugs_track_changed_fids(manager: Node) -> Array:
	return _VacancyPlugs.reconcile_vacancy_plugs_track_changed_fids(manager)


static func reconcile_vacancy_plugs(manager: Node) -> Array:
	return _VacancyPlugs.reconcile_vacancy_plugs(manager)


static func reconcile_vacancy_plugs_dirty_fids(manager: Node) -> Array:
	return _VacancyPlugs.reconcile_vacancy_plugs_dirty_fids(manager)


static func reconcile_vacancy_plugs_all_formations(manager: Node) -> bool:
	return _VacancyPlugs.reconcile_vacancy_plugs_all_formations(manager)


static func finish_vacancy_reconcile_follow_up(
	manager: Node,
	changed_fids: Array,
	placement_snap_before: Dictionary,
	emit_formation_changed_signals: bool
) -> void:
	_VacancyPlugs.finish_vacancy_reconcile_follow_up(
		manager, changed_fids, placement_snap_before, emit_formation_changed_signals
	)


static func debug_verify_vacancy_invariants_after_reconcile(manager: Node) -> void:
	_VacancyPlugs.debug_verify_vacancy_invariants_after_reconcile(manager)




static func apply_hit_reaction_if_needed(manager: Node, combatant_id: int, intensity: float = 0.5) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var c = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty() or not _EntityAccess.alive_bool(c):
		return
	var st: String = _EntityAccess.state_str(c)
	if st != CombatConstants.STATE_SWAP_RANK and st != CombatConstants.STATE_FALLING_BACK and st != CombatConstants.STATE_PLUG_FORWARD:
		return
	if intensity >= CombatConstants.FORMATION_HIT_CANCEL_INTENSITY:
		cancel_formation_move_from_hit(manager, combatant_id, intensity)
		return
	var extra: float = CombatConstants.FORMATION_HIT_REACTION_EXTRA_S * lerpf(0.4, 1.2, clampf(intensity, 0.0, 1.0))
	c.state_duration += extra
	var pid: int = c.get("formation_move_partner_id", -1)
	if pid >= 0:
		var p = _EntityAccess.manager_get_combatant(manager, pid)
		if not p.is_empty() and _EntityAccess.alive_bool(p):
			var pst: String = _EntityAccess.state_str(p)
			if pst == CombatConstants.STATE_SWAP_RANK or pst == CombatConstants.STATE_FALLING_BACK or pst == CombatConstants.STATE_PLUG_FORWARD:
				p.state_duration += extra
	bump_resolve_events(manager, combatant_id, extra)


## Hard hit during **`STATE_SWAP_RANK`** / **`STATE_FALLING_BACK`**: abort pair or solo move and drop pending resolves.
static func cancel_formation_move_from_hit(
	manager: Node, combatant_id: int, intensity: float = 1.0
) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var c = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty() or not _EntityAccess.alive_bool(c):
		return
	var st: String = _EntityAccess.state_str(c)
	if st != CombatConstants.STATE_SWAP_RANK and st != CombatConstants.STATE_FALLING_BACK and st != CombatConstants.STATE_PLUG_FORWARD:
		return
	var pid: int = c.get("formation_move_partner_id", -1)
	_EventScheduler.cancel_pending_formation_events_for_combatant(manager, combatant_id)
	if pid >= 0:
		_EventScheduler.cancel_pending_formation_events_for_combatant(manager, pid)
		var partner = _EntityAccess.manager_get_combatant(manager, pid)
		abort_pair(manager, c, partner, "hit_cancel intensity=%.2f" % intensity)
		if _EntityAccess.alive_bool(c):
			_EventScheduler.schedule_action_ready_for_combatant(manager, c)
		if not partner.is_empty() and _EntityAccess.alive_bool(partner):
			_EventScheduler.schedule_action_ready_for_combatant(manager, partner)
	else:
		abort_solo_formation_move(manager, c, "hit_cancel intensity=%.2f" % intensity)
		if _EntityAccess.alive_bool(c):
			_EventScheduler.schedule_action_ready_for_combatant(manager, c)


static func bump_resolve_events(manager: Node, for_combatant_id: int, extra_s: float) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	for ev in manager.event_queue:
		if ev is not Dictionary:
			continue
		var t: String = ev.get("type", "")
		var cid: int = ev.get("combatant_id", -1)
		var data_raw: Variant = ev.get("data", null)
		var data: Dictionary = data_raw if data_raw is Dictionary else {}
		var bump: bool = false
		match t:
			CombatConstants.EVENT_SWAP_RANK_RESOLVE:
				if cid == for_combatant_id or data.get("partner_id", -1) == for_combatant_id:
					bump = true
			CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE:
				if cid == for_combatant_id:
					bump = true
			CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
				if cid == for_combatant_id or data.get("partner_id", -1) == for_combatant_id:
					bump = true
		if bump:
			ev["resolve_at"] = ev.get("resolve_at", 0.0) + extra_s
	_EventScheduler.sort_event_queue(manager)


static func start_pair_move(manager: Node, initiator_id: int, partner_id: int, move_kind: String) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty() or partner.is_empty() or not _EntityAccess.is_available_formation_partner(init, partner):
		return
	if _pair_abort_cooldown_active(manager, init) or _pair_abort_cooldown_active(manager, partner):
		return
	if _EntityAccess.formation_id_str(init) != _EntityAccess.formation_id_str(partner):
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty() or formation.get("ranks", 1) <= 1:
		return
	var r0: int = _EntityAccess.rank_int(init)
	var r1: int = _EntityAccess.rank_int(partner)
	var f0: int = _EntityAccess.file_int(init)
	var f1: int = _EntityAccess.file_int(partner)
	if f0 != f1 or abs(r0 - r1) != 1:
		return
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var duration: float = _MoveDuration.estimate_adjacent_rank_pair_duration_s(
		manager, init, partner, move_kind
	)
	var use_falling: bool = move_kind == CombatConstants.MOVE_ID_DRAG_BACK or move_kind == CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR
	var st: String = CombatConstants.STATE_FALLING_BACK if use_falling else CombatConstants.STATE_SWAP_RANK
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var r_lo: int = mini(r0, r1)
	var r_hi: int = maxi(r0, r1)
	var id_at_lo: int = _EntityAccess.id_int(init) if _EntityAccess.rank_int(init) == r_lo else _EntityAccess.id_int(partner)
	var id_at_hi: int = _EntityAccess.id_int(init) if _EntityAccess.rank_int(init) == r_hi else _EntityAccess.id_int(partner)
	_FormationSlots.begin_adjacent_rank_pair_move(slots, r_lo, r_hi, f0, id_at_lo, id_at_hi)
	init["formation_move_partner_id"] = partner_id
	partner["formation_move_partner_id"] = initiator_id
	_scrub_idle_footwork_for_formation_move(init)
	_scrub_idle_footwork_for_formation_move(partner)
	init.state = st
	init.state_timer = 0.0
	init.state_duration = duration
	partner.state = st
	partner.state_timer = 0.0
	partner.state_duration = duration
	if CombatDebug.flow_verbose_enabled():
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		CombatDebug.flow_log(
			"formation_move_start %s (%d) %s with %s (%d) (%.2fs lane- - foot- - %.2f pressure- - %.2f)"
			% [n0, initiator_id, move_kind, n1, partner_id, duration, lane_foot, pressure_mod]
		)
	_EventScheduler.cancel_pending_swap_rank_pair_events(manager, initiator_id, partner_id)
	_EntityAccess.manager_schedule_event(manager, {
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": _EntityAccess.combat_clock_plus(manager, duration),
		"data": {"partner_id": partner_id, "move_kind": move_kind}
	})


static func start_fall_back_solo(manager: Node, initiator_id: int) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	if init.is_empty() or not _EntityAccess.alive_bool(init):
		return
	if _pair_abort_cooldown_active(manager, init):
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		return
	var ranks: int = formation.get("ranks", 1)
	if ranks <= 1 or _EntityAccess.rank_int(init) != 0:
		return
	var f: int = _EntityAccess.file_int(init)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
		return
	var duration: float = _MoveDuration.estimate_solo_fall_back_duration_s(manager, init)
	init["formation_move_partner_id"] = -1
	_scrub_idle_footwork_for_formation_move(init)
	init.state = CombatConstants.STATE_FALLING_BACK
	init.state_timer = 0.0
	init.state_duration = duration
	if CombatDebug.flow_verbose_enabled():
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		CombatDebug.flow_log("fall_back_solo_start %s (%d) (%.2fs)" % [n0, initiator_id, duration])
	_EntityAccess.manager_schedule_event(manager, {
		"type": CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": _EntityAccess.combat_clock_plus(manager, duration),
		"data": {}
	})


static func start_rotate_file(manager: Node, initiator_id: int, partner_id: int) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty() or partner.is_empty() or not _EntityAccess.is_available_formation_partner(init, partner):
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
	if _EntityAccess.formation_id_str(init) != _EntityAccess.formation_id_str(partner):
		return
	var r_init: int = _EntityAccess.rank_int(init)
	var r_partner: int = _EntityAccess.rank_int(partner)
	if r_init != r_partner:
		return
	var f0: int = _EntityAccess.file_int(init)
	var f1: int = _EntityAccess.file_int(partner)
	if abs(f0 - f1) != 1:
		return
	var duration: float = _MoveDuration.estimate_rotate_file_duration_s(manager, init, partner)
	init["formation_move_partner_id"] = partner_id
	partner["formation_move_partner_id"] = initiator_id
	_scrub_idle_footwork_for_formation_move(init)
	_scrub_idle_footwork_for_formation_move(partner)
	init.state = CombatConstants.STATE_SWAP_RANK
	init.state_timer = 0.0
	init.state_duration = duration
	partner.state = CombatConstants.STATE_SWAP_RANK
	partner.state_timer = 0.0
	partner.state_duration = duration
	if CombatDebug.flow_verbose_enabled():
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		CombatDebug.flow_log("rotate_file_start %s (%d) <-> %s (%d) (%.2fs)" % [n0, initiator_id, n1, partner_id, duration])
	_EntityAccess.manager_schedule_event(manager, {
		"type": CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": _EntityAccess.combat_clock_plus(manager, duration),
		"data": {"partner_id": partner_id}
	})


static func pair_state_ok(c) -> bool:
	return not c.is_empty() and _EntityAccess.state_str(c) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]


static func abort_pair(manager: Node, init, partner, reason: String = "") -> void:
	var iid: int = _EntityAccess.id_int(init) if not init.is_empty() else -1
	var pid: int = _EntityAccess.id_int(partner) if not partner.is_empty() else -1
	var rs: String = (" reason=%s" % reason) if not reason.is_empty() else ""
	CombatDebug.flow_log("formation_pair abort (reset to waiting) initiator_id=%d partner_id=%d%s" % [iid, pid, rs])
	if not init.is_empty():
		init.erase("formation_move_partner_id")
	if not partner.is_empty():
		partner.erase("formation_move_partner_id")
	if not init.is_empty() and not partner.is_empty():
		var fid: String = _EntityAccess.formation_id_str(init)
		if not fid.is_empty() and _EntityAccess.formation_id_str(init) == _EntityAccess.formation_id_str(partner):
			var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
			var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
			_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(init))
			_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(partner))
			if _EntityAccess.alive_bool(init):
				_FormationSlots.slot_set_single(slots, Vector2i(_EntityAccess.rank_int(init), _EntityAccess.file_int(init)), _EntityAccess.id_int(init))
			if _EntityAccess.alive_bool(partner):
				_FormationSlots.slot_set_single(slots, Vector2i(_EntityAccess.rank_int(partner), _EntityAccess.file_int(partner)), _EntityAccess.id_int(partner))
			manager.recompute_zoc_and_distance()
			manager.notify_formation_changed(fid)
			_EventScheduler.reschedule_back_rank_turns(manager, fid)
	if not init.is_empty() and _EntityAccess.alive_bool(init) and pair_state_ok(init):
		_set_combatant_waiting(init)
	if not partner.is_empty() and _EntityAccess.alive_bool(partner) and pair_state_ok(partner):
		_set_combatant_waiting(partner)
	# Keep a brief local guard after abort so the same pair does not instantly requeue under churn.
	var until: float = _EntityAccess.combat_clock_float(manager) + 0.7
	if not init.is_empty() and _EntityAccess.alive_bool(init):
		init["formation_pair_abort_cooldown_until"] = until
	if not partner.is_empty() and _EntityAccess.alive_bool(partner):
		partner["formation_pair_abort_cooldown_until"] = until


static func abort_solo_formation_move(manager: Node, init, reason: String = "") -> void:
	var iid: int = _EntityAccess.id_int(init) if not init.is_empty() else -1
	var rs: String = (" reason=%s" % reason) if not reason.is_empty() else ""
	CombatDebug.flow_log("formation_solo abort (reset to waiting) id=%d%s" % [iid, rs])
	if init.is_empty():
		return
	init.erase("formation_move_partner_id")
	if _EntityAccess.alive_bool(init) and _EntityAccess.state_str(init) == CombatConstants.STATE_FALLING_BACK:
		_set_combatant_waiting(init)
	var until: float = _EntityAccess.combat_clock_float(manager) + 0.7
	if _EntityAccess.alive_bool(init):
		init["formation_pair_abort_cooldown_until"] = until


static func _formation_resolve_medical_phase_skip(
	manager: Node, initiator_id: int, partner_id: int = -1
) -> bool:
	if not MedicalPhaseController.should_skip_formation_resolve(manager, initiator_id, partner_id):
		return false
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, partner_id)
	for c in [init, partner]:
		if c.is_empty() or not _EntityAccess.alive_bool(c):
			continue
		_set_combatant_waiting(c)
		c.state_timer = 0.0
		c.state_duration = 0.0
		c.erase("formation_move_partner_id")
	return true


static func handle_swap_rank_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var data_raw: Variant = ev.get("data", null)
	var data: Dictionary = data_raw if data_raw is Dictionary else {}
	var partner_id: int = data.get("partner_id", -1)
	var move_kind: String = data.get("move_kind", CombatConstants.MOVE_ID_SWAP_RANK)
	if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty():
		if not partner.is_empty() and pair_state_ok(partner):
			_set_combatant_waiting(partner)
		return
	if partner.is_empty():
		if pair_state_ok(init):
			_set_combatant_waiting(init)
		return
	if not _EntityAccess.are_both_alive(init, partner):
		abort_pair(manager, init, partner, "swap_rank_resolve_not_alive")
		if not init.is_empty() and _EntityAccess.alive_bool(init):
			_EventScheduler.schedule_action_ready_for_combatant(manager, init)
		if not partner.is_empty() and _EntityAccess.alive_bool(partner):
			_EventScheduler.schedule_action_ready_for_combatant(manager, partner)
		return
	if not pair_state_ok(init) or not pair_state_ok(partner):
		var si: String = _EntityAccess.state_str(init) if not init.is_empty() else "null"
		var sp: String = _EntityAccess.state_str(partner) if not partner.is_empty() else "null"
		abort_pair(manager, init, partner, "swap_rank_resolve_pair_state init=%s partner=%s" % [si, sp])
		if not init.is_empty() and _EntityAccess.alive_bool(init):
			_EventScheduler.schedule_action_ready_for_combatant(manager, init)
		if not partner.is_empty() and _EntityAccess.alive_bool(partner):
			_EventScheduler.schedule_action_ready_for_combatant(manager, partner)
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		abort_pair(manager, init, partner, "swap_rank_resolve_formation_empty fid=%s" % fid)
		return
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var r0: int = _EntityAccess.rank_int(init)
	var r1: int = _EntityAccess.rank_int(partner)
	var f0: int = _EntityAccess.file_int(init)
	var f1: int = _EntityAccess.file_int(partner)
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(init))
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(partner))
	init.rank = r1
	init.file = f1
	partner.rank = r0
	partner.file = f0
	repack_lane_offset_after_rank_file_change(init)
	repack_lane_offset_after_rank_file_change(partner)
	_FormationSlots.slot_set_single(
		slots,
		Vector2i(_EntityAccess.rank_int(init), _EntityAccess.file_int(init)),
		_EntityAccess.id_int(init)
	)
	_FormationSlots.slot_set_single(
		slots,
		Vector2i(_EntityAccess.rank_int(partner), _EntityAccess.file_int(partner)),
		_EntityAccess.id_int(partner)
	)
	_FormationSlots.refresh_gap_column_topology(formation)
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
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
	manager.emit_signal("action_resolved", initiator_id, partner_id, {"outcome": outcome, "dmg": 0, "died": false, "move_kind": move_kind})
	if CombatDebug.flow_verbose_enabled():
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		CombatDebug.flow_log(
			"formation_pair_resolve %s (%d) <-> %s (%d) move_kind=%s outcome=%s"
			% [n0, initiator_id, n1, partner_id, move_kind, outcome]
		)
	manager.recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	_EventScheduler.reschedule_back_rank_turns(manager, fid)
	_EventScheduler.reschedule_same_file_depth_rank2_plus(manager, fid, f0)
	_EventScheduler.schedule_action_ready_for_combatant(manager, init)
	if not partner.is_empty() and _EntityAccess.is_standing_combatant(partner):
		_EventScheduler.schedule_action_ready(
			manager, partner_id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S
		)


static func handle_fall_back_solo_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	if _formation_resolve_medical_phase_skip(manager, initiator_id):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	if init.is_empty() or not _EntityAccess.alive_bool(init):
		return
	if _EntityAccess.state_str(init) != CombatConstants.STATE_FALLING_BACK:
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		_set_combatant_waiting(init)
		return
	var f: int = _EntityAccess.file_int(init)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
		CombatDebug.flow_log("fall_back_solo_resolve id=%d aborted: rear slot (1,%d) occupied" % [initiator_id, f])
		_set_combatant_waiting(init)
		_EventScheduler.schedule_action_ready_for_combatant(manager, init)
		return
	_FormationSlots.remove_combatant_from_slots(slots, initiator_id)
	init.rank = 1
	repack_lane_offset_after_rank_file_change(init)
	_FormationSlots.slot_set_single(slots, Vector2i(1, f), initiator_id)
	_FormationSlots.refresh_gap_column_topology(formation)
	init.erase("formation_move_partner_id")
	_clear_shuffle_doctrine_commitments([init])
	_set_combatant_waiting(init)
	CombatDebug.flow_log("fall_back_solo_resolve id=%d complete rank 0->1 file %d" % [initiator_id, f])
	if _EntityAccess.get_attacking_arm(init).is_empty():
		_F5SoakTrace.note_cowering_fall_back_executed(
			_EntityAccess.get_display_name(init, initiator_id), f
		)
	manager.emit_signal("action_resolved", initiator_id, initiator_id, {"outcome": "fall_back_solo_complete", "dmg": 0, "died": false})
	manager.recompute_zoc_and_distance()
	# Manual rank/file write above  -  skip vacancy reconcile (would plug rank-2 into rank-1 and undo retreat).
	manager.emit_signal("formation_changed", fid)
	_EventScheduler.reschedule_back_rank_turns(manager, fid)
	_EventScheduler.reschedule_same_file_depth_rank2_plus(manager, fid, f)
	_EventScheduler.schedule_action_ready_for_combatant(manager, init)


static func handle_rotate_file_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var partner_id: int = -1
	var ev_data: Variant = ev.get("data", null)
	if ev_data is Dictionary:
		partner_id = int((ev_data as Dictionary).get("partner_id", -1))
	if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty() or partner.is_empty() or not _EntityAccess.are_both_alive(init, partner):
		abort_pair(manager, init, partner, "rotate_file_resolve_null_or_dead")
		return
	if not pair_state_ok(init) or not pair_state_ok(partner):
		var si2: String = _EntityAccess.state_str(init) if not init.is_empty() else "null"
		var sp2: String = _EntityAccess.state_str(partner) if not partner.is_empty() else "null"
		abort_pair(manager, init, partner, "rotate_file_resolve_pair_state init=%s partner=%s" % [si2, sp2])
		if not init.is_empty() and _EntityAccess.alive_bool(init):
			_EventScheduler.schedule_action_ready_for_combatant(manager, init)
		if not partner.is_empty() and _EntityAccess.alive_bool(partner):
			_EventScheduler.schedule_action_ready_for_combatant(manager, partner)
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		abort_pair(manager, init, partner, "rotate_file_resolve_formation_empty fid=%s" % fid)
		return
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var f0: int = _EntityAccess.file_int(init)
	var f1: int = _EntityAccess.file_int(partner)
	var r_rot: int = _EntityAccess.rank_int(init)
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(init))
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(partner))
	init.file = f1
	partner.file = f0
	repack_lane_offset_after_rank_file_change(init)
	repack_lane_offset_after_rank_file_change(partner)
	_FormationSlots.slot_set_single(
		slots,
		Vector2i(r_rot, _EntityAccess.file_int(init)),
		_EntityAccess.id_int(init)
	)
	_FormationSlots.slot_set_single(
		slots,
		Vector2i(r_rot, _EntityAccess.file_int(partner)),
		_EntityAccess.id_int(partner)
	)
	_FormationSlots.refresh_gap_column_topology(formation)
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
	_clear_shuffle_doctrine_commitments([init, partner])
	_stamp_rotate_file_cooldown(manager, init, partner)
	_stamp_rotate_file_reverse_pair_lock(manager, init, partner)
	_set_combatant_waiting(init)
	_set_combatant_waiting(partner)
	CombatDebug.flow_log("rotate_file_resolve id=%d <-> %d complete files %d <-> %d" % [initiator_id, partner_id, f0, f1])
	manager.emit_signal("action_resolved", initiator_id, partner_id, {"outcome": "rotate_file_complete", "dmg": 0, "died": false})
	manager.recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	_EventScheduler.reschedule_back_rank_turns(manager, fid)
	_EventScheduler.reschedule_same_file_depth_after_rotate_file(manager, fid, f0, f1)
	_EventScheduler.schedule_action_ready_for_combatant(manager, init)
	_EventScheduler.schedule_action_ready_for_combatant(manager, partner)


## III-4 **3e**: depth fighter steps forward into rank-0 during envelop mop-up.
static func start_plug_forward(manager: Node, initiator_id: int, partner_id: int) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty() or partner.is_empty():
		return
	if not _EntityAccess.alive_bool(init) or not _EntityAccess.alive_bool(partner):
		return
	if _EntityAccess.formation_id_str(init) != _EntityAccess.formation_id_str(partner):
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		return
	var r_init: int = _EntityAccess.rank_int(init)
	var r_partner: int = _EntityAccess.rank_int(partner)
	# Depth fighter (rank > 0) plugs into rank-0 partner's slot.
	if r_init <= r_partner:
		return
	var f: int = _EntityAccess.file_int(init)
	# Partner must be rank-0 in the same file.
	if r_partner != 0 or _EntityAccess.file_int(partner) != f:
		return
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	# Target slot (rank-0, same file) must be empty or occupied by the partner we're swapping with.
	var target_slot_id: int = _FormationSlots.slot_primary_id(slots, Vector2i(r_partner, f))
	if target_slot_id != -1 and target_slot_id != partner_id:
		return
	var duration: float = CombatConstants.PLUG_FORWARD_DURATION_S
	init["formation_move_partner_id"] = partner_id
	partner["formation_move_partner_id"] = initiator_id
	_scrub_idle_footwork_for_formation_move(init)
	_scrub_idle_footwork_for_formation_move(partner)
	var cooldown_until: float = (
		_EntityAccess.combat_clock_float(manager) + CombatConstants.FORMATION_PLUG_FORWARD_COOLDOWN_S
	)
	init["formation_plug_forward_cooldown_until"] = cooldown_until
	partner["formation_plug_forward_cooldown_until"] = cooldown_until
	init.state = CombatConstants.STATE_PLUG_FORWARD
	init.state_timer = 0.0
	init.state_duration = duration
	partner.state = CombatConstants.STATE_PLUG_FORWARD
	partner.state_timer = 0.0
	partner.state_duration = duration
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(init))
	_FormationSlots.slot_set_single(slots, Vector2i(r_partner, f), _EntityAccess.id_int(partner))
	if CombatDebug.flow_verbose_enabled():
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		CombatDebug.flow_log(
			"plug_forward_start %s (rank%d) -> %s (rank%d) (%.2fs)"
			% [n0, r_init, n1, r_partner, duration]
		)
	_EntityAccess.manager_schedule_event(manager, {
		"type": CombatConstants.EVENT_PLUG_FORWARD_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": _EntityAccess.combat_clock_plus(manager, duration),
		"data": {"partner_id": partner_id}
	})


static func handle_plug_forward_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var partner_id: int = -1
	var ev_data: Variant = ev.get("data", null)
	if ev_data is Dictionary:
		partner_id = int((ev_data as Dictionary).get("partner_id", -1))
	if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty() or partner.is_empty():
		return
	if not _EntityAccess.alive_bool(init) or not _EntityAccess.alive_bool(partner):
		abort_pair(manager, init, partner, "plug_forward_resolve_null_or_dead")
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		abort_pair(manager, init, partner, "plug_forward_resolve_formation_empty fid=%s" % fid)
		return
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var f: int = _EntityAccess.file_int(init)
	var r_init_old: int = _EntityAccess.rank_int(init)
	var r_partner_old: int = _EntityAccess.rank_int(partner)
	# Swap ranks in the same file: init goes to rank-0, partner goes to init's old rank.
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(init))
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(partner))
	init.rank = r_partner_old
	partner.rank = r_init_old
	repack_lane_offset_after_rank_file_change(init)
	repack_lane_offset_after_rank_file_change(partner)
	_FormationSlots.slot_set_single(
		slots,
		Vector2i(r_partner_old, f),
		_EntityAccess.id_int(init)
	)
	_FormationSlots.slot_set_single(
		slots,
		Vector2i(r_init_old, f),
		_EntityAccess.id_int(partner)
	)
	_FormationSlots.refresh_gap_column_topology(formation)
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
	init.erase("formation_plug_forward_cooldown_until")
	partner.erase("formation_plug_forward_cooldown_until")
	_clear_shuffle_doctrine_commitments([init, partner])
	_set_combatant_waiting(init)
	_set_combatant_waiting(partner)
	if CombatDebug.flow_verbose_enabled():
		var _n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var _n1: String = _EntityAccess.get_display_name(partner, partner_id)
		CombatDebug.flow_log(
			"plug_forward_resolve %s (rank%d) -> %s (rank%d) complete"
			% [_n0, r_partner_old, _n1, r_init_old]
		)
	manager.emit_signal("action_resolved", initiator_id, partner_id, {"outcome": "plug_forward_complete", "dmg": 0, "died": false})
	manager.recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	_EventScheduler.reschedule_back_rank_turns(manager, fid)
	_EventScheduler.reschedule_same_file_depth_after_rotate_file(manager, fid, f, f)
	_EventScheduler.schedule_action_ready_for_combatant(manager, init)
	_EventScheduler.schedule_action_ready_for_combatant(manager, partner)

static func on_combatant_died(manager: Node, c: Dictionary) -> void:
	var fid_home: String = _EntityAccess.formation_id_str(c)
	var ctx_geom: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid_geom: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_geom)
	# Intruders may occupy host `slots` while `formation_id` stays home  -  strip from every formation first.
	for fk in manager.formations.keys():
		var fd: Dictionary = _FormationSlots.formation_record_for_manager(manager, str(fk))
		if fd.is_empty():
			continue
		var s: Dictionary = _FormationSlots.formation_slots_dict(fd)
		_FormationSlots.remove_combatant_from_slots(s, _EntityAccess.id_int(c))
	var formation: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_geom)
	if formation.is_empty():
		return
	## Corpse obstacle + vacancy micro-plug run on the **host** grid (`fid_geom`); roster home is `fid_home`.
	var r: int = _EntityAccess.rank_int(c)
	var f: int = _EntityAccess.file_int(c)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	_FormationSlots.prune_dead_ids_from_formation_slots(manager, slots)
	if not formation.has("slot_obstacles"):
		formation["slot_obstacles"] = {}
	var obstacles: Dictionary = formation["slot_obstacles"] as Dictionary
	var key := Vector2i(r, f)
	if not obstacles.has(key):
		obstacles[key] = []
	obstacles[key].append(_EntityAccess.id_int(c))
	if formation.get("ranks", 1) > 1:
		_VacancyPlugs.run_death_column_micro_plug(manager, formation, fid_geom, slots, f)
	manager.recompute_zoc_and_distance()
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		manager.mark_all_formations_vacancy_dirty()
	_EntityAccess.manager_notify_formation_changed(manager, fid_geom)
	if fid_home != fid_geom:
		_EntityAccess.manager_notify_formation_changed(manager, fid_home)
	_EventScheduler.reschedule_back_rank_turns(manager, fid_geom)
	if fid_home != fid_geom:
		_EventScheduler.reschedule_back_rank_turns(manager, fid_home)
    