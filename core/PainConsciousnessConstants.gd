class_name PainConsciousnessConstants
extends RefCounted

## Pain scale multipliers by body part and sub-region; consciousness thresholds.

# Pain and consciousness (Combat Extended - style), adjusted for fallen-paths action-bar combat.
# Used by CoreEntity and CombatManager for gauge fill, hit chance, and incapacitation.

# --- Pain normalization: Method A (reference-based) vs Method B (normalized) ---
# Method B (canonical): effective_pain = total_pain / pain_reference; per-species scaling; NRS thresholds 4/6/8/10.
# Method A: raw total_pain vs fixed thresholds. Use only if you need global thresholds without species scaling.
const USE_NORMALIZED_PAIN: bool = true  # Method B = canonical implementation

# --- Method A: Reference-based thresholds (when USE_NORMALIZED_PAIN = false) ---
# PAIN_REFERENCE = typical pain from 1 moderate hit. Thresholds = NRS - -  PAIN_PER_NRS. Update when damage scale
# changes.
const PAIN_REFERENCE_MODERATE_HIT: float = 6.0
const PAIN_MODERATE: float = PAIN_REFERENCE_MODERATE_HIT * 2.0  # ~12: ~2 moderate hits
const PAIN_SEVERE: float = PAIN_REFERENCE_MODERATE_HIT * 4.0  # ~24
const PAIN_EXTREME: float = PAIN_REFERENCE_MODERATE_HIT * 6.0  # ~36
const PAIN_INTOLERABLE: float = PAIN_REFERENCE_MODERATE_HIT * 8.0  # ~48
const PAIN_SHOCK_THRESHOLD_RAW: float = PAIN_REFERENCE_MODERATE_HIT * 5.0  # ~30
const PAIN_SHOCK_RISK_PER_POINT_RAW: float = 0.02  # (pain - 30) * 0.02; 10 over = 20% risk

# --- Method B: Normalized thresholds (when USE_NORMALIZED_PAIN = true) ---
# effective_pain = total_pain / get_pain_reference(entity). Fixed NRS-equivalent thresholds.
const NRS_FIRST_EFFECT: float = 4.0  # research: NRS 4 - 5 = first functional impairment
const NRS_MODERATE: float = 6.0
const NRS_SEVERE: float = 8.0
const NRS_INTOLERABLE: float = 10.0
const NRS_SHOCK: float = 7.5
## END slope: how much endurance shifts the pain shock threshold per point above 100.
## Cold pressor test meta-analysis (Smith & Rose 2017, 42 studies): trained athletes show only ~8-12% higher
## pain tolerance vs sedentary — not proportional to END stat. At +50 END: old slope gave +1.0 (14%),
## new slope gives +0.25 (3.6%) which matches the upper bound of clinical athletic adaptation.
const ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT: float = 0.02
const PAIN_SHOCK_RISK_PER_POINT_NORMALIZED: float = 0.25  # (effective - 7) * 0.25; exceeding shock threshold is a significant event
# Ambient (sustained pain) shock: periodic roll in combat when effective pain stays above threshold (no new hit).
const PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S: float = 4.0
const PAIN_SHOCK_AMBIENT_RISK_PER_POINT: float = 0.025
const PAIN_SHOCK_AMBIENT_RISK_MULT: float = 0.35
# Cumulative pain susceptibility (Tier 6.1): scales shock **chance** only; hit pain stays primary (Option C + B).
const PAIN_SHOCK_SUSCEPTIBILITY_MULT_LOW: float = 0.8  # at/below NRS_FIRST_EFFECT
const PAIN_SHOCK_SUSCEPTIBILITY_MULT_HIGH: float = 1.2  # at/above NRS_SEVERE

