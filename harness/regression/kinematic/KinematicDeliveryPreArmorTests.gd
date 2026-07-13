class_name KinematicDeliveryPreArmorTests
extends CombatRegressionHarnessCore
## Tier 5.1: **`compute_pre_armor_cut`** scales with **`sqrt(KE)`** at fixed strength/**`arm_mod`** when
## **`velocity_m_s`** pins tip speed (no clamp skew)  -  **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**,
## **DAGGER** **`quick_slash`** (swing). **`compute_pre_armor_blunt`** rises with pinned speed on **MACE**
## **`direct_blow`** (momentum path).
static func _run_kinematic_delivery_pre_armor_cut_sqrt_ke_ratio_and_blunt_rises_with_speed(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_pre_armor: missing sword")
        return
    var move_cut: String = "oberhau"
    var ai_lo: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_lo.velocity_m_s = 8.0
    var ai_hi: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_hi.velocity_m_s = 15.0
    var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo)
    var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi)
    var cut_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo, strength, arm_mod)
    var cut_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi, strength, arm_mod)
    if ke_hi <= ke_lo + 1e-4:
        _fail(failures, "kin_pre_armor_cut: expected ke_hi > ke_lo got lo=%.4f hi=%.4f" % [ke_lo, ke_hi])
    if cut_hi <= cut_lo + 1e-4:
        _fail(failures, "kin_pre_armor_cut: cut_hi should exceed cut_lo (got lo=%.4f hi=%.4f)" % [cut_lo, cut_hi])
    var want_ratio: float = sqrt(ke_hi / ke_lo)
    var got_ratio: float = cut_hi / cut_lo
    if absf(got_ratio - want_ratio) > 0.03:
        _fail(
            failures,
            (
                "kin_pre_armor_cut: cut ratio %.4f want sqrt(ke) ratio %.4f (ke lo=%.4f hi=%.4f)"
                % [got_ratio, want_ratio, ke_lo, ke_hi]
            )
        )
    var arch_swing_cut: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    for cfx: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_pre_armor_cut_ax", "v_lo": 8.0, "v_hi": 15.0},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_pre_armor_cut_dg", "v_lo": 8.0, "v_hi": 15.0},
    ]:
        var w_c: Weapon = _Weapon.create_from_definition(str(cfx["def"]))
        if w_c == null:
            _fail(failures, "%s: missing %s" % [str(cfx["pfx"]), str(cfx["def"])])
            return
        var m_c: String = str(cfx["move"])
        var pfx_c: String = str(cfx["pfx"])
        var v_lo_c: float = float(cfx["v_lo"])
        var v_hi_c: float = float(cfx["v_hi"])
        var c_lo: AttackInstance = AttackInstance.new(m_c, 0.5)
        c_lo.archetype = arch_swing_cut
        c_lo.velocity_m_s = v_lo_c
        var c_hi: AttackInstance = AttackInstance.new(m_c, 0.5)
        c_hi.archetype = arch_swing_cut
        c_hi.velocity_m_s = v_hi_c
        var ke_lo_c: float = WeaponDamageHelper.compute_kinetic_energy_j(w_c, c_lo)
        var ke_hi_c: float = WeaponDamageHelper.compute_kinetic_energy_j(w_c, c_hi)
        var cut_lo_c: float = WeaponDamageHelper.compute_pre_armor_cut(w_c, c_lo, strength, arm_mod)
        var cut_hi_c: float = WeaponDamageHelper.compute_pre_armor_cut(w_c, c_hi, strength, arm_mod)
        if ke_hi_c <= ke_lo_c + 1e-4:
            _fail(failures, "%s: expected ke_hi > ke_lo got lo=%.4f hi=%.4f" % [pfx_c, ke_lo_c, ke_hi_c])
        if cut_hi_c <= cut_lo_c + 1e-4:
            _fail(failures, "%s: cut_hi should exceed cut_lo (lo=%.4f hi=%.4f)" % [pfx_c, cut_lo_c, cut_hi_c])
        var want_r_c: float = sqrt(ke_hi_c / ke_lo_c)
        var got_r_c: float = cut_hi_c / cut_lo_c
        if absf(got_r_c - want_r_c) > 0.03:
            _fail(
                failures,
                (
                    "%s: cut ratio %.4f want sqrt(ke) ratio %.4f (ke lo=%.4f hi=%.4f)"
                    % [pfx_c, got_r_c, want_r_c, ke_lo_c, ke_hi_c]
                )
            )
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_pre_armor: missing mace")
        return
    var move_blunt: String = "direct_blow"
    var b_lo: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_lo.velocity_m_s = 6.0
    var b_hi: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_hi.velocity_m_s = 14.0
    var blunt_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo, strength, arm_mod)
    var blunt_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi, strength, arm_mod)
    if blunt_hi <= blunt_lo + 1e-4:
        _fail(failures, "kin_pre_armor_blunt: blunt_hi should exceed blunt_lo (lo=%.4f hi=%.4f)" % [blunt_lo, blunt_hi])


