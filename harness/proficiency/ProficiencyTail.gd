class_name CombatRegressionHarnessProficiencyTail
extends RefCounted
## XCamp-4: use-based stat proficiency system tests.
## All tests are gated by CompanyState.read_stub_proficiency_enabled() --" stub is false by default.


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
    ProficiencyAwardPersistenceTests._run_intelligence_contract_bonus_mult(failures)

    # CombatantEntityAccess wind-up speed tests.
    ProficiencyAwardPersistenceTests._run_effective_medical_windup_speed_modifier(failures)
    ProficiencyAwardPersistenceTests._run_base_medical_windup_speed_modifier(failures)

    # CoreEntity stats sync tests (require stub ON).
    ProficiencyAwardPersistenceTests._run_copy_core_stats_applies_bonuses_when_on(failures)

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
    ProficiencyDecayMergeTests._run_parry_partial_no_defender_gain(failures)
    ProficiencyDecayMergeTests._run_medic_int_floor_per_entity_tracking(failures)
    ProficiencyDecayMergeTests._run_merge_training_pending_wired_in_camp_heal(failures)
    ProficiencyDecayMergeTests._run_decay_applies_on_defeat(failures)

    # Additional coverage: medical item mults, decay from low blood volume.
    ProficiencyDecayMergeTests._run_medical_item_multipliers(failures)
    ProficiencyDecayMergeTests._run_decay_low_blood_volume_protection(failures)

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
