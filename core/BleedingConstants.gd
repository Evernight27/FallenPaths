class_name BleedingConstants
extends RefCounted

## Bleeding rates, injury types, hemorrhage physics constants.

# Injury-based bleeding: rates by injury type and severity, body part multipliers,
# blood volume, death from blood loss, clotting, and bandaging.
# Aligned with clinical sources: ATLS hemorrhage classes (I - IV), arterial vs venous vs capillary
# (cut > crush), scalp/face/trunk bleed more (body part mults).
# Units, calibration, and TTD derivation: docs/LIVE_PATHS.md#bleeding-physics
# Body parts: head, chest, right_arm, left_arm, right_leg, left_leg (match CoreEntity).

# --- Injury types (cut = sharp/laceration, crush = blunt trauma, bruise = contusion, fracture = bone) ---
# Cut injuries more likely to open vessels (arterial/venous) -> higher rates than crush.
# Bruise: closed injury; pain without significant bleeding; resolves by severity (HealingConstants).
# Fracture: bone damage from blunt (or high-energy impact); no bleed; pain resolves over bone-healing time (~6 weeks).
const INJURY_TYPE_CUT: String = "cut"
const INJURY_TYPE_STAB: String = "stab"
const INJURY_TYPE_CRUSH: String = "crush"
const INJURY_TYPE_BRUISE: String = "bruise"
const INJURY_TYPE_FRACTURE: String = "fracture"
const INJURY_TYPE_COMPOUND_FRACTURE: String = "compound_fracture"
## Internal-organ bleed: a torso thrust that reaches an organ opens a slow hemorrhage that external
## pressure/bandaging cannot reach (forensic: stabs penetrate deeper and reach organs surface cuts miss).
const INJURY_TYPE_INTERNAL_BLEED: String = "internal_bleed"
## Chance a penetrating torso thrust opens an internal-organ bleed (plan_balance_tuning.md Change 2).
const INTERNAL_BLEED_CHANCE_TORSO_THRUST: float = 0.15
## Head intracranial hemorrhage (subdural/epidural hematoma): a head wound that breaches the skull
## (fracture by blunt force, or a sharp wound penetrating past the inner table) opens an internal,
## unclottable bleed that external pressure cannot stop — distinct from the external scalp laceration
## it accompanies. Clinically such wounds are fatal hours-to-days later without surgical evacuation,
## and field care (bandaging/packing) cannot reach the source. Triggers when the head's bone (skull)
## channel is breached (to_bone > 0) or a sharp wound penetrates past the skull into the cranial cavity.
const HEAD_INTRACRANIAL_BLEED_MAX_CHANCE: float = 0.65
## Skull damage (to_bone, range 0..bone_max=8) at which intracranial-bleed chance reaches its max.
## A chip (to_bone 1-2) bleeds rarely; a full fracture (to_bone 5+) bleeds often.
const HEAD_INTRACRANIAL_BLEED_FULL_DMG: float = 5.0
## Sharp-wound penetration depth (mm past the head soft-tissue stack, i.e. into the skull) at which a
## head cut/thrust is considered to have breached the inner table into the cranial cavity. The adult
## skull is ~6-8 mm thick; 6.0 triggers intracranial bleed for deep penetrating wounds.
const HEAD_SKULL_BREACH_PEN_MM: float = 6.0

# --- Severity levels (from damage vs part max; maps to wound depth/vessel involvement) ---
const SEVERITY_MINOR: String = "minor"
const SEVERITY_MODERATE: String = "moderate"
const SEVERITY_SEVERE: String = "severe"
const SEVERITY_CRITICAL: String = "critical"

# --- Bleeding rates (abstract HP/s) by injury type and severity ---
# Cut > crush (lacerations open vessels; blunt more capillary). Severe/critical = arterial-like.
# Absolute HP/s values are gameplay units; lethality is calibrated via BLOOD_LOSS_RATE_MULTIPLIER
# (derived in CombatResearchAnchors.derived_blood_loss_multiplier_for_ttd for 120 - 300 s TTD).
# Relative scaling (cut>crush, head>limb, arterial mult) is medically ordered.
const BLEEDING_RATES: Dictionary = {
    INJURY_TYPE_CUT: {SEVERITY_MINOR: 0.3, SEVERITY_MODERATE: 1.2, SEVERITY_SEVERE: 4.0, SEVERITY_CRITICAL: 4.5},
    INJURY_TYPE_STAB: {SEVERITY_MINOR: 0.25, SEVERITY_MODERATE: 0.85, SEVERITY_SEVERE: 1.6, SEVERITY_CRITICAL: 3.2},
    INJURY_TYPE_CRUSH: {SEVERITY_MINOR: 0.25, SEVERITY_MODERATE: 0.65, SEVERITY_SEVERE: 1.2, SEVERITY_CRITICAL: 2.25},
    INJURY_TYPE_BRUISE: {SEVERITY_MINOR: 0.0, SEVERITY_MODERATE: 0.0, SEVERITY_SEVERE: 0.0, SEVERITY_CRITICAL: 0.0},
    INJURY_TYPE_FRACTURE: {SEVERITY_MINOR: 0.0, SEVERITY_MODERATE: 0.0, SEVERITY_SEVERE: 0.0, SEVERITY_CRITICAL: 0.0},
    ## Compound fracture — open bone exposed to external environment; ~40% infection rate (Gandhi 2002),
    ## elevated hemorrhage vs closed due to bone marrow vascularization and potential medullary vessel tearing.
    ## Rates are ~1.5× cut at moderate+ severity (not higher than cut — clinical Gustilo-Anderson data shows
    ## compound fractures bleed more than closed but typically less than deep lacerations of major vessels).
    INJURY_TYPE_COMPOUND_FRACTURE: {SEVERITY_MINOR: 0.0, SEVERITY_MODERATE: 1.5, SEVERITY_SEVERE: 4.0, SEVERITY_CRITICAL: 5.0},
    ## Internal-organ bleed: severity-scaled, unclottable (no clotting decay applies).
    ## A ruptured solid organ or great vessel sustains a near-constant rate that direct pressure
    ## cannot stop. Calibrated against BLOOD_LOSS_RATE_MULTIPLIER (0.01176) and chest sub-region
    ## multipliers: critical (aortic) ≈ 7 min to 50% threshold; severe (liver/spleen) ≈ 20 min;
    ## moderate (contusion) ≈ 90 min. Matches clinical 5-8 min major-vessel and 20-60 min
    ## solid-organ timelines (RESEARCH_hypovolemic_shock.md §8b).
    INJURY_TYPE_INTERNAL_BLEED: {SEVERITY_MINOR: 0.0, SEVERITY_MODERATE: 0.5, SEVERITY_SEVERE: 2.0, SEVERITY_CRITICAL: 5.0}
}

# --- Body part bleeding multipliers (scalp/face/trunk more vascular; StatPearls / clinical) ---
# Used as base when no sub-region; with sub-regions, effective mult = part_base * sub_region_mult.
# Combined body part × sub-region multiplier cap prevents extreme multiplicative stacking (e.g., head 1.5× neck 1.6× arterial 2.0x).
const MAX_BODY_PART_SUBREGION_BLEED_MULT: float = 2.4
const BODY_PART_BLEEDING_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: 1.5,
    BodyPartConstants.PART_CHEST: 1.2,
    BodyPartConstants.PART_RIGHT_ARM: 1.0,
    BodyPartConstants.PART_LEFT_ARM: 1.0,
    BodyPartConstants.PART_RIGHT_LEG: 1.0,
    BodyPartConstants.PART_LEFT_LEG: 1.0
}

# --- Sub-regions per body part (medical: scalp/face/neck, thoracic/abdominal/sternum, upper_arm/elbow/forearm/hand/armpit,
# thigh/knee/calf/foot/inner_thigh) ---
# Research: scalp very vascular (StatPearls NBK541038); forearm vessels most injured in UE (StatPearls NBK536925);
# penetrating neck vascular ~25% (Zone I - III); popliteal blunt, SFA penetrating (lower limb); abdominal zones 1 - 4.
const SUB_REGIONS: Dictionary = {
    BodyPartConstants.PART_HEAD: ["scalp", "face", "neck"],
    BodyPartConstants.PART_CHEST: ["thoracic", "abdominal", "sternum"],
    BodyPartConstants.PART_RIGHT_ARM: ["upper_arm", "elbow", "forearm", "hand", "armpit", "axillary"],
    BodyPartConstants.PART_LEFT_ARM: ["upper_arm", "elbow", "forearm", "hand", "armpit", "axillary"],
    BodyPartConstants.PART_RIGHT_LEG: ["thigh", "knee", "calf", "foot", "inner_thigh"],
    BodyPartConstants.PART_LEFT_LEG: ["thigh", "knee", "calf", "foot", "inner_thigh"]
}
# Relative hit probability per sub-region (surface area / exposure). Sum per part can be any; we normalize.
const SUB_REGION_WEIGHTS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 1.2, "face": 1.0, "neck": 0.6},
    BodyPartConstants.PART_CHEST: {"thoracic": 1.0, "abdominal": 1.0, "sternum": 0.4},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 1.0, "elbow": 0.4, "forearm": 1.0, "hand": 0.8, "armpit": 0.3, "axillary": 0.3},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 1.0, "elbow": 0.4, "forearm": 1.0, "hand": 0.8, "armpit": 0.3, "axillary": 0.3},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 1.0, "knee": 0.5, "calf": 1.0, "foot": 0.6, "inner_thigh": 0.45},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 1.0, "knee": 0.5, "calf": 1.0, "foot": 0.6, "inner_thigh": 0.45}
}
# Bleeding multiplier per sub-region (relative to limb baseline 1.0). Scalp bleeds profusely; neck carotid/jugular;
# forearm most injured in UE.
const SUB_REGION_BLEEDING_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 1.8, "face": 1.4, "neck": 2.2},
    BodyPartConstants.PART_CHEST: {"thoracic": 1.15, "abdominal": 1.25, "sternum": 1.30},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 0.9, "elbow": 1.0, "forearm": 1.15, "hand": 1.05, "armpit": 1.2, "axillary": 1.2},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 0.9, "elbow": 1.0, "forearm": 1.15, "hand": 1.05, "armpit": 1.2, "axillary": 1.2},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 1.1, "knee": 1.2, "calf": 1.05, "foot": 0.95, "inner_thigh": 1.35},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 1.1, "knee": 1.2, "calf": 1.05, "foot": 0.95, "inner_thigh": 1.35}
}
# Arterial chance multiplier per sub-region (for both cut and crush; crush then scaled by
# SUB_REGION_BLUNT_ARTERIAL_MODIFIERS).
# Neck ~25% vascular in penetrating; scalp STA; forearm most injured in UE; SFA (thigh) penetrating, popliteal (knee)
# blunt.
const SUB_REGION_ARTERIAL_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 1.2, "face": 1.1, "neck": 2.0},
    BodyPartConstants.PART_CHEST: {"thoracic": 1.15, "abdominal": 1.2, "sternum": 1.30},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 0.95, "elbow": 1.0, "forearm": 1.2, "hand": 0.9, "armpit": 1.1, "axillary": 1.1},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 0.95, "elbow": 1.0, "forearm": 1.2, "hand": 0.9, "armpit": 1.1, "axillary": 1.1},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 1.15, "knee": 1.15, "calf": 1.0, "foot": 0.85, "inner_thigh": 1.30},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 1.15, "knee": 1.15, "calf": 1.0, "foot": 0.85, "inner_thigh": 1.30}
}
# --- Stump (amputation site) bleeding: part-accurate + level variation ---
# Amputation level: more proximal (closer to torso) = larger vessels = higher stump bleed; distal (hand, foot) = lower.
# Multiplier applied on top of part + sub_region bleeding rate for critical cut. Slight per-stump variation applied in
# CoreEntity.
const STUMP_LEVEL_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 1.15, "face": 1.0, "neck": 1.25},
    BodyPartConstants.PART_CHEST: {"thoracic": 1.08, "abdominal": 1.12, "sternum": 1.15},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 1.22, "elbow": 1.08, "forearm": 1.0, "hand": 0.88, "armpit": 1.1, "axillary": 1.1},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 1.22, "elbow": 1.08, "forearm": 1.0, "hand": 0.88, "armpit": 1.1, "axillary": 1.1},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 1.2, "knee": 1.1, "calf": 1.0, "foot": 0.88, "inner_thigh": 1.15},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 1.2, "knee": 1.1, "calf": 1.0, "foot": 0.88, "inner_thigh": 1.15}
}
# Stump wounds: arterial chance multiplier (amputation often involves major vessels).
const STUMP_ARTERIAL_CHANCE_MULTIPLIER: float = 1.4

