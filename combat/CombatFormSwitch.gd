class_name CombatFormSwitch
extends RefCounted

## C3: Realistic form/stance switching with committed wind-up.
## Models physical body movement — blade interpolation, parry vulnerability, stamina cost.
## During STATE_FORM_SWITCH the combatant cannot attack and has reduced parry readiness.
## Blade interpolates between old and new guard angles. Opponents get counter-tempo bonus.


## Compute angular distance (degrees) between two guard lines.
static func angular_distance_deg(old_guard: String, new_guard: String) -> float:
	var a: float = CombatGuardLines.line_to_angle(old_guard)
	var b: float = CombatGuardLines.line_to_angle(new_guard)
	return CombatGuardLines.angle_diff_deg(a, b)


## Compute transition duration in seconds based on angular distance and combatant stats.
static func transition_duration(
	old_guard: String,
	new_guard: String,
	agility: int,
	perf_mod: float,
	exhaustion_mult: float,
	in_bind: bool,
	old_cardinal: String,
	new_cardinal: String
) -> float:
	var theta: float = angular_distance_deg(old_guard, new_guard)
	var base: float = CombatConstantsEncounter.FORM_SWITCH_BASE_DURATION_S + theta * CombatConstantsEncounter.FORM_SWITCH_ANGULAR_SCALE_S
	if in_bind:
		base *= CombatConstantsEncounter.FORM_SWITCH_BIND_PENALTY_MULT
	if not old_cardinal.is_empty() and old_cardinal == new_cardinal:
		base *= CombatConstantsEncounter.FORM_SWITCH_SAME_CARDINAL_BONUS_MULT
	base /= clampf(float(agility) / 100.0, 0.7, 1.3)
	if perf_mod > 0.0:
		base /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	base *= exhaustion_mult
	return minf(base, CombatConstantsEncounter.FORM_SWITCH_MAX_DURATION_S)


## Compute stamina cost based on angular distance.
static func stamina_cost(old_guard: String, new_guard: String) -> float:
	var theta: float = angular_distance_deg(old_guard, new_guard)
	return CombatConstantsEncounter.FORM_SWITCH_BASE_STAMINA_COST + (theta / 180.0) * CombatConstantsEncounter.FORM_SWITCH_ANGULAR_STAMINA_SCALE


## Parry readiness during transition (scales with progress 0..1).
static func parry_readiness_during_switch(progress: float) -> float:
	return lerpf(CombatConstantsEncounter.FORM_SWITCH_PARRY_READINESS_START, CombatConstantsEncounter.FORM_SWITCH_PARRY_READINESS_END, clampf(progress, 0.0, 1.0))


## Dodge penalty during transition (scales with progress 0..1).
static func dodge_penalty_during_switch(progress: float) -> float:
	return lerpf(CombatConstantsEncounter.FORM_SWITCH_DODGE_PENALTY_START, 1.0, clampf(progress, 0.0, 1.0))


## Blade angle interpolation during transition (degrees).
static func blade_angle_during_switch(old_guard: String, new_guard: String, progress: float) -> float:
	var a: float = CombatGuardLines.line_to_angle(old_guard)
	var b: float = CombatGuardLines.line_to_angle(new_guard)
	var d: float = CombatGuardLines.angle_diff_deg(a, b)
	var dir: float = 1.0
	var diff: float = b - a
	if diff > 180.0:
		diff -= 360.0
	elif diff < -180.0:
		diff += 360.0
	dir = 1.0 if diff >= 0.0 else -1.0
	var current: float = a + dir * d * clampf(progress, 0.0, 1.0)
	return fmod(current + 360.0, 360.0)


## Check if the combatant can initiate a form switch.
static func can_switch(c: Dictionary) -> bool:
	if c.is_empty():
		return false
	var st: String = CombatantEntityAccess.state_str(c)
	return st == CombatConstants.STATE_WAITING


