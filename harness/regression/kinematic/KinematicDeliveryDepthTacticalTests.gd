class_name KinematicDeliveryDepthTacticalTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

## Tier 5.1 optional long-tail kinematic tests split from **`CombatRegressionHarness`** (Godot compile size).
## Footing: strike delivery / energy  -  may pass **`guard_line`** into path context; not L2 form or Tier 4.4 PA owner.
## LIVE_PATHS **`#wf-layer-labels`**.

## Tier 5.1 (optional long-tail): **`strike_physics_ctx`** depth-polearm open-lane stab raises **`strike_ke_j`**.
## Cut **`attack_type`** / **`over_shoulder`** lane do not.
const HumanSpecies := preload("res://resources/species/human.tres")


static func _run_kinematic_delivery_depth_polearm_thrust_ctx_scales_strike_ke(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var move_id: String = "spear_thrust"
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var neutral: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SPEAR", move_id, 1.0, arch
    )
    var depth_open: Dictionary = (
        CombatRegressionHarness
        . _kin_dmg_integration_sample(
            vo_pin,
            1.0,
            1.0,
            {},
            "SPEAR",
            move_id,
            1.0,
            arch,
            {},
            "",
            {
                "depth_polearm_attack": true,
                "attack_type": move_id,
                "depth_polearm_lane_type": "open",
            }
        )
    )
    var depth_cut: Dictionary = (
        CombatRegressionHarness
        . _kin_dmg_integration_sample(
            vo_pin,
            1.0,
            1.0,
            {},
            "SPEAR",
            move_id,
            1.0,
            arch,
            {},
            "",
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_slash",
                "depth_polearm_lane_type": "open",
            }
        )
    )
    var depth_shoulder: Dictionary = (
        CombatRegressionHarness
        . _kin_dmg_integration_sample(
            vo_pin,
            1.0,
            1.0,
            {},
            "SPEAR",
            move_id,
            1.0,
            arch,
            {},
            "",
            {
                "depth_polearm_attack": true,
                "attack_type": move_id,
                "depth_polearm_lane_type": "over_shoulder",
            }
        )
    )
    var ke_neutral: float = float(neutral["strike_ke_j"])
    var ke_open: float = float(depth_open["strike_ke_j"])
    var ke_cut: float = float(depth_cut["strike_ke_j"])
    var ke_shoulder: float = float(depth_shoulder["strike_ke_j"])
    var ctx_open: Dictionary = depth_open["strike_physics_ctx"] as Dictionary
    var cls_open: float = StrikePhysics.closing_speed_multiplier(
        depth_open["mgr"] as Node, depth_open["atk"] as Dictionary, depth_open["tgt"] as Dictionary, ctx_open
    )
    var cls_neutral: float = StrikePhysics.closing_speed_multiplier(
        neutral["mgr"] as Node, neutral["atk"] as Dictionary, neutral["tgt"] as Dictionary, {}
    )
    CombatRegressionHarness._free_manager(neutral["mgr"] as Node)
    CombatRegressionHarness._free_manager(depth_open["mgr"] as Node)
    CombatRegressionHarness._free_manager(depth_cut["mgr"] as Node)
    CombatRegressionHarness._free_manager(depth_shoulder["mgr"] as Node)
    if ke_neutral <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_depth_close: neutral strike_ke too small %.4f" % ke_neutral)
    if ke_open <= ke_neutral + 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_depth_close: open lane ke %.4f should exceed neutral %.4f" % [ke_open, ke_neutral]
        )
    if absf(ke_cut / ke_neutral - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures, "kin_depth_close: cut attack_type should not boost thrust ke (ratio %.4f)" % [ke_cut / ke_neutral]
        )
    if absf(ke_shoulder / ke_neutral - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures, "kin_depth_close: over_shoulder lane should not boost (ratio %.4f)" % [ke_shoulder / ke_neutral]
        )
    var ratio_ke: float = ke_open / maxf(ke_neutral, 0.001)
    var ratio_want: float = (cls_open / maxf(cls_neutral, 0.001)) ** 2.0
    if absf(ratio_ke - ratio_want) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_depth_close: ke ratio %.4f want ~(cls ratio)^2 %.4f (cls neutral=%.4f open=%.4f)"
                % [ratio_ke, ratio_want, cls_neutral, cls_open]
            )
        )
    if absf(cls_open - CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT) > 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_depth_close: open cls want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, cls_open]
            )
        )


## Tier 5.1 (optional long-tail): **`strike_physics_ctx.tactical_ambush_mult`** at cap raises **`strike_ke_j`**
## (~**v2**); **<= 1** unchanged.


