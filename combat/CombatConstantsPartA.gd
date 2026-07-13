class_name CombatConstantsPartA
extends RefCounted
const MOVE_TARGET_APPLY_BANDAGE: String = "apply_bandage"
const MOVE_TARGET_APPLY_PACKING: String = "apply_packing"
const MOVE_TARGET_APPLY_STABILIZE: String = "apply_stabilize"
const MOVE_TARGET_APPLY_TOURNIQUET: String = "apply_tourniquet"

## Re-export afterblow constant.
const AFTERBLOW_CANCELLED_RECOVERY_S: float = CombatAfterblowConstants.AFTERBLOW_CANCELLED_RECOVERY_S

## Stat effect range for parry speed, medical effectiveness, etc.
const STAT_EFFECT_MULT_MIN: float = 0.5
const STAT_EFFECT_MULT_MAX: float = 1.5

## Gauge fill threshold  -  combatant considered "ready" when gauge >= this value.
const GAUGE_FULL_THRESHOLD: float = 0.95

## Stamina multiplier bounds used by exhaustion and defense resolution.
const STAMINA_MULT_FLOOR: float = 0.25
const STAMINA_MULT_CEILING: float = 1.0

## Field care (campaign) constants  -  stabilization thresholds and effectiveness range.
const FIELD_CARE_STABILIZE_FLOOR: float = 0.3
const FIELD_CARE_EFF_MIN: float = 0.5
const FIELD_CARE_EFF_MAX: float = 1.5

## Phase D: muscle fatigue tuning (per-limb exertion pools).
const MUSCLE_FATIGUE_WIND_UP_PERF_FLOOR: float = 0.45
const MUSCLE_FATIGUE_EXERTION_PER_BREATH_POINT: float = 0.012
const MUSCLE_FATIGUE_TWO_HANDED_OFF_ARM_SHARE: float = 0.3
const MUSCLE_FATIGUE_RECOVERY_RATE: float = 0.06
const MUSCLE_FATIGUE_RECOVERING_RATE_MULT: float = 0.5
const MUSCLE_FATIGUE_UI_SHOW_THRESHOLD: float = 0.12
const MUSCLE_FATIGUE_WAIT_RECOVERY_BOOST_TOP: float = 1.6
const MUSCLE_FATIGUE_FORMATION_DAMP_FLOOR: float = 0.45
const MUSCLE_FATIGUE_OFFENSE_DAMP_FLOOR: float = 0.55
const MUSCLE_FATIGUE_PARRY_CAPACITY_FLOOR: float = 0.35
const MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR: float = 0.4

## Combat tuning constants. Single source for CombatManager and AttackResolver.
## Reduces CombatManager from ~150 lines of constants to references.

## Re-export damage type constants.
const DAMAGE_TYPE_SHARP := CombatConstantsDamage.DAMAGE_TYPE_SHARP
const DAMAGE_TYPE_BLUNT := CombatConstantsDamage.DAMAGE_TYPE_BLUNT

## Re-export attack state machine.
const STATE_WAITING := CombatConstantsState.STATE_WAITING
const STATE_WIND_UP := CombatConstantsState.STATE_WIND_UP
const STATE_MEDICAL_WIND_UP := CombatConstantsState.STATE_MEDICAL_WIND_UP
const STATE_RECOVERING := CombatConstantsState.STATE_RECOVERING
const STATE_RECEIVING_MEDICAL_ATTENTION := CombatConstantsState.STATE_RECEIVING_MEDICAL_ATTENTION
const STATE_COWERING := CombatConstantsState.STATE_COWERING
const STATE_YIELDED := CombatConstantsState.STATE_YIELDED
const STATE_FLED := CombatConstantsState.STATE_FLED
const STATE_DEAD := CombatConstantsState.STATE_DEAD

