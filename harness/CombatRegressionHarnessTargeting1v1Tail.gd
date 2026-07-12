class_name CombatRegressionHarnessTargeting1v1Tail
extends RefCounted

## 1v1 targeting validation harness for docs/archive/TARGETING_RESEARCH.md soak calibration.
## Runs short (3-exchange) strikes per weapon and logs aim=part distributions.
## Usage: run() from CombatRegressionHarness.run_all() or invoke run_tuning_all() manually.
## Each scenario fires exactly 3 exchanges (player→enemy, enemy→player = 2 attacks each).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _Harness := preload("res://harness/CombatRegressionHarness.gd")
const _Fixtures := preload("res://harness/HarnessFixtures.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")


## Per-exchange hit record.
static func _new_record(move_id: String, aimed_part: String, actual_part: String, outcome: String) -> Dictionary:
	return {
		"move_id": move_id,
		"aimed_part": aimed_part,
		"actual_part": actual_part,
		"outcome": outcome,
	}


## Execute a single strike from combatant `attacker_id` to `target_id`.
static func _execute_strike(
	data: Dictionary,
	attacker_id: int,
	target_id: int,
	move_id: String,
	attack_line: String = ""
) -> Dictionary:
	var mgr: Node = data.get("mgr")
	if not is_instance_valid(mgr):
		return {"error": "invalid_manager"}

	# Reset both combatants to waiting with balanced form.
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		c.state = _CombatConstants.STATE_WAITING
		var _WF := preload("res://combat/CombatWeaponForm.gd")
		_WF.assign_form(mgr, c, _WF.FORM_BALANCED, "harness_baseline")

	var atk: Dictionary = _EntityAccess.manager_get_combatant(mgr, attacker_id)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(mgr, target_id)
	if atk.is_empty() or tgt.is_empty():
		return {"error": "combatants_missing"}
	if not _EntityAccess.alive_bool(atk):
		return {"error": "attacker_dead"}

	var effective_line: String = attack_line
	if effective_line.is_empty():
		effective_line = str(_WeaponConstants.get_move(move_id).get("attack_line", "high")) if attack_line.is_empty() else "high"

	atk.state = _CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": target_id,
		"intensity": 0.62,
		"attack_type": move_id,
	}

	mgr.recompute_zoc_and_distance()

	# Explicitly set distance bands — 1v1 with single-file formations is CLOSE (bind geometry).
	var atk_dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(atk, "distance_to")
	atk_dist[target_id] = CombatConstants.DISTANCE_CLOSE
	var tgt_dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(tgt, "distance_to")
	tgt_dist[attacker_id] = CombatConstants.DISTANCE_CLOSE

	var result := _AttackResolver.resolve_attack(mgr, attacker_id)
	_AttackResultApplier.apply_result(mgr, attacker_id, result)

	return {
		"result_dict": result.get("result_dict", {}),
		"action": result.get("action", "unknown"),
		"target_part": result.get("result_dict", {}).get("target_part", ""),
	}


## Run 3 exchanges: player strikes, enemy strikes back. Collects hit records.
static func _run_targeting_exchange(
	data: Dictionary,
	player_id: int,
	enemy_id: int,
	player_moves: Array = ["thrust", "oberhau", "unterhau"],
	enemy_moves: Array = ["thrust", "oberhau"]
) -> Dictionary:
	var records: Array = []

	for i in range(3):
		# Player → Enemy
		var move_idx: int = i % player_moves.size()
		var p_result := _execute_strike(data, player_id, enemy_id, player_moves[move_idx])
		if not p_result.has("error"):
			var rd: Dictionary = p_result.get("result_dict", {})
			var action_str: String = str(p_result.get("action", "unknown"))
			# On first attack of each scenario, dump diagnostics to help debug
			if i == 0 and action_str != "hit":
				var _diag_mgr := data["mgr"] as Node
				var _diag_atk := _EntityAccess.manager_get_combatant(_diag_mgr, player_id)
				print("[Targeting1v1 diag] move=%s action=%s p_attack_type=%s dist_to=%s" % [
					player_moves[move_idx], action_str,
					str(_diag_atk.pending_attack.get("attack_type", "")),
					str(_EntityAccess.distance_to_opponent_band(_diag_atk, enemy_id))])
			records.append(_new_record(
				player_moves[move_idx],
				str(rd.get("target_part", "")),
				str(rd.get("part", "")),
				action_str
			))

		# Enemy → Player (only if enemy still alive)
		var en: Dictionary = _EntityAccess.manager_get_combatant(data["mgr"], enemy_id)
		if is_instance_valid(en) and _EntityAccess.alive_bool(en):
			var e_result := _execute_strike(data, enemy_id, player_id, enemy_moves[i % enemy_moves.size()])
			# Enemy records don't affect the primary aim=part validation
			# (they're AI vs AI with no proficiency channel)

	return {"records": records, "total_attacks": records.size()}


