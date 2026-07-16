class_name CombatResearchDerivations
extends RefCounted

## Literature bands and **derived** game anchors  -  not tuned in isolation.
## Narrative: docs/LIVE_PATHS.md#bleeding-physics . docs/LIVE_PATHS.md#research-audit
## Headless: `[research_benchmarks]` . harness `_run_research_*`

const HumanSpecies := preload("res://resources/species/human.tres")
const GoblinSpecies := preload("res://resources/species/goblin.tres")

## ATLS 10th ed. hemorrhage; field untreated major bleed (CoTCCC order-of-minutes, wide variance).
const LITERATURE_TTD_UNTREATED_S_MIN: float = 30.0
const LITERATURE_TTD_UNTREATED_S_MAX: float = 120.0
const LITERATURE_TTD_TARGET_S: float = 48.0
## StatPearls NBK526077 / standard transfusion: ~70 mL/kg (male); female ~65 mL/kg.
const LITERATURE_BLOOD_ML_PER_KG_NOMINAL: float = CombatDesignAnchors.REFERENCE_BLOOD_ML_PER_KG
const LITERATURE_BLOOD_ML_PER_KG_TOLERANCE: float = 1.0
## ATLS Class IV: >40% volume loss (remaining <60%).
const LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN: float = 40.0
const LITERATURE_ATLS_CLASS_I_LOSS_PCT_MAX: float = 15.0
const LITERATURE_ATLS_CLASS_II_LOSS_PCT_MAX: float = 30.0
const LITERATURE_ATLS_CLASS_III_LOSS_PCT_MAX: float = 40.0
## WTA/ATLS soft signs teaching: 1 sign ~10% vascular injury probability; 2+ signs ~25% (penetrating selective workup).
const LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS: float = 0.25
const LITERATURE_ARTERIAL_CRITICAL_TOLERANCE: float = 0.04
## Forearm SC fat ultrasound band (mm); game stack = subcut + muscle sheets (5 mm arm total).
const LITERATURE_ARM_SC_FAT_MM_MIN: float = 3.0
const LITERATURE_ARM_SC_FAT_MM_MAX: float = 12.0
## HEMA committed oberhau calibration (project biomechanics band, not cadaver J fracture).
const LITERATURE_HEMA_COMMITTED_KE_J_MIN: float = CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MIN
const LITERATURE_HEMA_COMMITTED_KE_J_MAX: float = CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MAX
## Manual compression: arterial hemorrhage often incompletely occluded (~30 - 50% flow may persist).
const LITERATURE_DIRECT_PRESSURE_ARTERIAL_FLOW_RETAINED: float = 0.50
const LITERATURE_PRESSURE_TTD_RATIO_TARGET: float = 2.0
const LITERATURE_PRESSURE_TTD_RATIO_TOLERANCE: float = 0.15
const LITERATURE_MULTIPLIER_TOLERANCE: float = 0.04
## Penetrating extremity vascular injury: blunt ~18 - 36%% of cases -> crush arterial mult <=0.36 (game 0.35).
const LITERATURE_BLUNT_VASCULAR_FRACTION_MAX: float = 0.36
## Scalp profuse bleeding vs limb baseline (StatPearls scalp vascularity).
const LITERATURE_SCALP_BLEED_MULT_MIN: float = 1.4
## Bandaged clotting half-life target ~2 - 5 min hemostasis (first-order k).
const LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN: float = 60.0
const LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX: float = 300.0
## Sustained compression: faster local rate decay than open bleed; compressible venous hemostasis over field-care
## window.
const LITERATURE_PRESSURE_HEMOSTASIS_HALF_LIFE_S_MIN: float = 10.0
const LITERATURE_PRESSURE_HEMOSTASIS_HALF_LIFE_S_MAX: float = 180.0
const GOBLIN_REFERENCE_MASS_KG: float = 38.0
## Goblin live tissue sum band with S5 profiled derived limbs (hand exports via mini() cap).
const GOBLIN_LIVE_TISSUE_SUM_MIN: int = 40
const GOBLIN_LIVE_TISSUE_SUM_MAX: int = 56
## NRS 4 - 5 = first functional impairment (acute pain literature); Method B thresholds in PainConsciousnessConstants.
const LITERATURE_NRS_FIRST_EFFECT: float = 4.0
const LITERATURE_HUMAN_PAIN_REFERENCE: float = 3.0
const LITERATURE_HUMAN_PAIN_REFERENCE_TOLERANCE: float = 0.15
## One moderate wound increment used in calibration audit species section.
const LITERATURE_MODERATE_HIT_RAW_PAIN: float = 6.0
const LITERATURE_HITS_TO_NRS4_MIN: float = 1.5
const LITERATURE_HITS_TO_NRS4_MAX: float = 3.0
## de Leva (1996) whole-body segment mass %  -  game head lump includes face/scalp (wider than head-only).
const LITERATURE_DE_LEVA_HEAD_PCT: float = 6.9
const LITERATURE_DE_LEVA_HEAD_PCT_TOLERANCE: float = 4.0
const LITERATURE_FOREARM_ARTERIAL_MULT_MIN: float = 1.1
## Post-S11 full production gate id (mirrors CombatCalibrationAudit.material_failure_headless_gate_line).
const LITERATURE_HEADLESS_GATE_FULL: String = "p3b_full_including_energy_pool_joule_armor_and_literal_blood_ml"
## M6 arm anchor: body_max 12 '??" design KE arm slot (`CombatDesignAnchors`).
const LITERATURE_ARM_TISSUE_CAPACITY_J: float = CombatDesignAnchors.DESIGN_KE_ARM_J
const LITERATURE_ARM_CAPACITY_J_TOLERANCE: float = 5.0
const LITERATURE_ARM_DISPLAY_HALF_J: float = 6.0
const LITERATURE_ARM_DISPLAY_HALF_TOLERANCE: float = 1.0
const LITERATURE_ARM_BLUNT_KE_BUDGET_J: float = 22.0
const HUMAN_ARM_TISSUE_BODY_MAX: int = CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
## Pain performance at NRS 4 (first effect): -8% per PainConsciousnessConstants.
const LITERATURE_PAIN_PERF_AT_NRS4: float = 0.92
const LITERATURE_PAIN_PERF_TOLERANCE: float = 0.02
## Joule armor: sqrt(ke_remaining/strike_ke) transmission; cuirass pen6 reference strike.
const LITERATURE_JOULE_REFERENCE_STRIKE_KE_J: float = 120.0
const LITERATURE_JOULE_REFERENCE_PEN_MM: float = 6.0
const LITERATURE_JOULE_KE_FRAC_MIN: float = 0.15
const LITERATURE_JOULE_KE_FRAC_MAX: float = 0.85
## Headless research gates  -  keep in sync with `_run_research_*` in CombatRegressionHarnessSimulation +
## docs/LIVE_PATHS.md#research-audit.
const RESEARCH_HARNESS_GATE_IDS: Array[String] = [
    "clinical_ttd_band",
    "blood_ml_nominal_70_per_kg",
    "atls_class_boundaries",
    "blood_loss_multiplier_derived",
    "reference_bleed_derivation",
    "atls_death_threshold",
    "arterial_chance_literature",
    "blunt_anchor_ordering",
    "committed_ke_hema_band",
    "direct_pressure_ttd_halving",
    "bleeding_ladder_monotonic",
    "pen_depth_monotonic",
    "clotting_half_life_order",
    "ml_percent_ttd_parity",
    "implied_ml_bridge",
    "species_reference_mass_anchors",
    "goblin_blood_ml_per_kg",
    "scalp_vs_limb_bleed",
    "absolute_severity_bands",
    "pain_human_reference",
    "pain_hits_to_nrs4",
    "pain_nrs_thresholds_ordered",
    "pain_goblin_below_human",
    "forearm_arterial_epidemiology",
    "human_chest_largest_segment",
    "production_full_stack_gate",
    "tissue_energy_arm_anchor",
    "normalized_pain_method_b",
    "derived_limb_species_flags",
    "blunt_ke_budget_reduces_bone",
    "atls_blood_consciousness_monotonic",
    "pain_performance_nrs_bands",
    "neck_arterial_epidemiology",
    "medical_triage_thresholds",
    "triage_danger_seconds_vs_ttd",
    "joule_sqrt_transmission",
    "material_curve_full_blend",
]


