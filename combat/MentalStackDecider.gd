class_name MentalStackDecider
extends RefCounted

## Tier 4.3: prioritized AI decision layers (self-medical → ally medical → counter → incoming → MS-L8 post-strike → L4b sparse fight → L4 hold line → MS-L5 formation plug → MS-L6 rout → L5 exhaustion → salience-damped utility pick).
## **MS-L4 footing boundary:** hold-line layer picks listed moves only — does **not** write **`guard_line`**, PA offset, or **`weapon_form`**. LIVE_PATHS **`#wf-pick-vs-strike`** · **`#wf-layer-labels`**.
## **No player target UI** — same picker for all sides; layers only narrow/reweight the listed action pool.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _VacancyPlugs := preload("res://combat/CombatFormationVacancyPlugs.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _PostStrike := preload("res://combat/CombatPostStrike.gd")
const _ZoC := preload("res://combat/ZoneOfControl.gd")


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
	# MS-L8: read post-strike stamp (clock-based, naturally expires after ~1 turn).
	var _strike_tick_val: float = float(c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0))
	var _current_clock: float = manager.combat_clock
	var _strike_tick_active: bool = (
		_strike_tick_val >= 0.0 and absf(_strike_tick_val - _current_clock) < CombatConstants.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE
	)
	if _MobilityRetreat.cannot_commit_melee(c):
		var retreat_only: Array = _MobilityRetreat.filter_actions_for_retreat_only(actions, c)
		if retreat_only.is_empty():
			return {}
		return _AIPicker.pick_weighted(retreat_only, combatant_id, manager)
	# L0: own immediate peril — self-aid before helping allies (TCCC-style).
	if _EntityAccess.is_in_immediate_peril(manager, c):
		var self_med: Array = _filter_self_medical_actions(actions, combatant_id, manager)
		if self_med.is_empty():
			self_med = _filter_self_medical_actions_fallback(actions, combatant_id)
		if not self_med.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_SELF_MEDICAL,
				_AIPicker.pick_weighted(self_med, combatant_id, manager)
			)
	# L1: ally peril → coordinated medical only.
	var _l1_ally_peril: bool = _Attention.ally_in_immediate_peril(manager, combatant_id)
	if _l1_ally_peril:
		var medical: Array = _filter_coordinated_medical_actions(actions, combatant_id, manager)
		if medical.is_empty():
			medical = _filter_ally_medical_actions_fallback(actions, combatant_id, manager)
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
	# MS-L8: post-strike momentum — press advantage or disengage cleanly after a successful strike.
	# Fires before L4b so pressing a specific target advantage takes priority over general
	# fight-finishing pressure (L4b sparse-fight / mop-up).
	var _fight_finish_tail: bool = false
	if CombatConstants.is_feature_ms_post_strike_enabled() and _strike_tick_active:
		var struck_id: int = int(c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID, -1))
		if struck_id >= 0:
			var ps_pool: Array = _PostStrike.filter_post_strike_actions(
				actions, combatant_id, manager, struck_id
			)
			if not ps_pool.is_empty():
				return _stamp_layer_pick(
					c,
					CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE,
					_AIPicker.pick_weighted(ps_pool, combatant_id, manager)
				)
	# L4b (before L4): combat-finish tails — sparse post-flee rank-0 or mop-up underdog; offense over wait/focus shuffle.
	# Skip when this combatant or any ally is in immediate peril — medical layers take priority.
	var _my_peril: bool = _EntityAccess.is_in_immediate_peril(manager, c)
	var _ally_in_peril_count: int = 0
	for _other in manager.combatants:
		if _other is not Dictionary: continue
		var _o: Dictionary = _other as Dictionary
		if _EntityAccess.side_str(_o) != _EntityAccess.side_str(c): continue
		if _EntityAccess.id_int(_o) == combatant_id: continue
		if _EntityAccess.is_in_immediate_peril(manager, _o):
			_ally_in_peril_count += 1
	if not _my_peril and _ally_in_peril_count == 0:
		_fight_finish_tail = _Doctrine.fight_finish_tail_active(
			manager, c, actions, combatant_id
		)
	if _fight_finish_tail:
		var fight_first: Array = _filter_sparse_fight_first_actions(
			actions, combatant_id, manager, c
		)
		if not fight_first.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT,
				_AIPicker.pick_weighted(fight_first, combatant_id, manager)
			)
	# L4: back rank / no reach — hold in place; retarget guard only on incoming telegraph mismatch.
	# Fight-finish tails skip L4 wait/focus when L4b had no offense — utility pick handles trusted close/strikes.
	if _ListedActions.action_list_is_reserve_posture_only(actions):
		if _fight_finish_tail:
			var close_only: Array = _filter_hold_line_close_actions(
				actions, combatant_id, manager, c
			)
			if not close_only.is_empty():
				return _stamp_layer_pick(
					c,
					CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
					_AIPicker.pick_weighted(close_only, combatant_id, manager)
				)
		else:
			var hold_pick: Dictionary = _pick_hold_line_action(
				actions, combatant_id, manager, c
			)
			if not hold_pick.is_empty():
				return _stamp_layer_pick(
					c, CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE, hold_pick
				)
	# MS-L5: vacancy / plug-forward — close rank-0 gaps before utility offense when plug moves are listed.
	if not _VacancyPlugs.formation_plug_layer_blocked(manager, c, actions, combatant_id):
		var plug_pool: Array = _VacancyPlugs.filter_formation_plug_actions(
			manager, c, combatant_id, actions
		)
		if not plug_pool.is_empty():
			return _stamp_layer_pick(
				c,
				CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG,
				_AIPicker.pick_weighted(plug_pool, combatant_id, manager, actions)
			)
	# MS-L6: cohesion break / abandon-field — flee or fall_back before salience utility offense.
	if CombatConstants.is_feature_ms_l6_rout_enabled():
		if not _FormationRout.rout_layer_blocked(manager, c, actions, combatant_id):
			var rout_pool: Array = _FormationRout.filter_rout_disengage_actions(
				manager, c, combatant_id, actions
			)
			if not rout_pool.is_empty() and _FormationRout.rout_cognition_pressure(manager, c):
				return _stamp_layer_pick(
					c,
					CombatConstants.MENTAL_STACK_LAYER_ROUT,
					_AIPicker.pick_weighted(rout_pool, combatant_id, manager, actions)
				)
	# MS-L9: positional awareness — disengage when surrounded and vulnerable.
	# Fight-finish tails skip MS-L9 so listed offense can win via L4b or salience-damped utility pick.
	if CombatConstants.is_feature_ms_positional_awareness_enabled():
		if not _Doctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
			var pos_pool: Array = _positional_disengage_check(manager, combatant_id, actions, c)
			if not pos_pool.is_empty():
				return _stamp_layer_pick(
					c,
					CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS,
					_AIPicker.pick_weighted(pos_pool, combatant_id, manager)
				)
	# L5 (MS-L7): exhaustion tunnel or critical stamina — wait / disengage before salience utility pick.
	# Fight-finish tails skip L5 so listed offense can win via L4b or salience-damped utility pick.
	if (
		_Exhaustion.exhaustion_tunnel_active(c)
		or _EntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
	):
		if not _Doctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
			var ex: float = _EntityAccess.exhaustion_float(c)
			if _CombatDebug.flow_verbose_enabled():
				var offense_mult: float = _Exhaustion.exhaustion_offense_weight_mult(c)
				var zone_label: String = "exhausted"
				if ex < CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD:
					zone_label = "fatigued"
				elif ex < CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD:
					zone_label = "winded"
				_CombatDebug.flow_log(
					"L5 exhaustion zone=%s ex=%.2f offense_mult=%.3f stamina_ratio=%.2f"
					% [zone_label, ex, offense_mult, _EntityAccess.stamina_ratio(c)]
				)
			var disengage: Array = _filter_exhaustion_disengage_actions(
				actions, combatant_id, manager, c
			)
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


