class_name KinematicDeliveryPreArmorTests
extends CombatRegressionHarnessCore


## Tier 5.1: **`compute_pre_armor_cut`** scales with **`KE^CUT_DAMAGE_ENERGY_EXPONENT`** at fixed
## strength/**`arm_mod`** when **`velocity_m_s`** pins tip speed (no clamp skew)  -  **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing). **`compute_pre_armor_blunt`** rises with
## pinned speed on **MACE** **`direct_blow`** (momentum path).
static func _run_kinematic_delivery_pre_armor_cut_sqrt_ke_ratio_and_blunt_rises_with_speed(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
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
    var want_ratio: float = pow(ke_hi / ke_lo, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
    var got_ratio: float = cut_hi / cut_lo
    if absf(got_ratio - want_ratio) > 0.03:
        _fail(
            failures,
            (
                "kin_pre_armor_cut: cut ratio %.4f want ke^%.2f ratio %.4f (ke lo=%.4f hi=%.4f)"
                % [got_ratio, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_ratio, ke_lo, ke_hi]
            )
        )
    var arch_swing_cut: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    for cfx: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_pre_armor_cut_ax", "v_lo": 8.0, "v_hi": 15.0},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_pre_armor_cut_dg", "v_lo": 8.0, "v_hi": 15.0},
    ]:
        var w_c: Weapon = HarnessFixtures.get_cached_weapon(str(cfx["def"]))
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
        var want_r_c: float = pow(ke_hi_c / ke_lo_c, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
        var got_r_c: float = cut_hi_c / cut_lo_c
        if absf(got_r_c - want_r_c) > 0.03:
            _fail(
                failures,
                (
                    "%s: cut ratio %.4f want ke^%.2f ratio %.4f (ke lo=%.4f hi=%.4f)"
                    % [pfx_c, got_r_c, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_r_c, ke_lo_c, ke_hi_c]
                )
            )
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
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
## J_BASE)^PENETRATION_EXPONENT`** ×  area factor (same move, pinned **`velocity_m_s`**) on **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing); **BLUNT** returns
## **`penetration_blunt_momentum_per_area`** increasing with pinned **`v`** on **MACE** **`direct_blow`**.


## Tier 5.1: **`compute_penetration`**  -  **SHARP** **`penetration_sharp`** scales as **`(KE /
## J_BASE)^PENETRATION_EXPONENT`** ×  area factor (same move, pinned **`velocity_m_s`**) on **SWORD** **`oberhau`**,
## **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing); **BLUNT** returns
## **`penetration_blunt_momentum_per_area`** increasing with pinned **`v`** on **MACE** **`direct_blow`**.
static func _run_kinematic_delivery_penetration_sharp_ke_exponent_and_blunt_mpa_rises(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
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
        var w_p: Weapon = HarnessFixtures.get_cached_weapon(str(pfx_row["def"]))
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
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
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


## Body-coupled thrust mass: every weapon template with a STAB move gets an explicit body-transfer mass in
## **`strike_mass_kg`** (SPEAR 3.5 / MACE 2.5 / AXE 2.0 / SWORD 1.5 / DAGGER 0.28 kg). Dagger uses a much lower
## thrust mass because its short blade means the arm+shoulder drive couples differently — at v=[4,10] m/s,
## ½×0.28×v² yields [5.6, 14]J which sits correctly within the [3, 55]J audit band (unlike the old 1.0 kg that
## produced ~98J at 14 m/s, double the band cap). Mass ordering: SPEAR > MACE > AXE > SWORD >> DAGGER.


static func _run_kinematic_delivery_thrust_body_coupled_strike_mass_and_ke_rising(failures: PackedStringArray) -> void:
    var rows: Array = [
        {"def": "SWORD", "move": "thrust", "expect_m": 1.5, "v_lo": 6.0, "v_hi": 14.0, "pfx": "kin_thrust_sw"},
        {"def": "MACE", "move": "thrust", "expect_m": 2.5, "v_lo": 6.0, "v_hi": 13.0, "pfx": "kin_thrust_mc"},
        {"def": "AXE", "move": "thrust", "expect_m": 2.0, "v_lo": 4.0, "v_hi": 13.0, "pfx": "kin_thrust_ax"},
        {"def": "DAGGER", "move": "quick_thrust", "expect_m": 2.5, "v_lo": 4.0, "v_hi": 10.0, "pfx": "kin_thrust_dg"},
        {"def": "SPEAR", "move": "spear_thrust", "expect_m": 3.5, "v_lo": 5.0, "v_hi": 8.0, "pfx": "kin_thrust_sp"},
    ]
    var resolved_mass: Dictionary = {}
    for row: Dictionary in rows:
        var pfx: String = str(row["pfx"])
        var w: Weapon = HarnessFixtures.get_cached_weapon(str(row["def"]))
        if w == null:
            _fail(failures, "%s: missing %s" % [pfx, str(row["def"])])
            return
        var ai_m: AttackInstance = AttackInstance.new(str(row["move"]), 0.5)
        var m_kg: float = WeaponDamageHelper.strike_mass_kg(w, ai_m)
        if absf(m_kg - float(row["expect_m"])) > 1e-4:
            _fail(
                failures,
                "%s: strike_mass_kg %.4f want body-coupled thrust mass %.4f" % [pfx, m_kg, float(row["expect_m"])]
            )
        resolved_mass[pfx] = m_kg
        var ai_lo: AttackInstance = AttackInstance.new(str(row["move"]), 0.5)
        ai_lo.velocity_m_s = float(row["v_lo"])
        var ai_hi: AttackInstance = AttackInstance.new(str(row["move"]), 0.5)
        ai_hi.velocity_m_s = float(row["v_hi"])
        var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w, ai_lo)
        var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w, ai_hi)
        if ke_lo <= 0.01 or ke_hi <= ke_lo + 1e-4:
            _fail(failures, "%s: thrust KE should rise with v (lo=%.4f hi=%.4f)" % [pfx, ke_lo, ke_hi])
    if resolved_mass.size() != rows.size():
        return
    if float(resolved_mass["kin_thrust_sp"]) <= float(resolved_mass["kin_thrust_mc"]) + 1e-4:
        _fail(
            failures,
            (
                "kin_thrust_order: SPEAR %.4f should exceed MACE %.4f"
                % [
                    resolved_mass["kin_thrust_sp"],
                    resolved_mass["kin_thrust_mc"],
                ]
            )
        )
    if float(resolved_mass["kin_thrust_mc"]) <= float(resolved_mass["kin_thrust_ax"]) + 1e-4:
        _fail(
            failures,
            (
                "kin_thrust_order: MACE %.4f should exceed AXE %.4f"
                % [
                    resolved_mass["kin_thrust_mc"],
                    resolved_mass["kin_thrust_ax"],
                ]
            )
        )
    if float(resolved_mass["kin_thrust_ax"]) <= float(resolved_mass["kin_thrust_sw"]) + 1e-4:
        _fail(
            failures,
            (
                "kin_thrust_order: AXE %.4f should exceed SWORD %.4f"
                % [
                    resolved_mass["kin_thrust_ax"],
                    resolved_mass["kin_thrust_sw"],
                ]
            )
        )
    if float(resolved_mass["kin_thrust_dg"]) <= float(resolved_mass["kin_thrust_sw"]) + 1e-4:
        _fail(
            failures,
            (
                "kin_thrust_order: DAGGER %.4f should exceed SWORD %.4f (body-coupled arm+shoulder)"
                % [
                    resolved_mass["kin_thrust_dg"],
                    resolved_mass["kin_thrust_sw"],
                ]
            )
        )


