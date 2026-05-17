class_name CombatFormationFlow
extends RefCounted

## Formation moves, resolve events, slot plug on death, hit reaction delays on pending formation events.
##
## Plug order (see docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md §4): **intrusion slot writes** first (crash success),
## then **vacancy plug** on the home formation (empty rank-0 without death). **Death plug** stays in
## `on_combatant_died` only; same-tick ordering avoids mixing vacancy with death removal.
##
## **Fill vs wedge/posture:** vacancy/death/pair moves are **orthogonal** to `intrusion_wedge_by_file` and engagement posture;
## they only share `lane_offset` repack when rank/file changes. Wedge does not drive who promotes — **slots + rules** do.
##
## **Vacancy reconcile:** `reconcile_vacancy_plugs` (dirty-only when `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY`) or full
## `reconcile_vacancy_plugs_track_changed_fids`; per-file work in `reconcile_vacancy_plugs_formation`. **`finish_vacancy_reconcile_follow_up`**
## applies ZoC, moved-only back-rank `action_ready`, and optional `formation_changed`. `notify_formation_changed` marks dirty then reconciles;
## `get_available_actions` marks all lines then reconciles (full pass); `CombatProcessTick` reconciles dirty formations only.
## **Plug priority (rank-0 hole, after same-column vertical):** **rear infill** from **any** other file (`rear_infill`:
## rank ≥ 1 steps into the empty front slot when the hole column is passable) before **front-rank lateral**
## (same-rank neighbor slide). Cross-file rear uses `prox` = rank depth + |Δfile| so closer reserves win; lateral is last resort.
## Front lateral at rank 0 only when `_rank0_lateral_slide_allowed` (hole column has no promotable native deeper).
## Deeper empty ranks: same-rank lateral from neighbors is allowed so the rear echelon can close gaps without rank-0 shuffling.
## `apply_vacancy_plug_same_file` scans **deepest empty rank first** so a gap under the front is closed from the rear before rank-0 considers lateral.
## Donors are **reserved** for the reconcile pass so the same unit is not assigned to two holes.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")

const _VACANCY_LATERAL_EDGE_META := "_vacancy_lateral_edges"
const _VACANCY_PLUG_RESERVED_DONORS_META := "_vacancy_plug_reserved_donors"


## Tier 1.3 P4: after rank/file changes from plugs or formation moves, keep `lane_offset` bounded (§4.2 repack).
## Intruders keep seam bias; line fighters reset to column center.
static func repack_lane_offset_after_rank_file_change(c: Dictionary) -> void:
	if c.is_empty():
		return
	if _ZoneOfControl.is_intruded(c):
		c["lane_offset"] = clampf(
			CombatConstants.INTRUSION_INTRUDER_LANE_OFFSET_BIAS,
			-CombatConstants.LANE_OFFSET_ABS_MAX,
			CombatConstants.LANE_OFFSET_ABS_MAX
		)
	else:
		c["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT


static func _vacancy_lateral_begin_tracking(manager: Node) -> void:
	manager.set_meta(_VACANCY_LATERAL_EDGE_META, [])
	manager.set_meta(_VACANCY_PLUG_RESERVED_DONORS_META, {})


static func _vacancy_lateral_end_tracking(manager: Node) -> void:
	if manager.has_meta(_VACANCY_LATERAL_EDGE_META):
		manager.remove_meta(_VACANCY_LATERAL_EDGE_META)
	if manager.has_meta(_VACANCY_PLUG_RESERVED_DONORS_META):
		manager.remove_meta(_VACANCY_PLUG_RESERVED_DONORS_META)


static func _vacancy_plug_reserved_donors(manager: Node) -> Dictionary:
	if manager.has_meta(_VACANCY_PLUG_RESERVED_DONORS_META):
		return manager.get_meta(_VACANCY_PLUG_RESERVED_DONORS_META) as Dictionary
	return {}


## True if this unit already slid donor→hole this pass; blocks immediate slide back (stops 0↔1 ping-pong).
static func _vacancy_lateral_is_reverse_blocked(
	manager: Node,
	ally_id: int,
	donor_file: int,
	hole_file: int,
	rk: int
) -> bool:
	if not manager.has_meta(_VACANCY_LATERAL_EDGE_META):
		return false
	var arr: Array = manager.get_meta(_VACANCY_LATERAL_EDGE_META) as Array
	for e in arr:
		if _EntityAccess.id_int(e, -9) != ally_id:
			continue
		if int(e.get("rk", -9)) != rk:
			continue
		if int(e.get("src_f", -9)) == hole_file and int(e.get("dst_f", -9)) == donor_file:
			return true
	return false


## Cross-pass undo guard: reconcile clears pass meta each run; tick + get_available_actions can otherwise alternate lateral fills A→B / B→A every frame.
static func _vacancy_lateral_undo_blocked_persistent(
	manager: Node,
	ally: Dictionary,
	donor_file: int,
	hole_file: int,
	fill_rank: int
) -> bool:
	if manager == null or ally.is_empty():
		return false
	if _EntityAccess.rank_int(ally, -9) != fill_rank:
		return false
	if not ally.has("formation_vacancy_lateral_reverse_lock_until"):
		return false
	var until: float = float(ally.get("formation_vacancy_lateral_reverse_lock_until", -1.0))
	if float(manager.combat_clock) >= until:
		return false
	var last_from: int = int(ally.get("formation_vacancy_lateral_last_from_file", -999))
	var last_to: int = int(ally.get("formation_vacancy_lateral_last_to_file", -999))
	if last_from == -999 or last_to == -999:
		return false
	return hole_file == last_from and donor_file == last_to


static func _vacancy_lateral_record_edge(manager: Node, ally_id: int, src_f: int, dst_f: int, rk: int) -> void:
	var arr: Array = manager.get_meta(_VACANCY_LATERAL_EDGE_META) as Array
	arr.append({"id": ally_id, "src_f": src_f, "dst_f": dst_f, "rk": rk})


static func apply_hit_reaction_if_needed(manager: Node, combatant_id: int, intensity: float = 0.5) -> void:
	var c = manager._get_by_id(combatant_id)
	if c == null or not _EntityAccess.alive_bool(c):
		return
	var st: String = _EntityAccess.state_str(c)
	if st != CombatConstants.STATE_SWAP_RANK and st != CombatConstants.STATE_FALLING_BACK:
		return
	var extra: float = CombatConstants.FORMATION_HIT_REACTION_EXTRA_S * lerpf(0.4, 1.2, clampf(intensity, 0.0, 1.0))
	c.state_duration += extra
	var pid: int = int(c.get("formation_move_partner_id", -1))
	if pid >= 0:
		var p = manager._get_by_id(pid)
		if p != null and _EntityAccess.alive_bool(p):
			var pst: String = _EntityAccess.state_str(p)
			if pst == CombatConstants.STATE_SWAP_RANK or pst == CombatConstants.STATE_FALLING_BACK:
				p.state_duration += extra
	bump_resolve_events(manager, combatant_id, extra)


static func bump_resolve_events(manager: Node, for_combatant_id: int, extra_s: float) -> void:
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
	var init = manager._get_by_id(initiator_id)
	var partner = manager._get_by_id(partner_id)
	if init == null or partner == null or not _EntityAccess.alive_bool(init) or not _EntityAccess.alive_bool(partner):
		return
	if _ZoneOfControl.is_intruded(init):
		return
	if _ZoneOfControl.is_intruded(partner):
		return
	if _EntityAccess.side_str(init) != _EntityAccess.side_str(partner) or _EntityAccess.formation_id_str(init) != _EntityAccess.formation_id_str(partner):
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
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
	var agi: float = float(_EntityAccess.stats_dict(init).get("agility", 100))
	var kind_mult: float = CombatConstants.DRAG_BACK_DURATION_MULT if move_kind == "drag_back" else 1.0
	var armor_mult: float = maxf(
		manager._armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(init)),
		manager._armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(partner))
	)
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_foot * pressure_mod * kind_mult * armor_mult
	var use_falling: bool = move_kind == "drag_back" or move_kind == "fall_back_pair"
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
			"formation_move_start %s (%d) %s with %s (%d) (%.2fs lane×foot×%.2f pressure×%.2f)"
			% [n0, initiator_id, move_kind, n1, partner_id, duration, lane_foot, pressure_mod]
		)
	_EventScheduler.cancel_pending_swap_rank_pair_events(manager, initiator_id, partner_id)
	manager._schedule_event({
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": manager.combat_clock + duration,
		"data": {"partner_id": partner_id, "move_kind": move_kind}
	})


