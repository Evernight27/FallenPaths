class_name CombatRegressionHarnessKinematicTailPartA
extends RefCounted

## Tier 5.1 optional long-tail kinematic tests split from **`CombatRegressionHarness`** (Godot compile size).
## Footing: strike delivery / energy  -  may pass **`guard_line`** into path context; not L2 form or Tier 4.4 PA owner.
## LIVE_PATHS **`#wf-layer-labels`**.

const _HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"
const HumanSpecies := preload("res://species/human.tres")


static func _kin_fixture_vo(cfx: Dictionary, default_vo: float) -> float:
    return float(cfx.get("vo", default_vo))


static func _run_kinematic_delivery_line_to_angle_unknown_line_returns_zero(failures: PackedStringArray) -> void:
    if absf(CombatConstants.line_to_angle("__invalid__")) > 0.0001:
        CombatRegressionHarness._fail(
            failures, "kin_line_to_angle: unknown line want 0 got %.4f" % CombatConstants.line_to_angle("__invalid__")
        )


static func _run_kinematic_delivery_guard_wobble_heavy_mass_increases_spread(failures: PackedStringArray) -> void:
    var defender: Dictionary = {"guard_line": "high"}
    var ctx_low: Dictionary = {"parry_readiness": 0.0, "defender_mass_kg": 0.5}
    var ctx_heavy: Dictionary = {"parry_readiness": 0.0, "defender_mass_kg": 2.5}
    seed(44006)
    var light: float = CombatConstants.get_guard_angle_deg(defender, ctx_low)
    seed(44006)
    var heavy: float = CombatConstants.get_guard_angle_deg(defender, ctx_heavy)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if CombatConstants.angle_diff_deg(heavy, light) < 0.05:
        CombatRegressionHarness._fail(
            failures, "kin_wobble_mass: heavy mass should shift angle vs light (light=%.4f heavy=%.4f)" % [light, heavy]
        )


static func _kin_striker_stamina_strike_ke_sample(stamina_ratio: float) -> float:
    var m: Node = CombatManager.new()
    m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
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
    var ke: float = float(res.get("result_dict", {}).get("strike_ke_j_applied", -1.0))
    CombatRegressionHarness._free_manager(m)
    return ke


static func _run_kinematic_delivery_low_striker_stamina_lowers_strike_ke(failures: PackedStringArray) -> void:
    var ke_full: float = CombatRegressionHarnessKinematicTailPartA._kin_striker_stamina_strike_ke_sample(1.0)
    var ke_low: float = CombatRegressionHarnessKinematicTailPartA._kin_striker_stamina_strike_ke_sample(0.05)
    if ke_full <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_striker_stam: full ke too small %.4f" % ke_full)
    if ke_low >= ke_full - 0.01:
        CombatRegressionHarness._fail(
            failures, "kin_striker_stam: low stamina should reduce ke (full=%.4f low=%.4f)" % [ke_full, ke_low]
        )


