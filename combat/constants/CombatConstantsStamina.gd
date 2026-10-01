class_name CombatConstantsStamina

extends RefCounted

## Stamina and exhaustion constants extracted from CombatConstants.gd.
## Preload this module when you only need stamina/exhaustion values and helpers.
const STAMINA_MAX := 100.0

## ATP-PCr resynthesis is first-order (exponential): dS/dt = k * (MAX - S), where k = ln(2)/HALF_TIME.
## HALF_TIME ~30 s matches the fast PCr-recovery phase (the "burst buffer"). This yields a fast initial recovery
## (~2.3 HP/s when fully depleted) that decays as the pool refills — the realistic "you can swing hard again after
## a short rest, but the pool tops up slowly" shape. The sustained "gassed" feeling is carried by exhaustion
## (lowers the burst cap AND slows k) and metabolic stress (slow decay), not by this fast buffer.
## Applied in CombatStateHandlers.process_waiting as s += k * (cap - s) * delta.
const STAMINA_REFILL_HALF_TIME_S := 30.0

const STAMINA_REFILL_RATE := log(2.0) / STAMINA_REFILL_HALF_TIME_S  # ~0.0231 1/s first-order rate constant

const STAMINA_ATTACK_COST_BASE := 8.0

const STAMINA_ATTACK_COST_SCALE := 13.0

const STAMINA_PARRY_COST_BASE := 8.0

const STAMINA_PARRY_COST_SCALE := 5.0

## A partial parry absorbs only a fraction of the incoming momentum (1 - remaining_ratio). A light
## deflect is a smaller isometric demand than a full braced stop, so its stamina cost is discounted.
## This is the floor: a partial parry that absorbs nothing still costs this fraction of a full parry
## (the defender still raised the blade and made contact).
const PARTIAL_PARRY_STAMINA_FLOOR := 0.5

## Time window (seconds) within which consecutive parries compound fatigue. If the gap between parries
## exceeds this, the defender has rested enough that the fatigue resets — the streak counter returns to 1.
## Matches the typical recovery window (default 1.5s).
const PARRY_FATIGUE_RESET_S := 1.5

## Dodge stamina cost — a full-body explosive step (footwork + body reposition) is the DOMINANT metabolic
## cost in fencing/HEMA (LEG_FATIGUE_RESEARCH: leg fatigue from explosive lower-limb work is the primary
## conditioning driver, and finicky footwork degrades first). A parry is a 30-80ms blade-contact deflection.
## Hence dodge ≥ parry cost: base 8 (equal to parry) and scale 6 (slightly above parry's 5) so a dodge
## always costs at least as much as a parry at equal intensity.
const STAMINA_DODGE_COST_BASE := 8.0

const STAMINA_DODGE_COST_SCALE := 6.0

const STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT := 1.35

const PARRY_BIND_RIPOSTE_GAUGE_BONUS := 28.0

const STAMINA_AT_ZERO_PARRY_MULT := 0.5

const STAMINA_AT_ZERO_DAMAGE_MULT := 0.7

const STAMINA_FACTOR_POWER := 0.50

const STAMINA_EXHAUSTION_MAX_MULT_FLOOR := 0.7

const STAMINA_BLOOD_MAX_MULT_FLOOR := 0.7

const STAMINA_REFILL_EXHAUSTION_MULT_FLOOR := 0.4

const EXHAUSTION_OFFENSE_DAMP_START := 0.25

const EXHAUSTION_OFFENSE_DAMP_FLOOR := 0.35

const COMBATANT_KEY_EXHAUSTION := "exhaustion"

const COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED := "exhaustion_fp_band_logged"

const COMBATANT_KEY_CONSECUTIVE_ACTIONS := "_consecutive_actions"

const COMBATANT_KEY_CONSECUTIVE_PARRIES := "_consecutive_parry_count"

const COMBATANT_KEY_METABOLIC_STRESS := "_metabolic_stress"

const EXHAUSTION_MAX := 1.0