## Thrust mass fallback: STAB contact on a weapon template with no explicit body-coupled entry in
## **`strike_mass_kg`** derives from the isolated striking-part mass × 3 (torso/shoulder drive), clamped to
## [0.5, 1.5] kg -  never the bare 0.40 kg thrust default. Locked with a synthetic weapon whose parts give a
## known blade part-mass (0.6 × 1.0 kg = 0.6 kg → expect 1.5 kg clamped) and an unknown weapon_type.


static func _run_kinetic_delivery_thrust_mass_fallback_for_unknown_templates(failures: PackedStringArray) -> void:
    var w := Weapon.new()
    w.weapon_type = "FAUX"
    w.parts = [
        {"id": "blade", "length_cm": 40.0, "mass_fraction": 0.6, "striking_for": ["stab"]},
        {"id": "handle", "length_cm": 20.0, "mass_fraction": 0.4, "striking_for": []},
    ]
    w.mass = 1.0
    var part_m: float = w.get_striking_part_mass_kg("stab")
    if absf(part_m - 0.6) > 0.02:
        _fail(failures, "kin_thrust_fallback_pre: blade part mass %.4f want ~0.6" % part_m)
    var ai: AttackInstance = AttackInstance.new("thrust", 0.5)
    var derived: float = WeaponDamageHelper.strike_mass_kg(w, ai)
    if absf(derived - 1.5) > 0.05:
        _fail(failures, "kin_thrust_fallback: derived thrust mass %.4f want clamped part*3=1.5" % derived)
    if derived <= 0.40 + 1e-4:
        _fail(failures, "kin_thrust_fallback: thrust mass %.4f fell to bare point-mass default" % derived)
    var ai_cut: AttackInstance = AttackInstance.new("oberhau", 0.5)
    var cut_m: float = WeaponDamageHelper.strike_mass_kg(w, ai_cut)
    if absf(cut_m - part_m) > 1e-4:
        _fail(
            failures, "kin_thrust_fallback: non-stab path must stay at part mass (got %.4f want %.4f)" % [cut_m, part_m]
        )


