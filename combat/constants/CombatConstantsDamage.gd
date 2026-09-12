class_name CombatConstantsDamage
extends RefCounted

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

## Base *intrinsic* miss probability for an attack, before perception/skill/measure/distance modifiers.
## The frequently-non-decisive HEMA exchange rate (~30-50% of exchanges produce no clean hit) emerges from
## combining this with the defender's dodge/parry rolls — it is not this single number. Raised from the
## pre-ship 0.08 so the attacker is less generous (plan_balance_tuning.md Change 4).
const MISS_CHANCE_BASE := 0.10
const HIT_CHANCE_PERCEPTION_MIN := 0.8
const HIT_CHANCE_PERCEPTION_MAX := 1.2
## Floor on effective hit chance after all multiplicative penalties (stamina, pain, fatigue, measure).
## Set just below the realistic close-range contact band (~50-70%) so a fully-compromised attacker still
## has a fair chance of landing. Before this floor, compounding penalties collapsed hit chance to 20-40%,
## below any realistic close-range contact rate.
const HIT_CHANCE_MIN_CAP := 0.45
## Minimum cap on the product of attacker-side "blow lands weakly" penalties (off-balance, out-of-measure,
## over-extended cut, inside a longer-armed defender's reach). Symmetric with HIT_CHANCE_MIN_CAP: the
## accuracy side already floored compounding penalties at 0.45 because they were collapsing to 20-40%;
## the damage side needs the same guard so a fully-compromised strike never degenerates to a trivial chip.
## Positional bonuses (rear/flank, angular, bind follow-through, form-switch) are rewards and stay unclamped.
const ATTACK_COMMIT_QUALITY_FLOOR := 0.45
const GLANCING_DAMAGE_RATIO := 0.1
const GLANCING_DAMAGE_ABSOLUTE_FLOOR := 0.3
const PHYSICAL_DAMAGE_ZERO_EPS := 1e-4

## Williams formula (KE/55)^0.6 outputs RHA penetration (steel-plate calibrated). For unarmored
## targets that RHA value is converted to soft-tissue depth by `CombatDamageMechanism.
## rha_penetration_to_tissue_depth_mm` — tissue yields and bleeds rather than deforming rigidly
## like steel, so the raw RHA depth is not used directly.

## R4: Minimum tissue floor for blunt damage — after armor absorption, at least this fraction of
## pre-armor blunt value must remain as tissue damage. Prevents high-KE blunt weapons from allocating
## nearly all post-armor damage to bone while doing almost zero soft-tissue trauma.
const BLUNT_MIN_TISSUE_FLOOR_MULT := 0.30

## Measure-ratio hit penalty (heuristic). At ratio=1.2 (attacker overextended by 20%),
## hit chance multiplier drops to this floor. Models short-weapon-at-range targeting loss.
## Formula: lerp(1.0, FLOOR, clampf((ratio - 1.0) * 5.0, 0, 1)) — full penalty at ratio >= 1.2.
const MEASURE_HIT_CHANCE_FLOOR := 0.55

## Under-reach (out-of-measure) hit penalty. When measure_ratio < 1.0 the target lies beyond the
## attacker's natural measure — a "half-step" strike that cannot generate full speed/angle.
## Milder than the over-extension penalty (0.80 vs 0.55 floor) because under-reach is recoverable
## by committing harder, whereas over-extension is a geometric dead-end.
## Formula: lerp(1.0, FLOOR, clampf((1.0 - ratio) / (1.0 - RATIO_MIN), 0, 1)) — full penalty at ratio <= RATIO_MIN (0.75).
const MEASURE_UNDER_REACH_HIT_CHANCE_FLOOR := 0.80

## Measure-ratio *damage* penalty (heuristic). A strike out of measure — over-extended (ratio > 1.0) or
## short of reach (ratio < 1.0) — arrives with less body mass and follow-through behind it. Complements
## the measure-ratio hit-chance penalty: distance governs both whether a blow lands AND how hard it lands.
## Milder than the over-reach hit-chance floor (0.80 vs 0.55): even an over-extended blade still cuts if
## it connects, it just lacks full commitment. Same lerp structure as the hit-chance floors.
const MEASURE_DMG_OVER_REACH_FLOOR := 0.80
const MEASURE_DMG_UNDER_REACH_FLOOR := 0.80
## Slope for the measure-ratio penalty ramp: at ratio = 1.0 + (1.0 / RAMP) the penalty is fully engaged.
## 5.0 means full penalty at ratio 1.2 (20% over-extension). Used by both hit-chance and damage paths.
const MEASURE_PENALTY_RAMP_PER_UNIT := 5.0
## Proximity-weighted hit-chance bonus (heuristic). Close range gives the attacker more blade engagement,
## so the effective hit chance is multiplied more at close range (1.35x) than mid range (1.10x); long range
## is the 1.0 baseline. Applied on top of an already-high base, 1.35x makes a healthy close-range exchange
## effectively guaranteed to connect — the intended "you land if you swing at arm's length" feel.
const CLOSE_RANGE_HIT_MULT := 1.35
const MID_RANGE_HIT_MULT := 1.10
## Maximum accuracy loss from sustained multi-region pain. A fighter in severe pain aims 15% worse
## at the cognitive level (targeting capture), independent of motor-swing degradation.
const PAIN_HIT_CHANCE_DEGRADATION_MAX := 0.15
## Melee-skill contribution to accuracy is clamped to this range. Floor 0.5: a zero-skill fighter
## still lands half their natural hit chance. Cap 1.3: perfect skill adds at most 30% accuracy.
const MELEE_SKILL_HIT_FACTOR_MIN := 0.5
const MELEE_SKILL_HIT_FACTOR_MAX := 1.3
## Glancing strikes get a reduced physical-damage floor: half the contact-hit minimum.
const GLANCING_DAMAGE_FLOOR_RATIO := 0.5
## Cut-specific over-reach *damage* penalty. A cut needs an arc: past the limit of measure the arc is
## truncated and the edge can't "run through" the target, so an over-extended cut lands notably softer
## than an over-extended thrust (a point weapon keeps its edge out to full measure). Applies on top of
## the contact-type-agnostic MEASURE_DMG_OVER_REACH_FLOOR, to pre_cut only. Milder floor (0.65) than the
## generic over-reach floor (0.80): the truncated-arc cost is real even at mild over-extension.
## Formula: lerp(1.0, FLOOR, clampf((ratio - 1.0) * 5.0, 0, 1)) — full penalty at ratio >= 1.2.
const MEASURE_DMG_CUT_OVER_REACH_FLOOR := 0.65
## Defender-reach (inside-measure) *damage* penalty. If the defender's weapon reaches further relative
## to the pair distance than the attacker's, the attacker is inside the defender's natural measure and
## must get through a longer, braced blade to land — the blow arrives with less clean commit. This is a
## RELATIONAL penalty (defender ratio vs attacker ratio), independent of the attacker's own self-measure,
## so it fires even at measure_ratio == 1.0. Milder floor (0.88) than the self-measure floors: it's the
## opponent's threat, not the attacker's flawed commit. Formula: lerp(1.0, FLOOR, clampf(gap * 5.0, 0, 1)).
const MEASURE_DMG_DEFENDER_REACH_FLOOR := 0.88

const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 100.0
const INTENSITY_STRENGTH_BIAS := 0.35
const INTENSITY_RANDOM_RANGE := 0.2
