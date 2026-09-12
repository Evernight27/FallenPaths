class_name CombatDepthPolearm
extends RefCounted

## Tier 1.9 (P10): depth-rank spear/polearm lanes, line threat, low-target filtering, attack `pa` lane flags.


## Living same-file rank-0 ally on home formation (opens spear / polearm lane from depth).
static func same_file_living_rank0_ally(manager: Node, c: Dictionary, zone_geometry_fid: String = "") -> Dictionary:
    if manager == null or c.is_empty():
        return {}
    var fid: String = (
        zone_geometry_fid if not zone_geometry_fid.is_empty() else ZoneOfControl.zone_geometry_fid_str(manager, c)
    )
    if fid.is_empty():
        return {}
    var f: int = CombatantEntityAccess.file_int(c)
    for x in manager.combatants:
        if not CombatantEntityAccess.is_living_same_side(c, x):
            continue
        if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, x, fid):
            continue
        if CombatantEntityAccess.rank_int(x) != 0:
            continue
        if CombatantEntityAccess.file_int(x) != f:
            continue
        if CombatantEntityAccess.is_incapacitated(x):
            continue
        return x
    return {}


static func depth_polearm_lane_open(manager: Node, c: Dictionary, zone_geometry_fid: String = "") -> bool:
    if manager == null or c.is_empty():
        return false
    if CombatantEntityAccess.rank_int(c) <= 0:
        return false
    if CombatantEntityAccess.get_attacking_arm(c).is_empty():
        return false
    var w: Variant = CombatantEntityAccess.get_weapon(c)
    if w == null or not (w is Weapon) or not (w as Weapon).depth_melee_eligible:
        return false
    return not same_file_living_rank0_ally(manager, c, zone_geometry_fid).is_empty()


static func depth_polearm_threatens_line_target(front_rank0_ally: Dictionary, opp: Dictionary) -> bool:
    if front_rank0_ally.is_empty() or opp.is_empty():
        return false
    if CombatantEntityAccess.rank_int(front_rank0_ally) != 0 or CombatantEntityAccess.rank_int(opp) != 0:
        return false
    if not CombatantEntityAccess.is_living_hostile_to(front_rank0_ally, opp):
        return false
    var df: int = absi(CombatantEntityAccess.file_int(opp) - CombatantEntityAccess.file_int(front_rank0_ally))
    return df <= int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)


static func depth_polearm_valid_line_threat(
    manager: Node,
    attacker: Dictionary,
    opp: Dictionary,
    zone_geometry_fid: String = "",
    lane_open_known: Variant = null
) -> bool:
    if manager == null or attacker.is_empty() or opp.is_empty():
        return false
    var fid: String = zone_geometry_fid
    if fid.is_empty():
        fid = ZoneOfControl.zone_geometry_fid_str(manager, attacker)
    var lane_open: bool = (
        bool(lane_open_known) if lane_open_known != null else depth_polearm_lane_open(manager, attacker, fid)
    )
    if not lane_open:
        return false
    var front: Dictionary = same_file_living_rank0_ally(manager, attacker, fid)
    return depth_polearm_threatens_line_target(front, opp)


static func depth_polearm_has_valid_line_threat_to_any_rank0_hostile(
    manager: Node, attacker: Dictionary, combatants: Array
) -> bool:
    if manager == null or attacker.is_empty() or combatants.is_empty():
        return false
    var fid: String = ZoneOfControl.zone_geometry_fid_str(manager, attacker)
    var lane_open: bool = depth_polearm_lane_open(manager, attacker, fid)
    if not lane_open:
        return false
    for opp in combatants:
        if not CombatantEntityAccess.is_living_hostile_to(attacker, opp):
            continue
        if CombatantEntityAccess.rank_int(opp) != 0:
            continue
        if depth_polearm_valid_line_threat(manager, attacker, opp, fid, lane_open):
            return true
    return false


