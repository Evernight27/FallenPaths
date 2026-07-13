class_name CombatD001SoakSanityPartA
extends RefCounted

## Headless **D-001** plausibility + validator cross-checks (grep needles vs log semantics).
## Called from **`CombatD001SoakRunner._evaluate`**, **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE=sanity` .
## `d001_presets`).

const BattleScene := preload("res://ui/BattleScene.gd")

const II6_PROBE_CUT: float = 22.0
const II6_PROBE_BLUNT: float = 22.0
const II6_PROBE_BV_PCT: float = 58.0

const RUNNER_NAME := "CombatD001SoakSanity"


static func _run_validator_fixture_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var good_ii5: PackedStringArray = PackedStringArray(
        [
            "%s: soak_fight_enter tile=cyan preset=ii5" % OperationalLog.TAG_COMBAT,
            "soak=ii5",
            "soak_setup ii5 leader armless",
            "cowering_fall_back listed for Leader",
            "cowering_fall_back pick Leader target_id=0",
            "cowering_fall_back executed Leader rank 0->1 file 0",
            "soak_fight_end winner=player medical_phase=false fight_profile=ii5",
        ]
    )
    var r5: Dictionary = CombatF5SoakLogValidator.validate(
        CombatD001SoakSanityPartB._normalize_fixture_lines(good_ii5),
        PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II5])
    )
    if not bool(r5.get("ok", false)):
        failures.append(
            "fixture_ii5_good: %s" % ", ".join(r5.get("failures", PackedStringArray()) as PackedStringArray)
        )

    var amb_line: String = CombatD001SoakSanityPartA._ii6_expected_ambient_log_line()
    var good_ii6: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58",
            "soak=ii6",
            amb_line,
            "soak_fight_end winner=player medical_phase=false fight_profile=ii6",
        ]
    )
    var r6: Dictionary = CombatF5SoakLogValidator.validate(
        good_ii6, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II6])
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
    var r5b: Dictionary = CombatF5SoakLogValidator.validate(
        bad_missing_listed, PackedStringArray([CombatD001TrackSpecs.PROFILE_PRESET_II5])
    )
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
    var r2b: Dictionary = CombatF5SoakLogValidator.validate(
        good_ii2b, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II2B])
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
    var rwf: Dictionary = CombatF5SoakLogValidator.validate(
        good_wf_m3, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    )
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
    var rwf_bad: Dictionary = CombatF5SoakLogValidator.validate(
        bad_wf_m3, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    )
    var bad_tracks: Dictionary = rwf_bad.get("tracks", {}) as Dictionary
    var grd_tr: Dictionary = bad_tracks.get("wf_m3_grd_before_form", {}) as Dictionary
    if bool(grd_tr.get("pass", false)):
        failures.append("fixture_wf_m3_bad: wf_m3_grd_before_form should fail without Grd/Atk before Form")

    var leak_wf_m3: PackedStringArray = PackedStringArray(
        [
            "turn_ready_gauge id=0 Leader label=Stm 92% . Ready . Step tooltip_match=melee_only",
        ]
    )
    var rwf_leak: Dictionary = CombatF5SoakLogValidator.validate(
        leak_wf_m3, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    )
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
    var rcamp: Dictionary = CombatF5SoakLogValidator.validate(
        good_camp, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_CAMP_EA])
    )
    if CombatD001TrackSpecs.PROFILE_CAMP_EA not in (rcamp.get("profiles", PackedStringArray()) as PackedStringArray):
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
    var camp_wf_profiles: PackedStringArray = CombatD001TrackSpecs.detect_profiles(camp_wf_smoke)
    var rcw: Dictionary = CombatF5SoakLogValidator.validate(camp_wf_smoke, camp_wf_profiles)
    if CombatD001TrackSpecs.PROFILE_CAMP_EA not in camp_wf_profiles:
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
    var rmopup: Dictionary = CombatF5SoakLogValidator.validate(
        good_mopup, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
    )
    var mop_tr: Dictionary = (rmopup.get("tracks", {}) as Dictionary).get("camp_mopup_strike_finish", {}) as Dictionary
    if not bool(mop_tr.get("pass", false)):
        failures.append("fixture_camp_mopup: camp_mopup_strike_finish should pass with strikes_listed")

    var bad_mopup: PackedStringArray = PackedStringArray(
        [
            (
                "engagement_debug turn side=player id=0 mop_up=true rotate_suppress=true "
                + "menu=reserve_only strikes=0 pick=attempt_close"
            ),
        ]
    )
    var rmopup_bad: Dictionary = CombatF5SoakLogValidator.validate(
        bad_mopup, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
    )
    var mop_bad_tr: Dictionary = (
        (rmopup_bad.get("tracks", {}) as Dictionary).get("camp_mopup_strike_finish", {}) as Dictionary
    )
    if bool(mop_bad_tr.get("pass", false)):
        failures.append("fixture_camp_mopup_bad: camp_mopup_strike_finish should fail on reserve_only stall")

    var good_line_plug: PackedStringArray = PackedStringArray(
        [
            (
                "engagement_debug turn id=0 Rear file=0 rank=1 menu=formation bands=LONG "
                + "opposed=Front mapped_opp=true wing_lack=false mop_up=false "
                + "rotate_suppress=false sparse_line=false line_plug=true pick=swap_rank "
                + "layer=formation_plug line_plug_pick=1"
            ),
        ]
    )
    var rplug: Dictionary = CombatF5SoakLogValidator.validate(
        good_line_plug, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
    )
    var plug_tr: Dictionary = (rplug.get("tracks", {}) as Dictionary).get("camp_line_plug_pick", {}) as Dictionary
    if not bool(plug_tr.get("pass", false)):
        failures.append("fixture_line_plug: camp_line_plug_pick should pass with line_plug_pick=1")

    var good_rotate_plug: PackedStringArray = PackedStringArray(
        [
            (
                "engagement_debug turn id=0 Front file=0 rank=0 menu=formation bands=LONG "
                + "opposed=Enemy mapped_opp=true wing_lack=false mop_up=false "
                + "rotate_suppress=false sparse_line=false line_plug=true pick=rotate_file "
                + "layer=formation_plug line_plug_pick=1"
            ),
        ]
    )
    var rrot: Dictionary = CombatF5SoakLogValidator.validate(
        good_rotate_plug, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
    )
    var rot_tr: Dictionary = (rrot.get("tracks", {}) as Dictionary).get("camp_line_plug_pick", {}) as Dictionary
    if not bool(rot_tr.get("pass", false)):
        failures.append("fixture_line_plug_rotate: camp_line_plug_pick should pass for rotate_file pick")

    var good_formation_layer: PackedStringArray = PackedStringArray(
        [
            (
                "engagement_debug turn id=0 Rear file=0 rank=1 menu=formation bands=LONG "
                + "opposed=Front mapped_opp=true wing_lack=false mop_up=false "
                + "rotate_suppress=false sparse_line=false line_plug=true pick=swap_rank "
                + "layer=formation_plug line_plug_pick=1"
            ),
        ]
    )
    var rlayer: Dictionary = CombatF5SoakLogValidator.validate(
        good_formation_layer, PackedStringArray([CombatD001TrackSpecs.PROFILE_PRESET_II_ENVELOP])
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
    var rmopup_hold: Dictionary = CombatF5SoakLogValidator.validate(
        good_mopup_hold,
        PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II_ENVELOP])
    )
    var mopup_hold_tr: Dictionary = (
        (rmopup_hold.get("tracks", {}) as Dictionary).get("ii_envelop_mopup_hold_hint", {}) as Dictionary
    )
    if not bool(mopup_hold_tr.get("pass", false)):
        failures.append("fixture_mopup_hold_line: ii_envelop_mopup_hold_hint should pass on mopup_hold_line_list")

    var good_sparse_hold: PackedStringArray = PackedStringArray(
        [
            (
                "mopup_hold_line_list id=4 Companion5 hint=Line open after rout  -  close in or strike; "
                + "shuffle won't fill distant gaps."
            ),
        ]
    )
    var rsparse_hold: Dictionary = CombatF5SoakLogValidator.validate(
        good_sparse_hold, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
    )
    var sparse_hold_stats: Dictionary = rsparse_hold.get("grep_stats", {}) as Dictionary
    if int(sparse_hold_stats.get("mopup_gauge_hint", 0)) < 1:
        failures.append("fixture_sparse_hold_line: mopup_gauge_hint should count mopup_hold_line_list sparse copy")

    var good_sparse_gauge: PackedStringArray = PackedStringArray(
        [
            (
                "mopup_hold_line_list id=4 Companion5 hint=Line open after rout  -  close in or strike; "
                + "shuffle won't fill distant gaps."
            ),
            "turn_ready_gauge id=4 Companion5 label=Ready . Focus head 78% tooltip_match=hold_line",
        ]
    )
    var rsparse_gauge: Dictionary = CombatF5SoakLogValidator.validate(
        good_sparse_gauge, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
    )
    var sparse_gauge_stats: Dictionary = rsparse_gauge.get("grep_stats", {}) as Dictionary
    if int(sparse_gauge_stats.get("tooltip_hold_line", 0)) < 1:
        failures.append("fixture_sparse_hold_gauge: tooltip_hold_line should count fight-finish hold_line match")

    var good_mopup_hold_close: PackedStringArray = PackedStringArray(
        [
            "mopup_hold_line_list id=1 Rear hint=Mop-up  -  finish the last enemy; close in or strike.",
        ]
    )
    var rmopup_hold_close: Dictionary = CombatF5SoakLogValidator.validate(
        good_mopup_hold_close,
        PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II_ENVELOP])
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
    var rmopup_fp: Dictionary = CombatF5SoakLogValidator.validate(
        mopup_false_positives,
        PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II_ENVELOP])
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
            (
                "controlling_close_list id=0 Leader hint=Close is harder vs Fool  -  strike from range or "
                + "commit with strength."
            ),
        ]
    )
    var rctrl: Dictionary = CombatF5SoakLogValidator.validate(
        good_ctrl_close, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    )
    var ctrl_tr: Dictionary = (rctrl.get("tracks", {}) as Dictionary).get("wf_controlling_close_hint", {}) as Dictionary
    if not bool(ctrl_tr.get("pass", false)):
        failures.append("fixture_wf_controlling_close: wf_controlling_close_hint should pass on controlling_close_list")

    var ctrl_false_positives: PackedStringArray = PackedStringArray(
        [
            "[wf_controlling_close_hint] PASS  -  count=1 need>=1",
            "soak_setup wf_controlling_close_hint ok",
        ]
    )
    var rctrl_fp: Dictionary = CombatF5SoakLogValidator.validate(
        ctrl_false_positives, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    )
    var ctrl_fp_tr: Dictionary = (
        (rctrl_fp.get("tracks", {}) as Dictionary).get("wf_controlling_close_hint", {}) as Dictionary
    )
    if bool(ctrl_fp_tr.get("pass", false)):
        failures.append("fixture_wf_controlling_close_false_positive: must not pass on report/setup echo lines")

    var good_incap_plug: PackedStringArray = PackedStringArray(
        [
            (
                "engagement_debug turn id=1 Rear file=0 rank=1 menu=formation bands=LONG "
                + "opposed=Front mapped_opp=true wing_lack=false mop_up=false "
                + "rotate_suppress=false sparse_line=false line_plug=true pick=swap_rank "
                + "layer=formation_plug line_plug_pick=1"
            ),
        ]
    )
    var rincap: Dictionary = CombatF5SoakLogValidator.validate(
        good_incap_plug, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_7V7])
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
    var rcontract: Dictionary = CombatF5SoakLogValidator.validate(
        contract_settle, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_CAMP_EA])
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
            (
                "party_triage_open living=7 untreated=2 bleeding=1 parts_need_dressing=3 med_left=12 "
                + "bandage_med_est=3 camp_med=1 total_med_est=4 med_shortfall=0"
            ),
        ]
    )
    var rext: Dictionary = CombatF5SoakLogValidator.validate(
        camp_extended, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_CAMP_EA])
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
    var rfp: Dictionary = CombatF5SoakLogValidator.validate(
        false_positives, PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_CAMP_EA])
    )
    for fp_id in ["camp_party_triage", "camp_field_care_action"]:
        var fp_tr: Dictionary = (rfp.get("tracks", {}) as Dictionary).get(fp_id, {}) as Dictionary
        if bool(fp_tr.get("pass", false)):
            failures.append("fixture_camp_false_positive: %s must not pass on echo/failed/hint lines" % fp_id)

    var soak_echo_only: PackedStringArray = PackedStringArray(
        [
            "soak_coverage camp warn [camp_settlement_continue] count=0 need>=1",
            "soak_coverage camp next [camp_party_triage] open Party on map (grep party_triage_open living=)",
            (
                "soak_coverage camp next [camp_paid_loss] lose a paid contract "
                + "(grep company_run_end reason=contract_failed reload=true)"
            ),
            "turn_ready_gauge id=0 Leader label=Stm 84% . Ready . Grd HiR . Form Ox",
        ]
    )
    if CombatD001TrackSpecs.PROFILE_CAMP_EA in CombatD001TrackSpecs.detect_profiles(soak_echo_only):
        failures.append("fixture_camp_ea_detect: soak_coverage echoes must not activate camp_ea profile")

    var step9_raw: PackedStringArray = PackedStringArray(
        [
            "FP_WORLD: company_run_end reason=tutorial_failed reload=false",
            "FP_WORLD: company_wages: gold=10 below next wage bill=35 (day 4)",
            "FP_WORLD: desertion summary=Ally(mood=12)",
        ]
    )
    var rstep9: Dictionary = CombatF5SoakLogValidator.validate(step9_raw)
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
        var step9_file: PackedStringArray = CombatF5SoakLogValidator._decode_f5_log_text(
            FileAccess.get_file_as_string(step9_doc)
        )
        var rstep9_file: Dictionary = CombatF5SoakLogValidator.validate(step9_file)
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
    if CombatD001SoakSanityPartB._ii5_plausibility_failures(missing_exec).is_empty():
        failures.append("fixture_ii5: should require executed line")

    var good_ii5: PackedStringArray = PackedStringArray(
        [
            "cowering_fall_back listed for Leader",
            "cowering_fall_back executed Leader rank 0->1 file 0",
        ]
    )
    if not CombatD001SoakSanityPartB._ii5_plausibility_failures(good_ii5).is_empty():
        failures.append("fixture_ii5: valid sample should pass")

    var setup_hint_only: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58 (grep ambient_pain_shock on Companion)",
            "soak=ii6",
        ]
    )
    if CombatD001SoakSanityPartB._ii6_plausibility_failures(setup_hint_only).is_empty():
        failures.append("fixture_ii6_hint: setup grep hint must not satisfy ambient Companion")

    var thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    var low_pain: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58",
            "ambient_pain_shock Companion effective_pain=%.1f duration=5.0s" % (thresh - 0.5),
        ]
    )
    if CombatD001SoakSanityPartB._ii6_plausibility_failures(low_pain).is_empty():
        failures.append("fixture_ii6_pain: effective_pain below threshold should fail")

    var good_ii6: PackedStringArray = PackedStringArray(
        [
            "soak_setup ii6 companion chest wounded bv=58",
            CombatD001SoakSanityPartA._ii6_expected_ambient_log_line(),
        ]
    )
    if not CombatD001SoakSanityPartB._ii6_plausibility_failures(good_ii6).is_empty():
        failures.append("fixture_ii6_pain: valid ambient sample should pass")

    var bad_profile: PackedStringArray = PackedStringArray(
        [
            "soak=ii5",
            "soak_fight_end winner=player fight_profile=ii6",
        ]
    )
    if (
        CombatD001SoakSanityPartB
        . _common_log_plausibility_failures(SoakEncounterPresets.PRESET_II5_COWERING, bad_profile)
        . is_empty()
    ):
        failures.append("fixture_common: fight_profile must match preset")

    var conflicting_winners: PackedStringArray = PackedStringArray(
        [
            "soak_fight_enter preset=ii5",
            "soak_fight_end winner=player",
            "soak_fight_end winner=enemy",
        ]
    )
    if (
        CombatD001SoakSanityPartB
        . _common_log_plausibility_failures(SoakEncounterPresets.PRESET_II5_COWERING, conflicting_winners)
        . is_empty()
    ):
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
        CombatD001SoakSanityPartB
        . _common_log_plausibility_failures(
            SoakEncounterPresets.PRESET_II5_COWERING, CombatD001SoakSanityPartB._lines_for_last_fight(multi_fight_retry)
        )
        . is_empty()
    ):
        failures.append("fixture_common: last-fight scope should ignore prior fight winner")

    var end_before_enter: PackedStringArray = PackedStringArray(
        [
            "soak_fight_end winner=player",
            "soak_fight_enter preset=ii5",
        ]
    )
    if (
        CombatD001SoakSanityPartB
        . _common_log_plausibility_failures(SoakEncounterPresets.PRESET_II5_COWERING, end_before_enter)
        . is_empty()
    ):
        failures.append("fixture_common: fight enter should precede fight end")

    return failures


