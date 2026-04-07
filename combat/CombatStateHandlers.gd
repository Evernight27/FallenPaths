class_name CombatStateHandlers
extends RefCounted

const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")

## Per-state handlers for CombatManager _process loop.
## Each handler mutates combatant (c) and may call manager methods.
## Manager must have: get_available_actions, resolve_action, emit_signal, _get_by_id, _find_first_opponent, _execute_attack.

const _MedicalWindUp := preload("res://combat/MedicalWindUpHandler.gd")

## Checks if combatant died this tick (e.g. bled out). Mutates c, emits action_resolved if died.
## Returns victor string if battle should end (non-empty), else "".
static func process_death_tick(manager: Node, c: Dictionary) -> String:
	if not c.alive or c.node == null:
		return ""
	if not (c.node.has_method("is_dead") and c.node.is_dead()):
		return ""
	c.alive = false
	c.state = CombatConstants.STATE_DEAD
	var death_reason: String = ""
	if c.node.has_method("get_death_reason"):
		death_reason = c.node.get_death_reason()
	print("[Combat] DEATH (tick): %s — %s" % [CombatantEntityAccess.get_display_name(c), death_reason])
	# Phase 3: Plug on death — update formation (slot_obstacles, promote rank 1 if rank 0 died).
	if manager.has_method("_on_combatant_died"):
		manager._on_combatant_died(c)
	manager.emit_signal("action_resolved", c.id, -1, {"dmg": 0, "died": true, "part": "", "damage_type": "", "outcome": "bled_out", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
	return manager._check_for_winner()

## Handles cowering recovery when arm functionality returns. Returns true if combatant should be skipped (incapacitated).
static func process_incapacitation(manager: Node, c: Dictionary) -> bool:
	if c.node == null or not c.node.has_method("is_incapacitated") or not c.node.is_incapacitated():
		return false
	# Cowering: when arm functionality returns, leave cowering state
	if c.state == CombatConstants.STATE_COWERING and c.node.has_method("is_cowering") and not c.node.is_cowering():
		c.state = CombatConstants.STATE_WAITING
		c.gauge = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		var who_name: String = CombatantEntityAccess.get_display_name(c)
		print("[Combat] %s no longer cowering (arm functionality returned)." % who_name)
		# Schedule ACTION_READY so they can act (use centralized scheduling to avoid duplicates)
		if manager.has_method("_schedule_action_ready"):
			manager._schedule_action_ready(c.id, 0.05)
		return false
	return true  # incapacitated: skip

## Enters short recovery (no arm, skip turn). For event-driven flow.
static func enter_short_recovery(c: Dictionary) -> void:
	c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	c.state = CombatConstants.STATE_RECOVERING
	c.state_timer = 0.0
	c.state_duration = 0.8
	c.gauge = 0.0
	c.pending_attack = {}

## Completes recovery: guard update, state -> WAITING or COWERING. For event-driven flow.
static func complete_recovery(c: Dictionary) -> void:
	c.gauge = 0.0
	c.state_timer = 0.0
	c.state_duration = 0.0
	var move_id: String = c.get("last_move_id", "")
	if move_id.is_empty():
		move_id = c.get("pending_attack", {}).get("attack_type", "")
	var eff_line: String = c.get("effective_attack_line", "")
	var cause: String = c.get("recovery_cause", "")
	if cause == "attack_deflect":
		var def_guard: String = c.get("defender_guard_line_at_parry", "")
		var clash_ctx: Dictionary = c.get("parry_clash_context", {})
		GuardLineUpdater.set_guard_deflected(c, move_id, eff_line, def_guard, clash_ctx)
		c.erase("defender_guard_line_at_parry")
		c.erase("parry_clash_context")
	else:
		GuardLineUpdater.set_guard_from_move(c, move_id, eff_line)
	c.pending_attack = {}
	if c.node != null and c.node.has_method("get_attacking_arm") and c.node.get_attacking_arm().is_empty():
		c.state = CombatConstants.STATE_COWERING
		var who_name: String = CombatantEntityAccess.get_display_name(c)
		print("[Combat] %s is cowering (no functional arms)." % who_name)
	else:
		c.state = CombatConstants.STATE_WAITING
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK

## Cancels medical wind-up if target died. Returns true if cancelled (caller should continue to next combatant).
static func process_medical_wind_up_cancel(manager: Node, c: Dictionary) -> bool:
	if c.state != CombatConstants.STATE_MEDICAL_WIND_UP:
		return false
	var pm_check = c.get("pending_medical", {})
	var tgt_cid_check: int = pm_check.get("target_combatant_id", c.id)
	if tgt_cid_check == c.id:
		return false
	var tgt_check = manager._get_by_id(tgt_cid_check)
	if tgt_check != null and tgt_check.alive and (tgt_check.node == null or not tgt_check.node.has_method("is_dead") or not tgt_check.node.is_dead()):
		return false
	if tgt_check != null:
		tgt_check.receiving_medical_count = max(0, tgt_check.get("receiving_medical_count", 0) - 1)
	c.pending_medical = {}
	c.state = CombatConstants.STATE_WAITING
	c.state_timer = 0.0
	c.state_duration = 0.0
	c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	var who_name: String = CombatantEntityAccess.get_display_name(c)
	print("[Combat] Medical cancelled: %s (target died during wind-up)" % who_name)
	# Schedule ACTION_READY so they can act (use centralized scheduling to avoid duplicates)
	if manager.has_method("_schedule_action_ready"):
		manager._schedule_action_ready(c.id, 0.05)
	return true

static func process_receiving_medical(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 100.0  # Keep readied; can hold/switch direct pressure on other wounds
	var cooldown: float = maxf(0.0, c.get("receiving_care_action_cooldown", 0.0) - delta)
	c.receiving_care_action_cooldown = cooldown
	if c.side == "player":
		var pending: bool = c.get("receiving_care_turn_pending", false)
		if cooldown <= 0.0 and not pending:
			var recv_actions: Array = manager.get_available_actions(c.id)
			if not recv_actions.is_empty():
				manager.notify_turn_ready(c.id)
				c.receiving_care_turn_pending = true
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
	else:
		if cooldown <= 0.0:
			var actions: Array = manager.get_available_actions(c.id)
			if not actions.is_empty():
				var choice = CombatAIActionPicker.pick(actions, c.id, manager)
				var opts: Dictionary = CombatAIActionPicker.opts_from_choice(choice)
				CombatDebug.flow_log("receiving_care enemy id=%d actions=[%s] => pick %s" % [
					c.id, CombatDebug.format_actions_compact(actions), choice.get("move_id", "")
				])
				manager.resolve_action(c.id, c.id, choice.get("move_id", ""), opts)
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S

static func process_waiting(_manager: Node, c: Dictionary, delta: float) -> void:
	# Option A: Event-driven. No gauge fill or turn_ready — events handle readiness. Only guard + stamina.
	var g: float = clampf(c.get("guard", 1.0), 0.0, 1.0)
	c["guard"] = minf(1.0, g + CombatConstants.GUARD_RISE_RATE * delta)
	var s: float = c.get("stamina", CombatConstants.STAMINA_MAX)
	c["stamina"] = minf(CombatConstants.STAMINA_MAX, s + CombatConstants.STAMINA_REFILL_RATE * delta)

static func process_wind_up(_manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	# Completion handled by EVENT_MELEE_ATTACK; state_timer for UI countdown only

static func process_medical_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	if c.state_timer >= c.state_duration:
		var pm = c.get("pending_medical", {})
		c.pending_medical = {}
		_MedicalWindUp.complete(manager, c, pm)

static func process_recovering(_manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	# Completion handled by EVENT_RECOVERY_END; state_timer for UI countdown only
