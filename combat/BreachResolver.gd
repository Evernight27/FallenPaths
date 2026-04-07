class_name BreachResolver
extends RefCounted

## Hold vs drive for crash / breach (docs/TACTICAL_ZONES_BREACH_MOVEMENT.md — incursion plan Phase C). No continuous (x,y).
## Layer A (formation): drive from reach vs spacing, strength, stamina, stance; hold from defender body + front ZoC + density + ambush.
## On success, CombatManager sets attacker `tactical_penetration_depth` and defender `formation.breached_files[file]`.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")

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
	var atk: Dictionary = manager._get_by_id(attacker_id)
	var def: Dictionary = manager._get_by_id(defender_id)
	if atk.is_empty() or def.is_empty():
		return out
	if not atk.get("alive", false) or not def.get("alive", false):
		return out
	if atk.get("side", "") == def.get("side", ""):
		return out
	if _EntityAccess.is_incapacitated(atk) or _EntityAccess.is_incapacitated(def):
		return out
	var old_depth: int = int(atk.get("tactical_penetration_depth", 0))
	if old_depth >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		out["tactical_penetration_depth"] = old_depth
		out["defender_file"] = int(def.get("file", 0))
		out["defender_formation_id"] = str(def.get("formation_id", ""))
		return out

	var weapon = _EntityAccess.get_weapon(atk)
	var melee_range: float = float(weapon.melee_range) if weapon != null else 1.5
	var eff_dist: float = _ActionsBuilder.effective_pair_eff_dist(manager, atk, def)
	var reach_ratio: float = clampf(
		melee_range / maxf(eff_dist, 0.4),
		CombatConstants.CRASH_DRIVE_REACH_MIN,
		CombatConstants.CRASH_DRIVE_REACH_MAX
	)
	var str_a: float = float(atk.stats.get("strength", 100))
	var st_atk: float = float(atk.get("stamina", CombatConstants.STAMINA_MAX))
	var drive: float = str_a * CombatConstants.stamina_factor(st_atk / CombatConstants.STAMINA_MAX) * reach_ratio
	drive *= CombatConstants.get_stance_modifier(str(atk.get("stance", CombatConstants.STANCE_BALANCED)), "close_attempt")

	var fid_def: String = str(def.get("formation_id", ""))
	var fm: Variant = manager.get("formations")
	var formation_def: Dictionary = {}
	if fm != null and typeof(fm) == TYPE_DICTIONARY:
		formation_def = (fm as Dictionary).get(fid_def, {})
	var zc: Dictionary = formation_def.get("zone_control", {})
	var front_z: float = clampf(float(zc.get(_ZoneOfControl.ZONE_FRONT, 0.55)), 0.12, 1.0)

	var str_d: float = float(def.stats.get("strength", 100))
	var agi_d: float = float(def.stats.get("agility", 100))
	var st_def: float = float(def.get("stamina", CombatConstants.STAMINA_MAX))
	var hold_body: float = (str_d * 0.52 + agi_d * 0.48) * CombatConstants.stamina_factor(st_def / CombatConstants.STAMINA_MAX)
	hold_body *= CombatConstants.get_stance_modifier(str(def.get("stance", CombatConstants.STANCE_BALANCED)), "evasion")
	var density: String = str(formation_def.get("density", "normal"))
	hold_body *= CombatConstants.get_density_close_mod(density)
	hold_body *= _TacticalCombat.ambush_defense_multiplier(manager, def)
	var zoc_hold: float = CombatConstants.CRASH_HOLD_BODY_REF * front_z * CombatConstants.CRASH_HOLD_ZOC_WEIGHT
	var hold: float = hold_body + zoc_hold

	var denom: float = drive + maxf(hold, 1.0)
	var p_ok: float = clampf(drive / denom, CombatConstants.CRASH_SUCCESS_P_MIN, CombatConstants.CRASH_SUCCESS_P_MAX)
	var ok: bool = randf() < p_ok

	out["drive"] = drive
	out["hold"] = hold
	out["defender_formation_id"] = fid_def
	out["defender_file"] = int(def.get("file", 0))
	out["ok"] = ok
	if ok:
		out["tactical_penetration_depth"] = clamp_tactical_penetration_depth(old_depth + 1)
		var margin: float = clampf((drive - hold) / maxf(denom, 0.001), -0.55, 0.55)
		var sev: float = 0.44 + margin * 0.85 + (reach_ratio - 1.0) * 0.1
		out["breach_severity"] = clampf(sev, 0.35, 1.0)
	else:
		out["tactical_penetration_depth"] = old_depth
		out["breach_severity"] = 0.0
	return out
