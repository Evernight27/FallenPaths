class_name CombatCampaignMoodBias
extends RefCounted

## XCamp-3.9: maps average company campaign mood to AI decision-layer weight biases.
## Low morale (<=25) -> defensive bias: higher wait/focus weights, lower attack aggression.
## High morale ('permille'70) -> aggressive bias: higher attack/feint weights, lower focus passivity.
## Balanced (25 - 70) -> no bias (1.0 multiplier).
## Read from encounter meta key `campaign_mood_bias_player` / `campaign_mood_bias_enemy`
## (float 0.0 - 100.0, same scale as CompanyState member mood).
## Canonical: mood_bias_for_combatant . wait/offense/focus/flee/disengage action_weight_mult.
## Read order: encounter meta keys -> mood_bias_for_combatant -> per-action multiplier -> batch compute.

# Mood bias thresholds (0-100 scale, same as CompanyState member mood)
const MOOD_BIAS_NEUTRAL_THRESHOLD: float = 25.0
const MOOD_BIAS_HIGH_THRESHOLD: float = 70.0
const MOOD_BIAS_RANGE_HIGH: float = 45.0  # HIGH - NEUTRAL (70-25)

# Wait action weight multipliers (low morale -> higher wait weight)
const MOOD_WAIT_MULT_LOW_MAX: float = 2.0

# Offense action weight multipliers (below neutral -> damp; above neutral -> boost)
const MOOD_OFFENSE_MULT_LOW_MIN: float = 0.6
const MOOD_OFFENSE_MULT_HIGH_MAX: float = 1.4

# Focus line action weight multipliers (low morale -> higher focus; high morale -> lower)
const MOOD_FOCUS_MULT_LOW_MAX: float = 1.5
const MOOD_FOCUS_MULT_HIGH_MIN: float = 0.7

# Flee action weight multipliers (low morale -> higher flee; high morale -> lower)
const MOOD_FLEE_MULT_LOW_MAX: float = 1.3
const MOOD_FLEE_MULT_HIGH_MIN: float = 0.7

# Disengage action weight multipliers (low morale -> higher disengage; high morale -> lower)
const MOOD_DISENGAGE_MULT_LOW_MAX: float = 1.4
const MOOD_DISENGAGE_MULT_HIGH_MIN: float = 0.6

## XCamp-3.9: encounter meta keys for mood bias (0 - 100, same scale as CompanyState member mood).
const ENCOUNTER_KEY_MOOD_BIAS_PLAYER := "campaign_mood_bias_player"
const ENCOUNTER_KEY_MOOD_BIAS_ENEMY := "campaign_mood_bias_enemy"


## Returns the effective campaign mood bias for a combatant's side (0 - 100, or 50.0 if unknown).
static func mood_bias_for_combatant(manager: Node, c: Dictionary) -> float:
    if manager == null or c.is_empty():
        return 50.0
    var side: String = CombatantEntityAccess.side_str(c)
    var enc: Dictionary = {}
    if manager.encounter is Dictionary:
        enc = manager.encounter as Dictionary
    if enc.is_empty():
        return 50.0
    var key: String = (
        ENCOUNTER_KEY_MOOD_BIAS_PLAYER if side == CombatConstants.SIDE_PLAYER else ENCOUNTER_KEY_MOOD_BIAS_ENEMY
    )
    if not enc.has(key):
        return 50.0
    return clampf(float(enc[key]), 0.0, 100.0)


## XCamp-3.9: returns a weight multiplier for wait actions based on campaign mood bias.
## Low morale -> higher wait weight (cautious). High morale -> lower wait weight (aggressive).
static func wait_action_weight_mult(mood_bias: float) -> float:
    if mood_bias < 0.0:
        return 1.0
    if mood_bias > MOOD_BIAS_HIGH_THRESHOLD:
        return 1.0
    # At NEUTRAL threshold: no extra weight over default weapon-form wait mult.
    # Below NEUTRAL: increase wait weight up to LOW_MAX at mood=0.
    return lerpf(
        1.0,
        MOOD_WAIT_MULT_LOW_MAX,
        clampf((MOOD_BIAS_NEUTRAL_THRESHOLD - mood_bias) / MOOD_BIAS_NEUTRAL_THRESHOLD, 0.0, 1.0)
    )


