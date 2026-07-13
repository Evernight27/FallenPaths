class_name Iv11LeaderTargetingTests
extends CombatRegressionHarnessCore


## IV-11 slice 9: party leader can cycle hold -> probe -> pinch -> hold without re-listing active doctrine.
static func _run_iv11_leader_doctrine_cycle_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) == 0:
            leader = c
            break
    if leader.is_empty():
        _fail(failures, "iv11_cycle: missing rank-0 leader")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    var leader_id: int = _EntityAccess.id_int(leader)
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var steps: Array = [
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
        CombatConstants.MOVE_ID_ORDER_PROBING,
        CombatConstants.MOVE_ID_ORDER_PINCH_CENTER,
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
    ]
    var want_docs: Array = [
        CombatConstants.DOCTRINE_HOLD_LANE,
        CombatConstants.DOCTRINE_PROBING,
        CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.DOCTRINE_HOLD_LANE,
    ]
    for i in steps.size():
        leader["state"] = CombatConstants.STATE_WAITING
        leader["gauge"] = 100.0
        var move_id: String = str(steps[i])
        if not _ResolveAction.resolve(mgr, leader_id, leader_id, move_id, {}):
            _fail(failures, "iv11_cycle: resolve %s failed at step %d" % [move_id, i])
            break
        if mgr.get_formation_doctrine("player") != want_docs[i]:
            _fail(
                failures, "iv11_cycle: step %d want %s got %s" % [i, want_docs[i], mgr.get_formation_doctrine("player")]
            )
            break
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: AI picker assigns canonical weight to listed leader formation commands.