## Re-export timing constants from CombatConstantsTiming.
const POWER_MIN := CombatConstantsTiming.POWER_MIN
const POWER_MAX := CombatConstantsTiming.POWER_MAX
const FOLLOW_THROUGH_MIN := CombatConstantsTiming.FOLLOW_THROUGH_MIN
const FOLLOW_THROUGH_MAX := CombatConstantsTiming.FOLLOW_THROUGH_MAX
const INTENSITY_MIN := CombatConstantsTiming.INTENSITY_MIN
const WIND_UP_BASE_S := CombatConstantsTiming.WIND_UP_BASE_S
const WIND_UP_SCALE_S := CombatConstantsTiming.WIND_UP_SCALE_S
const RECOVERY_BASE_S := CombatConstantsTiming.RECOVERY_BASE_S
const RECOVERY_COMMITMENT_SCALE_S := CombatConstantsTiming.RECOVERY_COMMITMENT_SCALE_S
const RECOVERY_EXTRA_HIT_S := CombatConstantsTiming.RECOVERY_EXTRA_HIT_S
const RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S := CombatConstantsTiming.RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S
const RECOVERY_EXTRA_DEFLECTED_BASE_S := CombatConstantsTiming.RECOVERY_EXTRA_DEFLECTED_BASE_S
const RECOVERY_DEFLECT_MOMENTUM_SCALE_S := CombatConstantsTiming.RECOVERY_DEFLECT_MOMENTUM_SCALE_S
const RECOVERY_EXTRA_GLANCING_BASE_S := CombatConstantsTiming.RECOVERY_EXTRA_GLANCING_BASE_S
const RECOVERY_GLANCING_SEVERITY_SCALE_S := CombatConstantsTiming.RECOVERY_GLANCING_SEVERITY_SCALE_S
const RECOVERY_EXTRA_MISS_BASE_S := CombatConstantsTiming.RECOVERY_EXTRA_MISS_BASE_S
const RECOVERY_MISS_COMMITMENT_SCALE_S := CombatConstantsTiming.RECOVERY_MISS_COMMITMENT_SCALE_S
const RECOVERY_EXTRA_FULL_STOP_BASE_S := CombatConstantsTiming.RECOVERY_EXTRA_FULL_STOP_BASE_S
const RECOVERY_FULL_STOP_COMMITMENT_SCALE_S := CombatConstantsTiming.RECOVERY_FULL_STOP_COMMITMENT_SCALE_S
const WINDUP_LEG_MIN := CombatConstantsTiming.WINDUP_LEG_MIN
const WIND_UP_DURATION_MAX_S := CombatConstantsTiming.WIND_UP_DURATION_MAX_S
const RECOVERY_AFTER_MEDICAL_S := CombatConstantsTiming.RECOVERY_AFTER_MEDICAL_S
const PACK_WOUND_TIMEOUT_S := 3.0

## Re-export attack data flow dict keys.
const PA_KEY_ATTACK_TYPE := CombatConstantsDictKeys.PA_KEY_ATTACK_TYPE
const PA_KEY_EFFECTIVE_ATTACK_LINE := CombatConstantsDictKeys.PA_KEY_EFFECTIVE_ATTACK_LINE
const PA_KEY_PASSIVE_PARRY_ATTEMPTED := CombatConstantsDictKeys.PA_KEY_PASSIVE_PARRY_ATTEMPTED
const PA_KEY_INTENSITY := CombatConstantsDictKeys.PA_KEY_INTENSITY
const PA_DEFAULT_INTENSITY := CombatConstantsDictKeys.PA_DEFAULT_INTENSITY
const CLASH_KEY_PARRY_CONTROL := CombatConstantsDictKeys.CLASH_KEY_PARRY_CONTROL
const DEFAULT_PARRY_CONTROL := CombatConstantsDictKeys.DEFAULT_PARRY_CONTROL
const INTERPOSE_KEY_ARM := CombatConstantsDictKeys.INTERPOSE_KEY_ARM
const CLASH_KEY_ARM_INTERPOSE := CombatConstantsDictKeys.CLASH_KEY_ARM_INTERPOSE
const RESULT_KEY_DIED := CombatConstantsDictKeys.RESULT_KEY_DIED
const MOVE_DEF_KEY_IS_FEINT := CombatConstantsDictKeys.MOVE_DEF_KEY_IS_FEINT

## Re-export miss/hit/glancing and intensity constants.
const MISS_CHANCE_BASE := CombatConstantsDamage.MISS_CHANCE_BASE
const HIT_CHANCE_PERCEPTION_MIN := CombatConstantsDamage.HIT_CHANCE_PERCEPTION_MIN
const HIT_CHANCE_PERCEPTION_MAX := CombatConstantsDamage.HIT_CHANCE_PERCEPTION_MAX
const GLANCING_DAMAGE_RATIO := CombatConstantsDamage.GLANCING_DAMAGE_RATIO
const PHYSICAL_DAMAGE_ZERO_EPS := CombatConstantsDamage.PHYSICAL_DAMAGE_ZERO_EPS
const INTENSITY_STRENGTH_SCALE := CombatConstantsDamage.INTENSITY_STRENGTH_SCALE
const INTENSITY_STRENGTH_NORM := CombatConstantsDamage.INTENSITY_STRENGTH_NORM
const INTENSITY_STRENGTH_BIAS := CombatConstantsDamage.INTENSITY_STRENGTH_BIAS
const INTENSITY_RANDOM_RANGE := CombatConstantsDamage.INTENSITY_RANDOM_RANGE

# Medical move IDs (canonical strings --" use MOVE_ID_*, not literals)
# Ally variants and direct-pressure sub-moves (MOVE_ID_BANDAGE_ALLY, MOVE_ID_FREE_PRESSURE, etc.)
# are in CombatConstantsMedical.gd --" preload that module directly for those constants.
const MOVE_ID_BANDAGE_SELF := "bandage_self"
const MOVE_ID_PACK_WOUND := "pack_wound"
const MOVE_ID_STABILIZE_WOUND := "stabilize_wound"
const MOVE_ID_APPLY_DIRECT_PRESSURE := "apply_direct_pressure"
const MOVE_ID_APPLY_TOURNIQUET := "apply_tourniquet"

