class_name D001TrackSpecsNeedles
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


static func _camp_ea_profile_active(normalized: PackedStringArray) -> bool:
    for line in normalized:
        if skip_profile_detection_line(line):
            continue
        if is_camp_ea_world_trace_line(line):
            return true
    return false


## Union of validator track needles (+ alts) for active profiles.


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


## Grep counts for **III-3** worksheet prefill (headless  -  not II-2b feel sign-off).


static func _headless_policy_checks() -> Array:
    return [
        {"id": "no_script_error", "needle": "SCRIPT_ERROR", "min": 0, "max": 0},
        {"id": "no_fp_error", "needle": "FP_ERROR", "min": 0, "max": 0},
        {"id": "no_crash_success_log", "needle": "crash_success", "min": 0, "max": 0},
    ]


static func _headless_preset_checks(preset_id: String) -> Array:
    match preset_id:
        SoakEncounterPresets.PRESET_II2B_SWORD_DUEL:
            return [
                {"id": "duel_mode", "needle": NEEDLE_ENGAGEMENT_DUEL, "min": 1},
                {"id": "parry_trace", "needle": NEEDLE_PARRY_TRACE, "min": 1},
                {"id": "parry_deflect_or_bind", "needle": "parry_deflect", "min": 1, "optional": true},
                {"id": "parry_bind", "needle": "parry_bind", "min": 1, "optional": true},
                {"id": "riposte", "needle": "riposte_chain", "min": 1, "optional": true},
                {"id": "flurry", "needle": "flurry_bind", "min": 1, "optional": true},
            ]
        SoakEncounterPresets.PRESET_II3_SURROUND:
            return [
                {"id": "arc_overlap", "needle": "ui_hint Arc overlap", "min": 1},
                {"id": "parry_trace", "needle": NEEDLE_PARRY_TRACE, "min": 1},
            ]
        SoakEncounterPresets.PRESET_II5_COWERING:
            return [
                {"id": "soak_setup", "needle": "soak_setup ii5", "min": 1},
                {"id": "cowering_listed", "needle": "cowering_fall_back listed", "min": 1},
                {"id": "cowering_executed", "needle": "cowering_fall_back executed", "min": 1},
            ]
        SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
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
        SoakEncounterPresets.PRESET_II8_FORMATION:
            return [
                {"id": "formation_mode", "needle": NEEDLE_ENGAGEMENT_FORMATION, "min": 1},
                {"id": "diagram_banner", "needle": NEEDLE_DIAGRAM_BANNER, "min": 1},
                {"id": "turn_ready_gauge", "needle": NEEDLE_TURN_READY_GAUGE, "min": 1},
                {"id": "tooltip_match_ok", "needle": NEEDLE_TOOLTIP_OK, "min": 1},
            ]
        SoakEncounterPresets.PRESET_II4D_EXHAUSTION:
            return [
                {"id": "duel_mode", "needle": NEEDLE_ENGAGEMENT_DUEL, "min": 1},
                {"id": "exhaustion_25", "needle": "exhaustion", "min": 1},
                {"id": "exhaustion_band", "needle": "crossed 25", "min": 1},
            ]
        SoakEncounterPresets.PRESET_II_ENVELOP:
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
                {
                    "id": "ii_envelop_sparse_post_flee",
                    "needle": "fight_finish=true",
                    "min": 1,
                    "optional": true,
                    "alt_needles":
                    [
                        "soak_setup ii_envelop_sparse_post_flee fight_finish_ok",
                        "soak_setup ii_envelop_sparse_post_flee hold_line_hint_ok",
                        "soak_setup 7v7_sparse_formation hold_line_hint_ok",
                    ],
                },
                {
                    "id": "ii_envelop_sparse_close_band",
                    "regex": REGEX_ENGAGEMENT_DEBUG_SPARSE_CLOSE_BAND,
                    "min": 1,
                    "optional": true,
                    "alt_needles":
                    [
                        "soak_setup ii_envelop_sparse_close_band rotate_suppress_ok",
                        "ii_envelop_sparse_close_band: PASS",
                    ],
                },
                {
                    "id": "ii_envelop_sparse_fight_layer",
                    "regex": REGEX_ENGAGEMENT_DEBUG_SPARSE_FIGHT_LAYER,
                    "min": 1,
                    "optional": true,
                    "alt_needles": ["soak_setup ii_envelop_sparse_post_flee fight_finish_ok"],
                },
                {
                    "id": "ii_line_plug_swap",
                    "regex": REGEX_ENGAGEMENT_DEBUG_LINE_PLUG_PICK,
                    "min": 1,
                    "optional": true,
                    "alt_needles": ["soak_setup ii_line_plug engagement_debug_ok"],
                },
                {
                    "id": "ii_line_plug_formation_layer",
                    "needle": NEEDLE_ENGAGEMENT_DEBUG_FORMATION_PLUG_LAYER,
                    "min": 1,
                    "optional": true,
                    "when_ok_at_least": "line_plug_pick=1",
                    "alt_needles": ["soak_setup ii_line_plug engagement_debug_ok"],
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
            "alt_needles":
            [
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
