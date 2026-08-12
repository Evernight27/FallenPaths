class_name Tier1EnvelopPlugSkirmishTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_fall_back_solo_depth_recheck_rank2_after_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(_CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var rank0: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rank1: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var rank2: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 2, 0)
    if rank0.is_empty() or rank1.is_empty() or rank2.is_empty():
        _CombatRegressionHarness._fail(failures, "fall_back_depth_recheck: missing 1x3 column fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    rank1["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    mgr.combat_clock = 1.0
    var rank0_id: int = CombatantEntityAccess.id_int(rank0)
    var rank2_id: int = CombatantEntityAccess.id_int(rank2)
    rank0["state"] = CombatConstants.STATE_FALLING_BACK
    rank0["state_timer"] = float(rank0.get(DataKeys.PA_STATE_DURATION, CombatConstants.BASE_FALL_BACK_S))
    CombatFormationFlow.handle_fall_back_solo_resolve(mgr, {"combatant_id": rank0_id, "resolve_at": 0.0, "data": {}})
    var after: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, rank0_id)
    var rank_after: int = CombatantEntityAccess.rank_int(after)
    var delay2: float = CombatEventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    _CombatRegressionHarness._free_manager(mgr)
    if rank_after != 1:
        _CombatRegressionHarness._fail(
            failures, "fall_back_depth_recheck: want rank1 got rank=%d delay2=%.2f" % [rank_after, delay2]
        )
    if absf(delay2 - want) > 0.05:
        _CombatRegressionHarness._fail(
            failures, "fall_back_depth_recheck: rank-2 want delay %.2f got %.2f" % [want, delay2]
        )


## III-6: incap plug-forward copy surfaces on formation gauge suffix when **`swap_rank`** listed.


## III-6: incap plug-forward copy surfaces on formation gauge suffix when **`swap_rank`** listed.
static func _harness_plug_forward_incap_fixtures(mgr: Node) -> Dictionary:
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    return {"front": front, "rear": rear}


static func _run_plug_forward_gauge_suffix_when_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var fx: Dictionary = Tier1EnvelopPlugSkirmishTests._harness_plug_forward_incap_fixtures(mgr)
    var front: Dictionary = fx["front"]
    var rear: Dictionary = fx["rear"]
    if front.is_empty() or rear.is_empty():
        _CombatRegressionHarness._fail(failures, "plug_forward_gauge: missing front/rear")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    _CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    _CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    front.state = CombatConstants.STATE_COWERING
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rear))
    if not CombatantEntityAccess.is_incapacitated(front):
        _CombatRegressionHarness._fail(failures, "plug_forward_gauge: want incapacitated front partner")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        _CombatRegressionHarness._fail(failures, "plug_forward_gauge: want swap_rank listed over incap front")
        _CombatRegressionHarness._free_manager(mgr)
        return
    CombatPlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, rear, acts)
    var stamp: String = str(rear.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
    _CombatRegressionHarness._free_manager(mgr)
    if "Partner down" not in stamp:
        _CombatRegressionHarness._fail(
            failures, "plug_forward_gauge: want partner-down suffix on gauge stamp got %s" % stamp
        )


## III-6 maintain: rear lists swap_rank to plug rank-0 hole when relief fitness gate blocks.


## III-6 maintain: rear lists swap_rank to plug rank-0 hole when relief fitness gate blocks.
static func _run_swap_rank_listed_line_plug_when_relief_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: missing hole/rear/front fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not CombatFormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want rank-0 hole on line after kill")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want relief swap blocked for listing test")
        _CombatRegressionHarness._free_manager(mgr)
        return
    rear["gauge"] = 100.0
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not CombatListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        _CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want swap_rank listed when line has hole")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var swap_act: Dictionary = CombatListedActions.first_action_with_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK)
    if not CombatFormationMoveListing.listed_action_is_formation_plug_pick(mgr, rear, swap_act, acts, rear_id):
        _CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want formation_plug pick on rank-0 hole swap")
    if not CombatEngagementDiagnostics.line_plug_logged_for_pick(mgr, rear, rear_id, acts, swap_act):
        _CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want line_plug=true on rank-0 hole swap")
    _CombatRegressionHarness._free_manager(mgr)


