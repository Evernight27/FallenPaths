class_name WeaponDamageHelper
extends RefCounted

## Physics-leaning intensity mapping: low commitment stays near lower band, full commitment still reaches cap.
## Floor 0.50 keeps polearm thrusts above the ~44J thrust KE floor at realistic exchange intensity (i≈0.6).
const INTENSITY_VELOCITY_FLOOR_FACTOR := 0.50
## Floor for effective delivery intensity (intensity - -  extension commit).
const DELIVERY_INTENSITY_FLOOR := 0.05
## R5: Sub-band energy penalty — strikes below band-minimum energy get a smooth damage/KE ramp.
## Replaces the harsh sqrt(ratio) floor (which zeroed out low-energy hits at ratio<0.04).
## Model: full value above SUB_BAND_RAMP_FULL_RATIO; linear ramp down to 25% at SUB_BAND_MINIMUM_RATIO;
## hard cutoff below that so strikes genuinely below band minimum deal no energy. The same factor scales
## BOTH the reported KE and the pre-armor damage (sqrt for cut, linear for blunt momentum) so a weak
## strike can't report low energy while still dealing full tissue deformation.
const SUB_BAND_MINIMUM_RATIO := 0.30    # hard cutoff: below this fraction of band-min KE → 0
const SUB_BAND_RAMP_FULL_RATIO := 1.0   # at/above band-min KE → full energy, no penalty
const SUB_BAND_RAMP_FLOOR := 0.25       # damage/KE fraction at the ramp floor (ratio=0.30)
## NOTE: a separate "sharp-weapon low-KE recovery" bonus was removed. The sharp-point penetration advantage at
## low KE is already modeled by the contact-area factor (compute_pre_armor_cut / compute_penetration): a narrow
## point has a tiny contact area, so pressure = force/area stays high even at sub-band KE. A separate recovery
## term would double-count that effect and over-reward sharp weapons.
## Hard cap for cut ratio on blunt-damage weapons (mace, pollarm). Prevents archetype overrides from giving
## these weapons significant cutting capability — they can nick skin but remain primarily blunt tools.
const CUT_RATIO_BLUNT_WEAPON_MAX := 0.15


## The point-mass cap (m_strike * r²) was double-counting geometry because the velocity bands
## already account for the reference radius; using I_full with omega = v/r gives correct KE.

## Default effective target mass (kg) when no species / unknown part — two-body reduced mass with yielding flesh.
## Biomechanics: rigid weapon vs soft tissue yields ~5-8 kg effective mass (Plagenhofs limb-segment compliance).
## 14 kg was a semi-rigid torso assumption; flesh/muscle deforms, reducing the coupled inertial response.
const DEFAULT_BLUNT_TARGET_MASS_KG := 6.5
## Human default tissue sum (human.tres); used only to scale inferred body mass from other species.
const _REFERENCE_SPECIES_TISSUE_SUM := float(CombatDesignAnchors.REFERENCE_HUMAN_TISSUE_SUM)
## Reference adult mass (kg) when tissue sum matches _REFERENCE_SPECIES_TISSUE_SUM.
const _REFERENCE_ADULT_BODY_MASS_KG := CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
## Segment mass as fraction of body mass (de Leva 1996; single-side full limbs).
## head=6.8%, chest=upper+lower torso lumped, each arm=full limb (humerus+radius/ulna+hand),
## each leg=full limb (femur+tibia/fibula+foot). Fractions sum to ~0.87 leaving 13% for pelvis/spine/etc.
const _PART_BODY_MASS_FRACTION := {
    "head": 0.068,
    "chest": 0.28,
    "right_arm": 0.077,
    "left_arm": 0.077,
    "right_leg": 0.197,
    "left_leg": 0.197,
}
## Fist/hand effective mass - -  nominal hand speed - -  coupling â same abstract scale as previous (strength/100)*8
## at ~100 STR.
const UNARMED_FIST_EFFECTIVE_MASS_KG := 0.55
const UNARMED_TYPICAL_HAND_SPEED_M_S := 7.0
const UNARMED_MOMENTUM_TO_PREARMOR := 2.10

