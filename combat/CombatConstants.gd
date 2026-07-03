class_name CombatConstants
extends RefCounted

## Central combat constants: states, timing, move IDs, medical config, formation/focus moves, flags.

const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

static func _get_entity_access() -> GDScript:
	return _EntityAccess

const _AfterblowConstants := preload("res://combat/CombatAfterblowConstants.gd")
const _TimingConstants := preload("res://combat/CombatConstantsTiming.gd")
const _Stamina := preload("res://combat/CombatConstantsStamina.gd")
const _AttackPath := preload("res://combat/CombatConstantsAttackPath.gd")
const _State := preload("res://combat/CombatConstantsState.gd")
const _DictKeys := preload("res://combat/CombatConstantsDictKeys.gd")
const _Damage := preload("res://combat/CombatConstantsDamage.gd")
const _GuardZone := preload("res://combat/CombatConstantsGuardZone.gd")
const _Distance := preload("res://combat/CombatConstantsDistance.gd")
const _EventQueue := preload("res://combat/CombatConstantsEventQueue.gd")
const _Debug := preload("res://combat/CombatConstantsDebug.gd")
const _ParryChoice := preload("res://combat/CombatConstantsParryChoice.gd")
const _FeatureFlags := preload("res://combat/CombatConstantsFeatureFlags.gd")
const _RecoveryCause := preload("res://combat/CombatConstantsRecoveryCause.gd")
const _CounterTempo := preload("res://combat/CombatConstantsCounterTempo.gd")
const _MentalStack := preload("res://combat/CombatConstantsMentalStack.gd")
const _Parry := preload("res://combat/CombatConstantsParry.gd")
const _Footwork := preload("res://combat/CombatConstantsFootwork.gd")
const _FormationMove := preload("res://combat/CombatConstantsFormationMove.gd")
const _CloseSlots := preload("res://combat/CombatConstantsCloseSlots.gd")
const _Encounter := preload("res://combat/CombatConstantsEncounter.gd")
const _Misc := preload("res://combat/CombatConstantsMisc.gd")
const _Stance := preload("res://combat/CombatConstantsStance.gd")

## Medical move target identifiers --" cross-cutting use (no sub-module).
const MOVE_TARGET_APPLY_BANDAGE: String = "apply_bandage"
const MOVE_TARGET_APPLY_PACKING: String = "apply_packing"
const MOVE_TARGET_APPLY_STABILIZE: String = "apply_stabilize"
const MOVE_TARGET_APPLY_TOURNIQUET: String = "apply_tourniquet"

## Re-export afterblow constant.
const AFTERBLOW_CANCELLED_RECOVERY_S: float = _AfterblowConstants.AFTERBLOW_CANCELLED_RECOVERY_S

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

## Combat tuning constants. Single source for CombatManager and AttackResolver.
## Reduces CombatManager from ~150 lines of constants to references.

## Re-export damage type constants.
const DAMAGE_TYPE_SHARP := _Damage.DAMAGE_TYPE_SHARP
const DAMAGE_TYPE_BLUNT := _Damage.DAMAGE_TYPE_BLUNT

## Re-export attack state machine.
const STATE_WAITING := _State.STATE_WAITING
const STATE_WIND_UP := _State.STATE_WIND_UP
const STATE_MEDICAL_WIND_UP := _State.STATE_MEDICAL_WIND_UP
const STATE_RECOVERING := _State.STATE_RECOVERING
const STATE_RECEIVING_MEDICAL_ATTENTION := _State.STATE_RECEIVING_MEDICAL_ATTENTION
const STATE_COWERING := _State.STATE_COWERING
const STATE_YIELDED := _State.STATE_YIELDED
const STATE_FLED := _State.STATE_FLED
const STATE_DEAD := _State.STATE_DEAD

## Re-export timing constants from CombatConstantsTiming.
const POWER_MIN := _TimingConstants.POWER_MIN
const POWER_MAX := _TimingConstants.POWER_MAX
const FOLLOW_THROUGH_MIN := _TimingConstants.FOLLOW_THROUGH_MIN
const FOLLOW_THROUGH_MAX := _TimingConstants.FOLLOW_THROUGH_MAX
const INTENSITY_MIN := _TimingConstants.INTENSITY_MIN
const WIND_UP_BASE_S := _TimingConstants.WIND_UP_BASE_S
const WIND_UP_SCALE_S := _TimingConstants.WIND_UP_SCALE_S
const RECOVERY_BASE_S := _TimingConstants.RECOVERY_BASE_S
const RECOVERY_COMMITMENT_SCALE_S := _TimingConstants.RECOVERY_COMMITMENT_SCALE_S
const RECOVERY_EXTRA_HIT_S := _TimingConstants.RECOVERY_EXTRA_HIT_S
const RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S := _TimingConstants.RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S
const RECOVERY_EXTRA_DEFLECTED_BASE_S := _TimingConstants.RECOVERY_EXTRA_DEFLECTED_BASE_S
const RECOVERY_DEFLECT_MOMENTUM_SCALE_S := _TimingConstants.RECOVERY_DEFLECT_MOMENTUM_SCALE_S
const RECOVERY_EXTRA_GLANCING_BASE_S := _TimingConstants.RECOVERY_EXTRA_GLANCING_BASE_S
const RECOVERY_GLANCING_SEVERITY_SCALE_S := _TimingConstants.RECOVERY_GLANCING_SEVERITY_SCALE_S
const RECOVERY_EXTRA_MISS_BASE_S := _TimingConstants.RECOVERY_EXTRA_MISS_BASE_S
const RECOVERY_MISS_COMMITMENT_SCALE_S := _TimingConstants.RECOVERY_MISS_COMMITMENT_SCALE_S
const RECOVERY_EXTRA_FULL_STOP_BASE_S := _TimingConstants.RECOVERY_EXTRA_FULL_STOP_BASE_S
const RECOVERY_FULL_STOP_COMMITMENT_SCALE_S := _TimingConstants.RECOVERY_FULL_STOP_COMMITMENT_SCALE_S
const WINDUP_LEG_MIN := _TimingConstants.WINDUP_LEG_MIN
const WIND_UP_DURATION_MAX_S := _TimingConstants.WIND_UP_DURATION_MAX_S
const RECOVERY_AFTER_MEDICAL_S := _TimingConstants.RECOVERY_AFTER_MEDICAL_S
const PACK_WOUND_TIMEOUT_S := 3.0

## Re-export attack data flow dict keys.
const PA_KEY_ATTACK_TYPE := _DictKeys.PA_KEY_ATTACK_TYPE
const PA_KEY_EFFECTIVE_ATTACK_LINE := _DictKeys.PA_KEY_EFFECTIVE_ATTACK_LINE
const PA_KEY_PASSIVE_PARRY_ATTEMPTED := _DictKeys.PA_KEY_PASSIVE_PARRY_ATTEMPTED
const PA_KEY_INTENSITY := _DictKeys.PA_KEY_INTENSITY
const PA_DEFAULT_INTENSITY := _DictKeys.PA_DEFAULT_INTENSITY
const CLASH_KEY_PARRY_CONTROL := _DictKeys.CLASH_KEY_PARRY_CONTROL
const DEFAULT_PARRY_CONTROL := _DictKeys.DEFAULT_PARRY_CONTROL
const INTERPOSE_KEY_ARM := _DictKeys.INTERPOSE_KEY_ARM
const CLASH_KEY_ARM_INTERPOSE := _DictKeys.CLASH_KEY_ARM_INTERPOSE
const RESULT_KEY_DIED := _DictKeys.RESULT_KEY_DIED
const MOVE_DEF_KEY_IS_FEINT := _DictKeys.MOVE_DEF_KEY_IS_FEINT

## Re-export miss/hit/glancing and intensity constants.
const MISS_CHANCE_BASE := _Damage.MISS_CHANCE_BASE
const HIT_CHANCE_PERCEPTION_MIN := _Damage.HIT_CHANCE_PERCEPTION_MIN
const HIT_CHANCE_PERCEPTION_MAX := _Damage.HIT_CHANCE_PERCEPTION_MAX
const GLANCING_DAMAGE_RATIO := _Damage.GLANCING_DAMAGE_RATIO
const PHYSICAL_DAMAGE_ZERO_EPS := _Damage.PHYSICAL_DAMAGE_ZERO_EPS
const INTENSITY_STRENGTH_SCALE := _Damage.INTENSITY_STRENGTH_SCALE
const INTENSITY_STRENGTH_NORM := _Damage.INTENSITY_STRENGTH_NORM
const INTENSITY_STRENGTH_BIAS := _Damage.INTENSITY_STRENGTH_BIAS
const INTENSITY_RANDOM_RANGE := _Damage.INTENSITY_RANDOM_RANGE

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


static func is_medical_move(move_id: String) -> bool:
	return move_id in MEDICAL_MOVE_IDS


static func is_direct_pressure_move(move_id: String) -> bool:
	return move_id == MOVE_ID_APPLY_DIRECT_PRESSURE


static func is_wind_up_medical_move(move_id: String) -> bool:
	return is_medical_move(move_id) and not is_direct_pressure_move(move_id)


const DRESSING_MEDICAL_MOVE_IDS: Array[String] = [
	MOVE_ID_BANDAGE_SELF, MOVE_ID_PACK_WOUND, MOVE_ID_STABILIZE_WOUND
]


static func is_dressing_medical_move(move_id: String) -> bool:
	return move_id in DRESSING_MEDICAL_MOVE_IDS


static func is_tourniquet_move(move_id: String) -> bool:
	return move_id == MOVE_ID_APPLY_TOURNIQUET


static func is_pack_wound_move(move_id: String) -> bool:
	return move_id == MOVE_ID_PACK_WOUND


static func is_stabilize_wound_move(move_id: String) -> bool:
	return move_id == MOVE_ID_STABILIZE_WOUND
## Extra pressure pass from the treater while an ally already holds the wound (bandage/pack/tourniquet wind-up). Scales treater medical effectiveness into `EntityMedical._apply_direct_pressure_to_wounds`.
## Second rescuer adds this fraction of their compression skill on top of primary hold (buddy pressure, TCCC).
const DIRECT_PRESSURE_TREATMENT_ASSIST_EFFECTIVENESS_FRACTION := 0.50
## Additive to treater effectiveness when completing wind-up with `direct_pressure_assist_held_by` set (helper + treater).
const MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS := 0.12
## Wind-up duration divisor when primary holder compresses the part during dressing (buddy system).
const MEDICAL_WINDUP_PRIMARY_HOLDER_DURATION_BONUS := 0.40
## Extra divisor when treater stacks assist on an existing holder during wind-up.
const MEDICAL_WINDUP_STACK_ASSIST_DURATION_BONUS := 0.25
## Ally treating ally: up to this fraction slower from patient thrashing (shock/pain), not full medic shock penalty.
const MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY := 0.18

## Re-export parry constants and functions.
const PARRY_V_FRACTION_OF_MAX_STRIKE := _Parry.PARRY_V_FRACTION_OF_MAX_STRIKE
const PARRY_STRENGTH_NORM := _Parry.PARRY_STRENGTH_NORM
const PARRY_DEFLECT_THRESHOLD := _Parry.PARRY_DEFLECT_THRESHOLD
const PARRY_TECHNIQUE_VARIANCE := _Parry.PARRY_TECHNIQUE_VARIANCE
const PARRY_V_MIN_FRACTION := _Parry.PARRY_V_MIN_FRACTION
const PARRY_V_MIN_NEAR_DEFLECT := _Parry.PARRY_V_MIN_NEAR_DEFLECT
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := _Parry.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S
const PARRY_BLADE_MOVEMENT_S := _Parry.PARRY_BLADE_MOVEMENT_S
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := _Parry.PARRY_MOVEMENT_MASS_STRENGTH_MIN
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := _Parry.PARRY_MOVEMENT_MASS_STRENGTH_MAX
const PERF_MOD_MIN := _Parry.PERF_MOD_MIN
const COMMITMENT_FRACTION := _Parry.COMMITMENT_FRACTION
const COMMITMENT_FRACTION_FEINT := _Parry.COMMITMENT_FRACTION_FEINT
const RECOVERY_READINESS_EARLY := _Parry.RECOVERY_READINESS_EARLY
const RECOVERY_READINESS_LATE := _Parry.RECOVERY_READINESS_LATE
const OFF_BALANCE_DURATION_S := _Parry.OFF_BALANCE_DURATION_S
const OFF_BALANCE_PARRY_CAPACITY_MULT := _Parry.OFF_BALANCE_PARRY_CAPACITY_MULT
const OFF_BALANCE_GAUGE_FILL_MULT := _Parry.OFF_BALANCE_GAUGE_FILL_MULT
const PARRY_BONUS_AFTER_DEFLECT_S := _Parry.PARRY_BONUS_AFTER_DEFLECT_S
const GUARD_AFTER_ATTACK := _Parry.GUARD_AFTER_ATTACK
const GUARD_RISE_RATE := _Parry.GUARD_RISE_RATE
const PARRY_DODGE_STRENGTH_RATIO := _Parry.PARRY_DODGE_STRENGTH_RATIO
const PARRY_BLOCK_MASS_THRESHOLD := _Parry.PARRY_BLOCK_MASS_THRESHOLD
const PARRY_BLOCK_STR_THRESHOLD := _Parry.PARRY_BLOCK_STR_THRESHOLD
const PARRY_REDIRECT_BONUS := _Parry.PARRY_REDIRECT_BONUS
const PARRY_REDIRECT_SKILL_SCALE := _Parry.PARRY_REDIRECT_SKILL_SCALE
const PARRY_REDIRECT_ATTEMPT_RATIO := _Parry.PARRY_REDIRECT_ATTEMPT_RATIO
const PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE := _Parry.PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE
const PARRY_GLANCING_EXPONENT := _Parry.PARRY_GLANCING_EXPONENT
const PARRY_REDIRECT_THRUST_BONUS := _Parry.PARRY_REDIRECT_THRUST_BONUS
const PARRY_REDIRECT_BLUNT_PENALTY := _Parry.PARRY_REDIRECT_BLUNT_PENALTY
const PARRY_CUT_TO_BLUNT_SHIFT := _Parry.PARRY_CUT_TO_BLUNT_SHIFT
const PARRY_PENETRATION_ANGLE_MIN := _Parry.PARRY_PENETRATION_ANGLE_MIN
const PARRY_PENETRATION_ALIGNMENT_SCALE := _Parry.PARRY_PENETRATION_ALIGNMENT_SCALE
const PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD := _Parry.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
const PARRY_BIND_CONTROL_THRESHOLD := _Parry.PARRY_BIND_CONTROL_THRESHOLD
static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool) -> bool:
	return _Parry.parry_full_stop_reached(c_d, parry_p_a, is_block_parry)
static func parry_edge_deflect_reached(
	c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool
) -> bool:
	return _Parry.parry_edge_deflect_reached(c_d, parry_p_a, alignment, is_block_parry)
static func parry_bind_control_reached(parry_control: float) -> bool:
	return _Parry.parry_bind_control_reached(parry_control)
static func iii3_baseline_constants_line() -> String:
	return _Parry.iii3_baseline_constants_line()
static func p4d_parry_bind_doc_sync_line() -> String:
	return _Parry.p4d_parry_bind_doc_sync_line()
