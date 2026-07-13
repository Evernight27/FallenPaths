class_name CombatRegressionHarnessFeintTempoTail
extends RefCounted
## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).


static func run_before_attention(failures: PackedStringArray) -> void:
    FeintTempoWindupListingTests._run_feint_windup_options_stamp_pa_and_telegraph_guard_zone(failures)
    FeintTempoWindupListingTests._run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust(
        failures
    )
    FeintTempoWindupListingTests._run_feint_windup_duration_mult_extends_state_duration_vs_oberhau(
        failures
    )
    FeintTempoWindupListingTests._run_feint_windup_duration_mult_extends_state_duration_vs_thrust(
        failures
    )
    FeintTempoWindupListingTests._run_feint_windup_target_only_sets_defender_guard_zone_to_target(
        failures
    )
    FeintTempoWindupListingTests._run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust(
        failures
    )
    FeintTempoWindupListingTests._run_feint_move_ai_distinct_feint_and_target_parts(failures)
    FeintTempoWindupListingTests._run_feint_move_ai_distinct_feint_and_target_parts_thrust(failures)
    FeintTempoWindupListingTests._run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau(
        failures
    )
    FeintTempoWindupListingTests._run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust(
        failures
    )
    (
        FeintTempoWindupListingTests
        . _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard(failures)
    )
    (
        FeintTempoWindupListingTests
        . _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust(failures)
    )
    FeintTempoWindupListingTests._run_feint_move_listing_spacing_long_dampens_vs_mid(failures)
    FeintTempoWindupListingTests._run_feint_move_listing_spacing_close_boosts_vs_mid(failures)
    (
        FeintTempoWindupListingTests
        . _run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering(failures)
    )
    (
        FeintTempoListingCounterTempoTests
        . _run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering(failures)
    )
    (
        FeintTempoListingCounterTempoTests
        . _run_feint_move_listing_readiness_recovery_curve_when_defender_recovering(failures)
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_stamina_low_dampens_feint_weight(failures)
    FeintTempoListingCounterTempoTests._run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp(
        failures
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult(
        failures
    )
    (
        FeintTempoListingCounterTempoTests
        . _run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult(failures)
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_doctrine_probing_multiplies_feint_weight(
        failures
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight(
        failures
    )
    (
        FeintTempoListingCounterTempoTests
        . _run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default(failures)
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance(
        failures
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting(
        failures
    )
    FeintTempoListingCounterTempoTests._run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult(
        failures
    )
    (
        FeintTempoListingCounterTempoTests
        . _run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally(failures)
    )
    FeintTempoListingCounterTempoTests._run_counter_tempo_window_opens_on_incoming_wind_up(failures)
    FeintTempoListingCounterTempoTests._run_counter_tempo_lists_melee_actions_when_window_open(failures)
    FeintTempoListingCounterTempoTests._run_counter_tempo_spend_gauge_subtracts_cost(failures)
    FeintTempoListingCounterTempoTests._run_counter_tempo_defers_incoming_melee_until_after_counter_wind_up(
        failures
    )
    FeintTempoListingCounterTempoTests._run_counter_tempo_abort_cancels_pending_incoming_melee(failures)
    FeintTempoListingCounterTempoTests._run_counter_tempo_wind_up_stamps_pa_and_shortens_duration(failures)
    (
        FeintTempoCounterTempoGuardZoneTests
        . _run_counter_tempo_ai_listing_boosts_counter_and_prefers_plain_over_feint(failures)
    )
    FeintTempoCounterTempoGuardZoneTests._run_counter_tempo_progress_gate_blocks_can_act_until_half_wind_up(
        failures
    )
    (
        FeintTempoCounterTempoGuardZoneTests
        . _run_counter_tempo_process_waiting_schedules_ready_when_progress_gate_met(failures)
    )
    FeintTempoCounterTempoGuardZoneTests._run_counter_tempo_ui_hint_winding_then_ready(failures)
    FeintTempoCounterTempoGuardZoneTests._run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain(
        failures
    )


## III-8: compatibility **`parry_deflect`** cause alias aligns passive readiness + tier-4.2 footwork with
## **`attack_deflect`**.


static func run_after_attention(failures: PackedStringArray) -> void:
    FeintTempoCounterTempoGuardZoneTests._run_feint_move_listing_stance_ai_feint_mult_ordering(failures)
    FeintTempoCounterTempoGuardZoneTests._run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight(
        failures
    )
    FeintTempoCounterTempoGuardZoneTests._run_feint_move_listing_defender_off_balance_boosts_feint_weight(
        failures
    )
    FeintTempoCounterTempoGuardZoneTests._run_feint_opts_from_choice_and_non_feint_attack_no_feint_part(failures)
    (
        FeintTempoCounterTempoGuardZoneTests
        . _run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus(failures)
    )
    FeintTempoCounterTempoGuardZoneTests._run_feint_guard_zone_readthrough_par_bonus_when_readiness_high(failures)
    FeintTempoCounterTempoGuardZoneTests._run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid(failures)
    FeintTempoCounterTempoGuardZoneTests._run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid(failures)
    FeintTempoCounterTempoGuardZoneTests._run_feint_target_reveal_progress_scales_readiness_mult(failures)
    FeintTempoCounterTempoGuardZoneTests._run_feint_move_listing_reveal_progress_dampens_early_wind_up(failures)
    FeintTempoCounterTempoGuardZoneTests._run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough(
        failures
    )
    (
        FeintTempoDefenseFootworkTests
        . _run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(failures)
    )
    FeintTempoDefenseFootworkTests._run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures)
    FeintTempoDefenseFootworkTests._run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures)
    FeintTempoDefenseFootworkTests._run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(
        failures
    )
    (
        FeintTempoDefenseFootworkTests
        . _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(failures)
    )
    FeintTempoDefenseFootworkTests._run_defense_spacing_band_modulates_parry_and_dodge(failures)
    FeintTempoDefenseFootworkTests._run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures)
    FeintTempoRecoveryIii8Tests._run_recovery_cause_parry_deflect_alias_aligns_readiness_and_footwork(
        failures
    )
    FeintTempoRecoveryIii8Tests._run_iii8_recovery_cause_table_parity(failures)
    FeintTempoDefenseFootworkTests._run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(
        failures
    )
    (
        FeintTempoDefenseFootworkTests
        . _run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(failures)
    )
    FeintTempoDefenseFootworkTests._run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(
        failures
    )
    FeintTempoDefenseFootworkTests._run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(
        failures
    )
    FeintTempoDefenseFootworkTests._run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(
        failures
    )
    (
        FeintTempoDefenseFootworkTests
        . _run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(failures)
    )
    FeintTempoRecoveryIii8Tests._run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint(
        failures
    )
    (
        FeintTempoRecoveryIii8Tests
        . _run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina(failures)
    )
    (
        FeintTempoRecoveryIii8Tests
        . _run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally(failures)
    )
    FeintTempoRecoveryIii8Tests._run_feint_telegraph_scrubbed_on_combat_manager_restart(failures)
