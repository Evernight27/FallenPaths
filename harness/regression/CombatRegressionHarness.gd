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


static var _test_functions_cache: Array = []

static func get_test_functions() -> Array:
    if not _test_functions_cache.is_empty():
        return _test_functions_cache
    var tests: Array = []
    tests.append(Callable(CombatRegressionHarnessCore, "_run_next_action_ready_map_matches_per_id"))
    tests.append(Callable(CombatRegressionHarnessCore, "_run_vacancy_reconcile_follow_up_regression"))
    tests.append(Callable(CombatRegressionHarnessCore, "_run_vacancy_reconcile_after_front_death"))
    tests.append(Callable(CombatRegressionHarnessTier1Tail, "run_early"))
    tests.append(Callable(CombatRegressionHarnessFeintTempoTail, "run_before_attention"))
    tests.append(Callable(CombatRegressionHarnessAttentionFootworkTail, "run"))
    tests.append(Callable(CombatRegressionHarnessMentalStackIntegrationTail, "run"))
    tests.append(Callable(CombatRegressionHarnessWeaponFormTail, "run"))
    tests.append(Callable(CombatRegressionHarnessFeintTempoTail, "run_after_attention"))
    tests.append(Callable(CombatRegressionHarnessTier1Tail, "run_mid"))
    tests.append(Callable(SoakFpOperationalLogDedupeTests, "_run_effective_pair_geometry_single_pass_matches_wrappers"))
    tests.append(Callable(SoakFpOperationalLogDedupeTests, "_run_windup_pending_attack_pair_geometry"))
    tests.append(Callable(SoakFpOperationalLogDedupeTests, "_run_strike_measure_constants_sanity"))
    tests.append(Callable(SoakFpOperationalLogDedupeTests, "_run_attack_result_applier_terminal_clears_pending"))
    tests.append(Callable(SoakFpOperationalLogDedupeTests, "_run_action_resolved_parry_deflect_payload_includes_clash_context"))
    tests.append(Callable(ParryActionResolvedTests, "_run_action_resolved_parry_partial_payload_includes_clash_context"))
    tests.append(Callable(ParryActionResolvedTests, "_run_hit_clears_attacker_parry_calibration_fields"))
    tests.append(Callable(ParryActionResolvedTests, "_run_hit_applier_sets_defender_guard_low_after_hit"))
    tests.append(Callable(ParryActionResolvedTests, "_run_parry_partial_bind_riposte_flags_when_aligned"))
    tests.append(Callable(ParryActionResolvedTests, "_run_parry_partial_bind_skips_counterstrike_window_when_flag_off"))
    tests.append(Callable(ParryActionResolvedTests, "_run_parry_clash_context_carries_strike_momentum"))
    tests.append(Callable(ParryActionResolvedTests, "_run_full_parry_recoil_scales_with_parry_control"))
    tests.append(Callable(ArmWoundDegradationTests, "_run_arm_wound_grip_sub_region_and_severity_ordering"))
    tests.append(Callable(ArmWoundDegradationTests, "_run_arm_wound_attack_modifier_and_parry_ease"))
    tests.append(Callable(ArmWoundDegradationTests, "_run_two_handed_weapon_offhand_arm_degradation"))
    tests.append(Callable(LeadLegFunctionalityTests, "_run_lead_leg_functionality_symmetric_vs_lead"))
    tests.append(Callable(LeadLegFunctionalityTests, "_run_lead_leg_destroyed_drive_floor"))
    tests.append(Callable(LeadLegFunctionalityTests, "_run_lead_leg_close_advance_drive"))
    tests.append(Callable(LeadLegFunctionalityTests, "_run_lead_leg_correlates_with_dominant_hand"))
    tests.append(Callable(PersistentFacingTests, "run_facing_turn_window_s"))
    tests.append(Callable(PersistentFacingTests, "run_facing_turn_no_window_neutral"))
    tests.append(Callable(PersistentFacingTests, "run_facing_turn_stamp_dips_parry_capacity"))
    tests.append(Callable(PersistentFacingTests, "run_facing_turn_expired_neutral"))
    tests.append(Callable(PersistentFacingTests, "run_facing_turn_pile_on_extends"))
    tests.append(Callable(PersistentFacingTests, "run_facing_turn_pile_on_capped"))
    tests.append(Callable(WoundedDefenderCautionTests, "_run_wounded_defender_caution_scaling"))
    tests.append(Callable(WoundedDefenderCautionTests, "_run_thrust_internal_bleed"))
    tests.append(Callable(WoundedDefenderCautionTests, "_run_head_skull_ko_gate"))
    tests.append(Callable(WoundedDefenderCautionTests, "_run_vital_destruction_grace"))
    tests.append(Callable(WoundedDefenderCautionTests, "_run_vital_consciousness_cap"))
    tests.append(Callable(WoundedDefenderCautionTests, "_run_blunt_ke_crush_capacity"))
    tests.append(Callable(CombatRegressionHarnessTier1Tail, "run_late"))
    tests.append(Callable(CombatRegressionHarnessKinematicTail, "run_core"))
    tests.append(Callable(CombatRegressionHarnessKinematicTail, "run"))
    tests.append(Callable(CombatRegressionHarnessSimulation, "run"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_weapon_blade_strong_fraction"))
    tests.append(Callable(CombatRegressionHarnessFleeTail, "run"))
    tests.append(Callable(CombatRegressionHarnessMedicalMobilityTail, "run"))
    tests.append(Callable(CombatRegressionHarnessInfectionStagingTail, "run"))
    tests.append(Callable(CombatRegressionHarnessTetanusTail, "run"))
    tests.append(Callable(CombatRegressionHarnessScarTail, "run"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_ai_attrition_offense_mult_duel_vs_line"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_wind_up_duration_bounded_for_move"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_kinematic_delivery_mace_weak_tap_pre_blunt_below_baseline_min"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_resolve_aborts_when_threat_lost_mid_combat_arm_loss"))
    tests.append(Callable(CombatRegressionHarnessMedicalPhaseTail, "run"))
    tests.append(Callable(CombatRegressionHarnessProficiencyTail, "run"))
    tests.append(Callable(CombatRegressionHarnessProficiency1v1Tail, "run"))
    tests.append(Callable(CombatRegressionHarnessMuscleFatigueTail, "run"))
    tests.append(Callable(CombatRegressionHarnessTargeting1v1Tail, "run"))
    tests.append(Callable(ParryActionResolvedTests, "_run_combat_end_enemy_win_stops_manager"))
    tests.append(Callable(ParryActionResolvedTests, "_run_duel_auto_end_detection"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_medical_pain_shock_susceptibility_mult_from_effective_pain"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_medical_ambient_pain_shock_tick_enters_from_sustained_pain"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_medical_ambient_pain_shock_skips_when_feature_off"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_campaign_bridge_can_enter_combat_rejects_empty_party"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_campaign_bridge_can_enter_combat_rejects_unconscious"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_bind_riposte_contact_types_normalized"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_bind_riposte_contact_multipliers"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_bind_riposte_archetype_ordering_spear_faster_than_mace"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_p4h_bind_riposte_balance_suite"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_p4d_parry_bind_doc_code_parity_suite"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_exchange_wind_up_reduced_vs_plain"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_exchange_consumes_on_wind_up"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_window_closes_on_hit"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_listing_restricts_to_bind_partner"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_opens_on_bind_deflect"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_expires_after_window"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_ui_gauge_label_when_window_open"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_flurry_bind_feature_flag_respects_runtime_toggle"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_p4g_flurry_bind_depth_suite"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_tier7_stamina_attack_cost_scales_with_intensity"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_tier7_stamina_parry_cost_scales_with_intensity"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_tier7_stamina_action_ready_cooldown_scales_with_fatigue"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_tier7_stamina_depletion_five_heavy_attacks_exhaust_pool"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_tier7_stamina_depletion_sustained_exchange_sim"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_stamina_effective_max_exhaustion_and_blood_cap"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_stamina_effective_refill_slows_with_exhaustion"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_stamina_refill_exponential_half_time_and_taper"))
    tests.append(Callable(KinematicDeliveryExhaustionTests, "_run_exhaustion_timing_vs_power_differentiation"))
    tests.append(Callable(KinematicDeliveryExhaustionTests, "_run_exhaustion_metabolic_stress_accumulation"))
    tests.append(Callable(KinematicDeliveryExhaustionTests, "_run_exhaustion_consecutive_action_scaling"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_opponent_pressure_defensive_uses_burst_ratio"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_tier7_parry_bind_riposte_gauge_bonus_on_deflect"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_lane_obstacle_slows_estimate"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_matches_flow_pair_start"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_ui_hint_when_lane_crowded"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_diagram_health_bar_reflects_body_damage"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_diagram_health_bar_tint_reflects_function_loss"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_listed_actions_stamp_hint"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_rotate_file_listed_for_adjacent_front_rank_allies"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_rotate_file_start_sets_duration_matches_estimate"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_rotate_file_resolve_stamps_rotate_cooldown"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_swap_rank_resolve_clears_doctrine_without_rotate_cooldown"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_rotate_file_lists_both_adjacent_wing_partners"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_rotate_file_cooldown_blocks_listing_and_resolve"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_rotate_file_reverse_pair_lock_blocks_re_swap"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_vacancy_plug_clears_doctrine_commitment"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_formation_shuffle_clears_close_block"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_pair_abort_cooldown_blocks_swap_rank_resolve"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_swap_rank_not_listed_without_tactical_gate"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_swap_rank_resolve_rejects_without_tactical_gate"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_resolve_close_attempt_long_success_closes_distance"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_automatic_doctrine_sets_pinch_on_hollow_when_enabled"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_automatic_doctrine_pinch_via_formation_recompute"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_p4c_numeric_superiority_auto_pinch"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_formation_move_duration_heavy_armor_slows_estimate"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_formation_move_duration_leg_injury_slows_estimate"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_fractured_leg_retains_hobbling_functionality"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv7_armor_burden_action_ready"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv7_armor_burden_passive_readiness"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_iv7b_stamina_engage_floor_suite"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv8_initiative_order_stagger"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv8_initiative_order_flag_off_parity"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv9_gap_column_compact_suppressed_when_flag_on"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv9_gap_column_flag_off_parity"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_iv9_gap_column_vacancy_reconcile_flag_on"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv9_gap_column_occupied_files_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv9_gap_column_diagram_display_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv9_gap_column_pair_geometry_column_arc_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv9_gap_column_dual_mode_formation_targeting_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv9_gap_column_topology_refresh_after_formation_moves"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv9_gap_column_topology_refresh_drag_back_fall_back_pair"))
    # IV-11 leader formation (slices 1 - 10)
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_leader_formation_ability_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_register_party_leader_stamp_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_campaign_bridge_party_leader_stamp_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_register_enemy_leader_stamp_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_encounter_spawn_enemy_leader_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_party_leader_diagram_callout_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_enemy_leader_diagram_callout_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_party_leader_roster_callout_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_leader_order_hold_lane_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_leader_order_hold_lane_formatter_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_leader_order_probing_suite"))

    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_leader_order_pinch_center_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_leader_order_pinch_center_formatter_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_enemy_commander_order_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_leader_doctrine_cycle_suite"))
    tests.append(Callable(Iv9GapColumnTests, "_run_iv11_enemy_commander_doctrine_cycle_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_leader_command_ai_weight_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_enemy_commander_ai_weight_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_pinch_outnumber_ai_weight_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_enemy_pinch_outnumber_ai_weight_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv11_f5_leader_order_trace_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv13_weapon_reach_zoc_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv13_weapon_reach_zoc_flag_off_parity"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv13_weapon_reach_zoc_distance_band_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv12_slot_distraction_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv12_slot_distraction_flag_off_parity"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv12_slot_distraction_ai_offense_damp"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv12_co_located_target_bias_suite"))
    tests.append(Callable(Iv11LeaderTargetingTests, "_run_iv12_drag_back_dual_occupancy_distraction_suite"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_player_turn_hint_from_listed_actions"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_gauge_tooltip_listed_hint"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_gauge_tooltip_clears_when_not_waiting"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_formation_move_duration_gauge_tooltip_clears_on_resolve"))
    tests.append(Callable(RotateFileDoctrineTests, "_run_p4b_formation_duration_ui_copy_suite"))
    tests.append(Callable(KinematicDeliveryStaminaFormationTests, "_run_wind_up_rejects_move_not_on_weapon"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_formation_hit_reaction_extends_pair_move_duration"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_formation_hit_cancel_aborts_pair_move"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_incoming_parry_choice_blocks_non_chosen_attacker"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_incoming_parry_can_parry_all_weak_pair"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_iii1_incoming_parry_sector_tiebreak"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_iii3_deflect_bind_calibration_suite"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_weapon_extended_parry_dampens_defender_recovering_from_attack"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_weapon_committed_attack_dampens_defender_parry_c_d"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_weapon_commit_fraction_stab_before_overhead_cut"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_weapon_windup_stamps_commit_fraction_on_pa"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_weapon_commit_fraction_inferred_for_untagged_thrust_move"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_zero_spread_equals_move_mean"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_move_overrides_weapon_default"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_ordering_spear_thrust_above_mace_direct_blow"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_windup_stamps_move_override"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_every_move_def_tagged"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_feint_coiled_below_honest_cut"))
    tests.append(Callable(ImpactStationWeaponCommitTests, "_run_impact_station_mean_pole_swing_below_spear_thrust"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_formation_hit_cancel_ui_gauge_vulnerable_suffix"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_parry_opposite_deflect_thresholds"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_parry_defender_vs_attack_modifiers"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_clash_context_calibration_fields"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_partial_clash_context_calibration_fields"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_control_bind_deflect_formula"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_bind_friction_blade_width"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_morale_parry_readiness"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_max_damage_reduction_cap"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_bind_pressure_defender_penalty"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_deflect_recovery_cost"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_deflect_immediate_guard_displacement"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_off_balance_deflect_scaled_duration"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_decision_named_constants"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_bonus_scales_with_control"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_velocity_named_constants"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_reach_disparity_named_constants"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_flex_factor_blade_slenderness"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_bind_pressure_decay_constants"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_partial_parry_stamina_discount"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_mid_swing_parry_penalty"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_recoil_mass_scale"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_fatigue_time_decay"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_two_handed_parry_bracing"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_recoil_alignment_scale"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_recoil_flex_scale"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_recoil_progress_scale"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_parry_recoil_body_mass_scale"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_follow_through_gate_at_low_remaining_ratio"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_follow_through_integration_gate"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_block_threshold_balance_test"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_block_threshold_asymmetric_test"))
    tests.append(Callable(ParryCalibrationBlockTests, "_run_weapon_melee_range_ordering"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_weapon_move_coverage"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_weapon_parts_mass_sum"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_weapon_sharpness_effective_contact_width"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_weapon_feint_parry_coverage"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_weapon_angle_variance_ranges"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_guard_line_deflected_severity_from_margin_ratio"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_guard_from_move_sets_guard_line_and_zone"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_no_pending_returns_false"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_wrong_state_returns_false"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_hindrance_block_cancels_pending"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_deflected_triggers_full_resolve_hit"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_low_hindrance_allow_triggers_resolve_hit"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_mid_hindrance_rand_cancel"))
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_afterblow_mid_hindrance_rand_executes_hit"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_campaign_bridge_entity_untreated_wounds"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_party_row_triage_formatter"))
    tests.append(Callable(SoakFpTraceFormatterTests, "_run_combat_log_formatter_negligible"))
    tests.append(Callable(FlurryBindCampaignTests, "_run_campaign_bridge_encounter_meta_from_node"))
    ## Phase 2: feint resistance gate  -  high-readiness defenders reject feints.
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_mental_stack_feint_resistance_high_readiness"))
    tests.append(Callable(MentalStackFeintMedicalTests, "_run_mental_stack_feint_resistance_low_readiness_still_falls_for"))
    ## Phase 3: MS-L8 post-strike momentum layer.
    tests.append(Callable(WeaponAfterblowGuardTests, "_run_ms_l8_post_strike_momentum_presses_target"))
    ## Phase 5: exhaustion gradient (offense weight lerp).
    tests.append(Callable(MentalStackFeintMedicalTests, "_run_ms_l7_exhaustion_gradient_offense_weight"))
    ## Phase 6: MS-L9 positional awareness  -  disengage when surrounded + vulnerable.
    tests.append(Callable(MentalStackFeintMedicalTests, "_run_ms_l9_positional_awareness_disengage_when_surrounded"))
    ## Phase 7: medical escalation TCCC ladder  -  pack boosted when bandage failed.
    tests.append(Callable(MentalStackFeintMedicalTests, "_run_mental_stack_medical_escalation_bandage_to_pack"))
    tests.append(Callable(MentalStackFeintMedicalTests, "_run_mental_stack_medical_escalation_no_bonus_when_no_failures"))
    ## Tier 1.7-1.8: stale swap-rank event cleanup and parry formation-pair state preservation.
    tests.append(Callable(CombatRegressionHarnessCore, "_run_cancel_stale_swap_rank_resolve_events"))
    tests.append(Callable(CombatRegressionHarnessCore, "_run_parry_preserves_formation_pair_state"))
    ## MS/EX-1: mercy & execution (downed predicate, weights, listing, resolve).
    tests.append(Callable(CombatRegressionHarnessMercyExecuteTail, "run"))

    _test_functions_cache = tests
    return tests


static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.reset_harness_feature_load_overrides()
    CombatConstants.set_feature_position_angle_footwork_load(true)

    var all: Array = get_test_functions()
    var patterns: PackedStringArray = _resolve_test_filter_patterns()
    var selected: Array = all
    if not patterns.is_empty():
        selected = []
        for tf in all:
            if tf is Callable and _matches_filter(tf as Callable, patterns):
                selected.append(tf)
        if selected.is_empty():
            return {
                "ok": false,
                "failures": PackedStringArray(
                    [
                        "FP_HARNESS_TESTS=\"%s\" matched 0 of %d tests; none ran (check the patterns)"
                        % [", ".join(patterns), all.size()]
                    ]
                ),
            }
        print("=== CombatRegressionHarness: FP_HARNESS_TESTS=\"%s\" selected %d/%d ===" % [", ".join(patterns), selected.size(), all.size()])

    ## Run selected test functions sequentially in a single Godot process.
    ## FP_HARNESS_TESTS (unset = all) narrows the run to matching class/method names.
    var timing_rows: PackedStringArray = PackedStringArray()
    for tf in selected:
        if tf is Callable:
            var t0: int = Time.get_ticks_msec()
            tf.call(failures)
            timing_rows.append("%d\t%s" % [Time.get_ticks_msec() - t0, _callable_label(tf as Callable)])
        seed(_HARNESS_RESTORE_GLOBAL_SEED)

    _write_timing_report(selected, timing_rows)
    flush_harness_live_nodes()
    return {"ok": failures.is_empty(), "failures": failures}


## Per-test durations (ms, desc) for `.regression_timing.txt` — which regression tail dominates.
static func _write_timing_report(selected: Array, timing_rows: PackedStringArray) -> void:
    var rows: Array = []
    for i in selected.size():
        var parts: PackedStringArray = timing_rows[i].split("\t")
        if parts.size() < 2:
            continue
        rows.append({"ms": int(parts[0]), "label": str(parts[1])})
    rows.sort_custom(func(a, b): return int(a.ms) > int(b.ms))
    var out: PackedStringArray = PackedStringArray()
    out.append("--- FP_REGRESSION_TIMING —")
    var total_ms: int = 0
    for r in rows:
        total_ms += int(r.ms)
        out.append("%d\t%s" % [int(r.ms), str(r.label)])
    out.append("--- TOTAL_MS=%d tests=%d —" % [total_ms, rows.size()])
    var root: String = ProjectSettings.globalize_path("res://")
    var f: FileAccess = FileAccess.open(root.path_join(".regression_timing.txt"), FileAccess.WRITE)
    if f != null:
        f.store_string("\n".join(out) + "\n")
        f.close()


## All registered regression test labels (ClassName.method, lowercased).
## FP_HARNESS_LIST prints these so a targeted FP_HARNESS_TESTS run can be chosen without grepping source.
static func list_test_labels() -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    for tf in get_test_functions():
        if tf is Callable:
            out.append(_callable_label(tf as Callable))
    return out


## FP_HARNESS_TESTS is a comma-separated list of case-insensitive substrings; a test runs if any
## pattern is a substring of its ClassName.method label. Empty (env unset) = run every test.
static func _resolve_test_filter_patterns() -> PackedStringArray:
    var raw: String = OS.get_environment("FP_HARNESS_TESTS").strip_edges()
    var out: PackedStringArray = PackedStringArray()
    if raw.is_empty():
        return out
    for part in raw.split(","):
        var p: String = part.strip_edges().to_lower()
        if not p.is_empty():
            out.append(p)
    return out


static func _matches_filter(tf: Callable, patterns: PackedStringArray) -> bool:
    var label: String = _callable_label(tf)
    for p in patterns:
        if label.contains(p):
            return true
    return false


static func _callable_label(tf: Callable) -> String:
    var owner: String = ""
    var obj: Variant = tf.get_object()
    if obj is GDScript:
        owner = str((obj as GDScript).get_global_name())
    return (owner + "." + tf.get_method()).to_lower()
