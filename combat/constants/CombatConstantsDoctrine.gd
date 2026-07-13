class_name CombatConstantsDoctrine
extends RefCounted

const DOCTRINE_AI_WEIGHT_MULT_MAX := 2.6

const DOCTRINE_AI_WEIGHT_MULT_MIN := 0.35

const DOCTRINE_COMMITMENT_DURATION_S := 4.5

const DOCTRINE_COMMIT_MATCH_WEIGHT_MULT := 1.28

const DOCTRINE_DEFAULT := "default"

const DOCTRINE_FILE_OPPOSED_WEIGHT_MULT := 1.42

const DOCTRINE_HOLD_LANE := "hold_lane"

const DOCTRINE_HOLD_LANE_OFF_FILE_MULT := 0.58

const DOCTRINE_PINCER_CLOSE_ARC_SPREAD_MULT := 0.92

const DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT := 1.28

const DOCTRINE_PINCH_CENTER := "pinch_center"

const DOCTRINE_PINCH_INWARD_BIAS_PER_FILE := 0.18

const DOCTRINE_PRESSURE_COUNT_REF := 3.0

const DOCTRINE_PRESSURE_DECAY_PER_ALLY := 0.22

const DOCTRINE_PROBING := "probing"

const DOCTRINE_SOFT_DISTANCE_SCALE := 0.55

const ENVELOP_MOP_UP_CLOSE_AI_WEIGHT_MULT := 1.28

const ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT := 0.15

const ENVELOP_MOP_UP_MAX_ENEMY_ACTIVE := 1

const ENVELOP_MOP_UP_MIN_OUR_ACTIVE := 2

const ENVELOP_MOP_UP_PLUG_FORWARD_ENABLED := true

const ENVELOP_MOP_UP_ROTATE_AI_WEIGHT_MULT := 0.12

const PLUG_FORWARD_AI_HIGH_WEIGHT := 1.5

const PLUG_FORWARD_AI_LOW_WEIGHT := 0.3

const PLUG_FORWARD_DURATION_S := 0.6

static func encounter_formation_doctrine_string(encounter: Dictionary, primary_key: String, alt_key: String) -> String:
    return formation_doctrine_string_from_dict(encounter, primary_key, alt_key)



static func formation_doctrine_string_from_dict(source: Dictionary, primary_key: String, alt_key: String) -> String:
    var s: String = source.get(primary_key, "").strip_edges()
    if s.is_empty():
        s = source.get(alt_key, "").strip_edges()
    return s



static func rout_thresholds_for_encounter_and_preset(
    encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
    var out: Dictionary = {}
    var fid: String = str(formation_id)
    var enc_coh_key: String = (
        CombatConstantsEncounter.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER
        if fid == CombatConstantsMisc.SIDE_PLAYER
        else CombatConstantsEncounter.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY
    )
    var enc_cas_key: String = (
        CombatConstantsEncounter.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER
        if fid == CombatConstantsMisc.SIDE_PLAYER
        else CombatConstantsEncounter.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY
    )
    if encounter.has(enc_coh_key):
        var coh_key: String = CombatConstantsDepthPolearm.ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX
        out[coh_key] = clampf(float(encounter[enc_coh_key]), 0.05, 0.95)
    if encounter.has(enc_cas_key):
        var cas_key: String = CombatConstantsDepthPolearm.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN
        out[cas_key] = clampf(float(encounter[enc_cas_key]), 0.05, 0.90)
    if preset.has(CombatConstantsDepthPolearm.FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX):
        out[CombatConstantsDepthPolearm.ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX] = clampf(
            float(preset[CombatConstantsDepthPolearm.FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX]), 0.05, 0.95
        )
    if preset.has(CombatConstantsDepthPolearm.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN):
        out[CombatConstantsDepthPolearm.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN] = clampf(
            float(preset[CombatConstantsDepthPolearm.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN]), 0.05, 0.90
        )
    return out
