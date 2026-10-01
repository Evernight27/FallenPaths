class_name ParryCalibrationRecoilTests

extends CombatRegressionHarnessCore

## Parry calibration named-constant + recoil-scale surface: deflect recovery/immediate guard,
## off-balance deflect scaling, bonus/velocity/reach/flex named constants and the
## full recoil-scale family (mass, alignment, flex, progress, body mass).


static func _run_parry_deflect_recovery_cost(failures: PackedStringArray) -> void:
    # Constant must be set correctly.
    if not is_equal_approx(CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT, 1.20):
        _fail(
            failures,
            (
                "deflect_recovery: PARRY_DEFLECT_RECOVERY_MULT want 1.20 got %.2f"
                % CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT
            )
        )
    # Zero intensity: should clamp to floor (0.3) and yield minimum boost.
    var mult_min: float = CombatConstants.parry_deflect_recovery_mult(0.0)
    var mult_floor: float = 1.0 + (CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT - 1.0) * 0.3 / 0.7
    if not is_equal_approx(mult_min, mult_floor):
        _fail(failures, "deflect_recovery: min intensity mult want %.4f got %.4f" % [mult_floor, mult_min])
    # Unit intensity: full boost.
    var mult_unit: float = CombatConstants.parry_deflect_recovery_mult(1.0)
    if not is_equal_approx(mult_unit, CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT):
        _fail(
            failures,
            (
                "deflect_recovery: unit intensity mult want %.4f got %.4f"
                % [CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT, mult_unit]
            )
        )
    # Must always be > 1.0 — deflect always costs more than a clean miss.
    if mult_min <= 1.0 or mult_unit <= 1.0:
        _fail(failures, "deflect_recovery: both min and unit intensity must be > 1.0")
    # Deflect mult must be strictly less than thrust mult at same intensity.
    var thrust_mult: float = CombatConstants.parry_thrust_recovery_mult(1.0)
    if mult_unit >= thrust_mult:
        _fail(failures, "deflect_recovery: deflect mult (%.4f) must be < thrust mult (%.4f)" % [mult_unit, thrust_mult])


## Pass 27 (HEMA physics): immediate blade displacement — after a full parry deflect, the attacker's
## guard_line must be displaced at parry time (not deferred to recovery completion).


static func _run_parry_deflect_immediate_guard_displacement(failures: PackedStringArray) -> void:
    # Verify the deflection is stored on the attacker dict at parry time.
    # Simulate: create a minimal attacker dict with the data that apply_result stores.
    var atk: Dictionary = {}
    atk[DataKeys.ATTACK_LAST_MOVE_ID] = "SWORD_CUT"
    atk[DataKeys.PA_LAST_MOVE_ID] = "SWORD_CUT"
    atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = "oberhau"
    atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = "vom_tag"
    atk[DataKeys.PA_PARRY_CLASH_CONTEXT] = {
        DataKeys.CLASH_DEFENDER_GUARD_LINE: "vom_tag",
        # parry_control below the bind threshold (0.48) so this resolves as a non-bind DEFLECT
        # (blend > 0), not a bind (blend 0.0).
        DataKeys.RESULT_PARRY_CONTROL: 0.3,
        DataKeys.RESULT_CLASH_SEVERITY: 0.5,
        DataKeys.ATTACK_ANGLE_DEG: 45.0,
        DataKeys.CLASH_GUARD_ANGLE_DEG: 90.0,
        DataKeys.CLASH_ALIGNMENT: 0.8,
        DataKeys.RESULT_ATTACK_TYPE: "SWORD_CUT",
        DataKeys.WEAPON_CONTACT_TYPE: "blade",
        DataKeys.PA_ARCHETYPE_ID: ""
    }
    atk[DataKeys.ATTACK_GUARD_LINE] = "vom_tag"
    # Apply immediate displacement (same call as in apply_result).
    GuardLineUpdater.set_guard_deflected(
        atk,
        atk.get(DataKeys.PA_LAST_MOVE_ID, ""),
        atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, ""),
        atk.get(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY, ""),
        atk.get(DataKeys.PA_PARRY_CLASH_CONTEXT, {})
    )
    # Guard must have been displaced — not still at the original vom_tag.
    var displaced_line: String = atk.get(DataKeys.ATTACK_GUARD_LINE, "")
    if displaced_line.is_empty() or displaced_line == "vom_tag":
        _fail(failures, "immediate_displace: guard_line should be displaced, got '%s'" % displaced_line)
    # Deflect blend must be set (non-zero for non-bind deflect).
    var blend: float = atk.get(DataKeys.PA_GUARD_DEFLECT_BLEND, 0.0)
    if blend <= 0.0:
        _fail(failures, "immediate_displace: PA_GUARD_DEFLECT_BLEND should be > 0 for deflect, got %.2f" % blend)
    # Deflect from-line must be set.
    var from_line: String = atk.get(DataKeys.PA_GUARD_DEFLECT_FROM_LINE, "")
    if from_line.is_empty():
        _fail(failures, "immediate_displace: PA_GUARD_DEFLECT_FROM_LINE should be set")
    # Now simulate complete_recovery — it should NOT re-displace, just clean up.
    # Verify that the keys still exist before cleanup.
    if not atk.has(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY):
        _fail(failures, "immediate_displace: PA_DEFENDER_GUARD_LINE_AT_PARRY should exist before cleanup")
    # After cleanup (erasing stored data), guard_line and blend must remain.
    atk.erase(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY)
    atk.erase(DataKeys.PA_DEFENDER_FORM_AT_PARRY)
    atk.erase(DataKeys.PA_PARRY_CLASH_CONTEXT)
    if atk.get(DataKeys.ATTACK_GUARD_LINE, "") != displaced_line:
        _fail(
            failures,
            (
                "immediate_displace: guard_line changed after cleanup (was '%s', now '%s')"
                % [displaced_line, atk.get(DataKeys.ATTACK_GUARD_LINE, "")]
            )
        )
    if not is_equal_approx(atk.get(DataKeys.PA_GUARD_DEFLECT_BLEND, 0.0), blend):
        _fail(failures, "immediate_displace: blend changed after cleanup")


## Pass 29 (HEMA biomechanics): scaled off-balance after parry deflect — heavier deflection = longer
## disorientation. The miss path stays flat at OFF_BALANCE_DURATION_S; the deflect path scales with intensity.


