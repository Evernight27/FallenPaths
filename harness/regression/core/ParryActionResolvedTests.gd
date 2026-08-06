class_name ParryActionResolvedTests
extends CombatRegressionHarnessCore


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
static func _run_parry_partial_bind_riposte_flags_when_aligned(failures: PackedStringArray) -> void:
    var apply_partial_bind := func(
        attack_angle_deg: float,
        parry_control: float,
        expect_bind: bool,
        label: String,
        seed_stale_bind: bool = false,
        misaligned_erase_bind_key: bool = false
    ) -> void:
        var mgr: Node = MgrScript.new()
        mgr.register(_new_entity("SWORD"), "player")
        mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
        var p: Dictionary = mgr.combatants[0]
        var e: Dictionary = mgr.combatants[1]
        var p_id: int = EntityAccess.id_int(p)
        var e_id: int = EntityAccess.id_int(e)
        p.state = CombatConstants.STATE_WAITING
        p["guard"] = 1.0
        p["guard_line"] = "high"
        p.pending_attack = {}
        if seed_stale_bind:
            p["parry_was_bind"] = true
            p["parry_against_id"] = e_id
            p["parry_bonus_until"] = 1.0e9
        e.state = CombatConstants.STATE_WIND_UP
        e.pending_attack = {
            "target_id": p_id,
            "attack_type": "thrust",
            "effective_attack_line": "high",
            "attack_angle_deg": attack_angle_deg,
            "intensity": 0.5,
            "parry_remaining_ratio": 0.05,
        }
        var pclash: Dictionary = {"parry_control": parry_control, "archetype_id": "stab"}
        AttackResultApplier.apply_result(
            mgr, e_id, {"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
        )
        if expect_bind:
            var dbg_keys: String = "N/A"
            var dbg_atk_line: String = "N/A"
            var dbg_atk_angle: float = -999.0
            var dbg_is_dict: bool = e.pending_attack is Dictionary
            if dbg_is_dict:
                dbg_keys = str(e.pending_attack.keys())
                dbg_atk_line = str(e.pending_attack.get("effective_attack_line", "high"))
                dbg_atk_angle = float(e.pending_attack.get("attack_angle_deg", -999.0))
            var dbg_align: float = -1.0
            if dbg_atk_angle >= 0.0:
                dbg_align = (
                    CombatConstants
                    . get_line_alignment_with_deflect(
                        dbg_atk_line,
                        p,
                        {
                            "attack_angle_deg": dbg_atk_angle,
                            "guard_angle_deg": 0.0,
                        }
                    )
                )
            if not bool(p.get("parry_was_bind", false)):
                _fail(
                    failures,
                    (
                        (
                            "parry_partial_bind %s: parry_was_bind want true got %s "
                            + "(keys=%s atk_angle=%.1f align_approx=%.3f control=%f)"
                        )
                        % [
                            label,
                            str(p.get("parry_was_bind", false)),
                            dbg_keys,
                            dbg_atk_angle,
                            dbg_align,
                            parry_control
                        ]
                    )
                )
            if int(p.get("parry_against_id", -99)) != e_id:
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: parry_against_id want %d got %s"
                        % [label, e_id, str(p.get("parry_against_id", -99))]
                    )
                )
            if not p.has("parry_bonus_until"):
                _fail(failures, "parry_partial_bind %s: expected parry_bonus_until set" % label)
        else:
            if p.has("parry_against_id"):
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: expected no parry_against_id got %s"
                        % [label, str(p.get("parry_against_id", -99))]
                    )
                )
            if p.has("parry_bonus_until"):
                _fail(failures, "parry_partial_bind %s: expected no parry_bonus_until" % label)
            if misaligned_erase_bind_key:
                if p.has("parry_was_bind"):
                    _fail(
                        failures,
                        "parry_partial_bind %s: expected parry_was_bind erased (misaligned / stale clear)" % label
                    )
            else:
                if not p.has("parry_was_bind") or bool(p["parry_was_bind"]):
                    _fail(
                        failures,
                        (
                            "parry_partial_bind %s: want parry_was_bind key false got has=%s val=%s"
                            % [label, str(p.has("parry_was_bind")), str(p.get("parry_was_bind", "<absent>"))]
                        )
                    )
        _free_manager(mgr)

    apply_partial_bind.call(0.0, 0.9, true, "aligned_high_control", false, false)
    # New parry_control curve (alignment^1.8): a thrust at align=1.0 yields ~0.84 control, so 0.65 is a
    # modest-but-real bind; values below PARRY_BIND_CONTROL_THRESHOLD (0.55) must NOT bind.
    apply_partial_bind.call(0.0, 0.65, true, "aligned_low_control", false, false)
    apply_partial_bind.call(0.0, 0.45, false, "aligned_sub_threshold", false, false)
    apply_partial_bind.call(90.0, 0.9, false, "misaligned_high_control", false, true)
    apply_partial_bind.call(90.0, 0.9, false, "misaligned_clears_stale_bind", true, true)