# Blunt (crush) arterial modifier per sub-region: scales ARTERIAL_CRUSH_MULTIPLIER so cut vs blunt differentiation is
# region-specific. 1.0 = default; <1 = blunt less often arterial than cut; >1 = blunt relatively more (e.g.
# knee/popliteal). Research: penetrating 85% neck vascular; thoracic/abdomen penetrating predominates; LE popliteal
# blunt, SFA penetrating; scalp STA 80% blunt cephalovascular.
const SUB_REGION_BLUNT_ARTERIAL_MODIFIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 0.9, "face": 0.75, "neck": 0.5},
    BodyPartConstants.PART_CHEST: {"thoracic": 0.5, "abdominal": 0.6, "sternum": 0.45},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 0.85, "elbow": 0.9, "forearm": 1.0, "hand": 0.9, "armpit": 0.7, "axillary": 0.7},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 0.85, "elbow": 0.9, "forearm": 1.0, "hand": 0.9, "armpit": 0.7, "axillary": 0.7},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 0.6, "knee": 1.25, "calf": 0.9, "foot": 0.9, "inner_thigh": 0.85},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 0.6, "knee": 1.25, "calf": 0.9, "foot": 0.9, "inner_thigh": 0.85}
}
# Severity modifier per sub-region: effective_damage = damage * mult when mapping to severity (thin tissue = depth
# reached sooner).
# Scalp thin over bone; neck less tissue; abdominal soft; elbow/knee less tissue; hand/foot smaller cross-section.
const SUB_REGION_SEVERITY_MODIFIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 1.25, "face": 1.1, "neck": 1.15},
    BodyPartConstants.PART_CHEST: {"thoracic": 1.0, "abdominal": 1.1, "sternum": 1.20},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 0.95, "elbow": 1.15, "forearm": 1.0, "hand": 1.1, "armpit": 1.15, "axillary": 1.15},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 0.95, "elbow": 1.15, "forearm": 1.0, "hand": 1.1, "armpit": 1.15, "axillary": 1.15},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 0.95, "knee": 1.1, "calf": 1.0, "foot": 1.1, "inner_thigh": 1.05},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 0.95, "knee": 1.1, "calf": 1.0, "foot": 1.1, "inner_thigh": 1.05}
}

# Vital zone damage multipliers — strikes to critical anatomical targets (vital organs, major vessels, brain) deal
# amplified mechanical damage beyond what tissue depth alone captures. Models clinical reality where a throat cut
# or sternum strike is disproportionately lethal vs equivalent damage to forearm/thigh. Based on ATLS vital organ
# zones and HEMA fight-ending strikes to head/chest core/groin.
## VITAL_DAMAGE_MULTIPLIERS maps (part, sub_region) → multiplier applied AFTER armor penetration but BEFORE bone/tissue allocation.
const VITAL_DAMAGE_MULTIPLIERS: Dictionary = {
    ## Head — brain exposure makes any head strike inherently more dangerous than limb strikes at equal damage.
    BodyPartConstants.PART_HEAD: {
        "scalp": 1.0,      # thick skull mitigates but hairline fractures can be fatal
        "face": 1.25,      # facial bones thin; proximity to eyes/brain increases severity
        "neck": 1.75       # carotid/jugular/trachea — fight-ending zone (Fiore's throat strikes)
    },
    ## Chest — thoracic organs (heart, aorta, lungs) and abdominal organs (liver, spleen, intestines).
    BodyPartConstants.PART_CHEST: {
        "thoracic": 1.50,  # heart/aorta/lungs exposure; penetrating chest trauma ~25% mortality even with care
        "abdominal": 1.35, # liver/spleen/GI tract — internal hemorrhage risk (peritoneal cavity)
        "sternum": 1.80    # direct heart/aortic strike through breastbone — fight-ending zone
    },
    ## Arms — no vital organs; standard multiplier for non-vital tissue.
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 0.9, "elbow": 1.0, "forearm": 0.95, "hand": 0.85, "armpit": 1.25, "axillary": 1.25},
    BodyPartConstants.PART_LEFT_ARM:  {"upper_arm": 0.9, "elbow": 1.0, "forearm": 0.95, "hand": 0.85, "armpit": 1.25, "axillary": 1.25},
    ## Legs — femoral artery in thigh is a vital concern; groin sub-region of upper leg is critical.
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 1.20, "knee": 1.0, "calf": 0.9, "foot": 0.8, "inner_thigh": 1.50},
    BodyPartConstants.PART_LEFT_LEG:  {"thigh": 1.20, "knee": 1.0, "calf": 0.9, "foot": 0.8, "inner_thigh": 1.50}
}

## Skull cut transmission — fraction of the allocated CUT (sharp) TISSUE damage that reaches brain tissue after the
## dense ~7mm skull blunts the edge (1.0 - this = absorbed by the skull). Applied to the allocated cut tissue
## (to_cut) AFTER the mechanism is determined, so the weapon's strike classification and bone allocation are
## unaffected — only the brain tissue damage is reduced. Cut channel only (blunt/bone skull trauma is unaffected).
## Prevents a single committed cut from fully lacerating the head in one blow, while keeping the head the most
## fragile region and allowing multiple blows to destroy it.
const HEAD_SKULL_CUT_TRANSMISSION: float = 0.2

# Groin-specific multiplier — applied when the attack targets the upper inner thigh region which clinically contains
# the femoral artery and vein in close proximity. A strike here has disproportionate hemorrhage risk even though it's
# technically on a leg part. Applied as an additional ×1.5 on top of thigh's 1.20 (net = 1.8) for groin-targeted hits.
## This is not a separate sub-region in the current anatomy model; instead, we check attack_line == "low" + part == leg
## to approximate groin targeting when the strike lands on upper inner thigh.
const VITAL_GROIN_MULTIPLIER: float = 1.50

# --- Blood volume (percentage 0 - 100). ATLS: Class I <15% loss, II 15 - 30%, III 30 - 40%, IV >40% (fatal). ---
## S6 pilot: literal mL pool on entity (`blood_volume_ml`); `blood_volume` % synced for ATLS/UI. Shipped.
const FEATURE_LITERAL_BLOOD_ML := true
## S6 pilot: soft-tissue penetration budget before bone (`CombatLayerTissue`). Shipped.
const FEATURE_LAYER_TISSUE := true
## P3b M1 - M2: `MaterialFailureCurves` pen/KE laws -> game damage allocation. Shipped.
const FEATURE_MATERIAL_FAILURE_CURVES := true
## M2: blend weight toward curve alloc when `FEATURE_MATERIAL_FAILURE_CURVES` on (1.0 = full replace).
const MATERIAL_CURVE_BLEND_WEIGHT := 1.0
## M3: per-layer yield/rupture vs flat mm budget (`CombatLayerTissue`). Shipped.
const FEATURE_LAYER_TISSUE_CURVES := true
## M3: bleed bump when subcutaneous sheet is ruptured on this hit.
const LAYER_RUPTURE_SUBCUT_BLEED_MULT := 1.08
## Dagger wounds: small blades create narrow deep channels that bypass natural clotting and tear vessels on entry/withdrawal.
## Clinically, dagger/pistol-grip stab wounds bleed ~2x surface cut at equivalent damage (Fiore/Talhoffer dagger combat).
const DAGGER_BLEED_MULTIPLIER: float = 2.0
## M4 (cancelled): continuum damage memory per sub_region  -  reserved; do not enable.
const FEATURE_TISSUE_DAMAGE_D := false
## M6: internal tissue J capacity; `body_cutting` as display derived from J. Shipped.
const FEATURE_TISSUE_ENERGY_POOL := true
## S8: shallow cut track -> lower severity/bleed; blunt KE absorbed in flesh before bone MFB.
const FEATURE_PENETRATION_DEPTH_SEVERITY := true
const FEATURE_BLUNT_TISSUE_KE_GATE := true
## mm into tissue: at/below MIN -> shallow mult; at/above FULL -> full depth scaling (penetrating trauma).
const PENETRATION_DEPTH_SEVERITY_MIN_MM := 1.0
const PENETRATION_DEPTH_SEVERITY_FULL_MM := 5.0
const PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT := 0.82
## Deep penetrating cut: higher major-vessel involvement (ATLS / penetrating neck-extremity data).
const PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT := 0.72
const PENETRATION_DEPTH_ARTERIAL_DEEP_MULT := 1.12

