class_name Weapon
extends RefCounted

# Template-backed weapon instance. Load from WeaponConstants; can later add
# durability, quality, modifications for customisable weapons.

var display_name: String = ""
var weapon_type: String = ""

# Physical properties (cm, kg). Used for contact area per attack type and per damage component.
var mass: float = 1.0
var blade_width: float = 2.0
var point_width: float = 0.5
var thrust_head_width: float = 0.0  # Width of head/shaft behind point; used for blunt momentum/area on thrusts.
var head_diameter: float = 0.0
# Optional: effective edge width for blunt weapons (flanges/ridges that can break skin). Used for sharp-component penetration on blunt moves.
var edge_width: float = 0.0
var melee_range: float = 1.5
# Cut ratio 0-1 for slash/cut (rest blunt). Blunt attacks use archetype; floor MIN_CUT_RATIO so no weapon is 0% cut.
var blade_cut_ratio: float = 0.75
# Edge sharpness 0-1: 1 = keen (small effective contact), 0 = dull (wider effective contact). Used for effective edge width in cutting.
var sharpness: float = 1.0

# Move pool for this weapon: move_id -> { cooldown, archetype_id }. From def["moves"]; defaults from get_move().
var attack_types: Dictionary = {}


static func create_from_definition(weapon_id: String) -> Weapon:
	var def: Dictionary = WeaponConstants.get_weapon_definition(weapon_id)
	if def.is_empty():
		return null
	var w := Weapon.new()
	w.display_name = def.get("name", weapon_id)
	w.weapon_type = weapon_id.to_upper()
	w.mass = def.get("mass", WeaponConstants.BASELINE_MASS_KG)
	w.blade_width = def.get("blade_width", WeaponConstants.BASELINE_CONTACT_CM)
	w.point_width = def.get("point_width", 0.5)
	w.thrust_head_width = def.get("thrust_head_width", 0.0)
	w.head_diameter = def.get("head_diameter", 0.0)
	w.edge_width = def.get("edge_width", 0.0)
	w.melee_range = def.get("melee_range", 1.5)
	w.blade_cut_ratio = def.get("blade_cut_ratio", 0.75)
	w.sharpness = def.get("sharpness", 1.0)
	var moves_arr = def.get("moves", [])
	for entry in moves_arr:
		if entry is Dictionary and entry.has("id"):
			var move_id: String = str(entry.id)
			var move_def: Dictionary = WeaponConstants.get_move(move_id)
			if move_def.is_empty():
				continue
			var cooldown = entry.get("cooldown", move_def.get("base_cooldown", WeaponConstants.DEFAULT_COOLDOWN))
			var arch_id = entry.get("archetype_id", move_def.get("archetype_id", WeaponConstants.ARCHETYPE_SLASH))
			w.attack_types[move_id] = { "cooldown": cooldown, "archetype_id": arch_id }
	return w


func get_cooldown(move_id: String) -> float:
	if attack_types.has(move_id):
		return attack_types[move_id].get("cooldown", WeaponConstants.DEFAULT_COOLDOWN)
	var m = WeaponConstants.get_move(move_id)
	return float(m.get("base_cooldown", WeaponConstants.DEFAULT_COOLDOWN))


# Contact type for this move (stab/cut/blunt); from move definition.
func get_contact_type(move_id: String) -> String:
	var m = WeaponConstants.get_move(move_id)
	return str(m.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))


# Contact area (cm) for this move: stab -> point, cut -> blade, blunt -> head.
# When blunt but head_diameter is 0 (pommel, poll, butt), use fallback.
const BLUNT_FALLBACK_CONTACT_CM: float = 3.0

func get_contact_width(move_id: String) -> float:
	var ct: String = get_contact_type(move_id)
	match ct:
		WeaponConstants.ATTACK_TYPE_STAB:
			return point_width
		WeaponConstants.ATTACK_TYPE_CUT:
			return blade_width
		WeaponConstants.ATTACK_TYPE_BLUNT:
			if head_diameter > 0.0:
				return head_diameter
			return BLUNT_FALLBACK_CONTACT_CM
	return WeaponConstants.BASELINE_CONTACT_CM


