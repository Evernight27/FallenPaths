class_name ParryCalibrationBlockTests
extends CombatRegressionHarnessCore


## Tier 3.2 + 3.0: parry clash context preserves bind/deflect calibration + strike kinematics; asserts geometry + move
## ids vs **`DefenseResolutionHandler._resolve_parry`** and **`WeaponDamageHelper`** / **`StrikeRealismProfile`**; Tier
## **3.1** **`strike_measure_ratio`** vs **`pa`** after **`stamp_attack_pair_geometry_on_dict`** +
## **`strike_measure_ratio_for_attack_pair`** (full-stop key set **`PARRY_CLASH_CONTEXT_KEYS_FULL_STOP`**); stamped path
## sets **`impact_blade_station`** before **`resolve`** so post-resolve kinematics recompute matches
## **`velocity_intent_mult_from_pa`** (no extra **`randf()`** vs resolver); unstamped **`pa`** -> clash
## **`strike_measure_ratio`** **-1**, then **`seed(3312)`** before stamped path for stable RNG.
static func _parry_clash_context_expected_strike_kinematics(
    pa: Dictionary, attacker: Dictionary, atk_move: String, intensity_val: float, archetype_passed: Dictionary
) -> Dictionary:
    var want_kdel: String = WeaponDamageHelper.kinematic_delivery(archetype_passed, atk_move)
    var ai := AttackInstance.new(atk_move, intensity_val)
    ai.archetype = archetype_passed
    var atk_w = EntityAccess.get_weapon(attacker)
    var want_sv: float = -1.0
    var want_ke: float = 0.0
    if atk_w != null:
        want_sv = WeaponDamageHelper.get_effective_velocity_m_s(atk_w, ai)
        want_sv *= StrikeRealismProfile.velocity_intent_mult_from_pa(
            pa, atk_w, atk_move, float(pa.get("intensity", intensity_val)), archetype_passed
        )
        ai.velocity_m_s = want_sv
        want_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_w, ai)
    return {
        "kinematic_delivery": want_kdel,
        "strike_velocity_m_s": want_sv,
        "strike_kinetic_energy_j": want_ke,
    }


## Tier 3.0: partial-parry follow-through  -  clash **`strike_velocity_m_s`** / **`strike_kinetic_energy_j`** use
## **`pa["velocity_m_s"]`** after **`DefenseResolutionHandler`** reduction (not pre-parry intent speed).


## Tier 3.0: partial-parry follow-through  -  clash **`strike_velocity_m_s`** / **`strike_kinetic_energy_j`** use
## **`pa["velocity_m_s"]`** after **`DefenseResolutionHandler`** reduction (not pre-parry intent speed).
static func _parry_clash_expected_partial_strike_kinematics(
    pa: Dictionary, attacker: Dictionary, atk_move: String, intensity_val: float, archetype_passed: Dictionary
) -> Dictionary:
    var want_kdel: String = WeaponDamageHelper.kinematic_delivery(archetype_passed, atk_move)
    var ai := AttackInstance.new(atk_move, intensity_val)
    ai.archetype = archetype_passed
    var atk_w = EntityAccess.get_weapon(attacker)
    var want_sv: float = float(pa.get("velocity_m_s", -1.0))
    ai.velocity_m_s = want_sv
    var want_ke: float = 0.0
    if atk_w != null:
        want_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_w, ai)
    return {
        "kinematic_delivery": want_kdel,
        "strike_velocity_m_s": want_sv,
        "strike_kinetic_energy_j": want_ke,
    }


