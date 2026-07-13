class_name SoakFpTraceFormatterTests
extends CombatRegressionHarnessCore
## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.


## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.
static func _run_swap_rank_resolve_completes_rank_swap(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_resolve_setup: expected player rank0/rank1 same file")
        _free_manager(mgr)
        return
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
        _fail(failures, "swap_resolve: expected swap_rank state on initiator")
        _free_manager(mgr)
        return
    _FormationFlow.handle_swap_rank_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    if _EntityAccess.rank_int(p0) != 1 or _EntityAccess.rank_int(p1) != 0:
        _fail(
            failures,
            (
                "swap_resolve: expected ranks swapped (p0=%d p1=%d)"
                % [_EntityAccess.rank_int(p0), _EntityAccess.rank_int(p1)]
            )
        )
    if (
        _EntityAccess.state_str(p0) != CombatConstants.STATE_WAITING
        or _EntityAccess.state_str(p1) != CombatConstants.STATE_WAITING
    ):
        _fail(
            failures,
            (
                "swap_resolve: both should return to waiting (got %s / %s)"
                % [_EntityAccess.state_str(p0), _EntityAccess.state_str(p1)]
            )
        )
    if p0.has("formation_move_partner_id") or p1.has("formation_move_partner_id"):
        _fail(failures, "swap_resolve: formation_move_partner_id should be cleared")
    _free_manager(mgr)


## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.

## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.

## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.


## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.
static func _run_negligible_hit_recovery_shorter_than_counted_hit(failures: PackedStringArray) -> void:
    var i: float = 0.55
    var t_hit: float = _CombatTiming.recovery_duration(i, "hit", 1.0, 1.0, 100, -1.0)
    var t_neg: float = _CombatTiming.recovery_duration(i, "negligible", 1.0, 1.0, 100, -1.0)
    if not (t_neg < t_hit):
        _fail(failures, "negligible_recovery: expected negligible < hit (hit=%.4f negligible=%.4f)" % [t_hit, t_neg])


## UI: `CombatLogFormatter` labels `outcome=negligible` distinctly from a counted hit.

## UI: `CombatLogFormatter` labels `outcome=negligible` distinctly from a counted hit.

## UI: `CombatLogFormatter` labels `outcome=negligible` distinctly from a counted hit.


## UI: `CombatLogFormatter` labels `outcome=negligible` distinctly from a counted hit.
static func _run_combat_log_formatter_negligible(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "Ally",
        "player",
        "Foe",
        "enemy",
        {
            "outcome": "negligible",
            "part": "head",
            "dmg": 0,
            "died": false,
            "total_physical": 0.2,
            "final_cut": 0.0,
            "final_blunt": 0.2,
            "health_before": 10,
            "health_after": 10
        }
    )
    if not line.contains("Graze") or not line.contains("rounds to 0"):
        _fail(failures, "combat_log_negligible: expected graze reason in line: %s" % line)
    var row_neg: String = _CombatLogFormatter.format_last_hit_on_target_row(
        {"outcome": "negligible", "part": "head", "total_physical": 0.2, "dmg": 0}
    )
    if not row_neg.begins_with("Graze:") or not row_neg.contains("rounds to 0"):
        _fail(failures, "combat_log_negligible_row: expected graze reason on row, got: %s" % row_neg)
    var line_deflect: String = _CombatLogFormatter.format_action_line(
        "Ally", "player", "Foe", "enemy", {"outcome": "deflected", "part": "chest", "dmg": 0, "total_physical": 0.0}
    )
    if not line_deflect.contains("Deflected") or not line_deflect.contains("armor stopped"):
        _fail(failures, "combat_log_deflected: expected armor reason, got: %s" % line_deflect)
    var note_glance: String = (
        _CombatLogFormatter
        . damage_resolve_note(
            {
                "outcome": "glancing",
                "final_cut": 0.1,
                "final_blunt": 0.0,
                "mechanical_post_armor": 2.0,
                "dmg": 0,
            }
        )
    )
    if not note_glance.contains("glancing"):
        _fail(failures, "damage_resolve_note glancing: %s" % note_glance)
    var row_hit: String = _CombatLogFormatter.format_last_hit_on_target_row(
        {"outcome": "hit", "part": "head", "total_physical": 5.0, "dmg": 5}
    )
    if not row_hit.begins_with("Hit:"):
        _fail(failures, "combat_log_hit_row: expected Hit prefix, got: %s" % row_hit)
    var row_parry: String = (
        _CombatLogFormatter
        . format_row_last_hit(
            {
                "outcome": "parry_partial",
                "parry_clash_context": {"remaining_ratio": 0.85, "parry_control": 0.12},
            }
        )
    )
    if not row_parry.contains("Partial parry"):
        _fail(failures, "combat_log_parry_row: expected Partial parry strip, got: %s" % row_parry)
    if _CombatLogFormatter.last_hit_row_combatant_id(3, 8, {"outcome": "parry_partial"}) != 3:
        _fail(failures, "last_hit_row_id: parry_partial want defender slot (first id)")
    if _CombatLogFormatter.last_hit_row_combatant_id(1, 2, {"outcome": "hit", "part": "head"}) != 2:
        _fail(failures, "last_hit_row_id: hit want defender slot (second id)")
    if _CombatLogFormatter.last_hit_row_combatant_id(5, -1, {"outcome": "bled_out", "died": true}) != 5:
        _fail(failures, "last_hit_row_id: bled_out want victim slot (first id)")
    if _CombatLogFormatter.format_row_last_hit({"outcome": "bled_out"}) != "Bled out":
        _fail(failures, "combat_log_bled_out_row: expected Bled out strip")
    if _CombatLogFormatter.action_resolved_victim_id(1, 2, {"outcome": "hit"}) != 2:
        _fail(failures, "action_resolved_victim_id: hit want target_id")
    if _CombatLogFormatter.action_resolved_victim_id(5, -1, {"outcome": "bled_out"}) != 5:
        _fail(failures, "action_resolved_victim_id: tick bleed want attacker_id when target=-1")
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
    if _CombatLogFormatter.format_row_last_hit({"outcome": "miss"}) != "Miss  -  attack missed (no contact)":
        _fail(failures, "combat_log_miss_row: expected Miss strip with reason")
    if (
        _CombatLogFormatter.format_row_last_hit({"outcome": "miss", "part": "left_arm"})
        != "Miss: L.Arm  -  attack missed (no contact)"
    ):
        _fail(failures, "combat_log_miss_row_part: expected part on avoid strip")
    if (
        _CombatLogFormatter.format_row_last_hit({"outcome": "dodge", "part": "head"})
        != "Dodged: Head  -  defender dodged"
    ):
        _fail(failures, "combat_log_dodge_row_part: expected part and reason on dodge strip")
    var line_focus: String = _CombatLogFormatter.format_action_line(
        "Ally", "player", "Ally", "player", {"outcome": "focus_line", "line": "high"}
    )
    if not line_focus.contains("shifts focus") or not line_focus.contains("High"):
        _fail(failures, "combat_log_focus_line: expected focus guard line, got: %s" % line_focus)
    if (
        _PartyRowFormatter.format_body_part_compact(
            "head", {"head": 29.8}, {"head": 0.0}, {"head": 30}, {"head": 0.0}, {}
        )
        != "Hd 29.8|0|0"
    ):
        _fail(failures, "body_part_compact: expected one-decimal chip display")


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
        _fail(failures, "ui_hint_fp_echo: want 1 FP ui_hint line got %d" % ui_count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)
    _free_harness_node(mgr)


static func _run_diagram_banner_fp_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var banner: String = "Formation line . Hold . cohesion 80%"
    _F5SoakTrace.log_diagram_banner_player(banner)
    _F5SoakTrace.log_diagram_banner_player(banner)
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: diagram_banner player:"):
            count += 1
    if count != 1:
        _fail(failures, "diagram_banner_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_fight_trace_buffer_preserves_session_counts(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.log_diagram_banner_player("Formation line . Hold . cohesion 50%")
    _F5SoakTrace.reset_fight_trace_buffer()
    _F5SoakTrace.log_fight_end_summary("player", false)
    var summary: String = ""
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: soak_fight_end "):
            summary = line
            break
    if summary.is_empty():
        _fail(failures, "fight_trace_reset: missing soak_fight_end line")
        return
    var parts: PackedStringArray = summary.split(" ")
    for part in parts:
        if part.begins_with("diagram_banner="):
            if int(part.substr("diagram_banner=".length())) < 1:
                _fail(
                    failures,
                    (
                        "fight_trace_reset: soak_fight_end should retain diagram_banner count after reset_fight_trace_b"
                        + "uffer (%s)" % part
                    )
                )
            return
    _fail(failures, "fight_trace_reset: soak_fight_end missing diagram_banner= field")
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
        _fail(failures, "turn_ready_formation_fp_dedupe: want 1 line got %d" % form_count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)
