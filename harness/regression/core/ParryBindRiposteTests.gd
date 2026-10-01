class_name ParryBindRiposteTests

extends CombatRegressionHarnessCore

## Parry bind + riposte: partial bind sets riposte flags when aligned, and skips the counterstrike window when
## the flag is off.


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
            var chain_until: float = float(p.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL, -1.0))
            var chain_tid: int = int(p.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID, -1))
            if chain_until <= 0.0 or chain_tid != e_id:
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: bind should grant counterstrike window "
                        + "got until=%f tid=%d" % [label, chain_until, chain_tid]
                    )
                )
        else:
            if p.has(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL):
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: no bind should not grant counterstrike window got %s"
                        % [label, str(p.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL))]
                    )
                )
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
    # modest-but-real bind; values below PARRY_BIND_CONTROL_THRESHOLD (0.48) must NOT bind.
    apply_partial_bind.call(0.0, 0.65, true, "aligned_low_control", false, false)
    apply_partial_bind.call(0.0, 0.45, false, "aligned_sub_threshold", false, false)
    apply_partial_bind.call(90.0, 0.9, false, "misaligned_high_control", false, true)
    apply_partial_bind.call(90.0, 0.9, false, "misaligned_clears_stale_bind", true, true)


## **`parry_partial`** bind still sets **`parry_was_bind`** when `FEATURE_PARRY_COUNTERSTRIKE_WINDOW` is disabled, but
## must NOT grant the riposte chain (counterstrike) window.


static func _run_parry_partial_bind_skips_counterstrike_window_when_flag_off(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_parry_counterstrike_window_enabled()
    CombatConstants.set_feature_parry_counterstrike_window_load(false)
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
    e.state = CombatConstants.STATE_WIND_UP
    e.pending_attack = {
        "target_id": p_id,
        "attack_type": "thrust",
        "effective_attack_line": "high",
        "attack_angle_deg": 0.0,
        "intensity": 0.5,
        "parry_remaining_ratio": 0.05,
    }
    var pclash: Dictionary = {"parry_control": 0.9, "archetype_id": "stab"}
    AttackResultApplier.apply_result(
        mgr, e_id, {"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
    )
    if not bool(p.get("parry_was_bind", false)):
        _fail(failures, "counterstrike_flag_off: expected bind established")
    if p.has(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL):
        _fail(
            failures,
            (
                "counterstrike_flag_off: riposte chain must NOT be granted when feature off got %s"
                % str(p.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL))
            )
        )
    CombatConstants.set_feature_parry_counterstrike_window_load(saved)
    _free_manager(mgr)
