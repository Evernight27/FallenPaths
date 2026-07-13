class_name D001SanityProbeTests
extends RefCounted
## Headless **D-001** plausibility + validator cross-checks (grep needles vs log semantics).
## Called from **`CombatD001SoakRunner._evaluate`**, **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE=sanity` .
## `d001_presets`).

const BattleScene := preload("res://ui/BattleScene.gd")

const II6_PROBE_CUT: float = 22.0
const II6_PROBE_BLUNT: float = 22.0
const II6_PROBE_BV_PCT: float = 58.0

const RUNNER_NAME := "CombatD001SoakSanity"


static func _common_log_plausibility_failures(preset_id: String, lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var enter_at: int = -1
    var end_at: int = -1
    var soak_tag_seen: bool = false
    var wrong_soak_tag: bool = false
    var fight_end_winners: PackedStringArray = PackedStringArray()
    var fight_profiles: PackedStringArray = PackedStringArray()
    for i in lines.size():
        var line: String = D001SanityProbeTests._combat_line(lines[i])
        if D001SanityProbeTests._is_grep_hint_line(line):
            continue
        if "soak_fight_enter" in line or ("encounter_begin" in line and "soak=" in line):
            if enter_at < 0:
                enter_at = i
        if "soak=%s" % preset_id in line:
            soak_tag_seen = true
        elif line.contains("soak=") and not line.contains("soak=%s" % preset_id):
            if preset_id != "7v7" or (not line.contains("soak=7v7") and "tile=red" not in line):
                wrong_soak_tag = true
        if line.begins_with("soak_fight_end"):
            if end_at < 0:
                end_at = i
            var winner: String = D001SanityProbeTests._parse_kv_token(line, "winner=")
            if not winner.is_empty():
                fight_end_winners.append(winner)
            var profile: String = D001SanityProbeTests._parse_kv_token(line, "fight_profile=")
            if not profile.is_empty():
                fight_profiles.append(profile)
    if enter_at >= 0 and end_at >= 0 and enter_at > end_at:
        failures.append("common: soak_fight_enter/encounter_begin must precede soak_fight_end")
    if fight_end_winners.size() > 1:
        var first: String = fight_end_winners[0]
        for w in fight_end_winners:
            if w != first:
                failures.append("common: conflicting soak_fight_end winner=%s vs %s" % [first, w])
                break
    if soak_tag_seen and wrong_soak_tag:
        failures.append("common: log mixes soak= tag for another preset (expected %s)" % preset_id)
    for profile in fight_profiles:
        if profile != preset_id and not (preset_id == "7v7" and profile == "7v7"):
            failures.append("common: soak_fight_end fight_profile=%s expected %s" % [profile, preset_id])
    return failures


static func _ii5_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var pick_at: int = -1
    var listed_n: int = 0
    var executed_n: int = 0
    for i in lines.size():
        var line: String = D001SanityProbeTests._combat_line(lines[i])
        if D001SanityProbeTests._is_grep_hint_line(line):
            continue
        if "cowering_fall_back listed" in line:
            listed_n += 1
        if "cowering_fall_back executed" in line:
            executed_n += 1
        if "cowering_fall_back pick" in line:
            pick_at = i
    if listed_n < 1:
        failures.append("ii5: want cowering_fall_back listed (got %d)" % listed_n)
    if executed_n < 1:
        failures.append("ii5: want cowering_fall_back executed (got %d)" % executed_n)
    if pick_at >= 0:
        var pick_line: String = D001SanityProbeTests._combat_line(lines[pick_at])
        if "target_id=" not in pick_line:
            failures.append("ii5: cowering_fall_back pick missing target_id")
    if executed_n > 0:
        var exec_line: String = ""
        for raw in lines:
            var s: String = D001SanityProbeTests._combat_line(raw)
            if "cowering_fall_back executed" in s:
                exec_line = s
                break
        if not exec_line.contains("rank 0->") and not exec_line.contains("rank 0->"):
            failures.append("ii5: executed line should mention rear rank shift (rank 0->)")
    return failures


static func _ii6_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var setup_at: int = -1
    var ambient_at: int = -1
    var ambient_line: String = ""
    var companion_ambient_n: int = 0
    for i in lines.size():
        var line: String = D001SanityProbeTests._combat_line(lines[i])
        if D001SanityProbeTests._is_grep_hint_line(line):
            continue
        if line.contains("soak_setup ii6"):
            setup_at = i
        if not line.begins_with("ambient_pain_shock"):
            continue
        if "Companion" in line:
            companion_ambient_n += 1
        if ambient_at < 0:
            ambient_at = i
            ambient_line = line
    if setup_at < 0:
        failures.append("ii6: missing soak_setup ii6 line")
    if companion_ambient_n < 1:
        failures.append("ii6: want ambient_pain_shock Companion (got %d)" % companion_ambient_n)
    if ambient_line.is_empty():
        return failures
    if setup_at >= 0 and ambient_at >= 0 and setup_at > ambient_at:
        failures.append("ii6: soak_setup should precede first ambient_pain_shock")
    var pain_m: float = D001SanityProbeTests._parse_ambient_metric(ambient_line, "effective_pain=")
    var dur_m: float = D001SanityProbeTests._parse_ambient_metric(ambient_line, "duration=")
    if pain_m < 0.0 or dur_m < 0.0:
        failures.append("ii6: could not parse effective_pain/duration from '%s'" % ambient_line)
        return failures
    var thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    if pain_m <= thresh:
        failures.append("ii6: effective_pain %.1f should exceed shock threshold %.1f" % [pain_m, thresh])
    if dur_m <= 0.0:
        failures.append("ii6: duration %.1f should be positive" % dur_m)
    var expected: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain_m, 0.0)
    var expected_min: float = expected * 0.85
    var expected_max: float = expected * 2.5
    if dur_m < expected_min or dur_m > expected_max:
        failures.append(
            (
                "ii6: duration %.1fs outside plausible band [%.1f, %.1f] (formula base=%.1f)"
                % [dur_m, expected_min, expected_max, expected]
            )
        )
    if absf(dur_m - expected) > 0.15:
        failures.append(
            "ii6: logged duration %.1fs disagrees with formula %.2fs for pain %.1f" % [dur_m, expected, pain_m]
        )
    var bv_m: float = D001SanityProbeTests._parse_ambient_metric(
        D001SanityProbeTests._find_line(lines, "soak_setup ii6"), "bv="
    )
    if bv_m >= 0.0 and (bv_m < 10.0 or bv_m > 95.0):
        failures.append("ii6: soak_setup bv=%.0f outside wounded preset %% band [10,95]" % bv_m)
    return failures


