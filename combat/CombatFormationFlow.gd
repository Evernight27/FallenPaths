class_name CombatFormationFlow
extends RefCounted

## Formation moves, resolve events, slot plug on death, hit reaction delays on pending formation events.
##
## Plug order (see docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md §4): **intrusion slot writes** first (crash success),
## then **vacancy plug** on the home formation (empty rank-0 without death). **Death plug** stays in
## `on_combatant_died` only; same-tick ordering avoids mixing vacancy with death removal.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")


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
	if CombatConstants.COMBAT_EVENT_DEBUG:
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
	if _FormationSlots.slot_has_any(slots, Vector2i(1, f)):
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
	if CombatConstants.COMBAT_EVENT_DEBUG:
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
	if init.get("rank", 0) != 0 or partner.get("rank", 0) != 0:
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
	if CombatConstants.COMBAT_EVENT_DEBUG:
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
	if init != null and init.get("alive", false) and pair_state_ok(init):
		init.state = CombatConstants.STATE_WAITING
	if partner != null and partner.get("alive", false) and pair_state_ok(partner):
		partner.state = CombatConstants.STATE_WAITING


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
	_FormationSlots.slot_set_single(slots, Vector2i(init.rank, init.file), init.id)
	_FormationSlots.slot_set_single(slots, Vector2i(partner.rank, partner.file), partner.id)
	init.erase("formation_move_partner_id")
	partner.erase("formation_move_partner_id")
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
	if CombatConstants.COMBAT_EVENT_DEBUG:
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
	if _FormationSlots.slot_has_any(slots, Vector2i(1, f)):
		CombatDebug.flow_log("fall_back_solo_resolve id=%d aborted: rear slot (1,%d) occupied" % [initiator_id, f])
		init.state = CombatConstants.STATE_WAITING
		manager._schedule_action_ready(initiator_id, manager._action_ready_cooldown(init))
		return
	_FormationSlots.remove_combatant_from_slots(slots, initiator_id)
	init.rank = 1
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
	_FormationSlots.remove_combatant_from_slots(slots, init.id)
	_FormationSlots.remove_combatant_from_slots(slots, partner.id)
	init.file = f1
	partner.file = f0
	_FormationSlots.slot_set_single(slots, Vector2i(0, init.file), init.id)
	_FormationSlots.slot_set_single(slots, Vector2i(0, partner.file), partner.id)
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
	var placed_rank: int = _FormationSlots.place_intruder_behind_front_line(slots_b, host_ranks, defender_file, aid)
	atk["rank"] = placed_rank
	atk["file"] = defender_file
	var sev_use: float = breach_severity
	if sev_use < 0.0:
		var bf0: Dictionary = form_b.get("breached_files", {})
		sev_use = float(bf0.get(defender_file, bf0.get(str(defender_file), 0.7)))
	_IntrusionWedge.upsert_from_intrusion(
		form_b,
		defender_file,
		aid,
		sev_use,
		int(atk.get("tactical_penetration_depth", 0)),
		CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX
	)
	atk["lane_offset"] = clampf(
		CombatConstants.INTRUSION_INTRUDER_LANE_OFFSET_BIAS,
		-CombatConstants.LANE_OFFSET_ABS_MAX,
		CombatConstants.LANE_OFFSET_ABS_MAX
	)
	if first_intrusion:
		atk["intrusion_source_file"] = home_vacancy_file
		apply_vacancy_plug_same_file(manager, fid_a, home_vacancy_file)
	manager._reschedule_back_rank_turns(fid_a)
	manager._reschedule_back_rank_turns(defender_formation_id)


## Promote shallowest empty cells in one file column (no death, no slot_obstacles). Caller runs ZoC/distance if needed.
static func apply_vacancy_plug_same_file(manager: Node, fid: String, file: int) -> void:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return
	var formation_ranks: int = formation.get("ranks", 1)
	if formation_ranks <= 1:
		return
	var slots: Dictionary = formation.get("slots", {})
	var side_wanted: String = str(formation.get("side", ""))
	for fill_rank in range(formation_ranks):
		if _FormationSlots.slot_has_any(slots, Vector2i(fill_rank, file)):
			continue
		var next_rank: int = fill_rank + 1
		if next_rank >= formation_ranks:
			break
		var promoted = null
		for ally in manager.combatants:
			if not ally.get("alive", false) or str(ally.get("side", "")) != side_wanted:
				continue
			if str(ally.get("formation_id", "")) != fid:
				continue
			if str(ally.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
				continue
			if int(ally.get("rank", 0)) == next_rank and int(ally.get("file", 0)) == file:
				promoted = ally
				break
		if promoted == null:
			break
		_FormationSlots.remove_combatant_from_slots(slots, promoted.id)
		promoted.rank = fill_rank
		promoted.file = file
		promoted["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT
		_FormationSlots.slot_set_single(slots, Vector2i(fill_rank, file), promoted.id)
		if CombatConstants.COMBAT_EVENT_DEBUG:
			var name_p: String = _EntityAccess.get_display_name(promoted, promoted.get("id", -1))
			print("[Combat] Vacancy plug: %s advanced to rank %d (file %d)" % [name_p, fill_rank, file])
		manager._schedule_action_ready(promoted.id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


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
	var obstacles: Dictionary = formation.get("slot_obstacles", {})
	var key := Vector2i(r, f)
	if not obstacles.has(key):
		obstacles[key] = []
	obstacles[key].append(c.id)
	if formation.get("ranks", 1) > 1:
		var formation_ranks: int = formation.get("ranks", 1)
		for fill_rank in range(formation_ranks):
			if _FormationSlots.slot_has_any(slots, Vector2i(fill_rank, f)):
				continue
			var next_rank: int = fill_rank + 1
			if next_rank >= formation_ranks:
				break
			var promoted = null
			for ally in manager.combatants:
				if not ally.alive or ally.side != c.side or ally.get("formation_id", "") != fid:
					continue
				if ally.get("rank", 0) == next_rank and ally.get("file", 0) == f:
					promoted = ally
					break
			if promoted == null:
				break
			_FormationSlots.remove_combatant_from_slots(slots, promoted.id)
			promoted.rank = fill_rank
			promoted.file = f
			promoted["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT
			_FormationSlots.slot_set_single(slots, Vector2i(fill_rank, f), promoted.id)
			if CombatConstants.COMBAT_EVENT_DEBUG:
				var name_p: String = _EntityAccess.get_display_name(promoted, promoted.get("id", -1))
				print("[Combat] Plug: %s advanced to rank %d (file %d) after ally fell" % [name_p, fill_rank, f])
			manager._schedule_action_ready(promoted.id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
