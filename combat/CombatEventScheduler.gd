class_name CombatEventScheduler
extends RefCounted

## Sorted event queue, ACTION_READY scheduling, and back-rank recheck after formation changes.
## Placement snapshot + back-rank recheck use **`ZoneOfControl.zone_geometry_for_combatant`** (same fid as formation dict reads).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")


static func compare_events(manager: Node, a: Variant, b: Variant) -> bool:
	if typeof(a) != TYPE_DICTIONARY:
		return false
	if typeof(b) != TYPE_DICTIONARY:
		return true
	var ad: Dictionary = a as Dictionary
	var bd: Dictionary = b as Dictionary
	var at_a: float = ad.get("resolve_at", 0.0)
	var at_b: float = bd.get("resolve_at", 0.0)
	if at_a != at_b:
		return at_a < at_b
	var ca: Dictionary = _EntityAccess.manager_get_combatant(manager, int(ad.get("combatant_id", -1)))
	var cb: Dictionary = _EntityAccess.manager_get_combatant(manager, int(bd.get("combatant_id", -1)))
	var agi_a: int = int(_EntityAccess.stats_dict(ca).get("agility", 100)) if not ca.is_empty() else 0
	var agi_b: int = int(_EntityAccess.stats_dict(cb).get("agility", 100)) if not cb.is_empty() else 0
	if agi_a != agi_b:
		return agi_a > agi_b
	return ad.get("combatant_id", 0) < bd.get("combatant_id", 0)


static func sort_event_queue(manager: Node) -> void:
	manager.event_queue.sort_custom(func(a, b): return compare_events(manager, a, b))


static func schedule_event(manager: Node, ev: Dictionary) -> void:
	if _MedicalPhase.should_block_scheduled_event(manager, ev):
		return
	manager.event_queue.append(ev)
	sort_event_queue(manager)


static func get_next_action_ready_at(manager: Node, combatant_id: int) -> float:
	var best: float = -1.0
	for ev in manager.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var evd: Dictionary = ev as Dictionary
		if evd.get("type", "") == CombatConstants.EVENT_ACTION_READY and evd.get("combatant_id", -1) == combatant_id:
			var at: float = evd.get("resolve_at", 0.0)
			if at > _EntityAccess.combat_clock_float(manager) and (best < 0.0 or at < best):
				best = at
	return best


## Single pass over `event_queue`: earliest future `EVENT_ACTION_READY` per `combatant_id` (vs `combat_clock`).
## Use for UI snapshots instead of O(combatants × queue) per-frame scans.
static func build_next_action_ready_times(manager: Node) -> Dictionary:
	var best_by_id: Dictionary = {}
	if manager == null:
		return best_by_id
	var clk: float = _EntityAccess.combat_clock_float(manager)
	for ev in manager.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var evb: Dictionary = ev as Dictionary
		if evb.get("type", "") != CombatConstants.EVENT_ACTION_READY:
			continue
		var cid: int = int(evb.get("combatant_id", -1))
		if cid < 0:
			continue
		var at: float = float(evb.get("resolve_at", 0.0))
		if at <= clk:
			continue
		if not best_by_id.has(cid) or at < float(best_by_id[cid]):
			best_by_id[cid] = at
	return best_by_id


static func get_pending_melee_attack_resolve_at(manager: Node, combatant_id: int) -> float:
	if manager == null or combatant_id < 0:
		return -1.0
	for ev in manager.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var evd: Dictionary = ev as Dictionary
		if (
			evd.get("type", "") == CombatConstants.EVENT_MELEE_ATTACK
			and int(evd.get("combatant_id", -1)) == combatant_id
		):
			return float(evd.get("resolve_at", -1.0))
	return -1.0


static func set_pending_melee_attack_resolve_at(
	manager: Node, combatant_id: int, resolve_at: float
) -> bool:
	if manager == null or combatant_id < 0:
		return false
	if _MedicalPhase.should_block_scheduled_event(
		manager,
		{
			"type": CombatConstants.EVENT_MELEE_ATTACK,
			"combatant_id": combatant_id,
			"resolve_at": resolve_at,
			"data": {},
		}
	):
		cancel_pending_melee_attack(manager, combatant_id)
		return false
	for ev in manager.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var evd: Dictionary = ev as Dictionary
		if (
			evd.get("type", "") == CombatConstants.EVENT_MELEE_ATTACK
			and int(evd.get("combatant_id", -1)) == combatant_id
		):
			evd["resolve_at"] = resolve_at
			sort_event_queue(manager)
			return true
	return false


