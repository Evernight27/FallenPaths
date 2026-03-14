class_name CombatConstants
extends RefCounted

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
const RECOVERY_EXTRA_DEFLECTED_BASE_S := 0.1
const RECOVERY_DEFLECT_MOMENTUM_SCALE_S := 0.15
const RECOVERY_EXTRA_GLANCING_BASE_S := 0.12
const RECOVERY_GLANCING_SEVERITY_SCALE_S := 0.2
const RECOVERY_EXTRA_MISS_BASE_S := 0.35
const RECOVERY_MISS_COMMITMENT_SCALE_S := 0.9
const RECOVERY_EXTRA_FULL_STOP_BASE_S := 0.5
const RECOVERY_FULL_STOP_COMMITMENT_SCALE_S := 0.35
const WINDUP_LEG_MIN := 0.2
const RECOVERY_AFTER_MEDICAL_S := 0.5

# Miss/hit/glancing
const MISS_CHANCE_BASE := 0.06
const HIT_CHANCE_PERCEPTION_MIN := 0.8
const HIT_CHANCE_PERCEPTION_MAX := 1.2
const GLANCING_DAMAGE_RATIO := 0.25

# Intensity
const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 100.0
const INTENSITY_STRENGTH_BIAS := 0.35
const INTENSITY_RANDOM_RANGE := 0.2

# Medical
const MEDICAL_MOVE_IDS: Array[String] = ["bandage_self", "pack_wound", "apply_direct_pressure", "apply_tourniquet"]

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
# Non-blade attacks (pommel, mace head): impact weapons, no sustained blade contact → never bind, always deflect.
const ARCHETYPES_NEVER_BIND: Array[String] = ["pommel_strike", "heavy_blunt"]
# Bind riposte wind-up: parry_part × contact_type. Extend=fast, wind=moderate, swing=slow. Fallback for missing cells.
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
	"blade": {"stab": 0.52, "cut": 0.75},
	"shaft": {"stab": 0.54, "cut": 0.80, "blunt": 0.90},
	"haft": {"stab": 0.53, "cut": 0.78}
}
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = 0.85
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
# Part → primary guard line (for guard_zone/guard_line sync)
const PART_TO_LINE: Dictionary = {"head": "high", "chest": "high", "left_arm": "left", "right_arm": "right", "left_leg": "low", "right_leg": "low"}
# Line → default body part (for syncing guard_zone when guard_line changes from outcome)
const LINE_TO_DEFAULT_PART: Dictionary = {"high": "head", "low": "left_leg", "left": "left_arm", "right": "right_arm"}

# 4-line guard (Liechtenauer): physics-based parry alignment
# alignment = cos(θ); parry capacity ∝ alignment; variance ∝ 1/alignment; leak ∝ (1-alignment)
const PARRY_ALIGNMENT_FLOOR := 0.15
const GEOMETRIC_LEAK_MAX := 0.35
const PARRY_GEOMETRY_VARIANCE_BASE := 0.08

# Guard transition: wind-up cost when blade must move from current guard to attack line.
# Physics: angular distance; alignment=1 (same line) = no cost; alignment=0 = +40% wind-up.
const GUARD_TRANSITION_COST_SCALE := 0.4
# AI target selection: preferred_parts from move get this weight multiplier (cut geometry).
const PREFERRED_PART_BONUS_MULT := 1.5

# Debug: when true, log combat resolution events. Disable in release to avoid log overflow.
const COMBAT_DEBUG := false
# Calibration: when true, log alignment, parry_c_d, variance, remaining_ratio for tuning to HEMA 57–80% parry share.
const COMBAT_DEBUG_CALIBRATION := false

# Stamina (separate pool): attack/parry consume; refill when idle. At 0: parry penalty, attack damage reduction.
const STAMINA_MAX := 100.0
const STAMINA_REFILL_RATE := 12.0  # per second when idle
const STAMINA_ATTACK_COST_BASE := 8.0
const STAMINA_PARRY_COST := 10.0
const STAMINA_AT_ZERO_PARRY_MULT := 0.5
const STAMINA_AT_ZERO_DAMAGE_MULT := 0.6
# Non-linear fatigue: power 0.6 — sharp drop below ~25% stamina (exercise science).
# Used everywhere stamina affects outcome: variance, parry, damage.
const STAMINA_FACTOR_POWER := 0.6

## Returns 0-1. At 100% stamina → 1; at 0% → 0. Curve ramps down faster below ~25%.
static func stamina_factor(ratio: float) -> float:
	return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)

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

