class_name CombatRegressionHarnessPartAPartA
extends RefCounted

## Manual / editor-invoked checks for Tier 1.5 - 1.9 (morale cohesion, engagement classifier, depth polearm, ZoC).
## CombatWeaponForm harness baseline: **`_harness_reset_combatants_form_balanced`** -> **`assign_form(...,
## harness_baseline)`**  -  home guard + **`form_str`** for parity rows; LIVE_PATHS **`#spawn--reset-path-wf-1a`** .
## **`#wf-soak-audit-status`**.
## Tier 4.2: **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**,
## **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust`**,
## **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**,
## **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust`**,
## **`_run_feint_windup_duration_mult_extends_state_duration_vs_oberhau`**,
## **`_run_feint_windup_duration_mult_extends_state_duration_vs_thrust`**,
## **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**,
## **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust`**,
## **`_run_feint_move_ai_distinct_feint_and_target_parts`**,
## **`_run_feint_move_ai_distinct_feint_and_target_parts_thrust`**,
## **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**,
## **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust`**,
## **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**,
## **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust`**,
## **`_run_feint_move_listing_spacing_long_dampens_vs_mid`**, **`_run_feint_move_listing_spacing_close_boosts_vs_mid`**,
## **`_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering`**,
## **`_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering`**,
## **`_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering`**,
## **`_run_feint_move_listing_stamina_low_dampens_feint_weight`**,
## **`_run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp`**,
## **`_run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult`**,
## **`_run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult`**,
## **`_run_feint_move_listing_doctrine_probing_multiplies_feint_weight`**,
## **`_run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight`**,
## **`_run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default`**,
## **`_run_feint_move_listing_stance_ai_feint_mult_ordering`**,
## **`_run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight`**,
## **`_run_feint_move_listing_defender_off_balance_boosts_feint_weight`**,
## **`_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance`**,
## **`_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting`**,
## **`_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult`,
## **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`****,
## **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`**,
## **`_run_feint_opts_from_choice_and_non_feint_attack_no_feint_part`**,
## **`_run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus`**,
## **`_run_feint_guard_zone_readthrough_par_bonus_when_readiness_high`**,
## **`_run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid`**,
## **`_run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid`**,
## **`_run_feint_target_reveal_progress_scales_readiness_mult`**,
## **`_run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough`**,
## **`_feint_guard_zone_sample_global_seed_for_modifier`** (PathResolver RNG seed scan),
## **`_run_feint_second_windup_clears_prior_telegraph_before_restamp`**,
## **`_run_feint_telegraph_scrubbed_on_combat_manager_restart`**; footwork / pair spacing  -
## **`_run_defense_spacing_band_modulates_parry_and_dodge`**,
## **`_run_defense_footwork_recovering_boosts_dodge_vs_waiting`**,
## **`_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult`**,
## **`_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close`**,
## **`_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance`**,
## **`_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close`**,
## **`_run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid`**,
## **`_run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid`**,
## **`_run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid`**,
## **`_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut`**,
## **`_run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense`**,
## **`_run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint`**,
## **`_run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina`**,
## **`_run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally`** (**`DefenseChoiceResolver`**,
## **`CombatAIActionPicker`**, **`distance_to`**, **`DEFENSE_SPACING_*`**,
## **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**, **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**,
## **`FEINT_GUARD_ZONE_READINESS_SPACING_*`**, **`feint_guard_zone_readiness_spacing_mult`**,
## **`CombatConstants.passive_parry_readiness_incoming_contact_mult`**, **`WeaponConstants`** **`thrust_feint`**).
## Tier 3.3: afterblow  -  **`_run_afterblow_deflected_triggers_full_resolve_hit`**,
## **`_run_afterblow_low_hindrance_allow_triggers_resolve_hit`** (fixed **`seed(1)`**, harness meta for mult);
## **`_run_afterblow_mid_hindrance_rand_cancel`** (**`seed(2)`**); **`_run_afterblow_mid_hindrance_rand_executes_hit`**
## (**`seed(0)`**, mult **0.55**); **`_afterblow_harness_seed_pending_cut`**. Hit reaction  -
## **`_run_hit_applier_sets_defender_guard_low_after_hit`** (**`AttackResultApplier`** **`hit`** ->
## **`GuardLineUpdater.set_guard_from_line`** low).
## Does not require a running battle scene. Example:
##   var r := CombatRegressionHarness.run_all()
##   assert(r.ok, str(r.failures))

const Snapshot := preload("res://world/PartyMemberSnapshot.gd")

const PartyManagerScript := preload("res://world/PartyManager.gd")

