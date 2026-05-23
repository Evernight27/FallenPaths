class_name CombatF5SoakTrace
extends RefCounted

## Editor F5 **D-001** traces — mirror on-screen battle UI in **`FP_COMBAT`** Output (grep, no human glance).
## Call sites: **`TurnReadyHandler`**, **`BattleScene`**, **`CombatResolveAction`**.
## **`ingest_trace_line`** (via **`OperationalLog.play_combat`**) feeds **`soak_coverage`** at fight end.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const _F5Validator := preload("res://combat/CombatF5SoakLogValidator.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")

const MAX_FIGHT_TRACE_LINES := 5000

static var _session_counts: Dictionary = {}
static var _fight_end_logged: bool = false
static var _fight_profile: String = ""
static var _fight_trace_lines: PackedStringArray = PackedStringArray()


## Reset F5 soak counters (legacy alias — prefer **`prepare_fight_end_log`** on fight enter).
static func reset_session() -> void:
	prepare_fight_end_log()


## Inspector snapshot at F5 start (grep **`soak_session_plan`**).
static func log_session_plan(dev_soak_encounter: String, dev_research_feel: bool) -> void:
	if not OS.has_feature("editor"):
		return
	var soak: String = dev_soak_encounter.strip_edges().to_lower()
	_OperationalLog.play_combat(
		"soak_session_plan dev_soak_encounter=%s dev_research_feel=%s"
		% [soak if not soak.is_empty() else "(empty)", str(dev_research_feel).to_lower()]
	)
	if soak.is_empty():
		_OperationalLog.play_combat(
			"soak_session_plan fight=walk red 7v7 tile — covers formation gauge medical parry exhaustion flee (not ii5 cowering / ii6 shock / ii2b bind-only)"
		)
	else:
		_OperationalLog.play_combat(
			"soak_session_plan fight=walk cyan marker preset=%s — grep soak= on encounter_begin" % soak
		)
	if dev_research_feel:
		_OperationalLog.play_combat(
			"soak_session_plan Q1=on — expect research_feel per hit; best with dev_soak_encounter=ii2b"
		)
	else:
		_OperationalLog.play_combat(
			"soak_session_plan Q1=off — enable main dev_research_feel for per-hit research_feel lines"
		)
	_OperationalLog.play_combat(
		"soak_session_plan after fight grep soak_fight_end soak_coverage soak_validate_hint — paste full Output for agent/validator"
	)


static func set_fight_profile(profile_id: String) -> void:
	_fight_profile = profile_id.strip_edges().to_lower()


## Headless D-001 runs one log line per simulated fight (not only **`CombatManager`** phase_end).
static func prepare_fight_end_log() -> void:
	_fight_end_logged = false
	_fight_trace_lines = PackedStringArray()
	_session_counts = {
		"turn_ready": 0,
		"tooltip_ok": 0,
		"tooltip_mismatch": 0,
		"tooltip_counter": 0,
		"tooltip_medical": 0,
		"tooltip_hold_line": 0,
		"tooltip_melee_only": 0,
		"tooltip_wind_up": 0,
		"tooltip_recovering": 0,
		"tooltip_partial": 0,
		"tooltip_na": 0,
		"diagram_banner": 0,
		"medical_pack_listed": 0,
		"medical_action_pick": 0,
		"medical_pack_pick": 0,
		"engagement_transition": 0,
		"research_feel": 0,
	}


## Append fight log for **`CombatF5SoakLogValidator`** (skip startup **`soak_guide`** grep examples).
static func ingest_trace_line(message: String) -> void:
	var s: String = message.strip_edges()
	if s.is_empty():
		return
	if s.begins_with("soak_guide ") or s.begins_with("soak_guide:"):
		return
	if s.begins_with("soak_session_plan "):
		return
	if s.begins_with("soak_coverage "):
		return
	_fight_trace_lines.append(s)
	if _fight_trace_lines.size() > MAX_FIGHT_TRACE_LINES:
		_fight_trace_lines.remove_at(0)


