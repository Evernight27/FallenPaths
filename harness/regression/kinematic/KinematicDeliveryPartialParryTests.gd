class_name KinematicDeliveryPartialParryTests
extends CombatRegressionHarnessCore


static func _kin_fixtures_all_damage() -> Array:
    var out: Array = _kin_fixtures_with_sharp_pen()
    out.append_array(_kin_fixtures_blunt())
    return out


static func _kin_arch_for_move(move_id: String) -> Dictionary:
    if move_id == "spear_thrust" or move_id == "thrust":
        return {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    return {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}


## Pinned **`velocity_override`** for kinematic fixture rows (optional **`vo`** on **`_kin_fixtures_*`** dicts).


## Pinned **`velocity_override`** for kinematic fixture rows (optional **`vo`** on **`_kin_fixtures_*`** dicts).
static func _kin_fixture_vo(cfx: Dictionary, default_vo: float) -> float:
    return float(cfx.get("vo", default_vo))


## One **`compute_and_apply_damage`** sample with harness meta exposing pens + **`strike_ke_j`** +
## **`blunt_contact_cm`** (+ pre-armor when kinematics meta set).


## One **`compute_and_apply_damage`** sample with harness meta exposing pens + **`strike_ke_j`** +
## **`blunt_contact_cm`** (+ pre-armor when kinematics meta set).
static func _kin_dmg_integration_sample(
    vo: float,
    parry_r: float,
    align: float,
    strike_mods: Dictionary,
    weapon_id: String = "SWORD",
    move_id: String = "oberhau",
    afterblow_mult: float = 1.0,
    arch_override: Dictionary = {},
    tgt_overrides: Dictionary = {},
    tgt_chest_armor_id: String = "",
    strike_physics_ctx: Dictionary = {}
) -> Dictionary:
    var intensity: float = 0.62
    var arch: Dictionary = arch_override
    if arch.is_empty():
        arch = (
            {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
            if move_id == "spear_thrust"
            else {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        )
    var m: Node = _MgrScript.new()
    m.set_meta(_HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
    m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    m.register(_new_entity(weapon_id), "player")
    var tgt_ent: CoreEntity = _new_entity(weapon_id)
    if not tgt_chest_armor_id.is_empty():
        var ap: Variant = _ArmorPiece.create_from_definition(tgt_chest_armor_id)
        if ap != null:
            tgt_ent.equip_armor("chest", ap)
    m.register(tgt_ent, "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    _harness_reset_combatants_form_balanced(m)
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    for ok in tgt_overrides:
        tgt[ok] = tgt_overrides[ok]
    var res: Dictionary = _AttackResolver.compute_and_apply_damage(
        m,
        _EntityAccess.id_int(atk),
        _EntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        intensity,
        move_id,
        arch,
        vo,
        1.0,
        1.0,
        -1.0,
        -1.0,
        parry_r,
        afterblow_mult,
        align,
        strike_mods,
        strike_physics_ctx
    )
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    return {
        "mgr": m,
        "atk": atk,
        "tgt": tgt,
        "intensity": intensity,
        "arch": arch,
        "move_id": move_id,
        "weapon_id": weapon_id,
        "afterblow_mult": afterblow_mult,
        "strike_physics_ctx": strike_physics_ctx,
        "pen_sharp": float(rd.get("penetration_sharp_applied", -999.0)),
        "pen_blunt_mpa": float(rd.get("penetration_blunt_mpa_applied", -999.0)),
        "strike_ke_j": float(rd.get("strike_ke_j_applied", -999.0)),
        "blunt_contact_cm": float(rd.get("blunt_contact_cm_applied", -999.0)),
        "pre_cut": float(rd.get("pre_cut_applied", -999.0)),
        "pre_blunt": float(rd.get("pre_blunt_applied", -999.0)),
        "final_cut": float(rd.get("final_cut", -999.0)),
        "final_blunt": float(rd.get("final_blunt", -999.0)),
        "final_bone": float(rd.get("final_bone", -999.0)),
        "total_physical": float(rd.get("total_physical", -999.0)),
        "mechanical_post_armor": float(rd.get("mechanical_post_armor", -999.0)),
    }


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** exposed **`strike_ke_j_applied`** matches
## **`compute_kinetic_energy_j`** at assembled **`v`**; **`blunt_contact_cm_applied`** matches **`compute_penetration`**
## **BLUNT** dict (same armor opts as resolver).


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** exposed **`strike_ke_j_applied`** matches
## **`compute_kinetic_energy_j`** at assembled **`v`**; **`blunt_contact_cm_applied`** matches **`compute_penetration`**
## **BLUNT** dict (same armor opts as resolver).
static func _run_kinematic_delivery_compute_damage_strike_ke_and_blunt_contact_exposed(
    failures: PackedStringArray
) -> void:
    var move_id: String = "oberhau"
    var vo_pin: float = 11.0
    var sample: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var m: Node = sample["mgr"] as Node
    var atk: Dictionary = sample["atk"] as Dictionary
    var tgt: Dictionary = sample["tgt"] as Dictionary
    var intensity: float = float(sample["intensity"])
    var arch: Dictionary = sample["arch"] as Dictionary
    var v_asm: float = _kin_expected_damage_velocity_m_s(m, atk, tgt, intensity, arch, move_id, vo_pin, 1.0)
    var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
    if weapon == null:
        _fail(failures, "kin_dmg_kin_exposed: missing weapon")
        _free_manager(m)
        return
    var ai: AttackInstance = AttackInstance.new(move_id, intensity)
    ai.archetype = arch
    ai.velocity_m_s = v_asm
    var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai)
    var ke_got: float = float(sample["strike_ke_j"])
    if ke_want <= 0.5:
        _fail(failures, "kin_dmg_kin_exposed: ke_want too small %.4f" % ke_want)
    elif absf(ke_got / ke_want - 1.0) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_kin_exposed: strike_ke_j ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)"
                % [ke_got / ke_want, ke_got, ke_want, v_asm]
            )
        )
    var pen_sharp_raw: float = float(
        WeaponDamageHelper.compute_penetration(weapon, ai, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var blunt_opts: Dictionary = {
        "pen_sharp_mm": pen_sharp_raw,
        "target_effective_mass_kg": WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest"),
    }
    var tgt_n: Node = _EntityAccess.scene_node(tgt)
    _EntityAccess.apply_armor_sharp_resistance_to_blunt_opts(blunt_opts, tgt, "chest")
    var bc_want: float = float(
        WeaponDamageHelper.compute_penetration(weapon, ai, WeaponConstants.DAMAGE_TYPE_BLUNT, blunt_opts).get(
            "blunt_contact_cm", -1.0
        )
    )
    var bc_got: float = float(sample["blunt_contact_cm"])
    if bc_want <= 0.0:
        _fail(failures, "kin_dmg_kin_exposed: blunt_contact_cm want > 0 got %.4f" % bc_want)
    elif absf(bc_got - bc_want) > 0.0001:
        _fail(failures, "kin_dmg_kin_exposed: blunt_contact_cm want %.4f got %.4f" % [bc_want, bc_got])
    if float(sample["pen_sharp"]) <= 0.001:
        _fail(failures, "kin_dmg_kin_exposed: pen_sharp_applied missing/too small")
    _free_manager(m)


## Tier 5.1 (optional long-tail): both angles in **`alignment_context`** -> continuous cos(theta); **`wobble_context`**
## ignored.


## Tier 5.1 (optional long-tail): both angles in **`alignment_context`** -> continuous cos(theta); **`wobble_context`**
## ignored.
static func _run_kinematic_delivery_alignment_both_angles_ignores_wobble(failures: PackedStringArray) -> void:
    var atk_deg: float = 30.0
    var guard_deg: float = 45.0
    var both_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var stable: float = CombatConstants.get_line_alignment_with_deflect("high", {}, both_ctx, {"parry_readiness": 1.0})
    seed(44002)
    var wobbled: float = CombatConstants.get_line_alignment_with_deflect("high", {}, both_ctx, {"parry_readiness": 0.0})
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var exp: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
    )
    if absf(stable - exp) > 0.0001:
        _fail(failures, "kin_align_wobble_both: stable want %.6f got %.6f" % [exp, stable])
    if absf(wobbled - stable) > 0.0001:
        _fail(
            failures,
            (
                "kin_align_wobble_both: wobble must not change both-angle align (stable=%.6f wobbled=%.6f)"
                % [stable, wobbled]
            )
        )


## Tier 5.1 (optional long-tail): attack-angle-only branch uses **`get_guard_angle_deg`** wobble  -  low
## **`parry_readiness`** changes alignment vs readiness **1**.


## Tier 5.1 (optional long-tail): attack-angle-only branch uses **`get_guard_angle_deg`** wobble  -  low
## **`parry_readiness`** changes alignment vs readiness **1**.
static func _run_kinematic_delivery_attack_angle_only_wobble_changes_alignment(failures: PackedStringArray) -> void:
    var defender: Dictionary = {"guard_line": "high"}
    var atk_only: Dictionary = {"attack_angle_deg": 0.0}
    var stable: float = CombatConstants.get_line_alignment_with_deflect(
        "right", defender, atk_only, {"parry_readiness": 1.0}
    )
    seed(44003)
    var wobbled: float = CombatConstants.get_line_alignment_with_deflect(
        "right", defender, atk_only, {"parry_readiness": 0.0}
    )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var g_stable: float = CombatConstants.get_guard_angle_deg(defender, {"parry_readiness": 1.0})
    var exp_stable: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(0.0, g_stable)
    )
    if absf(stable - exp_stable) > 0.0001:
        _fail(failures, "kin_align_wobble_atk: stable want %.6f got %.6f" % [exp_stable, stable])
    if absf(wobbled - stable) < 0.0001:
        _fail(
            failures,
            "kin_align_wobble_atk: readiness 0 should change align (stable=%.6f wobbled=%.6f)" % [stable, wobbled]
        )


## Tier 5.1 (optional long-tail): partial parry scales applied pens but not assembled **`strike_ke_j`** (pinned
## **`velocity_override`**).


## Tier 5.1 (optional long-tail): partial parry scales applied pens but not assembled **`strike_ke_j`** (pinned
## **`velocity_override`**).
static func _run_kinematic_delivery_partial_parry_strike_ke_unchanged_pen_scaled(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var full: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var half: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {})
    var ke_full: float = float(full["strike_ke_j"])
    var ke_half: float = float(half["strike_ke_j"])
    var pen_full: float = float(full["pen_sharp"])
    var pen_half: float = float(half["pen_sharp"])
    _free_manager(full["mgr"] as Node)
    _free_manager(half["mgr"] as Node)
    if ke_full <= 0.5:
        _fail(failures, "kin_partial_parry: ke_full too small %.4f" % ke_full)
    if absf(ke_half / ke_full - 1.0) > 0.02:
        _fail(failures, "kin_partial_parry: strike_ke_j should ignore parry (full=%.4f half=%.4f)" % [ke_full, ke_half])
    if pen_half >= pen_full - 0.0001:
        _fail(failures, "kin_partial_parry: pen_sharp should drop (full=%.4f half=%.4f)" % [pen_full, pen_half])
    var want_ratio: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    want_ratio = lerpf(1.0, want_ratio, 0.5)
    if absf(pen_half / pen_full - want_ratio) > 0.03:
        _fail(failures, "kin_partial_parry: pen ratio %.4f want %.4f" % [pen_half / pen_full, want_ratio])


static func _kin_expected_pre_armor_cut_blunt(
    weapon: Weapon,
    atk: Dictionary,
    tgt: Dictionary,
    move_id: String,
    intensity: float,
    arch: Dictionary,
    v_m_s: float,
    parry_r: float,
    strike_mods: Dictionary
) -> Vector2:
    var ai: AttackInstance = AttackInstance.new(move_id, intensity)
    ai.archetype = arch
    ai.velocity_m_s = v_m_s
    ai.strike_energy_mult = float(strike_mods.get("strike_energy_mult", 1.0))
    ai.strike_momentum_mult = float(strike_mods.get("strike_momentum_mult", 1.0))
    var atk_n: Node = _EntityAccess.scene_node(atk)
    var arm_mod: float = _EntityAccess.get_attack_damage_modifier(atk)
    var atk_str: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
    var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest")
    var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, move_id, arch)
    if weapon.get_contact_type(move_id) == WeaponConstants.ATTACK_TYPE_CUT and v_m_s >= 0.0 and parry_r < 1.0:
        var redirect: float = CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT * (1.0 - parry_r)
        cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect)
    var pre_cut: float = (
        WeaponDamageHelper.compute_pre_armor_cut(weapon, ai, atk_str, arm_mod)
        * cut_ratio
        * float(strike_mods.get("cut_damage_mult", 1.0))
    )
    var pre_blunt: float = WeaponDamageHelper.compute_blunt_slip_pre_armor(
        weapon, ai, atk_str, arm_mod, cut_ratio, target_mass, float(strike_mods.get("blunt_damage_mult", 1.0))
    )
    var WF := preload("res://combat/CombatWeaponForm.gd")
    var stance_mult: float = WF.mod(_EntityAccess.form_str(atk), "damage")
    return Vector2(pre_cut * stance_mult, pre_blunt * stance_mult)


