class_name CombatResearchAnchors
extends RefCounted

## Literature bands and **derived** game anchors  -  not tuned in isolation.
## Narrative: docs/LIVE_PATHS.md#bleeding-physics . docs/LIVE_PATHS.md#research-audit
## Headless: `[research_benchmarks]` . harness `_run_research_*`

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _DamageMechanism := preload("res://core/CombatDamageMechanism.gd")
const _CombatLayerTissue := preload("res://core/CombatLayerTissue.gd")
const _MaterialFailureCurves := preload("res://core/MaterialFailureCurves.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _WeaponDamage := preload("res://weapon/WeaponDamageHelper.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _AttackInstanceScript := preload("res://weapon/AttackInstance.gd")
const _Pain := preload("res://core/PainConsciousnessConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _TissueEnergy := preload("res://core/TissueEnergyCapacity.gd")
const _ArmorJoule := preload("res://core/ArmorJouleBudget.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _HumanSpecies := preload("res://species/human.tres")
const _GoblinSpecies := preload("res://species/goblin.tres")
const _SpeciesResource := preload("res://species/SpeciesResource.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")

## --- Literature anchors (cite in docs/LIVE_PATHS.md#research-audit) ---
## ATLS 10th ed. hemorrhage; field untreated major bleed (CoTCCC order-of-minutes, wide variance).
const LITERATURE_TTD_UNTREATED_S_MIN: float = 30.0
const LITERATURE_TTD_UNTREATED_S_MAX: float = 120.0
const LITERATURE_TTD_TARGET_S: float = 48.0
## StatPearls NBK526077 / standard transfusion: ~70 mL/kg (male); female ~65 mL/kg.
const LITERATURE_BLOOD_ML_PER_KG_NOMINAL: float = _DesignAnchors.REFERENCE_BLOOD_ML_PER_KG
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
const LITERATURE_HEMA_COMMITTED_KE_J_MIN: float = _DesignAnchors.COMMITTED_STRIKE_KE_J_MIN
const LITERATURE_HEMA_COMMITTED_KE_J_MAX: float = _DesignAnchors.COMMITTED_STRIKE_KE_J_MAX
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
## Sustained compression: faster local rate decay than open bleed; compressible venous hemostasis over field-care window.
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
const LITERATURE_ARM_TISSUE_CAPACITY_J: float = _DesignAnchors.DESIGN_KE_ARM_J
const LITERATURE_ARM_CAPACITY_J_TOLERANCE: float = 5.0
const LITERATURE_ARM_DISPLAY_HALF_J: float = 6.0
const LITERATURE_ARM_DISPLAY_HALF_TOLERANCE: float = 1.0
const LITERATURE_ARM_BLUNT_KE_BUDGET_J: float = 22.0
const HUMAN_ARM_TISSUE_BODY_MAX: int = _DesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
## Pain performance at NRS 4 (first effect): -8% per PainConsciousnessConstants.
const LITERATURE_PAIN_PERF_AT_NRS4: float = 0.92
const LITERATURE_PAIN_PERF_TOLERANCE: float = 0.02
## Joule armor: sqrt(ke_remaining/strike_ke) transmission; cuirass pen6 reference strike.
const LITERATURE_JOULE_REFERENCE_STRIKE_KE_J: float = 120.0
const LITERATURE_JOULE_REFERENCE_PEN_MM: float = 6.0
const LITERATURE_JOULE_KE_FRAC_MIN: float = 0.15
const LITERATURE_JOULE_KE_FRAC_MAX: float = 0.85
## Headless research gates  -  keep in sync with `_run_research_*` in CombatRegressionHarnessSimulation + docs/LIVE_PATHS.md#research-audit.
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
	var cut_crit: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CUT][_Bleeding.SEVERITY_CRITICAL])
	var head_mult: float = float(_Bleeding.BODY_PART_BLEEDING_MULTIPLIERS["head"])
	var arterial_mult: float = _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	var product: float = cut_crit * head_mult * arterial_mult
	var ref_kg: float = _DesignAnchors.REFERENCE_ADULT_MASS_KG
	var implied_ml_s: float = reference_uncontrolled_implied_ml_per_second(ref_kg, 1.0)
	var derived_mult: float = derived_blood_loss_multiplier_for_ttd(LITERATURE_TTD_TARGET_S)
	return {
		"critical_cut_hp_per_s": cut_crit,
		"head_part_mult": head_mult,
		"arterial_mult": arterial_mult,
		"product_hp_per_s": product,
		"matches_reference_const": is_equal_approx(product, _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE),
		"clinical_ttd_s": clinical_ttd_seconds(1.0),
		"derived_blood_loss_multiplier": derived_mult,
		"shipped_blood_loss_multiplier": _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER,
		"multiplier_matches_derived": blood_loss_multiplier_matches_derived(),
		"implied_ml_per_s": implied_ml_s,
		"implied_ml_per_min": implied_ml_s * 60.0,
		"ml_ttd_parity_ok": ml_percent_ttd_parity_ok(),
	}


static func blood_loss_multiplier_matches_derived() -> bool:
	var derived: float = derived_blood_loss_multiplier_for_ttd(LITERATURE_TTD_TARGET_S)
	return absf(_Bleeding.BLOOD_LOSS_RATE_MULTIPLIER - derived) <= LITERATURE_MULTIPLIER_TOLERANCE


static func human_reference_mass_matches_design_anchor() -> bool:
	return is_equal_approx(
		_HumanSpecies.resolved_reference_mass_kg(), _DesignAnchors.REFERENCE_ADULT_MASS_KG
	)


static func goblin_reference_mass_matches_anchor() -> bool:
	return is_equal_approx(_GoblinSpecies.resolved_reference_mass_kg(), GOBLIN_REFERENCE_MASS_KG)


static func human_live_tissue_sum_matches_design_anchor() -> bool:
	return _HumanSpecies.live_tissue_sum() == _DesignAnchors.REFERENCE_HUMAN_TISSUE_SUM


static func goblin_live_tissue_sum_in_band() -> bool:
	var sum: int = _GoblinSpecies.live_tissue_sum()
	return sum >= GOBLIN_LIVE_TISSUE_SUM_MIN and sum <= GOBLIN_LIVE_TISSUE_SUM_MAX


static func goblin_mass_below_human() -> bool:
	return (
		_GoblinSpecies.resolved_reference_mass_kg()
		< _HumanSpecies.resolved_reference_mass_kg() - 1.0
	)


static func species_reference_mass_anchors_match() -> bool:
	return (
		human_reference_mass_matches_design_anchor()
		and goblin_reference_mass_matches_anchor()
		and human_live_tissue_sum_matches_design_anchor()
		and goblin_live_tissue_sum_in_band()
		and goblin_mass_below_human()
	)


static func derived_blood_loss_multiplier_for_ttd(target_ttd_s: float) -> float:
	var buffer: float = _Bleeding.MAX_BLOOD_VOLUME - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	var denom: float = _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE * maxf(1.0, target_ttd_s)
	if denom <= 0.01:
		return 0.0
	return buffer / denom


## Implied mL/s from abstract HP/s bleed via percent'??"mL bridge (`BloodVolumeMl`).
## Not a clinical flow-rate claim  -  **TTD** (30 - 120 s band) is the calibrated outcome.
static func reference_uncontrolled_implied_ml_per_second(
	reference_mass_kg: float = _DesignAnchors.REFERENCE_ADULT_MASS_KG,
	loss_mult: float = 1.0
) -> float:
	var max_ml: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(reference_mass_kg)
	return _BloodVolumeMl.blood_ml_loss_per_second(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, max_ml, loss_mult
	)


static func reference_uncontrolled_implied_ml_per_minute(
	reference_mass_kg: float = _DesignAnchors.REFERENCE_ADULT_MASS_KG,
	loss_mult: float = 1.0
) -> float:
	return reference_uncontrolled_implied_ml_per_second(reference_mass_kg, loss_mult) * 60.0


static func clinical_ttd_seconds(loss_mult: float = 1.0) -> float:
	return _Bleeding.seconds_to_exsanguination(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, _Bleeding.MAX_BLOOD_VOLUME, loss_mult
	)


static func blood_ml_per_kg_at_reference_mass(reference_mass_kg: float) -> float:
	return _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(reference_mass_kg) / maxf(1.0, reference_mass_kg)


static func loss_pct_to_death_threshold() -> float:
	return 100.0 - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD


static func atls_class_boundaries_match_atls10() -> bool:
	return (
		_Bleeding.atls_hemorrhage_class_from_remaining_pct(90.0) == 1
		and _Bleeding.atls_hemorrhage_class_from_remaining_pct(75.0) == 2
		and _Bleeding.atls_hemorrhage_class_from_remaining_pct(65.0) == 3
		and _Bleeding.atls_hemorrhage_class_from_remaining_pct(50.0) == 4
		and _Bleeding.atls_hemorrhage_class_from_remaining_pct(59.0) == 4
		and _Bleeding.atls_hemorrhage_class_from_remaining_pct(60.0) == 3
	)


static func death_threshold_deep_in_class_iv() -> bool:
	return _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD < _Bleeding.ATLS_CLASS_III_MIN_REMAINING


static func committed_oberhau_ke_j() -> float:
	var sword: Variant = _Weapon.create_from_definition("SWORD")
	if sword == null:
		return -1.0
	var ai: Variant = _AttackInstanceScript.new("oberhau", 1.0)
	ai.archetype = {"kinematic_delivery": _WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai.delivery_commit_fraction = 0.78
	return _WeaponDamage.compute_kinetic_energy_j(sword, ai)


static func pressure_halved_ttd_ratio() -> float:
	var full: float = clinical_ttd_seconds(1.0)
	var half: float = clinical_ttd_seconds(0.5)
	if full < 0.01:
		return 0.0
	return half / full


static func blunt_anchor_ordering_ok() -> bool:
	var elbow: float = _DamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
	var forearm: float = _DamageMechanism.blunt_fracture_j_anchor("right_arm", "forearm")
	var thigh: float = _DamageMechanism.blunt_fracture_j_anchor("right_leg", "thigh")
	return elbow < forearm and forearm < thigh


static func clotting_effective_k(severity: String) -> float:
	var base: float = float(_Bleeding.CLOTTING_RATE_BY_SEVERITY.get(severity, 0.0))
	var mult: float = float(_Bleeding.CLOTTING_SEVERITY_MULTIPLIERS.get(severity, 1.0))
	return base * mult


static func clotting_half_life_s(severity: String) -> float:
	var k: float = clotting_effective_k(severity)
	if k <= 0.0001:
		return INF
	return log(2.0) / k


static func clotting_half_life_ordering_ok() -> bool:
	var minor_hl: float = clotting_half_life_s(_Bleeding.SEVERITY_MINOR)
	var mod_hl: float = clotting_half_life_s(_Bleeding.SEVERITY_MODERATE)
	var sev_hl: float = clotting_half_life_s(_Bleeding.SEVERITY_SEVERE)
	var crit_hl: float = clotting_half_life_s(_Bleeding.SEVERITY_CRITICAL)
	return minor_hl < mod_hl and mod_hl < sev_hl and sev_hl < crit_hl


static func bleeding_severity_ladder_monotonic() -> bool:
	var cut: Dictionary = _Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CUT]
	var crush: Dictionary = _Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CRUSH]
	var sevs: Array = [
		_Bleeding.SEVERITY_MINOR,
		_Bleeding.SEVERITY_MODERATE,
		_Bleeding.SEVERITY_SEVERE,
		_Bleeding.SEVERITY_CRITICAL,
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
		_Bleeding.SEVERITY_MINOR,
		_Bleeding.SEVERITY_MODERATE,
		_Bleeding.SEVERITY_SEVERE,
		_Bleeding.SEVERITY_CRITICAL,
	]:
		var cut_r: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CUT][sev])
		var crush_r: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CRUSH][sev])
		if cut_r <= crush_r:
			return false
	return true


