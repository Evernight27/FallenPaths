class_name StrikeRealismProfile
extends RefCounted

## Strike realism modifiers (no full multibody): blade station, measure (reach vs eff_dist),
## velocity curve exponent (archetype), KE coupling per contact, blunt pressure, obliquity on damage/pen.
## All five weapon templates carry `strike_physics` on Weapon; moves may override station via optional move keys.

const _W := preload("res://weapon/WeaponConstants.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")


static func _phys(weapon: RefCounted) -> Dictionary:
    if weapon == null or not (weapon is Object):
        return {}
    var sp: Variant = (weapon as Object).get("strike_physics")
    return sp if sp is Dictionary else {}


static func measure_ratio(manager: Node, atk: Dictionary, tgt: Dictionary, weapon: RefCounted) -> float:
    return _StrikeStamping.strike_measure_ratio_for_attack_pair(manager, atk, tgt, weapon, -1.0)


static func roll_blade_station(weapon: RefCounted, move_id: String, intensity: float) -> float:
    var phys: Dictionary = _phys(weapon)
    var mean: float = phys.get("station_mean", 0.56)
    var spread: float = phys.get("station_spread", 0.11)
    var md: Dictionary = _W.get_move(move_id)
    if md.get("impact_station_mean", null) is float or md.get("impact_station_mean", null) is int:
        mean = float(md.impact_station_mean)
    if md.get("impact_station_spread", null) is float or md.get("impact_station_spread", null) is int:
        spread = float(md.impact_station_spread)
    var jitter: float = (randf() - 0.5) * 2.0 * spread
    var focus: float = clampf((intensity - 0.35) * 0.08, -0.04, 0.04)
    return clampf(mean + jitter + focus, 0.06, 0.99)


static func blade_station_from_pa(pa: Dictionary, weapon: RefCounted, move_id: String, intensity: float) -> float:
    var s: float = pa.get("impact_blade_station", -1.0)
    if s >= 0.0 and s <= 1.0:
        return s
    return roll_blade_station(weapon, move_id, intensity)


static func _station_velocity_mult(contact: String, station: float, phys: Dictionary) -> float:
    if contact == _W.ATTACK_TYPE_CUT:
        var lo: float = phys.get("station_cut_vel_guard", 0.9)
        var hi: float = phys.get("station_cut_vel_tip", 1.08)
        return lerpf(lo, hi, station)
    if contact == _W.ATTACK_TYPE_STAB:
        return lerpf(0.94, 1.06, station)
    return lerpf(0.96, 1.05, station)


static func _measure_velocity_mult(contact: String, meas: float) -> float:
    var t: float = clampf((meas - 0.78) / 0.34, 0.0, 1.0)
    if contact == _W.ATTACK_TYPE_STAB:
        return lerpf(0.93, 1.04, t)
    return lerpf(0.97, 1.02, t)


## Used by parry/dodge intent speed (consistent with damage resolution).
static func velocity_intent_mult_from_pa(
    pa: Dictionary, weapon: RefCounted, move_id: String, intensity: float, _archetype: Dictionary
) -> float:
    var contact: String = _W.contact_type_for_move_id(move_id)
    var phys: Dictionary = _phys(weapon)
    var station: float = blade_station_from_pa(pa, weapon, move_id, intensity)
    var meas: float = pa.get("strike_measure_ratio", 1.0)
    return _station_velocity_mult(contact, station, phys) * _measure_velocity_mult(contact, meas)


static func _coupling(contact: String, phys: Dictionary) -> float:
    var k: String = "coupling_%s" % contact
    return clampf(phys.get(k, 1.0), 0.45, 1.15)


static func _blunt_pressure_mult(weapon: RefCounted, phys: Dictionary) -> float:
    var base: float = clampf(phys.get("blunt_pressure", 1.0), 0.75, 1.35)
    if weapon == null:
        return base
    var hd: float = (
        float(weapon.head_diameter) if (weapon.head_diameter is float or weapon.head_diameter is int) else 4.0
    )
    var ref: float = phys.get("blunt_head_ref_cm", 6.0)
    return base * clampf(ref / maxf(hd, 0.4), 0.82, 1.22)


static func _obliquity_factor(hit_alignment: float, parry_remaining_ratio: float) -> float:
    var f_align: float = lerpf(0.88, 1.0, clampf(hit_alignment, 0.0, 1.0))
    var f_parry: float = lerpf(0.9, 1.0, clampf(parry_remaining_ratio, 0.0, 1.0))
    return clampf(f_align * f_parry, 0.62, 1.0)


static func _station_cut_draw_mult(station: float) -> float:
    # Slight peak toward mid-blade for edge bite; foible/guard slightly softer in abstract HP model.
    var x: float = clampf(station, 0.0, 1.0)
    var bell: float = sin(x * PI)
    return clampf(lerpf(0.92, 1.08, bell), 0.88, 1.12)


static func compute_strike_modifiers(
    manager: Node,
    atk: Dictionary,
    tgt: Dictionary,
    weapon: RefCounted,
    move_id: String,
    intensity: float,
    _archetype: Dictionary,
    hit_alignment: float,
    parry_remaining_ratio: float,
    pa: Dictionary
) -> Dictionary:
    var contact: String = _W.contact_type_for_move_id(move_id)
    var phys: Dictionary = _phys(weapon)
    var station: float = blade_station_from_pa(pa, weapon, move_id, intensity)
    var eff_ov: float = -1.0
    if not pa.is_empty():
        var ve: Variant = pa.get("effective_pair_eff_dist", null)
        if ve is float or ve is int:
            eff_ov = float(ve)
    var meas_default: float = _StrikeStamping.strike_measure_ratio_for_attack_pair(manager, atk, tgt, weapon, eff_ov)
    var meas: float = float(pa.get("strike_measure_ratio", meas_default))
    var vel_m: float = _station_velocity_mult(contact, station, phys) * _measure_velocity_mult(contact, meas)
    var coup: float = _coupling(contact, phys)
    var obliq: float = _obliquity_factor(hit_alignment, parry_remaining_ratio)
    var cut_m: float = 1.0
    if contact == _W.ATTACK_TYPE_CUT:
        cut_m = _station_cut_draw_mult(station) * obliq
    elif contact == _W.ATTACK_TYPE_STAB:
        cut_m = lerpf(0.94, 1.05, station) * obliq
    else:
        cut_m = obliq
    var blunt_m: float = obliq * _blunt_pressure_mult(weapon, phys)
    if contact == _W.ATTACK_TYPE_BLUNT:
        blunt_m *= lerpf(0.94, 1.06, station)
    # Extra penetration vs armor from station only; oblique armor already handled in AttackResolver angle_factor.
    var pen_station: float = (
        lerpf(0.94, 1.045, station)
        if contact == _W.ATTACK_TYPE_STAB
        else clampf(lerpf(0.96, 1.028, sin(station * PI)), 0.9, 1.08)
    )
    return {
        "blade_station": station,
        "measure_ratio": meas,
        "velocity_mult": vel_m,
        "ke_coupling_mult": coup,
        "cut_damage_mult": cut_m,
        "blunt_damage_mult": blunt_m,
        "sharp_penetration_mult": pen_station,
        "blunt_momentum_pa_mult": obliq * _blunt_pressure_mult(weapon, phys),
        "strike_energy_mult": vel_m * vel_m * coup,
        "strike_momentum_mult": vel_m * coup
    }
