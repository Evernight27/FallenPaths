class_name CombatConstantsStance
extends RefCounted

## Opponent-pressure stance floats still used by CombatWeaponForm.
## Legacy per-stance Dictionary tables removed (zero production/harness readers; WF owns mods).

const STANCE_MOD_OPPONENT_CLOSE: float = 0.9
const STANCE_MOD_OPPONENT_DISENGAGE: float = 0.85
const DENSITY_CLOSE_MOD: Dictionary = {"tight": 0.8, "normal": 1.0, "loose": 1.2}
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")

static func get_stance_modifier(stance: String, effect: String) -> float:
	return _WeaponForm.mod(_WeaponForm.normalize_form(stance), effect)

static func get_density_close_mod(density: String) -> float:
	return DENSITY_CLOSE_MOD.get(density, 1.0)

static func get_spacing_from_density(density: String) -> float:
	match density:
		"tight": return 0.9
		"loose": return 1.8
		_: return 1.2
