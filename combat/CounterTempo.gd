class_name CounterTempo
extends RefCounted

## Tier 4.2 tempo pilot: partial-gauge counter during an incoming **`STATE_WIND_UP`** on this combatant.
## Footing: counter wind-up scrubs stale PA via **`CombatFootwork.clear_on_exchange_end(atk)`**  -  LIVE_PATHS **`#wf-tier-44-pa`** (clear).
## Opens **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`** on wind-up start; defender may act at **`COUNTER_TEMPO_GAUGE_THRESHOLD`**
## (grants threshold gauge when below  -  readiness built during the incoming wind-up). Spends **`COUNTER_TEMPO_GAUGE_COST`**,
## shortens wind-up via **`COUNTER_TEMPO_WINDUP_MULT`**, and defers the incoming **`EVENT_MELEE_ATTACK`** until after the counter's.
## When **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS` > 0**, counter listing / **`can_act`** wait until the incoming attacker is that
## far through wind-up; **`process_waiting`** schedules **`EVENT_ACTION_READY`** once the gate opens.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")

const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

const _FORMATION_MOVE_IDS: Array[String] = [
	CombatConstants.MOVE_ID_SWAP_RANK,
	CombatConstants.MOVE_ID_DRAG_BACK,
	CombatConstants.MOVE_ID_FALL_BACK,
	CombatConstants.MOVE_ID_ROTATE_FILE,
]


static func enabled() -> bool:
	return CombatConstants.is_feature_counter_tempo_enabled()


static func clear_window(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL)
	c.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED)
	c.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)


static func is_window_open(c: Dictionary, combat_clock: float) -> bool:
	if not enabled() or c == null:
		return false
	var until: float = c.get(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL, -1.0)
	return until > combat_clock


static func incoming_attacker_id(manager: Node, defender_id: int) -> int:
	if manager == null or defender_id < 0:
		return -1
	for other in manager.combatants:
		if other == null or not _EntityAccess.alive_bool(other):
			continue
		if _EntityAccess.id_int(other) == defender_id:
			continue
		if _EntityAccess.state_str(other) != CombatConstants.STATE_WIND_UP:
			continue
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(other, "pending_attack")
		if pa.get("target_id", -1) == defender_id:
			return _EntityAccess.id_int(other)
	return -1


static func incoming_wind_up_progress(manager: Node, attacker_id: int) -> float:
	if manager == null or attacker_id < 0:
		return 0.0
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty() or _EntityAccess.state_str(atk) != CombatConstants.STATE_WIND_UP:
		return 0.0
	var dur: float = atk.get("state_duration", 0.0)
	if dur <= 0.0:
		return 1.0
	return clampf(atk.get("state_timer", 0.0) / dur, 0.0, 1.0)


static func incoming_wind_up_meets_progress_gate(manager: Node, defender_id: int) -> bool:
	var min_p: float = CombatConstants.COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS
	if min_p <= 0.0:
		return true
	var aid: int = incoming_attacker_id(manager, defender_id)
	if aid < 0:
		return false
	return incoming_wind_up_progress(manager, aid) >= min_p


static func can_act(manager: Node, c: Dictionary) -> bool:
	if not enabled() or manager == null or c == null:
		return false
	if not _EntityAccess.is_standing_combatant(c):
		return false
	if _MobilityRetreat.cannot_commit_melee(c):
		return false
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return false
	if _MedicalPhase.combat_resolution_blocked(manager):
		return false
	if not is_window_open(c, _EntityAccess.combat_clock_float(manager)):
		return false
	var def_id: int = _EntityAccess.id_int(c)
	if incoming_attacker_id(manager, def_id) < 0:
		return false
	if not incoming_wind_up_meets_progress_gate(manager, def_id):
		return false
	return _EntityAccess.gauge_float(c) >= CombatConstants.COUNTER_TEMPO_GAUGE_THRESHOLD


static func spend_gauge(c: Dictionary) -> void:
	if c == null:
		return
	var g: float = _EntityAccess.gauge_float(c)
	c["gauge"] = maxf(0.0, g - CombatConstants.COUNTER_TEMPO_GAUGE_COST)


