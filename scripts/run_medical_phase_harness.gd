extends SceneTree

## Fast medical-phase combat-halt checks (subset of CombatRegressionHarness).

func _init() -> void:
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
		print("MedicalPhaseHarness: OK (10 tests)")
		quit(0)
		return
	for f in failures:
		push_error("  %s" % f)
	push_error("MedicalPhaseHarness: FAIL")
	quit(1)
	return
