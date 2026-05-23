extends SceneTree

## Headless **ii5** (cowering **fall_back**) + **ii6** (ambient pain shock) — grep **`.ii5_ii6_soak_out.txt`**.
## Usage: Godot -s res://scripts/run_d001_presets.gd
## Optional env **`D001_PRESETS=ii5,ii6`** (default both).

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _D001Runner := preload("res://combat/CombatD001SoakRunner.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")

const HARNESS_NAME := "D001PresetsIi5Ii6"


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	var preset_ids: PackedStringArray = _resolve_preset_ids()
	_OperationalLog.harness_begin(HARNESS_NAME)
	var r: Dictionary = _D001Runner.run_preset_ids(preset_ids)
	_print_preset_summary(r)
	if bool(r.get("ok", false)):
		_OperationalLog.harness_ok(HARNESS_NAME, "presets=%s" % ", ".join(preset_ids))
	else:
		_OperationalLog.harness_fail(HARNESS_NAME, r.get("failures", PackedStringArray()))
	quit(0 if bool(r.get("ok", false)) else 1)


func _resolve_preset_ids() -> PackedStringArray:
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


func _print_preset_summary(r: Dictionary) -> void:
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