# --- Pain -> performance modifier (action bar fill, hit chance, wind-up, etc). Research-aligned; pain impairs function.
## Clinical evidence: pain affects cognitive and motor functions differently.
## Cognitive: targeting accuracy, decision-making, reaction time — impaired by attentional capture from nociception.
## Motor: grip strength, swing speed, balance — impaired by reflex inhibition and localized tissue dysfunction.
## Studies (Meeuwisse et al. 1991; Bruhn et al. 2001): moderate pain reduces grip strength ~15-30% but targeting accuracy drops ~25-40%.
## Cognitive effects scale more steeply at lower pain levels because attentional capture is non-linear (any significant pain draws focus).
const PAIN_PERFORMANCE_NONE: float = 0.0
const PAIN_PERFORMANCE_MINOR: float = 0.10  # -10% (NRS 4 - 6: first functional impairment; lit. -10 to -18%)
const PAIN_PERFORMANCE_MODERATE: float = 0.32  # -32% (NRS 6 - 8: moderate impairment; updated from 0.28 per meta-analyses showing -20 to -45% functional loss)
const PAIN_PERFORMANCE_SEVERE: float = 0.50  # -50% (NRS 8 - 10: severe impairment; lit. -40 to -70%)
const PAIN_PERFORMANCE_EXTREME: float = 0.70  # -70% (NRS 10+: extreme impairment; literature ~70%)

# --- Separate cognitive vs motor pain modifiers ---
## Cognitive modifier affects: hit chance, parry timing, decision-making quality, perception-based rolls.
## Motor modifier affects: swing speed/velocity, movement rate, wind-up duration, grip strength for weapon handling.
## Clinical basis: attentional capture (cognitive) occurs at lower pain levels than motor inhibition;
## a fighter with moderate leg pain can still strike fast but aims poorly.
## (Steepness/floor values are inline in get_combined_performance_modifier; clinical basis in RESEARCH_pain_cognition_performance.md.)

# --- Conciousness: direct scale (effective_consciousness / 100 = performance scale). ---
# Incapacitation when true consciousness < this (no longer able to act).
const INCAPACITATION_CONSCIOUSNESS_THRESHOLD: float = 5.0
# Leg functionality below this threshold triggers cowering (both legs destroyed).
# Single-leg destruction returns ~0.35-0.55, above this threshold — fighter can still hobble and fight.
const LEG_COWER_THRESHOLD: float = 0.15
# Leg functionality below this '**' cannot walk for formation retreat (flee / fall_back). Tier 6.1.
const MOBILITY_FLEE_THRESHOLD: float = 0.2

# --- Blood -> consciousness (ATLS-aligned: effect starts at Class II, max at death threshold). ---
# Below START: consciousness modifier ramps down; at FLOOR (death threshold) modifier = 1.0 - REDUCTION_MAX.
# See RESEARCH_pain_cognition_performance.md (blood consciousness ATLS section).
const BLOOD_CONSCIOUSNESS_START_THRESHOLD: float = 85.0  # No effect above this (Class I: <15% lost)
# Max reduction at/below this (align with BLOOD_LOSS_DEATH_THRESHOLD, ~50; floor sits 3% above
# death so the fighter is unconscious well before the agonal window closes).
const BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD: float = 53.0
const BLOOD_CONSCIOUSNESS_REDUCTION_MAX: float = 0.96  # At floor: modifier = 0.04 (Class IV ATLS: obtunded/unresponsive; hypovolemic syncope — blood loss alone drives unconsciousness)
# --- Hypovolemia -> parry reaction time. Cerebral hypoperfusion slows neuromuscular
# response as blood volume drops (ATLS Class I-IV). Ramps from no penalty at the 85%
# threshold to this multiplier at near-total loss. Same 85% threshold + ramp shape as
# the hypovolemic cognitive mod in get_performance_modifier, applied to reaction time.
const HYPOVOLUME_REACTION_TIME_SLOW_MULT: float = 1.35  # At full hypovolemia: ~35% slower parry reaction

# --- Pain shock (temporary; reduces effective consciousness for combat, not incapacitation). ---
# Research: Lighter impacts cause brief grogginess; more severe single impacts cause longer confusion/disorientation
# (Frontiers Neurology 2020, concussion/TBI). Acute stress reaction and traumatic shock duration scale with severity of
# the triggering insult (ATLS, StatPearls). Duration therefore scales with both cumulative pain and the impact of the
# move that triggered the shock.
const PAIN_SHOCK_DURATION_BASE: float = 8.0  # base duration seconds; scaled by pain level and impact
# Clinical: acute stress reaction "daze" lasts minutes; 8s base + impact scaling → 8-30s range
# (compressed for combat pacing but closer to clinical ASR than the old 5s base).
# -50% effective consciousness while in shock (acute stress impairs but does not obliterate function; combined with
# blood loss/head trauma can approach ~70-80% total reduction)
const PAIN_SHOCK_CONSCIOUSNESS_REDUCTION: float = 50.0
## Cooldown between ambient pain shock triggers (prevents repeated re-entry during sustained high pain).
const PAIN_SHOCK_AMBIENT_COOLDOWN_S: float = 15.0
# Impact scaling: larger single hit -> longer shock (mechanoporation / acute stress magnitude). Reference damage for
# 1.0x impact factor; bigger hits multiply duration up to IMPACT_MAX_MULTIPLIER.
# damage of triggering hit vs this (e.g. 10 -> 1.0x, 20 -> 2.0x until cap)
const PAIN_SHOCK_DURATION_IMPACT_REFERENCE: float = 10.0
# max duration multiplier from impact (e.g. 2.5 = 2.5× duration for a heavy blow)
const PAIN_SHOCK_DURATION_IMPACT_MAX_MULTIPLIER: float = 2.5

