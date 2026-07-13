class_name CombatD001SoakSanity
extends RefCounted

## Headless **D-001** plausibility + validator cross-checks (grep needles vs log semantics).
## Called from **`CombatD001SoakRunner._evaluate`**, **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE=sanity` . `d001_presets`).

const _TrackSpecs := preload("res://harness/CombatD001TrackSpecs.gd")
const _Validator := preload("res://harness/CombatF5SoakLogValidator.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _EntityPain := preload("res://core/EntityPainConsciousness.gd")
const _CoreEntity := preload("res://core/CoreEntity.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _BattleScene := preload("res://ui/BattleScene.gd")
const _CompanyState := preload("res://world/CompanyState.gd")

## Mirrors **`CombatD001SoakRunner._new_entity`** + **ii6** chest wound (grep rounds to %.1f / %.1fs).
const II6_PROBE_CUT: float = 22.0
const II6_PROBE_BLUNT: float = 22.0
const II6_PROBE_BV_PCT: float = 58.0

const RUNNER_NAME := "CombatD001SoakSanity"


static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    failures.append_array(_run_validator_fixture_tests())
    failures.append_array(_run_plausibility_fixture_tests())
    failures.append_array(_run_profile_detection_tests())
    failures.append_array(_run_slice_isolation_tests())
    failures.append_array(_run_parry_plausibility_fixtures())
    failures.append_array(_run_exhaustion_plausibility_fixtures())
    failures.append_array(_run_numeric_formula_tests())
    failures.append_array(_run_ii6_wound_probe())
    failures.append_array(_run_parry_summary_line_fixture())
    failures.append_array(_run_ii6_capture_slice_fixture())
    failures.append_array(_run_track_crosswalk_tests())
    failures.append_array(_run_f5_soak_trace_fixtures())
    failures.append_array(_run_ii5_world_formation_meta_fixture())
    var ok: bool = failures.is_empty()
    if ok:
        var ent: CoreEntity = _ii6_probe_entity()
        var pain: float = _EntityPain.get_effective_pain_for_thresholds(ent)
        var dur: float = _PainConscious.get_pain_shock_duration_seconds(pain, 0.0)
        _OperationalLog.harness_ok(
            RUNNER_NAME,
            (
                "fixtures+ii6_pain=%.1f+dur=%.1fs+thresh=%.1f"
                % [snapped(pain, 0.1), snapped(dur, 0.1), _PainConscious.get_pain_shock_threshold()]
            )
        )
    else:
        _OperationalLog.harness_fail(RUNNER_NAME, failures)
    return {"ok": ok, "failures": failures, "harness_ok_emitted": true}


## Per-preset log semantics after grep needle checks pass.
static func plausibility_failures_for_preset(preset_id: String, lines: PackedStringArray) -> PackedStringArray:
    var pid: String = preset_id.strip_edges().to_lower()
    var scoped: PackedStringArray = _lines_for_last_fight(lines)
    var failures: PackedStringArray = _common_log_plausibility_failures(pid, scoped)
    match pid:
        _SoakPresets.PRESET_II5_COWERING:
            failures.append_array(_ii5_plausibility_failures(scoped))
        _SoakPresets.PRESET_II6_AMBIENT_SHOCK:
            failures.append_array(_ii6_plausibility_failures(scoped))
        _SoakPresets.PRESET_II3_SURROUND:
            failures.append_array(_ii3_plausibility_failures(scoped))
        _SoakPresets.PRESET_II8_FORMATION:
            failures.append_array(_ii8_plausibility_failures(scoped))
        _SoakPresets.PRESET_II4D_EXHAUSTION:
            failures.append_array(_ii4d_log_plausibility_failures(scoped))
        "7v7":
            failures.append_array(_7v7_plausibility_failures(lines))
    return failures


# --- run_all unit tests ---


static func _run_validator_fixture_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var good_ii5: PackedStringArray = PackedStringArray(
        [
            "%s: soak_fight_enter tile=cyan preset=ii5" % _OperationalLog.TAG_COMBAT,
            "soak=ii5",
            "soak_setup ii5 leader armless",
            "cowering_fall_back listed for Leader",
            "cowering_fall_back pick Leader target_id=0",
            "cowering_fall_back executed Leader rank 0->1 file 0",
            "soak_fight_end winner=player medical_phase=false fight_profile=ii5",
        ]
    )
    var r5: Dictionary = _Validator.validate(
        _normalize_fixture_lines(good_ii5),
        PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_PRESET_II5])
    )
    if not bool(r5.get("ok", false)):
        failures.append(
            "fixture_ii5_good: %s" % ", ".join(r5.get("failures", PackedStringArray()) as PackedStringArray)
        )

    var amb_line: String = _ii6_expected_ambient_log_line()
    var good_ii6: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58",
            "soak=ii6",
            amb_line,
            "soak_fight_end winner=player medical_phase=false fight_profile=ii6",
        ]
    )
    var r6: Dictionary = _Validator.validate(
        good_ii6, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_PRESET_II6])
    )
    if not bool(r6.get("ok", false)):
        failures.append(
            "fixture_ii6_good: %s" % ", ".join(r6.get("failures", PackedStringArray()) as PackedStringArray)
        )

    var bad_missing_listed: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii5 leader armless",
            "cowering_fall_back executed Leader rank 0->1 file 0",
        ]
    )
    var r5b: Dictionary = _Validator.validate(bad_missing_listed, PackedStringArray([_TrackSpecs.PROFILE_PRESET_II5]))
    if bool(r5b.get("ok", false)):
        failures.append("fixture_ii5_bad: validator should fail without cowering_fall_back listed")

    var good_ii2b: PackedStringArray = PackedStringArray(
        [
            "soak_fight_enter preset=ii2b",
            "soak=ii2b",
            "engagement mode=Duel",
            "parry_deflect attacker=0",
            "parry_bind",
            "riposte_chain",
            "soak_fight_end winner=player fight_profile=ii2b",
        ]
    )
    var r2b: Dictionary = _Validator.validate(
        good_ii2b, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_PRESET_II2B])
    )
    if not bool(r2b.get("ok", false)):
        failures.append(
            "fixture_ii2b_good: %s" % ", ".join(r2b.get("failures", PackedStringArray()) as PackedStringArray)
        )

    var good_wf_m3: PackedStringArray = PackedStringArray(
        [
            "turn_ready_gauge id=0 Leader label=Stm 84% . Ready . Grd HiR . Form Ox tooltip_match=melee_only",
            "form_switch id=1 ox->wrath reason=duel_read",
        ]
    )
    var rwf: Dictionary = _Validator.validate(good_wf_m3, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS]))
    if not bool(rwf.get("ok", false)):
        failures.append(
            "fixture_wf_m3_good: %s" % ", ".join(rwf.get("failures", PackedStringArray()) as PackedStringArray)
        )
    var wf_tracks: Dictionary = rwf.get("tracks", {}) as Dictionary
    for tid in ["wf_m3_turn_ready_form", "wf_m3_grd_before_form"]:
        var wf_track: Dictionary = wf_tracks.get(tid, {}) as Dictionary
        if not bool(wf_track.get("pass", false)):
            failures.append("fixture_wf_m3_good: %s not pass" % tid)

    var bad_wf_m3: PackedStringArray = PackedStringArray(
        [
            "turn_ready_gauge id=0 Leader label=Stm 84% . Ready . Form Ox tooltip_match=melee_only",
        ]
    )
    var rwf_bad: Dictionary = _Validator.validate(bad_wf_m3, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS]))
    var bad_tracks: Dictionary = rwf_bad.get("tracks", {}) as Dictionary
    var grd_tr: Dictionary = bad_tracks.get("wf_m3_grd_before_form", {}) as Dictionary
    if bool(grd_tr.get("pass", false)):
        failures.append("fixture_wf_m3_bad: wf_m3_grd_before_form should fail without Grd/Atk before Form")

    var leak_wf_m3: PackedStringArray = PackedStringArray(
        [
            "turn_ready_gauge id=0 Leader label=Stm 92% . Ready . Step tooltip_match=melee_only",
        ]
    )
    var rwf_leak: Dictionary = _Validator.validate(leak_wf_m3, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS]))
    var leak_tr: Dictionary = (rwf_leak.get("tracks", {}) as Dictionary).get("wf_m3_idle_step_leak", {}) as Dictionary
    if bool(leak_tr.get("pass", false)):
        failures.append("fixture_wf_m3_leak: wf_m3_idle_step_leak should fail on Ready . Step idle gauge")

    var good_camp: PackedStringArray = PackedStringArray(
        [
            "settlement_continue paid=120",
            "company_day_advanced day=2 wages_paid=true",
            "field_care: pressure applied",
        ]
    )
    var rcamp: Dictionary = _Validator.validate(
        good_camp, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_CAMP_EA])
    )
    if _TrackSpecs.PROFILE_CAMP_EA not in (rcamp.get("profiles", PackedStringArray()) as PackedStringArray):
        failures.append("fixture_camp_ea: detect_profiles should include camp_ea")
    var camp_tracks: Dictionary = rcamp.get("tracks", {}) as Dictionary
    for cid in ["camp_settlement_continue", "camp_company_day", "camp_field_care"]:
        var ctr: Dictionary = camp_tracks.get(cid, {}) as Dictionary
        if not bool(ctr.get("pass", false)):
            failures.append("fixture_camp_ea: %s not pass" % cid)

    var camp_wf_smoke: PackedStringArray = PackedStringArray(
        [
            "settlement_continue paid=120",
            "company_day_advanced day=2 wages_paid=true",
            "turn_ready_gauge id=0 Leader label=Stm 84% . Ready . Grd HiR . Form Ox tooltip_match=melee_only",
            "form_switch id=1 ox->wrath reason=duel_read",
        ]
    )
    var camp_wf_profiles: PackedStringArray = _TrackSpecs.detect_profiles(camp_wf_smoke)
    var rcw: Dictionary = _Validator.validate(camp_wf_smoke, camp_wf_profiles)
    if _TrackSpecs.PROFILE_CAMP_EA not in camp_wf_profiles:
        failures.append("fixture_camp_wf_smoke: expected camp_ea profile")
    if not bool(rcw.get("ok", false)):
        failures.append(
            "fixture_camp_wf_smoke: %s" % ", ".join(rcw.get("failures", PackedStringArray()) as PackedStringArray)
        )

    var good_mopup: PackedStringArray = PackedStringArray(
        [
            "engagement_debug turn side=player id=0 mop_up=true rotate_suppress=true menu=strikes_listed strikes=3",
            "soak_fight_end winner=player medical_phase=true fight_profile=7v7",
        ]
    )
    var rmopup: Dictionary = _Validator.validate(
        good_mopup, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var mop_tr: Dictionary = (rmopup.get("tracks", {}) as Dictionary).get("camp_mopup_strike_finish", {}) as Dictionary
    if not bool(mop_tr.get("pass", false)):
        failures.append("fixture_camp_mopup: camp_mopup_strike_finish should pass with strikes_listed")

    var bad_mopup: PackedStringArray = PackedStringArray(
        [
            "engagement_debug turn side=player id=0 mop_up=true rotate_suppress=true menu=reserve_only strikes=0 pick=attempt_close",
        ]
    )
    var rmopup_bad: Dictionary = _Validator.validate(
        bad_mopup, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var mop_bad_tr: Dictionary = (
        (rmopup_bad.get("tracks", {}) as Dictionary).get("camp_mopup_strike_finish", {}) as Dictionary
    )
    if bool(mop_bad_tr.get("pass", false)):
        failures.append("fixture_camp_mopup_bad: camp_mopup_strike_finish should fail on reserve_only stall")

    var good_line_plug: PackedStringArray = PackedStringArray(
        [
            "engagement_debug turn id=0 Rear file=0 rank=1 menu=formation bands=LONG opposed=Front mapped_opp=true wing_lack=false mop_up=false rotate_suppress=false sparse_line=false line_plug=true pick=swap_rank layer=formation_plug line_plug_pick=1",
        ]
    )
    var rplug: Dictionary = _Validator.validate(
        good_line_plug, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var plug_tr: Dictionary = (rplug.get("tracks", {}) as Dictionary).get("camp_line_plug_pick", {}) as Dictionary
    if not bool(plug_tr.get("pass", false)):
        failures.append("fixture_line_plug: camp_line_plug_pick should pass with line_plug_pick=1")

    var good_rotate_plug: PackedStringArray = PackedStringArray(
        [
            "engagement_debug turn id=0 Front file=0 rank=0 menu=formation bands=LONG opposed=Enemy mapped_opp=true wing_lack=false mop_up=false rotate_suppress=false sparse_line=false line_plug=true pick=rotate_file layer=formation_plug line_plug_pick=1",
        ]
    )
    var rrot: Dictionary = _Validator.validate(
        good_rotate_plug, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var rot_tr: Dictionary = (rrot.get("tracks", {}) as Dictionary).get("camp_line_plug_pick", {}) as Dictionary
    if not bool(rot_tr.get("pass", false)):
        failures.append("fixture_line_plug_rotate: camp_line_plug_pick should pass for rotate_file pick")

    var good_formation_layer: PackedStringArray = PackedStringArray(
        [
            "engagement_debug turn id=0 Rear file=0 rank=1 menu=formation bands=LONG opposed=Front mapped_opp=true wing_lack=false mop_up=false rotate_suppress=false sparse_line=false line_plug=true pick=swap_rank layer=formation_plug line_plug_pick=1",
        ]
    )
    var rlayer: Dictionary = _Validator.validate(
        good_formation_layer, PackedStringArray([_TrackSpecs.PROFILE_PRESET_II_ENVELOP])
    )
    var layer_tr: Dictionary = (
        (rlayer.get("tracks", {}) as Dictionary).get("ii_line_plug_formation_layer", {}) as Dictionary
    )
    if not bool(layer_tr.get("pass", false)):
        failures.append("fixture_formation_plug_layer: ii_line_plug_formation_layer should pass")

    var good_mopup_hold: PackedStringArray = PackedStringArray(
        [
            "mopup_hold_line_list id=3 Fighter hint=Mop-up  -  finish the last enemy with a listed strike.",
        ]
    )
    var rmopup_hold: Dictionary = _Validator.validate(
        good_mopup_hold, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_PRESET_II_ENVELOP])
    )
    var mopup_hold_tr: Dictionary = (
        (rmopup_hold.get("tracks", {}) as Dictionary).get("ii_envelop_mopup_hold_hint", {}) as Dictionary
    )
    if not bool(mopup_hold_tr.get("pass", false)):
        failures.append("fixture_mopup_hold_line: ii_envelop_mopup_hold_hint should pass on mopup_hold_line_list")

    var good_sparse_hold: PackedStringArray = PackedStringArray(
        [
            "mopup_hold_line_list id=4 Companion5 hint=Line open after rout  -  close in or strike; shuffle won't fill distant gaps.",
        ]
    )
    var rsparse_hold: Dictionary = _Validator.validate(
        good_sparse_hold, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var sparse_hold_stats: Dictionary = rsparse_hold.get("grep_stats", {}) as Dictionary
    if int(sparse_hold_stats.get("mopup_gauge_hint", 0)) < 1:
        failures.append("fixture_sparse_hold_line: mopup_gauge_hint should count mopup_hold_line_list sparse copy")

    var good_sparse_gauge: PackedStringArray = PackedStringArray(
        [
            "mopup_hold_line_list id=4 Companion5 hint=Line open after rout  -  close in or strike; shuffle won't fill distant gaps.",
            "turn_ready_gauge id=4 Companion5 label=Ready . Focus head 78% tooltip_match=hold_line",
        ]
    )
    var rsparse_gauge: Dictionary = _Validator.validate(
        good_sparse_gauge, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var sparse_gauge_stats: Dictionary = rsparse_gauge.get("grep_stats", {}) as Dictionary
    if int(sparse_gauge_stats.get("tooltip_hold_line", 0)) < 1:
        failures.append("fixture_sparse_hold_gauge: tooltip_hold_line should count fight-finish hold_line match")

    var good_mopup_hold_close: PackedStringArray = PackedStringArray(
        [
            "mopup_hold_line_list id=1 Rear hint=Mop-up  -  finish the last enemy; close in or strike.",
        ]
    )
    var rmopup_hold_close: Dictionary = _Validator.validate(
        good_mopup_hold_close, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_PRESET_II_ENVELOP])
    )
    var mopup_hold_close_tr: Dictionary = (
        (rmopup_hold_close.get("tracks", {}) as Dictionary).get("ii_envelop_mopup_hold_hint", {}) as Dictionary
    )
    if not bool(mopup_hold_close_tr.get("pass", false)):
        failures.append("fixture_mopup_hold_line_close: ii_envelop_mopup_hold_hint should pass on close copy")

    var mopup_false_positives: PackedStringArray = PackedStringArray(
        [
            "[ii_envelop_mopup_hold_hint] PASS  -  count=6 need>=1",
            "soak_setup ii_envelop_mopup 3e attrition smoke (engagement_debug mop_up)",
        ]
    )
    var rmopup_fp: Dictionary = _Validator.validate(
        mopup_false_positives, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_PRESET_II_ENVELOP])
    )
    var mopup_fp_tr: Dictionary = (
        (rmopup_fp.get("tracks", {}) as Dictionary).get("ii_envelop_mopup_hold_hint", {}) as Dictionary
    )
    if bool(mopup_fp_tr.get("pass", false)):
        failures.append(
            "fixture_mopup_false_positive: ii_envelop_mopup_hold_hint must not pass on report/setup echo lines"
        )

    var good_ctrl_close: PackedStringArray = PackedStringArray(
        [
            "controlling_close_list id=0 Leader hint=Close is harder vs Fool  -  strike from range or commit with strength.",
        ]
    )
    var rctrl: Dictionary = _Validator.validate(good_ctrl_close, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS]))
    var ctrl_tr: Dictionary = (rctrl.get("tracks", {}) as Dictionary).get("wf_controlling_close_hint", {}) as Dictionary
    if not bool(ctrl_tr.get("pass", false)):
        failures.append("fixture_wf_controlling_close: wf_controlling_close_hint should pass on controlling_close_list")

    var ctrl_false_positives: PackedStringArray = PackedStringArray(
        [
            "[wf_controlling_close_hint] PASS  -  count=1 need>=1",
            "soak_setup wf_controlling_close_hint ok",
        ]
    )
    var rctrl_fp: Dictionary = _Validator.validate(
        ctrl_false_positives, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS])
    )
    var ctrl_fp_tr: Dictionary = (
        (rctrl_fp.get("tracks", {}) as Dictionary).get("wf_controlling_close_hint", {}) as Dictionary
    )
    if bool(ctrl_fp_tr.get("pass", false)):
        failures.append("fixture_wf_controlling_close_false_positive: must not pass on report/setup echo lines")

    var good_incap_plug: PackedStringArray = PackedStringArray(
        [
            "engagement_debug turn id=1 Rear file=0 rank=1 menu=formation bands=LONG opposed=Front mapped_opp=true wing_lack=false mop_up=false rotate_suppress=false sparse_line=false line_plug=true pick=swap_rank layer=formation_plug line_plug_pick=1",
        ]
    )
    var rincap: Dictionary = _Validator.validate(
        good_incap_plug, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_7V7])
    )
    var incap_tr: Dictionary = (rincap.get("tracks", {}) as Dictionary).get("camp_line_plug_pick", {}) as Dictionary
    if not bool(incap_tr.get("pass", false)):
        failures.append("fixture_incap_plug: camp_line_plug_pick should pass for incap plug-forward swap")

    var contract_settle: PackedStringArray = PackedStringArray(
        [
            "contract_victory pay=120 gold=200 renown=1",
            "company_day_advanced day=2 wages_paid=true",
        ]
    )
    var rcontract: Dictionary = _Validator.validate(
        contract_settle, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_CAMP_EA])
    )
    var settle_tr: Dictionary = (
        (rcontract.get("tracks", {}) as Dictionary).get("camp_settlement_continue", {}) as Dictionary
    )
    if not bool(settle_tr.get("pass", false)):
        failures.append("fixture_camp_contract_victory: camp_settlement_continue alt contract_victory pay=")

    var camp_extended: PackedStringArray = PackedStringArray(
        [
            "campaign_medical_exit can_end=false fast_forward=true batch_resolve=true",
            "field_care bandage part=chest target=Leader seconds=150 parts_left=1 med_left=2 eff=1.00",
            "company_run_end reason=contract_failed reload=true",
            "company_run_end reason=tutorial_failed reload=false",
            "company_wages: gold=10 below next wage bill=35 (day 4)",
            "desertion summary=Ally(mood=12)",
            "party_triage_open living=7 untreated=2 bleeding=1 parts_need_dressing=3 med_left=12 bandage_med_est=3 camp_med=1 total_med_est=4 med_shortfall=0",
        ]
    )
    var rext: Dictionary = _Validator.validate(
        camp_extended, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_CAMP_EA])
    )
    for eid in [
        "camp_medical_exit",
        "camp_field_care_action",
        "camp_paid_loss",
        "camp_tutorial_soft_loss",
        "camp_wage_warn",
        "camp_desertion",
        "camp_party_triage",
    ]:
        var etr: Dictionary = (rext.get("tracks", {}) as Dictionary).get(eid, {}) as Dictionary
        if not bool(etr.get("pass", false)):
            failures.append("fixture_camp_extended: %s not pass" % eid)

    var false_positives: PackedStringArray = PackedStringArray(
        [
            "soak_coverage camp grep_stats party_triage_open=0 field_care_bandage=0",
            "field_care: untreated wounds remain after battle triage parts_left=5  -  open Party on the map",
            "field_care bandage failed part=chest target=Leader parts_left=1  -  med refunded",
            "[camp_party_triage] PASS  -  count=1 need>=1",
        ]
    )
    var rfp: Dictionary = _Validator.validate(
        false_positives, PackedStringArray([_TrackSpecs.PROFILE_ALWAYS, _TrackSpecs.PROFILE_CAMP_EA])
    )
    for fp_id in ["camp_party_triage", "camp_field_care_action"]:
        var fp_tr: Dictionary = (rfp.get("tracks", {}) as Dictionary).get(fp_id, {}) as Dictionary
        if bool(fp_tr.get("pass", false)):
            failures.append("fixture_camp_false_positive: %s must not pass on echo/failed/hint lines" % fp_id)

    var soak_echo_only: PackedStringArray = PackedStringArray(
        [
            "soak_coverage camp warn [camp_settlement_continue] count=0 need>=1",
            "soak_coverage camp next [camp_party_triage] open Party on map (grep party_triage_open living=)",
            "soak_coverage camp next [camp_paid_loss] lose a paid contract (grep company_run_end reason=contract_failed reload=true)",
            "turn_ready_gauge id=0 Leader label=Stm 84% . Ready . Grd HiR . Form Ox",
        ]
    )
    if _TrackSpecs.PROFILE_CAMP_EA in _TrackSpecs.detect_profiles(soak_echo_only):
        failures.append("fixture_camp_ea_detect: soak_coverage echoes must not activate camp_ea profile")

    var step9_raw: PackedStringArray = PackedStringArray(
        [
            "FP_WORLD: company_run_end reason=tutorial_failed reload=false",
            "FP_WORLD: company_wages: gold=10 below next wage bill=35 (day 4)",
            "FP_WORLD: desertion summary=Ally(mood=12)",
        ]
    )
    var rstep9: Dictionary = _Validator.validate(step9_raw)
    for sid in ["camp_tutorial_soft_loss", "camp_wage_warn", "camp_desertion"]:
        var str_tr: Dictionary = (rstep9.get("tracks", {}) as Dictionary).get(sid, {}) as Dictionary
        if not bool(str_tr.get("pass", false)):
            failures.append(
                (
                    "fixture_camp_step9_append: %s not pass (lines=%d detail=%s)"
                    % [sid, int(rstep9.get("line_count", 0)), str(str_tr.get("detail", ""))]
                )
            )
    var step9_doc: String = ProjectSettings.globalize_path("res://docs/f5_soak_log.camp_step9_optional.example.txt")
    if FileAccess.file_exists(step9_doc):
        var step9_file: PackedStringArray = _Validator._decode_f5_log_text(FileAccess.get_file_as_string(step9_doc))
        var rstep9_file: Dictionary = _Validator.validate(step9_file)
        for fid in ["camp_tutorial_soft_loss", "camp_wage_warn", "camp_desertion"]:
            var ftr: Dictionary = (rstep9_file.get("tracks", {}) as Dictionary).get(fid, {}) as Dictionary
            if not bool(ftr.get("pass", false)):
                failures.append(
                    (
                        "fixture_camp_step9_file: %s not pass (lines=%d detail=%s)"
                        % [fid, int(rstep9_file.get("line_count", 0)), str(ftr.get("detail", ""))]
                    )
                )

    return failures


