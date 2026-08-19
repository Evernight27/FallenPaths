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

## Mass scaling for band max: tip speed for a given muscular torque scales as sqrt(tau*r/I), so a weapon
## heavier than the reference achieves lower peak tip speed and a lighter one higher. The default bands are
## calibrated at SWORD (1.30 kg); scale band MAX by sqrt(m_ref/m) clamped to [0.7, 1.4] so standard weapons
## stay near their HEMA-calibrated values while custom/light/heavy templates move physically. Band MIN is
## reaction-limited (draw-back time), not inertia-limited, so it is left unscaled.
const MASS_SCALING_REFERENCE_KG := 1.30
const MASS_SCALING_MIN_FACTOR := 0.70
const MASS_SCALING_MAX_FACTOR := 1.40

## Calibrated bands: max produces realistic KE at committed intensity with full rotational inertia.
## Band values represent achievable tip speed (m/s) at _REFERENCE_STRIKE_RADIUS_M for each weapon type.
## Band MAX = peak velocity at full commitment (i≈1.0 + extension); typical exchanges produce lower effective speeds (~70-85% of max).
## No geometry multiplier is applied — the rotational KE path converts v -> omega via actual lever arm.
## SWORD: I≈0.42 (approx; actual computed from weapon geometry), r=0.75, cut_band_max=16.0 → KE≈93J at committed (mass=1.30 kg; HEMA force-plate shows typical cuts 8-14 m/s); stab_band_max=13.0 → thrust KE≈127J
## AXE:   I≈1.07 (approx; actual computed from weapon geometry), r=1.11, band_max=14.0 → KE≈82J at committed with inertia_scale=0.80 (heavy head swings slower); stab_band_max=12.0 → thrust KE≈144J
## MACE:  I≈0.50 (approx; actual computed from weapon geometry), r=0.63, band_max=14.0 → KE≈123J at committed (heavy weapon; peak combat velocities ~8-14 m/s per Lehmann HEMA studies); stab_band_max=10.0 → thrust KE≈125J
## DAGGER: I≈0.013 (blade 20cm×0.55 + handle 12cm×0.45 at mass=0.45 kg), r=0.29, band_max=10.0 → KE≈7-18J at committed (hand-speed limited)
## SPEAR: shaft mass dominates. Swing tip speeds (cut/blunt) capped ~12 m/s by physics; THRUST tip
## speed is far lower (5-8.0 m/s — a linear push, not a lever arc), so thrust KE (½·3.5kg·v² with body
## transfer) lands in the 40-130 J band at full commitment (audit band Vector2(40,130)). Swing uses full rotational inertia (~3.05 kg·m² after parts);
## thrust uses ~3.5 kg body-transfer effective mass (braced linear thrust: 3-6 kg torso/shoulder drive).
static var _default_bands: Dictionary = {
    "SWORD": {"stab": Vector2(5.5, 13.0), "cut": Vector2(7.5, 16.0), "blunt": Vector2(6.0, 14.0)},
    "AXE": {"stab": Vector2(3.5, 12.0), "cut": Vector2(5.0, 14.0), "blunt": Vector2(5.0, 14.0)},
    "MACE": {"stab": Vector2(5.5, 10.0), "cut": Vector2(6.5, 14.0), "blunt": Vector2(6.5, 15.0)},
    "DAGGER": {"stab": Vector2(4.0, 10.0), "cut": Vector2(5.5, 10.0), "blunt": Vector2(4.0, 10.0)},
    "SPEAR": {"stab": Vector2(5.0, 8.0), "cut": Vector2(4.0, 12.0), "blunt": Vector2(3.5, 12.0)}
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
        if mn > 0.0 and mx > mn:
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


## Mass scaling factor for band max: sqrt(m_ref/m) clamped to [MASS_SCALING_MIN_FACTOR, MASS_SCALING_MAX_FACTOR].
## Heavier-than-reference weapons swing slower (factor < 1); lighter ones faster (factor > 1). A weapon with
## no usable mass falls back to 1.0 (no scaling). See MASS_SCALING_REFERENCE_KG for the physical basis.
static func mass_scaling_factor(weapon: RefCounted) -> float:
    if weapon == null or not (weapon is Object):
        return 1.0
    var raw_mass: Variant = (weapon as Object).get("mass")
    if not (raw_mass is float or raw_mass is int):
        return 1.0
    var m: float = float(raw_mass)
    if m <= 0.01:
        return 1.0
    var factor: float = sqrt(MASS_SCALING_REFERENCE_KG / m)
    return clampf(factor, MASS_SCALING_MIN_FACTOR, MASS_SCALING_MAX_FACTOR)


## Resolved (min,max) impact speed (m/s) for this weapon and contact stream.
## Bands are calibrated at _REFERENCE_STRIKE_RADIUS_M; geometry scaling is NOT applied here because
## the rotational KE path already converts band velocity -> omega via r, and the band values account
## for the reference radius. Applying geometry would double-count the lever advantage. Band MAX is scaled
## by weapon mass (see mass_scaling_factor); band MIN is reaction-limited and left unscaled.
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
    ## Tier C overrides are authored per-weapon and already reflect that weapon's mass — do not re-scale.
    var m_scale: float = 1.0 if (c_band.x >= 0.0 and c_band.y > c_band.x) else mass_scaling_factor(weapon)
    return Vector2(
        clampf(vmin, ABS_VELOCITY_MIN_M_S, ABS_VELOCITY_MAX_M_S),
        clampf(vmax * m_scale, vmin + 0.55, ABS_VELOCITY_MAX_M_S)
    )
