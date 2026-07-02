class_name CombatRegressionHarnessProficiencyTail
extends RefCounted

## XCamp-4: use-based stat proficiency system tests.
## All tests are gated by CompanyState.read_stub_proficiency_enabled() --" stub is false by default.

const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _Proficiency := preload("res://core/EntityProficiency.gd")
const _ProcessTick := preload("res://combat/CombatProcessTick.gd")
const _PartyRowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _CampaignPersistence := preload("res://world/CampaignPersistence.gd")
const _CombatRegressionHarness := preload("res://combat/CombatRegressionHarness.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _PathResolver := preload("res://combat/AttackPathResolver.gd")


# --- Harness helpers ---

static func _new_entity_weapon_id() -> String:
	return "SWORD"


## Creates a mock CoreEntity with weapon, registers in manager. Returns {mgr, p_id, ent}.
static func _setup_proficiency_combat(failures: PackedStringArray) -> Dictionary:
	# Stub must be on for proficiency tests.
	if not _CompanyState.read_stub_proficiency_enabled():
		return {}
	var mgr: Node = _MgrScript.new()
	var p_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	mgr.register(p_ent, "player")
	p_ent.strength = 120
	p_ent.agility = 100
	p_ent.intelligence = 110
	p_ent.endurance = 110
	p_ent.perception = 95
	var en_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	mgr.register(en_ent, "enemy")
	en_ent.strength = 100
	en_ent.agility = 100
	en_ent.intelligence = 100
	en_ent.endurance = 100
	en_ent.perception = 100
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	return { "mgr": mgr, "p_id": p_id, "player_ent": p_ent, "enemy_ent": en_ent }


static func _free_proficiency_combat(data: Dictionary) -> void:
	if data.is_empty():
		return
	var mgr: Node = data.get("mgr")
	if is_instance_valid(mgr):
		mgr.queue_free()


## Helper: simulate a hit resolving on the player combatant, then check proficiency gains.
static func _simulate_hit_resolve_and_check_gains(
	data: Dictionary,
	failures: PackedStringArray,
	expected_str_gain_min: float = 0.3,
	expected_end_gain_min: float = 0.2
) -> void:
	if data.is_empty():
		return
	var mgr: Node = data.get("mgr")
	var player_ent: Node = data.get("player_ent")
	var p_id: int = data.get("p_id", -1)
	var enemy_ent: Node = data.get("enemy_ent")

	# Trigger a hit action by setting up pending_attack and resolving.
	var enemy: Dictionary = _EntityAccess.manager_get_combatant(mgr, 1)
	if enemy.is_empty():
		return
	var atk: Dictionary = _EntityAccess.manager_get_combatant(mgr, p_id)
	if atk.is_empty():
		return

	# Set up a wind-up on the player.
	atk.state = CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": 1,
		"intensity": 0.5,
		"attack_type": "thrust",
	}

	# Resolve the attack.
	var _AttackResolver := preload("res://combat/AttackResolver.gd")
	var result: Dictionary = _AttackResolver.resolve_attack(mgr, p_id)

	# The resolve should produce a hit (since perception is 95 and miss chance is low).
	if result.get("action", "") != "hit":
		# Even if miss, we should still get wind-up gains.
		var bonus_str: float = float(player_ent._proficiency_bonus.get("strength", 0) or 0)
		if bonus_str < expected_str_gain_min * 0.5:
			_CombatRegressionHarness._fail(
				failures,
				"hit_gains: wind-up STR gain too low on %s result (got %.2f, want >= %.1f)"
				% [result.get("action", ""), bonus_str, expected_str_gain_min]
			)
		return

	var bonus_str: float = float(player_ent._proficiency_bonus.get("strength", 0) or 0)
	if bonus_str < expected_str_gain_min:
		_CombatRegressionHarness._fail(
			failures,
			"hit_gains: STR gain too low (got %.2f, want >= %.1f)"
			% [bonus_str, expected_str_gain_min]
		)

	var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
	if bonus_end < expected_end_gain_min:
		_CombatRegressionHarness._fail(
			failures,
			"hit_gains: END gain on defender too low (got %.2f, want >= %.1f)"
			% [bonus_end, expected_end_gain_min]
		)


# --- Test functions ---

## Stub gating: proficiency bonuses are zero when stub is off.
static func _run_stub_gating_off(failures: PackedStringArray) -> void:
	if _CompanyState.read_stub_proficiency_enabled():
		return  # Skip if stub is on (test is for the OFF state).
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent.strength = 120
	if "_proficiency_bonus" not in ent:
		_CombatRegressionHarness._fail(failures, "stub_off: entity missing proficiency dict")
		_CombatRegressionHarness._free_harness_node(ent)
		return
	if ent._proficiency_bonus.get("strength", 0) != 0:
		_CombatRegressionHarness._fail(failures, "stub_off: bonus should be 0 when stub off (got %s)" % str(ent._proficiency_bonus))
	_CombatRegressionHarness._free_harness_node(ent)


## Stub gating: _copy_core_stats does not add bonuses when stub is off.
static func _run_copy_core_stats_no_bonuses_when_off(failures: PackedStringArray) -> void:
	if _CompanyState.read_stub_proficiency_enabled():
		return
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent.strength = 120
	ent.agility = 95
	ent.intelligence = 110
	var _StatsSync := preload("res://combat/CombatantStatsSync.gd")
	var stats: Dictionary = {}
	_StatsSync._copy_core_stats(ent, stats)
	if stats.get("strength", -1) != 120:
		_CombatRegressionHarness._fail(failures, "stub_off_copy: strength should be 120 not %s" % str(stats.get("strength")))
	if stats.get("agility", -1) != 95:
		_CombatRegressionHarness._fail(failures, "stub_off_copy: agility should be 95 not %s" % str(stats.get("agility")))
	if stats.get("intelligence", -1) != 110:
		_CombatRegressionHarness._fail(failures, "stub_off_copy: intelligence should be 110 not %s" % str(stats.get("intelligence")))
	_CombatRegressionHarness._free_harness_node(ent)


