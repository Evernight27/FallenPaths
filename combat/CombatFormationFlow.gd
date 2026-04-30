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
## **Global vacancy reconcile:** `reconcile_vacancy_plugs_formation` / `reconcile_vacancy_plugs_all_formations` promote
## shallow holes across every file column. `CombatManager.notify_formation_changed` and `get_available_actions` call
## these so rank-0 gaps do not persist off-intrusion paths; work is idempotent when the line is already filled.
## Rank-0 **lateral** plugs: only when the donor file has **promotable** depth (same donor rules as vertical: not intruded, etc.)
## or the hole column has none; otherwise the front waits while the hole's column promotes (`apply_vacancy_plug_same_file` order).
## Per hole: **best vertical** and **best lateral** are scored independently, then `_resolve_optimal_plug_vertical_vs_lateral`
## picks vertical whenever the same column has an adjacent-rank donor (depth funnels before same-rank lateral).
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
	if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
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
		if int(e.get("id", -9)) != ally_id:
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
	if int(ally.get("rank", -9)) != fill_rank:
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
	if c == null or not c.alive:
		return
	var st: String = c.get("state", "")
	if st != CombatConstants.STATE_SWAP_RANK and st != CombatConstants.STATE_FALLING_BACK:
		return
	var extra: float = CombatConstants.FORMATION_HIT_REACTION_EXTRA_S * lerpf(0.4, 1.2, clampf(intensity, 0.0, 1.0))
	c.state_duration += extra
	var pid: int = int(c.get("formation_move_partner_id", -1))
	if pid >= 0:
		var p = manager._get_by_id(pid)
		if p != null and p.alive:
			var pst: String = p.get("state", "")
			if pst == CombatConstants.STATE_SWAP_RANK or pst == CombatConstants.STATE_FALLING_BACK:
				p.state_duration += extra
	bump_resolve_events(manager, combatant_id, extra)