static func is_counter_tempo_melee_action(move_id: String) -> bool:
	if move_id.is_empty():
		return false
	if CombatConstants.is_medical_move(move_id):
		return false
	if move_id == CombatConstants.MOVE_ID_WAIT:
		return false
	if move_id in _FORMATION_MOVE_IDS:
		return false
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return false
	if CombatConstants.is_focus_line_move(move_id):
		return false
	return true


static func filter_actions_for_counter_tempo(actions: Array, c: Dictionary = {}) -> Array:
	if not c.is_empty():
		actions = _MobilityRetreat.filter_actions_for_retreat_only(actions, c)
	var out: Array = []
	for raw in actions:
		if raw is not Dictionary:
			continue
		var a: Dictionary = (raw as Dictionary).duplicate()
		var mid: String = str(a.get("move_id", ""))
		if not is_counter_tempo_melee_action(mid):
			continue
		a[CombatConstants.ACTION_KEY_COUNTER_TEMPO] = true
		out.append(a)
	return out


static func actions_include_counter_tempo_tagged(actions: Array) -> bool:
	for raw in actions:
		if raw is not Dictionary:
			continue
		if (raw as Dictionary).get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
			return true
	return false


## UI snapshot: stamped hint when present, else derive from open window + progress gate (read-only).
static func snapshot_ui_hint(manager: Node, c: Dictionary) -> String:
	if not enabled() or manager == null or c == null:
		return ""
	var stamped: String = str(c.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")).strip_edges()
	if not stamped.is_empty():
		return stamped
	if not is_window_open(c, _EntityAccess.combat_clock_float(manager)):
		return ""
	if can_act(manager, c):
		return "counter_ready"
	return "counter_winding"


static func _refresh_ui_hint(manager: Node, defender: Dictionary) -> void:
	if defender == null or manager == null:
		return
	if not is_window_open(defender, _EntityAccess.combat_clock_float(manager)):
		defender.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
		return
	if can_act(manager, defender):
		defender[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_ready"
	else:
		defender[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_winding"


static func try_schedule_counter_tempo_ready(manager: Node, defender: Dictionary) -> void:
	if not enabled() or manager == null or defender == null:
		return
	_refresh_ui_hint(manager, defender)
	if not can_act(manager, defender):
		return
	if defender.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false):
		return
	defender[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED] = true
	var def_id: int = _EntityAccess.id_int(defender)
	var delay_s: float = CombatConstants.COUNTER_TEMPO_ACTION_READY_DELAY_S
	_EventScheduler.schedule_action_ready(manager, def_id, delay_s)
	if _EntityAccess.is_player_side(defender) and manager.has_method("notify_turn_ready"):
		manager.notify_turn_ready(def_id)


static func on_attacker_wind_up_started(
	manager: Node, _attacker_id: int, defender: Dictionary, wind_up_s: float
) -> void:
	if not enabled() or manager == null or defender == null or _MedicalPhase.combat_resolution_blocked(manager):
		return
	var def_id: int = _EntityAccess.id_int(defender)
	if def_id < 0:
		return
	var until: float = _EntityAccess.combat_clock_float(manager) + wind_up_s * CombatConstants.COUNTER_TEMPO_WINDOW_FRACTION
	defender[CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL] = until
	defender.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED)
	if _EntityAccess.gauge_float(defender) < CombatConstants.COUNTER_TEMPO_GAUGE_THRESHOLD:
		defender["gauge"] = CombatConstants.COUNTER_TEMPO_GAUGE_THRESHOLD
	try_schedule_counter_tempo_ready(manager, defender)


static func defer_incoming_melee_after_counter(
	manager: Node, counter_id: int, deferred_attacker_id: int
) -> void:
	if manager == null or counter_id < 0 or deferred_attacker_id < 0:
		return
	if _MedicalPhase.combat_resolution_blocked(manager):
		var defer_atk: Dictionary = _EntityAccess.manager_get_combatant(manager, deferred_attacker_id)
		if not defer_atk.is_empty() and _MedicalPhase.is_losing_side(manager, defer_atk):
			_EventScheduler.cancel_pending_melee_attack(manager, deferred_attacker_id)
			abort_attacker_wind_up(manager, deferred_attacker_id)
			defer_atk.state_timer = 0.0
			defer_atk.state_duration = 0.0
			defer_atk.gauge = 0.0
			_Footwork.return_to_waiting(defer_atk)
		return
	var counter: Dictionary = _EntityAccess.manager_get_combatant(manager, counter_id)
	if counter.is_empty():
		return
	var counter_end: float = _EntityAccess.combat_clock_float(manager) + counter.get("state_duration", 0.0)
	var defer_to: float = counter_end + CombatConstants.COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S
	var incoming_at: float = _EventScheduler.get_pending_melee_attack_resolve_at(manager, deferred_attacker_id)
	if incoming_at < 0.0:
		return
	if incoming_at < defer_to:
		_EventScheduler.set_pending_melee_attack_resolve_at(manager, deferred_attacker_id, defer_to)


static func abort_attacker_wind_up(manager: Node, attacker_id: int) -> void:
	if manager == null or attacker_id < 0:
		return
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return
	_EventScheduler.cancel_pending_melee_attack(manager, attacker_id)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	var defender_id: int = pa.get("target_id", -1)
	if defender_id >= 0:
		var def: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
		if not def.is_empty():
			clear_window(def)
	if not pa.is_empty():
		_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa)
	_Footwork.clear_on_exchange_end(atk)
	atk.pending_attack = {}
	var was_wind_up: bool = _EntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP
	if was_wind_up and not (manager.medical_phase and _MedicalPhase.is_losing_side(manager, atk)):
		# III-6: mirror **`turn_resolved`** depth recheck  -  rank-0 abort wakes rank-1+; rank-1+ abort wakes deeper reserves.
		_EventScheduler.reschedule_same_file_depth_after_front_turn(manager, attacker_id)
		_EventScheduler.reschedule_same_file_depth_after_reserve_turn(manager, attacker_id)
	if was_wind_up:
		_StateHandlers.enter_short_recovery(atk, manager)
		if atk.get("state_duration", 0.0) > 0.0:
			_EventScheduler.schedule_event(manager, {
				"type": CombatConstants.EVENT_RECOVERY_END,
				"combatant_id": attacker_id,
				"resolve_at": _EntityAccess.combat_clock_float(manager) + float(atk.state_duration),
				"data": {},
			})


