class_name CombatRegressionHarnessProficiency1v1Tail
extends RefCounted

## Standalone 1v1 proficiency test harness for combat number tuning.
## Runs full attack cycles between two combatants and reports per-stat gains.
## Usage: call run() from CombatRegressionHarness.run_all() or invoke directly.
## Tuning: call run_tuning_all() for full report, then adjust gain constants
## in EntityProficiency.gd (GAIN_MELEE_HIT_BASE, GAIN_STRIKE_ATTEMPTED_BASE, etc.).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _Harness := preload("res://harness/CombatRegressionHarness.gd")
const _Fixtures := preload("res://harness/HarnessFixtures.gd")


## Per-stat proficiency bonuses for a CoreEntity. Returns {stat: float}.
static func get_proficiency_snapshot(entity: Node) -> Dictionary:
	if entity == null:
		return {}
	var pb = entity.get("_proficiency_bonus")
	if pb == null or typeof(pb) != TYPE_DICTIONARY:
		return {}
	var snapshot: Dictionary = {}
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		snapshot[stat] = float(pb.get(stat, 0))
	return snapshot


## Diff between two proficiency snapshots. Returns {stat: delta}.
static func get_gains_snapshot(before: Dictionary, after: Dictionary) -> Dictionary:
	var gains := {}
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		gains[stat] = after.get(stat, 0.0) - before.get(stat, 0.0)
	return gains


## Creates a 1v1 manager with two entities.
static func setup_1v1(
	weapon_id: String = "SWORD",
	player_stats: Dictionary = {"strength": 120, "agility": 100, "intelligence": 110, "endurance": 110, "perception": 95},
	enemy_stats: Dictionary = {"strength": 100, "agility": 100, "intelligence": 100, "endurance": 100, "perception": 100}
) -> Dictionary:
	var mgr := _MgrScript.new()

	var p_ent: Node = _new_entity(weapon_id)
	for stat in player_stats:
		p_ent.set(stat, int(player_stats[stat]))
	mgr.register(p_ent, "player")

	var e_ent: Node = _new_entity(weapon_id)
	for stat in enemy_stats:
		e_ent.set(stat, int(enemy_stats[stat]))
	mgr.register(e_ent, "enemy")

	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])

	return {
		"mgr": mgr,
		"p_id": p_id,
		"player_ent": p_ent,
		"enemy_ent": e_ent,
	}


## Creates a 1v1 manager with two entities using different weapon types.
static func setup_1v1_mixed_weapons(
	player_weapon: String,
	enemy_weapon: String,
	player_stats: Dictionary = {},
	enemy_stats: Dictionary = {}
) -> Dictionary:
	var mgr := _MgrScript.new()

	var p_ent: Node = _new_entity(player_weapon)
	for stat in player_stats:
		p_ent.set(stat, int(player_stats[stat]))
	mgr.register(p_ent, "player")

	var e_ent: Node = _new_entity(enemy_weapon)
	for stat in enemy_stats:
		e_ent.set(stat, int(enemy_stats[stat]))
	mgr.register(e_ent, "enemy")

	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])

	return {
		"mgr": mgr,
		"p_id": p_id,
		"player_ent": p_ent,
		"enemy_ent": e_ent,
	}


static func _free_1v1(data: Dictionary) -> void:
	if data.is_empty():
		return
	var mgr: Node = data.get("mgr")
	if is_instance_valid(mgr):
		mgr.queue_free()


static func _new_entity(weapon_id: String) -> Node:
	var e := CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	var w: Variant = _Weapon.create_from_definition(weapon_id)
	if w != null:
		e.equip_weapon(w)
	_Fixtures._track_harness_node(e)
	return e


## Reset both combatants to WAITING state with balanced form for next strike.
static func _reset_combatants_to_ready(mgr: Node) -> void:
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		c.state = _CombatConstants.STATE_WAITING
		c["_form_str"] = "balanced"
		c["guard_line"] = "high"


## Execute a single strike from player to enemy.
static func execute_player_strike(
	data: Dictionary,
	move_id: String = "oberhau"
) -> Dictionary:
	var mgr: Node = data.get("mgr")
	var p_id: int = data.get("p_id")

	_reset_combatants_to_ready(mgr)

	var atk: Dictionary = _EntityAccess.manager_get_combatant(mgr, p_id)
	var enemy: Dictionary = _EntityAccess.manager_get_combatant(mgr, 1)
	if atk.is_empty() or enemy.is_empty():
		return {"action": "skip"}
	if not _EntityAccess.alive_bool(atk):
		return {"action": "dead_attacker"}

	atk.state = _CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": 1,
		"intensity": 0.62,
		"attack_type": move_id,
	}

	var result := _AttackResolver.resolve_attack(mgr, p_id)
	_AttackResultApplier.apply_result(mgr, p_id, result)
	return result


