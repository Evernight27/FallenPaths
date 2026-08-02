class_name D001ProbesLinePlug
extends RefCounted
## Headless **D-001** line-plug engagement probes (III-6 maintain).
## Probes: deterministic rank-0 gap → rear `swap_rank` / front `rotate_file`.


const TICK_DT := 0.05


## III-6 maintain: deterministic rank-0 gap -> rear **`swap_rank`** -> `engagement_debug line_plug_pick=1`.
static func probe_ii_line_plug(preset_id: String) -> void:
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
    var mgr := _start_manager(preset_id, 7, 5, player_form, enemy_form, false)
    var hole := D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    var rear := D001RunnerHelpers._player_at_rank_file(mgr, 1, 0)
    var front := D001RunnerHelpers._player_at_rank_file(mgr, 0, 0)
    if hole.is_empty() or rear.is_empty() or front.is_empty():
        OperationalLog.play_combat("soak_setup ii_line_plug skip missing hole/rear/front fixtures")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    _soak_kill_combatant(mgr, CombatantEntityAccess.id_int(hole))
    if not CombatFormationFlow.formation_line_has_rank0_gap(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_line_plug skip no rank-0 gap after kill")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    if CombatAIActionPicker.is_relief_swap_tactically_allowed(rear, front):
        OperationalLog.play_combat("soak_setup ii_line_plug skip relief swap allowed (want line-plug path)")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var front_id: int = CombatantEntityAccess.id_int(front)
    rear["gauge"] = 100.0
    front["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(rear_id)
    if not CombatListedActions.actions_include_move_vs_target(acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK):
        OperationalLog.play_combat("soak_setup ii_line_plug skip swap_rank not listed vs front partner")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    var choice: Dictionary = CombatAIActionPicker.pick(acts, rear_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_line_plug skip empty pick")
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
        return
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, rear_id, acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, rear, acts)
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, rear, acts)
    OperationalLog.play_combat("soak_setup ii_line_plug engagement_debug_ok")
    _free_mgr_and_restore(mgr, was_quiet)


## III-6 maintain: Skirmish rank-0 hole -> front **`rotate_file`** -> `engagement_debug line_plug_pick=1`.
static func probe_ii_skirmish_rotate(preset_id: String) -> void:
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
    var mgr := _start_manager(preset_id, 7, 3, player_form, enemy_form, false)
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip not skirmish mode")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    var hole := D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    var rot_src := D001RunnerHelpers._player_at_rank_file(mgr, 0, 0)
    var rot_tgt := D001RunnerHelpers._player_at_rank_file(mgr, 0, 1)
    if hole.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip missing hole/rotate fixtures")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    _soak_kill_combatant(mgr, CombatantEntityAccess.id_int(hole))
    if not CombatFormationFlow.formation_has_rank0_hole(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip no rank-0 hole after kill")
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
        return
    # MS-L5 rotate plug only classifies on formation-only menus (strikes defer to utility pick).
    var plug_acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rot_id},
        rot_act,
    ]
    var choice: Dictionary = CombatAIActionPicker.pick(plug_acts, rot_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_skirmish_rotate skip empty pick")
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
        return
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, rot_id, plug_acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, rot_src, acts)
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, rot_src, acts)
    OperationalLog.play_combat("soak_setup ii_skirmish_rotate engagement_debug_ok")
    _free_mgr_and_restore(mgr, was_quiet)


static func _start_manager(
    preset_id: String,
    player_n: int,
    enemy_n: int,
    player_form: Dictionary,
    enemy_form: Dictionary,
    log_engagement_banner: bool = true
) -> Node:
    CombatF5SoakTrace.prepare_fight_end_log()
    var mgr := CombatManager.new()
    mgr.encounter = (
        {
            SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: "7v7",
            CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER: 50.0,
            CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY: 50.0
        }
        if preset_id == "7v7"
        else D001Ii5Ii6RunnerTests._encounter_dict_for_preset(preset_id)
    )
    _register_players(mgr, player_n, preset_id == "7v7")
    for _j in enemy_n:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
    var p_count: int = player_n
    var e_count: int = enemy_n
    OperationalLog.play_combat_start(p_count, e_count, player_form, enemy_form, mgr.encounter)
    mgr.start(player_form, enemy_form)
    if log_engagement_banner:
        D001RunnerHelpers._log_diagram_banner_once(mgr)
    return mgr


static func _register_players(mgr: Node, player_n: int, use_7v7_names: bool) -> void:
    for i in player_n:
        var pe := CoreEntity.new()
        pe.apply_species_harness_deterministic()
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
        var w := HarnessFixtures.get_cached_weapon("SWORD")
        if w != null:
            pe.equip_weapon(w)
        CombatRegressionHarness._track_harness_node(pe)
        mgr.register(pe, "player")


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


static func _free_mgr_and_restore(mgr: Node, was_quiet: bool) -> void:
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)
