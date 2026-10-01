class_name KinematicDeflectParryTests

extends KinematicDeliveryClosingDefenseTestBase

## Deflection + parry: deflected-line severity bind (opposite/stab), partial parry cut-to-blunt integration,
## pinned-VO misalignment penetration scaling, and striker-stamina strike KE sqrt scaling.


static func _run_kinematic_delivery_deflected_line_opposite_severity_bind(failures: PackedStringArray) -> void:
    var atk_deg: float = 0.0
    var guard_deg: float = 180.0
    var severity: float = 0.9
    var line: String = CombatConstants.get_deflected_line_from_angles(
        atk_deg, guard_deg, severity, WeaponConstants.ATTACK_TYPE_CUT, 1.0
    )
    if line != "low":
        CombatRegressionHarness._fail(
            failures, "kin_defl_opp: high vs low guard at severity %.2f want low got %s" % [severity, line]
        )
    var below: String = CombatConstants.get_deflected_line_from_angles(
        atk_deg,
        guard_deg,
        CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.05,
        WeaponConstants.ATTACK_TYPE_CUT,
        1.0
    )
    if below == "low":
        CombatRegressionHarness._fail(
            failures, "kin_defl_opp: sub-threshold severity should not bind to opposite (got low)"
        )


static func _run_kinematic_delivery_deflected_line_stab_opposite_severity_bind(failures: PackedStringArray) -> void:
    var atk_deg: float = 0.0
    var guard_deg: float = 180.0
    var stab_sev: float = CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST + 0.02
    var line_stab: String = CombatConstants.get_deflected_line_from_angles(
        atk_deg, guard_deg, stab_sev, WeaponConstants.ATTACK_TYPE_STAB, 1.0
    )
    if line_stab != "low":
        CombatRegressionHarness._fail(
            failures, "kin_defl_stab: stab at severity %.2f want low got %s" % [stab_sev, line_stab]
        )
    var cut_sev: float = CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.02
    var line_cut: String = CombatConstants.get_deflected_line_from_angles(
        atk_deg, guard_deg, cut_sev, WeaponConstants.ATTACK_TYPE_CUT, 1.0
    )
    if line_cut == "low":
        CombatRegressionHarness._fail(
            failures, "kin_defl_stab: cut below cut threshold should not bind opposite at severity %.2f" % cut_sev
        )


## Tier 5.1 (optional long-tail): **SWORD** **`thrust`** move  -  empty archetype infers thrust delivery on integration
## path.

## Tier 5.1 (optional long-tail): **SWORD** **`thrust`** move  -  empty archetype infers thrust delivery on integration
## path.


static func _run_kinematic_delivery_partial_parry_cut_to_blunt_integration_sword(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var parry_half: float = 0.5
    for cfx in CombatRegressionHarness._kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var clean: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, 1.0, arch
        )
        var partial: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, parry_half, 1.0, {}, wid, move, 1.0, arch
        )
        var pre_cut_clean: float = float(clean["pre_cut"])
        var pre_cut_part: float = float(partial["pre_cut"])
        var pre_blunt_clean: float = float(clean["pre_blunt"])
        var pre_blunt_part: float = float(partial["pre_blunt"])
        CombatRegressionHarness._free_manager(clean["mgr"] as Node)
        CombatRegressionHarness._free_manager(partial["mgr"] as Node)
        if pre_cut_part >= pre_cut_clean - 0.5:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_parry_shift_int partial should lower pre_cut (clean=%.4f part=%.4f)"
                    % [tag, pre_cut_clean, pre_cut_part]
                )
            )
        if pre_blunt_part <= pre_blunt_clean + 0.01:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_parry_shift_int partial should raise pre_blunt (clean=%.4f part=%.4f)"
                    % [tag, pre_blunt_clean, pre_blunt_part]
                )
            )


## Tier 5.1 (optional long-tail): pinned **`velocity_override`**  -  misaligned guard scales applied pens (oblique
## active); complements derived-**`v`** skip test.

