extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)
signal enemies_eliminated(winner_side)
signal combatant_health_changed(combatant_id)

var combatants := []
var medical_phase: bool = false
var medical_phase_winner: String = ""

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
		"guard_line": "high",
		"guard_zone": "head",
		"stamina": CombatConstants.STAMINA_MAX
	})
	# Connect health_changed so UI can refresh when consciousness/pain/blood changes
	if entity != null and entity.has_signal("health_changed"):
		entity.health_changed.connect(_on_entity_health_changed.bind(id))
	return id

func _on_entity_health_changed(combatant_id: int) -> void:
	emit_signal("combatant_health_changed", combatant_id)

func start():
	medical_phase = false
	medical_phase_winner = ""
	set_process(true)

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
	emit_signal("combat_ended", medical_phase_winner, null)
	stop()

## Resets a combatant's gauge so they can "skip" when they have no available actions (e.g. medical phase with no wounded allies).
func skip_turn(combatant_id: int) -> void:
	var c = _get_by_id(combatant_id)
	if c != null and c.state == CombatConstants.STATE_WAITING:
		c.gauge = 0.0

## When player wins: enter medical phase, emit enemies_eliminated, keep battle running. When enemy wins: end immediately.
func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	if winner == "enemy":
		emit_signal("combat_ended", winner, defeated_node)
		stop()
	else:
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
			"stats": stats,
			"gauge": c.gauge,
			"alive": c.alive,
			"state": c.get("state", CombatConstants.STATE_WAITING),
			"state_timer": c.get("state_timer", 0.0),
			"state_duration": c.get("state_duration", 0.0)
		}
		if CombatConstants.COMBAT_DEBUG:
			item["guard_line"] = c.get("guard_line", "high")
			item["guard_angle_deg"] = CombatConstants.get_guard_angle_deg(c)
		out.append(item)
	return out

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

# Called when player or AI chooses action. move_id optional; options can include "target_part" for medical actions.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = _get_by_id(attacker_id)
	if atk == null or atk.gauge < 100.0:
		return
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
			var who: String = atk.node.name if atk.node != null else "id:%d" % attacker_id
			print("[Combat] %s (receiving care) holding direct pressure on %s" % [who, part])
			emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false})
		return
	if atk.state != CombatConstants.STATE_WAITING:
		return
	# Medical actions (target_id = combatant to apply on, self or ally)
	if _is_medical_move(move_id):
		var part: String = str(options.get("target_part", ""))
		var who: String = atk.node.name if (atk.node != null) else "id:%d" % attacker_id
		var tgt_desc: String = "ally" if target_id != attacker_id else "self"
		print("[Combat] Action: %s chose medical %s on part=%s (%s)" % [who, move_id, part, tgt_desc])
		MedicalActionStarter.start(self, attacker_id, target_id, move_id, part)
		return
	var tgt = _get_by_id(target_id)
	if tgt == null or not tgt.alive:
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

func _execute_attack(attacker_id: int) -> void:
	var result: Dictionary = _AttackResolver.resolve_attack(self, attacker_id)
	_AttackResultApplier.apply_result(self, attacker_id, result)

func _get_by_id(id: int):
	for c in combatants:
		if c.id == id:
			return c
	return null

func _find_first_opponent(side: String):
	return _StandingHelper.get_first_opponent(combatants, side)

func _check_for_winner() -> String:
	return _StandingHelper.get_winner(combatants)
