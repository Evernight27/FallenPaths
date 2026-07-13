class_name SimulationResearchTests
extends CombatRegressionHarnessCore
## Simulation realism track (S1 - S10): `_run_sim_*`  -  docs/LIVE_PATHS.md#harness-prefixes.

const HumanSpecies := preload("res://species/human.tres")
const GoblinSpecies := preload("res://species/goblin.tres")


static func _run_mat_energy_arm_capacity_anchor(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var body_max: int = CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
    var cap_j: float = TissueEnergyCapacity.capacity_j_for_part(part, body_max)
    if cap_j < 95.0 or cap_j > 105.0:
        SimulationCombatTests._fail(failures, "mat_energy: arm capacity_J %.0f want ~100" % cap_j)


## M6: display bridge 50% J -> ~50% display tissue.


## M6: display bridge 50% J -> ~50% display tissue.
static func _run_mat_energy_display_bridge(failures: PackedStringArray) -> void:
    var body_max: int = CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
    var cap_j: float = TissueEnergyCapacity.capacity_j_for_part("right_arm", body_max)
    var display: float = TissueEnergyCapacity.display_tissue_from_remaining_j(body_max, cap_j * 0.5, cap_j)
    if display < 5.0 or display > 7.0:
        SimulationCombatTests._fail(
            failures, "mat_energy: 50%% J display %.0f want ~6 (body_max %d)" % [display, body_max]
        )
    var rem_j: float = TissueEnergyCapacity.remaining_j_from_display_pools(body_max, 6.0, 6.0, cap_j)
    if rem_j < cap_j * 0.45 or rem_j > cap_j * 0.55:
        SimulationCombatTests._fail(
            failures, "mat_energy: round-trip J %.0f want ~%.0f from 6+6 display" % [rem_j, cap_j * 0.5]
        )


## M6: when production flag off, J dicts stay empty after apply_species.


## M6: when production flag off, J dicts stay empty after apply_species.
static func _run_mat_energy_flag_off_no_entity_fields(failures: PackedStringArray) -> void:
    if BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        return
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    if not ent.tissue_energy_capacity_j.is_empty() or not ent.tissue_energy_remaining_j.is_empty():
        SimulationCombatTests._fail(
            failures, "mat_energy: J pools should be empty when production flag off"
        )


## M6: J path debits internal reservoir and syncs display pools (production or force).


## M6: J path debits internal reservoir and syncs display pools (production or force).
static func _run_mat_energy_entity_j_path_debits_internal(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        return
    var part: String = "right_arm"
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var cap_before: float = float(ent.tissue_energy_capacity_j.get(part, 0.0))
    if cap_before < 1.0:
        cap_before = TissueEnergyCapacity.capacity_j_for_part(
            part, int(ent.body_max.get(part, CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY))
        )
    var extras: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
    var cut_before: float = float(ent.body_cutting.get(part, 0.0))
    var res: Dictionary = ent.take_damage_split(6.0, 2.0, part, 4.0, -1.0, -1.0, extras)
    if float(res.get("tissue_energy_remaining_j", -1.0)) < 0.0:
        SimulationCombatTests._fail(
            failures, "mat_energy_j_path: want tissue_energy_remaining_j on result"
        )
    var rem_after: float = float(ent.tissue_energy_remaining_j.get(part, 0.0))
    if rem_after >= cap_before - 0.5:
        SimulationCombatTests._fail(
            failures, "mat_energy_j_path: remaining_J %.1f should drop from %.1f after hit" % [rem_after, cap_before]
        )
    var cut_after: float = float(ent.body_cutting.get(part, 0.0))
    if cut_after >= cut_before - 0.01:
        SimulationCombatTests._fail(
            failures, "mat_energy_j_path: display cut %.1f should drop from %.1f" % [cut_after, cut_before]
        )


## M6: HP pool path (disable J) matches itself; production J path reproducible.


## M6: HP pool path (disable J) matches itself; production J path reproducible.
static func _run_mat_energy_entity_flag_off_matches_display_pools(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var extras: Dictionary = {
        "hit_sub_region": "forearm",
        "strike_ke_j": 12.0,
        "disable_layer_tissue": true,
    }
    var fail_tag: String = "mat_energy_flag_off"
    if BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        extras["disable_tissue_energy_pool"] = true
        fail_tag = "mat_energy_hp_path"
    var ent_a: Node = CombatRegressionHarness._new_entity("SWORD")
    var ent_b: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_a: Dictionary = ent_a.take_damage_split(5.0, 1.0, part, 3.0, -1.0, -1.0, extras)
    var res_b: Dictionary = ent_b.take_damage_split(5.0, 1.0, part, 3.0, -1.0, -1.0, extras.duplicate())
    for key: String in ["final_cut", "final_blunt", "final_bone"]:
        if absf(float(res_a.get(key, 0.0)) - float(res_b.get(key, 0.0))) > 0.02:
            SimulationCombatTests._fail(failures, "%s: %s diverged" % [fail_tag, key])


## Research gate: untreated arterial TTD in clinical 30 - 120 s band.


## Research gate: untreated arterial TTD in clinical 30 - 120 s band.
static func _run_research_clinical_ttd_band(failures: PackedStringArray) -> void:
    var ttd_s: float = BleedingConstants.seconds_to_exsanguination(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, BleedingConstants.MAX_BLOOD_VOLUME, 1.0
    )
    if ttd_s < 30.0 or ttd_s > 120.0:
        SimulationCombatTests._fail(
            failures, "research_ttd: %.1fs outside clinical 30-120s band" % ttd_s
        )


## Research gate: species `.tres` masses and human tissue sum match design anchors.


## Research gate: species `.tres` masses and human tissue sum match design anchors.
static func _run_research_species_reference_mass_anchors(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.species_reference_mass_anchors_match():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    (
                        "research_species_mass: human=%.1f@%.0f goblin=%.1f@%.0f "
                        + "human_tissue=%d@%d goblin_tissue=%d@[%d-%d] goblin_below_human=%s"
                    )
                    % [
                        HumanSpecies.resolved_reference_mass_kg(),
                        CombatDesignAnchors.REFERENCE_ADULT_MASS_KG,
                        GoblinSpecies.resolved_reference_mass_kg(),
                        CombatResearchAnchors.GOBLIN_REFERENCE_MASS_KG,
                        HumanSpecies.live_tissue_sum(),
                        CombatDesignAnchors.REFERENCE_HUMAN_TISSUE_SUM,
                        GoblinSpecies.live_tissue_sum(),
                        CombatResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MIN,
                        CombatResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MAX,
                        str(CombatResearchAnchors.goblin_mass_below_human()).to_lower(),
                    ]
                )
            )
        )


## Research gate: 75 kg male anchor = 70 mL/kg (5250 mL).


## Research gate: 75 kg male anchor = 70 mL/kg (5250 mL).
static func _run_research_blood_ml_nominal_70_per_kg(failures: PackedStringArray) -> void:
    var ref_kg: float = HumanSpecies.resolved_reference_mass_kg()
    var per_kg: float = CombatResearchAnchors.blood_ml_per_kg_at_reference_mass(ref_kg)
    var tol: float = CombatResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_TOLERANCE
    if absf(per_kg - CombatResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_NOMINAL) > tol:
        SimulationCombatTests._fail(
            failures,
            (
                "research_blood_ml: %.2f mL/kg want %.0f +/- %.1f"
                % [per_kg, CombatResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_NOMINAL, tol]
            )
        )
    if not is_equal_approx(
        BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg), BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT
    ):
        SimulationCombatTests._fail(
            failures, "research_blood_ml: pool max != REFERENCE_BLOOD_VOLUME_ML_ADULT"
        )


