class_name CombatEventScheduler
extends RefCounted

## Sorted event queue, ACTION_READY scheduling, and back-rank recheck after formation changes.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func compare_events(manager: Node, a: Dictionary, b: Dictionary) -> bool:
	var at_a: float = a.get("resolve_at", 0.0)
	var at_b: float = b.get("resolve_at", 0.0)
	if at_a != at_b:
		return at_a < at_b
	var ca = manager._get_by_id(a.get("combatant_id", -1))
	var cb = manager._get_by_id(b.get("combatant_id", -1))
	var agi_a: int = ca.stats.get("agility", 100) if ca != null else 0
	var agi_b: int = cb.stats.get("agility", 100) if cb != null else 0
	if agi_a != agi_b:
		return agi_a > agi_b
	return a.get("combatant_id", 0) < b.get("combatant_id", 0)


static func sort_event_queue(manager: Node) -> void:
	manager.event_queue.sort_custom(func(a, b): return compare_events(manager, a, b))


static func schedule_event(manager: Node, ev: Dictionary) -> void:
	manager.event_queue.append(ev)
	sort_event_queue(manager)


static func get_next_action_ready_at(manager: Node, combatant_id: int) -> float:
	var best: float = -1.0
	for ev in manager.event_queue:
		if ev.get("type", "") == CombatConstants.EVENT_ACTION_READY and ev.get("combatant_id", -1) == combatant_id:
			var at: float = ev.get("resolve_at", 0.0)
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
		if ev.get("type", "") != CombatConstants.EVENT_ACTION_READY:
			continue
		var cid: int = int(ev.get("combatant_id", -1))
		if cid < 0:
			continue
		var at: float = float(ev.get("resolve_at", 0.0))
		if at <= clk:
			continue
		if not best_by_id.has(cid) or at < float(best_by_id[cid]):
			best_by_id[cid] = at
	return best_by_id


static func cancel_pending_action_ready(manager: Node, combatant_id: int) -> void:
	manager.event_queue = manager.event_queue.filter(func(ev: Dictionary) -> bool:
		return not (ev.get("type", "") == CombatConstants.EVENT_ACTION_READY and ev.get("combatant_id", -1) == combatant_id)
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
	var agi: float = float(c.stats.get("agility", 100))
	var cooldown: float = CombatConstants.COOLDOWN_ACTION_READY_BASE * (100.0 / maxf(50.0, agi))
	var off_until: float = c.get("off_balance_until", -1.0)
	if off_until > CombatTiming.now_seconds():
		cooldown /= CombatConstants.OFF_BALANCE_GAUGE_FILL_MULT
	var perf_mod: float = 1.0
	if c.node != null:
		if c.node.has_method("get_action_bar_performance_modifier"):
			perf_mod = c.node.get_action_bar_performance_modifier()
		elif c.node.has_method("get_performance_modifier"):
			perf_mod = c.node.get_performance_modifier()
	if perf_mod > 0.0:
		cooldown /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	return cooldown


static func schedule_initial_action_ready_events(manager: Node) -> void:
	for c in manager.combatants:
		if not c.alive or _EntityAccess.is_incapacitated(c):
			continue
		schedule_action_ready(manager, c.id, action_ready_cooldown(c))


static func reschedule_back_rank_turns(manager: Node, fid: String) -> void:
	for c in manager.combatants:
		if not c.alive or c.get("formation_id", "") != fid:
			continue
		if c.get("rank", 0) <= 0 or c.state != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		schedule_action_ready(manager, c.id, CombatConstants.READY_DELAY_FORMATION_RECHECK_S)


## Snapshot alive combatants' `(rank, file)` for anyone in a registered formation. Used with
## `ids_with_changed_rank_file_since_snapshot` so vacancy reconcile only resets **real** moves.
static func snapshot_rank_file_placements(manager: Node) -> Dictionary:
	var out: Dictionary = {}
	if manager == null or not manager.formations is Dictionary:
		return out
	var fm: Dictionary = manager.formations
	for c in manager.combatants:
		if c == null or not c.get("alive", true):
			continue
		var fid: String = str(c.get("formation_id", ""))
		if fid.is_empty() or not fm.has(fid):
			continue
		out[c.id] = Vector2i(int(c.get("rank", 0)), int(c.get("file", 0)))
	return out


## Combatants whose `(rank, file)` changed vs `snapshot_rank_file_placements`, or newly tracked line bodies.
static func ids_with_changed_rank_file_since_snapshot(manager: Node, snap: Dictionary) -> Array:
	var changed: Array = []
	if manager == null or snap == null:
		return changed
	if not manager.formations is Dictionary:
		return changed
	var fm: Dictionary = manager.formations
	for c in manager.combatants:
		if c == null or not c.get("alive", true):
			continue
		var fid: String = str(c.get("formation_id", ""))
		if fid.is_empty() or not fm.has(fid):
			continue
		var cur := Vector2i(int(c.get("rank", 0)), int(c.get("file", 0)))
		if not snap.has(c.id):
			changed.append(c.id)
			continue
		var prev: Variant = snap[c.id]
		if prev is Vector2i and (prev as Vector2i) != cur:
			changed.append(c.id)
	return changed


## After vacancy-style reconcile: only **moved** reserve-line units (`rank`>0, waiting) get a short recheck delay.
## Promoted front rank (`rank` 0) is excluded here; plug paths schedule them with `READY_DELAY_AFTER_PROMOTION_S`.
static func reschedule_formation_recheck_for_moved_back_ranks(manager: Node, moved_combatant_ids: Array) -> void:
	for mid in moved_combatant_ids:
		var cid: int = int(mid)
		var c = manager._get_by_id(cid) if manager.has_method("_get_by_id") else null
		if c == null or not c.get("alive", true):
			continue
		if int(c.get("rank", 0)) <= 0:
			continue
		if str(c.get("state", "")) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		schedule_action_ready(manager, cid, CombatConstants.READY_DELAY_FORMATION_RECHECK_S)