static func cancel_pending_melee_attack(manager: Node, combatant_id: int) -> void:
	if manager == null or combatant_id < 0:
		return
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if typeof(ev) != TYPE_DICTIONARY:
			return false
		var evc: Dictionary = ev as Dictionary
		return not (
			evc.get("type", "") == CombatConstants.EVENT_MELEE_ATTACK
			and int(evc.get("combatant_id", -1)) == combatant_id
		)
	)


static func cancel_pending_action_ready(manager: Node, combatant_id: int) -> void:
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if typeof(ev) != TYPE_DICTIONARY:
			return false
		var evc: Dictionary = ev as Dictionary
		return not (
			evc.get("type", "") == CombatConstants.EVENT_ACTION_READY and evc.get("combatant_id", -1) == combatant_id
		)
	)


static func cancel_pending_recovery_end(manager: Node, combatant_id: int) -> void:
	if manager == null or combatant_id < 0:
		return
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if typeof(ev) != TYPE_DICTIONARY:
			return false
		var evc: Dictionary = ev as Dictionary
		return not (
			evc.get("type", "") == CombatConstants.EVENT_RECOVERY_END
			and int(evc.get("combatant_id", -1)) == combatant_id
		)
	)


## Drop queued formation resolves that involve `combatant_id` (initiator or swap/rotate partner).
static func cancel_pending_formation_events_for_combatant(manager: Node, combatant_id: int) -> void:
	if manager == null or combatant_id < 0:
		return
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if typeof(ev) != TYPE_DICTIONARY:
			return false
		var evc: Dictionary = ev as Dictionary
		var ev_type: String = str(evc.get("type", ""))
		if ev_type == CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE:
			return int(evc.get("combatant_id", -1)) != combatant_id
		if (
			ev_type == CombatConstants.EVENT_SWAP_RANK_RESOLVE
			or ev_type == CombatConstants.EVENT_ROTATE_FILE_RESOLVE
		):
			var cid: int = int(evc.get("combatant_id", -1))
			var pid: int = -1
			var dr: Variant = evc.get("data", null)
			if dr is Dictionary:
				pid = int((dr as Dictionary).get("partner_id", -1))
			return cid != combatant_id and pid != combatant_id
		return true
	)


## Drop queued melee, turn-ready, recovery-end, and formation resolves for one combatant (medical-phase teardown).
static func cancel_pending_combat_events_for_combatant(manager: Node, combatant_id: int) -> void:
	cancel_pending_melee_attack(manager, combatant_id)
	cancel_pending_action_ready(manager, combatant_id)
	cancel_pending_recovery_end(manager, combatant_id)
	cancel_pending_formation_events_for_combatant(manager, combatant_id)


## Drop queued `swap_rank_resolve` events that involve either combatant (stale resolve after restarts/bumps).
static func cancel_pending_swap_rank_pair_events(manager: Node, id_a: int, id_b: int) -> void:
	if manager == null or id_a < 0 or id_b < 0:
		return
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if typeof(ev) != TYPE_DICTIONARY:
			return true
		var evc: Dictionary = ev as Dictionary
		if evc.get("type", "") != CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			return true
		var cid: int = int(evc.get("combatant_id", -1))
		var pid: int = -1
		var dr: Variant = evc.get("data", null)
		if dr is Dictionary:
			pid = int((dr as Dictionary).get("partner_id", -1))
		var touches: bool = cid == id_a or cid == id_b or pid == id_a or pid == id_b
		return not touches
	)


static func schedule_action_ready(manager: Node, combatant_id: int, delay_s: float) -> void:
	var ev: Dictionary = {
		"type": CombatConstants.EVENT_ACTION_READY,
		"combatant_id": combatant_id,
		"resolve_at": _EntityAccess.combat_clock_plus(manager, delay_s),
		"data": {},
	}
	cancel_pending_action_ready(manager, combatant_id)
	if _MedicalPhase.should_block_scheduled_event(manager, ev):
		return
	var c_ready: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if (
		not c_ready.is_empty()
		and _MobilityRetreat.cannot_commit_melee(c_ready)
		and not _EntityAccess.can_flee_or_fall_back(c_ready)
	):
		return
	schedule_event(manager, ev)


## `delay_s < 0` uses **`action_ready_cooldown(c)`** (same as **`CombatManager._action_ready_cooldown`**).
static func schedule_action_ready_for_combatant(
	manager: Node, c: Dictionary, delay_s: float = -1.0
) -> void:
	if manager == null or c.is_empty():
		return
	var delay: float = delay_s if delay_s >= 0.0 else action_ready_cooldown(c)
	schedule_action_ready(manager, _EntityAccess.id_int(c), delay)