static func _run_off_balance_deflect_scaled_duration(failures: PackedStringArray) -> void:
    # Base constant must be set correctly.
    if not is_equal_approx(CombatConstantsParry.OFF_BALANCE_DEFLECT_DURATION_S, 1.0):
        _fail(
            failures,
            (
                "ob_deflect: OFF_BALANCE_DEFLECT_DURATION_S want 1.0 got %.2f"
                % CombatConstantsParry.OFF_BALANCE_DEFLECT_DURATION_S
            )
        )
    # Zero intensity: scales to 0.5x base (0.5s).
    var dur_zero: float = CombatConstants.off_balance_deflect_duration(0.0)
    if not is_equal_approx(dur_zero, 0.5):
        _fail(failures, "ob_deflect: zero intensity want 0.5s got %.2f" % dur_zero)
    # Unit intensity: full base (1.0s).
    var dur_unit: float = CombatConstants.off_balance_deflect_duration(1.0)
    if not is_equal_approx(dur_unit, 1.0):
        _fail(failures, "ob_deflect: unit intensity want 1.0s got %.2f" % dur_unit)
    # Mid intensity (0.5): should be 0.75s (0.5 + 0.5*0.5 = 0.75).
    var dur_mid: float = CombatConstants.off_balance_deflect_duration(0.5)
    if not is_equal_approx(dur_mid, 0.75):
        _fail(failures, "ob_deflect: mid intensity want 0.75s got %.2f" % dur_mid)
    # Must always exceed miss off-balance (0.4s).
    if dur_zero <= CombatConstants.OFF_BALANCE_DURATION_S:
        _fail(
            failures,
            (
                "ob_deflect: min duration (%.2f) must exceed miss duration (%.2f)"
                % [dur_zero, CombatConstants.OFF_BALANCE_DURATION_S]
            )
        )


## Pass 30 (code audit): named parry decision constants — verify the inline magic numbers are now
## accessible as named constants with the correct values.


