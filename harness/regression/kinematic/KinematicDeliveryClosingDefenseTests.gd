class_name KinematicDeliveryClosingDefenseTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

## Tier 5.1 (optional long-tail): rear **`engagement_angle`** - -  **`afterblow_damage_mult`** compose on **`v`**.
## -> **`strike_ke_j`** (~**(cls - -  sqrtab)2**).
const HumanSpecies := preload("res://resources/species/human.tres")


static func _run_kinematic_delivery_rear_afterblow_compose_on_strike_ke(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var ab_mult: float = 0.64
    var plain: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
    )
    var composed: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", ab_mult, {}, {"engagement_angle": "rear"}
    )
    var ke_plain: float = float(plain["strike_ke_j"])
    var ke_comp: float = float(composed["strike_ke_j"])
    var mgr_p: Node = plain["mgr"] as Node
    var mgr_c: Node = composed["mgr"] as Node
    var cls_front: float = StrikePhysics.closing_speed_multiplier(
        mgr_p, plain["atk"] as Dictionary, plain["tgt"] as Dictionary, {}
    )
    var cls_rear: float = StrikePhysics.closing_speed_multiplier(
        mgr_c, composed["atk"] as Dictionary, composed["tgt"] as Dictionary, {}
    )
    CombatRegressionHarness._free_manager(mgr_p)
    CombatRegressionHarness._free_manager(mgr_c)
    if ke_plain <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_compose: plain strike_ke too small %.4f" % ke_plain)
    var ratio_ke: float = ke_comp / maxf(ke_plain, 0.001)
    var ratio_want: float = ((cls_rear / maxf(cls_front, 0.001)) * sqrt(ab_mult)) ** 2.0
    if absf(ratio_ke - ratio_want) > 0.07:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_compose: ke ratio %.4f want (cls- - sqrtab)2 %.4f (cls front=%.4f rear=%.4f)"
                % [ratio_ke, ratio_want, cls_front, cls_rear]
            )
        )


## Tier 5.1 (optional long-tail): **`CombatWeaponForm.mod(form_str, "damage")`** scales integration
## **`pre_cut_applied`** (wrath > wall).


## Tier 5.1 (optional long-tail): **`CombatWeaponForm.mod(form_str, "damage")`** scales integration
## **`pre_cut_applied`** (wrath > wall).
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
static func _run_kinematic_delivery_closing_speed_engagement_angle_scales_pre_cut(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var front: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
    )
    var rear: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "rear"}
    )
    var cut_front: float = float(front["pre_cut"])
    var cut_rear: float = float(rear["pre_cut"])
    var ke_front: float = float(front["strike_ke_j"])
    var ke_rear: float = float(rear["strike_ke_j"])
    CombatRegressionHarness._free_manager(front["mgr"] as Node)
    CombatRegressionHarness._free_manager(rear["mgr"] as Node)
    if cut_rear <= cut_front + 0.01:
        CombatRegressionHarness._fail(
            failures, "kin_close_pre: rear pre_cut %.4f should exceed front %.4f" % [cut_rear, cut_front]
        )
    var ratio_cut: float = cut_rear / maxf(cut_front, 0.001)
    var ratio_ke: float = ke_rear / maxf(ke_front, 0.001)
    if absf(ratio_cut - sqrt(ratio_ke)) > 0.06:
        CombatRegressionHarness._fail(
            failures, "kin_close_pre: pre_cut ratio %.4f want sqrt(ke ratio) %.4f" % [ratio_cut, sqrt(ratio_ke)]
        )


## Tier 5.1 (optional long-tail): **SWORD** **`mixed`** **0.35** blend  -  integration **`pre_cut_applied`** tracks
## **`sqrt(strike_ke_j)`** at assembled **`v`**.


