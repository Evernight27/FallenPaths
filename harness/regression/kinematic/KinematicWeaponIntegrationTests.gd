class_name KinematicWeaponIntegrationTests

extends KinematicDeliveryClosingDefenseTestBase

## Weapon-archetype integration: weapon-form damage scaling, mixed-archetype KE scaling, per-weapon pre-cut KE
## scaling (axe/dagger), mace blunt contact, and empty-arch sword thrust delivery inference.


static func _run_kinematic_delivery_weapon_form_damage_scales_pre_cut_integration(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mgr_a: Node = CombatManager.new()
    mgr_a.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    mgr_a.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_a.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_a.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk_a: Dictionary = mgr_a.combatants[0]
    var tgt_a: Dictionary = mgr_a.combatants[1]
    atk_a[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = "wrath"
    var res_a: Dictionary = AttackResolver.compute_and_apply_damage(
        mgr_a,
        CombatantEntityAccess.id_int(atk_a),
        CombatantEntityAccess.id_int(tgt_a),
        atk_a,
        tgt_a,
        "chest",
        0.62,
        "oberhau",
        {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING},
        vo_pin,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        1.0,
        1.0,
        {},
        {}
    )
    var cut_agg: float = float(res_a.get("result_dict", {}).get("pre_cut_applied", -1.0))
    CombatRegressionHarness._free_manager(mgr_a)
    var mgr_d: Node = CombatManager.new()
    mgr_d.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    mgr_d.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_d.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk_d: Dictionary = mgr_d.combatants[0]
    var tgt_d: Dictionary = mgr_d.combatants[1]
    atk_d[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = "wall"
    var res_d: Dictionary = AttackResolver.compute_and_apply_damage(
        mgr_d,
        CombatantEntityAccess.id_int(atk_d),
        CombatantEntityAccess.id_int(tgt_d),
        atk_d,
        tgt_d,
        "chest",
        0.62,
        "oberhau",
        {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING},
        vo_pin,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        1.0,
        1.0,
        {},
        {}
    )
    var cut_def: float = float(res_d.get("result_dict", {}).get("pre_cut_applied", -1.0))
    CombatRegressionHarness._free_manager(mgr_d)
    var stance_agg: float = CombatWeaponForm.mod(CombatWeaponForm.FORM_WRATH, "damage")
    var stance_def: float = CombatWeaponForm.mod(CombatWeaponForm.FORM_WALL, "damage")
    if cut_agg <= 0.5 or cut_def <= 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_stance: pre_cut too small (agg=%.4f def=%.4f)" % [cut_agg, cut_def]
        )
    if cut_agg <= cut_def + 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_stance: aggressive pre_cut %.4f should exceed defensive %.4f" % [cut_agg, cut_def]
        )
    if absf(cut_agg / cut_def - stance_agg / stance_def) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            "kin_stance: pre_cut ratio %.4f want stance ratio %.4f" % [cut_agg / cut_def, stance_agg / stance_def]
        )


## Tier 5.1 (optional long-tail): rear **`engagement_angle`** raises integration **`pre_cut_applied`**
## (~sqrt**`strike_ke_j`** ratio).

## Tier 5.1 (optional long-tail): rear **`engagement_angle`** raises integration **`pre_cut_applied`**
## (~sqrt**`strike_ke_j`** ratio).


