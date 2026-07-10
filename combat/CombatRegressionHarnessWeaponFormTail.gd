class_name CombatRegressionHarnessWeaponFormTail
extends RefCounted

## Expand WF: weapon form spawn, mods, picker weights, pressure class, UI suffix parity.
## Footing rows: home guard on **`assign_form`** . gauge/diagram **` . Form`** / **`[Ox]`**  -  not PA step. LIVE_PATHS **`#harness-row-catalog-combatregressionharnessweaponformtailgd`** . soak open scope **`#wf-soak-audit-status`** . compose **`#battle-ui`**.

const _Attention := preload("res://combat/CombatAttention.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _Tier1Tail := preload("res://combat/CombatRegressionHarnessTier1Tail.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _Diagram := preload("res://ui/FormationDiagramBuilder.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _LogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")


static func run(failures: PackedStringArray) -> void:
	_run_weapon_form_spawn_default_guard(failures)
	_run_weapon_form_allowed_forms_clamp(failures)
	_run_weapon_form_normalize_stance_alias(failures)
	_run_weapon_form_mod_parity_stance_alias(failures)
	_run_weapon_form_move_weight_distribution(failures)
	_run_weapon_form_axe_chop_weight_bias(failures)
	_run_weapon_form_pressure_class_zoc(failures)
	_run_weapon_form_close_controlling_evasion(failures)
	_run_weapon_form_controlling_disengage_pressure(failures)
	_run_weapon_form_controlling_disengage_listing_weight(failures)
	_run_weapon_form_controlling_close_listing_weight(failures)
	_run_weapon_form_controlling_close_turn_hint(failures)
	_run_weapon_form_controlling_close_list_stamp(failures)
	_run_weapon_form_controlling_close_listed_turn_detail(failures)
	_run_weapon_form_close_failed_log_controlling_note(failures)
	_run_weapon_form_close_resolve_contest_note(failures)
	_run_weapon_form_controlling_pressure_stamina_gate(failures)
	_run_weapon_form_turn_ready_listing_close_controlling(failures)
	_run_weapon_form_harness_assign_form_home_guard(failures)
	_run_weapon_form_octant_attack_path_cardinal_lookup(failures)
	_run_weapon_form_wait_weight_wall(failures)
	_run_weapon_form_wind_up_native_line(failures)
	_run_weapon_form_auto_switch_duel(failures)
	_run_weapon_form_auto_switch_duel_yomi(failures)
	_run_weapon_form_auto_switch_duel_yomi_ox_to_fool(failures)
	_run_weapon_form_auto_switch_surround(failures)
	_run_weapon_form_auto_switch_envelop_block(failures)
	_run_weapon_form_preference_spawn(failures)
	_run_weapon_form_yomi_inference(failures)
	_run_weapon_form_counter_pick(failures)
	_run_weapon_form_ui_suffix(failures)
	_run_weapon_form_wf_t2_suite(failures)


static func _run_weapon_form_spawn_default_guard(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var c: Dictionary = mgr.combatants[0]
	if _EntityAccess.form_str(c) != _WeaponForm.FORM_OX:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: spawn_default expected ox got %s" % _EntityAccess.form_str(c)
		)
	var home: String = _WeaponForm.home_guard_line(_WeaponForm.FORM_OX)
	if str(c.get("guard_line", "")) != home:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: spawn guard_line want %s got %s" % [home, c.get("guard_line", "")]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_allowed_forms_clamp(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("DAGGER"), "player")
	var c: Dictionary = mgr.combatants[0]
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_WRATH, "test")
	if _EntityAccess.form_str(c) != _WeaponForm.FORM_DAGGER_HIGH:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: dagger wrath alias want high_hut got %s" % _EntityAccess.form_str(c)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_normalize_stance_alias(failures: PackedStringArray) -> void:
	if _WeaponForm.normalize_form("defensive") != _WeaponForm.FORM_WALL:
		CombatRegressionHarness._fail(failures, "weapon_form: defensive alias")
	if _WeaponForm.normalize_form("aggressive") != _WeaponForm.FORM_WRATH:
		CombatRegressionHarness._fail(failures, "weapon_form: aggressive alias")
	if _WeaponForm.normalize_form("controlling") != _WeaponForm.FORM_FOOL:
		CombatRegressionHarness._fail(failures, "weapon_form: controlling alias")


static func _run_weapon_form_mod_parity_stance_alias(failures: PackedStringArray) -> void:
	for effect in ["parry", "evasion", "damage", "close_attempt", "ai_melee_focus", "feint_readthrough", "ai_feint_listing"]:
		var old_defensive: float = CombatConstants.get_stance_modifier(CombatConstants.STANCE_DEFENSIVE, effect)
		var wall: float = _WeaponForm.mod(_WeaponForm.FORM_WALL, effect)
		if absf(old_defensive - wall) > 0.001:
			CombatRegressionHarness._fail(
				failures,
				"weapon_form: wall/%s parity want %.3f got %.3f" % [effect, old_defensive, wall]
			)