## End-of-fight rollup for pasted-log validation (grep **`soak_fight_end`**).
static func log_fight_end_summary(winner: String, entering_medical_phase: bool) -> void:
	if _fight_end_logged or not _OperationalLog.is_play_session_active():
		return
	_fight_end_logged = true
	var parts: PackedStringArray = PackedStringArray()
	parts.append("winner=%s" % winner.strip_edges())
	parts.append("medical_phase=%s" % str(entering_medical_phase).to_lower())
	parts.append("fight_profile=%s" % (_fight_profile if not _fight_profile.is_empty() else "7v7"))
	for key in _session_counts.keys():
		parts.append("%s=%d" % [key, int(_session_counts[key])])
	_OperationalLog.play_combat("soak_fight_end %s" % " ".join(parts))
	_log_soak_coverage()
	_OperationalLog.play_combat(
		"soak_validate_hint copy full Godot Output to .f5_soak_in.txt then scripts/validate_f5_soak_log.ps1"
	)
	if int(_session_counts.get("research_feel", 0)) > 0:
		_OperationalLog.play_combat(
			"research_validate_hint %d research_feel lines — compare to docs/LIVE_PATHS.md#f5-optional-crosswalk-feel-vs-headless"
			% int(_session_counts["research_feel"])
		)
	elif _CombatConstants.combat_event_debug_verbose_active():
		_OperationalLog.play_combat(
			"research_validate_hint 0 research_feel lines — enable main dev_research_feel or land hits in combat"
		)
	if _fight_profile in [_SoakPresets.PRESET_II2B_SWORD_DUEL, _SoakPresets.PRESET_II4D_EXHAUSTION]:
		_log_q2_parry_rollup()
	if _fight_profile == _SoakPresets.PRESET_II5_COWERING:
		_log_q3_ii5_rollup()
	if _fight_profile == _SoakPresets.PRESET_II4D_EXHAUSTION:
		_log_q3_ii4d_rollup()
	if _fight_profile == _SoakPresets.PRESET_II8_FORMATION:
		_log_q4_ii8_rollup()


static func _log_q2_parry_rollup() -> void:
	var stats: Dictionary = _TrackSpecs.parry_outcome_stats(_fight_trace_lines)
	_OperationalLog.play_combat(_TrackSpecs.parry_stats_summary_line(stats))
	var plaus: PackedStringArray = _TrackSpecs.ii2b_plausibility_failures(stats)
	if plaus.is_empty():
		_OperationalLog.play_combat(
			"q2_validate_hint pass — F5 feel OK if bind/deflect/riposte timing read well; compare .ii2b_worksheet_prefill.txt"
		)
	else:
		_OperationalLog.play_combat(
			"q2_validate_hint warn %s — headless would fail; tune only if design changes (III-3)"
			% ", ".join(plaus)
		)


static func _log_q3_ii5_rollup() -> void:
	var listed: int = 0
	var executed: int = 0
	for line in _fight_trace_lines:
		if "cowering_fall_back listed" in line:
			listed += 1
		if "cowering_fall_back executed" in line:
			executed += 1
	_OperationalLog.play_combat(
		"q3_ii5_stats listed=%d executed=%d (headless needs both>=1)" % [listed, executed]
	)
	if listed >= 1 and executed >= 1:
		_OperationalLog.play_combat(
			"q3_validate_hint pass — F5 only: confirm fall_back pick UX on 2x3 world grid"
		)
	else:
		_OperationalLog.play_combat(
			"q3_validate_hint warn missing cowering_fall_back listed|executed — pick fall_back when listed"
		)


static func _log_q3_ii4d_rollup() -> void:
	var stats: Dictionary = _TrackSpecs.exhaustion_band_stats(_fight_trace_lines)
	_OperationalLog.play_combat(_TrackSpecs.exhaustion_stats_summary_line(stats))
	var plaus: PackedStringArray = _TrackSpecs.ii4d_plausibility_failures(stats, _gauge_has_exh_suffix())
	if plaus.is_empty():
		_OperationalLog.play_combat(
			"q3_validate_hint pass bands — F5 optional: 3–5 min duel pacing feel"
		)
	else:
		_OperationalLog.play_combat(
			"q3_validate_hint warn %s — headless ii4d would fail"
			% ", ".join(plaus)
		)


static func _gauge_has_exh_suffix() -> bool:
	for line in _fight_trace_lines:
		if "turn_ready_gauge" in line and "Exh" in line:
			return true
	return false


static func _log_q4_ii8_rollup() -> void:
	var banner: int = 0
	var tooltip_ok: int = 0
	for line in _fight_trace_lines:
		if "diagram_banner" in line:
			banner += 1
		if "tooltip_match=ok" in line:
			tooltip_ok += 1
	_OperationalLog.play_combat(
		"q4_ii8_stats diagram_banner=%d tooltip_match_ok=%d" % [banner, tooltip_ok]
	)
	if banner >= 1 and tooltip_ok >= 1:
		_OperationalLog.play_combat(
			"q4_validate_hint pass traces — F5 optional: widget layout / label centering glance"
		)
	else:
		_OperationalLog.play_combat(
			"q4_validate_hint warn need diagram_banner + tooltip_match=ok in formation fight"
		)