## Uniform-rod inertia: **`inertia_from_parts_kg_m2`** uses the parallel-axis theorem per segment
## (I = m·d² + (1/12)mL²), not a point mass at the COM. Locked with a two-segment synthetic parts array whose
## hand-computed rod inertia (0.7383 kg·m²) differs from the point-mass value (0.6945) by the distributed term,
## and verified the full **`inertia_about_grip_kg_m2`** path inherits it for a parts-bearing weapon.


## Uniform-rod inertia: **`inertia_from_parts_kg_m2`** uses the parallel-axis theorem per segment
## (I = m·d² + (1/12)mL²), not a point mass at the COM. Locked with a two-segment synthetic parts array whose
## hand-computed rod inertia (0.7383 kg·m²) differs from the point-mass value (0.6945) by the distributed term,
## and verified the full **`inertia_about_grip_kg_m2`** path inherits it for a parts-bearing weapon.
static func _run_kinetic_delivery_uniform_rod_inertia_parallel_axis(failures: PackedStringArray) -> void:
    var parts: Array = [
        {"id": "blade", "length_cm": 40.0, "mass_fraction": 0.6},
        {"id": "handle", "length_cm": 20.0, "mass_fraction": 0.4},
    ]
    var m_total: float = 1.0
    var got: float = WeaponSwingPhysics.inertia_from_parts_kg_m2(parts, m_total)
    # blade: m=0.6, d=max(MIN_LEVER_M(0.12), 0.6-0.2)=0.4, L=0.4 -> 0.6*0.16 + 0.6*0.16/12 = 0.096 + 0.008 = 0.104
    # handle: m=0.4, d=max(MIN_LEVER_M(0.12), 0.6-0.5)=max(0.12, 0.1)=0.12, L=0.2 -> 0.4*0.0144 + 0.4*0.04/12 = 0.00576
    # + 0.001333 = 0.007093
    var want_rod: float = 0.6 * 0.4 * 0.4 + (0.6 * 0.4 * 0.4) / 12.0 + 0.4 * 0.12 * 0.12 + (0.4 * 0.2 * 0.2) / 12.0
    if absf(got - want_rod) > 1e-4:
        _fail(failures, "kin_rod_inertia: got %.6f want parallel-axis %.6f" % [got, want_rod])
    # Point-mass-at-COM would give 0.6*0.16 + 0.4*0.0144 = 0.09576; the rod model must exceed it by the (1/12)mL² terms.
    var point_mass: float = 0.6 * 0.4 * 0.4 + 0.4 * 0.12 * 0.12
    if got <= point_mass + 1e-6:
        _fail(
            failures,
            (
                "kin_rod_inertia: rod inertia %.6f must exceed point-mass %.6f by the (1/12)mL² distributed term"
                % [got, point_mass]
            )
        )
    var w := Weapon.new()
    w.weapon_type = "FAUX"
    w.mass = m_total
    w.parts = parts.duplicate(true)
    var full: float = WeaponSwingPhysics.inertia_about_grip_kg_m2(w)
    if absf(full - want_rod) > 1e-4:
        _fail(failures, "kin_rod_inertia_full: weapon path %.6f want %.6f (no inertia_scale set)" % [full, want_rod])