# --- Impact speed: Tier A default tip-speed bands per weapon template + Tier C per-weapon overrides; see ImpactVelocityModel.gd.

## Two-body collision: effective mass for linear momentum when target presents finite inertia (blunt).
static func reduced_mass_pair_kg(m_weapon: float, m_target: float) -> float:
    var mw: float = maxf(0.02, m_weapon)
    var mt: float = maxf(0.05, m_target)
    return (mw * mt) / (mw + mt)


static func _exported_tissue_sum_duck_typed(sp: Object) -> float:
    var s: float = 0.0
    for key in SpeciesResource.BODY_PARTS:
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


## Unarmed pre-armor at full stance mod 1.0: ~ (STR/100)*8 in historical calibration units; derived from fist effective
## mass - -  hand speed.
static func unarmed_base_pre_armor(strength: float, mod: float) -> float:
    var st: float = maxf(0.1, float(strength) / 100.0)
    return st * mod * UNARMED_FIST_EFFECTIVE_MASS_KG * UNARMED_TYPICAL_HAND_SPEED_M_S * UNARMED_MOMENTUM_TO_PREARMOR


## Target-side effective mass for two-body blunt momentum (species or node hook).
static func effective_blunt_target_mass_kg(tgt: Dictionary, part: String = "") -> float:
    var n: Node = CombatantEntityAccess.scene_node(tgt)
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


## Extension commit has no effect on intensity — it is handled in get_effective_velocity_m_s via a
## post-velocity multiplier so that committed strikes can exceed the intensity-derived velocity cap.
## commit_frac < 0 â uncommitted baseline (no extension boost).
static func effective_intensity_for_delivery(intensity: float, _commit_frac: float = -1.0) -> float:
    return clampf(intensity, DELIVERY_INTENSITY_FLOOR, 1.0)


## Velocity multiplier for weapon extension commit — higher commit delivers more follow-through
## energy to impact. Uncommitted (commit < 0) returns 1.0 (no boost). Capped at 1.04 velocity
## (~8% speed, ~16% in KE terms since KE ∝ v²) so committed strikes stay near the bare-speed band.
static func velocity_mult_for_delivery_commit(commit_frac: float) -> float:
    if commit_frac < 0.0:
        return 1.0
    var mult: float = 1.0 + commit_frac * 0.04
    return clampf(mult, 1.0, 1.04)


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
## When weapon has no explicit striking-part mass data, use the weapon's own mass fraction at the striking point.
## The velocity bands encode tip-speed kinematics; the effective mass is the part mass, not a bare-hand value.
static func strike_mass_kg(weapon: RefCounted, attack_instance: RefCounted) -> float:
    ## Swing-mechanics strike-mass coupling (TOPIC 8b): green fighters convert body weight into the hit less
    ## efficiently. `strike_mass_mult` is set on the AttackInstance by the resolver (defaults to 1.0, so bare
    ## fixtures and untracked fighters are unchanged).
    var base_mass: float = _base_strike_mass_kg(weapon, attack_instance)
    var mass_mult: float = _attack_float_or_default(attack_instance, "strike_mass_mult", 1.0)
    return base_mass * maxf(0.5, mass_mult)


