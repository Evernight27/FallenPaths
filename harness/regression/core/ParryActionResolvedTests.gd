class_name ParryActionResolvedTests

extends CombatRegressionHarnessCore

## Parry action core: resolved parry payload clash context, hit clears attacker parry calibration, defender
## guard-low after hit, parry clash context carries strike momentum, and full parry recoil scales with parry
## control. Includes the redundant counter-tempo helper kept for caller compatibility.


## **`AttackResultApplier`**: first **`action_resolved`** on **`parry_partial`** is defender, attacker, payload with
## **`parry_clash_context`** (nested **`_execute_attack`** may append further rows).
static func _run_action_resolved_parry_partial_payload_includes_clash_context(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    var captured: Array = []
    mgr.action_resolved.connect(
        func(first_id: int, second_id: int, res: Dictionary) -> void:
            captured.append({"first": first_id, "second": second_id, "res": res.duplicate(true)})
    )
    e["pending_attack"] = {
        "target_id": p_id, "attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5
    }
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust", "strike_measure_ratio": 1.05, "parry_control": 0.41, "remaining_ratio": 0.33
    }
    AttackResultApplier.apply_result(
        mgr, e_id, {"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
    )
    if captured.is_empty():
        _fail(failures, "parry_partial_resolve_emit: expected at least one action_resolved")
        _free_manager(mgr)
        return
    var slot: Dictionary = captured[0] as Dictionary
    if int(slot.get("first", -99)) != p_id:
        _fail(
            failures,
            (
                "parry_partial_resolve_emit: first signal arg should be defender id %d got %d"
                % [p_id, int(slot.get("first", -99))]
            )
        )
    if int(slot.get("second", -99)) != e_id:
        _fail(
            failures,
            (
                "parry_partial_resolve_emit: second signal arg should be attacker id %d got %d"
                % [e_id, int(slot.get("second", -99))]
            )
        )
    var res: Dictionary = slot.get("res", {}) as Dictionary
    if str(res.get("outcome", "")) != "parry_partial":
        _fail(
            failures,
            "parry_partial_resolve_emit: first outcome want parry_partial got %s" % str(res.get("outcome", ""))
        )
    var ctx: Variant = res.get("parry_clash_context", null)
    if not (ctx is Dictionary):
        _fail(failures, "parry_partial_resolve_emit: missing parry_clash_context on first payload")
        _free_manager(mgr)
        return
    var cd: Dictionary = ctx as Dictionary
    if str(cd.get("kinematic_delivery", "")) != "thrust":
        _fail(failures, "parry_partial_resolve_emit: clash kinematic_delivery mismatch")
    if absf(float(cd.get("strike_measure_ratio", 0.0)) - 1.05) > 0.001:
        _fail(failures, "parry_partial_resolve_emit: strike_measure_ratio mismatch")
    if absf(float(cd.get("parry_control", 0.0)) - 0.41) > 0.001:
        _fail(failures, "parry_partial_resolve_emit: parry_control mismatch")
    if absf(float(cd.get("remaining_ratio", 0.0)) - 0.33) > 0.001:
        _fail(failures, "parry_partial_resolve_emit: remaining_ratio mismatch")
    _free_manager(mgr)


## **`AttackResultApplier`**: **`hit`** erases **`parry_clash_context`** / **`defender_guard_line_at_parry`** on the
## striker (stale calibration after **`parry_partial`** follow-through).

## **`AttackResultApplier`**: **`hit`** erases **`parry_clash_context`** / **`defender_guard_line_at_parry`** on the
## striker (stale calibration after **`parry_partial`** follow-through).


static func _run_hit_clears_attacker_parry_calibration_fields(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    p.state = CombatConstants.STATE_WAITING
    p.pending_attack = {}
    e.state = CombatConstants.STATE_WIND_UP
    e.pending_attack = {
        "target_id": p_id,
        "attack_type": "thrust",
        "intensity": 0.5,
        "effective_attack_line": "high",
    }
    e["parry_clash_context"] = {"kinematic_delivery": "thrust", "parry_control": 0.5}
    e["defender_guard_line_at_parry"] = "high"
    var rd: Dictionary = {
        "dmg": 2,
        "died": false,
        "part": "chest",
        "outcome": "hit",
        "damage_type": "cut",
        "health_before": 100,
        "health_after": 98,
        "final_cut": 1.0,
        "final_blunt": 1.0,
        "final_bone": 0.0,
        "total_physical": 2.0,
    }
    (
        AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "hit",
                "target_id": p_id,
                "intensity": 0.2,
                "recovery_duration": 0.45,
                "result_dict": rd,
            }
        )
    )
    if e.has("parry_clash_context"):
        _fail(failures, "hit_clear_parry: attacker should not retain parry_clash_context after hit")
    if e.has("defender_guard_line_at_parry"):
        _fail(failures, "hit_clear_parry: attacker should not retain defender_guard_line_at_parry after hit")
    _free_manager(mgr)


## **`AttackResultApplier`**: **`hit`** sets defender **`guard_line`** low and syncs **`guard_zone`** via
## **`GuardLineUpdater.set_guard_from_line`** (stagger / dropped guard).

## **`AttackResultApplier`**: **`hit`** sets defender **`guard_line`** low and syncs **`guard_zone`** via
## **`GuardLineUpdater.set_guard_from_line`** (stagger / dropped guard).