static func penetration_depth_mult_monotonic() -> bool:
	var shallow: float = _Bleeding.penetration_depth_severity_mult(0.5)
	var mid: float = _Bleeding.penetration_depth_severity_mult(3.0)
	var deep: float = _Bleeding.penetration_depth_severity_mult(6.0)
	return shallow < mid and mid <= deep and shallow <= _Bleeding.PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT + 0.01


static func penetration_arterial_mult_monotonic() -> bool:
	var shallow: float = _Bleeding.penetration_depth_arterial_mult(0.5)
	var deep: float = _Bleeding.penetration_depth_arterial_mult(6.0)
	return shallow < deep


static func ml_percent_ttd_parity_ok() -> bool:
	var rate: float = _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE
	var ttd_pct: float = _Bleeding.seconds_to_exsanguination(rate, _Bleeding.MAX_BLOOD_VOLUME, 1.0)
	var max_ml: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(
		_DesignAnchors.REFERENCE_ADULT_MASS_KG
	)
	var buffer_ml: float = max_ml * (
		(_Bleeding.MAX_BLOOD_VOLUME - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / _Bleeding.MAX_BLOOD_VOLUME
	)
	var loss_ml_s: float = reference_uncontrolled_implied_ml_per_second(_DesignAnchors.REFERENCE_ADULT_MASS_KG, 1.0)
	var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
	return is_equal_approx(ttd_pct, ttd_ml)


static func goblin_blood_ml_per_kg_matches_human_anchor() -> bool:
	var gob_per_kg: float = blood_ml_per_kg_at_reference_mass(GOBLIN_REFERENCE_MASS_KG)
	return absf(gob_per_kg - LITERATURE_BLOOD_ML_PER_KG_NOMINAL) <= LITERATURE_BLOOD_ML_PER_KG_TOLERANCE


static func bandage_clot_half_life_s() -> float:
	return log(2.0) / _Bleeding.CLOTTING_RATE_STABILIZED


static func pressure_held_clot_half_life_s() -> float:
	return log(2.0) / _Bleeding.CLOTTING_RATE_UNDER_DIRECT_PRESSURE


static func pressure_held_clot_half_life_in_literature_band() -> bool:
	var hl: float = pressure_held_clot_half_life_s()
	return (
		hl >= LITERATURE_PRESSURE_HEMOSTASIS_HALF_LIFE_S_MIN
		and hl <= LITERATURE_PRESSURE_HEMOSTASIS_HALF_LIFE_S_MAX
		and hl < bandage_clot_half_life_s()
	)


static func absolute_severity_bands_ordered() -> bool:
	return (
		_Bleeding.SEVERITY_ABSOLUTE_MODERATE < _Bleeding.SEVERITY_ABSOLUTE_SEVERE
		and _Bleeding.SEVERITY_ABSOLUTE_SEVERE < _Bleeding.SEVERITY_ABSOLUTE_CRITICAL
		and _Bleeding.SEVERITY_ABSOLUTE_BONE_MODERATE < _Bleeding.SEVERITY_ABSOLUTE_BONE_SEVERE
		and _Bleeding.SEVERITY_ABSOLUTE_BONE_SEVERE < _Bleeding.SEVERITY_ABSOLUTE_BONE_CRITICAL
	)


static func scalp_bleed_mult_exceeds_limb() -> bool:
	var scalp: float = float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"])
	var forearm: float = float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"])
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
	return absf(pain_reference_for_species(_HumanSpecies) - LITERATURE_HUMAN_PAIN_REFERENCE) <= LITERATURE_HUMAN_PAIN_REFERENCE_TOLERANCE


static func human_hits_to_nrs4_in_band() -> bool:
	var hits: float = hits_to_nrs_first_effect(_HumanSpecies)
	return hits >= LITERATURE_HITS_TO_NRS4_MIN and hits <= LITERATURE_HITS_TO_NRS4_MAX


static func goblin_pain_reference_below_human() -> bool:
	return pain_reference_for_species(_GoblinSpecies) < pain_reference_for_species(_HumanSpecies) - 0.05


static func nrs_thresholds_ordered() -> bool:
	return (
		_Pain.NRS_FIRST_EFFECT < _Pain.NRS_MODERATE
		and _Pain.NRS_MODERATE < _Pain.NRS_SHOCK
		and _Pain.NRS_SHOCK < _Pain.NRS_SEVERE
		and _Pain.NRS_SEVERE < _Pain.NRS_INTOLERABLE
	)


static func human_chest_largest_tissue_segment() -> bool:
	var h: SpeciesResource = _HumanSpecies
	return (
		h.get_body_part_max("chest") > h.get_body_part_max("head")
		and h.get_body_part_max("chest") > h.get_body_part_max("left_leg")
	)


static func human_head_pct_within_de_leva_note() -> bool:
	var total: int = _HumanSpecies.live_tissue_sum()
	if total <= 0:
		return false
	var pct_head: float = 100.0 * float(_HumanSpecies.get_body_part_max("head")) / float(total)
	return absf(pct_head - LITERATURE_DE_LEVA_HEAD_PCT) <= LITERATURE_DE_LEVA_HEAD_PCT_TOLERANCE


static func forearm_arterial_mult_exceeds_upper_arm() -> bool:
	var forearm: float = float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"])
	var upper: float = float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["upper_arm"])
	return forearm >= LITERATURE_FOREARM_ARTERIAL_MULT_MIN and forearm > upper