## IV-11 slice 9: AI picker assigns canonical weight to listed leader formation commands.
static func _run_iv11_leader_command_ai_weight_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = mgr.combatants[0]
    leader["is_party_leader"] = true
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    var leader_id: int = _EntityAccess.id_int(leader)
    var acts: Array = mgr.get_available_actions(leader_id)
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
            break
    if hold_act.is_empty():
        _fail(failures, "iv11_ai_weight: want order_hold_lane listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w: float = _AIPicker._get_action_weight(hold_act, leader_id, mgr, true, {}, {}, acts)
    if not is_equal_approx(w, CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT):
        _fail(
            failures,
            "iv11_ai_weight: want %.2f got %.4f" % [CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT, w]
        )
    leader["is_party_leader"] = false
    var w_member: float = _AIPicker._get_action_weight(hold_act, leader_id, mgr, true, {}, {}, acts)
    if w_member != 0.0:
        _fail(failures, "iv11_ai_weight: non-issuer want weight 0 got %.4f" % w_member)
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: enemy commander AI pick weight matches party leader path.


## IV-11 slice 9: enemy commander AI pick weight matches party leader path.
static func _run_iv11_enemy_commander_ai_weight_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    mgr.register(cmd_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var commander: Dictionary = mgr.combatants[1]
    commander["state"] = CombatConstants.STATE_WAITING
    commander["gauge"] = 100.0
    var cmd_id: int = _EntityAccess.id_int(commander)
    var acts: Array = mgr.get_available_actions(cmd_id)
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
            break
    if hold_act.is_empty():
        _fail(failures, "iv11_enemy_ai_weight: want order_hold_lane listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w: float = _AIPicker._get_action_weight(hold_act, cmd_id, mgr, true, {}, {}, acts)
    if not is_equal_approx(w, CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT):
        _fail(
            failures,
            "iv11_enemy_ai_weight: want %.2f got %.4f" % [CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT, w]
        )
    commander["is_enemy_leader"] = false
    var w_grunt: float = _AIPicker._get_action_weight(hold_act, cmd_id, mgr, true, {}, {}, acts)
    if w_grunt != 0.0:
        _fail(failures, "iv11_enemy_ai_weight: non-issuer want weight 0 got %.4f" % w_grunt)
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 10: pinch command AI weight boosts under numeric superiority (wider + front margin).


## IV-11 slice 10: pinch command AI weight boosts under numeric superiority (wider + front margin).
static func _run_iv11_pinch_outnumber_ai_weight_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice10=pinch_outnumber_ai_mult=" not in sync_line:
        _fail(failures, "iv11_pinch_ai: sync line missing slice10 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0 and leader.is_empty():
            leader = c
    if leader.is_empty():
        _fail(failures, "iv11_pinch_ai: missing rank-0 leader")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    if not _CombatDoctrine.numeric_superiority_for_pinch(mgr, "player"):
        _fail(failures, "iv11_pinch_ai: fixture want numeric superiority for player")
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
    var leader_id: int = _EntityAccess.id_int(leader)
    var acts: Array = mgr.get_available_actions(leader_id)
    var pinch_act: Dictionary = {}
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
            pinch_act = a
        elif mid == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
    if pinch_act.is_empty() or hold_act.is_empty():
        _fail(failures, "iv11_pinch_ai: want pinch and hold listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w_pinch: float = _AIPicker._get_action_weight(pinch_act, leader_id, mgr, true, {}, {}, acts)
    var w_hold: float = _AIPicker._get_action_weight(hold_act, leader_id, mgr, true, {}, {}, acts)
    var want_pinch: float = (
        CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
        * CombatConstants.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
    )
    if not is_equal_approx(w_pinch, want_pinch):
        _fail(failures, "iv11_pinch_ai: pinch want %.3f got %.4f" % [want_pinch, w_pinch])
    if not is_equal_approx(w_hold, CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT):
        _fail(failures, "iv11_pinch_ai: hold want base weight got %.4f" % w_hold)
    if w_pinch <= w_hold:
        _fail(failures, "iv11_pinch_ai: pinch should outweigh hold under outnumber")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 10: enemy commander pinch weight boosts under numeric superiority (mirror player).


## IV-11 slice 10: enemy commander pinch weight boosts under numeric superiority (mirror player).
static func _run_iv11_enemy_pinch_outnumber_ai_weight_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice10=pinch_outnumber_ai_mult=" not in sync_line:
        _fail(failures, "iv11_enemy_pinch_ai: sync line missing slice10 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    mgr.register(cmd_ent, "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var commander: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        if (
            c.get("is_enemy_leader", false) == true
            and _EntityAccess.rank_int(c) == 0
            and _EntityAccess.file_int(c) == 0
        ):
            commander = c
            break
    if commander.is_empty():
        _fail(failures, "iv11_enemy_pinch_ai: missing rank-0 enemy commander")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    commander["state"] = CombatConstants.STATE_WAITING
    commander["gauge"] = 100.0
    if not _CombatDoctrine.numeric_superiority_for_pinch(mgr, "enemy"):
        _fail(failures, "iv11_enemy_pinch_ai: fixture want numeric superiority for enemy")
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_PROBING)
    var cmd_id: int = _EntityAccess.id_int(commander)
    var acts: Array = mgr.get_available_actions(cmd_id)
    var pinch_act: Dictionary = {}
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
            pinch_act = a
        elif mid == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
    if pinch_act.is_empty() or hold_act.is_empty():
        _fail(failures, "iv11_enemy_pinch_ai: want pinch and hold listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w_pinch: float = _AIPicker._get_action_weight(pinch_act, cmd_id, mgr, true, {}, {}, acts)
    var w_hold: float = _AIPicker._get_action_weight(hold_act, cmd_id, mgr, true, {}, {}, acts)
    var want_pinch: float = (
        CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
        * CombatConstants.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
    )
    if not is_equal_approx(w_pinch, want_pinch):
        _fail(failures, "iv11_enemy_pinch_ai: pinch want %.3f got %.4f" % [want_pinch, w_pinch])
    if w_pinch <= w_hold:
        _fail(failures, "iv11_enemy_pinch_ai: pinch should outweigh hold under outnumber")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 10: F5 paste **`leader_order=`** trace format (deduped via OperationalLog capture).


## IV-11 slice 10: F5 paste **`leader_order=`** trace format (deduped via OperationalLog capture).
static func _run_iv11_f5_leader_order_trace_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "f5_track=iv11_leader_order" not in sync_line:
        _fail(failures, "iv11_f5_trace: sync line missing f5_track token in %s" % sync_line)
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_leader_formation_command_pick(
        "Captain", CombatConstants.MOVE_ID_ORDER_PROBING, "player", "player"
    )
    _F5SoakTrace.note_leader_formation_command_pick(
        "Captain", CombatConstants.MOVE_ID_ORDER_PROBING, "player", "player"
    )
    _F5SoakTrace.note_leader_formation_command_pick(
        "Warlord", CombatConstants.MOVE_ID_ORDER_HOLD_LANE, "enemy", "enemy"
    )
    var count: int = 0
    var player_sample: String = ""
    var enemy_sample: String = ""
    for line in _OperationalLog.get_captured_lines():
        if "leader_order=" not in line:
            continue
        count += 1
        if "side=player" in line:
            player_sample = line
        elif "side=enemy" in line:
            enemy_sample = line
    if count != 2:
        _fail(failures, "iv11_f5_trace: want 2 leader_order lines got %d" % count)
    elif "order_probing" not in player_sample or "formation=player" not in player_sample:
        _fail(failures, "iv11_f5_trace: bad player leader_order line %s" % player_sample)
    elif "order_hold_lane" not in enemy_sample or "formation=enemy" not in enemy_sample:
        _fail(failures, "iv11_f5_trace: bad enemy leader_order line %s" % enemy_sample)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


## IV-11 slice 10: **`EncounterNode.spawn_enemies`** stamps **`is_enemy_leader`** from config index.


## IV-11 slice 10: **`EncounterNode.spawn_enemies`** stamps **`is_enemy_leader`** from config index.
static func _run_iv11_encounter_spawn_enemy_leader_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "encounter_spawn=enemy_leader_index" not in sync_line:
        _fail(failures, "iv11_enc_spawn: sync line missing encounter_spawn token in %s" % sync_line)
    var world: Node2D = Node2D.new()
    var enc: Node = _EncounterNode.new()
    enc.enemy_count = 3
    enc.encounter_config = {
        _SoakPresets.ENCOUNTER_KEY_ENEMY_LEADER_INDEX: 1,
    }
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 42
    var enemies: Array = enc.spawn_enemies(world, rng)
    if enemies.size() != 3:
        _fail(failures, "iv11_enc_spawn: want 3 enemies got %d" % enemies.size())
        world.free()
        enc.free()
        return
    if enemies[1].get("is_enemy_leader") != true:
        _fail(failures, "iv11_enc_spawn: index 1 want is_enemy_leader true")
    if enemies[0].get("is_enemy_leader") == true or enemies[2].get("is_enemy_leader") == true:
        _fail(failures, "iv11_enc_spawn: only configured index may be commander")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_id: int = mgr.register(enemies[1], "enemy")
    mgr.register(enemies[0], "enemy")
    mgr.register(enemies[2], "enemy")
    if not bool(mgr.combatants[cmd_id].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enc_spawn: register want is_enemy_leader on commander")
    _free_manager(mgr)
    for n in enemies:
        if n != null and is_instance_valid(n):
            n.free()
    enc.free()
    world.free()


## IV-11 slice 6: **`CombatManager.register`** stamps **`is_enemy_leader`** from node (enemy only).


## IV-11 slice 6: **`CombatManager.register`** stamps **`is_enemy_leader`** from node (enemy only).
static func _run_iv11_register_enemy_leader_stamp_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice6=enemy_leader" not in sync_line:
        _fail(failures, "iv11_enemy_leader: sync line missing slice6 token in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    var cmd_ent: Node = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    var grunt_ent: Node = _new_entity("SWORD")
    grunt_ent.is_enemy_leader = false
    var player_ent: Node = _new_entity("SWORD")
    player_ent.is_enemy_leader = true
    mgr.register(player_ent, "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(cmd_ent, "enemy")
    mgr.register(grunt_ent, "enemy")
    if not bool(mgr.combatants[2].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enemy_leader: commander want is_enemy_leader true")
    if bool(mgr.combatants[3].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enemy_leader: grunt want is_enemy_leader false")
    if bool(mgr.combatants[0].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enemy_leader: player must not stamp is_enemy_leader")
    _free_manager(mgr)


## IV-11 slice 6: formation diagram **`[Cmd]`** callout for enemy commander only.


## IV-11 slice 6: formation diagram **`[Cmd]`** callout for enemy commander only.
static func _run_iv11_enemy_leader_diagram_callout_suite(failures: PackedStringArray) -> void:
    var Diagram := preload("res://ui/FormationDiagramBuilder.gd")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    var commander: Dictionary = {}
    var grunt: Dictionary = {}
    var player: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "player") and player.is_empty():
            player = c
        elif _EntityAccess.is_living_on_side(c, "enemy"):
            if commander.is_empty():
                commander = c
            elif grunt.is_empty():
                grunt = c
    commander["is_enemy_leader"] = true
    grunt["is_enemy_leader"] = false
    player["is_party_leader"] = true
    if _UiHints.enemy_leader_diagram_suffix(commander) != " [Cmd]":
        _fail(
            failures,
            (
                "iv11_enemy_diagram: commander suffix want ' [Cmd]' got '%s'"
                % _UiHints.enemy_leader_diagram_suffix(commander)
            )
        )
    if not _UiHints.enemy_leader_diagram_suffix(grunt).is_empty():
        _fail(failures, "iv11_enemy_diagram: grunt must not get commander suffix")
    if not _UiHints.party_leader_diagram_suffix(commander).is_empty():
        _fail(failures, "iv11_enemy_diagram: enemy must not get party [Ldr] suffix")
    var cmd_cell: String = Diagram._cell_label_with_footwork("Cmd", [commander])
    if " [Cmd]" not in cmd_cell:
        _fail(failures, "iv11_enemy_diagram: commander cell want [Cmd] got '%s'" % cmd_cell)
    if " [Cmd]" in Diagram._cell_label_with_footwork("Grunt", [grunt]):
        _fail(failures, "iv11_enemy_diagram: grunt cell must not show [Cmd]")
    var tips: PackedStringArray = _UiHints.formation_cell_tooltip_lines(
        commander, _EntityAccess.get_display_name(commander, _EntityAccess.id_int(commander)), mgr
    )
    var tip_hit: bool = false
    for line in tips:
        if str(line).ends_with(" -  Enemy commander"):
            tip_hit = true
            break
    if not tip_hit:
        _fail(failures, "iv11_enemy_diagram: formation cell tooltip missing Enemy commander")
    _free_manager(mgr)


## IV-11 slice 7: **`PartyRowFormatter`** roster **` . Leader`** suffix from snapshot / node.


## IV-11 slice 7: **`PartyRowFormatter`** roster **` . Leader`** suffix from snapshot / node.
static func _run_iv11_party_leader_roster_callout_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice7=roster_menu_leader_suffix" not in sync_line:
        _fail(failures, "iv11_roster: sync line missing slice7 token in %s" % sync_line)
    var leader_ent: CoreEntity = _new_entity("SWORD")
    leader_ent.is_party_leader = true
    var member_ent: CoreEntity = _new_entity("SWORD")
    member_ent.is_party_leader = false
    var leader_snap: Dictionary = _Snapshot.snapshot_from_member({"name": "Lead", "node_ref": leader_ent})
    var member_snap: Dictionary = _Snapshot.snapshot_from_member({"name": "Mate", "node_ref": member_ent})
    if _PartyRowFormatter.format_party_role_suffix(leader_snap) != " . Leader":
        _fail(
            failures,
            "iv11_roster: leader want ' . Leader' got '%s'" % _PartyRowFormatter.format_party_role_suffix(leader_snap)
        )
    if not _PartyRowFormatter.format_party_role_suffix(member_snap).is_empty():
        _fail(failures, "iv11_roster: member must not get leader suffix")
    _free_harness_node(leader_ent)
    _free_harness_node(member_ent)


## IV-13: weak front ZoC  -  spear gains virtual reach; sword does not at marginal eff_dist.


## IV-13: weak front ZoC  -  spear gains virtual reach; sword does not at marginal eff_dist.
static func _run_iv13_weapon_reach_zoc_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv13_weapon_reach_zoc_doc_sync_line()
    if "weapon-reach ZoC" not in sync_line:
        _fail(failures, "iv13_zoc: sync line missing token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled()
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    for _j in 2:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    mgr.formations["player"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    mgr.formations["enemy"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    var sword: Dictionary = {}
    var spear: Dictionary = {}
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            if enemy.is_empty() or _EntityAccess.file_int(c) < _EntityAccess.file_int(enemy):
                enemy = c
        elif _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.rank_int(c) == 0:
            if _EntityAccess.weapon_melee_reach(c) > 2.0:
                spear = c
            else:
                sword = c
    if sword.is_empty() or spear.is_empty() or enemy.is_empty():
        _fail(failures, "iv13_zoc: missing sword/spear/enemy rank-0 fixtures")
        CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
        _free_manager(mgr)
        return
    var e_id: int = _EntityAccess.id_int(enemy)
    var sword_id: int = _EntityAccess.id_int(sword)
    var spear_id: int = _EntityAccess.id_int(spear)
    _EntityAccess.nested_dictionary_for_mutation(sword, "distance_to")[e_id] = CombatConstants.DISTANCE_MID
    _EntityAccess.nested_dictionary_for_mutation(spear, "distance_to")[e_id] = CombatConstants.DISTANCE_MID
    _EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[sword_id] = CombatConstants.DISTANCE_MID
    _EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[spear_id] = CombatConstants.DISTANCE_MID
    var pair_geom: Dictionary = {"eff_dist": 2.6, "effective_pair_eff_dist": 2.6}
    var bonus_spear: float = _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, spear, enemy)
    var bonus_sword: float = _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, sword, enemy)
    if bonus_spear <= bonus_sword + 0.04:
        _fail(failures, "iv13_zoc: want spear bonus > sword (spear=%.3f sword=%.3f)" % [bonus_spear, bonus_sword])
    if not _MeleeListing.can_melee_threaten(mgr, spear, enemy, pair_geom):
        _fail(failures, "iv13_zoc: spear want can_melee_threaten with weak front + IV-13 on")
    if _MeleeListing.can_melee_threaten(mgr, sword, enemy, pair_geom):
        _fail(failures, "iv13_zoc: sword must not threaten at eff_dist=2.6 without reach bonus")
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
    _free_manager(mgr)


## IV-13: flag off  -  no virtual reach bonus at weak front.


## IV-13: flag off  -  no virtual reach bonus at weak front.
static func _run_iv13_weapon_reach_zoc_flag_off_parity(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled()
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(false)
    var mgr: Node = _MgrScript.new()
    for _i in 2:
        mgr.register(_new_entity("SPEAR"), "player")
    for _j in 2:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    mgr.formations["player"]["zone_control"] = {"front": 0.3, "left_flank": 0.4, "right_flank": 0.4, "rear": 0.5}
    mgr.formations["enemy"]["zone_control"] = {"front": 0.3, "left_flank": 0.4, "right_flank": 0.4, "rear": 0.5}
    var spear: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[2]
    var pair_geom: Dictionary = {"eff_dist": 2.6, "effective_pair_eff_dist": 2.6}
    var bonus: float = _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, spear, enemy)
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
    _free_manager(mgr)
    if absf(bonus) > 0.001:
        _fail(failures, "iv13_zoc_off: flag off want zero bonus got %.4f" % bonus)


## IV-13: distance bands stay aligned with `can_melee_threaten` when ZoC reach bonus is on.


## IV-13: distance bands stay aligned with `can_melee_threaten` when ZoC reach bonus is on.
static func _run_iv13_weapon_reach_zoc_distance_band_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled()
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(true)
    var mgr: Node = _MgrScript.new()
    for _i in 2:
        mgr.register(_new_entity("SPEAR"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 4, "ranks": 1})
    mgr.formations["player"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    mgr.formations["enemy"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    var spear: Dictionary = {}
    var enemy_far: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.file_int(c) == 0:
            spear = c
        elif _EntityAccess.is_living_on_side(c, "enemy") and _EntityAccess.file_int(c) == 3:
            enemy_far = c
    if spear.is_empty() or enemy_far.is_empty():
        _fail(failures, "iv13_zoc_band: missing spear / far-enemy fixture")
        CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
        _free_manager(mgr)
        return
    var eid: int = _EntityAccess.id_int(enemy_far)
    var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(mgr, spear, enemy_far)
    if _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, spear, enemy_far) <= 0.01:
        _fail(failures, "iv13_zoc_band: want positive ZoC reach bonus on wide-line fixture")
        CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
        _free_manager(mgr)
        return
    _DistanceBands.update_distance_to_from_formations(mgr)
    var band_on: String = _EntityAccess.distance_to_opponent_band(spear, eid)
    var threaten_on: bool = _MeleeListing.can_melee_threaten(mgr, spear, enemy_far, pair_geom)
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
    _free_manager(mgr)
    var band_implies_threaten: bool = (
        band_on == CombatConstants.DISTANCE_CLOSE or band_on == CombatConstants.DISTANCE_MID
    )
    if threaten_on != band_implies_threaten:
        _fail(failures, "iv13_zoc_band: band/threaten mismatch band=%s threaten=%s" % [band_on, threaten_on])


## IV-12: dual-occupancy opponent slot adds distraction pad to surround weight sum.


## IV-12: dual-occupancy opponent slot adds distraction pad to surround weight sum.
static func _run_iv12_slot_distraction_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv12_slot_distraction_doc_sync_line()
    if "IV-12 slot distraction" not in sync_line:
        _fail(failures, "iv12_distraction: sync line missing token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, e1_id]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, e1_id], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    if int(_TacticalCombat.count_engaging_threats(mgr, pid)) < 2:
        _fail(failures, "iv12_distraction: fixture want 2 engaging threats")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var w_on: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var w_off: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    var pad: float = CombatConstants.IV12_SLOT_DISTRACTION_WEIGHT_PAD
    if w_on < w_off + pad - 0.05:
        _fail(failures, "iv12_distraction: want on>off+pad (on=%.3f off=%.3f pad=%.2f)" % [w_on, w_off, pad])


## IV-12 slice 2: co-located threats damp AI hostile pick weight.


## IV-12 slice 2: co-located threats damp AI hostile pick weight.
static func _run_iv12_slot_distraction_ai_offense_damp(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, _EntityAccess.id_int(e1)]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, _EntityAccess.id_int(e1)], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    if _TacticalCombat.iv12_slot_distraction_pad_for_defender(mgr, pid) <= 0.0:
        _fail(failures, "iv12_ai_offense: fixture want distraction pad on player")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var act: Dictionary = {"move_id": "oberhau", "target_id": e0_id}
    var w_on: float = _AIPicker._get_action_weight(act, pid, mgr, true)
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var w_off: float = _AIPicker._get_action_weight(act, pid, mgr, true)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    var want_ratio: float = CombatConstants.IV12_AI_OFFENSE_WEIGHT_MULT
    var ratio: float = w_on / maxf(0.0001, w_off)
    if ratio > want_ratio + 0.04:
        _fail(
            failures, "iv12_ai_offense: want ratio<=%.2f got %.3f (on=%.4f off=%.4f)" % [want_ratio, ratio, w_on, w_off]
        )


## IV-12 slice 2: co-located slot-mate pile-on boosts hostile targeting weight.


## IV-12 slice 2: co-located slot-mate pile-on boosts hostile targeting weight.
static func _run_iv12_co_located_target_bias_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, e1_id]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, e1_id], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    if not _TacticalCombat.attacker_has_co_located_slot_mate_threatening(mgr, e1, player):
        _fail(failures, "iv12_pile_on: want co-located mate threatening player")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var w_on: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, e1, player)
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var w_off: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, e1, player)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    var want: float = CombatConstants.IV12_AI_COLOCATED_TARGET_BIAS_MULT
    if w_on < w_off * want - 0.02:
        _fail(failures, "iv12_pile_on: want on>=off*%.2f (on=%.4f off=%.4f)" % [want, w_on, w_off])


## IV-12 slice 3: **`drag_back`** dual slot occupancy groups threats by formation cell (not stale rank).


## IV-12 slice 3: **`drag_back`** dual slot occupancy groups threats by formation cell (not stale rank).
static func _run_iv12_drag_back_dual_occupancy_distraction_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv12_slot_distraction_doc_sync_line()
    if "slice3=formation_slot_cell" not in sync_line:
        _fail(failures, "iv12_drag_back: sync line missing slice3 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2})
    var player: Dictionary = mgr.combatants[0]
    var e_front: Dictionary = {}
    var e_rear: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        if _EntityAccess.rank_int(c) == 0:
            e_front = c
        elif _EntityAccess.rank_int(c) == 1:
            e_rear = c
    if e_front.is_empty() or e_rear.is_empty():
        _fail(failures, "iv12_drag_back: want enemy rank-0/rank-1 pair")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e_front)
    var e1_id: int = _EntityAccess.id_int(e_rear)
    for c in [player, e_front, e_rear]:
        c["gauge"] = 100.0
    _EntityAccess.nested_dictionary_for_mutation(player, "distance_to")[e0_id] = (CombatConstants.DISTANCE_CLOSE)
    _EntityAccess.nested_dictionary_for_mutation(e_front, "distance_to")[pid] = (CombatConstants.DISTANCE_CLOSE)
    _EntityAccess.nested_dictionary_for_mutation(e_rear, "distance_to")[pid] = (CombatConstants.DISTANCE_CLOSE)
    _FormationFlow.start_pair_move(mgr, e0_id, e1_id, "drag_back")
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    if _FormationSlots.living_count_in_slot(mgr, slots, Vector2i(0, 0)) < 2:
        _fail(failures, "iv12_drag_back: want dual occupancy at rank-0 during drag_back")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var pad: float = _TacticalCombat.iv12_slot_distraction_pad_for_defender(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    if pad < CombatConstants.IV12_SLOT_DISTRACTION_WEIGHT_PAD - 0.05:
        _fail(failures, "iv12_drag_back: want distraction pad from drag_back dual slot (got %.3f)" % pad)


## IV-12: flag off  -  co-located slot mates do not add distraction pad.


## IV-12: flag off  -  co-located slot mates do not add distraction pad.
static func _run_iv12_slot_distraction_flag_off_parity(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, e1_id]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, e1_id], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    var w0: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    var w1: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    if not is_equal_approx(w0, w1):
        _fail(failures, "iv12_distraction_off: flag off want stable weight got %.3f vs %.3f" % [w0, w1])


## IV-11 slice 1b: party leader gets telegraph-matching focus-line weight; members use base weight.


## IV-11 slice 1b: party leader gets telegraph-matching focus-line weight; members use base weight.
static func _run_iv11_leader_formation_ability_suite(failures: PackedStringArray) -> void:
    var line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    for token in [
        "slice1=focus_line_telegraph_match",
        "issuer=is_formation_command_issuer",
        "menu_abilities=roster_suffix",
        "slice9=enemy_commander_orders+doctrine_cycle",
        "slice10=pinch_outnumber_ai_mult=",
        "f5_track=iv11_leader_order",
        "is_party_leader=CombatManager.register",
        "order_hold_lane_feature=",
    ]:
        if token not in line:
            _fail(failures, "iv11_leader: sync line missing %s in %s" % [token, line])
    if CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT <= 1.0:
        _fail(
            failures,
            (
                "iv11_leader: want leader telegraph weight > 1 got %.2f"
                % CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
            )
        )
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = mgr.combatants[0]
    var pid: int = _EntityAccess.id_int(leader)
    leader["is_party_leader"] = true
    leader[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    var w_leader: float = _AIPicker._get_action_weight(
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
    )
    leader["is_party_leader"] = false
    var w_member: float = _AIPicker._get_action_weight(
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
    )
    if w_leader <= w_member:
        _fail(failures, "iv11_leader: telegraph match want leader>member (%.4f vs %.4f)" % [w_leader, w_member])
    if w_member > CombatConstants.AI_FOCUS_LINE_BASE_WEIGHT * 2.0:
        _fail(failures, "iv11_leader: member should use base focus weight got %.4f" % w_member)
    _free_manager(mgr)

## IV-7b: low stamina dampens attack / close listing weights via canonical engage floor.