## Tier 5.1 (optional long-tail): **`strike_physics_ctx.tactical_ambush_mult`** at cap raises **`strike_ke_j`**
## (~**v2**); **<= 1** unchanged.
static func _run_kinematic_delivery_tactical_ambush_mult_scales_strike_ke(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var amb_cap: float = StrikePhysics._AMBUSH_DIV
    var plain: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var ambush: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "", {"tactical_ambush_mult": amb_cap}
    )
    var ke_plain: float = float(plain["strike_ke_j"])
    var ke_amb: float = float(ambush["strike_ke_j"])
    var cls_plain: float = StrikePhysics.closing_speed_multiplier(
        plain["mgr"] as Node, plain["atk"] as Dictionary, plain["tgt"] as Dictionary, {}
    )
    var cls_amb: float = StrikePhysics.closing_speed_multiplier(
        ambush["mgr"] as Node,
        ambush["atk"] as Dictionary,
        ambush["tgt"] as Dictionary,
        {"tactical_ambush_mult": amb_cap}
    )
    CombatRegressionHarness._free_manager(plain["mgr"] as Node)
    CombatRegressionHarness._free_manager(ambush["mgr"] as Node)
    if ke_plain <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_ambush: plain strike_ke too small %.4f" % ke_plain)
    if ke_amb <= ke_plain + 0.25:
        CombatRegressionHarness._fail(
            failures, "kin_ambush: ambush ke %.4f should exceed plain %.4f" % [ke_amb, ke_plain]
        )
    var ratio_ke: float = ke_amb / maxf(ke_plain, 0.001)
    var ratio_want: float = (cls_amb / maxf(cls_plain, 0.001)) ** 2.0
    if absf(ratio_ke - ratio_want) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_ambush: ke ratio %.4f want ~(cls ratio)^2 %.4f (cls plain=%.4f amb=%.4f)"
                % [ratio_ke, ratio_want, cls_plain, cls_amb]
            )
        )


## Tier 5.1 (optional long-tail): depth-polearm stab with **`depth_polearm_allows_low_targets` false** and non-open lane
## -> no closing boost; default **true** still boosts.


## Tier 5.1 (optional long-tail): depth-polearm stab with **`depth_polearm_allows_low_targets` false** and non-open lane
## -> no closing boost; default **true** still boosts.
static func _run_kinematic_delivery_depth_polearm_allows_low_false_no_closing_boost(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var move_id: String = "spear_thrust"
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var neutral: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SPEAR", move_id, 1.0, arch
    )
    var no_low: Dictionary = (
        CombatRegressionHarness
        . _kin_dmg_integration_sample(
            vo_pin,
            1.0,
            1.0,
            {},
            "SPEAR",
            move_id,
            1.0,
            arch,
            {},
            "",
            {
                "depth_polearm_attack": true,
                "attack_type": move_id,
                "depth_polearm_lane_type": "",
                "depth_polearm_allows_low_targets": false,
            }
        )
    )
    var allow_low: Dictionary = (
        CombatRegressionHarness
        . _kin_dmg_integration_sample(
            vo_pin,
            1.0,
            1.0,
            {},
            "SPEAR",
            move_id,
            1.0,
            arch,
            {},
            "",
            {
                "depth_polearm_attack": true,
                "attack_type": move_id,
                "depth_polearm_lane_type": "",
                "depth_polearm_allows_low_targets": true,
            }
        )
    )
    var ke_neutral: float = float(neutral["strike_ke_j"])
    var ke_no_low: float = float(no_low["strike_ke_j"])
    var ke_allow: float = float(allow_low["strike_ke_j"])
    CombatRegressionHarness._free_manager(neutral["mgr"] as Node)
    CombatRegressionHarness._free_manager(no_low["mgr"] as Node)
    CombatRegressionHarness._free_manager(allow_low["mgr"] as Node)
    if ke_neutral <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_depth_allow_low: neutral ke too small %.4f" % ke_neutral)
    if absf(ke_no_low / ke_neutral - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_depth_allow_low: allows_low false want neutral ratio (got %.4f / %.4f = %.4f)"
                % [ke_no_low, ke_neutral, ke_no_low / ke_neutral]
            )
        )
    if ke_allow <= ke_neutral + 0.25:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_depth_allow_low: default allows_low true should boost ke (neutral=%.4f allow=%.4f)"
                % [ke_neutral, ke_allow]
            )
        )


static func _strike_physics_ctx_from_pa(pa: Dictionary, attack_type: String) -> Dictionary:
    return {
        "tactical_ambush_mult": float(pa.get("tactical_ambush_mult", 1.0)),
        "attack_type": attack_type,
        "depth_polearm_attack": bool(pa.get("depth_polearm_attack", false)),
        "depth_polearm_lane_type": str(pa.get("depth_polearm_lane_type", "")),
        "depth_polearm_allows_low_targets": bool(pa.get("depth_polearm_allows_low_targets", true)),
    }