static func start_fall_back_solo(manager: Node, initiator_id: int) -> void:
	var init = manager._get_by_id(initiator_id)
	if init == null or not _EntityAccess.alive_bool(init):
		return
	if _ZoneOfControl.is_intruded(init):
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return
	var ranks: int = formation.get("ranks", 1)
	if ranks <= 1 or _EntityAccess.rank_int(init) != 0:
		return
	var f: int = _EntityAccess.file_int(init)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
		return
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var agi: float = float(_EntityAccess.stats_dict(init).get("agility", 100))
	var armor_mult: float = manager._armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(init))
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_foot * pressure_mod * armor_mult
	init["formation_move_partner_id"] = -1
	init.state = CombatConstants.STATE_FALLING_BACK
	init.state_timer = 0.0
	init.state_duration = duration
	if CombatDebug.flow_verbose_enabled():
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		CombatDebug.flow_log("fall_back_solo_start %s (%d) (%.2fs)" % [n0, initiator_id, duration])
	manager._schedule_event({
		"type": CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": manager.combat_clock + duration,
		"data": {}
	})


static func start_rotate_file(manager: Node, initiator_id: int, partner_id: int) -> void:
	var init = manager._get_by_id(initiator_id)
	var partner = manager._get_by_id(partner_id)
	if init == null or partner == null or not _EntityAccess.alive_bool(init) or not _EntityAccess.alive_bool(partner):
		return
	if _ZoneOfControl.is_intruded(init):
		return
	if _ZoneOfControl.is_intruded(partner):
		return
	if _EntityAccess.side_str(init) != _EntityAccess.side_str(partner) or _EntityAccess.formation_id_str(init) != _EntityAccess.formation_id_str(partner):
		return
	var r_init: int = _EntityAccess.rank_int(init)
	var r_partner: int = _EntityAccess.rank_int(partner)
	if r_init != r_partner:
		return
	var f0: int = _EntityAccess.file_int(init)
	var f1: int = _EntityAccess.file_int(partner)
	if abs(f0 - f1) != 1:
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var agi: float = float(_EntityAccess.stats_dict(init).get("agility", 100))
	var armor_mult: float = maxf(
		manager._armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(init)),
		manager._armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(partner))
	)
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_foot * pressure_mod * armor_mult
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
	manager._schedule_event({
		"type": CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": manager.combat_clock + duration,
		"data": {"partner_id": partner_id}
	})


static func pair_state_ok(c) -> bool:
	return c != null and _EntityAccess.state_str(c) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]


static func abort_pair(manager: Node, init, partner, reason: String = "") -> void:
	var iid: int = _EntityAccess.id_int(init) if init != null else -1
	var pid: int = _EntityAccess.id_int(partner) if partner != null else -1
	var rs: String = (" reason=%s" % reason) if not reason.is_empty() else ""
	CombatDebug.flow_log("formation_pair abort (reset to waiting) initiator_id=%d partner_id=%d%s" % [iid, pid, rs])
	if init != null:
		init.erase("formation_move_partner_id")
	if partner != null:
		partner.erase("formation_move_partner_id")
	if init != null and partner != null:
		var fid: String = _EntityAccess.formation_id_str(init)
		if not fid.is_empty() and _EntityAccess.formation_id_str(init) == _EntityAccess.formation_id_str(partner):
			var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
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
	if init != null and _EntityAccess.alive_bool(init) and pair_state_ok(init):
		init.state = CombatConstants.STATE_WAITING
	if partner != null and _EntityAccess.alive_bool(partner) and pair_state_ok(partner):
		partner.state = CombatConstants.STATE_WAITING
	# Keep a brief local guard after abort so the same pair does not instantly requeue under churn.
	var until: float = float(manager.combat_clock) + 0.7
	if init != null and _EntityAccess.alive_bool(init):
		init["formation_pair_abort_cooldown_until"] = until
	if partner != null and _EntityAccess.alive_bool(partner):
		partner["formation_pair_abort_cooldown_until"] = until


static func handle_swap_rank_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var data_raw: Variant = ev.get("data", null)
	var data: Dictionary = data_raw if data_raw is Dictionary else {}
	var partner_id: int = data.get("partner_id", -1)
	var move_kind: String = data.get("move_kind", "swap_rank")
	var init = manager._get_by_id(initiator_id)
	var partner = manager._get_by_id(partner_id)
	if init == null:
		if partner != null and pair_state_ok(partner):
			partner.state = CombatConstants.STATE_WAITING
		return
	if partner == null:
		if pair_state_ok(init):
			init.state = CombatConstants.STATE_WAITING
		return
	if not _EntityAccess.alive_bool(init) or not _EntityAccess.alive_bool(partner):
		abort_pair(manager, init, partner, "swap_rank_resolve_not_alive")
		if init != null and _EntityAccess.alive_bool(init):
			manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		if partner != null and _EntityAccess.alive_bool(partner):
			manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))
		return
	if not pair_state_ok(init) or not pair_state_ok(partner):
		var si: String = _EntityAccess.state_str(init) if init != null else "null"
		var sp: String = _EntityAccess.state_str(partner) if partner != null else "null"
		abort_pair(manager, init, partner, "swap_rank_resolve_pair_state init=%s partner=%s" % [si, sp])
		if init != null and _EntityAccess.alive_bool(init):
			manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		if partner != null and _EntityAccess.alive_bool(partner):
			manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
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
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
	# Mirror CombatConstants rotate anti-thrash window; keep literal fallback to avoid stale analyzer symbol caches.
	var rotate_cd_until: float = float(manager.combat_clock) + 0.8
	init["formation_rotate_file_cooldown_until"] = rotate_cd_until
	partner["formation_rotate_file_cooldown_until"] = rotate_cd_until
	init.state = CombatConstants.STATE_WAITING
	partner.state = CombatConstants.STATE_WAITING
	var outcome: String = "swap_rank_complete"
	match move_kind:
		"drag_back":
			outcome = "drag_back_complete"
		"fall_back_pair":
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
	manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
	if partner != null and _EntityAccess.alive_bool(partner) and not _EntityAccess.is_incapacitated(partner):
		manager._schedule_action_ready(partner_id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


static func handle_fall_back_solo_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var init = manager._get_by_id(initiator_id)
	if init == null or not _EntityAccess.alive_bool(init):
		return
	if _EntityAccess.state_str(init) != CombatConstants.STATE_FALLING_BACK:
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		init.state = CombatConstants.STATE_WAITING
		return
	var f: int = _EntityAccess.file_int(init)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
		CombatDebug.flow_log("fall_back_solo_resolve id=%d aborted: rear slot (1,%d) occupied" % [initiator_id, f])
		init.state = CombatConstants.STATE_WAITING
		manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		return
	_FormationSlots.remove_combatant_from_slots(slots, initiator_id)
	init.rank = 1
	repack_lane_offset_after_rank_file_change(init)
	_FormationSlots.slot_set_single(slots, Vector2i(1, f), initiator_id)
	init.erase("formation_move_partner_id")
	init.state = CombatConstants.STATE_WAITING
	CombatDebug.flow_log("fall_back_solo_resolve id=%d complete rank 0->1 file %d" % [initiator_id, f])
	manager.emit_signal("action_resolved", initiator_id, initiator_id, {"outcome": "fall_back_solo_complete", "dmg": 0, "died": false})
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
	manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))