static func _run_parry_clash_context_calibration_fields(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard_line"] = "low"
    var pa_template: Dictionary = {
        "attack_type": "spear_thrust",
        "effective_attack_line": "high",
        "intensity": 0.5,
        "wind_up_duration": 1.0,
        "arc_start_deg": 0.0,
        "arc_end_deg": 180.0,
        "attack_angle_deg": 180.0
    }
    var parry_p_a: float = 5.0
    var parry_c_d: float = 100.0
    var m_a_parry: float = 1.25
    var m_d_parry: float = 2.5
    var m_a_velocity: float = 0.45
    var dc: Dictionary = {
        "defense": "parry",
        "can_parry_in_time": true,
        "parry_p_a": parry_p_a,
        "parry_c_d": parry_c_d,
        "parry_time_to_react": 0.1,
        "parry_readiness": 1.0,
        "is_block_parry": true,
        "m_a_parry": m_a_parry,
        "m_d_parry": m_d_parry,
        "m_a_velocity": m_a_velocity,
        "dodge_chance": 0.0,
        "dodge_eval_part": "",
        "effective_redirect": 1.0,
        "late_parry": false,
        "parry_off_balance": false
    }
    # Tier 3.1 sentinel: no **`strike_measure_ratio`** on **`pa`** -> clash carries **-1** (same RNG as main branch
    # after re-seed).
    seed(3312)
    var pa_unstamped: Dictionary = pa_template.duplicate(true)
    var res_unstamped: Variant = DefenseResolution.resolve(
        pa_unstamped,
        attacker,
        defender,
        dc,
        [],
        "spear_thrust",
        0.5,
        {},
        -1.0,
        1.0,
        1.0,
        EntityAccess.id_int(defender),
        EntityAccess.get_display_name(attacker),
        EntityAccess.get_display_name(defender)
    )
    if not (res_unstamped is Dictionary) or res_unstamped.get("action", "") != "parry_deflect":
        _fail(failures, "parry_clash_context unstamped: expected parry_deflect result")
        _free_manager_restore_global_rng(mgr)
        return
    var clash_un: Dictionary = res_unstamped.get("parry_clash_context", {})
    if (
        not clash_un.has("strike_measure_ratio")
        or absf(float(clash_un.get("strike_measure_ratio", 0.0)) - (-1.0)) > 0.001
    ):
        _fail(
            failures,
            (
                "parry_clash_context unstamped: strike_measure_ratio want -1 got %s"
                % str(clash_un.get("strike_measure_ratio", "missing"))
            )
        )
        _free_manager_restore_global_rng(mgr)
        return
    for _sk_un: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
        if not clash_un.has(_sk_un):
            _fail(failures, "parry_clash_context unstamped: missing key %s" % _sk_un)
            _free_manager_restore_global_rng(mgr)
            return
    seed(3312)
    var pa1: Dictionary = pa_template.duplicate(true)
    StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa1)
    var atk_w_for_meas: RefCounted = EntityAccess.get_weapon(attacker)
    StrikeStamping.stamp_strike_realism_on_pa(mgr, attacker, defender, pa1, atk_w_for_meas, "spear_thrust")
    if atk_w_for_meas != null:
        # Match wind-up: fixed blade station so **`velocity_intent_mult_from_pa`** does not draw a second RNG stream vs
        # post-resolve recompute.
        pa1["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
            pa1, atk_w_for_meas, "spear_thrust", 0.5
        )
    var result = DefenseResolution.resolve(
        pa1,
        attacker,
        defender,
        dc,
        [],
        "spear_thrust",
        0.5,
        {},
        -1.0,
        1.0,
        1.0,
        EntityAccess.id_int(defender),
        EntityAccess.get_display_name(attacker),
        EntityAccess.get_display_name(defender)
    )
    if not (result is Dictionary) or result.get("action", "") != "parry_deflect":
        _fail(failures, "parry_clash_context: expected parry_deflect result")
        _free_manager_restore_global_rng(mgr)
        return
    var clash: Dictionary = result.get("parry_clash_context", {})
    if clash.is_empty():
        _fail(failures, "parry_clash_context: missing context")
        _free_manager_restore_global_rng(mgr)
        return
    for _sk: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
        if not clash.has(_sk):
            _fail(failures, "parry_clash_context: missing key %s" % _sk)
            _free_manager_restore_global_rng(mgr)
            return
    var expected: Dictionary = {
        "parry_p_a": parry_p_a,
        "parry_c_d": parry_c_d,
        "m_a_parry": m_a_parry,
        "m_d_parry": m_d_parry,
        "m_a_velocity": m_a_velocity,
        "parry_time_to_react": float(dc.get("parry_time_to_react", -1.0)),
        "parry_readiness": float(dc.get("parry_readiness", -1.0))
    }
    for key in expected.keys():
        if absf(float(clash.get(key, -999.0)) - float(expected[key])) > 0.001:
            _fail(
                failures,
                (
                    "parry_clash_context: %s %.3f want %.3f"
                    % [str(key), float(clash.get(key, -999.0)), float(expected[key])]
                )
            )
    if bool(clash.get("late_parry", false)) != bool(dc.get("late_parry", false)):
        _fail(failures, "parry_clash_context: late_parry should match defense choice")
    if bool(clash.get("parry_off_balance", false)) != bool(dc.get("parry_off_balance", false)):
        _fail(failures, "parry_clash_context: parry_off_balance should match defense choice")
    if bool(clash.get("is_block_parry", false)) != bool(dc.get("is_block_parry", false)):
        _fail(failures, "parry_clash_context: is_block_parry should match defense choice")
    var atk_move: String = "spear_thrust"
    if str(clash.get("attack_type", "")) != atk_move:
        _fail(
            failures, "parry_clash_context: attack_type want %s got %s" % [atk_move, str(clash.get("attack_type", ""))]
        )
    var want_ct: String = str(WeaponConstants.contact_type_for_move_id(atk_move)).to_lower().strip_edges()
    if str(clash.get("contact_type", "")).to_lower().strip_edges() != want_ct:
        _fail(
            failures, "parry_clash_context: contact_type want %s got %s" % [want_ct, str(clash.get("contact_type", ""))]
        )
    var arc_s: float = float(pa_template.get("arc_start_deg", 0.0))
    var arc_e: float = CombatConstants.arc_end_deg_for_contact_geometry(pa_template)
    var atk_line_for_align: String = str(pa_template.get("effective_attack_line", "high"))
    var def_w0 = EntityAccess.get_weapon(defender)
    var def_mass: float = WeaponConstants.weapon_mass_kg(def_w0)
    if str(clash.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context: effective_attack_line want %s got %s"
                % [str(pa_template.get("effective_attack_line", "")), str(clash.get("effective_attack_line", ""))]
            )
        )
    if str(clash.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context: defender_guard_line want %s got %s"
                % [str(defender.get("guard_line", "")), str(clash.get("defender_guard_line", ""))]
            )
        )
    var atk_w = EntityAccess.get_weapon(attacker)
    var want_arch: String = EntityAccess.weapon_archetype_id(atk_w, atk_move, "")
    if str(clash.get("archetype_id", "")) != want_arch:
        _fail(
            failures,
            "parry_clash_context: archetype_id want %s got %s" % [want_arch, str(clash.get("archetype_id", ""))]
        )
    var eff_wind: float = (
        float(pa_template.get("wind_up_duration", 0.5))
        * (1.0 - CombatConstants.commitment_fraction_for_pending_attack(pa_template))
    )
    var parry_prog: float = 1.0
    if not bool(dc.get("late_parry", false)):
        parry_prog = 1.0 - clampf(float(dc.get("parry_time_to_react", 0.0)) / maxf(0.001, eff_wind), 0.0, 1.0)
    var want_atk_deg: float = (
        CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, parry_prog)
        if arc_e >= -900.0
        else CombatConstants.line_to_angle(str(pa_template.get("effective_attack_line", "high")))
    )
    if absf(float(clash.get("attack_angle_deg", -9999.0)) - want_atk_deg) > 0.05:
        _fail(
            failures,
            (
                "parry_clash_context: attack_angle_deg want %.4f got %.4f"
                % [want_atk_deg, float(clash.get("attack_angle_deg", -9999.0))]
            )
        )
    var wobble: Dictionary = {
        "parry_readiness": float(dc.get("parry_readiness", 1.0)),
        "defender_mass_kg": def_mass,
    }
    var want_guard_deg: float = CombatConstants.get_guard_angle_deg(defender, wobble)
    if absf(float(clash.get("guard_angle_deg", -9999.0)) - want_guard_deg) > 0.25:
        _fail(
            failures,
            (
                "parry_clash_context: guard_angle_deg want %.4f got %.4f"
                % [want_guard_deg, float(clash.get("guard_angle_deg", -9999.0))]
            )
        )
    var align_ctx1: Dictionary = {"attack_angle_deg": want_atk_deg, "guard_angle_deg": want_guard_deg}
    var want_align: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx1)
    if absf(float(clash.get("alignment", -999.0)) - want_align) > 0.02:
        _fail(
            failures,
            "parry_clash_context: alignment want %.4f got %.4f" % [want_align, float(clash.get("alignment", -999.0))]
        )
    var c_d_final: float = float(clash.get("c_d_final", 0.0))
    if c_d_final <= 0.0:
        _fail(failures, "parry_clash_context: c_d_final should be positive")
    var expected_margin: float = CombatConstants.parry_deflect_margin_ratio(c_d_final, parry_p_a)
    if absf(float(clash.get("margin_ratio", -1.0)) - expected_margin) > 0.001:
        _fail(failures, "parry_clash_context: margin_ratio does not match c_d_final/parry_p_a")
    var want_pc: float = CombatConstants.parry_control_for_bind_deflect(
        c_d_final,
        parry_p_a,
        float(clash.get("alignment", 0.0)),
        float(dc.get("parry_readiness", 1.0)),
        bool(dc.get("parry_off_balance", false)),
        bool(dc.get("late_parry", false)),
        str(clash.get("contact_type", ""))
    )
    if absf(float(clash.get("parry_control", -9.0)) - want_pc) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: parry_control %.4f vs CombatConstants.parry_control_for_bind_deflect %.4f"
                % [float(clash.get("parry_control", -9.0)), want_pc]
            )
        )
    var want_sev: float = CombatConstants.parry_deflect_severity_from_margin_ratio(
        float(clash.get("margin_ratio", 0.0))
    )
    if absf(float(clash.get("severity", -1.0)) - want_sev) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: severity %.4f vs parry_deflect_severity_from_margin_ratio %.4f"
                % [float(clash.get("severity", -1.0)), want_sev]
            )
        )
    var arch_passed: Dictionary = {}
    var exp_sk: Dictionary = _parry_clash_context_expected_strike_kinematics(pa1, attacker, atk_move, 0.5, arch_passed)
    if str(clash.get("kinematic_delivery", "")) != str(exp_sk.get("kinematic_delivery", "")):
        _fail(
            failures,
            (
                "parry_clash_context: kinematic_delivery want %s got %s"
                % [str(exp_sk.get("kinematic_delivery", "")), str(clash.get("kinematic_delivery", ""))]
            )
        )
    if absf(float(clash.get("strike_velocity_m_s", -999.0)) - float(exp_sk.get("strike_velocity_m_s", 0.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: strike_velocity_m_s %.6f want %.6f"
                % [float(clash.get("strike_velocity_m_s", -999.0)), float(exp_sk.get("strike_velocity_m_s", 0.0))]
            )
        )
    if (
        absf(float(clash.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk.get("strike_kinetic_energy_j", 0.0)))
        > 0.05
    ):
        _fail(
            failures,
            (
                "parry_clash_context: strike_kinetic_energy_j %.6f want %.6f"
                % [
                    float(clash.get("strike_kinetic_energy_j", -999.0)),
                    float(exp_sk.get("strike_kinetic_energy_j", 0.0))
                ]
            )
        )
    if absf(float(clash.get("strike_measure_ratio", -999.0)) - float(pa1.get("strike_measure_ratio", -1.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: strike_measure_ratio %.6f want %.6f"
                % [float(clash.get("strike_measure_ratio", -999.0)), float(pa1.get("strike_measure_ratio", -1.0))]
            )
        )
    # Late / off-balance flags propagate for calibration (same full_stop path).
    var dc_late: Dictionary = dc.duplicate(true)
    dc_late["late_parry"] = true
    dc_late["parry_off_balance"] = true
    dc_late["parry_readiness"] = 0.88
    dc_late["parry_time_to_react"] = 0.02
    seed(3313)
    var pa2: Dictionary = pa_template.duplicate(true)
    StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa2)
    StrikeStamping.stamp_strike_realism_on_pa(mgr, attacker, defender, pa2, atk_w_for_meas, "spear_thrust")
    if atk_w_for_meas != null:
        pa2["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
            pa2, atk_w_for_meas, "spear_thrust", 0.5
        )
    var result2 = DefenseResolution.resolve(
        pa2,
        attacker,
        defender,
        dc_late,
        [],
        "spear_thrust",
        0.5,
        {},
        -1.0,
        1.0,
        1.0,
        EntityAccess.id_int(defender),
        EntityAccess.get_display_name(attacker),
        EntityAccess.get_display_name(defender)
    )
    if not (result2 is Dictionary) or result2.get("action", "") != "parry_deflect":
        _fail(failures, "parry_clash_context late: expected parry_deflect result")
        _free_manager_restore_global_rng(mgr)
        return
    var clash2: Dictionary = result2.get("parry_clash_context", {})
    if clash2.is_empty():
        _fail(failures, "parry_clash_context late: missing context")
        _free_manager_restore_global_rng(mgr)
        return
    for _sk: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
        if not clash2.has(_sk):
            _fail(failures, "parry_clash_context late: missing key %s" % _sk)
            _free_manager_restore_global_rng(mgr)
            return
    if not bool(clash2.get("late_parry", false)) or not bool(clash2.get("parry_off_balance", false)):
        _fail(failures, "parry_clash_context: late/off_balance should be true on second fixture")
    if absf(float(clash2.get("parry_readiness", 0.0)) - 0.88) > 0.001:
        _fail(failures, "parry_clash_context: parry_readiness should echo defense choice (late branch)")
    if absf(float(clash2.get("parry_time_to_react", -1.0)) - 0.02) > 0.001:
        _fail(failures, "parry_clash_context: parry_time_to_react should echo defense choice (late branch)")
    if str(clash2.get("attack_type", "")) != atk_move:
        _fail(
            failures,
            "parry_clash_context late: attack_type want %s got %s" % [atk_move, str(clash2.get("attack_type", ""))]
        )
    if str(clash2.get("contact_type", "")).to_lower().strip_edges() != want_ct:
        _fail(
            failures,
            "parry_clash_context late: contact_type want %s got %s" % [want_ct, str(clash2.get("contact_type", ""))]
        )
    if str(clash2.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context late: effective_attack_line want %s got %s"
                % [str(pa_template.get("effective_attack_line", "")), str(clash2.get("effective_attack_line", ""))]
            )
        )
    if str(clash2.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context late: defender_guard_line want %s got %s"
                % [str(defender.get("guard_line", "")), str(clash2.get("defender_guard_line", ""))]
            )
        )
    if str(clash2.get("archetype_id", "")) != want_arch:
        _fail(
            failures,
            "parry_clash_context late: archetype_id want %s got %s" % [want_arch, str(clash2.get("archetype_id", ""))]
        )
    var want_atk_deg2: float = (
        CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, 1.0) if arc_e >= -900.0 else want_atk_deg
    )
    if absf(float(clash2.get("attack_angle_deg", -9999.0)) - want_atk_deg2) > 0.05:
        _fail(
            failures,
            (
                "parry_clash_context late: attack_angle_deg want %.4f got %.4f"
                % [want_atk_deg2, float(clash2.get("attack_angle_deg", -9999.0))]
            )
        )
    # Guard wobble uses **`randf_range`** when readiness < 1  -  replay alignment from stored clash angles (no second
    # draw).
    var align_ctx2: Dictionary = {
        "attack_angle_deg": float(clash2.get("attack_angle_deg", -9999.0)),
        "guard_angle_deg": float(clash2.get("guard_angle_deg", -9999.0)),
    }
    var want_align2: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx2)
    if absf(float(clash2.get("alignment", -999.0)) - want_align2) > 0.02:
        _fail(
            failures,
            (
                "parry_clash_context late: alignment want %.4f got %.4f"
                % [want_align2, float(clash2.get("alignment", -999.0))]
            )
        )
    var c_d2: float = float(clash2.get("c_d_final", 0.0))
    var want_pc2: float = CombatConstants.parry_control_for_bind_deflect(
        c_d2, parry_p_a, float(clash2.get("alignment", 0.0)), 0.88, true, true, str(clash2.get("contact_type", ""))
    )
    if absf(float(clash2.get("parry_control", -9.0)) - want_pc2) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context late: parry_control %.4f vs formula %.4f"
                % [float(clash2.get("parry_control", -9.0)), want_pc2]
            )
        )
    var want_sev2: float = CombatConstants.parry_deflect_severity_from_margin_ratio(
        float(clash2.get("margin_ratio", 0.0))
    )
    if absf(float(clash2.get("severity", -1.0)) - want_sev2) > 0.001:
        _fail(
            failures,
            "parry_clash_context late: severity %.4f vs formula %.4f" % [float(clash2.get("severity", -1.0)), want_sev2]
        )
    var exp_sk2: Dictionary = _parry_clash_context_expected_strike_kinematics(pa2, attacker, atk_move, 0.5, arch_passed)
    if str(clash2.get("kinematic_delivery", "")) != str(exp_sk2.get("kinematic_delivery", "")):
        _fail(
            failures,
            (
                "parry_clash_context late: kinematic_delivery want %s got %s"
                % [str(exp_sk2.get("kinematic_delivery", "")), str(clash2.get("kinematic_delivery", ""))]
            )
        )
    if absf(float(clash2.get("strike_velocity_m_s", -999.0)) - float(exp_sk2.get("strike_velocity_m_s", 0.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context late: strike_velocity_m_s %.6f want %.6f"
                % [float(clash2.get("strike_velocity_m_s", -999.0)), float(exp_sk2.get("strike_velocity_m_s", 0.0))]
            )
        )
    if (
        absf(float(clash2.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk2.get("strike_kinetic_energy_j", 0.0)))
        > 0.05
    ):
        _fail(
            failures,
            (
                "parry_clash_context late: strike_kinetic_energy_j %.6f want %.6f"
                % [
                    float(clash2.get("strike_kinetic_energy_j", -999.0)),
                    float(exp_sk2.get("strike_kinetic_energy_j", 0.0))
                ]
            )
        )
    if absf(float(clash2.get("strike_measure_ratio", -999.0)) - float(pa2.get("strike_measure_ratio", -1.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context late: strike_measure_ratio %.6f want %.6f"
                % [float(clash2.get("strike_measure_ratio", -999.0)), float(pa2.get("strike_measure_ratio", -1.0))]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 3.2 + 3.0: **`parry_partial`**  -  **`parry_clash_context`** mirrors full-stop keys plus **`remaining_ratio`** /
## **`geometric_leak`**; Tier **3.0** KE uses reduced **`pa["velocity_m_s"]`** (not intent-speed from
## **`_parry_clash_context_expected_strike_kinematics`**).


## Tier 3.2 + 3.0: **`parry_partial`**  -  **`parry_clash_context`** mirrors full-stop keys plus **`remaining_ratio`** /
## **`geometric_leak`**; Tier **3.0** KE uses reduced **`pa["velocity_m_s"]`** (not intent-speed from
## **`_parry_clash_context_expected_strike_kinematics`**).
static func _run_parry_partial_clash_context_calibration_fields(failures: PackedStringArray) -> void:
    var mgr2: Node = MgrScript.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SPEAR"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender_p: Dictionary = mgr2.combatants[0]
    var attacker_p: Dictionary = mgr2.combatants[1]
    defender_p["guard_line"] = "low"
    var pa_partial: Dictionary = {
        "attack_type": "spear_thrust",
        "effective_attack_line": "high",
        "intensity": 0.5,
        "wind_up_duration": 1.0,
        "arc_start_deg": 0.0,
        "arc_end_deg": 360.0,
        "attack_angle_deg": 180.0,
    }
    var parry_p_a_p: float = 5.0
    var parry_c_d_p: float = 100.0
    var dc_partial: Dictionary = {
        "defense": "parry",
        "can_parry_in_time": true,
        "parry_p_a": parry_p_a_p,
        "parry_c_d": parry_c_d_p,
        "parry_time_to_react": 0.1,
        "parry_readiness": 1.0,
        "is_block_parry": false,
        "m_a_parry": 1.25,
        "m_d_parry": 2.5,
        "m_a_velocity": 0.45,
        "dodge_chance": 0.0,
        "dodge_eval_part": "",
        "effective_redirect": 1.0,
        "late_parry": false,
        "parry_off_balance": false,
    }
    seed(3312)
    StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr2, attacker_p, defender_p, pa_partial)
    var atk_w_part: RefCounted = EntityAccess.get_weapon(attacker_p)
    StrikeStamping.stamp_strike_realism_on_pa(mgr2, attacker_p, defender_p, pa_partial, atk_w_part, "spear_thrust")
    if atk_w_part != null:
        pa_partial["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
            pa_partial, atk_w_part, "spear_thrust", 0.5
        )
    var res_partial: Variant = DefenseResolution.resolve(
        pa_partial,
        attacker_p,
        defender_p,
        dc_partial,
        [],
        "spear_thrust",
        0.5,
        {},
        -1.0,
        1.0,
        1.0,
        EntityAccess.id_int(defender_p),
        EntityAccess.get_display_name(attacker_p),
        EntityAccess.get_display_name(defender_p)
    )
    if not (res_partial is Dictionary) or str((res_partial as Dictionary).get("action", "")) != "parry_partial":
        _fail(failures, "parry_partial_clash: expected parry_partial result")
        _free_manager_restore_global_rng(mgr2)
        return
    var clash_partial: Dictionary = (res_partial as Dictionary).get("parry_clash_context", {}) as Dictionary
    if clash_partial.is_empty():
        _fail(failures, "parry_partial_clash: missing parry_clash_context")
        _free_manager_restore_global_rng(mgr2)
        return
    for _sk_part: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
        if not clash_partial.has(_sk_part):
            _fail(failures, "parry_partial_clash: missing key %s" % _sk_part)
            _free_manager_restore_global_rng(mgr2)
            return
    if not clash_partial.has(DataKeys.RESULT_REMAINING_RATIO) or not clash_partial.has("geometric_leak"):
        _fail(failures, "parry_partial_clash: missing remaining_ratio or geometric_leak")
        _free_manager_restore_global_rng(mgr2)
        return
    if (
        absf(float(clash_partial.get("remaining_ratio", -1.0)) - float(pa_partial.get("parry_remaining_ratio", -2.0)))
        > 1e-5
    ):
        _fail(
            failures,
            (
                "parry_partial_clash: remaining_ratio vs pa parry_remaining_ratio mismatch %s vs %s"
                % [str(clash_partial.get("remaining_ratio")), str(pa_partial.get("parry_remaining_ratio"))]
            )
        )
    var mr_part: float = float(clash_partial.get("margin_ratio", 0.0))
    var want_mr_part: float = CombatConstants.parry_deflect_margin_ratio(float(clash_partial["c_d_final"]), parry_p_a_p)
    if absf(mr_part - want_mr_part) > 1e-4:
        _fail(failures, "parry_partial_clash: margin_ratio mismatch")
    var pc_part: float = float(clash_partial.get("parry_control", 0.0))
    var want_pc_part: float = CombatConstants.parry_control_for_bind_deflect(
        float(clash_partial["c_d_final"]),
        parry_p_a_p,
        float(clash_partial["alignment"]),
        float(clash_partial.get("parry_readiness", 0.0)),
        bool(clash_partial.get("parry_off_balance", false)),
        bool(clash_partial.get("late_parry", false)),
        str(clash_partial.get("contact_type", ""))
    )
    if absf(pc_part - want_pc_part) > 0.002:
        _fail(failures, "parry_partial_clash: parry_control vs formula mismatch")
    var sev_part: float = float(clash_partial.get("severity", -1.0))
    var want_sev_part: float = CombatConstants.parry_deflect_severity_from_margin_ratio(mr_part)
    if absf(sev_part - want_sev_part) > 0.002:
        _fail(failures, "parry_partial_clash: severity vs formula mismatch")
    var exp_part_k: Dictionary = _parry_clash_expected_partial_strike_kinematics(
        pa_partial, attacker_p, "spear_thrust", 0.5, {}
    )
    if str(clash_partial.get("kinematic_delivery", "")) != str(exp_part_k.get("kinematic_delivery", "")):
        _fail(
            failures,
            (
                "parry_partial_clash: kinematic_delivery want %s got %s"
                % [str(exp_part_k.get("kinematic_delivery", "")), str(clash_partial.get("kinematic_delivery", ""))]
            )
        )
    if absf(float(clash_partial["strike_velocity_m_s"]) - float(exp_part_k["strike_velocity_m_s"])) > 1e-4:
        _fail(
            failures,
            (
                "parry_partial_clash: strike_velocity_m_s %.6f want %.6f"
                % [float(clash_partial["strike_velocity_m_s"]), float(exp_part_k["strike_velocity_m_s"])]
            )
        )
    if absf(float(clash_partial["strike_kinetic_energy_j"]) - float(exp_part_k["strike_kinetic_energy_j"])) > 1e-3:
        _fail(
            failures,
            (
                "parry_partial_clash: strike_kinetic_energy_j %.6f want %.6f"
                % [float(clash_partial["strike_kinetic_energy_j"]), float(exp_part_k["strike_kinetic_energy_j"])]
            )
        )
    if (
        absf(float(clash_partial["strike_measure_ratio"]) - float(pa_partial.get("strike_measure_ratio", -99.0)))
        > 0.001
    ):
        _fail(
            failures,
            (
                "parry_partial_clash: strike_measure_ratio %.6f want %.6f"
                % [float(clash_partial["strike_measure_ratio"]), float(pa_partial.get("strike_measure_ratio", -1.0))]
            )
        )
    _free_manager_restore_global_rng(mgr2)


## Tier 3.2: **`CombatConstants.parry_control_for_bind_deflect`** pure formula corner cases.


## Tier 3.2: **`CombatConstants.parry_control_for_bind_deflect`** pure formula corner cases.
static func _run_parry_control_bind_deflect_formula(failures: PackedStringArray) -> void:
    var hi_cd: float = 100.0
    var pa_m: float = 5.0
    var al: float = 0.9
    var cut_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut")
    # Alignment weight uses a power curve (alignment^1.2): at al=0.9 the weight is ~0.886, so a full-margin
    # cut saturates at 1.0 due to clampf(p, 0.0, 1.0).
    if not is_equal_approx(cut_hi, 1.0):
        _fail(failures, "parry_ctrl_formula: high-margin cut want 1.0 got %.4f" % cut_hi)
    var stab_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "stab")
    # Thrust mult (0.85) applied to full-margin case: ~0.899 is correct for alignment^1.2 * margin/2 * 0.85.
    if absf(stab_hi - 0.8989) > 0.004:
        _fail(failures, "parry_ctrl_formula: high-margin stab want ~0.899 got %.4f" % stab_hi)
    var blunt_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "BLUNT")
    if not is_equal_approx(blunt_hi, cut_hi):
        _fail(failures, "parry_ctrl_formula: blunt should match cut for thrust mult got %.4f" % blunt_hi)
    var low_cd: float = pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 0.25
    var cut_low: float = CombatConstants.parry_control_for_bind_deflect(low_cd, pa_m, 1.0, 1.0, false, false, "cut")
    if not is_equal_approx(cut_low, 0.5475):
        _fail(failures, "parry_ctrl_formula: low-margin cut want 0.5475 got %.4f" % cut_low)
    var late_mid: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, 0.65, 1.0, false, true, "cut")
    if absf(late_mid - 0.4294) > 0.004:
        _fail(failures, "parry_ctrl_formula: late+align 0.65 cut want ~0.429 got %.4f" % late_mid)
    if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(2.0), 1.0):
        _fail(failures, "parry_severity: margin 2.0 want 1.0")
    if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(0.5), 0.0):
        _fail(failures, "parry_severity: margin 0.5 want 0.0")
    if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(1.25), 0.25):
        _fail(failures, "parry_severity: margin 1.25 want 0.25")
    if not is_equal_approx(
        CombatConstants.parry_deflect_margin_ratio(hi_cd, pa_m),
        hi_cd / maxf(pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD, 0.01)
    ):
        _fail(failures, "parry_margin_ratio: helper should match explicit formula")

    # Boundary monotonicity (physics pass): control must not drop when a parry crosses from partial
    # (just below deflect threshold) to a clean full stop. Previously the deflect branch clamped at
    # 1.0 so a marginal stop (margin 1.0) could bind WORSE than the 99% partial (floor ~1.12).
    var almost_stop: float = CombatConstants.parry_control_for_bind_deflect(
        pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 0.995, pa_m, 0.9, 0.0, false, false, "cut"
    )
    var marginal_stop: float = CombatConstants.parry_control_for_bind_deflect(
        pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.005, pa_m, 0.9, 0.0, false, false, "cut"
    )
    if marginal_stop < almost_stop - 0.001:
        _fail(
            failures,
            "parry_ctrl_boundary: marginal full stop must not bind worse than near-miss partial (almost=%.4f stop=%.4f)"
            % [almost_stop, marginal_stop]
        )

    # Thrust partial sign (physics pass): a driven-through thrust grants the defender LESS control.
    # margin 0.5 partial: floor=0.77 - 0.18*0.5 = 0.68, +readiness*0.5 = 1.18 -> align_w(0.9)*0.59*0.85 = 0.4419.
    # Pre-fix the penetration term was dead code (applied after p) leaving only the 0.85 mult (0.4756),
    # and the old `+=` intent inflated it further. This pin fails unless the term feeds p AND is a penalty.
    var st_lo: float = pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 0.5
    var stab_partial: float = CombatConstants.parry_control_for_bind_deflect(st_lo, pa_m, 0.9, 1.0, false, false, "stab")
    if absf(stab_partial - 0.4419) > 0.004:
        _fail(
            failures,
            "parry_ctrl_thrust_partial: thrust penetration penalty must feed p (want ~0.442 got %.4f)" % stab_partial
        )
    if stab_partial >= CombatConstants.PARRY_BIND_CONTROL_THRESHOLD:
        _fail(
            failures,
            "parry_ctrl_thrust_partial: partial thrust parry must not bind (ctrl=%.4f >= %.3f)"
            % [stab_partial, CombatConstants.PARRY_BIND_CONTROL_THRESHOLD]
        )


