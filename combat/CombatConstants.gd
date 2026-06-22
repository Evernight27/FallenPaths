class_name CombatConstants
extends RefCounted

const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Combat tuning constants. Single source for CombatManager and AttackResolver.
## Reduces CombatManager from ~150 lines of constants to references.

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

# Attack state machine
const STATE_WAITING := "waiting"
const STATE_WIND_UP := "wind_up"
const STATE_MEDICAL_WIND_UP := "medical_wind_up"
const STATE_RECOVERING := "recovering"
const STATE_RECEIVING_MEDICAL_ATTENTION := "receiving_medical_attention"
const STATE_COWERING := "cowering"
const STATE_FLED := "fled"
const STATE_DEAD := "dead"

# Power and follow_through (0.2–1.0 each); intensity drives velocity, wind-up, recovery.
const POWER_MIN := 0.2
const POWER_MAX := 1.0
const FOLLOW_THROUGH_MIN := 0.2
const FOLLOW_THROUGH_MAX := 1.0
const INTENSITY_MIN := 0.2

# Timing
const WIND_UP_BASE_S := 0.25
const WIND_UP_SCALE_S := 0.6
const RECOVERY_BASE_S := 0.2
const RECOVERY_COMMITMENT_SCALE_S := 0.5
const RECOVERY_EXTRA_HIT_S := 0.0
## Outcome `negligible` (contact with sub-threshold rounded HP chip): slightly shorter recovery than a counted hit.
const RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S := -0.06
const RECOVERY_EXTRA_DEFLECTED_BASE_S := 0.1
const RECOVERY_DEFLECT_MOMENTUM_SCALE_S := 0.15
const RECOVERY_EXTRA_GLANCING_BASE_S := 0.12
const RECOVERY_GLANCING_SEVERITY_SCALE_S := 0.2
const RECOVERY_EXTRA_MISS_BASE_S := 0.35
const RECOVERY_MISS_COMMITMENT_SCALE_S := 0.9
const RECOVERY_EXTRA_FULL_STOP_BASE_S := 0.5
const RECOVERY_FULL_STOP_COMMITMENT_SCALE_S := 0.35
const WINDUP_LEG_MIN := 0.2
## Hard cap on committed attack wind-up after guard transition, injury, and feint mults (UI / harness bound).
const WIND_UP_DURATION_MAX_S := 2.4
const RECOVERY_AFTER_MEDICAL_S := 0.5

# Miss/hit/glancing
const MISS_CHANCE_BASE := 0.06
const HIT_CHANCE_PERCEPTION_MIN := 0.8
const HIT_CHANCE_PERCEPTION_MAX := 1.2
const GLANCING_DAMAGE_RATIO := 0.25
## Sum of final cut+blunt+bone at or below this is treated as no physical damage (outcome + UI).
const PHYSICAL_DAMAGE_ZERO_EPS := 1e-4

# Intensity
const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 100.0
const INTENSITY_STRENGTH_BIAS := 0.35
const INTENSITY_RANDOM_RANGE := 0.2

# Medical move IDs (canonical strings — use MOVE_ID_*, not literals)
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
	return str(move_id) in MEDICAL_MOVE_IDS


static func is_direct_pressure_move(move_id: String) -> bool:
	return str(move_id) == MOVE_ID_APPLY_DIRECT_PRESSURE


static func is_wind_up_medical_move(move_id: String) -> bool:
	return is_medical_move(move_id) and not is_direct_pressure_move(move_id)


const DRESSING_MEDICAL_MOVE_IDS: Array[String] = [
	MOVE_ID_BANDAGE_SELF, MOVE_ID_PACK_WOUND, MOVE_ID_STABILIZE_WOUND
]


static func is_dressing_medical_move(move_id: String) -> bool:
	return str(move_id) in DRESSING_MEDICAL_MOVE_IDS


static func is_tourniquet_move(move_id: String) -> bool:
	return str(move_id) == MOVE_ID_APPLY_TOURNIQUET


static func is_pack_wound_move(move_id: String) -> bool:
	return str(move_id) == MOVE_ID_PACK_WOUND


static func is_stabilize_wound_move(move_id: String) -> bool:
	return str(move_id) == MOVE_ID_STABILIZE_WOUND
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

# Parry (defensive move ~40–60% of max strike; research)
const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5
const PARRY_STRENGTH_NORM := 100.0
const PARRY_DEFLECT_THRESHOLD := 1.08
const PARRY_TECHNIQUE_VARIANCE := 0.15
const PARRY_V_MIN_FRACTION := 0.2
const PARRY_V_MIN_NEAR_DEFLECT := 0.1
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := 0.25
const PARRY_BLADE_MOVEMENT_S := 0.13
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0
const PERF_MOD_MIN := 0.35
const COMMITMENT_FRACTION := 0.2
## Tier 4.2 tempo: when **`pending_attack`** / **`pa`** has a non-empty **`feint_part`**, passive parry timing uses this larger committed fraction (shorter **`effective_wind_up`**) vs **`COMMITMENT_FRACTION`** — more opaque early commitment on feint telegraphs.
const COMMITMENT_FRACTION_FEINT := 0.35
const RECOVERY_READINESS_EARLY := 0.5
const RECOVERY_READINESS_LATE := 0.85
const OFF_BALANCE_DURATION_S := 0.4
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7
const OFF_BALANCE_GAUGE_FILL_MULT := 0.5  # Tempo penalty: slower to recover initiative after parried attack
const PARRY_BONUS_AFTER_DEFLECT_S := 2.0
const GUARD_AFTER_ATTACK := 0.4
const GUARD_RISE_RATE := 0.6
const PARRY_DODGE_STRENGTH_RATIO := 2.2
const PARRY_BLOCK_MASS_THRESHOLD := 0.9
const PARRY_BLOCK_STR_THRESHOLD := 0.95
const PARRY_REDIRECT_BONUS := 0.18
const PARRY_REDIRECT_SKILL_SCALE := 0.35
const PARRY_REDIRECT_ATTEMPT_RATIO := 3.5
const PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE := 0.5
const PARRY_GLANCING_EXPONENT := 0.5
const PARRY_REDIRECT_THRUST_BONUS := 0.22
const PARRY_REDIRECT_BLUNT_PENALTY := 0.12
const PARRY_CUT_TO_BLUNT_SHIFT := 0.45
const PARRY_PENETRATION_ANGLE_MIN := 0.72
# Direct hits (no parry/dodge): misaligned guard = blade hits at oblique angle. Only when parry_remaining_ratio == 1.0.
# Scale: 0 = no alignment effect; 1 = full (alignment 0 → angle_min). Avoid double-counting with parry/dodge.
const PARRY_PENETRATION_ALIGNMENT_SCALE := 0.5
# Parry partial: only update defender guard_line when alignment > this (blade properly met).
const PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD := 0.6

# HEMA bind vs deflect: parry_control above this → bind (blade stays).
const PARRY_BIND_CONTROL_THRESHOLD := 0.65


## III-3: shared full-stop gate — turn pick uses pre-variance **`parry_c_d`**; resolve uses post-variance **`c_d_final`**.
static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool) -> bool:
	return is_block_parry and c_d >= parry_p_a * PARRY_DEFLECT_THRESHOLD


## III-3: bind tag gate — `AttackResultApplier`, `GuardLineUpdater`, calibration audit.
static func parry_bind_control_reached(parry_control: float) -> bool:
	return parry_control >= PARRY_BIND_CONTROL_THRESHOLD


static func iii3_baseline_constants_line() -> String:
	return (
		"III-3 constants: unchanged baseline (PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f)"
		% [PARRY_DEFLECT_THRESHOLD, PARRY_BIND_CONTROL_THRESHOLD]
	)


## P4d: single doc-sync line for bind riposte table + gauge bonus (calibration audit + ii2b worksheet).
static func p4d_parry_bind_doc_sync_line() -> String:
	var blade: Dictionary = PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary
	var shaft: Dictionary = PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary
	return (
		"P4d bind sync: blade stab=%.2f cut=%.2f shaft blunt=%.2f fallback=%.2f gauge_bonus=%.0f"
		% [
			float(blade["stab"]),
			float(blade["cut"]),
			float(shaft["blunt"]),
			PARRY_BIND_RIPOSTE_MULT_FALLBACK,
			PARRY_BIND_RIPOSTE_GAUGE_BONUS,
		]
	)


# Non-blade attacks (pommel, mace head): impact weapons, no sustained blade contact → never bind, always deflect.
const ARCHETYPES_NEVER_BIND: Array[String] = ["pommel_strike", "heavy_blunt"]
# Bind riposte wind-up: parry_part × contact_type. Extend=fast, wind=moderate, swing=slow. Fallback for missing cells.
# P4h balance (2026-05-18): stab 0.55 < cut 0.78 < blunt 0.90 — extend vs wind vs swing from bind; harness **`_run_bind_riposte_*`**.
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
	"blade": {"stab": 0.55, "cut": 0.78},
	"shaft": {"stab": 0.55, "cut": 0.78, "blunt": 0.90},
	"haft": {"stab": 0.55, "cut": 0.78}
}
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = 0.78
# Late parry: control penalty (less time to set up proper parry).
const PARRY_LATE_CONTROL_FACTOR := 0.6
# Off-balance: control penalty.
const PARRY_OFF_BALANCE_CONTROL_FACTOR := 0.7
# For opposite-defender geometry: severity above this → 90° deflect. Below → 45°.
const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := 0.65
const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := 0.5
const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := 0.8
# Thrust: harder to achieve bind (point deflects more readily).
const PARRY_THRUST_CONTROL_MULT := 0.85
# Blade position after parry deflect: attacker's blade was knocked aside.
# Fallback when defender_guard unknown: maps attack_line -> deflected guard (opposite line).
const DEFLECTED_GUARD_FROM_ATTACK: Dictionary = {"high": "low", "low": "high", "left": "right", "right": "left"}
# Adjacent lines (45°): lateral deflection. Physics: "shed to the side" = smaller angular displacement.
const LINE_ADJACENTS: Dictionary = {"high": ["left", "right"], "low": ["left", "right"], "left": ["high", "low"], "right": ["high", "low"]}
# Blade position after full dodge: defender moved to avoid. Maps attack_line -> guard they end in (e.g. duck high -> low).
const DODGE_END_GUARD_FROM_ATTACK: Dictionary = {"high": "low", "low": "high", "left": "right", "right": "left"}
const PARRY_DESPERATE_DODGE_THRESHOLD := 0.06
const PARRY_PREFER_DODGE_FULL_THRESHOLD := 0.12
const PARRY_MASS_DISPARITY_BONUS := 0.18
const PARRY_LATE_CAPACITY_FLOOR := 0.22

# Weapon part model: parry capacity multiplier by defender's parry contact part (blade=best, shaft=wood, haft=wood).
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.88, "haft": 0.92}
# Defender weapon type vs attack contact_type modifier. def_weapon_type -> {contact_type -> mult}.
const PARRY_DEF_VS_ATK_MOD: Dictionary = {"DAGGER": {"stab": 0.9}, "MACE": {"blunt": 1.05}, "SPEAR": {"cut": 0.95}}
# Full weapon mass contributes to parry: effective mass = lerp(parry_part, total, this). 0.5 = equal weight.
const PARRY_INERTIA_BLEND: float = 0.5
# Shaft/haft longer than this (cm) get leverage factor from alignment (contact point along length matters).
const PARRY_LEVERAGE_LONG_PART_CM: float = 80.0
# Leverage factor range for long shaft/haft: 0.65 (bad alignment = weak contact) to 1.0 (good = strong).
const PARRY_LEVERAGE_FLOOR: float = 0.65

# Recovery cause → readiness: unique curves per cause. attack_hit = more stunned; attack_miss = off-balance.
# Each: [early, late] for lerp(early, late, progress). progress = state_timer / state_duration.
const READINESS_BY_CAUSE: Dictionary = {
	"attack_hit": [0.3, 0.6],      # Stunned from impact; worst parry
	"attack_miss": [0.45, 0.8],    # Off-balance from whiff; less stunned
	"attack_deflect": [0.5, 0.85], # Blade deflected; similar to baseline
	"skip": [0.5, 0.85],           # No attack; baseline
	"medical": [0.5, 0.85]         # Fallback for any other cause
}

# Guard zone (body-part): which zone defender chooses to protect. Parry bonus when guarded, penalty when unguarded.
const GUARD_ZONE_BONUS := 1.4
const GUARD_ZONE_UNGUARDED_PENALTY := 0.75
# Default guard/attack line when combatant or move lacks explicit value.
const GUARD_DEFAULT := "high"
# Part → primary guard line (for guard_zone/guard_line sync)
const PART_TO_LINE: Dictionary = {"head": "high", "chest": "high", "left_arm": "left", "right_arm": "right", "left_leg": "low", "right_leg": "low"}
# Line → default body part (for syncing guard_zone when guard_line changes from outcome)
const LINE_TO_DEFAULT_PART: Dictionary = {"high": "head", "low": "left_leg", "left": "left_arm", "right": "right_arm"}
## Tier 4.2 (Feint D): wind-up telegraph body part on defender; cleared when that incoming attack's `pending_attack` ends — survives `GuardLineUpdater` overwriting `guard_zone`.
const COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART := "incoming_attack_telegraph_part"
## Tier 4.2 short-horizon tempo: on **`attacker`**, maps **`str(defender_id)` → int** last **`CombatManager`** combat tick when that defender **`parry_deflect`**'d this attacker. Drives feint-move listing pressure in **`CombatAIActionPicker._get_action_weight`**; cleared on **`hit`** to that defender and on **`CombatManager.start()`**.
const COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK := "ai_feint_opp_last_parry_deflect_tick_by_id"
## Tier 4.2 counter-tempo pilot: combat clock until defender may spend partial gauge vs incoming **`STATE_WIND_UP`** on them (**`CounterTempo`**).
const COMBATANT_KEY_COUNTER_WINDOW_UNTIL := "counter_window_until"
const ACTION_KEY_COUNTER_TEMPO := "counter_tempo"
## Listed **`attempt_close`**: target form note when defender is controlling (Fool etc.).
const ACTION_KEY_CLOSE_LIST_HINT := "close_attempt_list_hint"
const PA_KEY_COUNTER_TEMPO := "counter_tempo"
## Partial gauge: minimum to start a counter-tempo melee; cost spent on resolve (**`CounterTempo.spend_gauge`**).
const COUNTER_TEMPO_GAUGE_THRESHOLD := 50.0
const COUNTER_TEMPO_GAUGE_COST := 50.0
## Incoming wind-up window length = attacker **`wind_up_s`** × this fraction (HEMA roadmap ~0.8).
const COUNTER_TEMPO_WINDOW_FRACTION := 0.8
## Tier 4.2 Approach B: defender counter-tempo only after incoming **`STATE_WIND_UP`** progress ≥ this (committed cut). **`0`** disables.
const COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS := 0.5
## Set when **`EVENT_ACTION_READY`** / **`notify_turn_ready`** was scheduled for an open counter window (cleared with window).
const COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED := "counter_tempo_ready_signaled"
## Optional UI hint from **`CounterTempo.process_waiting`**: **`counter_winding`** | **`counter_ready`**.
const COMBATANT_KEY_COUNTER_TEMPO_UI_HINT := "counter_tempo_ui_hint"
## Counter-attack wind-up multiplier vs a normal attack at the same rolls.
const COUNTER_TEMPO_WINDUP_MULT := 0.65
## Max counter tempo wind-up duration (hard cap). A well-timed counter should be faster than a committed attack, not similarly paced.
const COUNTER_TEMPO_WINDUP_MAX_S := 1.5 # hard cap on counter tempo wind-up duration
const COUNTER_TEMPO_ACTION_READY_DELAY_S := 0.02
const COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S := 0.001
## Tier 4.2 counter-tempo AI: boost listed actions flagged **`ACTION_KEY_COUNTER_TEMPO`**; extra nudge vs the incoming wind-up attacker; damp feints mid-tempo.
const AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT := 1.35
const AI_COUNTER_TEMPO_INCOMING_TARGET_MULT := 1.12
const AI_COUNTER_TEMPO_FEINT_DAMP_MULT := 0.88
## Tier 4.2 riposte chain: after **`parry_deflect`**, next attack vs that attacker within window uses shorter wind-up.
const COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL := "riposte_chain_until"
const COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID := "riposte_chain_target_id"
const PA_KEY_RIPOSTE_CHAIN := "riposte_chain"
const RIPOSTE_CHAIN_WINDOW_S := 1.5
const RIPOSTE_CHAIN_WINDUP_MULT := 0.5
## Tier 4.5 bind-exchange pilot (**`CombatFlurryBind`**): after hard bind deflect, both partners get a short window of faster wind-ups vs each other.
const FLURRY_BIND_WINDOW_S := 1.25
const FLURRY_BIND_MAX_EXCHANGES := 2
const FLURRY_BIND_WIND_UP_MULT := 0.82
## Attack stamina cost multiplier when exchanging inside an open bind-flurry window vs that target.
const FLURRY_BIND_STAMINA_ATTACK_COST_MULT := 0.88
## Tier 4.5: bind-exchange flurry pilot — production **on** (2026-05-18); harness may toggle via **`set_feature_flurry_bind_exchange_load`**.
const FEATURE_FLURRY_BIND_EXCHANGE := true
static var _feature_flurry_bind_exchange_enabled: bool = FEATURE_FLURRY_BIND_EXCHANGE
static var _feature_counter_tempo_enabled: bool = true


static func is_feature_flurry_bind_exchange_enabled() -> bool:
	return _feature_flurry_bind_exchange_enabled


static func set_feature_flurry_bind_exchange_load(enabled: bool) -> void:
	_feature_flurry_bind_exchange_enabled = enabled


static func is_feature_counter_tempo_enabled() -> bool:
	return _feature_counter_tempo_enabled


static func set_feature_counter_tempo_load(enabled: bool) -> void:
	_feature_counter_tempo_enabled = enabled