const MEDICAL_MOVE_IDS: Array[String] = [
    MOVE_ID_BANDAGE_SELF,
    MOVE_ID_PACK_WOUND,
    MOVE_ID_STABILIZE_WOUND,
    MOVE_ID_APPLY_DIRECT_PRESSURE,
    MOVE_ID_APPLY_TOURNIQUET,
]
const DRESSING_MEDICAL_MOVE_IDS: Array[String] = [MOVE_ID_BANDAGE_SELF, MOVE_ID_PACK_WOUND, MOVE_ID_STABILIZE_WOUND]
const DIRECT_PRESSURE_TREATMENT_ASSIST_EFFECTIVENESS_FRACTION := 0.50
## Additive to treater effectiveness when completing wind-up with `direct_pressure_assist_held_by` set (helper +
## treater).
const MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS := 0.12
## Wind-up duration divisor when primary holder compresses the part during dressing (buddy system).
const MEDICAL_WINDUP_PRIMARY_HOLDER_DURATION_BONUS := 0.40
## Extra divisor when treater stacks assist on an existing holder during wind-up.
const MEDICAL_WINDUP_STACK_ASSIST_DURATION_BONUS := 0.25
## Ally treating ally: up to this fraction slower from patient thrashing (shock/pain), not full medic shock penalty.
const MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY := 0.18

