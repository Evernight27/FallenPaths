extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)
signal enemies_eliminated(winner_side)
signal combatant_health_changed(combatant_id)

var combatants := []
var medical_phase: bool = false
var medical_phase_winner: String = ""
# FF4 migration Phase 0: event queue (array → min-heap in Phase 1), combat clock, encounter, formations.
var event_queue: Array = []
var combat_clock: float = 0.0
var encounter: Dictionary = {}
var formations: Dictionary = {}

const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _StandingHelper := preload("res://combat/CombatStandingHelper.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")

## Returns the node that holds health/wounds (CoreEntity for enemies; CombatBody for Character). Use for all health reads.
func _get_entity(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_medical_entity"):
		var e = node.get_medical_entity()
		return e if e != null else node
	return node

func _refresh_combatant_stats(c: Dictionary) -> void:
	"""Keep combatant stats in sync with node (pain, consciousness, blood, etc.) for UI and gauge fill.
	Uses _get_entity for unified health access (party Character -> CombatBody, enemies -> self)."""
	if c.node == null:
		return
	var entity = _get_entity(c.node)
	if entity == null:
		return
	_StatsSync.sync_from_entity(entity, c.stats)

func register(node: Node, side: String) -> int:
	var id = combatants.size()
	var entity = _get_entity(node)
	var stats = _StatsSync.sync_from_entity_for_register(entity if entity != null else node)
	combatants.append({
		"id": id,
		"node": node,
		"side": side,
		"stats": stats,
		"gauge": 0.0,
		"alive": true,
		"state": CombatConstants.STATE_WAITING,
		"state_timer": 0.0,
		"state_duration": 0.0,
		"pending_attack": {},
		"receiving_medical_count": 0,
		"guard": 1.0,
		"guard_line": CombatConstants.GUARD_DEFAULT,
		"guard_zone": "head",
		"stamina": CombatConstants.STAMINA_MAX,
		# FF4 formation fields (Phase 0). Phase 3 assigns rank/file.
		"rank": 0,
		"file": 0,
		"formation_id": "",
		"distance_to": {},
		"engaged_with_id": -1,
		"engagement_angle": "front",
		"zone_id": "",
		"occupied_zone_id": "",
		"stance": CombatConstants.STANCE_BALANCED,
		"stance_preference": "balanced",
	})
	# Connect health_changed so UI can refresh when consciousness/pain/blood changes
	if entity != null and entity.has_signal("health_changed"):
		entity.health_changed.connect(_on_entity_health_changed.bind(id))
	# Connect creature_incapacitated: same refresh as health_changed when consciousness drops below threshold
	if entity != null and entity.has_signal("creature_incapacitated"):
		entity.creature_incapacitated.connect(_on_entity_health_changed.bind(id))
	return id

func _on_entity_health_changed(combatant_id: int) -> void:
	emit_signal("combatant_health_changed", combatant_id)

## Start combat. Optional player_formation and enemy_formation presets: { files, ranks, density }.
## When provided, builds formations and assigns rank/file to combatants (spawn order).
func start(player_formation: Dictionary = {}, enemy_formation: Dictionary = {}):
	medical_phase = false
	medical_phase_winner = ""
	event_queue.clear()
	combat_clock = 0.0
	if encounter.is_empty():
		encounter = {"ambush_type": CombatConstants.AMBUSH_TYPE_NONE, "ambush_penalty": 0.0}
	formations.clear()
	# Build formations from presets and assign rank/file (always; use defaults when preset empty)
	_build_formations_and_assign_slots(player_formation, enemy_formation)
	# Phase 1: Schedule initial EVENT_ACTION_READY for each alive combatant (staggered by agility).
	_schedule_initial_action_ready_events()
	set_process(true)

func _build_formations_and_assign_slots(player_formation: Dictionary, enemy_formation: Dictionary) -> void:
	var player_count: int = 0
	var enemy_count: int = 0
	for c in combatants:
		if c.side == "player":
			player_count += 1
		else:
			enemy_count += 1
	var p_preset: Dictionary = player_formation
	var e_preset: Dictionary = enemy_formation
	if p_preset.is_empty():
		p_preset = _FormationPreset.default_for_count(player_count)
	if e_preset.is_empty():
		e_preset = _FormationPreset.default_for_count(enemy_count)
	# Option A: files = front-line count, ranks = depth. front_count overrides files when present.
	var p_files: int = p_preset.get("front_count", p_preset.get("files", 1))
	var p_ranks: int = p_preset.get("ranks", 1)
	var e_files: int = e_preset.get("front_count", e_preset.get("files", 1))
	var e_ranks: int = e_preset.get("ranks", 1)
	if p_preset.has("front_count") or not p_preset.has("ranks"):
		p_ranks = int(ceilf(float(maxi(1, player_count)) / float(maxi(1, p_files))))
	if e_preset.has("front_count") or not e_preset.has("ranks"):
		e_ranks = int(ceilf(float(maxi(1, enemy_count)) / float(maxi(1, e_files))))
	formations["player"] = {"files": p_files, "ranks": p_ranks, "density": p_preset.get("density", "normal"), "side": "player", "slots": {}, "zone_control": {}}
	formations["enemy"] = {"files": e_files, "ranks": e_ranks, "density": e_preset.get("density", "normal"), "side": "enemy", "slots": {}, "zone_control": {}}
	# Fill rank 0 first (spawn order): first files units -> rank 0, next files -> rank 1, etc.
	var pi: int = 0
	var ei: int = 0
	for c in combatants:
		if c.side == "player":
			var r: int = int(floorf(pi / float(p_files)))
			var f: int = pi % p_files
			c.rank = r
			c.file = f
			c.formation_id = "player"
			formations["player"].slots[Vector2i(r, f)] = c.id
			pi += 1
		else:
			var r: int = int(floorf(ei / float(e_files)))
			var f: int = ei % e_files
			c.rank = r
			c.file = f
			c.formation_id = "enemy"
			formations["enemy"].slots[Vector2i(r, f)] = c.id
			ei += 1
	# Phase 2: Initialize pair-wise distance_to. All opponents start at mid (spear can attack; others need close).
	for c in combatants:
		c.distance_to = {}
		for opp in combatants:
			if opp.side != c.side and opp.alive:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_MID

## Phase 1: Schedule EVENT_ACTION_READY for each alive combatant at combat start.
## Stagger by agility: faster units ready sooner. Tie-break: agility desc, then combatant_id asc.
func _schedule_initial_action_ready_events() -> void:
	for c in combatants:
		if not c.alive or _EntityAccess.is_incapacitated(c):
			continue
		var cooldown: float = _action_ready_cooldown(c)
		_schedule_event({
			"type": CombatConstants.EVENT_ACTION_READY,
			"combatant_id": c.id,
			"resolve_at": combat_clock + cooldown,
			"data": {}
		})

## Cooldown until next ACTION_READY. Replicates gauge fill: agility 100 -> ~2s.
## Off-balance adds tempo penalty (slower recovery). Performance modifier from pain/consciousness.
func _action_ready_cooldown(c: Dictionary) -> float:
	var agi: float = float(c.stats.get("agility", 100))
	var cooldown: float = CombatConstants.COOLDOWN_ACTION_READY_BASE * (100.0 / maxf(50.0, agi))
	var off_until: float = c.get("off_balance_until", -1.0)
	if off_until > CombatTiming.now_seconds():
		cooldown /= CombatConstants.OFF_BALANCE_GAUGE_FILL_MULT  # Longer when off-balance
	var perf_mod: float = 1.0
	if c.node != null:
		if c.node.has_method("get_action_bar_performance_modifier"):
			perf_mod = c.node.get_action_bar_performance_modifier()
		elif c.node.has_method("get_performance_modifier"):
			perf_mod = c.node.get_performance_modifier()
	if perf_mod > 0.0:
		cooldown /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	return cooldown

## Insert event into queue. Queue sorted by resolve_at; tie-break: agility desc, combatant_id asc.
func _schedule_event(ev: Dictionary) -> void:
	event_queue.append(ev)
	event_queue.sort_custom(_event_sort)

func _event_sort(a: Dictionary, b: Dictionary) -> bool:
	var at_a: float = a.get("resolve_at", 0.0)
	var at_b: float = b.get("resolve_at", 0.0)
	if at_a != at_b:
		return at_a < at_b
	var ca = _get_by_id(a.get("combatant_id", -1))
	var cb = _get_by_id(b.get("combatant_id", -1))
	var agi_a: int = ca.stats.get("agility", 100) if ca != null else 0
	var agi_b: int = cb.stats.get("agility", 100) if cb != null else 0
	if agi_a != agi_b:
		return agi_a > agi_b  # Higher agility first
	return a.get("combatant_id", 0) < b.get("combatant_id", 0)

## Pop and handle all events with resolve_at <= combat_clock.
func _process_event_queue() -> void:
	while event_queue.size() > 0 and event_queue[0].get("resolve_at", 0.0) <= combat_clock:
		var ev: Dictionary = event_queue.pop_front()
		_handle_event(ev)

func _handle_event(ev: Dictionary) -> void:
	var ev_type: String = ev.get("type", "")
	var cid: int = ev.get("combatant_id", -1)
	var c = _get_by_id(cid)
	if c != null and not c.alive:
		return
	match ev_type:
		CombatConstants.EVENT_ACTION_READY:
			_handle_action_ready(c)
		CombatConstants.EVENT_MELEE_ATTACK:
			_handle_melee_attack(c)
		CombatConstants.EVENT_RECOVERY_END:
			_handle_recovery_end(c)
		CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			_handle_swap_rank_resolve(ev)

func _handle_action_ready(c: Dictionary) -> void:
	if c == null or not c.alive or _EntityAccess.is_incapacitated(c):
		return
	if c.state != CombatConstants.STATE_WAITING:
		if CombatConstants.COMBAT_EVENT_DEBUG:
			var who: String = _EntityAccess.get_display_name(c) if c != null else "?"
			print("[Combat] EVENT_ACTION_READY skipped: %s (state=%s — hit/interrupted before turn; will act after recovery)" % [who, c.state])
		return
	c.gauge = 100.0  # For AvailableActionsBuilder and receiving_medical compatibility
	c.erase("action_cooldown_until")  # Clear close cooldown when turn fires
	if c.side == "player":
		emit_signal("turn_ready", c.id)
	else:
		var actions: Array = get_available_actions(c.id)
		if actions.is_empty():
			var tgt = _find_first_opponent(c.side)
			if tgt != null:
				var can_attack: bool = true
				if c.node != null and c.node.has_method("get_attacking_arm"):
					can_attack = not c.node.get_attacking_arm().is_empty()
				if can_attack:
					_WindUpStarter.start(self, c.id, tgt.id)
					_schedule_event({
						"type": CombatConstants.EVENT_MELEE_ATTACK,
						"combatant_id": c.id,
						"resolve_at": combat_clock + c.state_duration,
						"data": {}
					})
				else:
					var who_skip: String = _EntityAccess.get_display_name(c)
					print("[Combat] %s has no functional arm; skip turn (short recovery)." % who_skip)
					_StateHandlers.enter_short_recovery(c)
					_schedule_event({
						"type": CombatConstants.EVENT_RECOVERY_END,
						"combatant_id": c.id,
						"resolve_at": combat_clock + 0.8,
						"data": {}
					})
			else:
				# No opponents left; schedule next ready
				_schedule_event({
					"type": CombatConstants.EVENT_ACTION_READY,
					"combatant_id": c.id,
					"resolve_at": combat_clock + _action_ready_cooldown(c),
					"data": {}
				})
		else:
			var choice = CombatAIActionPicker.pick(actions, c.id, self)
			var opts: Dictionary = CombatAIActionPicker.opts_from_choice(choice)
			resolve_action(c.id, choice.target_id, choice.get("move_id", ""), opts)

func _handle_melee_attack(c: Dictionary) -> void:
	if c == null or not c.alive or c.state != CombatConstants.STATE_WIND_UP:
		return
	_execute_attack(c.id)
	# Schedule EVENT_RECOVERY_END for attacker (AttackResultApplier sets state_duration)
	var atk = _get_by_id(c.id)
	if atk != null and atk.state == CombatConstants.STATE_RECOVERING and atk.state_duration > 0.0:
		_schedule_event({
			"type": CombatConstants.EVENT_RECOVERY_END,
			"combatant_id": c.id,
			"resolve_at": combat_clock + atk.state_duration,
			"data": {}
		})

func _handle_recovery_end(c: Dictionary) -> void:
	if c == null or not c.alive or c.state != CombatConstants.STATE_RECOVERING:
		return
	_StateHandlers.complete_recovery(c)
	if c.state == CombatConstants.STATE_WAITING:
		var cooldown: float = _action_ready_cooldown(c)
		_schedule_event({
			"type": CombatConstants.EVENT_ACTION_READY,
			"combatant_id": c.id,
			"resolve_at": combat_clock + cooldown,
			"data": {}
		})
	elif c.state == CombatConstants.STATE_COWERING:
		# Cowering: no EVENT_ACTION_READY until they leave cowering (process_incapacitation handles)
		pass

func stop():
	set_process(false)

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated (bandaged, packed, or tourniqueted). Used to gate "End battle" during medical phase.
func can_end_medical_phase() -> bool:
	return _MedicalPhase.can_end_medical_phase(self)

## True if combatant has any wounded part that is not comprehensively treated (bandaged, packed, or tourniqueted). Direct pressure alone does not count.
func _has_untreated_wounds(c: Dictionary) -> bool:
	return _MedicalPhase.has_untreated_wounds(self, c)

## Called when player clicks "End battle" during medical phase. Emits combat_ended and stops.
func finish_battle() -> void:
	print("[Combat] finish_battle: player clicked End battle, winner=%s" % medical_phase_winner)
	emit_signal("combat_ended", medical_phase_winner, null)
	stop()

## Resets a combatant's turn so they can "skip" when they have no available actions (e.g. medical phase with no wounded allies).
## Phase 1: Schedule EVENT_ACTION_READY at short cooldown instead of gauge.
func skip_turn(combatant_id: int) -> void:
	var c = _get_by_id(combatant_id)
	if c != null and c.state == CombatConstants.STATE_WAITING:
		c.gauge = 0.0
		_schedule_event({
			"type": CombatConstants.EVENT_ACTION_READY,
			"combatant_id": combatant_id,
			"resolve_at": combat_clock + 0.5,
			"data": {}
		})

## When player wins: enter medical phase, emit enemies_eliminated, keep battle running. When enemy wins: end immediately.
func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	var alive_by_side: Dictionary = {}
	for c in combatants:
		if c.alive:
			alive_by_side[c.side] = alive_by_side.get(c.side, 0) + 1
	var def_node: String = str(defeated_node.name) if defeated_node != null else "null"
	print("[Combat] Phase end: winner=%s defeated_node=%s alive_by_side=%s" % [winner, def_node, alive_by_side])
	if winner == "enemy":
		print("[Combat] Enemy won => combat_ended, stopping manager")
		emit_signal("combat_ended", winner, defeated_node)
		stop()
	else:
		print("[Combat] Player side won => medical_phase=true, enemies_eliminated")
		medical_phase = true
		medical_phase_winner = winner
		emit_signal("enemies_eliminated", winner)

func get_combatants() -> Array:
	var out := []
	for c in combatants:
		var stats = c.stats.duplicate()
		if c.node != null:
			var entity = _get_entity(c.node)
			if entity != null:
				_StatsSync.sync_from_entity(entity, stats)
		_StatsSync.ensure_defaults(stats)
		var item: Dictionary = {
			"id": c.id,
			"node": c.node,
			"side": c.side,
			"rank": c.get("rank", 0),
			"file": c.get("file", 0),
			"stats": stats,
			"gauge": c.gauge,
			"stamina": c.get("stamina", CombatConstants.STAMINA_MAX),
			"alive": c.alive,
			"state": c.get("state", CombatConstants.STATE_WAITING),
			"state_timer": c.get("state_timer", 0.0),
			"state_duration": c.get("state_duration", 0.0)
		}
		if CombatConstants.COMBAT_DEBUG:
			item["guard_line"] = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
			item["guard_angle_deg"] = CombatConstants.get_guard_angle_deg(c)
		# Event tracking UI: show status when unit might look "frozen" (close cooldown, next turn queued)
		var cooldown_until: float = c.get("action_cooldown_until", 0.0)
		if cooldown_until > combat_clock:
			item["status_override"] = "Closing %.1fs" % (cooldown_until - combat_clock)
		else:
			var next_at: float = _get_next_action_ready_at(c.id)
			if next_at > combat_clock:
				item["status_override"] = "Next: %.1fs" % (next_at - combat_clock)
		out.append(item)
	return out

## Returns resolve_at of next EVENT_ACTION_READY for combatant_id, or -1 if none.
func _get_next_action_ready_at(combatant_id: int) -> float:
	var best: float = -1.0
	for ev in event_queue:
		if ev.get("type", "") == CombatConstants.EVENT_ACTION_READY and ev.get("combatant_id", -1) == combatant_id:
			var at: float = ev.get("resolve_at", 0.0)
			if at > combat_clock and (best < 0.0 or at < best):
				best = at
	return best

# Available actions: array of { "target_id": int, "move_id": String, optional "target_part": String }.
# Attack moves (non-parry) and medical when in danger. Parry is passive only (A4v3).
func _is_in_medical_danger(c: Dictionary) -> bool:
	return _MedicalPhase.is_in_medical_danger(self, c)

## Stricter than _is_in_medical_danger: about to bleed out. Must self-treat; cannot help others.
func _is_in_immediate_peril(c: Dictionary) -> bool:
	return _MedicalPhase.is_in_immediate_peril(self, c)

## True when entity has permanently left immediate peril (permanent bleeding rate low enough to recover).
func _has_left_immediate_peril_permanently(c: Dictionary) -> bool:
	return _MedicalPhase.has_left_immediate_peril_permanently(self, c)

func _get_medical_urgency(c: Dictionary) -> float:
	return _MedicalPhase.get_medical_urgency(self, c)

static func _is_medical_move(move_id: String) -> bool:
	return move_id in CombatConstants.MEDICAL_MOVE_IDS

## When bandage/pack/tourniquet fails: track failed part on target; if no one else can help, set pending_retry so performer retries.
func _track_medical_failure_and_maybe_retry(performer: Dictionary, target: Dictionary, part: String, target_cid: int) -> void:
	if target == null:
		return
	var failed: Array = target.get("failed_medical_parts", [])
	if part not in failed:
		failed.append(part)
	target.failed_medical_parts = failed
	var others: int = _count_others_who_can_perform_medical_on_target(performer.id, target_cid)
	if others <= 0:
		performer.pending_retry = {"target_id": target_cid, "part": part}

## Count other combatants (excluding exclude_id) who can perform medical on target_id. Used to decide if performer should retry after failure.
func _count_others_who_can_perform_medical_on_target(exclude_id: int, target_id: int) -> int:
	var count: int = 0
	for other in combatants:
		if other.id == exclude_id or not other.alive or other.side != medical_phase_winner or other.node == null:
			continue
		if _EntityAccess.is_incapacitated(other):
			continue
		var acts: Array = get_available_actions(other.id)
		for a in acts:
			if a.get("target_id", -1) == target_id:
				count += 1
				break
	return count

## Parts currently being treated on combatant_id by allies (bandage/tourniquet wind-up). Used so patient can hold pressure on other wounds.
func _get_parts_being_treated_on(combatant_id: int) -> Array:
	var out: Array = []
	for other in combatants:
		if other.state != CombatConstants.STATE_MEDICAL_WIND_UP:
			continue
		var pm = other.get("pending_medical", {})
		if pm.get("target_combatant_id", -1) == combatant_id:
			var part: String = pm.get("target_part", "")
			if not part.is_empty() and part not in out:
				out.append(part)
	return out

## Returns list of {move_id, target_part} for medical actions the performer can apply to the ally's part.
func _get_ally_medical_actions(performer: Dictionary, ally: Dictionary, part: String) -> Array:
	return _MedicalPhase.get_ally_medical_actions(self, performer, ally, part)

func get_available_actions(combatant_id: int) -> Array:
	return _ActionsBuilder.build(self, combatant_id)

func _process(delta: float) -> void:
	combat_clock += delta
	# Phase 1: Process event queue first (replace gauge-driven ready).
	_process_event_queue()
	var victor: String = ""
	# Bleeding and blood loss tick during combat here. Outside combat, they also advance on time (e.g. 1 min per move in main._advance_time_one_minute) for medical realism.
	for c in combatants:
		if not c.alive or c.node == null:
			continue
		_EntityTimeAdvance.advance(c.node, delta, false)
		# Refresh pain/consciousness/blood after tick so UI and gauge fill use current values.
		_refresh_combatant_stats(c)
	for c in combatants:
		if not c.alive or c.node == null:
			continue
		victor = _StateHandlers.process_death_tick(self, c)
		if not victor.is_empty():
			_end_combat_phase(victor, c.node)
			return
	victor = _check_for_winner()
	if not victor.is_empty():
		if not (medical_phase and victor == medical_phase_winner):
			_end_combat_phase(victor, null)
			return
	for c in combatants:
		if not c.alive:
			continue
		if _StateHandlers.process_incapacitation(self, c):
			continue
		if _StateHandlers.process_medical_wind_up_cancel(self, c):
			continue
		if c.state == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
			_StateHandlers.process_receiving_medical(self, c, delta)
		elif c.state == CombatConstants.STATE_WAITING:
			_StateHandlers.process_waiting(self, c, delta)
		elif c.state == CombatConstants.STATE_WIND_UP:
			_StateHandlers.process_wind_up(self, c, delta)
		elif c.state == CombatConstants.STATE_MEDICAL_WIND_UP:
			_StateHandlers.process_medical_wind_up(self, c, delta)
		elif c.state == CombatConstants.STATE_RECOVERING:
			_StateHandlers.process_recovering(self, c, delta)
		elif c.state == CombatConstants.STATE_SWAP_RANK:
			# Advance timer for UI; event fires when resolve_at reached
			c.state_timer = minf(c.state_timer + delta, c.get("state_duration", 1.0))

# Called when player or AI chooses action. move_id optional; options can include "target_part" for medical actions.
# Phase 1: Event-driven; combatant is ready when EVENT_ACTION_READY fired (state == WAITING).
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = _get_by_id(attacker_id)
	if atk == null:
		return
	if atk.state == CombatConstants.STATE_WAITING and atk.gauge < 100.0 and not medical_phase:
		return  # Event-driven: only allow when ready (gauge kept for medical phase receiving_care)
	# Receiving care: can hold/switch direct pressure on other wounds (no state change, no gauge drain)
	if atk.state == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION and move_id == "apply_direct_pressure" and target_id == attacker_id:
		atk.receiving_care_turn_pending = false  # Consumed this turn (success or fail); allow next turn_ready after cooldown
		atk.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S  # Pace next opportunity
		var part: String = str(options.get("target_part", ""))
		if part.is_empty():
			return
		var parts_being_treated: Array = _get_parts_being_treated_on(attacker_id)
		if part in parts_being_treated:
			return
		var entity = _get_entity(atk.node)
		if entity != null and entity.has_method("apply_direct_pressure") and entity.apply_direct_pressure(part):
			var who: String = _EntityAccess.get_display_name(atk, attacker_id)
			print("[Combat] %s (receiving care) holding direct pressure on %s" % [who, part])
			emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false})
		return
	if atk.state != CombatConstants.STATE_WAITING:
		return
	# Medical actions (target_id = combatant to apply on, self or ally)
	if _is_medical_move(move_id):
		var part: String = str(options.get("target_part", ""))
		var who: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_desc: String = "ally" if target_id != attacker_id else "self"
		print("[Combat] Action: %s chose medical %s on part=%s (%s)" % [who, move_id, part, tgt_desc])
		MedicalActionStarter.start(self, attacker_id, target_id, move_id, part)
		return
	var tgt = _get_by_id(target_id)
	if tgt == null or not tgt.alive:
		return
	# Phase 2: Close action — roll engagement_pressure vs defender evasion.
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		if CombatConstants.COMBAT_EVENT_DEBUG:
			var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
			var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
			print("[Combat] %s attempting to close on %s (weapon range too short for mid)" % [atk_name, tgt_name])
		_resolve_close_attempt(attacker_id, target_id)
		return
	# Phase 3: Swap rank — time-based; no stamina. Swap positions with ally in same file, other rank.
	if move_id == CombatConstants.MOVE_ID_SWAP_RANK:
		_start_swap_rank(attacker_id, target_id)
		return
	# Normal attack: clear direct pressure (new action), then start attack
	if atk.node != null and atk.node.has_method("clear_direct_pressure"):
		if atk.node.has_method("is_applying_direct_pressure") and atk.node.is_applying_direct_pressure():
			print("[Combat] %s taking another action => clear_direct_pressure (was holding %s)" % [atk.node.name if atk.node else "id:%d" % attacker_id, atk.node.get_direct_pressure_part() if atk.node.has_method("get_direct_pressure_part") else "?"])
		atk.node.clear_direct_pressure()
	var opts: Dictionary = {}
	if options.has("target_part"):
		opts["target_part"] = options.target_part
	if options.has("feint_part"):
		opts["feint_part"] = options.feint_part
	_WindUpStarter.start(self, attacker_id, target_id, move_id, opts)
	# Phase 1: Schedule EVENT_MELEE_ATTACK for event-driven resolution
	# _WindUpStarter mutates atk (state, state_duration); atk is reference so already updated
	if atk.state == CombatConstants.STATE_WIND_UP and atk.state_duration > 0.0:
		_schedule_event({
			"type": CombatConstants.EVENT_MELEE_ATTACK,
			"combatant_id": attacker_id,
			"resolve_at": combat_clock + atk.state_duration,
			"data": {}
		})