const MAX_BLOOD_VOLUME: float = 100.0
# Total bleeding rate — this = blood % lost per second (see docs/LIVE_PATHS.md#bleeding-physics).
# Derived from the clinical exsanguination target (LITERATURE_TTD_TARGET_S = 180 s, the median of the
# 120-300 s untreated major-arterial range; Irandoust/Byard 2013, J Forensic Leg Med 20:944-946):
#   buffer (100 - BLOOD_LOSS_DEATH_THRESHOLD)% / (REFERENCE_UNCONTROLLED_BLEED_RATE x 180 s)
#   = 50 / (23.625 x 180) = 0.01176.
# The reference (23.625) is the "clean" calibration anchor (critical × head × arterial, no vessel-damage
# amplifier). The live worst-case (with get_bleeding_rate's ×1.4 critical amplifier) is 33.075 → TTD
# ~128 s, still within the clinical 120–300 s band. The ×1.4 is the clinically-justified vessel-damage
# amplifier (critical wounds have worse vessel damage and wound cavity formation), not a double-scaling
# bug. The multiplier was calibrated against the clean anchor (23.625) to target 180 s, but the live
# worst-case lands at the fast end of the band (~128 s), which is realistic for a major arterial bleed.
# See CombatResearchDerivations.derived_blood_loss_multiplier_for_ttd() for the live derivation.
const BLOOD_LOSS_RATE_MULTIPLIER: float = 0.01176
## Hard cap on total blood loss rate (% blood/s) after all multipliers (injury type, body part,
## head, arterial, exertion). A sane ceiling for stacked arterial bleeds: at 3.5%/s the worst case
## (100%→50% death threshold) is ~14s exsanguination, i.e. ~13x faster than the reference-bleed TTD
## (~180 s, BLOOD_LOSS_RATE_MULTIPLIER 0.01176). Arterial is intentionally much faster than the
## 120-300 s clinical reference band (that speed is what makes it arterial); the cap only stops the
## absurd top end (e.g. 5-10 s). To clamp the worst case to the 120 s band floor instead, set this
## to ~0.42 (50/120).
const MAX_TOTAL_BLOOD_LOSS_RATE: float = 3.5
# Death when remaining blood_volume <= this. 50% remaining = 50% lost — ATLS Class IV, fatal
# untreated (~45-50% loss). Anchored to the clinical death point so the sim mirrors real-world
# exsanguination; the consciousness floor (BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD) carries the near-death
# weight — a fighter is unconscious well before this threshold, so the final window reads as an agonal phase.
const BLOOD_LOSS_DEATH_THRESHOLD: float = 50.0

# --- ATLS hemorrhage class (remaining blood %). ATLS 10th ed. loss bands: I <15%, II 15 - 30%, III 31 - 40%, IV >40%.
# ---
const ATLS_CLASS_I_MIN_REMAINING: float = 85.0  # <15% lost
const ATLS_CLASS_II_MIN_REMAINING: float = 70.0  # 15 - 30% lost
const ATLS_CLASS_III_MIN_REMAINING: float = 60.0  # 31 - 40% lost (60% remaining = 40% lost upper bound)
## S7: stepped consciousness curve by class (vs single linear ramp). Default on.
const FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS: bool = true
## Stepped consciousness band values (fraction of baseline mentation) for the ATLS curve.
## Class I top (>=85% remaining): fully oriented.
const ATLS_CONSC_CLASS_I_TOP: float = 1.0
## Class II floor (70% remaining, 30% lost): anxious but oriented (ATLS Class II).
const ATLS_CONSC_CLASS_II_FLOOR: float = 0.80
## Class III floor / Class IV top (60% remaining, 40% lost): confused/lethargic (ATLS 10th ed. Class III-IV).
## A patient at this boundary has significant cognitive impairment — confused, lethargic, poor decision-making.
## 0.30 maps to ~30% mentation; combined with pain the performance modifier reaches well below 0.5,
## so the fighter is severely degraded. Below this the curve drops steeply to the
## unconsciousness floor as Class IV progresses to exsanguination.
const ATLS_CONSC_CLASS_III_FLOOR: float = 0.30

# --- Rate/Endurance-aware syncope adjustment ---
# Medically, consciousness loss from hypovolemia depends not just on *volume lost*, but on the
# *rate* of loss and the patient's *compensatory endurance*. This adjusts the effective remaining %
# fed into the ATLS curve before it is evaluated, keeping the volume-based curve itself unchanged.
# Reference conditions: rate = 0%/s, endurance = 100 -> no shift (backward compatible).
const BLOOD_CONSC_RATE_REF_PCT_PER_S: float = 1.0    # %/s at which compensation is fully overwhelmed
const BLOOD_CONSC_RATE_SHIFT_MAX: float = 20.0       # Max effective-% reduction from rapid bleeding
const BLOOD_CONSC_END_REF: float = 100.0             # Reference endurance stat (no shift)
const BLOOD_CONSC_END_SHIFT_PER_POINT: float = 0.18  # Effective-% shift per endurance point above/below ref
const BLOOD_CONSC_END_SHIFT_MAX: float = 12.0        # Cap on endurance-based shift (in either direction)

# --- Medical triage bands (remaining % volume). Used by MedicalPhaseController AI/urgency. ---
const MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING: float = 58.0
const MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING: float = 55.0
# Scaled to the clinical 180 s ref-bleed TTD (danger ~1.25x, peril ~0.625x — same ratios as the
# old 60/30 s vs ~48 s TTD). These are the AI/urgency time windows, not gameplay pacing knobs.
const MEDICAL_TRIAGE_DANGER_SECONDS: float = 225.0
const MEDICAL_TRIAGE_PERIL_SECONDS: float = 112.5

 # --- Decompensation threshold: ATLS Class III→IV nonlinear collapse. ---
## When blood volume drops below this, compensatory mechanisms fail and the patient enters
## decompensated shock — a tipping point where deterioration accelerates non-linearly.
## 56% remaining = 44% lost, past the ATLS Class III→IV boundary (Class IV >40% loss): the point where
## tachycardia + vasoconstriction can no longer maintain perfusion; HR drifts toward bradycardia as a pre-terminal sign.
## Below this the patient is decompensated (ATLS Class III→IV): endogenous blood recovery collapses
## (see EntityWounds.process_blood_loss). The death spiral is carried by that recovery suppression + the
## blood→consciousness curve — decompensation does NOT accelerate a wound's bleed rate (a fixed vessel bleeds
## at a rate set by driving pressure, which falls as MAP drops).
const DECOMPENSATION_BLOOD_THRESHOLD: float = 56.0  # blood volume % — below this, decompensation active
## Field fluid resuscitation / transfusion: fraction of the current blood deficit restored per
## application at full effectiveness (scaled by treatment effectiveness). Closes the one-way
## decompensation death spiral — a medic can pull a bleeding-out comrade back above the
## decompensation threshold. Capped so a single bolus rarely fully restores (camp rest still
## governs full recovery).
const FLUID_RESUSCITATION_DEFICIT_RESTORE_FRACTION: float = 0.4
## A decompensated patient (blood_volume < DECOMPENSATION_BLOOD_THRESHOLD, ATLS Class III->IV) has a
## dilated, leaky vascular compartment and responds poorly to a crystalloid bolus — the same bolus
## restores far less effective circulating volume than in a compensated patient (classic teaching:
## deep shock needs repeated boluses / blood products, not one push). Multiply the restore fraction
## by this factor while decompensated so a single bolus rarely pulls a deep Class IV casualty back
## above the threshold on its own. Mirrors the binary DECOMPENSATION_BLOOD_THRESHOLD tipping point
## already used by the recovery-suppression path.
const FLUID_RESUSCITATION_DECOMPENSATED_MULT: float = 0.5

# --- Severity-dependent time-to-decompensation (ATLS Class I-IV progression) — clinical reference ---
## Clinically, the time from hemorrhage onset to compensatory collapse depends on bleeding rate and
## wound severity: Class II (15-30% loss) compensates 60-180 s, Class III (30-40% loss) ~30-90 s,
## Class IV (>40% loss) near-immediate (<30 s). This is modeled as a recovery-suppression +
## consciousness collapse (DECOMPENSATION_BLOOD_THRESHOLD), NOT as a bleed-rate acceleration: a
## fixed vessel bleeds at a rate set by its driving pressure, which FALLS as MAP drops, so
## decompensation does not speed the wound's flow. (Earlier versions drove a +80% bleed-rate
## multiplier from this ladder; that was physically inverted and has been removed.)