static func _run_kinematic_delivery_mixed_integration_pre_cut_scales_ke_pow(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var arch: Dictionary = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
        "kinematic_mixed_blend": 0.35,
    }
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
    )
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin * 1.28, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
    )
    var ke_lo: float = float(lo["strike_ke_j"])
    var ke_hi: float = float(hi["strike_ke_j"])
    var cut_lo: float = float(lo["pre_cut"])
    var cut_hi: float = float(hi["pre_cut"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if ke_hi <= ke_lo + 1e-4 or cut_hi <= cut_lo + 1e-4:
        CombatRegressionHarness._fail(failures, "kin_mixed_pre: need rising ke/pre_cut")
    var want_ratio: float = pow(ke_hi / maxf(ke_lo, 0.001), WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
    var got_ratio: float = cut_hi / maxf(cut_lo, 0.001)
    if absf(got_ratio - want_ratio) > 0.05:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_mixed_pre: pre_cut ratio %.4f want ke^%.2f %.4f"
                % [got_ratio, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_ratio]
            )
        )


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** clamps to **`_CLOSING_MAX`** even with
## rear + max ambush ctx.

## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** clamps to **`_CLOSING_MAX`** even with
## rear + max ambush ctx.


static func _run_kinematic_delivery_axe_integration_pre_cut_scales_ke_pow(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        9.0, 1.0, 1.0, {}, "AXE", "diagonal_chop", 1.0, arch
    )
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        14.0, 1.0, 1.0, {}, "AXE", "diagonal_chop", 1.0, arch
    )
    var ke_lo: float = float(lo["strike_ke_j"])
    var ke_hi: float = float(hi["strike_ke_j"])
    var cut_lo: float = float(lo["pre_cut"])
    var cut_hi: float = float(hi["pre_cut"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if ke_hi <= ke_lo + 1e-4 or cut_hi <= cut_lo + 1e-4:
        CombatRegressionHarness._fail(failures, "kin_axe_int: need rising ke/pre_cut")
    var want_ratio: float = pow(ke_hi / maxf(ke_lo, 0.001), WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
    if absf(cut_hi / maxf(cut_lo, 0.001) - want_ratio) > 0.04:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_axe_int: pre_cut ratio %.4f want ke^%.2f %.4f"
                % [cut_hi / cut_lo, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_ratio]
            )
        )


## Tier 5.1 (optional long-tail): **`strike_mods.cut_damage_mult`** scales integration **`pre_cut_applied`** only (not
## **`penetration_sharp_applied`**).

## Tier 5.1 (optional long-tail): **`strike_mods.cut_damage_mult`** scales integration **`pre_cut_applied`** only (not
## **`penetration_sharp_applied`**).


static func _run_kinematic_delivery_dagger_integration_pre_cut_scales_ke_pow(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        10.0, 1.0, 1.0, {}, "DAGGER", "quick_slash", 1.0, arch
    )
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        18.0, 1.0, 1.0, {}, "DAGGER", "quick_slash", 1.0, arch
    )
    var ke_lo: float = float(lo["strike_ke_j"])
    var ke_hi: float = float(hi["strike_ke_j"])
    var cut_lo: float = float(lo["pre_cut"])
    var cut_hi: float = float(hi["pre_cut"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if ke_hi <= ke_lo + 1e-4 or cut_hi <= cut_lo + 1e-4:
        CombatRegressionHarness._fail(failures, "kin_dagger_int: need rising ke/pre_cut")
    var want_ratio: float = pow(ke_hi / maxf(ke_lo, 0.001), WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
    if absf(cut_hi / maxf(cut_lo, 0.001) - want_ratio) > 0.04:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_dagger_int: pre_cut ratio %.4f want ke^%.2f %.4f"
                % [cut_hi / cut_lo, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_ratio]
            )
        )


## Tier 5.1 (optional long-tail): **`strike_mods.blunt_damage_mult`** scales integration **`pre_blunt_applied`** only
## (not **`penetration_sharp_applied`**).

## Tier 5.1 (optional long-tail): **`strike_mods.blunt_damage_mult`** scales integration **`pre_blunt_applied`** only
## (not **`penetration_sharp_applied`**).


static func _run_kinematic_delivery_mace_blunt_contact_cm_matches_helper_integration(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 12.0
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
    )
    var m: Node = sample["mgr"] as Node
    var atk: Dictionary = sample["atk"] as Dictionary
    var tgt: Dictionary = sample["tgt"] as Dictionary
    var weapon: Weapon = CombatantEntityAccess.get_weapon(atk) as Weapon
    var ai: AttackInstance = AttackInstance.new("direct_blow", 0.62)
    ai.archetype = arch
    ai.velocity_m_s = vo_pin
    var v_asm: float = CombatRegressionHarness._kin_expected_damage_velocity_m_s(
        m, atk, tgt, 0.62, arch, "direct_blow", vo_pin, 1.0, {}
    )
    ai.velocity_m_s = v_asm
    var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest")
    var pen_blunt: Dictionary = WeaponDamageHelper.compute_penetration(
        weapon, ai, WeaponConstants.DAMAGE_TYPE_BLUNT, {"target_effective_mass_kg": target_mass}
    )
    var want_bc: float = float(pen_blunt.get("blunt_contact_cm", -1.0))
    var got_bc: float = float(sample["blunt_contact_cm"])
    CombatRegressionHarness._free_manager(m)
    if want_bc <= 0.0:
        CombatRegressionHarness._fail(failures, "kin_mace_bc: helper blunt_contact_cm invalid %.4f" % want_bc)
    if absf(got_bc / want_bc - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            "kin_mace_bc: ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)" % [got_bc / want_bc, got_bc, want_bc, v_asm]
        )


## Tier 5.1 (optional long-tail): **`take_damage_split`** result  -  **`total_physical`** = **`final_cut`** +
## **`final_blunt`** + **`final_bone`**.

## Tier 5.1 (optional long-tail): **`take_damage_split`** result  -  **`total_physical`** = **`final_cut`** +
## **`final_blunt`** + **`final_bone`**.


static func _run_kinematic_delivery_empty_arch_sword_thrust_infers_delivery(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var move_id: String = "thrust"
    if WeaponDamageHelper.kinematic_delivery({}, move_id) != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
        CombatRegressionHarness._fail(failures, "kin_infer_sword: empty arch + stab want thrust")
    var explicit: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", move_id, 1.0, {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    )
    var mgr: Node = CombatManager.new()
    mgr.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var tgt: Dictionary = mgr.combatants[1]
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        mgr,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        0.62,
        move_id,
        {},
        vo_pin,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        1.0,
        1.0,
        {},
        {}
    )
    var ke_infer: float = float(res.get("result_dict", {}).get("strike_ke_j_applied", -999.0))
    CombatRegressionHarness._free_manager(mgr)
    CombatRegressionHarness._free_manager(explicit["mgr"] as Node)
    if absf(ke_infer / float(explicit["strike_ke_j"]) - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_infer_sword: strike_ke ratio %.4f (infer=%.4f explicit=%.4f)"
                % [ke_infer / float(explicit["strike_ke_j"]), ke_infer, float(explicit["strike_ke_j"])]
            )
        )

## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` >= 0**)  -  **`pre_blunt_applied`** rises,
## **`pre_cut_applied`** falls  -  **SWORD** / **AXE** / **DAGGER**.

## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` >= 0**)  -  **`pre_blunt_applied`** rises,
## **`pre_cut_applied`** falls  -  **SWORD** / **AXE** / **DAGGER**.
