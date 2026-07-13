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