static func _run_weapon_form_move_weight_distribution(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_PLOW, "test")
	var cid: int = _EntityAccess.id_int(c)
	var act_stab: Dictionary = {"move_id": "spear_thrust", "target_id": _EntityAccess.id_int(mgr.combatants[1])}
	var act_slash: Dictionary = {"move_id": "spear_slash", "target_id": _EntityAccess.id_int(mgr.combatants[1])}
	var w_stab: float = _AIPicker._get_action_weight(act_stab, cid, mgr, true, {}, {})
	var w_slash: float = _AIPicker._get_action_weight(act_slash, cid, mgr, true, {}, {})
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_BALANCED, "test")
	var w_stab_bal: float = _AIPicker._get_action_weight(act_stab, cid, mgr, true, {}, {})
	if w_stab <= w_stab_bal:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: plow stab weight want > balanced (%.3f vs %.3f)" % [w_stab, w_stab_bal]
		)
	if w_stab <= w_slash:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: plow stab want > slash (%.3f vs %.3f)" % [w_stab, w_slash]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_axe_chop_weight_bias(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("AXE"), "player")
	mgr.register(CombatRegressionHarness._new_entity("AXE"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var weapon: Variant = _EntityAccess.get_weapon(c)
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_AXE_DEMI, "test")
	var cid: int = _EntityAccess.id_int(c)
	var tid: int = _EntityAccess.id_int(mgr.combatants[1])
	var act_chop: Dictionary = {"move_id": "overhead_chop", "target_id": tid}
	var act_thrust: Dictionary = {"move_id": "spike_thrust", "target_id": tid}
	var w_chop: float = _AIPicker._get_action_weight(act_chop, cid, mgr, true, {}, {})
	var w_thrust: float = _AIPicker._get_action_weight(act_thrust, cid, mgr, true, {}, {})
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_BALANCED, "test")
	var w_chop_bal: float = _AIPicker._get_action_weight(act_chop, cid, mgr, true, {}, {})
	if w_chop <= w_chop_bal:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: demi_hache chop want > balanced (%.3f vs %.3f)" % [w_chop, w_chop_bal]
		)
	if w_chop <= w_thrust:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: demi_hache chop want > spike_thrust (%.3f vs %.3f)" % [w_chop, w_thrust]
		)
	var bec_chop: float = _WeaponForm.action_weight_mult(
		_WeaponForm.FORM_AXE_BEC, "overhead_chop", weapon
	)
	var demi_chop: float = _WeaponForm.action_weight_mult(
		_WeaponForm.FORM_AXE_DEMI, "overhead_chop", weapon
	)
	if demi_chop <= bec_chop:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: demi_hache overhead_chop mult want > bec_point (%.3f vs %.3f)"
			% [demi_chop, bec_chop]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_pressure_class_zoc(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			_WeaponForm.assign_form(mgr, c as Dictionary, _WeaponForm.FORM_WRATH, "test")
			c["stamina"] = CombatConstants.STAMINA_MAX
	var mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(mgr, "player")
	if mod != CombatConstants.PRESSURE_MOD_AGGRESSIVE:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: zoc aggressive want %.2f got %.2f"
			% [CombatConstants.PRESSURE_MOD_AGGRESSIVE, mod]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_close_controlling_evasion(failures: PackedStringArray) -> void:
	var old_controlling_close: float = CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	var fool_div: float = _WeaponForm.opponent_close_evasion_divisor(_WeaponForm.FORM_FOOL)
	if absf(old_controlling_close - fool_div) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fool close divisor want %.2f got %.2f" % [old_controlling_close, fool_div]
		)
	var close_list: float = _WeaponForm.opponent_close_listing_weight_mult(_WeaponForm.FORM_FOOL)
	if absf(close_list - old_controlling_close) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fool close listing mult want %.2f got %.2f" % [old_controlling_close, close_list]
		)


static func _run_weapon_form_controlling_disengage_pressure(failures: PackedStringArray) -> void:
	var old_controlling_disengage: float = 1.0 / CombatConstants.STANCE_MOD_OPPONENT_DISENGAGE
	var fool_mult: float = _WeaponForm.opponent_disengage_pressure_mult(_WeaponForm.FORM_FOOL)
	if absf(old_controlling_disengage - fool_mult) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fool disengage mult want %.4f got %.4f" % [old_controlling_disengage, fool_mult]
		)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			_WeaponForm.assign_form(mgr, c as Dictionary, _WeaponForm.FORM_FOOL, "test")
			c["stamina"] = CombatConstants.STAMINA_MAX
			c["state"] = CombatConstants.STATE_WAITING
	var mod_neutral: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(mgr, "player")
	var want: float = CombatConstants.PRESSURE_MOD_NEUTRAL * old_controlling_disengage
	if absf(mod_neutral - want) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fool disengage pressure want %.4f got %.4f"
			% [want, mod_neutral]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_disengage_listing_weight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			_WeaponForm.assign_form(mgr, c as Dictionary, _WeaponForm.FORM_FOOL, "test")
			c["stamina"] = CombatConstants.STAMINA_MAX
			c["state"] = CombatConstants.STATE_WAITING
	var acts: Array = [
		{"move_id": CombatConstants.MOVE_ID_FALL_BACK, "target_id": _EntityAccess.id_int(player)},
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": _EntityAccess.id_int(player)},
	]
	var fb_w: float = _AIPicker._get_action_weight(
		acts[0], _EntityAccess.id_int(player), mgr
	)
	var mgr_clear: Node = _MgrScript.new()
	mgr_clear.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_clear.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_clear.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player_clear: Dictionary = mgr_clear.combatants[0]
	for c in mgr_clear.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			_WeaponForm.assign_form(mgr_clear, c as Dictionary, _WeaponForm.FORM_BALANCED, "test")
			c["stamina"] = CombatConstants.STAMINA_MAX
			c["state"] = CombatConstants.STATE_WAITING
	var fb_w_clear: float = _AIPicker._get_action_weight(
		acts[0], _EntityAccess.id_int(player_clear), mgr_clear
	)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_clear)
	if fb_w_clear <= 0.0 or fb_w >= fb_w_clear:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fool front should lower fall_back weight got fool=%.4f clear=%.4f"
			% [fb_w, fb_w_clear]
		)


