class_name CombatConstantsDepthPolearm
extends RefCounted

const Formation := preload("res://combat/constants/CombatConstantsFormation.gd")

const DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT := 0.82

const DEPTH_POLEARM_AI_DOCTRINE_HOLD_NON_STAB_MULT := 1.06

const DEPTH_POLEARM_AI_DOCTRINE_HOLD_STAB_MULT := 0.94

const DEPTH_POLEARM_AI_DOCTRINE_PINCH_NON_STAB_MULT := 0.92

const DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT := 1.08

const DEPTH_POLEARM_AI_DOCTRINE_PROBING_NON_STAB_MULT := 0.99

const DEPTH_POLEARM_AI_DOCTRINE_PROBING_STAB_MULT := 1.01

const DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB := "hold_non_stab"

const DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB := "hold_stab"

const DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB := "pinch_non_stab"

const DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB := "pinch_stab"

const DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB := "probing_non_stab"

const DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB := "probing_stab"

const DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX := 1.5

const DEPTH_POLEARM_AI_MULT_OVERRIDE_MIN := 0.5

const DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT := 0.9

const DEPTH_POLEARM_AI_STAB_WEIGHT_MULT := 1.35

const DEPTH_POLEARM_LANE_TYPE_OPEN := "open"

const DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER := "over_shoulder"

const DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES := 1

const DEPTH_SPEAR_LANE_STRESS_OPEN_MIN := DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN

const DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT := 1.05

const DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT := 1.03

const DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT := 1.06

const DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN := 0.38

const ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY := "depth_polearm_ai_doctrine_mults_enemy"

const ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER := "depth_polearm_ai_doctrine_mults_player"


static func default_depth_polearm_ai_doctrine_mults_dict() -> Dictionary:
    return {
        DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB: DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT,
        DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB: DEPTH_POLEARM_AI_DOCTRINE_HOLD_STAB_MULT,
        DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB: DEPTH_POLEARM_AI_DOCTRINE_PROBING_STAB_MULT,
        DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB: DEPTH_POLEARM_AI_DOCTRINE_PINCH_NON_STAB_MULT,
        DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB: DEPTH_POLEARM_AI_DOCTRINE_HOLD_NON_STAB_MULT,
        DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB: DEPTH_POLEARM_AI_DOCTRINE_PROBING_NON_STAB_MULT,
    }


static func depth_polearm_ai_doctrine_mults_for_encounter_and_preset(
    encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
    var base: Dictionary = default_depth_polearm_ai_doctrine_mults_dict()
    var enc_key: String = (
        ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER
        if str(formation_id) == CombatConstantsMisc.SIDE_PLAYER
        else ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY
    )
    var after_enc: Dictionary = merge_depth_polearm_ai_doctrine_mults(base, encounter.get(enc_key))
    var preset_overlay: Variant = preset.get(Formation.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS)
    return merge_depth_polearm_ai_doctrine_mults(after_enc, preset_overlay)


static func merge_depth_polearm_ai_doctrine_mults(base: Dictionary, overlay: Variant) -> Dictionary:
    var out: Dictionary = base.duplicate(true)
    if overlay == null or not overlay is Dictionary:
        return out
    var keys: Array = [
        DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB,
        DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB,
        DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB,
        DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB,
        DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB,
        DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB,
    ]
    var o: Dictionary = overlay as Dictionary
    for k in keys:
        if not o.has(k):
            continue
        var v: Variant = o[k]
        var tv: int = typeof(v)
        var f: float = -1.0
        if tv == TYPE_FLOAT or tv == TYPE_INT:
            f = float(v)
        elif tv == TYPE_STRING and String(v).is_valid_float():
            f = float(v)
        if f > 0.0:
            out[k] = clampf(f, DEPTH_POLEARM_AI_MULT_OVERRIDE_MIN, DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX)
    return out