## Tier 4.3 combat attention + mental stack (default on; harness may toggle).
const COMBATANT_KEY_FOCUS_PART := "focus_part"
const COMBATANT_KEY_FOCUS_INTENSITY := "focus_intensity"
const COMBATANT_KEY_ATTENTION_LOAD := "attention_load"
const COMBATANT_KEY_YOMI_BY_ATTACKER := "yomi_by_attacker"
## Expand WF: active weapon form id (L2 — per fighter style package).
const COMBATANT_KEY_WEAPON_FORM := "weapon_form"
const COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL := "form_switch_cooldown_until"
## Last reason the AI auto-switched weapon form (cleared at turn ready; surfaced in gauge tooltip).
const COMBATANT_KEY_LAST_FORM_SWITCH_REASON := "last_form_switch_reason"
const COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID := "inferred_opp_form_by_id"
## Tier 4.3 UI: short row hint from **`CombatAttention.refresh_for_waiting_tick`** (focus line + effective % + load %).
const COMBATANT_KEY_ATTENTION_UI_HINT := "attention_ui_hint"
## Tier 4.3 debug: last mental-stack layer that picked (**`MentalStackDecider`**); cleared when stack does not pick.
const COMBATANT_KEY_MENTAL_STACK_LAYER := "mental_stack_layer"
## Fled off field before medical phase: skip passive bleed ticks but allow triage listing.
const COMBATANT_KEY_SUSPEND_BLEED_TICK := "suspend_bleed_tick"
## Layer stamp values (gauge **`Stack %s`** / soak).
const MENTAL_STACK_LAYER_SELF_MEDICAL := "self_medical"
const MENTAL_STACK_LAYER_MEDICAL := "medical"
const MENTAL_STACK_LAYER_COUNTER := "counter"
const MENTAL_STACK_LAYER_INCOMING := "incoming"
const MENTAL_STACK_LAYER_HOLD_LINE := "hold_line"
const MENTAL_STACK_LAYER_SPARSE_FIGHT := "sparse_fight"
## MS-L5 Expand: vacancy / plug-forward when line breaks (after L4, before exhaustion).
const MENTAL_STACK_LAYER_FORMATION_PLUG := "formation_plug"
## MS-L6 Expand: cohesion break → flee / fall_back before salience utility (after MS-L5, before exhaustion).
const MENTAL_STACK_LAYER_ROUT := "rout"
## MS-L8: post-strike momentum — press advantage or disengage cleanly after a successful strike.
const MENTAL_STACK_LAYER_POST_STRIKE := "post_strike"
const COMBATANT_KEY_LAST_STRIKE_TICK := "last_strike_tick"
const COMBATANT_KEY_LAST_STRIKE_TARGET_ID := "last_strike_target_id"
const POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE := 2.0
const POST_STRIKE_HIT_WEIGHT_BONUS := 1.1
const POST_STRIKE_MOMENTUM_WEIGHT_BONUS := 1.3
## MS-L9: positional awareness — disengage when surrounded + wounded/vulnerable.
const MENTAL_STACK_LAYER_POSITIONAL_DIS := "positional_dis"
## FEATURE flag for positional awareness layer.
const FEATURE_MS_POSITIONAL_AWARENESS := true
static var _feature_ms_positional_awareness_load: int = -1

static func is_feature_ms_positional_awareness_enabled() -> bool:
	if _feature_ms_positional_awareness_load >= 0:
		return _feature_ms_positional_awareness_load != 0
	return FEATURE_MS_POSITIONAL_AWARENESS

static func set_feature_ms_positional_awareness_load(enabled: bool) -> void:
	_feature_ms_positional_awareness_load = 1 if enabled else 0
## MS-L7: high fight exhaustion → wait / formation disengage before salience utility pick.
const MENTAL_STACK_LAYER_EXHAUSTION := "exhaustion"
const MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD := 0.50
## MS-GRADIENT: hard disengage tunnel threshold — exhaustion above this floors offense weight at damp floor.
const MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD := 0.75
## When no stack layer fires: multiply offensive action weights by **`lerp(1, 1 - this, attention_load)`** (attacks, feints, attempt_close).
const MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX := 0.4
const FOCUS_INTENSITY_DEFAULT := 1.0
const ATTENTION_LOAD_TELEGRAPH_WEIGHT := 0.45
const ATTENTION_LOAD_PERIL_WEIGHT := 0.4
const ATTENTION_LOAD_COUNTER_WEIGHT := 0.25
const ATTENTION_LOAD_FOCUS_PENALTY := 0.55
const FOCUS_WRONG_LINE_READTHROUGH_MULT := 0.82
const FOCUS_CORRECT_LINE_READTHROUGH_MULT := 1.06
const YOMI_FEINT_LISTING_MIN_LINE_COUNT := 2
const YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT := 0.04
const YOMI_FEINT_LISTING_MULT_CAP := 1.25
## AI defender focus drift toward attacker's habitual line (see **`CombatAttention.apply_yomi_focus_drift`**).
const YOMI_FOCUS_DRIFT_MIN_LINE_COUNT := 2
## Short engagement shortcut: after fewer total ticks, one observation suffices.
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD := 8
const YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT := 1
const YOMI_FOCUS_DRIFT_INTENSITY := 0.78
static var _feature_combat_attention_enabled: bool = true
static var _feature_mental_stack_ai_enabled: bool = true


static func is_feature_combat_attention_enabled() -> bool:
	return _feature_combat_attention_enabled


static func set_feature_combat_attention_load(enabled: bool) -> void:
	_feature_combat_attention_enabled = enabled


static func is_feature_mental_stack_ai_enabled() -> bool:
	return _feature_mental_stack_ai_enabled


## MS-L6 Expand: rout / cohesion-break layer in **`MentalStackDecider`** (after MS-L5 plug).
const FEATURE_MS_L6_ROUT := true
static var _feature_ms_l6_rout_load: int = -1


static func is_feature_ms_l6_rout_enabled() -> bool:
	if _feature_ms_l6_rout_load >= 0:
		return _feature_ms_l6_rout_load != 0
	return FEATURE_MS_L6_ROUT


static func set_feature_ms_l6_rout_load(enabled: bool) -> void:
	_feature_ms_l6_rout_load = 1 if enabled else 0


## MS-WEIGHT Expand: feint resistance gate — picker-level hard block for high-readiness defenders.
const FEATURE_MS_FEINT_RESISTANCE := true
static var _feature_ms_feint_resistance_load: int = -1

static func is_feature_ms_feint_resistance_enabled() -> bool:
	if _feature_ms_feint_resistance_load >= 0:
		return _feature_ms_feint_resistance_load != 0
	return FEATURE_MS_FEINT_RESISTANCE

static func set_feature_ms_feint_resistance_load(enabled: bool) -> void:
	_feature_ms_feint_resistance_load = 1 if enabled else 0


## MS-MID Expand: mid-fight ally medical listing when ally in immediate peril; L1 stack already coordinated.
const FEATURE_MS_MID_INFIGHT_MED := true
static var _feature_ms_mid_infight_med_load: int = -1


static func is_feature_ms_mid_infight_med_enabled() -> bool:
	if _feature_ms_mid_infight_med_load >= 0:
		return _feature_ms_mid_infight_med_load != 0
	return FEATURE_MS_MID_INFIGHT_MED


static func set_feature_ms_mid_infight_med_load(enabled: bool) -> void:
	_feature_ms_mid_infight_med_load = 1 if enabled else 0


## MS-WEIGHT Expand: medical escalation ladder — TCCC progression on repeated failure.
const FEATURE_MS_MEDICAL_ESCALATION := true
static var _feature_ms_medical_escalation_load: int = -1

static func is_feature_ms_medical_escalation_enabled() -> bool:
	if _feature_ms_medical_escalation_load >= 0:
		return _feature_ms_medical_escalation_load != 0
	return FEATURE_MS_MEDICAL_ESCALATION

static func set_feature_ms_medical_escalation_load(enabled: bool) -> void:
	_feature_ms_medical_escalation_load = 1 if enabled else 0


const MEDICAL_AI_WEIGHT_ESCALATION_BONUS := 1.5


## MS-POST-STRIKE Expand: post-strike momentum layer — press advantage after successful strike.
const FEATURE_MS_POST_STRIKE := true
static var _feature_ms_post_strike_load: int = -1

static func is_feature_ms_post_strike_enabled() -> bool:
	if _feature_ms_post_strike_load >= 0:
		return _feature_ms_post_strike_load != 0
	return FEATURE_MS_POST_STRIKE

static func set_feature_ms_post_strike_load(enabled: bool) -> void:
	_feature_ms_post_strike_load = 1 if enabled else 0


static func is_focus_line_move(move_id: String) -> bool:
	return str(move_id) in FOCUS_LINE_MOVE_IDS


static func is_feature_position_angle_footwork_enabled() -> bool:
	return _feature_position_angle_footwork_enabled


static func set_feature_position_angle_footwork_load(enabled: bool) -> void:
	_feature_position_angle_footwork_enabled = enabled


static func position_angle_offset_deg_for_attack_line(line: String) -> float:
	var k: String = str(line).strip_edges()
	if is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.position_angle_offset_deg_for_line(k)
	return float(POSITION_ANGLE_OFFSET_DEG_BY_LINE.get(k, 0.0))


static func guard_line_for_focus_move_id(move_id: String) -> String:
	match str(move_id):
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


static func set_feature_mental_stack_ai_load(enabled: bool) -> void:
	_feature_mental_stack_ai_enabled = enabled

## With feint: if **`parry_readiness * CombatWeaponForm.mod(form_str, "feint_readthrough")`** ≥ this, treat defender guard focus as the real line for guard-zone parry mult (see **`DefenseChoiceResolver._guard_zone_modifier`**).
const FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD := 0.9
## Tier 4.2 telegraph delay: while attacker **`STATE_WIND_UP`** progress is below **`feint_target_reveal_at_progress`** (move + stamped on **`pa`**), **`DefenseChoiceResolver._feint_readiness_reveal_mult`** lerps passive readiness from this toward **1.0** for feint read-through, dodge telegraph, guard-zone, reported **`parry_readiness`**, passive-parry guard-angle wobble in **`choose_defense`**, and feint-move **listing** **`pr_def`** when live **`pending_attack`** targets the listed defender. **`0.5`** ≈ early wind-up still bait-heavy.
const FEINT_PRE_REVEAL_READINESS_MULT := 0.5
## Tier 4.2: **`DefenseChoiceResolver.choose_defense`** may set **`dodge_eval_part`** to **`pa.feint_part`** (telegraph bait) when defender does not read through the feint. Harness-only **`pa`** override: **`PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS`** (**0..1**).
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS := 0.55
## Headless harness only: **`DefenseChoiceResolver.choose_defense`** may read this **`pa`** key (**0..1**) to override **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS`**.
const PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS := "_harness_feint_dodge_eval_bias"
## After harness override: multiplies effective feint dodge telegraph bias from defender **`distance_to[attacker]`** (**`DefenseChoiceResolver._apply_feint_telegraph_bias_to_dodge_eval_part`**). LONG = slightly more time to read real line; CLOSE = slightly more “bite” on telegraph.
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE := 1.08
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG := 0.88

# 4-line guard (Liechtenauer): physics-based parry alignment
# alignment = cos(θ); parry capacity ∝ alignment; variance ∝ 1/alignment; leak ∝ (1-alignment)
const PARRY_ALIGNMENT_FLOOR := 0.15
const GEOMETRIC_LEAK_MAX := 0.35
const PARRY_GEOMETRY_VARIANCE_BASE := 0.08

# Guard transition: wind-up cost when blade must move from current guard to attack line.
# Physics: angular distance; alignment=1 (same line) = no cost; alignment=0 = +40% wind-up.
const GUARD_TRANSITION_COST_SCALE := 0.4
## Clamp on guard-line transition mult (footwork offset can drive align toward 0 — keeps wind-up UI honest).
const GUARD_TRANSITION_MULT_MAX := 1.35
# AI target selection: preferred_parts from move get this weight multiplier (cut geometry).
const PREFERRED_PART_BONUS_MULT := 1.5

# Debug: when true, log detailed melee resolution (per-hit damage line, EntityDamage armor/bone traces, parry paths, wind-up skips). Verbose.
# Default false — enable locally for tuning; headless harness uses **`set_headless_harness_quiet(true)`** as well.
# **`COMBAT_DEV_VERBOSE`** — production default off. F5: **`main.tscn` → `dev_research_feel`** or **`set_combat_dev_verbose_override(true)`** (Track Q1).
const COMBAT_DEV_VERBOSE := false
## -1 = use const; 0/1 = editor session override (ignored when headless harness quiet).
static var _combat_dev_verbose_override: int = -1
const COMBAT_DEBUG := false
# Calibration: when true, log alignment, parry_c_d, variance, remaining_ratio for tuning to HEMA 57–80% parry share.
const COMBAT_DEBUG_CALIBRATION := false
# Flow / feature testing: with `COMBAT_EVENT_DEBUG` alone — turn pick lines (`CombatDebug.flow_log_turn`) and `[Combat.Flow]` prints from `flow_log_turn` only.
# With `COMBAT_EVENT_DEBUG_VERBOSE` also true — `CombatDebug.flow_log` (get_available_actions, incursion_snapshot, resolve_action, skip_turn, formation resolves),
# `[Combat]` formation move banners, and `EVENT_ACTION_READY skipped` (state not waiting). Crash summaries may still use `[Combat]` in `CombatEngagementResolver`.
# Disable in release to reduce console noise. Per-hit stdout damage + armor/bone traces: enable COMBAT_DEBUG; extra before/after part state: COMBAT_DEBUG_CALIBRATION.
# Default false — set true locally for `[Combat.Flow]` turn/action traces.
const COMBAT_EVENT_DEBUG := false
## When true with `COMBAT_EVENT_DEBUG`, enables verbose `CombatDebug.flow_log` and related high-frequency prints (see block comment above).
## Turn pick lines (`flow_log_turn`) still print when only `COMBAT_EVENT_DEBUG` is true.
const COMBAT_EVENT_DEBUG_VERBOSE := false
## Headless harness scripts (**`run_all_combat_checks.gd`**, etc.) set this so **`combat_debug_active()`** / **`combat_event_debug_active()`** are false (avoids megabytes of stdout and pipe deadlock with `| grep`).
static var _headless_harness_quiet: bool = false
## Editor F5 via **`OperationalLog.begin_play_session`**: **`[Combat.Flow]`** turn picks + **`FP_COMBAT`** milestones only.
## Does **not** enable per-hit **`[Combat.Debug]`** / armor / bone traces (use **`COMBAT_DEV_VERBOSE`** for those).
static var _play_session_diagnostic: bool = false
## F5 **`hit_resolve`** lines (grep-friendly per-strike outcomes). -1 = on when play-session diagnostic is on; 0/1 = **`main.tscn` `dev_hit_summary`** override.
static var _combat_hit_summary_override: int = -1


static func set_headless_harness_quiet(on: bool) -> void:
	_headless_harness_quiet = on


static func is_headless_harness_quiet() -> bool:
	return _headless_harness_quiet


static func set_play_session_diagnostic(on: bool) -> void:
	_play_session_diagnostic = on


static func play_session_diagnostic_active() -> bool:
	return _play_session_diagnostic and not _headless_harness_quiet


static func set_combat_hit_summary_override(on: bool) -> void:
	_combat_hit_summary_override = 1 if on else 0


static func clear_combat_hit_summary_override() -> void:
	_combat_hit_summary_override = -1


## **`FP_COMBAT: hit_resolve`** — default on during editor play session; off when **`dev_hit_summary`** false.
static func combat_hit_summary_active() -> bool:
	if _combat_hit_summary_override >= 0:
		return _combat_hit_summary_override != 0
	if _headless_harness_quiet:
		return false
	return play_session_diagnostic_active()


static func set_combat_dev_verbose_override(on: bool) -> void:
	_combat_dev_verbose_override = 1 if on else 0


static func clear_combat_dev_verbose_override() -> void:
	_combat_dev_verbose_override = -1


static func combat_dev_verbose_active() -> bool:
	if _headless_harness_quiet:
		return false
	if _combat_dev_verbose_override >= 0:
		return _combat_dev_verbose_override != 0
	return COMBAT_DEV_VERBOSE


static func combat_debug_active() -> bool:
	return (COMBAT_DEBUG or combat_dev_verbose_active()) and not _headless_harness_quiet


static func combat_event_debug_active() -> bool:
	return (
		COMBAT_EVENT_DEBUG or combat_dev_verbose_active() or _play_session_diagnostic
	) and not _headless_harness_quiet


static func combat_event_debug_verbose_active() -> bool:
	return combat_event_debug_active() and (
		COMBAT_EVENT_DEBUG_VERBOSE or combat_dev_verbose_active()
	)


## With verbose flow: `CombatDebug.flow_log(msg, dedupe_key)` omits a line when it matches the previous line for the same key (UI / tick polling). Set false to log every emission.
const COMBAT_FLOW_LOG_SUPPRESS_REPEATED := true
## When true, vacancy plug reconcile runs only on formations marked dirty (`CombatManager.mark_formation_vacancy_dirty`), not every frame on both lines. Set false to restore always-reconcile-all behavior (e.g. regression debugging).
const COMBAT_VACANCY_RECONCILE_DIRTY_ONLY := true
## 0 = off. If N > 0, every N combat ticks all formations are marked vacancy-dirty (safety valve if a code path forgets to mark).
const COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES := 0
# When true with a debug build, `CombatFormationFlow` logs if vacancy reconcile leaves an empty rank-0 column
# while a non-intruded ally still sits deeper in that column (should never happen after `reconcile_vacancy_plugs_*`).
const COMBAT_FORMATION_INVARIANT_DEBUG := false