const ARCHETYPES_NEVER_BIND: Array[String] = _Parry.ARCHETYPES_NEVER_BIND
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = _Parry.PARRY_BIND_RIPOSTE_BY_PART_CONTACT
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = _Parry.PARRY_BIND_RIPOSTE_MULT_FALLBACK
const PARRY_LATE_CONTROL_FACTOR := _Parry.PARRY_LATE_CONTROL_FACTOR
const PARRY_OFF_BALANCE_CONTROL_FACTOR := _Parry.PARRY_OFF_BALANCE_CONTROL_FACTOR
const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := _AttackPath.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT
const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := _AttackPath.PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST
const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := _AttackPath.PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT
const PARRY_THRUST_CONTROL_MULT := _Parry.PARRY_THRUST_CONTROL_MULT
const DEFLECTED_GUARD_FROM_ATTACK: Dictionary = _AttackPath.DEFLECTED_GUARD_FROM_ATTACK
const LINE_ADJACENTS: Dictionary = _AttackPath.LINE_ADJACENTS
const DODGE_END_GUARD_FROM_ATTACK: Dictionary = _AttackPath.DODGE_END_GUARD_FROM_ATTACK
const PARRY_DESPERATE_DODGE_THRESHOLD := _Parry.PARRY_DESPERATE_DODGE_THRESHOLD
const PARRY_PREFER_DODGE_FULL_THRESHOLD := _Parry.PARRY_PREFER_DODGE_FULL_THRESHOLD
const PARRY_MASS_DISPARITY_BONUS := _Parry.PARRY_MASS_DISPARITY_BONUS
const PARRY_LATE_CAPACITY_FLOOR := _Parry.PARRY_LATE_CAPACITY_FLOOR
const PARRY_CONTACT_MODIFIERS: Dictionary = _Parry.PARRY_CONTACT_MODIFIERS
const PARRY_DEF_VS_ATK_MOD: Dictionary = _Parry.PARRY_DEF_VS_ATK_MOD
const PARRY_INERTIA_BLEND: float = _Parry.PARRY_INERTIA_BLEND
const PARRY_LEVERAGE_LONG_PART_CM: float = _Parry.PARRY_LEVERAGE_LONG_PART_CM
const PARRY_LEVERAGE_FLOOR: float = _Parry.PARRY_LEVERAGE_FLOOR

## Re-export recovery cause readiness curves.
const READINESS_BY_CAUSE: Dictionary = _RecoveryCause.READINESS_BY_CAUSE

## Re-export guard zone and part-to-line mapping.
const GUARD_ZONE_BONUS := _GuardZone.GUARD_ZONE_BONUS
const GUARD_ZONE_UNGUARDED_PENALTY := _GuardZone.GUARD_ZONE_UNGUARDED_PENALTY
const GUARD_DEFAULT := _GuardZone.GUARD_DEFAULT
const PART_TO_LINE: Dictionary = _GuardZone.PART_TO_LINE
const LINE_TO_DEFAULT_PART: Dictionary = _GuardZone.LINE_TO_DEFAULT_PART

## Re-export counter-tempo, riposte chain, and flurry bind constants.
const COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART := _CounterTempo.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART
const COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK := _CounterTempo.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK
const COMBATANT_KEY_COUNTER_WINDOW_UNTIL := _CounterTempo.COMBATANT_KEY_COUNTER_WINDOW_UNTIL
const ACTION_KEY_COUNTER_TEMPO := _CounterTempo.ACTION_KEY_COUNTER_TEMPO
const ACTION_KEY_CLOSE_LIST_HINT := _CounterTempo.ACTION_KEY_CLOSE_LIST_HINT
const PA_KEY_COUNTER_TEMPO := _CounterTempo.PA_KEY_COUNTER_TEMPO
const COUNTER_TEMPO_GAUGE_THRESHOLD := _CounterTempo.COUNTER_TEMPO_GAUGE_THRESHOLD
const COUNTER_TEMPO_GAUGE_COST := _CounterTempo.COUNTER_TEMPO_GAUGE_COST
const COUNTER_TEMPO_WINDOW_FRACTION := _CounterTempo.COUNTER_TEMPO_WINDOW_FRACTION
const COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS := _CounterTempo.COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS
const COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED := _CounterTempo.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED
const COMBATANT_KEY_COUNTER_TEMPO_UI_HINT := _CounterTempo.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT
const COUNTER_TEMPO_WINDUP_MULT := _CounterTempo.COUNTER_TEMPO_WINDUP_MULT
const COUNTER_TEMPO_WINDUP_MAX_S := _CounterTempo.COUNTER_TEMPO_WINDUP_MAX_S
const COUNTER_TEMPO_ACTION_READY_DELAY_S := _CounterTempo.COUNTER_TEMPO_ACTION_READY_DELAY_S
const COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S := _CounterTempo.COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S
const AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT := _CounterTempo.AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT
const AI_COUNTER_TEMPO_INCOMING_TARGET_MULT := _CounterTempo.AI_COUNTER_TEMPO_INCOMING_TARGET_MULT
const AI_COUNTER_TEMPO_FEINT_DAMP_MULT := _CounterTempo.AI_COUNTER_TEMPO_FEINT_DAMP_MULT
const COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL := _CounterTempo.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL
const COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID := _CounterTempo.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID
const PA_KEY_RIPOSTE_CHAIN := _CounterTempo.PA_KEY_RIPOSTE_CHAIN
const RIPOSTE_CHAIN_WINDOW_S := _CounterTempo.RIPOSTE_CHAIN_WINDOW_S
const RIPOSTE_CHAIN_WINDUP_MULT := _CounterTempo.RIPOSTE_CHAIN_WINDUP_MULT
const FLURRY_BIND_WINDOW_S := _CounterTempo.FLURRY_BIND_WINDOW_S
const FLURRY_BIND_MAX_EXCHANGES := _CounterTempo.FLURRY_BIND_MAX_EXCHANGES
const FLURRY_BIND_WIND_UP_MULT := _CounterTempo.FLURRY_BIND_WIND_UP_MULT
const FLURRY_BIND_STAMINA_ATTACK_COST_MULT := _CounterTempo.FLURRY_BIND_STAMINA_ATTACK_COST_MULT

## Re-export mental stack and attention constants.
const COMBATANT_KEY_FOCUS_PART := _MentalStack.COMBATANT_KEY_FOCUS_PART
const COMBATANT_KEY_FOCUS_INTENSITY := _MentalStack.COMBATANT_KEY_FOCUS_INTENSITY
const COMBATANT_KEY_ATTENTION_LOAD := _MentalStack.COMBATANT_KEY_ATTENTION_LOAD
const COMBATANT_KEY_YOMI_BY_ATTACKER := _MentalStack.COMBATANT_KEY_YOMI_BY_ATTACKER
const COMBATANT_KEY_WEAPON_FORM := _MentalStack.COMBATANT_KEY_WEAPON_FORM
const COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL := _MentalStack.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL
const COMBATANT_KEY_LAST_FORM_SWITCH_REASON := _MentalStack.COMBATANT_KEY_LAST_FORM_SWITCH_REASON
const COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID := _MentalStack.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID
const COMBATANT_KEY_ATTENTION_UI_HINT := _MentalStack.COMBATANT_KEY_ATTENTION_UI_HINT
const COMBATANT_KEY_MENTAL_STACK_LAYER := _MentalStack.COMBATANT_KEY_MENTAL_STACK_LAYER
const COMBATANT_KEY_SUSPEND_BLEED_TICK := _MentalStack.COMBATANT_KEY_SUSPEND_BLEED_TICK
const MENTAL_STACK_LAYER_SELF_MEDICAL := _MentalStack.MENTAL_STACK_LAYER_SELF_MEDICAL
const MENTAL_STACK_LAYER_MEDICAL := _MentalStack.MENTAL_STACK_LAYER_MEDICAL
const MENTAL_STACK_LAYER_COUNTER := _MentalStack.MENTAL_STACK_LAYER_COUNTER
const MENTAL_STACK_LAYER_INCOMING := _MentalStack.MENTAL_STACK_LAYER_INCOMING
const MENTAL_STACK_LAYER_HOLD_LINE := _MentalStack.MENTAL_STACK_LAYER_HOLD_LINE
const MENTAL_STACK_LAYER_SPARSE_FIGHT := _MentalStack.MENTAL_STACK_LAYER_SPARSE_FIGHT
const MENTAL_STACK_LAYER_FORMATION_PLUG := _MentalStack.MENTAL_STACK_LAYER_FORMATION_PLUG
const MENTAL_STACK_LAYER_ROUT := _MentalStack.MENTAL_STACK_LAYER_ROUT
const MENTAL_STACK_LAYER_POST_STRIKE := _MentalStack.MENTAL_STACK_LAYER_POST_STRIKE
const COMBATANT_KEY_LAST_STRIKE_TICK := _MentalStack.COMBATANT_KEY_LAST_STRIKE_TICK
const COMBATANT_KEY_LAST_STRIKE_TARGET_ID := _MentalStack.COMBATANT_KEY_LAST_STRIKE_TARGET_ID
const POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE := _MentalStack.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE
const POST_STRIKE_HIT_WEIGHT_BONUS := _MentalStack.POST_STRIKE_HIT_WEIGHT_BONUS
const POST_STRIKE_MOMENTUM_WEIGHT_BONUS := _MentalStack.POST_STRIKE_MOMENTUM_WEIGHT_BONUS
const MENTAL_STACK_LAYER_POSITIONAL_DIS := _MentalStack.MENTAL_STACK_LAYER_POSITIONAL_DIS
const MENTAL_STACK_LAYER_EXHAUSTION := _MentalStack.MENTAL_STACK_LAYER_EXHAUSTION
const MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD := _MentalStack.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
const MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD := _MentalStack.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD
const MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX := _MentalStack.MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX
const FOCUS_INTENSITY_DEFAULT := _MentalStack.FOCUS_INTENSITY_DEFAULT
const ATTENTION_LOAD_TELEGRAPH_WEIGHT := _MentalStack.ATTENTION_LOAD_TELEGRAPH_WEIGHT
const ATTENTION_LOAD_PERIL_WEIGHT := _MentalStack.ATTENTION_LOAD_PERIL_WEIGHT
const ATTENTION_LOAD_COUNTER_WEIGHT := _MentalStack.ATTENTION_LOAD_COUNTER_WEIGHT
const ATTENTION_LOAD_FOCUS_PENALTY := _MentalStack.ATTENTION_LOAD_FOCUS_PENALTY
const FOCUS_WRONG_LINE_READTHROUGH_MULT := _MentalStack.FOCUS_WRONG_LINE_READTHROUGH_MULT
const FOCUS_CORRECT_LINE_READTHROUGH_MULT := _MentalStack.FOCUS_CORRECT_LINE_READTHROUGH_MULT
const YOMI_FEINT_LISTING_MIN_LINE_COUNT := _MentalStack.YOMI_FEINT_LISTING_MIN_LINE_COUNT
const YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT := _MentalStack.YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT
const YOMI_FEINT_LISTING_MULT_CAP := _MentalStack.YOMI_FEINT_LISTING_MULT_CAP
const YOMI_FOCUS_DRIFT_MIN_LINE_COUNT := _MentalStack.YOMI_FOCUS_DRIFT_MIN_LINE_COUNT
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD := _MentalStack.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT := _MentalStack.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT
const YOMI_FOCUS_DRIFT_INTENSITY := _MentalStack.YOMI_FOCUS_DRIFT_INTENSITY
const MEDICAL_AI_WEIGHT_ESCALATION_BONUS := _MentalStack.MEDICAL_AI_WEIGHT_ESCALATION_BONUS

## Re-export feature flag helpers.
static func is_feature_combat_attention_enabled() -> bool:
	return _FeatureFlags.is_feature_combat_attention_enabled()
static func set_feature_combat_attention_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_combat_attention_load(enabled)
static func is_feature_mental_stack_ai_enabled() -> bool:
	return _FeatureFlags.is_feature_mental_stack_ai_enabled()
static func set_feature_mental_stack_ai_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_mental_stack_ai_load(enabled)
static func is_feature_ms_positional_awareness_enabled() -> bool:
	return _FeatureFlags.is_feature_ms_positional_awareness_enabled()
static func set_feature_ms_positional_awareness_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_ms_positional_awareness_load(enabled)
static func is_feature_ms_l6_rout_enabled() -> bool:
	return _FeatureFlags.is_feature_ms_l6_rout_enabled()
static func set_feature_ms_l6_rout_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_ms_l6_rout_load(enabled)
static func is_feature_ms_feint_resistance_enabled() -> bool:
	return _FeatureFlags.is_feature_ms_feint_resistance_enabled()
static func set_feature_ms_feint_resistance_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_ms_feint_resistance_load(enabled)
static func is_feature_ms_mid_infight_med_enabled() -> bool:
	return _FeatureFlags.is_feature_ms_mid_infight_med_enabled()
static func set_feature_ms_mid_infight_med_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_ms_mid_infight_med_load(enabled)
static func is_feature_ms_medical_escalation_enabled() -> bool:
	return _FeatureFlags.is_feature_ms_medical_escalation_enabled()
static func set_feature_ms_medical_escalation_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_ms_medical_escalation_load(enabled)
static func is_feature_ms_post_strike_enabled() -> bool:
	return _FeatureFlags.is_feature_ms_post_strike_enabled()
static func set_feature_ms_post_strike_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_ms_post_strike_load(enabled)
static func is_feature_counter_tempo_enabled() -> bool:
	return _FeatureFlags.is_feature_counter_tempo_enabled()
static func set_feature_counter_tempo_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_counter_tempo_load(enabled)
static func is_feature_flurry_bind_exchange_enabled() -> bool:
	return _FeatureFlags.is_feature_flurry_bind_exchange_enabled()
static func set_feature_flurry_bind_exchange_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_flurry_bind_exchange_load(enabled)
static func is_feature_position_angle_footwork_enabled() -> bool:
	return _FeatureFlags.is_feature_position_angle_footwork_enabled()
static func set_feature_position_angle_footwork_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_position_angle_footwork_load(enabled)
static func is_feature_armor_burden_enabled() -> bool:
	return _FeatureFlags.is_feature_armor_burden_enabled()
static func set_feature_armor_burden_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_armor_burden_load(enabled)
static func armor_burden_mass_ratio_for_combatant(combatant: Dictionary) -> float:
	return _FeatureFlags.armor_burden_mass_ratio_for_combatant(combatant)
static func armor_burden_action_ready_mult(combatant: Dictionary) -> float:
	return _FeatureFlags.armor_burden_action_ready_mult(combatant)
static func armor_burden_passive_readiness_mult(combatant: Dictionary) -> float:
	return _FeatureFlags.armor_burden_passive_readiness_mult(combatant)
static func is_feature_initiative_order_enabled() -> bool:
	return _FeatureFlags.is_feature_initiative_order_enabled()
static func set_feature_initiative_order_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_initiative_order_load(enabled)
static func compare_combatants_for_initiative_order(a: Dictionary, b: Dictionary) -> bool:
	return _FeatureFlags.compare_combatants_for_initiative_order(a, b)
static func is_feature_gap_column_topology_enabled() -> bool:
	return _FeatureFlags.is_feature_gap_column_topology_enabled()
static func set_feature_gap_column_topology_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_gap_column_topology_load(enabled)
static func iv9_gap_column_doc_sync_line() -> String:
	return _FeatureFlags.iv9_gap_column_doc_sync_line()
static func is_feature_subregion_combat_mult_enabled() -> bool:
	return _FeatureFlags.is_feature_subregion_combat_mult_enabled()
static func set_feature_subregion_combat_mult_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_subregion_combat_mult_load(enabled)
static func is_feature_leader_formation_command_enabled() -> bool:
	return _FeatureFlags.is_feature_leader_formation_command_enabled()
static func set_feature_leader_formation_command_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_leader_formation_command_load(enabled)
static func iv11_leader_formation_doc_sync_line() -> String:
	return _FeatureFlags.iv11_leader_formation_doc_sync_line()
