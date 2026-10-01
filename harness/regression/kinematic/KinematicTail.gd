class_name CombatRegressionHarnessKinematicTail
extends RefCounted
## Tier 5.1 optional long-tail kinematic tests split from **`CombatRegressionHarness`** (Godot compile size).
## Footing: strike delivery / energy  -  may pass **`guard_line`** into path context; not L2 form or Tier 4.4 PA owner.
## LIVE_PATHS **`#wf-layer-labels`**.

const HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"
## Tier 5.1 core kinematic rows (bodies live on **`CombatRegressionHarness`** to avoid parse cycles).
const HumanSpecies := preload("res://resources/species/human.tres")


static func run_core(failures: PackedStringArray) -> void:
    KinematicDeliveryOverrideTests._run_kinematic_delivery_override_and_mixed_ke_blend_brackets_thrust_swing(failures)
    KinematicDeliveryOverrideTests._run_kinematic_delivery_velocity_from_intensity_bridges_get_effective_and_monotone(
        failures
    )
    KinematicDeliveryPreArmorTests._run_kinematic_delivery_pre_armor_cut_sqrt_ke_ratio_and_blunt_rises_with_speed(
        failures
    )
    KinematicDeliveryPreArmorTests._run_kinematic_delivery_penetration_sharp_ke_exponent_and_blunt_mpa_rises(failures)
    KinematicDeliveryPreArmorTests._run_kinematic_delivery_strike_energy_mult_scales_ke_and_pre_armor_cut_sqrt(failures)
    KinematicDeliveryPreArmorTests._run_kinematic_delivery_strike_momentum_mult_scales_blunt_damage_and_mpa(failures)
    KinematicDeliveryPreArmorTests._run_kinetic_delivery_thrust_mass_fallback_for_unknown_templates(failures)
    KinematicDeliveryPreArmorTests._run_kinematic_delivery_thrust_body_coupled_strike_mass_and_ke_rising(failures)
    KinematicDeliveryPreArmorTests._run_kinetic_delivery_mass_scaled_band_max(failures)
    KinematicDeliveryPreArmorTests._run_kinetic_delivery_uniform_rod_inertia_parallel_axis(failures)
    KinematicDeliveryPreArmorTests._run_kinetic_delivery_sub_band_energy_consistency(failures)
    KinematicDeliveryPreArmorTests._run_kinematic_delivery_impact_contact_time_speed_dependent(failures)
    KinematicDeliveryStrikeMultTests._run_kinematic_delivery_strike_mult_cross_coupling_ke_vs_blunt_isolated(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_penetration_oblique_angle_factor_attack_resolver(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_compute_damage_oblique_penetration_integration(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_compute_damage_strike_mods_penetration_integration(
        failures
    )
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_line_alignment_with_deflect_branches(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_deflected_angle_bilateral_and_line_angle_helpers(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_deflected_line_from_angles_same_line_bind(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_angle_diff_and_alignment_from_angles_helpers(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_path_lookup_discrete_from_angles_continuous_alignment(
        failures
    )
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_guard_deflect_blend_guard_angle_and_attack_only_align(
        failures
    )
    KinematicDeliveryPenetrationTests._run_kinetic_delivery_blunt_penetration_contact_mirrors_damage_cap(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_compute_penetration_return_keys_and_thrust_blunt_contact(
        failures
    )
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_attack_angle_deg_no_variance_deterministic(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_compute_damage_velocity_and_entity_split(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_alignment_context_guard_angle_only_uses_combatant_guard(
        failures
    )
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_parry_v_intent_effective_velocity_base(failures)
    KinematicDeliveryPenetrationTests._run_kinematic_delivery_guard_wobble_readiness_shifts_guard_angle(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_compute_damage_strike_ke_and_blunt_contact_exposed(
        failures
    )
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_alignment_both_angles_ignores_wobble(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_attack_angle_only_wobble_changes_alignment(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_partial_parry_strike_ke_unchanged_pen_scaled(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_compute_damage_pre_armor_matches_helper_at_assembled_v(
        failures
    )
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_partial_parry_cut_to_blunt_shift(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_derived_velocity_no_cut_to_blunt_shift_on_partial_parry(
        failures
    )
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_misaligned_guard_scales_pen_not_pre_armor(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_get_attack_path_fallback_to_attack_paths(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_strike_mods_damage_mults_scale_pre_armor_only(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_stab_partial_parry_no_cut_to_blunt_shift(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_partial_parry_misalign_oblique_parry_branch_wins(
        failures
    )
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_blunt_momentum_mult_scales_pen_not_pre_armor(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_get_attack_path_unknown_attack_line_fallback(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_sharp_penetration_mult_scales_pen_not_pre_cut(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_attack_angle_deg_variance_stamina_spreads(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_partial_parry_align_compose_on_pen_not_pre_armor_mix(
        failures
    )
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_entity_split_final_fields_on_hit(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_mace_blunt_partial_parry_no_cut_to_blunt_shift(failures)
    KinematicDeliveryPartialParryTests._run_kinematic_delivery_misaligned_guard_scales_sharp_and_blunt_pen(failures)
    KinematicDeliveryStaminaFormationTests._run_kinematic_delivery_strike_energy_mult_integration_pre_cut_not_pen(
        failures
    )
    KinematicDeliveryStaminaFormationTests._run_kinematic_delivery_afterblow_mult_scales_strike_ke_via_velocity(
        failures
    )
    KinematicDeliveryStaminaFormationTests._run_kinematic_delivery_angle_to_nearest_line_boundaries(failures)


## HEMA defense: misaligned guard (high atk vs low def) prefers dodge over leaky parry.


## Entry point  -  defined last so Godot resolves all `_run_*` bodies before `run()` (large-script forward-ref limit).
static func run(failures: PackedStringArray) -> void:
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_line_to_angle_unknown_line_returns_zero(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_guard_wobble_heavy_mass_increases_spread(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_strike_momentum_mult_integration_pre_blunt_not_pen(
        failures
    )
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_low_striker_stamina_lowers_strike_ke(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_get_attack_path_all_line_pairs_nonempty(failures)
    KinematicDeliveryGuardMatrixTests._run_iv4_guard_matrix_suite(failures)
    KinematicDeliveryGuardMatrixTests._run_iv6_attack_path_octant_suite(failures)
    KinematicDeliveryGuardMatrixTests._run_iv5_arm_interpose_suite(failures)
    KinematicDeliveryGuardMatrixTests._run_iv5_choose_defense_interpose_boost(failures)
    KinematicDeliveryClosingDefenseTests._run_choose_defense_misaligned_prefers_dodge(failures)
    KinematicDeliveryClosingDefenseTests._run_choose_defense_aligned_can_parry(failures)
    KinematicDeliveryGuardMatrixTests._run_iv5_parry_clash_context_carries_interpose(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_near_full_parry_respects_min_cut_ratio_floor(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_discrete_line_alignment_matches_with_deflect_no_angles(
        failures
    )
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_mixed_archetype_integration_ke_matches_helper(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_angle_diff_symmetry_and_zero(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_closing_speed_engagement_angle_scales_strike_ke(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_armored_chest_reduces_tissue_and_reports_mech_post_armor(
        failures
    )
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_unarmed_pre_blunt_matches_helper(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_unarmed_partial_parry_scales_pre_blunt(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_depth_polearm_thrust_ctx_scales_strike_ke(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_tactical_ambush_mult_scales_strike_ke(failures)
    KinematicDeliveryGuardMatrixTests._run_kinematic_delivery_gambeson_and_cuirass_chest_both_below_bare(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_depth_polearm_allows_low_false_no_closing_boost(
        failures
    )
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_pa_stamp_open_lane_strike_ke_matches_manual_ctx(
        failures
    )
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_attack_angle_deg_variance_off_balance_spreads(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_attack_angle_deg_variance_weapon_mass_spreads(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_tactical_ambush_mult_unity_no_boost(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_engagement_angle_unknown_matches_front(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_parry_v_intent_thrust_archetype(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_thrust_integration_pre_cut_scales_ke_pow(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_mace_integration_pre_blunt_rises_with_vo(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_thrust_integration_pen_sharp_scales_ke_exponent(
        failures
    )
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_resolve_hit_part_angle_path_keys(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_empty_arch_spear_thrust_infers_delivery(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_move_def_angle_offset_seeded_deterministic(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_derived_velocity_misalign_skips_oblique_pen(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_mace_integration_pen_blunt_mpa_rises_with_vo(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_low_striker_stamina_lowers_pre_cut(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_move_def_angle_variance_wider_than_bare_line(failures)
    KinematicDeliveryDepthTacticalTests._run_kinematic_delivery_choose_defense_parry_p_a_matches_v_intent_formula(
        failures
    )
    KinematicDeliveryClosingDefenseTests._run_kinematic_delivery_rear_afterblow_compose_on_strike_ke(failures)
    KinematicWeaponIntegrationTests._run_kinematic_delivery_weapon_form_damage_scales_pre_cut_integration(failures)
    KinematicDeliveryClosingDefenseTests._run_kinematic_delivery_closing_speed_engagement_angle_scales_pre_cut(failures)
    KinematicDeliveryClosingDefenseTests._run_kinematic_delivery_engagement_damage_multiplier_rear_hits_harder(failures)
    KinematicWeaponIntegrationTests._run_kinematic_delivery_mixed_integration_pre_cut_scales_ke_pow(failures)
    KinematicDeliveryClosingDefenseTests._run_kinematic_delivery_closing_speed_clamps_at_ceiling(failures)
    KinematicDeliveryClosingDefenseTests._run_kinematic_delivery_variance_off_balance_and_stamina_compose(failures)
    KinematicDeflectParryTests._run_kinematic_delivery_deflected_line_opposite_severity_bind(failures)
    KinematicDamageScalingTests._run_kinematic_delivery_target_mass_scales_blunt_pre_armor(failures)
    KinematicWeaponIntegrationTests._run_kinematic_delivery_axe_integration_pre_cut_scales_ke_pow(failures)
    KinematicDamageScalingTests._run_kinematic_delivery_cut_damage_mult_integration_scales_pre_cut_only(failures)
    KinematicDamageScalingTests._run_kinematic_delivery_unarmed_afterblow_scales_pre_blunt(failures)
    KinematicWeaponIntegrationTests._run_kinematic_delivery_dagger_integration_pre_cut_scales_ke_pow(failures)
    KinematicDamageScalingTests._run_kinematic_delivery_blunt_damage_mult_integration_scales_pre_blunt_only(failures)
    KinematicDeflectParryTests._run_kinematic_delivery_deflected_line_stab_opposite_severity_bind(failures)
    KinematicWeaponIntegrationTests._run_kinematic_delivery_empty_arch_sword_thrust_infers_delivery(failures)
    KinematicDeflectParryTests._run_kinematic_delivery_partial_parry_cut_to_blunt_integration_sword(failures)
    KinematicDeflectParryTests._run_kinematic_delivery_pinned_vo_misalign_scales_pen_integration(failures)
    KinematicDeflectParryTests._run_kinematic_delivery_striker_stamina_strike_ke_matches_sqrt_stamina_scale(failures)
    KinematicDamageScalingTests._run_kinematic_delivery_afterblow_scales_pre_cut_integration(failures)
    KinematicWeaponIntegrationTests._run_kinematic_delivery_mace_blunt_contact_cm_matches_helper_integration(failures)
    KinematicDamageScalingTests._run_kinematic_delivery_entity_split_total_includes_final_bone(failures)