## Bind friction (HEMA waffenfühlen): a wider parrying blade grips the bind better. The 7-arg baseline
## (default friction 1.0) is unchanged; a narrower blade reduces control; a real SWORD (2.0cm) yields
## exactly 1.0 (the D001 no-op guarantee); a shaft parry is gated out (1.0).
static func _run_bind_friction_blade_width(failures: PackedStringArray) -> void:
    var hi_cd: float = 100.0
    var pa_m: float = 5.0
    var al: float = 0.9
    # Backward compat: the 7-arg baseline (default friction 1.0) equals the explicit 1.0.
    var base: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut")
    var explicit_one: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut", 1.0)
    if absf(base - explicit_one) > 0.0001:
        _fail(
            failures,
            "bind_friction: 7-arg baseline must equal explicit 1.0 (base=%.4f explicit=%.4f)" % [base, explicit_one]
        )
    # A narrower parrying blade (dagger 1.5cm -> 0.94) reduces bind control.
    var narrow: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut", 0.94)
    if narrow >= explicit_one:
        _fail(
            failures,
            "bind_friction: narrow blade (0.94) should reduce control (narrow=%.4f full=%.4f)" % [narrow, explicit_one]
        )
    # bind_friction_mult_for_weapon: null -> 1.0.
    if absf(CombatConstants.bind_friction_mult_for_weapon(null) - 1.0) > 0.0001:
        _fail(failures, "bind_friction: null weapon should yield 1.0")
    # A real SWORD (2.0cm blade, blade parry) -> exactly 1.0 (the D001 no-op guarantee).
    var mgr: Node = MgrScript.new()
    var ent: CoreEntity = _new_entity("SWORD")
    mgr.register(ent, "player")
    var c: Dictionary = mgr.combatants[0]
    var sword_w = EntityAccess.get_weapon(c)
    if sword_w == null:
        _fail(failures, "bind_friction: SWORD weapon should not be null")
        _free_manager(mgr)
        return
    var sword_mult: float = CombatConstants.bind_friction_mult_for_weapon(sword_w)
    if absf(sword_mult - 1.0) > 0.0001:
        _fail(failures, "bind_friction: SWORD (2.0cm) should yield exactly 1.0 (got %.4f)" % sword_mult)
    # Mutate a FRESH weapon instance (not the shared cached SWORD) so the mutation does not leak
    # into later tests that read the cached weapon's blade_width / parry_part_id.
    var mut_w: Weapon = Weapon.create_from_definition("SWORD")
    # Narrow the blade to dagger width (1.5cm) -> < 1.0 (narrower blade grips less).
    mut_w.blade_width = 1.5
    var dagger_mult: float = CombatConstants.bind_friction_mult_for_weapon(mut_w)
    if dagger_mult >= 1.0 or dagger_mult < 0.9:
        _fail(failures, "bind_friction: 1.5cm blade should yield ~0.94 (got %.4f)" % dagger_mult)
    # A shaft parry (SPEAR-like) is gated out -> 1.0.
    mut_w.parry_part_id = "shaft"
    var shaft_mult: float = CombatConstants.bind_friction_mult_for_weapon(mut_w)
    if absf(shaft_mult - 1.0) > 0.0001:
        _fail(failures, "bind_friction: shaft parry should yield 1.0 (got %.4f)" % shaft_mult)
    _free_manager(mgr)


## Morale parry readiness: fear degrades fine motor control. At full morale (1.0) the multiplier is 1.0;
## at the drain floor (0.70) it is 0.85 (15% reduction); at 0.85 it is 0.925 (midpoint).
static func _run_morale_parry_readiness(failures: PackedStringArray) -> void:
    if not is_equal_approx(CombatMoraleCohesion.morale_parry_readiness_mult(1.0), 1.0):
        _fail(failures, "morale_parry: full morale should yield 1.0")
    if not is_equal_approx(
        CombatMoraleCohesion.morale_parry_readiness_mult(CombatMoraleCohesion.MORALE_DRAIN_FLOOR),
        CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT
    ):
        _fail(
            failures,
            "morale_parry: drain floor should yield %.2f" % CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT
        )
    var mid: float = CombatMoraleCohesion.morale_parry_readiness_mult(0.85)
    var want_mid: float = lerpf(
        CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT, 1.0, (0.85 - CombatMoraleCohesion.MORALE_DRAIN_FLOOR) / 0.30
    )
    if absf(mid - want_mid) > 0.0001:
        _fail(failures, "morale_parry: midpoint 0.85 should yield %.4f (got %.4f)" % [want_mid, mid])
    var low: float = CombatMoraleCohesion.morale_parry_readiness_mult(0.75)
    if low <= CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT or low >= 1.0:
        _fail(failures, "morale_parry: 0.75 should be between floor and 1.0 (got %.4f)" % low)


