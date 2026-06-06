class_name CombatD001TrackSpecs
extends RefCounted

## Shared **D-001** grep needles for **`CombatD001SoakRunner`** (headless) and **`CombatF5SoakLogValidator`** (F5 paste).

const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")

const PROFILE_ALWAYS := "always"
const PROFILE_7V7 := "7v7"
const PROFILE_PRESET_II2B := "preset_ii2b"
const PROFILE_PRESET_II3 := "preset_ii3"
const PROFILE_PRESET_II5 := "preset_ii5"
const PROFILE_PRESET_II6 := "preset_ii6"
const PROFILE_PRESET_II8 := "preset_ii8"
const PROFILE_PRESET_II4D := "preset_ii4d"
const PROFILE_PRESET_II_ENVELOP := "preset_ii_envelop"
const PROFILE_CAMP_EA := "camp_ea"

const NEEDLE_SOAK_FIGHT_END := "soak_fight_end winner="
const NEEDLE_TURN_READY_GAUGE := "turn_ready_gauge"
const NEEDLE_TOOLTIP_OK := "tooltip_match=ok"
const NEEDLE_DIAGRAM_BANNER := "diagram_banner player:"
const NEEDLE_ENGAGEMENT_FORMATION := "engagement mode=Formation line"
const NEEDLE_ENGAGEMENT_DUEL := "engagement mode=Duel"
const NEEDLE_PARRY_TRACE := "parry_"
## III-4 **3e** — combat-phase mop-up with listed strikes (shared by headless + F5 validator).
const REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED := (
	"engagement_debug turn .* mop_up=true .* (menu=strikes_listed|strikes=[1-9])"
)
## III-6 maintain — rank-0 gap or incap plug-forward pick (`line_plug_pick=1`; log sets `line_plug=true` for both).
const REGEX_ENGAGEMENT_DEBUG_LINE_PLUG_PICK := (
	"engagement_debug turn .* line_plug=true .* line_plug_pick=1"
)


static func headless_checks_for_preset(preset_id: String) -> Array:
	var checks: Array = _headless_policy_checks()
	checks.append({"id": "soak_tag", "needle": "soak=%s" % preset_id, "min": 1})
	checks.append_array(_headless_preset_checks(preset_id))
	return checks


static func detect_profiles(normalized: PackedStringArray) -> PackedStringArray:
	var profiles: PackedStringArray = PackedStringArray([PROFILE_ALWAYS])
	var blob: String = "\n".join(normalized)
	if _blob_has(blob, ["soak_fight_enter preset=ii2b", "soak=ii2b", "dev_soak=ii2b"]):
		profiles.append(PROFILE_PRESET_II2B)
	if _blob_has(blob, ["soak_fight_enter preset=ii3", "soak=ii3"]):
		profiles.append(PROFILE_PRESET_II3)
	if _blob_has(blob, ["soak_fight_enter preset=ii5", "soak=ii5"]):
		profiles.append(PROFILE_PRESET_II5)
	if _blob_has(blob, ["soak_fight_enter preset=ii6", "soak=ii6"]):
		profiles.append(PROFILE_PRESET_II6)
	if _blob_has(blob, ["soak_fight_enter preset=ii8", "soak=ii8"]):
		profiles.append(PROFILE_PRESET_II8)
	if _blob_has(blob, ["soak_fight_enter preset=ii4d", "soak=ii4d", "dev_soak=ii4d"]):
		profiles.append(PROFILE_PRESET_II4D)
	if _blob_has(blob, ["soak_fight_enter preset=ii_envelop", "soak=ii_envelop", "dev_soak=ii_envelop"]):
		profiles.append(PROFILE_PRESET_II_ENVELOP)
	if _blob_has(
		blob,
		camp_ea_profile_markers()
	):
		profiles.append(PROFILE_CAMP_EA)
	if _blob_has(blob, ["soak_fight_enter tile=red", "tile=red"]) or (
		not _blob_has(
			blob,
			[
				"soak_fight_enter preset=",
				"soak=ii2b",
				"soak=ii3",
				"soak=ii5",
				"soak=ii6",
				"soak=ii8",
			]
		)
		and normalized.size() > 80
	):
		profiles.append(PROFILE_7V7)
	return profiles


static func missing_cyan_presets(active_profiles: PackedStringArray) -> PackedStringArray:
	var have: Dictionary = {}
	for p in active_profiles:
		have[p] = true
	var out: PackedStringArray = PackedStringArray()
	for want in [PROFILE_PRESET_II2B, PROFILE_PRESET_II5, PROFILE_PRESET_II6]:
		if not have.has(want):
			out.append(want.replace("preset_", ""))
	return out


static func validator_tracks(active_profiles: PackedStringArray) -> Array:
	var tracks: Array = []
	var have: Dictionary = {}
	for p in active_profiles:
		have[p] = true
	tracks.append_array(_validator_always_tracks())
	if _profile_set_includes_trace_profiles(active_profiles):
		tracks.append_array(_validator_f5_trace_tracks())
	if have.has(PROFILE_7V7):
		tracks.append_array(_validator_7v7_tracks())
	if have.has(PROFILE_PRESET_II2B):
		tracks.append_array(_validator_ii2b_tracks())
	if have.has(PROFILE_PRESET_II3):
		tracks.append_array(_validator_ii3_tracks())
	if have.has(PROFILE_PRESET_II5):
		tracks.append_array(_validator_ii5_tracks())
	if have.has(PROFILE_PRESET_II6):
		tracks.append_array(_validator_ii6_tracks())
	if have.has(PROFILE_PRESET_II8):
		tracks.append_array(_validator_ii8_tracks())
	if have.has(PROFILE_PRESET_II4D):
		tracks.append_array(_validator_ii4d_tracks())
	if have.has(PROFILE_PRESET_II_ENVELOP):
		tracks.append_array(_validator_ii_envelop_tracks())
	tracks.append_array(_validator_wf_footing_tracks())
	if have.has(PROFILE_7V7) or have.has(PROFILE_CAMP_EA) or have.has(PROFILE_PRESET_II_ENVELOP):
		tracks.append_array(_validator_mopup_strike_finish_tracks())
		tracks.append_array(_validator_line_plug_pick_tracks())
	if have.has(PROFILE_CAMP_EA):
		tracks.append_array(_validator_camp_ea_tracks())
	return tracks.filter(func(spec: Dictionary) -> bool: return _track_applies(spec, active_profiles))


