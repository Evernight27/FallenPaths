class_name WeaponConstants
extends RefCounted

# Damage types (must match ArmorConstants / CoreEntity)
const DAMAGE_TYPE_SHARP: String = "SHARP"
const DAMAGE_TYPE_BLUNT: String = "BLUNT"

# Attack types: stab (point), cut/slash (edge), blunt/swing (head).
# Contact area per attack: stab -> point_width, cut -> blade_width, blunt -> head_diameter.
const ATTACK_TYPE_STAB: String = "stab"
const ATTACK_TYPE_CUT: String = "cut"
const ATTACK_TYPE_BLUNT: String = "blunt"

# Default baseline for physical modifier (contact area, cm)
const BASELINE_CONTACT_CM: float = 2.0
const BASELINE_MASS_KG: float = 1.0

# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# 1 mm mild steel ≈ 55 J to penetrate (base). 80 gives more realistic penetration; 130 was harder to penetrate (balance).
# Research: strike speeds 17–24 m/s; we use 6–20 m/s effective impact (BALANCING_INVESTIGATION.md).
const J_PER_MM_RHA: float = 80.0
# Effective impact velocity (m/s). Research: rod-like strikes 17.2–23.9 m/s; 20 allows near-peak strikes.
const VELOCITY_MIN_M_S: float = 6.0
const VELOCITY_MAX_M_S: float = 20.0
# Pre-armor damage: scale * sqrt(KE) * strength_mod * arm_mod. Tuned so damage band matches old 2–12 m/s at scale 4.0.
const DAMAGE_KE_SCALE: float = 2.6
const DAMAGE_KE_MIN: float = 1.0
const DAMAGE_KE_MAX: float = 80.0
# Cap penetration (mm RHA) from KE so very high energy doesn't trivialize armor.
const PENETRATION_KE_CAP_MM_RHA: float = 15.0

# --- Physics-based contact area ---
# Sharp: smaller contact (point) penetrates better than wide (cut). Factor = (BASELINE / contact_width_cm)^α.
const CONTACT_AREA_EXPONENT: float = 0.5
const MIN_CONTACT_WIDTH_CM: float = 0.2
# Contact area in damage: smaller contact -> more local damage. Cap factor so stab doesn't overscale.
const CONTACT_DAMAGE_EXPONENT: float = 0.3
const CONTACT_DAMAGE_FACTOR_MAX: float = 2.0
# Blunt: impact pressure (MPa) = BLUNT_PRESSURE_SCALE * KE_J / A_m² / 1e6. A_m² = π*(d_cm/100/2)².
const BLUNT_PRESSURE_SCALE: float = 500.0
# Floor so tiny contacts don't produce absurd MPa; 1 cm² min keeps normal blade areas unchanged (BALANCING_INVESTIGATION.md).
const MIN_BLUNT_AREA_M2: float = 1e-4
# For CUT moves, blunt stream uses at least this contact (cm) so the "slap" doesn't get blade pressure.
const BLUNT_CUT_MIN_CONTACT_CM: float = 5.0
# No weapon is 0% cutting: even maces can break skin (flanges/ridges). Floor for cut_ratio.
const MIN_CUT_RATIO: float = 0.02

# --- Effective edge (sharpness) for cutting ---
# Sharpness 0-1: effective sharp contact = geometric / (SHARPNESS_FACTOR_MIN + (1 - SHARPNESS_FACTOR_MIN) * sharpness).
# Sharpness 1 = geometric; sharpness 0 = geometric/0.2 (duller = wider effective contact = less penetration).
const SHARPNESS_FACTOR_MIN: float = 0.2

# --- Momentum-based blunt damage ---
# Pre-armor blunt = DAMAGE_MOMENTUM_SCALE * (mass_kg * velocity_m_s) * strength_mod * arm_mod * contact_factor, clamped.
# Tuned so typical mace (1.7 kg, 12 m/s) and sword blunt portion sit in same band as before.
const DAMAGE_MOMENTUM_SCALE: float = 0.42
const BLUNT_DAMAGE_MIN: float = 1.0
const BLUNT_DAMAGE_MAX: float = 80.0

# --- Move pool (historical / HEMA-inspired) ---
# Each move: id, name (UI), contact_type (stab/cut/blunt), archetype_id, base_cooldown.
# Parry moves have is_parry: true (explicit parry attack following a defensive action).
# Weapons reference move ids; get_available_attack_types() returns move ids for that weapon.
# contact_type maps to weapon dimensions: stab->point_width, cut->blade_width, blunt->head_diameter.
static func get_move(move_id: String) -> Dictionary:
	var all_moves := _move_definitions_build()
	if not all_moves.has(move_id):
		return {}
	return all_moves[move_id].duplicate(true)

