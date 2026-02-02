class_name ArmorConstants
extends RefCounted

# Damage types (must match CoreEntity / CombatManager)
const DAMAGE_TYPE_SHARP: String = "SHARP"
const DAMAGE_TYPE_BLUNT: String = "BLUNT"

# Armor calculation (deflection/penetration)
const PENETRATION_DAMAGE_REDUCTION_MAX: float = 0.5
const BLUNT_PENETRATION_REDUCTION: float = 0.3
const DEFLECTION_DAMAGE_REDUCTION: float = 0.5
const DURABILITY_LOSS_RATE: float = 0.1
const RHA_TO_MPA: float = 0.6

# --- Generic layer stats (cloth, leather, mail, plate only) ---
# Sharp resistance: mm RHA equivalent (1 mm mild steel ≈ 55 J to penetrate).
# Blunt resistance: MPa (relative; no direct medieval MPa data — ordering from literature).
# Sources: A Commonplace Book / Williams (14th c. metallurgy); arrow vs mail/padding tests
# (~80–120 J); buff leather ~30 J; gambeson/cloth minimal vs focused penetration.

# Cloth: thin fabric, gambeson padding, leg wraps. Minimal vs sharp; some blunt absorption.
const LAYER_CLOTH: Dictionary = {
	"sharp_resistance_rha_mm": 0.5,
	"blunt_resistance_mpa": 8.0,
	"durability_loss_rate": 0.20
}

# Leather: buff coat, boiled leather, bracers. ~30 J to penetrate (buff) → ~0.55 mm equiv; layered better.
const LAYER_LEATHER: Dictionary = {
	"sharp_resistance_rha_mm": 1.0,
	"blunt_resistance_mpa": 14.0,
	"durability_loss_rate": 0.15
}

# Mail: chainmail. ~80 J to begin failure, ~100–120 J with padding; good vs slash, poor vs blunt (transmits trauma).
const LAYER_MAIL: Dictionary = {
	"sharp_resistance_rha_mm": 2.0,
	"blunt_resistance_mpa": 10.0,
	"durability_loss_rate": 0.12
}

# Plate: generic metal (steel/iron). Medieval plate ~1–4 mm RHA equiv; 2.5 mm good steel ≈ 2.75 mm mild.
const LAYER_PLATE: Dictionary = {
	"sharp_resistance_rha_mm": 3.5,
	"blunt_resistance_mpa": 40.0,
	"durability_loss_rate": 0.08
}

# --- Armor piece definitions: one piece per body part, built from cloth/leather/mail/plate only ---
# Order: outer layer first (e.g. plate), then inner (e.g. cloth). Reflects how soldiers wore kit.
# Piece IDs by body part for random equipment.
static func get_armor_options_by_part() -> Dictionary:
	return {
		"head": ["KETTLE_HELM", "LEATHER_CAP", "CLOTH_COIF"],
		"chest": ["CUIRASS", "GAMBESON", "HAUBERK", "LEATHER_CUIRASS"],
		"right_arm": ["VAMBRACES", "LEATHER_BRACERS", "ARM_WRAPS"],
		"left_arm": ["VAMBRACES_LEFT"],
		"right_leg": ["GREAVES", "LEG_WRAPS", "LEATHER_GREAVES"],
		"left_leg": ["GREAVES_LEFT"]
	}

# Use get_piece_definition(piece_id) to get a definition with fresh layer copies.
static func get_piece_definition(piece_id: String) -> Dictionary:
	var id_normalized := piece_id
	if id_normalized == "CURASS":
		id_normalized = "CUIRASS"  # Legacy alias for typo
	var all := _piece_definitions_build()
	if not all.has(id_normalized):
		return {}
	return all[id_normalized].duplicate(true)

static func _piece_definitions_build() -> Dictionary:
	return {
		# Head: helm = plate + cloth (arming cap under metal)
		"KETTLE_HELM": {
			"name": "Kettle Helm",
			"body_part": "head",
			"layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"LEATHER_CAP": {
			"name": "Leather Cap",
			"body_part": "head",
			"layers": [LAYER_LEATHER.duplicate()]
		},
		"CLOTH_COIF": {
			"name": "Cloth Coif",
			"body_part": "head",
			"layers": [LAYER_CLOTH.duplicate()]
		},
		# Chest: cuirass = plate + cloth; hauberk = mail + cloth; gambeson = cloth only
		"CUIRASS": {
			"name": "Cuirass",
			"body_part": "chest",
			"layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"GAMBESON": {
			"name": "Gambeson",
			"body_part": "chest",
			"layers": [LAYER_CLOTH.duplicate()]
		},
		"HAUBERK": {
			"name": "Mail Hauberk",
			"body_part": "chest",
			"layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"LEATHER_CUIRASS": {
			"name": "Leather Cuirass",
			"body_part": "chest",
			"layers": [LAYER_LEATHER.duplicate()]
		},
		# Arms: vambraces = plate + cloth; leather bracers = leather; cloth = cloth
		"VAMBRACES": {
			"name": "Vambraces",
			"body_part": "right_arm",
			"layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"VAMBRACES_LEFT": {
			"name": "Vambraces (L)",
			"body_part": "left_arm",
			"layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"LEATHER_BRACERS": {
			"name": "Leather Bracers",
			"body_part": "right_arm",
			"layers": [LAYER_LEATHER.duplicate()]
		},
		"ARM_WRAPS": {
			"name": "Arm Wraps",
			"body_part": "right_arm",
			"layers": [LAYER_CLOTH.duplicate()]
		},
		# Legs: greaves = plate + cloth; leather = leather; cloth = cloth
		"GREAVES": {
			"name": "Greaves",
			"body_part": "right_leg",
			"layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"GREAVES_LEFT": {
			"name": "Greaves (L)",
			"body_part": "left_leg",
			"layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
		},
		"LEG_WRAPS": {
			"name": "Leg Wraps",
			"body_part": "right_leg",
			"layers": [LAYER_CLOTH.duplicate()]
		},
		"LEATHER_GREAVES": {
			"name": "Leather Greaves",
			"body_part": "right_leg",
			"layers": [LAYER_LEATHER.duplicate()]
		}
	}

# Default penetration when no weapon is specified (strength-scaled later)
const DEFAULT_PENETRATION_SHARP: float = 5.0
const DEFAULT_PENETRATION_BLUNT: float = 2.0