static func _run_profile_detection_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    for preset_id in SoakEncounterPresets.D001_PRESET_RUN_ORDER:
        var profile: String = CombatD001TrackSpecs.preset_id_to_profile(preset_id)
        if profile.is_empty():
            failures.append("profile_map: missing profile for %s" % preset_id)
            continue
        var markers: PackedStringArray = CombatD001TrackSpecs.synthetic_profile_markers(preset_id)
        if markers.is_empty():
            continue
        var detected: PackedStringArray = CombatD001TrackSpecs.detect_profiles(markers)
        if profile not in detected:
            failures.append(
                "detect_profiles: %s expected %s from %s got %s" % [preset_id, profile, str(markers), str(detected)]
            )
    var detected_7v7: PackedStringArray = CombatD001TrackSpecs.detect_profiles(
        PackedStringArray(["soak_fight_enter tile=red 7v7", "soak=7v7"])
    )
    if CombatD001TrackSpecs.PROFILE_7V7 not in detected_7v7:
        failures.append("detect_profiles: 7v7 markers should activate profile_7v7")
    var detected_camp: PackedStringArray = CombatD001TrackSpecs.detect_profiles(
        CombatD001TrackSpecs.synthetic_profile_markers("camp_ea")
    )
    if CombatD001TrackSpecs.PROFILE_CAMP_EA not in detected_camp:
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
    var ii5_slice: PackedStringArray = CombatD001TrackSpecs.slice_lines_for_soak_preset(
        mixed, SoakEncounterPresets.PRESET_II5_COWERING
    )
    if ii5_slice.is_empty() or not CombatD001SoakSanityPartB._blob_has(ii5_slice, "cowering_fall_back listed"):
        failures.append("slice_ii5: should capture ii5 fight lines only")
    if CombatD001SoakSanityPartB._blob_has(ii5_slice, "ambient_pain_shock"):
        failures.append("slice_ii5: must not include ii6 ambient lines")

    var ii6_slice: PackedStringArray = CombatD001TrackSpecs.slice_lines_for_soak_preset(
        mixed, SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK
    )
    if not CombatD001SoakSanityPartB._blob_has(ii6_slice, "ambient_pain_shock Companion"):
        failures.append("slice_ii6: should capture ii6 ambient line")
    if CombatD001SoakSanityPartB._blob_has(ii6_slice, "cowering_fall_back"):
        failures.append("slice_ii6: must not include ii5 cowering lines")

    var empty: PackedStringArray = CombatD001TrackSpecs.slice_lines_for_soak_preset(mixed, "ii99")
    if not empty.is_empty():
        failures.append("slice_unknown: unknown preset should yield empty slice")

    return failures


