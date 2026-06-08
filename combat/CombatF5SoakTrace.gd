class_name CombatF5SoakTrace
extends RefCounted

## Editor F5 **D-001** traces — mirror on-screen battle UI in **`FP_COMBAT`** Output (grep, no human glance).
## **`turn_ready_gauge`**: full label via **`BattleUIUpdater`** — suffix order **Step → Grd/Atk → Form** when present; content asserts **open** — LIVE_PATHS **`#wf-soak-audit-status`** · **`#battle-ui`** · **`#wf-footing-doc-map`**.
## Call sites: **`TurnReadyHandler`**, **`BattleScene`**, **`CombatResolveAction`**.
## **`ingest_trace_line`** (via **`OperationalLog.play_combat`**) feeds **`soak_coverage`** at fight end.
## **`ingest_world_trace_line`** (via **`OperationalLog.play_world`**) appends Camp §8 markers for post-medical supplement.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _LogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const _F5Validator := preload("res://combat/CombatF5SoakLogValidator.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _EngagementDiag := preload("res://combat/CombatEngagementDiagnostics.gd")

## One-line F5 follow-ups when optional Camp §8 validator tracks are still open.
const _CAMP_OPTIONAL_PLAY_HINTS := {
	"camp_field_care": "after messy win grep FP_WORLD field_care: hint on map",
	"camp_field_care_action": "map Party -> bandage or pressure one part (grep FP_WORLD field_care bandage part=)",
	"camp_paid_loss": "lose a paid contract (grep company_run_end reason=contract_failed reload=true)",
	"camp_tutorial_soft_loss": "lose tutorial 2v2 (grep company_run_end reason=tutorial_failed reload=false)",
	"camp_wage_warn": "End day with gold below next wage bill (grep company_wages: gold=)",
	"camp_desertion": "End day while broke until desertion summary= or bankrupt run-end",
	"camp_party_triage": "open Party on map once (grep party_triage_open living=)",
	"camp_medical_exit": "Finish medical treatment batch on tutorial or messy fight (grep campaign_medical_exit)",
	"camp_mopup_strike_finish": "win via rout mop-up strikes in Escort/Border (grep mop_up=true strikes_listed)",
	"camp_line_plug_pick": "sparse post-flee rank-0 gap swap or ii_envelop wing fight (line_plug_pick=1)",
	"camp_run_end": "any company_run_end reason= (paid loss, tutorial soft, or bankrupt)",
}

const MAX_FIGHT_TRACE_LINES := 5000

static var _session_counts: Dictionary = {}
static var _fight_end_logged: bool = false
static var _defer_soak_coverage_for_medical: bool = false
static var _soak_coverage_logged: bool = false
static var _medical_phase_intro_logged: bool = false
static var _research_validate_hint_logged: bool = false
static var _soak_validate_hint_logged: bool = false
static var _soak_coverage_deferred_note_logged: bool = false
static var _last_camp_supplement_key: String = ""
static var _session_camp_trace_lines: PackedStringArray = PackedStringArray()
static var _session_camp_combat_trace_lines: PackedStringArray = PackedStringArray()
static var _last_cowering_fall_back_executed_line: String = ""
static var _last_fled_line: String = ""
static var _last_ambient_pain_shock_line: String = ""
static var _last_death_tick_line: String = ""
static var _last_exhaustion_crossing_line: String = ""
static var _fight_profile: String = ""
static var _fight_trace_lines: PackedStringArray = PackedStringArray()
static var _last_diagram_banner_line: String = ""
static var _last_diagram_banner_enemy_line: String = ""
static var _last_turn_ready_formation_fp_line: String = ""
static var _last_gauge_tooltip_formation_fp_line: String = ""
static var _last_turn_ready_gauge_sig: String = ""
static var _last_engagement_transition_line: String = ""
static var _last_strike_avoided_line: String = ""
static var _last_hit_resolve_line: String = ""
static var _last_formation_move_pick_line: String = ""
static var _last_medical_pack_listed_line: String = ""
static var _last_research_feel_line: String = ""
static var _last_cowering_fall_back_listed_line: String = ""
static var _last_fall_back_pick_line: String = ""
static var _last_medical_action_pick_line: String = ""


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
		"soak_session_plan after fight grep hit_resolve reason= strike_avoided reason= diagram_banner player: engagement_transition hit_outcome_stats parry_stats soak_fight_end soak_coverage — paste full Output"
	)


static func set_fight_profile(profile_id: String) -> void:
	_fight_profile = profile_id.strip_edges().to_lower()


## Clear Camp §8 **`FP_WORLD`** lines accumulated since F5 session start (call once from **`main.gd`**).
static func reset_session_camp_trace() -> void:
	_session_camp_trace_lines = PackedStringArray()
	_session_camp_combat_trace_lines = PackedStringArray()
	_last_camp_supplement_key = ""


