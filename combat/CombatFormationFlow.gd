class_name CombatFormationFlow
extends RefCounted

## Formation moves, resolve events, slot plug on death, hit reaction delays on pending formation events.
## **Read order:** pair move start/resolve → death plug → vacancy reconcile follow-up (see **`CombatFormationVacancyPlugs`**).
## **Pair `move_kind`:** **`CombatConstants.FORMATION_MOVE_KIND_*`** (flow/events) — listing uses **`MOVE_ID_*`** (`fall_back` vs **`FORMATION_MOVE_KIND_FALL_BACK_PAIR`**).
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
## rank â‰¥ 1 steps into the empty front slot when the hole column is passable) before **front-rank lateral**
## (same-rank neighbor slide). Cross-file rear uses `prox` = rank depth + |Î”file| so closer reserves win; lateral is last resort.
## Front lateral at rank 0 only when `_rank0_lateral_slide_allowed` (hole column has no promotable native deeper).
## Deeper empty ranks: same-rank lateral from neighbors is allowed so the rear echelon can close gaps without rank-0 shuffling.
## `apply_vacancy_plug_same_file` scans **deepest empty rank first** so a gap under the front is closed from the rear before rank-0 considers lateral.
## Donors are **reserved** for the reconcile pass so the same unit is not assigned to two holes.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _Timing := preload("res://combat/CombatTiming.gd")
const _VacancyPlugs := preload("res://combat/CombatFormationVacancyPlugs.gd")
const _MoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")


## Tier 1.3 P4: after rank/file changes from plugs or formation moves, keep `lane_offset` bounded (Â§4.2 repack).
## Intruders keep seam bias; line fighters reset to column center.
static func repack_lane_offset_after_rank_file_change(c: Dictionary) -> void:
	if c.is_empty():
		return
	c["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT


static func formation_has_frontline_fill_opportunity(manager: Node, fid: String) -> bool:
	return _VacancyPlugs.formation_has_frontline_fill_opportunity(manager, fid)


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
	if st != CombatConstants.STATE_SWAP_RANK and st != CombatConstants.STATE_FALLING_BACK:
		return
	if intensity >= CombatConstants.FORMATION_HIT_CANCEL_INTENSITY:
		cancel_formation_move_from_hit(manager, combatant_id, intensity)
		return
	var extra: float = CombatConstants.FORMATION_HIT_REACTION_EXTRA_S * lerpf(0.4, 1.2, clampf(intensity, 0.0, 1.0))
	c.state_duration += extra
	var pid: int = int(c.get("formation_move_partner_id", -1))
	if pid >= 0:
		var p = _EntityAccess.manager_get_combatant(manager, pid)
		if not p.is_empty() and _EntityAccess.alive_bool(p):
			var pst: String = _EntityAccess.state_str(p)
			if pst == CombatConstants.STATE_SWAP_RANK or pst == CombatConstants.STATE_FALLING_BACK:
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
	if st != CombatConstants.STATE_SWAP_RANK and st != CombatConstants.STATE_FALLING_BACK:
		return
	var pid: int = int(c.get("formation_move_partner_id", -1))
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
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var t: String = ev.get("type", "")
		var cid: int = ev.get("combatant_id", -1)
		var data_raw: Variant = ev.get("data", null)
		var data: Dictionary = data_raw if data_raw is Dictionary else {}
		var bump: bool = false
		if t == CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			if cid == for_combatant_id or int(data.get("partner_id", -1)) == for_combatant_id:
				bump = true
		elif t == CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE and cid == for_combatant_id:
			bump = true
		elif t == CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
			if cid == for_combatant_id or int(data.get("partner_id", -1)) == for_combatant_id:
				bump = true
		if bump:
			ev["resolve_at"] = float(ev.get("resolve_at", 0.0)) + extra_s
	_EventScheduler.sort_event_queue(manager)


static func start_pair_move(manager: Node, initiator_id: int, partner_id: int, move_kind: String) -> void:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty() or partner.is_empty() or not _EntityAccess.is_available_formation_partner(init, partner):
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
	var use_falling: bool = (
		move_kind == CombatConstants.FORMATION_MOVE_KIND_DRAG_BACK
		or move_kind == CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR
	)
	var st: String = CombatConstants.STATE_FALLING_BACK if use_falling else CombatConstants.STATE_SWAP_RANK
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var r_lo: int = mini(r0, r1)
	var r_hi: int = maxi(r0, r1)
	var id_at_lo: int = _EntityAccess.id_int(init) if _EntityAccess.rank_int(init) == r_lo else _EntityAccess.id_int(partner)
	var id_at_hi: int = _EntityAccess.id_int(init) if _EntityAccess.rank_int(init) == r_hi else _EntityAccess.id_int(partner)
	_FormationSlots.begin_adjacent_rank_pair_move(slots, r_lo, r_hi, f0, id_at_lo, id_at_hi)
	init["formation_move_partner_id"] = partner_id
	partner["formation_move_partner_id"] = initiator_id
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
			"formation_move_start %s (%d) %s with %s (%d) (%.2fs laneÃ—footÃ—%.2f pressureÃ—%.2f)"
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
	return not c.is_empty() and _EntityAccess.state_str(c) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]


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
			manager._recompute_zoc_and_distance()
			manager.notify_formation_changed(fid)
			manager._reschedule_back_rank_turns(fid)
	if not init.is_empty() and _EntityAccess.alive_bool(init) and pair_state_ok(init):
		init.state = CombatConstants.STATE_WAITING
	if not partner.is_empty() and _EntityAccess.alive_bool(partner) and pair_state_ok(partner):
		partner.state = CombatConstants.STATE_WAITING
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
		init.state = CombatConstants.STATE_WAITING
	var until: float = _EntityAccess.combat_clock_float(manager) + 0.7
	if _EntityAccess.alive_bool(init):
		init["formation_pair_abort_cooldown_until"] = until


