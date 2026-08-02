class_name CombatConstantsMuscleFatigue
extends RefCounted

const FEATURE_MUSCLE_GROUP_FATIGUE := true


# --- Feature gate ---

static var _feature_muscle_group_fatigue_load: int = -1


static func is_feature_muscle_group_fatigue_enabled() -> bool:
    if _feature_muscle_group_fatigue_load >= 0:
        return _feature_muscle_group_fatigue_load != 0
    return FEATURE_MUSCLE_GROUP_FATIGUE


static func set_feature_muscle_group_fatigue_load(enabled: bool) -> void:
    _feature_muscle_group_fatigue_load = 1 if enabled else 0


# --- Curve power (shared by all leg-based curves) ---

## Power exponent for the curved degradation formula pow(fatigue, CURVE_POWER).
const MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER: float = 1.3


# --- Leg-based speed / balance / precision floors at max fatigue ---

## Forward step speed floor at max leg fatigue (fraction of base retained).
const MUSCLE_FATIGUE_FORWARD_SPEED_FLOOR_AT_MAX: float = 0.10

## Retreat speed floor at max leg fatigue (fraction of base step speed retained).
const MUSCLE_FATIGUE_RETREAT_SPEED_FLOOR_AT_MAX: float = 0.75

## Lateral movement speed penalty (fraction of forward base retained).
const MUSCLE_FATIGUE_LATERAL_SPEED_PENALTY: float = 0.85

## Balance / stability floor at max leg fatigue (affects dodge via smooth collapse below this).
const MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX: float = 0.30

## Step precision floor at max leg fatigue (affects formation alignment).
const MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX: float = 0.50


# --- Dodge collapse transition ---

## Dodge collapse starts here — at or above this value, dodge transitions to smooth balance_stability curve.
const MUSCLE_FATIGUE_DODGE_COLLAPSE_START: float = 0.85

## Flat dodge floor reached at 100% leg fatigue (after smooth collapse transition).
const MUSCLE_FATIGUE_DODGE_FLAT_FLOOR_AT_MAX: float = 0.15


# --- Arm-based damp floors ---

## Offense weight floor when dominant strike limb is fatigued.
const MUSCLE_FATIGUE_OFFENSE_DAMP_FLOOR: float = 0.55

## Parry capacity floor from dominant-arm fatigue.
const MUSCLE_FATIGUE_PARRY_CAPACITY_FLOOR: float = 0.35

## Wind-up performance floor from dominant-limb fatigue.
const MUSCLE_FATIGUE_WIND_UP_PERF_FLOOR: float = 0.45

## Heavy move off-arm fatigue share on dominant strike limb.
const MUSCLE_FATIGUE_HEAVY_OFF_ARM_PENALTY: float = 0.65


# --- Exertion / recovery rates ---

## Breath points converted to local limb exertion per point spent.
const MUSCLE_FATIGUE_EXERTION_PER_BREATH_POINT: float = 0.012

## Two-handed weapon off-arm share of exertion (dominant gets remainder).
const MUSCLE_FATIGUE_TWO_HANDED_OFF_ARM_SHARE: float = 0.3

## Recovery rate per second while waiting (base, before delta).
const MUSCLE_FATIGUE_RECOVERY_RATE: float = 0.06

## Multiplier for recovery rate while in recovering state (vs waiting).
const MUSCLE_FATIGUE_RECOVERING_RATE_MULT: float = 0.5


# --- AI decision weights ---

## Wait/recovery action weight boost top when dominant limb is fatigued.
const MUSCLE_FATIGUE_WAIT_RECOVERY_BOOST_TOP: float = 1.6


# --- UI thresholds ---

## Fatigue threshold below which muscle fatigue suffixes are hidden from UI.
const MUSCLE_FATIGUE_UI_SHOW_THRESHOLD: float = 0.12