static func research_harness_gate_count() -> int:
    return RESEARCH_HARNESS_GATE_IDS.size()


static func reference_bleed_rate_derivation() -> Dictionary:
    var cut_crit: float = float(
        BleedingConstants.BLEEDING_RATES[BleedingConstants.INJURY_TYPE_CUT][BleedingConstants.SEVERITY_CRITICAL]
    )
    var head_mult: float = float(BleedingConstants.BODY_PART_BLEEDING_MULTIPLIERS["head"])
    var arterial_mult: float = BleedingConstants.ARTERIAL_BLEEDING_MULTIPLIER
    var product: float = cut_crit * head_mult * arterial_mult
    var ref_kg: float = CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
    var implied_ml_s: float = reference_uncontrolled_implied_ml_per_second(ref_kg, 1.0)
    var derived_mult: float = derived_blood_loss_multiplier_for_ttd(LITERATURE_TTD_TARGET_S)
    return {
        "critical_cut_hp_per_s": cut_crit,
        "head_part_mult": head_mult,
        "arterial_mult": arterial_mult,
        "product_hp_per_s": product,
        "matches_reference_const": is_equal_approx(product, BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE),
        "clinical_ttd_s": clinical_ttd_seconds(1.0),
        "derived_blood_loss_multiplier": derived_mult,
        "shipped_blood_loss_multiplier": BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER,
        "multiplier_matches_derived": blood_loss_multiplier_matches_derived(),
        "implied_ml_per_s": implied_ml_s,
        "implied_ml_per_min": implied_ml_s * 60.0,
        "ml_ttd_parity_ok": ml_percent_ttd_parity_ok(),
    }


