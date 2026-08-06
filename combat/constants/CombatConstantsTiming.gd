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
## Successful hits (especially penetrating ones) delay recovery as momentum continues through target tissue.
## Models biomechanical reality — a strike that penetrates carries force forward, delaying blade repositioning.
const RECOVERY_EXTRA_HIT_S: float = 0.12
const RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S: float = -0.06
const RECOVERY_EXTRA_DEFLECTED_BASE_S: float = -0.04  # deflecting recovers faster (redirected opponent's energy; HEMA Farbenschlagen principle)
const RECOVERY_DEFLECT_MOMENTUM_SCALE_S: float = 0.15
## Glancing blows vs penetrating hits: glances have higher base recovery (0.25 > 0.12).
## Design rationale: a glance that doesn't fully connect means the attacker's blade slid past —
## they must re-establish their line and recover guard position, which takes time. A penetrating hit
## carries momentum through tissue but the attack path is complete; recovery begins from a stronger
## follow-through position. Severity-scaled: full-severity glances recover faster than negligible
## chips (which add additional recovery via RECOVERY_GLANCING_SEVERITY_SCALE_S).
const RECOVERY_EXTRA_GLANCING_BASE_S: float = 0.25
const RECOVERY_GLANCING_SEVERITY_SCALE_S: float = 0.2
const RECOVERY_EXTRA_MISS_BASE_S: float = 0.20
const RECOVERY_MISS_COMMITMENT_SCALE_S: float = 0.60
const RECOVERY_EXTRA_FULL_STOP_BASE_S: float = 0.5
const RECOVERY_FULL_STOP_COMMITMENT_SCALE_S: float = 0.35
## Wind-up energy cap (T_optimal): beyond this duration, no additional strike energy is gained.
## Models HEMA biomechanics — a human holding a weapon at full extension for >0.8s is telegraphing and losing balance.
## Research confirms optimal wind-up is ~0.40s; by 0.7-0.8s the quadratic factor hits 1.0 (full energy).
const WIND_UP_ENERGY_CAP_S: float = 0.75
## Maximum effective wind-up duration after soft cap — absolute ceiling on how long an attack can take.
## Capped at 0.8s to prevent telegraphed attacks with no penalty; any input held beyond this should trigger
## a "committed strike" state where the fighter cannot cancel or redirect the attack without penalty.
const WIND_UP_DURATION_MAX_S: float = 0.8
## Soft cap for wind-up duration — above this, diminishing returns apply (each extra 0.1s costs only 0.2s real time).
## Set at 0.5s so that most attacks naturally fall below the energy cap; power swings get a modest bonus but
## cannot exceed the hard cap of WIND_UP_DURATION_MAX_S.
const WIND_UP_SOFT_CAP_S: float = 0.5
## Hit recovery penalty: successful hits delay recovery by this factor (momentum continues through target tissue).
## Models biomechanical reality — penetrating strikes carry momentum into the target, delaying blade repositioning.
const RECOVERY_HIT_PENALTY_MULT: float = 1.20
## Maximum total recovery time for any single strike outcome (seconds). Prevents compound scaling from producing
## extreme values like 7+ second whiff penalties — trained combatants can retract a missed strike within ~3s.
const RECOVERY_MAX_S: float = 4.0

const WINDUP_LEG_MIN: float = 0.2
const RECOVERY_AFTER_MEDICAL_S: float = 0.5

# Power and follow_through (0.2-1.0 each); intensity drives velocity, wind-up, recovery.
const POWER_MIN: float = 0.2
const POWER_MAX: float = 1.0
const FOLLOW_THROUGH_MIN: float = 0.2
const FOLLOW_THROUGH_MAX: float = 1.0
const INTENSITY_MIN: float = 0.2

# Afterblow timing
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5
