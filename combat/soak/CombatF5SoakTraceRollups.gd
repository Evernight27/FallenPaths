class_name CombatF5SoakTraceRollups
extends RefCounted
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

## Editor F5 **D-001** traces  -  mirror on-screen battle UI in **`FP_COMBAT`** Output (grep, no human glance).
## **`turn_ready_gauge`**: full label via **`BattleUIUpdater`**  -  suffix order **Step -> Grd/Atk -> Form** when
## present; content asserts **open**  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`** .
## **`#wf-footing-doc-map`**.
## Call sites: **`TurnReadyHandler`**, **`BattleScene`**, **`CombatResolveAction`**.
## **`ingest_trace_line`** (via **`OperationalLog.play_combat`**) feeds **`soak_coverage`** at fight end.
## **`ingest_world_trace_line`** (via **`OperationalLog.play_world`**) appends Camp S8 markers for post-medical
## supplement.

static var _player_turn_hints_cache: Variant = null

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


static func _get_player_turn_hints() -> Variant:
    if _player_turn_hints_cache == null:
        _player_turn_hints_cache = load("res://combat/CombatPlayerTurnHints.gd")
    return _player_turn_hints_cache


## Inspector snapshot at F5 start (grep **`soak_session_plan`**).


## Rollup lines are emitted via **`play_combat`** but excluded from **`ingest_trace_line`**  -  append directly.
static func _append_fight_trace_line_direct(s: String) -> void:
    var line: String = s.strip_edges()
    if line.is_empty():
        return
    if _fight_trace_lines.size() > 0 and _fight_trace_lines[_fight_trace_lines.size() - 1] == line:
        return
    _fight_trace_lines.append(line)
    if _fight_trace_lines.size() > MAX_FIGHT_TRACE_LINES:
        _fight_trace_lines.remove_at(0)


## Camp S8 markers (**`FP_WORLD`**) land after medical  -  extend trace for in-editor camp supplement.


static func _log_parry_rollup() -> void:
    var stats: Dictionary = CombatD001TrackSpecs.parry_outcome_stats(_fight_trace_lines)
    var summary: String = CombatD001TrackSpecs.parry_stats_summary_line(stats)
    for i in range(_fight_trace_lines.size() - 1, maxi(-1, _fight_trace_lines.size() - 32), -1):
        if str(_fight_trace_lines[i]).begins_with("parry_stats "):
            return
    OperationalLog.play_combat(summary)


static func _log_hit_outcome_rollup() -> void:
    var summary: String = CombatD001TrackSpecs.hit_outcome_stats_summary_line(_session_counts)
    for i in range(_fight_trace_lines.size() - 1, maxi(-1, _fight_trace_lines.size() - 32), -1):
        if str(_fight_trace_lines[i]).begins_with("hit_outcome_stats "):
            return
    OperationalLog.play_combat(summary)


static func _fight_trace_has_line_prefix(prefix: String) -> bool:
    for i in range(_fight_trace_lines.size() - 1, -1, -1):
        if str(_fight_trace_lines[i]).begins_with(prefix):
            return true
    return false


## Headless D-001 can log **`hit_resolve`** via trace ingest while **`_session_counts`** stayed 0 (quiet harness); sync
## before **`soak_fight_end`**.


## Headless D-001 can log **`hit_resolve`** via trace ingest while **`_session_counts`** stayed 0 (quiet harness); sync
## before **`soak_fight_end`**.
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
    if CombatF5SoakTraceRollups._fight_trace_has_line_prefix("hit_coverage_hint "):
        return
    var avoided_note: String = ""
    if avoided > 0:
        avoided_note = " strike_avoided=%d" % avoided
    OperationalLog.play_combat(
        (
            "hit_coverage_hint hit_resolve=0 turn_ready=%d%s  -  grep strike_avoided reason= parry_partial rem=; fo"
            + "rmation-only or all avoids/parries" % [turns, avoided_note]
        )
    )


## F5: miss / dodge (grep **`strike_avoided`**).


static func _log_q2_parry_rollup() -> void:
    for i in range(_fight_trace_lines.size() - 1, maxi(-1, _fight_trace_lines.size() - 16), -1):
        if str(_fight_trace_lines[i]).begins_with("q2_validate_hint "):
            return
    var stats: Dictionary = CombatD001TrackSpecs.parry_outcome_stats(_fight_trace_lines)
    var plaus: PackedStringArray = CombatD001TrackSpecs.ii2b_plausibility_failures(stats)
    if plaus.is_empty():
        OperationalLog.play_combat(
            (
                "q2_validate_hint pass  -  F5 feel OK if bind/deflect/riposte timing read well; compare .ii2b_worksheet"
                + "_prefill.txt"
            )
        )
    else:
        OperationalLog.play_combat(
            "q2_validate_hint warn %s  -  headless would fail; tune only if design changes (III-3)" % ", ".join(plaus)
        )


static func _log_q3_ii5_rollup() -> void:
    if CombatF5SoakTraceRollups._fight_trace_has_line_prefix("q3_ii5_stats "):
        return
    var listed: int = 0
    var executed: int = 0
    for line in _fight_trace_lines:
        if "cowering_fall_back listed" in line:
            listed += 1
        if "cowering_fall_back executed" in line:
            executed += 1
    OperationalLog.play_combat("q3_ii5_stats listed=%d executed=%d (headless needs both>=1)" % [listed, executed])
    if not CombatF5SoakTraceRollups._fight_trace_has_line_prefix("q3_validate_hint "):
        if listed >= 1 and executed >= 1:
            OperationalLog.play_combat("q3_validate_hint pass  -  F5 only: confirm fall_back pick UX on 2x3 world grid")
        else:
            OperationalLog.play_combat(
                "q3_validate_hint warn missing cowering_fall_back listed|executed  -  pick fall_back when listed"
            )


