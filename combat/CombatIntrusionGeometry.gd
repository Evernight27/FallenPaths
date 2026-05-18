class_name CombatIntrusionGeometry
extends RefCounted

## Gap / intrusion helpers: neighbor support into crash hold today; intruder eff distance + slots later.
## See docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")


## Extra hold (same units as BreachResolver body+ZoC) from adjacent rank-0 allies on defender's **host** file line (`zone_geometry_fid_str` / `combatant_on_zone_geometry_fid`).
static func crash_neighbor_hold_support(manager: Node, defender: Dictionary, formation_def: Dictionary) -> float:
	if manager == null or defender.is_empty() or formation_def.is_empty():
		return 0.0
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(manager, defender)
	if fid.is_empty():
		return 0.0
	var f0: int = _EntityAccess.file_int(defender)
	var did: int = _EntityAccess.id_int(defender)
	var line_side: String = _FormationSlots.formation_side_str(formation_def)
	if line_side.is_empty():
		line_side = _EntityAccess.side_str(defender)
	var bonus: float = 0.0
	var added: int = 0
	for c in manager.combatants:
		if not _EntityAccess.is_living_on_side(c, line_side):
			continue
		if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, fid):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _EntityAccess.id_int(c, -2) == did:
			continue
		if abs(_EntityAccess.file_int(c) - f0) != 1:
			continue
		var reach_m: float = _EntityAccess.weapon_melee_reach(c)
		var reach_sc: float = clampf(reach_m / maxf(0.5, CombatConstants.CRASH_NEIGHBOR_REACH_REF_M), 0.72, 1.38)
		bonus += CombatConstants.CRASH_NEIGHBOR_HOLD_BASE * reach_sc
		added += 1
		if added >= CombatConstants.CRASH_NEIGHBOR_MAX_COUNT:
			break
	return bonus
