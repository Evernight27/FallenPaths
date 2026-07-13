class_name WeaponDamageHelper
extends RefCounted

const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
const _SpeciesResource := preload("res://species/SpeciesResource.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")
const _SwingPhysics := preload("res://weapon/WeaponSwingPhysics.gd")
## Physics-leaning intensity mapping: low commitment stays near lower band, full commitment still reaches cap.
const INTENSITY_VELOCITY_FLOOR_FACTOR := 0.2
## Floor for effective delivery intensity (intensity - -  extension commit).
const DELIVERY_INTENSITY_FLOOR := 0.05
const DELIVERY_COMMIT_FLOOR := 0.05
## Rotational KE uses min(full I, m_strike rÂ²); latter matches Â½ m_strike vÂ² for rigid v = Ï r (point-mass ceiling).
const INERTIA_KE_STRIKE_CAP_MULT := 1.0

## Default effective target mass (kg) when no species / unknown part (mid-torso order of magnitude).
const DEFAULT_BLUNT_TARGET_MASS_KG := 14.0
## Human default tissue sum (human.tres); used only to scale inferred body mass from other species.
const _REFERENCE_SPECIES_TISSUE_SUM := float(_DesignAnchors.REFERENCE_HUMAN_TISSUE_SUM)
## Reference adult mass (kg) when tissue sum matches _REFERENCE_SPECIES_TISSUE_SUM.
const _REFERENCE_ADULT_BODY_MASS_KG := _DesignAnchors.REFERENCE_ADULT_MASS_KG
## Segment mass as fraction of body mass (Plagenhoef / de Leva style; single-side limb, head, trunk slice).
const _PART_BODY_MASS_FRACTION := {
    "head": 0.068,
    "chest": 0.28,
    "right_arm": 0.052,
    "left_arm": 0.052,
    "right_leg": 0.161,
    "left_leg": 0.161,
}
## Fist/hand effective mass - -  nominal hand speed - -  coupling â same abstract scale as previous (strength/100)*8 at ~100 STR.
const UNARMED_FIST_EFFECTIVE_MASS_KG := 0.55
const UNARMED_TYPICAL_HAND_SPEED_M_S := 7.0
const UNARMED_MOMENTUM_TO_PREARMOR := 2.10

# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# Impact speed: Tier A defaults + Tier B geometry + Tier C weapon.impact_velocity_bands; see ImpactVelocityModel.gd.


## Two-body collision: effective mass for linear momentum when target presents finite inertia (blunt).
static func reduced_mass_pair_kg(m_weapon: float, m_target: float) -> float:
    var mw: float = maxf(0.02, m_weapon)
    var mt: float = maxf(0.05, m_target)
    return (mw * mt) / (mw + mt)


static func _exported_tissue_sum_duck_typed(sp: Object) -> float:
    var s: float = 0.0
    for key in _SpeciesResource.BODY_PARTS:
        var v: Variant = sp.get(key)
        if v is int or v is float:
            s += float(v)
    return maxf(1.0, s)


static func reference_body_mass_kg_from_species(sp: Object) -> float:
    if sp == null:
        return _REFERENCE_ADULT_BODY_MASS_KG
    if sp is SpeciesResource:
        return clampf((sp as SpeciesResource).resolved_reference_mass_kg(), 32.0, 120.0)
    var custom: Variant = sp.get("reference_body_mass_kg")
    if custom is float or custom is int:
        var cm: float = float(custom)
        if cm > 0.0:
            return clampf(cm, 28.0, 140.0)
    var sum_t: float = _exported_tissue_sum_duck_typed(sp)
    return clampf(_REFERENCE_ADULT_BODY_MASS_KG * sum_t / maxf(1.0, _REFERENCE_SPECIES_TISSUE_SUM), 32.0, 120.0)


