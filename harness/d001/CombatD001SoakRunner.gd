class_name CombatD001SoakRunner
extends RefCounted
## Headless **D-001** preset fights: simulates F5 cyan soaks, captures **`FP_COMBAT`**, parses runbook grep targets.
## Mandatory **II-2b / II-5a - c** sign-off is headless-only via plausibility + **`BattleUIUpdater`** probes (see
## **`.d001_headless_signoff.txt`**).
## **ii5c** (`_run_ii5c_gauge_label_checks`): **`Stm`/`Ready`/`Exh`/`Grd`** + WF gauge/diagram suffix order (incl.
## **`form_wrath_*`**)  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`**.

const RUNNER_NAME := "CombatD001SoakRunner"
const TICK_DT := 0.05

## Cross-file preloads — loaded at runtime via load(), so class_name resolution succeeds.
const _OpsLog := preload("res://core/OperationalLog.gd")
const SoakEncounterPresets := preload("res://world/SoakEncounterPresets.gd")
const CombatF5SoakLogValidator := preload("res://harness/CombatF5SoakLogValidator.gd")
const _D001SoakSanity := preload("res://harness/d001/CombatD001SoakSanity.gd")
const _D001TrackSpecs := preload("res://harness/d001/CombatD001TrackSpecs.gd")
const FallenPathsErrorLogger := preload("res://core/FallenPathsErrorLogger.gd")

static var _preset_runner_cls: Variant = null


static func _ensure_preset_runner() -> Variant:
	if _preset_runner_cls == null:
		_preset_runner_cls = load("res://harness/d001/D001PresetRunnerTests.gd")
	return _preset_runner_cls

