class_name CombatRegressionHarnessMedicalPhaseTail
extends RefCounted
## Tier 6.3 medical phase + treatment tests split from CombatRegressionHarness (compile size).

const BattleScene := preload("res://ui/battle/BattleScene.gd")


static func run_fast_phase_halt_checks(failures: PackedStringArray) -> void:
    MedicalPhaseGateTests._run_medical_phase_cancels_pending_enemy_melee(failures)
    MedicalPhaseGateTests._run_medical_phase_blocks_afterblow_on_loser(failures)
    MedicalPhaseGateTests._run_medical_phase_blocks_scheduled_enemy_events(failures)
    MedicalPhaseGateTests._run_medical_phase_teardown_cancels_formation_resolve(failures)
    MedicalPhaseGateTests._run_medical_phase_purge_queue_and_windup_blocked(failures)
    MedicalPhaseGateTests._run_medical_phase_skip_turn_silent_for_loser(failures)
    MedicalPhaseGateTests._run_medical_phase_winner_combat_resolve_blocked(failures)
    MedicalPhaseGateTests._run_medical_phase_winner_listing_medical_only(failures)
    MedicalCoordinationBattleTests._run_medical_phase_winner_locked_on_party_bleed_out(failures)
    MedicalPhaseGateTests._run_medical_phase_apply_result_blocked(failures)
    MedicalPhaseGateTests._run_medical_phase_end_combat_idempotent(failures)
    ParryActionResolvedTests._run_combat_end_enemy_win_stops_manager(failures)
    MedicalFieldTreatmentTests._run_field_care_procedure_sim_advance_seconds(failures)
    MedicalFieldTreatmentTests._run_field_care_venous_clot_under_procedure(failures)
    MedicalFieldTreatmentTests._run_field_care_arterial_stays_lethal_under_procedure(failures)
    MedicalFieldTreatmentTests._run_field_care_venous_blood_loss_bounded(failures)
    MedicalCoordinationBattleTests._run_field_care_arterial_blood_loss_meaningful(failures)
    MedicalFieldTreatmentTests._run_direct_pressure_flow_retention_venous_vs_arterial_parity(failures)
    MedicalFieldTreatmentTests._run_research_anchor_clotting_half_life_physics(failures)
    MedicalFieldTreatmentTests._run_research_anchor_reference_bleed_derivation_parity(failures)
    MedicalPhaseGateTests._run_direct_pressure_held_suppresses_bleed_rate(failures)
    MedicalPhaseGateTests._run_treatment_channel_count_not_raw_hit_count(failures)
    MedicalPhaseGateTests._run_direct_pressure_release_rebleeds_without_dressing(failures)
    MedicalFieldTreatmentTests._run_field_care_pressure_before_bandage_parity(failures)
    MedicalFieldTreatmentTests._run_field_care_pressure_before_pack_parity(failures)
    MedicalFieldTreatmentTests._run_entity_medical_dressing_requires_compression_when_bleeding(failures)
    MedicalFieldTreatmentTests._run_failed_packing_retains_direct_pressure(failures)
    MedicalPhaseGateTests._run_dressings_blocked_without_pressure_when_bleeding(failures)
    MedicalPhaseGateTests._run_dressings_still_offered_after_failure_out_of_peril(failures)
    MedicalPhaseGateTests._run_failed_dressing_retains_direct_pressure(failures)
    MedicalFieldTreatmentTests._run_pressure_held_until_dressed(failures)
    MedicalCoordinationBattleTests._run_medical_phase_full_blood_loss_rate(failures)
    MedicalPhaseGateTests._run_medical_phase_fled_winner_bleed_suspended_on_tick(failures)
    MedicalFieldTreatmentTests._run_medical_triage_reference_bleed_peril_parity(failures)
    MedicalFieldTreatmentTests._run_ambient_pain_shock_tick_accum_physics(failures)
    MedicalFieldTreatmentTests._run_ambient_pain_shock_seeded_rng_enters_shock(failures)
    MedicalFieldTreatmentTests._run_ambient_pain_shock_skips_when_feature_off(failures)
    MedicalPhaseGateTests._run_iii5_packing_channel_success_depth(failures)
    MedicalFieldTreatmentTests._run_stabilize_hold_does_not_mark_injury_stabilized(failures)
    MedicalFieldTreatmentTests._run_stabilize_success_still_untreated_for_camp(failures)
    MedicalFieldTreatmentTests._run_field_stabilize_trim_before_procedure_advance(failures)
    MedicalFieldTreatmentTests._run_field_tourniquet_applies_before_procedure_advance(failures)
    MedicalFieldTreatmentTests._run_stabilize_requires_intrinsic_active_bleed(failures)
    MedicalFieldTreatmentTests._run_entity_medical_bandage_blocked_when_tourniquet_indicated(failures)
    MedicalCoordinationBattleTests._run_field_care_tourniquet_before_bandage_parity(failures)
    MedicalFieldTreatmentTests._run_dressings_allowed_when_locally_clotted_under_pressure(failures)
    MedicalCoordinationBattleTests._run_direct_pressure_requires_active_bleed(failures)
    MedicalCoordinationBattleTests._run_clotting_pressure_faster_than_open_bleed(failures)
    MedicalCoordinationBattleTests._run_clotting_bandaged_slower_k_than_pressure_held(failures)
    MedicalCoordinationBattleTests._run_medical_phase_blood_loss_clotting_below_constant_drain(failures)
    MedicalCoordinationBattleTests._run_battle_ui_receiving_care_gauge_primary(failures)
    MedicalCoordinationBattleTests._run_medical_coordination_blocks_bandage_during_ally_windup(failures)
    MedicalCoordinationBattleTests._run_pressure_held_bandage_success_mult_parity(failures)
    MedicalCoordinationBattleTests._run_battle_ui_medical_wind_up_gauge_primary(failures)