static func action_ready_cooldown(c: Dictionary) -> float:
	var agi: float = float(_EntityAccess.stats_dict(c).get("agility", 100))
	var cooldown: float = CombatConstants.COOLDOWN_ACTION_READY_BASE * (100.0 / maxf(50.0, agi))
	var off_until: float = c.get("off_balance_until", -1.0)
	if off_until > CombatTiming.now_seconds():
		cooldown /= CombatConstants.OFF_BALANCE_GAUGE_FILL_MULT
	var perf_mod: float = _EntityAccess.get_action_bar_performance_modifier(c)
	if perf_mod > 0.0:
		cooldown /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	var st_ratio: float = _EntityAccess.stamina_ratio(c)
	cooldown *= CombatConstants.action_ready_stamina_delay_mult(st_ratio)
	cooldown *= CombatConstants.armor_burden_action_ready_mult(c)
	return cooldown


static func schedule_initial_action_ready_events(manager: Node) -> void:
	var pending: Array = []
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.is_unconscious(c):
			continue
		if manager.medical_phase and _MedicalPhase.is_losing_side(manager, c):
			continue
		pending.append(c)
	if CombatConstants.is_feature_initiative_order_enabled() and pending.size() > 1:
		pending.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				return CombatConstants.compare_combatants_for_initiative_order(a, b)
		)
		for i in pending.size():
			var c_stagger: Dictionary = pending[i]
			var delay: float = action_ready_cooldown(c_stagger) + float(i) * CombatConstants.INITIATIVE_ORDER_STAGGER_STEP_S
			schedule_action_ready(manager, _EntityAccess.id_int(c_stagger), delay)
		return
	for c in pending:
		schedule_action_ready(manager, _EntityAccess.id_int(c), action_ready_cooldown(c))


static func reschedule_back_rank_turns(manager: Node, fid: String) -> void:
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, fid):
			continue
		if manager.medical_phase and _MedicalPhase.is_losing_side(manager, c):
			continue
		if _EntityAccess.rank_int(c) < 1 or _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_unconscious(c):
			continue
		schedule_action_ready(manager, _EntityAccess.id_int(c), CombatConstants.READY_DELAY_FORMATION_RECHECK_S)


## III-6: after rank-0 acts, same-file reserves re-evaluate (depth spear lane / new ZoC bands).
static func reschedule_same_file_depth_after_front_turn(manager: Node, front_combatant_id: int) -> void:
	if manager == null or front_combatant_id < 0:
		return
	var front: Dictionary = _EntityAccess.manager_get_combatant(manager, front_combatant_id)
	if front.is_empty() or _EntityAccess.rank_int(front) != 0:
		return
	if manager.medical_phase and _MedicalPhase.is_losing_side(manager, front):
		return
	var fid: String = _EntityAccess.formation_id_str(front)
	if fid.is_empty():
		return
	var file: int = _EntityAccess.file_int(front)
	for c in manager.combatants:
		if not _EntityAccess.is_living_same_side(front, c):
			continue
		if _EntityAccess.formation_id_str(c) != fid:
			continue
		if _EntityAccess.file_int(c) != file:
			continue
		if _EntityAccess.rank_int(c) <= 0:
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_unconscious(c):
			continue
		schedule_action_ready(
			manager, _EntityAccess.id_int(c), CombatConstants.READY_DELAY_FORMATION_RECHECK_S
		)


## III-6: after rank>=1 acts, deeper same-file reserves re-evaluate (stacked depth column).
static func reschedule_same_file_depth_after_reserve_turn(manager: Node, reserve_combatant_id: int) -> void:
	if manager == null or reserve_combatant_id < 0:
		return
	var actor: Dictionary = _EntityAccess.manager_get_combatant(manager, reserve_combatant_id)
	if actor.is_empty() or _EntityAccess.rank_int(actor) < 1:
		return
	if manager.medical_phase and _MedicalPhase.is_losing_side(manager, actor):
		return
	var fid: String = _EntityAccess.formation_id_str(actor)
	if fid.is_empty():
		return
	var file: int = _EntityAccess.file_int(actor)
	var actor_rank: int = _EntityAccess.rank_int(actor)
	for c in manager.combatants:
		if not _EntityAccess.is_living_same_side(actor, c):
			continue
		if _EntityAccess.formation_id_str(c) != fid:
			continue
		if _EntityAccess.file_int(c) != file:
			continue
		if _EntityAccess.rank_int(c) <= actor_rank:
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_unconscious(c):
			continue
		schedule_action_ready(
			manager, _EntityAccess.id_int(c), CombatConstants.READY_DELAY_FORMATION_RECHECK_S
		)