## Unarmed pre-armor at full stance mod 1.0: ~ (STR/100)*8 in historical calibration units; derived from fist effective mass - -  hand speed.
static func unarmed_base_pre_armor(strength: float, mod: float) -> float:
    var st: float = maxf(0.1, float(strength) / 100.0)
    return st * mod * UNARMED_FIST_EFFECTIVE_MASS_KG * UNARMED_TYPICAL_HAND_SPEED_M_S * UNARMED_MOMENTUM_TO_PREARMOR


## Target-side effective mass for two-body blunt momentum (species or node hook).
static func effective_blunt_target_mass_kg(tgt: Dictionary, part: String = "") -> float:
    var n: Node = _EntityAccess.scene_node(tgt)
    if n != null and n.has_method("get_effective_blunt_target_mass_kg"):
        return maxf(1.0, float(n.get_effective_blunt_target_mass_kg(part)))
    if n != null and "species" in n:
        var sp: Variant = n.get("species")
        if sp != null:
            var em: Variant = sp.get("effective_blunt_target_mass_kg")
            if em is float or em is int:
                var emf: float = float(em)
                if emf > 0.0:
                    return maxf(1.0, emf)
            var m_body: float = reference_body_mass_kg_from_species(sp as Object)
            var p: String = part if not part.is_empty() else "chest"
            var frac: float = _PART_BODY_MASS_FRACTION.get(p, 0.19)
            return maxf(1.0, m_body * frac)
    return DEFAULT_BLUNT_TARGET_MASS_KG


static func move_id_from_attack_instance(attack_instance: RefCounted) -> String:
    var v: Variant = attack_instance.get("attack_type")
    return str(v) if v is String else ""


## Extension commit scales swing commitment for KE/cut: effective_i = intensity - -  commit (each clamped).
## commit_frac < 0 â no extra scaling (treat commit as 1.0).
static func effective_intensity_for_delivery(intensity: float, commit_frac: float = -1.0) -> float:
    var c: float = 1.0
    if commit_frac >= 0.0:
        c = clampf(commit_frac, DELIVERY_COMMIT_FLOOR, 1.0)
    var eff: float = clampf(intensity, 0.0, 1.0) * c
    return clampf(eff, DELIVERY_INTENSITY_FLOOR, 1.0)


static func _delivery_commit_from_attack_instance(attack_instance: RefCounted) -> float:
    if attack_instance == null:
        return -1.0
    var v: Variant = attack_instance.get("delivery_commit_fraction")
    if v is float or v is int:
        var cf: float = float(v)
        if cf >= 0.0:
            return cf
    var arch: Variant = attack_instance.get("archetype")
    if arch is Dictionary and arch.has("weapon_extension_commit_fraction"):
        var ac: float = float(arch["weapon_extension_commit_fraction"])
        if ac >= 0.0:
            return ac
    return -1.0


static func _attack_float_or_default(attack_instance: RefCounted, prop: String, default_val: float) -> float:
    if attack_instance == null:
        return default_val
    var v: Variant = attack_instance.get(prop)
    if v is float or v is int:
        return float(v)
    return default_val


## Mass (kg) participating in impact speed for KE / momentum (striking part when known; aligns with parry p_a).
static func strike_mass_kg(weapon: RefCounted, attack_instance: RefCounted) -> float:
    if weapon == null:
        return 0.35
    var move_id: String = move_id_from_attack_instance(attack_instance)
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    if weapon.has_method("get_striking_part_mass_kg"):
        return maxf(0.02, float(weapon.get_striking_part_mass_kg(ct)))
    return WeaponConstants.weapon_mass_kg(weapon)


