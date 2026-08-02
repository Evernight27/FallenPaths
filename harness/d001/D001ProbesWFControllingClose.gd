class_name D001ProbesWFControllingClose
extends RefCounted
## WF-M3 optional F5 grep: `controlling_close_list` when `attempt_close` vs Fool at long.


## WF-M3 optional F5 grep: `controlling_close_list` when `attempt_close` vs Fool at long.
static func probe_wf_controlling_close_turn_hint() -> void:
    OperationalLog.play_combat("soak_setup wf_controlling_close_hint fool defender at long (WF-M3 F5 grep)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var mgr: Node = CombatManager.new()
    mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "soak_probe")
    player["gauge"] = 100.0
    player["state"] = CombatConstants.STATE_WAITING
    enemy["gauge"] = 100.0
    var dist_p: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")
    var dist_e: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")
    dist_p[e_id] = CombatConstants.DISTANCE_LONG
    dist_e[p_id] = CombatConstants.DISTANCE_LONG
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
    ]
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, player, acts)
    if not str(player.get(CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT, "")).is_empty():
        OperationalLog.play_combat("soak_setup wf_controlling_close_hint ok")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)
