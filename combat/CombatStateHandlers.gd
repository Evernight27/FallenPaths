class_name CombatStateHandlers
extends RefCounted

const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Per-state handlers for CombatManager _process loop.
## Footing: parry/deflect --'??'' **`GuardLineUpdater.set_guard_deflected`** '. recovery --'??'' **`set_guard_from_move`** '. **`CombatFootwork.clear_on_exchange_end`** '. idle **`reconcile_idle_offset`** on tick paths '. **`return_to_waiting`** / **`return_to_cowering`** on state transitions. LIVE_PATHS **`#wf-guard-writers`** '. **`#wf-tier-44-pa`**.
## Each handler mutates combatant (c) and may call manager methods.
## Manager must have: get_available_actions, resolve_action, emit_signal, _get_by_id, _find_first_opponent, _execute_attack.

const _MedicalWindUp := preload("res://combat/MedicalWindUpHandler.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
# Runtime preload ' circular dependency (CombatMobilityRetreat preloads CombatStateHandlers).
static var _mobility_retreat_cache: Variant = null

static func _get_mobility_retreat() -> GDScript:
	if _mobility_retreat_cache == null:
		_mobility_retreat_cache = load("res://combat/CombatMobilityRetreat.gd")
	return _mobility_retreat_cache

const _PassiveParryCtx := preload("res://combat/PassiveParryContext.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")


## Drop queued turns for this combatant once they are dead (bleed-out or fatal wound).
static func cancel_events_for_dead_combatant(manager: Node, c: Dictionary) -> void:
	if manager == null or c.is_empty():
		return
	_EventScheduler.cancel_pending_combat_events_for_combatant(manager, _EntityAccess.id_int(c))

## Checks if combatant died this tick (e.g. bled out). Mutates c, emits action_resolved if died.
## Returns victor string if battle should end (non-empty), else "".
static func process_death_tick(manager: Node, c: Dictionary) -> String:
	if not _EntityAccess.alive_bool(c) or _EntityAccess.scene_node(c) == null:
		return ""
	if not _EntityAccess.is_dead(c):
		return ""
	c.alive = false
	_Footwork.clear_on_death(c)
	c.state = CombatConstants.STATE_DEAD
	cancel_events_for_dead_combatant(manager, c)
	var death_reason: String = _EntityAccess.get_death_reason(c)
	var who: String = _EntityAccess.get_display_name(c)
	if _OperationalLog.play_session_is_editor_f5():
		_F5SoakTrace.note_death_tick(who, death_reason)
	else:
		CombatDebug.combat_session("DEATH (tick) %s  -  %s" % [who, death_reason])
	# Phase 3: Plug on death  -  update formation (slot_obstacles, promote rank 1 if rank 0 died).
	if manager.has_method("_on_combatant_died"):
		manager.on_combatant_died(c)
	manager.emit_signal("action_resolved", _EntityAccess.id_int(c), -1, {"dmg": 0, "died": true, "part": "", "damage_type": "", "outcome": "bled_out", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
	return manager._check_for_winner()

## Handles cowering recovery when arm functionality returns. Returns true if combatant should be skipped (incapacitated).
static func process_incapacitation(manager: Node, c: Dictionary) -> bool:
	if _EntityAccess.scene_node(c) == null:
		return false
	if _EntityAccess.state_str(c) == CombatConstants.STATE_COWERING:
		_Footwork.reconcile_idle_offset(c)
	if _EntityAccess.is_unconscious(c):
		return true
	# Cowering: when arm functionality returns, leave cowering state
	if (
		_EntityAccess.state_str(c) == CombatConstants.STATE_COWERING
		and not _EntityAccess.is_cowering(c)
	):
		_Footwork.return_to_waiting(c)
		c.gauge = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		var who_name: String = _EntityAccess.get_display_name(c)
		_CombatDebug.combat_session("%s no longer cowering (arm functionality returned)." % who_name)
		_EventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
		return false
	# Mobile cowering (no arms, functional legs): allow ticks so formation retreat can be offered
	if _EntityAccess.is_cowering(c):
		_get_mobility_retreat().sync_cowering_state_if_no_functional_arm(c)
		return not _EntityAccess.can_flee_or_fall_back(c)
	if _EntityAccess.is_incapacitated(c):
		return true
	return false

## Enters short recovery (no arm, skip turn). For event-driven flow.
## When **`manager`** is set and **`c.pending_attack`** is non-empty, clears defender **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** (Tier 4.2) like **`complete_recovery`**.
static func enter_short_recovery(c: Dictionary, manager: Node = null) -> void:
	_Footwork.clear_on_exchange_end(c)
	c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	c.state = CombatConstants.STATE_RECOVERING
	c.state_timer = 0.0
	c.state_duration = 0.8
	c.gauge = 0.0
	var pa_short: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
	c.pending_attack = {}
	if manager != null and not pa_short.is_empty():
		_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa_short)

## Completes recovery: guard update, state -> WAITING or COWERING. For event-driven flow.
static func complete_recovery(manager: Node, c: Dictionary) -> void:
	c.gauge = 0.0
	c.state_timer = 0.0
	c.state_duration = 0.0
	var move_id: String = c.get("last_move_id", "")
	if move_id.is_empty():
		move_id = str(_EntityAccess.nested_dictionary_read(c, "pending_attack").get(CombatConstants.PA_KEY_ATTACK_TYPE, ""))
	var eff_line: String = c.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
	var cause: String = CombatConstants.normalize_recovery_cause(str(c.get("recovery_cause", "")))
	if cause == "attack_deflect":
		var def_guard: String = c.get("defender_guard_line_at_parry", "")
		var clash_ctx: Dictionary = _EntityAccess.nested_dictionary_read(c, "parry_clash_context")
		GuardLineUpdater.set_guard_deflected(c, move_id, eff_line, def_guard, clash_ctx)
		c.erase("defender_guard_line_at_parry")
		c.erase("parry_clash_context")
	else:
		GuardLineUpdater.set_guard_from_move(c, move_id, eff_line)
	var pa_before: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
	c.pending_attack = {}
	if manager != null and not pa_before.is_empty():
		_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa_before)
	_Footwork.clear_on_exchange_end(c)
	if _EntityAccess.get_attacking_arm(c).is_empty():
		_Footwork.return_to_cowering(c)
		if not _OperationalLog.is_play_session_active():
			var who_name: String = _EntityAccess.get_display_name(c)
			_CombatDebug.combat_session("%s is cowering (no functional arms)" % who_name)
	else:
		_Footwork.return_to_waiting(c)
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK

## Cancels medical wind-up if target died. Returns true if cancelled (caller should continue to next combatant).
static func process_medical_wind_up_cancel(manager: Node, c: Dictionary) -> bool:
	if _EntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
		return false
	var pm_raw_check: Variant = c.get("pending_medical", null)
	if pm_raw_check is not Dictionary:
		c["pending_medical"] = {}
		_Footwork.return_to_waiting(c)
		c.state_timer = 0.0
		c.state_duration = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		_EventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
		return true
	var pm_check: Dictionary = pm_raw_check
	var tgt_cid_check: int = pm_check.get("target_combatant_id", _EntityAccess.id_int(c))
	if tgt_cid_check == _EntityAccess.id_int(c):
		return false
	var tgt_check: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_cid_check)
	if not tgt_check.is_empty() and _EntityAccess.is_alive_in_combat(tgt_check):
		return false
	if not tgt_check.is_empty():
		tgt_check.receiving_medical_count = max(0, tgt_check.get("receiving_medical_count", 0) - 1)
	c.pending_medical = {}
	_Footwork.return_to_waiting(c)
	c.state_timer = 0.0
	c.state_duration = 0.0
	c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	var who_name: String = _EntityAccess.get_display_name(c)
	_CombatDebug.medical_session("Medical cancelled: %s (target died during wind-up)" % who_name)
	_EventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)
	return true

