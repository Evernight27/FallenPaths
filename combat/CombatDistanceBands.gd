class_name CombatDistanceBands
extends RefCounted

## MID/LONG/CLOSE bands from rank, `effective_pair_eff_dist`, `effective_pair_file_spacing_equivalent`, ZoC `mid_reach_files`, and weapon reach.

const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")


static func update_distance_to_from_formations(manager: Node) -> void:
	for c in manager.combatants:
		if not c.has("distance_to"):
			c.distance_to = {}
		var our_rank: int = c.get("rank", 0)
		for opp in manager.combatants:
			if opp.side == c.side or not opp.alive:
				continue
			var opp_rank: int = opp.get("rank", 0)
			# Intruders sit on host depth ranks but still contest the broken front line vs host rank-0.
			var c_intruded_on_host_opp: bool = (
				str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
				and str(opp.get("formation_id", "")) == str(c.get("intrusion_host_fid", ""))
			)
			if our_rank > 0 and not c_intruded_on_host_opp:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_LONG
				continue
			var cur: String = c.distance_to.get(opp.id, CombatConstants.DISTANCE_MID)
			if cur == CombatConstants.DISTANCE_CLOSE:
				continue
			var opp_intruded_on_host_c: bool = (
				str(opp.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
				and str(c.get("formation_id", "")) == str(opp.get("intrusion_host_fid", ""))
			)
			if opp_rank > 0 and not opp_intruded_on_host_c:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_LONG
				continue
			var mid_reach: int = _ZoneOfControl.mid_reach_files(manager, c, opp)
			var eff_dist: float = _ActionsBuilder.effective_pair_eff_dist(manager, c, opp)
			var reach_here: float = maxf(_ActionsBuilder.melee_weapon_reach(c), _ActionsBuilder.melee_weapon_reach(opp))
			var eff_files: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(manager, c, opp)
			var within_mid_files: bool = eff_files <= float(mid_reach) + CombatConstants.DIST_BAND_MID_FILE_EQUIV_SLACK
			if within_mid_files and reach_here >= eff_dist:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_MID
			else:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_LONG
	for c in manager.combatants:
		for opp in manager.combatants:
			if opp.side == c.side or not opp.alive:
				continue
			if c.distance_to.get(opp.id, "") == CombatConstants.DISTANCE_CLOSE:
				opp.distance_to[c.id] = CombatConstants.DISTANCE_CLOSE