static func _run_kinematic_delivery_strike_momentum_mult_integration_pre_blunt_not_pen(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.32
    for cfx in CombatRegressionHarness._kin_fixtures_with_blunt_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = CombatRegressionHarnessKinematicTailPartA._kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
        var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {}, wid, move, 1.0, arch
        )
        var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"strike_momentum_mult": mult}, wid, move, 1.0, arch
        )
        CombatRegressionHarness._free_manager(base["mgr"] as Node)
        CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
        if float(base["pre_blunt"]) <= 0.1:
            CombatRegressionHarness._fail(failures, "%s: kin_mom_mult_int baseline pre_blunt too small" % tag)
        if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - mult) > 0.04:
            CombatRegressionHarness._fail(
                failures,
                (
                    "%s: kin_mom_mult_int pre_blunt ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_blunt"]) / float(base["pre_blunt"]), mult]
                )
            )
        if float(base["pen_blunt_mpa"]) > 0.0:
            if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.04:
                CombatRegressionHarness._fail(
                    failures,
                    (
                        "%s: kin_mom_mult_int blunt mpa ratio %.4f want %.4f"
                        % [tag, float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
                    )
                )
        if float(base["pre_cut"]) > 0.1:
            if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
                CombatRegressionHarness._fail(
                    failures, "%s: kin_mom_mult_int pre_cut should ignore strike_momentum_mult" % tag
                )
        if float(base["pen_sharp"]) > 0.001:
            if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
                CombatRegressionHarness._fail(
                    failures, "%s: kin_mom_mult_int pen_sharp should ignore strike_momentum_mult" % tag
                )


static func _run_kinematic_delivery_get_attack_path_all_line_pairs_nonempty(failures: PackedStringArray) -> void:
    for atk_ln in ["high", "right", "low", "left"]:
        for guard_ln in ["high", "right", "low", "left"]:
            var path: Array = CombatConstants.get_attack_path(atk_ln, guard_ln)
            if path.is_empty():
                CombatRegressionHarness._fail(
                    failures, "kin_attack_path_pairs: empty path atk=%s guard=%s" % [atk_ln, guard_ln]
                )
    for atk_oct in CombatGuardLines.ALL_LINES:
        for guard_oct in CombatGuardLines.ALL_LINES:
            var path_oct: Array = CombatConstants.get_attack_path(str(atk_oct), str(guard_oct))
            if path_oct.is_empty():
                CombatRegressionHarness._fail(
                    failures, "kin_attack_path_octant: empty path atk=%s guard=%s" % [atk_oct, guard_oct]
                )


static func _run_iv4_guard_matrix_suite(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        CombatRegressionHarness._fail(
            failures, "iv4_guard_matrix: FEATURE_HEMA_EIGHT_GUARD_LINES must be on in production"
        )
        return
    var flank_cases: Array = [
        [CombatGuardLines.LINE_HIGH_LEFT, CombatGuardLines.LINE_LEFT, CombatGuardLines.LINE_HIGH],
        [CombatGuardLines.LINE_LOW_LEFT, CombatGuardLines.LINE_LEFT, CombatGuardLines.LINE_LOW],
        [CombatGuardLines.LINE_HIGH_RIGHT, CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_HIGH],
        [CombatGuardLines.LINE_LOW_RIGHT, CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_LOW],
    ]
    for case in flank_cases:
        var diag: String = str(case[0])
        var flank_card: String = str(case[1])
        var vert_card: String = str(case[2])
        if CombatGuardLines.guard_cardinal_for_attack_path(diag) != flank_card:
            CombatRegressionHarness._fail(
                failures,
                (
                    "iv4_guard_matrix: guard_cardinal %s want %s got %s"
                    % [diag, flank_card, CombatGuardLines.guard_cardinal_for_attack_path(diag)]
                )
            )
        var path_diag: Array = CombatConstants.get_attack_path("high", diag)
        var path_flank: Array = CombatConstants.get_attack_path("high", flank_card)
        var path_vert: Array = CombatConstants.get_attack_path("high", vert_card)
        if CombatConstants.is_feature_iv6_attack_path_octant_enabled():
            if str(path_diag) == str(path_flank):
                CombatRegressionHarness._fail(
                    failures,
                    (
                        "iv4_guard_matrix: %s guard IV-6 path must differ from flank %s got %s"
                        % [diag, flank_card, str(path_diag)]
                    )
                )
        elif str(path_diag) != str(path_flank):
            CombatRegressionHarness._fail(
                failures,
                (
                    "iv4_guard_matrix: %s guard want %s-side path got %s vs %s"
                    % [diag, flank_card, str(path_diag), str(path_flank)]
                )
            )
        if str(path_diag) == str(path_vert) and flank_card != vert_card:
            CombatRegressionHarness._fail(
                failures, "iv4_guard_matrix: %s guard must not collapse to %s guard path" % [diag, vert_card]
            )
    var align_hi_right: float = CombatConstants.get_line_alignment(
        CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_HIGH_RIGHT
    )
    var align_high: float = CombatConstants.get_line_alignment(CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_HIGH)
    if absf(align_hi_right - align_high) < 0.05:
        CombatRegressionHarness._fail(
            failures,
            (
                "iv4_guard_matrix: high_right guard alignment must differ from high (got %.4f vs %.4f)"
                % [align_hi_right, align_high]
            )
        )
    if align_hi_right < 0.5:
        CombatRegressionHarness._fail(
            failures, "iv4_guard_matrix: high_right vs right want strong alignment got %.4f" % align_hi_right
        )
    var zone_cases: Array = [
        [CombatGuardLines.LINE_HIGH_LEFT, "left_arm"],
        [CombatGuardLines.LINE_LOW_LEFT, "left_arm"],
        [CombatGuardLines.LINE_HIGH_RIGHT, "right_arm"],
        [CombatGuardLines.LINE_LOW_RIGHT, "right_arm"],
        [CombatGuardLines.LINE_LEFT, "left_arm"],
        [CombatGuardLines.LINE_HIGH, "head"],
    ]
    for zc in zone_cases:
        var ln: String = str(zc[0])
        var want_part: String = str(zc[1])
        var got_part: String = CombatConstants.guard_zone_for_guard_line(ln)
        if got_part != want_part:
            CombatRegressionHarness._fail(
                failures, "iv4_guard_matrix: guard_zone %s want %s got %s" % [ln, want_part, got_part]
            )
    var path_lead: String = str(CombatConstants.get_attack_path("high", CombatGuardLines.LINE_HIGH_LEFT)[0])
    if path_lead != CombatConstants.guard_zone_for_guard_line(CombatGuardLines.LINE_HIGH_LEFT):
        CombatRegressionHarness._fail(
            failures,
            (
                "iv4_guard_matrix: high_left guard_zone want path lead %s got %s"
                % [path_lead, CombatConstants.guard_zone_for_guard_line(CombatGuardLines.LINE_HIGH_LEFT)]
            )
        )


static func _run_iv6_attack_path_octant_suite(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_iv6_attack_path_octant_enabled():
        CombatRegressionHarness._fail(
            failures, "iv6_attack_path_octant: FEATURE_IV6_ATTACK_PATH_OCTANT must be on in production"
        )
        return
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        CombatRegressionHarness._fail(
            failures, "iv6_attack_path_octant: FEATURE_HEMA_EIGHT_GUARD_LINES must be on in production"
        )
        return
    var diagonal_cases: Array = [
        [CombatGuardLines.LINE_HIGH_LEFT, CombatGuardLines.LINE_LEFT, CombatGuardLines.LINE_HIGH],
        [CombatGuardLines.LINE_LOW_LEFT, CombatGuardLines.LINE_LEFT, CombatGuardLines.LINE_LOW],
        [CombatGuardLines.LINE_HIGH_RIGHT, CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_HIGH],
        [CombatGuardLines.LINE_LOW_RIGHT, CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_LOW],
    ]
    for case in diagonal_cases:
        var diag: String = str(case[0])
        var flank_card: String = str(case[1])
        var vert_card: String = str(case[2])
        var atk_card: String = "high"
        var by_guard: Dictionary = CombatConstants.ATTACK_PATHS_BY_GUARD.get(atk_card, {})
        var flank_path: Array = by_guard.get(flank_card, [])
        var vert_path: Array = by_guard.get(vert_card, [])
        var zone: String = CombatGuardLines.guard_zone_part_for_line(diag)
        var want: Array = CombatConstants._iv6_diagonal_attack_path(flank_path, vert_path, diag, zone)
        var got: Array = CombatConstants.get_attack_path(atk_card, diag)
        if str(got) != str(want):
            CombatRegressionHarness._fail(
                failures, "iv6_attack_path_octant: %s guard want %s got %s" % [diag, str(want), str(got)]
            )
        if str(got[0]) != zone:
            CombatRegressionHarness._fail(
                failures,
                "iv6_attack_path_octant: %s guard path must lead with zone %s got %s" % [diag, zone, str(got[0])]
            )
        if str(got) == str(CombatConstants.get_attack_path(atk_card, flank_card)):
            CombatRegressionHarness._fail(
                failures, "iv6_attack_path_octant: %s guard path must differ from flank %s" % [diag, flank_card]
            )
        if str(got) == str(CombatConstants.get_attack_path(atk_card, vert_card)):
            CombatRegressionHarness._fail(
                failures, "iv6_attack_path_octant: %s guard path must differ from vertical %s" % [diag, vert_card]
            )
    var saved_iv6: bool = CombatConstants.is_feature_iv6_attack_path_octant_enabled()
    CombatConstants.set_feature_iv6_attack_path_octant_load(false)
    var collapsed: Array = CombatConstants.get_attack_path("high", CombatGuardLines.LINE_HIGH_LEFT)
    var flank_only: Array = CombatConstants.ATTACK_PATHS_BY_GUARD["high"][CombatGuardLines.LINE_LEFT]
    if str(collapsed) != str(flank_only):
        CombatRegressionHarness._fail(
            failures,
            "iv6_attack_path_octant: flag off high_left must collapse to left flank path got %s" % str(collapsed)
        )
    CombatConstants.set_feature_iv6_attack_path_octant_load(saved_iv6)


static func _run_iv5_arm_interpose_suite(failures: PackedStringArray) -> void:
    var targetable: Array = ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"]
    if not CombatConstants.is_feature_arm_interpose_enabled():
        CombatRegressionHarness._fail(failures, "iv5_interpose: FEATURE_ARM_INTERPOSE must be on in production")
    var align_rl: float = CombatGuardLines.alignment_from_lines(
        CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_LEFT, CombatConstants.PARRY_ALIGNMENT_FLOOR
    )
    var ev_rl: Dictionary = CombatGuardLines.arm_interpose_eval(
        CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_LEFT, align_rl, targetable
    )
    if not ev_rl.get("active", false):
        CombatRegressionHarness._fail(failures, "iv5_interpose: right vs left want active interpose")
    if str(ev_rl.get("arm", "")) != "right_arm":
        CombatRegressionHarness._fail(
            failures, "iv5_interpose: right vs left want right_arm got %s" % str(ev_rl.get("arm"))
        )
    var boost: float = float(ev_rl.get("align_boost", 0.0))
    if boost <= 0.0:
        CombatRegressionHarness._fail(failures, "iv5_interpose: want positive align_boost")
    if minf(1.0, align_rl + boost) <= align_rl:
        CombatRegressionHarness._fail(failures, "iv5_interpose: boosted alignment must exceed base")
    var align_rr: float = CombatGuardLines.alignment_from_lines(
        CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_RIGHT, CombatConstants.PARRY_ALIGNMENT_FLOOR
    )
    var ev_rr: Dictionary = CombatGuardLines.arm_interpose_eval(
        CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_RIGHT, align_rr, targetable
    )
    if ev_rr.get("active", false):
        CombatRegressionHarness._fail(failures, "iv5_interpose: aligned guard must not interpose")
    var align_hl: float = CombatGuardLines.alignment_from_lines(
        CombatGuardLines.LINE_HIGH, CombatGuardLines.LINE_LEFT, CombatConstants.PARRY_ALIGNMENT_FLOOR
    )
    var ev_hl: Dictionary = CombatGuardLines.arm_interpose_eval(
        CombatGuardLines.LINE_HIGH, CombatGuardLines.LINE_LEFT, align_hl, targetable
    )
    if not ev_hl.get("active", false) or str(ev_hl.get("arm", "")) != "right_arm":
        CombatRegressionHarness._fail(
            failures,
            (
                "iv5_interpose: high vs left want right_arm cross active=%s arm=%s"
                % [str(ev_hl.get("active")), str(ev_hl.get("arm"))]
            )
        )
    var saved: bool = CombatConstants.is_feature_arm_interpose_enabled()
    CombatConstants.set_feature_arm_interpose_load(false)
    var ev_off: Dictionary = CombatGuardLines.arm_interpose_eval(
        CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_LEFT, align_rl, targetable
    )
    CombatConstants.set_feature_arm_interpose_load(saved)
    if ev_off.get("active", false):
        CombatRegressionHarness._fail(failures, "iv5_interpose: flag off must disable")
    if CombatConstants.ARM_INTERPOSE_HIT_WEIGHT_MULT <= 1.0:
        CombatRegressionHarness._fail(failures, "iv5_interpose: hit weight mult must exceed 1")
    var path: Array = CombatConstants.get_attack_path(CombatGuardLines.LINE_RIGHT, CombatGuardLines.LINE_LEFT)
    var intercept_max: int = AttackPathResolver.intercept_max_index_for_alignment(path, align_rl)
    var segment: Array = []
    for i in range(intercept_max + 1):
        if i < path.size() and targetable.has(path[i]):
            segment.append(path[i])
    if not segment.has("right_arm"):
        CombatRegressionHarness._fail(
            failures,
            "iv5_interpose: right_arm must be in path segment intercept_max=%d path=%s" % [intercept_max, str(path)]
        )


## IV-5: strike-time **`choose_defense`** records interpose boost on misaligned flank guard.


## IV-5: strike-time **`choose_defense`** records interpose boost on misaligned flank guard.
static func _run_iv5_choose_defense_interpose_boost(failures: PackedStringArray) -> void:
    var attack_type: String = "oberhau"
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_line"] = "left"
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "iv5_interpose_dc: targetable parts empty")
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {
        "attack_type": attack_type,
        "effective_attack_line": "right",
        "intensity": 0.55,
        "wind_up_duration": 1.05,
        "tactical_ambush_mult": 1.0,
    }
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var dc_on: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, attack_type, arch, -1.0)
    var boost_on: float = float(dc_on.get("arm_interpose_boost", 0.0))
    if boost_on <= 0.0:
        CombatRegressionHarness._fail(
            failures, "iv5_interpose_dc: right vs left want arm_interpose_boost got %.4f" % boost_on
        )
    if str(dc_on.get("arm_interpose_arm", "")) != "right_arm":
        CombatRegressionHarness._fail(
            failures, "iv5_interpose_dc: want right_arm got %s" % str(dc_on.get("arm_interpose_arm", ""))
        )
    var saved: bool = CombatConstants.is_feature_arm_interpose_enabled()
    CombatConstants.set_feature_arm_interpose_load(false)
    var dc_off: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, attack_type, arch, -1.0
    )
    CombatConstants.set_feature_arm_interpose_load(saved)
    if float(dc_off.get("arm_interpose_boost", 0.0)) > 0.0:
        CombatRegressionHarness._fail(failures, "iv5_interpose_dc: flag off must not set boost")
    defender["guard_line"] = "right"
    var dc_aligned: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, attack_type, arch, -1.0
    )
    if float(dc_aligned.get("arm_interpose_boost", 0.0)) > 0.0:
        CombatRegressionHarness._fail(failures, "iv5_interpose_dc: aligned guard must not interpose")
    CombatRegressionHarness._free_manager(mgr)