static func _run_hit_applier_sets_defender_guard_low_after_hit(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    p.state = CombatConstants.STATE_WAITING
    p.pending_attack = {}
    p["guard_line"] = "high"
    p["guard_zone"] = "head"
    e.state = CombatConstants.STATE_WIND_UP
    e.pending_attack = {
        "target_id": p_id,
        "attack_type": "thrust",
        "intensity": 0.5,
        "effective_attack_line": "high",
    }
    var rd: Dictionary = {
        "dmg": 2,
        "died": false,
        "part": "chest",
        "outcome": "hit",
        "damage_type": "cut",
        "health_before": 100,
        "health_after": 98,
        "final_cut": 1.0,
        "final_blunt": 1.0,
        "final_bone": 0.0,
        "total_physical": 2.0,
    }
    (
        AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "hit",
                "target_id": p_id,
                "intensity": 0.2,
                "recovery_duration": 0.45,
                "result_dict": rd,
            }
        )
    )
    if str(p.get("guard_line", "")) != "low":
        _fail(failures, "hit_guard_reaction: defender guard_line want low got %s" % str(p.get("guard_line", "")))
    var want_zone: String = CombatConstants.LINE_TO_DEFAULT_PART.get("low", "")
    if str(p.get("guard_zone", "")) != want_zone:
        _fail(
            failures,
            "hit_guard_reaction: defender guard_zone want %s got %s" % [want_zone, str(p.get("guard_zone", ""))]
        )
    _free_manager(mgr)


## **`parry_partial`**: defender **`parry_was_bind`** / **`parry_against_id`** when alignment >= partial threshold and
## clash **`parry_control`** crosses bind threshold; cleared when misaligned or control low (misaligned path
## **`erase`**s stale **`parry_was_bind`**).

## **`parry_partial`**: defender **`parry_was_bind`** / **`parry_against_id`** when alignment >= partial threshold and
## clash **`parry_control`** crosses bind threshold; cleared when misaligned or control low (misaligned path
## **`erase`**s stale **`parry_was_bind`**).


static func _run_parry_clash_context_carries_strike_momentum(failures: PackedStringArray) -> void:
    var kinematics: Dictionary = {
        "archetype_id": "sword",
        "kinematic_delivery": "swing",
        "strike_velocity_m_s": 8.0,
        "strike_kinetic_energy_j": 50.0,
        "strike_momentum_kg_ms": 9.5,
    }
    var ctx: Dictionary = DefenseParryClash._build_parry_clash_context(
        "high",
        "oberhau",
        20.0,
        10.0,
        8.0,
        9.0,
        0.9,
        "left",
        15.0,
        0.3,
        0.8,
        false,
        false,
        false,
        1.5,
        1.5,
        8.0,
        kinematics,
        1.0,
        {}
    )
    if not ctx.has("strike_momentum_kg_ms"):
        _fail(failures, "clash_momentum: clash context missing strike_momentum_kg_ms")
        return
    if absf(float(ctx.get("strike_momentum_kg_ms", 0.0)) - 9.5) > 0.001:
        _fail(failures, "clash_momentum: want momentum 9.5 got %.3f" % float(ctx.get("strike_momentum_kg_ms", 0.0)))
    if absf(float(ctx.get("strike_kinetic_energy_j", 0.0)) - 50.0) > 0.001:
        _fail(failures, "clash_momentum: want KE 50.0 got %.3f" % float(ctx.get("strike_kinetic_energy_j", 0.0)))


## Parry recoil (physics): a **full parry** (`parry_deflect`) transmits a fraction of the incoming blow's momentum
## into the defender's braced arm, scaled by **`parry_control`** (a well-braced parry catches more of the blow).
## High control + heavy blow -> a small `parry_deflection_shock` blunt fires; low control -> suppressed by the 0.5 gate.


static func _run_full_parry_recoil_scales_with_parry_control(failures: PackedStringArray) -> void:
    for row: Dictionary in [
        {"ctrl": 0.9, "want_recoil": true},
        {"ctrl": 0.3, "want_recoil": false},
    ]:
        var ctrl: float = float(row["ctrl"])
        var want_recoil: bool = bool(row["want_recoil"])
        var mgr: Node = MgrScript.new()
        mgr.register(_new_entity("SWORD"), "player")
        mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
        var p: Dictionary = mgr.combatants[0]
        var e: Dictionary = mgr.combatants[1]
        var p_id: int = EntityAccess.id_int(p)
        var e_id: int = EntityAccess.id_int(e)
        var captured: Array = []
        mgr.action_resolved.connect(
            func(_first_id: int, _second_id: int, res: Dictionary) -> void: captured.append(res.duplicate(true))
        )
        e["pending_attack"] = {
            "target_id": p_id, "attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5
        }
        var pclash: Dictionary = {
            "kinematic_delivery": "thrust",
            "strike_measure_ratio": 1.05,
            "parry_control": ctrl,
            "strike_momentum_kg_ms": 12.0,
            "strike_kinetic_energy_j": 60.0,
        }
        AttackResultApplier.apply_result(
            mgr, e_id, {"action": "parry_deflect", "target_id": p_id, "parry_clash_context": pclash}
        )
        var saw_recoil: bool = false
        for res in captured:
            if str((res as Dictionary).get("outcome", "")) == "parry_deflection_shock":
                saw_recoil = true
                break
        if want_recoil and not saw_recoil:
            _fail(failures, "full_parry_recoil: ctrl=%.2f expected a parry_deflection_shock but none fired" % ctrl)
        if not want_recoil and saw_recoil:
            _fail(failures, "full_parry_recoil: ctrl=%.2f expected no recoil (below 0.5 gate) but one fired" % ctrl)
        _free_manager(mgr)


static func _harness_counter_tempo_set_incoming_progress(mgr: Node, attacker_id: int, fraction: float) -> void:
    Fixtures._harness_counter_tempo_set_incoming_progress(mgr, attacker_id, fraction)

## Tier 4.2 counter-tempo pilot: incoming wind-up opens defender **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`**.

## Tier 4.2 counter-tempo pilot: incoming wind-up opens defender **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`**.
