class_name Weapon
extends RefCounted

## Weapon data model: create from definition, type info, damage stats.

const BLUNT_FALLBACK_CONTACT_CM: float = 3.0

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
# Optional: effective edge width for blunt weapons (flanges/ridges that can break skin). Used for sharp-component
# penetration on blunt moves.
var edge_width: float = 0.0
var melee_range: float = 1.5
## Tier 1.9: may strike enemy front rank from home depth when same-file rank 0 is alive (spear lane rules).
var depth_melee_eligible: bool = false
# Cut ratio 0-1 for slash/cut (rest blunt). Blunt attacks use archetype; floor MIN_CUT_RATIO so no weapon is 0% cut.
var blade_cut_ratio: float = 0.75
# Cut ratio 0-1 for stab/thrust (rest blunt). Falls back to blade_cut_ratio if unset.
var stab_cut_ratio: float = 0.75
# Edge sharpness 0-1: 1 = keen (small effective contact), 0 = dull (wider effective contact). Used for effective edge
# width in cutting.
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
    w.stab_cut_ratio = def.get("stab_cut_ratio", w.blade_cut_ratio)
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
            var m: Dictionary = WeaponConstants.get_move(move_id)
            if m is Dictionary and m.get("is_parry", false):
                continue
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
    return ImpactVelocityModel.resolve_band_m_s(self, contact_type)


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


# Effective sharp contact (cm) for cutting: the edge's bearing width, which shrinks as the edge is honed sharper.
# A sharp edge has a narrow apex (small bearing width -> high pressure); a dull edge has a wide rolled edge capped
# at the full blade width (the edge can never be wider than the blade). effective = lerp(geometric, apex, sharpness)
# where apex = max(MIN_CONTACT_WIDTH_CM, geometric * SHARP_APEX_FRACTION); floored at MIN_CONTACT_WIDTH_CM.
func get_effective_sharp_contact_cm(move_id: String) -> float:
    var geometric: float = get_sharp_contact_cm(move_id)
    var s: float = clampf(sharpness, 0.0, 1.0)
    var apex: float = maxf(WeaponConstants.MIN_CONTACT_WIDTH_CM, geometric * WeaponConstants.SHARP_APEX_FRACTION)
    var effective: float = lerpf(geometric, apex, s)
    return maxf(effective, WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Contact (cm) for the BLUNT damage component only. Uses the surface that actually hits for this attack.
# Stab -> geometric mean of point and thrust_head_width: both tip (initial puncture) and head (follow-through) influence
# area.
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
func _mass_from_part_entry(p: Dictionary) -> float:
    var frac: float = p.get("mass_fraction", 1.0)
    return mass * clampf(frac, 0.0, 1.0)


func _striking_mass_for_striking_for(ct: String) -> float:
    for p in parts:
        if p is Dictionary:
            var sf = p.get("striking_for", [])
            if sf is Array:
                for listed in sf:
                    if str(listed).to_lower().strip_edges() == ct:
                        return _mass_from_part_entry(p)
    return -1.0


func _striking_mass_for_ids(ids: Array) -> float:
    for p in parts:
        if p is Dictionary:
            var pid: String = _normalize_part_id(p.get("id", ""))
            if pid in ids:
                return _mass_from_part_entry(p)
    return -1.0


func get_striking_part_mass_kg(contact_type: String) -> float:
    if not has_parts():
        return mass
    var ct: String = contact_type.to_lower().strip_edges() if contact_type else WeaponConstants.ATTACK_TYPE_CUT
    var from_listed: float = _striking_mass_for_striking_for(ct)
    if from_listed >= 0.0:
        return from_listed
    var from_fallback: float = -1.0
    match ct:
        WeaponConstants.ATTACK_TYPE_STAB:
            # For polearm-style weapons, include shaft mass behind the point to reflect
            # that a thrust transmits significant weapon mass through linear drive —
            # especially for polearms where the entire shaft moves forward behind the tip.
            var head_mass: float = _striking_mass_for_ids(["point", "blade", "spike", "head"])
            var shaft_mass: float = _striking_mass_for_ids(["shaft", "haft"])
            if shaft_mass >= 0.0 and (head_mass < 0.0 or shaft_mass > head_mass):
                from_fallback = maxf(0.0, head_mass) + shaft_mass * 0.45  # shaft contributes ~45% to thrust inertia
            elif head_mass >= 0.0 and shaft_mass >= 0.0:
                # Polearm with separate head+shaft parts: shaft always contributes behind the point on thrust,
                # regardless of whether it's marked as striking_for=stab (it may only be marked for blunt).
                from_fallback = maxf(0.0, head_mass) + shaft_mass * 0.45
            elif head_mass >= 0.0:
                from_fallback = head_mass
        WeaponConstants.ATTACK_TYPE_CUT:
            from_fallback = _striking_mass_for_ids(["blade"])
        WeaponConstants.ATTACK_TYPE_BLUNT:
            from_fallback = _striking_mass_for_ids(["head", "haft", "shaft"])
    if from_fallback >= 0.0:
        return from_fallback
    if parts.size() > 0 and parts[0] is Dictionary:
        return _mass_from_part_entry(parts[0])
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


## Blade slenderness ratio: blade_length_cm / blade_width_cm. Higher = more flexible (longer/thinner).
## A flexible blade flexes more under load, so its forte/schwach difference is larger. Returns 0.0 when
## there is no blade part or no blade width (shaft/haft weapons).
func get_blade_slenderness() -> float:
    if not has_parts() or blade_width <= 0.0:
        return 0.0
    var blade_len: float = 0.0
    for p in parts:
        if p is Dictionary and _normalize_part_id(p.get("id", "")) == "blade":
            blade_len = float(p.get("length_cm", 0.0))
            break
    if blade_len <= 0.0:
        return 0.0
    return blade_len / blade_width


## Spatial strong/weak zone fraction at a given parry timing progress (0 = very early/handle-end, 1 = impact/tip).
## Models HEMA Stercke/Schweche: early parries contact with the forte (strong/near-hands), late parries
## contact near the middle or weak of blade. Contact quality scales multiplicatively with this fraction.
## `parry_progress` is where along the attack wind-up the defender meets the blade (0..1).
## Returns a strong_fraction in [0.25, 1.0] where 1.0 = full forte engagement.
func get_spatial_strong_fraction_at_parry(parry_progress: float) -> float:
    if not has_parts() or parry_part_id.is_empty():
        return 0.5
    if get_parry_contact_type() != "blade":
        return 1.0  # Shaft/haft don't have strong/weak zones in the same way
    var base_strong: float = get_parry_strong_fraction()
    # Early parry (parry_progress < 0.5): contact near handle — stronger engagement.
    # Late parry (parry_progress > 0.7): contact farther from handle — weaker engagement.
    # Parry progress 0.3 = very early = 90% of base_strong; progress 0.85 = late = 40% of base_strong.
    var timing_shift: float = 1.0 - clampf((parry_progress - 0.2) / 0.7, 0.0, 1.0)
    # Strong fraction at contact point: ranges from base_strong (early) down to base_strong * 0.4 (late).
    var effective_strong: float = lerpf(base_strong, base_strong * 0.35, timing_shift)
    return clampf(effective_strong, 0.15, 0.6)