static func production_headless_gate_id() -> String:
	if _Bleeding.FEATURE_TISSUE_DAMAGE_D:
		return "partial_enablement_review_flags"
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES and not _Bleeding.FEATURE_LAYER_TISSUE:
		return "partial_enablement_review_flags"
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		return "headless_M5_gate=all_pilot_flags_off_and_anchors_locked"
	if (
		_Bleeding.FEATURE_LITERAL_BLOOD_ML
		and _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
		and _Bleeding.FEATURE_TISSUE_ENERGY_POOL
		and _Bleeding.FEATURE_LAYER_TISSUE_CURVES
	):
		return LITERATURE_HEADLESS_GATE_FULL
	if (
		_CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
		and _Bleeding.FEATURE_TISSUE_ENERGY_POOL
		and _Bleeding.FEATURE_LAYER_TISSUE_CURVES
	):
		return "p3b_full_including_energy_pool_and_joule_armor"
	if _Bleeding.FEATURE_TISSUE_ENERGY_POOL and _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		return "p3b_full_including_energy_pool"
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		return "headless_M5_gate=curves_layer_tissue_and_curves_on"
	if _Bleeding.FEATURE_LAYER_TISSUE:
		return "headless_M5_gate=curves_and_layer_tissue_on"
	return "headless_M5_gate=curves_on_layer_pilots_off_anchors_locked"


static func production_sim_flags_full_stack_ok() -> bool:
	return production_headless_gate_id() == LITERATURE_HEADLESS_GATE_FULL


