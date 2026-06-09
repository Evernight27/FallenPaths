class_name CombatParryConstants
extends RefCounted

## Parry constants, guard zone/line mapping, counter-tempo, geometry, angle functions.
## Extracted from CombatConstants for modular organization.
##
## Read order: parry constants → bind/riposte → guard-zone/line → counter-tempo → riposte chain → flurry → readiness → movement-mass → penetration/alignment → dodge

const _GuardLines := preload("res://combat/CombatGuardLines.gd")

# --- Parry defensive move constants (~40–60% of max strike) ---
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

# --- Direct hits (no parry/dodge): penetration / alignment ---
## Scale: 0 = no alignment effect; 1 = full (alignment 0 → angle_min). Avoid double-counting with parry/dodge.
const PARRY_PENETRATION_ALIGNMENT_SCALE := 0.5
## Parry partial: only update defender guard_line when alignment > this (blade properly met).
const PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD := 0.6

# --- HEMA bind vs deflect ---
const PARRY_BIND_CONTROL_THRESHOLD := 0.65

# --- Non-blade attacks: impact weapons never bind, always deflect ---
const ARCHETYPES_NEVER_BIND: Array[String] = ["pommel_strike", "heavy_blunt"]

# --- Bind riposte wind-up: parry_part x contact_type ---
## P4h balance (2026-05-18): stab 0.55 < cut 0.78 < blunt 0.90 — extend vs wind vs swing from bind; harness **`_run_bind_riposte_*`**.
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
	"blade": {"stab": 0.55, "cut": 0.78},
	"shaft": {"stab": 0.55, "cut": 0.78, "blunt": 0.90},
	"haft": {"stab": 0.55, "cut": 0.78}
}
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = 0.78

# --- Late parry / off-balance penalties ---
const PARRY_LATE_CONTROL_FACTOR := 0.6
const PARRY_OFF_BALANCE_CONTROL_FACTOR := 0.7

# --- Opposite-defender geometry deflect thresholds ---
const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := 0.65
const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := 0.5
const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := 0.8

# --- Thrust bind difficulty ---
const PARRY_THRUST_CONTROL_MULT := 0.85

# --- Blade position after parry deflect / dodge ---
## Fallback when defender_guard unknown: maps attack_line -> deflected guard (opposite line).
const DEFLECTED_GUARD_FROM_ATTACK: Dictionary = {"high": "low", "low": "high", "left": "right", "right": "left"}
## Adjacent lines (45deg): lateral deflection. Physics: "shed to the side" = smaller angular displacement.
const LINE_ADJACENTS: Dictionary = {"high": ["left", "right"], "low": ["left", "right"], "left": ["high", "low"], "right": ["high", "low"]}
## Blade position after full dodge: defender moved to avoid. Maps attack_line -> guard they end in.
const DODGE_END_GUARD_FROM_ATTACK: Dictionary = {"high": "low", "low": "high", "left": "right", "right": "left"}

# --- Desperate dodge thresholds ---
const PARRY_DESPERATE_DODGE_THRESHOLD := 0.06
const PARRY_PREFER_DODGE_FULL_THRESHOLD := 0.12
const PARRY_MASS_DISPARITY_BONUS := 0.18
const PARRY_LATE_CAPACITY_FLOOR := 0.22

# --- Weapon part model parry capacity modifiers ---
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.88, "haft": 0.92}
## Defender weapon type vs attack contact_type modifier. def_weapon_type -> {contact_type -> mult}.
const PARRY_DEF_VS_ATK_MOD: Dictionary = {"DAGGER": {"stab": 0.9}, "MACE": {"blunt": 1.05}, "SPEAR": {"cut": 0.95}}
## Full weapon mass contributes to parry: effective mass = lerp(parry_part, total, this). 0.5 = equal weight.
const PARRY_INERTIA_BLEND: float = 0.5
## Shaft/haft longer than this (cm) get leverage factor from alignment.
const PARRY_LEVERAGE_LONG_PART_CM: float = 80.0
## Leverage factor range for long shaft/haft: 0.65 (bad alignment) to 1.0 (good).
const PARRY_LEVERAGE_FLOOR: float = 0.65

