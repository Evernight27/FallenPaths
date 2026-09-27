class_name KinematicDeliveryPenetrationTests
extends CombatRegressionHarnessCore


## Tier 5.1 (optional long-tail): **`AttackResolver.penetration_oblique_angle_factor`** matches parry vs
## misaligned-guard **`lerp`** rules; **`velocity_override` < 0** -> **1** (no penetration oblique here).
## When `parry_remaining_ratio` < 1 the parry branch wins (alignment is not compounded).
static func _run_kinematic_delivery_penetration_oblique_angle_factor_attack_resolver(
    failures: PackedStringArray
) -> void:
    var tol: float = 0.00001
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    var f_neg: float = AttackResolver.penetration_oblique_angle_factor(-1.0, 0.0, 0.0)
    if absf(f_neg - 1.0) > tol:
        _fail(failures, "kin_oblique: vo<0 should be 1 got %.6f" % f_neg)
    var f_clean: float = AttackResolver.penetration_oblique_angle_factor(10.0, 1.0, 1.0)
    if absf(f_clean - 1.0) > tol:
        _fail(failures, "kin_oblique: full parry+align should be 1 got %.6f" % f_clean)
    var f_parry_half: float = AttackResolver.penetration_oblique_angle_factor(0.0, 0.5, 1.0)
    var w_parry_half: float = lerpf(1.0, amin, 0.5)
    if absf(f_parry_half - w_parry_half) > tol:
        _fail(failures, "kin_oblique: parry 0.5 want %.6f got %.6f" % [w_parry_half, f_parry_half])
    var f_align_edge: float = AttackResolver.penetration_oblique_angle_factor(5.0, 1.0, 0.0)
    var w_align: float = lerpf(1.0, amin, ascale)
    if absf(f_align_edge - w_align) > tol:
        _fail(failures, "kin_oblique: align 0 parry=1 want %.6f got %.6f" % [w_align, f_align_edge])
    var f_parry_zero: float = AttackResolver.penetration_oblique_angle_factor(5.0, 0.0, 1.0)
    var w_pz: float = lerpf(1.0, amin, 1.0)
    if absf(f_parry_zero - w_pz) > tol:
        _fail(failures, "kin_oblique: parry 0 want %.6f got %.6f" % [w_pz, f_parry_zero])
    var f_parry_wins: float = AttackResolver.penetration_oblique_angle_factor(5.0, 0.25, 0.0)
    var w_pw: float = lerpf(1.0, amin, 0.75)
    if absf(f_parry_wins - w_pw) > tol:
        _fail(
            failures, "kin_oblique: parry 0.25+align0 should use parry branch want %.6f got %.6f" % [w_pw, f_parry_wins]
        )
    var f_align_mid: float = AttackResolver.penetration_oblique_angle_factor(3.0, 1.0, 0.5)
    var w_mid: float = lerpf(1.0, amin, (1.0 - 0.5) * ascale)
    if absf(f_align_mid - w_mid) > tol:
        _fail(failures, "kin_oblique: align 0.5 want %.6f got %.6f" % [w_mid, f_align_mid])


## Shared Tier **5.1** harness helper: one **`compute_and_apply_damage`** hit with meta-exposed pens (fresh manager each
## call).


## Shared Tier **5.1** harness helper: one **`compute_and_apply_damage`** hit with meta-exposed pens (fresh manager each
## call).
static func _kin_dmg_pen_sample(vo: float, parry_r: float, align: float, strike_mods: Dictionary) -> Vector2:
    var intensity: float = 0.62
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var m: Node = MgrScript.new()
    m.set_meta(HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
    m.register(_new_entity("SWORD"), "player")
    m.register(_new_entity("SWORD"), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    var aid: int = EntityAccess.id_int(atk)
    var tid: int = EntityAccess.id_int(tgt)
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        aid,
        tid,
        atk,
        tgt,
        "chest",
        intensity,
        "oberhau",
        arch,
        vo,
        1.0,
        1.0,
        -1.0,
        -1.0,
        parry_r,
        1.0,
        align,
        strike_mods,
        {}
    )
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    var ps: float = float(rd.get("penetration_sharp_applied", -999.0))
    var pb: float = float(rd.get("penetration_blunt_mpa_applied", -999.0))
    _free_manager(m)
    return Vector2(ps, pb)


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** applies the same oblique factor to **SHARP** /
## **BLUNT** penetration as **`penetration_oblique_angle_factor`** (fresh manager per sample; manager meta
## **`_harness_expose_penetration_applied`** -> **`penetration_sharp_applied`** / **`penetration_blunt_mpa_applied`** on
## **`result_dict`**).


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** applies the same oblique factor to **SHARP** /
## **BLUNT** penetration as **`penetration_oblique_angle_factor`** (fresh manager per sample; manager meta
## **`_harness_expose_penetration_applied`** -> **`penetration_sharp_applied`** / **`penetration_blunt_mpa_applied`** on
## **`result_dict`**).
static func _run_kinematic_delivery_compute_damage_oblique_penetration_integration(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    var want_parry_half: float = lerpf(1.0, amin, 0.5)
    var want_align_zero: float = lerpf(1.0, amin, ascale)

    var base: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {})
    if base.x <= 0.001:
        _fail(failures, "kin_dmg_pen: baseline pen_sharp too small %.6f" % base.x)
    if base.y <= 0.0:
        _fail(failures, "kin_dmg_pen: baseline pen_blunt_mpa invalid %.6f" % base.y)

    var parry_half: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {})
    var r_ps_ph: float = parry_half.x / base.x
    var r_pb_ph: float = parry_half.y / base.y
    if absf(r_ps_ph - want_parry_half) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: parry 0.5 sharp ratio %.4f want %.4f (base=%.4f half=%.4f)"
                % [r_ps_ph, want_parry_half, base.x, parry_half.x]
            )
        )
    if absf(r_pb_ph - want_parry_half) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: parry 0.5 blunt mpa ratio %.4f want %.4f (base=%.4f half=%.4f)"
                % [r_pb_ph, want_parry_half, base.y, parry_half.y]
            )
        )

    var align_zero: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 0.0, {})
    var r_ps_az: float = align_zero.x / base.x
    var r_pb_az: float = align_zero.y / base.y
    if absf(r_ps_az - want_align_zero) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: align 0 sharp ratio %.4f want %.4f (base=%.4f az=%.4f)"
                % [r_ps_az, want_align_zero, base.x, align_zero.x]
            )
        )
    if absf(r_pb_az - want_align_zero) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: align 0 blunt mpa ratio %.4f want %.4f (base=%.4f az=%.4f)"
                % [r_pb_az, want_align_zero, base.y, align_zero.y]
            )
        )

    var base_der: Vector2 = _kin_dmg_pen_sample(-1.0, 1.0, 1.0, {})
    var parry_der: Vector2 = _kin_dmg_pen_sample(-1.0, 0.5, 1.0, {})
    if base_der.x <= 0.001:
        _fail(failures, "kin_dmg_pen: derived-v baseline pen_sharp too small %.6f" % base_der.x)
    if absf(parry_der.x / base_der.x - 1.0) > 0.02 or absf(parry_der.y / base_der.y - 1.0) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: vo<0 parry 0.5 should not scale pens (base s=%.4f b=%.4f vs half s=%.4f b=%.4f)"
                % [base_der.x, base_der.y, parry_der.x, parry_der.y]
            )
        )


