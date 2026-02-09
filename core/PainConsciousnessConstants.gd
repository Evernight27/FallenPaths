class_name PainConsciousnessConstants
extends RefCounted

# Pain and consciousness (Combat Extended–style), adjusted for fallen-paths action-bar combat.
# Used by CoreEntity and CombatManager for gauge fill, hit chance, and incapacitation.

# --- Pain tiers (total pain points; from wounds: damage × severity multiplier summed) ---
const PAIN_MODERATE: float = 20.0   # 20–40: moderate pain
const PAIN_SEVERE: float = 40.0    # 40–60: severe
const PAIN_EXTREME: float = 60.0   # 60–80: extreme
const PAIN_INTOLERABLE: float = 80.0  # 80+: intolerable

# --- Pain → consciousness reduction (subtractive; applied after base × blood) ---
const PAIN_CONSCIOUSNESS_REDUCTION_MINOR: float = 0.0    # pain < 20
const PAIN_CONSCIOUSNESS_REDUCTION_MODERATE: float = 10.0  # 20–40: -10%
const PAIN_CONSCIOUSNESS_REDUCTION_SEVERE: float = 25.0   # 40–60: -25%
const PAIN_CONSCIOUSNESS_REDUCTION_EXTREME: float = 50.0  # 60–80: -50%
const PAIN_CONSCIOUSNESS_REDUCTION_INTOLERABLE: float = 75.0  # 80+: -75%

# --- Pain → performance modifier (action bar fill, hit chance). Multiplier; 1.0 = no penalty. ---
const PAIN_PERFORMANCE_NONE: float = 0.0
const PAIN_PERFORMANCE_MINOR: float = 0.05    # -5%
const PAIN_PERFORMANCE_MODERATE: float = 0.15  # -15%
const PAIN_PERFORMANCE_SEVERE: float = 0.30    # -30%
const PAIN_PERFORMANCE_EXTREME: float = 0.50   # -50%

# --- Consciousness: direct scale (effective_consciousness / 100 = performance scale). ---
# Incapacitation when true consciousness < this (no longer able to act).
const INCAPACITATION_CONSCIOUSNESS_THRESHOLD: float = 10.0

# --- Blood → consciousness (below this blood % remaining, consciousness is reduced). ---
const BLOOD_CONSCIOUSNESS_THRESHOLD: float = 50.0
const BLOOD_CONSCIOUSNESS_REDUCTION_MAX: float = 0.5  # max 50% consciousness reduction from blood

# --- Pain shock (temporary; reduces effective consciousness for combat, not incapacitation). ---
const PAIN_SHOCK_THRESHOLD: float = 50.0       # total pain > this: roll for shock
const PAIN_SHOCK_RISK_PER_POINT: float = 0.02  # shock chance = (pain - threshold) * this, capped 0–1
const PAIN_SHOCK_DURATION_BASE: float = 5.0    # base duration seconds; scaled by pain level
const PAIN_SHOCK_CONSCIOUSNESS_REDUCTION: float = 80.0  # -80% effective consciousness while in shock

# --- Performance floor (action bar and hit chance never below this). ---
const MIN_PERFORMANCE_MODIFIER: float = 0.35

# --- Per-injury pain: damage × this by severity (summed for get_total_pain). ---
const SEVERITY_PAIN_MULTIPLIERS: Dictionary = {
	"minor": 0.5,
	"moderate": 1.0,
	"severe": 1.5,
	"critical": 2.0
}

static func get_pain_consciousness_reduction(total_pain: float) -> float:
	if total_pain < PAIN_MODERATE:
		return PAIN_CONSCIOUSNESS_REDUCTION_MINOR
	if total_pain < PAIN_SEVERE:
		return PAIN_CONSCIOUSNESS_REDUCTION_MODERATE
	if total_pain < PAIN_EXTREME:
		return PAIN_CONSCIOUSNESS_REDUCTION_SEVERE
	if total_pain < PAIN_INTOLERABLE:
		return PAIN_CONSCIOUSNESS_REDUCTION_EXTREME
	return PAIN_CONSCIOUSNESS_REDUCTION_INTOLERABLE

static func get_pain_performance_modifier(total_pain: float) -> float:
	if total_pain < PAIN_MODERATE:
		return 1.0 - PAIN_PERFORMANCE_NONE
	if total_pain < PAIN_SEVERE:
		return 1.0 - PAIN_PERFORMANCE_MINOR
	if total_pain < PAIN_EXTREME:
		return 1.0 - PAIN_PERFORMANCE_MODERATE
	if total_pain < PAIN_INTOLERABLE:
		return 1.0 - PAIN_PERFORMANCE_SEVERE
	return 1.0 - PAIN_PERFORMANCE_EXTREME

static func get_consciousness_performance_modifier(consciousness: float) -> float:
	return clampf(consciousness / 100.0, 0.0, 1.0)

static func get_combined_performance_modifier(total_pain: float, consciousness: float) -> float:
	var pain_mod: float = get_pain_performance_modifier(total_pain)
	var cons_mod: float = get_consciousness_performance_modifier(consciousness)
	return maxf(MIN_PERFORMANCE_MODIFIER, pain_mod * cons_mod)
