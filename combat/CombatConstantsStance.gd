class_name CombatConstantsStance
extends RefCounted

const STANCE_MOD_PARRY: Dictionary = {"defensive": 1.2, "balanced": 1.0, "aggressive": 0.8, "controlling": 1.0}
const STANCE_MOD_EVASION: Dictionary = {"defensive": 1.15, "balanced": 1.0, "aggressive": 0.85, "controlling": 1.0}
const STANCE_MOD_DAMAGE: Dictionary = {"defensive": 0.85, "balanced": 1.0, "aggressive": 1.2, "controlling": 0.95}
const STANCE_MOD_CLOSE_ATTEMPT: Dictionary = {"defensive": 0.9, "balanced": 1.0, "aggressive": 1.1, "controlling": 1.0}
const STANCE_MOD_AI_MELEE_FOCUS: Dictionary = {"defensive": 0.92, "balanced": 1.0, "aggressive": 1.1, "controlling": 0.98}
const STANCE_MOD_FEINT_READTHROUGH: Dictionary = {"defensive": 1.06, "balanced": 1.0, "aggressive": 0.95, "controlling": 1.04}
const STANCE_MOD_AI_FEINT_LISTING: Dictionary = {
	"defensive": 0.94,
	"balanced": 1.0,
	"aggressive": 1.02,
	"controlling": 1.06,
}
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
