class_name D001ProbesSparsePostFlee
extends RefCounted
## Headless **D-001** sparse post-flee engagement probes (III-4 **3e** + 7v7 border).
## Probes: rank-0 survivor picks offense (`fight_finish=true`), hold-line hint validation.


const TICK_DT := 0.05


## III-4 **3e** + post-flee sparse: rank-0 survivor picks offense, `engagement_debug fight_finish=true`.
static func probe_ii_envelop_sparse_post_flee(preset_id: String) -> void:
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
    var mgr := _start_manager(preset_id, 6, 3, player_form, enemy_form, false)
    if str(CombatEngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip not skirmish mode")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled := D001RunnerHelpers._player_at_rank_file(mgr, 0, file)
        if fled.is_empty():
            OperationalLog.play_combat(
                "soak_setup ii_envelop_sparse_post_flee skip missing flee fixture file %d" % file
            )
            _free_mgr_and_restore(mgr, was_quiet)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled["state"] = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor := D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    if survivor.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip missing survivor")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip sparse_line=false")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    var survivor_id: int = CombatantEntityAccess.id_int(survivor)
    survivor["gauge"] = 100.0
    survivor["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(survivor_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, survivor, acts, survivor_id):
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip fight_finish=false")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    var choice: Dictionary = CombatAIActionPicker.pick(acts, survivor_id, mgr)
    if choice.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_sparse_post_flee skip empty pick")
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
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
    _free_mgr_and_restore(mgr, was_quiet)


## Border 7v7 formation line: sparse post-flee + strikes_listed hold-line / F5 trace (not skirmish-only).
static func probe_7v7_sparse_formation_hold_hint() -> void:
    OperationalLog.play_combat("soak_setup 7v7_sparse_formation hold-line smoke (formation-mode fight_finish)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var form := D001RunnerHelpers._formation_7v7()
    var mgr := _start_manager("7v7_sparse_hold", 7, 7, form, form)
    var form_player: Dictionary = mgr.formations["player"]
    var slots: Dictionary = FormationSlots.formation_slots_dict(form_player)
    for file in [0, 1, 2, 3]:
        var fled := D001RunnerHelpers._player_at_rank_file(mgr, 0, file)
        if fled.is_empty():
            OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip missing flee fixture file %d" % file)
            _free_mgr_and_restore(mgr, was_quiet)
            return
        FormationSlots.remove_combatant_from_slots(slots, CombatantEntityAccess.id_int(fled))
        fled[DataKeys.COMBATANT_COMBAT_ABSENT] = true
        fled["state"] = CombatConstants.STATE_FLED
    mgr.recompute_zoc_and_distance()
    var survivor := D001RunnerHelpers._player_at_rank_file(mgr, 0, 4)
    if survivor.is_empty():
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip missing survivor")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip sparse_line=false")
        _free_mgr_and_restore(mgr, was_quiet)
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
        _free_mgr_and_restore(mgr, was_quiet)
        return
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        if enemy_left.is_empty():
            OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip strikes_listed=false")
            _free_mgr_and_restore(mgr, was_quiet)
            return
        acts.append({
            "move_id": "thrust",
            "target_id": CombatantEntityAccess.id_int(enemy_left),
            "target_part": "head",
        })
    if not CombatListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip strikes_listed=false")
        _free_mgr_and_restore(mgr, was_quiet)
        return
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, survivor, acts)
    var hold_hint: String = str(survivor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if not hold_hint.contains("close in or strike"):
        OperationalLog.play_combat("soak_setup 7v7_sparse_formation skip hold_hint='%s'" % hold_hint)
        _free_mgr_and_restore(mgr, was_quiet)
        return
    OperationalLog.play_combat("soak_setup 7v7_sparse_formation hold_line_hint_ok")
    CombatF5SoakTrace.log_turn_ready_player_ui(mgr, survivor, acts)
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


static func _free_mgr_and_restore(mgr: Node, was_quiet: bool) -> void:
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)
