class_name CombatPlayerTurnHints
extends RefCounted

## Player `turn_ready` combat log / UI hints (action-list dependent). Display-only row hints live in **`CombatUiHints`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")


## Emit non-empty crash / cowering-retreat / counter-tempo hints via **`manager.notify_combat_ui_hint`**.
static func emit_turn_ready_hints(manager: Node, c: Dictionary, actions: Array) -> void:
	if manager == null or c.is_empty() or not manager.has_method("notify_combat_ui_hint"):
		return
	for hint in [
		crash_absence_hint_if_missing(manager, c, actions),
		cowering_retreat_hint_if_applicable(manager, c, actions),
		counter_tempo_hint_if_applicable(manager, c, actions),
	]:
		if not hint.is_empty():
			manager.notify_combat_ui_hint(hint)


## One line when crash is absent but breach viability suggests it matters.
static func crash_absence_hint_if_missing(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty():
		return ""
	if _EntityAccess.side_str(c) != "player":
		return ""
	if bool(manager.medical_phase):
		return ""
	if _ZoneOfControl.is_intruded(c):
		return ""
	if _EntityAccess.rank_int(c) != 0:
		return ""
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return ""
	var crash_count: int = 0
	for a in actions:
		if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
			crash_count += 1
	if crash_count > 0:
		return ""
	if CombatConstants.crash_breach_viability(c) < CombatConstants.CRASH_BREACH_VIABILITY_MIN:
		return ""
	var raw: String = _ActionsBuilder.crash_absent_primary_reason(manager, c)
	if raw.is_empty() or raw == "crash_eligible_but_missing_bug":
		return ""
	return _ActionsBuilder.format_crash_absent_reason_for_ui(raw)


## Cowering (no arms) with mobile legs — when solo **fall_back** is listed vs wait-only.
static func cowering_retreat_hint_if_applicable(
	manager: Node, c: Dictionary, actions: Array
) -> String:
	if manager == null or c.is_empty():
		return ""
	if _EntityAccess.side_str(c) != "player":
		return ""
	if bool(manager.medical_phase):
		return ""
	if not _MobilityRetreat.formation_retreat_only_for(c):
		return ""
	if not _EntityAccess.can_flee_or_fall_back(c):
		return ""
	var has_fall_back: bool = false
	var has_wait: bool = false
	for a in actions:
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_FALL_BACK:
			has_fall_back = true
		elif mid == CombatConstants.MOVE_ID_WAIT:
			has_wait = true
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
	if _EntityAccess.side_str(c) != "player":
		return ""
	if bool(manager.medical_phase):
		return ""
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return ""
	var tempo_ui: String = _UiHints.counter_tempo_hint_key(c, manager)
	if tempo_ui != "counter_ready" and tempo_ui != "counter_winding":
		return ""
	var has_counter_action: bool = false
	for a in actions:
		if typeof(a) != TYPE_DICTIONARY:
			continue
		if bool((a as Dictionary).get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			has_counter_action = true
			break
	if not has_counter_action:
		return ""
	if tempo_ui == "counter_ready":
		return "Counter window open — pick a melee action to seize tempo."
	return "Incoming attack winding up — counter window building."
