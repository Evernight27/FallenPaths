class_name CombatConstantsPartC
extends CombatConstantsPartB
const SWAP_RANK_AI_LOW_WEIGHT := 0.02
const SWAP_RANK_AI_HIGH_WEIGHT := 1.0
const SWAP_RANK_AI_LINE_PLUG_WEIGHT := 0.52  # Rear relief when another file has rank-0 hole (III-6 maintain)
const AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT := 0.62  # Skirmish shuffle when line has rank-0 holes (III-6 maintain)
const AI_ROTATE_FILE_WHEN_ENGAGEMENT_LISTED_MULT := 0.35  # Prefer strikes/close over shuffle when both are listed
const AI_ROTATE_FILE_LONG_CLOSE_ONLY_MULT := 1.35  # LONG close-only (no melee) --" shuffle can find angle vs close spam
const AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT := 0.82  # Mapped rank-0 LONG close-only --" rotate can compete
const AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT := 1.28  # Mapped wing out of reach --" close bind beats wait/shuffle
# Menu-listed close when pair gate fails at pick time (fight-finish tail)
const AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT := 0.58
const AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT := 1.4  # Sparse post-flee front --" close to finish beats shuffle
const AI_SPARSE_LINE_OFFENSE_MULT := 1.35  # Listed melee on sparse post-flee front --" fight over focus shuffle
const AI_FOCUS_LINE_SPARSE_ENGAGEMENT_LISTED_MULT := 0.35  # Damp guard retarget when strikes/close are listed
const AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT := 0.45  # Post-flee sparse --" wait below close/strike finish
const AI_WAIT_MOP_UP_FINISH_MULT := 0.4  # Mop-up winner or last-enemy underdog --" finish fight, don't idle
const AI_WAIT_NO_STRIKE_MULT := 0.15  # No hostile strikes listed --" prefer flee over endless wait loop
## Mobile cowering solo **fall_back** vs **wait** (Tier 6.1 --" no arms, legs OK).
const COWERING_SOLO_FALL_BACK_AI_WEIGHT := 1.5
## Tier 6.2: mobile cowering --" prefer **`flee`** over in-formation **`fall_back`** when both are listed (cannot hold
## weapon).
const COWERING_FLEE_AI_WEIGHT := 1.55
const DUEL_DISARMED_YIELD_AI_WEIGHT := 2.2
const DUEL_DISARMED_WAIT_AI_WEIGHT := 1.35
const DUEL_DISARMED_FLEE_AI_WEIGHT := 0.28
## Armed fighters: rout is rare --" well below rotate_file; scaled by `CombatFormationRout.flee_ai_pick_mult` (cohesion
## + casualties).
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
## Exhaustion ramp: as stamina approaches 0%, offense weight drops further (exhausted fighters can still defend but
## should not initiate fresh attacks at full weight).
const AI_STAMINA_ENGAGE_FLOOR_RATIO := 0.20
const AI_STAMINA_ENGAGE_LOW_MULT := 0.85
## Below this stamina ratio, offense weight uses **`AI_STAMINA_DEEP_EXHAUST_MULT`** (near-total exhaustion --" can
## defend but should not initiate).
const AI_STAMINA_DEEP_EXHAUST_RATIO := 0.05
const AI_STAMINA_DEEP_EXHAUST_MULT := 0.40
## Exhaustion cap: below this ratio, offense weight floors at **`AI_STAMINA_EXHAUSTION_DEEP_MULT`** (realistic
## simulation --" exhausted fighters cannot initiate).
const AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD := 0.05
const AI_STAMINA_EXHAUSTION_DEEP_MULT := 0.40
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
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE: Dictionary = (
    _Footwork.DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE
)
const DEFENSE_FOOTWORK_WAITING_DODGE_MULT := _Footwork.DEFENSE_FOOTWORK_WAITING_DODGE_MULT
const AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT := _Footwork.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
const AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT := _Footwork.AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE := (
    _Footwork.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE
)
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG := (
    _Footwork.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG
)
const PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT := _Footwork.PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT
const PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT := _Footwork.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT
const PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT := _Footwork.PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE := _Footwork.FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG := _Footwork.FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG
const REACH_MID_MIN := _CloseSlots.REACH_MID_MIN
const MOVE_ID_ATTEMPT_CLOSE := _CloseSlots.MOVE_ID_ATTEMPT_CLOSE
const SKIP_TURN_LOG_PASS := _CloseSlots.SKIP_TURN_LOG_PASS
const SKIP_TURN_LOG_WAIT := _CloseSlots.SKIP_TURN_LOG_WAIT
const SKIP_TURN_LOG_REJECT := _CloseSlots.SKIP_TURN_LOG_REJECT
const CLOSE_SLOTS_PER_TARGET := _CloseSlots.CLOSE_SLOTS_PER_TARGET
const CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS := _CloseSlots.CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS
const CLOSE_SLOTS_FULL_TARGETING_MULT := _CloseSlots.CLOSE_SLOTS_FULL_TARGETING_MULT
const CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S := _CloseSlots.CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S
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
## III-4 **3e**: pincer flank wing targeting spread damp --" penalizes wide-arc targets by this per-file offset from
## preferred enemy file.
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
const STANCE_MOD_OPPONENT_CLOSE: float = _Stance.STANCE_MOD_OPPONENT_CLOSE
const STANCE_MOD_OPPONENT_DISENGAGE: float = _Stance.STANCE_MOD_OPPONENT_DISENGAGE
const DENSITY_CLOSE_MOD: Dictionary = _Stance.DENSITY_CLOSE_MOD
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
const DEFAULT_STAT_VALUE := _Misc.DEFAULT_STAT_VALUE
const MEDICAL_ITEM_TOURNIQUET := _Misc.MEDICAL_ITEM_TOURNIQUET
const PATH_MAIN_SCENE := _Misc.PATH_MAIN_SCENE
const PATH_COUNTER_TEMPO := _Misc.PATH_COUNTER_TEMPO
const SIDE_PLAYER := _Misc.SIDE_PLAYER
const SIDE_ENEMY := _Misc.SIDE_ENEMY
const BIND_STATE_LIGHT_THRESHOLD := 0.25
const BIND_STATE_MEDIUM_THRESHOLD := 0.50
const BIND_STATE_HARD_THRESHOLD := 0.75
const BIND_PRESSURE_DURATION_S := 6.0
const BIND_PRESSURE_DECAY_RATE := 0.04
const BREATH_BIND_PRESS_COST := 8.0
const BREATH_BIND_VOID_COST := 12.0
const BREATH_BIND_WIND_COST := 5.0
const BIND_ACTION_COOLDOWN_S := 1.5
const LATERAL_STEP_DELTA := 0.2
const ANGULAR_ADVANTAGE_DURATION_S := 4.0


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