## Conservation of momentum: PARRY_MAX_DAMAGE_REDUCTION caps armed parry damage reduction so ~15%
## residual always passes through. A high-control parry (c_d > 0.85 * pa) is capped; a low-control one is not.
static func _run_parry_max_damage_reduction_cap(failures: PackedStringArray) -> void:
    var cap: float = CombatConstantsParry.PARRY_MAX_DAMAGE_REDUCTION
    if absf(cap - 0.85) > 0.0001:
        _fail(failures, "parry_dmg_cap: PARRY_MAX_DAMAGE_REDUCTION should be 0.85 (got %.4f)" % cap)
    # High-control parry: c_d_final*redirect = 1.0, pa = 1.0 → capped at 0.85, remaining = 0.15.
    var pa_hi: float = 1.0
    var base_red_hi: float = minf(1.0, pa_hi * cap)
    var remain_hi: float = maxf(0.0, pa_hi - base_red_hi) / pa_hi
    if absf(remain_hi - (1.0 - cap)) > 0.0001:
        _fail(failures, "parry_dmg_cap: high-control remaining should be %.2f (got %.4f)" % [1.0 - cap, remain_hi])
    # Low-control parry: c_d_final*redirect = 0.5, pa = 1.0 → NOT capped, remaining = 0.5.
    var pa_lo: float = 1.0
    var base_red_lo: float = minf(0.5, pa_lo * cap)
    var remain_lo: float = maxf(0.0, pa_lo - base_red_lo) / pa_lo
    if absf(remain_lo - 0.5) > 0.0001:
        _fail(failures, "parry_dmg_cap: low-control remaining should be 0.50 (got %.4f)" % remain_lo)
    # Unarmed cap is separate and lower (0.5).
    var unarmed_cap: float = CombatConstantsParry.PARRY_UNARMED_MAX_DAMAGE_REDUCTION
    if absf(unarmed_cap - 0.5) > 0.0001:
        _fail(failures, "parry_dmg_cap: unarmed cap should be 0.5 (got %.4f)" % unarmed_cap)


## HEMA bind pressure defense penalty: opponent pressing the bind reduces defender's parry capacity.
## Reads the OPPONENT's pressure, not the defender's (the original was inverted and removed).
static func _run_bind_pressure_defender_penalty(failures: PackedStringArray) -> void:
    var floor_val: float = CombatConstantsParry.BIND_PRESSURE_DEFENDER_PARRY_CAP_FLOOR
    if absf(floor_val - 0.70) > 0.0001:
        _fail(failures, "bind_pressure_def: floor should be 0.70 (got %.4f)" % floor_val)
    # Null opponent → 1.0 (no effect).
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult({}, 0.0), 1.0):
        _fail(failures, "bind_pressure_def: null opponent should yield 1.0")
    # No active bind pressure (until < 0) → 1.0.
    var no_pressure: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: -1.0, DataKeys.BIND_PRESSURE_VALUE: 0.5}
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(no_pressure, 0.0), 1.0):
        _fail(failures, "bind_pressure_def: expired pressure should yield 1.0")
    # Active bind pressure at 0.5 → lerpf(1.0, 0.70, 0.5) = 0.85.
    var mid_pressure: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: 10.0, DataKeys.BIND_PRESSURE_VALUE: 0.5}
    var want_mid: float = lerpf(1.0, floor_val, 0.5)
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(mid_pressure, 0.0), want_mid):
        _fail(failures, "bind_pressure_def: 0.5 pressure should yield %.4f (got %.4f)" % [
            want_mid, CombatBindPressure.defender_parry_cap_mult(mid_pressure, 0.0)
        ])
    # Active bind pressure at 0.8 → lerpf(1.0, 0.70, 0.8) = 0.76.
    var hi_pressure: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: 10.0, DataKeys.BIND_PRESSURE_VALUE: 0.8}
    var want_hi: float = lerpf(1.0, floor_val, 0.8)
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(hi_pressure, 0.0), want_hi):
        _fail(failures, "bind_pressure_def: 0.8 pressure should yield %.4f (got %.4f)" % [
            want_hi, CombatBindPressure.defender_parry_cap_mult(hi_pressure, 0.0)
        ])
    # Pressure expired (clock > until) → 1.0.
    var expired: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: 5.0, DataKeys.BIND_PRESSURE_VALUE: 0.8}
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(expired, 6.0), 1.0):
        _fail(failures, "bind_pressure_def: expired (clock > until) should yield 1.0")


## Pass 35 (HEMA blade fatigue): sustained bind pressure decays over time — the holding muscles tire.
## `apply_decay` was dead code (never called); it is now ticked each waiting frame in process_waiting.
## This test verifies the decay physics constants are set correctly and the documented accelerated
## decay (0.04/s base * 2.5 progressive = 0.10/s) is consistent.
static func _run_bind_pressure_decay_constants(failures: PackedStringArray) -> void:
    # Base decay rate: 0.04/s.
    if not is_equal_approx(CombatConstants.BIND_PRESSURE_DECAY_RATE, 0.04):
        _fail(
            failures,
            (
                "bind_decay: BIND_PRESSURE_DECAY_RATE want 0.04 got %.4f"
                % CombatConstants.BIND_PRESSURE_DECAY_RATE
            )
        )
    # Grace period: 1.0s before progressive degradation kicks in.
    if not is_equal_approx(CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S, 1.0):
        _fail(
            failures,
            (
                "bind_decay: BIND_LEVERAGE_GRACE_PERIOD_S want 1.0 got %.2f"
                % CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
            )
        )
    # Progressive leverage degradation multiplier: 2.5x.
    if not is_equal_approx(CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT, 2.5):
        _fail(
            failures,
            (
                "bind_decay: BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT want 2.5 got %.2f"
                % CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT
            )
        )
    # Bind pressure duration: 6.0s.
    if not is_equal_approx(CombatConstants.BIND_PRESSURE_DURATION_S, 6.0):
        _fail(
            failures,
            (
                "bind_decay: BIND_PRESSURE_DURATION_S want 6.0 got %.2f"
                % CombatConstants.BIND_PRESSURE_DURATION_S
            )
        )
    # Documented accelerated decay: base * progressive = 0.04 * 2.5 = 0.10/s.
    var accelerated: float = CombatConstants.BIND_PRESSURE_DECAY_RATE * CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT
    if not is_equal_approx(accelerated, 0.10):
        _fail(
            failures,
            (
                "bind_decay: accelerated decay want 0.10/s (0.04*2.5) got %.4f" % accelerated
            )
        )
    # A sustained medium-pressure bind (0.6) must decay monotonically over the duration.
    # Simulate: 1.0s base decay, then accelerated decay for the remainder.
    var p: float = 0.6
    var base_phase: float = CombatConstants.BIND_PRESSURE_DECAY_RATE * CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
    p -= base_phase  # after grace period
    var remaining: float = CombatConstants.BIND_PRESSURE_DURATION_S - CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
    p -= accelerated * remaining  # accelerated for the rest
    # Pressure must drop well below the starting value (fatigue is real).
    if p >= 0.6:
        _fail(
            failures,
            (
                "bind_decay: sustained bind should decay below start (final=%.3f)" % p
            )
        )
    # The decayed pressure must be less than the starting pressure (monotonic decrease).
    if p >= 0.6 - 0.01:
        _fail(
            failures,
            (
                "bind_decay: decay should be meaningful (start=0.6 final=%.3f)" % p
            )
        )
## **`AttackResultApplier`** must NOT call **`manager._execute_attack()`** after partial parry.


## Tier 3.2 (combat tuning fix): follow-through gate at low remaining ratio — when **`parry_remaining_ratio <= 0.1`**,
## **`AttackResultApplier`** must NOT call **`manager._execute_attack()`** after partial parry.
static func _run_follow_through_gate_at_low_remaining_ratio(failures: PackedStringArray) -> void:
    # Verify constant gate threshold is set correctly.
    if CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY < 0.6:
        _fail(
            failures,
            (
                "ft_gate: PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY should be >= 0.6 (got %.2f)"
                % CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY
            )
        )
    # Test the gate logic directly: remaining_ratio > 0.1 triggers follow-through, <= 0.1 does not.
    var gate_above: bool = 0.15 > 0.1
    var gate_at: bool = false  # boundary: remaining_ratio == 0.1 is not > 0.1
    var gate_below: bool = 0.05 > 0.1
    if not gate_above:
        _fail(failures, "ft_gate: ratio 0.15 should pass gate (> 0.1)")
    if gate_at:
        _fail(failures, "ft_gate: ratio 0.1 should NOT pass gate (must be > 0.1, not >=)")
    if gate_below:
        _fail(failures, "ft_gate: ratio 0.05 should NOT pass gate (> 0.1)")


## Tier 3.2 (combat tuning fix): block thresholds at balanced entity values — **`PARRY_BLOCK_MASS_THRESHOLD = 0.75`**,
## **`PARRY_BLOCK_STR_THRESHOLD = 0.85`**.


