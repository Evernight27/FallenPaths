class_name DefenseResolutionHandler
extends RefCounted

## Resolves defense outcomes: partial parry follow-through (twist dodge), full/partial dodge, parry deflect/partial.
## Footing (strike geometry): reads **`CombatFootwork.guard_angle_deg`** + attacker offset on contact — not form home
## guard. LIVE_PATHS **`#wf-tier-44-pa`** (geometry) . **`#wf-guard-writers`**.
## **Read order:** parry deflect/partial branches → dodge branches → follow-through re-entry hooks.
## **`parry_deflect`** full-stop and **`parry_partial`** follow-through both attach a **`parry_clash_context`** dict on
## the returned result (partial adds **`remaining_ratio`** / **`geometric_leak`**; Tier **3.0** KE on partial uses
## reduced **`pa[DataKeys.PA_VELOCITY_M_S]`**).
## Returns a result dict to return from resolve_attack, or null to fall through to hit.

## Debug logging — delegates to `CombatDebug.log` which gates on `combat_debug_active`.


## Resolves defense. Returns dict with action, target_id, recovery_duration (if applicable); or null to fall through to
## hit.
static func resolve(
    pa: Dictionary,
    atk: Dictionary,
    tgt: Dictionary,
    dc: Dictionary,
    targetable: Array,
    attack_type: String,
    intensity: float,
    archetype: Dictionary,
    velocity_override: float,
    recovery_mult: float,
    perf_mod: float,
    target_id: int,
    atk_name: String,
    tgt_name: String
) -> Variant:
    var already_used_defense: bool = pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
    var defense_choice: String = dc.defense
    var parry_p_a: float = dc.parry_p_a
    var parry_c_d: float = dc.parry_c_d
    var parry_time_to_react: float = dc.parry_time_to_react
    var parry_readiness: float = dc.parry_readiness
    var is_block_parry: bool = dc.is_block_parry
    var m_a_parry: float = dc.m_a_parry
    var m_d_parry: float = dc.m_d_parry
    var dodge_chance: float = dc.dodge_chance
    var dodge_eval_part: String = dc.dodge_eval_part
    var effective_redirect: float = dc.effective_redirect

    if already_used_defense:
        var result = _resolve_partial_parry_follow_through(
            pa,
            atk,
            tgt,
            targetable,
            attack_type,
            intensity,
            archetype,
            velocity_override,
            recovery_mult,
            perf_mod,
            target_id,
            atk_name,
            tgt_name
        )
        if result != null:
            return result
    elif defense_choice == "dodge":
        var result = _resolve_dodge(
            pa,
            atk,
            tgt,
            targetable,
            attack_type,
            intensity,
            archetype,
            dodge_chance,
            dodge_eval_part,
            recovery_mult,
            perf_mod,
            target_id,
            tgt_name
        )
        if result != null:
            return result
    elif defense_choice == "parry":
        var late_parry: bool = dc.get("late_parry", false)
        var parry_off_balance: bool = dc.get("parry_off_balance", false)
        var m_a_velocity: float = dc.get("m_a_velocity", m_a_parry)
        return _resolve_parry(
            pa,
            atk,
            tgt,
            attack_type,
            intensity,
            archetype,
            recovery_mult,
            parry_p_a,
            parry_c_d,
            parry_time_to_react,
            parry_readiness,
            is_block_parry,
            m_a_parry,
            m_d_parry,
            m_a_velocity,
            effective_redirect,
            late_parry,
            parry_off_balance,
            target_id,
            atk_name,
            tgt_name,
            dc
        )
    return null


