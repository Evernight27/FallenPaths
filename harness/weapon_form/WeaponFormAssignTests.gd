class_name WeaponFormAssignTests
extends CombatRegressionHarnessCore
const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Expand WF: weapon form spawn, mods, picker weights, pressure class, UI suffix parity.
## Footing rows: home guard on **`assign_form`** . gauge/diagram **` . Form`** / **`[Ox]`**  -  not PA step. LIVE_PATHS
## **`#harness-row-catalog-combatregressionharnessweaponformtailgd`** . soak open scope **`#wf-soak-audit-status`** .
## compose **`#battle-ui`**.


static func _run_weapon_form_spawn_default_guard(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    var c: Dictionary = mgr.combatants[0]
    if CombatantEntityAccess.form_str(c) != CombatWeaponForm.FORM_OX:
        _fail(failures, "weapon_form: spawn_default expected ox got %s" % CombatantEntityAccess.form_str(c))
    var home: String = CombatWeaponForm.home_guard_line(CombatWeaponForm.FORM_OX)
    if str(c.get("guard_line", "")) != home:
        _fail(failures, "weapon_form: spawn guard_line want %s got %s" % [home, c.get("guard_line", "")])
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_allowed_forms_clamp(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("DAGGER"), "player")
    var c: Dictionary = mgr.combatants[0]
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_WRATH, "test")
    if CombatantEntityAccess.form_str(c) != CombatWeaponForm.FORM_DAGGER_HIGH:
        _fail(failures, "weapon_form: dagger wrath alias want high_hut got %s" % CombatantEntityAccess.form_str(c))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_normalize_stance_alias(failures: PackedStringArray) -> void:
    if CombatWeaponForm.normalize_form("defensive") != CombatWeaponForm.FORM_WALL:
        _fail(failures, "weapon_form: defensive alias")
    if CombatWeaponForm.normalize_form("aggressive") != CombatWeaponForm.FORM_WRATH:
        _fail(failures, "weapon_form: aggressive alias")
    if CombatWeaponForm.normalize_form("controlling") != CombatWeaponForm.FORM_FOOL:
        _fail(failures, "weapon_form: controlling alias")


static func _run_weapon_form_mod_parity_stance_alias(failures: PackedStringArray) -> void:
    for effect in [
        "parry", "evasion", "damage", "close_attempt", "ai_melee_focus", "feint_readthrough", "ai_feint_listing"
    ]:
        var old_defensive: float = CombatConstants.get_stance_modifier(CombatConstants.STANCE_DEFENSIVE, effect)
        var wall: float = CombatWeaponForm.mod(CombatWeaponForm.FORM_WALL, effect)
        if absf(old_defensive - wall) > 0.001:
            _fail(failures, "weapon_form: wall/%s parity want %.3f got %.3f" % [effect, old_defensive, wall])


