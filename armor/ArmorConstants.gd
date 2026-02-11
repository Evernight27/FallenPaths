class_name ArmorConstants
extends RefCounted

# Damage types (must match CoreEntity / CombatManager)
const DAMAGE_TYPE_SHARP: String = "SHARP"
const DAMAGE_TYPE_BLUNT: String = "BLUNT"

# Armor calculation (deflection/penetration)
const PENETRATION_DAMAGE_REDUCTION_MAX: float = 0.5
const DURABILITY_LOSS_RATE: float = 0.1
const RHA_TO_MPA: float = 0.6

# Durability: no wear unless absorbed damage meets a minimum (vs layer "armor value" or flat floor).
# armor_value = sharp_resistance_rha_mm + blunt_resistance_mpa / 10; threshold = max(flat, armor_value * ratio).
const DURABILITY_MIN_DAMAGE_FLAT: float = 0.5
const DURABILITY_MIN_DAMAGE_RATIO: float = 0.05

# --- Generic layer stats (cloth, leather, mail, plate only) ---
# Sharp resistance: mm RHA equivalent. Penetration energy ≈ res × J_PER_MM_RHA (80 in WeaponConstants).
# Blunt resistance: MPa (relative; no direct medieval MPa data — ordering from literature).
# Deflection transmission: fraction of damage that becomes blunt when sharp fails (BAT: plate transmits more, cloth absorbs).
# Durability: wear per damage absorbed; cloth tears fastest, plate lasts. See ARMOR_VALUES_PHYSICS_RESEARCH.md.

const DEFLECTION_TRANSMISSION_DEFAULT: float = 0.5
# When blunt fails to penetrate (pen < blunt_res): this fraction is transmitted as BAT. Fallback if layer omits blunt_bat_transmission.
const BLUNT_BAT_TRANSMISSION: float = 0.65

# Option B: rigid (pressure) vs cushion (momentum). blunt_resistance_mpa = pressure (KE/area) to deform layer.
# blunt_cushion 0-1: when blunt deflects, transmission = base * (1 - cushion * momentum_factor). High cushion = padding absorbs.
# When momentum/area (kg·m/s)/m² exceeds this, cushion is overwhelmed (heavy blows push through padding).
# Example: mace 1.7 kg, 12 m/s, 8 cm head → p/A ≈ 20.4/0.005 ≈ 4080 (kg·m/s)/m² → above threshold.
const BLUNT_CUSHION_MOMENTUM_THRESHOLD: float = 3000.0  # (kg·m/s)/m²

# Cloth: gambeson padding, leg wraps, coif. Minimal vs sharp; good blunt absorption (cushioning). Tears fastest.
# blunt_bat_transmission: low — padding absorbs impact; less force reaches body.
const LAYER_CLOTH: Dictionary = {
	"sharp_resistance_rha_mm": 0.5,
	"blunt_resistance_mpa": 16.0,
	"blunt_cushion": 0.8,
	"blunt_bat_transmission": 0.50,
	"durability_loss_rate": 0.22,
	"deflection_transmission": 0.16
}

# Leather: buff coat, boiled leather, bracers. ~30 J (buff) to ~80 J (layered); good blunt absorption.
const LAYER_LEATHER: Dictionary = {
	"sharp_resistance_rha_mm": 1.0,
	"blunt_resistance_mpa": 14.0,
	"blunt_cushion": 0.5,
	"blunt_bat_transmission": 0.58,
	"durability_loss_rate": 0.16,
	"deflection_transmission": 0.24
}

# Mail: chainmail. 100–120 J with padding (→ 1.5 mm at 80 J/mm); good vs slash, poor vs blunt (transmits trauma).
const LAYER_MAIL: Dictionary = {
	"sharp_resistance_rha_mm": 1.5,
	"blunt_resistance_mpa": 10.0,
	"blunt_cushion": 0.2,
	"blunt_bat_transmission": 0.70,
	"durability_loss_rate": 0.12,
	"deflection_transmission": 0.36
}

# Plate: medieval steel/iron. ~1–4 mm RHA equiv; rigid → higher BAT transmission; little cushion (transmits).
const LAYER_PLATE: Dictionary = {
	"sharp_resistance_rha_mm": 3.5,
	"blunt_resistance_mpa": 40.0,
	"blunt_cushion": 0.0,
	"blunt_bat_transmission": 0.80,
	"durability_loss_rate": 0.07,
	"deflection_transmission": 0.46
}

# --- Armor piece definitions: one piece per body part, built from cloth/leather/mail/plate only ---
# Order: outer layer first (e.g. plate), then inner (e.g. cloth). Reflects how soldiers wore kit.
# Piece IDs by body part for random equipment.
static func get_armor_options_by_part() -> Dictionary:
	return {
		"head": ["KETTLE_HELM", "LEATHER_CAP", "CLOTH_COIF"],
		"chest": ["CUIRASS", "GAMBESON", "HAUBERK", "LEATHER_CUIRASS"],
		"right_arm": ["VAMBRACES", "LEATHER_BRACERS", "ARM_WRAPS"],
		"left_arm": ["VAMBRACES_LEFT", "LEATHER_BRACERS_LEFT", "ARM_WRAPS_LEFT"],
		"right_leg": ["GREAVES", "LEG_WRAPS", "LEATHER_GREAVES"],
		"left_leg": ["GREAVES_LEFT", "LEG_WRAPS_LEFT", "LEATHER_GREAVES_LEFT"]
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
		"LEATHER_BRACERS_LEFT": {
			"name": "Leather Bracers (L)",
			"body_part": "left_arm",
			"layers": [LAYER_LEATHER.duplicate()]
		},
		"ARM_WRAPS": {
			"name": "Arm Wraps",
			"body_part": "right_arm",
			"layers": [LAYER_CLOTH.duplicate()]
		},
		"ARM_WRAPS_LEFT": {
			"name": "Arm Wraps (L)",
			"body_part": "left_arm",
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
		"LEG_WRAPS_LEFT": {
			"name": "Leg Wraps (L)",
			"body_part": "left_leg",
			"layers": [LAYER_CLOTH.duplicate()]
		},
		"LEATHER_GREAVES": {
			"name": "Leather Greaves",
			"body_part": "right_leg",
			"layers": [LAYER_LEATHER.duplicate()]
		},
		"LEATHER_GREAVES_LEFT": {
			"name": "Leather Greaves (L)",
			"body_part": "left_leg",
			"layers": [LAYER_LEATHER.duplicate()]
		}
	}

# Default penetration when no weapon is specified (strength-scaled later)
const DEFAULT_PENETRATION_SHARP: float = 5.0
const DEFAULT_PENETRATION_BLUNT: float = 2.0