static func is_feature_iv12_slot_distraction_enabled() -> bool:
	return _FeatureFlags.is_feature_iv12_slot_distraction_enabled()
static func set_feature_iv12_slot_distraction_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_iv12_slot_distraction_load(enabled)
static func iv12_slot_distraction_doc_sync_line() -> String:
	return _FeatureFlags.iv12_slot_distraction_doc_sync_line()
static func is_feature_iv13_weapon_reach_zoc_enabled() -> bool:
	return _FeatureFlags.is_feature_iv13_weapon_reach_zoc_enabled()
static func set_feature_iv13_weapon_reach_zoc_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_iv13_weapon_reach_zoc_load(enabled)
static func iv13_weapon_reach_zoc_doc_sync_line() -> String:
	return _FeatureFlags.iv13_weapon_reach_zoc_doc_sync_line()
static func is_feature_t44_spatial_band_pa_enabled() -> bool:
	return _FeatureFlags.is_feature_t44_spatial_band_pa_enabled()
static func set_feature_t44_spatial_band_pa_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_t44_spatial_band_pa_load(enabled)
static func t44_spatial_band_pa_magnitude_mult(band: String) -> float:
	return _FeatureFlags.t44_spatial_band_pa_magnitude_mult(band)
static func is_feature_t44_spatial_file_dodge_bias_enabled() -> bool:
	return _FeatureFlags.is_feature_t44_spatial_file_dodge_bias_enabled()
static func set_feature_t44_spatial_file_dodge_bias_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_t44_spatial_file_dodge_bias_load(enabled)
static func t44_spatial_file_dodge_wing_mult(file_index: int, formation_files: int) -> float:
	return _FeatureFlags.t44_spatial_file_dodge_wing_mult(file_index, formation_files)
static func is_feature_t44_spatial_flurry_pa_enabled() -> bool:
	return _FeatureFlags.is_feature_t44_spatial_flurry_pa_enabled()
static func set_feature_t44_spatial_flurry_pa_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_t44_spatial_flurry_pa_load(enabled)
static func t44_spatial_band_pa_doc_sync_line() -> String:
	return _FeatureFlags.t44_spatial_band_pa_doc_sync_line()
static func t44_spatial_file_dodge_doc_sync_line() -> String:
	return _FeatureFlags.t44_spatial_file_dodge_doc_sync_line()
static func t44_spatial_flurry_pa_doc_sync_line() -> String:
	return _FeatureFlags.t44_spatial_flurry_pa_doc_sync_line()
static func is_feature_hema_eight_guard_lines_enabled() -> bool:
	return _FeatureFlags.is_feature_hema_eight_guard_lines_enabled()
static func set_feature_hema_eight_guard_lines_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_hema_eight_guard_lines_load(enabled)
static func is_feature_arm_interpose_enabled() -> bool:
	return _FeatureFlags.is_feature_arm_interpose_enabled()
static func set_feature_arm_interpose_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_arm_interpose_load(enabled)
static func is_feature_iv6_attack_path_octant_enabled() -> bool:
	return _FeatureFlags.is_feature_iv6_attack_path_octant_enabled()
static func set_feature_iv6_attack_path_octant_load(enabled: bool) -> void:
	_FeatureFlags.set_feature_iv6_attack_path_octant_load(enabled)
static func is_feature_sector_surround_load() -> bool:
	return _FeatureFlags.is_feature_sector_surround_load()
static func set_feature_sector_surround_load(on: bool) -> void:
	_FeatureFlags.set_feature_sector_surround_load(on)
static func is_feature_surround_arc_occupancy_enabled() -> bool:
	return _FeatureFlags.is_feature_surround_arc_occupancy_enabled()
static func reset_harness_feature_load_overrides() -> void:
	_FeatureFlags.reset_harness_feature_load_overrides()

static func is_focus_line_move(move_id: String) -> bool:
	return move_id in FOCUS_LINE_MOVE_IDS


static func position_angle_offset_deg_for_attack_line(line: String) -> float:
	var k: String = line.strip_edges()
	if is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.position_angle_offset_deg_for_line(k)
	return POSITION_ANGLE_OFFSET_DEG_BY_LINE.get(k, 0.0)


static func guard_line_for_focus_move_id(move_id: String) -> String:
	match move_id:
		MOVE_ID_FOCUS_HIGH:
			return "high"
		MOVE_ID_FOCUS_LOW:
			return "low"
		MOVE_ID_FOCUS_LEFT:
			return "left"
		MOVE_ID_FOCUS_RIGHT:
			return "right"
		_:
			return ""


## Re-export feint constants.
const FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD := _Parry.FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD
const FEINT_PRE_REVEAL_READINESS_MULT := _Parry.FEINT_PRE_REVEAL_READINESS_MULT
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS := _Parry.FEINT_TELEGRAPH_DODGE_EVAL_BIAS
const PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS := _Parry.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE := _Parry.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG := _Parry.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG

## Re-export guard line alignment values (from AttackPath).
const PARRY_ALIGNMENT_FLOOR := _AttackPath.PARRY_ALIGNMENT_FLOOR
const GEOMETRIC_LEAK_MAX := _AttackPath.GEOMETRIC_LEAK_MAX
const PARRY_GEOMETRY_VARIANCE_BASE := _AttackPath.PARRY_GEOMETRY_VARIANCE_BASE

## Re-export attack path helpers.
static func _iv6_diagonal_attack_path(flank_path: Array, vert_path: Array, guard_oct: String, zone_part: String) -> Array:
	return _AttackPath._iv6_diagonal_attack_path(flank_path, vert_path, guard_oct, zone_part)

## Re-export guard transition constants.
const GUARD_TRANSITION_COST_SCALE := _Parry.GUARD_TRANSITION_COST_SCALE
const GUARD_TRANSITION_MULT_MAX := _Parry.GUARD_TRANSITION_MULT_MAX
const PREFERRED_PART_BONUS_MULT := _Parry.PREFERRED_PART_BONUS_MULT
const AI_PICK_OFF_FOCUS_PART_MULT := _Parry.AI_PICK_OFF_FOCUS_PART_MULT
const AI_PICK_ON_FOCUS_LINE_PENALTY_MULT := _Parry.AI_PICK_ON_FOCUS_LINE_PENALTY_MULT
const AI_PICK_NOVICE_ON_FOCUS_LINE_PENALTY_MULT := _Parry.AI_PICK_NOVICE_ON_FOCUS_LINE_PENALTY_MULT
const AI_PICK_YOMI_HABIT_LINE_PART_MULT := _Parry.AI_PICK_YOMI_HABIT_LINE_PART_MULT
const AI_PICK_YOMI_COUNTER_LINE_PART_MULT := _Parry.AI_PICK_YOMI_COUNTER_LINE_PART_MULT
const AI_PICK_STAT_BASELINE := _Parry.AI_PICK_STAT_BASELINE
const AI_PICK_STAT_SPREAD := _Parry.AI_PICK_STAT_SPREAD
const AI_PICK_NOVICE_OFF_FOCUS_MULT := _Parry.AI_PICK_NOVICE_OFF_FOCUS_MULT
const AI_PICK_NOVICE_YOMI_HABIT_MULT := _Parry.AI_PICK_NOVICE_YOMI_HABIT_MULT
const AI_PICK_NOVICE_YOMI_COUNTER_MULT := _Parry.AI_PICK_NOVICE_YOMI_COUNTER_MULT
const AI_PICK_NOVICE_PREFERRED_MULT := _Parry.AI_PICK_NOVICE_PREFERRED_MULT

## Re-export debug and logging constants.
const COMBAT_DEV_VERBOSE := _Debug.COMBAT_DEV_VERBOSE
const COMBAT_DEBUG := _Debug.COMBAT_DEBUG
const COMBAT_DEBUG_CALIBRATION := _Debug.COMBAT_DEBUG_CALIBRATION
const COMBAT_EVENT_DEBUG := _Debug.COMBAT_EVENT_DEBUG
const COMBAT_EVENT_DEBUG_VERBOSE := _Debug.COMBAT_EVENT_DEBUG_VERBOSE
const COMBAT_FLOW_LOG_SUPPRESS_REPEATED := _Debug.COMBAT_FLOW_LOG_SUPPRESS_REPEATED
const COMBAT_VACANCY_RECONCILE_DIRTY_ONLY := _Debug.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY
const COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES := _Debug.COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES
const COMBAT_FORMATION_INVARIANT_DEBUG := _Debug.COMBAT_FORMATION_INVARIANT_DEBUG
static func set_headless_harness_quiet(on: bool) -> void:
	_Debug.set_headless_harness_quiet(on)
static func is_headless_harness_quiet() -> bool:
	return _Debug.is_headless_harness_quiet()
static func set_play_session_diagnostic(on: bool) -> void:
	_Debug.set_play_session_diagnostic(on)
static func play_session_diagnostic_active() -> bool:
	return _Debug.play_session_diagnostic_active()
static func set_combat_hit_summary_override(on: bool) -> void:
	_Debug.set_combat_hit_summary_override(on)
static func clear_combat_hit_summary_override() -> void:
	_Debug.clear_combat_hit_summary_override()
static func combat_hit_summary_active() -> bool:
	return _Debug.combat_hit_summary_active()
static func set_combat_dev_verbose_override(on: bool) -> void:
	_Debug.set_combat_dev_verbose_override(on)
static func clear_combat_dev_verbose_override() -> void:
	_Debug.clear_combat_dev_verbose_override()
static func combat_dev_verbose_active() -> bool:
	return _Debug.combat_dev_verbose_active()
static func combat_debug_active() -> bool:
	return _Debug.combat_debug_active()
static func combat_event_debug_active() -> bool:
	return _Debug.combat_event_debug_active()
static func combat_event_debug_verbose_active() -> bool:
	return _Debug.combat_event_debug_verbose_active()

# Stamina (separate pool): attack/parry consume; refill when idle.
# Realism target: stamina shapes execution quality without dominating combat length.
## Re-export stamina constants and helpers from **`CombatConstantsStamina`**.
## Maintain canonical values in the sub-module, not here.
const STAMINA_MAX := _Stamina.STAMINA_MAX
const STAMINA_REFILL_RATE := _Stamina.STAMINA_REFILL_RATE
const STAMINA_ATTACK_COST_BASE := _Stamina.STAMINA_ATTACK_COST_BASE
const STAMINA_ATTACK_COST_SCALE := _Stamina.STAMINA_ATTACK_COST_SCALE
const STAMINA_PARRY_COST := _Stamina.STAMINA_PARRY_COST
const STAMINA_PARRY_COST_BASE := _Stamina.STAMINA_PARRY_COST_BASE
const STAMINA_PARRY_COST_SCALE := _Stamina.STAMINA_PARRY_COST_SCALE
const STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT := _Stamina.STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT
const PARRY_BIND_RIPOSTE_GAUGE_BONUS := _Stamina.PARRY_BIND_RIPOSTE_GAUGE_BONUS
const STAMINA_AT_ZERO_PARRY_MULT := _Stamina.STAMINA_AT_ZERO_PARRY_MULT
const STAMINA_AT_ZERO_DAMAGE_MULT := _Stamina.STAMINA_AT_ZERO_DAMAGE_MULT
const STAMINA_FACTOR_POWER := _Stamina.STAMINA_FACTOR_POWER
const STAMINA_EXHAUSTION_MAX_MULT_FLOOR := _Stamina.STAMINA_EXHAUSTION_MAX_MULT_FLOOR
const STAMINA_BLOOD_MAX_MULT_FLOOR := _Stamina.STAMINA_BLOOD_MAX_MULT_FLOOR
const STAMINA_REFILL_EXHAUSTION_MULT_FLOOR := _Stamina.STAMINA_REFILL_EXHAUSTION_MULT_FLOOR
const EXHAUSTION_OFFENSE_DAMP_START := _Stamina.EXHAUSTION_OFFENSE_DAMP_START
const EXHAUSTION_OFFENSE_DAMP_FLOOR := _Stamina.EXHAUSTION_OFFENSE_DAMP_FLOOR
## Re-export exhaustion keys --" used by CombatManager.init and harness fixtures.
const COMBATANT_KEY_EXHAUSTION := _Stamina.COMBATANT_KEY_EXHAUSTION
const COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED := _Stamina.COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED
const EXHAUSTION_MAX := _Stamina.EXHAUSTION_MAX
const EXHAUSTION_EXERTION_PER_STAMINA_POINT := _Stamina.EXHAUSTION_EXERTION_PER_STAMINA_POINT
const EXHAUSTION_ENDURANCE_MAX_RELIEF := _Stamina.EXHAUSTION_ENDURANCE_MAX_RELIEF
const EXHAUSTION_RECOVERY_RATE := _Stamina.EXHAUSTION_RECOVERY_RATE
const EXHAUSTION_CURVE := _Stamina.EXHAUSTION_CURVE
const EXHAUSTION_FLOOR_MULT := _Stamina.EXHAUSTION_FLOOR_MULT
const EXHAUSTION_UI_SHOW_THRESHOLD := _Stamina.EXHAUSTION_UI_SHOW_THRESHOLD
const EXHAUSTION_GAIN_BLOOD_LOSS_MULT := _Stamina.EXHAUSTION_GAIN_BLOOD_LOSS_MULT
const EXHAUSTION_GAIN_PAIN_SHOCK_MULT := _Stamina.EXHAUSTION_GAIN_PAIN_SHOCK_MULT
const FEATURE_FIGHT_EXHAUSTION_INDEX := _FeatureFlags.FEATURE_FIGHT_EXHAUSTION_INDEX


static func stamina_factor(ratio: float) -> float:
	return _Stamina.stamina_factor(ratio)


static func stamina_attack_cost_from_intensity(intensity: float) -> float:
	return _Stamina.stamina_attack_cost_from_intensity(intensity)


static func stamina_parry_cost_from_intensity(intensity: float) -> float:
	return _Stamina.stamina_parry_cost_from_intensity(intensity)


static func action_ready_stamina_delay_mult(stamina_ratio: float) -> float:
	return _Stamina.action_ready_stamina_delay_mult(stamina_ratio)


static func is_feature_fight_exhaustion_enabled() -> bool:
	return _FeatureFlags.is_feature_fight_exhaustion_enabled()


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
	_FeatureFlags.set_feature_fight_exhaustion_index_load(on)


static func exhaustion_performance_mult(exhaustion: float) -> float:
	return _Stamina.exhaustion_performance_mult(exhaustion)


static func defender_passive_readiness_exhaustion_mult(combatant: Dictionary) -> float:
	return _Stamina.defender_passive_readiness_exhaustion_mult(combatant)


static func apply_parry_bind_riposte_gauge_bonus(defender: Dictionary) -> void:
	_Stamina.apply_parry_bind_riposte_gauge_bonus(defender)


static func defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio: float) -> float:
	return _Stamina.defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio)


## Re-export parry redirect and helper functions.
static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
	return _Parry.commitment_fraction_for_pending_attack(pa)
static func stats_factor_agi_perc(agi: float, perc: float) -> float:
	return _Parry.stats_factor_agi_perc(agi, perc)
static func glancing_factor(ratio: float, exponent: float = PARRY_GLANCING_EXPONENT) -> float:
	return _Parry.glancing_factor(ratio, exponent)
static func compute_parry_redirect_mult(pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float) -> float:
	return _Parry.compute_parry_redirect_mult(pcfg, agi, perc, contact_type, is_block_parry, m_a, m_d)
static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
	return _Parry.parry_deflect_margin_ratio(c_d_final, parry_p_a)
static func parry_deflect_severity_from_margin_ratio(margin_ratio: float) -> float:
	return _Parry.parry_deflect_severity_from_margin_ratio(margin_ratio)
