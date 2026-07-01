class_name CombatResolveAction
extends RefCounted

## Player/AI action dispatch: medical, close, formation moves, melee wind-up scheduling.
## Footing: focus-line resolve â **`GuardLineUpdater.set_guard_from_line`** (L3 drift, not form home) · melee â **`AttackWindUpStarter`** (PA stamp when flag on). LIVE_PATHS **`#wf-guard-writers`** · **`#wf-pick-vs-strike`** · **`#wf-tier-44-pa`**.

const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _FormationFlee := preload("res://combat/CombatFormationFlee.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _LeaderCommand := preload("res://combat/CombatLeaderFormationCommand.gd")
const _Proficiency := preload("res://core/EntityProficiency.gd")
const _CompanyState := preload("res://world/CompanyState.gd")


static func is_medical_move(move_id: String) -> bool:
	return CombatConstants.is_medical_move(move_id)


## True when the action changed combatant state (wind-up, formation move, flee, etc.). False â reject/skip path; no turn log.
static func resolve(manager: Node, attacker_id: int, target_id: int, move_id: String, options: Dictionary) -> bool:
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return false
	if manager.medical_phase:
		if not _EntityAccess.is_on_side(atk, str(manager.medical_phase_winner)):
			return false
		if not is_medical_move(move_id):
			return false
	var use_counter_tempo: bool = options.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)
	if (
		_EntityAccess.state_str(atk) == CombatConstants.STATE_WAITING
		and _EntityAccess.gauge_float(atk) < 100.0
		and not manager.medical_phase
	):
		if not (use_counter_tempo and _CounterTempo.can_act(manager, atk)):
			return false
	if (
		_EntityAccess.state_str(atk) == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		and CombatConstants.is_direct_pressure_move(move_id)
		and target_id == attacker_id
	):
		atk.receiving_care_turn_pending = false
		atk.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
		var part: String = str(options.get("target_part", ""))
		if part.is_empty():
			return false
		if not _MedicalCoord.medical_action_allowed(
			manager, attacker_id, attacker_id, part, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
		):
			return false
		if _EntityAccess.entity_apply_direct_pressure(manager, atk, part):
			var who: String = _EntityAccess.get_display_name(atk, attacker_id)
			CombatDebug.medical_session("%s (receiving care) holding direct pressure on %s" % [who, part])
			manager.emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false})
			# XCamp-4: proficiency gains for self-pressure during receiving care.
			if _CompanyState.read_stub_proficiency_enabled():
				var perf_node := _EntityAccess.get_entity_from_manager(manager, atk)
				if perf_node != null and perf_node.has("_proficiency_bonus"):
					_Proficiency.award_stat_gain(perf_node, "intelligence", _Proficiency.GAIN_MEDICAL_ACTION_BASE * _Proficiency.GAIN_DIRECT_PRESSURE_INT_MULT)
			manager.emit_signal("turn_resolved", attacker_id)
			return true
		return false
	if (
		_EntityAccess.state_str(atk) != CombatConstants.STATE_WAITING
		and _EntityAccess.state_str(atk) != CombatConstants.STATE_COWERING
	):
		return false
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(atk)
	if (
		_MobilityRetreat.cannot_commit_melee(atk)
		and not _MobilityRetreat.resolve_move_allowed_when_cannot_melee(move_id, target_id, attacker_id)
	):
		CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "cannot commit melee")
		return false
	_PlayerTurnHints.clear_formation_listed_turn_hint_on_combatant(atk)
	if move_id == CombatConstants.MOVE_ID_WAIT:
		manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_WAIT, "explicit wait move")
		return true
	if move_id == CombatConstants.MOVE_ID_FLEE and target_id == attacker_id:
		if not _FormationFlee.flee_action_legal(manager, atk):
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "flee not legal")
			return false
		_FormationFlee.apply_flee(manager, attacker_id)
		return true
	if (
		CombatConstants.is_leader_formation_command_move(move_id)
		and target_id == attacker_id
	):
		if _OperationalLog.is_play_session_active():
			var fid_cmd: String = _EntityAccess.formation_id_str(atk)
			_F5SoakTrace.note_leader_formation_command_pick(
				_EntityAccess.get_display_name(atk, attacker_id),
				move_id,
				fid_cmd,
				_EntityAccess.side_str(atk)
			)
		if not _LeaderCommand.apply_leader_command(manager, attacker_id, move_id):
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "leader command not legal")
			return false
		return true
	if CombatConstants.is_focus_line_move(move_id):
		var focus_line: String = CombatConstants.guard_line_for_focus_move_id(move_id)
		if focus_line.is_empty():
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "unknown focus move")
			return false
		var cur_line: String = str(atk.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()
		if cur_line == focus_line:
			manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_WAIT, "focus already set")
			return true
		_GuardLineUpdater.set_guard_from_line(atk, focus_line)
		manager.emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "focus_line", "line": focus_line})
		manager.emit_signal("turn_resolved", attacker_id)
		CombatDebug.finish_instant_turn_and_schedule_ready(manager, atk)
		return true
	if is_medical_move(move_id):
		var part: String = str(options.get("target_part", ""))
		if not _MedicalCoord.medical_action_allowed(manager, attacker_id, target_id, part, move_id):
			var block_reason: String = _MedicalCoord.medical_action_coordination_blocked(
				manager, attacker_id, target_id, part, move_id
			)
			CombatDebug.resolve_action_rejected(
				manager, attacker_id, move_id, "medical coordination: %s" % block_reason
			)
			return false
		var who: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_desc: String = "ally" if target_id != attacker_id else "self"
		if _OperationalLog.is_play_session_active():
			_F5SoakTrace.note_medical_action_pick(who, move_id, part, tgt_desc)
		elif not CombatDebug.flow_verbose_enabled():
			CombatDebug.combat_session(
				"action %s chose medical %s on part=%s (%s)" % [who, move_id, part, tgt_desc]
			)
		MedicalActionStarter.start(manager, attacker_id, target_id, move_id, part)
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty() or not _EntityAccess.is_alive_in_combat(tgt):
		CombatDebug.resolve_action_rejected(
			manager, attacker_id, move_id, "target missing or dead"
		)
		return false
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		var dist_close: String = _EntityAccess.distance_to_opponent_band(atk, target_id)
		if not _MeleeListing.attempt_close_listed_for_pair(manager, atk, target_id, dist_close):
			# Stale UI / scripted resolve: same blocked path as `CombatEngagementResolver` (telemetry).
			return _commit_close_attempt_resolve(manager, attacker_id, target_id)
		if (
			not _OperationalLog.is_play_session_active()
			and not CombatDebug.flow_verbose_enabled()
			and CombatConstants.combat_event_debug_active()
		):
			var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
			var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
			CombatDebug.combat_session(
				"%s attempting to close on %s (tactical distance  -  pressure vs evasion roll)" % [atk_name, tgt_name]
			)
		if _OperationalLog.is_play_session_active():
			_F5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
		return _commit_close_attempt_resolve(manager, attacker_id, target_id)
	if CombatConstants.is_formation_reposition_move(move_id):
		var move_policy: Dictionary = _EngagementMode.movement_policy(manager)
		if move_id == CombatConstants.MOVE_ID_SWAP_RANK and not move_policy.get("allow_swap_rank", false):
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks swap_rank")
			return false
		if move_id == CombatConstants.MOVE_ID_DRAG_BACK and not move_policy.get("allow_drag_back", false):
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks drag_back")
			return false
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and not move_policy.get("allow_fall_back", false):
			# Cowering solo retreat is listed without stable-line policy (`formation_retreat_only` in builder).
			var cowering_solo_retreat: bool = (
				target_id == attacker_id
				and _MobilityRetreat.formation_retreat_only_for(atk)
				and _FormationMoves.solo_fall_back_action_legal(manager, atk)
			)
			if not cowering_solo_retreat:
				CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks fall_back")
				return false
		if move_id == CombatConstants.MOVE_ID_ROTATE_FILE and not _EngagementMode.allow_rotate_file_for_formation(
			manager, _EntityAccess.formation_id_str(atk)
		):
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks rotate_file")
			return false
		if move_id == CombatConstants.MOVE_ID_PLUG_FORWARD:
			var can_plug: bool = move_policy.get("allow_swap_rank", false) \
				or _Doctrine.envelop_mop_up_active(manager, _EntityAccess.side_str(atk))
			if not can_plug:
				CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "movement policy blocks plug_forward")
				return false
		var ctx_mv: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, atk)
		var fid_mv: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_mv)
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id:
			if not _FormationMoves.solo_fall_back_action_legal(manager, atk):
				CombatDebug.resolve_action_rejected(
					manager,
					attacker_id,
					move_id,
					"solo fall_back not legal fid=%s" % fid_mv
				)
				return false
		if move_id != CombatConstants.MOVE_ID_FALL_BACK or target_id != attacker_id:
			var partner_mv: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
			if partner_mv.is_empty() or not _EntityAccess.is_available_formation_partner(atk, partner_mv):
				CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "invalid formation partner")
				return false
			match move_id:
				CombatConstants.MOVE_ID_ROTATE_FILE:
					if not _FormationMoves.rotate_file_action_legal(manager, atk, partner_mv, ctx_mv):
						CombatDebug.resolve_action_rejected(
							manager, attacker_id, move_id, "rotate_file not legal for partner"
						)
						return false
				CombatConstants.MOVE_ID_SWAP_RANK:
					if not _FormationMoves.swap_rank_action_legal(manager, atk, partner_mv, ctx_mv):
						CombatDebug.resolve_action_rejected(
							manager, attacker_id, move_id, "swap_rank not legal for partner"
						)
						return false
				CombatConstants.MOVE_ID_DRAG_BACK:
					if not _FormationMoves.front_rank_paired_retreat_action_legal(manager, atk, partner_mv, ctx_mv):
						CombatDebug.resolve_action_rejected(
							manager, attacker_id, move_id, "drag_back not legal for partner"
						)
						return false
				CombatConstants.MOVE_ID_FALL_BACK:
					if not _FormationMoves.front_rank_paired_retreat_action_legal(manager, atk, partner_mv, ctx_mv):
						CombatDebug.resolve_action_rejected(
							manager, attacker_id, move_id, "fall_back pair not legal for partner"
						)
						return false
				CombatConstants.MOVE_ID_PLUG_FORWARD:
					if not _FormationMoves.plug_forward_action_legal(manager, atk, partner_mv, ctx_mv):
						CombatDebug.resolve_action_rejected(
							manager, attacker_id, move_id, "plug_forward not legal for partner"
						)
						return false
	if move_id == CombatConstants.MOVE_ID_SWAP_RANK:
		if _OperationalLog.is_play_session_active():
			_F5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
		manager._start_formation_pair_move(attacker_id, target_id, move_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	if move_id == CombatConstants.MOVE_ID_DRAG_BACK:
		if _OperationalLog.is_play_session_active():
			_F5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
		manager._start_formation_pair_move(attacker_id, target_id, move_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	if move_id == CombatConstants.MOVE_ID_FALL_BACK:
		if _OperationalLog.is_play_session_active():
			var fb_tag: String = (
				"cowering_fall_back"
				if _EntityAccess.state_str(atk) == CombatConstants.STATE_COWERING
				else "fall_back"
			)
			_F5SoakTrace.note_fall_back_pick(
				fb_tag, _EntityAccess.get_display_name(atk, attacker_id), target_id
			)
		if target_id == attacker_id:
			manager._start_fall_back_solo(attacker_id)
		else:
			manager._start_formation_pair_move(attacker_id, target_id, CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR)
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	if move_id == CombatConstants.MOVE_ID_ROTATE_FILE:
		if _EntityAccess.rank_int(atk) != 0:
			CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "rotate_file requires front rank")
			return false
		var rotate_menu: Array = (
			manager.get_available_actions(attacker_id)
			if manager.has_method("get_available_actions")
			else []
		)
		if _Doctrine.should_suppress_skirmish_rotate_file(manager, atk, rotate_menu):
			CombatDebug.resolve_action_rejected(
				manager, attacker_id, move_id, "envelop mop-up suppresses rotate_file"
			)
			return false
		if _OperationalLog.is_play_session_active():
			_F5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
		manager._start_rotate_file(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	if move_id == CombatConstants.MOVE_ID_PLUG_FORWARD:
		if _OperationalLog.is_play_session_active():
			_F5SoakTrace.note_formation_move_pick(move_id, attacker_id, target_id)
		manager._start_plug_forward(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	if _EntityAccess.is_applying_direct_pressure_scene(atk):
		var pressure_part: String = _EntityAccess.get_direct_pressure_part_scene(atk)
		CombatDebug.flow_log(
			"clear_direct_pressure id=%d %s (was %s)"
			% [
				attacker_id,
				_EntityAccess.get_display_name(atk, attacker_id),
				pressure_part if not pressure_part.is_empty() else "?"
			],
			"clear_direct_pressure:%d" % attacker_id
		)
	_EntityAccess.clear_direct_pressure_scene(atk)
	if _MobilityRetreat.cannot_commit_melee(atk):
		CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "no functional arm for melee")
		return false
	var opts: Dictionary = {}
	if options.has("target_part"):
		opts["target_part"] = options.target_part
	if options.has("feint_part"):
		opts["feint_part"] = options.feint_part
	if use_counter_tempo:
		opts[CombatConstants.ACTION_KEY_COUNTER_TEMPO] = true
		_CounterTempo.spend_gauge(atk)
		_CounterTempo.clear_window(atk)
	var incoming_attacker_id: int = -1
	if use_counter_tempo:
		incoming_attacker_id = _CounterTempo.incoming_attacker_id(manager, attacker_id)
	_WindUpStarter.start(manager, attacker_id, target_id, move_id, opts)
	var wind_st: String = _EntityAccess.state_str(atk)
	if wind_st == CombatConstants.STATE_WIND_UP and atk.state_duration > 0.0:
		_TargetScoring.on_combat_commitment(manager, attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		_EntityAccess.manager_schedule_event(
			manager,
			{
				"type": CombatConstants.EVENT_MELEE_ATTACK,
				"combatant_id": attacker_id,
				"resolve_at": _EntityAccess.combat_clock_plus(manager, atk.state_duration),
				"data": {},
			}
		)
		if use_counter_tempo and incoming_attacker_id >= 0:
			_CounterTempo.defer_incoming_melee_after_counter(manager, attacker_id, incoming_attacker_id)
		return true
	if wind_st != CombatConstants.STATE_WAITING or _EntityAccess.gauge_float(atk) < CombatConstants.GAUGE_FULL_THRESHOLD:
		# e.g. short recovery when no functional arm
		manager.emit_signal("turn_resolved", attacker_id)
		return true
	CombatDebug.resolve_action_rejected(manager, attacker_id, move_id, "wind_up did not start")
	return false


## Close attempt: resolver clears gauge via **`_finish_close_attempt_turn`**; if it no-ops, **`skip_turn`** (no **`FP_WARN`**).
static func _commit_close_attempt_resolve(manager: Node, attacker_id: int, target_id: int) -> bool:
	manager._resolve_close_attempt(attacker_id, target_id)
	var atk_after: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk_after.is_empty():
		return false
	if (
		_EntityAccess.state_str(atk_after) == CombatConstants.STATE_WAITING
		and _EntityAccess.gauge_float(atk_after) >= CombatConstants.GAUGE_FULL_THRESHOLD
	):
		manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_PASS, "close resolve no-op")
		return false
	manager.emit_signal("turn_resolved", attacker_id)
	return true
      