## Tier 5.1: **`compute_penetration`**  -  **SHARP** **`penetration_sharp`** scales as **`(KE /
## J_BASE)^PENETRATION_EXPONENT`** - -  area factor (same move, pinned **`velocity_m_s`**) on **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing); **BLUNT** returns
## **`penetration_blunt_momentum_per_area`** increasing with pinned **`v`** on **MACE** **`direct_blow`**.


## Tier 5.1: **`compute_penetration`**  -  **SHARP** **`penetration_sharp`** scales as **`(KE /
## J_BASE)^PENETRATION_EXPONENT`** - -  area factor (same move, pinned **`velocity_m_s`**) on **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing); **BLUNT** returns
## **`penetration_blunt_momentum_per_area`** increasing with pinned **`v`** on **MACE** **`direct_blow`**.
static func _run_kinematic_delivery_penetration_sharp_ke_exponent_and_blunt_mpa_rises(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_pen: missing sword")
        return
    var move_cut: String = "oberhau"
    var ai_lo: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_lo.velocity_m_s = 9.0
    var ai_hi: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_hi.velocity_m_s = 16.0
    var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo)
    var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi)
    if ke_lo < 0.5:
        _fail(failures, "kin_pen_sharp: ke_lo unexpectedly small %.4f" % ke_lo)
    if ke_hi <= ke_lo + 1e-4:
        _fail(failures, "kin_pen_sharp: expected ke_hi > ke_lo lo=%.4f hi=%.4f" % [ke_lo, ke_hi])
    var pen_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, ai_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, ai_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if pen_lo <= 0.0 or pen_hi <= pen_lo + 1e-6:
        _fail(failures, "kin_pen_sharp: expected rising pen lo=%.6f hi=%.6f" % [pen_lo, pen_hi])
    var want_ratio: float = pow(ke_hi / ke_lo, WeaponConstants.PENETRATION_EXPONENT)
    var got_ratio: float = pen_hi / pen_lo
    if absf(got_ratio - want_ratio) > 0.05:
        _fail(
            failures,
            (
                "kin_pen_sharp: pen ratio %.4f want ke^exp ratio %.4f (ke lo=%.4f hi=%.4f exp=%.3f)"
                % [got_ratio, want_ratio, ke_lo, ke_hi, WeaponConstants.PENETRATION_EXPONENT]
            )
        )
    var arch_swing_pen: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var pen_v_lo: float = 9.0
    var pen_v_hi: float = 16.0
    for pfx_row: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_pen_sharp_ax"},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_pen_sharp_dg"},
    ]:
        var w_p: Weapon = _Weapon.create_from_definition(str(pfx_row["def"]))
        if w_p == null:
            _fail(failures, "%s: missing %s" % [str(pfx_row["pfx"]), str(pfx_row["def"])])
            return
        var m_p: String = str(pfx_row["move"])
        var pfx_p: String = str(pfx_row["pfx"])
        var p_lo: AttackInstance = AttackInstance.new(m_p, 0.5)
        p_lo.archetype = arch_swing_pen
        p_lo.velocity_m_s = pen_v_lo
        var p_hi: AttackInstance = AttackInstance.new(m_p, 0.5)
        p_hi.archetype = arch_swing_pen
        p_hi.velocity_m_s = pen_v_hi
        var ke_lo_p: float = WeaponDamageHelper.compute_kinetic_energy_j(w_p, p_lo)
        var ke_hi_p: float = WeaponDamageHelper.compute_kinetic_energy_j(w_p, p_hi)
        if ke_lo_p < 0.05:
            _fail(failures, "%s: ke_lo unexpectedly small %.4f" % [pfx_p, ke_lo_p])
        if ke_hi_p <= ke_lo_p + 1e-4:
            _fail(failures, "%s: expected ke_hi > ke_lo lo=%.4f hi=%.4f" % [pfx_p, ke_lo_p, ke_hi_p])
        var pen_lo_p: float = float(
            WeaponDamageHelper.compute_penetration(w_p, p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
                "penetration_sharp", -1.0
            )
        )
        var pen_hi_p: float = float(
            WeaponDamageHelper.compute_penetration(w_p, p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
                "penetration_sharp", -1.0
            )
        )
        if pen_lo_p <= 0.0 or pen_hi_p <= pen_lo_p + 1e-6:
            _fail(failures, "%s: expected rising pen lo=%.6f hi=%.6f" % [pfx_p, pen_lo_p, pen_hi_p])
        var want_rp: float = pow(ke_hi_p / ke_lo_p, WeaponConstants.PENETRATION_EXPONENT)
        var got_rp: float = pen_hi_p / pen_lo_p
        if absf(got_rp - want_rp) > 0.05:
            _fail(
                failures,
                (
                    "%s: pen ratio %.4f want ke^exp ratio %.4f (ke lo=%.4f hi=%.4f exp=%.3f)"
                    % [pfx_p, got_rp, want_rp, ke_lo_p, ke_hi_p, WeaponConstants.PENETRATION_EXPONENT]
                )
            )
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_pen: missing mace")
        return
    var move_blunt: String = "direct_blow"
    var b_lo: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_lo.velocity_m_s = 7.0
    var b_hi: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_hi.velocity_m_s = 13.0
    var d_lo: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var d_hi: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var mpa_lo: float = float(d_lo.get("penetration_blunt_momentum_per_area", -1.0))
    var mpa_hi: float = float(d_hi.get("penetration_blunt_momentum_per_area", -1.0))
    if mpa_lo <= 0.0 or mpa_hi <= mpa_lo + 1e-6:
        _fail(failures, "kin_pen_blunt: expected rising momentum/area lo=%.4f hi=%.4f" % [mpa_lo, mpa_hi])