## Tier 5.1 (optional long-tail): exposed **`pre_cut_applied`** / **`pre_blunt_applied`** match **`WeaponDamageHelper`**
## at assembled **`v`** (incl. parry cut->blunt shift + stance).


## Tier 5.1 (optional long-tail): exposed **`pre_cut_applied`** / **`pre_blunt_applied`** match **`WeaponDamageHelper`**
## at assembled **`v`** (incl. parry cut->blunt shift + stance).
static func _run_kinematic_delivery_compute_damage_pre_armor_matches_helper_at_assembled_v(
    failures: PackedStringArray
) -> void:
    var move_id: String = "oberhau"
    var vo_pin: float = 11.0
    var intensity: float = 0.62
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    for case in [
        {"parry_r": 1.0, "label": "clean"},
        {"parry_r": 0.5, "label": "partial_parry"},
    ]:
        var sample: Dictionary = _kin_dmg_integration_sample(vo_pin, float(case["parry_r"]), 1.0, {})
        var m: Node = sample["mgr"] as Node
        var atk: Dictionary = sample["atk"] as Dictionary
        var tgt: Dictionary = sample["tgt"] as Dictionary
        var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
        if weapon == null:
            _fail(failures, "kin_pre_armor: missing weapon (%s)" % case["label"])
            _free_manager(m)
            return
        var v_asm: float = _kin_expected_damage_velocity_m_s(m, atk, tgt, intensity, arch, move_id, vo_pin, 1.0)
        var want: Vector2 = _kin_expected_pre_armor_cut_blunt(
            weapon, atk, tgt, move_id, intensity, arch, v_asm, float(case["parry_r"]), {}
        )
        var got_cut: float = float(sample["pre_cut"])
        var got_blunt: float = float(sample["pre_blunt"])
        if got_cut < 0.0 or got_blunt < 0.0:
            _fail(failures, "kin_pre_armor: missing pre_armor meta (%s)" % case["label"])
        elif absf(got_cut / maxf(want.x, 0.001) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "kin_pre_armor: %s pre_cut ratio %.4f (got=%.4f want=%.4f)"
                    % [case["label"], got_cut / want.x, got_cut, want.x]
                )
            )
        elif absf(got_blunt / maxf(want.y, 0.001) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "kin_pre_armor: %s pre_blunt ratio %.4f (got=%.4f want=%.4f)"
                    % [case["label"], got_blunt / want.y, got_blunt, want.y]
                )
            )
        _free_manager(m)


## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` >= 0**) shifts
## **`PARRY_CUT_TO_BLUNT_SHIFT`**  -  **`pre_blunt_applied`** rises vs clean parry; **`pre_cut_applied`** falls.


## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` >= 0**) shifts
## **`PARRY_CUT_TO_BLUNT_SHIFT`**  -  **`pre_blunt_applied`** rises vs clean parry; **`pre_cut_applied`** falls.
static func _run_kinematic_delivery_partial_parry_cut_to_blunt_shift(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {})
    var pre_cut_clean: float = float(clean["pre_cut"])
    var pre_cut_part: float = float(partial["pre_cut"])
    var pre_blunt_clean: float = float(clean["pre_blunt"])
    var pre_blunt_part: float = float(partial["pre_blunt"])
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if pre_cut_clean <= 0.1 or pre_blunt_clean < 0.0:
        _fail(
            failures,
            "kin_cut_blunt_shift: clean pre_armor invalid cut=%.4f blunt=%.4f" % [pre_cut_clean, pre_blunt_clean]
        )
    if pre_cut_part >= pre_cut_clean - 0.01:
        _fail(
            failures,
            (
                "kin_cut_blunt_shift: partial parry should reduce pre_cut (clean=%.4f partial=%.4f)"
                % [pre_cut_clean, pre_cut_part]
            )
        )
    if pre_blunt_part <= pre_blunt_clean + 0.01:
        _fail(
            failures,
            (
                "kin_cut_blunt_shift: partial parry should raise pre_blunt (clean=%.4f partial=%.4f)"
                % [pre_blunt_clean, pre_blunt_part]
            )
        )
    var share_clean: float = pre_cut_clean / maxf(pre_cut_clean + pre_blunt_clean, 0.001)
    var share_part: float = pre_cut_part / maxf(pre_cut_part + pre_blunt_part, 0.001)
    if share_part >= share_clean - 0.01:
        _fail(
            failures, "kin_cut_blunt_shift: cut share should drop (clean=%.4f partial=%.4f)" % [share_clean, share_part]
        )