static func _base_strike_mass_kg(weapon: RefCounted, attack_instance: RefCounted) -> float:
    ## Move-level override takes priority (e.g. spear shaft_thrust needs higher blunt strike mass).
    var move_id: String = move_id_from_attack_instance(attack_instance)
    if weapon == null:
        return 0.40
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    var raw_mass: Variant = attack_instance.get("strike_mass_override_kg")
    if raw_mass is float or raw_mass is int:
        return maxf(float(raw_mass), 0.02)
    ## Body-coupled thrust mass: a linear thrust drives the point with the whole weapon plus body
    ## transfer behind it. The isolated striking-part mass (spear head ≈0.27 kg) understates thrust KE.
    ## Calibrated for 44-158 J band at i=0→1 (3.5 kg body-transfer; ImpactVelocityModel comment §27-30).
    if ct == WeaponConstants.ATTACK_TYPE_STAB:
        var wt0: String = str(weapon.weapon_type).to_upper() if "weapon_type" in weapon else ""
        match wt0:
            "SPEAR":
                return 3.5
            "MACE":
                return 2.5
            "AXE":
                return 2.0
            "SWORD":
                return 1.5
            ## Dagger armor-piercing thrusts drive the point with arm + shoulder behind the short blade.
            ## Clinical data shows rondel dagger thrusts into soft tissue deliver ~40-70J (Fiore's dente di porco
            ## was designed to pierce plate mail). At v=[3.5,7.5] m/s and m=2.5 kg body-coupled: KE in band.
            "DAGGER":
                return 2.5
            _:
                # No explicit entry for this template: derive from the isolated striking-part mass plus a
                # torso/shoulder drive so unknown thrusting weapons don't fall to the bare point-mass default.
                return _thrust_body_coupled_mass_from_part_kg(weapon, ct)
    if weapon.has_method("get_striking_part_mass_kg"):
        return maxf(0.02, float(weapon.get_striking_part_mass_kg(ct)))
    # Velocity band is tip speed; effective mass is the part mass at contact point.
    # Blunt impacts concentrate more mass (head/haft); edged strikes use blade mass fraction.
    var is_blunt: bool = ct == WeaponConstants.ATTACK_TYPE_BLUNT
    return 0.55 if is_blunt else 0.40


## Body-coupled thrust mass for templates without an explicit entry: isolated striking-part mass × 3
## (torso/shoulder drive), clamped to [0.5, 1.5] kg — a conservative band between a bare-hand stab and the
## lightest body-coupled entry that stays below the explicit per-weapon table values (SWORD 1.5 .. SPEAR 3.5).
static func _thrust_body_coupled_mass_from_part_kg(weapon: RefCounted, ct: String) -> float:
    var part_m: float = (
        maxf(0.02, float(weapon.get_striking_part_mass_kg(ct)))
        if weapon.has_method("get_striking_part_mass_kg")
        else 0.40
    )
    return clampf(part_m * 3.0, 0.5, 1.5)


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
    var band: Vector2 = ImpactVelocityModel.resolve_band_m_s(weapon, ct)
    return band.x + (band.y - band.x) * g


static func _velocity_swing_from_g(weapon: RefCounted, move_id: String, g: float) -> float:
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    var band: Vector2 = ImpactVelocityModel.resolve_band_m_s(weapon, ct)
    if weapon != null and weapon.has_method("has_parts") and weapon.has_parts():
        var r: float = WeaponSwingPhysics.strike_lever_arm_m(weapon, ct)
        var w_min: float = band.x / r
        var w_max: float = band.y / r
        var omega: float = w_min + (w_max - w_min) * g
        return ImpactVelocityModel.clamp_velocity_m_s(omega * r)
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


# Effective impact velocity (m/s). Prefer attack.velocity_m_s if set (e.g. after partial parry); else derive from
# intensity. Commit fraction boosts post-velocity for follow-through energy on extended strikes.
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
    var vel: float = velocity_m_s_from_intensity(eff_i, arch if arch is Dictionary else {}, weapon, move_id)
    ## Commit fraction scales delivery energy — higher commit adds follow-through coupling for
    ## sub-max intensity strikes. At band max (i=1.0), committed strikes don't exceed no-commit snap
    ## but higher commit delivers more KE than lower commit by reducing the extension dampen penalty.
    if use_delivery_commit and commit >= 0.0:
        if base_i < 1.0:
            vel *= velocity_mult_for_delivery_commit(commit)
        else:
            ## At band max, extended strike is slower than body-snap no-commit (no-commit=band max).
            ## Higher commit = less dampen (better follow-through coupling), so ke_hi > ke_lo < ke_no.
            var dampen: float = 1.0 - (1.0 - commit) * 0.04
            vel *= dampen
    return vel