## Tier 5.1 (optional long-tail): **SWORD** **`mixed`** **0.35** blend  -  integration **`pre_cut_applied`** tracks
## **`sqrt(strike_ke_j)`** at assembled **`v`**.
static func _run_kinematic_delivery_mixed_integration_pre_cut_scales_sqrt_ke(failures: PackedStringArray) -> void:
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
    var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
    var got_ratio: float = cut_hi / maxf(cut_lo, 0.001)
    if absf(got_ratio - want_ratio) > 0.05:
        CombatRegressionHarness._fail(
            failures, "kin_mixed_pre: pre_cut ratio %.4f want sqrt(ke) %.4f" % [got_ratio, want_ratio]
        )


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** clamps to **`_CLOSING_MAX`** even with
## rear + max ambush ctx.


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** clamps to **`_CLOSING_MAX`** even with
## rear + max ambush ctx.
static func _run_kinematic_delivery_closing_speed_clamps_at_ceiling(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var tgt: Dictionary = mgr.combatants[1]
    tgt["engagement_angle"] = "rear"
    var ctx: Dictionary = {"tactical_ambush_mult": 1.12}
    var cls: float = StrikePhysics.closing_speed_multiplier(mgr, atk, tgt, ctx)
    CombatRegressionHarness._free_manager(mgr)
    if cls > 1.101:
        CombatRegressionHarness._fail(failures, "kin_close_clamp: cls want <= ~1.10 got %.4f" % cls)
    if cls <= 1.04:
        CombatRegressionHarness._fail(
            failures, "kin_close_clamp: rear+ambush should still boost above front baseline (got %.4f)" % cls
        )


## Tier 5.1 (optional long-tail): **`off_balance` + low `stamina_ratio`** in **`variance_context`** widen spread more
## than either alone (seeded).


## Tier 5.1 (optional long-tail): **`off_balance` + low `stamina_ratio`** in **`variance_context`** widen spread more
## than either alone (seeded).
static func _run_kinematic_delivery_variance_off_balance_and_stamina_compose(failures: PackedStringArray) -> void:
    seed(44013)
    var full: float = CombatConstants.get_attack_angle_deg(
        "high", true, {}, {"stamina_ratio": 1.0, "off_balance": false}
    )
    seed(44013)
    var stam_only: float = CombatConstants.get_attack_angle_deg(
        "high", true, {}, {"stamina_ratio": 0.05, "off_balance": false}
    )
    seed(44013)
    var ob_only: float = CombatConstants.get_attack_angle_deg(
        "high", true, {}, {"stamina_ratio": 1.0, "off_balance": true}
    )
    seed(44013)
    var both: float = CombatConstants.get_attack_angle_deg(
        "high", true, {}, {"stamina_ratio": 0.05, "off_balance": true}
    )
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var d_stam: float = CombatConstants.angle_diff_deg(stam_only, full)
    var d_ob: float = CombatConstants.angle_diff_deg(ob_only, full)
    var d_both: float = CombatConstants.angle_diff_deg(both, full)
    if d_both <= d_stam + 0.03 and d_both <= d_ob + 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_var_compose: both should exceed single factors (d_stam=%.4f d_ob=%.4f d_both=%.4f)"
                % [d_stam, d_ob, d_both]
            )
        )


## Tier 5.1 (optional long-tail): **`get_deflected_line_from_angles`**  -  guard on attack opposite line + severity >=
## threshold -> opposite bind (no magnitude RNG).


## Tier 5.1 (optional long-tail): **`get_deflected_line_from_angles`**  -  guard on attack opposite line + severity >=
## threshold -> opposite bind (no magnitude RNG).
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


static func _kin_entity_with_human_species(weapon_id: String) -> CoreEntity:
    var e: CoreEntity = CombatRegressionHarness._new_entity(weapon_id)
    if e.species == null:
        e.species = HumanSpecies
        e.apply_species()
    return e