## III-6 maintain: resolve accepts line-plug **`swap_rank`** when relief fitness gate blocks listing-only path.


## III-6 maintain: resolve accepts line-plug **`swap_rank`** when relief fitness gate blocks listing-only path.
static func _run_swap_rank_resolve_line_plug_when_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    var front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if hole_front.is_empty() or rear.is_empty() or front.is_empty():
        _CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: missing hole/rear/front fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not CombatFormationFlow.formation_line_has_rank0_gap(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: want rank-0 gap on line after kill")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        _CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: want relief swap blocked for resolve test")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var front_id: int = CombatantEntityAccess.id_int(front)
    rear["gauge"] = 100.0
    front["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var acts: Array = AvailableActionsBuilder.build(mgr, rear_id)
    if not CombatListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        _CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: want swap_rank listed vs front partner")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var ok: bool = CombatResolveAction.resolve(mgr, rear_id, front_id, CombatConstants.MOVE_ID_SWAP_RANK, {})
    _CombatRegressionHarness._free_manager(mgr)
    if not ok:
        _CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: resolve should accept line-plug swap_rank")


## III-6: line-plug copy surfaces on formation gauge suffix when **`swap_rank`** listed.


## III-6: line-plug copy surfaces on formation gauge suffix when **`swap_rank`** listed.
static func _run_line_plug_gauge_suffix_when_swap_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if hole_front.is_empty() or rear.is_empty():
        _CombatRegressionHarness._fail(failures, "line_plug_gauge: missing hole/rear fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rear))
    CombatPlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, rear, acts)
    var stamp: String = str(rear.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
    _CombatRegressionHarness._free_manager(mgr)
    if "Front gap" not in stamp:
        _CombatRegressionHarness._fail(failures, "line_plug_gauge: want plug suffix on gauge stamp got %s" % stamp)


## III-6: rank-1 turn resolves -> rank-2+ same-file reserves get formation recheck delay.


## III-6: rank-1 turn resolves -> rank-2+ same-file reserves get formation recheck delay.
static func _run_same_file_depth_recheck_after_rank1_turn(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(_CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(_CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
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
        _CombatRegressionHarness._fail(failures, "depth_recheck_rank1: missing rank-1/rank-2 column")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var rank1_id: int = CombatantEntityAccess.id_int(rank1)
    var rank2_id: int = CombatantEntityAccess.id_int(rank2)
    mgr.skip_turn(rank1_id)
    var delay: float = CombatEventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
    var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
    if absf(delay - want) > 0.05:
        _CombatRegressionHarness._fail(failures, "depth_recheck_rank1: want delay %.2f got %.2f" % [want, delay])
    _CombatRegressionHarness._free_manager(mgr)


## p4f UX: front-gap swap hint when line-plug **`swap_rank`** is listed.


## p4f UX: front-gap swap hint when line-plug **`swap_rank`** is listed.
static func _run_front_gap_line_plug_hint_when_swap_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if hole_front.is_empty() or rear.is_empty():
        _CombatRegressionHarness._fail(failures, "front_gap_hint: missing hole/rear fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rear))
    var hint: String = CombatPlayerTurnHints.front_gap_line_plug_hint(mgr, rear, acts)
    if "Front gap" not in hint:
        _CombatRegressionHarness._fail(failures, "front_gap_hint: want plug copy got %s" % hint)
    _CombatRegressionHarness._free_manager(mgr)


## p4f UX: Skirmish rotate hint when rank-0 gap and **`rotate_file`** listed.


## p4f UX: Skirmish rotate hint when rank-0 gap and **`rotate_file`** listed.
static func _run_skirmish_line_gap_rotate_hint(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: expected skirmish mode")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rot_src: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rot_tgt: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        _CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: missing hole/rotate fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not CombatFormationFlow.formation_has_rank0_hole(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: want rank-0 hole on line after kill")
        _CombatRegressionHarness._free_manager(mgr)
        return
    rot_src["gauge"] = 100.0
    rot_tgt["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rot_src))
    var hint: String = CombatPlayerTurnHints.skirmish_line_gap_rotate_hint(mgr, rot_src, acts)
    if "Line gap" not in hint:
        _CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: want rotate gap copy got %s" % hint)
    _CombatRegressionHarness._free_manager(mgr)


## III-6: Skirmish rank-0 hole boosts **`rotate_file`** weight even without depth ranks.


## III-6: Skirmish rank-0 hole boosts **`rotate_file`** weight even without depth ranks.
static func _run_rotate_line_plug_weight_skirmish_rank0_hole(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _CombatRegressionHarness._fail(failures, "rotate_skirmish_hole: expected skirmish mode")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rot_src: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rot_tgt: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        _CombatRegressionHarness._fail(failures, "rotate_skirmish_hole: missing hole/rotate fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if not CombatFormationFlow.formation_has_rank0_hole(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "rotate_skirmish_hole: want rank-0 hole after kill")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if CombatFormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _CombatRegressionHarness._fail(
            failures, "rotate_skirmish_hole: skirmish 1-rank should not expose depth plug opportunity"
        )
        _CombatRegressionHarness._free_manager(mgr)
        return
    var rot_act: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_ROTATE_FILE,
        "target_id": CombatantEntityAccess.id_int(rot_tgt),
    }
    var w: float = CombatAIActionPicker._get_action_weight(
        rot_act, CombatantEntityAccess.id_int(rot_src), mgr, true, {}, {}
    )
    if w < CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT - 0.01:
        _CombatRegressionHarness._fail(
            failures,
            "rotate_skirmish_hole: want >= %.2f got %.3f" % [CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT, w]
        )
    _CombatRegressionHarness._free_manager(mgr)


## p4f UX: plug-forward hint when **`swap_rank`** lists over incapacitated rank-0 partner.


## p4f UX: plug-forward hint when **`swap_rank`** lists over incapacitated rank-0 partner.
static func _run_plug_forward_incap_partner_hint(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var fx: Dictionary = Tier1EnvelopPlugSkirmishTests._harness_plug_forward_incap_fixtures(mgr)
    var front: Dictionary = fx["front"]
    var rear: Dictionary = fx["rear"]
    if front.is_empty() or rear.is_empty():
        _CombatRegressionHarness._fail(failures, "plug_forward_hint: missing front/rear")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front) as CoreEntity
    _CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    _CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    front.state = CombatConstants.STATE_COWERING
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rear))
    if not CombatantEntityAccess.is_incapacitated(front):
        _CombatRegressionHarness._fail(failures, "plug_forward_hint: want incapacitated front partner")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
        _CombatRegressionHarness._fail(failures, "plug_forward_hint: want swap_rank listed over incap front")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var hint: String = CombatPlayerTurnHints.plug_forward_incap_partner_hint(mgr, rear, acts)
    if "Partner down" not in hint:
        _CombatRegressionHarness._fail(failures, "plug_forward_hint: want partner-down copy got %s" % hint)
    _CombatRegressionHarness._free_manager(mgr)


## III-6 maintain: rotate_file gets line-plug floor when rank-0 hole exists (weight path).


## III-6 maintain: rotate_file gets line-plug floor when rank-0 hole exists (weight path).
static func _run_rotate_file_line_plug_weight_when_front_hole(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 10:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var hole_front: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var rot_src: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var rot_tgt: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        _CombatRegressionHarness._fail(failures, "rotate_line_plug: missing hole/rotate fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    hole_front["alive"] = false
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
    if FormationSlots.slot_has_any_living_occupant(mgr, slots, Vector2i(0, 4)):
        _CombatRegressionHarness._fail(failures, "rotate_line_plug: want empty rank-0 file 4 after kill")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatFormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "rotate_line_plug: want rank-0 hole on line after kill")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var rot_act: Dictionary = {
        "move_id": CombatConstants.MOVE_ID_ROTATE_FILE,
        "target_id": CombatantEntityAccess.id_int(rot_tgt),
    }
    var w: float = CombatAIActionPicker._get_action_weight(
        rot_act, CombatantEntityAccess.id_int(rot_src), mgr, true, {}, {}
    )
    if w < CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT - 0.01:
        _CombatRegressionHarness._fail(
            failures,
            "rotate_line_plug: want >= %.2f got %.3f" % [CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT, w]
        )
    _CombatRegressionHarness._free_manager(mgr)


## III-4 Track A PR3 (**2b**): Skirmish wide side skips native line compaction when outnumbering on files.


## III-4 Track A PR3 (**2b**): Skirmish wide side skips native line compaction when outnumbering on files.
static func _run_geometry_skirmish_wide_line_no_compact(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1}, {"files": 3, "ranks": 1})
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: expected skirmish mode")
    var players_r0: Array = []
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "player"):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        players_r0.append(c)
    if players_r0.size() != 3:
        _CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: expected 3 player rank-0")
    players_r0.sort_custom(
        func(a: Dictionary, b: Dictionary) -> bool:
            return CombatantEntityAccess.id_int(a) < CombatantEntityAccess.id_int(b)
    )
    var want_files: Array[int] = [2, 3, 4]
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for i in range(3):
        var c: Dictionary = players_r0[i]
        var nid: int = CombatantEntityAccess.id_int(c)
        FormationSlots.remove_combatant_from_slots(slots, nid)
        var wf: int = want_files[i]
        c["file"] = wf
        FormationSlots.slot_set_single(slots, Vector2i(0, wf), nid)
    if CombatFormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: wide player should skip skirmish compaction")
    for i in range(3):
        if CombatantEntityAccess.file_int(players_r0[i]) != want_files[i]:
            _CombatRegressionHarness._fail(
                failures,
                (
                    "geometry_skirmish_wide: player rank-0 file shifted want %s got %d"
                    % [str(want_files), CombatantEntityAccess.file_int(players_r0[i])]
                )
            )
    # Narrower enemy side may still compact when rank-0 has gaps.
    var enemies_r0: Array = []
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        enemies_r0.append(c)
    enemies_r0.sort_custom(
        func(a: Dictionary, b: Dictionary) -> bool:
            return CombatantEntityAccess.id_int(a) < CombatantEntityAccess.id_int(b)
    )
    var form_enemy: Dictionary = mgr.formations["enemy"]
    var eslots: Dictionary = FormationSlots.formation_slots_dict(form_enemy)
    for c in enemies_r0:
        FormationSlots.remove_combatant_from_slots(eslots, CombatantEntityAccess.id_int(c))
    for i in range(enemies_r0.size()):
        var ec: Dictionary = enemies_r0[i]
        var eid: int = CombatantEntityAccess.id_int(ec)
        var ef: int = i + 1
        ec["file"] = ef
        FormationSlots.slot_set_single(eslots, Vector2i(0, ef), eid)
    if not CombatFormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: narrow enemy with gaps should compact")
    for i in range(enemies_r0.size()):
        if CombatantEntityAccess.file_int(enemies_r0[i]) != i:
            _CombatRegressionHarness._fail(
                failures,
                (
                    "geometry_skirmish_wide: enemy compact want file %d got %d"
                    % [i, CombatantEntityAccess.file_int(enemies_r0[i])]
                )
            )
    _CombatRegressionHarness._free_manager(mgr)


## III-4 Track A PR5 (**3b**): Skirmish outnumber allows **`rotate_file`** on wider side only.


## III-4 Track A PR5 (**3b**): Skirmish outnumber allows **`rotate_file`** on wider side only.
static func _run_skirmish_outnumber_allows_rotate_file(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _CombatRegressionHarness._fail(failures, "skirmish_rotate: expected skirmish mode")
    if not CombatEngagementMode.allow_rotate_file_for_formation(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "skirmish_rotate: wide player should allow rotate_file")
    if CombatEngagementMode.allow_rotate_file_for_formation(mgr, "enemy"):
        _CombatRegressionHarness._fail(failures, "skirmish_rotate: narrow enemy should not allow rotate_file")
    var p0: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var p1: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if p0.is_empty() or p1.is_empty():
        _CombatRegressionHarness._fail(failures, "skirmish_rotate: need adjacent player rank-0 allies")
    else:
        p0["gauge"] = 100.0
        p1["gauge"] = 100.0
        var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(p0))
        var saw_rotate: bool = not (
            CombatListedActions
            . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, CombatantEntityAccess.id_int(p1))
            . is_empty()
        )
        if not saw_rotate:
            _CombatRegressionHarness._fail(
                failures, "skirmish_rotate: player file-0 should list rotate_file vs file-1 in skirmish outnumber"
            )
    var e0: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    var e1: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 1)
    if e0.is_empty() or e1.is_empty():
        _CombatRegressionHarness._fail(failures, "skirmish_rotate: need adjacent enemy rank-0 allies")
    else:
        e0["gauge"] = 100.0
        e1["gauge"] = 100.0
        var e_acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(e0))
        if (
            (
                CombatListedActions
                . first_action_move_vs_target(
                    e_acts, CombatConstants.MOVE_ID_ROTATE_FILE, CombatantEntityAccess.id_int(e1)
                )
                . is_empty()
            )
            == false
        ):
            _CombatRegressionHarness._fail(failures, "skirmish_rotate: narrow enemy should not list rotate_file")
    _CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: post-attrition mop-up (4v1 tail)  -  `envelop_mop_up_active`, MID close listing, rotate suppress.


## III-4 **3e**: post-attrition mop-up (4v1 tail)  -  `envelop_mop_up_active`, MID close listing, rotate suppress.
static func _harness_7v3_mop_up_mgr() -> Node:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        _CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    return mgr


static func _run_envelop_mop_up_active_after_attrition(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "envelop_mop_up: expected active after 7v1 attrition")
    if CombatDoctrine.envelop_mop_up_active(mgr, "enemy"):
        _CombatRegressionHarness._fail(failures, "envelop_mop_up: narrow enemy should not have mop-up advantage")
    _CombatRegressionHarness._free_manager(mgr)


static func _run_envelop_close_listed_mid_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if player.is_empty() or enemy.is_empty():
        _CombatRegressionHarness._fail(failures, "envelop_close_mid: missing player/enemy fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_MID
    if not CombatMeleeListing.attempt_close_listed_for_pair(mgr, player, enemy_id, CombatConstants.DISTANCE_MID):
        _CombatRegressionHarness._fail(failures, "envelop_close_mid: want attempt_close listed at MID during mop-up")
    dist[enemy_id] = CombatConstants.DISTANCE_LONG
    var eff: float = CombatPairGeometry.effective_pair_eff_dist(mgr, player, enemy)
    var in_swing: bool = CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(player), eff
    )
    var listed_long: bool = CombatMeleeListing.attempt_close_listed_for_pair(
        mgr, player, enemy_id, CombatConstants.DISTANCE_LONG
    )
    if in_swing:
        if listed_long:
            _CombatRegressionHarness._fail(
                failures, "envelop_close_mid: in-swing at LONG during mop-up must not list attempt_close"
            )
    else:
        if not listed_long:
            _CombatRegressionHarness._fail(
                failures, "envelop_close_mid: out-of-reach LONG during mop-up want attempt_close listed"
            )
    _CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `resolve_close_attempt` accepts MID band during mop-up (not `not_long` telemetry).


## III-4 **3e**: `resolve_close_attempt` accepts MID band during mop-up (not `not_long` telemetry).
static func _run_envelop_close_resolve_mid_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if player.is_empty() or enemy.is_empty():
        _CombatRegressionHarness._fail(failures, "envelop_close_resolve: missing player/enemy fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
        player["distance_to"] = {}
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    (player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
    (enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
    if mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        mgr.remove_meta(TacticalCombat.META_COMBAT_TELEMETRY)
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        var tel: Dictionary = mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
        if int(tel.get("invalid_close_resolve_blocked", 0)) >= 1:
            _CombatRegressionHarness._fail(
                failures, "envelop_close_resolve: MID mop-up must not increment invalid_close_resolve_blocked"
            )
    _CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `resolve_close_attempt` accepts CLOSE band during mop-up (listing/resolve parity).


## III-4 **3e**: `resolve_close_attempt` accepts CLOSE band during mop-up (listing/resolve parity).
static func _run_envelop_close_resolve_close_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if player.is_empty() or enemy.is_empty():
        _CombatRegressionHarness._fail(failures, "envelop_close_resolve_close: missing player/enemy fixtures")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
        player["distance_to"] = {}
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    (player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_CLOSE
    (enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_CLOSE
    if mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        mgr.remove_meta(TacticalCombat.META_COMBAT_TELEMETRY)
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        var tel: Dictionary = mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
        if int(tel.get("invalid_close_resolve_blocked", 0)) >= 1:
            _CombatRegressionHarness._fail(
                failures, "envelop_close_resolve_close: CLOSE mop-up must not increment invalid_close_resolve_blocked"
            )
    _CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: depth fighter lists plug_forward during envelop mop-up (multi-rank formation).


## III-4 **3e**: depth fighter lists plug_forward during envelop mop-up (multi-rank formation).
static func _run_plug_forward_listed_during_envelop_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    # Multi-rank formation: 5 files x 2 ranks for player, 1 rank for enemy.
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    # Kill 2 enemies to trigger envelop mop-up advantage.
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        _CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "plug_forward_mop_up: expected envelop mop-up active")
        _CombatRegressionHarness._free_manager(mgr)
        return
    # Find a depth fighter (rank 1) in file 0.
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if rear.is_empty():
        _CombatRegressionHarness._fail(failures, "plug_forward_mop_up: missing rank-1 fixture")
        _CombatRegressionHarness._free_manager(mgr)
        return
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rear))
    if not CombatListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_PLUG_FORWARD):
        _CombatRegressionHarness._fail(
            failures, "plug_forward_mop_up: want plug_forward listed for depth fighter during envelop mop-up"
        )
    _CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: plug_forward NOT listed when envelop mop-up is inactive.


## III-4 **3e**: plug_forward NOT listed when envelop mop-up is inactive.
static func _run_plug_forward_not_listed_without_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    # Equal force  -  no mop-up advantage. 3 files x 2 ranks.
    mgr.start({"files": 3, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 2, "density": "normal"})
    if CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "plug_forward_no_mop_up: mop-up should not be active with equal forces")
    var rear: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
    if rear.is_empty():
        _CombatRegressionHarness._fail(failures, "plug_forward_no_mop_up: missing rank-1 fixture")
        _CombatRegressionHarness._free_manager(mgr)
        return
    rear["gauge"] = 100.0
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(rear))
    if CombatListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_PLUG_FORWARD):
        _CombatRegressionHarness._fail(
            failures, "plug_forward_no_mop_up: plug_forward must NOT list when envelop mop-up inactive"
        )
    _CombatRegressionHarness._free_manager(mgr)


