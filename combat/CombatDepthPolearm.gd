class_name CombatDepthPolearm
extends RefCounted

## Tier 1.9 (P10): depth-rank spear/polearm lanes, line threat, low-target filtering, attack `pa` lane flags.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FileKeyedDict := preload("res://combat/CombatFileKeyedDict.gd")


## Host-line formation id for melee column / lane checks (same contract as **`zone_geometry_fid_str`**).
static func actor_host_fid_for_melee_targeting(actor: Dictionary, manager: Variant = null) -> String:
	var mgr: Node = manager as Node if manager is Node else null
	return _ZoneOfControl.zone_geometry_fid_str(mgr, actor)


## Living same-file rank-0 ally on home formation (opens spear / polearm lane from depth).
static func same_file_living_rank0_ally(manager: Node, c: Dictionary, zone_geometry_fid: String = "") -> Dictionary:
	if manager == null or c.is_empty():
		return {}
	var fid: String = (
		zone_geometry_fid
		if not zone_geometry_fid.is_empty()
		else _ZoneOfControl.zone_geometry_fid_str(manager, c)
	)
	if fid.is_empty():
		return {}
	var f: int = _EntityAccess.file_int(c)
	for x in manager.combatants:
		if not _EntityAccess.is_living_same_side(c, x):
			continue
		if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, x, fid):
			continue
		if _EntityAccess.rank_int(x) != 0:
			continue
		if _EntityAccess.file_int(x) != f:
			continue
		if _EntityAccess.is_incapacitated(x):
			continue
		return x
	return {}


static func depth_polearm_lane_open(manager: Node, c: Dictionary, zone_geometry_fid: String = "") -> bool:
	if manager == null or c.is_empty():
		return false
	if _EntityAccess.rank_int(c) <= 0:
		return false
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return false
	var w: Variant = _EntityAccess.get_weapon(c)
	if w == null or not (w is Weapon) or not (w as Weapon).depth_melee_eligible:
		return false
	return not same_file_living_rank0_ally(manager, c, zone_geometry_fid).is_empty()


static func depth_polearm_threatens_line_target(front_rank0_ally: Dictionary, opp: Dictionary) -> bool:
	if front_rank0_ally.is_empty() or opp.is_empty():
		return false
	if _EntityAccess.rank_int(front_rank0_ally) != 0 or _EntityAccess.rank_int(opp) != 0:
		return false
	if not _EntityAccess.is_living_hostile_to(front_rank0_ally, opp):
		return false
	var df: int = absi(_EntityAccess.file_int(opp) - _EntityAccess.file_int(front_rank0_ally))
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
		fid = _ZoneOfControl.zone_geometry_fid_str(manager, attacker)
	var lane_open: bool = (
		bool(lane_open_known)
		if lane_open_known != null
		else depth_polearm_lane_open(manager, attacker, fid)
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
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(manager, attacker)
	var lane_open: bool = depth_polearm_lane_open(manager, attacker, fid)
	if not lane_open:
		return false
	for opp in combatants:
		if not _EntityAccess.is_living_hostile_to(attacker, opp):
			continue
		if _EntityAccess.rank_int(opp) != 0:
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
		else _ZoneOfControl.zone_geometry_fid_str(manager, attacker)
	)
	if not assume_depth_lane_open:
		if not depth_polearm_lane_open(manager, attacker, fid_geom):
			return true
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(
		manager, attacker, formation_dict_cache, fid_geom
	)
	var prof: String = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	if not fd.is_empty():
		prof = CombatConstants.normalize_spear_lane_profile(
			fd.get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, "")
		)
	if prof == CombatConstants.SPEAR_LANE_PROFILE_OPEN:
		return true
	var fi: int = _EntityAccess.file_int(attacker)
	var ls: Dictionary = _FormationSlots.formation_nested_dictionary_read(fd, "lane_stress_by_file")
	var gap: float = clampf(float(_FileKeyedDict.get_value(ls, fi, 0.0)), 0.0, 1.0)
	var lane_stress_opens: bool = gap + 0.0001 >= float(CombatConstants.DEPTH_SPEAR_LANE_STRESS_OPEN_MIN)
	if prof == CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED:
		return lane_stress_opens
	if lane_stress_opens:
		return true
	var disc: String = CombatFormationEngagement.effective_line_discipline(manager, fd)
	if disc == CombatConstants.LINE_DISCIPLINE_STRICT:
		return false
	var dens: String = str(fd.get("density", "normal")) if not fd.is_empty() else "normal"
	if dens == "loose":
		return true
	if disc == CombatConstants.LINE_DISCIPLINE_LOOSE:
		return true
	var posture: String = str(fd.get("engagement_posture", "")).strip_edges().to_lower()
	if posture == CombatConstants.ENGAGEMENT_POSTURE_OPEN or posture == CombatConstants.ENGAGEMENT_POSTURE_DUEL:
		return true
	return false


## Depth spear lane flags on attack **`pa`** (after pair geometry stamped).
static func stamp_depth_flags_on_pa(manager: Node, atk: Dictionary, pa: Dictionary) -> void:
	pa["depth_polearm_attack"] = false
	pa["depth_polearm_allows_low_targets"] = true
	pa["depth_polearm_lane_type"] = ""
	if manager == null or atk.is_empty() or _EntityAccess.rank_int(atk) <= 0:
		return
	var ctx_stamp: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, atk)
	var fid_stamp: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_stamp)
	if not depth_polearm_lane_open(manager, atk, fid_stamp):
		return
	pa["depth_polearm_attack"] = true
	var fd_stamp: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_stamp)
	if not fd_stamp.is_empty():
		pa["zone_geometry_atk_density"] = str(fd_stamp.get("density", "normal"))
	var allow_low: bool = depth_polearm_lane_allows_low_targets(
		manager, atk, fid_stamp, fd_stamp, true
	)
	pa["depth_polearm_allows_low_targets"] = allow_low
	pa["depth_polearm_lane_type"] = (
		CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
		if allow_low
		else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
	)


static func depth_polearm_targetable_parts_filter(
	manager: Node, attacker: Dictionary, targetable: Array, stamped_pa: Dictionary = {}
) -> Array:
	if targetable.is_empty() or manager == null or attacker.is_empty():
		return targetable
	if stamped_pa.has("depth_polearm_attack"):
		if not bool(stamped_pa.get("depth_polearm_attack", false)):
			return targetable
		if bool(stamped_pa.get("depth_polearm_allows_low_targets", true)):
			return targetable
	else:
		var ctx_filt: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, attacker)
		var fid_filt: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_filt)
		if not depth_polearm_lane_open(manager, attacker, fid_filt):
			return targetable
		if _EntityAccess.rank_int(attacker) <= 0:
			return targetable
		var fd_filt: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_filt)
		if depth_polearm_lane_allows_low_targets(manager, attacker, fid_filt, fd_filt, true):
			return targetable
	var out: Array = []
	for p in targetable:
		if p == "left_leg" or p == "right_leg":
			continue
		out.append(p)
	return out if not out.is_empty() else targetable