## Thrust / swing / mixed from archetype; if missing, infer from move contact (stab â thrust).
static func kinematic_delivery(archetype: Dictionary, move_id: String) -> String:
    var arch: Dictionary = archetype if archetype is Dictionary else {}
    var raw: Variant = arch.get("kinematic_delivery", "")
    if raw is String:
        var s: String = str(raw).strip_edges().to_lower()
        if (
            s == WeaponConstants.KINEMATIC_DELIVERY_THRUST
            or s == WeaponConstants.KINEMATIC_DELIVERY_SWING
            or s == WeaponConstants.KINEMATIC_DELIVERY_MIXED
        ):
            return s
    var ct0: String = WeaponConstants.contact_type_for_move_id(move_id)
    if ct0 == WeaponConstants.ATTACK_TYPE_STAB:
        return WeaponConstants.KINEMATIC_DELIVERY_THRUST
    return WeaponConstants.KINEMATIC_DELIVERY_SWING


static func _velocity_intensity_g(intensity: float, archetype: Dictionary) -> float:
    var int0: float = clampf(intensity, 0.0, 1.0)
    var curve: float = 1.0
    if archetype is Dictionary and archetype.has("velocity_intensity_curve"):
        curve = clampf(float(archetype.velocity_intensity_curve), 0.55, 1.5)
    var intensity_val: float = pow(int0, curve)
    var factor: float = INTENSITY_VELOCITY_FLOOR_FACTOR + (1.0 - INTENSITY_VELOCITY_FLOOR_FACTOR) * intensity_val
    if archetype is Dictionary and archetype.has("velocity_factor"):
        var vf: float = float(archetype.velocity_factor)
        factor *= clampf(vf, 0.1, 1.5)
    return clampf(factor, 0.0, 1.0)


static func _velocity_linear_from_g(weapon: RefCounted, move_id: String, g: float) -> float:
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    var band: Vector2 = _ImpactVelocityModel.resolve_band_m_s(weapon, ct)
    return band.x + (band.y - band.x) * g


static func _velocity_swing_from_g(weapon: RefCounted, move_id: String, g: float) -> float:
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    var band: Vector2 = _ImpactVelocityModel.resolve_band_m_s(weapon, ct)
    if weapon != null and weapon.has_method("has_parts") and weapon.has_parts():
        var r: float = _SwingPhysics.strike_lever_arm_m(weapon, ct)
        var w_min: float = band.x / r
        var w_max: float = band.y / r
        var omega: float = w_min + (w_max - w_min) * g
        return _ImpactVelocityModel.clamp_velocity_m_s(omega * r)
    return _velocity_linear_from_g(weapon, move_id, g)


# Single place for intensity -> m/s. Thrust: linear band. Swing: Ï - lever. Mixed: kinematic_mixed_blend.
static func velocity_m_s_from_intensity(
    intensity: float, archetype: Dictionary, weapon: RefCounted = null, move_id: String = ""
) -> float:
    var arch: Dictionary = archetype if archetype is Dictionary else {}
    var g: float = _velocity_intensity_g(intensity, arch)
    var delivery: String = kinematic_delivery(arch, move_id)
    match delivery:
        WeaponConstants.KINEMATIC_DELIVERY_THRUST:
            return _velocity_linear_from_g(weapon, move_id, g)
        WeaponConstants.KINEMATIC_DELIVERY_SWING:
            return _velocity_swing_from_g(weapon, move_id, g)
        WeaponConstants.KINEMATIC_DELIVERY_MIXED:
            var b: float = 0.5
            if arch.has("kinematic_mixed_blend"):
                var bm: Variant = arch.get("kinematic_mixed_blend")
                if bm is float or bm is int:
                    b = clampf(float(bm), 0.0, 1.0)
            return lerpf(_velocity_linear_from_g(weapon, move_id, g), _velocity_swing_from_g(weapon, move_id, g), b)
        _:
            return _velocity_swing_from_g(weapon, move_id, g)