static func _run_envelop_mop_up_rotate_suppressed(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var wing: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var partner: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
    if wing.is_empty() or partner.is_empty():
        _CombatRegressionHarness._fail(failures, "envelop_rotate: need adjacent rank-0 wing pair")
        _CombatRegressionHarness._free_manager(mgr)
        return
    wing["gauge"] = 100.0
    partner["gauge"] = 100.0
    var wing_id: int = CombatantEntityAccess.id_int(wing)
    var acts: Array = AvailableActionsBuilder.build(mgr, wing_id)
    var reserve_only: Array = []
    for raw in acts:
        var a: Dictionary = CombatListedActions._entry(raw)
        if a.is_empty():
            continue
        var mid: String = CombatListedActions.entry_move_id(a)
        if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
            reserve_only.append(a)
        elif mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            reserve_only.append(a)
    if not CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, wing, reserve_only):
        _CombatRegressionHarness._fail(
            failures, "envelop_rotate: should_suppress when mop-up and no melee strikes in menu"
        )
    if CombatListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
        if not (
            CombatListedActions
            . first_action_move_vs_target(
                acts, CombatConstants.MOVE_ID_ROTATE_FILE, CombatantEntityAccess.id_int(partner)
            )
            . is_empty()
        ):
            _CombatRegressionHarness._fail(
                failures, "envelop_rotate: must not list rotate_file when close is listed during mop-up"
            )
    elif not CombatListedActions.action_list_has_hostile_melee_strike(acts, wing_id):
        if not (
            CombatListedActions
            . first_action_move_vs_target(
                acts, CombatConstants.MOVE_ID_ROTATE_FILE, CombatantEntityAccess.id_int(partner)
            )
            . is_empty()
        ):
            _CombatRegressionHarness._fail(
                failures, "envelop_rotate: must not list rotate_file without melee during mop-up"
            )
    _CombatRegressionHarness._free_manager(mgr)


