class_name CombatD001TrackSpecs
extends RefCounted
## Shared **D-001** grep needles for **`CombatD001SoakRunner`** (headless) and **`CombatF5SoakLogValidator`** (F5
## paste).

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
## III-4 **3e**  -  combat-phase mop-up with listed strikes (shared by headless + F5 validator).
const REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED := (
    "engagement_debug turn .* mop_up=true .* (menu=strikes_listed|stri" + "kes=[1-9])"
)
## III-6 maintain  -  rank-0 gap or incap plug-forward pick (`line_plug_pick=1`; log sets `line_plug=true` for both).
const REGEX_ENGAGEMENT_DEBUG_LINE_PLUG_PICK := "engagement_debug turn .* line_plug=true .* line_plug_pick=1"
## MS-L5  -  mental-stack plug layer stamped on rank-0 gap / incap plug picks.
const NEEDLE_ENGAGEMENT_DEBUG_FORMATION_PLUG_LAYER := "layer=formation_plug"
## III-4 **3e** post-flee sparse  -  CLOSE-band rotate suppress + mental-stack fight-first layer.
const REGEX_ENGAGEMENT_DEBUG_SPARSE_CLOSE_BAND := (
    "engagement_debug turn .*(?:rotate_suppress=true).*?(?:sparse_line=true)"
    + "|engagement_debug turn .*(?:sparse_line=true).*?(?:rotate_suppress=true)"
)
const REGEX_ENGAGEMENT_DEBUG_SPARSE_FIGHT_LAYER := "engagement_debug turn .* layer=sparse_fight"
## MS-L8: post-strike momentum layer stamped on press-the-target picks.
const NEEDLE_ENGAGEMENT_DEBUG_POST_STRIKE_LAYER := "layer=post_strike"
## MS-L9: positional awareness layer stamped on surrounded-disengage picks.
const NEEDLE_ENGAGEMENT_DEBUG_POSITIONAL_DIS_LAYER := "layer=positional_dis"
const _HEADLESS_ONLY_CHECK_IDS: Dictionary = {
    "soak_tag": true,
    "soak_setup": true,
    "fight_enter": true,
    "party_count": true,
    "no_script_error": true,
    "no_fp_error": true,
    "no_crash_success_log": true,
}


static func headless_checks_for_preset(preset_id: String) -> Array:
    var checks: Array = D001TrackSpecsNeedles._headless_policy_checks()
    checks.append({"id": "soak_tag", "needle": "soak=%s" % preset_id, "min": 1})
    checks.append_array(D001TrackSpecsNeedles._headless_preset_checks(preset_id))
    return checks


