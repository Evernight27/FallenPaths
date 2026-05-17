class_name WeaponConstants
extends RefCounted

const _Combat := preload("res://combat/CombatConstants.gd")
# Damage types (canonical in CombatConstants)
const DAMAGE_TYPE_SHARP: String = _Combat.DAMAGE_TYPE_SHARP
const DAMAGE_TYPE_BLUNT: String = _Combat.DAMAGE_TYPE_BLUNT

# Attack types: stab (point), cut/slash (edge), blunt/swing (head).
# Contact area per attack: stab -> point_width, cut -> blade_width, blunt -> head_diameter.
const ATTACK_TYPE_STAB: String = "stab"
const ATTACK_TYPE_CUT: String = "cut"
const ATTACK_TYPE_BLUNT: String = "blunt"

# Default baseline for physical modifier (contact area, cm)
const BASELINE_CONTACT_CM: float = 2.0
const BASELINE_MASS_KG: float = 1.0


## Weapon `mass` when present; else **`BASELINE_MASS_KG`** (parry, KE, inertia).
static func weapon_mass_kg(weapon: Variant) -> float:
	if weapon == null:
		return BASELINE_MASS_KG
	var mass_raw: Variant = weapon.get("mass") if weapon is Object else null
	if mass_raw is float or mass_raw is int:
		return float(mass_raw)
	return BASELINE_MASS_KG


# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# Williams (Knight & Blast Furnace): 1mm=55J, 1.5mm=110J, 2mm=175J → E ∝ t^1.67. Nonlinear: pen = (KE/J_BASE)^PEN_EXPONENT.
const J_PER_MM_BASE: float = 55.0  # Williams: 55 J for 1 mm mild steel
const PENETRATION_EXPONENT: float = 0.6  # 1/1.67; thicker armor needs disproportionately more energy
# Global impact speed floor/ceiling (m/s): fallback when a weapon template has no Tier-A band entry; ImpactVelocityModel uses these (see ImpactVelocityModel._tier_a_default_band).
const VELOCITY_MIN_M_S: float = 6.0
const VELOCITY_MAX_M_S: float = 24.0
# Pre-armor damage: scale * sqrt(KE) * strength_mod * arm_mod. 2.0 aligns severance with research (~100 J arm, ~200 J leg).
# Severance tuning narrative: docs/PHYSICS_DAMAGE_AND_FLOW.md (embedded RESEARCHED_NUMBERS / damage tables).
const DAMAGE_KE_SCALE: float = 2.0
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
# Blunt: transmission-only (no rigid check). Older blunt rigid-penetration constants were removed in favor of this model.
# Floor so tiny contacts don't produce absurd momentum/area; 1 cm² min keeps normal blade areas unchanged.
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

static func is_feint_move(move_id: String) -> bool:
	var m = get_move(move_id)
	return m.get("is_feint", false) == true


## move_id (e.g. thrust, oberhau) -> stab | cut | blunt. Bare stab/cut/blunt pass through unchanged.
## Single source for combat + velocity; use this directly (not a separate forwarder).
static func contact_type_for_move_id(move_id: String) -> String:
	var key: String = str(move_id).to_lower().strip_edges()
	if key == ATTACK_TYPE_STAB or key == ATTACK_TYPE_CUT or key == ATTACK_TYPE_BLUNT:
		return key
	var md: Dictionary = get_move(move_id)
	if md.is_empty():
		return ATTACK_TYPE_CUT
	var ct: String = str(md.get("contact_type", ATTACK_TYPE_CUT)).to_lower()
	if ct == ATTACK_TYPE_STAB or ct == ATTACK_TYPE_CUT or ct == ATTACK_TYPE_BLUNT:
		return ct
	return ATTACK_TYPE_CUT