## Fallback for immediate-peril self-medical: allow any self-targeted medical move
## when coordination checks fail (e.g. harness tests where bleeding rate detection fails).
static func _filter_self_medical_actions_fallback(actions: Array, combatant_id: int) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if int(a.get("target_id", -1)) != combatant_id:
			continue
		var mid: String = str(a.get("move_id", ""))
		if CombatConstants.is_medical_move(mid):
			out.append(a)
	return out


## Fallback for immediate-peril ally-medical: allow any ally-targeted medical move
## when coordination checks fail (same root cause as self-medical fallback).
static func _filter_ally_medical_actions_fallback(actions: Array, combatant_id: int, manager: Node) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if not CombatConstants.is_medical_move(mid):
			continue
		var tgt_id: int = int(a.get("target_id", -1))
		if tgt_id == combatant_id:
			continue  # skip self-medical (handled by L0)
		var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
		if c.is_empty():
			continue
		var tgt_c: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_id)
		if tgt_c.is_empty():
			continue
		if _EntityAccess.side_str(tgt_c) != _EntityAccess.side_str(c):
			continue  # skip enemy medical
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


static func _filter_sparse_fight_first_actions(
	actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
	var out: Array = []
	for raw in _filter_hold_line_close_actions(actions, combatant_id, manager, c):
		out.append(raw)
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid.is_empty() or mid == CombatConstants.MOVE_ID_WAIT:
			continue
		if CombatConstants.is_focus_line_move(mid):
			continue
		if CombatConstants.is_formation_movement_move(mid):
			continue
		if CombatConstants.is_medical_move(mid):
			continue
		if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			continue
		var tid: int = _ListedActions.entry_target_id(a, combatant_id)
		if tid == combatant_id:
			continue
		if not _ListedActions.first_action_move_vs_target(out, mid, tid).is_empty():
			continue
		out.append(a)
	return out


static func _filter_hold_line_close_actions(
	actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
	var trust_menu_close: bool = _Doctrine.fight_finish_tail_active(
		manager, c, actions, combatant_id
	)
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
		var close_listed: bool = _MeleeListing.attempt_close_listed_for_pair(
			manager, c, tgt_id, dist
		)
		if not close_listed and dist == CombatConstants.DISTANCE_LONG:
			close_listed = _Doctrine.envelop_close_allowed(manager, c, tgt_id)
		if not close_listed and trust_menu_close:
			close_listed = true
		if not close_listed:
			continue
		if _MeleeListing.close_attempt_pair_blocked(manager, c, tgt_id) and not trust_menu_close:
			continue
		if dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID:
			if _ListedActions.action_list_has_hostile_melee_strike(actions, combatant_id):
				continue
			# CLOSE/MID without listed strikes: only mop-up may need another close (band/reach gap).
			if not _Doctrine.envelop_mop_up_active(manager, _EntityAccess.formation_id_str(c)):
				continue
		out.append(a)
	return out


## Reserve posture: default **`wait`**; focus when incoming telegraph needs retarget; **`attempt_close`** when `hold_line_close_pick_eligible` (wing lacks map, pincer flank, or III-4 **3e** mop-up).
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
	var close_pool: Array = _filter_hold_line_close_actions(actions, combatant_id, manager, c)
	var close_eligible: bool = (
		not close_pool.is_empty() and _Doctrine.hold_line_close_pick_eligible(manager, c)
	)
	# III-4 **3e** / fight-finish: close beats focus shuffle when finishing the last enemy or sparse tail.
	if close_eligible and (
		_Doctrine.envelop_mop_up_active(manager, _EntityAccess.formation_id_str(c))
		or _Doctrine.fight_finish_tail_active(manager, c, actions, combatant_id)
	):
		return _AIPicker.pick_weighted(close_pool, combatant_id, manager)
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
		if close_eligible:
			return _AIPicker.pick_weighted(close_pool, combatant_id, manager)
		return _AIPicker.pick_weighted(hold, combatant_id, manager)
	if close_eligible:
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
			if CombatConstants.is_medical_move(mid):
				continue
			if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
				continue
			out.append(a)
	return out


static func _filter_exhaustion_disengage_actions(
	actions: Array, combatant_id: int, manager: Node, c: Dictionary
) -> Array:
	var flee_listed: bool = false
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var probe: Dictionary = raw as Dictionary
		if (
			str(probe.get("move_id", "")) == CombatConstants.MOVE_ID_FLEE
			and int(probe.get("target_id", -1)) == combatant_id
		):
			flee_listed = true
			break
	var block_formation_shuffle: bool = (
		manager != null
		and not c.is_empty()
		and _ListedActions.action_list_has_hostile_strike(actions, combatant_id)
		and _EntityAccess.rank_int(c) == 0
	)
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
		if flee_listed and mid in [
			CombatConstants.MOVE_ID_ROTATE_FILE,
			CombatConstants.MOVE_ID_SWAP_RANK,
			CombatConstants.MOVE_ID_DRAG_BACK,
		]:
			continue
		if block_formation_shuffle and mid in [
			CombatConstants.MOVE_ID_FALL_BACK,
			CombatConstants.MOVE_ID_ROTATE_FILE,
			CombatConstants.MOVE_ID_SWAP_RANK,
			CombatConstants.MOVE_ID_DRAG_BACK,
		]:
			continue
		if block_formation_shuffle and CombatConstants.is_focus_line_move(mid):
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


## MS-L9: positional awareness — returns weighted disengage array when combatant is surrounded and vulnerable.
## Returns empty when not surrounded OR when combatant is healthy (blood >= L9 threshold AND NOT exhausted tunnel).
## Only fires when actual disengage moves (fall_back/flee) exist — does not force wait over utility pick.
static func _positional_disengage_check(
	manager: Node, combatant_id: int, actions: Array, c: Dictionary
) -> Array:
	if not _ZoC.is_combatant_surrounded(manager, combatant_id):
		return []
	# Check vulnerability: must be wounded (blood < L9 threshold) OR exhausted (tunnel active).
	# Reads from entity node (not stats dict) so it works in harness tests where CombatantStatsSync
	# may not have re-synced after wounds are applied post-registration.
	var _node: Variant = _EntityAccess.node_variant(c)
	var blood: float = _EntityAccess.get_blood_volume_from_node(_node as Node) if _node != null else 100.0
	var exhausted_t: bool = _Exhaustion.exhaustion_tunnel_active(c)
	if blood >= CombatConstants.MENTAL_STACK_L9_VULNERABILITY_BLOOD_THRESHOLD and not exhausted_t:
		return []
	# Build disengage pool: fall_back first, flee second, wait third.
	var out: Array = []
	var fall_backs: Array = []
	var flees: Array = []
	var waits: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_FALL_BACK:
			fall_backs.append(a)
		elif mid == CombatConstants.MOVE_ID_FLEE and int(a.get("target_id", -1)) == combatant_id:
			flees.append(a)
		elif mid == CombatConstants.MOVE_ID_WAIT:
			waits.append(a)
	# Only fire when actual disengage moves exist — do not force wait over utility pick.
	if fall_backs.is_empty() and flees.is_empty():
		return []
	out.append_array(fall_backs)
	out.append_array(flees)
	out.append_array(waits)
	return out