static func _log_q3_ii4d_rollup() -> void:
    var stats: Dictionary = CombatD001TrackSpecs.exhaustion_band_stats(_fight_trace_lines)
    var ex_summary: String = CombatD001TrackSpecs.exhaustion_stats_summary_line(stats)
    if not CombatF5SoakTraceRollups._fight_trace_has_line_prefix("exhaustion_stats "):
        OperationalLog.play_combat(ex_summary)
    if CombatF5SoakTraceRollups._fight_trace_has_line_prefix("q3_validate_hint "):
        return
    var plaus: PackedStringArray = CombatD001TrackSpecs.ii4d_plausibility_failures(
        stats, CombatF5SoakTraceRollups._gauge_has_exh_suffix()
    )
    if plaus.is_empty():
        OperationalLog.play_combat("q3_validate_hint pass bands  -  F5 optional: 3 - 5 min duel pacing feel")
    else:
        OperationalLog.play_combat("q3_validate_hint warn %s  -  headless ii4d would fail" % ", ".join(plaus))


static func _gauge_has_exh_suffix() -> bool:
    for line in _fight_trace_lines:
        if "turn_ready_gauge" in line and "Exh" in line:
            return true
    return false


static func _log_q4_ii8_rollup() -> void:
    if CombatF5SoakTraceRollups._fight_trace_has_line_prefix("q4_ii8_stats "):
        return
    var banner: int = 0
    var tooltip_ok: int = 0
    for line in _fight_trace_lines:
        if "diagram_banner" in line:
            banner += 1
        if "tooltip_match=ok" in line:
            tooltip_ok += 1
    OperationalLog.play_combat("q4_ii8_stats diagram_banner=%d tooltip_match_ok=%d" % [banner, tooltip_ok])
    if not CombatF5SoakTraceRollups._fight_trace_has_line_prefix("q4_validate_hint "):
        if banner >= 1 and tooltip_ok >= 1:
            OperationalLog.play_combat(
                "q4_validate_hint pass traces  -  F5 optional: widget layout / label centering glance"
            )
        else:
            OperationalLog.play_combat(
                "q4_validate_hint warn need diagram_banner + tooltip_match=ok in formation fight"
            )


static func _merge_validator_profiles(base: PackedStringArray) -> PackedStringArray:
    var out: PackedStringArray = base.duplicate()
    for p in CombatD001TrackSpecs.detect_profiles(_fight_trace_lines):
        if p not in out:
            out.append(p)
    return out


static func _log_soak_coverage() -> void:
    if _soak_coverage_logged:
        return
    _soak_coverage_logged = true
    var profiles: PackedStringArray = CombatF5SoakTraceRollups._merge_validator_profiles(
        CombatF5SoakTraceUiMatch._validator_profiles_for_fight()
    )
    var result: Dictionary = CombatF5SoakLogValidator.validate(_fight_trace_lines, profiles)
    var ok: bool = bool(result.get("ok", false))
    OperationalLog.play_combat(
        (
            "soak_coverage ok=%s profiles=%s trace_lines=%d"
            % [str(ok).to_lower(), ", ".join(profiles), _fight_trace_lines.size()]
        )
    )
    var stats: Dictionary = result.get("grep_stats", {}) as Dictionary
    if not stats.is_empty():
        var stat_parts: PackedStringArray = PackedStringArray()
        for stat_key in stats.keys():
            stat_parts.append("%s=%d" % [str(stat_key), int(stats[stat_key])])
        OperationalLog.play_combat("soak_coverage grep_stats %s" % " ".join(stat_parts))
    var tracks: Dictionary = result.get("tracks", {}) as Dictionary
    for track_id in tracks.keys():
        var track_result: Dictionary = tracks[track_id] as Dictionary
        if bool(track_result.get("pass", false)):
            continue
        var optional: bool = bool(track_result.get("optional", false))
        var tag: String = "warn" if optional else "fail"
        OperationalLog.play_combat("soak_coverage %s [%s] %s" % [tag, track_id, str(track_result.get("detail", ""))])
    for f in result.get("failures", PackedStringArray()) as PackedStringArray:
        OperationalLog.play_combat("soak_coverage fail %s" % f)
    var missing: PackedStringArray = result.get("missing_cyan_presets", PackedStringArray()) as PackedStringArray
    if not missing.is_empty():
        OperationalLog.play_combat(
            "soak_coverage note full II-0 needs cyan presets in other F5 runs: %s" % ", ".join(missing)
        )
    if ok:
        OperationalLog.play_combat(
            (
                "soak_coverage pass this fight matches D-001 validator for %s  -  still grep FP_ERROR SCRIPT_ERROR "
                + "in Output" % ", ".join(profiles)
            )
        )
    if CombatF5SoakTraceRollups._camp_trace_pending_for_supplement():
        CombatF5SoakTraceUiMatch._log_soak_coverage_camp_supplement()


static func _camp_trace_pending_for_supplement() -> bool:
    if not _session_camp_trace_lines.is_empty():
        return true
    for line in _fight_trace_lines:
        if CombatD001TrackSpecs.is_camp_ea_world_trace_line(str(line)):
            return true
    return false


static func _archive_fight_camp_combat_lines() -> void:
    for line in _fight_trace_lines:
        var s: String = str(line)
        if not CombatD001TrackSpecs.is_camp_ea_combat_trace_line(s):
            continue
        if s in _session_camp_combat_trace_lines:
            continue
        _session_camp_combat_trace_lines.append(s)