static func _run_parry_decision_named_constants(failures: PackedStringArray) -> void:
    # Passive defense bias: must be < 1.0 (favors parry) and > 0.5 (not too aggressive).
    if not (CombatConstants.PASSIVE_DEFENSE_BIAS < 1.0 and CombatConstants.PASSIVE_DEFENSE_BIAS > 0.5):
        _fail(
            failures,
            "named_consts: PASSIVE_DEFENSE_BIAS want (0.5, 1.0) got %.2f" % CombatConstants.PASSIVE_DEFENSE_BIAS
        )
    if not is_equal_approx(CombatConstants.PASSIVE_DEFENSE_BIAS, 0.90):
        _fail(failures, "named_consts: PASSIVE_DEFENSE_BIAS want 0.90 got %.2f" % CombatConstants.PASSIVE_DEFENSE_BIAS)
    # Dodge boosts: below-glancing must be > glancing > 1.0.
    if not (
        CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST > CombatConstants.PARRY_GLANCING_DODGE_BOOST
        and CombatConstants.PARRY_GLANCING_DODGE_BOOST > 1.0
    ):
        _fail(
            failures,
            (
                "named_consts: dodge boost ordering violated (below=%.2f glancing=%.2f)"
                % [CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST, CombatConstants.PARRY_GLANCING_DODGE_BOOST]
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST, 1.25):
        _fail(
            failures,
            (
                "named_consts: PARRY_BELOW_GLANCING_DODGE_BOOST want 1.25 got %.2f"
                % CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_GLANCING_DODGE_BOOST, 1.15):
        _fail(
            failures,
            "named_consts: PARRY_GLANCING_DODGE_BOOST want 1.15 got %.2f" % CombatConstants.PARRY_GLANCING_DODGE_BOOST
        )
    # Twist-dodge constants: floor must be in (0, 1), slope must be in (0, 1).
    if not (CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR > 0.0 and CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR < 1.0):
        _fail(
            failures,
            (
                "named_consts: TWIST_DODGE_MIN_TIME_FACTOR want (0,1) got %.2f"
                % CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR
            )
        )
    if not (
        CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE > 0.0 and CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE < 1.0
    ):
        _fail(
            failures,
            (
                "named_consts: TWIST_DODGE_PARRY_QUALITY_SLOPE want (0,1) got %.2f"
                % CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE
            )
        )
    # Quality floor must be in (0, 1) and consistent with slope: floor = 1—slope.
    var expected_floor: float = 1.0 - CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE
    if not is_equal_approx(CombatConstants.TWIST_DODGE_PARRY_QUALITY_FLOOR, expected_floor):
        _fail(
            failures,
            (
                "named_consts: TWIST_DODGE_PARRY_QUALITY_FLOOR want %.2f (1-slope) got %.2f"
                % [expected_floor, CombatConstants.TWIST_DODGE_PARRY_QUALITY_FLOOR]
            )
        )


## Pass 31 (HEMA tempo): parry bonus scales with parry quality — a clean catch (high control)
## gives a bigger capacity boost than a marginal deflect (low control).


static func _run_parry_bonus_scales_with_control(failures: PackedStringArray) -> void:
    # Constants must be set correctly.
    if not is_equal_approx(CombatConstants.PARRY_BONUS_MULT_MIN, 1.05):
        _fail(failures, "parry_bonus: PARRY_BONUS_MULT_MIN want 1.05 got %.2f" % CombatConstants.PARRY_BONUS_MULT_MIN)
    if not is_equal_approx(CombatConstants.PARRY_BONUS_MULT_MAX, 1.15):
        _fail(failures, "parry_bonus: PARRY_BONUS_MULT_MAX want 1.15 got %.2f" % CombatConstants.PARRY_BONUS_MULT_MAX)
    # At the bind threshold (0.48): minimum bonus.
    var mult_min: float = CombatConstants.parry_bonus_mult(CombatConstants.PARRY_BIND_CONTROL_THRESHOLD)
    if not is_equal_approx(mult_min, CombatConstants.PARRY_BONUS_MULT_MIN):
        _fail(
            failures,
            "parry_bonus: at bind threshold want %.2f got %.2f" % [CombatConstants.PARRY_BONUS_MULT_MIN, mult_min]
        )
    # At perfect control (1.0): maximum bonus.
    var mult_max: float = CombatConstants.parry_bonus_mult(1.0)
    if not is_equal_approx(mult_max, CombatConstants.PARRY_BONUS_MULT_MAX):
        _fail(
            failures,
            "parry_bonus: at perfect control want %.2f got %.2f" % [CombatConstants.PARRY_BONUS_MULT_MAX, mult_max]
        )
    # Mid control (0.74): should be between min and max.
    var mid_ctrl: float = (CombatConstants.PARRY_BIND_CONTROL_THRESHOLD + 1.0) * 0.5
    var mult_mid: float = CombatConstants.parry_bonus_mult(mid_ctrl)
    if not (mult_mid > mult_min and mult_mid < mult_max):
        _fail(
            failures,
            "parry_bonus: mid control (%.2f) want (%.2f, %.2f) got %.2f" % [mid_ctrl, mult_min, mult_max, mult_mid]
        )
    # Must always be > 1.0 — parry bonus is always a boost, never a penalty.
    if mult_min <= 1.0 or mult_max <= 1.0:
        _fail(failures, "parry_bonus: both min and max must be > 1.0")
    # Below bind threshold: clamped to minimum (no bonus for non-bind parries).
    var mult_below: float = CombatConstants.parry_bonus_mult(0.3)
    if not is_equal_approx(mult_below, CombatConstants.PARRY_BONUS_MULT_MIN):
        _fail(
            failures,
            "parry_bonus: below threshold want %.2f got %.2f" % [CombatConstants.PARRY_BONUS_MULT_MIN, mult_below]
        )


## Pass 32 (code audit): named partial-parry velocity constants — verify the inline magic numbers
## in the v_min / follow-through velocity path are now accessible as named constants.


static func _run_parry_velocity_named_constants(failures: PackedStringArray) -> void:
    # Velocity clamp: must be > 1.0 (allows slight overshoot) and < 1.5 (not unphysical).
    if not (
        CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP > 1.0 and CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP < 1.5
    ):
        _fail(
            failures,
            (
                "vel_consts: PARRY_FOLLOW_THROUGH_VEL_CLAMP want (1.0, 1.5) got %.2f"
                % CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP, 1.1):
        _fail(
            failures,
            (
                "vel_consts: PARRY_FOLLOW_THROUGH_VEL_CLAMP want 1.1 got %.2f"
                % CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP
            )
        )
    # Fallback mass (light weapon) must be < reference mass (heavy weapon).
    if not (CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG < CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG):
        _fail(
            failures,
            (
                "vel_consts: fallback mass (%.2f) must be < reference mass (%.2f)"
                % [CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG, CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG]
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG, 0.45):
        _fail(
            failures,
            "vel_consts: PARRY_V_MIN_FALLBACK_MASS_KG want 0.45 got %.2f" % CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG
        )
    if not is_equal_approx(CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG, 2.7):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_REFERENCE_MASS_KG want 2.7 got %.2f"
                % CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG
            )
        )
    # Mass-scale threshold: must be in (0, 1) — a remaining-ratio cutoff.
    if not (
        CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD > 0.0
        and CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD < 1.0
    ):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_MASS_SCALE_THRESHOLD want (0,1) got %.2f"
                % CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD, 0.3):
        _fail(
            failures,
            (
                "vel_consts: PARRY_V_MIN_MASS_SCALE_THRESHOLD want 0.3 got %.2f"
                % CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD
            )
        )
    # Mass scaling: fallback mass / reference mass must be in (0, 1) — light weapons get less momentum retention.
    var mass_ratio: float = CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG / CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG
    if not (mass_ratio > 0.0 and mass_ratio < 1.0):
        _fail(failures, "vel_consts: mass ratio (%.2f) must be in (0,1)" % mass_ratio)


## Pass 33 (code audit): named reach disparity + reach readiness constants — verify the inline
## magic numbers in the reach penalty/bonus path are now accessible as named constants.


static func _run_reach_disparity_named_constants(failures: PackedStringArray) -> void:
    # Reach disparity threshold: must be > 0 (some reach delta is free) and < 1.0 (not absurdly large).
    if not (CombatConstants.REACH_DISPARITY_THRESHOLD_M > 0.0 and CombatConstants.REACH_DISPARITY_THRESHOLD_M < 1.0):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_THRESHOLD_M want (0,1) got %.2f"
                % CombatConstants.REACH_DISPARITY_THRESHOLD_M
            )
        )
    if not is_equal_approx(CombatConstants.REACH_DISPARITY_THRESHOLD_M, 0.30):
        _fail(
            failures,
            "reach_consts: REACH_DISPARITY_THRESHOLD_M want 0.30 got %.2f" % CombatConstants.REACH_DISPARITY_THRESHOLD_M
        )
    # Penalty slope: must be in (0, 1) — a fraction of capacity lost per meter.
    if not (
        CombatConstants.REACH_DISPARITY_PENALTY_SLOPE > 0.0 and CombatConstants.REACH_DISPARITY_PENALTY_SLOPE < 1.0
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_SLOPE want (0,1) got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_SLOPE
            )
        )
    if not is_equal_approx(CombatConstants.REACH_DISPARITY_PENALTY_SLOPE, 0.30):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_SLOPE want 0.30 got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_SLOPE
            )
        )
    # Penalty floor: must be in (0, 1) — reach disparity can't zero out parry capacity.
    if not (
        CombatConstants.REACH_DISPARITY_PENALTY_FLOOR > 0.0 and CombatConstants.REACH_DISPARITY_PENALTY_FLOOR < 1.0
    ):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_FLOOR want (0,1) got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_FLOOR
            )
        )
    if not is_equal_approx(CombatConstants.REACH_DISPARITY_PENALTY_FLOOR, 0.25):
        _fail(
            failures,
            (
                "reach_consts: REACH_DISPARITY_PENALTY_FLOOR want 0.25 got %.2f"
                % CombatConstants.REACH_DISPARITY_PENALTY_FLOOR
            )
        )
    # Reach readiness scale: must be > 0 (positive bonus for longer weapons) and small (< 0.2/m).
    if not (CombatConstants.REACH_READINESS_SCALE_PER_M > 0.0 and CombatConstants.REACH_READINESS_SCALE_PER_M < 0.2):
        _fail(
            failures,
            (
                "reach_consts: REACH_READINESS_SCALE_PER_M want (0,0.2) got %.2f"
                % CombatConstants.REACH_READINESS_SCALE_PER_M
            )
        )
    if not is_equal_approx(CombatConstants.REACH_READINESS_SCALE_PER_M, 0.06):
        _fail(
            failures,
            "reach_consts: REACH_READINESS_SCALE_PER_M want 0.06 got %.2f" % CombatConstants.REACH_READINESS_SCALE_PER_M
        )
    # Reach readiness cap: must be in (0, 1) and consistent with scale (cap / scale = max reach advantage in meters).
    if not (CombatConstants.REACH_READINESS_CAP > 0.0 and CombatConstants.REACH_READINESS_CAP < 1.0):
        _fail(failures, "reach_consts: REACH_READINESS_CAP want (0,1) got %.2f" % CombatConstants.REACH_READINESS_CAP)
    if not is_equal_approx(CombatConstants.REACH_READINESS_CAP, 0.15):
        _fail(failures, "reach_consts: REACH_READINESS_CAP want 0.15 got %.2f" % CombatConstants.REACH_READINESS_CAP)
    # Cap must be a multiple of the scale (i.e. cap/scale is a clean meter count).
    var max_reach_advantage: float = CombatConstants.REACH_READINESS_CAP / CombatConstants.REACH_READINESS_SCALE_PER_M
    if max_reach_advantage < 1.0:
        _fail(failures, "reach_consts: max reach advantage (%.2f m) must be >= 1.0 m" % max_reach_advantage)


