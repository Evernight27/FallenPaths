class_name CombatConstantsMoves
extends RefCounted

# Move IDs (medical actions) — defined first so arrays can reference them.
const MOVE_ID_BANDAGE_SELF: String = "bandage_self"
const MOVE_ID_BANDAGE_ALLY: String = "bandage_ally"
const MOVE_ID_PACK_WOUND: String = "pack_wound"
const MOVE_ID_PACK_ALLY: String = "pack_ally"
const MOVE_ID_STABILIZE_WOUND: String = "stabilize_wound"
const MOVE_ID_STABILIZE_ALLY: String = "stabilize_ally"
const MOVE_ID_APPLY_TOURNIQUET: String = "apply_tourniquet"
const MOVE_ID_APPLY_TOURNIQUET_ALLY: String = "apply_tourniquet_ally"
const MOVE_ID_HOLD_DIRECT_PRESSURE: String = "hold_direct_pressure"
const MOVE_ID_HOLD_DIRECT_PRESSURE_ALLY: String = "hold_direct_pressure_ally"
const MOVE_ID_RELEASE_DIRECT_PRESSURE: String = "release_direct_pressure"
const MOVE_ID_RELEASE_DIRECT_PRESSURE_ALLY: String = "release_direct_pressure_ally"

const DRESSING_MEDICAL_MOVE_IDS: Array[String] = [MOVE_ID_BANDAGE_SELF, MOVE_ID_PACK_WOUND, MOVE_ID_STABILIZE_WOUND, MOVE_ID_BANDAGE_ALLY, MOVE_ID_PACK_ALLY, MOVE_ID_STABILIZE_ALLY]

const FOCUS_LINE_MOVE_IDS: Array[String] = [
    MOVE_ID_FOCUS_HIGH,
    MOVE_ID_FOCUS_LOW,
    MOVE_ID_FOCUS_LEFT,
    MOVE_ID_FOCUS_RIGHT,
]

const MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY := 0.18

const MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS := 0.12

const MEDICAL_MOVE_IDS: Array[String] = [
    MOVE_ID_BANDAGE_SELF,
    MOVE_ID_PACK_WOUND,
    MOVE_ID_STABILIZE_WOUND,
    MOVE_ID_APPLY_DIRECT_PRESSURE,
    MOVE_ID_APPLY_TOURNIQUET,
    MOVE_ID_BANDAGE_ALLY,
    MOVE_ID_PACK_ALLY,
    MOVE_ID_STABILIZE_ALLY,
    MOVE_ID_APPLY_TOURNIQUET_ALLY,
    MOVE_ID_HOLD_DIRECT_PRESSURE_ALLY,
    MOVE_ID_RELEASE_DIRECT_PRESSURE_ALLY,
]

const MEDICAL_WINDUP_PRIMARY_HOLDER_DURATION_BONUS := 0.40

const MEDICAL_WINDUP_STACK_ASSIST_DURATION_BONUS := 0.25

const MOVE_ID_APPLY_DIRECT_PRESSURE := "apply_direct_pressure"

const MOVE_ID_EXECUTE := "execute"

const MOVE_ID_FEINT := "feint"

const MOVE_ID_FOCUS_HIGH := "focus_high"

const MOVE_ID_FOCUS_LEFT := "focus_left"

const MOVE_ID_FOCUS_LOW := "focus_low"

const MOVE_ID_FOCUS_RIGHT := "focus_right"

const MOVE_ID_HEAVY := "heavy"

const MOVE_ID_MEDIUM := "medium"

const MOVE_ID_QUICK := "quick"

const MOVE_ID_WAIT := "wait"


static func guard_line_for_focus_move_id(move_id: String) -> String:
    match move_id:
        MOVE_ID_FOCUS_HIGH:
            return "high"
        MOVE_ID_FOCUS_LOW:
            return "low"
        MOVE_ID_FOCUS_LEFT:
            return "left"
        MOVE_ID_FOCUS_RIGHT:
            return "right"
        _:
            return ""


static func is_direct_pressure_move(move_id: String) -> bool:
    return move_id == MOVE_ID_APPLY_DIRECT_PRESSURE


static func is_execute_move(move_id: String) -> bool:
    return move_id == MOVE_ID_EXECUTE


static func is_dressing_medical_move(move_id: String) -> bool:
    return move_id in DRESSING_MEDICAL_MOVE_IDS


static func is_focus_line_move(move_id: String) -> bool:
    return move_id in FOCUS_LINE_MOVE_IDS


static func is_medical_move(move_id: String) -> bool:
    return move_id in MEDICAL_MOVE_IDS


static func is_medical_target_method(target_method: String) -> bool:
    return (
        target_method
        in [
            CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_BANDAGE,
            CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_PACKING,
            CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_STABILIZE,
            CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_TOURNIQUET,
        ]
    )


static func is_pack_wound_move(move_id: String) -> bool:
    return move_id == MOVE_ID_PACK_WOUND


static func is_stabilize_wound_move(move_id: String) -> bool:
    return move_id == MOVE_ID_STABILIZE_WOUND


static func is_tourniquet_move(move_id: String) -> bool:
    return move_id == MOVE_ID_APPLY_TOURNIQUET


static func is_wind_up_medical_move(move_id: String) -> bool:
    return is_medical_move(move_id) and not is_direct_pressure_move(move_id)


static func medical_outcome_string(target_method: String, ok: bool) -> String:
    match target_method:
        CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_BANDAGE:
            return "bandaged" if ok else "bandage_failed"
        CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_STABILIZE:
            return "stabilized" if ok else "stabilize_failed"
        CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_PACKING:
            return "packed" if ok else "packing_failed"
        CombatConstantsMedicalTargets.MOVE_TARGET_APPLY_TOURNIQUET:
            return "tourniquet_applied" if ok else "tourniquet_failed"
        _:
            return ""  # caller falls back to wind_up_cfg.get("outcome", med_id)