## Aggregate aim=part distribution from records. Returns {part: count}.
static func _aggregate_aim(records: Array) -> Dictionary:
	var dist := {}
	for r in records:
		var part: String = str(r.get("aimed_part", ""))
		if not part.is_empty():
			dist[part] = dist.get(part, 0) + 1
	return dist


## Aggregate actual hit distribution from records. Returns {part: count}.
static func _aggregate_actual(records: Array) -> Dictionary:
	var dist := {}
	for r in records:
		var part: String = str(r.get("actual_part", ""))
		if not part.is_empty():
			dist[part] = dist.get(part, 0) + 1
	return dist


## Count aim=part matches from records. Returns {"hits": int, "total": int}.
static func _count_matches(records: Array) -> Dictionary:
	var hits := 0
	var total := 0
	for r in records:
		if str(r.get("outcome", "")) == "hit":
			total += 1
			if str(r.get("aimed_part", "")) == str(r.get("actual_part", "")):
				hits += 1
	return {"hits": hits, "total": total}


## Setup a 1v1 manager with given weapons (player only; enemy is unarmed so it can dodge but not parry).
static func _setup_1v1(
	player_weapon: String = "SWORD",
	_enemy_weapon: String = "",
	player_stats: Dictionary = {},
	enemy_stats: Dictionary = {}
) -> Dictionary:
	var mgr := _MgrScript.new()

	var p_ent: Node = CoreEntity.new()
	p_ent.apply_species()
	p_ent.dominant_hand = "right_arm"
	p_ent.offhand_functionality = 1.0
	var pw: Variant = _Weapon.create_from_definition(player_weapon)
	if pw != null:
		p_ent.equip_weapon(pw)
	_Fixtures._track_harness_node(p_ent)
	mgr.register(p_ent, "player")

	var e_ent: Node = CoreEntity.new()
	e_ent.apply_species()
	e_ent.dominant_hand = "right_arm"
	e_ent.offhand_functionality = 1.0
	_Fixtures._track_harness_node(e_ent)
	mgr.register(e_ent, "enemy")

	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

	if player_stats is Dictionary:
		for stat in player_stats:
			p_ent.set(stat, int(player_stats[stat]))
	if enemy_stats is Dictionary:
		for stat in enemy_stats:
			e_ent.set(stat, int(enemy_stats[stat]))

	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])

	return {
		"mgr": mgr,
		"p_id": p_id,
		"e_id": e_id,
		"player_ent": p_ent,
		"enemy_ent": e_ent,
	}


static func _free_1v1(data: Dictionary) -> void:
	if data.is_empty():
		return
	var mgr: Node = data.get("mgr")
	if is_instance_valid(mgr):
		mgr.queue_free()


## Proficiency levels for targeting validation.
const PROF_NOVICE := {"strength": 80, "agility": 70, "intelligence": 60, "endurance": 70, "perception": 50}
const PROF_VETERAN := {"strength": 140, "agility": 130, "intelligence": 120, "endurance": 130, "perception": 110}


# --- Weapon scenarios ---

## SWORD: balanced form, standard move pool.
static func run_sword_balanced() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SWORD", "SWORD", PROF_NOVICE, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["thrust", "oberhau", "unterhau"], ["thrust", "oberhau"])
	_free_1v1(data)
	return _format_scenario_result("SWORD_balanced_novice", result, data)


## SWORD: veteran stats.
static func run_sword_veteran() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SWORD", "SWORD", PROF_VETERAN, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["thrust", "oberhau", "unterhau"], ["thrust", "oberhau"])
	_free_1v1(data)
	return _format_scenario_result("SWORD_balanced_veteran", result, data)


## AXE: head-heavy targeting.
static func run_axe_novice() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("AXE", "AXE", PROF_NOVICE, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["overhead_chop", "diagonal_chop", "spike_thrust"], ["overhead_chop", "poll_strike"])
	_free_1v1(data)
	return _format_scenario_result("AXE_novice", result, data)


## AXE: veteran.
static func run_axe_veteran() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("AXE", "AXE", PROF_VETERAN, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["overhead_chop", "diagonal_chop", "spike_thrust"], ["overhead_chop", "poll_strike"])
	_free_1v1(data)
	return _format_scenario_result("AXE_veteran", result, data)


## MACE: high head rate.
static func run_mace_novice() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("MACE", "MACE", PROF_NOVICE, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["overhead_strike", "side_strike", "direct_blow"], ["overhead_strike", "parry_strike"])
	_free_1v1(data)
	return _format_scenario_result("MACE_novice", result, data)