static func _kin_strike_ke_on_manager(
    mgr: Node, atk: Dictionary, tgt: Dictionary, move_id: String, vo_pin: float, strike_physics_ctx: Dictionary
) -> float:
    mgr.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        mgr,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        0.62,
        move_id,
        arch,
        vo_pin,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        1.0,
        1.0,
        {},
        strike_physics_ctx
    )
    return float(res.get("result_dict", {}).get("strike_ke_j_applied", -999.0))


## Tier 5.1 (optional long-tail): rank-1 depth **`stamp_attack_pair_geometry_on_dict`** -> **`strike_physics_ctx`**
## matches **`AttackResolver`**; open lane **`strike_ke_j`** matches manual ctx.


## Tier 5.1 (optional long-tail): rank-1 depth **`stamp_attack_pair_geometry_on_dict`** -> **`strike_physics_ctx`**
## matches **`AttackResolver`**; open lane **`strike_ke_j`** matches manual ctx.
static func _run_kinematic_delivery_pa_stamp_open_lane_strike_ke_matches_manual_ctx(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var move_id: String = "spear_thrust"
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    (
        mgr
        . start(
            {
                "files": 1,
                "ranks": 2,
                "density": "normal",
                CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE: CombatConstants.SPEAR_LANE_PROFILE_OPEN,
            },
            {"files": 1, "ranks": 1, "density": "normal"}
        )
    )
    var depth: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "kin_pa_stamp: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {"attack_type": move_id, "tactical_ambush_mult": 1.0}
    CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa)
    if not bool(pa.get("depth_polearm_attack", false)):
        CombatRegressionHarness._fail(failures, "kin_pa_stamp: depth_polearm_attack want true after stamp")
    if str(pa.get("depth_polearm_lane_type", "")) != CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN:
        CombatRegressionHarness._fail(
            failures, "kin_pa_stamp: lane_type want open got %s" % str(pa.get("depth_polearm_lane_type", ""))
        )
    var ctx_from_pa: Dictionary = KinematicDeliveryDepthTacticalTests._strike_physics_ctx_from_pa(pa, move_id)
    var manual_ctx: Dictionary = {
        "tactical_ambush_mult": 1.0,
        "depth_polearm_attack": true,
        "attack_type": move_id,
        "depth_polearm_lane_type": "open",
        "depth_polearm_allows_low_targets": true,
    }
    for key in manual_ctx:
        if ctx_from_pa.get(key) != manual_ctx.get(key):
            CombatRegressionHarness._fail(
                failures,
                "kin_pa_stamp: ctx[%s] want %s got %s" % [key, str(manual_ctx[key]), str(ctx_from_pa.get(key))]
            )
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var weapon: Weapon = CombatantEntityAccess.get_weapon(depth) as Weapon
    var ke_got: float = KinematicDeliveryDepthTacticalTests._kin_strike_ke_on_manager(
        mgr, depth, enemy, move_id, vo_pin, ctx_from_pa
    )
    var v_asm: float = CombatRegressionHarness._kin_expected_damage_velocity_m_s(
        mgr, depth, enemy, 0.62, arch, move_id, vo_pin, 1.0, ctx_from_pa
    )
    var ai: AttackInstance = AttackInstance.new(move_id, 0.62)
    ai.archetype = arch
    ai.velocity_m_s = v_asm
    var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai) if weapon != null else -1.0
    CombatRegressionHarness._free_manager(mgr)
    if ke_got <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_pa_stamp: stamped ke too small %.4f" % ke_got)
    if weapon == null:
        CombatRegressionHarness._fail(failures, "kin_pa_stamp: missing spear weapon")
    elif absf(ke_got / ke_want - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_pa_stamp: strike_ke_j ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)"
                % [ke_got / ke_want, ke_got, ke_want, v_asm]
            )
        )


## Tier 5.1 (optional long-tail): **`variance_context.off_balance`** widens **`get_attack_angle_deg`** spread (seeded);
## complements stamina-only harness in main file.


## Tier 5.1 (optional long-tail): **`variance_context.off_balance`** widens **`get_attack_angle_deg`** spread (seeded);
## complements stamina-only harness in main file.
static func _run_kinematic_delivery_attack_angle_deg_variance_off_balance_spreads(failures: PackedStringArray) -> void:
    seed(44007)
    var balanced: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"off_balance": false})
    seed(44007)
    var off_bal: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"off_balance": true})
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if absf(balanced - off_bal) < 0.05:
        CombatRegressionHarness._fail(
            failures, "kin_atk_angle_ob: off_balance should shift angle (balanced=%.4f off=%.4f)" % [balanced, off_bal]
        )


## Tier 5.1 (optional long-tail): heavy **`variance_context.weapon_mass_kg`** widens attack-angle spread vs reference
## mass (seeded).