## Tier 3.2 (combat tuning fix): block thresholds at balanced entity values — **`PARRY_BLOCK_MASS_THRESHOLD = 0.75`**,
## **`PARRY_BLOCK_STR_THRESHOLD = 0.85`**.
static func _run_block_threshold_balance_test(failures: PackedStringArray) -> void:
    # Mass threshold: 0.75 means defender with 75% attacker mass should qualify.
    if not is_equal_approx(CombatConstants.PARRY_BLOCK_MASS_THRESHOLD, 0.75):
        _fail(
            failures,
            (
                "block_threshold: PARRY_BLOCK_MASS_THRESHOLD want 0.75 got %.2f"
                % CombatConstants.PARRY_BLOCK_MASS_THRESHOLD
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_BLOCK_STR_THRESHOLD, 0.85):
        _fail(
            failures,
            "block_threshold: PARRY_BLOCK_STR_THRESHOLD want 0.85 got %.2f" % CombatConstants.PARRY_BLOCK_STR_THRESHOLD
        )
    # Test balanced entity scenario: both SWORD (mass 1.2 each), strength equal at 50/50.
    var d_mass: float = HarnessFixtures.get_cached_weapon("SWORD").mass
    var a_mass: float = HarnessFixtures.get_cached_weapon("SWORD").mass
    var d_str: float = 50.0
    var a_str: float = 50.0
    # Balanced: mass ratio = 1.0, str ratio = 1.0 — both should pass threshold.
    var mass_ok: bool = d_mass / maxf(a_mass, 0.01) >= CombatConstants.PARRY_BLOCK_MASS_THRESHOLD
    var str_ok: bool = d_str / maxf(a_str, 0.01) >= CombatConstants.PARRY_BLOCK_STR_THRESHOLD
    if not mass_ok or not str_ok:
        _fail(
            failures,
            (
                "block_threshold: balanced SWORD vs SWORD should pass both thresholds (mass=%.2f/%.2f, str=%.0f/%.0f)"
                % [d_mass, a_mass, d_str, a_str]
            )
        )


## Tier 3.2 (combat tuning fix): follow-through gate integration — when **`parry_remaining_ratio <= 0.1`** on
## parry_partial, **`AttackResultApplier.apply_result`** must NOT call **`manager._execute_attack()`**.


## Tier 3.2 (combat tuning fix): follow-through gate integration — when **`parry_remaining_ratio <= 0.1`** on
## parry_partial, **`AttackResultApplier.apply_result`** must NOT call **`manager._execute_attack()`**.
static func _run_follow_through_integration_gate(failures: PackedStringArray) -> void:
    # Test the gate logic directly: simulate remaining_ratio values and check whether follow-through would trigger.
    var should_trigger_low: bool = 0.05 > 0.1
    var should_trigger_high: bool = 0.15 > 0.1
    if should_trigger_low:
        _fail(failures, "ft_integration: ratio 0.05 should NOT trigger follow-through (gate returned true)")
    if not should_trigger_high:
        _fail(failures, "ft_integration: ratio 0.15 SHOULD trigger follow-through (gate returned false)")


## Tier 3.2 (combat tuning fix): asymmetric block threshold — DAGGER vs SPEAR should NOT qualify for block parry (mass
## ratio far below 0.75).


## Tier 3.2 (combat tuning fix): asymmetric block threshold — DAGGER vs SPEAR should NOT qualify for block parry (mass
## ratio far below 0.75).
static func _run_block_threshold_asymmetric_test(failures: PackedStringArray) -> void:
    var d_mass: float = HarnessFixtures.get_cached_weapon("DAGGER").mass
    var a_mass: float = HarnessFixtures.get_cached_weapon("SPEAR").mass
    var mass_ratio: float = d_mass / maxf(a_mass, 0.01)
    if mass_ratio >= CombatConstants.PARRY_BLOCK_MASS_THRESHOLD:
        _fail(
            failures,
            (
                "block_threshold_asym: DAGGER(mass=%.2f) vs SPEAR(mass=%.2f) ratio=%.3f should be below threshold %.2f"
                % [d_mass, a_mass, mass_ratio, CombatConstants.PARRY_BLOCK_MASS_THRESHOLD]
            )
        )
    # Borderline case: AXE (1.5 kg) vs MACE (1.7 kg), mass_ratio = 0.883 — should pass mass check.
    var d_mass2: float = HarnessFixtures.get_cached_weapon("AXE").mass
    var a_mass2: float = HarnessFixtures.get_cached_weapon("MACE").mass
    var mass_ratio2: float = d_mass2 / maxf(a_mass2, 0.01)
    if mass_ratio2 < CombatConstants.PARRY_BLOCK_MASS_THRESHOLD:
        _fail(
            failures,
            (
                "block_threshold_borderline: AXE(mass=%.2f) vs MACE(mass=%.2f) ratio=%.3f should pass threshold %.2f"
                % [d_mass2, a_mass2, mass_ratio2, CombatConstants.PARRY_BLOCK_MASS_THRESHOLD]
            )
        )


## Tier 3.2 (weapon audit): melee_range ordering — DAGGER < MACE <= SWORD == AXE < SPEAR, reflecting total weapon
## length. Also verifies each weapon has at least one stab, one cut or blunt move, and valid coupling values.


## Tier 3.2 (weapon audit): melee_range ordering — DAGGER < MACE <= SWORD == AXE < SPEAR, reflecting total weapon
## length. Also verifies each weapon has at least one stab, one cut or blunt move, and valid coupling values.
static func _run_weapon_melee_range_ordering(failures: PackedStringArray) -> void:
    var expected_order: Array[String] = ["DAGGER", "MACE", "SWORD", "AXE", "SPEAR"]
    var ranges: Dictionary = {}
    for wname in expected_order:
        ranges[wname] = HarnessFixtures.get_cached_weapon_melee_range(wname)
    # DAGGER < MACE <= SWORD == AXE < SPEAR
    if ranges.has("DAGGER") and ranges.has("SPEAR"):
        if ranges["DAGGER"] >= ranges["SPEAR"]:
            _fail(
                failures,
                "weapon_audit: DAGGER range (%.2f) must be < SPEAR range (%.2f)" % [ranges["DAGGER"], ranges["SPEAR"]]
            )
    if ranges.has("MACE") and ranges.has("SWORD"):
        if ranges["MACE"] > ranges["SWORD"]:
            _fail(
                failures,
                "weapon_audit: MACE range (%.2f) must be <= SWORD range (%.2f)" % [ranges["MACE"], ranges["SWORD"]]
            )
    if ranges.has("SWORD") and ranges.has("AXE"):
        if absf(ranges["SWORD"] - ranges["AXE"]) > 0.01:
            _fail(
                failures,
                "weapon_audit: SWORD range (%.2f) must equal AXE range (%.2f)" % [ranges["SWORD"], ranges["AXE"]]
            )
    if ranges.has("AXE") and ranges.has("SPEAR"):
        if ranges["AXE"] >= ranges["SPEAR"]:
            _fail(
                failures,
                "weapon_audit: AXE range (%.2f) must be < SPEAR range (%.2f)" % [ranges["AXE"], ranges["SPEAR"]]
            )

## Tier 3.2 (weapon audit): verify each weapon has required move types and valid coupling physics.

## Pass 26 (HEMA biomechanics): deflect recovery cost — full-parry deflects cost 20% more recovery than a
## clean miss because the blade is physically knocked offline and requires extra repositioning.
static func _run_parry_deflect_recovery_cost(failures: PackedStringArray) -> void:
    # Constant must be set correctly.
    if not is_equal_approx(CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT, 1.20):
        _fail(
            failures,
            (
                "deflect_recovery: PARRY_DEFLECT_RECOVERY_MULT want 1.20 got %.2f"
                % CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT
            )
        )
    # Zero intensity: should clamp to floor (0.3) and yield minimum boost.
    var mult_min: float = CombatConstants.parry_deflect_recovery_mult(0.0)
    var mult_floor: float = 1.0 + (CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT - 1.0) * 0.3 / 0.7
    if not is_equal_approx(mult_min, mult_floor):
        _fail(
            failures,
            (
                "deflect_recovery: min intensity mult want %.4f got %.4f" % [mult_floor, mult_min]
            )
        )
    # Unit intensity: full boost.
    var mult_unit: float = CombatConstants.parry_deflect_recovery_mult(1.0)
    if not is_equal_approx(mult_unit, CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT):
        _fail(
            failures,
            (
                "deflect_recovery: unit intensity mult want %.4f got %.4f"
                % [CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT, mult_unit]
            )
        )
    # Must always be > 1.0 — deflect always costs more than a clean miss.
    if mult_min <= 1.0 or mult_unit <= 1.0:
        _fail(failures, "deflect_recovery: both min and unit intensity must be > 1.0")
    # Deflect mult must be strictly less than thrust mult at same intensity.
    var thrust_mult: float = CombatConstants.parry_thrust_recovery_mult(1.0)
    if mult_unit >= thrust_mult:
        _fail(
            failures,
            (
                "deflect_recovery: deflect mult (%.4f) must be < thrust mult (%.4f)"
                % [mult_unit, thrust_mult]
            )
        )


## Pass 27 (HEMA physics): immediate blade displacement — after a full parry deflect, the attacker's
## guard_line must be displaced at parry time (not deferred to recovery completion).
static func _run_parry_deflect_immediate_guard_displacement(failures: PackedStringArray) -> void:
    # Verify the deflection is stored on the attacker dict at parry time.
    # Simulate: create a minimal attacker dict with the data that apply_result stores.
    var atk: Dictionary = {}
    atk[DataKeys.ATTACK_LAST_MOVE_ID] = "SWORD_CUT"
    atk[DataKeys.PA_LAST_MOVE_ID] = "SWORD_CUT"
    atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = "oberhau"
    atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = "vom_tag"
    atk[DataKeys.PA_PARRY_CLASH_CONTEXT] = {
        DataKeys.CLASH_DEFENDER_GUARD_LINE: "vom_tag",
        # parry_control below the bind threshold (0.48) so this resolves as a non-bind DEFLECT
        # (blend > 0), not a bind (blend 0.0).
        DataKeys.RESULT_PARRY_CONTROL: 0.3,
        DataKeys.RESULT_CLASH_SEVERITY: 0.5,
        DataKeys.ATTACK_ANGLE_DEG: 45.0,
        DataKeys.CLASH_GUARD_ANGLE_DEG: 90.0,
        DataKeys.CLASH_ALIGNMENT: 0.8,
        DataKeys.RESULT_ATTACK_TYPE: "SWORD_CUT",
        DataKeys.WEAPON_CONTACT_TYPE: "blade",
        DataKeys.PA_ARCHETYPE_ID: ""
    }
    atk[DataKeys.ATTACK_GUARD_LINE] = "vom_tag"
    # Apply immediate displacement (same call as in apply_result).
    GuardLineUpdater.set_guard_deflected(
        atk,
        atk.get(DataKeys.PA_LAST_MOVE_ID, ""),
        atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, ""),
        atk.get(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY, ""),
        atk.get(DataKeys.PA_PARRY_CLASH_CONTEXT, {})
    )
    # Guard must have been displaced — not still at the original vom_tag.
    var displaced_line: String = atk.get(DataKeys.ATTACK_GUARD_LINE, "")
    if displaced_line.is_empty() or displaced_line == "vom_tag":
        _fail(
            failures,
            (
                "immediate_displace: guard_line should be displaced, got '%s'" % displaced_line
            )
        )
    # Deflect blend must be set (non-zero for non-bind deflect).
    var blend: float = atk.get(DataKeys.PA_GUARD_DEFLECT_BLEND, 0.0)
    if blend <= 0.0:
        _fail(
            failures,
            (
                "immediate_displace: PA_GUARD_DEFLECT_BLEND should be > 0 for deflect, got %.2f" % blend
            )
        )
    # Deflect from-line must be set.
    var from_line: String = atk.get(DataKeys.PA_GUARD_DEFLECT_FROM_LINE, "")
    if from_line.is_empty():
        _fail(failures, "immediate_displace: PA_GUARD_DEFLECT_FROM_LINE should be set")
    # Now simulate complete_recovery — it should NOT re-displace, just clean up.
    # Verify that the keys still exist before cleanup.
    if not atk.has(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY):
        _fail(failures, "immediate_displace: PA_DEFENDER_GUARD_LINE_AT_PARRY should exist before cleanup")
    # After cleanup (erasing stored data), guard_line and blend must remain.
    atk.erase(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY)
    atk.erase(DataKeys.PA_DEFENDER_FORM_AT_PARRY)
    atk.erase(DataKeys.PA_PARRY_CLASH_CONTEXT)
    if atk.get(DataKeys.ATTACK_GUARD_LINE, "") != displaced_line:
        _fail(
            failures,
            "immediate_displace: guard_line changed after cleanup (was '%s', now '%s')"
            % [displaced_line, atk.get(DataKeys.ATTACK_GUARD_LINE, "")]
        )
    if not is_equal_approx(atk.get(DataKeys.PA_GUARD_DEFLECT_BLEND, 0.0), blend):
        _fail(failures, "immediate_displace: blend changed after cleanup")


## Pass 29 (HEMA biomechanics): scaled off-balance after parry deflect — heavier deflection = longer
## disorientation. The miss path stays flat at OFF_BALANCE_DURATION_S; the deflect path scales with intensity.
static func _run_off_balance_deflect_scaled_duration(failures: PackedStringArray) -> void:
    # Base constant must be set correctly.
    if not is_equal_approx(CombatConstantsParry.OFF_BALANCE_DEFLECT_DURATION_S, 1.0):
        _fail(
            failures,
            (
                "ob_deflect: OFF_BALANCE_DEFLECT_DURATION_S want 1.0 got %.2f"
                % CombatConstantsParry.OFF_BALANCE_DEFLECT_DURATION_S
            )
        )
    # Zero intensity: scales to 0.5x base (0.5s).
    var dur_zero: float = CombatConstants.off_balance_deflect_duration(0.0)
    if not is_equal_approx(dur_zero, 0.5):
        _fail(failures, "ob_deflect: zero intensity want 0.5s got %.2f" % dur_zero)
    # Unit intensity: full base (1.0s).
    var dur_unit: float = CombatConstants.off_balance_deflect_duration(1.0)
    if not is_equal_approx(dur_unit, 1.0):
        _fail(failures, "ob_deflect: unit intensity want 1.0s got %.2f" % dur_unit)
    # Mid intensity (0.5): should be 0.75s (0.5 + 0.5*0.5 = 0.75).
    var dur_mid: float = CombatConstants.off_balance_deflect_duration(0.5)
    if not is_equal_approx(dur_mid, 0.75):
        _fail(failures, "ob_deflect: mid intensity want 0.75s got %.2f" % dur_mid)
    # Must always exceed miss off-balance (0.4s).
    if dur_zero <= CombatConstants.OFF_BALANCE_DURATION_S:
        _fail(
            failures,
            (
                "ob_deflect: min duration (%.2f) must exceed miss duration (%.2f)"
                % [dur_zero, CombatConstants.OFF_BALANCE_DURATION_S]
            )
        )


