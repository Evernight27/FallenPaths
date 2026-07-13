class_name CombatD001TrackSpecsPartB
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
        {
            "id": "ii_envelop_setup",
            "needle": "soak_setup ii_envelop",
            "min": 1,
            "profiles": [PROFILE_PRESET_II_ENVELOP]
        },
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
        {
            "id": "ii_envelop_sparse_post_flee",
            "needle": "fight_finish=true",
            "min": 1,
            "profiles": [PROFILE_PRESET_II_ENVELOP],
            "optional": true,
            "alt_needles": ["soak_setup ii_envelop_sparse_post_flee fight_finish_ok"],
        },
        {
            "id": "ii_envelop_sparse_close_band",
            "regex": REGEX_ENGAGEMENT_DEBUG_SPARSE_CLOSE_BAND,
            "min": 1,
            "profiles": [PROFILE_PRESET_II_ENVELOP],
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
            "profiles": [PROFILE_PRESET_II_ENVELOP],
            "optional": true,
            "alt_needles": ["soak_setup ii_envelop_sparse_post_flee fight_finish_ok"],
        },
        {
            "id": "ii_line_plug_swap",
            "regex": REGEX_ENGAGEMENT_DEBUG_LINE_PLUG_PICK,
            "min": 1,
            "profiles": [PROFILE_PRESET_II_ENVELOP],
            "optional": true,
            "alt_needles": ["soak_setup ii_line_plug engagement_debug_ok"],
        },
        {
            "id": "ii_line_plug_formation_layer",
            "needle": NEEDLE_ENGAGEMENT_DEBUG_FORMATION_PLUG_LAYER,
            "min": 1,
            "profiles": [PROFILE_PRESET_II_ENVELOP],
            "optional": true,
            "when_ok_at_least": "line_plug_pick=1",
            "alt_needles": ["soak_setup ii_line_plug engagement_debug_ok"],
        },
    ]


static func _validator_wf_footing_tracks() -> Array:
    ## WF-M3 F5 paste checks  -  gated on **`turn_ready_gauge`** presence (Camp-5 human footing).
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
            "regex": "turn_ready_gauge .* label=Stm [0-9]+% . Ready . Step",
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


static func _validator_iv11_tracks() -> Array:
    ## IV-11 slice 10: optional F5 grep when **`FEATURE_LEADER_FORMATION_COMMAND`** exercised in soak.
    return [
        {
            "id": "iv11_leader_order",
            "needle": "leader_order=",
            "min": 1,
            "profiles": [PROFILE_ALWAYS],
            "optional": true,
        },
    ]


static func _validator_mopup_strike_finish_tracks() -> Array:
    ## III-4 **3e**  -  listed strikes during mop-up (7v7 campaign fights + Camp paste).
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
    ## III-6 maintain  -  F5 / Camp paste when rear plugs rank-0 gap (`line_plug_pick=1`).
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


static func _validator_mental_stack_layers_tracks() -> Array:
    ## MS-L8 (post-strike) and MS-L9 (positional awareness)  -  optional F5 grep when FEATURE flags active.
    return [
        {
            "id": "ms_l8_post_strike_layer",
            "needle": NEEDLE_ENGAGEMENT_DEBUG_POST_STRIKE_LAYER,
            "min": 1,
            "profiles": [PROFILE_ALWAYS],
            "optional": true,
        },
        {
            "id": "ms_l9_positional_dis_layer",
            "needle": NEEDLE_ENGAGEMENT_DEBUG_POSITIONAL_DIS_LAYER,
            "min": 1,
            "profiles": [PROFILE_ALWAYS],
            "optional": true,
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
            "needle": "field_care bandage part=",
            "min": 1,
            "profiles": [PROFILE_CAMP_EA],
            "optional": true,
            "alt_needles":
            [
                "field_care pressure part=",
                "field_care stabilize part=",
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
            "needle": "reason=tutorial_failed reload=false",
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
            "alt_needles": ["Wages short  -  paid"],
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
            "needle": "party_triage_open living=",
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