## Tier 5.1 (optional long-tail): **`velocity_override` < 0**  -  partial parry does not apply
## **`PARRY_CUT_TO_BLUNT_SHIFT`** (pre-armor mix unchanged; pens already >= oblique).


## Tier 5.1 (optional long-tail): **`velocity_override` < 0**  -  partial parry does not apply
## **`PARRY_CUT_TO_BLUNT_SHIFT`** (pre-armor mix unchanged; pens already >= oblique).
static func _run_kinematic_delivery_derived_velocity_no_cut_to_blunt_shift_on_partial_parry(
    failures: PackedStringArray
) -> void:
    var clean: Dictionary = _kin_dmg_integration_sample(-1.0, 1.0, 1.0, {})
    var partial: Dictionary = _kin_dmg_integration_sample(-1.0, 0.5, 1.0, {})
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_derived_no_shift: pre_cut should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_cut"]), float(partial["pre_cut"])]
            )
        )
    if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_derived_no_shift: pre_blunt should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
            )
        )


## Tier 5.1 (optional long-tail): misaligned guard (**`alignment` 0**, full parry) scales pens via oblique factor but
## not **`pre_cut_applied`** / **`pre_blunt_applied`** (pinned **`vo`**).


## Tier 5.1 (optional long-tail): misaligned guard (**`alignment` 0**, full parry) scales pens via oblique factor but
## not **`pre_cut_applied`** / **`pre_blunt_applied`** (pinned **`vo`**).
static func _run_kinematic_delivery_misaligned_guard_scales_pen_not_pre_armor(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var aligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var misaligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 0.0, {})
    _free_manager(aligned["mgr"] as Node)
    _free_manager(misaligned["mgr"] as Node)
    if absf(float(aligned["pre_cut"]) - float(misaligned["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_misalign: pre_cut should be unchanged (aligned=%.4f misaligned=%.4f)"
                % [float(aligned["pre_cut"]), float(misaligned["pre_cut"])]
            )
        )
    if absf(float(aligned["pre_blunt"]) - float(misaligned["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_misalign: pre_blunt should be unchanged (aligned=%.4f misaligned=%.4f)"
                % [float(aligned["pre_blunt"]), float(misaligned["pre_blunt"])]
            )
        )
    var want_pen_ratio: float = lerpf(
        1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    )
    var pen_ratio: float = float(misaligned["pen_sharp"]) / maxf(float(aligned["pen_sharp"]), 0.001)
    if absf(pen_ratio - want_pen_ratio) > 0.03:
        _fail(failures, "kin_misalign: pen_sharp ratio %.4f want %.4f" % [pen_ratio, want_pen_ratio])


## Tier 5.1 (optional long-tail): **`get_attack_path`** unknown guard line falls back to **`ATTACK_PATHS[attack_line]`**
## (not **`ATTACK_PATHS_BY_GUARD`**).


## Tier 5.1 (optional long-tail): **`get_attack_path`** unknown guard line falls back to **`ATTACK_PATHS[attack_line]`**
## (not **`ATTACK_PATHS_BY_GUARD`**).
static func _run_kinematic_delivery_get_attack_path_fallback_to_attack_paths(failures: PackedStringArray) -> void:
    var by_guard: Array = CombatConstants.get_attack_path("high", "low")
    var fallback: Array = CombatConstants.get_attack_path("high", "__no_such_guard__")
    var want: Array = CombatConstants.ATTACK_PATHS.get("high", CombatConstants.ATTACK_PATH_HIGH)
    if fallback.is_empty():
        _fail(failures, "kin_attack_path: fallback path empty")
    if str(fallback) != str(want):
        _fail(failures, "kin_attack_path: fallback want ATTACK_PATHS[high] got %s" % str(fallback))
    if str(by_guard) == str(fallback):
        _fail(failures, "kin_attack_path: guard-specific path should differ from fallback")


## Tier 5.1 (optional long-tail): **`strike_mods`** **`cut_damage_mult`** / **`blunt_damage_mult`** scale pre-armor only
## (not **`penetration_sharp_applied`**)  -  cut moves + **MACE** blunt.


## Tier 5.1 (optional long-tail): **`strike_mods`** **`cut_damage_mult`** / **`blunt_damage_mult`** scale pre-armor only
## (not **`penetration_sharp_applied`**)  -  cut moves + **MACE** blunt.
static func _run_kinematic_delivery_strike_mods_damage_mults_scale_pre_armor_only(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var cut_mult: float = 1.4
    var blunt_mult: float = 1.25
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"cut_damage_mult": cut_mult, "blunt_damage_mult": blunt_mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - cut_mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pre_cut ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_cut"]) / float(base["pre_cut"]), cut_mult]
                )
            )
        if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - blunt_mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pre_blunt ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_blunt"]) / float(base["pre_blunt"]), blunt_mult]
                )
            )
        if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pen_sharp should ignore damage mults (base=%.4f shaped=%.4f)"
                    % [tag, float(base["pen_sharp"]), float(shaped["pen_sharp"])]
                )
            )
    for bfx in _kin_fixtures_blunt():
        var wid_b: String = str(bfx["wid"])
        var move_b: String = str(bfx["move"])
        var tag_b: String = str(bfx["tag"])
        var arch_b: Dictionary = _kin_arch_for_move(move_b)
        var base_b: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, wid_b, move_b, 1.0, arch_b)
        var shaped_b: Dictionary = _kin_dmg_integration_sample(
            vo_pin, 1.0, 1.0, {"blunt_damage_mult": blunt_mult}, wid_b, move_b, 1.0, arch_b
        )
        _free_manager(base_b["mgr"] as Node)
        _free_manager(shaped_b["mgr"] as Node)
        if float(base_b["pre_blunt"]) <= 0.1:
            _fail(failures, "%s: kin_dmg_mults baseline pre_blunt too small" % tag_b)
        if absf(float(shaped_b["pre_blunt"]) / float(base_b["pre_blunt"]) - blunt_mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pre_blunt ratio %.4f want %.4f"
                    % [tag_b, float(shaped_b["pre_blunt"]) / float(base_b["pre_blunt"]), blunt_mult]
                )
            )
        if float(base_b["pen_sharp"]) > 0.001:
            if absf(float(shaped_b["pen_sharp"]) / float(base_b["pen_sharp"]) - 1.0) > 0.02:
                _fail(failures, "%s: kin_dmg_mults pen_sharp should ignore blunt_damage_mult" % tag_b)