static func _ke_thrust_point_mass(weapon: RefCounted, attack_instance: RefCounted, v: float) -> float:
    var m_strike: float = strike_mass_kg(weapon, attack_instance)
    return 0.5 * m_strike * v * v


static func _ke_swing_rotational(weapon: RefCounted, attack_instance: RefCounted, v: float) -> float:
    var move_id: String = move_id_from_attack_instance(attack_instance)
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    if weapon.has_method("has_parts") and weapon.has_parts():
        var inertia_full: float = WeaponSwingPhysics.inertia_about_grip_kg_m2(weapon)
        var r: float = maxf(WeaponSwingPhysics.MIN_LEVER_M, WeaponSwingPhysics.strike_lever_arm_m(weapon, ct))
        ## Velocity bands are tip-speed at the strike lever; omega = v/r converts to angular velocity.
        ## Previous code rescaled via r_tip (v * r / r_tip / r) which introduced geometry-dependent error when lever ≠ tip length.
        var omega: float = v / r
        return WeaponSwingPhysics.rotational_ke_j(inertia_full, omega)
    return _ke_thrust_point_mass(weapon, attack_instance, v)


# Kinetic energy (J): thrust -> 1/2 m_strike v^2; swing -> 1/2 I omega^2 (full I); mixed -> blend. Unarmed/no parts uses
# thrust path on swing fallback. strike_energy_mult is intentionally NOT applied here — it models damage transfer
# efficiency, not kinetic energy. The same information lives in cut_damage_mult/blunt_damage_mult from StrikeRealismProfile.
static func _raw_kinetic_energy_j(weapon: RefCounted, attack_instance: RefCounted) -> float:
    if weapon == null:
        return 0.0
    var v: float = get_effective_velocity_m_s(weapon, attack_instance)
    var move_id: String = move_id_from_attack_instance(attack_instance)
    var arch: Dictionary = attack_instance.get("archetype") if attack_instance.get("archetype") is Dictionary else {}
    var delivery: String = kinematic_delivery(arch, move_id)
    match delivery:
        WeaponConstants.KINEMATIC_DELIVERY_THRUST:
            return _ke_thrust_point_mass(weapon, attack_instance, v)
        WeaponConstants.KINEMATIC_DELIVERY_SWING:
            return _ke_swing_rotational(weapon, attack_instance, v)
        WeaponConstants.KINEMATIC_DELIVERY_MIXED:
            var b: float = 0.5
            if arch.has("kinematic_mixed_blend"):
                var bm: Variant = arch.get("kinematic_mixed_blend")
                if bm is float or bm is int:
                    b = clampf(float(bm), 0.0, 1.0)
            return lerpf(
                _ke_thrust_point_mass(weapon, attack_instance, v),
                _ke_swing_rotational(weapon, attack_instance, v),
                b
            )
        _:
            return _ke_swing_rotational(weapon, attack_instance, v)


