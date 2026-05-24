class_name MentalStackDecider
extends RefCounted

## Tier 4.3: prioritized AI decision layers (self-medical → ally medical → counter → incoming → hold line → exhaustion tunnel → salience-damped utility pick).
## **No player target UI** — same picker for all sides; layers only narrow/reweight the listed action pool.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_mental_stack_ai_enabled()


## Returns a picked action when a high-priority layer applies; empty **`{}`** → caller uses salience-damped **`pick_weighted`**.
static func try_pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if not enabled() or actions.is_empty() or manager == null or combatant_id < 0:
		return {}
	_Attention.refresh_salience(manager, combatant_id)
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return {}
	c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
	if _MobilityRetreat.cannot_commit_melee(c):
		var retreat_only: Array = _MobilityRetreat.filter_actions_for_retreat_only(actions, c)
		if retreat_only.is_empty():
			return {}
		return _AIPicker.pick_weighted(retreat_only, combatant_id, manager)
	# L0: own immediate peril — self-aid before helping allies (TCCC-style).
	if manager._is_in_immediate_peril(c):
		var self_med: Array = _filter_self_medical_actions(actions, combatant_id, manager)
		if not self_med.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_SELF_MEDICAL,
				_AIPicker.pick_weighted(self_med, combatant_id, manager)
			)
	# L1: ally peril → coordinated medical only.
	if _Attention.ally_in_immediate_peril(manager, combatant_id):
		var medical: Array = _filter_coordinated_medical_actions(actions, combatant_id, manager)
		if not medical.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_MEDICAL,
				_AIPicker.pick_weighted(medical, combatant_id, manager)
			)
	# L2: counter-tempo window.
	if _CounterTempo.can_act(manager, c):
		var counters: Array = _filter_counter_tempo_actions(actions)
		if not counters.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_COUNTER,
				_AIPicker.pick_weighted(counters, combatant_id, manager)
			)
	# L3: incoming wind-up on me → counter (if listed) or melee vs that attacker.
	if _Attention.is_being_wind_up_targeted(manager, combatant_id):
		var incoming_id: int = _CounterTempo.incoming_attacker_id(manager, combatant_id)
		var threat: Array = _filter_incoming_threat_actions(actions, incoming_id)
		if not threat.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_INCOMING,
				_AIPicker.pick_weighted(threat, combatant_id, manager)
			)
	# L4: back rank / no reach — hold in place; retarget guard only on incoming telegraph mismatch.
	if _ListedActions.action_list_is_reserve_posture_only(actions):
		var hold_pick: Dictionary = _pick_hold_line_action(actions, combatant_id, manager, c)
		if not hold_pick.is_empty():
			return _stamp_layer_pick(c, CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE, hold_pick)
	# L5 (MS-L7): fight exhaustion tunnel — wait / disengage before salience utility pick.
	if _Exhaustion.exhaustion_tunnel_active(c):
		var disengage: Array = _filter_exhaustion_disengage_actions(actions, combatant_id)
		if not disengage.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION,
				_AIPicker.pick_weighted(disengage, combatant_id, manager)
			)
	return {}


static func _stamp_layer_pick(c: Dictionary, layer: String, picked: Dictionary) -> Dictionary:
	if picked.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
		return picked
	c[CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER] = layer
	if _CombatDebug.flow_verbose_enabled():
		_CombatDebug.flow_log(
			"mental_stack %s layer=%s move=%s"
			% [_EntityAccess.get_display_name(c), layer, str(picked.get("move_id", ""))]
		)
	return picked


static func _filter_coordinated_medical_actions(actions: Array, performer_id: int, manager: Node) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if not manager._is_medical_move(mid):
			continue
		var tgt_id: int = int(a.get("target_id", -1))
		var part: String = str(a.get("target_part", ""))
		if _MedicalCoord.medical_action_allowed(manager, performer_id, tgt_id, part, mid):
			out.append(a)
	return out


static func _filter_self_medical_actions(actions: Array, combatant_id: int, manager: Node) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if int(a.get("target_id", -1)) != combatant_id:
			continue
		var mid: String = str(a.get("move_id", ""))
		if not manager._is_medical_move(mid):
			continue
		var part: String = str(a.get("target_part", ""))
		if _MedicalCoord.medical_action_allowed(manager, combatant_id, combatant_id, part, mid):
			out.append(a)
	return out


