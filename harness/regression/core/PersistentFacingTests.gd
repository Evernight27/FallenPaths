class_name PersistentFacingTests
extends RefCounted
## Tier 3.1 persistent facing: a flank/rear resolve stamps a decaying facing-turn window on the
## defender; while still turned, their parry capacity takes a small bounded dip (blade off-line on
## the new exposure line). D001-neutral: front-on duels never stamp a window, so they stay byte-stable.
## Mirrors the off-balance window idiom but on a distinct axis (orientation, not balance/feet).

const CombatConstants := preload("res://combat/CombatConstants.gd")
const DataKeys := preload("res://core/DataKeys.gd")
const CombatTiming := preload("res://combat/flow/CombatTiming.gd")
const PassiveParryContext := preload("res://combat/weapon_form/PassiveParryContext.gd")


## facing_turn_window_s: front/unknown -> 0.0, flank -> flank window, rear -> rear window.
static func run_facing_turn_window_s(failures: PackedStringArray) -> void:
    var flank: float = CombatConstants.facing_turn_window_s("flank")
    var rear: float = CombatConstants.facing_turn_window_s("rear")
    var front: float = CombatConstants.facing_turn_window_s("front")
    var unknown: float = CombatConstants.facing_turn_window_s("bogus")
    if flank != CombatConstants.FACING_TURN_WINDOW_FLANK_S:
        _fail(failures, "facing_window: flank want %f got %f" % [CombatConstants.FACING_TURN_WINDOW_FLANK_S, flank])
    if rear != CombatConstants.FACING_TURN_WINDOW_REAR_S:
        _fail(failures, "facing_window: rear want %f got %f" % [CombatConstants.FACING_TURN_WINDOW_REAR_S, rear])
    if front != 0.0:
        _fail(failures, "facing_window: front must be 0.0 got %f" % front)
    if unknown != 0.0:
        _fail(failures, "facing_window: unknown angle must be 0.0 got %f" % unknown)
    # Rear turn takes longer than a flank turn (no anticipation to re-center).
    if not (rear > flank):
        _fail(failures, "facing_window: rear (%f) must exceed flank (%f)" % [rear, flank])


## No stamped window -> depth 0.0 -> parry capacity 1.0 (settled / D001 front-on fighter).
static func run_facing_turn_no_window_neutral(failures: PackedStringArray) -> void:
    var settled: Dictionary = {}
    var depth: float = PassiveParryContext.facing_turn_depth(settled)
    if absf(depth) > 0.001:
        _fail(failures, "facing_neutral: settled depth want ~0 got %f" % depth)
    var mult: float = PassiveParryContext.facing_turn_parry_capacity_mult(settled)
    if absf(mult - 1.0) > 0.001:
        _fail(failures, "facing_neutral: settled parry-capacity mult want 1.0 got %f" % mult)


## A freshly stamped flank window reads full depth (~1.0) and dips parry capacity toward the floor,
## bounded below by FACING_TURN_PARRY_CAPACITY_MULT_MIN.
static func run_facing_turn_stamp_dips_parry_capacity(failures: PackedStringArray) -> void:
    var c: Dictionary = {}
    var now: float = CombatTiming.now_seconds()
    var window: float = CombatConstants.facing_turn_window_s("flank")
    c[DataKeys.PA_FACING_TURN_UNTIL] = now + window
    c[DataKeys.PA_FACING_TURN_TOTAL] = window
    var depth: float = PassiveParryContext.facing_turn_depth(c)
    if absf(depth - 1.0) > 0.05:
        _fail(failures, "facing_stamp: fresh depth want ~1 got %f" % depth)
    var floor: float = CombatConstants.FACING_TURN_PARRY_CAPACITY_MULT_MIN
    var mult: float = PassiveParryContext.facing_turn_parry_capacity_mult(c)
    # Fresh (depth ~1) -> at or near the floor; must dip below 1.0 and never underflow the floor.
    if mult >= 1.0:
        _fail(failures, "facing_stamp: parry-capacity must dip below 1.0, got %f" % mult)
    if mult < floor - 0.001:
        _fail(failures, "facing_stamp: parry-capacity must not fall under floor %f, got %f" % [floor, mult])


## An expired window (until in the past) reads 0.0 depth / 1.0 mult even though total is set.
static func run_facing_turn_expired_neutral(failures: PackedStringArray) -> void:
    var c: Dictionary = {}
    var now: float = CombatTiming.now_seconds()
    c[DataKeys.PA_FACING_TURN_UNTIL] = now - 5.0
    c[DataKeys.PA_FACING_TURN_TOTAL] = 1.2
    var depth: float = PassiveParryContext.facing_turn_depth(c)
    if absf(depth) > 0.001:
        _fail(failures, "facing_expired: depth want ~0 got %f" % depth)
    if absf(PassiveParryContext.facing_turn_parry_capacity_mult(c) - 1.0) > 0.001:
        _fail(
            failures,
            (
                "facing_expired: parry-capacity mult want 1.0 got %f"
                % PassiveParryContext.facing_turn_parry_capacity_mult(c)
            )
        )


## Pile-on: a second flank hit while still turned extends the window beyond a single stamp.
static func run_facing_turn_pile_on_extends(failures: PackedStringArray) -> void:
    var c: Dictionary = {}
    var t1: float = PassiveParryContext.apply_facing_turn(c, "flank")
    if absf(t1 - CombatConstants.FACING_TURN_WINDOW_FLANK_S) > 0.05:
        _fail(failures, "pile_on: first stamp want ~%f got %f" % [CombatConstants.FACING_TURN_WINDOW_FLANK_S, t1])
    var t2: float = PassiveParryContext.apply_facing_turn(c, "flank")
    if t2 <= t1:
        _fail(failures, "pile_on: second stamp should extend window, got t1=%f t2=%f" % [t1, t2])


## Pile-on cap: repeated rear stamps never exceed FACING_TURN_MAX_WINDOW_S.
static func run_facing_turn_pile_on_capped(failures: PackedStringArray) -> void:
    var c: Dictionary = {}
    var cap: float = CombatConstants.FACING_TURN_MAX_WINDOW_S
    var t: float = 0.0
    for i in range(5):
        t = PassiveParryContext.apply_facing_turn(c, "rear")
    if t > cap + 0.01:
        _fail(failures, "pile_on_cap: total %f exceeds cap %f" % [t, cap])
    if t < 2.0:
        _fail(failures, "pile_on_cap: total %f below expected extended value (extension not happening)" % t)


static func _fail(failures: PackedStringArray, msg: String) -> void:
    failures.append(msg)
