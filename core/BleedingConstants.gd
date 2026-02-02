class_name BleedingConstants
extends RefCounted

# Injury-based bleeding: rates by injury type and severity, body part multipliers,
# blood volume, death from blood loss, clotting, and bandaging.
# Aligned with clinical sources: ATLS hemorrhage classes (I–IV), arterial vs venous vs capillary
# (cut > crush), scalp/face/trunk bleed more (body part mults). See BLEEDING_MEDICAL_ACCURACY.md.
# Body parts: head, chest, right_arm, left_arm, right_leg, left_leg (match CoreEntity).

# --- Injury types (cut = sharp/laceration, crush = blunt trauma) ---
# Cut injuries more likely to open vessels (arterial/venous) -> higher rates than crush.
const INJURY_TYPE_CUT: String = "cut"
const INJURY_TYPE_CRUSH: String = "crush"

# --- Severity levels (from damage vs part max; maps to wound depth/vessel involvement) ---
const SEVERITY_MINOR: String = "minor"
const SEVERITY_MODERATE: String = "moderate"
const SEVERITY_SEVERE: String = "severe"
const SEVERITY_CRITICAL: String = "critical"

# --- Bleeding rates (abstract HP/s) by injury type and severity ---
# Cut > crush (lacerations open vessels; blunt more capillary). Severe/critical = arterial-like.
# Exact values tuned for gameplay; relative scaling is medically consistent.
const BLEEDING_RATES: Dictionary = {
	INJURY_TYPE_CUT: {
		SEVERITY_MINOR: 0.35,
		SEVERITY_MODERATE: 1.2,
		SEVERITY_SEVERE: 2.25,
		SEVERITY_CRITICAL: 4.5
	},
	INJURY_TYPE_CRUSH: {
		SEVERITY_MINOR: 0.25,
		SEVERITY_MODERATE: 0.65,
		SEVERITY_SEVERE: 1.2,
		SEVERITY_CRITICAL: 2.25
	}
}

# --- Body part bleeding multipliers (scalp/face/trunk more vascular; StatPearls / clinical) ---
# Used as base when no sub-region; with sub-regions, effective mult = part_base * sub_region_mult.
const BODY_PART_BLEEDING_MULTIPLIERS: Dictionary = {
	"head": 1.5,
	"chest": 1.2,
	"right_arm": 1.0,
	"left_arm": 1.0,
	"right_leg": 1.0,
	"left_leg": 1.0
}

# --- Sub-regions per body part (medical: scalp/face/neck, thoracic/abdominal, upper_arm/elbow/forearm/hand, thigh/knee/calf/foot) ---
# Research: scalp very vascular (StatPearls NBK541038); forearm vessels most injured in UE (StatPearls NBK536925);
# penetrating neck vascular ~25% (Zone I–III); popliteal blunt, SFA penetrating (lower limb); abdominal zones 1–4.
const SUB_REGIONS: Dictionary = {
	"head": ["scalp", "face", "neck"],
	"chest": ["thoracic", "abdominal"],
	"right_arm": ["upper_arm", "elbow", "forearm", "hand"],
	"left_arm": ["upper_arm", "elbow", "forearm", "hand"],
	"right_leg": ["thigh", "knee", "calf", "foot"],
	"left_leg": ["thigh", "knee", "calf", "foot"]
}
# Relative hit probability per sub-region (surface area / exposure). Sum per part can be any; we normalize.
const SUB_REGION_WEIGHTS: Dictionary = {
	"head": {"scalp": 1.2, "face": 1.0, "neck": 0.6},
	"chest": {"thoracic": 1.0, "abdominal": 1.0},
	"right_arm": {"upper_arm": 1.0, "elbow": 0.4, "forearm": 1.0, "hand": 0.8},
	"left_arm": {"upper_arm": 1.0, "elbow": 0.4, "forearm": 1.0, "hand": 0.8},
	"right_leg": {"thigh": 1.0, "knee": 0.5, "calf": 1.0, "foot": 0.6},
	"left_leg": {"thigh": 1.0, "knee": 0.5, "calf": 1.0, "foot": 0.6}
}
# Bleeding multiplier per sub-region (relative to limb baseline 1.0). Scalp bleeds profusely; neck carotid/jugular; forearm most injured in UE.
const SUB_REGION_BLEEDING_MULTIPLIERS: Dictionary = {
	"head": {"scalp": 1.8, "face": 1.4, "neck": 1.6},
	"chest": {"thoracic": 1.15, "abdominal": 1.25},
	"right_arm": {"upper_arm": 0.9, "elbow": 1.0, "forearm": 1.15, "hand": 1.05},
	"left_arm": {"upper_arm": 0.9, "elbow": 1.0, "forearm": 1.15, "hand": 1.05},
	"right_leg": {"thigh": 1.1, "knee": 1.2, "calf": 1.05, "foot": 0.95},
	"left_leg": {"thigh": 1.1, "knee": 1.2, "calf": 1.05, "foot": 0.95}
}
# Arterial chance multiplier per sub-region. Neck ~25% vascular; scalp superficial temporal; forearm vessels; popliteal/SFA.
const SUB_REGION_ARTERIAL_MULTIPLIERS: Dictionary = {
	"head": {"scalp": 1.2, "face": 1.1, "neck": 1.5},
	"chest": {"thoracic": 1.15, "abdominal": 1.2},
	"right_arm": {"upper_arm": 0.95, "elbow": 1.0, "forearm": 1.2, "hand": 0.9},
	"left_arm": {"upper_arm": 0.95, "elbow": 1.0, "forearm": 1.2, "hand": 0.9},
	"right_leg": {"thigh": 1.15, "knee": 1.25, "calf": 1.0, "foot": 0.85},
	"left_leg": {"thigh": 1.15, "knee": 1.25, "calf": 1.0, "foot": 0.85}
}
# Severity modifier per sub-region: effective_damage = damage * mult when mapping to severity (thin tissue = depth reached sooner).
# Scalp thin over bone; neck less tissue; abdominal soft; elbow/knee less tissue; hand/foot smaller cross-section.
const SUB_REGION_SEVERITY_MODIFIERS: Dictionary = {
	"head": {"scalp": 1.25, "face": 1.1, "neck": 1.15},
	"chest": {"thoracic": 1.0, "abdominal": 1.1},
	"right_arm": {"upper_arm": 0.95, "elbow": 1.15, "forearm": 1.0, "hand": 1.1},
	"left_arm": {"upper_arm": 0.95, "elbow": 1.15, "forearm": 1.0, "hand": 1.1},
	"right_leg": {"thigh": 0.95, "knee": 1.1, "calf": 1.0, "foot": 1.1},
	"left_leg": {"thigh": 0.95, "knee": 1.1, "calf": 1.0, "foot": 1.1}
}

