class_name Tier1SparseLineMopUpTests
extends CombatRegressionHarnessCore
const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_sparse_line_rotate_no_line_plug_weight_floor(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_no_plug_floor: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var partner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 5)
    if survivor.is_empty() or partner.is_empty():
        _fail(failures, "sparse_no_plug_floor: missing survivor/partner")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    partner["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var partner_id: int = CombatantEntityAccess.id_int(partner)
    var reserve_only: Array = []
    for raw in AvailableActionsBuilder.build(mgr, survivor_id):
        var a: Dictionary = CombatListedActions._entry(raw)
        if a.is_empty():
            continue
        var mid: String = CombatListedActions.entry_move_id(a)
        if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
            reserve_only.append(a)
    var rot_act: Dictionary = CombatListedActions.first_action_move_vs_target(
        reserve_only, CombatConstants.MOVE_ID_ROTATE_FILE, partner_id
    )
    if rot_act.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var w_rot: float = CombatAIActionPicker._get_action_weight(rot_act, survivor_id, mgr, true, {}, {}, reserve_only)
    if w_rot >= CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT - 0.001:
        _fail(failures, "sparse_no_plug_floor: want < line_plug min on sparse line got %.3f" % w_rot)
    HarnessFixtures._free_manager(mgr)


## Sparse line: no line-plug swap weight / plug pick when distant holes remain (parity with rotate).


## Sparse line: no line-plug swap weight / plug pick when distant holes remain (parity with rotate).
static func _run_sparse_line_swap_no_line_plug_weight_floor(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 12:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_swap_plug: missing rank-0 flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        _fail(failures, "sparse_swap_plug: want sparse line after flee")
        HarnessFixtures._free_manager(mgr)
        return
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 4)
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty() or front.is_empty():
        _fail(failures, "sparse_swap_plug: missing rear/front at file 4")
        HarnessFixtures._free_manager(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _fail(failures, "sparse_swap_plug: want relief swap blocked")
        HarnessFixtures._free_manager(mgr)
        return
    rear["gauge"] = 100.0
    front["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var front_id: int = CombatantEntityAccess.id_int(front)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    var swap_act: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_SWAP_RANK,
        "target_id": front_id,
    }
    var w: float = CombatAIActionPicker._get_action_weight(swap_act, rear_id, mgr, true, {}, {}, acts)
    if w >= CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT - 0.001:
        _fail(failures, "sparse_swap_plug: want < line_plug min on sparse line got %.3f" % w)
    if CombatFormationMoveListing.listed_action_is_formation_plug_pick(mgr, rear, swap_act, acts, rear_id):
        _fail(failures, "sparse_swap_plug: swap must not count as formation_plug pick")
    if CombatFormationMoveListing.swap_rank_action_legal(mgr, rear, front):
        _fail(failures, "sparse_swap_plug: line-plug relief swap should not list on sparse line")
    var hint: String = CombatPlayerTurnHints.front_gap_line_plug_hint(mgr, rear, acts)
    if not hint.is_empty():
        _fail(failures, "sparse_swap_plug: front_gap hint should stay empty on sparse got %s" % hint)
    HarnessFixtures._free_manager(mgr)


## III-6 / 3e: sparse post-flee strike pick logs **`line_plug=false`** even when distant holes remain.


## III-6 / 3e: sparse post-flee strike pick logs **`line_plug=false`** even when distant holes remain.
static func _run_engagement_debug_line_plug_false_on_sparse_strike_pick(failures: PackedStringArray) -> void:
    var fix: Dictionary = HarnessFixtures._harness_sparse_post_flee_6v3_mgr()
    if fix.is_empty():
        _fail(failures, "sparse_line_plug_log: fixture setup failed")
        return
    var mgr: Node = fix["mgr"]
    var survivor: Dictionary = fix["survivor"]
    var survivor_id: int = int(fix["survivor_id"])
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        _fail(failures, "sparse_line_plug_log: want sparse line")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatFormationFlow.formation_line_has_rank0_gap(mgr, "player"):
        _fail(failures, "sparse_line_plug_log: want rank-0 gap on sparse line")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    var strike: Dictionary = {}
    for raw in acts:
        var a: Dictionary = CombatListedActions._entry(raw)
        if a.is_empty():
            continue
        var mid: String = CombatListedActions.entry_move_id(a)
        if mid in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
            continue
        if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
            continue
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        strike = a
        break
    if strike.is_empty():
        _fail(failures, "sparse_line_plug_log: want listed strike on sparse survivor")
        HarnessFixtures._free_manager(mgr)
        return
    if CombatEngagementDiagnostics.line_plug_logged_for_pick(mgr, survivor, survivor_id, acts, strike):
        _fail(failures, "sparse_line_plug_log: want line_plug=false on sparse strike pick")
    HarnessFixtures._free_manager(mgr)


## Fight-finish / sparse: redundant attempt_close at CLOSE when melee is listed should weight 0.


## Fight-finish / sparse: redundant attempt_close at CLOSE when melee is listed should weight 0.
static func _run_sparse_attempt_close_weight_zero_when_close_and_melee_listed(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        _fail(failures, "sparse_close_weight: missing center/enemy fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    center["gauge"] = 100.0
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[center_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var acts: Array = AvailableActionsBuilder.build(mgr, center_id)
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, center_id):
        _fail(failures, "sparse_close_weight: want listed melee at CLOSE during mop-up")
        HarnessFixtures._free_manager(mgr)
        return
    var close_act: Dictionary = CombatListedActions.first_action_move_vs_target(
        acts, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, enemy_id
    )
    if not close_act.is_empty():
        _fail(failures, "sparse_close_weight: want attempt_close stripped from menu at CLOSE with melee listed")
        HarnessFixtures._free_manager(mgr)
        return
    HarnessFixtures._free_manager(mgr)


## Listing strip: synthetic melee+close menu drops close at CLOSE when finish-prefer active.


## Listing strip: synthetic melee+close menu drops close at CLOSE when finish-prefer active.
static func _run_sparse_strip_redundant_close_at_close(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        _fail(failures, "sparse_strip_close: missing center/enemy fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var acts: Array = [
        {"target_id": enemy_id, "move_id": "overhead_strike"},
        {"target_id": enemy_id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE},
    ]
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(mgr, center, acts, center_id):
        _fail(failures, "sparse_strip_close: want sparse_prefer_finish on synthetic menu")
        HarnessFixtures._free_manager(mgr)
        return
    CombatMeleeListing.strip_redundant_attempt_close_for_finish(mgr, center, acts)
    if not (
        CombatListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, enemy_id)
        . is_empty()
    ):
        _fail(failures, "sparse_strip_close: want attempt_close removed when melee listed at CLOSE")
    HarnessFixtures._free_manager(mgr)


## L4 hold-line: non-mop-up CLOSE band with close-only menu must not keep attempt_close in pick pool.


## L4 hold-line: non-mop-up CLOSE band with close-only menu must not keep attempt_close in pick pool.
static func _run_hold_line_close_filter_omits_close_at_close_non_mop_up(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _fail(failures, "hold_line_close_filter: 1v1 must not be mop-up")
        HarnessFixtures._free_manager(mgr)
        return
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var enemy: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    if player.is_empty() or enemy.is_empty():
        _fail(failures, "hold_line_close_filter: missing fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    var player_id: int = CombatantEntityAccess.id_int(player)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    var close_pool: Array = MentalStackDecider._filter_hold_line_close_actions(acts, player_id, mgr, player)
    if not (
        CombatListedActions
        . first_action_move_vs_target(close_pool, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, enemy_id)
        . is_empty()
    ):
        _fail(failures, "hold_line_close_filter: non-mop-up CLOSE must omit attempt_close without melee")
    HarnessFixtures._free_manager(mgr)


## Canonical helper: sparse rank-0 CLOSE/MID band prefers finish over shuffle.


## Canonical helper: sparse rank-0 CLOSE/MID band prefers finish over shuffle.
static func _run_sparse_prefer_finish_helper_close_band(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_prefer_finish: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if survivor.is_empty() or enemy.is_empty():
        _fail(failures, "sparse_prefer_finish: missing survivor/enemy")
        HarnessFixtures._free_manager(mgr)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(survivor, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var reserve_only: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": survivor_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_LEFT, "target_id": survivor_id},
    ]
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(mgr, survivor, reserve_only, survivor_id):
        _fail(failures, "sparse_prefer_finish: want true at CLOSE on sparse rank-0")
    HarnessFixtures._free_manager(mgr)


## Fight-finish reserve-only: L4 must not return wait when close pool is empty (utility pick handles finish).


## Fight-finish reserve-only: L4 must not return wait when close pool is empty (utility pick handles finish).
static func _run_fight_finish_reserve_only_skips_hold_wait(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        _fail(failures, "fight_finish_skip_wait: missing center/enemy fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    center["gauge"] = 100.0
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[center_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var acts: Array = AvailableActionsBuilder.build(mgr, center_id)
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, center_id):
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDoctrine.fight_finish_tail_active(mgr, center, acts, center_id):
        _fail(failures, "fight_finish_skip_wait: want fight_finish_tail on mop-up center")
        HarnessFixtures._free_manager(mgr)
        return
    var reserve_only: Array = []
    for raw in acts:
        var a: Dictionary = CombatListedActions._entry(raw)
        if a.is_empty():
            continue
        if CombatListedActions.is_reserve_posture_listing_move_id(CombatListedActions.entry_move_id(a)):
            reserve_only.append(a)
    if not CombatListedActions.action_list_is_reserve_posture_only(reserve_only):
        HarnessFixtures._free_manager(mgr)
        return
    var picked: Dictionary = MentalStackDecider.try_pick(reserve_only, center_id, mgr)
    if picked.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var layer: String = str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    var mid: String = str(picked.get("move_id", ""))
    if layer == CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE and mid == CombatConstants.MOVE_ID_WAIT:
        _fail(failures, "fight_finish_skip_wait: hold_line must not pick wait when close pool empty at CLOSE")
    HarnessFixtures._free_manager(mgr)


## Post-flee sparse: full AI pick + fight-finish engagement flags (F5 grep parity).


## Post-flee sparse: full AI pick + fight-finish engagement flags (F5 grep parity).
static func _run_sparse_post_flee_full_pick_offense(failures: PackedStringArray) -> void:
    var fix: Dictionary = HarnessFixtures._harness_sparse_post_flee_6v3_mgr()
    if fix.is_empty():
        _fail(failures, "sparse_full_pick: fixture setup failed")
        return
    var mgr: Node = fix["mgr"]
    var survivor: Dictionary = fix["survivor"]
    var survivor_id: int = int(fix["survivor_id"])
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        _fail(failures, "sparse_full_pick: want sparse_line")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    survivor["state"] = CombatConstants.STATE_WAITING
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, survivor, acts, survivor_id):
        _fail(failures, "sparse_full_pick: want fight_finish_tail")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(mgr, survivor, acts, survivor_id):
        _fail(failures, "sparse_full_pick: want sparse_prefer_finish")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, survivor, acts):
        _fail(failures, "sparse_full_pick: want rotate_suppress")
        HarnessFixtures._free_manager(mgr)
        return
    var picked: Dictionary = CombatAIActionPicker.pick(acts, survivor_id, mgr)
    if picked.is_empty():
        _fail(failures, "sparse_full_pick: expected pick")
        HarnessFixtures._free_manager(mgr)
        return
    var mid: String = str(picked.get("move_id", ""))
    if (
        mid == CombatConstants.MOVE_ID_WAIT
        or mid == CombatConstants.MOVE_ID_ROTATE_FILE
        or mid == CombatConstants.MOVE_ID_SWAP_RANK
        or CombatConstants.is_focus_line_move(mid)
    ):
        _fail(failures, "sparse_full_pick: want offense pick got %s" % mid)
        HarnessFixtures._free_manager(mgr)
        return
    if CombatConstants.is_feature_mental_stack_ai_enabled():
        var layer: String = str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
            _fail(failures, "sparse_full_pick: want sparse_fight layer got %s" % layer)
            HarnessFixtures._free_manager(mgr)
            return
    if CombatEngagementDiagnostics.line_plug_logged_for_pick(mgr, survivor, survivor_id, acts, picked):
        _fail(failures, "sparse_full_pick: want line_plug=false on sparse offense pick")
    HarnessFixtures._free_manager(mgr)


## Reserve-only fight-finish: hold-line gauge hint steers to finish, not shuffle.


## Reserve-only fight-finish: hold-line gauge hint steers to finish, not shuffle.
static func _run_fight_finish_hold_line_focus_hint(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "fight_finish_hold_hint: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if survivor.is_empty():
        _fail(failures, "fight_finish_hold_hint: missing survivor")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not CombatListedActions.action_list_is_reserve_posture_only(acts):
        HarnessFixtures._free_manager(mgr)
        return
    var hint: String = CombatPlayerTurnHints.hold_line_focus_only_hint(mgr, survivor, acts)
    if "close in or strike" not in hint:
        _fail(failures, "fight_finish_hold_hint: want finish copy got %s" % hint)
    HarnessFixtures._free_manager(mgr)


## Fight-finish rank-0: utility swap_rank weight zero when offense is listed.


## Fight-finish rank-0: utility swap_rank weight zero when offense is listed.
static func _run_fight_finish_rank0_swap_weight_zero(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var partner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if player.is_empty() or partner.is_empty():
        _fail(failures, "fight_finish_swap_weight: missing fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    player["gauge"] = 100.0
    var player_id: int = CombatantEntityAccess.id_int(player)
    var partner_id: int = CombatantEntityAccess.id_int(partner)
    var acts: Array = AvailableActionsBuilder.build(mgr, player_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, player, acts, player_id):
        _fail(failures, "fight_finish_swap_weight: want fight_finish_tail")
        HarnessFixtures._free_manager(mgr)
        return
    var swap_act: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_SWAP_RANK,
        "target_id": partner_id,
    }
    var w_swap: float = CombatAIActionPicker._get_action_weight(swap_act, player_id, mgr, true, {}, {}, acts)
    if w_swap > 0.001:
        _fail(failures, "fight_finish_swap_weight: want 0 swap weight on rank-0 mop-up got %.3f" % w_swap)
    HarnessFixtures._free_manager(mgr)


## Half-or-fewer rank-0 occupancy with holes is sparse; one-kill wide line is not.


## Half-or-fewer rank-0 occupancy with holes is sparse; one-kill wide line is not.
static func _run_skirmish_line_sparse_threshold(failures: PackedStringArray) -> void:
    var mgr_sparse: Node = CombatManager.new()
    for _i in 6:
        mgr_sparse.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr_sparse.register(_new_entity("SWORD"), "enemy")
    mgr_sparse.start({"files": 6, "ranks": 1}, {"files": 3, "ranks": 1})
    var slots_sparse: Dictionary = FormationSlots.formation_slots_dict(mgr_sparse.formations["player"])
    for file in [0, 1, 2]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr_sparse, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_threshold: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr_sparse)
            return
        FormationSlots.remove_combatant_from_slots(slots_sparse, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr_sparse, "player"):
        _fail(failures, "sparse_threshold: want sparse at 3/6 rank-0 occupancy with holes")
    HarnessFixtures._free_manager(mgr_sparse)
    var mgr_dense: Node = CombatManager.new()
    for _i in 5:
        mgr_dense.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr_dense.register(_new_entity("SWORD"), "enemy")
    mgr_dense.start({"files": 5, "ranks": 1}, {"files": 3, "ranks": 1})
    var hole: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr_dense, "player", 0, 4)
    if hole.is_empty():
        _fail(failures, "sparse_threshold: missing one-kill hole fixture")
        HarnessFixtures._free_manager(mgr_dense)
        return
    hole["alive"] = false
    var slots_dense: Dictionary = FormationSlots.formation_slots_dict(mgr_dense.formations["player"])
    FormationSlots.prune_dead_ids_from_formation_slots(mgr_dense, slots_dense)
    if CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr_dense, "player"):
        _fail(failures, "sparse_threshold: one-kill 4/5 line should not count as sparse")
    HarnessFixtures._free_manager(mgr_dense)


## Post-flee sparse front: player hint steers to fight, not adjacent rotate shuffle.


## Post-flee sparse front: player hint steers to fight, not adjacent rotate shuffle.
static func _run_sparse_skirmish_line_fight_hint(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_fight_hint: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if survivor.is_empty():
        _fail(failures, "sparse_fight_hint: missing survivor")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    var hint: String = CombatPlayerTurnHints.skirmish_line_gap_rotate_hint(mgr, survivor, acts)
    if "close or strike" not in hint:
        _fail(failures, "sparse_fight_hint: want fight-first copy got %s" % hint)
    if "rotate with an adjacent" in hint:
        _fail(failures, "sparse_fight_hint: rotate shuffle copy should not show on sparse line")
    if CombatListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        var hold_hint: String = CombatPlayerTurnHints.hold_line_focus_only_hint(mgr, survivor, acts)
        if "close in or strike" not in hold_hint:
            _fail(failures, "sparse_fight_hint: strikes_listed want hold-line finish copy got %s" % hold_hint)
        CombatPlayerTurnHints.sync_hold_line_focus_only_hint_on_combatant(mgr, survivor, acts)
        if str(survivor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).is_empty():
            _fail(failures, "sparse_fight_hint: want hold-line stamp on combatant dict")
    HarnessFixtures._free_manager(mgr)


## Mop-up + sparse post-flee: fight-finish hint steers to offense, not rotate shuffle.


## Mop-up + sparse post-flee: fight-finish hint steers to offense, not rotate shuffle.
static func _run_mop_up_sparse_fight_finish_hint(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3, 4]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "mop_up_sparse_hint: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 6)
    if survivor.is_empty():
        for c in mgr.combatants:
            if CombatantEntityAccess.is_living_on_side(c, "player") and CombatantEntityAccess.rank_int(c) == 0:
                survivor = c
                break
    if survivor.is_empty():
        _fail(failures, "mop_up_sparse_hint: missing survivor")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _fail(failures, "mop_up_sparse_hint: want mop-up active after flee attrition")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, survivor, acts, survivor_id):
        _fail(failures, "mop_up_sparse_hint: want fight_finish_tail on survivor")
        HarnessFixtures._free_manager(mgr)
        return
    var hint: String = CombatPlayerTurnHints.skirmish_line_gap_rotate_hint(mgr, survivor, acts)
    if "close or strike" not in hint:
        _fail(failures, "mop_up_sparse_hint: want fight-first copy got %s" % hint)
    if "rotate with an adjacent" in hint:
        _fail(failures, "mop_up_sparse_hint: rotate shuffle copy should not show during fight-finish")
    HarnessFixtures._free_manager(mgr)


## Sparse post-flee rank-0 survivors: mental-stack close pick eligible (L4 hold-line path).


## Sparse post-flee rank-0 survivors: mental-stack close pick eligible (L4 hold-line path).
static func _run_sparse_line_hold_close_pick_eligible(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_close_eligible: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if survivor.is_empty():
        _fail(failures, "sparse_close_eligible: missing survivor")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDoctrine.hold_line_close_pick_eligible(mgr, survivor):
        _fail(failures, "sparse_close_eligible: want hold_line close eligible on sparse rank-0 survivor")
    HarnessFixtures._free_manager(mgr)


## Sparse post-flee: listed melee should outweigh focus shuffle when engagement is listed.


## Sparse post-flee: listed melee should outweigh focus shuffle when engagement is listed.
static func _run_sparse_line_offense_weight_beats_focus(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_offense_weight: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if survivor.is_empty():
        _fail(failures, "sparse_offense_weight: missing survivor")
        HarnessFixtures._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    var offense_act: Dictionary = {}
    var focus_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if CombatConstants.is_focus_line_move(mid):
            if focus_act.is_empty():
                focus_act = a
            continue
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            if offense_act.is_empty():
                offense_act = a
            continue
        if (
            mid == CombatConstants.MOVE_ID_WAIT
            or CombatConstants.is_formation_movement_move(mid)
            or CombatConstants.is_medical_move(mid)
        ):
            continue
        if int(a.get("target_id", -1)) < 0:
            continue
        if offense_act.is_empty():
            offense_act = a
    if offense_act.is_empty() or focus_act.is_empty():
        _fail(
            failures,
            (
                "sparse_offense_weight: want listed offense and focus (offense=%s focus=%s)"
                % [not offense_act.is_empty(), not focus_act.is_empty()]
            )
        )
        HarnessFixtures._free_manager(mgr)
        return
    var w_offense: float = CombatAIActionPicker._get_action_weight(offense_act, survivor_id, mgr, true, {}, {}, acts)
    var w_focus: float = CombatAIActionPicker._get_action_weight(focus_act, survivor_id, mgr, true, {}, {}, acts)
    if w_offense <= w_focus:
        _fail(
            failures, "sparse_offense_weight: want offense > focus got offense=%.3f focus=%.3f" % [w_offense, w_focus]
        )
    HarnessFixtures._free_manager(mgr)


## Post-flee sparse line: low-standing attrition damp must not weaken finish offense.


## Post-flee sparse line: low-standing attrition damp must not weaken finish offense.
static func _run_sparse_line_attrition_offense_exempt(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _fail(failures, "sparse_attrition: missing flee fixture file %d" % file)
            HarnessFixtures._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if survivor.is_empty():
        _fail(failures, "sparse_attrition: missing survivor")
        HarnessFixtures._free_manager(mgr)
        return
    var mult: float = CombatAIActionPicker._attrition_offense_weight_mult(mgr, survivor)
    if absf(mult - 1.0) > 0.001:
        _fail(failures, "sparse_attrition: want 1.0 offense mult on sparse line got %.3f" % mult)
    HarnessFixtures._free_manager(mgr)


## Mop-up underdog: last enemy must not get low-standing attrition damp on offense.


## Mop-up underdog: last enemy must not get low-standing attrition damp on offense.
static func _run_mop_up_underdog_attrition_offense_exempt(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if enemy.is_empty():
        _fail(failures, "mop_up_underdog_attrition: missing last enemy")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDoctrine.mop_up_underdog_active(mgr, enemy):
        _fail(failures, "mop_up_underdog_attrition: want underdog active on last enemy")
    var mult: float = CombatAIActionPicker._attrition_offense_weight_mult(mgr, enemy)
    if absf(mult - 1.0) > 0.001:
        _fail(failures, "mop_up_underdog_attrition: want 1.0 offense mult on underdog got %.3f" % mult)
    HarnessFixtures._free_manager(mgr)


## Mop-up underdog: last enemy mental stack picks offense, not wait shuffle.


## Mop-up underdog: last enemy mental stack picks offense, not wait shuffle.
static func _run_mop_up_underdog_mental_stack_picks_offense(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if enemy.is_empty():
        _fail(failures, "mop_up_underdog_stack: missing last enemy")
        HarnessFixtures._free_manager(mgr)
        return
    enemy["gauge"] = 100.0
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var acts: Array = AvailableActionsBuilder.build(mgr, enemy_id)
    if not CombatListedActions.action_list_has_hostile_strike(acts, enemy_id):
        _fail(failures, "mop_up_underdog_stack: want hostile strike or close listed for last enemy")
        HarnessFixtures._free_manager(mgr)
        return
    var picked: Dictionary = MentalStackDecider.try_pick(acts, enemy_id, mgr)
    if picked.is_empty():
        _fail(failures, "mop_up_underdog_stack: expected mental-stack pick")
        HarnessFixtures._free_manager(mgr)
        return
    var mid: String = str(picked.get("move_id", ""))
    if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
        _fail(failures, "mop_up_underdog_stack: want offense pick got %s" % mid)
    var layer: String = str(enemy.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
        _fail(failures, "mop_up_underdog_stack: want sparse_fight layer got %s" % layer)
    HarnessFixtures._free_manager(mgr)


## Mop-up winner: wait damped below listed offense when finishing last enemy.


## Mop-up winner: wait damped below listed offense when finishing last enemy.
static func _run_mop_up_finish_wait_below_offense_weight(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if player.is_empty():
        _fail(failures, "mop_up_wait_weight: missing player fixture")
        HarnessFixtures._free_manager(mgr)
        return
    player["gauge"] = 100.0
    var player_id: int = CombatantEntityAccess.id_int(player)
    var acts: Array = AvailableActionsBuilder.build(mgr, player_id)
    var offense_act: Dictionary = {}
    var wait_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_WAIT:
            wait_act = a
            continue
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            if offense_act.is_empty():
                offense_act = a
            continue
        if CombatConstants.is_focus_line_move(mid) or CombatConstants.is_formation_movement_move(mid):
            continue
        if int(a.get("target_id", -1)) < 0:
            continue
        if offense_act.is_empty():
            offense_act = a
    if offense_act.is_empty():
        _fail(failures, "mop_up_wait_weight: want listed offense action")
        HarnessFixtures._free_manager(mgr)
        return
    var w_offense: float = CombatAIActionPicker._get_action_weight(offense_act, player_id, mgr, true, {}, {}, acts)
    var w_wait: float = CombatAIActionPicker._get_action_weight(wait_act, player_id, mgr, true, {}, {}, acts)
    if w_offense <= w_wait:
        _fail(failures, "mop_up_wait_weight: want offense > wait got offense=%.3f wait=%.3f" % [w_offense, w_wait])
    HarnessFixtures._free_manager(mgr)

## Post-flee sparse: wait damped below listed offense when finishing on a sparse front.
