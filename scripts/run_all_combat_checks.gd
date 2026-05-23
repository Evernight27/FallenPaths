extends SceneTree

## Headless combat checks — set **`FP_HARNESS_MODE`** (`all` default · `regression` · `d001` · `sanity` · `calibration` · `medical`).
## Phase 0: **`run_all_combat_checks.ps1`** / **`.sh`**. Presets subset: **`run_d001_presets.gd`**. F5 log: **`run_f5_soak_log_validator.gd`**.

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _D001Runner := preload("res://combat/CombatD001SoakRunner.gd")
const _CalibrationAudit := preload("res://combat/CombatCalibrationAudit.gd")
const _SoakSanity := preload("res://combat/CombatD001SoakSanity.gd")
const _MedicalPhaseTail := preload("res://combat/CombatRegressionHarnessMedicalPhaseTail.gd")
const HARNESS_NAME := "AllCombatChecks"
const MEDICAL_FAST_NAME := "MedicalPhaseHarness"
const MEDICAL_FAST_TEST_COUNT := 12


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
	if failures.is_empty():
		quit(_OperationalLog.harness_ok(MEDICAL_FAST_NAME, "(%d tests)" % MEDICAL_FAST_TEST_COUNT))
		return
	quit(_OperationalLog.harness_fail(MEDICAL_FAST_NAME, failures, "(%d tests)" % MEDICAL_FAST_TEST_COUNT))
	return


func _run_mode_sanity() -> void:
	_OperationalLog.harness_begin(_SoakSanity.RUNNER_NAME)
	var r: Dictionary = _SoakSanity.run_all()
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
