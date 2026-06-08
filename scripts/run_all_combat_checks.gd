extends SceneTree

## Headless combat checks — set **`FP_HARNESS_MODE`** (`all` default · `regression` · `d001` · `d001_presets` · `sanity` · `calibration` · `medical` · `f5_validate` · `q_track`).
## Phase 0: **`run_all_combat_checks.ps1`** / **`.sh`**. Q track: mode **`q_track`**. F5 validate: **`f5_validate`** (+ optional path after **`--`**).

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _D001Runner := preload("res://combat/CombatD001SoakRunner.gd")
const _CalibrationAudit := preload("res://combat/CombatCalibrationAudit.gd")
const _SoakSanity := preload("res://combat/CombatD001SoakSanity.gd")
const _MedicalPhaseTail := preload("res://combat/CombatRegressionHarnessMedicalPhaseTail.gd")
const _F5Validator := preload("res://combat/CombatF5SoakLogValidator.gd")
const _QTrack := preload("res://combat/CombatQTrackAudits.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const HARNESS_NAME := "AllCombatChecks"
const MEDICAL_FAST_NAME := "MedicalPhaseHarness"
const MEDICAL_FAST_TEST_COUNT := 32
const D001_PRESETS_NAME := "D001PresetsIi5Ii6"
const F5_VALIDATOR_NAME := "CombatF5SoakLogValidator"


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
		"q_track":
			_run_mode_q_track()
		"all":
			_run_mode_all()
		_:
			_OperationalLog.harness_fail(
				HARNESS_NAME,
				PackedStringArray(["unknown FP_HARNESS_MODE=%s" % mode])
			)
			quit(1)
	return


func _run_mode_regression() -> void:
	var failures: PackedStringArray = PackedStringArray()
	_merge_failures(failures, "CombatRegressionHarness", _run_regression())
	_quit_mode("CombatRegressionHarness", failures, "regression")


func _run_mode_d001() -> void:
	var failures: PackedStringArray = PackedStringArray()
	_merge_failures(failures, _D001Runner.RUNNER_NAME, _run_d001())
	_quit_mode(_D001Runner.RUNNER_NAME, failures, "d001")


func _run_mode_calibration() -> void:
	var failures: PackedStringArray = PackedStringArray()
	_merge_failures(failures, "CombatCalibrationAudit", _run_calibration_audit())
	_quit_mode("CombatCalibrationAudit", failures, "calibration")


func _run_mode_medical() -> void:
	_OperationalLog.harness_begin(MEDICAL_FAST_NAME)
	var failures: PackedStringArray = PackedStringArray()
	_MedicalPhaseTail.run_fast_phase_halt_checks(failures)
	CombatRegressionHarness.flush_harness_live_nodes()
	if failures.is_empty():
		quit(_OperationalLog.harness_ok(MEDICAL_FAST_NAME, "(%d tests)" % MEDICAL_FAST_TEST_COUNT))
		return
	quit(_OperationalLog.harness_fail(MEDICAL_FAST_NAME, failures, "(%d tests)" % MEDICAL_FAST_TEST_COUNT))
	return


func _run_mode_sanity() -> void:
	_OperationalLog.harness_begin(_SoakSanity.RUNNER_NAME)
	var r: Dictionary = _SoakSanity.run_all()
	CombatRegressionHarness.flush_harness_live_nodes()
	if bool(r.get("ok", false)):
		quit(_OperationalLog.harness_ok(_SoakSanity.RUNNER_NAME))
	else:
		quit(_OperationalLog.harness_fail(_SoakSanity.RUNNER_NAME, r.get("failures", PackedStringArray())))
	return


func _run_mode_all() -> void:
	var failures: PackedStringArray = PackedStringArray()
	_merge_failures(failures, "CombatRegressionHarness", _run_regression())
	_merge_failures(failures, _D001Runner.RUNNER_NAME, _run_d001())
	_merge_failures(failures, "CombatCalibrationAudit", _run_calibration_audit())
	_quit_mode(HARNESS_NAME, failures, "regression+d001")


func _quit_mode(label: String, failures: PackedStringArray, detail: String) -> void:
	CombatRegressionHarness.flush_harness_live_nodes()
	if failures.is_empty():
		quit(_OperationalLog.harness_ok(label, detail))
	else:
		quit(_OperationalLog.harness_fail(label, failures))
	return


func _run_regression() -> Dictionary:
	print("=== CombatRegressionHarness ===")
	_OperationalLog.harness_begin("CombatRegressionHarness")
	return CombatRegressionHarness.run_all()


func _run_d001() -> Dictionary:
	print("=== CombatD001SoakRunner ===")
	_OperationalLog.harness_begin(_D001Runner.RUNNER_NAME)
	return _D001Runner.run_all()


func _run_calibration_audit() -> Dictionary:
	print("=== CombatCalibrationAudit ===")
	_OperationalLog.harness_begin("CombatCalibrationAudit")
	return _CalibrationAudit.run_and_write_report()


func _merge_failures(
	out: PackedStringArray,
	label: String,
	result: Dictionary
) -> void:
	if bool(result.get("ok", false)):
		if not bool(result.get("harness_ok_emitted", false)):
			_OperationalLog.harness_ok(label)
		return
	for raw in result.get("failures", PackedStringArray()) as PackedStringArray:
		out.append("%s: %s" % [label, raw])


func _run_mode_d001_presets() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	var preset_ids: PackedStringArray = _resolve_d001_preset_ids()
	_OperationalLog.harness_begin(D001_PRESETS_NAME)
	var r: Dictionary = _D001Runner.run_preset_ids(preset_ids)
	_print_d001_preset_summary(r)
	CombatRegressionHarness.flush_harness_live_nodes()
	if bool(r.get("ok", false)):
		_OperationalLog.harness_ok(D001_PRESETS_NAME, "presets=%s" % ", ".join(preset_ids))
		quit(0)
		return
	_OperationalLog.harness_fail(D001_PRESETS_NAME, r.get("failures", PackedStringArray()))
	quit(1)


func _resolve_d001_preset_ids() -> PackedStringArray:
	var raw: String = OS.get_environment("D001_PRESETS").strip_edges()
	if raw.is_empty():
		return PackedStringArray([
			_SoakPresets.PRESET_II5_COWERING,
			_SoakPresets.PRESET_II6_AMBIENT_SHOCK,
		])
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
			_OperationalLog.tag_line(
				_OperationalLog.TAG_HARNESS_SUMMARY,
				"[%s] ok=%s %s | %s"
				% [
					pid,
					str(bool(pr.get("ok", false))).to_lower(),
					str(pr.get("summary", "")),
					", ".join(check_bits),
				]
			)
		)