## Research gate: ATLS 10th ed. class boundaries from remaining %.


## Research gate: ATLS 10th ed. class boundaries from remaining %.
static func _run_research_atls_class_boundaries(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.atls_class_boundaries_match_atls10():
        SimulationCombatTests._fail(
            failures, "research_atls: remaining%% -> class mapping does not match ATLS 10 loss bands"
        )


## Research gate: BLOOD_LOSS_RATE_MULTIPLIER matches closed-form derivation for 48 s TTD.


## Research gate: BLOOD_LOSS_RATE_MULTIPLIER matches closed-form derivation for 48 s TTD.
static func _run_research_blood_loss_multiplier_derived(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.blood_loss_multiplier_matches_derived():
        var derived: float = CombatResearchAnchors.derived_blood_loss_multiplier_for_ttd(
            CombatResearchAnchors.LITERATURE_TTD_TARGET_S
        )
        SimulationCombatTests._fail(
            failures,
            (
                "research_mult: shipped %.4f vs derived %.4f for %.0fs TTD"
                % [BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER, derived, CombatResearchAnchors.LITERATURE_TTD_TARGET_S]
            )
        )


## Research gate: REFERENCE_UNCONTROLLED_BLEED_RATE equals documented product (not a magic constant).


## Research gate: REFERENCE_UNCONTROLLED_BLEED_RATE equals documented product (not a magic constant).
static func _run_research_reference_bleed_derivation(failures: PackedStringArray) -> void:
    var deriv: Dictionary = CombatResearchAnchors.reference_bleed_rate_derivation()
    if not bool(deriv.get("matches_reference_const", false)):
        SimulationCombatTests._fail(
            failures,
            (
                "research_bleed_deriv: product %.2f != REFERENCE %.2f"
                % [float(deriv.get("product_hp_per_s", 0.0)), BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE]
            )
        )
    if not bool(deriv.get("multiplier_matches_derived", false)):
        SimulationCombatTests._fail(
            failures, "research_bleed_deriv: shipped multiplier diverges from 48s TTD derivation"
        )
    var ttd_s: float = float(deriv.get("clinical_ttd_s", 0.0))
    if ttd_s < 30.0 or ttd_s > 120.0:
        SimulationCombatTests._fail(
            failures, "research_bleed_deriv: calibrated TTD %.1fs outside 30-120s" % ttd_s
        )
    if not bool(deriv.get("ml_ttd_parity_ok", false)):
        SimulationCombatTests._fail(
            failures, "research_bleed_deriv: percent and mL TTD paths diverge at reference bleed"
        )


## Research gate: death threshold at or beyond ATLS Class IV (>40% loss).


## Research gate: death threshold at or beyond ATLS Class IV (>40% loss).
static func _run_research_atls_death_threshold(failures: PackedStringArray) -> void:
    var loss_pct: float = CombatResearchAnchors.loss_pct_to_death_threshold()
    if loss_pct < CombatResearchAnchors.LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN:
        SimulationCombatTests._fail(
            failures,
            (
                "research_atls_death: loss to death %.0f%% below literature %.0f%%"
                % [loss_pct, CombatResearchAnchors.LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN]
            )
        )
    if not CombatResearchAnchors.death_threshold_deep_in_class_iv():
        SimulationCombatTests._fail(
            failures, "research_atls_death: death threshold should be below 60%% remaining (Class IV entry)"
        )


## Research gate: critical cut arterial chance near penetrating vascular soft-sign literature (~25%).


## Research gate: critical cut arterial chance near penetrating vascular soft-sign literature (~25%).
static func _run_research_arterial_chance_literature(failures: PackedStringArray) -> void:
    var game: float = float(BleedingConstants.ARTERIAL_CHANCE_BY_SEVERITY[BleedingConstants.SEVERITY_CRITICAL])
    if (
        absf(game - CombatResearchAnchors.LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS)
        > CombatResearchAnchors.LITERATURE_ARTERIAL_CRITICAL_TOLERANCE
    ):
        SimulationCombatTests._fail(
            failures,
            (
                "research_arterial: critical chance %.2f want ~%.2f (2+ soft signs teaching)"
                % [game, CombatResearchAnchors.LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS]
            )
        )


## Research gate: distal blunt tolerance < proximal (biomechanics ordering).


## Research gate: distal blunt tolerance < proximal (biomechanics ordering).
static func _run_research_blunt_anchor_ordering(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.blunt_anchor_ordering_ok():
        SimulationCombatTests._fail(
            failures, "research_blunt_order: want elbow < forearm < thigh J anchors"
        )


## Research gate: committed oberhau KE in HEMA calibration band.


## Research gate: committed oberhau KE in HEMA calibration band.
static func _run_research_committed_ke_hema_band(failures: PackedStringArray) -> void:
    var ke_j: float = CombatResearchAnchors.committed_oberhau_ke_j()
    if (
        ke_j < CombatResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MIN
        or ke_j > CombatResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MAX
    ):
        SimulationCombatTests._fail(
            failures,
            (
                "research_hema_ke: %.0f J outside %.0f-%.0f"
                % [
                    ke_j,
                    CombatResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MIN,
                    CombatResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MAX
                ]
            )
        )


## Research gate: loss_mult 0.5 ~= doubles TTD (direct pressure heuristic).


## Research gate: loss_mult 0.5 ~= doubles TTD (direct pressure heuristic).
static func _run_research_direct_pressure_ttd_halving(failures: PackedStringArray) -> void:
    var ratio: float = CombatResearchAnchors.pressure_halved_ttd_ratio()
    if (
        absf(ratio - CombatResearchAnchors.LITERATURE_PRESSURE_TTD_RATIO_TARGET)
        > CombatResearchAnchors.LITERATURE_PRESSURE_TTD_RATIO_TOLERANCE
    ):
        SimulationCombatTests._fail(
            failures,
            (
                "research_pressure_ttd: halved-loss TTD ratio %.2f want ~%.1f"
                % [ratio, CombatResearchAnchors.LITERATURE_PRESSURE_TTD_RATIO_TARGET]
            )
        )


## Research gate: cut bleed rates exceed crush at every severity; ladders monotonic.


## Research gate: cut bleed rates exceed crush at every severity; ladders monotonic.
static func _run_research_bleeding_ladder_monotonic(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.cut_bleeding_exceeds_crush_at_all_severities():
        SimulationCombatTests._fail(
            failures, "research_bleed_ladder: cut rates must exceed crush at all severities"
        )
    if not CombatResearchAnchors.bleeding_severity_ladder_monotonic():
        SimulationCombatTests._fail(
            failures, "research_bleed_ladder: minor<moderate<severe<critical within cut and crush"
        )


## Research gate: shallow penetration < deep for severity and arterial mults.


## Research gate: shallow penetration < deep for severity and arterial mults.
static func _run_research_pen_depth_monotonic(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY:
        SimulationCombatTests._fail(
            failures, "research_pen_depth: FEATURE_PENETRATION_DEPTH_SEVERITY must be on"
        )
    if not CombatResearchAnchors.penetration_depth_mult_monotonic():
        SimulationCombatTests._fail(
            failures, "research_pen_depth: severity mult must rise shallow->deep"
        )
    if not CombatResearchAnchors.penetration_arterial_mult_monotonic():
        SimulationCombatTests._fail(
            failures, "research_pen_depth: arterial mult must rise shallow->deep"
        )


## Research gate: clotting half-life increases with wound severity; bandage in 60 - 300 s band.


## Research gate: clotting half-life increases with wound severity; bandage in 60 - 300 s band.
static func _run_research_clotting_half_life_order(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.clotting_half_life_ordering_ok():
        SimulationCombatTests._fail(failures, "research_clot: half-life must increase minor->critical")
    var bandage_hl: float = CombatResearchAnchors.bandage_clot_half_life_s()
    if (
        bandage_hl < CombatResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN
        or bandage_hl > CombatResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX
    ):
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_clot: bandage half-life %.0fs outside %.0f-%.0fs"
                    % [
                        bandage_hl,
                        CombatResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN,
                        CombatResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX,
                    ]
                )
            )
        )


## Research gate: literal mL TTD matches percent-scale TTD at 75 kg (FEATURE_LITERAL_BLOOD_ML).


## Research gate: literal mL TTD matches percent-scale TTD at 75 kg (FEATURE_LITERAL_BLOOD_ML).
static func _run_research_ml_percent_ttd_parity(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        SimulationCombatTests._fail(
            failures, "research_ml_ttd: FEATURE_LITERAL_BLOOD_ML must be on for parity gate"
        )
    if not CombatResearchAnchors.ml_percent_ttd_parity_ok():
        SimulationCombatTests._fail(
            failures, "research_ml_ttd: percent and mL exsanguination paths diverge at reference mass"
        )


## Research gate: implied mL bridge helper matches BloodVolumeMl and stays positive at reference mass.


## Research gate: implied mL bridge helper matches BloodVolumeMl and stays positive at reference mass.
static func _run_research_implied_ml_bridge(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        return
    var ref_kg: float = CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
    var max_ml: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg)
    var want: float = BloodVolumeMl.blood_ml_loss_per_second(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, max_ml, 1.0
    )
    var got: float = CombatResearchAnchors.reference_uncontrolled_implied_ml_per_second(ref_kg, 1.0)
    if want <= 0.01 or got <= 0.01:
        SimulationCombatTests._fail(
            failures, "research_implied_ml_bridge: implied loss must be positive at reference bleed"
        )
    elif not is_equal_approx(want, got):
        SimulationCombatTests._fail(
            failures, "research_implied_ml_bridge: helper %.3f != BloodVolumeMl %.3f" % [got, want]
        )


## Research gate: goblin mass-scaled pool preserves 70 mL/kg anchor.


## Research gate: goblin mass-scaled pool preserves 70 mL/kg anchor.
static func _run_research_goblin_blood_ml_per_kg(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.goblin_blood_ml_per_kg_matches_human_anchor():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_goblin_blood: mL/kg must match %.0f +/- %.1f at %.0f kg"
                    % [
                        CombatResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_NOMINAL,
                        CombatResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_TOLERANCE,
                        CombatResearchAnchors.GOBLIN_REFERENCE_MASS_KG,
                    ]
                )
            )
        )


## Research gate: scalp bleed mult exceeds limb baseline (vascular scalp literature).


## Research gate: scalp bleed mult exceeds limb baseline (vascular scalp literature).
static func _run_research_scalp_vs_limb_bleed(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.scalp_bleed_mult_exceeds_limb():
        SimulationCombatTests._fail(
            failures, "research_scalp: scalp multiplier must exceed forearm and be >= 1.4"
        )


## Research gate: absolute tissue/bone severity thresholds ordered.


## Research gate: absolute tissue/bone severity thresholds ordered.
static func _run_research_absolute_severity_bands(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.absolute_severity_bands_ordered():
        SimulationCombatTests._fail(
            failures, "research_abs_severity: tissue and bone absolute bands must be strictly ordered"
        )


## Research gate: human auto pain_reference ~= 3.0 (tissue_sum/32).


## Research gate: human auto pain_reference ~= 3.0 (tissue_sum/32).
static func _run_research_pain_human_reference(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.human_pain_reference_matches_literature():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_pain_ref: human %.3f want %.1f +/- %.2f"
                    % [
                        CombatResearchAnchors.pain_reference_for_species(HumanSpecies),
                        CombatResearchAnchors.LITERATURE_HUMAN_PAIN_REFERENCE,
                        CombatResearchAnchors.LITERATURE_HUMAN_PAIN_REFERENCE_TOLERANCE,
                    ]
                )
            )
        )


## Research gate: ~2 moderate hits to reach NRS 4 (first functional impairment).


## Research gate: ~2 moderate hits to reach NRS 4 (first functional impairment).
static func _run_research_pain_hits_to_nrs4(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.human_hits_to_nrs4_in_band():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_pain_nrs4: human hits_to_NRS4=%.2f want %.1f-%.1f"
                    % [
                        CombatResearchAnchors.hits_to_nrs_first_effect(HumanSpecies),
                        CombatResearchAnchors.LITERATURE_HITS_TO_NRS4_MIN,
                        CombatResearchAnchors.LITERATURE_HITS_TO_NRS4_MAX,
                    ]
                )
            )
        )