const EXHAUSTION_EXERTION_PER_STAMINA_POINT := 0.001

const EXHAUSTION_ENDURANCE_MAX_RELIEF := 0.45

## Central fatigue recovery rate per second while in WAITING state. At 0.008/s, full recovery from
## max exhaustion (1.0) takes ~125s (~2 min). Clinical: central fatigue from high-intensity exercise
## takes 5-15 min for significant recovery; 125s is the fast end for a fit fighter in a short rest
## (disengaged from combat). The sustained "gassed" feeling is carried by metabolic stress (slow decay),
## not by this recovery rate.
const EXHAUSTION_RECOVERY_RATE := 0.008

const METABOLIC_STRESS_MAX := 1.0

const METABOLIC_STRESS_GAIN_PER_STAMINA_POINT := 0.002

const METABOLIC_STRESS_ENDURANCE_MAX_RELIEF := 0.35

const METABOLIC_STRESS_DECAY_RATE_WAITING := 0.0008

const EXHAUSTION_CURVE := 2.0

const EXHAUSTION_FLOOR_MULT := 0.40

const EXHAUSTION_UI_SHOW_THRESHOLD := 0.06

const EXHAUSTION_GAIN_BLOOD_LOSS_MULT := 1.35

const EXHAUSTION_GAIN_PAIN_SHOCK_MULT := 1.25

const EXHAUSTION_POWER_DEGRADATION_DELAY := 0.15

const FEATURE_FIGHT_EXHAUSTION_INDEX := CombatConstantsFeatureFlags.FEATURE_FIGHT_EXHAUSTION_INDEX

const FATIGUE_VELOCITY_FLOOR_AT_ZERO_STAMINA: float = 0.80

# How quickly velocity degrades as stamina drops — steeper than damage because RFD is sensitive to ATP availability.
const FATIGUE_VELOCITY_POWER_EXPONENT: float = 0.7  # power < 1.0 means degradation accelerates faster at low stamina

# Exhaustion adds a multiplicative layer on top of stamina-based velocity loss, modeling glycogen depletion over time.
# At max exhaustion, this factor multiplies the already-reduced velocity further. Kept shallow (old 0.55) so the
# combined stamina×exhaustion floor stays above ~0.64 velocity → KE ≥ ~40% of full, consistent with sustained-effort
# data.
const FATIGUE_VELOCITY_EXHAUSTION_FLOOR: float = 0.80

# Skill-dependent fatigue resilience (TOPIC 8d): trained fighters hold mechanical intensity later into effort.
# A skill_hold of -0.5 (green) shifts both floors down by the span, +0.5 (veteran) shifts up; ±0.05 at span 0.10
# keeps the rookie/veteran band near the research range (weakest punches lose ~2x the strongest's velocity,
# Stewart 2025; fatigue delays RFD most in rotational strikes, Dunn 2021). Default 0.0 preserves prior behavior.
const FATIGUE_SKILL_HOLD_FLOOR_SPAN: float = 0.10


static func stamina_factor(ratio: float) -> float:
    return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)


## Compat alias of stamina_factor (call sites may use either).


static func breath_factor(ratio: float) -> float:
    return stamina_factor(ratio)


static func stamina_attack_cost_from_intensity(intensity: float) -> float:
    return STAMINA_ATTACK_COST_BASE + STAMINA_ATTACK_COST_SCALE * clampf(intensity, 0.0, 1.0)


static func stamina_parry_cost_from_intensity(intensity: float) -> float:
    return STAMINA_PARRY_COST_BASE + STAMINA_PARRY_COST_SCALE * clampf(intensity, 0.0, 1.0)


## Stamina cost multiplier for a partial parry, scaled by momentum absorption (1 - remaining_ratio).
## A light deflect (little absorption) costs PARTIAL_PARRY_STAMINA_FLOOR of a full parry; a near-full
## stop (full absorption) costs the full amount. Linear in absorption.


static func partial_parry_stamina_mult(absorption: float) -> float:
    return lerpf(PARTIAL_PARRY_STAMINA_FLOOR, 1.0, clampf(absorption, 0.0, 1.0))


