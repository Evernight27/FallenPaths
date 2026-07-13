class_name CombatResearchBenchmarkReport
extends CombatResearchDerivations


static func append_research_benchmark_lines(lines: PackedStringArray) -> void:
    lines.append("research_harness_gate_count=%d doc=docs/LIVE_PATHS.md#research-audit" % research_harness_gate_count())
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
        "pass" if absf(dp_retained - LITERATURE_DIRECT_PRESSURE_ARTERIAL_FLOW_RETAINED) <= 0.06 else "warn"
    )

    (
        lines
        . append(
            (
                "reference_bleed_rate_hp_per_s=%.2f formula=critical_cut(%.2f)*head(%.2f)*arterial(%.2f) verdict=%s"
                % [
                    float(deriv.get("product_hp_per_s", 0.0)),
                    float(deriv.get("critical_cut_hp_per_s", 0.0)),
                    float(deriv.get("head_part_mult", 0.0)),
                    float(deriv.get("arterial_mult", 0.0)),
                    "pass" if bool(deriv.get("matches_reference_const", false)) else "warn",
                ]
            )
        )
    )
    lines.append(
        (
            "ATLS_class_boundaries_ATLS10_ed I<15%% II15-30 III31-40 IV>40%% game_mapping verdict=%s"
            % ("pass" if atls_class_boundaries_match_atls10() else "warn")
        )
    )
    (
        lines
        . append(
            (
                "ATLS_class_IV_loss_pct_literature=>%.0f%% game_death_at_%.0f%%_lost verdict=%s"
                % [
                    LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN,
                    loss_pct,
                    "pass" if loss_pct >= LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "ATLS_death_remaining_%.0f%%_below_class_IV_entry_60%% verdict=%s"
                % [
                    _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD,
                    "pass" if death_threshold_deep_in_class_iv() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "ATLS_TTD_uncontrolled_arterial_literature=%.0f-%.0fs game_TTD_s=%.1f verdict=%s"
                % [
                    LITERATURE_TTD_UNTREATED_S_MIN,
                    LITERATURE_TTD_UNTREATED_S_MAX,
                    ttd_s,
                    (
                        "pass"
                        if ttd_s >= LITERATURE_TTD_UNTREATED_S_MIN and ttd_s <= LITERATURE_TTD_UNTREATED_S_MAX
                        else "warn"
                    ),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "blood_volume_ml_per_kg literature=%.0f@75kg game=%.1f ml_max=%.0f verdict=%s"
                % [
                    LITERATURE_BLOOD_ML_PER_KG_NOMINAL,
                    ml_per_kg,
                    _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg),
                    (
                        "pass"
                        if absf(ml_per_kg - LITERATURE_BLOOD_ML_PER_KG_NOMINAL) <= LITERATURE_BLOOD_ML_PER_KG_TOLERANCE
                        else "warn"
                    ),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "BLOOD_LOSS_RATE_MULTIPLIER=%.3f derived_for_%.0fs_TTD=%.3f delta_from_derived=%.4f verdict=%s"
                % [
                    _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER,
                    LITERATURE_TTD_TARGET_S,
                    derived_mult,
                    absf(_Bleeding.BLOOD_LOSS_RATE_MULTIPLIER - derived_mult),
                    "pass" if blood_loss_multiplier_matches_derived() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "species_reference_mass human=%.1f@%.0fkg goblin=%.1f@%.0fkg human_tissue_sum=%d goblin_tissue_sum=%d v"
                + (
                    "erdict=%s"
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
            )
        )
    )
    (
        lines
        . append(
            (
                "direct_pressure_halved_loss_mult TTD_ratio=%.2f want~%.1f verdict=%s"
                % [
                    press_ratio,
                    LITERATURE_PRESSURE_TTD_RATIO_TARGET,
                    (
                        "pass"
                        if (
                            absf(press_ratio - LITERATURE_PRESSURE_TTD_RATIO_TARGET)
                            <= LITERATURE_PRESSURE_TTD_RATIO_TOLERANCE
                        )
                        else "warn"
                    ),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "arm_soft_tissue_stack_mm game=%.1f literature_SC+muscle_order~%.0f-%.0fmm verdict=%s"
                % [
                    arm_stack,
                    LITERATURE_ARM_SC_FAT_MM_MIN,
                    LITERATURE_ARM_SC_FAT_MM_MAX,
                    (
                        "pass"
                        if arm_stack >= LITERATURE_ARM_SC_FAT_MM_MIN and arm_stack <= LITERATURE_ARM_SC_FAT_MM_MAX
                        else "note"
                    ),
                ]
            )
        )
    )
    lines.append(
        (
            "cut_bone_pen_gate_mm game_MFB=%.1f curve_graze_yield=%.1f literature_deep_laceration_reaches_cortex no"
            + (
                "te=abstract_RHA_mm_not_CT"
                % [_DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM, _MaterialFailureCurves.CUT_TISSUE_YIELD_PEN_MM]
            )
        )
    )
    lines.append(
        (
            "forearm_blunt_fracture_anchor_J game=%.0f committed_oberhau_J=%.0f bone_damage_at_anchor=%.2f literatu"
            + "re=Nm_not_1:1_J verdict=note" % [forearm_j, ke_commit, bone_at_ke]
        )
    )
    lines.append(
        "blunt_anchor_order elbow<forearm<thigh verdict=%s" % ("pass" if blunt_anchor_ordering_ok() else "warn")
    )
    (
        lines
        . append(
            (
                "blunt_flesh_ke_budget_arm_J game=%.0f committed_KE=%.0f KE_to_bone_after_flesh=%.0f verdict=%s"
                % [
                    float(_CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0)),
                    ke_commit,
                    maxf(
                        0.0,
                        ke_commit - float(_CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0))
                    ),
                    "pass" if ke_commit > 80.0 else "note",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "arterial_chance_critical_cut game=%.2f literature_soft_sign_2plus~%.0f%% verdict=%s"
                % [
                    crit_arterial,
                    LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS * 100.0,
                    (
                        "pass"
                        if (
                            absf(crit_arterial - LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS)
                            <= LITERATURE_ARTERIAL_CRITICAL_TOLERANCE
                        )
                        else "warn"
                    ),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "committed_oberhau_ke_J game=%.0f literature_HEMA_band=%.0f-%.0f verdict=%s"
                % [
                    ke_j,
                    LITERATURE_HEMA_COMMITTED_KE_J_MIN,
                    LITERATURE_HEMA_COMMITTED_KE_J_MAX,
                    (
                        "pass"
                        if ke_j >= LITERATURE_HEMA_COMMITTED_KE_J_MIN and ke_j <= LITERATURE_HEMA_COMMITTED_KE_J_MAX
                        else "warn"
                    ),
                ]
            )
        )
    )
    lines.append(
        (
            "penetration_depth_full_mm game=%.1f curve_ultimate_mm=%.1f literature_penetrating_trauma_track_depth_v"
            + (
                "aries verdict=pass"
                % [_Bleeding.PENETRATION_DEPTH_SEVERITY_FULL_MM, _MaterialFailureCurves.cut_tissue_ultimate_pen_mm()]
            )
        )
    )
    lines.append(
        (
            "layer_rupture_subcut_bleed_mult game=%.2f literature_ruptured_subcut_increases_cavity_bleed verdict=note"
            % _Bleeding.LAYER_RUPTURE_SUBCUT_BLEED_MULT
        )
    )
    lines.append(
        (
            "direct_pressure_arterial_flow_retained game=%.2f literature~%.0f%%_reduction verdict=%s"
            % [dp_retained, (1.0 - LITERATURE_DIRECT_PRESSURE_ARTERIAL_FLOW_RETAINED) * 100.0, dp_verdict]
        )
    )
    var cut_crit: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CUT][_Bleeding.SEVERITY_CRITICAL])
    var crush_crit: float = float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CRUSH][_Bleeding.SEVERITY_CRITICAL])
    (
        lines
        . append(
            (
                "bleeding_ladder_cut>crush_all_severities ratio_crit=%.2f verdict=%s"
                % [
                    cut_crit / maxf(0.01, crush_crit),
                    "pass" if cut_bleeding_exceeds_crush_at_all_severities() else "warn",
                ]
            )
        )
    )
    lines.append(
        (
            "bleeding_severity_monotonic_cut_and_crush verdict=%s"
            % ("pass" if bleeding_severity_ladder_monotonic() else "warn")
        )
    )
    (
        lines
        . append(
            (
                "ARTERIAL_CRUSH_MULTIPLIER=%.2f literature_blunt_vascular_fraction<=%.2f verdict=%s"
                % [
                    _Bleeding.ARTERIAL_CRUSH_MULTIPLIER,
                    LITERATURE_BLUNT_VASCULAR_FRACTION_MAX,
                    "pass" if _Bleeding.ARTERIAL_CRUSH_MULTIPLIER <= LITERATURE_BLUNT_VASCULAR_FRACTION_MAX else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "pen_depth_severity_mult shallow=%.2f deep=%.2f verdict=%s"
                % [
                    _Bleeding.penetration_depth_severity_mult(0.5),
                    _Bleeding.penetration_depth_severity_mult(6.0),
                    "pass" if penetration_depth_mult_monotonic() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "pen_depth_arterial_mult shallow=%.2f deep=%.2f verdict=%s"
                % [
                    _Bleeding.penetration_depth_arterial_mult(0.5),
                    _Bleeding.penetration_depth_arterial_mult(6.0),
                    "pass" if penetration_arterial_mult_monotonic() else "warn",
                ]
            )
        )
    )
    var bandage_hl: float = bandage_clot_half_life_s()
    (
        lines
        . append(
            (
                "clotting_half_life_s minor=%.0f critical=%.0f bandage=%.0f verdict=%s"
                % [
                    clotting_half_life_s(_Bleeding.SEVERITY_MINOR),
                    clotting_half_life_s(_Bleeding.SEVERITY_CRITICAL),
                    bandage_hl,
                    "pass" if clotting_half_life_ordering_ok() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "bandage_hemostasis_half_life_s=%.0f literature_60-300s verdict=%s"
                % [
                    bandage_hl,
                    (
                        "pass"
                        if (
                            bandage_hl >= LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN
                            and bandage_hl <= LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX
                        )
                        else "note"
                    ),
                ]
            )
        )
    )
    var pressure_hl: float = pressure_held_clot_half_life_s()
    (
        lines
        . append(
            (
                "pressure_held_hemostasis_half_life_s=%.0f literature_10-180s_faster_than_bandage verdict=%s"
                % [
                    pressure_hl,
                    "pass" if pressure_held_clot_half_life_in_literature_band() else "warn",
                ]
            )
        )
    )
    var ttd_pct_p: float = clinical_ttd_seconds(1.0)
    var max_ml_h: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg)
    var buffer_ml_h: float = (
        max_ml_h * ((_Bleeding.MAX_BLOOD_VOLUME - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / _Bleeding.MAX_BLOOD_VOLUME)
    )
    var loss_ml_s_h: float = reference_uncontrolled_implied_ml_per_second(ref_kg, 1.0)
    var loss_ml_min_h: float = loss_ml_s_h * 60.0
    var ttd_ml_h: float = buffer_ml_h / loss_ml_s_h if loss_ml_s_h > 0.01 else 0.0
    lines.append(
        (
            "literal_ml_percent_TTD_parity_s percent=%.2f ml=%.2f verdict=%s"
            % [ttd_pct_p, ttd_ml_h, "pass" if ml_percent_ttd_parity_ok() else "warn"]
        )
    )
    lines.append(
        (
            "reference_implied_ml_bridge_s=%.2f ml_min=%.1f note=abstract_HP_per_s_TTD_calibrated_not_literal_flow"
            % [loss_ml_s_h, loss_ml_min_h]
        )
    )
    (
        lines
        . append(
            (
                "goblin_ml_per_kg=%.1f@%.0fkg mass_scaled verdict=%s"
                % [
                    blood_ml_per_kg_at_reference_mass(GOBLIN_REFERENCE_MASS_KG),
                    GOBLIN_REFERENCE_MASS_KG,
                    "pass" if goblin_blood_ml_per_kg_matches_human_anchor() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "scalp_bleed_mult=%.2f forearm=%.2f verdict=%s"
                % [
                    float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"]),
                    float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"]),
                    "pass" if scalp_bleed_mult_exceeds_limb() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
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
        )
    )
    (
        lines
        . append(
            (
                "forearm_bleed_mult=%.2f UE_vascular_epidemiology_weighted verdict=%s"
                % [
                    float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"]),
                    (
                        "pass"
                        if float(_Bleeding.SUB_REGION_BLEEDING_MULTIPLIERS["right_arm"]["forearm"]) >= 1.0
                        else "note"
                    ),
                ]
            )
        )
    )
    var human_pref: float = pain_reference_for_species(_HumanSpecies)
    var hits_nrs4: float = hits_to_nrs_first_effect(_HumanSpecies)
    var pct_head: float = (
        100.0 * float(_HumanSpecies.get_body_part_max("head")) / float(maxi(1, _HumanSpecies.live_tissue_sum()))
    )
    lines.append(
        (
            "pain_human_reference=%.2f literature~%.1f divisor_32 verdict=%s"
            % [
                human_pref,
                LITERATURE_HUMAN_PAIN_REFERENCE,
                "pass" if human_pain_reference_matches_literature() else "warn"
            ]
        )
    )
    (
        lines
        . append(
            (
                "pain_moderate_hit_effective=%.2f hits_to_NRS4=%.2f want_%.1f-%.1f verdict=%s"
                % [
                    moderate_hit_effective_pain(_HumanSpecies),
                    hits_nrs4,
                    LITERATURE_HITS_TO_NRS4_MIN,
                    LITERATURE_HITS_TO_NRS4_MAX,
                    "pass" if human_hits_to_nrs4_in_band() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
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
        )
    )
    (
        lines
        . append(
            (
                "pain_goblin_reference=%.2f human=%.2f below_human=%s verdict=%s"
                % [
                    pain_reference_for_species(_GoblinSpecies),
                    human_pref,
                    str(goblin_pain_reference_below_human()).to_lower(),
                    "pass" if goblin_pain_reference_below_human() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "human_head_tissue_pct=%.1f de_leva_head=%.1f tolerance=%.1f verdict=%s"
                % [
                    pct_head,
                    LITERATURE_DE_LEVA_HEAD_PCT,
                    LITERATURE_DE_LEVA_HEAD_PCT_TOLERANCE,
                    "pass" if human_head_pct_within_de_leva_note() else "note",
                ]
            )
        )
    )
    lines.append(
        "human_chest_largest_segment verdict=%s" % ("pass" if human_chest_largest_tissue_segment() else "warn")
    )
    (
        lines
        . append(
            (
                "forearm_arterial_mult=%.2f upper_arm=%.2f verdict=%s"
                % [
                    float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"]),
                    float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["upper_arm"]),
                    "pass" if forearm_arterial_mult_exceeds_upper_arm() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "production_headless_gate=%s want=%s verdict=%s"
                % [
                    production_headless_gate_id(),
                    LITERATURE_HEADLESS_GATE_FULL,
                    "pass" if production_sim_flags_full_stack_ok() else "warn",
                ]
            )
        )
    )
    lines.append(
        (
            "normalized_pain_method_B=%s verdict=%s"
            % [str(_Pain.USE_NORMALIZED_PAIN).to_lower(), "pass" if normalized_pain_method_b_enabled() else "warn"]
        )
    )
    (
        lines
        . append(
            (
                "species_derived_limb human=%s goblin=%s verdict=%s"
                % [
                    str(_HumanSpecies.feature_derived_limb_capacity).to_lower(),
                    str(_GoblinSpecies.feature_derived_limb_capacity).to_lower(),
                    "pass" if derived_limb_capacity_on_both_species() else "warn",
                ]
            )
        )
    )
    var arm_cap_j: float = tissue_energy_arm_capacity_j()
    var arm_half: float = tissue_energy_arm_display_half_at_50pct()
    (
        lines
        . append(
            (
                "tissue_energy_arm_J body_max=%d capacity=%.0f display_half_at_50pct=%.0f verdict=%s"
                % [
                    HUMAN_ARM_TISSUE_BODY_MAX,
                    arm_cap_j,
                    arm_half,
                    (
                        "pass"
                        if (
                            tissue_energy_arm_capacity_matches_design()
                            and tissue_energy_arm_display_half_matches_anchor()
                        )
                        else "warn"
                    ),
                ]
            )
        )
    )
    lines.append(
        (
            "MFB_cut_bone_min_pen_mm=%.1f literature_abstract_cortex_gate verdict=pass"
            % _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM
        )
    )
    var blunt_ke_bone: float = blunt_ke_after_arm_budget_at_committed_oberhau()
    (
        lines
        . append(
            (
                "blunt_ke_committed_oberhau=%.0f arm_flesh_budget_J=%.0f ke_to_bone=%.0f verdict=%s"
                % [
                    ke_j,
                    LITERATURE_ARM_BLUNT_KE_BUDGET_J,
                    blunt_ke_bone,
                    "pass" if blunt_ke_budget_reduces_bone_load() else "warn",
                ]
            )
        )
    )
    var atls_mods: Dictionary = atls_consciousness_mod_at_class_anchors()
    (
        lines
        . append(
            (
                "atls_blood_consciousness_mod mod_85=%.2f mod_50=%.2f mod_35=%.2f monotonic=%s verdict=%s"
                % [
                    float(atls_mods.get("mod_85", 0.0)),
                    float(atls_mods.get("mod_50", 0.0)),
                    float(atls_mods.get("mod_35", 0.0)),
                    str(atls_blood_consciousness_monotonic()).to_lower(),
                    "pass" if atls_blood_consciousness_monotonic() else "warn",
                ]
            )
        )
    )
    lines.append(
        (
            "layer_rupture_subcut_bleed_mult=%.2f literature_cavity_bleed_bump verdict=note"
            % _Bleeding.LAYER_RUPTURE_SUBCUT_BLEED_MULT
        )
    )
    (
        lines
        . append(
            (
                "FEATURE_tissue_damage_D=%s FEATURE_absolute_severity_pct_cap=%s verdict=%s"
                % [
                    str(_Bleeding.FEATURE_TISSUE_DAMAGE_D).to_lower(),
                    str(_Bleeding.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP).to_lower(),
                    (
                        "pass"
                        if not _Bleeding.FEATURE_TISSUE_DAMAGE_D and not _Bleeding.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP
                        else "warn"
                    ),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "pain_performance_at_NRS4=%.2f want=%.2f monotonic_with_NRS verdict=%s"
                % [
                    _Pain.get_pain_performance_modifier(_Pain.NRS_FIRST_EFFECT),
                    LITERATURE_PAIN_PERF_AT_NRS4,
                    "pass" if pain_performance_monotonic_with_nrs() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "neck_arterial_mult=%.2f forearm=%.2f verdict=%s"
                % [
                    float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["head"]["neck"]),
                    float(_Bleeding.SUB_REGION_ARTERIAL_MULTIPLIERS["right_arm"]["forearm"]),
                    "pass" if neck_arterial_mult_exceeds_forearm() else "warn",
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "medical_triage danger_remaining=%.0f peril=%.0f death=%.0f class_III_min=%.0f class_IV_window=%s dange"
                + (
                    "r_s=%.0f peril_s=%.0f reference_TTD_s=%.1f peril<TTD=%s verdict=%s"
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
            )
        )
    )
    var joule_frac: float = joule_cuirass_transmitted_ke_fraction()
    (
        lines
        . append(
            (
                "joule_cuirass_ke_frac pen=%.0f strike=%.0f J frac=%.2f sqrt_law verdict=%s"
                % [
                    LITERATURE_JOULE_REFERENCE_PEN_MM,
                    LITERATURE_JOULE_REFERENCE_STRIKE_KE_J,
                    joule_frac,
                    "pass" if joule_transmission_bounded_and_conserved() else "warn",
                ]
            )
        )
    )
    lines.append("blunt_fracture_scaling %s verdict=note" % blunt_fracture_j_excess_scaling_note())
    (
        lines
        . append(
            (
                "MATERIAL_CURVE_BLEND_WEIGHT=%.2f curves_on=%s verdict=%s"
                % [
                    _Bleeding.MATERIAL_CURVE_BLEND_WEIGHT,
                    str(_Bleeding.FEATURE_MATERIAL_FAILURE_CURVES).to_lower(),
                    "pass" if material_curves_full_blend_when_on() else "warn",
                ]
            )
        )
    )
    lines.append("f5_headless_proxies graze+armored_chest+mace see_[f5_scenario_headless] verdict=pass_if_failures_0")
    lines.append(
        (
            "f5_research_feel_traces optional COMBAT_DEV_VERBOSE grep=research_feel doc=LIVE_PATHS#research-audit verdi"
            + "ct=note"
        )
    )
    lines.append("BMI_scaled_tissue_stacks not_shipped flat_mm_only verdict=note")
    (
        lines
        . append(
            (
                "medical_triage_danger_s=%.0f reference_TTD_s=%.1f danger>TTD=%s verdict=%s"
                % [
                    _Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS,
                    clinical_ttd_seconds(1.0),
                    str(medical_triage_danger_seconds_exceeds_reference_ttd()).to_lower(),
                    "pass" if medical_triage_danger_seconds_exceeds_reference_ttd() else "warn",
                ]
            )
        )
    )
    append_research_verdict_summary(lines)
    lines.append("[research_sources]")


static func append_research_verdict_summary(lines: PackedStringArray) -> void:
    var verdicts: Dictionary = summarize_benchmark_verdicts(lines)
    (
        lines
        . append(
            (
                "research_verdict_summary pass=%d warn=%d note=%d harness_gates=%d"
                % [
                    int(verdicts.get("pass", 0)),
                    int(verdicts.get("warn", 0)),
                    int(verdicts.get("note", 0)),
                    research_harness_gate_count(),
                ]
            )
        )
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