## Tier 5.1 (optional long-tail): heavy **`variance_context.weapon_mass_kg`** widens attack-angle spread vs reference
## mass (seeded).
static func _run_kinematic_delivery_attack_angle_deg_variance_weapon_mass_spreads(failures: PackedStringArray) -> void:
    seed(44008)
    var ref_mass: float = CombatConstants.get_attack_angle_deg(
        "high", true, {}, {"weapon_mass_kg": CombatConstants.ANGLE_VARIANCE_MASS_REFERENCE_KG}
    )
    seed(44008)
    var heavy: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"weapon_mass_kg": 3.0})
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if absf(ref_mass - heavy) < 0.05:
        CombatRegressionHarness._fail(
            failures, "kin_atk_angle_mass: heavy mass should shift angle (ref=%.4f heavy=%.4f)" % [ref_mass, heavy]
        )


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`**  -  **`tactical_ambush_mult` <= 1** does
## not raise closing (only **`amb > 1.001`** lerps toward **`_AMBUSH_CAP`**; code authoritative vs narrative "ambush
## cap" only).


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`**  -  **`tactical_ambush_mult` <= 1** does
## not raise closing (only **`amb > 1.001`** lerps toward **`_AMBUSH_CAP`**; code authoritative vs narrative "ambush
## cap" only).
static func _run_kinematic_delivery_tactical_ambush_mult_unity_no_boost(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var plain: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var unity: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "", {"tactical_ambush_mult": 1.0}
    )
    var sub_one: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "", {"tactical_ambush_mult": 0.85}
    )
    var ke_plain: float = float(plain["strike_ke_j"])
    var ke_unity: float = float(unity["strike_ke_j"])
    var ke_sub: float = float(sub_one["strike_ke_j"])
    CombatRegressionHarness._free_manager(plain["mgr"] as Node)
    CombatRegressionHarness._free_manager(unity["mgr"] as Node)
    CombatRegressionHarness._free_manager(sub_one["mgr"] as Node)
    if ke_plain <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_ambush_unity: plain strike_ke too small %.4f" % ke_plain)
    if absf(ke_unity / ke_plain - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures, "kin_ambush_unity: mult=1.0 should not boost ke (ratio %.4f)" % [ke_unity / ke_plain]
        )
    if absf(ke_sub / ke_plain - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures, "kin_ambush_unity: mult<1 should not boost ke (ratio %.4f)" % [ke_sub / ke_plain]
        )


## Tier 5.1 (optional long-tail): unknown **`engagement_angle`** on target -> same closing multiplier as **`front`**
## (StrikePhysics default branch).


## Tier 5.1 (optional long-tail): unknown **`engagement_angle`** on target -> same closing multiplier as **`front`**
## (StrikePhysics default branch).
static func _run_kinematic_delivery_engagement_angle_unknown_matches_front(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var tgt_front: Dictionary = mgr.combatants[1].duplicate()
    tgt_front["engagement_angle"] = "front"
    var tgt_unknown: Dictionary = mgr.combatants[1].duplicate()
    tgt_unknown["engagement_angle"] = "diagonal"
    var cls_front: float = StrikePhysics.closing_speed_multiplier(mgr, atk, tgt_front, {})
    var cls_unknown: float = StrikePhysics.closing_speed_multiplier(mgr, atk, tgt_unknown, {})
    CombatRegressionHarness._free_manager(mgr)
    if absf(cls_unknown - cls_front) > 0.0001:
        CombatRegressionHarness._fail(
            failures, "kin_eng_ang: unknown want front cls %.4f got %.4f" % [cls_front, cls_unknown]
        )


## Tier 5.1 (optional long-tail): parry **`v_intent`** on **SPEAR** **`spear_thrust`** uses thrust
## **`get_effective_velocity_m_s`** (not swing curve).


## Tier 5.1 (optional long-tail): parry **`v_intent`** on **SPEAR** **`spear_thrust`** uses thrust
## **`get_effective_velocity_m_s`** (not swing curve).
static func _run_kinematic_delivery_parry_v_intent_thrust_archetype(failures: PackedStringArray) -> void:
    var spear: Weapon = HarnessFixtures.get_cached_weapon("SPEAR")
    if spear == null:
        CombatRegressionHarness._fail(failures, "kin_parry_v_thrust: missing spear")
        return
    var move_id: String = "spear_thrust"
    var intensity: float = 0.62
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_derived: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_derived.archetype = arch
    ai_derived.velocity_m_s = -1.0
    var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, ai_derived)
    var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(intensity, arch, spear, move_id)
    if absf(v_eff - v_from_i) > 0.0001:
        CombatRegressionHarness._fail(
            failures, "kin_parry_v_thrust: derived v_eff want %.6f got %.6f" % [v_from_i, v_eff]
        )
    if WeaponDamageHelper.kinematic_delivery(arch, move_id) != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
        CombatRegressionHarness._fail(failures, "kin_parry_v_thrust: explicit thrust archetype want thrust delivery")
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        CombatRegressionHarness._fail(failures, "kin_parry_v_thrust: missing sword")
        return
    var ai_cut: AttackInstance = AttackInstance.new("oberhau", intensity)
    ai_cut.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_cut.velocity_m_s = -1.0
    var v_cut: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_cut)
    if absf(v_eff - v_cut) < 0.05:
        CombatRegressionHarness._fail(
            failures,
            "kin_parry_v_thrust: spear thrust v_eff %.4f should differ from sword oberhau %.4f" % [v_eff, v_cut]
        )


