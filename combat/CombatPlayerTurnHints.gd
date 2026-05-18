class_name CombatPlayerTurnHints
extends RefCounted

## Player `turn_ready` combat log / UI hints (action-list dependent). Display-only row hints live in **`CombatUiHints`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _CrashActions := preload("res://combat/CombatCrashActions.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")


static func clear_formation_listed_turn_hint_on_combatant(c: Dictionary) -> void:
	if not c.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT)


## Stamp or clear **`COMBATANT_KEY_FORMATION_MOVES_TURN_HINT`** for gauge tooltips this turn.
static func sync_formation_listed_turn_hint_on_combatant(c: Dictionary, actions: Array) -> void:
	if c.is_empty():
		return
	var line: String = formation_listed_moves_hint_if_applicable(c, actions)
	if line.is_empty():
		clear_formation_listed_turn_hint_on_combatant(c)
	else:
		c[CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT] = line


## Emit non-empty crash / cowering-retreat / counter-tempo hints via **`manager.notify_combat_ui_hint`**.
static func emit_turn_ready_hints(manager: Node, c: Dictionary, actions: Array) -> void:
	if manager == null or c.is_empty():
		return
	sync_formation_listed_turn_hint_on_combatant(c, actions)
	if not manager.has_method("notify_combat_ui_hint"):
		return
	for hint in [
		crash_absence_hint_if_missing(manager, c, actions),
		cowering_retreat_hint_if_applicable(manager, c, actions),
		counter_tempo_hint_if_applicable(manager, c, actions),
		formation_listed_moves_hint_if_applicable(c, actions),
	]:
		if not hint.is_empty():
			manager.notify_combat_ui_hint(hint)


## Listed formation-move actions with **`formation_move_duration_hint`** (lane / pressure / armor).
static func formation_listed_moves_hint_if_applicable(c: Dictionary, actions: Array) -> String:
	if c.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	return _FormationMoveDuration.formation_listed_moves_turn_hint(actions)


## One line when crash is absent but breach viability suggests it matters.
static func crash_absence_hint_if_missing(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _ZoneOfControl.is_intruded(c):
		return ""
	if _EntityAccess.rank_int(c) != 0:
		return ""
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return ""
	if _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_CRASH):
		return ""
	if CombatConstants.crash_breach_viability(c) < CombatConstants.CRASH_BREACH_VIABILITY_MIN:
		return ""
	var raw: String = _CrashActions.crash_absent_primary_reason(manager, c)
	if raw.is_empty() or raw == "crash_eligible_but_missing_bug":
		return ""
	return _CrashActions.format_crash_absent_reason_for_ui(raw)


## Cowering (no arms) with mobile legs — when solo **fall_back** is listed vs wait-only.
static func cowering_retreat_hint_if_applicable(
	manager: Node, c: Dictionary, actions: Array
) -> String:
	if manager == null or c.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if not _MobilityRetreat.formation_retreat_only_for(c):
		return ""
	if not _EntityAccess.can_flee_or_fall_back(c):
		return ""
	var cid: int = _EntityAccess.id_int(c)
	var has_flee: bool = _MobilityRetreat.actions_include_self_target_move(
		actions, cid, CombatConstants.MOVE_ID_FLEE
	)
	var has_fall_back: bool = _MobilityRetreat.actions_include_self_target_move(
		actions, cid, CombatConstants.MOVE_ID_FALL_BACK
	)
	var has_wait: bool = _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT)
	if has_flee:
		return "No arms — flee abandons the fight; fall back keeps you in formation if the rear rank is clear."
	if has_fall_back:
		return "No arms — fall back is available (rear rank in your file must be clear)."
	if has_wait:
		return "No arms — holding position (fall back blocked: policy, breach, or rear rank occupied)."
	return ""


## Counter-tempo window with tagged melee listings.
static func counter_tempo_hint_if_applicable(
	manager: Node, c: Dictionary, actions: Array
) -> String:
	if manager == null or c.is_empty() or not _CounterTempo.enabled():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return ""
	var tempo_ui: String = _UiHints.counter_tempo_hint_key(c, manager)
	if tempo_ui != "counter_ready" and tempo_ui != "counter_winding":
		return ""
	if not _CounterTempo.actions_include_counter_tempo_tagged(actions):
		return ""
	if tempo_ui == "counter_ready":
		return "Counter window open — pick a melee action to seize tempo."
	return "Incoming attack winding up — counter window building."
