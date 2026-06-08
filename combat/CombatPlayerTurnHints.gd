class_name CombatPlayerTurnHints
extends RefCounted

## Player `turn_ready` combat log / UI hints (action-list dependent). Display-only row hints live in **`CombatUiHints`**.
## Footing: does **not** write **`guard_line`**, **`weapon_form`**, or PA offset — gauge suffixes via **`BattleUIUpdater`**. LIVE_PATHS **`#battle-ui`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")


static func clear_formation_listed_turn_hint_on_combatant(c: Dictionary) -> void:
	if not c.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT)
		c.erase(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT)
		c.erase(CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT)


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
static func line_plug_gauge_suffix(manager: Node, c: Dictionary, actions: Array) -> String:
	var plug: String = front_gap_line_plug_hint(manager, c, actions)
	if not plug.is_empty():
		return plug
	var rotate: String = skirmish_line_gap_rotate_hint(manager, c, actions)
	if not rotate.is_empty():
		return rotate
	return plug_forward_incap_partner_hint(manager, c, actions)


static func sync_formation_listed_turn_hint_on_combatant(
	manager: Node, c: Dictionary, actions: Array
) -> void:
	if c.is_empty():
		return
	var line: String = formation_and_rout_turn_ready_hint(manager, c, actions)
	var plug_suffix: String = line_plug_gauge_suffix(manager, c, actions)
	if not plug_suffix.is_empty():
		line = ("%s — %s" % [line, plug_suffix]) if not line.is_empty() else plug_suffix
	if line.is_empty():
		clear_formation_listed_turn_hint_on_combatant(c)
	else:
		c[CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT] = line


## Reserve posture (wait / focus / close only): gauge tooltip for back rank or outflanked wing.
static func hold_line_focus_only_hint(manager: Node, c: Dictionary, actions: Array) -> String:
	if c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	var cid: int = _EntityAccess.id_int(c)
	var fid: String = _EntityAccess.formation_id_str(c)
	if (
		manager != null
		and not fid.is_empty()
		and _CombatDoctrine.envelop_mop_up_active(manager, fid)
		and _ListedActions.action_list_has_hostile_melee_strike(actions, cid)
	):
		return "Mop-up — finish the last enemy with a listed strike."
	if (
		manager != null
		and _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, actions, cid)
		and _ListedActions.action_list_has_hostile_melee_strike(actions, cid)
	):
		return "Line open after rout — close in or strike; shuffle won't fill distant gaps."
	if not _ListedActions.action_list_is_reserve_posture_only(actions):
		return ""
	if (
		manager != null
		and not fid.is_empty()
		and _CombatDoctrine.envelop_mop_up_active(manager, fid)
		and _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_ATTEMPT_CLOSE)
	):
		return "Mop-up — finish the last enemy; close in or strike."
	if _EntityAccess.rank_int(c) >= 1:
		return "Back rank — no front reach this turn; adjust guard focus lines only."
	if (
		manager != null
		and _reserve_posture_needs_bind_close(manager, c, actions)
	):
		return "Assigned foe out of reach — close in to bind."
	if (
		manager != null
		and _EngagementOpposition.wing_lacks_mapped_opposition(manager, c)
		and _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_ATTEMPT_CLOSE)
	):
		return "Wing — no mapped front; close in or adjust guard focus."
	if (
		manager != null
		and _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(
			manager, c, actions, _EntityAccess.id_int(c)
		)
	):
		return "Line open after rout — close in or strike; shuffle won't fill distant gaps."
	return ""


## Reserve-only menu with **`attempt_close`** at LONG when geometric reach already covers — false.
static func _reserve_posture_needs_bind_close(
	manager: Node, c: Dictionary, actions: Array
) -> bool:
	if manager == null or c.is_empty() or actions.is_empty():
		return false
	if _EntityAccess.rank_int(c) != 0:
		return false
	if not _ListedActions.action_list_is_reserve_posture_only(actions):
		return false
	if not _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
		return false
	if _ListedActions.action_list_has_hostile_melee_strike(actions, _EntityAccess.id_int(c)):
		return false
	return _EngagementOpposition.rank0_needs_bind_close_at_long(manager, c)


static func sync_hold_line_focus_only_hint_on_combatant(manager: Node, c: Dictionary, actions: Array) -> void:
	if c.is_empty():
		return
	var line: String = hold_line_focus_only_hint(manager, c, actions)
	if line.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT] = line


static func sync_controlling_close_turn_hint_on_combatant(
	manager: Node, c: Dictionary, actions: Array
) -> void:
	if c.is_empty():
		return
	var line: String = _UiHints.controlling_defender_close_hint_line(manager, c, actions)
	if line.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT] = line


