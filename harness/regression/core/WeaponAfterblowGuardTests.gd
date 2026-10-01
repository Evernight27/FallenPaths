class_name WeaponAfterblowGuardTests
extends CombatRegressionHarnessCore
const _AFTERBLOW_EXECUTE_HIT_SEED: int = 1
## **`seed(2)`**: hybrid hindrance in **(ALLOW, BLOCK)** and first **`randf()` < hindrance** -> **`try_afterblow`
## false** + **`_cancel_pending`** (chest **`final_cut` 11.25**).
const _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED: int = 2
## **`seed(0)`**: same fixture + chest **`final_cut` 11.25** -> **`randf() >= hindrance`** -> **`_execute_afterblow`**
## (**`afterblow_damage_mult` 0.55**) + **`attack_hit`** resolve.
const _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED: int = 0


## Tier 3.2 (weapon audit): verify each weapon has required move types and valid coupling physics.
static func _run_weapon_move_coverage(failures: PackedStringArray) -> void:
    var weapons_and_needs: Dictionary = {
        "SWORD": {"stab": true, "cut": true, "blunt": true},
        "AXE": {"stab": true, "cut": true, "blunt": true},
        "MACE": {"stab": false, "cut": false, "blunt": true},
        "DAGGER": {"stab": true, "cut": true, "blunt": true},
        "SPEAR": {"stab": true, "cut": true, "blunt": true},
    }
    var min_moves: Dictionary = {
        "SWORD": 12,
        "AXE": 10,
        "MACE": 9,
        "DAGGER": 9,
        "SPEAR": 9,
    }
    for wname in weapons_and_needs:
        var needs: Dictionary = weapons_and_needs[wname]
        var wep: Weapon = HarnessFixtures.get_cached_weapon(wname)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            continue
        var all_moves := WeaponMoveDefinitions._move_definitions_build()
        var weapon_move_ids: Array = wep.attack_types.keys()
        var has_stab: bool = false
        var has_cut: bool = false
        var has_blunt: bool = false
        for move_id in weapon_move_ids:
            if move_id is String and all_moves.has(move_id):
                var move_def: Dictionary = all_moves[move_id]
                var contact: String = move_def.get("contact_type", "")
                if contact == "stab":
                    has_stab = true
                elif contact == "cut":
                    has_cut = true
                elif contact == "blunt":
                    has_blunt = true
        if needs["stab"] and not has_stab:
            _fail(failures, "weapon_audit: %s requires stab move but has none" % wname)
        if needs["cut"] and not has_cut:
            _fail(failures, "weapon_audit: %s requires cut move but has none" % wname)
        if needs["blunt"] and not has_blunt:
            _fail(failures, "weapon_audit: %s requires blunt move but has none" % wname)
        if min_moves.has(wname):
            var mc: int = weapon_move_ids.size()
            var mn: int = min_moves[wname]
            if mc < mn:
                _fail(failures, "weapon_audit: %s has %d moves (minimum %d)" % [wname, mc, mn])
        # Verify coupling values are in valid range (0.7-1.2)
        var physics: Dictionary = wep.strike_physics if is_instance_of(wep, Weapon) else {}
        if physics is Dictionary:
            for key in ["coupling_stab", "coupling_cut", "coupling_blunt"]:
                if physics.has(key):
                    var val: float = float(physics[key])
                    if val < 0.7 or val > 1.2:
                        _fail(failures, "weapon_audit: %s %s=%.2f outside valid range [0.7, 1.2]" % [wname, key, val])


## Tier 3.2 (weapon audit): verify parts mass_fraction sums to ~1.0 for each weapon.


## Tier 3.2 (weapon audit): verify parts mass_fraction sums to ~1.0 for each weapon.
static func _run_weapon_parts_mass_sum(failures: PackedStringArray) -> void:
    var wnames: Array[String] = ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
    for wname in wnames:
        var wep: Weapon = HarnessFixtures.get_cached_weapon(wname)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            continue
        var parts: Array = wep.parts if is_instance_of(wep, Weapon) else []
        var sum_f: float = 0.0
        for part in parts:
            if part is Dictionary:
                sum_f += float(part.get("mass_fraction", 0.0))
        if absf(sum_f - 1.0) > 0.01:
            _fail(failures, "weapon_audit: %s parts mass_fraction sum=%.3f (expected ~1.0)" % [wname, sum_f])