static func _ii3_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var arc_at: int = -1
    var parry_at: int = -1
    for i in lines.size():
        var line: String = D001SanityProbeTests._combat_line(lines[i])
        if D001SanityProbeTests._is_grep_hint_line(line):
            continue
        if "ui_hint Arc overlap" in line:
            if arc_at < 0:
                arc_at = i
        if CombatD001TrackSpecs.NEEDLE_PARRY_TRACE in line:
            if parry_at < 0:
                parry_at = i
    if arc_at < 0:
        failures.append("ii3: want ui_hint Arc overlap before surround parry work")
    if parry_at >= 0 and arc_at >= 0 and arc_at > parry_at:
        failures.append("ii3: Arc overlap hint should precede first parry trace")
    return failures


static func _ii8_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var formation_n: int = 0
    var gauge_ok_n: int = 0
    var gauge_n: int = 0
    for raw in lines:
        var line: String = D001SanityProbeTests._combat_line(raw)
        if D001SanityProbeTests._is_grep_hint_line(line):
            continue
        if CombatD001TrackSpecs.NEEDLE_ENGAGEMENT_FORMATION in line:
            formation_n += 1
        if CombatD001TrackSpecs.NEEDLE_TURN_READY_GAUGE in line:
            gauge_n += 1
            if CombatD001TrackSpecs.NEEDLE_TOOLTIP_OK in line:
                gauge_ok_n += 1
    if formation_n < 1:
        failures.append("ii8: want engagement mode=Formation line")
    if gauge_n < 1:
        failures.append("ii8: want turn_ready_gauge line")
    elif gauge_ok_n < 1:
        failures.append("ii8: want turn_ready_gauge with tooltip_match=ok (got %d/%d)" % [gauge_ok_n, gauge_n])
    return failures