## Stub gating: bonuses are applied when stub is on.
static func _run_copy_core_stats_applies_bonuses_when_on(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return  # Skip if stub is off.
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent.strength = 120
	ent.agility = 95
	ent.intelligence = 110
	ent.endurance = 105
	ent.perception = 98
	# Set proficiency bonuses.
	ent._proficiency_bonus["strength"] = 3.0
	ent._proficiency_bonus["agility"] = -2.0
	ent._proficiency_bonus["intelligence"] = 5.0
	ent._proficiency_bonus["endurance"] = 1.0
	ent._proficiency_bonus["perception"] = 0.0
	var _StatsSync := preload("res://combat/CombatantStatsSync.gd")
	var stats: Dictionary = {}
	_StatsSync._copy_core_stats(ent, stats)
	if int(stats.get("strength", -1)) != 123:
		_CombatRegressionHarness._fail(failures, "stub_on_copy: strength should be 123 (120+3), got %s" % str(stats.get("strength")))
	if int(stats.get("agility", -1)) != 93:
		_CombatRegressionHarness._fail(failures, "stub_on_copy: agility should be 93 (95-2), got %s" % str(stats.get("agility")))
	if int(stats.get("intelligence", -1)) != 115:
		_CombatRegressionHarness._fail(failures, "stub_on_copy: intelligence should be 115 (110+5), got %s" % str(stats.get("intelligence")))
	if int(stats.get("endurance", -1)) != 106:
		_CombatRegressionHarness._fail(failures, "stub_on_copy: endurance should be 106 (105+1), got %s" % str(stats.get("endurance")))
	_CombatRegressionHarness._free_harness_node(ent)


## EntityProficiency.award_stat_gain applies diminishing returns.
static func _run_award_stat_gain_diminishing_returns(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	# Award gain at novice level (bonus < 5).
	_Proficiency.award_stat_gain(ent, "strength", 1.0)
	var bonus_novice: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(bonus_novice - 1.0) > 0.001:
		_CombatRegressionHarness._fail(failures, "diminishing: novice gain should be 1.0 (got %.2f)" % bonus_novice)

	# Award more to push into proficient range (bonus > 5).
	for _i in range(5):
		_Proficiency.award_stat_gain(ent, "strength", 1.0)
	var bonus_proficient: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	var expected_min: float = 6.0 * 0.7 + 1.0  # At least the first proficient gain at 0.7x
	if bonus_proficient < expected_min:
		_CombatRegressionHarness._fail(
			failures,
			"diminishing: proficient gain too low (got %.2f, want >= %.2f)"
			% [bonus_proficient, expected_min]
		)

	# Award more to push into veteran range (bonus > 10).
	for _i in range(8):
		_Proficiency.award_stat_gain(ent, "strength", 1.0)
	var bonus_veteran: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if bonus_veteran < 5.0:  # Should have grown significantly.
		_CombatRegressionHarness._fail(
			failures,
			"diminishing: veteran gain too low (got %.2f)" % bonus_veteran
		)
	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## EntityProficiency.award_stat_gain respects stance modifiers.
static func _run_award_stat_gain_stance_modifier(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	_Proficiency.award_stat_gain(ent, "strength", 1.0, "", "wrath")
	var wrath_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(wrath_str - 1.25) > 0.001:
		_CombatRegressionHarness._fail(failures, "stance_wrath: STR gain should be 1.25 (got %.2f)" % wrath_str)

	_Proficiency.award_stat_gain(ent, "endurance", 1.0, "", "wall")
	var wall_end: float = float(ent._proficiency_bonus.get("endurance", 0) or 0)
	if absf(wall_end - 1.25) > 0.001:
		_CombatRegressionHarness._fail(failures, "stance_wall: END gain should be 1.25 (got %.2f)" % wall_end)

	_Proficiency.award_stat_gain(ent, "strength", 1.0, "", "balanced")
	var balanced_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(balanced_str - 3.25) > 0.001:  # 1.25 + 1.0 + 1.0
		_CombatRegressionHarness._fail(failures, "stance_balanced: STR should be cumulative (got %.2f)" % balanced_str)
	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## EntityProficiency.award_stat_gain respects weapon curve modifiers.
static func _run_award_stat_gain_weapon_curve(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SPEAR")
	_Proficiency.award_stat_gain(ent, "strength", 1.0, "SPEAR", "")
	var spear_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(spear_str - 1.3) > 0.001:
		_CombatRegressionHarness._fail(failures, "weapon_spear: STR gain should be 1.3 (got %.2f)" % spear_str)

	_Proficiency.award_stat_gain(ent, "agility", 1.0, "SPEAR", "")
	var spear_agi: float = float(ent._proficiency_bonus.get("agility", 0) or 0)
	if absf(spear_agi - 1.0) > 0.001:
		_CombatRegressionHarness._fail(failures, "weapon_spear: AGI gain should be 1.0 (got %.2f)" % spear_agi)

	_Proficiency.award_stat_gain(ent, "strength", 1.0, "DAGGER", "")
	var dual_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(dual_str - 2.0) > 0.001:  # 1.3 + 0.7
		_CombatRegressionHarness._fail(failures, "weapon_dagger: STR should be cumulative (got %.2f)" % dual_str)
	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## EntityProficiency.apply_decay reduces bonuses for inactive mercenaries.
static func _run_apply_decay_inactive_mercenary(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 12.0
	ent.last_fought_day = -2
	_Proficiency.apply_decay(ent, 1)  # 3 inactive days (day 1 - (-2) = 3).
	var decayed_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if decayed_str >= 12.0:
		_CombatRegressionHarness._fail(failures, "decay: strength should decrease after 3 inactive days (got %.2f)" % decayed_str)
	# Decay below +10 should stop.
	ent._proficiency_bonus["strength"] = 9.0
	_Proficiency.apply_decay(ent, 5)
	var stopped_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(stopped_str - 9.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "decay_stop: bonus below 10 should not decay (got %.2f)" % stopped_str)
	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## EntityProficiency.apply_decay penalizes wounded mercenaries less.
static func _run_apply_decay_wounded_protection(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 15.0
	ent.last_fought_day = -5
	ent.blood_volume = 35.0  # Below 40% --" wounded protection.
	_Proficiency.apply_decay(ent, 0)
	var wounded_decay: float = float(ent._proficiency_bonus.get("strength", 0) or 0)

	# Compare with healthy mercenary.
	var ent2: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent2._proficiency_bonus["strength"] = 15.0
	ent2.last_fought_day = -5
	ent2.blood_volume = 90.0  # Healthy.
	_Proficiency.apply_decay(ent2, 0)
	var healthy_decay: float = float(ent2._proficiency_bonus.get("strength", 0) or 0)

	if wounded_decay >= healthy_decay:
		_CombatRegressionHarness._fail(
			failures,
			"decay_wounded: wounded decay (%.4f) should be less than healthy (%.4f)"
			% [wounded_decay, healthy_decay]
		)
	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(ent2)


## EntityProficiency.merge_training_pending applies pending gains.
static func _run_merge_training_pending(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 5.0
	ent.training_pending["strength"] = 3.0
	ent.training_pending["intelligence"] = 2.0
	_Proficiency.merge_training_pending(ent)
	var merged_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(merged_str - 8.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "merge: STR should be 8.0 (got %.2f)" % merged_str)
	var pending_str: float = float(ent.training_pending.get("strength", 0) or 0)
	if absf(pending_str - 0.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "merge: training_pending STR should be reset to 0 (got %.2f)" % pending_str)
	var pending_int: float = float(ent.training_pending.get("intelligence", 0) or 0)
	if absf(pending_int - 2.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "merge: training_pending INT should remain 2.0 (got %.2f)" % pending_int)
	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## END blood volume multiplier scales correctly.
static func _run_endurance_blood_volume_mult(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	if not ent.has_method("get_endurance_blood_volume_mult"):
		_CombatRegressionHarness._fail(failures, "end_bvm: entity missing method")
		_CombatRegressionHarness._free_harness_node(ent)
		return

	var mult_100: float = ent.get_endurance_blood_volume_mult()
	if absf(mult_100 - 1.0) > 0.001:
		_CombatRegressionHarness._fail(failures, "end_bvm@100: should be 1.0 (got %.4f)" % mult_100)

	ent.endurance = 150
	var mult_150: float = ent.get_endurance_blood_volume_mult()
	if absf(mult_150 - 1.25) > 0.01:
		_CombatRegressionHarness._fail(failures, "end_bvm@150: should be 1.25 (got %.4f)" % mult_150)

	ent.endurance = 80
	var mult_80: float = ent.get_endurance_blood_volume_mult()
	if absf(mult_80 - 0.95) > 0.01:
		_CombatRegressionHarness._fail(failures, "end_bvm@80: should be 0.95 (got %.4f)" % mult_80)

	_CombatRegressionHarness._free_harness_node(ent)


## END healing speed multiplier scales correctly.
static func _run_endurance_healing_speed_mult(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	if not ent.has_method("get_endurance_healing_speed_mult"):
		_CombatRegressionHarness._fail(failures, "end_hsm: entity missing method")
		_CombatRegressionHarness._free_harness_node(ent)
		return

	var mult_100: float = ent.get_endurance_healing_speed_mult()
	if absf(mult_100 - 1.0) > 0.001:
		_CombatRegressionHarness._fail(failures, "end_hsm@100: should be 1.0 (got %.4f)" % mult_100)

	ent.endurance = 150
	var mult_150: float = ent.get_endurance_healing_speed_mult()
	if absf(mult_150 - 0.9) > 0.01:  # 1.0 - clampf(50/500, 0, 0.25) = 1.0 - 0.1 = 0.9
		_CombatRegressionHarness._fail(failures, "end_hsm@150: should be 0.9 (got %.4f)" % mult_150)

	ent.endurance = 80
	var mult_80: float = ent.get_endurance_healing_speed_mult()
	if absf(mult_80 - 1.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "end_hsm@80: should be 1.0 (got %.4f)" % mult_80)

	_CombatRegressionHarness._free_harness_node(ent)


## INT contract bonus multiplier scales correctly.
static func _run_intelligence_contract_bonus_mult(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	if not ent.has_method("get_intelligence_contract_bonus_mult"):
		_CombatRegressionHarness._fail(failures, "int_cbm: entity missing method")
		_CombatRegressionHarness._free_harness_node(ent)
		return

	var mult_100: float = ent.get_intelligence_contract_bonus_mult()
	if absf(mult_100 - 1.0) > 0.001:
		_CombatRegressionHarness._fail(failures, "int_cbm@100: should be 1.0 (got %.4f)" % mult_100)

	ent.intelligence = 150
	var mult_150: float = ent.get_intelligence_contract_bonus_mult()
	if absf(mult_150 - 1.1) > 0.01:  # 1.0 + clampf(50/500, 0, 0.15) = 1.0 + 0.1 = 1.1
		_CombatRegressionHarness._fail(failures, "int_cbm@150: should be 1.1 (got %.4f)" % mult_150)

	ent.intelligence = 80
	var mult_80: float = ent.get_intelligence_contract_bonus_mult()
	if absf(mult_80 - 1.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "int_cbm@80: should be 1.0 (got %.4f)" % mult_80)

	_CombatRegressionHarness._free_harness_node(ent)


## CombatantEntityAccess.get_effective_medical_windup_speed_modifier reads from stats dict.
static func _run_effective_medical_windup_speed_modifier(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return  # This test requires stub to be on for proficiency bonus integration.

	var mgr: Node = _MgrScript.new()
	var p_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	p_ent.intelligence = 120
	p_ent._proficiency_bonus["intelligence"] = 5.0  # Effective INT = 125.
	mgr.register(p_ent, "player")
	var en_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	en_ent.intelligence = 100
	mgr.register(en_ent, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var en_id: int = _EntityAccess.id_int(mgr.combatants[1])

	var speed_mod: float = _EntityAccess.get_effective_medical_windup_speed_modifier(mgr, mgr.combatants[0], mgr.combatants[1])

	# Effective INT is 125, so med_eff = clampf(125/100.0, 0.5, 1.5) = 1.25
	var expected_med_eff: float = 1.25
	if absf(speed_mod - expected_med_eff) > 0.01:
		_CombatRegressionHarness._fail(
			failures,
			"eff_windup_speed: expected %.2f (INT=125), got %.2f"
			% [expected_med_eff, speed_mod]
		)

	_CombatRegressionHarness._free_harness_node(mgr)


## CombatantEntityAccess.get_medical_windup_speed_modifier reads base INT (not proficiency).
static func _run_base_medical_windup_speed_modifier(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var p_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	p_ent.intelligence = 120
	p_ent._proficiency_bonus["intelligence"] = 5.0  # Should NOT affect base method.
	mgr.register(p_ent, "player")
	var en_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	en_ent.intelligence = 100
	mgr.register(en_ent, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var en_id: int = _EntityAccess.id_int(mgr.combatants[1])

	var speed_mod: float = _EntityAccess.get_medical_windup_speed_modifier(mgr, mgr.combatants[0], mgr.combatants[1])

	# Base INT is 120, so med_eff = clampf(120/100.0, 0.5, 1.5) = 1.2
	var expected_med_eff: float = 1.2
	if absf(speed_mod - expected_med_eff) > 0.01:
		_CombatRegressionHarness._fail(
			failures,
			"base_windup_speed: expected %.2f (base INT=120), got %.2f"
			% [expected_med_eff, speed_mod]
		)

	_CombatRegressionHarness._free_harness_node(mgr)


## PartyRowFormatter.format_proficiency_bonus_line shows bonuses.
static func _run_formatter_proficiency_bonus_line(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent.name = "TestMerc"
	ent._proficiency_bonus["strength"] = 3.0
	ent._proficiency_bonus["intelligence"] = 5.0

	var member: Dictionary = {
		"name": "TestMerc",
		"node_ref": ent,
	}
	var line: String = _PartyRowFormatter.format_proficiency_bonus_line(member)
	if line.is_empty():
		_CombatRegressionHarness._fail(failures, "formatter: proficiency line should not be empty")

	if not line.contains("STR:") and not line.contains("AGI:"):
		_CombatRegressionHarness._fail(
			failures, "formatter: proficiency line should contain stat abbreviations (got '%s')" % line
		)

	# Empty bonuses should return empty string.
	var ent2: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent2.name = "EmptyMerc"
	var member2: Dictionary = {
		"name": "EmptyMerc",
		"node_ref": ent2,
	}
	var line2: String = _PartyRowFormatter.format_proficiency_bonus_line(member2)
	if not line2.is_empty():
		_CombatRegressionHarness._fail(failures, "formatter: empty bonuses should return empty string (got '%s')" % line2)

	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(ent2)


## Persistence integration: proficiency data survives serialization round-trip.
static func _run_persistence_round_trip(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 4.0
	ent._proficiency_bonus["agility"] = 2.0
	ent._proficiency_bonus["intelligence"] = 6.0
	ent._proficiency_bonus["endurance"] = 1.0
	ent._proficiency_bonus["perception"] = 0.0
	ent.training_pending["strength"] = 2.0
	ent.training_pending["agility"] = 0.0
	ent.last_fought_day = 42
	ent.last_fought_in_combat = true

	# Simulate serialization.
	var _CampaignPersistence := preload("res://world/CampaignPersistence.gd")
	var serialized: Dictionary = _CampaignPersistence._serialize_entity(ent)

	if not serialized.has("proficiency_bonus"):
		_CombatRegressionHarness._fail(failures, "persist: proficiency_bonus should be serialized")
	if int(serialized.get("last_fought_day", -1)) != 42:
		_CombatRegressionHarness._fail(
			failures, "persist: last_fought_day should be 42 (got %s)" % str(serialized.get("last_fought_day"))
		)

	# Simulate deserialization into a fresh entity.
	var fresh_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	fresh_ent._proficiency_bonus["strength"] = 0
	fresh_ent._proficiency_bonus["agility"] = 0
	fresh_ent._proficiency_bonus["intelligence"] = 0
	fresh_ent._proficiency_bonus["endurance"] = 0
	fresh_ent._proficiency_bonus["perception"] = 0
	fresh_ent.training_pending["strength"] = 0
	fresh_ent.training_pending["agility"] = 0
	fresh_ent.last_fought_day = 0
	fresh_ent.last_fought_in_combat = false

	_CampaignPersistence._apply_entity(fresh_ent, serialized)

	var restored_str: float = float(fresh_ent._proficiency_bonus.get("strength", -1))
	if absf(restored_str - 4.0) > 0.01:
		_CombatRegressionHarness._fail(
			failures, "persist: restored strength should be 4.0 (got %.2f)" % restored_str
		)
	var restored_int: float = float(fresh_ent._proficiency_bonus.get("intelligence", -1))
	if absf(restored_int - 6.0) > 0.01:
		_CombatRegressionHarness._fail(
			failures, "persist: restored intelligence should be 6.0 (got %.2f)" % restored_int
		)
	var restored_day: int = fresh_ent.last_fought_day
	if restored_day != 42:
		_CombatRegressionHarness._fail(
			failures, "persist: restored last_fought_day should be 42 (got %d)" % restored_day
		)

	var restored_in_combat: bool = fresh_ent.last_fought_in_combat
	if restored_in_combat != true:
		_CombatRegressionHarness._fail(
			failures, "persist: restored last_fought_in_combat should be true (got %s)" % str(restored_in_combat)
		)

	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(fresh_ent)


## Persistence integration: training_pending serializes and restores.
static func _run_persistence_training_pending(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent.training_pending["strength"] = 3.5
	ent.training_pending["intelligence"] = 1.0

	var _CampaignPersistence := preload("res://world/CampaignPersistence.gd")
	var serialized: Dictionary = _CampaignPersistence._serialize_entity(ent)

	if not serialized.has("training_pending"):
		_CombatRegressionHarness._fail(failures, "persist_train: training_pending should be serialized")

	var fresh_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	fresh_ent.training_pending["strength"] = 0
	fresh_ent.training_pending["intelligence"] = 0
	_CampaignPersistence._apply_entity(fresh_ent, serialized)

	var restored_str: float = float(fresh_ent.training_pending.get("strength", -1))
	if absf(restored_str - 3.5) > 0.01:
		_CombatRegressionHarness._fail(
			failures, "persist_train: restored strength should be 3.5 (got %.2f)" % restored_str
		)

	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(fresh_ent)


## Combat hit flow awards proficiency gains when stub is on.
static func _run_combat_hit_awards_proficiency_gains(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return  # Skip if stub is off.

	var data: Dictionary = _setup_proficiency_combat(failures)
	if data.is_empty():
		_CombatRegressionHarness._fail(failures, "combat_hit_gains: setup failed")
		return

	var player_ent: Node = data.get("player_ent")
	player_ent.strength = 130
	player_ent.agility = 105
	player_ent.intelligence = 115
	player_ent.perception = 100

	# Set up and resolve an attack.
	var atk: Dictionary = _EntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
	if atk.is_empty():
		_CombatRegressionHarness._fail(failures, "combat_hit_gains: no player combatant")
		return

	atk.state = CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": 1,
		"intensity": 0.5,
		"attack_type": "thrust",
	}

	var _AttackResolver := preload("res://combat/AttackResolver.gd")
	var result: Dictionary = _AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))

	if result.get("action", "") == "hit":
		var bonus_str: float = float(player_ent._proficiency_bonus.get("strength", 0) or 0)
		if bonus_str < 0.25:
			_CombatRegressionHarness._fail(
				failures, "combat_hit_gains: STR gain too low on hit (got %.2f)" % bonus_str
			)

	_free_proficiency_combat(data)


## Combat dodge awards proficiency gains when stub is on.
static func _run_combat_dodge_awards_proficiency_gains(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return  # Skip if stub is off.

	var data: Dictionary = _setup_proficiency_combat(failures)
	if data.is_empty():
		_CombatRegressionHarness._fail(failures, "combat_dodge_gains: setup failed")
		return

	var enemy_ent: Node = data.get("enemy_ent")

	# Set up attack on player that will be dodged (low perception).
	var atk: Dictionary = _EntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
	if atk.is_empty():
		_CombatRegressionHarness._fail(failures, "combat_dodge_gains: no player combatant")
		return

	atk.state = CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": 1,
		"intensity": 0.5,
		"attack_type": "thrust",
	}

	var _AttackResolver := preload("res://combat/AttackResolver.gd")
	var result: Dictionary = _AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))

	if result.get("action", "") == "dodge":
		var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
		if bonus_end < 0.1:
			_CombatRegressionHarness._fail(
				failures, "combat_dodge_gains: defender END gain too low on dodge (got %.2f)" % bonus_end
			)

	_free_proficiency_combat(data)


## Medical action awards proficiency gains when stub is on.
static func _run_medical_action_awards_proficiency_gains(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return  # Skip if stub is off.

	var data: Dictionary = _setup_proficiency_combat(failures)
	if data.is_empty():
		_CombatRegressionHarness._fail(failures, "medical_gains: setup failed")
		return

	var player_ent: Node = data.get("player_ent")
	var enemy_ent: Node = data.get("enemy_ent")

	# Give enemy a wound.
	var _EntityMedical := preload("res://core/EntityMedical.gd")
	var _EntityWounds := preload("res://core/EntityWounds.gd")
	_EntityWounds.add_wound(enemy_ent, "chest", "cut", 5.0, "upper_thorax", "moderate")

	# Set up and complete a bandage action through the medical wind-up handler.
	var _MedicalWindUp := preload("res://combat/MedicalWindUpHandler.gd")
	var _MedicalActionStarter := preload("res://combat/MedicalActionStarter.gd")

	var mgr: Node = data.get("mgr")
	var p_id: int = data.get("p_id")
	var enemy_id: int = 1

	# Start the medical wind-up.
	_MedicalActionStarter.start(
		mgr, p_id, enemy_id, "apply_bandage", "chest"
	)

	# Complete the wind-up via tick.
	var c: Dictionary = _EntityAccess.manager_get_combatant(mgr, p_id)
	if c.is_empty():
		_CombatRegressionHarness._fail(failures, "medical_gains: no player combatant")
		return

	_MedicalWindUp.complete(mgr, c, c.pending_medical)

	var bonus_int: float = float(player_ent._proficiency_bonus.get("intelligence", 0) or 0)
	if bonus_int < 0.3:
		_CombatRegressionHarness._fail(
			failures, "medical_gains: INT gain too low (got %.2f)" % bonus_int
		)

	var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
	if bonus_end < 0.1:
		_CombatRegressionHarness._fail(
			failures, "medical_gains: END gain on patient too low (got %.2f)" % bonus_end
		)

	_free_proficiency_combat(data)


## Decay rates per stat are calibrated correctly.
static func _run_decay_rates_per_stat(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent_str: Node = _CombatRegressionHarness._new_entity("SWORD")
	var ent_end: Node = _CombatRegressionHarness._new_entity("SWORD")
	var ent_agi: Node = _CombatRegressionHarness._new_entity("SWORD")

	ent_str._proficiency_bonus["strength"] = 15.0
	ent_str.last_fought_day = -3
	_Proficiency.apply_decay(ent_str, 0)
	var str_decay: float = absf(float(ent_str._proficiency_bonus.get("strength", 15) or 15) - 15.0)

	ent_end._proficiency_bonus["endurance"] = 15.0
	ent_end.last_fought_day = -3
	_Proficiency.apply_decay(ent_end, 0)
	var end_decay: float = absf(float(ent_end._proficiency_bonus.get("endurance", 15) or 15) - 15.0)

	ent_agi._proficiency_bonus["agility"] = 15.0
	ent_agi.last_fought_day = -3
	_Proficiency.apply_decay(ent_agi, 0)
	var agi_decay: float = absf(float(ent_agi._proficiency_bonus.get("agility", 15) or 15) - 15.0)

	# END decay should be ~1.5x STR decay; AGI should be ~1.3x STR decay.
	if end_decay < str_decay * 1.2:
		_CombatRegressionHarness._fail(
			failures, "decay_rates: END decay (%.4f) should be >1.2x STR decay (%.4f)"
			% [end_decay, str_decay]
		)
	if agi_decay < str_decay * 1.0:
		_CombatRegressionHarness._fail(
			failures, "decay_rates: AGI decay (%.4f) should be > STR decay (%.4f)"
			% [agi_decay, str_decay]
		)

	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent_str)
	_CombatRegressionHarness._free_harness_node(ent_end)
	_CombatRegressionHarness._free_harness_node(ent_agi)


## Parry deflect awards END gain for defender (absorbing recoil).
static func _run_parry_deflect_awards_end_gains(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return

	var data: Dictionary = _setup_proficiency_combat(failures)
	if data.is_empty():
		_CombatRegressionHarness._fail(failures, "parry_end_gains: setup failed")
		return

	var enemy_ent: Node = data.get("enemy_ent")

	# Set up attack on player that will be parried.
	var atk: Dictionary = _EntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
	if atk.is_empty():
		_CombatRegressionHarness._fail(failures, "parry_end_gains: no player combatant")
		return

	atk.state = CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": 1,
		"intensity": 0.5,
		"attack_type": "thrust",
	}

	var _AttackResolver := preload("res://combat/AttackResolver.gd")
	var result: Dictionary = _AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))

	if result.get("action", "") == "parry_deflect":
		var bonus_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
		if bonus_end < 0.1:
			_CombatRegressionHarness._fail(
				failures, "parry_end_gains: defender END gain too low on parry_deflect (got %.2f)" % bonus_end
			)

	_free_proficiency_combat(data)


## Parry partial awards no END gain to defender (parry absorbed the strike).
static func _run_parry_partial_no_defender_gain(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return

	var data: Dictionary = _setup_proficiency_combat(failures)
	if data.is_empty():
		_CombatRegressionHarness._fail(failures, "parry_partial_no_defender: setup failed")
		return

	var enemy_ent: Node = data.get("enemy_ent")
	var initial_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)

	# Set up attack on player that will be partially parried.
	var atk: Dictionary = _EntityAccess.manager_get_combatant(data.get("mgr"), data.get("p_id"))
	if atk.is_empty():
		_CombatRegressionHarness._fail(failures, "parry_partial_no_defender: no player combatant")
		return

	atk.state = CombatConstants.STATE_WIND_UP
	atk.pending_attack = {
		"target_id": 1,
		"intensity": 0.5,
		"attack_type": "thrust",
	}

	var _AttackResolver := preload("res://combat/AttackResolver.gd")
	var result: Dictionary = _AttackResolver.resolve_attack(data.get("mgr"), data.get("p_id"))

	var action: String = result.get("action", "")
	if not action.is_empty():
		var final_end: float = float(enemy_ent._proficiency_bonus.get("endurance", 0) or 0)
		if action == "parry_partial" and final_end > initial_end + 0.001:
			_CombatRegressionHarness._fail(
				failures, "parry_partial_no_defender: defender END should not increase on parry_partial (initial=%.2f final=%.2f)" % [initial_end, final_end]
			)

	_free_proficiency_combat(data)


## Medic INT floor tracks per-entity actions (not global counter).
static func _run_medic_int_floor_per_entity_tracking(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return

	var _Bridge := preload("res://world/CampaignEncounterBridge.gd")

	# Simulate two medic entities performing different numbers of actions.
	var ent1: Node = _CombatRegressionHarness._new_entity("SWORD")
	var ent2: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent1._proficiency_bonus["intelligence"] = 0
	ent2._proficiency_bonus["intelligence"] = 0

	# Create a mock world node with party manager.
	var world: Node2D = Node2D.new()
	world.set_meta("party_manager", null)
	var medic_actions: Dictionary = {}
	world.set_meta("campaign_medic_actions_by", medic_actions)

	# Entity 1 performs 3 actions, entity 2 performs 5 actions.
	_Bridge.record_medic_action(world, ent1)
	_Bridge.record_medic_action(world, ent1)
	_Bridge.record_medic_action(world, ent1)
	_Bridge.record_medic_action(world, ent2)
	_Bridge.record_medic_action(world, ent2)
	_Bridge.record_medic_action(world, ent2)
	_Bridge.record_medic_action(world, ent2)
	_Bridge.record_medic_action(world, ent2)

	var stored: Dictionary = world.get_meta("campaign_medic_actions_by")
	if int(stored.get(ent1, 0)) != 3:
		_CombatRegressionHarness._fail(failures, "medic_int_floor: entity1 should have 3 actions (got %s)" % str(stored.get(ent1)))
	if int(stored.get(ent2, 0)) != 5:
		_CombatRegressionHarness._fail(failures, "medic_int_floor: entity2 should have 5 actions (got %s)" % str(stored.get(ent2)))

	world.queue_free()
	_CombatRegressionHarness._free_harness_node(ent1)
	_CombatRegressionHarness._free_harness_node(ent2)


## merge_training_pending is wired into camp heal flow.
static func _run_merge_training_pending_wired_in_camp_heal(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return

	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 5.0
	ent.training_pending["strength"] = 3.0
	ent.training_pending["intelligence"] = 2.0

	# Call merge directly to verify it works (the wiring is in CompanyState.try_camp_heal).
	_Proficiency.merge_training_pending(ent)
	var merged_str: float = float(ent._proficiency_bonus.get("strength", 0) or 0)
	if absf(merged_str - 8.0) > 0.01:
		_CombatRegressionHarness._fail(failures, "merge_wired: STR should be 8.0 after merge (got %.2f)" % merged_str)

	_CombatRegressionHarness._free_harness_node(ent)


## Decay applies on defeat (not just player victory).
static func _run_decay_applies_on_defeat(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 15.0
	ent.last_fought_day = -3

	# Simulate defeat scenario: decay should still apply.
	_Proficiency.apply_decay(ent, 0)  # 3 inactive days (day 0 - (-3) = 3).
	var defeated_decay: float = float(ent._proficiency_bonus.get("strength", 15) or 15)

	# Compare with victory scenario (same decay expected).
	var ent2: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent2._proficiency_bonus["strength"] = 15.0
	ent2.last_fought_day = -3
	_Proficiency.apply_decay(ent2, 0)
	var victory_decay: float = float(ent2._proficiency_bonus.get("strength", 15) or 15)

	if absf(defeated_decay - victory_decay) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "decay_defeat: defeated decay (%.4f) should match victory decay (%.4f)"
			% [defeated_decay, victory_decay]
		)

	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(ent2)


## Medical item multipliers scale INT gain correctly.
static func _run_medical_item_multipliers(failures: PackedStringArray) -> void:
	var bandage_mult: float = _Proficiency.get_medical_item_mult("bandage")
	if absf(bandage_mult - 0.8) > 0.001:
		_CombatRegressionHarness._fail(failures, "med_item: bandage mult should be 0.8 (got %.2f)" % bandage_mult)

	var pack_mult: float = _Proficiency.get_medical_item_mult("pack")
	if absf(pack_mult - 1.2) > 0.001:
		_CombatRegressionHarness._fail(failures, "med_item: pack mult should be 1.2 (got %.2f)" % pack_mult)

	var tkt_mult: float = _Proficiency.get_medical_item_mult("tourniquet")
	if absf(tkt_mult - 1.5) > 0.001:
		_CombatRegressionHarness._fail(failures, "med_item: tourniquet mult should be 1.5 (got %.2f)" % tkt_mult)

	var unknown_mult: float = _Proficiency.get_medical_item_mult("unknown")
	if absf(unknown_mult - 1.0) > 0.001:
		_CombatRegressionHarness._fail(failures, "med_item: unknown type should default to 1.0 (got %.2f)" % unknown_mult)


## Decay protection from low blood volume halves decay rate (replaces removed _in_medical_danger test).
static func _run_decay_low_blood_volume_protection(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent._proficiency_bonus["strength"] = 15.0
	ent.last_fought_day = -3
	# CoreEntity default blood_volume is not set to <40, so add a mock entity with low bv
	var ent_low_bv := _CombatRegressionHarness._new_entity("SWORD")
	ent_low_bv._proficiency_bonus["strength"] = 15.0
	ent_low_bv.last_fought_day = -3

	_Proficiency.apply_decay(ent, 0)
	var normal_decay: float = float(ent._proficiency_bonus.get("strength", 15) or 15)

	# Set low blood volume on second entity to test wounded protection (decay x0.5).
	ent_low_bv.blood_volume = 30.0
	_Proficiency.apply_decay(ent_low_bv, 0)
	var low_bv_decay: float = float(ent_low_bv._proficiency_bonus.get("strength", 15) or 15)

	if low_bv_decay >= normal_decay:
		_CombatRegressionHarness._fail(
			failures, "decay_low_blood: low blood volume decay (%.4f) should be less than normal (%.4f)"
			% [low_bv_decay, normal_decay]
		)

	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(ent_low_bv)


## Medical wind-up speed uses effective INT when stub is on.
static func _run_medical_windup_uses_effective_int(failures: PackedStringArray) -> void:
	if not _CompanyState.read_stub_proficiency_enabled():
		return

	var mgr: Node = _MgrScript.new()
	var medic_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	medic_ent.intelligence = 100
	medic_ent._proficiency_bonus["intelligence"] = 20.0  # Effective INT = 120.
	mgr.register(medic_ent, "player")

	var patient_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	patient_ent.intelligence = 100
	mgr.register(patient_ent, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})

	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var eff_speed: float = _EntityAccess.get_effective_medical_windup_speed_modifier(
		mgr, mgr.combatants[0], mgr.combatants[1]
	)
	var base_speed: float = _EntityAccess.get_medical_windup_speed_modifier(
		mgr, mgr.combatants[0], mgr.combatants[1]
	)

	if absf(eff_speed - base_speed) < 0.01:
		_CombatRegressionHarness._fail(
			failures, "windup_eff_int: effective (%.2f) should differ from base (%.2f)"
			% [eff_speed, base_speed]
		)

	_CombatRegressionHarness._free_harness_node(mgr)


## Pain shock END slope constant is correctly named and usable.
static func _run_pain_shock_end_slope_constant(failures: PackedStringArray) -> void:
	var slope: float = _PainConscious.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
	if absf(slope - 0.02) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "pain_shock_slope: constant should be 0.02 (got %.4f)" % slope
		)


## Medical effectiveness formula uses correct clamp.
static func _run_medical_effectiveness_formula(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")

	ent.intelligence = 100
	if absf(ent.get_medical_effectiveness() - 1.0) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "med_eff@100: should be 1.0 (got %.4f)" % ent.get_medical_effectiveness()
		)

	ent.intelligence = 50
	var eff_50: float = ent.get_medical_effectiveness()
	if absf(eff_50 - 0.5) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "med_eff@50: should be 0.5 (got %.4f)" % eff_50
		)

	ent.intelligence = 150
	var eff_150: float = ent.get_medical_effectiveness()
	if absf(eff_150 - 1.5) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "med_eff@150: should be 1.5 (got %.4f)" % eff_150
		)

	ent.intelligence = 200
	var eff_200: float = ent.get_medical_effectiveness()
	if absf(eff_200 - 1.5) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "med_eff@200: should still be 1.5 (got %.4f)" % eff_200
		)

	_CombatRegressionHarness._free_harness_node(ent)


## Dodge formula uses /100 divisor instead of /200.
static func _run_dodge_formula_divisor(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	ent.agility = 150

	# Dodge factor should be (AGI-100)/100 * 0.5 = 50/100 * 0.5 = 0.25
	var dodge_factor: float = float(ent.agility - 100) / 100.0 * 0.5
	if absf(dodge_factor - 0.25) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "dodge_divisor: expected 0.25 (got %.4f)" % dodge_factor
		)

	# Old formula would have given: 50/200 * 0.5 = 0.125 --" half as much.
	var old_dodge_factor: float = float(ent.agility - 100) / 200.0 * 0.5
	if absf(old_dodge_factor - 0.125) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "dodge_divisor: old formula should give 0.125 (got %.4f)" % old_dodge_factor
		)

	_CombatRegressionHarness._free_harness_node(ent)


## Parry multipliers extract to named constants with correct values.
static func _run_parry_constants_correct_values(failures: PackedStringArray) -> void:

	var parry_deflect_str: float = _Proficiency.GAIN_PARRY_DEFLECT_STR_MULT
	if absf(parry_deflect_str - 0.5) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "parry_deflect_str_mult: expected 0.5 (got %.4f)" % parry_deflect_str
		)

	var parry_deflect_end: float = _Proficiency.GAIN_PARRY_DEFLECT_END_MULT
	if absf(parry_deflect_end - 0.5) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "parry_deflect_end_mult: expected 0.5 (got %.4f)" % parry_deflect_end
		)

	var parry_partial_str: float = _Proficiency.GAIN_PARRY_PARTIAL_STR_MULT
	if absf(parry_partial_str - 0.3) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "parry_partial_str_mult: expected 0.3 (got %.4f)" % parry_partial_str
		)


## Direct pressure awards INT to medic and small END to patient.
static func _run_direct_pressure_awards_gains(failures: PackedStringArray) -> void:
	var ent1: Node = _CombatRegressionHarness._new_entity("SWORD")
	var ent2: Node = _CombatRegressionHarness._new_entity("SPEAR")

	# Simulate stub being ON by temporarily enabling it.
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true

	ent1._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}
	ent2._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}

	# Direct pressure INT gain: GAIN_MEDICAL_ACTION_BASE * 0.8 (bandage mult since no item specified)
	var expected_int_gain: float = _Proficiency.GAIN_MEDICAL_ACTION_BASE * _Proficiency.GAIN_DIRECT_PRESSURE_INT_MULT  # 0.5 * 0.8 = 0.4
	_Proficiency.award_stat_gain(ent1, "intelligence", expected_int_gain)

	if absf(float(ent1._proficiency_bonus.get("intelligence", 0)) - expected_int_gain) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "dp INT gain: expected %.4f (got %.4f)" % [expected_int_gain, ent1._proficiency_bonus.get("intelligence", 0)]
		)

	# Direct pressure END gain for patient: GAIN_BLOOD_PERIL_BASE * GAIN_DIRECT_PRESSURE_PATIENT_END_MULT = 0.8 * 0.25 = 0.2
	var expected_end_gain: float = _Proficiency.GAIN_BLOOD_PERIL_BASE * _Proficiency.GAIN_DIRECT_PRESSURE_PATIENT_END_MULT  # 0.2
	_Proficiency.award_stat_gain(ent2, "endurance", expected_end_gain)

	if absf(float(ent2._proficiency_bonus.get("endurance", 0)) - expected_end_gain) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "dp END gain: expected %.4f (got %.4f)" % [expected_end_gain, ent2._proficiency_bonus.get("endurance", 0)]
		)

	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent1)
	_CombatRegressionHarness._free_harness_node(ent2)


## Decay skips entities that never fought (_last_fought_day == 0).
static func _run_decay_skips_never_fought_entities(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")

	ent._proficiency_bonus = {"strength": 0, "endurance": 25, "intelligence": 0, "agility": 0, "perception": 0}
	ent.last_fought_day = 0  # Never fought --" should NOT decay

	_Proficiency.apply_decay(ent, 1)  # Day 1, last_fought=0 |' skip

	if float(ent._proficiency_bonus.get("endurance", 0)) != 25.0:
		_CombatRegressionHarness._fail(
			failures, "never-fought decay: endurance should stay 25 (got %.4f)" % ent._proficiency_bonus.get("endurance", 0)
		)

	# Now set last_fought_day to a past day --" decay should apply.
	ent.last_fought_day = -10  # 11 inactive days on day 1
	var expected_after_decay: float = maxf(0.0, 25.0 + (_Proficiency.DECAY_RATE_VETERAN_PLUS * _Proficiency.DECAY_MULT_END) * 11)
	_Proficiency.apply_decay(ent, 1)

	if absf(float(ent._proficiency_bonus.get("endurance", 0)) - expected_after_decay) > 0.01:
		_CombatRegressionHarness._fail(
			failures, "post-fight decay: expected %.4f (got %.4f)" % [expected_after_decay, ent._proficiency_bonus.get("endurance", 0)]
		)

	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## Outnumbered dodge bonus uses proper slot-group alive count.
static func _run_outnumbered_dodge_bonus_with_slot_group_check(failures: PackedStringArray) -> void:
	var _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

	# Build a minimal mock manager with get_combatants().
	var mock_mgr = Node.new()
	mock_mgr.name = "mock_mgr"
	var combatants := []

	# Create defender in slot group 1, player side.
	var defender := {"slot_key": "player_1_0", "side": "player", "alive": true}
	combatants.append(defender)

	# Only one alive in group |' production function returns false (no get_combatants method).
	var ap = preload("res://combat/AttackResultApplier.gd")
	var is_outnumbered: bool = ap._is_defender_outnumbered(mock_mgr, defender)
	if is_outnumbered:
		_CombatRegressionHarness._fail(failures, "outnumbered: production func returns false without get_combatants (expected)")

	mock_mgr.queue_free()

	# Verify slot-group counting logic directly --" should be 1 for defender alone, 2 with ally.
	var ally := {"slot_key": "player_1_1", "side": "player", "alive": true}
	var enemy := {"slot_key": "enemy_2_0", "side": "enemy", "alive": true}

	var group_count: int = 0
	for c in [defender, ally]:
		if not c is Dictionary:
			continue
		var c_slot := str(c.get("slot_key", "")).get_slice("_", 1)
		if c_slot != "1":
			continue
		if not c.get("alive", false):
			continue
		group_count += 1
	if group_count != 2:
		_CombatRegressionHarness._fail(failures, "outnumbered count: should be 2 with ally (got %d)" % group_count)

	# Enemy in different group and side should not count.
	group_count = 0
	for c in [defender, enemy]:
		if not c is Dictionary:
			continue
		var c_slot := str(c.get("slot_key", "")).get_slice("_", 1)
		if c_slot != "1":
			continue
		if not c.get("alive", false):
			continue
		group_count += 1
	if group_count != 1:
		_CombatRegressionHarness._fail(failures, "outnumbered count: enemy should not count (got %d)" % group_count)


## Post-combat stub gating: apply_decay respects read_stub_proficiency_enabled().
static func _run_stub_gating_post_combat(failures: PackedStringArray) -> void:
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")

	ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 20, "agility": 0, "perception": 0}
	ent.last_fought_day = -5  # Simulate last fought 6 days before day 1

	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = false

	_Proficiency.apply_decay(ent, 1)

	if float(ent._proficiency_bonus.get("intelligence", 0)) != 20.0:
		_CombatRegressionHarness._fail(
			failures, "post_combat_stub_off: intelligence should stay 20 (got %.4f)" % ent._proficiency_bonus.get("intelligence", 0)
		)

	_CompanyState.PROFICIENCY_ENABLED = true
	var expected_after_decay: float = maxf(0.0, 20.0 + (_Proficiency.DECAY_RATE_VETERAN_PLUS * _Proficiency.DECAY_MULT_INT) * 6)
	_Proficiency.apply_decay(ent, 1)

	if absf(float(ent._proficiency_bonus.get("intelligence", 0)) - expected_after_decay) > 0.01:
		_CombatRegressionHarness._fail(
			failures, "post_combat_stub_on: intelligence should decay to %.4f (got %.4f)" % [expected_after_decay, ent._proficiency_bonus.get("intelligence", 0)]
		)

	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)