static func parry_control_for_bind_deflect(
	c_d_final: float,
	parry_p_a: float,
	alignment: float,
	parry_readiness: float,
	parry_off_balance: bool,
	late_parry: bool,
	contact_type: String
) -> float:
	return _Parry.parry_control_for_bind_deflect(c_d_final, parry_p_a, alignment, parry_readiness, parry_off_balance, late_parry, contact_type)

## Re-export event queue constants.
const EVENT_ACTION_READY := _EventQueue.EVENT_ACTION_READY
const EVENT_MELEE_ATTACK := _EventQueue.EVENT_MELEE_ATTACK
const EVENT_RECOVERY_END := _EventQueue.EVENT_RECOVERY_END
const EVENT_SWAP_RANK_RESOLVE := _EventQueue.EVENT_SWAP_RANK_RESOLVE
const EVENT_FALL_BACK_SOLO_RESOLVE := _EventQueue.EVENT_FALL_BACK_SOLO_RESOLVE
const EVENT_ROTATE_FILE_RESOLVE := _EventQueue.EVENT_ROTATE_FILE_RESOLVE
const EVENT_PLUG_FORWARD_RESOLVE := _EventQueue.EVENT_PLUG_FORWARD_RESOLVE
const COOLDOWN_ACTION_READY_BASE := _EventQueue.COOLDOWN_ACTION_READY_BASE
const READY_DELAY_SKIP_DEFAULT_S := _EventQueue.READY_DELAY_SKIP_DEFAULT_S
const READY_DELAY_SKIP_BACK_RANK_S := _EventQueue.READY_DELAY_SKIP_BACK_RANK_S
const READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S := _EventQueue.READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S
const READY_DELAY_FORMATION_RECHECK_S := _EventQueue.READY_DELAY_FORMATION_RECHECK_S
const READY_DELAY_AFTER_PROMOTION_S := _EventQueue.READY_DELAY_AFTER_PROMOTION_S
const READY_DELAY_PARRY_RIPOSTE_S := _EventQueue.READY_DELAY_PARRY_RIPOSTE_S
const READY_DELAY_CLOSE_ATTEMPT_S := _EventQueue.READY_DELAY_CLOSE_ATTEMPT_S

# FF4 Formation + Stance (Phase 0 prep). See docs/LIVE_PATHS.md tier 0--"1.
const SPACING_TIGHT := 0.9
const SPACING_NORMAL := 1.2
const SPACING_LOOSE := 1.8
const REACH_SAFETY_FACTOR := 0.8
const FLANK_PARRY_MOD := 0.8
const REAR_PARRY_MOD := 0.7
## Pack / protection-circle fallback: flank parry mod when `effective_pair_file_spacing_equivalent` --''deg'' this (Tier 3.1 --" wedge/lane-aware; matches integer |f"file|--''deg''2 at default spacing).
const PARRY_FLANK_EFFECTIVE_FILES_MIN := 2.0
## Abstract strike **measure**: `melee_range / max(effective_pair_eff_dist, floor)` then clamp (Tier 3.1 --" `CombatStrikeStamping.strike_measure_ratio_*`, `StrikeRealismProfile.measure_ratio`).
const STRIKE_MEASURE_EFF_DIST_FLOOR := 0.2
const STRIKE_MEASURE_RATIO_MIN := 0.75
const STRIKE_MEASURE_RATIO_MAX := 1.12
# Phase 4: ZoC --" zone control thresholds and cross-zone support (tune in playtests).
const ZOC_ACCESS_THRESHOLD := 0.55
const ZOC_FRONT_SUPPORT_TO_FLANK := 0.35
const ZOC_FLANK_SUPPORT_TO_FRONT := 0.25
const ZOC_REAR_SUPPORT_FROM_FRONT := 0.2
const ZOC_CASUALTY_PER_BODY := 0.12
## Phase 6: Incursion pressure (front-rank imbalance) reduces raw zone strength before cross-zone blend.
const ZOC_INCURSION_ZONE_PENALTY := 0.38
## Lane stress fills only headroom above global incursion (same 0..INCURSION_PRESSURE_MAX scale) --" avoids double-counting with global rank-delta.
const INCURSION_LANE_HEADROOM_FACTOR := 0.88
## Local lane stress 0..1 from formation (dual living in a cell, density). Not slot_obstacles --" those stay in ZOC_CASUALTY_PER_BODY only.
const LANE_STRESS_DUAL_LIVING := 0.42
const LANE_STRESS_DENSITY_TIGHT := 0.12
const LANE_STRESS_DENSITY_LOOSE := -0.07
## --- Tier 1.3 P4 freeze: `lane_stress_by_file` + `lane_offset` ---
## **`lane_stress_by_file`**: per-formation file --'' ' 0..1 stress from dual occupancy + density (`TacticalCombat._recompute_lane_stress_by_file`).
## **`lane_offset`**: per-combatant float; **lateral offset within the nominal file column** feeding `CombatPairGeometry.effective_pair_eff_dist` (`EFF_DIST_LANE_OFFSET_FILE_EQUIV`). **Range:** clamp every writer/read to **`[-LANE_OFFSET_ABS_MAX, LANE_OFFSET_ABS_MAX]`** (currently **[-0.5, 0.5]**). **0** = column center. **Sign:** **positive** = toward **increasing file index** (+file / --..."enemy-right--'? on default symmetric grids). `CombatFormationFlow.repack_lane_offset_after_rank_file_change` + `CombatManager.register` defaults must stay inside this interval.
## Vacancy reconcile: lateral slides can open a hole in a neighbor file; repeat until stable (safety cap).
const FORMATION_VACANCY_RECONCILE_MAX_ROUNDS := 16
## Inner promotion chain per file per vacancy/death plug pass (one rank step + restart shallow scan per iteration).
const FORMATION_VACANCY_MICRO_STEPS_MAX := 24
## After an automatic vacancy/death plug moves a unit, that unit cannot be chosen as a plug donor again until this many seconds of `combat_clock` elapse (damps tick-by-tick lateral / chain thrash; abstract, not a long --..."realistic--'? delay).
const FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S := 0.35
## Vacancy **lateral** slide: block immediately sliding back (hole reopens in donor file) across ticks. Pass-local meta alone cannot stop this because reconcile runs every frame + get_available_actions.
const FORMATION_VACANCY_LATERAL_REVERSE_LOCK_S := 1.2
## Plug priority: `pow(effectiveness_0_1, EXPONENT) * 1/(1 + PROXIMITY_WEIGHT * step_count)`. Higher EXPONENT makes injured fighters fall off nonlinearly so fitter units in other lanes/ranks can win despite extra steps.
const FORMATION_PLUG_EFFECTIVENESS_EXPONENT := 2.6
## Larger = proximity matters less relative to effectiveness (able-bodied farther can override closer wounded).
const FORMATION_PLUG_PROXIMITY_WEIGHT := 0.28
## When false (default), per-move Vacancy plug / death Plug `[Combat]` lines are suppressed; keeps logs usable with `COMBAT_EVENT_DEBUG` on.
const COMBAT_FORMATION_PLUG_MOVE_DEBUG := false
## When true, logs vacancy promotions and rank-0 holes still empty after reconcile (independent of `COMBAT_EVENT_DEBUG`).
const COMBAT_FORMATION_VACANCY_DEBUG := false
## Extra priority score for filling **rank 0** holes so the front line closes before lateral shuffles when scores tie.
const FORMATION_PLUG_RANK0_URGENCY_BONUS := 0.75
## Added to `READY_DELAY_AFTER_PROMOTION_S` per file of horizontal travel when a **rear** rank plugs a rank-0 hole from another file (reserves sidestep before stepping up; front rank no longer shuffles sideways first).
const FORMATION_PLUG_REAR_CROSS_FILE_READY_PER_FILE_S := 0.18
## Per-combatant lateral metric --" see **Tier 1.3 P4 freeze** block above (f''Sec4.2).
const LANE_OFFSET_DEFAULT := 0.0
const LANE_OFFSET_ABS_MAX := 0.5
## effective_pair_eff_dist: |f"lane_offset| as fraction of a file spacing equivalent before ZoC mult.
const EFF_DIST_LANE_OFFSET_FILE_EQUIV := 0.42
## `CombatDistanceBands`: MID vs LONG uses `effective_pair_file_spacing_equivalent` vs `mid_reach_files`; slack avoids float edge flicker with lane_offset.
const DIST_BAND_MID_FILE_EQUIV_SLACK := 0.38
## How strongly incursion penalty applies per zone (rear echelon less exposed to --..."line buckling--'? than front).
const ZOC_INCURSION_EXPOSURE_FRONT := 1.0
const ZOC_INCURSION_EXPOSURE_FLANK := 0.9
const ZOC_INCURSION_EXPOSURE_REAR := 0.36
## Weak front ZoC (both lines) scales geometric pair distance down --" lines feel closer, easier to bridge.
const ZOC_GEOMETRIC_EXTENT_MIN := 0.78
## Getting hit during formation move: below cancel threshold extends duration; at/above cancels the move.
const FORMATION_HIT_REACTION_EXTRA_S := 0.38
const FORMATION_HIT_CANCEL_INTENSITY := 0.72



const FEATURE_INCOMING_PARRY_CHOICE := _ParryChoice.FEATURE_INCOMING_PARRY_CHOICE
const INCOMING_MELEE_PARRY_WINDOW_S := _ParryChoice.INCOMING_MELEE_PARRY_WINDOW_S
const INCOMING_PARRY_ALL_COMBINED_P_A_BUDGET_MULT := _ParryChoice.INCOMING_PARRY_ALL_COMBINED_P_A_BUDGET_MULT
## Re-export parry telegraph and weapon extension constants from CombatConstantsParryChoice.
const PARRY_TELEGRAPH_CONTACT_MULT_CUT := _ParryChoice.PARRY_TELEGRAPH_CONTACT_MULT_CUT
const PARRY_TELEGRAPH_CONTACT_MULT_STAB := _ParryChoice.PARRY_TELEGRAPH_CONTACT_MULT_STAB
const PARRY_TELEGRAPH_CONTACT_MULT_BLUNT := _ParryChoice.PARRY_TELEGRAPH_CONTACT_MULT_BLUNT
const PARRY_TELEGRAPH_FEINT_APPARENT_MULT := _ParryChoice.PARRY_TELEGRAPH_FEINT_APPARENT_MULT
const PARRY_TELEGRAPH_PERCEPTION_READ_BONUS := _ParryChoice.PARRY_TELEGRAPH_PERCEPTION_READ_BONUS
static func parry_telegraph_contact_mult(contact_type: String) -> float:
	return _ParryChoice.parry_telegraph_contact_mult(contact_type)
const WEAPON_EXTENDED_PARRY_MULT := _ParryChoice.WEAPON_EXTENDED_PARRY_MULT
const WEAPON_COMMITTED_ATTACK_PARRY_C_D_MULT := _ParryChoice.WEAPON_COMMITTED_ATTACK_PARRY_C_D_MULT
const WEAPON_EXTENDED_COMMIT_FRACTION := _ParryChoice.WEAPON_EXTENDED_COMMIT_FRACTION
const WEAPON_COMMIT_FRACTION_STAB := _ParryChoice.WEAPON_COMMIT_FRACTION_STAB
const WEAPON_COMMIT_FRACTION_CUT := _ParryChoice.WEAPON_COMMIT_FRACTION_CUT
const WEAPON_COMMIT_FRACTION_OVERHEAD := _ParryChoice.WEAPON_COMMIT_FRACTION_OVERHEAD
const WEAPON_COMMIT_FRACTION_BLUNT := _ParryChoice.WEAPON_COMMIT_FRACTION_BLUNT
const WEAPON_COMMIT_FRACTION_QUICK := _ParryChoice.WEAPON_COMMIT_FRACTION_QUICK

## Re-export feature flag constants and helpers from CombatConstantsFeatureFlags.
## Maintain canonical values in the sub-module.
const FEATURE_AMBIENT_PAIN_SHOCK := _FeatureFlags.FEATURE_AMBIENT_PAIN_SHOCK
const FEATURE_ARMOR_BURDEN := _FeatureFlags.FEATURE_ARMOR_BURDEN
const FORMATION_ARMOR_MASS_REF_KG := _FeatureFlags.FORMATION_ARMOR_MASS_REF_KG
const FORMATION_ARMOR_MAX_SLOW_MULT := _FeatureFlags.FORMATION_ARMOR_MAX_SLOW_MULT
const INITIATIVE_ORDER_STAGGER_STEP_S := _FeatureFlags.INITIATIVE_ORDER_STAGGER_STEP_S
const FEATURE_INITIATIVE_ORDER := _FeatureFlags.FEATURE_INITIATIVE_ORDER
const FEATURE_GAP_COLUMN_TOPOLOGY := _FeatureFlags.FEATURE_GAP_COLUMN_TOPOLOGY
const FEATURE_SUBREGION_COMBAT_MULT := _FeatureFlags.FEATURE_SUBREGION_COMBAT_MULT
const FEATURE_LEADER_FORMATION_COMMAND := _FeatureFlags.FEATURE_LEADER_FORMATION_COMMAND
const AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT := _FeatureFlags.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
const AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT := _FeatureFlags.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
const AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT := _FeatureFlags.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
const AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT := _FeatureFlags.AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT
const FEATURE_MS_MID_INFIGHT_MED := _FeatureFlags.FEATURE_MS_MID_INFIGHT_MED
const FEATURE_FLURRY_BIND_EXCHANGE := _FeatureFlags.FEATURE_FLURRY_BIND_EXCHANGE
const FEATURE_IV12_SLOT_DISTRACTION := _FeatureFlags.FEATURE_IV12_SLOT_DISTRACTION
const IV12_SLOT_DISTRACTION_WEIGHT_PAD := _FeatureFlags.IV12_SLOT_DISTRACTION_WEIGHT_PAD
const IV12_AI_OFFENSE_WEIGHT_MULT := _FeatureFlags.IV12_AI_OFFENSE_WEIGHT_MULT
const IV12_AI_COLOCATED_TARGET_BIAS_MULT := _FeatureFlags.IV12_AI_COLOCATED_TARGET_BIAS_MULT
const FEATURE_IV13_WEAPON_REACH_ZOC := _FeatureFlags.FEATURE_IV13_WEAPON_REACH_ZOC
const IV13_WEAPON_REACH_ZOC_REF_M := _FeatureFlags.IV13_WEAPON_REACH_ZOC_REF_M
const IV13_WEAPON_REACH_ZOC_SPAN_M := _FeatureFlags.IV13_WEAPON_REACH_ZOC_SPAN_M
const IV13_WEAPON_REACH_ZOC_MAX_BONUS_M := _FeatureFlags.IV13_WEAPON_REACH_ZOC_MAX_BONUS_M
const IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX := _FeatureFlags.IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX
const FEATURE_T44_SPATIAL_BAND_PA := _FeatureFlags.FEATURE_T44_SPATIAL_BAND_PA
const FEATURE_T44_SPATIAL_FILE_DODGE_BIAS := _FeatureFlags.FEATURE_T44_SPATIAL_FILE_DODGE_BIAS
const FEATURE_T44_SPATIAL_FLURRY_PA := _FeatureFlags.FEATURE_T44_SPATIAL_FLURRY_PA
const T44_SPATIAL_FLURRY_PA_MULT := _FeatureFlags.T44_SPATIAL_FLURRY_PA_MULT
const T44_SPATIAL_BAND_PA_MULT_CLOSE := _FeatureFlags.T44_SPATIAL_BAND_PA_MULT_CLOSE
const T44_SPATIAL_BAND_PA_MULT_LONG := _FeatureFlags.T44_SPATIAL_BAND_PA_MULT_LONG
const T44_SPATIAL_FILE_DODGE_WING_MULT := _FeatureFlags.T44_SPATIAL_FILE_DODGE_WING_MULT
static func is_feature_ambient_pain_shock() -> bool:
	return _FeatureFlags.is_feature_ambient_pain_shock()
