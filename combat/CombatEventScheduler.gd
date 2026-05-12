class_name CombatEventScheduler
extends RefCounted

## Sorted event queue, ACTION_READY scheduling, and back-rank recheck after formation changes.
## Placement snapshot + back-rank recheck use **`ZoneOfControl.formation_id_for_zone_geometry`** / **`formation_dict_for_zone_geometry`** so **intruders** on a host grid align with that formation’s `notify_formation_changed` / reconcile passes.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")


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
	var ca: Dictionary = _EntityAccess.combatant_dict_or_empty(manager._get_by_id(ad.get("combatant_id", -1)))
	var cb: Dictionary = _EntityAccess.combatant_dict_or_empty(manager._get_by_id(bd.get("combatant_id", -1)))
	var agi_a: int = int(_EntityAccess.stats_dict(ca).get("agility", 100)) if not ca.is_empty() else 0
	var agi_b: int = int(_EntityAccess.stats_dict(cb).get("agility", 100)) if not cb.is_empty() else 0
	if agi_a != agi_b:
		return agi_a > agi_b
	return ad.get("combatant_id", 0) < bd.get("combatant_id", 0)


static func sort_event_queue(manager: Node) -> void:
	manager.event_queue.sort_custom(func(a, b): return compare_events(manager, a, b))


static func schedule_event(manager: Node, ev: Dictionary) -> void:
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
			if at > manager.combat_clock and (best < 0.0 or at < best):
				best = at
	return best


## Single pass over `event_queue`: earliest future `EVENT_ACTION_READY` per `combatant_id` (vs `combat_clock`).
## Use for UI snapshots instead of O(combatants × queue) per-frame scans.
static func build_next_action_ready_times(manager: Node) -> Dictionary:
	var best_by_id: Dictionary = {}
	if manager == null:
		return best_by_id
	var clk: float = float(manager.combat_clock)
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


static func cancel_pending_action_ready(manager: Node, combatant_id: int) -> void:
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if typeof(ev) != TYPE_DICTIONARY:
			return false
		var evc: Dictionary = ev as Dictionary
		return not (
			evc.get("type", "") == CombatConstants.EVENT_ACTION_READY and evc.get("combatant_id", -1) == combatant_id
		)
	)


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
	cancel_pending_action_ready(manager, combatant_id)
	schedule_event(manager, {
		"type": CombatConstants.EVENT_ACTION_READY,
		"combatant_id": combatant_id,
		"resolve_at": manager.combat_clock + delay_s,
		"data": {}
	})


static func action_ready_cooldown(c: Dictionary) -> float:
	var agi: float = float(_EntityAccess.stats_dict(c).get("agility", 100))
	var cooldown: float = CombatConstants.COOLDOWN_ACTION_READY_BASE * (100.0 / maxf(50.0, agi))
	var off_until: float = c.get("off_balance_until", -1.0)
	if off_until > CombatTiming.now_seconds():
		cooldown /= CombatConstants.OFF_BALANCE_GAUGE_FILL_MULT
	var perf_mod: float = 1.0
	var sched_node: Node = _EntityAccess.scene_node(c)
	if sched_node != null:
		if sched_node.has_method("get_action_bar_performance_modifier"):
			perf_mod = sched_node.get_action_bar_performance_modifier()
		elif sched_node.has_method("get_performance_modifier"):
			perf_mod = sched_node.get_performance_modifier()
	if perf_mod > 0.0:
		cooldown /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	return cooldown


static func schedule_initial_action_ready_events(manager: Node) -> void:
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.is_incapacitated(c):
			continue
		schedule_action_ready(manager, _EntityAccess.id_int(c), action_ready_cooldown(c))


static func reschedule_back_rank_turns(manager: Node, fid: String) -> void:
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or _ZoneOfControl.formation_id_for_zone_geometry(manager, c) != fid:
			continue
		if _EntityAccess.rank_int(c) <= 0 or _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		schedule_action_ready(manager, _EntityAccess.id_int(c), CombatConstants.READY_DELAY_FORMATION_RECHECK_S)


## Snapshot alive combatants' `(rank, file)` for anyone in a registered formation. Used with
## `ids_with_changed_rank_file_since_snapshot` so vacancy reconcile only resets **real** moves.
static func snapshot_rank_file_placements(manager: Node) -> Dictionary:
	var out: Dictionary = {}
	if manager == null or not manager.formations is Dictionary:
		return out
	for c in manager.combatants:
		if c == null or not _EntityAccess.alive_bool(c, true):
			continue
		var fid_snap: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
		if fid_snap.is_empty():
			continue
		var frec: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_snap)
		if frec.is_empty():
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
		if c == null or not _EntityAccess.alive_bool(c, true):
			continue
		var fid_snap2: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
		if fid_snap2.is_empty():
			continue
		var frec2: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_snap2)
		if frec2.is_empty():
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
		var c: Dictionary = (
			_EntityAccess.combatant_dict_or_empty(manager._get_by_id(cid))
			if manager.has_method("_get_by_id")
			else {}
		)
		if c.is_empty() or not _EntityAccess.alive_bool(c, true):
			continue
		if _EntityAccess.rank_int(c) <= 0:
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		schedule_action_ready(manager, cid, CombatConstants.READY_DELAY_FORMATION_RECHECK_S)