static func handle_rotate_file_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var partner_id: int = -1
	var ev_data: Variant = ev.get("data", null)
	if typeof(ev_data) == TYPE_DICTIONARY:
		partner_id = int((ev_data as Dictionary).get("partner_id", -1))
	var init = manager._get_by_id(initiator_id)
	var partner = manager._get_by_id(partner_id)
	if init == null or partner == null or not _EntityAccess.alive_bool(init) or not _EntityAccess.alive_bool(partner):
		abort_pair(manager, init, partner, "rotate_file_resolve_null_or_dead")
		return
	if not pair_state_ok(init) or not pair_state_ok(partner):
		var si2: String = _EntityAccess.state_str(init) if init != null else "null"
		var sp2: String = _EntityAccess.state_str(partner) if partner != null else "null"
		abort_pair(manager, init, partner, "rotate_file_resolve_pair_state init=%s partner=%s" % [si2, sp2])
		if init != null and _EntityAccess.alive_bool(init):
			manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		if partner != null and _EntityAccess.alive_bool(partner):
			manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))
		return
	var fid: String = _EntityAccess.formation_id_str(init)
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
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
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
	init.state = CombatConstants.STATE_WAITING
	partner.state = CombatConstants.STATE_WAITING
	CombatDebug.flow_log("rotate_file_resolve id=%d <-> %d complete files %d <-> %d" % [initiator_id, partner_id, f0, f1])
	manager.emit_signal("action_resolved", initiator_id, partner_id, {"outcome": "rotate_file_complete", "dmg": 0, "died": false})
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
	manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
	manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))


## After crash success: clear intruder from home `slots`, place in host anchor **column** at first free rank ≥ 1 (behind their line), align rank/file, vacancy plug home column.
static func apply_intrusion_after_crash_success(
	manager: Node,
	atk: Dictionary,
	_defender_id: int,
	defender_formation_id: String,
	defender_file: int,
	breach_severity: float = -1.0
) -> void:
	if manager == null or atk.is_empty():
		return
	var fid_a: String = _EntityAccess.formation_id_str(atk)
	if fid_a.is_empty() or defender_formation_id.is_empty():
		return
	var form_a: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid_a)
	var form_b: Dictionary = _FormationSlots.formation_record_read(manager.formations, defender_formation_id)
	if form_a.is_empty() or form_b.is_empty():
		return
	var aid: int = _EntityAccess.id_int(atk)
	if aid < 0:
		return
	var stored_home: int = int(atk.get("intrusion_source_file", -1))
	var first_intrusion: bool = stored_home < 0
	var home_vacancy_file: int = _EntityAccess.file_int(atk) if first_intrusion else stored_home
	for fk in manager.formations.keys():
		var raw_fd_strip: Variant = manager.formations.get(fk, null)
		if raw_fd_strip == null or not (raw_fd_strip is Dictionary):
			continue
		var fd: Dictionary = raw_fd_strip as Dictionary
		if fd.is_empty():
			continue
		_FormationSlots.remove_combatant_from_slots(_FormationSlots.formation_slots_dict(fd), aid)
	var slots_b: Dictionary = _FormationSlots.formation_slots_dict(form_b)
	var host_ranks: int = maxi(1, int(form_b.get("ranks", 1)))
	var placed_rank: int = _FormationSlots.place_intruder_behind_front_line(manager, slots_b, host_ranks, defender_file, aid)
	atk["rank"] = placed_rank
	atk["file"] = defender_file
	var sev_use: float = breach_severity
	if sev_use < 0.0:
		var bf0: Dictionary = _FormationSlots.formation_nested_dictionary_read(form_b, "breached_files")
		sev_use = _FormationBreachRules.breached_file_severity(bf0, defender_file, 0.7)
	_IntrusionWedge.upsert_from_intrusion(
		form_b,
		defender_file,
		aid,
		sev_use,
		_EntityAccess.tactical_penetration_depth_int(atk),
		CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX
	)
	repack_lane_offset_after_rank_file_change(atk)
	_nudge_anchor_rank0_lane_offset_for_intrusion(manager, defender_formation_id, defender_file, aid)
	if first_intrusion:
		atk["intrusion_source_file"] = home_vacancy_file
		apply_vacancy_plug_same_file(manager, fid_a, home_vacancy_file)
	manager._reschedule_back_rank_turns(fid_a)
	manager._reschedule_back_rank_turns(defender_formation_id)


## §4.2: nudge anchor rank-0 defender on host file slightly opposite intruder seam bias (anti-overlap).
static func _nudge_anchor_rank0_lane_offset_for_intrusion(
	manager: Node,
	defender_formation_id: String,
	anchor_file: int,
	intruder_id: int
) -> void:
	if manager == null or not manager.has_method("_get_by_id"):
		return
	var form_b: Dictionary = _FormationSlots.formation_record_read(manager.formations, defender_formation_id)
	if form_b.is_empty():
		return
	var slots_b: Dictionary = _FormationSlots.formation_slots_dict(form_b)
	var occ: Array = _FormationSlots.normalize_cell(slots_b.get(Vector2i(0, anchor_file), []))
	for did in occ:
		var cid: int = int(did)
		if cid == intruder_id:
			continue
		var defc: Variant = manager._get_by_id(cid)
		if defc == null or not _EntityAccess.alive_bool(defc as Dictionary):
			continue
		var d: Dictionary = defc as Dictionary
		if _ZoneOfControl.is_intruded(d):
			continue
		if _EntityAccess.rank_int(d) != 0:
			continue
		if _EntityAccess.formation_id_str(d) != defender_formation_id:
			continue
		var cur: float = float(d.get("lane_offset", 0.0))
		d["lane_offset"] = clampf(
			cur - CombatConstants.INTRUSION_ANCHOR_LANE_OFFSET_NUDGE,
			-CombatConstants.LANE_OFFSET_ABS_MAX,
			CombatConstants.LANE_OFFSET_ABS_MAX
		)
		break


static func _formation_has_rank0_hole(manager: Node, fid: String) -> bool:
	if manager == null:
		return false
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var nfiles: int = maxi(1, int(formation.get("files", 1)))
	for file in range(nfiles):
		if not _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
			return true
	return false


