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
const RECOVERY_EXTRA_DEFLECTED_BASE_S: float = -0.04
# deflecting recovers faster (redirected opponent's energy; HEMA Farbenschlagen principle)
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
## Reference wind-up energy cap (T_optimal): the quadratic wind-up energy factor min(1.0,(t/0.40)²) reaches full
## energy at t=0.40s (WIND_UP_FACTOR_OPTIMAL_S), so no additional energy is gained beyond that. Kept as a tuning
## reference; the live duration clamp is WIND_UP_DURATION_MAX_S.
const WIND_UP_ENERGY_CAP_S: float = 0.75
## Maximum effective wind-up duration after soft cap — absolute ceiling on how long an attack can take.
## Capped at 0.8s to prevent telegraphed attacks with no penalty; any input held beyond this should trigger
## a "committed strike" state where the fighter cannot cancel or redirect the attack without penalty.
const WIND_UP_DURATION_MAX_S: float = 0.8
## Soft cap for wind-up duration — above this, diminishing returns apply (each extra 0.1s of input adds only
## 0.05s of real wind-up, i.e. duration is compressed toward the hard cap WIND_UP_DURATION_MAX_S).
## Set at 0.5s so that most attacks naturally fall below the energy cap; power swings get a modest bonus but
## cannot exceed the hard cap of WIND_UP_DURATION_MAX_S.
const WIND_UP_SOFT_CAP_S: float = 0.5
## Diminishing-returns ratio past the soft cap: each second beyond WIND_UP_SOFT_CAP_S adds only this
## fraction of a second to the real wind-up (the swing is already at full extension; extra input just
## makes it more telegraphed, not stronger).
const WIND_UP_SOFT_CAP_EXCESS_RATIO: float = 0.5
## Maximum total recovery time for any single strike outcome (seconds). Prevents compound scaling from producing
## extreme values like 7+ second whiff penalties — trained combatants can retract a missed strike within ~3s.
const RECOVERY_MAX_S: float = 4.0
## Minimum effective wind-up multiplier: form or state modifiers can shorten wind-up but never below 50% of the
## base duration. A rushed attack still needs a minimum biomechanical preparation time.
const WIND_UP_MULTIPLIER_MIN: float = 0.5
## Commitment scaling for guard-line transition recovery cost. The longer the fighter has been committed to a
## non-default guard line (commitment 0.0-1.0), the more time it takes to transition back. At full commitment
## the cost is 1.5× the base transition cost (1.0 + 0.5 * 1.0).
const GUARD_TRANSITION_COMMITMENT_SCALE: float = 0.5
## Tactical breathing recovery floor: even with maximum breathing offset the recovery never drops below 55%
## of the base recovery time. Models the biomechanical limit that pausing to breathe recovers a fighter faster
## than unassisted, but not to instant re-readiness.
const TACTICAL_BREATHING_RECOVERY_FLOOR_RATIO: float = 0.55

const WINDUP_LEG_MIN: float = 0.2
## Floor for leg functionality when scaling formation-move (footwork) duration. A fractured/crippled
## leg slows repositioning (duration ∝ 1/speed); the clamp caps the slowdown so a destroyed leg
## slows the unit rather than freezing it (total immobilization is handled by cowering).
const MOVEMENT_LEG_FUNC_MIN: float = 0.25
## Note: WINDUP_LEG_MIN (0.2) and MOVEMENT_LEG_FUNC_MIN (0.25) are deliberately different. They floor
## *different physical quantities*: wind-up (0.2) is getting into the *strike posture* — a crippled
## fighter can still settle into a guarded, weapon-ready stance, so the floor is lower. Formation
## movement (0.25) is active *repositioning between slots*, which demands more functional legs, so
## its floor is higher (a slower pace, not a freeze). Do not "normalize" these to one value.
const RECOVERY_AFTER_MEDICAL_S: float = 0.5

# Power and follow_through (0.5-1.0 each); ensures realistic KE distributions matching HEMA data.
const POWER_MIN: float = 0.5
const POWER_MAX: float = 1.0
const FOLLOW_THROUGH_MIN: float = 0.5
const FOLLOW_THROUGH_MAX: float = 1.0
const INTENSITY_MIN: float = 0.2

# Afterblow timing
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5
