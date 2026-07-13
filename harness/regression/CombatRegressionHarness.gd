class_name CombatRegressionHarness
extends CombatRegressionHarnessCore

## Thin facade: orchestrates regression modules under harness/regression/ and subsystem tails.


static func _kin_fixtures_cut_swing() -> Array:
    return KinematicDeliveryPenetrationTests._kin_fixtures_cut_swing()


static func _kin_fixtures_thrust() -> Array:
    return KinematicDeliveryPenetrationTests._kin_fixtures_thrust()


static func _kin_fixtures_blunt() -> Array:
    return KinematicDeliveryPenetrationTests._kin_fixtures_blunt()


static func _kin_fixtures_with_sharp_pen() -> Array:
    return KinematicDeliveryPenetrationTests._kin_fixtures_with_sharp_pen()


static func _kin_fixtures_with_blunt_pen() -> Array:
    return KinematicDeliveryPenetrationTests._kin_fixtures_with_blunt_pen()


static func _kin_fixtures_all_damage() -> Array:
    return KinematicDeliveryPartialParryTests._kin_fixtures_all_damage()


static func _kin_arch_for_move(move_id: String) -> Dictionary:
    return KinematicDeliveryPartialParryTests._kin_arch_for_move(move_id)


static func _kin_fixture_vo(cfx: Dictionary, default_vo: float) -> float:
    return KinematicDeliveryPartialParryTests._kin_fixture_vo(cfx, default_vo)


static func _kin_dmg_integration_sample(
    vo: float,
    parry_r: float,
    align: float,
    strike_mods: Dictionary,
    weapon_id: String = "SWORD",
    move_id: String = "oberhau",
    afterblow_mult: float = 1.0,
    arch_override: Dictionary = {},
    tgt_overrides: Dictionary = {},
    tgt_chest_armor_id: String = "",
    strike_physics_ctx: Dictionary = {}
) -> Dictionary:
    return KinematicDeliveryPartialParryTests._kin_dmg_integration_sample(
        vo,
        parry_r,
        align,
        strike_mods,
        weapon_id,
        move_id,
        afterblow_mult,
        arch_override,
        tgt_overrides,
        tgt_chest_armor_id,
        strike_physics_ctx
    )


static func _kin_expected_damage_velocity_m_s(
    mgr: Node,
    atk: Dictionary,
    tgt: Dictionary,
    intensity: float,
    arch: Dictionary,
    move_id: String,
    velocity_override: float,
    afterblow_damage_mult: float,
    strike_physics_ctx: Dictionary = {}
) -> float:
    return KinematicDeliveryPenetrationTests._kin_expected_damage_velocity_m_s(
        mgr, atk, tgt, intensity, arch, move_id, velocity_override, afterblow_damage_mult, strike_physics_ctx
    )


static func _kin_path_intercept_max_index(path: Array, alignment: float) -> int:
    return KinematicDeliveryPenetrationTests._kin_path_intercept_max_index(path, alignment)


static func _afterblow_harness_seed_pending_cut(mgr: Node, attacker_index: int, defender_index: int) -> void:
    WeaponAfterblowGuardTests._afterblow_harness_seed_pending_cut(mgr, attacker_index, defender_index)