## Post-flee sparse front: distant rank-0 holes  -  suppress **`rotate_file`** when strikes/close are listed.


## Post-flee sparse front: distant rank-0 holes  -  suppress **`rotate_file`** when strikes/close are listed.
static func _run_sparse_skirmish_line_rotate_suppressed_when_engagement_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _CombatRegressionHarness._fail(failures, "sparse_rotate: expected skirmish mode")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _CombatRegressionHarness._fail(failures, "sparse_rotate: missing rank-0 file %d" % file)
            _CombatRegressionHarness._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "sparse_rotate: want sparse line after four flee gaps")
        _CombatRegressionHarness._free_manager(mgr)
        return
    var survivor: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var partner: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 5)
    if survivor.is_empty() or partner.is_empty():
        _CombatRegressionHarness._fail(failures, "sparse_rotate: want survivors at rank-0 files 4 and 5")
        _CombatRegressionHarness._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    partner["gauge"] = 100.0
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not CombatListedActions.action_list_has_hostile_strike(acts, survivor_id):
        _CombatRegressionHarness._fail(
            failures, "sparse_rotate: want hostile strike or attempt_close listed for survivor"
        )
        _CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, survivor, acts):
        _CombatRegressionHarness._fail(failures, "sparse_rotate: should_suppress when sparse line and engagement listed")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if not (
        CombatListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, CombatantEntityAccess.id_int(partner))
        . is_empty()
    ):
        _CombatRegressionHarness._fail(failures, "sparse_rotate: rotate_file must not list on sparse post-flee line")
    _CombatRegressionHarness._free_manager(mgr)