## Tier 5.1: **`strike_energy_mult`** scales **`compute_kinetic_energy_j`** linearly (**`maxf(0.05, mult)`**);
## **`compute_pre_armor_cut`** ratio tracks **`sqrt(KE)`** at the same pinned **`v`** (swing  -  **SWORD**
## **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**). Same ratios on **`mixed`** +
## **`kinematic_mixed_blend` 0.5** with intensity-derived **`v`** (**`velocity_m_s` < 0**)  -  **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**.


## Tier 5.1: **`strike_energy_mult`** scales **`compute_kinetic_energy_j`** linearly (**`maxf(0.05, mult)`**);
## **`compute_pre_armor_cut`** ratio tracks **`sqrt(KE)`** at the same pinned **`v`** (swing  -  **SWORD**
## **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**). Same ratios on **`mixed`** +
## **`kinematic_mixed_blend` 0.5** with intensity-derived **`v`** (**`velocity_m_s` < 0**)  -  **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**.
static func _run_kinematic_delivery_strike_energy_mult_scales_ke_and_pre_armor_cut_sqrt(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_e_mult: missing sword")
        return
    var move_id: String = "oberhau"
    var mult_hi: float = 1.5625
    var ai_1: AttackInstance = AttackInstance.new(move_id, 0.5)
    ai_1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_1.velocity_m_s = 11.0
    ai_1.strike_energy_mult = 1.0
    var ai_2: AttackInstance = AttackInstance.new(move_id, 0.5)
    ai_2.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_2.velocity_m_s = 11.0
    ai_2.strike_energy_mult = mult_hi
    var ke_1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_1)
    var ke_2: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_2)
    if ke_1 <= 0.01:
        _fail(failures, "kin_e_mult: ke_1 too small %.6f" % ke_1)
    var ke_ratio: float = ke_2 / ke_1
    if absf(ke_ratio - mult_hi) > 0.02:
        _fail(failures, "kin_e_mult: ke ratio %.6f want strike_energy ratio %.4f" % [ke_ratio, mult_hi])
    var cut_1: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_1, strength, arm_mod)
    var cut_2: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_2, strength, arm_mod)
    var want_cut_ratio: float = sqrt(mult_hi)
    var cut_ratio: float = cut_2 / cut_1
    if absf(cut_ratio - want_cut_ratio) > 0.04:
        _fail(
            failures,
            (
                "kin_e_mult: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                % [cut_ratio, want_cut_ratio, cut_1, cut_2]
            )
        )
    var pin_v: float = 11.0
    var arch_swing: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    for pin_fx: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_e_mult_pin_ax"},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_e_mult_pin_dg"},
    ]:
        var wp: Weapon = _Weapon.create_from_definition(str(pin_fx["def"]))
        if wp == null:
            _fail(failures, "%s: missing %s" % [str(pin_fx["pfx"]), str(pin_fx["def"])])
            return
        var mp: String = str(pin_fx["move"])
        var pfxp: String = str(pin_fx["pfx"])
        var pi1: AttackInstance = AttackInstance.new(mp, 0.5)
        pi1.archetype = arch_swing
        pi1.velocity_m_s = pin_v
        pi1.strike_energy_mult = 1.0
        var pi2: AttackInstance = AttackInstance.new(mp, 0.5)
        pi2.archetype = arch_swing
        pi2.velocity_m_s = pin_v
        pi2.strike_energy_mult = mult_hi
        var kpe1: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, pi1)
        var kpe2: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, pi2)
        if kpe1 <= 0.01:
            _fail(failures, "%s: ke_1 too small %.6f" % [pfxp, kpe1])
        var kpe_r: float = kpe2 / kpe1
        if absf(kpe_r - mult_hi) > 0.02:
            _fail(failures, "%s: ke ratio %.6f want %.4f" % [pfxp, kpe_r, mult_hi])
        var cpe1: float = WeaponDamageHelper.compute_pre_armor_cut(wp, pi1, strength, arm_mod)
        var cpe2: float = WeaponDamageHelper.compute_pre_armor_cut(wp, pi2, strength, arm_mod)
        var cpe_rr: float = cpe2 / cpe1
        if absf(cpe_rr - want_cut_ratio) > 0.04:
            _fail(
                failures,
                (
                    "%s: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                    % [pfxp, cpe_rr, want_cut_ratio, cpe1, cpe2]
                )
            )
    var mixed_inten: float = 0.53
    var arch_mix: Dictionary = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5
    }
    var ai_mix_1: AttackInstance = AttackInstance.new(move_id, mixed_inten, -1.0)
    ai_mix_1.archetype = arch_mix
    ai_mix_1.strike_energy_mult = 1.0
    var ai_mix_2: AttackInstance = AttackInstance.new(move_id, mixed_inten, -1.0)
    ai_mix_2.archetype = arch_mix
    ai_mix_2.strike_energy_mult = mult_hi
    var ke_mix_1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix_1)
    var ke_mix_2: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix_2)
    if ke_mix_1 <= 0.01:
        _fail(failures, "kin_e_mult_mix: ke_mix_1 too small %.6f" % ke_mix_1)
    var ke_mix_ratio: float = ke_mix_2 / ke_mix_1
    if absf(ke_mix_ratio - mult_hi) > 0.02:
        _fail(failures, "kin_e_mult_mix: ke ratio %.6f want strike_energy ratio %.4f" % [ke_mix_ratio, mult_hi])
    var cut_mix_1: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_mix_1, strength, arm_mod)
    var cut_mix_2: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_mix_2, strength, arm_mod)
    var want_cut_mix_ratio: float = sqrt(mult_hi)
    var cut_mix_ratio: float = cut_mix_2 / cut_mix_1
    if absf(cut_mix_ratio - want_cut_mix_ratio) > 0.04:
        _fail(
            failures,
            (
                "kin_e_mult_mix: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                % [cut_mix_ratio, want_cut_mix_ratio, cut_mix_1, cut_mix_2]
            )
        )
    for fx: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_e_mult_mix_ax"},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_e_mult_mix_dg"},
    ]:
        var w_ex: Weapon = _Weapon.create_from_definition(str(fx["def"]))
        if w_ex == null:
            _fail(failures, "%s: missing %s" % [str(fx["pfx"]), str(fx["def"])])
            return
        var m_ex: String = str(fx["move"])
        var pfx: String = str(fx["pfx"])
        var wx1: AttackInstance = AttackInstance.new(m_ex, mixed_inten, -1.0)
        wx1.archetype = arch_mix
        wx1.strike_energy_mult = 1.0
        var wx2: AttackInstance = AttackInstance.new(m_ex, mixed_inten, -1.0)
        wx2.archetype = arch_mix
        wx2.strike_energy_mult = mult_hi
        var kx1: float = WeaponDamageHelper.compute_kinetic_energy_j(w_ex, wx1)
        var kx2: float = WeaponDamageHelper.compute_kinetic_energy_j(w_ex, wx2)
        if kx1 <= 0.01:
            _fail(failures, "%s: ke_1 too small %.6f" % [pfx, kx1])
        var kx_r: float = kx2 / kx1
        if absf(kx_r - mult_hi) > 0.02:
            _fail(failures, "%s: ke ratio %.6f want %.4f" % [pfx, kx_r, mult_hi])
        var cx1: float = WeaponDamageHelper.compute_pre_armor_cut(w_ex, wx1, strength, arm_mod)
        var cx2: float = WeaponDamageHelper.compute_pre_armor_cut(w_ex, wx2, strength, arm_mod)
        var cx_rr: float = cx2 / cx1
        if absf(cx_rr - want_cut_mix_ratio) > 0.04:
            _fail(
                failures,
                (
                    "%s: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                    % [pfx, cx_rr, want_cut_mix_ratio, cx1, cx2]
                )
            )


