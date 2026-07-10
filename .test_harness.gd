extends SceneTree
func _init() -> void:
    var h := preload("res://combat/CombatRegressionHarness.gd")
    print("Loaded: " + str(h))
    quit(0)