## Sparse rank-0 at CLOSE/MID: suppress line-plug rotate even when fight_finish is false (formation menu).


## Sparse rank-0 at CLOSE/MID: suppress line-plug rotate even when fight_finish is false (formation menu).
static func _run_sparse_line_rotate_suppressed_close_band(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 6:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, file)
        if fled.is_empty():
            _CombatRegressionHarness._fail(failures, "sparse_close_band: missing flee fixture file %d" % file)
            _CombatRegressionHarness._free_manager(mgr)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    var partner: Dictionary = _CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 5)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if survivor.is_empty() or partner.is_empty() or enemy.is_empty():
        _CombatRegressionHarness._fail(failures, "sparse_close_band: missing survivor/partner/enemy")
        _CombatRegressionHarness._free_manager(mgr)
        return
    survivor["gauge"] = 100.0
    partner["gauge"] = 100.0
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(survivor, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    var acts: Array = AvailableActionsBuilder.build(mgr, survivor_id)
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        _CombatRegressionHarness._fail(failures, "sparse_close_band: want sparse line")
        _CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, survivor, acts):
        _CombatRegressionHarness._fail(failures, "sparse_close_band: want rotate suppress at CLOSE on sparse rank-0")
    if not (
        CombatListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, CombatantEntityAccess.id_int(partner))
        . is_empty()
    ):
        _CombatRegressionHarness._fail(failures, "sparse_close_band: rotate_file must not list at CLOSE on sparse line")
    _CombatRegressionHarness._free_manager(mgr)

## Sparse line: no line-plug rotate weight floor when line is sparse (distant holes).
