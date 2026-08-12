extends SceneTree

const CombatManager := preload("res://combat/CombatManager.gd")
const CombatConstants := preload("res://combat/CombatConstants.gd")
const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")
const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")
const CombatMeleeListing := preload("res://combat/ai/CombatMeleeListing.gd")
const CounterTempo := preload("res://combat/strike/CounterTempo.gd")

func _init() -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(HarnessFixtures._new_entity("SWORD"), "player")
    mgr.register(HarnessFixtures._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var tgt: Dictionary = mgr.combatants[1]
    tgt.alive = true
    tgt.state = CombatConstants.STATE_COWERING
    var actions: Array = []
    CombatMeleeListing.append_melee_actions_for_combatant(
        mgr, atk, mgr.combatants, actions, false, ZoneOfControl.zone_geometry_line_context(mgr, atk)
    )
    print("append_melee_actions -> ", actions)
    var cid: int = CombatantEntityAccess.id_int(atk)
    print("gauge=", CombatantEntityAccess.gauge_float(atk), " can_counter_tempo=", CounterTempo.can_act(mgr, atk))
    var filtered: Array = CounterTempo.filter_actions_for_counter_tempo(actions, atk)
    print("after counter_tempo filter -> ", filtered)
    HarnessFixtures.flush_harness_live_nodes()
    mgr.free()
    quit()
