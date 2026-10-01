class_name HoldLineHintMopUpTests

extends MentalStackFormationPlugBase

## Hold-line hint mop-up: mop-up listing, rear-rank mop-up + strike listing,
## and back-rank-not-mop-up gating.


static func _run_hold_line_hint_mop_up(failures: PackedStringArray) -> void:
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
        _fail(failures, "hold_line_hint_mop_up: missing center/enemy fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "hold_line_hint_mop_up: want mop-up hint got '%s'" % hint)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up hold-line hint when listed melee strikes finish the last enemy.

## III-4 **3e**: mop-up hold-line hint when listed melee strikes finish the last enemy.


static func _run_hold_line_hint_mop_up_strikes_listed(failures: PackedStringArray) -> void:
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
        _fail(failures, "hold_line_hint_mop_up_strikes: missing center/enemy fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "hold_line_hint_mop_up_strikes: want mop-up hint got '%s'" % hint)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up beats generic back-rank copy.

## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up beats generic back-rank copy.


static func _run_hold_line_hint_mop_up_rear_rank(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 14:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        HarnessFixtures._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if rear.is_empty() or enemy.is_empty():
        _fail(failures, "hold_line_hint_mop_up_rear: missing rear/enemy fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "hold_line_hint_mop_up_rear: want mop-up hint got '%s'" % hint)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## III-4 **3e**: rear rank with listed strikes during mop-up gets strike-finish mop-up copy.

## III-4 **3e**: rear rank with listed strikes during mop-up gets strike-finish mop-up copy.


static func _run_hold_line_hint_mop_up_rear_rank_strikes(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 14:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        HarnessFixtures._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if rear.is_empty() or enemy.is_empty():
        _fail(failures, "hold_line_hint_mop_up_rear_strikes: missing rear/enemy fixtures")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "hold_line_hint_mop_up_rear_strikes: want strike mop-up hint got '%s'" % hint)
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Back rank reserve-only when not mop-up stays generic back-rank copy.

## Back rank reserve-only when not mop-up stays generic back-rank copy.


static func _run_hold_line_hint_back_rank_not_mopup(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 14:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 1, 3)
    if rear.is_empty():
        _fail(failures, "hold_line_hint_back_rank: missing rear fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
    ]
    var hint: String = PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
    if hint.is_empty() or not hint.begins_with("Back rank"):
        _fail(failures, "hold_line_hint_back_rank: want back-rank copy got '%s'" % hint)
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## MS-L5: rank-0 gap -> rear **`swap_rank`** beats listed strikes; stamps **`formation_plug`**.

## MS-L5: rank-0 gap -> rear **`swap_rank`** beats listed strikes; stamps **`formation_plug`**.
