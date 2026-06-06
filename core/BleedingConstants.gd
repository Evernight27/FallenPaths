class_name BleedingConstants
extends RefCounted

# Injury-based bleeding: rates by injury type and severity, body part multipliers,
# blood volume, death from blood loss, clotting, and bandaging.
# Aligned with clinical sources: ATLS hemorrhage classes (I–IV), arterial vs venous vs capillary
# (cut > crush), scalp/face/trunk bleed more (body part mults).
# Units, calibration, and TTD derivation: docs/LIVE_PATHS.md#bleeding-physics
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
# Absolute HP/s values are gameplay units; lethality is calibrated via BLOOD_LOSS_RATE_MULTIPLIER
# (derived in CombatResearchAnchors.derived_blood_loss_multiplier_for_ttd for 30–120 s TTD).
# Relative scaling (cut>crush, head>limb, arterial mult) is medically ordered.
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
## S6 pilot: literal mL pool on entity (`blood_volume_ml`); `blood_volume` % synced for ATLS/UI. Default off.
const FEATURE_LITERAL_BLOOD_ML := true
## S6 pilot: soft-tissue penetration budget before bone (`CombatLayerTissue`). Default off.
const FEATURE_LAYER_TISSUE := true
## P3b M1–M2: `MaterialFailureCurves` pen/KE laws → game damage allocation. Default off.
const FEATURE_MATERIAL_FAILURE_CURVES := true
## M2: blend weight toward curve alloc when `FEATURE_MATERIAL_FAILURE_CURVES` on (1.0 = full replace).
const MATERIAL_CURVE_BLEND_WEIGHT := 1.0
## M3: per-layer yield/rupture vs flat mm budget (`CombatLayerTissue`). Default off.
const FEATURE_LAYER_TISSUE_CURVES := true
## M3: bleed bump when subcutaneous sheet is ruptured on this hit.
const LAYER_RUPTURE_SUBCUT_BLEED_MULT := 1.08
## M4 (cancelled): continuum damage memory per sub_region — reserved; do not enable.
const FEATURE_TISSUE_DAMAGE_D := false
## M6: internal tissue J capacity; `body_cutting` as display derived from J. Default off.
const FEATURE_TISSUE_ENERGY_POOL := true
## S8: shallow cut track → lower severity/bleed; blunt KE absorbed in flesh before bone MFB.
const FEATURE_PENETRATION_DEPTH_SEVERITY := true
const FEATURE_BLUNT_TISSUE_KE_GATE := true
## mm into tissue: at/below MIN → shallow mult; at/above FULL → full depth scaling (penetrating trauma).
const PENETRATION_DEPTH_SEVERITY_MIN_MM := 1.0
const PENETRATION_DEPTH_SEVERITY_FULL_MM := 5.0
const PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT := 0.82
## Deep penetrating cut: higher major-vessel involvement (ATLS / penetrating neck-extremity data).
const PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT := 0.72
const PENETRATION_DEPTH_ARTERIAL_DEEP_MULT := 1.12

const MAX_BLOOD_VOLUME: float = 100.0
# total_bleeding_rate × this = blood % lost per second (see docs/LIVE_PATHS.md#bleeding-physics).
# Derived: buffer (100−35)% / (REFERENCE_UNCONTROLLED_BLEED_RATE × 48 s) ≈ 0.1003; shipped 0.10 within tolerance.
# Calibrates TTD to ATLS/CoTCCC untreated major-bleed band (30–120 s). Tune lethality here, not raw HP/s alone.
const BLOOD_LOSS_RATE_MULTIPLIER: float = 0.10
# Death when remaining blood_volume <= this. 35% remaining = 65% lost (deep Class IV; ATLS IV begins >40% lost).
const BLOOD_LOSS_DEATH_THRESHOLD: float = 35.0
# Critical state (UI/effects) when remaining <= this (Class III–IV border).
const BLOOD_LOSS_CRITICAL_THRESHOLD: float = 30.0

