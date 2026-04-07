class_name CombatDistanceBands
extends RefCounted

## MID/LONG/CLOSE bands from rank, file spacing, ZoC mid_reach, and weapon reach.

const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")


static func update_distance_to_from_formations(manager: Node) -> void:
	for c in manager.combatants:
		if not c.has("distance_to"):
			c.distance_to = {}
		var our_rank: int = c.get("rank", 0)
		var our_file: int = c.get("file", 0)
		for opp in manager.combatants:
			if opp.side == c.side or not opp.alive:
				continue
			var opp_rank: int = opp.get("rank", 0)
			var opp_file: int = opp.get("file", 0)
			if our_rank > 0:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_LONG
				continue
			var cur: String = c.distance_to.get(opp.id, CombatConstants.DISTANCE_MID)
			if cur == CombatConstants.DISTANCE_CLOSE:
				continue
			if opp_rank > 0:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_LONG
				continue
			var df: int = int(absf(float(our_file - opp_file)))
			var mid_reach: int = _ZoneOfControl.mid_reach_files(manager, c, opp)
			var eff_dist: float = _ActionsBuilder.effective_pair_eff_dist(manager, c, opp)
			var reach_here: float = maxf(_ActionsBuilder.melee_weapon_reach(c), _ActionsBuilder.melee_weapon_reach(opp))
			if df <= mid_reach and reach_here >= eff_dist:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_MID
			else:
				c.distance_to[opp.id] = CombatConstants.DISTANCE_LONG
	for c in manager.combatants:
		for opp in manager.combatants:
			if opp.side == c.side or not opp.alive:
				continue
			if c.distance_to.get(opp.id, "") == CombatConstants.DISTANCE_CLOSE:
				opp.distance_to[c.id] = CombatConstants.DISTANCE_CLOSE