static func stamina_dodge_cost_from_intensity(intensity: float) -> float:
    return STAMINA_DODGE_COST_BASE + STAMINA_DODGE_COST_SCALE * clampf(intensity, 0.0, 1.0)


static func action_ready_stamina_delay_mult(stamina_ratio: float) -> float:
    return lerpf(STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT, 1.0, stamina_factor(stamina_ratio))


static func defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio: float) -> float:
    var st_ratio: float = clampf(stamina_ratio, 0.0, 1.0)
    return lerpf(STAMINA_AT_ZERO_PARRY_MULT, 1.0, stamina_factor(st_ratio))


static func is_feature_fight_exhaustion_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_fight_exhaustion_enabled()


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_fight_exhaustion_index_load(on)


static func exhaustion_performance_mult(exhaustion: float) -> float:
    var t: float = pow(clampf(exhaustion, 0.0, EXHAUSTION_MAX), EXHAUSTION_CURVE)
    return lerpf(1.0, EXHAUSTION_FLOOR_MULT, t)


## Timing/precision degradation (parry readiness, wind-up speed) — degrades immediately with exhaustion.
## Models the biomechanical finding that fine motor control and reaction time degrade before gross power output.


static func exhaustion_timing_mult(exhaustion: float) -> float:
    return exhaustion_performance_mult(exhaustion)


## Power degradation (damage output) — delayed onset so gross strength holds out slightly longer than precision.
## Models boxing research showing punch velocity drops 3-5% by round 3-4 while power drops only 5-8% by round 4-5.


static func exhaustion_power_mult(exhaustion: float) -> float:
    var delayed: float = maxf(0.0, exhaustion - EXHAUSTION_POWER_DEGRADATION_DELAY)
    return exhaustion_performance_mult(delayed)


## Metabolic stress decision-quality degradation (lactate-like accumulation).
## At 0.3+ stress: AI makes measurably worse reads and commits to wrong actions more often.
## Models Rae et al. findings on cognitive decline at blood lactate >4-6 mM.


static func metabolic_stress_decision_mult(stress: float) -> float:
    var t: float = clampf(stress, 0.0, METABOLIC_STRESS_MAX)
    ## Linear degradation from 1.0 to ~0.75 at max stress (reaction time +15% per Rae et al.)
    return lerpf(1.0, 0.75, t)


static func defender_passive_readiness_exhaustion_mult(combatant: Dictionary) -> float:
    if not is_feature_fight_exhaustion_enabled() or combatant.is_empty():
        return 1.0
    return exhaustion_performance_mult(combatant.get(COMBATANT_KEY_EXHAUSTION, 0.0))


static func apply_parry_bind_riposte_gauge_bonus(defender: Dictionary) -> void:
    if defender.is_empty():
        return
    var g: float = defender.get(DataKeys.COMBATANT_GAUGE, 0.0)
    defender[DataKeys.COMBATANT_GAUGE] = minf(100.0, g + PARRY_BIND_RIPOSTE_GAUGE_BONUS)


## Scaling multiplier for stamina cost when a combatant performs consecutive actions without recovery.
## Each additional action in rapid succession costs more (simulating accumulated fatigue from not resetting
## posture/breath).
## `consecutive` = number of back-to-back actions (1 = first attack, 2 = second without full recovery, etc.).


static func consecutive_action_stamina_mult(consecutive: int) -> float:
    if consecutive <= 1:
        return 1.0
    var t: float = float(consecutive - 1)
    return lerpf(1.0, 2.0, clampf(t / 4.0, 0.0, 1.0))


## Escalating stamina cost multiplier specifically for consecutive parries.
## Models HEMA reality: repeatedly parrying without letting the blade settle creates compounding fatigue.
## Each parry within `parry_cooldown_reset_s` seconds of the previous one costs more than the last.
## Consecutive count resets after a full recovery window (default 1.5s).