## Re-export parry constants and functions.
const PARRY_V_FRACTION_OF_MAX_STRIKE := CombatConstantsParry.PARRY_V_FRACTION_OF_MAX_STRIKE
const PARRY_STRENGTH_NORM := CombatConstantsParry.PARRY_STRENGTH_NORM
const PARRY_DEFLECT_THRESHOLD := CombatConstantsParry.PARRY_DEFLECT_THRESHOLD
const PARRY_TECHNIQUE_VARIANCE := CombatConstantsParry.PARRY_TECHNIQUE_VARIANCE
const PARRY_V_MIN_FRACTION := CombatConstantsParry.PARRY_V_MIN_FRACTION
const PARRY_V_MIN_NEAR_DEFLECT := CombatConstantsParry.PARRY_V_MIN_NEAR_DEFLECT
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := CombatConstantsParry.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S
const PARRY_BLADE_MOVEMENT_S := CombatConstantsParry.PARRY_BLADE_MOVEMENT_S
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := CombatConstantsParry.PARRY_MOVEMENT_MASS_STRENGTH_MIN
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := CombatConstantsParry.PARRY_MOVEMENT_MASS_STRENGTH_MAX
const PERF_MOD_MIN := CombatConstantsParry.PERF_MOD_MIN
const COMMITMENT_FRACTION := CombatConstantsParry.COMMITMENT_FRACTION
const COMMITMENT_FRACTION_FEINT := CombatConstantsParry.COMMITMENT_FRACTION_FEINT
const RECOVERY_READINESS_EARLY := CombatConstantsParry.RECOVERY_READINESS_EARLY
const RECOVERY_READINESS_LATE := CombatConstantsParry.RECOVERY_READINESS_LATE
const OFF_BALANCE_DURATION_S := CombatConstantsParry.OFF_BALANCE_DURATION_S
const OFF_BALANCE_PARRY_CAPACITY_MULT := CombatConstantsParry.OFF_BALANCE_PARRY_CAPACITY_MULT
const OFF_BALANCE_GAUGE_FILL_MULT := CombatConstantsParry.OFF_BALANCE_GAUGE_FILL_MULT
const PARRY_BONUS_AFTER_DEFLECT_S := CombatConstantsParry.PARRY_BONUS_AFTER_DEFLECT_S
const GUARD_AFTER_ATTACK := CombatConstantsParry.GUARD_AFTER_ATTACK
const GUARD_RISE_RATE := CombatConstantsParry.GUARD_RISE_RATE
const PARRY_DODGE_STRENGTH_RATIO := CombatConstantsParry.PARRY_DODGE_STRENGTH_RATIO
const PARRY_BLOCK_MASS_THRESHOLD := CombatConstantsParry.PARRY_BLOCK_MASS_THRESHOLD
const PARRY_BLOCK_STR_THRESHOLD := CombatConstantsParry.PARRY_BLOCK_STR_THRESHOLD
const PARRY_REDIRECT_BONUS := CombatConstantsParry.PARRY_REDIRECT_BONUS
const PARRY_REDIRECT_SKILL_SCALE := CombatConstantsParry.PARRY_REDIRECT_SKILL_SCALE
const PARRY_REDIRECT_ATTEMPT_RATIO := CombatConstantsParry.PARRY_REDIRECT_ATTEMPT_RATIO
const PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE := CombatConstantsParry.PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE
const PARRY_GLANCING_EXPONENT := CombatConstantsParry.PARRY_GLANCING_EXPONENT
const PARRY_REDIRECT_THRUST_BONUS := CombatConstantsParry.PARRY_REDIRECT_THRUST_BONUS
const PARRY_REDIRECT_BLUNT_PENALTY := CombatConstantsParry.PARRY_REDIRECT_BLUNT_PENALTY
const PARRY_CUT_TO_BLUNT_SHIFT := CombatConstantsParry.PARRY_CUT_TO_BLUNT_SHIFT
const PARRY_PENETRATION_ANGLE_MIN := CombatConstantsParry.PARRY_PENETRATION_ANGLE_MIN
const PARRY_PENETRATION_ALIGNMENT_SCALE := CombatConstantsParry.PARRY_PENETRATION_ALIGNMENT_SCALE
const PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD := CombatConstantsParry.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
const PARRY_BIND_CONTROL_THRESHOLD := CombatConstantsParry.PARRY_BIND_CONTROL_THRESHOLD
const ARCHETYPES_NEVER_BIND: Array[String] = CombatConstantsParry.ARCHETYPES_NEVER_BIND
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = CombatConstantsParry.PARRY_BIND_RIPOSTE_BY_PART_CONTACT
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = CombatConstantsParry.PARRY_BIND_RIPOSTE_MULT_FALLBACK
const PARRY_LATE_CONTROL_FACTOR := CombatConstantsParry.PARRY_LATE_CONTROL_FACTOR
const PARRY_OFF_BALANCE_CONTROL_FACTOR := CombatConstantsParry.PARRY_OFF_BALANCE_CONTROL_FACTOR
const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := CombatConstantsAttackPath.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT
const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := CombatConstantsAttackPath.PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST
const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := CombatConstantsAttackPath.PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT
const PARRY_THRUST_CONTROL_MULT := CombatConstantsParry.PARRY_THRUST_CONTROL_MULT
const DEFLECTED_GUARD_FROM_ATTACK: Dictionary = CombatConstantsAttackPath.DEFLECTED_GUARD_FROM_ATTACK
const LINE_ADJACENTS: Dictionary = CombatConstantsAttackPath.LINE_ADJACENTS
const DODGE_END_GUARD_FROM_ATTACK: Dictionary = CombatConstantsAttackPath.DODGE_END_GUARD_FROM_ATTACK
const PARRY_DESPERATE_DODGE_THRESHOLD := CombatConstantsParry.PARRY_DESPERATE_DODGE_THRESHOLD
const PARRY_PREFER_DODGE_FULL_THRESHOLD := CombatConstantsParry.PARRY_PREFER_DODGE_FULL_THRESHOLD
const PARRY_MASS_DISPARITY_BONUS := CombatConstantsParry.PARRY_MASS_DISPARITY_BONUS
const PARRY_LATE_CAPACITY_FLOOR := CombatConstantsParry.PARRY_LATE_CAPACITY_FLOOR
const PARRY_CONTACT_MODIFIERS: Dictionary = CombatConstantsParry.PARRY_CONTACT_MODIFIERS
const PARRY_DEF_VS_ATK_MOD: Dictionary = CombatConstantsParry.PARRY_DEF_VS_ATK_MOD
const PARRY_INERTIA_BLEND: float = CombatConstantsParry.PARRY_INERTIA_BLEND
const PARRY_LEVERAGE_LONG_PART_CM: float = CombatConstantsParry.PARRY_LEVERAGE_LONG_PART_CM
const PARRY_LEVERAGE_FLOOR: float = CombatConstantsParry.PARRY_LEVERAGE_FLOOR

## Re-export recovery cause readiness curves.
const READINESS_BY_CAUSE: Dictionary = CombatConstantsRecoveryCause.READINESS_BY_CAUSE

## Re-export guard zone and part-to-line mapping.
const GUARD_ZONE_BONUS := CombatConstantsGuardZone.GUARD_ZONE_BONUS
const GUARD_ZONE_UNGUARDED_PENALTY := CombatConstantsGuardZone.GUARD_ZONE_UNGUARDED_PENALTY
const GUARD_DEFAULT := CombatConstantsGuardZone.GUARD_DEFAULT
const PART_TO_LINE: Dictionary = CombatConstantsGuardZone.PART_TO_LINE
const LINE_TO_DEFAULT_PART: Dictionary = CombatConstantsGuardZone.LINE_TO_DEFAULT_PART