static func _run_plausibility_fixture_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()

    var missing_exec: PackedStringArray = PackedStringArray(
        [
            "cowering_fall_back listed for Leader",
        ]
    )
    if _ii5_plausibility_failures(missing_exec).is_empty():
        failures.append("fixture_ii5: should require executed line")

    var good_ii5: PackedStringArray = PackedStringArray(
        [
            "cowering_fall_back listed for Leader",
            "cowering_fall_back executed Leader rank 0->1 file 0",
        ]
    )
    if not _ii5_plausibility_failures(good_ii5).is_empty():
        failures.append("fixture_ii5: valid sample should pass")

    var setup_hint_only: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58 (grep ambient_pain_shock on Companion)",
            "soak=ii6",
        ]
    )
    if _ii6_plausibility_failures(setup_hint_only).is_empty():
        failures.append("fixture_ii6_hint: setup grep hint must not satisfy ambient Companion")

    var thresh: float = _PainConscious.get_pain_shock_threshold()
    var low_pain: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58",
            "ambient_pain_shock Companion effective_pain=%.1f duration=5.0s" % (thresh - 0.5),
        ]
    )
    if _ii6_plausibility_failures(low_pain).is_empty():
        failures.append("fixture_ii6_pain: effective_pain below threshold should fail")

    var good_ii6: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58",
            _ii6_expected_ambient_log_line(),
        ]
    )
    if not _ii6_plausibility_failures(good_ii6).is_empty():
        failures.append("fixture_ii6_pain: valid ambient sample should pass")

    var bad_profile: PackedStringArray = PackedStringArray(
        [
            "soak=ii5",
            "soak_fight_end winner=player fight_profile=ii6",
        ]
    )
    if _common_log_plausibility_failures(_SoakPresets.PRESET_II5_COWERING, bad_profile).is_empty():
        failures.append("fixture_common: fight_profile must match preset")

    var conflicting_winners: PackedStringArray = PackedStringArray(
        [
            "soak_fight_enter preset=ii5",
            "soak_fight_end winner=player",
            "soak_fight_end winner=enemy",
        ]
    )
    if _common_log_plausibility_failures(_SoakPresets.PRESET_II5_COWERING, conflicting_winners).is_empty():
        failures.append("fixture_common: conflicting soak_fight_end winners in one fight should fail")

    var multi_fight_retry: PackedStringArray = PackedStringArray(
        [
            "soak_fight_enter preset=ii5",
            "soak_fight_end winner=enemy",
            "soak_fight_enter preset=ii5",
            "soak_fight_end winner=player",
        ]
    )
    if not (
        _common_log_plausibility_failures(_SoakPresets.PRESET_II5_COWERING, _lines_for_last_fight(multi_fight_retry))
        . is_empty()
    ):
        failures.append("fixture_common: last-fight scope should ignore prior fight winner")

    var end_before_enter: PackedStringArray = PackedStringArray(
        [
            "soak_fight_end winner=player",
            "soak_fight_enter preset=ii5",
        ]
    )
    if _common_log_plausibility_failures(_SoakPresets.PRESET_II5_COWERING, end_before_enter).is_empty():
        failures.append("fixture_common: fight enter should precede fight end")

    return failures