static func _run_weapon_form_controlling_close_listing_weight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.recompute_zoc_and_distance()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "player", 0, 6
	)
	var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "enemy", 0, 2
	)
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: missing 7v3 wing fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["gauge"] = 100.0
	enemy["gauge"] = 100.0
	_EntityAccess.nested_dictionary_for_mutation(player, "distance_to")[e_id] = (
		CombatConstants.DISTANCE_LONG
	)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = (
		CombatConstants.DISTANCE_LONG
	)
	if _PairGeometry.melee_reach_covers_eff_dist(
		_MeleeListing.melee_weapon_reach(player),
		_PairGeometry.effective_pair_eff_dist(mgr, player, enemy)
	):
		CombatRegressionHarness._fail(
			failures, "weapon_form: wing setup want out-of-reach LONG for close vs Fool"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_FOOL, "test")
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var close_fool: Dictionary = {
		"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
		"target_id": e_id,
	}
	var mgr_bal: Node = _MgrScript.new()
	for _i in 7:
		mgr_bal.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr_bal.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_bal.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_bal._recompute_zoc_and_distance()
	var player_bal: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr_bal, "player", 0, 6
	)
	var enemy_bal: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr_bal, "enemy", 0, 2
	)
	if player_bal.is_empty() or enemy_bal.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: missing balanced wing fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr_bal)
		return
	var p_id_bal: int = _EntityAccess.id_int(player_bal)
	var e_id_bal: int = _EntityAccess.id_int(enemy_bal)
	player_bal["gauge"] = 100.0
	enemy_bal["gauge"] = 100.0
	_EntityAccess.nested_dictionary_for_mutation(player_bal, "distance_to")[e_id_bal] = (
		CombatConstants.DISTANCE_LONG
	)
	_EntityAccess.nested_dictionary_for_mutation(enemy_bal, "distance_to")[p_id_bal] = (
		CombatConstants.DISTANCE_LONG
	)
	_WeaponForm.assign_form(mgr_bal, enemy_bal, _WeaponForm.FORM_BALANCED, "test")
	enemy_bal["stamina"] = CombatConstants.STAMINA_MAX
	var w_fool: float = _AIPicker._get_action_weight(close_fool, p_id, mgr, true)
	var close_bal: Dictionary = {
		"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
		"target_id": e_id_bal,
	}
	var w_bal: float = _AIPicker._get_action_weight(close_bal, p_id_bal, mgr_bal, true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_bal)
	if w_bal <= 0.001 or w_fool >= w_bal:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fool defender should lower close weight got fool=%.4f bal=%.4f"
			% [w_fool, w_bal]
		)


