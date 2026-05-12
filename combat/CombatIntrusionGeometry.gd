class_name CombatIntrusionGeometry
extends RefCounted

## Gap / intrusion helpers: neighbor support into crash hold today; intruder eff distance + slots later.
## See docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")


## Extra hold (same units as BreachResolver body+ZoC) from adjacent rank-0 allies on defender's **host** file line (`formation_id_for_zone_geometry`).
static func crash_neighbor_hold_support(manager: Node, defender: Dictionary, formation_def: Dictionary) -> float:
	if manager == null or defender.is_empty() or formation_def.is_empty():
		return 0.0
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, defender)
	if fid.is_empty():
		return 0.0
	var f0: int = _EntityAccess.file_int(defender)
	var did: int = _EntityAccess.id_int(defender)
	var bonus: float = 0.0
	var added: int = 0
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _ZoneOfControl.formation_id_for_zone_geometry(manager, c) != fid:
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		if _EntityAccess.id_int(c, -2) == did:
			continue
		if abs(_EntityAccess.file_int(c) - f0) != 1:
			continue
		var w = _EntityAccess.get_weapon(c)
		var reach_m: float = float(w.melee_range) if w != null else 1.5
		var reach_sc: float = clampf(reach_m / maxf(0.5, CombatConstants.CRASH_NEIGHBOR_REACH_REF_M), 0.72, 1.38)
		bonus += CombatConstants.CRASH_NEIGHBOR_HOLD_BASE * reach_sc
		added += 1
		if added >= CombatConstants.CRASH_NEIGHBOR_MAX_COUNT:
			break
	return bonus