## Tier 3.2: full-stop **`parry_deflect`**  -  keys on **`parry_clash_context`** (see **`DefenseResolutionHandler`**)
## incl. Tier **3.0** strike kinematics + Tier **3.1** **`strike_measure_ratio`** (from **`pa`** when stamped, else
## **-1**); harness schema lock in **`_run_parry_clash_context_calibration_fields`**. **`parry_partial`** adds the same
## key set plus **`remaining_ratio`** / **`geometric_leak`**
## (**`_run_parry_partial_clash_context_calibration_fields`**); Tier **3.0** KE on partial uses reduced
## **`pa["velocity_m_s"]`**; **`CombatLogFormatter`** + harness
## **`_run_parry_partial_formatter_clash_context_branches`** (**`rem=`** when calibration **on**);
## **`_run_action_resolved_parry_partial_payload_includes_clash_context`** locks first **`action_resolved`** emit;
## **`_run_hit_clears_attacker_parry_calibration_fields`** locks **`hit`** erase of calibration carry;
## **`_run_hit_applier_sets_defender_guard_low_after_hit`** locks defender **`guard_line`** / **`guard_zone`** after
## **`hit`**; **`_run_parry_partial_bind_riposte_flags_when_aligned`** locks defender bind-riposte flags vs alignment +
## **`parry_control`** (misaligned **`erase`** vs aligned explicit **false**, stale-bind seed).
const PARRY_CLASH_CONTEXT_KEYS_FULL_STOP: Array[String] = [
    "archetype_id",
    "parry_control",
    "parry_p_a",
    "parry_c_d",
    "c_d_final",
    "m_a_parry",
    "m_d_parry",
    "m_a_velocity",
    "margin_ratio",
    "alignment",
    "defender_guard_line",
    "guard_angle_deg",
    "parry_time_to_react",
    "parry_readiness",
    "late_parry",
    "parry_off_balance",
    "is_block_parry",
    "attack_type",
    "contact_type",
    "effective_attack_line",
    "severity",
    "attack_angle_deg",
    "kinematic_delivery",
    "strike_velocity_m_s",
    "strike_kinetic_energy_j",
    "strike_measure_ratio",
]

## Tier 4.2: global **`seed`** for **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`** (wind-up rolls);
## refresh if Godot RNG drifts.
const _FEINT_WINDUP_HARNESS_SEED: int = 20260514
## Tier 4.2: global **`seed`** for **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`** (non-feint
## **`oberhau`** + **`target_part`** only).
const _FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED: int = 20260515
## After harnesses that call **`seed(...)`** for local control, restore global RNG so later **`run_all()`** entries stay
## order-stable (matches **`_windup_duration_for_bind_test`** post-**`AttackWindUpStarter.start`** restore).
const _HARNESS_RESTORE_GLOBAL_SEED: int = 90210


