class_name CombatConstantsStamina
extends RefCounted

## Stamina and exhaustion constants extracted from CombatConstants.gd.
## Preload this module when you only need stamina/exhaustion values and helpers.
const STAMINA_MAX := 100.0
const STAMINA_REFILL_RATE := 2.1
const STAMINA_ATTACK_COST_BASE := 12.0
const STAMINA_ATTACK_COST_SCALE := 8.0
const STAMINA_PARRY_COST := 12.0
const STAMINA_PARRY_COST_BASE := 12.0
const STAMINA_PARRY_COST_SCALE := 8.0
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
const COMBATANT_KEY_METABOLIC_STRESS := "_metabolic_stress"
const EXHAUSTION_MAX := 1.0
const EXHAUSTION_EXERTION_PER_STAMINA_POINT := 0.001
const EXHAUSTION_ENDURANCE_MAX_RELIEF := 0.45
const EXHAUSTION_RECOVERY_RATE := 0.015
const METABOLIC_STRESS_MAX := 1.0
const METABOLIC_STRESS_GAIN_PER_STAMINA_POINT := 0.002
const METABOLIC_STRESS_ENDURANCE_MAX_RELIEF := 0.35
const METABOLIC_STRESS_DECAY_RATE_WAITING := 0.0008
const EXHAUSTION_CURVE := 1.35
const EXHAUSTION_FLOOR_MULT := 0.55
const EXHAUSTION_UI_SHOW_THRESHOLD := 0.06
const EXHAUSTION_GAIN_BLOOD_LOSS_MULT := 1.35
const EXHAUSTION_GAIN_PAIN_SHOCK_MULT := 1.25
const EXHAUSTION_POWER_DEGRADATION_DELAY := 0.15
const FEATURE_FIGHT_EXHAUSTION_INDEX := CombatConstantsFeatureFlags.FEATURE_FIGHT_EXHAUSTION_INDEX


static func stamina_factor(ratio: float) -> float:
    return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)


## Compat alias of stamina_factor (call sites may use either).
static func breath_factor(ratio: float) -> float:
    return stamina_factor(ratio)


static func stamina_attack_cost_from_intensity(intensity: float) -> float:
    return STAMINA_ATTACK_COST_BASE + STAMINA_ATTACK_COST_SCALE * clampf(intensity, 0.0, 1.0)


static func stamina_parry_cost_from_intensity(intensity: float) -> float:
    return STAMINA_PARRY_COST_BASE + STAMINA_PARRY_COST_SCALE * clampf(intensity, 0.0, 1.0)


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
## Each additional action in rapid succession costs more (simulating accumulated fatigue from not resetting posture/breath).
## `consecutive` = number of back-to-back actions (1 = first attack, 2 = second without full recovery, etc.).
static func consecutive_action_stamina_mult(consecutive: int) -> float:
    if consecutive <= 1:
        return 1.0
    var t: float = float(consecutive - 1)
    return lerpf(1.0, 2.5, clampf(t / 4.0, 0.0, 1.0))


## Gain metabolic stress from stamina spend (lactate-like accumulation).
## Stacks with exertion but clears much slower — models medium-term metabolic burden affecting decision quality.
static func metabolic_stress_gain_from_stamina_spend(stamina_spent: float, endurance: float) -> float:
    var relief: float = clampf(endurance / 100.0, 0.0, 1.0) * METABOLIC_STRESS_ENDURANCE_MAX_RELIEF
    return stamina_spent * METABOLIC_STRESS_GAIN_PER_STAMINA_POINT * (1.0 - relief)