## Headless D-001 runs one log line per simulated fight (not only **`CombatManager`** phase_end).
## New fight: archive prior fight camp combat needles, then reset per-fight trace
## (Camp **`FP_WORLD`** kept in **`_session_camp_trace_lines`** until session reset).
static func prepare_fight_end_log() -> void:
	_archive_fight_camp_combat_lines()
	reset_fight_trace_buffer()
	_EngagementDiag.reset_session()
	_last_diagram_banner_line = ""
	_last_diagram_banner_enemy_line = ""
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
		"hit_resolve": 0,
		"hit_outcome_hit": 0,
		"hit_outcome_glancing": 0,
		"hit_outcome_negligible": 0,
		"hit_outcome_deflected": 0,
		"hit_outcome_other": 0,
		"strike_avoided": 0,
		"strike_avoided_miss": 0,
		"strike_avoided_dodge": 0,
	}


## Headless **`_simulate_fight`**: clear trace only — keep **`_session_counts`** from setup / early probes.
static func reset_fight_trace_buffer() -> void:
	_fight_end_logged = false
	_defer_soak_coverage_for_medical = false
	_soak_coverage_logged = false
	_medical_phase_intro_logged = false
	_research_validate_hint_logged = false
	_soak_validate_hint_logged = false
	_soak_coverage_deferred_note_logged = false
	_last_camp_supplement_key = ""
	_fight_trace_lines = PackedStringArray()
	_last_turn_ready_formation_fp_line = ""
	_last_gauge_tooltip_formation_fp_line = ""
	_last_turn_ready_gauge_sig = ""
	_last_engagement_transition_line = ""
	_last_strike_avoided_line = ""
	_last_hit_resolve_line = ""
	_last_formation_move_pick_line = ""
	_last_medical_pack_listed_line = ""
	_last_research_feel_line = ""
	_last_cowering_fall_back_listed_line = ""
	_last_fall_back_pick_line = ""
	_last_medical_action_pick_line = ""
	_last_cowering_fall_back_executed_line = ""
	_last_fled_line = ""
	_last_ambient_pain_shock_line = ""
	_last_death_tick_line = ""
	_last_exhaustion_crossing_line = ""
	_OperationalLog.reset_fight_fp_channel_dedupe()


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
	# Fight-end rollups — do not re-ingest (avoids inflating parry/grep stats if trace is re-parsed).
	if (
		s.begins_with("parry_stats ")
		or s.begins_with("hit_outcome_stats ")
		or s.begins_with("hit_coverage_hint ")
		or s.begins_with("q2_validate_hint ")
		or s.begins_with("q3_validate_hint ")
		or s.begins_with("q3_ii5_stats ")
		or s.begins_with("q4_ii8_stats ")
		or s.begins_with("q4_validate_hint ")
		or s.begins_with("exhaustion_stats ")
		or s.begins_with("soak_fight_end ")
		or s.begins_with("soak_validate_hint ")
		or s.begins_with("research_validate_hint ")
	):
		return
	if _fight_trace_lines.size() > 0 and _fight_trace_lines[_fight_trace_lines.size() - 1] == s:
		return
	_fight_trace_lines.append(s)
	if _fight_trace_lines.size() > MAX_FIGHT_TRACE_LINES:
		_fight_trace_lines.remove_at(0)
	if _soak_coverage_logged and "campaign_medical_exit" in s:
		refresh_camp_supplement_after_medical_exit()


## Rollup lines are emitted via **`play_combat`** but excluded from **`ingest_trace_line`** — append directly.
static func _append_fight_trace_line_direct(s: String) -> void:
	var line: String = s.strip_edges()
	if line.is_empty():
		return
	if _fight_trace_lines.size() > 0 and _fight_trace_lines[_fight_trace_lines.size() - 1] == line:
		return
	_fight_trace_lines.append(line)
	if _fight_trace_lines.size() > MAX_FIGHT_TRACE_LINES:
		_fight_trace_lines.remove_at(0)