func _run_mode_f5_validate() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	_OperationalLog.harness_begin(F5_VALIDATOR_NAME)
	var path: String = _resolve_f5_input_path()
	if not FileAccess.file_exists(path):
		var msg: String = (
			"Missing log file: %s — copy Godot Output after F5 soak, save as that path, re-run."
			% path
		)
		_OperationalLog.harness_fail(F5_VALIDATOR_NAME, PackedStringArray([msg]))
		CombatRegressionHarness.flush_harness_live_nodes()
		quit(2)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var lines: PackedStringArray = _F5Validator._decode_f5_log_text(text)
	var result: Dictionary = _F5Validator.validate(lines)
	_F5Validator.write_report(result)
	if bool(result.get("ok", false)):
		_OperationalLog.harness_ok(
			F5_VALIDATOR_NAME,
			"profiles=%s lines=%d"
			% [", ".join(result.get("profiles", PackedStringArray())), int(result.get("line_count", 0))]
		)
		CombatRegressionHarness.flush_harness_live_nodes()
		quit(0)
		return
	_OperationalLog.harness_fail(F5_VALIDATOR_NAME, result.get("failures", PackedStringArray()))
	CombatRegressionHarness.flush_harness_live_nodes()
	quit(1)


func _run_mode_q_track() -> void:
	var code: int = _QTrack.run_headless()
	CombatRegressionHarness.flush_harness_live_nodes()
	quit(code)


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
	return root.path_join(_F5Validator.DEFAULT_INPUT_FILENAME)