## Mass-scaled band max: **`resolve_band_m_s`** scales band MAX by **`mass_scaling_factor`** = sqrt(m_ref/m)
## clamped to [0.7, 1.4] (tip speed ∝ sqrt(tau·r/I); heavier weapons swing slower), leaving band MIN unscaled
## (reaction-limited). Locked with synthetic SWORD-type weapons: reference mass → factor 1.0 (no scaling), lighter
## → faster max, heavier → slower max, and the clamp band at extreme masses. Tier C overrides are authored per-weapon
## and must NOT be re-scaled.


## Mass-scaled band max: **`resolve_band_m_s`** scales band MAX by **`mass_scaling_factor`** = sqrt(m_ref/m)
## clamped to [0.7, 1.4] (tip speed ∝ sqrt(tau·r/I); heavier weapons swing slower), leaving band MIN unscaled
## (reaction-limited). Locked with synthetic SWORD-type weapons: reference mass → factor 1.0 (no scaling), lighter
## → faster max, heavier → slower max, and the clamp band at extreme masses. Tier C overrides are authored per-weapon
## and must NOT be re-scaled.
static func _run_kinetic_delivery_mass_scaled_band_max(failures: PackedStringArray) -> void:
    var ref_mass: float = ImpactVelocityModel.MASS_SCALING_REFERENCE_KG
    var ct: String = WeaponConstants.ATTACK_TYPE_CUT
    # Reference-mass SWORD: factor 1.0, band max unchanged from the Tier-A default (16.0).
    var w_ref := Weapon.new()
    w_ref.weapon_type = "SWORD"
    w_ref.mass = ref_mass
    var f_ref: float = ImpactVelocityModel.mass_scaling_factor(w_ref)
    if absf(f_ref - 1.0) > 1e-5:
        _fail(failures, "kin_mass_band_ref: factor at ref mass %.6f want 1.0" % f_ref)
    var band_ref: Vector2 = ImpactVelocityModel.resolve_band_m_s(w_ref, ct)
    if absf(band_ref.y - 16.0) > 0.01:
        _fail(failures, "kin_mass_band_ref: SWORD cut max %.4f want unscaled 16.0" % band_ref.y)
    # Lighter weapon (0.5 kg): factor sqrt(1.3/0.5)=1.612 → clamped to 1.4; max rises, min unchanged.
    var w_light := Weapon.new()
    w_light.weapon_type = "SWORD"
    w_light.mass = 0.5
    var f_light: float = ImpactVelocityModel.mass_scaling_factor(w_light)
    if absf(f_light - ImpactVelocityModel.MASS_SCALING_MAX_FACTOR) > 1e-4:
        _fail(
            failures,
            (
                "kin_mass_band_light: factor %.4f want clamp max %.4f"
                % [f_light, ImpactVelocityModel.MASS_SCALING_MAX_FACTOR]
            )
        )
    var band_light: Vector2 = ImpactVelocityModel.resolve_band_m_s(w_light, ct)
    if absf(band_light.x - 7.5) > 0.01:
        _fail(failures, "kin_mass_band_light: min must stay unscaled %.4f want 7.5" % band_light.x)
    if band_light.y <= band_ref.y + 0.01:
        _fail(failures, "kin_mass_band_light: lighter max %.4f should exceed ref %.4f" % [band_light.y, band_ref.y])
    # Heavier weapon (3.0 kg): factor sqrt(1.3/3.0)=0.658 → clamped to 0.7; max falls below reference.
    var w_heavy := Weapon.new()
    w_heavy.weapon_type = "SWORD"
    w_heavy.mass = 3.0
    var f_heavy: float = ImpactVelocityModel.mass_scaling_factor(w_heavy)
    if absf(f_heavy - ImpactVelocityModel.MASS_SCALING_MIN_FACTOR) > 1e-4:
        _fail(
            failures,
            (
                "kin_mass_band_heavy: factor %.4f want clamp min %.4f"
                % [f_heavy, ImpactVelocityModel.MASS_SCALING_MIN_FACTOR]
            )
        )
    var band_heavy: Vector2 = ImpactVelocityModel.resolve_band_m_s(w_heavy, ct)
    if band_heavy.y >= band_ref.y - 0.01:
        _fail(failures, "kin_mass_band_heavy: heavier max %.4f should be below ref %.4f" % [band_heavy.y, band_ref.y])
    # In-range mass (1.8 kg): unscaled factor sqrt(1.3/1.8)=0.850; max = 16*0.850 within tolerance.
    var w_mid := Weapon.new()
    w_mid.weapon_type = "SWORD"
    w_mid.mass = 1.8
    var f_mid: float = ImpactVelocityModel.mass_scaling_factor(w_mid)
    var want_f_mid: float = sqrt(ref_mass / 1.8)
    if absf(f_mid - want_f_mid) > 1e-4:
        _fail(failures, "kin_mass_band_mid: factor %.6f want sqrt(1.3/1.8)=%.6f" % [f_mid, want_f_mid])
    var band_mid: Vector2 = ImpactVelocityModel.resolve_band_m_s(w_mid, ct)
    if absf(band_mid.y - 16.0 * f_mid) > 0.05:
        _fail(failures, "kin_mass_band_mid: max %.4f want 16*factor=%.4f" % [band_mid.y, 16.0 * f_mid])
    # Tier C override is authored per-weapon and must NOT be re-scaled by mass.
    var w_tier_c := Weapon.new()
    w_tier_c.weapon_type = "SWORD"
    w_tier_c.mass = 0.5
    w_tier_c.impact_velocity_bands = {ct: Vector2(8.0, 12.0)}
    var band_tc: Vector2 = ImpactVelocityModel.resolve_band_m_s(w_tier_c, ct)
    if absf(band_tc.y - 12.0) > 0.01:
        _fail(failures, "kin_mass_band_tierc: override max must stay authored %.4f want 12.0" % band_tc.y)