static func set_feature_ambient_pain_shock(on: bool) -> void:
	_FeatureFlags.set_feature_ambient_pain_shock(on)
## Re-export formation move constants and helpers from CombatConstantsFormationMove.
const SURROUND_MAX_SPLIT_DIVISOR := _FormationMove.SURROUND_MAX_SPLIT_DIVISOR
const SURROUND_AWARENESS_AT_LOW_PERCEPTION := _FormationMove.SURROUND_AWARENESS_AT_LOW_PERCEPTION
const INCURSION_PRESSURE_PER_RANK_ADVANTAGE := _FormationMove.INCURSION_PRESSURE_PER_RANK_ADVANTAGE
const INCURSION_PRESSURE_MAX := _FormationMove.INCURSION_PRESSURE_MAX
const STANCE_DEFENSIVE := _FormationMove.STANCE_DEFENSIVE
const STANCE_BALANCED := _FormationMove.STANCE_BALANCED
const STANCE_AGGRESSIVE := _FormationMove.STANCE_AGGRESSIVE
const STANCE_CONTROLLING := _FormationMove.STANCE_CONTROLLING
const STANCE_MIN_STAMINA_AGGRESSIVE_RATIO := _FormationMove.STANCE_MIN_STAMINA_AGGRESSIVE_RATIO
const STANCE_MIN_STAMINA_CONTROLLING_RATIO := _FormationMove.STANCE_MIN_STAMINA_CONTROLLING_RATIO
const OPPONENT_PRESSURE_DEFENSIVE_STAMINA_RATIO := _FormationMove.OPPONENT_PRESSURE_DEFENSIVE_STAMINA_RATIO
const BASE_FALL_BACK_S := _FormationMove.BASE_FALL_BACK_S
const LANE_MOD_CLEAR := _FormationMove.LANE_MOD_CLEAR
const LANE_MOD_CROWDED := _FormationMove.LANE_MOD_CROWDED
const LANE_MOD_BLOCKED := _FormationMove.LANE_MOD_BLOCKED
const AI_FORMATION_MOVE_BLOCKED_LANE_MULT := _FormationMove.AI_FORMATION_MOVE_BLOCKED_LANE_MULT
const PRESSURE_MOD_DEFENSIVE := _FormationMove.PRESSURE_MOD_DEFENSIVE
const PRESSURE_MOD_NEUTRAL := _FormationMove.PRESSURE_MOD_NEUTRAL
const PRESSURE_MOD_AGGRESSIVE := _FormationMove.PRESSURE_MOD_AGGRESSIVE
const FOOTING_STEP_OVER_MIN := _FormationMove.FOOTING_STEP_OVER_MIN
const FOOTING_STEP_OVER_MAX := _FormationMove.FOOTING_STEP_OVER_MAX
const DRAG_BACK_DURATION_MULT := _FormationMove.DRAG_BACK_DURATION_MULT
const FORMATION_PAIR_ABORT_RETRY_COOLDOWN_S := _FormationMove.FORMATION_PAIR_ABORT_RETRY_COOLDOWN_S
const FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S := _FormationMove.FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S
const FORMATION_ROTATE_FILE_REVERSE_PAIR_LOCK_S := _FormationMove.FORMATION_ROTATE_FILE_REVERSE_PAIR_LOCK_S
const STATE_FALLING_BACK := _FormationMove.STATE_FALLING_BACK
const STATE_SWAP_RANK := _FormationMove.STATE_SWAP_RANK
const STATE_PLUG_FORWARD := _FormationMove.STATE_PLUG_FORWARD
const MOVE_ID_SWAP_RANK := _FormationMove.MOVE_ID_SWAP_RANK
const MOVE_ID_DRAG_BACK := _FormationMove.MOVE_ID_DRAG_BACK
const MOVE_ID_FALL_BACK := _FormationMove.MOVE_ID_FALL_BACK
const MOVE_ID_ROTATE_FILE := _FormationMove.MOVE_ID_ROTATE_FILE
const MOVE_ID_PLUG_FORWARD := _FormationMove.MOVE_ID_PLUG_FORWARD
const FORMATION_MOVE_KIND_SWAP_RANK := _FormationMove.FORMATION_MOVE_KIND_SWAP_RANK
const FORMATION_MOVE_KIND_DRAG_BACK := _FormationMove.FORMATION_MOVE_KIND_DRAG_BACK
const FORMATION_MOVE_KIND_FALL_BACK_PAIR := _FormationMove.FORMATION_MOVE_KIND_FALL_BACK_PAIR
const MOVE_ID_FLEE := _FormationMove.MOVE_ID_FLEE
const MOVE_ID_YIELD := _FormationMove.MOVE_ID_YIELD
const MOVE_ID_ORDER_HOLD_LANE := _FormationMove.MOVE_ID_ORDER_HOLD_LANE
const MOVE_ID_ORDER_PROBING := _FormationMove.MOVE_ID_ORDER_PROBING
const MOVE_ID_ORDER_PINCH_CENTER := _FormationMove.MOVE_ID_ORDER_PINCH_CENTER
const LEADER_FORMATION_COMMAND_MOVE_IDS: Array[String] = _FormationMove.LEADER_FORMATION_COMMAND_MOVE_IDS
const FORMATION_MOVEMENT_MOVE_IDS: Array[String] = _FormationMove.FORMATION_MOVEMENT_MOVE_IDS
static func is_formation_movement_move(move_id: String) -> bool:
	return _FormationMove.is_formation_movement_move(move_id)
static func is_leader_formation_command_move(move_id: String) -> bool:
	return _FormationMove.is_leader_formation_command_move(move_id)
static func is_formation_reposition_move(move_id: String) -> bool:
	return _FormationMove.is_formation_reposition_move(move_id)
static func is_partner_formation_move(move_id: String) -> bool:
	return _FormationMove.is_partner_formation_move(move_id)
static func is_plug_forward_move(move_id: String) -> bool:
	return _FormationMove.is_plug_forward_move(move_id)
static func is_formation_pair_move_kind(move_kind: String) -> bool:
	return _FormationMove.is_formation_pair_move_kind(move_kind)
static func formation_pair_move_kind_for_menu_move(move_id: String) -> String:
	return _FormationMove.formation_pair_move_kind_for_menu_move(move_id)
## Tactical rank penetration (0 = at their front line). Not armor RHA penetration.
const TACTICAL_PENETRATION_DEPTH_MAX := 2
## Extra damp when this side has very few standing fighters (duel / skirmish attrition).
const AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT := 0.72
## Tier 1.6 (P7): `CombatTargetScoring.ai_targeting_weight_mult` --" melee/close: resolved **`engagement_mode`**, our posture+cohesion + **opponent** formation, stance.
const AI_TARGETING_LINE_COH_LO_MULT := 0.94
const AI_TARGETING_LINE_COH_HI_MULT := 1.03
const AI_TARGETING_OPEN_COH_TIGHT_MULT := 1.0
const AI_TARGETING_OPEN_COH_LOOSE_MULT := 1.06
## Tier 1.6 breadth: hostile pick vs **opponent** LINE `line_cohesion` (solid enemy wall --'' ' slight hedge; ragged --'' ' press).
const AI_TARGETING_OPP_LINE_COH_SOLID_MULT := 0.96
const AI_TARGETING_OPP_LINE_COH_RAGGED_MULT := 1.04
## Dispersed enemy posture (OPEN/DUEL) --" small isolation / pick-off nudge.
const AI_TARGETING_OPP_OPEN_DUEL_MULT := 1.03
## Tier 1.6 / 1.7: resolved `CombatEngagementMode.engagement_mode` on listed hostile weights (`CombatTargetScoring`).
const AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT := 1.04
const AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT := 1.0
const AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT := 1.025
## Tier 1.6: `hostile_pair_targeting_weight_mult` scales down listed hostile picks vs **incapacitated** defenders (still valid targets if actions list them).
const AI_TARGETING_INCAP_HOSTILE_MULT := 0.42
## AI targeting bonus for opponents performing a medical wind-up (vulnerable, worth interrupting).
const AI_TARGETING_MEDICAL_WIND_UP_MULT := 1.6
## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** --" **`WeaponConstants.is_feint_move(move_id)`** hostile attacks get this multiplier (AI listing only).
const AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT := 1.06
## Tier 4.2: on top of **`AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`**, feint hostile weights scale by **`lerpf(1.0, this, pr_def)`** where **`pr_def`** = **`clampf(get_passive_parry_readiness ff -  passive_parry_readiness_incoming_contact_mult ff -  defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio), 0, 1)`** on the defender (WAITING uses **`guard`**).
const AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT := 1.10
## Tier 4.2: when attacker **`stamina_ratio` < `AI_FEINT_LISTING_STAMINA_GATE`**, multiply feint listing only by **`lerpf(AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO, 1.0, stamina_ratio / gate)`** (gassed attackers list feints less).
const AI_FEINT_LISTING_STAMINA_GATE := 0.30
const AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO := 0.86
## Tier 4.2: formation **`doctrine`** **`probing`** --" multiply feint-move listing weight only (**`CombatDoctrine.doctrine_for_fid`** on attacker **`formation_id`**).
const AI_FEINT_LISTING_DOCTRINE_PROBING_MULT := 1.04
## Tier 4.2: formation **`doctrine`** **`pinch_center`** --" feint listing nudge (inward-pressure doctrine; AI listing only).
const AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT := 1.03
## Tier 4.2: formation **`doctrine`** **`hold_lane`** --" feint listing dampen (disciplined line; AI listing only).
const AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT := 0.97
## Tier 4.2: after defender **`parry_deflect`**, feint-move listing vs that defender scales up to this mult while **`CombatManager.get_combat_tick_index() - stored_tick --''deg'' AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS`** (then lerps to **1**).
const AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT := 1.05
## Tier 4.2: combat ticks over which **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT`** lerps back to **1** after a **`parry_deflect`** (see **`CombatProcessTick`**).
const AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS := 8
## Tier 4.2: defender **`PassiveParryContext.is_off_balance`** while **`STATE_WAITING`** --" multiply feint-move listing vs that defender (footwork / tempo).
const AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT := 1.06
## Tier 1.9 (P10): depth rank + open spear lane --" AI favors thrusts over cuts/closes (CombatAIActionPicker).
const DEPTH_POLEARM_AI_STAB_WEIGHT_MULT := 1.35
const DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT := 0.9
const DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT := 0.82
## Tier 1.9: depth rank + open lane --" formation **`doctrine`** scales stab vs cut listing weights (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
const DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT := 1.08
const DEPTH_POLEARM_AI_DOCTRINE_HOLD_STAB_MULT := 0.94
const DEPTH_POLEARM_AI_DOCTRINE_PINCH_NON_STAB_MULT := 0.92
const DEPTH_POLEARM_AI_DOCTRINE_HOLD_NON_STAB_MULT := 1.06
## Tier 1.9: **`DOCTRINE_PROBING`** --" depth stab/cut weights between **hold** and **pinch** (listed actions only).
const DEPTH_POLEARM_AI_DOCTRINE_PROBING_STAB_MULT := 1.01
const DEPTH_POLEARM_AI_DOCTRINE_PROBING_NON_STAB_MULT := 0.99
## Optional encounter / preset overrides for the six doctrine multipliers above (`CombatManager.start`, Tier 1.9).
const DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB := "pinch_stab"
const DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB := "hold_stab"
const DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB := "probing_stab"
const DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB := "pinch_non_stab"
const DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB := "hold_non_stab"
const DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB := "probing_non_stab"
## Encounter dict: per-side Dictionary merged after defaults, before preset (preset wins on overlap).
const ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER := "depth_polearm_ai_doctrine_mults_player"
const ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY := "depth_polearm_ai_doctrine_mults_enemy"
## Preset dict passed to **`CombatManager.start`**: wins over encounter for that formation side.
const FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS := "depth_polearm_ai_doctrine_mults"
const DEPTH_POLEARM_AI_MULT_OVERRIDE_MIN := 0.5
const DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX := 1.5
## Tier 1.9: max |f"file| between **same-file rank-0 ally** and **enemy rank 0** for depth polearm lane thrusts.
## 0 = only the opposed file; 1 = immediate neighbor files (reach + `effective_pair_eff_dist` still gate strikes).
const DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES := 1
## Tier 1.9: max(pressure, depth) at this file --''deg'' this --'' ' depth spear may target legs even when density is tight/normal (wedge gap).
const DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN := 0.38
## Alias for lane-stress open threshold (`CombatDepthPolearm`, post--"intrusion removal).
const DEPTH_SPEAR_LANE_STRESS_OPEN_MIN := DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN
## Tier 3.1: depth spear **over-shoulder** lane (`depth_polearm_allows_low_targets` false) --" defender parry capacity vs that thrust line.
const DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT := 1.06
## Tier 3.1: depth spear **open** lane + stab --" attacker momentum seen at parry (full high/low envelope).
const DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT := 1.05
## Tier 3.1: depth rank stab through an open spear lane --" closing-speed proxy (`StrikePhysics`, `AttackResolver` ctx).
## Tight (**`over_shoulder`**) lane depth stabs use neutral **1.0** in `StrikePhysics.depth_polearm_thrust_closing_factor` (no extra closing bonus vs open).
const DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT := 1.03
## Tier 1.9 / 3.1: `pa["depth_polearm_lane_type"]` when **`depth_polearm_attack`** (empty string when not depth polearm). Mirrors **`depth_polearm_allows_low_targets`** for consumers that prefer a string lane id.
const DEPTH_POLEARM_LANE_TYPE_OPEN := "open"
const DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER := "over_shoulder"
## Formation dict `spear_lane_profile` preset key + normalized values (`CombatFormationSetup` / `CombatDepthPolearm.depth_polearm_lane_allows_low_targets`).
const FORMATION_KEY_SPEAR_LANE_PROFILE := "spear_lane_profile"
## Optional on **`CombatManager.start(player_formation, enemy_formation)`** preset dicts: wins over encounter doctrine for that side (same normalize path as **`set_formation_doctrine`**). Canonical key **`FORMATION_PRESET_KEY_DOCTRINE`**; if empty after strip, **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**.
const FORMATION_PRESET_KEY_DOCTRINE := "formation_doctrine"
## Short preset alias when **`FORMATION_PRESET_KEY_DOCTRINE`** is missing or whitespace-only.
const FORMATION_PRESET_KEY_DOCTRINE_ALT := "doctrine"
## Tier 6.2: optional rout gates on **`start()`** preset dict --" wins over encounter **`ENCOUNTER_KEY_FLEE_*`** for that side.
const FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX := "flee_line_cohesion_max"
const FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN := "flee_casualty_ratio_min"
## Keys on **`CombatManager.rout_thresholds_by_fid`** merged at **`start()`** (read by **`CombatFormationRout`**).
const ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX := "flee_line_cohesion_max"
const ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN := "flee_casualty_ratio_min"
const SPEAR_LANE_PROFILE_AUTO := ""
const SPEAR_LANE_PROFILE_OPEN := "open"
const SPEAR_LANE_PROFILE_RESTRICTED := "restricted"


static func normalize_spear_lane_profile(raw: Variant) -> String:
	var s: String = str(raw).strip_edges().to_lower()
	if s.is_empty() or s == "auto" or s == "default":
		return SPEAR_LANE_PROFILE_AUTO
	if s in ["open", "full", "wide", "lanes_open"]:
		return SPEAR_LANE_PROFILE_OPEN
	if s in ["restricted", "over_shoulder", "shoulder", "shoulder_only", "tight_lanes"]:
		return SPEAR_LANE_PROFILE_RESTRICTED
	return SPEAR_LANE_PROFILE_AUTO