## MACE: veteran.
static func run_mace_veteran() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("MACE", "MACE", PROF_VETERAN, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["overhead_strike", "side_strike", "direct_blow"], ["overhead_strike", "parry_strike"])
	_free_1v1(data)
	return _format_scenario_result("MACE_veteran", result, data)


## DAGGER: chest-heavy, high fidelity.
static func run_dagger_novice() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("DAGGER", "DAGGER", PROF_NOVICE, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["quick_thrust", "committed_thrust", "quick_slash"], ["quick_thrust"])
	_free_1v1(data)
	return _format_scenario_result("DAGGER_novice", result, data)


## DAGGER: veteran.
static func run_dagger_veteran() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("DAGGER", "DAGGER", PROF_VETERAN, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["quick_thrust", "committed_thrust", "quick_slash"], ["quick_thrust"])
	_free_1v1(data)
	return _format_scenario_result("DAGGER_veteran", result, data)


## SPEAR: chest-dominant, long lane.
static func run_spear_novice() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SPEAR", "SPEAR", PROF_NOVICE, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["spear_thrust", "off_line_thrust", "spear_slash"], ["spear_thrust"])
	_free_1v1(data)
	return _format_scenario_result("SPEAR_novice", result, data)


## SPEAR: veteran.
static func run_spear_veteran() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SPEAR", "SPEAR", PROF_VETERAN, {})
	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["spear_thrust", "off_line_thrust", "spear_slash"], ["spear_thrust"])
	_free_1v1(data)
	return _format_scenario_result("SPEAR_veteran", result, data)


## Form doctrine: Ox form should boost thrust→chest.
static func run_sword_ox_form() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SWORD", "SWORD", PROF_VETERAN, {})

	# Override player form to Ox before exchanges.
	for c in data["mgr"].combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var _WF := preload("res://combat/CombatWeaponForm.gd")
		if _EntityAccess.id_int(c) == data["p_id"]:
			_WF.assign_form(data["mgr"], c, _WF.FORM_OX, "harness_ox")
		else:
			_WF.assign_form(data["mgr"], c, _WF.FORM_BALANCED, "harness_baseline")

	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["thrust", "oberhau", "unterhau"], ["thrust", "oberhau"])
	_free_1v1(data)
	return _format_scenario_result("SWORD_OX_veteran", result, data)


## Form doctrine: Wrath form should boost head.
static func run_sword_wrath_form() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SWORD", "SWORD", PROF_VETERAN, {})

	for c in data["mgr"].combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var _WF := preload("res://combat/CombatWeaponForm.gd")
		if _EntityAccess.id_int(c) == data["p_id"]:
			_WF.assign_form(data["mgr"], c, _WF.FORM_WRATH, "harness_wrath")
		else:
			_WF.assign_form(data["mgr"], c, _WF.FORM_BALANCED, "harness_baseline")

	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["thrust", "oberhau", "unterhau"], ["thrust", "oberhau"])
	_free_1v1(data)
	return _format_scenario_result("SWORD_WRATH_veteran", result, data)


## Form doctrine: Fool form should boost feints→legs.
static func run_sword_fool_form() -> Dictionary:
	_ensure_proficiency_on()
	var data := _setup_1v1("SWORD", "SWORD", PROF_VETERAN, {})

	for c in data["mgr"].combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var _WF := preload("res://combat/CombatWeaponForm.gd")
		if _EntityAccess.id_int(c) == data["p_id"]:
			_WF.assign_form(data["mgr"], c, _WF.FORM_FOOL, "harness_fool")
		else:
			_WF.assign_form(data["mgr"], c, _WF.FORM_BALANCED, "harness_baseline")

	var result := _run_targeting_exchange(data, data["p_id"], data["e_id"], ["oberhau_feint", "thrust", "unterhau"], ["thrust"])
	_free_1v1(data)
	return _format_scenario_result("SWORD_FOOL_veteran", result, data)


# --- Report formatting ---

static func _format_scenario_result(name: String, exchange_result: Dictionary, setup_data: Dictionary) -> Dictionary:
	var records: Array = exchange_result.get("records", [])
	var aim_dist := _aggregate_aim(records)
	var actual_dist := _aggregate_actual(records)
	var matches := _count_matches(records)

	return {
		"name": name,
		"total_attacks": records.size(),
		"aim_distribution": aim_dist,
		"actual_distribution": actual_dist,
		"matches": matches,
		"match_pct": 0.0 if matches["total"] == 0 else float(matches["hits"]) / float(matches["total"]) * 100.0,
		"records": records,
	}