# Contact (cm) for the SHARP damage component only. Used for sharp penetration so each component is accurate.
# Stab -> point; cut -> blade; blunt move -> edge_width (flanges/ridges) if set, else MIN to avoid zero.
func get_sharp_contact_cm(move_id: String) -> float:
	var ct: String = get_contact_type(move_id)
	match ct:
		WeaponConstants.ATTACK_TYPE_STAB:
			return point_width if point_width > 0.0 else WeaponConstants.MIN_CONTACT_WIDTH_CM
		WeaponConstants.ATTACK_TYPE_CUT:
			return blade_width if blade_width > 0.0 else WeaponConstants.MIN_CONTACT_WIDTH_CM
		WeaponConstants.ATTACK_TYPE_BLUNT:
			if edge_width > 0.0:
				return edge_width
			if point_width > 0.0:
				return point_width
			return WeaponConstants.MIN_CONTACT_WIDTH_CM
	return WeaponConstants.BASELINE_CONTACT_CM


# Effective sharp contact (cm) for cutting: geometric contact reduced by sharpness (sharper = smaller effective = higher pressure).
# effective = geometric / (SHARPNESS_FACTOR_MIN + (1 - SHARPNESS_FACTOR_MIN) * sharpness); floored at MIN_CONTACT_WIDTH_CM.
func get_effective_sharp_contact_cm(move_id: String) -> float:
	var geometric: float = get_sharp_contact_cm(move_id)
	var s: float = clampf(sharpness, 0.0, 1.0)
	var denom: float = WeaponConstants.SHARPNESS_FACTOR_MIN + (1.0 - WeaponConstants.SHARPNESS_FACTOR_MIN) * s
	var effective: float = geometric / denom if denom > 0.0 else geometric
	return maxf(effective, WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Contact (cm) for the BLUNT damage component only. Uses the surface that actually hits for this attack.
# Stab -> geometric mean of point and thrust_head_width: both tip (initial puncture) and head (follow-through) influence area.
# Cut -> slap/flat; blunt -> head or fallback.
func get_blunt_contact_cm(move_id: String) -> float:
	var ct: String = get_contact_type(move_id)
	match ct:
		WeaponConstants.ATTACK_TYPE_STAB:
			var point: float = point_width if point_width > 0.0 else WeaponConstants.MIN_CONTACT_WIDTH_CM
			if thrust_head_width > 0.0:
				return sqrt(point * thrust_head_width)
			return point
		WeaponConstants.ATTACK_TYPE_CUT:
			return maxf(blade_width, WeaponConstants.BLUNT_CUT_MIN_CONTACT_CM)
		WeaponConstants.ATTACK_TYPE_BLUNT:
			if head_diameter > 0.0:
				return head_diameter
			return BLUNT_FALLBACK_CONTACT_CM
	return WeaponConstants.BASELINE_CONTACT_CM


func get_damage_type(move_id: String) -> String:
	if get_contact_type(move_id) == WeaponConstants.ATTACK_TYPE_BLUNT:
		return WeaponConstants.DAMAGE_TYPE_BLUNT
	return WeaponConstants.DAMAGE_TYPE_SHARP


func get_available_attack_types() -> Array:
	var out: Array = []
	for key in attack_types.keys():
		out.append(key)
	return out


func get_archetype_id(move_id: String) -> String:
	if attack_types.has(move_id):
		var aid = attack_types[move_id].get("archetype_id", "")
		if aid is String and aid != "":
			return aid
	var m = WeaponConstants.get_move(move_id)
	return str(m.get("archetype_id", WeaponConstants.ARCHETYPE_SLASH))


# Display name for this move (e.g. "Oberhau", "Pommel strike").
func get_move_name(move_id: String) -> String:
	var m = WeaponConstants.get_move(move_id)
	return str(m.get("name", move_id))


# True if this move is an explicit parry attack (deflect then counter).
func is_parry_move(move_id: String) -> bool:
	return WeaponConstants.is_parry_move(move_id)