## Research gate: NRS thresholds strictly ordered (4 < 6 < 7 < 8 < 10).


## Research gate: NRS thresholds strictly ordered (4 < 6 < 7 < 8 < 10).
static func _run_research_pain_nrs_thresholds_ordered(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.nrs_thresholds_ordered():
        SimulationCombatTests._fail(
            failures, "research_pain_nrs: NRS thresholds must be strictly ordered"
        )


## Research gate: smaller goblin tissue sum -> lower pain_reference (more pain per hit).


## Research gate: smaller goblin tissue sum -> lower pain_reference (more pain per hit).
static func _run_research_pain_goblin_below_human(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.goblin_pain_reference_below_human():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_pain_goblin: goblin ref %.3f must be below human %.3f"
                    % [
                        CombatResearchAnchors.pain_reference_for_species(GoblinSpecies),
                        CombatResearchAnchors.pain_reference_for_species(HumanSpecies),
                    ]
                )
            )
        )


## Research gate: forearm arterial mult > upper_arm (UE penetrating vascular epidemiology).


## Research gate: forearm arterial mult > upper_arm (UE penetrating vascular epidemiology).
static func _run_research_forearm_arterial_epidemiology(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.forearm_arterial_mult_exceeds_upper_arm():
        SimulationCombatTests._fail(
            failures, "research_forearm_arterial: forearm mult must exceed upper_arm and be >= 1.1"
        )


## Research gate: human chest largest tissue segment (gameplay mass proportions).


## Research gate: human chest largest tissue segment (gameplay mass proportions).
static func _run_research_human_chest_largest_segment(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.human_chest_largest_tissue_segment():
        SimulationCombatTests._fail(
            failures, "research_anatomy: human chest must be largest tissue segment"
        )


## Research gate: post-S11 full production headless gate id.


## Research gate: post-S11 full production headless gate id.
static func _run_research_production_full_stack_gate(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.production_sim_flags_full_stack_ok():
        SimulationCombatTests._fail(
            failures,
            (
                "research_production_gate: got %s want %s"
                % [
                    CombatResearchAnchors.production_headless_gate_id(),
                    CombatResearchAnchors.LITERATURE_HEADLESS_GATE_FULL
                ]
            )
        )


## Research gate: M6 arm tissue J capacity ~100 @ body_max 12; display half ~6 at 50%% J.


## Research gate: M6 arm tissue J capacity ~100 @ body_max 12; display half ~6 at 50%% J.
static func _run_research_tissue_energy_arm_anchor(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        SimulationCombatTests._fail(
            failures, "research_tissue_energy: FEATURE_TISSUE_ENERGY_POOL must be on"
        )
    if not CombatResearchAnchors.tissue_energy_arm_capacity_matches_design():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_tissue_energy: arm capacity %.0f J want %.0f +/- %.0f"
                    % [
                        CombatResearchAnchors.tissue_energy_arm_capacity_j(),
                        CombatResearchAnchors.LITERATURE_ARM_TISSUE_CAPACITY_J,
                        CombatResearchAnchors.LITERATURE_ARM_CAPACITY_J_TOLERANCE,
                    ]
                )
            )
        )
    if not CombatResearchAnchors.tissue_energy_arm_display_half_matches_anchor():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_tissue_energy: display half at 50%% J=%.0f want %.0f +/- %.0f"
                    % [
                        CombatResearchAnchors.tissue_energy_arm_display_half_at_50pct(),
                        CombatResearchAnchors.LITERATURE_ARM_DISPLAY_HALF_J,
                        CombatResearchAnchors.LITERATURE_ARM_DISPLAY_HALF_TOLERANCE,
                    ]
                )
            )
        )