## Maps headless preset id → validator profile id (`preset_ii2b`, `7v7`, …).
static func preset_id_to_profile(preset_id: String) -> String:
	match preset_id:
		_SoakPresets.PRESET_II2B_SWORD_DUEL:
			return PROFILE_PRESET_II2B
		_SoakPresets.PRESET_II3_SURROUND:
			return PROFILE_PRESET_II3
		_SoakPresets.PRESET_II5_COWERING:
			return PROFILE_PRESET_II5
		_SoakPresets.PRESET_II6_AMBIENT_SHOCK:
			return PROFILE_PRESET_II6
		_SoakPresets.PRESET_II8_FORMATION:
			return PROFILE_PRESET_II8
		_SoakPresets.PRESET_II4D_EXHAUSTION:
			return PROFILE_PRESET_II4D
		_SoakPresets.PRESET_II_ENVELOP:
			return PROFILE_PRESET_II_ENVELOP
		"7v7":
			return PROFILE_7V7
	return ""


## Synthetic log markers so **`detect_profiles`** recognizes a preset in harness alignment tests.
static func synthetic_profile_markers(preset_id: String) -> PackedStringArray:
	match preset_id:
		_SoakPresets.PRESET_II2B_SWORD_DUEL:
			return PackedStringArray(["soak_fight_enter preset=ii2b", "soak=ii2b"])
		_SoakPresets.PRESET_II3_SURROUND:
			return PackedStringArray(["soak_fight_enter preset=ii3"])
		_SoakPresets.PRESET_II5_COWERING:
			return PackedStringArray(["soak_fight_enter preset=ii5"])
		_SoakPresets.PRESET_II6_AMBIENT_SHOCK:
			return PackedStringArray(["soak_setup ii6", "soak=ii6"])
		_SoakPresets.PRESET_II8_FORMATION:
			return PackedStringArray(["soak_fight_enter preset=ii8"])
		_SoakPresets.PRESET_II4D_EXHAUSTION:
			return PackedStringArray(["soak_fight_enter preset=ii4d", "soak=ii4d"])
		_SoakPresets.PRESET_II_ENVELOP:
			return PackedStringArray(["soak_fight_enter preset=ii_envelop", "soak=ii_envelop"])
		"7v7":
			return PackedStringArray(["soak_fight_enter tile=red 7v7", "soak=7v7"])
		"camp_ea":
			return PackedStringArray([
				"settlement_continue",
				"contract_victory pay=",
				"company_day_advanced",
			])
	return PackedStringArray()


## Grep needles that activate **`camp_ea`** profile (F5 paste + world trace ingest).
static func camp_ea_profile_markers() -> Array:
	return [
		"settlement_continue",
		"contract_victory pay=",
		"campaign_medical_exit",
		"company_day_advanced",
		"company_run_end reason=",
		"field_care:",
		"field_care bandage",
		"field_care pressure",
		"field_care stabilize",
		"company_wages: gold=",
		"Wages short",
		"desertion summary=",
		"party_triage_open",
	]


static func is_camp_ea_world_trace_line(s: String) -> bool:
	var line: String = s.strip_edges()
	if line.is_empty():
		return false
	for marker in camp_ea_profile_markers():
		var m: String = str(marker)
		if line.begins_with(m) or m in line:
			return true
	return false