# --- Performance floor (action bar and hit chance never below this). ---
## Floor at 15% — a severely injured, near-unconscious fighter still moves but cannot fight effectively (~crippled gait).
const MIN_PERFORMANCE_MODIFIER: float = 0.15

# --- Per-injury pain: damage × severity_mult × body_part_mult × injury_type_mult × (1 - healing). ---
## Stevens' power law for pain (ψ = kI^n, n ≈ 0.6-1.0): pain perception is compressive —
## the jump from minor→moderate is proportionally larger than moderate→severe.
## Derived from clinical NRS data: minor (NRS 2-3) ≈ 0.4× moderate (NRS 4-6),
## severe (NRS 7-8) ≈ 1.4× moderate, critical (NRS 9-10) ≈ 1.7× moderate.
const SEVERITY_PAIN_MULTIPLIERS: Dictionary = {"minor": 0.4, "moderate": 1.0, "severe": 1.4, "critical": 1.7}

# --- Body part pain multipliers (cortical representation + clinical pain salience). ---
## Research (RESEARCH_pain_cognition_performance.md §3a): head 1.2-1.5, neck 1.3-1.6, torso 1.4-1.8.
## Torso/chest at upper range — impairs breathing, vital organ proximity, higher nociceptive density.
## Head at research max (1.5) — cortical homunculus representation is large but chest pain is more
## functionally debilitating (respiratory splinting, cardiac referred pain). Sub-region multipliers
## (face/neck/sternum) layer on top for localized pain salience.
const BODY_PART_PAIN_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: 1.5,
    BodyPartConstants.PART_CHEST: 1.6,
    BodyPartConstants.PART_RIGHT_ARM: 1.0,
    BodyPartConstants.PART_LEFT_ARM: 1.0,
    BodyPartConstants.PART_RIGHT_LEG: 0.95,
    BodyPartConstants.PART_LEFT_LEG: 0.95
}

# --- Sub-region pain multipliers (hand, face, neck higher; foot lower). ---
const SUB_REGION_PAIN_MULTIPLIERS: Dictionary = {
    BodyPartConstants.PART_HEAD: {"scalp": 1.3, "face": 1.4, "neck": 1.35},
    BodyPartConstants.PART_CHEST: {"thoracic": 1.2, "abdominal": 1.15, "sternum": 1.6},
    BodyPartConstants.PART_RIGHT_ARM: {"upper_arm": 0.95, "elbow": 1.1, "forearm": 1.05, "hand": 1.35, "armpit": 1.45, "axillary": 1.45},
    BodyPartConstants.PART_LEFT_ARM: {"upper_arm": 0.95, "elbow": 1.1, "forearm": 1.05, "hand": 1.35, "armpit": 1.45, "axillary": 1.45},
    BodyPartConstants.PART_RIGHT_LEG: {"thigh": 0.95, "knee": 1.1, "calf": 1.0, "foot": 0.75, "inner_thigh": 1.3},
    BodyPartConstants.PART_LEFT_LEG: {"thigh": 0.95, "knee": 1.1, "calf": 1.0, "foot": 0.75, "inner_thigh": 1.3}
}

# --- Injury type pain multipliers (fracture/crush often more debilitating than cut). ---
const INJURY_TYPE_PAIN_MULTIPLIERS: Dictionary = {"cut": 1.0, "crush": 1.15, "bruise": 0.7, "fracture": 1.35, "compound_fracture": 2.0}

# --- Stump (amputation site) pain: among the most severe acute pains. ---
const STUMP_PAIN_MULTIPLIER: float = 1.5