static func _run_ii5_world_formation_meta_fixture() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var world := Node2D.new()
    SoakEncounterPresets.apply_world_post_setup(world, SoakEncounterPresets.PRESET_II5_COWERING)
    if not world.has_meta("party_formation"):
        failures.append("ii5_world: missing party_formation meta")
    else:
        var pf: Dictionary = world.get_meta("party_formation") as Dictionary
        if int(pf.get("files", 0)) != 2 or int(pf.get("ranks", 0)) != 3:
            failures.append("ii5_world: want files=2 ranks=3 (loose 2x3)")
        if str(pf.get("line_discipline", "")) != CombatConstants.LINE_DISCIPLINE_LOOSE:
            failures.append("ii5_world: want line_discipline loose")
    if (
        not world.has_meta(SoakEncounterPresets.WORLD_META_LOCK_PARTY_FORMATION)
        or not bool(world.get_meta(SoakEncounterPresets.WORLD_META_LOCK_PARTY_FORMATION))
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
    if CombatD001TrackSpecs.ii2b_plausibility_failures(too_low).is_empty():
        failures.append("fixture_ii2b_parry: empty stats should fail plausibility")

    var bind_heavy: Dictionary = {
        "parry_deflect": 1,
        "parry_bind": 9,
        "parry_partial": 0,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if CombatD001TrackSpecs.ii2b_plausibility_failures(bind_heavy).is_empty():
        failures.append("fixture_ii2b_parry: bind dominating deflect should fail")

    var good: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 1,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if not CombatD001TrackSpecs.ii2b_plausibility_failures(good).is_empty():
        failures.append("fixture_ii2b_parry: balanced stats should pass")

    var partial_leak: Dictionary = {
        "parry_deflect": 1,
        "parry_bind": 1,
        "parry_partial": 20,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if CombatD001TrackSpecs.ii2b_plausibility_failures(partial_leak).is_empty():
        failures.append("fixture_ii2b_parry: excessive partial vs clean outcomes should fail")

    return failures


static func _run_exhaustion_plausibility_fixtures() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var no_band: Dictionary = {"crossed_25": 0, "crossed_50": 0, "exhaustion_log": 0}
    if CombatD001TrackSpecs.ii4d_plausibility_failures(no_band, true).is_empty():
        failures.append("fixture_ii4d: missing band crossings should fail")

    var no_gauge: Dictionary = {"crossed_25": 1, "crossed_50": 1, "exhaustion_log": 2}
    if CombatD001TrackSpecs.ii4d_plausibility_failures(no_gauge, false).is_empty():
        failures.append("fixture_ii4d: missing gauge Exh suffix should fail")

    var good: Dictionary = {"crossed_25": 1, "crossed_50": 0, "crossed_75": 0, "exhaustion_log": 3}
    if not CombatD001TrackSpecs.ii4d_plausibility_failures(good, true).is_empty():
        failures.append("fixture_ii4d: minimal band + gauge should pass")

    return failures


static func _run_numeric_formula_tests() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    if absf(thresh - PainConsciousnessConstants.NRS_SHOCK) > 0.001:
        failures.append(
            "numeric: shock threshold %.2f want NRS_SHOCK %.1f" % [thresh, PainConsciousnessConstants.NRS_SHOCK]
        )
    var probe_ent: CoreEntity = CombatD001SoakSanityPartA._ii6_probe_entity()
    var pain_probe: float = EntityPainConsciousness.get_effective_pain_for_thresholds(probe_ent)
    var dur_probe: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain_probe, 0.0)
    var want_dur: float = PainConsciousnessConstants.PAIN_SHOCK_DURATION_BASE * (pain_probe / thresh)
    if absf(dur_probe - want_dur) > 0.001:
        failures.append("numeric: duration(pain)=%.3f want %.3f" % [dur_probe, want_dur])
    if pain_probe <= thresh:
        failures.append("numeric: ii6 probe pain %.2f must exceed threshold %.2f" % [pain_probe, thresh])
    var interval: float = PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    if interval <= 0.0 or interval > 10.0:
        failures.append("numeric: ambient check interval %.1fs out of band" % interval)
    return failures


static func _run_ii6_wound_probe() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var was_on: bool = CombatConstants.is_feature_ambient_pain_shock()
    CombatConstants.set_feature_ambient_pain_shock(true)
    var ent: CoreEntity = CombatD001SoakSanityPartA._ii6_probe_entity()
    var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(ent)
    var thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    var dur: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain, 0.0)
    if pain <= thresh:
        failures.append("ii6_probe: effective_pain %.2f must exceed threshold %.2f" % [pain, thresh])
    var log_line: String = CombatD001SoakSanityPartA._ii6_ambient_log_line_for_entity(ent)
    var parsed_pain: float = CombatD001SoakSanityPartB._parse_ambient_metric(log_line, "effective_pain=")
    var parsed_dur: float = CombatD001SoakSanityPartB._parse_ambient_metric(log_line, "duration=")
    if absf(parsed_pain - snapped(pain, 0.1)) > 0.05:
        failures.append("ii6_probe: log pain %.1f vs computed %.2f" % [parsed_pain, pain])
    if absf(parsed_dur - snapped(dur, 0.1)) > 0.05:
        failures.append("ii6_probe: log duration %.1f vs computed %.2f" % [parsed_dur, dur])
    var entered: bool = false
    var interval: float = PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    ent._ambient_pain_shock_accum = interval - 0.001
    for _i in 80:
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
            entered = true
            break
        ent._ambient_pain_shock_accum = interval - 0.001
    if not entered:
        failures.append("ii6_probe: ambient shock should enter within 80 ticks (pain=%.2f)" % pain)
    if not was_on:
        CombatConstants.set_feature_ambient_pain_shock(false)
    return failures


static func _ii6_probe_entity() -> CoreEntity:
    var ent: CoreEntity = CoreEntity.new()
    ent.apply_species()
    ent.dominant_hand = "right_arm"
    ent.offhand_functionality = 1.0
    var w: Weapon = Weapon.create_from_definition("SWORD")
    if w != null:
        ent.equip_weapon(w)
    ent.take_damage_split(II6_PROBE_CUT, II6_PROBE_BLUNT, "chest")
    ent.blood_volume = II6_PROBE_BV_PCT
    ent._pain_shock_until_time = -1.0
    ent._ambient_pain_shock_accum = 0.0
    CombatRegressionHarness._track_harness_node(ent)
    return ent


static func _ii6_expected_ambient_log_line() -> String:
    return CombatD001SoakSanityPartA._ii6_ambient_log_line_for_entity(CombatD001SoakSanityPartA._ii6_probe_entity())


static func _ii6_ambient_log_line_for_entity(ent: CoreEntity) -> String:
    var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(ent)
    var dur: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain, 0.0)
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
    var stats: Dictionary = CombatD001TrackSpecs.parry_stats_from_summary_line(line)
    if int(stats.get("parry_deflect", 0)) != 4 or int(stats.get("parry_bind", 0)) != 1:
        failures.append("fixture_parry_summary: parse failed for deflect/bind")
    if not CombatD001TrackSpecs.ii2b_plausibility_failures(stats).is_empty():
        failures.append("fixture_parry_summary: d001 sample line should pass ii2b plausibility")
    var weak: Dictionary = CombatD001TrackSpecs.parry_stats_from_summary_line(
        "parry_stats deflect=0 bind=0 partial=0 riposte=0 counter_tempo=0 flurry_opened=0 flurry=0"
    )
    if CombatD001TrackSpecs.ii2b_plausibility_failures(weak).is_empty():
        failures.append("fixture_parry_summary: empty stats should fail ii2b plausibility")
    return failures