## Tier 5.1 (optional long-tail): **`strike_mods`**  -  **`sharp_penetration_mult`** / **`blunt_momentum_pa_mult`**
## scale applied pens in **`compute_and_apply_damage`** (orthogonal; compose after oblique); **`cut_damage_mult`** /
## **`blunt_damage_mult`** do not (full hit or partial parry  -  **`_kin_dmg_pen_sample`**).


## Tier 5.1 (optional long-tail): **`strike_mods`**  -  **`sharp_penetration_mult`** / **`blunt_momentum_pa_mult`**
## scale applied pens in **`compute_and_apply_damage`** (orthogonal; compose after oblique); **`cut_damage_mult`** /
## **`blunt_damage_mult`** do not (full hit or partial parry  -  **`_kin_dmg_pen_sample`**).
static func _run_kinematic_delivery_compute_damage_strike_mods_penetration_integration(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var mult_sharp: float = 1.35
    var mult_blunt: float = 1.22
    var base: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {})
    if base.x <= 0.001:
        _fail(failures, "kin_dmg_pen_sm: baseline pen_sharp too small %.6f" % base.x)
    if base.y <= 0.0:
        _fail(failures, "kin_dmg_pen_sm: baseline pen_blunt_mpa invalid %.6f" % base.y)
    var only_sharp: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {"sharp_penetration_mult": mult_sharp})
    if absf(only_sharp.x / base.x - mult_sharp) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: sharp mult ratio %.4f want %.4f (base=%.4f sm=%.4f)"
                % [only_sharp.x / base.x, mult_sharp, base.x, only_sharp.x]
            )
        )
    if absf(only_sharp.y / base.y - 1.0) > 0.02:
        _fail(failures, "kin_dmg_pen_sm: sharp mult should not scale blunt mpa (ratio %.4f)" % (only_sharp.y / base.y))
    var only_blunt: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {"blunt_momentum_pa_mult": mult_blunt})
    if absf(only_blunt.x / base.x - 1.0) > 0.02:
        _fail(failures, "kin_dmg_pen_sm: blunt mult should not scale sharp pen (ratio %.4f)" % (only_blunt.x / base.x))
    if absf(only_blunt.y / base.y - mult_blunt) > 0.02:
        _fail(failures, "kin_dmg_pen_sm: blunt mpa mult ratio %.4f want %.4f" % [only_blunt.y / base.y, mult_blunt])
    var both: Vector2 = _kin_dmg_pen_sample(
        vo_pin, 1.0, 1.0, {"sharp_penetration_mult": mult_sharp, "blunt_momentum_pa_mult": mult_blunt}
    )
    if absf(both.x / base.x - mult_sharp) > 0.02 or absf(both.y / base.y - mult_blunt) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: both mults want sharp×%.2f blunt×%.2f got ratios %.4f %.4f"
                % [mult_sharp, mult_blunt, both.x / base.x, both.y / base.y]
            )
        )
    var half_base: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {})
    var half_sharp: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {"sharp_penetration_mult": mult_sharp})
    if half_base.x <= 0.001:
        _fail(failures, "kin_dmg_pen_sm: oblique baseline pen_sharp too small %.6f" % half_base.x)
    if absf(half_sharp.x / half_base.x - mult_sharp) > 0.03:
        _fail(
            failures,
            "kin_dmg_pen_sm: oblique+sharp_mult ratio %.4f want %.4f" % [half_sharp.x / half_base.x, mult_sharp]
        )
    var dmg_shape: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {"cut_damage_mult": 1.55, "blunt_damage_mult": 0.72})
    if absf(dmg_shape.x - base.x) > 0.0001 or absf(dmg_shape.y - base.y) > 0.0001:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: cut/blunt_damage_mult must not change applied pens (base s=%.6f b=%.6f vs dmg s=%.6f b"
                + "=%.6f)" % [base.x, base.y, dmg_shape.x, dmg_shape.y]
            )
        )
    var half_dmg_shape: Vector2 = _kin_dmg_pen_sample(
        vo_pin, 0.5, 1.0, {"cut_damage_mult": 1.88, "blunt_damage_mult": 0.61}
    )
    if absf(half_dmg_shape.x - half_base.x) > 0.0001 or absf(half_dmg_shape.y - half_base.y) > 0.0001:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: cut/blunt_damage_mult under partial parry must not change applied pens (half s=%.6f b="
                + "%.6f vs dmg s=%.6f b=%.6f)" % [half_base.x, half_base.y, half_dmg_shape.x, half_dmg_shape.y]
            )
        )


## Tier 5.1 (optional long-tail): **`CombatConstants.get_line_alignment_with_deflect`**  -  continuous cos(theta) vs
## attack-angle-only vs discrete **`get_line_alignment`** vs **`guard_deflect_blend`** lerp.