## Tier 3.2 (weapon audit): sharpness -> effective sharp contact width is physically grounded. A sharp edge has a
## NARROW apex (small bearing width -> high pressure); a dull edge is capped at the FULL blade width (the cutting
## edge can never be wider than the blade). Locks the corrected saturating map (the old hyperbolic formula gave a
## dull edge 5x the blade width—physically impossible).
static func _run_weapon_sharpness_effective_contact_width(failures: PackedStringArray) -> void:
    var all_moves := WeaponMoveDefinitions._move_definitions_build()
    var wnames: Array[String] = ["SWORD", "AXE", "DAGGER", "SPEAR"]
    for wname in wnames:
        var wep: Weapon = HarnessFixtures.get_cached_weapon(wname)
        if wep == null:
            _fail(failures, "sharp_width: %s has no weapon definition" % wname)
            continue
        var cut_move: String = ""
        for move_id in wep.attack_types.keys():
            if move_id is String and all_moves.has(move_id) and all_moves[move_id].get("contact_type", "") == "cut":
                cut_move = move_id
                break
        if cut_move.is_empty():
            continue
        var geometric: float = wep.get_sharp_contact_cm(cut_move)
        if geometric <= 0.0:
            continue
        var orig_sharpness: float = wep.sharpness
        var apex: float = maxf(WeaponConstants.MIN_CONTACT_WIDTH_CM, geometric * WeaponConstants.SHARP_APEX_FRACTION)
        wep.sharpness = 1.0
        var sharp_w: float = wep.get_effective_sharp_contact_cm(cut_move)
        wep.sharpness = 0.0
        var dull_w: float = wep.get_effective_sharp_contact_cm(cut_move)
        wep.sharpness = orig_sharpness
        if absf(sharp_w - apex) > 0.01:
            _fail(failures, "sharp_width: %s sharp width=%.3f want apex=%.3f" % [wname, sharp_w, apex])
        if absf(dull_w - geometric) > 0.01:
            _fail(
                failures,
                "sharp_width: %s dull width=%.3f want geometric=%.3f (capped at blade)" % [wname, dull_w, geometric]
            )
        if sharp_w >= dull_w:
            _fail(
                failures,
                "sharp_width: %s sharp=%.3f should be < dull=%.3f (sharper = narrower)" % [wname, sharp_w, dull_w]
            )
        if dull_w > geometric + 0.01:
            _fail(
                failures,
                "sharp_width: %s dull width=%.3f exceeds blade width=%.3f (impossible)" % [wname, dull_w, geometric]
            )
        if sharp_w < WeaponConstants.MIN_CONTACT_WIDTH_CM - 1e-6:
            _fail(
                failures,
                (
                    "sharp_width: %s sharp width=%.3f below floor %.3f"
                    % [wname, sharp_w, WeaponConstants.MIN_CONTACT_WIDTH_CM]
                )
            )


## Tier 3.2 (weapon audit): verify each weapon has at least one feint move and one parry-counter move.


## Tier 3.2 (weapon audit): verify each weapon has at least one feint move and one parry-counter move.
static func _run_weapon_feint_parry_coverage(failures: PackedStringArray) -> void:
    var wnames: Array[String] = ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
    for wname in wnames:
        var wep: Weapon = HarnessFixtures.get_cached_weapon(wname)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            continue
        var weapon_move_ids: Array = wep.attack_types.keys()
        var has_feint: bool = false
        var has_parry: bool = false
        for move_id in weapon_move_ids:
            if move_id is String:
                var mdef: Dictionary = WeaponConstants.get_move(move_id)
                if mdef.is_empty():
                    continue
                if mdef.get("is_feint", false):
                    has_feint = true
                if mdef.get("is_parry", false):
                    has_parry = true
        if not has_feint:
            _fail(failures, "weapon_audit: %s has no feint move" % wname)
        if not has_parry:
            _fail(failures, "weapon_audit: %s has no parry-counter move" % wname)


## Tier 3.2 (weapon audit): angle_variance_deg within expected range per weapon weight class.


## Tier 3.2 (weapon audit): angle_variance_deg within expected range per weapon weight class.
static func _run_weapon_angle_variance_ranges(failures: PackedStringArray) -> void:
    var variance_ranges: Dictionary = {
        "DAGGER": [5, 8],
        "SWORD": [7, 12],
        "AXE": [9, 14],
        "MACE": [9, 14],
        "SPEAR": [7, 16],
    }
    for wname in variance_ranges:
        var range_bounds: Array = variance_ranges[wname]
        var v_min: int = range_bounds[0]
        var v_max: int = range_bounds[1]
        var wep: Weapon = HarnessFixtures.get_cached_weapon(wname)
        if wep == null:
            continue
        var weapon_move_ids: Array = wep.attack_types.keys()
        for move_id in weapon_move_ids:
            if move_id is String:
                var mdef: Dictionary = WeaponConstants.get_move(move_id)
                if mdef.is_empty():
                    continue
                if mdef.has("angle_variance_deg"):
                    var av: int = int(mdef["angle_variance_deg"])
                    if av < v_min or av > v_max:
                        _fail(
                            failures,
                            (
                                "weapon_audit: %s move '%s' angle_variance=%d outside [%d, %d]"
                                % [wname, move_id, av, v_min, v_max]
                            )
                        )


## Tier 3.2: **`GuardLineUpdater.set_guard_deflected`**  -  when **`severity`** is absent, **`guard_deflect_blend`**
## matches **`parry_deflect_severity_from_margin_ratio(margin_ratio)`**; explicit **`severity`** wins if both are set.


