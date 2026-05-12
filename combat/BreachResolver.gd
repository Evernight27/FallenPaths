class_name BreachResolver
extends RefCounted

## Hold vs drive for crash / breach (docs/TACTICAL_ZONES_BREACH_MOVEMENT.md — incursion plan Phase C). No continuous (x,y).
## Layer A (formation): drive from reach vs spacing, strength, stamina, stance; hold from defender body + front ZoC + density + ambush.
## On success, CombatManager sets attacker `tactical_penetration_depth` and defender `formation.breached_files[file]`.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _IntrusionGeometry := preload("res://combat/CombatIntrusionGeometry.gd")

static func clamp_tactical_penetration_depth(depth: int) -> int:
	return mini(maxi(0, depth), CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX)

static func contest_crash(manager: Node, attacker_id: int, defender_id: int) -> Dictionary:
	var out: Dictionary = {
		"ok": false,
		"tactical_penetration_depth": 0,
		"breach_severity": 0.0,
		"defender_file": -1,
		"defender_formation_id": "",
		"drive": 0.0,
		"hold": 0.0,
	}
	if manager == null or not manager.has_method("_get_by_id"):
		return out
	var atk: Dictionary = _EntityAccess.combatant_dict_or_empty(manager._get_by_id(attacker_id))
	var def: Dictionary = _EntityAccess.combatant_dict_or_empty(manager._get_by_id(defender_id))
	if atk.is_empty() or def.is_empty():
		return out
	if not _EntityAccess.alive_bool(atk) or not _EntityAccess.alive_bool(def):
		return out
	if _EntityAccess.side_str(atk) == _EntityAccess.side_str(def):
		return out
	if _EntityAccess.is_incapacitated(atk) or _EntityAccess.is_incapacitated(def):
		return out
	var old_depth: int = _EntityAccess.tactical_penetration_depth_int(atk)
	var fid_geom: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, def)
	var formation_def: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, def, fid_geom)
	if old_depth >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		out["tactical_penetration_depth"] = old_depth
		out["defender_file"] = _EntityAccess.file_int(def)
		out["defender_formation_id"] = fid_geom
		return out

	var weapon = _EntityAccess.get_weapon(atk)
	var melee_range: float = float(weapon.melee_range) if weapon != null else 1.5
	var eff_dist: float = _ActionsBuilder.effective_pair_eff_dist(manager, atk, def)
	var reach_ratio: float = clampf(
		melee_range / maxf(eff_dist, 0.4),
		CombatConstants.CRASH_DRIVE_REACH_MIN,
		CombatConstants.CRASH_DRIVE_REACH_MAX
	)
	var str_a: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
	var st_atk: float = _EntityAccess.stamina_float(atk)
	var drive: float = str_a * CombatConstants.stamina_factor(st_atk / CombatConstants.STAMINA_MAX) * reach_ratio
	drive *= CombatConstants.get_stance_modifier(_EntityAccess.stance_str(atk), "close_attempt")

	var zc: Dictionary = _FormationSlots.formation_nested_dictionary_read(formation_def, "zone_control")
	var front_z: float = clampf(float(zc.get(_ZoneOfControl.ZONE_FRONT, 0.55)), 0.12, 1.0)

	var str_d: float = float(_EntityAccess.stats_dict(def).get("strength", 100))
	var agi_d: float = float(_EntityAccess.stats_dict(def).get("agility", 100))
	var st_def: float = _EntityAccess.stamina_float(def)
	var hold_body: float = (str_d * 0.52 + agi_d * 0.48) * CombatConstants.stamina_factor(st_def / CombatConstants.STAMINA_MAX)
	hold_body *= CombatConstants.get_stance_modifier(_EntityAccess.stance_str(def), "evasion")
	var density: String = str(formation_def.get("density", "normal"))
	hold_body *= CombatConstants.get_density_close_mod(density)
	hold_body *= _TacticalCombat.ambush_defense_multiplier(manager, def)
	var zoc_hold: float = CombatConstants.CRASH_HOLD_BODY_REF * front_z * CombatConstants.CRASH_HOLD_ZOC_WEIGHT
	var neighbor_hold: float = _IntrusionGeometry.crash_neighbor_hold_support(manager, def, formation_def)
	var hold: float = hold_body + zoc_hold + neighbor_hold

	var denom: float = drive + maxf(hold, 1.0)
	var p_win: float = clampf(drive / denom, CombatConstants.CRASH_SUCCESS_P_MIN, CombatConstants.CRASH_SUCCESS_P_MAX)
	var roll: float
	if CombatConstants.has_queued_breach_crash_roll():
		roll = CombatConstants.take_queued_breach_crash_roll()
	else:
		if CombatConstants.is_incursion_breach_harness_active():
			CombatConstants.warn_crash_test_roll_queue_exhausted_once()
		roll = randf()
	var ok: bool = roll < p_win

	out["drive"] = drive
	out["hold"] = hold
	out["defender_formation_id"] = fid_geom
	out["defender_file"] = _EntityAccess.file_int(def)
	out["ok"] = ok
	if ok:
		out["tactical_penetration_depth"] = clamp_tactical_penetration_depth(old_depth + 1)
		var margin: float = clampf((drive - hold) / maxf(denom, 0.001), -0.55, 0.55)
		var sev: float = 0.44 + margin * 0.85 + (reach_ratio - 1.0) * 0.1
		out["breach_severity"] = clampf(sev, 0.35, 1.0)
	else:
		out["tactical_penetration_depth"] = old_depth
		out["breach_severity"] = 0.0
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"contest_crash atk=%d def=%d ok=%s p_win=%.3f roll=%.3f drive=%.2f hold=%.2f reach_ratio=%.3f eff_dist=%.2f melee_range=%.2f front_z=%.3f old_depth=%d new_depth=%d sev=%.2f file=%d fid=%s"
			% [
				attacker_id,
				defender_id,
				ok,
				p_win,
				roll,
				drive,
				hold,
				reach_ratio,
				eff_dist,
				melee_range,
				front_z,
				old_depth,
				int(out["tactical_penetration_depth"]),
				float(out["breach_severity"]),
				int(out["defender_file"]),
				fid_geom
			]
		)
	return out
