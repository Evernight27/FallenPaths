class_name CombatConstantsEncounter
extends RefCounted

const AMBUSH_TYPE_NONE := "none"
const AMBUSH_TYPE_FULL := "full"
const AMBUSH_TYPE_PARTIAL := "partial"
const ENCOUNTER_KEY_POSTURE_ENTER_DELTA := "engagement_posture_enter_delta"
const ENCOUNTER_KEY_POSTURE_LEAVE_DELTA := "engagement_posture_leave_delta"
const ENCOUNTER_KEY_LINE_DISCIPLINE := "line_discipline"
const ENCOUNTER_KEY_POSTURE_ASYMMETRY_STRENGTH := "posture_asymmetry_strength"
const ENCOUNTER_KEY_MORALE_COHESION_PLAYER := "morale_cohesion_player"
const ENCOUNTER_KEY_MORALE_COHESION_ENEMY := "morale_cohesion_enemy"
const ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER := "flee_line_cohesion_max_player"
const ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY := "flee_line_cohesion_max_enemy"
const ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER := "flee_casualty_ratio_min_player"
const ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY := "flee_casualty_ratio_min_enemy"
const ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER := "formation_doctrine_player"
const ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY := "formation_doctrine_enemy"
const ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT := "doctrine_player"
const ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT := "doctrine_enemy"
const ENCOUNTER_KEY_PLAYER_FORMATION := "player_formation"
const ENCOUNTER_KEY_PLAYER_FRONT_COUNT := "player_front_count"
const ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM := "player_default_weapon_form"
const ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM := "enemy_default_weapon_form"
const WF_FORM_SWITCH_COOLDOWN_S := 8.0
const WF_FORM_SWITCH_STAMINA_COST := 0.0

## C3: Form switch transition timing and costs.
const FORM_SWITCH_BASE_DURATION_S := 0.3
const FORM_SWITCH_ANGULAR_SCALE_S := 0.00667
const FORM_SWITCH_MAX_DURATION_S := 1.5
const FORM_SWITCH_BIND_PENALTY_MULT := 1.3
const FORM_SWITCH_SAME_CARDINAL_BONUS_MULT := 0.85
const FORM_SWITCH_BASE_STAMINA_COST := 2.0
const FORM_SWITCH_ANGULAR_STAMINA_SCALE := 6.0
const FORM_SWITCH_PARRY_READINESS_START := 0.3
const FORM_SWITCH_PARRY_READINESS_END := 0.85
const FORM_SWITCH_DODGE_PENALTY_START := 0.4
const FORM_SWITCH_SHORT_RECOVERY_S := 0.3
const FORM_SWITCH_COUNTER_TEMPO_BONUS_MULT := 1.25
const WF_YOMI_FORM_INFERENCE_MIN_OBS := 4
const WF_YOMI_FORM_INFERENCE_MARGIN := 0.15
const WF_YOMI_FORM_PRIORS: Dictionary = {
    "balanced": 3.0,
    "ox": 2.5,
    "wall": 2.0,
    "plow": 1.8,
    "wrath": 1.2,
    "fool": 1.0,
    "tempest": 0.5,
}
const WF_YOMI_STALENESS_RECENT_WINDOW: int = 5
const WF_YOMI_FORM_INFERENCE_MIN_SIGNAL_AGREEMENT: int = 2
const WF_FORM_COUNTER_MULT_CAP := 1.15
const WF_COUNTER_READINESS_NUDGE_MIN := 0.03
const WF_COUNTER_READINESS_NUDGE_MAX := 0.06
const WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD := 0.12
const WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD := 0.15
const WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD := 0.10
const WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD := 0.05
const WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD := 0.08
const AI_FOCUS_LINE_FORM_PREFERRED_MULT := 1.25

## A2 Meisterhäue: decisive counter-strikes scale counter bonus by this factor (yomi-intent aware).
## Values < 1.0 reduce the effective counter mult; tuned so meisterhau is risky without yomi commitment.
const A2_MEISTERHAU_CONFIDENCE_SCALE_FACTOR: float = 0.75

## Phase 2: Counter-read gating constants.
const COUNTER_READ_SAME_PRESSURE_BONUS: float = 1.0
const COUNTER_READ_NEUTRAL_TO_AGGRESSIVE_MIN_CONFIDENCE: float = 0.65
const COUNTER_READ_AGGRESSIVE_TO_DEFENSIVE_MIN_CONFIDENCE: float = 0.75
const COUNTER_READ_NEUTRAL_TO_CONTROLLING_MIN_CONFIDENCE: float = 0.45
const COUNTER_READ_NEUTRAL_TO_DEFENSIVE_MIN_CONFIDENCE: float = 0.60
const COUNTER_READ_AGGRESSIVE_TO_CONTROLLING_MIN_CONFIDENCE: float = 0.65
const COUNTER_READ_CONTROLLING_TO_AGGRESSIVE_MIN_CONFIDENCE: float = 0.5
const COUNTER_READ_CONTROLLING_TO_DEFENSIVE_MIN_CONFIDENCE: float = 0.75
const COUNTER_READ_CONTROLLING_TO_NEUTRAL_MIN_CONFIDENCE: float = 0.5
const COUNTER_READ_AGGRESSIVE_TO_NEUTRAL_MIN_CONFIDENCE: float = 0.5
const COUNTER_READ_DEFENSIVE_TO_AGGRESSIVE_MIN_CONFIDENCE: float = 0.75
const COUNTER_READ_DEFENSIVE_TO_CONTROLLING_MIN_CONFIDENCE: float = 0.5
const COUNTER_READ_DEFENSIVE_TO_NEUTRAL_MIN_CONFIDENCE: float = 0.75
const COUNTER_READ_MIN_CONFIDENCE_NO_OBSERVATIONS: float = 0.2
const WF_YOMI_OBS_LOW_THRESHOLD: int = 5
const WF_YOMI_OBS_MED_THRESHOLD: int = 7
const WF_YOMI_OBS_LOW_CONFIDENCE: float = 0.3
const WF_YOMI_OBS_MED_CONFIDENCE: float = 0.6
const WF_YOMI_OBS_HIGH_CONFIDENCE: float = 0.85
const COUNTER_READ_COMMITMENT_DURATION_TICKS: int = 3
const OVERCOMMIT_PARRY_DEFLECT_PENALTY: float = 0.7

## Phase 2: Counter-read outcome tracking key. Max entries kept in history to prevent unbounded growth.
const COUNTER_READ_HISTORY_MAX_ENTRIES: int = 50
const COMBATANT_KEY_COUNTER_READ_HISTORY: String = "counter_read_history"
const COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL: String = "counter_read_committed_until"
const ENCOUNTER_PROTECTION_CIRCLE_ACTIVE := "protection_circle_active"
const ENCOUNTER_AMBUSHED_SIDE := "ambushed_side"
const WORLD_META_COMBAT_ENCOUNTER := "combat_encounter"
