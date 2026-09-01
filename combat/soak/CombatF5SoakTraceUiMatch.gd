class_name CombatF5SoakTraceUiMatch
extends CombatF5SoakTraceRollups

## Editor F5 **D-001** traces  -  mirror on-screen battle UI in **`FP_COMBAT`** Output (grep, no human glance).
## **`turn_ready_gauge`**: full label via **`BattleUIUpdater`**  -  suffix order **Step -> Grd/Atk -> Form** when
## present; content asserts **open**  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`** .
## **`#wf-footing-doc-map`**.
## Call sites: **`TurnReadyHandler`**, **`BattleScene`**, **`CombatResolveAction`**.
## **`ingest_trace_line`** (via **`OperationalLog.play_combat`**) feeds **`soak_coverage`** at fight end.
## **`ingest_world_trace_line`** (via **`OperationalLog.play_world`**) appends Camp S8 markers for post-medical
## supplement.

static var _defer_soak_coverage_for_medical: bool = false
static var _soak_coverage_deferred_note_logged: bool = false
static var _last_camp_supplement_key: String = ""
static var _fight_profile: String = ""
static var _last_turn_ready_formation_fp_line: String = ""


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


## After medical triage, **`settlement_continue`** / **`company_day_advanced`** arrive on **`FP_WORLD`**.
static func _log_soak_coverage_camp_supplement() -> void:
    if not _soak_coverage_logged:
        return
    var merged: PackedStringArray = CombatF5SoakTraceUiMatch._merged_camp_validation_lines()
    var dedupe_key: String = CombatF5SoakTraceUiMatch._camp_supplement_dedupe_key(merged)
    if dedupe_key == _last_camp_supplement_key:
        return
    _last_camp_supplement_key = dedupe_key
    var profiles: PackedStringArray = PackedStringArray(
        [
            CombatD001TrackSpecs.PROFILE_ALWAYS,
            CombatD001TrackSpecs.PROFILE_CAMP_EA,
        ]
    )
    var result: Dictionary = CombatF5SoakLogValidator.validate(merged, profiles)
    (
        OperationalLog
        . play_combat(
            (
                (
                    "soak_coverage camp ok=%s session_world=%d session_combat=%d fight_trace=%d"
                    + "  -  paste full Output for validate_f5_soak_log.ps1"
                )
                % [
                    str(bool(result.get("ok", false))).to_lower(),
                    _session_camp_trace_lines.size(),
                    _session_camp_combat_trace_lines.size(),
                    _fight_trace_lines.size(),
                ]
            )
        )
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
            OperationalLog.play_combat("soak_coverage camp grep_stats %s" % " ".join(camp_stat_parts))
    var tracks: Dictionary = result.get("tracks", {}) as Dictionary
    for track_id in tracks.keys():
        if not str(track_id).begins_with("camp_"):
            continue
        var track_result: Dictionary = tracks[track_id] as Dictionary
        if bool(track_result.get(DataKeys.SOAK_TRACE_PASS, false)):
            OperationalLog.play_combat(
                "soak_coverage camp pass [%s] %s" % [track_id, str(track_result.get("detail", ""))]
            )
            continue
        var optional: bool = bool(track_result.get("optional", false))
        var tag: String = "warn" if optional else "fail"
        OperationalLog.play_combat(
            "soak_coverage camp %s [%s] %s" % [tag, track_id, str(track_result.get("detail", ""))]
        )
    var optional_missing: PackedStringArray = PackedStringArray()
    for track_id in tracks.keys():
        if not str(track_id).begins_with("camp_"):
            continue
        var track_result: Dictionary = tracks[track_id] as Dictionary
        if bool(track_result.get(DataKeys.SOAK_TRACE_PASS, false)):
            continue
        if not bool(track_result.get("optional", false)):
            continue
        optional_missing.append(str(track_id))
    if not optional_missing.is_empty():
        var missing_str := ", ".join(optional_missing)
        OperationalLog.play_combat(
            "soak_coverage camp hint optional still missing: %s  -  separate F5 runs or docs/f5_soak_log.camp_full.example.txt" % [missing_str]
        )
        for track_id in optional_missing:
            var hint: String = str(_CAMP_OPTIONAL_PLAY_HINTS.get(track_id, ""))
            if hint.is_empty():
                continue
            OperationalLog.play_combat("soak_coverage camp next [%s] %s" % [track_id, hint])


static func _validator_profiles_for_fight() -> PackedStringArray:
    var profiles: PackedStringArray = PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    match _fight_profile:
        SoakEncounterPresets.PRESET_II2B_SWORD_DUEL, "ii2b":
            profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II2B)
        SoakEncounterPresets.PRESET_II3_SURROUND, "ii3":
            profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II3)
        SoakEncounterPresets.PRESET_II5_COWERING, "ii5":
            profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II5)
        SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK, "ii6":
            profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II6)
        SoakEncounterPresets.PRESET_II8_FORMATION, "ii8":
            profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II8)
        SoakEncounterPresets.PRESET_II4D_EXHAUSTION, "ii4d":
            profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II4D)
        "7v7":
            profiles.append(CombatD001TrackSpecs.PROFILE_7V7)
    return profiles


