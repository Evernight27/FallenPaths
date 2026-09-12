class_name CombatConstantsCounterTempo
extends RefCounted

const COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART := "incoming_attack_telegraph_part"
const COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK := "ai_feint_opp_last_parry_deflect_tick_by_id"
const COMBATANT_KEY_COUNTER_WINDOW_UNTIL := "counter_window_until"
const ACTION_KEY_COUNTER_TEMPO := "counter_tempo"
const ACTION_KEY_CLOSE_LIST_HINT := "close_attempt_list_hint"
const PA_KEY_COUNTER_TEMPO := "counter_tempo"
const COUNTER_TEMPO_GAUGE_THRESHOLD := 50.0
const COUNTER_TEMPO_GAUGE_COST := 30.0
const COUNTER_TEMPO_WINDOW_FRACTION := 0.8
const COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS := 0.5
const COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED := "counter_tempo_ready_signaled"
const COMBATANT_KEY_COUNTER_TEMPO_UI_HINT := "counter_tempo_ui_hint"
const COUNTER_TEMPO_WINDUP_MULT := 0.65
const COUNTER_TEMPO_WINDUP_MAX_S := 1.5
const COUNTER_TEMPO_ACTION_READY_DELAY_S := 0.02
const COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S := 0.001
const AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT := 1.35
const AI_COUNTER_TEMPO_INCOMING_TARGET_MULT := 1.12
const AI_COUNTER_TEMPO_FEINT_DAMP_MULT := 0.88
const COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL := "riposte_chain_until"
const COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID := "riposte_chain_target_id"
const COMBATANT_KEY_RIPOSTE_TARGET_LINE := "riposte_target_line"
const PA_KEY_RIPOSTE_CHAIN := "riposte_chain"
const RIPOSTE_CHAIN_WINDOW_S := 1.5
const RIPOSTE_CHAIN_WINDUP_MULT := 0.5
## HEMA nach/Vorschlag: after a landed strike the attacker holds initiative while the victim is
## off-balance. Shorter window and a slower wind-up than a blade-catch riposte — a completed strike
## is controlled commitment, not the fast re-positioning of a parry.
const COMBATANT_KEY_HIT_CONTINUATION_UNTIL := "hit_continuation_until"
const COMBATANT_KEY_HIT_CONTINUATION_TARGET_ID := "hit_continuation_target_id"
const HIT_CONTINUATION_WINDOW_S := 0.9
const HIT_CONTINUATION_WINDUP_MULT := 0.85
const FLURRY_BIND_WINDOW_S := 1.25
const FLURRY_BIND_MAX_EXCHANGES := 2
const FLURRY_BIND_WIND_UP_MULT := 0.82
const FLURRY_BIND_STAMINA_ATTACK_COST_MULT := 0.88
## Positional feint: when a feint move lands, the defender's guard is committed to the feint's
## telegraph line and displaced for a short window. The next attack on that line finds the
## defender unable to re-establish full parry capacity (0.75 = 25% reduction). Grounded in HEMA:
## a feint that draws a reaction leaves the defender's blade in a suboptimal position for
## the follow-up on the same line.
const FEINT_OPEN_LINE_DURATION_S := 3.0
const FEINT_OPEN_LINE_PARRY_MULT := 0.75

## Gegenschlag (counterblow trade): when the defender counters, there is a probability that the
## counter becomes a trade (both strikes land) instead of a safe preemptive strike (opponent deferred).
## Base probability at equal timing; modulated by timing advantage (our wind-up end vs their remaining).
const GEGENSCHLAG_TRADE_BASE_PROB := 0.5
const GEGENSCHLAG_TIMING_DELTA_SCALE := 0.5

## Verwunden (circumscription): a stronger open-line parry penalty than a plain positional feint.
## Going around the committed blade leaves the far side more exposed than a same-line follow-up.
const CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT := 0.55

## HEMA parry-riposte: when an attack is deflected, the attacker's blade is committed on the line
## they struck — a riposte into that same line finds the parried sword already displaced off it, so
## the parried fighter cannot re-cover. Distinct from off-balance (general readiness) and feint open-line.
const DEFLECT_OPEN_LINE_PARRY_MULT := 0.60
