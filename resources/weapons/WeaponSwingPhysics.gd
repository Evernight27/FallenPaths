class_name WeaponSwingPhysics
extends RefCounted

## Discrete rigid-body swing model: parts[] ordered **tip → grip** (index 0 furthest from hands).
## Inertia about grip: inertia_kg_m2 = Σ m_i d_i². Strike lever r = max(grip→striking COM, ImpactVelocityModel
## strike radius)
## so ω = v_band / r stays aligned with band calibration. WeaponDamageHelper uses full rotational inertia for KE.
const MIN_LEVER_M := 0.12
const MIN_INERTIA_KG_M2 := 0.001


static func _total_length_m_from_parts(parts: Array) -> float:
    var s: float = 0.0
    for p in parts:
        if p is Dictionary:
            s += maxf(0.0, p.get("length_cm", 0.0)) / 100.0
    return maxf(s, 0.05)


## Distance from grip to part COM (m). `parts` tip→grip; `part_index` indexes into `parts`.
static func com_distance_from_grip_m(parts: Array, part_index: int) -> float:
    if part_index < 0 or part_index >= parts.size():
        return MIN_LEVER_M
    var total_length_m: float = _total_length_m_from_parts(parts)
    var cum_from_tip: float = 0.0
    for i in range(parts.size()):
        if not parts[i] is Dictionary:
            continue
        var segment_momentum: float = maxf(0.0, parts[i].get("length_cm", 0.0)) / 100.0
        if i == part_index:
            var com_from_tip: float = cum_from_tip + segment_momentum * 0.5
            return maxf(MIN_LEVER_M, total_length_m - com_from_tip)
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


## Lever arm (m): max(grip→striking-part COM, ImpactVelocityModel strike radius) so ω = v/r matches band tuning.
static func strike_lever_arm_m(weapon: Object, contact_type: String) -> float:
    var r_geom: float = maxf(MIN_LEVER_M, ImpactVelocityModel.strike_radius_m(weapon, contact_type))
    if weapon == null or not weapon.has_method("has_parts") or not weapon.has_parts():
        return r_geom
    var idx: int = _striking_part_index(weapon, contact_type)
    if idx < 0:
        return r_geom
    var r_com: float = maxf(MIN_LEVER_M, com_distance_from_grip_m(weapon.parts, idx))
    return maxf(r_com, r_geom)


## Moment of inertia about grip (kg·m²), point-mass segments at each part's COM.
static func inertia_about_grip_kg_m2(weapon: Object) -> float:
    if weapon == null:
        return MIN_INERTIA_KG_M2
    var total_mass: float = WeaponConstants.weapon_mass_kg(weapon)
    if not weapon.has_method("has_parts") or not weapon.has_parts():
        var l_total: float = (
            float(weapon.melee_range)
            if (weapon.get("melee_range") is float or weapon.get("melee_range") is int)
            else 1.2
        )
        ## Effective lever arm for inertia: I = m·r_eff² where r_eff captures mass concentration toward grip.
        ## Combined shortened lever and mass profile into single 0.35 factor (merged from old eff_radius*0.48 × 0.25
        ## correction).
        var eff_radius: float = l_total * WeaponConstants.INERTIA_EFF_RADIUS_FRACTION
        return maxf(MIN_INERTIA_KG_M2, total_mass * eff_radius * eff_radius)
    var parts: Array = weapon.parts
    if parts.is_empty():
        var l_default: float = 1.2
        if weapon != null and weapon.has_method("get"):
            var mr: Variant = weapon.get("melee_range")
            if mr is float or mr is int:
                l_default = float(mr)
        var eff_radius: float = l_default * WeaponConstants.INERTIA_EFF_RADIUS_FRACTION
        return maxf(MIN_INERTIA_KG_M2, total_mass * eff_radius * eff_radius)
    ## Uniform-rod segments via parallel-axis theorem (see inertia_from_parts_kg_m2); the per-weapon
    ## strike_physics.inertia_scale remains as a calibration trim on top of the physically-derived base.
    var inertia_kg_m2: float = inertia_from_parts_kg_m2(parts, total_mass)
    if weapon is Object and weapon.has_method("get"):
        var sp: Variant = weapon.get("strike_physics")
        if sp is Dictionary and sp.has("inertia_scale"):
            inertia_kg_m2 *= float(sp.inertia_scale)
    return maxf(MIN_INERTIA_KG_M2, inertia_kg_m2)


## Inertia about grip for a parts array (kg·m²): each segment is a uniform rod, I = m·d² + (1/12)mL²,
## where d is the grip→segment-COM distance and L the segment length. The (1/12)mL² term is the
## distributed-mass correction a point mass at the COM misses (~33% for long thin segments).
static func inertia_from_parts_kg_m2(parts: Array, total_mass: float) -> float:
    var inertia_kg_m2: float = 0.0
    for i in range(parts.size()):
        if not parts[i] is Dictionary:
            continue
        var frac: float = clampf(parts[i].get("mass_fraction", 1.0), 0.0, 1.0)
        var m_i: float = maxf(0.0, total_mass * frac)
        var d: float = com_distance_from_grip_m(parts, i)
        var seg_m: float = maxf(0.0, parts[i].get("length_cm", 0.0)) / 100.0
        inertia_kg_m2 += m_i * d * d + (m_i * seg_m * seg_m) / 12.0
    return maxf(MIN_INERTIA_KG_M2, inertia_kg_m2)


## Rotational kinetic energy at angular velocity ω (rad/s).
static func rotational_ke_j(inertia_kg_m2: float, omega_rad_s: float) -> float:
    return 0.5 * maxf(MIN_INERTIA_KG_M2, inertia_kg_m2) * omega_rad_s * omega_rad_s
