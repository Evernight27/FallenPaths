class_name CombatRegressionHarnessFpDedupeTail
extends RefCounted

## FP (flow-probe) dedupe / operational-log tests split from CombatRegressionHarness (compile size).
## Tests: _OperationalLog dedup, _F5SoakTrace single-line guarantees, editor F5 vs headless gating.

const _MgrScript := preload("res://combat/CombatManager.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _Constants := preload("res://combat/CombatConstants.gd")


static func run(failures: PackedStringArray) -> void:
	_run_combat_ui_hint_fp_echo_dedupe(failures)
	_run_diagram_banner_fp_dedupe(failures)
	_run_fight_trace_buffer_preserves_session_counts(failures)
	_run_turn_ready_formation_fp_line_dedupe(failures)
	_run_turn_ready_gauge_fp_line_dedupe(failures)
	_run_manager_started_no_encounter_repeat(failures)
	_run_medical_action_pick_single_fp_line(failures)
	_run_engagement_transition_fp_dedupe(failures)
	_run_strike_avoided_fp_dedupe(failures)
	_run_combat_hit_summary_override_while_harness_quiet(failures)
	_run_medical_session_fp_dedupe(failures)
	_run_parry_fp_reason_suffix(failures)
	_run_combat_session_fp_dedupe(failures)
	_run_diagram_banner_enemy_fp(failures)
	_run_play_combat_fp_dedupe(failures)
	_run_formation_move_pick_fp_dedupe(failures)
	_run_soak_coverage_once_per_fight(failures)
	_run_medical_pressure_fp_suppressed_in_play(failures)
	_run_medical_phase_intro_once(failures)
	_run_ambient_pain_shock_fp_dedupe(failures)
	_run_editor_f5_skips_verbose_phase_end(failures)
	_run_fight_fp_channel_dedupe_resets_between_fights(failures)


static func _run_combat_ui_hint_fp_echo_dedupe(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	mgr.notify_combat_ui_hint("Listed formation moves: step_in", false)
	mgr.notify_combat_ui_hint("Arc overlap", true)
	var ui_count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if "ui_hint " in line:
			ui_count += 1
	if ui_count != 1:
		CombatRegressionHarness._fail(failures, "ui_hint_fp_echo: want 1 FP ui_hint line got %d" % ui_count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	CombatRegressionHarness._free_harness_node(mgr)


static func _run_diagram_banner_fp_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var banner: String = "Formation line \u00b7 Hold \u00b7 cohesion 80%"
	_F5SoakTrace.log_diagram_banner_player(banner)
	_F5SoakTrace.log_diagram_banner_player(banner)
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: diagram_banner player:"):
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "diagram_banner_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_fight_trace_buffer_preserves_session_counts(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.log_diagram_banner_player("Formation line \u00b7 Hold \u00b7 cohesion 50%")
	_F5SoakTrace.reset_fight_trace_buffer()
	_F5SoakTrace.log_fight_end_summary("player", false)
	var summary: String = ""
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: soak_fight_end "):
			summary = line
			break
	if summary.is_empty():
		CombatRegressionHarness._fail(failures, "fight_trace_reset: missing soak_fight_end line")
		return
	var parts: PackedStringArray = summary.split(" ")
	for part in parts:
		if part.begins_with("diagram_banner="):
			if int(part.substr("diagram_banner=".length())) < 1:
				CombatRegressionHarness._fail(
					failures,
					"fight_trace_reset: soak_fight_end should retain diagram_banner count after reset_fight_trace_buffer (%s)"
					% part
				)
			return
	CombatRegressionHarness._fail(failures, "fight_trace_reset: soak_fight_end missing diagram_banner= field")
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_turn_ready_formation_fp_line_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var fp: String = "Listed formation moves: wait"
	_F5SoakTrace._emit_turn_ready_formation_fp(1, "Leader", fp)
	_F5SoakTrace._emit_turn_ready_formation_fp(1, "Leader", fp)
	var form_count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: turn_ready_formation_line "):
			form_count += 1
	if form_count != 1:
		CombatRegressionHarness._fail(failures, "turn_ready_formation_fp_dedupe: want 1 line got %d" % form_count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_turn_ready_gauge_fp_line_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var mgr: Node = _MgrScript.new()
	var leader: Dictionary = {
		"id": 1,
		"side": "player",
		"state": _Constants.STATE_WAITING,
		"gauge": 100.0,
		"rank": 0,
	}
	_F5SoakTrace.log_turn_ready_player_ui(mgr, leader, [])
	_F5SoakTrace.log_turn_ready_player_ui(mgr, leader, [])
	var gauge_count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: turn_ready_gauge "):
			gauge_count += 1
	if gauge_count != 1:
		CombatRegressionHarness._fail(failures, "turn_ready_gauge_fp_dedupe: want 1 line got %d" % gauge_count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	CombatRegressionHarness._free_harness_node(mgr)


static func _run_manager_started_no_encounter_repeat(failures: PackedStringArray) -> void:
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_OperationalLog.play_combat_manager_started(2, 3, {"player": "default"}, {"soak": "ii2b"})
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: manager_started ") and "| encounter[" in line:
			CombatRegressionHarness._fail(failures, "manager_started: should not repeat encounter blob (got %s)" % line)
			break
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_medical_action_pick_single_fp_line(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.note_medical_action_pick("Medic", "apply_direct_pressure", "chest", "ally")
	var pick_count: int = 0
	var legacy_count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: medical_action pick "):
			pick_count += 1
		if line.begins_with("FP_COMBAT: action ") and " chose medical " in line:
			legacy_count += 1
	if pick_count != 1:
		CombatRegressionHarness._fail(failures, "medical_action_pick: want 1 medical_action pick line got %d" % pick_count)
	if legacy_count != 0:
		CombatRegressionHarness._fail(failures, "medical_action_pick: want 0 legacy action chose medical lines got %d" % legacy_count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_engagement_transition_fp_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.note_engagement_transition("Duel", "Formation line")
	_F5SoakTrace.note_engagement_transition("Duel", "Formation line")
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: engagement_transition "):
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "engagement_transition_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_strike_avoided_fp_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	var was_quiet: bool = _Constants.is_headless_harness_quiet()
	_Constants.set_headless_harness_quiet(false)
	_Constants.set_combat_hit_summary_override(true)
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var atk: Dictionary = {"id": 1, "side": "player", "name": "A"}
	var tgt: Dictionary = {"id": 2, "side": "enemy", "name": "D"}
	_F5SoakTrace.note_strike_avoided(1, 2, atk, tgt, "miss", "head")
	_F5SoakTrace.note_strike_avoided(1, 2, atk, tgt, "miss", "head")
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: strike_avoided "):
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "strike_avoided_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	_Constants.clear_combat_hit_summary_override()
	_Constants.set_headless_harness_quiet(was_quiet)


static func _run_combat_hit_summary_override_while_harness_quiet(failures: PackedStringArray) -> void:
	var was_quiet: bool = _Constants.is_headless_harness_quiet()
	_Constants.set_headless_harness_quiet(true)
	_Constants.set_combat_hit_summary_override(true)
	if not _Constants.combat_hit_summary_active():
		CombatRegressionHarness._fail(
			failures,
			"hit_summary_override: want active under harness quiet (D-001 soak_fight_end hit_resolve)"
		)
	_Constants.set_combat_hit_summary_override(false)
	if _Constants.combat_hit_summary_active():
		CombatRegressionHarness._fail(failures, "hit_summary_override: explicit off should lose to harness quiet")
	_Constants.clear_combat_hit_summary_override()
	_Constants.set_headless_harness_quiet(was_quiet)


static func _run_medical_session_fp_dedupe(failures: PackedStringArray) -> void:
	_CombatDebug.clear_flow_log_dedup()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var body: String = "Medic apply_bandage(chest) => success, 1 wound(s) stabilized"
	_CombatDebug.medical_session(body)
	_CombatDebug.medical_session(body)
	var want: String = "FP_COMBAT: medical %s" % body
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line == want:
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "medical_session_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_parry_fp_reason_suffix(failures: PackedStringArray) -> void:
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var atk: Dictionary = {"id": 1, "side": "enemy", "name": "A"}
	var tgt: Dictionary = {"id": 2, "side": "player", "name": "D"}
	_AttackResultApplier._log_fp_parry_outcome(atk, tgt, 1, 2, "parry_partial", {"parry_control": 0.5, "remaining_ratio": 0.2})
	var found: bool = false
	for line in _OperationalLog.get_captured_lines():
		if line.contains("parry_partial") and line.contains("reason="):
			found = true
			break
	if not found:
		CombatRegressionHarness._fail(failures, "parry_fp_reason: expected parry_partial line with reason=")
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_combat_session_fp_dedupe(failures: PackedStringArray) -> void:
	_CombatDebug.clear_flow_log_dedup()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_CombatDebug.combat_session("exhaustion Ally crossed 50% (index 52% perf 90%)")
	_CombatDebug.combat_session("exhaustion Ally crossed 50% (index 52% perf 90%)")
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.contains("exhaustion Ally crossed 50%"):
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "combat_session_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_diagram_banner_enemy_fp(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.log_diagram_banner_enemy("Skirmish \u00b7 Loose \u00b7 cohesion 40%")
	_F5SoakTrace.log_diagram_banner_enemy("Skirmish \u00b7 Loose \u00b7 cohesion 40%")
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: diagram_banner enemy:"):
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "diagram_banner_enemy_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_play_combat_fp_dedupe(failures: PackedStringArray) -> void:
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var body: String = "cowering_fall_back listed for Leader"
	_OperationalLog.play_combat(body)
	_OperationalLog.play_combat(body)
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line == "FP_COMBAT: %s" % body:
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "play_combat_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_formation_move_pick_fp_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.note_formation_move_pick("rotate_file", 1, 2)
	_F5SoakTrace.note_formation_move_pick("rotate_file", 1, 2)
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line == "FP_COMBAT: rotate_file@2":
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "formation_move_pick_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_soak_coverage_once_per_fight(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.log_fight_end_summary("player", false)
	_F5SoakTrace.log_fight_end_summary("player", false)
	var count: int = 0
	var validate_n: int = 0
	var soak_end_n: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: soak_coverage ok="):
			count += 1
		if line.begins_with("FP_COMBAT: soak_validate_hint "):
			validate_n += 1
		if line.begins_with("FP_COMBAT: soak_fight_end "):
			soak_end_n += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "soak_coverage_once: want 1 soak_coverage header got %d" % count)
	if validate_n != 1:
		CombatRegressionHarness._fail(failures, "soak_validate_hint_once: want 1 line got %d" % validate_n)
	if soak_end_n != 1:
		CombatRegressionHarness._fail(failures, "soak_fight_end_once: want 1 line got %d" % soak_end_n)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_medical_pressure_fp_suppressed_in_play(failures: PackedStringArray) -> void:
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_EntityMedical.log_medical_session("Ally direct_pressure self part=chest (TCCC)")
	_EntityMedical.log_medical_session("Ally apply_bandage(chest) => success, 1 wound(s) stabilized")
	var pressure_n: int = 0
	var bandage_n: int = 0
	for line in _OperationalLog.get_captured_lines():
		if "direct_pressure self" in line:
			pressure_n += 1
		if "apply_bandage" in line:
			bandage_n += 1
	if pressure_n != 0:
		CombatRegressionHarness._fail(failures, "medical_pressure_fp: want 0 pressure lines got %d" % pressure_n)
	if bandage_n != 1:
		CombatRegressionHarness._fail(failures, "medical_pressure_fp: want 1 bandage line got %d" % bandage_n)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_medical_phase_intro_once(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.note_medical_phase_intro()
	_F5SoakTrace.note_medical_phase_intro()
	var count: int = 0
	var double_medical: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: medical_phase: full hemorrhage"):
			count += 1
		if "medical medical_phase:" in line:
			double_medical += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "medical_phase_intro_once: want 1 intro line got %d" % count)
	if double_medical != 0:
		CombatRegressionHarness._fail(failures, "medical_phase_intro_prefix: forbid medical medical_phase: got %d" % double_medical)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_ambient_pain_shock_fp_dedupe(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	_F5SoakTrace.note_ambient_pain_shock("Companion", 42.0, 3.5)
	_F5SoakTrace.note_ambient_pain_shock("Companion", 42.0, 3.5)
	var count: int = 0
	for line in _OperationalLog.get_captured_lines():
		if line.begins_with("FP_COMBAT: ambient_pain_shock "):
			count += 1
	if count != 1:
		CombatRegressionHarness._fail(failures, "ambient_pain_shock_dedupe: want 1 line got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_editor_f5_skips_verbose_phase_end(failures: PackedStringArray) -> void:
	const PHASE_STUB: String = (
		"phase_end winner=player defeated_node=null alive_by_side={} standing_by_side={} fled_by_side={}"
	)
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("res://main.tscn", "", false, true)
	if not _OperationalLog.play_session_is_editor_f5():
		CombatRegressionHarness._fail(failures, "editor_f5_detect: main.tscn session should be editor F5")
	if not _OperationalLog.play_session_is_editor_f5():
		_CombatDebug.combat_session(PHASE_STUB)
	_F5SoakTrace.log_fight_end_summary("player", true)
	var phase_n: int = 0
	var soak_end_n: int = 0
	for line in _OperationalLog.get_captured_lines():
		if "phase_end winner=" in line:
			phase_n += 1
		if line.begins_with("FP_COMBAT: soak_fight_end "):
			soak_end_n += 1
	if phase_n != 0:
		CombatRegressionHarness._fail(failures, "editor_f5_phase_end: want 0 phase_end got %d" % phase_n)
	if soak_end_n != 1:
		CombatRegressionHarness._fail(failures, "editor_f5_soak_fight_end: want 1 got %d" % soak_end_n)
	_OperationalLog.end_play_session()
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("headless://d001-soak", "", false, true)
	if _OperationalLog.play_session_is_editor_f5():
		CombatRegressionHarness._fail(failures, "editor_f5_detect: headless session must not be editor F5")
	if not _OperationalLog.play_session_is_editor_f5():
		_CombatDebug.combat_session(PHASE_STUB)
	phase_n = 0
	for line in _OperationalLog.get_captured_lines():
		if "phase_end winner=" in line:
			phase_n += 1
	if phase_n != 1:
		CombatRegressionHarness._fail(failures, "headless_phase_end: want 1 phase_end got %d" % phase_n)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)


static func _run_fight_fp_channel_dedupe_resets_between_fights(failures: PackedStringArray) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("test", "", false, true)
	var line: String = "turn_ready_gauge id=0 Tester label=Ready tooltip_match=ok"
	_OperationalLog.play_combat(line)
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.play_combat(line)
	var count: int = 0
	for cap in _OperationalLog.get_captured_lines():
		if cap == "FP_COMBAT: %s" % line:
			count += 1
	if count != 2:
		CombatRegressionHarness._fail(failures, "fight_fp_channel_reset: want 2 identical lines across fights got %d" % count)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
