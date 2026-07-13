class_name WeaponSwingPhysics
extends RefCounted

## Discrete rigid-body swing model: parts[] ordered **tip â grip** (index 0 furthest from hands).
## Inertia about grip: inertia_kg_m2 = Î£ m_i d_iÂ². Strike lever r = max(gripâstriking COM, ImpactVelocityModel
## strike radius)
## so Ï = v_band / r stays aligned with band calibration. WeaponDamageHelper caps KE inertia to m_strike rÂ².

const MIN_LEVER_M := 0.12
const MIN_INERTIA_KG_M2 := 0.001


static func _total_length_m_from_parts(parts: Array) -> float:
    var s: float = 0.0
    for p in parts:
        if p is Dictionary:
            s += maxf(0.0, p.get("length_cm", 0.0)) / 100.0
    return maxf(s, 0.05)


## Distance from grip to part COM (m). `parts` tipâgrip; `part_index` indexes into `parts`.
static func com_distance_from_grip_m(parts: Array, part_index: int) -> float:
    if part_index < 0 or part_index >= parts.size():
        return MIN_LEVER_M
    var total_momentum: float = _total_length_m_from_parts(parts)
    var cum_from_tip: float = 0.0
    for i in range(parts.size()):
        if not parts[i] is Dictionary:
            continue
        var segment_momentum: float = maxf(0.0, parts[i].get("length_cm", 0.0)) / 100.0
        if i == part_index:
            var com_from_tip: float = cum_from_tip + segment_momentum * 0.5
            return maxf(MIN_LEVER_M, total_momentum - com_from_tip)
        cum_from_tip += segment_momentum
    return MIN_LEVER_M


static func _striking_part_index(weapon: Object, contact_type: String) -> int:
    if weapon == null or not weapon.has_method("has_parts") or not weapon.has_parts():
        return -1
    var parts: Array = weapon.parts
    var ct: String = contact_type.to_lower() if contact_type else WeaponConstants.ATTACK_TYPE_CUT
    for i in range(parts.size()):
        if not parts[i] is Dictionary:
            continue
        var sf: Variant = parts[i].get("striking_for", [])
        if sf is Array and ct in sf:
            return i
    match ct:
        WeaponConstants.ATTACK_TYPE_STAB:
            for i in range(parts.size()):
                if not parts[i] is Dictionary:
                    continue
                var pid: String = parts[i].get("id", "")
                if pid in ["point", "blade", "spike", "head"]:
                    return i
        WeaponConstants.ATTACK_TYPE_CUT:
            for i in range(parts.size()):
                if not parts[i] is Dictionary:
                    continue
                if parts[i].get("id", "") == "blade":
                    return i
        WeaponConstants.ATTACK_TYPE_BLUNT:
            for i in range(parts.size()):
                if not parts[i] is Dictionary:
                    continue
                var pid2: String = parts[i].get("id", "")
                if pid2 in ["head", "haft"]:
                    return i
    return 0 if parts.size() > 0 else -1


## Lever arm (m): max(gripâstriking-part COM, ImpactVelocityModel strike radius) so Ï = v/r matches band tuning.
static func strike_lever_arm_m(weapon: Object, contact_type: String) -> float:
    var r_geom: float = maxf(MIN_LEVER_M, ImpactVelocityModel.strike_radius_m(weapon, contact_type))
    if weapon == null or not weapon.has_method("has_parts") or not weapon.has_parts():
        return r_geom
    var idx: int = _striking_part_index(weapon, contact_type)
    if idx < 0:
        return r_geom
    var r_com: float = maxf(MIN_LEVER_M, com_distance_from_grip_m(weapon.parts, idx))
    return maxf(r_com, r_geom)


## Moment of inertia about grip (kg·mÂ²), point-mass segments at each part's COM.
static func inertia_about_grip_kg_m2(weapon: Object) -> float:
    if weapon == null:
        return MIN_INERTIA_KG_M2
    var total_mass: float = WeaponConstants.weapon_mass_kg(weapon)
    if not weapon.has_method("has_parts") or not weapon.has_parts():
        var ang_momentum: float = (
            float(weapon.melee_range)
            if (weapon.get("melee_range") is float or weapon.get("melee_range") is int)
            else 1.5
        )
        ang_momentum = clampf(ang_momentum * 0.75, 0.35, 1.4)
        return maxf(MIN_INERTIA_KG_M2, total_mass * ang_momentum * ang_momentum / 3.0)
    var parts: Array = weapon.parts
    if parts.is_empty():
        return maxf(MIN_INERTIA_KG_M2, total_mass * 0.5 * 0.5 / 3.0)
    var inertia_kg_m2: float = 0.0
    for i in range(parts.size()):
        if not parts[i] is Dictionary:
            continue
        var frac: float = clampf(parts[i].get("mass_fraction", 1.0), 0.0, 1.0)
        var m_i: float = maxf(0.0, total_mass * frac)
        var d: float = com_distance_from_grip_m(parts, i)
        inertia_kg_m2 += m_i * d * d
    return maxf(MIN_INERTIA_KG_M2, inertia_kg_m2)


## Rotational kinetic energy at angular velocity Ï (rad/s).
static func rotational_ke_j(inertia_kg_m2: float, omega_rad_s: float) -> float:
    return 0.5 * maxf(MIN_INERTIA_KG_M2, inertia_kg_m2) * omega_rad_s * omega_rad_s


## Ï from tip speed v (m/s) and lever r (m).
static func omega_from_tip_speed(v_m_s: float, lever_m: float) -> float:
    var r: float = maxf(MIN_LEVER_M, lever_m)
    return v_m_s / r


## Effective mass (kg) so Â½ m_eff vÂ² = Â½ inertia_kg_m2 ÏÂ² with v = Ï r â m_eff = inertia_kg_m2 / rÂ².
static func effective_rotational_mass_kg(weapon: Object, contact_type: String) -> float:
    var inertia_kg_m2: float = inertia_about_grip_kg_m2(weapon)
    var r: float = strike_lever_arm_m(weapon, contact_type)
    var r2: float = r * r
    if r2 <= 1e-6:
        return maxf(0.02, float(weapon.mass) * 0.5) if weapon != null else 0.35
    return maxf(0.02, inertia_kg_m2 / r2)