# --- Clotting: exponential decay of bleeding rate (rate *= exp(-k*delta)). First-order kinetics. ---
# Per-severity clotting rate (k) per second. Half-life of rate = ln(2)/k (first-order clot decay).
# Minor: small cuts stop in seconds - minutes (faster k). Severe/critical: vessel involvement, clot slower.
const CLOTTING_RATE_BY_SEVERITY: Dictionary = {
    # half-life ~14 s; ~1.2 min to ~1% rate ("small cuts may stop in seconds")  # half-life ~35 s; ~4 min to ~1% rate
    # (normal wounds 2 - 7 min)  # half-life ~56 s; ~6.5 min to ~1% rate (vessel involvement)  # half-life ~98 s; ~11
    # min for deep vessel involvement (slightly faster than old 15 min — modern hemostatic agents improve outcomes)
    SEVERITY_MINOR: 0.05,
    SEVERITY_MODERATE: 0.02,
    SEVERITY_SEVERE: 0.012,
    SEVERITY_CRITICAL: 0.007
}
# Multiplier on clotting rate by severity: minor clots faster (superficial); severe/critical slower (vessel
# involvement).
const CLOTTING_SEVERITY_MULTIPLIERS: Dictionary = {
    # minor: effective k higher -> ~9 s half-life ("stop in seconds")  # severe/critical: vessel involvement -> clot
    # slower
    SEVERITY_MINOR: 1.5,
    SEVERITY_MODERATE: 1.0,
    SEVERITY_SEVERE: 0.5,
    SEVERITY_CRITICAL: 0.25
}
# When bandaged: clotting rate (Option A: tuned for ~2-5 min to hemostasis, research-based).
const CLOTTING_RATE_STABILIZED: float = 0.006  # per second when bandaged; half-life ~2 min
## Sustained direct pressure: faster local clotting than unstabilized open bleed (compression aids hemostasis).
## Tuned for MapFieldCare FIELD_CARE_SIM_ADVANCE_SECONDS (~150 s): moderate venous -> local hemostasis while held.
const CLOTTING_RATE_UNDER_DIRECT_PRESSURE: float = 0.032
## Success mult when dressing completes while compression was still on the part (TCCC: do not release early).
const TREATMENT_PRESSURE_HELD_SUCCESS_MULT: float = 1.18
# Rate below this is treated as clotted (removal). Avoids relying on float underflow. MINOR_WOUND_BLEEDING_METHODS
# Method 4.
const BLEEDING_RATE_EPSILON: float = 0.001
# Heuristic: effective clotting rate (per second) for "will they clot before dying?". Used when permanent bleeding is
# reduced (e.g. partial tourniquet). If perm_rate <= (blood_volume - death_threshold) * this /
# BLOOD_LOSS_RATE_MULTIPLIER, integrated loss stays below remaining buffer so they survive. Conservative (between severe
# and critical).
# Re-anchored 0.008 -> 0.00183 (x4.37, matching the BLOOD_LOSS_RATE_MULTIPLIER 0.072 -> 0.01646 TTD re-anchor) so the
# danger gate's max-safe rate preserves its original calibration (~7.8 game-rate units, ~33% of the reference arterial
# rate): a major arterial bleed stays in danger, while clotting-manageable minor bleeds read as safe.
const CLOTTING_SAFE_EFFECTIVE_RATE: float = 0.00183

# --- Arterial bleeding chance (research-based) ---
# Penetrating (cut) wounds: depth/severity correlates with vessel involvement. Soft signs: 1 sign ~10% vascular injury,
# 2+ ~25%.
# Penetrating neck: vascular injury in ~25% of penetrating neck trauma (StatPearls, penetrating neck). Blunt = 20-25% of
# vascular injuries vs penetrating 75-80%.
# Base chance for CUT by severity (superficial = low, deep/critical = high). Crush uses ARTERIAL_CRUSH_MULTIPLIER (blunt
# less often arterial).
const ARTERIAL_CHANCE_BY_SEVERITY: Dictionary = {
    # superficial, rarely reaches vessels  # moderate depth  # deep; soft-sign range  # high damage; 25% vascular in
    # penetrating neck / 2+ soft signs
    SEVERITY_MINOR: 0.01,
    SEVERITY_MODERATE: 0.06,
    SEVERITY_SEVERE: 0.14,
    SEVERITY_CRITICAL: 0.26
}
# blunt arterial chance = 35% of cut's; literature: penetrating 64-82% of extremity vascular injuries (blunt 18-36%)
const ARTERIAL_CRUSH_MULTIPLIER: float = 0.35
# Body part: neck/head 25% vascular in penetrating; chest major vessels; limbs vascular injury ~1% of extremity trauma
# but when present = major arteries.
const ARTERIAL_BODY_PART_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: 1.4,  # scalp/face/neck highly vascular; penetrating neck ~25% vascular
    BodyPartConstants.PART_CHEST: 1.2,  # major vessels (aorta, iliac, etc.)
    BodyPartConstants.PART_RIGHT_ARM: 1.0,
    BodyPartConstants.PART_LEFT_ARM: 1.0,
    BodyPartConstants.PART_RIGHT_LEG: 1.0,
    BodyPartConstants.PART_LEFT_LEG: 1.0
}

# --- Explicit bleeding types (arterial / venous / capillary) with physiologically distinct rates ---
## Rather than a single "arterial" multiplier, wounds are classified into three hemorrhage types
## with independent rate modifiers and clotting behavior matching clinical observations:
## Arterial: bright red, spurting/synchronous with pulse; high pressure prevents natural clotting.
##   Rate ≈ 3-5× venous; death in 2-5 min without intervention (TCCC). Clotting nearly impossible without tourniquet.
## Venous: dark red, steady ooze; lower pressure allows partial hemostasis via platelet plug.
##   Rate = baseline; responds well to direct pressure/bandaging. Clots in 3-10 min with treatment.
## Capillary: slow oozing from surface vessels; lowest rate but can accumulate if untreated.
##   Rate ≈ 0.25× venous; usually self-limiting within minutes. Responds to minimal intervention.
const BLEEDING_TYPE_ARTERIAL: String = "arterial"
const BLEEDING_TYPE_VENOUS: String = "venous"
const BLEEDING_TYPE_CAPILLARY: String = "capillary"

# Rate multipliers relative to base wound rate (from injury_type × severity × body_part).
## Arterial: 3.5× vs old 3.0 — reflects systolic pressure driving flow through opened artery (clinical TCCC data).
## Venous: 1.0× = baseline rate. Capillary wounds get this as default when no arterial involvement.
## Capillary: 0.25× — slow ooze from superficial vascular disruption; minimal hemorrhage risk.
const BLEEDING_TYPE_RATE_MULT: Dictionary = {
    BLEEDING_TYPE_ARTERIAL: 3.5,
    BLEEDING_TYPE_VENOUS: 1.0,
    BLEEDING_TYPE_CAPILLARY: 0.25
}

# Clotting difficulty multipliers by bleeding type.
## Arterial pressure actively prevents clot formation (platelet plug cannot withstand systolic flow).
## Venous wounds can form stable clots under direct pressure. Capillary clots spontaneously in most cases.
const BLEEDING_TYPE_CLOTTING_MULT: Dictionary = {
    BLEEDING_TYPE_ARTERIAL: 0.1,     # arterial pressure prevents clotting; requires tourniquet or hemostatic agent
    BLEEDING_TYPE_VENOUS: 1.0,       # baseline clotting kinetics apply
    BLEEDING_TYPE_CAPILLARY: 2.5     # capillary bleeding clots rapidly; minor wounds self-limiting in seconds
}

# --- Bandaging ---
# Research: arterial wounds need direct pressure / tourniquets; simple bandages less effective (pressure inhibits clot).
# Option A: stronger reduction to compensate for slower clotting (2-5 min to hemostasis).
const BANDAGE_IMMEDIATE_REDUCTION: float = 0.70  # 70% immediate reduction on success (venous/capillary; TCCC ceiling)
# bandage less effective on arterial (50% of reduction); arterial often needs more than a simple bandage
const BANDAGE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.5
const BANDAGE_STABILIZATION_DURATION: float = 0.0  # 0 = no expiry; bandage stays effective until wound heals
# Option B: success rate (research: conventional bandages ~32-70% hemostasis; medical skill affects outcome).
const BANDAGE_SUCCESS_BASE_CHANCE: float = 0.55  # base success for venous/capillary (TCCC: conventional bandages ~32-70% hemostasis)
const BANDAGE_SUCCESS_ARTERIAL_MULT: float = 0.6  # arterial harder to bandage successfully
# Time (seconds) to apply a bandage to one wound; action system should delay effect until this duration has passed.
const BANDAGE_APPLICATION_TIME_SECONDS: float = 4.0
# Extra seconds per additional wound on the same body part (bandaging multiple wounds takes longer).
const BANDAGE_PER_WOUND_EXTRA_SECONDS: float = 2.0

# --- Combat stabilize (Camp-2.5): fast hemostatic hold; does not replace bandage/pack for map travel ---
const STABILIZE_APPLICATION_TIME_SECONDS: float = 4.0  # Quick temporary pressure hold (trims bleed only; NOT a definitive dress). Game-time 4s — a fast interim measure, far shorter than a full TCCC dressing (~2-5 min); the definitive bandage/pack carries the longer time.
const STABILIZE_PER_WOUND_EXTRA_SECONDS: float = 1.0
const STABILIZE_SUCCESS_BASE_CHANCE: float = 0.82
const STABILIZE_SUCCESS_ARTERIAL_MULT: float = 0.72
const STABILIZE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.55
const STABILIZE_IMMEDIATE_REDUCTION: float = 0.65

# --- Wound packing (head/chest; deep cavity; linen/cloth stuffed into wound) ---
# Medieval: Celsus, Albucasis, Crusades - packing wounds with lint, linen, cloth to control hemorrhage. For
# junctional/deep wounds where tourniquet cannot be used.
const PACKING_PARTS: Array = [BodyPartConstants.PART_HEAD, BodyPartConstants.PART_CHEST]
## Minimum wound severity to offer pack (B): moderate+ / critical / deep only  -  not shallow grazes.
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
## Junctional sub-regions: shallow/moderate bleeds -> pressure/bandage first; pack when severe+ OR arterial
## (TCCC junctional / penetrating vascular  -  moderate neck/abd can still be arterial in this model).
const PACKING_STRICT_SUB_REGIONS: Dictionary = {
    BodyPartConstants.PART_HEAD: ["neck"],
    BodyPartConstants.PART_CHEST: ["abdominal", "thoracic"],
}
const PACKING_STRICT_SUB_REGION_MIN_SEVERITY := SEVERITY_SEVERE
## Multi-channel cavity (several sub-regions / deep tracks): harder to pack successfully.
const PACKING_SUCCESS_PER_EXTRA_CHANNEL: float = 0.92

