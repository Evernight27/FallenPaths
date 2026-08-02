class_name D001SanityValidatorFixtures
extends RefCounted
## Validator cross-check fixtures: log lines validated against track specs.
## Called from **`CombatD001SoakRunner._evaluate`**, **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE=sanity`).

const BattleScene := preload("res://ui/battle/BattleScene.gd")


static func _run_validator_fixture_tests() -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	# --- II-5 validator fixture ---
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
		D001SanityProbeTests._normalize_fixture_lines(good_ii5),
		PackedStringArray([CombatD001TrackSpecs.PROFILE_ALWAYS, CombatD001TrackSpecs.PROFILE_PRESET_II5])
	)
	if not bool(r5.get("ok", false)):
		failures.append(
			"fixture_ii5_good: %s" % ", ".join(r5.get("failures", PackedStringArray()) as PackedStringArray)
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

	# --- II-6 validator fixture ---
	var amb_line: String = D001SanityProbeTests._find_line(good_ii5, "soak_setup ii5")
	var good_ii6: PackedStringArray = PackedStringArray(
		[
			"soak_setup ii6 companion chest wounded bv=58",
			"soak=ii6",
			D001SanityProbeTests._find_line(good_ii5, "cowering_fall_back executed"),
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

	# --- II-2b validator fixture ---
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

	# --- WF-M3 validator fixtures ---
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

	# --- Camp EA validator fixtures ---
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

	# --- Mopup validator fixtures ---
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

	# --- Line plug validator fixtures ---
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

	# --- Mopup hold-line validator fixtures ---
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

	# --- Controlling close validator fixtures ---
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

	# --- Incap plug validator fixture ---
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

	# --- Contract / campaign validator fixtures ---
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

	# --- Camp false positive fixtures ---
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

	# --- Step 9 append fixtures ---
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
