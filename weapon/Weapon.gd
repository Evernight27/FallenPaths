class_name Weapon
extends RefCounted

## Weapon data model: create from definition, type info, damage stats.

const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")

# Template-backed weapon instance. Load from WeaponConstants; can later add
# durability, quality, modifications for customisable weapons.

var display_name: String = ""
var weapon_type: String = ""

# Physical properties (cm, kg). Used for contact area per attack type and per damage component.
var mass: float = 1.0
var is_two_handed: bool = false
var parry_speed_factor: float = 1.0  # Scale for parry blade speed (1.0 = default; dagger > 1, mace < 1)
var blade_width: float = 2.0
var point_width: float = 0.5
var thrust_head_width: float = 0.0  # Width of head/shaft behind point; used for blunt momentum/area on thrusts.
var head_diameter: float = 0.0
# Optional: effective edge width for blunt weapons (flanges/ridges that can break skin). Used for sharp-component penetration on blunt moves.
var edge_width: float = 0.0
var melee_range: float = 1.5
## Tier 1.9: may strike enemy front rank from home depth when same-file rank 0 is alive (spear lane rules).
var depth_melee_eligible: bool = false
# Cut ratio 0-1 for slash/cut (rest blunt). Blunt attacks use archetype; floor MIN_CUT_RATIO so no weapon is 0% cut.
var blade_cut_ratio: float = 0.75
# Edge sharpness 0-1: 1 = keen (small effective contact), 0 = dull (wider effective contact). Used for effective edge width in cutting.
var sharpness: float = 1.0

# Move pool for this weapon: move_id -> { cooldown, archetype_id }. From def["moves"]; defaults from get_move().
var attack_types: Dictionary = {}

# Weapon part model (Level 4): per-part length, mass fraction, parry eligibility.
# Definitions always provide parts; empty array is filled in create_from_definition with one whole-weapon part.
var parts: Array = []  # Array of {id, length_cm, mass_fraction, parry_eligible, striking_for}
var parry_part_id: String = ""  # Which part parries; must match a part with parry_eligible true.
# Bind riposte: contact types eligible for wind-up bonus. From def or inferred from is_parry moves.
var bind_riposte_contact_types: Array = []
## Tier C: optional per-contact velocity bands (m/s). Keys: stab | cut | blunt -> Vector2(min,max) or {"min":f,"max":f}.
var impact_velocity_bands: Dictionary = {}
## Strike realism defaults (station, coupling, blunt pressure); see StrikeRealismProfile.gd.
var strike_physics: Dictionary = {}


static func _normalize_part_id(raw_id: Variant) -> String:
    return str(raw_id).to_lower().strip_edges()


static func parry_part_id_from_parts(parts_arr: Array, preferred_id: String = "") -> String:
    var wanted: String = _normalize_part_id(preferred_id)
    if not wanted.is_empty():
        for p in parts_arr:
            if p is Dictionary and _normalize_part_id(p.get("id", "")) == wanted:
                if p.get("parry_eligible", false):
                    return p.get("id", "")
                break
    for p in parts_arr:
        if p is Dictionary and p.get("parry_eligible", false):
            return p.get("id", "")
    var best_id: String = ""
    var best_fraction: float = -1.0
    for p in parts_arr:
        if p is Dictionary:
            var frac: float = p.get("mass_fraction", 0.0)
            if frac > best_fraction:
                best_fraction = frac
                best_id = p.get("id", "")
    return best_id


