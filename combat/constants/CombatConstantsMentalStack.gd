class_name CombatConstantsMentalStack
extends RefCounted

const COMBATANT_KEY_FOCUS_PART := "focus_part"
const COMBATANT_KEY_FOCUS_INTENSITY := "focus_intensity"
const COMBATANT_KEY_ATTENTION_LOAD := "attention_load"
const COMBATANT_KEY_YOMI_BY_ATTACKER := "yomi_by_attacker"
const COMBATANT_KEY_WEAPON_FORM := "weapon_form"
const COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL := "form_switch_cooldown_until"
const COMBATANT_KEY_LAST_FORM_SWITCH_REASON := "last_form_switch_reason"
const COMBATANT_KEY_FORM_SWITCH_OLD_FORM := "form_switch_old_form"
const COMBATANT_KEY_FORM_SWITCH_OLD_GUARD := "form_switch_old_guard"
const COMBATANT_KEY_FORM_SWITCH_TARGET_FORM := "form_switch_target_form"
const COMBATANT_KEY_FORM_SWITCH_TARGET_GUARD := "form_switch_target_guard"
const COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID := "inferred_opp_form_by_id"
const COMBATANT_KEY_ATTENTION_UI_HINT := "attention_ui_hint"
const COMBATANT_KEY_MENTAL_STACK_LAYER := "mental_stack_layer"
const COMBATANT_KEY_SUSPEND_BLEED_TICK := "suspend_bleed_tick"
const MENTAL_STACK_LAYER_SELF_MEDICAL := "self_medical"
const MENTAL_STACK_LAYER_MEDICAL := "medical"
const MENTAL_STACK_LAYER_COUNTER := "counter"
const MENTAL_STACK_LAYER_INCOMING := "incoming"
const MENTAL_STACK_LAYER_HOLD_LINE := "hold_line"
const MENTAL_STACK_LAYER_SPARSE_FIGHT := "sparse_fight"
const MENTAL_STACK_LAYER_FORMATION_PLUG := "formation_plug"
const MENTAL_STACK_LAYER_ROUT := "rout"
const MENTAL_STACK_LAYER_POST_STRIKE := "post_strike"
const COMBATANT_KEY_LAST_STRIKE_TICK := "last_strike_tick"
const COMBATANT_KEY_LAST_STRIKE_TARGET_ID := "last_strike_target_id"
const POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE := 2.0
const POST_STRIKE_HIT_WEIGHT_BONUS := 1.1
const POST_STRIKE_MOMENTUM_WEIGHT_BONUS := 1.3
const MENTAL_STACK_LAYER_POSITIONAL_DIS := "positional_dis"
const MENTAL_STACK_LAYER_EXHAUSTION := "exhaustion"
const MENTAL_STACK_LAYER_GUARD_PRIORITY := "guard_priority"
## AI exhaustion tunnel thresholds — stamina ratio bands where decision quality degrades.
## 0.55 = point where AI starts favoring suboptimal actions (observed in playtest: ~45% error rate above this).
## 0.80 = "exhausted tunnel" state — AI almost entirely ignores offensive options, defaults to flee/wait.
const MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD := 0.55
const MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD := 0.80
const MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX := 0.4
const FOCUS_INTENSITY_DEFAULT := 1.0
## Attention load scores — additive (not normalized to 1.0). Sum > 1.0 by design: each component represents an
## independent cognitive demand channel. The AI's attention_overflow check uses a threshold, not a ratio.
## 0.45 telegraph weight = reading opponent tells is primary cognitive task during combat engagement.
## 0.40 peril weight = threat assessment (incoming strikes, flank pressure) competes with offense reading.
## 0.25 counter weight = planning counter-actions requires separate attention channel from immediate defense.
const ATTENTION_LOAD_TELEGRAPH_WEIGHT := 0.45
const ATTENTION_LOAD_PERIL_WEIGHT := 0.4
const ATTENTION_LOAD_COUNTER_WEIGHT := 0.25
## Focus penalty applied when AI's chosen action mismatches its current attention priority (e.g., attacking while
## attention is loaded with telegraph reading). Reduces weight of mismatched actions by this amount.
const ATTENTION_LOAD_FOCUS_PENALTY := 0.55
const FOCUS_WRONG_LINE_READTHROUGH_MULT := 0.82
const FOCUS_CORRECT_LINE_READTHROUGH_MULT := 1.06
const YOMI_FEINT_LISTING_MIN_LINE_COUNT := 2
const YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT := 0.04
const YOMI_FEINT_LISTING_MULT_CAP := 1.25
const YOMI_FOCUS_DRIFT_MIN_LINE_COUNT := 2
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD := 8
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT := 1
const YOMI_FOCUS_DRIFT_INTENSITY := 0.78
const MEDICAL_AI_WEIGHT_ESCALATION_BONUS := 1.5