# Arm interpose (BP6): superseded by guard-dependent paths (ATTACK_PATHS_BY_GUARD).
# Path puts arms first when guard is high; no separate interpose roll. Kept for reference.
const INTERPOSE_BASE := 0.10
const INTERPOSE_EXPOSURE: Dictionary = {
	"high": {"high": 1.2, "low": 0.4, "left": 0.9, "right": 0.9},
	"low": {"high": 0.4, "low": 1.2, "left": 0.9, "right": 0.9},
	"left": {"high": 0.8, "low": 0.8, "left": 1.1, "right": 0.5},
	"right": {"high": 0.8, "low": 0.8, "left": 0.5, "right": 1.1}
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

## Returns attack path for (attack_line, guard_line). Fallback to ATTACK_PATHS if missing.
static func get_attack_path(attack_line: String, guard_line: String) -> Array:
	var by_guard: Variant = ATTACK_PATHS_BY_GUARD.get(attack_line, {})
	if by_guard is Dictionary and by_guard.has(guard_line):
		return by_guard[guard_line]
	return ATTACK_PATHS.get(attack_line, ATTACK_PATH_HIGH)

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
const ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT: float = 1.5
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

## Attack angle from pending_attack at given progress. Uses arc_start/arc_end when available;
## falls back to arc_intended_deg during wind-up (before arc_end is rolled at resolution).
static func get_attack_angle_at_progress(pa: Dictionary, progress: float) -> float:
	var start: float = pa.get("arc_start_deg", 0.0)
	var end: float = pa.get("arc_end_deg", -999.0)
	if end < -900.0:
		end = pa.get("arc_intended_deg", line_to_angle("high"))
	return get_arc_angle_at_progress(start, end, progress)

## Shortest angular distance (0–180°). Handles wraparound.
static func angle_diff_deg(a_deg: float, b_deg: float) -> float:
	var d := fmod(abs(a_deg - b_deg) + 360.0, 360.0)
	return minf(d, 360.0 - d) if d > 180.0 else d

## Map discrete line to angle. Returns LINE_TO_ANGLE_DEG value or 0 for unknown.
static func line_to_angle(line: String) -> float:
	return float(LINE_TO_ANGLE_DEG.get(line, 0))

## Map angle to nearest of 4 lines. Boundaries at 45° (high/right), 135° (right/low), 225° (low/left), 315° (left/high).
static func angle_to_nearest_line(angle_deg: float) -> String:
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
static func get_deflection_magnitude_deg(alignment: float, severity: float, attack_type: String) -> float:
	var base := (1.0 - alignment) * 90.0 * severity
	var mult: float = 1.0
	if attack_type == "stab":
		mult = 1.15
	elif attack_type == "blunt":
		mult = 0.9
	return base * mult * randf_range(0.9, 1.1)

## Returns alignment 0..1 from attack_line vs guard_line. Floor PARRY_ALIGNMENT_FLOOR for lucky intercept.
static func get_line_alignment(attack_line: String, guard_line: String) -> float:
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

## Guard angle from combatant. Uses guard_line; when guard_deflect_blend > 0, lerps from guard_deflect_from_line to guard_line.
## wobble_context: parry_readiness (0-1), defender_mass_kg (optional). When readiness < 1, adds ±wobble (defender reacting).
## Heavier defender weapon = more inertia = more wobble when reacting.
static func get_guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
	var line: String = combatant.get("guard_line", "high")
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
static func get_deflected_line_from_angles(attack_angle_deg: float, guard_angle_deg: float, severity: float, attack_type: String, alignment: float) -> String:
	var mag := get_deflection_magnitude_deg(alignment, severity, attack_type)
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
	var guard_line: String = combatant.get("guard_line", "high")
	var blend: float = combatant.get("guard_deflect_blend", 0.0)
	if blend <= 0.0:
		return get_line_alignment(attack_line, guard_line)
	var from_line: String = combatant.get("guard_deflect_from_line", guard_line)
	var align_from: float = get_line_alignment(attack_line, from_line)
	var align_to: float = get_line_alignment(attack_line, guard_line)
	return lerpf(align_from, align_to, blend)

## [DEPRECATED] Superseded by get_deflected_line_from_angles (angle-based, bilateral).
## Physics-based deflection: blade ends where parry geometry dictates.
## Same line (0°): bind — blade stays in attack line.
## Adjacent defender (45°): lateral shed — deflect to other adjacent (45° movement, plausible for single contact).
## Opposite defender (90°): strong block — deflect to opposite (90° movement, head-on impact).
static func get_deflected_line_from_geometry(attack_line: String, defender_guard_line: String) -> String:
	if attack_line == defender_guard_line:
		return attack_line  # Bind
	var adjacents: Variant = LINE_ADJACENTS.get(attack_line, [])
	if adjacents is Array:
		var adj_arr: Array = adjacents
		# Defender adjacent (45°)? Shed to the other adjacent — smaller angular displacement.
		if defender_guard_line in adj_arr:
			for a in adj_arr:
				if a != defender_guard_line:
					return str(a)
	# Defender opposite (90°): strong block drives blade through to opposite line.
	return DEFLECTED_GUARD_FROM_ATTACK.get(attack_line, attack_line)

## [DEPRECATED] Superseded by get_deflected_line_from_angles (uses get_deflection_magnitude_deg).
## HEMA: severity modulates opposite-defender outcome. Low severity → 45° (adjacent); high → 90° (opposite).
## attack_type: stab/cut/blunt use different thresholds.
static func get_deflected_line_with_severity(attack_line: String, defender_guard_line: String, severity: float, attack_type: String) -> String:
	if attack_line == defender_guard_line:
		return attack_line
	var adjacents: Variant = LINE_ADJACENTS.get(attack_line, [])
	if adjacents is Array:
		var adj_arr: Array = adjacents
		if defender_guard_line in adj_arr:
			for a in adj_arr:
				if a != defender_guard_line:
					return str(a)
	var thr: float = PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT
	if attack_type == "stab":
		thr = PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST
	elif attack_type == "blunt":
		thr = PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT
	if severity < thr:
		var adj: Array = adjacents if adjacents is Array else []
		return adj[0] if adj.size() > 0 else attack_line
	return DEFLECTED_GUARD_FROM_ATTACK.get(attack_line, attack_line)
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
	"apply_tourniquet": {"duration_method": "get_tourniquet_application_time_seconds", "duration_takes_part": false, "target_method": "apply_tourniquet", "outcome": "tourniquet_applied"}
}