# --- Direct pressure (TCCC / CoTCCC MARCH step 1: direct pressure on compressible hemorrhage) ---
# Sustained manual compression: venous/capillary near-occlusion; arterial flow reduced but not reliably stopped until
# clot/dressing.
# Retained flow fractions = fraction of wound rate still lost while pressure is held (literature: arterial may still
# ooze ~30 - 50%).
const DIRECT_PRESSURE_IMMEDIATE_REDUCTION: float = 0.25  # initial placement only; sustained hold dominates
const DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS: float = 0.10  # ~90% flow reduction (compressible hemorrhage)
const DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL: float = 0.50  # ~50% reduction; systolic pressure fights back
# release before hemostasis -> return to intrinsic wound rate (do not release early)
const DIRECT_PRESSURE_REBOUND_TO_INTRINSIC_MULT: float = 1.0
## Partial rebound: when clotting reduced the current rate below base, only bounce back partially (realistic  -  tissue
## trauma already initiated hemostasis cascade).
const DIRECT_PRESSURE_REBOUND_PARTIAL_MULT: float = 0.75  # at low clotting: rebound to 75% of intrinsic (not full 100%)
const DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT: float = 0.7  # first-touch trim on arterial wounds (vs bandage 50%)
# Bleeding rate +/-variance at wound creation (simulates hit in more/less vascular spot).
const BLEEDING_RATE_VARIANCE_MIN: float = 0.9
const BLEEDING_RATE_VARIANCE_MAX: float = 1.1

# --- Tourniquet (limb-only; stops arterial/venous flow when applied correctly) ---
# Only limbs can be tourniqueted; head/chest/junctional need packing/direct pressure. CoTCCC, TCCC guidelines.
# Historical: tourniquets used since Roman era for amputations; modern TCCC: life-threatening extremity hemorrhage,
# traumatic amputation, arterial bleeding, uncontrolled bleeding. Bandages/direct pressure first-line for compressible
# hemorrhage.
# Tourniquet indicated when: (1) limb bleeding rate >= this threshold (severe), (2) severed limb (stump), or (3) heavily
# damaged (severe/critical wounds).
# Bleeding rate (abstract HP/s) above which tourniquet is appropriate. Sits between moderate cut (1.2) and severe
# cut (4.0) — a moderate bleed is managed with pressure/packing; a severe (arterial-like) bleed warrants a TQ.
const TOURNIQUET_BLEEDING_RATE_THRESHOLD: float = 2.0
# Max duration (seconds) before a tourniquet is auto-released to assess the limb; 0 = no expiry. Real-world ~2 h
# ischemia risk for the limb. The game compresses field time, so 1 game-hour maps to the real-world ~2 h risk window:
# a TQ applied in combat that is still on when campaign time advances past this window causes ischemic limb damage.
const TOURNIQUET_MAX_DURATION_SECONDS: float = 3600.0
# Fraction of the limb's tissue (per channel) lost when a tourniquet expires at the max-duration window
# (~2 h real-world). 2 h is the ONSET of ischemic risk, not established necrosis: Kragh et al. (J Trauma
# 2009 / Ann Surg 2010) report no TQ-related amputations up to ~6 h, and the 2 h mark is the reversible-injury
# boundary. So this is a meaningful but recoverable soft-tissue compromise (early compartment / muscle injury),
# not limb-destroying necrosis. Applied to body_cutting + body_blunt (not bone — ischemia damages soft tissue).
const TOURNIQUET_ISCHEMIA_TISSUE_FRACTION: float = 0.10
# Time (seconds) to apply a tourniquet (positioning, tightening); action system should delay effect until this duration
# has passed.
# 25s is a deliberate SUB-clinical pacing value: real CAT application is 45-90s under combat stress (Kragh et al.
# Am J Surg 2011) and improvised ligatures 2-5 min, but the medical phase now runs at the clinical 120-300 s TTD band.
const TOURNIQUET_APPLICATION_TIME_SECONDS: float = 25.0
# Success rate: tourniquets can fail if not tight enough or poorly placed. Training/medical skill affects outcome.
# Research: layperson first-attempt ~50% (CAT with video), some devices 17%; without formal training results poor (e.g.
# "Missing expectations" windlass study). Trained/CoTCCC much higher.
const TOURNIQUET_SUCCESS_BASE_CHANCE: float = 0.85  # base success; medical skill scales this
# When applied successfully, bleeding reduction scales with application effectiveness (skill/tightness/placement).
# Perfect application can achieve near-complete occlusion; poor application leaves significant flow. residual_rate =
# raw_rate * (1 - effectiveness * this).
# at 1.0 effectiveness -> 99% reduction; 0.5 effectiveness -> 49.5% (partial occlusion)
const TOURNIQUET_REDUCTION_AT_FULL: float = 0.99
# Partial bleed reduction on failed tourniquet: a failed TQ still partially occludes the vessel (realistic  -  tension
# was applied, just not sufficient for full hemostasis).
# failed TQ still reduces bleeding by ~30% of effectiveness * reduction_at_full
const TOURNIQUET_FAILED_REDUCTION_MULT: float = 0.30
# Escalating retry chance: +15% base success per prior failure on same part (models medic adjusting
# placement/tightness).
const TOURNIQUET_RETRY_SUCCESS_BONUS: float = 0.15  # escalating retry bonus per prior failure

# --- Wound infection (campaign) ---
# Untreated wounds accumulate infection risk over days. A clean dressing (bandage/pack) or a tourniquet
# (definitive hemostasis) greatly reduces the risk. Progression is a per-day dose:
#   infection_progress += (seconds / SECONDS_PER_DAY) * daily_risk;  infected when progress >= 1.0.
# It only advances inside _process_healing (day-scale time), never during a battle, so it is campaign-only.
# An infected wound heals at WOUND_INFECTION_HEAL_SPEED_MULT; a successful definitive dressing clears it.
const WOUND_INFECTION_SEVERITY_RISK: Dictionary = {
    SEVERITY_MINOR: 0.08,      # ~12 days untreated to infect
    SEVERITY_MODERATE: 0.15,   # ~6-7 days
    SEVERITY_SEVERE: 0.30,     # ~3 days
    SEVERITY_CRITICAL: 0.50,   # ~2 days
}
## Compound fractures carry a high infection rate (~40% Gandhi 2002) — double the base risk.
const WOUND_INFECTION_COMPOUND_FRACTURE_MULT: float = 2.0
## Open high-flow arterial wounds are more contaminated — 1.5x the base risk.
const WOUND_INFECTION_ARTERIAL_MULT: float = 1.5
## A part with definitive hemostasis (bandaged/packed/tourniqueted) is a clean, isolated wound — 15% risk.
const WOUND_INFECTION_TREATED_MULT: float = 0.15
## Infected wounds heal at this fraction of normal speed (systemic response + tissue damage).
const WOUND_INFECTION_HEAL_SPEED_MULT: float = 0.5
## Infected (stage >= 1) wounds bleed at this multiplier of the base rate — inflamed tissue is
## hyperemic (increased blood flow) and more friable, so it bleeds more readily than clean tissue.
## Applies per-injury in get_bleeding_rate_for_part, independent of hemostasis status.
const WOUND_INFECTION_BLEED_MULT: float = 1.15

# --- Staged infection / sepsis (CAMP-INF-1) ---
# Stage 0 = clean, 1 = localized (what is_infected represents today), 2 = septic.
# Entity-level: is_septic / sepsis_resolve_progress / _sepsis_dead (CoreEntity).

## Per-day accrual for localized→septic progression on an untreated stage-1 wound.
## 0.40/day ≈ 2.5 days untreated (SIRS→sepsis 24-72 h, wound_infection_data.md §2).
const SEPSIS_LOCALIZED_TO_SEPTIC_PER_DAY: float = 0.40
## Per-day death roll while septic and NOT source-controlled (pre-antibiotic 70-90%).
const SEPSIS_DEATH_RISK_PER_DAY: float = 0.35
## Per-day death roll while septic AND source-controlled (bacterial load reduced).
const SEPSIS_DEATH_RISK_SOURCE_CONTROLLED: float = 0.12
## Stamina cap multiplier for a septic member (systemic catabolism + CIP/CIM).
const SEPSIS_STAMINA_MULT: float = 0.70
## Heal-speed multiplier for a septic part (worse than stage-1 infected).
const SEPSIS_HEAL_SPEED_MULT: float = 0.25
## Additional track-(a) resolution duration multiplier for septic tissue (stacks on stage-1 extension).
const SEPSIS_HEAL_DURATION_MULT: float = 1.50
## Per-day sepsis resolve accrual while source-controlled; at 1.0 → is_septic = false.
const SEPSIS_RESOLVE_PER_DAY_TREATED: float = 0.25
## Sepsis confusion (playable systemic tell).
const SEPSIS_COMBAT_PERCEPTION_MULT: float = 0.80
## Sepsis tachycardia/shock: higher stamina drain per action while septic.
const SEPSIS_COMBAT_STAMINA_DRAIN_MULT: float = 1.30
## Stage-1 localized infection pain multiplier (cellulitis: warmth, swelling, pain).
const INFECTION_LOCALIZED_PAIN_MULT: float = 1.10

## Track-(a) resolution duration extension at stage-0→1 flip (one-way; recompute on clear).
const INFECTION_HEAL_DURATION_MULT: float = 1.75

## Susceptibility multipliers (multiply the per-day infection dose, capped by INFECTION_DAILY_DOSE_CAP).
const INFECTION_RISK_STARVATION_MULT: float = 1.5  # lerp 1.0 (well-fed) → 1.5 (starving) on nutrition_level
const INFECTION_RISK_FATIGUE_MAX_MULT: float = 1.25  # lerp 1.0 → 1.25 on campaign_fatigue
const INFECTION_RISK_CONCUSSION_MULT: float = 1.2  # applied while acute concussion phase active
const INFECTION_DAILY_DOSE_CAP: float = 0.90  # after all multipliers; worst-case needs ~2 days to infect

## Contamination (dirty/debrised/foreign-body) — auto-flagged by penetration depth.
const WOUND_INFECTION_CONTAMINATED_MULT: float = 1.75
const CONTAMINATION_PENETRATION_MM: float = 5.0  # = PENETRATION_DEPTH_SEVERITY_FULL_MM

## Golden-period realism: wound-infection risk is front-loaded in a wound's life — highest while the
## wound is freshly open (first ~24-72h of clinical onset) and decaying as the wound begins to close.
## The per-day infection dose is scaled by infection_freshness_factor(wound_age_days): 1.0 when fresh,
## lerp'ing down to WOUND_INFECTION_FRESHNESS_FLOOR once the wound has aged INFECTION_FRESH_WINDOW_DAYS.
## A fresh wound (age 0) is unaffected, so the calibrated per-day base rates and the "starving member
## infects faster" criterion are preserved; only an aging (closing) wound's residual risk is trimmed.
const INFECTION_FRESH_WINDOW_DAYS: float = 5.0
const WOUND_INFECTION_FRESHNESS_FLOOR: float = 0.5


