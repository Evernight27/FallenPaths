extends SceneTree

const MgrScript := preload("res://combat/CombatManager.gd")
const MentalStack := preload("res://combat/ai/MentalStackDecider.gd")
const CombatConstants := preload("res://combat/CombatConstants.gd")
const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")
const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")
const CombatDoctrine := preload("res://combat/formation/CombatDoctrine.gd")
const CombatExhaustion := preload("res://combat/flow/CombatExhaustion.gd")
const CombatListedActions := preload("res://combat/ai/CombatListedActions.gd")
const CombatFormationFlow := preload("res://combat/formation/CombatFormationFlow.gd")


func _init() -> void:
    var mgr: Node = MgrScript.new()
    for i in range(2):
        mgr.register(HarnessFixtures._new_entity("SWORD"), "player")
    mgr.register(HarnessFixtures._new_entity("SWORD"), "enemy")
    mgr.register(HarnessFixtures._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD + 0.05
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": fighter_id},
    ]
    print(
        "DIAG_MS: tunnel=%s finish=%s rank0=%s sparse=%s underdog=%s envelop_own=%s strike=%s"
        % [
            CombatExhaustion.exhaustion_tunnel_active(fighter),
            CombatDoctrine.fight_finish_tail_active(mgr, fighter, actions, fighter_id),
            CombatantEntityAccess.rank_int(fighter),
            CombatFormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"),
            CombatDoctrine.mop_up_underdog_active(mgr, fighter),
            CombatDoctrine.envelop_mop_up_active(mgr, "player"),
            CombatListedActions.action_list_has_hostile_strike(actions, fighter_id),
        ]
    )
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    print("DIAG_MS: picked=%s layer=%s" % [picked, fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "none")])
    quit(0)
