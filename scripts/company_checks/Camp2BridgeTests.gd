class_name CompanyChecksCamp2BridgeTests
extends CompanyChecksCore
## Headless Camp-1 economy loop + Camp-2 spot checks + XCamp-3.x + P2 persistence roundtrip.
## Run: .\scripts\run_company_state_checks.ps1
## Labels: Camp-1.x / XCamp-3.x in failure messages map to SHIP_PLAN S Camp-1 / EXPANSION_PLAN Exp-3.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `scripts/README.md`).
## P2 rows use `CampaignPersistence.begin_harness_isolated_save()`  -  production `user://fallen_paths_slot0.json`
## untouched.
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const HARNESS_NAME := "CompanyStateChecks"


static func _run_camp_2_bridge_spot_checks(failures: PackedStringArray) -> void:
    CompanyChecksCamp2PartyMenuTests._run_camp_2_bridge_spot_checks(failures)
    CompanyChecksCamp2AfflictionTests._run_camp_2_bridge_spot_checks(failures)