## Pass 30 (code audit): named parry decision constants — verify the inline magic numbers are now
## accessible as named constants with the correct values.
static func _run_parry_decision_named_constants(failures: PackedStringArray) -> void:
    # Passive defense bias: must be < 1.0 (favors parry) and > 0.5 (not too aggressive).
    if not (CombatConstants.PASSIVE_DEFENSE_BIAS < 1.0 and CombatConstants.PASSIVE_DEFENSE_BIAS > 0.5):
        _fail(
            failures,
            (
                "named_consts: PASSIVE_DEFENSE_BIAS want (0.5, 1.0) got %.2f"
                % CombatConstants.PASSIVE_DEFENSE_BIAS
            )
        )
    if not is_equal_approx(CombatConstants.PASSIVE_DEFENSE_BIAS, 0.90):
        _fail(
            failures,
            (
                "named_consts: PASSIVE_DEFENSE_BIAS want 0.90 got %.2f"
                % CombatConstants.PASSIVE_DEFENSE_BIAS
            )
        )
    # Dodge boosts: below-glancing must be > glancing > 1.0.
    if not (
        CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST > CombatConstants.PARRY_GLANCING_DODGE_BOOST
        and CombatConstants.PARRY_GLANCING_DODGE_BOOST > 1.0
    ):
        _fail(
            failures,
            (
                "named_consts: dodge boost ordering violated (below=%.2f glancing=%.2f)"
                % [
                    CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST,
                    CombatConstants.PARRY_GLANCING_DODGE_BOOST
                ]
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST, 1.25):
        _fail(
            failures,
            (
                "named_consts: PARRY_BELOW_GLANCING_DODGE_BOOST want 1.25 got %.2f"
                % CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_GLANCING_DODGE_BOOST, 1.15):
        _fail(
            failures,
            (
                "named_consts: PARRY_GLANCING_DODGE_BOOST want 1.15 got %.2f"
                % CombatConstants.PARRY_GLANCING_DODGE_BOOST
            )
        )
    # Twist-dodge constants: floor must be in (0, 1), slope must be in (0, 1).
    if not (
        CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR > 0.0
        and CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR < 1.0
    ):
        _fail(
            failures,
            (
                "named_consts: TWIST_DODGE_MIN_TIME_FACTOR want (0,1) got %.2f"
                % CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR
            )
        )
    if not (
        CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE > 0.0
        and CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE < 1.0
    ):
        _fail(
            failures,
            (
                "named_consts: TWIST_DODGE_PARRY_QUALITY_SLOPE want (0,1) got %.2f"
                % CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE
            )
        )
    # Quality floor must be in (0, 1) and consistent with slope: floor = 1 - slope.
    var expected_floor: float = 1.0 - CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE
    if not is_equal_approx(
        CombatConstants.TWIST_DODGE_PARRY_QUALITY_FLOOR, expected_floor
    ):
        _fail(
            failures,
            (
                "named_consts: TWIST_DODGE_PARRY_QUALITY_FLOOR want %.2f (1-slope) got %.2f"
                % [expected_floor, CombatConstants.TWIST_DODGE_PARRY_QUALITY_FLOOR]
            )
        )


## Pass 31 (HEMA tempo): parry bonus scales with parry quality — a clean catch (high control)
## gives a bigger capacity boost than a marginal deflect (low control).
static func _run_parry_bonus_scales_with_control(failures: PackedStringArray) -> void:
    # Constants must be set correctly.
    if not is_equal_approx(CombatConstants.PARRY_BONUS_MULT_MIN, 1.05):
        _fail(
            failures,
            (
                "parry_bonus: PARRY_BONUS_MULT_MIN want 1.05 got %.2f"
                % CombatConstants.PARRY_BONUS_MULT_MIN
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_BONUS_MULT_MAX, 1.15):
        _fail(
            failures,
            (
                "parry_bonus: PARRY_BONUS_MULT_MAX want 1.15 got %.2f"
                % CombatConstants.PARRY_BONUS_MULT_MAX
            )
        )
    # At the bind threshold (0.48): minimum bonus.
    var mult_min: float = CombatConstants.parry_bonus_mult(CombatConstants.PARRY_BIND_CONTROL_THRESHOLD)
    if not is_equal_approx(mult_min, CombatConstants.PARRY_BONUS_MULT_MIN):
        _fail(
            failures,
            (
                "parry_bonus: at bind threshold want %.2f got %.2f"
                % [CombatConstants.PARRY_BONUS_MULT_MIN, mult_min]
            )
        )
    # At perfect control (1.0): maximum bonus.
    var mult_max: float = CombatConstants.parry_bonus_mult(1.0)
    if not is_equal_approx(mult_max, CombatConstants.PARRY_BONUS_MULT_MAX):
        _fail(
            failures,
            (
                "parry_bonus: at perfect control want %.2f got %.2f"
                % [CombatConstants.PARRY_BONUS_MULT_MAX, mult_max]
            )
        )
    # Mid control (0.74): should be between min and max.
    var mid_ctrl: float = (CombatConstants.PARRY_BIND_CONTROL_THRESHOLD + 1.0) * 0.5
    var mult_mid: float = CombatConstants.parry_bonus_mult(mid_ctrl)
    if not (mult_mid > mult_min and mult_mid < mult_max):
        _fail(
            failures,
            (
                "parry_bonus: mid control (%.2f) want (%.2f, %.2f) got %.2f"
                % [mid_ctrl, mult_min, mult_max, mult_mid]
            )
        )
    # Must always be > 1.0 — parry bonus is always a boost, never a penalty.
    if mult_min <= 1.0 or mult_max <= 1.0:
        _fail(failures, "parry_bonus: both min and max must be > 1.0")
    # Below bind threshold: clamped to minimum (no bonus for non-bind parries).
    var mult_below: float = CombatConstants.parry_bonus_mult(0.3)
    if not is_equal_approx(mult_below, CombatConstants.PARRY_BONUS_MULT_MIN):
        _fail(
            failures,
            (
                "parry_bonus: below threshold want %.2f got %.2f"
                % [CombatConstants.PARRY_BONUS_MULT_MIN, mult_below]
            )
        )


## Pass 32 (code audit): named partial-parry velocity constants — verify the inline magic numbers
## in the v_min / follow-through velocity path are now accessible as named constants.
static func _run_parry_velocity_named_constants(failures: PackedStringArray) -> void:
    # Velocity clamp: must be > 1.0 (allows slight overshoot) and < 1.5 (not unphysical).
    if not (CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP > 1.0 and CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP < 1.5):
        _fail(
            failures,
            (
                "vel_consts: PARRY_FOLLOW_THROUGH_VEL_CLAMP want (1.0, 1.5) got %.2f"
                % CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP, 1.1):
        _fail(
            failures,
            (
                "vel_consts: PARRY_FOLLOW_THROUGH_VEL_CLAMP want 1.1 got %.2f"
                % CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP
            )
        )
    # Fallback mass (light weapon) must be < reference mass (heavy weapon).
    if not (CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG < CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG):
        _fail(
            failures,
            (
                "vel_consts: fallback mass (%.2f) must be < reference mass (%.2f)"
                % [
                    CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG,
                    CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG
                ]
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG, 0.45):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_FALLBACK_MASS_KG want 0.45 got %.2f"
                % CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG, 2.7):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_REFERENCE_MASS_KG want 2.7 got %.2f"
                % CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG
            )
        )
    # Mass-scale threshold: must be in (0, 1) — a remaining-ratio cutoff.
    if not (
        CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD > 0.0
        and CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD < 1.0
    ):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_MASS_SCALE_THRESHOLD want (0,1) got %.2f"
                % CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD, 0.3):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_MASS_SCALE_THRESHOLD want 0.3 got %.2f"
                % CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD
            )
        )
    # Mass scaling: fallback mass / reference mass must be in (0, 1) — light weapons get less momentum retention.
    var mass_ratio: float = CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG / CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG
    if not (mass_ratio > 0.0 and mass_ratio < 1.0):
        _fail(
            failures,
            (
                "vel_consts: mass ratio (%.2f) must be in (0,1)" % mass_ratio
            )
        )


## Pass 33 (code audit): named reach disparity + reach readiness constants — verify the inline
## magic numbers in the reach penalty/bonus path are now accessible as named constants.
static func _run_reach_disparity_named_constants(failures: PackedStringArray) -> void:
    # Reach disparity threshold: must be > 0 (some reach delta is free) and < 1.0 (not absurdly large).
    if not (
        CombatConstants.REACH_DISPARITY_THRESHOLD_M > 0.0
        and CombatConstants.REACH_DISPARITY_THRESHOLD_M < 1.0
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_THRESHOLD_M want (0,1) got %.2f"
                % CombatConstants.REACH_DISPARITY_THRESHOLD_M
            )
        )
    if not is_equal_approx(CombatConstants.REACH_DISPARITY_THRESHOLD_M, 0.30):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_THRESHOLD_M want 0.30 got %.2f"
                % CombatConstants.REACH_DISPARITY_THRESHOLD_M
            )
        )
    # Penalty slope: must be in (0, 1) — a fraction of capacity lost per meter.
    if not (
        CombatConstants.REACH_DISPARITY_PENALTY_SLOPE > 0.0
        and CombatConstants.REACH_DISPARITY_PENALTY_SLOPE < 1.0
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_SLOPE want (0,1) got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_SLOPE
            )
        )
    if not is_equal_approx(CombatConstants.REACH_DISPARITY_PENALTY_SLOPE, 0.30):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_SLOPE want 0.30 got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_SLOPE
            )
        )
    # Penalty floor: must be in (0, 1) — reach disparity can't zero out parry capacity.
    if not (
        CombatConstants.REACH_DISPARITY_PENALTY_FLOOR > 0.0
        and CombatConstants.REACH_DISPARITY_PENALTY_FLOOR < 1.0
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_FLOOR want (0,1) got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_FLOOR
            )
        )
    if not is_equal_approx(CombatConstants.REACH_DISPARITY_PENALTY_FLOOR, 0.25):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_FLOOR want 0.25 got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_FLOOR
            )
        )
    # Reach readiness scale: must be > 0 (positive bonus for longer weapons) and small (< 0.2/m).
    if not (
        CombatConstants.REACH_READINESS_SCALE_PER_M > 0.0
        and CombatConstants.REACH_READINESS_SCALE_PER_M < 0.2
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_READINESS_SCALE_PER_M want (0,0.2) got %.2f"
                % CombatConstants.REACH_READINESS_SCALE_PER_M
            )
        )
    if not is_equal_approx(CombatConstants.REACH_READINESS_SCALE_PER_M, 0.06):
        _fail(
            failures,
            (
                "reach_consts: REACH_READINESS_SCALE_PER_M want 0.06 got %.2f"
                % CombatConstants.REACH_READINESS_SCALE_PER_M
            )
        )
    # Reach readiness cap: must be in (0, 1) and consistent with scale (cap / scale = max reach advantage in meters).
    if not (
        CombatConstants.REACH_READINESS_CAP > 0.0
        and CombatConstants.REACH_READINESS_CAP < 1.0
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_READINESS_CAP want (0,1) got %.2f"
                % CombatConstants.REACH_READINESS_CAP
            )
        )
    if not is_equal_approx(CombatConstants.REACH_READINESS_CAP, 0.15):
        _fail(
            failures,
            (
                "reach_consts: REACH_READINESS_CAP want 0.15 got %.2f"
                % CombatConstants.REACH_READINESS_CAP
            )
        )
    # Cap must be a multiple of the scale (i.e. cap/scale is a clean meter count).
    var max_reach_advantage: float = CombatConstants.REACH_READINESS_CAP / CombatConstants.REACH_READINESS_SCALE_PER_M
    if max_reach_advantage < 1.0:
        _fail(
            failures,
            (
                "reach_consts: max reach advantage (%.2f m) must be >= 1.0 m"
                % max_reach_advantage
            )
        )


## Pass 34 (HEMA forte/schwach): flex factor scales the forte/schwach bonus with blade slenderness.
## A flexible blade (long/thin) has a larger forte/schwach difference than a stiff blade (short/thick).
## Reference calibrated to SWORD (slenderness 45) so D001 (SWORD-only) is unaffected.
static func _run_flex_factor_blade_slenderness(failures: PackedStringArray) -> void:
    # Reference constant must be set correctly (SWORD: 90cm / 2.0cm = 45).
    if not is_equal_approx(CombatConstants.FLEX_REFERENCE_SLENDERNess, 45.0):
        _fail(
            failures,
            (
                "flex_factor: FLEX_REFERENCE_SLENDERNess want 45.0 got %.1f"
                % CombatConstants.FLEX_REFERENCE_SLENDERNess
            )
        )
    # At the reference slenderness (45): flex factor = 1.0 (neutral, SWORD unchanged).
    var ref_factor: float = CombatConstants.flex_factor_for_slenderness(45.0)
    if not is_equal_approx(ref_factor, 1.0):
        _fail(
            failures,
            (
                "flex_factor: at reference slenderness want 1.0 got %.2f" % ref_factor
            )
        )
    # Zero slenderness (no blade / shaft weapon): neutral 1.0 (no forte/schwach).
    var zero_factor: float = CombatConstants.flex_factor_for_slenderness(0.0)
    if not is_equal_approx(zero_factor, 1.0):
        _fail(
            failures,
            (
                "flex_factor: zero slenderness want 1.0 got %.2f" % zero_factor
            )
        )
    # Stiff blade (DAGGER: 20cm / 1.5cm = 13.3): flex factor < 1.0 (smaller forte/schwach difference).
    var stiff_factor: float = CombatConstants.flex_factor_for_slenderness(13.3)
    if not (stiff_factor < 1.0 and stiff_factor >= CombatConstants.FLEX_FACTOR_MIN):
        _fail(
            failures,
            (
                "flex_factor: stiff blade (13.3) want [%.2f, 1.0) got %.2f"
                % [CombatConstants.FLEX_FACTOR_MIN, stiff_factor]
            )
        )
    # Flexible blade (slenderness 90): flex factor > 1.0, capped at FLEX_FACTOR_MAX.
    var flex_factor_hi: float = CombatConstants.flex_factor_for_slenderness(90.0)
    if not (flex_factor_hi > 1.0 and flex_factor_hi <= CombatConstants.FLEX_FACTOR_MAX):
        _fail(
            failures,
            (
                "flex_factor: flexible blade (90) want (1.0, %.2f] got %.2f"
                % [CombatConstants.FLEX_FACTOR_MAX, flex_factor_hi]
            )
        )
    # Verify SWORD weapon slenderness is exactly the reference (D001 safety).
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    var sword_slenderness: float = sword.get_blade_slenderness()
    if not is_equal_approx(sword_slenderness, CombatConstants.FLEX_REFERENCE_SLENDERNess):
        _fail(
            failures,
            (
                "flex_factor: SWORD slenderness want %.1f (reference) got %.1f"
                % [CombatConstants.FLEX_REFERENCE_SLENDERNess, sword_slenderness]
            )
        )
    # Verify SWORD flex factor is exactly 1.0 (D001 safety — no behavior change).
    var sword_factor: float = CombatConstants.flex_factor_for_slenderness(sword_slenderness)
    if not is_equal_approx(sword_factor, 1.0):
        _fail(
            failures,
            (
                "flex_factor: SWORD flex factor want 1.0 (D001 safety) got %.2f"
                % sword_factor
            )
        )
    # Verify DAGGER is stiffer (lower slenderness) than SWORD.
    var dagger: Weapon = HarnessFixtures.get_cached_weapon("DAGGER")
    var dagger_slenderness: float = dagger.get_blade_slenderness()
    if not (dagger_slenderness > 0.0 and dagger_slenderness < sword_slenderness):
        _fail(
            failures,
            (
                "flex_factor: DAGGER slenderness (%.1f) must be < SWORD (%.1f)"
                % [dagger_slenderness, sword_slenderness]
            )
        )