static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.reset_harness_feature_load_overrides()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarnessCore._run_next_action_ready_map_matches_per_id(failures)
    CombatRegressionHarnessCore._run_vacancy_reconcile_follow_up_regression(failures)
    CombatRegressionHarnessCore._run_vacancy_reconcile_after_front_death(failures)
    CombatRegressionHarnessTier1Tail.run_early(failures)
    CombatRegressionHarnessFeintTempoTail.run_before_attention(failures)
    CombatRegressionHarnessAttentionFootworkTail.run(failures)
    CombatRegressionHarnessMentalStackIntegrationTail.run(failures)
    CombatRegressionHarnessWeaponFormTail.run(failures)
    CombatRegressionHarnessFeintTempoTail.run_after_attention(failures)
    CombatRegressionHarnessTier1Tail.run_mid(failures)
    SoakFpOperationalLogDedupeTests._run_effective_pair_geometry_single_pass_matches_wrappers(failures)
    SoakFpOperationalLogDedupeTests._run_windup_pending_attack_pair_geometry(failures)
    SoakFpOperationalLogDedupeTests._run_strike_measure_constants_sanity(failures)
    SoakFpOperationalLogDedupeTests._run_attack_result_applier_terminal_clears_pending(failures)
    SoakFpOperationalLogDedupeTests._run_action_resolved_parry_deflect_payload_includes_clash_context(failures)
    ParryActionResolvedTests._run_action_resolved_parry_partial_payload_includes_clash_context(failures)
    ParryActionResolvedTests._run_hit_clears_attacker_parry_calibration_fields(failures)
    ParryActionResolvedTests._run_hit_applier_sets_defender_guard_low_after_hit(failures)
    ParryActionResolvedTests._run_parry_partial_bind_riposte_flags_when_aligned(failures)
    CombatRegressionHarnessTier1Tail.run_late(failures)
    CombatRegressionHarnessKinematicTail.run_core(failures)
    CombatRegressionHarnessKinematicTail.run(failures)
    CombatRegressionHarnessSimulation.run(failures)
    KinematicDeliveryStaminaFormationTests._run_weapon_blade_strong_fraction(failures)
    CombatRegressionHarnessFleeTail.run(failures)
    CombatRegressionHarnessMedicalMobilityTail.run(failures)
    WeaponAfterblowGuardTests._run_ai_attrition_offense_mult_duel_vs_line(failures)
    WeaponAfterblowGuardTests._run_wind_up_duration_bounded_for_move(failures)
    WeaponAfterblowGuardTests._run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11(failures)
    WeaponAfterblowGuardTests._run_kinematic_delivery_mace_weak_tap_pre_blunt_below_baseline_min(failures)
    WeaponAfterblowGuardTests._run_resolve_aborts_when_threat_lost_mid_combat_arm_loss(failures)
    CombatRegressionHarnessMedicalPhaseTail.run(failures)
    CombatRegressionHarnessProficiencyTail.run(failures)
    CombatRegressionHarnessProficiency1v1Tail.run(failures)
    CombatRegressionHarnessMuscleFatigueTail.run(failures)
    CombatRegressionHarnessTargeting1v1Tail.run(failures)
    ParryActionResolvedTests._run_combat_end_enemy_win_stops_manager(failures)
    KinematicDeliveryStaminaFormationTests._run_medical_pain_shock_susceptibility_mult_from_effective_pain(failures)
    KinematicDeliveryStaminaFormationTests._run_medical_ambient_pain_shock_tick_enters_from_sustained_pain(failures)
    KinematicDeliveryStaminaFormationTests._run_medical_ambient_pain_shock_skips_when_feature_off(failures)
    KinematicDeliveryStaminaFormationTests._run_campaign_bridge_can_enter_combat_rejects_empty_party(failures)
    KinematicDeliveryStaminaFormationTests._run_campaign_bridge_can_enter_combat_rejects_unconscious(failures)
    KinematicDeliveryStaminaFormationTests._run_bind_riposte_contact_types_normalized(failures)
    FlurryBindCampaignTests._run_bind_riposte_contact_multipliers(failures)
    FlurryBindCampaignTests._run_bind_riposte_archetype_ordering_spear_faster_than_mace(failures)
    FlurryBindCampaignTests._run_p4h_bind_riposte_balance_suite(failures)
    FlurryBindCampaignTests._run_p4d_parry_bind_doc_code_parity_suite(failures)
    FlurryBindCampaignTests._run_flurry_bind_exchange_wind_up_reduced_vs_plain(failures)
    FlurryBindCampaignTests._run_flurry_bind_exchange_consumes_on_wind_up(failures)
    FlurryBindCampaignTests._run_flurry_bind_window_closes_on_hit(failures)
    FlurryBindCampaignTests._run_flurry_bind_listing_restricts_to_bind_partner(failures)
    FlurryBindCampaignTests._run_flurry_bind_opens_on_bind_deflect(failures)
    FlurryBindCampaignTests._run_flurry_bind_expires_after_window(failures)
    FlurryBindCampaignTests._run_flurry_bind_ui_gauge_label_when_window_open(failures)
    FlurryBindCampaignTests._run_flurry_bind_feature_flag_respects_runtime_toggle(failures)
    FlurryBindCampaignTests._run_p4g_flurry_bind_depth_suite(failures)
    KinematicDeliveryStaminaFormationTests._run_tier7_stamina_attack_cost_scales_with_intensity(failures)
    KinematicDeliveryStaminaFormationTests._run_tier7_stamina_parry_cost_scales_with_intensity(failures)
    KinematicDeliveryStaminaFormationTests._run_tier7_stamina_action_ready_cooldown_scales_with_fatigue(failures)
    KinematicDeliveryStaminaFormationTests._run_tier7_stamina_depletion_five_heavy_attacks_exhaust_pool(failures)
    KinematicDeliveryStaminaFormationTests._run_tier7_stamina_depletion_sustained_exchange_sim(failures)
    KinematicDeliveryStaminaFormationTests._run_stamina_effective_max_exhaustion_and_blood_cap(failures)
    KinematicDeliveryStaminaFormationTests._run_stamina_effective_refill_slows_with_exhaustion(failures)
    KinematicDeliveryStaminaFormationTests._run_opponent_pressure_defensive_uses_burst_ratio(failures)
    FlurryBindCampaignTests._run_tier7_parry_bind_riposte_gauge_bonus_on_deflect(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_lane_obstacle_slows_estimate(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_matches_flow_pair_start(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_ui_hint_when_lane_crowded(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_diagram_health_bar_reflects_body_damage(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_diagram_health_bar_tint_reflects_function_loss(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_listed_actions_stamp_hint(failures)
    RotateFileDoctrineTests._run_rotate_file_listed_for_adjacent_front_rank_allies(failures)
    RotateFileDoctrineTests._run_rotate_file_start_sets_duration_matches_estimate(failures)
    RotateFileDoctrineTests._run_rotate_file_resolve_stamps_rotate_cooldown(failures)
    RotateFileDoctrineTests._run_swap_rank_resolve_clears_doctrine_without_rotate_cooldown(failures)
    RotateFileDoctrineTests._run_rotate_file_lists_both_adjacent_wing_partners(failures)
    RotateFileDoctrineTests._run_rotate_file_cooldown_blocks_listing_and_resolve(failures)
    RotateFileDoctrineTests._run_rotate_file_reverse_pair_lock_blocks_re_swap(failures)
    RotateFileDoctrineTests._run_vacancy_plug_clears_doctrine_commitment(failures)
    RotateFileDoctrineTests._run_formation_shuffle_clears_close_block(failures)
    RotateFileDoctrineTests._run_pair_abort_cooldown_blocks_swap_rank_resolve(failures)
    RotateFileDoctrineTests._run_swap_rank_not_listed_without_tactical_gate(failures)
    RotateFileDoctrineTests._run_swap_rank_resolve_rejects_without_tactical_gate(failures)
    RotateFileDoctrineTests._run_resolve_close_attempt_long_success_closes_distance(failures)
    RotateFileDoctrineTests._run_automatic_doctrine_sets_pinch_on_hollow_when_enabled(failures)
    FlurryBindCampaignTests._run_automatic_doctrine_pinch_via_formation_recompute(failures)
    FlurryBindCampaignTests._run_p4c_numeric_superiority_auto_pinch(failures)
    RotateFileDoctrineTests._run_formation_move_duration_heavy_armor_slows_estimate(failures)
    RotateFileDoctrineTests._run_iv7_armor_burden_action_ready(failures)
    RotateFileDoctrineTests._run_iv7_armor_burden_passive_readiness(failures)
    ImpactStationWeaponCommitTests._run_iv7b_stamina_engage_floor_suite(failures)
    RotateFileDoctrineTests._run_iv8_initiative_order_stagger(failures)
    RotateFileDoctrineTests._run_iv8_initiative_order_flag_off_parity(failures)
    RotateFileDoctrineTests._run_iv9_gap_column_compact_suppressed_when_flag_on(failures)
    RotateFileDoctrineTests._run_iv9_gap_column_flag_off_parity(failures)
    RotateFileDoctrineTests._run_iv9_gap_column_vacancy_reconcile_flag_on(failures)
    Iv9GapColumnTests._run_iv9_gap_column_occupied_files_suite(failures)
    Iv9GapColumnTests._run_iv9_gap_column_diagram_display_suite(failures)
    Iv9GapColumnTests._run_iv9_gap_column_pair_geometry_column_arc_suite(failures)
    Iv9GapColumnTests._run_iv9_gap_column_dual_mode_formation_targeting_suite(failures)
    Iv9GapColumnTests._run_iv9_gap_column_topology_refresh_after_formation_moves(failures)
    Iv9GapColumnTests._run_iv9_gap_column_topology_refresh_drag_back_fall_back_pair(failures)
    # IV-11 leader formation (slices 1 - 10)
    Iv11LeaderTargetingTests._run_iv11_leader_formation_ability_suite(failures)
    Iv9GapColumnTests._run_iv11_register_party_leader_stamp_suite(failures)
    Iv9GapColumnTests._run_iv11_campaign_bridge_party_leader_stamp_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_register_enemy_leader_stamp_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_encounter_spawn_enemy_leader_suite(failures)
    Iv9GapColumnTests._run_iv11_party_leader_diagram_callout_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_enemy_leader_diagram_callout_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_party_leader_roster_callout_suite(failures)
    Iv9GapColumnTests._run_iv11_leader_order_hold_lane_suite(failures)
    Iv9GapColumnTests._run_iv11_leader_order_hold_lane_formatter_suite(failures)
    Iv9GapColumnTests._run_iv11_leader_order_probing_suite(failures)
    Iv9GapColumnTests._run_iv11_leader_order_probing_formatter_suite(failures)
    Iv9GapColumnTests._run_iv11_leader_order_pinch_center_suite(failures)
    Iv9GapColumnTests._run_iv11_leader_order_pinch_center_formatter_suite(failures)
    Iv9GapColumnTests._run_iv11_enemy_commander_order_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_leader_doctrine_cycle_suite(failures)
    Iv9GapColumnTests._run_iv11_enemy_commander_doctrine_cycle_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_leader_command_ai_weight_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_enemy_commander_ai_weight_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_pinch_outnumber_ai_weight_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_enemy_pinch_outnumber_ai_weight_suite(failures)
    Iv11LeaderTargetingTests._run_iv11_f5_leader_order_trace_suite(failures)
    Iv11LeaderTargetingTests._run_iv13_weapon_reach_zoc_suite(failures)
    Iv11LeaderTargetingTests._run_iv13_weapon_reach_zoc_flag_off_parity(failures)
    Iv11LeaderTargetingTests._run_iv13_weapon_reach_zoc_distance_band_suite(failures)
    Iv11LeaderTargetingTests._run_iv12_slot_distraction_suite(failures)
    Iv11LeaderTargetingTests._run_iv12_slot_distraction_flag_off_parity(failures)
    Iv11LeaderTargetingTests._run_iv12_slot_distraction_ai_offense_damp(failures)
    Iv11LeaderTargetingTests._run_iv12_co_located_target_bias_suite(failures)
    Iv11LeaderTargetingTests._run_iv12_drag_back_dual_occupancy_distraction_suite(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_player_turn_hint_from_listed_actions(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_gauge_tooltip_listed_hint(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_gauge_tooltip_clears_when_not_waiting(failures)
    KinematicDeliveryStaminaFormationTests._run_formation_move_duration_gauge_tooltip_clears_on_resolve(failures)
    RotateFileDoctrineTests._run_p4b_formation_duration_ui_copy_suite(failures)
    KinematicDeliveryStaminaFormationTests._run_wind_up_rejects_move_not_on_weapon(failures)
    ImpactStationWeaponCommitTests._run_formation_hit_reaction_extends_pair_move_duration(failures)
    ImpactStationWeaponCommitTests._run_formation_hit_cancel_aborts_pair_move(failures)
    ImpactStationWeaponCommitTests._run_incoming_parry_choice_blocks_non_chosen_attacker(failures)
    ImpactStationWeaponCommitTests._run_incoming_parry_can_parry_all_weak_pair(failures)
    ImpactStationWeaponCommitTests._run_iii1_incoming_parry_sector_tiebreak(failures)
    ImpactStationWeaponCommitTests._run_iii3_deflect_bind_calibration_suite(failures)
    ImpactStationWeaponCommitTests._run_weapon_extended_parry_dampens_defender_recovering_from_attack(failures)
    ImpactStationWeaponCommitTests._run_weapon_committed_attack_dampens_defender_parry_c_d(failures)
    ImpactStationWeaponCommitTests._run_weapon_commit_fraction_stab_before_overhead_cut(failures)
    ImpactStationWeaponCommitTests._run_weapon_windup_stamps_commit_fraction_on_pa(failures)
    ImpactStationWeaponCommitTests._run_weapon_commit_fraction_inferred_for_untagged_thrust_move(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_zero_spread_equals_move_mean(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_move_overrides_weapon_default(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_ordering_spear_thrust_above_mace_direct_blow(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_windup_stamps_move_override(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_every_move_def_tagged(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_feint_coiled_below_honest_cut(failures)
    ImpactStationWeaponCommitTests._run_impact_station_mean_pole_swing_below_spear_thrust(failures)
    FlurryBindCampaignTests._run_formation_hit_cancel_ui_gauge_vulnerable_suffix(failures)
    FlurryBindCampaignTests._run_parry_opposite_deflect_thresholds(failures)
    FlurryBindCampaignTests._run_parry_defender_vs_attack_modifiers(failures)
    ParryCalibrationBlockTests._run_parry_clash_context_calibration_fields(failures)
    ParryCalibrationBlockTests._run_parry_partial_clash_context_calibration_fields(failures)
    ParryCalibrationBlockTests._run_parry_control_bind_deflect_formula(failures)
    ParryCalibrationBlockTests._run_follow_through_gate_at_low_remaining_ratio(failures)
    ParryCalibrationBlockTests._run_follow_through_integration_gate(failures)
    ParryCalibrationBlockTests._run_block_threshold_balance_test(failures)
    ParryCalibrationBlockTests._run_block_threshold_asymmetric_test(failures)
    ParryCalibrationBlockTests._run_weapon_melee_range_ordering(failures)
    WeaponAfterblowGuardTests._run_weapon_move_coverage(failures)
    WeaponAfterblowGuardTests._run_weapon_parts_mass_sum(failures)
    WeaponAfterblowGuardTests._run_weapon_feint_parry_coverage(failures)
    WeaponAfterblowGuardTests._run_weapon_angle_variance_ranges(failures)
    WeaponAfterblowGuardTests._run_guard_line_deflected_severity_from_margin_ratio(failures)
    WeaponAfterblowGuardTests._run_guard_from_move_sets_guard_line_and_zone(failures)
    WeaponAfterblowGuardTests._run_afterblow_no_pending_returns_false(failures)
    WeaponAfterblowGuardTests._run_afterblow_wrong_state_returns_false(failures)
    WeaponAfterblowGuardTests._run_afterblow_hindrance_block_cancels_pending(failures)
    WeaponAfterblowGuardTests._run_afterblow_deflected_triggers_full_resolve_hit(failures)
    WeaponAfterblowGuardTests._run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures)
    WeaponAfterblowGuardTests._run_afterblow_mid_hindrance_rand_cancel(failures)
    WeaponAfterblowGuardTests._run_afterblow_mid_hindrance_rand_executes_hit(failures)
    FlurryBindCampaignTests._run_campaign_bridge_entity_untreated_wounds(failures)
    FlurryBindCampaignTests._run_party_row_triage_formatter(failures)
    SoakFpTraceFormatterTests._run_combat_log_formatter_negligible(failures)
    FlurryBindCampaignTests._run_campaign_bridge_encounter_meta_from_node(failures)
    ## Phase 2: feint resistance gate  -  high-readiness defenders reject feints.
    WeaponAfterblowGuardTests._run_mental_stack_feint_resistance_high_readiness(failures)
    MentalStackFeintMedicalTests._run_mental_stack_feint_resistance_low_readiness_still_falls_for(failures)
    ## Phase 3: MS-L8 post-strike momentum layer.
    WeaponAfterblowGuardTests._run_ms_l8_post_strike_momentum_presses_target(failures)
    ## Phase 5: exhaustion gradient (offense weight lerp).
    MentalStackFeintMedicalTests._run_ms_l7_exhaustion_gradient_offense_weight(failures)
    ## Phase 6: MS-L9 positional awareness  -  disengage when surrounded + vulnerable.
    MentalStackFeintMedicalTests._run_ms_l9_positional_awareness_disengage_when_surrounded(failures)
    ## Phase 7: medical escalation TCCC ladder  -  pack boosted when bandage failed.
    MentalStackFeintMedicalTests._run_mental_stack_medical_escalation_bandage_to_pack(failures)
    MentalStackFeintMedicalTests._run_mental_stack_medical_escalation_no_bonus_when_no_failures(failures)
    ## Tier 1.7-1.8: stale swap-rank event cleanup and parry formation-pair state preservation.
    CombatRegressionHarnessCore._run_cancel_stale_swap_rank_resolve_events(failures)
    CombatRegressionHarnessCore._run_parry_preserves_formation_pair_state(failures)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    flush_harness_live_nodes()
    return {"ok": failures.is_empty(), "failures": failures}