## Tier 5.1 (optional long-tail): **`CombatConstants.get_line_alignment_with_deflect`**  -  continuous cos(theta) vs
## attack-angle-only vs discrete **`get_line_alignment`** vs **`guard_deflect_blend`** lerp.
static func _run_kinematic_delivery_line_alignment_with_deflect_branches(failures: PackedStringArray) -> void:
    var atk_deg: float = 30.0
    var guard_deg: float = 45.0
    var both_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var want_both: float = CombatConstants.get_line_alignment_with_deflect("high", {}, both_ctx, {})
    var exp_both: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
    )
    if absf(want_both - exp_both) > 0.0001:
        _fail(failures, "line_align_deflect: both angles want %.6f got %.6f" % [exp_both, want_both])
    var def_low: Dictionary = {"guard_line": "low"}
    var only_atk_ctx: Dictionary = {"attack_angle_deg": atk_deg}
    var g_deg: float = CombatConstants.get_guard_angle_deg(def_low, {})
    var want_only_atk: float = CombatConstants.get_line_alignment_with_deflect("high", def_low, only_atk_ctx, {})
    var exp_only_atk: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, g_deg)
    )
    if absf(want_only_atk - exp_only_atk) > 0.0001:
        _fail(
            failures,
            (
                "line_align_deflect: attack_angle only want %.6f got %.6f (guard_deg=%.4f)"
                % [exp_only_atk, want_only_atk, g_deg]
            )
        )
    var want_discrete: float = CombatConstants.get_line_alignment_with_deflect("high", def_low, {}, {})
    var exp_discrete: float = CombatConstants.get_line_alignment("high", "low")
    if absf(want_discrete - exp_discrete) > 0.0001:
        _fail(failures, "line_align_deflect: discrete want %.6f got %.6f" % [exp_discrete, want_discrete])
    var def_blend: Dictionary = {
        "guard_line": "low",
        "guard_deflect_from_line": "high",
        "guard_deflect_blend": 0.5,
    }
    var want_blend: float = CombatConstants.get_line_alignment_with_deflect("high", def_blend, {}, {})
    var a_from: float = CombatConstants.get_line_alignment("high", "high")
    var a_to: float = CombatConstants.get_line_alignment("high", "low")
    var exp_blend: float = lerpf(a_from, a_to, 0.5)
    if absf(want_blend - exp_blend) > 0.0001:
        _fail(failures, "line_align_deflect: blend 0.5 want %.6f got %.6f" % [exp_blend, want_blend])


## Tier 5.1 (optional long-tail): deterministic angle helpers used by deflection magnitude path  -
## **`get_deflected_angle_bilateral`**, **`angle_to_nearest_line`**, **`line_to_angle`** (no RNG).


## Tier 5.1 (optional long-tail): deterministic angle helpers used by deflection magnitude path  -
## **`get_deflected_angle_bilateral`**, **`angle_to_nearest_line`**, **`line_to_angle`** (no RNG).
static func _run_kinematic_delivery_deflected_angle_bilateral_and_line_angle_helpers(
    failures: PackedStringArray
) -> void:
    if CombatConstants.angle_to_nearest_line(0.0) != "high":
        _fail(failures, "kin_line_angle: 0deg want high got %s" % CombatConstants.angle_to_nearest_line(0.0))
    if CombatConstants.angle_to_nearest_line(90.0) != "right":
        _fail(failures, "kin_line_angle: 90deg want right got %s" % CombatConstants.angle_to_nearest_line(90.0))
    if CombatConstants.angle_to_nearest_line(180.0) != "low":
        _fail(failures, "kin_line_angle: 180deg want low got %s" % CombatConstants.angle_to_nearest_line(180.0))
    if CombatConstants.angle_to_nearest_line(270.0) != "left":
        _fail(failures, "kin_line_angle: 270deg want left got %s" % CombatConstants.angle_to_nearest_line(270.0))
    if CombatConstants.angle_to_nearest_line(360.0) != "high":
        _fail(failures, "kin_line_angle: 360deg want high got %s" % CombatConstants.angle_to_nearest_line(360.0))
    for ln in ["high", "right", "low", "left"]:
        var a: float = CombatConstants.line_to_angle(ln)
        if CombatConstants.angle_to_nearest_line(a) != ln:
            _fail(
                failures,
                (
                    "kin_line_angle: round-trip line %s angle %.1f -> %s"
                    % [ln, a, CombatConstants.angle_to_nearest_line(a)]
                )
            )
    var b1: float = CombatConstants.get_deflected_angle_bilateral(0.0, 270.0, 10.0)
    if absf(b1 - 10.0) > 0.0001:
        _fail(failures, "kin_bilateral: (0,270,10) want 10 got %.4f" % b1)
    var b2: float = CombatConstants.get_deflected_angle_bilateral(200.0, 0.0, 15.0)
    if absf(b2 - fmod(200.0 - 15.0 + 360.0, 360.0)) > 0.0001:
        _fail(failures, "kin_bilateral: (200,0,15) want ccw 185 got %.4f" % b2)
    var b3: float = CombatConstants.get_deflected_angle_bilateral(0.0, 200.0, 5.0)
    if absf(b3 - 5.0) > 0.0001:
        _fail(failures, "kin_bilateral: (0,200,5) want cw 5 got %.4f" % b3)


## Tier 5.1 (optional long-tail): **`CombatConstants.get_deflected_line_from_angles`** same-line early return (bind)  -
## skips magnitude RNG.


## Tier 5.1 (optional long-tail): **`CombatConstants.get_deflected_line_from_angles`** same-line early return (bind)  -
## skips magnitude RNG.
static func _run_kinematic_delivery_deflected_line_from_angles_same_line_bind(failures: PackedStringArray) -> void:
    var hi: String = CombatConstants.get_deflected_line_from_angles(10.0, 350.0, 1.0, "cut", 0.5)
    if hi != "high":
        _fail(failures, "kin_deflect_same: high bind want high got %s" % hi)
    var rt: String = CombatConstants.get_deflected_line_from_angles(100.0, 110.0, 0.0, "stab", 0.2)
    if rt != "right":
        _fail(failures, "kin_deflect_same: right bind want right got %s" % rt)
    var lo: String = CombatConstants.get_deflected_line_from_angles(200.0, 190.0, 0.7, "blunt", 0.9)
    if lo != "low":
        _fail(failures, "kin_deflect_same: low bind want low got %s" % lo)
    var lf: String = CombatConstants.get_deflected_line_from_angles(270.0, 280.0, 0.3, "cut", 1.0)
    if lf != "left":
        _fail(failures, "kin_deflect_same: left bind want left got %s" % lf)


## Tier 5.1: **`CombatConstants.angle_diff_deg`** (shortest arc 0 - 180) + **`get_alignment_from_angles`** (cos theta
## floor).