## Aborts medical wind-up when the performer takes damage mid-wind-up.
static func abort_medical_wind_up(manager: Node, performer_id: int) -> void:
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, performer_id)
	if c.is_empty():
		return
	if _EntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
		return
	var pm: Dictionary = c.get("pending_medical", {}) as Dictionary
	var tgt_cid: int = pm.get("target_combatant_id", performer_id)
	if tgt_cid != performer_id:
		var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_cid)
		if not tgt.is_empty():
			tgt.receiving_medical_count = max(0, tgt.get("receiving_medical_count", 0) - 1)
	c["pending_medical"] = {}
	_Footwork.return_to_waiting(c)
	c.state_timer = 0.0
	c.state_duration = 0.0
	c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	var who: String = _EntityAccess.get_display_name(c)
	_CombatDebug.medical_session("Medical wind-up interrupted: %s (took damage during treatment)" % who)
	_EventScheduler.schedule_action_ready_for_combatant(manager, c, 0.05)

static func process_receiving_medical(manager: Node, c: Dictionary, delta: float) -> void:
	_Footwork.reconcile_idle_offset(c)
	c.gauge = 100.0  # Keep readied; can hold/switch direct pressure on other wounds
	var cooldown: float = maxf(0.0, c.get("receiving_care_action_cooldown", 0.0) - delta)
	c.receiving_care_action_cooldown = cooldown
	if _EntityAccess.is_player_side(c):
		var pending: bool = c.get("receiving_care_turn_pending", false)
		if cooldown <= 0.0 and not pending:
			var recv_actions: Array = manager.get_available_actions(_EntityAccess.id_int(c))
			if not recv_actions.is_empty():
				manager.notify_turn_ready(_EntityAccess.id_int(c))
				c.receiving_care_turn_pending = true
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
	else:
		if MedicalPhaseController.combat_resolution_blocked(manager) and MedicalPhaseController.is_losing_side(manager, c):
			return
		if cooldown <= 0.0:
			var actions: Array = manager.get_available_actions(_EntityAccess.id_int(c))
			if not actions.is_empty():
				var cid_recv: int = _EntityAccess.id_int(c)
				var choice: Dictionary = CombatAIActionPicker.pick(actions, cid_recv, manager)
				CombatDebug.flow_log(
					"receiving_care enemy id=%d actions=[%s] => pick %s"
					% [cid_recv, CombatDebug.format_actions_compact(actions), choice.get("move_id", "")],
					"receiving_care_enemy:%d" % cid_recv
				)
				CombatAIActionPicker.resolve_choice(manager, cid_recv, choice, true)
				c.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S