## Union of validator track needles (+ alts) for active profiles.
static func validator_needle_union(active_profiles: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for spec in validator_tracks(active_profiles):
		var needle: String = str(spec.get("needle", "")).strip_edges()
		if not needle.is_empty() and needle not in out:
			out.append(needle)
		for alt in spec.get("alt_needles", []) as Array:
			var alt_s: String = str(alt).strip_edges()
			if not alt_s.is_empty() and alt_s not in out:
				out.append(alt_s)
	return out


## True when a required headless needle is matched by some validator track (substring either way).
static func headless_needle_covered_by_validator(
	headless_needle: String,
	validator_needles: PackedStringArray
) -> bool:
	if headless_needle.is_empty():
		return true
	for v in validator_needles:
		if headless_needle in v or v in headless_needle:
			return true
	return false


## Headless runner checks with no F5-validator analogue (policy, soak tags, setup lines).
const _HEADLESS_ONLY_CHECK_IDS: Dictionary = {
	"soak_tag": true,
	"soak_setup": true,
	"fight_enter": true,
	"party_count": true,
	"no_script_error": true,
	"no_fp_error": true,
	"no_crash_success_log": true,
}


## Returns failures when a required headless check has no validator counterpart for its profile.
static func headless_validator_coverage_failures() -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	var preset_ids: PackedStringArray = _SoakPresets.D001_PRESET_RUN_ORDER.duplicate()
	preset_ids.append("7v7")
	for preset_id in preset_ids:
		var profile: String = preset_id_to_profile(preset_id)
		if profile.is_empty():
			failures.append("unknown preset_id=%s" % preset_id)
			continue
		var profiles: PackedStringArray = PackedStringArray([PROFILE_ALWAYS, profile])
		var val_needles: PackedStringArray = validator_needle_union(profiles)
		for spec in headless_checks_for_preset(preset_id):
			var check_id: String = str(spec.get("id", ""))
			if bool(spec.get("optional", false)) or _HEADLESS_ONLY_CHECK_IDS.has(check_id):
				continue
			var needle: String = str(spec.get("needle", ""))
			if not headless_needle_covered_by_validator(needle, val_needles):
				failures.append(
					"%s: headless '%s' not covered by validator profile %s"
					% [preset_id, needle, profile]
				)
		var markers: PackedStringArray = synthetic_profile_markers(preset_id)
		if not markers.is_empty():
			var detected: PackedStringArray = detect_profiles(markers)
			if profile not in detected:
				failures.append(
					"%s: detect_profiles missed %s from markers %s"
					% [preset_id, profile, str(markers)]
				)
	return failures


static func grep_stats(normalized: PackedStringArray, count_needle: Callable, _count_regex: Callable) -> Dictionary:
	return {
		NEEDLE_TURN_READY_GAUGE: count_needle.call(normalized, NEEDLE_TURN_READY_GAUGE),
		"tooltip_ok": count_needle.call(normalized, NEEDLE_TOOLTIP_OK),
		"tooltip_mismatch": count_needle.call(normalized, "tooltip_match=mismatch"),
		"tooltip_counter": count_needle.call(normalized, "tooltip_match=counter"),
		"tooltip_medical": count_needle.call(normalized, "tooltip_match=medical"),
		"tooltip_hold_line": count_needle.call(normalized, "tooltip_match=hold_line"),
		NEEDLE_DIAGRAM_BANNER: count_needle.call(normalized, NEEDLE_DIAGRAM_BANNER),
		"engagement_transition": count_needle.call(normalized, "engagement_transition"),
		"medical_action_pick": count_needle.call(normalized, "medical_action pick"),
		"medical_pack_listed": count_needle.call(normalized, "medical_pack_wound listed"),
		"medical_pack_pick": count_needle.call(normalized, "medical_pack_wound pick"),
		"soak_fight_end": count_needle.call(normalized, NEEDLE_SOAK_FIGHT_END),
		"phase_end_winner": count_needle.call(normalized, "phase_end winner="),
		"research_feel": count_needle.call(normalized, "research_feel "),
		"hit_resolve": count_needle.call(normalized, "hit_resolve "),
		"strike_avoided": count_needle.call(normalized, "strike_avoided "),
		"engagement_debug_mop_up": count_needle.call(normalized, "mop_up=true"),
		"engagement_debug_rotate_suppress": count_needle.call(normalized, "rotate_suppress=true"),
		"engagement_debug_mopup_strikes_listed": _count_regex.call(
			normalized,
			REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED
		),
		"mopup_gauge_hint": count_needle.call(normalized, "Mop-up"),
		"form_switch": count_needle.call(normalized, "form_switch id="),
		"wf_m3_form_on_gauge": _count_regex.call(
			normalized, "turn_ready_gauge .* label=.* Form "
		),
		"controlling_close_hint": count_needle.call(normalized, "controlling_close_list "),
		"field_care_bandage": count_needle.call(normalized, "field_care bandage"),
		"field_care_pressure": count_needle.call(normalized, "field_care pressure part="),
		"company_day_advanced": count_needle.call(normalized, "company_day_advanced"),
		"settlement_continue": count_needle.call(normalized, "settlement_continue"),
		"company_wages_warn": (
			count_needle.call(normalized, "company_wages: gold=")
			+ count_needle.call(normalized, "Wages short — paid")
		),
		"desertion_summary": count_needle.call(normalized, "desertion summary="),
		"party_triage_open": count_needle.call(normalized, "party_triage_open"),
	}


## Lines for all preset fights (multi-rep duel sim + optional **`soak_setup`** smoke tail) from a capture blob.
static func slice_lines_for_soak_preset(lines: PackedStringArray, preset_id: String) -> PackedStringArray:
	var soak_tag: String = "soak=%s" % preset_id
	var setup_tag: String = "soak_setup %s" % preset_id
	var out: PackedStringArray = PackedStringArray()
	var capturing: bool = false
	for raw in lines:
		var line: String = str(raw)
		if "encounter_begin" in line:
			if soak_tag in line:
				capturing = true
				out.append(line)
				continue
			var other_soak: String = _encounter_soak_id_from_line(line)
			if capturing and not other_soak.is_empty() and other_soak != preset_id:
				capturing = false
			continue
		if setup_tag in line:
			capturing = true
		if capturing:
			out.append(line)
	return out


static func _encounter_soak_id_from_line(line: String) -> String:
	var key: String = "encounter[soak="
	var idx: int = line.find(key)
	if idx < 0:
		return ""
	var tail: String = line.substr(idx + key.length())
	var end: int = tail.find("]")
	if end < 0:
		return ""
	return tail.substr(0, end)


## Grep counts for **III-3** worksheet prefill (headless — not II-2b feel sign-off).
static func parry_outcome_stats(lines: PackedStringArray) -> Dictionary:
	var stats: Dictionary = {
		"parry_deflect": 0,
		"parry_bind": 0,
		"parry_partial": 0,
		"riposte_chain": 0,
		"counter_tempo": 0,
		"flurry_bind_opened": 0,
		"flurry_bind": 0,
	}
	for raw in lines:
		var line: String = str(raw)
		if "parry_deflect" in line:
			stats["parry_deflect"] = int(stats["parry_deflect"]) + 1
		if "parry_bind" in line:
			stats["parry_bind"] = int(stats["parry_bind"]) + 1
		if "parry_partial" in line:
			stats["parry_partial"] = int(stats["parry_partial"]) + 1
		if "riposte_chain" in line:
			stats["riposte_chain"] = int(stats["riposte_chain"]) + 1
		if "counter_tempo" in line:
			stats["counter_tempo"] = int(stats["counter_tempo"]) + 1
		if "flurry_bind opened" in line:
			stats["flurry_bind_opened"] = int(stats["flurry_bind_opened"]) + 1
		elif "flurry_bind" in line:
			stats["flurry_bind"] = int(stats["flurry_bind"]) + 1
	return stats


static func parry_stats_summary_line(stats: Dictionary) -> String:
	return (
		"parry_stats deflect=%d bind=%d partial=%d riposte=%d counter_tempo=%d flurry_opened=%d flurry=%d"
		% [
			int(stats.get("parry_deflect", 0)),
			int(stats.get("parry_bind", 0)),
			int(stats.get("parry_partial", 0)),
			int(stats.get("riposte_chain", 0)),
			int(stats.get("counter_tempo", 0)),
			int(stats.get("flurry_bind_opened", 0)),
			int(stats.get("flurry_bind", 0)),
		]
	)


## Rollup from **`CombatF5SoakTrace`** session counters at **`soak_fight_end`** (grep **`hit_outcome_stats`**).
static func hit_outcome_stats_summary_line(session_counts: Dictionary) -> String:
	return (
		"hit_outcome_stats hit=%d glancing=%d negligible=%d deflected=%d other=%d resolve=%d avoided_miss=%d avoided_dodge=%d"
		% [
			int(session_counts.get("hit_outcome_hit", 0)),
			int(session_counts.get("hit_outcome_glancing", 0)),
			int(session_counts.get("hit_outcome_negligible", 0)),
			int(session_counts.get("hit_outcome_deflected", 0)),
			int(session_counts.get("hit_outcome_other", 0)),
			int(session_counts.get("hit_resolve", 0)),
			int(session_counts.get("strike_avoided_miss", 0)),
			int(session_counts.get("strike_avoided_dodge", 0)),
		]
	)


## Parse **`FP_COMBAT: parry_stats deflect=N …`** rollup (headless II-2b worksheet).
static func parry_stats_from_summary_line(line: String) -> Dictionary:
	var stats: Dictionary = {
		"parry_deflect": 0,
		"parry_bind": 0,
		"parry_partial": 0,
		"riposte_chain": 0,
		"counter_tempo": 0,
		"flurry_bind_opened": 0,
		"flurry_bind": 0,
	}
	var key_map: Dictionary = {
		"deflect": "parry_deflect",
		"bind": "parry_bind",
		"partial": "parry_partial",
		"riposte": "riposte_chain",
		"counter_tempo": "counter_tempo",
		"flurry_opened": "flurry_bind_opened",
		"flurry": "flurry_bind",
	}
	for short_key in key_map.keys():
		var token: String = "%s=" % short_key
		var idx: int = line.find(token)
		if idx < 0:
			continue
		var tail: String = line.substr(idx + token.length())
		var end: int = 0
		while end < tail.length() and tail[end].is_valid_int():
			end += 1
		if end > 0:
			stats[key_map[short_key]] = int(tail.substr(0, end))
	return stats


static func ii2b_plausibility_failures(stats: Dictionary) -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	var deflect: int = int(stats.get("parry_deflect", 0))
	var bind: int = int(stats.get("parry_bind", 0))
	var partial: int = int(stats.get("parry_partial", 0))
	var riposte: int = int(stats.get("riposte_chain", 0))
	var flurry_opened: int = int(stats.get("flurry_bind_opened", 0))
	if deflect < 1:
		failures.append("parry_deflect>=1 (got %d)" % deflect)
	if bind < 1:
		failures.append("parry_bind>=1 (got %d)" % bind)
	if riposte < 1:
		failures.append("riposte_chain>=1 (got %d)" % riposte)
	if CombatConstants.is_feature_flurry_bind_exchange_enabled() and flurry_opened < 1:
		failures.append("flurry_bind_opened>=1 (got %d)" % flurry_opened)
	var total: int = deflect + bind + partial
	if total < 2:
		failures.append("parry_outcomes>=2 (got %d)" % total)
	if bind > deflect + 2:
		failures.append("bind must not dominate deflect (bind=%d deflect=%d)" % [bind, deflect])
	# Ratio gate: short headless soaks can show many partials vs few clean deflect/bind events.
	var partial_cap: int = (deflect + bind) * 2 + 3
	if partial > partial_cap:
		failures.append(
			"partial leaks too high vs clean outcomes (partial=%d cap=%d)"
			% [partial, partial_cap]
		)
	return failures


## Grep band crossings for **II-4d** headless sign-off (F5 3–5 min feel remains optional).
static func exhaustion_band_stats(lines: PackedStringArray) -> Dictionary:
	var stats: Dictionary = {
		"crossed_25": 0,
		"crossed_50": 0,
		"crossed_75": 0,
		"exhaustion_log": 0,
	}
	for raw in lines:
		var line: String = str(raw)
		if "exhaustion" not in line:
			continue
		stats["exhaustion_log"] = int(stats.get("exhaustion_log", 0)) + 1
		if "crossed 25" in line:
			stats["crossed_25"] = int(stats.get("crossed_25", 0)) + 1
		if "crossed 50" in line:
			stats["crossed_50"] = int(stats.get("crossed_50", 0)) + 1
		if "crossed 75" in line:
			stats["crossed_75"] = int(stats.get("crossed_75", 0)) + 1
	return stats


static func exhaustion_stats_summary_line(stats: Dictionary) -> String:
	return (
		"exhaustion_stats crossed_25=%d crossed_50=%d crossed_75=%d exhaustion_log=%d"
		% [
			int(stats.get("crossed_25", 0)),
			int(stats.get("crossed_50", 0)),
			int(stats.get("crossed_75", 0)),
			int(stats.get("exhaustion_log", 0)),
		]
	)


static func ii4d_plausibility_failures(stats: Dictionary, gauge_exh_ok: bool) -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	if int(stats.get("crossed_25", 0)) < 1:
		failures.append("crossed_25>=1 (got %d)" % int(stats.get("crossed_25", 0)))
	if int(stats.get("exhaustion_log", 0)) < 1:
		failures.append("exhaustion_log>=1 (got %d)" % int(stats.get("exhaustion_log", 0)))
	if not gauge_exh_ok:
		failures.append("gauge_label_missing_Exh_suffix")
	return failures


static func ii2b_worksheet_prefill_text(stats: Dictionary, headless_signed: bool) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("--- II-2b worksheet prefill (headless) ---")
	lines.append("headless_signed_off=%s" % str(headless_signed).to_lower())
	lines.append("Copy Sword row into .ii2b_worksheet_prefill.txt / calibration audit (III-3 baseline).")
	lines.append(parry_stats_summary_line(stats))
	lines.append(
		"Sword | deflect=%d | bind=%d | partial=%d | riposte=%d | counter=%d | flurry_opened=%d"
		% [
			int(stats.get("parry_deflect", 0)),
			int(stats.get("parry_bind", 0)),
			int(stats.get("parry_partial", 0)),
			int(stats.get("riposte_chain", 0)),
			int(stats.get("counter_tempo", 0)),
			int(stats.get("flurry_bind_opened", 0)),
		]
	)
	if headless_signed:
		lines.append(
			"III-3 constants: unchanged baseline (PARRY_DEFLECT_THRESHOLD=1.08 PARRY_BIND_CONTROL_THRESHOLD=0.65)"
		)
	lines.append("--- END II-2b worksheet prefill ---")
	return "\n".join(lines) + "\n"


## Mandatory **D-001** tracks satisfied by headless runner (no F5).
static func headless_mandatory_signoff_failures(preset_results: Dictionary) -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	for track_id in ["ii2b", "ii5a", "ii5b", "ii5c"]:
		var pr: Dictionary = preset_results.get(track_id, {}) as Dictionary
		if pr.is_empty():
			failures.append("%s: missing preset_results" % track_id)
			continue
		if not bool(pr.get("ok", false)):
			failures.append("%s: %s" % [track_id, str(pr.get("summary", "not ok"))])
	var ii2b: Dictionary = preset_results.get(_SoakPresets.PRESET_II2B_SWORD_DUEL, {}) as Dictionary
	if not bool(ii2b.get("ii2b_plausibility_ok", false)):
		for msg in ii2b.get("ii2b_plausibility_failures", PackedStringArray()) as PackedStringArray:
			failures.append("ii2b_plausibility: %s" % msg)
	return failures


static func _headless_policy_checks() -> Array:
	return [
		{"id": "no_script_error", "needle": "SCRIPT_ERROR", "min": 0, "max": 0},
		{"id": "no_fp_error", "needle": "FP_ERROR", "min": 0, "max": 0},
		{"id": "no_crash_success_log", "needle": "crash_success", "min": 0, "max": 0},
	]


static func _headless_preset_checks(preset_id: String) -> Array:
	match preset_id:
		_SoakPresets.PRESET_II2B_SWORD_DUEL:
			return [
				{"id": "duel_mode", "needle": NEEDLE_ENGAGEMENT_DUEL, "min": 1},
				{"id": "parry_trace", "needle": NEEDLE_PARRY_TRACE, "min": 1},
				{"id": "parry_deflect_or_bind", "needle": "parry_deflect", "min": 1, "optional": true},
				{"id": "parry_bind", "needle": "parry_bind", "min": 1, "optional": true},
				{"id": "riposte", "needle": "riposte_chain", "min": 1, "optional": true},
				{"id": "flurry", "needle": "flurry_bind", "min": 1, "optional": true},
			]
		_SoakPresets.PRESET_II3_SURROUND:
			return [
				{"id": "arc_overlap", "needle": "ui_hint Arc overlap", "min": 1},
				{"id": "parry_trace", "needle": NEEDLE_PARRY_TRACE, "min": 1},
			]
		_SoakPresets.PRESET_II5_COWERING:
			return [
				{"id": "soak_setup", "needle": "soak_setup ii5", "min": 1},
				{"id": "cowering_listed", "needle": "cowering_fall_back listed", "min": 1},
				{"id": "cowering_executed", "needle": "cowering_fall_back executed", "min": 1},
			]
		_SoakPresets.PRESET_II6_AMBIENT_SHOCK:
			return [
				{"id": "soak_setup", "needle": "soak_setup ii6", "min": 1},
				{"id": "ambient", "needle": "ambient_pain_shock", "min": 1},
				{
					"id": "ambient_companion",
					"needle": "ambient_pain_shock Companion",
					"min": 1,
					"optional": true,
				},
			]
		_SoakPresets.PRESET_II8_FORMATION:
			return [
				{"id": "formation_mode", "needle": NEEDLE_ENGAGEMENT_FORMATION, "min": 1},
				{"id": "diagram_banner", "needle": NEEDLE_DIAGRAM_BANNER, "min": 1},
				{"id": "turn_ready_gauge", "needle": NEEDLE_TURN_READY_GAUGE, "min": 1},
				{"id": "tooltip_match_ok", "needle": NEEDLE_TOOLTIP_OK, "min": 1},
			]
		_SoakPresets.PRESET_II4D_EXHAUSTION:
			return [
				{"id": "duel_mode", "needle": NEEDLE_ENGAGEMENT_DUEL, "min": 1},
				{"id": "exhaustion_25", "needle": "exhaustion", "min": 1},
				{"id": "exhaustion_band", "needle": "crossed 25", "min": 1},
			]
		_SoakPresets.PRESET_II_ENVELOP:
			return [
				{"id": "soak_setup", "needle": "soak_setup ii_envelop", "min": 1},
				{"id": "skirmish_mode", "needle": "engagement mode=Skirmish", "min": 1},
				{
					"id": "wing_engagement",
					"needle": "attempt_close@",
					"min": 1,
					"alt_needles": ["Stack hold_line", "rotate_file@", "hit_resolve "],
				},
				{"id": "ii_envelop_hit", "needle": "hit_resolve ", "min": 1},
				{
					"id": "ii_envelop_mopup",
					"needle": "mop_up=true",
					"min": 1,
					"alt_needles": ["soak_setup ii_envelop_mopup"],
				},
				{
					"id": "ii_envelop_mopup_rotate_suppress",
					"needle": "rotate_suppress=true",
					"min": 1,
					"optional": true,
				},
				{
					"id": "ii_envelop_mopup_hold_hint",
					"needle": "Mop-up",
					"min": 1,
					"optional": true,
					"alt_needles": ["hold_line_hint_ok", "finish the last enemy"],
				},
				{
					"id": "ii_envelop_mopup_strike_finish",
					"regex": REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED,
					"min": 1,
					"optional": true,
					"when_ok_at_least": "mop_up=true",
				},
			]
		"7v7":
			return [
				{"id": "fight_enter", "needle": "soak_fight_enter tile=red", "min": 1},
				{"id": "party_count", "needle": "party_entering_combat count=7", "min": 1},
				{"id": "formation_mode", "needle": NEEDLE_ENGAGEMENT_FORMATION, "min": 1},
				{"id": "turn_ready_gauge", "needle": NEEDLE_TURN_READY_GAUGE, "min": 5},
				{"id": "tooltip_ok", "needle": NEEDLE_TOOLTIP_OK, "min": 3},
				{"id": "diagram_banner", "needle": NEEDLE_DIAGRAM_BANNER, "min": 1},
				{
					"id": "formation_moves",
					"needle": "rotate_file",
					"min": 1,
					"optional": true,
					"alt_needles": ["swap_rank"],
				},
				{"id": "arc_overlap", "needle": "ui_hint Arc overlap", "min": 1, "optional": true},
				{"id": "parry_trace", "needle": NEEDLE_PARRY_TRACE, "min": 1, "optional": true},
				{"id": "fight_end", "needle": NEEDLE_SOAK_FIGHT_END, "min": 1},
				{"id": "medical_phase", "needle": "medical_phase", "min": 1, "optional": true},
				{"id": "medical_action_pick", "needle": "medical_action pick", "min": 1, "optional": true},
			]
	return []


static func _validator_always_tracks() -> Array:
	return [
		{"id": "no_script_error", "needle": "SCRIPT ERROR", "max": 0, "profiles": [PROFILE_ALWAYS]},
		{"id": "no_fp_error", "needle": "FP_ERROR:", "max": 0, "profiles": [PROFILE_ALWAYS]},
		{"id": "no_crash_success", "needle": "crash_success", "max": 0, "profiles": [PROFILE_ALWAYS]},
	]


static func _validator_f5_trace_tracks() -> Array:
	return [
		{
			"id": "turn_ready_gauge",
			"needle": NEEDLE_TURN_READY_GAUGE,
			"min": 1,
			"profiles": [PROFILE_7V7, PROFILE_PRESET_II8],
		},
		{
			"id": "gauge_stm_ready",
			"regex": "turn_ready_gauge .* label=.*Stm .*Ready",
			"min": 1,
			"profiles": [PROFILE_7V7, PROFILE_PRESET_II8],
		},
		{
			"id": "tooltip_match_ok",
			"needle": NEEDLE_TOOLTIP_OK,
			"min": 1,
			"profiles": [PROFILE_7V7, PROFILE_PRESET_II8],
		},
		{
			"id": "tooltip_mismatch_low",
			"needle": "tooltip_match=mismatch",
			"max": 0,
			"profiles": [PROFILE_7V7, PROFILE_PRESET_II8],
			"when_ok_at_least": "tooltip_match_ok",
		},
		{
			"id": "diagram_banner",
			"needle": NEEDLE_DIAGRAM_BANNER,
			"min": 1,
			"profiles": [PROFILE_7V7, PROFILE_PRESET_II8],
			"optional": true,
		},
	]


static func _validator_7v7_tracks() -> Array:
	return [
		{
			"id": "7v7_formation_mode",
			"needle": NEEDLE_ENGAGEMENT_FORMATION,
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "formation_moves",
			"needle": "rotate_file",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
			"alt_needles": ["swap_rank"],
		},
		{
			"id": "medical_phase",
			"needle": "medical_phase",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "medical_action_pick",
			"needle": "medical_action pick",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "medical_pack_pick",
			"needle": "medical_pack_wound pick",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
			"alt_needles": [
				"medical_action pick move=pack_wound",
				"medical_pack_wound listed",
			],
		},
		{
			"id": "exhaustion_bands",
			"needle": "exhaustion",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "soak_fight_end",
			"needle": NEEDLE_SOAK_FIGHT_END,
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "engagement_transition",
			"needle": "engagement_transition",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "phase_end",
			"needle": "phase_end winner=",
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
		{
			"id": "parry_trace",
			"needle": NEEDLE_PARRY_TRACE,
			"min": 1,
			"profiles": [PROFILE_7V7],
			"optional": true,
		},
	]


static func _validator_ii2b_tracks() -> Array:
	return [
		{"id": "ii2b_duel", "needle": NEEDLE_ENGAGEMENT_DUEL, "min": 1, "profiles": [PROFILE_PRESET_II2B]},
		{"id": "ii2b_parry", "needle": NEEDLE_PARRY_TRACE, "min": 1, "profiles": [PROFILE_PRESET_II2B]},
		{
			"id": "ii2b_bind_or_flurry",
			"needle": "parry_bind",
			"min": 1,
			"profiles": [PROFILE_PRESET_II2B],
			"optional": true,
			"alt_needles": ["flurry_bind", "parry_deflect", "riposte_chain"],
		},
	]


static func _validator_ii3_tracks() -> Array:
	return [
		{"id": "ii3_arc_overlap", "needle": "Arc overlap", "min": 1, "profiles": [PROFILE_PRESET_II3]},
		{
			"id": "ii3_parry",
			"needle": NEEDLE_PARRY_TRACE,
			"min": 1,
			"profiles": [PROFILE_PRESET_II3],
			"optional": true,
		},
	]


static func _validator_ii5_tracks() -> Array:
	return [
		{
			"id": "ii5_cowering_listed",
			"needle": "cowering_fall_back listed",
			"min": 1,
			"profiles": [PROFILE_PRESET_II5],
		},
		{
			"id": "ii5_cowering_executed",
			"needle": "cowering_fall_back executed",
			"min": 1,
			"profiles": [PROFILE_PRESET_II5],
			"optional": true,
			"alt_needles": ["fall_back pick", "cowering_fall_back pick"],
		},
	]


static func _validator_ii6_tracks() -> Array:
	return [
		{"id": "ii6_setup", "needle": "soak_setup ii6", "min": 1, "profiles": [PROFILE_PRESET_II6]},
		{"id": "ii6_ambient", "needle": "ambient_pain_shock", "min": 1, "profiles": [PROFILE_PRESET_II6]},
		{
			"id": "ii6_companion",
			"needle": "ambient_pain_shock Companion",
			"min": 1,
			"profiles": [PROFILE_PRESET_II6],
			"optional": true,
			"alt_needles": ["ambient_pain_shock Main", "ambient_pain_shock Character"],
		},
	]


static func _validator_ii8_tracks() -> Array:
	return [
		{
			"id": "ii8_formation_mode",
			"needle": NEEDLE_ENGAGEMENT_FORMATION,
			"min": 1,
			"profiles": [PROFILE_PRESET_II8],
		},
		{
			"id": "ii8_diagram_banner",
			"needle": NEEDLE_DIAGRAM_BANNER,
			"min": 1,
			"profiles": [PROFILE_PRESET_II8],
			"optional": true,
		},
	]


static func _validator_ii4d_tracks() -> Array:
	return [
		{
			"id": "ii4d_duel",
			"needle": NEEDLE_ENGAGEMENT_DUEL,
			"min": 1,
			"profiles": [PROFILE_PRESET_II4D],
			"optional": true,
		},
		{
			"id": "ii4d_exhaustion",
			"needle": "crossed 25",
			"min": 1,
			"profiles": [PROFILE_PRESET_II4D],
			"optional": true,
			"alt_needles": ["exhaustion"],
		},
	]


static func _validator_ii_envelop_tracks() -> Array:
	return [
		{"id": "ii_envelop_setup", "needle": "soak_setup ii_envelop", "min": 1, "profiles": [PROFILE_PRESET_II_ENVELOP]},
		{
			"id": "ii_envelop_skirmish",
			"needle": "engagement mode=Skirmish",
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
		},
		{
			"id": "ii_envelop_wing",
			"needle": "attempt_close@",
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
			"alt_needles": ["Stack hold_line", "rotate_file@", "hit_resolve "],
		},
		{
			"id": "ii_envelop_hit",
			"needle": "hit_resolve ",
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
		},
		{
			"id": "ii_envelop_mopup",
			"needle": "mop_up=true",
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
			"alt_needles": ["soak_setup ii_envelop_mopup"],
		},
		{
			"id": "ii_envelop_mopup_rotate_suppress",
			"needle": "rotate_suppress=true",
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
			"optional": true,
		},
		{
			"id": "ii_envelop_mopup_hold_hint",
			"needle": "Mop-up",
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
			"optional": true,
			"alt_needles": ["hold_line_hint_ok", "finish the last enemy"],
		},
		{
			"id": "ii_envelop_mopup_strike_finish",
			"regex": REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED,
			"min": 1,
			"profiles": [PROFILE_PRESET_II_ENVELOP],
			"optional": true,
			"when_ok_at_least": "mop_up=true",
		},
	]


static func _validator_wf_footing_tracks() -> Array:
	## WF-M3 F5 paste checks — gated on **`turn_ready_gauge`** presence (Camp-5 human footing).
	return [
		{
			"id": "wf_m3_turn_ready_form",
			"regex": "turn_ready_gauge .* label=.* Form ",
			"min": 1,
			"profiles": [PROFILE_ALWAYS],
			"when_ok_at_least": "turn_ready_gauge",
		},
		{
			"id": "wf_m3_grd_before_form",
			"regex": "turn_ready_gauge .* label=.*(?:Grd|Atk) .+ Form ",
			"min": 1,
			"profiles": [PROFILE_ALWAYS],
			"when_ok_at_least": "turn_ready_gauge",
		},
		{
			"id": "wf_m3_form_switch",
			"needle": "form_switch id=",
			"min": 1,
			"profiles": [PROFILE_ALWAYS],
			"optional": true,
		},
		{
			"id": "wf_m3_idle_step_leak",
			"regex": "turn_ready_gauge .* label=Stm [0-9]+% · Ready · Step",
			"max": 0,
			"profiles": [PROFILE_ALWAYS],
			"when_ok_at_least": "turn_ready_gauge",
			"optional": true,
		},
		{
			"id": "wf_controlling_close_hint",
			"needle": "controlling_close_list ",
			"min": 1,
			"profiles": [PROFILE_ALWAYS],
			"optional": true,
		},
	]


static func _validator_mopup_strike_finish_tracks() -> Array:
	## III-4 **3e** — listed strikes during mop-up (7v7 campaign fights + Camp paste).
	return [
		{
			"id": "camp_mopup_strike_finish",
			"regex": REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED,
			"min": 1,
			"profiles": [PROFILE_CAMP_EA, PROFILE_7V7],
			"optional": true,
			"when_ok_at_least": "mop_up=true",
		},
	]


static func _validator_line_plug_pick_tracks() -> Array:
	## III-6 maintain — F5 / Camp paste when rear plugs rank-0 gap (`line_plug_pick=1`).
	return [
		{
			"id": "camp_line_plug_pick",
			"regex": REGEX_ENGAGEMENT_DEBUG_LINE_PLUG_PICK,
			"min": 1,
			"profiles": [PROFILE_CAMP_EA, PROFILE_7V7, PROFILE_PRESET_II_ENVELOP],
			"optional": true,
			"when_ok_at_least": "line_plug=true",
		},
	]


static func _validator_camp_ea_tracks() -> Array:
	return [
		{
			"id": "camp_settlement_continue",
			"needle": "settlement_continue",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
			"alt_needles": ["contract_victory pay="],
		},
		{
			"id": "camp_company_day",
			"needle": "company_day_advanced",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_field_care",
			"needle": "field_care:",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_field_care_action",
			"needle": "field_care bandage",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
			"alt_needles": [
				"field_care pressure part=",
				"field_care stabilize part=",
				"field_care bandage part=",
				"parts_left=",
			],
		},
		{
			"id": "camp_paid_loss",
			"regex": "company_run_end reason=contract_failed.*reload=true",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_tutorial_soft_loss",
			"regex": "company_run_end reason=tutorial_failed.*reload=false",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_wage_warn",
			"needle": "company_wages: gold=",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
			"alt_needles": ["Wages short — paid"],
		},
		{
			"id": "camp_desertion",
			"needle": "desertion summary=",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_run_end",
			"needle": "company_run_end reason=",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_party_triage",
			"needle": "party_triage_open",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
		{
			"id": "camp_medical_exit",
			"needle": "campaign_medical_exit",
			"min": 1,
			"profiles": [PROFILE_CAMP_EA],
			"optional": true,
		},
	]


static func _profile_set_includes_trace_profiles(profiles: PackedStringArray) -> bool:
	for p in profiles:
		if p == PROFILE_7V7 or p == PROFILE_PRESET_II8:
			return true
	return false


static func _track_applies(spec: Dictionary, active_profiles: PackedStringArray) -> bool:
	for p in spec.get("profiles", []) as Array:
		if str(p) in active_profiles:
			return true
	return false


static func _blob_has(blob: String, needles: Array) -> bool:
	for n in needles:
		if str(n) in blob:
			return true
	return false


## Lines inside **`[preset] pass=...`** block from **`.d001_soak_out.txt`** (harness report, not raw FP_COMBAT).
static func d001_report_section_lines(all_lines: PackedStringArray, preset_id: String) -> PackedStringArray:
	var pid: String = preset_id.strip_edges().to_lower()
	var in_section: bool = false
	var out: PackedStringArray = PackedStringArray()
	for raw in all_lines:
		var line: String = str(raw).strip_edges()
		if line.begins_with("[%s]" % pid):
			in_section = true
			continue
		if in_section and line.begins_with("[") and not line.begins_with("[%s]" % pid):
			break
		if in_section:
			out.append(line)
	return out


static func d001_report_pass(all_lines: PackedStringArray, preset_id: String) -> bool:
	var pid: String = preset_id.strip_edges().to_lower()
	for raw in all_lines:
		var line: String = str(raw).strip_edges()
		if line.begins_with("[%s]" % pid):
			return "pass=true" in line
	return false


static func d001_report_check_pass(section: PackedStringArray, check_id: String) -> bool:
	for raw in section:
		var line: String = str(raw).strip_edges()
		if line.begins_with("%s: PASS" % check_id):
			return true
	return false


static func d001_report_field_line(section: PackedStringArray, prefix: String) -> String:
	for raw in section:
		var line: String = str(raw).strip_edges()
		if line.begins_with(prefix):
			return line
	return ""
