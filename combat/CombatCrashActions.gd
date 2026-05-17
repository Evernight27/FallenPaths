class_name CombatCrashActions
extends RefCounted

## Breach rush (`MOVE_ID_CRASH`) listing gates and player UI reason strings.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")


static func crash_action_eligible(
	manager: Node,
	c: Dictionary,
	_opp: Dictionary,
	in_swing_range: bool,
	dist: String
) -> bool:
	if _EntityAccess.rank_int(c) != 0:
		return false
	if _ZoneOfControl.is_intruded(c):
		return false
	if not _EngagementMode.crash_intrusion_attacker_allowed(manager, c):
		return false
	if not _EngagementMode.incursion_allowed(manager):
		return false
	if _EntityAccess.tactical_penetration_depth_int(c) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		return false
	if _EntityAccess.stamina_float(c, 0.0) < CombatConstants.CRASH_STAMINA_COST:
		return false
	var clock: float = 0.0
	if manager != null:
		var cc: Variant = manager.get("combat_clock")
		if cc != null:
			clock = float(cc)
	if clock < float(c.get("crash_cooldown_until", 0.0)):
		return false
	if not in_swing_range:
		return false
	return dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID


static func crash_absent_primary_reason(manager: Node, c: Dictionary) -> String:
	var block: String = _EngagementMode.crash_intrusion_attacker_block_reason(manager, c)
	if not block.is_empty():
		return block
	if not _EngagementMode.incursion_allowed(manager):
		var mode_now: String = _EngagementMode.engagement_mode(manager)
		return "engagement_mode_%s" % mode_now
	if _EntityAccess.tactical_penetration_depth_int(c) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		return "at_max_penetration_depth"
	if _EntityAccess.stamina_float(c, 0.0) < CombatConstants.CRASH_STAMINA_COST:
		return "low_stamina"
	var clock: float = 0.0
	if manager != null:
		var cc: Variant = manager.get("combat_clock")
		if cc != null:
			clock = float(cc)
	if clock < float(c.get("crash_cooldown_until", 0.0)):
		return "crash_cooldown"
	var weapon = _EntityAccess.get_weapon(c)
	if not _EntityAccess.weapon_has_attack_types(weapon):
		return "no_melee_weapon_profile"
	var melee_range: float = float(weapon.melee_range)
	var fid_c: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
	var fc: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_c)
	var any_enemy_rank0: bool = false
	for opp in manager.combatants:
		if _MeleeRank.opp_matches_melee_rank_target(manager, c, opp, 0):
			any_enemy_rank0 = true
			break
	var ranks_to_check: Array = [0] if any_enemy_rank0 else [1]
	var saw_line_enemy: bool = false
	var first_reason: String = ""
	for rank_req in ranks_to_check:
		for opp in manager.combatants:
			if not _MeleeRank.opp_matches_melee_rank_target(manager, c, opp, rank_req):
				continue
			saw_line_enemy = true
			var fid_o: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, opp)
			var fo: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, opp, fid_o)
			var eff_dist: float = float(
				_PairGeometry.effective_pair_geometry(manager, c, opp, fc, fo).get("eff_dist", 0.0)
			)
			var in_swing: bool = melee_range >= eff_dist
			var dist: String = str(
				_EntityAccess.nested_dictionary_read(c, "distance_to").get(
					_EntityAccess.id_int(opp), CombatConstants.DISTANCE_LONG
				)
			)
			if crash_action_eligible(manager, c, opp, in_swing, dist):
				return "crash_eligible_but_missing_bug"
			if first_reason.is_empty():
				if not in_swing:
					first_reason = "out_of_swing_range"
				elif dist == CombatConstants.DISTANCE_LONG:
					first_reason = "distance_long"
				else:
					first_reason = "distance_band_%s" % dist
	if not saw_line_enemy:
		return "no_front_rank_enemy"
	return first_reason if not first_reason.is_empty() else "unknown"


static func format_crash_absent_reason_for_ui(reason_key: String) -> String:
	var k: String = str(reason_key)
	if k.begins_with("engagement_mode_"):
		var m: String = k.trim_prefix("engagement_mode_")
		return "Breach rush unavailable: %s" % _EngagementMode.mode_display_name(m)
	match k:
		"intrusion_disabled":
			return "Breach rush unavailable: intrusions disabled (development flag)"
		"intruder_cap":
			return "Breach rush unavailable: intruder cap (heavy armor role)"
		"light_armor":
			return "Breach rush unavailable: need heavy armor (mass)"
		"low_breach_power":
			return "Breach rush unavailable: not strong enough for a line breach"
		"at_max_penetration_depth":
			return "Breach rush unavailable: at max penetration depth"
		"low_stamina":
			return "Breach rush unavailable: low stamina"
		"crash_cooldown":
			return "Breach rush unavailable: crash on cooldown"
		"no_melee_weapon_profile":
			return "Breach rush unavailable: no melee weapon"
		"no_front_rank_enemy":
			return "Breach rush unavailable: no valid front target"
		"out_of_swing_range":
			return "Breach rush unavailable: out of weapon reach"
		"distance_long":
			return "Breach rush unavailable: target too far"
		"unknown":
			return "Breach rush unavailable"
		_:
			if k.begins_with("distance_band_"):
				return "Breach rush unavailable: spacing (%s)" % k.trim_prefix("distance_band_")
			return "Breach rush unavailable (%s)" % k