## Tier 5.1 (optional long-tail): **SPEAR** **`spear_thrust`** integration  -  **`pre_cut_applied`** ~
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`** at two pinned **`velocity_override`** values.


## Tier 5.1 (optional long-tail): **SPEAR** **`spear_thrust`** integration  -  **`pre_cut_applied`** ~
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`** at two pinned **`velocity_override`** values.
static func _run_kinematic_delivery_thrust_integration_pre_cut_scales_ke_pow(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        9.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
    )
    # hi velocity kept below the DAMAGE_KE_MAX / penetration caps so the ratio cleanly tracks the
    # power law (vo=14 clamps the high sample and compresses the ratio).
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        11.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
    )
    var ke_lo: float = float(lo["strike_ke_j"])
    var ke_hi: float = float(hi["strike_ke_j"])
    var cut_lo: float = float(lo["pre_cut"])
    var cut_hi: float = float(hi["pre_cut"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if ke_hi <= ke_lo + 1e-4:
        CombatRegressionHarness._fail(
            failures, "kin_thrust_int: ke_hi should exceed ke_lo (lo=%.4f hi=%.4f)" % [ke_lo, ke_hi]
        )
    if cut_hi <= cut_lo + 1e-4:
        CombatRegressionHarness._fail(
            failures, "kin_thrust_int: pre_cut_hi should exceed pre_cut_lo (lo=%.4f hi=%.4f)" % [cut_lo, cut_hi]
        )
    var want_ratio: float = pow(ke_hi / maxf(ke_lo, 0.001), WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT)
    var got_ratio: float = cut_hi / maxf(cut_lo, 0.001)
    if absf(got_ratio - want_ratio) > 0.04:
        CombatRegressionHarness._fail(
            failures,
            "kin_thrust_int: pre_cut ratio %.4f want ke^%.2f ratio %.4f"
            % [got_ratio, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_ratio]
        )


## Tier 5.1 (optional long-tail): **MACE** **`direct_blow`** integration  -  **`pre_blunt_applied`** rises with pinned
## **`velocity_override`**.


## Tier 5.1 (optional long-tail): **MACE** **`direct_blow`** integration  -  **`pre_blunt_applied`** rises with pinned
## **`velocity_override`**.
static func _run_kinematic_delivery_mace_integration_pre_blunt_rises_with_vo(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        8.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
    )
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        14.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
    )
    var blunt_lo: float = float(lo["pre_blunt"])
    var blunt_hi: float = float(hi["pre_blunt"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if blunt_hi <= blunt_lo + 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_mace_int: pre_blunt_hi should exceed lo (lo=%.4f hi=%.4f)" % [blunt_lo, blunt_hi]
        )


## Tier 5.1 (optional long-tail): **SPEAR** thrust integration  -  applied **`penetration_sharp`** ~
## **`KE^PENETRATION_EXPONENT`** at two pinned **`vo`**.


## Tier 5.1 (optional long-tail): **SPEAR** thrust integration  -  applied **`penetration_sharp`** ~
## **`KE^PENETRATION_EXPONENT`** at two pinned **`vo`**.
static func _run_kinematic_delivery_thrust_integration_pen_sharp_scales_ke_exponent(
    failures: PackedStringArray
) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        9.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
    )
    # hi velocity kept below the DAMAGE_KE_MAX / penetration caps so the ratio cleanly tracks the
    # power law (vo=14 clamps the high sample and compresses the ratio).
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        11.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
    )
    var ke_lo: float = float(lo["strike_ke_j"])
    var ke_hi: float = float(hi["strike_ke_j"])
    var pen_lo: float = float(lo["pen_sharp"])
    var pen_hi: float = float(hi["pen_sharp"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if ke_hi <= ke_lo + 1e-4 or pen_hi <= pen_lo + 1e-6:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_thrust_pen: need rising ke/pen (ke lo=%.4f hi=%.4f pen lo=%.4f hi=%.4f)"
                % [ke_lo, ke_hi, pen_lo, pen_hi]
            )
        )
    var exp: float = WeaponConstants.PENETRATION_EXPONENT
    var want_ratio: float = pow(ke_hi / maxf(ke_lo, 0.001), exp)
    var got_ratio: float = pen_hi / maxf(pen_lo, 0.001)
    if absf(got_ratio - want_ratio) > 0.06:
        CombatRegressionHarness._fail(
            failures, "kin_thrust_pen: pen ratio %.4f want ke^%.2f ratio %.4f" % [got_ratio, exp, want_ratio]
        )


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`**  -  both angles -> path keys from
## **`angle_to_nearest_line`**; hit part stays inside intercept segment.


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`**  -  both angles -> path keys from
## **`angle_to_nearest_line`**; hit part stays inside intercept segment.
static func _run_kinematic_delivery_resolve_hit_part_angle_path_keys(failures: PackedStringArray) -> void:
    var atk_deg: float = 90.0
    var guard_deg: float = 0.0
    var align_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var atk_line_path: String = CombatConstants.angle_to_nearest_line(atk_deg)
    var guard_line_path: String = CombatConstants.angle_to_nearest_line(guard_deg)
    var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
    if path.is_empty():
        CombatRegressionHarness._fail(failures, "kin_resolve_part: empty angle-based path")
        return
    var defender: Dictionary = {"guard_line": "high"}
    var align: float = CombatConstants.get_line_alignment_with_deflect("high", defender, align_ctx)
    var intercept_max: int = CombatRegressionHarness._kin_path_intercept_max_index(path, align)
    var targetable: Array = []
    for p in path:
        if p is String and not targetable.has(p):
            targetable.append(p)
    seed(44009)
    var part: String = AttackPathResolver.resolve_hit_part("high", "high", targetable, {}, "", defender, align_ctx)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var allowed: Array = []
    for i in range(intercept_max + 1):
        if i < path.size():
            allowed.append(path[i])
    if part.is_empty():
        CombatRegressionHarness._fail(failures, "kin_resolve_part: empty hit part")
    elif not allowed.has(part):
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_resolve_part: part %s not in intercept segment %s (max=%d align=%.4f)"
                % [part, str(allowed), intercept_max, align]
            )
        )
    var path_strings: Array = CombatConstants.get_attack_path("high", "high")
    if not path_strings.is_empty() and path[0] == path_strings[0]:
        CombatRegressionHarness._fail(
            failures, "kin_resolve_part: angle path first segment should differ from high/high (%s)" % str(path[0])
        )


