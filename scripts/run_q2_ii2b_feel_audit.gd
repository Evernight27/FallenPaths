extends SceneTree

## Track Q2 headless proxy: II-2b parry/bind/riposte plausibility vs **`.d001_soak_out.txt`** (no F5 editor).
## Writes **`.q2_ii2b_feel_audit.txt`** at repo root.

const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const OUT_PATH := "res://.q2_ii2b_feel_audit.txt"
const D001_PATH := "res://.d001_soak_out.txt"
const WORKSHEET_PATH := "res://.ii2b_worksheet_prefill.txt"


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== Q2 ii2b bind/riposte feel audit (headless proxy) ===")
	lines.append("")

	var boundary_fail: bool = false
	boundary_fail = _append_fixture_checks(lines) or boundary_fail
	boundary_fail = _append_d001_parry_audit(lines) or boundary_fail
	_append_worksheet_snapshot(lines)
	_append_f5_subjective_checklist(lines)

	var text: String = "\n".join(lines) + "\n"
	print(text)
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		print("FP_HARNESS_FAIL: Q2Ii2bFeelAudit could not write %s" % OUT_PATH)
		quit(1)
	f.store_string(text)
	if boundary_fail:
		print("FP_HARNESS_FAIL: Q2Ii2bFeelAudit BOUNDARY_FAIL")
		quit(1)
	print("FP_HARNESS_OK: Q2Ii2bFeelAudit")
	quit(0)


static func _append_fixture_checks(lines: PackedStringArray) -> bool:
	lines.append("[fixtures]")
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
		lines.append("  plausibility_gates=ok")
	else:
		for msg in failures:
			lines.append("  BOUNDARY_FAIL fixture: %s" % msg)
	lines.append("")
	return not failures.is_empty()


static func _append_d001_parry_audit(lines: PackedStringArray) -> bool:
	lines.append("[d001_ii2b]")
	if not FileAccess.file_exists(D001_PATH):
		lines.append("  BOUNDARY_FAIL missing .d001_soak_out.txt — run .\\scripts\\run_all_combat_checks.ps1 first")
		lines.append("")
		return true
	var all_lines: PackedStringArray = PackedStringArray()
	for part in FileAccess.get_file_as_string(D001_PATH).split("\n", false):
		all_lines.append(part)
	var section: PackedStringArray = _TrackSpecs.d001_report_section_lines(
		all_lines, _SoakPresets.PRESET_II2B_SWORD_DUEL
	)
	var field: String = _TrackSpecs.d001_report_field_line(section, "parry_stats deflect=")
	var stats: Dictionary = (
		_TrackSpecs.parry_stats_from_summary_line(field) if not field.is_empty() else {}
	)
	if stats.is_empty():
		lines.append("  BOUNDARY_FAIL no ii2b parry_stats in .d001_soak_out.txt")
		lines.append("")
		return true
	lines.append("  source=d001_report_[ii2b]")
	lines.append("  %s" % _TrackSpecs.parry_stats_summary_line(stats))
	var plaus: PackedStringArray = _TrackSpecs.ii2b_plausibility_failures(stats)
	if plaus.is_empty():
		lines.append("  ii2b_plausibility=pass")
	else:
		for msg in plaus:
			lines.append("  BOUNDARY_FAIL ii2b_plausibility: %s" % msg)
	lines.append("")
	return not plaus.is_empty()


static func _append_worksheet_snapshot(lines: PackedStringArray) -> void:
	lines.append("[worksheet]")
	if FileAccess.file_exists(WORKSHEET_PATH):
		var body: String = FileAccess.get_file_as_string(WORKSHEET_PATH).strip_edges()
		for part in body.split("\n", false):
			lines.append("  %s" % part)
	else:
		lines.append("  (missing .ii2b_worksheet_prefill.txt — written by D-001 harness after ii2b)")
	lines.append("")


static func _append_f5_subjective_checklist(lines: PackedStringArray) -> void:
	lines.append("[f5_subjective — human only]")
	lines.append("  main.tscn: dev_soak_encounter=ii2b (dev_research_feel optional)")
	lines.append("  play: deflect timing readable; riposte after deflect; flurry window after bind")
	lines.append("  grep: parry_deflect | parry_bind | riposte_chain | flurry_bind | parry_stats deflect=")
	lines.append("  helper: .\\scripts\\run_q_feel.ps1 -Track Q2 | .\\scripts\\run_q_audit.ps1 -Track Track")
	lines.append("")