## Camp §8 markers (**`FP_WORLD`**) land after medical — extend trace for in-editor camp supplement.
static func ingest_world_trace_line(message: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var s: String = message.strip_edges()
	if s.is_empty():
		return
	if not _TrackSpecs.is_camp_ea_world_trace_line(s):
		return
	_append_fight_trace_line_direct(s)
	if _session_camp_trace_lines.is_empty() or _session_camp_trace_lines[_session_camp_trace_lines.size() - 1] != s:
		_session_camp_trace_lines.append(s)
	if _fight_end_logged and _soak_coverage_logged and _should_refresh_camp_supplement(s):
		_log_soak_coverage_camp_supplement()


## End-of-fight rollup for pasted-log validation (grep **`soak_fight_end`**).
static func log_fight_end_summary(winner: String, entering_medical_phase: bool) -> void:
	if _fight_end_logged or not _OperationalLog.is_play_session_active():
		return
	_reconcile_session_hit_counts_from_fight_trace()
	_fight_end_logged = true
	var parts: PackedStringArray = PackedStringArray()
	parts.append("winner=%s" % winner.strip_edges())
	parts.append("medical_phase=%s" % str(entering_medical_phase).to_lower())
	parts.append("fight_profile=%s" % (_fight_profile if not _fight_profile.is_empty() else "7v7"))
	for key in _session_counts.keys():
		parts.append("%s=%d" % [key, int(_session_counts[key])])
	var end_line: String = "soak_fight_end %s" % " ".join(parts)
	_OperationalLog.play_combat(end_line)
	_append_fight_trace_line_direct(end_line)
	if entering_medical_phase:
		_defer_soak_coverage_for_medical = true
	else:
		_log_soak_coverage()
	if not _soak_validate_hint_logged:
		_soak_validate_hint_logged = true
		_OperationalLog.play_combat(
			"soak_validate_hint copy full Godot Output to .f5_soak_in.txt then scripts/validate_f5_soak_log.ps1"
		)
	if not _research_validate_hint_logged:
		_research_validate_hint_logged = true
		if int(_session_counts.get("research_feel", 0)) > 0:
			_OperationalLog.play_combat(
				"research_validate_hint %d research_feel lines — compare to docs/LIVE_PATHS.md#f5-optional-crosswalk-feel-vs-headless"
				% int(_session_counts["research_feel"])
			)
		elif _CombatConstants.combat_event_debug_verbose_active():
			_OperationalLog.play_combat(
				"research_validate_hint 0 research_feel lines — enable main dev_research_feel or land hits in combat"
			)
	_log_parry_rollup()
	_log_hit_outcome_rollup()
	_log_hit_coverage_hint()
	if _fight_profile in [_SoakPresets.PRESET_II2B_SWORD_DUEL, _SoakPresets.PRESET_II4D_EXHAUSTION]:
		_log_q2_parry_rollup()
	if _fight_profile == _SoakPresets.PRESET_II5_COWERING:
		_log_q3_ii5_rollup()
	if _fight_profile == _SoakPresets.PRESET_II4D_EXHAUSTION:
		_log_q3_ii4d_rollup()
	if _fight_profile == _SoakPresets.PRESET_II8_FORMATION:
		_log_q4_ii8_rollup()


static func _log_parry_rollup() -> void:
	var stats: Dictionary = _TrackSpecs.parry_outcome_stats(_fight_trace_lines)
	var summary: String = _TrackSpecs.parry_stats_summary_line(stats)
	for i in range(_fight_trace_lines.size() - 1, maxi(-1, _fight_trace_lines.size() - 32), -1):
		if str(_fight_trace_lines[i]).begins_with("parry_stats "):
			return
	_OperationalLog.play_combat(summary)


static func _log_hit_outcome_rollup() -> void:
	var summary: String = _TrackSpecs.hit_outcome_stats_summary_line(_session_counts)
	for i in range(_fight_trace_lines.size() - 1, maxi(-1, _fight_trace_lines.size() - 32), -1):
		if str(_fight_trace_lines[i]).begins_with("hit_outcome_stats "):
			return
	_OperationalLog.play_combat(summary)


static func _fight_trace_has_line_prefix(prefix: String) -> bool:
	for i in range(_fight_trace_lines.size() - 1, -1, -1):
		if str(_fight_trace_lines[i]).begins_with(prefix):
			return true
	return false


## Headless D-001 can log **`hit_resolve`** via trace ingest while **`_session_counts`** stayed 0 (quiet harness); sync before **`soak_fight_end`**.
static func _reconcile_session_hit_counts_from_fight_trace() -> void:
	var trace_hits: int = 0
	var outcome_counts: Dictionary = {}
	for line in _fight_trace_lines:
		var s: String = str(line)
		if not s.begins_with("hit_resolve "):
			continue
		trace_hits += 1
		var outcome: String = ""
		var oidx: int = s.find(" outcome=")
		if oidx >= 0:
			var tail: String = s.substr(oidx + 9)
			var sp: int = tail.find(" ")
			outcome = (tail.substr(0, sp) if sp >= 0 else tail).strip_edges()
		var bump_key: String = "hit_outcome_%s" % outcome
		if outcome.is_empty() or not _session_counts.has(bump_key):
			bump_key = "hit_outcome_other"
		outcome_counts[bump_key] = int(outcome_counts.get(bump_key, 0)) + 1
	var logged_hits: int = int(_session_counts.get("hit_resolve", 0))
	if trace_hits <= logged_hits:
		return
	_session_counts["hit_resolve"] = trace_hits
	if logged_hits == 0:
		for key in outcome_counts.keys():
			_session_counts[key] = outcome_counts[key]


static func _log_hit_coverage_hint() -> void:
	var hits: int = int(_session_counts.get("hit_resolve", 0))
	var avoided: int = int(_session_counts.get("strike_avoided", 0))
	var turns: int = int(_session_counts.get("turn_ready", 0))
	if hits > 0 or turns < 12:
		return
	if _fight_trace_has_line_prefix("hit_coverage_hint "):
		return
	var avoided_note: String = ""
	if avoided > 0:
		avoided_note = " strike_avoided=%d" % avoided
	_OperationalLog.play_combat(
		"hit_coverage_hint hit_resolve=0 turn_ready=%d%s — grep strike_avoided reason= parry_partial rem=; formation-only or all avoids/parries"
		% [turns, avoided_note]
	)


## F5: miss / dodge (grep **`strike_avoided`**).
static func note_strike_avoided(
	attacker_id: int,
	target_id: int,
	atk: Dictionary,
	tgt: Dictionary,
	outcome: String,
	part: String = ""
) -> void:
	if not _CombatConstants.combat_hit_summary_active():
		return
	if not _OperationalLog.is_play_session_active():
		return
	var oc: String = outcome.strip_edges().to_lower()
	if oc.is_empty():
		return
	var atk_n: String = _EntityAccess.get_display_name(atk, attacker_id)
	var tgt_n: String = _EntityAccess.get_display_name(tgt, target_id)
	var part_s: String = part if not part.is_empty() else "-"
	var avoid_reason: String = _LogFormatter.strike_avoided_reason(oc)
	var line: String = (
		"strike_avoided %s->%s %s outcome=%s reason=%s"
		% [atk_n, tgt_n, part_s, oc, avoid_reason]
	)
	if line == _last_strike_avoided_line:
		return
	_last_strike_avoided_line = line
	_bump("strike_avoided")
	var sub_key: String = "strike_avoided_%s" % oc
	if _session_counts.has(sub_key):
		_bump(sub_key)
	_OperationalLog.play_combat(line)


static func _log_q2_parry_rollup() -> void:
	for i in range(_fight_trace_lines.size() - 1, maxi(-1, _fight_trace_lines.size() - 16), -1):
		if str(_fight_trace_lines[i]).begins_with("q2_validate_hint "):
			return
	var stats: Dictionary = _TrackSpecs.parry_outcome_stats(_fight_trace_lines)
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
	if _fight_trace_has_line_prefix("q3_ii5_stats "):
		return
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
	if not _fight_trace_has_line_prefix("q3_validate_hint "):
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
	var ex_summary: String = _TrackSpecs.exhaustion_stats_summary_line(stats)
	if not _fight_trace_has_line_prefix("exhaustion_stats "):
		_OperationalLog.play_combat(ex_summary)
	if _fight_trace_has_line_prefix("q3_validate_hint "):
		return
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
	if _fight_trace_has_line_prefix("q4_ii8_stats "):
		return
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
	if not _fight_trace_has_line_prefix("q4_validate_hint "):
		if banner >= 1 and tooltip_ok >= 1:
			_OperationalLog.play_combat(
				"q4_validate_hint pass traces — F5 optional: widget layout / label centering glance"
			)
		else:
			_OperationalLog.play_combat(
				"q4_validate_hint warn need diagram_banner + tooltip_match=ok in formation fight"
			)


static func _merge_validator_profiles(base: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = base.duplicate()
	for p in _TrackSpecs.detect_profiles(_fight_trace_lines):
		if p not in out:
			out.append(p)
	return out


static func _log_soak_coverage() -> void:
	if _soak_coverage_logged:
		return
	_soak_coverage_logged = true
	var profiles: PackedStringArray = _merge_validator_profiles(_validator_profiles_for_fight())
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
		var track_result: Dictionary = tracks[track_id] as Dictionary
		if bool(track_result.get("pass", false)):
			continue
		var optional: bool = bool(track_result.get("optional", false))
		var tag: String = "warn" if optional else "fail"
		_OperationalLog.play_combat(
			"soak_coverage %s [%s] %s" % [tag, track_id, str(track_result.get("detail", ""))]
		)
	for f in result.get("failures", PackedStringArray()) as PackedStringArray:
		_OperationalLog.play_combat("soak_coverage fail %s" % f)
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
	if _camp_trace_pending_for_supplement():
		_log_soak_coverage_camp_supplement()


static func _camp_trace_pending_for_supplement() -> bool:
	if not _session_camp_trace_lines.is_empty():
		return true
	for line in _fight_trace_lines:
		if _TrackSpecs.is_camp_ea_world_trace_line(str(line)):
			return true
	return false


static func _archive_fight_camp_combat_lines() -> void:
	for line in _fight_trace_lines:
		var s: String = str(line)
		if not _TrackSpecs.is_camp_ea_combat_trace_line(s):
			continue
		if s in _session_camp_combat_trace_lines:
			continue
		_session_camp_combat_trace_lines.append(s)


static func _merged_camp_validation_lines() -> PackedStringArray:
	var out: PackedStringArray = _session_camp_combat_trace_lines.duplicate()
	for line in _session_camp_trace_lines:
		if line not in out:
			out.append(line)
	for line in _fight_trace_lines:
		if line not in out:
			out.append(line)
	return out


static func _should_refresh_camp_supplement(world_line: String) -> bool:
	var s: String = world_line.strip_edges()
	if s.is_empty():
		return false
	return (
		s.begins_with("settlement_continue")
		or s.begins_with("contract_victory pay=")
		or s.begins_with("company_day_advanced")
		or s.begins_with("field_care:")
		or s.begins_with("field_care bandage")
		or s.begins_with("field_care pressure")
		or s.begins_with("field_care stabilize")
		or s.begins_with("field_care pack")
		or s.begins_with("field_care tourniquet")
		or "field_care bandage failed" in s
		or "field_care pressure failed" in s
		or "field_care stabilize failed" in s
		or "field_care pack failed" in s
		or "field_care tourniquet failed" in s
		or s.begins_with("contract_victory triage")
		or s.begins_with("camp_heal ")
		or s.begins_with("company_run_end reason=")
		or s.begins_with("company_wages:")
		or s.begins_with("Wages short")
		or s.begins_with("desertion summary=")
		or s.begins_with("party_triage_open")
		or s.begins_with("campaign_medical_exit")
		or "campaign_medical_exit" in s
	)


static func _camp_supplement_dedupe_key(lines: PackedStringArray) -> String:
	var settle: int = 0
	var day: int = 0
	var bandage: int = 0
	var pressure: int = 0
	var loss: int = 0
	var medical_exit: int = 0
	for line in lines:
		var s: String = str(line)
		if "settlement_continue" in s or "contract_victory pay=" in s:
			settle += 1
		if "company_day_advanced" in s:
			day += 1
		if "field_care bandage" in s:
			bandage += 1
		if "field_care pressure part=" in s:
			pressure += 1
		if "company_run_end reason=" in s:
			loss += 1
		if "campaign_medical_exit" in s:
			medical_exit += 1
	return "%d:%d:%d:%d:%d:%d" % [settle, day, bandage, pressure, loss, medical_exit]


## After medical triage, **`settlement_continue`** / **`company_day_advanced`** arrive on **`FP_WORLD`**.
static func _log_soak_coverage_camp_supplement() -> void:
	if not _soak_coverage_logged:
		return
	var merged: PackedStringArray = _merged_camp_validation_lines()
	var dedupe_key: String = _camp_supplement_dedupe_key(merged)
	if dedupe_key == _last_camp_supplement_key:
		return
	_last_camp_supplement_key = dedupe_key
	var profiles: PackedStringArray = PackedStringArray([
		_TrackSpecs.PROFILE_ALWAYS,
		_TrackSpecs.PROFILE_CAMP_EA,
	])
	var result: Dictionary = _F5Validator.validate(merged, profiles)
	_OperationalLog.play_combat(
		(
			"soak_coverage camp ok=%s session_world=%d session_combat=%d fight_trace=%d"
			+ " — paste full Output for validate_f5_soak_log.ps1"
		)
		% [
			str(bool(result.get("ok", false))).to_lower(),
			_session_camp_trace_lines.size(),
			_session_camp_combat_trace_lines.size(),
			_fight_trace_lines.size(),
		]
	)
	var camp_stats: Dictionary = result.get("grep_stats", {}) as Dictionary
	if not camp_stats.is_empty():
		var camp_stat_parts: PackedStringArray = PackedStringArray()
		for stat_key in [
			"settlement_continue",
			"company_day_advanced",
			"field_care_bandage",
			"field_care_pressure",
			"company_wages_warn",
			"desertion_summary",
			"party_triage_open",
			"engagement_debug_mopup_strikes_listed",
		]:
			if camp_stats.has(stat_key):
				camp_stat_parts.append("%s=%d" % [stat_key, int(camp_stats[stat_key])])
		if not camp_stat_parts.is_empty():
			_OperationalLog.play_combat(
				"soak_coverage camp grep_stats %s" % " ".join(camp_stat_parts)
			)
	var tracks: Dictionary = result.get("tracks", {}) as Dictionary
	for track_id in tracks.keys():
		if not str(track_id).begins_with("camp_"):
			continue
		var track_result: Dictionary = tracks[track_id] as Dictionary
		if bool(track_result.get("pass", false)):
			_OperationalLog.play_combat(
				"soak_coverage camp pass [%s] %s" % [track_id, str(track_result.get("detail", ""))]
			)
			continue
		var optional: bool = bool(track_result.get("optional", false))
		var tag: String = "warn" if optional else "fail"
		_OperationalLog.play_combat(
			"soak_coverage camp %s [%s] %s" % [tag, track_id, str(track_result.get("detail", ""))]
		)
	var optional_missing: PackedStringArray = PackedStringArray()
	for track_id in tracks.keys():
		if not str(track_id).begins_with("camp_"):
			continue
		var track_result: Dictionary = tracks[track_id] as Dictionary
		if bool(track_result.get("pass", false)):
			continue
		if not bool(track_result.get("optional", false)):
			continue
		optional_missing.append(str(track_id))
	if not optional_missing.is_empty():
		_OperationalLog.play_combat(
			"soak_coverage camp hint optional still missing: %s — separate F5 runs or docs/f5_soak_log.camp_full.example.txt"
			% ", ".join(optional_missing)
		)
		for track_id in optional_missing:
			var hint: String = str(_CAMP_OPTIONAL_PLAY_HINTS.get(track_id, ""))
			if hint.is_empty():
				continue
			_OperationalLog.play_combat("soak_coverage camp next [%s] %s" % [track_id, hint])


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


## F5 / play session: one line per resolved strike (grep **`hit_resolve reason=`**). Default on when play-session diagnostic is on.
static func note_hit_resolve(
	attacker_id: int,
	target_id: int,
	atk: Dictionary,
	tgt: Dictionary,
	result_dict: Dictionary
) -> void:
	if not _CombatConstants.combat_hit_summary_active():
		return
	if not _OperationalLog.is_play_session_active():
		return
	var outcome: String = str(result_dict.get("outcome", "hit")).strip_edges()
	if outcome.is_empty():
		outcome = "hit"
	var atk_n: String = _EntityAccess.get_display_name(atk, attacker_id)
	var tgt_n: String = _EntityAccess.get_display_name(tgt, target_id)
	var part: String = str(result_dict.get("part", ""))
	var phys: float = float(result_dict.get("total_physical", -1.0))
	if phys < 0.0:
		phys = float(result_dict.get("dmg", 0))
	var dmg_int: int = int(result_dict.get("dmg", int(roundf(phys))))
	var reason: String = str(result_dict.get("damage_resolve_note", "")).strip_edges()
	if reason.is_empty():
		reason = _LogFormatter.damage_resolve_note(result_dict)
	if reason.is_empty():
		reason = "counted_damage"
	var line: String = (
		"hit_resolve %s->%s %s outcome=%s phys=%.3f dmg_int=%d reason=%s"
		% [atk_n, tgt_n, part if not part.is_empty() else "-", outcome, phys, dmg_int, reason]
	)
	if line == _last_hit_resolve_line:
		return
	_last_hit_resolve_line = line
	_bump("hit_resolve")
	var bump_key: String = "hit_outcome_%s" % outcome
	if _session_counts.has(bump_key):
		_bump(bump_key)
	else:
		_bump("hit_outcome_other")
	_OperationalLog.play_combat(line)


## F5 optional: per-hit damage outcome when **`COMBAT_DEV_VERBOSE`** (grep **`research_feel`**).
static func note_research_damage_outcome(part: String, result: Dictionary, extras: Dictionary) -> void:
	if not _CombatConstants.combat_event_debug_verbose_active():
		return
	if not _OperationalLog.is_play_session_active():
		return
	var sub: String = str(extras.get("hit_sub_region", ""))
	var pen: float = float(result.get("penetration_to_tissue_mm", extras.get("penetration_to_tissue_mm", -1.0)))
	var ke_frac: float = float(result.get("transmitted_ke_fraction", 1.0))
	var line: String = (
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
	if line == _last_research_feel_line:
		return
	_last_research_feel_line = line
	_bump("research_feel")
	_OperationalLog.play_combat(line)


static func note_engagement_transition(from_mode: String, to_mode: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = "engagement_transition %s -> %s" % [from_mode, to_mode]
	if line == _last_engagement_transition_line:
		return
	_last_engagement_transition_line = line
	_bump("engagement_transition")
	_OperationalLog.play_combat(line)


static func note_fall_back_pick(tag: String, who: String, target_id: int) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = "%s pick %s target_id=%d" % [tag.strip_edges(), who.strip_edges(), target_id]
	if line == _last_fall_back_pick_line:
		return
	_last_fall_back_pick_line = line
	_OperationalLog.play_combat(line)


static func note_cowering_fall_back_executed(who: String, file: int) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = "cowering_fall_back executed %s rank 0->1 file %d" % [who.strip_edges(), file]
	if line == _last_cowering_fall_back_executed_line:
		return
	_last_cowering_fall_back_executed_line = line
	_OperationalLog.play_combat(line)


## F5 soak (**II-6**): grep **`ambient_pain_shock`**.
static func note_death_tick(who: String, death_reason: String) -> void:
	if not _OperationalLog.play_session_is_editor_f5():
		return
	var line: String = "DEATH (tick) %s — %s" % [who.strip_edges(), death_reason.strip_edges()]
	if line == _last_death_tick_line:
		return
	_last_death_tick_line = line
	_OperationalLog.play_combat(line)


static func note_exhaustion_crossing(
	who: String, band_pct: int, index_pct: float, perf_pct: int
) -> void:
	if not _OperationalLog.play_session_is_editor_f5():
		return
	var line: String = (
		"exhaustion %s crossed %d%% (index %.0f%% perf %d%%)"
		% [who.strip_edges(), band_pct, index_pct, perf_pct]
	)
	if line == _last_exhaustion_crossing_line:
		return
	_last_exhaustion_crossing_line = line
	_OperationalLog.play_combat(line)


static func note_ambient_pain_shock(who: String, effective_pain: float, duration_s: float) -> void:
	if not _OperationalLog.play_session_is_editor_f5():
		return
	var line: String = (
		"ambient_pain_shock %s effective_pain=%.1f duration=%.1fs"
		% [who.strip_edges(), effective_pain, duration_s]
	)
	if line == _last_ambient_pain_shock_line:
		return
	_last_ambient_pain_shock_line = line
	_OperationalLog.play_combat(line)


static func note_fled(
	combatant_id: int,
	who: String,
	cohesion: float,
	casualties_pct: float,
	holding_field: bool
) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = (
		"fled id=%d %s cohesion=%.2f casualties=%.0f%% holding_field=%s"
		% [combatant_id, who.strip_edges(), cohesion, casualties_pct, str(holding_field).to_lower()]
	)
	if line == _last_fled_line:
		return
	_last_fled_line = line
	_OperationalLog.play_combat(line)


static func note_cowering_fall_back_listed(who: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = "cowering_fall_back listed for %s" % who.strip_edges()
	if line == _last_cowering_fall_back_listed_line:
		return
	_last_cowering_fall_back_listed_line = line
	_OperationalLog.play_combat(line)


static func note_controlling_close_listed(c: Dictionary, hint: String) -> void:
	if not _OperationalLog.is_play_session_active() or c.is_empty():
		return
	var text: String = hint.strip_edges()
	if text.is_empty():
		return
	_bump("controlling_close_hint")
	_OperationalLog.play_combat(
		"controlling_close_list id=%d %s hint=%s"
		% [_EntityAccess.id_int(c), _EntityAccess.get_display_name(c), text]
	)


static func _fight_finish_hold_line_hint_text(text: String) -> bool:
	return (
		text.contains("Mop-up")
		or text.contains("close in or strike")
		or text.contains("close or strike")
	)


static func note_mopup_hold_line_listed(c: Dictionary, hint: String) -> void:
	if not _OperationalLog.is_play_session_active() or c.is_empty():
		return
	var text: String = hint.strip_edges()
	if text.is_empty() or not _fight_finish_hold_line_hint_text(text):
		return
	_bump("mopup_gauge_hint")
	_OperationalLog.play_combat(
		"mopup_hold_line_list id=%d %s hint=%s"
		% [_EntityAccess.id_int(c), _EntityAccess.get_display_name(c), text]
	)


static func note_formation_move_pick(move_id: String, _initiator_id: int, partner_id: int) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = "%s@%d" % [move_id.strip_edges(), partner_id]
	if line == _last_formation_move_pick_line:
		return
	_last_formation_move_pick_line = line
	_OperationalLog.play_combat(line)


## IV-11: grep **`leader_order=`** on F5 paste when **`FEATURE_LEADER_FORMATION_COMMAND`** on.
static func note_leader_formation_command_pick(
	who: String, move_id: String, formation_id: String, side: String
) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	_OperationalLog.play_combat(
		"leader_order=%s side=%s formation=%s who=%s"
		% [move_id.strip_edges(), side.strip_edges(), formation_id.strip_edges(), who.strip_edges()]
	)


## Once per fight when player enters post-victory medical phase (grep **`medical_phase`**).
static func note_medical_phase_intro() -> void:
	if not _OperationalLog.is_play_session_active():
		return
	if _medical_phase_intro_logged:
		return
	_medical_phase_intro_logged = true
	# Grep **`medical_phase`** — not `medical_session` (would emit `medical medical_phase:`).
	_OperationalLog.play_combat(
		"medical_phase: full hemorrhage rates until TCCC control (pressure/TQ/pack/bandage); no passive blood recovery"
	)


static func note_medical_pack_listed(who: String, part: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var line: String = "medical_pack_wound listed for %s part=%s" % [who, part]
	if line == _last_medical_pack_listed_line:
		return
	_last_medical_pack_listed_line = line
	_bump("medical_pack_listed")
	_OperationalLog.play_combat(line)
	_maybe_flush_deferred_soak_coverage()


static func note_medical_action_pick(who: String, move_id: String, part: String, tgt_desc: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var pick_line: String = (
		"medical_action pick %s move=%s part=%s (%s)" % [who, move_id, part, tgt_desc]
	)
	if pick_line == _last_medical_action_pick_line:
		return
	_last_medical_action_pick_line = pick_line
	_bump("medical_action_pick")
	_OperationalLog.play_combat(pick_line)
	if move_id == CombatConstants.MOVE_ID_PACK_WOUND:
		_bump("medical_pack_pick")
		var pack_line: String = "medical_pack_wound pick %s part=%s (%s)" % [who, part, tgt_desc]
		_OperationalLog.play_combat(pack_line)
	_maybe_flush_deferred_soak_coverage()


## Call when post-victory medical phase ends (early exit or End battle) — not only on medical picks.
static func flush_deferred_soak_coverage() -> void:
	_maybe_flush_deferred_soak_coverage()


## Re-validate Camp §8 optional tracks when **`campaign_medical_exit`** lands after an earlier medical flush.
static func refresh_camp_supplement_after_medical_exit() -> void:
	if not _OperationalLog.is_play_session_active() or not _soak_coverage_logged:
		return
	_log_soak_coverage_camp_supplement()


static func _maybe_flush_deferred_soak_coverage() -> void:
	if not _defer_soak_coverage_for_medical:
		return
	_defer_soak_coverage_for_medical = false
	_log_soak_coverage()
	if not _soak_coverage_deferred_note_logged:
		_soak_coverage_deferred_note_logged = true
		_OperationalLog.play_combat(
			"soak_coverage note counts include post-victory medical triage (deferred from soak_fight_end)"
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
	var gauge_sig: String = "%d|%s|%s" % [cid, label, match_s]
	var skip_gauge_line: bool = gauge_sig == _last_turn_ready_gauge_sig
	_last_turn_ready_gauge_sig = gauge_sig
	if not skip_gauge_line:
		_OperationalLog.play_combat(
			"turn_ready_gauge id=%d %s label=%s tooltip_match=%s"
			% [cid, who, label, match_s]
		)
	if not formation_tip.is_empty() and formation_tip != fp_line:
		if formation_tip != _last_gauge_tooltip_formation_fp_line:
			_last_gauge_tooltip_formation_fp_line = formation_tip
			_OperationalLog.play_combat(
				"gauge_tooltip_formation id=%d %s line=%s" % [cid, who, formation_tip]
			)
	_emit_turn_ready_formation_fp(cid, who, fp_line)


## Auto / manual weapon form change (**WF-1c / WF-3** soak grep). Production path: **`CombatWeaponForm.assign_form`**.
static func log_form_switch(
	_manager: Node, c: Dictionary, old_form: String, new_form: String, reason: String
) -> void:
	if not _OperationalLog.is_play_session_active() or c.is_empty():
		return
	var cid: int = _EntityAccess.id_int(c)
	var who: String = _EntityAccess.get_display_name(c, cid)
	_OperationalLog.play_combat(
		"form_switch id=%d %s %s→%s reason=%s"
		% [cid, who, old_form.strip_edges(), new_form.strip_edges(), reason.strip_edges()]
	)


static func _emit_turn_ready_formation_fp(combatant_id: int, who: String, fp_line: String) -> void:
	var text: String = fp_line.strip_edges()
	if text.is_empty() or text == _last_turn_ready_formation_fp_line:
		return
	_last_turn_ready_formation_fp_line = text
	_OperationalLog.play_combat(
		"turn_ready_formation_line id=%d %s line=%s" % [combatant_id, who, text]
	)


## Party diagram header above player rows (**#8** — grep **`diagram_banner player:`**).
static func log_diagram_banner_player(line: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var text: String = line.strip_edges()
	if text.is_empty() or text == "—":
		return
	if text == _last_diagram_banner_line:
		return
	_last_diagram_banner_line = text
	_bump("diagram_banner")
	_OperationalLog.play_combat("diagram_banner player: %s" % text)


## Enemy-side diagram (**II-8** symmetry — grep **`diagram_banner enemy:`**).
static func log_diagram_banner_enemy(line: String) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var text: String = line.strip_edges()
	if text.is_empty() or text == "—":
		return
	if text == _last_diagram_banner_enemy_line:
		return
	# UI may refresh before doctrine suffix is known (e.g. Pinch Center) — skip duplicate row.
	if (
		not _last_diagram_banner_enemy_line.is_empty()
		and text.begins_with(_last_diagram_banner_enemy_line)
	):
		_last_diagram_banner_enemy_line = text
		return
	_last_diagram_banner_enemy_line = text
	_bump("diagram_banner_enemy")
	_OperationalLog.play_combat("diagram_banner enemy: %s" % text)


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
		and (
			_ListedActions.action_list_is_reserve_posture_only(actions)
			or _fight_finish_hold_line_hint_text(hold_line)
		)
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
