class_name CombatConstantsBind
extends RefCounted

const ANGULAR_ADVANTAGE_DURATION_S := 4.0

const BIND_ACTION_COOLDOWN_S := 1.5

const BIND_PRESSURE_DECAY_RATE := 0.04

const BIND_PRESSURE_DURATION_S := 6.0

const BIND_STATE_HARD_THRESHOLD := 0.75

const BIND_STATE_LIGHT_THRESHOLD := 0.25

const BIND_STATE_MEDIUM_THRESHOLD := 0.50

const BREATH_BIND_PRESS_COST := 8.0

const BREATH_BIND_VOID_COST := 12.0

const BREATH_BIND_WIND_COST := 5.0

const LATERAL_STEP_DELTA := 0.2

## Max bind pressure a combatant can sustain before their blade slips and wrestling transition becomes available.
## Models HEMA reality: prolonged binds cause blade fatigue — the defender's control degrades over time.
const BIND_WRESTLING_TRANSITION_THRESHOLD := 0.85
## Pressure loss per second during sustained bind (progressive leverage degradation).
## Represents muscle fatigue from maintaining pressure against resistance.
const BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT: float = 2.5
## Time threshold before progressive leverage degradation kicks in (seconds of sustained bind).
const BIND_LEVERAGE_GRACE_PERIOD_S := 1.0
