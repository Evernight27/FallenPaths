extends SceneTree

## Headless combat checks  -  set **`FP_HARNESS_MODE`** (`all` default . `regression` . `d001` . `d001_presets` .
## `sanity` . `calibration` . `medical` . `f5_validate` . `f5_validate_camp_smokes` . `q_track`).
## Phase 0: **`run_all_combat_checks.ps1`** / **`.sh`**. Q track: mode **`q_track`**. F5 validate: **`f5_validate`** (+
## optional path after **`--`**). Camp smokes batch: **`f5_validate_camp_smokes`**.

const HARNESS_NAME := "AllCombatChecks"
const MEDICAL_FAST_NAME := "MedicalPhaseHarness"
const MEDICAL_FAST_TEST_COUNT := 54
const D001_PRESETS_NAME := "D001PresetsIi5Ii6"
const F5_VALIDATOR_NAME := "CombatF5SoakLogValidator"
const F5_CAMP_SMOKES_BATCH_NAME := "CampOptionalSmokesBatch"
const F5_CAMP_SMOKES_BATCH_REPORT := ".f5_camp_smokes_batch.txt"
const F5_CAMP_SMOKES_BATCH_TAG_END := "--- END FP_F5_CAMP_SMOKES_BATCH ---"
const CAMP_SMOKE_ROWS: Array = [
    {"file": "step3e_mopup.txt", "track": "camp_mopup_strike_finish"},
    {"file": "step4_field_care_action.txt", "track": "camp_field_care_action"},
    {"file": "step8_paid_loss.txt", "track": "camp_paid_loss"},
    {"file": "step8_tutorial_soft.txt", "track": "camp_tutorial_soft_loss"},
    {"file": "step9_wage_warn.txt", "track": "camp_wage_warn"},
    {"file": "step9_desertion.txt", "track": "camp_desertion"},
    {"file": "step10_party_triage.txt", "track": "camp_party_triage"},
    {"file": "medical_exit.txt", "track": "camp_medical_exit"},
]


func _init() -> void:
    CombatConstants.set_headless_harness_quiet(true)
    var mode: String = OS.get_environment("FP_HARNESS_MODE").strip_edges().to_lower()
    if mode.is_empty():
        mode = "all"
    match mode:
        "regression":
            _run_mode_regression()
        "d001":
            _run_mode_d001()
        "sanity":
            _run_mode_sanity()
        "calibration":
            _run_mode_calibration()
        "medical":
            _run_mode_medical()
        "d001_presets":
            _run_mode_d001_presets()
        "f5_validate":
            _run_mode_f5_validate()
        "f5_validate_camp_smokes":
            _run_mode_f5_validate_camp_smokes()
        "q_track":
            _run_mode_q_track()
        "all":
            _run_mode_all()
        _:
            OperationalLog.harness_fail(HARNESS_NAME, PackedStringArray(["unknown FP_HARNESS_MODE=%s" % mode]))
            quit(1)
    return


func _run_mode_regression() -> void:
    var failures: PackedStringArray = PackedStringArray()
    _merge_failures(failures, "CombatRegressionHarness", _run_regression())
    _quit_mode("CombatRegressionHarness", failures, "regression")


func _run_mode_d001() -> void:
    var failures: PackedStringArray = PackedStringArray()
    _merge_failures(failures, CombatD001SoakRunner.RUNNER_NAME, _run_d001())
    _quit_mode(CombatD001SoakRunner.RUNNER_NAME, failures, "d001")


func _run_mode_calibration() -> void:
    var failures: PackedStringArray = PackedStringArray()
    _merge_failures(failures, "CombatCalibrationAudit", _run_calibration_audit())
    _quit_mode("CombatCalibrationAudit", failures, "calibration")


func _run_mode_medical() -> void:
    OperationalLog.harness_begin(MEDICAL_FAST_NAME)
    var failures: PackedStringArray = PackedStringArray()
    CombatRegressionHarnessMedicalPhaseTail.run_fast_phase_halt_checks(failures)
    CombatRegressionHarness.flush_harness_live_nodes()
    if failures.is_empty():
        quit(OperationalLog.harness_ok(MEDICAL_FAST_NAME, "(%d tests)" % MEDICAL_FAST_TEST_COUNT))
        return
    quit(OperationalLog.harness_fail(MEDICAL_FAST_NAME, failures, "(%d tests)" % MEDICAL_FAST_TEST_COUNT))
    return


func _run_mode_sanity() -> void:
    OperationalLog.harness_begin(CombatD001SoakSanity.RUNNER_NAME)
    var r: Dictionary = CombatD001SoakSanity.run_all()
    CombatRegressionHarness.flush_harness_live_nodes()
    if bool(r.get("ok", false)):
        quit(OperationalLog.harness_ok(CombatD001SoakSanity.RUNNER_NAME))
    else:
        quit(OperationalLog.harness_fail(CombatD001SoakSanity.RUNNER_NAME, r.get("failures", PackedStringArray())))
    return