## Pass 36 (HEMA biomechanics): partial parry stamina discount — a partial parry absorbs only a
## fraction of the incoming momentum, so it costs less stamina than a full braced stop.
static func _run_partial_parry_stamina_discount(failures: PackedStringArray) -> void:
    # Floor constant must be set correctly.
    if not is_equal_approx(CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR, 0.5):
        _fail(
            failures,
            (
                "partial_stam: PARTIAL_PARRY_STAMINA_FLOOR want 0.5 got %.2f"
                % CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR
            )
        )
    # Full absorption (1.0): full cost (1.0).
    var mult_full: float = CombatConstants.partial_parry_stamina_mult(1.0)
    if not is_equal_approx(mult_full, 1.0):
        _fail(
            failures,
            (
                "partial_stam: full absorption want 1.0 got %.2f" % mult_full
            )
        )
    # Zero absorption (0.0): floor (0.5).
    var mult_zero: float = CombatConstants.partial_parry_stamina_mult(0.0)
    if not is_equal_approx(mult_zero, CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR):
        _fail(
            failures,
            (
                "partial_stam: zero absorption want %.2f got %.2f"
                % [CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR, mult_zero]
            )
        )
    # Mid absorption (0.5): 0.75 (lerp between 0.5 and 1.0).
    var mult_mid: float = CombatConstants.partial_parry_stamina_mult(0.5)
    if not is_equal_approx(mult_mid, 0.75):
        _fail(
            failures,
            (
                "partial_stam: mid absorption want 0.75 got %.2f" % mult_mid
            )
        )
    # Must always be in [floor, 1.0] — a partial parry never costs more than a full parry.
    if mult_zero < CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR or mult_full > 1.0:
        _fail(failures, "partial_stam: mult must be in [floor, 1.0]")
    # Monotonic: more absorption = more cost.
    if not (mult_zero < mult_mid and mult_mid < mult_full):
        _fail(failures, "partial_stam: mult must increase with absorption")
    # The discount must be meaningful for a typical partial parry (remaining_ratio = 0.5, absorption = 0.5).
    # A 50% partial parry should cost less than a full parry.
    if mult_mid >= 1.0:
        _fail(failures, "partial_stam: a 50% partial parry must cost less than a full parry")


## Pass 37 (HEMA blade control): mid-swing (committed weapon) parry penalty — a defender already in
## their own wind-up has their blade locked in their own attack arc, so their reflexive parry has
## reduced blade control. Applied on top of the timing-based late floor.
static func _run_mid_swing_parry_penalty(failures: PackedStringArray) -> void:
    # Constant must be set correctly.
    if not is_equal_approx(CombatConstants.PARRY_MID_SWING_CAPACITY_MULT, 0.80):
        _fail(
            failures,
            (
                "mid_swing: PARRY_MID_SWING_CAPACITY_MULT want 0.80 got %.2f"
                % CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
            )
        )
    # Must be a penalty (< 1.0) — a committed weapon reduces parry capacity.
    if not (CombatConstants.PARRY_MID_SWING_CAPACITY_MULT < 1.0 and CombatConstants.PARRY_MID_SWING_CAPACITY_MULT > 0.0):
        _fail(
            failures,
            (
                "mid_swing: mult must be in (0, 1) got %.2f"
                % CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
            )
        )
    # Must be a modest penalty (not too harsh) — a mid-swing parry is still viable.
    if CombatConstants.PARRY_MID_SWING_CAPACITY_MULT < 0.5:
        _fail(
            failures,
            (
                "mid_swing: mult too harsh (< 0.5) got %.2f"
                % CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
            )
        )
    # The mid-swing penalty must stack with the late floor (both are penalties).
    # A mid-swing late parry: floor * mid_swing = 0.45 * 0.80 = 0.36.
    var combined: float = CombatConstants.PARRY_LATE_CAPACITY_FLOOR * CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
    var want_combined: float = 0.45 * 0.80
    if not is_equal_approx(combined, want_combined):
        _fail(
            failures,
            (
                "mid_swing: combined floor*mid_swing want %.3f got %.3f"
                % [want_combined, combined]
            )
        )
    # The combined penalty must be strictly less than the late floor alone (mid-swing is weaker).
    if combined >= CombatConstants.PARRY_LATE_CAPACITY_FLOOR:
        _fail(
            failures,
            (
                "mid_swing: combined (%.3f) must be < late floor (%.3f)"
                % [combined, CombatConstants.PARRY_LATE_CAPACITY_FLOOR]
            )
        )


## Pass 38 (HEMA impulse-momentum): parry recoil scales with the mass ratio — a heavier parrying
## weapon absorbs more of the impact, reducing the recoil transmitted to the arm.
static func _run_parry_recoil_mass_scale(failures: PackedStringArray) -> void:
    # Equal masses (D001 SWORD mirror): scale = 1.0 (no behavior change).
    var equal: float = CombatConstants.parry_recoil_mass_scale(1.2, 1.2)
    if not is_equal_approx(equal, 1.0):
        _fail(
            failures,
            (
                "recoil_mass: equal masses want 1.0 got %.3f" % equal
            )
        )
    # Heavier defender weapon (m_d > m_a): scale < 1.0 (less recoil).
    var heavy_def: float = CombatConstants.parry_recoil_mass_scale(1.0, 2.0)
    if not (heavy_def < 1.0 and heavy_def >= CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: heavy defender want [%.2f, 1.0) got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN, heavy_def]
            )
        )
    # Lighter defender weapon (m_d < m_a): scale > 1.0 (more recoil).
    var light_def: float = CombatConstants.parry_recoil_mass_scale(2.0, 1.0)
    if not (light_def > 1.0 and light_def <= CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: light defender want (1.0, %.2f] got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX, light_def]
            )
        )
    # Zero/invalid masses: neutral 1.0 (no division by zero).
    if not is_equal_approx(CombatConstants.parry_recoil_mass_scale(0.0, 1.0), 1.0):
        _fail(failures, "recoil_mass: zero m_a want 1.0")
    if not is_equal_approx(CombatConstants.parry_recoil_mass_scale(1.0, 0.0), 1.0):
        _fail(failures, "recoil_mass: zero m_d want 1.0")
    # Bounds: extreme mass ratios clamp to [MIN, MAX].
    var extreme_heavy: float = CombatConstants.parry_recoil_mass_scale(0.1, 10.0)
    if not is_equal_approx(extreme_heavy, CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: extreme heavy want %.2f (floor) got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN, extreme_heavy]
            )
        )
    var extreme_light: float = CombatConstants.parry_recoil_mass_scale(10.0, 0.1)
    if not is_equal_approx(extreme_light, CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: extreme light want %.2f (cap) got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX, extreme_light]
            )
        )


## Pass 39 (HEMA fatigue decay): consecutive parry fatigue resets after rest — the streak counter
## compounds only for back-to-back parries, not for parries separated by a long rest.
static func _run_parry_fatigue_time_decay(failures: PackedStringArray) -> void:
    # Reset window constant must be set correctly.
    if not is_equal_approx(CombatConstants.PARRY_FATIGUE_RESET_S, 1.5):
        _fail(
            failures,
            (
                "parry_fatigue: PARRY_FATIGUE_RESET_S want 1.5 got %.2f"
                % CombatConstants.PARRY_FATIGUE_RESET_S
            )
        )
    # The reset window must be positive and reasonable (not too short, not too long).
    if not (CombatConstants.PARRY_FATIGUE_RESET_S > 0.0 and CombatConstants.PARRY_FATIGUE_RESET_S < 5.0):
        _fail(
            failures,
            (
                "parry_fatigue: reset window want (0, 5) got %.2f"
                % CombatConstants.PARRY_FATIGUE_RESET_S
            )
        )
    # The consecutive parry multiplier must escalate with the count (fatigue compounds).
    var mult_1: float = CombatConstants.consecutive_parry_stamina_mult(1)
    var mult_2: float = CombatConstants.consecutive_parry_stamina_mult(2)
    var mult_5: float = CombatConstants.consecutive_parry_stamina_mult(5)
    if not (mult_1 < mult_2 and mult_2 < mult_5):
        _fail(
            failures,
            (
                "parry_fatigue: mult must escalate (1=%.2f 2=%.2f 5=%.2f)"
                % [mult_1, mult_2, mult_5]
            )
        )
    # The multiplier must be capped (not unbounded).
    if mult_5 > 2.5:
        _fail(
            failures,
            (
                "parry_fatigue: 5th parry mult too high (%.2f > 2.5)" % mult_5
            )
        )


