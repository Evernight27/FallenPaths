class_name CombatConstantsPartB
extends CombatConstantsPartA
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
## Pack / protection-circle fallback: flank parry mod when `effective_pair_file_spacing_equivalent` --''deg'' this (Tier
## 3.1 --" wedge/lane-aware; matches integer |f"file|--''deg''2 at default spacing).
const PARRY_FLANK_EFFECTIVE_FILES_MIN := 2.0
## Abstract strike **measure**: `melee_range / max(effective_pair_eff_dist, floor)` then clamp (Tier 3.1 --"
## `CombatStrikeStamping.strike_measure_ratio_*`, `StrikeRealismProfile.measure_ratio`).
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
## Lane stress fills only headroom above global incursion (same 0..INCURSION_PRESSURE_MAX scale) --" avoids
## double-counting with global rank-delta.
const INCURSION_LANE_HEADROOM_FACTOR := 0.88
## Local lane stress 0..1 from formation (dual living in a cell, density). Not slot_obstacles --" those stay in
## ZOC_CASUALTY_PER_BODY only.
const LANE_STRESS_DUAL_LIVING := 0.42
const LANE_STRESS_DENSITY_TIGHT := 0.12
const LANE_STRESS_DENSITY_LOOSE := -0.07
## --- Tier 1.3 P4 freeze: `lane_stress_by_file` + `lane_offset` ---
## **`lane_stress_by_file`**: per-formation file --'' ' 0..1 stress from dual occupancy + density
## (`TacticalCombat._recompute_lane_stress_by_file`).
## **`lane_offset`**: per-combatant float; **lateral offset within the nominal file column** feeding
## `CombatPairGeometry.effective_pair_eff_dist` (`EFF_DIST_LANE_OFFSET_FILE_EQUIV`). **Range:** clamp every writer/read
## to **`[-LANE_OFFSET_ABS_MAX, LANE_OFFSET_ABS_MAX]`** (currently **[-0.5, 0.5]**). **0** = column center. **Sign:**
## **positive** = toward **increasing file index** (+file / --..."enemy-right--'? on default symmetric grids).
## `CombatFormationFlow.repack_lane_offset_after_rank_file_change` + `CombatManager.register` defaults must stay inside
## this interval.
## Vacancy reconcile: lateral slides can open a hole in a neighbor file; repeat until stable (safety cap).
const FORMATION_VACANCY_RECONCILE_MAX_ROUNDS := 16
## Inner promotion chain per file per vacancy/death plug pass (one rank step + restart shallow scan per iteration).
const FORMATION_VACANCY_MICRO_STEPS_MAX := 24
## After an automatic vacancy/death plug moves a unit, that unit cannot be chosen as a plug donor again until this many
## seconds of `combat_clock` elapse (damps tick-by-tick lateral / chain thrash; abstract, not a long --..."realistic--'?
## delay).
const FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S := 0.35
## Vacancy **lateral** slide: block immediately sliding back (hole reopens in donor file) across ticks. Pass-local meta
## alone cannot stop this because reconcile runs every frame + get_available_actions.
const FORMATION_VACANCY_LATERAL_REVERSE_LOCK_S := 1.2
## Plug priority: `pow(effectiveness_0_1, EXPONENT) * 1/(1 + PROXIMITY_WEIGHT * step_count)`. Higher EXPONENT makes
## injured fighters fall off nonlinearly so fitter units in other lanes/ranks can win despite extra steps.
const FORMATION_PLUG_EFFECTIVENESS_EXPONENT := 2.6
## Larger = proximity matters less relative to effectiveness (able-bodied farther can override closer wounded).
const FORMATION_PLUG_PROXIMITY_WEIGHT := 0.28
## When false (default), per-move Vacancy plug / death Plug `[Combat]` lines are suppressed; keeps logs usable with
## `COMBAT_EVENT_DEBUG` on.
const COMBAT_FORMATION_PLUG_MOVE_DEBUG := false
## When true, logs vacancy promotions and rank-0 holes still empty after reconcile (independent of
## `COMBAT_EVENT_DEBUG`).
const COMBAT_FORMATION_VACANCY_DEBUG := false
## Extra priority score for filling **rank 0** holes so the front line closes before lateral shuffles when scores tie.
const FORMATION_PLUG_RANK0_URGENCY_BONUS := 0.75
## Added to `READY_DELAY_AFTER_PROMOTION_S` per file of horizontal travel when a **rear** rank plugs a rank-0 hole from
## another file (reserves sidestep before stepping up; front rank no longer shuffles sideways first).
const FORMATION_PLUG_REAR_CROSS_FILE_READY_PER_FILE_S := 0.18
## Per-combatant lateral metric --" see **Tier 1.3 P4 freeze** block above (f''Sec4.2).
const LANE_OFFSET_DEFAULT := 0.0
const LANE_OFFSET_ABS_MAX := 0.5
## effective_pair_eff_dist: |f"lane_offset| as fraction of a file spacing equivalent before ZoC mult.
const EFF_DIST_LANE_OFFSET_FILE_EQUIV := 0.42
## `CombatDistanceBands`: MID vs LONG uses `effective_pair_file_spacing_equivalent` vs `mid_reach_files`; slack avoids
## float edge flicker with lane_offset.
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
const AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT := (
    _FeatureFlags.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
)
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
const TACTICAL_PENETRATION_DEPTH_MAX := 2
## Extra damp when this side has very few standing fighters (duel / skirmish attrition).
const AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT := 0.72
## Tier 1.6 (P7): `CombatTargetScoring.ai_targeting_weight_mult` --" melee/close: resolved **`engagement_mode`**, our
## posture+cohesion + **opponent** formation, stance.
const AI_TARGETING_LINE_COH_LO_MULT := 0.94
const AI_TARGETING_LINE_COH_HI_MULT := 1.03
const AI_TARGETING_OPEN_COH_TIGHT_MULT := 1.0
const AI_TARGETING_OPEN_COH_LOOSE_MULT := 1.06
## Tier 1.6 breadth: hostile pick vs **opponent** LINE `line_cohesion` (solid enemy wall --'' ' slight hedge; ragged
## --'' ' press).
const AI_TARGETING_OPP_LINE_COH_SOLID_MULT := 0.96
const AI_TARGETING_OPP_LINE_COH_RAGGED_MULT := 1.04
## Dispersed enemy posture (OPEN/DUEL) --" small isolation / pick-off nudge.
const AI_TARGETING_OPP_OPEN_DUEL_MULT := 1.03
## Tier 1.6 / 1.7: resolved `CombatEngagementMode.engagement_mode` on listed hostile weights (`CombatTargetScoring`).
const AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT := 1.04
const AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT := 1.0
const AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT := 1.025
## Tier 1.6: `hostile_pair_targeting_weight_mult` scales down listed hostile picks vs **incapacitated** defenders (still
## valid targets if actions list them).
const AI_TARGETING_INCAP_HOSTILE_MULT := 0.42
## AI targeting bonus for opponents performing a medical wind-up (vulnerable, worth interrupting).
const AI_TARGETING_MEDICAL_WIND_UP_MULT := 1.6
## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** --" **`WeaponConstants.is_feint_move(move_id)`** hostile
## attacks get this multiplier (AI listing only).
const AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT := 1.06
## Tier 4.2: on top of **`AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`**, feint hostile weights scale by **`lerpf(1.0, this,
## pr_def)`** where **`pr_def`** = **`clampf(get_passive_parry_readiness ff -
## passive_parry_readiness_incoming_contact_mult ff -
## defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio), 0, 1)`** on the defender (WAITING uses
## **`guard`**).
const AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT := 1.10
## Tier 4.2: when attacker **`stamina_ratio` < `AI_FEINT_LISTING_STAMINA_GATE`**, multiply feint listing only by
## **`lerpf(AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO, 1.0, stamina_ratio / gate)`** (gassed attackers list feints
## less).
const AI_FEINT_LISTING_STAMINA_GATE := 0.30
const AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO := 0.86
## Tier 4.2: formation **`doctrine`** **`probing`** --" multiply feint-move listing weight only
## (**`CombatDoctrine.doctrine_for_fid`** on attacker **`formation_id`**).
const AI_FEINT_LISTING_DOCTRINE_PROBING_MULT := 1.04
## Tier 4.2: formation **`doctrine`** **`pinch_center`** --" feint listing nudge (inward-pressure doctrine; AI listing
## only).
const AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT := 1.03
## Tier 4.2: formation **`doctrine`** **`hold_lane`** --" feint listing dampen (disciplined line; AI listing only).
const AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT := 0.97
## Tier 4.2: after defender **`parry_deflect`**, feint-move listing vs that defender scales up to this mult while
## **`CombatManager.get_combat_tick_index() - stored_tick --''deg'' AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS`**
## (then lerps to **1**).
const AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT := 1.05
## Tier 4.2: combat ticks over which **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT`** lerps back to **1**
## after a **`parry_deflect`** (see **`CombatProcessTick`**).
const AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS := 8
## Tier 4.2: defender **`PassiveParryContext.is_off_balance`** while **`STATE_WAITING`** --" multiply feint-move listing
## vs that defender (footwork / tempo).
const AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT := 1.06
## Tier 1.9 (P10): depth rank + open spear lane --" AI favors thrusts over cuts/closes (CombatAIActionPicker).
const DEPTH_POLEARM_AI_STAB_WEIGHT_MULT := 1.35
const DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT := 0.9
const DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT := 0.82
## Tier 1.9: depth rank + open lane --" formation **`doctrine`** scales stab vs cut listing weights
## (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
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
## Tier 1.9: max(pressure, depth) at this file --''deg'' this --'' ' depth spear may target legs even when density is
## tight/normal (wedge gap).
const DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN := 0.38
## Alias for lane-stress open threshold (`CombatDepthPolearm`, post--"intrusion removal).
const DEPTH_SPEAR_LANE_STRESS_OPEN_MIN := DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN
## Tier 3.1: depth spear **over-shoulder** lane (`depth_polearm_allows_low_targets` false) --" defender parry capacity
## vs that thrust line.
const DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT := 1.06
## Tier 3.1: depth spear **open** lane + stab --" attacker momentum seen at parry (full high/low envelope).
const DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT := 1.05
## Tier 3.1: depth rank stab through an open spear lane --" closing-speed proxy (`StrikePhysics`, `AttackResolver` ctx).
## Tight (**`over_shoulder`**) lane depth stabs use neutral **1.0** in
## `StrikePhysics.depth_polearm_thrust_closing_factor` (no extra closing bonus vs open).
const DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT := 1.03
## Tier 1.9 / 3.1: `pa["depth_polearm_lane_type"]` when **`depth_polearm_attack`** (empty string when not depth
## polearm). Mirrors **`depth_polearm_allows_low_targets`** for consumers that prefer a string lane id.
const DEPTH_POLEARM_LANE_TYPE_OPEN := "open"
const DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER := "over_shoulder"
## Formation dict `spear_lane_profile` preset key + normalized values (`CombatFormationSetup` /
## `CombatDepthPolearm.depth_polearm_lane_allows_low_targets`).
const FORMATION_KEY_SPEAR_LANE_PROFILE := "spear_lane_profile"
## Optional on **`CombatManager.start(player_formation, enemy_formation)`** preset dicts: wins over encounter doctrine
## for that side (same normalize path as **`set_formation_doctrine`**). Canonical key
## **`FORMATION_PRESET_KEY_DOCTRINE`**; if empty after strip, **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**.
const FORMATION_PRESET_KEY_DOCTRINE := "formation_doctrine"
## Short preset alias when **`FORMATION_PRESET_KEY_DOCTRINE`** is missing or whitespace-only.
const FORMATION_PRESET_KEY_DOCTRINE_ALT := "doctrine"
## Tier 6.2: optional rout gates on **`start()`** preset dict --" wins over encounter **`ENCOUNTER_KEY_FLEE_*`** for
## that side.
const FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX := "flee_line_cohesion_max"
const FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN := "flee_casualty_ratio_min"
## Keys on **`CombatManager.rout_thresholds_by_fid`** merged at **`start()`** (read by **`CombatFormationRout`**).
const ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX := "flee_line_cohesion_max"
const ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN := "flee_casualty_ratio_min"
const SPEAR_LANE_PROFILE_AUTO := ""
const SPEAR_LANE_PROFILE_OPEN := "open"
const SPEAR_LANE_PROFILE_RESTRICTED := "restricted"
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
## Option 4 pilot: `CombatDoctrine.evaluate_automatic_doctrine` may set **`pinch_center`** from a hollow enemy front
## (only when formation doctrine is still **default**).
const FEATURE_AUTOMATIC_DOCTRINE := _FeatureFlags.FEATURE_AUTOMATIC_DOCTRINE
## p4c: min extra living rank-0 on our front vs opponent when our formation has more files
## (`numeric_superiority_for_pinch`).
const AUTO_DOCTRINE_NUMERIC_SUPERIORITY_FRONT_MARGIN := 1
## S6 pilot: layer KE budget scales pre-armor damage (sqrt curve); default off --" see `ArmorJouleBudget`.
const FEATURE_JOULE_ARMOR_BUDGET := _FeatureFlags.FEATURE_JOULE_ARMOR_BUDGET
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
## Per-side attrition AI damp when this side has at most this many actives
## (`CombatAIActionPicker._attrition_offense_weight_mult`).
const AI_ATTRITION_LOW_STANDING_MAX := 2
## Formation requires both sides at/above this active count in addition to front/fill thresholds.
const ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE := 4
## III-4 Track A **3b**: Skirmish **`rotate_file`** only when `our_files > opp_files + margin`.
const SKIRMISH_ROTATE_OUTNUMBER_FILE_MARGIN := 1
## FORMATION requires at least this many effective front fighters per side.
const FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE := 2
## FORMATION also requires this minimum front-fill ratio per side: front_alive / formation.files.
const FORMATION_MIN_FRONT_FILL_RATIO := 0.67
## Hysteresis leave threshold for FORMATION: stay in formation mode until line thins below this (prevents mode jitter
## near thresholds).
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
## LINE--'' "OPEN hysteresis (Tier 1.4): cohesion must reach **L_in** to flip OPEN--'' 'LINE; must fall below **L_out**
## to flip LINE--'' 'OPEN (`L_in` > `L_out`).
const LINE_COHESION_POSTURE_ENTER_LINE_MIN := 0.62
const LINE_COHESION_POSTURE_LEAVE_LINE_BELOW := 0.50
## When **> 0**, each side--'"'s `L_in`/`L_out` shift from **relative** cohesion vs the opponent (`delta = strength *
## (our_coh - opp_coh)`):
## stronger line --'' ' easier LINE (lower `L_in`, higher `L_out`); weaker --'' ' easier OPEN. Set encounter
## `posture_asymmetry_strength` to **0** to disable.
const POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH := 0.12
## Combatant engagement role.
const ENGAGEMENT_ROLE_LINE := "line"
## Cohesion = (COHESION_BASE_FLOOR + COHESION_FILL_SCALE * front_fill) * (1 - COHESION_LANE_STRESS_WEIGHT *
## avg_lane_stress) * morale_cohesion_factor
const COHESION_LANE_STRESS_WEIGHT := 0.45
## Floor for `morale_cohesion_factor` (matches `CombatFormationEngagement` clamp).
const MORALE_COHESION_FACTOR_MIN := 0.15
const COHESION_BASE_FLOOR := 0.35
const COHESION_FILL_SCALE := 0.65
## Optional `line_discipline` tag on **encounter** or **formation preset** (formation wins): shifts hysteresis band for
## testing / data.
const LINE_DISCIPLINE_STRICT := "strict"
const LINE_DISCIPLINE_NORMAL := "normal"
const LINE_DISCIPLINE_LOOSE := "loose"
const FORMATION_RETREAT_BLOOD_VOLUME_MAX := 85.0
## Abandon-field **flee** (rout): Class III+ personal crisis (~45% lost) or immediate bleed-out --" not --..."step back
## in the file.--'?
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
## Wounded + stressed rout blocked when this side still has --''deg'' this ff -  opponent standing (tactical win --"
## hold the field).
const FORMATION_FLEE_WINNING_STANDING_RATIO := 1.15

