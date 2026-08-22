class_name Tier1SwapRankEngagementTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map``.


static func _run_engagement_reach_audit_close_bind_and_wing_gap(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    if p_wing.is_empty() or e_wing.is_empty():
        _fail(failures, "reach_audit: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    var e_id: int = CombatantEntityAccess.id_int(e_wing)
    var melee: float = CombatMeleeListing.melee_weapon_reach(p_wing)
    var eff_long: float = CombatPairGeometry.effective_pair_eff_dist(wide, p_wing, e_wing)
    if eff_long <= melee:
        _fail(
            failures,
            "reach_audit: wing at LONG want eff_dist > sword reach got eff=%.3f reach=%.3f" % [eff_long, melee]
        )
        HarnessFixtures._free_manager(wide)
        return
    CombatantEntityAccess.nested_dictionary_for_mutation(p_wing, "distance_to")[e_id] = (CombatConstants.DISTANCE_CLOSE)
    var p_wing_id: int = CombatantEntityAccess.id_int(p_wing)
    CombatantEntityAccess.nested_dictionary_for_mutation(e_wing, "distance_to")[p_wing_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var eff_bind: float = CombatPairGeometry.effective_pair_eff_dist(wide, p_wing, e_wing)
    if eff_bind > melee:
        _fail(
            failures, "reach_audit: CLOSE bind want eff_dist <= reach got eff=%.3f reach=%.3f" % [eff_bind, melee]
        )
        HarnessFixtures._free_manager(wide)
        return
    if not CombatMeleeListing.can_melee_threaten(wide, p_wing, e_wing):
        _fail(failures, "reach_audit: CLOSE bind want can_melee_threaten")
    wide.recompute_zoc_and_distance()
    var band_after: String = CombatantEntityAccess.distance_to_opponent_band(p_wing, e_id, "")
    if band_after != CombatConstants.DISTANCE_CLOSE:
        _fail(failures, "reach_audit: want sticky CLOSE after recompute got %s" % band_after)
    HarnessFixtures._free_manager(wide)


## Listing: geometric reach at LONG band (lag) lists strikes, not attempt_close.


## Listing: geometric reach at LONG band (lag) lists strikes, not attempt_close.
static func _run_listing_strikes_when_in_swing_at_long_band(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_inner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 1)
    var e_left: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 0)
    if p_inner.is_empty() or e_left.is_empty():
        _fail(failures, "listing_swing_long: missing inner-wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    if not EngagementOpposition.is_mapped_file_opposed(wide, p_inner, e_left):
        _fail(failures, "listing_swing_long: want mapped inner-wing pair")
        HarnessFixtures._free_manager(wide)
        return
    var e_id: int = CombatantEntityAccess.id_int(e_left)
    var p_id: int = CombatantEntityAccess.id_int(p_inner)
    var eff: float = CombatPairGeometry.effective_pair_eff_dist(wide, p_inner, e_left)
    if eff >= CombatMeleeListing.melee_weapon_reach(p_inner):
        _fail(failures, "listing_swing_long: setup want in-swing pair got eff=%.3f" % eff)
        HarnessFixtures._free_manager(wide)
        return
    CombatantEntityAccess.nested_dictionary_for_mutation(p_inner, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(e_left, "distance_to")[p_id] = (CombatConstants.DISTANCE_LONG)
    p_inner["gauge"] = 100.0
    var acts: Array = wide.get_available_actions(p_id)
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, p_id):
        _fail(
            failures, "listing_swing_long: want melee strike listed at LONG when reach covers"
        )
    if not (
        CombatListedActions.first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, e_id).is_empty()
    ):
        _fail(
            failures, "listing_swing_long: must not list attempt_close when in-swing at LONG band"
        )
    HarnessFixtures._free_manager(wide)


## 7v3 inner wing (mapped gap 1): recompute promotes MID and lists strikes without close.


## 7v3 inner wing (mapped gap 1): recompute promotes MID and lists strikes without close.
static func _run_inner_wing_gap1_mid_strikes_after_recompute(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_inner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 1)
    var e_left: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 0)
    if p_inner.is_empty() or e_left.is_empty():
        _fail(failures, "inner_wing_mid: missing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    wide.recompute_zoc_and_distance()
    var e_id: int = CombatantEntityAccess.id_int(e_left)
    var band: String = CombatantEntityAccess.distance_to_opponent_band(p_inner, e_id, "")
    if band == CombatConstants.DISTANCE_LONG:
        _fail(failures, "inner_wing_mid: mapped gap 1 want MID/CLOSE band got %s" % band)
        HarnessFixtures._free_manager(wide)
        return
    p_inner["gauge"] = 100.0
    var acts: Array = wide.get_available_actions(CombatantEntityAccess.id_int(p_inner))
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, CombatantEntityAccess.id_int(p_inner)):
        _fail(failures, "inner_wing_mid: want strikes listed after recompute")
    HarnessFixtures._free_manager(wide)


## 7v3 outer wing: successful close at LONG lists strikes on next menu without ZoC recompute.


## 7v3 outer wing: successful close at LONG lists strikes on next menu without ZoC recompute.
static func _run_close_success_wing_lists_strikes_without_recompute(failures: PackedStringArray) -> void:
    seed(0)
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    if p_wing.is_empty() or e_wing.is_empty():
        _fail(failures, "close_success_wing: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    var p_id: int = CombatantEntityAccess.id_int(p_wing)
    var e_id: int = CombatantEntityAccess.id_int(e_wing)
    var eff: float = CombatPairGeometry.effective_pair_eff_dist(wide, p_wing, e_wing)
    if eff <= CombatMeleeListing.melee_weapon_reach(p_wing):
        _fail(failures, "close_success_wing: setup want out-of-reach wing got eff=%.3f" % eff)
        HarnessFixtures._free_manager(wide)
        return
    CombatantEntityAccess.nested_dictionary_for_mutation(p_wing, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(e_wing, "distance_to")[p_id] = (CombatConstants.DISTANCE_LONG)
    var sd: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(p_wing)
    sd["strength"] = 400.0
    var sd_e: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(e_wing)
    sd_e["agility"] = 5.0
    p_wing["gauge"] = 100.0
    var cap: Array = []
    wide.action_resolved.connect(
        func(_a: int, _t: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    CombatEngagementResolver.resolve_close_attempt(wide, p_id, e_id)
    if cap.is_empty():
        _fail(failures, "close_success_wing: expected action_resolved")
        HarnessFixtures._free_manager(wide)
        return
    if str((cap[0] as Dictionary).get("outcome", "")) != "close_success":
        _fail(failures, "close_success_wing: expected close_success got %s" % str(cap[0]))
        HarnessFixtures._free_manager(wide)
        return
    if CombatantEntityAccess.distance_to_opponent_band(p_wing, e_id, "") != CombatConstants.DISTANCE_CLOSE:
        _fail(
            failures,
            (
                "close_success_wing: want CLOSE band after bind got %s"
                % CombatantEntityAccess.distance_to_opponent_band(p_wing, e_id, "")
            )
        )
        HarnessFixtures._free_manager(wide)
        return
    p_wing["gauge"] = 100.0
    var acts: Array = wide.get_available_actions(p_id)
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, p_id):
        _fail(
            failures, "close_success_wing: want strikes listed after close bind without recompute"
        )
    if not (
        CombatListedActions.first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, e_id).is_empty()
    ):
        _fail(failures, "close_success_wing: must not list attempt_close at CLOSE after bind")
    HarnessFixtures._free_manager(wide)


## Player hint: mapped outer wing at LONG out of reach  -  not wing_lacks copy.


## Player hint: mapped outer wing at LONG out of reach  -  not wing_lacks copy.
static func _run_mapped_wing_out_of_reach_hold_hint(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    if p_wing.is_empty() or e_wing.is_empty():
        _fail(failures, "wing_out_of_reach_hint: missing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    if EngagementOpposition.wing_lacks_mapped_opposition(wide, p_wing):
        _fail(failures, "wing_out_of_reach_hint: outer wing should have mapped opposition")
        HarnessFixtures._free_manager(wide)
        return
    var e_id: int = CombatantEntityAccess.id_int(e_wing)
    var p_id: int = CombatantEntityAccess.id_int(p_wing)
    CombatantEntityAccess.nested_dictionary_for_mutation(p_wing, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(e_wing, "distance_to")[p_id] = (CombatConstants.DISTANCE_LONG)
    p_wing["gauge"] = 100.0
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": p_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": p_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
    ]
    if not CombatMeleeListing.attempt_close_listed_for_pair(wide, p_wing, e_id, CombatConstants.DISTANCE_LONG):
        _fail(failures, "wing_out_of_reach_hint: setup want close listed at LONG out of reach")
        HarnessFixtures._free_manager(wide)
        return
    var hint: String = CombatPlayerTurnHints.hold_line_focus_only_hint(wide, p_wing, acts)
    if not hint.contains("out of reach"):
        _fail(failures, "wing_out_of_reach_hint: want out-of-reach copy got '%s'" % hint)
    if hint.contains("no mapped front"):
        _fail(failures, "wing_out_of_reach_hint: must not use wing_lacks copy")
    HarnessFixtures._free_manager(wide)


## Defense-in-depth: attempt_close_listed_for_pair false when in-swing at LONG band.


## Defense-in-depth: attempt_close_listed_for_pair false when in-swing at LONG band.
static func _run_attempt_close_listed_for_pair_omit_in_swing_long(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_inner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 1)
    var e_left: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 0)
    if p_inner.is_empty() or e_left.is_empty():
        _fail(failures, "close_listed_in_swing: missing inner-wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    var e_id: int = CombatantEntityAccess.id_int(e_left)
    if CombatMeleeListing.attempt_close_listed_for_pair(wide, p_inner, e_id, CombatConstants.DISTANCE_LONG):
        _fail(failures, "close_listed_in_swing: must not list close when in-swing at LONG")
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_right: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    if p_wing.is_empty() or e_right.is_empty():
        _fail(failures, "close_listed_in_swing: missing outer-wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    var e_wing_id: int = CombatantEntityAccess.id_int(e_right)
    if not CombatMeleeListing.attempt_close_listed_for_pair(wide, p_wing, e_wing_id, CombatConstants.DISTANCE_LONG):
        _fail(
            failures, "close_listed_in_swing: outer wing out of reach should list close at LONG"
        )
    HarnessFixtures._free_manager(wide)


## Resolve: stale close at LONG when in-swing must block (listing parity + telemetry).


## Resolve: stale close at LONG when in-swing must block (listing parity + telemetry).
static func _run_resolve_close_blocked_in_swing_long(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var p: Dictionary = mgr.combatants[0]
    var en: Dictionary = mgr.combatants[1]
    CombatantEntityAccess.nested_dictionary_for_mutation(p, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(en, "distance_to")[p_id] = (CombatConstants.DISTANCE_LONG)
    if not CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(p), CombatPairGeometry.effective_pair_eff_dist(mgr, p, en)
    ):
        _fail(failures, "resolve_close_in_swing: setup want in-swing pair at LONG band")
        HarnessFixtures._free_manager(mgr)
        return
    if mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        mgr.remove_meta(TacticalCombat.META_COMBAT_TELEMETRY)
    var cap: Array = []
    mgr.action_resolved.connect(
        func(_a: int, _t: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if cap.is_empty():
        _fail(failures, "resolve_close_in_swing: expected action_resolved")
        HarnessFixtures._free_manager(mgr)
        return
    if str((cap[0] as Dictionary).get("outcome", "")) != "close_failed":
        _fail(failures, "resolve_close_in_swing: want close_failed got %s" % str(cap[0]))
    elif str((cap[0] as Dictionary).get("reason", "")) != "not_long":
        _fail(
            failures,
            "resolve_close_in_swing: want reason not_long got %s" % str((cap[0] as Dictionary).get("reason", ""))
        )
    elif not mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        _fail(failures, "resolve_close_in_swing: want telemetry meta")
    elif (
        int((mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary).get("invalid_close_resolve_blocked", 0))
        < 1
    ):
        _fail(failures, "resolve_close_in_swing: want invalid_close_resolve_blocked >= 1")
    HarnessFixtures._free_manager(mgr)


## L4: mapped 7v3 outer wing out of reach is close-pick eligible (not wing_lacks-only).


## L4: mapped 7v3 outer wing out of reach is close-pick eligible (not wing_lacks-only).
static func _run_hold_line_close_pick_mapped_wing_out_of_reach(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    var p_center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 3)
    if p_wing.is_empty() or e_wing.is_empty() or p_center.is_empty():
        _fail(failures, "hold_line_wing_close: missing 7v3 fixtures")
        HarnessFixtures._free_manager(wide)
        return
    if EngagementOpposition.wing_lacks_mapped_opposition(wide, p_wing):
        _fail(failures, "hold_line_wing_close: outer wing should have mapped opposition")
        HarnessFixtures._free_manager(wide)
        return
    if not EngagementOpposition.rank0_needs_bind_close_at_long(wide, p_wing):
        _fail(failures, "hold_line_wing_close: setup want bind-close need on outer wing")
        HarnessFixtures._free_manager(wide)
        return
    if not CombatDoctrine.hold_line_close_pick_eligible(wide, p_wing):
        _fail(
            failures, "hold_line_wing_close: mapped out-of-reach wing want close_pick_eligible"
        )
    if CombatDoctrine.hold_line_close_pick_eligible(wide, p_center):
        _fail(failures, "hold_line_wing_close: center in-swing should not need bind-close pick")
    var wing_id: int = CombatantEntityAccess.id_int(p_wing)
    var e_id: int = CombatantEntityAccess.id_int(e_wing)
    CombatantEntityAccess.nested_dictionary_for_mutation(p_wing, "distance_to")[e_id] = (CombatConstants.DISTANCE_LONG)
    CombatantEntityAccess.nested_dictionary_for_mutation(e_wing, "distance_to")[wing_id] = (
        CombatConstants.DISTANCE_LONG
    )
    p_wing["gauge"] = 100.0
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": wing_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": wing_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(acts, wing_id, wide)
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        _fail(
            failures, "hold_line_wing_close: want attempt_close pick got %s" % str(picked.get("move_id", ""))
        )
    HarnessFixtures._free_manager(wide)


## Bind-close wing: shuffle futile (`rotate_suppress`); utility pick favors close over wait.


## Bind-close wing: shuffle futile (`rotate_suppress`); utility pick favors close over wait.
static func _run_bind_close_rotate_suppressed_and_close_weight(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    var partner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 5)
    if p_wing.is_empty() or e_wing.is_empty() or partner.is_empty():
        _fail(failures, "bind_close_ai: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    var wing_id: int = CombatantEntityAccess.id_int(p_wing)
    var e_id: int = CombatantEntityAccess.id_int(e_wing)
    var partner_id: int = CombatantEntityAccess.id_int(partner)
    HarnessFixtures._harness_bind_pair_long_band(p_wing, e_wing)
    if not EngagementOpposition.rank0_needs_bind_close_at_long(wide, p_wing):
        _fail(failures, "bind_close_ai: setup want bind-close need")
        HarnessFixtures._free_manager(wide)
        return
    p_wing["gauge"] = 100.0
    var menu: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": wing_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": partner_id},
    ]
    if not CombatDoctrine.should_suppress_skirmish_rotate_file(wide, p_wing, menu):
        _fail(failures, "bind_close_ai: want rotate suppressed on bind-close wing")
    if CombatAIActionPicker._long_close_only_offense_menu(wide, p_wing, wing_id, menu):
        _fail(
            failures, "bind_close_ai: bind-close wing must not use long close-only shuffle helper"
        )
    var w_rot: float = CombatAIActionPicker._get_action_weight(menu[2], wing_id, wide, true, {}, {}, menu)
    if w_rot > 0.001:
        _fail(
            failures, "bind_close_ai: rotate weight should be 0 when suppressed got %.4f" % w_rot
        )
    var w_close: float = CombatAIActionPicker._get_action_weight(menu[1], wing_id, wide, true, {}, {}, menu)
    var w_wait: float = CombatAIActionPicker._get_action_weight(menu[0], wing_id, wide, true, {}, {}, menu)
    if w_close <= w_wait * 1.05:
        _fail(
            failures, "bind_close_ai: close should beat wait got close=%.4f wait=%.4f" % [w_close, w_wait]
        )
    HarnessFixtures._free_manager(wide)


static func _run_border_skirmish_encounter_enemy_pinch(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.encounter = {
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 7,
        CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER: 50.0,
        CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY: 50.0,
    }
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(
            failures,
            "border_skirmish_pinch: enemy doctrine want pinch_center got %s" % mgr.get_formation_doctrine("enemy")
        )
    HarnessFixtures._free_manager(mgr)


static func _run_opposition_equal_width_same_index(failures: PackedStringArray) -> void:
    var eq: Node = CombatManager.new()
    for _i in 3:
        eq.register(_new_entity("SWORD"), "player")
    for _j in 3:
        eq.register(_new_entity("SWORD"), "enemy")
    eq.start({"files": 3, "ranks": 1}, {"files": 3, "ranks": 1})
    if EngagementOpposition.opposition_file_offset(eq, "player") != 0:
        _fail(failures, "opposition_offset: equal width expected offset 0")
    for fi in 3:
        var pp: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(eq, "player", 0, fi)
        var ee: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(eq, "enemy", 0, fi)
        if pp.is_empty() or ee.is_empty():
            _fail(failures, "opposition_offset: 3v3 missing file %d fixtures" % fi)
        elif not EngagementOpposition.is_mapped_file_opposed(eq, pp, ee):
            _fail(
                failures, "opposition_offset: 3v3 file %d should oppose same-index enemy only" % fi
            )
        for fj in 3:
            if fi == fj:
                continue
            var ee_off: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(eq, "enemy", 0, fj)
            if EngagementOpposition.is_mapped_file_opposed(eq, pp, ee_off):
                _fail(
                    failures, "opposition_offset: 3v3 file %d should not map to enemy file %d" % [fi, fj]
                )
    eq.start({"files": 2, "ranks": 2}, {"files": 4, "ranks": 1})
    if EngagementOpposition.opposition_file_offset(eq, "player") != -1:
        _fail(
            failures,
            (
                "opposition_offset: second start 2 vs 4 expected player offset -1 got %d"
                % EngagementOpposition.opposition_file_offset(eq, "player")
            )
        )
    eq.stop()
    if eq.has_meta(EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
        _fail(failures, "opposition_offset: stop() should clear opposition meta")
    HarnessFixtures._free_manager(eq)


## III-6: depth spear reserve skips with faster recheck when lane is open (same-file rank-0 ally).


## III-6: depth spear reserve skips with faster recheck when lane is open (same-file rank-0 ally).
static func _run_back_rank_depth_lane_skip_recheck(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var rear: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c) and CombatantEntityAccess.rank_int(c) == 1:
            rear = c
            break
    if rear.is_empty():
        _fail(failures, "back_rank_depth_skip: missing rank-1 spear reserve")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, rear):
        _fail(failures, "back_rank_depth_skip: expected depth lane open")
        HarnessFixtures._free_manager(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    mgr.skip_turn(rear_id)
    var delay: float = CombatEventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S
    if absf(delay - want) > 0.05:
        _fail(failures, "back_rank_depth_skip: want delay %.2f got %.2f" % [want, delay])
    HarnessFixtures._free_manager(mgr)


## III-6 maintain: rear relief swap gets line-plug weight when another file has rank-0 hole.


## III-6 maintain: rear relief swap gets line-plug weight when another file has rank-0 hole.
static func _run_swap_rank_line_plug_weight_when_front_hole(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _fail(failures, "swap_rank_line_plug: missing hole/rear/front fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if FormationSlots.slot_has_any_living_occupant(mgr, slots, Vector2i(0, 4)):
        _fail(failures, "swap_rank_line_plug: want empty rank-0 file 4 after kill")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatFormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _fail(failures, "swap_rank_line_plug: want rank-0 hole on line after kill")
        HarnessFixtures._free_manager(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _fail(failures, "swap_rank_line_plug: want relief swap blocked for weight test")
        HarnessFixtures._free_manager(mgr)
        return
    var swap_act: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_SWAP_RANK,
        "target_id": CombatantEntityAccess.id_int(front),
    }
    var w: float = CombatAIActionPicker._get_action_weight(
        swap_act, CombatantEntityAccess.id_int(rear), mgr, true, {}, {}
    )
    if w < CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT - 0.01:
        _fail(
            failures, "swap_rank_line_plug: want >= %.2f got %.3f" % [CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT, w]
        )
    HarnessFixtures._free_manager(mgr)


## III-6: rank-0 turn resolves -> same-file reserves get formation recheck delay.


## III-6: rank-0 turn resolves -> same-file reserves get formation recheck delay.
static func _run_same_file_depth_recheck_after_front_turn(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var front: Dictionary = {}
    var rear: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.rank_int(c) == 0:
            front = c
        elif CombatantEntityAccess.rank_int(c) == 1:
            rear = c
    if front.is_empty() or rear.is_empty():
        _fail(failures, "depth_recheck_front_turn: missing front/rear pair")
        HarnessFixtures._free_manager(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    mgr.skip_turn(front_id)
    var delay: float = CombatEventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    if absf(delay - want) > 0.05:
        _fail(failures, "depth_recheck_front_turn: want delay %.2f got %.2f" % [want, delay])
    HarnessFixtures._free_manager(mgr)


## III-6: rank-0 wind-up abort -> same-file reserves get formation recheck delay.


## III-6: rank-0 wind-up abort -> same-file reserves get formation recheck delay.
static func _run_windup_abort_same_file_depth_recheck(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var front: Dictionary = {}
    var rear: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.rank_int(c) == 0:
            front = c
        elif CombatantEntityAccess.rank_int(c) == 1:
            rear = c
    if front.is_empty() or rear.is_empty():
        _fail(failures, "windup_depth_recheck: missing front/rear pair")
        HarnessFixtures._free_manager(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])
    AttackWindUpStarter.start(mgr, front_id, enemy_id, "thrust")
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    HarnessFixtures._harness_destroy_limb(ent, "right_arm")
    HarnessFixtures._harness_destroy_limb(ent, "left_arm")
    CombatStateHandlers.process_wind_up(mgr, front, 0.05)
    var delay: float = CombatEventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    if absf(delay - want) > 0.05:
        _fail(failures, "windup_depth_recheck: want delay %.2f got %.2f" % [want, delay])
    HarnessFixtures._free_manager(mgr)


## III-6: rank-1 wind-up abort -> rank-2+ same-file reserves get formation recheck delay.


## III-6: rank-1 wind-up abort -> rank-2+ same-file reserves get formation recheck delay.
static func _run_windup_abort_rank1_same_file_depth_recheck(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var rank1: Dictionary = {}
    var rank2: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.rank_int(c) == 1:
            rank1 = c
        elif CombatantEntityAccess.rank_int(c) == 2:
            rank2 = c
    if rank1.is_empty() or rank2.is_empty():
        _fail(failures, "windup_depth_recheck_rank1: missing rank-1/rank-2 column")
        HarnessFixtures._free_manager(mgr)
        return
    var rank1_id: int = CombatantEntityAccess.id_int(rank1)
    var rank2_id: int = CombatantEntityAccess.id_int(rank2)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[3])
    AttackWindUpStarter.start(mgr, rank1_id, enemy_id, "spear_slash")
    if CombatantEntityAccess.state_str(rank1) != CombatConstants.STATE_WIND_UP:
        _fail(failures, "windup_depth_recheck_rank1: rank-1 wind-up should start")
        HarnessFixtures._free_manager(mgr)
        return
    var ent: CoreEntity = CombatantEntityAccess.scene_node(rank1) as CoreEntity
    HarnessFixtures._harness_destroy_limb(ent, "right_arm")
    HarnessFixtures._harness_destroy_limb(ent, "left_arm")
    CombatStateHandlers.process_wind_up(mgr, rank1, 0.05)
    var delay: float = CombatEventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    if absf(delay - want) > 0.05:
        _fail(failures, "windup_depth_recheck_rank1: want delay %.2f got %.2f" % [want, delay])
    HarnessFixtures._free_manager(mgr)


## III-6: rank-0 wind-up start -> same-file depth reserves get formation recheck delay.


## III-6: rank-0 wind-up start -> same-file depth reserves get formation recheck delay.
static func _run_windup_start_same_file_depth_recheck(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var front: Dictionary = {}
    var rear: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.rank_int(c) == 0:
            front = c
        elif CombatantEntityAccess.rank_int(c) == 1:
            rear = c
    if front.is_empty() or rear.is_empty():
        _fail(failures, "windup_start_depth_recheck: missing front/rear pair")
        HarnessFixtures._free_manager(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var enemy_id: int = -1
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c) and CombatantEntityAccess.rank_int(c) == 0:
            enemy_id = CombatantEntityAccess.id_int(c)
            break
    if enemy_id < 0:
        _fail(failures, "windup_start_depth_recheck: missing enemy front")
        HarnessFixtures._free_manager(mgr)
        return
    AttackWindUpStarter.start(mgr, front_id, enemy_id, "thrust")
    if CombatantEntityAccess.state_str(front) != CombatConstants.STATE_WIND_UP:
        _fail(failures, "windup_start_depth_recheck: front should enter wind_up")
        HarnessFixtures._free_manager(mgr)
        return
    var delay: float = CombatEventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    if absf(delay - want) > 0.05:
        _fail(failures, "windup_start_depth_recheck: want delay %.2f got %.2f" % [want, delay])
    HarnessFixtures._free_manager(mgr)


## III-6: **`rotate_file`** resolve rechecks depth reserves in both swapped file columns.


## III-6: **`rotate_file`** resolve rechecks depth reserves in both swapped file columns.
static func _run_rotate_file_depth_recheck_both_columns(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var rot0: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rot1: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    var rear0: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var rear1: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 1)
    if rot0.is_empty() or rot1.is_empty() or rear0.is_empty() or rear1.is_empty():
        _fail(failures, "rotate_depth_recheck: missing 2x2 fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    mgr.combat_clock = 1.0
    var id0: int = CombatantEntityAccess.id_int(rot0)
    var id1: int = CombatantEntityAccess.id_int(rot1)
    var rear0_id: int = CombatantEntityAccess.id_int(rear0)
    var rear1_id: int = CombatantEntityAccess.id_int(rear1)
    CombatFormationFlow.start_rotate_file(mgr, id0, id1)
    CombatFormationFlow.handle_rotate_file_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1}}
    )
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    var delay0: float = CombatEventScheduler.get_next_action_ready_at(mgr, rear0_id) - mgr.combat_clock
    var delay1: float = CombatEventScheduler.get_next_action_ready_at(mgr, rear1_id) - mgr.combat_clock
    HarnessFixtures._free_manager(mgr)
    if absf(delay0 - want) > 0.05:
        _fail(
            failures, "rotate_depth_recheck: file-0 reserve want delay %.2f got %.2f" % [want, delay0]
        )
    if absf(delay1 - want) > 0.05:
        _fail(
            failures, "rotate_depth_recheck: file-1 reserve want delay %.2f got %.2f" % [want, delay1]
        )


## III-6: Skirmish rotate gauge suffix when rank-0 gap and **`rotate_file`** listed.


## III-6: Skirmish rotate gauge suffix when rank-0 gap and **`rotate_file`** listed.
static func _run_skirmish_rotate_gauge_suffix_when_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _fail(failures, "skirmish_rotate_gauge: expected skirmish mode")
        HarnessFixtures._free_manager(mgr)
        return
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rot_src: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rot_src.is_empty():
        _fail(failures, "skirmish_rotate_gauge: missing hole/rotate fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    rot_src["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rot_src))
    CombatPlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, rot_src, acts)
    var stamp: String = str(rot_src.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
    HarnessFixtures._free_manager(mgr)
    if "Line gap" not in stamp:
        _fail(
            failures, "skirmish_rotate_gauge: want rotate gap suffix on gauge stamp got %s" % stamp
        )


## III-6: **`swap_rank`** resolve rechecks rank-2+ reserves in the swapped column.


## III-6: **`swap_rank`** resolve rechecks rank-2+ reserves in the swapped column.
static func _run_swap_rank_depth_recheck_rank2_after_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var rank0: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rank1: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var rank2: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 2, 0)
    if rank0.is_empty() or rank1.is_empty() or rank2.is_empty():
        _fail(failures, "swap_depth_recheck: missing 1x3 column fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    mgr.combat_clock = 1.0
    var id0: int = CombatantEntityAccess.id_int(rank0)
    var id1: int = CombatantEntityAccess.id_int(rank1)
    var rank2_id: int = CombatantEntityAccess.id_int(rank2)
    CombatFormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    CombatFormationFlow.handle_swap_rank_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    var delay2: float = CombatEventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
    var delay1: float = CombatEventScheduler.get_next_action_ready_at(mgr, id1) - mgr.combat_clock
    var prom: float = CombatConstants.READY_DELAY_AFTER_PROMOTION_S
    HarnessFixtures._free_manager(mgr)
    if absf(delay2 - want) > 0.05:
        _fail(failures, "swap_depth_recheck: rank-2 want delay %.2f got %.2f" % [want, delay2])
    if absf(delay1 - prom) > 0.05:
        _fail(
            failures, "swap_depth_recheck: demoted rank-1 want promotion %.2f got %.2f" % [prom, delay1]
        )


## III-6: **`reschedule_same_file_depth_rank2_plus`** wakes rank-2+ in a column (wired from swap / fall_back resolve).


## III-6: **`reschedule_same_file_depth_rank2_plus`** wakes rank-2+ in a column (wired from swap / fall_back resolve).
static func _run_same_file_depth_rank2_plus_scheduler(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var rank1: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var rank2: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 2, 0)
    if rank1.is_empty() or rank2.is_empty():
        _fail(failures, "rank2_plus_scheduler: missing rank-1/rank-2 fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    rank1["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    mgr.combat_clock = 1.0
    var rank2_id: int = CombatantEntityAccess.id_int(rank2)
    CombatEventScheduler.reschedule_same_file_depth_rank2_plus(mgr, "player", 0)
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    var delay2: float = CombatEventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
    HarnessFixtures._free_manager(mgr)
    if absf(delay2 - want) > 0.05:
        _fail(
            failures, "rank2_plus_scheduler: rank-2 want delay %.2f got %.2f" % [want, delay2]
        )


## III-6: lone rank-0 **`fall_back_solo`** demotes when the rear slot in-column is empty (ii5-style).


## III-6: lone rank-0 **`fall_back_solo`** demotes when the rear slot in-column is empty (ii5-style).
static func _run_fall_back_solo_demotes_when_rear_slot_empty(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    (
        mgr
        . start(
            {
                "files": 1,
                "ranks": 2,
                "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
                "density": "normal",
            },
            {"files": 1, "ranks": 1, "density": "normal"}
        )
    )
    var rank0: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if rank0.is_empty():
        _fail(failures, "fall_back_solo_demote: missing rank-0 fixture")
        HarnessFixtures._free_manager(mgr)
        return
    mgr.combat_clock = 1.0
    var rank0_id: int = CombatantEntityAccess.id_int(rank0)
    rank0["state"] = CombatConstants.STATE_FALLING_BACK
    rank0["state_timer"] = float(rank0.get(DataKeys.PA_STATE_DURATION, CombatConstants.BASE_FALL_BACK_S))
    CombatFormationFlow.handle_fall_back_solo_resolve(mgr, {"combatant_id": rank0_id, "resolve_at": 0.0, "data": {}})
    var after: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, rank0_id)
    var rank_after: int = CombatantEntityAccess.rank_int(after)
    HarnessFixtures._free_manager(mgr)
    if rank_after != 1:
        _fail(failures, "fall_back_solo_demote: want rank1 got rank=%d" % rank_after)

## III-6: sparse column (rank-0 + rank-2, empty rank-1)  -  solo fall_back demotes without vacancy undo; rank-2 recheck
## delay.