static func _run_weapon_form_controlling_close_turn_hint(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_FOOL, "test")
	var acts: Array = [
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
	]
	var hint: String = _UiHints.controlling_defender_close_hint_line(mgr, player, acts)
	if hint.is_empty() or not hint.to_lower().contains("fool"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: controlling close hint want Fool copy got '%s'" % hint
		)
	player["state"] = CombatConstants.STATE_WAITING
	player["gauge"] = 100.0
	_PlayerTurnHints.sync_controlling_close_turn_hint_on_combatant(mgr, player, acts)
	var gauge_tips: String = "\n".join(_UiHints.gauge_tooltip_lines(player, mgr))
	if not gauge_tips.contains("Fool") or not gauge_tips.to_lower().contains("controlling"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: controlling close gauge tip want Fool/controlling got '%s'" % gauge_tips
		)
	var acts_bal: Array = [{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id}]
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_BALANCED, "test")
	var hint_bal: String = _UiHints.controlling_defender_close_hint_line(mgr, player, acts_bal)
	if not hint_bal.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: balanced defender should not emit controlling close hint got '%s'"
			% hint_bal
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_close_list_stamp(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.recompute_zoc_and_distance()
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
		player["distance_to"] = {}
	if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
		enemy["distance_to"] = {}
	(player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(enemy["distance_to"] as Dictionary)[_EntityAccess.id_int(player)] = CombatConstants.DISTANCE_LONG
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_FOOL, "test")
	var acts: Array = []
	_MeleeListing._append_attempt_close_action(acts, enemy)
	if acts.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: close list stamp want one action")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var tag: String = str(acts[0].get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")).strip_edges()
	if not tag.to_lower().contains("fool") or not tag.contains("controlling"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: close list stamp want Fool (controlling) got '%s'" % tag
		)
	var menu: String = _MoveDuration.formation_listed_moves_menu_line(acts)
	if not menu.contains("Fool"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: close menu line want Fool tag got '%s'" % menu
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_close_listed_turn_detail(failures: PackedStringArray) -> void:
	var acts: Array = [
		{
			"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
			"target_id": 1,
			CombatConstants.ACTION_KEY_CLOSE_LIST_HINT: "Fool (controlling)",
		},
	]
	var detail: String = _MoveDuration.formation_listed_moves_turn_hint(acts)
	if not detail.to_lower().contains("fool") or not detail.contains("harder"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: close turn detail want Fool/harder got '%s'" % detail
		)


static func _run_weapon_form_close_failed_log_controlling_note(failures: PackedStringArray) -> void:
	var result: Dictionary = {
		"outcome": "close_failed",
		"reason": "contest_failed",
		"close_contest_note": "Fool (controlling)",
	}
	var line: String = _LogFormatter.format_action_line(
		"Alice", "player", "Bob", "enemy", result
	)
	if not line.contains("Fool") or not line.contains("held their measure"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: close_failed log want Fool measure copy got '%s'" % line
		)
	var plain: Dictionary = {
		"outcome": "close_failed",
		"reason": "contest_failed",
	}
	var line_plain: String = _LogFormatter.format_action_line(
		"Alice", "player", "Bob", "enemy", plain
	)
	if line_plain.contains("Fool"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: close_failed log without note should omit form got '%s'" % line_plain
		)


static func _run_weapon_form_close_resolve_contest_note(failures: PackedStringArray) -> void:
	var fixtures: Array = CombatRegressionHarness._harness_7v3_wing_rank0_fixtures()
	var mgr: Node = fixtures[0] as Node
	var p: Dictionary = fixtures[1] as Dictionary
	var en: Dictionary = fixtures[2] as Dictionary
	if p.is_empty() or en.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: missing 7v3 wing fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(en)
	CombatRegressionHarness._harness_bind_pair_long_band(p, en)
	_WeaponForm.assign_form(mgr, en, _WeaponForm.FORM_FOOL, "test")
	en["stamina"] = CombatConstants.STAMINA_MAX
	var sd: Dictionary = _EntityAccess.stats_dict_for_mutation(p)
	sd["strength"] = 0.0
	var cap: Array = []
	mgr.action_resolved.connect(
		func(_aid: int, _tid: int, result: Dictionary) -> void:
			cap.clear()
			cap.append(result)
	)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if cap.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: close resolve want payload")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var r: Dictionary = cap[0] as Dictionary
	var note: String = str(r.get("close_contest_note", "")).strip_edges()
	if str(r.get("outcome", "")) != "close_failed" or note.is_empty() or not note.to_lower().contains("fool"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: close resolve want Fool contest note got %s" % str(r)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_pressure_stamina_gate(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
		player["distance_to"] = {}
	if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
		enemy["distance_to"] = {}
	(player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_FOOL, "test")
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	enemy["state"] = CombatConstants.STATE_WAITING
	if not _WeaponForm.controlling_pressure_active(enemy):
		CombatRegressionHarness._fail(failures, "weapon_form: fresh fool should have controlling pressure")
	var fresh_tip: String = _UiHints.weapon_form_tooltip_line(enemy)
	if not fresh_tip.to_lower().contains("controlling"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fresh fool tooltip want controlling got '%s'" % fresh_tip
		)
	if _ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(mgr, "player") <= 1.01:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: fresh fool front should pin disengage"
		)
	enemy["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	if _WeaponForm.controlling_pressure_active(enemy):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: exhausted fool should not have controlling pressure"
		)
	var exhaust_tip: String = _UiHints.weapon_form_tooltip_line(enemy)
	if exhaust_tip.to_lower().contains("controlling"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: exhausted fool tooltip should omit controlling got '%s'" % exhaust_tip
		)
	if _ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(mgr, "player") > 1.01:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: exhausted fool front should not pin disengage"
		)
	var acts: Array = [{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id}]
	var hint: String = _UiHints.controlling_defender_close_hint_line(mgr, player, acts)
	if not hint.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: exhausted fool should not emit close hint got '%s'" % hint
		)
	var close_act: Dictionary = {
		"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
		"target_id": e_id,
	}
	var w_exhaust: float = _AIPicker._get_action_weight(close_act, p_id, mgr, true)
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_BALANCED, "test")
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var w_bal: float = _AIPicker._get_action_weight(close_act, p_id, mgr, true)
	if absf(w_exhaust - w_bal) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: exhausted fool close weight should match balanced got ex=%.4f bal=%.4f"
			% [w_exhaust, w_bal]
		)
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_FOOL, "test")
	enemy["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	var wing_fix: Array = CombatRegressionHarness._harness_7v3_wing_rank0_fixtures()
	var wing_mgr: Node = wing_fix[0] as Node
	var wing_player: Dictionary = wing_fix[1] as Dictionary
	var wing_enemy: Dictionary = wing_fix[2] as Dictionary
	if wing_player.is_empty() or wing_enemy.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: exhausted fool resolve missing wing fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(wing_mgr)
		return
	var wing_p_id: int = _EntityAccess.id_int(wing_player)
	var wing_e_id: int = _EntityAccess.id_int(wing_enemy)
	CombatRegressionHarness._harness_bind_pair_long_band(wing_player, wing_enemy)
	_WeaponForm.assign_form(wing_mgr, wing_enemy, _WeaponForm.FORM_FOOL, "test")
	wing_enemy["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	var cap: Array = []
	wing_mgr.action_resolved.connect(
		func(_aid: int, _tid: int, result: Dictionary) -> void:
			cap.clear()
			cap.append(result)
	)
	var sd_wing: Dictionary = _EntityAccess.stats_dict_for_mutation(wing_player)
	sd_wing["strength"] = 0.0
	_EngagementResolver.resolve_close_attempt(wing_mgr, wing_p_id, wing_e_id)
	if cap.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: exhausted fool close resolve want payload")
	elif not str((cap[0] as Dictionary).get("close_contest_note", "")).strip_edges().is_empty():
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: exhausted fool close resolve should omit contest note got %s" % str(cap[0])
		)
	CombatRegressionHarness._free_manager_restore_global_rng(wing_mgr)


static func _run_weapon_form_turn_ready_listing_close_controlling(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.recompute_zoc_and_distance()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "player", 0, 6
	)
	var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "enemy", 0, 2
	)
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: missing 7v3 wing fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["gauge"] = 100.0
	player["state"] = CombatConstants.STATE_WAITING
	_EntityAccess.nested_dictionary_for_mutation(player, "distance_to")[e_id] = (
		CombatConstants.DISTANCE_LONG
	)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = (
		CombatConstants.DISTANCE_LONG
	)
	if _PairGeometry.melee_reach_covers_eff_dist(
		_MeleeListing.melee_weapon_reach(player),
		_PairGeometry.effective_pair_eff_dist(mgr, player, enemy)
	):
		CombatRegressionHarness._fail(
			failures, "weapon_form: wing setup want out-of-reach LONG for close vs Fool"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	_WeaponForm.assign_form(mgr, enemy, _WeaponForm.FORM_FOOL, "test")
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var acts: Array = []
	_MeleeListing._append_attempt_close_action(acts, enemy)
	if acts.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form: turn_ready listing want attempt_close")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var tag: String = str(acts[0].get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")).strip_edges()
	if not tag.to_lower().contains("fool"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: listed close want Fool stamp got '%s'" % tag
		)
	var fp_line: String = _MoveDuration.formation_listed_moves_turn_hint(acts)
	if not fp_line.to_lower().contains("fool") or not fp_line.contains("harder"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: turn_ready FP line want Fool/harder got '%s'" % fp_line
		)
	var menu_actions: Array = mgr.get_available_actions(p_id)
	var listed_close_vs_fool: bool = false
	for raw in menu_actions:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			continue
		if int(a.get("target_id", -1)) != e_id:
			continue
		listed_close_vs_fool = true
		var menu_tag: String = str(a.get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")).strip_edges()
		if not menu_tag.to_lower().contains("fool"):
			CombatRegressionHarness._fail(
				failures,
				"weapon_form: menu close want Fool stamp got '%s'" % menu_tag
			)
	if not listed_close_vs_fool:
		CombatRegressionHarness._fail(
			failures, "weapon_form: get_available_actions want attempt_close vs Fool target"
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_harness_assign_form_home_guard(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var c: Dictionary = mgr.combatants[0]
	CombatRegressionHarness.harness_assign_form(mgr, c, _WeaponForm.FORM_WRATH)
	if _EntityAccess.form_str(c) != _WeaponForm.FORM_WRATH:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: harness_assign_form want wrath got %s" % _EntityAccess.form_str(c)
		)
	var home: String = _WeaponForm.home_guard_line(_WeaponForm.FORM_WRATH)
	if str(c.get("guard_line", "")) != home:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: harness_assign_form home guard want %s got %s"
			% [home, str(c.get("guard_line", ""))]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_octant_attack_path_cardinal_lookup(failures: PackedStringArray) -> void:
	var path_oct: Array = CombatConstants.get_attack_path("high_left", "low")
	var path_card: Array = CombatConstants.get_attack_path("high", "low")
	if str(path_oct) != str(path_card):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: octant attack path high_left/low want cardinal parity got oct=%s card=%s"
			% [str(path_oct), str(path_card)]
		)
	var path_wrath_home: Array = CombatConstants.get_attack_path("high", "high_left")
	var path_left_guard: Array = CombatConstants.get_attack_path("high", "left")
	var path_high_guard: Array = CombatConstants.get_attack_path("high", "high")
	if CombatConstants.is_feature_iv6_attack_path_octant_enabled():
		if str(path_wrath_home) == str(path_left_guard):
			CombatRegressionHarness._fail(
				failures,
				"weapon_form: IV-6 high_left guard path must differ from left flank got %s"
				% str(path_wrath_home)
			)
		if str(path_wrath_home) == str(path_high_guard):
			CombatRegressionHarness._fail(
				failures,
				"weapon_form: IV-6 high_left guard path must differ from high guard got %s"
				% str(path_wrath_home)
			)
		if str(path_wrath_home[0]) != CombatConstants.guard_zone_for_guard_line("high_left"):
			CombatRegressionHarness._fail(
				failures,
				"weapon_form: IV-6 high_left guard path must lead with zone %s got %s"
				% [
					CombatConstants.guard_zone_for_guard_line("high_left"),
					str(path_wrath_home[0])
				]
			)
	elif str(path_wrath_home) != str(path_left_guard):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: IV-4 high_left guard want left-side path got %s vs %s"
			% [str(path_wrath_home), str(path_left_guard)]
		)
	var fallback: Array = CombatConstants.get_attack_path("high", "__no_such_guard__")
	var want_fallback: Array = CombatConstants.ATTACK_PATHS.get("high", CombatConstants.ATTACK_PATH_HIGH)
	if str(fallback) != str(want_fallback):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: unknown guard should still fall back to ATTACK_PATHS[high]"
		)


