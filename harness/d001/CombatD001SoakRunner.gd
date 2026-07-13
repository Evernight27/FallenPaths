class_name CombatD001SoakRunner
extends RefCounted
## Headless **D-001** preset fights: simulates F5 cyan soaks, captures **`FP_COMBAT`**, parses runbook grep targets.
## Mandatory **II-2b / II-5a - c** sign-off is headless-only via plausibility + **`BattleUIUpdater`** probes (see
## **`.d001_headless_signoff.txt`**).
## **ii5c** (`_run_ii5c_gauge_label_checks`): **`Stm`/`Ready`/`Exh`/`Grd`** + WF gauge/diagram suffix order (incl.
## **`form_wrath_*`**)  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`**.

const RUNNER_NAME := "CombatD001SoakRunner"
const TICK_DT := 0.05


static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    var preset_results: Dictionary = {}
    var aggregate_lines: PackedStringArray = PackedStringArray()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.begin_play_session("headless://d001-soak", "")
    CombatConstants.set_feature_ambient_pain_shock(true)
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    for preset_id in SoakEncounterPresets.D001_PRESET_RUN_ORDER:
        OperationalLog.clear_capture()
        seed(D001PresetRunnerTests._preset_seed(preset_id))
        var pr: Dictionary = D001PresetRunnerTests._run_preset(preset_id)
        preset_results[preset_id] = pr
        for line in OperationalLog.get_captured_lines():
            aggregate_lines.append(line)
        if not bool(pr.get("ok", false)):
            failures.append("%s: %s" % [preset_id, str(pr.get("summary", "failed"))])
    OperationalLog.clear_capture()
    FallenPathsErrorLogger.reset_script_error_count()
    seed(D001PresetRunnerTests._preset_seed("7v7"))
    var pr7: Dictionary = D001PresetRunnerTests._run_7v7_brawl()
    preset_results["7v7"] = pr7
    for line in OperationalLog.get_captured_lines():
        aggregate_lines.append(line)
    if not bool(pr7.get("ok", false)):
        failures.append("7v7: %s" % str(pr7.get("summary", "failed")))
    var ui_pr: Dictionary = D001PresetRunnerTests._run_ii5c_gauge_label_checks()
    preset_results["ii5c"] = ui_pr
    if not bool(ui_pr.get("ok", false)):
        failures.append("ii5c: %s" % str(ui_pr.get("summary", "failed")))
    OperationalLog.clear_capture()
    var ii5a_pr: Dictionary = D001PresetRunnerTests._run_ii5a_formation_hint_checks()
    preset_results["ii5a"] = ii5a_pr
    if not bool(ii5a_pr.get("ok", false)):
        failures.append("ii5a: %s" % str(ii5a_pr.get("summary", "failed")))
    var ii5b_pr: Dictionary = D001PresetRunnerTests._run_ii5b_log_policy_checks(aggregate_lines)
    preset_results["ii5b"] = ii5b_pr
    if not bool(ii5b_pr.get("ok", false)):
        failures.append("ii5b: %s" % str(ii5b_pr.get("summary", "failed")))
    var ii1e_pr: Dictionary = D001PresetRunnerTests._run_ii1e_engagement_label_checks()
    preset_results["ii1e"] = ii1e_pr
    if not bool(ii1e_pr.get("ok", false)):
        failures.append("ii1e: %s" % str(ii1e_pr.get("summary", "failed")))
    OperationalLog.clear_capture()
    var ii7_pr: Dictionary = D001PresetRunnerTests._run_ii7_medical_phase_smoke()
    preset_results["ii7"] = ii7_pr
    for line in OperationalLog.get_captured_lines():
        aggregate_lines.append(line)
    if not bool(ii7_pr.get("ok", false)):
        failures.append("ii7: %s" % str(ii7_pr.get("summary", "failed")))
    OperationalLog.clear_capture()
    var fm_pr: Dictionary = D001PresetRunnerTests._run_formation_move_f5_smoke()
    preset_results["formation_move_f5"] = fm_pr
    for line in OperationalLog.get_captured_lines():
        aggregate_lines.append(line)
    if not bool(fm_pr.get("ok", false)):
        failures.append("formation_move_f5: %s" % str(fm_pr.get("summary", "failed")))
    OperationalLog.clear_capture()
    D001PresetRunnerTests._probe_wf_controlling_close_turn_hint()
    for line in OperationalLog.get_captured_lines():
        aggregate_lines.append(line)
    OperationalLog.clear_capture()
    OperationalLog.write_f5_soak_capture(aggregate_lines)
    var val_r: Dictionary = CombatF5SoakLogValidator.validate(aggregate_lines)
    if not bool(val_r.get("ok", false)):
        for f in val_r.get("failures", PackedStringArray()) as PackedStringArray:
            failures.append("f5_log_validator: %s" % f)
    var sanity: Dictionary = CombatD001SoakSanity.run_all()
    if not bool(sanity.get("ok", false)):
        for msg in sanity.get("failures", PackedStringArray()) as PackedStringArray:
            failures.append("soak_sanity: %s" % msg)
    var ok: bool = failures.is_empty()
    var mandatory_fail: PackedStringArray = CombatD001TrackSpecs.headless_mandatory_signoff_failures(preset_results)
    for msg in mandatory_fail:
        failures.append("mandatory_signoff: %s" % msg)
    ok = failures.is_empty()
    OperationalLog.write_d001_soak_report(ok, preset_results, failures)
    var ii2b_pr: Dictionary = preset_results.get(SoakEncounterPresets.PRESET_II2B_SWORD_DUEL, {}) as Dictionary
    var ii2b_signed: bool = bool(ii2b_pr.get("ii2b_plausibility_ok", false)) and bool(ii2b_pr.get("ok", false))
    if ii2b_pr.has("parry_stats"):
        OperationalLog.write_ii2b_worksheet_prefill(ii2b_pr.get("parry_stats", {}) as Dictionary, ii2b_signed)
    OperationalLog.write_d001_headless_signoff(ok, preset_results, bool(val_r.get("ok", false)))
    CombatF5SoakLogValidator.write_report(val_r)
    if ok:
        OperationalLog.harness_ok(
            RUNNER_NAME, "presets=%d+7v7+ii5a+ii5b+ii5c+ii7+ii1e" % SoakEncounterPresets.D001_PRESET_RUN_ORDER.size()
        )
    else:
        OperationalLog.harness_fail(RUNNER_NAME, failures)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)
    return {
        "ok": ok,
        "failures": failures,
        "presets": preset_results,
        "harness_ok_emitted": true,
    }