## Tier 5.1: **`CombatConstants.angle_diff_deg`** (shortest arc 0 - 180) + **`get_alignment_from_angles`** (cos theta
## floor).
static func _run_kinematic_delivery_angle_diff_and_alignment_from_angles_helpers(failures: PackedStringArray) -> void:
    if CombatConstants.angle_diff_deg(350.0, 10.0) != 20.0:
        _fail(failures, "kin_angle_diff: 350->10 want 20 got %.4f" % CombatConstants.angle_diff_deg(350.0, 10.0))
    if CombatConstants.angle_diff_deg(10.0, 350.0) != 20.0:
        _fail(failures, "kin_angle_diff: 10->350 want 20 got %.4f" % CombatConstants.angle_diff_deg(10.0, 350.0))
    if CombatConstants.angle_diff_deg(0.0, 180.0) != 180.0:
        _fail(failures, "kin_angle_diff: 0->180 want 180 got %.4f" % CombatConstants.angle_diff_deg(0.0, 180.0))
    if CombatConstants.angle_diff_deg(400.0, 40.0) != 0.0:
        _fail(failures, "kin_angle_diff: 400->40 (wrap) want 0 got %.4f" % CombatConstants.angle_diff_deg(400.0, 40.0))
    var a1: float = CombatConstants.get_alignment_from_angles(0.0, 0.0)
    if absf(a1 - 1.0) > 0.0001:
        _fail(failures, "kin_align_from_angles: 0,0 want 1 got %.6f" % a1)
    var a2: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
    if absf(a2 - CombatConstants.PARRY_ALIGNMENT_FLOOR) > 0.0001:
        _fail(
            failures,
            "kin_align_from_angles: 0,180 want floor %.4f got %.6f" % [CombatConstants.PARRY_ALIGNMENT_FLOOR, a2]
        )
    var a3: float = CombatConstants.get_alignment_from_angles(0.0, 60.0)
    if absf(a3 - 0.5) > 0.0001:
        _fail(failures, "kin_align_from_angles: 0,60 want 0.5 got %.6f" % a3)


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`** contract  -  when both angles present, path
## keys use **`angle_to_nearest_line`** (discrete **`ATTACK_PATHS_BY_GUARD`**); alignment still uses continuous
## **`get_line_alignment_with_deflect`** (not discrete **`get_line_alignment(attack_line, guard_line)`**). Mirrors
## resolver intercept math (no RNG).


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`** contract  -  when both angles present, path
## keys use **`angle_to_nearest_line`** (discrete **`ATTACK_PATHS_BY_GUARD`**); alignment still uses continuous
## **`get_line_alignment_with_deflect`** (not discrete **`get_line_alignment(attack_line, guard_line)`**). Mirrors
## resolver intercept math (no RNG).
static func _run_kinematic_delivery_path_lookup_discrete_from_angles_continuous_alignment(
    failures: PackedStringArray
) -> void:
    var atk_deg: float = 90.0
    var guard_deg: float = 0.0
    var atk_line_str: String = "high"
    var guard_line_str: String = "high"
    var align_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var atk_line_path: String = CombatConstants.angle_to_nearest_line(atk_deg)
    var guard_line_path: String = CombatConstants.angle_to_nearest_line(guard_deg)
    if atk_line_path != "right" or guard_line_path != "high":
        _fail(failures, "kin_path_angle_split: quantize want right/high got %s/%s" % [atk_line_path, guard_line_path])
    var path_from_angles: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
    var path_from_strings: Array = CombatConstants.get_attack_path(atk_line_str, guard_line_str)
    if path_from_angles.is_empty() or path_from_strings.is_empty():
        _fail(
            failures, "kin_path_angle_split: empty path (angles=%s strings=%s)" % [path_from_angles, path_from_strings]
        )
        return
    if path_from_angles[0] == path_from_strings[0]:
        _fail(
            failures,
            (
                "kin_path_angle_split: first segment must differ (angle path %s vs string path %s)"
                % [path_from_angles[0], path_from_strings[0]]
            )
        )
    var defender: Dictionary = {"guard_line": guard_line_str}
    var align_cont: float = CombatConstants.get_line_alignment_with_deflect(atk_line_str, defender, align_ctx, {})
    var align_discrete: float = CombatConstants.get_line_alignment(atk_line_str, guard_line_str)
    var exp_cont: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
    )
    if absf(align_cont - exp_cont) > 0.0001:
        _fail(failures, "kin_path_angle_split: continuous align want %.6f got %.6f" % [exp_cont, align_cont])
    if absf(align_discrete - 1.0) > 0.0001:
        _fail(failures, "kin_path_angle_split: discrete high/high want 1 got %.6f" % align_discrete)
    if align_cont >= align_discrete - 0.0001:
        _fail(failures, "kin_path_angle_split: continuous %.6f must be < discrete %.6f" % [align_cont, align_discrete])
    var intercept_cont: int = _kin_path_intercept_max_index(path_from_angles, align_cont)
    var intercept_disc: int = _kin_path_intercept_max_index(path_from_strings, align_discrete)
    if intercept_cont <= intercept_disc:
        _fail(
            failures,
            (
                "kin_path_angle_split: low continuous align -> later intercept (cont=%d disc=%d)"
                % [intercept_cont, intercept_disc]
            )
        )
    var partial_ctx: Dictionary = {"attack_angle_deg": atk_deg}
    var path_partial: Array = CombatConstants.get_attack_path(atk_line_str, guard_line_str)
    if path_partial[0] != path_from_strings[0]:
        _fail(
            failures,
            (
                "kin_path_angle_split: guard_angle only must keep string path first=%s got %s"
                % [path_from_strings[0], path_partial[0]]
            )
        )