static func _run_weapon_form_move_weight_distribution(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SPEAR"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_PLOW, "test")
    var cid: int = CombatantEntityAccess.id_int(c)
    var act_stab: Dictionary = {"move_id": "spear_thrust", "target_id": CombatantEntityAccess.id_int(mgr.combatants[1])}
    var act_slash: Dictionary = {"move_id": "spear_slash", "target_id": CombatantEntityAccess.id_int(mgr.combatants[1])}
    var w_stab: float = CombatAIActionPicker._get_action_weight(act_stab, cid, mgr, true, {}, {})
    var w_slash: float = CombatAIActionPicker._get_action_weight(act_slash, cid, mgr, true, {}, {})
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_BALANCED, "test")
    var w_stab_bal: float = CombatAIActionPicker._get_action_weight(act_stab, cid, mgr, true, {}, {})
    if w_stab <= w_stab_bal:
        _fail(failures, "weapon_form: plow stab weight want > balanced (%.3f vs %.3f)" % [w_stab, w_stab_bal])
    if w_stab <= w_slash:
        _fail(failures, "weapon_form: plow stab want > slash (%.3f vs %.3f)" % [w_stab, w_slash])
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_axe_chop_weight_bias(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("AXE"), "player")
    mgr.register(_new_entity("AXE"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var weapon: Variant = CombatantEntityAccess.get_weapon(c)
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_AXE_DEMI, "test")
    var cid: int = CombatantEntityAccess.id_int(c)
    var tid: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var act_chop: Dictionary = {"move_id": "overhead_chop", "target_id": tid}
    var act_thrust: Dictionary = {"move_id": "spike_thrust", "target_id": tid}
    var w_chop: float = CombatAIActionPicker._get_action_weight(act_chop, cid, mgr, true, {}, {})
    var w_thrust: float = CombatAIActionPicker._get_action_weight(act_thrust, cid, mgr, true, {}, {})
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_BALANCED, "test")
    var w_chop_bal: float = CombatAIActionPicker._get_action_weight(act_chop, cid, mgr, true, {}, {})
    if w_chop <= w_chop_bal:
        _fail(failures, "weapon_form: demi_hache chop want > balanced (%.3f vs %.3f)" % [w_chop, w_chop_bal])
    if w_chop <= w_thrust:
        _fail(failures, "weapon_form: demi_hache chop want > spike_thrust (%.3f vs %.3f)" % [w_chop, w_thrust])
    var bec_chop: float = CombatWeaponForm.action_weight_mult(CombatWeaponForm.FORM_AXE_BEC, "overhead_chop", weapon)
    var demi_chop: float = CombatWeaponForm.action_weight_mult(CombatWeaponForm.FORM_AXE_DEMI, "overhead_chop", weapon)
    if demi_chop <= bec_chop:
        _fail(
            failures,
            "weapon_form: demi_hache overhead_chop mult want > bec_point (%.3f vs %.3f)" % [demi_chop, bec_chop]
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_pressure_class_zoc(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_WRATH, "test")
            c["stamina"] = CombatConstants.STAMINA_MAX
    var mod: float = ZoneOfControl.get_opponent_pressure_duration_multiplier(mgr, "player")
    if mod != CombatConstants.PRESSURE_MOD_AGGRESSIVE:
        _fail(
            failures, "weapon_form: zoc aggressive want %.2f got %.2f" % [CombatConstants.PRESSURE_MOD_AGGRESSIVE, mod]
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_close_controlling_evasion(failures: PackedStringArray) -> void:
    var old_controlling_close: float = CombatConstants.STANCE_MOD_OPPONENT_CLOSE
    var fool_div: float = CombatWeaponForm.opponent_close_evasion_divisor(CombatWeaponForm.FORM_FOOL)
    if absf(old_controlling_close - fool_div) > 0.001:
        _fail(failures, "weapon_form: fool close divisor want %.2f got %.2f" % [old_controlling_close, fool_div])
    var close_list: float = CombatWeaponForm.opponent_close_listing_weight_mult(CombatWeaponForm.FORM_FOOL)
    if absf(close_list - old_controlling_close) > 0.001:
        _fail(failures, "weapon_form: fool close listing mult want %.2f got %.2f" % [old_controlling_close, close_list])


static func _run_weapon_form_controlling_disengage_pressure(failures: PackedStringArray) -> void:
    var old_controlling_disengage: float = 1.0 / CombatConstants.STANCE_MOD_OPPONENT_DISENGAGE
    var fool_mult: float = CombatWeaponForm.opponent_disengage_pressure_mult(CombatWeaponForm.FORM_FOOL)
    if absf(old_controlling_disengage - fool_mult) > 0.001:
        _fail(failures, "weapon_form: fool disengage mult want %.4f got %.4f" % [old_controlling_disengage, fool_mult])
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_FOOL, "test")
            c["stamina"] = CombatConstants.STAMINA_MAX
            c["state"] = CombatConstants.STATE_WAITING
    var mod_neutral: float = ZoneOfControl.get_opponent_pressure_duration_multiplier(mgr, "player")
    var want: float = CombatConstants.PRESSURE_MOD_NEUTRAL * old_controlling_disengage
    if absf(mod_neutral - want) > 0.001:
        _fail(failures, "weapon_form: fool disengage pressure want %.4f got %.4f" % [want, mod_neutral])
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_disengage_listing_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_FOOL, "test")
            c["stamina"] = CombatConstants.STAMINA_MAX
            c["state"] = CombatConstants.STATE_WAITING
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_FALL_BACK, "target_id": CombatantEntityAccess.id_int(player)},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": CombatantEntityAccess.id_int(player)},
    ]
    var fb_w: float = CombatAIActionPicker._get_action_weight(acts[0], CombatantEntityAccess.id_int(player), mgr)
    var mgr_clear: Node = CombatManager.new()
    mgr_clear.register(_new_entity("SWORD"), "player")
    mgr_clear.register(_new_entity("SWORD"), "enemy")
    mgr_clear.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player_clear: Dictionary = mgr_clear.combatants[0]
    for c in mgr_clear.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            CombatWeaponForm.assign_form(mgr_clear, c as Dictionary, CombatWeaponForm.FORM_BALANCED, "test")
            c["stamina"] = CombatConstants.STAMINA_MAX
            c["state"] = CombatConstants.STATE_WAITING
    var fb_w_clear: float = CombatAIActionPicker._get_action_weight(
        acts[0], CombatantEntityAccess.id_int(player_clear), mgr_clear
    )
    HarnessFixtures._free_manager_restore_global_rng(mgr)
    HarnessFixtures._free_manager_restore_global_rng(mgr_clear)
    if fb_w_clear <= 0.0 or fb_w >= fb_w_clear:
        _fail(
            failures,
            "weapon_form: fool front should lower fall_back weight got fool=%.4f clear=%.4f" % [fb_w, fb_w_clear]
        )


