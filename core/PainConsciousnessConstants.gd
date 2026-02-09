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

# --- Blood → consciousness (ATLS-aligned: effect starts at Class II, max at death threshold). ---
# Below START: consciousness modifier ramps down; at FLOOR (death threshold) modifier = 1.0 - REDUCTION_MAX.
# See BLOOD_LOSS_CONSCIOUSNESS_RESEARCH.md.
const BLOOD_CONSCIOUSNESS_START_THRESHOLD: float = 85.0   # No effect above this (Class I: <15% lost)
const BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD: float = 35.0   # Max reduction at/below this (align with BLOOD_LOSS_DEATH_THRESHOLD)
const BLOOD_CONSCIOUSNESS_REDUCTION_MAX: float = 0.5     # At floor: modifier = 0.5 (50% of base)

# --- Pain shock (temporary; reduces effective consciousness for combat, not incapacitation). ---
# Research: Lighter impacts cause brief grogginess; more severe single impacts cause longer confusion/disorientation (Frontiers Neurology 2020, concussion/TBI). Acute stress reaction and traumatic shock duration scale with severity of the triggering insult (ATLS, StatPearls). Duration therefore scales with both cumulative pain and the impact of the move that triggered the shock.
const PAIN_SHOCK_THRESHOLD: float = 50.0       # total pain > this: roll for shock
const PAIN_SHOCK_RISK_PER_POINT: float = 0.02  # shock chance = (pain - threshold) * this, capped 0–1
const PAIN_SHOCK_DURATION_BASE: float = 5.0    # base duration seconds; scaled by pain level and impact
const PAIN_SHOCK_CONSCIOUSNESS_REDUCTION: float = 80.0  # -80% effective consciousness while in shock
# Impact scaling: larger single hit → longer shock (mechanoporation / acute stress magnitude). Reference damage for 1.0x impact factor; bigger hits multiply duration up to IMPACT_MAX_MULTIPLIER.
const PAIN_SHOCK_DURATION_IMPACT_REFERENCE: float = 10.0   # damage of triggering hit vs this (e.g. 10 → 1.0x, 20 → 2.0x until cap)
const PAIN_SHOCK_DURATION_IMPACT_MAX_MULTIPLIER: float = 2.0  # max duration multiplier from impact (e.g. 2.0 = double duration for a heavy blow)

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

# Duration (seconds) for pain shock: base * (pain/threshold) * impact_mult. Impact = total damage of the hit that triggered the roll; 0 when shock triggered by bleed/healing (no single move).
static func get_pain_shock_duration_seconds(total_pain: float, triggering_hit_damage: float) -> float:
	var pain_ratio: float = total_pain / PAIN_SHOCK_THRESHOLD if PAIN_SHOCK_THRESHOLD > 0.0 else 1.0
	var base_duration: float = PAIN_SHOCK_DURATION_BASE * pain_ratio
	if triggering_hit_damage <= 0.0:
		return base_duration
	var impact_mult: float = 1.0 + minf(triggering_hit_damage / PAIN_SHOCK_DURATION_IMPACT_REFERENCE, PAIN_SHOCK_DURATION_IMPACT_MAX_MULTIPLIER - 1.0)
	return base_duration * impact_mult