static func _kin_path_intercept_max_index(path: Array, alignment: float) -> int:
    var intercept_max: int = int(
        lerpf(float(CombatConstants.PATH_INTERCEPT_EARLY_MAX), float(path.size() - 1), 1.0 - alignment)
    )
    return clampi(intercept_max, 0, path.size() - 1)


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** lerps **`guard_deflect_from_line` -> `guard_line`**;
## **`get_line_alignment_with_deflect`** attack-angle-only branch uses that blended guard (not discrete **`guard_line`**
## alone).


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** lerps **`guard_deflect_from_line` -> `guard_line`**;
## **`get_line_alignment_with_deflect`** attack-angle-only branch uses that blended guard (not discrete **`guard_line`**
## alone).
static func _run_kinematic_delivery_guard_deflect_blend_guard_angle_and_attack_only_align(
    failures: PackedStringArray
) -> void:
    var def_blend: Dictionary = {
        "guard_line": "low",
        "guard_deflect_from_line": "high",
        "guard_deflect_blend": 0.5,
    }
    var g_blend: float = CombatConstants.get_guard_angle_deg(def_blend, {"parry_readiness": 1.0})
    var exp_blend_deg: float = lerpf(CombatConstants.line_to_angle("high"), CombatConstants.line_to_angle("low"), 0.5)
    if absf(g_blend - exp_blend_deg) > 0.0001:
        _fail(failures, "kin_guard_blend: guard angle want %.4f got %.4f" % [exp_blend_deg, g_blend])
    var def_static: Dictionary = {"guard_line": "low"}
    var g_static: float = CombatConstants.get_guard_angle_deg(def_static, {"parry_readiness": 1.0})
    if absf(g_static - CombatConstants.line_to_angle("low")) > 0.0001:
        _fail(
            failures,
            "kin_guard_blend: no blend want low %.1f got %.4f" % [CombatConstants.line_to_angle("low"), g_static]
        )
    var atk_match: float = 90.0
    var align_match: float = CombatConstants.get_line_alignment_with_deflect(
        "high", def_blend, {"attack_angle_deg": atk_match}, {"parry_readiness": 1.0}
    )
    var exp_match: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_match, g_blend)
    )
    if absf(align_match - exp_match) > 0.0001:
        _fail(
            failures,
            (
                "kin_guard_blend: attack-only align@90deg want %.6f got %.6f (guard=%.4f)"
                % [exp_match, align_match, g_blend]
            )
        )
    # 10deg vs blended guard (~90deg) stays above PARRY_ALIGNMENT_FLOOR; static low (~180deg) floors.
    var atk_mid: float = 10.0
    var align_blend_mid: float = CombatConstants.get_line_alignment_with_deflect(
        "high", def_blend, {"attack_angle_deg": atk_mid}, {"parry_readiness": 1.0}
    )
    var exp_blend_mid: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_mid, g_blend)
    )
    if absf(align_blend_mid - exp_blend_mid) > 0.0001:
        _fail(
            failures, "kin_guard_blend: attack-only align@10deg want %.6f got %.6f" % [exp_blend_mid, align_blend_mid]
        )
    var align_static_mid: float = CombatConstants.get_line_alignment_with_deflect(
        "high", def_static, {"attack_angle_deg": atk_mid}, {"parry_readiness": 1.0}
    )
    if align_static_mid >= align_blend_mid - 0.0001:
        _fail(
            failures,
            (
                "kin_guard_blend: static low guard should align lower than blended (static=%.6f blend=%.6f)"
                % [align_static_mid, align_blend_mid]
            )
        )


## Tier 5.1 (optional long-tail): **`WeaponDamageHelper.compute_penetration`** return keys match **`AttackResolver`**
## consumption  -  **SHARP** **`penetration_sharp`** only; **BLUNT** **`penetration_blunt_momentum_per_area`** +
## **`blunt_contact_cm`** (bare + thrust depth coupling via **`armor_resistance_rha_mm`** / **`pen_sharp_mm`**).