# Effective impact velocity (m/s). Prefer attack.velocity_m_s if set (e.g. after partial parry); else derive from intensity.
# use_delivery_commit: when false, blunt momentum paths keep full intensity (commit does not reduce slip).
static func get_effective_velocity_m_s(
    weapon: RefCounted, attack_instance: RefCounted, use_delivery_commit: bool = true
) -> float:
    var v = attack_instance.get("velocity_m_s")
    if v is float and v >= 0.0:
        return v
    var i = attack_instance.get("intensity")
    var base_i: float = i if i is float else 0.5
    var commit: float = _delivery_commit_from_attack_instance(attack_instance) if use_delivery_commit else -1.0
    var eff_i: float = effective_intensity_for_delivery(base_i, commit)
    var arch = attack_instance.get("archetype")
    var move_id: String = move_id_from_attack_instance(attack_instance)
    return velocity_m_s_from_intensity(eff_i, arch if arch is Dictionary else {}, weapon, move_id)


static func _ke_thrust_point_mass(weapon: RefCounted, attack_instance: RefCounted, v: float, e_mult: float) -> float:
    var m_strike: float = strike_mass_kg(weapon, attack_instance)
    return 0.5 * m_strike * v * v * maxf(0.05, e_mult)


static func _ke_swing_rotational(weapon: RefCounted, attack_instance: RefCounted, v: float, e_mult: float) -> float:
    var move_id: String = move_id_from_attack_instance(attack_instance)
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    if weapon.has_method("has_parts") and weapon.has_parts():
        var I_full: float = _SwingPhysics.inertia_about_grip_kg_m2(weapon)
        var m_strike: float = strike_mass_kg(weapon, attack_instance)
        var r: float = _SwingPhysics.strike_lever_arm_m(weapon, ct)
        var I_cap: float = maxf(_SwingPhysics.MIN_INERTIA_KG_M2, m_strike * r * r * INERTIA_KE_STRIKE_CAP_MULT)
        var I_use: float = minf(I_full, I_cap)
        var omega: float = _SwingPhysics.omega_from_tip_speed(v, r)
        return _SwingPhysics.rotational_ke_j(I_use, omega) * maxf(0.05, e_mult)
    return _ke_thrust_point_mass(weapon, attack_instance, v, e_mult)


# Kinetic energy (J): thrust â Â½ m_strike vÂ²; swing â Â½ I ÏÂ² (capped I); mixed â blend. Unarmed/no parts uses thrust path on swing fallback.
static func compute_kinetic_energy_j(weapon: RefCounted, attack_instance: RefCounted) -> float:
    if weapon == null:
        return 0.0
    var v: float = get_effective_velocity_m_s(weapon, attack_instance)
    var e_mult: float = _attack_float_or_default(attack_instance, "strike_energy_mult", 1.0)
    var move_id: String = move_id_from_attack_instance(attack_instance)
    var arch: Dictionary = attack_instance.get("archetype") if attack_instance.get("archetype") is Dictionary else {}
    var delivery: String = kinematic_delivery(arch, move_id)
    match delivery:
        WeaponConstants.KINEMATIC_DELIVERY_THRUST:
            return _ke_thrust_point_mass(weapon, attack_instance, v, e_mult)
        WeaponConstants.KINEMATIC_DELIVERY_SWING:
            return _ke_swing_rotational(weapon, attack_instance, v, e_mult)
        WeaponConstants.KINEMATIC_DELIVERY_MIXED:
            var b: float = 0.5
            if arch.has("kinematic_mixed_blend"):
                var bm: Variant = arch.get("kinematic_mixed_blend")
                if bm is float or bm is int:
                    b = clampf(float(bm), 0.0, 1.0)
            return lerpf(
                _ke_thrust_point_mass(weapon, attack_instance, v, e_mult),
                _ke_swing_rotational(weapon, attack_instance, v, e_mult),
                b
            )
        _:
            return _ke_swing_rotational(weapon, attack_instance, v, e_mult)


