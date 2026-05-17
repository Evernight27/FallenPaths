extends SceneTree

func _init() -> void:
	# Suppress COMBAT_DEBUG / COMBAT_EVENT_DEBUG spam so headless runs finish in ~10s and
	# do not block when shell stdout is piped (e.g. `| grep` pipe buffer deadlock).
	CombatConstants.set_headless_harness_quiet(true)
	var r: Dictionary = CombatRegressionHarness.run_all()
	if bool(r.get("ok", false)):
		print("CombatRegressionHarness: OK")
		quit(0)
	else:
		push_error("CombatRegressionHarness: FAIL")
		for f in r.get("failures", []):
			push_error("  %s" % str(f))
		quit(1)
		return