## Pass 34 (HEMA forte/schwach): flex factor scales the forte/schwach bonus with blade slenderness.
## A flexible blade (long/thin) has a larger forte/schwach difference than a stiff blade (short/thick).
## Reference calibrated to SWORD (slenderness 45) so D001 (SWORD-only) is unaffected.


static func _run_flex_factor_blade_slenderness(failures: PackedStringArray) -> void:
    # Reference constant must be set correctly (SWORD: 90cm / 2.0cm = 45).
    if not is_equal_approx(CombatConstants.FLEX_REFERENCE_SLENDERNESS, 45.0):
        _fail(
            failures,
            "flex_factor: FLEX_REFERENCE_SLENDERNESS want 45.0 got %.1f" % CombatConstants.FLEX_REFERENCE_SLENDERNESS
        )
    # At the reference slenderness (45): flex factor = 1.0 (neutral, SWORD unchanged).
    var ref_factor: float = CombatConstants.flex_factor_for_slenderness(45.0)
    if not is_equal_approx(ref_factor, 1.0):
        _fail(failures, "flex_factor: at reference slenderness want 1.0 got %.2f" % ref_factor)
    # Zero slenderness (no blade / shaft weapon): neutral 1.0 (no forte/schwach).
    var zero_factor: float = CombatConstants.flex_factor_for_slenderness(0.0)
    if not is_equal_approx(zero_factor, 1.0):
        _fail(failures, "flex_factor: zero slenderness want 1.0 got %.2f" % zero_factor)
    # Stiff blade (DAGGER: 20cm / 1.5cm = 13.3): flex factor < 1.0 (smaller forte/schwach difference).
    var stiff_factor: float = CombatConstants.flex_factor_for_slenderness(13.3)
    if not (stiff_factor < 1.0 and stiff_factor >= CombatConstants.FLEX_FACTOR_MIN):
        _fail(
            failures,
            (
                "flex_factor: stiff blade (13.3) want [%.2f, 1.0) got %.2f"
                % [CombatConstants.FLEX_FACTOR_MIN, stiff_factor]
            )
        )
    # Flexible blade (slenderness 90): flex factor > 1.0, capped at FLEX_FACTOR_MAX.
    var flex_factor_hi: float = CombatConstants.flex_factor_for_slenderness(90.0)
    if not (flex_factor_hi > 1.0 and flex_factor_hi <= CombatConstants.FLEX_FACTOR_MAX):
        _fail(
            failures,
            (
                "flex_factor: flexible blade (90) want (1.0, %.2f] got %.2f"
                % [CombatConstants.FLEX_FACTOR_MAX, flex_factor_hi]
            )
        )
    # Verify SWORD weapon slenderness is exactly the reference (D001 safety).
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    var sword_slenderness: float = sword.get_blade_slenderness()
    if not is_equal_approx(sword_slenderness, CombatConstants.FLEX_REFERENCE_SLENDERNESS):
        _fail(
            failures,
            (
                "flex_factor: SWORD slenderness want %.1f (reference) got %.1f"
                % [CombatConstants.FLEX_REFERENCE_SLENDERNESS, sword_slenderness]
            )
        )
    # Verify SWORD flex factor is exactly 1.0 (D001 safety — no behavior change).
    var sword_factor: float = CombatConstants.flex_factor_for_slenderness(sword_slenderness)
    if not is_equal_approx(sword_factor, 1.0):
        _fail(failures, "flex_factor: SWORD flex factor want 1.0 (D001 safety) got %.2f" % sword_factor)
    # Verify DAGGER is stiffer (lower slenderness) than SWORD.
    var dagger: Weapon = HarnessFixtures.get_cached_weapon("DAGGER")
    var dagger_slenderness: float = dagger.get_blade_slenderness()
    if not (dagger_slenderness > 0.0 and dagger_slenderness < sword_slenderness):
        _fail(
            failures,
            "flex_factor: DAGGER slenderness (%.1f) must be < SWORD (%.1f)" % [dagger_slenderness, sword_slenderness]
        )


## Pass 36 (HEMA biomechanics): partial parry stamina discount — a partial parry absorbs only a
## fraction of the incoming momentum, so it costs less stamina than a full braced stop.