static func create_from_definition(weapon_id: String) -> Weapon:
    var def: Dictionary = WeaponConstants.get_weapon_definition(weapon_id)
    if def.is_empty():
        return null
    var w := Weapon.new()
    w.display_name = def.get("name", weapon_id)
    w.weapon_type = weapon_id.to_upper()
    w.mass = def.get("mass", WeaponConstants.BASELINE_MASS_KG)
    w.is_two_handed = def.get("is_two_handed", false)
    w.parry_speed_factor = def.get("parry_speed_factor", 1.0)
    w.blade_width = def.get("blade_width", WeaponConstants.BASELINE_CONTACT_CM)
    w.point_width = def.get("point_width", 0.5)
    w.thrust_head_width = def.get("thrust_head_width", 0.0)
    w.head_diameter = def.get("head_diameter", 0.0)
    w.edge_width = def.get("edge_width", 0.0)
    w.melee_range = def.get("melee_range", 1.5)
    w.depth_melee_eligible = def.get("depth_melee_eligible", false)
    w.blade_cut_ratio = def.get("blade_cut_ratio", 0.75)
    w.sharpness = def.get("sharpness", 1.0)
    var parts_arr = def.get("parts", [])
    if parts_arr is Array and parts_arr.size() > 0:
        for p in parts_arr:
            if p is Dictionary:
                w.parts.append(p.duplicate())
        w.parry_part_id = parry_part_id_from_parts(w.parts, def.get("parry_part_id", ""))
    if w.parts.is_empty():
        var len_cm: float = maxf(30.0, w.melee_range * 60.0)
        w.parts = [
            {
                "id": "weapon",
                "length_cm": len_cm,
                "mass_fraction": 1.0,
                "parry_eligible": true,
                "striking_for":
                [WeaponConstants.ATTACK_TYPE_STAB, WeaponConstants.ATTACK_TYPE_CUT, WeaponConstants.ATTACK_TYPE_BLUNT]
            }
        ]
        if w.parry_part_id.is_empty():
            w.parry_part_id = "weapon"
    var moves_arr = def.get("moves", [])
    for entry in moves_arr:
        if entry is Dictionary and entry.has("id"):
            var move_id: String = str(entry.id)
            var move_def: Dictionary = WeaponConstants.get_move(move_id)
            if move_def.is_empty():
                continue
            var cooldown = entry.get("cooldown", move_def.get("base_cooldown", WeaponConstants.DEFAULT_COOLDOWN))
            var arch_id = entry.get("archetype_id", move_def.get("archetype_id", WeaponConstants.ARCHETYPE_SLASH))
            w.attack_types[move_id] = {"cooldown": cooldown, "archetype_id": arch_id}
    var brct: Variant = def.get("bind_riposte_contact_types", [])
    var valid_bind_contacts: Dictionary = {
        WeaponConstants.ATTACK_TYPE_STAB: true,
        WeaponConstants.ATTACK_TYPE_CUT: true,
        WeaponConstants.ATTACK_TYPE_BLUNT: true
    }
    if brct is Array and brct.size() > 0:
        var seen_override: Dictionary = {}
        for raw_ct in brct:
            var ct_override: String = str(raw_ct).to_lower().strip_edges()
            if valid_bind_contacts.get(ct_override, false) and not seen_override.get(ct_override, false):
                seen_override[ct_override] = true
                w.bind_riposte_contact_types.append(ct_override)
    else:
        var seen: Dictionary = {}
        for move_id in w.attack_types.keys():
            if WeaponConstants.is_parry_move(move_id):
                var m: Dictionary = WeaponConstants.get_move(move_id)
                var ct: String = str(m.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)).to_lower().strip_edges()
                if valid_bind_contacts.get(ct, false) and not seen.get(ct, false):
                    seen[ct] = true
                    w.bind_riposte_contact_types.append(ct)
    var ivb: Variant = def.get("impact_velocity_bands", {})
    if ivb is Dictionary:
        w.impact_velocity_bands = ivb.duplicate(true)
    var sp: Variant = def.get("strike_physics", {})
    if sp is Dictionary:
        w.strike_physics = sp.duplicate(true)
    return w


## Resolved impact speed band (m/s) for Tier A - C model. contact_type: stab | cut | blunt.
func get_impact_velocity_band_m_s(contact_type: String) -> Vector2:
    return _ImpactVelocityModel.resolve_band_m_s(self, contact_type)


func get_cooldown(move_id: String) -> float:
    if attack_types.has(move_id):
        return attack_types[move_id].get("cooldown", WeaponConstants.DEFAULT_COOLDOWN)
    var m = WeaponConstants.get_move(move_id)
    return m.get("base_cooldown", WeaponConstants.DEFAULT_COOLDOWN)


# Contact type for this move (stab/cut/blunt); canonical resolver (move id or bare contact).
func get_contact_type(move_id: String) -> String:
    return WeaponConstants.contact_type_for_move_id(move_id)


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


