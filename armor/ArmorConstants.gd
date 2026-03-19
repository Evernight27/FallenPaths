class_name ArmorConstants
extends RefCounted

const _Combat := preload("res://combat/CombatConstants.gd")
# Damage types (canonical in CombatConstants)
const DAMAGE_TYPE_SHARP: String = _Combat.DAMAGE_TYPE_SHARP
const DAMAGE_TYPE_BLUNT: String = _Combat.DAMAGE_TYPE_BLUNT

# Armor: sharp penetration vs resistance; blunt transmission (no penetration). Durability loss per layer from absorbed damage.
const PENETRATION_DAMAGE_REDUCTION_MAX: float = 0.5
const DURABILITY_LOSS_RATE: float = 0.1

# Durability: no wear unless absorbed damage meets a minimum. Sharp term: max(flat, sharp_resistance_rha_mm * ratio).
# For blunt-origin absorbed damage, add (1 - blunt_transmission) * BLUNT_DURABILITY_THRESHOLD_RATIO so layers that absorb more blunt (padding) require more absorbed damage before wearing (research: energy absorption and degradation linked; padding designed to absorb repeated small blows).
const DURABILITY_MIN_DAMAGE_FLAT: float = 0.5
const DURABILITY_MIN_DAMAGE_RATIO: float = 0.05
const BLUNT_DURABILITY_THRESHOLD_RATIO: float = 0.5

# --- Generic layer stats (cloth, leather, mail, plate only) ---
# Sharp resistance: mm RHA equivalent. Nonlinear pen = (KE/55)^0.6 × area_factor (Williams).
# Blunt: transmission-only (no penetration check). Durability uses sharp_resistance_rha_mm and blunt_transmission.
# Sharp deflect transmission: fraction of damage that becomes blunt when sharp is stopped by layer (plate transmits more, cloth absorbs).
# Blunt transmission: fraction of blunt damage that passes through layer (transmission-only; no penetration).
# Durability: wear per damage absorbed; cloth tears fastest, plate lasts. See ARMOR_VALUES_PHYSICS_RESEARCH.md.

const SHARP_DEFLECT_TRANSMISSION_DEFAULT: float = 0.5
const DEFLECTION_TRANSMISSION_DEFAULT: float = 0.5  # Legacy alias
const BLUNT_TRANSMISSION_DEFAULT: float = 0.65
const BLUNT_BAT_TRANSMISSION: float = 0.65  # Legacy alias

# blunt_cushion 0-1: transmission = base * (1 - cushion * momentum_factor). High cushion = padding absorbs.
# When momentum/area (kg·m/s)/m² exceeds this, cushion is overwhelmed (heavy blows push through padding).
# Example: mace 1.7 kg, 12 m/s, 8 cm head → p/A ≈ 20.4/0.005 ≈ 4080 (kg·m/s)/m² → above threshold.
const BLUNT_CUSHION_MOMENTUM_THRESHOLD: float = 3000.0  # (kg·m/s)/m²

# Area coupling for rigid layers: coupling = lerp(1, contact_cm/REFERENCE, rigidity). No clamp.
# ArmorPiece uses WeaponConstants.get_blunt_coupling_reference_cm() (mean head_diameter from weapon defs).
const BLUNT_COUPLING_REFERENCE_CM: float = 6.0  # fallback only
# Rigidity >= this: apply area coupling. Below: no area effect (flexible).
const RIGIDITY_THRESHOLD: float = 0.5
# Warn when area_factor or transmission outside these (tuning check)
const BLUNT_AREA_FACTOR_WARN_MIN: float = 0.05
const BLUNT_AREA_FACTOR_WARN_MAX: float = 5.0
const BLUNT_TRANSMISSION_WARN_MIN: float = 0.0
const BLUNT_TRANSMISSION_WARN_MAX: float = 1.0

# rigidity 0–1: area coupling for blunt. Rigid (plate) transmits more with large contact (mace); flexible (cloth) no effect.
# Cloth: gambeson padding, leg wraps, coif. Williams: 50 J for 16 layers linen. pen=(50/55)^0.6 ≈ 0.9 mm.
const LAYER_CLOTH: Dictionary = {
	"sharp_resistance_rha_mm": 0.9,
	"blunt_cushion": 0.8,
	"blunt_transmission": 0.45,
	"rigidity": 0.0,
	"durability_loss_rate": 0.22,
	"sharp_deflect_transmission": 0.16
}

# Leather: buff coat, boiled leather. Williams: buff 30 J, cuir-bouilli 20–30 J. pen=(30/55)^0.6 ≈ 0.6 mm.
const LAYER_LEATHER: Dictionary = {
	"sharp_resistance_rha_mm": 0.6,
	"blunt_cushion": 0.5,
	"blunt_transmission": 0.58,
	"rigidity": 0.2,
	"durability_loss_rate": 0.16,
	"sharp_deflect_transmission": 0.24
}

# Mail: chainmail + jack. Williams: 80–120 J. pen=(120/55)^0.6 ≈ 1.5 mm.
const LAYER_MAIL: Dictionary = {
	"sharp_resistance_rha_mm": 1.5,
	"blunt_cushion": 0.2,
	"blunt_transmission": 0.70,
	"rigidity": 0.2,
	"durability_loss_rate": 0.12,
	"sharp_deflect_transmission": 0.36
}

# Plate: medieval steel. Williams: 2 mm=175 J, 3.5 mm≈380 J. Rigid → area coupling (mace > thrust).
const LAYER_PLATE: Dictionary = {
	"sharp_resistance_rha_mm": 3.5,
	"blunt_cushion": 0.0,
	"blunt_transmission": 0.72,
	"rigidity": 1.0,
	"durability_loss_rate": 0.07,
	"sharp_deflect_transmission": 0.46
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
