class_name KinematicDeliveryOverrideTests

extends CombatRegressionHarnessCore

## Kinematic delivery overrides: mixed KE blend brackets for thrust/swing, and velocity-from-intensity bridges
## get_effective monotonicity.


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

## Parry recoil (physics): **`DefenseParryClash._build_parry_clash_context`** carries the incoming blow's
## **`strike_momentum_kg_ms`** into the **`parry_clash_context`** so the parry-deflection impulse model can read it.
## (Previously only KE/velocity were copied, leaving the momentum-based deflection/recoil dead.)