## Begin a form switch: enter STATE_FORM_SWITCH, stamp old/new guard, schedule completion.
static func start(manager: Node, c: Dictionary, new_form: String, reason: String) -> bool:
	if manager == null or c.is_empty():
		return false
	if not can_switch(c):
		return false
	var weapon = CombatantEntityAccess.get_weapon(c)
	var resolved: String = CombatWeaponForm.normalize_form(new_form, weapon)
	if not CombatWeaponForm.form_allowed_for_weapon(resolved, weapon):
		resolved = CombatWeaponForm.default_form_for_weapon(weapon)
	var old_form: String = CombatantEntityAccess.form_str(c)
	if old_form == resolved:
		return false
	var old_guard: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
	var new_guard: String = CombatWeaponForm.home_guard_line(resolved, weapon)
	var agility: int = int(CombatantEntityAccess.stats_dict(c).get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
	var perf_mod: float = CombatantEntityAccess.get_performance_modifier(c)
	var in_bind: bool = c.get(DataKeys.BIND_PARTNER_ID, -1) >= 0
	var old_card: String = str(CombatGuardLines.LINE_TO_CARDINAL.get(old_guard, ""))
	var new_card: String = str(CombatGuardLines.LINE_TO_CARDINAL.get(new_guard, ""))
	var base_dur: float = transition_duration(old_guard, new_guard, agility, perf_mod, 1.0, in_bind, old_card, new_card)
	var dur: float = CombatExhaustion.apply_attacker_wind_up_exhaustion_mult(base_dur, c)
	var cost: float = stamina_cost(old_guard, new_guard)
	c[DataKeys.COMBATANT_STAMINA] = maxf(0.0, CombatantEntityAccess.stamina_float(c) - cost)
	c.state = CombatConstants.STATE_FORM_SWITCH
	c.state_timer = 0.0
	c.state_duration = dur
	c.gauge = 0.0
	c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_FORM] = old_form
	c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_GUARD] = old_guard
	c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_FORM] = resolved
	c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_GUARD] = new_guard
	CombatFootwork.clear_on_exchange_end(c)
	_schedule_complete_event(manager, c, dur)
	if CombatConstants.combat_event_debug_active():
		CombatDebug.flow_log(
			"form_switch_start id=%d %s->%s dur=%.2f reason=%s" % [
				CombatantEntityAccess.id_int(c), old_form, resolved, dur, reason
			]
		)
	if OperationalLog.is_play_session_active():
		OperationalLog.play_combat(
			"form_switch_start id=%d %s %s->%s dur=%.2f reason=%s" % [
				CombatantEntityAccess.id_int(c),
				CombatantEntityAccess.get_display_name(c),
				old_form, resolved, dur, reason
			]
		)
	return true


## Complete the form switch: apply the new form, enter short recovery.
static func complete(manager: Node, c: Dictionary) -> void:
	if c.is_empty():
		return
	var target_form: String = str(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_FORM, "")).strip_edges()
	var reason: String = str(c.get(CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON, "")).strip_edges()
	if reason.is_empty():
		reason = "form_switch_complete"
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_FORM)
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_GUARD)
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_FORM)
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_GUARD)
	CombatWeaponForm.assign_form(manager, c, target_form, reason)
	c.state = CombatConstants.STATE_RECOVERING
	c.state_timer = 0.0
	c.state_duration = CombatConstantsEncounter.FORM_SWITCH_SHORT_RECOVERY_S
	c.gauge = 0.0
	c[DataKeys.ATTACK_RECOVERY_CAUSE] = "form_switch_complete"
	if CombatConstants.combat_event_debug_active():
		CombatDebug.flow_log(
			"form_switch_complete id=%d form=%s" % [CombatantEntityAccess.id_int(c), target_form]
		)


## Abort the form switch: cancel transition, return to old guard, enter short recovery.
static func abort(manager: Node, c: Dictionary) -> void:
	if c.is_empty():
		return
	var old_form: String = str(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_FORM, "")).strip_edges()
	var _old_guard: String = str(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_GUARD, "")).strip_edges()
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_FORM)
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_GUARD)
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_FORM)
	c.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_GUARD)
	if not old_form.is_empty():
		CombatWeaponForm.assign_form(manager, c, old_form, "form_switch_abort")
	c.state = CombatConstants.STATE_RECOVERING
	c.state_timer = 0.0
	c.state_duration = CombatConstantsEncounter.FORM_SWITCH_SHORT_RECOVERY_S
	c.gauge = 0.0
	c[DataKeys.ATTACK_RECOVERY_CAUSE] = "form_switch_abort"
	CombatFootwork.clear_on_exchange_end(c)
	if CombatConstants.combat_event_debug_active():
		CombatDebug.flow_log(
			"form_switch_abort id=%d restored=%s" % [CombatantEntityAccess.id_int(c), old_form]
		)


## Process tick for STATE_FORM_SWITCH. Increments timer, checks for completion.
static func process_tick(manager: Node, c: Dictionary, delta: float) -> void:
	if c.is_empty():
		return
	c.gauge = 0.0
	c.state_timer += delta
	if CombatMobilityRetreat.cannot_commit_melee(c):
		abort(manager, c)
		CombatEventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
		return


## Handle form switch completion event.
static func handle_complete_event(manager: Node, c: Dictionary) -> void:
	if c.is_empty():
		return
	if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_FORM_SWITCH:
		return
	complete(manager, c)
	CombatEventScheduler.schedule_action_ready_for_combatant(manager, c, 0.0)


## Transition progress 0..1.
static func transition_progress(c: Dictionary) -> float:
	var dur: float = c.get(DataKeys.PA_STATE_DURATION, 0.001)
	var t: float = c.get(DataKeys.PA_STATE_TIMER, 0.0)
	return clampf(t / dur, 0.0, 1.0)


## Schedule the EVENT_FORM_SWITCH_COMPLETE event.
static func _schedule_complete_event(manager: Node, c: Dictionary, delay_s: float) -> void:
	if manager == null:
		return
	manager.event_queue.append({
		"type": CombatConstants.EVENT_FORM_SWITCH_COMPLETE,
		"combatant_id": CombatantEntityAccess.id_int(c),
		"resolve_at": CombatantEntityAccess.combat_clock_float(manager) + delay_s,
	})