## Tier 5.1 (optional long-tail): **STAB** contact  -  partial parry at pinned **`vo`** does not apply cut->blunt shift
## (**`PARRY_CUT_TO_BLUNT`** is cut-only).


## Tier 5.1 (optional long-tail): **STAB** contact  -  partial parry at pinned **`vo`** does not apply cut->blunt shift
## (**`PARRY_CUT_TO_BLUNT`** is cut-only).
static func _run_kinematic_delivery_stab_partial_parry_no_cut_to_blunt_shift(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, "SPEAR", "spear_thrust")
    var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {}, "SPEAR", "spear_thrust")
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_stab_no_shift: thrust pre_cut should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_cut"]), float(partial["pre_cut"])]
            )
        )
    if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_stab_no_shift: thrust pre_blunt should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
            )
        )


## Tier 5.1 (optional long-tail): partial parry + misaligned guard  -  oblique factor uses **parry** branch (not
## alignment-only branch) on cut swings.


## Tier 5.1 (optional long-tail): partial parry + misaligned guard  -  oblique factor uses **parry** branch (not
## alignment-only branch) on cut swings.
static func _run_kinematic_delivery_partial_parry_misalign_oblique_parry_branch_wins(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var parry_r: float = 0.25
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var both: Dictionary = _kin_dmg_integration_sample(vo, parry_r, 0.0, {}, wid, move, 1.0, arch)
        var align_only: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 0.0, {}, wid, move, 1.0, arch)
        _free_manager(base["mgr"] as Node)
        _free_manager(both["mgr"] as Node)
        _free_manager(align_only["mgr"] as Node)
        var want_parry_branch: float = lerpf(1.0, amin, 1.0 - parry_r)
        var want_align_branch: float = lerpf(1.0, amin, (1.0 - 0.0) * CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE)
        var ratio_both: float = float(both["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
        var ratio_align: float = float(align_only["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
        if absf(ratio_both - want_parry_branch) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_oblique_parry_wins parry+align pen ratio %.4f want parry branch %.4f"
                    % [tag, ratio_both, want_parry_branch]
                )
            )
        if absf(ratio_both - ratio_align) < 0.02:
            _fail(
                failures,
                (
                    "%s: kin_oblique_parry_wins parry+align should differ from align-only (both=%.4f align=%.4f)"
                    % [tag, ratio_both, ratio_align]
                )
            )
        if want_parry_branch >= want_align_branch - 0.001:
            _fail(
                failures,
                (
                    "%s: kin_oblique_parry_wins fixture want parry branch > align branch (%.4f vs %.4f)"
                    % [tag, want_parry_branch, want_align_branch]
                )
            )


## Tier 5.1 (optional long-tail): **`blunt_momentum_pa_mult`** scales **`penetration_blunt_mpa_applied`** only (not
## **`pre_blunt_applied`**)  -  cut slap + **MACE**.


## Tier 5.1 (optional long-tail): **`blunt_momentum_pa_mult`** scales **`penetration_blunt_mpa_applied`** only (not
## **`pre_blunt_applied`**)  -  cut slap + **MACE**.
static func _run_kinematic_delivery_blunt_momentum_mult_scales_pen_not_pre_armor(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.28
    for cfx in _kin_fixtures_with_blunt_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"blunt_momentum_pa_mult": mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        if float(base["pen_blunt_mpa"]) <= 0.0:
            _fail(
                failures, "%s: kin_blunt_pa_mult baseline blunt mpa invalid %.6f" % [tag, float(base["pen_blunt_mpa"])]
            )
        if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_blunt_pa_mult pen blunt mpa ratio %.4f want %.4f"
                    % [tag, float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
                )
            )
        if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_blunt_pa_mult pre_blunt should ignore blunt_momentum_pa_mult (base=%.4f shaped=%.4f)"
                    % [tag, float(base["pre_blunt"]), float(shaped["pre_blunt"])]
                )
            )


