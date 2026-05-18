class_name CombatFormationFlee
extends RefCounted

## Tier 6.2: abandon the engagement (leave the field) vs tactical **`fall_back`** within formation.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")


static func flee_action_legal(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	if bool(c.get("combat_absent", false)):
		return false
	if not _EntityAccess.can_flee_or_fall_back(c):
		return false
	if not _EntityAccess.alive_bool(c):
		return false
	var st: String = _EntityAccess.state_str(c)
	if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
		return false
	if _FormationMoves.in_pair_abort_cooldown(manager, c):
		return false
	if _MobilityRetreat.formation_retreat_only_for(c):
		return true
	if not _EntityAccess.retreat_formation_body_damage_warranted(c, manager):
		return false
	return not _FormationMoves.solo_fall_back_action_legal(manager, c)


static func apply_flee(manager: Node, combatant_id: int) -> void:
	if manager == null or combatant_id < 0:
		return
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty() or not flee_action_legal(manager, c):
		return
	var st: String = _EntityAccess.state_str(c)
	if st in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
		var pid: int = int(c.get("formation_move_partner_id", -1))
		var partner: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, pid)
		_FormationFlow.abort_pair(manager, c, partner, "flee")
	_EventScheduler.cancel_pending_combat_events_for_combatant(manager, combatant_id)
	var fid: String = _EntityAccess.formation_id_str(c)
	if not fid.is_empty():
		var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if not formation.is_empty():
			var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
			_FormationSlots.remove_combatant_from_slots(slots, combatant_id)
	c["combat_absent"] = true
	c.state = CombatConstants.STATE_FLED
	c.state_timer = 0.0
	c.state_duration = 0.0
	c.gauge = 0.0
	c.erase("formation_move_partner_id")
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"flee id=%d %s fid=%s"
			% [combatant_id, _EntityAccess.get_display_name(c, combatant_id), fid]
		)
	if not fid.is_empty():
		manager.notify_formation_changed(fid)
		manager._recompute_zoc_and_distance()
		manager._reschedule_back_rank_turns(fid)
	manager.emit_signal(
		"action_resolved",
		combatant_id,
		combatant_id,
		{"outcome": "fled", "dmg": 0, "died": false}
	)
	manager.emit_signal("turn_resolved", combatant_id)
	var winner: String = manager._check_for_winner() if manager.has_method("_check_for_winner") else ""
	if not winner.is_empty() and manager.has_method("_end_combat_phase"):
		manager._end_combat_phase(winner, null)
