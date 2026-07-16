class_name CombatStrikeStamping
extends RefCounted

## Tier 3.1: pair geometry + strike measure on attack `pa` / `pending_attack`.


static func strike_measure_ratio_for_weapon_eff_dist(weapon: RefCounted, eff_dist: float) -> float:
    if weapon == null:
        return 1.0
    var eff: float = maxf(eff_dist, CombatConstants.STRIKE_MEASURE_EFF_DIST_FLOOR)
    var melee: float = float(weapon.melee_range) if (weapon.melee_range is float or weapon.melee_range is int) else 1.5
    return clampf(melee / eff, CombatConstants.STRIKE_MEASURE_RATIO_MIN, CombatConstants.STRIKE_MEASURE_RATIO_MAX)


static func strike_measure_ratio_for_attack_pair(
    manager: Node, atk: Dictionary, tgt: Dictionary, weapon: RefCounted, stamped_eff_dist: float = -1.0
) -> float:
    if manager == null or weapon == null:
        return 1.0
    var eff: float = stamped_eff_dist
    if eff < 0.01:
        eff = CombatPairGeometry.cached_eff_dist(CombatPairGeometry.effective_pair_geometry(manager, atk, tgt))
    return strike_measure_ratio_for_weapon_eff_dist(weapon, eff)


static func stamp_attack_pair_geometry_on_dict(manager: Node, atk: Dictionary, tgt: Dictionary, pa: Dictionary) -> void:
    if manager == null:
        return
    var pair_geom: Dictionary = CombatPairGeometry.effective_pair_geometry(manager, atk, tgt)
    pa[DataKeys.EFFECTIVE_PAIR_FILE_SPACING_EQUIV] = pair_geom.get(DataKeys.PAIR_FILE_SPACING_EQUIV, 0.0)
    pa[DataKeys.PA_EFFECTIVE_PAIR_EFF_DIST] = CombatPairGeometry.cached_eff_dist(pair_geom)
    CombatDepthPolearm.stamp_depth_flags_on_pa(manager, atk, pa)


static func stamp_strike_realism_on_pa(
    manager: Node, atk: Dictionary, tgt: Dictionary, pa: Dictionary, weapon: Variant, attack_type: String
) -> void:
    if weapon == null:
        pa[DataKeys.PA_STRIKE_MEASURE_RATIO] = 1.0
        return
    pa[DataKeys.PA_STRIKE_MEASURE_RATIO] = strike_measure_ratio_for_attack_pair(
        manager, atk, tgt, weapon, pa.get(DataKeys.PA_EFFECTIVE_PAIR_EFF_DIST, -1.0)
    )
    if str(pa.get(DataKeys.PA_MOVE_CONTACT_TYPE, "")).is_empty():
        pa[DataKeys.PA_MOVE_CONTACT_TYPE] = WeaponConstants.contact_type_for_move_id(attack_type)


static func stamp_attack_pair_and_strike_realism(
    manager: Node, atk: Dictionary, tgt: Dictionary, pa: Dictionary, weapon: Variant, attack_type: String
) -> void:
    stamp_attack_pair_geometry_on_dict(manager, atk, tgt, pa)
    stamp_strike_realism_on_pa(manager, atk, tgt, pa, weapon, attack_type)
