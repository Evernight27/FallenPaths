class_name CombatProcessTick
extends RefCounted

## One frame of combat simulation: event queue, entity time advance, death/winner checks, per-state updates.

const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")

static func tick(manager: Node, delta: float) -> void:
	manager.combat_clock += delta
	_EventDispatch.process_event_queue(manager)
	var victor: String = ""
	for c in manager.combatants:
		if not c.alive or c.node == null:
			continue
		_EntityTimeAdvance.advance(c.node, delta, false)
		manager._refresh_combatant_stats(c)
	for c in manager.combatants:
		if not c.alive or c.node == null:
			continue
		victor = _StateHandlers.process_death_tick(manager, c)
		if not victor.is_empty():
			manager._end_combat_phase(victor, c.node)
			return
	victor = manager._check_for_winner()
	if not victor.is_empty():
		if not (manager.medical_phase and victor == manager.medical_phase_winner):
			manager._end_combat_phase(victor, null)
			return
	for c in manager.combatants:
		if not c.alive:
			continue
		if _StateHandlers.process_incapacitation(manager, c):
			continue
		if _StateHandlers.process_medical_wind_up_cancel(manager, c):
			continue
		if c.state == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
			_StateHandlers.process_receiving_medical(manager, c, delta)
		elif c.state == CombatConstants.STATE_WAITING:
			_StateHandlers.process_waiting(manager, c, delta)
		elif c.state == CombatConstants.STATE_WIND_UP:
			_StateHandlers.process_wind_up(manager, c, delta)
		elif c.state == CombatConstants.STATE_MEDICAL_WIND_UP:
			_StateHandlers.process_medical_wind_up(manager, c, delta)
		elif c.state == CombatConstants.STATE_RECOVERING:
			_StateHandlers.process_recovering(manager, c, delta)
		elif c.state == CombatConstants.STATE_SWAP_RANK or c.state == CombatConstants.STATE_FALLING_BACK:
			c.state_timer = minf(c.state_timer + delta, c.get("state_duration", 1.0))