static func _run_profile_detection_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    for preset_id in _SoakPresets.D001_PRESET_RUN_ORDER:
        var profile: String = _TrackSpecs.preset_id_to_profile(preset_id)
        if profile.is_empty():
            failures.append("profile_map: missing profile for %s" % preset_id)
            continue
        var markers: PackedStringArray = _TrackSpecs.synthetic_profile_markers(preset_id)
        if markers.is_empty():
            continue
        var detected: PackedStringArray = _TrackSpecs.detect_profiles(markers)
        if profile not in detected:
            failures.append(
                "detect_profiles: %s expected %s from %s got %s" % [preset_id, profile, str(markers), str(detected)]
            )
    var detected_7v7: PackedStringArray = _TrackSpecs.detect_profiles(
        PackedStringArray(["soak_fight_enter tile=red 7v7", "soak=7v7"])
    )
    if _TrackSpecs.PROFILE_7V7 not in detected_7v7:
        failures.append("detect_profiles: 7v7 markers should activate profile_7v7")
    var detected_camp: PackedStringArray = _TrackSpecs.detect_profiles(_TrackSpecs.synthetic_profile_markers("camp_ea"))
    if _TrackSpecs.PROFILE_CAMP_EA not in detected_camp:
        failures.append("detect_profiles: camp_ea markers should activate profile_camp_ea")
    return failures


