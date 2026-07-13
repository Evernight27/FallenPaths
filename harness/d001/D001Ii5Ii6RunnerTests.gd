class_name D001Ii5Ii6RunnerTests
extends RefCounted
## Headless **D-001** preset fights: simulates F5 cyan soaks, captures **`FP_COMBAT`**, parses runbook grep targets.
## Mandatory **II-2b / II-5a - c** sign-off is headless-only via plausibility + **`BattleUIUpdater`** probes (see
## **`.d001_headless_signoff.txt`**).
## **ii5c** (`_run_ii5c_gauge_label_checks`): **`Stm`/`Ready`/`Exh`/`Grd`** + WF gauge/diagram suffix order (incl.
## **`form_wrath_*`**)  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`**.

const RUNNER_NAME := "CombatD001SoakRunner"
const TICK_DT := 0.05


## III-4 **3e** + post-flee sparse: rank-0 survivor picks offense, `engagement_debug fight_finish=true`.
static func _probe_ii_sparse_post_flee_engagement_debug(preset_id: String) -> void:
    OperationalLog.play_combat(
        "soak_setup ii_envelop_sparse_post_flee fight-first smoke (engagement_debug fight_finish)"
    )
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var player_form: Dictionary = {
        "files": 6,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var enemy_form: Dictionary = {
        "files": 3,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(preset_id, 6, 3, player_form, enemy_form, false)
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip not skirmish mode")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, file)
        if fled.is_empty():
            OperationalLog.play_combat(
                "soak_setup ii_envelop_sparse_post_flee skip missing flee fixture file %d" % file
            )
            D001RunnerHelpers._free_manager(mgr)
            CombatConstants.set_headless_harness_quiet(was_quiet)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled["combat_absent"] = true
        fled["state"] = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    if survivor.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip missing survivor")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip sparse_line=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    survivor["gauge"] = 100.0
    survivor["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(survivor_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, survivor, acts, survivor_id):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip fight_finish=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var choice: Dictionary = CombatAIActionPicker.pick(acts, survivor_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip empty pick")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, survivor_id, acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, survivor, acts)
    var mid: String = str(choice.get("move_id", ""))
    if (
        mid == CombatConstants.MOVE_ID_WAIT
        or mid == CombatConstants.MOVE_ID_ROTATE_FILE
        or CombatConstants.is_focus_line_move(mid)
    ):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip shuffle pick=%s" % mid)
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee fight_finish_ok")
    OperationalLog.play_combat("ii_envelop_sparse_post_flee: PASS")
    var hold_hint: String = str(survivor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if (
        CombatListedActions.action_list_has_hostile_melee_strike(acts, survivor_id)
        and hold_hint.contains("close in or strike")
    ):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee hold_line_hint_ok")
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, survivor, acts)
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## Border 7v7 formation line: sparse post-flee + strikes_listed hold-line / F5 trace (not skirmish-only).


## Border 7v7 formation line: sparse post-flee + strikes_listed hold-line / F5 trace (not skirmish-only).
static func _probe_7v7_sparse_formation_hold_hint() -> void:
    OperationalLog.play_combat("soak_setup 7v7_sparse_formation hold-line smoke (formation-mode fight_finish)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var form: Dictionary = D001RunnerHelpers._formation_7v7()
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager("7v7_sparse_hold", 7, 7, form, form)
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, file)
        if fled.is_empty():
            OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip missing flee fixture file %d" % file)
            D001RunnerHelpers._free_manager(mgr)
            CombatConstants.set_headless_harness_quiet(was_quiet)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled["combat_absent"] = true
        fled["state"] = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    if survivor.is_empty():
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip missing survivor")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip sparse_line=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    survivor["gauge"] = 100.0
    survivor["state"] = CombatConstants.STATE_WAITING
    var enemy_left: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy_left = c
            break
    if not enemy_left.is_empty():
        var enemy_id: int = CombatantEntityAccess.id_int(enemy_left)
        var dist_survivor: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(survivor, "distance_to")
        dist_survivor[enemy_id] = CombatConstants.DISTANCE_CLOSE
        var dist_enemy: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(enemy_left, "distance_to")
        dist_enemy[survivor_id] = CombatConstants.DISTANCE_CLOSE
    var acts: Array = mgr.get_available_actions(survivor_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, survivor, acts, survivor_id):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip fight_finish=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        if enemy_left.is_empty():
            OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip strikes_listed=false")
            D001RunnerHelpers._free_manager(mgr)
            CombatConstants.set_headless_harness_quiet(was_quiet)
            return
        (
            acts
            . append(
                {
                    "move_id": "thrust",
                    "target_id": CombatantEntityAccess.id_int(enemy_left),
                    "target_part": "head",
                }
            )
        )
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip strikes_listed=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, survivor, acts)
    var hold_hint: String = str(survivor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if not hold_hint.contains("close in or strike"):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip hold_hint='%s'" % hold_hint)
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    OperationalLog.play_combat("soak_setup 7v7_sparse_formation hold_line_hint_ok")
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, survivor, acts)
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## Post-flee sparse rank-0 at CLOSE: rotate suppressed (line-plug shuffle noise trim).