static func blood_loss_multiplier_matches_derived() -> bool:
    var derived: float = derived_blood_loss_multiplier_for_ttd(LITERATURE_TTD_TARGET_S)
    return absf(BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER - derived) <= LITERATURE_MULTIPLIER_TOLERANCE


static func human_reference_mass_matches_design_anchor() -> bool:
    return is_equal_approx(HumanSpecies.resolved_reference_mass_kg(), CombatDesignAnchors.REFERENCE_ADULT_MASS_KG)


static func goblin_reference_mass_matches_anchor() -> bool:
    return is_equal_approx(GoblinSpecies.resolved_reference_mass_kg(), GOBLIN_REFERENCE_MASS_KG)


static func human_live_tissue_sum_matches_design_anchor() -> bool:
    return HumanSpecies.live_tissue_sum() == CombatDesignAnchors.REFERENCE_HUMAN_TISSUE_SUM


static func goblin_live_tissue_sum_in_band() -> bool:
    var sum: int = GoblinSpecies.live_tissue_sum()
    return sum >= GOBLIN_LIVE_TISSUE_SUM_MIN and sum <= GOBLIN_LIVE_TISSUE_SUM_MAX


static func goblin_mass_below_human() -> bool:
    return GoblinSpecies.resolved_reference_mass_kg() < HumanSpecies.resolved_reference_mass_kg() - 1.0


static func species_reference_mass_anchors_match() -> bool:
    return (
        human_reference_mass_matches_design_anchor()
        and goblin_reference_mass_matches_anchor()
        and human_live_tissue_sum_matches_design_anchor()
        and goblin_live_tissue_sum_in_band()
        and goblin_mass_below_human()
    )


static func derived_blood_loss_multiplier_for_ttd(target_ttd_s: float) -> float:
    var buffer: float = BleedingConstants.MAX_BLOOD_VOLUME - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
    var denom: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE * maxf(1.0, target_ttd_s)
    if denom <= 0.01:
        return 0.0
    return buffer / denom


## Implied mL/s from abstract HP/s bleed via percent'??"mL bridge (`BloodVolumeMl`).
## Not a clinical flow-rate claim  -  **TTD** (30 - 120 s band) is the calibrated outcome.


## Implied mL/s from abstract HP/s bleed via percent'??"mL bridge (`BloodVolumeMl`).
## Not a clinical flow-rate claim  -  **TTD** (30 - 120 s band) is the calibrated outcome.
static func reference_uncontrolled_implied_ml_per_second(
    reference_mass_kg: float = CombatDesignAnchors.REFERENCE_ADULT_MASS_KG, loss_mult: float = 1.0
) -> float:
    var max_ml: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(reference_mass_kg)
    return BloodVolumeMl.blood_ml_loss_per_second(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, max_ml, loss_mult
    )