static func _run_weapon_form_wait_weight_wall(failures: PackedStringArray) -> void:
	var wall_w: float = _WeaponForm.wait_action_weight_mult(_WeaponForm.FORM_WALL)
	var bal_w: float = _WeaponForm.wait_action_weight_mult(_WeaponForm.FORM_BALANCED)
	if wall_w <= bal_w:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: wall wait want > balanced (%.2f vs %.2f)" % [wall_w, bal_w]
		)


static func _run_weapon_form_wind_up_native_line(failures: PackedStringArray) -> void:
	var native: float = _WeaponForm.wind_up_transition_mult(
		_WeaponForm.FORM_OX, "thrust", "high_right", "high_right"
	)
	var cross: float = _WeaponForm.wind_up_transition_mult(
		_WeaponForm.FORM_OX, "thrust", "low", "high_right"
	)
	if native >= cross or native >= 1.0:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: ox native wind-up mult want < cross (native=%.2f cross=%.2f)" % [native, cross]
		)


static func _run_weapon_form_auto_switch_duel(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_WRATH, "test")
	c["stamina"] = CombatConstants.STAMINA_MAX * 0.05
	if not _WeaponForm.evaluate_automatic_form(mgr, c):
		CombatRegressionHarness._fail(failures, "weapon_form: auto_switch low stamina expected true")
	if _EntityAccess.form_str(c) != _WeaponForm.FORM_WALL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: auto_switch want wall got %s" % _EntityAccess.form_str(c)
		)
	if _WeaponForm.evaluate_automatic_form(mgr, c):
		CombatRegressionHarness._fail(
			failures, "weapon_form: auto_switch cooldown should block second switch"
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_duel_yomi(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	_WeaponForm.assign_form(mgr, def, _WeaponForm.FORM_OX, "harness")
	def["stamina"] = CombatConstants.STAMINA_MAX
	for _i in 5:
		_Attention.record_attack_toward_defender(null, atk_id, def, "head")
		_Attention.record_resolved_strike_toward_defender(def, atk_id, "oberhau")
	_WeaponForm.refresh_inferred_forms_for_observer(mgr, def)
	if not _WeaponForm.evaluate_automatic_form(mgr, def):
		CombatRegressionHarness._fail(failures, "weapon_form_auto_switch_duel_yomi: expected switch")
	if _EntityAccess.form_str(def) != _WeaponForm.FORM_FOOL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_auto_switch_duel_yomi: inferred wrath want fool got %s"
			% _EntityAccess.form_str(def)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_duel_yomi_ox_to_fool(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	_WeaponForm.assign_form(mgr, def, _WeaponForm.FORM_BALANCED, "harness")
	def["stamina"] = CombatConstants.STAMINA_MAX
	def[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(atk_id): _WeaponForm.FORM_OX}
	if not _WeaponForm.evaluate_automatic_form(mgr, def):
		CombatRegressionHarness._fail(failures, "weapon_form_auto_switch_duel_yomi_ox: expected switch")
	if _EntityAccess.form_str(def) != _WeaponForm.FORM_FOOL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_auto_switch_duel_yomi_ox: inferred ox want fool got %s"
			% _EntityAccess.form_str(def)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_surround(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr.recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	if _TacticalCombat.count_engaging_threats(mgr, def_id) < 2:
		CombatRegressionHarness._fail(failures, "weapon_form_auto_switch_surround: fixture want 2+ threats")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	_WeaponForm.assign_form(mgr, def, _WeaponForm.FORM_WRATH, "harness")
	def["stamina"] = CombatConstants.STAMINA_MAX
	if not _WeaponForm.evaluate_automatic_form(mgr, def):
		CombatRegressionHarness._fail(failures, "weapon_form_auto_switch_surround: expected switch")
	var got: String = _EntityAccess.form_str(def)
	if got != _WeaponForm.FORM_WALL and got != _WeaponForm.FORM_TEMPEST:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_auto_switch_surround: want wall/tempest got %s" % got
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_envelop_block(failures: PackedStringArray) -> void:
	var mgr: Node = _Tier1Tail._harness_7v3_mop_up_mgr()
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(
			failures, "weapon_form_auto_switch_envelop: setup want envelop_mop_up_active"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	if player.is_empty():
		CombatRegressionHarness._fail(failures, "weapon_form_auto_switch_envelop: missing player fixture")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	_WeaponForm.assign_form(mgr, player, _WeaponForm.FORM_WRATH, "harness")
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.05
	if _WeaponForm.evaluate_automatic_form(mgr, player):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_auto_switch_envelop: low stamina must not switch to wall during mop-up",
		)
	if _EntityAccess.form_str(player) != _WeaponForm.FORM_WRATH:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_auto_switch_envelop: form should stay wrath got %s"
			% _EntityAccess.form_str(player)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_preference_spawn(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var c: Dictionary = mgr.combatants[0]
	c["stance_preference"] = _WeaponForm.FORM_WALL
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if _EntityAccess.form_str(c) != _WeaponForm.FORM_WALL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: stance_preference want wall got %s (sword default is ox)" % _EntityAccess.form_str(c)
		)
	var home: String = _WeaponForm.home_guard_line(_WeaponForm.FORM_WALL)
	if str(c.get("guard_line", "")) != home:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: preference spawn guard_line want %s got %s" % [home, c.get("guard_line", "")]
		)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.combatants[0]["stance_preference"] = _WeaponForm.FORM_WALL
	mgr2.encounter[CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM] = _WeaponForm.FORM_FOOL
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c2: Dictionary = mgr2.combatants[0]
	if _EntityAccess.form_str(c2) != _WeaponForm.FORM_FOOL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form: encounter default should beat stance_preference (want fool got %s)"
			% _EntityAccess.form_str(c2)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr2)


static func _run_weapon_form_yomi_inference(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	_WeaponForm.assign_form(mgr, atk, _WeaponForm.FORM_WRATH, "harness")
	for _i in 5:
		_Attention.record_attack_toward_defender(null, atk_id, def, "head")
		_Attention.record_resolved_strike_toward_defender(def, atk_id, "oberhau")
	var wrath_inf: String = _WeaponForm.infer_opponent_form(mgr, def, atk_id)
	if wrath_inf != _WeaponForm.FORM_WRATH:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_yomi: repeated oberhau want wrath got %s" % wrath_inf
		)
	_WeaponForm.refresh_inferred_forms_for_observer(mgr, def)
	var cache: Dictionary = def.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, {}) as Dictionary
	if str(cache.get(str(atk_id), "")) != _WeaponForm.FORM_WRATH:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_yomi: cache want wrath got %s" % str(cache.get(str(atk_id), ""))
		)
	var def_feint: Dictionary = {}
	var feint_atk_id: int = 42
	for _j in 5:
		_Attention.record_feint_resolved_toward_defender(def_feint, feint_atk_id)
		_Attention.record_resolved_strike_toward_defender(def_feint, feint_atk_id, "oberhau_feint")
	var fool_inf: String = _WeaponForm.infer_opponent_form(null, def_feint, feint_atk_id)
	if fool_inf != _WeaponForm.FORM_FOOL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_yomi: feint habit want fool got %s" % fool_inf
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_counter_pick(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var eid: int = _EntityAccess.id_int(mgr.combatants[1])
	c[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(eid): _WeaponForm.FORM_OX}
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_FOOL, "harness")
	var cid: int = _EntityAccess.id_int(c)
	var act_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": eid}
	var act_thrust: Dictionary = {"move_id": "thrust", "target_id": eid}
	var act_cut: Dictionary = {"move_id": "oberhau", "target_id": eid}
	var w_feint: float = _AIPicker._get_action_weight(act_feint, cid, mgr, true, {}, {})
	var w_thrust: float = _AIPicker._get_action_weight(act_thrust, cid, mgr, true, {}, {})
	var w_cut: float = _AIPicker._get_action_weight(act_cut, cid, mgr, true, {}, {})
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_BALANCED, "harness")
	c[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(eid): _WeaponForm.FORM_OX}
	var w_feint_bal: float = _AIPicker._get_action_weight(act_feint, cid, mgr, true, {}, {})
	var w_thrust_bal: float = _AIPicker._get_action_weight(act_thrust, cid, mgr, true, {}, {})
	if w_feint <= w_feint_bal:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_counter: fool feint vs inferred ox want > balanced (%.3f vs %.3f)"
			% [w_feint, w_feint_bal]
		)
	if w_thrust <= w_thrust_bal:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_counter: fool thrust vs inferred ox want > balanced (%.3f vs %.3f)"
			% [w_thrust, w_thrust_bal]
		)
	var fool_feint_only: float = _WeaponForm.form_counter_mult(
		_WeaponForm.FORM_FOOL, _WeaponForm.FORM_OX, "oberhau_feint"
	)
	var fool_cut_only: float = _WeaponForm.form_counter_mult(
		_WeaponForm.FORM_FOOL, _WeaponForm.FORM_OX, "oberhau"
	)
	if fool_feint_only <= 1.0 or fool_cut_only > 1.0:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_counter: fool vs ox feint mult=%.3f cut mult=%.3f" % [fool_feint_only, fool_cut_only]
		)
	if w_cut >= w_thrust:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_counter: fool thrust should beat oberhau vs ox (%.3f vs %.3f)" % [w_thrust, w_cut]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_ui_suffix(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	c["state"] = CombatConstants.STATE_WAITING
	var gauge_suffix: String = _UiHints.weapon_form_gauge_suffix(c)
	if gauge_suffix != " . Form Ox":
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_ui: gauge suffix want ' . Form Ox' got '%s'" % gauge_suffix
		)
	var diagram_suffix: String = _UiHints.weapon_form_diagram_suffix(c)
	if diagram_suffix != " [Ox]":
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_ui: diagram suffix want ' [Ox]' got '%s'" % diagram_suffix
		)
	var tip: String = _UiHints.weapon_form_tooltip_line(c)
	if tip != "Form: Ox":
		CombatRegressionHarness._fail(
			failures, "weapon_form_ui: tooltip want 'Form: Ox' got '%s'" % tip
		)
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
	if not label.contains(" . Form Ox"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_ui: gauge label missing Form Ox suffix (got '%s')" % label
		)
	var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, mgr)
	var tip_hit: bool = false
	for line in tips:
		if str(line) == "Form: Ox":
			tip_hit = true
			break
	if not tip_hit:
		CombatRegressionHarness._fail(failures, "weapon_form_ui: gauge tooltip lines missing Form: Ox")
	var cell_label: String = _Diagram._cell_label_with_footwork("A1", [c])
	if not cell_label.contains(" [Ox]"):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_ui: diagram cell missing [Ox] (got '%s')" % cell_label
		)
	_WeaponForm.assign_form(mgr, c, _WeaponForm.FORM_WALL, "harness_ui")
	if _UiHints.weapon_form_gauge_suffix(c) != " . Form Wall":
		CombatRegressionHarness._fail(failures, "weapon_form_ui: wall gauge suffix after assign")
	var wall_tip: String = _UiHints.weapon_form_tooltip_line(c)
	if wall_tip != "Form: Wall (defensive)":
		CombatRegressionHarness._fail(
			failures, "weapon_form_ui: wall tooltip want defensive flavor got '%s'" % wall_tip
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-T2: soak-tuned tuning constants locked (duel / surround / counter cap).
static func _run_weapon_form_wf_t2_thresholds_locked(failures: PackedStringArray) -> void:
	if absf(CombatConstants.WF_FORM_COUNTER_MULT_CAP - 1.15) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_wf_t2: counter cap want 1.15 got %.4f"
			% CombatConstants.WF_FORM_COUNTER_MULT_CAP
		)
	if absf(CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD - 0.12) > 0.0001:
		CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: duel offense pad")
	if absf(CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD - 0.15) > 0.0001:
		CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: duel wrath promote pad")
	if absf(CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD - 0.10) > 0.0001:
		CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: duel wrath demote pad")