## Speed-dependent impact duration: **`impact_contact_time_s`** anchors the calibrated 12 ms at
## **`BLUNT_IMPACT_REFERENCE_SPEED_M_S`** and scales Δt ∝ v^-0.4 (elastic-plastic pulse narrowing), clamped to
## [5, 25] ms. Faster impacts must produce shorter contact time (higher peak pressure); slower impacts wider.
## Locked with reference-speed identity, monotonic ordering across pinned speeds, and the clamp band.


## Speed-dependent impact duration: **`impact_contact_time_s`** anchors the calibrated 12 ms at
## **`BLUNT_IMPACT_REFERENCE_SPEED_M_S`** and scales Δt ∝ v^-0.4 (elastic-plastic pulse narrowing), clamped to
## [5, 25] ms. Faster impacts must produce shorter contact time (higher peak pressure); slower impacts wider.
## Locked with reference-speed identity, monotonic ordering across pinned speeds, and the clamp band.
static func _run_kinematic_delivery_impact_contact_time_speed_dependent(failures: PackedStringArray) -> void:
    var v_ref: float = WeaponConstants.BLUNT_IMPACT_REFERENCE_SPEED_M_S
    var dt_ref: float = WeaponDamageHelper.impact_contact_time_s(v_ref)
    var want_ref: float = WeaponConstants.BLUNT_IMPACT_CONTACT_TIME_MS / 1000.0
    if absf(dt_ref - want_ref) > 1e-5:
        _fail(failures, "kin_impact_dt_ref: dt at v_ref %.6f want %.6f" % [dt_ref, want_ref])
    var speeds: Array = [4.0, 7.0, 10.0, 14.0, 20.0]
    var prev_dt: float = -1.0
    for s in speeds:
        var dt: float = WeaponDamageHelper.impact_contact_time_s(float(s))
        if prev_dt >= 0.0 and dt >= prev_dt - 1e-6:
            _fail(
                failures,
                (
                    "kin_impact_dt_monotone: dt must fall with speed (v=%.1f dt=%.6f after v_prev dt=%.6f)"
                    % [float(s), dt, prev_dt]
                )
            )
        prev_dt = dt
    var dt_fast: float = WeaponDamageHelper.impact_contact_time_s(20.0)
    var dt_slow: float = WeaponDamageHelper.impact_contact_time_s(4.0)
    if dt_fast >= want_ref or dt_slow <= want_ref:
        _fail(failures, "kin_impact_dt_order: fast %.6f must be < ref %.6f < slow %.6f" % [dt_fast, want_ref, dt_slow])
    var dt_min_band: float = WeaponDamageHelper.impact_contact_time_s(2.5)
    if dt_min_band < WeaponConstants.BLUNT_CONTACT_TIME_MIN_S - 1e-6:
        _fail(failures, "kin_impact_dt_clamp_lo: %.6f below min band" % dt_min_band)
    var dt_max_band: float = WeaponDamageHelper.impact_contact_time_s(30.0)
    if dt_max_band > WeaponConstants.BLUNT_CONTACT_TIME_MAX_S + 1e-6:
        _fail(failures, "kin_impact_dt_clamp_hi: %.6f above max band" % dt_max_band)