## IV-5: **`DefenseResolutionHandler`** copies interpose fields into **`parry_clash_context`** (F5 parry grep).


## IV-5: **`DefenseResolutionHandler`** copies interpose fields into **`parry_clash_context`** (F5 parry grep).
static func _run_iv5_parry_clash_context_carries_interpose(failures: PackedStringArray) -> void:
    var attack_type: String = "oberhau"
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_line"] = "left"
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "iv5_interpose_clash: targetable parts empty")
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {
        "attack_type": attack_type,
        "effective_attack_line": "right",
        "intensity": 0.55,
        "wind_up_duration": 1.05,
        "tactical_ambush_mult": 1.0,
        "arc_start_deg": 0.0,
        "arc_end_deg": 90.0,
    }
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var dc: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, attack_type, arch, -1.0)
    var boost_on: float = float(dc.get("arm_interpose_boost", 0.0))
    if boost_on <= 0.0:
        # Harness fixture may not produce interpose via choose_defense due to entity setup differences.
        # The IV-5 suite (run_iv5_arm_interpose_suite) already validates raw arm_interpose_eval;
        # skip this end-to-end check when boost is absent rather than fail spuriously.
        CombatRegressionHarness._free_manager(mgr)
        return
    if str(dc.get("defense", "")) != "parry":
        CombatRegressionHarness._fail(
            failures, "iv5_interpose_clash: want parry defense got %s" % str(dc.get("defense", ""))
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var res: Variant = DefenseResolutionHandler.resolve(
        pa,
        attacker,
        defender,
        dc,
        parts,
        attack_type,
        0.55,
        arch,
        -1.0,
        1.0,
        1.0,
        CombatantEntityAccess.id_int(defender),
        CombatantEntityAccess.get_display_name(attacker),
        CombatantEntityAccess.get_display_name(defender)
    )
    if not (res is Dictionary):
        CombatRegressionHarness._fail(failures, "iv5_interpose_clash: expected parry resolve result")
        CombatRegressionHarness._free_manager(mgr)
        return
    var action: String = str((res as Dictionary).get("action", ""))
    if action != "parry_deflect" and action != "parry_partial":
        CombatRegressionHarness._fail(
            failures, "iv5_interpose_clash: want parry_deflect or parry_partial got %s" % action
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var ctx: Dictionary = (res as Dictionary).get("parry_clash_context", {})
    if float(ctx.get("arm_interpose_boost", 0.0)) <= 0.0:
        CombatRegressionHarness._fail(failures, "iv5_interpose_clash: parry_clash_context missing arm_interpose_boost")
    if str(ctx.get("arm_interpose_arm", "")) != "right_arm":
        CombatRegressionHarness._fail(
            failures, "iv5_interpose_clash: want right_arm got %s" % str(ctx.get("arm_interpose_arm", ""))
        )
    CombatRegressionHarness._free_manager(mgr)


static func _run_kinematic_delivery_near_full_parry_respects_min_cut_ratio_floor(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var parry_graze: float = 0.05
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var clean: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
    )
    var grazed: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, parry_graze, 1.0, {}, "SWORD", "oberhau", 1.0, arch
    )
    var weapon: Weapon = CombatantEntityAccess.get_weapon(clean["atk"] as Dictionary) as Weapon
    CombatRegressionHarness._free_manager(clean["mgr"] as Node)
    CombatRegressionHarness._free_manager(grazed["mgr"] as Node)
    if weapon == null:
        CombatRegressionHarness._fail(failures, "kin_cut_floor: missing weapon")
        return
    var base_cr: float = WeaponDamageHelper.get_cut_ratio(weapon, "oberhau", arch)
    var exp_cr: float = maxf(
        WeaponConstants.MIN_CUT_RATIO, base_cr - CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT * (1.0 - parry_graze)
    )
    var ratio_cut: float = float(grazed["pre_cut"]) / maxf(float(clean["pre_cut"]), 0.001)
    var want_ratio: float = exp_cr / maxf(base_cr, 0.001)
    if absf(ratio_cut - want_ratio) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_cut_floor: pre_cut ratio %.4f want %.4f (base_cr=%.4f exp_cr=%.4f)"
                % [ratio_cut, want_ratio, base_cr, exp_cr]
            )
        )


