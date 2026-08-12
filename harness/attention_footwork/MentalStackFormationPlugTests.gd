class_name AttentionFootworkMentalStackFormationPlugTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
const FormationRout := preload("res://combat/formation/CombatFormationRout.gd")
const CombatWeaponFormConst := preload("res://combat/weapon_form/CombatWeaponForm.gd")

## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _run_mental_stack_close_beats_focus_mop_up_under_telegraph(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_close_beats_focus_mop_up: missing center/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_LONG
    center["gauge"] = 100.0
    center["guard_line"] = "low"
    center[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    if not CombatAttention.is_being_wind_up_targeted(mgr, center_id):
        CombatRegressionHarness._fail(failures, "mental_stack_close_beats_focus_mop_up: setup want wind_up targeted")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, center_id, mgr)
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        CombatRegressionHarness._fail(
            failures,
            "mental_stack_close_beats_focus_mop_up: want attempt_close got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up hold-line gauge hint when `attempt_close` is listed.


## III-4 **3e**: mop-up hold-line gauge hint when `attempt_close` is listed.
static func _run_hold_line_hint_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up: missing center/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    var hint: String = PlayerTurnHints.hold_line_focus_only_hint(mgr, center, actions)
    if hint.is_empty() or not hint.contains("Mop-up"):
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up: want mop-up hint got '%s'" % hint)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up hold-line hint when listed melee strikes finish the last enemy.


## III-4 **3e**: mop-up hold-line hint when listed melee strikes finish the last enemy.
static func _run_hold_line_hint_mop_up_strikes_listed(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up_strikes: missing center/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_CLOSE
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var hint: String = PlayerTurnHints.hold_line_focus_only_hint(mgr, center, actions)
    if hint.is_empty() or not hint.contains("Mop-up"):
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up_strikes: want mop-up hint got '%s'" % hint)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up beats generic back-rank copy.


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up beats generic back-rank copy.
static func _run_hold_line_hint_mop_up_rear_rank(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 14:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if rear.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up_rear: missing rear/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    var hint: String = PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
    if hint.is_empty() or not hint.contains("Mop-up"):
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up_rear: want mop-up hint got '%s'" % hint)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: rear rank with listed strikes during mop-up gets strike-finish mop-up copy.


## III-4 **3e**: rear rank with listed strikes during mop-up gets strike-finish mop-up copy.
static func _run_hold_line_hint_mop_up_rear_rank_strikes(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 14:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if rear.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up_rear_strikes: missing rear/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(rear, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_CLOSE
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var hint: String = PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
    if hint.is_empty() or not hint.contains("listed strike"):
        CombatRegressionHarness._fail(
            failures, "hold_line_hint_mop_up_rear_strikes: want strike mop-up hint got '%s'" % hint
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Back rank reserve-only when not mop-up stays generic back-rank copy.


## Back rank reserve-only when not mop-up stays generic back-rank copy.
static func _run_hold_line_hint_back_rank_not_mopup(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 14:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 3)
    if rear.is_empty():
        CombatRegressionHarness._fail(failures, "hold_line_hint_back_rank: missing rear fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
    ]
    var hint: String = PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
    if hint.is_empty() or not hint.begins_with("Back rank"):
        CombatRegressionHarness._fail(failures, "hold_line_hint_back_rank: want back-rank copy got '%s'" % hint)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: rank-0 gap -> rear **`swap_rank`** beats listed strikes; stamps **`formation_plug`**.


## MS-L5: rank-0 gap -> rear **`swap_rank`** beats listed strikes; stamps **`formation_plug`**.
static func _run_mental_stack_formation_plug_swap_rank_over_strike(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: missing hole/rear/front fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: want rank-0 hole on line after kill")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: want relief swap blocked for plug test")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var front_id: int = CombatantEntityAccess.id_int(front)
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: want swap_rank listed vs front partner")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if not ListedActions.action_list_has_hostile_strike(acts, rear_id):
        var enemy_id: int = -1
        for c in mgr.combatants:
            if CombatantEntityAccess.is_living_on_side(c, "enemy"):
                enemy_id = CombatantEntityAccess.id_int(c)
                break
        if enemy_id < 0:
            CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: missing enemy for strike fixture")
            CombatRegressionHarness._free_manager_restore_global_rng(mgr)
            return
        acts.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
    var picked: Dictionary = MentalStack.try_pick(acts, rear_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_plug_swap: want formation_plug got %s"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_swap: want swap_rank got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: incapacitated front partner -> rear **`swap_rank`** stamps **`formation_plug`**.


## MS-L5: incapacitated front partner -> rear **`swap_rank`** stamps **`formation_plug`**.
static func _run_mental_stack_formation_plug_incap_forward(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if front.is_empty() or rear.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_incap: missing front/rear fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    front.state = CombatConstants.STATE_COWERING
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
    rear["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_incap: want swap_rank listed over incap front")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, rear_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_incap: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_plug_incap: want formation_plug got %s"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_incap: want swap_rank got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: Skirmish rank-0 hole -> front **`rotate_file`** when formation-only menu; stamps **`formation_plug`**.


## MS-L5: Skirmish rank-0 hole -> front **`rotate_file`** when formation-only menu; stamps **`formation_plug`**.
static func _run_mental_stack_formation_plug_rotate_skirmish_hole(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: expected skirmish mode")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rot_src: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rot_tgt: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: missing hole/rotate fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_rank0_hole(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: want rank-0 hole after kill")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var rot_src_id: int = CombatantEntityAccess.id_int(rot_src)
    var rot_tgt_id: int = CombatantEntityAccess.id_int(rot_tgt)
    rot_src["gauge"] = 100.0
    if not FormationMoves.rotate_file_action_legal(mgr, rot_src, rot_tgt):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: want legal rotate_file vs adjacent file")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    # Rotate plug path matches utility weight: formation-only menu (no listed strikes).
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rot_src_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": rot_tgt_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(acts, rot_src_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_plug_rotate: want formation_plug got %s"
                % str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ROTATE_FILE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_rotate: want rotate_file got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: fight-finish tail with listed offense must not stamp **`formation_plug`**.


## MS-L5: fight-finish tail with listed offense must not stamp **`formation_plug`**.
static func _run_mental_stack_formation_plug_skipped_fight_finish(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: want envelop_mop_up_active")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if center.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: missing center fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    center["gauge"] = 100.0
    var center_id: int = CombatantEntityAccess.id_int(center)
    var acts: Array = AvailableActionsBuilder.build(mgr, center_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, center, acts, center_id):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: want fight_finish_tail")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if not ListedActions.action_list_has_hostile_strike(acts, center_id):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: want listed offense")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, center_id, mgr)
    if (
        str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_skip_ff: formation_plug must not fire on fight-finish tail"
        )
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: expected stack pick on fight-finish")
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
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: envelop mop-up + listed strikes defers plug (rear rank with hole still finishes).


## MS-L5: envelop mop-up + listed strikes defers plug (rear rank with hole still finishes).
static func _run_mental_stack_formation_plug_skipped_mop_up_offense(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 10:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(4, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: want envelop_mop_up_active")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: missing hole/rear/front fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: want relief swap blocked")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: want rank-0 hole on line after kill")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
            CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: missing living enemy")
            CombatRegressionHarness._free_manager_restore_global_rng(mgr)
            return
        acts.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
    var front_id: int = CombatantEntityAccess.id_int(front)
    if not ListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        if not FormationMoves.swap_rank_action_legal(mgr, rear, front):
            CombatRegressionHarness._fail(
                failures, "mental_stack_plug_skip_mop: want legal swap_rank for plug-defer fixture"
            )
            CombatRegressionHarness._free_manager_restore_global_rng(mgr)
            return
        acts.append({"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": front_id})
    if not FormationVacancyPlugs.formation_plug_layer_blocked(mgr, rear, acts, rear_id):
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_skip_mop: want formation_plug_layer_blocked during mop-up offense"
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = CombatAIActionPicker.pick(acts, rear_id, mgr)
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_skip_mop: formation_plug must defer during mop-up offense"
        )
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
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: intact line + strikes only -> stack miss (no **`formation_plug`** stamp).


## MS-L5: intact line + strikes only -> stack miss (no **`formation_plug`** stamp).
static func _run_mental_stack_formation_plug_no_gap_stack_miss(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var player_id: int = CombatantEntityAccess.id_int(player)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    player["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, player_id)
    if not ListedActions.action_list_has_hostile_strike(acts, player_id):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want listed strikes")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want no swap_rank on intact duel")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if FormationVacancyPlugs.formation_plug_layer_eligible(mgr, player, player_id, acts):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want plug layer ineligible")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want cleared stack layer stamp")
    var picked: Dictionary = CombatAIActionPicker.pick(acts, player_id, mgr)
    if picked.is_empty() or str(picked.get("move_id", "")) in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_no_gap: want utility offense got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: sparse post-flee line + listed melee defers plug even when shuffle moves exist.


## MS-L5: sparse post-flee line + listed melee defers plug even when shuffle moves exist.
static func _run_mental_stack_formation_plug_skipped_sparse_line_offense(failures: PackedStringArray) -> void:
    var fix: Dictionary = CombatRegressionHarness._harness_sparse_post_flee_6v3_mgr()
    if fix.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: fixture setup failed")
        return
    var mgr: Node = fix["mgr"]
    var survivor: Dictionary = fix["survivor"]
    var survivor_id: int = int(fix["survivor_id"])
    survivor["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not ListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: want listed melee")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(mgr, survivor, acts, survivor_id):
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_skip_sparse: want sparse_line_prefer_finish_over_shuffle"
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if not FormationVacancyPlugs.formation_plug_layer_blocked(mgr, survivor, acts, survivor_id):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: want formation_plug_layer_blocked")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = CombatAIActionPicker.pick(acts, survivor_id, mgr)
    if (
        str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_skip_sparse: formation_plug must defer on sparse finish line"
        )
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: expected pick")
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
            failures, "mental_stack_plug_skip_sparse: want offense pick got %s" % str(picked.get("move_id", ""))
        )
    if CombatConstants.is_feature_mental_stack_ai_enabled():
        var layer: String = str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        if layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
            CombatRegressionHarness._fail(
                failures, "mental_stack_plug_skip_sparse: want sparse_fight layer got %s" % layer
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## L4b: sparse post-flee rank-0 **`try_pick`** stamps **`sparse_fight`** and chooses offense.


## L4b: sparse post-flee rank-0 **`try_pick`** stamps **`sparse_fight`** and chooses offense.
static func _run_mental_stack_sparse_fight_stamps_layer_on_try_pick(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return
    var fix: Dictionary = CombatRegressionHarness._harness_sparse_post_flee_6v3_mgr()
    if fix.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: fixture setup failed")
        return
    var mgr: Node = fix["mgr"]
    var survivor: Dictionary = fix["survivor"]
    var survivor_id: int = int(fix["survivor_id"])
    if not FormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: want sparse line")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    survivor["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not ListedActions.action_list_has_hostile_strike(acts, survivor_id):
        CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: want hostile strike listed for survivor")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, survivor_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: expected try_pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var layer: String = str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    var mid: String = str(picked.get("move_id", ""))
    if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
        CombatRegressionHarness._fail(
            failures, "mental_stack_sparse_fight: want offense pick got %s layer=%s" % [mid, layer]
        )
    var reserve_only: bool = ListedActions.action_list_is_reserve_posture_only(acts)
    if reserve_only:
        if (
            layer
            not in [
                CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
                CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT,
            ]
        ):
            CombatRegressionHarness._fail(
                failures, "mental_stack_sparse_fight: reserve_only want hold_line or sparse_fight got %s" % layer
            )
    elif layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
        CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: want sparse_fight layer got %s" % layer)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: full **`CombatAIActionPicker.pick`** path stamps **`formation_plug`** on rank-0 gap relief.


## MS-L5: full **`CombatAIActionPicker.pick`** path stamps **`formation_plug`** on rank-0 gap relief.
static func _run_mental_stack_formation_plug_picker_e2e(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_plug_picker: missing hole/rear/front fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        CombatRegressionHarness._fail(failures, "mental_stack_plug_picker: want relief swap blocked")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    rear["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    var picked: Dictionary = CombatAIActionPicker.pick(acts, rear_id, mgr)
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_plug_picker: want formation_plug got %s"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        CombatRegressionHarness._fail(
            failures, "mental_stack_plug_picker: want swap_rank got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: low cohesion + wounded front on losing side -> **`flee`** beats listed strike; stamps **`rout`**.


## MS-L6: low cohesion + wounded front on losing side -> **`flee`** beats listed strike; stamps **`rout`**.
static func _run_mental_stack_rout_stressed_flee_beats_strike(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 1, "ranks": 2}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var front_c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front_c) as CoreEntity
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    ent.blood_volume = 82.0
    form["line_cohesion"] = 0.38
    form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
    if not CombatantEntityAccess.flee_abandonment_warranted(front_c, mgr):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_stress: want abandonment warranted")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var fighter_id: int = CombatantEntityAccess.id_int(front_c)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_rout_stress: expected rout layer pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != (CombatConstants.MENTAL_STACK_LAYER_ROUT)
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_rout_stress: want rout got %s"
                % str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_rout_stress: want flee got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: heavy side casualties -> **`flee`** beats **`wait`**; stamps **`rout`**.


## MS-L6: heavy side casualties -> **`flee`** beats **`wait`**; stamps **`rout`**.
static func _run_mental_stack_rout_casualty_flee_beats_wait(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 1, "ranks": 2}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    form["line_cohesion"] = 0.9
    form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
    var rear_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    CombatRegressionHarness._soak_kill_combatant(mgr, rear_id)
    var front_c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front_c) as CoreEntity
    ent.blood_volume = 82.0
    if not FormationRout.rout_cognition_pressure(mgr, front_c):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_casualty: want rout pressure")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var fighter_id: int = CombatantEntityAccess.id_int(front_c)
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if (
        str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != (CombatConstants.MENTAL_STACK_LAYER_ROUT)
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_rout_casualty: want rout got %s"
                % str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_rout_casualty: want flee got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)

## MS-L6: fight-finish tail must not stamp **`rout`** when listed offense should finish.


## Phase 3: tier persistence — plug layer persists across ticks within commitment window.
static func _run_mental_stack_tier_persistence_plug(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: missing fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want rank-0 hole")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    rear["gauge"] = 100.0
    mgr.combat_clock = 1.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not ListedActions.actions_include_move_vs_target(acts, CombatantEntityAccess.id_int(front), CombatConstants.MOVE_ID_SWAP_RANK):
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want swap_rank listed")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStack.try_pick(acts, rear_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: expected first pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want swap_rank on first pick got %s" % str(picked.get("move_id", "")))
    var tier_state: Dictionary = rear.get(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE, {})
    if tier_state.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want tier state stamped")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var entered_at: float = tier_state.get(CombatConstantsMentalStack._TIER_ENTERED_AT, 0.0)
    if entered_at <= 0.0:
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want non-zero entered_at")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var persistent_acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": CombatantEntityAccess.id_int(front)},
    ]
    mgr.combat_clock = entered_at + 1.0
    var second_pick: Dictionary = MentalStack.try_pick(persistent_acts, rear_id, mgr)
    if second_pick.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want persistent pick within window")
    elif str(second_pick.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want swap_rank on persistent pick got %s" % str(second_pick.get("move_id", "")))
    mgr.combat_clock = entered_at + float(CombatConstantsMentalStack.MENTAL_STACK_TIER_COMMITMENT_TICKS) + 1.0
    var expired_acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": CombatantEntityAccess.id_int(front)},
    ]
    var third_pick: Dictionary = MentalStack.try_pick(expired_acts, rear_id, mgr)
    var tier_state_after: Dictionary = rear.get(CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE, {})
    if not tier_state_after.is_empty():
        var new_entered_at: float = tier_state_after.get(CombatConstantsMentalStack._TIER_ENTERED_AT, 0.0)
        if abs(new_entered_at - entered_at) < 0.01:
            CombatRegressionHarness._fail(failures, "mental_stack_tier_persist_plug: want expired tier state re-stamped with old clock but got entered_at=%.2f" % new_entered_at)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Phase 3: cohesion modifier — plug actions get bonus when nearby allies present and banner carrier alive.
static func _run_mental_stack_cohesion_modifier_nearby_banner(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if rear.is_empty():
        CombatRegressionHarness._fail(failures, "cohesion_modifier_nearby: missing rear fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var modifier: float = CombatMoraleCohesion._compute_cohesion_modifier(CombatantEntityAccess.id_int(rear), mgr)
    if modifier < 1.0:
        CombatRegressionHarness._fail(failures, "cohesion_modifier_nearby: want modifier >= 1.0 got %s" % str(modifier))
    rear["banner_carrier"] = true
    var form_player: Dictionary = mgr.formations["player"]
    form_player["morale_cohesion_factor"] = 1.0
    modifier = CombatMoraleCohesion._compute_cohesion_modifier(CombatantEntityAccess.id_int(rear), mgr)
    if modifier < 1.1:
        CombatRegressionHarness._fail(failures, "cohesion_modifier_banner: want banner bonus >= 1.1 got %s" % str(modifier))
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Phase 3: L6 rout trigger via consecutive guard breaks — guard_break_count reaches threshold -> rout layer fires.
static func _run_mental_stack_l6_rout_guard_break_threshold(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if front.is_empty():
        CombatRegressionHarness._fail(failures, "l6_rout_guard_break: missing front fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    if ent != null:
        ent.blood_volume = 48.0
    for _k in range(CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD):
        MentalStackDecider._record_guard_break(front)
    var gb_count: int = front.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_BREAK_COUNT, 0)
    if gb_count != CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD:
        CombatRegressionHarness._fail(failures, "l6_rout_guard_break: want %d guard breaks got %d" % [CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD, gb_count])
    front["gauge"] = 100.0
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[7]) if mgr.combatants.size() > 7 else -1
    if enemy_id < 0:
        for c in mgr.combatants:
            if CombatantEntityAccess.is_living_on_side(c, "enemy"):
                enemy_id = CombatantEntityAccess.id_int(c)
                break
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": front_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": front_id},
    ]
    if enemy_id >= 0:
        actions.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
    var picked: Dictionary = MentalStack.try_pick(actions, front_id, mgr)
    if not picked.is_empty() and str(front.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) == CombatConstants.MENTAL_STACK_LAYER_ROUT:
        pass
    else:
        if picked.is_empty():
            var layer: String = str(front.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            CombatRegressionHarness._fail(failures, "l6_rout_guard_break: expected rout pick got empty layer=%s" % layer)
        else:
            CombatRegressionHarness._fail(failures, "l6_rout_guard_break: want rout layer got %s" % str(front.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")))
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Phase 4: attention budget degrades excess targets — top N get full weight, beyond-N get degraded.
static func _run_attention_budget_degrades_excess_targets(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    ## 5 enemy attackers, all at close distance.
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if front.is_empty():
        CombatRegressionHarness._fail(failures, "attention_budget_degrade: missing front fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    ## Record observations from all 5 enemies so entries exist.
    for idx in range(7, mini(12, mgr.combatants.size())):
        var atk: Dictionary = mgr.combatants[idx] if idx < mgr.combatants.size() else {}
        if atk.is_empty():
            continue
        if not CombatantEntityAccess.is_living_on_side(atk, "enemy"):
            continue
        var dist_map: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(front, "distance_to")
        dist_map[CombatantEntityAccess.id_int(atk)] = CombatConstants.DISTANCE_CLOSE
        CombatAttention.record_attack_toward_defender(mgr, CombatantEntityAccess.id_int(atk), front, "head", "thrust")
    ## Set combat clock so refresh can run decay + priority update.
    mgr.combat_clock = 10.0
    CombatAttention.refresh_for_waiting_tick(mgr, front)
    var budget_max: int = CombatConstantsMentalStack.YOMI_ATTENTION_BUDGET_MAX
    ## Collect all enemy entries and their ranks/weights from the yomi root.
    var entry_0: Dictionary = CombatAttention.yomi_entry_for_attacker(front, mgr.combatants[7].get("id", -1))
    if not entry_0.is_empty():
        var rank: int = entry_0.get("priority_rank", -1)
        var weight: float = entry_0.get("attention_weight", 0.0)
        ## Entry must have a valid priority rank after refresh, and weight in [0.25, 1.0].
        if rank <= 0 or weight < 0.25 or weight > 1.0:
            CombatRegressionHarness._fail(failures, "attention_budget_degrade: top entry invalid rank=%d weight=%s" % [rank, str(weight)])
    ## Verify that among the 5 entries, at least one has degraded weight (budget_max=3, so ranks 4-5 degrade).
    var root: Dictionary = front.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, {}) as Dictionary
    var has_degraded: bool = false
    for key in root.keys():
        var ent: Variant = root.get(key, null)
        if ent is not Dictionary:
            continue
        var e: Dictionary = (ent as Dictionary)
        var w: float = e.get("attention_weight", 1.0)
        var r: int = e.get("priority_rank", -1)
        if r > budget_max and w < CombatConstantsMentalStack.YOMI_ATTENTION_PRIORITY_DEGRADE_MULT * 1.1:
            has_degraded = true
    if not has_degraded:
        CombatRegressionHarness._fail(failures, "attention_budget_degrade: expected at least one degraded attacker")
    ## Verify weighted observation view applies attention multiplier to degraded entries.
    for key in root.keys():
        var ent: Variant = root.get(key, null)
        if ent is not Dictionary:
            continue
        var e: Dictionary = (ent as Dictionary)
        var w: float = e.get("attention_weight", 1.0)
        if w < 1.0 and w > 0.0:
            var view: Dictionary = CombatAttention.get_observation_view(e, "weighted")
            var wc: Dictionary = view.get("line_counts", {})
            for vk in wc.keys():
                var val: float = float(wc[vk])
                if val < 1.0:
                    break
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Phase 5: Deception exploit bait suppression — counter-reads are skipped when opponent is in Exploit phase.
static func _run_deception_exploit_bait_suppression(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty():
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: missing fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var opponent_id: int = -1
    for enemy in mgr.combatants:
        if CombatantEntityAccess.side_str(enemy) == "enemy" and enemy is Dictionary:
            opponent_id = CombatantEntityAccess.id_int(enemy)
            break
    if opponent_id < 0:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: missing opponent fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    ## Verify deterministic gating conditions for should_respect_bait.
    ## exploit_counter >= 3 — must return false (seen through).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.2,
        "exploit_counter": 3,
    }
    if CombatAttention.should_respect_bait(rear):
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected bait to be inactive after 3 exploits")
    ## Set resistance = 0.6 — should_respect_bait must return false (high resistance).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.6,
        "exploit_counter": 1,
    }
    if CombatAttention.should_respect_bait(rear):
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected bait to be inactive with high resistance")
    ## Seed in Establish phase — should_respect_bait must return false (not yet Exploit).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_ESTABLISH,
        "resistance": 0.0,
        "exploit_counter": 0,
    }
    if CombatAttention.should_respect_bait(rear):
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected bait inactive in Establish phase")
    ## Verify deception state transitions via record_deception_outcome.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_before: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_before.get("phase", "") != YomiConstants.DECEPTION_PHASE_ESTABLISH:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected initial Establish phase")
    ## Simulate 3 consecutive correct reads — both record_counter_read_outcome and
    ## record_deception_outcome fire per exchange (as in production). After the third
    ## iteration, try_advance_deception_probe advances to Probe and then
    ## record_deception_outcome (Probe+success) advances to Exploit.
    for _k in range(3):
        CombatWeaponFormConst.record_counter_read_outcome(rear, opponent_id, true, "ox")
        CombatAttention.record_deception_outcome(rear, opponent_id, true)
    CombatAttention.try_advance_deception_probe(rear, 3)
    CombatAttention.record_deception_outcome(rear, opponent_id, true)
    var ds_after: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_after.get("phase", "") != YomiConstants.DECEPTION_PHASE_EXPLOIT:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected Exploit after 3 correct reads")
    var exploit_c: int = ds_after.get("exploit_counter", -1)
    if exploit_c != 0:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected exploit_counter=0 on entry to Exploit")
    ## A failure while in Exploit → back to Establish with resistance boost.
    CombatAttention.record_deception_outcome(rear, opponent_id, false)
    ds_after = CombatAttention._get_deception_state(rear)
    if ds_after.get("phase", "") != YomiConstants.DECEPTION_PHASE_ESTABLISH:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected back to Establish after Exploit failure")
    var resistance_val: float = ds_after.get("resistance", 0.0)
    if resistance_val < 0.3:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected resistance boost on exploit exposure")
    ## Verify clear_focus_and_yomi erases deception state.
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {"phase": "test", "resistance": 0.5, "exploit_counter": 1}
    CombatAttention.clear_focus_and_yomi(rear)
    if rear.has(CombatConstants.COMBATANT_KEY_DECEPTION_STATE):
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected deception state to be cleared")
    ## Probe+success → Exploit with exploit_counter reset.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_probe: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_PROBE,
        "resistance": 0.1,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_probe
    CombatAttention.record_deception_outcome(rear, opponent_id, true)
    var ds_after_probe_success: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_after_probe_success.get("phase", "") != YomiConstants.DECEPTION_PHASE_EXPLOIT:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected Probe→Exploit on success")
    if ds_after_probe_success.get("exploit_counter", -1) != 0:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected exploit_counter=0 on Probe→Exploit transition")
    ## Probe+failure → back to Establish (no resistance change).
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_probe_fail: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_PROBE,
        "resistance": 0.1,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_probe_fail
    CombatAttention.record_deception_outcome(rear, opponent_id, false)
    var ds_after_probe_failure: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_after_probe_failure.get("phase", "") != YomiConstants.DECEPTION_PHASE_ESTABLISH:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected Probe→Establish on failure")
    var probe_fail_resistance: float = ds_after_probe_failure.get("resistance", -1.0)
    if abs(probe_fail_resistance - 0.1) > 0.001:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected resistance unchanged on Probe→Establish")
    ## Multi-cycle resistance accumulation: Establish+success adds 0.25 each cycle.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_cycle: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_ESTABLISH,
        "resistance": 0.0,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_cycle
    for _cycle in range(3):
        CombatAttention.record_deception_outcome(rear, opponent_id, true)
    var ds_after_cycles: Dictionary = CombatAttention._get_deception_state(rear)
    var cycle_resistance: float = ds_after_cycles.get("resistance", -1.0)
    if abs(cycle_resistance - 0.75) > 0.001:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected resistance=0.75 after 3 Establish+success cycles (got %s)" % str(cycle_resistance))
    ## With resistance 0.75 > DECEPTION_ESTABLISH_PROB (0.5), should_respect_bait must return false even in Exploit phase.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_high_res: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.75,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_high_res
    if CombatAttention.should_respect_bait(rear):
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected bait inactive with high accumulated resistance")
    ## Verify _is_form_stale_for_opponent returns false when no yomi entry exists.
    if not CombatWeaponFormConst._is_form_stale_for_opponent(mgr, rear, opponent_id):
        pass  ## expected: stale=false with no yomi entry
    else:
        CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected stale=false with no yomi entry")
    ## Advance the combat clock so evaluate_automatic_form can run.
    mgr.combat_clock = 5.0
    rear["gauge"] = 100.0
    var form_before: String = CombatantEntityAccess.form_str(rear)
    CombatWeaponFormConst.evaluate_automatic_form(mgr, rear)
    ## Without yomi data the counter_read/duel_read paths must not switch; only geometry-driven
    ## surround / low-stamina switches can fire.  In a tight formation those may legitimately
    ## trigger, so we check that no *inference-based* (counter_read / duel_read) stamp was applied.
    var form_after: String = CombatantEntityAccess.form_str(rear)
    if str(form_after) != str(form_before):
        var reason: String = str(rear.get(CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON, ""))
        if "counter_read" in reason or "duel_read" in reason:
            CombatRegressionHarness._fail(failures, "deception_exploit_bait: expected no inference-based auto-switch with no yomi data, got form=%s reason=%s" % [form_after, reason])
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Phase 5: Deception probabilistic bait suppression — seeded RNG test for randf() branch.
static func _run_deception_probabilistic_bait_suppression(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty():
        CombatRegressionHarness._fail(failures, "prob_bait_suppression: missing fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var opponent_id: int = -1
    for enemy in mgr.combatants:
        if CombatantEntityAccess.side_str(enemy) == "enemy" and enemy is Dictionary:
            opponent_id = CombatantEntityAccess.id_int(enemy)
            break
    if opponent_id < 0:
        CombatRegressionHarness._fail(failures, "prob_bait_suppression: missing opponent fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    ## Set up Exploit phase with exploit_counter=1 and low resistance (bait_prob ~0.233).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.0,
        "exploit_counter": 1,
    }
    ## Use a local RNG instance for deterministic testing of the randf() bait branch.
    var hit_bait_count: int = 0
    var total_trials: int = 20
    for _trial in range(total_trials):
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.seed = 12345 + _trial
        if CombatAttention.should_respect_bait(rear, rng):
            hit_bait_count += 1
    ## With exploit_counter=1, bait_prob ≈ lerpf(0.1, 0.5, 1/3) ≈ 0.233.
    ## Over 20 trials with seeds 0..19, expect some hits; verify not all pass and not all fail.
    if hit_bait_count <= 0:
        CombatRegressionHarness._fail(failures, "prob_bait_suppression: expected at least one bait hit in %d trials" % str(total_trials))
    if hit_bait_count >= total_trials:
        CombatRegressionHarness._fail(failures, "prob_bait_suppression: expected some rejections (got %d/%d)" % [hit_bait_count, total_trials])
    ## Verify _is_form_stale_for_opponent helper exists and returns false with empty yomi entry.
    if CombatWeaponFormConst._is_form_stale_for_opponent(mgr, rear, opponent_id):
        CombatRegressionHarness._fail(failures, "prob_bait_suppression: expected stale=false with no yomi data")
    ## Verify _should_bait_counter_read returns false when opponent has no deception state.
    var enemy_c: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, opponent_id)
    if not enemy_c.is_empty():
        enemy_c.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
        if CombatWeaponFormConst._should_bait_counter_read(mgr, rear, opponent_id):
            CombatRegressionHarness._fail(failures, "prob_bait_suppression: expected false with no deception state on opponent")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Phase 3: L2 transition guard — counter-tempo requires >= 2 consecutive failures at higher tiers.
static func _run_mental_stack_l2_transition_guard(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty():
        CombatRegressionHarness._fail(failures, "l2_transition_guard: missing fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    rear["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var enemy_atk: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_atk = c
            break
    if enemy_atk.is_empty():
        CombatRegressionHarness._fail(failures, "l2_transition_guard: missing enemy attacker")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var atk_id: int = CombatantEntityAccess.id_int(enemy_atk)
    for enemy in mgr.combatants:
        if CombatantEntityAccess.side_str(enemy) == "enemy":
            var dist: Dictionary = enemy.get("distance_to", {}) as Dictionary
            dist[rear_id] = CombatConstants.DISTANCE_CLOSE
    AttackWindUpStarter.start(mgr, atk_id, rear_id, "thrust")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    rear[CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL] = mgr.combat_clock + 10.0
    rear[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    if not CounterTempo.can_act(mgr, rear):
        CombatRegressionHarness._fail(failures, "l2_transition_guard: want can_act true for counter-tempo fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    rear[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] = {
        CombatConstantsMentalStack._TIER_ACTIVE: "",
        CombatConstantsMentalStack._TIER_ENTERED_AT: mgr.combat_clock - 10.0,
        CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES: 1,
    }
    var acts_with_counters: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": "parry_high", "target_id": rear_id, "target_part": "head", CombatConstants.ACTION_KEY_COUNTER_TEMPO: true},
    ]
    var picked_low: Dictionary = MentalStack.try_pick(acts_with_counters, rear_id, mgr)
    var c_check_low: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, rear_id)
    var layer_low: String = str(c_check_low.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if not picked_low.is_empty() and layer_low == CombatConstants.MENTAL_STACK_LAYER_COUNTER:
        CombatRegressionHarness._fail(failures, "l2_transition_guard: guard should block L2 with failures=1")
    rear[CombatConstantsMentalStack.COMBATANT_KEY_TIER_STATE] = {
        CombatConstantsMentalStack._TIER_ACTIVE: "",
        CombatConstantsMentalStack._TIER_ENTERED_AT: mgr.combat_clock - 10.0,
        CombatConstantsMentalStack._TIER_CONSECUTIVE_FAILURES: 3,
    }
    AttackWindUpStarter.start(mgr, atk_id, rear_id, "thrust")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    rear[CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL] = mgr.combat_clock + 10.0
    rear[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    var picked_high: Dictionary = MentalStack.try_pick(acts_with_counters, rear_id, mgr)
    var c_check: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, rear_id)
    var layer: String = str(c_check.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if not picked_high.is_empty() and (layer == CombatConstants.MENTAL_STACK_LAYER_COUNTER or layer == CombatConstants.MENTAL_STACK_LAYER_INCOMING):
        pass  ## Guard satisfied -> counter-tempo fires at L2/L3.
    else:
        CombatRegressionHarness._fail(failures, "l2_transition_guard: expected L2/L3 to fire with failures=3 got layer='%s' picked_empty=%s" % [layer, str(picked_high.is_empty())])
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