## Tier 4.2 harness helper: matches **`CombatAIActionPicker._get_action_weight`** feint-listing **`read_m`**
## (**`pr_def`** chain before stance / low-stamina / doctrine / deflect / off-balance terms).
static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.reset_harness_feature_load_overrides()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    _run_next_action_ready_map_matches_per_id(failures)
    _run_vacancy_reconcile_follow_up_regression(failures)
    _run_vacancy_reconcile_after_front_death(failures)
    CombatRegressionHarnessTier1Tail.run_early(failures)
    CombatRegressionHarnessFeintTempoTail.run_before_attention(failures)
    CombatRegressionHarnessAttentionFootworkTail.run(failures)
    CombatRegressionHarnessMentalStackIntegrationTail.run(failures)
    CombatRegressionHarnessWeaponFormTail.run(failures)
    CombatRegressionHarnessFeintTempoTail.run_after_attention(failures)
    CombatRegressionHarnessTier1Tail.run_mid(failures)
    _run_effective_pair_geometry_single_pass_matches_wrappers(failures)
    _run_windup_pending_attack_pair_geometry(failures)
    _run_strike_measure_constants_sanity(failures)
    _run_attack_result_applier_terminal_clears_pending(failures)
    _run_action_resolved_parry_deflect_payload_includes_clash_context(failures)
    _run_action_resolved_parry_partial_payload_includes_clash_context(failures)
    _run_hit_clears_attacker_parry_calibration_fields(failures)
    _run_hit_applier_sets_defender_guard_low_after_hit(failures)
    _run_parry_partial_bind_riposte_flags_when_aligned(failures)
    CombatRegressionHarnessTier1Tail.run_late(failures)
    CombatRegressionHarnessKinematicTail.run_core(failures)
    CombatRegressionHarnessKinematicTail.run(failures)
    CombatRegressionHarnessSimulation.run(failures)
    _run_weapon_blade_strong_fraction(failures)
    CombatRegressionHarnessFleeTail.run(failures)
    CombatRegressionHarnessMedicalMobilityTail.run(failures)
    _run_ai_attrition_offense_mult_duel_vs_line(failures)
    _run_wind_up_duration_bounded_for_move(failures)
    _run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11(failures)
    _run_kinematic_delivery_mace_weak_tap_pre_blunt_below_baseline_min(failures)
    _run_resolve_aborts_when_threat_lost_mid_combat_arm_loss(failures)
    CombatRegressionHarnessMedicalPhaseTail.run(failures)
    CombatRegressionHarnessProficiencyTail.run(failures)
    CombatRegressionHarnessProficiency1v1Tail.run(failures)
    CombatRegressionHarnessMuscleFatigueTail.run(failures)
    CombatRegressionHarnessTargeting1v1Tail.run(failures)
    _run_combat_end_enemy_win_stops_manager(failures)
    _run_medical_pain_shock_susceptibility_mult_from_effective_pain(failures)
    _run_medical_ambient_pain_shock_tick_enters_from_sustained_pain(failures)
    _run_medical_ambient_pain_shock_skips_when_feature_off(failures)
    _run_campaign_bridge_can_enter_combat_rejects_empty_party(failures)
    _run_campaign_bridge_can_enter_combat_rejects_unconscious(failures)
    _run_bind_riposte_contact_types_normalized(failures)
    _run_bind_riposte_contact_multipliers(failures)
    _run_bind_riposte_archetype_ordering_spear_faster_than_mace(failures)
    _run_p4h_bind_riposte_balance_suite(failures)
    _run_p4d_parry_bind_doc_code_parity_suite(failures)
    _run_flurry_bind_exchange_wind_up_reduced_vs_plain(failures)
    _run_flurry_bind_exchange_consumes_on_wind_up(failures)
    _run_flurry_bind_window_closes_on_hit(failures)
    _run_flurry_bind_listing_restricts_to_bind_partner(failures)
    _run_flurry_bind_opens_on_bind_deflect(failures)
    _run_flurry_bind_expires_after_window(failures)
    _run_flurry_bind_ui_gauge_label_when_window_open(failures)
    _run_flurry_bind_feature_flag_respects_runtime_toggle(failures)
    _run_p4g_flurry_bind_depth_suite(failures)
    _run_tier7_stamina_attack_cost_scales_with_intensity(failures)
    _run_tier7_stamina_parry_cost_scales_with_intensity(failures)
    _run_tier7_stamina_action_ready_cooldown_scales_with_fatigue(failures)
    _run_tier7_stamina_depletion_five_heavy_attacks_exhaust_pool(failures)
    _run_tier7_stamina_depletion_sustained_exchange_sim(failures)
    _run_stamina_effective_max_exhaustion_and_blood_cap(failures)
    _run_stamina_effective_refill_slows_with_exhaustion(failures)
    _run_opponent_pressure_defensive_uses_burst_ratio(failures)
    _run_tier7_parry_bind_riposte_gauge_bonus_on_deflect(failures)
    _run_formation_move_duration_lane_obstacle_slows_estimate(failures)
    _run_formation_move_duration_matches_flow_pair_start(failures)
    _run_formation_move_duration_ui_hint_when_lane_crowded(failures)
    _run_formation_diagram_health_bar_reflects_body_damage(failures)
    _run_formation_diagram_health_bar_tint_reflects_function_loss(failures)
    _run_formation_move_duration_listed_actions_stamp_hint(failures)
    _run_rotate_file_listed_for_adjacent_front_rank_allies(failures)
    _run_rotate_file_start_sets_duration_matches_estimate(failures)
    _run_rotate_file_resolve_stamps_rotate_cooldown(failures)
    _run_swap_rank_resolve_clears_doctrine_without_rotate_cooldown(failures)
    _run_rotate_file_lists_both_adjacent_wing_partners(failures)
    _run_rotate_file_cooldown_blocks_listing_and_resolve(failures)
    _run_rotate_file_reverse_pair_lock_blocks_re_swap(failures)
    _run_vacancy_plug_clears_doctrine_commitment(failures)
    _run_formation_shuffle_clears_close_block(failures)
    _run_pair_abort_cooldown_blocks_swap_rank_resolve(failures)
    _run_swap_rank_not_listed_without_tactical_gate(failures)
    _run_swap_rank_resolve_rejects_without_tactical_gate(failures)
    _run_resolve_close_attempt_long_success_closes_distance(failures)
    _run_automatic_doctrine_sets_pinch_on_hollow_when_enabled(failures)
    _run_automatic_doctrine_pinch_via_formation_recompute(failures)
    _run_p4c_numeric_superiority_auto_pinch(failures)
    _run_formation_move_duration_heavy_armor_slows_estimate(failures)
    _run_iv7_armor_burden_action_ready(failures)
    _run_iv7_armor_burden_passive_readiness(failures)
    _run_iv7b_stamina_engage_floor_suite(failures)
    _run_iv8_initiative_order_stagger(failures)
    _run_iv8_initiative_order_flag_off_parity(failures)
    _run_iv9_gap_column_compact_suppressed_when_flag_on(failures)
    _run_iv9_gap_column_flag_off_parity(failures)
    _run_iv9_gap_column_vacancy_reconcile_flag_on(failures)
    _run_iv9_gap_column_occupied_files_suite(failures)
    _run_iv9_gap_column_diagram_display_suite(failures)
    _run_iv9_gap_column_pair_geometry_column_arc_suite(failures)
    _run_iv9_gap_column_dual_mode_formation_targeting_suite(failures)
    _run_iv9_gap_column_topology_refresh_after_formation_moves(failures)
    _run_iv9_gap_column_topology_refresh_drag_back_fall_back_pair(failures)
    # IV-11 leader formation (slices 1 - 10)
    _run_iv11_leader_formation_ability_suite(failures)
    _run_iv11_register_party_leader_stamp_suite(failures)
    _run_iv11_campaign_bridge_party_leader_stamp_suite(failures)
    _run_iv11_register_enemy_leader_stamp_suite(failures)
    _run_iv11_encounter_spawn_enemy_leader_suite(failures)
    _run_iv11_party_leader_diagram_callout_suite(failures)
    _run_iv11_enemy_leader_diagram_callout_suite(failures)
    _run_iv11_party_leader_roster_callout_suite(failures)
    _run_iv11_leader_order_hold_lane_suite(failures)
    _run_iv11_leader_order_hold_lane_formatter_suite(failures)
    _run_iv11_leader_order_probing_suite(failures)
    _run_iv11_leader_order_probing_formatter_suite(failures)
    _run_iv11_leader_order_pinch_center_suite(failures)
    _run_iv11_leader_order_pinch_center_formatter_suite(failures)
    _run_iv11_enemy_commander_order_suite(failures)
    _run_iv11_leader_doctrine_cycle_suite(failures)
    _run_iv11_enemy_commander_doctrine_cycle_suite(failures)
    _run_iv11_leader_command_ai_weight_suite(failures)
    _run_iv11_enemy_commander_ai_weight_suite(failures)
    _run_iv11_pinch_outnumber_ai_weight_suite(failures)
    _run_iv11_enemy_pinch_outnumber_ai_weight_suite(failures)
    _run_iv11_f5_leader_order_trace_suite(failures)
    _run_iv13_weapon_reach_zoc_suite(failures)
    _run_iv13_weapon_reach_zoc_flag_off_parity(failures)
    _run_iv13_weapon_reach_zoc_distance_band_suite(failures)
    _run_iv12_slot_distraction_suite(failures)
    _run_iv12_slot_distraction_flag_off_parity(failures)
    _run_iv12_slot_distraction_ai_offense_damp(failures)
    _run_iv12_co_located_target_bias_suite(failures)
    _run_iv12_drag_back_dual_occupancy_distraction_suite(failures)
    _run_formation_move_duration_player_turn_hint_from_listed_actions(failures)
    _run_formation_move_duration_gauge_tooltip_listed_hint(failures)
    _run_formation_move_duration_gauge_tooltip_clears_when_not_waiting(failures)
    _run_formation_move_duration_gauge_tooltip_clears_on_resolve(failures)
    _run_p4b_formation_duration_ui_copy_suite(failures)
    _run_wind_up_rejects_move_not_on_weapon(failures)
    _run_formation_hit_reaction_extends_pair_move_duration(failures)
    _run_formation_hit_cancel_aborts_pair_move(failures)
    _run_incoming_parry_choice_blocks_non_chosen_attacker(failures)
    _run_incoming_parry_can_parry_all_weak_pair(failures)
    _run_iii1_incoming_parry_sector_tiebreak(failures)
    _run_iii3_deflect_bind_calibration_suite(failures)
    _run_weapon_extended_parry_dampens_defender_recovering_from_attack(failures)
    _run_weapon_committed_attack_dampens_defender_parry_c_d(failures)
    _run_weapon_commit_fraction_stab_before_overhead_cut(failures)
    _run_weapon_windup_stamps_commit_fraction_on_pa(failures)
    _run_weapon_commit_fraction_inferred_for_untagged_thrust_move(failures)
    _run_impact_station_mean_zero_spread_equals_move_mean(failures)
    _run_impact_station_mean_move_overrides_weapon_default(failures)
    _run_impact_station_mean_ordering_spear_thrust_above_mace_direct_blow(failures)
    _run_impact_station_mean_windup_stamps_move_override(failures)
    _run_impact_station_mean_every_move_def_tagged(failures)
    _run_impact_station_mean_feint_coiled_below_honest_cut(failures)
    _run_impact_station_mean_pole_swing_below_spear_thrust(failures)
    _run_formation_hit_cancel_ui_gauge_vulnerable_suffix(failures)
    _run_parry_opposite_deflect_thresholds(failures)
    _run_parry_defender_vs_attack_modifiers(failures)
    _run_parry_clash_context_calibration_fields(failures)
    _run_parry_partial_clash_context_calibration_fields(failures)
    _run_parry_control_bind_deflect_formula(failures)
    _run_follow_through_gate_at_low_remaining_ratio(failures)
    _run_follow_through_integration_gate(failures)
    _run_block_threshold_balance_test(failures)
    _run_block_threshold_asymmetric_test(failures)
    _run_weapon_melee_range_ordering(failures)
    _run_weapon_move_coverage(failures)
    _run_weapon_parts_mass_sum(failures)
    _run_weapon_feint_parry_coverage(failures)
    _run_weapon_angle_variance_ranges(failures)
    _run_guard_line_deflected_severity_from_margin_ratio(failures)
    _run_guard_from_move_sets_guard_line_and_zone(failures)
    _run_afterblow_no_pending_returns_false(failures)
    _run_afterblow_wrong_state_returns_false(failures)
    _run_afterblow_hindrance_block_cancels_pending(failures)
    _run_afterblow_deflected_triggers_full_resolve_hit(failures)
    _run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures)
    _run_afterblow_mid_hindrance_rand_cancel(failures)
    _run_afterblow_mid_hindrance_rand_executes_hit(failures)
    _run_campaign_bridge_entity_untreated_wounds(failures)
    _run_party_row_triage_formatter(failures)
    _run_combat_log_formatter_negligible(failures)
    _run_campaign_bridge_encounter_meta_from_node(failures)
    ## Phase 2: feint resistance gate  -  high-readiness defenders reject feints.
    _run_mental_stack_feint_resistance_high_readiness(failures)
    _run_mental_stack_feint_resistance_low_readiness_still_falls_for(failures)
    ## Phase 3: MS-L8 post-strike momentum layer.
    _run_ms_l8_post_strike_momentum_presses_target(failures)
    ## Phase 5: exhaustion gradient (offense weight lerp).
    _run_ms_l7_exhaustion_gradient_offense_weight(failures)
    ## Phase 6: MS-L9 positional awareness  -  disengage when surrounded + vulnerable.
    _run_ms_l9_positional_awareness_disengage_when_surrounded(failures)
    ## Phase 7: medical escalation TCCC ladder  -  pack boosted when bandage failed.
    _run_mental_stack_medical_escalation_bandage_to_pack(failures)
    _run_mental_stack_medical_escalation_no_bonus_when_no_failures(failures)
    ## Tier 1.7-1.8: stale swap-rank event cleanup and parry formation-pair state preservation.
    _run_cancel_stale_swap_rank_resolve_events(failures)
    _run_parry_preserves_formation_pair_state(failures)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    flush_harness_live_nodes()
    return {"ok": failures.is_empty(), "failures": failures}


