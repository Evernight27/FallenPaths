extends SceneTree

## Validate pasted F5 Output — **`FP_F5_SOAK_VALIDATION`** in **`.f5_soak_validation.txt`**.
## Input: **`.f5_soak_in.txt`** at project root, or first user arg after **`--`**.
## Example: `godot --headless --path <project> -s res://scripts/run_f5_soak_log_validator.gd -- my_fight.log`

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _Validator := preload("res://combat/CombatF5SoakLogValidator.gd")
const RUNNER_NAME := "CombatF5SoakLogValidator"


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	_OperationalLog.harness_begin(RUNNER_NAME)
	var path: String = _resolve_input_path()
	if not FileAccess.file_exists(path):
		var msg: String = (
			"Missing log file: %s — copy Godot Output after F5 soak, save as that path, re-run."
			% path
		)
		_OperationalLog.harness_fail(RUNNER_NAME, PackedStringArray([msg]))
		quit(2)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var lines: PackedStringArray = PackedStringArray()
	for part in text.split("\n", false):
		lines.append(part)
	var result: Dictionary = _Validator.validate(lines)
	_Validator.write_report(result)
	if bool(result.get("ok", false)):
		_OperationalLog.harness_ok(
			RUNNER_NAME,
			"profiles=%s lines=%d"
			% [", ".join(result.get("profiles", PackedStringArray())), int(result.get("line_count", 0))]
		)
		quit(0)
	else:
		_OperationalLog.harness_fail(RUNNER_NAME, result.get("failures", PackedStringArray()))
		quit(1)
	return


static func _resolve_input_path() -> String:
	var root: String = ProjectSettings.globalize_path("res://")
	for arg in OS.get_cmdline_user_args():
		var a: String = str(arg).strip_edges()
		if a.is_empty() or a.begins_with("-"):
			continue
		if a.begins_with("res://"):
			return ProjectSettings.globalize_path(a)
		if a.contains("/") or a.contains("\\") or a.ends_with(".txt") or a.ends_with(".log"):
			return a if a.is_absolute_path() else root.path_join(a)
		return root.path_join(a)
	return root.path_join(_Validator.DEFAULT_INPUT_FILENAME)