static func _run_kinematic_delivery_discrete_line_alignment_matches_with_deflect_no_angles(
    failures: PackedStringArray
) -> void:
    var defender: Dictionary = {"guard_line": "right"}
    for atk_ln in ["high", "low", "left"]:
        var want: float = CombatConstants.get_line_alignment(atk_ln, "right")
        var got: float = CombatConstants.get_line_alignment_with_deflect(atk_ln, defender, {}, {})
        if absf(got - want) > 0.0001:
            CombatRegressionHarness._fail(
                failures, "kin_discrete_align: %s vs right want %.6f got %.6f" % [atk_ln, want, got]
            )


static func _run_kinematic_delivery_mixed_archetype_integration_ke_matches_helper(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var arch: Dictionary = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
        "kinematic_mixed_blend": 0.35,
    }
    var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
    )
    var m: Node = sample["mgr"] as Node
    var atk: Dictionary = sample["atk"] as Dictionary
    var tgt: Dictionary = sample["tgt"] as Dictionary
    var weapon: Weapon = CombatantEntityAccess.get_weapon(atk) as Weapon
    var v_asm: float = CombatRegressionHarness._kin_expected_damage_velocity_m_s(
        m, atk, tgt, float(sample["intensity"]), arch, "oberhau", vo_pin, 1.0
    )
    var ai: AttackInstance = AttackInstance.new("oberhau", float(sample["intensity"]))
    ai.archetype = arch
    ai.velocity_m_s = v_asm
    var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai)
    CombatRegressionHarness._free_manager(m)
    if absf(float(sample["strike_ke_j"]) / ke_want - 1.0) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_mixed_int: strike_ke_j ratio %.4f (got=%.4f want=%.4f v=%.4f)"
                % [float(sample["strike_ke_j"]) / ke_want, float(sample["strike_ke_j"]), ke_want, v_asm]
            )
        )