static func process_waiting(manager: Node, c: Dictionary) -> void:
	if not enabled() or manager == null or c == null:
		return
	var until: float = c.get(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL, -1.0)
	if until < 0.0:
		return
	if _EntityAccess.combat_clock_float(manager) >= until:
		clear_window(c)
		return
	try_schedule_counter_tempo_ready(manager, c)


static func clear_riposte_chain(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL)
	c.erase(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID)


static func grant_riposte_chain(manager: Node, defender: Dictionary, attacker_id: int) -> void:
	if manager == null or defender == null or attacker_id < 0:
		return
	defender[CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL] = (
		_EntityAccess.combat_clock_float(manager) + CombatConstants.RIPOSTE_CHAIN_WINDOW_S
	)
	defender[CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID] = attacker_id


static func riposte_chain_windup_mult(manager: Node, attacker: Dictionary, target_id: int) -> float:
	if manager == null or attacker == null or target_id < 0:
		return 1.0
	var until: float = attacker.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL, -1.0)
	if until <= _EntityAccess.combat_clock_float(manager):
		return 1.0
	if int(attacker.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID, -1)) != target_id:
		return 1.0
	return CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT


static func counter_tempo_listing_weight_mult(
	manager: Node, combatant_id: int, action: Dictionary, move_id: String
) -> float:
	if not enabled() or manager == null or not action.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
		return 1.0
	var mult: float = CombatConstants.AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT
	var incoming_id: int = incoming_attacker_id(manager, combatant_id)
	var tid: int = action.get("target_id", -1)
	if incoming_id >= 0 and tid == incoming_id:
		mult *= CombatConstants.AI_COUNTER_TEMPO_INCOMING_TARGET_MULT
	if _WeaponConstants.is_feint_move(move_id):
		mult *= CombatConstants.AI_COUNTER_TEMPO_FEINT_DAMP_MULT
	return mult