static func infection_freshness_factor(age_days: float) -> float:
    return lerpf(1.0, WOUND_INFECTION_FRESHNESS_FLOOR, clampf(age_days / INFECTION_FRESH_WINDOW_DAYS, 0.0, 1.0))


## Gas gangrene (Phase A+; gated on is_gas_gangrene wound flag, armed at the stage-1->2 flip).
const GAS_GANGRENE_PROGRESS_MULT: float = 2.0
const GAS_GANGRENE_DEATH_RISK_PER_DAY: float = 0.50
const GAS_GANGRENE_CANDIDATE_BASE_RISK: float = 0.50
## Cut/stab wounds deeper than this (mm) are deep/penetrating enough to host clostridial growth.
const GAS_GANGRENE_DEEP_PENETRATION_MM: float = 5.0  # = PENETRATION_DEPTH_SEVERITY_FULL_MM

## Tetanus (Phase A+): delayed spore-borne hazard (plan §10.2). A contaminated deep cut/stab
## seeds a single entity-level spore load; the wound can heal before the member manifests.
const TETANUS_INCUBATION_MIN_DAYS: float = 3.0
const TETANUS_INCUBATION_MAX_DAYS: float = 21.0
const TETANUS_ONSET_RISK: float = 0.30
const TETANUS_SYMPTOMATIC_DAYS: float = 7.0
const TETANUS_DEATH_RISK_PER_DAY: float = 0.12
const TETANUS_PERCEPTION_MULT: float = 0.85
## A contaminated wound that is cleanly dressed / debrided (definitive hemostasis) at the moment the
## spore load is seeded has roughly half the onset probability — debridement removes spores before
## they germinate (plan §10.2 counter-play). Multiplies TETANUS_ONSET_RISK when tetanus_cleaned_at_arm.
const TETANUS_ONSET_RISK_TREATED_MULT: float = 0.50
## Draw a fresh tetanus incubation period (days) in [MIN, MAX] using the global RNG (the same
## source as the rest of the day-scale code). Called once per seeded spore load.
static func tetanus_arm_days() -> float:
    return lerp(TETANUS_INCUBATION_MIN_DAYS, TETANUS_INCUBATION_MAX_DAYS, randf())

## Osteomyelitis (Phase A+): chronic bone infection from an infected compound fracture.
## While the flag is present the part's bone-heal rate is multiplied by this (halves closure).
const OSTEOMYELITIS_BONE_HEAL_MULT: float = 0.50
## A sequestered bone nidus is not cleared by surface dressing: an osteomyelitic, source-controlled
## wound keeps a small festering daily dose (driving toward systemic) instead of fully stalling.
## ~25% of SEPSIS_LOCALIZED_TO_SEPTIC_PER_DAY — chronic, not acute.
const OSTEOMYELITIS_RESIDUAL_DAILY_DOSE: float = 0.10

## Stage-1 dressing clear probability (base; INT-scaled upward, repeatable per day).
const INFECTION_DRESSING_CLEAR_STAGE1: float = 0.40

# --- Wound-derived scars (CAMP-SCAR-1) ---
## A wound landing on an already-scarred part starts one severity band higher / +15% severity score.
## Read in EntityWounds.severity_from_damage to make the stored `part` matter on re-injury.
const SCAR_REINJURY_MULT: float = 1.15
## A second severe wound on an already-scarred part deepens the existing scar instead of no-op-ing:
## the existing damage_mult is multiplied by this on the id+part merge.
const SCAR_DEEPEN_MULT: float = 1.05
## Scarred tissue holds ~70-80% of normal tensile strength and shears more readily, so a part
## carrying a wound-derived scar severs more easily than healthy tissue. Added to the severance
## ease factor in EntityDamage.get_severance_ease_factor (capped at SEVERANCE_EASE_MAX there).
## Same research anchor as SCAR_REINJURY_MULT (Wikipedia:Scar — mechanical stress / lost elasticity).
const SCAR_SEVERANCE_EASE_BONUS: float = 0.10

# --- Wound escalation & hemostasis tuning (CAMP-INF-1 / Phase A+) ---
## Two or more fractures in the same limb escalate each to a compound fracture (exposed bone).
const COMPOUND_FRACTURE_THRESHOLD: int = 2
## Compound fractures bleed 2.5x the base rate — exposed bone, torn periosteum.
const COMPOUND_FRACTURE_BLEED_MULT: float = 2.5
## Compound fractures lower the pain-shock threshold by 30% (exposed bone is more sensitive).
const COMPOUND_FRACTURE_PAIN_THRESHOLD_MULT: float = 0.7
## Stump bleeding anatomical variance: ±8% around baseline (conservative vs clinical 15–20%).
const STUMP_BLEED_VARIATION_MIN: float = 0.92
const STUMP_BLEED_VARIATION_SPAN: float = 0.16
## Active combat/exertion impairs clotting (movement, adrenaline, trauma reopen clots).
const EXERTION_CLOTTING_MULT: float = 0.6
## Active combat increases blood loss rate (heart rate, wound reopening from movement).
const EXERTION_BLOOD_LOSS_MULT: float = 1.5
## Pain shock (sympathetic surge) impairs coagulation beyond exertion alone.
const PAIN_SHOCK_CLOTTING_MULT: float = 0.75
## Endurance modifier on clotting: END/divisor lerp'd into [min, max] (higher END -> faster clotting).
const ENDURANCE_CLOTTING_MIN: float = 0.9
const ENDURANCE_CLOTTING_MAX: float = 1.1
const ENDURANCE_CLOTTING_DIVISOR: float = 1000.0
## Below the decompensation threshold, endogenous blood recovery is suppressed to ~5% (near-zero).
const DECOMPENSATED_RECOVERY_SUPPRESSION: float = 0.05
## Part intervention threat score weights (triage ordering).
const THREAT_BLEED_RATE_WEIGHT: float = 3.5
const THREAT_ARTERIAL_BONUS: float = 2.25
const THREAT_STUMP_BONUS: float = 4.5
const THREAT_SEVERITY_CRITICAL_BONUS: float = 1.6
const THREAT_SEVERITY_SEVERE_BONUS: float = 0.85
const THREAT_TOURNIQUET_BONUS: float = 1.15


## True when a wound is auto-contaminated by depth (cut/stab penetrating to the "full" band).
## A traumatic amputation stump is a raw, devitalized, open wound (unknown depth) and is always
## treated as contaminated: it seeds the tetanus spore load (plan §10.2) and takes the full
## WOUND_INFECTION_CONTAMINATED_MULT infection-dose boost — the historical stump-infection risk.
static func is_wound_contaminated(injury: Dictionary) -> bool:
    if bool(injury.get("is_stump", false)):
        return true
    # Debridement (plan §10.2 counter-play): a wound cleaned of devitalized tissue + debris by a
    # successful dressing is no longer contaminated — the depth-qualified contamination is removed,
    # so the WOUND_INFECTION_CONTAMINATED_MULT dose boost stops. A stump is excluded above (a raw
    # amputation surface stays the historical infection/tetanus risk even once cleaned).
    if bool(injury.get("debrided", false)):
        return false
    var itype: String = str(injury.get("injury_type", ""))
    if itype != INJURY_TYPE_CUT and itype != INJURY_TYPE_STAB:
        return false
    var pen: float = float(injury.get("penetration_to_tissue_mm", -1.0))
    return pen >= CONTAMINATION_PENETRATION_MM


## True when a wound has an open entry portal that can seed infection. Sepsis needs a tract: a closed
## contusion (bruise) and a clean (non-compound) fracture have no portal for colonization — the tissue
## is intact or the damage is internally contained — so their per-day infection dose must be zero.
## compound_fracture is open (exposed bone); cut/stab/crush breach tissue; internal_bleed keeps the
## pass-4 boundary. This mirrors the open-wound gate the scar mint uses (CAMP-SCAR-1 §2.3): a closed
## injury neither gets infected nor remodels into scar tissue. Legacy descriptors ("" — pre-stash-era
## saves) keep the old dose rule.
static func injury_has_open_entry(injury: Dictionary) -> bool:
    if bool(injury.get("is_stump", false)):
        return true
    if bool(injury.get("is_compound_fracture", false)):
        return true
    var itype: String = str(injury.get("injury_type", ""))
    return itype.is_empty() or (itype != INJURY_TYPE_BRUISE and itype != INJURY_TYPE_FRACTURE)


## Combined susceptibility multiplier (starvation × fatigue × concussion).
## entity must have: nutrition_level, campaign_fatigue; concussion via EntityPainConsciousness.
static func infection_susceptibility_mult(entity: Node) -> float:
    var mult: float = 1.0
    # Starvation: lerp 1.5 (starving) -> 1.0 (well-fed). nutrition_level is a CoreEntity property (default 1.0).
    var nutrition: float = 1.0
    if "nutrition_level" in entity:
        nutrition = clampf(float(entity.get("nutrition_level")), 0.0, 1.0)
    mult *= lerp(INFECTION_RISK_STARVATION_MULT, 1.0, nutrition)
    # Fatigue: lerp 1.0 -> 1.25. campaign_fatigue is a CoreEntity property (default 0.0).
    var fatigue: float = 0.0
    if "campaign_fatigue" in entity:
        fatigue = clampf(float(entity.get("campaign_fatigue")), 0.0, 1.0)
    mult *= lerp(1.0, INFECTION_RISK_FATIGUE_MAX_MULT, fatigue)
    # Concussion: acute phase (critical or acute)
    var conc_info: Dictionary = EntityPainConsciousness.get_concussion_phase_info(entity)
    var phase: int = int(conc_info.get("phase", 0))
    if phase == PainConsciousnessConstants.CONCUSSION_PHASE_CRITICAL or phase == PainConsciousnessConstants.CONCUSSION_PHASE_ACUTE:
        mult *= INFECTION_RISK_CONCUSSION_MULT
    return mult