## III-6: after rank-0 **`rotate_file`** completes, reserves in both swapped file columns re-evaluate.
static func reschedule_same_file_depth_after_rotate_file(
	manager: Node, fid: String, file_a: int, file_b: int
) -> void:
	if manager == null or fid.is_empty():
		return
	var files: Array[int] = []
	if file_a >= 0:
		files.append(file_a)
	if file_b >= 0 and file_b != file_a:
		files.append(file_b)
	for file in files:
		for c in manager.combatants:
			if typeof(c) != TYPE_DICTIONARY:
				continue
			if _EntityAccess.formation_id_str(c) != fid:
				continue
			if not _EntityAccess.alive_bool(c):
				continue
			if _EntityAccess.file_int(c) != file:
				continue
			if _EntityAccess.rank_int(c) <= 0:
				continue
			if manager.medical_phase and _MedicalPhase.is_losing_side(manager, c):
				continue
			if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
				continue
			if _EntityAccess.is_unconscious(c):
				continue
			schedule_action_ready(
				manager, _EntityAccess.id_int(c), CombatConstants.READY_DELAY_FORMATION_RECHECK_S
			)


## III-6: rank-2+ reserves in a file column re-evaluate after rank shuffle (swap resolve, solo fall_back).
static func reschedule_same_file_depth_rank2_plus(
	manager: Node, fid: String, file: int
) -> void:
	if manager == null or fid.is_empty() or file < 0:
		return
	for c in manager.combatants:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		if _EntityAccess.formation_id_str(c) != fid:
			continue
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.file_int(c) != file:
			continue
		if _EntityAccess.rank_int(c) < 2:
			continue
		if manager.medical_phase and _MedicalPhase.is_losing_side(manager, c):
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_unconscious(c):
			continue
		schedule_action_ready(
			manager, _EntityAccess.id_int(c), CombatConstants.READY_DELAY_FORMATION_RECHECK_S
		)


## Host-line formation record for placement tracking, or `{}` when not on a line grid.
static func _line_formation_record_for_placement(manager: Node, c: Variant) -> Dictionary:
	if c == null or not _EntityAccess.alive_bool(c, true):
		return {}
	var ctx: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	if _ZoneOfControl.zone_geometry_fid_from_pack(ctx).is_empty():
		return {}
	return _ZoneOfControl.zone_geometry_formation_from_pack(ctx)


## Snapshot alive combatants' `(rank, file)` for anyone in a registered formation. Used with
## `ids_with_changed_rank_file_since_snapshot` so vacancy reconcile only resets **real** moves.
static func snapshot_rank_file_placements(manager: Node) -> Dictionary:
	var out: Dictionary = {}
	if manager == null or not manager.formations is Dictionary:
		return out
	for c in manager.combatants:
		if _line_formation_record_for_placement(manager, c).is_empty():
			continue
		var cid: int = _EntityAccess.id_int(c)
		out[cid] = Vector2i(_EntityAccess.rank_int(c), _EntityAccess.file_int(c))
	return out


## Combatants whose `(rank, file)` changed vs `snapshot_rank_file_placements`, or newly tracked line bodies.
static func ids_with_changed_rank_file_since_snapshot(manager: Node, snap: Dictionary) -> Array:
	var changed: Array = []
	if manager == null or snap == null:
		return changed
	if not manager.formations is Dictionary:
		return changed
	for c in manager.combatants:
		if _line_formation_record_for_placement(manager, c).is_empty():
			continue
		var cur := Vector2i(_EntityAccess.rank_int(c), _EntityAccess.file_int(c))
		var cid2: int = _EntityAccess.id_int(c)
		if not snap.has(cid2):
			changed.append(cid2)
			continue
		var prev: Variant = snap[cid2]
		if prev is Vector2i and (prev as Vector2i) != cur:
			changed.append(cid2)
	return changed


## After vacancy-style reconcile: only **moved** reserve-line units (`rank`>0, waiting) get a short recheck delay.
## Promoted front rank (`rank` 0) is excluded here; plug paths schedule them with `READY_DELAY_AFTER_PROMOTION_S`.
static func reschedule_formation_recheck_for_moved_back_ranks(manager: Node, moved_combatant_ids: Array) -> void:
	for mid in moved_combatant_ids:
		var cid: int = int(mid)
		var c: Dictionary = _EntityAccess.manager_get_combatant(manager, cid)
		if c.is_empty() or not _EntityAccess.alive_bool(c, true):
			continue
		if _EntityAccess.rank_int(c) < 1:
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_unconscious(c):
			continue
		if manager.medical_phase and _MedicalPhase.is_losing_side(manager, c):
			continue
		schedule_action_ready(manager, cid, CombatConstants.READY_DELAY_FORMATION_RECHECK_S)