static func _harness_counter_tempo_set_incoming_progress(mgr: Node, attacker_id: int, fraction: float) -> void:
    Fixtures._harness_counter_tempo_set_incoming_progress(mgr, attacker_id, fraction)


## Tier 4.2 counter-tempo pilot: incoming wind-up opens defender **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`**.


## Tier 4.2 counter-tempo pilot: incoming wind-up opens defender **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`**.
static func _run_combat_end_enemy_win_stops_manager(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var ent_player := _new_entity("SWORD")
    mgr.register(ent_player, "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.set_process(true)
    var ended_box: Array = [0]
    mgr.combat_ended.connect(func(_w: String, _d: Node) -> void: ended_box[0] = int(ended_box[0]) + 1)
    mgr._end_combat_phase("enemy", ent_player)
    if not mgr.medical_phase:
        _fail(failures, "combat_end_enemy_win: medical_phase should be set true for halt_losing_side")
    if mgr.is_processing():
        _fail(failures, "combat_end_enemy_win: manager should stop processing")
    if not mgr.combat_resolution_closed:
        _fail(failures, "combat_end_enemy_win: combat_resolution_closed should be true")
    for _i in 24:
        ProcessTick.tick(mgr, 0.05)
    if int(ended_box[0]) != 1:
        _fail(
            failures,
            "combat_end_enemy_win: combat_ended should emit once after manual ticks (got %d)" % int(ended_box[0])
        )
    _free_manager(mgr)


## Tier 5.0: full-stop **`duel_auto_end_detection`** — runs a seeded 1v1 SWORD duel for up to 120 s, asserts combat resolves (medical_phase or single survivor). Validates the auto-end chain (winner check -> phase end -> manager stop) under full AI-driven simulation.
## Realism note: armored sword duels run longer than a minute (seeded SWORD duel resolves ~68 s, up to ~76 s across weapons), so the budget is 120 s — generous vs. real fight length while still bounded.


static func _run_duel_auto_end_detection(failures: PackedStringArray) -> void:
    seed(42)
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var elapsed: float = 0.0
    const MAX_TICKS := 2400
    for _i in MAX_TICKS:
        for c in mgr.combatants:
            if c is not Dictionary: continue
            if not EntityAccess.alive_bool(c): continue
            if bool(c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)): continue
            var st: String = EntityAccess.state_str(c)
            if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING: continue
            if EntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD: continue
            var cid: int = EntityAccess.id_int(c)
            var actions: Array = mgr.get_available_actions(cid)
            var log_side: String = "player" if EntityAccess.is_player_side(c) else "enemy"
            AIPicker.resolve_picked_turn_or_skip(mgr, cid, actions, log_side)
        ProcessTick.tick(mgr, 0.05)
        elapsed += 0.05
        if mgr.medical_phase: break
    var players_alive := 0
    var enemies_alive := 0
    for c in mgr.combatants:
        if c is not Dictionary or not EntityAccess.alive_bool(c): continue
        if bool(c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)): continue
        if EntityAccess.is_player_side(c): players_alive += 1
        else: enemies_alive += 1
    var single_survivor := (players_alive + enemies_alive) == 1 and (players_alive + enemies_alive) > 0
    if not mgr.medical_phase and not single_survivor:
        _fail(
            failures,
            "duel_auto_end_timeout: clock=%.2f medical_phase=%s player_alive=%d enemy_alive=%d"
            % [elapsed, str(mgr.medical_phase), players_alive, enemies_alive]
        )
    _free_manager(mgr)


## Tier 4.3: mental stack L1 picks medical when ally in peril.