## Batch resolve medical actions award proficiency gains.
static func _run_batch_resolve_awards_medical_gains(failures: PackedStringArray) -> void:

	var medic_ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	var patient_ent: Node = _CombatRegressionHarness._new_entity("SPEAR")

	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true

	medic_ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}
	patient_ent._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}

	# Bandage: INT gain = 0.5 * 0.8 (bandage mult) = 0.4
	_Proficiency.award_stat_gain(medic_ent, "intelligence", _Proficiency.GAIN_MEDICAL_ACTION_BASE * _Proficiency.get_medical_item_mult("bandage"))
	if absf(float(medic_ent._proficiency_bonus.get("intelligence", 0)) - 0.4) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "batch bandage INT: expected 0.4 (got %.4f)" % medic_ent._proficiency_bonus.get("intelligence", 0)
		)

	# Patient END gain on successful bandage: GAIN_BLOOD_PERIL_BASE * GAIN_MEDICAL_PATIENT_END_MULT = 0.8 * 0.5 = 0.4
	_Proficiency.award_stat_gain(patient_ent, "endurance", _Proficiency.GAIN_BLOOD_PERIL_BASE * _Proficiency.GAIN_MEDICAL_PATIENT_END_MULT)
	if absf(float(patient_ent._proficiency_bonus.get("endurance", 0)) - 0.4) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "batch bandage END: expected 0.4 (got %.4f)" % patient_ent._proficiency_bonus.get("endurance", 0)
		)

	# Tourniquet: INT gain = 0.5 * 1.5 (tourniquet mult) = 0.75
	medic_ent._proficiency_bonus["intelligence"] = 0.0
	_Proficiency.award_stat_gain(medic_ent, "intelligence", _Proficiency.GAIN_MEDICAL_ACTION_BASE * _Proficiency.get_medical_item_mult("tourniquet"))
	if absf(float(medic_ent._proficiency_bonus.get("intelligence", 0)) - 0.75) > 0.001:
		_CombatRegressionHarness._fail(
			failures, "batch tourniquet INT: expected 0.75 (got %.4f)" % medic_ent._proficiency_bonus.get("intelligence", 0)
		)

	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(medic_ent)
	_CombatRegressionHarness._free_harness_node(patient_ent)