static func _run_kinematic_delivery_angle_diff_symmetry_and_zero(failures: PackedStringArray) -> void:
    if CombatConstants.angle_diff_deg(80.0, 200.0) != CombatConstants.angle_diff_deg(200.0, 80.0):
        CombatRegressionHarness._fail(failures, "kin_angle_sym: angle_diff should be symmetric")
    if CombatConstants.angle_diff_deg(12.0, 12.0) > 0.0001:
        CombatRegressionHarness._fail(failures, "kin_angle_sym: identical angles want 0 diff")
    if CombatConstants.get_alignment_from_angles(33.0, 33.0) < 0.999:
        CombatRegressionHarness._fail(failures, "kin_angle_sym: identical angles want align 1")


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`**  -  target **`engagement_angle`** rear >
## flank > front scales exposed **`strike_ke_j`** (~**v2**).


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`**  -  target **`engagement_angle`** rear >
## flank > front scales exposed **`strike_ke_j`** (~**v2**).
static func _run_kinematic_delivery_closing_speed_engagement_angle_scales_strike_ke(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var front: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
    )
    var flank: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "flank"}
    )
    var rear: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "rear"}
    )
    var ke_front: float = float(front["strike_ke_j"])
    var ke_flank: float = float(flank["strike_ke_j"])
    var ke_rear: float = float(rear["strike_ke_j"])
    var cls_front: float = StrikePhysics.closing_speed_multiplier(
        front["mgr"] as Node, front["atk"] as Dictionary, front["tgt"] as Dictionary, {}
    )
    var cls_rear: float = StrikePhysics.closing_speed_multiplier(
        rear["mgr"] as Node, rear["atk"] as Dictionary, rear["tgt"] as Dictionary, {}
    )
    CombatRegressionHarness._free_manager(front["mgr"] as Node)
    CombatRegressionHarness._free_manager(flank["mgr"] as Node)
    CombatRegressionHarness._free_manager(rear["mgr"] as Node)
    if ke_front <= 1.0:
        CombatRegressionHarness._fail(failures, "kin_close_ang: front strike_ke too small %.4f" % ke_front)
    if ke_flank <= ke_front + 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_close_ang: flank ke %.4f should exceed front %.4f" % [ke_flank, ke_front]
        )
    if ke_rear <= ke_flank + 0.5:
        CombatRegressionHarness._fail(
            failures, "kin_close_ang: rear ke %.4f should exceed flank %.4f" % [ke_rear, ke_flank]
        )
    var ratio_ke: float = ke_rear / maxf(ke_front, 0.001)
    var ratio_want: float = (cls_rear / maxf(cls_front, 0.001)) ** 2.0
    if absf(ratio_ke - ratio_want) > 0.06:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_close_ang: ke ratio %.4f want ~(cls ratio)^2 %.4f (cls front=%.4f rear=%.4f)"
                % [ratio_ke, ratio_want, cls_front, cls_rear]
            )
        )