static func format_report(result: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("--- Targeting 1v1 Report: %s ---" % result.get("name", ""))
	lines.append("Total attacks: %d" % result.get("total_attacks", 0))

	var aim_dist: Dictionary = result.get("aim_distribution", {})
	if not aim_dist.is_empty():
		lines.append("")
		lines.append("Aim distribution:")
		for part in aim_dist:
			lines.append("  %s: %d (%.1f%%)" % [part, aim_dist[part], float(aim_dist[part]) / result.get("total_attacks", 1) * 100.0])

	var actual_dist: Dictionary = result.get("actual_distribution", {})
	if not actual_dist.is_empty():
		lines.append("")
		lines.append("Actual hit distribution:")
		for part in actual_dist:
			lines.append("  %s: %d (%.1f%%)" % [part, actual_dist[part], float(actual_dist[part]) / maxi(1, result.get("total_attacks", 0)) * 100.0])

	var matches: Dictionary = result.get("matches", {})
	lines.append("")
	lines.append("Aim=part matches: %d/%d (%.1f%%)" % [
		matches.get("hits", 0), matches.get("total", 0), result.get("match_pct", 0.0)
	])

	# Per-move breakdown
	var move_stats := {}
	for r in result.get("records", []):
		if str(r.get("outcome", "")) != "hit":
			continue
		var mid: String = r.get("move_id", "")
		if not move_stats.has(mid):
			move_stats[mid] = {"total": 0, "matches": 0}
		move_stats[mid]["total"] += 1
		if str(r.get("aimed_part", "")) == str(r.get("actual_part", "")):
			move_stats[mid]["matches"] += 1

	if not move_stats.is_empty():
		lines.append("")
		lines.append("Per-move aim=part:")
		for mid in move_stats:
			var ms: Dictionary = move_stats[mid]
			var pct: float = 0.0 if ms["total"] == 0 else float(ms["matches"]) / float(ms["total"]) * 100.0
			lines.append("  %s: %d/%d (%.1f%%)" % [mid, ms["matches"], ms["total"], pct])

	return "\n".join(lines)


static func format_all_reports(reports: Dictionary) -> String:
	var lines := PackedStringArray()
	for name in reports:
		lines.append("")
		var sep := ""
		for _i in 60:
			sep += "="
		lines.append(sep)
		lines.append(format_report(reports[name]))
	return "\n".join(lines)


# --- Harness integration ---

static func _ensure_proficiency_on() -> void:
	_CompanyState.PROFICIENCY_ENABLED = true


static func run(failures: PackedStringArray) -> void:
	var scenarios := {
		"sword_balanced_novice": run_sword_balanced,
		"sword_balanced_veteran": run_sword_veteran,
		"axe_novice": run_axe_novice,
		"axe_veteran": run_axe_veteran,
		"mace_novice": run_mace_novice,
		"mace_veteran": run_mace_veteran,
		"dagger_novice": run_dagger_novice,
		"dagger_veteran": run_dagger_veteran,
		"spear_novice": run_spear_novice,
		"spear_veteran": run_spear_veteran,
		"sword_ox_form": run_sword_ox_form,
		"sword_wrath_form": run_sword_wrath_form,
		"sword_fool_form": run_sword_fool_form,
	}

	for name in scenarios:
		var runner: Callable = scenarios[name]
		var result: Dictionary = runner.call()
		var total: int = result.get("total_attacks", 0)
		if total == 0:
			_Harness._fail(failures, "targeting_1v1_%s: no attacks recorded" % name)
			continue

		var matches: Dictionary = result.get("matches", {})
		if matches["total"] < 1:
			var action_summary := ""
			for r in result.get("records", []):
				action_summary += "%s(%s) " % [r.get("move_id", ""), r.get("outcome", "")]
			_Harness._fail(failures, "targeting_1v1_%s: no hits in %d attacks [%s]" % [name, total, action_summary.strip_edges()])


## Run all scenarios and print reports (for manual tuning).
static func run_tuning_all() -> Dictionary:
	var reports := {}

	var scenarios := {
		"sword_balanced_novice": run_sword_balanced,
		"sword_balanced_veteran": run_sword_veteran,
		"axe_novice": run_axe_novice,
		"axe_veteran": run_axe_veteran,
		"mace_novice": run_mace_novice,
		"mace_veteran": run_mace_veteran,
		"dagger_novice": run_dagger_novice,
		"dagger_veteran": run_dagger_veteran,
		"spear_novice": run_spear_novice,
		"spear_veteran": run_spear_veteran,
		"sword_ox_form": run_sword_ox_form,
		"sword_wrath_form": run_sword_wrath_form,
		"sword_fool_form": run_sword_fool_form,
	}

	for name in scenarios:
		var runner: Callable = scenarios[name]
		var result: Dictionary = runner.call()
		reports[name] = result
		print("=".repeat(60))
		print(format_report(result))

	return reports