## IV-7b: step-down offense engage weight (investigated 2026-05; locked 2026-06-08).
## Exhaustion ramp: as stamina approaches 0%, offense weight drops further --" exhausted fighters can still defend but
## should not initiate fresh attacks at full weight.


## IV-7b: step-down offense engage weight (investigated 2026-05; locked 2026-06-08).
## Exhaustion ramp: as stamina approaches 0%, offense weight drops further --" exhausted fighters can still defend but
## should not initiate fresh attacks at full weight.
static func ai_offense_stamina_weight_mult(stamina_ratio: float) -> float:
    if stamina_ratio >= AI_STAMINA_ENGAGE_FLOOR_RATIO:
        return 1.0
    var w: float = AI_STAMINA_ENGAGE_LOW_MULT
    if stamina_ratio <= AI_STAMINA_DEEP_EXHAUST_RATIO:
        w = AI_STAMINA_DEEP_EXHAUST_MULT
    elif stamina_ratio < AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD:
        w = lerpf(
            AI_STAMINA_EXHAUSTION_DEEP_MULT,
            AI_STAMINA_ENGAGE_LOW_MULT,
            stamina_ratio / maxf(AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD, 0.001)
        )
    return w


static func iv7b_stamina_engage_doc_sync_line() -> String:
    return (
        "IV-7b engage floor: ratio<%.2f -> offense_mult=%.2f"
        % [AI_STAMINA_ENGAGE_FLOOR_RATIO, AI_STAMINA_ENGAGE_LOW_MULT]
    )


## Partner must exceed our composite fitness (perf ff -  blood norm) by at least this much for a routine relief.

## Tier 1.9: canonical + optional alt string keys on a dict (**`strip_edges`** each); non-empty canonical wins.


## Tier 1.9: canonical + optional alt string keys on a dict (**`strip_edges`** each); non-empty canonical wins.
static func formation_doctrine_string_from_dict(source: Dictionary, primary_key: String, alt_key: String) -> String:
    var s: String = source.get(primary_key, "").strip_edges()
    if s.is_empty():
        s = source.get(alt_key, "").strip_edges()
    return s


## Tier 1.9: encounter doctrine seed --" delegates to **`formation_doctrine_string_from_dict`**.


