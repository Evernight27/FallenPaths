class_name CombatConstantsRecoveryCause
extends RefCounted

const READINESS_BY_CAUSE: Dictionary = {
	"attack_hit": [0.3, 0.6],
	"attack_miss": [0.45, 0.8],
	"attack_deflect": [0.5, 0.85],
	"skip": [0.5, 0.85],
	"medical": [0.5, 0.85],
}