static func bump_resolve_events(manager: Node, for_combatant_id: int, extra_s: float) -> void:
	for ev in manager.event_queue:
		var t: String = ev.get("type", "")
		var cid: int = ev.get("combatant_id", -1)
		var data: Dictionary = ev.get("data", {})
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
	if init == null or partner == null or not init.alive or not partner.alive:
		return
	if str(init.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return
	if str(partner.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return
	if init.side != partner.side or init.get("formation_id", "") != partner.get("formation_id", ""):
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty() or formation.get("ranks", 1) <= 1:
		return
	var r0: int = init.get("rank", 0)
	var r1: int = partner.get("rank", 0)
	var f0: int = init.get("file", 0)
	var f1: int = partner.get("file", 0)
	if f0 != f1 or abs(r0 - r1) != 1:
		return
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var agi: float = float(init.stats.get("agility", 100))
	var kind_mult: float = CombatConstants.DRAG_BACK_DURATION_MULT if move_kind == "drag_back" else 1.0
	var armor_mult: float = maxf(manager._armor_mass_duration_multiplier_for_node(init.node), manager._armor_mass_duration_multiplier_for_node(partner.node))
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_foot * pressure_mod * kind_mult * armor_mult
	var use_falling: bool = move_kind == "drag_back" or move_kind == "fall_back_pair"
	var st: String = CombatConstants.STATE_FALLING_BACK if use_falling else CombatConstants.STATE_SWAP_RANK
	var slots: Dictionary = formation.get("slots", {})
	var r_lo: int = mini(r0, r1)
	var r_hi: int = maxi(r0, r1)
	var id_at_lo: int = init.id if init.get("rank", 0) == r_lo else partner.id
	var id_at_hi: int = init.id if init.get("rank", 0) == r_hi else partner.id
	_FormationSlots.begin_adjacent_rank_pair_move(slots, r_lo, r_hi, f0, id_at_lo, id_at_hi)
	init["formation_move_partner_id"] = partner_id
	partner["formation_move_partner_id"] = initiator_id
	init.state = st
	init.state_timer = 0.0
	init.state_duration = duration
	partner.state = st
	partner.state_timer = 0.0
	partner.state_duration = duration
	if CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE:
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		print("[Combat] %s formation move (%s) with %s (%.2fs, lane×foot×%.2f pressure×%.2f)" % [n0, move_kind, n1, duration, lane_foot, pressure_mod])
	manager._schedule_event({
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": manager.combat_clock + duration,
		"data": {"partner_id": partner_id, "move_kind": move_kind}
	})


static func start_fall_back_solo(manager: Node, initiator_id: int) -> void:
	var init = manager._get_by_id(initiator_id)
	if init == null or not init.alive:
		return
	if str(init.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return
	var ranks: int = formation.get("ranks", 1)
	if ranks <= 1 or init.get("rank", 0) != 0:
		return
	var f: int = init.get("file", 0)
	var slots: Dictionary = formation.get("slots", {})
	if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(1, f)):
		return
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var agi: float = float(init.stats.get("agility", 100))
	var armor_mult: float = manager._armor_mass_duration_multiplier_for_node(init.node)
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_foot * pressure_mod * armor_mult
	init["formation_move_partner_id"] = -1
	init.state = CombatConstants.STATE_FALLING_BACK
	init.state_timer = 0.0
	init.state_duration = duration
	if CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE:
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		print("[Combat] %s falling back solo (%.2fs)" % [n0, duration])
	manager._schedule_event({
		"type": CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": manager.combat_clock + duration,
		"data": {}
	})


static func start_rotate_file(manager: Node, initiator_id: int, partner_id: int) -> void:
	var init = manager._get_by_id(initiator_id)
	var partner = manager._get_by_id(partner_id)
	if init == null or partner == null or not init.alive or not partner.alive:
		return
	if str(init.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return
	if str(partner.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return
	if init.side != partner.side or init.get("formation_id", "") != partner.get("formation_id", ""):
		return
	var r_init: int = int(init.get("rank", 0))
	var r_partner: int = int(partner.get("rank", 0))
	if r_init != r_partner:
		return
	var f0: int = init.get("file", 0)
	var f1: int = partner.get("file", 0)
	if abs(f0 - f1) != 1:
		return
	var fid: String = init.get("formation_id", "")
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var agi: float = float(init.stats.get("agility", 100))
	var armor_mult: float = maxf(manager._armor_mass_duration_multiplier_for_node(init.node), manager._armor_mass_duration_multiplier_for_node(partner.node))
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_foot * pressure_mod * armor_mult
	init["formation_move_partner_id"] = partner_id
	partner["formation_move_partner_id"] = initiator_id
	init.state = CombatConstants.STATE_SWAP_RANK
	init.state_timer = 0.0
	init.state_duration = duration
	partner.state = CombatConstants.STATE_SWAP_RANK
	partner.state_timer = 0.0
	partner.state_duration = duration
	if CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE:
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		print("[Combat] %s rotating file with %s (%.2fs)" % [n0, n1, duration])
	manager._schedule_event({
		"type": CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": manager.combat_clock + duration,
		"data": {"partner_id": partner_id}
	})


static func pair_state_ok(c) -> bool:
	return c != null and c.get("state", "") in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]


static func abort_pair(manager: Node, init, partner) -> void:
	var iid: int = init.get("id", -1) if init != null else -1
	var pid: int = partner.get("id", -1) if partner != null else -1
	CombatDebug.flow_log("formation_pair abort (reset to waiting) initiator_id=%d partner_id=%d" % [iid, pid])
	if init != null:
		init.erase("formation_move_partner_id")
	if partner != null:
		partner.erase("formation_move_partner_id")
	if init != null and partner != null:
		var fid: String = str(init.get("formation_id", ""))
		if not fid.is_empty() and init.get("formation_id", "") == partner.get("formation_id", ""):
			var formation: Dictionary = manager.formations.get(fid, {})
			var slots: Dictionary = formation.get("slots", {})
			_FormationSlots.remove_combatant_from_slots(slots, init.id)
			_FormationSlots.remove_combatant_from_slots(slots, partner.id)
			if init.get("alive", false):
				_FormationSlots.slot_set_single(slots, Vector2i(init.get("rank", 0), init.get("file", 0)), init.id)
			if partner.get("alive", false):
				_FormationSlots.slot_set_single(slots, Vector2i(partner.get("rank", 0), partner.get("file", 0)), partner.id)
			manager._recompute_zoc_and_distance()
			manager.notify_formation_changed(fid)
			manager._reschedule_back_rank_turns(fid)
	if init != null and init.get("alive", false) and pair_state_ok(init):
		init.state = CombatConstants.STATE_WAITING
	if partner != null and partner.get("alive", false) and pair_state_ok(partner):
		partner.state = CombatConstants.STATE_WAITING
	# Keep a brief local guard after abort so the same pair does not instantly requeue under churn.
	var until: float = float(manager.combat_clock) + 0.7
	if init != null and init.get("alive", false):
		init["formation_pair_abort_cooldown_until"] = until
	if partner != null and partner.get("alive", false):
		partner["formation_pair_abort_cooldown_until"] = until


static func handle_swap_rank_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var data: Dictionary = ev.get("data", {})
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
	if not init.alive or not partner.alive:
		abort_pair(manager, init, partner)
		if init != null and init.alive:
			manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		if partner != null and partner.alive:
			manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))
		return
	if not pair_state_ok(init) or not pair_state_ok(partner):
		abort_pair(manager, init, partner)
		if init != null and init.alive:
			manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		if partner != null and partner.alive:
			manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		abort_pair(manager, init, partner)
		return
	var slots: Dictionary = formation.get("slots", {})
	var r0: int = init.get("rank", 0)
	var r1: int = partner.get("rank", 0)
	var f0: int = init.get("file", 0)
	var f1: int = partner.get("file", 0)
	_FormationSlots.remove_combatant_from_slots(slots, init.id)
	_FormationSlots.remove_combatant_from_slots(slots, partner.id)
	init.rank = r1
	init.file = f1
	partner.rank = r0
	partner.file = f0
	repack_lane_offset_after_rank_file_change(init)
	repack_lane_offset_after_rank_file_change(partner)
	_FormationSlots.slot_set_single(slots, Vector2i(init.rank, init.file), init.id)
	_FormationSlots.slot_set_single(slots, Vector2i(partner.rank, partner.file), partner.id)
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
	CombatDebug.flow_log("formation_pair_resolve id=%d <-> %d move_kind=%s outcome=%s" % [initiator_id, partner_id, move_kind, outcome])
	manager.emit_signal("action_resolved", initiator_id, partner_id, {"outcome": outcome, "dmg": 0, "died": false, "move_kind": move_kind})
	if CombatConstants.COMBAT_EVENT_DEBUG and CombatConstants.COMBAT_EVENT_DEBUG_VERBOSE:
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		print("[Combat] %s and %s finished formation move (%s)" % [n0, n1, move_kind])
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
	manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
	if partner != null and partner.alive and not _EntityAccess.is_incapacitated(partner):
		manager._schedule_action_ready(partner_id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


static func handle_fall_back_solo_resolve(manager: Node, ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var init = manager._get_by_id(initiator_id)
	if init == null or not init.alive:
		return
	if init.get("state", "") != CombatConstants.STATE_FALLING_BACK:
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		init.state = CombatConstants.STATE_WAITING
		return
	var f: int = init.get("file", 0)
	var slots: Dictionary = formation.get("slots", {})
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
	var partner_id: int = ev.get("data", {}).get("partner_id", -1)
	var init = manager._get_by_id(initiator_id)
	var partner = manager._get_by_id(partner_id)
	if init == null or partner == null or not init.alive or not partner.alive:
		abort_pair(manager, init, partner)
		return
	if not pair_state_ok(init) or not pair_state_ok(partner):
		abort_pair(manager, init, partner)
		if init != null and init.alive:
			manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		if partner != null and partner.alive:
			manager._schedule_action_ready(partner_id, manager._action_ready_cooldown(partner))
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		abort_pair(manager, init, partner)
		return
	var slots: Dictionary = formation.get("slots", {})
	var f0: int = init.get("file", 0)
	var f1: int = partner.get("file", 0)
	var r_rot: int = int(init.get("rank", 0))
	_FormationSlots.remove_combatant_from_slots(slots, init.id)
	_FormationSlots.remove_combatant_from_slots(slots, partner.id)
	init.file = f1
	partner.file = f0
	repack_lane_offset_after_rank_file_change(init)
	repack_lane_offset_after_rank_file_change(partner)
	_FormationSlots.slot_set_single(slots, Vector2i(r_rot, init.file), init.id)
	_FormationSlots.slot_set_single(slots, Vector2i(r_rot, partner.file), partner.id)
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
	var fid_a: String = str(atk.get("formation_id", ""))
	if fid_a.is_empty() or defender_formation_id.is_empty():
		return
	var form_a: Dictionary = manager.formations.get(fid_a, {})
	var form_b: Dictionary = manager.formations.get(defender_formation_id, {})
	if form_a.is_empty() or form_b.is_empty():
		return
	var aid: int = int(atk.get("id", -1))
	if aid < 0:
		return
	var stored_home: int = int(atk.get("intrusion_source_file", -1))
	var first_intrusion: bool = stored_home < 0
	var home_vacancy_file: int = int(atk.get("file", 0)) if first_intrusion else stored_home
	for fk in manager.formations.keys():
		var fd: Dictionary = manager.formations[fk]
		if fd.is_empty():
			continue
		_FormationSlots.remove_combatant_from_slots(fd.get("slots", {}), aid)
	var slots_b: Dictionary = form_b.get("slots", {})
	var host_ranks: int = maxi(1, int(form_b.get("ranks", 1)))
	var placed_rank: int = _FormationSlots.place_intruder_behind_front_line(manager, slots_b, host_ranks, defender_file, aid)
	atk["rank"] = placed_rank
	atk["file"] = defender_file
	var sev_use: float = breach_severity
	if sev_use < 0.0:
		var bf0: Dictionary = form_b.get("breached_files", {})
		sev_use = _FormationBreachRules.breached_file_severity(bf0, defender_file, 0.7)
	_IntrusionWedge.upsert_from_intrusion(
		form_b,
		defender_file,
		aid,
		sev_use,
		int(atk.get("tactical_penetration_depth", 0)),
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
	var form_b: Dictionary = manager.formations.get(defender_formation_id, {})
	if form_b.is_empty():
		return
	var slots_b: Dictionary = form_b.get("slots", {})
	var occ: Array = _FormationSlots.normalize_cell(slots_b.get(Vector2i(0, anchor_file), []))
	for did in occ:
		var cid: int = int(did)
		if cid == intruder_id:
			continue
		var defc: Variant = manager._get_by_id(cid)
		if defc == null or not (defc as Dictionary).get("alive", false):
			continue
		var d: Dictionary = defc as Dictionary
		if str(d.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			continue
		if int(d.get("rank", 0)) != 0:
			continue
		if str(d.get("formation_id", "")) != defender_formation_id:
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
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return false
	var slots: Dictionary = formation.get("slots", {})
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
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return false
	var formation_ranks: int = int(formation.get("ranks", 1))
	if formation_ranks <= 1:
		return false
	var slots: Dictionary = formation.get("slots", {})
	var nfiles: int = maxi(1, int(formation.get("files", 1)))
	var side_wanted: String = str(formation.get("side", ""))
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


## Busy combatants must not be picked as vacancy donors (would fight slot state during swaps / wind-up).
## Units just moved by automatic plug also sit out briefly so reconcile ticks cannot ping-pong them as donors.
static func _is_ineligible_vacancy_donor(manager: Node, c: Dictionary) -> bool:
	var st: String = str(c.get("state", ""))
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
			var fid: String = str(c.get("formation_id", ""))
			# Frontline-first override: if rank 0 has holes, let reserves donate even during autofill cooldown.
			if not _formation_has_rank0_hole(manager, fid):
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
		if ally == null or not ally.get("alive", false):
			continue
		if str(ally.get("side", "")) != side_wanted:
			continue
		if str(ally.get("formation_id", "")) != fid:
			continue
		if skip_intruded and str(ally.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
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
## When `adjacent_rank_only`, only `fill_rank + 1` is considered so one move cannot skip a rank (avoids mid-column holes + early `break` starving deeper fills).
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
	var search_end: int = formation_ranks
	if adjacent_rank_only:
		search_end = mini(fill_rank + 2, formation_ranks)
	for search_rank in range(fill_rank + 1, search_end):
		var ally_v: Variant = _combatant_from_slot_primary_living(
			manager, slots, Vector2i(search_rank, file), fid, side_wanted, skip_intruded
		)
		if ally_v == null:
			continue
		var aid: int = int(ally_v.get("id", -1))
		if reserved.get(aid, false):
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
	return best


## Best lateral option for this hole (same rank, adjacent files). Evaluated separately from vertical.
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
		var aid: int = int(ally_l.get("id", -1))
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


## Pick exactly one move after independent vertical vs lateral scores.
## If the hole's **column** has a legal vertical donor (same file, one rank deeper), always use it so the stack promotes before sideways shuffle.
static func _resolve_optimal_plug_vertical_vs_lateral(vert: Dictionary, lat: Dictionary) -> Dictionary:
	if vert.is_empty() and lat.is_empty():
		return {}
	if vert.is_empty():
		return lat
	if lat.is_empty():
		return vert
	return vert


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


## Resolves one hole: compute best vertical and best lateral independently, then choose optimal (not mixed candidate list).
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
	var lat: Dictionary = {}
	if allow_lateral:
		lat = _evaluate_best_lateral_plug_for_cell(
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
	return _plug_move_for_apply(_resolve_optimal_plug_vertical_vs_lateral(vert, lat))


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
	_FormationSlots.remove_combatant_from_slots(slots, ally.id)
	ally.rank = fill_rank
	ally.file = file
	repack_lane_offset_after_rank_file_change(ally)
	_FormationSlots.slot_set_single(slots, Vector2i(fill_rank, file), ally.id)
	ally["formation_autofill_cooldown_until"] = (
		float(manager.combat_clock) + CombatConstants.FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S
	)
	ally["formation_autofill_last_move_clock"] = float(manager.combat_clock)
	if kind == "lateral":
		ally["formation_vacancy_lateral_last_from_file"] = from_f
		ally["formation_vacancy_lateral_last_to_file"] = file
		ally["formation_vacancy_lateral_reverse_lock_until"] = (
			float(manager.combat_clock) + CombatConstants.FORMATION_VACANCY_LATERAL_REVERSE_LOCK_S
		)
		if manager.has_meta(_VACANCY_LATERAL_EDGE_META):
			_vacancy_lateral_record_edge(manager, int(ally.get("id", -1)), from_f, file, fill_rank)
	else:
		ally.erase("formation_vacancy_lateral_last_from_file")
		ally.erase("formation_vacancy_lateral_last_to_file")
		ally.erase("formation_vacancy_lateral_reverse_lock_until")
	if CombatConstants.COMBAT_FORMATION_PLUG_MOVE_DEBUG:
		var name_p: String = _EntityAccess.get_display_name(ally, ally.get("id", -1))
		if kind == "lateral":
			print(
				"[Combat] %s: %s slid file %d → %d (rank %d)" % [log_prefix, name_p, from_f, file, fill_rank]
			)
		else:
			print("[Combat] %s: %s advanced to rank %d (file %d)" % [log_prefix, name_p, fill_rank, file])
	elif CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG and str(log_prefix).begins_with("Vacancy"):
		var name_v: String = _EntityAccess.get_display_name(ally, ally.get("id", -1))
		CombatDebug.formation_vacancy_log("%s: %s → rank %d file %d (%s)" % [log_prefix, name_v, fill_rank, file, kind])
	if manager.has_meta(_VACANCY_PLUG_RESERVED_DONORS_META):
		var rd: Dictionary = manager.get_meta(_VACANCY_PLUG_RESERVED_DONORS_META) as Dictionary
		rd[int(ally.get("id", -1))] = true
	manager._schedule_action_ready(ally.id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


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


## Rank-0 lateral: allow only when the slide is not "shuffling the line ahead of" depth in the **hole** column.
## - Donor file has promotable rank ≥ 1: moving the front frees that column for vertical plugs on later micro steps / rounds.
## - Hole file has no promotable depth: nothing eligible can step up the hole column; neighbor front may span the gap.
static func _rank0_lateral_slide_allowed(
	manager: Node,
	slots: Dictionary,
	hole_file: int,
	donor_file: int,
	formation_ranks: int,
	fid: String,
	side_wanted: String,
	skip_intruded: bool
) -> bool:
	if manager == null or formation_ranks <= 1:
		return false
	if _has_promotable_deeper_in_file(
		manager, slots, 0, donor_file, formation_ranks, fid, side_wanted, skip_intruded
	):
		return true
	if not _has_promotable_deeper_in_file(
		manager, slots, 0, hole_file, formation_ranks, fid, side_wanted, skip_intruded
	):
		return true
	return false


## Promote / slide into empty cells (no death, no slot_obstacles). Caller runs ZoC/distance if needed.
## Priority = `pow(effectiveness01, EXP) / (1 + W*proximity_steps)` so heavy injury nonlinearly defers plugging when fitter allies exist in other ranks or files.
## Returns true if any combatant moved.
static func apply_vacancy_plug_same_file(manager: Node, fid: String, file: int) -> bool:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return false
	var formation_ranks: int = formation.get("ranks", 1)
	if formation_ranks <= 1:
		return false
	var slots: Dictionary = formation.get("slots", {})
	var side_wanted: String = str(formation.get("side", ""))
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
			var allow_lateral: bool = fill_rank == 0
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


## Skirmish: pack natives to contiguous files so stragglers are addressable. **Formation (shield wall):** do not
## compact — vacancy plugs already fill empty cells; contiguous repack was shifting rank-0 fighters sideways
## whenever `front_n / nfiles` dipped barely below `FORMATION_MIN_FRONT_FILL_RATIO` (e.g. 2/3-wide line),
## which reads as units swapping files instead of holding ground until a slot is actually empty.
static func _should_compact_native_line_files(manager: Node, _fid: String) -> bool:
	if manager == null:
		return false
	if str(_EngagementMode.engagement_mode(manager)) == str(CombatConstants.ENGAGEMENT_MODE_FORMATION):
		return false
	return true


static func _formation_has_blocking_formation_motion_for_compact(manager: Node, fid: String) -> bool:
	for c in manager.combatants:
		if not c.get("alive", false):
			continue
		if str(c.get("formation_id", "")) != fid:
			continue
		if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			continue
		var st: String = str(c.get("state", ""))
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
	if nat == null or not nat.get("alive", false):
		return
	var key := Vector2i(rank, file_col)
	_FormationSlots.remove_combatant_from_slots(slots, native_id)
	var merged: Array = []
	var cur: Array = _FormationSlots.normalize_cell(slots.get(key, []))
	for cid in cur:
		var oc = manager._get_by_id(int(cid)) if manager.has_method("_get_by_id") else null
		if oc == null or not oc.get("alive", false):
			continue
		if str(oc.get("formation_id", "")) != fid or str(oc.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
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
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return false
	var slots: Dictionary = formation.get("slots", {})
	var side_wanted: String = str(formation.get("side", ""))
	var formation_ranks: int = maxi(1, int(formation.get("ranks", 1)))
	var any: bool = false
	for rank in range(formation_ranks):
		var natives: Array = []
		for c in manager.combatants:
			if not c.get("alive", false):
				continue
			if str(c.get("formation_id", "")) != fid:
				continue
			if str(c.get("side", "")) != side_wanted:
				continue
			if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
				continue
			if int(c.get("rank", 0)) != rank:
				continue
			natives.append(c)
		if natives.is_empty():
			continue
		natives.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				var af: int = int(a.get("file", 0))
				var bf: int = int(b.get("file", 0))
				if af != bf:
					return af < bf
				return int(a.get("id", 0)) < int(b.get("id", 0))
		)
		var i: int = 0
		for nat in natives:
			var nid: int = int(nat.get("id", -1))
			var new_f: int = i
			i += 1
			var key := Vector2i(rank, new_f)
			var need: bool = int(nat.get("file", 0)) != new_f
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
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return
	var formation_ranks: int = int(formation.get("ranks", 1))
	if formation_ranks <= 1:
		return
	var slots: Dictionary = formation.get("slots", {})
	var nfiles: int = int(formation.get("files", 1))
	var side_wanted: String = str(formation.get("side", ""))
	for file in range(nfiles):
		if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
			continue
		for ally in manager.combatants:
			if not ally.get("alive", false):
				continue
			if str(ally.get("side", "")) != side_wanted:
				continue
			if str(ally.get("formation_id", "")) != fid:
				continue
			if str(ally.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
				continue
			if int(ally.get("file", 0)) != file or int(ally.get("rank", 0)) < 1:
				continue
			if _is_ineligible_vacancy_donor(manager, ally):
				continue
			CombatDebug.formation_vacancy_log(
				"rank0 gap fid=%s file=%d donor id=%d state=%s rank=%d (slots out of sync or plug blocked)"
				% [fid, file, ally.get("id", -1), str(ally.get("state", "")), int(ally.get("rank", 0))]
			)
			break


## Run vacancy plug on every file column so empty front cells do not persist while deeper ranks are alive (avoids soft deadlock: no enemy rank 0 while enemies remain).
## Repeats rounds so lateral slides that open a gap in a neighbor file get a chance to fill.
static func reconcile_vacancy_plugs_formation(manager: Node, fid: String) -> bool:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return false
	var slots_prune: Dictionary = formation.get("slots", {})
	if _FormationSlots.prune_dead_ids_from_formation_slots(manager, slots_prune):
		CombatDebug.formation_vacancy_log("pruned dead occupant ids from slots fid=%s" % fid)
	_vacancy_lateral_begin_tracking(manager)
	var nfiles: int = int(formation.get("files", 1))
	var any: bool = false
	var max_rounds: int = CombatConstants.FORMATION_VACANCY_RECONCILE_MAX_ROUNDS
	var exhausted_unstable: bool = false
	for ri in range(max_rounds):
		var round_changed: bool = false
		for file in range(nfiles):
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


static func reconcile_vacancy_plugs_all_formations(manager: Node) -> bool:
	var any: bool = false
	for fk in manager.formations.keys():
		if reconcile_vacancy_plugs_formation(manager, str(fk)):
			any = true
	debug_verify_vacancy_invariants_after_reconcile(manager)
	return any


## Debug-only: after a full reconcile pass, rank 0 in a column should not stay empty if a non-intruded ally
## could step up (same rules as `apply_vacancy_plug_same_file`). Intruder-only deeper ranks are allowed.
static func debug_verify_vacancy_invariants_after_reconcile(manager: Node) -> void:
	if not CombatConstants.COMBAT_FORMATION_INVARIANT_DEBUG:
		return
	if not OS.is_debug_build():
		return
	for fid in manager.formations.keys():
		var formation: Dictionary = manager.formations[fid]
		if formation.is_empty():
			continue
		var formation_ranks: int = int(formation.get("ranks", 1))
		if formation_ranks <= 1:
			continue
		var slots: Dictionary = formation.get("slots", {})
		var nfiles: int = int(formation.get("files", 1))
		var side_wanted: String = str(formation.get("side", ""))
		for file in range(nfiles):
			if _FormationSlots.slot_has_any_living_occupant(manager, slots, Vector2i(0, file)):
				continue
			var has_promotable_deeper: bool = false
			for ally in manager.combatants:
				if not ally.get("alive", false):
					continue
				if str(ally.get("side", "")) != side_wanted:
					continue
				if str(ally.get("formation_id", "")) != fid:
					continue
				if str(ally.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
					continue
				if _is_ineligible_vacancy_donor(manager, ally):
					continue
				if int(ally.get("file", 0)) == file and int(ally.get("rank", 0)) >= 1:
					has_promotable_deeper = true
					break
			if has_promotable_deeper:
				push_error(
					"CombatFormationFlow: vacancy invariant failed after reconcile (rank 0 empty, deeper non-intruded ally) fid=%s file=%d"
					% [fid, file]
				)


static func on_combatant_died(manager: Node, c: Dictionary) -> void:
	_IntrusionWedge.remove_intruder_from_all_wedges(manager, int(c.get("id", -1)))
	var fid: String = c.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return
	var r: int = c.get("rank", 0)
	var f: int = c.get("file", 0)
	if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		var src_f: int = int(c.get("intrusion_source_file", -1))
		if src_f >= 0:
			f = src_f
			r = 0
	# Intruders may occupy host `slots` while `formation_id` stays home — strip from every formation first.
	for fk in manager.formations.keys():
		var fd: Dictionary = manager.formations[fk]
		if fd.is_empty():
			continue
		var s: Dictionary = fd.get("slots", {})
		_FormationSlots.remove_combatant_from_slots(s, c.id)
	var slots: Dictionary = formation.get("slots", {})
	_FormationSlots.prune_dead_ids_from_formation_slots(manager, slots)
	var obstacles: Dictionary = formation.get("slot_obstacles", {})
	var key := Vector2i(r, f)
	if not obstacles.has(key):
		obstacles[key] = []
	obstacles[key].append(c.id)
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
				var allow_lateral_d: bool = fill_rank == 0
				var move_d: Dictionary = _select_best_plug_move_for_empty_cell(
					manager,
					fid,
					slots,
					fill_rank,
					f,
					formation_ranks,
					nfiles_death,
					str(c.side),
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
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