# --- ATLS hemorrhage class (remaining blood %). ATLS 10th ed. loss bands: I <15%, II 15–30%, III 31–40%, IV >40%. ---
const ATLS_CLASS_I_MIN_REMAINING: float = 85.0   # <15% lost
const ATLS_CLASS_II_MIN_REMAINING: float = 70.0  # 15–30% lost
const ATLS_CLASS_III_MIN_REMAINING: float = 60.0 # 31–40% lost (60% remaining = 40% lost upper bound)
## S7: stepped consciousness curve by class (vs single linear ramp). Default on.
const FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS: bool = true

# --- Medical triage bands (remaining % volume). Used by MedicalPhaseController AI/urgency. ---
const MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING: float = 55.0
const MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING: float = 42.0
const MEDICAL_TRIAGE_DANGER_SECONDS: float = 90.0
const MEDICAL_TRIAGE_PERIL_SECONDS: float = 45.0

# --- Clotting: exponential decay of bleeding rate (rate *= exp(-k*delta)). First-order kinetics. ---
# Per-severity clotting rate (k) per second. Half-life of rate = ln(2)/k (first-order clot decay).
# Minor: small cuts stop in seconds–minutes (faster k). Severe/critical: vessel involvement, clot slower.
const CLOTTING_RATE_BY_SEVERITY: Dictionary = {
	SEVERITY_MINOR: 0.05,     # half-life ~14 s; ~1.2 min to ~1% rate ("small cuts may stop in seconds")
	SEVERITY_MODERATE: 0.02,  # half-life ~35 s; ~4 min to ~1% rate (normal wounds 2–7 min)
	SEVERITY_SEVERE: 0.01,    # half-life ~70 s; ~8 min (vessel involvement)
	SEVERITY_CRITICAL: 0.005  # half-life ~139 s; ~15 min (deep vessel involvement)
}
# Multiplier on clotting rate by severity: minor clots faster (superficial); severe/critical slower (vessel involvement).
const CLOTTING_SEVERITY_MULTIPLIERS: Dictionary = {
	SEVERITY_MINOR: 1.5,     # minor: effective k higher → ~9 s half-life ("stop in seconds")
	SEVERITY_MODERATE: 1.0,
	SEVERITY_SEVERE: 0.5,     # severe/critical: vessel involvement → clot slower
	SEVERITY_CRITICAL: 0.25
}
# When bandaged: clotting rate (Option A: tuned for ~2-5 min to hemostasis, research-based).
const CLOTTING_RATE_STABILIZED: float = 0.006  # per second when bandaged; half-life ~2 min
## Sustained direct pressure: faster local clotting than unstabilized open bleed (compression aids hemostasis).
const CLOTTING_RATE_UNDER_DIRECT_PRESSURE: float = 0.014
## Success mult when dressing completes while compression was still on the part (TCCC: do not release early).
const TREATMENT_PRESSURE_HELD_SUCCESS_MULT: float = 1.18
# Rate below this is treated as clotted (removal). Avoids relying on float underflow. MINOR_WOUND_BLEEDING_METHODS Method 4.
const BLEEDING_RATE_EPSILON: float = 0.001
# Heuristic: effective clotting rate (per second) for "will they clot before dying?". Used when permanent bleeding is reduced (e.g. partial tourniquet). If perm_rate <= (blood_volume - death_threshold) * this / BLOOD_LOSS_RATE_MULTIPLIER, integrated loss stays below remaining buffer so they survive. Conservative (between severe and critical).
const CLOTTING_SAFE_EFFECTIVE_RATE: float = 0.008

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
# Research: arterial wounds need direct pressure / tourniquets; simple bandages less effective (pressure inhibits clot).
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

# --- Combat stabilize (Camp-2.5): fast hemostatic hold; does not replace bandage/pack for map travel ---
const STABILIZE_APPLICATION_TIME_SECONDS: float = 2.0
const STABILIZE_PER_WOUND_EXTRA_SECONDS: float = 1.0
const STABILIZE_SUCCESS_BASE_CHANCE: float = 0.82
const STABILIZE_SUCCESS_ARTERIAL_MULT: float = 0.72
const STABILIZE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.55
const STABILIZE_IMMEDIATE_REDUCTION: float = 0.45

