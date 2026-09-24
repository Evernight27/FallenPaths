class_name CombatRegressionHarnessProficiencyTail
extends RefCounted
## XCamp-4: use-based stat proficiency system tests.
## All tests are gated by CompanyState.read_stub_proficiency_enabled() — proficiency_enabled defaults to true.


## Run all proficiency harness tests.
static func run(failures: PackedStringArray) -> void:
    # Stub-gating tests always run.
    ProficiencyAwardPersistenceTests._run_stub_gating_off(failures)
    ProficiencyAwardPersistenceTests._run_copy_core_stats_no_bonuses_when_off(failures)

    # Core EntityProficiency tests.
    ProficiencyAwardPersistenceTests._run_award_stat_gain_diminishing_returns(failures)
    ProficiencyAwardPersistenceTests._run_award_stat_gain_stance_modifier(failures)
    ProficiencyAwardPersistenceTests._run_award_stat_gain_weapon_curve(failures)
    ProficiencyDecayMergeTests._run_targeting_proficiency_channels(failures)
    ProficiencyAwardPersistenceTests._run_apply_decay_inactive_mercenary(failures)
    ProficiencyAwardPersistenceTests._run_apply_decay_wounded_protection(failures)
    ProficiencyAwardPersistenceTests._run_merge_training_pending(failures)

    # END/INT helper function tests.
    ProficiencyAwardPersistenceTests._run_endurance_blood_volume_mult(failures)
    ProficiencyAwardPersistenceTests._run_endurance_healing_speed_mult(failures)
    ProficiencyAwardPersistenceTests._run_nutrition_healing_speed_mult(failures)
    ProficiencyAwardPersistenceTests._run_intelligence_contract_bonus_mult(failures)

    # CombatantEntityAccess wind-up speed tests.
    ProficiencyAwardPersistenceTests._run_effective_medical_windup_speed_modifier(failures)
    ProficiencyAwardPersistenceTests._run_base_medical_windup_speed_modifier(failures)

    # CoreEntity stats sync tests (require stub ON).
    ProficiencyAwardPersistenceTests._run_copy_core_stats_applies_bonuses_when_on(failures)
    ProficiencyAwardPersistenceTests._run_copy_core_stats_preserves_fractional_bonus(failures)

    # UI formatter test.
    ProficiencyAwardPersistenceTests._run_formatter_proficiency_bonus_line(failures)

    # Persistence round-trip tests.
    ProficiencyAwardPersistenceTests._run_persistence_round_trip(failures)
    ProficiencyAwardPersistenceTests._run_persistence_training_pending(failures)

    # Combat flow proficiency gain tests (require stub ON).
    ProficiencyAwardPersistenceTests._run_combat_hit_awards_proficiency_gains(failures)
    ProficiencyAwardPersistenceTests._run_combat_dodge_awards_proficiency_gains(failures)
    ProficiencyAwardPersistenceTests._run_medical_action_awards_proficiency_gains(failures)

    # Decay calibration.
    ProficiencyAwardPersistenceTests._run_decay_rates_per_stat(failures)

    # Medical wind-up effective INT test.
    ProficiencyDecayMergeTests._run_medical_windup_uses_effective_int(failures)

    # Constant correctness tests.
    ProficiencyDecayMergeTests._run_pain_shock_end_slope_constant(failures)

    # Formula normalization tests.
    ProficiencyDecayMergeTests._run_medical_effectiveness_formula(failures)
    ProficiencyDecayMergeTests._run_dodge_formula_divisor(failures)

    # Audit fix tests (parry END gain, medic INT floor, merge_training_pending wiring, defeat decay).
    ProficiencyDecayMergeTests._run_parry_deflect_awards_end_gains(failures)
    ProficiencyDecayMergeTests._run_parry_deflect_end_gain_scales_with_defender_form(failures)
    ProficiencyDecayMergeTests._run_blood_peril_end_factor_monotonic(failures)
    ProficiencyDecayMergeTests._run_wounded_write_factor_bounds(failures)
    ProficiencyDecayMergeTests._run_wounded_fighter_gains_less_physical_stat(failures)
    ProficiencyDecayMergeTests._run_execution_quality_factor_bounds(failures)
    ProficiencyDecayMergeTests._run_dazed_fighter_trains_less_per_strike(failures)
    ProficiencyDecayMergeTests._run_dazed_fighter_practices_weapon_less(failures)
    ProficiencyDecayMergeTests._run_attacker_strikes_build_aerobic_end(failures)
    ProficiencyDecayMergeTests._run_hit_absorbed_end_scales_with_defender_form(failures)
    ProficiencyDecayMergeTests._run_parry_deflect_awards_reflex_agi(failures)
    ProficiencyDecayMergeTests._run_counter_read_per_gain(failures)
    ProficiencyDecayMergeTests._run_dodge_read_per_gain(failures)
    ProficiencyDecayMergeTests._run_combat_hit_awards_windup_agi(failures)
    ProficiencyDecayMergeTests._run_dodge_awards_windup_agi(failures)
    ProficiencyDecayMergeTests._run_parry_partial_awards_partial_end_gain(failures)
    ProficiencyDecayMergeTests._run_parry_partial_awards_reflex_agi(failures)
    ProficiencyDecayMergeTests._run_parry_awards_read_per_gain(failures)
    ProficiencyDecayMergeTests._run_dazed_parryer_reads_less(failures)
    ProficiencyDecayMergeTests._run_stronger_foe_sharpens_parry_read(failures)
    ProficiencyDecayMergeTests._run_medic_int_floor_per_entity_tracking(failures)
    ProficiencyDecayMergeTests._run_merge_training_pending_wired_in_camp_heal(failures)
    ProficiencyDecayMergeTests._run_decay_applies_on_defeat(failures)

    # Additional coverage: medical item mults, decay from low blood volume.
    ProficiencyDecayMergeTests._run_medical_item_multipliers(failures)
    ProficiencyDecayMergeTests._run_decay_low_blood_volume_protection(failures)

    # Wounded-merc protection also halves weapon/form rust, not just stat rust.
    ProficiencyDecayMergeTests._run_decay_low_blood_volume_protection_weapon_form(failures)

    # Parry constant correctness.
    ProficiencyDecayMergeTests._run_parry_constants_correct_values(failures)

    # Direct pressure proficiency gains.
    ProficiencyDecayMergeTests._run_direct_pressure_awards_gains(failures)

    # Never-fought mercenaries don't decay on first camp rest.
    ProficiencyDecayMergeTests._run_decay_skips_never_fought_entities(failures)

    # Outnumbered dodge bonus with proper slot-group check.
    ProficiencyDecayMergeTests._run_outnumbered_dodge_bonus_with_slot_group_check(failures)

    # Stub gating: post-combat respects stub state.
    ProficiencyDecayMergeTests._run_stub_gating_post_combat(failures)

    # Batch resolve medical proficiency gains.
    ProficiencyDecayMergeTests._run_batch_resolve_awards_medical_gains(failures)

    # Swing-mechanics coupling (TOPIC 8): economy bounds, tier gating, fatigue skill hold, strike mass.
    ProficiencyDecayMergeTests._run_swing_economy_bounds(failures)
    ProficiencyDecayMergeTests._run_swing_tier_gating(failures)
    ProficiencyDecayMergeTests._run_fatigue_velocity_skill_hold(failures)
    ProficiencyDecayMergeTests._run_strike_mass_coupling(failures)

    # Forgetting-curve / detraining shape of the decay inactivity factor (Topic 7d).
    ProficiencyDecayMergeTests._run_decay_forgetting_curve_shape(failures)

    # Repeated decay calls within one absence must not double-charge days already decayed.
    ProficiencyDecayMergeTests._run_decay_repeated_calls_do_not_double_charge(failures)

    # Weapon/form proficiency caps at the veteran max.
    ProficiencyDecayMergeTests._run_weapon_form_proficiency_capped_at_veteran_max(failures)

    # Weapon/form familiarity rusts with inactivity for tracked fighters (tracked-gated, >10 floor).
    ProficiencyDecayMergeTests._run_weapon_form_proficiency_decays_with_inactivity(failures)

    # Gain-side severity curve: compressive clinical shape, decoupled from the AI severity score.
    ProficiencyDecayMergeTests._run_gain_severity_curve(failures)

    # Opponent-difficulty scaling is self-relative (near-level = 1.0 baseline), clamped to the band.
    ProficiencyDecayMergeTests._run_opponent_difficulty_self_relative(failures)

    # Desirable difficulty extends to defensive physical gains (END/AGI/STR on parry, AGI on dodge).
    ProficiencyDecayMergeTests._run_stronger_foe_sharpens_defensive_gains(failures)

    # Desirable difficulty extends to the attacker's weapon/form motor gains on a clean hit.
    ProficiencyDecayMergeTests._run_hit_weapon_form_scales_with_target_difficulty(failures)

    # Desirable difficulty extends to the attacker's STR (hit + severe-wound) on a clean hit.
    ProficiencyDecayMergeTests._run_hit_str_scales_with_target_difficulty(failures)

    # Desirable difficulty extends to the attacker's off-focus PER read on a clean hit.
    ProficiencyDecayMergeTests._run_off_focus_per_scales_with_target_difficulty(failures)

    # Write-side gate: untracked fighters (enemies) do not accrue stat bonuses in combat.
    ProficiencyDecayMergeTests._run_untracked_fighter_does_not_gain_stat_bonus(failures)

    # Weapon/form proficiency accrues on strike attempts (reps) for tracked fighters only.
    ProficiencyDecayMergeTests._run_weapon_form_attempt_gains_tracked_only(failures)

    # A successful parry trains the *parrier's* weapon/form too, not just the swinging attacker.
    ProficiencyDecayMergeTests._run_parry_deflect_awards_parryer_weapon_prof(failures)

    # Rust warning fires for weapon/form mastery above the floor, not just stat bonuses.
    ProficiencyDecayMergeTests._run_rust_note_fires_for_weapon_form_mastery(failures)

    # Snapshot marks the canonical last_fought_in_combat property (not an orphaned underscore variant).
    ProficiencyDecayMergeTests._run_snapshot_marks_canonical_fought_flag(failures)

    # A day-0 fight records last_fought_day >= 1 so the fighter's bonuses actually decay later.
    ProficiencyDecayMergeTests._run_day0_fight_records_decaying_last_fought_day(failures)