static func _run_ii6_capture_slice_fixture() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var amb: String = CombatD001SoakSanityPartA._ii6_expected_ambient_log_line()
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
    var slice: PackedStringArray = CombatD001TrackSpecs.slice_lines_for_soak_preset(
        blob, SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK
    )
    if not CombatD001SoakSanityPartB._ii6_plausibility_failures(slice).is_empty():
        failures.append("fixture_ii6_slice: sliced ii6 capture should pass plausibility")
    if CombatD001SoakSanityPartB._blob_has(slice, "cowering_fall_back"):
        failures.append("fixture_ii6_slice: must not include ii5 lines")
    return failures


static func _run_track_crosswalk_tests() -> PackedStringArray:
    return CombatD001TrackSpecs.headless_validator_coverage_failures()


static func _run_f5_soak_trace_fixtures() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    CombatF5SoakTrace.reset_session_camp_trace()
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    CombatF5SoakTrace.note_medical_pack_listed("Leader", "chest")
    var end_warn: int = 0
    var coverage_ok: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = CombatD001SoakSanityPartB._combat_line(raw)
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
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    var exit_mgr: Node = CombatManager.new()
    exit_mgr.medical_phase = true
    exit_mgr.medical_phase_winner = "player"
    exit_mgr.finish_battle()
    var early_exit_cov: int = 0
    var medical_exit_log: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = CombatD001SoakSanityPartB._combat_line(raw)
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
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    CombatF5SoakTrace.note_medical_pack_listed("Leader", "chest")
    var camp_world: Node2D = Node2D.new()
    camp_world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var camp_battle: Node = BattleScene.new()
    camp_battle.parent_scene = camp_world
    var camp_mgr: Node = CombatManager.new()
    camp_battle.add_child(camp_mgr)
    camp_mgr.medical_phase = true
    camp_mgr.medical_phase_winner = "player"
    if not bool(camp_mgr.call("_is_campaign_contract_battle")):
        failures.append("f5_trace_camp_med_exit_refresh: harness battle should resolve contract world")
    camp_mgr.finish_battle()
    var exit_log: int = 0
    var camp_med_refresh: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = CombatD001SoakSanityPartB._combat_line(raw)
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
    OperationalLog.play_world("settlement_continue paid=120 renown=1")
    var camp_header: int = 0
    var camp_day_pass: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = CombatD001SoakSanityPartB._combat_line(raw)
        if body.begins_with("soak_coverage camp ok="):
            camp_header += 1
    if camp_header < 1:
        failures.append("f5_trace_camp_supplement: want soak_coverage camp header got %d" % camp_header)
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.log_fight_end_summary("player", false)
    OperationalLog.play_world("company_day_advanced day=2 wages_paid=105 gold=395 living=7")
    for raw in OperationalLog.get_captured_lines():
        var body: String = CombatD001SoakSanityPartB._combat_line(raw)
        if body.begins_with("soak_coverage camp pass [camp_company_day]"):
            camp_day_pass += 1
    if camp_day_pass < 1:
        failures.append("f5_trace_camp_supplement: camp_company_day pass after company_day_advanced (session merge)")
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("test", "", false, true)
    CombatF5SoakTrace.ingest_trace_line(
        "engagement_debug turn 12 mop_up=true menu=strikes_listed strikes=17" + " sparse=false line_plug=false"
    )
    CombatF5SoakTrace.log_fight_end_summary("player", false)
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    CombatF5SoakTrace.log_fight_end_summary("enemy", false)
    OperationalLog.play_world("company_run_end reason=contract_failed reload=true")
    var mopup_session_pass: int = 0
    var mopup_session_warn: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = CombatD001SoakSanityPartB._combat_line(raw)
        if body.begins_with("soak_coverage camp pass [camp_mopup_strike_finish]"):
            mopup_session_pass += 1
        if body.begins_with("soak_coverage camp warn [camp_mopup_strike_finish]"):
            mopup_session_warn += 1
    if mopup_session_pass < 1:
        failures.append(
            (
                "f5_trace_camp_session_combat: want camp_mopup_strike_finish pass after prior fight archive got pas"
                + "s=%d warn=%d" % [mopup_session_pass, mopup_session_warn]
            )
        )
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)
    return failures

# --- per-preset log plausibility ---