static func run_all() -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	var preset_results: Dictionary = {}
	var aggregate_lines: PackedStringArray = PackedStringArray()
	_OpsLog.set_capture_enabled(true)
	_OpsLog.begin_play_session("headless://d001-soak", "")
	CombatConstants.set_feature_ambient_pain_shock(true)
	CombatConstants.set_feature_flurry_bind_exchange_load(true)
	for preset_id in SoakEncounterPresets.D001_PRESET_RUN_ORDER:
		_OpsLog.clear_capture()
		seed(_ensure_preset_runner()._preset_seed(preset_id))
		var t_preset: int = Time.get_ticks_msec()
		var pr: Dictionary = _ensure_preset_runner()._run_preset(preset_id)
		pr["duration_ms"] = Time.get_ticks_msec() - t_preset
		preset_results[preset_id] = pr
		for line in _OpsLog.get_captured_lines():
			aggregate_lines.append(line)
		if not bool(pr.get("ok", false)):
			failures.append("%s: %s" % [preset_id, str(pr.get("summary", "failed"))])
	_OpsLog.clear_capture()
	FallenPathsErrorLogger.reset_script_error_count()
	seed(_ensure_preset_runner()._preset_seed("7v7"))
	var t_7v7: int = Time.get_ticks_msec()
	var pr7: Dictionary = _ensure_preset_runner()._run_7v7_brawl()
	pr7["duration_ms"] = Time.get_ticks_msec() - t_7v7
	preset_results["7v7"] = pr7
	for line in _OpsLog.get_captured_lines():
		aggregate_lines.append(line)
	if not bool(pr7.get("ok", false)):
		failures.append("7v7: %s" % str(pr7.get("summary", "failed")))
	var t_ui: int = Time.get_ticks_msec()
	var ui_pr: Dictionary = _ensure_preset_runner()._run_ii5c_gauge_label_checks()
	ui_pr["duration_ms"] = Time.get_ticks_msec() - t_ui
	preset_results["ii5c"] = ui_pr
	if not bool(ui_pr.get("ok", false)):
		failures.append("ii5c: %s" % str(ui_pr.get("summary", "failed")))
	_OpsLog.clear_capture()
	var t_ii5a: int = Time.get_ticks_msec()
	var ii5a_pr: Dictionary = _ensure_preset_runner()._run_ii5a_formation_hint_checks()
	ii5a_pr["duration_ms"] = Time.get_ticks_msec() - t_ii5a
	preset_results["ii5a"] = ii5a_pr
	if not bool(ii5a_pr.get("ok", false)):
		failures.append("ii5a: %s" % str(ii5a_pr.get("summary", "failed")))
	var t_ii5b: int = Time.get_ticks_msec()
	var ii5b_pr: Dictionary = _ensure_preset_runner()._run_ii5b_log_policy_checks(aggregate_lines)
	ii5b_pr["duration_ms"] = Time.get_ticks_msec() - t_ii5b
	preset_results["ii5b"] = ii5b_pr
	if not bool(ii5b_pr.get("ok", false)):
		failures.append("ii5b: %s" % str(ii5b_pr.get("summary", "failed")))
	var t_ii1e: int = Time.get_ticks_msec()
	var ii1e_pr: Dictionary = _ensure_preset_runner()._run_ii1e_engagement_label_checks()
	ii1e_pr["duration_ms"] = Time.get_ticks_msec() - t_ii1e
	preset_results["ii1e"] = ii1e_pr
	if not bool(ii1e_pr.get("ok", false)):
		failures.append("ii1e: %s" % str(ii1e_pr.get("summary", "failed")))
	_OpsLog.clear_capture()
	var t_ii7: int = Time.get_ticks_msec()
	var ii7_pr: Dictionary = _ensure_preset_runner()._run_ii7_medical_phase_smoke()
	ii7_pr["duration_ms"] = Time.get_ticks_msec() - t_ii7
	preset_results["ii7"] = ii7_pr
	for line in _OpsLog.get_captured_lines():
		aggregate_lines.append(line)
	if not bool(ii7_pr.get("ok", false)):
		failures.append("ii7: %s" % str(ii7_pr.get("summary", "failed")))
	_OpsLog.clear_capture()
	var t_fm: int = Time.get_ticks_msec()
	var fm_pr: Dictionary = _ensure_preset_runner()._run_formation_move_f5_smoke()
	fm_pr["duration_ms"] = Time.get_ticks_msec() - t_fm
	preset_results["formation_move_f5"] = fm_pr
	for line in _OpsLog.get_captured_lines():
		aggregate_lines.append(line)
	if not bool(fm_pr.get("ok", false)):
		failures.append("formation_move_f5: %s" % str(fm_pr.get("summary", "failed")))
	_OpsLog.clear_capture()
	_ensure_preset_runner()._probe_wf_controlling_close_turn_hint()
	for line in _OpsLog.get_captured_lines():
		aggregate_lines.append(line)
	_OpsLog.clear_capture()
	_OpsLog.write_f5_soak_capture(aggregate_lines)
	var val_r: Dictionary = CombatF5SoakLogValidator.validate(aggregate_lines)
	if not bool(val_r.get("ok", false)):
		for f in val_r.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("f5_log_validator: %s" % f)
	var sanity: Dictionary = _D001SoakSanity.run_all()
	if not bool(sanity.get("ok", false)):
		for msg in sanity.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("soak_sanity: %s" % msg)
	var ok: bool = failures.is_empty()
	var mandatory_fail: PackedStringArray = _D001TrackSpecs.headless_mandatory_signoff_failures(preset_results)
	for msg in mandatory_fail:
		failures.append("mandatory_signoff: %s" % msg)
	ok = failures.is_empty()
	_OpsLog.write_d001_soak_report(ok, preset_results, failures)
	var ii2b_pr: Dictionary = preset_results.get(SoakEncounterPresets.PRESET_II2B_SWORD_DUEL, {}) as Dictionary
	var ii2b_signed: bool = bool(ii2b_pr.get("ii2b_plausibility_ok", false)) and bool(ii2b_pr.get("ok", false))
	if ii2b_pr.has("parry_stats"):
		_OpsLog.write_ii2b_worksheet_prefill(ii2b_pr.get("parry_stats", {}) as Dictionary, ii2b_signed)
	_OpsLog.write_d001_headless_signoff(ok, preset_results, bool(val_r.get("ok", false)))
	CombatF5SoakLogValidator.write_report(val_r)
	if ok:
		_OpsLog.harness_ok(
			RUNNER_NAME, "presets=%d+7v7+ii5a+ii5b+ii5c+ii7+ii1e" % SoakEncounterPresets.D001_PRESET_RUN_ORDER.size()
		)
	else:
		_OpsLog.harness_fail(RUNNER_NAME, failures)
	_OpsLog.end_play_session()
	_OpsLog.set_capture_enabled(false)
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
	var sanity: Dictionary = _D001SoakSanity.run_all()
	if not bool(sanity.get("ok", false)):
		for msg in sanity.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("soak_sanity: %s" % msg)
		return {"ok": false, "failures": failures, "presets": {}, "validator": {}}
	var preset_results: Dictionary = {}
	var aggregate_lines: PackedStringArray = PackedStringArray()
	_OpsLog.set_capture_enabled(true)
	_OpsLog.begin_play_session("headless://d001-presets", ",".join(preset_ids))
	CombatConstants.set_feature_ambient_pain_shock(true)
	CombatConstants.set_feature_flurry_bind_exchange_load(true)
	for preset_id in preset_ids:
		var pid: String = preset_id.strip_edges().to_lower()
		if pid.is_empty() or not SoakEncounterPresets.is_known_preset(pid):
			failures.append("%s: unknown preset" % preset_id)
			continue
		_OpsLog.clear_capture()
		seed(_ensure_preset_runner()._preset_seed(pid))
		var pr: Dictionary = _ensure_preset_runner()._run_preset(pid)
		preset_results[pid] = pr
		for line in _OpsLog.get_captured_lines():
			aggregate_lines.append(line)
		if not bool(pr.get("ok", false)):
			failures.append("%s: %s" % [pid, str(pr.get("summary", "failed"))])
	_OpsLog.write_f5_soak_capture(aggregate_lines)
	var profiles: PackedStringArray = PackedStringArray([_D001TrackSpecs.PROFILE_ALWAYS])
	for pid in preset_ids:
		var p: String = pid.strip_edges().to_lower()
		match p:
			SoakEncounterPresets.PRESET_II5_COWERING:
				if _D001TrackSpecs.PROFILE_PRESET_II5 not in profiles:
					profiles.append(_D001TrackSpecs.PROFILE_PRESET_II5)
			SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
				if _D001TrackSpecs.PROFILE_PRESET_II6 not in profiles:
					profiles.append(_D001TrackSpecs.PROFILE_PRESET_II6)
			_:
				pass
	var val_r: Dictionary = CombatF5SoakLogValidator.validate(aggregate_lines, profiles)
	if not bool(val_r.get("ok", false)):
		for f in val_r.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("f5_log_validator: %s" % f)
	CombatF5SoakLogValidator.write_report(val_r)
	var ok: bool = failures.is_empty()
	_OpsLog.end_play_session()
	_OpsLog.set_capture_enabled(false)
	return {"ok": ok, "failures": failures, "presets": preset_results, "validator": val_r}