static func _run_weapon_form_controlling_close_listing_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 6)
    var enemy: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "enemy", 0, 2)
    if player.is_empty() or enemy.is_empty():
        _fail(failures, "weapon_form: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    player["gauge"] = 100.0
    enemy["gauge"] = 100.0
    CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = (CombatConstants.DISTANCE_LONG)
    if CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(player), CombatPairGeometry.effective_pair_eff_dist(mgr, player, enemy)
    ):
        _fail(failures, "weapon_form: wing setup want out-of-reach LONG for close vs Fool")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "test")
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    var close_fool: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
        "target_id": e_id,
    }
    var mgr_bal: Node = CombatManager.new()
    for _i in 7:
        mgr_bal.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr_bal.register(_new_entity("SWORD"), "enemy")
    mgr_bal.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr_bal.recompute_zoc_and_distance()
    var player_bal: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr_bal, "player", 0, 6)
    var enemy_bal: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr_bal, "enemy", 0, 2)
    if player_bal.is_empty() or enemy_bal.is_empty():
        _fail(failures, "weapon_form: missing balanced wing fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        HarnessFixtures._free_manager_restore_global_rng(mgr_bal)
        return
    var p_id_bal: int = CombatantEntityAccess.id_int(player_bal)
    var e_id_bal: int = CombatantEntityAccess.id_int(enemy_bal)
    player_bal["gauge"] = 100.0
    enemy_bal["gauge"] = 100.0
    CombatantEntityAccess.nested_dictionary_for_mutation(player_bal, "distance_to")[e_id_bal] = (
        CombatConstants.DISTANCE_LONG
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy_bal, "distance_to")[p_id_bal] = (
        CombatConstants.DISTANCE_LONG
    )
    CombatWeaponForm.assign_form(mgr_bal, enemy_bal, CombatWeaponForm.FORM_BALANCED, "test")
    enemy_bal["stamina"] = CombatConstants.STAMINA_MAX
    var w_fool: float = CombatAIActionPicker._get_action_weight(close_fool, p_id, mgr, true)
    var close_bal: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
        "target_id": e_id_bal,
    }
    var w_bal: float = CombatAIActionPicker._get_action_weight(close_bal, p_id_bal, mgr_bal, true)
    HarnessFixtures._free_manager_restore_global_rng(mgr)
    HarnessFixtures._free_manager_restore_global_rng(mgr_bal)
    if w_bal <= 0.001 or w_fool >= w_bal:
        _fail(failures, "weapon_form: fool defender should lower close weight got fool=%.4f bal=%.4f" % [w_fool, w_bal])