## True when this formation currently has at least one legal plug move into rank 0.
## Frontline-first policy: if true, keep line closure ahead of non-essential movement choices.
static func formation_has_frontline_fill_opportunity(manager: Node, fid: String) -> bool:
	if manager == null:
		return false
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return false
	var formation_ranks: int = int(formation.get("ranks", 1))
	if formation_ranks <= 1:
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var nfiles: int = maxi(1, int(formation.get("files", 1)))
	var side_wanted: String = _FormationSlots.formation_side_str(formation)
	for file in range(nfiles):
		if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
			continue
		var reserved: Dictionary = {}
		var move: Dictionary = _select_best_plug_move_for_empty_cell(
			manager, fid, slots, 0, file, formation_ranks, nfiles, side_wanted, true, reserved, true, true
		)
		if not move.is_empty():
			return true
	return false


## Same as **`formation_has_frontline_fill_opportunity`**, but only for one **file** column (solo **`fall_back`** uses this so an empty front cell in another lane does not block retreat).
static func formation_has_frontline_fill_opportunity_at_file(
	manager: Node, fid: String, file: int
) -> bool:
	if manager == null or file < 0:
		return false
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return false
	var formation_ranks: int = int(formation.get("ranks", 1))
	if formation_ranks <= 1:
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var nfiles: int = maxi(1, int(formation.get("files", 1)))
	if file >= nfiles:
		return false
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
		return false
	var side_wanted: String = _FormationSlots.formation_side_str(formation)
	var reserved: Dictionary = {}
	var move: Dictionary = _select_best_plug_move_for_empty_cell(
		manager, fid, slots, 0, file, formation_ranks, nfiles, side_wanted, true, reserved, true, true
	)
	return not move.is_empty()


## Busy combatants must not be picked as vacancy donors (would fight slot state during swaps / wind-up).
## Units just moved by automatic plug also sit out briefly so reconcile ticks cannot ping-pong them as donors.
static func _is_ineligible_vacancy_donor(manager: Node, c: Dictionary) -> bool:
	var st: String = _EntityAccess.state_str(c)
	if st in [
		CombatConstants.STATE_SWAP_RANK,
		CombatConstants.STATE_FALLING_BACK,
		CombatConstants.STATE_WIND_UP,
		CombatConstants.STATE_RECOVERING,
		CombatConstants.STATE_MEDICAL_WIND_UP,
		CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
		CombatConstants.STATE_COWERING,
	]:
		return true
	var until: float = float(c.get("formation_autofill_cooldown_until", -1.0))
	if until >= 0.0 and manager != null:
		var clk: float = float(manager.combat_clock)
		# Hard lock: never allow two automatic plug donations in the same simulation clock,
		# even when frontline-first override is active.
		var last_move_clk: float = float(c.get("formation_autofill_last_move_clock", -9999.0))
		if absf(last_move_clk - clk) < 0.0001:
			return true
		if clk < until:
			var fid_geom: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
			# Frontline-first override: if rank 0 has holes, let reserves donate even during autofill cooldown.
			if not _formation_has_rank0_hole(manager, fid_geom):
				return true
	return false


## First living non-intruded occupant in `slots` at `key` for this formation side (dual cells: try each id; skip busy donors).
static func _combatant_from_slot_primary_living(
	manager: Node,
	slots: Dictionary,
	key: Vector2i,
	fid: String,
	side_wanted: String,
	skip_intruded: bool
) -> Variant:
	var arr: Array = _FormationSlots.normalize_cell(slots.get(key, []))
	for cid in arr:
		var ally = manager._get_by_id(int(cid)) if manager.has_method("_get_by_id") else null
		if ally == null or not _EntityAccess.alive_bool(ally):
			continue
		if _EntityAccess.side_str(ally) != side_wanted:
			continue
		if _ZoneOfControl.formation_id_for_zone_geometry(manager, ally) != fid:
			continue
		if skip_intruded and _ZoneOfControl.is_intruded(ally):
			continue
		if _is_ineligible_vacancy_donor(manager, ally):
			continue
		return ally
	return null


## Higher = fitter to hold the line (performance, legs, blood). Incapacitated fighters score very low.
static func _plug_effectiveness_score(manager: Node, c: Dictionary) -> float:
	if _EntityAccess.is_incapacitated(c):
		return -100.0
	var perf: float = clampf(_EntityAccess.get_performance_modifier(c), 0.0, 2.0)
	var leg: float = clampf(_EntityAccess.get_leg_functionality(c), 0.0, 1.0)
	if is_nan(perf) or is_inf(perf):
		perf = 1.0
	if is_nan(leg) or is_inf(leg):
		leg = 1.0
	var blood_f: float = 1.0
	var ent: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if ent != null:
		blood_f = clampf(_EntityAccess.get_blood_volume_from_node(ent) / 100.0, 0.0, 1.0)
	if is_nan(blood_f) or is_inf(blood_f):
		blood_f = 1.0
	return perf * 0.45 + leg * 0.35 + blood_f * 0.2


## 0 = unfit to plug, 1 = peak readiness (for nonlinear curve).
static func _plug_effectiveness_normalized_0_1(manager: Node, c: Dictionary) -> float:
	var raw: float = _plug_effectiveness_score(manager, c)
	if raw <= -50.0:
		return 0.0
	return clampf(raw / 1.5, 0.0, 1.0)


## Single score: nonlinear penalty on low effectiveness can override raw proximity when fit allies exist elsewhere.
## `fill_rank`: when 0 (front row hole), adds urgency so the line closes before lateral shuffles when scores are close.
static func _plug_priority_score(manager: Node, prox_steps: int, c: Dictionary, fill_rank: int = -1) -> float:
	var eff_n: float = _plug_effectiveness_normalized_0_1(manager, c)
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
## When `adjacent_rank_only`, walk ranks shallow→deep: skip empty ranks; **skip** ranks whose primary native
## is not a legal donor (wind-up, reserved elsewhere, intruder-only cell, etc.) and keep scanning so a deeper
## reserve can still plug the hole without forcing a front-rank lateral shuffle. Stop at the first **eligible,
## unreserved** donor (closest promotable native — do not jump over them to pull someone even deeper).
## When false, scan the full column and keep the best-scoring eligible donor (full-column donor scan).
static func _evaluate_best_vertical_plug_for_cell(
	manager: Node,
	fid: String,
	slots: Dictionary,
	fill_rank: int,
	file: int,
	formation_ranks: int,
	side_wanted: String,
	skip_intruded: bool,
	reserved: Dictionary,
	adjacent_rank_only: bool = true
) -> Dictionary:
	var best: Dictionary = {}
	var best_pri: float = -1.0
	const rank_tie_eps: float = 1e-4
	if adjacent_rank_only:
		var search_rank: int = fill_rank + 1
		while search_rank < formation_ranks:
			if not _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(search_rank, file)):
				search_rank += 1
				continue
			var ally_v: Variant = _combatant_from_slot_primary_living(
				manager, slots, Vector2i(search_rank, file), fid, side_wanted, skip_intruded
			)
			if ally_v == null:
				search_rank += 1
				continue
			var aid: int = _EntityAccess.id_int(ally_v)
			if reserved.get(aid, false):
				search_rank += 1
				continue
			var prox: int = search_rank - fill_rank
			var pri: float = _plug_priority_score(manager, prox, ally_v, fill_rank)
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
		var ally_v2: Variant = _combatant_from_slot_primary_living(
			manager, slots, Vector2i(search_rank, file), fid, side_wanted, skip_intruded
		)
		if ally_v2 == null:
			continue
		var aid2: int = _EntityAccess.id_int(ally_v2)
		if reserved.get(aid2, false):
			continue
		var prox2: int = search_rank - fill_rank
		var pri2: float = _plug_priority_score(manager, prox2, ally_v2, fill_rank)
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


