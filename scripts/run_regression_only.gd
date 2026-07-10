extends SceneTree

func _init():
	print("=== Regression Harness Only ===")
	var result = CombatRegressionHarness.run_all()
	
	var out := []
	out.append("--- FP_HARNESS_REPORT ---")
	out.append("ok=" + str(result.ok))
	out.append("name=AllCombatChecks")
	out.append("failure_count=" + str(result.failures.size()))
	if not result.failures.is_empty():
		out.append("failures:")
		for f in result.failures:
			out.append("  - " + f)
	out.append("--- END FP_HARNESS_REPORT ---")
	
	var s := "\n".join(out)
	print(s)
	
	var f := FileAccess.open("user://regression_only.txt", FileAccess.WRITE)
	if f:
		f.store_string(s + "\n")
		f.close()
	
	quit()