# --- Blood volume (percentage 0–100). ATLS: Class I <15% loss, II 15–30%, III 30–40%, IV >40% (fatal). ---
const MAX_BLOOD_VOLUME: float = 100.0
# total_bleeding_rate * this = blood % lost per second (gameplay scaling).
const BLOOD_LOSS_RATE_MULTIPLIER: float = 0.28
# Death when remaining blood_volume <= this. 35% remaining = 65% lost (Class IV, typically fatal).
const BLOOD_LOSS_DEATH_THRESHOLD: float = 35.0
# Critical state (UI/effects) when remaining <= this (Class III–IV border).
const BLOOD_LOSS_CRITICAL_THRESHOLD: float = 30.0

# --- Clotting: exponential decay of bleeding rate (rate *= exp(-k*delta)). First-order kinetics. ---
# Per-severity clotting rate (k) per second. Half-life of rate = ln(2)/k. See RESEARCH_BASED_APPROXIMATIONS.md, MINOR_WOUND_BLEEDING_METHODS.md.
# Minor: small cuts stop in seconds–minutes (faster k). Severe/critical: vessel involvement, clot slower.
const CLOTTING_RATE_BY_SEVERITY: Dictionary = {
	SEVERITY_MINOR: 0.05,     # half-life ~14 s; ~1.2 min to ~1% rate ("small cuts may stop in seconds")
	SEVERITY_MODERATE: 0.02,  # half-life ~35 s; ~4 min to ~1% rate (normal wounds 2–7 min)
	SEVERITY_SEVERE: 0.01,    # half-life ~70 s; ~8 min (vessel involvement)
	SEVERITY_CRITICAL: 0.005  # half-life ~139 s; ~15 min (deep vessel involvement)
}
# When bandaged: same fast clotting for all severities (pressure stops flow, clot forms quickly).
const CLOTTING_RATE_STABILIZED: float = 0.15  # per second when bandaged; half-life ~4.6 s

# --- Arterial bleeding chance (research-based) ---
# Penetrating (cut) wounds: depth/severity correlates with vessel involvement. Soft signs: 1 sign ~10% vascular injury, 2+ ~25%.
# Penetrating neck: vascular injury in ~25% of penetrating neck trauma (StatPearls, penetrating neck). Blunt = 20-25% of vascular injuries vs penetrating 75-80%.
# Base chance for CUT by severity (superficial = low, deep/critical = high). Crush uses ARTERIAL_CRUSH_MULTIPLIER (blunt less often arterial).
const ARTERIAL_CHANCE_BY_SEVERITY: Dictionary = {
	SEVERITY_MINOR: 0.01,    # superficial, rarely reaches vessels
	SEVERITY_MODERATE: 0.06, # moderate depth
	SEVERITY_SEVERE: 0.14,   # deep; soft-sign range
	SEVERITY_CRITICAL: 0.26  # high damage; 25% vascular in penetrating neck / 2+ soft signs
}
const ARTERIAL_CRUSH_MULTIPLIER: float = 0.35  # blunt causes ~20-25% of vascular injuries vs penetrating
# Body part: neck/head 25% vascular in penetrating; chest major vessels; limbs vascular injury ~1% of extremity trauma but when present = major arteries.
const ARTERIAL_BODY_PART_MULTIPLIERS: Dictionary = {
	"head": 1.4,   # scalp/face/neck highly vascular; penetrating neck ~25% vascular
	"chest": 1.2,  # major vessels (aorta, iliac, etc.)
	"right_arm": 1.0,
	"left_arm": 1.0,
	"right_leg": 1.0,
	"left_leg": 1.0
}
# When a wound is arterial: higher bleeding rate and pressure inhibits clotting (2-5 min to exsanguination if uncontrolled).
const ARTERIAL_BLEEDING_MULTIPLIER: float = 2.0   # arterial bleeds much faster
const ARTERIAL_CLOTTING_MULTIPLIER: float = 0.15  # arterial pressure inhibits clotting; clot very slowly