# Pre-armor CUT (sharp) from KE and effective edge: scale * sqrt(KE) * strength_mod * arm_mod * contact_factor(effective sharp), clamped.
static func compute_pre_armor_cut(
    weapon: RefCounted, attack_instance: RefCounted, strength: float, arm_mod: float
) -> float:
    var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
    var strength_mod: float = maxf(0.1, float(strength) / 100.0)
    var raw: float = WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, ke_j)) * strength_mod * arm_mod
    var at: String = attack_instance.get("attack_type")
    if at == null or not (at is String):
        at = WeaponConstants.ATTACK_TYPE_CUT
    var contact_cm: float = _get_effective_sharp_contact_cm(weapon, at)
    contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
    var contact_factor: float = pow(
        WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT
    )
    contact_factor = minf(contact_factor, WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX)
    raw *= contact_factor
    return clampf(raw, WeaponConstants.DAMAGE_KE_MIN, WeaponConstants.DAMAGE_KE_MAX)


# Pre-armor BLUNT from momentum: scale * (mass * velocity) * strength_mod * arm_mod * contact_factor (unclamped).
# Uses blunt contact (head_diameter for blunt, max(blade, BLUNT_CUT_MIN) for cut slap, point for thrust).
# target_effective_mass_kg: when > 0, use reduced mass with strike mass for more realistic impulse coupling.
static func compute_pre_armor_blunt_momentum_raw(
    weapon: RefCounted,
    attack_instance: RefCounted,
    strength: float,
    arm_mod: float,
    target_effective_mass_kg: float = -1.0
) -> float:
    if weapon == null:
        return 0.0
    var mass_kg: float = strike_mass_kg(weapon, attack_instance)
    if target_effective_mass_kg > 0.0:
        mass_kg = reduced_mass_pair_kg(mass_kg, target_effective_mass_kg)
    var v: float = get_effective_velocity_m_s(weapon, attack_instance, false)
    var p_mult: float = _attack_float_or_default(attack_instance, "strike_momentum_mult", 1.0)
    var momentum: float = mass_kg * v * maxf(0.05, p_mult)
    var strength_mod: float = maxf(0.1, float(strength) / 100.0)
    var raw: float = WeaponConstants.DAMAGE_MOMENTUM_SCALE * momentum * strength_mod * arm_mod
    var contact_cm: float = _get_blunt_contact_for_damage(weapon, attack_instance)
    contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
    var contact_factor: float = pow(
        WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT
    )
    contact_factor = minf(contact_factor, WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX)
    return raw * contact_factor


## Cut-induced blunt slip: momentum raw - -  **`(1 - cut_ratio)`** - -  optional **`blunt_damage_mult`**, max-only clamp (no **`BLUNT_DAMAGE_MIN`**  -  see **`AttackResolver.compute_and_apply_damage`**).
static func compute_blunt_slip_pre_armor(
    weapon: RefCounted,
    attack_instance: RefCounted,
    strength: float,
    arm_mod: float,
    cut_ratio: float,
    target_effective_mass_kg: float = -1.0,
    blunt_damage_mult: float = 1.0
) -> float:
    var slip_raw: float = (
        compute_pre_armor_blunt_momentum_raw(weapon, attack_instance, strength, arm_mod, target_effective_mass_kg)
        * (1.0 - clampf(cut_ratio, 0.0, 1.0))
        * maxf(0.0, blunt_damage_mult)
    )
    return clampf(slip_raw, 0.0, WeaponConstants.BLUNT_DAMAGE_MAX)


## Clamped pre-armor blunt (full weapon swing / pure blunt). Cut weapons use **`compute_blunt_slip_pre_armor`** in **`AttackResolver`** so **`strike_momentum_mult`** is not erased by **`BLUNT_DAMAGE_MIN`** before the slip split.
static func compute_pre_armor_blunt(
    weapon: RefCounted,
    attack_instance: RefCounted,
    strength: float,
    arm_mod: float,
    target_effective_mass_kg: float = -1.0
) -> float:
    var raw: float = compute_pre_armor_blunt_momentum_raw(
        weapon, attack_instance, strength, arm_mod, target_effective_mass_kg
    )
    return clampf(raw, WeaponConstants.BLUNT_DAMAGE_MIN, WeaponConstants.BLUNT_DAMAGE_MAX)