## Re-export feature flag constants from CombatConstantsFeatureFlags.
const SURROUND_SECTOR_LOAD_FREE := _FeatureFlags.SURROUND_SECTOR_LOAD_FREE
const SURROUND_SECTOR_LOAD_K := _FeatureFlags.SURROUND_SECTOR_LOAD_K
const SURROUND_SECTOR_WEIGHT_MIN := _FeatureFlags.SURROUND_SECTOR_WEIGHT_MIN
const FEATURE_HEMA_EIGHT_GUARD_LINES := _FeatureFlags.FEATURE_HEMA_EIGHT_GUARD_LINES
const FEATURE_ARM_INTERPOSE := _FeatureFlags.FEATURE_ARM_INTERPOSE
const FEATURE_IV6_ATTACK_PATH_OCTANT := _FeatureFlags.FEATURE_IV6_ATTACK_PATH_OCTANT
const ARM_INTERPOSE_MIN_ANGLE_DEG := _FeatureFlags.ARM_INTERPOSE_MIN_ANGLE_DEG
const ARM_INTERPOSE_MIN_ALIGN := _FeatureFlags.ARM_INTERPOSE_MIN_ALIGN
const ARM_INTERPOSE_MAX_ALIGN := _FeatureFlags.ARM_INTERPOSE_MAX_ALIGN
const ARM_INTERPOSE_ALIGNMENT_BOOST := _FeatureFlags.ARM_INTERPOSE_ALIGNMENT_BOOST
const ARM_INTERPOSE_MAX_PATH_INDEX := _FeatureFlags.ARM_INTERPOSE_MAX_PATH_INDEX
const ARM_INTERPOSE_HIT_WEIGHT_MULT := _FeatureFlags.ARM_INTERPOSE_HIT_WEIGHT_MULT
const FEATURE_SURROUND_ARC_OCCUPANCY := _FeatureFlags.FEATURE_SURROUND_ARC_OCCUPANCY
const SURROUND_ARC_HALF_WIDTH_DEG := _FeatureFlags.SURROUND_ARC_HALF_WIDTH_DEG
const SURROUND_ARC_OVERLAP_TOLERANCE_DEG := _FeatureFlags.SURROUND_ARC_OVERLAP_TOLERANCE_DEG
const SURROUND_ARC_BLOCKED_THREAT_WEIGHT_MULT := _FeatureFlags.SURROUND_ARC_BLOCKED_THREAT_WEIGHT_MULT


## Engagement mode (duel / skirmish / formation) from live front-rank state --" see ENGAGEMENT_MODE_* below.
## Option 4 pilot: `CombatDoctrine.evaluate_automatic_doctrine` may set **`pinch_center`** from a hollow enemy front (only when formation doctrine is still **default**).
const FEATURE_AUTOMATIC_DOCTRINE := _FeatureFlags.FEATURE_AUTOMATIC_DOCTRINE
## p4c: min extra living rank-0 on our front vs opponent when our formation has more files (`numeric_superiority_for_pinch`).
const AUTO_DOCTRINE_NUMERIC_SUPERIORITY_FRONT_MARGIN := 1
## S6 pilot: layer KE budget scales pre-armor damage (sqrt curve); default off --" see `ArmorJouleBudget`.
const FEATURE_JOULE_ARMOR_BUDGET := _FeatureFlags.FEATURE_JOULE_ARMOR_BUDGET


static func is_joule_armor_budget_active() -> bool:
	return FEATURE_JOULE_ARMOR_BUDGET
## **Dev:** After `CombatManager.start`, `BattleScene` re-equips combatants with **rank > 0** with `SPEAR` (formations unchanged --" same `FormationPreset.default_for_count` as usual). Set **true** only for depth-polearm / spear-lane debugging.
const DEBUG_BACK_RANK_DEPTH_POLEARM_LOADOUT := _FeatureFlags.DEBUG_BACK_RANK_DEPTH_POLEARM_LOADOUT
## Engagement-mode names from live front-rank state.
const ENGAGEMENT_MODE_FORMATION := "formation"
const ENGAGEMENT_MODE_SKIRMISH := "skirmish"
const ENGAGEMENT_MODE_DUEL := "duel"
## Stable numeric ids for telemetry/tests/UI filters.
## 0 = duel, 1 = skirmish, 2 = formation.
const ENGAGEMENT_MODE_CODE_DUEL := 0
const ENGAGEMENT_MODE_CODE_SKIRMISH := 1
const ENGAGEMENT_MODE_CODE_FORMATION := 2
## Option 2 (Tier 1.7): historical active-count bands (alive + not incapacitated on each side) gate mode eligibility.
## Resolved **Duel** mode: `CombatEngagementMode.snapshot_is_true_duel` (exactly 1 living fighter per side).
## Per-side attrition AI damp when this side has at most this many actives (`CombatAIActionPicker._attrition_offense_weight_mult`).
const AI_ATTRITION_LOW_STANDING_MAX := 2
## Formation requires both sides at/above this active count in addition to front/fill thresholds.
const ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE := 4
## III-4 Track A **3b**: Skirmish **`rotate_file`** only when `our_files > opp_files + margin`.
const SKIRMISH_ROTATE_OUTNUMBER_FILE_MARGIN := 1
## FORMATION requires at least this many effective front fighters per side.
const FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE := 2
## FORMATION also requires this minimum front-fill ratio per side: front_alive / formation.files.
const FORMATION_MIN_FRONT_FILL_RATIO := 0.67
## Hysteresis leave threshold for FORMATION: stay in formation mode until line thins below this (prevents mode jitter near thresholds).
const FORMATION_LEAVE_MIN_FRONT_FIGHTERS_PER_SIDE := 1
const FORMATION_LEAVE_MIN_FRONT_FILL_RATIO := 0.45
## If true, mode is SKIRMISH when either side has zero effective front fighters.
const SKIRMISH_WHEN_EITHER_SIDE_ZERO_FRONT := true

## Default front-line width (files) for `FormationPreset.default_for_count`; raise after playtest.
const FORMATION_MAX_FRONT_FILES_DEFAULT := 5
## Hard cap on fighters per side in one engagement (party, encounter spawn, preset counts).
const FORMATION_UNIT_COUNT_HARD_CAP := 15

## --- Engagement / line cohesion / posture (docs/LIVE_PATHS.md#tier-1-spec) ---
const ENGAGEMENT_POSTURE_LINE := "line"
const ENGAGEMENT_POSTURE_OPEN := "open"
const ENGAGEMENT_POSTURE_DUEL := "duel"
## LINE--'' "OPEN hysteresis (Tier 1.4): cohesion must reach **L_in** to flip OPEN--'' 'LINE; must fall below **L_out** to flip LINE--'' 'OPEN (`L_in` > `L_out`).
const LINE_COHESION_POSTURE_ENTER_LINE_MIN := 0.62
const LINE_COHESION_POSTURE_LEAVE_LINE_BELOW := 0.50
## When **> 0**, each side--'"'s `L_in`/`L_out` shift from **relative** cohesion vs the opponent (`delta = strength * (our_coh - opp_coh)`):
## stronger line --'' ' easier LINE (lower `L_in`, higher `L_out`); weaker --'' ' easier OPEN. Set encounter `posture_asymmetry_strength` to **0** to disable.
const POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH := 0.12
## Combatant engagement role.
const ENGAGEMENT_ROLE_LINE := "line"
## Cohesion = (COHESION_BASE_FLOOR + COHESION_FILL_SCALE * front_fill) * (1 - COHESION_LANE_STRESS_WEIGHT * avg_lane_stress) * morale_cohesion_factor
const COHESION_LANE_STRESS_WEIGHT := 0.45
## Floor for `morale_cohesion_factor` (matches `CombatFormationEngagement` clamp).
const MORALE_COHESION_FACTOR_MIN := 0.15
const COHESION_BASE_FLOOR := 0.35
const COHESION_FILL_SCALE := 0.65
## Optional `line_discipline` tag on **encounter** or **formation preset** (formation wins): shifts hysteresis band for testing / data.
const LINE_DISCIPLINE_STRICT := "strict"
const LINE_DISCIPLINE_NORMAL := "normal"
const LINE_DISCIPLINE_LOOSE := "loose"
## Extra (f" enter threshold, f" leave threshold) from `line_discipline_posture_extra_deltas` --" strict = stickier LINE (higher both).
static func line_discipline_posture_extra_deltas(discipline: String) -> Vector2:
	var d: String = str(discipline).strip_edges().to_lower()
	if d == LINE_DISCIPLINE_STRICT:
		return Vector2(0.03, 0.04)
	if d == LINE_DISCIPLINE_LOOSE:
		return Vector2(-0.03, -0.04)
	return Vector2.ZERO


## Rank-0 self `fall_back` into an **empty** same-file rear slot: only `loose`. Strict/normal/empty require paired swap/drag/fall_back_pair (replacement in file).
static func line_discipline_allows_solo_fall_back(discipline: String) -> bool:
	return str(discipline).strip_edges().to_lower() == LINE_DISCIPLINE_LOOSE
## Paired disengage (swap_rank / drag / fall_back to rear) and solo fall_back: require real injury (blood this low, no usable arm, or immediate peril) --" not low stamina / composite fitness alone.
## ~85 = ATLS Class II (~15% blood lost): wounded, may seek rear rank --" not first-cut nuisance (was 94 / ~6%, too eager).
const FORMATION_RETREAT_BLOOD_VOLUME_MAX := 85.0
## Abandon-field **flee** (rout): Class III+ personal crisis (~45% lost) or immediate bleed-out --" not --..."step back in the file.--'?
## Aligns with `MedicalPhaseController.MEDICAL_DANGER_BLOOD_THRESHOLD` (55).
const FORMATION_FLEE_BLOOD_VOLUME_MAX := 55.0
## True duel (armed): flee only when personal bleed-out is imminent.
const FORMATION_FLEE_DUEL_ARMED_BLOOD_MAX := 28.0
## MS-L9 positional awareness: disengage when surrounded and blood below this threshold.
## ~60% remaining (~40% lost): ATLS Class III boundary --" real vulnerability, not minor bruising.
## Higher than `FORMATION_FLEE_BLOOD_VOLUME_MAX` (55) so AI disengages before reaching bleed-out danger.
const MENTAL_STACK_L9_VULNERABILITY_BLOOD_THRESHOLD := 60.0
## Formation keys (see `CombatFormationRout`, `CombatFormationEngagement`).
const FORMATION_KEY_STANDING_AT_START := "standing_at_start"
## Wounded fighter may **rout** when cached `line_cohesion` falls below this (--''deg< below LINE leave band 0.50).
const FORMATION_FLEE_LINE_COHESION_MAX := 0.42
## Side has lost this fraction of `standing_at_start` (dead / fled / incapacitated) --'' ' rout pressure.
const FORMATION_FLEE_CASUALTY_RATIO_MIN := 0.30
## Wounded + stressed rout blocked when this side still has --''deg'' this ff -  opponent standing (tactical win --" hold the field).
const FORMATION_FLEE_WINNING_STANDING_RATIO := 1.15

## Explicit no-op: pass turn, schedule next action_ready (same delays as skip_turn).
const MOVE_ID_WAIT := "wait"
## Tier 4.3.7: retarget mental **`focus_part`** + **`guard_line`** while waiting (no strike).
const MOVE_ID_FOCUS_HIGH := "focus_high"
const MOVE_ID_FOCUS_LOW := "focus_low"
const MOVE_ID_FOCUS_LEFT := "focus_left"
const MOVE_ID_FOCUS_RIGHT := "focus_right"
const FOCUS_LINE_MOVE_IDS: Array[String] = [
	MOVE_ID_FOCUS_HIGH,
	MOVE_ID_FOCUS_LOW,
	MOVE_ID_FOCUS_LEFT,
	MOVE_ID_FOCUS_RIGHT,
]
const AI_FOCUS_LINE_BASE_WEIGHT := 0.06
const YOMI_PARRY_DEFLECT_FEINT_LISTING_MULT_PER := 0.035
const YOMI_PARRY_DEFLECT_FEINT_LISTING_MULT_CAP := 1.18
const YOMI_DEFENSE_READINESS_MULT_PER_PARRY_DEFLECT := 0.04
const YOMI_DEFENSE_READINESS_MULT_CAP := 1.14
## Tier 4.4: attacker step-on-wind-up lateral angle nudge (degrees). Cleared via **`CombatFootwork.clear_on_exchange_end`** on resolve, abort, recovery, combat start, death (not left on idle **`waiting`** reserve).
const COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG := "position_angle_offset_deg"
## Tier 4.4.3: row label fragment when footwork enabled (`Step`, no degrees); UI only in **`wind_up`** / **`recovering`**.
const COMBATANT_KEY_POSITION_ANGLE_UI_HINT := "position_angle_ui_hint"
## Player turn-ready: aggregated duration hints from listed formation moves (see **`CombatPlayerTurnHints.sync_formation_listed_turn_hint`**).
const COMBATANT_KEY_FORMATION_MOVES_TURN_HINT := "formation_moves_turn_hint"
## Stamped on turn-ready when listed actions are only wait + guard/focus lines (depth rank hold).
const COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT := "hold_line_focus_only_hint"
## Player turn-ready: **`attempt_close`** listed vs controlling defender (gauge + combat log).
const COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT := "controlling_close_turn_hint"
const POSITION_ANGLE_OFFSET_DEG_BY_LINE: Dictionary = {
	"high": 0.0,
	"low": 6.0,
	"left": 14.0,
	"right": -14.0,
}
## L4 pilot: 4-cardinal keys when eight-guard flag off; when on, **`CombatGuardLines.position_angle_offset_deg_for_line`** (octant table). LIVE_PATHS **`#wf-form-guard-pa-matrix`**.
## Tier 4.4.2: defender step scales (symmetric to attacker step-on-wind-up; still flag-gated).
## WF-T1 (2026-06-07): Camp-5 soak confirms parry 0.55 / dodge 0.85 --" tune octant raw table first.
const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY := 0.55
const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE := 0.85
static func position_angle_defender_offset_deg_for_line(line: String, scale: float) -> float:
	return position_angle_offset_deg_for_attack_line(line) * scale


static func guard_line_for_body_part(part: String) -> String:
	var p: String = str(part).strip_edges()
	if p.is_empty():
		return GUARD_DEFAULT
	if is_feature_hema_eight_guard_lines_enabled():
		match p:
			"head", "neck", "face", "scalp", "chest":
				return _GuardLines.LINE_HIGH
			"left_leg":
				return _GuardLines.LINE_LOW_LEFT
			"right_leg":
				return _GuardLines.LINE_LOW_RIGHT
			"left_arm":
				return _GuardLines.LINE_LEFT
			"right_arm":
				return _GuardLines.LINE_RIGHT
		for line_key in _GuardLines.LINE_TO_DEFAULT_PART:
			if str(_GuardLines.LINE_TO_DEFAULT_PART[line_key]) == p:
				return str(line_key)
		return _GuardLines.LINE_HIGH
	match p:
		"head", "neck", "face", "scalp", "chest":
			return "high"
		"left_leg", "right_leg":
			return "low"
		"left_arm":
			return "left"
		"right_arm":
			return "right"
	for line_key in LINE_TO_DEFAULT_PART:
		if str(LINE_TO_DEFAULT_PART[line_key]) == p:
			return str(line_key)
	return GUARD_DEFAULT


static func guard_zone_for_guard_line(line: String) -> String:
	if is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.guard_zone_part_for_line(line)
	return str(LINE_TO_DEFAULT_PART.get(str(line), "head"))