static func _formation_resolve_medical_phase_skip(
	manager: Node, initiator_id: int, partner_id: int = -1
) -> bool:
	if not MedicalPhaseController.should_skip_formation_resolve(manager, initiator_id, partner_id):
		return false
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner: Dictionary = _EntityAccess.manager_get_combatant(manager, partner_id)
	for c in [init, partner]:
		if c.is_empty() or not _EntityAccess.alive_bool(c):
			continue
		c.state = CombatConstants.STATE_WAITING
		c.state_timer = 0.0
		c.state_duration = 0.0
		c.erase("formation_move_partner_id")
	return true


static func handle_swap_rank_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var data_raw: Variant = ev.get("data", null)
	var data: Dictionary = data_raw if data_raw is Dictionary else {}
	var partner_id: int = data.get("partner_id", -1)
	var move_kind: String = data.get(
		"move_kind", CombatConstants.FORMATION_MOVE_KIND_SWAP_RANK
	)
	if _formation_resolve_medical_phase_skip(manager, initiator_id, partner_id):
		return
	var init = _EntityAccess.manager_get_combatant(manager, initiator_id)
	var partner = _EntityAccess.manager_get_combatant(manager, partner_id)
	if init.is_empty():
		if not partner.is_empty() and pair_state_ok(partner):
			partner.state = CombatConstants.STATE_WAITING
		return
	if partner.is_empty():
		if pair_state_ok(init):
			init.state = CombatConstants.STATE_WAITING
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
	_clear_doctrine_commitments_after_slot_change(init, partner)
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
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
	# Mirror CombatConstants rotate anti-thrash window; keep literal fallback to avoid stale analyzer symbol caches.
	var rotate_cd_until: float = _EntityAccess.combat_clock_float(manager) + 0.8
	init["formation_rotate_file_cooldown_until"] = rotate_cd_until
	partner["formation_rotate_file_cooldown_until"] = rotate_cd_until
	init.state = CombatConstants.STATE_WAITING
	partner.state = CombatConstants.STATE_WAITING
	var outcome: String = "swap_rank_complete"
	match move_kind:
		CombatConstants.FORMATION_MOVE_KIND_DRAG_BACK:
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
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
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
		init.state = CombatConstants.STATE_WAITING
		return
	var f: int = _EntityAccess.file_int(init)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
		CombatDebug.flow_log("fall_back_solo_resolve id=%d aborted: rear slot (1,%d) occupied" % [initiator_id, f])
		init.state = CombatConstants.STATE_WAITING
		_EventScheduler.schedule_action_ready_for_combatant(manager, init)
		return
	_FormationSlots.remove_combatant_from_slots(slots, initiator_id)
	init.rank = 1
	repack_lane_offset_after_rank_file_change(init)
	_FormationSlots.slot_set_single(slots, Vector2i(1, f), initiator_id)
	init.erase("formation_move_partner_id")
	init.state = CombatConstants.STATE_WAITING
	CombatDebug.flow_log("fall_back_solo_resolve id=%d complete rank 0->1 file %d" % [initiator_id, f])
	if _EntityAccess.get_attacking_arm(init).is_empty():
		_F5SoakTrace.note_cowering_fall_back_executed(
			_EntityAccess.get_display_name(init, initiator_id), f
		)
	manager.emit_signal("action_resolved", initiator_id, initiator_id, {"outcome": "fall_back_solo_complete", "dmg": 0, "died": false})
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
	_EventScheduler.schedule_action_ready_for_combatant(manager, init)


static func handle_rotate_file_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var partner_id: int = -1
	var ev_data: Variant = ev.get("data", null)
	if typeof(ev_data) == TYPE_DICTIONARY:
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
	_clear_doctrine_commitments_after_slot_change(init, partner)
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
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
	init.state = CombatConstants.STATE_WAITING
	partner.state = CombatConstants.STATE_WAITING
	CombatDebug.flow_log("rotate_file_resolve id=%d <-> %d complete files %d <-> %d" % [initiator_id, partner_id, f0, f1])
	manager.emit_signal("action_resolved", initiator_id, partner_id, {"outcome": "rotate_file_complete", "dmg": 0, "died": false})
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
	_EventScheduler.schedule_action_ready_for_combatant(manager, init)
	_EventScheduler.schedule_action_ready_for_combatant(manager, partner)

static func on_combatant_died(manager: Node, c: Dictionary) -> void:
	var fid_home: String = _EntityAccess.formation_id_str(c)
	var ctx_geom: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid_geom: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_geom)
	# Intruders may occupy host `slots` while `formation_id` stays home — strip from every formation first.
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
	manager._recompute_zoc_and_distance()
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		manager.mark_all_formations_vacancy_dirty()
	_EntityAccess.manager_notify_formation_changed(manager, fid_geom)
	if fid_home != fid_geom:
		_EntityAccess.manager_notify_formation_changed(manager, fid_home)
	manager._reschedule_back_rank_turns(fid_geom)
	if fid_home != fid_geom:
		manager._reschedule_back_rank_turns(fid_home)


static func _clear_doctrine_commitments_after_slot_change(init: Dictionary, partner: Dictionary) -> void:
	_Doctrine.clear_combatant_doctrine_commitment(init)
	_Doctrine.clear_combatant_doctrine_commitment(partner)
