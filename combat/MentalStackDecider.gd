class_name MentalStackDecider
extends RefCounted

## Tier 4.3: prioritized AI decision layers (self-medical → ally medical → counter → incoming → formation plug → rout → hold line → exhaustion tunnel → salience-damped utility pick).
## **Read order:** `try_pick` L0 self-med → L1 ally med → L2 counter → L3 incoming → formation plug → MS-L6 rout → L4 hold line → L5 exhaustion → `{}` fallback to **`CombatAIActionPicker.pick_weighted`**.
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
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")


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
		var picked_retreat: Dictionary = _AIPicker.pick_weighted(retreat_only, combatant_id, manager)
		if (
			not picked_retreat.is_empty()
			and str(picked_retreat.get("move_id", "")) == CombatConstants.MOVE_ID_FLEE
			and not _filter_rout_flee_actions(actions, combatant_id).is_empty()
			and _formation_rout_layer_active(manager, c)
		):
			return _stamp_layer_pick(
				c, CombatConstants.MENTAL_STACK_LAYER_ROUT, picked_retreat
			)
		return picked_retreat
	# L0: own immediate peril — self-aid before helping allies (TCCC-style).
	if _EntityAccess.is_in_immediate_peril(manager, c):
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
	# MS-L5: same-file rank-0 vacant — rear steps up via listed **`swap_rank`** / **`drag_back`**.
	var plug_pool: Array = _filter_formation_plug_actions(actions, combatant_id, manager, c)
	if not plug_pool.is_empty() and _same_file_rank0_vacant(manager, c):
		return _stamp_layer_pick(
			c,
			CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG,
			_AIPicker.pick_weighted(plug_pool, combatant_id, manager)
		)
	# MS-L6: breaking formation — prefer listed **`flee`** before hold-line idle.
	var rout_pool: Array = _filter_rout_flee_actions(actions, combatant_id)
	if not rout_pool.is_empty() and _formation_rout_layer_active(manager, c):
		return _stamp_layer_pick(
			c,
			CombatConstants.MENTAL_STACK_LAYER_ROUT,
			_AIPicker.pick_weighted(rout_pool, combatant_id, manager)
		)
	# L4: reserve posture only (wait/focus/close) — **`rotate_file`** / melee exit to utility pick (III-4 **3b**).
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
		if not CombatConstants.is_medical_move(mid):
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
		if not CombatConstants.is_medical_move(mid):
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


static func _hold_line_close_eligible(manager: Node, c: Dictionary) -> bool:
	if _EngagementOpposition.wing_lacks_mapped_opposition(manager, c):
		return true
	if _Doctrine.pincer_flank_wing_should_close_at_long(manager, c):
		return true
	return false


## Reserve posture: default **`wait`**; focus when incoming telegraph needs retarget; wing + LONG may **`attempt_close`** (unmapped wing **3d** or pincer flank wing).
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
		if not close_only.is_empty() and _hold_line_close_eligible(manager, c):
			return _AIPicker.pick_weighted(close_only, combatant_id, manager)
		return _AIPicker.pick_weighted(hold, combatant_id, manager)
	var close_pool: Array = _filter_hold_line_close_actions(actions, combatant_id, manager, c)
	if not close_pool.is_empty() and _hold_line_close_eligible(manager, c):
		return _AIPicker.pick_weighted(close_pool, combatant_id, manager)
	return wait_pick


static func _same_file_rank0_vacant(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	if _EntityAccess.rank_int(c) <= 0:
		return false
	var ctx: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx)
	if fid.is_empty():
		return false
	var form: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx)
	if form.is_empty():
		return false
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form)
	var file_col: int = _EntityAccess.file_int(c)
	return not _FormationSlots.slot_has_any_living_occupant(
		manager, slots, Vector2i(0, file_col)
	)


static func _filter_formation_plug_actions(
	actions: Array, _combatant_id: int, manager: Node, c: Dictionary
) -> Array:
	if manager == null or c.is_empty():
		return []
	var our_rank: int = _EntityAccess.rank_int(c)
	if our_rank <= 1:
		return []
	var our_file: int = _EntityAccess.file_int(c)
	var ctx: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx)
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_FALL_BACK:
			continue
		if not CombatConstants.is_partner_formation_move(mid):
			continue
		var partner_id: int = int(a.get("target_id", -1))
		if partner_id < 0:
			continue
		var partner: Dictionary = _EntityAccess.manager_get_combatant(manager, partner_id)
		if partner.is_empty() or not _EntityAccess.is_available_formation_partner(c, partner):
			continue
		if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, partner, fid):
			continue
		if _EntityAccess.file_int(partner) != our_file:
			continue
		if _EntityAccess.rank_int(partner) >= our_rank:
			continue
		out.append(a)
	return out


static func _filter_rout_flee_actions(actions: Array, combatant_id: int) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
			continue
		if int(a.get("target_id", -1)) != combatant_id:
			continue
		out.append(a)
	return out


static func _formation_rout_layer_active(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	if _MobilityRetreat.formation_retreat_only_for(c):
		return true
	if not _FormationRout.formation_stressed_for_rout(manager, c):
		return false
	if not _EntityAccess.flee_abandonment_warranted(c, manager):
		return false
	return not _FormationRout.side_holding_field(manager, c)


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
			if CombatConstants.is_medical_move(mid):
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
		if CombatConstants.is_formation_reposition_move(mid):
			out.append(a)
			continue
		if CombatConstants.is_focus_line_move(mid):
			out.append(a)
	return out