# Stamina (separate pool): attack/parry consume; refill when idle.
# Realism target: stamina shapes execution quality without dominating combat length.
const STAMINA_MAX := 100.0
## Tier 7.2: idle refill — with attack costs **12–20**, five heavy swings exhaust the pool; ~**5**/s refill keeps sustained exchanges tiring over **~2–3** minutes.
const STAMINA_REFILL_RATE := 5.0
const STAMINA_ATTACK_COST_BASE := 12.0
## Tier 7: `stamina_attack_cost_from_intensity` — light **12**, heavy **20** at intensity **1.0**.
const STAMINA_ATTACK_COST_SCALE := 8.0
## Tier 7: flat parry default; prefer **`stamina_parry_cost_from_intensity`** (mirrors attack cost curve).
const STAMINA_PARRY_COST := 12.0
const STAMINA_PARRY_COST_BASE := 12.0
const STAMINA_PARRY_COST_SCALE := 8.0
## Tier 7: event-driven turn spacing — low stamina lengthens **`action_ready_cooldown`** (gauge-fill analogue).
const STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT := 1.35
## Tier 7 / HEMA bind riposte tempo: modest gauge bump on **`parry_deflect`** when **`parry_was_bind`** (stacks with **`READY_DELAY_PARRY_RIPOSTE_S`**).
const PARRY_BIND_RIPOSTE_GAUGE_BONUS := 28.0
const STAMINA_AT_ZERO_PARRY_MULT := 0.5
const STAMINA_AT_ZERO_DAMAGE_MULT := 0.7
# Non-linear fatigue: moderate curve; low stamina hurts quality but is not a hard cliff.
# Used everywhere stamina affects outcome: variance, parry, damage.
const STAMINA_FACTOR_POWER := 0.65
## Central fatigue + hypovolemia cap burst pool (× at full exhaustion / blood floor).
const STAMINA_EXHAUSTION_MAX_MULT_FLOOR := 0.7
const STAMINA_BLOOD_MAX_MULT_FLOOR := 0.7
## PCr resynthesis slows when fight-exhausted (× at exhaustion 1.0).
const STAMINA_REFILL_EXHAUSTION_MULT_FLOOR := 0.4
## Gradual offense damp from **`EXHAUSTION_OFFENSE_DAMP_START`** → floor at **`MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD`** (p4a: aligns with 50% FP band + MS-L7 tunnel).
const EXHAUSTION_OFFENSE_DAMP_START := 0.25
const EXHAUSTION_OFFENSE_DAMP_FLOOR := 0.35

## Returns 0-1. At 100% stamina → 1; at 0% → 0. Curve ramps down faster below ~25%.
static func stamina_factor(ratio: float) -> float:
	return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)


## Tier 7: attack stamina spend from wind-up **`intensity`** (0–1).
static func stamina_attack_cost_from_intensity(intensity: float) -> float:
	return STAMINA_ATTACK_COST_BASE + STAMINA_ATTACK_COST_SCALE * clampf(intensity, 0.0, 1.0)


## Tier 7: defender parry stamina from incoming strike **`intensity`** (same curve as attack cost).
static func stamina_parry_cost_from_intensity(intensity: float) -> float:
	return STAMINA_PARRY_COST_BASE + STAMINA_PARRY_COST_SCALE * clampf(intensity, 0.0, 1.0)


## Tier 7: multiply **`CombatEventScheduler.action_ready_cooldown`** when fatigued.
static func action_ready_stamina_delay_mult(stamina_ratio: float) -> float:
	return lerpf(STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT, 1.0, stamina_factor(stamina_ratio))


# --- Fight exhaustion index (MXm / D-004): cumulative 0–1 performance drain ---
const COMBATANT_KEY_EXHAUSTION := "exhaustion"
## Highest exhaustion FP_COMBAT band index logged this fight (0=25%, 1=50%, 2=75%).
const COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED := "exhaustion_fp_band_logged"
const EXHAUSTION_MAX := 1.0
## Stamina spend maps to exhaustion gain: heavy attack (~20) ≈ **0.08** before endurance relief.
const EXHAUSTION_EXERTION_PER_STAMINA_POINT := 0.004
## High **`stats.endurance`** reduces gain (up to this fraction of exertion waived).
const EXHAUSTION_ENDURANCE_MAX_RELIEF := 0.45
## Passive drop per second while **`STATE_WAITING`** (between exchanges).
const EXHAUSTION_RECOVERY_RATE := 0.012
const EXHAUSTION_CURVE := 1.35
const EXHAUSTION_FLOOR_MULT := 0.55
## Gauge suffix when exhaustion index ≥ this (avoid clutter at trace levels).
const EXHAUSTION_UI_SHOW_THRESHOLD := 0.06
## Below **`PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD`**, exertion gain scales up.
const EXHAUSTION_GAIN_BLOOD_LOSS_MULT := 1.35
## Active pain shock on entity multiplies exertion gain.
const EXHAUSTION_GAIN_PAIN_SHOCK_MULT := 1.25
const FEATURE_FIGHT_EXHAUSTION_INDEX := true
static var _feature_fight_exhaustion_index: bool = FEATURE_FIGHT_EXHAUSTION_INDEX


static func is_feature_fight_exhaustion_enabled() -> bool:
	return _feature_fight_exhaustion_index


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
	_feature_fight_exhaustion_index = on


## MXm: performance multiplier from exhaustion index (1.0 = fresh, floor at **`EXHAUSTION_FLOOR_MULT`**).
static func exhaustion_performance_mult(exhaustion: float) -> float:
	var t: float = pow(clampf(exhaustion, 0.0, EXHAUSTION_MAX), EXHAUSTION_CURVE)
	return lerpf(1.0, EXHAUSTION_FLOOR_MULT, t)


## MXm-2: defender readiness / surround awareness (mirrors stamina reporting curve shape, separate pool).
static func defender_passive_readiness_exhaustion_mult(combatant: Dictionary) -> float:
	if not is_feature_fight_exhaustion_enabled() or combatant.is_empty():
		return 1.0
	return exhaustion_performance_mult(float(combatant.get(COMBATANT_KEY_EXHAUSTION, 0.0)))


## Tier 7: HEMA bind deflect — defender gauge bump before next **`EVENT_ACTION_READY`**.
static func apply_parry_bind_riposte_gauge_bonus(defender: Dictionary) -> void:
	if defender.is_empty():
		return
	var g: float = float(defender.get("gauge", 0.0))
	defender["gauge"] = minf(100.0, g + PARRY_BIND_RIPOSTE_GAUGE_BONUS)


## Tier 4.2 footwork / tempo: defender stamina curve for **readiness reporting** (feint read-through, guard-zone, dodge telegraph, feint-move listing **`pr_def`**) — same **`lerpf(STAMINA_AT_ZERO_PARRY_MULT, 1.0, stamina_factor(ratio))`** as post-alignment parry capacity uses once on **`parry_c_d`**. **`DefenseChoiceResolver._defender_passive_readiness_stamina_mult`** passes **`stamina_ratio()`** via **`CombatantEntityAccess`**.
static func defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio: float) -> float:
	var st_ratio: float = clampf(stamina_ratio, 0.0, 1.0)
	return lerpf(STAMINA_AT_ZERO_PARRY_MULT, 1.0, stamina_factor(st_ratio))


## Tier 4.2 tempo: committed fraction for passive parry **`effective_wind_up`** in **`DefenseChoiceResolver.choose_defense`** / **`DefenseResolutionHandler`** — non-empty **`feint_part`** uses **`COMMITMENT_FRACTION_FEINT`** (shorter reactive window vs plain **`COMMITMENT_FRACTION`**).
static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
	if not str(pa.get("feint_part", "")).strip_edges().is_empty():
		return COMMITMENT_FRACTION_FEINT
	return COMMITMENT_FRACTION


## Agility+perception stat factor (0.5–1.5). Used for mobility, redirect skill, dodge.
static func stats_factor_agi_perc(agi: float, perc: float) -> float:
	return clampf((agi + perc) / 200.0, 0.5, 1.5)

## Glancing factor from remaining ratio. Used for partial dodge/parry velocity reduction.
static func glancing_factor(ratio: float, exponent: float = PARRY_GLANCING_EXPONENT) -> float:
	return pow(clampf(ratio, 0.0, 1.0), exponent)

## Parry redirect multiplier from parry config, attacker/defender stats, contact type (stab|cut|blunt), mass disparity.
static func compute_parry_redirect_mult(pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float) -> float:
	var r_bonus: float = pcfg.get("redirect_bonus", PARRY_REDIRECT_BONUS)
	var r_scale: float = pcfg.get("redirect_skill_scale", PARRY_REDIRECT_SKILL_SCALE)
	var redirect_skill: float = stats_factor_agi_perc(agi, perc)
	var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
	var ct: String = str(contact_type).to_lower()
	if ct == "stab":
		redirect_mult *= 1.0 + pcfg.get("redirect_thrust_bonus", PARRY_REDIRECT_THRUST_BONUS)
	elif ct == "blunt":
		redirect_mult *= 1.0 - pcfg.get("redirect_blunt_penalty", PARRY_REDIRECT_BLUNT_PENALTY)
	if not is_block_parry and m_a > 0.001 and m_d < m_a:
		var mass_bonus: float = pcfg.get("mass_disparity_bonus", PARRY_MASS_DISPARITY_BONUS) * (1.0 - m_d / m_a)
		redirect_mult *= 1.0 + mass_bonus
	return redirect_mult


## Tier 3.2: **`c_d_final` / (`parry_p_a * PARRY_DEFLECT_THRESHOLD`)** — shared by **`parry_control`**, **`severity`**, and **`parry_clash_context.margin_ratio`** (`DefenseResolutionHandler`).
static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
	return c_d_final / maxf(parry_p_a * PARRY_DEFLECT_THRESHOLD, 0.01)


## Tier 3.2: Deflection blend driver in **`parry_clash_context.severity`** / **`GuardLineUpdater.set_guard_deflected`** (from **`margin_ratio`** via **`parry_deflect_margin_ratio`** when **`severity`** omitted).
static func parry_deflect_severity_from_margin_ratio(margin_ratio: float) -> float:
	return clampf((margin_ratio - 1.0) / 1.0, 0.0, 1.0)


## Tier 3.2: **`parry_deflect`** full-stop bind vs deflect score (`parry_clash_context.parry_control`; **`DefenseResolutionHandler`**). Uses post-variance **`c_d_final`**. **`contact_type`**: `stab` | `cut` | `blunt` (from **`WeaponConstants.contact_type_for_move_id`**).
static func parry_control_for_bind_deflect(
	c_d_final: float,
	parry_p_a: float,
	alignment: float,
	parry_readiness: float,
	parry_off_balance: bool,
	late_parry: bool,
	contact_type: String
) -> float:
	var margin_ratio: float = parry_deflect_margin_ratio(c_d_final, parry_p_a)
	var margin_factor: float = clampf(margin_ratio, 0.5, 2.0)
	var readiness_factor: float = parry_readiness * (PARRY_OFF_BALANCE_CONTROL_FACTOR if parry_off_balance else 1.0)
	var timing_factor: float = PARRY_LATE_CONTROL_FACTOR if late_parry else 1.0
	var p: float = clampf(margin_factor * alignment * readiness_factor * timing_factor, 0.0, 1.0)
	var ct: String = str(contact_type).to_lower().strip_edges()
	if ct == "stab":
		p *= PARRY_THRUST_CONTROL_MULT
	return p


# Event queue (Phase 1). Stamina/exhaustion: LIVE_PATHS D-004. Resolve at combat_clock; tie-break: agility desc, then combatant_id asc.
const EVENT_ACTION_READY := "action_ready"
const EVENT_MELEE_ATTACK := "melee_attack"
const EVENT_RECOVERY_END := "recovery_end"
const EVENT_SWAP_RANK_RESOLVE := "swap_rank_resolve"
const EVENT_FALL_BACK_SOLO_RESOLVE := "fall_back_solo_resolve"
const EVENT_ROTATE_FILE_RESOLVE := "rotate_file_resolve"
## III-4 **3e**: depth fighter steps forward into rank-0 during envelop mop-up.
const EVENT_PLUG_FORWARD_RESOLVE := "plug_forward_resolve"
# Time to "ready" from idle: replicates gauge fill. agility 100 -> ~2s. Stagger for combat start.
const COOLDOWN_ACTION_READY_BASE := 2.0
# Seconds until EVENT_ACTION_READY. Prefix READY_DELAY_ = delay until next turn check.
const READY_DELAY_SKIP_DEFAULT_S := 0.5    # Skip (no actions): front rank
const READY_DELAY_SKIP_BACK_RANK_S := 2.0 # Skip (no actions): back rank "in reserve"
const READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S := 1.0 # III-6: depth spear lane open — faster recheck than reserve
const READY_DELAY_FORMATION_RECHECK_S := 0.2  # formation_changed → back rank re-evaluates
const READY_DELAY_AFTER_PROMOTION_S := 0.15   # Plug/swap → promoted unit acts soon
const READY_DELAY_PARRY_RIPOSTE_S := 0.02    # Parry deflect/partial → defender riposte
const READY_DELAY_CLOSE_ATTEMPT_S := 0.3     # Close attempt → next turn

# FF4 Formation + Stance (Phase 0 prep). See docs/LIVE_PATHS.md tier 0–1.
const SPACING_TIGHT := 0.9
const SPACING_NORMAL := 1.2
const SPACING_LOOSE := 1.8
const REACH_SAFETY_FACTOR := 0.8
const FLANK_PARRY_MOD := 0.8
const REAR_PARRY_MOD := 0.7
## Pack / protection-circle fallback: flank parry mod when `effective_pair_file_spacing_equivalent` ≥ this (Tier 3.1 — wedge/lane-aware; matches integer |Δfile|≥2 at default spacing).
const PARRY_FLANK_EFFECTIVE_FILES_MIN := 2.0
## Abstract strike **measure**: `melee_range / max(effective_pair_eff_dist, floor)` then clamp (Tier 3.1 — `CombatStrikeStamping.strike_measure_ratio_*`, `StrikeRealismProfile.measure_ratio`).
const STRIKE_MEASURE_EFF_DIST_FLOOR := 0.2
const STRIKE_MEASURE_RATIO_MIN := 0.75
const STRIKE_MEASURE_RATIO_MAX := 1.12
# Phase 4: ZoC — zone control thresholds and cross-zone support (tune in playtests).
const ZOC_ACCESS_THRESHOLD := 0.55
const ZOC_FRONT_SUPPORT_TO_FLANK := 0.35
const ZOC_FLANK_SUPPORT_TO_FRONT := 0.25
const ZOC_REAR_SUPPORT_FROM_FRONT := 0.2
const ZOC_CASUALTY_PER_BODY := 0.12
## Phase 6: Incursion pressure (front-rank imbalance) reduces raw zone strength before cross-zone blend.
const ZOC_INCURSION_ZONE_PENALTY := 0.38
## Lane stress fills only headroom above global incursion (same 0..INCURSION_PRESSURE_MAX scale) — avoids double-counting with global rank-delta.
const INCURSION_LANE_HEADROOM_FACTOR := 0.88
## Local lane stress 0..1 from formation (dual living in a cell, density). Not slot_obstacles — those stay in ZOC_CASUALTY_PER_BODY only.
const LANE_STRESS_DUAL_LIVING := 0.42
const LANE_STRESS_DENSITY_TIGHT := 0.12
const LANE_STRESS_DENSITY_LOOSE := -0.07
## --- Tier 1.3 P4 freeze: `lane_stress_by_file` + `lane_offset` ---
## **`lane_stress_by_file`**: per-formation file → 0..1 stress from dual occupancy + density (`TacticalCombat._recompute_lane_stress_by_file`).
## **`lane_offset`**: per-combatant float; **lateral offset within the nominal file column** feeding `CombatPairGeometry.effective_pair_eff_dist` (`EFF_DIST_LANE_OFFSET_FILE_EQUIV`). **Range:** clamp every writer/read to **`[-LANE_OFFSET_ABS_MAX, LANE_OFFSET_ABS_MAX]`** (currently **[-0.5, 0.5]**). **0** = column center. **Sign:** **positive** = toward **increasing file index** (+file / “enemy-right” on default symmetric grids). `CombatFormationFlow.repack_lane_offset_after_rank_file_change` + `CombatManager.register` defaults must stay inside this interval.
## Vacancy reconcile: lateral slides can open a hole in a neighbor file; repeat until stable (safety cap).
const FORMATION_VACANCY_RECONCILE_MAX_ROUNDS := 16
## Inner promotion chain per file per vacancy/death plug pass (one rank step + restart shallow scan per iteration).
const FORMATION_VACANCY_MICRO_STEPS_MAX := 24
## After an automatic vacancy/death plug moves a unit, that unit cannot be chosen as a plug donor again until this many seconds of `combat_clock` elapse (damps tick-by-tick lateral / chain thrash; abstract, not a long “realistic” delay).
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
## Per-combatant lateral metric — see **Tier 1.3 P4 freeze** block above (§4.2).
const LANE_OFFSET_DEFAULT := 0.0
const LANE_OFFSET_ABS_MAX := 0.5
## effective_pair_eff_dist: |Δlane_offset| as fraction of a file spacing equivalent before ZoC mult.
const EFF_DIST_LANE_OFFSET_FILE_EQUIV := 0.42
## `CombatDistanceBands`: MID vs LONG uses `effective_pair_file_spacing_equivalent` vs `mid_reach_files`; slack avoids float edge flicker with lane_offset.
const DIST_BAND_MID_FILE_EQUIV_SLACK := 0.38
## How strongly incursion penalty applies per zone (rear echelon less exposed to “line buckling” than front).
const ZOC_INCURSION_EXPOSURE_FRONT := 1.0
const ZOC_INCURSION_EXPOSURE_FLANK := 0.9
const ZOC_INCURSION_EXPOSURE_REAR := 0.36
## Weak front ZoC (both lines) scales geometric pair distance down — lines feel closer, easier to bridge.
const ZOC_GEOMETRIC_EXTENT_MIN := 0.78
## Getting hit during formation move: below cancel threshold extends duration; at/above cancels the move.
const FORMATION_HIT_REACTION_EXTRA_S := 0.38
const FORMATION_HIT_CANCEL_INTENSITY := 0.72
## Tier 0 pilot: overlapping melee wind-ups on one defender — parry only the highest-threat attacker.
## Tier 6.1: sustained high pain rolls for pain shock during combat ticks (see **`EntityPainConsciousness.try_ambient_pain_shock_tick`**).
const FEATURE_AMBIENT_PAIN_SHOCK := true
static var _feature_ambient_pain_shock: bool = FEATURE_AMBIENT_PAIN_SHOCK


