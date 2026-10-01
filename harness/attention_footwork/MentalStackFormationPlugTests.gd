class_name AttentionFootworkMentalStackFormationPlugTests

extends MentalStackFormationPlugBase

## Mental-stack formation-plug surface: close-vs-focus mop-up, swap-rank,
## incapacitated-forward, rotate-skirmish-hole, skipped fight-finish/mop-up
## offense, no-gap stack miss, sparse-line offense, sparse-fight layer stamp
## and the picker end-to-end path.


## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.
static func _run_mental_stack_close_beats_focus_mop_up_under_telegraph(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        HarnessFixtures._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        _fail(failures, "mental_stack_close_beats_focus_mop_up: missing center/enemy fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_LONG
    center["gauge"] = 100.0
    center["guard_line"] = "low"
    center[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    if not CombatAttention.is_being_wind_up_targeted(mgr, center_id):
        _fail(failures, "mental_stack_close_beats_focus_mop_up: setup want wind_up targeted")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, center_id, mgr)
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        _fail(
            failures,
            "mental_stack_close_beats_focus_mop_up: want attempt_close got %s" % str(picked.get("move_id", ""))
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up hold-line gauge hint when `attempt_close` is listed.

## III-4 **3e**: mop-up hold-line gauge hint when `attempt_close` is listed.


static func _run_mental_stack_formation_plug_swap_rank_over_strike(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _fail(failures, "mental_stack_plug_swap: missing hole/rear/front fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _fail(failures, "mental_stack_plug_swap: want rank-0 hole on line after kill")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _fail(failures, "mental_stack_plug_swap: want relief swap blocked for plug test")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var front_id: int = CombatantEntityAccess.id_int(front)
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        _fail(failures, "mental_stack_plug_swap: want swap_rank listed vs front partner")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if not ListedActions.action_list_has_hostile_strike(acts, rear_id):
        var enemy_id: int = -1
        for c in mgr.combatants:
            if CombatantEntityAccess.is_living_on_side(c, "enemy"):
                enemy_id = CombatantEntityAccess.id_int(c)
                break
        if enemy_id < 0:
            _fail(failures, "mental_stack_plug_swap: missing enemy for strike fixture")
            HarnessFixtures._free_manager_restore_global_rng(mgr)
            return
        acts.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
    var picked: Dictionary = MentalStack.try_pick(acts, rear_id, mgr)
    if picked.is_empty():
        _fail(failures, "mental_stack_plug_swap: expected stack pick")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        _fail(
            failures,
            (
                "mental_stack_plug_swap: want formation_plug got %s"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        _fail(failures, "mental_stack_plug_swap: want swap_rank got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: incapacitated front partner -> rear **`swap_rank`** stamps **`formation_plug`**.

## MS-L5: incapacitated front partner -> rear **`swap_rank`** stamps **`formation_plug`**.


static func _run_mental_stack_formation_plug_incap_forward(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if front.is_empty() or rear.is_empty():
        _fail(failures, "mental_stack_plug_incap: missing front/rear fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    HarnessFixtures._harness_destroy_limb(ent, "right_arm")
    HarnessFixtures._harness_destroy_limb(ent, "left_arm")
    front.state = CombatConstants.STATE_COWERING
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
    rear["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        _fail(failures, "mental_stack_plug_incap: want swap_rank listed over incap front")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, rear_id, mgr)
    if picked.is_empty():
        _fail(failures, "mental_stack_plug_incap: expected stack pick")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        _fail(
            failures,
            (
                "mental_stack_plug_incap: want formation_plug got %s"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        _fail(failures, "mental_stack_plug_incap: want swap_rank got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: Skirmish rank-0 hole -> front **`rotate_file`** when formation-only menu; stamps **`formation_plug`**.

## MS-L5: Skirmish rank-0 hole -> front **`rotate_file`** when formation-only menu; stamps **`formation_plug`**.


static func _run_mental_stack_formation_plug_rotate_skirmish_hole(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _fail(failures, "mental_stack_plug_rotate: expected skirmish mode")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rot_src: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rot_tgt: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        _fail(failures, "mental_stack_plug_rotate: missing hole/rotate fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_rank0_hole(mgr, "player"):
        _fail(failures, "mental_stack_plug_rotate: want rank-0 hole after kill")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var rot_src_id: int = CombatantEntityAccess.id_int(rot_src)
    var rot_tgt_id: int = CombatantEntityAccess.id_int(rot_tgt)
    rot_src["gauge"] = 100.0
    if not FormationMoves.rotate_file_action_legal(mgr, rot_src, rot_tgt):
        _fail(failures, "mental_stack_plug_rotate: want legal rotate_file vs adjacent file")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    # Rotate plug path matches utility weight: formation-only menu (no listed strikes).
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rot_src_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": rot_tgt_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(acts, rot_src_id, mgr)
    if picked.is_empty():
        _fail(failures, "mental_stack_plug_rotate: expected stack pick")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if (
        str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        _fail(
            failures,
            (
                "mental_stack_plug_rotate: want formation_plug got %s"
                % str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ROTATE_FILE:
        _fail(failures, "mental_stack_plug_rotate: want rotate_file got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: fight-finish tail with listed offense must not stamp **`formation_plug`**.

## MS-L5: fight-finish tail with listed offense must not stamp **`formation_plug`**.


static func _run_mental_stack_formation_plug_skipped_fight_finish(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        HarnessFixtures._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _fail(failures, "mental_stack_plug_skip_ff: want envelop_mop_up_active")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if center.is_empty():
        _fail(failures, "mental_stack_plug_skip_ff: missing center fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    center["gauge"] = 100.0
    var center_id: int = CombatantEntityAccess.id_int(center)
    var acts: Array = AvailableActionsBuilder.build(mgr, center_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, center, acts, center_id):
        _fail(failures, "mental_stack_plug_skip_ff: want fight_finish_tail")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if not ListedActions.action_list_has_hostile_strike(acts, center_id):
        _fail(failures, "mental_stack_plug_skip_ff: want listed offense")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, center_id, mgr)
    if (
        str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        _fail(failures, "mental_stack_plug_skip_ff: formation_plug must not fire on fight-finish tail")
    if picked.is_empty():
        _fail(failures, "mental_stack_plug_skip_ff: expected stack pick on fight-finish")
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
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "mental_stack_plug_skip_ff: want offense pick got %s layer=%s"
                    % [
                        str(picked.get("move_id", "")),
                        str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
                    ]
                )
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: envelop mop-up + listed strikes defers plug (rear rank with hole still finishes).

## MS-L5: envelop mop-up + listed strikes defers plug (rear rank with hole still finishes).


static func _run_mental_stack_formation_plug_skipped_mop_up_offense(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 10:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(4, enemy_ids.size())):
        HarnessFixtures._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _fail(failures, "mental_stack_plug_skip_mop: want envelop_mop_up_active")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _fail(failures, "mental_stack_plug_skip_mop: missing hole/rear/front fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _fail(failures, "mental_stack_plug_skip_mop: want relief swap blocked")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _fail(failures, "mental_stack_plug_skip_mop: want rank-0 hole on line after kill")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    rear["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.action_list_has_hostile_strike(acts, rear_id):
        var enemy_id: int = -1
        for c in mgr.combatants:
            if CombatantEntityAccess.is_living_on_side(c, "enemy"):
                enemy_id = CombatantEntityAccess.id_int(c)
                break
        if enemy_id < 0:
            _fail(failures, "mental_stack_plug_skip_mop: missing living enemy")
            HarnessFixtures._free_manager_restore_global_rng(mgr)
            return
        acts.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
    var front_id: int = CombatantEntityAccess.id_int(front)
    if not ListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        if not FormationMoves.swap_rank_action_legal(mgr, rear, front):
            _fail(failures, "mental_stack_plug_skip_mop: want legal swap_rank for plug-defer fixture")
            HarnessFixtures._free_manager_restore_global_rng(mgr)
            return
        acts.append({"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": front_id})
    if not FormationVacancyPlugs.formation_plug_layer_blocked(mgr, rear, acts, rear_id):
        _fail(failures, "mental_stack_plug_skip_mop: want formation_plug_layer_blocked during mop-up offense")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = CombatAIActionPicker.pick(acts, rear_id, mgr)
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        _fail(failures, "mental_stack_plug_skip_mop: formation_plug must defer during mop-up offense")
    if picked.is_empty() or str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_SWAP_RANK:
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "mental_stack_plug_skip_mop: want non-plug offense got %s layer=%s"
                    % [
                        str(picked.get("move_id", "")),
                        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
                    ]
                )
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: intact line + strikes only -> stack miss (no **`formation_plug`** stamp).

## MS-L5: intact line + strikes only -> stack miss (no **`formation_plug`** stamp).


static func _run_mental_stack_formation_plug_no_gap_stack_miss(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var player_id: int = CombatantEntityAccess.id_int(player)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    player["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, player_id)
    if not ListedActions.action_list_has_hostile_strike(acts, player_id):
        _fail(failures, "mental_stack_plug_no_gap: want listed strikes")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        _fail(failures, "mental_stack_plug_no_gap: want no swap_rank on intact duel")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if FormationVacancyPlugs.formation_plug_layer_eligible(mgr, player, player_id, acts):
        _fail(failures, "mental_stack_plug_no_gap: want plug layer ineligible")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var stacked: Dictionary = MentalStack.try_pick(acts, player_id, mgr)
    if not stacked.is_empty():
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "mental_stack_plug_no_gap: want stack miss got %s layer=%s"
                    % [
                        str(stacked.get("move_id", "")),
                        str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
                    ]
                )
            )
        )
    if not str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")).is_empty():
        _fail(failures, "mental_stack_plug_no_gap: want cleared stack layer stamp")
    var picked: Dictionary = CombatAIActionPicker.pick(acts, player_id, mgr)
    if picked.is_empty() or str(picked.get("move_id", "")) in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
        _fail(failures, "mental_stack_plug_no_gap: want utility offense got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: sparse post-flee line + listed melee defers plug even when shuffle moves exist.

## MS-L5: sparse post-flee line + listed melee defers plug even when shuffle moves exist.


static func _run_mental_stack_formation_plug_skipped_sparse_line_offense(failures: PackedStringArray) -> void:
    var fix: Dictionary = HarnessFixtures._harness_sparse_post_flee_6v3_mgr()
    if fix.is_empty():
        _fail(failures, "mental_stack_plug_skip_sparse: fixture setup failed")
        return
    var mgr: Node = fix["mgr"]
    var survivor: Dictionary = fix["survivor"]
    var survivor_id: int = int(fix["survivor_id"])
    survivor["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not ListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        _fail(failures, "mental_stack_plug_skip_sparse: want listed melee")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(mgr, survivor, acts, survivor_id):
        _fail(failures, "mental_stack_plug_skip_sparse: want sparse_line_prefer_finish_over_shuffle")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if not FormationVacancyPlugs.formation_plug_layer_blocked(mgr, survivor, acts, survivor_id):
        _fail(failures, "mental_stack_plug_skip_sparse: want formation_plug_layer_blocked")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = CombatAIActionPicker.pick(acts, survivor_id, mgr)
    if (
        str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        _fail(failures, "mental_stack_plug_skip_sparse: formation_plug must defer on sparse finish line")
    if picked.is_empty():
        _fail(failures, "mental_stack_plug_skip_sparse: expected pick")
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
        _fail(failures, "mental_stack_plug_skip_sparse: want offense pick got %s" % str(picked.get("move_id", "")))
    if CombatConstants.is_feature_mental_stack_ai_enabled():
        var layer: String = str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
            _fail(failures, "mental_stack_plug_skip_sparse: want sparse_fight layer got %s" % layer)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## L4b: sparse post-flee rank-0 **`try_pick`** stamps **`sparse_fight`** and chooses offense.

## L4b: sparse post-flee rank-0 **`try_pick`** stamps **`sparse_fight`** and chooses offense.


static func _run_mental_stack_sparse_fight_stamps_layer_on_try_pick(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var fix: Dictionary = HarnessFixtures._harness_sparse_post_flee_6v3_mgr()
    if fix.is_empty():
        _fail(failures, "mental_stack_sparse_fight: fixture setup failed")
        return
    var mgr: Node = fix["mgr"]
    var survivor: Dictionary = fix["survivor"]
    var survivor_id: int = int(fix["survivor_id"])
    if not FormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        _fail(failures, "mental_stack_sparse_fight: want sparse line")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    survivor["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not ListedActions.action_list_has_hostile_strike(acts, survivor_id):
        _fail(failures, "mental_stack_sparse_fight: want hostile strike listed for survivor")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, survivor_id, mgr)
    if picked.is_empty():
        _fail(failures, "mental_stack_sparse_fight: expected try_pick")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var layer: String = str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    var mid: String = str(picked.get("move_id", ""))
    if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
        _fail(failures, "mental_stack_sparse_fight: want offense pick got %s layer=%s" % [mid, layer])
    var reserve_only: bool = ListedActions.action_list_is_reserve_posture_only(acts)
    if reserve_only:
        if (
            layer
            not in [
                CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
                CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT,
            ]
        ):
            _fail(failures, "mental_stack_sparse_fight: reserve_only want hold_line or sparse_fight got %s" % layer)
    elif layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
        _fail(failures, "mental_stack_sparse_fight: want sparse_fight layer got %s" % layer)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## MS-L5: full **`CombatAIActionPicker.pick`** path stamps **`formation_plug`** on rank-0 gap relief.

## MS-L5: full **`CombatAIActionPicker.pick`** path stamps **`formation_plug`** on rank-0 gap relief.


static func _run_mental_stack_formation_plug_picker_e2e(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _fail(failures, "mental_stack_plug_picker: missing hole/rear/front fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _fail(failures, "mental_stack_plug_picker: want relief swap blocked")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    rear["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    var picked: Dictionary = CombatAIActionPicker.pick(acts, rear_id, mgr)
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        _fail(
            failures,
            (
                "mental_stack_plug_picker: want formation_plug got %s"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        _fail(failures, "mental_stack_plug_picker: want swap_rank got %s" % str(picked.get("move_id", "")))
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## MS-L6: low cohesion + wounded front on losing side -> **`flee`** beats listed strike; stamps **`rout`**.

## MS-L6: low cohesion + wounded front on losing side -> **`flee`** beats listed strike; stamps **`rout`**.