# Penetration: sharp (mm RHA from contact area); blunt uses momentum_per_area for cushion.
# SHARP returns { penetration_sharp }. BLUNT returns { penetration_blunt_momentum_per_area, blunt_contact_cm }.
# opts: optional { "armor_resistance_rha_mm": float, "pen_sharp_mm": float }  -  when both provided for thrusts, use energy-based contact.
static func compute_penetration(
    weapon: RefCounted, attack_instance: RefCounted, damage_type: String, opts: Dictionary = {}
) -> Dictionary:
    var armor_resistance_rha_mm: float = opts.get("armor_resistance_rha_mm", -1.0) if opts is Dictionary else -1.0
    var pen_sharp_mm: float = opts.get("pen_sharp_mm", -1.0) if opts is Dictionary else -1.0
    var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
    var attack_type: String = attack_instance.get("attack_type")
    if attack_type == null or not (attack_type is String):
        attack_type = WeaponConstants.ATTACK_TYPE_CUT

    if damage_type == WeaponConstants.DAMAGE_TYPE_SHARP:
        # Sharp: Williams nonlinear  -  pen = (KE/J_BASE)^exp * area_factor. E â t^1.67 â pen â KE^0.6.
        var contact_cm: float = _get_effective_sharp_contact_cm(weapon, attack_type)
        contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
        var area_factor: float = pow(
            WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_AREA_EXPONENT
        )
        var pen_mm_rha: float = (
            pow(ke_j / WeaponConstants.J_PER_MM_BASE, WeaponConstants.PENETRATION_EXPONENT) * area_factor
        )
        pen_mm_rha = minf(pen_mm_rha, WeaponConstants.PENETRATION_KE_CAP_MM_RHA)
        return {"penetration_sharp": pen_mm_rha}
    else:
        # Blunt: transmission-only. Returns momentum_per_area and contact_cm for area coupling.
        var contact_cm: float = _get_blunt_contact_for_penetration(
            weapon, attack_instance, armor_resistance_rha_mm, pen_sharp_mm
        )
        var tgt_m: float = opts.get("target_effective_mass_kg", -1.0) if opts is Dictionary else -1.0
        var momentum_per_area: float = _compute_blunt_momentum_per_area_with_contact(
            weapon, attack_instance, contact_cm, tgt_m
        )
        return {"penetration_blunt_momentum_per_area": momentum_per_area, "blunt_contact_cm": contact_cm}


# Blunt contact width (cm) for area-dependent transmission. Public for armor coupling.
static func get_blunt_contact_cm(weapon: RefCounted, attack_instance: RefCounted) -> float:
    if weapon == null:
        return -1.0
    var attack_type: String = attack_instance.get("attack_type")
    if attack_type == null or not (attack_type is String):
        attack_type = WeaponConstants.ATTACK_TYPE_CUT
    return _get_blunt_contact_cm(weapon, attack_type)


# Blunt contact for penetration: energy-based when armor_resistance_rha_mm and pen_sharp_mm provided (thrusts).
# depth_factor = clamp(pen/armor, 0, 1); effective = point + (head - point) * depth_factor.
static func _get_blunt_contact_for_penetration(
    weapon: RefCounted, attack_instance: RefCounted, armor_resistance_rha_mm: float = -1.0, pen_sharp_mm: float = -1.0
) -> float:
    var attack_type: String = attack_instance.get("attack_type")
    if attack_type == null or not (attack_type is String):
        attack_type = WeaponConstants.ATTACK_TYPE_CUT
    var contact_pen: String = WeaponConstants.contact_type_for_move_id(attack_type)
    if (
        contact_pen == WeaponConstants.ATTACK_TYPE_STAB
        and armor_resistance_rha_mm >= 0.0
        and pen_sharp_mm >= 0.0
        and weapon != null
    ):
        var pw = weapon.get("point_width")
        var point: float = float(pw) if (pw is float or pw is int) else WeaponConstants.MIN_CONTACT_WIDTH_CM
        if point <= 0.0:
            point = WeaponConstants.MIN_CONTACT_WIDTH_CM
        var hw = weapon.get("thrust_head_width")
        var head: float = float(hw) if (hw is float or hw is int) else point
        if head <= 0.0:
            head = point
        var armor_rha: float = maxf(armor_resistance_rha_mm, 0.1)
        var depth_factor: float = clampf(pen_sharp_mm / armor_rha, 0.0, 1.0)
        return point + (head - point) * depth_factor
    return _get_blunt_contact_cm(weapon, attack_type)