static func _run_weapon_form_controlling_close_turn_hint(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "test")
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
    ]
    var hint: String = CombatUiHints.controlling_defender_close_hint_line(mgr, player, acts)
    if hint.is_empty() or not hint.to_lower().contains("fool"):
        _fail(failures, "weapon_form: controlling close hint want Fool copy got '%s'" % hint)
    player["state"] = CombatConstants.STATE_WAITING
    player["gauge"] = 100.0
    CombatPlayerTurnHints.sync_controlling_close_turn_hint_on_combatant(mgr, player, acts)
    var gauge_tips: String = "\n".join(CombatUiHints.gauge_tooltip_lines(player, mgr))
    if not gauge_tips.contains("Fool") or not gauge_tips.to_lower().contains("controlling"):
        _fail(failures, "weapon_form: controlling close gauge tip want Fool/controlling got '%s'" % gauge_tips)
    var acts_bal: Array = [{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id}]
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_BALANCED, "test")
    var hint_bal: String = CombatUiHints.controlling_defender_close_hint_line(mgr, player, acts_bal)
    if not hint_bal.is_empty():
        _fail(failures, "weapon_form: balanced defender should not emit controlling close hint got '%s'" % hint_bal)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_close_list_stamp(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
        player["distance_to"] = {}
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    (player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    (enemy["distance_to"] as Dictionary)[CombatantEntityAccess.id_int(player)] = CombatConstants.DISTANCE_LONG
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "test")
    var acts: Array = []
    CombatMeleeListing._append_attempt_close_action(acts, enemy)
    if acts.is_empty():
        _fail(failures, "weapon_form: close list stamp want one action")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var tag: String = str(acts[0].get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")).strip_edges()
    if not tag.to_lower().contains("fool") or not tag.contains("controlling"):
        _fail(failures, "weapon_form: close list stamp want Fool (controlling) got '%s'" % tag)
    var menu: String = CombatFormationMoveDuration.formation_listed_moves_menu_line(acts)
    if not menu.contains("Fool"):
        _fail(failures, "weapon_form: close menu line want Fool tag got '%s'" % menu)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_close_listed_turn_detail(failures: PackedStringArray) -> void:
    var acts: Array = [
        {
            "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
            "target_id": 1,
            CombatConstants.ACTION_KEY_CLOSE_LIST_HINT: "Fool (controlling)",
        },
    ]
    var detail: String = CombatFormationMoveDuration.formation_listed_moves_turn_hint(acts)
    if not detail.to_lower().contains("fool") or not detail.contains("harder"):
        _fail(failures, "weapon_form: close turn detail want Fool/harder got '%s'" % detail)


static func _run_weapon_form_close_failed_log_controlling_note(failures: PackedStringArray) -> void:
    var result: Dictionary = {
        "outcome": "close_failed",
        "reason": "contest_failed",
        "close_contest_note": "Fool (controlling)",
    }
    var line: String = CombatLogFormatter.format_action_line("Alice", "player", "Bob", "enemy", result)
    if not line.contains("Fool") or not line.contains("held their measure"):
        _fail(failures, "weapon_form: close_failed log want Fool measure copy got '%s'" % line)
    var plain: Dictionary = {
        "outcome": "close_failed",
        "reason": "contest_failed",
    }
    var line_plain: String = CombatLogFormatter.format_action_line("Alice", "player", "Bob", "enemy", plain)
    if line_plain.contains("Fool"):
        _fail(failures, "weapon_form: close_failed log without note should omit form got '%s'" % line_plain)


static func _run_weapon_form_close_resolve_contest_note(failures: PackedStringArray) -> void:
    var fixtures: Array = HarnessFixtures._harness_7v3_wing_rank0_fixtures()
    var mgr: Node = fixtures[0] as Node
    var p: Dictionary = fixtures[1] as Dictionary
    var en: Dictionary = fixtures[2] as Dictionary
    if p.is_empty() or en.is_empty():
        _fail(failures, "weapon_form: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(en)
    HarnessFixtures._harness_bind_pair_long_band(p, en)
    CombatWeaponForm.assign_form(mgr, en, CombatWeaponForm.FORM_FOOL, "test")
    en["stamina"] = CombatConstants.STAMINA_MAX
    var sd: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(p)
    sd["strength"] = 0.0
    var cap: Array = []
    mgr.action_resolved.connect(
        func(_aid: int, _tid: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if cap.is_empty():
        _fail(failures, "weapon_form: close resolve want payload")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var r: Dictionary = cap[0] as Dictionary
    var note: String = str(r.get("close_contest_note", "")).strip_edges()
    if str(r.get("outcome", "")) != "close_failed" or note.is_empty() or not note.to_lower().contains("fool"):
        _fail(failures, "weapon_form: close resolve want Fool contest note got %s" % str(r))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_controlling_pressure_stamina_gate(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
        player["distance_to"] = {}
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    (player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    (enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "test")
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    enemy["state"] = CombatConstants.STATE_WAITING
    if not CombatWeaponForm.controlling_pressure_active(enemy):
        _fail(failures, "weapon_form: fresh fool should have controlling pressure")
    var fresh_tip: String = CombatUiHints.weapon_form_tooltip_line(enemy)
    if not fresh_tip.to_lower().contains("controlling"):
        _fail(failures, "weapon_form: fresh fool tooltip want controlling got '%s'" % fresh_tip)
    if ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(mgr, "player") <= 1.01:
        _fail(failures, "weapon_form: fresh fool front should pin disengage")
    enemy["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    if CombatWeaponForm.controlling_pressure_active(enemy):
        _fail(failures, "weapon_form: exhausted fool should not have controlling pressure")
    var exhaust_tip: String = CombatUiHints.weapon_form_tooltip_line(enemy)
    if exhaust_tip.to_lower().contains("controlling"):
        _fail(failures, "weapon_form: exhausted fool tooltip should omit controlling got '%s'" % exhaust_tip)
    if ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(mgr, "player") > 1.01:
        _fail(failures, "weapon_form: exhausted fool front should not pin disengage")
    var acts: Array = [{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id}]
    var hint: String = CombatUiHints.controlling_defender_close_hint_line(mgr, player, acts)
    if not hint.is_empty():
        _fail(failures, "weapon_form: exhausted fool should not emit close hint got '%s'" % hint)
    var close_act: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
        "target_id": e_id,
    }
    var w_exhaust: float = CombatAIActionPicker._get_action_weight(close_act, p_id, mgr, true)
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_BALANCED, "test")
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    var w_bal: float = CombatAIActionPicker._get_action_weight(close_act, p_id, mgr, true)
    if absf(w_exhaust - w_bal) > 0.0001:
        _fail(
            failures,
            "weapon_form: exhausted fool close weight should match balanced got ex=%.4f bal=%.4f" % [w_exhaust, w_bal]
        )
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "test")
    enemy["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    HarnessFixtures._free_manager_restore_global_rng(mgr)
    var wing_fix: Array = HarnessFixtures._harness_7v3_wing_rank0_fixtures()
    var wing_mgr: Node = wing_fix[0] as Node
    var wing_player: Dictionary = wing_fix[1] as Dictionary
    var wing_enemy: Dictionary = wing_fix[2] as Dictionary
    if wing_player.is_empty() or wing_enemy.is_empty():
        _fail(failures, "weapon_form: exhausted fool resolve missing wing fixtures")
        HarnessFixtures._free_manager_restore_global_rng(wing_mgr)
        return
    var wing_p_id: int = CombatantEntityAccess.id_int(wing_player)
    var wing_e_id: int = CombatantEntityAccess.id_int(wing_enemy)
    HarnessFixtures._harness_bind_pair_long_band(wing_player, wing_enemy)
    CombatWeaponForm.assign_form(wing_mgr, wing_enemy, CombatWeaponForm.FORM_FOOL, "test")
    wing_enemy["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    var cap: Array = []
    wing_mgr.action_resolved.connect(
        func(_aid: int, _tid: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    var sd_wing: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(wing_player)
    sd_wing["strength"] = 0.0
    CombatEngagementResolver.resolve_close_attempt(wing_mgr, wing_p_id, wing_e_id)
    if cap.is_empty():
        _fail(failures, "weapon_form: exhausted fool close resolve want payload")
    elif not str((cap[0] as Dictionary).get("close_contest_note", "")).strip_edges().is_empty():
        _fail(failures, "weapon_form: exhausted fool close resolve should omit contest note got %s" % str(cap[0]))
    HarnessFixtures._free_manager_restore_global_rng(wing_mgr)


static func _run_weapon_form_turn_ready_listing_close_controlling(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 6)
    var enemy: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "enemy", 0, 2)
    if player.is_empty() or enemy.is_empty():
        _fail(failures, "weapon_form: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    player["gauge"] = 100.0
    player["state"] = CombatConstants.STATE_WAITING
    CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = (CombatConstants.DISTANCE_LONG)
    if CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(player), CombatPairGeometry.effective_pair_eff_dist(mgr, player, enemy)
    ):
        _fail(failures, "weapon_form: wing setup want out-of-reach LONG for close vs Fool")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "test")
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    var acts: Array = []
    CombatMeleeListing._append_attempt_close_action(acts, enemy)
    if acts.is_empty():
        _fail(failures, "weapon_form: turn_ready listing want attempt_close")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var tag: String = str(acts[0].get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")).strip_edges()
    if not tag.to_lower().contains("fool"):
        _fail(failures, "weapon_form: listed close want Fool stamp got '%s'" % tag)
    var fp_line: String = CombatFormationMoveDuration.formation_listed_moves_turn_hint(acts)
    if not fp_line.to_lower().contains("fool") or not fp_line.contains("harder"):
        _fail(failures, "weapon_form: turn_ready FP line want Fool/harder got '%s'" % fp_line)
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
            _fail(failures, "weapon_form: menu close want Fool stamp got '%s'" % menu_tag)
    if not listed_close_vs_fool:
        _fail(failures, "weapon_form: get_available_actions want attempt_close vs Fool target")
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_harness_assign_form_home_guard(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    var c: Dictionary = mgr.combatants[0]
    harness_assign_form(mgr, c, CombatWeaponForm.FORM_WRATH)
    if CombatantEntityAccess.form_str(c) != CombatWeaponForm.FORM_WRATH:
        _fail(failures, "weapon_form: harness_assign_form want wrath got %s" % CombatantEntityAccess.form_str(c))
    var home: String = CombatWeaponForm.home_guard_line(CombatWeaponForm.FORM_WRATH)
    if str(c.get("guard_line", "")) != home:
        _fail(
            failures,
            "weapon_form: harness_assign_form home guard want %s got %s" % [home, str(c.get("guard_line", ""))]
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_octant_attack_path_cardinal_lookup(failures: PackedStringArray) -> void:
    var path_oct: Array = CombatConstants.get_attack_path("high_left", "low")
    var path_card: Array = CombatConstants.get_attack_path("high", "low")
    if str(path_oct) != str(path_card):
        _fail(
            failures,
            (
                "weapon_form: octant attack path high_left/low want cardinal parity got oct=%s card=%s"
                % [str(path_oct), str(path_card)]
            )
        )
    var path_wrath_home: Array = CombatConstants.get_attack_path("high", "high_left")
    var path_left_guard: Array = CombatConstants.get_attack_path("high", "left")
    var path_high_guard: Array = CombatConstants.get_attack_path("high", "high")
    if CombatConstants.is_feature_iv6_attack_path_octant_enabled():
        if str(path_wrath_home) == str(path_left_guard):
            _fail(
                failures,
                "weapon_form: IV-6 high_left guard path must differ from left flank got %s" % str(path_wrath_home)
            )
        if str(path_wrath_home) == str(path_high_guard):
            _fail(
                failures,
                "weapon_form: IV-6 high_left guard path must differ from high guard got %s" % str(path_wrath_home)
            )
        if str(path_wrath_home[0]) != CombatConstants.guard_zone_for_guard_line("high_left"):
            _fail(
                failures,
                (
                    "weapon_form: IV-6 high_left guard path must lead with zone %s got %s"
                    % [CombatConstants.guard_zone_for_guard_line("high_left"), str(path_wrath_home[0])]
                )
            )
    elif str(path_wrath_home) != str(path_left_guard):
        _fail(
            failures,
            (
                "weapon_form: IV-4 high_left guard want left-side path got %s vs %s"
                % [str(path_wrath_home), str(path_left_guard)]
            )
        )
    var fallback: Array = CombatConstants.get_attack_path("high", "__no_such_guard__")
    var want_fallback: Array = CombatConstants.ATTACK_PATHS.get("high", CombatConstants.ATTACK_PATH_HIGH)
    if str(fallback) != str(want_fallback):
        _fail(failures, "weapon_form: unknown guard should still fall back to ATTACK_PATHS[high]")


static func _run_weapon_form_wait_weight_wall(failures: PackedStringArray) -> void:
    var wall_w: float = CombatWeaponForm.wait_action_weight_mult(CombatWeaponForm.FORM_WALL)
    var bal_w: float = CombatWeaponForm.wait_action_weight_mult(CombatWeaponForm.FORM_BALANCED)
    if wall_w <= bal_w:
        _fail(failures, "weapon_form: wall wait want > balanced (%.2f vs %.2f)" % [wall_w, bal_w])


static func _run_weapon_form_wind_up_native_line(failures: PackedStringArray) -> void:
    var native: float = CombatWeaponForm.wind_up_transition_mult(
        CombatWeaponForm.FORM_OX, "thrust", "high_right", "high_right"
    )
    var cross: float = CombatWeaponForm.wind_up_transition_mult(CombatWeaponForm.FORM_OX, "thrust", "low", "high_right")
    if native >= cross or native >= 1.0:
        _fail(failures, "weapon_form: ox native wind-up mult want < cross (native=%.2f cross=%.2f)" % [native, cross])


static func _run_weapon_form_auto_switch_duel(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_WRATH, "test")
    c["stamina"] = CombatConstants.STAMINA_MAX * 0.05
    if not CombatWeaponForm.evaluate_automatic_form(mgr, c):
        _fail(failures, "weapon_form: auto_switch low stamina expected true")
    if CombatantEntityAccess.form_str(c) != CombatWeaponForm.FORM_WALL:
        _fail(failures, "weapon_form: auto_switch want wall got %s" % CombatantEntityAccess.form_str(c))
    if CombatWeaponForm.evaluate_automatic_form(mgr, c):
        _fail(failures, "weapon_form: auto_switch cooldown should block second switch")
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_duel_yomi(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    CombatWeaponForm.assign_form(mgr, def, CombatWeaponForm.FORM_OX, "harness")
    def["stamina"] = CombatConstants.STAMINA_MAX
    for _i in 5:
        CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
        CombatAttention.record_resolved_strike_toward_defender(def, atk_id, "oberhau")
    CombatWeaponForm.refresh_inferred_forms_for_observer(mgr, def)
    if not CombatWeaponForm.evaluate_automatic_form(mgr, def):
        _fail(failures, "weapon_form_auto_switch_duel_yomi: expected switch")
    if CombatantEntityAccess.form_str(def) != CombatWeaponForm.FORM_FOOL:
        _fail(
            failures,
            "weapon_form_auto_switch_duel_yomi: inferred wrath want fool got %s" % CombatantEntityAccess.form_str(def)
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_duel_yomi_ox_to_fool(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    CombatWeaponForm.assign_form(mgr, def, CombatWeaponForm.FORM_BALANCED, "harness")
    def["stamina"] = CombatConstants.STAMINA_MAX
    def[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(atk_id): CombatWeaponForm.FORM_OX}
    if not CombatWeaponForm.evaluate_automatic_form(mgr, def):
        _fail(failures, "weapon_form_auto_switch_duel_yomi_ox: expected switch")
    if CombatantEntityAccess.form_str(def) != CombatWeaponForm.FORM_FOOL:
        _fail(
            failures,
            "weapon_form_auto_switch_duel_yomi_ox: inferred ox want fool got %s" % CombatantEntityAccess.form_str(def)
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_surround(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.combatants[0]["file"] = 1
    mgr.combatants[1]["file"] = 0
    mgr.combatants[2]["file"] = 2
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var def: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(def)
    if TacticalCombat.count_engaging_threats(mgr, def_id) < 2:
        _fail(failures, "weapon_form_auto_switch_surround: fixture want 2+ threats")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    CombatWeaponForm.assign_form(mgr, def, CombatWeaponForm.FORM_WRATH, "harness")
    def["stamina"] = CombatConstants.STAMINA_MAX
    if not CombatWeaponForm.evaluate_automatic_form(mgr, def):
        _fail(failures, "weapon_form_auto_switch_surround: expected switch")
    var got: String = CombatantEntityAccess.form_str(def)
    if got != CombatWeaponForm.FORM_WALL and got != CombatWeaponForm.FORM_TEMPEST:
        _fail(failures, "weapon_form_auto_switch_surround: want wall/tempest got %s" % got)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_auto_switch_envelop_block(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarnessTier1Tail._harness_7v3_mop_up_mgr()
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _fail(failures, "weapon_form_auto_switch_envelop: setup want envelop_mop_up_active")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if player.is_empty():
        _fail(failures, "weapon_form_auto_switch_envelop: missing player fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    CombatWeaponForm.assign_form(mgr, player, CombatWeaponForm.FORM_WRATH, "harness")
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.05
    if CombatWeaponForm.evaluate_automatic_form(mgr, player):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                "weapon_form_auto_switch_envelop: low stamina must not switch to wall during mop-up",
            )
        )
    if CombatantEntityAccess.form_str(player) != CombatWeaponForm.FORM_WRATH:
        _fail(
            failures,
            "weapon_form_auto_switch_envelop: form should stay wrath got %s" % CombatantEntityAccess.form_str(player)
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_preference_spawn(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    var c: Dictionary = mgr.combatants[0]
    c["stance_preference"] = CombatWeaponForm.FORM_WALL
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if CombatantEntityAccess.form_str(c) != CombatWeaponForm.FORM_WALL:
        _fail(
            failures,
            "weapon_form: stance_preference want wall got %s (sword default is ox)" % CombatantEntityAccess.form_str(c)
        )
    var home: String = CombatWeaponForm.home_guard_line(CombatWeaponForm.FORM_WALL)
    if str(c.get("guard_line", "")) != home:
        _fail(failures, "weapon_form: preference spawn guard_line want %s got %s" % [home, c.get("guard_line", "")])
    var mgr2: Node = CombatManager.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.combatants[0]["stance_preference"] = CombatWeaponForm.FORM_WALL
    mgr2.encounter[CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM] = CombatWeaponForm.FORM_FOOL
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c2: Dictionary = mgr2.combatants[0]
    if CombatantEntityAccess.form_str(c2) != CombatWeaponForm.FORM_FOOL:
        _fail(
            failures,
            (
                "weapon_form: encounter default should beat stance_preference (want fool got %s)"
                % CombatantEntityAccess.form_str(c2)
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)
    HarnessFixtures._free_manager_restore_global_rng(mgr2)


static func _run_weapon_form_yomi_inference(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    CombatWeaponForm.assign_form(mgr, atk, CombatWeaponForm.FORM_WRATH, "harness")
    for _i in 5:
        CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
        CombatAttention.record_resolved_strike_toward_defender(def, atk_id, "oberhau")
    var wrath_inf: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if wrath_inf != CombatWeaponForm.FORM_WRATH:
        _fail(failures, "weapon_form_yomi: repeated oberhau want wrath got %s" % wrath_inf)
    CombatWeaponForm.refresh_inferred_forms_for_observer(mgr, def)
    var cache: Dictionary = def.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, {}) as Dictionary
    if str(cache.get(str(atk_id), "")) != CombatWeaponForm.FORM_WRATH:
        _fail(failures, "weapon_form_yomi: cache want wrath got %s" % str(cache.get(str(atk_id), "")))
    var def_feint: Dictionary = {}
    var feint_atk_id: int = 42
    for _j in 5:
        CombatAttention.record_feint_resolved_toward_defender(def_feint, feint_atk_id)
        CombatAttention.record_resolved_strike_toward_defender(def_feint, feint_atk_id, "oberhau_feint")
    var fool_inf: String = CombatWeaponForm.infer_opponent_form(null, def_feint, feint_atk_id)
    if fool_inf != CombatWeaponForm.FORM_FOOL:
        _fail(failures, "weapon_form_yomi: feint habit want fool got %s" % fool_inf)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_weapon_form_counter_pick(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var eid: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    c[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(eid): CombatWeaponForm.FORM_OX}
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_FOOL, "harness")
    var cid: int = CombatantEntityAccess.id_int(c)
    var act_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": eid}
    var act_thrust: Dictionary = {"move_id": "thrust", "target_id": eid}
    var act_cut: Dictionary = {"move_id": "oberhau", "target_id": eid}
    var w_feint: float = CombatAIActionPicker._get_action_weight(act_feint, cid, mgr, true, {}, {})
    var w_thrust: float = CombatAIActionPicker._get_action_weight(act_thrust, cid, mgr, true, {}, {})
    var w_cut: float = CombatAIActionPicker._get_action_weight(act_cut, cid, mgr, true, {}, {})
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_BALANCED, "harness")
    c[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = {str(eid): CombatWeaponForm.FORM_OX}
    var w_feint_bal: float = CombatAIActionPicker._get_action_weight(act_feint, cid, mgr, true, {}, {})
    var w_thrust_bal: float = CombatAIActionPicker._get_action_weight(act_thrust, cid, mgr, true, {}, {})
    if w_feint <= w_feint_bal:
        _fail(
            failures,
            "weapon_form_counter: fool feint vs inferred ox want > balanced (%.3f vs %.3f)" % [w_feint, w_feint_bal]
        )
    if w_thrust <= w_thrust_bal:
        _fail(
            failures,
            "weapon_form_counter: fool thrust vs inferred ox want > balanced (%.3f vs %.3f)" % [w_thrust, w_thrust_bal]
        )
    var fool_feint_only: float = CombatWeaponForm.form_counter_mult(
        CombatWeaponForm.FORM_FOOL, CombatWeaponForm.FORM_OX, "oberhau_feint"
    )
    var fool_cut_only: float = CombatWeaponForm.form_counter_mult(
        CombatWeaponForm.FORM_FOOL, CombatWeaponForm.FORM_OX, "oberhau"
    )
    if fool_feint_only <= 1.0 or fool_cut_only > 1.0:
        _fail(
            failures, "weapon_form_counter: fool vs ox feint mult=%.3f cut mult=%.3f" % [fool_feint_only, fool_cut_only]
        )
    if w_cut >= w_thrust:
        _fail(failures, "weapon_form_counter: fool thrust should beat oberhau vs ox (%.3f vs %.3f)" % [w_thrust, w_cut])
    HarnessFixtures._free_manager_restore_global_rng(mgr)