# --- Wound packing (head/chest; deep cavity; linen/cloth stuffed into wound) ---
# Medieval: Celsus, Albucasis, Crusades—packing wounds with lint, linen, cloth to control hemorrhage. For junctional/deep wounds where tourniquet cannot be used.
const PACKING_PARTS: Array = ["head", "chest"]
## Minimum wound severity to offer pack (B): moderate+ / critical / deep only — not shallow grazes.
const PACKING_MIN_SEVERITY_RANK: Dictionary = {
	SEVERITY_MINOR: 0,
	SEVERITY_MODERATE: 1,
	SEVERITY_SEVERE: 2,
	SEVERITY_CRITICAL: 3,
	"deep": 3,
	"light": 0,
}
const PACKING_MIN_SEVERITY := SEVERITY_MODERATE
## Linen strips consumed per pack attempt (C). Party pool on **`CoreEntity.linen_strips_remaining`**.
const PACKING_LINEN_COST_PER_ATTEMPT := 1
const PACKING_LINEN_PARTY_START := 6
const PACKING_IMMEDIATE_REDUCTION: float = 0.85  # stronger than bandage for deep wounds
const PACKING_ARTERIAL_EFFECTIVENESS_MULT: float = 0.55  # slightly better than bandage on arterial (reaches cavity)
const PACKING_SUCCESS_BASE_CHANCE: float = 0.65  # harder technique than bandage
const PACKING_SUCCESS_ARTERIAL_MULT: float = 0.6  # arterial harder to pack successfully
const PACKING_APPLICATION_TIME_SECONDS: float = 10.0
const PACKING_PER_WOUND_EXTRA_SECONDS: float = 3.0
## Junctional sub-regions: shallow/moderate bleeds → pressure/bandage first; pack when severe+ OR arterial
## (TCCC junctional / penetrating vascular — moderate neck/abd can still be arterial in this model).
const PACKING_STRICT_SUB_REGIONS: Dictionary = {
	"head": ["neck"],
	"chest": ["abdominal"],
}
const PACKING_STRICT_SUB_REGION_MIN_SEVERITY := SEVERITY_SEVERE
## Multi-channel cavity (several sub-regions / deep tracks): harder to pack successfully.
const PACKING_SUCCESS_PER_EXTRA_CHANNEL: float = 0.92

# --- Direct pressure (TCCC / CoTCCC MARCH step 1: direct pressure on compressible hemorrhage) ---
# Sustained manual compression: venous/capillary near-occlusion; arterial flow reduced but not reliably stopped until clot/dressing.
# Retained flow fractions = fraction of wound rate still lost while pressure is held (literature: arterial may still ooze ~30–50%).
const DIRECT_PRESSURE_IMMEDIATE_REDUCTION: float = 0.25  # initial placement only; sustained hold dominates
const DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS: float = 0.10  # ~90% flow reduction (compressible hemorrhage)
const DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL: float = 0.50  # ~50% reduction; systolic pressure fights back
const DIRECT_PRESSURE_REBOUND_TO_INTRINSIC_MULT: float = 1.0  # release before hemostasis → return to intrinsic wound rate (do not release early)
const DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.7  # first-touch trim on arterial wounds (vs bandage 50%)
# Bleeding rate ±variance at wound creation (simulates hit in more/less vascular spot).
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
# Research: layperson first-attempt ~50% (CAT with video), some devices 17%; without formal training results poor (e.g. "Missing expectations" windlass study). Trained/CoTCCC much higher.
const TOURNIQUET_SUCCESS_BASE_CHANCE: float = 0.85  # base success; medical skill scales this
# When applied successfully, bleeding reduction scales with application effectiveness (skill/tightness/placement).
# Perfect application can achieve near-complete occlusion; poor application leaves significant flow. residual_rate = raw_rate * (1 - effectiveness * this).
const TOURNIQUET_REDUCTION_AT_FULL: float = 0.99  # at 1.0 effectiveness → 99% reduction; 0.5 effectiveness → 49.5% (partial occlusion)

