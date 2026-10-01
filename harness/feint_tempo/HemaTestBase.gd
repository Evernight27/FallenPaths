class_name HemaTestBase

extends RefCounted

## Shared preloads and assertion helpers for the HEMA mechanic test classes.
## Split out of HemaNewMechanicsTests to keep each test module under the file-size budget.
const HarnessCore := preload("res://harness/regression/core/CombatRegressionHarnessCore.gd")

const CombatManager := preload("res://combat/CombatManager.gd")

const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")

const CounterTempo := preload("res://combat/strike/CounterTempo.gd")

const CombatConstants := preload("res://combat/CombatConstants.gd")

const CombatConstantsEncounter := preload("res://combat/constants/CombatConstantsEncounter.gd")

const CombatEventScheduler := preload("res://combat/flow/CombatEventScheduler.gd")

const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")

const DataKeys := preload("res://core/DataKeys.gd")

const WeaponConstants := preload("res://resources/weapons/WeaponConstants.gd")

const CombatGuardLines := preload("res://combat/weapon_form/CombatGuardLines.gd")

const CombatBindPressure := preload("res://combat/strike/CombatBindPressure.gd")

const CombatTiming := preload("res://combat/flow/CombatTiming.gd")

static var _mgr_ref: Node = null


static func _actions_have_move(actions: Array, move_id: String) -> bool:
    for a in actions:
        if a.get(DataKeys.ACTION_MOVE_ID, "") == move_id:
            return true
    return false


## Formation-move settling: plug=0 (no-op), rotate=base*1.2, fall_back=base*1.1.
## apply_formation_settle should create an off-balance window for non-zero durations.


static func _make_1v1_sword() -> Node:
    var mgr: Node = CombatManager.new()
    var e1: Node = HarnessFixtures._new_entity("SWORD")
    var e2: Node = HarnessFixtures._new_entity("SWORD")
    mgr.register(e1, "player")
    mgr.register(e2, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    HarnessFixtures._harness_reset_combatants_form_balanced(mgr)
    _mgr_ref = mgr
    return mgr


## Set a live bind at the given pressure value on `c` (until = clock+4) and return the follow-through mult.
## A value < 0.25 yields pressure level "none" -> no bonus (used to simulate no active pressure).


static func _follow_through_at(c: Dictionary, value: float, clock: float) -> float:
    c[DataKeys.BIND_PRESSURE_VALUE] = value
    c[DataKeys.BIND_PRESSURE_UNTIL] = clock + 4.0
    return CombatBindPressure.follow_through_dmg_mult(c, clock)


static func _assert(cond: bool, failures: PackedStringArray, msg: String) -> void:
    if not cond:
        failures.append(msg)


static func _assert_eq(got: String, want: String, failures: PackedStringArray, msg: String) -> void:
    if got != want:
        failures.append(msg)