static func _run_slice_isolation_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var mixed: PackedStringArray = PackedStringArray(
        [
            "encounter_begin players=1 enemies=1 | encounter[soak=ii5]",
            "cowering_fall_back listed for Leader",
            "encounter_begin players=1 enemies=1 | encounter[soak=ii6]",
            "soak_setup ii6 companion chest wounded bv=58",
            "ambient_pain_shock Companion effective_pain=12.0 duration=8.6s",
        ]
    )
    var ii5_slice: PackedStringArray = _TrackSpecs.slice_lines_for_soak_preset(mixed, _SoakPresets.PRESET_II5_COWERING)
    if ii5_slice.is_empty() or not _blob_has(ii5_slice, "cowering_fall_back listed"):
        failures.append("slice_ii5: should capture ii5 fight lines only")
    if _blob_has(ii5_slice, "ambient_pain_shock"):
        failures.append("slice_ii5: must not include ii6 ambient lines")

    var ii6_slice: PackedStringArray = _TrackSpecs.slice_lines_for_soak_preset(
        mixed, _SoakPresets.PRESET_II6_AMBIENT_SHOCK
    )
    if not _blob_has(ii6_slice, "ambient_pain_shock Companion"):
        failures.append("slice_ii6: should capture ii6 ambient line")
    if _blob_has(ii6_slice, "cowering_fall_back"):
        failures.append("slice_ii6: must not include ii5 cowering lines")

    var empty: PackedStringArray = _TrackSpecs.slice_lines_for_soak_preset(mixed, "ii99")
    if not empty.is_empty():
        failures.append("slice_unknown: unknown preset should yield empty slice")

    return failures