## Tier 4.3: mental stack L1 picks medical when ally in peril.
static func _run_feint_second_windup_clears_prior_telegraph_before_restamp(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(_FEINT_WINDUP_HARNESS_SEED)
    WindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "left_leg", "feint_part": "head"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
        _fail(
            failures,
            (
                "feint_rewind: first telegraph want head got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    seed(_FEINT_WINDUP_HARNESS_SEED)
    WindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "right_leg", "feint_part": "chest"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "chest":
        _fail(
            failures,
            (
                "feint_rewind: second telegraph want chest got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    if str(e.get("guard_zone", "")) != "chest":
        _fail(failures, "feint_rewind: second guard_zone telegraph want chest got %s" % str(e.get("guard_zone", "")))
    _free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatManager.start`** erases **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on all combatants
## (second **`start()`** without re-**`register`**).


## Tier 4.2: **`CombatManager.start`** erases **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on all combatants
## (second **`start()`** without re-**`register`**).
static func _run_weapon_part_mass_model_normalized(failures: PackedStringArray) -> void:
    for wid in WeaponConstants.get_all_weapon_ids():
        var weapon: Weapon = HarnessFixtures.get_cached_weapon(wid)
        if weapon == null:
            _fail(failures, "weapon_parts: could not create %s" % wid)
            continue
        if not weapon.has_parts():
            _fail(failures, "weapon_parts: %s should define part model data" % wid)
            continue
        var total_fraction: float = 0.0
        for part in weapon.parts:
            if part is Dictionary:
                total_fraction += float((part as Dictionary).get("mass_fraction", 0.0))
        if absf(total_fraction - 1.0) > 0.001:
            _fail(failures, "weapon_parts: %s mass fractions sum %.3f, want 1.000" % [wid, total_fraction])
    var spear: Weapon = HarnessFixtures.get_cached_weapon("SPEAR")
    if spear == null:
        _fail(failures, "weapon_parts: missing spear")
        return
    if spear.get_parry_contact_type() != "shaft":
        _fail(failures, "weapon_parts: spear should parry with shaft, got %s" % spear.get_parry_contact_type())
    var expected_spear_parry_mass: float = spear.mass * 0.85
    if absf(spear.get_parry_part_mass_kg() - expected_spear_parry_mass) > 0.001:
        _fail(
            failures,
            (
                "weapon_parts: spear parry mass %.3f want %.3f"
                % [spear.get_parry_part_mass_kg(), expected_spear_parry_mass]
            )
        )


## Tier 3.2: parry part id selection follows documented fallback order.


## Tier 3.2: parry part id selection follows documented fallback order.
static func _run_weapon_parry_part_selection_fallbacks(failures: PackedStringArray) -> void:
    var parts: Array = [
        {"id": "head", "length_cm": 10, "mass_fraction": 0.65, "parry_eligible": false},
        {"id": "shaft", "length_cm": 60, "mass_fraction": 0.35, "parry_eligible": true}
    ]
    var selector := Callable(Weapon, "parry_part_id_from_parts")
    var preferred: String = str(selector.call(parts, " Shaft "))
    if preferred != "shaft":
        _fail(failures, "weapon_parry_part: normalized preferred id got %s want shaft" % preferred)
    var invalid_preferred: String = str(selector.call(parts, "head"))
    if invalid_preferred != "shaft":
        _fail(failures, "weapon_parry_part: non-eligible preferred should fallback to shaft got %s" % invalid_preferred)
    var missing_preferred: String = str(selector.call(parts, "blade"))
    if missing_preferred != "shaft":
        _fail(failures, "weapon_parry_part: missing preferred should fallback to shaft got %s" % missing_preferred)
    var no_eligible: Array = [
        {"id": "light", "length_cm": 10, "mass_fraction": 0.25, "parry_eligible": false},
        {"id": "heavy", "length_cm": 30, "mass_fraction": 0.75, "parry_eligible": false}
    ]
    var largest: String = str(selector.call(no_eligible, ""))
    if largest != "heavy":
        _fail(failures, "weapon_parry_part: no eligible should fallback to largest mass got %s" % largest)


## Tier 3.2: attack momentum / KE helpers use the intended striking part mass.


## Tier 3.2: attack momentum / KE helpers use the intended striking part mass.
static func _run_weapon_striking_part_mass_model(failures: PackedStringArray) -> void:
    var spear: Weapon = HarnessFixtures.get_cached_weapon("SPEAR")
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
    var axe: Weapon = HarnessFixtures.get_cached_weapon("AXE")
    if spear == null or mace == null or axe == null:
        _fail(failures, "weapon_striking_parts: missing spear/mace/axe")
        return
    var spear_stab: float = spear.get_striking_part_mass_kg(" STAB ")
    var spear_blunt: float = spear.get_striking_part_mass_kg(WeaponConstants.ATTACK_TYPE_BLUNT)
    var mace_blunt: float = mace.get_striking_part_mass_kg("BLUNT")
    var axe_stab: float = axe.get_striking_part_mass_kg(WeaponConstants.ATTACK_TYPE_STAB)
    if absf(spear_stab - spear.mass * 0.15) > 0.001:
        _fail(failures, "weapon_striking_parts: spear stab mass %.3f want %.3f" % [spear_stab, spear.mass * 0.15])
    if absf(spear_blunt - spear.mass * 0.85) > 0.001:
        _fail(failures, "weapon_striking_parts: spear blunt mass %.3f want %.3f" % [spear_blunt, spear.mass * 0.85])
    if absf(mace_blunt - mace.mass * 0.7) > 0.001:
        _fail(failures, "weapon_striking_parts: mace blunt mass %.3f want %.3f" % [mace_blunt, mace.mass * 0.7])
    if absf(axe_stab - axe.mass * 0.15) > 0.001:
        _fail(failures, "weapon_striking_parts: axe stab mass %.3f want %.3f" % [axe_stab, axe.mass * 0.15])


## Tier 3.0 (+ Tier 5 damage-flow anchor): **`WeaponDamageHelper.kinematic_delivery`** overrides move inference;
## **`kinematic_mixed_blend`** **0** / **1** KE + effective velocity match pure thrust / swing at the same move +
## intensity; interior blend **0.5** velocity = **`lerp`** of pure thrust vs pure swing speeds; mixed blend **0.5** KE =
## **`lerp`** of thrust vs swing KE **at that same blended `v`** (not **`lerp`** of pure-mode KE at each mode's
## **`v`**). Repeats the mixed **0** / **0.5** / **1** bracket checks on **AXE** **`diagonal_chop`** and **DAGGER**
## **`quick_slash`** (extra cut fixtures; **`spear_slash`** can degenerate thrust/swing KE at some intensities).


## Tier 3.0 (+ Tier 5 damage-flow anchor): **`WeaponDamageHelper.kinematic_delivery`** overrides move inference;
## **`kinematic_mixed_blend`** **0** / **1** KE + effective velocity match pure thrust / swing at the same move +
## intensity; interior blend **0.5** velocity = **`lerp`** of pure thrust vs pure swing speeds; mixed blend **0.5** KE =
## **`lerp`** of thrust vs swing KE **at that same blended `v`** (not **`lerp`** of pure-mode KE at each mode's
## **`v`**). Repeats the mixed **0** / **0.5** / **1** bracket checks on **AXE** **`diagonal_chop`** and **DAGGER**
## **`quick_slash`** (extra cut fixtures; **`spear_slash`** can degenerate thrust/swing KE at some intensities).
static func _run_kinematic_delivery_override_and_mixed_ke_blend_brackets_thrust_swing(
    failures: PackedStringArray
) -> void:
    var empty: Dictionary = {}
    if WeaponDamageHelper.kinematic_delivery(empty, "thrust") != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
        _fail(failures, "kin_del: empty arch + thrust move should infer thrust")
    if WeaponDamageHelper.kinematic_delivery(empty, "oberhau") != WeaponConstants.KINEMATIC_DELIVERY_SWING:
        _fail(failures, "kin_del: empty arch + cut move should infer swing")
    var arch_thrust_override: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    if (
        WeaponDamageHelper.kinematic_delivery(arch_thrust_override, "oberhau")
        != WeaponConstants.KINEMATIC_DELIVERY_THRUST
    ):
        _fail(failures, "kin_del: thrust archetype should override cut move to thrust")
    var arch_swing_override: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    if WeaponDamageHelper.kinematic_delivery(arch_swing_override, "thrust") != WeaponConstants.KINEMATIC_DELIVERY_SWING:
        _fail(failures, "kin_del: swing archetype should override stab move to swing")
    if (
        WeaponDamageHelper.kinematic_delivery({"kinematic_delivery": "mixed"}, "thrust")
        != WeaponConstants.KINEMATIC_DELIVERY_MIXED
    ):
        _fail(failures, "kin_del: mixed archetype should win over stab inference")
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        _fail(failures, "kin_del_mixed: missing sword")
        return
    var move_id: String = "oberhau"
    var inten: float = 0.55
    var ai_thrust: AttackInstance = AttackInstance.new(move_id, inten)
    ai_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_swing: AttackInstance = AttackInstance.new(move_id, inten)
    ai_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_mix0: AttackInstance = AttackInstance.new(move_id, inten)
    ai_mix0.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.0}
    var ai_mix1: AttackInstance = AttackInstance.new(move_id, inten)
    ai_mix1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 1.0}
    var v_th: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_thrust)
    var v_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_swing)
    var v_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix0)
    var v_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix1)
    if absf(v_m0 - v_th) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 0 velocity %.6f should match thrust velocity %.6f" % [v_m0, v_th])
    if absf(v_m1 - v_sw) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 1 velocity %.6f should match swing velocity %.6f" % [v_m1, v_sw])
    var ai_mix_mid: AttackInstance = AttackInstance.new(move_id, inten)
    ai_mix_mid.archetype = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5
    }
    var v_mid: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix_mid)
    var want_mid_v: float = lerpf(v_th, v_sw, 0.5)
    if absf(v_mid - want_mid_v) > 0.001:
        _fail(
            failures,
            "kin_del_mixed: mixed blend 0.5 velocity %.6f want lerp(thrust,swing,0.5)=%.6f" % [v_mid, want_mid_v]
        )
    var ke_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix_mid)
    var ai_th_pin: AttackInstance = AttackInstance.new(move_id, inten)
    ai_th_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    ai_th_pin.velocity_m_s = v_mid
    var ai_sw_pin: AttackInstance = AttackInstance.new(move_id, inten)
    ai_sw_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_sw_pin.velocity_m_s = v_mid
    var ke_th_at_mid_v: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_th_pin)
    var ke_sw_at_mid_v: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_sw_pin)
    var want_ke_mid: float = lerpf(ke_th_at_mid_v, ke_sw_at_mid_v, 0.5)
    if absf(ke_mid - want_ke_mid) > 0.001:
        _fail(
            failures,
            (
                "kin_del_mixed: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
                % [ke_mid, want_ke_mid]
            )
        )
    var ke_th: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_thrust)
    var ke_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_swing)
    var ke_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix0)
    var ke_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix1)
    if ke_th <= 0.05 or ke_sw <= 0.05:
        _fail(failures, "kin_del_mixed: expected positive KE thrust=%.4f swing=%.4f" % [ke_th, ke_sw])
    if absf(ke_m0 - ke_th) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_m0, ke_th])
    if absf(ke_m1 - ke_sw) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_m1, ke_sw])
    ## Second weapon: AXE + diagonal_chop (cut)  -  same mixed brackets (Tier 5.1); avoids **`spear_slash`**
    ## thrust/swing KE degeneracy at some intensities.
    var axe: Weapon = HarnessFixtures.get_cached_weapon("AXE")
    if axe == null:
        _fail(failures, "kin_del_axe: missing axe")
        return
    var move_chop: String = "diagonal_chop"
    var ai_ax_thrust: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_ax_swing: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_ax_m0: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_m0.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.0}
    var ai_ax_m1: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_m1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 1.0}
    var v_ax_th: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_thrust)
    var v_ax_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_swing)
    var v_ax_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_m0)
    var v_ax_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_m1)
    if absf(v_ax_m0 - v_ax_th) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 0 velocity %.6f should match thrust %.6f" % [v_ax_m0, v_ax_th])
    if absf(v_ax_m1 - v_ax_sw) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 1 velocity %.6f should match swing %.6f" % [v_ax_m1, v_ax_sw])
    var ai_ax_mid: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_mid.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5}
    var v_ax_mid: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_mid)
    var want_ax_mid_v: float = lerpf(v_ax_th, v_ax_sw, 0.5)
    if absf(v_ax_mid - want_ax_mid_v) > 0.001:
        _fail(
            failures,
            "kin_del_axe: mixed blend 0.5 velocity %.6f want lerp(thrust,swing,0.5)=%.6f" % [v_ax_mid, want_ax_mid_v]
        )
    var ke_ax_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_mid)
    var ai_ax_th_pin: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_th_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    ai_ax_th_pin.velocity_m_s = v_ax_mid
    var ai_ax_sw_pin: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_sw_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_ax_sw_pin.velocity_m_s = v_ax_mid
    var ke_ax_th_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_th_pin)
    var ke_ax_sw_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_sw_pin)
    var want_ax_ke_mid: float = lerpf(ke_ax_th_at_mid, ke_ax_sw_at_mid, 0.5)
    if absf(ke_ax_mid - want_ax_ke_mid) > 0.001:
        _fail(
            failures,
            (
                "kin_del_axe: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
                % [ke_ax_mid, want_ax_ke_mid]
            )
        )
    var ke_ax_th: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_thrust)
    var ke_ax_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_swing)
    var ke_ax_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_m0)
    var ke_ax_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_m1)
    if ke_ax_th <= 0.05 or ke_ax_sw <= 0.05:
        _fail(failures, "kin_del_axe: expected positive KE thrust=%.4f swing=%.4f" % [ke_ax_th, ke_ax_sw])
    if absf(ke_ax_m0 - ke_ax_th) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_ax_m0, ke_ax_th])
    if absf(ke_ax_m1 - ke_ax_sw) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_ax_m1, ke_ax_sw])
    ## Third weapon: DAGGER + quick_slash (cut)  -  same mixed brackets (Tier 5.1 light weapon coverage).
    var dagger: Weapon = HarnessFixtures.get_cached_weapon("DAGGER")
    if dagger == null:
        _fail(failures, "kin_del_dagger: missing dagger")
        return
    var move_slash: String = "quick_slash"
    var ai_dg_thrust: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_dg_swing: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_dg_m0: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_m0.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.0}
    var ai_dg_m1: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_m1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 1.0}
    var v_dg_th: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_thrust)
    var v_dg_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_swing)
    var v_dg_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_m0)
    var v_dg_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_m1)
    if absf(v_dg_m0 - v_dg_th) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 0 velocity %.6f should match thrust %.6f" % [v_dg_m0, v_dg_th])
    if absf(v_dg_m1 - v_dg_sw) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 1 velocity %.6f should match swing %.6f" % [v_dg_m1, v_dg_sw])
    var ai_dg_mid: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_mid.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5}
    var v_dg_mid: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_mid)
    var want_dg_mid_v: float = lerpf(v_dg_th, v_dg_sw, 0.5)
    if absf(v_dg_mid - want_dg_mid_v) > 0.001:
        _fail(
            failures,
            "kin_del_dagger: mixed blend 0.5 velocity %.6f want lerp(thrust,swing,0.5)=%.6f" % [v_dg_mid, want_dg_mid_v]
        )
    var ke_dg_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_mid)
    var ai_dg_th_pin: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_th_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    ai_dg_th_pin.velocity_m_s = v_dg_mid
    var ai_dg_sw_pin: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_sw_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_dg_sw_pin.velocity_m_s = v_dg_mid
    var ke_dg_th_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_th_pin)
    var ke_dg_sw_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_sw_pin)
    var want_dg_ke_mid: float = lerpf(ke_dg_th_at_mid, ke_dg_sw_at_mid, 0.5)
    if absf(ke_dg_mid - want_dg_ke_mid) > 0.001:
        _fail(
            failures,
            (
                "kin_del_dagger: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
                % [ke_dg_mid, want_dg_ke_mid]
            )
        )
    var ke_dg_th: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_thrust)
    var ke_dg_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_swing)
    var ke_dg_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_m0)
    var ke_dg_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_m1)
    if ke_dg_th <= 0.05 or ke_dg_sw <= 0.05:
        _fail(failures, "kin_del_dagger: expected positive KE thrust=%.4f swing=%.4f" % [ke_dg_th, ke_dg_sw])
    if absf(ke_dg_m0 - ke_dg_th) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_dg_m0, ke_dg_th])
    if absf(ke_dg_m1 - ke_dg_sw) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_dg_m1, ke_dg_sw])


## Tier 5.1: **`velocity_m_s_from_intensity`** must match **`get_effective_velocity_m_s`** when
## **`AttackInstance.velocity_m_s` < 0** (derived path). Intensity **0.05 -> 0.95** increases speed where expected:
## **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (inferred swing, thrust override,
## mixed **`kinematic_mixed_blend` 0.35**), **SPEAR** **`spear_thrust`** (inferred thrust), **MACE** **`direct_blow`**
## (blunt -> swing path).


## Tier 5.1: **`velocity_m_s_from_intensity`** must match **`get_effective_velocity_m_s`** when
## **`AttackInstance.velocity_m_s` < 0** (derived path). Intensity **0.05 -> 0.95** increases speed where expected:
## **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (inferred swing, thrust override,
## mixed **`kinematic_mixed_blend` 0.35**), **SPEAR** **`spear_thrust`** (inferred thrust), **MACE** **`direct_blow`**
## (blunt -> swing path).
static func _run_kinematic_delivery_velocity_from_intensity_bridges_get_effective_and_monotone(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        _fail(failures, "kin_vel_bridge: missing sword")
        return
    var move_id: String = "oberhau"
    var arch_empty: Dictionary = {}
    var arch_thrust: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var arch_mixed: Dictionary = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.35
    }
    for inten in [0.22, 0.78]:
        var ai: AttackInstance = AttackInstance.new(move_id, inten)
        ai.archetype = arch_empty
        var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_empty, sword, move_id)
        var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai)
        if absf(v_eff - v_from_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: swing inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten, v_eff, v_from_i]
                )
            )
        var ai_t: AttackInstance = AttackInstance.new(move_id, inten)
        ai_t.archetype = arch_thrust
        var v_t_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_thrust, sword, move_id)
        var v_t_e: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_t)
        if absf(v_t_e - v_t_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: thrust override inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten, v_t_e, v_t_i]
                )
            )
        var ai_m: AttackInstance = AttackInstance.new(move_id, inten)
        ai_m.archetype = arch_mixed
        var v_m_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_mixed, sword, move_id)
        var v_m_e: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_m)
        if absf(v_m_e - v_m_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: mixed inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten, v_m_e, v_m_i]
                )
            )
    var v_sw_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, sword, move_id)
    var v_sw_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, sword, move_id)
    if v_sw_lo > v_sw_hi + 0.0001:
        _fail(failures, "kin_vel_mono: swing inferred v(0.05)=%.6f > v(0.95)=%.6f" % [v_sw_lo, v_sw_hi])
    if v_sw_hi - v_sw_lo < 0.01:
        _fail(
            failures,
            "kin_vel_mono: swing inferred expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_sw_hi - v_sw_lo]
        )
    var v_th_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_thrust, sword, move_id)
    var v_th_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_thrust, sword, move_id)
    if v_th_lo > v_th_hi + 0.0001:
        _fail(failures, "kin_vel_mono: thrust override v(0.05)=%.6f > v(0.95)=%.6f" % [v_th_lo, v_th_hi])
    if v_th_hi - v_th_lo < 0.01:
        _fail(
            failures,
            "kin_vel_mono: thrust override expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_th_hi - v_th_lo]
        )
    var v_mx_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_mixed, sword, move_id)
    var v_mx_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_mixed, sword, move_id)
    if v_mx_lo > v_mx_hi + 0.0001:
        _fail(failures, "kin_vel_mono: mixed blend v(0.05)=%.6f > v(0.95)=%.6f" % [v_mx_lo, v_mx_hi])
    if v_mx_hi - v_mx_lo < 0.01:
        _fail(
            failures, "kin_vel_mono: mixed blend expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_mx_hi - v_mx_lo]
        )
    ## Stab-inferred thrust: SPEAR + spear_thrust (linear band).
    var spear: Weapon = HarnessFixtures.get_cached_weapon("SPEAR")
    if spear == null:
        _fail(failures, "kin_vel_bridge: missing spear")
        return
    var move_spear: String = "spear_thrust"
    for inten_sp in [0.31, 0.69]:
        var ai_sp: AttackInstance = AttackInstance.new(move_spear, inten_sp)
        ai_sp.archetype = arch_empty
        var v_sp_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_sp, arch_empty, spear, move_spear)
        var v_sp_e: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, ai_sp)
        if absf(v_sp_e - v_sp_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: spear thrust inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%"
                    + ".6f" % [inten_sp, v_sp_e, v_sp_i]
                )
            )
    var v_sp_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, spear, move_spear)
    var v_sp_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, spear, move_spear)
    if v_sp_lo > v_sp_hi + 0.0001:
        _fail(failures, "kin_vel_mono: spear thrust v(0.05)=%.6f > v(0.95)=%.6f" % [v_sp_lo, v_sp_hi])
    if v_sp_hi - v_sp_lo < 0.01:
        _fail(
            failures,
            "kin_vel_mono: spear thrust expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_sp_hi - v_sp_lo]
        )
    ## Blunt contact -> swing kinematic path: MACE + direct_blow.
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
    if mace == null:
        _fail(failures, "kin_vel_bridge: missing mace")
        return
    var move_mace: String = "direct_blow"
    for inten_mc in [0.28, 0.72]:
        var ai_mc: AttackInstance = AttackInstance.new(move_mace, inten_mc)
        ai_mc.archetype = arch_empty
        var v_mc_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_mc, arch_empty, mace, move_mace)
        var v_mc_e: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, ai_mc)
        if absf(v_mc_e - v_mc_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: mace blunt inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten_mc, v_mc_e, v_mc_i]
                )
            )
    var v_mc_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, mace, move_mace)
    var v_mc_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, mace, move_mace)
    if v_mc_lo > v_mc_hi + 0.0001:
        _fail(failures, "kin_vel_mono: mace blunt v(0.05)=%.6f > v(0.95)=%.6f" % [v_mc_lo, v_mc_hi])
    if v_mc_hi - v_mc_lo < 0.01:
        _fail(
            failures, "kin_vel_mono: mace blunt expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_mc_hi - v_mc_lo]
        )
    for blade_spec: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_vel_ax"},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_vel_dg"},
    ]:
        var w_b: Weapon = HarnessFixtures.get_cached_weapon(str(blade_spec["def"]))
        if w_b == null:
            _fail(failures, "%s: missing %s" % [str(blade_spec["pfx"]), str(blade_spec["def"])])
            return
        var m_b: String = str(blade_spec["move"])
        var tag: String = str(blade_spec["pfx"])
        for inten_b in [0.22, 0.78]:
            var ai_b: AttackInstance = AttackInstance.new(m_b, inten_b)
            ai_b.archetype = arch_empty
            var vfi: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_empty, w_b, m_b)
            var vfe: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_b)
            if absf(vfe - vfi) > 0.001:
                _fail(
                    failures,
                    (
                        "%s: swing inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                        % [tag, inten_b, vfe, vfi]
                    )
                )
            var ai_bt: AttackInstance = AttackInstance.new(m_b, inten_b)
            ai_bt.archetype = arch_thrust
            var vti: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_thrust, w_b, m_b)
            var vte: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_bt)
            if absf(vte - vti) > 0.001:
                _fail(
                    failures,
                    (
                        "%s: thrust override inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                        % [tag, inten_b, vte, vti]
                    )
                )
            var ai_bm: AttackInstance = AttackInstance.new(m_b, inten_b)
            ai_bm.archetype = arch_mixed
            var vmi: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_mixed, w_b, m_b)
            var vme: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_bm)
            if absf(vme - vmi) > 0.001:
                _fail(
                    failures,
                    (
                        "%s: mixed inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                        % [tag, inten_b, vme, vmi]
                    )
                )
        var vb_sw_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, w_b, m_b)
        var vb_sw_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, w_b, m_b)
        if vb_sw_lo > vb_sw_hi + 0.0001:
            _fail(failures, "%s: swing inferred v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_sw_lo, vb_sw_hi])
        if vb_sw_hi - vb_sw_lo < 0.01:
            _fail(
                failures,
                "%s: swing inferred expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_sw_hi - vb_sw_lo]
            )
        var vb_th_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_thrust, w_b, m_b)
        var vb_th_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_thrust, w_b, m_b)
        if vb_th_lo > vb_th_hi + 0.0001:
            _fail(failures, "%s: thrust override v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_th_lo, vb_th_hi])
        if vb_th_hi - vb_th_lo < 0.01:
            _fail(
                failures,
                "%s: thrust override expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_th_hi - vb_th_lo]
            )
        var vb_mx_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_mixed, w_b, m_b)
        var vb_mx_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_mixed, w_b, m_b)
        if vb_mx_lo > vb_mx_hi + 0.0001:
            _fail(failures, "%s: mixed blend v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_mx_lo, vb_mx_hi])
        if vb_mx_hi - vb_mx_lo < 0.01:
            _fail(
                failures,
                "%s: mixed blend expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_mx_hi - vb_mx_lo]
            )


## Tier 5.1: **`compute_pre_armor_cut`** scales with **`sqrt(KE)`** at fixed strength/**`arm_mod`** when
## **`velocity_m_s`** pins tip speed (no clamp skew)  -  **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**,
## **DAGGER** **`quick_slash`** (swing). **`compute_pre_armor_blunt`** rises with pinned speed on **MACE**
## **`direct_blow`** (momentum path).