## Strike move IDs (wind-up / stamina cost tiers).
const MOVE_ID_QUICK := "quick"
const MOVE_ID_MEDIUM := "medium"
const MOVE_ID_HEAVY := "heavy"
const MOVE_ID_FEINT := "feint"

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
## Tier 4.4: attacker step-on-wind-up lateral angle nudge (degrees). Cleared via
## **`CombatFootwork.clear_on_exchange_end`** on resolve, abort, recovery, combat start, death (not left on idle
## **`waiting`** reserve).
const COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG := "position_angle_offset_deg"
## Tier 4.4.3: row label fragment when footwork enabled (`Step`, no degrees); UI only in **`wind_up`** /
## **`recovering`**.
const COMBATANT_KEY_POSITION_ANGLE_UI_HINT := "position_angle_ui_hint"
## Player turn-ready: aggregated duration hints from listed formation moves (see
## **`CombatPlayerTurnHints.sync_formation_listed_turn_hint`**).
const COMBATANT_KEY_FORMATION_MOVES_TURN_HINT := "formation_moves_turn_hint"
## Stamped on turn-ready when listed actions are only wait + guard/focus lines (depth rank hold).
const COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT := "hold_line_focus_only_hint"
## Player turn-ready: **`attempt_close`** listed vs controlling defender (gauge + combat log).
const COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT := "controlling_close_turn_hint"
## L4 pilot: when eight-guard flag on, **`CombatGuardLines.position_angle_offset_deg_for_line`** uses octant table.
## LIVE_PATHS **`#wf-form-guard-pa-matrix`**.
## Tier 4.4.2: defender step scales (symmetric to attacker step-on-wind-up; still flag-gated).
## WF-T1 (2026-06-07): Camp-5 soak confirms parry 0.55 / dodge 0.85 --" tune octant raw table first.
const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY := 0.55
const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE := 0.85


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

