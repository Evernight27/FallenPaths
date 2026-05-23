class_name CombatPlayerTurnHints
extends RefCounted

## Player `turn_ready` combat log / UI hints (action-list dependent). Display-only row hints live in **`CombatUiHints`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")


static func clear_formation_listed_turn_hint_on_combatant(c: Dictionary) -> void:
	if not c.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT)
		c.erase(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT)


## One formation **`FP_COMBAT`** line: duration/menu summary + optional rout context when **`flee`** is listed.
static func formation_and_rout_turn_ready_hint(
	manager: Node, c: Dictionary, actions: Array
) -> String:
	var form: String = _FormationMoveDuration.formation_turn_ready_ui_hint(actions)
	if manager == null or c.is_empty():
		return form
	var rout: String = rout_hint_when_flee_listed(manager, c, actions)
	if form.is_empty():
		return rout
	if rout.is_empty():
		return form
	return _merge_rout_into_formation_hint(form, rout)


static func _flee_action_display_label() -> String:
	return str(
		_BattleUIConstants.FORMATION_ACTION_LABELS.get(CombatConstants.MOVE_ID_FLEE, "Flee")
	)


static func _formation_segment_is_flee(segment: String) -> bool:
	return segment.begins_with(_flee_action_display_label())


## Append rout copy to flee segment(s) in **`Listed formation moves:`** lines; else one trailing merge.
static func _merge_rout_into_formation_hint(form: String, rout: String) -> String:
	if rout.is_empty() or form.contains(rout):
		return form
	const listed_prefix := "Listed formation moves: "
	if form.begins_with(listed_prefix):
		var segments: PackedStringArray = form.substr(listed_prefix.length()).split("; ", false)
		var merged_any := false
		for i in range(segments.size()):
			var seg: String = str(segments[i]).strip_edges()
			if _formation_segment_is_flee(seg):
				segments[i] = "%s — %s" % [seg, rout]
				merged_any = true
		if merged_any:
			return listed_prefix + "; ".join(segments)
	return "%s — %s" % [form, rout]


## Stamp or clear **`COMBATANT_KEY_FORMATION_MOVES_TURN_HINT`** for gauge tooltips this turn.
static func sync_formation_listed_turn_hint_on_combatant(
	manager: Node, c: Dictionary, actions: Array
) -> void:
	if c.is_empty():
		return
	var line: String = formation_and_rout_turn_ready_hint(manager, c, actions)
	if line.is_empty():
		clear_formation_listed_turn_hint_on_combatant(c)
	else:
		c[CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT] = line


## Back rank (or any rank) with only wait + **`focus_*`** — gauge tooltip + optional **`FP_COMBAT`** line.
static func hold_line_focus_only_hint(c: Dictionary, actions: Array) -> String:
	if c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if _EntityAccess.rank_int(c) < 1:
		return ""
	if not _ListedActions.action_list_is_hold_line_only(actions):
		return ""
	return "Back rank — no front reach this turn; adjust guard focus lines only."


static func sync_hold_line_focus_only_hint_on_combatant(c: Dictionary, actions: Array) -> void:
	if c.is_empty():
		return
	var line: String = hold_line_focus_only_hint(c, actions)
	if line.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT] = line


## Emit non-empty cowering-retreat / counter-tempo hints via **`manager.notify_combat_ui_hint`**.
static func emit_turn_ready_hints(manager: Node, c: Dictionary, actions: Array) -> void:
	if manager == null or c.is_empty():
		return
	sync_formation_listed_turn_hint_on_combatant(manager, c, actions)
	sync_hold_line_focus_only_hint_on_combatant(c, actions)
	_log_cowering_fall_back_listed_if_applicable(c, actions)
	_log_medical_pack_wound_listed_if_applicable(manager, c, actions)
	if not manager.has_method("notify_combat_ui_hint"):
		return
	for hint in [
		hold_line_focus_only_hint(c, actions),
		formation_and_rout_turn_ready_hint(manager, c, actions),
		surround_arc_overlap_hint_if_applicable(manager, c),
		cowering_retreat_hint_if_applicable(manager, c, actions),
		counter_tempo_hint_if_applicable(manager, c, actions),
	]:
		if not hint.is_empty():
			manager.notify_combat_ui_hint(hint)


## Player formation hint for gauge tooltip — same resolver as primary formation **`FP_COMBAT`** line.
static func formation_listed_moves_hint_if_applicable(
	manager: Node, c: Dictionary, actions: Array
) -> String:
	if c.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	return formation_and_rout_turn_ready_hint(manager, c, actions)


## Armed player with **`flee`** listed — cohesion / casualty context (`CombatFormationRout`).
static func rout_hint_when_flee_listed(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _MobilityRetreat.formation_retreat_only_for(c):
		return ""
	return _FormationRout.rout_hint_when_flee_listed(manager, c, actions)


## Multi-threat surround (**II-0 #3**): same copy as gauge tooltip when arc occupancy blocks weight.
static func surround_arc_overlap_hint_if_applicable(manager: Node, c: Dictionary) -> String:
	if manager == null or c.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	return _UiHints.surround_arc_occupancy_tooltip_line(c, manager)


## F5 soak (**#5**): mobile cowering with **`fall_back`** on the action list.
static func _log_cowering_fall_back_listed_if_applicable(c: Dictionary, actions: Array) -> void:
	if not _OperationalLog.is_play_session_active() or c.is_empty():
		return
	if not _EntityAccess.is_player_side(c):
		return
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		return
	if not _EntityAccess.can_flee_or_fall_back(c):
		return
	var cid: int = _EntityAccess.id_int(c)
	if not _MobilityRetreat.actions_include_self_target_move(
		actions, cid, CombatConstants.MOVE_ID_FALL_BACK
	):
		return
	_OperationalLog.play_combat(
		"cowering_fall_back listed for %s" % _EntityAccess.get_display_name(c)
	)


## F5 soak (**#7**): **`pack_wound`** on medical menu (grep before **`medical_pack_wound pick`**).
static func _log_medical_pack_wound_listed_if_applicable(
	manager: Node, c: Dictionary, actions: Array
) -> void:
	if not _OperationalLog.is_play_session_active() or manager == null or c.is_empty():
		return
	if not _EntityAccess.is_player_side(c):
		return
	if not bool(manager.medical_phase):
		return
	for entry in actions:
		if not (entry is Dictionary):
			continue
		var mid: String = str(entry.get("move_id", entry.get("id", ""))).strip_edges()
		if mid != "pack_wound":
			continue
		_F5SoakTrace.note_medical_pack_listed(
			_EntityAccess.get_display_name(c),
			str(entry.get("target_part", "")).strip_edges()
		)
		return


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
		return "No arms — holding position (fall back blocked: movement policy, line discipline, or rear rank occupied)."
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