# --- Bandaging ---
# Research: arterial wounds need pressure points / tourniquets; simple bandages less effective (pressure inhibits clot).
const BANDAGE_IMMEDIATE_REDUCTION: float = 0.6   # 60% immediate reduction when bandage applied
const BANDAGE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.6  # bandage less effective on arterial wounds
const BANDAGE_STABILIZATION_DURATION: float = 300.0  # seconds (optional; 0 = no expiry)

# --- Severity thresholds (damage as fraction of part max) ---
const SEVERITY_PERCENTAGE_CRITICAL: float = 0.75
const SEVERITY_PERCENTAGE_SEVERE: float = 0.5
const SEVERITY_PERCENTAGE_MODERATE: float = 0.25
# Absolute damage thresholds for large parts (e.g. chest with high max)
const SEVERITY_ABSOLUTE_CRITICAL: float = 10.0
const SEVERITY_ABSOLUTE_SEVERE: float = 5.0
const SEVERITY_ABSOLUTE_MINOR: float = 2.0

static func get_bleeding_rate(injury_type: String, severity: String, part: String, sub_region: String = "") -> float:
	var type_rates: Dictionary = BLEEDING_RATES.get(injury_type, {})
	var base_rate: float = type_rates.get(severity, 0.0)
	var mult: float = BODY_PART_BLEEDING_MULTIPLIERS.get(part, 1.0)
	if not sub_region.is_empty() and SUB_REGION_BLEEDING_MULTIPLIERS.get(part, {}).get(sub_region, 0.0) > 0.0:
		mult *= SUB_REGION_BLEEDING_MULTIPLIERS[part][sub_region]
	return base_rate * mult

static func get_body_part_multiplier(part: String) -> float:
	return BODY_PART_BLEEDING_MULTIPLIERS.get(part, 1.0)

# Pick a random sub-region given the body part was hit. Uses SUB_REGION_WEIGHTS[part] so probabilities are relative to that part only. Returns empty string if part has no sub-regions.
static func get_random_sub_region(part: String) -> String:
	var subs: Array = SUB_REGIONS.get(part, [])
	var weights: Dictionary = SUB_REGION_WEIGHTS.get(part, {})
	if subs.is_empty() or weights.is_empty():
		return ""
	var total: float = 0.0
	for sub in subs:
		total += float(weights.get(sub, 1.0))
	if total <= 0.0:
		return subs[0]
	var r: float = randf() * total
	var acc: float = 0.0
	for sub in subs:
		acc += float(weights.get(sub, 1.0))
		if r < acc:
			return sub
	return subs[subs.size() - 1]

static func get_sub_regions(part: String) -> Array:
	return SUB_REGIONS.get(part, []).duplicate()

# Effective damage multiplier for severity mapping (thin tissue / exposed bone = higher effective depth).
static func get_severity_modifier(part: String, sub_region: String) -> float:
	if sub_region.is_empty() or not SUB_REGION_SEVERITY_MODIFIERS.get(part, {}).has(sub_region):
		return 1.0
	return SUB_REGION_SEVERITY_MODIFIERS[part][sub_region]

# Per-severity clotting rate (k per second). Use when not stabilized; arterial applies ARTERIAL_CLOTTING_MULTIPLIER on top.
static func get_clotting_rate(severity: String) -> float:
	return CLOTTING_RATE_BY_SEVERITY.get(severity, 0.02)  # 0.02 = moderate default

# Chance (0.0-1.0) that a wound is arterial based on severity, injury type (cut vs crush), body part, and sub-region. Research-based.
static func get_arterial_chance(severity: String, injury_type: String, part: String, sub_region: String = "") -> float:
	var base_chance: float = ARTERIAL_CHANCE_BY_SEVERITY.get(severity, 0.06)
	if injury_type == INJURY_TYPE_CRUSH:
		base_chance *= ARTERIAL_CRUSH_MULTIPLIER
	var part_mult: float = ARTERIAL_BODY_PART_MULTIPLIERS.get(part, 1.0)
	if not sub_region.is_empty() and SUB_REGION_ARTERIAL_MULTIPLIERS.get(part, {}).get(sub_region, 0.0) > 0.0:
		part_mult *= SUB_REGION_ARTERIAL_MULTIPLIERS[part][sub_region]
	return clampf(base_chance * part_mult, 0.0, 1.0)