# Blunt cushion: momentum per area (kg·m/s)/mÂ². Used by armor for transmission absorption.
static func compute_blunt_momentum_per_area(weapon: RefCounted, attack_instance: RefCounted) -> float:
    var contact_cm: float = get_blunt_contact_cm(weapon, attack_instance)
    return (
        _compute_blunt_momentum_per_area_with_contact(weapon, attack_instance, contact_cm) if contact_cm > 0 else -1.0
    )


static func _compute_blunt_momentum_per_area_with_contact(
    weapon: RefCounted, attack_instance: RefCounted, contact_cm: float, target_effective_mass_kg: float = -1.0
) -> float:
    if weapon == null or contact_cm <= 0.0:
        return -1.0
    var d_m: float = contact_cm / 100.0 if contact_cm > 0 else 0.01
    var A_m2: float = PI * (d_m / 2.0) * (d_m / 2.0)
    A_m2 = maxf(A_m2, WeaponConstants.MIN_BLUNT_AREA_M2)
    var mass_kg: float = strike_mass_kg(weapon, attack_instance)
    if target_effective_mass_kg > 0.0:
        mass_kg = reduced_mass_pair_kg(mass_kg, target_effective_mass_kg)
    var v: float = get_effective_velocity_m_s(weapon, attack_instance, false)
    var p_mult: float = _attack_float_or_default(attack_instance, "strike_momentum_mult", 1.0)
    var momentum: float = mass_kg * v * maxf(0.05, p_mult)
    return momentum / A_m2 if A_m2 > 0 else 0.0


# Damage type for this attack (SHARP or BLUNT).
static func get_damage_type(weapon: RefCounted, attack_type: String) -> String:
    return weapon.get_damage_type(attack_type)


# Contact width (cm) for attack type; used for area-based penetration and pre-armor damage.
static func _get_contact_width_cm(weapon: RefCounted, attack_type: String) -> float:
    if weapon == null:
        return WeaponConstants.BASELINE_CONTACT_CM
    if weapon is Object and (weapon as Object).has_method("get_contact_width"):
        var ret = (weapon as Object).get_contact_width(attack_type)
        if ret is float or ret is int:
            return float(ret)
    if weapon != null:
        push_warning(
            "[WeaponDamageHelper] Weapon lacks get_contact_width; using BASELINE_CONTACT_CM. Ensure weapon is Weapon instance from create_from_definition."
        )
    return WeaponConstants.BASELINE_CONTACT_CM