## Emit non-empty cowering-retreat / counter-tempo hints via **`manager.notify_combat_ui_hint`**.
static func emit_turn_ready_hints(manager: Node, c: Dictionary, actions: Array) -> void:
	if manager == null or c.is_empty():
		return
	sync_formation_listed_turn_hint_on_combatant(manager, c, actions)
	sync_hold_line_focus_only_hint_on_combatant(manager, c, actions)
	sync_controlling_close_turn_hint_on_combatant(manager, c, actions)
	_log_cowering_fall_back_listed_if_applicable(c, actions)
	_log_medical_pack_wound_listed_if_applicable(manager, c, actions)
	if not manager.has_method("notify_combat_ui_hint"):
		return
	var arc_hint: String = surround_arc_overlap_hint_if_applicable(manager, c)
	if not arc_hint.is_empty():
		manager.notify_combat_ui_hint(arc_hint)
	var cow_hint: String = cowering_retreat_hint_if_applicable(manager, c, actions)
	if not cow_hint.is_empty():
		# Combat log only — row gauge tooltip carries the shorter cowering copy for FP.
		manager.notify_combat_ui_hint(cow_hint, false)
	var counter_hint: String = counter_tempo_hint_if_applicable(manager, c, actions)
	if not counter_hint.is_empty():
		# Combat log only — gauge + **`turn_ready_gauge`** (`tooltip_match=counter`) cover FP.
		manager.notify_combat_ui_hint(counter_hint, false)
	# Combat log only — **`TurnReadyHandler`** logs **`turn_ready_formation_line`** / gauge tooltip to FP.
	var form_hint: String = formation_and_rout_turn_ready_hint(manager, c, actions)
	if not form_hint.is_empty():
		manager.notify_combat_ui_hint(form_hint, false)
	var hold_hint: String = hold_line_focus_only_hint(manager, c, actions)
	if not hold_hint.is_empty():
		_F5SoakTrace.note_mopup_hold_line_listed(c, hold_hint)
		manager.notify_combat_ui_hint(hold_hint, false)
	var rout_early: String = rout_pressure_early_hint(manager, c, actions)
	if not rout_early.is_empty():
		manager.notify_combat_ui_hint(rout_early, false)
	var plug_hint: String = front_gap_line_plug_hint(manager, c, actions)
	if not plug_hint.is_empty():
		manager.notify_combat_ui_hint(plug_hint, false)
	var plug_fwd: String = plug_forward_incap_partner_hint(manager, c, actions)
	if not plug_fwd.is_empty():
		manager.notify_combat_ui_hint(plug_fwd, false)
	var rotate_gap: String = skirmish_line_gap_rotate_hint(manager, c, actions)
	if not rotate_gap.is_empty() and hold_hint.is_empty():
		_F5SoakTrace.note_mopup_hold_line_listed(c, rotate_gap)
		manager.notify_combat_ui_hint(rotate_gap, false)
	var wf_hint: String = _weapon_form_turn_ready_hint_if_applicable(c)
	if not wf_hint.is_empty():
		manager.notify_combat_ui_hint(wf_hint, false)
	var close_ctrl_hint: String = _UiHints.controlling_defender_close_hint_line(manager, c, actions)
	if not close_ctrl_hint.is_empty():
		_F5SoakTrace.note_controlling_close_listed(c, close_ctrl_hint)
		manager.notify_combat_ui_hint(close_ctrl_hint, false)


## Player-side spawn form identity (read-only — no in-fight switch).
static func _weapon_form_turn_ready_hint_if_applicable(c: Dictionary) -> String:
	if c.is_empty() or not _EntityAccess.is_player_side(c):
		return ""
	var line: String = _UiHints.weapon_form_tooltip_line(c)
	if line.is_empty():
		return ""
	return line


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


## Player hint when the line is wavering but **`flee`** is not listed yet (p4f UX).
static func rout_pressure_early_hint(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _MobilityRetreat.formation_retreat_only_for(c):
		return ""
	if _ListedActions.actions_include_self_target_move(
		actions, _EntityAccess.id_int(c), CombatConstants.MOVE_ID_FLEE
	):
		return ""
	if not _FormationRout.formation_stressed_for_rout(manager, c):
		return ""
	if (
		_FormationRout.side_holding_field(manager, c)
		and not _FormationRout.personal_rout_pressure(manager, c)
	):
		return ""
	var line: String = _FormationRout.rout_pressure_tooltip_line(manager, c)
	if line.is_empty():
		return ""
	return "Line wavering — %s" % line


## Player hint when a rank-0 gap exists and **`swap_rank`** is listed for a rear reserve.
static func front_gap_line_plug_hint(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _EntityAccess.rank_int(c) <= 0:
		return ""
	var fid: String = _EntityAccess.formation_id_str(c)
	if fid.is_empty():
		return ""
	if not _FormationFlow.formation_line_has_rank0_gap(manager, fid):
		return ""
	if _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
		return ""
	if not _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_SWAP_RANK):
		return ""
	return "Front gap — swap up to fill the line."


## Player hint when a rear reserve may **`swap_rank`** forward over an incapacitated partner.
static func plug_forward_incap_partner_hint(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _EntityAccess.rank_int(c) <= 0:
		return ""
	if not _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_SWAP_RANK):
		return ""
	var our_rank: int = _EntityAccess.rank_int(c)
	for raw in actions:
		if raw is not Dictionary:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
			continue
		var partner: Dictionary = _EntityAccess.manager_get_combatant_optional(
			manager, int(a.get("target_id", -1))
		)
		if partner.is_empty():
			continue
		if _EntityAccess.rank_int(partner) >= our_rank:
			continue
		if not _EntityAccess.is_incapacitated(partner):
			continue
		return "Partner down — step up to hold the line."
	return ""


## Player hint when Skirmish **`rotate_file`** is listed and the line still has rank-0 holes.
static func skirmish_line_gap_rotate_hint(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	if bool(manager.medical_phase):
		return ""
	if _EntityAccess.rank_int(c) != 0:
		return ""
	if str(_EngagementMode.engagement_mode(manager)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		return ""
	var fid: String = _EntityAccess.formation_id_str(c)
	if fid.is_empty():
		return ""
	if not _FormationFlow.formation_has_rank0_hole(manager, fid):
		return ""
	var cid: int = _EntityAccess.id_int(c)
	if _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, actions, cid):
		return "Line open — close or strike; adjacent shuffle won't fill distant gaps."
	if not _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_ROTATE_FILE):
		return ""
	return "Line gap — rotate with an adjacent file to tighten the front."


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
	_F5SoakTrace.note_cowering_fall_back_listed(_EntityAccess.get_display_name(c))


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
		if mid != CombatConstants.MOVE_ID_PACK_WOUND:
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