## Tier 3.2: **`GuardLineUpdater.set_guard_deflected`**  -  when **`severity`** is absent, **`guard_deflect_blend`**
## matches **`parry_deflect_severity_from_margin_ratio(margin_ratio)`**; explicit **`severity`** wins if both are set.
static func _run_guard_line_deflected_severity_from_margin_ratio(failures: PackedStringArray) -> void:
    var c1: Dictionary = {"guard_line": "high", "combatant_id": 1, "alive": true}
    var clash_margin: Dictionary = {
        "parry_control": 0.3,
        "margin_ratio": 1.5,
        "defender_guard_line": "low",
        "contact_type": "stab",
        "alignment": 0.9,
    }
    GuardLineUpdater.set_guard_deflected(c1, "spear_thrust", "", "low", clash_margin)
    var want_from_margin: float = CombatConstants.parry_deflect_severity_from_margin_ratio(1.5)
    if not is_equal_approx(float(c1.get("guard_deflect_blend", -1.0)), want_from_margin):
        _fail(
            failures,
            (
                "guard_deflect_blend: margin-only clash want %.4f got %.4f"
                % [want_from_margin, float(c1.get("guard_deflect_blend", -1.0))]
            )
        )
    var clash_both: Dictionary = clash_margin.duplicate(true)
    clash_both["severity"] = 0.11
    clash_both["margin_ratio"] = 2.0
    var c2: Dictionary = {"guard_line": "high", "combatant_id": 2, "alive": true}
    GuardLineUpdater.set_guard_deflected(c2, "spear_thrust", "", "low", clash_both)
    if not is_equal_approx(float(c2.get("guard_deflect_blend", -1.0)), 0.11):
        _fail(
            failures,
            (
                "guard_deflect_blend: explicit severity should win when both keys set (want 0.11 got %.4f)"
                % float(c2.get("guard_deflect_blend", -1.0))
            )
        )


## Godot **4.6.stable** global RNG: **`seed(1)`** yields **`attack_hit`** on the afterblow execute path for the SWORD
## 1v1 **`_afterblow_harness_seed_pending_cut`** fixture (avoids scanning thousands of seeds in **`run_all()`**).

## Tier 3.3 harness: deterministic **`pending_attack`** (cut + stamped geometry) so **`AfterblowHandler`** ->
## **`_execute_attack`** does not depend on wind-up RNG.


## Tier 3.3 harness: deterministic **`pending_attack`** (cut + stamped geometry) so **`AfterblowHandler`** ->
## **`_execute_attack`** does not depend on wind-up RNG.
static func _afterblow_harness_seed_pending_cut(mgr: Node, attacker_index: int, defender_index: int) -> void:
    var atk: Dictionary = mgr.combatants[attacker_index]
    var defc: Dictionary = mgr.combatants[defender_index]
    var weapon = EntityAccess.get_weapon(atk)
    var attack_type: String = WeaponConstants.ATTACK_TYPE_CUT
    if EntityAccess.weapon_has_attack_types(weapon):
        var types_a: Array = EntityAccess.weapon_attack_types(weapon)
        if types_a.has(WeaponConstants.ATTACK_TYPE_CUT):
            attack_type = WeaponConstants.ATTACK_TYPE_CUT
        elif not types_a.is_empty():
            attack_type = str(types_a[0])
    var archetype: Dictionary = EntityAccess.weapon_archetype_for_move(weapon, attack_type)
    var pa: Dictionary = {
        "target_id": EntityAccess.id_int(defc),
        "intensity": 0.88,
        "power": 0.72,
        "follow_through": 0.68,
        "attack_type": attack_type,
        "archetype": archetype,
    }
    StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, atk, defc, pa)
    StrikeStamping.stamp_strike_realism_on_pa(mgr, atk, defc, pa, weapon, attack_type)
    atk["state"] = CombatConstants.STATE_WIND_UP
    atk["state_timer"] = 0.0
    atk["state_duration"] = 0.5
    atk["pending_attack"] = pa
    defc.erase("off_balance_until")
    # Afterblow: attacker (index) executes against defender (index). The guard value must be set on the
    # combatant that will DEFEND during _execute_attack -- i.e. the defender. In the harness tests,
    # _afterblow_harness_seed_pending_cut(mgr, 1, 0) sets up combatant 1 as initial attacker and
    # combatant 0 as initial defender. But afterblow reverses roles: combatant 0 attacks, combatant 1 defends.
    # Set guard=0 on the actual defender (combatant at defender_index from caller's perspective =
    # mgr.combatants[defender_index]).
    mgr.combatants[defender_index]["guard"] = 0.0


## Tier 3.3: **`outcome` == `"deflected"`** -> **`_execute_afterblow`** (**hindrance 0**) ->
## **`CombatManager._execute_attack`**; fixed **`seed(1)`** (**`_AFTERBLOW_EXECUTE_HIT_SEED`**) must yield
## **`recovery_cause` == `attack_hit`** and **`afterblow_damage_mult` == 1.0** (via harness meta on manager).