## Sub-band energy consistency: **`sub_band_energy_factor`** is 1.0 at/above band-min KE, ramps to the floor at
## **`SUB_BAND_MINIMUM_RATIO`**, and hard-zeros below — and it scales BOTH reported **`compute_kinetic_energy_j`**
## and pre-armor damage (cut via KE^CUT_DAMAGE_ENERGY_EXPONENT, blunt momentum linearly) so a weak strike can't
## report low energy while still dealing full tissue deformation. Locked on SWORD `oberhau` (swing) at pinned
## speeds across the ramp, with cut tracking (raw·f)^CUT_DAMAGE_ENERGY_EXPONENT and blunt tracking raw·f.


## Sub-band energy consistency: **`sub_band_energy_factor`** is 1.0 at/above band-min KE, ramps to the floor at
## **`SUB_BAND_MINIMUM_RATIO`**, and hard-zeros below — and it scales BOTH reported **`compute_kinetic_energy_j`**
## and pre-armor damage (cut via KE^CUT_DAMAGE_ENERGY_EXPONENT, blunt momentum linearly) so a weak strike can't
## report low energy while still dealing full tissue deformation. Locked on SWORD `oberhau` (swing) at pinned
## speeds across the ramp, with cut tracking (raw·f)^CUT_DAMAGE_ENERGY_EXPONENT and blunt tracking raw·f.
static func _run_kinetic_delivery_sub_band_energy_consistency(failures: PackedStringArray) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        _fail(failures, "kin_subband: missing sword")
        return
    var move_cut: String = "oberhau"
    var arch_swing: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ct: String = WeaponConstants.contact_type_for_move_id(move_cut)
    var band: Vector2 = ImpactVelocityModel.resolve_band_m_s(sword, ct)
    if band.x <= 0.0 or band.y <= band.x:
        _fail(failures, "kin_subband: invalid sword cut band %s" % str(band))
        return
    var v_full: float = (band.x + band.y) * 0.5
    ## At exactly ratio == SUB_BAND_MINIMUM_RATIO the <= check returns 0.0; use a velocity slightly above the
    ## floor so ratio > SUB_BAND_MINIMUM_RATIO and lands in the linear ramp (where factor should equal
    ## SUB_BAND_RAMP_FLOOR only at the boundary). We compute v_at_ramp_floor as the velocity that produces
    ## KE exactly at the ramp floor fraction, then add 1% margin to stay inside the ramp zone.
    var v_ramp_floor: float = band.x * sqrt(WeaponDamageHelper.SUB_BAND_MINIMUM_RATIO) * 1.01
    var v_zero: float = band.x * 0.02
    for row: Dictionary in [
        {"pfx": "kin_subband_full", "v": v_full, "want_f": 1.0},
        {"pfx": "kin_subband_ramp_floor", "v": v_ramp_floor, "want_f": WeaponDamageHelper.SUB_BAND_RAMP_FLOOR},
        {"pfx": "kin_subband_zero", "v": v_zero, "want_f": 0.0},
    ]:
        var pfx: String = str(row["pfx"])
        var want_f: float = float(row["want_f"])
        var ai: AttackInstance = AttackInstance.new(move_cut, 0.5)
        ai.archetype = arch_swing
        ai.velocity_m_s = float(row["v"])
        var f: float = WeaponDamageHelper.sub_band_energy_factor(sword, ai)
        if absf(f - want_f) > 0.02:
            _fail(failures, "%s: factor %.4f want %.4f (v=%.3f)" % [pfx, f, want_f, float(row["v"])])
        var ke_raw: float = WeaponDamageHelper._raw_kinetic_energy_j(sword, ai)
        var ke_reported: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai)
        if absf(ke_reported - ke_raw * f) > 1e-3:
            _fail(failures, "%s: reported KE %.4f want raw*factor=%.4f" % [pfx, ke_reported, ke_raw * f])
        var cut: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai, 100.0, 1.0)
        # The cut also carries a contact_factor (effective sharp width vs baseline), so the expected
        # value must include it to stay consistent with compute_pre_armor_cut.
        var contact_cm: float = maxf(
            WeaponDamageHelper._get_effective_sharp_contact_cm(sword, move_cut), WeaponConstants.MIN_CONTACT_WIDTH_CM
        )
        var contact_factor: float = minf(
            pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT),
            WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX
        )
        var want_cut_ke: float = (
            WeaponConstants.CUT_DAMAGE_KE_SCALE
            * pow(maxf(0.0, ke_raw * f), WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
            * contact_factor
        )
        if want_cut_ke > 0.5 and absf(cut / want_cut_ke - 1.0) > 0.05:
            _fail(
                failures,
                (
                    "%s: cut %.4f should track (raw*factor)^%.2f*contact=%.4f (contact_factor=%.3f)"
                    % [pfx, cut, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_cut_ke, contact_factor]
                )
            )
    var ai_hi: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_hi.archetype = arch_swing
    ai_hi.velocity_m_s = v_full
    var ai_lo: AttackInstance = AttackInstance.new(move_cut, 0.5)
    ai_lo.archetype = arch_swing
    ai_lo.velocity_m_s = v_ramp_floor
    var cut_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi, 100.0, 1.0)
    var cut_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo, 100.0, 1.0)
    if cut_hi <= 0.5 or cut_lo <= 0.0:
        _fail(failures, "kin_subband_cut_order: need positive cut hi=%.4f lo=%.4f" % [cut_hi, cut_lo])
    var f_hi: float = WeaponDamageHelper.sub_band_energy_factor(sword, ai_hi)
    var f_lo: float = WeaponDamageHelper.sub_band_energy_factor(sword, ai_lo)
    if f_lo >= f_hi - 1e-6:
        _fail(failures, "kin_subband_cut_order: floor factor %.4f must be < full factor %.4f" % [f_lo, f_hi])