func _execute_attack(attacker_id: int) -> void:
	var result: Dictionary = _AttackResolver.resolve_attack(self, attacker_id)
	_AttackResultApplier.apply_result(self, attacker_id, result)
	# Option D: CombatManager owns flow. After parry, defender gets EVENT_ACTION_READY.
	var action: String = result.get("action", "")
	var tgt_id: int = result.get("target_id", -1)
	if action in ["parry_deflect", "parry_partial"] and tgt_id >= 0:
		var tgt = _get_by_id(tgt_id)
		if tgt != null and tgt.alive and tgt.state == CombatConstants.STATE_WAITING:
			_schedule_event({
				"type": CombatConstants.EVENT_ACTION_READY,
				"combatant_id": tgt_id,
				"resolve_at": combat_clock + 0.02,
				"data": {}
			})

## Phase 2: Resolve close attempt — roll engagement_pressure vs defender evasion. Success → both distance_to = close.
func _resolve_close_attempt(attacker_id: int, target_id: int) -> void:
	var atk = _get_by_id(attacker_id)
	var tgt = _get_by_id(target_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	var weapon = _EntityAccess.get_weapon(atk)
	var melee_range: float = float(weapon.melee_range) if weapon != null else 1.5
	var str_val: float = float(atk.stats.get("strength", 100))
	var agi_def: float = float(tgt.stats.get("agility", 100))
	var st_atk: float = atk.get("stamina", CombatConstants.STAMINA_MAX)
	var st_def: float = tgt.get("stamina", CombatConstants.STAMINA_MAX)
	var pressure: float = str_val * CombatConstants.stamina_factor(st_atk / CombatConstants.STAMINA_MAX) * (melee_range / 1.5)
	pressure *= CombatConstants.get_stance_modifier(atk.get("stance", CombatConstants.STANCE_BALANCED), "close_attempt")
	var evasion: float = agi_def * CombatConstants.stamina_factor(st_def / CombatConstants.STAMINA_MAX)
	evasion *= CombatConstants.get_stance_modifier(tgt.get("stance", CombatConstants.STANCE_BALANCED), "evasion")
	if tgt.get("stance", "") == CombatConstants.STANCE_CONTROLLING:
		evasion /= CombatConstants.STANCE_MOD_OPPONENT_CLOSE  # Attacker close harder vs controlling
	var fid: String = tgt.get("formation_id", "")
	var density: String = formations.get(fid, {}).get("density", "normal")
	evasion *= CombatConstants.get_density_close_mod(density)
	var success: bool = randf() < pressure / (pressure + maxf(evasion, 1.0))
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
		print("[Combat] Close attempt %s → %s: %s (next turn in 0.3s)" % [atk_name, tgt_name, "success" if success else "failed"])
	emit_signal("action_resolved", attacker_id, target_id, {"outcome": "close_success" if success else "close_failed", "dmg": 0, "died": false})
	if success:
		atk.distance_to[target_id] = CombatConstants.DISTANCE_CLOSE
		tgt.distance_to[attacker_id] = CombatConstants.DISTANCE_CLOSE
	atk["action_cooldown_until"] = combat_clock + 0.3  # UI can show "Closing X.Xs"
	_schedule_event({
		"type": CombatConstants.EVENT_ACTION_READY,
		"combatant_id": attacker_id,
		"resolve_at": combat_clock + 0.3,
		"data": {}
	})

## Phase 3: Start swap rank — time-based, no stamina. Both units enter STATE_SWAP_RANK until resolve.
func _start_swap_rank(initiator_id: int, partner_id: int) -> void:
	var init = _get_by_id(initiator_id)
	var partner = _get_by_id(partner_id)
	if init == null or partner == null or not partner.alive:
		return
	if init.side != partner.side or init.get("formation_id", "") != partner.get("formation_id", ""):
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = formations.get(fid, {})
	if formation.is_empty() or formation.get("ranks", 1) <= 1:
		return
	var r0: int = init.get("rank", 0)
	var r1: int = partner.get("rank", 0)
	var f0: int = init.get("file", 0)
	var f1: int = partner.get("file", 0)
	if f0 != f1 or abs(r0 - r1) != 1:
		return  # Must be same file, adjacent rank
	var lane_mod: float = CombatConstants.LANE_MOD_CLEAR
	var pressure_mod: float = CombatConstants.PRESSURE_MOD_NEUTRAL
	var agi: float = float(init.stats.get("agility", 100))
	var duration: float = CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi)) * lane_mod * pressure_mod
	init.state = CombatConstants.STATE_SWAP_RANK
	init.state_timer = 0.0
	init.state_duration = duration
	partner.state = CombatConstants.STATE_SWAP_RANK
	partner.state_timer = 0.0
	partner.state_duration = duration
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		print("[Combat] %s swapping rank with %s (%.2fs)" % [n0, n1, duration])
	emit_signal("action_resolved", initiator_id, partner_id, {"outcome": "swap_rank_start", "dmg": 0, "died": false})
	_schedule_event({
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": initiator_id,
		"resolve_at": combat_clock + duration,
		"data": {"partner_id": partner_id}
	})