static func _fail(arr: PackedStringArray, msg: String) -> void:
    arr.append(msg)


## Headless `-s` scripts call `quit()` without flushing deferred deletes  -  track orphan nodes and `free()` at harness
## exit.
## All node-lifecycle helpers forwarded to HarnessFixtures (single owner of `_harness_live_nodes`).

## Headless `-s` scripts call `quit()` without flushing deferred deletes  -  track orphan nodes and `free()` at harness
## exit.
## All node-lifecycle helpers forwarded to HarnessFixtures (single owner of `_harness_live_nodes`).

## Headless `-s` scripts call `quit()` without flushing deferred deletes  -  track orphan nodes and `free()` at harness
## exit.
## All node-lifecycle helpers forwarded to HarnessFixtures (single owner of `_harness_live_nodes`).

## Headless `-s` scripts call `quit()` without flushing deferred deletes  -  track orphan nodes and `free()` at harness
## exit.
## All node-lifecycle helpers forwarded to HarnessFixtures (single owner of `_harness_live_nodes`).


static func _track_harness_node(n: Node) -> void:
    HarnessFixtures._track_harness_node(n)


## Final sweep for standalone `_new_entity` rows that omit explicit teardown.

## Final sweep for standalone `_new_entity` rows that omit explicit teardown.