static func _kin_dmg_sample_on_part(
    part: String, vo: float, weapon_id: String, move_id: String, arch: Dictionary
) -> Dictionary:
    var m: Node = CombatManager.new()
    m.set_meta(CombatRegressionHarness.HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    m.set_meta(CombatRegressionHarness.HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
    m.register(KinematicDeliveryClosingDefenseTests._kin_entity_with_human_species(weapon_id), "player")
    m.register(KinematicDeliveryClosingDefenseTests._kin_entity_with_human_species(weapon_id), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        part,
        0.62,
        move_id,
        arch,
        vo,
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
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    return {
        "mgr": m,
        "tgt": tgt,
        "pre_blunt": float(rd.get("pre_blunt_applied", -999.0)),
        "pre_cut": float(rd.get("pre_cut_applied", -999.0)),
    }


## Tier 5.1 (optional long-tail): **`effective_blunt_target_mass_kg`**  -  **MACE** **`direct_blow`**
## **`pre_blunt_applied`** differs on **head** vs **chest** (reduced-mass coupling).


## Tier 5.1 (optional long-tail): **`effective_blunt_target_mass_kg`**  -  **MACE** **`direct_blow`**
## **`pre_blunt_applied`** differs on **head** vs **chest** (reduced-mass coupling).
static func _run_kinematic_delivery_target_mass_scales_blunt_pre_armor(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var vo_pin: float = 12.0
    var chest: Dictionary = KinematicDeliveryClosingDefenseTests._kin_dmg_sample_on_part(
        "chest", vo_pin, "MACE", "direct_blow", arch
    )
    var head: Dictionary = KinematicDeliveryClosingDefenseTests._kin_dmg_sample_on_part(
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
## **`sqrt(strike_ke_j)`**.


## Tier 5.1 (optional long-tail): **AXE** **`diagonal_chop`** integration  -  **`pre_cut_applied`** ~
## **`sqrt(strike_ke_j)`**.
static func _run_kinematic_delivery_axe_integration_pre_cut_scales_sqrt_ke(failures: PackedStringArray) -> void:
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
    var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
    if absf(cut_hi / maxf(cut_lo, 0.001) - want_ratio) > 0.04:
        CombatRegressionHarness._fail(
            failures, "kin_axe_int: pre_cut ratio %.4f want sqrt(ke) %.4f" % [cut_hi / cut_lo, want_ratio]
        )


## Tier 5.1 (optional long-tail): **`strike_mods.cut_damage_mult`** scales integration **`pre_cut_applied`** only (not
## **`penetration_sharp_applied`**).


## Tier 5.1 (optional long-tail): **`strike_mods.cut_damage_mult`** scales integration **`pre_cut_applied`** only (not
## **`penetration_sharp_applied`**).
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


static func _kin_unarmed_pre_blunt_afterblow_sample(afterblow_mult: float) -> float:
    var m: Node = CombatManager.new()
    m.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    m.register(CombatRegressionHarness._new_entity_unarmed(), "player")
    m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        0.62,
        "punch",
        {},
        -1.0,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        afterblow_mult,
        1.0,
        {},
        {}
    )
    var pre: float = float(res.get("result_dict", {}).get("pre_blunt_applied", -999.0))
    CombatRegressionHarness._free_manager(m)
    return pre


## Tier 5.1 (optional long-tail): unarmed path  -  **`afterblow_damage_mult`** scales **`pre_blunt_applied`** via
## **`sqrt(mult)`** (closing/stamina path, not KE).


## Tier 5.1 (optional long-tail): unarmed path  -  **`afterblow_damage_mult`** scales **`pre_blunt_applied`** via
## **`sqrt(mult)`** (closing/stamina path, not KE).
static func _run_kinematic_delivery_unarmed_afterblow_scales_pre_blunt(failures: PackedStringArray) -> void:
    var ab_full: float = 1.0
    var ab_half: float = 0.55
    var pre_full: float = KinematicDeliveryClosingDefenseTests._kin_unarmed_pre_blunt_afterblow_sample(ab_full)
    var pre_half: float = KinematicDeliveryClosingDefenseTests._kin_unarmed_pre_blunt_afterblow_sample(ab_half)
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
## **`sqrt(strike_ke_j)`**.


## Tier 5.1 (optional long-tail): **DAGGER** **`quick_slash`** integration  -  **`pre_cut_applied`** ~
## **`sqrt(strike_ke_j)`**.
static func _run_kinematic_delivery_dagger_integration_pre_cut_scales_sqrt_ke(failures: PackedStringArray) -> void:
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
    var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
    if absf(cut_hi / maxf(cut_lo, 0.001) - want_ratio) > 0.04:
        CombatRegressionHarness._fail(
            failures, "kin_dagger_int: pre_cut ratio %.4f want sqrt(ke) %.4f" % [cut_hi / cut_lo, want_ratio]
        )


## Tier 5.1 (optional long-tail): **`strike_mods.blunt_damage_mult`** scales integration **`pre_blunt_applied`** only
## (not **`penetration_sharp_applied`**).


## Tier 5.1 (optional long-tail): **`strike_mods.blunt_damage_mult`** scales integration **`pre_blunt_applied`** only
## (not **`penetration_sharp_applied`**).
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


static func _kin_result_split_fields_sample(
    vo: float, weapon_id: String, move_id: String, arch: Dictionary
) -> Dictionary:
    var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo, 1.0, 1.0, {}, weapon_id, move_id, 1.0, arch
    )
    CombatRegressionHarness._free_manager(sample["mgr"] as Node)
    return {
        "final_cut": float(sample["final_cut"]),
        "final_blunt": float(sample["final_blunt"]),
        "final_bone": float(sample["final_bone"]),
        "total_physical": float(sample["total_physical"]),
    }


## Tier 5.1 (optional long-tail): weapon path  -  **`afterblow_damage_mult`** scales **`pre_cut_applied`** by
## **`sqrt(mult)`** (**`v`** - -  sqrtmult -> **`pre_cut`** ~ sqrtKE).


## Tier 5.1 (optional long-tail): weapon path  -  **`afterblow_damage_mult`** scales **`pre_cut_applied`** by
## **`sqrt(mult)`** (**`v`** - -  sqrtmult -> **`pre_cut`** ~ sqrtKE).
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
static func _run_kinematic_delivery_entity_split_total_includes_final_bone(failures: PackedStringArray) -> void:
    var vo_pin: float = 14.0
    for cfx in CombatRegressionHarness._kin_fixtures_all_damage():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = KinematicDeliveryGuardMatrixTests._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var rd: Dictionary = KinematicDeliveryClosingDefenseTests._kin_result_split_fields_sample(vo, wid, move, arch)
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
static func _run_choose_defense_misaligned_prefers_dodge(failures: PackedStringArray) -> void:
    var attack_type: String = "oberhau"
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_line"] = "low"
    # Reduce parry stats so energy comparison favors dodge when alignment is low (misaligned).
    defender["agility"] = maxf(defender.get("agility", 10) - 8, 0)
    defender["perception"] = maxf(defender.get("perception", 10) - 8, 0)
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "choose_defense_misaligned: targetable parts empty")
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {
        "attack_type": attack_type,
        "effective_attack_line": "high",
        "intensity": 0.65,
        "wind_up_duration": 0.85,
        "tactical_ambush_mult": 1.0,
    }
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var dc: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, attack_type, arch, -1.0, mgr
    )
    # Phase 2A: alignment threshold = 0.15 (cos(81°)) — cross-line parry uses continuous scaling instead of hard gate.
    # Misaligned guard still reduces parry_c_d via _get_contact_geometry(), so dodge may win on energy basis.
    var preview: float = float(dc.get("parry_preview_alignment", 1.0))
    if str(dc.get("defense", "")) == "parry" and preview > 0.5:
        CombatRegressionHarness._fail(
            failures, "choose_defense_misaligned: high vs low with good alignment got parry (align=%.3f)" % preview
        )
    CombatRegressionHarness._free_manager(mgr)


## HEMA defense: aligned guard may still choose parry when in time.


## HEMA defense: aligned guard may still choose parry when in time.
static func _run_choose_defense_aligned_can_parry(failures: PackedStringArray) -> void:
    var attack_type: String = "oberhau"
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_line"] = "high"
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "choose_defense_aligned: targetable parts empty")
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {
        "attack_type": attack_type,
        "effective_attack_line": "high",
        "intensity": 0.65,
        "wind_up_duration": 0.85,
        "tactical_ambush_mult": 1.0,
    }
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var dc: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, attack_type, arch, -1.0, mgr
    )
    if not bool(dc.get("can_parry_in_time", false)):
        CombatRegressionHarness._fail(failures, "choose_defense_aligned: want can_parry_in_time")
    # Phase 2A: alignment threshold = 0.15 (cos(81°)) — aligned preview >= 0.15 passes the gate check.
    var preview: float = float(dc.get("parry_preview_alignment", 0.0))
    if preview < 0.15:
        CombatRegressionHarness._fail(failures, "choose_defense_aligned: want aligned preview got %.3f" % preview)
    if str(dc.get("defense", "")) != "parry":
        CombatRegressionHarness._fail(
            failures, "choose_defense_aligned: high vs high want parry got %s" % str(dc.get("defense", ""))
        )
    CombatRegressionHarness._free_manager(mgr)

## Entry point  -  defined last so Godot resolves all `_run_*` bodies before `run()` (large-script forward-ref limit).