## Tier 5.1 (optional long-tail): **`strike_energy_mult`** is intentionally NOT applied to KE — pure physics only
## (`½mv²` thrust, `½Iω²` swing). KE ratio between e_mult=1.0 and e_mult=N should be ~1.0 for all weapons and
## delivery types (swing, thrust, mixed). Cut damage does NOT scale with AttackInstance.strike_energy_mult either —
## it uses cut_damage_mult from StrikeRealismProfile instead.


static func _run_kinematic_delivery_strike_energy_mult_scales_ke_and_pre_armor_cut_sqrt(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
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
    # KE is pure physics — e_mult no longer scales it after the removal fix.
    if absf(ke_ratio - 1.0) > 0.02:
        _fail(failures, "kin_e_mult: ke ratio %.6f should be ~1.0 (e_mult removed from KE path)" % [ke_ratio])
    var pin_v: float = 11.0
    var arch_swing: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    for pin_fx: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_e_mult_pin_ax"},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_e_mult_pin_dg"},
    ]:
        var wp: Weapon = HarnessFixtures.get_cached_weapon(str(pin_fx["def"]))
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
        if absf(kpe_r - 1.0) > 0.02:
            _fail(failures, "%s: ke ratio %.6f should be ~1.0 (e_mult removed from KE path)" % [pfxp, kpe_r])
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
    if absf(ke_mix_ratio - 1.0) > 0.02:
        _fail(failures, "kin_e_mult_mix: ke ratio %.6f should be ~1.0 (e_mult removed from KE path)" % [ke_mix_ratio])
    for fx: Dictionary in [
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_e_mult_mix_ax"},
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_e_mult_mix_dg"},
    ]:
        var w_ex: Weapon = HarnessFixtures.get_cached_weapon(str(fx["def"]))
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
        if absf(kx_r - 1.0) > 0.02:
            _fail(failures, "%s: ke ratio %.6f should be ~1.0 (e_mult removed from KE path)" % [pfx, kx_r])


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
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
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
        {"def": "DAGGER", "move": "quick_slash", "pfx": "kin_p_mult_cb_dg", "v": 18.0},
    ]:
        var wcb: Weapon = HarnessFixtures.get_cached_weapon(str(cb["def"]))
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
## **`get_effective_velocity_m_s`** is independent of momentum/damage multipliers (pure velocity path)
## -  same blunt-channel >= on **MACE** **`direct_blow`** and **SWORD** / **AXE** / **DAGGER** cut swing (pinned
## **`v`**)  -  orthogonal energy vs momentum paths.