static func is_feature_ambient_pain_shock() -> bool:
	return _feature_ambient_pain_shock


static func set_feature_ambient_pain_shock(on: bool) -> void:
	_feature_ambient_pain_shock = on


const FEATURE_INCOMING_PARRY_CHOICE := true
const INCOMING_MELEE_PARRY_WINDOW_S := 0.25
## Simultaneous parry-all: sum of incoming **`parry_p_a`** must fit under min split **`parry_c_d`** × dodge ratio × this.
## Retuned 0.88→0.45 when **`can_parry_all`** uses live sector **`surround_threat_weight_sum`** (III-1).
const INCOMING_PARRY_ALL_COMBINED_P_A_BUDGET_MULT := 0.45
## Per-move override optional in `WeaponConstants` (`parry_telegraph` 0–1). Base from intensity × power × follow_through × contact mult.
const PARRY_TELEGRAPH_CONTACT_MULT_CUT := 1.0
const PARRY_TELEGRAPH_CONTACT_MULT_STAB := 0.88
const PARRY_TELEGRAPH_CONTACT_MULT_BLUNT := 1.12
## Feint wind-ups: apparent telegraph multiplier until reveal (defender perception lerps toward true).
const PARRY_TELEGRAPH_FEINT_APPARENT_MULT := 1.22
## High perception reads through feint telegraph faster (0 = reveal curve only; 1 = full bonus at 100 PER).
const PARRY_TELEGRAPH_PERCEPTION_READ_BONUS := 0.38


static func parry_telegraph_contact_mult(contact_type: String) -> float:
	match str(contact_type).to_lower():
		"stab":
			return PARRY_TELEGRAPH_CONTACT_MULT_STAB
		"blunt":
			return PARRY_TELEGRAPH_CONTACT_MULT_BLUNT
		_:
			return PARRY_TELEGRAPH_CONTACT_MULT_CUT


## Defender blade extended (e.g. recovering from own attack) — passive parry capacity scale.
const WEAPON_EXTENDED_PARRY_MULT := 0.85
## Incoming attack past wind-up commit (attacker blade extended): defender passive parry capacity scale.
const WEAPON_COMMITTED_ATTACK_PARRY_C_D_MULT := 0.92
## Wind-up progress at/above this fraction → weapon extended for **`CombatWeaponPosition`** (move may override).
const WEAPON_EXTENDED_COMMIT_FRACTION := 0.7
## Inferred commit fractions when a move omits **`weapon_extension_commit_fraction`** (see **`CombatWeaponPosition.commit_fraction_from_move_def`**).
const WEAPON_COMMIT_FRACTION_STAB := 0.58
const WEAPON_COMMIT_FRACTION_CUT := 0.72
const WEAPON_COMMIT_FRACTION_OVERHEAD := 0.78
const WEAPON_COMMIT_FRACTION_BLUNT := 0.76
const WEAPON_COMMIT_FRACTION_QUICK := 0.62
## Armor mass vs ~full medieval kit; lerps formation-move duration toward FORMATION_ARMOR_MAX_SLOW_MULT.
const FORMATION_ARMOR_MASS_REF_KG := 28.0
const FORMATION_ARMOR_MAX_SLOW_MULT := 1.35

## IV-7: equipped armor mass lengthens **`action_ready_cooldown`** and lowers passive parry readiness.
const FEATURE_ARMOR_BURDEN := true
static var _feature_armor_burden_load: int = -1


static func is_feature_armor_burden_enabled() -> bool:
	if _feature_armor_burden_load >= 0:
		return _feature_armor_burden_load != 0
	return FEATURE_ARMOR_BURDEN


static func set_feature_armor_burden_load(enabled: bool) -> void:
	_feature_armor_burden_load = 1 if enabled else 0


## Max **`action_ready_cooldown`** mult at **`FORMATION_ARMOR_MASS_REF_KG`** (full kit).
const ARMOR_BURDEN_ACTION_READY_MAX_MULT := 1.28
## Passive readiness floor at full kit (WAITING **`guard`** × this; RECOVERING curve scaled same).
const ARMOR_BURDEN_PASSIVE_READINESS_FLOOR := 0.78


static func armor_burden_mass_ratio_for_combatant(combatant: Dictionary) -> float:
	if combatant.is_empty():
		return 0.0
	var node: Node = _EntityAccess.scene_node(combatant)
	if node == null:
		return 0.0
	var mass_kg: float = _EntityAccess.get_total_armor_mass_kg_from_node(node)
	return clampf(mass_kg / FORMATION_ARMOR_MASS_REF_KG, 0.0, 1.5)


static func armor_burden_action_ready_mult(combatant: Dictionary) -> float:
	if not is_feature_armor_burden_enabled():
		return 1.0
	var t: float = clampf(armor_burden_mass_ratio_for_combatant(combatant), 0.0, 1.0)
	return lerpf(1.0, ARMOR_BURDEN_ACTION_READY_MAX_MULT, t)


static func armor_burden_passive_readiness_mult(combatant: Dictionary) -> float:
	if not is_feature_armor_burden_enabled():
		return 1.0
	var t: float = clampf(armor_burden_mass_ratio_for_combatant(combatant), 0.0, 1.0)
	return lerpf(1.0, ARMOR_BURDEN_PASSIVE_READINESS_FLOOR, t)


## IV-8: combat-start **`EVENT_ACTION_READY`** stagger by initiative score (agi+perc, rank, armor burden).
const FEATURE_INITIATIVE_ORDER := true
static var _feature_initiative_order_load: int = -1
## Extra delay per initiative rank after sorting (best = rank 0, no extra).
const INITIATIVE_ORDER_STAGGER_STEP_S := 0.08


static func is_feature_initiative_order_enabled() -> bool:
	if _feature_initiative_order_load >= 0:
		return _feature_initiative_order_load != 0
	return FEATURE_INITIATIVE_ORDER


static func set_feature_initiative_order_load(enabled: bool) -> void:
	_feature_initiative_order_load = 1 if enabled else 0


## IV-9: gap-column slot topology — intentional file gaps; disables naive native-line compaction.
const FEATURE_GAP_COLUMN_TOPOLOGY := false
static var _feature_gap_column_topology_load: int = -1


static func is_feature_gap_column_topology_enabled() -> bool:
	if _feature_gap_column_topology_load >= 0:
		return _feature_gap_column_topology_load != 0
	return FEATURE_GAP_COLUMN_TOPOLOGY


static func set_feature_gap_column_topology_load(enabled: bool) -> void:
	_feature_gap_column_topology_load = 1 if enabled else 0


## Doc-sync line for calibration audit / III-4 Track B worksheet.
static func iv9_gap_column_doc_sync_line() -> String:
	return (
		(
			"IV-9 gap-column: default_flag=%s compact_native_line=disabled_when_on "
			+ "slots=occupied_files_have_gaps slice2=column_graph_file_distance+diagram_gaps "
			+ "pair_geometry=column_arc_when_gaps harness=dual_mode_formation_targeting "
			+ "flow_refresh=swap_drag_fall_back_reconcile"
		)
		% ("on" if FEATURE_GAP_COLUMN_TOPOLOGY else "off")
	)


## Higher score → earlier first turn at combat start (IV-7 armor burden lowers score).
static func initiative_score_for_combatant(combatant: Dictionary) -> float:
	if combatant.is_empty():
		return 0.0
	var stats: Dictionary = _EntityAccess.stats_dict(combatant)
	var agi: float = float(stats.get("agility", 100))
	var perc: float = float(stats.get("perception", 100))
	var rank_factor: float = maxf(0.65, 1.2 - float(_EntityAccess.rank_int(combatant)) * 0.18)
	var armor_factor: float = 1.0 / maxf(0.01, armor_burden_action_ready_mult(combatant))
	return stats_factor_agi_perc(agi, perc) * rank_factor * armor_factor


## Sort **`schedule_initial_action_ready_events`** when IV-8 on; tie-break matches event queue (agi desc, id asc).
static func compare_combatants_for_initiative_order(a: Dictionary, b: Dictionary) -> bool:
	var sa: float = initiative_score_for_combatant(a)
	var sb: float = initiative_score_for_combatant(b)
	if sa != sb:
		return sa > sb
	var agi_a: int = int(_EntityAccess.stats_dict(a).get("agility", 100))
	var agi_b: int = int(_EntityAccess.stats_dict(b).get("agility", 100))
	if agi_a != agi_b:
		return agi_a > agi_b
	return _EntityAccess.id_int(a) < _EntityAccess.id_int(b)


## IV-10: resolved **`hit_sub_region`** scales post-armor mechanical cut/blunt (severity table; no double-apply at wound map).
const FEATURE_SUBREGION_COMBAT_MULT := true
static var _feature_subregion_combat_mult_load: int = -1


static func is_feature_subregion_combat_mult_enabled() -> bool:
	if _feature_subregion_combat_mult_load >= 0:
		return _feature_subregion_combat_mult_load != 0
	return FEATURE_SUBREGION_COMBAT_MULT


static func set_feature_subregion_combat_mult_load(enabled: bool) -> void:
	_feature_subregion_combat_mult_load = 1 if enabled else 0


## IV-11 slice 1: party leader lists instant doctrine commands (`order_hold_lane`); default off until playtest.
const FEATURE_LEADER_FORMATION_COMMAND := false
static var _feature_leader_formation_command_load: int = -1


static func is_feature_leader_formation_command_enabled() -> bool:
	if _feature_leader_formation_command_load >= 0:
		return _feature_leader_formation_command_load != 0
	return FEATURE_LEADER_FORMATION_COMMAND


static func set_feature_leader_formation_command_load(enabled: bool) -> void:
	_feature_leader_formation_command_load = 1 if enabled else 0


## Headless harness: clear **`set_feature_*_load`** overrides so **`run_all()`** / `-HarnessMode regression` starts from production defaults.
static func reset_harness_feature_load_overrides() -> void:
	_feature_ms_feint_resistance_load = -1
	_feature_ms_post_strike_load = -1
	_feature_ms_positional_awareness_load = -1
	_feature_ms_l6_rout_load = -1
	_feature_ms_mid_infight_med_load = -1
	_feature_armor_burden_load = -1
	_feature_initiative_order_load = -1
	_feature_gap_column_topology_load = -1
	_feature_subregion_combat_mult_load = -1
	_feature_leader_formation_command_load = -1
	_feature_iv12_slot_distraction_load = -1
	_feature_iv13_weapon_reach_zoc_load = -1
	_feature_t44_spatial_band_pa_load = -1
	_feature_t44_spatial_file_dodge_bias_load = -1
	_feature_t44_spatial_flurry_pa_load = -1
	_feature_hema_eight_guard_lines_load = -1
	_feature_arm_interpose_load = -1
	_feature_iv6_attack_path_octant_load = -1


## IV-12 slice 1: co-located hostile slot mates add sector distraction load (default off).
const FEATURE_IV12_SLOT_DISTRACTION := false
static var _feature_iv12_slot_distraction_load: int = -1
## Extra surround weight when 2+ living threats share one opponent slot cell.
const IV12_SLOT_DISTRACTION_WEIGHT_PAD := 0.35
## IV-12 slice 2: co-located slot-mate already threatening defender → AI pile-on bias.
const IV12_AI_COLOCATED_TARGET_BIAS_MULT := 1.12
## IV-12 slice 2: AI hostile pick damp when co-located slot distraction pad is active.
const IV12_AI_OFFENSE_WEIGHT_MULT := 0.78


static func is_feature_iv12_slot_distraction_enabled() -> bool:
	if _feature_iv12_slot_distraction_load >= 0:
		return _feature_iv12_slot_distraction_load != 0
	return FEATURE_IV12_SLOT_DISTRACTION


static func set_feature_iv12_slot_distraction_load(enabled: bool) -> void:
	_feature_iv12_slot_distraction_load = 1 if enabled else 0


static func iv12_slot_distraction_doc_sync_line() -> String:
	var feat: String = "on" if FEATURE_IV12_SLOT_DISTRACTION else "off"
	return (
		"IV-12 slot distraction: feature=" + feat
		+ " pad=" + str(snappedf(IV12_SLOT_DISTRACTION_WEIGHT_PAD, 0.01))
		+ " ai_offense=" + str(snappedf(IV12_AI_OFFENSE_WEIGHT_MULT, 0.01))
		+ " ai_pile_on=" + str(snappedf(IV12_AI_COLOCATED_TARGET_BIAS_MULT, 0.01))
		+ " slice3=formation_slot_cell drag_back_dual_occ"
	)


## IV-13: weapon reach extends threaten range when ZoC front is weak (wide lines only; default off).
const FEATURE_IV13_WEAPON_REACH_ZOC := false
static var _feature_iv13_weapon_reach_zoc_load: int = -1
const IV13_WEAPON_REACH_ZOC_REF_M := 1.5
const IV13_WEAPON_REACH_ZOC_SPAN_M := 1.0
const IV13_WEAPON_REACH_ZOC_MAX_BONUS_M := 0.35
const IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX := 0.55


static func is_feature_iv13_weapon_reach_zoc_enabled() -> bool:
	if _feature_iv13_weapon_reach_zoc_load >= 0:
		return _feature_iv13_weapon_reach_zoc_load != 0
	return FEATURE_IV13_WEAPON_REACH_ZOC


static func set_feature_iv13_weapon_reach_zoc_load(enabled: bool) -> void:
	_feature_iv13_weapon_reach_zoc_load = 1 if enabled else 0


static func iv13_weapon_reach_zoc_doc_sync_line() -> String:
	return (
		"IV-13 weapon-reach ZoC: feature=%s weak_front<%.2f max_bonus=%.2fm ref=%.1fm"
		% [
			"on" if FEATURE_IV13_WEAPON_REACH_ZOC else "off",
			IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX,
			IV13_WEAPON_REACH_ZOC_MAX_BONUS_M,
			IV13_WEAPON_REACH_ZOC_REF_M,
		]
	)


## Tier 4.4 spatial slice 1: engagement band scales PA step magnitude (CLOSE > LONG).
const FEATURE_T44_SPATIAL_BAND_PA := true
static var _feature_t44_spatial_band_pa_load: int = -1
const T44_SPATIAL_BAND_PA_MULT_CLOSE := 1.12
const T44_SPATIAL_BAND_PA_MULT_MID := 1.0
const T44_SPATIAL_BAND_PA_MULT_LONG := 0.88


static func is_feature_t44_spatial_band_pa_enabled() -> bool:
	if _feature_t44_spatial_band_pa_load >= 0:
		return _feature_t44_spatial_band_pa_load != 0
	return FEATURE_T44_SPATIAL_BAND_PA


static func set_feature_t44_spatial_band_pa_load(enabled: bool) -> void:
	_feature_t44_spatial_band_pa_load = 1 if enabled else 0


## Tier 4.4 spatial slice 2: wing file scales defender **dodge** PA step (wing > interior, files ≥ 2).
const FEATURE_T44_SPATIAL_FILE_DODGE_BIAS := true
static var _feature_t44_spatial_file_dodge_bias_load: int = -1
const T44_SPATIAL_FILE_DODGE_WING_MULT := 1.1


static func is_feature_t44_spatial_file_dodge_bias_enabled() -> bool:
	if _feature_t44_spatial_file_dodge_bias_load >= 0:
		return _feature_t44_spatial_file_dodge_bias_load != 0
	return FEATURE_T44_SPATIAL_FILE_DODGE_BIAS


static func set_feature_t44_spatial_file_dodge_bias_load(enabled: bool) -> void:
	_feature_t44_spatial_file_dodge_bias_load = 1 if enabled else 0


## 1.0 on interior files; **`T44_SPATIAL_FILE_DODGE_WING_MULT`** on file 0 / file max when files ≥ 2.
static func t44_spatial_file_dodge_wing_mult(file_index: int, formation_files: int) -> float:
	if not is_feature_t44_spatial_file_dodge_bias_enabled():
		return 1.0
	var files: int = maxi(1, formation_files)
	if files < 2:
		return 1.0
	var fi: int = maxi(0, file_index)
	if fi <= 0 or fi >= files - 1:
		return T44_SPATIAL_FILE_DODGE_WING_MULT
	return 1.0


static func t44_spatial_file_dodge_doc_sync_line() -> String:
	return (
		"T44 spatial file dodge: feature=%s wing_mult=%.2f slice2=wing_file_dodge_step_bias"
		% [
			"on" if FEATURE_T44_SPATIAL_FILE_DODGE_BIAS else "off",
			T44_SPATIAL_FILE_DODGE_WING_MULT,
		]
	)


## Tier 4.4 spatial slice 3: bind-exchange flurry window scales PA step magnitude (active flurry bind boost).
const FEATURE_T44_SPATIAL_FLURRY_PA := true
static var _feature_t44_spatial_flurry_pa_load: int = -1
const T44_SPATIAL_FLURRY_PA_MULT := 1.08


static func is_feature_t44_spatial_flurry_pa_enabled() -> bool:
	if _feature_t44_spatial_flurry_pa_load >= 0:
		return _feature_t44_spatial_flurry_pa_load != 0
	return FEATURE_T44_SPATIAL_FLURRY_PA


static func set_feature_t44_spatial_flurry_pa_load(enabled: bool) -> void:
	_feature_t44_spatial_flurry_pa_load = 1 if enabled else 0


static func t44_spatial_flurry_pa_doc_sync_line() -> String:
	return (
		"T44 spatial flurry PA: feature=%s mult=%.2f slice3=flurry_bind_pa_boost"
		% [
			"on" if FEATURE_T44_SPATIAL_FLURRY_PA else "off",
			T44_SPATIAL_FLURRY_PA_MULT,
		]
	)


static func t44_spatial_band_pa_magnitude_mult(band: String) -> float:
	match str(band):
		DISTANCE_CLOSE:
			return T44_SPATIAL_BAND_PA_MULT_CLOSE
		DISTANCE_LONG:
			return T44_SPATIAL_BAND_PA_MULT_LONG
		_:
			return T44_SPATIAL_BAND_PA_MULT_MID