static func is_parry_move(move_id: String) -> bool:
	var m = get_move(move_id)
	return m.get("is_parry", false) == true

static func _move_definitions_build() -> Dictionary:
	return {
		# Sword (Liechtenauer/KDF): thrust, Oberhau, Unterhau, horizontal (Zwerchau-style), pommel, explicit parry-counters
		"thrust": { "name": "Point thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.2 },
		"oberhau": { "name": "Downward diagonal cut", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_OVERHEAD, "base_cooldown": 2.4 },
		"unterhau": { "name": "Upward diagonal cut", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 2.2 },
		"slash": { "name": "Horizontal cut (cross)", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 2.0 },
		"pommel_strike": { "name": "Pommel strike (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_POMMEL, "base_cooldown": 1.8 },
		"parry_thrust": { "name": "Parry and thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.0, "is_parry": true },
		"parry_cut": { "name": "Parry and cut", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 1.9, "is_parry": true },
		# Axe (battle axe / Le Jeu de la Hache): spike, overhead chop, diagonal chop, poll, explicit parry-counter
		"spike_thrust": { "name": "Spike thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 3.2 },
		"overhead_chop": { "name": "Overhead chop", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_OVERHEAD, "base_cooldown": 3.5 },
		"diagonal_chop": { "name": "Diagonal chop", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 3.0 },
		"poll_strike": { "name": "Back-of-head strike (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.0 },
		"parry_chop": { "name": "Parry and chop", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 3.0, "is_parry": true },
		# Mace: blunt only — overhead, side, direct, explicit parry-counter
		"overhead_strike": { "name": "Overhead strike", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.5 },
		"side_strike": { "name": "Side strike", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.2 },
		"direct_blow": { "name": "Direct blow", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.0 },
		"parry_strike": { "name": "Parry and strike", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.0, "is_parry": true },
		# Dagger / rondel (Fiore, Talhoffer): thrust, slash, pommel, explicit parry-counter
		"quick_thrust": { "name": "Quick thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 0.7 },
		"committed_thrust": { "name": "Strong thrust (armor-piercing)", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 1.0 },
		"quick_slash": { "name": "Quick slash", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_QUICK_SLASH, "base_cooldown": 0.6 },
		"dagger_pommel": { "name": "Pommel strike (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_POMMEL, "base_cooldown": 0.5 },
		"parry_thrust_dagger": { "name": "Parry and thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 0.6, "is_parry": true },
		# Spear (Fiore): thrust, angled thrust, slash, pole swing (shaft), explicit parry-counter (no beat-and-thrust)
		"spear_thrust": { "name": "Forward thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 3.0 },
		"off_line_thrust": { "name": "Angled thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.8 },
		"spear_slash": { "name": "Slash with spearhead", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 2.8 },
		"pole_swing": { "name": "Pole swing (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 2.5 },
		"parry_thrust_spear": { "name": "Parry and thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.7, "is_parry": true }
	}

# --- Weapon template definitions ---
# Per weapon: mass (kg), dimensions (cm), edge_width (cm, optional), blade_cut_ratio, melee_range, moves.
# Dimensions: blade_width = edge contact for cuts; point_width = tip for thrusts; head_diameter = striking head for blunt.
# edge_width = effective sharp contact for blunt weapons (flanges/ridges that can break skin); used for sharp-component penetration.
# Data: Oakeshott/longsword 2–3 cm edge, 0.3–0.6 cm point; Le Jeu axe 3–4 cm edge, 0.5–1 cm spike; mace flanges 0.4–0.6 cm (Williams, Tod Cutler); Fiore/Talhoffer dagger ~1.5 cm edge, 0.2–0.4 cm point; spear 0.4–0.8 cm point.
# No weapon has 0% cutting (MIN_CUT_RATIO); each component uses get_sharp_contact_cm / get_blunt_contact_cm for its damage type.
static func get_all_weapon_ids() -> Array:
	return ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]

# Use get_weapon_definition(weapon_id) for a fresh copy.
static func get_weapon_definition(weapon_id: String) -> Dictionary:
	var id_normalized := weapon_id.to_upper()
	var all := _weapon_definitions_build()
	if not all.has(id_normalized):
		return {}
	return all[id_normalized].duplicate(true)

static func _weapon_definitions_build() -> Dictionary:
	return {
		# Longsword / arming sword: thrust, cuts, pommel, parry-counters (German tradition).
		"SWORD": {
			"name": "Sword",
			"mass": 1.2,
			"blade_width": 2.0,
			"point_width": 0.5,
			"head_diameter": 0.0,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.75,
			"melee_range": 1.5,
			"moves": [
				{ "id": "thrust" },
				{ "id": "oberhau" },
				{ "id": "unterhau" },
				{ "id": "slash" },
				{ "id": "pommel_strike" },
				{ "id": "parry_thrust" },
				{ "id": "parry_cut" }
			]
		},
		# Battle axe: spike, chops, poll, parry-counter (Le Jeu de la Hache style).
		"AXE": {
			"name": "Axe",
			"mass": 1.5,
			"blade_width": 3.0,
			"point_width": 0.8,
			"head_diameter": 0.0,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.6,
			"melee_range": 1.5,
			"moves": [
				{ "id": "spike_thrust" },
				{ "id": "overhead_chop" },
				{ "id": "diagonal_chop" },
				{ "id": "poll_strike" },
				{ "id": "parry_chop" }
			]
		},
		# Mace: overhead, side, direct, parry-counter (blunt only).
		"MACE": {
			"name": "Mace",
			"mass": 1.7,
			"blade_width": 0.0,
			"point_width": 0.0,
			"head_diameter": 8.0,
			"edge_width": 0.5,
			"blade_cut_ratio": 0.0,
			"melee_range": 1.5,
			"moves": [
				{ "id": "overhead_strike" },
				{ "id": "side_strike" },
				{ "id": "direct_blow" },
				{ "id": "parry_strike" }
			]
		},
		# Dagger / rondel: thrusts, slash, pommel, parry-counter (Fiore, Talhoffer).
		"DAGGER": {
			"name": "Dagger",
			"mass": 0.3,
			"blade_width": 1.5,
			"point_width": 0.3,
			"head_diameter": 0.0,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.9,
			"melee_range": 0.8,
			"moves": [
				{ "id": "quick_thrust" },
				{ "id": "committed_thrust" },
				{ "id": "quick_slash" },
				{ "id": "dagger_pommel" },
				{ "id": "parry_thrust_dagger" }
			]
		},
		# Spear (Fiore): thrusts, slash, pole swing (shaft), parry-counter.
		"SPEAR": {
			"name": "Spear",
			"mass": 1.8,
			"blade_width": 2.5,
			"point_width": 0.6,
			"head_diameter": 0.0,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.85,
			"melee_range": 2.5,
			"moves": [
				{ "id": "spear_thrust" },
				{ "id": "off_line_thrust" },
				{ "id": "spear_slash" },
				{ "id": "pole_swing" },
				{ "id": "parry_thrust_spear" }
			]
		}
	}

# Default cooldown when no weapon or unknown attack type
const DEFAULT_COOLDOWN: float = 1.5

# --- Attack archetypes: velocity arc, cut ratio, recovery/windup multiplier ---
# velocity_factor: 1.0 = full intensity -> full velocity; <1 = quicker attack, less KE.
# cut_ratio: 0-1 (rest blunt). Overridden by weapon blade_cut_ratio for slash/cut when not set in archetype.
# recovery_multiplier / windup_multiplier: scale state-machine timing.
const ARCHETYPE_STAB: String = "stab"
const ARCHETYPE_SLASH: String = "slash"
const ARCHETYPE_OVERHEAD: String = "overhead"
const ARCHETYPE_QUICK_SLASH: String = "quick_slash"
const ARCHETYPE_POMMEL: String = "pommel_strike"
const ARCHETYPE_HEAVY_BLUNT: String = "heavy_blunt"

static func get_archetype(archetype_id: String) -> Dictionary:
	var all_arch := _archetype_definitions_build()
	if not all_arch.has(archetype_id):
		return all_arch.get(ARCHETYPE_SLASH, {})
	return all_arch[archetype_id].duplicate(true)

static func _archetype_definitions_build() -> Dictionary:
	return {
		ARCHETYPE_STAB: {
			"velocity_factor": 1.0,
			"cut_ratio": -1.0,  # use weapon blade_cut_ratio
			"recovery_multiplier": 1.0,
			"windup_multiplier": 1.0
		},
		ARCHETYPE_SLASH: {
			"velocity_factor": 0.9,
			"cut_ratio": -1.0,
			"recovery_multiplier": 1.0,
			"windup_multiplier": 1.0
		},
		ARCHETYPE_OVERHEAD: {
			"velocity_factor": 1.0,
			"cut_ratio": -1.0,
			"recovery_multiplier": 1.2,
			"windup_multiplier": 1.15
		},
		ARCHETYPE_QUICK_SLASH: {
			"velocity_factor": 0.65,
			"cut_ratio": -1.0,
			"recovery_multiplier": 0.85,
			"windup_multiplier": 0.8
		},
		ARCHETYPE_POMMEL: {
			"velocity_factor": 0.7,
			"cut_ratio": 0.05,
			"recovery_multiplier": 0.9,
			"windup_multiplier": 0.85
		},
		ARCHETYPE_HEAVY_BLUNT: {
			"velocity_factor": 1.0,
			"cut_ratio": 0.05,
			"recovery_multiplier": 1.15,
			"windup_multiplier": 1.1
		}
	}