# --- Guard zone / line mapping ---
## Guard zone (body-part): which zone defender chooses to protect. Parry bonus when guarded, penalty when unguarded.
const GUARD_ZONE_BONUS := 1.4
const GUARD_ZONE_UNGUARDED_PENALTY := 0.75
## Default guard/attack line when combatant or move lacks explicit value.
const GUARD_DEFAULT := "high"
## Part -> primary guard line (for guard_zone/guard_line sync)
const PART_TO_LINE: Dictionary = {"head": "high", "chest": "high", "left_arm": "left", "right_arm": "right", "left_leg": "low", "right_leg": "low"}
## Line -> default body part (for syncing guard_zone when guard_line changes from outcome)
const LINE_TO_DEFAULT_PART: Dictionary = {"high": "head", "low": "left_leg", "left": "left_arm", "right": "right_arm"}

# --- Tier 4.2 telegraph / feint read-through ---
## Tier 4.2 (Feint D): wind-up telegraph body part on defender; cleared when that incoming attack's `pending_attack` ends.
const COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART := "incoming_attack_telegraph_part"
## Tier 4.2 short-horizon tempo: attacker maps str(defender_id) -> last CombatManager tick when defender parry_deflect'd this attacker.
const COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK := "ai_feint_opp_last_parry_deflect_tick_by_id"
## After harness override: multiplies effective feint dodge telegraph bias from defender distance.
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE := 1.08
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG := 0.88

# --- Counter-tempo pilot ---
const COMBATANT_KEY_COUNTER_WINDOW_UNTIL := "counter_window_until"
const ACTION_KEY_COUNTER_TEMPO := "counter_tempo"
const PA_KEY_COUNTER_TEMPO := "counter_tempo"
const COUNTER_TEMPO_GAUGE_THRESHOLD := 50.0
const COUNTER_TEMPO_GAUGE_COST := 50.0
const COUNTER_TEMPO_WINDOW_FRACTION := 0.8
## Tier 4.2 Approach B: defender counter-tempo only after incoming STATE_WIND_UP progress >= this.
const COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS := 0.5
const COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED := "counter_tempo_ready_signaled"
const COMBATANT_KEY_COUNTER_TEMPO_UI_HINT := "counter_tempo_ui_hint"
const COUNTER_TEMPO_WINDUP_MULT := 0.65
const COUNTER_TEMPO_ACTION_READY_DELAY_S := 0.02
const COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S := 0.001
## Tier 4.2 counter-tempo AI weights.
const AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT := 1.35
const AI_COUNTER_TEMPO_INCOMING_TARGET_MULT := 1.12
const AI_COUNTER_TEMPO_FEINT_DAMP_MULT := 0.88

# --- Riposte chain ---
const COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL := "riposte_chain_until"
const COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID := "riposte_chain_target_id"
const PA_KEY_RIPOSTE_CHAIN := "riposte_chain"
const RIPOSTE_CHAIN_WINDOW_S := 1.5
const RIPOSTE_CHAIN_WINDUP_MULT := 0.5

# --- Flurry bind exchange (Tier 4.5) ---
const FLURRY_BIND_WINDOW_S := 1.25
const FLURRY_BIND_MAX_EXCHANGES := 2
const FLURRY_BIND_WIND_UP_MULT := 0.82
const FLURRY_BIND_STAMINA_ATTACK_COST_MULT := 0.88

