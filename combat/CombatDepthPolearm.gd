class_name CombatDepthPolearm
extends RefCounted

## Tier 1.9 (P10): depth-rank spear/polearm lanes, line threat, low-target filtering, attack `pa` lane flags.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")


## Host formation for “who is this column on?” — intruders occupy host `slots` while `formation_id` stays home (P4).
static func actor_host_fid_for_melee_targeting(actor: Dictionary) -> String:
	if _ZoneOfControl.is_intruded(actor):
		var hf: String = _ZoneOfControl.intrusion_host_fid(actor)
		if not hf.is_empty():
			return hf
	return _EntityAccess.formation_id_str(actor)


## Living same-file rank-0 ally on home formation (opens spear / polearm lane from depth).
static func same_file_living_rank0_ally(manager: Node, c: Dictionary, zone_geometry_fid: String = "") -> Dictionary:
	if manager == null or c.is_empty():
		return {}
	var fid: String = (
		zone_geometry_fid
		if not zone_geometry_fid.is_empty()
		else _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
	)
	if fid.is_empty():
		return {}
	var f: int = _EntityAccess.file_int(c)
	var side: String = _EntityAccess.side_str(c)
	for x in manager.combatants:
		if not _EntityAccess.alive_bool(x):
			continue
		if _EntityAccess.side_str(x) != side:
			continue
		if _ZoneOfControl.formation_id_for_zone_geometry(manager, x) != fid:
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
	if _ZoneOfControl.is_intruded(c):
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
	if _EntityAccess.side_str(front_rank0_ally) == _EntityAccess.side_str(opp):
		return false
	if not _EntityAccess.alive_bool(opp):
		return false
	if _EntityAccess.is_incapacitated(opp):
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
		fid = _ZoneOfControl.formation_id_for_zone_geometry(manager, attacker)
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
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, attacker)
	var lane_open: bool = depth_polearm_lane_open(manager, attacker, fid)
	if not lane_open:
		return false
	var host_fid: String = actor_host_fid_for_melee_targeting(attacker)
	var my_side: String = _EntityAccess.side_str(attacker)
	for opp in combatants:
		if not _EntityAccess.alive_bool(opp) or _EntityAccess.side_str(opp) == my_side:
			continue
		if _EntityAccess.rank_int(opp) != 0:
			continue
		if _ZoneOfControl.intruder_on_host_formation(opp, host_fid):
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
		else _ZoneOfControl.formation_id_for_zone_geometry(manager, attacker)
	)
	if not assume_depth_lane_open:
		if not depth_polearm_lane_open(manager, attacker, fid_geom):
			return true
	var fd: Dictionary = (
		(formation_dict_cache as Dictionary)
		if formation_dict_cache != null and formation_dict_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, attacker, fid_geom)
	)
	var prof: String = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	if not fd.is_empty():
		prof = CombatConstants.normalize_spear_lane_profile(
			fd.get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, "")
		)
	if prof == CombatConstants.SPEAR_LANE_PROFILE_OPEN:
		return true
	var col: Vector2 = _PairGeometry.wedge_pressure_depth_at_combatant_column(manager, attacker)
	var gap: float = maxf(col.x, col.y)
	var wedge_opens: bool = gap + 0.0001 >= float(CombatConstants.DEPTH_SPEAR_WEDGE_OPEN_LANE_MIN)
	if prof == CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED:
		return wedge_opens
	if wedge_opens:
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
	var fid_stamp: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, atk)
	if not depth_polearm_lane_open(manager, atk, fid_stamp):
		return
	pa["depth_polearm_attack"] = true
	var fd_stamp: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, atk, fid_stamp)
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
		var fid_filt: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, attacker)
		if not depth_polearm_lane_open(manager, attacker, fid_filt):
			return targetable
		if _EntityAccess.rank_int(attacker) <= 0:
			return targetable
		var fd_filt: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, attacker, fid_filt)
		if depth_polearm_lane_allows_low_targets(manager, attacker, fid_filt, fd_filt, true):
			return targetable
	var out: Array = []
	for p in targetable:
		if p == "left_leg" or p == "right_leg":
			continue
		out.append(p)
	return out if not out.is_empty() else targetable
