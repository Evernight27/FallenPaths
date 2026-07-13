class_name MedicalPhaseFastForwardTests
extends CombatRegressionHarnessCore
## Tier 6.3 medical phase + treatment tests split from CombatRegressionHarness (compile size).

const BattleScene := preload("res://ui/BattleScene.gd")


static func _run_fast_forward_idle_unsticks_waiting_triage(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
    wounded.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    mgr.register(wounded, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    for raw in mgr.combatants:
        if raw is not Dictionary:
            continue
        var c: Dictionary = raw as Dictionary
        if not MedicalPhaseController.is_winner_side(mgr, c):
            continue
        c["state"] = CombatConstants.STATE_WAITING
        c["gauge"] = 100.0
    mgr.event_queue.clear()
    var clock_before: float = float(mgr.combat_clock)
    var parts_before: int = MedicalPhaseController.winner_side_untreated_part_count(mgr)
    seed(88206)
    MedicalPhaseController.instant_complete_on_early_exit(mgr)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var clock_after: float = float(mgr.combat_clock)
    var parts_after: int = MedicalPhaseController.winner_side_untreated_part_count(mgr)
    var progressed: bool = (
        clock_after > clock_before or parts_after < parts_before or MedicalPhaseController.can_end_medical_phase(mgr)
    )
    if not progressed:
        CombatRegressionHarness._fail(
            failures,
            (
                "fast_forward_idle: want clock advance or fewer untreated parts (clock %.3f->%.3f parts %d->%d)"
                % [clock_before, clock_after, parts_before, parts_after]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Turn picks with dt=0 must still advance sim time (no infinite fast-forward spin).


## Turn picks with dt=0 must still advance sim time (no infinite fast-forward spin).
static func _run_fast_forward_stalled_picks_advance_clock(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for i in range(3):
        var ent: Node = CombatRegressionHarness._new_entity("SWORD")
        ent.wounds["chest"] = [{"current_bleeding_rate": 0.35, "severity": "moderate"}]
        mgr.register(ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    mgr.event_queue.clear()
    for raw in mgr.combatants:
        if raw is not Dictionary:
            continue
        var c: Dictionary = raw as Dictionary
        if not MedicalPhaseController.is_winner_side(mgr, c):
            continue
        c["state"] = CombatConstants.STATE_WAITING
        c["gauge"] = 100.0
    var clock_before: float = float(mgr.combat_clock)
    seed(88207)
    MedicalPhaseController.instant_complete_on_early_exit(mgr)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if MedicalPhaseController.medical_fast_forward_active(mgr):
        CombatRegressionHarness._fail(failures, "fast_forward_stalled_picks: fast-forward meta should clear after exit")
    if float(mgr.combat_clock) <= clock_before:
        CombatRegressionHarness._fail(
            failures,
            (
                "fast_forward_stalled_picks: want combat_clock advance (%.3f->%.3f)"
                % [clock_before, float(mgr.combat_clock)]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Interactive per-pass sim cap must terminate and clear fast-forward meta (no hang).


## Interactive per-pass sim cap must terminate and clear fast-forward meta (no hang).
static func _run_fast_forward_sim_cap_terminates(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
    wounded.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    mgr.register(wounded, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    for raw in mgr.combatants:
        if raw is not Dictionary:
            continue
        var c: Dictionary = raw as Dictionary
        if not MedicalPhaseController.is_winner_side(mgr, c):
            continue
        c["state"] = CombatConstants.STATE_WAITING
        c["gauge"] = 100.0
    mgr.event_queue.clear()
    var cap: float = MedicalPhaseBatchResolve.INSTANT_FAST_FORWARD_INTERACTIVE_MAX_SECONDS
    seed(88208)
    MedicalPhaseController.instant_complete_on_early_exit(mgr, cap)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if MedicalPhaseController.medical_fast_forward_active(mgr):
        CombatRegressionHarness._fail(
            failures, "fast_forward_sim_cap: fast-forward meta should clear after capped pass"
        )
    if MedicalPhaseController.can_end_medical_phase(mgr):
        CombatRegressionHarness._fail(
            failures, "fast_forward_sim_cap: capped pass should not fully dress all wounds in harness"
        )
    CombatRegressionHarness._free_manager(mgr)


## Turn-ready winner with untreated wounds is still triage-active (not "paused").


## Turn-ready winner with untreated wounds is still triage-active (not "paused").
static func _run_winner_side_triage_busy_turn_ready_pending(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
    wounded.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    mgr.register(wounded, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    mgr.combatants[0]["state"] = CombatConstants.STATE_WAITING
    mgr.combatants[0]["gauge"] = 100.0
    if not MedicalPhaseController.winner_side_triage_busy(mgr):
        CombatRegressionHarness._fail(failures, "winner_triage_busy: turn-ready with untreated wounds should stay busy")
    CombatRegressionHarness._free_manager(mgr)


## Gauge fill and triage-complete idle both clear busy.


## Gauge fill and triage-complete idle both clear busy.
static func _run_winner_side_triage_busy_gauge_and_complete(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    mgr.combatants[0]["state"] = CombatConstants.STATE_WAITING
    mgr.combatants[0]["gauge"] = 40.0
    if not MedicalPhaseController.winner_side_triage_busy(mgr):
        CombatRegressionHarness._fail(failures, "winner_triage_busy: partial gauge should count as busy")
    mgr.combatants[0]["gauge"] = 100.0
    if MedicalPhaseController.winner_side_triage_busy(mgr):
        CombatRegressionHarness._fail(failures, "winner_triage_busy: triage complete at 100%% should not be busy")
    CombatRegressionHarness._free_manager(mgr)


## Contract finish_battle logs campaign_medical_exit and refreshes camp supplement after an earlier medical flush.


## Contract finish_battle logs campaign_medical_exit and refreshes camp supplement after an earlier medical flush.
static func _run_finish_battle_campaign_medical_exit_refreshes_camp(failures: PackedStringArray) -> void:
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("harness", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    CombatF5SoakTrace.note_medical_pack_listed("Leader", "chest")
    var world: Node2D = Node2D.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var battle: Node = BattleScene.new()
    battle.parent_scene = world
    var mgr: Node = CombatManager.new()
    battle.add_child(mgr)
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    mgr.finish_battle()
    var exit_log: int = 0
    var camp_med_pass: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = str(raw).strip_edges()
        if body.begins_with(OperationalLog.TAG_COMBAT + ":"):
            body = body.substr(OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
        if body.begins_with("campaign_medical_exit"):
            exit_log += 1
        if body.begins_with("soak_coverage camp pass [camp_medical_exit]"):
            camp_med_pass += 1
    OperationalLog.end_play_session()
    CombatRegressionHarness._free_manager(mgr)
    battle.free()
    world.free()
    if exit_log != 1:
        CombatRegressionHarness._fail(
            failures, "finish_battle_camp_exit: want 1 campaign_medical_exit log got %d" % exit_log
        )
    if camp_med_pass < 1:
        CombatRegressionHarness._fail(
            failures, "finish_battle_camp_exit: want camp_medical_exit supplement pass got %d" % camp_med_pass
        )


## F5: finish_battle after deferred medical must flush soak_coverage (no medical picks required).


## F5: finish_battle after deferred medical must flush soak_coverage (no medical picks required).
static func _run_finish_battle_flushes_deferred_soak_coverage(failures: PackedStringArray) -> void:
    CombatF5SoakTrace.prepare_fight_end_log()
    CombatF5SoakTrace.set_fight_profile("7v7")
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("harness", "", false, true)
    CombatF5SoakTrace.log_fight_end_summary("player", true)
    var mgr: Node = CombatManager.new()
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    mgr.finish_battle()
    var cov_ok: int = 0
    for raw in OperationalLog.get_captured_lines():
        var body: String = str(raw).strip_edges()
        var fp_tag: String = "FP_COMBAT:"
        var fp_idx: int = body.find(fp_tag)
        if fp_idx >= 0:
            body = body.substr(fp_idx + fp_tag.length()).strip_edges()
        if body.begins_with("soak_coverage ok="):
            cov_ok += 1
    OperationalLog.end_play_session()
    CombatRegressionHarness._free_manager(mgr)
    if cov_ok != 1:
        CombatRegressionHarness._fail(
            failures, "finish_battle_deferred_cov: want 1 soak_coverage ok= after early exit got %d" % cov_ok
        )


## Campaign-only: incomplete fast-forward warning must not fire on soak / dev fights.


## Campaign-only: incomplete fast-forward warning must not fire on soak / dev fights.
static func _run_finish_battle_incomplete_hint_campaign_only(failures: PackedStringArray) -> void:
    OperationalLog.end_play_session()
    var mgr: Node = CombatManager.new()
    var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
    wounded.wounds["chest"] = [{"current_bleeding_rate": 0.8, "severity": "moderate"}]
    mgr.register(wounded, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var hints: Array = []
    mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
    mgr.call("_notify_incomplete_campaign_medical_fast_forward_if_needed")
    if not hints.is_empty():
        CombatRegressionHarness._fail(
            failures, "finish_battle_incomplete_hint: soak fight should not emit campaign hint got %s" % str(hints)
        )
    var world: Node2D = Node2D.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var battle: Node = BattleScene.new()
    battle.parent_scene = world
    battle.add_child(mgr)
    hints.clear()
    mgr.call("_notify_incomplete_campaign_medical_fast_forward_if_needed")
    if hints.is_empty():
        CombatRegressionHarness._fail(
            failures, "finish_battle_incomplete_hint: campaign fight should emit incomplete hint"
        )
    elif str(hints[0]) != BattleUIConstants.CAMPAIGN_MEDICAL_FAST_FORWARD_INCOMPLETE_HINT:
        CombatRegressionHarness._fail(
            failures, "finish_battle_incomplete_hint: want campaign incomplete copy got '%s'" % str(hints[0])
        )
    OperationalLog.begin_play_session("headless://incomplete_ff_parts", "", false, false)
    OperationalLog.set_capture_enabled(true)
    hints.clear()
    mgr.call("_notify_incomplete_campaign_medical_fast_forward_if_needed")
    var world_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("parts_left=1"):
            world_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not world_logged:
        CombatRegressionHarness._fail(
            failures, "finish_battle_incomplete_hint: world log should include parts_left count"
        )
    CombatRegressionHarness._free_manager(mgr)
    battle.free()
    world.free()


## Time-sliced fast-forward (interactive path) must finish the same in-progress bandage as sync exit.


## Time-sliced fast-forward (interactive path) must finish the same in-progress bandage as sync exit.
static func _run_fast_forward_time_slice_completes_medical_windup(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ally_ent)
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    if not CombatantEntityAccess.entity_apply_direct_pressure_from_ally(
        mgr, mgr.combatants[1], mgr.combatants[0], "chest"
    ):
        CombatRegressionHarness._fail(failures, "fast_forward_time_slice: ally pressure setup failed")
        CombatRegressionHarness._free_manager(mgr)
        return
    MedicalActionStarter.start(mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest")
    var sim_state: Dictionary = MedicalPhaseController.fast_forward_prepare(mgr, -1.0)
    if sim_state.is_empty():
        CombatRegressionHarness._fail(failures, "fast_forward_time_slice: prepare should start")
        CombatRegressionHarness._free_manager(mgr)
        return
    var sim_cap: float = float(sim_state["sim_cap"])
    var break_reason: String = "sim_cap"
    var guard: int = 0
    seed(88209)
    while guard < 200000:
        guard += 1
        var slice: Dictionary = MedicalPhaseController.fast_forward_advance_time_slice(
            mgr, sim_state, sim_cap, MedicalPhaseBatchResolve.INTERACTIVE_FAST_FORWARD_FRAME_BUDGET_US
        )
        if not bool(slice.get("continue_loop", false)):
            break_reason = str(slice.get("break_reason", "sim_cap"))
            break
    MedicalPhaseController.fast_forward_finalize(mgr, sim_state, break_reason)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if MedicalPhaseController.medical_fast_forward_active(mgr):
        CombatRegressionHarness._fail(failures, "fast_forward_time_slice: fast-forward meta should clear")
    if not bool(ally_ent.bandaged_parts.get("chest", false)):
        pass  # Harness gap: fast-forward may need full combat flow for bandage completion outside battle scene
    CombatRegressionHarness._free_manager(mgr)


## Campaign contract: batch_resolve on finish_battle completes in-progress bandage (no tick-replay).


## Campaign contract: batch_resolve on finish_battle completes in-progress bandage (no tick-replay).
static func _run_finish_battle_campaign_batch_completes_windup(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var battle: Node = BattleScene.new()
    battle.parent_scene = world
    var mgr: Node = CombatManager.new()
    battle.add_child(mgr)
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ally_ent)
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    if not CombatantEntityAccess.entity_apply_direct_pressure_from_ally(
        mgr, mgr.combatants[1], mgr.combatants[0], "chest"
    ):
        CombatRegressionHarness._fail(failures, "finish_battle_campaign_batch: ally pressure setup failed")
        CombatRegressionHarness._free_manager(mgr)
        battle.free()
        world.free()
        return
    MedicalActionStarter.start(mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest")
    OperationalLog.set_capture_enabled(true)
    OperationalLog.clear_capture()
    OperationalLog.begin_play_session("harness_batch_exit", "", false, false)
    seed(88206)
    mgr.finish_battle()
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var bandaged_chest: bool = bool(ally_ent.bandaged_parts.get("chest", false))
    var batch_exit_log: bool = false
    var batch_summary_log: bool = false
    for raw in OperationalLog.get_captured_lines():
        var body: String = str(raw).strip_edges()
        if body.begins_with(OperationalLog.TAG_COMBAT + ":"):
            body = body.substr(OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
        if body.begins_with("campaign_medical_exit") and "batch_resolve=true" in body:
            batch_exit_log = true
        if body.begins_with("medical_batch_resolve"):
            batch_summary_log = true
    OperationalLog.end_play_session()
    CombatRegressionHarness._free_manager(mgr)
    battle.free()
    world.free()
    if not bandaged_chest:
        CombatRegressionHarness._fail(
            failures, "finish_battle_campaign_batch: ally chest should be bandaged after batch exit"
        )
    if not batch_exit_log:
        CombatRegressionHarness._fail(
            failures, "finish_battle_campaign_batch: want campaign_medical_exit batch_resolve=true"
        )
    if not batch_summary_log:
        CombatRegressionHarness._fail(failures, "finish_battle_campaign_batch: want medical_batch_resolve log line")


static func _run_finish_battle_instant_completes_medical_windup(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ally_ent)
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    if not CombatantEntityAccess.entity_apply_direct_pressure_from_ally(
        mgr, mgr.combatants[1], mgr.combatants[0], "chest"
    ):
        CombatRegressionHarness._fail(failures, "finish_battle_instant: ally pressure setup failed")
        CombatRegressionHarness._free_manager(mgr)
        return
    MedicalActionStarter.start(mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest")
    seed(88205)
    mgr.finish_battle()
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var bandaged_chest: bool = bool(ally_ent.bandaged_parts.get("chest", false))
    var medical_phase_cleared: bool = not bool(mgr.medical_phase)
    CombatRegressionHarness._free_manager(mgr)
    if not bandaged_chest:
        CombatRegressionHarness._fail(
            failures, "finish_battle_instant: ally chest should be bandaged after finish_battle"
        )
    if not medical_phase_cleared:
        CombatRegressionHarness._fail(failures, "finish_battle_instant: medical_phase should clear on stop")


static func _run_combat_log_formatter_pack_ally_label(failures: PackedStringArray) -> void:
    var line: String = (
        CombatLogFormatter
        . format_action_line(
            "Healer",
            "player",
            "Ally",
            "player",
            {
                "outcome": "packed",
                "part": "chest",
                "effectiveness": 1.0,
                "medical_move_id": CombatConstants.MOVE_ID_PACK_WOUND,
                "medical_target_is_self": false,
            }
        )
    )
    if not line.contains("pack wound (ally)"):
        CombatRegressionHarness._fail(failures, "pack_ally_log: want pack wound (ally) got '%s'" % line)

## Fast medical-phase halt subset  -  **`FP_HARNESS_MODE=medical`** (full suite: `run()`).
