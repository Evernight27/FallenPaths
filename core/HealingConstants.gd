class_name HealingConstants
extends RefCounted

## Healing time, difficulty, and material cost multipliers by body part and injury type.

# Medically realistic healing: duration-based (days/weeks) for tissue, bone, and blood volume.
# Bleeding continues outside combat; time advance runs bleeding, blood loss, then healing.
# Healing uses EXPONENTIAL decay of deficit (rate ~ current deficit): 72% of wounds fit exponential; 35% vs 21% closure
# (BMC Dermatol 9:2). See RESEARCH_BASED_APPROXIMATIONS.md.
# Body parts: head, chest, right_arm, left_arm, right_leg, left_leg (match CoreEntity).
# References: wound healing phases (inflammatory 2 - 5 days, proliferation ~3 weeks); fracture 6 - 8 weeks.

const SECONDS_PER_DAY: float = 86400.0

# --- Tissue healing: "duration" = time (seconds) to ~95% healed when using exponential model (deficit *= exp(-t/tau),
# tau = duration/3) ---
# Minor: superficial ~3 - 5 days. Moderate: 1 - 2 weeks. Severe: 3 - 6 weeks. Critical: 6+ weeks.
const TISSUE_HEAL_DURATION_SECONDS: Dictionary = {
    "minor": 4.0 * SECONDS_PER_DAY,  # ~4 days
    "moderate": 10.0 * SECONDS_PER_DAY,  # ~10 days
    "severe": 21.0 * SECONDS_PER_DAY,  # ~3 weeks
    "critical": 42.0 * SECONDS_PER_DAY  # ~6 weeks
}

# Part multipliers: longer duration = slower heal (chest/head often slower due to depth/vascularity).
const TISSUE_PART_DURATION_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: 1.15,
    BodyPartConstants.PART_CHEST: 1.25,
    BodyPartConstants.PART_RIGHT_ARM: 1.0,
    BodyPartConstants.PART_LEFT_ARM: 1.0,
    BodyPartConstants.PART_RIGHT_LEG: 1.0,
    BodyPartConstants.PART_LEFT_LEG: 1.0
}

# --- Bone healing (simple fracture ~6 - 8 weeks) ---
const BONE_HEAL_DURATION_SECONDS: float = 42.0 * SECONDS_PER_DAY  # 6 weeks to full

const BONE_PART_DURATION_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: 1.2,  # skull
    BodyPartConstants.PART_CHEST: 1.3,  # ribs/sternum
    BodyPartConstants.PART_RIGHT_ARM: 1.0,
    BodyPartConstants.PART_LEFT_ARM: 1.0,
    BodyPartConstants.PART_RIGHT_LEG: 1.1,
    BodyPartConstants.PART_LEFT_LEG: 1.1
}

# --- Blood volume recovery (when not bleeding) ---
# Body replenishes blood over hours - days. Full recovery from low volume over ~24 - 48 h.
const BLOOD_VOLUME_RECOVERY_DURATION_SECONDS: float = 24.0 * 3600.0  # 24 hours to approach 100%

# Exponential healing: time constant tau = duration / EXPONENTIAL_HEAL_TAU_DIVISOR so that after duration seconds, ~95%
# healed (1 - e^(-3) 'permille^ 0.95).
const EXPONENTIAL_HEAL_TAU_DIVISOR: float = 3.0

# --- Nutrition: malnutrition impairs wound healing (clinical: protein/energy deficiency slows tissue repair).
# nutrition_level 1.0 (well-fed) -> 1.0x; 0.0 (starving) -> NUTRITION_HEAL_STARVATION_MULT (0.6x).
const NUTRITION_HEAL_STARVATION_MULT: float = 0.6

# --- Per-wound healing (individual pain resolution and wound lifecycle) ---
# Injury types: "cut", "crush", "bruise", "fracture" (BleedingConstants). Each wound gets its own healing duration by
# part + severity + type.
# Bruises (contusions): closed injury; pain resolves by severity (small bump = days, deep contusion = ~2 weeks).
# Fracture: bone injury from blunt; no bleed; pain resolves over bone-healing time (~6 weeks by part).
# Cut/crush: use tissue duration by severity; part multipliers reflect vascularity/depth (head/chest slower).
const WOUND_TYPE_BRUISE: String = "bruise"
const WOUND_TYPE_FRACTURE: String = "fracture"

# Bruise: duration to ~95% pain resolution by severity. Minor = small bump (~4 d); moderate - critical = deeper/larger,
# longer.
# Minor bruise now comparable to minor cut (4 d); typical "2 weeks" for severe.
const BRUISE_HEAL_DURATION_BY_SEVERITY: Dictionary = {
    "minor": 4.0 * SECONDS_PER_DAY,  # ~4 days (small bruise)
    "moderate": 8.0 * SECONDS_PER_DAY,  # ~8 days
    "severe": 14.0 * SECONDS_PER_DAY,  # ~2 weeks (typical contusion)
    "critical": 21.0 * SECONDS_PER_DAY  # ~3 weeks (deep/large contusion)
}

# Per-part multiplier for bruise resolution (scalp/face/trunk can linger; limbs typical).
const BRUISE_PART_DURATION_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: 1.2,
    BodyPartConstants.PART_CHEST: 1.1,
    BodyPartConstants.PART_RIGHT_ARM: 1.0,
    BodyPartConstants.PART_LEFT_ARM: 1.0,
    BodyPartConstants.PART_RIGHT_LEG: 1.0,
    BodyPartConstants.PART_LEFT_LEG: 1.0
}

# Crush (blunt with bleeding): same phases as tissue; use tissue duration.
# Cut (laceration): full tissue duration by severity + part.
# Fracture: bone-healing duration by part (~6 weeks); pain resolution follows bone healing.
# Wound is removed when healing progress >= this (~95% healed). Used by EntityHealing and pain resolution.
const WOUND_RESOLVED_THRESHOLD: float = 0.95


# Returns seconds to ~95% healing (pain resolution) for this wound. Used for per-wound pain decay and "resolved"
# removal.
static func get_wound_healing_duration_seconds(part: String, severity: String, injury_type: String) -> float:
    if injury_type == WOUND_TYPE_BRUISE:
        var base: float = BRUISE_HEAL_DURATION_BY_SEVERITY.get(severity, 14.0 * SECONDS_PER_DAY)
        var part_mult: float = BRUISE_PART_DURATION_MULTIPLIERS.get(part, 1.0)
        return base * part_mult
    if injury_type == WOUND_TYPE_FRACTURE:
        return get_bone_heal_duration_seconds(part)
    # Cut and crush: tissue-based duration (unique per body part and severity)
    return get_tissue_heal_duration_seconds(part, severity)


# --- Helpers ---
static func get_tissue_heal_duration_seconds(part: String, severity: String) -> float:
    var base: float = TISSUE_HEAL_DURATION_SECONDS.get(severity, 10.0 * SECONDS_PER_DAY)
    var part_mult: float = TISSUE_PART_DURATION_MULTIPLIERS.get(part, 1.0)
    return base * part_mult


static func get_bone_heal_duration_seconds(part: String) -> float:
    var part_mult: float = BONE_PART_DURATION_MULTIPLIERS.get(part, 1.0)
    return BONE_HEAL_DURATION_SECONDS * part_mult