## Tier 5.1 (optional long-tail): pinned **`velocity_override`**  -  misaligned guard scales applied pens (oblique
## active); complements derived-**`v`** skip test.


static func _run_kinematic_delivery_pinned_vo_misalign_scales_pen_integration(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var want_ratio: float = lerpf(
        1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    )
    for cfx in CombatRegressionHarness._kin_fixtures_with_sharp_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var aligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, 1.0, arch
        )
        var misaligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 0.0, {}, wid, move, 1.0, arch
        )
        CombatRegressionHarness._free_manager(aligned["mgr"] as Node)
        CombatRegressionHarness._free_manager(misaligned["mgr"] as Node)
        if float(misaligned["pen_sharp"]) >= float(aligned["pen_sharp"]) - 0.001:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_pin_oblique misalign should reduce pen_sharp (aligned=%.4f mis=%.4f)"
                    % [tag, float(aligned["pen_sharp"]), float(misaligned["pen_sharp"])]
                )
            )
        if absf(float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]) - want_ratio) > 0.04:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_pin_oblique pen ratio %.4f want oblique %.4f"
                    % [tag, float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]), want_ratio]
                )
            )


## Tier 5.1 (optional long-tail): assembled **`v`** stamina scale  -  low striker **`strike_ke_j`** ratio ~=
## **`stamina_vel_scale2`** (pinned **`vo`**).

## Tier 5.1 (optional long-tail): assembled **`v`** stamina scale  -  low striker **`strike_ke_j`** ratio ~=
## **`stamina_vel_scale2`** (pinned **`vo`**).


static func _run_kinematic_delivery_striker_stamina_strike_ke_matches_sqrt_stamina_scale(
    failures: PackedStringArray
) -> void:
    var st_ratio_low: float = 0.05
    var ke_full: float = KinematicDeliveryGuardMatrixTests._kin_striker_stamina_strike_ke_sample(1.0)
    var ke_low: float = KinematicDeliveryGuardMatrixTests._kin_striker_stamina_strike_ke_sample(st_ratio_low)
    if ke_full <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_stam_ke: full ke too small %.4f" % ke_full)
    # Fatigue velocity model: lerpf(FLOOR,1,pow(ratio,EXPONENT))^2 ratio. A fatigued striker's KE can drop below
    # band-minimum energy, in which case the sub-band ramp (sub_band_energy_factor) additionally scales reported
    # KE — so the expected ratio is fatigue_vel² × (f_low / f_full). Both samples here are on SWORD oberhau at
    # pinned v=11, so the factor is derived from the same weapon/move.
    var st_factor_low: float = pow(st_ratio_low, CombatConstantsStamina.FATIGUE_VELOCITY_POWER_EXPONENT)
    var vel_low: float = lerpf(CombatConstantsStamina.FATIGUE_VELOCITY_FLOOR_AT_ZERO_STAMINA, 1.0, st_factor_low)
    var want_raw_ratio: float = vel_low * vel_low
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    var arch_swing: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var f_full: float = 1.0
    var f_low: float = 1.0
    if sword != null:
        var ai_full: AttackInstance = AttackInstance.new("oberhau", 0.62)
        ai_full.archetype = arch_swing
        ai_full.velocity_m_s = 11.0
        var ai_lo: AttackInstance = AttackInstance.new("oberhau", 0.62)
        ai_lo.archetype = arch_swing
        ai_lo.velocity_m_s = 11.0 * vel_low
        f_full = WeaponDamageHelper.sub_band_energy_factor(sword, ai_full)
        f_low = WeaponDamageHelper.sub_band_energy_factor(sword, ai_lo)
    if f_full <= 0.0:
        f_full = 1.0
    var want_ratio: float = want_raw_ratio * (f_low / f_full)
    if absf(ke_low / ke_full - want_ratio) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_stam_ke: ke ratio %.4f want fatigue_vel2*subband %.4f (full=%.4f low=%.4f f_full=%.3f f_low=%.3f)"
                % [ke_low / ke_full, want_ratio, ke_full, ke_low, f_full, f_low]
            )
        )
