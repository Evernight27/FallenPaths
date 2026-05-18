class_name CombatMeleeRankTargeting
extends RefCounted

## Melee rank / intrusion gates shared by action listing and crash diagnostics.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")


static func melee_pair_rank_allowed(manager: Node, attacker: Dictionary, defender: Dictionary) -> bool:
	var ar: int = _EntityAccess.rank_int(attacker)
	var dr: int = _EntityAccess.rank_int(defender)
	var ai: bool = _ZoneOfControl.is_intruded(attacker)
	var di: bool = _ZoneOfControl.is_intruded(defender)
	if ar == 0 and dr == 0 and not ai and not di:
		return true
	if ai and _ZoneOfControl.intruder_contests_home_line_fighter(attacker, defender) and dr == 0:
		return true
	if di and _ZoneOfControl.intruder_contests_home_line_fighter(defender, attacker):
		return true
	if manager != null and ar > 0 and not ai and dr == 0 and not di:
		return _DepthPolearm.depth_polearm_valid_line_threat(manager, attacker, defender)
	return false


static func opp_matches_melee_rank_target(
	manager: Node, actor: Dictionary, opp: Dictionary, opp_rank_required: int
) -> bool:
	if not _EntityAccess.is_living_hostile_to(actor, opp):
		return false
	var host_fid: String = _DepthPolearm.actor_host_fid_for_melee_targeting(actor, manager)
	var ornk: int = _EntityAccess.rank_int(opp)
	var opp_intr_on_actor_host: bool = _ZoneOfControl.intruder_on_host_formation(opp, host_fid)
	if ornk == opp_rank_required:
		if (
			opp_rank_required == 0
			and _EntityAccess.rank_int(actor) > 0
			and not _ZoneOfControl.is_intruded(actor)
			and not opp_intr_on_actor_host
		):
			if manager == null or not _DepthPolearm.depth_polearm_valid_line_threat(manager, actor, opp):
				return false
		return true
	if opp_rank_required <= 1 and opp_intr_on_actor_host:
		return true
	return false


## True when any opponent passes **`opp_matches_melee_rank_target(..., 0)`** (stalemate rank-1 pass when all front enemies are incap).
static func any_living_enemy_rank0_target(
	manager: Node, actor: Dictionary, combatants: Array
) -> bool:
	for opp in combatants:
		if opp_matches_melee_rank_target(manager, actor, opp, 0):
			return true
	return false


static func host_formation_has_enemy_intruder(
	manager: Node, combatants: Array, actor: Dictionary
) -> bool:
	if _ZoneOfControl.is_intruded(actor):
		return false
	var fid: String = _DepthPolearm.actor_host_fid_for_melee_targeting(actor, manager)
	if fid.is_empty():
		return false
	for x in combatants:
		if not _EntityAccess.is_alive_opponent_of(actor, x):
			continue
		if _ZoneOfControl.intruder_on_host_formation(x, fid):
			return true
	return false