static func t44_spatial_band_pa_doc_sync_line() -> String:
	return (
		"T44 spatial band PA: feature=%s close=%.2f mid=%.2f long=%.2f slice1=engagement_band_step_magnitude"
		% [
			"on" if FEATURE_T44_SPATIAL_BAND_PA else "off",
			T44_SPATIAL_BAND_PA_MULT_CLOSE,
			T44_SPATIAL_BAND_PA_MULT_MID,
			T44_SPATIAL_BAND_PA_MULT_LONG,
		]
	)


## IV-11 doc-sync: leader formation abilities (slices 1–10); flag default off until playtest.
static func iv11_leader_formation_doc_sync_line() -> String:
	var feat: String = "on" if FEATURE_LEADER_FORMATION_COMMAND else "off"
	return (
		"IV-11 leader formation: slice1=focus_line_telegraph_match "
		+ "slice3=register_stamp+formatter "
		+ "slice4=bridge_roster_stamp+diagram_callout "
		+ "is_party_leader=CombatManager.register "
		+ "weight="
		+ str(snappedf(AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT, 0.1))
		+ " menu_abilities=roster_suffix "
		+ "order_hold_lane_feature="
		+ feat
		+ " issuer=is_formation_command_issuer menu_label=Order_Hold_lane "
		+ "slice5=order_probing menu_label_probing=Order_Probe "
		+ "slice6=enemy_leader diagram_cmd=[Cmd] "
		+ "slice7=roster_menu_leader_suffix "
		+ "slice8=order_pinch_center menu_label_pinch=Order_Pinch_center "
		+ "slice9=enemy_commander_orders+doctrine_cycle ai_pick="
		+ str(snappedf(AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT, 0.01))
		+ " slice10=pinch_outnumber_ai_mult="
		+ str(snappedf(AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT, 0.01))
		+ " f5_track=iv11_leader_order encounter_spawn=enemy_leader_index"
	)


## IV-8 doc-sync line (harness / calibration audit).
static func iv8_initiative_doc_sync_line() -> String:
	return (
		"IV-8 initiative: stagger_step=%.2fs score=agi+perc*rank*armor_inv"
		% INITIATIVE_ORDER_STAGGER_STEP_S
	)
## Phase 6: Surround — cap divisor for defense split (checklist §4).
const SURROUND_MAX_SPLIT_DIVISOR := 4
## At perception 0, awareness factor floor when multiple engaging threats.
const SURROUND_AWARENESS_AT_LOW_PERCEPTION := 0.65
## Phase 6: Incursion pressure per extra enemy front-rank fighter vs ours (clamped).
const INCURSION_PRESSURE_PER_RANK_ADVANTAGE := 0.12
const INCURSION_PRESSURE_MAX := 0.45
const STANCE_DEFENSIVE := "defensive"
const STANCE_BALANCED := "balanced"
const STANCE_AGGRESSIVE := "aggressive"
const STANCE_CONTROLLING := "controlling"
## Min burst ratio (vs **`CombatExhaustion.effective_stamina_max`**) for stance to read as pressuring.
const STANCE_MIN_STAMINA_AGGRESSIVE_RATIO := 0.30
const STANCE_MIN_STAMINA_CONTROLLING_RATIO := 0.24
## Opponent front-rank average burst ratio below this → defensive pressure (disengage faster).
const OPPONENT_PRESSURE_DEFENSIVE_STAMINA_RATIO := 0.35
# Swap rank / fall back: time-based, no stamina. Lane: clear=1.0, crowded=1.3, blocked=1.6. Pressure: defensive=0.9, neutral=1.0, aggressive=1.3.
const BASE_FALL_BACK_S := 1.0
const LANE_MOD_CLEAR := 1.0
const LANE_MOD_CROWDED := 1.3
const LANE_MOD_BLOCKED := 1.6
## Formation-move AI: damp **`rotate_file`** (and similar) when lane timing is blocked.
const AI_FORMATION_MOVE_BLOCKED_LANE_MULT := 0.22
const PRESSURE_MOD_DEFENSIVE := 0.9
const PRESSURE_MOD_NEUTRAL := 1.0
const PRESSURE_MOD_AGGRESSIVE := 1.3
## Step over fallen: extra duration multiplier when slot_obstacles present (Part 4.5).
const FOOTING_STEP_OVER_MIN := 1.15
const FOOTING_STEP_OVER_MAX := 1.25
## Drag wounded to rear — slower than quick swap.
const DRAG_BACK_DURATION_MULT := 1.15
## After a formation pair-move abort, block immediate re-issue for the same unit briefly (prevents retry thrash loops under pressure/hit-interrupt churn).
const FORMATION_PAIR_ABORT_RETRY_COOLDOWN_S := 0.7
## Rotate-file anti-thrash: brief cooldown after a completed same-rank file swap so front units don't ping-pong lanes every turn.
const FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S := 0.8
## Block re-rotating with the same adjacent partner until lock expires (stops A↔B swap loops while rank-0 holes remain).
const FORMATION_ROTATE_FILE_REVERSE_PAIR_LOCK_S := 6.0
const STATE_FALLING_BACK := "falling_back"
const STATE_SWAP_RANK := "swap_rank"
## III-4 **3e**: depth fighter steps forward into rank-0 during envelop mop-up.
const STATE_PLUG_FORWARD := "plug_forward"
const MOVE_ID_SWAP_RANK := "swap_rank"
## Phase 5: formation movement (time-based, no stamina).
const MOVE_ID_DRAG_BACK := "drag_back"
const MOVE_ID_FALL_BACK := "fall_back"
const MOVE_ID_ROTATE_FILE := "rotate_file"
## III-4 **3e**: depth fighter steps forward into rank-0 during envelop mop-up.
const MOVE_ID_PLUG_FORWARD := "plug_forward"
const FORMATION_MOVE_KIND_SWAP_RANK := MOVE_ID_SWAP_RANK
const FORMATION_MOVE_KIND_DRAG_BACK := MOVE_ID_DRAG_BACK
const FORMATION_MOVE_KIND_FALL_BACK_PAIR := "fall_back_pair"
## Tier 6.2: leave the engagement (not a rank swap / solo fall_back within the line).
const MOVE_ID_FLEE := "flee"
## IV-11: party leader instant formation command (doctrine shift; not slot movement).
const MOVE_ID_ORDER_HOLD_LANE := "order_hold_lane"
const MOVE_ID_ORDER_PROBING := "order_probing"
const MOVE_ID_ORDER_PINCH_CENTER := "order_pinch_center"
const LEADER_FORMATION_COMMAND_MOVE_IDS: Array[String] = [
	MOVE_ID_ORDER_HOLD_LANE,
	MOVE_ID_ORDER_PROBING,
	MOVE_ID_ORDER_PINCH_CENTER,
]
## Swap / drag / fall back / rotate / flee — used so "only formation moves" still offers wait.
const FORMATION_MOVEMENT_MOVE_IDS: Array[String] = [
	MOVE_ID_SWAP_RANK, MOVE_ID_DRAG_BACK, MOVE_ID_FALL_BACK, MOVE_ID_ROTATE_FILE, MOVE_ID_FLEE, MOVE_ID_PLUG_FORWARD
]


static func is_formation_movement_move(move_id: String) -> bool:
	return str(move_id) in FORMATION_MOVEMENT_MOVE_IDS


static func is_leader_formation_command_move(move_id: String) -> bool:
	return str(move_id) in LEADER_FORMATION_COMMAND_MOVE_IDS


static func is_formation_reposition_move(move_id: String) -> bool:
	return is_formation_movement_move(move_id) and str(move_id) != MOVE_ID_FLEE


static func is_partner_formation_move(move_id: String) -> bool:
	var mid := str(move_id)
	return mid == MOVE_ID_SWAP_RANK or mid == MOVE_ID_DRAG_BACK or mid == MOVE_ID_FALL_BACK or mid == MOVE_ID_PLUG_FORWARD


static func is_plug_forward_move(move_id: String) -> bool:
	return str(move_id) == MOVE_ID_PLUG_FORWARD


static func is_formation_pair_move_kind(move_kind: String) -> bool:
	var k := str(move_kind)
	return (
		k == FORMATION_MOVE_KIND_SWAP_RANK
		or k == FORMATION_MOVE_KIND_DRAG_BACK
		or k == FORMATION_MOVE_KIND_FALL_BACK_PAIR
		or k == MOVE_ID_PLUG_FORWARD
	)


static func formation_pair_move_kind_for_menu_move(move_id: String) -> String:
	match str(move_id):
		MOVE_ID_SWAP_RANK:
			return FORMATION_MOVE_KIND_SWAP_RANK
		MOVE_ID_DRAG_BACK:
			return FORMATION_MOVE_KIND_DRAG_BACK
		MOVE_ID_FALL_BACK:
			return FORMATION_MOVE_KIND_FALL_BACK_PAIR
		MOVE_ID_PLUG_FORWARD:
			return MOVE_ID_PLUG_FORWARD
		_:
			return str(move_id)
## Tactical rank penetration (0 = at their front line). Not armor RHA penetration.
const TACTICAL_PENETRATION_DEPTH_MAX := 2
## Extra damp when this side has very few standing fighters (duel / skirmish attrition).
const AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT := 0.72
## Tier 1.6 (P7): `CombatTargetScoring.ai_targeting_weight_mult` — melee/close: resolved **`engagement_mode`**, our posture+cohesion + **opponent** formation, stance.
const AI_TARGETING_LINE_COH_LO_MULT := 0.94
const AI_TARGETING_LINE_COH_HI_MULT := 1.03
const AI_TARGETING_OPEN_COH_TIGHT_MULT := 1.0
const AI_TARGETING_OPEN_COH_LOOSE_MULT := 1.06
## Tier 1.6 breadth: hostile pick vs **opponent** LINE `line_cohesion` (solid enemy wall → slight hedge; ragged → press).
const AI_TARGETING_OPP_LINE_COH_SOLID_MULT := 0.96
const AI_TARGETING_OPP_LINE_COH_RAGGED_MULT := 1.04
## Dispersed enemy posture (OPEN/DUEL) — small isolation / pick-off nudge.
const AI_TARGETING_OPP_OPEN_DUEL_MULT := 1.03
## Tier 1.6 / 1.7: resolved `CombatEngagementMode.engagement_mode` on listed hostile weights (`CombatTargetScoring`).
const AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT := 1.04
const AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT := 1.0
const AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT := 1.025
## Tier 1.6: `hostile_pair_targeting_weight_mult` scales down listed hostile picks vs **incapacitated** defenders (still valid targets if actions list them).
const AI_TARGETING_INCAP_HOSTILE_MULT := 0.42
## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — **`WeaponConstants.is_feint_move(move_id)`** hostile attacks get this multiplier (AI listing only).
const AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT := 1.06
## Tier 4.2: on top of **`AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`**, feint hostile weights scale by **`lerpf(1.0, this, pr_def)`** where **`pr_def`** = **`clampf(get_passive_parry_readiness × passive_parry_readiness_incoming_contact_mult × defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio), 0, 1)`** on the defender (WAITING uses **`guard`**).
const AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT := 1.10
## Tier 4.2: when attacker **`stamina_ratio` < `AI_FEINT_LISTING_STAMINA_GATE`**, multiply feint listing only by **`lerpf(AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO, 1.0, stamina_ratio / gate)`** (gassed attackers list feints less).
const AI_FEINT_LISTING_STAMINA_GATE := 0.30
const AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO := 0.86
## Tier 4.2: formation **`doctrine`** **`probing`** — multiply feint-move listing weight only (**`CombatDoctrine.doctrine_for_fid`** on attacker **`formation_id`**).
const AI_FEINT_LISTING_DOCTRINE_PROBING_MULT := 1.04
## Tier 4.2: formation **`doctrine`** **`pinch_center`** — feint listing nudge (inward-pressure doctrine; AI listing only).
const AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT := 1.03
## Tier 4.2: formation **`doctrine`** **`hold_lane`** — feint listing dampen (disciplined line; AI listing only).
const AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT := 0.97
## Tier 4.2: after defender **`parry_deflect`**, feint-move listing vs that defender scales up to this mult while **`CombatManager.get_combat_tick_index() - stored_tick ≤ AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS`** (then lerps to **1**).
const AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT := 1.05
## Tier 4.2: combat ticks over which **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT`** lerps back to **1** after a **`parry_deflect`** (see **`CombatProcessTick`**).
const AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS := 8
## Tier 4.2: defender **`PassiveParryContext.is_off_balance`** while **`STATE_WAITING`** — multiply feint-move listing vs that defender (footwork / tempo).
const AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT := 1.06
## Tier 1.9 (P10): depth rank + open spear lane — AI favors thrusts over cuts/closes (CombatAIActionPicker).
const DEPTH_POLEARM_AI_STAB_WEIGHT_MULT := 1.35
const DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT := 0.9
const DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT := 0.82
## Tier 1.9: depth rank + open lane — formation **`doctrine`** scales stab vs cut listing weights (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
const DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT := 1.08
const DEPTH_POLEARM_AI_DOCTRINE_HOLD_STAB_MULT := 0.94
const DEPTH_POLEARM_AI_DOCTRINE_PINCH_NON_STAB_MULT := 0.92
const DEPTH_POLEARM_AI_DOCTRINE_HOLD_NON_STAB_MULT := 1.06
## Tier 1.9: **`DOCTRINE_PROBING`** — depth stab/cut weights between **hold** and **pinch** (listed actions only).
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
## Tier 1.9: max |Δfile| between **same-file rank-0 ally** and **enemy rank 0** for depth polearm lane thrusts.
## 0 = only the opposed file; 1 = immediate neighbor files (reach + `effective_pair_eff_dist` still gate strikes).
const DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES := 1
## Tier 1.9: max(pressure, depth) at this file ≥ this → depth spear may target legs even when density is tight/normal (wedge gap).
const DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN := 0.38
## Alias for lane-stress open threshold (`CombatDepthPolearm`, post–intrusion removal).
const DEPTH_SPEAR_LANE_STRESS_OPEN_MIN := DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN
## Tier 3.1: depth spear **over-shoulder** lane (`depth_polearm_allows_low_targets` false) — defender parry capacity vs that thrust line.
const DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT := 1.06
## Tier 3.1: depth spear **open** lane + stab — attacker momentum seen at parry (full high/low envelope).
const DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT := 1.05
## Tier 3.1: depth rank stab through an open spear lane — closing-speed proxy (`StrikePhysics`, `AttackResolver` ctx).
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
## Tier 6.2: optional rout gates on **`start()`** preset dict — wins over encounter **`ENCOUNTER_KEY_FLEE_*`** for that side.
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

## Phase D: sector-weighted surround load vs integer-only threat count (Tier 3.1).
## Default **true** (sector `surround_threat_weight_sum` + `1/(1+k·excess)`). **`set_feature_sector_surround_load(false)`** for integer `surround_threat_count` regression / compare.
static var _feature_sector_surround_load: bool = true


static func is_feature_sector_surround_load() -> bool:
	return _feature_sector_surround_load


static func set_feature_sector_surround_load(on: bool) -> void:
	_feature_sector_surround_load = on
## First `SURROUND_SECTOR_LOAD_FREE` units of summed threat weight incur no surround split (one primary engagement axis).
const SURROUND_SECTOR_LOAD_FREE := 1.0
## After free allowance: `mult = 1/(1 + k * excess)` before perception; `k=1` matches integer-only `1/n` when each threat weight is 1.
const SURROUND_SECTOR_LOAD_K := 1.0
## Minimum per threatening enemy weight = clamp(`effective_pair_file_spacing_equivalent` / `PARRY_FLANK_EFFECTIVE_FILES_MIN`, min, 1).
const SURROUND_SECTOR_WEIGHT_MIN := 0.35
## HEMA Method C: eight guard/attack lines (45° octants). **`CombatGuardLines`**.
const FEATURE_HEMA_EIGHT_GUARD_LINES := true
static var _feature_hema_eight_guard_lines_load: int = -1


static func is_feature_hema_eight_guard_lines_enabled() -> bool:
	if _feature_hema_eight_guard_lines_load >= 0:
		return _feature_hema_eight_guard_lines_load != 0
	return FEATURE_HEMA_EIGHT_GUARD_LINES


static func set_feature_hema_eight_guard_lines_load(enabled: bool) -> void:
	_feature_hema_eight_guard_lines_load = 1 if enabled else 0


## IV-5 BP6: misaligned guard but attack-side arm on intercept path boosts parry alignment + hit weight.
const FEATURE_ARM_INTERPOSE := true
static var _feature_arm_interpose_load: int = -1


static func is_feature_arm_interpose_enabled() -> bool:
	if _feature_arm_interpose_load >= 0:
		return _feature_arm_interpose_load != 0
	return FEATURE_ARM_INTERPOSE


static func set_feature_arm_interpose_load(enabled: bool) -> void:
	_feature_arm_interpose_load = 1 if enabled else 0


## IV-6: per-octant **`ATTACK_PATHS_BY_GUARD`** — flank diagonal merges flank + vertical cardinal paths (zone part first).
const FEATURE_IV6_ATTACK_PATH_OCTANT := true
static var _feature_iv6_attack_path_octant_load: int = -1


static func is_feature_iv6_attack_path_octant_enabled() -> bool:
	if _feature_iv6_attack_path_octant_load >= 0:
		return _feature_iv6_attack_path_octant_load != 0
	return FEATURE_IV6_ATTACK_PATH_OCTANT


static func set_feature_iv6_attack_path_octant_load(enabled: bool) -> void:
	_feature_iv6_attack_path_octant_load = 1 if enabled else 0


## Min guard–attack angle (°) before arm interpose applies; align band [`ARM_INTERPOSE_MIN_ALIGN`, `ARM_INTERPOSE_MAX_ALIGN`).
const ARM_INTERPOSE_MIN_ANGLE_DEG := 45.0
const ARM_INTERPOSE_MIN_ALIGN := PARRY_ALIGNMENT_FLOOR
const ARM_INTERPOSE_MAX_ALIGN := 0.72
const ARM_INTERPOSE_ALIGNMENT_BOOST := 0.22
const ARM_INTERPOSE_MAX_PATH_INDEX := 4
const ARM_INTERPOSE_HIT_WEIGHT_MULT := 1.55