static func run(failures: PackedStringArray) -> void:
    var steps: Array = [
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_cancels_pending_enemy_melee"), "MedicalPhaseGateTests._run_medical_phase_cancels_pending_enemy_melee"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_blocks_afterblow_on_loser"), "MedicalPhaseGateTests._run_medical_phase_blocks_afterblow_on_loser"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_blocks_scheduled_enemy_events"), "MedicalPhaseGateTests._run_medical_phase_blocks_scheduled_enemy_events"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_teardown_cancels_formation_resolve"), "MedicalPhaseGateTests._run_medical_phase_teardown_cancels_formation_resolve"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_purge_queue_and_windup_blocked"), "MedicalPhaseGateTests._run_medical_phase_purge_queue_and_windup_blocked"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_skip_turn_silent_for_loser"), "MedicalPhaseGateTests._run_medical_phase_skip_turn_silent_for_loser"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_winner_combat_resolve_blocked"), "MedicalPhaseGateTests._run_medical_phase_winner_combat_resolve_blocked"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_winner_listing_medical_only"), "MedicalPhaseGateTests._run_medical_phase_winner_listing_medical_only"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_apply_result_blocked"), "MedicalPhaseGateTests._run_medical_phase_apply_result_blocked"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_end_combat_idempotent"), "MedicalPhaseGateTests._run_medical_phase_end_combat_idempotent"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_phase_winner_locked_on_party_bleed_out"), "MedicalCoordinationBattleTests._run_medical_phase_winner_locked_on_party_bleed_out"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_phase_tick_continues_after_locked_bleed_out"), "MedicalCoordinationBattleTests._run_medical_phase_tick_continues_after_locked_bleed_out"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_winner_fled_suspends_bleed_tick"), "MedicalPhaseGateTests._run_medical_phase_winner_fled_suspends_bleed_tick"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_fled_winner_bleed_suspended_on_tick"), "MedicalPhaseGateTests._run_medical_phase_fled_winner_bleed_suspended_on_tick"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_non_fled_winner_bleed_continues_on_tick"), "MedicalPhaseGateTests._run_medical_phase_non_fled_winner_bleed_continues_on_tick"],
        [Callable(MedicalPhaseGateTests, "_run_medical_phase_stop_clears_suspend_bleed_tick"), "MedicalPhaseGateTests._run_medical_phase_stop_clears_suspend_bleed_tick"],
        [Callable(MedicalPhaseGateTests, "_run_combat_log_formatter_bandage_ally_label"), "MedicalPhaseGateTests._run_combat_log_formatter_bandage_ally_label"],
        [Callable(MedicalPhaseGateTests, "_run_pack_wound_strict_subregion_eligibility"), "MedicalPhaseGateTests._run_pack_wound_strict_subregion_eligibility"],
        [Callable(MedicalPhaseGateTests, "_run_pack_wound_can_apply_on_chest_wound"), "MedicalPhaseGateTests._run_pack_wound_can_apply_on_chest_wound"],
        [Callable(MedicalPhaseGateTests, "_run_pack_wound_blocked_when_already_packed"), "MedicalPhaseGateTests._run_pack_wound_blocked_when_already_packed"],
        [Callable(MedicalPhaseGateTests, "_run_pack_wound_lists_in_medical_phase"), "MedicalPhaseGateTests._run_pack_wound_lists_in_medical_phase"],
        [Callable(MedicalCoordinationBattleTests, "_run_pack_wound_apply_packing_marks_packed_parts"), "MedicalCoordinationBattleTests._run_pack_wound_apply_packing_marks_packed_parts"],
        [Callable(MedicalCoordinationBattleTests, "_run_pack_wound_windup_complete_packed_outcome"), "MedicalCoordinationBattleTests._run_pack_wound_windup_complete_packed_outcome"],
        [Callable(MedicalCoordinationBattleTests, "_run_instant_complete_finishes_in_progress_bandage"), "MedicalCoordinationBattleTests._run_instant_complete_finishes_in_progress_bandage"],
        [Callable(MedicalPhaseFastForwardTests, "_run_fast_forward_idle_unsticks_waiting_triage"), "MedicalPhaseFastForwardTests._run_fast_forward_idle_unsticks_waiting_triage"],
        [Callable(MedicalPhaseFastForwardTests, "_run_fast_forward_stalled_picks_advance_clock"), "MedicalPhaseFastForwardTests._run_fast_forward_stalled_picks_advance_clock"],
        [Callable(MedicalPhaseFastForwardTests, "_run_fast_forward_sim_cap_terminates"), "MedicalPhaseFastForwardTests._run_fast_forward_sim_cap_terminates"],
        [Callable(MedicalPhaseFastForwardTests, "_run_winner_side_triage_busy_turn_ready_pending"), "MedicalPhaseFastForwardTests._run_winner_side_triage_busy_turn_ready_pending"],
        [Callable(MedicalPhaseFastForwardTests, "_run_winner_side_triage_busy_gauge_and_complete"), "MedicalPhaseFastForwardTests._run_winner_side_triage_busy_gauge_and_complete"],
        [Callable(MedicalPhaseFastForwardTests, "_run_finish_battle_flushes_deferred_soak_coverage"), "MedicalPhaseFastForwardTests._run_finish_battle_flushes_deferred_soak_coverage"],
        [Callable(MedicalPhaseFastForwardTests, "_run_finish_battle_campaign_medical_exit_refreshes_camp"), "MedicalPhaseFastForwardTests._run_finish_battle_campaign_medical_exit_refreshes_camp"],
        [Callable(MedicalPhaseFastForwardTests, "_run_finish_battle_incomplete_hint_campaign_only"), "MedicalPhaseFastForwardTests._run_finish_battle_incomplete_hint_campaign_only"],
        [Callable(MedicalPhaseFastForwardTests, "_run_fast_forward_time_slice_completes_medical_windup"), "MedicalPhaseFastForwardTests._run_fast_forward_time_slice_completes_medical_windup"],
        [Callable(MedicalPhaseFastForwardTests, "_run_finish_battle_campaign_batch_completes_windup"), "MedicalPhaseFastForwardTests._run_finish_battle_campaign_batch_completes_windup"],
        [Callable(MedicalPhaseFastForwardTests, "_run_finish_battle_instant_completes_medical_windup"), "MedicalPhaseFastForwardTests._run_finish_battle_instant_completes_medical_windup"],
        [Callable(MedicalPhaseGateTests, "_run_bandage_allowed_on_packed_part"), "MedicalPhaseGateTests._run_bandage_allowed_on_packed_part"],
        [Callable(MedicalPhaseGateTests, "_run_direct_pressure_held_suppresses_bleed_rate"), "MedicalPhaseGateTests._run_direct_pressure_held_suppresses_bleed_rate"],
        [Callable(MedicalPhaseGateTests, "_run_direct_pressure_release_rebleeds_without_dressing"), "MedicalPhaseGateTests._run_direct_pressure_release_rebleeds_without_dressing"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_windup_prepare_preserves_ally_head_pressure"), "MedicalCoordinationBattleTests._run_medical_windup_prepare_preserves_ally_head_pressure"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_coordination_blocks_overlapping_treatment"), "MedicalCoordinationBattleTests._run_medical_coordination_blocks_overlapping_treatment"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_coordination_blocks_bandage_during_ally_windup"), "MedicalCoordinationBattleTests._run_medical_coordination_blocks_bandage_during_ally_windup"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_coordination_stack_assist_during_windup"), "MedicalCoordinationBattleTests._run_medical_coordination_stack_assist_during_windup"],
        [Callable(MedicalCoordinationBattleTests, "_run_ms_mid_infight_med_depth_suite"), "MedicalCoordinationBattleTests._run_ms_mid_infight_med_depth_suite"],
        [Callable(MedicalPhaseGateTests, "_run_treatment_channel_count_not_raw_hit_count"), "MedicalPhaseGateTests._run_treatment_channel_count_not_raw_hit_count"],
        [Callable(MedicalPhaseGateTests, "_run_iii5_packing_channel_success_depth"), "MedicalPhaseGateTests._run_iii5_packing_channel_success_depth"],
        [Callable(MedicalPhaseGateTests, "_run_failed_dressing_retains_direct_pressure"), "MedicalPhaseGateTests._run_failed_dressing_retains_direct_pressure"],
        [Callable(MedicalPhaseGateTests, "_run_dressings_blocked_without_pressure_when_bleeding"), "MedicalPhaseGateTests._run_dressings_blocked_without_pressure_when_bleeding"],
        [Callable(MedicalPhaseGateTests, "_run_dressings_still_offered_after_failure_out_of_peril"), "MedicalPhaseGateTests._run_dressings_still_offered_after_failure_out_of_peril"],
        [Callable(MedicalPhaseGateTests, "_run_pending_retry_set_even_with_other_medics"), "MedicalPhaseGateTests._run_pending_retry_set_even_with_other_medics"],
        [Callable(MedicalPhaseGateTests, "_run_medical_ai_prefers_dressing_over_stabilize_out_of_peril"), "MedicalPhaseGateTests._run_medical_ai_prefers_dressing_over_stabilize_out_of_peril"],
        [Callable(MedicalFieldTreatmentTests, "_run_entity_untreated_matches_bridge"), "MedicalFieldTreatmentTests._run_entity_untreated_matches_bridge"],
        [Callable(MedicalFieldTreatmentTests, "_run_pressure_held_until_dressed"), "MedicalFieldTreatmentTests._run_pressure_held_until_dressed"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_care_procedure_sim_advance_seconds"), "MedicalFieldTreatmentTests._run_field_care_procedure_sim_advance_seconds"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_care_venous_clot_under_procedure"), "MedicalFieldTreatmentTests._run_field_care_venous_clot_under_procedure"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_care_arterial_stays_lethal_under_procedure"), "MedicalFieldTreatmentTests._run_field_care_arterial_stays_lethal_under_procedure"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_care_venous_blood_loss_bounded"), "MedicalFieldTreatmentTests._run_field_care_venous_blood_loss_bounded"],
        [Callable(MedicalCoordinationBattleTests, "_run_field_care_arterial_blood_loss_meaningful"), "MedicalCoordinationBattleTests._run_field_care_arterial_blood_loss_meaningful"],
        [Callable(MedicalFieldTreatmentTests, "_run_direct_pressure_flow_retention_venous_vs_arterial_parity"), "MedicalFieldTreatmentTests._run_direct_pressure_flow_retention_venous_vs_arterial_parity"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_care_pressure_before_bandage_parity"), "MedicalFieldTreatmentTests._run_field_care_pressure_before_bandage_parity"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_care_pressure_before_pack_parity"), "MedicalFieldTreatmentTests._run_field_care_pressure_before_pack_parity"],
        [Callable(MedicalFieldTreatmentTests, "_run_entity_medical_dressing_requires_compression_when_bleeding"), "MedicalFieldTreatmentTests._run_entity_medical_dressing_requires_compression_when_bleeding"],
        [Callable(MedicalFieldTreatmentTests, "_run_failed_packing_retains_direct_pressure"), "MedicalFieldTreatmentTests._run_failed_packing_retains_direct_pressure"],
        [Callable(MedicalFieldTreatmentTests, "_run_research_anchor_clotting_half_life_physics"), "MedicalFieldTreatmentTests._run_research_anchor_clotting_half_life_physics"],
        [Callable(MedicalFieldTreatmentTests, "_run_medical_triage_reference_bleed_peril_parity"), "MedicalFieldTreatmentTests._run_medical_triage_reference_bleed_peril_parity"],
        [Callable(MedicalFieldTreatmentTests, "_run_ambient_pain_shock_tick_accum_physics"), "MedicalFieldTreatmentTests._run_ambient_pain_shock_tick_accum_physics"],
        [Callable(MedicalFieldTreatmentTests, "_run_ambient_pain_shock_seeded_rng_enters_shock"), "MedicalFieldTreatmentTests._run_ambient_pain_shock_seeded_rng_enters_shock"],
        [Callable(MedicalFieldTreatmentTests, "_run_ambient_pain_shock_skips_when_feature_off"), "MedicalFieldTreatmentTests._run_ambient_pain_shock_skips_when_feature_off"],
        [Callable(MedicalFieldTreatmentTests, "_run_stabilize_hold_does_not_mark_injury_stabilized"), "MedicalFieldTreatmentTests._run_stabilize_hold_does_not_mark_injury_stabilized"],
        [Callable(MedicalFieldTreatmentTests, "_run_stabilize_success_still_untreated_for_camp"), "MedicalFieldTreatmentTests._run_stabilize_success_still_untreated_for_camp"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_stabilize_trim_before_procedure_advance"), "MedicalFieldTreatmentTests._run_field_stabilize_trim_before_procedure_advance"],
        [Callable(MedicalFieldTreatmentTests, "_run_field_tourniquet_applies_before_procedure_advance"), "MedicalFieldTreatmentTests._run_field_tourniquet_applies_before_procedure_advance"],
        [Callable(MedicalFieldTreatmentTests, "_run_tourniquet_ischemia_on_expiry"), "MedicalFieldTreatmentTests._run_tourniquet_ischemia_on_expiry"],
        [Callable(MedicalFieldTreatmentTests, "_run_resolved_wound_releases_tourniquet"), "MedicalFieldTreatmentTests._run_resolved_wound_releases_tourniquet"],
        [Callable(MedicalFieldTreatmentTests, "_run_tourniquet_release_clears_failure_session"), "MedicalFieldTreatmentTests._run_tourniquet_release_clears_failure_session"],
        [Callable(MedicalFieldTreatmentTests, "_run_corpse_does_not_heal_or_resolve"), "MedicalFieldTreatmentTests._run_corpse_does_not_heal_or_resolve"],
        [Callable(MedicalFieldTreatmentTests, "_run_corpse_does_not_bleed_or_release"), "MedicalFieldTreatmentTests._run_corpse_does_not_bleed_or_release"],
		[Callable(MedicalFieldTreatmentTests, "_run_tourniquet_preexpiry_no_ischemia"), "MedicalFieldTreatmentTests._run_tourniquet_preexpiry_no_ischemia"],
		[Callable(MedicalFieldTreatmentTests, "_run_tourniquet_ischemia_latches_on_wound"), "MedicalFieldTreatmentTests._run_tourniquet_ischemia_latches_on_wound"],
		[Callable(MedicalFieldTreatmentTests, "_run_was_infected_latches_survive_cure"), "MedicalFieldTreatmentTests._run_was_infected_latches_survive_cure"],
		[Callable(MedicalFieldTreatmentTests, "_run_sepsis_death_skips_tetanus_pass"), "MedicalFieldTreatmentTests._run_sepsis_death_skips_tetanus_pass"],
        [Callable(MedicalFieldTreatmentTests, "_run_decompensated_rest_recovery_suppressed"), "MedicalFieldTreatmentTests._run_decompensated_rest_recovery_suppressed"],
        [Callable(MedicalFieldTreatmentTests, "_run_resolved_wound_releases_held_pressure"), "MedicalFieldTreatmentTests._run_resolved_wound_releases_held_pressure"],
        [Callable(MedicalFieldTreatmentTests, "_run_corpse_release_clears_pressure_bookkeeping"), "MedicalFieldTreatmentTests._run_corpse_release_clears_pressure_bookkeeping"],
        [Callable(MedicalFieldTreatmentTests, "_run_death_within_advance_stops_healing_pipeline"), "MedicalFieldTreatmentTests._run_death_within_advance_stops_healing_pipeline"],
        [Callable(MedicalFieldTreatmentTests, "_run_wound_infection_progression_slowdown_and_cure"), "MedicalFieldTreatmentTests._run_wound_infection_progression_slowdown_and_cure"],
        [Callable(MedicalFieldTreatmentTests, "_run_bleeding_slows_tissue_healing"), "MedicalFieldTreatmentTests._run_bleeding_slows_tissue_healing"],
        [Callable(MedicalFieldTreatmentTests, "_run_arterial_untreated_stalls_healing"), "MedicalFieldTreatmentTests._run_arterial_untreated_stalls_healing"],
        [Callable(MedicalFieldTreatmentTests, "_run_stabilize_requires_intrinsic_active_bleed"), "MedicalFieldTreatmentTests._run_stabilize_requires_intrinsic_active_bleed"],
        [Callable(MedicalFieldTreatmentTests, "_run_entity_medical_bandage_blocked_when_tourniquet_indicated"), "MedicalFieldTreatmentTests._run_entity_medical_bandage_blocked_when_tourniquet_indicated"],
        [Callable(MedicalCoordinationBattleTests, "_run_field_care_tourniquet_before_bandage_parity"), "MedicalCoordinationBattleTests._run_field_care_tourniquet_before_bandage_parity"],
        [Callable(MedicalFieldTreatmentTests, "_run_dressings_allowed_when_locally_clotted_under_pressure"), "MedicalFieldTreatmentTests._run_dressings_allowed_when_locally_clotted_under_pressure"],
        [Callable(MedicalCoordinationBattleTests, "_run_direct_pressure_requires_active_bleed"), "MedicalCoordinationBattleTests._run_direct_pressure_requires_active_bleed"],
        [Callable(MedicalCoordinationBattleTests, "_run_clotting_pressure_faster_than_open_bleed"), "MedicalCoordinationBattleTests._run_clotting_pressure_faster_than_open_bleed"],
        [Callable(MedicalCoordinationBattleTests, "_run_clotting_bandaged_slower_k_than_pressure_held"), "MedicalCoordinationBattleTests._run_clotting_bandaged_slower_k_than_pressure_held"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_phase_blood_loss_clotting_below_constant_drain"), "MedicalCoordinationBattleTests._run_medical_phase_blood_loss_clotting_below_constant_drain"],
        [Callable(MedicalCoordinationBattleTests, "_run_battle_ui_receiving_care_gauge_primary"), "MedicalCoordinationBattleTests._run_battle_ui_receiving_care_gauge_primary"],
        [Callable(MedicalCoordinationBattleTests, "_run_pressure_held_bandage_success_mult_parity"), "MedicalCoordinationBattleTests._run_pressure_held_bandage_success_mult_parity"],
        [Callable(MedicalCoordinationBattleTests, "_run_battle_ui_medical_wind_up_gauge_primary"), "MedicalCoordinationBattleTests._run_battle_ui_medical_wind_up_gauge_primary"],
        [Callable(MedicalCoordinationBattleTests, "_run_wound_merge_same_subregion"), "MedicalCoordinationBattleTests._run_wound_merge_same_subregion"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_phase_losing_side_stays_fled"), "MedicalCoordinationBattleTests._run_medical_phase_losing_side_stays_fled"],
        [Callable(MedicalCoordinationBattleTests, "_run_ally_medical_tourniquet_path_pressure_first"), "MedicalCoordinationBattleTests._run_ally_medical_tourniquet_path_pressure_first"],
        [Callable(MedicalCoordinationBattleTests, "_run_medical_phase_full_blood_loss_rate"), "MedicalCoordinationBattleTests._run_medical_phase_full_blood_loss_rate"],
        [Callable(MedicalPhaseFastForwardTests, "_run_combat_log_formatter_pack_ally_label"), "MedicalPhaseFastForwardTests._run_combat_log_formatter_pack_ally_label"],
    ]
    var rows: PackedStringArray = PackedStringArray()
    for step in steps:
        var t0: int = Time.get_ticks_msec()
        (step[0] as Callable).call(failures)
        rows.append("%d\t%s" % [Time.get_ticks_msec() - t0, str(step[1])])
    _write_subtest_timing("medical_phase_tail", rows)
    # XCamp-4: stub-gating tests always run alongside medical tests.
    ProficiencyAwardPersistenceTests._run_stub_gating_off(failures)
    ProficiencyAwardPersistenceTests._run_copy_core_stats_no_bonuses_when_off(failures)
    OperationalLog.end_play_session()
    OperationalLog.set_capture_enabled(false)
    CombatF5SoakTrace.prepare_fight_end_log()


## Per-subtest durations (ms, desc) for `.medical_subtest_timing.txt` â€” which medical subtests dominate.
static func _write_subtest_timing(section: String, rows: PackedStringArray) -> void:
    var data: Array = []
    for r in rows:
        var p: PackedStringArray = r.split("\t")
        if p.size() < 2:
            continue
        data.append({"ms": int(p[0]), "label": str(p[1])})
    data.sort_custom(func(a, b): return int(a.ms) > int(b.ms))
    var out: PackedStringArray = PackedStringArray()
    out.append("[%s]" % section)
    var total: int = 0
    for d in data:
        total += int(d.ms)
        out.append("%d\t%s" % [int(d.ms), str(d.label)])
    out.append("TOTAL_MS=%d count=%d" % [total, data.size()])
    var root: String = ProjectSettings.globalize_path("res://")
    var f: FileAccess = FileAccess.open(root.path_join(".medical_subtest_timing.txt"), FileAccess.WRITE)
    if f != null:
        f.store_string("\n".join(out) + "\n")
        f.close()