static func _run_ii5_world_formation_meta_fixture() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var world := Node2D.new()
    _SoakPresets.apply_world_post_setup(world, _SoakPresets.PRESET_II5_COWERING)
    if not world.has_meta("party_formation"):
        failures.append("ii5_world: missing party_formation meta")
    else:
        var pf: Dictionary = world.get_meta("party_formation") as Dictionary
        if int(pf.get("files", 0)) != 2 or int(pf.get("ranks", 0)) != 3:
            failures.append("ii5_world: want files=2 ranks=3 (loose 2x3)")
        if str(pf.get("line_discipline", "")) != CombatConstants.LINE_DISCIPLINE_LOOSE:
            failures.append("ii5_world: want line_discipline loose")
    if (
        not world.has_meta(_SoakPresets.WORLD_META_LOCK_PARTY_FORMATION)
        or not bool(world.get_meta(_SoakPresets.WORLD_META_LOCK_PARTY_FORMATION))
    ):
        failures.append("ii5_world: soak_lock_party_formation meta missing")
    if is_instance_valid(world):
        world.free()
    return failures


static func _run_parry_plausibility_fixtures() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var too_low: Dictionary = {
        "parry_deflect": 0,
        "parry_bind": 0,
        "parry_partial": 0,
        "riposte_chain": 0,
        "flurry_bind_opened": 0,
    }
    if _TrackSpecs.ii2b_plausibility_failures(too_low).is_empty():
        failures.append("fixture_ii2b_parry: empty stats should fail plausibility")

    var bind_heavy: Dictionary = {
        "parry_deflect": 1,
        "parry_bind": 9,
        "parry_partial": 0,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if _TrackSpecs.ii2b_plausibility_failures(bind_heavy).is_empty():
        failures.append("fixture_ii2b_parry: bind dominating deflect should fail")

    var good: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 1,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if not _TrackSpecs.ii2b_plausibility_failures(good).is_empty():
        failures.append("fixture_ii2b_parry: balanced stats should pass")

    var partial_leak: Dictionary = {
        "parry_deflect": 1,
        "parry_bind": 1,
        "parry_partial": 20,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if _TrackSpecs.ii2b_plausibility_failures(partial_leak).is_empty():
        failures.append("fixture_ii2b_parry: excessive partial vs clean outcomes should fail")

    return failures


static func _run_exhaustion_plausibility_fixtures() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var no_band: Dictionary = {"crossed_25": 0, "crossed_50": 0, "exhaustion_log": 0}
    if _TrackSpecs.ii4d_plausibility_failures(no_band, true).is_empty():
        failures.append("fixture_ii4d: missing band crossings should fail")

    var no_gauge: Dictionary = {"crossed_25": 1, "crossed_50": 1, "exhaustion_log": 2}
    if _TrackSpecs.ii4d_plausibility_failures(no_gauge, false).is_empty():
        failures.append("fixture_ii4d: missing gauge Exh suffix should fail")

    var good: Dictionary = {"crossed_25": 1, "crossed_50": 0, "crossed_75": 0, "exhaustion_log": 3}
    if not _TrackSpecs.ii4d_plausibility_failures(good, true).is_empty():
        failures.append("fixture_ii4d: minimal band + gauge should pass")

    return failures


static func _run_numeric_formula_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var thresh: float = _PainConscious.get_pain_shock_threshold()
    if absf(thresh - _PainConscious.NRS_SHOCK) > 0.001:
        failures.append("numeric: shock threshold %.2f want NRS_SHOCK %.1f" % [thresh, _PainConscious.NRS_SHOCK])
    var probe_ent: CoreEntity = _ii6_probe_entity()
    var pain_probe: float = _EntityPain.get_effective_pain_for_thresholds(probe_ent)
    var dur_probe: float = _PainConscious.get_pain_shock_duration_seconds(pain_probe, 0.0)
    var want_dur: float = _PainConscious.PAIN_SHOCK_DURATION_BASE * (pain_probe / thresh)
    if absf(dur_probe - want_dur) > 0.001:
        failures.append("numeric: duration(pain)=%.3f want %.3f" % [dur_probe, want_dur])
    if pain_probe <= thresh:
        failures.append("numeric: ii6 probe pain %.2f must exceed threshold %.2f" % [pain_probe, thresh])
    var interval: float = _PainConscious.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    if interval <= 0.0 or interval > 10.0:
        failures.append("numeric: ambient check interval %.1fs out of band" % interval)
    return failures


static func _run_ii6_wound_probe() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var was_on: bool = CombatConstants.is_feature_ambient_pain_shock()
    CombatConstants.set_feature_ambient_pain_shock(true)
    var ent: CoreEntity = _ii6_probe_entity()
    var pain: float = _EntityPain.get_effective_pain_for_thresholds(ent)
    var thresh: float = _PainConscious.get_pain_shock_threshold()
    var dur: float = _PainConscious.get_pain_shock_duration_seconds(pain, 0.0)
    if pain <= thresh:
        failures.append("ii6_probe: effective_pain %.2f must exceed threshold %.2f" % [pain, thresh])
    var log_line: String = _ii6_ambient_log_line_for_entity(ent)
    var parsed_pain: float = _parse_ambient_metric(log_line, "effective_pain=")
    var parsed_dur: float = _parse_ambient_metric(log_line, "duration=")
    if absf(parsed_pain - snapped(pain, 0.1)) > 0.05:
        failures.append("ii6_probe: log pain %.1f vs computed %.2f" % [parsed_pain, pain])
    if absf(parsed_dur - snapped(dur, 0.1)) > 0.05:
        failures.append("ii6_probe: log duration %.1f vs computed %.2f" % [parsed_dur, dur])
    var entered: bool = false
    var interval: float = _PainConscious.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    ent._ambient_pain_shock_accum = interval - 0.001
    for _i in 80:
        if _EntityPain.try_ambient_pain_shock_tick(ent, 0.01):
            entered = true
            break
        ent._ambient_pain_shock_accum = interval - 0.001
    if not entered:
        failures.append("ii6_probe: ambient shock should enter within 80 ticks (pain=%.2f)" % pain)
    if not was_on:
        CombatConstants.set_feature_ambient_pain_shock(false)
    return failures


static func _ii6_probe_entity() -> CoreEntity:
    var ent: CoreEntity = _CoreEntity.new()
    ent.apply_species()
    ent.dominant_hand = "right_arm"
    ent.offhand_functionality = 1.0
    var w: Weapon = _Weapon.create_from_definition("SWORD")
    if w != null:
        ent.equip_weapon(w)
    ent.take_damage_split(II6_PROBE_CUT, II6_PROBE_BLUNT, "chest")
    ent.blood_volume = II6_PROBE_BV_PCT
    ent._pain_shock_until_time = -1.0
    ent._ambient_pain_shock_accum = 0.0
    CombatRegressionHarness._track_harness_node(ent)
    return ent


static func _ii6_expected_ambient_log_line() -> String:
    return _ii6_ambient_log_line_for_entity(_ii6_probe_entity())


static func _ii6_ambient_log_line_for_entity(ent: CoreEntity) -> String:
    var pain: float = _EntityPain.get_effective_pain_for_thresholds(ent)
    var dur: float = _PainConscious.get_pain_shock_duration_seconds(pain, 0.0)
    return (
        "ambient_pain_shock Companion effective_pain=%.1f duration=%.1fs"
        % [
            snapped(pain, 0.1),
            snapped(dur, 0.1),
        ]
    )


static func _run_parry_summary_line_fixture() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var line: String = "parry_stats deflect=4 bind=1 partial=7 riposte=5 counter_tempo=0 flurry_opened=1 flurry=1"
    var stats: Dictionary = _TrackSpecs.parry_stats_from_summary_line(line)
    if int(stats.get("parry_deflect", 0)) != 4 or int(stats.get("parry_bind", 0)) != 1:
        failures.append("fixture_parry_summary: parse failed for deflect/bind")
    if not _TrackSpecs.ii2b_plausibility_failures(stats).is_empty():
        failures.append("fixture_parry_summary: d001 sample line should pass ii2b plausibility")
    var weak: Dictionary = _TrackSpecs.parry_stats_from_summary_line(
        "parry_stats deflect=0 bind=0 partial=0 riposte=0 counter_tempo=0 flurry_opened=0 flurry=0"
    )
    if _TrackSpecs.ii2b_plausibility_failures(weak).is_empty():
        failures.append("fixture_parry_summary: empty stats should fail ii2b plausibility")
    return failures


static func _run_ii6_capture_slice_fixture() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var amb: String = _ii6_expected_ambient_log_line()
    var blob: PackedStringArray = PackedStringArray(
        [
            "encounter_begin players=1 enemies=1 | encounter[soak=ii5]",
            "cowering_fall_back listed for Leader",
            "encounter_begin players=1 enemies=1 | encounter[soak=ii6]",
            "soak_setup ii6 companion chest wounded bv=58",
            amb,
            "soak_fight_end winner=player fight_profile=ii6",
            "encounter_begin players=1 enemies=1 | encounter[soak=ii8]",
            "engagement mode=Formation line",
        ]
    )
    var slice: PackedStringArray = _TrackSpecs.slice_lines_for_soak_preset(blob, _SoakPresets.PRESET_II6_AMBIENT_SHOCK)
    if not _ii6_plausibility_failures(slice).is_empty():
        failures.append("fixture_ii6_slice: sliced ii6 capture should pass plausibility")
    if _blob_has(slice, "cowering_fall_back"):
        failures.append("fixture_ii6_slice: must not include ii5 lines")
    return failures


static func _run_track_crosswalk_tests() -> PackedStringArray:
    return _TrackSpecs.headless_validator_coverage_failures()


static func _run_f5_soak_trace_fixtures() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    CombatF5SoakTrace.reset_session_camp_trace()
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    CombatF5SoakTrace.note_medical_pack_listed("Leader", "chest")
    var end_warn: int = 0
    var coverage_ok: int = 0
    for raw in _OperationalLog.get_captured_lines():
        var body: String = _combat_line(raw)
        if body.begins_with("soak_coverage warn [soak_fight_end]"):
            end_warn += 1
        if body.begins_with("soak_coverage ok="):
            coverage_ok += 1
    if end_warn > 0:
        failures.append("f5_trace_deferred_medical: soak_fight_end count=0 warn after medical flush")
    if coverage_ok != 1:
        failures.append("f5_trace_deferred_medical: want 1 soak_coverage ok= got %d" % coverage_ok)
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    var exit_mgr: Node = _MgrScript.new()
    exit_mgr.medical_phase = true
    exit_mgr.medical_phase_winner = "player"
    exit_mgr.finish_battle()
    var early_exit_cov: int = 0
    var medical_exit_log: int = 0
    for raw in _OperationalLog.get_captured_lines():
        var body: String = _combat_line(raw)
        if body.begins_with("soak_coverage ok="):
            early_exit_cov += 1
        if body.begins_with("campaign_medical_exit"):
            medical_exit_log += 1
    if early_exit_cov != 1:
        failures.append("f5_trace_early_medical_exit: want soak_coverage after finish_battle got %d" % early_exit_cov)
    if medical_exit_log > 0:
        failures.append("f5_trace_early_medical_exit: campaign_medical_exit should not log without contract world")
    CombatRegressionHarness._free_harness_node(exit_mgr)
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    CombatF5SoakTrace.note_medical_pack_listed("Leader", "chest")
    var camp_world: Node2D = Node2D.new()
    camp_world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var camp_battle: Node = _BattleScene.new()
    camp_battle.parent_scene = camp_world
    var camp_mgr: Node = _MgrScript.new()
    camp_battle.add_child(camp_mgr)
    camp_mgr.medical_phase = true
    camp_mgr.medical_phase_winner = "player"
    if not bool(camp_mgr.call("_is_campaign_contract_battle")):
        failures.append("f5_trace_camp_med_exit_refresh: harness battle should resolve contract world")
    camp_mgr.finish_battle()
    var exit_log: int = 0
    var camp_med_refresh: int = 0
    for raw in _OperationalLog.get_captured_lines():
        var body: String = _combat_line(raw)
        if body.begins_with("campaign_medical_exit"):
            exit_log += 1
        if body.begins_with("soak_coverage camp pass [camp_medical_exit]"):
            camp_med_refresh += 1
    if exit_log != 1:
        failures.append("f5_trace_camp_med_exit_refresh: want campaign_medical_exit log got %d" % exit_log)
    if camp_med_refresh < 1:
        failures.append(
            "f5_trace_camp_med_exit_refresh: want camp_medical_exit supplement pass got %d" % camp_med_refresh
        )
    CombatRegressionHarness._free_manager(camp_mgr)
    camp_battle.free()
    camp_world.free()
    _OperationalLog.play_world("settlement_continue paid=120 renown=1")
    var camp_header: int = 0
    var camp_day_pass: int = 0
    for raw in _OperationalLog.get_captured_lines():
        var body: String = _combat_line(raw)
        if body.begins_with("soak_coverage camp ok="):
            camp_header += 1
    if camp_header < 1:
        failures.append("f5_trace_camp_supplement: want soak_coverage camp header got %d" % camp_header)
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.log_fight_end_summary("player", false)
    _OperationalLog.play_world("company_day_advanced day=2 wages_paid=105 gold=395 living=7")
    for raw in _OperationalLog.get_captured_lines():
        var body: String = _combat_line(raw)
        if body.begins_with("soak_coverage camp pass [camp_company_day]"):
            camp_day_pass += 1
    if camp_day_pass < 1:
        failures.append("f5_trace_camp_supplement: camp_company_day pass after company_day_advanced (session merge)")
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.ingest_trace_line(
        "engagement_debug turn 12 mop_up=true menu=strikes_listed strikes=17" + " sparse=false line_plug=false"
    )
    CombatF5SoakTrace.log_fight_end_summary("player", false)
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    CombatF5SoakTrace.log_fight_end_summary("enemy", false)
    _OperationalLog.play_world("company_run_end reason=contract_failed reload=true")
    var mopup_session_pass: int = 0
    var mopup_session_warn: int = 0
    for raw in _OperationalLog.get_captured_lines():
        var body: String = _combat_line(raw)
        if body.begins_with("soak_coverage camp pass [camp_mopup_strike_finish]"):
            mopup_session_pass += 1
        if body.begins_with("soak_coverage camp warn [camp_mopup_strike_finish]"):
            mopup_session_warn += 1
    if mopup_session_pass < 1:
        (
            failures
            . append(
                (
                    "f5_trace_camp_session_combat: want camp_mopup_strike_finish pass after prior fight archive got pass=%d warn=%d"
                    % [mopup_session_pass, mopup_session_warn]
                )
            )
        )
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)
    return failures


# --- per-preset log plausibility ---


static func _common_log_plausibility_failures(preset_id: String, lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var enter_at: int = -1
    var end_at: int = -1
    var soak_tag_seen: bool = false
    var wrong_soak_tag: bool = false
    var fight_end_winners: PackedStringArray = PackedStringArray()
    var fight_profiles: PackedStringArray = PackedStringArray()
    for i in lines.size():
        var line: String = _combat_line(lines[i])
        if _is_grep_hint_line(line):
            continue
        if "soak_fight_enter" in line or ("encounter_begin" in line and "soak=" in line):
            if enter_at < 0:
                enter_at = i
        if "soak=%s" % preset_id in line:
            soak_tag_seen = true
        elif line.contains("soak=") and not line.contains("soak=%s" % preset_id):
            if preset_id != "7v7" or (not line.contains("soak=7v7") and "tile=red" not in line):
                wrong_soak_tag = true
        if line.begins_with("soak_fight_end"):
            if end_at < 0:
                end_at = i
            var winner: String = _parse_kv_token(line, "winner=")
            if not winner.is_empty():
                fight_end_winners.append(winner)
            var profile: String = _parse_kv_token(line, "fight_profile=")
            if not profile.is_empty():
                fight_profiles.append(profile)
    if enter_at >= 0 and end_at >= 0 and enter_at > end_at:
        failures.append("common: soak_fight_enter/encounter_begin must precede soak_fight_end")
    if fight_end_winners.size() > 1:
        var first: String = fight_end_winners[0]
        for w in fight_end_winners:
            if w != first:
                failures.append("common: conflicting soak_fight_end winner=%s vs %s" % [first, w])
                break
    if soak_tag_seen and wrong_soak_tag:
        failures.append("common: log mixes soak= tag for another preset (expected %s)" % preset_id)
    for profile in fight_profiles:
        if profile != preset_id and not (preset_id == "7v7" and profile == "7v7"):
            failures.append("common: soak_fight_end fight_profile=%s expected %s" % [profile, preset_id])
    return failures


static func _ii5_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var pick_at: int = -1
    var listed_n: int = 0
    var executed_n: int = 0
    for i in lines.size():
        var line: String = _combat_line(lines[i])
        if _is_grep_hint_line(line):
            continue
        if "cowering_fall_back listed" in line:
            listed_n += 1
        if "cowering_fall_back executed" in line:
            executed_n += 1
        if "cowering_fall_back pick" in line:
            pick_at = i
    if listed_n < 1:
        failures.append("ii5: want cowering_fall_back listed (got %d)" % listed_n)
    if executed_n < 1:
        failures.append("ii5: want cowering_fall_back executed (got %d)" % executed_n)
    if pick_at >= 0:
        var pick_line: String = _combat_line(lines[pick_at])
        if "target_id=" not in pick_line:
            failures.append("ii5: cowering_fall_back pick missing target_id")
    if executed_n > 0:
        var exec_line: String = ""
        for raw in lines:
            var s: String = _combat_line(raw)
            if "cowering_fall_back executed" in s:
                exec_line = s
                break
        if not exec_line.contains("rank 0->") and not exec_line.contains("rank 0->"):
            failures.append("ii5: executed line should mention rear rank shift (rank 0->)")
    return failures


static func _ii6_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var setup_at: int = -1
    var ambient_at: int = -1
    var ambient_line: String = ""
    var companion_ambient_n: int = 0
    for i in lines.size():
        var line: String = _combat_line(lines[i])
        if _is_grep_hint_line(line):
            continue
        if line.contains("soak_setup ii6"):
            setup_at = i
        if not line.begins_with("ambient_pain_shock"):
            continue
        if "Companion" in line:
            companion_ambient_n += 1
        if ambient_at < 0:
            ambient_at = i
            ambient_line = line
    if setup_at < 0:
        failures.append("ii6: missing soak_setup ii6 line")
    if companion_ambient_n < 1:
        failures.append("ii6: want ambient_pain_shock Companion (got %d)" % companion_ambient_n)
    if ambient_line.is_empty():
        return failures
    if setup_at >= 0 and ambient_at >= 0 and setup_at > ambient_at:
        failures.append("ii6: soak_setup should precede first ambient_pain_shock")
    var pain_m: float = _parse_ambient_metric(ambient_line, "effective_pain=")
    var dur_m: float = _parse_ambient_metric(ambient_line, "duration=")
    if pain_m < 0.0 or dur_m < 0.0:
        failures.append("ii6: could not parse effective_pain/duration from '%s'" % ambient_line)
        return failures
    var thresh: float = _PainConscious.get_pain_shock_threshold()
    if pain_m <= thresh:
        failures.append("ii6: effective_pain %.1f should exceed shock threshold %.1f" % [pain_m, thresh])
    if dur_m <= 0.0:
        failures.append("ii6: duration %.1f should be positive" % dur_m)
    var expected: float = _PainConscious.get_pain_shock_duration_seconds(pain_m, 0.0)
    var expected_min: float = expected * 0.85
    var expected_max: float = expected * 2.5
    if dur_m < expected_min or dur_m > expected_max:
        failures.append(
            (
                "ii6: duration %.1fs outside plausible band [%.1f, %.1f] (formula base=%.1f)"
                % [dur_m, expected_min, expected_max, expected]
            )
        )
    if absf(dur_m - expected) > 0.15:
        failures.append(
            "ii6: logged duration %.1fs disagrees with formula %.2fs for pain %.1f" % [dur_m, expected, pain_m]
        )
    var bv_m: float = _parse_ambient_metric(_find_line(lines, "soak_setup ii6"), "bv=")
    if bv_m >= 0.0 and (bv_m < 10.0 or bv_m > 95.0):
        failures.append("ii6: soak_setup bv=%.0f outside wounded preset %% band [10,95]" % bv_m)
    return failures


static func _ii3_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var arc_at: int = -1
    var parry_at: int = -1
    for i in lines.size():
        var line: String = _combat_line(lines[i])
        if _is_grep_hint_line(line):
            continue
        if "ui_hint Arc overlap" in line:
            if arc_at < 0:
                arc_at = i
        if _TrackSpecs.NEEDLE_PARRY_TRACE in line:
            if parry_at < 0:
                parry_at = i
    if arc_at < 0:
        failures.append("ii3: want ui_hint Arc overlap before surround parry work")
    if parry_at >= 0 and arc_at >= 0 and arc_at > parry_at:
        failures.append("ii3: Arc overlap hint should precede first parry trace")
    return failures


static func _ii8_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var formation_n: int = 0
    var gauge_ok_n: int = 0
    var gauge_n: int = 0
    for raw in lines:
        var line: String = _combat_line(raw)
        if _is_grep_hint_line(line):
            continue
        if _TrackSpecs.NEEDLE_ENGAGEMENT_FORMATION in line:
            formation_n += 1
        if _TrackSpecs.NEEDLE_TURN_READY_GAUGE in line:
            gauge_n += 1
            if _TrackSpecs.NEEDLE_TOOLTIP_OK in line:
                gauge_ok_n += 1
    if formation_n < 1:
        failures.append("ii8: want engagement mode=Formation line")
    if gauge_n < 1:
        failures.append("ii8: want turn_ready_gauge line")
    elif gauge_ok_n < 1:
        failures.append("ii8: want turn_ready_gauge with tooltip_match=ok (got %d/%d)" % [gauge_ok_n, gauge_n])
    return failures


static func _ii4d_log_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    ## Band ordering only  -  full **ii4d** sign-off (gauge **Exh**) stays in **`CombatD001SoakRunner._run_ii4d_exhaustion`**.
    var failures: PackedStringArray = PackedStringArray()
    var stats: Dictionary = _TrackSpecs.exhaustion_band_stats(lines)
    var c25: int = int(stats.get("crossed_25", 0))
    var c50: int = int(stats.get("crossed_50", 0))
    var c75: int = int(stats.get("crossed_75", 0))
    if c50 > 0 and c25 < 1:
        failures.append("ii4d: crossed 50 logged without crossed 25")
    if c75 > 0 and c50 < 1:
        failures.append("ii4d: crossed 75 logged without crossed 50")
    return failures


static func _7v7_plausibility_failures(lines: PackedStringArray) -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var party_n: int = 0
    var red_enter: int = 0
    for raw in lines:
        var line: String = _combat_line(raw)
        if "party_entering_combat count=7" in line:
            party_n += 1
        if "soak_fight_enter tile=red" in line or "soak_fight_enter tile=red 7v7" in line:
            red_enter += 1
    if party_n < 1:
        failures.append("7v7: want party_entering_combat count=7")
    if red_enter < 1:
        failures.append("7v7: want soak_fight_enter tile=red")
    return failures


# --- helpers ---


## Headless soaks may retry in one capture without a second **soak_fight_enter**; use lines after the prior **soak_fight_end**.
static func _lines_for_last_fight(lines: PackedStringArray) -> PackedStringArray:
    var last_end: int = -1
    for i in range(lines.size() - 1, -1, -1):
        var line: String = _combat_line(lines[i])
        if line.begins_with("soak_fight_end"):
            last_end = i
            break
    if last_end < 0:
        return lines
    var start: int = 0
    for i in range(last_end - 1, -1, -1):
        var line: String = _combat_line(lines[i])
        if "soak_fight_enter" in line or ("encounter_begin" in line and "encounter[soak=" in line):
            start = i
            break
        if line.begins_with("soak_fight_end"):
            start = i + 1
            break
    var out: PackedStringArray = PackedStringArray()
    for j in range(start, lines.size()):
        out.append(lines[j])
    return out


static func _normalize_fixture_lines(lines: PackedStringArray) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    for raw in lines:
        out.append(_combat_line(raw))
    return out


static func _find_line(lines: PackedStringArray, needle: String) -> String:
    for raw in lines:
        var line: String = _combat_line(raw)
        if needle in line:
            return line
    return ""


static func _parse_kv_token(line: String, key: String) -> String:
    var idx: int = line.find(key)
    if idx < 0:
        return ""
    var tail: String = line.substr(idx + key.length())
    var space: int = tail.find(" ")
    if space < 0:
        return tail.strip_edges()
    return tail.substr(0, space).strip_edges()


static func _parse_ambient_metric(line: String, key: String) -> float:
    if line.is_empty():
        return -1.0
    var idx: int = line.find(key)
    if idx < 0:
        return -1.0
    var tail: String = line.substr(idx + key.length()).strip_edges()
    var end: int = 0
    while end < tail.length():
        var c: String = tail[end]
        if c.is_valid_float() or c == "." or c == "-":
            end += 1
        else:
            break
    if end <= 0:
        return -1.0
    return float(tail.substr(0, end))


static func _blob_has(lines: PackedStringArray, needle: String) -> bool:
    for raw in lines:
        if needle in _combat_line(raw):
            return true
    return false


static func _combat_line(raw: String) -> String:
    var s: String = str(raw).strip_edges()
    if s.begins_with(_OperationalLog.TAG_COMBAT + ":"):
        return s.substr(_OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
    return s


static func _is_grep_hint_line(line: String) -> bool:
    var s: String = line.strip_edges()
    if s.begins_with("soak_guide ") or s.begins_with("soak_session_plan "):
        return true
    if s.begins_with("soak_validate_hint ") or s.begins_with("soak_coverage "):
        return true
    if "grep SCRIPT" in s or "grep FP_ERROR" in s:
        return true
    if s.begins_with("FP_SESSION_BEGIN:") or s.begins_with("FP_SESSION_END:"):
        return true
    return false