# --- Severity thresholds (damage as fraction of part max) ---
const SEVERITY_PERCENTAGE_CRITICAL: float = 0.75
const SEVERITY_PERCENTAGE_SEVERE: float = 0.5
const SEVERITY_PERCENTAGE_MODERATE: float = 0.25
# Absolute tissue damage (game units) — S4: decouple label from % body_max (prep for derived capacities).
const FEATURE_ABSOLUTE_SEVERITY_BANDS: bool = true
## When true with absolute bands: severity cannot exceed %‑based label (ceil on fragile small parts).
const FEATURE_ABSOLUTE_SEVERITY_PCT_CAP: bool = false
const SEVERITY_ABSOLUTE_CRITICAL: float = 10.0
const SEVERITY_ABSOLUTE_SEVERE: float = 5.0
const SEVERITY_ABSOLUTE_MODERATE: float = 2.0
## Legacy alias kept for callers referencing SEVERITY_ABSOLUTE_MINOR.
const SEVERITY_ABSOLUTE_MINOR: float = SEVERITY_ABSOLUTE_MODERATE
const SEVERITY_ABSOLUTE_BONE_CRITICAL: float = 6.0
const SEVERITY_ABSOLUTE_BONE_SEVERE: float = 3.0
const SEVERITY_ABSOLUTE_BONE_MODERATE: float = 1.0

## Documented worst-case single-channel bleed (critical arterial cut, head, no treatment). See docs/LIVE_PATHS.md#bleeding-physics.
const REFERENCE_UNCONTROLLED_BLEED_RATE: float = (
	BLEEDING_RATES[INJURY_TYPE_CUT][SEVERITY_CRITICAL]
	* BODY_PART_BLEEDING_MULTIPLIERS["head"]
	* ARTERIAL_BLEEDING_MULTIPLIER
)