## True when ranks `1 .. search_rank-1` in the hole file have no **promotable** occupant (same filters as vertical donors).
## Lets a reserve in an adjacent file step into a rank-0 hole when the same column cannot promote (or first deeper is busy)
## without treating a wind-up ally in-column as a hard blocker for rear infill.
static func _rear_infill_hole_column_passable(
	manager: Node,
	fid: String,
	slots: Dictionary,
	hole_file: int,
	search_rank: int,
	side_wanted: String,
	skip_intruded: bool
) -> bool:
	for rr in range(1, search_rank):
		if not _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(rr, hole_file)):
			continue
		if (
			_combatant_from_slot_primary_living(
				manager, slots, Vector2i(rr, hole_file), fid, side_wanted, skip_intruded
			)
			!= null
		):
			return false
	return true


## Rank-0 hole only: best **rear** donor on **any other** file (rank ≥ 1) who can occupy the front slot in one plug.
## Deeper ranks preferred as donors first (then shallower); ties prefer smaller |file − hole| then lower file index.
## Proximity for scoring includes file distance so farther sidesteps lose to nearer fit reserves before front-rank lateral.
static func _evaluate_best_rear_infill_for_rank0_hole(
	manager: Node,
	fid: String,
	slots: Dictionary,
	hole_file: int,
	nfiles: int,
	formation_ranks: int,
	side_wanted: String,
	skip_intruded: bool,
	reserved: Dictionary
) -> Dictionary:
	var best: Dictionary = {}
	var best_pri: float = -1.0
	const rank_tie_eps: float = 1e-4
	for nf in range(nfiles):
		if nf == hole_file:
			continue
		for search_rank in range(formation_ranks - 1, 0, -1):
			if not _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(search_rank, nf)):
				continue
			var ally_r: Variant = _combatant_from_slot_primary_living(
				manager, slots, Vector2i(search_rank, nf), fid, side_wanted, skip_intruded
			)
			if ally_r == null:
				continue
			var aid: int = _EntityAccess.id_int(ally_r)
			if reserved.get(aid, false):
				continue
			if not _rear_infill_hole_column_passable(
				manager, fid, slots, hole_file, search_rank, side_wanted, skip_intruded
			):
				continue
			if _vacancy_lateral_is_reverse_blocked(manager, aid, nf, hole_file, 0):
				continue
			var file_dist: int = abs(nf - hole_file)
			var prox: int = search_rank + file_dist
			var pri: float = _plug_priority_score(manager, prox, ally_r, 0)
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
					elif file_dist == best_fd and nf == best_nf and aid < _EntityAccess.id_int(_EntityAccess.nested_dictionary_read(best, "ally"), 999999):
						best = cand
						best_pri = pri
	return best


## Best **front-rank** lateral option for this hole (same rank, adjacent files only). Evaluated after vertical and rear infill.
static func _evaluate_best_lateral_plug_for_cell(
	manager: Node,
	fid: String,
	slots: Dictionary,
	fill_rank: int,
	file: int,
	nfiles: int,
	formation_ranks: int,
	side_wanted: String,
	skip_intruded: bool,
	reserved: Dictionary
) -> Dictionary:
	var best: Dictionary = {}
	var best_pri: float = -1.0
	const file_tie_eps: float = 1e-4
	for dfile in [-1, 1]:
		var nf: int = file + dfile
		if nf < 0 or nf >= nfiles:
			continue
		if not _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(fill_rank, nf)):
			continue
		var ally_l: Variant = _combatant_from_slot_primary_living(
			manager, slots, Vector2i(fill_rank, nf), fid, side_wanted, skip_intruded
		)
		if ally_l == null:
			continue
		var aid: int = _EntityAccess.id_int(ally_l)
		if reserved.get(aid, false):
			continue
		if _vacancy_lateral_is_reverse_blocked(manager, aid, nf, file, fill_rank):
			continue
		if _vacancy_lateral_undo_blocked_persistent(manager, ally_l, nf, file, fill_rank):
			continue
		if fill_rank == 0 and not _rank0_lateral_slide_allowed(
			manager, slots, file, nf, formation_ranks, fid, side_wanted, skip_intruded
		):
			continue
		var pri: float = _plug_priority_score(manager, 1, ally_l, fill_rank)
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
static func _select_best_plug_move_for_empty_cell(
	manager: Node,
	fid: String,
	slots: Dictionary,
	fill_rank: int,
	file: int,
	formation_ranks: int,
	nfiles: int,
	side_wanted: String,
	skip_intruded: bool,
	reserved: Dictionary,
	adjacent_vertical_only: bool = true,
	allow_lateral: bool = true
) -> Dictionary:
	var vert: Dictionary = _evaluate_best_vertical_plug_for_cell(
		manager,
		fid,
		slots,
		fill_rank,
		file,
		formation_ranks,
		side_wanted,
		skip_intruded,
		reserved,
		adjacent_vertical_only
	)
	if not vert.is_empty():
		return _plug_move_for_apply(vert)
	if allow_lateral:
		if fill_rank == 0 and formation_ranks > 1:
			var rear: Dictionary = _evaluate_best_rear_infill_for_rank0_hole(
				manager,
				fid,
				slots,
				file,
				nfiles,
				formation_ranks,
				side_wanted,
				skip_intruded,
				reserved
			)
			if not rear.is_empty():
				return _plug_move_for_apply(rear)
		var lat: Dictionary = _evaluate_best_lateral_plug_for_cell(
			manager,
			fid,
			slots,
			fill_rank,
			file,
			nfiles,
			formation_ranks,
			side_wanted,
			skip_intruded,
			reserved
		)
		if not lat.is_empty():
			return _plug_move_for_apply(lat)
	return {}


