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
	print("[Combat] DEATH (tick): %s — %s" % [c.node.name if c.node else "id:%d" % c.id, death_reason])
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
		var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
		print("[Combat] %s no longer cowering (arm functionality returned)." % who_name)
		return false
	return true  # incapacitated: skip

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
	var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
	print("[Combat] Medical cancelled: %s (target died during wind-up)" % who_name)
	return true

static func process_receiving_medical(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 100.0  # Keep readied; can hold/switch direct pressure on other wounds
	if c.side == "player":
		var cooldown: float = c.get("receiving_care_action_cooldown", 0.0) - delta
		c.receiving_care_action_cooldown = cooldown
		var pending: bool = c.get("receiving_care_turn_pending", false)
		if cooldown <= 0.0 and not pending:
			var recv_actions: Array = manager.get_available_actions(c.id)
			if not recv_actions.is_empty():
				manager.emit_signal("turn_ready", c.id)
				c.receiving_care_turn_pending = true
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
	else:
		var cooldown: float = c.get("receiving_care_action_cooldown", 0.0) - delta
		c.receiving_care_action_cooldown = cooldown
		if cooldown <= 0.0:
			var actions: Array = manager.get_available_actions(c.id)
			if not actions.is_empty():
				var choice = CombatAIActionPicker.pick(actions, c.id, manager)
				var opts: Dictionary = {}
				if choice.get("target_part", "") != "":
					opts["target_part"] = choice.target_part
				if choice.get("feint_part", "") != "":
					opts["feint_part"] = choice.feint_part
				manager.resolve_action(c.id, c.id, choice.get("move_id", ""), opts)
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S

static func process_waiting(manager: Node, c: Dictionary, delta: float) -> void:
	var g: float = clampf(c.get("guard", 1.0), 0.0, 1.0)
	c["guard"] = minf(1.0, g + CombatConstants.GUARD_RISE_RATE * delta)
	# Stamina refill when idle
	var s: float = c.get("stamina", CombatConstants.STAMINA_MAX)
	c["stamina"] = minf(CombatConstants.STAMINA_MAX, s + CombatConstants.STAMINA_REFILL_RATE * delta)
	var spd: float = float(c.stats.get("agility", 100))
	var fill_rate: float = spd * delta * 0.5
	# Physics: off_balance (e.g. after parried attack) = tempo penalty; slower gauge fill
	var off_until: float = c.get("off_balance_until", -1.0)
	if off_until > Time.get_ticks_msec() / 1000.0:
		fill_rate *= CombatConstants.OFF_BALANCE_GAUGE_FILL_MULT
	if c.node != null:
		if c.node.has_method("get_action_bar_performance_modifier"):
			fill_rate *= c.node.get_action_bar_performance_modifier()
		elif c.node.has_method("get_performance_modifier"):
			fill_rate *= c.node.get_performance_modifier()
	c.gauge = min(100.0, c.gauge + fill_rate)
	if c.gauge >= 100.0:
		if c.side == "player":
			manager.emit_signal("turn_ready", c.id)
		else:
			var actions: Array = manager.get_available_actions(c.id)
			if actions.is_empty():
				var tgt = manager._find_first_opponent(c.side)
				if tgt != null:
					var can_attack: bool = true
					if c.node != null and c.node.has_method("get_attacking_arm"):
						can_attack = not c.node.get_attacking_arm().is_empty()
					if can_attack:
						_WindUpStarter.start(manager, c.id, tgt.id)
					else:
						var who_skip: String = c.node.name if (c.node != null) else "id:%d" % c.id
						print("[Combat] %s has no functional arm; skip turn (short recovery)." % who_skip)
						c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
						c.state = CombatConstants.STATE_RECOVERING
						c.state_timer = 0.0
						c.state_duration = 0.8
						c.gauge = 0.0
						c.pending_attack = {}
			else:
				var choice = CombatAIActionPicker.pick(actions, c.id, manager)
				var opts: Dictionary = {}
				if choice.get("target_part", "") != "":
					opts["target_part"] = choice.target_part
				if choice.get("feint_part", "") != "":
					opts["feint_part"] = choice.feint_part
				manager.resolve_action(c.id, choice.target_id, choice.get("move_id", ""), opts)

static func process_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	if c.state_timer >= c.state_duration:
		manager._execute_attack(c.id)

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
	if c.state_timer >= c.state_duration:
		c.gauge = 0.0
		c.state_timer = 0.0
		c.state_duration = 0.0
		# Weapon position: attack ends in guard; set guard_line from last move.
		# Outcome-dependent: parried blade ends deflected; hit/miss ends in attack line.
		var move_id: String = c.get("last_move_id", "")
		if move_id.is_empty():
			move_id = c.pending_attack.get("attack_type", "")
		var eff_line: String = c.get("effective_attack_line", "")
		var cause: String = c.get("recovery_cause", "")
		if cause == "attack_deflect":
			# Blade was knocked aside by parry; ends in deflected position (or bind if same-line).
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
			var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
			print("[Combat] %s is cowering (no functional arms)." % who_name)
		else:
			c.state = CombatConstants.STATE_WAITING
			c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