## Full per-day infection dose for one wound (base × contamination × susceptibility), capped.
## Replaces the direct `per_day * risk` pattern in EntityHealing when staging is enabled.
static func wound_infection_daily_dose(entity: Node, injury: Dictionary, treated: bool) -> float:
    var base: float = wound_infection_daily_risk(injury, treated)
    if is_wound_contaminated(injury):
        base *= WOUND_INFECTION_CONTAMINATED_MULT
    base *= infection_susceptibility_mult(entity)
    return minf(base, INFECTION_DAILY_DOSE_CAP)


## True when a stage-1 (localized) wound is a gas-gangrene candidate (clostridial myonecrosis: anaerobic,
## deep / devitalized / low-perfusion tissue). Crush and compound-fracture wounds are prime substrates
## (devitalized muscle / exposed bone); a raw amputation stump qualifies outright (devitalized + open,
## the historical leading cause of amputation mortality); deep penetrating cut/stab wounds qualify by
## depth; a part currently under a tourniquet (low perfusion) also qualifies. (plan §10.1)
static func is_gangrene_candidate(entity: Node, part: String, injury: Dictionary) -> bool:
    var itype: String = str(injury.get("injury_type", ""))
    if itype == INJURY_TYPE_CRUSH or itype == INJURY_TYPE_COMPOUND_FRACTURE:
        return true
    # A raw amputation stump is devitalized, crushed, open tissue — a prime clostridial substrate even
    # though its depth is unknown. Historically the leading cause of amputation mortality (plan §10.1).
    if bool(injury.get("is_stump", false)):
        return true
    if itype == INJURY_TYPE_CUT or itype == INJURY_TYPE_STAB:
        var pen: float = float(injury.get("penetration_to_tissue_mm", -1.0))
        if pen >= GAS_GANGRENE_DEEP_PENETRATION_MM:
            return true
    if entity != null and entity.tourniquet_applied.has(part):
        return true
    return false


## Per-stage-2 gas-gangrene arming roll: base risk scaled up by severity (worse wounds gangrene more).
## Never a certainty — returns a probability in (0, 1]. (plan §10.1: "a roll scaled by severity, not a certainty")
static func gangrene_candidate_roll(injury: Dictionary) -> float:
    var sev: String = str(injury.get(DataKeys.INJURY_SEVERITY, SEVERITY_MODERATE))
    var scale: float
    match sev:
        SEVERITY_MINOR:
            scale = 0.5
        SEVERITY_MODERATE:
            scale = 0.75
        SEVERITY_SEVERE:
            scale = 1.0
        SEVERITY_CRITICAL:
            scale = 1.25
        _:
            scale = 0.75
    return clampf(GAS_GANGRENE_CANDIDATE_BASE_RISK * scale, 0.0, 1.0)


# --- Active bleeding slows tissue/bone repair ---
## Hemorrhage diverts repair resources and impairs local perfusion (hypovolemia): the faster a part bleeds,
## the slower its tissue/bone repair. 1.0 at no bleed -> BLEED_HEAL_SLOW_FLOOR at/above the reference rate.
## Reference = TOURNIQUET_BLEEDING_RATE_THRESHOLD (a severe bleed) so the factor is a no-op for trivial oozing.
const BLEED_HEAL_SLOW_REF_RATE: float = 2.0
const BLEED_HEAL_SLOW_FLOOR: float = 0.5
## An open, untreated arterial wound cannot close while systolic pressure drives flow through it: repair
## stalls (0.0) until definitive hemostasis (tourniquet/pack/clot), after which it resumes.
const ARTERIAL_UNTREATED_HEAL_STALL_MULT: float = 0.0


## Per-part healing-speed factor from active bleeding. 1.0 when the part is not bleeding; a hard stall
## (0.0) for an open untreated arterial wound; otherwise lerp 1.0 -> BLEED_HEAL_SLOW_FLOOR as the bleed rate
## rises to BLEED_HEAL_SLOW_REF_RATE.
static func bleed_healing_speed_mult(part_bleed_rate: float, untreated_arterial: bool) -> float:
    if part_bleed_rate <= BLEEDING_RATE_EPSILON:
        return 1.0
    if untreated_arterial:
        return ARTERIAL_UNTREATED_HEAL_STALL_MULT
    var t: float = clampf(part_bleed_rate / BLEED_HEAL_SLOW_REF_RATE, 0.0, 1.0)
    return lerpf(1.0, BLEED_HEAL_SLOW_FLOOR, t)


## Per-day infection risk dose for one wound. Treated parts (definitive hemostasis) get a greatly reduced
## risk; compound fractures and arterial wounds are more infection-prone.
static func wound_infection_daily_risk(injury: Dictionary, treated: bool) -> float:
    var sev: String = str(injury.get(DataKeys.INJURY_SEVERITY, SEVERITY_MODERATE))
    var risk: float = float(WOUND_INFECTION_SEVERITY_RISK.get(sev, WOUND_INFECTION_SEVERITY_RISK[SEVERITY_MODERATE]))
    if injury.get("is_compound_fracture", false):
        risk *= WOUND_INFECTION_COMPOUND_FRACTURE_MULT
    if injury.get("is_arterial", false):
        risk *= WOUND_INFECTION_ARTERIAL_MULT
    if treated:
        risk *= WOUND_INFECTION_TREATED_MULT
    return risk


# --- Severity thresholds (damage as fraction of part max) ---
const SEVERITY_PERCENTAGE_CRITICAL: float = 0.75
const SEVERITY_PERCENTAGE_SEVERE: float = 0.5
const SEVERITY_PERCENTAGE_MODERATE: float = 0.25
# Absolute tissue damage (game units)  -  S4: decouple label from % body_max (prep for derived capacities).
const FEATURE_ABSOLUTE_SEVERITY_BANDS: bool = true
## When true with absolute bands: severity cannot exceed %→'based label (ceil on fragile small parts).
const FEATURE_ABSOLUTE_SEVERITY_PCT_CAP: bool = false
const SEVERITY_ABSOLUTE_CRITICAL: float = 10.0
const SEVERITY_ABSOLUTE_SEVERE: float = 5.0
const SEVERITY_ABSOLUTE_MODERATE: float = 2.0
const SEVERITY_ABSOLUTE_BONE_CRITICAL: float = 8.0
const SEVERITY_ABSOLUTE_BONE_SEVERE: float = 3.0
const SEVERITY_ABSOLUTE_BONE_MODERATE: float = 1.0