## F5 / play session: one line per resolved strike (grep **`hit_resolve reason=`**). Default on when play-session
## diagnostic is on.


static func _fight_finish_hold_line_hint_text(text: String) -> bool:
    return text.contains("Mop-up") or text.contains("close in or strike") or text.contains("close or strike")


static func _maybe_flush_deferred_soak_coverage() -> void:
    if not _defer_soak_coverage_for_medical:
        return
    _defer_soak_coverage_for_medical = false
    CombatF5SoakTraceRollups._log_soak_coverage()
    if not _soak_coverage_deferred_note_logged:
        _soak_coverage_deferred_note_logged = true
        OperationalLog.play_combat(
            "soak_coverage note counts include post-victory medical triage (deferred from soak_fight_end)"
        )


## Player **`turn_ready`**: row gauge label + formation tooltip vs turn-ready formation line (**II-5a / II-5c**).


static func _emit_turn_ready_formation_fp(combatant_id: int, who: String, fp_line: String) -> void:
    var text: String = fp_line.strip_edges()
    if text.is_empty() or text == _last_turn_ready_formation_fp_line:
        return
    _last_turn_ready_formation_fp_line = text
    OperationalLog.play_combat("turn_ready_formation_line id=%d %s line=%s" % [combatant_id, who, text])


## Party diagram header above player rows (**#8**  -  grep **`diagram_banner player:`**).


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
    return str(c.get(_get_combat_constants().COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()


static func _formation_line_from_tooltip(c: Dictionary, manager: Node) -> String:
    var stamp: String = CombatF5SoakTraceUiMatch._formation_stamp_on_combatant(c)
    if not stamp.is_empty():
        return stamp
    var tips: PackedStringArray = CombatUiHints.gauge_tooltip_lines(c, manager)
    for tip in tips:
        var t: String = str(tip).strip_edges()
        if (
            CombatF5SoakTraceUiMatch._looks_like_formation_turn_hint(t)
            and not CombatF5SoakTraceUiMatch._is_formation_duration_preview_only(t)
        ):
            return t
    return ""


## Generic duration preview (`Formation move: ~1.4s, under pressure`)  -  not the stamped turn line.


## Generic duration preview (`Formation move: ~1.4s, under pressure`)  -  not the stamped turn line.
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


## Non-formation row labels  -  grep **`tooltip_match=counter`** / **`medical`** / **`melee_only`** (not II-5a
## failures).


## Non-formation row labels  -  grep **`tooltip_match=counter`** / **`medical`** / **`melee_only`** (not II-5a
## failures).
static func _turn_ui_match_context(
    manager: Node, c: Dictionary, actions: Array, label: String, fp_line: String, hold_line: String
) -> String:
    var state: String = CombatantEntityAccess.state_str(c)
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
        var tempo_key: String = CombatUiHints.counter_tempo_hint_key(c, manager)
        if not CombatUiHints.counter_tempo_gauge_label(tempo_key).is_empty():
            if label.begins_with("Counter") or label.begins_with("Seize tempo"):
                return "counter"
    if (
        state == CombatConstants.STATE_WAITING
        and fp_line.is_empty()
        and not hold_line.is_empty()
        and (
            CombatListedActions.action_list_is_reserve_posture_only(actions)
            or CombatF5SoakTraceUiMatch._fight_finish_hold_line_hint_text(hold_line)
        )
    ):
        return "hold_line"
    if state == CombatConstants.STATE_WAITING and fp_line.is_empty() and hold_line.is_empty():
        if not CombatF5SoakTraceUiMatch._actions_include_formation_menu(actions):
            return "melee_only"
    return ""


static func _actions_include_formation_menu(actions: Array) -> bool:
    for entry in actions:
        if not (entry is Dictionary):
            continue
        var mid: String = str(entry.get(DataKeys.ACTION_MOVE_ID, entry.get("id", ""))).strip_edges()
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
    return false


static func _tooltip_formation_match_label(tooltip_line: String, fp_line: String, hold_line: String = "") -> String:
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