func _run_mode_all() -> void:
    var failures: PackedStringArray = PackedStringArray()
    _merge_failures(failures, "CombatRegressionHarness", _run_regression())
    _merge_failures(failures, CombatD001SoakRunner.RUNNER_NAME, _run_d001())
    _merge_failures(failures, "CombatCalibrationAudit", _run_calibration_audit())
    _quit_mode(HARNESS_NAME, failures, "regression+d001")


func _quit_mode(label: String, failures: PackedStringArray, detail: String) -> void:
    CombatRegressionHarness.flush_harness_live_nodes()
    if failures.is_empty():
        quit(OperationalLog.harness_ok(label, detail))
    else:
        quit(OperationalLog.harness_fail(label, failures))
    return


func _run_regression() -> Dictionary:
    print("=== CombatRegressionHarness ===")
    OperationalLog.harness_begin("CombatRegressionHarness")
    return CombatRegressionHarness.run_all()


func _run_d001() -> Dictionary:
    print("=== CombatD001SoakRunner ===")
    OperationalLog.harness_begin(CombatD001SoakRunner.RUNNER_NAME)
    return CombatD001SoakRunner.run_all()


func _run_calibration_audit() -> Dictionary:
    print("=== CombatCalibrationAudit ===")
    OperationalLog.harness_begin("CombatCalibrationAudit")
    return CombatCalibrationAudit.run_and_write_report()


func _merge_failures(out: PackedStringArray, label: String, result: Dictionary) -> void:
    if bool(result.get("ok", false)):
        if not bool(result.get("harness_ok_emitted", false)):
            OperationalLog.harness_ok(label)
        return
    for raw in result.get("failures", PackedStringArray()) as PackedStringArray:
        out.append("%s: %s" % [label, raw])


func _run_mode_d001_presets() -> void:
    CombatConstants.set_headless_harness_quiet(true)
    var preset_ids: PackedStringArray = _resolve_d001_preset_ids()
    OperationalLog.harness_begin(D001_PRESETS_NAME)
    var r: Dictionary = CombatD001SoakRunner.run_preset_ids(preset_ids)
    _print_d001_preset_summary(r)
    CombatRegressionHarness.flush_harness_live_nodes()
    if bool(r.get("ok", false)):
        OperationalLog.harness_ok(D001_PRESETS_NAME, "presets=%s" % ", ".join(preset_ids))
        quit(0)
        return
    OperationalLog.harness_fail(D001_PRESETS_NAME, r.get("failures", PackedStringArray()))
    quit(1)


func _resolve_d001_preset_ids() -> PackedStringArray:
    var raw: String = OS.get_environment("D001_PRESETS").strip_edges()
    if raw.is_empty():
        return PackedStringArray(
            [
                SoakEncounterPresets.PRESET_II5_COWERING,
                SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK,
            ]
        )
    var out: PackedStringArray = PackedStringArray()
    for part in raw.split(","):
        var pid: String = part.strip_edges().to_lower()
        if not pid.is_empty():
            out.append(pid)
    return out


func _print_d001_preset_summary(r: Dictionary) -> void:
    var presets: Dictionary = r.get("presets", {}) as Dictionary
    for pid in presets.keys():
        var pr: Dictionary = presets[pid] as Dictionary
        var checks: Dictionary = pr.get("checks", {}) as Dictionary
        var check_bits: PackedStringArray = PackedStringArray()
        for cid in checks.keys():
            var c: Dictionary = checks[cid] as Dictionary
            var st: String = "PASS" if bool(c.get("pass", false)) else "FAIL"
            check_bits.append("%s=%s" % [cid, st])
        print(
            (
                OperationalLog
                . tag_line(
                    OperationalLog.TAG_HARNESS_SUMMARY,
                    (
                        "[%s] ok=%s %s | %s"
                        % [
                            pid,
                            str(bool(pr.get("ok", false))).to_lower(),
                            str(pr.get("summary", "")),
                            ", ".join(check_bits),
                        ]
                    )
                )
            )
        )


func _run_mode_f5_validate() -> void:
    CombatConstants.set_headless_harness_quiet(true)
    OperationalLog.harness_begin(F5_VALIDATOR_NAME)
    var path: String = _resolve_f5_input_path()
    if not FileAccess.file_exists(path):
        var msg: String = "Missing log file: %s  -  copy Godot Output after F5 soak, save as that path, re-run." % path
        OperationalLog.harness_fail(F5_VALIDATOR_NAME, PackedStringArray([msg]))
        CombatRegressionHarness.flush_harness_live_nodes()
        quit(2)
        return
    var text: String = FileAccess.get_file_as_string(path)
    var lines: PackedStringArray = CombatF5SoakLogValidator._decode_f5_log_text(text)
    var result: Dictionary = CombatF5SoakLogValidator.validate(lines)
    CombatF5SoakLogValidator.write_report(result)
    if bool(result.get("ok", false)):
        OperationalLog.harness_ok(
            F5_VALIDATOR_NAME,
            (
                "profiles=%s lines=%d"
                % [", ".join(result.get("profiles", PackedStringArray())), int(result.get("line_count", 0))]
            )
        )
        CombatRegressionHarness.flush_harness_live_nodes()
        quit(0)
        return
    OperationalLog.harness_fail(F5_VALIDATOR_NAME, result.get("failures", PackedStringArray()))
    CombatRegressionHarness.flush_harness_live_nodes()
    quit(1)


