class_name CombatConstantsMuscleFatigue
extends RefCounted

const FEATURE_MUSCLE_GROUP_FATIGUE := true

const MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR: float = 0.4

const MUSCLE_FATIGUE_EXERTION_PER_BREATH_POINT: float = 0.012

const MUSCLE_FATIGUE_FORMATION_DAMP_FLOOR: float = 0.45

const MUSCLE_FATIGUE_OFFENSE_DAMP_FLOOR: float = 0.55

const MUSCLE_FATIGUE_PARRY_CAPACITY_FLOOR: float = 0.35

const MUSCLE_FATIGUE_RECOVERING_RATE_MULT: float = 0.5

const MUSCLE_FATIGUE_RECOVERY_RATE: float = 0.06

const MUSCLE_FATIGUE_TWO_HANDED_OFF_ARM_SHARE: float = 0.3

const MUSCLE_FATIGUE_UI_SHOW_THRESHOLD: float = 0.12

const MUSCLE_FATIGUE_WAIT_RECOVERY_BOOST_TOP: float = 1.6

const MUSCLE_FATIGUE_WIND_UP_PERF_FLOOR: float = 0.45

static var _feature_muscle_group_fatigue_load: int = -1

static func is_feature_muscle_group_fatigue_enabled() -> bool:
    if _feature_muscle_group_fatigue_load >= 0:
        return _feature_muscle_group_fatigue_load != 0
    return FEATURE_MUSCLE_GROUP_FATIGUE



static func set_feature_muscle_group_fatigue_load(enabled: bool) -> void:
    _feature_muscle_group_fatigue_load = 1 if enabled else 0