static func _move_definitions_build() -> Dictionary:
	# attack_line: Liechtenauer 4 lines — high (0°), low (180°), left (270°), right (90°). Blade path, not body target.
	# angle_variance_deg: optional ±deg human error; heavier/awkward moves have more variance.
	# angle_offset_deg: optional bias from base line (e.g. off_line_thrust angled toward flank).
	return {
		# Sword (Liechtenauer/KDF): thrust, Oberhau, Unterhau, horizontal (Zwerchau-style), pommel, parry-counters
		"thrust": {"name": "Point thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.2, "attack_line": "high", "preferred_parts": ["chest"]},
		"oberhau": {"name": "Downward diagonal cut", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_OVERHEAD, "base_cooldown": 2.4, "attack_line": "high", "preferred_parts": ["head"], "angle_variance_deg": 10},
		# Tier 4.2: optional feint_windup_duration_mult (>1) — extra wind-up vs same-archetype honest cut (two-line commitment cost).
		"oberhau_feint": {"name": "Feint high, cut low", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_OVERHEAD, "base_cooldown": 2.6, "attack_line": "high", "preferred_parts": ["head"], "is_feint": true, "feint_windup_duration_mult": 1.1, "feint_target_reveal_at_progress": 0.45, "angle_variance_deg": 12},
		# Tier 4.2: stab feint — feint_target_reveal_at_progress earlier than oberhau_feint (faster thrust telegraph); feint_windup_duration_mult < cut feint (stab archetype already tighter).
		"thrust_feint": {"name": "Feint line, thrust true", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.4, "attack_line": "high", "preferred_parts": ["chest"], "is_feint": true, "feint_windup_duration_mult": 1.07, "feint_target_reveal_at_progress": 0.4, "angle_variance_deg": 9},
		"unterhau": {"name": "Upward diagonal cut", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 2.2, "attack_line": "low", "preferred_parts": ["left_leg", "right_leg"], "angle_variance_deg": 10},
		"slash": {"name": "Horizontal cut (cross)", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 2.0, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm", "chest"], "angle_variance_deg": 10},
		"pommel_strike": {"name": "Pommel strike (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_POMMEL, "base_cooldown": 1.8, "attack_line": "high", "preferred_parts": ["head"], "angle_variance_deg": 9},
		"parry_thrust": {"name": "Parry and thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.0, "is_parry": true, "attack_line": "high", "preferred_parts": ["chest"]},
		"parry_cut": {"name": "Parry and cut", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 1.9, "is_parry": true, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm"]},
		# Axe (Le Jeu de la Hache): spike, overhead chop, diagonal chop, poll
		"spike_thrust": {"name": "Spike thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 3.2, "attack_line": "high", "preferred_parts": ["chest"], "angle_variance_deg": 9},
		"overhead_chop": {"name": "Overhead chop", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_OVERHEAD, "base_cooldown": 3.5, "attack_line": "high", "preferred_parts": ["head"], "angle_variance_deg": 12},
		"diagonal_chop": {"name": "Diagonal chop", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 3.0, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm", "chest"], "angle_variance_deg": 11},
		"poll_strike": {"name": "Back-of-head strike (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.0, "attack_line": "high", "preferred_parts": ["head"], "angle_variance_deg": 11},
		"parry_chop": {"name": "Parry and chop", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 3.0, "is_parry": true, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm"]},
		# Mace: overhead, side, direct — heavy weapon, more wobble
		"overhead_strike": {"name": "Overhead strike", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.5, "attack_line": "high", "preferred_parts": ["head"], "angle_variance_deg": 13},
		"side_strike": {"name": "Side strike", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.2, "attack_line": "right", "preferred_parts": ["left_arm", "right_arm"], "angle_variance_deg": 12},
		"direct_blow": {"name": "Direct blow", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.0, "attack_line": "high", "preferred_parts": ["head", "chest"], "angle_variance_deg": 11},
		"parry_strike": {"name": "Parry and strike", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 3.0, "is_parry": true, "attack_line": "high", "preferred_parts": ["head"]},
		# Dagger / rondel — small, quick, tighter control
		"quick_thrust": {"name": "Quick thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 0.7, "attack_line": "high", "preferred_parts": ["chest"], "angle_variance_deg": 5},
		"committed_thrust": {"name": "Strong thrust (armor-piercing)", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 1.0, "attack_line": "high", "preferred_parts": ["chest"], "angle_variance_deg": 6},
		"quick_slash": {"name": "Quick slash", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_QUICK_SLASH, "base_cooldown": 0.6, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm"], "angle_variance_deg": 6},
		"dagger_pommel": {"name": "Pommel strike (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_POMMEL, "base_cooldown": 0.5, "attack_line": "high", "preferred_parts": ["head"], "angle_variance_deg": 6},
		"parry_thrust_dagger": {"name": "Parry and thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 0.6, "is_parry": true, "attack_line": "high", "preferred_parts": ["chest"], "angle_variance_deg": 5},
		# Spear (Fiore): thrust, angled thrust, slash, pole swing
		"spear_thrust": {"name": "Forward thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 3.0, "attack_line": "high", "preferred_parts": ["chest"], "angle_variance_deg": 7},
		"off_line_thrust": {"name": "Angled thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.8, "attack_line": "high", "preferred_parts": ["chest"], "angle_variance_deg": 20, "angle_offset_deg": 25},
		"spear_slash": {"name": "Slash with spearhead", "contact_type": ATTACK_TYPE_CUT, "archetype_id": ARCHETYPE_SLASH, "base_cooldown": 2.8, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm"], "angle_variance_deg": 10},
		"pole_swing": {"name": "Pole swing (blunt)", "contact_type": ATTACK_TYPE_BLUNT, "archetype_id": ARCHETYPE_HEAVY_BLUNT, "base_cooldown": 2.5, "attack_line": "left", "preferred_parts": ["left_arm", "right_arm", "head"], "angle_variance_deg": 12},
		"parry_thrust_spear": {"name": "Parry and thrust", "contact_type": ATTACK_TYPE_STAB, "archetype_id": ARCHETYPE_STAB, "base_cooldown": 2.7, "is_parry": true, "attack_line": "high", "preferred_parts": ["chest"]}
	}

# --- Weapon template definitions ---
# Per weapon: mass (kg), dimensions (cm), edge_width (cm, optional), blade_cut_ratio, melee_range, moves.
# Dimensions: blade_width = edge contact for cuts; point_width = tip for thrusts; head_diameter = striking head for blunt.
# thrust_head_width = width of head/shaft behind point (cm); used for blunt momentum/area on thrusts. Broader head = lower p/A.
# edge_width = effective sharp contact for blunt weapons (flanges/ridges that can break skin); used for sharp-component penetration.
# impact_velocity_bands (optional): Tier C overrides — keys stab|cut|blunt → {"min":m/s,"max":m/s} or Vector2; see ImpactVelocityModel.gd.
# Data: Oakeshott/longsword 2–3 cm edge, 0.3–0.6 cm point; Le Jeu axe 3–4 cm edge, 0.5–1 cm spike; mace flanges 0.4–0.6 cm (Williams, Tod Cutler); Fiore/Talhoffer dagger ~1.5 cm edge, 0.2–0.4 cm point; spear 0.4–0.8 cm point, head blade 2–3 cm.
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
			"parry_speed_factor": 1.0,
			"blade_width": 2.0,
			"point_width": 0.5,
			"thrust_head_width": 2.0,
			"head_diameter": 3.0,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.75,
			"melee_range": 1.5,
			"parts": [
				{"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
				{"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
			],
			"parry_part_id": "blade",
			"strike_physics": {
				"station_mean": 0.54,
				"station_spread": 0.1,
				"station_cut_vel_guard": 0.9,
				"station_cut_vel_tip": 1.06,
				"coupling_stab": 0.9,
				"coupling_cut": 0.84,
				"coupling_blunt": 0.96,
				"blunt_pressure": 1.0,
				"blunt_head_ref_cm": 6.0
			},
			"moves": [
				{"id": "thrust"},
				{"id": "oberhau"},
				{"id": "oberhau_feint"},
				{"id": "thrust_feint"},
				{"id": "unterhau"},
				{"id": "slash"},
				{"id": "pommel_strike"},
				{"id": "parry_thrust"},
				{"id": "parry_cut"}
			]
		},
		# Battle axe: spike, chops, poll, parry-counter (Le Jeu de la Hache style).
		"AXE": {
			"name": "Axe",
			"mass": 1.5,
			"parry_speed_factor": 0.95,
			"bind_riposte_contact_types": ["cut", "stab"],
			"blade_width": 3.0,
			"point_width": 0.8,
			"thrust_head_width": 1.5,
			"head_diameter": 4.0,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.6,
			"melee_range": 1.5,
			"parts": [
				{"id": "blade", "length_cm": 25, "mass_fraction": 0.4, "parry_eligible": true, "striking_for": ["cut"]},
				{"id": "spike", "length_cm": 8, "mass_fraction": 0.15, "parry_eligible": false, "striking_for": ["stab"]},
				{"id": "haft", "length_cm": 90, "mass_fraction": 0.45, "parry_eligible": true, "striking_for": ["blunt"]}
			],
			"parry_part_id": "haft",
			"strike_physics": {
				"station_mean": 0.58,
				"station_spread": 0.12,
				"station_cut_vel_guard": 0.88,
				"station_cut_vel_tip": 1.07,
				"coupling_stab": 0.88,
				"coupling_cut": 0.86,
				"coupling_blunt": 0.98,
				"blunt_pressure": 1.05,
				"blunt_head_ref_cm": 6.0
			},
			"moves": [
				{"id": "spike_thrust"},
				{"id": "overhead_chop"},
				{"id": "diagonal_chop"},
				{"id": "poll_strike"},
				{"id": "parry_chop"}
			]
		},
		# Mace: overhead, side, direct, parry-counter (blunt only).
		"MACE": {
			"name": "Mace",
			"mass": 1.7,
			"parry_speed_factor": 0.9,
			"blade_width": 0.0,
			"point_width": 0.0,
			"head_diameter": 8.0,
			"edge_width": 0.5,
			"blade_cut_ratio": 0.0,
			"melee_range": 1.5,
			"parts": [
				{"id": "head", "length_cm": 15, "mass_fraction": 0.7, "parry_eligible": false, "striking_for": ["blunt"]},
				{"id": "shaft", "length_cm": 55, "mass_fraction": 0.3, "parry_eligible": true}
			],
			"parry_part_id": "shaft",
			"strike_physics": {
				"station_mean": 0.62,
				"station_spread": 0.09,
				"station_cut_vel_guard": 0.92,
				"station_cut_vel_tip": 1.04,
				"coupling_stab": 0.95,
				"coupling_cut": 0.92,
				"coupling_blunt": 1.06,
				"blunt_pressure": 1.14,
				"blunt_head_ref_cm": 6.0
			},
			"moves": [
				{"id": "overhead_strike"},
				{"id": "side_strike"},
				{"id": "direct_blow"},
				{"id": "parry_strike"}
			]
		},
		# Dagger / rondel: thrusts, slash, pommel, parry-counter (Fiore, Talhoffer).
		"DAGGER": {
			"name": "Dagger",
			"mass": 0.3,
			"parry_speed_factor": 1.2,
			"blade_width": 1.5,
			"point_width": 0.3,
			"thrust_head_width": 1.0,
			"head_diameter": 2.5,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.9,
			"melee_range": 0.8,
			"parts": [
				{"id": "blade", "length_cm": 20, "mass_fraction": 0.55, "parry_eligible": true},
				{"id": "handle", "length_cm": 12, "mass_fraction": 0.45, "parry_eligible": false}
			],
			"parry_part_id": "blade",
			"strike_physics": {
				"station_mean": 0.52,
				"station_spread": 0.08,
				"station_cut_vel_guard": 0.91,
				"station_cut_vel_tip": 1.1,
				"coupling_stab": 0.94,
				"coupling_cut": 0.88,
				"coupling_blunt": 0.9,
				"blunt_pressure": 0.95,
				"blunt_head_ref_cm": 6.0
			},
			"moves": [
				{"id": "quick_thrust"},
				{"id": "committed_thrust"},
				{"id": "quick_slash"},
				{"id": "dagger_pommel"},
				{"id": "parry_thrust_dagger"}
			]
		},
		# Spear (Fiore): thrusts, slash, pole swing (shaft), parry-counter.
		"SPEAR": {
			"name": "Spear",
			"mass": 1.8,
			"parry_speed_factor": 1.0,
			"blade_width": 2.5,
			"point_width": 0.6,
			"thrust_head_width": 2.5,
			"head_diameter": 3.5,
			"edge_width": 0.0,
			"blade_cut_ratio": 0.85,
			"melee_range": 2.5,
			"depth_melee_eligible": true,
			"parts": [
				{"id": "head", "length_cm": 25, "mass_fraction": 0.15, "parry_eligible": false, "striking_for": ["stab", "cut"]},
				{"id": "shaft", "length_cm": 200, "mass_fraction": 0.85, "parry_eligible": true, "striking_for": ["blunt"]}
			],
			"parry_part_id": "shaft",
			"impact_velocity_bands": {
				"stab": {"min": 5.5, "max": 21.0}
			},
			"strike_physics": {
				"station_mean": 0.48,
				"station_spread": 0.11,
				"station_cut_vel_guard": 0.89,
				"station_cut_vel_tip": 1.05,
				"coupling_stab": 0.91,
				"coupling_cut": 0.87,
				"coupling_blunt": 0.99,
				"blunt_pressure": 1.02,
				"blunt_head_ref_cm": 6.0
			},
			"moves": [
				{"id": "spear_thrust"},
				{"id": "off_line_thrust"},
				{"id": "spear_slash"},
				{"id": "pole_swing"},
				{"id": "parry_thrust_spear"}
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

## Kinematic delivery for `WeaponDamageHelper` (abstract — no unit positions): thrust = linear band + point-mass KE; swing = ω–lever + rotational KE; mixed = blend (`kinematic_mixed_blend` 0..1).
const KINEMATIC_DELIVERY_THRUST := "thrust"
const KINEMATIC_DELIVERY_SWING := "swing"
const KINEMATIC_DELIVERY_MIXED := "mixed"

static func get_archetype(archetype_id: String) -> Dictionary:
	var all_arch := _archetype_definitions_build()
	if not all_arch.has(archetype_id):
		return all_arch.get(ARCHETYPE_SLASH, {})
	return all_arch[archetype_id].duplicate(true)

# Reference for area coupling: larger contact (mace) vs smaller (pommel). Using max(head_diameter)
# so the largest blunt weapon yields area_factor=1.0 and transmission stays <= layer blunt_transmission.
static func get_blunt_coupling_reference_cm() -> float:
	var ids: Array = get_all_weapon_ids()
	var max_hd: float = 0.0
	for wid in ids:
		var d: Dictionary = get_weapon_definition(wid)
		var hd = d.get("head_diameter", 0.0)
		if (hd is float or hd is int) and float(hd) > max_hd:
			max_hd = float(hd)
	return max_hd if max_hd > 0.0 else 6.0

static func _archetype_definitions_build() -> Dictionary:
	return {
		ARCHETYPE_STAB: {
			"velocity_factor": 1.0,
			"velocity_intensity_curve": 0.95,
			"cut_ratio": - 1.0, # use weapon blade_cut_ratio
			"recovery_multiplier": 1.0,
			"windup_multiplier": 1.0,
			"kinematic_delivery": KINEMATIC_DELIVERY_THRUST
		},
		ARCHETYPE_SLASH: {
			"velocity_factor": 0.9,
			"velocity_intensity_curve": 1.04,
			"cut_ratio": - 1.0,
			"recovery_multiplier": 1.0,
			"windup_multiplier": 1.0,
			"kinematic_delivery": KINEMATIC_DELIVERY_SWING
		},
		ARCHETYPE_OVERHEAD: {
			"velocity_factor": 1.0,
			"velocity_intensity_curve": 1.1,
			"cut_ratio": - 1.0,
			"recovery_multiplier": 1.2,
			"windup_multiplier": 1.15,
			"kinematic_delivery": KINEMATIC_DELIVERY_SWING
		},
		ARCHETYPE_QUICK_SLASH: {
			"velocity_factor": 0.65,
			"velocity_intensity_curve": 0.8,
			"cut_ratio": - 1.0,
			"recovery_multiplier": 0.85,
			"windup_multiplier": 0.8,
			"kinematic_delivery": KINEMATIC_DELIVERY_SWING
		},
		ARCHETYPE_POMMEL: {
			"velocity_factor": 0.7,
			"velocity_intensity_curve": 0.88,
			"cut_ratio": 0.05,
			"recovery_multiplier": 0.9,
			"windup_multiplier": 0.85,
			"kinematic_delivery": KINEMATIC_DELIVERY_SWING
		},
		ARCHETYPE_HEAVY_BLUNT: {
			"velocity_factor": 1.0,
			"velocity_intensity_curve": 1.12,
			"cut_ratio": 0.05,
			"recovery_multiplier": 1.15,
			"windup_multiplier": 1.1,
			"kinematic_delivery": KINEMATIC_DELIVERY_SWING
		}
	}
