class_name CombatF5SoakLogValidator
extends RefCounted

## Parses pasted **F5 Output** (or **`.f5_soak_in.txt`**) for **D-001** / II-0 grep sign-offs.
## Headless entry: **`scripts/run_f5_soak_log_validator.gd`** → **`.f5_soak_validation.txt`**.

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const REPORT_TAG_BEGIN := "--- FP_F5_SOAK_VALIDATION ---"
const REPORT_TAG_END := "--- END FP_F5_SOAK_VALIDATION ---"
const REPORT_FILENAME := ".f5_soak_validation.txt"
const DEFAULT_INPUT_FILENAME := ".f5_soak_in.txt"

const PROFILE_ALWAYS := _TrackSpecs.PROFILE_ALWAYS
const PROFILE_7V7 := _TrackSpecs.PROFILE_7V7
const PROFILE_PRESET_II2B := _TrackSpecs.PROFILE_PRESET_II2B
const PROFILE_PRESET_II3 := _TrackSpecs.PROFILE_PRESET_II3
const PROFILE_PRESET_II5 := _TrackSpecs.PROFILE_PRESET_II5
const PROFILE_PRESET_II6 := _TrackSpecs.PROFILE_PRESET_II6
const PROFILE_PRESET_II8 := _TrackSpecs.PROFILE_PRESET_II8
const PROFILE_PRESET_II4D := _TrackSpecs.PROFILE_PRESET_II4D
const PROFILE_PRESET_II_ENVELOP := _TrackSpecs.PROFILE_PRESET_II_ENVELOP
const PROFILE_CAMP_EA := _TrackSpecs.PROFILE_CAMP_EA

static func validate(lines: PackedStringArray, profiles_override: PackedStringArray = []) -> Dictionary:
	var normalized: PackedStringArray = _normalize_lines(lines)
	var profiles: PackedStringArray = (
		profiles_override
		if not profiles_override.is_empty()
		else _TrackSpecs.detect_profiles(normalized)
	)
	var tracks: Array = _TrackSpecs.validator_tracks(profiles)
	var track_results: Dictionary = {}
	var failures: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	for spec in tracks:
		var id: String = str(spec.get("id", ""))
		var result: Dictionary = _evaluate_track(normalized, spec)
		track_results[id] = result
		if not bool(result.get("pass", false)):
			if bool(spec.get("optional", false)):
				warnings.append("%s: %s" % [id, str(result.get("detail", "fail"))])
			else:
				failures.append("%s: %s" % [id, str(result.get("detail", "fail"))])
	var missing_cyan: PackedStringArray = _TrackSpecs.missing_cyan_presets(profiles)
	var ok: bool = failures.is_empty()
	return {
		"ok": ok,
		"profiles": profiles,
		"tracks": track_results,
		"failures": failures,
		"warnings": warnings,
		"line_count": normalized.size(),
		"grep_stats": _grep_stats(normalized),
		"missing_cyan_presets": missing_cyan,
	}


static func write_report(result: Dictionary) -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(REPORT_TAG_BEGIN)
	lines.append("ok=%s" % str(bool(result.get("ok", false))).to_lower())
	lines.append("profiles=%s" % ", ".join(result.get("profiles", PackedStringArray())))
	var missing: PackedStringArray = result.get("missing_cyan_presets", PackedStringArray()) as PackedStringArray
	if missing.is_empty():
		lines.append("missing_cyan_presets=(none — ii2b/ii5/ii6 present or not applicable)")
	else:
		lines.append(
			"missing_cyan_presets=%s — F5 dev_soak_encounter then re-validate"
			% ", ".join(missing)
		)
	lines.append("lines=%d" % int(result.get("line_count", 0)))
	var stats: Dictionary = result.get("grep_stats", {}) as Dictionary
	if not stats.is_empty():
		lines.append("")
		lines.append("grep_stats:")
		for stat_key in stats.keys():
			lines.append("  %s=%d" % [str(stat_key), int(stats[stat_key])])
	lines.append("")
	var tracks: Dictionary = result.get("tracks", {}) as Dictionary
	for track_id in tracks.keys():
		var track_result: Dictionary = tracks[track_id] as Dictionary
		var status: String = "PASS" if bool(track_result.get("pass", false)) else "FAIL"
		if bool(track_result.get("optional", false)) and not bool(track_result.get("pass", false)):
			status = "OPTIONAL_MISS"
		lines.append(
			"[%s] %s — %s"
			% [track_id, status, str(track_result.get("detail", ""))]
		)
	lines.append("")
	lines.append("failures:")
	for f in result.get("failures", PackedStringArray()) as PackedStringArray:
		lines.append("  - %s" % f)
	lines.append("warnings:")
	for w in result.get("warnings", PackedStringArray()) as PackedStringArray:
		lines.append("  - %s" % w)
	lines.append(REPORT_TAG_END)
	var body: String = "\n".join(lines) + "\n"
	var path: String = ProjectSettings.globalize_path("res://").path_join(REPORT_FILENAME)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(body)
		f.close()
	print(_OperationalLog.tag_line(_OperationalLog.TAG_HARNESS_SUMMARY, "wrote %s" % path))
	print(body.strip_edges())


