extends SceneTree

const CombatManager := preload("res://combat/CombatManager.gd")
const CombatResolveAction := preload("res://combat/flow/CombatResolveAction.gd")
const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")
const CombatConstants := preload("res://combat/CombatConstants.gd")
const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")


func _init() -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(HarnessFixtures._new_entity("SWORD"), "player")
    mgr.register(HarnessFixtures._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    attacker.gauge = 100.0
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    var payloads: Array = []
    var on_resolved := func(_a, _b, payload): payloads.append(payload)
    mgr.action_resolved.connect(on_resolved)
    var ok: bool = CombatResolveAction.resolve(
        mgr, CombatantEntityAccess.id_int(attacker), CombatantEntityAccess.id_int(target), CombatConstants.MOVE_ID_EXECUTE, {}
    )
    print("DIAG_SIG: resolve ok=%s payloads=%s target_alive=%s" % [ok, payloads, target.alive])
    quit(0)
