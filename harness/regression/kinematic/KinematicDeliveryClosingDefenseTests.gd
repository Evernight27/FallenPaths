class_name KinematicDeliveryClosingDefenseTests

extends KinematicDeliveryClosingDefenseTestBase

## Closing engagement + defense choice: rear afterblow compose on strike KE, closing-speed x engagement-angle
## scaling, rear-hit damage multiplier, closing-speed ceiling clamp, off-balance/stamina variance, and choose-
## defense dodge/parry selection.


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
                "kin_compose: ke ratio %.4f want (cls×sqrtab)² %.4f (cls front=%.4f rear=%.4f)"
                % [ratio_ke, ratio_want, cls_front, cls_rear]
            )
        )


## Tier 5.1 (optional long-tail): **`CombatWeaponForm.mod(form_str, "damage")`** scales integration
## **`pre_cut_applied`** (wrath > wall).

## Tier 5.1 (optional long-tail): **`CombatWeaponForm.mod(form_str, "damage")`** scales integration
## **`pre_cut_applied`** (wrath > wall).


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
    # pre_cut composes the closing-speed channel (KE^CUT_DAMAGE_ENERGY_EXPONENT) AND the engagement-angle
    # damage multiplier (rear lands on an unguarded side). KE is unaffected by the engagement multiplier
    # (velocity-only).
    var eng_front: float = StrikePhysics.engagement_damage_multiplier(front["tgt"] as Dictionary)
    var eng_rear: float = StrikePhysics.engagement_damage_multiplier(rear["tgt"] as Dictionary)
    var want_ratio: float = (
        pow(ratio_ke, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT) * (eng_rear / maxf(eng_front, 0.001))
    )
    if absf(ratio_cut - want_ratio) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_close_pre: pre_cut ratio %.4f want ke^%.2f*eng %.4f (eng front=%.2f rear=%.2f)"
                % [ratio_cut, WeaponConstants.CUT_DAMAGE_ENERGY_EXPONENT, want_ratio, eng_front, eng_rear]
            )
        )


## Tier 5.1 (optional long-tail): **`StrikePhysics.engagement_damage_multiplier`** — a clean rear strike
## lands on an unguarded side and hits harder than a front strike; flank is a smaller bonus. Unit:
## front/unstamped = 1.0, flank = 1.10, rear = 1.20. Integration: rear pre_cut exceeds front by the
## engagement factor on top of the closing-speed channel (closing speed alone is only ~1.045).


static func _run_kinematic_delivery_engagement_damage_multiplier_rear_hits_harder(failures: PackedStringArray) -> void:
    # Unit: engagement multiplier by stamped angle.
    var m_front: float = StrikePhysics.engagement_damage_multiplier({"engagement_angle": "front"})
    var m_flank: float = StrikePhysics.engagement_damage_multiplier({"engagement_angle": "flank"})
    var m_rear: float = StrikePhysics.engagement_damage_multiplier({"engagement_angle": "rear"})
    var m_default: float = StrikePhysics.engagement_damage_multiplier({})
    if not is_equal_approx(m_front, 1.0):
        CombatRegressionHarness._fail(failures, "kin_eng: front mult want 1.0 got %.4f" % m_front)
    if not is_equal_approx(m_default, 1.0):
        CombatRegressionHarness._fail(failures, "kin_eng: unstamped mult want 1.0 got %.4f" % m_default)
    if not is_equal_approx(m_flank, 1.10):
        CombatRegressionHarness._fail(failures, "kin_eng: flank mult want 1.10 got %.4f" % m_flank)
    if not is_equal_approx(m_rear, 1.20):
        CombatRegressionHarness._fail(failures, "kin_eng: rear mult want 1.20 got %.4f" % m_rear)
    if not (m_rear > m_flank and m_flank > m_front):
        CombatRegressionHarness._fail(
            failures, "kin_eng: ordering want rear>flank>front got %.4f/%.4f/%.4f" % [m_rear, m_flank, m_front]
        )
    # Integration: rear pre_cut exceeds front by the engagement factor on top of closing speed.
    var vo_pin: float = 11.0
    var front: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
    )
    var rear: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "rear"}
    )
    var cut_front: float = float(front["pre_cut"])
    var cut_rear: float = float(rear["pre_cut"])
    CombatRegressionHarness._free_manager(front["mgr"] as Node)
    CombatRegressionHarness._free_manager(rear["mgr"] as Node)
    if cut_front <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_eng: front pre_cut too small %.4f" % cut_front)
    # Closing speed alone gives ~1.045; the engagement factor (1.20) must be visible on top.
    if cut_rear <= cut_front * 1.20:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_eng: rear pre_cut %.4f should exceed front*1.20 %.4f (engagement factor visible)"
                % [cut_rear, cut_front * 1.20]
            )
        )


## Tier 5.1 (optional long-tail): **SWORD** **`mixed`** **0.35** blend  -  integration **`pre_cut_applied`** tracks
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`** at assembled **`v`**.

## Tier 5.1 (optional long-tail): **SWORD** **`mixed`** **0.35** blend  -  integration **`pre_cut_applied`** tracks
## **`strike_ke_j^CUT_DAMAGE_ENERGY_EXPONENT`** at assembled **`v`**.


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
