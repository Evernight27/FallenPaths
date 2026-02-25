class_name BleedingConstants
extends RefCounted

# Injury-based bleeding: rates by injury type and severity, body part multipliers,
# blood volume, death from blood loss, clotting, and bandaging.
# Aligned with clinical sources: ATLS hemorrhage classes (I–IV), arterial vs venous vs capillary
# (cut > crush), scalp/face/trunk bleed more (body part mults). See BLEEDING_MEDICAL_ACCURACY.md.
# Body parts: head, chest, right_arm, left_arm, right_leg, left_leg (match CoreEntity).

# --- Injury types (cut = sharp/laceration, crush = blunt trauma, bruise = contusion, fracture = bone) ---
# Cut injuries more likely to open vessels (arterial/venous) -> higher rates than crush.
# Bruise: closed injury; pain without significant bleeding; resolves by severity (HealingConstants).
# Fracture: bone damage from blunt (or high-energy impact); no bleed; pain resolves over bone-healing time (~6 weeks).
const INJURY_TYPE_CUT: String = "cut"
const INJURY_TYPE_CRUSH: String = "crush"
const INJURY_TYPE_BRUISE: String = "bruise"
const INJURY_TYPE_FRACTURE: String = "fracture"

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
	},
	INJURY_TYPE_BRUISE: {
		SEVERITY_MINOR: 0.0,
		SEVERITY_MODERATE: 0.0,
		SEVERITY_SEVERE: 0.0,
		SEVERITY_CRITICAL: 0.0
	},
	INJURY_TYPE_FRACTURE: {
		SEVERITY_MINOR: 0.0,
		SEVERITY_MODERATE: 0.0,
		SEVERITY_SEVERE: 0.0,
		SEVERITY_CRITICAL: 0.0
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
# Arterial chance multiplier per sub-region (for both cut and crush; crush then scaled by SUB_REGION_BLUNT_ARTERIAL_MODIFIERS).
# Neck ~25% vascular in penetrating; scalp STA; forearm most injured in UE; SFA (thigh) penetrating, popliteal (knee) blunt.
const SUB_REGION_ARTERIAL_MULTIPLIERS: Dictionary = {
	"head": {"scalp": 1.2, "face": 1.1, "neck": 1.5},
	"chest": {"thoracic": 1.15, "abdominal": 1.2},
	"right_arm": {"upper_arm": 0.95, "elbow": 1.0, "forearm": 1.2, "hand": 0.9},
	"left_arm": {"upper_arm": 0.95, "elbow": 1.0, "forearm": 1.2, "hand": 0.9},
	"right_leg": {"thigh": 1.15, "knee": 1.15, "calf": 1.0, "foot": 0.85},
	"left_leg": {"thigh": 1.15, "knee": 1.15, "calf": 1.0, "foot": 0.85}
}
# --- Stump (amputation site) bleeding: part-accurate + level variation ---
# Amputation level: more proximal (closer to torso) = larger vessels = higher stump bleed; distal (hand, foot) = lower.
# Multiplier applied on top of part + sub_region bleeding rate for critical cut. Slight per-stump variation applied in CoreEntity.
const STUMP_LEVEL_MULTIPLIERS: Dictionary = {
	"head": {"scalp": 1.15, "face": 1.0, "neck": 1.25},
	"chest": {"thoracic": 1.08, "abdominal": 1.12},
	"right_arm": {"upper_arm": 1.22, "elbow": 1.08, "forearm": 1.0, "hand": 0.88},
	"left_arm": {"upper_arm": 1.22, "elbow": 1.08, "forearm": 1.0, "hand": 0.88},
	"right_leg": {"thigh": 1.2, "knee": 1.1, "calf": 1.0, "foot": 0.88},
	"left_leg": {"thigh": 1.2, "knee": 1.1, "calf": 1.0, "foot": 0.88}
}
# Stump wounds: arterial chance multiplier (amputation often involves major vessels).
const STUMP_ARTERIAL_CHANCE_MULTIPLIER: float = 1.4

# Blunt (crush) arterial modifier per sub-region: scales ARTERIAL_CRUSH_MULTIPLIER so cut vs blunt differentiation is region-specific. 1.0 = default; <1 = blunt less often arterial than cut; >1 = blunt relatively more (e.g. knee/popliteal). Research: penetrating 85% neck vascular; thoracic/abdomen penetrating predominates; LE popliteal blunt, SFA penetrating; scalp STA 80% blunt cephalovascular.
const SUB_REGION_BLUNT_ARTERIAL_MODIFIERS: Dictionary = {
	"head": {"scalp": 0.9, "face": 0.75, "neck": 0.5},
	"chest": {"thoracic": 0.5, "abdominal": 0.6},
	"right_arm": {"upper_arm": 0.85, "elbow": 0.9, "forearm": 1.0, "hand": 0.9},
	"left_arm": {"upper_arm": 0.85, "elbow": 0.9, "forearm": 1.0, "hand": 0.9},
	"right_leg": {"thigh": 0.6, "knee": 1.25, "calf": 0.9, "foot": 0.9},
	"left_leg": {"thigh": 0.6, "knee": 1.25, "calf": 0.9, "foot": 0.9}
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
# total_bleeding_rate * this = blood % lost per second. 0.10 gives ~2–5 min to exsanguination for uncontrolled arterial (BALANCING_INVESTIGATION.md); use 0.28 for faster lethality.
const BLOOD_LOSS_RATE_MULTIPLIER: float = 0.10
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
# Multiplier on clotting rate by severity: minor clots faster (superficial); severe/critical slower (vessel involvement). BLEEDING_MEDICAL_ACCURACY §7, MINOR_WOUND_BLEEDING_METHODS Method 1.
const CLOTTING_SEVERITY_MULTIPLIERS: Dictionary = {
	SEVERITY_MINOR: 1.5,     # minor: effective k higher → ~9 s half-life ("stop in seconds")
	SEVERITY_MODERATE: 1.0,
	SEVERITY_SEVERE: 0.5,     # severe/critical: vessel involvement → clot slower
	SEVERITY_CRITICAL: 0.25
}
# When bandaged: clotting rate (Option A: tuned for ~2-5 min to hemostasis, research-based).
const CLOTTING_RATE_STABILIZED: float = 0.006  # per second when bandaged; half-life ~2 min
# Rate below this is treated as clotted (removal). Avoids relying on float underflow. MINOR_WOUND_BLEEDING_METHODS Method 4.
const BLEEDING_RATE_EPSILON: float = 0.001

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
const ARTERIAL_CRUSH_MULTIPLIER: float = 0.35  # blunt arterial chance = 35% of cut's; literature: penetrating 64-82% of extremity vascular injuries (blunt 18-36%)
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
# Research: arterial wounds need direct pressure / tourniquets; simple bandages less effective (pressure inhibits clot). BLEEDING_MEDICAL_ACCURACY §9a.
# Option A: stronger reduction to compensate for slower clotting (2-5 min to hemostasis).
const BANDAGE_IMMEDIATE_REDUCTION: float = 0.75  # 75% immediate reduction on success (venous/capillary)
const BANDAGE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.5  # bandage less effective on arterial (50% of reduction); arterial often needs more than a simple bandage
const BANDAGE_STABILIZATION_DURATION: float = 0.0  # 0 = no expiry; bandage stays effective until wound heals
# Option B: success rate (research: conventional bandages ~32-70% hemostasis; medical skill affects outcome).
const BANDAGE_SUCCESS_BASE_CHANCE: float = 0.7  # base success for venous/capillary
const BANDAGE_SUCCESS_ARTERIAL_MULT: float = 0.6  # arterial harder to bandage successfully
# Time (seconds) to apply a bandage to one wound; action system should delay effect until this duration has passed.
const BANDAGE_APPLICATION_TIME_SECONDS: float = 4.0
# Extra seconds per additional wound on the same body part (bandaging multiple wounds takes longer).
const BANDAGE_PER_WOUND_EXTRA_SECONDS: float = 2.0

# --- Wound packing (head/chest; deep cavity; linen/cloth stuffed into wound) ---
# Medieval: Celsus, Albucasis, Crusades—packing wounds with lint, linen, cloth to control hemorrhage. For junctional/deep wounds where tourniquet cannot be used.
const PACKING_PARTS: Array = ["head", "chest"]
const PACKING_IMMEDIATE_REDUCTION: float = 0.85  # stronger than bandage for deep wounds
const PACKING_ARTERIAL_EFFECTIVENESS_MULT: float = 0.55  # slightly better than bandage on arterial (reaches cavity)
const PACKING_SUCCESS_BASE_CHANCE: float = 0.65  # harder technique than bandage
const PACKING_SUCCESS_ARTERIAL_MULT: float = 0.6  # arterial harder to pack successfully
const PACKING_APPLICATION_TIME_SECONDS: float = 10.0
const PACKING_PER_WOUND_EXTRA_SECONDS: float = 3.0

# --- Direct pressure (uses arm to apply pressure; stronger than bandage, requires functional arm) ---
# First-line hemorrhage control: hands-on pressure. Stronger immediate reduction than bandage; still less effective on arterial.
const DIRECT_PRESSURE_IMMEDIATE_REDUCTION: float = 0.8   # 80% reduction (vs bandage 75%)
const DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.7  # 70% of that on arterial (vs bandage 50%); arterial still harder to control
# Bleeding rate ±variance at wound creation (simulates hit in more/less vascular spot). BLEEDING_MEDICAL_ACCURACY §10.
const BLEEDING_RATE_VARIANCE_MIN: float = 0.9
const BLEEDING_RATE_VARIANCE_MAX: float = 1.1

# --- Tourniquet (limb-only; stops arterial/venous flow when applied correctly) ---
# Only limbs can be tourniqueted; head/chest/junctional need packing/direct pressure. CoTCCC, TCCC guidelines.
# Historical: tourniquets used since Roman era for amputations; modern TCCC: life-threatening extremity hemorrhage,
# traumatic amputation, arterial bleeding, uncontrolled bleeding. Bandages/direct pressure first-line for compressible hemorrhage.
# Tourniquet indicated when: (1) limb bleeding rate >= this threshold (severe), (2) severed limb (stump), or (3) heavily damaged (severe/critical wounds).
const LIMB_PARTS: Array = ["right_arm", "left_arm", "right_leg", "left_leg"]
# Bleeding rate (abstract HP/s) above which tourniquet is appropriate. Severe cut base = 2.25; moderate = 1.2.
const TOURNIQUET_BLEEDING_RATE_THRESHOLD: float = 2.0
# Optional: max duration (seconds) before tourniquet should be released to assess limb; 0 = no expiry. Real-world ~2 h risk for limb.
const TOURNIQUET_MAX_DURATION_SECONDS: float = 0.0  # 0 = no auto-expiry; set e.g. 7200 (2 h) for limb-ischemia risk
# Time (seconds) to apply a tourniquet (positioning, tightening); action system should delay effect until this duration has passed.
const TOURNIQUET_APPLICATION_TIME_SECONDS: float = 18.0
# Success rate: tourniquets can fail if not tight enough or poorly placed. Training/medical skill affects outcome.
const TOURNIQUET_SUCCESS_BASE_CHANCE: float = 0.85  # base success; proper application requires training

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

# Stump (amputation site) bleeding: part + sub_region (level) accurate. Sub_region = where the cut occurred (proximal vs distal).
# If sub_region empty, uses 1.0 for level multiplier. Caller should pass get_random_sub_region(part) when level unknown.
static func get_stump_bleeding_rate(part: String, sub_region: String = "") -> float:
	var base: float = get_bleeding_rate(INJURY_TYPE_CUT, SEVERITY_CRITICAL, part, sub_region)
	var level_mult: float = 1.0
	if not sub_region.is_empty() and STUMP_LEVEL_MULTIPLIERS.get(part, {}).has(sub_region):
		level_mult = STUMP_LEVEL_MULTIPLIERS[part][sub_region]
	return base * level_mult

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

# Multiplier on clotting rate by severity (minor faster, severe/critical slower). Apply in process_bleeding: clotting *= get_clotting_multiplier(sev).
static func get_clotting_multiplier(severity: String) -> float:
	return CLOTTING_SEVERITY_MULTIPLIERS.get(severity, 1.0)

# Chance (0.0-1.0) that a wound is arterial based on severity, injury type (cut vs crush), body part, and sub-region. Research-based. Crush uses ARTERIAL_CRUSH_MULTIPLIER × SUB_REGION_BLUNT_ARTERIAL_MODIFIER for region-specific cut vs blunt differentiation.
static func get_arterial_chance(severity: String, injury_type: String, part: String, sub_region: String = "") -> float:
	var base_chance: float = ARTERIAL_CHANCE_BY_SEVERITY.get(severity, 0.06)
	if injury_type == INJURY_TYPE_CRUSH:
		base_chance *= ARTERIAL_CRUSH_MULTIPLIER
		if not sub_region.is_empty() and SUB_REGION_BLUNT_ARTERIAL_MODIFIERS.get(part, {}).has(sub_region):
			base_chance *= SUB_REGION_BLUNT_ARTERIAL_MODIFIERS[part][sub_region]
	var part_mult: float = ARTERIAL_BODY_PART_MULTIPLIERS.get(part, 1.0)
	if not sub_region.is_empty() and SUB_REGION_ARTERIAL_MULTIPLIERS.get(part, {}).get(sub_region, 0.0) > 0.0:
		part_mult *= SUB_REGION_ARTERIAL_MULTIPLIERS[part][sub_region]
	return clampf(base_chance * part_mult, 0.0, 1.0)
