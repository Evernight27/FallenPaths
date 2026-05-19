extends SceneTree

## Fast medical-phase combat-halt checks (subset of CombatRegressionHarness).

const _OperationalLog := preload("res://core/OperationalLog.gd")

const HARNESS_NAME := "MedicalPhaseHarness"
const TEST_COUNT := 10


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	_OperationalLog.harness_begin(HARNESS_NAME)
	var failures: PackedStringArray = PackedStringArray()
	CombatRegressionHarness._run_medical_phase_cancels_pending_enemy_melee(failures)
	CombatRegressionHarness._run_medical_phase_blocks_afterblow_on_loser(failures)
	CombatRegressionHarness._run_medical_phase_blocks_scheduled_enemy_events(failures)
	CombatRegressionHarness._run_medical_phase_teardown_cancels_formation_resolve(failures)
	CombatRegressionHarness._run_medical_phase_purge_queue_and_windup_blocked(failures)
	CombatRegressionHarness._run_medical_phase_skip_turn_silent_for_loser(failures)
	CombatRegressionHarness._run_medical_phase_winner_combat_resolve_blocked(failures)
	CombatRegressionHarness._run_medical_phase_apply_result_blocked(failures)
	CombatRegressionHarness._run_medical_phase_end_combat_idempotent(failures)
	CombatRegressionHarness._run_combat_end_enemy_win_stops_manager(failures)
	if failures.is_empty():
		quit(_OperationalLog.harness_ok(HARNESS_NAME, "(%d tests)" % TEST_COUNT))
		return
	quit(_OperationalLog.harness_fail(HARNESS_NAME, failures, "(%d tests)" % TEST_COUNT))
	return