## Re-export counter-tempo, riposte chain, and flurry bind constants.
const COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART := (
    CombatConstantsCounterTempo.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART
)
const COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK := (
    CombatConstantsCounterTempo.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK
)
const COMBATANT_KEY_COUNTER_WINDOW_UNTIL := CombatConstantsCounterTempo.COMBATANT_KEY_COUNTER_WINDOW_UNTIL
const ACTION_KEY_COUNTER_TEMPO := CombatConstantsCounterTempo.ACTION_KEY_COUNTER_TEMPO
const ACTION_KEY_CLOSE_LIST_HINT := CombatConstantsCounterTempo.ACTION_KEY_CLOSE_LIST_HINT
const PA_KEY_COUNTER_TEMPO := CombatConstantsCounterTempo.PA_KEY_COUNTER_TEMPO
const COUNTER_TEMPO_GAUGE_THRESHOLD := CombatConstantsCounterTempo.COUNTER_TEMPO_GAUGE_THRESHOLD
const COUNTER_TEMPO_GAUGE_COST := CombatConstantsCounterTempo.COUNTER_TEMPO_GAUGE_COST
const COUNTER_TEMPO_WINDOW_FRACTION := CombatConstantsCounterTempo.COUNTER_TEMPO_WINDOW_FRACTION
const COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS := (
    CombatConstantsCounterTempo.COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS
)
const COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED := (
    CombatConstantsCounterTempo.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED
)
const COMBATANT_KEY_COUNTER_TEMPO_UI_HINT := CombatConstantsCounterTempo.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT
const COUNTER_TEMPO_WINDUP_MULT := CombatConstantsCounterTempo.COUNTER_TEMPO_WINDUP_MULT
const COUNTER_TEMPO_WINDUP_MAX_S := CombatConstantsCounterTempo.COUNTER_TEMPO_WINDUP_MAX_S
const COUNTER_TEMPO_ACTION_READY_DELAY_S := CombatConstantsCounterTempo.COUNTER_TEMPO_ACTION_READY_DELAY_S
const COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S := (
    CombatConstantsCounterTempo.COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S
)
const AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT := CombatConstantsCounterTempo.AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT
const AI_COUNTER_TEMPO_INCOMING_TARGET_MULT := CombatConstantsCounterTempo.AI_COUNTER_TEMPO_INCOMING_TARGET_MULT
const AI_COUNTER_TEMPO_FEINT_DAMP_MULT := CombatConstantsCounterTempo.AI_COUNTER_TEMPO_FEINT_DAMP_MULT
const COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL := CombatConstantsCounterTempo.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL
const COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID := CombatConstantsCounterTempo.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID
const PA_KEY_RIPOSTE_CHAIN := CombatConstantsCounterTempo.PA_KEY_RIPOSTE_CHAIN
const RIPOSTE_CHAIN_WINDOW_S := CombatConstantsCounterTempo.RIPOSTE_CHAIN_WINDOW_S
const RIPOSTE_CHAIN_WINDUP_MULT := CombatConstantsCounterTempo.RIPOSTE_CHAIN_WINDUP_MULT
const FLURRY_BIND_WINDOW_S := CombatConstantsCounterTempo.FLURRY_BIND_WINDOW_S
const FLURRY_BIND_MAX_EXCHANGES := CombatConstantsCounterTempo.FLURRY_BIND_MAX_EXCHANGES
const FLURRY_BIND_WIND_UP_MULT := CombatConstantsCounterTempo.FLURRY_BIND_WIND_UP_MULT
const FLURRY_BIND_STAMINA_ATTACK_COST_MULT := CombatConstantsCounterTempo.FLURRY_BIND_STAMINA_ATTACK_COST_MULT

