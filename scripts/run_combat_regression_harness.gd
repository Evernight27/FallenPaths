extends SceneTree

func _init() -> void:
	var r: Dictionary = CombatRegressionHarness.run_all()
	if bool(r.get("ok", false)):
		print("CombatRegressionHarness: OK")
		quit(0)
	else:
		push_error("CombatRegressionHarness: FAIL")
		for f in r.get("failures", []):
			push_error("  %s" % str(f))
		quit(1)