static func _normalize_lines(lines: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for raw in lines:
		var s: String = str(raw).strip_edges()
		if s.is_empty() or s.begins_with("#"):
			continue
		if s.begins_with(_OperationalLog.TAG_COMBAT + ":"):
			s = s.substr(_OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
		elif s.begins_with(_OperationalLog.TAG_WORLD + ":"):
			s = s.substr(_OperationalLog.TAG_WORLD.length() + 1).strip_edges()
		out.append(s)
	return out


static func _evaluate_track(normalized: PackedStringArray, spec: Dictionary) -> Dictionary:
	var optional: bool = bool(spec.get("optional", false))
	if spec.has("when_ok_at_least"):
		var gate_id: String = str(spec.get("when_ok_at_least", ""))
		var gate_needle: String = gate_id
		if gate_id == "tooltip_match_ok":
			gate_needle = "tooltip_match=ok"
		if _count_needle(normalized, gate_needle) < 1:
			return {
				"pass": true,
				"detail": "skipped (no %s)" % gate_id,
				"optional": optional,
				"skipped": true,
			}
	var count: int = 0
	if spec.has("regex"):
		count = _count_regex(normalized, str(spec.get("regex", "")))
	else:
		count = _count_needle(normalized, str(spec.get("needle", "")))
		if count < int(spec.get("min", 1)) and spec.has("alt_needles"):
			for alt in spec.get("alt_needles", []) as Array:
				count += _count_needle(normalized, str(alt))
	var min_c: int = int(spec.get("min", 1))
	var max_c: int = int(spec.get("max", -1))
	var ok_check: bool = true
	if max_c >= 0:
		ok_check = count <= max_c
	else:
		ok_check = count >= min_c
	var detail: String = "count=%d" % count
	if max_c >= 0:
		detail += " need<=%d" % max_c
	else:
		detail += " need>=%d" % min_c
	return {"pass": ok_check, "detail": detail, "optional": optional, "count": count}


static func _is_soak_guide_line(line: String) -> bool:
	# Startup hints mention grep targets (e.g. `FP_ERROR`, `crash_success`) — not real errors.
	return line.begins_with("soak_guide ") or line.begins_with("soak_guide:")


static func _count_needle(lines: PackedStringArray, needle: String) -> int:
	if needle.is_empty():
		return 0
	var n: int = 0
	for line in lines:
		if _is_soak_guide_line(line):
			continue
		if needle in line:
			n += 1
	return n


static func _count_regex(lines: PackedStringArray, pattern: String) -> int:
	if pattern.is_empty():
		return 0
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		return 0
	var n: int = 0
	for line in lines:
		if re.search(line) != null:
			n += 1
	return n


static func _grep_stats(normalized: PackedStringArray) -> Dictionary:
	return _TrackSpecs.grep_stats(
		normalized,
		func(lines: PackedStringArray, needle: String) -> int: return _count_needle(lines, needle),
		func(lines: PackedStringArray, pattern: String) -> int: return _count_regex(lines, pattern)
	)