## Re-export mental stack and attention constants.
const COMBATANT_KEY_FOCUS_PART := CombatConstantsMentalStack.COMBATANT_KEY_FOCUS_PART
const COMBATANT_KEY_FOCUS_INTENSITY := CombatConstantsMentalStack.COMBATANT_KEY_FOCUS_INTENSITY
const COMBATANT_KEY_ATTENTION_LOAD := CombatConstantsMentalStack.COMBATANT_KEY_ATTENTION_LOAD
const COMBATANT_KEY_YOMI_BY_ATTACKER := CombatConstantsMentalStack.COMBATANT_KEY_YOMI_BY_ATTACKER
const COMBATANT_KEY_WEAPON_FORM := CombatConstantsMentalStack.COMBATANT_KEY_WEAPON_FORM
const COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL := CombatConstantsMentalStack.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL
const COMBATANT_KEY_LAST_FORM_SWITCH_REASON := CombatConstantsMentalStack.COMBATANT_KEY_LAST_FORM_SWITCH_REASON
const COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID := CombatConstantsMentalStack.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID
const COMBATANT_KEY_ATTENTION_UI_HINT := CombatConstantsMentalStack.COMBATANT_KEY_ATTENTION_UI_HINT
const COMBATANT_KEY_MENTAL_STACK_LAYER := CombatConstantsMentalStack.COMBATANT_KEY_MENTAL_STACK_LAYER
const COMBATANT_KEY_SUSPEND_BLEED_TICK := CombatConstantsMentalStack.COMBATANT_KEY_SUSPEND_BLEED_TICK
const MENTAL_STACK_LAYER_SELF_MEDICAL := CombatConstantsMentalStack.MENTAL_STACK_LAYER_SELF_MEDICAL
const MENTAL_STACK_LAYER_MEDICAL := CombatConstantsMentalStack.MENTAL_STACK_LAYER_MEDICAL
const MENTAL_STACK_LAYER_COUNTER := CombatConstantsMentalStack.MENTAL_STACK_LAYER_COUNTER
const MENTAL_STACK_LAYER_INCOMING := CombatConstantsMentalStack.MENTAL_STACK_LAYER_INCOMING
const MENTAL_STACK_LAYER_HOLD_LINE := CombatConstantsMentalStack.MENTAL_STACK_LAYER_HOLD_LINE
const MENTAL_STACK_LAYER_SPARSE_FIGHT := CombatConstantsMentalStack.MENTAL_STACK_LAYER_SPARSE_FIGHT
const MENTAL_STACK_LAYER_FORMATION_PLUG := CombatConstantsMentalStack.MENTAL_STACK_LAYER_FORMATION_PLUG
const MENTAL_STACK_LAYER_ROUT := CombatConstantsMentalStack.MENTAL_STACK_LAYER_ROUT
const MENTAL_STACK_LAYER_POST_STRIKE := CombatConstantsMentalStack.MENTAL_STACK_LAYER_POST_STRIKE
const COMBATANT_KEY_LAST_STRIKE_TICK := CombatConstantsMentalStack.COMBATANT_KEY_LAST_STRIKE_TICK
const COMBATANT_KEY_LAST_STRIKE_TARGET_ID := CombatConstantsMentalStack.COMBATANT_KEY_LAST_STRIKE_TARGET_ID
const POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE := CombatConstantsMentalStack.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE
const POST_STRIKE_HIT_WEIGHT_BONUS := CombatConstantsMentalStack.POST_STRIKE_HIT_WEIGHT_BONUS
const POST_STRIKE_MOMENTUM_WEIGHT_BONUS := CombatConstantsMentalStack.POST_STRIKE_MOMENTUM_WEIGHT_BONUS
const MENTAL_STACK_LAYER_POSITIONAL_DIS := CombatConstantsMentalStack.MENTAL_STACK_LAYER_POSITIONAL_DIS
const MENTAL_STACK_LAYER_EXHAUSTION := CombatConstantsMentalStack.MENTAL_STACK_LAYER_EXHAUSTION
const MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD := CombatConstantsMentalStack.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
const MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD := (
    CombatConstantsMentalStack.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD
)
const MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX := CombatConstantsMentalStack.MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX
const FOCUS_INTENSITY_DEFAULT := CombatConstantsMentalStack.FOCUS_INTENSITY_DEFAULT
const ATTENTION_LOAD_TELEGRAPH_WEIGHT := CombatConstantsMentalStack.ATTENTION_LOAD_TELEGRAPH_WEIGHT
const ATTENTION_LOAD_PERIL_WEIGHT := CombatConstantsMentalStack.ATTENTION_LOAD_PERIL_WEIGHT
const ATTENTION_LOAD_COUNTER_WEIGHT := CombatConstantsMentalStack.ATTENTION_LOAD_COUNTER_WEIGHT
const ATTENTION_LOAD_FOCUS_PENALTY := CombatConstantsMentalStack.ATTENTION_LOAD_FOCUS_PENALTY
const FOCUS_WRONG_LINE_READTHROUGH_MULT := CombatConstantsMentalStack.FOCUS_WRONG_LINE_READTHROUGH_MULT
const FOCUS_CORRECT_LINE_READTHROUGH_MULT := CombatConstantsMentalStack.FOCUS_CORRECT_LINE_READTHROUGH_MULT
const YOMI_FEINT_LISTING_MIN_LINE_COUNT := CombatConstantsMentalStack.YOMI_FEINT_LISTING_MIN_LINE_COUNT
const YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT := CombatConstantsMentalStack.YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT
const YOMI_FEINT_LISTING_MULT_CAP := CombatConstantsMentalStack.YOMI_FEINT_LISTING_MULT_CAP
const YOMI_FOCUS_DRIFT_MIN_LINE_COUNT := CombatConstantsMentalStack.YOMI_FOCUS_DRIFT_MIN_LINE_COUNT
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD := (
    CombatConstantsMentalStack.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD
)
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT := (
    CombatConstantsMentalStack.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT
)
const YOMI_FOCUS_DRIFT_INTENSITY := CombatConstantsMentalStack.YOMI_FOCUS_DRIFT_INTENSITY
const MEDICAL_AI_WEIGHT_ESCALATION_BONUS := CombatConstantsMentalStack.MEDICAL_AI_WEIGHT_ESCALATION_BONUS

## Re-export muscle fatigue key.
const COMBATANT_KEY_MUSCLE_FATIGUE := DataKeys.COMBATANT_KEY_MUSCLE_FATIGUE
const FEATURE_MUSCLE_GROUP_FATIGUE := true
static var _feature_muscle_group_fatigue_load: int = -1

