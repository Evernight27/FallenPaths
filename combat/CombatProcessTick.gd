class_name CombatProcessTick
extends RefCounted

## One frame of combat simulation: event queue, entity time advance, death/winner checks, per-state updates.

const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")

static func tick(manager: Node, delta: float) -> void:
	manager.combat_clock += delta
	_EventDispatch.process_event_queue(manager)
	manager._combat_tick_index += 1
	if (
		_CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY
		and _CombatConstants.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES > 0
	):
		var n: int = _CombatConstants.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES
		if n > 0 and manager._combat_tick_index % n == 0:
			manager.mark_all_formations_vacancy_dirty()
	var snap: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(manager)
	var changed_fids: Array = _FormationFlow.reconcile_vacancy_plugs(manager)
	_FormationFlow.finish_vacancy_reconcile_follow_up(manager, changed_fids, snap, true)
	var victor: String = ""
	var last_death_node: Node = null
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if bool(c.get("combat_absent", false)):
			continue
		var adv_node: Node = _EntityAccess.scene_node(c)
		if adv_node == null:
			continue
		_EntityTimeAdvance.advance(adv_node, delta, false)
		if adv_node.has_method("_try_ambient_pain_shock_tick"):
			adv_node._try_ambient_pain_shock_tick(delta)
		manager._refresh_combatant_stats(c)
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var death_node: Node = _EntityAccess.scene_node(c)
		if death_node == null:
			continue
		var tick_victor: String = _StateHandlers.process_death_tick(manager, c)
		if not tick_victor.is_empty():
			victor = tick_victor
			last_death_node = death_node
	if not victor.is_empty():
		manager._end_combat_phase(victor, last_death_node)
		return
	victor = manager._check_for_winner()
	if not victor.is_empty():
		if not (manager.medical_phase and victor == manager.medical_phase_winner):
			manager._end_combat_phase(victor, null)
			return
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _StateHandlers.process_incapacitation(manager, c):
			continue
		if _StateHandlers.process_medical_wind_up_cancel(manager, c):
			continue
		if _EntityAccess.state_str(c) == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
			_StateHandlers.process_receiving_medical(manager, c, delta)
		elif _EntityAccess.state_str(c) == CombatConstants.STATE_WAITING:
			_StateHandlers.process_waiting(manager, c, delta)
		elif _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
			if not (
				_MedicalPhase.combat_resolution_blocked(manager)
				and _MedicalPhase.is_losing_side(manager, c)
			):
				_StateHandlers.process_wind_up(manager, c, delta)
		elif _EntityAccess.state_str(c) == CombatConstants.STATE_MEDICAL_WIND_UP:
			_StateHandlers.process_medical_wind_up(manager, c, delta)
		elif _EntityAccess.state_str(c) == CombatConstants.STATE_RECOVERING:
			if not (
				_MedicalPhase.combat_resolution_blocked(manager)
				and _MedicalPhase.is_losing_side(manager, c)
			):
				_StateHandlers.process_recovering(manager, c, delta)
		elif (
			_EntityAccess.state_str(c) == CombatConstants.STATE_SWAP_RANK
			or _EntityAccess.state_str(c) == CombatConstants.STATE_FALLING_BACK
		):
			if not (
				_MedicalPhase.combat_resolution_blocked(manager)
				and _MedicalPhase.is_losing_side(manager, c)
			):
				c.state_timer = minf(c.state_timer + delta, c.get("state_duration", 1.0))