## Tier 5.1 (optional long-tail): unknown **`attack_line`** -> **`ATTACK_PATH_HIGH`** default.


## Tier 5.1 (optional long-tail): unknown **`attack_line`** -> **`ATTACK_PATH_HIGH`** default.
static func _run_kinematic_delivery_get_attack_path_unknown_attack_line_fallback(failures: PackedStringArray) -> void:
    var path: Array = CombatConstants.get_attack_path("__no_such_attack__", "low")
    if str(path) != str(CombatConstants.ATTACK_PATH_HIGH):
        _fail(failures, "kin_attack_path_atk: want ATTACK_PATH_HIGH got %s" % str(path))


## Tier 5.1 (optional long-tail): **`sharp_penetration_mult`** scales **`penetration_sharp_applied`** only (not
## **`pre_cut_applied`**)  -  cut swings + **SPEAR** thrust.


## Tier 5.1 (optional long-tail): **`sharp_penetration_mult`** scales **`penetration_sharp_applied`** only (not
## **`pre_cut_applied`**)  -  cut swings + **SPEAR** thrust.
static func _run_kinematic_delivery_sharp_penetration_mult_scales_pen_not_pre_cut(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.33
    for cfx in _kin_fixtures_with_sharp_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"sharp_penetration_mult": mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        if float(base["pen_sharp"]) <= 0.001:
            _fail(failures, "%s: kin_sharp_pen_mult baseline pen too small %.6f" % [tag, float(base["pen_sharp"])])
        if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_sharp_pen_mult pen ratio %.4f want %.4f"
                    % [tag, float(shaped["pen_sharp"]) / float(base["pen_sharp"]), mult]
                )
            )
        if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_sharp_pen_mult pre_cut should ignore sharp_penetration_mult (base=%.4f shaped=%.4f)"
                    % [tag, float(base["pre_cut"]), float(shaped["pre_cut"])]
                )
            )


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=true)`**  -  low **`stamina_ratio`** in
## **`variance_context`** widens spread vs full stamina (seeded).


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=true)`**  -  low **`stamina_ratio`** in
## **`variance_context`** widens spread vs full stamina (seeded).
static func _run_kinematic_delivery_attack_angle_deg_variance_stamina_spreads(failures: PackedStringArray) -> void:
    seed(44005)
    var full_stam: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"stamina_ratio": 1.0})
    seed(44005)
    var low_stam: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"stamina_ratio": 0.05})
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if absf(full_stam - low_stam) < 0.05:
        _fail(
            failures,
            "kin_atk_angle_var: low stamina should shift angle vs full (full=%.4f low=%.4f)" % [full_stam, low_stam]
        )
    if CombatConstants.angle_diff_deg(full_stam, CombatConstants.line_to_angle("high")) > 25.0:
        _fail(failures, "kin_atk_angle_var: full-stamina draw far from line high (%.4f)" % full_stam)


