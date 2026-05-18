class_name MentalStackDecider
extends RefCounted

## Tier 4.3: prioritized AI decision layers (medical → counter-tempo → incoming threat → attack utility).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_mental_stack_ai_enabled()


## Returns a picked action when a high-priority layer applies; empty **`{}`** → caller uses legacy full-list pick.
static func try_pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if not enabled() or actions.is_empty() or manager == null or combatant_id < 0:
		return {}
	_Attention.refresh_salience(manager, combatant_id)
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return {}
	if _MobilityRetreat.cannot_commit_melee(c):
		var retreat_only: Array = _MobilityRetreat.filter_actions_for_retreat_only(actions, c)
		if retreat_only.is_empty():
			return {}
		return _AIPicker.pick_weighted(retreat_only, combatant_id, manager)
	# L1: ally peril → medical only.
	if _Attention.ally_in_immediate_peril(manager, combatant_id):
		var medical: Array = _filter_medical_actions(actions, manager)
		if not medical.is_empty():
			return _stamp_layer_pick(c, "medical", _AIPicker.pick_weighted(medical, combatant_id, manager))
	# L2: counter-tempo window.
	if _CounterTempo.can_act(manager, c):
		var counters: Array = _filter_counter_tempo_actions(actions)
		if not counters.is_empty():
			return _stamp_layer_pick(c, "counter", _AIPicker.pick_weighted(counters, combatant_id, manager))
	# L3: incoming wind-up on me → counter (if listed) or melee vs that attacker.
	if _Attention.is_being_wind_up_targeted(manager, combatant_id):
		var incoming_id: int = _CounterTempo.incoming_attacker_id(manager, combatant_id)
		var threat: Array = _filter_incoming_threat_actions(actions, incoming_id)
		if not threat.is_empty():
			return _stamp_layer_pick(
				c, "incoming", _AIPicker.pick_weighted(threat, combatant_id, manager)
			)
	return {}


static func _stamp_layer_pick(c: Dictionary, layer: String, picked: Dictionary) -> Dictionary:
	if picked.is_empty():
		return picked
	c[CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER] = layer
	if _CombatDebug.flow_verbose_enabled():
		_CombatDebug.flow_log(
			"mental_stack %s layer=%s move=%s"
			% [_EntityAccess.get_display_name(c), layer, str(picked.get("move_id", ""))]
		)
	return picked


static func _filter_medical_actions(actions: Array, manager: Node) -> Array:
	var out: Array = []
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if manager._is_medical_move(str(a.get("move_id", ""))):
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