## Execute a single strike from enemy to player.
static func execute_enemy_strike(data: Dictionary) -> Dictionary:
	var mgr: Node = data.get("mgr")
	var p_id: int = data.get("p_id")

	_reset_combatants_to_ready(mgr)

	var atk: Dictionary = _EntityAccess.manager_get_combatant(mgr, 1)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(mgr, p_id)
	if atk.is_empty() or tgt.is_empty():
		return {"action": "skip"}
	if not _EntityAccess.alive_bool(atk):
		return {"action": "dead_attacker"}

	atk.state = _CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": p_id,
		"intensity": 0.62,
		"attack_type": "oberhau",
	}

	var result := _AttackResolver.resolve_attack(mgr, 1)
	_AttackResultApplier.apply_result(mgr, 1, result)
	return result


## Execute a full exchange: player strikes enemy, then enemy strikes back.
static func execute_exchange(
	data: Dictionary,
	player_move: String = "oberhau"
) -> Dictionary:
	var p_before := get_proficiency_snapshot(data.get("player_ent"))
	var e_before := get_proficiency_snapshot(data.get("enemy_ent"))

	var player_result := execute_player_strike(data, player_move)
	if player_result.get("action", "") == "dead_attacker":
		return {"player_result": player_result, "error": "attacker_dead"}

	var enemy_result := execute_enemy_strike(data)

	var p_after := get_proficiency_snapshot(data.get("player_ent"))
	var e_after := get_proficiency_snapshot(data.get("enemy_ent"))

	return {
		"player_result": player_result,
		"enemy_result": enemy_result,
		"player_gains": get_gains_snapshot(p_before, p_after),
		"enemy_gains": get_gains_snapshot(e_before, e_after),
		"player_final": p_after,
		"enemy_final": e_after,
	}


## Run N exchange rounds. Each round: player strikes, enemy strikes back.
static func simulate_rounds(
	data: Dictionary,
	num_rounds: int = 5,
	player_move: String = "oberhau"
) -> Dictionary:
	var all_rounds := []
	var cumulative_player_gains := {"strength": 0.0, "agility": 0.0, "intelligence": 0.0, "endurance": 0.0, "perception": 0.0}
	var cumulative_enemy_gains := {"strength": 0.0, "agility": 0.0, "intelligence": 0.0, "endurance": 0.0, "perception": 0.0}

	for i in range(num_rounds):
		var round_result := execute_exchange(data, player_move)
		if round_result.get("error") == "attacker_dead":
			break
		all_rounds.append(round_result)

		for stat in cumulative_player_gains:
			cumulative_player_gains[stat] += round_result.get("player_gains", {}).get(stat, 0.0)
		for stat in cumulative_enemy_gains:
			cumulative_enemy_gains[stat] += round_result.get("enemy_gains", {}).get(stat, 0.0)

	return {
		"rounds": all_rounds,
		"total_rounds_played": all_rounds.size(),
		"cumulative_player_gains": cumulative_player_gains,
		"cumulative_enemy_gains": cumulative_enemy_gains,
		"player_final": get_proficiency_snapshot(data.get("player_ent")),
		"enemy_final": get_proficiency_snapshot(data.get("enemy_ent")),
	}


# --- Tuning report formatters ---

