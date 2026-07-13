class_name CombatQTrackAudits
extends RefCounted

## Headless Track **Q** proxies (Q1 - Q4) vs **`.d001_soak_out.txt`**  -  writes **`.q_track_audits.txt`**.
## Q4 **ii8** (`II8_CHECKS`): formation trace gates + WF **` . Form`** / **`[Ox]`** / suffix-order content from D-001 report  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`**.
## Entry: **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE=q_track`) . **`run_q_feel.ps1 -Headless`**.

const _TrackSpecs := preload("res://harness/CombatD001TrackSpecs.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _Audit := preload("res://harness/CombatCalibrationAudit.gd")
const _Research := preload("res://core/CombatResearchAnchors.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const RUNNER_NAME := "QTrackAudits"
const OUT_PATH := "res://.q_track_audits.txt"
const D001_PATH := "res://.d001_soak_out.txt"
const WORKSHEET_PATH := "res://.ii2b_worksheet_prefill.txt"

const II5_CHECKS: Array = ["soak_setup", "cowering_listed", "cowering_executed"]
const II4D_CHECKS: Array = ["exhaustion_25", "exhaustion_band", "ii4d_plausibility"]
const II8_CHECKS: Array = [
    "formation_mode",
    "turn_ready_gauge",
    "tooltip_match_ok",
    "diagram_banner",
    "form_gauge_suffix",
    "form_diagram_suffix",
    "gauge_suffix_order",
    "turn_ready_form_suffix",
]


static func run_headless() -> int:
    CombatConstants.set_headless_harness_quiet(true)
    _OperationalLog.harness_begin(RUNNER_NAME)
    var lines: PackedStringArray = PackedStringArray()
    lines.append("=== Q track audits (headless proxies, no F5 sign-off) ===")
    lines.append("")

    var boundary_fail: bool = false
    boundary_fail = _append_q2(lines) or boundary_fail
    boundary_fail = _append_q3_ii5(lines) or boundary_fail
    boundary_fail = _append_q3_ii4d(lines) or boundary_fail
    boundary_fail = _append_q4_ii8(lines) or boundary_fail
    boundary_fail = _append_q1_research_feel(lines) or boundary_fail

    var text: String = "\n".join(lines) + "\n"
    print(text)
    var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
    if f == null:
        _OperationalLog.harness_fail(RUNNER_NAME, PackedStringArray(["could not write %s" % OUT_PATH]))
        return 1
    f.store_string(text)
    if boundary_fail:
        _OperationalLog.harness_fail(RUNNER_NAME, PackedStringArray(["BOUNDARY_FAIL"]))
        return 1
    _OperationalLog.harness_ok(RUNNER_NAME)
    return 0


static func _read_d001_lines() -> PackedStringArray:
    if not FileAccess.file_exists(D001_PATH):
        return PackedStringArray()
    var raw: String = FileAccess.get_file_as_string(D001_PATH)
    var out: PackedStringArray = PackedStringArray()
    for part in raw.split("\n", false):
        out.append(part)
    return out


static func _append_q2(lines: PackedStringArray) -> bool:
    lines.append("[Q2 ii2b]")
    var fail: bool = _append_q2_fixture_checks(lines)
    var d001: PackedStringArray = _read_d001_lines()
    if d001.is_empty():
        lines.append("  BOUNDARY_FAIL missing .d001_soak_out.txt")
        lines.append("")
        _append_q2_worksheet_snapshot(lines)
        _append_q2_f5_subjective_checklist(lines)
        return true
    var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(d001, _SoakPresets.PRESET_II2B_SWORD_DUEL)
    if not _TrackSpecs.d001_report_pass(d001, _SoakPresets.PRESET_II2B_SWORD_DUEL):
        lines.append("  BOUNDARY_FAIL [ii2b] pass=false in d001 report")
        lines.append("")
        _append_q2_worksheet_snapshot(lines)
        _append_q2_f5_subjective_checklist(lines)
        return true
    var field: String = _TrackSpecs.d001_report_field_line(section, "parry_stats deflect=")
    var stats: Dictionary = _TrackSpecs.parry_stats_from_summary_line(field) if not field.is_empty() else {}
    if stats.is_empty():
        lines.append("  BOUNDARY_FAIL no parry_stats line in [ii2b] section")
        lines.append("")
        _append_q2_worksheet_snapshot(lines)
        _append_q2_f5_subjective_checklist(lines)
        return true
    lines.append("  %s" % _TrackSpecs.parry_stats_summary_line(stats))
    var plaus: PackedStringArray = _TrackSpecs.ii2b_plausibility_failures(stats)
    if plaus.is_empty():
        lines.append("  ii2b_plausibility=pass (F5 timing feel still optional)")
    else:
        for msg in plaus:
            lines.append("  BOUNDARY_FAIL %s" % msg)
    lines.append("")
    _append_q2_worksheet_snapshot(lines)
    _append_q2_f5_subjective_checklist(lines)
    return fail or not plaus.is_empty()


static func _append_q2_fixture_checks(lines: PackedStringArray) -> bool:
    lines.append("  [fixtures]")
    var failures: PackedStringArray = PackedStringArray()
    var good: Dictionary = _TrackSpecs.parry_stats_from_summary_line(
        "parry_stats deflect=4 bind=1 partial=7 riposte=5 counter_tempo=0 flurry_opened=1 flurry=1"
    )
    if not _TrackSpecs.ii2b_plausibility_failures(good).is_empty():
        failures.append("balanced d001 sample should pass")
    var bind_heavy: Dictionary = {
        "parry_deflect": 1,
        "parry_bind": 9,
        "parry_partial": 0,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if _TrackSpecs.ii2b_plausibility_failures(bind_heavy).is_empty():
        failures.append("bind-heavy should fail")
    if failures.is_empty():
        lines.append("    plausibility_gates=ok")
    else:
        for msg in failures:
            lines.append("    BOUNDARY_FAIL fixture: %s" % msg)
    lines.append("")
    return not failures.is_empty()


static func _append_q2_worksheet_snapshot(lines: PackedStringArray) -> void:
    lines.append("  [worksheet]")
    if FileAccess.file_exists(WORKSHEET_PATH):
        var body: String = FileAccess.get_file_as_string(WORKSHEET_PATH).strip_edges()
        for part in body.split("\n", false):
            lines.append("    %s" % part)
    else:
        lines.append("    (missing .ii2b_worksheet_prefill.txt  -  written by D-001 harness after ii2b)")
    lines.append("")


static func _append_q2_f5_subjective_checklist(lines: PackedStringArray) -> void:
    lines.append("  [f5_subjective  -  human only]")
    lines.append("    main.tscn: dev_soak_encounter=ii2b (dev_research_feel optional)")
    lines.append("    play: deflect timing readable; riposte after deflect; flurry window after bind")
    lines.append("    grep: parry_deflect | parry_bind | riposte_chain | flurry_bind | parry_stats deflect=")
    lines.append("    helper: .\\scripts\\run_q_feel.ps1 -Track Q2")
    lines.append("")


static func _append_q3_ii5(lines: PackedStringArray) -> bool:
    lines.append("[Q3 ii5 fall_back]")
    var d001: PackedStringArray = _read_d001_lines()
    if d001.is_empty():
        lines.append("  BOUNDARY_FAIL missing .d001_soak_out.txt")
        lines.append("")
        return true
    if not _TrackSpecs.d001_report_pass(d001, _SoakPresets.PRESET_II5_COWERING):
        lines.append("  BOUNDARY_FAIL [ii5] pass=false")
        lines.append("")
        return true
    var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(d001, _SoakPresets.PRESET_II5_COWERING)
    var fail: bool = false
    for cid in II5_CHECKS:
        if _TrackSpecs.d001_report_check_pass(section, cid):
            lines.append("  %s=pass" % cid)
        else:
            lines.append("  BOUNDARY_FAIL %s not PASS in d001 report" % cid)
            fail = true
    lines.append("  f5_only=walk cyan ii5 tile; pick fall_back when listed (2x3 world UX)")
    lines.append("")
    return fail


static func _append_q3_ii4d(lines: PackedStringArray) -> bool:
    lines.append("[Q3 ii4d exhaustion]")
    var d001: PackedStringArray = _read_d001_lines()
    if d001.is_empty():
        lines.append("  BOUNDARY_FAIL missing .d001_soak_out.txt")
        lines.append("")
        return true
    if not _TrackSpecs.d001_report_pass(d001, _SoakPresets.PRESET_II4D_EXHAUSTION):
        lines.append("  BOUNDARY_FAIL [ii4d] pass=false")
        lines.append("")
        return true
    var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(d001, _SoakPresets.PRESET_II4D_EXHAUSTION)
    var fail: bool = false
    for cid in II4D_CHECKS:
        if _TrackSpecs.d001_report_check_pass(section, cid):
            lines.append("  %s=pass" % cid)
        else:
            lines.append("  BOUNDARY_FAIL %s not PASS in d001 report" % cid)
            fail = true
    var ex_line: String = _TrackSpecs.d001_report_field_line(section, "exhaustion_stats")
    if not ex_line.is_empty():
        lines.append("  %s" % ex_line)
    lines.append("  f5_only=3-5 min duel pacing (bands already headless)")
    lines.append("")
    return fail


static func _append_q4_ii8(lines: PackedStringArray) -> bool:
    lines.append("[Q4 ii8 formation diagram]")
    var d001: PackedStringArray = _read_d001_lines()
    if d001.is_empty():
        lines.append("  BOUNDARY_FAIL missing .d001_soak_out.txt")
        lines.append("")
        return true
    if not _TrackSpecs.d001_report_pass(d001, _SoakPresets.PRESET_II8_FORMATION):
        lines.append("  BOUNDARY_FAIL [ii8] pass=false")
        lines.append("")
        return true
    var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(d001, _SoakPresets.PRESET_II8_FORMATION)
    var fail: bool = false
    for cid in II8_CHECKS:
        if _TrackSpecs.d001_report_check_pass(section, cid):
            lines.append("  %s=pass" % cid)
        else:
            lines.append("  BOUNDARY_FAIL %s not PASS in d001 report" % cid)
            fail = true
    for raw in section:
        var line: String = str(raw).strip_edges()
        if line.begins_with("diagram_banner:") and " PASS (" not in line:
            lines.append("  %s" % line)
            break
    lines.append("  f5_only=widget layout / label centering glance")
    lines.append("")
    return fail


static func _append_q1_research_feel(lines: PackedStringArray) -> bool:
    lines.append("[Q1 research_feel]")
    var graze: Dictionary = _Audit.f5_forearm_graze_metrics()
    var chest: Dictionary = _Audit.f5_armored_chest_metrics()
    var mace: Dictionary = _Audit.f5_mace_elbow_metrics()
    _log_q1_scenario(lines, "forearm_graze", graze, "right_arm", "forearm")
    _log_q1_scenario(lines, "armored_chest_bare", _q1_bare_row_from_chest(chest), "chest", "thoracic")
    _log_q1_scenario(lines, "armored_chest_plate", _q1_armored_row_from_chest(chest), "chest", "thoracic")
    _log_q1_scenario(lines, "mace_elbow", mace, "right_arm", "elbow")
    _append_q1_global_benchmarks(lines)
    return _append_q1_boundary_checks(lines, graze, chest, mace)


static func _q1_bare_row_from_chest(m: Dictionary) -> Dictionary:
    return {
        "final_cut": m.get("bare_damage_sum", 0.0),
        "final_blunt": 0.0,
        "final_bone": 0.0,
        "penetration_to_tissue_mm": m.get("bare_tissue_pen_mm", 0.0),
        "transmitted_ke_fraction": 1.0,
    }


static func _q1_armored_row_from_chest(m: Dictionary) -> Dictionary:
    return {
        "final_cut": m.get("armored_damage_sum", 0.0),
        "final_blunt": 0.0,
        "final_bone": 0.0,
        "penetration_to_tissue_mm": m.get("armored_tissue_pen_mm", 0.0),
        "transmitted_ke_fraction": m.get("transmitted_ke_fraction", 1.0),
    }


static func _log_q1_scenario(
    lines: PackedStringArray, label: String, res: Dictionary, part: String, sub: String
) -> void:
    lines.append("  [%s]" % label)
    (
        lines
        . append(
            (
                "    research_feel part=%s sub=%s cut=%.1f blunt=%.1f bone=%.1f pen_mm=%.2f ke_frac=%.2f"
                % [
                    part,
                    sub,
                    res.get("final_cut", 0.0),
                    res.get("final_blunt", 0.0),
                    res.get("final_bone", 0.0),
                    res.get("penetration_to_tissue_mm", -1.0),
                    res.get("transmitted_ke_fraction", 1.0),
                ]
            )
        )
    )


static func _append_q1_global_benchmarks(lines: PackedStringArray) -> void:
    lines.append("  [global_research_benchmarks]")
    var ttd: float = _Research.clinical_ttd_seconds(1.0)
    var ttd_ok: bool = (
        ttd >= _Research.LITERATURE_TTD_UNTREATED_S_MIN and ttd <= _Research.LITERATURE_TTD_UNTREATED_S_MAX
    )
    (
        lines
        . append(
            (
                "    TTD_uncontrolled_s=%.1f band=%.0f-%.0f verdict=%s"
                % [
                    ttd,
                    _Research.LITERATURE_TTD_UNTREATED_S_MIN,
                    _Research.LITERATURE_TTD_UNTREATED_S_MAX,
                    "pass" if ttd_ok else "FAIL",
                ]
            )
        )
    )
    var ke: float = _Research.committed_oberhau_ke_j()
    var ke_ok: bool = (
        ke >= _Research.LITERATURE_HEMA_COMMITTED_KE_J_MIN and ke <= _Research.LITERATURE_HEMA_COMMITTED_KE_J_MAX
    )
    (
        lines
        . append(
            (
                "    committed_oberhau_ke_J=%.0f band=%.0f-%.0f verdict=%s"
                % [
                    ke,
                    _Research.LITERATURE_HEMA_COMMITTED_KE_J_MIN,
                    _Research.LITERATURE_HEMA_COMMITTED_KE_J_MAX,
                    "pass" if ke_ok else "FAIL",
                ]
            )
        )
    )
    var ml_max: float = _BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT
    var per_kg: float = _Research.blood_ml_per_kg_at_reference_mass(_DesignAnchors.REFERENCE_ADULT_MASS_KG)
    var ml_ok: bool = (
        absf(per_kg - _Research.LITERATURE_BLOOD_ML_PER_KG_NOMINAL) <= _Research.LITERATURE_BLOOD_ML_PER_KG_TOLERANCE
    )
    lines.append(
        (
            "    blood_ml_max=%.0f ml_per_kg=%.1f want~%.0f verdict=%s"
            % [ml_max, per_kg, _Research.LITERATURE_BLOOD_ML_PER_KG_NOMINAL, "pass" if ml_ok else "FAIL"]
        )
    )


static func _append_q1_boundary_checks(
    lines: PackedStringArray, graze: Dictionary, chest: Dictionary, mace: Dictionary
) -> bool:
    lines.append("  [boundary_checks]")
    var fail: bool = false
    fail = (
        _append_q1_check(
            lines,
            "graze_no_bone",
            graze.get("final_bone", 0.0) < 0.01,
            "bone=%.2f" % graze.get("final_bone", 0.0),
        )
        or fail
    )
    fail = (
        _append_q1_check(
            lines,
            "graze_shallow_pen",
            graze.get("penetration_to_tissue_mm", 99.0) <= 1.5,
            "pen_mm=%.2f" % graze.get("penetration_to_tissue_mm", 0.0),
        )
        or fail
    )
    fail = (
        _append_q1_check(
            lines,
            "graze_has_cut",
            graze.get("final_cut", 0.0) > 0.0,
            "cut=%.2f" % graze.get("final_cut", 0.0),
        )
        or fail
    )
    fail = (
        _append_q1_check(
            lines,
            "cuirass_lowers_pen",
            chest.get("armored_tissue_pen_mm", 0.0) < chest.get("bare_tissue_pen_mm", 0.0) - 0.01,
            "bare=%.2f armored=%.2f" % [chest.get("bare_tissue_pen_mm", 0.0), chest.get("armored_tissue_pen_mm", 0.0)],
        )
        or fail
    )
    fail = (
        _append_q1_check(
            lines,
            "cuirass_ke_frac",
            chest.get("transmitted_ke_fraction", 0.0) > 0.5 and chest.get("transmitted_ke_fraction", 0.0) < 1.0,
            "ke_frac=%.3f" % chest.get("transmitted_ke_fraction", 1.0),
        )
        or fail
    )
    fail = (
        _append_q1_check(
            lines,
            "cuirass_lowers_damage",
            chest.get("armored_damage_sum", 0.0) < chest.get("bare_damage_sum", 0.0) - 0.5,
            (
                "bare_dmg=%.1f armored_dmg=%.1f"
                % [chest.get("bare_damage_sum", 0.0), chest.get("armored_damage_sum", 0.0)]
            ),
        )
        or fail
    )
    fail = (
        _append_q1_check(
            lines,
            "mace_bone_chip",
            mace.get("final_bone", 0.0) >= 0.5,
            (
                "bone=%.2f KE=%.0f anchor=%.0f"
                % [mace.get("final_bone", 0.0), mace.get("strike_ke_j", 0.0), mace.get("j_anchor", 0.0)]
            ),
        )
        or fail
    )
    lines.append(
        "    note=matches .calibration_audit.txt [f5_scenario_headless]; F5 editor adds live duel parry/bind lines"
    )
    lines.append("    helper: .\\scripts\\run_q_feel.ps1 -Track Q1")
    lines.append("")
    return fail


static func _append_q1_check(lines: PackedStringArray, id: String, ok: bool, detail: String) -> bool:
    var tag: String = "pass" if ok else "BOUNDARY_FAIL"
    lines.append("    %s %s (%s)" % [id, tag, detail])
    return not ok