## Tier 5.1 (optional long-tail): partial parry shifts pre-armor only; misalign scales pens only; **(parry, align)**
## uses parry oblique branch when **`parry_r` < 1**  -  cut swings.


## Tier 5.1 (optional long-tail): partial parry shifts pre-armor only; misalign scales pens only; **(parry, align)**
## uses parry oblique branch when **`parry_r` < 1**  -  cut swings.
static func _run_kinematic_delivery_partial_parry_align_compose_on_pen_not_pre_armor_mix(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var parry_r: float = 0.25
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var clean: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var parry_only: Dictionary = _kin_dmg_integration_sample(vo, parry_r, 1.0, {}, wid, move, 1.0, arch)
        var both: Dictionary = _kin_dmg_integration_sample(vo, parry_r, 0.0, {}, wid, move, 1.0, arch)
        var align_only: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 0.0, {}, wid, move, 1.0, arch)
        _free_manager(clean["mgr"] as Node)
        _free_manager(parry_only["mgr"] as Node)
        _free_manager(both["mgr"] as Node)
        _free_manager(align_only["mgr"] as Node)
        if absf(float(parry_only["pre_cut"]) - float(both["pre_cut"])) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix pre_cut parry-only vs both (%.4f vs %.4f)"
                    % [tag, float(parry_only["pre_cut"]), float(both["pre_cut"])]
                )
            )
        if absf(float(parry_only["pre_blunt"]) - float(both["pre_blunt"])) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix pre_blunt parry-only vs both (%.4f vs %.4f)"
                    % [tag, float(parry_only["pre_blunt"]), float(both["pre_blunt"])]
                )
            )
        if absf(float(parry_only["pen_sharp"]) - float(both["pen_sharp"])) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix pen parry-only vs both should match (%.4f vs %.4f)"
                    % [tag, float(parry_only["pen_sharp"]), float(both["pen_sharp"])]
                )
            )
        if float(parry_only["pre_cut"]) >= float(clean["pre_cut"]) - 0.01:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix partial parry should lower pre_cut (clean=%.4f parry=%.4f)"
                    % [tag, float(clean["pre_cut"]), float(parry_only["pre_cut"])]
                )
            )
        if absf(float(align_only["pre_cut"]) - float(clean["pre_cut"])) > 0.02:
            _fail(failures, "%s: kin_parry_align_mix misalign alone should not change pre_cut" % tag)
        var pen_r_parry: float = float(parry_only["pen_sharp"]) / maxf(float(clean["pen_sharp"]), 0.001)
        var pen_r_align: float = float(align_only["pen_sharp"]) / maxf(float(clean["pen_sharp"]), 0.001)
        var want_parry: float = lerpf(1.0, amin, 1.0 - parry_r)
        var want_align: float = lerpf(1.0, amin, (1.0 - 0.0) * ascale)
        if absf(pen_r_parry - want_parry) > 0.03:
            _fail(failures, "%s: kin_parry_align_mix parry pen ratio %.4f want %.4f" % [tag, pen_r_parry, want_parry])
        if absf(pen_r_align - want_align) > 0.03:
            _fail(failures, "%s: kin_parry_align_mix align pen ratio %.4f want %.4f" % [tag, pen_r_align, want_align])
        if absf(pen_r_parry - pen_r_align) < 0.01:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix fixture should distinguish parry %.2f vs align-only (both %.4f)"
                    % [tag, parry_r, pen_r_parry]
                )
            )