## Tier 5.1 (optional long-tail): empty archetype on stab move  -  **`kinematic_delivery`** infers thrust;
## **`compute_and_apply_damage`** matches explicit thrust arch.


## Tier 5.1 (optional long-tail): empty archetype on stab move  -  **`kinematic_delivery`** infers thrust;
## **`compute_and_apply_damage`** matches explicit thrust arch.
static func _run_kinematic_delivery_empty_arch_spear_thrust_infers_delivery(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var move_id: String = "spear_thrust"
    if WeaponDamageHelper.kinematic_delivery({}, move_id) != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
        CombatRegressionHarness._fail(failures, "kin_infer_arch: empty arch + stab want thrust delivery")
    var explicit: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SPEAR", move_id, 1.0, {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    )
    var mgr: Node = CombatManager.new()
    mgr.set_meta(CombatRegressionHarness.HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    mgr.set_meta(CombatRegressionHarness.HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    CombatRegressionHarness._harness_reset_combatants_form_balanced(mgr)
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
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    var ke_infer: float = float(rd.get("strike_ke_j_applied", -999.0))
    var cut_infer: float = float(rd.get("pre_cut_applied", -999.0))
    CombatRegressionHarness._free_manager(mgr)
    CombatRegressionHarness._free_manager(explicit["mgr"] as Node)
    if absf(ke_infer / float(explicit["strike_ke_j"]) - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_infer_arch: strike_ke ratio %.4f (infer=%.4f explicit=%.4f)"
                % [ke_infer / float(explicit["strike_ke_j"]), ke_infer, float(explicit["strike_ke_j"])]
            )
        )
    if absf(cut_infer / float(explicit["pre_cut"]) - 1.0) > 0.04:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_infer_arch: pre_cut ratio %.4f (infer=%.4f explicit=%.4f)"
                % [cut_infer / float(explicit["pre_cut"]), cut_infer, float(explicit["pre_cut"])]
            )
        )


## Tier 5.1 (optional long-tail): **`move_def.angle_offset_deg`** applies even when **`add_variance=false`** (seeded
## deterministic).


