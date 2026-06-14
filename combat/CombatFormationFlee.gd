class_name CombatFormationFlee
extends RefCounted

## Tier 6.2: abandon the engagement (leave the field) vs tactical **`fall_back`** within formation.
## Footing: **`clear_on_exchange_end`** + idle scrub on **`STATE_FLED`** — LIVE_PATHS **`#wf-tier-44-pa`**.
## Rout policy: **`CombatFormationRout`** (`line_cohesion` + side casualty ratio); listing via **`flee_abandonment_warranted`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")


static func flee_action_legal(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	_FormationRout.ensure_rout_baseline(manager)
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
	if not _EntityAccess.flee_abandonment_warranted(c, manager):
		return false
	return not _FormationMoves.solo_fall_back_action_legal(manager, c)


## Verbose build trace when **`flee`** is listed (cohesion / casualties / holding field).
static func log_flee_listed_if_verbose(manager: Node, c: Dictionary) -> void:
	if not CombatDebug.flow_verbose_enabled() or manager == null or c.is_empty():
		return
	var ctx: Dictionary = _FormationRout.rout_context_snapshot(manager, c)
	CombatDebug.flow_log(
		(
			"flee_listed id=%d %s cohesion=%.2f casualty=%.2f stressed=%s holding=%s"
			% [
				_EntityAccess.id_int(c),
				_EntityAccess.get_display_name(c, _EntityAccess.id_int(c)),
				float(ctx.get("line_cohesion", 0.0)),
				float(ctx.get("casualty_ratio", 0.0)),
				str(ctx.get("formation_stressed", false)),
				str(ctx.get("side_holding_field", false)),
			]
		)
	)


static func apply_flee(manager: Node, combatant_id: int) -> void:
	if manager == null or combatant_id < 0:
		return
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty() or not flee_action_legal(manager, c):
		return
	var st: String = _EntityAccess.state_str(c)
	if st in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]:
		var pid: int = int(c.get("formation_move_partner_id", -1))
		var partner: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, pid)
		_FormationFlow.abort_pair(manager, c, partner, CombatConstants.MOVE_ID_FLEE)
	_EventScheduler.cancel_pending_combat_events_for_combatant(manager, combatant_id)
	_Footwork.clear_on_exchange_end(c)
	var fid: String = _EntityAccess.formation_id_str(c)
	if not fid.is_empty():
		var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if not formation.is_empty():
			var slots: Dictionary = _FormationSlots.formation_slots_dict(formation)
			_FormationSlots.remove_combatant_from_slots(slots, combatant_id)
	c["combat_absent"] = true
	c.state = CombatConstants.STATE_FLED
	_Footwork.reconcile_idle_offset(c)
	c.state_timer = 0.0
	c.state_duration = 0.0
	c.gauge = 0.0
	c.erase("formation_move_partner_id")
	_Doctrine.clear_combatant_doctrine_commitment(c)
	var ctx: Dictionary = _FormationRout.rout_context_snapshot(manager, c)
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			(
				"flee id=%d %s fid=%s cohesion=%.2f casualty=%.2f stressed=%s holding=%s"
				% [
					combatant_id,
					_EntityAccess.get_display_name(c, combatant_id),
					fid,
					float(ctx.get("line_cohesion", 0.0)),
					float(ctx.get("casualty_ratio", 0.0)),
					str(ctx.get("formation_stressed", false)),
					str(ctx.get("side_holding_field", false)),
				]
			)
		)
	_F5SoakTrace.note_fled(
		combatant_id,
		_EntityAccess.get_display_name(c, combatant_id),
		float(ctx.get("line_cohesion", 0.0)),
		float(ctx.get("casualty_ratio", 0.0)) * 100.0,
		bool(ctx.get("side_holding_field", false))
	)
	if not fid.is_empty():
		manager.notify_formation_changed(fid)
		manager._recompute_zoc_and_distance()
		manager._reschedule_back_rank_turns(fid)
	manager.emit_signal(
		"action_resolved",
		combatant_id,
		combatant_id,
		{
			"outcome": "fled",
			"dmg": 0,
			"died": false,
			"line_cohesion": float(ctx.get("line_cohesion", -1.0)),
			"casualty_ratio": float(ctx.get("casualty_ratio", -1.0)),
			"formation_stressed": bool(ctx.get("formation_stressed", false)),
			"side_holding_field": bool(ctx.get("side_holding_field", false)),
		}
	)
	manager.emit_signal("turn_resolved", combatant_id)
	var winner: String = manager._check_for_winner() if manager.has_method("_check_for_winner") else ""
	if not winner.is_empty() and manager.has_method("_end_combat_phase"):
		manager._end_combat_phase(winner, null)