static func _apply_plug_move(
	manager: Node,
	slots: Dictionary,
	move: Dictionary,
	fill_rank: int,
	file: int,
	log_prefix: String
) -> void:
	var ally: Dictionary = move["ally"]
	var kind: String = str(move.get("kind", "vertical"))
	var from_f: int = int(move.get("from_file", 0))
	_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(ally))
	ally.rank = fill_rank
	ally.file = file
	repack_lane_offset_after_rank_file_change(ally)
	_FormationSlots.slot_set_single(slots, Vector2i(fill_rank, file), _EntityAccess.id_int(ally))
	ally["formation_autofill_cooldown_until"] = (
		float(manager.combat_clock) + CombatConstants.FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S
	)
	ally["formation_autofill_last_move_clock"] = float(manager.combat_clock)
	if kind == "lateral" or kind == "rear_infill":
		ally["formation_vacancy_lateral_last_from_file"] = from_f
		ally["formation_vacancy_lateral_last_to_file"] = file
		ally["formation_vacancy_lateral_reverse_lock_until"] = (
			float(manager.combat_clock) + CombatConstants.FORMATION_VACANCY_LATERAL_REVERSE_LOCK_S
		)
		if manager.has_meta(_VACANCY_LATERAL_EDGE_META):
			_vacancy_lateral_record_edge(manager, _EntityAccess.id_int(ally), from_f, file, fill_rank)
	else:
		ally.erase("formation_vacancy_lateral_last_from_file")
		ally.erase("formation_vacancy_lateral_last_to_file")
		ally.erase("formation_vacancy_lateral_reverse_lock_until")
	if CombatConstants.COMBAT_FORMATION_PLUG_MOVE_DEBUG:
		var name_p: String = _EntityAccess.get_display_name(ally, _EntityAccess.id_int(ally))
		if kind == "lateral":
			print(
				"[Combat] %s: %s slid file %d → %d (rank %d)" % [log_prefix, name_p, from_f, file, fill_rank]
			)
		elif kind == "rear_infill":
			print(
				(
					"[Combat] %s: %s rear infill rank %d file %d → rank %d file %d"
					% [log_prefix, name_p, int(move.get("from_rank", 0)), from_f, fill_rank, file]
				)
			)
		else:
			print("[Combat] %s: %s advanced to rank %d (file %d)" % [log_prefix, name_p, fill_rank, file])
	elif CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG and str(log_prefix).begins_with("Vacancy"):
		var name_v: String = _EntityAccess.get_display_name(ally, _EntityAccess.id_int(ally))
		CombatDebug.formation_vacancy_log("%s: %s → rank %d file %d (%s)" % [log_prefix, name_v, fill_rank, file, kind])
	if manager.has_meta(_VACANCY_PLUG_RESERVED_DONORS_META):
		var rd: Dictionary = manager.get_meta(_VACANCY_PLUG_RESERVED_DONORS_META) as Dictionary
		rd[_EntityAccess.id_int(ally)] = true
	var ready_delay: float = CombatConstants.READY_DELAY_AFTER_PROMOTION_S
	if kind == "rear_infill":
		var fdist: int = abs(int(from_f) - int(file))
		ready_delay += float(fdist) * CombatConstants.FORMATION_PLUG_REAR_CROSS_FILE_READY_PER_FILE_S
	manager._schedule_action_ready(_EntityAccess.id_int(ally), ready_delay)


## True when this file has a living occupant strictly deeper than `rank_i`.
## Vacancy reconcile should not force-fill optional rear depth (e.g. lone reserve bouncing between files).
static func _has_living_deeper_in_file(
	manager: Node, slots: Dictionary, rank_i: int, file: int, formation_ranks: int
) -> bool:
	for rr in range(rank_i + 1, formation_ranks):
		if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(rr, file)):
			return true
	return false


## True if any rank below `rank_i` has a **vacancy vertical-style** donor (same filters as `_combatant_from_slot_primary_living`).
## Avoids treating intruders-only (or other skipped slot ids) as "depth" that blocks rank-0 lateral while vertical finds nobody.
static func _has_promotable_deeper_in_file(
	manager: Node,
	slots: Dictionary,
	rank_i: int,
	file: int,
	formation_ranks: int,
	fid: String,
	side_wanted: String,
	skip_intruded: bool
) -> bool:
	for rr in range(rank_i + 1, formation_ranks):
		if _combatant_from_slot_primary_living(manager, slots, Vector2i(rr, file), fid, side_wanted, skip_intruded) != null:
			return true
	return false


## True when the formation has at least one eligible non-intruded donor in ranks >= 1.
## Used to avoid rank-0 lateral "hole chasing" when the line has no reserves at all.
static func _formation_has_any_promotable_rear_donor(
	manager: Node,
	slots: Dictionary,
	formation_ranks: int,
	nfiles: int,
	fid: String,
	side_wanted: String,
	skip_intruded: bool
) -> bool:
	if manager == null or formation_ranks <= 1:
		return false
	for rr in range(1, formation_ranks):
		for ff in range(nfiles):
			if (
				_combatant_from_slot_primary_living(
					manager, slots, Vector2i(rr, ff), fid, side_wanted, skip_intruded
				)
				!= null
			):
				return true
	return false


## Rank-0 lateral: only when the **hole** column cannot pull a reserve up (no promotable native deeper).
## If this column has anyone who can vertical-plug (possibly after skipping empty ranks), do not slide a
## neighbor's front sideways — that read as "shuffling files" instead of filling from behind.
## `donor_file` kept for call-site stability; intrusion nuance may use it later.
static func _rank0_lateral_slide_allowed(
	manager: Node,
	slots: Dictionary,
	hole_file: int,
	_donor_file: int,
	formation_ranks: int,
	fid: String,
	side_wanted: String,
	skip_intruded: bool
) -> bool:
	if manager == null or formation_ranks <= 1:
		return false
	var nfiles: int = 0
	for k in slots.keys():
		if k is Vector2i:
			nfiles = maxi(nfiles, int((k as Vector2i).y) + 1)
	if nfiles <= 0:
		nfiles = 1
	if not _formation_has_any_promotable_rear_donor(
		manager, slots, formation_ranks, nfiles, fid, side_wanted, skip_intruded
	):
		return false
	if _has_promotable_deeper_in_file(
		manager, slots, 0, hole_file, formation_ranks, fid, side_wanted, skip_intruded
	):
		return false
	return true


## Promote / slide into empty cells (no death, no slot_obstacles). Caller runs ZoC/distance if needed.
## Priority = `pow(effectiveness01, EXP) / (1 + W*proximity_steps)` so heavy injury nonlinearly defers plugging when fitter allies exist in other ranks or files.
## Returns true if any combatant moved.
static func apply_vacancy_plug_same_file(manager: Node, fid: String, file: int) -> bool:
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return false
	var formation_ranks: int = formation.get("ranks", 1)
	if formation_ranks <= 1:
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var side_wanted: String = _FormationSlots.formation_side_str(formation)
	var nfiles: int = int(formation.get("files", 1))
	var any_promoted: bool = false
	var micro_max: int = CombatConstants.FORMATION_VACANCY_MICRO_STEPS_MAX
	for _micro in range(micro_max):
		var moved_step: bool = false
		# Deepest empty rank first so rank-1.. gaps are closed from the rear before rank-0 (avoids lateral into the front while the same file still has depth below).
		for fill_rank in range(formation_ranks - 1, -1, -1):
			if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(fill_rank, file)):
				continue
			# Rank 0 is always meaningful (front line). Deeper ranks are only meaningful when
			# someone exists behind them in the same file; otherwise the empty cell is valid reserve space.
			if fill_rank > 0 and not _has_living_deeper_in_file(
				manager, slots, fill_rank, file, formation_ranks
			):
				continue
			var reserved: Dictionary = _vacancy_plug_reserved_donors(manager)
			var allow_lateral: bool = true
			var move: Dictionary = _select_best_plug_move_for_empty_cell(
				manager,
				fid,
				slots,
				fill_rank,
				file,
				formation_ranks,
				nfiles,
				side_wanted,
				true,
				reserved,
				true,
				allow_lateral
			)
			if move.is_empty():
				continue
			_apply_plug_move(manager, slots, move, fill_rank, file, "Vacancy plug")
			any_promoted = true
			moved_step = true
			break
		if not moved_step:
			break
	return any_promoted


