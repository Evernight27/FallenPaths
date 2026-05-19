class_name OperationalLog
extends RefCounted

## Stable stdout tags for grep / Cursor — copy Godot **Output** after F5; search `FP_COMBAT` `FP_ERROR` `SCRIPT ERROR`.
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
const REPORT_BEGIN := "--- FP_HARNESS_REPORT ---"
const REPORT_END := "--- END FP_HARNESS_REPORT ---"

const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _FallenPathsErrorLogger := preload("res://core/FallenPathsErrorLogger.gd")

static var _play_session_active: bool = false
static var _play_session_scene: String = ""
static var _play_error_logger = null


static func is_play_session_active() -> bool:
	return _play_session_active


static func tag_line(tag: String, message: String) -> String:
	return "%s: %s" % [tag, message.strip_edges()]


## Always prints to stdout. Optionally mirrors to Godot's error/warning channel.
static func emit(tag: String, message: String, also_push: bool = false) -> void:
	var line: String = tag_line(tag, message)
	print(line)
	if not also_push:
		return
	if tag == TAG_WARN:
		push_warning(line)
	else:
		push_error(line)


static func error(message: String) -> void:
	emit(TAG_ERROR, message, true)


static func warn(message: String) -> void:
	emit(TAG_WARN, message, true)


static func play_combat(message: String) -> void:
	emit(TAG_COMBAT, message)


static func play_world(message: String) -> void:
	emit(TAG_WORLD, message)


## Call from `main.gd` when running under the editor (F5). Enables turn-pick flow logs; all lines go to Output for copy-paste.
static func begin_play_session(main_scene: String = "res://main.tscn") -> void:
	_play_session_active = true
	_play_session_scene = main_scene
	_CombatConstants.set_play_session_diagnostic(true)
	if _play_error_logger == null:
		_play_error_logger = _FallenPathsErrorLogger.new()
		OS.add_logger(_play_error_logger)
	emit(
		TAG_SESSION_BEGIN,
		(
			"%s flow_logs=%s per_hit_debug=%s — copy Output; grep FP_COMBAT FP_ERROR SCRIPT_ERROR (medical pressure/triage in FP_COMBAT; COMBAT_DEV_VERBOSE for armor traces)"
			% [
				main_scene,
				_CombatConstants.combat_event_debug_active(),
				_CombatConstants.combat_debug_active(),
			]
		)
	)


static func end_play_session() -> void:
	if not _play_session_active:
		return
	emit(TAG_SESSION_END, _play_session_scene)
	_play_session_active = false
	_play_session_scene = ""
	_CombatConstants.set_play_session_diagnostic(false)


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


static func play_combat_manager_started(
	player_count: int,
	enemy_count: int,
	formation_doctrine: Dictionary,
	encounter: Dictionary
) -> void:
	play_combat(
		"manager_started combatants=%d/%d doctrine=%s | %s"
		% [
			player_count,
			enemy_count,
			str(formation_doctrine),
			_format_encounter(encounter),
		]
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
	var amb: String = str(enc.get("ambush_type", "")).strip_edges()
	if not amb.is_empty() and amb != _CombatConstants.AMBUSH_TYPE_NONE:
		parts.append("ambush=%s" % amb)
	var ld: String = str(enc.get(_CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE, "")).strip_edges()
	if not ld.is_empty():
		parts.append("line_discipline=%s" % ld)
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
	print(tag_line(TAG_HARNESS_SUMMARY, "wrote %s" % path))