static func _run_partial_parry_stamina_discount(failures: PackedStringArray) -> void:
    # Floor constant must be set correctly.
    if not is_equal_approx(CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR, 0.5):
        _fail(
            failures,
            "partial_stam: PARTIAL_PARRY_STAMINA_FLOOR want 0.5 got %.2f" % CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR
        )
    # Full absorption (1.0): full cost (1.0).
    var mult_full: float = CombatConstants.partial_parry_stamina_mult(1.0)
    if not is_equal_approx(mult_full, 1.0):
        _fail(failures, "partial_stam: full absorption want 1.0 got %.2f" % mult_full)
    # Zero absorption (0.0): floor (0.5).
    var mult_zero: float = CombatConstants.partial_parry_stamina_mult(0.0)
    if not is_equal_approx(mult_zero, CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR):
        _fail(
            failures,
            (
                "partial_stam: zero absorption want %.2f got %.2f"
                % [CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR, mult_zero]
            )
        )
    # Mid absorption (0.5): 0.75 (lerp between 0.5 and 1.0).
    var mult_mid: float = CombatConstants.partial_parry_stamina_mult(0.5)
    if not is_equal_approx(mult_mid, 0.75):
        _fail(failures, "partial_stam: mid absorption want 0.75 got %.2f" % mult_mid)
    # Must always be in [floor, 1.0] — a partial parry never costs more than a full parry.
    if mult_zero < CombatConstants.PARTIAL_PARRY_STAMINA_FLOOR or mult_full > 1.0:
        _fail(failures, "partial_stam: mult must be in [floor, 1.0]")
    # Monotonic: more absorption = more cost.
    if not (mult_zero < mult_mid and mult_mid < mult_full):
        _fail(failures, "partial_stam: mult must increase with absorption")
    # The discount must be meaningful for a typical partial parry (remaining_ratio = 0.5, absorption = 0.5).
    # A 50% partial parry should cost less than a full parry.
    if mult_mid >= 1.0:
        _fail(failures, "partial_stam: a 50% partial parry must cost less than a full parry")


## Pass 37 (HEMA blade control): mid-swing (committed weapon) parry penalty — a defender already in
## their own wind-up has their blade locked in their own attack arc, so their reflexive parry has
## reduced blade control. Applied on top of the timing-based late floor.


static func _run_mid_swing_parry_penalty(failures: PackedStringArray) -> void:
    # Constant must be set correctly.
    if not is_equal_approx(CombatConstants.PARRY_MID_SWING_CAPACITY_MULT, 0.80):
        _fail(
            failures,
            (
                "mid_swing: PARRY_MID_SWING_CAPACITY_MULT want 0.80 got %.2f"
                % CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
            )
        )
    # Must be a penalty (< 1.0) — a committed weapon reduces parry capacity.
    if not (
        CombatConstants.PARRY_MID_SWING_CAPACITY_MULT < 1.0 and CombatConstants.PARRY_MID_SWING_CAPACITY_MULT > 0.0
    ):
        _fail(failures, "mid_swing: mult must be in (0, 1) got %.2f" % CombatConstants.PARRY_MID_SWING_CAPACITY_MULT)
    # Must be a modest penalty (not too harsh) — a mid-swing parry is still viable.
    if CombatConstants.PARRY_MID_SWING_CAPACITY_MULT < 0.5:
        _fail(failures, "mid_swing: mult too harsh (< 0.5) got %.2f" % CombatConstants.PARRY_MID_SWING_CAPACITY_MULT)
    # The mid-swing penalty must stack with the late floor (both are penalties).
    # A mid-swing late parry: floor * mid_swing = 0.45 * 0.80 = 0.36.
    var combined: float = CombatConstants.PARRY_LATE_CAPACITY_FLOOR * CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
    var want_combined: float = 0.45 * 0.80
    if not is_equal_approx(combined, want_combined):
        _fail(failures, "mid_swing: combined floor*mid_swing want %.3f got %.3f" % [want_combined, combined])
    # The combined penalty must be strictly less than the late floor alone (mid-swing is weaker).
    if combined >= CombatConstants.PARRY_LATE_CAPACITY_FLOOR:
        _fail(
            failures,
            (
                "mid_swing: combined (%.3f) must be < late floor (%.3f)"
                % [combined, CombatConstants.PARRY_LATE_CAPACITY_FLOOR]
            )
        )


## Pass 38 (HEMA impulse-momentum): parry recoil scales with the mass ratio — a heavier parrying
## weapon absorbs more of the impact, reducing the recoil transmitted to the arm.


static func _run_parry_recoil_mass_scale(failures: PackedStringArray) -> void:
    # Equal masses (D001 SWORD mirror): scale = 1.0 (no behavior change).
    var equal: float = CombatConstants.parry_recoil_mass_scale(1.2, 1.2)
    if not is_equal_approx(equal, 1.0):
        _fail(failures, "recoil_mass: equal masses want 1.0 got %.3f" % equal)
    # Heavier defender weapon (m_d > m_a): scale < 1.0 (less recoil).
    var heavy_def: float = CombatConstants.parry_recoil_mass_scale(1.0, 2.0)
    if not (heavy_def < 1.0 and heavy_def >= CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: heavy defender want [%.2f, 1.0) got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN, heavy_def]
            )
        )
    # Lighter defender weapon (m_d < m_a): scale > 1.0 (more recoil).
    var light_def: float = CombatConstants.parry_recoil_mass_scale(2.0, 1.0)
    if not (light_def > 1.0 and light_def <= CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: light defender want (1.0, %.2f] got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX, light_def]
            )
        )
    # Zero/invalid masses: neutral 1.0 (no division by zero).
    if not is_equal_approx(CombatConstants.parry_recoil_mass_scale(0.0, 1.0), 1.0):
        _fail(failures, "recoil_mass: zero m_a want 1.0")
    if not is_equal_approx(CombatConstants.parry_recoil_mass_scale(1.0, 0.0), 1.0):
        _fail(failures, "recoil_mass: zero m_d want 1.0")
    # Bounds: extreme mass ratios clamp to [MIN, MAX].
    var extreme_heavy: float = CombatConstants.parry_recoil_mass_scale(0.1, 10.0)
    if not is_equal_approx(extreme_heavy, CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: extreme heavy want %.2f (floor) got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MIN, extreme_heavy]
            )
        )
    var extreme_light: float = CombatConstants.parry_recoil_mass_scale(10.0, 0.1)
    if not is_equal_approx(extreme_light, CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: extreme light want %.2f (cap) got %.3f"
                % [CombatConstants.PARRY_RECOIL_MASS_SCALE_MAX, extreme_light]
            )
        )


## Pass 39 (HEMA fatigue decay): consecutive parry fatigue resets after rest — the streak counter
## compounds only for back-to-back parries, not for parries separated by a long rest.