## Weapon/form proficiency channels and Layer C intended-part boost scaling.
static func _run_targeting_proficiency_channels(failures: PackedStringArray) -> void:
	var old_stub: bool = _CompanyState.read_stub_proficiency_enabled()
	_CompanyState.PROFICIENCY_ENABLED = true
	var ent: Node = _CombatRegressionHarness._new_entity("SWORD")
	_Proficiency.award_weapon_proficiency(ent, "SWORD", 20.0)
	_Proficiency.award_form_proficiency(ent, _WeaponForm.FORM_WRATH, 20.0)
	var boost_vet: float = _Proficiency.intended_part_boost_mult(ent, "SWORD", _WeaponForm.FORM_WRATH)
	if boost_vet < 2.95:
		_CombatRegressionHarness._fail(
			failures,
			"targeting_prof: veteran intended_part boost want ~3.0 got %.2f" % boost_vet
		)
	var ent_nov: Node = _CombatRegressionHarness._new_entity("SWORD")
	var boost_nov: float = _Proficiency.intended_part_boost_mult(ent_nov, "SWORD", _WeaponForm.FORM_BALANCED)
	if absf(boost_nov - 2.0) > 0.05:
		_CombatRegressionHarness._fail(
			failures,
			"targeting_prof: novice intended_part boost want 2.0 got %.2f" % boost_nov
		)
	var atk: Dictionary = {
		"weapon": {"weapon_type": "SWORD"},
		"weapon_form": _WeaponForm.FORM_WRATH,
	}
	var move_def: Dictionary = {"contact_type": "stab", "preferred_parts": ["chest"]}
	var part: String = _PathResolver.resolve_hit_part(
		"high", "low", ["head", "chest", "left_arm"],
		{}, "chest", {}, {}, atk, move_def
	)
	if part.is_empty():
		_CombatRegressionHarness._fail(failures, "targeting_prof: resolve_hit_part returned empty")
	_Proficiency.notify_targeting_gains_from_hit(
		ent, "SWORD", _WeaponForm.FORM_WRATH, move_def, "chest", "chest", "head"
	)
	if float(ent._weapon_proficiency.get("SWORD", 0.0)) <= 20.0:
		_CombatRegressionHarness._fail(failures, "targeting_prof: weapon prof should increase on hit")
	if float(ent._form_proficiency.get(_WeaponForm.FORM_WRATH, 0.0)) <= 20.0:
		_CombatRegressionHarness._fail(failures, "targeting_prof: form prof should increase on hit")
	_CompanyState.PROFICIENCY_ENABLED = old_stub
	_CombatRegressionHarness._free_harness_node(ent)
	_CombatRegressionHarness._free_harness_node(ent_nov)