## Skirmish: pack natives to contiguous files so stragglers are addressable.
## Formation mode: usually avoid compaction (vacancy plugs handle true holes), but when there are **no rear
## donors anywhere** and rank-0 has gaps, run deterministic compaction so the line closes once and holds
## (prevents lateral hole chasing A<->B while still keeping frontage contiguous).
static func _should_compact_native_line_files(manager: Node, fid: String) -> bool:
	if manager == null:
		return false
	if str(_EngagementMode.engagement_mode(manager)) == str(CombatConstants.ENGAGEMENT_MODE_FORMATION):
		var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
		if formation.is_empty():
			return false
		if not _formation_has_rank0_hole(manager, fid):
			return false
		var formation_ranks: int = maxi(1, int(formation.get("ranks", 1)))
		if formation_ranks <= 1:
			return true
		var nfiles: int = maxi(1, int(formation.get("files", 1)))
		var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
		var side_wanted: String = _FormationSlots.formation_side_str(formation)
		return not _formation_has_any_promotable_rear_donor(
			manager, slots, formation_ranks, nfiles, fid, side_wanted, true
		)
	return true


static func _formation_has_blocking_formation_motion_for_compact(manager: Node, fid: String) -> bool:
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _ZoneOfControl.formation_id_for_zone_geometry(manager, c) != fid:
			continue
		var st: String = _EntityAccess.state_str(c)
		if st == CombatConstants.STATE_SWAP_RANK or st == CombatConstants.STATE_FALLING_BACK:
			return true
	return false


## After removing `native_id` from all cells, write it at `key` while preserving intruders / foreign-formation ids in that cell.
static func _slot_place_native_merging_intruders(
	manager: Node,
	slots: Dictionary,
	fid: String,
	rank: int,
	file_col: int,
	native_id: int
) -> void:
	var nat = manager._get_by_id(native_id) if manager.has_method("_get_by_id") else null
	if nat == null or not _EntityAccess.alive_bool(nat):
		return
	var key := Vector2i(rank, file_col)
	_FormationSlots.remove_combatant_from_slots(slots, native_id)
	var merged: Array = []
	var cur: Array = _FormationSlots.normalize_cell(slots.get(key, []))
	for cid in cur:
		var oc = manager._get_by_id(int(cid)) if manager.has_method("_get_by_id") else null
		if oc == null or not _EntityAccess.alive_bool(oc):
			continue
		if _EntityAccess.formation_id_str(oc) != fid or _ZoneOfControl.is_intruded(oc):
			merged.append(int(cid))
	if not merged.has(native_id):
		merged.append(native_id)
	slots[key] = merged
	nat["rank"] = rank
	nat["file"] = file_col
	repack_lane_offset_after_rank_file_change(nat)
	nat["formation_autofill_cooldown_until"] = (
		float(manager.combat_clock) + CombatConstants.FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S
	)
	nat["formation_autofill_last_move_clock"] = float(manager.combat_clock)
	nat.erase("formation_vacancy_lateral_last_from_file")
	nat.erase("formation_vacancy_lateral_last_to_file")
	nat.erase("formation_vacancy_lateral_reverse_lock_until")
	manager._schedule_action_ready(native_id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


## Pack non-intruded `formation_id` natives to files `0..n-1` per rank (stable sort by current file, then id).
## Returns true if any combatant moved or slots were repaired.
static func compact_native_line_files_if_thinned(manager: Node, fid: String) -> bool:
	if manager == null or not _should_compact_native_line_files(manager, fid):
		return false
	if _formation_has_blocking_formation_motion_for_compact(manager, fid):
		return false
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var side_wanted: String = _FormationSlots.formation_side_str(formation)
	var formation_ranks: int = maxi(1, int(formation.get("ranks", 1)))
	var any: bool = false
	for rank in range(formation_ranks):
		var natives: Array = []
		for c in manager.combatants:
			if not _EntityAccess.alive_bool(c):
				continue
			if _EntityAccess.formation_id_str(c) != fid:
				continue
			if _EntityAccess.side_str(c) != side_wanted:
				continue
			if _ZoneOfControl.is_intruded(c):
				continue
			if _EntityAccess.rank_int(c) != rank:
				continue
			natives.append(c)
		if natives.is_empty():
			continue
		natives.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				var af: int = _EntityAccess.file_int(a)
				var bf: int = _EntityAccess.file_int(b)
				if af != bf:
					return af < bf
				return _EntityAccess.id_int(a, 0) < _EntityAccess.id_int(b, 0)
		)
		var i: int = 0
		for nat in natives:
			var nid: int = _EntityAccess.id_int(nat)
			var new_f: int = i
			i += 1
			var key := Vector2i(rank, new_f)
			var need: bool = _EntityAccess.file_int(nat) != new_f
			if not need:
				var occ: Array = _FormationSlots.normalize_cell(slots.get(key, []))
				need = not occ.has(nid)
			if not need:
				continue
			_slot_place_native_merging_intruders(manager, slots, fid, rank, new_f, nid)
			any = true
	return any


## When `COMBAT_FORMATION_VACANCY_DEBUG`, log rank-0 holes that still have no living slot occupant while an eligible deeper ally exists.
static func _log_rank0_vacancy_gaps_if_debug(manager: Node, fid: String) -> void:
	if not CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG:
		return
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return
	var formation_ranks: int = int(formation.get("ranks", 1))
	if formation_ranks <= 1:
		return
	var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
	var nfiles: int = int(formation.get("files", 1))
	var side_wanted: String = _FormationSlots.formation_side_str(formation)
	for file in range(nfiles):
		if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
			continue
		for ally in manager.combatants:
			if not _EntityAccess.alive_bool(ally):
				continue
			if _EntityAccess.side_str(ally) != side_wanted:
				continue
			if _EntityAccess.formation_id_str(ally) != fid:
				continue
			if _ZoneOfControl.is_intruded(ally):
				continue
			if _EntityAccess.file_int(ally) != file or _EntityAccess.rank_int(ally) < 1:
				continue
			if _is_ineligible_vacancy_donor(manager, ally):
				continue
			CombatDebug.formation_vacancy_log(
				"rank0 gap fid=%s file=%d donor id=%d state=%s rank=%d (slots out of sync or plug blocked)"
				% [fid, file, _EntityAccess.id_int(ally), _EntityAccess.state_str(ally), _EntityAccess.rank_int(ally)]
			)
			break


## Run vacancy plug on every file column so empty front cells do not persist while deeper ranks are alive (avoids soft deadlock: no enemy rank 0 while enemies remain).
## Repeats rounds so lateral slides that open a gap in a neighbor file get a chance to fill.
## Each round processes **files with an empty rank 0 first** (then the rest) so an edge column does not pull a
## neighbor's front fighter into a shallow hole before that neighbor's own rank-0 gap is closed — that pattern
## read as the line scooting over and then back when the center finally pulls a reserve.
static func reconcile_vacancy_plugs_formation(manager: Node, fid: String) -> bool:
	var formation: Dictionary = _FormationSlots.formation_record_read(manager.formations, fid)
	if formation.is_empty():
		return false
	var slots_prune: Dictionary = _FormationSlots.formation_slots_dict(formation)
	if _FormationSlots.prune_dead_ids_from_formation_slots(manager, slots_prune):
		CombatDebug.formation_vacancy_log("pruned dead occupant ids from slots fid=%s" % fid)
	_vacancy_lateral_begin_tracking(manager)
	var nfiles: int = int(formation.get("files", 1))
	var any: bool = false
	var max_rounds: int = CombatConstants.FORMATION_VACANCY_RECONCILE_MAX_ROUNDS
	var exhausted_unstable: bool = false
	for ri in range(max_rounds):
		var round_changed: bool = false
		var files_rank0_hole_first: Array[int] = []
		var files_rest: Array[int] = []
		for file in range(nfiles):
			if not _FormationSlots.slot_has_any_living_occupant(manager, slots_prune, Vector2i(0, file)):
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
	_vacancy_lateral_end_tracking(manager)
	if compact_native_line_files_if_thinned(manager, fid):
		any = true
	if exhausted_unstable and OS.is_debug_build():
		push_warning(
			"CombatFormationFlow: vacancy reconcile used all %d rounds with a change on the last round (fid=%s). Slots may still have holes; check plug rules or raise FORMATION_VACANCY_RECONCILE_MAX_ROUNDS."
			% [max_rounds, fid]
		)
	_log_rank0_vacancy_gaps_if_debug(manager, fid)
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