## Front-arc occupancy for surround threat weight (physical cap vs abstract slot count).
const FEATURE_SURROUND_ARC_OCCUPANCY := true
const SURROUND_ARC_HALF_WIDTH_DEG := 38.0
const SURROUND_ARC_OVERLAP_TOLERANCE_DEG := 6.0
const SURROUND_ARC_BLOCKED_THREAT_WEIGHT_MULT := 0.35


static func is_feature_surround_arc_occupancy_enabled() -> bool:
	return FEATURE_SURROUND_ARC_OCCUPANCY


## Engagement mode (duel / skirmish / formation) from live front-rank state — see ENGAGEMENT_MODE_* below.
## Option 4 pilot: `CombatDoctrine.evaluate_automatic_doctrine` may set **`pinch_center`** from a hollow enemy front (only when formation doctrine is still **default**).
const FEATURE_AUTOMATIC_DOCTRINE := true
## p4c: min extra living rank-0 on our front vs opponent when our formation has more files (`numeric_superiority_for_pinch`).
const AUTO_DOCTRINE_NUMERIC_SUPERIORITY_FRONT_MARGIN := 1
## S6 pilot: layer KE budget scales pre-armor damage (sqrt curve); default off — see `ArmorJouleBudget`.
const FEATURE_JOULE_ARMOR_BUDGET := true


static func is_joule_armor_budget_active() -> bool:
	return FEATURE_JOULE_ARMOR_BUDGET
## **Dev:** After `CombatManager.start`, `BattleScene` re-equips combatants with **rank > 0** with `SPEAR` (formations unchanged — same `FormationPreset.default_for_count` as usual). Set **true** only for depth-polearm / spear-lane debugging.
const DEBUG_BACK_RANK_DEPTH_POLEARM_LOADOUT := false
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
## LINE↔OPEN hysteresis (Tier 1.4): cohesion must reach **L_in** to flip OPEN→LINE; must fall below **L_out** to flip LINE→OPEN (`L_in` > `L_out`).
const LINE_COHESION_POSTURE_ENTER_LINE_MIN := 0.62
const LINE_COHESION_POSTURE_LEAVE_LINE_BELOW := 0.50
## When **> 0**, each side’s `L_in`/`L_out` shift from **relative** cohesion vs the opponent (`delta = strength * (our_coh - opp_coh)`):
## stronger line → easier LINE (lower `L_in`, higher `L_out`); weaker → easier OPEN. Set encounter `posture_asymmetry_strength` to **0** to disable.
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
## Extra (Δ enter threshold, Δ leave threshold) from `line_discipline_posture_extra_deltas` — strict = stickier LINE (higher both).
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
## Paired disengage (swap_rank / drag / fall_back to rear) and solo fall_back: require real injury (blood this low, no usable arm, or immediate peril) — not low stamina / composite fitness alone.
## ~85 = ATLS Class II (~15% blood lost): wounded, may seek rear rank — not first-cut nuisance (was 94 / ~6%, too eager).
const FORMATION_RETREAT_BLOOD_VOLUME_MAX := 85.0
## Abandon-field **flee** (rout): Class III+ personal crisis (~45% lost) or immediate bleed-out — not “step back in the file.”
## Aligns with `MedicalPhaseController.MEDICAL_DANGER_BLOOD_THRESHOLD` (55).
const FORMATION_FLEE_BLOOD_VOLUME_MAX := 55.0
## MS-L9 positional awareness: disengage when surrounded and blood below this threshold.
## ~60% remaining (~40% lost): ATLS Class III boundary — real vulnerability, not minor bruising.
## Higher than `FORMATION_FLEE_BLOOD_VOLUME_MAX` (55) so AI disengages before reaching bleed-out danger.
const MENTAL_STACK_L9_VULNERABILITY_BLOOD_THRESHOLD := 60.0
## Formation keys (see `CombatFormationRout`, `CombatFormationEngagement`).
const FORMATION_KEY_STANDING_AT_START := "standing_at_start"
## Wounded fighter may **rout** when cached `line_cohesion` falls below this (≈ below LINE leave band 0.50).
const FORMATION_FLEE_LINE_COHESION_MAX := 0.42
## Side has lost this fraction of `standing_at_start` (dead / fled / incapacitated) → rout pressure.
const FORMATION_FLEE_CASUALTY_RATIO_MIN := 0.30
## Wounded + stressed rout blocked when this side still has ≥ this × opponent standing (tactical win — hold the field).
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
const AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT := 6.0
## IV-11 slice 9: AI weighted pick for leader formation doctrine commands (below routine offense).
const AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT := 0.38
## IV-11 slice 10: boost **`order_pinch_center`** when numeric superiority suggests pincer.
const AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT := 1.45
const AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT := 0.02
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
## WF-T1 (2026-06-07): Camp-5 soak confirms parry 0.55 / dodge 0.85 — tune octant raw table first.
const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY := 0.55
const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE := 0.85
## Production default on (2026-05-17): pilot tuned via `_run_footwork_*`; harness still toggles via load setter.
static var _feature_position_angle_footwork_enabled: bool = true


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


# Swap rank AI (CombatAIActionPicker): relief only when necessary — not marginal fitness differences.
const SWAP_RANK_AI_LOW_WEIGHT := 0.02
const SWAP_RANK_AI_HIGH_WEIGHT := 1.0
const SWAP_RANK_AI_LINE_PLUG_WEIGHT := 0.52 # Rear relief when another file has rank-0 hole (III-6 maintain)
const AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT := 0.62 # Skirmish shuffle when line has rank-0 holes (III-6 maintain)
const AI_ROTATE_FILE_WHEN_ENGAGEMENT_LISTED_MULT := 0.35 # Prefer strikes/close over shuffle when both are listed
const AI_ROTATE_FILE_LONG_CLOSE_ONLY_MULT := 1.35 # LONG close-only (no melee) — shuffle can find angle vs close spam
const AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT := 0.82 # Mapped rank-0 LONG close-only — rotate can compete
const AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT := 1.28 # Mapped wing out of reach — close bind beats wait/shuffle
const AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT := 0.58 # Menu-listed close when pair gate fails at pick time (fight-finish tail)
const AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT := 1.4 # Sparse post-flee front — close to finish beats shuffle
const AI_SPARSE_LINE_OFFENSE_MULT := 1.35 # Listed melee on sparse post-flee front — fight over focus shuffle
const AI_FOCUS_LINE_SPARSE_ENGAGEMENT_LISTED_MULT := 0.35 # Damp guard retarget when strikes/close are listed
const AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT := 0.45 # Post-flee sparse — wait below close/strike finish
const AI_WAIT_MOP_UP_FINISH_MULT := 0.4 # Mop-up winner or last-enemy underdog — finish fight, don't idle
## Mobile cowering solo **fall_back** vs **wait** (Tier 6.1 — no arms, legs OK).
const COWERING_SOLO_FALL_BACK_AI_WEIGHT := 1.5
## Tier 6.2: mobile cowering — prefer **`flee`** over in-formation **`fall_back`** when both are listed (cannot hold weapon).
const COWERING_FLEE_AI_WEIGHT := 1.55
## Armed fighters: rout is rare — well below rotate_file; scaled by `CombatFormationRout.flee_ai_pick_mult` (cohesion + casualties).
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
## Below this stamina ratio, offense weight uses **`AI_STAMINA_DEEP_EXHAUST_MULT`** (near-total exhaustion — can defend but should not initiate).
const AI_STAMINA_DEEP_EXHAUST_RATIO := 0.05
const AI_STAMINA_DEEP_EXHAUST_MULT := 0.40
## Exhaustion cap: below this ratio, offense weight floors at **`AI_STAMINA_EXHAUSTION_DEEP_MULT`** (realistic simulation — exhausted fighters cannot initiate).
const AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD := 0.05
const AI_STAMINA_EXHAUSTION_DEEP_MULT := 0.40


## IV-7b: step-down offense engage weight (investigated 2026-05; locked 2026-06-08).
## Exhaustion ramp: as stamina approaches 0%, offense weight drops further — exhausted fighters can still defend but should not initiate fresh attacks at full weight.
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
## Partner must exceed our composite fitness (perf × blood norm) by at least this much for a routine relief.
const SWAP_RANK_AI_MIN_FITNESS_GAP := 0.20
## Below this our_fitness, treat as dangerously unfit: partner need only be ahead by URGENT_MIN_GAP.
const SWAP_RANK_AI_CRITICAL_FITNESS := 0.42
## When our_fitness is at/under CRITICAL, partner must be at least this much fitter (smaller than MIN_FITNESS_GAP).
const SWAP_RANK_AI_URGENT_MIN_GAP := 0.10
# Ambush (Phase 6). Set on encounter when starting combat.
const AMBUSH_TYPE_NONE := "none"
const AMBUSH_TYPE_FULL := "full"
const AMBUSH_TYPE_PARTIAL := "partial"
## Phase 4: When true (e.g. lore protection circle), ZoC flank/rear bonuses and mid-reach widening are disabled.
## Optional float deltas added to `LINE_COHESION_POSTURE_ENTER_LINE_MIN` / `LINE_COHESION_POSTURE_LEAVE_LINE_BELOW` (Tier 1.4 testing / encounter data).
const ENCOUNTER_KEY_POSTURE_ENTER_DELTA := "engagement_posture_enter_delta"
const ENCOUNTER_KEY_POSTURE_LEAVE_DELTA := "engagement_posture_leave_delta"
## String: `line_discipline` = `LINE_DISCIPLINE_*` — encounter-wide default; overridden by per-formation `line_discipline` from preset.
const ENCOUNTER_KEY_LINE_DISCIPLINE := "line_discipline"
## Optional float override for `POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH` (0 = no opponent-relative posture coupling).
const ENCOUNTER_KEY_POSTURE_ASYMMETRY_STRENGTH := "posture_asymmetry_strength"
## Tier 1.5: direct `morale_cohesion_factor` for that side’s formation (0.15–1.0); overrides combatant mean when set on `manager.encounter`.
const ENCOUNTER_KEY_MORALE_COHESION_PLAYER := "morale_cohesion_player"
const ENCOUNTER_KEY_MORALE_COHESION_ENEMY := "morale_cohesion_enemy"
## Tier 6.2: optional per-side rout gates (override `FORMATION_FLEE_*` defaults when set on `manager.encounter`).
const ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER := "flee_line_cohesion_max_player"
const ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY := "flee_line_cohesion_max_enemy"
const ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER := "flee_casualty_ratio_min_player"
const ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_ENEMY := "flee_casualty_ratio_min_enemy"
## Tier 1.9: optional initial **`CombatManager.set_formation_doctrine`** for each side when **`start()`** runs (non-empty after strip; unknown strings → **`DOCTRINE_DEFAULT`** via normalize).
const ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER := "formation_doctrine_player"
const ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY := "formation_doctrine_enemy"
## Optional encounter aliases: read only when the canonical **`ENCOUNTER_KEY_FORMATION_DOCTRINE_*`** value is missing or empty after **`strip_edges`** (canonical still wins if non-empty).
const ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT := "doctrine_player"
const ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT := "doctrine_enemy"
## III-4 Track A **3c**: optional player line width before **`refresh_party_formation_meta`** default.
const ENCOUNTER_KEY_PLAYER_FORMATION := "player_formation"
const ENCOUNTER_KEY_PLAYER_FRONT_COUNT := "player_front_count"
## Expand WF-4: default weapon form per side when roster has no **`stance_preference`**.
const ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM := "player_default_weapon_form"
const ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM := "enemy_default_weapon_form"
## Expand WF-3: auto form switch cooldown (combat clock seconds).
const WF_FORM_SWITCH_COOLDOWN_S := 8.0
const WF_FORM_SWITCH_STAMINA_COST := 0.0
const WF_YOMI_FORM_INFERENCE_MIN_OBS := 4
const WF_YOMI_FORM_INFERENCE_MARGIN := 0.15
## Expand WF-2b: cap **`CombatWeaponForm.form_counter_mult`** picker boost.
const WF_FORM_COUNTER_MULT_CAP := 1.15
const WF_COUNTER_READINESS_NUDGE_MIN := 0.03
const WF_COUNTER_READINESS_NUDGE_MAX := 0.06
## WF-T2 (2026-06-08): auto-switch duel thresholds — F5 soak: block offensive duel_read from **wall** until stamina recovers.
const WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD := 0.12
const WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD := 0.15
const WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD := 0.10
const WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD := 0.05
const WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD := 0.08
const AI_FOCUS_LINE_FORM_PREFERRED_MULT := 1.25
const ENCOUNTER_PROTECTION_CIRCLE_ACTIVE := "protection_circle_active"
## Phase 6: Which side suffers ambush penalties (typically "player" when monsters ambush party).
const ENCOUNTER_AMBUSHED_SIDE := "ambushed_side"
## Optional on **world** `Node` before **`CombatFlow.start_combat`**: `Dictionary` copied into **`CombatManager.encounter`** before **`CombatManager.start()`** (**`BattleScene.start`** reads **`parent_scene.get_meta(WORLD_META_COMBAT_ENCOUNTER)`** when the 5th `p_encounter` arg is empty).
const WORLD_META_COMBAT_ENCOUNTER := "combat_encounter"

## Tier 1.9: canonical + optional alt string keys on a dict (**`strip_edges`** each); non-empty canonical wins.
static func formation_doctrine_string_from_dict(source: Dictionary, primary_key: String, alt_key: String) -> String:
	var s: String = str(source.get(primary_key, "")).strip_edges()
	if s.is_empty():
		s = str(source.get(alt_key, "")).strip_edges()
	return s


## Tier 1.9: encounter doctrine seed — delegates to **`formation_doctrine_string_from_dict`**.
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