static func detect_profiles(normalized: PackedStringArray) -> PackedStringArray:
    var profiles: PackedStringArray = PackedStringArray([PROFILE_ALWAYS])
    var blob: String = "\n".join(normalized)
    if D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter preset=ii2b", "soak=ii2b", "dev_soak=ii2b"]):
        profiles.append(PROFILE_PRESET_II2B)
    if D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter preset=ii3", "soak=ii3"]):
        profiles.append(PROFILE_PRESET_II3)
    if D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter preset=ii5", "soak=ii5"]):
        profiles.append(PROFILE_PRESET_II5)
    if D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter preset=ii6", "soak=ii6"]):
        profiles.append(PROFILE_PRESET_II6)
    if D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter preset=ii8", "soak=ii8"]):
        profiles.append(PROFILE_PRESET_II8)
    if D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter preset=ii4d", "soak=ii4d", "dev_soak=ii4d"]):
        profiles.append(PROFILE_PRESET_II4D)
    if D001TrackSpecsProfiles._blob_has(
        blob, ["soak_fight_enter preset=ii_envelop", "soak=ii_envelop", "dev_soak=ii_envelop"]
    ):
        profiles.append(PROFILE_PRESET_II_ENVELOP)
    if D001TrackSpecsNeedles._camp_ea_profile_active(normalized):
        profiles.append(PROFILE_CAMP_EA)
    if (
        D001TrackSpecsProfiles._blob_has(blob, ["soak_fight_enter tile=red", "tile=red"])
        or (
            not (
                D001TrackSpecsProfiles
                . _blob_has(
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
            )
            and normalized.size() > 80
        )
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
    tracks.append_array(D001TrackSpecsNeedles._validator_always_tracks())
    if D001TrackSpecsProfiles._profile_set_includes_trace_profiles(active_profiles):
        tracks.append_array(D001TrackSpecsNeedles._validator_f5_trace_tracks())
    if have.has(PROFILE_7V7):
        tracks.append_array(D001TrackSpecsNeedles._validator_7v7_tracks())
    if have.has(PROFILE_PRESET_II2B):
        tracks.append_array(D001TrackSpecsNeedles._validator_ii2b_tracks())
    if have.has(PROFILE_PRESET_II3):
        tracks.append_array(D001TrackSpecsNeedles._validator_ii3_tracks())
    if have.has(PROFILE_PRESET_II5):
        tracks.append_array(D001TrackSpecsNeedles._validator_ii5_tracks())
    if have.has(PROFILE_PRESET_II6):
        tracks.append_array(D001TrackSpecsNeedles._validator_ii6_tracks())
    if have.has(PROFILE_PRESET_II8):
        tracks.append_array(D001TrackSpecsProfiles._validator_ii8_tracks())
    if have.has(PROFILE_PRESET_II4D):
        tracks.append_array(D001TrackSpecsProfiles._validator_ii4d_tracks())
    if have.has(PROFILE_PRESET_II_ENVELOP):
        tracks.append_array(D001TrackSpecsProfiles._validator_ii_envelop_tracks())
    tracks.append_array(D001TrackSpecsProfiles._validator_wf_footing_tracks())
    tracks.append_array(D001TrackSpecsProfiles._validator_iv11_tracks())
    tracks.append_array(D001TrackSpecsProfiles._validator_mental_stack_layers_tracks())
    if have.has(PROFILE_7V7) or have.has(PROFILE_CAMP_EA) or have.has(PROFILE_PRESET_II_ENVELOP):
        tracks.append_array(D001TrackSpecsProfiles._validator_mopup_strike_finish_tracks())
        tracks.append_array(D001TrackSpecsProfiles._validator_line_plug_pick_tracks())
    if have.has(PROFILE_CAMP_EA):
        tracks.append_array(D001TrackSpecsProfiles._validator_camp_ea_tracks())
    return tracks.filter(
        func(spec: Dictionary) -> bool: return D001TrackSpecsProfiles._track_applies(spec, active_profiles)
    )


## Maps headless preset id -> validator profile id (`preset_ii2b`, `7v7`, ...).


## Maps headless preset id -> validator profile id (`preset_ii2b`, `7v7`, ...).
static func preset_id_to_profile(preset_id: String) -> String:
    match preset_id:
        SoakEncounterPresets.PRESET_II2B_SWORD_DUEL:
            return PROFILE_PRESET_II2B
        SoakEncounterPresets.PRESET_II3_SURROUND:
            return PROFILE_PRESET_II3
        SoakEncounterPresets.PRESET_II5_COWERING:
            return PROFILE_PRESET_II5
        SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
            return PROFILE_PRESET_II6
        SoakEncounterPresets.PRESET_II8_FORMATION:
            return PROFILE_PRESET_II8
        SoakEncounterPresets.PRESET_II4D_EXHAUSTION:
            return PROFILE_PRESET_II4D
        SoakEncounterPresets.PRESET_II_ENVELOP:
            return PROFILE_PRESET_II_ENVELOP
        "7v7":
            return PROFILE_7V7
    return ""


## Synthetic log markers so **`detect_profiles`** recognizes a preset in harness alignment tests.


## Synthetic log markers so **`detect_profiles`** recognizes a preset in harness alignment tests.
static func synthetic_profile_markers(preset_id: String) -> PackedStringArray:
    match preset_id:
        SoakEncounterPresets.PRESET_II2B_SWORD_DUEL:
            return PackedStringArray(["soak_fight_enter preset=ii2b", "soak=ii2b"])
        SoakEncounterPresets.PRESET_II3_SURROUND:
            return PackedStringArray(["soak_fight_enter preset=ii3"])
        SoakEncounterPresets.PRESET_II5_COWERING:
            return PackedStringArray(["soak_fight_enter preset=ii5"])
        SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
            return PackedStringArray(["soak_setup ii6", "soak=ii6"])
        SoakEncounterPresets.PRESET_II8_FORMATION:
            return PackedStringArray(["soak_fight_enter preset=ii8"])
        SoakEncounterPresets.PRESET_II4D_EXHAUSTION:
            return PackedStringArray(["soak_fight_enter preset=ii4d", "soak=ii4d"])
        SoakEncounterPresets.PRESET_II_ENVELOP:
            return PackedStringArray(["soak_fight_enter preset=ii_envelop", "soak=ii_envelop"])
        "7v7":
            return PackedStringArray(["soak_fight_enter tile=red 7v7", "soak=7v7"])
        "camp_ea":
            return PackedStringArray(
                [
                    "settlement_continue",
                    "contract_victory pay=",
                    "company_day_advanced",
                ]
            )
    return PackedStringArray()


## Grep needles that activate **`camp_ea`** profile (F5 paste + world trace ingest).


## Grep needles that activate **`camp_ea`** profile (F5 paste + world trace ingest).
static func camp_ea_profile_markers() -> Array:
    return [
        "settlement_continue",
        "contract_victory pay=",
        "campaign_medical_exit",
        "company_day_advanced",
        "company_run_end reason=",
        "field_care:",
        "field_care bandage part=",
        "field_care pressure part=",
        "field_care stabilize part=",
        "company_wages: gold=",
        "Wages short",
        "desertion summary=",
        "party_triage_open living=",
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


## Combat **`FP_COMBAT`** lines merged across F5 fights for in-session camp supplement (prior fights cleared per-fight
## trace).


## Combat **`FP_COMBAT`** lines merged across F5 fights for in-session camp supplement (prior fights cleared per-fight
## trace).
static func is_camp_ea_combat_trace_line(s: String) -> bool:
    var line: String = s.strip_edges()
    if line.is_empty():
        return false
    if "campaign_medical_exit" in line:
        return true
    if not line.begins_with("engagement_debug "):
        return false
    return "mop_up=true" in line or "line_plug=true" in line


## Lines ignored when inferring **`camp_ea`** from pasted F5 / headless capture (matches validator skip rules).


## Lines ignored when inferring **`camp_ea`** from pasted F5 / headless capture (matches validator skip rules).
static func skip_profile_detection_line(line: String) -> bool:
    var s: String = line.strip_edges()
    if s.is_empty():
        return true
    if s.begins_with("soak_coverage "):
        return true
    if s.begins_with("--- FP_F5_SOAK_VALIDATION"):
        return true
    if s.begins_with("[camp_") or s.begins_with("[wf_m3_"):
        return true
    if s.begins_with("soak_guide ") or s.begins_with("soak_guide:"):
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


## True when a required headless needle is matched by some validator track (substring either way).
static func headless_needle_covered_by_validator(headless_needle: String, validator_needles: PackedStringArray) -> bool:
    if headless_needle.is_empty():
        return true
    for v in validator_needles:
        if headless_needle in v or v in headless_needle:
            return true
    return false


## Headless runner checks with no F5-validator analogue (policy, soak tags, setup lines).

## Returns failures when a required headless check has no validator counterpart for its profile.


## Returns failures when a required headless check has no validator counterpart for its profile.
static func headless_validator_coverage_failures() -> PackedStringArray:
    var failures: PackedStringArray = PackedStringArray()
    var preset_ids: PackedStringArray = SoakEncounterPresets.D001_PRESET_RUN_ORDER.duplicate()
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
                failures.append("%s: headless '%s' not covered by validator profile %s" % [preset_id, needle, profile])
        var markers: PackedStringArray = synthetic_profile_markers(preset_id)
        if not markers.is_empty():
            var detected: PackedStringArray = detect_profiles(markers)
            if profile not in detected:
                failures.append("%s: detect_profiles missed %s from markers %s" % [preset_id, profile, str(markers)])
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
        "engagement_debug_sparse_line": count_needle.call(normalized, "sparse_line=true"),
        "engagement_debug_fight_finish": count_needle.call(normalized, "fight_finish=true"),
        "engagement_debug_sparse_prefer_finish": count_needle.call(normalized, "sparse_prefer_finish=true"),
        "engagement_debug_sparse_fight_layer": _count_regex.call(normalized, REGEX_ENGAGEMENT_DEBUG_SPARSE_FIGHT_LAYER),
        "engagement_debug_post_strike_layer": count_needle.call(normalized, NEEDLE_ENGAGEMENT_DEBUG_POST_STRIKE_LAYER),
        "engagement_debug_positional_dis_layer":
        count_needle.call(normalized, NEEDLE_ENGAGEMENT_DEBUG_POSITIONAL_DIS_LAYER),
        "engagement_debug_mopup_strikes_listed":
        _count_regex.call(normalized, REGEX_ENGAGEMENT_DEBUG_MOPUP_STRIKES_LISTED),
        "mopup_gauge_hint": count_needle.call(normalized, "mopup_hold_line_list "),
        "form_switch": count_needle.call(normalized, "form_switch id="),
        "wf_m3_form_on_gauge": _count_regex.call(normalized, "turn_ready_gauge .* label=.* Form "),
        "controlling_close_hint": count_needle.call(normalized, "controlling_close_list "),
        "leader_order": count_needle.call(normalized, "leader_order="),
        "field_care_bandage": count_needle.call(normalized, "field_care bandage part="),
        "field_care_pressure": count_needle.call(normalized, "field_care pressure part="),
        "company_day_advanced": count_needle.call(normalized, "company_day_advanced"),
        "settlement_continue": count_needle.call(normalized, "settlement_continue"),
        "company_wages_warn":
        count_needle.call(normalized, "company_wages: gold=") + count_needle.call(normalized, "Wages short  -  paid"),
        "desertion_summary": count_needle.call(normalized, "desertion summary="),
        "party_triage_open": count_needle.call(normalized, "party_triage_open living="),
    }


## Lines for all preset fights (multi-rep duel sim + optional **`soak_setup`** smoke tail) from a capture blob.


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
            var other_soak: String = D001TrackSpecsNeedles._encounter_soak_id_from_line(line)
            if capturing and not other_soak.is_empty() and other_soak != preset_id:
                capturing = false
            continue
        if setup_tag in line:
            capturing = true
        if capturing:
            out.append(line)
    return out


## Grep counts for **III-3** worksheet prefill (headless  -  not II-2b feel sign-off).
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


## Rollup from **`CombatF5SoakTrace`** session counters at **`soak_fight_end`** (grep **`hit_outcome_stats`**).
static func hit_outcome_stats_summary_line(session_counts: Dictionary) -> String:
    return (
        (
            "hit_outcome_stats hit=%d glancing=%d negligible=%d deflected=%d "
            + "other=%d resolve=%d avoided_miss=%d avoided_dodge=%d"
        )
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


## Parse **`FP_COMBAT: parry_stats deflect=N ...`** rollup (headless II-2b worksheet).


## Parse **`FP_COMBAT: parry_stats deflect=N ...`** rollup (headless II-2b worksheet).
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
        failures.append("partial leaks too high vs clean outcomes (partial=%d cap=%d)" % [partial, partial_cap])
    return failures


## Grep band crossings for **II-4d** headless sign-off (F5 3 - 5 min feel remains optional).


## Grep band crossings for **II-4d** headless sign-off (F5 3 - 5 min feel remains optional).
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
    (
        lines
        . append(
            (
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
        )
    )
    if headless_signed:
        lines.append(CombatConstants.iii3_baseline_constants_line())
        lines.append(CombatConstants.p4d_parry_bind_doc_sync_line())
    lines.append("--- END II-2b worksheet prefill ---")
    return "\n".join(lines) + "\n"


## Mandatory **D-001** tracks satisfied by headless runner (no F5).


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
    var ii2b: Dictionary = preset_results.get(SoakEncounterPresets.PRESET_II2B_SWORD_DUEL, {}) as Dictionary
    if not bool(ii2b.get("ii2b_plausibility_ok", false)):
        for msg in ii2b.get("ii2b_plausibility_failures", PackedStringArray()) as PackedStringArray:
            failures.append("ii2b_plausibility: %s" % msg)
    return failures


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