## Central combat constants facade: re-exports sibling CombatConstants*.gd modules.
## New consts belong in the owning sibling module, then re-export here if call sites use CombatConstants.X.
## Do not grow large literal tables in this file.


static func _get_entity_access() -> GDScript:
    return CombatantEntityAccess


static func is_medical_move(move_id: String) -> bool:
    return move_id in MEDICAL_MOVE_IDS


static func is_direct_pressure_move(move_id: String) -> bool:
    return move_id == MOVE_ID_APPLY_DIRECT_PRESSURE


static func is_wind_up_medical_move(move_id: String) -> bool:
    return is_medical_move(move_id) and not is_direct_pressure_move(move_id)


static func is_dressing_medical_move(move_id: String) -> bool:
    return move_id in DRESSING_MEDICAL_MOVE_IDS


static func is_tourniquet_move(move_id: String) -> bool:
    return move_id == MOVE_ID_APPLY_TOURNIQUET


static func is_pack_wound_move(move_id: String) -> bool:
    return move_id == MOVE_ID_PACK_WOUND


static func is_stabilize_wound_move(move_id: String) -> bool:
    return move_id == MOVE_ID_STABILIZE_WOUND


## Extra pressure pass from the treater while an ally already holds the wound (bandage/pack/tourniquet wind-up). Scales
## treater medical effectiveness into `EntityMedical._apply_direct_pressure_to_wounds`.
## Second rescuer adds this fraction of their compression skill on top of primary hold (buddy pressure, TCCC).


static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool) -> bool:
    return CombatConstantsParry.parry_full_stop_reached(c_d, parry_p_a, is_block_parry)


static func parry_edge_deflect_reached(c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool) -> bool:
    return CombatConstantsParry.parry_edge_deflect_reached(c_d, parry_p_a, alignment, is_block_parry)


static func parry_bind_control_reached(parry_control: float) -> bool:
    return CombatConstantsParry.parry_bind_control_reached(parry_control)


static func iii3_baseline_constants_line() -> String:
    return CombatConstantsParry.iii3_baseline_constants_line()


static func p4d_parry_bind_doc_sync_line() -> String:
    return CombatConstantsParry.p4d_parry_bind_doc_sync_line()


## Re-export feature flag helpers.


## Re-export feature flag helpers.
static func is_feature_combat_attention_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_combat_attention_enabled()


static func set_feature_combat_attention_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_combat_attention_load(enabled)


static func is_feature_mental_stack_ai_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_mental_stack_ai_enabled()


static func set_feature_mental_stack_ai_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_mental_stack_ai_load(enabled)


static func is_feature_ms_positional_awareness_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_ms_positional_awareness_enabled()


static func set_feature_ms_positional_awareness_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_ms_positional_awareness_load(enabled)


static func is_feature_ms_l6_rout_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_ms_l6_rout_enabled()


static func set_feature_ms_l6_rout_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_ms_l6_rout_load(enabled)


static func is_feature_ms_feint_resistance_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_ms_feint_resistance_enabled()


static func set_feature_ms_feint_resistance_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_ms_feint_resistance_load(enabled)


static func is_feature_ms_mid_infight_med_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_ms_mid_infight_med_enabled()


static func set_feature_ms_mid_infight_med_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_ms_mid_infight_med_load(enabled)


static func is_feature_ms_medical_escalation_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_ms_medical_escalation_enabled()


static func set_feature_ms_medical_escalation_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_ms_medical_escalation_load(enabled)


static func is_feature_ms_post_strike_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_ms_post_strike_enabled()


static func set_feature_ms_post_strike_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_ms_post_strike_load(enabled)


static func is_feature_counter_tempo_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_counter_tempo_enabled()


static func set_feature_counter_tempo_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_counter_tempo_load(enabled)


static func is_feature_flurry_bind_exchange_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_flurry_bind_exchange_enabled()


static func set_feature_flurry_bind_exchange_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_flurry_bind_exchange_load(enabled)


static func is_feature_position_angle_footwork_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_position_angle_footwork_enabled()


static func set_feature_position_angle_footwork_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_position_angle_footwork_load(enabled)


static func is_feature_armor_burden_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_armor_burden_enabled()


static func set_feature_armor_burden_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_armor_burden_load(enabled)


static func armor_burden_mass_ratio_for_combatant(combatant: Dictionary) -> float:
    return CombatConstantsFeatureFlags.armor_burden_mass_ratio_for_combatant(combatant)


static func armor_burden_action_ready_mult(combatant: Dictionary) -> float:
    return CombatConstantsFeatureFlags.armor_burden_action_ready_mult(combatant)


static func armor_burden_passive_readiness_mult(combatant: Dictionary) -> float:
    return CombatConstantsFeatureFlags.armor_burden_passive_readiness_mult(combatant)


static func is_feature_initiative_order_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_initiative_order_enabled()


static func set_feature_initiative_order_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_initiative_order_load(enabled)