## Tier 5.1 (optional long-tail): **`move_def.angle_offset_deg`** applies even when **`add_variance=false`** (seeded
## deterministic).
static func _run_kinematic_delivery_move_def_angle_offset_seeded_deterministic(failures: PackedStringArray) -> void:
    var move_def: Dictionary = WeaponConstants.get_move("off_line_thrust")
    if float(move_def.get("angle_offset_deg", 0.0)) <= 0.0:
        CombatRegressionHarness._fail(failures, "kin_move_offset: off_line_thrust needs angle_offset_deg")
        return
    seed(44010)
    var a: float = CombatConstants.get_attack_angle_deg("high", false, move_def, {})
    seed(44010)
    var b: float = CombatConstants.get_attack_angle_deg("high", false, move_def, {})
    seed(44011)
    var c: float = CombatConstants.get_attack_angle_deg("high", false, move_def, {})
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if absf(a - b) > 0.0001:
        CombatRegressionHarness._fail(failures, "kin_move_offset: same seed want same angle (a=%.4f b=%.4f)" % [a, b])
    if absf(a - c) < 0.05:
        CombatRegressionHarness._fail(
            failures, "kin_move_offset: different seed should shift angle (a=%.4f c=%.4f)" % [a, c]
        )
    var base: float = CombatConstants.line_to_angle("high")
    if absf(a - base) < 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_move_offset: offset should move angle away from line high (base=%.4f got=%.4f)" % [base, a]
        )


## Tier 5.1 (optional long-tail): **`velocity_override` < 0**  -  misaligned guard (**`alignment` 0**) does not scale
## applied pens (oblique branch skipped).


## Tier 5.1 (optional long-tail): **`velocity_override` < 0**  -  misaligned guard (**`alignment` 0**) does not scale
## applied pens (oblique branch skipped).
static func _run_kinematic_delivery_derived_velocity_misalign_skips_oblique_pen(failures: PackedStringArray) -> void:
    var aligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(-1.0, 1.0, 1.0, {})
    var misaligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(-1.0, 1.0, 0.0, {})
    CombatRegressionHarness._free_manager(aligned["mgr"] as Node)
    CombatRegressionHarness._free_manager(misaligned["mgr"] as Node)
    if absf(float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]) - 1.0) > 0.02:
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "kin_derived_misalign: sharp pen ratio %.4f want 1 (aligned=%.4f mis=%.4f)"
                    % [
                        float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]),
                        float(aligned["pen_sharp"]),
                        float(misaligned["pen_sharp"]),
                    ]
                )
            )
        )
    if absf(float(misaligned["pen_blunt_mpa"]) / float(aligned["pen_blunt_mpa"]) - 1.0) > 0.02:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_derived_misalign: blunt mpa ratio %.4f want 1"
                % [float(misaligned["pen_blunt_mpa"]) / float(aligned["pen_blunt_mpa"])]
            )
        )


## Tier 5.1 (optional long-tail): **MACE** integration  -  applied **`penetration_blunt_mpa`** rises with pinned
## **`velocity_override`**.


## Tier 5.1 (optional long-tail): **MACE** integration  -  applied **`penetration_blunt_mpa`** rises with pinned
## **`velocity_override`**.
static func _run_kinematic_delivery_mace_integration_pen_blunt_mpa_rises_with_vo(failures: PackedStringArray) -> void:
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        8.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
    )
    var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        14.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
    )
    var pen_lo: float = float(lo["pen_blunt_mpa"])
    var pen_hi: float = float(hi["pen_blunt_mpa"])
    CombatRegressionHarness._free_manager(lo["mgr"] as Node)
    CombatRegressionHarness._free_manager(hi["mgr"] as Node)
    if pen_hi <= pen_lo + 1e-4:
        CombatRegressionHarness._fail(
            failures, "kin_mace_pen: mpa_hi should exceed lo (lo=%.4f hi=%.4f)" % [pen_lo, pen_hi]
        )


static func _kin_striker_pre_cut_sample(stamina_ratio: float) -> float:
    var m: Node = CombatManager.new()
    m.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    m.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    atk["stamina"] = CombatConstants.STAMINA_MAX * clampf(stamina_ratio, 0.0, 1.0)
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        0.62,
        "oberhau",
        {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING},
        11.0,
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
    var pre: float = float(res.get("result_dict", {}).get("pre_cut_applied", -999.0))
    CombatRegressionHarness._free_manager(m)
    return pre


## Tier 5.1 (optional long-tail): low striker **`stamina`** lowers integration **`pre_cut_applied`** (same pinned
## **`vo`** as strike_ke tail).


## Tier 5.1 (optional long-tail): low striker **`stamina`** lowers integration **`pre_cut_applied`** (same pinned
## **`vo`** as strike_ke tail).
static func _run_kinematic_delivery_low_striker_stamina_lowers_pre_cut(failures: PackedStringArray) -> void:
    var cut_full: float = KinematicDeliveryDepthTacticalTests._kin_striker_pre_cut_sample(1.0)
    var cut_low: float = KinematicDeliveryDepthTacticalTests._kin_striker_pre_cut_sample(0.05)
    if cut_full <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_striker_pre: full pre_cut too small %.4f" % cut_full)
    if cut_low >= cut_full - 0.01:
        CombatRegressionHarness._fail(
            failures, "kin_striker_pre: low stamina should reduce pre_cut (full=%.4f low=%.4f)" % [cut_full, cut_low]
        )