## Tier 5.1 (optional long-tail): entity split  -  **`final_cut` / `final_blunt`** on **`result_dict`** from one chest
## hit; tissue chip > 0  -  all weapon families.


## Tier 5.1 (optional long-tail): entity split  -  **`final_cut` / `final_blunt`** on **`result_dict`** from one chest
## hit; tissue chip > 0  -  all weapon families.
static func _run_kinematic_delivery_entity_split_final_fields_on_hit(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    for cfx in _kin_fixtures_all_damage():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var sample: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        _free_manager(sample["mgr"] as Node)
        var final_cut: float = float(sample["final_cut"])
        var final_blunt: float = float(sample["final_blunt"])
        if final_cut < 0.0 or final_blunt < 0.0:
            _fail(
                failures,
                (
                    "%s: kin_entity_final missing final_cut/final_blunt (cut=%.4f blunt=%.4f)"
                    % [tag, final_cut, final_blunt]
                )
            )
        var tissue: float = final_cut + final_blunt
        if tissue <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            _fail(
                failures,
                "%s: kin_entity_final tissue chip too small (cut=%.4f blunt=%.4f)" % [tag, final_cut, final_blunt]
            )


## Tier 5.1 (optional long-tail): **BLUNT** contact (**MACE** **`direct_blow`**)  -  no cut->blunt shift on partial
## parry at pinned **`vo`**.


## Tier 5.1 (optional long-tail): **BLUNT** contact (**MACE** **`direct_blow`**)  -  no cut->blunt shift on partial
## parry at pinned **`vo`**.
static func _run_kinematic_delivery_mace_blunt_partial_parry_no_cut_to_blunt_shift(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, "MACE", "direct_blow")
    var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {}, "MACE", "direct_blow")
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_mace_no_shift: blunt pre_cut should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_cut"]), float(partial["pre_cut"])]
            )
        )
    if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_mace_no_shift: blunt pre_blunt should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
            )
        )


## Tier 5.1 (optional long-tail): misaligned guard scales **SHARP** and **BLUNT** **`penetration_*_applied`** equally
## (pinned **`vo`**, full parry)  -  cut swings + **MACE**.


## Tier 5.1 (optional long-tail): misaligned guard scales **SHARP** and **BLUNT** **`penetration_*_applied`** equally
## (pinned **`vo`**, full parry)  -  cut swings + **MACE**.
static func _run_kinematic_delivery_misaligned_guard_scales_sharp_and_blunt_pen(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var want: float = lerpf(
        1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    )
    for cfx in _kin_fixtures_with_blunt_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var aligned: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var misaligned: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 0.0, {}, wid, move, 1.0, arch)
        _free_manager(aligned["mgr"] as Node)
        _free_manager(misaligned["mgr"] as Node)
        if float(aligned["pen_sharp"]) > 0.001:
            var r_sharp: float = float(misaligned["pen_sharp"]) / maxf(float(aligned["pen_sharp"]), 0.001)
            if absf(r_sharp - want) > 0.03:
                _fail(failures, "%s: kin_misalign_both sharp ratio %.4f want %.4f" % [tag, r_sharp, want])
        if float(aligned["pen_blunt_mpa"]) > 0.0:
            var r_blunt: float = float(misaligned["pen_blunt_mpa"]) / maxf(float(aligned["pen_blunt_mpa"]), 0.001)
            if absf(r_blunt - want) > 0.03:
                _fail(failures, "%s: kin_misalign_both blunt mpa ratio %.4f want %.4f" % [tag, r_blunt, want])

## Tier 5.1 (optional long-tail): **`strike_mods.strike_energy_mult`** in **`compute_and_apply_damage`**  -
## **`strike_ke_j`** * mult; **`pre_cut`** * **`sqrt(mult)`**; **`penetration_sharp`** * **`mult^PENETRATION_EXPONENT`**
## -  cut swings.
