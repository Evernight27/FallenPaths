class_name ImpactVelocityModel
extends RefCounted

## Tier A: default tip-speed bands (m/s) per weapon template for contact_type (stab/cut/blunt).
## Bands represent achievable tip speed (m/s) at _REFERENCE_STRIKE_RADIUS_M = 0.52m for each weapon type.
## No geometry multiplier is applied — the rotational KE path converts v -> omega via actual lever arm.
## Tier C: optional per-weapon overrides in Weapon.impact_velocity_bands[contact] = Vector2 or {min,max}.
## Move ids map to contact via WeaponConstants.contact_type_for_move_id(move_id).

const ABS_VELOCITY_MIN_M_S := 2.0
const ABS_VELOCITY_MAX_M_S := 30.0

## Unarmed strike band (m/s): trained hand peak speeds often ~6 - 9 m/s; band allows fatigue/weak shots.
const UNARMED_VELOCITY_MIN_M_S := 4.5
const UNARMED_VELOCITY_MAX_M_S := 10.0

const _REFERENCE_STRIKE_RADIUS_M := 0.52

## Calibrated bands: max produces realistic KE at committed intensity with full rotational inertia.
## Band values represent achievable tip speed (m/s) at _REFERENCE_STRIKE_RADIUS_M for each weapon type.
## No geometry multiplier is applied — the rotational KE path converts v -> omega via actual lever arm.
## SWORD: I≈0.42, r=0.75, cut_band_max=19.4 → KE≈137J at committed
## AXE:   I≈1.07, r=1.11, band_max=20.0 → KE≈133J at committed
## MACE:  I≈0.50, r=0.63, band_max=16.0 → KE≈230J at committed (reduced: heavy weapon swings slower; research says 8-14 m/s peak)
## DAGGER: I≈0.008, r=0.29, band_max=20.0 → KE≈16J at committed (hand-speed limited)
## SPEAR: shaft mass dominates. Swing tip speeds (cut/blunt) capped ~16 m/s by physics; THRUST tip
## speed is far lower (5-9.5 m/s — a linear push, not a lever arc), so thrust KE (½·2kg·v² with body
## transfer) lands in the 25-90 J reference band. Swing uses full rotational inertia (~2.75 kg·m²);
## thrust uses ~2 kg body-transfer point mass. Same band source, different KE computation path.
static var _default_bands: Dictionary = {
    "SWORD": {"stab": Vector2(5.5, 19.0), "cut": Vector2(7.5, 19.4), "blunt": Vector2(6.0, 20.0)},
    "AXE": {"stab": Vector2(3.5, 14.0), "cut": Vector2(5.0, 18.5), "blunt": Vector2(5.0, 17.5)},
    "MACE": {"stab": Vector2(5.5, 16.0), "cut": Vector2(6.5, 16.0), "blunt": Vector2(6.5, 16.0)},
    "DAGGER": {"stab": Vector2(4.0, 18.0), "cut": Vector2(5.5, 20.0), "blunt": Vector2(4.0, 14.0)},
    "SPEAR": {"stab": Vector2(5.0, 9.5), "cut": Vector2(5.0, 16.0), "blunt": Vector2(4.7, 16.0)}
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
    if by_weapon.has(WeaponConstants.ATTACK_TYPE_CUT):
        return by_weapon[WeaponConstants.ATTACK_TYPE_CUT]
    return Vector2(WeaponConstants.VELOCITY_MIN_M_S, WeaponConstants.VELOCITY_MAX_M_S)


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
        var mn: float = entry.get("min", -1.0)
        var mx: float = entry.get("max", -1.0)
        if mn >= 0.0 and mx > mn:
            return Vector2(mn, mx)
    return Vector2(-1.0, -1.0)


## Approximate strike radius (m) used by WeaponSwingPhysics for lever arm and omega calculation.
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
                    total_len_cm += pd.get("length_cm", 0.0)
        if total_len_cm > 0.0:
            if ct == WeaponConstants.ATTACK_TYPE_CUT or ct == WeaponConstants.ATTACK_TYPE_BLUNT:
                return clampf((total_len_cm / 100.0) * 0.58, 0.22, 1.05)
            if ct == WeaponConstants.ATTACK_TYPE_STAB:
                var mr: float = (
                    float(weapon.melee_range) if (weapon.melee_range is float or weapon.melee_range is int) else 1.5
                )
                return clampf((total_len_cm / 100.0) * 0.32 + mr * 0.09, 0.25, 0.88)
    var melee_r: float = (
        float(weapon.melee_range) if (weapon.melee_range is float or weapon.melee_range is int) else 1.5
    )
    return clampf(melee_r * 0.36, 0.28, 0.92)


## Resolved (min,max) impact speed (m/s) for this weapon and contact stream.
## Bands are calibrated at _REFERENCE_STRIKE_RADIUS_M; geometry scaling is NOT applied here because
## the rotational KE path already converts band velocity -> omega via r, and the band values account
## for the reference radius. Applying geometry would double-count the lever advantage.
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
    return Vector2(
        clampf(vmin, ABS_VELOCITY_MIN_M_S, ABS_VELOCITY_MAX_M_S),
        clampf(vmax, vmin + 0.55, ABS_VELOCITY_MAX_M_S)
    )