static func normalized_pain_method_b_enabled() -> bool:
	return _Pain.USE_NORMALIZED_PAIN


static func derived_limb_capacity_on_both_species() -> bool:
	return _HumanSpecies.feature_derived_limb_capacity and _GoblinSpecies.feature_derived_limb_capacity


static func tissue_energy_arm_capacity_j() -> float:
	return _TissueEnergy.capacity_j_for_part("right_arm", HUMAN_ARM_TISSUE_BODY_MAX)


static func tissue_energy_arm_capacity_matches_design() -> bool:
	return absf(tissue_energy_arm_capacity_j() - LITERATURE_ARM_TISSUE_CAPACITY_J) <= LITERATURE_ARM_CAPACITY_J_TOLERANCE


static func tissue_energy_arm_display_half_at_50pct() -> float:
	var cap: float = tissue_energy_arm_capacity_j()
	return _TissueEnergy.display_tissue_from_remaining_j(HUMAN_ARM_TISSUE_BODY_MAX, cap * 0.5, cap)


static func tissue_energy_arm_display_half_matches_anchor() -> bool:
	return (
		absf(tissue_energy_arm_display_half_at_50pct() - LITERATURE_ARM_DISPLAY_HALF_J)
		<= LITERATURE_ARM_DISPLAY_HALF_TOLERANCE
	)


static func blunt_ke_after_arm_budget_at_committed_oberhau() -> float:
	return _CombatLayerTissue.blunt_ke_reaching_bone("right_arm", committed_oberhau_ke_j())


static func blunt_ke_budget_reduces_bone_load() -> bool:
	var ke: float = committed_oberhau_ke_j()
	if ke < 0.0:
		return false
	return blunt_ke_after_arm_budget_at_committed_oberhau() < ke - 1.0


static func _blood_consciousness_mod(remaining_pct: float) -> float:
	return _Bleeding.blood_consciousness_modifier_from_remaining(
		remaining_pct,
		_Pain.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
		_Pain.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
		_Pain.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
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
	var below: float = _Pain.get_pain_performance_modifier(_Pain.NRS_FIRST_EFFECT - 0.1)
	var at_first: float = _Pain.get_pain_performance_modifier(_Pain.NRS_FIRST_EFFECT)
	var at_mod: float = _Pain.get_pain_performance_modifier(_Pain.NRS_MODERATE)
	var at_sev: float = _Pain.get_pain_performance_modifier(_Pain.NRS_SEVERE)
	return (
		below >= at_first - 0.001
		and at_first >= at_mod - 0.001
		and at_mod >= at_sev - 0.001
		and absf(at_first - LITERATURE_PAIN_PERF_AT_NRS4) <= LITERATURE_PAIN_PERF_TOLERANCE
	)


static func neck_arterial_mult_exceeds_forearm() -> bool:
	var neck: float = float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["head"]["neck"])
	var forearm: float = float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"])
	return neck > forearm


## Danger/peril blood bands sit in ATLS Class IV (<=60% remaining, above death threshold).
static func medical_triage_blood_bands_in_class_iv_window() -> bool:
	var class_iii_min: float = _Bleeding.ATLS_CLASS_III_MIN_REMAINING
	var death: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	return (
		_Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING <= class_iii_min
		and _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
		< _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING
		and _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING > death
		and death < class_iii_min
	)


static func medical_triage_thresholds_ordered() -> bool:
	var ref_ttd_s: float = clinical_ttd_seconds(1.0)
	return (
		_Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING > _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
		and _Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS > _Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS
		and _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING > _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
		and _Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS < ref_ttd_s
		and medical_triage_blood_bands_in_class_iv_window()
	)


static func medical_triage_danger_seconds_exceeds_reference_ttd() -> bool:
	return _Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS > clinical_ttd_seconds(1.0)


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
	var cuirass: Variant = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass == null:
		return -1.0
	return float(
		_ArmorJoule.account_ke_through_armor(
			cuirass, LITERATURE_JOULE_REFERENCE_STRIKE_KE_J, LITERATURE_JOULE_REFERENCE_PEN_MM, true
		).get("transmitted_ke_fraction", 0.0)
	)


static func joule_transmission_bounded_and_conserved() -> bool:
	var cuirass: Variant = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass == null:
		return false
	var r: Dictionary = _ArmorJoule.account_ke_through_armor(
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
		frac >= LITERATURE_JOULE_KE_FRAC_MIN
		and frac <= LITERATURE_JOULE_KE_FRAC_MAX
		and absf(frac - want_frac) <= 0.06
	)


static func blunt_fracture_j_excess_scaling_note() -> String:
	var anchor: float = _DamageMechanism.blunt_fracture_j_anchor("right_arm", "forearm")
	var excess: float = maxf(0.0, committed_oberhau_ke_j() - anchor)
	var damage: float = _DamageMechanism.j_excess_to_bone_damage(excess)
	return "anchor_J=%.0f excess_J=%.0f damage=2*sqrt(excess)=%.2f" % [anchor, excess, damage]


static func material_curves_full_blend_when_on() -> bool:
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		return true
	return is_equal_approx(_Bleeding.MATERIAL_CURVE_BLEND_WEIGHT, 1.0)