## WF-T2: identity-form **`mod`** bands (ox / plow / tempest)  -  stance alias wall/wrath/fool stay parity harness.
static func _run_weapon_form_wf_t2_mod_identity_bands(failures: PackedStringArray) -> void:
	var bands: Dictionary = {
		_WeaponForm.FORM_OX: {"parry": 1.08, "damage": 1.04, "ai_melee_focus": 1.02},
		_WeaponForm.FORM_PLOW: {"parry": 1.14, "damage": 0.96, "ai_melee_focus": 0.94},
		_WeaponForm.FORM_TEMPEST: {"parry": 0.84, "damage": 1.18, "ai_melee_focus": 1.08},
	}
	for form_id in bands.keys():
		var want: Dictionary = bands[form_id] as Dictionary
		for effect in want.keys():
			var got: float = _WeaponForm.mod(form_id, str(effect))
			var target: float = float(want[effect])
			if absf(got - target) > 0.001:
				CombatRegressionHarness._fail(
					failures,
					"weapon_form_wf_t2: %s/%s want %.3f got %.3f" % [form_id, effect, target, got]
				)


## WF-T2: counter mult respects cap; fool feint vs inferred ox boosted, cut not.
static func _run_weapon_form_wf_t2_counter_mult_cap(failures: PackedStringArray) -> void:
	var feint_m: float = _WeaponForm.form_counter_mult(
		_WeaponForm.FORM_FOOL, _WeaponForm.FORM_OX, "oberhau_feint"
	)
	var cut_m: float = _WeaponForm.form_counter_mult(
		_WeaponForm.FORM_FOOL, _WeaponForm.FORM_OX, "oberhau"
	)
	if feint_m <= 1.0 or feint_m > CombatConstants.WF_FORM_COUNTER_MULT_CAP + 0.001:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_wf_t2: fool feint counter want (1, %.3f] got %.3f"
			% [CombatConstants.WF_FORM_COUNTER_MULT_CAP, feint_m]
		)
	if cut_m > 1.0:
		CombatRegressionHarness._fail(
			failures, "weapon_form_wf_t2: fool cut vs ox should not counter got %.3f" % cut_m
		)


