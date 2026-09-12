class_name CombatConstantsBind
extends RefCounted

const ANGULAR_ADVANTAGE_DURATION_S := 4.0
## HEMA B3: voiding outside an opponent's strong side leaves their bracing misaligned to the line
## you take — the voider's strike against the voided target lands with a modest positional bonus.
const ANGULAR_ADVANTAGE_DMG_MULT := 1.10

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
## HEMA: a successful bind-wrestle transition unbalances the opponent — a body grab from a
## sustained bind is more destabilizing than a parry-deflect (1.0s). While off-balance, the
## target's attack damage and parry capacity are both reduced by their respective constants.
const BIND_WRESTLE_TARGET_OFF_BALANCE_S := 1.2
## HEMA: a striker who is actively holding a bind (pressing the opponent's blade) has control of
## the engagement and a positional edge for the follow-through strike — the trapped line and
## braced contact give a modest damage bonus on the next strike while the bind is live.
const BIND_FOLLOW_THROUGH_DMG_MULT := 1.10
## Minimum follow-through bonus at the weakest (light) live bind. Scales up to
## BIND_FOLLOW_THROUGH_DMG_MULT at a hard bind — a firmer hold controls the follow-through more.
const BIND_FOLLOW_THROUGH_DMG_MIN_MULT := 1.04

## Waffenfühlen: how strongly Perception scales attack-side bind contest power per 100 points of stat.
const BLADE_FEEL_PERC_SCALE := 0.3

## Waffenfühlen: how strongly Intelligence scales attack-side bind contest power per 100 points of stat.
const BLADE_FEEL_INT_SCALE := 0.5

## Waffenfühlen: how strongly Perception scales defense-side bind contest power per 100 points of stat.
## Slightly weaker than the attack side — holding a bind is less about reading the weapon than keeping it.
const BLADE_FEEL_RESIST_PERC_SCALE := 0.25

## Number of pressure levels spanned by the follow-through damage interpolation (light=1 to hard=3).
const BIND_FOLLOW_THROUGH_LEVEL_SPAN := 2.0
## Multiplier on the base per-second pressure decay (0.04/s) once the grace period elapses, giving 0.10/s of
## progressive leverage degradation. Represents muscle fatigue from maintaining pressure against resistance.
const BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT: float = 2.5
## Time threshold before progressive leverage degradation kicks in (seconds of sustained bind).
const BIND_LEVERAGE_GRACE_PERIOD_S := 1.0