# Swap rank AI (CombatAIActionPicker): relief only when necessary --" not marginal fitness differences.
const SWAP_RANK_AI_LOW_WEIGHT := 0.02
const SWAP_RANK_AI_HIGH_WEIGHT := 1.0
const SWAP_RANK_AI_LINE_PLUG_WEIGHT := 0.52 # Rear relief when another file has rank-0 hole (III-6 maintain)
const AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT := 0.62 # Skirmish shuffle when line has rank-0 holes (III-6 maintain)
const AI_ROTATE_FILE_WHEN_ENGAGEMENT_LISTED_MULT := 0.35 # Prefer strikes/close over shuffle when both are listed
const AI_ROTATE_FILE_LONG_CLOSE_ONLY_MULT := 1.35 # LONG close-only (no melee) --" shuffle can find angle vs close spam
const AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT := 0.82 # Mapped rank-0 LONG close-only --" rotate can compete
const AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT := 1.28 # Mapped wing out of reach --" close bind beats wait/shuffle
const AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT := 0.58 # Menu-listed close when pair gate fails at pick time (fight-finish tail)
const AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT := 1.4 # Sparse post-flee front --" close to finish beats shuffle
const AI_SPARSE_LINE_OFFENSE_MULT := 1.35 # Listed melee on sparse post-flee front --" fight over focus shuffle
const AI_FOCUS_LINE_SPARSE_ENGAGEMENT_LISTED_MULT := 0.35 # Damp guard retarget when strikes/close are listed
const AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT := 0.45 # Post-flee sparse --" wait below close/strike finish
const AI_WAIT_MOP_UP_FINISH_MULT := 0.4 # Mop-up winner or last-enemy underdog --" finish fight, don't idle
const AI_WAIT_NO_STRIKE_MULT := 0.15 # No hostile strikes listed --" prefer flee over endless wait loop
## Mobile cowering solo **fall_back** vs **wait** (Tier 6.1 --" no arms, legs OK).
const COWERING_SOLO_FALL_BACK_AI_WEIGHT := 1.5
## Tier 6.2: mobile cowering --" prefer **`flee`** over in-formation **`fall_back`** when both are listed (cannot hold weapon).
const COWERING_FLEE_AI_WEIGHT := 1.55
const DUEL_DISARMED_YIELD_AI_WEIGHT := 2.2
const DUEL_DISARMED_WAIT_AI_WEIGHT := 1.35
const DUEL_DISARMED_FLEE_AI_WEIGHT := 0.28
## Armed fighters: rout is rare --" well below rotate_file; scaled by `CombatFormationRout.flee_ai_pick_mult` (cohesion + casualties).
const AI_FLEE_ROUTINE_WEIGHT := 0.22
const AI_FLEE_HIGH_COHESION_MULT := 0.35
const AI_FLEE_LOW_COHESION_MULT := 1.08
const AI_FLEE_HIGH_CASUALTY_MULT := 1.22
const AI_FLEE_LOSING_SIDE_MULT := 1.28
## MS-L7 exhaustion tunnel: flee must beat rotate_file (~0.55) when abandon-field is listed.
const AI_FLEE_EXHAUSTION_TUNNEL_WEIGHT := 0.88
## Flee listing when stamina is nearly spent (even below MS-L7 tunnel threshold).
const AI_FLEE_CRITICAL_STAMINA_RATIO := 0.12
## IV-7b: below this stamina ratio, attack / **`attempt_close`** listing weights use **`AI_STAMINA_ENGAGE_LOW_MULT`**.
## Exhaustion ramp: as stamina approaches 0%, offense weight drops further (exhausted fighters can still defend but should not initiate fresh attacks at full weight).
const AI_STAMINA_ENGAGE_FLOOR_RATIO := 0.20
const AI_STAMINA_ENGAGE_LOW_MULT := 0.85
## Below this stamina ratio, offense weight uses **`AI_STAMINA_DEEP_EXHAUST_MULT`** (near-total exhaustion --" can defend but should not initiate).
const AI_STAMINA_DEEP_EXHAUST_RATIO := 0.05
const AI_STAMINA_DEEP_EXHAUST_MULT := 0.40
## Exhaustion cap: below this ratio, offense weight floors at **`AI_STAMINA_EXHAUSTION_DEEP_MULT`** (realistic simulation --" exhausted fighters cannot initiate).
const AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD := 0.05
const AI_STAMINA_EXHAUSTION_DEEP_MULT := 0.40


## IV-7b: step-down offense engage weight (investigated 2026-05; locked 2026-06-08).
## Exhaustion ramp: as stamina approaches 0%, offense weight drops further --" exhausted fighters can still defend but should not initiate fresh attacks at full weight.
static func ai_offense_stamina_weight_mult(stamina_ratio: float) -> float:
	if stamina_ratio >= AI_STAMINA_ENGAGE_FLOOR_RATIO:
		return 1.0
	var w: float = AI_STAMINA_ENGAGE_LOW_MULT
	if stamina_ratio <= AI_STAMINA_DEEP_EXHAUST_RATIO:
		w = AI_STAMINA_DEEP_EXHAUST_MULT
	elif stamina_ratio < AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD:
		w = lerpf(AI_STAMINA_EXHAUSTION_DEEP_MULT, AI_STAMINA_ENGAGE_LOW_MULT, stamina_ratio / maxf(AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD, 0.001))
	return w


static func iv7b_stamina_engage_doc_sync_line() -> String:
	return (
		"IV-7b engage floor: ratio<%.2f -> offense_mult=%.2f"
		% [AI_STAMINA_ENGAGE_FLOOR_RATIO, AI_STAMINA_ENGAGE_LOW_MULT]
	)
## Partner must exceed our composite fitness (perf ff -  blood norm) by at least this much for a routine relief.
const SWAP_RANK_AI_MIN_FITNESS_GAP := 0.20
## Below this our_fitness, treat as dangerously unfit: partner need only be ahead by URGENT_MIN_GAP.
const SWAP_RANK_AI_CRITICAL_FITNESS := 0.42
## When our_fitness is at/under CRITICAL, partner must be at least this much fitter (smaller than MIN_FITNESS_GAP).
const SWAP_RANK_AI_URGENT_MIN_GAP := 0.10
## Re-export encounter/ambush/WF constants from CombatConstantsEncounter.
## Maintain canonical values in the sub-module, not here.
const AMBUSH_TYPE_NONE := _Encounter.AMBUSH_TYPE_NONE
const AMBUSH_TYPE_FULL := _Encounter.AMBUSH_TYPE_FULL
const AMBUSH_TYPE_PARTIAL := _Encounter.AMBUSH_TYPE_PARTIAL
const ENCOUNTER_KEY_POSTURE_ENTER_DELTA := _Encounter.ENCOUNTER_KEY_POSTURE_ENTER_DELTA
const ENCOUNTER_KEY_POSTURE_LEAVE_DELTA := _Encounter.ENCOUNTER_KEY_POSTURE_LEAVE_DELTA
const ENCOUNTER_KEY_LINE_DISCIPLINE := _Encounter.ENCOUNTER_KEY_LINE_DISCIPLINE
const ENCOUNTER_KEY_POSTURE_ASYMMETRY_STRENGTH := _Encounter.ENCOUNTER_KEY_POSTURE_ASYMMETRY_STRENGTH
const ENCOUNTER_KEY_MORALE_COHESION_PLAYER := _Encounter.ENCOUNTER_KEY_MORALE_COHESION_PLAYER
const ENCOUNTER_KEY_MORALE_COHESION_ENEMY := _Encounter.ENCOUNTER_KEY_MORALE_COHESION_ENEMY
const ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER := _Encounter.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER
const ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY := _Encounter.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY
const ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER := _Encounter.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER
const ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY := _Encounter.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY
const ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER := _Encounter.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER
const ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY := _Encounter.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY
const ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT := _Encounter.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
const ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT := _Encounter.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT
const ENCOUNTER_KEY_PLAYER_FORMATION := _Encounter.ENCOUNTER_KEY_PLAYER_FORMATION
const ENCOUNTER_KEY_PLAYER_FRONT_COUNT := _Encounter.ENCOUNTER_KEY_PLAYER_FRONT_COUNT
const ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM := _Encounter.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM
const ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM := _Encounter.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM
const WF_FORM_SWITCH_COOLDOWN_S := _Encounter.WF_FORM_SWITCH_COOLDOWN_S
const WF_FORM_SWITCH_STAMINA_COST := _Encounter.WF_FORM_SWITCH_STAMINA_COST
const WF_YOMI_FORM_INFERENCE_MIN_OBS := _Encounter.WF_YOMI_FORM_INFERENCE_MIN_OBS
const WF_YOMI_FORM_INFERENCE_MARGIN := _Encounter.WF_YOMI_FORM_INFERENCE_MARGIN
const WF_FORM_COUNTER_MULT_CAP := _Encounter.WF_FORM_COUNTER_MULT_CAP
const WF_COUNTER_READINESS_NUDGE_MIN := _Encounter.WF_COUNTER_READINESS_NUDGE_MIN
const WF_COUNTER_READINESS_NUDGE_MAX := _Encounter.WF_COUNTER_READINESS_NUDGE_MAX
const WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD := _Encounter.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
const WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD := _Encounter.WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD
const WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD := _Encounter.WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD
const WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD := _Encounter.WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD
const WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD := _Encounter.WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD
const AI_FOCUS_LINE_FORM_PREFERRED_MULT := _Encounter.AI_FOCUS_LINE_FORM_PREFERRED_MULT
const ENCOUNTER_PROTECTION_CIRCLE_ACTIVE := _Encounter.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE
const ENCOUNTER_AMBUSHED_SIDE := _Encounter.ENCOUNTER_AMBUSHED_SIDE
const WORLD_META_COMBAT_ENCOUNTER := _Encounter.WORLD_META_COMBAT_ENCOUNTER

## Tier 1.9: canonical + optional alt string keys on a dict (**`strip_edges`** each); non-empty canonical wins.
static func formation_doctrine_string_from_dict(source: Dictionary, primary_key: String, alt_key: String) -> String:
	var s: String = source.get(primary_key, "").strip_edges()
	if s.is_empty():
		s = source.get(alt_key, "").strip_edges()
	return s


## Tier 1.9: encounter doctrine seed --" delegates to **`formation_doctrine_string_from_dict`**.
static func encounter_formation_doctrine_string(encounter: Dictionary, primary_key: String, alt_key: String) -> String:
	return formation_doctrine_string_from_dict(encounter, primary_key, alt_key)


## Tier 1.9: baseline depth-spear **doctrine** mults (encounter / preset may override via **`merge_depth_polearm_ai_doctrine_mults`**).
static func default_depth_polearm_ai_doctrine_mults_dict() -> Dictionary:
	return {
		DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB: DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT,
		DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB: DEPTH_POLEARM_AI_DOCTRINE_HOLD_STAB_MULT,
		DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB: DEPTH_POLEARM_AI_DOCTRINE_PROBING_STAB_MULT,
		DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB: DEPTH_POLEARM_AI_DOCTRINE_PINCH_NON_STAB_MULT,
		DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB: DEPTH_POLEARM_AI_DOCTRINE_HOLD_NON_STAB_MULT,
		DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB: DEPTH_POLEARM_AI_DOCTRINE_PROBING_NON_STAB_MULT,
	}


static func merge_depth_polearm_ai_doctrine_mults(base: Dictionary, overlay: Variant) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	if overlay == null or not overlay is Dictionary:
		return out
	var keys: Array = [
		DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB,
		DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB,
		DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB,
		DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB,
		DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB,
		DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB,
	]
	var o: Dictionary = overlay as Dictionary
	for k in keys:
		if not o.has(k):
			continue
		var v: Variant = o[k]
		var tv: int = typeof(v)
		var f: float = -1.0
		if tv == TYPE_FLOAT or tv == TYPE_INT:
			f = float(v)
		elif tv == TYPE_STRING and String(v).is_valid_float():
			f = float(v)
		if f > 0.0:
			out[k] = clampf(f, DEPTH_POLEARM_AI_MULT_OVERRIDE_MIN, DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX)
	return out


