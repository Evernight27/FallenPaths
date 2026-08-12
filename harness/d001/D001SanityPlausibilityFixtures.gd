class_name D001SanityPlausibilityFixtures
extends RefCounted
## Plausibility fixture tests for D001 sanity checks.


static func _run_plausibility_fixture_tests() -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()

	# --- II-5 plausibility fixtures ---
	var missing_blocked: PackedStringArray = PackedStringArray(
		[
			"cowering_fall_back listed for Leader",
		]
	)
	if D001SanityProbeTests._ii5_plausibility_failures(missing_blocked).is_empty():
		failures.append("fixture_ii5: should require blocked line")

	var good_ii5: PackedStringArray = PackedStringArray(
		[
			"cowering_fall_back listed for Leader",
			"solo fall_back blocked: cowering unit alone on side (Leader)",
		]
	)
	if not D001SanityProbeTests._ii5_plausibility_failures(good_ii5).is_empty():
		failures.append("fixture_ii5: valid sample should pass")

	# --- II-6 plausibility fixtures ---
	var setup_hint_only: PackedStringArray = PackedStringArray(
		[
			"soak_setup ii6 companion chest wounded bv=58 (grep ambient_pain_shock on Companion)",
			"soak=ii6",
		]
	)
	if D001SanityProbeTests._ii6_plausibility_failures(setup_hint_only).is_empty():
		failures.append("fixture_ii6_hint: setup grep hint must not satisfy ambient Companion")

	var thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
	var low_pain: PackedStringArray = PackedStringArray(
		[
			"soak_setup ii6 companion chest wounded bv=58",
			"ambient_pain_shock Companion effective_pain=%.1f duration=5.0s" % (thresh - 0.5),
		]
	)
	if D001SanityProbeTests._ii6_plausibility_failures(low_pain).is_empty():
		failures.append("fixture_ii6_pain: effective_pain below threshold should fail")

	var good_ii6: PackedStringArray = PackedStringArray(
		[
			"soak_setup ii6 companion chest wounded bv=58",
			D001SanityFixtureTests._ii6_expected_ambient_log_line(),
		]
	)
	if not D001SanityProbeTests._ii6_plausibility_failures(good_ii6).is_empty():
		failures.append("fixture_ii6_pain: valid ambient sample should pass")

	# --- Common plausibility fixtures ---
	var bad_profile: PackedStringArray = PackedStringArray(
		[
			"soak=ii5",
			"soak_fight_end winner=player fight_profile=ii6",
		]
	)
	if (
		D001SanityProbeTests
		._common_log_plausibility_failures(SoakEncounterPresets.PRESET_II5_COWERING, bad_profile)
		.is_empty()
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
		D001SanityProbeTests
		._common_log_plausibility_failures(SoakEncounterPresets.PRESET_II5_COWERING, conflicting_winners)
		.is_empty()
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
		D001SanityProbeTests
		._common_log_plausibility_failures(
			SoakEncounterPresets.PRESET_II5_COWERING, D001SanityProbeTests._lines_for_last_fight(multi_fight_retry)
		)
		.is_empty()
	):
		failures.append("fixture_common: last-fight scope should ignore prior fight winner")

	var end_before_enter: PackedStringArray = PackedStringArray(
		[
			"soak_fight_end winner=player",
			"soak_fight_enter preset=ii5",
		]
	)
	if (
		D001SanityProbeTests
		._common_log_plausibility_failures(SoakEncounterPresets.PRESET_II5_COWERING, end_before_enter)
		.is_empty()
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
	if ii5_slice.is_empty() or not D001SanityProbeTests._blob_has(ii5_slice, "cowering_fall_back listed"):
		failures.append("slice_ii5: should capture ii5 fight lines only")
	if D001SanityProbeTests._blob_has(ii5_slice, "ambient_pain_shock"):
		failures.append("slice_ii5: must not include ii6 ambient lines")

	var ii6_slice: PackedStringArray = CombatD001TrackSpecs.slice_lines_for_soak_preset(
		mixed, SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK
	)
	if not D001SanityProbeTests._blob_has(ii6_slice, "ambient_pain_shock Companion"):
		failures.append("slice_ii6: should capture ii6 ambient line")
	if D001SanityProbeTests._blob_has(ii6_slice, "cowering_fall_back"):
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
	var probe_ent: CoreEntity = D001SanityFixtureTests._ii6_probe_entity()
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
	var ent: CoreEntity = D001SanityFixtureTests._ii6_probe_entity()
	var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(ent)
	var thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
	var dur: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain, 0.0)
	if pain <= thresh:
		failures.append("ii6_probe: effective_pain %.2f must exceed threshold %.2f" % [pain, thresh])
	var log_line: String = D001SanityFixtureTests._ii6_ambient_log_line_for_entity(ent)
	var parsed_pain: float = D001SanityProbeTests._parse_ambient_metric(log_line, "effective_pain=")
	var parsed_dur: float = D001SanityProbeTests._parse_ambient_metric(log_line, "duration=")
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
	var amb: String = D001SanityFixtureTests._ii6_expected_ambient_log_line()
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
	if not D001SanityProbeTests._ii6_plausibility_failures(slice).is_empty():
		failures.append("fixture_ii6_slice: sliced ii6 capture should pass plausibility")
	if D001SanityProbeTests._blob_has(slice, "cowering_fall_back"):
		failures.append("fixture_ii6_slice: must not include ii5 lines")
	return failures


static func _run_track_crosswalk_tests() -> PackedStringArray:
	return CombatD001TrackSpecs.headless_validator_coverage_failures()
