class_name Tier1EnvelopFightFinishTests
extends CombatRegressionHarnessCore
## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_sparse_finish_wait_below_offense_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            CombatRegressionHarness._fail(failures, "sparse_wait_weight: missing flee fixture file %d" % file)
            CombatRegressionHarness._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if survivor.is_empty():
        CombatRegressionHarness._fail(failures, "sparse_wait_weight: missing survivor")
        CombatRegressionHarness._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    var offense_act: Dictionary = {}
    var wait_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": survivor_id}
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
        CombatRegressionHarness._fail(failures, "sparse_wait_weight: want listed offense action")
        CombatRegressionHarness._free_manager(mgr)
        return
    var w_offense: float = CombatAIActionPicker._get_action_weight(offense_act, survivor_id, mgr, true, {}, {}, acts)
    var w_wait: float = CombatAIActionPicker._get_action_weight(wait_act, survivor_id, mgr, true, {}, {}, acts)
    if w_offense <= w_wait:
        CombatRegressionHarness._fail(
            failures, "sparse_wait_weight: want offense > wait got offense=%.3f wait=%.3f" % [w_offense, w_wait]
        )
    CombatRegressionHarness._free_manager(mgr)


## MS-L7: rank-0 with listed strikes must not exhaustion-pick rotate_file (fight-first over shuffle).