## XCamp-3.9: returns a weight multiplier for attack/close actions based on campaign mood bias.
## Low morale -> lower attack aggression (damp). High morale -> higher attack aggression (boost).
static func offense_action_weight_mult(mood_bias: float) -> float:
    if mood_bias < 0.0:
        return 1.0
    if mood_bias > MOOD_BIAS_HIGH_THRESHOLD:
        return 1.0
    # At NEUTRAL: neutral (1.0). Below NEUTRAL: damp up to LOW_MIN at mood=0.
    # Above NEUTRAL toward HIGH: boost up to HIGH_MAX at mood=HIGH.
    if mood_bias <= MOOD_BIAS_NEUTRAL_THRESHOLD:
        return lerpf(
            1.0,
            MOOD_OFFENSE_MULT_LOW_MIN,
            clampf((MOOD_BIAS_NEUTRAL_THRESHOLD - mood_bias) / MOOD_BIAS_NEUTRAL_THRESHOLD, 0.0, 1.0)
        )
    return lerpf(
        1.0,
        MOOD_OFFENSE_MULT_HIGH_MAX,
        clampf((mood_bias - MOOD_BIAS_NEUTRAL_THRESHOLD) / MOOD_BIAS_RANGE_HIGH, 0.0, 1.0)
    )


## XCamp-3.9: returns a weight multiplier for focus-line moves based on campaign mood bias.
## Low morale -> higher focus weight (defensive guard discipline). High morale -> lower focus weight.
static func focus_line_action_weight_mult(mood_bias: float) -> float:
    if mood_bias < 0.0:
        return 1.0
    if mood_bias > MOOD_BIAS_HIGH_THRESHOLD:
        return 1.0
    if mood_bias <= MOOD_BIAS_NEUTRAL_THRESHOLD:
        return lerpf(
            1.0,
            MOOD_FOCUS_MULT_LOW_MAX,
            clampf((MOOD_BIAS_NEUTRAL_THRESHOLD - mood_bias) / MOOD_BIAS_NEUTRAL_THRESHOLD, 0.0, 1.0)
        )
    return lerpf(
        1.0,
        MOOD_FOCUS_MULT_HIGH_MIN,
        clampf((mood_bias - MOOD_BIAS_NEUTRAL_THRESHOLD) / MOOD_BIAS_RANGE_HIGH, 0.0, 1.0)
    )


## XCamp-3.9: returns a weight multiplier for flee actions based on campaign mood bias.
## Low morale -> higher flee tendency (desperation). High morale -> lower flee tendency (resolve).
static func flee_action_weight_mult(mood_bias: float) -> float:
    if mood_bias < 0.0:
        return 1.0
    if mood_bias > MOOD_BIAS_HIGH_THRESHOLD:
        return 1.0
    if mood_bias <= MOOD_BIAS_NEUTRAL_THRESHOLD:
        return lerpf(
            1.0,
            MOOD_FLEE_MULT_LOW_MAX,
            clampf((MOOD_BIAS_NEUTRAL_THRESHOLD - mood_bias) / MOOD_BIAS_NEUTRAL_THRESHOLD, 0.0, 1.0)
        )
    return lerpf(
        1.0, MOOD_FLEE_MULT_HIGH_MIN, clampf((mood_bias - MOOD_BIAS_NEUTRAL_THRESHOLD) / MOOD_BIAS_RANGE_HIGH, 0.0, 1.0)
    )


## XCamp-3.9: returns a weight multiplier for swap_rank/fall_back disengage moves based on mood bias.
## Low morale -> higher disengage (fragile cohesion). High morale -> lower disengage (hold ground).
static func disengage_action_weight_mult(mood_bias: float) -> float:
    if mood_bias < 0.0:
        return 1.0
    if mood_bias > MOOD_BIAS_HIGH_THRESHOLD:
        return 1.0
    if mood_bias <= MOOD_BIAS_NEUTRAL_THRESHOLD:
        return lerpf(
            1.0,
            MOOD_DISENGAGE_MULT_LOW_MAX,
            clampf((MOOD_BIAS_NEUTRAL_THRESHOLD - mood_bias) / MOOD_BIAS_NEUTRAL_THRESHOLD, 0.0, 1.0)
        )
    return lerpf(
        1.0,
        MOOD_DISENGAGE_MULT_HIGH_MIN,
        clampf((mood_bias - MOOD_BIAS_NEUTRAL_THRESHOLD) / MOOD_BIAS_RANGE_HIGH, 0.0, 1.0)
    )


## XCamp-3.9: batch apply all mood bias multipliers to a combatant's action weights.
## Returns a dictionary of {wait_mult, offense_mult, focus_mult, flee_mult, disengage_mult}.
static func compute_all_multipliers(mood_bias: float) -> Dictionary:
    return {
        "wait_mult": wait_action_weight_mult(mood_bias),
        "offense_mult": offense_action_weight_mult(mood_bias),
        "focus_mult": focus_line_action_weight_mult(mood_bias),
        "flee_mult": flee_action_weight_mult(mood_bias),
        "disengage_mult": disengage_action_weight_mult(mood_bias),
    }
