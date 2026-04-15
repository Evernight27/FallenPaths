class_name CombatFormationFlow
extends RefCounted

## Formation moves, resolve events, slot plug on death, hit reaction delays on pending formation events.
##
## Plug order (see docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md §4): **intrusion slot writes** first (crash success),
## then **vacancy plug** on the home formation (empty rank-0 without death). **Death plug** stays in
## `on_combatant_died` only; same-tick ordering avoids mixing vacancy with death removal.
##
## **Global vacancy reconcile:** `reconcile_vacancy_plugs_formation` / `reconcile_vacancy_plugs_all_formations` promote
## shallow holes across every file column. `CombatManager.notify_formation_changed` and `get_available_actions` call
## these so rank-0 gaps do not persist off-intrusion paths; work is idempotent when the line is already filled.

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
	var r_rot: int = int(init.get("rank", 0))
	_FormationSlots.remove_combatant_from_slots(slots, init.id)
	_FormationSlots.remove_combatant_from_slots(slots, partner.id)
	init.file = f1
	partner.file = f0
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


## First living non-intruded occupant in `slots` at `key` for this formation side (dual cells: first valid).
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
		return ally
	return null


## Higher = fitter to hold the line (performance, legs, blood). Incapacitated fighters score very low.
static func _plug_effectiveness_score(manager: Node, c: Dictionary) -> float:
	if _EntityAccess.is_incapacitated(c):
		return -100.0
	var perf: float = clampf(_EntityAccess.get_performance_modifier(c), 0.0, 2.0)
	var leg: float = clampf(_EntityAccess.get_leg_functionality(c), 0.0, 1.0)
	var blood_f: float = 1.0
	var node = c.get("node")
	if manager != null and manager.has_method("_get_entity") and node != null:
		var ent = manager._get_entity(node)
		if ent != null:
			blood_f = clampf(_EntityAccess.get_blood_volume_from_node(ent) / 100.0, 0.0, 1.0)
	return perf * 0.45 + leg * 0.35 + blood_f * 0.2


## 0 = unfit to plug, 1 = peak readiness (for nonlinear curve).
static func _plug_effectiveness_normalized_0_1(manager: Node, c: Dictionary) -> float:
	var raw: float = _plug_effectiveness_score(manager, c)
	if raw <= -50.0:
		return 0.0
	return clampf(raw / 1.5, 0.0, 1.0)


## Single score: nonlinear penalty on low effectiveness can override raw proximity when fit allies exist elsewhere.
static func _plug_priority_score(manager: Node, prox_steps: int, c: Dictionary) -> float:
	var eff_n: float = _plug_effectiveness_normalized_0_1(manager, c)
	var exp_n: float = CombatConstants.FORMATION_PLUG_EFFECTIVENESS_EXPONENT
	var nonlinear: float = pow(eff_n, exp_n)
	var w: float = CombatConstants.FORMATION_PLUG_PROXIMITY_WEIGHT
	var prox_factor: float = 1.0 / (1.0 + w * float(max(0, prox_steps)))
	return nonlinear * prox_factor