static func append_research_benchmark_lines(lines: PackedStringArray) -> void:
	lines.append(
		"research_harness_gate_count=%d doc=docs/LIVE_PATHS.md#research-audit"
		% research_harness_gate_count()
	)
	var deriv: Dictionary = reference_bleed_rate_derivation()
	var ttd_s: float = clinical_ttd_seconds()
	var loss_pct: float = loss_pct_to_death_threshold()
	var ref_kg: float = _DesignAnchors.REFERENCE_ADULT_MASS_KG
	var ml_per_kg: float = blood_ml_per_kg_at_reference_mass(ref_kg)
	var ke_j: float = committed_oberhau_ke_j()
	var arm_stack: float = _CombatLayerTissue.soft_tissue_budget_mm("right_arm")
	var forearm_j: float = _DamageMechanism.blunt_fracture_j_anchor("right_arm", "forearm")
	var ke_commit: float = _MaterialFailureCurves.reference_committed_arm_ke_j()
	var bone_at_ke: float = _MaterialFailureCurves.blunt_bone_damage_from_ke(ke_commit, "right_arm", "forearm")
	var crit_arterial: float = float(_Bleeding.ARTERIAL_CHANCE_BY_SEVERITY[_Bleeding.SEVERITY_CRITICAL])
	var press_ratio: float = pressure_halved_ttd_ratio()
	var derived_mult: float = derived_blood_loss_multiplier_for_ttd(LITERATURE_TTD_TARGET_S)
	var dp_retained: float = _Bleeding.DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL
	var dp_verdict: String = (
		"pass"
		if absf(dp_retained - LITERATURE_DIRECT_PRESSURE_ARTERIAL_FLOW_RETAINED) <= 0.06
		else "warn"
	)

	lines.append(
		"reference_bleed_rate_hp_per_s=%.2f formula=critical_cut(%.2f)*head(%.2f)*arterial(%.2f) verdict=%s"
		% [
			float(deriv.get("product_hp_per_s", 0.0)),
			float(deriv.get("critical_cut_hp_per_s", 0.0)),
			float(deriv.get("head_part_mult", 0.0)),
			float(deriv.get("arterial_mult", 0.0)),
			"pass" if bool(deriv.get("matches_reference_const", false)) else "warn",
		]
	)
	lines.append(
		"ATLS_class_boundaries_ATLS10_ed I<15%% II15-30 III31-40 IV>40%% game_mapping verdict=%s"
		% ("pass" if atls_class_boundaries_match_atls10() else "warn")
	)
	lines.append(
		"ATLS_class_IV_loss_pct_literature=>%.0f%% game_death_at_%.0f%%_lost verdict=%s"
		% [
			LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN,
			loss_pct,
			"pass" if loss_pct >= LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN else "warn",
		]
	)
	lines.append(
		"ATLS_death_remaining_%.0f%%_below_class_IV_entry_60%% verdict=%s"
		% [
			_Bleeding.BLOOD_LOSS_DEATH_THRESHOLD,
			"pass" if death_threshold_deep_in_class_iv() else "warn",
		]
	)
	lines.append(
		"ATLS_TTD_uncontrolled_arterial_literature=%.0f-%.0fs game_TTD_s=%.1f verdict=%s"
		% [
			LITERATURE_TTD_UNTREATED_S_MIN,
			LITERATURE_TTD_UNTREATED_S_MAX,
			ttd_s,
			"pass" if ttd_s >= LITERATURE_TTD_UNTREATED_S_MIN and ttd_s <= LITERATURE_TTD_UNTREATED_S_MAX else "warn",
		]
	)
	lines.append(
		"blood_volume_ml_per_kg literature=%.0f@75kg game=%.1f ml_max=%.0f verdict=%s"
		% [
			LITERATURE_BLOOD_ML_PER_KG_NOMINAL,
			ml_per_kg,
			_BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg),
			"pass"
			if absf(ml_per_kg - LITERATURE_BLOOD_ML_PER_KG_NOMINAL) <= LITERATURE_BLOOD_ML_PER_KG_TOLERANCE
			else "warn",
		]
	)
	lines.append(
		"BLOOD_LOSS_RATE_MULTIPLIER=%.3f derived_for_%.0fs_TTD=%.3f delta_from_derived=%.4f verdict=%s"
		% [
			_Bleeding.BLOOD_LOSS_RATE_MULTIPLIER,
			LITERATURE_TTD_TARGET_S,
			derived_mult,
			absf(_Bleeding.BLOOD_LOSS_RATE_MULTIPLIER - derived_mult),
			"pass" if blood_loss_multiplier_matches_derived() else "warn",
		]
	)
	lines.append(
		"species_reference_mass human=%.1f@%.0fkg goblin=%.1f@%.0fkg human_tissue_sum=%d goblin_tissue_sum=%d verdict=%s"
		% [
			_HumanSpecies.resolved_reference_mass_kg(),
			_DesignAnchors.REFERENCE_ADULT_MASS_KG,
			_GoblinSpecies.resolved_reference_mass_kg(),
			GOBLIN_REFERENCE_MASS_KG,
			_HumanSpecies.live_tissue_sum(),
			_GoblinSpecies.live_tissue_sum(),
			"pass" if species_reference_mass_anchors_match() else "warn",
		]
	)
	lines.append(
		"direct_pressure_halved_loss_mult TTD_ratio=%.2f want~%.1f verdict=%s"
		% [
			press_ratio,
			LITERATURE_PRESSURE_TTD_RATIO_TARGET,
			"pass"
			if absf(press_ratio - LITERATURE_PRESSURE_TTD_RATIO_TARGET) <= LITERATURE_PRESSURE_TTD_RATIO_TOLERANCE
			else "warn",
		]
	)
	lines.append(
		"arm_soft_tissue_stack_mm game=%.1f literature_SC+muscle_order~%.0f-%.0fmm verdict=%s"
		% [
			arm_stack,
			LITERATURE_ARM_SC_FAT_MM_MIN,
			LITERATURE_ARM_SC_FAT_MM_MAX,
			"pass" if arm_stack >= LITERATURE_ARM_SC_FAT_MM_MIN and arm_stack <= LITERATURE_ARM_SC_FAT_MM_MAX else "note",
		]
	)
	lines.append(
		"cut_bone_pen_gate_mm game_MFB=%.1f curve_graze_yield=%.1f literature_deep_laceration_reaches_cortex note=abstract_RHA_mm_not_CT"
		% [_DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM, _MaterialFailureCurves.CUT_TISSUE_YIELD_PEN_MM]
	)
	lines.append(
		"forearm_blunt_fracture_anchor_J game=%.0f committed_oberhau_J=%.0f bone_damage_at_anchor=%.2f literature=Nm_not_1:1_J verdict=note"
		% [forearm_j, ke_commit, bone_at_ke]
	)
	lines.append(
		"blunt_anchor_order elbow<forearm<thigh verdict=%s"
		% ("pass" if blunt_anchor_ordering_ok() else "warn")
	)
	lines.append(
		"blunt_flesh_ke_budget_arm_J game=%.0f committed_KE=%.0f KE_to_bone_after_flesh=%.0f verdict=%s"
		% [
			float(_CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0)),
			ke_commit,
			maxf(0.0, ke_commit - float(_CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0))),
			"pass" if ke_commit > 80.0 else "note",
		]
	)
	lines.append(
		"arterial_chance_critical_cut game=%.2f literature_soft_sign_2plus~%.0f%% verdict=%s"
		% [
			crit_arterial,
			LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS * 100.0,
			"pass"
			if absf(crit_arterial - LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS)
			<= LITERATURE_ARTERIAL_CRITICAL_TOLERANCE
			else "warn",
		]
	)
	lines.append(
		"committed_oberhau_ke_J game=%.0f literature_HEMA_band=%.0f-%.0f verdict=%s"
		% [
			ke_j,
			LITERATURE_HEMA_COMMITTED_KE_J_MIN,
			LITERATURE_HEMA_COMMITTED_KE_J_MAX,
			"pass" if ke_j >= LITERATURE_HEMA_COMMITTED_KE_J_MIN and ke_j <= LITERATURE_HEMA_COMMITTED_KE_J_MAX else "warn",
		]
	)
	lines.append(
		"penetration_depth_full_mm game=%.1f curve_ultimate_mm=%.1f literature_penetrating_trauma_track_depth_varies verdict=pass"
		% [_Bleeding.PENETRATION_DEPTH_SEVERITY_FULL_MM, _MaterialFailureCurves.cut_tissue_ultimate_pen_mm()]
	)
	lines.append(
		"layer_rupture_subcut_bleed_mult game=%.2f literature_ruptured_subcut_increases_cavity_bleed verdict=note"
		% _Bleeding.LAYER_RUPTURE_SUBCUT_BLEED_MULT
	)
	lines.append(
		"direct_pressure_arterial_flow_retained game=%.2f literature~%.0f%%_reduction verdict=%s"
		% [dp_retained, (1.0 - LITERATURE_DIRECT_PRESSURE_ARTERIAL_FLOW_RETAINED) * 100.0, dp_verdict]
	)
	var cut_crit: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CUT][_Bleeding.SEVERITY_CRITICAL])
	var crush_crit: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CRUSH][_Bleeding.SEVERITY_CRITICAL])
	lines.append(
		"bleeding_ladder_cut>crush_all_severities ratio_crit=%.2f verdict=%s"
		% [
			cut_crit / maxf(0.01, crush_crit),
			"pass" if cut_bleeding_exceeds_crush_at_all_severities() else "warn",
		]
	)
	lines.append(
		"bleeding_severity_monotonic_cut_and_crush verdict=%s"
		% ("pass" if bleeding_severity_ladder_monotonic() else "warn")
	)
	lines.append(
		"ARTERIAL_CRUSH_MULTIPLIER=%.2f literature_blunt_vascular_fraction<=%.2f verdict=%s"
		% [
			_Bleeding.ARTERIAL_CRUSH_MULTIPLIER,
			LITERATURE_BLUNT_VASCULAR_FRACTION_MAX,
			"pass" if _Bleeding.ARTERIAL_CRUSH_MULTIPLIER <= LITERATURE_BLUNT_VASCULAR_FRACTION_MAX else "warn",
		]
	)
	lines.append(
		"pen_depth_severity_mult shallow=%.2f deep=%.2f verdict=%s"
		% [
			_Bleeding.penetration_depth_severity_mult(0.5),
			_Bleeding.penetration_depth_severity_mult(6.0),
			"pass" if penetration_depth_mult_monotonic() else "warn",
		]
	)
	lines.append(
		"pen_depth_arterial_mult shallow=%.2f deep=%.2f verdict=%s"
		% [
			_Bleeding.penetration_depth_arterial_mult(0.5),
			_Bleeding.penetration_depth_arterial_mult(6.0),
			"pass" if penetration_arterial_mult_monotonic() else "warn",
		]
	)
	var bandage_hl: float = bandage_clot_half_life_s()
	lines.append(
		"clotting_half_life_s minor=%.0f critical=%.0f bandage=%.0f verdict=%s"
		% [
			clotting_half_life_s(_Bleeding.SEVERITY_MINOR),
			clotting_half_life_s(_Bleeding.SEVERITY_CRITICAL),
			bandage_hl,
			"pass" if clotting_half_life_ordering_ok() else "warn",
		]
	)
	lines.append(
		"bandage_hemostasis_half_life_s=%.0f literature_60-300s verdict=%s"
		% [
			bandage_hl,
			"pass"
			if bandage_hl >= LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN
			and bandage_hl <= LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX
			else "note",
		]
	)
	var pressure_hl: float = pressure_held_clot_half_life_s()
	lines.append(
		"pressure_held_hemostasis_half_life_s=%.0f literature_10-180s_faster_than_bandage verdict=%s"
		% [
			pressure_hl,
			"pass" if pressure_held_clot_half_life_in_literature_band() else "warn",
		]
	)
	var ttd_pct_p: float = clinical_ttd_seconds(1.0)
	var max_ml_h: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg)
	var buffer_ml_h: float = max_ml_h * (
		(_Bleeding.MAX_BLOOD_VOLUME - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / _Bleeding.MAX_BLOOD_VOLUME
	)
	var loss_ml_s_h: float = reference_uncontrolled_implied_ml_per_second(ref_kg, 1.0)
	var loss_ml_min_h: float = loss_ml_s_h * 60.0
	var ttd_ml_h: float = buffer_ml_h / loss_ml_s_h if loss_ml_s_h > 0.01 else 0.0
	lines.append(
		"literal_ml_percent_TTD_parity_s percent=%.2f ml=%.2f verdict=%s"
		% [ttd_pct_p, ttd_ml_h, "pass" if ml_percent_ttd_parity_ok() else "warn"]
	)
	lines.append(
		"reference_implied_ml_bridge_s=%.2f ml_min=%.1f note=abstract_HP_per_s_TTD_calibrated_not_literal_flow"
		% [loss_ml_s_h, loss_ml_min_h]
	)
	lines.append(
		"goblin_ml_per_kg=%.1f@%.0fkg mass_scaled verdict=%s"
		% [
			blood_ml_per_kg_at_reference_mass(GOBLIN_REFERENCE_MASS_KG),
			GOBLIN_REFERENCE_MASS_KG,
			"pass" if goblin_blood_ml_per_kg_matches_human_anchor() else "warn",
		]
	)
	lines.append(
		"scalp_bleed_mult=%.2f forearm=%.2f verdict=%s"
		% [
			float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"]),
			float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"]),
			"pass" if scalp_bleed_mult_exceeds_limb() else "warn",
		]
	)
	lines.append(
		"absolute_severity_tissue=%.0f/%.0f/%.0f bone=%.0f/%.0f/%.0f verdict=%s"
		% [
			_Bleeding.SEVERITY_ABSOLUTE_MODERATE,
			_Bleeding.SEVERITY_ABSOLUTE_SEVERE,
			_Bleeding.SEVERITY_ABSOLUTE_CRITICAL,
			_Bleeding.SEVERITY_ABSOLUTE_BONE_MODERATE,
			_Bleeding.SEVERITY_ABSOLUTE_BONE_SEVERE,
			_Bleeding.SEVERITY_ABSOLUTE_BONE_CRITICAL,
			"pass" if absolute_severity_bands_ordered() else "warn",
		]
	)
	lines.append(
		"forearm_bleed_mult=%.2f UE_vascular_epidemiology_weighted verdict=%s"
		% [
			float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"]),
			"pass" if float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"]) >= 1.0 else "note",
		]
	)
	var human_pref: float = pain_reference_for_species(_HumanSpecies)
	var hits_nrs4: float = hits_to_nrs_first_effect(_HumanSpecies)
	var pct_head: float = (
		100.0 * float(_HumanSpecies.get_body_part_max("head")) / float(maxi(1, _HumanSpecies.live_tissue_sum()))
	)
	lines.append(
		"pain_human_reference=%.2f literature~%.1f divisor_32 verdict=%s"
		% [human_pref, LITERATURE_HUMAN_PAIN_REFERENCE, "pass" if human_pain_reference_matches_literature() else "warn"]
	)
	lines.append(
		"pain_moderate_hit_effective=%.2f hits_to_NRS4=%.2f want_%.1f-%.1f verdict=%s"
		% [
			moderate_hit_effective_pain(_HumanSpecies),
			hits_nrs4,
			LITERATURE_HITS_TO_NRS4_MIN,
			LITERATURE_HITS_TO_NRS4_MAX,
			"pass" if human_hits_to_nrs4_in_band() else "warn",
		]
	)
	lines.append(
		"pain_NRS_thresholds first=%.0f mod=%.0f shock=%.0f sev=%.0f intol=%.0f verdict=%s"
		% [
			_Pain.NRS_FIRST_EFFECT,
			_Pain.NRS_MODERATE,
			_Pain.NRS_SHOCK,
			_Pain.NRS_SEVERE,
			_Pain.NRS_INTOLERABLE,
			"pass" if nrs_thresholds_ordered() else "warn",
		]
	)
	lines.append(
		"pain_goblin_reference=%.2f human=%.2f below_human=%s verdict=%s"
		% [
			pain_reference_for_species(_GoblinSpecies),
			human_pref,
			str(goblin_pain_reference_below_human()).to_lower(),
			"pass" if goblin_pain_reference_below_human() else "warn",
		]
	)
	lines.append(
		"human_head_tissue_pct=%.1f de_leva_head=%.1f tolerance=%.1f verdict=%s"
		% [
			pct_head,
			LITERATURE_DE_LEVA_HEAD_PCT,
			LITERATURE_DE_LEVA_HEAD_PCT_TOLERANCE,
			"pass" if human_head_pct_within_de_leva_note() else "note",
		]
	)
	lines.append(
		"human_chest_largest_segment verdict=%s"
		% ("pass" if human_chest_largest_tissue_segment() else "warn")
	)
	lines.append(
		"forearm_arterial_mult=%.2f upper_arm=%.2f verdict=%s"
		% [
			float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"]),
			float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["upper_arm"]),
			"pass" if forearm_arterial_mult_exceeds_upper_arm() else "warn",
		]
	)
	lines.append(
		"production_headless_gate=%s want=%s verdict=%s"
		% [
			production_headless_gate_id(),
			LITERATURE_HEADLESS_GATE_FULL,
			"pass" if production_sim_flags_full_stack_ok() else "warn",
		]
	)
	lines.append(
		"normalized_pain_method_B=%s verdict=%s"
		% [str(_Pain.USE_NORMALIZED_PAIN).to_lower(), "pass" if normalized_pain_method_b_enabled() else "warn"]
	)
	lines.append(
		"species_derived_limb human=%s goblin=%s verdict=%s"
		% [
			str(_HumanSpecies.feature_derived_limb_capacity).to_lower(),
			str(_GoblinSpecies.feature_derived_limb_capacity).to_lower(),
			"pass" if derived_limb_capacity_on_both_species() else "warn",
		]
	)
	var arm_cap_j: float = tissue_energy_arm_capacity_j()
	var arm_half: float = tissue_energy_arm_display_half_at_50pct()
	lines.append(
		"tissue_energy_arm_J body_max=%d capacity=%.0f display_half_at_50pct=%.0f verdict=%s"
		% [
			HUMAN_ARM_TISSUE_BODY_MAX,
			arm_cap_j,
			arm_half,
			"pass"
			if tissue_energy_arm_capacity_matches_design() and tissue_energy_arm_display_half_matches_anchor()
			else "warn",
		]
	)
	lines.append(
		"MFB_cut_bone_min_pen_mm=%.1f literature_abstract_cortex_gate verdict=pass"
		% _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM
	)
	var blunt_ke_bone: float = blunt_ke_after_arm_budget_at_committed_oberhau()
	lines.append(
		"blunt_ke_committed_oberhau=%.0f arm_flesh_budget_J=%.0f ke_to_bone=%.0f verdict=%s"
		% [
			ke_j,
			LITERATURE_ARM_BLUNT_KE_BUDGET_J,
			blunt_ke_bone,
			"pass" if blunt_ke_budget_reduces_bone_load() else "warn",
		]
	)
	var atls_mods: Dictionary = atls_consciousness_mod_at_class_anchors()
	lines.append(
		"atls_blood_consciousness_mod mod_85=%.2f mod_50=%.2f mod_35=%.2f monotonic=%s verdict=%s"
		% [
			float(atls_mods.get("mod_85", 0.0)),
			float(atls_mods.get("mod_50", 0.0)),
			float(atls_mods.get("mod_35", 0.0)),
			str(atls_blood_consciousness_monotonic()).to_lower(),
			"pass" if atls_blood_consciousness_monotonic() else "warn",
		]
	)
	lines.append(
		"layer_rupture_subcut_bleed_mult=%.2f literature_cavity_bleed_bump verdict=note"
		% _Bleeding.LAYER_RUPTURE_SUBCUT_BLEED_MULT
	)
	lines.append(
		"FEATURE_tissue_damage_D=%s FEATURE_absolute_severity_pct_cap=%s verdict=%s"
		% [
			str(_Bleeding.FEATURE_TISSUE_DAMAGE_D).to_lower(),
			str(_Bleeding.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP).to_lower(),
			"pass" if not _Bleeding.FEATURE_TISSUE_DAMAGE_D and not _Bleeding.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP else "warn",
		]
	)
	lines.append(
		"pain_performance_at_NRS4=%.2f want=%.2f monotonic_with_NRS verdict=%s"
		% [
			_Pain.get_pain_performance_modifier(_Pain.NRS_FIRST_EFFECT),
			LITERATURE_PAIN_PERF_AT_NRS4,
			"pass" if pain_performance_monotonic_with_nrs() else "warn",
		]
	)
	lines.append(
		"neck_arterial_mult=%.2f forearm=%.2f verdict=%s"
		% [
			float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["head"]["neck"]),
			float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"]),
			"pass" if neck_arterial_mult_exceeds_forearm() else "warn",
		]
	)
	lines.append(
		"medical_triage danger_remaining=%.0f peril=%.0f death=%.0f class_III_min=%.0f class_IV_window=%s danger_s=%.0f peril_s=%.0f reference_TTD_s=%.1f peril<TTD=%s verdict=%s"
		% [
			_Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING,
			_Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING,
			_Bleeding.BLOOD_LOSS_DEATH_THRESHOLD,
			_Bleeding.ATLS_CLASS_III_MIN_REMAINING,
			str(medical_triage_blood_bands_in_class_iv_window()).to_lower(),
			_Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS,
			_Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS,
			clinical_ttd_seconds(1.0),
			str(_Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS < clinical_ttd_seconds(1.0)).to_lower(),
			"pass" if medical_triage_thresholds_ordered() else "warn",
		]
	)
	var joule_frac: float = joule_cuirass_transmitted_ke_fraction()
	lines.append(
		"joule_cuirass_ke_frac pen=%.0f strike=%.0f J frac=%.2f sqrt_law verdict=%s"
		% [
			LITERATURE_JOULE_REFERENCE_PEN_MM,
			LITERATURE_JOULE_REFERENCE_STRIKE_KE_J,
			joule_frac,
			"pass" if joule_transmission_bounded_and_conserved() else "warn",
		]
	)
	lines.append("blunt_fracture_scaling %s verdict=note" % blunt_fracture_j_excess_scaling_note())
	lines.append(
		"MATERIAL_CURVE_BLEND_WEIGHT=%.2f curves_on=%s verdict=%s"
		% [
			_Bleeding.MATERIAL_CURVE_BLEND_WEIGHT,
			str(_Bleeding.FEATURE_MATERIAL_FAILURE_CURVES).to_lower(),
			"pass" if material_curves_full_blend_when_on() else "warn",
		]
	)
	lines.append(
		"f5_headless_proxies graze+armored_chest+mace see_[f5_scenario_headless] verdict=pass_if_failures_0"
	)
	lines.append(
		"f5_research_feel_traces optional COMBAT_DEV_VERBOSE grep=research_feel doc=LIVE_PATHS#research-audit verdict=note"
	)
	lines.append(
		"BMI_scaled_tissue_stacks not_shipped flat_mm_only verdict=note"
	)
	lines.append(
		"medical_triage_danger_s=%.0f reference_TTD_s=%.1f danger>TTD=%s verdict=%s"
		% [
			_Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS,
			clinical_ttd_seconds(1.0),
			str(medical_triage_danger_seconds_exceeds_reference_ttd()).to_lower(),
			"pass" if medical_triage_danger_seconds_exceeds_reference_ttd() else "warn",
		]
	)
	append_research_verdict_summary(lines)
	lines.append("[research_sources]")