static func consecutive_parry_stamina_mult(consecutive: int) -> float:
    if consecutive <= 1:
        return 1.0
    # Parry fatigue escalates faster than general actions — each successive parry is ~20-37% more expensive.
    # By the 5th consecutive parry, cost is 2.5x base (vs 2.0x for generic consecutive actions, which
    # include low-cost actions like waiting). Parries are physically demanding defensive motions.
    var t: float = float(consecutive - 1)
    return lerpf(1.0, 2.5, clampf(t / 4.0, 0.0, 1.0))


## Gain metabolic stress from stamina spend (lactate-like accumulation).
## Stacks with exertion but clears much slower — models medium-term metabolic burden affecting decision quality.


static func metabolic_stress_gain_from_stamina_spend(stamina_spent: float, endurance: float) -> float:
    var relief: float = clampf(endurance / 100.0, 0.0, 1.0) * METABOLIC_STRESS_ENDURANCE_MAX_RELIEF
    return stamina_spent * METABOLIC_STRESS_GAIN_PER_STAMINA_POINT * (1.0 - relief)


# --- Muscle fatigue → strike velocity degradation (HIGH #10 from biomechanics audit) ---
## Clinical basis: as muscles deplete ATP/PCr stores, rate of force development (RFD) drops before max strength fails.
## Boxing research (Häkkinen et al.): punch velocity declines 8-12% after ~90s of high-intensity work while peak power
## only drops 3-5%. This is because fast-twitch glycogen depletion impairs cross-bridge cycling speed first.
## The model: strike velocity degrades as a function of both current stamina ratio AND accumulated exhaustion,
## with separate curves for short-term (stamina) and medium-term (exhaustion/metabolic stress).

# At zero stamina, velocity retains this fraction after all other modifiers — a fighter can still throw weak strikes.
# Cited Häkkinen et al. boxing data: punch velocity declines ~8-12% after ~90s of high-intensity work (peak power only
# 3-5%). A floor near 0.80 keeps committed swings in the HEMA KE band; a steeper floor (old 0.45) drove KE to ~6% of
# full (KE ∝ v²), far below observed combat impact energy.


## Compute the combined stamina + exhaustion → strike velocity degradation factor (1.0 = full speed, lower = slower).
## This is applied multiplicatively to base weapon velocity before KE/damage calculation.
## `stamina_ratio`: current stamina / max stamina (0-1).
## `exhaustion`: accumulated exhaustion as a 0-1 depletion fraction (0 = fresh, 1 = fully exhausted).
## `skill_hold`: optional swing-mechanics hold in [-0.5, +0.5] (EntityProficiency.swing_skill_hold); 0.0 = neutral.
static func fatigue_velocity_mult(stamina_ratio: float, exhaustion: float = 0.0, skill_hold: float = 0.0) -> float:
    var hold: float = clampf(skill_hold, -0.5, 0.5)
    var st_factor: float = pow(clampf(stamina_ratio, 0.0, 1.0), FATIGUE_VELOCITY_POWER_EXPONENT)
    var zero_stamina_floor: float = clampf(
        FATIGUE_VELOCITY_FLOOR_AT_ZERO_STAMINA + hold * FATIGUE_SKILL_HOLD_FLOOR_SPAN, 0.55, 1.0
    )
    var vel_from_stamina: float = lerpf(zero_stamina_floor, 1.0, st_factor)

    # Exhaustion adds medium-term degradation — models glycogen depletion. The exhaustion value is already a
    # 0-1 depletion fraction that accumulates gradually with sustained exertion, so map it directly onto the floor.
    var exh_frac: float = clampf(exhaustion, 0.0, 1.0)
    var exhaustion_floor: float = clampf(
        FATIGUE_VELOCITY_EXHAUSTION_FLOOR + hold * FATIGUE_SKILL_HOLD_FLOOR_SPAN, 0.55, 1.0
    )
    var vel_from_exhaustion: float = lerpf(1.0, exhaustion_floor, exh_frac)

    return vel_from_stamina * vel_from_exhaustion