static func reference_uncontrolled_implied_ml_per_minute(
    reference_mass_kg: float = CombatDesignAnchors.REFERENCE_ADULT_MASS_KG, loss_mult: float = 1.0
) -> float:
    return reference_uncontrolled_implied_ml_per_second(reference_mass_kg, loss_mult) * 60.0


static func clinical_ttd_seconds(loss_mult: float = 1.0) -> float:
    return BleedingConstants.seconds_to_exsanguination(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, BleedingConstants.MAX_BLOOD_VOLUME, loss_mult
    )


static func blood_ml_per_kg_at_reference_mass(reference_mass_kg: float) -> float:
    return BloodVolumeMl.blood_volume_ml_max_for_reference_mass(reference_mass_kg) / maxf(1.0, reference_mass_kg)


static func loss_pct_to_death_threshold() -> float:
    return 100.0 - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD


static func atls_class_boundaries_match_atls10() -> bool:
    return (
        BleedingConstants.atls_hemorrhage_class_from_remaining_pct(90.0) == 1
        and BleedingConstants.atls_hemorrhage_class_from_remaining_pct(75.0) == 2
        and BleedingConstants.atls_hemorrhage_class_from_remaining_pct(65.0) == 3
        and BleedingConstants.atls_hemorrhage_class_from_remaining_pct(50.0) == 4
        and BleedingConstants.atls_hemorrhage_class_from_remaining_pct(59.0) == 4
        and BleedingConstants.atls_hemorrhage_class_from_remaining_pct(60.0) == 3
    )


static func death_threshold_deep_in_class_iv() -> bool:
    return BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD < BleedingConstants.ATLS_CLASS_III_MIN_REMAINING


static func committed_oberhau_ke_j() -> float:
    var sword: Variant = Weapon.create_from_definition("SWORD")
    if sword == null:
        return -1.0
    var ai: Variant = AttackInstance.new("oberhau", 1.0)
    ai.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai.delivery_commit_fraction = 0.78
    return WeaponDamageHelper.compute_kinetic_energy_j(sword, ai)


static func pressure_halved_ttd_ratio() -> float:
    var full: float = clinical_ttd_seconds(1.0)
    var half: float = clinical_ttd_seconds(0.5)
    if full < 0.01:
        return 0.0
    return half / full


static func blunt_anchor_ordering_ok() -> bool:
    var elbow: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
    var forearm: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_arm", "forearm")
    var thigh: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_leg", "thigh")
    return elbow < forearm and forearm < thigh


static func clotting_effective_k(severity: String) -> float:
    var base: float = float(BleedingConstants.CLOTTING_RATE_BY_SEVERITY.get(severity, 0.0))
    var mult: float = float(BleedingConstants.CLOTTING_SEVERITY_MULTIPLIERS.get(severity, 1.0))
    return base * mult


static func clotting_half_life_s(severity: String) -> float:
    var k: float = clotting_effective_k(severity)
    if k <= 0.0001:
        return INF
    return log(2.0) / k


static func clotting_half_life_ordering_ok() -> bool:
    var minor_hl: float = clotting_half_life_s(BleedingConstants.SEVERITY_MINOR)
    var mod_hl: float = clotting_half_life_s(BleedingConstants.SEVERITY_MODERATE)
    var sev_hl: float = clotting_half_life_s(BleedingConstants.SEVERITY_SEVERE)
    var crit_hl: float = clotting_half_life_s(BleedingConstants.SEVERITY_CRITICAL)
    return minor_hl < mod_hl and mod_hl < sev_hl and sev_hl < crit_hl


