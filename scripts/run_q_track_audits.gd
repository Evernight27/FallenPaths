extends SceneTree

## Headless Track **Q** proxies (Q2–Q4) vs **`.d001_soak_out.txt`** — no F5 editor.
## Writes **`.q_track_audits.txt`**. Q1: **`run_q_audit.ps1 -Track Q1`** (separate).

const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const OUT_PATH := "res://.q_track_audits.txt"
const D001_PATH := "res://.d001_soak_out.txt"

const II5_CHECKS: Array = ["soak_setup", "cowering_listed", "cowering_executed"]
const II4D_CHECKS: Array = ["exhaustion_25", "exhaustion_band", "ii4d_plausibility"]
const II8_CHECKS: Array = [
	"formation_mode",
	"engagement_ui",
	"turn_ready_gauge",
	"tooltip_match_ok",
	"diagram_banner",
]


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== Q track audits (headless proxies, no F5 sign-off) ===")
	lines.append("")

	var boundary_fail: bool = false
	boundary_fail = _append_q2(lines) or boundary_fail
	boundary_fail = _append_q3_ii5(lines) or boundary_fail
	boundary_fail = _append_q3_ii4d(lines) or boundary_fail
	boundary_fail = _append_q4_ii8(lines) or boundary_fail
	_append_q1_note(lines)

	var text: String = "\n".join(lines) + "\n"
	print(text)
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		print("FP_HARNESS_FAIL: QTrackAudits could not write %s" % OUT_PATH)
		quit(1)
	f.store_string(text)
	if boundary_fail:
		print("FP_HARNESS_FAIL: QTrackAudits BOUNDARY_FAIL")
		quit(1)
	print("FP_HARNESS_OK: QTrackAudits")
	quit(0)


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
	var d001: PackedStringArray = _read_d001_lines()
	if d001.is_empty():
		lines.append("  BOUNDARY_FAIL missing .d001_soak_out.txt")
		lines.append("")
		return true
	var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(
		d001, _SoakPresets.PRESET_II2B_SWORD_DUEL
	)
	if not _TrackSpecs.d001_report_pass(d001, _SoakPresets.PRESET_II2B_SWORD_DUEL):
		lines.append("  BOUNDARY_FAIL [ii2b] pass=false in d001 report")
		lines.append("")
		return true
	var field: String = _TrackSpecs.d001_report_field_line(section, "parry_stats deflect=")
	var stats: Dictionary = (
		_TrackSpecs.parry_stats_from_summary_line(field) if not field.is_empty() else {}
	)
	if stats.is_empty():
		lines.append("  BOUNDARY_FAIL no parry_stats line in [ii2b] section")
		lines.append("")
		return true
	lines.append("  %s" % _TrackSpecs.parry_stats_summary_line(stats))
	var plaus: PackedStringArray = _TrackSpecs.ii2b_plausibility_failures(stats)
	if plaus.is_empty():
		lines.append("  ii2b_plausibility=pass (F5 timing feel still optional)")
	else:
		for msg in plaus:
			lines.append("  BOUNDARY_FAIL %s" % msg)
	lines.append("")
	return not plaus.is_empty()


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
	var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(
		d001, _SoakPresets.PRESET_II5_COWERING
	)
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
	var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(
		d001, _SoakPresets.PRESET_II4D_EXHAUSTION
	)
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
	var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(
		d001, _SoakPresets.PRESET_II8_FORMATION
	)
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


static func _append_q1_note(lines: PackedStringArray) -> void:
	lines.append("[Q1 research_feel]")
	lines.append("  run: .\\scripts\\run_q_audit.ps1 -Track Q1 (separate; verbose proxies)")
	lines.append("")