static func _ii4d_log_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    ## Band ordering only  -  full **ii4d** sign-off (gauge **Exh**) stays in
    ## **`CombatD001SoakRunner._run_ii4d_exhaustion`**.
    var failures: PackedStringArray = PackedStringArray()
    var stats: Dictionary = CombatD001TrackSpecs.exhaustion_band_stats(lines)
    var c25: int = int(stats.get("crossed_25", 0))
    var c50: int = int(stats.get("crossed_50", 0))
    var c75: int = int(stats.get("crossed_75", 0))
    if c50 > 0 and c25 < 1:
        failures.append("ii4d: crossed 50 logged without crossed 25")
    if c75 > 0 and c50 < 1:
        failures.append("ii4d: crossed 75 logged without crossed 50")
    return failures


static func _seven_v7_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var party_n: int = 0
    var red_enter: int = 0
    for raw in lines:
        var line: String = D001SanityProbeTests._combat_line(raw)
        if "party_entering_combat count=7" in line:
            party_n += 1
        if "soak_fight_enter tile=red" in line or "soak_fight_enter tile=red 7v7" in line:
            red_enter += 1
    if party_n < 1:
        failures.append("7v7: want party_entering_combat count=7")
    if red_enter < 1:
        failures.append("7v7: want soak_fight_enter tile=red")
    return failures


# --- helpers ---

## Headless soaks may retry in one capture without a second **soak_fight_enter**; use lines after the prior
## **soak_fight_end**.


## Headless soaks may retry in one capture without a second **soak_fight_enter**; use lines after the prior
## **soak_fight_end**.
static func _lines_for_last_fight(lines: PackedStringArray) -> PackedStringArray:
    var last_end: int = -1
    for i in range(lines.size() - 1, -1, -1):
        var line: String = D001SanityProbeTests._combat_line(lines[i])
        if line.begins_with("soak_fight_end"):
            last_end = i
            break
    if last_end < 0:
        return lines
    var start: int = 0
    for i in range(last_end - 1, -1, -1):
        var line: String = D001SanityProbeTests._combat_line(lines[i])
        if "soak_fight_enter" in line or ("encounter_begin" in line and "encounter[soak=" in line):
            start = i
            break
        if line.begins_with("soak_fight_end"):
            start = i + 1
            break
    var out: PackedStringArray = PackedStringArray()
    for j in range(start, lines.size()):
        out.append(lines[j])
    return out


static func _normalize_fixture_lines(lines: PackedStringArray) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    for raw in lines:
        out.append(D001SanityProbeTests._combat_line(raw))
    return out


static func _find_line(lines: PackedStringArray, needle: String) -> String:
    for raw in lines:
        var line: String = D001SanityProbeTests._combat_line(raw)
        if needle in line:
            return line
    return ""


static func _parse_kv_token(line: String, key: String) -> String:
    var idx: int = line.find(key)
    if idx < 0:
        return ""
    var tail: String = line.substr(idx + key.length())
    var space: int = tail.find(" ")
    if space < 0:
        return tail.strip_edges()
    return tail.substr(0, space).strip_edges()


static func _parse_ambient_metric(line: String, key: String) -> float:
    if line.is_empty():
        return -1.0
    var idx: int = line.find(key)
    if idx < 0:
        return -1.0
    var tail: String = line.substr(idx + key.length()).strip_edges()
    var end: int = 0
    while end < tail.length():
        var c: String = tail[end]
        if c.is_valid_float() or c == "." or c == "-":
            end += 1
        else:
            break
    if end <= 0:
        return -1.0
    return float(tail.substr(0, end))


static func _blob_has(lines: PackedStringArray, needle: String) -> bool:
    for raw in lines:
        if needle in D001SanityProbeTests._combat_line(raw):
            return true
    return false


static func _combat_line(raw: String) -> String:
    var s: String = str(raw).strip_edges()
    if s.begins_with(OperationalLog.TAG_COMBAT + ":"):
        return s.substr(OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
    return s


static func _is_grep_hint_line(line: String) -> bool:
    var s: String = line.strip_edges()
    if s.begins_with("soak_guide ") or s.begins_with("soak_session_plan "):
        return true
    if s.begins_with("soak_validate_hint ") or s.begins_with("soak_coverage "):
        return true
    if "grep SCRIPT" in s or "grep FP_ERROR" in s:
        return true
    if s.begins_with("FP_SESSION_BEGIN:") or s.begins_with("FP_SESSION_END:"):
        return true
    return false
