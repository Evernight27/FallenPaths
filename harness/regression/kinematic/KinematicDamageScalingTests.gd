class_name KinematicDamageScalingTests

extends KinematicDeliveryClosingDefenseTestBase

## Damage-model scaling: target-mass blunt scaling, cut/blunt damage-mult scoping, unarmed afterblow pre-blunt
## scaling, afterblow pre-cut scaling, and entity split total including final bone.


static func _run_kinematic_delivery_target_mass_scales_blunt_pre_armor(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var vo_pin: float = 12.0
    var chest: Dictionary = KinematicDeliveryClosingDefenseTestBase._kin_dmg_sample_on_part(
        "chest", vo_pin, "MACE", "direct_blow", arch
    )
    var head: Dictionary = KinematicDeliveryClosingDefenseTestBase._kin_dmg_sample_on_part(
        "head", vo_pin, "MACE", "direct_blow", arch
    )
    var blunt_chest: float = float(chest["pre_blunt"])
    var blunt_head: float = float(head["pre_blunt"])
    var mass_chest: float = WeaponDamageHelper.effective_blunt_target_mass_kg(chest["tgt"] as Dictionary, "chest")
    var mass_head: float = WeaponDamageHelper.effective_blunt_target_mass_kg(head["tgt"] as Dictionary, "head")
    CombatRegressionHarness._free_manager(chest["mgr"] as Node)
    CombatRegressionHarness._free_manager(head["mgr"] as Node)
    if mass_head >= mass_chest - 0.01:
        CombatRegressionHarness._fail(
            failures, "kin_tgt_mass: head effective mass %.4f should be < chest %.4f" % [mass_head, mass_chest]
        )
    if absf(blunt_head - blunt_chest) < 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_tgt_mass: pre_blunt should differ by part (chest=%.4f head=%.4f)" % [blunt_chest, blunt_head]
        )
    if blunt_head >= blunt_chest - 0.01:
        CombatRegressionHarness._fail(
            failures,
            "kin_tgt_mass: lighter head target want lower blunt (chest=%.4f head=%.4f)" % [blunt_chest, blunt_head]
        )


## Tier 5.1 (optional long-tail): **AXE** **`diagonal_chop`** integration  -  **`pre_cut_applied`** ~
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`**.

## Tier 5.1 (optional long-tail): **AXE** **`diagonal_chop`** integration  -  **`pre_cut_applied`** ~
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`**.


static func _run_kinematic_delivery_cut_damage_mult_integration_scales_pre_cut_only(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.38
    for cfx in CombatRegressionHarness._kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, 1.0, arch
        )
        var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"cut_damage_mult": mult}, wid, move, 1.0, arch
        )
        CombatRegressionHarness._free_manager(base["mgr"] as Node)
        CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
        if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - mult) > 0.05:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_cut_dmg_mult pre_cut ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_cut"]) / float(base["pre_cut"]), mult]
                )
            )
        if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.03:
            CombatRegressionHarness._fail(
                failures, "%s: kin_cut_dmg_mult pen_sharp should ignore cut_damage_mult" % tag
            )


static func _run_kinematic_delivery_unarmed_afterblow_scales_pre_blunt(failures: PackedStringArray) -> void:
    var ab_full: float = 1.0
    var ab_half: float = 0.55
    var pre_full: float = KinematicDeliveryClosingDefenseTestBase._kin_unarmed_pre_blunt_afterblow_sample(ab_full)
    var pre_half: float = KinematicDeliveryClosingDefenseTestBase._kin_unarmed_pre_blunt_afterblow_sample(ab_half)
    if pre_full <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_unarmed_ab: full pre_blunt too small %.4f" % pre_full)
    var want_ratio: float = sqrt(ab_half)
    if absf(pre_half / pre_full - want_ratio) > 0.05:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_unarmed_ab: ratio %.4f want sqrt(ab) %.4f (full=%.4f half=%.4f)"
                % [pre_half / pre_full, want_ratio, pre_full, pre_half]
            )
        )


## Tier 5.1 (optional long-tail): **DAGGER** **`quick_slash`** integration  -  **`pre_cut_applied`** ~
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`**.

## Tier 5.1 (optional long-tail): **DAGGER** **`quick_slash`** integration  -  **`pre_cut_applied`** ~
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`**.