## Encounter side keys --'' ' optional preset overlay (preset wins per field). Empty dict --'' ' use **`FORMATION_FLEE_*`** defaults.
static func rout_thresholds_for_encounter_and_preset(
	encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
	var out: Dictionary = {}
	var fid: String = str(formation_id)
	var enc_coh_key: String = (
		ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER
		if fid == SIDE_PLAYER
		else ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY
	)
	var enc_cas_key: String = (
		ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER
		if fid == SIDE_PLAYER
		else ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY
	)
	if encounter.has(enc_coh_key):
		out[ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX] = clampf(
			float(encounter[enc_coh_key]), 0.05, 0.95
		)
	if encounter.has(enc_cas_key):
		out[ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN] = clampf(
			float(encounter[enc_cas_key]), 0.05, 0.90
		)
	if preset.has(FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX):
		out[ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX] = clampf(
			float(preset[FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX]), 0.05, 0.95
		)
	if preset.has(FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN):
		out[ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN] = clampf(
			float(preset[FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN]), 0.05, 0.90
		)
	return out


## Defaults --'' ' encounter side --'' ' preset (**`FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS`** wins on overlap).
static func depth_polearm_ai_doctrine_mults_for_encounter_and_preset(
	encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
	var base: Dictionary = default_depth_polearm_ai_doctrine_mults_dict()
	var enc_key: String = (
		ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER
		if str(formation_id) == SIDE_PLAYER
		else ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY
	)
	var after_enc: Dictionary = merge_depth_polearm_ai_doctrine_mults(base, encounter.get(enc_key))
	var preset_overlay: Variant = preset.get(FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS)
	return merge_depth_polearm_ai_doctrine_mults(after_enc, preset_overlay)

## Re-export distance bands from CombatConstantsDistance.
const DISTANCE_CLOSE := _Distance.DISTANCE_CLOSE
const DISTANCE_MID := _Distance.DISTANCE_MID
const DISTANCE_LONG := _Distance.DISTANCE_LONG

## Re-export Tier 4.2 footwork constants and helpers from CombatConstantsFootwork.
## Maintain canonical values in the sub-module.
const DEFENSE_SPACING_PARRY_MULT_CLOSE := _Footwork.DEFENSE_SPACING_PARRY_MULT_CLOSE
const DEFENSE_SPACING_PARRY_MULT_LONG := _Footwork.DEFENSE_SPACING_PARRY_MULT_LONG
const DEFENSE_SPACING_DODGE_MULT_CLOSE := _Footwork.DEFENSE_SPACING_DODGE_MULT_CLOSE
const DEFENSE_SPACING_DODGE_MULT_LONG := _Footwork.DEFENSE_SPACING_DODGE_MULT_LONG
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT := _Footwork.DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE: Dictionary = _Footwork.DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE
const DEFENSE_FOOTWORK_WAITING_DODGE_MULT := _Footwork.DEFENSE_FOOTWORK_WAITING_DODGE_MULT
const AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT := _Footwork.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
const AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT := _Footwork.AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE := _Footwork.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG := _Footwork.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG
const PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT := _Footwork.PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT
const PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT := _Footwork.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT
const PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT := _Footwork.PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE := _Footwork.FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG := _Footwork.FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG
static func normalize_recovery_cause(cause: String) -> String:
	return _Footwork.normalize_recovery_cause(cause)
static func readiness_curve_for_cause(cause: String) -> Array:
	return _Footwork.readiness_curve_for_cause(cause)
static func defense_footwork_recovering_dodge_mult_for_cause(cause: String) -> float:
	return _Footwork.defense_footwork_recovering_dodge_mult_for_cause(cause)
static func ai_feint_listing_defender_recovering_footwork_mult_for_cause(cause: String) -> float:
	return _Footwork.ai_feint_listing_defender_recovering_footwork_mult_for_cause(cause)
static func passive_parry_readiness_incoming_contact_mult(contact_type: String) -> float:
	return _Footwork.passive_parry_readiness_incoming_contact_mult(contact_type)
static func defender_distance_band_to_attacker_id(defender: Dictionary, attacker_id: int) -> String:
	return _Footwork.defender_distance_band_to_attacker_id(defender, attacker_id)
static func ai_feint_listing_defender_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
	return _Footwork.ai_feint_listing_defender_readiness_spacing_mult(defender, attacker_id)
static func feint_guard_zone_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
	return _Footwork.feint_guard_zone_readiness_spacing_mult(defender, attacker_id)





## Re-export close-slot constants from CombatConstantsCloseSlots.
const REACH_MID_MIN := _CloseSlots.REACH_MID_MIN
const MOVE_ID_ATTEMPT_CLOSE := _CloseSlots.MOVE_ID_ATTEMPT_CLOSE
const SKIP_TURN_LOG_PASS := _CloseSlots.SKIP_TURN_LOG_PASS
const SKIP_TURN_LOG_WAIT := _CloseSlots.SKIP_TURN_LOG_WAIT
const SKIP_TURN_LOG_REJECT := _CloseSlots.SKIP_TURN_LOG_REJECT
const CLOSE_SLOTS_PER_TARGET := _CloseSlots.CLOSE_SLOTS_PER_TARGET
const CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS := _CloseSlots.CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS
const CLOSE_SLOTS_FULL_TARGETING_MULT := _CloseSlots.CLOSE_SLOTS_FULL_TARGETING_MULT
const CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S := _CloseSlots.CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S

static func max_close_slots_for_density(density: String) -> int:
	return _CloseSlots.max_close_slots_for_density(density)

## Formation doctrine for hybrid targeting (CombatDoctrine / CombatTargetScoring).
const DOCTRINE_DEFAULT := "default"
const DOCTRINE_PINCH_CENTER := "pinch_center"
const DOCTRINE_HOLD_LANE := "hold_lane"
## Optional: measured thrusts / feints --" depth spear listing weights only (no pinch inward / hold off-file hedge).
const DOCTRINE_PROBING := "probing"
## Seconds: AI "sticks" to last offensive target (hysteresis).
const DOCTRINE_COMMITMENT_DURATION_S := 4.5
const DOCTRINE_COMMIT_MATCH_WEIGHT_MULT := 1.28
const DOCTRINE_FILE_OPPOSED_WEIGHT_MULT := 1.42
## Extra weight toward enemy-line center when PINCH + wing has no file-opposed rank-0 target.
const DOCTRINE_PINCH_INWARD_BIAS_PER_FILE := 0.18
## III-4 **3e**: pincer flank wing AI/listing bias toward outer-file enemy under pinch + file outnumber.
const DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT := 1.28
## III-4 **3e**: pincer flank wing targeting spread damp --" penalizes wide-arc targets by this per-file offset from preferred enemy file.
const DOCTRINE_PINCER_CLOSE_ARC_SPREAD_MULT := 0.92
## III-4 **3e**: post-rout envelop mop-up --" enemy standing at or below this, our side above, standing advantage.
const ENVELOP_MOP_UP_MAX_ENEMY_ACTIVE := 1
const ENVELOP_MOP_UP_MIN_OUR_ACTIVE := 2
## III-4 **3e**: depth fighter plug forward into rank-0 during envelop mop-up.
const ENVELOP_MOP_UP_PLUG_FORWARD_ENABLED := true
const PLUG_FORWARD_DURATION_S := 0.6
const FORMATION_PLUG_FORWARD_COOLDOWN_S := 3.0
## AI weight for plug_forward during envelop mop-up (high --" entire formation should engage).
const PLUG_FORWARD_AI_HIGH_WEIGHT := 1.5
const PLUG_FORWARD_AI_LOW_WEIGHT := 0.3
## Utility-pick damp when rotate still lists during post-rout mop-up (listing gate is primary).
const ENVELOP_MOP_UP_ROTATE_AI_WEIGHT_MULT := 0.12
## Utility-pick nudge for listed **`attempt_close`** during post-rout mop-up.
const ENVELOP_MOP_UP_CLOSE_AI_WEIGHT_MULT := 1.28
## Utility-pick damp for focus-line shuffle during post-rout mop-up (L4 close is primary).
const ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT := 0.15
## Larger = geometry matters less in soft score (1/(1+eff*k)).
const DOCTRINE_SOFT_DISTANCE_SCALE := 0.55
## Normalizer for how many allies already committed on same defender.
const DOCTRINE_PRESSURE_COUNT_REF := 3.0
const DOCTRINE_PRESSURE_DECAY_PER_ALLY := 0.22
## HOLD_LANE: demote non-file-opposed rank-0 targets.
const DOCTRINE_HOLD_LANE_OFF_FILE_MULT := 0.58
const DOCTRINE_AI_WEIGHT_MULT_MIN := 0.35
const DOCTRINE_AI_WEIGHT_MULT_MAX := 2.6
## Re-export stance constants and helpers from CombatConstantsStance.
## Maintain canonical values in the sub-module, not here.
const STANCE_MOD_PARRY: Dictionary = _Stance.STANCE_MOD_PARRY
const STANCE_MOD_EVASION: Dictionary = _Stance.STANCE_MOD_EVASION
const STANCE_MOD_DAMAGE: Dictionary = _Stance.STANCE_MOD_DAMAGE
const STANCE_MOD_CLOSE_ATTEMPT: Dictionary = _Stance.STANCE_MOD_CLOSE_ATTEMPT
const STANCE_MOD_AI_MELEE_FOCUS: Dictionary = _Stance.STANCE_MOD_AI_MELEE_FOCUS
const STANCE_MOD_FEINT_READTHROUGH: Dictionary = _Stance.STANCE_MOD_FEINT_READTHROUGH
const STANCE_MOD_AI_FEINT_LISTING: Dictionary = _Stance.STANCE_MOD_AI_FEINT_LISTING
const STANCE_MOD_OPPONENT_CLOSE: float = _Stance.STANCE_MOD_OPPONENT_CLOSE
const STANCE_MOD_OPPONENT_DISENGAGE: float = _Stance.STANCE_MOD_OPPONENT_DISENGAGE
const DENSITY_CLOSE_MOD: Dictionary = _Stance.DENSITY_CLOSE_MOD

## **Harness-only alias:** see LIVE_PATHS WF-M5. Do not add new production call sites.
static func get_stance_modifier(stance: String, effect: String) -> float:
	return _Stance.get_stance_modifier(stance, effect)

static func get_density_close_mod(density: String) -> float:
	return _Stance.get_density_close_mod(density)

static func get_spacing_from_density(density: String) -> float:
	return _Stance.get_spacing_from_density(density)

## Re-export attack path tables and geometry from **`CombatConstantsAttackPath`**.
## Maintain canonical values in the sub-module, not here.

const DIAGONAL_WEIGHTS: Dictionary = _AttackPath.DIAGONAL_WEIGHTS
const ATTACK_PATH_HIGH: Array = _AttackPath.ATTACK_PATH_HIGH
const ATTACK_PATH_LOW: Array = _AttackPath.ATTACK_PATH_LOW
const ATTACK_PATH_LEFT: Array = _AttackPath.ATTACK_PATH_LEFT
const ATTACK_PATH_RIGHT: Array = _AttackPath.ATTACK_PATH_RIGHT
const ATTACK_PATHS: Dictionary = _AttackPath.ATTACK_PATHS
const ATTACK_PATHS_BY_GUARD: Dictionary = _AttackPath.ATTACK_PATHS_BY_GUARD
const PATH_INTERCEPT_EARLY_MAX := _AttackPath.PATH_INTERCEPT_EARLY_MAX
const PATH_INTERCEPT_FULL_MAX := _AttackPath.PATH_INTERCEPT_FULL_MAX
const LINE_ANGLE_DEG: Dictionary = _AttackPath.LINE_ANGLE_DEG
const LINE_TO_ANGLE_DEG: Dictionary = _AttackPath.LINE_TO_ANGLE_DEG
const ANGLE_VARIANCE_DEG: float = _AttackPath.ANGLE_VARIANCE_DEG
const ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT: float = _AttackPath.ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT
const ANGLE_VARIANCE_OFF_BALANCE_MULT: float = _AttackPath.ANGLE_VARIANCE_OFF_BALANCE_MULT
const ANGLE_VARIANCE_MASS_REFERENCE_KG: float = _AttackPath.ANGLE_VARIANCE_MASS_REFERENCE_KG
const ANGLE_VARIANCE_MASS_SCALE: float = _AttackPath.ANGLE_VARIANCE_MASS_SCALE
const GUARD_WOBBLE_MAX_DEG: float = _AttackPath.GUARD_WOBBLE_MAX_DEG
const GUARD_WOBBLE_READINESS_SCALE: float = _AttackPath.GUARD_WOBBLE_READINESS_SCALE
const GUARD_WOBBLE_MASS_REFERENCE_KG: float = _AttackPath.GUARD_WOBBLE_MASS_REFERENCE_KG
const GUARD_WOBBLE_MASS_SCALE: float = _AttackPath.GUARD_WOBBLE_MASS_SCALE
const ARC_SPAN_LATE_PARRY_THRESHOLD_DEG: float = _AttackPath.ARC_SPAN_LATE_PARRY_THRESHOLD_DEG
const ARC_SPAN_LATE_PARRY_PENALTY_MAX: float = _AttackPath.ARC_SPAN_LATE_PARRY_PENALTY_MAX
const DODGE_FULL_THRESHOLD := _AttackPath.DODGE_FULL_THRESHOLD
const DODGE_PARTIAL_RATIO_MIN := _AttackPath.DODGE_PARTIAL_RATIO_MIN
const PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY := _AttackPath.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY
const PARRY_FOLLOW_THROUGH_PARTIAL_MIN := _AttackPath.PARRY_FOLLOW_THROUGH_PARTIAL_MIN
const PARRY_FOLLOW_THROUGH_THRUST_PENALTY := _AttackPath.PARRY_FOLLOW_THROUGH_THRUST_PENALTY
const PARRY_FOLLOW_THROUGH_CUT_BONUS := _AttackPath.PARRY_FOLLOW_THROUGH_CUT_BONUS
const RECOVERY_AGILITY_MIN := _AttackPath.RECOVERY_AGILITY_MIN
const RECOVERY_AGILITY_MAX := _AttackPath.RECOVERY_AGILITY_MAX
const WEAK_EXPOSURE_BY_ARCH: Dictionary = _AttackPath.WEAK_EXPOSURE_BY_ARCH
const DEFENDER_STRONG_BONUS: float = _AttackPath.DEFENDER_STRONG_BONUS
const PARRY_STRONG_CONTACT_BY_ARCH: Dictionary = _AttackPath.PARRY_STRONG_CONTACT_BY_ARCH
const GUARD_DEFAULT_ATTACK_PATH := _AttackPath.GUARD_DEFAULT


static func get_attack_path(attack_line: String, guard_line: String) -> Array:
	return _AttackPath.get_attack_path(attack_line, guard_line)


static func get_arc_angle_at_progress(arc_start_deg: float, arc_end_deg: float, progress: float) -> float:
	return _AttackPath.get_arc_angle_at_progress(arc_start_deg, arc_end_deg, progress)


static func arc_end_deg_for_contact_geometry(pa: Dictionary) -> float:
	return _AttackPath.arc_end_deg_for_contact_geometry(pa)


static func get_attack_angle_at_progress(pa: Dictionary, progress: float) -> float:
	return _AttackPath.get_attack_angle_at_progress(pa, progress)


static func angle_diff_deg(a_deg: float, b_deg: float) -> float:
	return _AttackPath.angle_diff_deg(a_deg, b_deg)


static func line_to_angle(line: String) -> float:
	return _AttackPath.line_to_angle(line)


static func angle_to_nearest_line(angle_deg: float) -> String:
	return _AttackPath.angle_to_nearest_line(angle_deg)


static func get_alignment_from_angles(attack_angle_deg: float, guard_angle_deg: float) -> float:
	return _AttackPath.get_alignment_from_angles(attack_angle_deg, guard_angle_deg)


static func get_deflected_angle_bilateral(attack_angle_deg: float, guard_angle_deg: float, magnitude_deg: float) -> float:
	return _AttackPath.get_deflected_angle_bilateral(attack_angle_deg, guard_angle_deg, magnitude_deg)


static func get_deflection_magnitude_deg(alignment: float, severity: float, contact_type: String) -> float:
	return _AttackPath.get_deflection_magnitude_deg(alignment, severity, contact_type)


static func get_line_alignment(attack_line: String, guard_line: String) -> float:
	return _AttackPath.get_line_alignment(attack_line, guard_line)


static func get_attack_angle_deg(attack_line: String, add_variance: bool = true, move_def: Dictionary = {}, variance_context: Dictionary = {}) -> float:
	return _AttackPath.get_attack_angle_deg(attack_line, add_variance, move_def, variance_context)


static func get_guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
	return _AttackPath.get_guard_angle_deg(combatant, wobble_context)


static func get_deflected_line_from_angles(attack_angle_deg: float, guard_angle_deg: float, severity: float, contact_type: String, alignment: float) -> String:
	return _AttackPath.get_deflected_line_from_angles(attack_angle_deg, guard_angle_deg, severity, contact_type, alignment)


static func get_line_alignment_with_deflect(attack_line: String, combatant: Dictionary, alignment_context: Dictionary = {}, wobble_context: Dictionary = {}) -> float:
	return _AttackPath.get_line_alignment_with_deflect(attack_line, combatant, alignment_context, wobble_context)



## Re-export general-purpose constants from CombatConstantsMisc.
const DEFAULT_STAT_VALUE := _Misc.DEFAULT_STAT_VALUE
const MEDICAL_ITEM_TOURNIQUET := _Misc.MEDICAL_ITEM_TOURNIQUET
const PATH_MAIN_SCENE := _Misc.PATH_MAIN_SCENE
const PATH_COUNTER_TEMPO := _Misc.PATH_COUNTER_TEMPO
const SIDE_PLAYER := _Misc.SIDE_PLAYER
const SIDE_ENEMY := _Misc.SIDE_ENEMY

static func clamp_prob(v: float) -> float:
	return _Misc.clamp_prob(v)

static func companion_path(index: int) -> String:
	return _Misc.companion_path(index)

## Map medical target_method + success to outcome string (used by MedicalPhaseController + MedicalWindUpHandler).
static func medical_outcome_string(target_method: String, ok: bool) -> String:
	match target_method:
		MOVE_TARGET_APPLY_BANDAGE:
			return "bandaged" if ok else "bandage_failed"
		MOVE_TARGET_APPLY_STABILIZE:
			return "stabilized" if ok else "stabilize_failed"
		MOVE_TARGET_APPLY_PACKING:
			return "packed" if ok else "packing_failed"
		MOVE_TARGET_APPLY_TOURNIQUET:
			return "tourniquet_applied" if ok else "tourniquet_failed"
		_:
			return ""  # caller falls back to wind_up_cfg.get("outcome", med_id)

## Check if a target_method string matches one of the medical action targets.
static func is_medical_target_method(target_method: String) -> bool:
	return target_method in [
		MOVE_TARGET_APPLY_BANDAGE,
		MOVE_TARGET_APPLY_PACKING,
		MOVE_TARGET_APPLY_STABILIZE,
		MOVE_TARGET_APPLY_TOURNIQUET,
	]