## Re-export attack path helpers.


## Re-export attack path helpers.
static func _iv6_diagonal_attack_path(
    flank_path: Array, vert_path: Array, guard_oct: String, zone_part: String
) -> Array:
    return _AttackPath._iv6_diagonal_attack_path(flank_path, vert_path, guard_oct, zone_part)


## Re-export guard transition constants.


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


static func stamina_factor(ratio: float) -> float:
    return _Stamina.stamina_factor(ratio)


static func breath_factor(ratio: float) -> float:
    return _Stamina.breath_factor(ratio)


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


## Re-export parry redirect and helper functions.
static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
    return _Parry.commitment_fraction_for_pending_attack(pa)


static func stats_factor_agi_perc(agi: float, perc: float) -> float:
    return _Parry.stats_factor_agi_perc(agi, perc)


static func glancing_factor(ratio: float, exponent: float = PARRY_GLANCING_EXPONENT) -> float:
    return _Parry.glancing_factor(ratio, exponent)


static func compute_parry_redirect_mult(
    pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float
) -> float:
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
    return _Parry.parry_control_for_bind_deflect(
        c_d_final, parry_p_a, alignment, parry_readiness, parry_off_balance, late_parry, contact_type
    )


## Re-export event queue constants.


static func parry_telegraph_contact_mult(contact_type: String) -> float:
    return _ParryChoice.parry_telegraph_contact_mult(contact_type)


