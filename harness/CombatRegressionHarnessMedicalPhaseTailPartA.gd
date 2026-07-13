class_name CombatRegressionHarnessMedicalPhaseTailPartA
extends RefCounted

## Tier 6.3 medical phase + treatment tests split from CombatRegressionHarness (compile size).

const BattleScene := preload("res://ui/BattleScene.gd")


static func _free_entity_fixture(n: Node) -> void:
    CombatRegressionHarness._free_harness_node(n)


## Medical phase: queued enemy melee and wind-up are torn down; dispatch does not resolve attacks.


## Medical phase: queued enemy melee and wind-up are torn down; dispatch does not resolve attacks.
static func _run_medical_phase_cancels_pending_enemy_melee(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ent_enemy := CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ent_enemy, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var en: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(en)
    en.state = CombatConstants.STATE_WIND_UP
    en.state_duration = 0.5
    en.pending_attack = {
        "target_id": p_id,
        "attack_type": "thrust",
        "intensity": 0.5,
        "effective_attack_line": "high",
    }
    var resolve_at: float = mgr.combat_clock + 0.1
    (
        mgr
        . _schedule_event(
            {
                "type": CombatConstants.EVENT_MELEE_ATTACK,
                "combatant_id": e_id,
                "resolve_at": resolve_at,
                "data": {},
            }
        )
    )
    var fired_box: Array = [0]
    mgr.action_resolved.connect(func(_a: int, _t: int, _r: Dictionary) -> void: fired_box[0] = int(fired_box[0]) + 1)
    mgr._end_combat_phase("player", ent_enemy)
    if not mgr.medical_phase:
        CombatRegressionHarness._fail(failures, "medical_phase_melee: expected medical_phase after player win")
        CombatRegressionHarness._free_manager(mgr)
        return
    if CombatantEntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(
            failures, "medical_phase_melee: enemy should not remain in wind_up after teardown"
        )
    if CombatantEntityAccess.state_str(en) == CombatConstants.STATE_RECOVERING:
        CombatRegressionHarness._fail(
            failures, "medical_phase_melee: enemy should not remain in recovering after teardown"
        )
    if CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_melee: pending EVENT_MELEE_ATTACK should be cancelled")
    var enemy_actions: Array = mgr.get_available_actions(e_id)
    for raw in enemy_actions:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var mid: String = str((raw as Dictionary).get("move_id", ""))
        if not CombatConstants.is_medical_move(mid) and mid != CombatConstants.MOVE_ID_WAIT:
            CombatRegressionHarness._fail(failures, "medical_phase_melee: enemy should not list combat move %s" % mid)
            break
    mgr.combat_clock = resolve_at + 0.01
    CombatEventDispatch.process_event_queue(mgr)
    if int(fired_box[0]) != 0:
        CombatRegressionHarness._fail(
            failures, "medical_phase_melee: expected no action_resolved got fired=%d" % int(fired_box[0])
        )
    if CombatantEntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(failures, "medical_phase_melee: enemy still wind_up after queued melee dispatch")
    CombatRegressionHarness._free_manager(mgr)


## After medical phase, afterblow must not resolve a losing-side wind-up.


## After medical phase, afterblow must not resolve a losing-side wind-up.
static func _run_medical_phase_blocks_afterblow_on_loser(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var en: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(en)
    en.state = CombatConstants.STATE_WIND_UP
    en.pending_attack = {
        "target_id": p_id,
        "attack_type": "thrust",
        "intensity": 0.5,
        "effective_attack_line": "high",
    }
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var fired_box: Array = [0]
    mgr.action_resolved.connect(func(_a: int, _t: int, _r: Dictionary) -> void: fired_box[0] = int(fired_box[0]) + 1)
    if AfterblowHandler.try_afterblow(mgr, p_id, e_id, {"part": "chest", "outcome": "hit", "final_cut": 1.0}, 0.2):
        CombatRegressionHarness._fail(
            failures, "medical_phase_afterblow: try_afterblow should be false for losing side"
        )
    if int(fired_box[0]) != 0:
        CombatRegressionHarness._fail(failures, "medical_phase_afterblow: expected no action_resolved")
    if not CombatantEntityAccess.nested_dictionary_read(en, "pending_attack").is_empty():
        CombatRegressionHarness._fail(failures, "medical_phase_afterblow: pending_attack should clear")
    if CombatantEntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(failures, "medical_phase_afterblow: enemy should not remain in wind_up")
    CombatRegressionHarness._free_manager(mgr)


## schedule_event / schedule_action_ready ignore losing-side combat queue entries during medical phase.


## schedule_event / schedule_action_ready ignore losing-side combat queue entries during medical phase.
static func _run_medical_phase_blocks_scheduled_enemy_events(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    CombatEventScheduler.schedule_action_ready(mgr, e_id, 0.05)
    if CombatEventScheduler.get_next_action_ready_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_schedule: enemy action_ready should not schedule")
    if CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_schedule: enemy melee should not schedule")
    (
        CombatEventScheduler
        . schedule_event(
            mgr,
            {
                "type": CombatConstants.EVENT_MELEE_ATTACK,
                "combatant_id": e_id,
                "resolve_at": mgr.combat_clock + 0.05,
                "data": {},
            }
        )
    )
    if CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(
            failures, "medical_phase_schedule: enemy melee via schedule_event should be blocked"
        )
    CombatEventScheduler.schedule_action_ready(mgr, p_id, 0.05)
    if CombatEventScheduler.get_next_action_ready_at(mgr, p_id) < 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_schedule: winner action_ready should schedule")
    CombatRegressionHarness._free_manager(mgr)


## Teardown drops queued formation resolves for the losing side.


## Teardown drops queued formation resolves for the losing side.
static func _run_medical_phase_teardown_cancels_formation_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var en: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(en)
    en.state = CombatConstants.STATE_SWAP_RANK
    en.state_duration = 2.0
    (
        CombatEventScheduler
        . schedule_event(
            mgr,
            {
                "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
                "combatant_id": e_id,
                "resolve_at": mgr.combat_clock + 0.5,
                "data": {"partner_id": -1},
            }
        )
    )
    mgr._end_combat_phase("player", CombatantEntityAccess.scene_node(en))
    if CombatantEntityAccess.state_str(en) == CombatConstants.STATE_SWAP_RANK:
        CombatRegressionHarness._fail(failures, "medical_phase_formation: enemy should leave swap_rank after teardown")
    var has_swap: bool = false
    for ev in mgr.event_queue:
        if (
            typeof(ev) == TYPE_DICTIONARY
            and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE
        ):
            has_swap = true
            break
    if has_swap:
        CombatRegressionHarness._fail(failures, "medical_phase_formation: swap_rank_resolve should be cancelled")
    CombatRegressionHarness._free_manager(mgr)


## Purge pass + wind-up start guard: only winner combat events remain schedulable.


## Purge pass + wind-up start guard: only winner combat events remain schedulable.
static func _run_medical_phase_purge_queue_and_windup_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var en: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(en)
    mgr.event_queue.clear()
    (
        CombatEventScheduler
        . schedule_event(
            mgr,
            {
                "type": CombatConstants.EVENT_MELEE_ATTACK,
                "combatant_id": e_id,
                "resolve_at": mgr.combat_clock + 0.2,
                "data": {},
            }
        )
    )
    CombatEventScheduler.schedule_action_ready(mgr, p_id, 0.3)
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    MedicalPhaseController.halt_losing_side_combat(mgr)
    if CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_purge: enemy melee should be purged from queue")
    if CombatEventScheduler.get_next_action_ready_at(mgr, p_id) < 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_purge: winner action_ready should remain in queue")
    AttackWindUpStarter.start(mgr, e_id, p_id, "thrust")
    if CombatantEntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(failures, "medical_phase_purge: losing-side wind-up start should be blocked")
    if not CombatantEntityAccess.nested_dictionary_read(en, "pending_attack").is_empty():
        CombatRegressionHarness._fail(failures, "medical_phase_purge: losing-side pending_attack should stay empty")
    CombatRegressionHarness._free_manager(mgr)


## Loser skip_turn is a no-op during medical phase (no log spam / no reschedule).


## Loser skip_turn is a no-op during medical phase (no log spam / no reschedule).
static func _run_medical_phase_skip_turn_silent_for_loser(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var en: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(en)
    en.state = CombatConstants.STATE_WAITING
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    CombatEventScheduler.cancel_pending_action_ready(mgr, e_id)
    var fired_box: Array = [0]
    mgr.action_resolved.connect(func(_a: int, _t: int, _r: Dictionary) -> void: fired_box[0] = int(fired_box[0]) + 1)
    CombatantEntityAccess.manager_skip_turn(mgr, e_id, CombatConstants.SKIP_TURN_LOG_PASS, "harness")
    if int(fired_box[0]) != 0:
        CombatRegressionHarness._fail(failures, "medical_phase_skip: loser skip_turn should not emit action_resolved")
    if CombatEventScheduler.get_next_action_ready_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(failures, "medical_phase_skip: loser skip_turn should not schedule action_ready")
    CombatRegressionHarness._free_manager(mgr)


## During medical phase the winner cannot start combat moves (thrust / wait / wind-up).


## During medical phase the winner cannot start combat moves (thrust / wait / wind-up).
static func _run_medical_phase_winner_combat_resolve_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var fired_box: Array = [0]
    mgr.action_resolved.connect(func(_a: int, _t: int, _r: Dictionary) -> void: fired_box[0] = int(fired_box[0]) + 1)
    mgr.resolve_action(p_id, e_id, "thrust", {})
    if CombatantEntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(failures, "medical_phase_winner: thrust should not start wind-up")
    mgr.resolve_action(p_id, p_id, CombatConstants.MOVE_ID_WAIT, {})
    if int(fired_box[0]) != 0:
        CombatRegressionHarness._fail(failures, "medical_phase_winner: wait should not emit during medical phase")
    AttackWindUpStarter.start(mgr, p_id, e_id, "thrust")
    if CombatantEntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(failures, "medical_phase_winner: AttackWindUpStarter.start should be blocked")
    var res: Dictionary = AttackResolver.resolve_attack(mgr, p_id)
    if str(res.get("action", "")) != "skip":
        CombatRegressionHarness._fail(
            failures, "medical_phase_winner: resolve_attack should skip got %s" % str(res.get("action", ""))
        )
    CombatRegressionHarness._free_manager(mgr)


## Winner-side action listing during medical phase must not offer combat or flee moves.


## Winner-side action listing during medical phase must not offer combat or flee moves.
static func _run_medical_phase_winner_listing_medical_only(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var medic_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(medic_ent, "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ally_ent.take_damage_split(4.0, 1.0, "chest")
    mgr.register(ally_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr._end_combat_phase("player", CombatantEntityAccess.scene_node(mgr.combatants[2]))
    var medic: Dictionary = mgr.combatants[0]
    medic.state = CombatConstants.STATE_WAITING
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var blocked_move_ids: Array[String] = [
        "thrust",
        "cut",
        "slice",
        CombatConstants.MOVE_ID_WAIT,
        CombatConstants.MOVE_ID_FLEE,
        CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
        CombatConstants.MOVE_ID_FALL_BACK,
        CombatConstants.MOVE_ID_SWAP_RANK,
    ]
    var actions: Array = AvailableActionsBuilder.build(mgr, medic_id)
    for a in actions:
        var mid: String = str(a.get("move_id", ""))
        if mid in blocked_move_ids:
            CombatRegressionHarness._fail(
                failures, "medical_phase_winner_listing: blocked move_id '%s' in %s" % [mid, str(actions)]
            )
    CombatRegressionHarness._free_manager(mgr)


## AttackResultApplier must not apply combat outcomes during medical phase.


## AttackResultApplier must not apply combat outcomes during medical phase.
static func _run_medical_phase_apply_result_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var fired_box: Array = [0]
    mgr.action_resolved.connect(func(_a: int, _t: int, _r: Dictionary) -> void: fired_box[0] = int(fired_box[0]) + 1)
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "hit", "target_id": p_id, "recovery_duration": 0.5, "result_dict": {"died": false}}
    )
    if int(fired_box[0]) != 0:
        CombatRegressionHarness._fail(
            failures, "medical_phase_applier: apply_result should not emit during medical phase"
        )
    CombatRegressionHarness._free_manager(mgr)


## Second `_end_combat_phase("player")` refreshes teardown without re-emitting `enemies_eliminated`.


## Second `_end_combat_phase("player")` refreshes teardown without re-emitting `enemies_eliminated`.
static func _run_medical_phase_end_combat_idempotent(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var en: Dictionary = mgr.combatants[1]
    en.state = CombatConstants.STATE_WIND_UP
    en.pending_attack = {
        "target_id": CombatantEntityAccess.id_int(mgr.combatants[0]), "attack_type": "thrust", "intensity": 0.5
    }
    (
        mgr
        . _schedule_event(
            {
                "type": CombatConstants.EVENT_MELEE_ATTACK,
                "combatant_id": e_id,
                "resolve_at": mgr.combat_clock + 0.2,
                "data": {},
            }
        )
    )
    var emit_box: Array = [0]
    mgr.enemies_eliminated.connect(func(_w: String) -> void: emit_box[0] = int(emit_box[0]) + 1)
    mgr._end_combat_phase("player", null)
    if not mgr.medical_phase:
        CombatRegressionHarness._fail(failures, "medical_phase_idempotent: expected medical_phase after first end")
    mgr._end_combat_phase("player", null)
    if int(emit_box[0]) != 1:
        CombatRegressionHarness._fail(
            failures, "medical_phase_idempotent: enemies_eliminated should emit once got %d" % int(emit_box[0])
        )
    if CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
        CombatRegressionHarness._fail(
            failures, "medical_phase_idempotent: loser melee should stay cancelled after refresh"
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 6.2: winner fled before medical phase  -  clear **`combat_absent`**, suspend bleed, list triage.


## Tier 6.2: winner fled before medical phase  -  clear **`combat_absent`**, suspend bleed, list triage.
static func _run_medical_phase_winner_fled_suspends_bleed_tick(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var c: Dictionary = mgr.combatants[0]
    c["combat_absent"] = true
    c.state = CombatConstants.STATE_FLED
    mgr._end_combat_phase("player", null)
    if bool(c.get("combat_absent", false)):
        CombatRegressionHarness._fail(failures, "med_phase_fled: winner combat_absent should clear for medical listing")
    if not bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
        CombatRegressionHarness._fail(failures, "med_phase_fled: winner should suspend bleed ticks after fleeing")
    if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_FLED:
        CombatRegressionHarness._fail(failures, "med_phase_fled: winner should leave STATE_FLED for medical listing")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        CombatRegressionHarness._fail(
            failures, "med_phase_fled: want STATE_WAITING for triage got %s" % CombatantEntityAccess.state_str(c)
        )
    if not CombatantEntityAccess.is_alive_in_combat(c):
        CombatRegressionHarness._fail(failures, "med_phase_fled: fled winner should list medical actions")
    CombatRegressionHarness._free_manager(mgr)


## Fled winner with active bleed: medical tick must not drain blood while suspend flag is set.


## Fled winner with active bleed: medical tick must not drain blood while suspend flag is set.
static func _run_medical_phase_fled_winner_bleed_suspended_on_tick(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var c: Dictionary = mgr.combatants[0]
    var node: Node = CombatantEntityAccess.scene_node(c)
    if node == null or not ("blood_volume" in node):
        CombatRegressionHarness._fail(failures, "med_phase_bleed_suspend: missing scene node blood")
        CombatRegressionHarness._free_manager(mgr)
        return
    node.take_damage_split(6.0, 2.0, "chest")
    if EntityWounds.get_total_bleeding_rate(node) <= 0.0:
        CombatRegressionHarness._fail(failures, "med_phase_bleed_suspend: need active bleed on chest wound")
        CombatRegressionHarness._free_manager(mgr)
        return
    node._set_combat_blood_loss_mult(1.0)
    node._set_combat_blood_recovery_per_s(0.0)
    var bv_before: float = float(node.blood_volume)
    c["combat_absent"] = true
    c.state = CombatConstants.STATE_FLED
    mgr._end_combat_phase("player", null)
    CombatProcessTick.tick(mgr, 2.0)
    if float(node.blood_volume) < bv_before - 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "med_phase_bleed_suspend: blood %.2f should not drop from %.2f on tick"
                % [float(node.blood_volume), bv_before]
            )
        )
    c.erase(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK)
    CombatProcessTick.tick(mgr, 2.0)
    if float(node.blood_volume) >= bv_before - 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "med_phase_bleed_suspend: blood should drain after suspend flag cleared (still %.2f)"
                % float(node.blood_volume)
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Winner who stayed on field: medical phase must keep bleed ticks (urgency / triage pressure).


## Winner who stayed on field: medical phase must keep bleed ticks (urgency / triage pressure).
static func _run_medical_phase_non_fled_winner_bleed_continues_on_tick(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var c: Dictionary = mgr.combatants[0]
    var node: Node = CombatantEntityAccess.scene_node(c)
    if node == null or not ("blood_volume" in node):
        CombatRegressionHarness._fail(failures, "med_phase_bleed_continue: missing scene node blood")
        CombatRegressionHarness._free_manager(mgr)
        return
    node.take_damage_split(6.0, 2.0, "chest")
    if EntityWounds.get_total_bleeding_rate(node) <= 0.0:
        CombatRegressionHarness._fail(failures, "med_phase_bleed_continue: need active bleed on chest wound")
        CombatRegressionHarness._free_manager(mgr)
        return
    node._set_combat_blood_loss_mult(1.0)
    node._set_combat_blood_recovery_per_s(0.0)
    var bv_before: float = float(node.blood_volume)
    mgr._end_combat_phase("player", null)
    if bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
        CombatRegressionHarness._fail(
            failures, "med_phase_bleed_continue: non-fled winner must not suspend bleed ticks"
        )
    CombatProcessTick.tick(mgr, 2.0)
    if float(node.blood_volume) >= bv_before - 0.01:
        CombatRegressionHarness._fail(
            failures,
            "med_phase_bleed_continue: blood should drop from %.2f (still %.2f)" % [bv_before, float(node.blood_volume)]
        )
    CombatRegressionHarness._free_manager(mgr)


## Combat stop tears down suspend_bleed_tick so overworld bleed is not frozen on reused dicts.


## Combat stop tears down suspend_bleed_tick so overworld bleed is not frozen on reused dicts.
static func _run_medical_phase_stop_clears_suspend_bleed_tick(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var c: Dictionary = mgr.combatants[0]
    c["combat_absent"] = true
    c.state = CombatConstants.STATE_FLED
    mgr._end_combat_phase("player", null)
    if not bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
        CombatRegressionHarness._fail(
            failures, "med_phase_stop: setup want suspend_bleed_tick after fled medical entry"
        )
    mgr.stop()
    if bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
        CombatRegressionHarness._fail(failures, "med_phase_stop: stop() should erase suspend_bleed_tick")
    CombatRegressionHarness._free_manager(mgr)


## Medical log: ally bandage uses clear procedure label (not bare **`bandage_self`**).


## Medical log: ally bandage uses clear procedure label (not bare **`bandage_self`**).
static func _run_combat_log_formatter_bandage_ally_label(failures: PackedStringArray) -> void:
    var line: String = (
        CombatLogFormatter
        . format_action_line(
            "Alice",
            "player",
            "Bob",
            "player",
            {
                "outcome": "bandaged",
                "part": "left_leg",
                "effectiveness": 1.0,
                "medical_move_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
                "medical_target_is_self": false,
            }
        )
    )
    if not line.contains("bandage (ally)"):
        CombatRegressionHarness._fail(failures, "bandage_ally_log: want bandage (ally) got '%s'" % line)
    if not line.contains("Bob"):
        CombatRegressionHarness._fail(failures, "bandage_ally_log: want target name in line")


static func _harness_wound_chest_for_packing(ent: Node) -> void:
    if ent == null:
        return
    # Thoracic cut at moderate+ (>=25% of chest max) so pack eligibility is stable; keep damage below vital collapse.
    EntityWounds.add_wound(
        ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
    )


## Hold compression when fixture still bleeds so dress/pack gates match TCCC production paths.


## Hold compression when fixture still bleeds so dress/pack gates match TCCC production paths.
static func _harness_hold_pressure_if_bleeding(ent: Node, part: String) -> void:
    if ent == null or part.is_empty():
        return
    if EntityWounds.get_bleeding_rate_for_part(ent, part) <= BleedingConstants.BLEEDING_RATE_EPSILON:
        return
    if EntityMedical.has_direct_pressure_on_part(ent, part):
        return
    if not ent.apply_direct_pressure(part):
        push_warning("harness: could not hold pressure on %s for dressing fixture" % part)


## Tier 6.1: **`pack_wound`** legal only on **`PACKING_PARTS`** with open wounds.


## Tier 6.1: **`pack_wound`** legal only on **`PACKING_PARTS`** with open wounds.
static func _run_pack_wound_strict_subregion_eligibility(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 5.0, "neck", BleedingConstants.SEVERITY_MODERATE
    )
    if ent.wounds.get("head", []).size() > 0:
        ent.wounds["head"][0]["is_arterial"] = false
    if ent.can_apply_packing("head"):
        CombatRegressionHarness._fail(
            failures, "pack_wound_strict: moderate non-arterial neck should not allow packing"
        )
    ent.wounds["head"].clear()
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 5.0, "neck", BleedingConstants.SEVERITY_MODERATE
    )
    if ent.wounds["head"].size() != 1:
        CombatRegressionHarness._fail(failures, "pack_wound_strict: expected one neck wound")
    else:
        ent.wounds["head"][0]["is_arterial"] = true
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_hold_pressure_if_bleeding(ent, "head")
    if not ent.can_apply_packing("head"):
        CombatRegressionHarness._fail(failures, "pack_wound_strict: moderate arterial neck should allow packing")
    ent.wounds["head"].clear()
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 12.0, "neck", BleedingConstants.SEVERITY_SEVERE
    )
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_hold_pressure_if_bleeding(ent, "head")
    if not ent.can_apply_packing("head"):
        CombatRegressionHarness._fail(failures, "pack_wound_strict: severe neck should allow packing when linen ok")
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_pack_wound_can_apply_on_chest_wound(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_wound_chest_for_packing(ent)
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_hold_pressure_if_bleeding(ent, "chest")
    if not ent.can_apply_packing("chest"):
        CombatRegressionHarness._fail(failures, "pack_wound_can: chest wound should allow packing")
    if ent.can_apply_packing("left_arm"):
        CombatRegressionHarness._fail(failures, "pack_wound_can: left_arm not a packing part")
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_pack_wound_blocked_when_already_packed(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_wound_chest_for_packing(ent)
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_hold_pressure_if_bleeding(ent, "chest")
    seed(88201)
    var ok: bool = ent._apply_packing("chest", 1.5)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if not ok:
        CombatRegressionHarness._fail(failures, "pack_wound_packed: setup apply_packing should succeed")
    if ent.can_apply_packing("chest"):
        CombatRegressionHarness._fail(failures, "pack_wound_packed: should not pack twice")
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_pack_wound_lists_in_medical_phase(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ent_enemy: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ent_enemy, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally: Dictionary = mgr.combatants[1]
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent == null:
        CombatRegressionHarness._fail(failures, "pack_wound_list: need ally entity")
        CombatRegressionHarness._free_manager(mgr)
        return
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_wound_chest_for_packing(ally_ent)
    mgr._end_combat_phase("player", ent_enemy)
    if not mgr.medical_phase:
        CombatRegressionHarness._fail(failures, "pack_wound_list: expected medical_phase")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.combatants[0]["gauge"] = 100.0
    mgr.combatants[0].state = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(healer_id)
    var found_pressure: bool = false
    var found_pack: bool = false
    for raw in acts:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if int(a.get("target_id", -1)) != CombatantEntityAccess.id_int(ally):
            continue
        if str(a.get("target_part", "")) != "chest":
            continue
        var mid: String = str(a.get("move_id", ""))
        if CombatConstants.is_direct_pressure_move(mid):
            found_pressure = true
        elif CombatConstants.is_pack_wound_move(mid):
            found_pack = true
    CombatRegressionHarness._free_manager(mgr)
    if not found_pressure:
        CombatRegressionHarness._fail(
            failures, "pack_wound_list: actively bleeding chest should list apply_direct_pressure first"
        )
    if found_pack:
        CombatRegressionHarness._fail(
            failures, "pack_wound_list: pack_wound should not list before pressure on active chest bleed"
        )


static func _run_bandage_allowed_on_packed_part(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_wound_chest_for_packing(ent)
    CombatRegressionHarnessMedicalPhaseTailPartA._harness_hold_pressure_if_bleeding(ent, "chest")
    seed(88203)
    var packed: bool = ent._apply_packing("chest", 1.5)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if not packed:
        CombatRegressionHarness._fail(failures, "bandage_packed: setup packing should succeed")
    # Packing clears pressure and reduces bleed rate; simulate clotting so compression gate clears.
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(60.0)
    if not ent._can_apply_bandage("chest"):
        CombatRegressionHarness._fail(failures, "bandage_packed: should allow outer bandage over pack")
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_direct_pressure_held_suppresses_bleed_rate(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(6.0, 2.0, "right_arm")
    if not ent.wounds.has("right_arm"):
        CombatRegressionHarness._fail(failures, "direct_pressure_held: need arm wound")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    # Venous compressible bleed: arterial retained-flow (~50%) is intentionally weaker than this gate.
    for injury in ent.wounds["right_arm"]:
        injury["is_arterial"] = false
        injury["current_bleeding_rate"] = float(
            injury.get("base_bleeding_rate", injury.get("current_bleeding_rate", 0.0))
        )
    var raw: float = EntityWounds.get_bleeding_rate_for_part(ent, "right_arm")
    if raw <= BleedingConstants.BLEEDING_RATE_EPSILON:
        CombatRegressionHarness._fail(failures, "direct_pressure_held: wound should bleed before pressure")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    if not ent.apply_direct_pressure("right_arm"):
        CombatRegressionHarness._fail(failures, "direct_pressure_held: apply_direct_pressure failed")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    var held: float = EntityWounds.get_bleeding_rate_for_part(ent, "right_arm")
    if held >= raw * 0.4:
        CombatRegressionHarness._fail(
            failures,
            "direct_pressure_held: expected strong suppression while held got raw=%.3f held=%.3f" % [raw, held]
        )
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_direct_pressure_release_rebleeds_without_dressing(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(6.0, 2.0, "left_leg")
    if not ent.wounds.has("left_leg"):
        CombatRegressionHarness._fail(failures, "direct_pressure_rebound: need leg wound")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    ent.apply_direct_pressure("left_leg")
    var held: float = EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
    EntityMedical.release_direct_pressure_on_part(ent, "left_leg")
    var after: float = EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
    if after <= held + BleedingConstants.BLEEDING_RATE_EPSILON:
        CombatRegressionHarness._fail(failures, "direct_pressure_rebound: expected higher bleed after early release")
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


## III-5: multi-channel cavity pack scales success by **`PACKING_SUCCESS_PER_EXTRA_CHANNEL`** (depth / complexity).


## III-5: multi-channel cavity pack scales success by **`PACKING_SUCCESS_PER_EXTRA_CHANNEL`** (depth / complexity).
static func _run_iii5_packing_channel_success_depth(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.linen_strips_remaining = BleedingConstants.PACKING_LINEN_PARTY_START
    EntityWounds.add_wound(
        ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 8.0, "upper_thorax", BleedingConstants.SEVERITY_MODERATE
    )
    EntityWounds.add_wound(
        ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 8.0, "lower_thorax", BleedingConstants.SEVERITY_MODERATE
    )
    var channels: int = EntityMedical.get_treatment_channel_count(ent, "chest")
    if channels < 2:
        CombatRegressionHarness._fail(failures, "iii5_pack_depth: want 2+ treatment channels got %d" % channels)
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    var mult: float = EntityMedical.packing_channel_success_mult(ent, "chest")
    var want: float = pow(BleedingConstants.PACKING_SUCCESS_PER_EXTRA_CHANNEL, float(channels - 1))
    if absf(mult - want) > 0.001:
        CombatRegressionHarness._fail(
            failures, "iii5_pack_depth: want mult=%.3f got %.3f (channels=%d)" % [want, mult, channels]
        )
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_treatment_channel_count_not_raw_hit_count(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    for _i in 6:
        EntityWounds.add_wound(
            ent, "head", BleedingConstants.INJURY_TYPE_CUT, 2.0, "scalp", BleedingConstants.SEVERITY_MODERATE
        )
    if ent.wounds.get("head", []).size() != 1:
        CombatRegressionHarness._fail(failures, "treatment_channels: merge should leave one injury row")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    var channels: int = EntityMedical.get_treatment_channel_count(ent, "head")
    if channels != 1:
        CombatRegressionHarness._fail(
            failures, "treatment_channels: expected 1 channel for one sub_region got %d" % channels
        )
    var pack_s: float = EntityMedical._get_packing_application_time_seconds_for_part(ent, "head")
    var raw_pack: float = (
        BleedingConstants.PACKING_APPLICATION_TIME_SECONDS + BleedingConstants.PACKING_PER_WOUND_EXTRA_SECONDS * 5.0
    )
    if pack_s >= raw_pack - 0.01:
        CombatRegressionHarness._fail(
            failures, "treatment_channels: channel pack %.1f should beat six-hit raw %.1f" % [pack_s, raw_pack]
        )
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_failed_dressing_retains_direct_pressure(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.6, "severity": "moderate"},
    ]
    if not ent.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "failed_dressing_retain: pressure setup failed")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    if ent._apply_bandage("chest", 0.0):
        CombatRegressionHarness._fail(failures, "failed_dressing_retain: zero-eff bandage should fail")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    if not EntityMedical.has_direct_pressure_on_part(ent, "chest"):
        CombatRegressionHarness._fail(failures, "failed_dressing_retain: failed bandage must keep direct pressure")
    ent.bandaged_parts.erase("chest")
    ent.linen_strips_remaining = 4
    ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    if ent._apply_packing("chest", 0.0):
        CombatRegressionHarness._fail(failures, "failed_dressing_retain: zero-eff packing should fail")
        CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)
        return
    if not EntityMedical.has_direct_pressure_on_part(ent, "chest"):
        CombatRegressionHarness._fail(failures, "failed_dressing_retain: failed packing must keep direct pressure")
    CombatRegressionHarnessMedicalPhaseTailPartA._free_entity_fixture(ent)


static func _run_dressings_blocked_without_pressure_when_bleeding(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var ally_ent := CombatRegressionHarness._new_entity("SWORD")
    var healer_ent := CombatRegressionHarness._new_entity("SWORD")
    ally_ent.take_damage_split(8.0, 3.0, "head")
    mgr.register(healer_ent, "player")
    mgr.register(ally_ent, "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer_c: Dictionary = mgr.combatants[0]
    var ally_c: Dictionary = mgr.combatants[1]
    if MedicalPhaseController.dressings_allowed_for_part(mgr, ally_c, "head"):
        CombatRegressionHarness._fail(failures, "dressings_gate: should block dressings on active unheld head bleed")
        return
    var acts: Array = MedicalPhaseController.get_ally_medical_actions(mgr, healer_c, ally_c, "head")
    var mids: Array = []
    for raw in acts:
        if raw is Dictionary:
            mids.append(str((raw as Dictionary).get("move_id", "")))
    if CombatConstants.MOVE_ID_BANDAGE_SELF in mids or CombatConstants.MOVE_ID_PACK_WOUND in mids:
        CombatRegressionHarness._fail(failures, "dressings_gate: bandage/pack listed without pressure")
    CombatRegressionHarness._free_manager(mgr)


static func _run_dressings_still_offered_after_failure_out_of_peril(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var ally_ent := CombatRegressionHarness._new_entity("SWORD")
    var healer_ent := CombatRegressionHarness._new_entity("SWORD")
    ally_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.05, "base_bleeding_rate": 0.4, "severity": "moderate"},
    ]
    ally_ent.apply_direct_pressure("chest")
    mgr.register(healer_ent, "player")
    mgr.register(ally_ent, "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer_c: Dictionary = mgr.combatants[0]
    var ally_c: Dictionary = mgr.combatants[1]
    ally_c["failed_medical_parts"] = ["chest"]
    if not MedicalPhaseController.has_left_immediate_peril_permanently(mgr, ally_c):
        CombatRegressionHarness._fail(
            failures, "dressings_retry: ally should be out of immediate peril for this fixture"
        )
        return
    if not MedicalPhaseController.dressings_allowed_for_part(mgr, ally_c, "chest"):
        CombatRegressionHarness._fail(
            failures, "dressings_retry: must still allow dressings after failed attempt when out of peril"
        )
        return
    var acts: Array = MedicalPhaseController.get_ally_medical_actions(mgr, healer_c, ally_c, "chest")
    var mids: Array = []
    for raw in acts:
        if raw is Dictionary:
            mids.append(str((raw as Dictionary).get("move_id", "")))
    if CombatConstants.MOVE_ID_BANDAGE_SELF not in mids:
        CombatRegressionHarness._fail(
            failures, "dressings_retry: bandage_self should stay listed after failure (got %s)" % str(mids)
        )
    CombatRegressionHarness._free_manager(mgr)


static func _run_pending_retry_set_even_with_other_medics(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var ally_ent := CombatRegressionHarness._new_entity("SWORD")
    var healer_a := CombatRegressionHarness._new_entity("SWORD")
    var healer_b := CombatRegressionHarness._new_entity("SWORD")
    ally_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.4, "severity": "moderate"},
    ]
    ally_ent.apply_direct_pressure("chest")
    mgr.register(healer_a, "player")
    mgr.register(healer_b, "player")
    mgr.register(ally_ent, "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer_ac: Dictionary = mgr.combatants[0]
    var healer_bc: Dictionary = mgr.combatants[1]
    var ally_c: Dictionary = mgr.combatants[2]
    CombatMedicalCoordination.track_failure_and_maybe_retry(
        mgr, healer_ac, ally_c, "chest", CombatantEntityAccess.id_int(ally_c)
    )
    var pending: Variant = healer_ac.get("pending_retry", null)
    if typeof(pending) != TYPE_DICTIONARY or (pending as Dictionary).is_empty():
        CombatRegressionHarness._fail(
            failures, "pending_retry: performer should keep retry hint after dressing failure"
        )
    elif (pending as Dictionary).get("part", "") != "chest":
        CombatRegressionHarness._fail(failures, "pending_retry: expected chest part in retry hint")
    var failed: Variant = ally_c.get("failed_medical_parts", null)
    if not (failed is Array) or "chest" not in (failed as Array):
        CombatRegressionHarness._fail(failures, "pending_retry: failed_medical_parts should track chest")
    CombatRegressionHarness._free_manager(mgr)


static func _run_medical_ai_prefers_dressing_over_stabilize_out_of_peril(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var healer_ent := CombatRegressionHarness._new_entity("SWORD")
    var ally_ent := CombatRegressionHarness._new_entity("SWORD")
    ally_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.08, "severity": "moderate"},
    ]
    ally_ent.apply_direct_pressure("chest")
    mgr.register(healer_ent, "player")
    mgr.register(ally_ent, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    if MedicalPhaseController.is_in_immediate_peril(mgr, mgr.combatants[1]):
        CombatRegressionHarness._fail(failures, "medical_ai_dressing: fixture should be out of immediate peril")
        CombatRegressionHarness._free_manager(mgr)
        return
    var bandage_act: Dictionary = {
        "move_id": "bandage_self",
        "target_id": ally_id,
        "target_part": "chest",
    }
    var stab_act: Dictionary = {
        "move_id": "stabilize_wound",
        "target_id": ally_id,
        "target_part": "chest",
    }
    var w_bandage: float = CombatAIActionPicker._get_medical_weight(bandage_act, healer_id, mgr)
    var w_stab: float = CombatAIActionPicker._get_medical_weight(stab_act, healer_id, mgr)
    if w_bandage <= w_stab:
        CombatRegressionHarness._fail(
            failures,
            "medical_ai_dressing: bandage weight %.3f should exceed stabilize %.3f out of peril" % [w_bandage, w_stab]
        )
    CombatRegressionHarness._free_manager(mgr)