## Shallow vs deep laceration: vessel involvement scales with penetration depth (ATLS penetrating trauma).
static func penetration_depth_severity_mult(penetration_to_tissue_mm: float) -> float:
	if not FEATURE_PENETRATION_DEPTH_SEVERITY or penetration_to_tissue_mm < 0.0:
		return 1.0
	if penetration_to_tissue_mm <= PENETRATION_DEPTH_SEVERITY_MIN_MM:
		return PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT
	if penetration_to_tissue_mm >= PENETRATION_DEPTH_SEVERITY_FULL_MM:
		return 1.0
	var span: float = PENETRATION_DEPTH_SEVERITY_FULL_MM - PENETRATION_DEPTH_SEVERITY_MIN_MM
	if span <= 0.01:
		return 1.0
	var t: float = (penetration_to_tissue_mm - PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
	return lerpf(PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT, 1.0, clampf(t, 0.0, 1.0))


## Arterial involvement scales with wound track depth (cuts only; uses same depth bands as severity).
static func penetration_depth_arterial_mult(penetration_to_tissue_mm: float) -> float:
	if not FEATURE_PENETRATION_DEPTH_SEVERITY or penetration_to_tissue_mm < 0.0:
		return 1.0
	if penetration_to_tissue_mm <= PENETRATION_DEPTH_SEVERITY_MIN_MM:
		return PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT
	if penetration_to_tissue_mm >= PENETRATION_DEPTH_SEVERITY_FULL_MM:
		return PENETRATION_DEPTH_ARTERIAL_DEEP_MULT
	var span: float = PENETRATION_DEPTH_SEVERITY_FULL_MM - PENETRATION_DEPTH_SEVERITY_MIN_MM
	if span <= 0.01:
		return 1.0
	var t: float = (penetration_to_tissue_mm - PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
	return lerpf(
		PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT, PENETRATION_DEPTH_ARTERIAL_DEEP_MULT, clampf(t, 0.0, 1.0)
	)


## ATLS hemorrhage class 1–4 from remaining blood volume % (ATLS 10th ed. loss bands).
static func atls_hemorrhage_class_from_remaining_pct(remaining_pct: float) -> int:
	var r: float = clampf(remaining_pct, 0.0, MAX_BLOOD_VOLUME)
	if r >= ATLS_CLASS_I_MIN_REMAINING:
		return 1
	if r >= ATLS_CLASS_II_MIN_REMAINING:
		return 2
	if r >= ATLS_CLASS_III_MIN_REMAINING:
		return 3
	return 4


## Consciousness modifier from blood loss (S7 stepped ATLS when flag on; else linear legacy).
static func blood_consciousness_modifier_from_remaining(
	remaining_pct: float,
	linear_start: float,
	linear_floor: float,
	linear_reduction_max: float,
	use_stepped: bool = FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS
) -> float:
	if remaining_pct >= linear_start:
		return 1.0
	if remaining_pct <= linear_floor:
		return maxf(0.0, 1.0 - linear_reduction_max)
	if not use_stepped:
		var reduction: float = (linear_start - remaining_pct) / (linear_start - linear_floor) * linear_reduction_max
		return maxf(0.0, 1.0 - reduction)
	# Piecewise within ATLS classes (mild Class II → marked Class IV toward death threshold).
	if remaining_pct >= ATLS_CLASS_II_MIN_REMAINING:
		return lerpf(0.96, 1.0, (remaining_pct - ATLS_CLASS_II_MIN_REMAINING) / (ATLS_CLASS_I_MIN_REMAINING - ATLS_CLASS_II_MIN_REMAINING))
	if remaining_pct >= ATLS_CLASS_III_MIN_REMAINING:
		return lerpf(0.88, 0.96, (remaining_pct - ATLS_CLASS_III_MIN_REMAINING) / (ATLS_CLASS_II_MIN_REMAINING - ATLS_CLASS_III_MIN_REMAINING))
	return lerpf(
		maxf(0.0, 1.0 - linear_reduction_max),
		0.88,
		(remaining_pct - linear_floor) / (ATLS_CLASS_III_MIN_REMAINING - linear_floor)
	)


## Blood volume % lost per second from summed wound bleed rates (game units).
static func blood_volume_loss_per_second(total_bleeding_rate: float, loss_mult: float = 1.0) -> float:
	return total_bleeding_rate * BLOOD_LOSS_RATE_MULTIPLIER * clampf(loss_mult, 0.0, 1.0)


## Seconds until `blood_volume` reaches a given death threshold at constant bleed (no clotting, no treatment).
static func seconds_to_exsanguination_at_death_threshold(
	total_bleeding_rate: float,
	blood_volume: float,
	death_threshold: float,
	loss_mult: float = 1.0
) -> float:
	var loss_per_s: float = blood_volume_loss_per_second(total_bleeding_rate, loss_mult)
	if loss_per_s <= 0.0:
		return INF
	var buffer: float = blood_volume - death_threshold
	if buffer <= 0.0:
		return 0.0
	return buffer / loss_per_s


## Seconds until `blood_volume` reaches default **`BLOOD_LOSS_DEATH_THRESHOLD`**.
static func seconds_to_exsanguination(
	total_bleeding_rate: float,
	blood_volume: float = MAX_BLOOD_VOLUME,
	loss_mult: float = 1.0
) -> float:
	return seconds_to_exsanguination_at_death_threshold(
		total_bleeding_rate, blood_volume, BLOOD_LOSS_DEATH_THRESHOLD, loss_mult
	)


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


## Fraction of wound bleed rate still lost while direct pressure is held (per injury).
static func direct_pressure_held_flow_retained(is_arterial: bool) -> float:
	if is_arterial:
		return DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL
	return DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS

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
static func get_arterial_chance(
	severity: String,
	injury_type: String,
	part: String,
	sub_region: String = "",
	penetration_to_tissue_mm: float = -1.0
) -> float:
	var base_chance: float = ARTERIAL_CHANCE_BY_SEVERITY.get(severity, 0.06)
	if injury_type == INJURY_TYPE_CRUSH:
		base_chance *= ARTERIAL_CRUSH_MULTIPLIER
		if not sub_region.is_empty() and SUB_REGION_BLUNT_ARTERIAL_MODIFIERS.get(part, {}).has(sub_region):
			base_chance *= SUB_REGION_BLUNT_ARTERIAL_MODIFIERS[part][sub_region]
	elif injury_type == INJURY_TYPE_CUT and penetration_to_tissue_mm >= 0.0:
		base_chance *= penetration_depth_arterial_mult(penetration_to_tissue_mm)
	var part_mult: float = ARTERIAL_BODY_PART_MULTIPLIERS.get(part, 1.0)
	if not sub_region.is_empty() and SUB_REGION_ARTERIAL_MULTIPLIERS.get(part, {}).get(sub_region, 0.0) > 0.0:
		part_mult *= SUB_REGION_ARTERIAL_MULTIPLIERS[part][sub_region]
	return clampf(base_chance * part_mult, 0.0, 1.0)