static func is_feature_ambient_pain_shock() -> bool:
    return _FeatureFlags.is_feature_ambient_pain_shock()


static func set_feature_ambient_pain_shock(on: bool) -> void:
    _FeatureFlags.set_feature_ambient_pain_shock(on)


## Re-export formation move constants and helpers from CombatConstantsFormationMove.


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


static func is_joule_armor_budget_active() -> bool:
    return FEATURE_JOULE_ARMOR_BUDGET


## **Dev:** After `CombatManager.start`, `BattleScene` re-equips combatants with **rank > 0** with `SPEAR` (formations
## unchanged --" same `FormationPreset.default_for_count` as usual). Set **true** only for depth-polearm / spear-lane
## debugging.

## Extra (f" enter threshold, f" leave threshold) from `line_discipline_posture_extra_deltas` --" strict = stickier LINE
## (higher both).


## Extra (f" enter threshold, f" leave threshold) from `line_discipline_posture_extra_deltas` --" strict = stickier LINE
## (higher both).
static func line_discipline_posture_extra_deltas(discipline: String) -> Vector2:
    var d: String = str(discipline).strip_edges().to_lower()
    if d == LINE_DISCIPLINE_STRICT:
        return Vector2(0.03, 0.04)
    if d == LINE_DISCIPLINE_LOOSE:
        return Vector2(-0.03, -0.04)
    return Vector2.ZERO


## Rank-0 self `fall_back` into an **empty** same-file rear slot: only `loose`. Strict/normal/empty require paired
## swap/drag/fall_back_pair (replacement in file).


## Rank-0 self `fall_back` into an **empty** same-file rear slot: only `loose`. Strict/normal/empty require paired
## swap/drag/fall_back_pair (replacement in file).
static func line_discipline_allows_solo_fall_back(discipline: String) -> bool:
    return str(discipline).strip_edges().to_lower() == LINE_DISCIPLINE_LOOSE


## Paired disengage (swap_rank / drag / fall_back to rear) and solo fall_back: require real injury (blood this low, no
## usable arm, or immediate peril) --" not low stamina / composite fitness alone.
## ~85 = ATLS Class II (~15% blood lost): wounded, may seek rear rank --" not first-cut nuisance (was 94 / ~6%, too
## eager).


static func position_angle_defender_offset_deg_for_line(line: String, scale: float) -> float:
    return position_angle_offset_deg_for_attack_line(line) * scale