## Phase 3: Complete swap rank — swap rank/file of both combatants and update formation slots.
func _handle_swap_rank_resolve(ev: Dictionary) -> void:
	var initiator_id: int = ev.get("combatant_id", -1)
	var partner_id: int = ev.get("data", {}).get("partner_id", -1)
	var init = _get_by_id(initiator_id)
	var partner = _get_by_id(partner_id)
	if init == null:
		if partner != null and partner.state == CombatConstants.STATE_SWAP_RANK:
			partner.state = CombatConstants.STATE_WAITING
		return
	if partner == null or init.state != CombatConstants.STATE_SWAP_RANK:
		return
	var fid: String = init.get("formation_id", "")
	var formation: Dictionary = formations.get(fid, {})
	if formation.is_empty():
		init.state = CombatConstants.STATE_WAITING
		if partner != null:
			partner.state = CombatConstants.STATE_WAITING
		return
	var slots: Dictionary = formation.get("slots", {})
	var r0: int = init.get("rank", 0)
	var r1: int = partner.get("rank", 0)
	var f0: int = init.get("file", 0)
	var f1: int = partner.get("file", 0)
	slots.erase(Vector2i(r0, f0))
	slots.erase(Vector2i(r1, f1))
	init.rank = r1
	init.file = f1
	partner.rank = r0
	partner.file = f0
	slots[Vector2i(r1, f1)] = init.id
	slots[Vector2i(r0, f0)] = partner.id
	init.state = CombatConstants.STATE_WAITING
	partner.state = CombatConstants.STATE_WAITING
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var n0: String = _EntityAccess.get_display_name(init, initiator_id)
		var n1: String = _EntityAccess.get_display_name(partner, partner_id)
		print("[Combat] %s and %s swapped rank" % [n0, n1])
	_schedule_event({
		"type": CombatConstants.EVENT_ACTION_READY,
		"combatant_id": initiator_id,
		"resolve_at": combat_clock + _action_ready_cooldown(init),
		"data": {}
	})

func _get_by_id(id: int):
	for c in combatants:
		if c.id == id:
			return c
	return null

func _find_first_opponent(side: String):
	return _StandingHelper.get_first_opponent(combatants, side)

func _check_for_winner() -> String:
	return _StandingHelper.get_winner(combatants)