## Tier 3.3: **`outcome` == `"deflected"`** -> **`_execute_afterblow`** (**hindrance 0**) ->
## **`CombatManager._execute_attack`**; fixed **`seed(1)`** (**`_AFTERBLOW_EXECUTE_HIT_SEED`**) must yield
## **`recovery_cause` == `attack_hit`** and **`afterblow_damage_mult` == 1.0** (via harness meta on manager).
static func _run_afterblow_deflected_triggers_full_resolve_hit(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_EXECUTE_HIT_SEED)
    var mgr: Node = MgrScript.new()
    mgr.set_meta(HARNESS_META_RECORD_AFTERBLOW_MULT, true)
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    _afterblow_harness_seed_pending_cut(mgr, 1, 0)
    var atk: Dictionary = mgr.combatants[1]
    var tid: int = EntityAccess.id_int(atk)
    var rd: Dictionary = {
        "part": "chest",
        "outcome": "deflected",
        "final_cut": 0.0,
        "final_blunt": 0.0,
        "final_bone": 0.0,
    }
    print(
        (
            "[AFTERBLOW_DEBUG] deflected: tgt_state=%s tgt_guard=%s"
            % [EntityAccess.state_str(atk), str(mgr.combatants[0].get("guard", "?"))]
        )
    )
    if not AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
        _fail(failures, "afterblow_deflected_hit: try_afterblow false (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
        mgr.remove_meta(HARNESS_META_RECORD_AFTERBLOW_MULT)
        if mgr.has_meta(HARNESS_META_LAST_AFTERBLOW_MULT):
            mgr.remove_meta(HARNESS_META_LAST_AFTERBLOW_MULT)
        _free_manager_restore_global_rng(mgr)
        return
    if str(atk.get("recovery_cause", "")) != "attack_hit":
        _fail(
            failures,
            (
                "afterblow_deflected_hit: want recovery_cause attack_hit got %s (seed=%d)"
                % [str(atk.get("recovery_cause", "")), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    if EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
        _fail(
            failures,
            (
                "afterblow_deflected_hit: want recovering got %s (seed=%d)"
                % [EntityAccess.state_str(atk), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    if not EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
        _fail(failures, "afterblow_deflected_hit: pending_attack not empty (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
    if not mgr.has_meta(HARNESS_META_LAST_AFTERBLOW_MULT):
        _fail(
            failures,
            "afterblow_deflected_hit: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED
        )
    elif not is_equal_approx(float(mgr.get_meta(HARNESS_META_LAST_AFTERBLOW_MULT)), 1.0):
        _fail(
            failures,
            (
                "afterblow_deflected_hit: want afterblow_damage_mult 1.0 got %s (seed=%d)"
                % [str(mgr.get_meta(HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    mgr.remove_meta(HARNESS_META_RECORD_AFTERBLOW_MULT)
    mgr.remove_meta(HARNESS_META_LAST_AFTERBLOW_MULT)
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: low hybrid hindrance (**<= `AFTERBLOW_HINDRANCE_ALLOW`**) -> **`_execute_afterblow`** stamps
## **`afterblow_damage_mult` < 1.0**; same fixed seed + **`attack_hit`** resolve.


## Tier 3.3: low hybrid hindrance (**<= `AFTERBLOW_HINDRANCE_ALLOW`**) -> **`_execute_afterblow`** stamps
## **`afterblow_damage_mult` < 1.0**; same fixed seed + **`attack_hit`** resolve.
static func _run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_EXECUTE_HIT_SEED)
    var mgr: Node = MgrScript.new()
    mgr.set_meta(HARNESS_META_RECORD_AFTERBLOW_MULT, true)
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    _afterblow_harness_seed_pending_cut(mgr, 1, 0)
    var atk: Dictionary = mgr.combatants[1]
    var tid: int = EntityAccess.id_int(atk)
    var rd: Dictionary = {
        "part": "chest",
        "outcome": "hit",
        "final_cut": 5.0,
        "final_blunt": 0.0,
        "final_bone": 0.0,
    }
    if not AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
        _fail(failures, "afterblow_allow_hit: try_afterblow false (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
        mgr.remove_meta(HARNESS_META_RECORD_AFTERBLOW_MULT)
        if mgr.has_meta(HARNESS_META_LAST_AFTERBLOW_MULT):
            mgr.remove_meta(HARNESS_META_LAST_AFTERBLOW_MULT)
        _free_manager_restore_global_rng(mgr)
        return
    if str(atk.get("recovery_cause", "")) != "attack_hit":
        _fail(
            failures,
            (
                "afterblow_allow_hit: want recovery_cause attack_hit got %s (seed=%d)"
                % [str(atk.get("recovery_cause", "")), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    if not mgr.has_meta(HARNESS_META_LAST_AFTERBLOW_MULT):
        _fail(
            failures, "afterblow_allow_hit: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED
        )
    elif absf(float(mgr.get_meta(HARNESS_META_LAST_AFTERBLOW_MULT)) - 0.8) > 0.001:
        _fail(
            failures,
            (
                "afterblow_allow_hit: want afterblow_damage_mult 0.8 (hindrance 0.2) got %s (seed=%d)"
                % [str(mgr.get_meta(HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    mgr.remove_meta(HARNESS_META_RECORD_AFTERBLOW_MULT)
    mgr.remove_meta(HARNESS_META_LAST_AFTERBLOW_MULT)
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: hindrance strictly between **`AFTERBLOW_HINDRANCE_ALLOW`** and **`AFTERBLOW_HINDRANCE_BLOCK`** ->
## **`randf() < hindrance`** cancels (**`_cancel_pending`**, **`try_afterblow` false**); fixed **`seed(2)`** on the same
## fixture + chest **`final_cut` 11.25** (hybrid hindrance **0.45**).


## Tier 3.3: hindrance strictly between **`AFTERBLOW_HINDRANCE_ALLOW`** and **`AFTERBLOW_HINDRANCE_BLOCK`** ->
## **`randf() < hindrance`** cancels (**`_cancel_pending`**, **`try_afterblow` false**); fixed **`seed(2)`** on the same
## fixture + chest **`final_cut` 11.25** (hybrid hindrance **0.45**).
static func _run_afterblow_mid_hindrance_rand_cancel(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED)
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    _afterblow_harness_seed_pending_cut(mgr, 1, 0)
    var atk: Dictionary = mgr.combatants[1]
    var tid: int = EntityAccess.id_int(atk)
    var rd: Dictionary = {
        "part": "chest",
        "outcome": "hit",
        "final_cut": 11.25,
        "final_blunt": 0.0,
        "final_bone": 0.0,
    }
    if AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: try_afterblow should be false (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED
            )
        )
        _free_manager_restore_global_rng(mgr)
        return
    if EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: want recovering got %s (seed=%d)"
                % [EntityAccess.state_str(atk), _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED]
            )
        )
    if not EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: pending_attack should clear (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED
            )
        )
    if absf(float(atk.get(DataKeys.PA_STATE_DURATION, 0.0)) - CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S) > 0.0001:
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: state_duration want AFTERBLOW_CANCELLED_RECOVERY_S got %s (seed=%d)"
                % [str(atk.get(DataKeys.PA_STATE_DURATION)), _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: middle hindrance + **`randf() >= hindrance`** -> **`_execute_afterblow`** (**`afterblow_damage_mult`
## ~0.55**) + full resolve **`attack_hit`**; fixed **`seed(0)`**.


## Tier 3.3: middle hindrance + **`randf() >= hindrance`** -> **`_execute_afterblow`** (**`afterblow_damage_mult`
## ~0.55**) + full resolve **`attack_hit`**; fixed **`seed(0)`**.
static func _run_afterblow_mid_hindrance_rand_executes_hit(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED)
    var mgr: Node = MgrScript.new()
    mgr.set_meta(HARNESS_META_RECORD_AFTERBLOW_MULT, true)
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    _afterblow_harness_seed_pending_cut(mgr, 1, 0)
    var atk: Dictionary = mgr.combatants[1]
    var tid: int = EntityAccess.id_int(atk)
    var rd: Dictionary = {
        "part": "chest",
        "outcome": "hit",
        "final_cut": 11.25,
        "final_blunt": 0.0,
        "final_bone": 0.0,
    }
    if not AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: try_afterblow should be true (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED
            )
        )
        mgr.remove_meta(HARNESS_META_RECORD_AFTERBLOW_MULT)
        if mgr.has_meta(HARNESS_META_LAST_AFTERBLOW_MULT):
            mgr.remove_meta(HARNESS_META_LAST_AFTERBLOW_MULT)
        _free_manager_restore_global_rng(mgr)
        return
    if str(atk.get("recovery_cause", "")) != "attack_hit":
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: want recovery_cause attack_hit got %s (seed=%d)"
                % [str(atk.get("recovery_cause", "")), _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED]
            )
        )
    if not mgr.has_meta(HARNESS_META_LAST_AFTERBLOW_MULT):
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: missing harness afterblow mult meta (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED
            )
        )
    elif not is_equal_approx(float(mgr.get_meta(HARNESS_META_LAST_AFTERBLOW_MULT)), 0.55):
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: want afterblow_damage_mult 0.55 got %s (seed=%d)"
                % [str(mgr.get_meta(HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED]
            )
        )
    mgr.remove_meta(HARNESS_META_RECORD_AFTERBLOW_MULT)
    mgr.remove_meta(HARNESS_META_LAST_AFTERBLOW_MULT)
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: **`GuardLineUpdater.set_guard_from_move`** copies move **`attack_line`** into **`guard_line`** and syncs
## **`guard_zone`** (clears deflect keys).


## Tier 3.3: **`GuardLineUpdater.set_guard_from_move`** copies move **`attack_line`** into **`guard_line`** and syncs
## **`guard_zone`** (clears deflect keys).
static func _run_guard_from_move_sets_guard_line_and_zone(failures: PackedStringArray) -> void:
    var c: Dictionary = {"guard_line": "low", "guard_zone": "left_leg", "combatant_id": 901, "alive": true}
    GuardLineUpdater.set_guard_from_move(c, "oberhau", "")
    var want_line: String = str(WeaponConstants.get_move("oberhau").get("attack_line", "high"))
    if str(c.get("guard_line", "")) != want_line:
        _fail(failures, "guard_from_move: oberhau want guard_line %s got %s" % [want_line, str(c.get("guard_line"))])
    if c.has("guard_deflect_blend") or c.has("guard_deflect_from_line"):
        _fail(failures, "guard_from_move: should clear deflect keys")
    var want_zone: String = CombatConstants.guard_zone_for_guard_line(want_line)
    if str(c.get("guard_zone", "")) != want_zone:
        _fail(
            failures,
            "guard_from_move: guard_zone for %s want %s got %s" % [want_line, want_zone, str(c.get("guard_zone"))]
        )


## Tier 3.3: **`AfterblowHandler.try_afterblow`**  -  no **`pending_attack`** -> **false** (no **`_execute_attack`**).


## Tier 3.3: **`AfterblowHandler.try_afterblow`**  -  no **`pending_attack`** -> **false** (no **`_execute_attack`**).
static func _run_afterblow_no_pending_returns_false(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var tgt: Dictionary = mgr.combatants[1]
    tgt["pending_attack"] = {}
    tgt["state"] = CombatConstants.STATE_WIND_UP
    var tid: int = EntityAccess.id_int(tgt)
    if AfterblowHandler.try_afterblow(mgr, 0, tid, {"part": "chest", "outcome": "hit", "final_cut": 1.0}, 1.0):
        _fail(failures, "afterblow_no_pending: expected false")
    _free_manager(mgr)


## Tier 3.3: **`AfterblowHandler.try_afterblow`**  -  not **`STATE_WIND_UP`** -> **false**.


## Tier 3.3: **`AfterblowHandler.try_afterblow`**  -  not **`STATE_WIND_UP`** -> **false**.
static func _run_afterblow_wrong_state_returns_false(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var tgt: Dictionary = mgr.combatants[1]
    tgt["pending_attack"] = {"target_id": 0, "attack_type": "thrust"}
    tgt["state"] = CombatConstants.STATE_WAITING
    var tid: int = EntityAccess.id_int(tgt)
    if AfterblowHandler.try_afterblow(mgr, 0, tid, {"part": "chest", "outcome": "hit", "final_cut": 1.0}, 1.0):
        _fail(failures, "afterblow_wrong_state: expected false")
    _free_manager(mgr)


## Tier 3.3: **`AfterblowHandler`** hybrid hindrance >= **`AFTERBLOW_HINDRANCE_BLOCK`** cancels **`pending_attack`** (no
## **`_execute_attack`**).


## Tier 3.3: **`AfterblowHandler`** hybrid hindrance >= **`AFTERBLOW_HINDRANCE_BLOCK`** cancels **`pending_attack`** (no
## **`_execute_attack`**).
static func _run_afterblow_hindrance_block_cancels_pending(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var tgt: Dictionary = mgr.combatants[1]
    tgt["state"] = CombatConstants.STATE_WIND_UP
    tgt["pending_attack"] = {"target_id": 0, "attack_type": "thrust"}
    var tid: int = EntityAccess.id_int(tgt)
    var rd: Dictionary = {
        "part": "right_arm",
        "outcome": "hit",
        "final_cut": 40.0,
        "final_blunt": 0.0,
        "final_bone": 0.0,
    }
    if AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
        _fail(failures, "afterblow_block: expected false (hindered cancel)")
    if EntityAccess.state_str(tgt) != CombatConstants.STATE_RECOVERING:
        _fail(failures, "afterblow_block: want recovering got %s" % str(tgt.get("state")))
    if not EntityAccess.nested_dictionary_read(tgt, "pending_attack").is_empty():
        _fail(failures, "afterblow_block: pending_attack should clear")
    if absf(float(tgt.get(DataKeys.PA_STATE_DURATION, 0.0)) - CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S) > 0.0001:
        _fail(
            failures,
            (
                "afterblow_block: state_duration want AFTERBLOW_CANCELLED_RECOVERY_S got %s"
                % str(tgt.get(DataKeys.PA_STATE_DURATION))
            )
        )
    _free_manager(mgr)


static func _run_ai_attrition_offense_mult_duel_vs_line(failures: PackedStringArray) -> void:
    var mgr_d: Node = MgrScript.new()
    mgr_d.register(_new_entity("SWORD"), "player")
    mgr_d.register(_new_entity("SWORD"), "enemy")
    mgr_d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var m_duel: float = AIPicker._attrition_offense_weight_mult(mgr_d, mgr_d.combatants[0])
    _free_manager(mgr_d)
    if absf(m_duel - CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT) > 0.001:
        _fail(
            failures,
            "ai_skirmish_mult: 1v1 want %.4f got %.4f" % [CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT, m_duel]
        )
    var mgr_l: Node = MgrScript.new()
    for _i in 4:
        mgr_l.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr_l.register(_new_entity("SWORD"), "enemy")
    mgr_l.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
    var m_line: float = AIPicker._attrition_offense_weight_mult(mgr_l, mgr_l.combatants[0])
    _free_manager(mgr_l)
    if absf(m_line - 1.0) > 0.001:
        _fail(failures, "ai_skirmish_mult: 4v4 want 1.0 got %.4f" % m_line)


static func _run_wind_up_duration_bounded_for_move(failures: PackedStringArray) -> void:
    if CombatTiming.guard_transition_mult(0.0) > CombatConstants.GUARD_TRANSITION_MULT_MAX + 0.001:
        _fail(
            failures,
            (
                "wind_up_bound: guard_transition_mult(0) %.3f exceeds GUARD_TRANSITION_MULT_MAX"
                % CombatTiming.guard_transition_mult(0.0)
            )
        )
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("MACE"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(mgr.combatants[1])
    var ent: CoreEntity = EntityAccess.scene_node(p) as CoreEntity
    for leg_part in ["left_leg", "right_leg"]:
        _harness_destroy_limb(ent, leg_part)
    p["guard_line"] = "low"
    Footwork.apply_attack_step_on_windup(p, "high")
    seed(90212)
    WindUpStarter.start(mgr, p_id, e_id, "overhead_strike")
    var dur: float = float(p.get(DataKeys.PA_STATE_DURATION, 0.0))
    if dur > CombatConstants.WIND_UP_DURATION_MAX_S + 0.001:
        _fail(
            failures,
            "wind_up_bound: overhead_strike want <= %.3fs got %.3fs" % [CombatConstants.WIND_UP_DURATION_MAX_S, dur]
        )
    var pa: Dictionary = EntityAccess.nested_dictionary_read(p, "pending_attack")
    if float(pa.get("wind_up_duration", 0.0)) > CombatConstants.WIND_UP_DURATION_MAX_S + 0.001:
        _fail(
            failures,
            "wind_up_bound: pending_attack wind_up_duration %.3fs exceeds cap" % float(pa.get("wind_up_duration", 0.0))
        )
    _free_manager_restore_global_rng(mgr)


## **MACE** weak tap: when raw momentum blunt is below **`BLUNT_DAMAGE_MIN`**, slip path stays sub-min; clamped helper
## still floors to min.


## **MACE** weak tap: when raw momentum blunt is below **`BLUNT_DAMAGE_MIN`**, slip path stays sub-min; clamped helper
## still floors to min.
static func _run_kinematic_delivery_mace_weak_tap_pre_blunt_below_baseline_min(failures: PackedStringArray) -> void:
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
    if mace == null:
        _fail(failures, "kin_mace_weak: missing MACE weapon")
        return
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai: AttackInstance = AttackInstance.new("direct_blow", 0.35)
    ai.archetype = arch
    # Head contact is capped at BLUNT_HEAD_MAX_CONTACT_CM (2.5) for the damage pressure formula, so the mace
    # produces ~10x more blunt pressure per unit momentum than the old full 8 cm face. A weak tap must therefore
    # be far slower to stay below BLUNT_DAMAGE_MIN (threshold ~0.49 m/s at strength 52).
    ai.velocity_m_s = 0.35
    var str_weak: float = 52.0
    var raw: float = WeaponDamageHelper.compute_pre_armor_blunt_momentum_raw(mace, ai, str_weak, 1.0)
    if raw >= WeaponConstants.BLUNT_DAMAGE_MIN:
        _fail(
            failures,
            (
                "kin_mace_weak: fixture raw %.4f should be < BLUNT_DAMAGE_MIN %.4f"
                % [raw, WeaponConstants.BLUNT_DAMAGE_MIN]
            )
        )
        return
    var slip: float = WeaponDamageHelper.compute_blunt_slip_pre_armor(mace, ai, str_weak, 1.0, 0.0)
    var clamped: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, ai, str_weak, 1.0)
    if slip >= WeaponConstants.BLUNT_DAMAGE_MIN - 0.02:
        _fail(failures, "kin_mace_weak: slip %.4f should stay below BLUNT_DAMAGE_MIN" % slip)
    if clamped < WeaponConstants.BLUNT_DAMAGE_MIN - 0.02:
        _fail(failures, "kin_mace_weak: clamped helper should floor to min got %.4f" % clamped)
    if slip >= clamped - 0.02:
        _fail(failures, "kin_mace_weak: slip %.4f should be below clamped %.4f" % [slip, clamped])


## Slip path: **`strike_momentum_mult`** scales **`pre_blunt_applied`** at **`v=11`** without dagger fixture boost
## (locks **`compute_blunt_slip_pre_armor`**).


## Slip path: **`strike_momentum_mult`** scales **`pre_blunt_applied`** at **`v=11`** without dagger fixture boost
## (locks **`compute_blunt_slip_pre_armor`**).
static func _run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11(failures: PackedStringArray) -> void:
    var vo: float = 11.0
    var mult: float = 1.32
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var base: Dictionary = KinematicDeliveryPartialParryTests._kin_dmg_integration_sample(
        vo, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
    )
    var shaped: Dictionary = KinematicDeliveryPartialParryTests._kin_dmg_integration_sample(
        vo, 1.0, 1.0, {"strike_momentum_mult": mult}, "SWORD", "oberhau", 1.0, arch
    )
    var b_blunt: float = float(base["pre_blunt"])
    var s_blunt: float = float(shaped["pre_blunt"])
    _free_manager(base["mgr"] as Node)
    _free_manager(shaped["mgr"] as Node)
    if b_blunt <= 0.01:
        _fail(failures, "kin_slip_mom_v11: baseline pre_blunt too small %.6f" % b_blunt)
    if absf(s_blunt / b_blunt - mult) > 0.05:
        _fail(
            failures,
            (
                "kin_slip_mom_v11: pre_blunt ratio %.4f want %.4f (base=%.6f shaped=%.6f)"
                % [s_blunt / b_blunt, mult, b_blunt, s_blunt]
            )
        )


## Mid-combat arm loss: pending wind-up resolves **`skip`** with no target damage (**`can_melee_threaten`** / arm gate).


## Mid-combat arm loss: pending wind-up resolves **`skip`** with no target damage (**`can_melee_threaten`** / arm gate).
static func _run_resolve_aborts_when_threat_lost_mid_combat_arm_loss(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = EntityAccess.id_int(mgr.combatants[0])
    var e_id: int = EntityAccess.id_int(mgr.combatants[1])
    WindUpStarter.start(mgr, p_id, e_id, "thrust")
    var p: Dictionary = mgr.combatants[0]
    var en_ent: CoreEntity = EntityAccess.scene_node(mgr.combatants[1]) as CoreEntity
    var chest_before: float = float(en_ent.body_cutting.get("chest", 0.0))
    var arm: String = EntityAccess.get_attacking_arm(p)
    if arm.is_empty():
        arm = "right_arm"
    var ent: CoreEntity = EntityAccess.scene_node(p) as CoreEntity
    _harness_destroy_limb(ent, arm)
    if not EntityAccess.get_attacking_arm(p).is_empty():
        _harness_destroy_limb(ent, "left_arm")
    if not EntityAccess.get_attacking_arm(p).is_empty():
        _fail(failures, "arm_loss_abort: could not strip attacking arm on setup")
        _free_manager(mgr)
        return
    var res: Dictionary = AttackResolver.resolve_attack(mgr, p_id)
    if str(res.get("action", "")) != "skip":
        _fail(failures, "arm_loss_abort: expected skip after arm loss got %s" % str(res.get("action", "")))
    var chest_after: float = float(en_ent.body_cutting.get("chest", 0.0))
    if chest_after < chest_before - 0.01:
        _fail(failures, "arm_loss_abort: enemy chest damage %.2f -> %.2f on skip" % [chest_before, chest_after])
    _free_manager(mgr)


## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------
## Phase 3 (MS-L8): post-strike momentum  -  attacker presses target after successful strike.
## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------


## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------
## Phase 3 (MS-L8): post-strike momentum  -  attacker presses target after successful strike.
## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------
static func _run_ms_l8_post_strike_momentum_presses_target(failures: PackedStringArray) -> void:
    # Build a 1v1 scenario where player just struck enemy (stamp the tick).
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var player_id: int = EntityAccess.id_int(player)
    var enemy_id: int = EntityAccess.id_int(enemy)
    # Stamp last_strike_tick and last_strike_target_id to simulate post-strike state.
    player[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = float(mgr.combat_clock)
    player[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = enemy_id
    player["state"] = CombatConstants.STATE_WAITING
    player["gauge"] = 100.0
    # Build actions manually (mimicking what AvailableActionsBuilder produces for a WAITING fighter).
    var actions: Array = [
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
    ]
    # MentalStackDecider should pick from post-strike layer (press the target).
    var picked: Dictionary = MentalStackDecider.try_pick(actions, player_id, mgr)
    if picked.is_empty():
        _fail(failures, "ms_l8_post_strike: MentalStackDecider returned empty  -  expected post-strike layer pick")
        _free_manager(mgr)
        return
    var layer: String = str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if layer != CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE:
        _fail(
            failures,
            "ms_l8_post_strike: expected layer=%s got %s" % [CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE, layer]
        )
    var move_id: String = str(picked.get("move_id", ""))
    # The pick should target the struck enemy (melee strike or attempt_close).
    if int(picked.get("target_id", -1)) != enemy_id:
        _fail(
            failures, "ms_l8_post_strike: pick targets %d not enemy %d" % [int(picked.get("target_id", -1)), enemy_id]
        )
    _free_manager(mgr)


## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------
## Phase 2: feint resistance gate  -  high-readiness settled defenders reject feints.
## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------


## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------
## Phase 2: feint resistance gate  -  high-readiness settled defenders reject feints.
## ---------------------------------------------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------------------------------------------
## -------------------------------------------------------------------------------------------------------
static func _run_mental_stack_feint_resistance_high_readiness(failures: PackedStringArray) -> void:
    # Verify that a high-readiness defender (guard=1.0, WAITING state) suppresses
    # feint dampening shortcuts  -  the soft-damp chain still applies but off-balance /
    # recovering / settled-footwork boosts are suppressed so feints get lower weight
    # than against an unready defender.
    CombatConstants.set_feature_ms_feint_resistance_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var player_id: int = EntityAccess.id_int(player)
    var enemy_id: int = EntityAccess.id_int(enemy)
    # Set defender to high-readiness WAITING state (guard=1.0, no off-balance).
    player["state"] = CombatConstants.STATE_WAITING
    player["guard"] = 1.0
    player.erase("off_balance_until")
    player["gauge"] = 100.0
    # Build actions manually including a feint move targeting the enemy.
    var actions: Array = [
        {"move_id": "oberhau_feint", "target_id": enemy_id, "target_part": "head"},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
    ]
    var w_feint_hr: float = AIPicker._get_action_weight(actions[0], player_id, mgr, true)
    # Verify feint weight is reduced vs a low-readiness defender.
    player["guard"] = 0.5
    var mgr2: Node = MgrScript.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player2: Dictionary = mgr2.combatants[0]
    var enemy2: Dictionary = mgr2.combatants[1]
    player2["state"] = CombatConstants.STATE_WAITING
    player2["guard"] = 0.5
    player2.erase("off_balance_until")
    player2["gauge"] = 100.0
    var w_feint_lr: float = AIPicker._get_action_weight(actions[0], player_id, mgr2, true)
    if w_feint_hr > w_feint_lr * 1.05:
        _fail(
            failures,
            (
                "ms_feint_resist_hr: feint weight high-read=%.6f should be <= low-read %.6f * 1.05"
                % [w_feint_hr, w_feint_lr]
            )
        )
    _free_manager(mgr)
    _free_manager(mgr2)