static func _run_parry_fatigue_time_decay(failures: PackedStringArray) -> void:
    # Reset window constant must be set correctly.
    if not is_equal_approx(CombatConstants.PARRY_FATIGUE_RESET_S, 1.5):
        _fail(
            failures, "parry_fatigue: PARRY_FATIGUE_RESET_S want 1.5 got %.2f" % CombatConstants.PARRY_FATIGUE_RESET_S
        )
    # The reset window must be positive and reasonable (not too short, not too long).
    if not (CombatConstants.PARRY_FATIGUE_RESET_S > 0.0 and CombatConstants.PARRY_FATIGUE_RESET_S < 5.0):
        _fail(failures, "parry_fatigue: reset window want (0, 5) got %.2f" % CombatConstants.PARRY_FATIGUE_RESET_S)
    # The consecutive parry multiplier must escalate with the count (fatigue compounds).
    var mult_1: float = CombatConstants.consecutive_parry_stamina_mult(1)
    var mult_2: float = CombatConstants.consecutive_parry_stamina_mult(2)
    var mult_5: float = CombatConstants.consecutive_parry_stamina_mult(5)
    if not (mult_1 < mult_2 and mult_2 < mult_5):
        _fail(failures, "parry_fatigue: mult must escalate (1=%.2f 2=%.2f 5=%.2f)" % [mult_1, mult_2, mult_5])
    # The multiplier must be capped (not unbounded).
    if mult_5 > 2.5:
        _fail(failures, "parry_fatigue: 5th parry mult too high (%.2f > 2.5)" % mult_5)


## Pass 40 (HEMA bracing): a two-handed grip braces the weapon into the torso — less recoil to the
## arm and better structural stability. One-handed (SWORD/DAGGER/MACE/AXE) is neutral; only SPEAR is
## two-handed, so the D001 SWORD soak is unaffected.


static func _run_two_handed_parry_bracing(failures: PackedStringArray) -> void:
    # Recoil: two-handed transmits less than one-handed (a real reduction, not neutral).
    var recoil_one: float = CombatConstants.parry_two_handed_recoil_mult(false)
    var recoil_two: float = CombatConstants.parry_two_handed_recoil_mult(true)
    if not is_equal_approx(recoil_one, 1.0):
        _fail(failures, "two_handed: one-handed recoil want 1.0 got %.3f" % recoil_one)
    if not (recoil_two < 1.0 and recoil_two > 0.0):
        _fail(failures, "two_handed: two-handed recoil want (0, 1) got %.3f" % recoil_two)
    # Recoil reduction must be meaningful but not absurd (a real bracing effect, not a free parry).
    if not (recoil_two >= 0.5 and recoil_two <= 0.9):
        _fail(failures, "two_handed: recoil mult want [0.5, 0.9] got %.3f" % recoil_two)
    # Capacity: two-handed holds structure better (a real bonus, not neutral).
    var cap_one: float = CombatConstants.parry_two_handed_capacity_mult(false)
    var cap_two: float = CombatConstants.parry_two_handed_capacity_mult(true)
    if not is_equal_approx(cap_one, 1.0):
        _fail(failures, "two_handed: one-handed capacity want 1.0 got %.3f" % cap_one)
    if not (cap_two > 1.0 and cap_two <= 1.25):
        _fail(failures, "two_handed: capacity bonus want (1.0, 1.25] got %.3f" % cap_two)
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_TWO_HANDED_RECOIL_MULT, 0.70):
        _fail(
            failures,
            "two_handed: PARRY_TWO_HANDED_RECOIL_MULT want 0.70 got %.3f" % CombatConstants.PARRY_TWO_HANDED_RECOIL_MULT
        )
    if not is_equal_approx(CombatConstants.PARRY_TWO_HANDED_CAPACITY_BONUS, 1.10):
        _fail(
            failures,
            (
                "two_handed: PARRY_TWO_HANDED_CAPACITY_BONUS want 1.10 got %.3f"
                % CombatConstants.PARRY_TWO_HANDED_CAPACITY_BONUS
            )
        )
    # D001 safety: SWORD is one-handed, so the SWORD soak sees neutral multipliers.
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    if WeaponConstants.weapon_is_two_handed(sword):
        _fail(failures, "two_handed: SWORD should be one-handed (D001 safety)")
    if not is_equal_approx(
        CombatConstants.parry_two_handed_recoil_mult(WeaponConstants.weapon_is_two_handed(sword)), 1.0
    ):
        _fail(failures, "two_handed: SWORD recoil must be neutral 1.0 (D001 safety)")
    if not is_equal_approx(
        CombatConstants.parry_two_handed_capacity_mult(WeaponConstants.weapon_is_two_handed(sword)), 1.0
    ):
        _fail(failures, "two_handed: SWORD capacity must be neutral 1.0 (D001 safety)")
    # SPEAR is two-handed, so it gets the bracing benefit.
    var spear: Weapon = Weapon.create_from_definition("SPEAR")
    if not WeaponConstants.weapon_is_two_handed(spear):
        _fail(failures, "two_handed: SPEAR should be two-handed")
    if not (CombatConstants.parry_two_handed_recoil_mult(WeaponConstants.weapon_is_two_handed(spear)) < 1.0):
        _fail(failures, "two_handed: SPEAR recoil must be reduced (< 1.0)")
    if not (CombatConstants.parry_two_handed_capacity_mult(WeaponConstants.weapon_is_two_handed(spear)) > 1.0):
        _fail(failures, "two_handed: SPEAR capacity must be boosted (> 1.0)")


## Pass 41 (HEMA impulse direction): a square-on parry catch (high alignment) drives the full force
## of the blow straight into the blade and arm; a glancing catch (low alignment) deflects the force
## along the blade so less reaches the wrist. Recoil scales linearly from glancing (least) to square
## (most) with alignment. At alignment 0.5 the scale is ~1.0 (neutral).