## YOMI AGGREGATION — decay, power-law, attention budget.

const YOMI_DECAY_FACTOR_PER_TICK: float = 0.92
const YOMI_POWER_LAW_ALPHA: float = 0.7
const YOMI_NON_ENGAGED_WEIGHT: float = 0.25
const YOMI_ATTENTION_BUDGET_MAX: int = 3
const YOMI_ATTENTION_PRIORITY_DEGRADE_MULT: float = 0.5

## COMBATANT DICT KEYS — form inference history, tier tracking.

const COMBATANT_KEY_FORM_INFERENCE_HISTORY := "form_inference_history"
const COMBATANT_KEY_TIER_STATE := "_tier_state"
const COMBATANT_KEY_GUARD_BREAK_COUNT := "guard_break_count"
const MENTAL_STACK_TIER_COMMITMENT_TICKS: int = 3
const MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD: int = 3

## Tier state sub-keys.

const _TIER_ACTIVE := "active_tier"
const _TIER_ENTERED_AT := "entered_at"
const _TIER_CONSECUTIVE_FAILURES := "consecutive_failures"

## Phase 3: minimum consecutive failures at higher tiers before L2 counter-tempo is allowed.
const MENTAL_STACK_L1_TO_L2_FAILURE_THRESHOLD: int = 2

## Phase 5: Deception state machine combatant dict key.

const COMBATANT_KEY_DECEPTION_STATE := "_deception_state"

## V5 HEMA realism: Perception scaling for yomi min_line_count. High perception = fewer observations to detect patterns.
const YOMI_PERCEPTION_LINE_SCALE: float = 0.6  # At max perception (100), min lines reduced by 60%

## Tier 4.3.8: guard priority — proactive defensive positioning (waiting-tick drift + L4G stack layer).
## Score 0..1 = how strongly a waiting combatant should hold + position blade toward the expected attack
## line instead of opening new offense (a correctly-braced fighter still scores its read). Telegraph
## (live wind-up) scores highest and decays with wind-up progress (readability: a fully-committed strike
## is too late to shift stance to — anticipation early, reaction at the end); otherwise the most
## threatening engaged attacker's habitual yomi line builds score from observation count, band-weighted
## so a CLOSE threat dominates a MID one. Drift applies the yomi habit for free each waiting tick
## (anticipation outside wind-up) with a count-margin commitment (no flicker between near-equal reads);
## L4G spends the action to align on a live telegraph (offensive-or-hold decision). Suppressed for
## exhausted / critical-stamina fighters (L5 exhaustion already dominates their menu).
const COMBATANT_KEY_GUARD_PRIORITY := "guard_priority"
const COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE := "guard_priority_target_line"
const GUARD_PRIORITY_MIN_SCORE := 0.5
const GUARD_PRIORITY_TELEGRAPH_SCORE := 0.9
const GUARD_PRIORITY_YOMI_BASE := 0.55
const GUARD_PRIORITY_YOMI_PER_LINE_COUNT := 0.05
const GUARD_PRIORITY_YOMI_CAP := 0.8
const GUARD_PRIORITY_MIN_LINE_COUNT := 2
const GUARD_PRIORITY_MID_BAND_MULT := 0.85  # MID-range attackers scored at 85% of CLOSE to keep guard priority active in formation combat
const GUARD_PRIORITY_FOCUS_WEIGHT_TOP := 18.0  # focus-line weight multiplier at max priority
const GUARD_PRIORITY_SWITCH_COUNT_MARGIN := 1  # drift holds the current read until the new line is observed this much more

