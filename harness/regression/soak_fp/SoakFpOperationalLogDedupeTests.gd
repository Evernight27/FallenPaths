class_name SoakFpOperationalLogDedupeTests
extends CombatRegressionHarnessCore


static func _run_turn_ready_gauge_fp_line_dedupe(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    var mgr: Node = MgrScript.new()
    var leader: Dictionary = {
        "id": 1,
        "side": "player",
        "state": CombatConstants.STATE_WAITING,
        "gauge": 100.0,
        "rank": 0,
    }
    F5SoakTrace.log_turn_ready_player_ui(mgr, leader, [])
    F5SoakTrace.log_turn_ready_player_ui(mgr, leader, [])
    var gauge_count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: turn_ready_gauge "):
            gauge_count += 1
    if gauge_count != 1:
        _fail(failures, "turn_ready_gauge_fp_dedupe: want 1 line got %d" % gauge_count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)
    _free_harness_node(mgr)


static func _run_manager_started_no_encounter_repeat(failures: PackedStringArray) -> void:
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    OperationalLog.play_combat_manager_started(2, 3, {"player": "default"}, {"soak": "ii2b"})
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: manager_started ") and "| encounter[" in line:
            _fail(failures, "manager_started: should not repeat encounter blob (got %s)" % line)
            break
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_medical_action_pick_single_fp_line(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.note_medical_action_pick("Medic", "apply_direct_pressure", "chest", "ally")
    var pick_count: int = 0
    var fp_count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: medical_action pick "):
            pick_count += 1
        if line.begins_with("FP_COMBAT: action ") and " chose medical " in line:
            fp_count += 1
    if pick_count != 1:
        _fail(failures, "medical_action_pick: want 1 medical_action pick line got %d" % pick_count)
    if fp_count != 0:
        _fail(failures, "medical_action_pick: want 0 FP action chose medical lines got %d" % fp_count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_engagement_transition_fp_dedupe(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.note_engagement_transition("Duel", "Formation line")
    F5SoakTrace.note_engagement_transition("Duel", "Formation line")
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: engagement_transition "):
            count += 1
    if count != 1:
        _fail(failures, "engagement_transition_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_strike_avoided_fp_dedupe(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    CombatConstants.set_combat_hit_summary_override(true)
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    var atk: Dictionary = {"id": 1, "side": "player", "name": "A"}
    var tgt: Dictionary = {"id": 2, "side": "enemy", "name": "D"}
    F5SoakTrace.note_strike_avoided(1, 2, atk, tgt, "miss", "head")
    F5SoakTrace.note_strike_avoided(1, 2, atk, tgt, "miss", "head")
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: strike_avoided "):
            count += 1
    if count != 1:
        _fail(failures, "strike_avoided_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)
    CombatConstants.clear_combat_hit_summary_override()
    CombatConstants.set_headless_harness_quiet(was_quiet)


static func _run_combat_hit_summary_override_while_harness_quiet(failures: PackedStringArray) -> void:
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(true)
    CombatConstants.set_combat_hit_summary_override(true)
    if not CombatConstants.combat_hit_summary_active():
        _fail(failures, "hit_summary_override: want active under harness quiet (D-001 soak_fight_end hit_resolve)")
    CombatConstants.set_combat_hit_summary_override(false)
    if CombatConstants.combat_hit_summary_active():
        _fail(failures, "hit_summary_override: explicit off should lose to harness quiet")
    CombatConstants.clear_combat_hit_summary_override()
    CombatConstants.set_headless_harness_quiet(was_quiet)


static func _run_medical_session_fp_dedupe(failures: PackedStringArray) -> void:
    CombatDebug.clear_flow_log_dedup()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    var body: String = "Medic _apply_bandage(chest) => success, 1 wound(s) stabilized"
    CombatDebug.medical_session(body)
    CombatDebug.medical_session(body)
    var want: String = "FP_COMBAT: medical %s" % body
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line == want:
            count += 1
    if count != 1:
        _fail(failures, "medical_session_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_parry_fp_reason_suffix(failures: PackedStringArray) -> void:
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    var atk: Dictionary = {"id": 1, "side": "enemy", "name": "A"}
    var tgt: Dictionary = {"id": 2, "side": "player", "name": "D"}
    AttackResultApplier._log_fp_parry_outcome(
        atk, tgt, 1, 2, "parry_partial", {"parry_control": 0.5, "remaining_ratio": 0.2}
    )
    var found: bool = false
    for line in OperationalLog.get_captured_lines():
        if line.contains("parry_partial") and line.contains("reason="):
            found = true
            break
    if not found:
        _fail(failures, "parry_fp_reason: expected parry_partial line with reason=")
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_combat_session_fp_dedupe(failures: PackedStringArray) -> void:
    CombatDebug.clear_flow_log_dedup()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    CombatDebug.combat_session("exhaustion Ally crossed 50% (index 52% perf 90%)")
    CombatDebug.combat_session("exhaustion Ally crossed 50% (index 52% perf 90%)")
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.contains("exhaustion Ally crossed 50%"):
            count += 1
    if count != 1:
        _fail(failures, "combat_session_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_diagram_banner_enemy_fp(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.log_diagram_banner_enemy("Skirmish . Loose . cohesion 40%")
    F5SoakTrace.log_diagram_banner_enemy("Skirmish . Loose . cohesion 40%")
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: diagram_banner enemy:"):
            count += 1
    if count != 1:
        _fail(failures, "diagram_banner_enemy_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_play_combat_fp_dedupe(failures: PackedStringArray) -> void:
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    var body: String = "cowering_fall_back listed for Leader"
    OperationalLog.play_combat(body)
    OperationalLog.play_combat(body)
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line == "FP_COMBAT: %s" % body:
            count += 1
    if count != 1:
        _fail(failures, "play_combat_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_formation_move_pick_fp_dedupe(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.note_formation_move_pick("rotate_file", 1, 2)
    F5SoakTrace.note_formation_move_pick("rotate_file", 1, 2)
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line == "FP_COMBAT: rotate_file@2":
            count += 1
    if count != 1:
        _fail(failures, "formation_move_pick_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_soak_coverage_once_per_fight(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.log_fight_end_summary("player", false)
    F5SoakTrace.log_fight_end_summary("player", false)
    var count: int = 0
    var validate_n: int = 0
    var soak_end_n: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: soak_coverage ok="):
            count += 1
        if line.begins_with("FP_COMBAT: soak_validate_hint "):
            validate_n += 1
        if line.begins_with("FP_COMBAT: soak_fight_end "):
            soak_end_n += 1
    if count != 1:
        _fail(failures, "soak_coverage_once: want 1 soak_coverage header got %d" % count)
    if validate_n != 1:
        _fail(failures, "soak_validate_hint_once: want 1 line got %d" % validate_n)
    if soak_end_n != 1:
        _fail(failures, "soak_fight_end_once: want 1 line got %d" % soak_end_n)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_medical_pressure_fp_suppressed_in_play(failures: PackedStringArray) -> void:
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    EntityMedical.log_medical_session("Ally direct_pressure self part=chest (TCCC)")
    EntityMedical.log_medical_session("Ally _apply_bandage(chest) => success, 1 wound(s) stabilized")
    var pressure_n: int = 0
    var bandage_n: int = 0
    for line in OperationalLog.get_captured_lines():
        if "direct_pressure self" in line:
            pressure_n += 1
        if "apply_bandage" in line:
            bandage_n += 1
    if pressure_n != 0:
        _fail(failures, "medical_pressure_fp: want 0 pressure lines got %d" % pressure_n)
    if bandage_n != 1:
        _fail(failures, "medical_pressure_fp: want 1 bandage line got %d" % bandage_n)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_medical_phase_intro_once(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.note_medical_phase_intro()
    F5SoakTrace.note_medical_phase_intro()
    var count: int = 0
    var double_medical: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: medical_phase: full hemorrhage"):
            count += 1
        if "medical medical_phase:" in line:
            double_medical += 1
    if count != 1:
        _fail(failures, "medical_phase_intro_once: want 1 intro line got %d" % count)
    if double_medical != 0:
        _fail(failures, "medical_phase_intro_prefix: forbid medical medical_phase: got %d" % double_medical)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_ambient_pain_shock_fp_dedupe(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    F5SoakTrace.note_ambient_pain_shock("Companion", 42.0, 3.5)
    F5SoakTrace.note_ambient_pain_shock("Companion", 42.0, 3.5)
    var count: int = 0
    for line in OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: ambient_pain_shock "):
            count += 1
    if count != 1:
        _fail(failures, "ambient_pain_shock_dedupe: want 1 line got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_editor_f5_skips_verbose_phase_end(failures: PackedStringArray) -> void:
    var phase_stub: String = "phase_end winner=player defeated_node=null alive_by_side={} standing_by_side={} fled_by_s"
    "ide={}"
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("res://scenes/campaign/main.tscn", "", false, true)
    if not OperationalLog.play_session_is_editor_f5():
        _fail(failures, "editor_f5_detect: scenes/campaign/main.tscn session should be editor F5")
    # Mirror CombatManager.finish_battle gate (editor F5 uses soak_fight_end, not phase_end).
    if not OperationalLog.play_session_is_editor_f5():
        CombatDebug.combat_session(phase_stub)
    F5SoakTrace.log_fight_end_summary("player", true)
    var phase_n: int = 0
    var soak_end_n: int = 0
    for line in OperationalLog.get_captured_lines():
        if "phase_end winner=" in line:
            phase_n += 1
        if line.begins_with("FP_COMBAT: soak_fight_end "):
            soak_end_n += 1
    if phase_n != 0:
        _fail(failures, "editor_f5_phase_end: want 0 phase_end got %d" % phase_n)
    if soak_end_n != 1:
        _fail(failures, "editor_f5_soak_fight_end: want 1 got %d" % soak_end_n)
    OperationalLog.end_play_session()
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("headless://d001-soak", "", false, true)
    if OperationalLog.play_session_is_editor_f5():
        _fail(failures, "editor_f5_detect: headless session must not be editor F5")
    if not OperationalLog.play_session_is_editor_f5():
        CombatDebug.combat_session(phase_stub)
    phase_n = 0
    for line in OperationalLog.get_captured_lines():
        if "phase_end winner=" in line:
            phase_n += 1
    if phase_n != 1:
        _fail(failures, "headless_phase_end: want 1 phase_end got %d" % phase_n)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _run_fight_fp_channel_dedupe_resets_between_fights(failures: PackedStringArray) -> void:
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    var line: String = "turn_ready_gauge id=0 Tester label=Ready tooltip_match=ok"
    OperationalLog.play_combat(line)
    F5SoakTrace.prepare_fight_end_log()
    OperationalLog.play_combat(line)
    var count: int = 0
    for cap in OperationalLog.get_captured_lines():
        if cap == "FP_COMBAT: %s" % line:
            count += 1
    if count != 2:
        _fail(failures, "fight_fp_channel_reset: want 2 identical lines across fights got %d" % count)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)


static func _assert_depth_polearm_allows_low_fid_round_trip_slice(
    mgr: Node, failures: PackedStringArray, ctx: String
) -> void:
    Fixtures._assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, ctx)


static func _assert_stamp_depth_pa_defaults(pa: Dictionary, failures: PackedStringArray, ctx: String) -> void:
    Fixtures._assert_stamp_depth_pa_defaults(pa, failures, ctx)


static func _assert_depth_lane_open_cache_matches_builder(mgr: Node, failures: PackedStringArray, ctx: String) -> void:
    Fixtures._assert_depth_lane_open_cache_matches_builder(mgr, failures, ctx)


## Tier 3.1: pack / protection-circle parry flank uses wedge/lane-aware effective file spacing (falls back to
## |-file|>=2).
## Tier 3.1: sector surround `1/(1+k.excess)` matches integer **`surround_defense_multiplier`** when total weight = 2
## (two full-width flank threats).


## Tier 3.1: pack / protection-circle parry flank uses wedge/lane-aware effective file spacing (falls back to
## |-file|>=2).
## Tier 3.1: sector surround `1/(1+k.excess)` matches integer **`surround_defense_multiplier`** when total weight = 2
## (two full-width flank threats).
static func _run_strike_measure_constants_sanity(failures: PackedStringArray) -> void:
    var w: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if w == null:
        _fail(failures, "strike_meas_const: missing SWORD weapon")
        return
    var eff_in: float = 1.0
    var got: float = StrikeStamping.strike_measure_ratio_for_weapon_eff_dist(w, eff_in)
    var eff: float = maxf(eff_in, CombatConstants.STRIKE_MEASURE_EFF_DIST_FLOOR)
    var melee: float = w.melee_range
    var want: float = clampf(
        melee / eff, CombatConstants.STRIKE_MEASURE_RATIO_MIN, CombatConstants.STRIKE_MEASURE_RATIO_MAX
    )
    if not is_equal_approx(got, want):
        _fail(failures, "strike_meas_const: got %.4f want %.4f (melee=%.3f eff_floor=%.3f)" % [got, want, melee, eff])


## Tier 1.3: **`effective_pair_geometry`** returns **`eff_dist`** / **`file_spacing_equiv`** matching wrapper helpers
## (one ZoC read).


## Tier 1.3: **`effective_pair_geometry`** returns **`eff_dist`** / **`file_spacing_equiv`** matching wrapper helpers
## (one ZoC read).
static func _run_effective_pair_geometry_single_pass_matches_wrappers(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "loose"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var a: Dictionary = mgr.combatants[0]
    var b: Dictionary = mgr.combatants[2]
    var geom: Dictionary = PairGeometry.effective_pair_geometry(mgr, a, b)
    var eff_wrap: float = PairGeometry.cached_eff_dist(geom)
    var space_wrap: float = float(geom.get("file_spacing_equiv", 0.0))
    _free_manager(mgr)
    if not geom.has("eff_dist") or not geom.has("file_spacing_equiv"):
        _fail(failures, "pair_geom: result dict missing eff_dist or file_spacing_equiv")
        return
    if not is_equal_approx(float(geom["eff_dist"]), eff_wrap):
        _fail(failures, "pair_geom: eff_dist %.4f vs wrapper %.4f" % [float(geom["eff_dist"]), eff_wrap])
    if not is_equal_approx(float(geom["file_spacing_equiv"]), space_wrap):
        _fail(
            failures,
            "pair_geom: file_spacing_equiv %.4f vs wrapper %.4f" % [float(geom["file_spacing_equiv"]), space_wrap]
        )


## Tier 3.1: `CombatStrikeStamping.stamp_attack_pair_geometry_on_dict` via wind-up (re-stamped each resolve).
## Covers rank-0, depth 1-file line, and depth vs 3-wide enemy frontage (stamp vs live builder).


## Tier 3.1: `CombatStrikeStamping.stamp_attack_pair_geometry_on_dict` via wind-up (re-stamped each resolve).
## Covers rank-0, depth 1-file line, and depth vs 3-wide enemy frontage (stamp vs live builder).
static func _run_windup_pending_attack_pair_geometry(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p0_id: int = EntityAccess.id_int(mgr.combatants[0])
    var e0_id: int = EntityAccess.id_int(mgr.combatants[1])
    WindUpStarter.start(mgr, p0_id, e0_id, "thrust")
    var comb_pa0: Variant = mgr._get_by_id(p0_id)
    var pa0: Dictionary = EntityAccess.nested_dictionary_read(
        comb_pa0 if comb_pa0 is Dictionary else {}, "pending_attack"
    )
    if pa0.is_empty():
        _fail(failures, "windup_geom: empty pending_attack (rank0)")
    else:
        if not pa0.has("effective_pair_file_spacing_equivalent") or not pa0.has("effective_pair_eff_dist"):
            _fail(failures, "windup_geom: rank0 missing spacing keys")
        var p0: Dictionary = mgr.combatants[0]
        var e0: Dictionary = mgr.combatants[1]
        var want_eff0: float = PairGeometry.effective_pair_eff_dist(mgr, p0, e0)
        var want_space0: float = PairGeometry.effective_pair_file_spacing_equivalent(mgr, p0, e0)
        if not is_equal_approx(float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0):
            _fail(
                failures,
                (
                    "windup_geom: rank0 eff_dist stamp %.4f vs builder %.4f"
                    % [float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0]
                )
            )
        if not is_equal_approx(float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0):
            _fail(
                failures,
                (
                    "windup_geom: rank0 file_spacing_eq stamp %.4f vs builder %.4f"
                    % [float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0]
                )
            )
        var w0: Variant = EntityAccess.get_weapon(p0)
        if w0 != null:
            var want_meas0: float = StrikeStamping.strike_measure_ratio_for_attack_pair(mgr, p0, e0, w0, want_eff0)
            if not is_equal_approx(float(pa0.get("strike_measure_ratio", -9.0)), want_meas0):
                _fail(
                    failures,
                    (
                        "windup_geom: rank0 strike_measure_ratio %.4f vs eff-keyed measure %.4f"
                        % [float(pa0.get("strike_measure_ratio", -9.0)), want_meas0]
                    )
                )
        if bool(pa0.get("depth_polearm_attack", true)):
            _fail(failures, "windup_geom: rank0 must not set depth_polearm_attack")
        if str(pa0.get("depth_polearm_lane_type", "")) != "":
            _fail(failures, "windup_geom: rank0 must not set depth_polearm_lane_type")
    _free_manager(mgr)

    var mgr2: Node = MgrScript.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SPEAR"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 2, "density": "loose"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr2.call("recompute_zoc_and_distance")
    var depth: Dictionary = mgr2.combatants[1]
    var en: Dictionary = mgr2.combatants[2]
    if not DepthPolearm.depth_polearm_lane_open(mgr2, depth):
        _fail(failures, "windup_geom: expected depth polearm lane open")
    else:
        var d_id: int = EntityAccess.id_int(depth)
        var en_id: int = EntityAccess.id_int(en)
        WindUpStarter.start(mgr2, d_id, en_id, "spear_thrust")
        var comb_pa1: Variant = mgr2._get_by_id(d_id)
        var pa1: Dictionary = EntityAccess.nested_dictionary_read(
            comb_pa1 if comb_pa1 is Dictionary else {}, "pending_attack"
        )
        if pa1.is_empty():
            _fail(failures, "windup_geom: empty pending_attack (depth)")
        elif not pa1.has("effective_pair_file_spacing_equivalent") or not pa1.has("effective_pair_eff_dist"):
            _fail(failures, "windup_geom: depth missing spacing keys")
        elif not bool(pa1.get("depth_polearm_attack", false)):
            _fail(failures, "windup_geom: depth spear should set depth_polearm_attack")
        else:
            var want_eff1: float = PairGeometry.effective_pair_eff_dist(mgr2, depth, en)
            var want_space1: float = PairGeometry.effective_pair_file_spacing_equivalent(mgr2, depth, en)
            if not is_equal_approx(float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1):
                _fail(
                    failures,
                    (
                        "windup_geom: depth eff_dist stamp %.4f vs builder %.4f"
                        % [float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1]
                    )
                )
            if not is_equal_approx(float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1):
                _fail(
                    failures,
                    (
                        "windup_geom: depth file_spacing_eq stamp %.4f vs builder %.4f"
                        % [float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1]
                    )
                )
            var want_allow: bool = DepthPolearm.depth_polearm_lane_allows_low_targets(mgr2, depth)
            if bool(pa1.get("depth_polearm_allows_low_targets", not want_allow)) != want_allow:
                _fail(
                    failures,
                    (
                        "windup_geom: depth_polearm_allows_low_targets=%s want %s"
                        % [str(pa1.get("depth_polearm_allows_low_targets")), str(want_allow)]
                    )
                )
            var want_lane: String = "open" if want_allow else "over_shoulder"
            if str(pa1.get("depth_polearm_lane_type", "")) != want_lane:
                _fail(
                    failures,
                    (
                        "windup_geom: depth_polearm_lane_type=%s want %s"
                        % [str(pa1.get("depth_polearm_lane_type")), want_lane]
                    )
                )
            var w1: Variant = EntityAccess.get_weapon(depth)
            if w1 != null:
                var want_meas1: float = StrikeStamping.strike_measure_ratio_for_attack_pair(
                    mgr2, depth, en, w1, want_eff1
                )
                if not is_equal_approx(float(pa1.get("strike_measure_ratio", -9.0)), want_meas1):
                    _fail(
                        failures,
                        (
                            "windup_geom: depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
                            % [float(pa1.get("strike_measure_ratio", -9.0)), want_meas1]
                        )
                    )
    _free_manager(mgr2)

    # 3-wide enemy line: stamped `effective_pair_*` must still match builder (wedge/lane/ZoC path stress).
    var mgr3: Node = MgrScript.new()
    mgr3.register(_new_entity("SWORD"), "player")
    mgr3.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr3.register(_new_entity("SWORD"), "enemy")
    mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr3.call("recompute_zoc_and_distance")
    var depth3: Dictionary = mgr3.combatants[1]
    var en30: Dictionary = mgr3.combatants[2]
    if not DepthPolearm.depth_polearm_lane_open(mgr3, depth3):
        _fail(failures, "windup_geom: 3-file enemy expected depth polearm lane open")
    elif not MeleeListing.can_melee_threaten(mgr3, depth3, en30):
        _fail(failures, "windup_geom: 3-file enemy depth should melee-threaten file-opposed rank-0")
    else:
        var d3_id: int = EntityAccess.id_int(depth3)
        var e3_id: int = EntityAccess.id_int(en30)
        WindUpStarter.start(mgr3, d3_id, e3_id, "spear_thrust")
        var comb_pa3: Variant = mgr3._get_by_id(d3_id)
        var pa3: Dictionary = EntityAccess.nested_dictionary_read(
            comb_pa3 if comb_pa3 is Dictionary else {}, "pending_attack"
        )
        if pa3.is_empty():
            _fail(failures, "windup_geom: empty pending_attack (depth 3-file line)")
        elif not bool(pa3.get("depth_polearm_attack", false)):
            _fail(failures, "windup_geom: depth 3-file should set depth_polearm_attack")
        else:
            var want_eff3: float = PairGeometry.effective_pair_eff_dist(mgr3, depth3, en30)
            var want_space3: float = PairGeometry.effective_pair_file_spacing_equivalent(mgr3, depth3, en30)
            if not is_equal_approx(float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3):
                _fail(
                    failures,
                    (
                        "windup_geom: 3-file depth eff_dist stamp %.4f vs builder %.4f"
                        % [float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3]
                    )
                )
            if not is_equal_approx(float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)), want_space3):
                _fail(
                    failures,
                    (
                        "windup_geom: 3-file depth file_spacing_eq stamp %.4f vs builder %.4f"
                        % [float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)), want_space3]
                    )
                )
            var w3: Variant = EntityAccess.get_weapon(depth3)
            if w3 != null:
                var want_meas3: float = StrikeStamping.strike_measure_ratio_for_attack_pair(
                    mgr3, depth3, en30, w3, want_eff3
                )
                if not is_equal_approx(float(pa3.get("strike_measure_ratio", -9.0)), want_meas3):
                    _fail(
                        failures,
                        (
                            "windup_geom: 3-file depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
                            % [float(pa3.get("strike_measure_ratio", -9.0)), want_meas3]
                        )
                    )
    _free_manager(mgr3)


## `AttackResultApplier`: terminal outcomes clear `pending_attack` (defeated / miss / dodge / skip).


## `AttackResultApplier`: terminal outcomes clear `pending_attack` (defeated / miss / dodge / skip).
static func _run_attack_result_applier_terminal_clears_pending(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    p.state = CombatConstants.STATE_WIND_UP
    p.pending_attack = {"target_id": e_id, "attack_type": "thrust", "intensity": 0.5}
    AttackResultApplier.apply_result(mgr, p_id, {"action": "defeated", "target_id": e_id})
    if not EntityAccess.nested_dictionary_read(p, "pending_attack").is_empty():
        _fail(failures, "result_applier: defeated should clear attacker pending_attack")
    if EntityAccess.state_str(p) != CombatConstants.STATE_WAITING:
        _fail(failures, "result_applier: defeated attacker should be WAITING got %s" % EntityAccess.state_str(p))
    _free_manager(mgr)

    var mgr2: Node = MgrScript.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p2: Dictionary = mgr2.combatants[0]
    var e2: Dictionary = mgr2.combatants[1]
    var p2_id: int = EntityAccess.id_int(p2)
    var e2_id: int = EntityAccess.id_int(e2)
    p2.state = CombatConstants.STATE_WIND_UP
    p2.pending_attack = {"target_id": e2_id, "attack_type": "thrust", "intensity": 0.5, "effective_attack_line": "high"}
    AttackResultApplier.apply_result(mgr2, p2_id, {"action": "miss", "target_id": e2_id, "recovery_duration": 0.35})
    if not EntityAccess.nested_dictionary_read(p2, "pending_attack").is_empty():
        _fail(failures, "result_applier: miss should clear attacker pending_attack")
    if str(p2.get("last_move_id", "")) != "thrust":
        _fail(failures, "result_applier: miss should set last_move_id from pending thrust")
    if EntityAccess.state_str(p2) != CombatConstants.STATE_RECOVERING:
        _fail(failures, "result_applier: miss attacker should be RECOVERING got %s" % EntityAccess.state_str(p2))
    _free_manager(mgr2)

    var mgr3: Node = MgrScript.new()
    mgr3.register(_new_entity("SWORD"), "player")
    mgr3.register(_new_entity("SWORD"), "enemy")
    mgr3.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p3: Dictionary = mgr3.combatants[0]
    var e3: Dictionary = mgr3.combatants[1]
    var p3_id: int = EntityAccess.id_int(p3)
    var e3_id: int = EntityAccess.id_int(e3)
    p3.state = CombatConstants.STATE_WIND_UP
    p3.pending_attack = {"target_id": e3_id, "attack_type": "slash", "intensity": 0.5, "effective_attack_line": "left"}
    AttackResultApplier.apply_result(mgr3, p3_id, {"action": "dodge", "target_id": e3_id, "recovery_duration": 0.4})
    if not EntityAccess.nested_dictionary_read(p3, "pending_attack").is_empty():
        _fail(failures, "result_applier: dodge should clear attacker pending_attack")
    if EntityAccess.state_str(p3) != CombatConstants.STATE_RECOVERING:
        _fail(failures, "result_applier: dodge attacker should be RECOVERING got %s" % EntityAccess.state_str(p3))
    _free_manager(mgr3)

    var mgr4: Node = MgrScript.new()
    mgr4.register(_new_entity("SWORD"), "player")
    mgr4.register(_new_entity("SWORD"), "enemy")
    mgr4.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p4: Dictionary = mgr4.combatants[0]
    var e4: Dictionary = mgr4.combatants[1]
    var p4_id: int = EntityAccess.id_int(p4)
    var e4_id: int = EntityAccess.id_int(e4)
    p4.state = CombatConstants.STATE_WIND_UP
    p4.pending_attack = {"target_id": e4_id, "attack_type": "thrust", "intensity": 0.5}
    AttackResultApplier.apply_result(mgr4, p4_id, {"action": "skip", "target_id": e4_id, "recovery_duration": 0.28})
    if not EntityAccess.nested_dictionary_read(p4, "pending_attack").is_empty():
        _fail(failures, "result_applier: skip+recovery should clear attacker pending_attack")
    if EntityAccess.state_str(p4) != CombatConstants.STATE_RECOVERING:
        _fail(
            failures, "result_applier: skip+recovery attacker should be RECOVERING got %s" % EntityAccess.state_str(p4)
        )
    _free_manager(mgr4)

    var mgr5: Node = MgrScript.new()
    mgr5.register(_new_entity("SWORD"), "player")
    mgr5.register(_new_entity("SWORD"), "enemy")
    mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p5: Dictionary = mgr5.combatants[0]
    var e5_id: int = EntityAccess.id_int(mgr5.combatants[1])
    var p5_id: int = EntityAccess.id_int(p5)
    p5.state = CombatConstants.STATE_WIND_UP
    p5.pending_attack = {"target_id": e5_id, "attack_type": "slash", "intensity": 0.5}
    AttackResultApplier.apply_result(mgr5, p5_id, {"action": "skip", "target_id": e5_id, "recovery_duration": 0.0})
    if not EntityAccess.nested_dictionary_read(p5, "pending_attack").is_empty():
        _fail(failures, "result_applier: skip no-recovery should clear attacker pending_attack")
    if EntityAccess.state_str(p5) != CombatConstants.STATE_WAITING:
        _fail(
            failures, "result_applier: skip no-recovery attacker should be WAITING got %s" % EntityAccess.state_str(p5)
        )
    _free_manager(mgr5)


## **`AttackResultApplier`**: **`parry_deflect`** -> **`action_resolved`** payload includes resolver
## **`parry_clash_context`** (signal args: defender id, attacker id, **`BattleScene`** slot names reversed).


## **`AttackResultApplier`**: **`parry_deflect`** -> **`action_resolved`** payload includes resolver
## **`parry_clash_context`** (signal args: defender id, attacker id, **`BattleScene`** slot names reversed).
static func _run_action_resolved_parry_deflect_payload_includes_clash_context(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    var captured: Array = []
    mgr.action_resolved.connect(
        func(first_id: int, second_id: int, res: Dictionary) -> void:
            captured.clear()
            captured.append({"first": first_id, "second": second_id, "res": res.duplicate(true)})
    )
    e["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5}
    var pclash: Dictionary = {"kinematic_delivery": "thrust", "strike_measure_ratio": 1.05, "parry_control": 0.41}
    AttackResultApplier.apply_result(
        mgr,
        e_id,
        {"action": "parry_deflect", "target_id": p_id, "recovery_duration": 0.45, "parry_clash_context": pclash}
    )
    if captured.is_empty():
        _fail(failures, "parry_resolve_emit: expected action_resolved")
        _free_manager(mgr)
        return
    var slot: Dictionary = captured[0] as Dictionary
    if int(slot.get("first", -99)) != p_id:
        _fail(
            failures,
            "parry_resolve_emit: first signal arg should be defender id %d got %d" % [p_id, int(slot.get("first", -99))]
        )
    if int(slot.get("second", -99)) != e_id:
        _fail(
            failures,
            (
                "parry_resolve_emit: second signal arg should be attacker id %d got %d"
                % [e_id, int(slot.get("second", -99))]
            )
        )
    var res: Dictionary = slot.get("res", {}) as Dictionary
    if str(res.get("outcome", "")) != "parry_deflect":
        _fail(failures, "parry_resolve_emit: outcome want parry_deflect got %s" % str(res.get("outcome", "")))
    var ctx: Variant = res.get("parry_clash_context", null)
    if not (ctx is Dictionary):
        _fail(failures, "parry_resolve_emit: missing parry_clash_context on resolved payload")
        _free_manager(mgr)
        return
    var cd: Dictionary = ctx as Dictionary
    if str(cd.get("kinematic_delivery", "")) != "thrust":
        _fail(failures, "parry_resolve_emit: clash kinematic_delivery mismatch")
    if absf(float(cd.get("strike_measure_ratio", 0.0)) - 1.05) > 0.001:
        _fail(failures, "parry_resolve_emit: strike_measure_ratio mismatch")
    if absf(float(cd.get("parry_control", 0.0)) - 0.41) > 0.001:
        _fail(failures, "parry_resolve_emit: parry_control mismatch")
    _free_manager(mgr)

## **`AttackResultApplier`**: first **`action_resolved`** on **`parry_partial`** is defender, attacker, payload with
## **`parry_clash_context`** (nested **`_execute_attack`** may append further rows).