# --- Recovery cause -> readiness curves ---
## Recovery cause -> readiness: unique curves per cause. Each: [early, late] for lerp(early, late, progress).
const READINESS_BY_CAUSE: Dictionary = {
	"attack_hit": [0.3, 0.6],      # Stunned from impact; worst parry
	"attack_miss": [0.45, 0.8],    # Off-balance from whiff; less stunned
	"attack_deflect": [0.5, 0.85], # Blade deflected; similar to baseline
	"skip": [0.5, 0.85],           # No attack; baseline
	"medical": [0.5, 0.85]         # Fallback for any other cause
}

# --- Parry geometry / alignment (4-line guard) ---
const PARRY_ALIGNMENT_FLOOR := 0.15
const GEOMETRIC_LEAK_MAX := 0.35
const PARRY_GEOMETRY_VARIANCE_BASE := 0.08

# --- Guard transition wind-up cost ---
## Guard transition: wind-up cost when blade must move from current guard to attack line.
const GUARD_TRANSITION_COST_SCALE := 0.4
## Clamp on guard-line transition mult (footwork offset can drive align toward 0).
const GUARD_TRANSITION_MULT_MAX := 1.35

# --- Guard zone read-through with feint ---
## With feint: if parry_readiness * WeaponForm.mod(form_str, "feint_readthrough") >= this, treat defender guard focus as real line.
const FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD := 0.9
## Tier 4.2 telegraph delay: readiness lerp fraction during early wind-up.
const FEINT_PRE_REVEAL_READINESS_MULT := 0.5
## Tier 4.2: DefenseChoiceResolver may set dodge_eval_part to pa.feint_part when defender does not read through the feint.
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS := 0.55
## Headless harness only: pa key override for feint dodge eval bias.
const PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS := "_harness_feint_dodge_eval_bias"

# --- Guard line functions (4-line legacy / eight-line octants) ---
static func guard_zone_for_guard_line(line: String) -> String:
	if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.guard_zone_part_for_line(line)
	return str(LINE_TO_DEFAULT_PART.get(str(line), "head"))


# --- Parry gate functions (III-3 baseline) ---
## III-3: shared full-stop gate — turn pick uses pre-variance parry_c_d; resolve uses post-variance c_d_final.
static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool) -> bool:
	return is_block_parry and c_d >= parry_p_a * PARRY_DEFLECT_THRESHOLD


## III-3: bind tag gate — AttackResultApplier, GuardLineUpdater, calibration audit.
static func parry_bind_control_reached(parry_control: float) -> bool:
	return parry_control >= PARRY_BIND_CONTROL_THRESHOLD


static func iii3_baseline_constants_line() -> String:
	return (
		"III-3 constants: unchanged baseline (PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f)"
		% [PARRY_DEFLECT_THRESHOLD, PARRY_BIND_CONTROL_THRESHOLD]
	)


## P4d: single doc-sync line for bind riposte table + gauge bonus.
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
			CombatConstants.PARRY_BIND_RIPOSTE_GAUGE_BONUS,
		]
	)


## Returns parry opposite deflect severity threshold for contact type.
static func parry_opposite_deflect_severity_threshold(contact_type: String) -> float:
	var ct: String = str(contact_type).to_lower().strip_edges()
	if ct == "stab":
		return PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST
	if ct == "blunt":
		return PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT
	return PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT


## Returns alignment 0..1 from attack_line vs guard_line. Floor PARRY_ALIGNMENT_FLOOR for lucky intercept.
static func get_line_alignment(attack_line: String, guard_line: String) -> float:
	if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.alignment_from_lines(
			_GuardLines.normalize_line(attack_line),
			_GuardLines.normalize_line(guard_line),
			PARRY_ALIGNMENT_FLOOR
		)
	var def_row: Variant = CombatConstants.LINE_ANGLE_DEG.get(guard_line, {})
	if def_row is Dictionary:
		var deg: float = float(def_row.get(attack_line, 90))
		return maxf(PARRY_ALIGNMENT_FLOOR, cos(deg * PI / 180.0))
	return PARRY_ALIGNMENT_FLOOR