# --- Wound depth -> pain: deep penetrating wounds transect more nociceptor-rich tissue (periosteum,
# deep fascia, viscera) -> more pain at equal damage. Reuses the S8 depth bands [1,5] mm. Shallow
# (<=1 mm) is neutral because penetration_depth_severity_mult already discounts shallow cuts. ---
const PAIN_DEPTH_FULL_MULT: float = 1.25


static func get_body_part_pain_multiplier(part: String) -> float:
    return BODY_PART_PAIN_MULTIPLIERS.get(part, 1.0)


static func get_wound_depth_pain_multiplier(penetration_to_tissue_mm: float) -> float:
    if penetration_to_tissue_mm < 0.0:
        return 1.0
    if penetration_to_tissue_mm <= BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return 1.0
    if penetration_to_tissue_mm >= BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM:
        return PAIN_DEPTH_FULL_MULT
    var span: float = (
        BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM
    )
    var t: float = (penetration_to_tissue_mm - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return lerpf(1.0, PAIN_DEPTH_FULL_MULT, clampf(t, 0.0, 1.0))


static func get_sub_region_pain_multiplier(part: String, sub_region: String) -> float:
    if sub_region.is_empty():
        return 1.0
    var subs: Dictionary = SUB_REGION_PAIN_MULTIPLIERS.get(part, {})
    return subs.get(sub_region, 1.0)


static func get_injury_type_pain_multiplier(injury_type: String) -> float:
    return INJURY_TYPE_PAIN_MULTIPLIERS.get(injury_type, 1.0)


static func get_stump_pain_multiplier(is_stump: bool) -> float:
    return STUMP_PAIN_MULTIPLIER if is_stump else 1.0


static func _get_pain_moderate_threshold() -> float:
    return NRS_FIRST_EFFECT if USE_NORMALIZED_PAIN else PAIN_MODERATE


static func _get_pain_severe_threshold() -> float:
    return NRS_MODERATE if USE_NORMALIZED_PAIN else PAIN_SEVERE


static func _get_pain_extreme_threshold() -> float:
    return NRS_SEVERE if USE_NORMALIZED_PAIN else PAIN_EXTREME


static func _get_pain_intolerable_threshold() -> float:
    return NRS_INTOLERABLE if USE_NORMALIZED_PAIN else PAIN_INTOLERABLE


static func get_pain_shock_threshold() -> float:
    return NRS_SHOCK if USE_NORMALIZED_PAIN else PAIN_SHOCK_THRESHOLD_RAW


static func get_pain_shock_risk_per_point() -> float:
    return PAIN_SHOCK_RISK_PER_POINT_NORMALIZED if USE_NORMALIZED_PAIN else PAIN_SHOCK_RISK_PER_POINT_RAW


static func get_pain_shock_susceptibility_mult(effective_pain: float) -> float:
    if effective_pain <= NRS_FIRST_EFFECT:
        return PAIN_SHOCK_SUSCEPTIBILITY_MULT_LOW
    if effective_pain >= NRS_SEVERE:
        return PAIN_SHOCK_SUSCEPTIBILITY_MULT_HIGH
    var span: float = maxf(NRS_SEVERE - NRS_FIRST_EFFECT, 0.001)
    var t: float = clampf((effective_pain - NRS_FIRST_EFFECT) / span, 0.0, 1.0)
    return lerpf(PAIN_SHOCK_SUSCEPTIBILITY_MULT_LOW, PAIN_SHOCK_SUSCEPTIBILITY_MULT_HIGH, t)


static func get_pain_performance_modifier(pain_value: float) -> float:
    """pain_value is either raw total_pain (Method A) or effective_pain (Method B)."""
    var mod_t: float = _get_pain_moderate_threshold()
    var sev_t: float = _get_pain_severe_threshold()
    var ext_t: float = _get_pain_extreme_threshold()
    var int_t: float = _get_pain_intolerable_threshold()
    if pain_value < mod_t:
        return 1.0 - PAIN_PERFORMANCE_NONE
    if pain_value < sev_t:
        return 1.0 - PAIN_PERFORMANCE_MINOR
    if pain_value < ext_t:
        return 1.0 - PAIN_PERFORMANCE_MODERATE
    if pain_value < int_t:
        return 1.0 - PAIN_PERFORMANCE_SEVERE
    return 1.0 - PAIN_PERFORMANCE_EXTREME


static func get_consciousness_performance_modifier(consciousness: float) -> float:
    return clampf(consciousness / 100.0, 0.0, 1.0)


static func get_combined_performance_modifier(total_pain: float, consciousness: float) -> float:
    var pain_mod: float = get_pain_performance_modifier(total_pain)
    var cons_mod: float = get_consciousness_performance_modifier(consciousness)
    return maxf(MIN_PERFORMANCE_MODIFIER, pain_mod * cons_mod)


# Duration (seconds) for pain shock: base * (pain/threshold) * impact_mult. Impact = total damage of the hit that
# triggered the roll; 0 when shock triggered by bleed/healing (no single move).
# pain_value is either raw total_pain (Method A) or effective_pain (Method B).
static func get_pain_shock_duration_seconds(pain_value: float, triggering_hit_damage: float) -> float:
    var thresh: float = get_pain_shock_threshold()
    var pain_ratio: float = pain_value / thresh if thresh > 0.0 else 1.0
    var base_duration: float = PAIN_SHOCK_DURATION_BASE * pain_ratio
    if triggering_hit_damage <= 0.0:
        return base_duration
    var impact_mult: float = (
        1.0
        + minf(
            triggering_hit_damage / PAIN_SHOCK_DURATION_IMPACT_REFERENCE,
            PAIN_SHOCK_DURATION_IMPACT_MAX_MULTIPLIER - 1.0
        )
    )
    return base_duration * impact_mult


# --- Concussion phase identifiers (numeric constants for match/case). ---
const CONCUSSION_PHASE_CRITICAL: int = 1
const CONCUSSION_PHASE_ACUTE: int = 2
const CONCUSSION_PHASE_SUBACUTE: int = 3
const CONCUSSION_PHASE_RECOVERY: int = 4

# --- Phase boundary weights (proportional fractions of total recovery duration). ---
## Clinical research basis: recovery follows exponential decay — most dramatic improvement in first days,
## then gradual tapering. Weights chosen to approximate this curve across capped game durations:
## Critical(15%) captures immediate post-injury confusion/disorientation (~minutes),
## Acute(40%) covers the peak symptom period where most patients are still impaired,
## Subacute(35%) represents the longest recovery window where gradual improvement occurs.
## Recovery is the remainder (1.0 - the three above) — the tail-end return-to-baseline period.
const CONCUSSION_PHASE_WEIGHT_CRITICAL: float = 0.15
const CONCUSSION_PHASE_WEIGHT_ACUTE: float = 0.40
const CONCUSSION_PHASE_WEIGHT_SUBACUTE: float = 0.35

# --- TBI / concussion wound-healing effect (Issue 8). ---
## Clinical reversal: Aghapour et al. (Wound Repair Regen, 2025) showed mild TBI ACCELERATES
## peripheral wound healing via systemic IGF-1/CCL22 elevation — faster immune cell recruitment,
## earlier re-epithelialization. Only severe TBI with CNS involvement or spinal cord injury
## impairs peripheral healing. Game concussions are mild-to-moderate (90s duration), so the
## clinically accurate behavior is NO IMPAIRMENT (set to 1.0). Kept as named constants for
## future use if severe-TBI healing impairment is added.
const CONCUSSION_HEALING_CRITICAL_MULT: float = 1.0    # no impairment (mild TBI accelerates healing)
const CONCUSSION_HEALING_ACUTE_MULT: float = 1.0       # no impairment
const CONCUSSION_HEALING_SUBACUTE_MULT: float = 1.0    # no impairment
const CONCUSSION_HEALING_RECOVERY_MULT: float = 1.0    # no impairment

# --- Blunt head trauma energy threshold (Issue: dagger HEAD_TRAUMA at 17J) ---
## Minimum single-strike blunt KE to classify a death/incapacitation as "head trauma" (TBI/cranial fracture).
## Clinical: skull fracture onset 47-130J (temporal bone cadaver studies, thinnest at ~47J), but
## clinically significant TBI (diffuse axonal injury, contusion) requires higher energy transfer.
## Gadd (1966): ~158J frontal; Nahum & Smith (1976): 135-203J frontal; Brandenburg et al. (1979): ~80-120J onset.
## 90J = onset of clinically significant TBI (contusion/concussion with functional impairment),
## not just hairline fracture. Strikes below this threshold that destroy head tissue are bleed_out from
## accumulated wounds, not acute traumatic brain injury.
const BLUNT_HEAD_TRAUMA_MIN_KE_J: float = 90.0

