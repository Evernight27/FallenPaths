class_name DefenseParryClash
extends RefCounted

## Parry clash computation: attack angle at contact, strike kinematics (KE / velocity / momentum),
## and assembly of the **`parry_clash_context`** dict attached to parry deflect/partial results.
## Pure helpers called by **`DefenseResolutionHandler._resolve_parry`**; no mutation, no state.


static func _parry_attack_angle_deg(
    atk: Dictionary, arc_start: float, arc_end: float, parry_progress: float, eff_atk_line: String
) -> float:
    var angle: float = (
        CombatConstants.get_arc_angle_at_progress(arc_start, arc_end, parry_progress)
        if arc_end >= -900.0
        else CombatConstants.line_to_angle(eff_atk_line)
    )
    return CombatFootwork.apply_offset_to_angle_deg(angle, atk)


static func _strike_kinematics_for_parry_clash(
    atk_weapon: Variant,
    pa: Dictionary,
    attack_type: String,
    intensity: float,
    archetype: Dictionary,
    strike_velocity_m_s: float = -999.0
) -> Dictionary:
    var arch_id: String = CombatantEntityAccess.weapon_archetype_id(atk_weapon, attack_type, "")
    var kinematic_delivery_str: String = WeaponDamageHelper.kinematic_delivery(archetype, attack_type)
    var strike_v: float = strike_velocity_m_s
    var strike_ke: float = 0.0
    var strike_momentum: float = 0.0
    if atk_weapon != null:
        var attack_instance: AttackInstance = AttackInstance.new(attack_type, intensity, -1.0)
        attack_instance.archetype = archetype
        if strike_v < -900.0:
            strike_v = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
            strike_v *= StrikeRealismProfile.velocity_intent_mult_from_pa(
                pa, atk_weapon, attack_type, float(pa.get(DataKeys.ATTACK_INTENSITY, intensity)), archetype
            )
        var parry_wind_up_dur: float = pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)
        var parry_wuf: float = CombatTiming.wind_up_factor(parry_wind_up_dur) if parry_wind_up_dur > 0.0 else 1.0
        if parry_wuf < 1.0:
            strike_v *= parry_wuf
        attack_instance.velocity_m_s = strike_v
        strike_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_weapon, attack_instance)
        var strike_mass: float = WeaponDamageHelper.strike_mass_kg(atk_weapon, attack_instance)
        strike_momentum = strike_mass * strike_v
    return {
        "archetype_id": arch_id,
        "kinematic_delivery": kinematic_delivery_str,
        "strike_velocity_m_s": strike_v,
        "strike_kinetic_energy_j": strike_ke,
        "strike_momentum_kg_ms": strike_momentum,
    }


static func _build_parry_clash_context(
    eff_atk_line: String,
    attack_type: String,
    attack_angle_deg: float,
    c_d_final: float,
    parry_p_a: float,
    parry_c_d: float,
    alignment: float,
    guard_line: String,
    guard_angle_deg: float,
    parry_time_to_react: float,
    parry_readiness: float,
    late_parry: bool,
    parry_off_balance: bool,
    is_block_parry: bool,
    m_a_parry: float,
    m_d_parry: float,
    m_a_velocity: float,
    kinematics: Dictionary,
    strike_measure_ratio: float,
    extra: Dictionary = {},
    def_weapon: Variant = null,
    parry_progress: float = 0.5
) -> Dictionary:
    var contact_ct: String = WeaponConstants.contact_type_for_move_id(attack_type)
    var margin_ratio: float = CombatConstants.parry_deflect_margin_ratio(c_d_final, parry_p_a)
    # Blade-width friction (HEMA waffenfühlen): the parrying weapon's blade width sets bind friction.
    var bind_friction: float = CombatConstants.bind_friction_mult_for_weapon(def_weapon)
    var parry_control: float = CombatConstants.parry_control_for_bind_deflect(
        c_d_final, parry_p_a, alignment, parry_readiness, parry_off_balance, late_parry, contact_ct, bind_friction
    )
    var ctx: Dictionary = {
        "archetype_id": kinematics.get(DataKeys.PA_ARCHETYPE_ID, ""),
        "parry_control": parry_control,
        "parry_p_a": parry_p_a,
        "parry_c_d": parry_c_d,
        "c_d_final": c_d_final,
        "m_a_parry": m_a_parry,
        "m_d_parry": m_d_parry,
        "m_a_velocity": m_a_velocity,
        "margin_ratio": margin_ratio,
        ## IV-5: raw (pre-interpose) alignment — parry_control and harness validation use this same value;
        ## interpose boost is captured separately in arm_interpose_boost / arm_interpose_arm fields.
        "alignment": alignment,
        "defender_guard_line": guard_line,
        "guard_angle_deg": guard_angle_deg,
        "parry_time_to_react": parry_time_to_react,
        "parry_progress": parry_progress,
        "parry_readiness": parry_readiness,
        "late_parry": late_parry,
        "parry_off_balance": parry_off_balance,
        "is_block_parry": is_block_parry,
        "attack_type": attack_type,
        "contact_type": contact_ct,
        "effective_attack_line": eff_atk_line,
        "severity": CombatConstants.parry_deflect_severity_from_margin_ratio(margin_ratio),
        "attack_angle_deg": attack_angle_deg,
        "kinematic_delivery": kinematics.get(DataKeys.WD_KINEMATIC_DELIVERY, ""),
        "strike_velocity_m_s": kinematics.get("strike_velocity_m_s", -1.0),
        "strike_kinetic_energy_j": kinematics.get("strike_kinetic_energy_j", 0.0),
        "strike_momentum_kg_ms": kinematics.get("strike_momentum_kg_ms", 0.0),
        "strike_measure_ratio": strike_measure_ratio,
    }
    for k in extra:
        ctx[k] = extra[k]
    return ctx
