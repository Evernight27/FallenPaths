class_name DefenseParryResolution
extends RefCounted

## Parry contact resolution, extracted from **`DefenseResolutionHandler`**.
## Handles the full parry deflect/partial outcome computation: clash geometry, glancing
## factors, recovery timing, and bind/flurry transitions. Pure code motion — no behavior
## change. All external deps are class_name references (no circular preload).

## Minimum strike mass (kg) for velocity computation in parry resolution — prevents division-by-zero when weapon
## parts data is missing or mass is zero. 1 g is below any realistic weapon component; at this floor v_reduced
## becomes unphysically high but the subsequent `maxf(v_reduced, v_min_eff)` line caps it to intent velocity.
const MIN_STRIKE_MASS_FOR_VEL_KG: float = 0.001


static func _arm_interpose_clash_extra(dc: Dictionary) -> Dictionary:
    var boost: float = dc.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0)
    if boost <= 0.0:
        return {}
    return {
        "arm_interpose_arm": str(dc.get(CombatConstants.CLASH_KEY_ARM_INTERPOSE, "")),
        "arm_interpose_boost": boost,
    }


static func resolve_parry(
    pa: Dictionary,
    atk: Dictionary,
    tgt: Dictionary,
    attack_type: String,
    intensity: float,
    archetype: Dictionary,
    recovery_mult: float,
    parry_p_a: float,
    parry_c_d: float,
    parry_time_to_react: float,
    parry_readiness: float,
    is_block_parry: bool,
    m_a_parry: float,
    m_d_parry: float,
    m_a_velocity: float,
    _effective_redirect: float,
    late_parry: bool,
    parry_off_balance: bool,
    target_id: int,
    atk_name: String,
    _tgt_name: String,
    dc: Dictionary = {}
) -> Variant:
    var interpose_extra: Dictionary = _arm_interpose_clash_extra(dc)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    pa[DataKeys.PA_PASSIVE_PARRY_ATTEMPTED] = true
    pa[DataKeys.PA_PARRY_TWIST_TIME_TO_REACT] = parry_time_to_react
    pa[DataKeys.PA_PARRY_TWIST_READINESS] = parry_readiness
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var attack_line: String = pa.get(
        DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high")
    )
    var guard_line: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
    # Arc tracking: use blade position at parry contact for alignment (where blades meet).
    var parry_progress: float = 1.0
    if not late_parry:
        var eff_wind: float = (
            pa.get(DataKeys.PA_WIND_UP_DURATION, 0.5)
            * (1.0 - CombatConstants.commitment_fraction_for_pending_attack(pa))
        )
        parry_progress = 1.0 - clampf(parry_time_to_react / maxf(0.001, eff_wind), 0.0, 1.0)
    var align_ctx: Dictionary = {}
    var arc_start: float = pa.get(DataKeys.ATTACK_ARC_START_DEG, 0.0)
    var arc_end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
    if arc_end >= -900.0:
        var attack_angle_at_contact: float = CombatConstants.get_arc_angle_at_progress(
            arc_start, arc_end, parry_progress
        )
        attack_angle_at_contact = CombatFootwork.apply_offset_to_angle_deg(attack_angle_at_contact, atk)
        var wobble: Dictionary = CombatantEntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
        align_ctx = {
            "attack_angle_deg": attack_angle_at_contact,
            "guard_angle_deg": CombatFootwork.guard_angle_deg(tgt, wobble),
        }
    var alignment: float = CombatConstants.get_line_alignment_with_deflect(attack_line, tgt, align_ctx)
    var c_d_final: float = parry_c_d
    if CombatConstants.PARRY_TECHNIQUE_VARIANCE > 0.0:
        var agi_var: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
        var variance_scale: float = clampf(
            1.0 - CombatConstants.PARRY_VARIANCE_AGILITY_SCALE * (agi_var - 100.0) / 100.0,
            CombatConstants.STAMINA_MULT_FLOOR,
            CombatConstants.STAMINA_MULT_CEILING
        )
        var variance_eff: float = CombatConstants.PARRY_TECHNIQUE_VARIANCE * variance_scale
        var geom_scale: float = clampf(
            1.0 / maxf(CombatConstants.PARRY_VARIANCE_GEOM_MIN, alignment), 1.0, CombatConstants.PARRY_VARIANCE_GEOM_MAX
        )
        variance_eff *= geom_scale
        c_d_final *= randf_range(1.0 - variance_eff, 1.0 + variance_eff)
    var effective_alignment: float = alignment
    if not interpose_extra.is_empty():
        effective_alignment = minf(1.0, alignment + interpose_extra.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0))
    var interpose_note: String = ""
    if not interpose_extra.is_empty():
        interpose_note = (
            " interpose_arm=%s boost=%.3f"
            % [
                interpose_extra.get(CombatConstants.CLASH_KEY_ARM_INTERPOSE, ""),
                interpose_extra.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0)
            ]
        )
    var pcfg: Dictionary = PassiveParryContext.get_parry_config()
    var glancing_exp: float = pcfg.get("glancing_exponent", CombatConstants.PARRY_GLANCING_EXPONENT)
    var def_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
    CombatDebug.log(
        (
            "parry %s block=%s align=%.3f eff_align=%.3f c_d_final=%.2f p_a=%.2f"
            % [def_name, is_block_parry, alignment, effective_alignment, c_d_final, parry_p_a]
        )
    )
    if CombatConstants.COMBAT_DEBUG_CALIBRATION:
        var geom_scale: float = clampf(
            1.0 / maxf(CombatConstants.PARRY_VARIANCE_GEOM_MIN, alignment), 1.0, CombatConstants.PARRY_VARIANCE_GEOM_MAX
        )
        var angle_suffix: String = ""
        if pa.get(DataKeys.ATTACK_ATTACK_ANGLE_DEG, -999.0) >= 0.0:
            var wobble_cal: Dictionary = CombatantEntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
            angle_suffix = (
                " atk_deg=%.0f guard_deg=%.0f"
                % [pa[DataKeys.ATTACK_ANGLE_DEG], CombatFootwork.guard_angle_deg(tgt, wobble_cal)]
            )
        CombatDebug.calibration_log(
            (
                "parry_calc atk=%s guard=%s align=%.3f eff_align=%.3f c_d_final=%.2f p_a=%.2f geom_scale=%.2f%s%s"
                % [
                    attack_line,
                    guard_line,
                    alignment,
                    effective_alignment,
                    c_d_final,
                    parry_p_a,
                    geom_scale,
                    angle_suffix,
                    interpose_note
                ]
            )
        )
    var contact_type_full_stop: String = WeaponConstants.contact_type_for_move_id(attack_type)
    var full_stop: bool = CombatConstants.parry_full_stop_reached(
        c_d_final, parry_p_a, is_block_parry, contact_type_full_stop
    )
    if full_stop:
        var parry_intensity: float = pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
        var atk_perf: float = CombatantEntityAccess.get_performance_modifier(atk)
        var contact_type_for_outcome: String = contact_type_full_stop
        # Guard transition cost: parry pushes blade to attack line; repositioning to a different guard costs extra time.
        # A staggered attacker has less blade control while recovering from the parry.
        var guard_trans_cost: float = (
            CombatTiming.compute_guard_transition_cost_s(guard_line, attack_line)
            * CombatConstants.guard_transition_off_balance_mult(PassiveParryContext.off_balance_depth(atk))
            * CombatConstants.guard_transition_fatigue_mult(
                CombatMuscleFatigue.limb_fatigue(atk, CombatMuscleFatigue.dominant_strike_limb(atk))
            )
        )
        var rec_dur: float = CombatTiming.recovery_duration_with_form(
            parry_intensity,
            "full_stop",
            recovery_mult,
            atk_perf,
            atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
            -1.0,
            CombatantEntityAccess.form_str(atk),
            CombatantEntityAccess.get_weapon(atk),
            guard_trans_cost
        )
        # Thrust deflections cost more recovery — redirecting linear body-weight momentum requires full blade
        # repositioning.
        if contact_type_for_outcome.to_lower().strip_edges() == "stab":
            rec_dur *= CombatConstants.parry_thrust_recovery_mult(parry_intensity)
        # Deflected attacks cost extra recovery — blade knocked offline requires extra repositioning vs a clean miss.
        rec_dur *= CombatConstants.parry_deflect_recovery_mult(parry_intensity)
        var eff_atk_line: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, attack_line)
        var atk_weapon_ctx = CombatantEntityAccess.get_weapon(atk)
        var atk_angle_at_contact: float = DefenseParryClash._parry_attack_angle_deg(
            atk, arc_start, arc_end, parry_progress, eff_atk_line
        )
        var wobble_ctx: Dictionary = CombatantEntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
        var kinematics_fs: Dictionary = DefenseParryClash._strike_kinematics_for_parry_clash(
            atk_weapon_ctx, pa, attack_type, intensity, archetype
        )
        var parry_clash_context: Dictionary = DefenseParryClash._build_parry_clash_context(
            eff_atk_line,
            attack_type,
            atk_angle_at_contact,
            c_d_final,
            parry_p_a,
            parry_c_d,
            alignment,
            guard_line,
            CombatFootwork.guard_angle_deg(tgt, wobble_ctx),
            parry_time_to_react,
            parry_readiness,
            late_parry,
            parry_off_balance,
            is_block_parry,
            m_a_parry,
            m_d_parry,
            m_a_velocity,
            kinematics_fs,
            pa.get("strike_measure_ratio", -1.0),
            interpose_extra,
            CombatantEntityAccess.get_weapon(tgt),
            parry_progress
        )
        CombatDebug.log(
            (
                "parry_deflect %s blocked %s align=%.3f eff_align=%.3f ctrl=%.3f%s"
                % [
                    def_name,
                    atk_name,
                    alignment,
                    effective_alignment,
                    parry_clash_context.get(
                        CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
                    ),
                    interpose_note
                ]
            )
        )
        CombatDebug.calibration_log(
            (
                "outcome=parry_deflect c_d_final=%.2f p_a=%.2f ctrl=%.3f align=%.3f eff_align=%.3f glancing_exp=%.2f%s"
                % [
                    c_d_final,
                    parry_p_a,
                    parry_clash_context.get(
                        CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
                    ),
                    alignment,
                    effective_alignment,
                    glancing_exp,
                    interpose_note
                ]
            )
        )
        return {
            "action": "parry_deflect",
            "target_id": target_id,
            "recovery_duration": rec_dur,
            "parry_clash_context": parry_clash_context
        }
    var edge_contact_ct: String = WeaponConstants.contact_type_for_move_id(attack_type)
    var edge_contact: String = "" if edge_contact_ct.is_empty() else edge_contact_ct
    if edge_contact.is_empty():
        edge_contact = edge_contact_ct
    var atk_weapon_edge = CombatantEntityAccess.get_weapon(atk)
    var is_wide_arc_edge: bool = CombatConstantsParry.is_wide_arc_weapon(atk_weapon_edge)
    var eff_atk_line_edge: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, attack_line)
    var edge_deflect: bool = CombatConstants.parry_edge_deflect_reached(
        c_d_final,
        parry_p_a,
        effective_alignment,
        is_block_parry,
        edge_contact,
        eff_atk_line_edge,
        guard_line,
        is_wide_arc_edge
    )
    if edge_deflect:
        var parry_intensity_edge: float = pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
        var atk_perf_edge: float = CombatantEntityAccess.get_performance_modifier(atk)
        var guard_trans_cost_edge: float = (
            CombatTiming.compute_guard_transition_cost_s(guard_line, attack_line)
            * CombatConstants.guard_transition_off_balance_mult(PassiveParryContext.off_balance_depth(atk))
            * CombatConstants.guard_transition_fatigue_mult(
                CombatMuscleFatigue.limb_fatigue(atk, CombatMuscleFatigue.dominant_strike_limb(atk))
            )
        )
        var rec_dur_edge: float = CombatTiming.recovery_duration_with_form(
            parry_intensity_edge,
            "full_stop",
            recovery_mult,
            atk_perf_edge,
            atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
            -1.0,
            CombatantEntityAccess.form_str(atk),
            CombatantEntityAccess.get_weapon(atk),
            guard_trans_cost_edge
        )
        # Thrust edge-deflections (rare but possible with strong alignment) cost more recovery.
        if edge_contact.to_lower().strip_edges() == "stab":
            rec_dur_edge *= CombatConstants.parry_thrust_recovery_mult(parry_intensity_edge)
        # Deflected attacks cost extra recovery — blade knocked offline requires extra repositioning vs a clean miss.
        rec_dur_edge *= CombatConstants.parry_deflect_recovery_mult(parry_intensity_edge)
        var atk_angle_edge: float = DefenseParryClash._parry_attack_angle_deg(
            atk, arc_start, arc_end, parry_progress, eff_atk_line_edge
        )
        var wobble_edge: Dictionary = CombatantEntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
        var kinematics_edge: Dictionary = DefenseParryClash._strike_kinematics_for_parry_clash(
            atk_weapon_edge, pa, attack_type, intensity, archetype
        )
        var parry_clash_edge: Dictionary = DefenseParryClash._build_parry_clash_context(
            eff_atk_line_edge,
            attack_type,
            atk_angle_edge,
            c_d_final,
            parry_p_a,
            parry_c_d,
            alignment,
            guard_line,
            CombatFootwork.guard_angle_deg(tgt, wobble_edge),
            parry_time_to_react,
            parry_readiness,
            late_parry,
            parry_off_balance,
            is_block_parry,
            m_a_parry,
            m_d_parry,
            m_a_velocity,
            kinematics_edge,
            pa.get("strike_measure_ratio", -1.0),
            interpose_extra,
            CombatantEntityAccess.get_weapon(tgt),
            parry_progress
        )
        CombatDebug.log(
            (
                "parry_deflect_edge %s blocked %s align=%.3f eff_align=%.3f ctrl=%.3f%s"
                % [
                    def_name,
                    atk_name,
                    alignment,
                    effective_alignment,
                    parry_clash_edge.get(
                        CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
                    ),
                    interpose_note
                ]
            )
        )
        return {
            "action": "parry_deflect",
            "target_id": target_id,
            "recovery_duration": rec_dur_edge,
            "parry_clash_context": parry_clash_edge
        }
    var attacker_weapon = CombatantEntityAccess.get_weapon(atk)
    var agi_d: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    var perc_d: float = float(tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    var contact_type_current: String = WeaponConstants.contact_type_for_move_id(attack_type)
    var redirect_mult: float = CombatConstants.compute_parry_redirect_mult(
        pcfg, agi_d, perc_d, contact_type_current, is_block_parry, m_a_parry, m_d_parry
    )
    # Thrust linear commitment: partially parried thrusts carry more residual momentum.
    # Attacker's body weight drives forward — no "slide off" geometry like cutting edge.
    var is_thrust: bool = contact_type_current.to_lower().strip_edges() == "stab"
    var base_reduction: float = c_d_final * redirect_mult
    # Conservation of momentum: even a perfect parry cannot absorb 100% of attack force.
    # Capped at PARRY_MAX_DAMAGE_REDUCTION (85%) so ~15% residual always passes through.
    base_reduction = minf(base_reduction, parry_p_a * CombatConstantsParry.PARRY_MAX_DAMAGE_REDUCTION)
    # Compute remaining momentum first (before thrust adjustment).
    var remaining_momentum_raw: float = maxf(0.0, parry_p_a - base_reduction)
    var effective_reduction_applied: float = base_reduction
    if is_thrust and remaining_momentum_raw > 0.0:
        # Thrusts reduce parry effectiveness when partially stopped — attacker drives through.
        var thrust_intensity: float = pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
        effective_reduction_applied = (
            base_reduction * (1.0 - CombatConstants.parry_thrust_commitment_penalty() * thrust_intensity)
        )
    var remaining_momentum: float = maxf(0.0, parry_p_a - effective_reduction_applied)
    var remaining_ratio: float = remaining_momentum / parry_p_a if parry_p_a > 0.0 else 0.0
    var margin_ratio_leak: float = CombatConstants.parry_deflect_margin_ratio(c_d_final, parry_p_a)
    # Non-linear geometric leak: pow(1-align,2)*max so high-alignment parries are clean (HEMA "on the blade"), while
    # oblique angles produce more leak than linear scaling.
    var geometric_leak: float = pow(1.0 - effective_alignment, 2) * CombatConstants.GEOMETRIC_LEAK_MAX
    if margin_ratio_leak < 1.0:
        geometric_leak *= clampf(margin_ratio_leak, 0.0, 1.0)
    var pre_leak_ratio: float = remaining_ratio
    remaining_ratio = minf(1.0, remaining_ratio + geometric_leak)
    # Parry so ineffective it's a hit — fall through to normal damage resolution.
    if remaining_ratio > CombatConstants.PARRY_PARTIAL_MAX_RATIO:
        return null
    # Redirect completely stopped the attack even though raw c_d didn't reach the full_stop threshold.
    if remaining_ratio <= 0.0:
        var parry_intensity_zero: float = pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
        var atk_perf_zero: float = CombatantEntityAccess.get_performance_modifier(atk)
        var guard_trans_cost_zero: float = (
            CombatTiming.compute_guard_transition_cost_s(guard_line, attack_line)
            * CombatConstants.guard_transition_off_balance_mult(PassiveParryContext.off_balance_depth(atk))
            * CombatConstants.guard_transition_fatigue_mult(
                CombatMuscleFatigue.limb_fatigue(atk, CombatMuscleFatigue.dominant_strike_limb(atk))
            )
        )
        var rec_dur_zero: float = CombatTiming.recovery_duration_with_form(
            parry_intensity_zero,
            "full_stop",
            recovery_mult,
            atk_perf_zero,
            atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
            -1.0,
            CombatantEntityAccess.form_str(atk),
            CombatantEntityAccess.get_weapon(atk),
            guard_trans_cost_zero
        )
        # Thrust redirect-stops also cost more recovery.
        if is_thrust:
            rec_dur_zero *= CombatConstants.parry_thrust_recovery_mult(parry_intensity_zero)
        # Deflected attacks cost extra recovery — blade knocked offline requires extra repositioning vs a clean miss.
        rec_dur_zero *= CombatConstants.parry_deflect_recovery_mult(parry_intensity_zero)
        var eff_atk_line_z: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, attack_line)
        var atk_weapon_z = CombatantEntityAccess.get_weapon(atk)
        var atk_angle_z: float = DefenseParryClash._parry_attack_angle_deg(
            atk, arc_start, arc_end, parry_progress, eff_atk_line_z
        )
        var wobble_z: Dictionary = CombatantEntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
        var kinematics_z: Dictionary = DefenseParryClash._strike_kinematics_for_parry_clash(
            atk_weapon_z, pa, attack_type, intensity, archetype
        )
        var partial_extra_z: Dictionary = {"remaining_ratio": 0.0, "geometric_leak": geometric_leak}
        for k in interpose_extra:
            partial_extra_z[k] = interpose_extra[k]
        var parry_clash_zero: Dictionary = DefenseParryClash._build_parry_clash_context(
            eff_atk_line_z,
            attack_type,
            atk_angle_z,
            c_d_final,
            parry_p_a,
            parry_c_d,
            alignment,
            guard_line,
            CombatFootwork.guard_angle_deg(tgt, wobble_z),
            parry_time_to_react,
            parry_readiness,
            late_parry,
            parry_off_balance,
            is_block_parry,
            m_a_parry,
            m_d_parry,
            m_a_velocity,
            kinematics_z,
            pa.get("strike_measure_ratio", -1.0),
            partial_extra_z,
            CombatantEntityAccess.get_weapon(tgt),
            parry_progress
        )
        CombatDebug.log(
            (
                "parry_deflect_redirect %s blocked %s ctrl=%.3f"
                % [
                    def_name,
                    atk_name,
                    parry_clash_zero.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL)
                ]
            )
        )
        # The [HEMA] exchange line already carries parry=deflect + ctrl; this applier record is redundant for
        # realism debugging. Gate behind the calibration trace to keep the always-on log dense.
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session(
                (
                    "parry_outcome def=%s vs atk=%s action=parry_deflect ctrl=%.3f"
                    % [
                        def_name,
                        atk_name,
                        parry_clash_zero.get(
                            CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
                        )
                    ]
                )
            )
        return {
            "action": "parry_deflect",
            "target_id": target_id,
            "recovery_duration": rec_dur_zero,
            "parry_clash_context": parry_clash_zero
        }
    if CombatConstants.combat_debug_active():
        (
            CombatDebug
            . calibration_log(
                (
                    (
                        "parry_partial c_d_final=%.2f p_a=%.2f align=%.3f eff_align=%.3f pre_leak=%.2f leak=%.2f "
                        + "final_ratio=%.2f glancing_exp=%.2f m_a_vel=%.2f%s"
                    )
                    % [
                        c_d_final,
                        parry_p_a,
                        alignment,
                        effective_alignment,
                        pre_leak_ratio,
                        geometric_leak,
                        remaining_ratio,
                        glancing_exp,
                        m_a_velocity,
                        interpose_note,
                    ]
                )
            )
        )
    var glancing_factor: float = CombatConstants.glancing_factor(remaining_ratio, glancing_exp)
    var attack_instance = AttackInstance.new(attack_type, intensity)
    attack_instance.archetype = archetype
    var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance)
    if attacker_weapon != null:
        v_intent *= StrikeRealismProfile.velocity_intent_mult_from_pa(
            pa, attacker_weapon, attack_type, float(pa.get(DataKeys.ATTACK_INTENSITY, intensity)), archetype
        )
    var partial_wind_up_dur: float = pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)
    var partial_wuf: float = CombatTiming.wind_up_factor(partial_wind_up_dur) if partial_wind_up_dur > 0.0 else 1.0
    if partial_wuf < 1.0:
        v_intent *= partial_wuf
    # Use m_a_velocity (striking part mass when weapon has parts) for v_reduced; else m_a_parry (total mass).
    var m_a_vel: float = m_a_velocity if m_a_velocity > 0.0 else m_a_parry
    var v_reduced: float = (parry_p_a * glancing_factor) / maxf(MIN_STRIKE_MASS_FOR_VEL_KG, m_a_vel)
    # Clamp reduced velocity to prevent unphysical amplification from small division mass.
    # A parry follow-through cannot exceed the attacker's intent velocity, and for heavy weapons
    # (spear ~2kg strike mass) should retain more momentum than light weapons (dagger ~0.45kg).
    v_reduced = (
        minf(v_reduced, v_intent * CombatConstants.PARRY_FOLLOW_THROUGH_VEL_CLAMP) if v_intent > 0.0 else v_reduced
    )
    var strike_mass_for_floor: float = (
        m_a_vel if m_a_vel >= MIN_STRIKE_MASS_FOR_VEL_KG else CombatConstants.PARRY_V_MIN_FALLBACK_MASS_KG
    )
    var v_min_mass_scaled: float = (
        maxf(
            CombatConstants.PARRY_V_MIN_NEAR_DEFLECT,
            (
                clampf(strike_mass_for_floor / CombatConstants.PARRY_V_MIN_REFERENCE_MASS_KG, 0.0, 1.0)
                * (v_intent * CombatConstants.PARRY_V_MIN_FRACTION)
            )
        )
        if v_intent > 0.0
        else CombatConstants.PARRY_V_MIN_NEAR_DEFLECT
    )
    var v_min_eff: float = (
        v_intent
        * lerpf(
            CombatConstants.PARRY_V_MIN_NEAR_DEFLECT,
            CombatConstants.PARRY_V_MIN_FRACTION,
            clampf(remaining_ratio, 0.0, 1.0)
        )
    )
    # Use mass-scaled minimum when remaining_ratio is low (near-deflect parry): heavy weapons retain more momentum.
    var v_min_final: float = v_min_eff
    if remaining_ratio < CombatConstants.PARRY_V_MIN_MASS_SCALE_THRESHOLD:
        v_min_final = maxf(v_min_eff, v_min_mass_scaled)
    pa[DataKeys.PA_VELOCITY_M_S] = maxf(v_reduced, v_min_final)
    pa[DataKeys.ATTACK_PARRY_REMAINING_RATIO] = remaining_ratio
    CombatDebug.log(
        (
            "parry_partial %s vs %s final_ratio=%.2f (align=%.2f align_eff=%.2f pre_leak=%.2f + leak=%.2f)%s"
            % [
                def_name,
                atk_name,
                remaining_ratio,
                alignment,
                effective_alignment,
                pre_leak_ratio,
                geometric_leak,
                interpose_note
            ]
        )
    )
    # The [HEMA] exchange line already carries parry=partial + ctrl + rem; redundant for realism debugging.
    if CombatDebug.dc_trace_active():
        CombatDebug.combat_session(
            (
                "parry_outcome def=%s vs atk=%s action=parry_partial final_ratio=%.2f"
                % [def_name, atk_name, remaining_ratio]
            )
        )
    var eff_atk_line_p: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, attack_line)
    var atk_angle_partial: float = DefenseParryClash._parry_attack_angle_deg(
        atk, arc_start, arc_end, parry_progress, eff_atk_line_p
    )
    var wobble_p: Dictionary = CombatantEntityAccess.parry_wobble_context_for_combatant(tgt, parry_readiness)
    var strike_v_partial: float = pa.get("velocity_m_s", 0.0)
    var kinematics_p: Dictionary = DefenseParryClash._strike_kinematics_for_parry_clash(
        attacker_weapon, pa, attack_type, intensity, archetype, strike_v_partial
    )
    var partial_extra: Dictionary = {
        "remaining_ratio": remaining_ratio,
        "geometric_leak": geometric_leak,
    }
    for k in interpose_extra:
        partial_extra[k] = interpose_extra[k]
    var parry_clash_context_partial: Dictionary = DefenseParryClash._build_parry_clash_context(
        eff_atk_line_p,
        attack_type,
        atk_angle_partial,
        c_d_final,
        parry_p_a,
        parry_c_d,
        alignment,
        guard_line,
        CombatFootwork.guard_angle_deg(tgt, wobble_p),
        parry_time_to_react,
        parry_readiness,
        late_parry,
        parry_off_balance,
        is_block_parry,
        m_a_parry,
        m_d_parry,
        m_a_velocity,
        kinematics_p,
        pa.get("strike_measure_ratio", -1.0),
        partial_extra,
        CombatantEntityAccess.get_weapon(tgt),
        parry_progress
    )
    return {
        "action": "parry_partial",
        "target_id": target_id,
        "parry_clash_context": parry_clash_context_partial,
    }