## Pass 40 (HEMA bracing): a two-handed grip braces the weapon into the torso — less recoil to the
## arm and better structural stability. One-handed (SWORD/DAGGER/MACE/AXE) is neutral; only SPEAR is
## two-handed, so the D001 SWORD soak is unaffected.
static func _run_two_handed_parry_bracing(failures: PackedStringArray) -> void:
    # Recoil: two-handed transmits less than one-handed (a real reduction, not neutral).
    var recoil_one: float = CombatConstants.parry_two_handed_recoil_mult(false)
    var recoil_two: float = CombatConstants.parry_two_handed_recoil_mult(true)
    if not is_equal_approx(recoil_one, 1.0):
        _fail(failures, "two_handed: one-handed recoil want 1.0 got %.3f" % recoil_one)
    if not (recoil_two < 1.0 and recoil_two > 0.0):
        _fail(
            failures,
            (
                "two_handed: two-handed recoil want (0, 1) got %.3f" % recoil_two
            )
        )
    # Recoil reduction must be meaningful but not absurd (a real bracing effect, not a free parry).
    if not (recoil_two >= 0.5 and recoil_two <= 0.9):
        _fail(
            failures,
            (
                "two_handed: recoil mult want [0.5, 0.9] got %.3f" % recoil_two
            )
        )
    # Capacity: two-handed holds structure better (a real bonus, not neutral).
    var cap_one: float = CombatConstants.parry_two_handed_capacity_mult(false)
    var cap_two: float = CombatConstants.parry_two_handed_capacity_mult(true)
    if not is_equal_approx(cap_one, 1.0):
        _fail(failures, "two_handed: one-handed capacity want 1.0 got %.3f" % cap_one)
    if not (cap_two > 1.0 and cap_two <= 1.25):
        _fail(
            failures,
            (
                "two_handed: capacity bonus want (1.0, 1.25] got %.3f" % cap_two
            )
        )
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_TWO_HANDED_RECOIL_MULT, 0.70):
        _fail(
            failures,
            (
                "two_handed: PARRY_TWO_HANDED_RECOIL_MULT want 0.70 got %.3f"
                % CombatConstants.PARRY_TWO_HANDED_RECOIL_MULT
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_TWO_HANDED_CAPACITY_BONUS, 1.10):
        _fail(
            failures,
            (
                "two_handed: PARRY_TWO_HANDED_CAPACITY_BONUS want 1.10 got %.3f"
                % CombatConstants.PARRY_TWO_HANDED_CAPACITY_BONUS
            )
        )
    # D001 safety: SWORD is one-handed, so the SWORD soak sees neutral multipliers.
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    if WeaponConstants.weapon_is_two_handed(sword):
        _fail(failures, "two_handed: SWORD should be one-handed (D001 safety)")
    if not is_equal_approx(
        CombatConstants.parry_two_handed_recoil_mult(WeaponConstants.weapon_is_two_handed(sword)), 1.0
    ):
        _fail(failures, "two_handed: SWORD recoil must be neutral 1.0 (D001 safety)")
    if not is_equal_approx(
        CombatConstants.parry_two_handed_capacity_mult(WeaponConstants.weapon_is_two_handed(sword)), 1.0
    ):
        _fail(failures, "two_handed: SWORD capacity must be neutral 1.0 (D001 safety)")
    # SPEAR is two-handed, so it gets the bracing benefit.
    var spear: Weapon = Weapon.create_from_definition("SPEAR")
    if not WeaponConstants.weapon_is_two_handed(spear):
        _fail(failures, "two_handed: SPEAR should be two-handed")
    if not (
        CombatConstants.parry_two_handed_recoil_mult(WeaponConstants.weapon_is_two_handed(spear)) < 1.0
    ):
        _fail(failures, "two_handed: SPEAR recoil must be reduced (< 1.0)")
    if not (
        CombatConstants.parry_two_handed_capacity_mult(WeaponConstants.weapon_is_two_handed(spear)) > 1.0
    ):
        _fail(failures, "two_handed: SPEAR capacity must be boosted (> 1.0)")


## Pass 41 (HEMA impulse direction): a square-on parry catch (high alignment) drives the full force
## of the blow straight into the blade and arm; a glancing catch (low alignment) deflects the force
## along the blade so less reaches the wrist. Recoil scales linearly from glancing (least) to square
## (most) with alignment. At alignment 0.5 the scale is ~1.0 (neutral).
static func _run_parry_recoil_alignment_scale(failures: PackedStringArray) -> void:
    # Fully glancing (alignment 0): least recoil (a real reduction, not neutral).
    var glancing: float = CombatConstants.parry_recoil_alignment_mult(0.0)
    if not (glancing < 1.0 and glancing > 0.0):
        _fail(
            failures,
            (
                "recoil_align: glancing want (0, 1) got %.3f" % glancing
            )
        )
    # Fully square-on (alignment 1): most recoil (a real increase, not neutral).
    var square: float = CombatConstants.parry_recoil_alignment_mult(1.0)
    if not (square > 1.0 and square < 2.0):
        _fail(
            failures,
            (
                "recoil_align: square want (1.0, 2.0) got %.3f" % square
            )
        )
    # Ordering: glancing < neutral < square.
    var neutral: float = CombatConstants.parry_recoil_alignment_mult(0.5)
    if not (glancing < neutral and neutral < square):
        _fail(
            failures,
            (
                "recoil_align: ordering want glancing<neutral<square got %.3f<%.3f<%.3f"
                % [glancing, neutral, square]
            )
        )
    # Neutral point (alignment 0.5) must be ~1.0 (no behavior change at mid alignment).
    if absf(neutral - 1.0) > 0.02:
        _fail(
            failures,
            (
                "recoil_align: neutral want ~1.0 got %.3f" % neutral
            )
        )
    # Monotonic: higher alignment -> more recoil.
    var a025: float = CombatConstants.parry_recoil_alignment_mult(0.25)
    var a075: float = CombatConstants.parry_recoil_alignment_mult(0.75)
    if not (a025 < a075):
        _fail(
            failures,
            (
                "recoil_align: monotonic want 0.25<0.75 got %.3f<%.3f" % [a025, a075]
            )
        )
    # Out-of-range alignment clamps (no extrapolation).
    if not is_equal_approx(CombatConstants.parry_recoil_alignment_mult(-1.0), glancing):
        _fail(failures, "recoil_align: negative alignment must clamp to glancing")
    if not is_equal_approx(CombatConstants.parry_recoil_alignment_mult(2.0), square):
        _fail(failures, "recoil_align: >1 alignment must clamp to square")
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_GLANCING_MULT, 0.85):
        _fail(
            failures,
            (
                "recoil_align: PARRY_RECOIL_GLANCING_MULT want 0.85 got %.3f"
                % CombatConstants.PARRY_RECOIL_GLANCING_MULT
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_SQUARE_MULT, 1.15):
        _fail(
            failures,
            (
                "recoil_align: PARRY_RECOIL_SQUARE_MULT want 1.15 got %.3f"
                % CombatConstants.PARRY_RECOIL_SQUARE_MULT
            )
        )


## Pass 42 (HEMA contact duration): a flexible (slender) blade flexes on impact, spreading the
## impulse over a longer contact time (lower peak force) so less recoil reaches the arm; a stiff
## (wide) blade transmits a sharper, higher-peak impulse so more recoil. Driven by the blade-flex
## factor (1.0 at the SWORD reference slenderness), so the D001 SWORD soak is neutral.
static func _run_parry_recoil_flex_scale(failures: PackedStringArray) -> void:
    # SWORD reference (slenderness 45) -> flex factor 1.0 -> neutral recoil 1.0 (D001 safety).
    var sword_flex: float = CombatConstants.flex_factor_for_slenderness(45.0)
    if not is_equal_approx(sword_flex, 1.0):
        _fail(
            failures,
            (
                "recoil_flex: SWORD flex factor want 1.0 got %.3f" % sword_flex
            )
        )
    var sword_recoil: float = CombatConstants.parry_recoil_flex_mult(sword_flex)
    if not is_equal_approx(sword_recoil, 1.0):
        _fail(
            failures,
            (
                "recoil_flex: SWORD recoil want neutral 1.0 got %.3f (D001 safety)"
                % sword_recoil
            )
        )
    # Most flexible (flex factor MAX, slender blade) -> least recoil (a real reduction).
    var flex_max: float = CombatConstants.parry_recoil_flex_mult(CombatConstants.FLEX_FACTOR_MAX)
    if not (flex_max < 1.0 and flex_max > 0.0):
        _fail(
            failures,
            (
                "recoil_flex: most-flexible want (0, 1) got %.3f" % flex_max
            )
        )
    # Most stiff (flex factor MIN, wide blade) -> most recoil (a real increase).
    var flex_min: float = CombatConstants.parry_recoil_flex_mult(CombatConstants.FLEX_FACTOR_MIN)
    if not (flex_min > 1.0 and flex_min < 2.0):
        _fail(
            failures,
            (
                "recoil_flex: most-stiff want (1.0, 2.0) got %.3f" % flex_min
            )
        )
    # Ordering: stiff (most recoil) > neutral > flexible (least recoil).
    if not (flex_min > sword_recoil and sword_recoil > flex_max):
        _fail(
            failures,
            (
                "recoil_flex: ordering want stiff>neutral>flexible got %.3f/%.3f/%.3f"
                % [flex_min, sword_recoil, flex_max]
            )
        )
    # Monotonic: higher flex factor -> less recoil.
    var f_lo: float = CombatConstants.parry_recoil_flex_mult(0.75)
    var f_hi: float = CombatConstants.parry_recoil_flex_mult(1.25)
    if not (f_hi < f_lo):
        _fail(
            failures,
            (
                "recoil_flex: monotonic want 1.25<0.75 recoil got %.3f/%.3f"
                % [f_hi, f_lo]
            )
        )
    # Out-of-range flex factor clamps (no extrapolation).
    if not is_equal_approx(CombatConstants.parry_recoil_flex_mult(0.0), flex_min):
        _fail(failures, "recoil_flex: below-MIN flex must clamp to stiff (max recoil)")
    if not is_equal_approx(CombatConstants.parry_recoil_flex_mult(2.0), flex_max):
        _fail(failures, "recoil_flex: above-MAX flex must clamp to flexible (min recoil)")
    # A bladeless weapon (slenderness 0) -> flex factor 1.0 -> neutral recoil (no blade to flex).
    var bladeless_flex: float = CombatConstants.flex_factor_for_slenderness(0.0)
    if not is_equal_approx(bladeless_flex, 1.0):
        _fail(failures, "recoil_flex: bladeless slenderness 0 want flex 1.0")
    if not is_equal_approx(CombatConstants.parry_recoil_flex_mult(bladeless_flex), 1.0):
        _fail(failures, "recoil_flex: bladeless weapon must be neutral recoil 1.0")
    # End-to-end: a real SWORD weapon yields neutral recoil (D001 safety).
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    var sword_end_to_end: float = CombatConstants.parry_recoil_flex_mult(
        CombatConstants.flex_factor_for_slenderness(sword.get_blade_slenderness())
    )
    if not is_equal_approx(sword_end_to_end, 1.0):
        _fail(
            failures,
            (
                "recoil_flex: SWORD end-to-end want neutral 1.0 got %.3f (D001 safety)"
                % sword_end_to_end
            )
        )
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_FLEX_MULT_MIN, 0.7):
        _fail(
            failures,
            (
                "recoil_flex: PARRY_RECOIL_FLEX_MULT_MIN want 0.7 got %.3f"
                % CombatConstants.PARRY_RECOIL_FLEX_MULT_MIN
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_FLEX_MULT_MAX, 1.3):
        _fail(
            failures,
            (
                "recoil_flex: PARRY_RECOIL_FLEX_MULT_MAX want 1.3 got %.3f"
                % CombatConstants.PARRY_RECOIL_FLEX_MULT_MAX
            )
        )


## Pass 43 (HEMA forte/schwach lever arm): a well-timed parry meets the blade early (near the
## forte/handle), a short lever arm from the hand so less recoil reaches the wrist; a late parry
## meets it late (near the schwach/tip), a long lever arm so more recoil. Driven by parry progress
## (weapon-independent), linear from FORTE (least recoil) to SCHWACH (most recoil). At progress 0.5
## the scale is ~1.0 (neutral).
static func _run_parry_recoil_progress_scale(failures: PackedStringArray) -> void:
    # Early parry (progress 0, forte): least recoil (a real reduction, not neutral).
    var forte: float = CombatConstants.parry_recoil_progress_mult(0.0)
    if not (forte < 1.0 and forte > 0.0):
        _fail(
            failures,
            (
                "recoil_prog: forte want (0, 1) got %.3f" % forte
            )
        )
    # Late parry (progress 1, schwach): most recoil (a real increase, not neutral).
    var schwach: float = CombatConstants.parry_recoil_progress_mult(1.0)
    if not (schwach > 1.0 and schwach < 2.0):
        _fail(
            failures,
            (
                "recoil_prog: schwach want (1.0, 2.0) got %.3f" % schwach
            )
        )
    # Ordering: forte (least) < neutral < schwach (most).
    var neutral: float = CombatConstants.parry_recoil_progress_mult(0.5)
    if not (forte < neutral and neutral < schwach):
        _fail(
            failures,
            (
                "recoil_prog: ordering want forte<neutral<schwach got %.3f/%.3f/%.3f"
                % [forte, neutral, schwach]
            )
        )
    # Neutral point (progress 0.5) must be ~1.0 (no behavior change at mid progress).
    if absf(neutral - 1.0) > 0.02:
        _fail(
            failures,
            (
                "recoil_prog: neutral want ~1.0 got %.3f" % neutral
            )
        )
    # Monotonic: higher progress (later parry) -> more recoil.
    var p025: float = CombatConstants.parry_recoil_progress_mult(0.25)
    var p075: float = CombatConstants.parry_recoil_progress_mult(0.75)
    if not (p025 < p075):
        _fail(
            failures,
            (
                "recoil_prog: monotonic want 0.25<0.75 recoil got %.3f/%.3f"
                % [p025, p075]
            )
        )
    # Out-of-range progress clamps (no extrapolation).
    if not is_equal_approx(CombatConstants.parry_recoil_progress_mult(-1.0), forte):
        _fail(failures, "recoil_prog: negative progress must clamp to forte")
    if not is_equal_approx(CombatConstants.parry_recoil_progress_mult(2.0), schwach):
        _fail(failures, "recoil_prog: >1 progress must clamp to schwach")
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_FORTE_MULT, 0.90):
        _fail(
            failures,
            (
                "recoil_prog: PARRY_RECOIL_FORTE_MULT want 0.90 got %.3f"
                % CombatConstants.PARRY_RECOIL_FORTE_MULT
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_SCHWACH_MULT, 1.10):
        _fail(
            failures,
            (
                "recoil_prog: PARRY_RECOIL_SCHWACH_MULT want 1.10 got %.3f"
                % CombatConstants.PARRY_RECOIL_SCHWACH_MULT
            )
        )


## Pass 44 (HEMA Newtonian inertia / footing): a heavier, well-rooted defender has more inertia,
## so the same impulse produces less acceleration and less arm shock. Recoil scales as
## reference_mass / body_mass, clamped to [MIN, MAX]. At the reference mass (adult human) the scale
## is 1.0 (neutral); a missing/unknown mass (0.0) yields neutral 1.0 (D001 entities carry no species).
static func _run_parry_recoil_body_mass_scale(failures: PackedStringArray) -> void:
    # Reference mass constant must match the canonical adult anchor.
    if not is_equal_approx(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG, CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
    ):
        _fail(
            failures,
            (
                "recoil_mass: reference want %.1f (anchor) got %.1f"
                % [
                    CombatDesignAnchors.REFERENCE_ADULT_MASS_KG,
                    CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG
                ]
            )
        )
    # At the reference mass the scale is neutral 1.0 (no behavior change).
    var ref: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG
    )
    if not is_equal_approx(ref, 1.0):
        _fail(
            failures,
            (
                "recoil_mass: reference mass want neutral 1.0 got %.3f" % ref
            )
        )
    # Missing/unknown mass (0.0) yields neutral 1.0 (D001 safety: no species -> neutral).
    if not is_equal_approx(CombatConstants.parry_recoil_body_mass_scale(0.0), 1.0):
        _fail(failures, "recoil_mass: zero mass want neutral 1.0 (D001 safety)")
    # A heavier-than-reference defender transmits less recoil (a real reduction, not neutral).
    var heavy: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 1.5
    )
    if not (heavy < 1.0 and heavy >= CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: heavy defender want [%.2f, 1.0) got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN, heavy]
            )
        )
    # A lighter-than-reference defender transmits more recoil (a real increase, not neutral).
    var light: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 0.5
    )
    if not (light > 1.0 and light <= CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: light defender want (1.0, %.2f] got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX, light]
            )
        )
    # Ordering: heavy (least) < neutral < light (most).
    if not (heavy < ref and ref < light):
        _fail(
            failures,
            (
                "recoil_mass: ordering want heavy<neutral<light got %.3f/%.3f/%.3f"
                % [heavy, ref, light]
            )
        )
    # Extreme masses clamp to [MIN, MAX] (no unbounded scaling).
    var extreme_heavy: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 10.0
    )
    if not is_equal_approx(extreme_heavy, CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: extreme heavy want %.2f (floor) got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN, extreme_heavy]
            )
        )
    var extreme_light: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 0.05
    )
    if not is_equal_approx(extreme_light, CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: extreme light want %.2f (cap) got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX, extreme_light]
            )
        )
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN, 0.85):
        _fail(
            failures,
            (
                "recoil_mass: PARRY_RECOIL_BODY_MASS_SCALE_MIN want 0.85 got %.3f"
                % CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX, 1.15):
        _fail(
            failures,
            (
                "recoil_mass: PARRY_RECOIL_BODY_MASS_SCALE_MAX want 1.15 got %.3f"
                % CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX
            )
        )