## Entry point: full pass when `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY` is false; otherwise only `CombatManager._vacancy_dirty_fids` (cleared as processed).
static func reconcile_vacancy_plugs(manager: Node) -> Array:
	if manager == null or not manager.formations is Dictionary:
		return []
	if not CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		manager._vacancy_dirty_fids.clear()
		return reconcile_vacancy_plugs_track_changed_fids(manager)
	return reconcile_vacancy_plugs_dirty_fids(manager)


static func reconcile_vacancy_plugs_dirty_fids(manager: Node) -> Array:
	var changed_fids: Array = []
	if manager == null or not manager.formations is Dictionary:
		return changed_fids
	var dirty_dict: Dictionary = manager._vacancy_dirty_fids
	if dirty_dict.is_empty():
		debug_verify_vacancy_invariants_after_reconcile(manager)
		return changed_fids
	var to_proc: Array = dirty_dict.keys()
	dirty_dict.clear()
	to_proc.sort_custom(func(a, b): return str(a) < str(b))
	for fk_any in to_proc:
		var fk: String = str(fk_any)
		if _FormationSlots.formation_record_read(manager.formations, fk).is_empty():
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


## Shared tail for vacancy reconcile: ZoC/distance, surgical back-rank `action_ready` bump, optional `formation_changed`.
## Call with `emit_formation_changed_signals=false` when the caller emits those signals separately (e.g. `notify_formation_changed`).
static func finish_vacancy_reconcile_follow_up(
	manager: Node,
	changed_fids: Array,
	placement_snap_before: Dictionary,
	emit_formation_changed_signals: bool
) -> void:
	if manager == null or changed_fids.is_empty():
		return
	manager._recompute_zoc_and_distance()
	var moved: Array = CombatEventScheduler.ids_with_changed_rank_file_since_snapshot(manager, placement_snap_before)
	CombatEventScheduler.reschedule_formation_recheck_for_moved_back_ranks(manager, moved)
	if not emit_formation_changed_signals:
		return
	for fv in changed_fids:
		var fk: String = str(fv)
		if manager.formations is Dictionary and (manager.formations as Dictionary).has(fk):
			manager.emit_signal("formation_changed", fk)


## Debug-only: after a full reconcile pass, rank 0 in a column should not stay empty if a non-intruded ally
## could step up (same rules as `apply_vacancy_plug_same_file`). Intruder-only deeper ranks are allowed.
static func debug_verify_vacancy_invariants_after_reconcile(manager: Node) -> void:
	if not CombatConstants.COMBAT_FORMATION_INVARIANT_DEBUG:
		return
	if not OS.is_debug_build():
		return
	for fid_key in manager.formations.keys():
		var raw_form_dbg: Variant = manager.formations.get(fid_key, null)
		if raw_form_dbg == null or not (raw_form_dbg is Dictionary):
			continue
		var formation: Dictionary = raw_form_dbg as Dictionary
		if formation.is_empty():
			continue
		var fid_str: String = str(fid_key)
		var formation_ranks: int = int(formation.get("ranks", 1))
		if formation_ranks <= 1:
			continue
		var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
		var nfiles: int = int(formation.get("files", 1))
		var side_wanted: String = _FormationSlots.formation_side_str(formation)
		for file in range(nfiles):
			if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
				continue
			var has_promotable_deeper: bool = false
			for ally in manager.combatants:
				if not _EntityAccess.alive_bool(ally):
					continue
				if _EntityAccess.side_str(ally) != side_wanted:
					continue
				if _EntityAccess.formation_id_str(ally) != fid_str:
					continue
				if _ZoneOfControl.is_intruded(ally):
					continue
				if _is_ineligible_vacancy_donor(manager, ally):
					continue
				if _EntityAccess.file_int(ally) == file and _EntityAccess.rank_int(ally) >= 1:
					has_promotable_deeper = true
					break
			if has_promotable_deeper:
				push_error(
					"CombatFormationFlow: vacancy invariant failed after reconcile (rank 0 empty, deeper non-intruded ally) fid=%s file=%d"
					% [fid_str, file]
				)


static func on_combatant_died(manager: Node, c: Dictionary) -> void:
	_IntrusionWedge.remove_intruder_from_all_wedges(manager, _EntityAccess.id_int(c))
	var fid_home: String = _EntityAccess.formation_id_str(c)
	var fid_geom: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
	# Intruders may occupy host `slots` while `formation_id` stays home — strip from every formation first.
	for fk in manager.formations.keys():
		var raw_fd_death: Variant = manager.formations.get(fk, null)
		if raw_fd_death == null or not (raw_fd_death is Dictionary):
			continue
		var fd: Dictionary = raw_fd_death as Dictionary
		if fd.is_empty():
			continue
		var s: Dictionary = _FormationSlots.formation_slots_dict(fd)
		_FormationSlots.remove_combatant_from_slots(s, _EntityAccess.id_int(c))
	var formation: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_geom)
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
		var formation_ranks: int = formation.get("ranks", 1)
		var nfiles_death: int = int(formation.get("files", 1))
		_vacancy_lateral_begin_tracking(manager)
		var micro_max_d: int = CombatConstants.FORMATION_VACANCY_MICRO_STEPS_MAX
		for _micro_d in range(micro_max_d):
			var moved_step_d: bool = false
			for fill_rank in range(formation_ranks - 1, -1, -1):
				if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(fill_rank, f)):
					continue
				if fill_rank > 0 and not _has_living_deeper_in_file(
					manager, slots, fill_rank, f, formation_ranks
				):
					continue
				var reserved_d: Dictionary = _vacancy_plug_reserved_donors(manager)
				var allow_lateral_d: bool = true
				var side_death: String = _FormationSlots.formation_side_str(formation)
				var move_d: Dictionary = _select_best_plug_move_for_empty_cell(
					manager,
					fid_geom,
					slots,
					fill_rank,
					f,
					formation_ranks,
					nfiles_death,
					side_death,
					true,
					reserved_d,
					true,
					allow_lateral_d
				)
				if move_d.is_empty():
					continue
				_apply_plug_move(manager, slots, move_d, fill_rank, f, "Plug")
				moved_step_d = true
				break
			if not moved_step_d:
				break
		_vacancy_lateral_end_tracking(manager)
	manager._recompute_zoc_and_distance()
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		manager.mark_all_formations_vacancy_dirty()
	manager.notify_formation_changed(fid_geom)
	if fid_home != fid_geom and manager.has_method("notify_formation_changed"):
		manager.notify_formation_changed(fid_home)
	manager._reschedule_back_rank_turns(fid_geom)
	if fid_home != fid_geom:
		manager._reschedule_back_rank_turns(fid_home)