static func compare_combatants_for_initiative_order(a: Dictionary, b: Dictionary) -> bool:
    return CombatConstantsFeatureFlags.compare_combatants_for_initiative_order(a, b)


static func is_feature_gap_column_topology_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_gap_column_topology_enabled()


static func set_feature_gap_column_topology_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_gap_column_topology_load(enabled)


static func iv9_gap_column_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.iv9_gap_column_doc_sync_line()


static func is_feature_subregion_combat_mult_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_subregion_combat_mult_enabled()


static func set_feature_subregion_combat_mult_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_subregion_combat_mult_load(enabled)


static func is_feature_leader_formation_command_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_leader_formation_command_enabled()


static func set_feature_leader_formation_command_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_leader_formation_command_load(enabled)


static func iv11_leader_formation_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.iv11_leader_formation_doc_sync_line()


static func is_feature_iv12_slot_distraction_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_iv12_slot_distraction_enabled()


static func set_feature_iv12_slot_distraction_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_iv12_slot_distraction_load(enabled)


static func iv12_slot_distraction_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.iv12_slot_distraction_doc_sync_line()


static func is_feature_iv13_weapon_reach_zoc_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_iv13_weapon_reach_zoc_enabled()


static func set_feature_iv13_weapon_reach_zoc_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_iv13_weapon_reach_zoc_load(enabled)


static func iv13_weapon_reach_zoc_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.iv13_weapon_reach_zoc_doc_sync_line()


static func is_feature_t44_spatial_band_pa_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_t44_spatial_band_pa_enabled()


static func set_feature_t44_spatial_band_pa_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_t44_spatial_band_pa_load(enabled)


static func t44_spatial_band_pa_magnitude_mult(band: String) -> float:
    return CombatConstantsFeatureFlags.t44_spatial_band_pa_magnitude_mult(band)


static func is_feature_t44_spatial_file_dodge_bias_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_t44_spatial_file_dodge_bias_enabled()


static func set_feature_t44_spatial_file_dodge_bias_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_t44_spatial_file_dodge_bias_load(enabled)


static func t44_spatial_file_dodge_wing_mult(file_index: int, formation_files: int) -> float:
    return CombatConstantsFeatureFlags.t44_spatial_file_dodge_wing_mult(file_index, formation_files)


static func is_feature_t44_spatial_flurry_pa_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_t44_spatial_flurry_pa_enabled()


static func set_feature_t44_spatial_flurry_pa_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_t44_spatial_flurry_pa_load(enabled)


static func t44_spatial_band_pa_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.t44_spatial_band_pa_doc_sync_line()


static func t44_spatial_file_dodge_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.t44_spatial_file_dodge_doc_sync_line()


static func t44_spatial_flurry_pa_doc_sync_line() -> String:
    return CombatConstantsFeatureFlags.t44_spatial_flurry_pa_doc_sync_line()


static func is_feature_hema_eight_guard_lines_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled()


static func set_feature_hema_eight_guard_lines_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_hema_eight_guard_lines_load(enabled)


static func is_feature_arm_interpose_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_arm_interpose_enabled()


static func set_feature_arm_interpose_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_arm_interpose_load(enabled)


static func is_feature_iv6_attack_path_octant_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_iv6_attack_path_octant_enabled()


static func set_feature_iv6_attack_path_octant_load(enabled: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_iv6_attack_path_octant_load(enabled)


static func is_feature_sector_surround_load() -> bool:
    return CombatConstantsFeatureFlags.is_feature_sector_surround_load()


static func set_feature_sector_surround_load(on: bool) -> void:
    CombatConstantsFeatureFlags.set_feature_sector_surround_load(on)


static func is_feature_surround_arc_occupancy_enabled() -> bool:
    return CombatConstantsFeatureFlags.is_feature_surround_arc_occupancy_enabled()


static func reset_harness_feature_load_overrides() -> void:
    CombatConstantsFeatureFlags.reset_harness_feature_load_overrides()


## Phase D: muscle fatigue feature flag.


static func is_feature_muscle_group_fatigue_enabled() -> bool:
    if _feature_muscle_group_fatigue_load >= 0:
        return _feature_muscle_group_fatigue_load != 0
    return FEATURE_MUSCLE_GROUP_FATIGUE


static func set_feature_muscle_group_fatigue_load(enabled: bool) -> void:
    _feature_muscle_group_fatigue_load = 1 if enabled else 0


static func is_focus_line_move(move_id: String) -> bool:
    return move_id in FOCUS_LINE_MOVE_IDS


static func position_angle_offset_deg_for_attack_line(line: String) -> float:
    var k: String = line.strip_edges()
    if is_feature_hema_eight_guard_lines_enabled():
        return CombatGuardLines.position_angle_offset_deg_for_line(k)
    # Fallback for harness/tests with eight-guard flag off — delegate to guard lines module.
    return CombatGuardLines.position_angle_offset_deg_for_line(k)