static func _run_kinematic_delivery_blunt_damage_mult_integration_scales_pre_blunt_only(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.28
    for cfx in CombatRegressionHarness._kin_fixtures_with_blunt_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, 1.0, arch
        )
        var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"blunt_damage_mult": mult}, wid, move, 1.0, arch
        )
        CombatRegressionHarness._free_manager(base["mgr"] as Node)
        CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
        if float(base["pre_blunt"]) <= 0.1:
            CombatRegressionHarness._fail(failures, "%s: kin_blunt_dmg_mult baseline pre_blunt too small" % tag)
        if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - mult) > 0.05:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_blunt_dmg_mult pre_blunt ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_blunt"]) / float(base["pre_blunt"]), mult]
                )
            )
        if float(base["pen_sharp"]) > 0.001:
            if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.03:
                CombatRegressionHarness._fail(
                    failures, "%s: kin_blunt_dmg_mult pen_sharp should ignore blunt_damage_mult" % tag
                )


## Tier 5.1 (optional long-tail): **`get_deflected_line_from_angles`**  -  stab contact uses lower opposite-severity
## threshold than cut.

## Tier 5.1 (optional long-tail): **`get_deflected_line_from_angles`**  -  stab contact uses lower opposite-severity
## threshold than cut.


static func _run_kinematic_delivery_afterblow_scales_pre_cut_integration(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var ab_mult: float = 0.6
    var want_ratio: float = sqrt(ab_mult)
    for cfx in CombatRegressionHarness._kin_fixtures_with_sharp_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var clean: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, 1.0, arch
        )
        var hindered: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, ab_mult, arch
        )
        CombatRegressionHarness._free_manager(clean["mgr"] as Node)
        CombatRegressionHarness._free_manager(hindered["mgr"] as Node)
        if float(clean["pre_cut"]) <= 0.5:
            CombatRegressionHarness._fail(failures, "%s: kin_ab_pre_cut baseline pre_cut too small" % tag)
        var ratio_cut: float = float(hindered["pre_cut"]) / maxf(float(clean["pre_cut"]), 0.001)
        if absf(ratio_cut - want_ratio) > 0.06:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_ab_pre_cut ratio %.4f want sqrt(ab) %.4f (clean=%.4f hind=%.4f)"
                    % [tag, ratio_cut, want_ratio, float(clean["pre_cut"]), float(hindered["pre_cut"])]
                )
            )


## Tier 5.1 (optional long-tail): **MACE** integration  -  **`blunt_contact_cm_applied`** matches
## **`WeaponDamageHelper.compute_penetration`** **BLUNT** dict.

## Tier 5.1 (optional long-tail): **MACE** integration  -  **`blunt_contact_cm_applied`** matches
## **`WeaponDamageHelper.compute_penetration`** **BLUNT** dict.


static func _run_kinematic_delivery_entity_split_total_includes_final_bone(failures: PackedStringArray) -> void:
    var vo_pin: float = 14.0
    for cfx in CombatRegressionHarness._kin_fixtures_all_damage():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var rd: Dictionary = KinematicDeliveryClosingDefenseTestBase._kin_result_split_fields_sample(
            vo, wid, move, arch
        )
        var fc: float = float(rd["final_cut"])
        var fb: float = float(rd["final_blunt"])
        var bone: float = float(rd["final_bone"])
        var total: float = float(rd["total_physical"])
        if fc < 0.0 or fb < 0.0 or bone < 0.0 or total < 0.0:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_entity_bone missing split fields (cut=%.4f blunt=%.4f bone=%.4f total=%.4f)"
                    % [tag, fc, fb, bone, total]
                )
            )
        if total + 0.02 < fc + fb + bone:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_entity_bone total %.4f < tissue+bone %.4f (cut=%.4f blunt=%.4f bone=%.4f)"
                    % [tag, total, fc + fb + bone, fc, fb, bone]
                )
            )
        if total <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            CombatRegressionHarness._fail(failures, "%s: kin_entity_bone total_physical too small %.4f" % [tag, total])

## Tier 5.1 core kinematic rows (bodies live on **`CombatRegressionHarness`** to avoid parse cycles).

## HEMA defense: misaligned guard (high atk vs low def) prefers dodge over leaky parry.