## Sub-band energy ramp factor (0..1): 1.0 at/above band-minimum KE, linear down to SUB_BAND_RAMP_FLOOR at
## SUB_BAND_MINIMUM_RATIO of band-min KE, hard zero below that. Shared by reported KE and pre-armor damage so
## a weak strike can't report low energy while still dealing full tissue deformation.
static func sub_band_energy_factor(weapon: RefCounted, attack_instance: RefCounted) -> float:
    if weapon == null or SUB_BAND_MINIMUM_RATIO <= 0.0:
        return 1.0
    var move_id: String = move_id_from_attack_instance(attack_instance)
    var arch: Dictionary = attack_instance.get("archetype") if attack_instance.get("archetype") is Dictionary else {}
    var delivery: String = kinematic_delivery(arch, move_id)
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    var band: Vector2 = ImpactVelocityModel.resolve_band_m_s(weapon, ct)
    if band.x <= 0.0:
        return 1.0
    var ke_at_band_min: float
    match delivery:
        WeaponConstants.KINEMATIC_DELIVERY_THRUST:
            ke_at_band_min = _ke_thrust_point_mass(weapon, attack_instance, band.x)
        WeaponConstants.KINEMATIC_DELIVERY_SWING:
            ke_at_band_min = _ke_swing_rotational(weapon, attack_instance, band.x)
        _:
            ke_at_band_min = _ke_swing_rotational(weapon, attack_instance, band.x)
    if ke_at_band_min <= 0.0:
        return 1.0
    var ratio: float = _raw_kinetic_energy_j(weapon, attack_instance) / ke_at_band_min
    if ratio >= SUB_BAND_RAMP_FULL_RATIO:
        return 1.0
    if ratio <= SUB_BAND_MINIMUM_RATIO:
        return 0.0
    var t: float = (ratio - SUB_BAND_MINIMUM_RATIO) / maxf(0.0001, SUB_BAND_RAMP_FULL_RATIO - SUB_BAND_MINIMUM_RATIO)
    return lerpf(SUB_BAND_RAMP_FLOOR, 1.0, clampf(t, 0.0, 1.0))


# Kinetic energy (J): raw delivery energy scaled by the sub-band ramp.
static func compute_kinetic_energy_j(weapon: RefCounted, attack_instance: RefCounted) -> float:
    return _raw_kinetic_energy_j(weapon, attack_instance) * sub_band_energy_factor(weapon, attack_instance)