static func format_report(result: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("--- Proficiency 1v1 Report ---")
	lines.append("Rounds played: %d" % result.get("total_rounds_played", 0))
	lines.append("")

	var pgains: Dictionary = result.get("cumulative_player_gains", {})
	var egains: Dictionary = result.get("cumulative_enemy_gains", {})

	lines.append("Player cumulative gains:")
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		lines.append("  %s: +%.3f" % [stat, pgains.get(stat, 0.0)])
	lines.append("")

	lines.append("Enemy cumulative gains:")
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		lines.append("  %s: +%.3f" % [stat, egains.get(stat, 0.0)])
	lines.append("")

	var pfinal: Dictionary = result.get("player_final", {})
	var efinal: Dictionary = result.get("enemy_final", {})

	lines.append("Player final bonuses:")
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		lines.append("  %s: %.3f" % [stat, pfinal.get(stat, 0.0)])
	lines.append("")

	lines.append("Enemy final bonuses:")
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		lines.append("  %s: %.3f" % [stat, efinal.get(stat, 0.0)])

	return "\n".join(lines)


static func format_round_details(result: Dictionary) -> String:
	var lines := PackedStringArray()
	var rounds: Array = result.get("rounds", [])

	if rounds.is_empty():
		lines.append("(no rounds played)")
		return "\n".join(lines)

	for i in range(rounds.size()):
		var r: Dictionary = rounds[i]
		lines.append("--- Round %d ---" % (i + 1))
		lines.append("  Player action: %s" % r.get("player_result", {}).get("action", "unknown"))
		lines.append("  Enemy action: %s" % r.get("enemy_result", {}).get("action", "unknown"))

		var pg: Dictionary = r.get("player_gains", {})
		var eg: Dictionary = r.get("enemy_gains", {})
		lines.append("  Player gains: STR+%.3f AGI+%.3f END+%.3f" % [
			pg.get("strength", 0.0), pg.get("agility", 0.0), pg.get("endurance", 0.0)
		])
		lines.append("  Enemy gains: STR+%.3f AGI+%.3f END+%.3f" % [
			eg.get("strength", 0.0), eg.get("agility", 0.0), eg.get("endurance", 0.0)
		])

	return "\n".join(lines)


# --- Tuning scenarios ---

static func _ensure_proficiency_on() -> void:
	_CompanyState.PROFICIENCY_ENABLED = true


static func run_balanced_1v1() -> Dictionary:
	_ensure_proficiency_on()
	var data := setup_1v1("SWORD", {}, {})
	var result := simulate_rounds(data, 5)
	_free_1v1(data)
	return result


static func run_str_heavy_player() -> Dictionary:
	_ensure_proficiency_on()
	var data := setup_1v1(
		"SWORD",
		{"strength": 150, "agility": 80, "intelligence": 90, "endurance": 120, "perception": 85},
		{}
	)
	var result := simulate_rounds(data, 5)
	_free_1v1(data)
	return result


static func run_agi_heavy_player() -> Dictionary:
	_ensure_proficiency_on()
	var data := setup_1v1(
		"SWORD",
		{"strength": 80, "agility": 150, "intelligence": 90, "endurance": 90, "perception": 120},
		{}
	)
	var result := simulate_rounds(data, 5)
	_free_1v1(data)
	return result


static func run_spear_vs_sword() -> Dictionary:
	_ensure_proficiency_on()
	var data := setup_1v1_mixed_weapons("SPEAR", "SWORD", {}, {})
	var result := simulate_rounds(data, 5, "spear_thrust")
	_free_1v1(data)
	return result


static func run_mace_vs_sword() -> Dictionary:
	_ensure_proficiency_on()
	var data := setup_1v1("MACE", {}, {})
	var result := simulate_rounds(data, 5)
	_free_1v1(data)
	return result


static func run_low_perception_player() -> Dictionary:
	_ensure_proficiency_on()
	var data := setup_1v1(
		"SWORD",
		{"strength": 100, "agility": 100, "intelligence": 80, "endurance": 90, "perception": 60},
		{}
	)
	var result := simulate_rounds(data, 5)
	_free_1v1(data)
	return result


# --- Main run entry (for harness integration) ---

static func run(failures: PackedStringArray) -> void:
	var scenarios := {
		"balanced_1v1": run_balanced_1v1,
		"str_heavy_player": run_str_heavy_player,
		"agi_heavy_player": run_agi_heavy_player,
		"spear_vs_sword": run_spear_vs_sword,
		"mace_vs_sword": run_mace_vs_sword,
		"low_perception": run_low_perception_player,
	}

	for name in scenarios:
		var runner: Callable = scenarios[name]
		var result: Dictionary = runner.call()
		var total_rounds: int = result.get("total_rounds_played", 0)
		if total_rounds == 0:
			_Harness._fail(failures, "proficiency_1v1_%s: no rounds played" % name)
			continue

		var pgains: Dictionary = result.get("cumulative_player_gains", {})
		var total_gain := 0.0
		for stat in pgains:
			total_gain += absf(pgains[stat])

		if total_gain < 0.1:
			_Harness._fail(
				failures,
				"proficiency_1v1_%s: player gains too low (%.3f over %d rounds)"
				% [name, total_gain, total_rounds]
			)


## Run all scenarios and print report output (for manual tuning).
static func run_tuning_all() -> Dictionary:
	var reports := {}

	var scenarios := {
		"balanced": run_balanced_1v1,
		"str_heavy": run_str_heavy_player,
		"agi_heavy": run_agi_heavy_player,
		"spear_vs_sword": run_spear_vs_sword,
		"mace_vs_sword": run_mace_vs_sword,
		"low_perception": run_low_perception_player,
	}

	for name in scenarios:
		var runner: Callable = scenarios[name]
		var result: Dictionary = runner.call()
		reports[name] = format_report(result)
		print("--- Tuning report: %s ---" % name)
		print(reports[name])

	return reports