## MS-L7: rank-0 with listed strikes must not exhaustion-pick rotate_file (fight-first over shuffle).
static func _run_exhaustion_rank0_strikes_blocks_rotate_file(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    fighter["stamina"] = 0.01 * float(fighter.get(CombatConstants.STAMINA_MAX, 100.0))
    if CombatantEntityAccess.stamina_ratio(fighter) >= CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO:
        CombatRegressionHarness._fail(failures, "exhaustion_rank0_rotate: stamina should be critical")
        CombatRegressionHarness._free_manager(mgr)
        return
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "exhaustion_rank0_rotate: expected stack pick")
        CombatRegressionHarness._free_manager(mgr)
        return
    if str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_ROTATE_FILE:
        CombatRegressionHarness._fail(
            failures, "exhaustion_rank0_rotate: rotate_file must not win when strikes are listed on rank 0"
        )
    if (
        str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "exhaustion_rank0_rotate: want exhaustion layer got %s"
                % str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Fight-finish tail: trust menu-listed close when pair gate fails at pick time (underdog mop-up).


## Fight-finish tail: trust menu-listed close when pair gate fails at pick time (underdog mop-up).
static func _run_fight_finish_trust_menu_close_underdog(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var enemy: Dictionary = {}
    var player: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
        elif (
            CombatantEntityAccess.is_living_on_side(c, "player")
            and CombatantEntityAccess.rank_int(c) == 0
            and player.is_empty()
        ):
            player = c
    if enemy.is_empty() or player.is_empty():
        CombatRegressionHarness._fail(failures, "fight_finish_trust_close: missing underdog enemy or player fixture")
        CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatDoctrine.mop_up_underdog_active(mgr, enemy):
        CombatRegressionHarness._fail(failures, "fight_finish_trust_close: want mop-up underdog on last enemy")
        CombatRegressionHarness._free_manager(mgr)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var player_id: int = CombatantEntityAccess.id_int(player)
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    (enemy["distance_to"] as Dictionary)[player_id] = CombatConstants.DISTANCE_LONG
    if typeof(enemy.get("close_block_until_by_target_id", null)) != TYPE_DICTIONARY:
        enemy["close_block_until_by_target_id"] = {}
    (enemy["close_block_until_by_target_id"] as Dictionary)[player_id] = 999999.0
    if CombatMeleeListing.attempt_close_listed_for_pair(mgr, enemy, player_id, CombatConstants.DISTANCE_LONG):
        CombatRegressionHarness._fail(failures, "fight_finish_trust_close: want pair gate blocked at pick time")
        CombatRegressionHarness._free_manager(mgr)
        return
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": enemy_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": player_id},
    ]
    if not CombatDoctrine.fight_finish_tail_active(mgr, enemy, acts, enemy_id):
        CombatRegressionHarness._fail(
            failures, "fight_finish_trust_close: want fight_finish_tail_active on underdog menu"
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var picked: Dictionary = MentalStackDecider.try_pick(acts, enemy_id, mgr)
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        CombatRegressionHarness._fail(
            failures, "fight_finish_trust_close: want attempt_close pick got %s" % str(picked.get("move_id", ""))
        )
    var close_w: float = CombatAIActionPicker._get_action_weight(acts[1], enemy_id, mgr, true, {}, {}, acts)
    if close_w < CombatConstants.AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT - 0.001:
        CombatRegressionHarness._fail(
            failures, "fight_finish_trust_close: want trusted close weight got %.3f" % close_w
        )
    CombatRegressionHarness._free_manager(mgr)


## Fight-finish: hold-line close filter trusts menu-listed close when pair gate fails at pick time.


## Fight-finish: hold-line close filter trusts menu-listed close when pair gate fails at pick time.
static func _run_fight_finish_close_filter_trusts_menu(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var enemy: Dictionary = {}
    var player: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
        elif (
            CombatantEntityAccess.is_living_on_side(c, "player")
            and CombatantEntityAccess.rank_int(c) == 0
            and player.is_empty()
        ):
            player = c
    if enemy.is_empty() or player.is_empty():
        CombatRegressionHarness._fail(failures, "fight_finish_close_filter: missing underdog enemy or player fixture")
        CombatRegressionHarness._free_manager(mgr)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var player_id: int = CombatantEntityAccess.id_int(player)
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    (enemy["distance_to"] as Dictionary)[player_id] = CombatConstants.DISTANCE_LONG
    if typeof(enemy.get("close_block_until_by_target_id", null)) != TYPE_DICTIONARY:
        enemy["close_block_until_by_target_id"] = {}
    (enemy["close_block_until_by_target_id"] as Dictionary)[player_id] = 999999.0
    if CombatMeleeListing.attempt_close_listed_for_pair(mgr, enemy, player_id, CombatConstants.DISTANCE_LONG):
        CombatRegressionHarness._fail(failures, "fight_finish_close_filter: want pair gate blocked at pick time")
        CombatRegressionHarness._free_manager(mgr)
        return
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": enemy_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": player_id},
    ]
    if not CombatDoctrine.fight_finish_tail_active(mgr, enemy, acts, enemy_id):
        CombatRegressionHarness._fail(
            failures, "fight_finish_close_filter: want fight_finish_tail_active on underdog menu"
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var close_pool: Array = MentalStackDecider._filter_hold_line_close_actions(acts, enemy_id, mgr, enemy)
    if (
        CombatListedActions
        . first_action_move_vs_target(close_pool, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, player_id)
        . is_empty()
    ):
        CombatRegressionHarness._fail(failures, "fight_finish_close_filter: want attempt_close in trusted close pool")
    CombatRegressionHarness._free_manager(mgr)


## Fight-finish tail: critical stamina must not exhaustion-layer wait when offense is listed.


## Fight-finish tail: critical stamina must not exhaustion-layer wait when offense is listed.
static func _run_fight_finish_skips_exhaustion_with_listed_offense(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if player.is_empty():
        CombatRegressionHarness._fail(failures, "fight_finish_skip_exhaustion: missing rank-0 player fixture")
        CombatRegressionHarness._free_manager(mgr)
        return
    player["stamina"] = 0.01 * float(player.get(CombatConstants.STAMINA_MAX, 100.0))
    player["gauge"] = 100.0
    var player_id: int = CombatantEntityAccess.id_int(player)
    var acts: Array = AvailableActionsBuilder.build(mgr, player_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, player, acts, player_id):
        CombatRegressionHarness._fail(failures, "fight_finish_skip_exhaustion: want fight_finish_tail on mop-up player")
        CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatListedActions.action_list_has_hostile_strike(acts, player_id):
        CombatRegressionHarness._fail(failures, "fight_finish_skip_exhaustion: want listed offense")
        CombatRegressionHarness._free_manager(mgr)
        return
    var picked: Dictionary = MentalStackDecider.try_pick(acts, player_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._free_manager(mgr)
        return
    var layer: String = str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if layer == CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION:
        CombatRegressionHarness._fail(
            failures, "fight_finish_skip_exhaustion: exhaustion layer must not fire on fight-finish tail"
        )
    if (
        (
            str(picked.get("move_id", ""))
            in [
                CombatConstants.MOVE_ID_WAIT,
                CombatConstants.MOVE_ID_ROTATE_FILE,
                CombatConstants.MOVE_ID_SWAP_RANK,
            ]
        )
        or CombatConstants.is_focus_line_move(str(picked.get("move_id", "")))
    ):
        CombatRegressionHarness._fail(
            failures,
            "fight_finish_skip_exhaustion: want offense pick got %s layer=%s" % [str(picked.get("move_id", "")), layer]
        )
    CombatRegressionHarness._free_manager(mgr)


## Fight-finish tail: utility focus weight below listed melee when finishing.


## Fight-finish tail: utility focus weight below listed melee when finishing.
static func _run_fight_finish_focus_damped_below_offense(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if enemy.is_empty():
        CombatRegressionHarness._fail(failures, "fight_finish_focus_damp: missing last enemy")
        CombatRegressionHarness._free_manager(mgr)
        return
    enemy["gauge"] = 100.0
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var acts: Array = AvailableActionsBuilder.build(mgr, enemy_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, enemy, acts, enemy_id):
        CombatRegressionHarness._fail(failures, "fight_finish_focus_damp: want fight_finish_tail on underdog")
        CombatRegressionHarness._free_manager(mgr)
        return
    var offense_act: Dictionary = {}
    var focus_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if CombatConstants.is_focus_line_move(mid) and focus_act.is_empty():
            focus_act = a
            continue
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            if offense_act.is_empty():
                offense_act = a
            continue
        if (
            mid in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS
            or mid == CombatConstants.MOVE_ID_WAIT
            or CombatConstants.is_focus_line_move(mid)
        ):
            continue
        if int(a.get("target_id", -1)) < 0:
            continue
        if offense_act.is_empty():
            offense_act = a
    if offense_act.is_empty() or focus_act.is_empty():
        CombatRegressionHarness._free_manager(mgr)
        return
    var w_offense: float = CombatAIActionPicker._get_action_weight(offense_act, enemy_id, mgr, true, {}, {}, acts)
    var w_focus: float = CombatAIActionPicker._get_action_weight(focus_act, enemy_id, mgr, true, {}, {}, acts)
    if w_offense <= w_focus:
        CombatRegressionHarness._fail(
            failures, "fight_finish_focus_damp: want offense > focus got offense=%.3f focus=%.3f" % [w_offense, w_focus]
        )
    CombatRegressionHarness._free_manager(mgr)


## MS-L7: rank-0 with listed strikes must not exhaustion-pick focus shuffle.


## MS-L7: rank-0 with listed strikes must not exhaustion-pick focus shuffle.
static func _run_exhaustion_rank0_strikes_blocks_focus_line(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    fighter["stamina"] = 0.01 * float(fighter.get(CombatConstants.STAMINA_MAX, 100.0))
    if CombatantEntityAccess.stamina_ratio(fighter) >= CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO:
        CombatRegressionHarness._fail(failures, "exhaustion_rank0_focus: stamina should be critical")
        CombatRegressionHarness._free_manager(mgr)
        return
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_LEFT, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "exhaustion_rank0_focus: expected stack pick")
        CombatRegressionHarness._free_manager(mgr)
        return
    if CombatConstants.is_focus_line_move(str(picked.get("move_id", ""))):
        CombatRegressionHarness._fail(
            failures, "exhaustion_rank0_focus: focus must not win when strikes are listed on rank 0"
        )
    if (
        str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "exhaustion_rank0_focus: want exhaustion layer got %s"
                % str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Mop-up rank-0: L4b sparse_fight beats L5 exhaustion when finishing with listed strikes.


## Mop-up rank-0: L4b sparse_fight beats L5 exhaustion when finishing with listed strikes.
static func _run_mop_up_rank0_exhaustion_prefers_fight_finish(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if player.is_empty():
        CombatRegressionHarness._fail(failures, "mop_up_rank0_exhaustion: missing rank-0 player")
        CombatRegressionHarness._free_manager(mgr)
        return
    player["stamina"] = 0.01 * float(player.get(CombatConstants.STAMINA_MAX, 100.0))
    player["gauge"] = 100.0
    var player_id: int = CombatantEntityAccess.id_int(player)
    var acts: Array = AvailableActionsBuilder.build(mgr, player_id)
    if not CombatListedActions.action_list_has_hostile_strike(acts, player_id):
        CombatRegressionHarness._fail(failures, "mop_up_rank0_exhaustion: want listed strikes")
        CombatRegressionHarness._free_manager(mgr)
        return
    var reserve_only: bool = CombatListedActions.action_list_is_reserve_posture_only(acts)
    var picked: Dictionary = MentalStackDecider.try_pick(acts, player_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mop_up_rank0_exhaustion: expected mental-stack pick")
        CombatRegressionHarness._free_manager(mgr)
        return
    var mid: String = str(picked.get("move_id", ""))
    var layer: String = str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if reserve_only:
        if (
            layer
            not in [
                CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
                CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT,
            ]
        ):
            CombatRegressionHarness._fail(
                failures, "mop_up_rank0_exhaustion: reserve_only want hold_line or sparse_fight got %s" % layer
            )
        if mid != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            CombatRegressionHarness._fail(
                failures, "mop_up_rank0_exhaustion: reserve_only want attempt_close got %s" % mid
            )
    else:
        if (
            mid
            in [
                CombatConstants.MOVE_ID_WAIT,
                CombatConstants.MOVE_ID_ROTATE_FILE,
                CombatConstants.MOVE_ID_SWAP_RANK,
            ]
        ):
            CombatRegressionHarness._fail(failures, "mop_up_rank0_exhaustion: want offense pick got %s" % mid)
        if layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
            CombatRegressionHarness._fail(failures, "mop_up_rank0_exhaustion: want sparse_fight layer got %s" % layer)
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: fled allies do not count toward mop-up standing advantage.


## III-4 **3e**: fled allies do not count toward mop-up standing advantage.
static func _run_envelop_mop_up_excludes_fled_allies(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var fled_count: int = 0
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c) or not CombatantEntityAccess.is_standing_combatant(c):
            continue
        if fled_count >= 3:
            break
        c[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        c["state"] = CombatConstants.STATE_FLED
        fled_count += 1
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        CombatRegressionHarness._fail(
            failures, "envelop_mop_up_fled: want active with 4 standing vs 1 enemy got inactive"
        )
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: fled enemies are not living hostiles (listing / opposition / close slots).


## III-4 **3e**: fled enemies are not living hostiles (listing / opposition / close slots).
static func _run_living_hostile_excludes_fled_enemy(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    enemy[DataKeys.COMBATANT_COMBAT_ABSENT] = true
    enemy["state"] = CombatConstants.STATE_FLED
    if CombatantEntityAccess.is_living_hostile_to(player, enemy):
        CombatRegressionHarness._fail(failures, "living_hostile_fled: fled enemy must not be hostile target")
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: flee purges stale **`distance_to`** / melee ordering (no ghost `e9:close` after rout).


## III-4 **3e**: flee purges stale **`distance_to`** / melee ordering (no ghost `e9:close` after rout).
static func _run_fled_enemy_distance_to_purged_after_recompute(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var fled: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy") and CombatantEntityAccess.file_int(c) == 2:
            fled = c
            break
    var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if fled.is_empty() or player.is_empty():
        CombatRegressionHarness._fail(failures, "fled_distance_to: missing fled enemy or player fixture")
        CombatRegressionHarness._free_manager(mgr)
        return
    var fled_id: int = CombatantEntityAccess.id_int(fled)
    CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")[fled_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
    fled["state"] = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var d_to: Dictionary = CombatantEntityAccess.nested_dictionary_read(player, "distance_to")
    if d_to.has(fled_id):
        CombatRegressionHarness._fail(
            failures, "fled_distance_to: want fled id purged from distance_to after recompute"
        )
    var ordered: Array = CombatTargetScoring.ordered_melee_opponents(mgr, player, mgr.combatants, 0)
    for opp in ordered:
        if CombatantEntityAccess.id_int(opp) == fled_id:
            CombatRegressionHarness._fail(failures, "fled_distance_to: ordered_melee_opponents must exclude fled enemy")
    if ordered.is_empty():
        CombatRegressionHarness._fail(failures, "fled_distance_to: want living enemy targets after one flee")
    CombatDistanceBands.purge_stale_distance_to_entries(mgr)
    if CombatantEntityAccess.nested_dictionary_read(player, "distance_to").has(fled_id):
        CombatRegressionHarness._fail(
            failures, "fled_distance_to: purge_stale_distance_to_entries should be idempotent safe"
        )
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: incapacitated enemy purges stale **`distance_to`** after recompute (mop-up hygiene).


## III-4 **3e**: incapacitated enemy purges stale **`distance_to`** after recompute (mop-up hygiene).
static func _run_incap_enemy_distance_to_purged_after_recompute(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ent_enemy = CombatRegressionHarness._new_entity("SWORD")
    ent_enemy.consciousness = 5.0
    mgr.register(ent_enemy, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    if not CombatantEntityAccess.is_incapacitated(enemy):
        CombatRegressionHarness._fail(failures, "incap_distance_to: enemy should be incapacitated for fixture")
        CombatRegressionHarness._free_manager(mgr)
        return
    var incap_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")[incap_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    mgr.recompute_zoc_and_distance()
    if CombatantEntityAccess.nested_dictionary_read(player, "distance_to").has(incap_id):
        CombatRegressionHarness._fail(
            failures, "incap_distance_to: want incap id purged from distance_to after recompute"
        )
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `CombatResolveAction` rejects `rotate_file` during mop-up when listing would suppress.


## III-4 **3e**: `CombatResolveAction` rejects `rotate_file` during mop-up when listing would suppress.
static func _run_envelop_resolve_rotate_rejected_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var wing: Dictionary = {}
    var partner: Dictionary = {}
    for file_i in range(7):
        var cand: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, file_i)
        if cand.is_empty():
            continue
        cand["gauge"] = 100.0
        var cand_id: int = CombatantEntityAccess.id_int(cand)
        var cand_acts: Array = AvailableActionsBuilder.build(mgr, cand_id)
        if not CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, cand, cand_acts):
            continue
        for delta in [-1, 1]:
            var adj: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
                mgr, "player", 0, file_i + delta
            )
            if adj.is_empty():
                continue
            adj["gauge"] = 100.0
            wing = cand
            partner = adj
            break
        if not wing.is_empty():
            break
    if wing.is_empty() or partner.is_empty():
        CombatRegressionHarness._fail(
            failures, "envelop_resolve_rotate: need rank-0 pair with mop-up rotate suppress on live menu"
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var wing_id: int = CombatantEntityAccess.id_int(wing)
    var partner_id: int = CombatantEntityAccess.id_int(partner)
    var committed: bool = CombatResolveAction.resolve(mgr, wing_id, partner_id, CombatConstants.MOVE_ID_ROTATE_FILE, {})
    if committed:
        CombatRegressionHarness._fail(failures, "envelop_resolve_rotate: must reject rotate_file during mop-up")
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: true 1v1 standing duel is not envelop mop-up (min standing advantage).


## III-4 **3e**: true 1v1 standing duel is not envelop mop-up (min standing advantage).
static func _run_envelop_mop_up_inactive_true_duel(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        CombatRegressionHarness._fail(failures, "envelop_mop_up_duel: 1v1 should not activate mop-up")
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `attempt_close` listed at CLOSE band during mop-up (band/reach gap).


## III-4 **3e**: `attempt_close` listed at CLOSE band during mop-up (band/reach gap).
static func _run_envelop_close_listed_close_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if player.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "envelop_close_close: missing player/enemy fixtures")
        CombatRegressionHarness._free_manager(mgr)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_CLOSE
    if not CombatMeleeListing.attempt_close_listed_for_pair(mgr, player, enemy_id, CombatConstants.DISTANCE_CLOSE):
        CombatRegressionHarness._fail(failures, "envelop_close_close: want attempt_close listed at CLOSE during mop-up")
    CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: mop-up lists melee at CLOSE when band/reach gap would otherwise close-only stall.


## III-4 **3e**: mop-up lists melee at CLOSE when band/reach gap would otherwise close-only stall.
static func _run_envelop_melee_strike_listed_close_mop_up_reach_gap(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "envelop_strike_close: missing center/enemy fixtures")
        CombatRegressionHarness._free_manager(mgr)
        return
    center["gauge"] = 100.0
    var c_id: int = CombatantEntityAccess.id_int(center)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    var dist_c: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
    dist_c[e_id] = CombatConstants.DISTANCE_CLOSE
    var dist_e: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")
    dist_e[c_id] = CombatConstants.DISTANCE_CLOSE
    var melee_range: float = CombatMeleeListing.melee_weapon_reach(center)
    var eff_dist: float = CombatPairGeometry.effective_pair_eff_dist(mgr, center, enemy)
    var reach_gap: bool = not CombatPairGeometry.melee_reach_covers_eff_dist(melee_range, eff_dist)
    if not CombatMeleeListing.can_melee_threaten(mgr, center, enemy):
        CombatRegressionHarness._fail(
            failures,
            (
                "envelop_strike_close: can_melee_threaten want true at CLOSE during mop-up (reach_gap=%s)"
                % str(reach_gap).to_lower()
            )
        )
    var acts: Array = AvailableActionsBuilder.build(mgr, c_id)
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, c_id):
        CombatRegressionHarness._fail(
            failures,
            (
                "envelop_strike_close: want listed melee strike at CLOSE during mop-up (reach_gap=%s)"
                % str(reach_gap).to_lower()
            )
        )
    if CombatListedActions.action_list_is_reserve_posture_only(acts):
        CombatRegressionHarness._fail(
            failures, "envelop_strike_close: reserve_only menu must not hold when strikes listed"
        )
    var mgr_duel: Node = CombatManager.new()
    for _i in 2:
        mgr_duel.register(CombatRegressionHarness._new_entity("SWORD"), "player")
        mgr_duel.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_duel.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    var p0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr_duel, "player", 0, 0)
    var e0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr_duel, "enemy", 0, 0)
    if not p0.is_empty() and not e0.is_empty():
        var p_id: int = CombatantEntityAccess.id_int(p0)
        var e0_id: int = CombatantEntityAccess.id_int(e0)
        CombatantEntityAccess.nested_dictionary_for_mutation(p0, "distance_to")[e0_id] = CombatConstants.DISTANCE_CLOSE
        CombatantEntityAccess.nested_dictionary_for_mutation(e0, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
        var eff_duel: float = CombatPairGeometry.effective_pair_eff_dist(mgr_duel, p0, e0)
        if not CombatPairGeometry.melee_reach_covers_eff_dist(CombatMeleeListing.melee_weapon_reach(p0), eff_duel):
            if CombatMeleeListing.can_melee_threaten(mgr_duel, p0, e0):
                CombatRegressionHarness._fail(
                    failures, "envelop_strike_close: 1v1 must not bypass reach without mop-up"
                )
    CombatRegressionHarness._free_manager(mgr_duel)
    CombatRegressionHarness._free_manager(mgr)


static func _run_pincer_wing_commitment_propagates_from_center(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    if center.is_empty() or wing.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "pincer_propagate: missing center/wing/enemy fixtures")
        CombatRegressionHarness._free_manager(mgr)
        return
    if CombatDoctrine.pincer_role_for_combatant(mgr, center) != CombatDoctrine.PINCER_ROLE_CENTER:
        CombatRegressionHarness._fail(failures, "pincer_propagate: file-3 player want center role")
    if CombatDoctrine.pincer_role_for_combatant(mgr, wing) != CombatDoctrine.PINCER_ROLE_FLANK_WING:
        CombatRegressionHarness._fail(failures, "pincer_propagate: file-0 player want flank_wing role")
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var want_wing_tgt: int = CombatDoctrine.preferred_pincer_flank_enemy_id(mgr, wing)
    if want_wing_tgt < 0:
        CombatRegressionHarness._fail(failures, "pincer_propagate: wing should have preferred flank enemy")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.combat_clock = 0.0
    CombatTargetScoring.on_combat_commitment(mgr, center_id, enemy_id)
    var got_tgt: int = int(wing.get("doctrine_target_commit_id", -1))
    if got_tgt != want_wing_tgt:
        CombatRegressionHarness._fail(
            failures, "pincer_propagate: wing commit want %d got %d" % [want_wing_tgt, got_tgt]
        )
    CombatRegressionHarness._free_manager(mgr)


static func _run_pincer_preferred_flank_target_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var pref_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    var off_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 2)
    if wing.is_empty() or pref_enemy.is_empty() or off_enemy.is_empty():
        CombatRegressionHarness._fail(failures, "pincer_target_mult: missing wing/enemy fixtures")
        CombatRegressionHarness._free_manager(mgr)
        return
    var m_pref: float = CombatTargetScoring.pincer_preferred_flank_target_mult(mgr, wing, pref_enemy)
    var m_off: float = CombatTargetScoring.pincer_preferred_flank_target_mult(mgr, wing, off_enemy)
    if not is_equal_approx(m_pref, CombatConstants.DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "pincer_target_mult: preferred enemy want %.4f got %.4f"
                % [CombatConstants.DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT, m_pref]
            )
        )
    if not is_equal_approx(m_off, 1.0):
        CombatRegressionHarness._fail(failures, "pincer_target_mult: off-preference enemy want 1.0 got %.4f" % m_off)
    CombatRegressionHarness._free_manager(mgr)


## Pincer flank wing already at CLOSE must not list attempt_close (reserve-only close stall).


## Pincer flank wing already at CLOSE must not list attempt_close (reserve-only close stall).
static func _run_pincer_flank_omits_close_listing_at_close_band(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    if wing.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "pincer_close_band: missing wing/enemy fixtures")
        CombatRegressionHarness._free_manager(mgr)
        return
    if CombatDoctrine.pincer_role_for_combatant(mgr, wing) != CombatDoctrine.PINCER_ROLE_FLANK_WING:
        CombatRegressionHarness._fail(failures, "pincer_close_band: file-0 player want flank_wing role")
        CombatRegressionHarness._free_manager(mgr)
        return
    var wing_id: int = CombatantEntityAccess.id_int(wing)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(wing, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    if CombatDoctrine.envelop_close_allowed(mgr, wing, enemy_id):
        CombatRegressionHarness._fail(
            failures, "pincer_close_band: flank wing CLOSE must not envelop_close_allowed without mop-up"
        )
    if CombatMeleeListing.attempt_close_listed_for_pair(mgr, wing, enemy_id, CombatConstants.DISTANCE_CLOSE):
        CombatRegressionHarness._fail(
            failures, "pincer_close_band: flank wing CLOSE must not list attempt_close without mop-up"
        )
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": wing_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    var close_pool: Array = MentalStackDecider._filter_hold_line_close_actions(acts, wing_id, mgr, wing)
    if not (
        CombatListedActions
        . first_action_move_vs_target(close_pool, CombatConstants.MOVE_ID_ATTEMPT_CLOSE, enemy_id)
        . is_empty()
    ):
        CombatRegressionHarness._fail(
            failures, "pincer_close_band: hold_line close pool must omit CLOSE-band attempt_close without mop-up"
        )
    CombatantEntityAccess.nested_dictionary_for_mutation(wing, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_LONG
    )
    if not CombatMeleeListing.attempt_close_listed_for_pair(mgr, wing, enemy_id, CombatConstants.DISTANCE_LONG):
        CombatRegressionHarness._fail(failures, "pincer_close_band: flank wing LONG should still list attempt_close")
    CombatRegressionHarness._free_manager(mgr)


## Pincer flank wing: close-arc spread damp  -  preferred enemy gets 1.0, offset enemies scale down.


## Pincer flank wing: close-arc spread damp  -  preferred enemy gets 1.0, offset enemies scale down.
static func _run_pincer_close_arc_spread_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var pref_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    var mid_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 1)
    var off_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 2)
    if wing.is_empty() or pref_enemy.is_empty() or mid_enemy.is_empty() or off_enemy.is_empty():
        CombatRegressionHarness._fail(failures, "pincer_arc_spread: missing wing/enemy fixtures")
        CombatRegressionHarness._free_manager(mgr)
        return
    var m_pref: float = CombatDoctrine.pincer_close_arc_spread_mult(mgr, wing, pref_enemy)
    var m_mid: float = CombatDoctrine.pincer_close_arc_spread_mult(mgr, wing, mid_enemy)
    var m_off: float = CombatDoctrine.pincer_close_arc_spread_mult(mgr, wing, off_enemy)
    if not is_equal_approx(m_pref, 1.0):
        CombatRegressionHarness._fail(failures, "pincer_arc_spread: preferred enemy want 1.0 got %.4f" % m_pref)
    if m_mid >= m_pref:
        CombatRegressionHarness._fail(
            failures,
            "pincer_arc_spread: mid-file offset damp should be < preferred (got %.4f >= %.4f)" % [m_mid, m_pref]
        )
    if m_off >= m_mid:
        CombatRegressionHarness._fail(
            failures, "pincer_arc_spread: off-file offset damp should be < mid (got %.4f >= %.4f)" % [m_off, m_mid]
        )
    # Non-wing combatant gets 1.0 always.
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if not center.is_empty():
        var m_center: float = CombatDoctrine.pincer_close_arc_spread_mult(mgr, center, pref_enemy)
        if not is_equal_approx(m_center, 1.0):
            CombatRegressionHarness._fail(failures, "pincer_arc_spread: center role want 1.0 got %.4f" % m_center)
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.4: mirrored line -> same cohesion -> same `engagement_posture` (two-pass recompute + coupling neutral when
## equal).


## Tier 1.4: mirrored line -> same cohesion -> same `engagement_posture` (two-pass recompute + coupling neutral when
## equal).
static func _run_posture_mirror_symmetric(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 4:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
    var fp: String = str(mgr.formations["player"].get("engagement_posture", ""))
    var fe: String = str(mgr.formations["enemy"].get("engagement_posture", ""))
    if fp.is_empty() or fe.is_empty():
        CombatRegressionHarness._fail(failures, "posture_mirror: missing posture player=%s enemy=%s" % [fp, fe])
    elif fp != fe:
        CombatRegressionHarness._fail(
            failures, "posture_mirror: symmetric presets expected same posture got %s vs %s" % [fp, fe]
        )
    CombatFormationEngagement.recompute_all(mgr)
    fp = str(mgr.formations["player"].get("engagement_posture", ""))
    fe = str(mgr.formations["enemy"].get("engagement_posture", ""))
    if fp != fe:
        CombatRegressionHarness._fail(
            failures, "posture_mirror: after recompute_all expected same posture got %s vs %s" % [fp, fe]
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.5: encounter `morale_cohesion_*` lowers `line_cohesion` vs default factor 1.0.


## Tier 1.5: encounter `morale_cohesion_*` lowers `line_cohesion` vs default factor 1.0.
static func _run_morale_cohesion_affects_line_cohesion(failures: PackedStringArray) -> void:
    var m_base: Node = CombatManager.new()
    m_base.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m_base.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m_base.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var coh_base: float = float(m_base.formations["player"].get("line_cohesion", 1.0))
    var m_low: Node = CombatManager.new()
    m_low.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m_low.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m_low.encounter[CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER] = 0.35
    m_low.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var coh_low: float = float(m_low.formations["player"].get("line_cohesion", 1.0))
    if coh_low >= coh_base - 0.001:
        CombatRegressionHarness._fail(
            failures,
            (
                "morale_cohesion: expected lower player line_cohesion with low morale (base=%.4f low=%.4f)"
                % [coh_base, coh_low]
            )
        )
    var m_agg: Node = CombatManager.new()
    m_agg.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m_agg.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m_agg.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m_agg.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var coh_agg_hi: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
    m_agg.combatants[0]["morale_cohesion"] = 0.2
    m_agg.combatants[1]["morale_cohesion"] = 0.2
    CombatFormationEngagement.recompute_all(m_agg)
    var coh_agg_lo: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
    if coh_agg_lo >= coh_agg_hi - 0.001:
        CombatRegressionHarness._fail(
            failures,
            "morale_cohesion: combatant mean should drop cohesion (hi=%.4f lo=%.4f)" % [coh_agg_hi, coh_agg_lo]
        )
    CombatRegressionHarness._free_manager(m_base)
    CombatRegressionHarness._free_manager(m_low)
    CombatRegressionHarness._free_manager(m_agg)