func _run_mode_f5_validate_camp_smokes() -> void:
    CombatConstants.set_headless_harness_quiet(true)
    OperationalLog.harness_begin(F5_CAMP_SMOKES_BATCH_NAME)
    var root: String = ProjectSettings.globalize_path("res://")
    var smoke_dir: String = root.path_join("docs/camp_optional_step_smokes")
    var failures: PackedStringArray = PackedStringArray()
    var passed: int = 0
    var batch_lines: PackedStringArray = PackedStringArray()
    batch_lines.append("--- FP_F5_CAMP_SMOKES_BATCH ---")
    for row in CAMP_SMOKE_ROWS:
        var file_name: String = str(row.get("file", ""))
        var track_id: String = str(row.get("track", ""))
        var path: String = smoke_dir.path_join(file_name)
        if not FileAccess.file_exists(path):
            failures.append("%s: missing file" % file_name)
            batch_lines.append("[%s] %s MISSING" % [file_name, track_id])
            continue
        var text: String = FileAccess.get_file_as_string(path)
        var lines: PackedStringArray = CombatF5SoakLogValidator._decode_f5_log_text(text)
        var result: Dictionary = CombatF5SoakLogValidator.validate(lines)
        var tracks: Dictionary = result.get("tracks", {}) as Dictionary
        var track_result: Dictionary = tracks.get(track_id, {}) as Dictionary
        var track_pass: bool = bool(track_result.get("pass", false))
        var row_ok: bool = bool(result.get("ok", false)) and track_pass
        if row_ok:
            passed += 1
            batch_lines.append("[%s] %s PASS" % [file_name, track_id])
        else:
            var detail: String = (
                "ok=%s track=%s"
                % [
                    str(bool(result.get("ok", false))).to_lower(),
                    "pass" if track_pass else "fail",
                ]
            )
            failures.append("%s: %s" % [file_name, detail])
            batch_lines.append("[%s] %s FAIL  -  %s" % [file_name, track_id, detail])
    batch_lines.append("ok=%s" % str(failures.is_empty()).to_lower())
    batch_lines.append("passed=%d/%d" % [passed, CAMP_SMOKE_ROWS.size()])
    batch_lines.append(F5_CAMP_SMOKES_BATCH_TAG_END)
    _write_text_file(root.path_join(F5_CAMP_SMOKES_BATCH_REPORT), "\n".join(batch_lines) + "\n")
    var human_path: String = root.path_join(CombatF5SoakLogValidator.DEFAULT_INPUT_FILENAME)
    if FileAccess.file_exists(human_path):
        var human_text: String = FileAccess.get_file_as_string(human_path)
        var human_lines: PackedStringArray = CombatF5SoakLogValidator._decode_f5_log_text(human_text)
        var human_result: Dictionary = CombatF5SoakLogValidator.validate(human_lines)
        CombatF5SoakLogValidator.write_report(human_result)
    if failures.is_empty():
        OperationalLog.harness_ok(F5_CAMP_SMOKES_BATCH_NAME, "passed=%d/%d" % [passed, CAMP_SMOKE_ROWS.size()])
        CombatRegressionHarness.flush_harness_live_nodes()
        quit(0)
        return
    OperationalLog.harness_fail(F5_CAMP_SMOKES_BATCH_NAME, failures)
    CombatRegressionHarness.flush_harness_live_nodes()
    quit(1)


func _run_mode_q_track() -> void:
    var code: int = CombatQTrackAudits.run_headless()
    CombatRegressionHarness.flush_harness_live_nodes()
    quit(code)


static func _write_text_file(path: String, body: String) -> void:
    var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if f != null:
        f.store_string(body)
        f.close()


static func _resolve_f5_input_path() -> String:
    var root: String = ProjectSettings.globalize_path("res://")
    var env_path: String = OS.get_environment("FP_F5_VALIDATE_LOG").strip_edges()
    if not env_path.is_empty() and FileAccess.file_exists(env_path):
        return env_path
    for arg in OS.get_cmdline_user_args():
        var a: String = str(arg).strip_edges()
        if a.is_empty() or a.begins_with("-"):
            continue
        if a.begins_with("res://"):
            return ProjectSettings.globalize_path(a)
        if a.contains("/") or a.contains("\\") or a.ends_with(".txt") or a.ends_with(".log"):
            return a if a.is_absolute_path() else root.path_join(a)
        return root.path_join(a)
    return root.path_join(CombatF5SoakLogValidator.DEFAULT_INPUT_FILENAME)
