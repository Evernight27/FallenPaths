class_name ImpactVelocityModel
extends RefCounted

## Tier A: default tip-speed bands (m/s) per weapon template × contact_type (stab/cut/blunt).
## Tier B: geometry multiplier from strike lever vs reference (~longsword cut arc).
## Tier C: optional per-weapon overrides in Weapon.impact_velocity_bands[contact] = Vector2 or {min,max}.
## Move ids map to contact via WeaponConstants.contact_type_for_move_id(move_id).

const _W := preload("res://weapon/WeaponConstants.gd")

const ABS_VELOCITY_MIN_M_S := 2.0
const ABS_VELOCITY_MAX_M_S := 30.0

## Unarmed strike band (m/s): trained hand peak speeds often ~6–9 m/s; band allows fatigue/weak shots.
const UNARMED_VELOCITY_MIN_M_S := 4.5
const UNARMED_VELOCITY_MAX_M_S := 10.0

const _REFERENCE_STRIKE_RADIUS_M := 0.52

static var _default_bands: Dictionary = {
	"SWORD": {
		"stab": Vector2(4.5, 17.0),
		"cut": Vector2(6.0, 22.0),
		"blunt": Vector2(5.0, 18.0)
	},
	"AXE": {
		"stab": Vector2(4.0, 15.0),
		"cut": Vector2(5.5, 20.0),
		"blunt": Vector2(5.5, 19.0)
	},
	"MACE": {
		"stab": Vector2(6.0, 18.0),
		"cut": Vector2(7.0, 20.0),
		"blunt": Vector2(7.0, 20.5)
	},
	"DAGGER": {
		"stab": Vector2(4.0, 18.0),
		"cut": Vector2(5.5, 20.0),
		"blunt": Vector2(4.0, 14.0)
	},
	"SPEAR": {
		"stab": Vector2(5.0, 20.0),
		"cut": Vector2(5.5, 17.5),
		"blunt": Vector2(5.5, 17.5)
	}
}


static func clamp_velocity_m_s(v: float) -> float:
	return clampf(v, ABS_VELOCITY_MIN_M_S, ABS_VELOCITY_MAX_M_S)


static func unarmed_velocity_band_m_s() -> Vector2:
	return Vector2(UNARMED_VELOCITY_MIN_M_S, UNARMED_VELOCITY_MAX_M_S)


static func _tier_a_default_band(weapon_type: String, contact_type: String) -> Vector2:
	var wt: String = weapon_type.to_upper()
	var ct: String = contact_type.to_lower()
	var by_weapon: Dictionary = _default_bands.get(wt, _default_bands["SWORD"])
	var band: Variant = by_weapon.get(ct, null)
	if band is Vector2:
		return band
	if by_weapon.has(_W.ATTACK_TYPE_CUT):
		return by_weapon[_W.ATTACK_TYPE_CUT]
	return Vector2(_W.VELOCITY_MIN_M_S, _W.VELOCITY_MAX_M_S)


static func _tier_c_override(weapon: RefCounted, contact_type: String) -> Vector2:
	if weapon == null or not (weapon is Object):
		return Vector2(-1.0, -1.0)
	var iv_raw: Variant = (weapon as Object).get("impact_velocity_bands")
	var iv: Dictionary = iv_raw if iv_raw is Dictionary else {}
	var entry: Variant = iv.get(contact_type.to_lower(), null)
	if entry == null:
		return Vector2(-1.0, -1.0)
	if entry is Vector2:
		return entry
	if entry is Dictionary:
		var mn: float = float(entry.get("min", -1.0))
		var mx: float = float(entry.get("max", -1.0))
		if mn >= 0.0 and mx > mn:
			return Vector2(mn, mx)
	return Vector2(-1.0, -1.0)


## Approximate strike radius (m) for scaling Tier B: longer lever → slightly higher v_cap at same effort.
static func strike_radius_m(weapon: RefCounted, contact_type: String) -> float:
	if weapon == null:
		return _REFERENCE_STRIKE_RADIUS_M
	var ct: String = contact_type.to_lower()
	var parts_src: Array = []
	if weapon is Object:
		var pr: Variant = (weapon as Object).get("parts")
		if pr is Array:
			parts_src = pr
	var use_part_geometry: bool = parts_src.size() > 0 or (weapon.has_method("has_parts") and weapon.has_parts())
	if use_part_geometry:
		var iterable: Array = parts_src
		if iterable.is_empty() and weapon is Object:
			var pr2: Variant = (weapon as Object).get("parts")
			if pr2 is Array:
				iterable = pr2
		var total_len_cm: float = 0.0
		for p in iterable:
			if p is Dictionary:
				var pd: Dictionary = p
				var sf: Variant = pd.get("striking_for", [])
				if sf is Array and ct in sf:
					total_len_cm += float(pd.get("length_cm", 0.0))
		if total_len_cm > 0.0:
			if ct == _W.ATTACK_TYPE_CUT or ct == _W.ATTACK_TYPE_BLUNT:
				return clampf((total_len_cm / 100.0) * 0.58, 0.22, 1.05)
			if ct == _W.ATTACK_TYPE_STAB:
				var mr: float = float(weapon.melee_range) if (weapon.melee_range is float or weapon.melee_range is int) else 1.5
				return clampf((total_len_cm / 100.0) * 0.32 + mr * 0.09, 0.25, 0.88)
	var melee_r: float = float(weapon.melee_range) if (weapon.melee_range is float or weapon.melee_range is int) else 1.5
	return clampf(melee_r * 0.36, 0.28, 0.92)


static func geometry_velocity_multiplier(weapon: RefCounted, contact_type: String) -> float:
	var r: float = strike_radius_m(weapon, contact_type)
	if r <= 0.001:
		return 1.0
	var t: float = sqrt(clampf(r / _REFERENCE_STRIKE_RADIUS_M, 0.62, 1.38))
	return clampf(t, 0.88, 1.15)


## Resolved (min,max) impact speed (m/s) for this weapon and contact stream.
static func resolve_band_m_s(weapon: RefCounted, contact_type: String) -> Vector2:
	var ct: String = contact_type.to_lower()
	if weapon == null:
		var u := unarmed_velocity_band_m_s()
		return Vector2(
			clampf(u.x, ABS_VELOCITY_MIN_M_S, ABS_VELOCITY_MAX_M_S),
			clampf(u.y, ABS_VELOCITY_MIN_M_S, ABS_VELOCITY_MAX_M_S)
		)
	var c_band: Vector2 = _tier_c_override(weapon, ct)
	var vmin: float
	var vmax: float
	if c_band.x >= 0.0 and c_band.y > c_band.x:
		vmin = c_band.x
		vmax = c_band.y
	else:
		var wtype: String = str(weapon.weapon_type).to_upper() if "weapon_type" in weapon else "SWORD"
		var base: Vector2 = _tier_a_default_band(wtype, ct)
		vmin = base.x
		vmax = base.y
	var mult: float = geometry_velocity_multiplier(weapon, ct)
	vmin = clampf(vmin * lerpf(1.0, mult, 0.38), ABS_VELOCITY_MIN_M_S, ABS_VELOCITY_MAX_M_S)
	vmax = clampf(vmax * mult, vmin + 0.55, ABS_VELOCITY_MAX_M_S)
	return Vector2(vmin, vmax)