## Chooses who fills `(fill_rank, file)`: every **vertical** occupant above the hole (all ranks) plus **lateral** same-rank neighbors.
## Picks max `_plug_priority_score` (nonlinear effectiveness × proximity softness) so injured closer ranks lose to able-bodied farther lanes/rows.
static func _select_best_plug_move_for_empty_cell(
	manager: Node,
	fid: String,
	slots: Dictionary,
	fill_rank: int,
	file: int,
	formation_ranks: int,
	nfiles: int,
	side_wanted: String,
	skip_intruded: bool
) -> Dictionary:
	var candidates: Array = []
	for search_rank in range(fill_rank + 1, formation_ranks):
		var ally_v: Variant = _combatant_from_slot_primary_living(
			manager, slots, Vector2i(search_rank, file), fid, side_wanted, skip_intruded
		)
		if ally_v != null:
			candidates.append(
				{"ally": ally_v, "kind": "vertical", "from_rank": search_rank, "from_file": file, "prox": search_rank - fill_rank}
			)
	for dfile in [-1, 1]:
		var nf: int = file + dfile
		if nf < 0 or nf >= nfiles:
			continue
		if not _FormationSlots.slot_has_any(slots, Vector2i(fill_rank, nf)):
			continue
		var ally_l: Variant = _combatant_from_slot_primary_living(
			manager, slots, Vector2i(fill_rank, nf), fid, side_wanted, skip_intruded
		)
		if ally_l == null:
			continue
		candidates.append(
			{"ally": ally_l, "kind": "lateral", "from_rank": fill_rank, "from_file": nf, "prox": 1}
		)
	if candidates.is_empty():
		return {}
	var best: Dictionary = candidates[0]
	var best_pri: float = _plug_priority_score(manager, int(best["prox"]), best["ally"])
	for i in range(1, candidates.size()):
		var cand: Dictionary = candidates[i]
		var pri: float = _plug_priority_score(manager, int(cand["prox"]), cand["ally"])
		if pri > best_pri:
			best = cand
			best_pri = pri
	return best


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
	ally["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT
	_FormationSlots.slot_set_single(slots, Vector2i(fill_rank, file), ally.id)
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var name_p: String = _EntityAccess.get_display_name(ally, ally.get("id", -1))
		if kind == "lateral":
			print(
				"[Combat] %s: %s slid file %d → %d (rank %d)" % [log_prefix, name_p, from_f, file, fill_rank]
			)
		else:
			print("[Combat] %s: %s advanced to rank %d (file %d)" % [log_prefix, name_p, fill_rank, file])
	manager._schedule_action_ready(ally.id, CombatConstants.READY_DELAY_AFTER_PROMOTION_S)


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
	for fill_rank in range(formation_ranks):
		if _FormationSlots.slot_has_any(slots, Vector2i(fill_rank, file)):
			continue
		var move: Dictionary = _select_best_plug_move_for_empty_cell(
			manager, fid, slots, fill_rank, file, formation_ranks, nfiles, side_wanted, true
		)
		if move.is_empty():
			break
		_apply_plug_move(manager, slots, move, fill_rank, file, "Vacancy plug")
		any_promoted = true
	return any_promoted


## Run vacancy plug on every file column so empty front cells do not persist while deeper ranks are alive (avoids soft deadlock: no enemy rank 0 while enemies remain).
## Repeats rounds so lateral slides that open a gap in a neighbor file get a chance to fill.
static func reconcile_vacancy_plugs_formation(manager: Node, fid: String) -> bool:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return false
	var nfiles: int = int(formation.get("files", 1))
	var any: bool = false
	for _round in range(CombatConstants.FORMATION_VACANCY_RECONCILE_MAX_ROUNDS):
		var round_changed: bool = false
		for file in range(nfiles):
			if apply_vacancy_plug_same_file(manager, fid, file):
				round_changed = true
				any = true
		if not round_changed:
			break
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
			if _FormationSlots.slot_has_any(slots, Vector2i(0, file)):
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
	var obstacles: Dictionary = formation.get("slot_obstacles", {})
	var key := Vector2i(r, f)
	if not obstacles.has(key):
		obstacles[key] = []
	obstacles[key].append(c.id)
	if formation.get("ranks", 1) > 1:
		var formation_ranks: int = formation.get("ranks", 1)
		var nfiles_death: int = int(formation.get("files", 1))
		for fill_rank in range(formation_ranks):
			if _FormationSlots.slot_has_any(slots, Vector2i(fill_rank, f)):
				continue
			var move_d: Dictionary = _select_best_plug_move_for_empty_cell(
				manager, fid, slots, fill_rank, f, formation_ranks, nfiles_death, str(c.side), true
			)
			if move_d.is_empty():
				break
			_apply_plug_move(manager, slots, move_d, fill_rank, f, "Plug")
	manager._recompute_zoc_and_distance()
	manager.notify_formation_changed(fid)
	manager._reschedule_back_rank_turns(fid)
