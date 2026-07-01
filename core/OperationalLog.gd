class_name OperationalLog
extends RefCounted

## Stable stdout tags for grep  -  copy Godot **Output** after F5; search `FP_COMBAT` `FP_ERROR` `SCRIPT ERROR`.
## Headless harness also writes `.harness_out.txt` (long runs, no editor UI to copy from).

const TAG_ERROR := "FP_ERROR"
const TAG_WARN := "FP_WARN"
const TAG_HARNESS_BEGIN := "FP_HARNESS_BEGIN"
const TAG_HARNESS_OK := "FP_HARNESS_OK"
const TAG_HARNESS_FAIL := "FP_HARNESS_FAIL"
const TAG_HARNESS_SUMMARY := "FP_HARNESS_SUMMARY"
const TAG_SESSION_BEGIN := "FP_SESSION_BEGIN"
const TAG_SESSION_END := "FP_SESSION_END"
const TAG_COMBAT := "FP_COMBAT"
const TAG_WORLD := "FP_WORLD"

const HARNESS_REPORT_FILENAME := ".harness_out.txt"
const D001_SOAK_REPORT_FILENAME := ".d001_soak_out.txt"
const F5_SOAK_CAPTURE_FILENAME := ".f5_soak_in.txt"
const II2B_WORKSHEET_PREFILL_FILENAME := ".ii2b_worksheet_prefill.txt"
const D001_HEADLESS_SIGNOFF_FILENAME := ".d001_headless_signoff.txt"
const REPORT_BEGIN := "--- FP_HARNESS_REPORT ---"
const REPORT_END := "--- END FP_HARNESS_REPORT ---"

const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _FallenPathsErrorLogger := preload("res://core/FallenPathsErrorLogger.gd")

static var _play_session_active: bool = false
static var _play_session_scene: String = ""
static var _play_error_logger = null
static var _capture_enabled: bool = false
static var _captured_lines: PackedStringArray = PackedStringArray()
## Max captured lines before oldest are dropped (prevents unbounded growth in long campaigns).
const CAPTURE_MAX_LINES: int = 5000
## F5: suppress consecutive identical **`FP_COMBAT`** bodies (turn_ready double-fire, etc.).
static var _last_play_combat_body: String = ""


static func is_play_session_active() -> bool:
	return _play_session_active


## Editor F5 (`main.tscn`)  -  excludes headless D-001 capture sessions (`headless://...`).
static func play_session_is_editor_f5() -> bool:
	return _play_session_active and not _play_session_scene.begins_with("headless://")


## Between fights in one F5 session: allow the same line to log again (new encounter).
static func reset_fight_fp_channel_dedupe() -> void:
	_last_play_combat_body = ""
	CombatDebug.clear_flow_log_dedup()


static func tag_line(tag: String, message: String) -> String:
	return "%s: %s" % [tag, message.strip_edges()]


## Always prints tagged lines to stdout. Godot script/runtime faults are mirrored separately via **`FallenPathsErrorLogger`**.
static func set_capture_enabled(on: bool) -> void:
	_capture_enabled = on
	if not on:
		_captured_lines = PackedStringArray()


static func clear_capture() -> void:
	_captured_lines = PackedStringArray()


static func get_captured_lines() -> PackedStringArray:
	return _captured_lines.duplicate()


## Headless harness: register error logger once and reset SCRIPT_ERROR tally for the run.
static func ensure_harness_error_logger() -> void:
	if _play_error_logger == null:
		_play_error_logger = _FallenPathsErrorLogger.new()
		OS.add_logger(_play_error_logger)
	_FallenPathsErrorLogger.reset_script_error_count()


static func harness_script_error_count() -> int:
	return _FallenPathsErrorLogger.get_script_error_count()


## Replace the in-memory capture buffer (e.g. multi-rep D-001 duel lines merged after per-rep clears).
static func replace_capture(lines: PackedStringArray) -> void:
	_captured_lines = lines.duplicate()


static func emit(tag: String, message: String) -> void:
	var line: String = tag_line(tag, message)
	print(line)
	if _capture_enabled:
		_captured_lines.append(line)
		if _captured_lines.size() > CAPTURE_MAX_LINES:
			_captured_lines = _captured_lines.slice(_captured_lines.size() - CAPTURE_MAX_LINES)