## Tier 5.1: **`strike_momentum_mult`** scales blunt momentum linearly (**`maxf(0.05, mult)`**);
## **`compute_pre_armor_blunt`** (full swing, clamped) and **`compute_blunt_slip_pre_armor`** (integration
## **`pre_blunt_applied`**) + **BLUNT** **`penetration_blunt_momentum_per_area`** track the same ratio at pinned
## **`v`**. **DAGGER** helper tests use **`v=20`**; integration slip lock
## **`_run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11`** uses **SWORD** **`oberhau`** at **`v=11`**.


## Tier 5.1: **`strike_momentum_mult`** scales blunt momentum linearly (**`maxf(0.05, mult)`**);
## **`compute_pre_armor_blunt`** (full swing, clamped) and **`compute_blunt_slip_pre_armor`** (integration
## **`pre_blunt_applied`**) + **BLUNT** **`penetration_blunt_momentum_per_area`** track the same ratio at pinned
## **`v`**. **DAGGER** helper tests use **`v=20`**; integration slip lock
## **`_run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11`** uses **SWORD** **`oberhau`** at **`v=11`**.
static func _run_kinematic_delivery_strike_momentum_mult_scales_blunt_damage_and_mpa(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_p_mult: missing mace")
        return
    var move_id: String = "direct_blow"
    var p_hi: float = 1.65
    var b_1: AttackInstance = AttackInstance.new(move_id, 0.5)
    b_1.velocity_m_s = 10.0
    b_1.strike_momentum_mult = 1.0
    var b_2: AttackInstance = AttackInstance.new(move_id, 0.5)
    b_2.velocity_m_s = 10.0
    b_2.strike_momentum_mult = p_hi
    var blunt_1: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_1, strength, arm_mod)
    var blunt_2: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_2, strength, arm_mod)
    if blunt_1 <= 0.01:
        _fail(failures, "kin_p_mult: blunt_1 too small %.4f" % blunt_1)
    var blunt_ratio: float = blunt_2 / blunt_1
    if absf(blunt_ratio - p_hi) > 0.03:
        _fail(failures, "kin_p_mult: blunt ratio %.4f want strike_momentum_mult ratio %.4f" % [blunt_ratio, p_hi])
    var d_1: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_1, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var d_2: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_2, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var mpa_1: float = float(d_1.get("penetration_blunt_momentum_per_area", -1.0))
    var mpa_2: float = float(d_2.get("penetration_blunt_momentum_per_area", -1.0))
    if mpa_1 <= 0.0:
        _fail(failures, "kin_p_mult: mpa_1 invalid %.4f" % mpa_1)
    var mpa_ratio: float = mpa_2 / mpa_1
    if absf(mpa_ratio - p_hi) > 0.03:
        _fail(failures, "kin_p_mult: mpa ratio %.4f want %.4f (mpa1=%.4f mpa2=%.4f)" % [mpa_ratio, p_hi, mpa_1, mpa_2])
    var arch_sw_bl: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var v_pin_mo: float = 10.0
    for cb: Dictionary in [
        {"def": "SWORD", "move": "oberhau", "pfx": "kin_p_mult_cb_sw"},
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_p_mult_cb_ax"},
        # Light blade: raise pinned **`v`** so raw blunt clears **`BLUNT_DAMAGE_MIN`** for both mults (narrow blade
        # otherwise clamps both samples to **1.0** -> ratio **1.0**).
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_p_mult_cb_dg", "v": 20.0},
    ]:
        var wcb: Weapon = _Weapon.create_from_definition(str(cb["def"]))
        if wcb == null:
            _fail(failures, "%s: missing %s" % [str(cb["pfx"]), str(cb["def"])])
            return
        var mvb: String = str(cb["move"])
        var tcb: String = str(cb["pfx"])
        var v_this: float = float(cb.get("v", v_pin_mo))
        var str_this: float = float(cb.get("strength", strength))
        var sb1: AttackInstance = AttackInstance.new(mvb, 0.5)
        sb1.archetype = arch_sw_bl
        sb1.velocity_m_s = v_this
        sb1.strike_momentum_mult = 1.0
        var sb2: AttackInstance = AttackInstance.new(mvb, 0.5)
        sb2.archetype = arch_sw_bl
        sb2.velocity_m_s = v_this
        sb2.strike_momentum_mult = p_hi
        var bl1: float = WeaponDamageHelper.compute_pre_armor_blunt(wcb, sb1, str_this, arm_mod)
        var bl2: float = WeaponDamageHelper.compute_pre_armor_blunt(wcb, sb2, str_this, arm_mod)
        if bl1 <= 0.001:
            _fail(failures, "%s: blunt_1 too small %.4f" % [tcb, bl1])
        var bl_r: float = bl2 / bl1
        if absf(bl_r - p_hi) > 0.03:
            _fail(failures, "%s: blunt ratio %.4f want strike_momentum_mult ratio %.4f" % [tcb, bl_r, p_hi])
        var db1: Dictionary = WeaponDamageHelper.compute_penetration(wcb, sb1, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
        var db2: Dictionary = WeaponDamageHelper.compute_penetration(wcb, sb2, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
        var mpb1: float = float(db1.get("penetration_blunt_momentum_per_area", -1.0))
        var mpb2: float = float(db2.get("penetration_blunt_momentum_per_area", -1.0))
        if mpb1 <= 0.0:
            _fail(failures, "%s: mpa_1 invalid %.4f" % [tcb, mpb1])
        var mpb_r: float = mpb2 / mpb1
        if absf(mpb_r - p_hi) > 0.03:
            _fail(failures, "%s: mpa ratio %.4f want %.4f (mpa1=%.4f mpa2=%.4f)" % [tcb, mpb_r, p_hi, mpb1, mpb2])

## Tier 5.1: **`strike_momentum_mult`** must not change **`compute_kinetic_energy_j`** (pinned **`velocity_m_s`** or
## derived **`velocity_m_s` < 0** on **SWORD** / **AXE** / **DAGGER** swing, **MACE** blunt->swing, **SPEAR** thrust),
## **SHARP** **`compute_penetration`** / **`compute_pre_armor_cut`** (pinned **`v`** or same derived-**`v`**
## **`sv_p_*`**, **`sp_p_*`**, **`mv_p_*`**, **`ax_p_*`**, **`dg_p_*`** pairs), or derived
## **`get_effective_velocity_m_s`** (`AttackInstance.velocity_m_s` < 0; **SWORD** **`oberhau`**, **AXE**
## **`diagonal_chop`**, **DAGGER** **`quick_slash`**, **MACE** **`direct_blow`**, **SPEAR** **`spear_thrust`**); pinned
## **`v`**: **`get_effective_velocity_m_s`** >= **`strike_momentum_mult`** (**SWORD** **`ai_*_p`**, **`wcx_pm`** **AXE**
## / **DAGGER**); **`strike_energy_mult`** must not change **`compute_pre_armor_blunt`** (pinned **`v`** or derived
## **`velocity_m_s` < 0** on **MACE** **`mv_e_*`**, **SPEAR** **`sp_e_*`**, **SWORD** **`sv_e_*`**, **AXE**
## **`ax_sv_e_*`**, **DAGGER** **`dg_sv_e_*`**, incl. **`target_effective_mass_kg`** reduced-mass + opts), **BLUNT**
## **`compute_penetration`** **`penetration_blunt_momentum_per_area`** (same), or derived
## **`get_effective_velocity_m_s`** (**SWORD** + **MACE** + **SPEAR** + **AXE** + **DAGGER**); pinned **`v`**:
## **`get_effective_velocity_m_s`** >= **`strike_energy_mult`** (**SWORD** **`sw_*`**, **`swx`** **AXE** / **DAGGER**)
## -  same blunt-channel >= on **MACE** **`direct_blow`** and **SWORD** / **AXE** / **DAGGER** cut swing (pinned
## **`v`**)  -  orthogonal energy vs momentum paths.