# Sharp-component contact (cm): point, blade, or edge/flange. Uses weapon get_sharp_contact_cm (blade_width, point_width, edge_width).
static func _get_sharp_contact_cm(weapon: RefCounted, attack_type: String) -> float:
    if weapon is Object and weapon.has_method("get_sharp_contact_cm"):
        var ret = weapon.get_sharp_contact_cm(attack_type)
        if ret is float or ret is int:
            return maxf(float(ret), WeaponConstants.MIN_CONTACT_WIDTH_CM)
    if weapon != null:
        push_warning(
            "[WeaponDamageHelper] Weapon lacks get_sharp_contact_cm; using fallback. Ensure weapon is Weapon instance."
        )
    return maxf(_get_contact_width_cm(weapon, attack_type), WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Effective sharp contact (cm): geometric sharp contact / sharpness factor. Sharper = smaller = higher penetration.
static func _get_effective_sharp_contact_cm(weapon: RefCounted, attack_type: String) -> float:
    if weapon is Object and weapon.has_method("get_effective_sharp_contact_cm"):
        var ret = weapon.get_effective_sharp_contact_cm(attack_type)
        if ret is float or ret is int:
            return maxf(float(ret), WeaponConstants.MIN_CONTACT_WIDTH_CM)
    return maxf(_get_sharp_contact_cm(weapon, attack_type), WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Blunt-component contact (cm): head, shaft, or slap (cut uses BLUNT_CUT_MIN). Used for blunt damage and penetration.
static func _get_blunt_contact_cm(weapon: RefCounted, attack_type: String) -> float:
    if weapon is Object and weapon.has_method("get_blunt_contact_cm"):
        var ret = weapon.get_blunt_contact_cm(attack_type)
        if ret is float or ret is int:
            return float(ret)
    if weapon != null:
        push_warning(
            "[WeaponDamageHelper] Weapon lacks get_blunt_contact_cm; using fallback. Ensure weapon is Weapon instance from create_from_definition."
        )
    var contact_cm: float = _get_contact_width_cm(weapon, attack_type)
    var contact_fallback: String = WeaponConstants.contact_type_for_move_id(attack_type)
    if contact_fallback == WeaponConstants.ATTACK_TYPE_CUT:
        contact_cm = maxf(contact_cm, WeaponConstants.BLUNT_CUT_MIN_CONTACT_CM)
    return contact_cm


# Blunt contact for damage: archetype override or weapon get_blunt_contact_cm (uses actual blade_width, point_width, head_diameter).
static func _get_blunt_contact_for_damage(weapon: RefCounted, attack_instance: RefCounted) -> float:
    var arch = attack_instance.get("archetype")
    if arch is Dictionary and arch.get("contact_override_cm", -1.0) >= 0.0:
        return float(arch.contact_override_cm)
    var at = attack_instance.get("attack_type")
    if at is String:
        return _get_blunt_contact_cm(weapon, at)
    push_warning("[WeaponDamageHelper] attack_instance missing attack_type; using BASELINE_CONTACT_CM for blunt.")
    return WeaponConstants.BASELINE_CONTACT_CM


# Contact width for damage factor: archetype override or weapon default.
static func _get_contact_width_for_damage(weapon: RefCounted, attack_instance: RefCounted) -> float:
    var arch = attack_instance.get("archetype")
    if arch is Dictionary and arch.get("contact_override_cm", -1.0) >= 0.0:
        return float(arch.contact_override_cm)
    var at = attack_instance.get("attack_type")
    if at is String:
        return _get_contact_width_cm(weapon, at)
    return WeaponConstants.BASELINE_CONTACT_CM


# Cut ratio 0.0 - 1.0 for this move (rest blunt). From archetype or weapon blade_cut_ratio.
# No weapon has 0% cutting: even maces can break skin (flanges/ridges); floor is MIN_CUT_RATIO.
static func get_cut_ratio(weapon: RefCounted, attack_type: String, archetype_dict: Dictionary) -> float:
    var cr: float = 0.75
    if archetype_dict.has("cut_ratio") and float(archetype_dict.cut_ratio) >= 0.0:
        cr = clampf(float(archetype_dict.cut_ratio), 0.0, 1.0)
    elif weapon is Object and weapon.has_method("get_damage_type"):
        if weapon.get_damage_type(attack_type) == WeaponConstants.DAMAGE_TYPE_BLUNT:
            cr = 0.0
        elif "blade_cut_ratio" in weapon:
            cr = clampf(float(weapon.blade_cut_ratio), 0.0, 1.0)
    elif weapon != null and "blade_cut_ratio" in weapon:
        cr = clampf(float(weapon.blade_cut_ratio), 0.0, 1.0)
    return maxf(cr, WeaponConstants.MIN_CUT_RATIO)
