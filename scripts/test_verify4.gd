extends RefCounted

func _init() -> void:
	var s: Variant = load("res://combat/CombatAIActionPicker.gd")
	if s == null:
		print("FAIL")
	elif s is GDScript:
		print("OK")
	else:
		print("TYPE " + str(typeof(s)))