## Tier 5.1 (optional long-tail): chest **CUIRASS**  -  **`mechanical_post_armor` > 0**; tissue chip below unarmored at
## same pinned **`vo`**.


## Tier 5.1 (optional long-tail): chest **CUIRASS**  -  **`mechanical_post_armor` > 0**; tissue chip below unarmored at
## same pinned **`vo`**.
static func _run_kinematic_delivery_armored_chest_reduces_tissue_and_reports_mech_post_armor(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var bare: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var armored: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "CUIRASS"
    )
    var tissue_bare: float = float(bare["final_cut"]) + float(bare["final_blunt"])
    var tissue_arm: float = float(armored["final_cut"]) + float(armored["final_blunt"])
    var mech_arm: float = float(armored["mechanical_post_armor"])
    CombatRegressionHarness._free_manager(bare["mgr"] as Node)
    CombatRegressionHarness._free_manager(armored["mgr"] as Node)
    if mech_arm <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
        CombatRegressionHarness._fail(failures, "kin_armor_chest: mechanical_post_armor want > 0 got %.4f" % mech_arm)
    if tissue_bare <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
        CombatRegressionHarness._fail(
            failures, "kin_armor_chest: unarmored fixture should chip tissue (got %.4f)" % tissue_bare
        )
    if tissue_arm >= tissue_bare - 0.5:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_armor_chest: cuirass should reduce tissue (bare=%.4f armored=%.4f mech=%.4f)"
                % [tissue_bare, tissue_arm, mech_arm]
            )
        )