static func bleeding_severity_ladder_monotonic() -> bool:
    var cut: Dictionary = BleedingConstants.BLEEDING_RATES[BleedingConstants.INJURY_TYPE_CUT]
    var crush: Dictionary = BleedingConstants.BLEEDING_RATES[BleedingConstants.INJURY_TYPE_CRUSH]
    var sevs: Array = [
        BleedingConstants.SEVERITY_MINOR,
        BleedingConstants.SEVERITY_MODERATE,
        BleedingConstants.SEVERITY_SEVERE,
        BleedingConstants.SEVERITY_CRITICAL,
    ]
    var prev_cut: float = -1.0
    var prev_crush: float = -1.0
    for sev: String in sevs:
        var c: float = float(cut[sev])
        var b: float = float(crush[sev])
        if c <= prev_cut or b <= prev_crush or c <= b:
            return false
        prev_cut = c
        prev_crush = b
    return true


static func cut_bleeding_exceeds_crush_at_all_severities() -> bool:
    for sev: String in [
        BleedingConstants.SEVERITY_MINOR,
        BleedingConstants.SEVERITY_MODERATE,
        BleedingConstants.SEVERITY_SEVERE,
        BleedingConstants.SEVERITY_CRITICAL,
    ]:
        var cut_r: float = float(BleedingConstants.BLEEDING_RATES[BleedingConstants.INJURY_TYPE_CUT][sev])
        var crush_r: float = float(BleedingConstants.BLEEDING_RATES[BleedingConstants.INJURY_TYPE_CRUSH][sev])
        if cut_r <= crush_r:
            return false
    return true


static func penetration_depth_mult_monotonic() -> bool:
    var shallow: float = BleedingConstants.penetration_depth_severity_mult(0.5)
    var mid: float = BleedingConstants.penetration_depth_severity_mult(3.0)
    var deep: float = BleedingConstants.penetration_depth_severity_mult(6.0)
    return shallow < mid and mid <= deep and shallow <= BleedingConstants.PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT + 0.01


static func penetration_arterial_mult_monotonic() -> bool:
    var shallow: float = BleedingConstants.penetration_depth_arterial_mult(0.5)
    var deep: float = BleedingConstants.penetration_depth_arterial_mult(6.0)
    return shallow < deep


static func ml_percent_ttd_parity_ok() -> bool:
    var rate: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE
    var ttd_pct: float = BleedingConstants.seconds_to_exsanguination(rate, BleedingConstants.MAX_BLOOD_VOLUME, 1.0)
    var max_ml: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(
        CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
    )
    var buffer_ml: float = (
        max_ml
        * (
            (BleedingConstants.MAX_BLOOD_VOLUME - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD)
            / BleedingConstants.MAX_BLOOD_VOLUME
        )
    )
    var loss_ml_s: float = reference_uncontrolled_implied_ml_per_second(
        CombatDesignAnchors.REFERENCE_ADULT_MASS_KG, 1.0
    )
    var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
    return is_equal_approx(ttd_pct, ttd_ml)


static func goblin_blood_ml_per_kg_matches_human_anchor() -> bool:
    var gob_per_kg: float = blood_ml_per_kg_at_reference_mass(GOBLIN_REFERENCE_MASS_KG)
    return absf(gob_per_kg - LITERATURE_BLOOD_ML_PER_KG_NOMINAL) <= LITERATURE_BLOOD_ML_PER_KG_TOLERANCE


static func bandage_clot_half_life_s() -> float:
    return log(2.0) / BleedingConstants.CLOTTING_RATE_STABILIZED


static func pressure_held_clot_half_life_s() -> float:
    return log(2.0) / BleedingConstants.CLOTTING_RATE_UNDER_DIRECT_PRESSURE


static func pressure_held_clot_half_life_in_literature_band() -> bool:
    var hl: float = pressure_held_clot_half_life_s()
    return (
        hl >= LITERATURE_PRESSURE_HEMOSTASIS_HALF_LIFE_S_MIN
        and hl <= LITERATURE_PRESSURE_HEMOSTASIS_HALF_LIFE_S_MAX
        and hl < bandage_clot_half_life_s()
    )


static func absolute_severity_bands_ordered() -> bool:
    return (
        BleedingConstants.SEVERITY_ABSOLUTE_MODERATE < BleedingConstants.SEVERITY_ABSOLUTE_SEVERE
        and BleedingConstants.SEVERITY_ABSOLUTE_SEVERE < BleedingConstants.SEVERITY_ABSOLUTE_CRITICAL
        and BleedingConstants.SEVERITY_ABSOLUTE_BONE_MODERATE < BleedingConstants.SEVERITY_ABSOLUTE_BONE_SEVERE
        and BleedingConstants.SEVERITY_ABSOLUTE_BONE_SEVERE < BleedingConstants.SEVERITY_ABSOLUTE_BONE_CRITICAL
    )