## Harness-only summary output — uses bare `print()` (not `emit`) so it does not feed into the F5 capture buffer.
static func harness_summary(message: String) -> void:
	print(tag_line(TAG_HARNESS_SUMMARY, message))


static func error(message: String) -> void:
	emit(TAG_ERROR, message)


static func warn(message: String) -> void:
	emit(TAG_WARN, message)


static func play_combat(message: String) -> void:
	var body: String = message.strip_edges()
	if body.is_empty():
		return
	if _play_session_active and body == _last_play_combat_body:
		return
	if _play_session_active:
		_last_play_combat_body = body
	emit(TAG_COMBAT, body)
	if _play_session_active:
		CombatF5SoakTrace.ingest_trace_line(body)


static func play_world(message: String) -> void:
	var body: String = message.strip_edges()
	if body.is_empty():
		return
	emit(TAG_WORLD, body)
	if _play_session_active:
		CombatF5SoakTrace.ingest_world_trace_line(body)


## Call from `main.gd` when running under the editor (F5). Enables turn-pick flow logs; all lines go to Output for copy-paste.
static func begin_play_session(
	main_scene: String = CombatConstants.PATH_MAIN_SCENE,
	dev_soak_encounter: String = "",
	dev_research_feel: bool = false,
	dev_hit_summary: bool = true
) -> void:
	_play_session_active = true
	_play_session_scene = main_scene
	_last_play_combat_body = ""
	_CombatConstants.set_play_session_diagnostic(true)
	if not dev_hit_summary:
		_CombatConstants.set_combat_hit_summary_override(false)
	else:
		_CombatConstants.clear_combat_hit_summary_override()
	if _play_error_logger == null:
		_play_error_logger = _FallenPathsErrorLogger.new()
		OS.add_logger(_play_error_logger)
	var soak_s: String = dev_soak_encounter.strip_edges().to_lower()
	var soak_note: String = (
		" dev_soak=%s dev_research_feel=%s  -  grep soak_guide | soak_session_plan"
		% [soak_s, str(dev_research_feel).to_lower()]
		if not soak_s.is_empty()
		else (
			" dev_soak=(empty) dev_research_feel=%s  -  walk red 7v7 tile OR set dev_soak_encounter; grep soak_guide"
			% str(dev_research_feel).to_lower()
		)
	)
	emit(
		TAG_SESSION_BEGIN,
		(
			"%s flow_logs=%s hit_summary=%s per_hit_debug=%s research_feel=%s%s  -  copy full Output; grep hit_resolve reason= strike_avoided reason= diagram_banner player: engagement_debug opposition offset engagement_transition encounter_context parry_partial rem= hit_outcome_stats parry_stats soak_fight_end hit_coverage_hint FP_COMBAT FP_ERROR SCRIPT_ERROR"
			% [
				main_scene,
				_CombatConstants.combat_event_debug_active(),
				_CombatConstants.combat_hit_summary_active(),
				_CombatConstants.combat_debug_active(),
				str(dev_research_feel).to_lower(),
				soak_note,
			]
		)
	)


static func end_play_session() -> void:
	if not _play_session_active:
		return
	emit(TAG_SESSION_END, _play_session_scene)
	_play_session_active = false
	_play_session_scene = ""
	_last_play_combat_body = ""
	_CombatConstants.set_play_session_diagnostic(false)
	_CombatConstants.clear_combat_hit_summary_override()


static func play_combat_start(
	player_count: int,
	enemy_count: int,
	player_formation: Dictionary,
	enemy_formation: Dictionary,
	encounter: Dictionary
) -> void:
	play_combat(
		"encounter_begin players=%d enemies=%d | player_preset[%s] enemy_preset[%s] | encounter[%s]"
		% [
			player_count,
			enemy_count,
			_format_formation_preset(player_formation),
			_format_formation_preset(enemy_formation),
			_format_encounter(encounter),
		]
	)
	play_encounter_context(encounter)