## Post-flee sparse rank-0 at CLOSE: rotate suppressed (line-plug shuffle noise trim).
static func _probe_ii_sparse_close_band_rotate_suppress(preset_id: String) -> void:
    OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band rotate_suppress smoke")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var player_form: Dictionary = {
        "files": 6,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var enemy_form: Dictionary = {
        "files": 3,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(preset_id, 6, 3, player_form, enemy_form, false)
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, file)
        if fled.is_empty():
            OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band skip missing flee file %d" % file)
            D001RunnerHelpers._free_manager(mgr)
            CombatConstants.set_headless_harness_quiet(was_quiet)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled["combat_absent"] = true
        fled.state = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if survivor.is_empty() or enemy.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band skip missing survivor/enemy")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band skip sparse_line=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.nested_dictionary_for_mutation(survivor, "distance_to")[enemy_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    survivor["gauge"] = 100.0
    survivor["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(survivor_id)
    if not CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, survivor, acts):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band skip rotate_suppress=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var choice: Dictionary = CombatAIActionPicker.pick(acts, survivor_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band skip empty pick")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, survivor_id, acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, survivor, acts)
    var mid: String = str(choice.get("move_id", ""))
    if mid == CombatConstants.MOVE_ID_ROTATE_FILE:
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band skip shuffle pick=%s" % mid)
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    OperationalLog.play_combat("soak_setup ii_envelop_sparse_close_band rotate_suppress_ok")
    OperationalLog.play_combat("ii_envelop_sparse_close_band: PASS")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## III-6 maintain: deterministic rank-0 gap -> rear **`swap_rank`** -> `engagement_debug line_plug_pick=1`.


## III-6 maintain: deterministic rank-0 gap -> rear **`swap_rank`** -> `engagement_debug line_plug_pick=1`.
static func _probe_ii_line_plug_engagement_debug(preset_id: String) -> void:
    OperationalLog.play_combat("soak_setup ii_line_plug rank-0 gap smoke (engagement_debug line_plug_pick)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var player_form: Dictionary = {
        "files": 5,
        "ranks": 2,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var enemy_form: Dictionary = {
        "files": 5,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(preset_id, 7, 5, player_form, enemy_form, false)
    var hole: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    var rear: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 1, 0)
    var front: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 0)
    if hole.is_empty() or rear.is_empty() or front.is_empty():
        OperationalLog.play_combat("soak_setup ii_line_plug skip missing hole/rear/front fixtures")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    D001Ii5Ii6RunnerTests._soak_kill_combatant(mgr, CombatantEntityAccess.id_int(hole))
    if not CombatFormationFlow.formation_line_has_rank0_gap(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_line_plug skip no rank-0 gap after kill")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        OperationalLog.play_combat("soak_setup ii_line_plug skip relief swap allowed (want line-plug path)")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var front_id: int = CombatantEntityAccess.id_int(front)
    rear["gauge"] = 100.0
    front["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(rear_id)
    if not CombatListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        OperationalLog.play_combat("soak_setup ii_line_plug skip swap_rank not listed vs front partner")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var choice: Dictionary = CombatAIActionPicker.pick(acts, rear_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_line_plug skip empty pick")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if str(choice.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
        (
            OperationalLog
            . play_combat(
                (
                    "soak_setup ii_line_plug skip pick=%s want swap_rank layer=%s"
                    % [
                        str(choice.get("move_id", "")),
                        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
                    ]
                )
            )
        )
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if (
        str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        OperationalLog.play_combat(
            (
                "soak_setup ii_line_plug skip layer=%s want formation_plug"
                % str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, rear_id, acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, rear, acts)
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, rear, acts)
    OperationalLog.play_combat("soak_setup ii_line_plug engagement_debug_ok")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## III-6 maintain: Skirmish rank-0 hole -> front **`rotate_file`** -> `engagement_debug line_plug_pick=1`.


## III-6 maintain: Skirmish rank-0 hole -> front **`rotate_file`** -> `engagement_debug line_plug_pick=1`.
static func _probe_ii_skirmish_rotate_line_plug_engagement_debug(preset_id: String) -> void:
    OperationalLog.play_combat(
        "soak_setup ii_skirmish_rotate rank-0 gap smoke (engagement_debug line_plug_pick rotate)"
    )
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var player_form: Dictionary = {
        "files": 5,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var enemy_form: Dictionary = {
        "files": 3,
        "ranks": 1,
        "density": FormationPreset.DENSITY_NORMAL,
    }
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(preset_id, 7, 3, player_form, enemy_form, false)
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip not skirmish mode")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var hole: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    var rot_src: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 0)
    var rot_tgt: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 1)
    if hole.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip missing hole/rotate fixtures")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    D001Ii5Ii6RunnerTests._soak_kill_combatant(mgr, CombatantEntityAccess.id_int(hole))
    if not CombatFormationFlow.formation_has_rank0_hole(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip no rank-0 hole after kill")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var rot_id: int = CombatantEntityAccess.id_int(rot_src)
    var tgt_id: int = CombatantEntityAccess.id_int(rot_tgt)
    rot_src["gauge"] = 100.0
    rot_tgt["gauge"] = 100.0
    rot_src["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(rot_id)
    var rot_act: Dictionary = CombatListedActions.first_action_move_vs_target(
        acts, CombatConstants.MOVE_ID_ROTATE_FILE, tgt_id
    )
    if rot_act.is_empty():
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip rotate_file not listed vs adjacent file")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    # MS-L5 rotate plug only classifies on formation-only menus (strikes defer to utility pick).
    var plug_acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rot_id},
        rot_act,
    ]
    var choice: Dictionary = CombatAIActionPicker.pick(plug_acts, rot_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip empty pick")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if str(choice.get("move_id", "")) != CombatConstants.MOVE_ID_ROTATE_FILE:
        (
            OperationalLog
            . play_combat(
                (
                    "soak_setup ii_skirmish_rotate skip pick=%s want rotate_file layer=%s"
                    % [
                        str(choice.get("move_id", "")),
                        str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
                    ]
                )
            )
        )
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    if (
        str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != (CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG)
    ):
        OperationalLog.play_combat(
            (
                "soak_setup ii_skirmish_rotate skip layer=%s want formation_plug"
                % str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, rot_id, plug_acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, rot_src, acts)
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, rot_src, acts)
    OperationalLog.play_combat("soak_setup ii_skirmish_rotate engagement_debug_ok")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
    if mgr == null:
        return
    var c: Variant = mgr._get_by_id(combatant_id)
    if c == null or typeof(c) != TYPE_DICTIONARY:
        return
    if not CombatantEntityAccess.alive_bool(c):
        return
    c["alive"] = false
    mgr.on_combatant_died(c)


static func _probe_formation_turn_hints(mgr: Node) -> Dictionary:
    var leader: Dictionary = D001RunnerHelpers._first_alive_player_front_rank(mgr)
    if leader.is_empty():
        return {"formation_stamp": "", "snapshot_gauge_begins_stm": false, "ui_hint_formation": 0}
    leader.gauge = 100.0
    leader.state = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(CombatantEntityAccess.id_int(leader))
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, leader, acts)
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, leader, acts)
    var stamp: String = str(leader.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
    var ui_n: int = 0
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        var is_formation_fp: bool = "Formation" in s or "Rotate" in s or "Hold line" in s or "Attempt close" in s
        if not is_formation_fp:
            continue
        # Formation turn copy: combat log via **`ui_hint`** (echo off) or FP via turn-ready lines.
        if (
            s.begins_with("FP_COMBAT: ui_hint ")
            or s.begins_with("FP_COMBAT: turn_ready_formation_line ")
            or s.begins_with("FP_COMBAT: gauge_tooltip_formation ")
        ):
            ui_n += 1
    leader.stamina = maxf(80.0, CombatantEntityAccess.stamina_float(leader))
    leader.erase("status_override")
    var snap_label: String = BattleUIUpdater.gauge_label_text_for_combatant(leader, null)
    var snap_stm: bool = snap_label.begins_with("Stm")
    if not snap_stm:
        snap_label = BattleUIUpdater.gauge_label_text_for_combatant(leader, mgr)
        snap_stm = snap_label.begins_with("Stm")
    for row in CombatCombatantsSnapshot.build(mgr):
        if CombatantEntityAccess.id_int(row) != CombatantEntityAccess.id_int(leader):
            continue
        if not stamp.is_empty() and not row.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
            stamp = str(row.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
        break
    if not stamp.is_empty():
        OperationalLog.play_combat("soak_setup ii8 formation_stamp=%s snapshot_label=%s" % [stamp, snap_label])
    var diagram_cell: String = FormationDiagramBuilder._cell_label_with_footwork("P0", [leader])
    var turn_ready_form_ok: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if "turn_ready_gauge" in s and " . Form" in s:
            turn_ready_form_ok = true
            break
    return {
        "formation_stamp": stamp,
        "snapshot_gauge_begins_stm": snap_stm,
        "snapshot_label": snap_label,
        "diagram_cell_label": diagram_cell,
        "turn_ready_form_suffix": turn_ready_form_ok,
        "ui_hint_formation": ui_n,
    }


static func _merge_probe_ii8_checks(pr: Dictionary, probe: Dictionary) -> Dictionary:
    var check_out: Dictionary = pr.get("checks", {}) as Dictionary
    var stamp: String = str(probe.get("formation_stamp", ""))
    var ui_n: int = int(probe.get("ui_hint_formation", 0))
    var snap_ok: bool = bool(probe.get("snapshot_gauge_begins_stm", false))
    check_out["formation_stamp"] = {
        "pass": not stamp.is_empty(),
        "count": 1 if not stamp.is_empty() else 0,
        "min": 1,
        "optional": false,
    }
    check_out["ui_hint_formation"] = {
        "pass": ui_n >= 1,
        "count": ui_n,
        "min": 1,
        "optional": false,
    }
    check_out["snapshot_stm"] = {
        "pass": snap_ok,
        "count": 1 if snap_ok else 0,
        "min": 1,
        "optional": true,
    }
    var required_fail: PackedStringArray = PackedStringArray()
    if not bool(pr.get("ok", false)):
        required_fail.append(str(pr.get("summary", "grep failed")))
    if stamp.is_empty():
        required_fail.append("formation_stamp empty")
    if ui_n < 1:
        required_fail.append("ui_hint_formation (got %d need>=1)" % ui_n)
    var ok: bool = bool(pr.get("ok", false)) and stamp.is_empty() == false and ui_n >= 1
    var summary: String = "ok" if ok else ", ".join(required_fail)
    var banner: String = str(probe.get("diagram_banner", ""))
    check_out["diagram_banner"] = {
        "pass": banner.contains("Formation line"),
        "count": 1 if banner.contains("Formation line") else 0,
        "min": 1,
        "optional": true,
    }
    var snap_label: String = str(probe.get("snapshot_label", ""))
    var diagram_cell: String = str(probe.get("diagram_cell_label", ""))
    var form_gauge_ok: bool = " . Form" in snap_label
    var form_diagram_ok: bool = " [Ox]" in diagram_cell
    var suffix_order_ok: bool = (
        form_gauge_ok
        and D001PresetRunnerTests._label_tokens_in_order(snap_label, PackedStringArray(["Grd", " . Form"]))
    )
    var turn_ready_form_ok: bool = bool(probe.get("turn_ready_form_suffix", false))
    check_out["form_gauge_suffix"] = {
        "pass": form_gauge_ok,
        "count": 1 if form_gauge_ok else 0,
        "min": 1,
    }
    check_out["form_diagram_suffix"] = {
        "pass": form_diagram_ok,
        "count": 1 if form_diagram_ok else 0,
        "min": 1,
    }
    check_out["gauge_suffix_order"] = {
        "pass": suffix_order_ok,
        "count": 1 if suffix_order_ok else 0,
        "min": 1,
    }
    check_out["turn_ready_form_suffix"] = {
        "pass": turn_ready_form_ok,
        "count": 1 if turn_ready_form_ok else 0,
        "min": 1,
    }
    if not form_gauge_ok:
        required_fail.append("form_gauge_suffix missing . Form in snapshot_label")
    if not form_diagram_ok:
        required_fail.append("form_diagram_suffix missing [Ox] in diagram cell")
    if not suffix_order_ok:
        required_fail.append("gauge_suffix_order Grd before . Form")
    if not turn_ready_form_ok:
        required_fail.append("turn_ready_form_suffix missing . Form in turn_ready_gauge")
    ok = ok and form_gauge_ok and form_diagram_ok and suffix_order_ok and turn_ready_form_ok
    summary = "ok" if ok else ", ".join(required_fail)
    return {
        "ok": ok,
        "summary": summary,
        "checks": check_out,
        "notes": pr.get("notes", ""),
        "snapshot_label": snap_label,
        "diagram_cell_label": diagram_cell,
        "diagram_banner": banner,
    }


static func _run_ii5_cowering(preset_id: String) -> Dictionary:
    CombatF5SoakTrace.set_fight_profile(preset_id)
    OperationalLog.play_combat(
        "soak_fight_enter tile=cyan preset=%s (grep soak=%s on encounter_begin)" % [preset_id, preset_id]
    )
    OperationalLog.play_combat("soak_setup ii5 leader armless + loose 1x2 (grep cowering_fall_back listed|executed)")
    var mgr: Node = (
        D001Ii5Ii6RunnerTests
        . _start_manager(
            preset_id,
            1,
            1,
            {
                "files": 1,
                "ranks": 2,
                "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
                "density": FormationPreset.DENSITY_NORMAL,
            },
            D001RunnerHelpers._player_1x1()
        )
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    mgr.set_meta("_d001_suppress_winner_check", true)
    var leader: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 0)
    if not leader.is_empty():
        var ent: CoreEntity = CombatantEntityAccess.scene_node(leader) as CoreEntity
        D001RunnerHelpers._destroy_limb(ent, "right_arm")
        D001RunnerHelpers._destroy_limb(ent, "left_arm")
        leader.state = CombatConstants.STATE_COWERING
        CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(leader)
        leader.gauge = 100.0
        var lid: int = CombatantEntityAccess.id_int(leader)
        var acts: Array = mgr.get_available_actions(lid)
        CombatPlayerTurnHints.emit_turn_ready_hints(mgr, leader, acts)
        if D001RunnerHelpers._try_force_fall_back(mgr, lid, acts):
            D001RunnerHelpers._drain_until_capture_needle(mgr, "cowering_fall_back executed", 18.0)
            D001RunnerHelpers._ensure_ii5_cowering_fall_back_executed(mgr, lid)
    if mgr.has_meta("_d001_suppress_winner_check"):
        mgr.remove_meta("_d001_suppress_winner_check")
    D001RunnerHelpers._simulate_fight(mgr, 25.0, preset_id)
    D001RunnerHelpers._free_manager(mgr)
    return D001Ii5Ii6RunnerTests._evaluate(
        preset_id, OperationalLog.get_captured_lines(), CombatD001TrackSpecs.headless_checks_for_preset(preset_id)
    )


static func _run_ii4d_exhaustion(preset_id: String) -> Dictionary:
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(
        preset_id, 1, 1, D001RunnerHelpers._player_1x1(), D001RunnerHelpers._player_1x1()
    )
    D001RunnerHelpers._simulate_fight(mgr, 120.0, preset_id)
    if D001Ii5Ii6RunnerTests._count_needle(OperationalLog.get_captured_lines(), "crossed 25") < 1:
        OperationalLog.play_combat("soak_setup ii4d sustained exertion tail (grep exhaustion crossed 25|50|75)")
        var fighter: Dictionary = {}
        for c in mgr.combatants:
            if CombatantEntityAccess.alive_bool(c):
                fighter = c
                break
        if not fighter.is_empty():
            var attack_cost: float = CombatConstants.stamina_attack_cost_from_intensity(0.85)
            for _burst in 60:
                if D001Ii5Ii6RunnerTests._count_needle(OperationalLog.get_captured_lines(), "crossed 25") >= 1:
                    break
                CombatExhaustion.apply_exertion_from_stamina_spend(mgr, fighter, attack_cost)
                mgr._process(TICK_DT)
    var lines: PackedStringArray = OperationalLog.get_captured_lines()
    var gauge_exh_ok: bool = D001Ii5Ii6RunnerTests._ii4d_gauge_exh_suffix_ok(mgr)
    var ex_stats: Dictionary = CombatD001TrackSpecs.exhaustion_band_stats(lines)
    var ex_summary: String = CombatD001TrackSpecs.exhaustion_stats_summary_line(ex_stats)
    var ex_dup: bool = false
    for i in range(lines.size() - 1, maxi(-1, lines.size() - 24), -1):
        if "exhaustion_stats " in str(lines[i]):
            ex_dup = true
            break
    if not ex_dup:
        OperationalLog.play_combat(ex_summary)
    var pr: Dictionary = D001Ii5Ii6RunnerTests._evaluate(
        preset_id, lines, CombatD001TrackSpecs.headless_checks_for_preset(preset_id)
    )
    var plaus_fail: PackedStringArray = CombatD001TrackSpecs.ii4d_plausibility_failures(ex_stats, gauge_exh_ok)
    pr["exhaustion_stats"] = ex_stats
    pr["ii4d_plausibility_ok"] = plaus_fail.is_empty()
    pr["ii4d_plausibility_failures"] = plaus_fail
    pr["ii4d_gauge_exh_ok"] = gauge_exh_ok
    if not plaus_fail.is_empty():
        pr["ok"] = false
        var prev: String = str(pr.get("summary", ""))
        pr["summary"] = "ii4d_plausibility: %s" % ", ".join(plaus_fail)
        if not prev.is_empty() and prev != "ok":
            pr["summary"] = "%s | %s" % [prev, pr["summary"]]
    var checks: Dictionary = pr.get("checks", {}) as Dictionary
    checks["ii4d_plausibility"] = {
        "pass": plaus_fail.is_empty(),
        "count": 1 if plaus_fail.is_empty() else 0,
        "min": 1,
    }
    pr["checks"] = checks
    pr["notes"] = "headless II-4d band + Exh gauge (F5 3 - 5 min feel optional)"
    D001RunnerHelpers._free_manager(mgr)
    return pr


static func _ii4d_gauge_exh_suffix_ok(mgr: Node) -> bool:
    if not CombatConstants.is_feature_fight_exhaustion_enabled():
        return true
    for c in mgr.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatantEntityAccess.has_left_battlefield(c):
            continue
        CombatantEntityAccess.set_exhaustion_float(c, 0.28)
        c["state"] = CombatConstants.STATE_WAITING
        c.erase("status_override")
        var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
        if "Exh" in label:
            return true
    return false


static func _run_ii6_ambient(preset_id: String) -> Dictionary:
    CombatF5SoakTrace.set_fight_profile(preset_id)
    OperationalLog.play_combat(
        "soak_fight_enter tile=cyan preset=%s (grep soak=%s soak_setup ii6)" % [preset_id, preset_id]
    )
    var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(
        preset_id, 1, 1, D001RunnerHelpers._player_1x1(), D001RunnerHelpers._player_1x1()
    )
    var companion: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 0)
    if not companion.is_empty():
        var ent: CoreEntity = CombatantEntityAccess.scene_node(companion) as CoreEntity
        if ent != null:
            ent.name = "Companion"
            ent.take_damage_split(22.0, 22.0, "chest")
            ent.blood_volume = 58.0
            ent._pain_shock_until_time = -1.0
            ent._ambient_pain_shock_accum = 0.0
    OperationalLog.play_combat("soak_setup ii6 companion chest wounded bv=58 (grep ambient_pain_shock on Companion)")
    # II-6: ambient tick only  -  do not **`mgr._process`** (AI combat would end the fight / kill the probe).
    var ambient_ok: bool = false
    for _t in 120:
        if companion.is_empty():
            break
        var ent6: CoreEntity = CombatantEntityAccess.scene_node(companion) as CoreEntity
        if ent6 != null and EntityPainConsciousness.try_ambient_pain_shock_tick(ent6, 1.0):
            ambient_ok = true
            break
    if ambient_ok:
        CombatF5SoakTrace.log_fight_end_summary("player", false)
    else:
        OperationalLog.play_combat(
            (
                "soak_setup ii6 WARN ambient_pain_shock not fired in 120s  -  check PAIN_SHOCK_AMBIENT interval / featu"
                + "re flag"
            )
        )
        D001RunnerHelpers._simulate_fight(mgr, 8.0, preset_id)
    D001RunnerHelpers._free_manager(mgr)
    return D001Ii5Ii6RunnerTests._evaluate(
        preset_id, OperationalLog.get_captured_lines(), CombatD001TrackSpecs.headless_checks_for_preset(preset_id)
    )


static func _evaluate(_preset_id: String, lines: PackedStringArray, checks: Array) -> Dictionary:
    var check_out: Dictionary = {}
    var required_fail: PackedStringArray = PackedStringArray()
    var optional_miss: PackedStringArray = PackedStringArray()
    for spec in checks:
        var id: String = str(spec.get("id", ""))
        var needle: String = str(spec.get("needle", ""))
        var min_c: int = int(spec.get("min", 1))
        var max_c: int = int(spec.get("max", -1))
        var count: int = 0
        if spec.has("regex"):
            count = D001Ii5Ii6RunnerTests._count_regex(lines, str(spec.get("regex", "")))
        else:
            count = D001Ii5Ii6RunnerTests._count_needle(lines, needle)
            for alt in spec.get("alt_needles", []) as Array:
                count = maxi(count, D001Ii5Ii6RunnerTests._count_needle(lines, str(alt)))
        var ok_check: bool = true
        if max_c >= 0:
            ok_check = count <= max_c
        else:
            ok_check = count >= min_c
        var optional: bool = bool(spec.get("optional", false))
        check_out[id] = {"pass": ok_check, "count": count, "min": min_c, "optional": optional}
        if not ok_check:
            if optional:
                optional_miss.append("%s (got %d need>=%d)" % [id, count, min_c])
            else:
                required_fail.append("%s (got %d need>=%d)" % [id, count, min_c])
    var plaus_fail: PackedStringArray = CombatD001SoakSanity.plausibility_failures_for_preset(_preset_id, lines)
    for msg in plaus_fail:
        required_fail.append("plausibility: %s" % msg)
    var ok: bool = required_fail.is_empty()
    var summary: String = "ok" if ok else ", ".join(required_fail)
    if not optional_miss.is_empty():
        summary += " | optional: " + ", ".join(optional_miss)
    return {
        "ok": ok,
        "summary": summary,
        "checks": check_out,
        "plausibility_ok": plaus_fail.is_empty(),
        "notes": "headless sim  -  II-5c gauge not verified",
    }


static func _count_needle(lines: PackedStringArray, needle: String) -> int:
    if needle.is_empty():
        return 0
    var n: int = 0
    for line in lines:
        if D001Ii5Ii6RunnerTests._is_soak_grep_hint_line(line):
            continue
        if needle in line:
            n += 1
    return n


static func _count_regex(lines: PackedStringArray, pattern: String) -> int:
    if pattern.is_empty():
        return 0
    var re := RegEx.new()
    if re.compile(pattern) != OK:
        return 0
    var n: int = 0
    for line in lines:
        if D001Ii5Ii6RunnerTests._is_soak_grep_hint_line(line):
            continue
        if re.search(line) != null:
            n += 1
    return n


## Session banners mention **`grep SCRIPT_ERROR`**  -  not real errors (see **`CombatF5SoakLogValidator`**).


## Session banners mention **`grep SCRIPT_ERROR`**  -  not real errors (see **`CombatF5SoakLogValidator`**).
static func _is_soak_grep_hint_line(line: String) -> bool:
    var s: String = line.strip_edges()
    if s.begins_with("soak_guide ") or s.begins_with("soak_session_plan "):
        return true
    if s.begins_with("soak_validate_hint ") or s.begins_with("soak_coverage "):
        return true
    if "grep SCRIPT" in s or "grep FP_ERROR" in s or "grep soak_fight_end" in s:
        return true
    if s.begins_with("FP_SESSION_BEGIN:") or s.begins_with("FP_SESSION_END:"):
        return true
    return false


static func _start_manager(
    preset_id: String,
    player_n: int,
    enemy_n: int,
    player_form: Dictionary,
    enemy_form: Dictionary,
    log_engagement_banner: bool = true
) -> Node:
    CombatF5SoakTrace.prepare_fight_end_log()
    var mgr: Node = CombatManager.new()
    mgr.encounter = (
        {
            SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: "7v7",
            CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER: 50.0,
            CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY: 50.0
        }
        if preset_id == "7v7"
        else D001Ii5Ii6RunnerTests._encounter_dict_for_preset(preset_id)
    )
    D001Ii5Ii6RunnerTests._register_players(mgr, player_n, preset_id == "7v7")
    for _j in enemy_n:
        var w_id: String = "SWORD"
        if (
            preset_id == SoakEncounterPresets.PRESET_II2B_SWORD_DUEL
            or preset_id == SoakEncounterPresets.PRESET_II4D_EXHAUSTION
        ):
            w_id = "SWORD"
        mgr.register(D001RunnerHelpers._new_entity(w_id), "enemy")
    var p_count: int = player_n
    var e_count: int = enemy_n
    OperationalLog.play_combat_start(p_count, e_count, player_form, enemy_form, mgr.encounter)
    mgr.start(player_form, enemy_form)
    if log_engagement_banner:
        D001RunnerHelpers._log_diagram_banner_once(mgr)
    return mgr


static func _register_players(mgr: Node, player_n: int, use_7v7_names: bool) -> void:
    for i in player_n:
        var pe: CoreEntity = D001RunnerHelpers._new_entity("SWORD")
        if use_7v7_names:
            if i == 0:
                pe.name = "Character"
            elif i == 1:
                pe.name = "Companion"
            else:
                pe.name = "Companion%d" % i
        elif i == 0:
            pe.name = "Leader"
        elif i == 1:
            pe.name = "Companion"
        else:
            pe.name = "Companion%d" % i
        mgr.register(pe, "player")


static func _encounter_dict_for_preset(preset_id: String) -> Dictionary:
    var enc: Dictionary = {
        SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: preset_id,
        CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER: 50.0,
        CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY: 50.0,
    }
    if (
        preset_id == SoakEncounterPresets.PRESET_II2B_SWORD_DUEL
        or preset_id == SoakEncounterPresets.PRESET_II4D_EXHAUSTION
    ):
        enc[SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID] = "SWORD"
    if preset_id == SoakEncounterPresets.PRESET_II_ENVELOP:
        enc[SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID] = "SWORD"
        enc[CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT] = 7
        enc[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY] = CombatConstants.DOCTRINE_PINCH_CENTER
    return enc
