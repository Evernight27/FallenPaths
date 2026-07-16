class_name CombatConstantsTiming
extends RefCounted

## Timing constants extracted from CombatConstants.gd for easier tuning.
## Preload this module instead of CombatConstants when you only need timing values.
## Original source: CombatConstants.gd lines ~31-50.

# Attack timing (seconds)
const WIND_UP_BASE_S: float = 0.25
const WIND_UP_SCALE_S: float = 0.6
const RECOVERY_BASE_S: float = 0.2
const RECOVERY_COMMITMENT_SCALE_S: float = 0.5
const RECOVERY_EXTRA_HIT_S: float = 0.0
const RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S: float = -0.06
const RECOVERY_EXTRA_DEFLECTED_BASE_S: float = 0.1
const RECOVERY_DEFLECT_MOMENTUM_SCALE_S: float = 0.15
const RECOVERY_EXTRA_GLANCING_BASE_S: float = 0.12
const RECOVERY_GLANCING_SEVERITY_SCALE_S: float = 0.2
const RECOVERY_EXTRA_MISS_BASE_S: float = 0.35
const RECOVERY_MISS_COMMITMENT_SCALE_S: float = 0.9
const RECOVERY_EXTRA_FULL_STOP_BASE_S: float = 0.5
const RECOVERY_FULL_STOP_COMMITMENT_SCALE_S: float = 0.35
const WINDUP_LEG_MIN: float = 0.2
const WIND_UP_DURATION_MAX_S: float = 2.4
const RECOVERY_AFTER_MEDICAL_S: float = 0.5

# Power and follow_through (0.2-1.0 each); intensity drives velocity, wind-up, recovery.
const POWER_MIN: float = 0.2
const POWER_MAX: float = 1.0
const FOLLOW_THROUGH_MIN: float = 0.2
const FOLLOW_THROUGH_MAX: float = 1.0
const INTENSITY_MIN: float = 0.2

# Afterblow timing
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5