## Headless subset (e.g. **`ii5`** + **`ii6`**)  -  same checks as **`run_all`**, without other presets.


## Headless subset (e.g. **`ii5`** + **`ii6`**)  -  same checks as **`run_all`**, without other presets.
static func run_preset_ids(preset_ids: PackedStringArray) -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    var sanity: Dictionary = CombatD001SoakSanity.run_all()
    if not bool(sanity.get("ok", false)):
        for msg in sanity.get("failures", PackedStringArray()) as PackedStringArray:
            failures.append("soak_sanity: %s" % msg)
        return {"ok": false, "failures": failures, "presets": {}, "validator": {}}
    var preset_results: Dictionary = {}
    var aggregate_lines: PackedStringArray = PackedStringArray()
    OperationalLog.set_capture_enabled(true)
    OperationalLog.begin_play_session("headless://d001-presets", ",".join(preset_ids))
    CombatConstants.set_feature_ambient_pain_shock(true)
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    for preset_id in preset_ids:
        var pid: String = preset_id.strip_edges().to_lower()
        if pid.is_empty() or not SoakEncounterPresets.is_known_preset(pid):
            failures.append("%s: unknown preset" % preset_id)
            continue
        OperationalLog.clear_capture()
        seed(D001PresetRunnerTests._preset_seed(pid))
        var pr: Dictionary = D001PresetRunnerTests._run_preset(pid)
        preset_results[pid] = pr
        for line in OperationalLog.get_captured_lines():
            aggregate_lines.append(line)
        if not bool(pr.get("ok", false)):
            failures.append("%s: %s" % [pid, str(pr.get("summary", "failed"))])
    OperationalLog.write_f5_soak_capture(aggregate_lines)
    var profiles: PackedStringArray = PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS])
    for pid in preset_ids:
        var p: String = pid.strip_edges().to_lower()
        match p:
            SoakEncounterPresets.PRESET_II5_COWERING:
                if CombatD001TrackSpecs.PROFILE_PRESET_II5 not in profiles:
                    profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II5)
            SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
                if CombatD001TrackSpecs.PROFILE_PRESET_II6 not in profiles:
                    profiles.append(CombatD001TrackSpecs.PROFILE_PRESET_II6)
            _:
                pass
    var val_r: Dictionary = CombatF5SoakLogValidator.validate(aggregate_lines, profiles)
    if not bool(val_r.get("ok", false)):
        for f in val_r.get("failures", PackedStringArray()) as PackedStringArray:
            failures.append("f5_log_validator: %s" % f)
    CombatF5SoakLogValidator.write_report(val_r)
    var ok: bool = failures.is_empty()
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)
    return {"ok": ok, "failures": failures, "presets": preset_results, "validator": val_r}