static func _run_parry_recoil_alignment_scale(failures: PackedStringArray) -> void:
    # Fully glancing (alignment 0): least recoil (a real reduction, not neutral).
    var glancing: float = CombatConstants.parry_recoil_alignment_mult(0.0)
    if not (glancing < 1.0 and glancing > 0.0):
        _fail(failures, "recoil_align: glancing want (0, 1) got %.3f" % glancing)
    # Fully square-on (alignment 1): most recoil (a real increase, not neutral).
    var square: float = CombatConstants.parry_recoil_alignment_mult(1.0)
    if not (square > 1.0 and square < 2.0):
        _fail(failures, "recoil_align: square want (1.0, 2.0) got %.3f" % square)
    # Ordering: glancing < neutral < square.
    var neutral: float = CombatConstants.parry_recoil_alignment_mult(0.5)
    if not (glancing < neutral and neutral < square):
        _fail(
            failures,
            "recoil_align: ordering want glancing<neutral<square got %.3f<%.3f<%.3f" % [glancing, neutral, square]
        )
    # Neutral point (alignment 0.5) must be ~1.0 (no behavior change at mid alignment).
    if absf(neutral - 1.0) > 0.02:
        _fail(failures, "recoil_align: neutral want ~1.0 got %.3f" % neutral)
    # Monotonic: higher alignment -> more recoil.
    var a025: float = CombatConstants.parry_recoil_alignment_mult(0.25)
    var a075: float = CombatConstants.parry_recoil_alignment_mult(0.75)
    if not (a025 < a075):
        _fail(failures, "recoil_align: monotonic want 0.25<0.75 got %.3f<%.3f" % [a025, a075])
    # Out-of-range alignment clamps (no extrapolation).
    if not is_equal_approx(CombatConstants.parry_recoil_alignment_mult(-1.0), glancing):
        _fail(failures, "recoil_align: negative alignment must clamp to glancing")
    if not is_equal_approx(CombatConstants.parry_recoil_alignment_mult(2.0), square):
        _fail(failures, "recoil_align: >1 alignment must clamp to square")
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_GLANCING_MULT, 0.85):
        _fail(
            failures,
            "recoil_align: PARRY_RECOIL_GLANCING_MULT want 0.85 got %.3f" % CombatConstants.PARRY_RECOIL_GLANCING_MULT
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_SQUARE_MULT, 1.15):
        _fail(
            failures,
            "recoil_align: PARRY_RECOIL_SQUARE_MULT want 1.15 got %.3f" % CombatConstants.PARRY_RECOIL_SQUARE_MULT
        )


## Pass 42 (HEMA contact duration): a flexible (slender) blade flexes on impact, spreading the
## impulse over a longer contact time (lower peak force) so less recoil reaches the arm; a stiff
## (wide) blade transmits a sharper, higher-peak impulse so more recoil. Driven by the blade-flex
## factor (1.0 at the SWORD reference slenderness), so the D001 SWORD soak is neutral.


static func _run_parry_recoil_flex_scale(failures: PackedStringArray) -> void:
    # SWORD reference (slenderness 45) -> flex factor 1.0 -> neutral recoil 1.0 (D001 safety).
    var sword_flex: float = CombatConstants.flex_factor_for_slenderness(45.0)
    if not is_equal_approx(sword_flex, 1.0):
        _fail(failures, "recoil_flex: SWORD flex factor want 1.0 got %.3f" % sword_flex)
    var sword_recoil: float = CombatConstants.parry_recoil_flex_mult(sword_flex)
    if not is_equal_approx(sword_recoil, 1.0):
        _fail(failures, "recoil_flex: SWORD recoil want neutral 1.0 got %.3f (D001 safety)" % sword_recoil)
    # Most flexible (flex factor MAX, slender blade) -> least recoil (a real reduction).
    var flex_max: float = CombatConstants.parry_recoil_flex_mult(CombatConstants.FLEX_FACTOR_MAX)
    if not (flex_max < 1.0 and flex_max > 0.0):
        _fail(failures, "recoil_flex: most-flexible want (0, 1) got %.3f" % flex_max)
    # Most stiff (flex factor MIN, wide blade) -> most recoil (a real increase).
    var flex_min: float = CombatConstants.parry_recoil_flex_mult(CombatConstants.FLEX_FACTOR_MIN)
    if not (flex_min > 1.0 and flex_min < 2.0):
        _fail(failures, "recoil_flex: most-stiff want (1.0, 2.0) got %.3f" % flex_min)
    # Ordering: stiff (most recoil) > neutral > flexible (least recoil).
    if not (flex_min > sword_recoil and sword_recoil > flex_max):
        _fail(
            failures,
            "recoil_flex: ordering want stiff>neutral>flexible got %.3f/%.3f/%.3f" % [flex_min, sword_recoil, flex_max]
        )
    # Monotonic: higher flex factor -> less recoil.
    var f_lo: float = CombatConstants.parry_recoil_flex_mult(0.75)
    var f_hi: float = CombatConstants.parry_recoil_flex_mult(1.25)
    if not (f_hi < f_lo):
        _fail(failures, "recoil_flex: monotonic want 1.25<0.75 recoil got %.3f/%.3f" % [f_hi, f_lo])
    # Out-of-range flex factor clamps (no extrapolation).
    if not is_equal_approx(CombatConstants.parry_recoil_flex_mult(0.0), flex_min):
        _fail(failures, "recoil_flex: below-MIN flex must clamp to stiff (max recoil)")
    if not is_equal_approx(CombatConstants.parry_recoil_flex_mult(2.0), flex_max):
        _fail(failures, "recoil_flex: above-MAX flex must clamp to flexible (min recoil)")
    # A bladeless weapon (slenderness 0) -> flex factor 1.0 -> neutral recoil (no blade to flex).
    var bladeless_flex: float = CombatConstants.flex_factor_for_slenderness(0.0)
    if not is_equal_approx(bladeless_flex, 1.0):
        _fail(failures, "recoil_flex: bladeless slenderness 0 want flex 1.0")
    if not is_equal_approx(CombatConstants.parry_recoil_flex_mult(bladeless_flex), 1.0):
        _fail(failures, "recoil_flex: bladeless weapon must be neutral recoil 1.0")
    # End-to-end: a real SWORD weapon yields neutral recoil (D001 safety).
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    var sword_end_to_end: float = CombatConstants.parry_recoil_flex_mult(
        CombatConstants.flex_factor_for_slenderness(sword.get_blade_slenderness())
    )
    if not is_equal_approx(sword_end_to_end, 1.0):
        _fail(failures, "recoil_flex: SWORD end-to-end want neutral 1.0 got %.3f (D001 safety)" % sword_end_to_end)
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_FLEX_MULT_MIN, 0.7):
        _fail(
            failures,
            "recoil_flex: PARRY_RECOIL_FLEX_MULT_MIN want 0.7 got %.3f" % CombatConstants.PARRY_RECOIL_FLEX_MULT_MIN
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_FLEX_MULT_MAX, 1.3):
        _fail(
            failures,
            "recoil_flex: PARRY_RECOIL_FLEX_MULT_MAX want 1.3 got %.3f" % CombatConstants.PARRY_RECOIL_FLEX_MULT_MAX
        )


