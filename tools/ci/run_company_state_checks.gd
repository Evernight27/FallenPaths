class_name CompanyStateChecksHarness
extends SceneTree

## Headless Camp-1 economy loop + Camp-2 spot checks + XCamp-3.x + P2 persistence roundtrip.
## Run: .\\tools\\ci\\run_company_state_checks.ps1
## Labels: Camp-1.x / XCamp-3.x in failure messages map to SHIP_PLAN S Camp-1 / EXPANSION_PLAN Exp-3.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `tools/ci/README.md`).
## P2 rows use `CampaignPersistence.begin_harness_isolated_save()`  -  production `user://fallen_paths_slot0.json`
## untouched.
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const HARNESS_NAME := "CompanyStateChecks"


func _init() -> void:
    CombatConstants.set_headless_harness_quiet(true)
    call_deferred("_run_harness")


func _run_harness() -> void:
    OperationalLog.ensure_harness_error_logger()
    CampaignPersistence.begin_harness_isolated_save()
    var failures: PackedStringArray = PackedStringArray()
    CompanyChecksCamp1EconomyTests._run_camp_1_1_company_state(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_2_wages_and_day(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_3_supply_pools(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_3_settlement_tool_repair(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_4_contracts(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_5_settlement_data(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_6_camp_heal(failures)
    CompanyChecksCamp1EconomyTests._run_camp_fatigue_weariness_stamina(failures)
    CompanyChecksCamp1EconomyTests._run_weapon_edge_wear_sharpening(failures)
    CompanyChecksCamp1EconomyTests._run_camp_rest_quality_starvation_partial_recovery(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_7_renown_scaling(failures)
    CompanyChecksCamp1EconomyTests._run_camp_1_8_roster_cleanup(failures)
    CompanyChecksCampHireOverworldTests._run_hire_rookie(failures)
    CompanyChecksCampHireOverworldTests._run_overworld_map_5x5(failures)
    CompanyChecksCampHireOverworldTests._run_contract_deck_refresh(failures)
    CompanyChecksCampHireOverworldTests._run_xcamp_34_affliction_catalog(failures)
    CompanyChecksCampHireOverworldTests._run_xcamp_35_camp_tavern_mood(failures)
    CompanyChecksCampHireOverworldTests._run_xcamp_36_provisions(failures)
    CompanyChecksCampHireOverworldTests._run_xcamp_37_burial_costs(failures)
    CompanyChecksCampHireOverworldTests._run_xcamp_38_ms_camp_bridge(failures)
    CompanyChecksCampHireOverworldTests._run_xcamp_39_mood_bias_to_ms(failures)
    CompanyChecksCamp2BridgeTests._run_camp_2_bridge_spot_checks(failures)
    CompanyChecksCamp3EncounterTests._run_camp_3_player_front_count_encounter(failures)
    CompanyChecksCamp3EncounterTests._run_camp_5_ea_log_markers(failures)
    CompanyChecksPersistenceRoundtripTests._run_persistence_roundtrip(failures)
    CompanyChecksGladiatorTests._run_xcamp_4b_fighter_names(failures)
    CompanyChecksGladiatorTests._run_xcamp_4b_living_names_invariant(failures)
    CompanyChecksGladiatorTests._run_xcamp_4_c_recruit_quality_cost(failures)
    CompanyChecksGladiatorTests._run_xcamp_4_gear_commerce(failures)
    CompanyChecksGladiatorTests._run_xcamp_4b_name_persistence_roundtrip(failures)
    CompanyChecksGladiatorTests._run_xcamp_4b_4c_hire_integration(failures)
    CompanyChecksGladiatorTests._run_xcamp_5f_fame_accrual(failures)
    CompanyChecksGladiatorTests._run_xcamp_5f_fame_tier_label(failures)
    CompanyChecksGladiatorTests._run_xcamp_5f_fame_survivor_scaling(failures)
    CompanyChecksGladiatorTests._run_xcamp_4d_recruit_kit(failures)
    CompanyChecksGladiatorTests._run_xcamp_4e_sell_unequip(failures)
    CompanyChecksGladiatorTests._run_xcamp_4f_armor_tiers(failures)
    CompanyChecksGladiatorTests._run_xcamp_4h_armor_condition(failures)
    CompanyChecksGladiatorTests._run_xcamp_4h_armor_persist_repair(failures)
    CompanyChecksGladiatorTests._run_xcamp_4i_armor_wear_protection(failures)
    CompanyChecksGladiatorTests._run_xcamp_4j_armor_encumbrance(failures)
    CompanyChecksGladiatorTests._run_xcamp_4k_armor_material_wear(failures)
    CompanyChecksGladiatorTests._run_xcamp_4l_armor_blunt_material_wear(failures)
    CompanyChecksGladiatorTests._run_xcamp_4m_armor_wear_fatigue(failures)
    CompanyChecksGladiatorTests._run_xcamp_4n_armor_layer_fail_trace(failures)
    CompanyChecksGladiatorTests._run_xcamp_4o_armor_damage_type_wear(failures)
    CompanyChecksGladiatorTests._run_xcamp_4p_armor_joule_wear_consistency(failures)
    CompanyChecksGladiatorTests._run_xcamp_4q_armor_breakthrough_crush(failures)
    CompanyChecksGladiatorTests._run_xcamp_4r_armor_worn_deflect(failures)
    CompanyChecksGladiatorTests._run_xcamp_4s_wear_curve_shape(failures)
    CompanyChecksGladiatorTests._run_xcamp_4t_wear_rate_cliff(failures)
    CompanyChecksGladiatorTests._run_xcamp_4u_wear_aware_rha(failures)
    CompanyChecksSchoolTests._run_xcamp_6_profile_reveal(failures)
    CompanyChecksSchoolTests._run_xcamp_6_profile_roundtrip(failures)
    CompanyChecksSchoolTests._run_xcamp_6_counter_recommendations(failures)
    CompanyChecksSchoolTests._run_xcamp_6_form_weapon_drill(failures)
    CompanyChecksSchoolTests._run_xcamp_6_school_registry(failures)
    CompanyChecksSchoolTests._run_xcamp_6_scout_dispatch(failures)
    CompanyChecksSchoolTests._run_xcamp_6_scout_return_reveals(failures)
    CompanyChecksSchoolTests._run_xcamp_6_match_flow(failures)
    CompanyChecksSchoolTests._run_xcamp_6_single_fighter_filter(failures)
    CompanyChecksSchoolTests._run_xcamp_6_school_persistence(failures)
    CompanyChecksSchoolTests._run_xcamp_6_match_outcome_variants(failures)
    CompanyChecksSchoolTests._run_xcamp_6_bout_card(failures)
    CompanyChecksSchoolTests._run_xcamp_6_scout_match_gate(failures)
    CompanyChecksSchoolTests._run_xcamp_6_dossier_visible_view(failures)
    CompanyChecksSchoolTests._run_xcamp_6_cancel_frees_lock(failures)
    CompanyChecksSchoolTests._run_xcamp_6_card_intel_redaction(failures)
    CompanyChecksSchoolTests._run_xcamp_6_scout_no_return(failures)
    CompanyChecksSchoolTests._run_xcamp_6_school_summary(failures)
    CompanyChecksSchoolTests._run_xcamp_6_bout_encounter_setup(failures)
    CompanyChecksCore._cleanup_harness_tree_leaks()
    call_deferred("_finish_harness", failures)


func _finish_harness(failures: PackedStringArray):
    await process_frame
    CompanyChecksCore._cleanup_harness_tree_leaks()
    HarnessFixtures.flush_harness_live_nodes()
    var script_errors: int = OperationalLog.harness_script_error_count()
    if script_errors > 0:
        CompanyChecksCore._fail(
            failures, "Harness: %d SCRIPT_ERROR(s) during CompanyStateChecks (see FP_ERROR lines)" % script_errors
        )
    CampaignPersistence.end_harness_isolated_save()
    if failures.is_empty():
        quit(OperationalLog.harness_ok(HARNESS_NAME, "(%d tests)" % CompanyChecksCore._test_count))
    else:
        quit(OperationalLog.harness_fail(HARNESS_NAME, failures, "(%d tests)" % CompanyChecksCore._test_count))
