class_name CombatDistanceBands
extends RefCounted

## MID/LONG/CLOSE bands from rank, `effective_pair_eff_dist`, `effective_pair_file_spacing_equivalent`, ZoC `mid_reach_files`, and weapon reach.
## Strike eligibility vs a pair at MID also requires `AvailableActionsBuilder` geometric check (`melee_range >= effective_pair_eff_dist`); not only `REACH_MID_MIN`.
## Depth-polearm lane gate (`depth_polearm_lane_open`) is computed **once per combatant** per pass (O(n²) → O(n) for that predicate).

const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


## Per-alive-combatant snapshot of **`AvailableActionsBuilder.depth_polearm_lane_open`** ( **`formation_id_for_zone_geometry`** `fid` ) — same keys as used inside **`update_distance_to_from_formations`**.
static func depth_polearm_lane_open_by_combatant_id(manager: Node) -> Dictionary:
	var depth_lane_ok_by_id: Dictionary = {}
	for cc in manager.combatants:
		if not _EntityAccess.alive_bool(cc):
			continue
		var ccid: int = _EntityAccess.id_int(cc)
		if _EntityAccess.rank_int(cc) <= 0:
			depth_lane_ok_by_id[ccid] = false
			continue
		var fid_cc: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, cc)
		depth_lane_ok_by_id[ccid] = _ActionsBuilder.depth_polearm_lane_open(manager, cc, fid_cc)
	return depth_lane_ok_by_id


static func update_distance_to_from_formations(manager: Node) -> void:
	var depth_lane_ok_by_id: Dictionary = depth_polearm_lane_open_by_combatant_id(manager)
	for c in manager.combatants:
		var d_to: Dictionary = _EntityAccess.nested_dictionary_for_mutation(c, "distance_to")
		var our_rank: int = _EntityAccess.rank_int(c)
		for opp in manager.combatants:
			if _EntityAccess.side_str(opp) == _EntityAccess.side_str(c) or not _EntityAccess.alive_bool(opp):
				continue
			var oid: int = _EntityAccess.id_int(opp)
			var opp_rank: int = _EntityAccess.rank_int(opp)
			# Intruders sit on host depth ranks but still contest the broken front line vs host rank-0.
			var c_intruded_on_host_opp: bool = _ZoneOfControl.intruder_contests_home_line_fighter(c, opp)
			if our_rank > 0 and not c_intruded_on_host_opp:
				if not bool(depth_lane_ok_by_id.get(_EntityAccess.id_int(c), false)):
					d_to[oid] = CombatConstants.DISTANCE_LONG
					continue
			var cur: String = str(d_to.get(oid, CombatConstants.DISTANCE_MID))
			if cur == CombatConstants.DISTANCE_CLOSE:
				continue
			var opp_intruded_on_host_c: bool = _ZoneOfControl.intruder_contests_home_line_fighter(opp, c)
			# Mirror depth-polearm exception on our side: rank-1+ enemy with open spear lane still
			# participates in MID/LONG geometry vs our rank-0 (Tier 1.9 band ↔ action coherence).
			if opp_rank > 0 and not opp_intruded_on_host_c:
				if not bool(depth_lane_ok_by_id.get(oid, false)):
					d_to[oid] = CombatConstants.DISTANCE_LONG
					continue
			var mid_reach: int = _ZoneOfControl.mid_reach_files(manager, c, opp)
			var eff_dist: float = _ActionsBuilder.effective_pair_eff_dist(manager, c, opp)
			var reach_here: float = maxf(_ActionsBuilder.melee_weapon_reach(c), _ActionsBuilder.melee_weapon_reach(opp))
			var eff_files: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(manager, c, opp)
			var within_mid_files: bool = eff_files <= float(mid_reach) + CombatConstants.DIST_BAND_MID_FILE_EQUIV_SLACK
			if within_mid_files and reach_here >= eff_dist:
				d_to[oid] = CombatConstants.DISTANCE_MID
			else:
				# (C) Attacker reach already covers geometric separation — treat as mid so strike
				# Promote to MID when attacker's reach alone covers separation (keeps bands aligned with `can_melee_threaten` / action list).
				var atk_reach_only: float = _ActionsBuilder.melee_weapon_reach(c)
				if atk_reach_only + 1e-4 >= eff_dist:
					d_to[oid] = CombatConstants.DISTANCE_MID
				else:
					d_to[oid] = CombatConstants.DISTANCE_LONG
	for c in manager.combatants:
		var cid2: int = _EntityAccess.id_int(c)
		for opp in manager.combatants:
			if _EntityAccess.side_str(opp) == _EntityAccess.side_str(c) or not _EntityAccess.alive_bool(opp):
				continue
			var oid2: int = _EntityAccess.id_int(opp)
			if _EntityAccess.nested_dictionary_for_mutation(c, "distance_to").get(oid2, "") == CombatConstants.DISTANCE_CLOSE:
				_EntityAccess.nested_dictionary_for_mutation(opp, "distance_to")[cid2] = CombatConstants.DISTANCE_CLOSE