## Encounter side keys → optional preset overlay (preset wins per field). Empty dict → use **`FORMATION_FLEE_*`** defaults.
static func rout_thresholds_for_encounter_and_preset(
	encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
	var out: Dictionary = {}
	var fid: String = str(formation_id)
	var enc_coh_key: String = (
		ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER
		if fid == "player"
		else ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_ENEMY
	)
	var enc_cas_key: String = (
		ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER
		if fid == "player"
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


## Defaults → encounter side → preset (**`FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS`** wins on overlap).
static func depth_polearm_ai_doctrine_mults_for_encounter_and_preset(
	encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
	var base: Dictionary = default_depth_polearm_ai_doctrine_mults_dict()
	var enc_key: String = (
		ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER
		if str(formation_id) == "player"
		else ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY
	)
	var after_enc: Dictionary = merge_depth_polearm_ai_doctrine_mults(base, encounter.get(enc_key))
	var preset_overlay: Variant = preset.get(FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS)
	return merge_depth_polearm_ai_doctrine_mults(after_enc, preset_overlay)

# Phase 2: Distance bands. Pair-wise for unformed; zone-based in Phase 4.
const DISTANCE_CLOSE := "close"
const DISTANCE_MID := "mid"
const DISTANCE_LONG := "long"
## Tier 4.2 footwork: **`DefenseChoiceResolver.choose_defense`** — defender **`distance_to[attacker]`** nudges passive parry capacity (no angle deltas) and dodge chance at CLOSE / LONG. Does not replace **`CombatDistanceBands`** writers; reads snapshot on defender dict.
const DEFENSE_SPACING_PARRY_MULT_CLOSE := 1.04
const DEFENSE_SPACING_PARRY_MULT_LONG := 0.92
const DEFENSE_SPACING_DODGE_MULT_CLOSE := 0.94
const DEFENSE_SPACING_DODGE_MULT_LONG := 1.06
## Tier 4.2 footwork / tempo: unstable base after a hit — **`DefenseChoiceResolver.choose_defense`** scales reported **`dodge_chance`** when defender **`STATE_RECOVERING`** (orthogonal to pair **`distance_to`** spacing and passive readiness curves on **`parry_c_d`**).
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT := 1.05
## Tier 4.2 footwork / tempo: per-**`recovery_cause`** multiplier on reported **`dodge_chance`** while **`STATE_RECOVERING`** (after spacing). Keys align with **`READINESS_BY_CAUSE`** / **`PassiveParryContext`**; unknown causes use **`DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT`**.
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE: Dictionary = {
	"attack_hit": 1.05,
	"attack_miss": 1.09,
	"attack_deflect": 1.06,
	"skip": 1.05,
	"medical": 1.04,
}
## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** (not off-balance) — reported **`dodge_chance`** after spacing; skipped when **`PassiveParryContext.is_off_balance`**.
const DEFENSE_FOOTWORK_WAITING_DODGE_MULT := 1.02
## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** defender (not off-balance) — damp feint-move listing vs that target (inverse pressure to **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** on dodge).
const AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT := 0.98
## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** defender (not off-balance) — base feint-listing damp (**`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** uses **`1.0 / defense_footwork_recovering_dodge_mult_for_cause`** per **`recovery_cause`**).
const AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT := 1.0 / DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT


## Tier 4.2 footwork: **`CombatAIActionPicker`** feint-move listing scales defender-readiness lerp input (**`pr_def`**) by defender **`distance_to[attacker_id]`** (after passive × incoming × stamina), aligned with feint dodge telegraph spacing.
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE := 1.05
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG := 0.94
## Tier 4.2 footwork / tempo: after **`PassiveParryContext.get_passive_parry_readiness`**, **`DefenseChoiceResolver.choose_defense`** scales readiness by **incoming** move **`contact_type`** (stab telegraphs less in the abstract window).
const PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT := 1.0
const PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT := 0.88
const PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT := 1.0


## Tier 4.2 / III-8: canonical **`recovery_cause`** for readiness + footwork lookups (aliases harness compatibility keys).
static func normalize_recovery_cause(cause: String) -> String:
	var k: String = str(cause).strip_edges()
	if k.is_empty():
		return "skip"
	if k == "parry_deflect" or k == "parry_partial":
		return "attack_deflect"
	return k


static func readiness_curve_for_cause(cause: String) -> Array:
	var k: String = normalize_recovery_cause(cause)
	return READINESS_BY_CAUSE.get(k, READINESS_BY_CAUSE.get("medical", [0.5, 0.85]))


static func defense_footwork_recovering_dodge_mult_for_cause(cause: String) -> float:
	var k: String = normalize_recovery_cause(cause)
	var v: Variant = DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE.get(k, DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT)
	if v is float or v is int:
		return float(v)
	return DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT


## Tier 4.2 footwork / tempo: inverse of **`defense_footwork_recovering_dodge_mult_for_cause`** for feint-move listing vs **`STATE_RECOVERING`** defender.
static func ai_feint_listing_defender_recovering_footwork_mult_for_cause(cause: String) -> float:
	var dodge_m: float = defense_footwork_recovering_dodge_mult_for_cause(cause)
	if dodge_m <= 1e-9:
		return AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT
	return 1.0 / dodge_m


## Tier 4.2 footwork / tempo: scales passive parry readiness by incoming move **`contact_type`** (**`DefenseChoiceResolver.choose_defense`**, **`CombatAIActionPicker`** feint listing **`pr_def`** before **`distance_to`** spacing mult). Feint listing also applies **`defender_passive_readiness_stamina_mult_from_ratio`** after passive × **`contact_type`** (same curve as **`DefenseChoiceResolver`** readiness reporting). Uses string keys only (no **`WeaponConstants`** import — avoids load cycle).
static func passive_parry_readiness_incoming_contact_mult(contact_type: String) -> float:
	var ct: String = str(contact_type).to_lower().strip_edges()
	if ct == "stab":
		return PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT
	if ct == "blunt":
		return PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT
	return PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT


## Tier 4.2 footwork: read defender **`distance_to[attacker_id]`** for **`CombatAIActionPicker`** / tests (same string set as **`DefenseChoiceResolver`**).
static func defender_distance_band_to_attacker_id(defender: Dictionary, attacker_id: int) -> String:
	if attacker_id < 0:
		return DISTANCE_MID
	var dm: Variant = defender.get("distance_to", {})
	if dm is Dictionary:
		var raw: String = str(dm.get(attacker_id, DISTANCE_MID))
		if raw == DISTANCE_CLOSE or raw == DISTANCE_MID or raw == DISTANCE_LONG:
			return raw
	return DISTANCE_MID


## Tier 4.2 footwork: multiplier on feint-listing **`pr_def`** from **`defender_distance_band_to_attacker_id`**.
static func ai_feint_listing_defender_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
	match defender_distance_band_to_attacker_id(defender, attacker_id):
		DISTANCE_CLOSE:
			return AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE
		DISTANCE_LONG:
			return AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG
		_:
			return 1.0


## Tier 4.2 footwork: scales **`parry_readiness_for_feint`** only for **`_feint_guard_reads_real_line`** in **`DefenseChoiceResolver._guard_zone_modifier`** (LONG slightly easier read-through vs telegraph; CLOSE slightly harder).
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE := 0.98
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG := 1.04


static func feint_guard_zone_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
	match defender_distance_band_to_attacker_id(defender, attacker_id):
		DISTANCE_CLOSE:
			return FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE
		DISTANCE_LONG:
			return FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG
		_:
			return 1.0


const REACH_MID_MIN := 1.2  # AI/depth polearm bias; shorts still strike at MID when melee_range >= effective_pair_eff_dist.
const MOVE_ID_ATTEMPT_CLOSE := "attempt_close"
const SKIP_TURN_LOG_PASS := "pass"
const SKIP_TURN_LOG_WAIT := "wait"
const SKIP_TURN_LOG_REJECT := "reject"
## Max living opponents at **DISTANCE_CLOSE** vs one defender (IV-2 / M4f). Tight formation +1.
const CLOSE_SLOTS_PER_TARGET := 3
const CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS := 1
## When defender close slots are full, damp listed/AI weight toward that defender (IV-2 spread).
const CLOSE_SLOTS_FULL_TARGETING_MULT := 0.32
## After a **failed** close vs a defender, `attempt_close` vs that same defender is withheld until `combat_clock` passes this (per attacker–defender pair). Turn spacing uses `READY_DELAY_CLOSE_ATTEMPT_S` separately.
const CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S := 1.65


static func max_close_slots_for_density(density: String) -> int:
	var bonus: int = (
		CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS if str(density).strip_edges() == "tight" else 0
	)
	return CLOSE_SLOTS_PER_TARGET + bonus

## Formation doctrine for hybrid targeting (CombatDoctrine / CombatTargetScoring).
const DOCTRINE_DEFAULT := "default"
const DOCTRINE_PINCH_CENTER := "pinch_center"
const DOCTRINE_HOLD_LANE := "hold_lane"
## Optional: measured thrusts / feints — depth spear listing weights only (no pinch inward / hold off-file hedge).
const DOCTRINE_PROBING := "probing"
## Seconds: AI "sticks" to last offensive target (hysteresis).
const DOCTRINE_COMMITMENT_DURATION_S := 4.5
const DOCTRINE_COMMIT_MATCH_WEIGHT_MULT := 1.28
const DOCTRINE_FILE_OPPOSED_WEIGHT_MULT := 1.42
## Extra weight toward enemy-line center when PINCH + wing has no file-opposed rank-0 target.
const DOCTRINE_PINCH_INWARD_BIAS_PER_FILE := 0.18
## III-4 **3e**: pincer flank wing AI/listing bias toward outer-file enemy under pinch + file outnumber.
const DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT := 1.28
## III-4 **3e**: pincer flank wing targeting spread damp — penalizes wide-arc targets by this per-file offset from preferred enemy file.
const DOCTRINE_PINCER_CLOSE_ARC_SPREAD_MULT := 0.92
## III-4 **3e**: post-rout envelop mop-up — enemy standing at or below this, our side above, standing advantage.
const ENVELOP_MOP_UP_MAX_ENEMY_ACTIVE := 1
const ENVELOP_MOP_UP_MIN_OUR_ACTIVE := 2
## III-4 **3e**: depth fighter plug forward into rank-0 during envelop mop-up.
const ENVELOP_MOP_UP_PLUG_FORWARD_ENABLED := true
const PLUG_FORWARD_DURATION_S := 0.6
## AI weight for plug_forward during envelop mop-up (high — entire formation should engage).
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
# Stance modifiers (Phase 2). Expand WF: [`docs/LIVE_PATHS.md#wf-weapon-form-stances`](../docs/LIVE_PATHS.md#wf-weapon-form-stances).
const STANCE_MOD_PARRY: Dictionary = {"defensive": 1.2, "balanced": 1.0, "aggressive": 0.8, "controlling": 1.0}
const STANCE_MOD_EVASION: Dictionary = {"defensive": 1.15, "balanced": 1.0, "aggressive": 0.85, "controlling": 1.0}
const STANCE_MOD_DAMAGE: Dictionary = {"defensive": 0.85, "balanced": 1.0, "aggressive": 1.2, "controlling": 0.95}
const STANCE_MOD_CLOSE_ATTEMPT: Dictionary = {"defensive": 0.9, "balanced": 1.0, "aggressive": 1.1, "controlling": 1.0}
## Tier 4.1: `CombatTargetScoring.ai_targeting_weight_mult` — hostile melee/close pick only (not medical / formation moves).
const STANCE_MOD_AI_MELEE_FOCUS: Dictionary = {"defensive": 0.92, "balanced": 1.0, "aggressive": 1.1, "controlling": 0.98}
## Tier 4.2: scales with passive parry readiness for feint telegraph read-through in **`DefenseChoiceResolver._guard_zone_modifier`** (defensive / controlling read feints a bit better).
const STANCE_MOD_FEINT_READTHROUGH: Dictionary = {"defensive": 1.06, "balanced": 1.0, "aggressive": 0.95, "controlling": 1.04}
## Tier 4.2: attacker stance nudges **feint-move** listing weight only in **`CombatAIActionPicker._get_action_weight`** (plain attacks unchanged).
const STANCE_MOD_AI_FEINT_LISTING: Dictionary = {
	"defensive": 0.94,
	"balanced": 1.0,
	"aggressive": 1.02,
	"controlling": 1.06,
}
const STANCE_MOD_OPPONENT_CLOSE: float = 0.9   # Controlling makes opponent close attempt harder
const STANCE_MOD_OPPONENT_DISENGAGE: float = 0.85  # Controlling makes opponent disengage harder
# Density modifier for close attempt (defender evasion). tight=easier to close, loose=harder.
const DENSITY_CLOSE_MOD: Dictionary = {"tight": 0.8, "normal": 1.0, "loose": 1.2}

## Returns stance modifier for given effect. Delegates to **`CombatWeaponForm.mod`** (stance alias compatibility preserved).
## **Harness-only alias:** production uses **`CombatWeaponForm.mod(_EntityAccess.form_str(c), effect)`** — see LIVE_PATHS **`#wf-footing-improvement-backlog`** (WF-M5). Do not add new production call sites.
static func get_stance_modifier(stance: String, effect: String) -> float:
	const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
	return _WeaponForm.mod(_WeaponForm.normalize_form(stance), effect)

## Returns density modifier for close attempt (applied to defender evasion).
static func get_density_close_mod(density: String) -> float:
	return DENSITY_CLOSE_MOD.get(density, 1.0)

## Returns spacing_m for formation targeting (effective_distance). tight=0.9, normal=1.2, loose=1.8.
static func get_spacing_from_density(density: String) -> float:
	match density:
		"tight": return SPACING_TIGHT
		"loose": return SPACING_LOOSE
		_: return SPACING_NORMAL

# Diagonal line roll (C: alignment-weighted): weights per (move_id, defender_guard_line) for diagonal moves.
# oberhau crosses high+left; defender high guard → more likely high. Format: { "line": weight }
const DIAGONAL_WEIGHTS: Dictionary = {
	"oberhau": {"high": {"high": 0.7, "low": 0.5, "left": 0.55, "right": 0.5}, "low": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.5}, "left": {"high": 0.6, "low": 0.5, "left": 0.65, "right": 0.5}, "right": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.65}},
	"oberhau_feint": {"high": {"high": 0.7, "low": 0.5, "left": 0.55, "right": 0.5}, "low": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.5}, "left": {"high": 0.6, "low": 0.5, "left": 0.65, "right": 0.5}, "right": {"high": 0.6, "low": 0.5, "left": 0.5, "right": 0.65}},
	"unterhau": {"high": {"high": 0.5, "low": 0.65, "left": 0.5, "right": 0.5}, "low": {"high": 0.5, "low": 0.7, "left": 0.55, "right": 0.55}, "left": {"high": 0.5, "low": 0.6, "left": 0.65, "right": 0.5}, "right": {"high": 0.5, "low": 0.6, "left": 0.5, "right": 0.65}},
	"diagonal_chop": {"high": {"high": 0.65, "low": 0.5, "left": 0.7, "right": 0.5}, "low": {"high": 0.5, "low": 0.6, "left": 0.65, "right": 0.55}, "left": {"high": 0.55, "low": 0.5, "left": 0.7, "right": 0.5}, "right": {"high": 0.5, "low": 0.55, "left": 0.5, "right": 0.65}},
	"slash": {"high": {"high": 0.55, "low": 0.5, "left": 0.65, "right": 0.55}, "low": {"high": 0.5, "low": 0.55, "left": 0.6, "right": 0.55}, "left": {"high": 0.55, "low": 0.5, "left": 0.7, "right": 0.5}, "right": {"high": 0.5, "low": 0.55, "left": 0.5, "right": 0.65}},
	"side_strike": {"high": {"high": 0.5, "low": 0.5, "left": 0.65, "right": 0.65}, "low": {"high": 0.5, "low": 0.5, "left": 0.6, "right": 0.6}, "left": {"high": 0.55, "low": 0.55, "left": 0.65, "right": 0.5}, "right": {"high": 0.55, "low": 0.55, "left": 0.5, "right": 0.65}}
}

# Option 6: Path + Guard Intercept — blade path per attack_line; guard determines intercept point.
# Path order = blade travel; early parts = first contact when guard puts limbs in the way.
# High alignment (same line) = early intercept (arms/limbs); low alignment = blade gets through (center mass).
const ATTACK_PATH_HIGH: Array = ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"]  # descending
const ATTACK_PATH_LOW: Array = ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"]   # rising
const ATTACK_PATH_LEFT: Array = ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"] # from left
const ATTACK_PATH_RIGHT: Array = ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"] # from right
const ATTACK_PATHS: Dictionary = {
	"high": ATTACK_PATH_HIGH,
	"low": ATTACK_PATH_LOW,
	"left": ATTACK_PATH_LEFT,
	"right": ATTACK_PATH_RIGHT
}

# Guard-dependent paths: path varies by defender posture. Anatomically accurate.
# When defender has high guard vs high attack: arms up → arms first. When low guard: head exposed first.
# attack_line = blade trajectory; guard_line = defender's weapon/limb position.
const ATTACK_PATHS_BY_GUARD: Dictionary = {
	"high": {
		"high": ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"],
		"low": ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"],
		"left": ["left_arm", "head", "chest", "right_arm", "left_leg", "right_leg"],
		"right": ["right_arm", "head", "chest", "left_arm", "left_leg", "right_leg"]
	},
	"low": {
		"high": ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"],
		"low": ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"],
		"left": ["left_leg", "left_arm", "right_leg", "chest", "right_arm", "head"],
		"right": ["right_leg", "right_arm", "left_leg", "chest", "left_arm", "head"]
	},
	"left": {
		"high": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
		"low": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
		"left": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
		"right": ["left_arm", "chest", "left_leg", "head", "right_arm", "right_leg"]
	},
	"right": {
		"high": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"],
		"low": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"],
		"left": ["right_arm", "chest", "right_leg", "head", "left_arm", "left_leg"],
		"right": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"]
	}
}

## IV-6: zone part first, then shaped tail distinct from flank-only and vertical-only cardinals.
static func _iv6_bubble_pair(parts: Array, before: String, after: String) -> Array:
	var out: Array = parts.duplicate()
	var i_before: int = out.find(before)
	var i_after: int = out.find(after)
	if i_before < 0 or i_after < 0 or i_before <= i_after:
		return out
	out.remove_at(i_before)
	i_after = out.find(after)
	out.insert(i_after, before)
	return out


static func _iv6_promote_to_front(parts: Array, part: String) -> Array:
	var out: Array = parts.duplicate()
	var idx: int = out.find(part)
	if idx <= 0:
		return out
	out.remove_at(idx)
	out.insert(0, part)
	return out


static func _iv6_diagonal_path_pool(flank_path: Array, vert_path: Array, zone_part: String) -> Array:
	var pool: Array = []
	for part in flank_path:
		var p: String = str(part)
		if p != zone_part and p not in pool:
			pool.append(p)
	for part in vert_path:
		var p: String = str(part)
		if p != zone_part and p not in pool:
			pool.append(p)
	return pool


static func _iv6_shape_diagonal_pool(pool: Array, guard_oct: String) -> Array:
	var shaped: Array = pool.duplicate()
	match guard_oct:
		_GuardLines.LINE_HIGH_LEFT:
			shaped = _iv6_bubble_pair(shaped, "head", "right_arm")
			shaped = _iv6_bubble_pair(shaped, "right_arm", "chest")
		_GuardLines.LINE_HIGH_RIGHT:
			shaped = _iv6_bubble_pair(shaped, "head", "left_arm")
			shaped = _iv6_bubble_pair(shaped, "left_arm", "chest")
		_GuardLines.LINE_LOW_LEFT, _GuardLines.LINE_LOW_RIGHT:
			shaped = _iv6_promote_to_front(shaped, "left_leg")
			shaped = _iv6_promote_to_front(shaped, "right_leg")
	return shaped


static func _iv6_diagonal_attack_path(
	flank_path: Array, vert_path: Array, guard_oct: String, zone_part: String
) -> Array:
	var pool: Array = _iv6_diagonal_path_pool(flank_path, vert_path, zone_part)
	pool = _iv6_shape_diagonal_pool(pool, guard_oct)
	var out: Array = []
	if zone_part != "":
		out.append(zone_part)
	for part in pool:
		out.append(part)
	return out


## Returns attack path for (attack_line, guard_line). Attack octants map via **`cardinal_for_path_lookup`**; guard octants use **`guard_cardinal_for_attack_path`** (IV-4) or IV-6 octant merge when enabled.
static func get_attack_path(attack_line: String, guard_line: String) -> Array:
	var atk_key: String = str(attack_line).strip_edges()
	var guard_key: String = str(guard_line).strip_edges()
	var guard_oct: String = ""
	if _GuardLines.is_known_line(atk_key):
		atk_key = _GuardLines.cardinal_for_path_lookup(atk_key)
	if _GuardLines.is_known_line(guard_key):
		guard_oct = _GuardLines.normalize_line(guard_key)
		if is_feature_hema_eight_guard_lines_enabled():
			guard_key = _GuardLines.guard_cardinal_for_attack_path(guard_oct)
		else:
			guard_key = _GuardLines.cardinal_for_path_lookup(guard_key)
	var by_guard: Variant = ATTACK_PATHS_BY_GUARD.get(atk_key, {})
	if not (by_guard is Dictionary and by_guard.has(guard_key)):
		return ATTACK_PATHS.get(atk_key, ATTACK_PATH_HIGH)
	var flank_path: Array = (by_guard as Dictionary)[guard_key]
	if (
		is_feature_iv6_attack_path_octant_enabled()
		and is_feature_hema_eight_guard_lines_enabled()
		and guard_oct != ""
		and _GuardLines.is_flank_diagonal_guard_line(guard_oct)
	):
		var vert_key: String = _GuardLines.cardinal_for_path_lookup(guard_oct)
		if vert_key != guard_key:
			var vert_path: Array = (by_guard as Dictionary).get(vert_key, flank_path)
			var zone: String = _GuardLines.guard_zone_part_for_line(guard_oct)
			return _iv6_diagonal_attack_path(flank_path, vert_path, guard_oct, zone)
	return flank_path