# Pre-armor CUT (sharp) from KE and effective edge: CUT_DAMAGE_KE_SCALE * KE^CUT_DAMAGE_ENERGY_EXPONENT
# * strength_mod * arm_mod * contact_factor(effective sharp), clamped.
static func compute_pre_armor_cut(
    weapon: RefCounted, attack_instance: RefCounted, strength: float, arm_mod: float
) -> float:
    var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
    # The sub-band ramp is already folded into ke_j, so no separate factor here — damage and
    # reported energy stay consistent by construction.
    var strength_mod: float = maxf(0.1, float(strength) / 100.0)
    # Cut scales as KE^CUT_DAMAGE_ENERGY_EXPONENT (Williams-consistent), re-anchored at 100 J -> 35.
    var raw: float = (
        WeaponConstants.CUT_DAMAGE_KE_SCALE * pow(maxf(0.0, ke_j), WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
        * strength_mod
        * arm_mod
    )
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
    # Zero-KE strikes (fully defused parry follow-throughs at ~0 m/s) carry no edge energy to cut — skip the
    # DAMAGE_KE_MIN floor so they cannot score damage out of thin air. The AttackResolver contact floor still
    # prevents genuine contact hits from rounding to zero HP.
    var min_cut: float = WeaponConstants.DAMAGE_KE_MIN if ke_j > 0.0 else 0.0
    return clampf(raw, min_cut, WeaponConstants.DAMAGE_KE_MAX)


## Impact contact duration (s) at tip speed v: the calibrated 12 ms constant is anchored at
## BLUNT_IMPACT_REFERENCE_SPEED_M_S; faster impacts compress the pulse (Δt ∝ v^-0.4), slower ones widen it.
## Clamped to [BLUNT_CONTACT_TIME_MIN_S, BLUNT_CONTACT_TIME_MAX_S] so sub-band or pinned velocities stay physical.
static func impact_contact_time_s(v_m_s: float) -> float:
    var base_s: float = WeaponConstants.BLUNT_IMPACT_CONTACT_TIME_MS / 1000.0
    if WeaponConstants.BLUNT_CONTACT_TIME_SPEED_EXPONENT <= 0.0:
        return base_s
    var v_ref: float = maxf(1.0, WeaponConstants.BLUNT_IMPACT_REFERENCE_SPEED_M_S)
    var ratio: float = maxf(0.25, absf(v_m_s)) / v_ref
    var dt: float = base_s * pow(ratio, -WeaponConstants.BLUNT_CONTACT_TIME_SPEED_EXPONENT)
    return clampf(dt, WeaponConstants.BLUNT_CONTACT_TIME_MIN_S, WeaponConstants.BLUNT_CONTACT_TIME_MAX_S)


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
    ## Pressure-based blunt damage: P = m·v/(A·Δt), converted to game damage units.
    ## Contact area A derived from contact_cm (already computed below); Δt = BLUNT_IMPACT_CONTACT_TIME_MS.
    var contact_cm: float = _get_blunt_contact_for_damage(weapon, attack_instance)
    contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
    var contact_area_m2: float = PI * (contact_cm / 200.0) * (contact_cm / 200.0)   # diameter in cm → radius in m → circular area
    var delta_t_s: float = impact_contact_time_s(v)
    var pressure_pa: float = momentum / (maxf(contact_area_m2, 0.0001) * maxf(delta_t_s, WeaponConstants.BLUNT_CONTACT_TIME_MIN_S))
    var raw: float = pressure_pa * WeaponConstants.BLUNT_DAMAGE_PER_UNIT_PRESSURE * strength_mod * arm_mod
    # Blunt damage is linear in momentum (v), so the sub-band ramp applies linearly — matching the KE factor
    # that cut damage receives through sqrt(KE). Keeps weak strikes' blunt channel consistent with reported energy.
    return raw * sub_band_energy_factor(weapon, attack_instance)


## Cut-induced blunt slip: momentum raw - -  **`(1 - cut_ratio)`** - -  optional **`blunt_damage_mult`**, max-only clamp
## (no **`BLUNT_DAMAGE_MIN`**  -  see **`AttackResolver.compute_and_apply_damage`**).
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


## Clamped pre-armor blunt (full weapon swing / pure blunt). Cut weapons use **`compute_blunt_slip_pre_armor`** in
## **`AttackResolver`** so **`strike_momentum_mult`** is not erased by **`BLUNT_DAMAGE_MIN`** before the slip split.
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
# opts: optional { "armor_resistance_rha_mm": float, "pen_sharp_mm": float }  -  when both provided for thrusts, use
# energy-based contact.
static func compute_penetration(
    weapon: RefCounted, attack_instance: RefCounted, damage_type: String, opts: Dictionary = {}
) -> Dictionary:
    var armor_resistance_rha_mm: float = opts.get("armor_resistance_rha_mm", -1.0) if opts is Dictionary else -1.0
    var pen_sharp_mm: float = opts.get("pen_sharp_mm", -1.0) if opts is Dictionary else -1.0
    var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
    var attack_type: String = attack_instance.get("attack_type")
    if attack_type == null or not (attack_type is String):
        attack_type = WeaponConstants.ATTACK_TYPE_CUT

    var contact_cm: float
    if damage_type == WeaponConstants.DAMAGE_TYPE_SHARP:
        # Sharp: Williams nonlinear — pen = (KE/J_BASE)^exp * area_factor. E ∝ t^1.67 → pen ∝ KE^0.6.
        # Apply material correction for medieval steel vs RHA and average obliquity factor.
        contact_cm = _get_effective_sharp_contact_cm(weapon, attack_type)
        contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
        var area_factor: float = pow(
            WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_AREA_EXPONENT
        )
        ## Effective KE adjusted for historical steel (1.6× more penetrable than RHA) and average combat angle (÷1.1 effective armor thickness).
        ## Since pen ∝ KE^PENETRATION_EXPONENT (=0.6), the 1.45× net KE multiplier (1.6/1.1) yields 1.45^0.6 ≈ 1.25×
        ## penetration increase — consistent with softer medieval steel vs RHA.
        var ke_effective: float = ke_j * WeaponConstants.WILLIAMS_MATERIAL_CORRECTION / WeaponConstants.WILLIAMS_OBLIQUITY_FACTOR
        var pen_mm_rha: float = (
            pow(ke_effective / WeaponConstants.J_PER_MM_BASE, WeaponConstants.PENETRATION_EXPONENT) * area_factor
        )
        # Edge geometry (wedge mechanics): sharper edges displace less material per mm depth.
        # Factor = sin(DEFAULT/2)/sin(angle/2) where angle interpolates between sharp=25° and dull=65°
        # (EDGE_ANGLE_SHARP_DEG..EDGE_ANGLE_DULL_DEG).
        var edge_angle: float = WeaponConstants.EDGE_ANGLE_DEFAULT_DEG  # fallback when weapon has no sharpness
        if weapon != null and "sharpness" in weapon:
            var s_val = weapon.sharpness
            if s_val is float or s_val is int:
                edge_angle = (s_val as float)
        pen_mm_rha *= WeaponConstants.edge_wedge_penetration_factor(edge_angle)
        var contact_ct: String = WeaponConstants.contact_type_for_move_id(attack_type)
        if contact_ct == WeaponConstants.ATTACK_TYPE_STAB:
            pen_mm_rha *= WeaponConstants.STAB_PENETRATION_MULT
        pen_mm_rha = minf(pen_mm_rha, WeaponConstants.PENETRATION_KE_CAP_MM_RHA)
        return {"penetration_sharp": pen_mm_rha}
    # Blunt: transmission-only. Returns momentum_per_area and contact_cm for area coupling.
    contact_cm = _get_blunt_contact_for_penetration(weapon, attack_instance, armor_resistance_rha_mm, pen_sharp_mm)
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
    var contact_pen_raw: float = _get_blunt_contact_cm(weapon, attack_type)
    # Mirror the damage channel's BLUNT head cap so momentum/area for armor absorption uses the same
    # effective face as pre-armor pressure — without it a large head (mace 8 cm) dissipates over an
    # oversized area here but is capped in _get_blunt_contact_for_damage, desyncing the two channels.
    if contact_pen == WeaponConstants.ATTACK_TYPE_STAB:
        return maxf(contact_pen_raw, WeaponConstants.BLUNT_STAB_MIN_CONTACT_CM)
    if contact_pen == WeaponConstants.ATTACK_TYPE_BLUNT:
        return minf(contact_pen_raw, WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM)
    return contact_pen_raw


# Blunt cushion: momentum per area (kg·m/s)/mÂ². Used by armor for transmission absorption.
static func _compute_blunt_momentum_per_area_with_contact(
    weapon: RefCounted, attack_instance: RefCounted, contact_cm: float, target_effective_mass_kg: float = -1.0
) -> float:
    if weapon == null or contact_cm <= 0.0:
        return -1.0
    var d_m: float = contact_cm / 100.0 if contact_cm > 0 else 0.01
    var area_m2: float = PI * (d_m / 2.0) * (d_m / 2.0)   # diameter in m → radius → circular area
    area_m2 = maxf(area_m2, WeaponConstants.MIN_BLUNT_AREA_M2)
    var mass_kg: float = strike_mass_kg(weapon, attack_instance)
    if target_effective_mass_kg > 0.0:
        mass_kg = reduced_mass_pair_kg(mass_kg, target_effective_mass_kg)
    var v: float = get_effective_velocity_m_s(weapon, attack_instance, false)
    var p_mult: float = _attack_float_or_default(attack_instance, "strike_momentum_mult", 1.0)
    var momentum: float = mass_kg * v * maxf(0.05, p_mult)
    return momentum / area_m2 if area_m2 > 0 else 0.0





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
            (
                "[WeaponDamageHelper] Weapon lacks get_contact_width; using BASELINE_CONTACT_CM. "
                + "Ensure weapon is Weapon instance from create_from_definition."
            )
        )
    return WeaponConstants.BASELINE_CONTACT_CM