static func _resolve_partial_parry_follow_through(
    pa: Dictionary,
    atk: Dictionary,
    tgt: Dictionary,
    targetable: Array,
    attack_type: String,
    intensity: float,
    _archetype: Dictionary,
    velocity_override: float,
    recovery_mult: float,
    perf_mod: float,
    target_id: int,
    atk_name: String,
    tgt_name: String
) -> Variant:
    var time_to_react: float = pa.get("parry_twist_time_to_react", 0.0)
    var twist_readiness: float = pa.get("parry_twist_readiness", 1.0)
    var time_factor: float = clampf(
        time_to_react / maxf(0.001, CombatConstants.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S), 0.0, 1.0
    )
    if time_to_react <= 0.0:
        # Floor raised from 0.15 (Tuning T3.2): insufficient-react-time twist needs meaningful dodge capacity, not near-
        # zero.
        time_factor = CombatConstants.TWIST_DODGE_MIN_TIME_FACTOR
    var leg: float = CombatantEntityAccess.get_leg_functionality(tgt)
    var perf: float = CombatantEntityAccess.get_performance_modifier(tgt)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var agi: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    var perc: float = float(tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    var mobility_factor: float = leg * perf * CombatConstants.stats_factor_agi_perc(agi, perc)
    var twist_capacity: float = time_factor * mobility_factor * twist_readiness
    var follow_eff: float = CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY
    var attack_type_mod: float = 1.0
    var twist_ct: String = WeaponConstants.contact_type_for_move_id(attack_type)
    if twist_ct == WeaponConstants.ATTACK_TYPE_STAB:
        attack_type_mod = 1.0 - CombatConstants.PARRY_FOLLOW_THROUGH_THRUST_PENALTY
    elif twist_ct == WeaponConstants.ATTACK_TYPE_CUT:
        attack_type_mod = 1.0 + CombatConstants.PARRY_FOLLOW_THROUGH_CUT_BONUS
    var twist_partial_min: float = CombatConstants.PARRY_FOLLOW_THROUGH_PARTIAL_MIN
    var parry_ratio: float = pa.get(DataKeys.ATTACK_PARRY_REMAINING_RATIO, 1.0)
    var parry_quality_scale: float = 1.0 - CombatConstants.TWIST_DODGE_PARRY_QUALITY_SLOPE * parry_ratio
    parry_quality_scale = clampf(parry_quality_scale, CombatConstants.TWIST_DODGE_PARRY_QUALITY_FLOOR, 1.0)
    var dodge_chance_follow: float = CombatantEntityAccess.get_dodge_chance(
        tgt, pa.get(DataKeys.PA_WIND_UP_DURATION, 0.5)
    )
    var part_follow: String = (
        BodyPartConstants.get_weighted_random_part(targetable) if not targetable.is_empty() else ""
    )
    var part_mod_follow: float = CombatantEntityAccess._get_part_dodge_modifier(tgt, part_follow)
    var effective_follow_dodge: float = (
        dodge_chance_follow * follow_eff * part_mod_follow * twist_capacity * attack_type_mod * parry_quality_scale
    )
    var dodge_roll_follow: float = randf()
    if effective_follow_dodge > 0.0:
        if dodge_roll_follow < effective_follow_dodge * CombatConstants.DODGE_FULL_THRESHOLD:
            CombatDebug.log("twist_full_dodge %s->%s eff=%.2f" % [atk_name, tgt_name, effective_follow_dodge])
            var rec_dur: float = CombatTiming.recovery_duration_with_form(
                intensity,
                "dodge",
                recovery_mult,
                perf_mod,
                atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
                -1.0,
                CombatantEntityAccess.form_str(tgt),
                CombatantEntityAccess.get_weapon(tgt)
            )
            return {"action": "dodge", "target_id": target_id, "recovery_duration": rec_dur}
        if dodge_roll_follow < effective_follow_dodge:
            var partial_range: float = effective_follow_dodge * (1.0 - CombatConstants.DODGE_FULL_THRESHOLD)
            var t_twist: float = (
                (dodge_roll_follow - effective_follow_dodge * CombatConstants.DODGE_FULL_THRESHOLD) / partial_range
                if partial_range > 0.001
                else 1.0
            )
            var twist_remaining_ratio: float = lerpf(twist_partial_min, 1.0, clampf(t_twist, 0.0, 1.0))
            var combined_ratio: float = parry_ratio * twist_remaining_ratio
            pa[DataKeys.ATTACK_PARRY_REMAINING_RATIO] = combined_ratio
            var v_current: float = pa.get("velocity_m_s", velocity_override)
            if v_current >= 0.0:
                var glancing_factor: float = CombatConstants.glancing_factor(
                    twist_remaining_ratio, CombatConstants.DODGE_GLANCING_EXPONENT
                )
                pa[DataKeys.PA_VELOCITY_M_S] = v_current * glancing_factor
            CombatDebug.log("twist_partial %s->%s combined=%.2f" % [atk_name, tgt_name, combined_ratio])
        else:
            CombatDebug.log("twist_none %s->%s resolving" % [atk_name, tgt_name])
    else:
        CombatDebug.log("twist_no_capacity %s->%s" % [atk_name, tgt_name])
    return null


static func _resolve_dodge(
    pa: Dictionary,
    atk: Dictionary,
    tgt: Dictionary,
    targetable: Array,
    attack_type: String,
    intensity: float,
    archetype: Dictionary,
    dodge_chance: float,
    dodge_eval_part: String,
    recovery_mult: float,
    perf_mod: float,
    target_id: int,
    tgt_name: String
) -> Variant:
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var dodge_target_part: String = (
        dodge_eval_part if not dodge_eval_part.is_empty() else BodyPartConstants.get_weighted_random_part(targetable)
    )
    var part_mod: float = CombatantEntityAccess._get_part_dodge_modifier(tgt, dodge_target_part)
    var effective_dodge_chance: float = dodge_chance * part_mod
    var dodge_roll: float = randf()
    if effective_dodge_chance > 0.0:
        if dodge_roll < effective_dodge_chance * CombatConstants.DODGE_FULL_THRESHOLD:
            CombatDebug.log("dodge_full %s eff=%.2f" % [tgt_name, effective_dodge_chance])
            var rec_dur: float = CombatTiming.recovery_duration_with_form(
                intensity,
                "dodge",
                recovery_mult,
                perf_mod,
                atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
                -1.0,
                CombatantEntityAccess.form_str(tgt),
                CombatantEntityAccess.get_weapon(tgt)
            )
            # Swing KE: the incoming blow's energy, so the applier can scale the attacker's
            # over-extension by impulse (mirrors the miss-path plumb in AttackResolver). A dodged
            # swing is the same over-extended commitment as a whiff, regardless of why it missed.
            var dodge_ke_j: float = AttackResolver._swing_kinetic_energy_j(
                CombatantEntityAccess.get_weapon(atk), intensity, archetype, attack_type
            )
            return {
                "action": "dodge",
                "target_id": target_id,
                "recovery_duration": rec_dur,
                DataKeys.RESULT_STRIKE_KE_J: dodge_ke_j,
            }
        if dodge_roll < effective_dodge_chance:
            var partial_range: float = effective_dodge_chance * (1.0 - CombatConstants.DODGE_FULL_THRESHOLD)
            var t: float = (
                (dodge_roll - effective_dodge_chance * CombatConstants.DODGE_FULL_THRESHOLD) / partial_range
                if partial_range > 0.001
                else 1.0
            )
            var dodge_remaining_ratio: float = lerpf(CombatConstants.DODGE_PARTIAL_RATIO_MIN, 1.0, clampf(t, 0.0, 1.0))
            pa[DataKeys.ATTACK_PARRY_REMAINING_RATIO] = dodge_remaining_ratio
            var atk_weapon = CombatantEntityAccess.get_weapon(atk)
            if atk_weapon != null:
                var attack_instance = AttackInstance.new(attack_type, intensity)
                attack_instance.archetype = archetype
                var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
                v_intent *= StrikeRealismProfile.velocity_intent_mult_from_pa(
                    pa, atk_weapon, attack_type, float(pa.get(DataKeys.ATTACK_INTENSITY, intensity)), archetype
                )
                var dodge_wind_up_dur: float = pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)
                var dodge_wuf: float = (
                    CombatTiming.wind_up_factor(dodge_wind_up_dur) if dodge_wind_up_dur > 0.0 else 1.0
                )
                if dodge_wuf < 1.0:
                    v_intent *= dodge_wuf
                var glancing_factor: float = CombatConstants.glancing_factor(
                    dodge_remaining_ratio, CombatConstants.DODGE_GLANCING_EXPONENT
                )
                pa[DataKeys.PA_VELOCITY_M_S] = v_intent * glancing_factor
            else:
                pa[DataKeys.PA_VELOCITY_M_S] = -1.0
            pa[DataKeys.PA_PARTIAL_DODGE_PART] = dodge_target_part
            CombatDebug.log(
                "dodge_partial %s part=%s ratio=%.2f" % [tgt_name, dodge_target_part, dodge_remaining_ratio]
            )
        else:
            CombatDebug.log("dodge_none %s => hit" % [tgt_name])
    return null


## Parry contact resolution now lives in **`DefenseParryResolution`** (pure code-motion split).
## This delegate keeps the internal call site in `resolve` unchanged.


static func _resolve_parry(
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
    return DefenseParryResolution.resolve_parry(
        pa,
        atk,
        tgt,
        attack_type,
        intensity,
        archetype,
        recovery_mult,
        parry_p_a,
        parry_c_d,
        parry_time_to_react,
        parry_readiness,
        is_block_parry,
        m_a_parry,
        m_d_parry,
        m_a_velocity,
        _effective_redirect,
        late_parry,
        parry_off_balance,
        target_id,
        atk_name,
        _tgt_name,
        dc
    )