# Intercept: alignment 1.0 = hit early parts (indices 0..2); alignment 0.0 = full path (0..5)
const PATH_INTERCEPT_EARLY_MAX := 2
const PATH_INTERCEPT_FULL_MAX := 5

## Angle (degrees) from defender guard line to attacker attack line. Used for cos(θ) alignment.
const LINE_ANGLE_DEG: Dictionary = {
	"high": {"high": 0, "low": 90, "left": 45, "right": 45},
	"low": {"high": 90, "low": 0, "left": 45, "right": 45},
	"left": {"high": 45, "low": 45, "left": 0, "right": 90},
	"right": {"high": 45, "low": 45, "left": 90, "right": 0}
}

# Angle-based trajectory: 0°=high, 90°=right, 180°=low, 270°=left. Used for deflection direction, path lookup.
const LINE_TO_ANGLE_DEG: Dictionary = {"high": 0.0, "right": 90.0, "low": 180.0, "left": 270.0}
const ANGLE_VARIANCE_DEG: float = 8.0  # Default ±deg human error; overridden per move by angle_variance_deg.
# Fatigue/readiness/off-balance: variance multiplier. At stamina 0, mult = STAMINA_AT_ZERO_VARIANCE_MULT.
const ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT: float = 1.6
const ANGLE_VARIANCE_OFF_BALANCE_MULT: float = 1.35
# Mass: heavier weapons harder to control. Reference 1.0 kg; mass 1.8 kg adds ~8% variance.
const ANGLE_VARIANCE_MASS_REFERENCE_KG: float = 1.0
const ANGLE_VARIANCE_MASS_SCALE: float = 0.1
# Guard wobble: defender reacting; low readiness = more wobble (degrees).
const GUARD_WOBBLE_MAX_DEG: float = 12.0
const GUARD_WOBBLE_READINESS_SCALE: float = 1.0  # wobble = max * (1 - readiness * scale)
# Defender mass: heavier blade = more inertia = slower to stabilize when reacting. Reference 1.0 kg.
const GUARD_WOBBLE_MASS_REFERENCE_KG: float = 1.0
const GUARD_WOBBLE_MASS_SCALE: float = 0.08  # 1.8 kg blade adds ~6.4% more wobble
# Attack arc: large arc_span = blade traveled far; late parry has harder time catching.
const ARC_SPAN_LATE_PARRY_THRESHOLD_DEG: float = 50.0
const ARC_SPAN_LATE_PARRY_PENALTY_MAX: float = 0.25

## Blade angle at a given progress through the attack arc. progress 0 = arc_start, 1 = arc_end.
## Interpolates along shortest angular path so weapon position is accurate at any moment.
## Use for parry alignment (blade where defender meets it), intercept depth, reaction checks.
static func get_arc_angle_at_progress(arc_start_deg: float, arc_end_deg: float, progress: float) -> float:
	var p: float = clampf(progress, 0.0, 1.0)
	var a: float = fmod(arc_start_deg + 360.0, 360.0)
	var b: float = fmod(arc_end_deg + 360.0, 360.0)
	var diff: float = fmod(b - a + 540.0, 360.0) - 180.0  # Shortest path (-180..180)
	return fmod(a + diff * p + 360.0, 360.0)

## Base arc end for contact geometry (pre attacker footwork offset). Prefer **`arc_end_deg`**; else **`arc_intended_deg`**.
## Never **`attack_angle_deg`** — that field includes footwork offset after resolve.
static func arc_end_deg_for_contact_geometry(pa: Dictionary) -> float:
	var end: float = pa.get("arc_end_deg", -999.0)
	if end >= -900.0:
		return end
	end = pa.get("arc_intended_deg", -999.0)
	if end >= -900.0:
		return end
	return -999.0


## Attack angle from pending_attack at given progress. Uses arc_start/arc_end when available;
## falls back to arc_intended_deg during wind-up (before arc_end is rolled at resolution).
static func get_attack_angle_at_progress(pa: Dictionary, progress: float) -> float:
	var start: float = pa.get("arc_start_deg", 0.0)
	var end: float = arc_end_deg_for_contact_geometry(pa)
	if end < -900.0:
		end = line_to_angle("high")
	return get_arc_angle_at_progress(start, end, progress)

## Shortest angular distance (0–180°). Handles wraparound.
static func angle_diff_deg(a_deg: float, b_deg: float) -> float:
	var d := fmod(abs(a_deg - b_deg) + 360.0, 360.0)
	return minf(d, 360.0 - d) if d > 180.0 else d

## Map discrete line to angle. Returns LINE_TO_ANGLE_DEG value or 0 for unknown.
static func line_to_angle(line: String) -> float:
	if is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.line_to_angle(line)
	return float(LINE_TO_ANGLE_DEG.get(line, 0))


## Map angle to nearest guard line (four-line baseline or eight-line octants when **`FEATURE_HEMA_EIGHT_GUARD_LINES`**).
static func angle_to_nearest_line(angle_deg: float) -> String:
	if is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.angle_to_line(angle_deg)
	var a := fmod(angle_deg + 360.0, 360.0)
	if a < 45.0 or a >= 315.0:
		return "high"
	if a < 135.0:
		return "right"
	if a < 225.0:
		return "low"
	return "left"

## Alignment from continuous angles. cos(θ); floor PARRY_ALIGNMENT_FLOOR.
static func get_alignment_from_angles(attack_angle_deg: float, guard_angle_deg: float) -> float:
	var theta := angle_diff_deg(attack_angle_deg, guard_angle_deg)
	return maxf(PARRY_ALIGNMENT_FLOOR, cos(theta * PI / 180.0))

## Bilateral deflection: blade deflects "away from" defender's blade. Returns deflected angle (0–360).
static func get_deflected_angle_bilateral(attack_angle_deg: float, guard_angle_deg: float, magnitude_deg: float) -> float:
	var cw := fmod(attack_angle_deg + magnitude_deg + 360.0, 360.0)
	var ccw := fmod(attack_angle_deg - magnitude_deg + 360.0, 360.0)
	var dist_cw := angle_diff_deg(cw, guard_angle_deg)
	var dist_ccw := angle_diff_deg(ccw, guard_angle_deg)
	return cw if dist_cw > dist_ccw else ccw

## Deflection magnitude (deg) from alignment and severity. Lower alignment → larger deflection.
## contact_type: stab | cut | blunt (not move_id; callers may pass move_id only if they normalize first).
static func get_deflection_magnitude_deg(alignment: float, severity: float, contact_type: String) -> float:
	var base := (1.0 - alignment) * 90.0 * severity
	var mult: float = 1.0
	if contact_type == "stab":
		mult = 1.15
	elif contact_type == "blunt":
		mult = 0.9
	return base * mult * randf_range(0.9, 1.1)


static func parry_opposite_deflect_severity_threshold(contact_type: String) -> float:
	var ct: String = str(contact_type).to_lower().strip_edges()
	if ct == "stab":
		return PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST
	if ct == "blunt":
		return PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT
	return PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT


static func _adjacent_line_away_from_guard(attack_line: String, guard_angle_deg: float) -> String:
	var atk_line: String = attack_line
	var adj_src: Dictionary = LINE_ADJACENTS
	if is_feature_hema_eight_guard_lines_enabled():
		atk_line = _GuardLines.normalize_line(attack_line)
		adj_src = _GuardLines.LINE_ADJACENTS
	var adj_raw: Variant = adj_src.get(atk_line, [])
	if not (adj_raw is Array) or (adj_raw as Array).is_empty():
		return atk_line
	var best_line: String = str((adj_raw as Array)[0])
	var best_dist: float = -1.0
	for candidate in (adj_raw as Array):
		var line: String = str(candidate)
		var dist: float = angle_diff_deg(line_to_angle(line), guard_angle_deg)
		if dist > best_dist:
			best_dist = dist
			best_line = line
	return best_line


## Returns alignment 0..1 from attack_line vs guard_line. Floor PARRY_ALIGNMENT_FLOOR for lucky intercept.
static func get_line_alignment(attack_line: String, guard_line: String) -> float:
	if is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.alignment_from_lines(
			_GuardLines.normalize_line(attack_line),
			_GuardLines.normalize_line(guard_line),
			PARRY_ALIGNMENT_FLOOR
		)
	var def_row: Variant = LINE_ANGLE_DEG.get(guard_line, {})
	if def_row is Dictionary:
		var deg: float = float(def_row.get(attack_line, 90))
		return maxf(PARRY_ALIGNMENT_FLOOR, cos(deg * PI / 180.0))
	return PARRY_ALIGNMENT_FLOOR

## Effective attack angle from line. Adds human-error variance; optional move_def and variance_context.
## variance_context: stamina_ratio (0-1), off_balance (bool), weapon_mass_kg (float) — fatigue/readiness/mass scale variance.
static func get_attack_angle_deg(attack_line: String, add_variance: bool = true, move_def: Dictionary = {}, variance_context: Dictionary = {}) -> float:
	var base := line_to_angle(attack_line)
	var offset_range: float = float(move_def.get("angle_offset_deg", 0))
	if offset_range > 0:
		base += randf_range(-offset_range, offset_range)
	if add_variance:
		var variance: float = float(move_def.get("angle_variance_deg", ANGLE_VARIANCE_DEG))
		var mult: float = 1.0
		var stamina_ratio: float = variance_context.get("stamina_ratio", 1.0)
		if stamina_ratio < 1.0:
			var sf: float = stamina_factor(stamina_ratio)
			mult = 1.0 + (ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT - 1.0) * (1.0 - sf)
		if variance_context.get("off_balance", false):
			mult *= ANGLE_VARIANCE_OFF_BALANCE_MULT
		var mass_kg: float = float(variance_context.get("weapon_mass_kg", ANGLE_VARIANCE_MASS_REFERENCE_KG))
		if mass_kg > 0 and ANGLE_VARIANCE_MASS_REFERENCE_KG > 0:
			var mass_mult: float = 1.0 + (mass_kg - ANGLE_VARIANCE_MASS_REFERENCE_KG) * ANGLE_VARIANCE_MASS_SCALE
			mult *= maxf(0.7, mass_mult)
		variance *= mult
		base += randf_range(-variance, variance)
	return fmod(base + 360.0, 360.0)

## Guard angle from combatant. Uses **`guard_line`**; when guard_deflect_blend > 0, lerps from guard_deflect_from_line to guard_line.
## At strike contact with PA pilot, prefer **`CombatFootwork.guard_angle_deg`** (adds offset) — LIVE_PATHS **`#wf-tier-44-pa`** (geometry). **Not** **`weapon_form`**.
## wobble_context: parry_readiness (0-1), defender_mass_kg (optional). When readiness < 1, adds ±wobble (defender reacting).
static func get_guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
	var line: String = combatant.get("guard_line", GUARD_DEFAULT)
	var blend: float = combatant.get("guard_deflect_blend", 0.0)
	var base_angle: float
	if blend <= 0.0:
		base_angle = line_to_angle(line)
	else:
		var from_line: String = combatant.get("guard_deflect_from_line", line)
		var from_a: float = line_to_angle(from_line)
		var to_a: float = line_to_angle(line)
		base_angle = lerpf(from_a, to_a, blend)
	var readiness: float = wobble_context.get("parry_readiness", 1.0)
	if readiness < 1.0 and GUARD_WOBBLE_MAX_DEG > 0:
		var wobble: float = GUARD_WOBBLE_MAX_DEG * (1.0 - readiness * GUARD_WOBBLE_READINESS_SCALE)
		var mass_kg: float = float(wobble_context.get("defender_mass_kg", GUARD_WOBBLE_MASS_REFERENCE_KG))
		if mass_kg > 0 and GUARD_WOBBLE_MASS_REFERENCE_KG > 0:
			var mass_mult: float = 1.0 + (mass_kg - GUARD_WOBBLE_MASS_REFERENCE_KG) * GUARD_WOBBLE_MASS_SCALE
			wobble *= maxf(0.7, mass_mult)
		base_angle += randf_range(-wobble, wobble)
	return fmod(base_angle + 360.0, 360.0)

## Deflected line from bilateral angle-based deflection. Replaces discrete geometry with continuous physics.
## contact_type: stab | cut | blunt for magnitude scaling (not move_id).
static func get_deflected_line_from_angles(attack_angle_deg: float, guard_angle_deg: float, severity: float, contact_type: String, alignment: float) -> String:
	var atk_line: String = angle_to_nearest_line(attack_angle_deg)
	var guard_line: String = angle_to_nearest_line(guard_angle_deg)
	if atk_line == guard_line:
		return atk_line
	var opposite_line: String = (
		_GuardLines.opposite_line(atk_line)
		if is_feature_hema_eight_guard_lines_enabled()
		else str(DEFLECTED_GUARD_FROM_ATTACK.get(atk_line, atk_line))
	)
	if guard_line == opposite_line:
		var threshold: float = parry_opposite_deflect_severity_threshold(contact_type)
		if severity >= threshold:
			return opposite_line
		return _adjacent_line_away_from_guard(atk_line, guard_angle_deg)
	var mag := get_deflection_magnitude_deg(alignment, severity, contact_type)
	var deflected := get_deflected_angle_bilateral(attack_angle_deg, guard_angle_deg, mag)
	return angle_to_nearest_line(deflected)

## HEMA: when combatant has guard_deflect_blend (partial deflection), lerp alignment between from and to.
## alignment_context: optional {attack_angle_deg, guard_angle_deg}. When both present, uses continuous cos(θ) alignment.
## wobble_context: passed to get_guard_angle_deg for defender reactivity (guard wobble).
static func get_line_alignment_with_deflect(attack_line: String, combatant: Dictionary, alignment_context: Dictionary = {}, wobble_context: Dictionary = {}) -> float:
	var atk_a: Variant = alignment_context.get("attack_angle_deg", null)
	var guard_a: Variant = alignment_context.get("guard_angle_deg", null)
	if atk_a is float and guard_a is float:
		return maxf(PARRY_ALIGNMENT_FLOOR, get_alignment_from_angles(float(atk_a), float(guard_a)))
	guard_a = get_guard_angle_deg(combatant, wobble_context)
	if atk_a is float:
		return maxf(PARRY_ALIGNMENT_FLOOR, get_alignment_from_angles(float(atk_a), float(guard_a)))
	var guard_line: String = combatant.get("guard_line", GUARD_DEFAULT)
	var blend: float = combatant.get("guard_deflect_blend", 0.0)
	if blend <= 0.0:
		return get_line_alignment(attack_line, guard_line)
	var from_line: String = combatant.get("guard_deflect_from_line", GUARD_DEFAULT)
	var align_from: float = get_line_alignment(attack_line, from_line)
	var align_to: float = get_line_alignment(attack_line, guard_line)
	return lerpf(align_from, align_to, blend)

const DODGE_FULL_THRESHOLD := 0.4
const DODGE_PARTIAL_RATIO_MIN := 0.4
const PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY := 0.5
const PARRY_FOLLOW_THROUGH_PARTIAL_MIN := 0.5
const PARRY_FOLLOW_THROUGH_THRUST_PENALTY := 0.12
const PARRY_FOLLOW_THROUGH_CUT_BONUS := 0.05
const RECOVERY_AGILITY_MIN := 0.7
const RECOVERY_AGILITY_MAX := 1.3

# Attacker weak exposure (forte/foible): 0–1 how much weak is exposed for defender to catch.
# OVERHEAD = tip leads, most weak exposed. STAB = point leads — point IS the weak (foible), so highly exposed, easier to deflect.
# Thrusts are easier to bat aside: lateral force redirects the point readily (Sword STEM, redirect_thrust_bonus).
# QUICK_SLASH = minimal commitment, blade not fully extended, less weak exposed.
# HEAVY_BLUNT/POMMEL = 0: no blade — mace head/pommel is impact surface, no forte/foible.
const WEAK_EXPOSURE_BY_ARCH: Dictionary = {
	"overhead": 1.0,
	"heavy_blunt": 0.0,
	"slash": 0.5,
	"stab": 0.75,
	"pommel_strike": 0.0,
	"quick_slash": 0.3
}
# Bidirectional strong/weak: when defender uses forte (blade), bonus scales with strong_fraction × weak_exposure.
# Shaft/haft use leverage factor instead; this applies to blade parrying only.
const DEFENDER_STRONG_BONUS: float = 0.12
# Baseline parry effectiveness by attacker archetype. Stab 1.02: point (weak) leads, easier to redirect.
# QUICK_SLASH 0.95: fast, less telegraphed — defender rarely catches at optimal strong-on-weak.
# OVERHEAD 1.12: tip leads, defender readily catches weak on forte.
# POMMEL_STRIKE 1.0: hilt strike — no blade strong/weak; contact is pommel-on-blade, not blade-on-blade.
const PARRY_STRONG_CONTACT_BY_ARCH: Dictionary = {
	"overhead": 1.12,
	"heavy_blunt": 1.08,
	"slash": 1.0,
	"stab": 1.02,
	"pommel_strike": 1.0,
	"quick_slash": 0.95
}

# Afterblow: physically realistic — allow completion iff blow wasn't intense enough to hinder.
const AFTERBLOW_DAMAGE_HINDER_THRESHOLD: float = 15.0
const AFTERBLOW_HINDRANCE_BLOCK: float = 0.7
const AFTERBLOW_HINDRANCE_ALLOW: float = 0.3
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5

const MEDICAL_WIND_UP_CONFIG: Dictionary = {
	"bandage_self": {"duration_method": "get_bandage_application_time_seconds_for_part", "duration_takes_part": true, "target_method": "apply_bandage", "outcome": "bandaged"},
	"pack_wound": {"duration_method": "get_packing_application_time_seconds_for_part", "duration_takes_part": true, "target_method": "apply_packing", "outcome": "packed"},
	"stabilize_wound": {
		"duration_method": "get_stabilize_application_time_seconds_for_part",
		"duration_takes_part": true,
		"target_method": "apply_stabilize",
		"outcome": "stabilized",
	},
	"apply_tourniquet": {"duration_method": "get_tourniquet_application_time_seconds", "duration_takes_part": false, "target_method": "apply_tourniquet", "outcome": "tourniquet_applied"}
}
