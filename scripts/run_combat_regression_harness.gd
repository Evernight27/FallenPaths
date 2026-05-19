extends SceneTree

const _OperationalLog := preload("res://core/OperationalLog.gd")

const HARNESS_NAME := "CombatRegressionHarness"


func _init() -> void:
	# Suppress COMBAT_DEBUG / COMBAT_EVENT_DEBUG spam so headless runs finish in ~10s and
	# do not block when shell stdout is piped (e.g. `| grep` pipe buffer deadlock).
	CombatConstants.set_headless_harness_quiet(true)
	_OperationalLog.harness_begin(HARNESS_NAME)
	var r: Dictionary = CombatRegressionHarness.run_all()
	var failures: PackedStringArray = r.get("failures", PackedStringArray())
	if bool(r.get("ok", false)):
		quit(_OperationalLog.harness_ok(HARNESS_NAME))
	else:
		quit(_OperationalLog.harness_fail(HARNESS_NAME, failures))
	return