## WF-T2: recovering **wall** must not yo-yo to fool/wrath until stamina pad clears (F5 soak).
static func _run_weapon_form_wf_t2_duel_wall_recovery_gate(failures: PackedStringArray) -> void:
	var mgr_hold: Node = CombatRegressionHarness._harness_start_1v1()
	var def_hold: Dictionary = mgr_hold.combatants[0]
	var atk_hold: Dictionary = mgr_hold.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk_hold)
	_WeaponForm.assign_form(mgr_hold, def_hold, _WeaponForm.FORM_WALL, "harness")
	var min_r: float = _WeaponForm.min_stamina_ratio_for_form(_WeaponForm.FORM_WALL)
	var pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
	def_hold["stamina"] = CombatConstants.STAMINA_MAX * (min_r + pad * 0.5)
	for _i in 5:
		_Attention.record_attack_toward_defender(null, atk_id, def_hold, "head")
		_Attention.record_resolved_strike_toward_defender(def_hold, atk_id, "oberhau")
	_WeaponForm.refresh_inferred_forms_for_observer(mgr_hold, def_hold)
	if _WeaponForm.evaluate_automatic_form(mgr_hold, def_hold):
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_wf_t2: recovering wall should hold got %s"
			% _EntityAccess.form_str(def_hold)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_hold)
	var mgr_switch: Node = CombatRegressionHarness._harness_start_1v1()
	var def_sw: Dictionary = mgr_switch.combatants[0]
	var atk_sw: Dictionary = mgr_switch.combatants[1]
	var atk_sw_id: int = _EntityAccess.id_int(atk_sw)
	_WeaponForm.assign_form(mgr_switch, def_sw, _WeaponForm.FORM_WALL, "harness")
	def_sw["stamina"] = CombatConstants.STAMINA_MAX * (min_r + pad + 0.05)
	for _j in 5:
		_Attention.record_attack_toward_defender(null, atk_sw_id, def_sw, "head")
		_Attention.record_resolved_strike_toward_defender(def_sw, atk_sw_id, "oberhau")
	_WeaponForm.refresh_inferred_forms_for_observer(mgr_switch, def_sw)
	if not _WeaponForm.evaluate_automatic_form(mgr_switch, def_sw):
		CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: recovered wall should duel-switch vs wrath")
	if _EntityAccess.form_str(def_sw) != _WeaponForm.FORM_FOOL:
		CombatRegressionHarness._fail(
			failures,
			"weapon_form_wf_t2: recovered wall want fool vs wrath got %s"
			% _EntityAccess.form_str(def_sw)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_switch)


## WF-T2 suite: mod bands + counter cap + auto-switch thresholds  -  single Phase 0 maintain entry.
static func _run_weapon_form_wf_t2_suite(failures: PackedStringArray) -> void:
	_run_weapon_form_wf_t2_thresholds_locked(failures)
	_run_weapon_form_wf_t2_mod_identity_bands(failures)
	_run_weapon_form_wf_t2_counter_mult_cap(failures)
	_run_weapon_form_wf_t2_duel_wall_recovery_gate(failures)