## Tier 5.1 (optional long-tail): **`WeaponDamageHelper.compute_penetration`** return keys match **`AttackResolver`**
## consumption  -  **SHARP** **`penetration_sharp`** only; **BLUNT** **`penetration_blunt_momentum_per_area`** +
## **`blunt_contact_cm`** (bare + thrust depth coupling via **`armor_resistance_rha_mm`** / **`pen_sharp_mm`**).
static func _run_kinematic_delivery_compute_penetration_return_keys_and_thrust_blunt_contact(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
    var spear: Weapon = HarnessFixtures.get_cached_weapon("SPEAR")
    if sword == null or mace == null or spear == null:
        _fail(failures, "kin_pen_keys: missing sword/mace/spear")
        return
    var ai_cut: AttackInstance = AttackInstance.new("oberhau", 0.55)
    ai_cut.velocity_m_s = 11.0
    var d_sharp: Dictionary = WeaponDamageHelper.compute_penetration(
        sword, ai_cut, WeaponConstants.DAMAGE_TYPE_SHARP, {}
    )
    if not d_sharp.has("penetration_sharp"):
        _fail(failures, "kin_pen_keys: SHARP dict missing penetration_sharp keys=%s" % str(d_sharp.keys()))
    if d_sharp.has("penetration_blunt_momentum_per_area") or d_sharp.has("blunt_contact_cm"):
        _fail(failures, "kin_pen_keys: SHARP dict must not include blunt keys keys=%s" % str(d_sharp.keys()))
    var ai_blunt: AttackInstance = AttackInstance.new("direct_blow", 0.5)
    ai_blunt.velocity_m_s = 10.0
    var d_blunt: Dictionary = WeaponDamageHelper.compute_penetration(
        mace, ai_blunt, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
    )
    if not d_blunt.has("penetration_blunt_momentum_per_area"):
        _fail(failures, "kin_pen_keys: BLUNT dict missing penetration_blunt_momentum_per_area")
    if not d_blunt.has("blunt_contact_cm"):
        _fail(failures, "kin_pen_keys: BLUNT dict missing blunt_contact_cm")
    # The BLUNT penetration channel caps at BLUNT_HEAD_MAX_CONTACT_CM (mirroring the damage channel), so a
    # large head like the MACE 8 cm resolves to the capped face, not the raw head diameter.
    var want_bc: float = minf(
        WeaponDamageHelper.get_blunt_contact_cm(mace, ai_blunt), WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM
    )
    var got_bc: float = float(d_blunt.get("blunt_contact_cm", -1.0))
    if got_bc <= 0.0:
        _fail(failures, "kin_pen_keys: blunt_contact_cm must be > 0 got %.4f" % got_bc)
    if absf(got_bc - want_bc) > 0.0001:
        _fail(failures, "kin_pen_keys: blunt_contact_cm want %.4f got %.4f" % [want_bc, got_bc])
    var pen_mpa: float = float(d_blunt.get("penetration_blunt_momentum_per_area", -1.0))
    if pen_mpa <= 0.0:
        _fail(failures, "kin_pen_keys: penetration_blunt_momentum_per_area must be > 0 got %.6f" % pen_mpa)
    var ai_thrust: AttackInstance = AttackInstance.new("spear_thrust", 0.6)
    ai_thrust.velocity_m_s = 12.0
    ai_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var pen_sharp_sp: float = float(
        WeaponDamageHelper.compute_penetration(spear, ai_thrust, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if pen_sharp_sp <= 0.001:
        _fail(failures, "kin_pen_keys: spear thrust pen_sharp too small %.6f" % pen_sharp_sp)
    var armor_rha: float = 10.0
    var pen_for_blunt: float = pen_sharp_sp * 0.5
    var d_thrust_blunt: Dictionary = (
        WeaponDamageHelper
        . compute_penetration(
            spear,
            ai_thrust,
            WeaponConstants.DAMAGE_TYPE_BLUNT,
            {
                "armor_resistance_rha_mm": armor_rha,
                "pen_sharp_mm": pen_for_blunt,
                "target_effective_mass_kg": 14.0,
            }
        )
    )
    var point_w: float = maxf(float(spear.point_width), WeaponConstants.MIN_CONTACT_WIDTH_CM)
    var head_w: float = float(spear.thrust_head_width)
    if head_w <= 0.0:
        head_w = point_w
    var depth: float = clampf(pen_for_blunt / armor_rha, 0.0, 1.0)
    var want_thrust_bc: float = point_w + (head_w - point_w) * depth
    var got_thrust_bc: float = float(d_thrust_blunt.get("blunt_contact_cm", -1.0))
    if absf(got_thrust_bc - want_thrust_bc) > 0.0001:
        _fail(
            failures,
            (
                "kin_pen_keys: thrust depth-coupled blunt_contact want %.4f got %.4f (depth=%.3f)"
                % [want_thrust_bc, got_thrust_bc, depth]
            )
        )
    if head_w > point_w + 0.01 and depth > 0.01 and depth < 0.99:
        var bare_thrust_bc: float = WeaponDamageHelper.get_blunt_contact_cm(spear, ai_thrust)
        if absf(got_thrust_bc - bare_thrust_bc) < 0.0001:
            _fail(
                failures,
                (
                    "kin_pen_keys: depth-coupled contact should differ from bare (bare=%.4f coupled=%.4f depth=%.3f)"
                    % [bare_thrust_bc, got_thrust_bc, depth]
                )
            )


## BLUNT penetration channel must mirror the damage channel's **`BLUNT_HEAD_MAX_CONTACT_CM`** cap: a large head
## (MACE 8 cm) dissipates momentum/area over the capped face in **`compute_penetration`**, not the raw 8 cm, so armor
## absorption stays consistent with pre-armor pressure. Locked for MACE `direct_blow` (cap engages) and SWORD
## `pommel_strike` (small head, cap is a no-op).


## BLUNT penetration channel must mirror the damage channel's **`BLUNT_HEAD_MAX_CONTACT_CM`** cap: a large head
## (MACE 8 cm) dissipates momentum/area over the capped face in **`compute_penetration`**, not the raw 8 cm, so armor
## absorption stays consistent with pre-armor pressure. Locked for MACE `direct_blow` (cap engages) and SWORD
## `pommel_strike` (small head, cap is a no-op).
static func _run_kinetic_delivery_blunt_penetration_contact_mirrors_damage_cap(failures: PackedStringArray) -> void:
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if mace == null or sword == null:
        _fail(failures, "kin_blunt_pen_cap: missing mace/sword")
        return
    var ai_mace: AttackInstance = AttackInstance.new("direct_blow", 0.5)
    ai_mace.velocity_m_s = 10.0
    var pen_mace: Dictionary = WeaponDamageHelper.compute_penetration(
        mace, ai_mace, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
    )
    var got_mace: float = float(pen_mace.get("blunt_contact_cm", -1.0))
    if absf(got_mace - WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM) > 0.0001:
        _fail(
            failures,
            "kin_blunt_pen_cap: MACE penetration contact %.4f want damage-channel cap %.4f"
            % [got_mace, WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM]
        )
    var raw_mace: float = mace.get_blunt_contact_cm("direct_blow")
    if raw_mace <= WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM + 0.0001:
        _fail(
            failures,
            "kin_blunt_pen_cap_pre: MACE raw head %.4f should exceed cap for the test to be meaningful" % raw_mace
        )
    var ai_pommel: AttackInstance = AttackInstance.new("pommel_strike", 0.5)
    ai_pommel.velocity_m_s = 8.0
    var pen_pommel: Dictionary = WeaponDamageHelper.compute_penetration(
        sword, ai_pommel, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
    )
    var got_pommel: float = float(pen_pommel.get("blunt_contact_cm", -1.0))
    var want_pommel: float = minf(
        sword.get_blunt_contact_cm("pommel_strike"), WeaponConstants.BLUNT_HEAD_MAX_CONTACT_CM
    )
    if absf(got_pommel - want_pommel) > 0.0001:
        _fail(
            failures,
            "kin_blunt_pen_cap: SWORD pommel penetration contact %.4f want min(raw, cap)=%.4f" % [got_pommel, want_pommel]
        )


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=false)`** matches **`line_to_angle`**;
## **`variance_context`** ignored without variance RNG.


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=false)`** matches **`line_to_angle`**;
## **`variance_context`** ignored without variance RNG.
static func _run_kinematic_delivery_attack_angle_deg_no_variance_deterministic(failures: PackedStringArray) -> void:
    for ln in ["high", "right", "low", "left"]:
        var want: float = CombatConstants.line_to_angle(ln)
        var got: float = CombatConstants.get_attack_angle_deg(ln, false, {}, {})
        if absf(got - want) > 0.0001:
            _fail(failures, "kin_atk_angle_nv: line %s want %.1f got %.4f" % [ln, want, got])
    seed(90211)
    var with_ctx: float = CombatConstants.get_attack_angle_deg(
        "high", false, {}, {"stamina_ratio": 0.05, "off_balance": true, "weapon_mass_kg": 4.0}
    )
    seed(90211)
    var bare: float = CombatConstants.get_attack_angle_deg("high", false, {}, {})
    if absf(with_ctx - bare) > 0.0001:
        _fail(
            failures,
            (
                "kin_atk_angle_nv: variance_context must not affect add_variance=false (ctx=%.4f bare=%.4f)"
                % [with_ctx, bare]
            )
        )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Replicate **`AttackResolver.compute_and_apply_damage`** velocity assembly (not parry **`v_intent`**).


## Replicate **`AttackResolver.compute_and_apply_damage`** velocity assembly (not parry **`v_intent`**).
static func _kin_expected_damage_velocity_m_s(
    mgr: Node,
    atk: Dictionary,
    tgt: Dictionary,
    intensity: float,
    arch: Dictionary,
    move_id: String,
    velocity_override: float,
    afterblow_damage_mult: float,
    strike_physics_ctx: Dictionary = {}
) -> float:
    var weapon: Weapon = EntityAccess.get_weapon(atk) as Weapon
    if weapon == null:
        return -1.0
    var commit_frac: float = float(strike_physics_ctx.get("weapon_extension_commit_fraction", -1.0))
    if commit_frac < 0.0:
        commit_frac = WeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move(move_id))
    var delivery_intensity: float = WeaponDamageHelper.effective_intensity_for_delivery(intensity, commit_frac)
    var v_base: float = (
        velocity_override
        if velocity_override >= 0.0
        else WeaponDamageHelper.velocity_m_s_from_intensity(delivery_intensity, arch, weapon, move_id)
    )
    var v: float = v_base * StrikePhysics.closing_speed_multiplier(mgr, atk, tgt, strike_physics_ctx)
    var st_ratio: float = clampf(EntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
    v *= sqrt(lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(st_ratio)))
    if afterblow_damage_mult < 1.0:
        v *= sqrt(maxf(0.04, afterblow_damage_mult))
    return ImpactVelocityModel.clamp_velocity_m_s(v)


static func _kin_pen_sharp_at_velocity(
    weapon: Weapon, move_id: String, arch: Dictionary, intensity: float, v_m_s: float, strike_mods: Dictionary = {}
) -> float:
    var ai: AttackInstance = AttackInstance.new(move_id, intensity)
    ai.archetype = arch
    ai.velocity_m_s = v_m_s
    ai.strike_momentum_mult = float(strike_mods.get("strike_momentum_mult", 1.0))
    return float(
        WeaponDamageHelper.compute_penetration(weapon, ai, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )


## Tier 5.1 (optional long-tail): hit damage **`velocity_m_s`** path matches **`WeaponDamageHelper`** at replicated
## effective **`v`**; **`compute_and_apply_damage`** -> **`take_damage_split`** contract (**`damage_type` SPLIT**,
## **`mechanical_post_armor`**, tissue delta).


## Tier 5.1 (optional long-tail): hit damage **`velocity_m_s`** path matches **`WeaponDamageHelper`** at replicated
## effective **`v`**; **`compute_and_apply_damage`** -> **`take_damage_split`** contract (**`damage_type` SPLIT**,
## **`mechanical_post_armor`**, tissue delta).
static func _run_kinematic_delivery_compute_damage_velocity_and_entity_split(failures: PackedStringArray) -> void:
    var intensity: float = 0.62
    var move_id: String = "oberhau"
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        _fail(failures, "kin_dmg_v_entity: missing sword")
        return
    var m: Node = MgrScript.new()
    m.set_meta(HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
    m.register(_new_entity("SWORD"), "player")
    m.register(_new_entity("SWORD"), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    var tgt_n: Node = EntityAccess.scene_node(tgt)
    if tgt_n == null:
        _fail(failures, "kin_dmg_v_entity: missing target node")
        _free_manager(m)
        return
    var cut_before: float = float(tgt_n.body_cutting.get("chest", 0.0))
    for case in [
        {"vo": -1.0, "label": "derived"},
        {"vo": 11.0, "label": "pinned"},
    ]:
        var vo: float = float(case["vo"])
        var v_exp: float = _kin_expected_damage_velocity_m_s(m, atk, tgt, intensity, arch, move_id, vo, 1.0)
        var pen_exp: float = _kin_pen_sharp_at_velocity(sword, move_id, arch, intensity, v_exp, {})
        var pen_int: float = _kin_dmg_pen_sample(vo, 1.0, 1.0, {}).x
        if pen_exp <= 0.001:
            _fail(failures, "kin_dmg_v_entity: %s pen_exp too small %.6f" % [case["label"], pen_exp])
        elif absf(pen_int / pen_exp - 1.0) > 0.02:
            _fail(
                failures,
                (
                    "kin_dmg_v_entity: %s pen ratio %.4f want ~1 (int=%.4f exp=%.4f v=%.4f)"
                    % [case["label"], pen_int / pen_exp, pen_int, pen_exp, v_exp]
                )
            )
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        EntityAccess.id_int(atk),
        EntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        intensity,
        move_id,
        arch,
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
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    if str(rd.get("damage_type", "")) != "SPLIT":
        _fail(failures, "kin_dmg_v_entity: damage_type want SPLIT got %s" % str(rd.get("damage_type")))
    if float(rd.get("mechanical_post_armor", -1.0)) < 0.0:
        _fail(failures, "kin_dmg_v_entity: mechanical_post_armor missing (EntityDamage path not taken?)")
    var total_phys: float = float(rd.get("total_physical", 0.0))
    var final_cut: float = float(rd.get("final_cut", 0.0))
    var cut_after: float = float(tgt_n.body_cutting.get("chest", 0.0))
    if total_phys > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS and final_cut > 0.0 and cut_after >= cut_before:
        _fail(
            failures,
            (
                "kin_dmg_v_entity: chest cut should drop on hit (before=%.2f after=%.2f final_cut=%.2f)"
                % [cut_before, cut_after, final_cut]
            )
        )
    _free_manager(m)


## Tier 5.1 (optional long-tail): **`alignment_context.guard_angle_deg` alone is ignored**  -  without
## **`attack_angle_deg`**, **`get_line_alignment_with_deflect`** uses **`get_guard_angle_deg`** / discrete
## **`guard_line`** (not the context guard angle).


## Tier 5.1 (optional long-tail): **`alignment_context.guard_angle_deg` alone is ignored**  -  without
## **`attack_angle_deg`**, **`get_line_alignment_with_deflect`** uses **`get_guard_angle_deg`** / discrete
## **`guard_line`** (not the context guard angle).
static func _run_kinematic_delivery_alignment_context_guard_angle_only_uses_combatant_guard(
    failures: PackedStringArray
) -> void:
    var def_line: String = (
        GuardLines.LINE_HIGH_RIGHT if CombatConstants.is_feature_hema_eight_guard_lines_enabled() else "right"
    )
    var defender: Dictionary = {"guard_line": def_line}
    var ctx_guard_only: Dictionary = {"guard_angle_deg": 180.0}
    var atk_line: String = _harness_cardinal_attack_line("high_right")
    var got: float = CombatConstants.get_line_alignment_with_deflect(
        atk_line, defender, ctx_guard_only, {"parry_readiness": 1.0}
    )
    var exp_discrete: float = CombatConstants.get_line_alignment(atk_line, def_line)
    if absf(got - exp_discrete) > 0.0001:
        _fail(failures, "kin_align_ctx: guard_angle only want discrete high/right %.6f got %.6f" % [exp_discrete, got])
    var wrong_ctx_pair: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(0.0, 180.0)
    )
    if absf(got - wrong_ctx_pair) < 0.0001:
        _fail(
            failures,
            "kin_align_ctx: must not pair line highdeg with context guard 180deg alone (floor %.6f)" % wrong_ctx_pair
        )
    if exp_discrete <= CombatConstants.PARRY_ALIGNMENT_FLOOR + 0.01:
        _fail(failures, "kin_align_ctx: fixture needs discrete align above floor (got %.6f)" % exp_discrete)


## Tier 5.1 (optional long-tail): parry **`v_intent`** base is **`WeaponDamageHelper.get_effective_velocity_m_s`** ×
## **`StrikeRealismProfile.velocity_intent_mult_from_pa`** (pinned station); damage **KE** uses effective **`v`**
## without intent mult.


## Tier 5.1 (optional long-tail): parry **`v_intent`** base is **`WeaponDamageHelper.get_effective_velocity_m_s`** ×
## **`StrikeRealismProfile.velocity_intent_mult_from_pa`** (pinned station); damage **KE** uses effective **`v`**
## without intent mult.
static func _run_kinematic_delivery_parry_v_intent_effective_velocity_base(failures: PackedStringArray) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        _fail(failures, "kin_parry_v: missing sword")
        return
    var move_id: String = "oberhau"
    var intensity: float = 0.62
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_derived: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_derived.archetype = arch
    ai_derived.velocity_m_s = -1.0
    var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_derived)
    var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(intensity, arch, sword, move_id)
    if absf(v_eff - v_from_i) > 0.0001:
        _fail(failures, "kin_parry_v: derived v_eff want %.6f got %.6f" % [v_from_i, v_eff])
    var ai_pin: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_pin.archetype = arch
    ai_pin.velocity_m_s = 10.0
    if absf(WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_pin) - 10.0) > 0.0001:
        _fail(failures, "kin_parry_v: pinned v_eff should be 10")
    var pa_tip: Dictionary = {"impact_blade_station": 0.92, "strike_measure_ratio": 1.0}
    var pa_guard: Dictionary = {"impact_blade_station": 0.12, "strike_measure_ratio": 1.0}
    var mult_tip: float = StrikeRealism.velocity_intent_mult_from_pa(pa_tip, sword, move_id, intensity, arch)
    var mult_guard: float = StrikeRealism.velocity_intent_mult_from_pa(pa_guard, sword, move_id, intensity, arch)
    if mult_tip <= mult_guard + 0.0001:
        _fail(failures, "kin_parry_v: cut tip station mult %.4f should exceed guard %.4f" % [mult_tip, mult_guard])
    var v_intent_tip: float = v_eff * mult_tip
    var ke_damage: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_derived)
    var ai_intent: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_intent.archetype = arch
    ai_intent.velocity_m_s = v_intent_tip
    var ke_at_intent: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_intent)
    if ke_at_intent <= ke_damage + 1e-4:
        _fail(failures, "kin_parry_v: intent v should raise KE (damage=%.4f intent=%.4f)" % [ke_damage, ke_at_intent])
    var ratio_v: float = v_intent_tip / maxf(v_eff, 0.001)
    var ratio_ke: float = ke_at_intent / maxf(ke_damage, 0.001)
    if absf(ratio_ke - ratio_v * ratio_v) > 0.08:
        _fail(failures, "kin_parry_v: KE ratio %.4f want ~(v ratio)^2 %.4f" % [ratio_ke, ratio_v * ratio_v])


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** wobble when **`parry_readiness` < 1** (seeded); readiness
## **1** matches **`line_to_angle(guard_line)`** without blend.


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** wobble when **`parry_readiness` < 1** (seeded); readiness
## **1** matches **`line_to_angle(guard_line)`** without blend.
static func _run_kinematic_delivery_guard_wobble_readiness_shifts_guard_angle(failures: PackedStringArray) -> void:
    var defender: Dictionary = {"guard_line": "high"}
    var wobble_ctx_full: Dictionary = {"parry_readiness": 1.0}
    var stable: float = CombatConstants.get_guard_angle_deg(defender, wobble_ctx_full)
    if absf(stable - CombatConstants.line_to_angle("high")) > 0.0001:
        _fail(
            failures,
            "kin_guard_wobble: readiness 1 want high %.1f got %.4f" % [CombatConstants.line_to_angle("high"), stable]
        )
    seed(44001)
    var wobble_ctx_low: Dictionary = {"parry_readiness": 0.0}
    var wobbled: float = CombatConstants.get_guard_angle_deg(defender, wobble_ctx_low)
    if absf(wobbled - stable) < 0.05:
        _fail(
            failures, "kin_guard_wobble: readiness 0 should shift angle (stable=%.4f wobbled=%.4f)" % [stable, wobbled]
        )
    var max_shift: float = CombatConstants.GUARD_WOBBLE_MAX_DEG + 0.01
    if CombatConstants.angle_diff_deg(wobbled, stable) > max_shift:
        _fail(
            failures,
            (
                "kin_guard_wobble: shift %.4f exceeds max wobble %.4f"
                % [CombatConstants.angle_diff_deg(wobbled, stable), CombatConstants.GUARD_WOBBLE_MAX_DEG]
            )
        )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 5.1: canonical resources/weapons/move rows for integration loops (matches velocity / KE bracket coverage).


## Tier 5.1: canonical resources/weapons/move rows for integration loops (matches velocity / KE bracket coverage).
static func _kin_fixtures_cut_swing() -> Array:
    return [
        {"wid": "SWORD", "move": "oberhau", "tag": "sw"},
        {"wid": "AXE", "move": "diagonal_chop", "tag": "ax"},
        # Light blade: pinned v high enough for measurable blunt slip (see strike_momentum_mult harness).
        {"wid": "DAGGER", "move": "quick_slash", "tag": "dg", "vo": 18.0},
    ]


static func _kin_fixtures_thrust() -> Array:
    return [{"wid": "SPEAR", "move": "spear_thrust", "tag": "sp"}]


static func _kin_fixtures_blunt() -> Array:
    return [{"wid": "MACE", "move": "direct_blow", "tag": "mc"}]


static func _kin_fixtures_with_sharp_pen() -> Array:
    var out: Array = _kin_fixtures_cut_swing()
    out.append_array(_kin_fixtures_thrust())
    return out


static func _kin_fixtures_with_blunt_pen() -> Array:
    var out: Array = _kin_fixtures_cut_swing()
    out.append_array(_kin_fixtures_blunt())
    return out