# Sharp-component contact (cm): point, blade, or edge/flange. Uses weapon get_sharp_contact_cm (blade_width,
# point_width, edge_width).
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
            (
                "[WeaponDamageHelper] Weapon lacks get_blunt_contact_cm; using fallback. "
                + "Ensure weapon is Weapon instance from create_from_definition."
            )
        )
    var contact_cm: float = _get_contact_width_cm(weapon, attack_type)
    var contact_fallback: String = WeaponConstants.contact_type_for_move_id(attack_type)
    if contact_fallback == WeaponConstants.ATTACK_TYPE_CUT:
        contact_cm = maxf(contact_cm, WeaponConstants.BLUNT_CUT_MIN_CONTACT_CM)
    return contact_cm


# Blunt contact for damage: archetype override or weapon get_blunt_contact_cm (uses actual blade_width, point_width,
# head_diameter). For STAB moves, floors at BLUNT_STAB_MIN_CONTACT_CM so the blunt slip channel isn't amplified by tiny
# point contact — the pressure formula was calibrated for broader impacts (~3 cm²), not concentrated tip puncture.
# For BLUNT moves, caps at BLUNT_HEAD_MAX_CONTACT_CM so large heads (mace 8 cm) don't dissipate pressure over an
# oversized face (see WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM).
static func _get_blunt_contact_for_damage(weapon: RefCounted, attack_instance: RefCounted) -> float:
    var arch = attack_instance.get("archetype")
    if arch is Dictionary and arch.get("contact_override_cm", -1.0) >= 0.0:
        return float(arch.contact_override_cm)
    var at = attack_instance.get("attack_type")
    if at is String:
        var contact: float = _get_blunt_contact_cm(weapon, at)
        var ct: String = WeaponConstants.contact_type_for_move_id(at)
        if ct == WeaponConstants.ATTACK_TYPE_STAB:
            return maxf(contact, WeaponConstants.BLUNT_STAB_MIN_CONTACT_CM)
        if ct == WeaponConstants.ATTACK_TYPE_BLUNT:
            return minf(contact, WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM)
        return contact
    push_warning("[WeaponDamageHelper] attack_instance missing attack_type; using BASELINE_CONTACT_CM for blunt.")
    return WeaponConstants.BASELINE_CONTACT_CM