static func process_waiting(_manager: Node, c: Dictionary, delta: float) -> void:
	# Option A: Event-driven. No gauge fill or turn_ready  -  events handle readiness. Only guard + stamina.
	var g: float = _PassiveParryCtx.guard_readiness_float(c)
	c["guard"] = minf(1.0, g + CombatConstants.GUARD_RISE_RATE * delta)
	_Exhaustion.process_waiting_recovery(c, delta)
	var s: float = _EntityAccess.stamina_float(c)
	var cap: float = _Exhaustion.effective_stamina_max(c)
	c["stamina"] = minf(cap, s + _Exhaustion.effective_stamina_refill_rate(c) * delta)
	_CounterTempo.process_waiting(_manager, c)
	_FlurryBind.process_waiting(_manager, c)
	_Footwork.reconcile_idle_offset(c)
	_UiHints.refresh_waiting_tick_stamps(_manager, c)

static func process_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	if manager != null and _get_mobility_retreat().cannot_commit_melee(c):
		_CounterTempo.abort_attacker_wind_up(manager, _EntityAccess.id_int(c))
		return
	# Completion handled by EVENT_MELEE_ATTACK; state_timer for UI countdown only

static func process_medical_wind_up(manager: Node, c: Dictionary, delta: float) -> void:
	_Footwork.reconcile_idle_offset(c)
	c.gauge = 0.0
	c.state_timer += delta
	if manager != null and _get_mobility_retreat().cannot_commit_melee(c):
		abort_medical_wind_up(manager, _EntityAccess.id_int(c))
		return
	if c.state_timer >= c.state_duration:
		var pm_raw: Variant = c.get("pending_medical", null)
		var pm: Dictionary = pm_raw as Dictionary if pm_raw is Dictionary else {}
		c["pending_medical"] = {}
		_MedicalWindUp.complete(manager, c, pm)

static func process_recovering(manager: Node, c: Dictionary, delta: float) -> void:
	c.gauge = 0.0
	c.state_timer += delta
	if manager != null and _get_mobility_retreat().cannot_commit_melee(c):
		_get_mobility_retreat().react_attacking_arm_lost_if_needed(manager, c)
		return
	# Completion handled by EVENT_RECOVERY_END; state_timer for UI countdown only


## Formation shuffle timers (**`swap_rank`**, **`fall_back`**)  -  scrub idle PA each tick (no **`process_waiting`** on these states).
static func process_formation_move_timer(c: Dictionary, delta: float) -> void:
	_Footwork.reconcile_idle_offset(c)
	c.state_timer = minf(c.state_timer + delta, c.get("state_duration", 1.0))
          