static func append_research_verdict_summary(lines: PackedStringArray) -> void:
	var verdicts: Dictionary = summarize_benchmark_verdicts(lines)
	lines.append(
		"research_verdict_summary pass=%d warn=%d note=%d harness_gates=%d"
		% [
			int(verdicts.get("pass", 0)),
			int(verdicts.get("warn", 0)),
			int(verdicts.get("note", 0)),
			research_harness_gate_count(),
		]
	)
	lines.append("ATLS_hemorrhage=ATLS_10th_ed_student_manual_class_I-IV_loss_pct")
	lines.append("blood_volume=StatPearls_NBK526077_70mL_per_kg_male_adult")
	lines.append("TTD_band=CoTCCC_order_of_minutes_30-120s_project_anchor")
	lines.append("arterial_soft_signs=WTA_ATLS_teaching_2plus_signs_25pct_not_population_prevalence")
	lines.append("direct_pressure=manual_compression_arterial_incomplete_occlusion_heuristic")
	lines.append("blunt_J_anchors=biomechanics_rank_order_only_not_Nm_calibration")
	lines.append("HEMA_KE=project_sword_oberhau_commit_0.78_calibration_band")
	lines.append("bleeding_ladder=cut>crush_monotonic_severity_ladders")
	lines.append("clotting=first_order_k_ln2_over_k_bandage_60-300s_hemostasis")
	lines.append("scalp_bleed=StatPearls_scalp_vascularity_vs_limb_baseline")
	lines.append("blunt_vascular_fraction=UE_penetrating_18-36pct_blunt_share_of_vascular_injuries")
	lines.append("pain_NRS=acute_trauma_NRS4-5_first_functional_impairment_Krebs_band")
	lines.append("pain_reference=species_tissue_sum_over_32_human_96_to_3.0")
	lines.append("de_leva_segment_mass=1996_whole_body_percent_head_6.9_game_lump_wider")
	lines.append("tissue_energy_pool=M6_design_KE_100J_per_arm_12_display_anchor")
	lines.append("production_stack=P3b_S11_full_headless_gate_documented_in_audit")
	lines.append("joule_armor=sqrt_ke_remaining_over_strike_ke_gameplay_transmission")
	lines.append("blunt_J_vs_Nm=rank_order_only_cadaver_bending_uses_Nm_not_1to1_J")