static func scalp_bleed_mult_exceeds_limb() -> bool:
    var scalp: float = float(BleedingConstants.SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"])
    var forearm: float = float(BleedingConstants.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"])
    return scalp >= LITERATURE_SCALP_BLEED_MULT_MIN and scalp > forearm


static func pain_reference_for_species(sp: SpeciesResource) -> float:
    return sp.live_pain_reference()


static func moderate_hit_effective_pain(sp: SpeciesResource) -> float:
    return LITERATURE_MODERATE_HIT_RAW_PAIN / maxf(0.01, pain_reference_for_species(sp))


static func hits_to_nrs_first_effect(sp: SpeciesResource) -> float:
    var eff: float = moderate_hit_effective_pain(sp)
    if eff <= 0.01:
        return INF
    return LITERATURE_NRS_FIRST_EFFECT / eff


static func human_pain_reference_matches_literature() -> bool:
    return (
        absf(pain_reference_for_species(HumanSpecies) - LITERATURE_HUMAN_PAIN_REFERENCE)
        <= LITERATURE_HUMAN_PAIN_REFERENCE_TOLERANCE
    )


static func human_hits_to_nrs4_in_band() -> bool:
    var hits: float = hits_to_nrs_first_effect(HumanSpecies)
    return hits >= LITERATURE_HITS_TO_NRS4_MIN and hits <= LITERATURE_HITS_TO_NRS4_MAX


static func goblin_pain_reference_below_human() -> bool:
    return pain_reference_for_species(GoblinSpecies) < pain_reference_for_species(HumanSpecies) - 0.05


static func nrs_thresholds_ordered() -> bool:
    return (
        PainConsciousnessConstants.NRS_FIRST_EFFECT < PainConsciousnessConstants.NRS_MODERATE
        and PainConsciousnessConstants.NRS_MODERATE < PainConsciousnessConstants.NRS_SHOCK
        and PainConsciousnessConstants.NRS_SHOCK < PainConsciousnessConstants.NRS_SEVERE
        and PainConsciousnessConstants.NRS_SEVERE < PainConsciousnessConstants.NRS_INTOLERABLE
    )


static func human_chest_largest_tissue_segment() -> bool:
    var h: SpeciesResource = HumanSpecies
    return (
        h.get_body_part_max("chest") > h.get_body_part_max("head")
        and h.get_body_part_max("chest") > h.get_body_part_max("left_leg")
    )


static func human_head_pct_within_de_leva_note() -> bool:
    var total: int = HumanSpecies.live_tissue_sum()
    if total <= 0:
        return false
    var pct_head: float = 100.0 * float(HumanSpecies.get_body_part_max("head")) / float(total)
    return absf(pct_head - LITERATURE_DE_LEVA_HEAD_PCT) <= LITERATURE_DE_LEVA_HEAD_PCT_TOLERANCE


static func forearm_arterial_mult_exceeds_upper_arm() -> bool:
    var forearm: float = float(BleedingConstants.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"])
    var upper: float = float(BleedingConstants.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["upper_arm"])
    return forearm >= LITERATURE_FOREARM_ARTERIAL_MULT_MIN and forearm > upper


static func production_headless_gate_id() -> String:
    if BleedingConstants.FEATURE_TISSUE_DAMAGE_D:
        return "partial_enablement_review_flags"
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES and not BleedingConstants.FEATURE_LAYER_TISSUE:
        return "partial_enablement_review_flags"
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        return "headless_M5_gate=all_pilot_flags_off_and_anchors_locked"
    if (
        BleedingConstants.FEATURE_LITERAL_BLOOD_ML
        and CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
        and BleedingConstants.FEATURE_TISSUE_ENERGY_POOL
        and BleedingConstants.FEATURE_LAYER_TISSUE_CURVES
    ):
        return LITERATURE_HEADLESS_GATE_FULL
    if (
        CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
        and BleedingConstants.FEATURE_TISSUE_ENERGY_POOL
        and BleedingConstants.FEATURE_LAYER_TISSUE_CURVES
    ):
        return "p3b_full_including_energy_pool_and_joule_armor"
    if BleedingConstants.FEATURE_TISSUE_ENERGY_POOL and BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        return "p3b_full_including_energy_pool"
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        return "headless_M5_gate=curves_layer_tissue_and_curves_on"
    if BleedingConstants.FEATURE_LAYER_TISSUE:
        return "headless_M5_gate=curves_and_layer_tissue_on"
    return "headless_M5_gate=curves_on_layer_pilots_off_anchors_locked"


static func production_sim_flags_full_stack_ok() -> bool:
    return production_headless_gate_id() == LITERATURE_HEADLESS_GATE_FULL


static func normalized_pain_method_b_enabled() -> bool:
    return PainConsciousnessConstants.USE_NORMALIZED_PAIN


static func derived_limb_capacity_on_both_species() -> bool:
    return HumanSpecies.feature_derived_limb_capacity and GoblinSpecies.feature_derived_limb_capacity


static func tissue_energy_arm_capacity_j() -> float:
    return TissueEnergyCapacity.capacity_j_for_part("right_arm", HUMAN_ARM_TISSUE_BODY_MAX)


static func tissue_energy_arm_capacity_matches_design() -> bool:
    return (
        absf(tissue_energy_arm_capacity_j() - LITERATURE_ARM_TISSUE_CAPACITY_J) <= LITERATURE_ARM_CAPACITY_J_TOLERANCE
    )


static func tissue_energy_arm_display_half_at_50pct() -> float:
    var cap: float = tissue_energy_arm_capacity_j()
    return TissueEnergyCapacity.display_tissue_from_remaining_j(HUMAN_ARM_TISSUE_BODY_MAX, cap * 0.5, cap)


static func tissue_energy_arm_display_half_matches_anchor() -> bool:
    return (
        absf(tissue_energy_arm_display_half_at_50pct() - LITERATURE_ARM_DISPLAY_HALF_J)
        <= LITERATURE_ARM_DISPLAY_HALF_TOLERANCE
    )


static func blunt_ke_after_arm_budget_at_committed_oberhau() -> float:
    return CombatLayerTissue.blunt_ke_reaching_bone("right_arm", committed_oberhau_ke_j())


static func blunt_ke_budget_reduces_bone_load() -> bool:
    var ke: float = committed_oberhau_ke_j()
    if ke < 0.0:
        return false
    return blunt_ke_after_arm_budget_at_committed_oberhau() < ke - 1.0


static func _blood_consciousness_mod(remaining_pct: float) -> float:
    return BleedingConstants.blood_consciousness_modifier_from_remaining(
        remaining_pct,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
    )


static func atls_blood_consciousness_monotonic() -> bool:
    var prev: float = 2.0
    for pct: float in [100.0, 85.0, 70.0, 50.0, 35.0]:
        var mod: float = _blood_consciousness_mod(pct)
        if mod > prev + 0.001:
            return false
        prev = mod
    return true


static func atls_consciousness_mod_at_class_anchors() -> Dictionary:
    return {
        "mod_85": _blood_consciousness_mod(85.0),
        "mod_50": _blood_consciousness_mod(50.0),
        "mod_35": _blood_consciousness_mod(35.0),
    }


static func pain_performance_monotonic_with_nrs() -> bool:
    var below: float = PainConsciousnessConstants.get_pain_performance_modifier(
        PainConsciousnessConstants.NRS_FIRST_EFFECT - 0.1
    )
    var at_first: float = PainConsciousnessConstants.get_pain_performance_modifier(
        PainConsciousnessConstants.NRS_FIRST_EFFECT
    )
    var at_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
        PainConsciousnessConstants.NRS_MODERATE
    )
    var at_sev: float = PainConsciousnessConstants.get_pain_performance_modifier(PainConsciousnessConstants.NRS_SEVERE)
    return (
        below >= at_first - 0.001
        and at_first >= at_mod - 0.001
        and at_mod >= at_sev - 0.001
        and absf(at_first - LITERATURE_PAIN_PERF_AT_NRS4) <= LITERATURE_PAIN_PERF_TOLERANCE
    )


static func neck_arterial_mult_exceeds_forearm() -> bool:
    var neck: float = float(BleedingConstants.SUB_REGION_ARTERIAL_MULTIPLIERS["head"]["neck"])
    var forearm: float = float(BleedingConstants.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"])
    return neck > forearm


## Danger/peril blood bands sit in ATLS Class IV (<=60% remaining, above death threshold).


## Danger/peril blood bands sit in ATLS Class IV (<=60% remaining, above death threshold).
static func medical_triage_blood_bands_in_class_iv_window() -> bool:
    var class_iii_min: float = BleedingConstants.ATLS_CLASS_III_MIN_REMAINING
    var death: float = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
    return (
        BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING <= class_iii_min
        and (
            BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
            < BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING
        )
        and BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING > death
        and death < class_iii_min
    )


static func medical_triage_thresholds_ordered() -> bool:
    var ref_ttd_s: float = clinical_ttd_seconds(1.0)
    return (
        BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING > BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
        and BleedingConstants.MEDICAL_TRIAGE_DANGER_SECONDS > BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS
        and BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING > BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
        and BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS < ref_ttd_s
        and medical_triage_blood_bands_in_class_iv_window()
    )


static func medical_triage_danger_seconds_exceeds_reference_ttd() -> bool:
    return BleedingConstants.MEDICAL_TRIAGE_DANGER_SECONDS > clinical_ttd_seconds(1.0)


static func summarize_benchmark_verdicts(lines: PackedStringArray) -> Dictionary:
    var pass_n: int = 0
    var warn_n: int = 0
    var note_n: int = 0
    var in_section: bool = false
    for line: String in lines:
        if line == "[research_benchmarks]":
            in_section = true
            continue
        if in_section and line.begins_with("["):
            break
        if not in_section:
            continue
        if line.contains("verdict=pass"):
            pass_n += 1
        elif line.contains("verdict=warn"):
            warn_n += 1
        elif line.contains("verdict=note"):
            note_n += 1
    return {"pass": pass_n, "warn": warn_n, "note": note_n}


static func joule_cuirass_transmitted_ke_fraction() -> float:
    var cuirass: Variant = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null:
        return -1.0
    return float(
        (
            ArmorJouleBudget
            . account_ke_through_armor(
                cuirass, LITERATURE_JOULE_REFERENCE_STRIKE_KE_J, LITERATURE_JOULE_REFERENCE_PEN_MM, true
            )
            . get("transmitted_ke_fraction", 0.0)
        )
    )


static func joule_transmission_bounded_and_conserved() -> bool:
    var cuirass: Variant = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null:
        return false
    var r: Dictionary = ArmorJouleBudget.account_ke_through_armor(
        cuirass, LITERATURE_JOULE_REFERENCE_STRIKE_KE_J, LITERATURE_JOULE_REFERENCE_PEN_MM, true
    )
    var strike: float = float(r.get("strike_ke_j", 0.0))
    var absorbed: float = float(r.get("armor_ke_absorbed_j", 0.0))
    var remaining: float = float(r.get("armor_ke_remaining_j", 0.0))
    var frac: float = float(r.get("transmitted_ke_fraction", 0.0))
    if not is_equal_approx(absorbed + remaining, strike):
        return false
    var want_frac: float = sqrt(remaining / strike) if strike > 0.01 else 0.0
    return (
        frac >= LITERATURE_JOULE_KE_FRAC_MIN and frac <= LITERATURE_JOULE_KE_FRAC_MAX and absf(frac - want_frac) <= 0.06
    )


static func blunt_fracture_j_excess_scaling_note() -> String:
    var anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_arm", "forearm")
    var excess: float = maxf(0.0, committed_oberhau_ke_j() - anchor)
    var damage: float = CombatDamageMechanism.j_excess_to_bone_damage(excess)
    return "anchor_J=%.0f excess_J=%.0f damage=2*sqrt(excess)=%.2f" % [anchor, excess, damage]


static func material_curves_full_blend_when_on() -> bool:
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        return true
    return is_equal_approx(BleedingConstants.MATERIAL_CURVE_BLEND_WEIGHT, 1.0)