## Calibration anchor for the blood-loss multiplier derivation — "clean" critical bleed (critical × head × arterial)
## WITHOUT the ×1.4 vessel-damage amplifier applied by get_bleeding_rate(). The live worst-case bleed rate
## (critical arterial cut, head, no treatment) is 1.4× higher (33.075) → TTD ~128 s (within clinical
## 120–300 s band). This anchor is used by the multiplier derivation to target ~180 s for the reference
## product; the live worst-case lands at the fast end of the band, realistic for a major arterial bleed.
## See docs/LIVE_PATHS.md#bleeding-physics.
const REFERENCE_UNCONTROLLED_BLEED_RATE: float = (
    BLEEDING_RATES[INJURY_TYPE_CUT][SEVERITY_CRITICAL]
    * BODY_PART_BLEEDING_MULTIPLIERS[BodyPartConstants.PART_HEAD]
    * BLEEDING_TYPE_RATE_MULT[BLEEDING_TYPE_ARTERIAL]
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
    var t: float = (penetration_to_tissue_mm - PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return lerpf(PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT, PENETRATION_DEPTH_ARTERIAL_DEEP_MULT, clampf(t, 0.0, 1.0))


## Internal-organ bleed chance for a torso thrust, scaled by penetration depth (game mm).
## A shallow thrust (pen < MIN) can't reach the organ plane; a deep thrust (pen >= FULL) reaches it at
## full chance. Reuses the same depth bands as the severity/arterial models so all three agree on what
## "deep enough to matter" means. Returns 0.0 when penetration is unknown (< 0) or too shallow.
static func internal_bleed_chance_torso_thrust(penetration_to_tissue_mm: float) -> float:
    if penetration_to_tissue_mm < PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return 0.0
    if penetration_to_tissue_mm >= PENETRATION_DEPTH_SEVERITY_FULL_MM:
        return INTERNAL_BLEED_CHANCE_TORSO_THRUST
    var span: float = PENETRATION_DEPTH_SEVERITY_FULL_MM - PENETRATION_DEPTH_SEVERITY_MIN_MM
    var t: float = (penetration_to_tissue_mm - PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return INTERNAL_BLEED_CHANCE_TORSO_THRUST * clampf(t, 0.0, 1.0)


## Severity of an internal-organ bleed, scaled by penetration depth (game mm). A shallow thrust that just
## reaches the organ plane nicks it lightly (moderate); a deep thrust that pierces through nicks it hard
## (severe). Mirrors internal_bleed_chance_torso_thrust's depth bands. Capped at SEVERE — a nicked organ
## oozes, it is not a severed artery, so it never reaches the CRITICAL arterial decomp band.
static func internal_bleed_severity_for_penetration(penetration_to_tissue_mm: float) -> String:
    if penetration_to_tissue_mm < PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return SEVERITY_MODERATE
    var span: float = PENETRATION_DEPTH_SEVERITY_FULL_MM - PENETRATION_DEPTH_SEVERITY_MIN_MM
    var t: float = (penetration_to_tissue_mm - PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return SEVERITY_SEVERE if t >= 0.5 else SEVERITY_MODERATE


## Chance of intracranial hemorrhage given skull damage (to_bone) from a head strike.
## Scales linearly with skull damage: a minor chip (to_bone 1) bleeds at ~13% of max chance;
## a full fracture (to_bone >= FULL_DMG) bleeds at max. No breach (to_bone <= 0) -> no bleed.
static func internal_bleed_chance_head_skull_damage(skull_damage: float) -> float:
    if skull_damage <= 0.0:
        return 0.0
    var t: float = clampf(skull_damage / HEAD_INTRACRANIAL_BLEED_FULL_DMG, 0.0, 1.0)
    return HEAD_INTRACRANIAL_BLEED_MAX_CHANCE * t


## Severity of an intracranial bleed from a head skull breach. A sharp wound that penetrates past
## the skull (deep) or a heavy skull fracture -> SEVERE (subdural hematoma); a light breach ->
## MODERATE (oozing meningeal vessels). Capped at SEVERE — intracranial bleeding is slow/progressive,
## not a CRITICAL arterial exsanguination.
static func internal_bleed_severity_head_skull_damage(
    skull_damage: float, penetration_to_tissue_mm: float = -1.0
) -> String:
    if penetration_to_tissue_mm >= HEAD_SKULL_BREACH_PEN_MM:
        return SEVERITY_SEVERE
    return SEVERITY_SEVERE if skull_damage >= HEAD_INTRACRANIAL_BLEED_FULL_DMG else SEVERITY_MODERATE


## ATLS hemorrhage class 1 - 4 from remaining blood volume % (ATLS 10th ed. loss bands).
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
    # Piecewise within ATLS classes (mild Class II -> marked Class IV toward death threshold).
    # Class IV (60%->floor) drops steeply to the floor so deep blood loss alone produces unconsciousness.
    if remaining_pct >= ATLS_CLASS_II_MIN_REMAINING:
        return lerpf(
            ATLS_CONSC_CLASS_II_FLOOR,
            ATLS_CONSC_CLASS_I_TOP,
            (remaining_pct - ATLS_CLASS_II_MIN_REMAINING) / (ATLS_CLASS_I_MIN_REMAINING - ATLS_CLASS_II_MIN_REMAINING)
        )
    if remaining_pct >= ATLS_CLASS_III_MIN_REMAINING:
        return lerpf(
            ATLS_CONSC_CLASS_III_FLOOR,
            ATLS_CONSC_CLASS_II_FLOOR,
            (
                (remaining_pct - ATLS_CLASS_III_MIN_REMAINING)
                / (ATLS_CLASS_II_MIN_REMAINING - ATLS_CLASS_III_MIN_REMAINING)
            )
        )
    return lerpf(
        maxf(0.0, 1.0 - linear_reduction_max),
        ATLS_CONSC_CLASS_III_FLOOR,
        (remaining_pct - linear_floor) / (ATLS_CLASS_III_MIN_REMAINING - linear_floor)
    )


## Shift effective remaining % by bleeding rate (downward) and endurance (upward), before
## feeding into the ATLS stepped consciousness curve. Reference conditions (rate=0, endurance=100)
## return the input unchanged. Rate is in %/s (use blood_volume_loss_per_second).
static func adjusted_remaining_for_consciousness(
    remaining_pct: float,
    bleeding_rate_pct_per_s: float,
    endurance: float
) -> float:
    var rate_shift: float = minf(
        (bleeding_rate_pct_per_s / BLOOD_CONSC_RATE_REF_PCT_PER_S) * BLOOD_CONSC_RATE_SHIFT_MAX,
        BLOOD_CONSC_RATE_SHIFT_MAX
    )
    var end_shift: float = clampf(
        (endurance - BLOOD_CONSC_END_REF) * BLOOD_CONSC_END_SHIFT_PER_POINT,
        -BLOOD_CONSC_END_SHIFT_MAX,
        BLOOD_CONSC_END_SHIFT_MAX
    )
    return clampf(remaining_pct - rate_shift + end_shift, 0.0, 100.0)


## Blood volume % lost per second from summed wound bleed rates (game units).
static func blood_volume_loss_per_second(total_bleeding_rate: float, loss_mult: float = 1.0) -> float:
    return total_bleeding_rate * BLOOD_LOSS_RATE_MULTIPLIER * maxf(loss_mult, 0.0)


## Seconds until `blood_volume` reaches a given death threshold at constant bleed (no clotting, no treatment).
static func seconds_to_exsanguination_at_death_threshold(
    total_bleeding_rate: float, blood_volume: float, death_threshold: float, loss_mult: float = 1.0
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
    total_bleeding_rate: float, blood_volume: float = MAX_BLOOD_VOLUME, loss_mult: float = 1.0
) -> float:
    return seconds_to_exsanguination_at_death_threshold(
        total_bleeding_rate, blood_volume, BLOOD_LOSS_DEATH_THRESHOLD, loss_mult
    )


static func get_bleeding_rate(injury_type: String, severity: String, part: String, sub_region: String = "") -> float:
    var type_rates: Dictionary = BLEEDING_RATES.get(injury_type, {})
    var base_rate: float = type_rates.get(severity, 0.0)
    # Critical wounds bleed disproportionately faster due to vessel damage and wound cavity formation
    if severity == SEVERITY_CRITICAL:
        base_rate *= 1.4
    elif severity == SEVERITY_SEVERE:
        base_rate *= 1.15
    var mult: float = BODY_PART_BLEEDING_MULTIPLIERS.get(part, 1.0)
    if not sub_region.is_empty():
        mult *= SUB_REGION_BLEEDING_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
    # Cap combined body part × sub-region multiplier to prevent extreme stacking (e.g., head+neck=2.4x vs clinical ~1.5-2.0x).
    mult = clampf(mult, 0.0, MAX_BODY_PART_SUBREGION_BLEED_MULT)
    return base_rate * mult


# Stump (amputation site) bleeding: part + sub_region (level) accurate. Sub_region = where the cut occurred (proximal vs
# distal).
# If sub_region empty, uses 1.0 for level multiplier. Caller should pass get_random_sub_region(part) when level unknown.
static func get_stump_bleeding_rate(part: String, sub_region: String = "") -> float:
    var base: float = get_bleeding_rate(INJURY_TYPE_CUT, SEVERITY_CRITICAL, part, sub_region)
    var level_mult: float = 1.0
    if not sub_region.is_empty():
        level_mult = STUMP_LEVEL_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
    return base * level_mult



## Fraction of wound bleed rate still lost while direct pressure is held (per injury).
static func direct_pressure_held_flow_retained(is_arterial: bool) -> float:
    if is_arterial:
        return DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL
    return DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS


# Pick a random sub-region given the body part was hit. Uses SUB_REGION_WEIGHTS[part] so probabilities are relative to
# that part only. Returns empty string if part has no sub-regions.
static func get_random_sub_region(part: String) -> String:
    var subs: Array = SUB_REGIONS.get(part, [])
    var weights: Dictionary = SUB_REGION_WEIGHTS.get(part, {})
    if subs.is_empty() or weights.is_empty():
        return ""
    for sub in subs:
        if not weights.has(sub):
            weights[sub] = 1.0
    return WeightedSample.pick_random(weights)


# Effective damage multiplier for severity mapping (thin tissue / exposed bone = higher effective depth).
static func get_severity_modifier(part: String, sub_region: String) -> float:
    if sub_region.is_empty():
        return 1.0
    return SUB_REGION_SEVERITY_MODIFIERS.get(part, {}).get(sub_region, 1.0)


# Per-severity clotting rate (k per second). Use when not stabilized; arterial applies BLEEDING_TYPE_CLOTTING_MULT[BLEEDING_TYPE_ARTERIAL] on
# top.
static func get_clotting_rate(severity: String) -> float:
    return CLOTTING_RATE_BY_SEVERITY.get(severity, 0.02)  # 0.02 = moderate default


# Multiplier on clotting rate by severity (minor faster, severe/critical slower). Apply in process_bleeding: clotting *=
# get_clotting_multiplier(sev).
static func get_clotting_multiplier(severity: String) -> float:
    return CLOTTING_SEVERITY_MULTIPLIERS.get(severity, 1.0)


## True when a wound type cannot be clotted by external means (pressure/bandage). Internal-organ bleeds
## sit inside the body, so the clotting path holds their rate constant instead of decaying it.
static func is_unclottable(injury_type: String) -> bool:
    return injury_type == INJURY_TYPE_INTERNAL_BLEED


# Chance (0.0-1.0) that a wound is arterial based on severity, injury type (cut vs crush), body part, and sub-region.
# Research-based. Crush uses ARTERIAL_CRUSH_MULTIPLIER × SUB_REGION_BLUNT_ARTERIAL_MODIFIER for region-specific cut
# vs blunt differentiation.
static func get_arterial_chance(
    severity: String, injury_type: String, part: String, sub_region: String = "", penetration_to_tissue_mm: float = -1.0
) -> float:
    # Internal-organ bleeds are a slow constant ooze, not an arterial event — no arterial chance/multiplier.
    if injury_type == INJURY_TYPE_INTERNAL_BLEED:
        return 0.0
    var base_chance: float = ARTERIAL_CHANCE_BY_SEVERITY.get(severity, 0.06)
    if injury_type == INJURY_TYPE_CRUSH:
        base_chance *= ARTERIAL_CRUSH_MULTIPLIER
        if not sub_region.is_empty():
            base_chance *= SUB_REGION_BLUNT_ARTERIAL_MODIFIERS.get(part, {}).get(sub_region, 1.0)
    elif injury_type == INJURY_TYPE_CUT and penetration_to_tissue_mm >= 0.0:
        base_chance *= penetration_depth_arterial_mult(penetration_to_tissue_mm)
    var part_mult: float = ARTERIAL_BODY_PART_MULTIPLIERS.get(part, 1.0)
    if not sub_region.is_empty():
        var sr_mult: float = SUB_REGION_ARTERIAL_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
        # Use max of part/sub-region rather than multiply to avoid over-counting vascular chance (e.g., neck critical at ~55% vs lit ~25%).
        part_mult = maxf(part_mult, sr_mult)
    return clampf(base_chance * part_mult, 0.0, 1.0)



## Vital zone damage multiplier - strikes to critical anatomical targets (vital organs, major vessels, brain) deal
## amplified mechanical damage beyond what tissue depth alone captures. Models clinical reality where a throat cut or
## sternum strike is disproportionately lethal vs equivalent damage to forearm/thigh. Returns 1.0 for non-vital zones.
static func get_vital_damage_multiplier(part: String, sub_region: String = "", attack_line: String = "") -> float:
    var base_mult: float = VITAL_DAMAGE_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
    ## Groin targeting: when a low-line strike hits the upper thigh (femoral artery proximity), apply additional multiplier.
    if part == BodyPartConstants.PART_RIGHT_LEG or part == BodyPartConstants.PART_LEFT_LEG:
        var is_low_line: bool = attack_line.to_lower().begins_with("low")
        if sub_region == "thigh" and is_low_line:
            base_mult *= VITAL_GROIN_MULTIPLIER
    return base_mult