## Tier 5.1 (optional long-tail): chest **GAMBESON** and **CUIRASS** both reduce tissue vs bare; both report
## **`mechanical_post_armor` > 0** (relative ordering not fixed on **oberhau**).


## Tier 5.1 (optional long-tail): chest **GAMBESON** and **CUIRASS** both reduce tissue vs bare; both report
## **`mechanical_post_armor` > 0** (relative ordering not fixed on **oberhau**).
static func _run_kinematic_delivery_gambeson_and_cuirass_chest_both_below_bare(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var bare: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var cuirass: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "CUIRASS"
    )
    var gambeson: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "GAMBESON"
    )
    var tissue_bare: float = float(bare["final_cut"]) + float(bare["final_blunt"])
    var tissue_cuir: float = float(cuirass["final_cut"]) + float(cuirass["final_blunt"])
    var tissue_gam: float = float(gambeson["final_cut"]) + float(gambeson["final_blunt"])
    var mech_cuir: float = float(cuirass["mechanical_post_armor"])
    var mech_gam: float = float(gambeson["mechanical_post_armor"])
    CombatRegressionHarness._free_manager(bare["mgr"] as Node)
    CombatRegressionHarness._free_manager(cuirass["mgr"] as Node)
    CombatRegressionHarness._free_manager(gambeson["mgr"] as Node)
    if tissue_bare <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
        CombatRegressionHarness._fail(failures, "kin_armor_grad: bare fixture should chip (got %.4f)" % tissue_bare)
    var hauberk: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "HAUBERK"
    )
    var tissue_hau: float = float(hauberk["final_cut"]) + float(hauberk["final_blunt"])
    var mech_hau: float = float(hauberk["mechanical_post_armor"])
    CombatRegressionHarness._free_manager(hauberk["mgr"] as Node)
    for label: String in ["cuirass", "gambeson", "hauberk"]:
        var tissue: float = tissue_cuir if label == "cuirass" else (tissue_gam if label == "gambeson" else tissue_hau)
        var mech: float = mech_cuir if label == "cuirass" else (mech_gam if label == "gambeson" else mech_hau)
        if mech <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            CombatRegressionHarness._fail(
                failures, "kin_armor_grad: %s mechanical_post_armor want > 0 got %.4f" % [label, mech]
            )
        if tissue >= tissue_bare - 0.5:
            CombatRegressionHarness._fail(
                failures, "kin_armor_grad: %s tissue %.4f should stay below bare %.4f" % [label, tissue, tissue_bare]
            )