## Final sweep for standalone `_new_entity` rows that omit explicit teardown.


## Final sweep for standalone `_new_entity` rows that omit explicit teardown.
static func flush_harness_live_nodes() -> void:
    HarnessFixtures.flush_harness_live_nodes()


## Expand CombatWeaponForm: harness rows that set stance alias must sync **`weapon_form`** for picker/defense paths.

## Expand CombatWeaponForm: harness rows that set stance alias must sync **`weapon_form`** for picker/defense paths.

## Expand CombatWeaponForm: harness rows that set stance alias must sync **`weapon_form`** for picker/defense paths.


## Expand CombatWeaponForm: harness rows that set stance alias must sync **`weapon_form`** for picker/defense paths.
static func harness_sync_weapon_form_from_stance(c: Dictionary, stance: String) -> void:
    c["stance"] = stance
    c[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = CombatWeaponForm.normalize_form(stance)


## Preferred harness path: **`assign_form`** with home guard + stance alias sync (CombatWeaponForm-M5).

## Preferred harness path: **`assign_form`** with home guard + stance alias sync (CombatWeaponForm-M5).

## Preferred harness path: **`assign_form`** with home guard + stance alias sync (CombatWeaponForm-M5).


## Preferred harness path: **`assign_form`** with home guard + stance alias sync (CombatWeaponForm-M5).
static func harness_assign_form(mgr: Node, c: Dictionary, form: String) -> void:
    CombatWeaponForm.assign_form(mgr, c, form, "harness")


## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).

## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).

## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).


## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).
static func _run_next_action_ready_map_matches_per_id(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var cmap: Dictionary = CombatEventScheduler.build_next_action_ready_times(mgr)
    for c in mgr.combatants:
        if not CombatantEntityAccess.alive_bool(c, true):
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        var per: float = CombatEventScheduler.get_next_action_ready_at(mgr, cid)
        if per < 0.0:
            if cmap.has(cid):
                _fail(failures, "next_ready_map: id=%d no pending event but map has %s" % [cid, str(cmap[cid])])
        else:
            if not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001:
                _fail(failures, "next_ready_map: id=%d per=%.6f map=%s" % [cid, per, str(cmap.get(cid, "missing"))])
    _free_manager(mgr)


## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.

## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.

## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.


## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.
static func _run_vacancy_reconcile_follow_up_regression(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 2:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var clk0: float = float(mgr.combat_clock)
    var q0: int = mgr.event_queue.size()
    var snap0: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(mgr)
    CombatFormationFlow.finish_vacancy_reconcile_follow_up(mgr, [], snap0, true)
    if float(mgr.combat_clock) != clk0:
        _fail(failures, "vacancy_follow_up: empty changed_fids mutated combat_clock")
    if mgr.event_queue.size() != q0:
        _fail(failures, "vacancy_follow_up: empty changed_fids mutated event_queue size")
    var snap1: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(mgr)
    var ch1: Array = CombatFormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    if not ch1.is_empty():
        _fail(failures, "vacancy_follow_up: expected stable line after start, changed_fids=%s" % str(ch1))
    var q1: int = mgr.event_queue.size()
    CombatFormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch1, snap1, true)
    if mgr.event_queue.size() != q1:
        _fail(failures, "vacancy_follow_up: no-op reconcile follow-up mutated event_queue")
    var cmap: Dictionary = CombatEventScheduler.build_next_action_ready_times(mgr)
    for c in mgr.combatants:
        if not CombatantEntityAccess.alive_bool(c, true):
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        var per: float = CombatEventScheduler.get_next_action_ready_at(mgr, cid)
        if per >= 0.0 and (not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001):
            _fail(failures, "vacancy_follow_up: map/per mismatch id=%d" % cid)
    _free_manager(mgr)


## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.

## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.

## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.


## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.
static func _run_vacancy_reconcile_after_front_death(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var front_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    _soak_kill_combatant(mgr, front_id)
    var snap: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = CombatFormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    CombatFormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    var living_rank0_player: bool = false
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "player"):
            continue
        if CombatantEntityAccess.rank_int(c, -9) == 0:
            living_rank0_player = true
            break
    if not living_rank0_player:
        _fail(failures, "vacancy_death: no living player at rank 0 after plug")
    _free_manager(mgr)


## Entity creation  -  forwards to HarnessFixtures.

## Entity creation  -  forwards to HarnessFixtures.

## Entity creation  -  forwards to HarnessFixtures.


## Entity creation  -  forwards to HarnessFixtures.
static func _new_entity(weapon_id: String) -> CoreEntity:
    return HarnessFixtures._new_entity(weapon_id)


static func _new_entity_unarmed() -> CoreEntity:
    return HarnessFixtures._new_entity_unarmed()


## Manager setup  -  forwards to HarnessFixtures.

## Manager setup  -  forwards to HarnessFixtures.

## Manager setup  -  forwards to HarnessFixtures.


## Manager setup  -  forwards to HarnessFixtures.
static func _harness_start_1v1(
    weapon_id: String = "SWORD",
    player_side: Dictionary = {"files": 1, "ranks": 1},
    enemy_side: Dictionary = {"files": 1, "ranks": 1}
) -> Node:
    return HarnessFixtures._harness_start_1v1(weapon_id, player_side, enemy_side)


static func _harness_reset_combatants_form_balanced(mgr: Node) -> void:
    HarnessFixtures._harness_reset_combatants_form_balanced(mgr)


static func _harness_start_player_only(player_side: Dictionary = {"files": 1, "ranks": 1}) -> Node:
    return HarnessFixtures._harness_start_player_only(player_side)


## Equipment  -  forwards to HarnessFixtures.

## Equipment  -  forwards to HarnessFixtures.

## Equipment  -  forwards to HarnessFixtures.


## Equipment  -  forwards to HarnessFixtures.
static func _harness_equip_heavy_plate_kit(e: CoreEntity) -> void:
    HarnessFixtures._harness_equip_heavy_plate_kit(e)


## Roster / formation lookups  -  forwards to HarnessFixtures.

## Roster / formation lookups  -  forwards to HarnessFixtures.

## Roster / formation lookups  -  forwards to HarnessFixtures.


## Roster / formation lookups  -  forwards to HarnessFixtures.
static func _harness_find_living_at_rank_file(mgr: Node, side: String, rank: int, file: int) -> Dictionary:
    return HarnessFixtures._harness_find_living_at_rank_file(mgr, side, rank, file)


## Formation fixtures  -  forwards to HarnessFixtures.

## Formation fixtures  -  forwards to HarnessFixtures.

## Formation fixtures  -  forwards to HarnessFixtures.


## Formation fixtures  -  forwards to HarnessFixtures.
static func _harness_sparse_post_flee_6v3_mgr(survivor_file: int = 4, fled_files: Array = [0, 1, 2, 3]) -> Dictionary:
    return HarnessFixtures._harness_sparse_post_flee_6v3_mgr(survivor_file, fled_files)


static func _harness_7v3_wing_rank0_fixtures() -> Array:
    return HarnessFixtures._harness_7v3_wing_rank0_fixtures()


static func _harness_bind_pair_long_band(p: Dictionary, e: Dictionary) -> void:
    HarnessFixtures._harness_bind_pair_long_band(p, e)


## Guard-line helpers  -  forwards to HarnessFixtures.

## Guard-line helpers  -  forwards to HarnessFixtures.

## Guard-line helpers  -  forwards to HarnessFixtures.


## Guard-line helpers  -  forwards to HarnessFixtures.
static func _harness_cardinal_attack_line(cardinal: String) -> String:
    return HarnessFixtures._harness_cardinal_attack_line(cardinal)


static func _harness_adjacent_lines_for(cardinal_attack: String) -> Array:
    return HarnessFixtures._harness_adjacent_lines_for(cardinal_attack)


static func _harness_opposite_cardinal(cardinal: String) -> String:
    return HarnessFixtures._harness_opposite_cardinal(cardinal)


## IV-9 harness helpers  -  forwards to HarnessFixtures.

## IV-9 harness helpers  -  forwards to HarnessFixtures.

## IV-9 harness helpers  -  forwards to HarnessFixtures.


## IV-9 harness helpers  -  forwards to HarnessFixtures.
static func _harness_iv9_player_rotate_file_listed(mgr: Node) -> bool:
    return HarnessFixtures._harness_iv9_player_rotate_file_listed(mgr)


static func _harness_iv9_center_rank0_can_melee_threaten(mgr: Node) -> bool:
    return HarnessFixtures._harness_iv9_center_rank0_can_melee_threaten(mgr)


static func _harness_iv9_gap_column_cache_matches_occupied(formation: Dictionary) -> bool:
    return HarnessFixtures._harness_iv9_gap_column_cache_matches_occupied(formation)


static func _harness_iv9_resolve_adjacent_rank_pair_move(
    mgr: Node, initiator_id: int, partner_id: int, move_kind: String
) -> void:
    HarnessFixtures._harness_iv9_resolve_adjacent_rank_pair_move(mgr, initiator_id, partner_id, move_kind)


## Cleanup  -  forwards to HarnessFixtures.

## Cleanup  -  forwards to HarnessFixtures.

## Cleanup  -  forwards to HarnessFixtures.


## Cleanup  -  forwards to HarnessFixtures.
static func _free_harness_node(n: Node) -> void:
    HarnessFixtures._free_harness_node(n)


static func _free_manager(mgr: Node) -> void:
    HarnessFixtures._free_manager(mgr)


## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager  -  keeps run_all() order-stable.

## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager  -  keeps run_all() order-stable.

## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager  -  keeps run_all() order-stable.


## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager  -  keeps run_all() order-stable.
static func _free_manager_restore_global_rng(mgr: Node) -> void:
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Harness utility forwards  -  all forwarded to HarnessFixtures.

## Harness utility forwards  -  all forwarded to HarnessFixtures.

## Harness utility forwards  -  all forwarded to HarnessFixtures.


## Harness utility forwards  -  all forwarded to HarnessFixtures.
static func _windup_duration_for_bind_test(weapon_id: String, move_id: String, bind: bool) -> float:
    return HarnessFixtures._windup_duration_for_bind_test(weapon_id, move_id, bind)


static func _shuffle_int_array_in_place(ids: Array, rng: RandomNumberGenerator) -> void:
    HarnessFixtures._shuffle_int_array_in_place(ids, rng)


static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
    HarnessFixtures._soak_kill_combatant(mgr, combatant_id)


## Tier 1.7 - 1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot
## stays in sync.

## Tier 1.7 - 1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot
## stays in sync.

## Tier 1.7 - 1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot
## stays in sync.


## Tier 1.7 - 1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot
## stays in sync.
static func _run_cancel_stale_swap_rank_resolve_events(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = CombatantEntityAccess.id_int(p0)
    var id1: int = CombatantEntityAccess.id_int(p1)
    CombatEventScheduler.schedule_event(
        mgr,
        {
            "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
            "combatant_id": id0,
            "resolve_at": mgr.combat_clock + 10.0,
            "data": {"partner_id": id1, "move_kind": "swap_rank"}
        }
    )
    CombatEventScheduler.schedule_event(
        mgr,
        {
            "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
            "combatant_id": id1,
            "resolve_at": mgr.combat_clock + 11.0,
            "data": {"partner_id": id0, "move_kind": "swap_rank"}
        }
    )
    var swap_queued: int = 0
    for ev in mgr.event_queue:
        if (
            typeof(ev) == TYPE_DICTIONARY
            and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE
        ):
            swap_queued += 1
    if swap_queued != 2:
        _fail(failures, "swap_cancel_setup: expected 2 stale swap_rank_resolve events, got %d" % swap_queued)
        _free_manager(mgr)
        return
    CombatEventScheduler.cancel_pending_swap_rank_pair_events(mgr, id0, id1)
    for ev in mgr.event_queue:
        if (
            typeof(ev) == TYPE_DICTIONARY
            and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE
        ):
            _fail(failures, "swap_cancel: stale swap_rank_resolve should be removed")
            _free_manager(mgr)
            return
    _free_manager(mgr)


## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).

## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).

## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).


## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).
static func _run_parry_preserves_formation_pair_state(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var en: Dictionary = mgr.combatants[2]
    var id0: int = CombatantEntityAccess.id_int(p0)
    var id1: int = CombatantEntityAccess.id_int(p1)
    var eid: int = CombatantEntityAccess.id_int(en)
    CombatFormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    if CombatantEntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
        _fail(
            failures,
            (
                "parry_swap: expected rank0 in swap_rank after start_pair_move (got %s)"
                % CombatantEntityAccess.state_str(p0)
            )
        )
        _free_manager(mgr)
        return
    if CombatantEntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
        _fail(failures, "parry_swap: expected rank1 in swap_rank after start_pair_move")
        _free_manager(mgr)
        return
    en["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high"}
    AttackResultApplier.apply_result(
        mgr,
        eid,
        {
            "action": "parry_deflect",
            "target_id": id0,
            "recovery_duration": 0.5,
            "parry_clash_context": {"archetype_id": "", "parry_control": 0.0}
        }
    )
    if CombatantEntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
        _fail(
            failures,
            (
                "parry_swap: parry_deflect must not set defender to waiting mid pair move (got %s)"
                % CombatantEntityAccess.state_str(p0)
            )
        )
    if CombatantEntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
        _fail(failures, "parry_swap: partner must stay swap_rank (got %s)" % CombatantEntityAccess.state_str(p1))
    _free_manager(mgr)

## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.

## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.
