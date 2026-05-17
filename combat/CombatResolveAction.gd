class_name CombatResolveAction
extends RefCounted

## Player/AI action dispatch: medical, close, crash, formation moves, melee wind-up scheduling.

const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")


static func is_medical_move(move_id: String) -> bool:
	return move_id in CombatConstants.MEDICAL_MOVE_IDS


static func resolve(manager: Node, attacker_id: int, target_id: int, move_id: String, options: Dictionary) -> void:
	var atk = manager._get_by_id(attacker_id)
	if atk == null:
		return
	var use_counter_tempo: bool = bool(options.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false))
	if (
		_EntityAccess.state_str(atk) == CombatConstants.STATE_WAITING
		and _EntityAccess.gauge_float(atk) < 100.0
		and not manager.medical_phase
	):
		if not (use_counter_tempo and _CounterTempo.can_act(manager, atk)):
			return
	if (
		_EntityAccess.state_str(atk) == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		and move_id == "apply_direct_pressure"
		and target_id == attacker_id
	):
		atk.receiving_care_turn_pending = false
		atk.receiving_care_action_cooldown = CombatConstants.RECOVERY_AFTER_MEDICAL_S
		var part: String = str(options.get("target_part", ""))
		if part.is_empty():
			return
		var parts_being_treated: Array = manager._get_parts_being_treated_on(attacker_id)
		if part in parts_being_treated:
			return
		var entity = _EntityAccess.get_entity_from_manager(manager, atk)
		if entity != null and entity.has_method("apply_direct_pressure") and entity.apply_direct_pressure(part):
			var who: String = _EntityAccess.get_display_name(atk, attacker_id)
			print("[Combat] %s (receiving care) holding direct pressure on %s" % [who, part])
			manager.emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false})
			manager.emit_signal("turn_resolved", attacker_id)
		return
	if (
		_EntityAccess.state_str(atk) != CombatConstants.STATE_WAITING
		and _EntityAccess.state_str(atk) != CombatConstants.STATE_COWERING
	):
		return
	if move_id == CombatConstants.MOVE_ID_WAIT:
		manager.skip_turn(attacker_id, "wait", "explicit wait move")
		return
	if CombatConstants.is_focus_line_move(move_id):
		var focus_line: String = CombatConstants.guard_line_for_focus_move_id(move_id)
		if focus_line.is_empty():
			return
		_GuardLineUpdater.set_guard_from_line(atk, focus_line)
		manager.emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "focus_line", "line": focus_line})
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if is_medical_move(move_id):
		var part: String = str(options.get("target_part", ""))
		var who: String = _EntityAccess.get_display_name(atk, attacker_id)
		var tgt_desc: String = "ally" if target_id != attacker_id else "self"
		if not CombatDebug.flow_verbose_enabled():
			print("[Combat] Action: %s chose medical %s on part=%s (%s)" % [who, move_id, part, tgt_desc])
		MedicalActionStarter.start(manager, attacker_id, target_id, move_id, part)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	var tgt = manager._get_by_id(target_id)
	if tgt == null or not _EntityAccess.alive_bool(tgt):
		return
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		var dist_close: String = str(
			_EntityAccess.nested_dictionary_read(atk, "distance_to").get(
				target_id, CombatConstants.DISTANCE_LONG
			)
		)
		if not _ActionsBuilder._attempt_close_listed_for_pair(manager, atk, target_id, dist_close):
			# Stale UI / scripted resolve: same blocked path as `CombatEngagementResolver` (telemetry).
			manager._resolve_close_attempt(attacker_id, target_id)
			manager.emit_signal("turn_resolved", attacker_id)
			return
		if not CombatDebug.flow_verbose_enabled() and CombatConstants.COMBAT_EVENT_DEBUG:
			var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
			var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
			print("[Combat] %s attempting to close on %s (tactical distance — pressure vs evasion roll)" % [atk_name, tgt_name])
		manager._resolve_close_attempt(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_CRASH:
		if _EntityAccess.rank_int(atk) != 0:
			return
		if _ZoneOfControl.is_intruded(atk):
			return
		manager._resolve_crash_attempt(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK, CombatConstants.MOVE_ID_ROTATE_FILE]:
		var move_policy: Dictionary = _EngagementMode.movement_policy(manager)
		if move_id == CombatConstants.MOVE_ID_SWAP_RANK and not bool(move_policy.get("allow_swap_rank", false)):
			return
		if move_id == CombatConstants.MOVE_ID_DRAG_BACK and not bool(move_policy.get("allow_drag_back", false)):
			return
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and not bool(move_policy.get("allow_fall_back", false)):
			# Cowering solo retreat is listed without stable-line policy (`formation_retreat_only` in builder).
			var cowering_solo_retreat: bool = (
				target_id == attacker_id
				and (
					_EntityAccess.state_str(atk) == CombatConstants.STATE_COWERING
					or _EntityAccess.is_cowering(atk)
				)
				and AvailableActionsBuilder.solo_fall_back_action_legal(manager, atk)
			)
			if not cowering_solo_retreat:
				return
		if move_id == CombatConstants.MOVE_ID_ROTATE_FILE and not bool(move_policy.get("allow_rotate_file", false)):
			return
		var fid_mv: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, atk)
		var f_mv: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, atk, fid_mv)
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id:
			if not AvailableActionsBuilder.solo_fall_back_action_legal(manager, atk):
				CombatDebug.flow_log(
					"resolve_action solo fall_back rejected id=%d fid=%s (discipline/state/breach/fill)"
					% [attacker_id, fid_mv],
					"solo_fall_back_reject:%d" % attacker_id
				)
				return
		var breach_blocked: bool = false
		if move_id == CombatConstants.MOVE_ID_FALL_BACK and target_id == attacker_id:
			breach_blocked = _FormationBreachRules.breach_blocks_open_lane_moves(manager, f_mv)
		else:
			var partner_mv = manager._get_by_id(target_id)
			if partner_mv == null or not _EntityAccess.alive_bool(partner_mv):
				return
			breach_blocked = _FormationBreachRules.resolve_blocks_formation_move(
				manager, f_mv, move_id, atk, partner_mv
			)
		if breach_blocked:
			CombatDebug.flow_log(
				"resolve_action formation move blocked breach_blocks_moves id=%d move=%s fid=%s breached[%s]"
				% [
					attacker_id,
					move_id,
					fid_mv,
					CombatDebug.format_breached_files(_FormationSlots.formation_nested_dictionary_read(f_mv, "breached_files"))
				],
				"formation_move_block:%d:%s" % [attacker_id, move_id]
			)
			return
	if move_id == CombatConstants.MOVE_ID_SWAP_RANK:
		manager._start_formation_pair_move(attacker_id, target_id, "swap_rank")
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_DRAG_BACK:
		manager._start_formation_pair_move(attacker_id, target_id, "drag_back")
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_FALL_BACK:
		if target_id == attacker_id:
			manager._start_fall_back_solo(attacker_id)
		else:
			manager._start_formation_pair_move(attacker_id, target_id, "fall_back_pair")
		manager.emit_signal("turn_resolved", attacker_id)
		return
	if move_id == CombatConstants.MOVE_ID_ROTATE_FILE:
		if _EntityAccess.rank_int(atk) != 0:
			return
		if _ZoneOfControl.is_intruded(atk):
			return
		manager._start_rotate_file(attacker_id, target_id)
		manager.emit_signal("turn_resolved", attacker_id)
		return
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
	_TargetScoring.on_combat_commitment(manager, attacker_id, target_id)
	manager.emit_signal("turn_resolved", attacker_id)
	if _EntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP and atk.state_duration > 0.0:
		manager._schedule_event({
			"type": CombatConstants.EVENT_MELEE_ATTACK,
			"combatant_id": attacker_id,
			"resolve_at": manager.combat_clock + atk.state_duration,
			"data": {}
		})
		if use_counter_tempo and incoming_attacker_id >= 0:
			_CounterTempo.defer_incoming_melee_after_counter(manager, attacker_id, incoming_attacker_id)
