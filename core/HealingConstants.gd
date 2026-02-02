class_name HealingConstants
extends RefCounted

# Medically realistic healing: duration-based (days/weeks) for tissue, bone, and blood volume.
# Bleeding continues outside combat; time advance runs bleeding, blood loss, then healing.
# Healing uses EXPONENTIAL decay of deficit (rate ∝ current deficit): 72% of wounds fit exponential; 35% vs 21% closure (BMC Dermatol 9:2). See RESEARCH_BASED_APPROXIMATIONS.md.
# Body parts: head, chest, right_arm, left_arm, right_leg, left_leg (match CoreEntity).
# References: wound healing phases (inflammatory 2–5 days, proliferation ~3 weeks); fracture 6–8 weeks.

const SECONDS_PER_DAY: float = 86400.0

# --- Tissue healing: "duration" = time (seconds) to ~95% healed when using exponential model (deficit *= exp(-t/τ), τ = duration/3) ---
# Minor: superficial ~3–5 days. Moderate: 1–2 weeks. Severe: 3–6 weeks. Critical: 6+ weeks.
const TISSUE_HEAL_DURATION_SECONDS: Dictionary = {
	"minor": 4.0 * SECONDS_PER_DAY,    # ~4 days
	"moderate": 10.0 * SECONDS_PER_DAY, # ~10 days
	"severe": 21.0 * SECONDS_PER_DAY,   # ~3 weeks
	"critical": 42.0 * SECONDS_PER_DAY  # ~6 weeks
}

# Part multipliers: longer duration = slower heal (chest/head often slower due to depth/vascularity).
const TISSUE_PART_DURATION_MULTIPLIERS: Dictionary = {
	"head": 1.15,
	"chest": 1.25,
	"right_arm": 1.0,
	"left_arm": 1.0,
	"right_leg": 1.0,
	"left_leg": 1.0
}

# --- Bone healing (simple fracture ~6–8 weeks) ---
const BONE_HEAL_DURATION_SECONDS: float = 42.0 * SECONDS_PER_DAY  # 6 weeks to full

const BONE_PART_DURATION_MULTIPLIERS: Dictionary = {
	"head": 1.2,   # skull
	"chest": 1.3,  # ribs/sternum
	"right_arm": 1.0,
	"left_arm": 1.0,
	"right_leg": 1.1,
	"left_leg": 1.1
}

# --- Blood volume recovery (when not bleeding) ---
# Body replenishes blood over hours–days. Full recovery from low volume over ~24–48 h.
const BLOOD_VOLUME_RECOVERY_DURATION_SECONDS: float = 24.0 * 3600.0  # 24 hours to approach 100%

# Exponential healing: time constant τ = duration / EXPONENTIAL_HEAL_TAU_DIVISOR so that after duration seconds, ~95% healed (1 - e^(-3) ≈ 0.95).
const EXPONENTIAL_HEAL_TAU_DIVISOR: float = 3.0

# --- Helpers ---
static func get_tissue_heal_duration_seconds(part: String, severity: String) -> float:
	var base: float = TISSUE_HEAL_DURATION_SECONDS.get(severity, 10.0 * SECONDS_PER_DAY)
	var part_mult: float = TISSUE_PART_DURATION_MULTIPLIERS.get(part, 1.0)
	return base * part_mult

static func get_bone_heal_duration_seconds(part: String) -> float:
	var part_mult: float = BONE_PART_DURATION_MULTIPLIERS.get(part, 1.0)
	return BONE_HEAL_DURATION_SECONDS * part_mult