# --- Weapon part model (Level 4): parry and striking part mass ---


func has_parts() -> bool:
    return parts.size() > 0


## Mass (kg) of the part used for parrying. Without parts, uses total weapon mass.
func get_parry_part_mass_kg() -> float:
    if not has_parts() or parry_part_id.is_empty():
        return mass
    var wanted_part_id: String = _normalize_part_id(parry_part_id)
    for p in parts:
        if p is Dictionary and _normalize_part_id(p.get("id", "")) == wanted_part_id:
            var frac: float = p.get("mass_fraction", 1.0)
            return mass * clampf(frac, 0.0, 1.0)
    return mass


## Length (cm) of the parry part. Without parts, returns 0.
func get_parry_part_length_cm() -> float:
    if not has_parts() or parry_part_id.is_empty():
        return 0.0
    var wanted_part_id: String = _normalize_part_id(parry_part_id)
    for p in parts:
        if p is Dictionary and _normalize_part_id(p.get("id", "")) == wanted_part_id:
            return p.get("length_cm", 0)
    return 0.0


## Mass (kg) of the part that strikes for the given contact_type. Without parts, uses total mass.
func get_striking_part_mass_kg(contact_type: String) -> float:
    if not has_parts():
        return mass
    var ct: String = contact_type.to_lower().strip_edges() if contact_type else WeaponConstants.ATTACK_TYPE_CUT
    for p in parts:
        if p is Dictionary:
            var sf = p.get("striking_for", [])
            if sf is Array:
                for listed in sf:
                    if str(listed).to_lower().strip_edges() == ct:
                        var frac: float = p.get("mass_fraction", 1.0)
                        return mass * clampf(frac, 0.0, 1.0)
    match ct:
        WeaponConstants.ATTACK_TYPE_STAB:
            for p in parts:
                if p is Dictionary:
                    var pid: String = _normalize_part_id(p.get("id", ""))
                    if pid in ["point", "blade", "spike", "head"]:
                        var frac: float = p.get("mass_fraction", 1.0)
                        return mass * clampf(frac, 0.0, 1.0)
        WeaponConstants.ATTACK_TYPE_CUT:
            for p in parts:
                if p is Dictionary and _normalize_part_id(p.get("id", "")) == "blade":
                    var frac: float = p.get("mass_fraction", 1.0)
                    return mass * clampf(frac, 0.0, 1.0)
        WeaponConstants.ATTACK_TYPE_BLUNT:
            for p in parts:
                if p is Dictionary:
                    var pid: String = _normalize_part_id(p.get("id", ""))
                    if pid in ["head", "haft", "shaft"]:
                        var frac: float = p.get("mass_fraction", 1.0)
                        return mass * clampf(frac, 0.0, 1.0)
    if parts.size() > 0 and parts[0] is Dictionary:
        var frac: float = parts[0].get("mass_fraction", 1.0)
        return mass * clampf(frac, 0.0, 1.0)
    return mass


## Parry contact type for modifier lookup: "blade"|"shaft"|"haft". Default "blade" when unknown.
func get_parry_contact_type() -> String:
    if not has_parts() or parry_part_id.is_empty():
        return "blade"
    var map: Dictionary = {"blade": "blade", "handle": "blade", "shaft": "shaft", "haft": "haft", "head": ""}
    var t: String = map.get(_normalize_part_id(parry_part_id), "blade")
    return t if not t.is_empty() else "blade"


## Strong fraction for blade parrying: portion of weapon near guard (forte). handle_length/total_length.
## Only meaningful when parry_part_id is "blade". Shaft/haft use leverage factor instead. Returns 0.25 when unknown.
func get_parry_strong_fraction() -> float:
    if not has_parts() or parry_part_id.is_empty():
        return 0.25
    if get_parry_contact_type() != "blade":
        return 0.25
    var handle_len: float = 0.0
    var total: float = 0.0
    for p in parts:
        if p is Dictionary:
            var plen: float = p.get("length_cm", 0)
            total += plen
            var pid: String = _normalize_part_id(p.get("id", ""))
            if pid == "handle":
                handle_len = plen
    if total <= 0.0 or handle_len <= 0.0:
        return 0.25
    return clampf(handle_len / total, 0.1, 0.5)