## Research gate: Method B normalized pain is canonical.


## Research gate: Method B normalized pain is canonical.
static func _run_research_normalized_pain_method_b(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.normalized_pain_method_b_enabled():
        SimulationCombatTests._fail(failures, "research_pain: USE_NORMALIZED_PAIN must be true")


## Research gate: S5 derived limb pilot on human and goblin species resources.


## Research gate: S5 derived limb pilot on human and goblin species resources.
static func _run_research_derived_limb_species_flags(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.derived_limb_capacity_on_both_species():
        SimulationCombatTests._fail(
            failures, "research_derived_limb: human and goblin feature_derived_limb_capacity must be true"
        )


## Research gate: blunt flesh KE budget reduces KE reaching bone at committed oberhau.


## Research gate: blunt flesh KE budget reduces KE reaching bone at committed oberhau.
static func _run_research_blunt_ke_budget_reduces_bone(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_BLUNT_TISSUE_KE_GATE:
        SimulationCombatTests._fail(
            failures, "research_blunt_ke: FEATURE_BLUNT_TISSUE_KE_GATE must be on"
        )
    if not CombatResearchAnchors.blunt_ke_budget_reduces_bone_load():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_blunt_ke: ke_to_bone %.0f should be < committed %.0f minus budget"
                    % [
                        CombatResearchAnchors.blunt_ke_after_arm_budget_at_committed_oberhau(),
                        CombatResearchAnchors.committed_oberhau_ke_j(),
                    ]
                )
            )
        )