## Tier 1.9: encounter doctrine seed --" delegates to **`formation_doctrine_string_from_dict`**.
static func encounter_formation_doctrine_string(encounter: Dictionary, primary_key: String, alt_key: String) -> String:
    return formation_doctrine_string_from_dict(encounter, primary_key, alt_key)


## Tier 1.9: baseline depth-spear **doctrine** mults (encounter / preset may override via
## **`merge_depth_polearm_ai_doctrine_mults`**).


## Tier 1.9: baseline depth-spear **doctrine** mults (encounter / preset may override via
## **`merge_depth_polearm_ai_doctrine_mults`**).
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


## Encounter side keys --'' ' optional preset overlay (preset wins per field). Empty dict --'' ' use
## **`FORMATION_FLEE_*`** defaults.


## Encounter side keys --'' ' optional preset overlay (preset wins per field). Empty dict --'' ' use
## **`FORMATION_FLEE_*`** defaults.
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
        out[ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX] = clampf(float(encounter[enc_coh_key]), 0.05, 0.95)
    if encounter.has(enc_cas_key):
        out[ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN] = clampf(float(encounter[enc_cas_key]), 0.05, 0.90)
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


static func max_close_slots_for_density(density: String) -> int:
    return _CloseSlots.max_close_slots_for_density(density)


## Formation doctrine for hybrid targeting (CombatDoctrine / CombatTargetScoring).

## **Harness-only alias:** see LIVE_PATHS WF-M5. Do not add new production call sites.


## **Harness-only alias:** see LIVE_PATHS WF-M5. Do not add new production call sites.
static func get_stance_modifier(stance: String, effect: String) -> float:
    return _Stance.get_stance_modifier(stance, effect)


static func get_density_close_mod(density: String) -> float:
    return _Stance.get_density_close_mod(density)


static func get_spacing_from_density(density: String) -> float:
    return _Stance.get_spacing_from_density(density)


## Re-export attack path tables and geometry from **`CombatConstantsAttackPath`**.
## Maintain canonical values in the sub-module, not here.


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


static func get_deflected_angle_bilateral(
    attack_angle_deg: float, guard_angle_deg: float, magnitude_deg: float
) -> float:
    return _AttackPath.get_deflected_angle_bilateral(attack_angle_deg, guard_angle_deg, magnitude_deg)


static func get_deflection_magnitude_deg(alignment: float, severity: float, contact_type: String) -> float:
    return _AttackPath.get_deflection_magnitude_deg(alignment, severity, contact_type)


static func get_line_alignment(attack_line: String, guard_line: String) -> float:
    return _AttackPath.get_line_alignment(attack_line, guard_line)


static func get_attack_angle_deg(
    attack_line: String, add_variance: bool = true, move_def: Dictionary = {}, variance_context: Dictionary = {}
) -> float:
    return _AttackPath.get_attack_angle_deg(attack_line, add_variance, move_def, variance_context)


static func get_guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
    return _AttackPath.get_guard_angle_deg(combatant, wobble_context)


static func get_deflected_line_from_angles(
    attack_angle_deg: float, guard_angle_deg: float, severity: float, contact_type: String, alignment: float
) -> String:
    return _AttackPath.get_deflected_line_from_angles(
        attack_angle_deg, guard_angle_deg, severity, contact_type, alignment
    )


static func get_line_alignment_with_deflect(
    attack_line: String, combatant: Dictionary, alignment_context: Dictionary = {}, wobble_context: Dictionary = {}
) -> float:
    return _AttackPath.get_line_alignment_with_deflect(attack_line, combatant, alignment_context, wobble_context)


## Re-export general-purpose constants from CombatConstantsMisc.


static func clamp_prob(v: float) -> float:
    return _Misc.clamp_prob(v)


static func companion_path(index: int) -> String:
    return _Misc.companion_path(index)


## Map medical target_method + success to outcome string (used by MedicalPhaseController + MedicalWindUpHandler).


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
## Bind pressure: thresholds, durations, costs (CombatBindPressure.gd).

## Check if a target_method string matches one of the medical action targets.


## Check if a target_method string matches one of the medical action targets.
static func is_medical_target_method(target_method: String) -> bool:
    return (
        target_method
        in [
            MOVE_TARGET_APPLY_BANDAGE,
            MOVE_TARGET_APPLY_PACKING,
            MOVE_TARGET_APPLY_STABILIZE,
            MOVE_TARGET_APPLY_TOURNIQUET,
        ]
    )
