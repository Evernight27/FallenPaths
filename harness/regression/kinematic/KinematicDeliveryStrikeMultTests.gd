class_name KinematicDeliveryStrikeMultTests
extends CombatRegressionHarnessCore


static func _run_kinematic_delivery_strike_mult_cross_coupling_ke_vs_blunt_isolated(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_cross: missing sword")
        return
    var w_axe: Weapon = Weapon.create_from_definition("AXE")
    var w_dagger: Weapon = Weapon.create_from_definition("DAGGER")
    if w_axe == null or w_dagger == null:
        _fail(failures, "kin_cross: missing axe or dagger")
        return
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var move_cut: String = "oberhau"
    var ai_lo_p: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_lo_p.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_lo_p.velocity_m_s = 10.0
    ai_lo_p.strike_energy_mult = 1.0
    ai_lo_p.strike_momentum_mult = 1.0
    var ai_hi_p: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_hi_p.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_hi_p.velocity_m_s = 10.0
    ai_hi_p.strike_energy_mult = 1.0
    ai_hi_p.strike_momentum_mult = 4.25
    var ke_lo_p: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo_p)
    var ke_hi_p: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi_p)
    if absf(ke_hi_p - ke_lo_p) > 0.0001:
        _fail(failures, "kin_cross: KE should ignore strike_momentum_mult (lo=%.6f hi=%.6f)" % [ke_lo_p, ke_hi_p])
    var pen_lo_p: float = float(
        WeaponDamageHelper.compute_penetration(sword, ai_lo_p, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_hi_p: float = float(
        WeaponDamageHelper.compute_penetration(sword, ai_hi_p, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_hi_p - pen_lo_p) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                % [pen_lo_p, pen_hi_p]
            )
        )
    var cut_lo_pm: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo_p, 100.0, 1.0)
    var cut_hi_pm: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi_p, 100.0, 1.0)
    if absf(cut_hi_pm - cut_lo_pm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                % [cut_lo_pm, cut_hi_pm]
            )
        )
    var ev_sw_pm_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_lo_p)
    var ev_sw_pm_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_hi_p)
    if absf(ev_sw_pm_hi - ev_sw_pm_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: pinned get_effective_velocity_m_s should ignore strike_momentum_mult (sword lo=%.6f hi=%.6f"
                + ")" % [ev_sw_pm_lo, ev_sw_pm_hi]
            )
        )
    var v_pin_cross: float = 10.0
    var ev_wx_pm_lo: float
    var ev_wx_pm_hi: float
    for wcx_pm: Dictionary in [
        {"w": w_axe, "move": "diagonal_chop", "pfx": "kin_cross_ax_pm"},
        {"w": w_dagger, "move": "quick_slash", "pfx": "kin_cross_dg_pm"},
    ]:
        var wp: Weapon = wcx_pm["w"] as Weapon
        var mv: String = str(wcx_pm["move"])
        var pfx: String = str(wcx_pm["pfx"])
        var lo_x: AttackInstance = AttackInstance.new(mv, 0.5)
        lo_x.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        lo_x.velocity_m_s = v_pin_cross
        lo_x.strike_energy_mult = 1.0
        lo_x.strike_momentum_mult = 1.0
        var hi_x: AttackInstance = AttackInstance.new(mv, 0.5)
        hi_x.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        hi_x.velocity_m_s = v_pin_cross
        hi_x.strike_energy_mult = 1.0
        hi_x.strike_momentum_mult = 4.25
        var ke_lo_x: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, lo_x)
        var ke_hi_x: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, hi_x)
        if absf(ke_hi_x - ke_lo_x) > 0.0001:
            _fail(failures, "%s: KE should ignore strike_momentum_mult (lo=%.6f hi=%.6f)" % [pfx, ke_lo_x, ke_hi_x])
        var pen_lo_x: float = float(
            WeaponDamageHelper.compute_penetration(wp, lo_x, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
                "penetration_sharp", -1.0
            )
        )
        var pen_hi_x: float = float(
            WeaponDamageHelper.compute_penetration(wp, hi_x, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
                "penetration_sharp", -1.0
            )
        )
        if absf(pen_hi_x - pen_lo_x) > 0.0001:
            _fail(
                failures,
                (
                    "%s: SHARP penetration_sharp should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                    % [pfx, pen_lo_x, pen_hi_x]
                )
            )
        var cut_lo_x: float = WeaponDamageHelper.compute_pre_armor_cut(wp, lo_x, strength, arm_mod)
        var cut_hi_x: float = WeaponDamageHelper.compute_pre_armor_cut(wp, hi_x, strength, arm_mod)
        if absf(cut_hi_x - cut_lo_x) > 0.0001:
            _fail(
                failures,
                (
                    "%s: compute_pre_armor_cut should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                    % [pfx, cut_lo_x, cut_hi_x]
                )
            )
        ev_wx_pm_lo = WeaponDamageHelper.get_effective_velocity_m_s(wp, lo_x)
        ev_wx_pm_hi = WeaponDamageHelper.get_effective_velocity_m_s(wp, hi_x)
        if absf(ev_wx_pm_hi - ev_wx_pm_lo) > 0.0001:
            _fail(
                failures,
                (
                    "%s: pinned get_effective_velocity_m_s should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                    % [pfx, ev_wx_pm_lo, ev_wx_pm_hi]
                )
            )
    var sv_p_lo: AttackInstance = AttackInstance.new(move_cut, 0.63)
    sv_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    sv_p_lo.strike_energy_mult = 1.0
    sv_p_lo.strike_momentum_mult = 1.0
    var sv_p_hi: AttackInstance = AttackInstance.new(move_cut, 0.63)
    sv_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    sv_p_hi.strike_energy_mult = 1.0
    sv_p_hi.strike_momentum_mult = 4.25
    var ev_p_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_p_lo)
    var ev_p_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_p_hi)
    if absf(ev_p_hi - ev_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                % [ev_p_lo, ev_p_hi]
            )
        )
    var move_ax: String = "diagonal_chop"
    var ax_p_lo: AttackInstance = AttackInstance.new(move_ax, 0.63)
    ax_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ax_p_lo.strike_energy_mult = 1.0
    ax_p_lo.strike_momentum_mult = 1.0
    var ax_p_hi: AttackInstance = AttackInstance.new(move_ax, 0.63)
    ax_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ax_p_hi.strike_energy_mult = 1.0
    ax_p_hi.strike_momentum_mult = 4.25
    var move_dg: String = "quick_slash"
    var dg_p_lo: AttackInstance = AttackInstance.new(move_dg, 0.63)
    dg_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    dg_p_lo.strike_energy_mult = 1.0
    dg_p_lo.strike_momentum_mult = 1.0
    var dg_p_hi: AttackInstance = AttackInstance.new(move_dg, 0.63)
    dg_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    dg_p_hi.strike_energy_mult = 1.0
    dg_p_hi.strike_momentum_mult = 4.25
    var ev_ax_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_p_lo)
    var ev_ax_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_p_hi)
    if absf(ev_ax_hi - ev_ax_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (axe lo=%.6f hi=%.6f)"
                % [ev_ax_lo, ev_ax_hi]
            )
        )
    var ev_dg_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_p_lo)
    var ev_dg_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_p_hi)
    if absf(ev_dg_hi - ev_dg_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (dagger lo=%.6f hi=%."
                + "6f)" % [ev_dg_lo, ev_dg_hi]
            )
        )
    var mace: Weapon = Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_cross: missing mace")
        return
    var spear: Weapon = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "kin_cross: missing spear")
        return
    var move_bl: String = "direct_blow"
    var b_lo_e: AttackInstance = AttackInstance.new(move_bl, 0.5)
    b_lo_e.velocity_m_s = 10.0
    b_lo_e.strike_energy_mult = 1.0
    b_lo_e.strike_momentum_mult = 1.0
    var b_hi_e: AttackInstance = AttackInstance.new(move_bl, 0.5)
    b_hi_e.velocity_m_s = 10.0
    b_hi_e.strike_energy_mult = 3.1
    b_hi_e.strike_momentum_mult = 1.0
    var mv_e_lo: AttackInstance = AttackInstance.new(move_bl, 0.58)
    mv_e_lo.strike_energy_mult = 1.0
    mv_e_lo.strike_momentum_mult = 1.0
    var mv_e_hi: AttackInstance = AttackInstance.new(move_bl, 0.58)
    mv_e_hi.strike_energy_mult = 3.1
    mv_e_hi.strike_momentum_mult = 1.0
    var ev_e_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_e_lo)
    var ev_e_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_e_hi)
    if absf(ev_e_hi - ev_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (mace lo=%.6f hi=%.6f)"
                % [ev_e_lo, ev_e_hi]
            )
        )
    var mv_p_lo: AttackInstance = AttackInstance.new(move_bl, 0.57)
    mv_p_lo.strike_energy_mult = 1.0
    mv_p_lo.strike_momentum_mult = 1.0
    var mv_p_hi: AttackInstance = AttackInstance.new(move_bl, 0.57)
    mv_p_hi.strike_energy_mult = 1.0
    mv_p_hi.strike_momentum_mult = 2.85
    var ev_m_p_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_p_lo)
    var ev_m_p_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_p_hi)
    if absf(ev_m_p_hi - ev_m_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (mace lo=%.6f hi=%.6f"
                + ")" % [ev_m_p_lo, ev_m_p_hi]
            )
        )
    var move_thr: String = "spear_thrust"
    var sp_p_lo: AttackInstance = AttackInstance.new(move_thr, 0.56)
    sp_p_lo.strike_energy_mult = 1.0
    sp_p_lo.strike_momentum_mult = 1.0
    var sp_p_hi: AttackInstance = AttackInstance.new(move_thr, 0.56)
    sp_p_hi.strike_energy_mult = 1.0
    sp_p_hi.strike_momentum_mult = 3.5
    var ev_sp_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_p_lo)
    var ev_sp_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_p_hi)
    if absf(ev_sp_hi - ev_sp_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (spear lo=%.6f hi=%.6"
                + "f)" % [ev_sp_lo, ev_sp_hi]
            )
        )
    var sp_e_lo: AttackInstance = AttackInstance.new(move_thr, 0.54)
    sp_e_lo.strike_energy_mult = 1.0
    sp_e_lo.strike_momentum_mult = 1.0
    var sp_e_hi: AttackInstance = AttackInstance.new(move_thr, 0.54)
    sp_e_hi.strike_energy_mult = 2.7
    sp_e_hi.strike_momentum_mult = 1.0
    var ev_ste_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_e_lo)
    var ev_ste_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_e_hi)
    if absf(ev_ste_hi - ev_ste_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (spear lo=%.6f hi=%.6f)"
                % [ev_ste_lo, ev_ste_hi]
            )
        )
    var ke_sv_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, sv_p_lo)
    var ke_sv_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, sv_p_hi)
    if absf(ke_sv_der_hi - ke_sv_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
                % [ke_sv_der_lo, ke_sv_der_hi]
            )
        )
    var ke_mv_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(mace, mv_p_lo)
    var ke_mv_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(mace, mv_p_hi)
    if absf(ke_mv_der_hi - ke_mv_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
                % [ke_mv_der_lo, ke_mv_der_hi]
            )
        )
    var ke_sp_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, sp_p_lo)
    var ke_sp_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, sp_p_hi)
    if absf(ke_sp_der_hi - ke_sp_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
                % [ke_sp_der_lo, ke_sp_der_hi]
            )
        )
    var ke_ax_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w_axe, ax_p_lo)
    var ke_ax_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w_axe, ax_p_hi)
    if absf(ke_ax_der_hi - ke_ax_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (axe swing derived v lo=%.6f hi=%.6f)"
                % [ke_ax_der_lo, ke_ax_der_hi]
            )
        )
    var ke_dg_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w_dagger, dg_p_lo)
    var ke_dg_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w_dagger, dg_p_hi)
    if absf(ke_dg_der_hi - ke_dg_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (dagger swing derived v lo=%.6f hi=%.6f)"
                % [ke_dg_der_lo, ke_dg_der_hi]
            )
        )
    var pen_sv_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_sv_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_sv_p_hi - pen_sv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f"
                + ")" % [pen_sv_p_lo, pen_sv_p_hi]
            )
        )
    var cut_sv_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, sv_p_lo, strength, arm_mod)
    var cut_sv_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, sv_p_hi, strength, arm_mod)
    if absf(cut_sv_p_hi - cut_sv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
                % [cut_sv_p_lo, cut_sv_p_hi]
            )
        )
    var pen_ax_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_ax_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_ax_p_hi - pen_ax_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (axe derived v lo=%.6f hi=%.6f)"
                % [pen_ax_p_lo, pen_ax_p_hi]
            )
        )
    var cut_ax_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(w_axe, ax_p_lo, strength, arm_mod)
    var cut_ax_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(w_axe, ax_p_hi, strength, arm_mod)
    if absf(cut_ax_p_hi - cut_ax_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (axe derived v lo=%.6f hi=%.6f)"
                % [cut_ax_p_lo, cut_ax_p_hi]
            )
        )
    var pen_dg_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_dg_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_dg_p_hi - pen_dg_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (dagger derived v lo=%.6f hi=%.6"
                + "f)" % [pen_dg_p_lo, pen_dg_p_hi]
            )
        )
    var cut_dg_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(w_dagger, dg_p_lo, strength, arm_mod)
    var cut_dg_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(w_dagger, dg_p_hi, strength, arm_mod)
    if absf(cut_dg_p_hi - cut_dg_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (dagger derived v lo=%.6f hi=%.6f)"
                % [cut_dg_p_lo, cut_dg_p_hi]
            )
        )
    var pen_sp_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_sp_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_sp_p_hi - pen_sp_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (spear thrust derived v lo=%.6f "
                + "hi=%.6f)" % [pen_sp_p_lo, pen_sp_p_hi]
            )
        )
    var cut_sp_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(spear, sp_p_lo, strength, arm_mod)
    var cut_sp_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(spear, sp_p_hi, strength, arm_mod)
    if absf(cut_sp_p_hi - cut_sp_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi"
                + "=%.6f)" % [cut_sp_p_lo, cut_sp_p_hi]
            )
        )
    var pen_mv_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_mv_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_mv_p_hi - pen_mv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi"
                + "=%.6f)" % [pen_mv_p_lo, pen_mv_p_hi]
            )
        )
    var cut_mv_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(mace, mv_p_lo, strength, arm_mod)
    var cut_mv_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(mace, mv_p_hi, strength, arm_mod)
    if absf(cut_mv_p_hi - cut_mv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%"
                + ".6f)" % [cut_mv_p_lo, cut_mv_p_hi]
            )
        )
    var blunt_lo_e: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo_e, strength, arm_mod)
    var blunt_hi_e: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi_e, strength, arm_mod)
    if absf(blunt_hi_e - blunt_lo_e) > 0.0001:
        _fail(
            failures,
            "kin_cross: blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [blunt_lo_e, blunt_hi_e]
        )
    var mpa_lo_e: float = float(
        WeaponDamageHelper.compute_penetration(mace, b_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_hi_e: float = float(
        WeaponDamageHelper.compute_penetration(mace, b_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_hi_e - mpa_lo_e) > 0.0001:
        _fail(
            failures, "kin_cross: BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [mpa_lo_e, mpa_hi_e]
        )
    var tgt_kg_blunt: float = 73.0
    var blunt_lo_e_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo_e, strength, arm_mod, tgt_kg_blunt)
    var blunt_hi_e_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi_e, strength, arm_mod, tgt_kg_blunt)
    if absf(blunt_hi_e_rm - blunt_lo_e_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [blunt_lo_e_rm, blunt_hi_e_rm]
            )
        )
    var opts_rm: Dictionary = {"target_effective_mass_kg": 68.0}
    var mpa_lo_e_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, b_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_hi_e_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, b_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_hi_e_rm - mpa_lo_e_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [mpa_lo_e_rm, mpa_hi_e_rm]
            )
        )
    var blunt_mv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, mv_e_lo, strength, arm_mod)
    var blunt_mv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, mv_e_hi, strength, arm_mod)
    if absf(blunt_mv_e_hi - blunt_mv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
                % [blunt_mv_e_lo, blunt_mv_e_hi]
            )
        )
    var mpa_mv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_mv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_mv_e_hi - mpa_mv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
                % [mpa_mv_e_lo, mpa_mv_e_hi]
            )
        )
    var blunt_mv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
        mace, mv_e_lo, strength, arm_mod, tgt_kg_blunt
    )
    var blunt_mv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
        mace, mv_e_hi, strength, arm_mod, tgt_kg_blunt
    )
    if absf(blunt_mv_e_rm_hi - blunt_mv_e_rm_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (mace derived v lo=%.6f hi="
                + "%.6f)" % [blunt_mv_e_rm_lo, blunt_mv_e_rm_hi]
            )
        )
    var mpa_mv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_mv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_mv_e_hi_rm - mpa_mv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa (target mass opts) should ignore strike_energy_mult (mace derived v lo=%.6f hi=%."
                + "6f)" % [mpa_mv_e_lo_rm, mpa_mv_e_hi_rm]
            )
        )
    var blunt_sp_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(spear, sp_e_lo, strength, arm_mod)
    var blunt_sp_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(spear, sp_e_hi, strength, arm_mod)
    if absf(blunt_sp_e_hi - blunt_sp_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (spear derived v lo=%.6f hi=%.6f)"
                % [blunt_sp_e_lo, blunt_sp_e_hi]
            )
        )
    var mpa_sp_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_sp_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_sp_e_hi - mpa_sp_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa should ignore strike_energy_mult (spear derived v lo=%.6f hi=%.6f)"
                % [mpa_sp_e_lo, mpa_sp_e_hi]
            )
        )
    var sw_lo_e: AttackInstance = AttackInstance.new(move_cut, 0.5)
    sw_lo_e.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    sw_lo_e.velocity_m_s = 10.0
    sw_lo_e.strike_energy_mult = 1.0
    sw_lo_e.strike_momentum_mult = 1.0
    var sw_hi_e: AttackInstance = AttackInstance.new(move_cut, 0.5)
    sw_hi_e.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    sw_hi_e.velocity_m_s = 10.0
    sw_hi_e.strike_energy_mult = 3.1
    sw_hi_e.strike_momentum_mult = 1.0
    var ev_pin_sw_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sw_lo_e)
    var ev_pin_sw_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sw_hi_e)
    if absf(ev_pin_sw_hi - ev_pin_sw_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: pinned get_effective_velocity_m_s should ignore strike_energy_mult (sword lo=%.6f hi=%.6f)"
                % [ev_pin_sw_lo, ev_pin_sw_hi]
            )
        )
    var s_blunt_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sw_lo_e, strength, arm_mod)
    var s_blunt_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sw_hi_e, strength, arm_mod)
    if absf(s_blunt_hi - s_blunt_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [s_blunt_lo, s_blunt_hi]
            )
        )
    var tgt_kg_sword: float = 71.0
    var s_blunt_lo_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
        sword, sw_lo_e, strength, arm_mod, tgt_kg_sword
    )
    var s_blunt_hi_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
        sword, sw_hi_e, strength, arm_mod, tgt_kg_sword
    )
    if absf(s_blunt_hi_rm - s_blunt_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [s_blunt_lo_rm, s_blunt_hi_rm]
            )
        )
    var mpa_s_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_s_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_s_hi - mpa_s_lo) > 0.0001:
        _fail(
            failures,
            "kin_cross: sword BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [mpa_s_lo, mpa_s_hi]
        )
    var mpa_s_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_s_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_s_hi_rm - mpa_s_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [mpa_s_lo_rm, mpa_s_hi_rm]
            )
        )
    var sv_e_lo: AttackInstance = AttackInstance.new(move_cut, 0.61)
    sv_e_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    sv_e_lo.strike_energy_mult = 1.0
    sv_e_lo.strike_momentum_mult = 1.0
    var sv_e_hi: AttackInstance = AttackInstance.new(move_cut, 0.61)
    sv_e_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    sv_e_hi.strike_energy_mult = 3.1
    sv_e_hi.strike_momentum_mult = 1.0
    var ev_s_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_e_lo)
    var ev_s_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_e_hi)
    if absf(ev_s_hi - ev_s_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (sword lo=%.6f hi=%.6f)"
                % [ev_s_lo, ev_s_hi]
            )
        )
    var blunt_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sv_e_lo, strength, arm_mod)
    var blunt_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sv_e_hi, strength, arm_mod)
    if absf(blunt_sv_e_hi - blunt_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (sword derived v lo=%.6f hi=%.6f)"
                % [blunt_sv_e_lo, blunt_sv_e_hi]
            )
        )
    var blunt_sv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
        sword, sv_e_lo, strength, arm_mod, tgt_kg_sword
    )
    var blunt_sv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
        sword, sv_e_hi, strength, arm_mod, tgt_kg_sword
    )
    if absf(blunt_sv_e_rm_hi - blunt_sv_e_rm_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (sword derived v lo=%.6f hi"
                + "=%.6f)" % [blunt_sv_e_rm_lo, blunt_sv_e_rm_hi]
            )
        )
    var mpa_sv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_sv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_sv_e_hi - mpa_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_sv_e_lo, mpa_sv_e_hi]
            )
        )
    var mpa_sv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_sv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_sv_e_hi_rm - mpa_sv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%"
                + ".6f)" % [mpa_sv_e_lo_rm, mpa_sv_e_hi_rm]
            )
        )
    for swx: Dictionary in [
        {
            "w": w_axe,
            "move": "diagonal_chop",
            "v": 10.0,
            "pfx": "kin_cross_ax_sw_e",
            "tgt_kg": 71.0,
        },
        {
            "w": w_dagger,
            "move": "quick_slash",
            "v": 20.0,
            "pfx": "kin_cross_dg_sw_e",
            "tgt_kg": 71.0,
        },
    ]:
        var wx: Weapon = swx["w"] as Weapon
        var mvx: String = str(swx["move"])
        var pfxx: String = str(swx["pfx"])
        var vx: float = float(swx["v"])
        var tk: float = float(swx["tgt_kg"])
        var slo: AttackInstance = AttackInstance.new(mvx, 0.5)
        slo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        slo.velocity_m_s = vx
        slo.strike_energy_mult = 1.0
        slo.strike_momentum_mult = 1.0
        var shi: AttackInstance = AttackInstance.new(mvx, 0.5)
        shi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        shi.velocity_m_s = vx
        shi.strike_energy_mult = 3.1
        shi.strike_momentum_mult = 1.0
        var ev_pin_wx_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(wx, slo)
        var ev_pin_wx_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(wx, shi)
        if absf(ev_pin_wx_hi - ev_pin_wx_lo) > 0.0001:
            _fail(
                failures,
                (
                    "%s: pinned get_effective_velocity_m_s should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                    % [pfxx, ev_pin_wx_lo, ev_pin_wx_hi]
                )
            )
        var bl0: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, slo, strength, arm_mod)
        var bl1: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, shi, strength, arm_mod)
        if absf(bl1 - bl0) > 0.0001:
            _fail(failures, "%s: blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [pfxx, bl0, bl1])
        var bl0r: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, slo, strength, arm_mod, tk)
        var bl1r: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, shi, strength, arm_mod, tk)
        if absf(bl1r - bl0r) > 0.0001:
            _fail(
                failures,
                (
                    "%s: blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                    % [pfxx, bl0r, bl1r]
                )
            )
        var mp0: float = float(
            WeaponDamageHelper.compute_penetration(wx, slo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
                "penetration_blunt_momentum_per_area", -1.0
            )
        )
        var mp1: float = float(
            WeaponDamageHelper.compute_penetration(wx, shi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
                "penetration_blunt_momentum_per_area", -1.0
            )
        )
        if absf(mp1 - mp0) > 0.0001:
            _fail(failures, "%s: BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [pfxx, mp0, mp1])
        var mp0r: float = float(
            WeaponDamageHelper.compute_penetration(wx, slo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
                "penetration_blunt_momentum_per_area", -1.0
            )
        )
        var mp1r: float = float(
            WeaponDamageHelper.compute_penetration(wx, shi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
                "penetration_blunt_momentum_per_area", -1.0
            )
        )
        if absf(mp1r - mp0r) > 0.0001:
            _fail(
                failures,
                (
                    "%s: BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                    % [pfxx, mp0r, mp1r]
                )
            )
    var ax_sv_e_lo: AttackInstance = AttackInstance.new(move_ax, 0.61)
    ax_sv_e_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ax_sv_e_lo.strike_energy_mult = 1.0
    ax_sv_e_lo.strike_momentum_mult = 1.0
    var ax_sv_e_hi: AttackInstance = AttackInstance.new(move_ax, 0.61)
    ax_sv_e_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ax_sv_e_hi.strike_energy_mult = 3.1
    ax_sv_e_hi.strike_momentum_mult = 1.0
    var ev_ax_e_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_sv_e_lo)
    var ev_ax_e_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_sv_e_hi)
    if absf(ev_ax_e_hi - ev_ax_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (axe lo=%.6f hi=%.6f)"
                % [ev_ax_e_lo, ev_ax_e_hi]
            )
        )
    var blunt_ax_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(w_axe, ax_sv_e_lo, strength, arm_mod)
    var blunt_ax_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(w_axe, ax_sv_e_hi, strength, arm_mod)
    if absf(blunt_ax_sv_e_hi - blunt_ax_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (axe derived v lo=%.6f hi=%.6f)"
                % [blunt_ax_sv_e_lo, blunt_ax_sv_e_hi]
            )
        )
    var blunt_ax_sv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
        w_axe, ax_sv_e_lo, strength, arm_mod, 71.0
    )
    var blunt_ax_sv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
        w_axe, ax_sv_e_hi, strength, arm_mod, 71.0
    )
    if absf(blunt_ax_sv_e_rm_hi - blunt_ax_sv_e_rm_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (axe derived v lo=%.6f hi=%"
                + ".6f)" % [blunt_ax_sv_e_rm_lo, blunt_ax_sv_e_rm_hi]
            )
        )
    var mpa_ax_sv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_ax_sv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_ax_sv_e_hi - mpa_ax_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: axe BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_ax_sv_e_lo, mpa_ax_sv_e_hi]
            )
        )
    var mpa_ax_sv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_ax_sv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_ax_sv_e_hi_rm - mpa_ax_sv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: axe BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6"
                + "f)" % [mpa_ax_sv_e_lo_rm, mpa_ax_sv_e_hi_rm]
            )
        )
    var dg_sv_e_lo: AttackInstance = AttackInstance.new(move_dg, 0.61)
    dg_sv_e_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    dg_sv_e_lo.strike_energy_mult = 1.0
    dg_sv_e_lo.strike_momentum_mult = 1.0
    var dg_sv_e_hi: AttackInstance = AttackInstance.new(move_dg, 0.61)
    dg_sv_e_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    dg_sv_e_hi.strike_energy_mult = 3.1
    dg_sv_e_hi.strike_momentum_mult = 1.0
    var ev_dg_e_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_sv_e_lo)
    var ev_dg_e_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_sv_e_hi)
    if absf(ev_dg_e_hi - ev_dg_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (dagger lo=%.6f hi=%.6f"
                + ")" % [ev_dg_e_lo, ev_dg_e_hi]
            )
        )
    var blunt_dg_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(w_dagger, dg_sv_e_lo, strength, arm_mod)
    var blunt_dg_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(w_dagger, dg_sv_e_hi, strength, arm_mod)
    if absf(blunt_dg_sv_e_hi - blunt_dg_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (dagger derived v lo=%.6f hi=%.6f)"
                % [blunt_dg_sv_e_lo, blunt_dg_sv_e_hi]
            )
        )
    var blunt_dg_sv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
        w_dagger, dg_sv_e_lo, strength, arm_mod, 71.0
    )
    var blunt_dg_sv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
        w_dagger, dg_sv_e_hi, strength, arm_mod, 71.0
    )
    if absf(blunt_dg_sv_e_rm_hi - blunt_dg_sv_e_rm_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (dagger derived v lo=%.6f h"
                + "i=%.6f)" % [blunt_dg_sv_e_rm_lo, blunt_dg_sv_e_rm_hi]
            )
        )
    var mpa_dg_sv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_dg_sv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_dg_sv_e_hi - mpa_dg_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: dagger BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_dg_sv_e_lo, mpa_dg_sv_e_hi]
            )
        )
    var mpa_dg_sv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_dg_sv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_dg_sv_e_hi_rm - mpa_dg_sv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: dagger BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi="
                + "%.6f)" % [mpa_dg_sv_e_lo_rm, mpa_dg_sv_e_hi_rm]
            )
        )

## Tier 5.1 (optional long-tail): **`AttackResolver.penetration_oblique_angle_factor`** matches parry vs
## misaligned-guard **`lerp`** rules; **`velocity_override` < 0** -> **1** (no penetration oblique here).
