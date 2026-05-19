class_name AvailableActionsBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _MedicalListing := preload("res://combat/CombatMedicalActionListing.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
## Orchestrates `build()`; listing in **`CombatMeleeListing`** / **`CombatFormationMoveListing`** / **`CombatMedicalActionListing`**.


static func _counter_tempo() -> GDScript:
	return load("res://combat/CounterTempo.gd") as GDScript


static func build(manager: Node, combatant_id: int) -> Array:
	var log_fid: String = ""
	var log_breach_blocks_moves: bool = false
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty() or not _EntityAccess.alive_bool(c):
		return []
	var counter_tempo: bool = false
	if _EntityAccess.gauge_float(c) < 100.0:
		if _counter_tempo().call("can_act", manager, c):
			counter_tempo = true
		else:
			return []
	var state: String = _EntityAccess.state_str(c)
	if (
		state != CombatConstants.STATE_WAITING
		and state != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		and state != CombatConstants.STATE_COWERING
	):
		return []
	if _EntityAccess.is_unconscious(c):
		return []
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
	state = _EntityAccess.state_str(c)
	var formation_retreat_only: bool = _MobilityRetreat.formation_retreat_only_for(c)
	var actions: Array = []
	var combatants: Array = manager.combatants
	var medical_phase: bool = manager.medical_phase
	var medical_phase_winner: String = manager.medical_phase_winner
	if medical_phase and _MedicalPhase.is_losing_side(manager, c):
		return []

	if _MedicalListing.append_receiving_care_direct_pressure(
		manager, c, combatant_id, actions, medical_phase_winner
	):
		return actions

	if not medical_phase:
		var zone_ctx: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
		_MeleeListing.append_melee_actions_for_combatant(
			manager, c, combatants, actions, formation_retreat_only, zone_ctx
		)
		var fm_ctx: Dictionary = _FormationMoves.append_formation_move_actions(
			manager, c, combatant_id, combatants, actions, formation_retreat_only, zone_ctx
		)
		log_fid = str(fm_ctx.get("zone_fid", ""))
		log_breach_blocks_moves = bool(fm_ctx.get("breach_blocks_moves", false))
		if bool(fm_ctx.get("cowering_early_exit", false)):
			_FormationMoves.append_combat_wait_if_needed(actions, combatant_id)
			return actions
		_Attention.append_focus_line_listing_actions(c, combatant_id, actions)
		_FormationMoves.append_combat_wait_if_needed(actions, combatant_id)
	else:
		_MedicalListing.append_medical_phase_winner_actions(
			manager, c, combatants, actions, medical_phase_winner
		)
	var result_actions: Array = actions
	if counter_tempo:
		result_actions = _counter_tempo().call("filter_actions_for_counter_tempo", actions, c)
	result_actions = _drop_actions_vs_dead_opponents(manager, c, result_actions)
	CombatDebug.log_available_actions_build(
		manager,
		combatant_id,
		c,
		result_actions,
		actions,
		counter_tempo,
		medical_phase,
		log_fid,
		log_breach_blocks_moves,
		combatants
	)
	return result_actions


## Drop hostile actions whose target died between listing and pick (death same tick / queue lag).
static func _drop_actions_vs_dead_opponents(manager: Node, actor: Dictionary, actions: Array) -> Array:
	if actions.is_empty() or actor.is_empty():
		return actions
	var kept: Array = []
	for a in actions:
		var tid: int = int(a.get("target_id", -1))
		if tid < 0:
			kept.append(a)
			continue
		var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
		if tgt.is_empty():
			kept.append(a)
			continue
		if _EntityAccess.is_living_same_side(actor, tgt):
			kept.append(a)
			continue
		if _EntityAccess.is_alive_in_combat(tgt):
			kept.append(a)
	return kept
