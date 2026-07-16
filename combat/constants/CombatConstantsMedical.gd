class_name CombatConstantsMedical
extends RefCounted

## Medical constants extracted from CombatConstants.gd for easier tuning.
## Preload this module when you only need medical move IDs and configuration.

# Move IDs (medical actions)
const MOVE_ID_BANDAGE_SELF: String = "bandage_self"
const MOVE_ID_BANDAGE_ALLY: String = "bandage_ally"
const MOVE_ID_PACK_WOUND: String = "pack_wound"
const MOVE_ID_PACK_ALLY: String = "pack_ally"
const MOVE_ID_STABILIZE_WOUND: String = "stabilize_wound"
const MOVE_ID_STABILIZE_ALLY: String = "stabilize_ally"
const MOVE_ID_APPLY_TOURNIQUET: String = "apply_tourniquet"
const MOVE_ID_APPLY_TOURNIQUET_ALLY: String = "apply_tourniquet_ally"
const MOVE_ID_FREE_PRESSURE: String = "free_pressure"
const MOVE_ID_HOLD_DIRECT_PRESSURE: String = "hold_direct_pressure"
const MOVE_ID_HOLD_DIRECT_PRESSURE_ALLY: String = "hold_direct_pressure_ally"
const MOVE_ID_RELEASE_DIRECT_PRESSURE: String = "release_direct_pressure"
const MOVE_ID_RELEASE_DIRECT_PRESSURE_ALLY: String = "release_direct_pressure_ally"

# Move target methods
const MOVE_TARGET_APPLY_BANDAGE: String = "apply_bandage"
const MOVE_TARGET_APPLY_PACKING: String = "apply_packing"
const MOVE_TARGET_APPLY_STABILIZE: String = "apply_stabilize"
const MOVE_TARGET_APPLY_TOURNIQUET: String = "apply_tourniquet"

# Medical item type
const MEDICAL_ITEM_TOURNIQUET: String = "tourniquet"

# Wind-up config (moved from CombatConstants dictionary). Keys are move IDs; ally /
# target-method aliases resolve via wind_up_config_for().
const MEDICAL_WIND_UP_CONFIG: Dictionary = {
    MOVE_ID_BANDAGE_SELF:
    {
        "duration_method": "get_bandage_application_time_seconds_for_part",
        "duration_takes_part": true,
        "target_method": MOVE_TARGET_APPLY_BANDAGE,
        "outcome": "bandaged"
    },
    MOVE_ID_PACK_WOUND:
    {
        "duration_method": "get_packing_application_time_seconds_for_part",
        "duration_takes_part": true,
        "target_method": MOVE_TARGET_APPLY_PACKING,
        "outcome": "packed"
    },
    MOVE_ID_STABILIZE_WOUND:
    {
        "duration_method": "get_stabilize_application_time_seconds_for_part",
        "duration_takes_part": true,
        "target_method": MOVE_TARGET_APPLY_STABILIZE,
        "outcome": "stabilized",
    },
    MOVE_ID_APPLY_TOURNIQUET:
    {
        "duration_method": "get_tourniquet_application_time_seconds",
        "duration_takes_part": false,
        "target_method": MOVE_TARGET_APPLY_TOURNIQUET,
        "outcome": "tourniquet_applied"
    }
}


## Resolve wind-up config for a medical move id (self, ally, or target-method alias).
static func wind_up_config_for(medical_id: String) -> Dictionary:
    if medical_id.is_empty():
        return {}
    var direct: Variant = MEDICAL_WIND_UP_CONFIG.get(medical_id, {})
    if direct is Dictionary and not (direct as Dictionary).is_empty():
        return direct as Dictionary
    match medical_id:
        MOVE_ID_BANDAGE_ALLY, MOVE_TARGET_APPLY_BANDAGE:
            return MEDICAL_WIND_UP_CONFIG.get(MOVE_ID_BANDAGE_SELF, {}) as Dictionary
        MOVE_ID_PACK_ALLY, MOVE_TARGET_APPLY_PACKING:
            return MEDICAL_WIND_UP_CONFIG.get(MOVE_ID_PACK_WOUND, {}) as Dictionary
        MOVE_ID_STABILIZE_ALLY, MOVE_TARGET_APPLY_STABILIZE:
            return MEDICAL_WIND_UP_CONFIG.get(MOVE_ID_STABILIZE_WOUND, {}) as Dictionary
        MOVE_ID_APPLY_TOURNIQUET_ALLY:
            return MEDICAL_WIND_UP_CONFIG.get(MOVE_ID_APPLY_TOURNIQUET, {}) as Dictionary
        _:
            return {}


## Map medical target_method + success to outcome string.
static func medical_outcome_string(target_method: String, ok: bool) -> String:
    match target_method:
        MOVE_TARGET_APPLY_BANDAGE:
            return "bandaged" if ok else "bandage_failed"
        MOVE_TARGET_APPLY_STABILIZE:
            return "stabilized" if ok else "stabilize_failed"
        MOVE_TARGET_APPLY_PACKING:
            return "packed" if ok else "packing_failed"
        MOVE_TARGET_APPLY_TOURNIQUET:
            return "tourniquet_applied" if ok else "tourniquet_failed"
        _:
            return ""