## Contract/tutorial bleed and kind  -  grep **`encounter_context`** on F5 paste.
static func play_encounter_context(enc: Dictionary) -> void:
	if not _play_session_active or enc.is_empty():
		return
	var parts: PackedStringArray = PackedStringArray()
	if enc.get("tutorial", false):
		parts.append("kind=tutorial")
	var ctype: String = enc.get("contract_type", "").strip_edges()
	if not ctype.is_empty() and not enc.get("tutorial", false):
		parts.append("contract=%s" % ctype)
	if enc.has("map_bleed_mult"):
		parts.append("map_bleed_mult=%.2f" % enc.get("map_bleed_mult", 1.0))
	var title: String = enc.get("contract_title", "").strip_edges()
	if not title.is_empty():
		parts.append("title=%s" % title)
	if parts.is_empty():
		return
	play_combat("encounter_context %s" % " ".join(parts))


static func play_combat_manager_started(
	player_count: int,
	enemy_count: int,
	formation_doctrine: Dictionary,
	_encounter: Dictionary
) -> void:
	# Encounter blob is on the prior **`encounter_begin`** line  -  avoid repeating it here.
	play_combat(
		"manager_started combatants=%d/%d doctrine=%s"
		% [player_count, enemy_count, str(formation_doctrine)]
	)


