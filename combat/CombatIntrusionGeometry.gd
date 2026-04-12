class_name CombatIntrusionGeometry
extends RefCounted

## Gap / intrusion helpers: neighbor support into crash hold today; intruder eff distance + slots later.
## See docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


## Extra hold (same units as BreachResolver body+ZoC) from adjacent rank-0 allies on defender's file line.
static func crash_neighbor_hold_support(manager: Node, defender: Dictionary, formation_def: Dictionary) -> float:
	if manager == null or defender.is_empty() or formation_def.is_empty():
		return 0.0
	var fid: String = str(defender.get("formation_id", ""))
	if fid.is_empty():
		return 0.0
	var f0: int = int(defender.get("file", 0))
	var did: int = int(defender.get("id", -1))
	var bonus: float = 0.0
	var added: int = 0
	for c in manager.combatants:
		if not c.get("alive", false):
			continue
		if str(c.get("formation_id", "")) != fid:
			continue
		if int(c.get("rank", 0)) != 0:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		if int(c.get("id", -2)) == did:
			continue
		if abs(int(c.get("file", 0)) - f0) != 1:
			continue
		var w = _EntityAccess.get_weapon(c)
		var reach_m: float = float(w.melee_range) if w != null else 1.5
		var reach_sc: float = clampf(reach_m / maxf(0.5, CombatConstants.CRASH_NEIGHBOR_REACH_REF_M), 0.72, 1.38)
		bonus += CombatConstants.CRASH_NEIGHBOR_HOLD_BASE * reach_sc
		added += 1
		if added >= CombatConstants.CRASH_NEIGHBOR_MAX_COUNT:
			break
	return bonus