static func _log_soak_coverage() -> void:
	var profiles: PackedStringArray = _validator_profiles_for_fight()
	var result: Dictionary = _F5Validator.validate(_fight_trace_lines, profiles)
	var ok: bool = bool(result.get("ok", false))
	_OperationalLog.play_combat(
		"soak_coverage ok=%s profiles=%s trace_lines=%d"
		% [str(ok).to_lower(), ", ".join(profiles), _fight_trace_lines.size()]
	)
	var stats: Dictionary = result.get("grep_stats", {}) as Dictionary
	if not stats.is_empty():
		var stat_parts: PackedStringArray = PackedStringArray()
		for stat_key in stats.keys():
			stat_parts.append("%s=%d" % [str(stat_key), int(stats[stat_key])])
		_OperationalLog.play_combat("soak_coverage grep_stats %s" % " ".join(stat_parts))
	var tracks: Dictionary = result.get("tracks", {}) as Dictionary
	for track_id in tracks.keys():
		var tr: Dictionary = tracks[track_id] as Dictionary
		if bool(tr.get("pass", false)):
			continue
		var optional: bool = bool(tr.get("optional", false))
		var tag: String = "warn" if optional else "fail"
		_OperationalLog.play_combat(
			"soak_coverage %s [%s] %s" % [tag, track_id, str(tr.get("detail", ""))]
		)
	for f in result.get("failures", PackedStringArray()) as PackedStringArray:
		_OperationalLog.play_combat("soak_coverage fail %s" % f)
	for w in result.get("warnings", PackedStringArray()) as PackedStringArray:
		_OperationalLog.play_combat("soak_coverage warn %s" % w)
	var missing: PackedStringArray = result.get("missing_cyan_presets", PackedStringArray()) as PackedStringArray
	if not missing.is_empty():
		_OperationalLog.play_combat(
			"soak_coverage note full II-0 needs cyan presets in other F5 runs: %s"
			% ", ".join(missing)
		)
	if ok:
		_OperationalLog.play_combat(
			"soak_coverage pass this fight matches D-001 validator for %s — still grep FP_ERROR SCRIPT_ERROR in Output"
			% ", ".join(profiles)
		)


static func _validator_profiles_for_fight() -> PackedStringArray:
	var profiles: PackedStringArray = PackedStringArray([_TrackSpecs.PROFILE_ALWAYS])
	match _fight_profile:
		_SoakPresets.PRESET_II2B_SWORD_DUEL, "ii2b":
			profiles.append(_TrackSpecs.PROFILE_PRESET_II2B)
		_SoakPresets.PRESET_II3_SURROUND, "ii3":
			profiles.append(_TrackSpecs.PROFILE_PRESET_II3)
		_SoakPresets.PRESET_II5_COWERING, "ii5":
			profiles.append(_TrackSpecs.PROFILE_PRESET_II5)
		_SoakPresets.PRESET_II6_AMBIENT_SHOCK, "ii6":
			profiles.append(_TrackSpecs.PROFILE_PRESET_II6)
		_SoakPresets.PRESET_II8_FORMATION, "ii8":
			profiles.append(_TrackSpecs.PROFILE_PRESET_II8)
		_SoakPresets.PRESET_II4D_EXHAUSTION, "ii4d":
			profiles.append(_TrackSpecs.PROFILE_PRESET_II4D)
		_:
			profiles.append(_TrackSpecs.PROFILE_7V7)
	return profiles


## F5 optional: per-hit damage outcome when **`COMBAT_DEV_VERBOSE`** (grep **`research_feel`**).
static func note_research_damage_outcome(part: String, result: Dictionary, extras: Dictionary) -> void:
	if not _CombatConstants.combat_event_debug_verbose_active():
		return
	if not _OperationalLog.is_play_session_active():
		return
	_bump("research_feel")
	var sub: String = str(extras.get("hit_sub_region", ""))
	var pen: float = float(result.get("penetration_to_tissue_mm", extras.get("penetration_to_tissue_mm", -1.0)))
	var ke_frac: float = float(result.get("transmitted_ke_fraction", 1.0))
	_OperationalLog.play_combat(
		"research_feel part=%s sub=%s cut=%.1f blunt=%.1f bone=%.1f pen_mm=%.1f ke_frac=%.2f"
		% [
			part,
			sub if not sub.is_empty() else "-",
			float(result.get("final_cut", 0.0)),
			float(result.get("final_blunt", 0.0)),
			float(result.get("final_bone", 0.0)),
			pen,
			ke_frac,
		]
	)