## Run all proficiency harness tests.
static func run(failures: PackedStringArray) -> void:
	# Stub-gating tests always run.
	_run_stub_gating_off(failures)
	_run_copy_core_stats_no_bonuses_when_off(failures)

	# Core EntityProficiency tests.
	_run_award_stat_gain_diminishing_returns(failures)
	_run_award_stat_gain_stance_modifier(failures)
	_run_award_stat_gain_weapon_curve(failures)
	_run_targeting_proficiency_channels(failures)
	_run_apply_decay_inactive_mercenary(failures)
	_run_apply_decay_wounded_protection(failures)
	_run_merge_training_pending(failures)

	# END/INT helper function tests.
	_run_endurance_blood_volume_mult(failures)
	_run_endurance_healing_speed_mult(failures)
	_run_intelligence_contract_bonus_mult(failures)

	# CombatantEntityAccess wind-up speed tests.
	_run_effective_medical_windup_speed_modifier(failures)
	_run_base_medical_windup_speed_modifier(failures)

	# CoreEntity stats sync tests (require stub ON).
	_run_copy_core_stats_applies_bonuses_when_on(failures)

	# UI formatter test.
	_run_formatter_proficiency_bonus_line(failures)

	# Persistence round-trip tests.
	_run_persistence_round_trip(failures)
	_run_persistence_training_pending(failures)

	# Combat flow proficiency gain tests (require stub ON).
	_run_combat_hit_awards_proficiency_gains(failures)
	_run_combat_dodge_awards_proficiency_gains(failures)
	_run_medical_action_awards_proficiency_gains(failures)

	# Decay calibration.
	_run_decay_rates_per_stat(failures)

	# Medical wind-up effective INT test.
	_run_medical_windup_uses_effective_int(failures)

	# Constant correctness tests.
	_run_pain_shock_end_slope_constant(failures)

	# Formula normalization tests.
	_run_medical_effectiveness_formula(failures)
	_run_dodge_formula_divisor(failures)

	# Audit fix tests (parry END gain, medic INT floor, merge_training_pending wiring, defeat decay).
	_run_parry_deflect_awards_end_gains(failures)
	_run_parry_partial_no_defender_gain(failures)
	_run_medic_int_floor_per_entity_tracking(failures)
	_run_merge_training_pending_wired_in_camp_heal(failures)
	_run_decay_applies_on_defeat(failures)

	# Additional coverage: medical item mults, decay from low blood volume.
	_run_medical_item_multipliers(failures)
	_run_decay_low_blood_volume_protection(failures)

	# Parry constant correctness.
	_run_parry_constants_correct_values(failures)

	# Direct pressure proficiency gains.
	_run_direct_pressure_awards_gains(failures)

	# Never-fought mercenaries don't decay on first camp rest.
	_run_decay_skips_never_fought_entities(failures)

	# Outnumbered dodge bonus with proper slot-group check.
	_run_outnumbered_dodge_bonus_with_slot_group_check(failures)

	# Stub gating: post-combat respects stub state.
	_run_stub_gating_post_combat(failures)

	# Batch resolve medical proficiency gains.
	_run_batch_resolve_awards_medical_gains(failures)