# Cut ratio 0.0 - 1.0 for this move (rest blunt). From archetype or weapon blade_cut_ratio / stab_cut_ratio.
# No weapon has 0% cutting: even maces can break skin (flanges/ridges); floor is MIN_CUT_RATIO.
# Blunt-damage weapons (mace, pollarm) hard-capped at CUT_RATIO_BLUNT_WEAPON_MAX so they remain primarily blunt tools.
static func get_cut_ratio(weapon: RefCounted, attack_type: String, archetype_dict: Dictionary) -> float:
    var cr: float = 0.75
    if archetype_dict.has("cut_ratio") and float(archetype_dict.cut_ratio) >= 0.0:
        cr = clampf(float(archetype_dict.cut_ratio), 0.0, 1.0)
    elif weapon is Object and weapon.has_method("get_damage_type"):
        if weapon.get_damage_type(attack_type) == WeaponConstants.DAMAGE_TYPE_BLUNT:
            cr = 0.0
        else:
            cr = _weapon_cut_ratio_for_attack(weapon, attack_type)
    elif weapon != null:
        cr = _weapon_cut_ratio_for_attack(weapon, attack_type)
    # Hard cap for blunt-damage weapons maces and pollarms can nick skin but should not deal significant cut damage.
    if weapon is Object and weapon.has_method("get_damage_type"):
        var dtype: String = weapon.get_damage_type(attack_type)
        if dtype == WeaponConstants.DAMAGE_TYPE_BLUNT:
            cr = minf(cr, CUT_RATIO_BLUNT_WEAPON_MAX)
    return maxf(cr, WeaponConstants.MIN_CUT_RATIO)


static func _weapon_cut_ratio_for_attack(weapon: Variant, attack_type: String) -> float:
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    if move_def.get("contact_type", "") == WeaponConstants.ATTACK_TYPE_STAB and "stab_cut_ratio" in weapon:
        return clampf(float(weapon.stab_cut_ratio), 0.0, 1.0)
    if "blade_cut_ratio" in weapon:
        return clampf(float(weapon.blade_cut_ratio), 0.0, 1.0)
    return 0.75