static func _filter_counter_tempo_actions(actions: Array) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if bool(a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			out.append(a)
	return out


static func _filter_hold_line_actions(actions: Array) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
			out.append(a)
	return out


static func _filter_hold_line_close_actions(
	actions: Array, _combatant_id: int, manager: Node, c: Dictionary
) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			continue
		var tgt_id: int = int(a.get("target_id", -1))
		if tgt_id < 0:
			continue
		var dist: String = _EntityAccess.distance_to_opponent_band(c, tgt_id, "")
		if not _MeleeListing.attempt_close_listed_for_pair(manager, c, tgt_id, dist):
			continue
		out.append(a)
	return out


## Reserve posture: default **`wait`**; focus when incoming telegraph needs retarget; wing + LONG may **`attempt_close`**.
static func _pick_hold_line_action(
	actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Dictionary:
	var hold: Array = _filter_hold_line_actions(actions)
	if hold.is_empty():
		return {}
	var wait_pick: Dictionary = {}
	var focus_pool: Array = []
	var cur_line: String = str(c.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()
	for raw in hold:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_WAIT:
			wait_pick = a.duplicate()
			continue
		if CombatConstants.is_focus_line_move(mid):
			var line: String = CombatConstants.guard_line_for_focus_move_id(mid)
			if line != cur_line:
				focus_pool.append(a)
	if not focus_pool.is_empty() and _hold_line_needs_focus_retarget(manager, combatant_id, c):
		var tele: String = str(
			c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")
		).strip_edges()
		var tele_line: String = str(CombatConstants.PART_TO_LINE.get(tele, "")).strip_edges()
		for raw in focus_pool:
			var a: Dictionary = raw as Dictionary
			if CombatConstants.guard_line_for_focus_move_id(str(a.get("move_id", ""))) == tele_line:
				return a.duplicate()
		return _AIPicker.pick_weighted(focus_pool, combatant_id, manager)
	if wait_pick.is_empty():
		var close_only: Array = _filter_hold_line_close_actions(actions, combatant_id, manager, c)
		if (
			not close_only.is_empty()
			and _EngagementOpposition.wing_lacks_mapped_opposition(manager, c)
		):
			return _AIPicker.pick_weighted(close_only, combatant_id, manager)
		return _AIPicker.pick_weighted(hold, combatant_id, manager)
	var close_pool: Array = _filter_hold_line_close_actions(actions, combatant_id, manager, c)
	if not close_pool.is_empty() and _EngagementOpposition.wing_lacks_mapped_opposition(manager, c):
		return _AIPicker.pick_weighted(close_pool, combatant_id, manager)
	return wait_pick


static func _hold_line_needs_focus_retarget(manager: Node, combatant_id: int, c: Dictionary) -> bool:
	if not _Attention.is_being_wind_up_targeted(manager, combatant_id):
		return false
	var tele: String = str(
		c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")
	).strip_edges()
	if tele.is_empty():
		return false
	var tele_line: String = str(CombatConstants.PART_TO_LINE.get(tele, "")).strip_edges()
	if tele_line.is_empty():
		return false
	var cur_line: String = str(c.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()
	return tele_line != cur_line


static func _filter_incoming_threat_actions(actions: Array, incoming_attacker_id: int) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if bool(a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			out.append(a)
			continue
		if incoming_attacker_id >= 0 and int(a.get("target_id", -1)) == incoming_attacker_id:
			var mid: String = str(a.get("move_id", ""))
			if mid in CombatConstants.MEDICAL_MOVE_IDS:
				continue
			if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
				continue
			out.append(a)
	return out


static func _filter_exhaustion_disengage_actions(actions: Array, combatant_id: int) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_WAIT:
			out.append(a)
			continue
		if mid == CombatConstants.MOVE_ID_FLEE and int(a.get("target_id", -1)) == combatant_id:
			out.append(a)
			continue
		if mid in [
			CombatConstants.MOVE_ID_FALL_BACK,
			CombatConstants.MOVE_ID_ROTATE_FILE,
			CombatConstants.MOVE_ID_SWAP_RANK,
			CombatConstants.MOVE_ID_DRAG_BACK,
		]:
			out.append(a)
			continue
		if CombatConstants.is_focus_line_move(mid):
			out.append(a)
	return out