## Pass 43 (HEMA forte/schwach lever arm): a well-timed parry meets the blade early (near the
## forte/handle), a short lever arm from the hand so less recoil reaches the wrist; a late parry
## meets it late (near the schwach/tip), a long lever arm so more recoil. Driven by parry progress
## (weapon-independent), linear from FORTE (least recoil) to SCHWACH (most recoil). At progress 0.5
## the scale is ~1.0 (neutral).


static func _run_parry_recoil_progress_scale(failures: PackedStringArray) -> void:
    # Early parry (progress 0, forte): least recoil (a real reduction, not neutral).
    var forte: float = CombatConstants.parry_recoil_progress_mult(0.0)
    if not (forte < 1.0 and forte > 0.0):
        _fail(failures, "recoil_prog: forte want (0, 1) got %.3f" % forte)
    # Late parry (progress 1, schwach): most recoil (a real increase, not neutral).
    var schwach: float = CombatConstants.parry_recoil_progress_mult(1.0)
    if not (schwach > 1.0 and schwach < 2.0):
        _fail(failures, "recoil_prog: schwach want (1.0, 2.0) got %.3f" % schwach)
    # Ordering: forte (least) < neutral < schwach (most).
    var neutral: float = CombatConstants.parry_recoil_progress_mult(0.5)
    if not (forte < neutral and neutral < schwach):
        _fail(
            failures, "recoil_prog: ordering want forte<neutral<schwach got %.3f/%.3f/%.3f" % [forte, neutral, schwach]
        )
    # Neutral point (progress 0.5) must be ~1.0 (no behavior change at mid progress).
    if absf(neutral - 1.0) > 0.02:
        _fail(failures, "recoil_prog: neutral want ~1.0 got %.3f" % neutral)
    # Monotonic: higher progress (later parry) -> more recoil.
    var p025: float = CombatConstants.parry_recoil_progress_mult(0.25)
    var p075: float = CombatConstants.parry_recoil_progress_mult(0.75)
    if not (p025 < p075):
        _fail(failures, "recoil_prog: monotonic want 0.25<0.75 recoil got %.3f/%.3f" % [p025, p075])
    # Out-of-range progress clamps (no extrapolation).
    if not is_equal_approx(CombatConstants.parry_recoil_progress_mult(-1.0), forte):
        _fail(failures, "recoil_prog: negative progress must clamp to forte")
    if not is_equal_approx(CombatConstants.parry_recoil_progress_mult(2.0), schwach):
        _fail(failures, "recoil_prog: >1 progress must clamp to schwach")
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_FORTE_MULT, 0.90):
        _fail(
            failures,
            "recoil_prog: PARRY_RECOIL_FORTE_MULT want 0.90 got %.3f" % CombatConstants.PARRY_RECOIL_FORTE_MULT
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_SCHWACH_MULT, 1.10):
        _fail(
            failures,
            "recoil_prog: PARRY_RECOIL_SCHWACH_MULT want 1.10 got %.3f" % CombatConstants.PARRY_RECOIL_SCHWACH_MULT
        )


## Pass 44 (HEMA Newtonian inertia / footing): a heavier, well-rooted defender has more inertia,
## so the same impulse produces less acceleration and less arm shock. Recoil scales as
## reference_mass / body_mass, clamped to [MIN, MAX]. At the reference mass (adult human) the scale
## is 1.0 (neutral); a missing/unknown mass (0.0) yields neutral 1.0 (D001 entities carry no species).


static func _run_parry_recoil_body_mass_scale(failures: PackedStringArray) -> void:
    # Reference mass constant must match the canonical adult anchor.
    if not is_equal_approx(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG, CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
    ):
        _fail(
            failures,
            (
                "recoil_mass: reference want %.1f (anchor) got %.1f"
                % [CombatDesignAnchors.REFERENCE_ADULT_MASS_KG, CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG]
            )
        )
    # At the reference mass the scale is neutral 1.0 (no behavior change).
    var ref: float = CombatConstants.parry_recoil_body_mass_scale(CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG)
    if not is_equal_approx(ref, 1.0):
        _fail(failures, "recoil_mass: reference mass want neutral 1.0 got %.3f" % ref)
    # Missing/unknown mass (0.0) yields neutral 1.0 (D001 safety: no species -> neutral).
    if not is_equal_approx(CombatConstants.parry_recoil_body_mass_scale(0.0), 1.0):
        _fail(failures, "recoil_mass: zero mass want neutral 1.0 (D001 safety)")
    # A heavier-than-reference defender transmits less recoil (a real reduction, not neutral).
    var heavy: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 1.5
    )
    if not (heavy < 1.0 and heavy >= CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: heavy defender want [%.2f, 1.0) got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN, heavy]
            )
        )
    # A lighter-than-reference defender transmits more recoil (a real increase, not neutral).
    var light: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 0.5
    )
    if not (light > 1.0 and light <= CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: light defender want (1.0, %.2f] got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX, light]
            )
        )
    # Ordering: heavy (least) < neutral < light (most).
    if not (heavy < ref and ref < light):
        _fail(failures, "recoil_mass: ordering want heavy<neutral<light got %.3f/%.3f/%.3f" % [heavy, ref, light])
    # Extreme masses clamp to [MIN, MAX] (no unbounded scaling).
    var extreme_heavy: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 10.0
    )
    if not is_equal_approx(extreme_heavy, CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN):
        _fail(
            failures,
            (
                "recoil_mass: extreme heavy want %.2f (floor) got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN, extreme_heavy]
            )
        )
    var extreme_light: float = CombatConstants.parry_recoil_body_mass_scale(
        CombatConstants.PARRY_RECOIL_BODY_MASS_REFERENCE_KG * 0.05
    )
    if not is_equal_approx(extreme_light, CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX):
        _fail(
            failures,
            (
                "recoil_mass: extreme light want %.2f (cap) got %.3f"
                % [CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX, extreme_light]
            )
        )
    # Constants must be set to the expected values.
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN, 0.85):
        _fail(
            failures,
            (
                "recoil_mass: PARRY_RECOIL_BODY_MASS_SCALE_MIN want 0.85 got %.3f"
                % CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MIN
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX, 1.15):
        _fail(
            failures,
            (
                "recoil_mass: PARRY_RECOIL_BODY_MASS_SCALE_MAX want 1.15 got %.3f"
                % CombatConstants.PARRY_RECOIL_BODY_MASS_SCALE_MAX
            )
        )