## Tier 5.1 (optional long-tail): **`move_def.angle_variance_deg`** widens attack-angle spread vs bare line (seeded).


## Tier 5.1 (optional long-tail): **`move_def.angle_variance_deg`** widens attack-angle spread vs bare line (seeded).
static func _run_kinematic_delivery_move_def_angle_variance_wider_than_bare_line(failures: PackedStringArray) -> void:
    var move_def: Dictionary = WeaponConstants.get_move("off_line_thrust")
    if float(move_def.get("angle_variance_deg", 0.0)) <= 0.0:
        CombatRegressionHarness._fail(failures, "kin_move_var: off_line_thrust needs angle_variance_deg")
        return
    seed(44012)
    var with_move: float = CombatConstants.get_attack_angle_deg("high", true, move_def, {"stamina_ratio": 1.0})
    seed(44012)
    var bare_line: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"stamina_ratio": 1.0})
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if absf(with_move - bare_line) < 0.05:
        CombatRegressionHarness._fail(
            failures, "kin_move_var: move variance should shift angle (bare=%.4f move=%.4f)" % [bare_line, with_move]
        )


## Tier 5.1 (optional long-tail): **`DefenseChoiceResolver.choose_defense`**  -  **`parry_p_a`** = **`m_a - -  v_intent
## - -  velocity_curve_factor(progress)`** with **`v_intent`** from **`WeaponDamageHelper.get_effective_velocity_m_s`**.


## Tier 5.1 (optional long-tail): **`DefenseChoiceResolver.choose_defense`**  -  **`parry_p_a`** = **`m_a - -  v_intent
## - -  velocity_curve_factor(progress)`** with **`v_intent`** from **`WeaponDamageHelper.get_effective_velocity_m_s`**.
static func _run_kinematic_delivery_choose_defense_parry_p_a_matches_v_intent_formula(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.44
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_line"] = "high"
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "kin_parry_pa: targetable parts empty")
        CombatRegressionHarness._free_manager(mgr)
        return
    var attack_type: String = "oberhau"
    var intensity: float = 0.55
    var wind_up: float = 0.95
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var pa: Dictionary = {
        "attack_type": attack_type,
        "intensity": intensity,
        "wind_up_duration": wind_up,
        "tactical_ambush_mult": 1.0,
    }
    var dc: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, attack_type, arch, -1.0)
    if not bool(dc.get("can_parry_in_time", false)):
        CombatRegressionHarness._fail(failures, "kin_parry_pa: fixture should allow parry in time")
        CombatRegressionHarness._free_manager(mgr)
        return
    var atk_weapon: Weapon = CombatantEntityAccess.get_weapon(attacker) as Weapon
    if atk_weapon == null:
        CombatRegressionHarness._fail(failures, "kin_parry_pa: missing attacker weapon")
        CombatRegressionHarness._free_manager(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var contact_type: String = str(move_def.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
    var m_a: float = CombatantEntityAccess.weapon_striking_mass_kg(atk_weapon, contact_type)
    var comm_frac: float = CombatConstants.commitment_fraction_for_pending_attack(pa)
    var effective_wind_up: float = wind_up * (1.0 - comm_frac)
    var reaction_time: float = CombatantEntityAccess.get_passive_parry_reaction_time(defender)
    var parry_time: float = effective_wind_up - reaction_time
    var parry_progress: float = 1.0 - clampf(parry_time / maxf(0.001, effective_wind_up), 0.0, 1.0)
    var ai: AttackInstance = AttackInstance.new(attack_type, intensity)
    ai.archetype = arch
    ai.velocity_m_s = -1.0
    var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, ai)
    v_intent *= StrikeRealismProfile.velocity_intent_mult_from_pa(pa, atk_weapon, attack_type, intensity, arch)
    var want_pa: float = m_a * v_intent * CombatTiming.velocity_curve_factor(parry_progress)
    var got_pa: float = float(dc.get("parry_p_a", 0.0))
    if got_pa <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_parry_pa: parry_p_a too small %.4f" % got_pa)
    elif absf(got_pa / want_pa - 1.0) > 0.30:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_parry_pa: ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f m=%.4f prog=%.4f)"
                % [got_pa / want_pa, got_pa, want_pa, v_intent, m_a, parry_progress]
            )
        )
    CombatRegressionHarness._free_manager(mgr)

## Tier 5.1 (optional long-tail): rear **`engagement_angle`** - -  **`afterblow_damage_mult`** compose on assembled
## **`v`** -> **`strike_ke_j`** (~**(cls - -  sqrtab)2**).