static func _format_formation_preset(fd: Dictionary) -> String:
	if fd.is_empty():
		return "default"
	var doc: String = _CombatConstants.formation_doctrine_string_from_dict(
		fd,
		_CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		_CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	var doc_s: String = (" doctrine=%s" % doc) if not doc.is_empty() else ""
	var rout_parts: PackedStringArray = PackedStringArray()
	if fd.has(_CombatConstants.FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX):
		rout_parts.append(
			"flee_coh_max=%s" % str(fd.get(_CombatConstants.FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX))
		)
	if fd.has(_CombatConstants.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN):
		rout_parts.append(
			"flee_cas_min=%s" % str(fd.get(_CombatConstants.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN))
		)
	var rout_s: String = (" " + ", ".join(rout_parts)) if not rout_parts.is_empty() else ""
	return "files=%s ranks=%s density=%s%s%s" % [
		str(fd.get("files", "?")),
		str(fd.get("ranks", "?")),
		str(fd.get("density", "normal")),
		doc_s,
		rout_s,
	]


static func _format_encounter(enc: Dictionary) -> String:
	if enc.is_empty():
		return "defaults"
	var dp: String = _CombatConstants.encounter_formation_doctrine_string(
		enc,
		_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	var de: String = _CombatConstants.encounter_formation_doctrine_string(
		enc,
		_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY,
		_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT
	)
	var parts: PackedStringArray = PackedStringArray()
	if not dp.is_empty():
		parts.append("doc_player=%s" % dp)
	if not de.is_empty():
		parts.append("doc_enemy=%s" % de)
	var amb: String = enc.get("ambush_type", "").strip_edges()
	if not amb.is_empty() and amb != _CombatConstants.AMBUSH_TYPE_NONE:
		parts.append("ambush=%s" % amb)
	var ld: String = str(enc.get(_CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE, "")).strip_edges()
	if not ld.is_empty():
		parts.append("line_discipline=%s" % ld)
	var soak: String = enc.get("soak_preset_id", "").strip_edges()
	if not soak.is_empty():
		parts.append("soak=%s" % soak)
	for key in [
		_CombatConstants.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER,
		_CombatConstants.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY,
		_CombatConstants.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER,
		_CombatConstants.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY,
	]:
		if enc.has(key):
			parts.append("%s=%s" % [key, str(enc.get(key))])
	if parts.is_empty():
		return "defaults"
	return ", ".join(parts)


static func harness_begin(harness_name: String) -> void:
	emit(TAG_HARNESS_BEGIN, harness_name)


static func harness_ok(harness_name: String, detail: String = "") -> int:
	var msg: String = harness_name
	if not detail.is_empty():
		msg = "%s %s" % [harness_name, detail]
	emit(TAG_HARNESS_OK, msg)
	emit(TAG_HARNESS_SUMMARY, "%s OK" % harness_name)
	_write_harness_report(harness_name, true, PackedStringArray(), detail)
	return 0


static func harness_fail(harness_name: String, failures: PackedStringArray, detail: String = "") -> int:
	var n: int = failures.size()
	for i in n:
		emit(
			TAG_HARNESS_FAIL,
			"[%d/%d] %s" % [i + 1, n, failures[i]]
		)
	var summary: String = "%s FAIL failures=%d" % [harness_name, n]
	if not detail.is_empty():
		summary += " (%s)" % detail
	emit(TAG_HARNESS_SUMMARY, summary)
	_write_harness_report(harness_name, false, failures, detail)
	return 1


static func _project_root() -> String:
	return ProjectSettings.globalize_path("res://")


static func _harness_report_path() -> String:
	return _project_root().path_join(HARNESS_REPORT_FILENAME)


static func _write_text_file(path: String, body: String, append: bool) -> void:
	var f: FileAccess = null
	if append and FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(body)
	else:
		emit(TAG_WARN, "could not write log %s" % path)


static func _write_harness_report(
	harness_name: String,
	ok: bool,
	failures: PackedStringArray,
	detail: String
) -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(REPORT_BEGIN)
	lines.append("ok=%s" % str(ok).to_lower())
	lines.append("name=%s" % harness_name)
	if not detail.is_empty():
		lines.append("detail=%s" % detail)
	lines.append("failure_count=%d" % failures.size())
	lines.append("failures:")
	for failure_line in failures:
		lines.append("  - %s" % failure_line)
	lines.append(REPORT_END)
	var body: String = "\n".join(lines) + "\n"
	var path: String = _harness_report_path()
	_write_text_file(path, body, false)
	harness_summary("wrote %s" % path)


static func write_d001_soak_report(
	ok: bool,
	preset_results: Dictionary,
	failures: PackedStringArray
) -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("--- FP_D001_SOAK_REPORT ---")
	lines.append("ok=%s" % str(ok).to_lower())
	for preset_id in preset_results.keys():
		var pr: Dictionary = preset_results[preset_id] as Dictionary
		lines.append("")
		lines.append("[%s] pass=%s" % [preset_id, str(pr.get("ok", false)).to_lower()])
		var checks: Dictionary = pr.get("checks", {}) as Dictionary
		for check_id in checks.keys():
			var cr: Dictionary = checks[check_id] as Dictionary
			var optional: bool = cr.get("optional", false)
			var status: String = "PASS" if cr.get("pass", false) else "FAIL"
			if optional and not cr.get("pass", false):
				status = "OPTIONAL_MISS"
			lines.append(
				"  %s: %s (count=%d need>=%d%s)"
				% [
					check_id,
					status,
					cr.get("count", 0),
					cr.get("min", 1),
					" optional" if optional else "",
				]
			)
		if pr.has("notes"):
			lines.append("  notes: %s" % pr.get("notes", ""))
		for check_id in checks.keys():
			var cr_extra: Dictionary = checks[check_id] as Dictionary
			if cr_extra.has("label"):
				lines.append("    label[%s]: %s" % [check_id, cr_extra.get("label", "")])
		if pr.has("snapshot_label"):
			lines.append("  snapshot_label: %s" % pr.get("snapshot_label", ""))
		if pr.has("diagram_cell_label"):
			lines.append("  diagram_cell_label: %s" % pr.get("diagram_cell_label", ""))
		if pr.has("diagram_banner"):
			lines.append("  diagram_banner: %s" % pr.get("diagram_banner", ""))
		if pr.has("ii2b_plausibility_ok"):
			lines.append("  ii2b_plausibility: %s" % str(pr.get("ii2b_plausibility_ok", false)).to_lower())
		if pr.has("parry_stats"):
			var ps: Dictionary = pr.get("parry_stats", {}) as Dictionary
			lines.append(
				(
					"  parry_stats deflect=%d bind=%d partial=%d riposte=%d counter_tempo=%d flurry_opened=%d flurry=%d"
					% [
						ps.get("parry_deflect", 0),
						ps.get("parry_bind", 0),
						ps.get("parry_partial", 0),
						ps.get("riposte_chain", 0),
						ps.get("counter_tempo", 0),
						ps.get("flurry_bind_opened", 0),
						ps.get("flurry_bind", 0),
					]
				)
			)
		if pr.has("ii4d_plausibility_ok"):
			lines.append("  ii4d_plausibility: %s" % str(pr.get("ii4d_plausibility_ok", false)).to_lower())
		if pr.has("exhaustion_stats"):
			var es: Dictionary = pr.get("exhaustion_stats", {}) as Dictionary
			lines.append(
				"  exhaustion_stats crossed_25=%d crossed_50=%d crossed_75=%d exhaustion_log=%d"
					% [
						es.get("crossed_25", 0),
						es.get("crossed_50", 0),
						es.get("crossed_75", 0),
						es.get("exhaustion_log", 0),
					]
			)
	lines.append("")
	lines.append("failures:")
	for failure_line in failures:
		lines.append("  - %s" % failure_line)
	lines.append("")
	lines.append(
		"f5_log_validator: see .f5_soak_validation.txt (headless aggregate  -  same rules as F5 paste)"
	)
	lines.append("--- END FP_D001_SOAK_REPORT ---")
	var path: String = _project_root().path_join(D001_SOAK_REPORT_FILENAME)
	_write_text_file(path, "\n".join(lines) + "\n", false)
	harness_summary("wrote %s" % path)


## Markdown-friendly **II-2b** counts for **`.calibration_audit.txt`** / III-3 (not feel sign-off).
static func write_ii2b_worksheet_prefill(parry_stats: Dictionary, headless_signed: bool) -> void:
	var _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
	var body: String = _TrackSpecs.ii2b_worksheet_prefill_text(parry_stats, headless_signed)
	var path: String = _project_root().path_join(II2B_WORKSHEET_PREFILL_FILENAME)
	_write_text_file(path, body, false)
	harness_summary("wrote %s" % path)


static func write_d001_headless_signoff(
	run_ok: bool,
	preset_results: Dictionary,
	validator_ok: bool
) -> void:
	var _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
	var mandatory: PackedStringArray = _TrackSpecs.headless_mandatory_signoff_failures(preset_results)
	var signoff_ok: bool = run_ok and validator_ok and mandatory.is_empty()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("--- FP_D001_HEADLESS_SIGNOFF ---")
	lines.append("ok=%s" % str(signoff_ok).to_lower())
	lines.append("policy=headless_only")
	lines.append("validator_ok=%s" % str(validator_ok).to_lower())
	var _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
	for track_id in ["ii2b", "ii5a", "ii5b", "ii5c", "ii4d"]:
		var pr: Dictionary = {}
		if track_id == "ii4d":
			pr = preset_results.get(_SoakPresets.PRESET_II4D_EXHAUSTION, {}) as Dictionary
		else:
			pr = preset_results.get(track_id, {}) as Dictionary
		var passed: bool = pr.get("ok", false)
		if track_id == "ii2b":
			passed = passed and pr.get("ii2b_plausibility_ok", false)
		elif track_id == "ii4d":
			passed = passed and pr.get("ii4d_plausibility_ok", false)
		lines.append("[%s] pass=%s" % [track_id, str(passed).to_lower()])
	if not mandatory.is_empty():
		lines.append("mandatory_failures:")
		for msg in mandatory:
			lines.append("  - %s" % msg)
	lines.append("--- END FP_D001_HEADLESS_SIGNOFF ---")
	var path: String = _project_root().path_join(D001_HEADLESS_SIGNOFF_FILENAME)
	_write_text_file(path, "\n".join(lines) + "\n", false)
	harness_summary("wrote %s" % path)
	if signoff_ok:
		print(tag_line(TAG_HARNESS_OK, "D001HeadlessSignoff mandatory=ii2b+ii5a+ii5b+ii5c"))


## Headless D-001 aggregate in F5 paste shape  -  re-run **`validate_f5_soak_log.ps1`** without editor Output.
static func write_f5_soak_capture(combat_lines: PackedStringArray) -> void:
	var out: PackedStringArray = PackedStringArray()
	out.append(
		"%s: headless d001 capture (auto from CombatD001SoakRunner  -  validate with scripts/validate_f5_soak_log.ps1)"
		% TAG_SESSION_BEGIN
	)
	for raw in combat_lines:
		var s: String = str(raw).strip_edges()
		if s.is_empty():
			continue
		if s.begins_with(TAG_COMBAT + ":"):
			out.append(s)
		else:
			out.append("%s: %s" % [TAG_COMBAT, s])
	var path: String = _project_root().path_join(F5_SOAK_CAPTURE_FILENAME)
	_write_text_file(path, "\n".join(out) + "\n", false)
	harness_summary("wrote %s (%d combat lines)" % [path, combat_lines.size()])