## Research gate: ATLS stepped blood consciousness modifier decreases with volume loss.


## Research gate: ATLS stepped blood consciousness modifier decreases with volume loss.
static func _run_research_atls_blood_consciousness_monotonic(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS:
        SimulationCombatTests._fail(
            failures, "research_atls_consciousness: FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS must be on"
        )
    if not CombatResearchAnchors.atls_blood_consciousness_monotonic():
        SimulationCombatTests._fail(
            failures, "research_atls_consciousness: modifier must decrease 100%%->35%% remaining"
        )


## Research gate: pain performance decreases at NRS 4/6/8; -8% at first effect.


## Research gate: pain performance decreases at NRS 4/6/8; -8% at first effect.
static func _run_research_pain_performance_nrs_bands(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.pain_performance_monotonic_with_nrs():
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "research_pain_perf: modifier at NRS4=%.3f want ~%.2f and monotonic bands"
                    % [
                        PainConsciousnessConstants.get_pain_performance_modifier(
                            PainConsciousnessConstants.NRS_FIRST_EFFECT
                        ),
                        CombatResearchAnchors.LITERATURE_PAIN_PERF_AT_NRS4,
                    ]
                )
            )
        )


## Research gate: neck arterial mult > forearm (penetrating neck vascular risk).


## Research gate: neck arterial mult > forearm (penetrating neck vascular risk).
static func _run_research_neck_arterial_epidemiology(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.neck_arterial_mult_exceeds_forearm():
        SimulationCombatTests._fail(failures, "research_neck_arterial: neck mult must exceed forearm")


## Research gate: triage danger > peril > death threshold; danger time > peril time.


## Research gate: triage danger > peril > death threshold; danger time > peril time.
static func _run_research_medical_triage_thresholds(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.medical_triage_thresholds_ordered():
        SimulationCombatTests._fail(
            failures,
            (
                "research_triage: danger>peril>death; class_IV_window; peril_s=%.0f < reference_TTD=%.1fs"
                % [BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS, CombatResearchAnchors.clinical_ttd_seconds(1.0)]
            )
        )


## Research gate: joule armor KE conserved; transmitted fraction = sqrt(remaining/strike).


## Research gate: joule armor KE conserved; transmitted fraction = sqrt(remaining/strike).
static func _run_research_joule_sqrt_transmission(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        SimulationCombatTests._fail(failures, "research_joule: FEATURE_JOULE_ARMOR_BUDGET must be on")
    if not CombatResearchAnchors.joule_transmission_bounded_and_conserved():
        SimulationCombatTests._fail(
            failures,
            (
                "research_joule: cuirass frac %.3f must match sqrt law and lie in 0.15-0.85"
                % CombatResearchAnchors.joule_cuirass_transmitted_ke_fraction()
            )
        )


## Research gate: material curves on -> full blend weight 1.0 (M2 production).


## Research gate: material curves on -> full blend weight 1.0 (M2 production).
static func _run_research_material_curve_full_blend(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        SimulationCombatTests._fail(
            failures, "research_mat_curve: FEATURE_MATERIAL_FAILURE_CURVES must be on"
        )
    if not CombatResearchAnchors.material_curves_full_blend_when_on():
        SimulationCombatTests._fail(
            failures,
            (
                "research_mat_curve: MATERIAL_CURVE_BLEND_WEIGHT %.2f want 1.0 when curves on"
                % BleedingConstants.MATERIAL_CURVE_BLEND_WEIGHT
            )
        )


## Research gate: registry count matches documented RESEARCH_HARNESS_GATE_IDS (drift guard).


## Research gate: registry count matches documented RESEARCH_HARNESS_GATE_IDS (drift guard).
static func _run_research_gate_registry_count(failures: PackedStringArray) -> void:
    var want: int = CombatResearchAnchors.research_harness_gate_count()
    if want < 1:
        SimulationCombatTests._fail(failures, "research_registry: RESEARCH_HARNESS_GATE_IDS is empty")
    # Meta-gate: when adding `_run_research_*`, append id to RESEARCH_HARNESS_GATE_IDS + checklist table.
    var expected_research_gates: int = 37
    if want != expected_research_gates:
        SimulationCombatTests._fail(
            failures,
            "research_registry: RESEARCH_HARNESS_GATE_IDS count %d != expected %d" % [want, expected_research_gates]
        )


## Research gate: triage danger window (90 s) exceeds reference exsanguination TTD (~48 s).


## Research gate: triage danger window (90 s) exceeds reference exsanguination TTD (~48 s).
static func _run_research_triage_danger_seconds_vs_ttd(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.medical_triage_danger_seconds_exceeds_reference_ttd():
        SimulationCombatTests._fail(
            failures,
            (
                "research_triage: DANGER_SECONDS %.0f should exceed reference TTD %.1fs"
                % [BleedingConstants.MEDICAL_TRIAGE_DANGER_SECONDS, CombatResearchAnchors.clinical_ttd_seconds(1.0)]
            )
        )


## F5 headless proxy: shallow forearm graze  -  no bone, tissue pen shallow.


## F5 headless proxy: shallow forearm graze  -  no bone, tissue pen shallow.
static func _run_f5_headless_forearm_graze(failures: PackedStringArray) -> void:
    var m: Dictionary = CombatCalibrationAudit.f5_forearm_graze_metrics()
    if float(m.get("final_bone", 0.0)) >= 0.01:
        SimulationCombatTests._fail(
            failures, "f5_graze: final_bone %.2f should be 0" % float(m.get("final_bone", 0.0))
        )
    if float(m.get("final_cut", 0.0)) <= 0.0:
        SimulationCombatTests._fail(failures, "f5_graze: want tissue cut damage on graze")
    if float(m.get("penetration_to_tissue_mm", 99.0)) > 1.5:
        SimulationCombatTests._fail(
            failures, "f5_graze: tissue pen %.2f too deep for graze" % float(m.get("penetration_to_tissue_mm", 0.0))
        )


## F5 headless proxy: cuirass reduces chest penetration or total damage.


## F5 headless proxy: cuirass reduces chest penetration or total damage.
static func _run_f5_headless_armored_chest(failures: PackedStringArray) -> void:
    var m: Dictionary = CombatCalibrationAudit.f5_armored_chest_metrics()
    var bare_pen: float = float(m.get("bare_tissue_pen_mm", 0.0))
    var arm_pen: float = float(m.get("armored_tissue_pen_mm", 0.0))
    var bare_dmg: float = float(m.get("bare_damage_sum", 0.0))
    var arm_dmg: float = float(m.get("armored_damage_sum", 0.0))
    if arm_pen >= bare_pen - 0.01 and not bool(m.get("armor_stopped", false)):
        SimulationCombatTests._fail(
            failures, "f5_armored: armored pen %.2f should be < bare %.2f" % [arm_pen, bare_pen]
        )
    if arm_dmg >= bare_dmg - 0.5:
        SimulationCombatTests._fail(
            failures, "f5_armored: armored damage %.1f should be < bare %.1f" % [arm_dmg, bare_dmg]
        )


## F5 headless proxy: mace elbow blunt fracture at KE above anchor.


## F5 headless proxy: mace elbow blunt fracture at KE above anchor.
static func _run_f5_headless_mace_elbow(failures: PackedStringArray) -> void:
    var m: Dictionary = CombatCalibrationAudit.f5_mace_elbow_metrics()
    if float(m.get("final_bone", 0.0)) < 0.5:
        SimulationCombatTests._fail(
            failures,
            (
                "f5_mace_elbow: final_bone %.2f want >=0.5 at KE %.0f"
                % [float(m.get("final_bone", 0.0)), float(m.get("strike_ke_j", 0.0))]
            )
        )
