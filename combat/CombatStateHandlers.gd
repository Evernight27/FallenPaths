class_name CombatStateHandlers
extends RefCounted

const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Per-state handlers for CombatManager _process loop.
## Each handler mutates combatant (c) and may call manager methods.
## Manager must have: get_available_actions, resolve_action, emit_signal, _get_by_id, _find_first_opponent, _execute_attack.

const _MedicalWindUp := preload("res://combat/MedicalWindUpHandler.gd")

## Checks if combatant died this tick (e.g. bled out). Mutates c, emits action_resolved if died.
## Returns victor string if battle should end (non-empty), else "".
static func process_death_tick(manager: Node, c: Dictionary) -> String:
	if not _EntityAccess.alive_bool(c) or _EntityAccess.scene_node(c) == null:
		return ""
	var death_node: Node = _EntityAccess.scene_node(c)
	if not (death_node.has_method("is_dead") and death_node.is_dead()):
		return ""
	c.alive = false
	c.state = CombatConstants.STATE_DEAD
	var death_reason: String = ""
	if death_node.has_method("get_death_reason"):
		death_reason = death_node.get_death_reason()
	print("[Combat] DEATH (tick): %s — %s" % [CombatantEntityAccess.get_display_name(c), death_reason])
	# Phase 3: Plug on death — update formation (slot_obstacles, promote rank 1 if rank 0 died).
	if manager.has_method("_on_combatant_died"):
		manager._on_combatant_died(c)
	manager.emit_signal("action_resolved", _EntityAccess.id_int(c), -1, {"dmg": 0, "died": true, "part": "", "damage_type": "", "outcome": "bled_out", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
	return manager._check_for_winner()

## Handles cowering recovery when arm functionality returns. Returns true if combatant should be skipped (incapacitated).
static func process_incapacitation(manager: Node, c: Dictionary) -> bool:
	var inc_node: Node = _EntityAccess.scene_node(c)
	if inc_node == null or not inc_node.has_method("is_incapacitated") or not inc_node.is_incapacitated():
		return false
	# Cowering: when arm functionality returns, leave cowering state
	if (
		_EntityAccess.state_str(c) == CombatConstants.STATE_COWERING
		and inc_node.has_method("is_cowering")
		and not inc_node.is_cowering()
	):
		c.state = CombatConstants.STATE_WAITING
		c.gauge = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		var who_name: String = CombatantEntityAccess.get_display_name(c)
		print("[Combat] %s no longer cowering (arm functionality returned)." % who_name)
		# Schedule ACTION_READY so they can act (use centralized scheduling to avoid duplicates)
		if manager.has_method("_schedule_action_ready"):
			manager._schedule_action_ready(_EntityAccess.id_int(c), 0.05)
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
		move_id = str(_EntityAccess.nested_dictionary_read(c, "pending_attack").get("attack_type", ""))
	var eff_line: String = c.get("effective_attack_line", "")
	var cause: String = c.get("recovery_cause", "")
	if cause == "attack_deflect":
		var def_guard: String = c.get("defender_guard_line_at_parry", "")
		var clash_ctx: Dictionary = _EntityAccess.nested_dictionary_read(c, "parry_clash_context")
		GuardLineUpdater.set_guard_deflected(c, move_id, eff_line, def_guard, clash_ctx)
		c.erase("defender_guard_line_at_parry")
		c.erase("parry_clash_context")
	else:
		GuardLineUpdater.set_guard_from_move(c, move_id, eff_line)
	c.pending_attack = {}
	var rec_node: Node = _EntityAccess.scene_node(c)
	if rec_node != null and rec_node.has_method("get_attacking_arm") and rec_node.get_attacking_arm().is_empty():
		c.state = CombatConstants.STATE_COWERING
		var who_name: String = CombatantEntityAccess.get_display_name(c)
		print("[Combat] %s is cowering (no functional arms)." % who_name)
	else:
		c.state = CombatConstants.STATE_WAITING
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK

## Cancels medical wind-up if target died. Returns true if cancelled (caller should continue to next combatant).
static func process_medical_wind_up_cancel(manager: Node, c: Dictionary) -> bool:
	if _EntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
		return false
	var pm_raw_check: Variant = c.get("pending_medical", null)
	if typeof(pm_raw_check) != TYPE_DICTIONARY:
		c["pending_medical"] = {}
		c.state = CombatConstants.STATE_WAITING
		c.state_timer = 0.0
		c.state_duration = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		if manager.has_method("_schedule_action_ready"):
			manager._schedule_action_ready(_EntityAccess.id_int(c), 0.05)
		return true
	var pm_check: Dictionary = pm_raw_check as Dictionary
	var tgt_cid_check: int = pm_check.get("target_combatant_id", _EntityAccess.id_int(c))
	if tgt_cid_check == _EntityAccess.id_int(c):
		return false
	var tgt_check = manager._get_by_id(tgt_cid_check)
	var tgt_chk_n: Node = _EntityAccess.scene_node(tgt_check) if tgt_check != null else null
	if (
		tgt_check != null
		and _EntityAccess.alive_bool(tgt_check)
		and (
			tgt_chk_n == null
			or not tgt_chk_n.has_method("is_dead")
			or not tgt_chk_n.is_dead()
		)
	):
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
		manager._schedule_action_ready(_EntityAccess.id_int(c), 0.05)
	return true

static func process_receiving_medical(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 100.0  # Keep readied; can hold/switch direct pressure on other wounds
	var cooldown: float = maxf(0.0, c.get("receiving_care_action_cooldown", 0.0) - delta)
	c.receiving_care_action_cooldown = cooldown
	if _EntityAccess.side_str(c) == "player":
		var pending: bool = c.get("receiving_care_turn_pending", false)
		if cooldown <= 0.0 and not pending:
			var recv_actions: Array = manager.get_available_actions(_EntityAccess.id_int(c))
			if not recv_actions.is_empty():
				manager.notify_turn_ready(_EntityAccess.id_int(c))
				c.receiving_care_turn_pending = true
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
	else:
		if cooldown <= 0.0:
			var actions: Array = manager.get_available_actions(_EntityAccess.id_int(c))
			if not actions.is_empty():
				var choice = CombatAIActionPicker.pick(actions, _EntityAccess.id_int(c), manager)
				var opts: Dictionary = CombatAIActionPicker.opts_from_choice(choice)
				CombatDebug.flow_log(
					"receiving_care enemy id=%d actions=[%s] => pick %s"
					% [_EntityAccess.id_int(c), CombatDebug.format_actions_compact(actions), choice.get("move_id", "")],
					"receiving_care_enemy:%d" % _EntityAccess.id_int(c)
				)
				manager.resolve_action(_EntityAccess.id_int(c), _EntityAccess.id_int(c), choice.get("move_id", ""), opts)
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S

static func process_waiting(_manager: Node, c: Dictionary, delta: float) -> void:
	# Option A: Event-driven. No gauge fill or turn_ready — events handle readiness. Only guard + stamina.
	var g: float = clampf(c.get("guard", 1.0), 0.0, 1.0)
	c["guard"] = minf(1.0, g + CombatConstants.GUARD_RISE_RATE * delta)
	var s: float = _EntityAccess.stamina_float(c)
	c["stamina"] = minf(CombatConstants.STAMINA_MAX, s + CombatConstants.STAMINA_REFILL_RATE * delta)

static func process_wind_up(_manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	# Completion handled by EVENT_MELEE_ATTACK; state_timer for UI countdown only

static func process_medical_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	if c.state_timer >= c.state_duration:
		var pm_raw: Variant = c.get("pending_medical", null)
		var pm: Dictionary = (pm_raw as Dictionary) if typeof(pm_raw) == TYPE_DICTIONARY else {}
		c["pending_medical"] = {}
		_MedicalWindUp.complete(manager, c, pm)

static func process_recovering(_manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	# Completion handled by EVENT_RECOVERY_END; state_timer for UI countdown only