static func note_engagement_transition(from_mode: String, to_mode: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	_bump("engagement_transition")
	_OperationalLog.play_combat("engagement_transition %s -> %s" % [from_mode, to_mode])


static func note_formation_move_pick(move_id: String, initiator_id: int, partner_id: int) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	_OperationalLog.play_combat("%s@%d" % [move_id.strip_edges(), partner_id])


static func note_medical_pack_listed(who: String, part: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	_bump("medical_pack_listed")
	_OperationalLog.play_combat("medical_pack_wound listed for %s part=%s" % [who, part])


static func note_medical_action_pick(who: String, move_id: String, part: String, tgt_desc: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	_bump("medical_action_pick")
	_OperationalLog.play_combat(
		"medical_action pick %s move=%s part=%s (%s)" % [who, move_id, part, tgt_desc]
	)
	if move_id == "pack_wound":
		_bump("medical_pack_pick")
		_OperationalLog.play_combat(
			"medical_pack_wound pick %s part=%s (%s)" % [who, part, tgt_desc]
		)


## Player **`turn_ready`**: row gauge label + formation tooltip vs turn-ready formation line (**II-5a / II-5c**).
static func log_turn_ready_player_ui(manager: Node, c: Dictionary, actions: Array) -> void:
	if not _OperationalLog.is_play_session_active() or c.is_empty():
		return
	if not _EntityAccess.is_player_side(c):
		return
	var cid: int = _EntityAccess.id_int(c)
	var who: String = _EntityAccess.get_display_name(c, cid)
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, manager)
	var stamp: String = _formation_stamp_on_combatant(c)
	var hold: String = str(
		c.get(_CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")
	).strip_edges()
	var fp_line: String = _PlayerTurnHints.formation_and_rout_turn_ready_hint(manager, c, actions).strip_edges()
	var ctx: String = _turn_ui_match_context(manager, c, actions, label, fp_line, hold)
	var formation_tip: String = ""
	var match_s: String = ctx
	if ctx.is_empty():
		formation_tip = stamp if not stamp.is_empty() else _formation_line_from_tooltip(c, manager)
		if formation_tip.is_empty() and not hold.is_empty():
			formation_tip = hold
		match_s = _tooltip_formation_match_label(formation_tip, fp_line, hold)
	else:
		# Counter / medical / melee-only — avoid stale formation stamp in gauge_tooltip_formation.
		if not fp_line.is_empty():
			formation_tip = fp_line
		elif ctx == "hold_line" and not hold.is_empty():
			formation_tip = hold
	_bump("turn_ready")
	_bump(_tooltip_match_counter_key(match_s))
	_OperationalLog.play_combat(
		"turn_ready_gauge id=%d %s label=%s tooltip_match=%s"
		% [cid, who, label, match_s]
	)
	if not formation_tip.is_empty():
		_OperationalLog.play_combat(
			"gauge_tooltip_formation id=%d %s line=%s" % [cid, who, formation_tip]
		)
	if not fp_line.is_empty():
		_OperationalLog.play_combat(
			"turn_ready_formation_line id=%d %s line=%s" % [cid, who, fp_line]
		)


## Party diagram header (same string as **`engagement ui player:`** — **#8**).
static func log_diagram_banner_player(line: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var text: String = line.strip_edges()
	if text.is_empty() or text == "—":
		return
	_bump("diagram_banner")
	_OperationalLog.play_combat("diagram_banner player: %s" % text)


static func _bump(counter_key: String) -> void:
	if counter_key.is_empty():
		return
	_session_counts[counter_key] = int(_session_counts.get(counter_key, 0)) + 1


static func _tooltip_match_counter_key(match_s: String) -> String:
	match match_s:
		"ok":
			return "tooltip_ok"
		"mismatch":
			return "tooltip_mismatch"
		"counter":
			return "tooltip_counter"
		"medical":
			return "tooltip_medical"
		"hold_line":
			return "tooltip_hold_line"
		"melee_only":
			return "tooltip_melee_only"
		"wind_up":
			return "tooltip_wind_up"
		"recovering":
			return "tooltip_recovering"
		"partial":
			return "tooltip_partial"
		_:
			return "tooltip_na"


static func _formation_stamp_on_combatant(c: Dictionary) -> String:
	return str(c.get(_CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()


static func _formation_line_from_tooltip(c: Dictionary, manager: Node) -> String:
	var stamp: String = _formation_stamp_on_combatant(c)
	if not stamp.is_empty():
		return stamp
	var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, manager)
	for tip in tips:
		var t: String = str(tip).strip_edges()
		if _looks_like_formation_turn_hint(t) and not _is_formation_duration_preview_only(t):
			return t
	return ""


## Generic duration preview (`Formation move: ~1.4s, under pressure`) — not the stamped turn line.
static func _is_formation_duration_preview_only(text: String) -> bool:
	var t: String = text.strip_edges()
	if not t.begins_with("Formation move:"):
		return false
	return not (
		t.contains("Rotate file")
		or t.contains("Swap rank")
		or t.contains("Drag back")
		or t.contains("Fall back")
		or t.contains("Flee")
		or t.contains("Listed formation")
		or t.contains("Formation actions")
		or t.contains("Close distance")
		or t.begins_with("Back rank")
	)


static func _looks_like_formation_turn_hint(text: String) -> bool:
	if text.is_empty():
		return false
	if text.begins_with("Back rank"):
		return true
	if text.contains("Formation move") or text.contains("Rotate file") or text.contains("Flee"):
		return true
	if text.contains("Listed formation moves") or text.contains("Formation actions"):
		return true
	return false


## Non-formation row labels — grep **`tooltip_match=counter`** / **`medical`** / **`melee_only`** (not II-5a failures).
static func _turn_ui_match_context(
	manager: Node,
	c: Dictionary,
	actions: Array,
	label: String,
	fp_line: String,
	hold_line: String
) -> String:
	var state: String = _EntityAccess.state_str(c)
	if state == CombatConstants.STATE_WIND_UP:
		return "wind_up"
	if state == CombatConstants.STATE_RECOVERING:
		return "recovering"
	if (
		state == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		or state == "medical_wind_up"
		or label.begins_with("Receiving care")
		or label.begins_with("Recov.")
	):
		return "medical"
	if label.begins_with("Counter!") or label.begins_with("Seize tempo"):
		return "counter"
	if manager != null:
		var tempo_key: String = _UiHints.counter_tempo_hint_key(c, manager)
		if not _UiHints.counter_tempo_gauge_label(tempo_key).is_empty():
			if label.begins_with("Counter") or label.begins_with("Seize tempo"):
				return "counter"
	if (
		state == CombatConstants.STATE_WAITING
		and fp_line.is_empty()
		and not hold_line.is_empty()
		and _ListedActions.action_list_is_hold_line_only(actions)
	):
		return "hold_line"
	if state == CombatConstants.STATE_WAITING and fp_line.is_empty() and hold_line.is_empty():
		if not _actions_include_formation_menu(actions):
			return "melee_only"
	return ""


static func _actions_include_formation_menu(actions: Array) -> bool:
	for entry in actions:
		if not (entry is Dictionary):
			continue
		var mid: String = str(entry.get("move_id", entry.get("id", ""))).strip_edges()
		if mid.is_empty() or mid == CombatConstants.MOVE_ID_WAIT:
			continue
		if mid.begins_with("focus_"):
			continue
		if (
			mid
			in [
				CombatConstants.MOVE_ID_ROTATE_FILE,
				CombatConstants.MOVE_ID_SWAP_RANK,
				CombatConstants.MOVE_ID_FALL_BACK,
				CombatConstants.MOVE_ID_DRAG_BACK,
				CombatConstants.MOVE_ID_FLEE,
				CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
			]
		):
			return true
		if mid.begins_with("rotate_file") or mid.begins_with("swap_rank") or mid.begins_with("flee"):
			return true
	return false


static func _tooltip_formation_match_label(
	tooltip_line: String, fp_line: String, hold_line: String = ""
) -> String:
	if tooltip_line.is_empty() and fp_line.is_empty() and hold_line.is_empty():
		return "n/a"
	# Back rank wait+focus only: hold-line tooltip, no formation **`FP_COMBAT`** line.
	if not hold_line.is_empty() and fp_line.is_empty():
		if tooltip_line.is_empty() or tooltip_line == hold_line:
			return "ok"
	if tooltip_line.is_empty() or fp_line.is_empty():
		return "partial"
	if tooltip_line == fp_line:
		return "ok"
	if tooltip_line in fp_line or fp_line in tooltip_line:
		return "ok"
	return "mismatch"