static func depth_polearm_lane_allows_low_targets(
    manager: Node,
    attacker: Dictionary,
    zone_geometry_fid: String = "",
    formation_dict_cache: Variant = null,
    assume_depth_lane_open: bool = false
) -> bool:
    if manager == null or attacker.is_empty():
        return true
    var fid_geom: String = (
        zone_geometry_fid
        if not zone_geometry_fid.is_empty()
        else ZoneOfControl.zone_geometry_fid_str(manager, attacker)
    )
    if not assume_depth_lane_open:
        if not depth_polearm_lane_open(manager, attacker, fid_geom):
            return true
    var fd: Dictionary = ZoneOfControl.formation_for_combatant_cached(manager, attacker, formation_dict_cache, fid_geom)
    var prof: String = CombatConstants.SPEAR_LANE_PROFILE_AUTO
    if not fd.is_empty():
        prof = CombatConstants.normalize_spear_lane_profile(
            fd.get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, "")
        )
    if prof == CombatConstants.SPEAR_LANE_PROFILE_OPEN:
        return true
    var fi: int = CombatantEntityAccess.file_int(attacker)
    var ls: Dictionary = FormationSlots.formation_nested_dictionary_read(fd, "lane_stress_by_file")
    var gap: float = clampf(float(CombatFileKeyedDict.get_value(ls, fi, 0.0)), 0.0, 1.0)
    var lane_stress_opens: bool = gap + 0.0001 >= float(CombatConstants.DEPTH_SPEAR_LANE_STRESS_OPEN_MIN)
    if prof == CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED:
        return lane_stress_opens
    if lane_stress_opens:
        return true
    var disc: String = CombatFormationEngagement.effective_line_discipline(manager, fd)
    if disc == CombatConstants.LINE_DISCIPLINE_STRICT:
        return false
    var dens: String = str(fd.get(DataKeys.FORMATION_DENSITY, "normal")) if not fd.is_empty() else "normal"
    if dens == "loose":
        return true
    if disc == CombatConstants.LINE_DISCIPLINE_LOOSE:
        return true
    var posture: String = str(fd.get(DataKeys.FORMATION_ENGAGEMENT_POSTURE, "")).strip_edges().to_lower()
    if posture == CombatConstants.ENGAGEMENT_POSTURE_OPEN or posture == CombatConstants.ENGAGEMENT_POSTURE_DUEL:
        return true
    return false


## Depth spear lane flags on attack **`pa`** (after pair geometry stamped).
static func stamp_depth_flags_on_pa(manager: Node, atk: Dictionary, pa: Dictionary) -> void:
    pa[DataKeys.PA_DEPTH_POLEARM_ATTACK] = false
    pa[DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW] = true
    pa[DataKeys.PA_DEPTH_POLEARM_LANE_TYPE] = ""
    if manager == null or atk.is_empty() or CombatantEntityAccess.rank_int(atk) <= 0:
        return
    var ctx_stamp: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, atk)
    var fid_stamp: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_stamp)
    if not depth_polearm_lane_open(manager, atk, fid_stamp):
        return
    pa[DataKeys.PA_DEPTH_POLEARM_ATTACK] = true
    var fd_stamp: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx_stamp)
    if not fd_stamp.is_empty():
        pa[DataKeys.PA_ZONE_GEOMETRY_ATK_DENSITY] = str(fd_stamp.get(DataKeys.FORMATION_DENSITY, "normal"))
    var allow_low: bool = depth_polearm_lane_allows_low_targets(manager, atk, fid_stamp, fd_stamp, true)
    pa[DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW] = allow_low
    pa[DataKeys.PA_DEPTH_POLEARM_LANE_TYPE] = (
        CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
        if allow_low
        else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
    )


static func depth_polearm_targetable_parts_filter(
    manager: Node, attacker: Dictionary, targetable: Array, stamped_pa: Dictionary = {}
) -> Array:
    if targetable.is_empty() or manager == null or attacker.is_empty():
        return targetable
    if stamped_pa.has(DataKeys.PA_DEPTH_POLEARM_ATTACK):
        if stamped_pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false) != true:
            return targetable
        if stamped_pa.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true):
            return targetable
    else:
        var ctx_filt: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, attacker)
        var fid_filt: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_filt)
        if not depth_polearm_lane_open(manager, attacker, fid_filt):
            return targetable
        if CombatantEntityAccess.rank_int(attacker) <= 0:
            return targetable
        var fd_filt: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx_filt)
        if depth_polearm_lane_allows_low_targets(manager, attacker, fid_filt, fd_filt, true):
            return targetable
    var out: Array = []
    for p in targetable:
        if p == BodyPartConstants.PART_LEFT_LEG or p == BodyPartConstants.PART_RIGHT_LEG:
            continue
        out.append(p)
    return out if not out.is_empty() else targetable