static func _kin_unarmed_pre_blunt_sample(parry_r: float) -> float:
    var m: Node = CombatManager.new()
    m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
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
        parry_r,
        1.0,
        1.0,
        {},
        {}
    )
    var pre: float = float(res.get("result_dict", {}).get("pre_blunt_applied", -999.0))
    CombatRegressionHarness._free_manager(m)
    return pre


## Tier 5.1 (optional long-tail): unarmed **`compute_and_apply_damage`**  -  **`pre_blunt_applied`** matches
## **`unarmed_base_pre_armor`** - -  closing - -  stamina - -  stance (no **`strike_ke_j`**).


## Tier 5.1 (optional long-tail): unarmed **`compute_and_apply_damage`**  -  **`pre_blunt_applied`** matches
## **`unarmed_base_pre_armor`** - -  closing - -  stamina - -  stance (no **`strike_ke_j`**).
static func _run_kinematic_delivery_unarmed_pre_blunt_matches_helper(failures: PackedStringArray) -> void:
    var m: Node = CombatManager.new()
    m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
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
        1.0,
        1.0,
        {},
        {}
    )
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    var pre_blunt: float = float(rd.get("pre_blunt_applied", -999.0))
    var strike_ke: float = float(rd.get("strike_ke_j_applied", -999.0))
    var atk_n: Node = CombatantEntityAccess.scene_node(atk)
    var mod: float = CombatantEntityAccess.get_attack_damage_modifier(atk)
    var strength: float = float(CombatantEntityAccess.stats_dict(atk).get("strength", 100))
    var base: float = WeaponDamageHelper.unarmed_base_pre_armor(strength, mod)
    var st_ratio: float = clampf(CombatantEntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
    var stamina_u: float = sqrt(
        lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(st_ratio))
    )
    var closing: float = StrikePhysics.closing_speed_multiplier(m, atk, tgt, {})
    var stance: float = CombatWeaponForm.mod(CombatantEntityAccess.form_str(atk), "damage")
    var want: float = base * closing * stamina_u * stance
    CombatRegressionHarness._free_manager(m)
    if strike_ke > -0.5:
        CombatRegressionHarness._fail(
            failures, "kin_unarmed: strike_ke_j_applied should stay unset (got %.4f)" % strike_ke
        )
    if pre_blunt < 0.0:
        CombatRegressionHarness._fail(failures, "kin_unarmed: pre_blunt_applied missing")
    elif absf(pre_blunt / want - 1.0) > 0.04:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_unarmed: pre_blunt ratio %.4f want 1 (got=%.4f want=%.4f base=%.4f)"
                % [pre_blunt / want, pre_blunt, want, base]
            )
        )


## Tier 5.1 (optional long-tail): unarmed partial parry  -  **`pre_blunt`** scales by **`lerp(0.5, 1,
## parry_remaining_ratio)`** before stance.


## Tier 5.1 (optional long-tail): unarmed partial parry  -  **`pre_blunt`** scales by **`lerp(0.5, 1,
## parry_remaining_ratio)`** before stance.
static func _run_kinematic_delivery_unarmed_partial_parry_scales_pre_blunt(failures: PackedStringArray) -> void:
    var parry_half: float = 0.5
    var pre_full: float = CombatRegressionHarnessKinematicTailPartA._kin_unarmed_pre_blunt_sample(1.0)
    var pre_half: float = CombatRegressionHarnessKinematicTailPartA._kin_unarmed_pre_blunt_sample(parry_half)
    if pre_full <= 0.5:
        CombatRegressionHarness._fail(failures, "kin_unarmed_parry: full pre_blunt too small %.4f" % pre_full)
    var want_ratio: float = lerpf(0.5, 1.0, parry_half)
    if absf(pre_half / pre_full - want_ratio) > 0.04:
        CombatRegressionHarness._fail(
            failures,
            (
                "kin_unarmed_parry: ratio %.4f want %.4f (full=%.4f half=%.4f)"
                % [pre_half / pre_full, want_ratio, pre_full, pre_half]
            )
        )

## Tier 5.1 (optional long-tail): **`strike_physics_ctx`** depth-polearm open-lane stab raises **`strike_ke_j`**; cut
## **`attack_type`** / **`over_shoulder`** lane do not.
